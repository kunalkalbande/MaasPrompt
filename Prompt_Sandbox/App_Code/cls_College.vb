Imports System
Imports System.Web
Imports System.Web.UI.WebControls
Imports System.IO
Imports System.Data
Imports System.Data.SqlClient
Imports System.Text

Namespace Prompt

    '********************************************
    '*  College Class
    '*  
    '*  Purpose: Processes data for the College Object
    '*
    '*  Last Mod By:    Ford James
    '*  Last Mod On:    04/02/07
    '*
    '********************************************

    Public Class College
        Implements IDisposable

        'Properties
        Public CallingPage As Page
        Public Reader As SqlDataReader
        Public DataTable As DataTable

        Private db As PromptDataHelper

        Public Sub New()
            db = New PromptDataHelper
        End Sub

#Region "Subs and Functions"

        Public Sub GetCollege(ByVal ctrl As Control, ByVal id As Integer)
            ' gets the college info and fills passed user control
            Dim sql As String = "SELECT * FROM Colleges WHERE CollegeID = " & id
            'pass the form and table to fill routine
            db.FillForm(ctrl, sql)

        End Sub

        Public Function GetCollegeList(ByVal districtid As Integer) As DataTable
            Return db.ExecuteDataTable("SELECT * FROM Colleges WHERE DistrictID = " & districtid & " ORDER BY College")
        End Function

        Public Sub GetCollegeForEdit(ByVal CollegeID As Integer, ByVal DistrictID As Integer)
            ' gets the college info data and fills edit form

            'Fill the dropdown(s)
            Dim sql As String = "SELECT LookupValue As Val, LookupTitle as Lbl FROM dbo.Lookups "
            sql &= "WHERE DistrictID = " & DistrictID & " AND ParentTable = 'Projects' AND ParentField = 'BondSeriesNumber'  ORDER By LookupTitle"
            db.FillDropDown(sql, CallingPage.Form.FindControl("lstCurrentSeriesNumber"))

            If CollegeID > 0 Then
                db.FillForm(CallingPage.FindControl("Form1"), "SELECT * FROM Colleges WHERE CollegeID = " & CollegeID)
            End If

        End Sub

        Public Function GetCollegeTotals(ByVal Category As String, ByVal id As Integer) As Double

            'Calculates the totals in the summary box and returns number

            Dim sql As New StringBuilder
            With sql
                Select Case Category
                    Case "Contracts"
                        .Append("SELECT SUM(Amount) AS nAmt FROM ContractLineItems WHERE CollegeID = " & id & " AND LineType = 'Contract'  ")

                    Case "Adjustments"
                        .Append("SELECT SUM(Amount) AS nAmt FROM ContractLineItems WHERE CollegeID = " & id & " AND LineType = 'Adjustment'  ")


                    Case "Transactions"
                        .Append("SELECT SUM(TransactionDetail.Amount) AS nAmt FROM TransactionDetail  INNER JOIN Contracts ON TransactionDetail.ContractID = Contracts.ContractID ")
                        .Append("WHERE CollegeID = " & id)

                    Case "Amendments"
                        .Append("SELECT SUM(Amount) AS nAmt FROM ContractLineItems WHERE CollegeID = " & id & " AND LineType = 'ChangeOrder'")

                    Case "InterestIncome"
                        .Append("SELECT SUM(Amount) AS nAmt FROM LedgerAccountEntries LAE join LedgerAccounts LA on LAE.LedgerAccountID = LA.LedgerAccountID Where LAE.CollegeID = " & id)


                End Select
            End With
            Dim rr = db.ExecuteScalar(sql.ToString)    'do not type cast because we don't know what is coming back
            If IsDBNull(rr) Then rr = 0
            Return rr

        End Function


        Public Sub SaveCollege(ByVal CollegeID As Integer, ByVal DistrictID As Integer, ByVal ClientID As Integer)
            Dim sql As String = ""
            If CollegeID = 0 Then   'this is new record
                sql = "INSERT INTO Colleges (ClientID,DistrictID) "
                sql &= "VALUES  (" & ClientID & "," & DistrictID & ")"
                sql &= ";SELECT NewKey = Scope_Identity()"

                CollegeID = db.ExecuteScalar(sql)

                'create the attachment directory
                Dim att As New promptAttachment
                With att
                    .DistrictID = DistrictID
                    .CollegeID = CollegeID
                    .CreateAttachmentDir()
                End With

            End If

            sql = "SELECT * FROM Colleges WHERE CollegeID = " & CollegeID
            db.SaveForm(CallingPage.FindControl("Form1"), sql)

        End Sub

        Public Function DeleteCollege(ByVal CollegeID As Integer) As String

            Dim msg As String = ""
            Dim sql As String = "SELECT COUNT(ProjectID) as TOT FROM Projects WHERE CollegeID = " & CollegeID
            Dim cnt As Integer = db.ExecuteScalar(sql)
            If cnt > 0 Then                 'display a popup warning and close edit page
                msg = "There are " & cnt & " Projects associtated with this College. Please Delete all associated records before deleting this College. "
            Else
                db.ExecuteNonQuery("DELETE FROM Colleges WHERE CollegeID = " & CollegeID)
            End If

            Return msg

        End Function


#End Region

#Region "Copy College"

        Public Sub CopyCollege(ByVal nCollegeID As Integer, ByVal CollegeName As String)

            'This sub creates a complete copy of the currently opened college including all child records minus attachments.
            Dim nDistrictID As Integer = HttpContext.Current.Session("DistrictID")
            Dim nClientID As Integer = HttpContext.Current.Session("ClientId")

            CollegeName = "Copy of " & CollegeName   'make new college name

            Dim sql As String = "INSERT INTO Colleges (College,CollegeType,ClientID,DistrictID) "
            sql &= "VALUES ('** New College **','College'," & nClientID & "," & nDistrictID & ")"
            sql &= ";SELECT NewKey = Scope_Identity()"

            Dim nNewTargetID As Integer = db.ExecuteScalar(sql)

            CollegeName = CollegeName & " (" & nNewTargetID & ")"   'to make new name unique to fix doubleing problem when college names are the same

            'Copy all other info
            Using dbTarget As New PromptDataHelper
                dbTarget.FillDataTableForUpdate("SELECT * FROM Colleges WHERE CollegeID = " & nNewTargetID)

                db.FillReader("SELECT * FROM Colleges WHERE CollegeID = " & nCollegeID)
                While db.Reader.Read
                    Dim TargetRow As DataRow = dbTarget.DataTable.Rows(0)
                    For Each Col As DataColumn In dbTarget.DataTable.Columns
                        Dim sColName As String = Col.ColumnName
                        Dim val = db.Reader(sColName)
                        If sColName <> "CollegeID" Then      'skip primary key
                            If sColName = "LastUpdateBy" Then
                                TargetRow.Item(sColName) = "CreateCopy"
                            ElseIf sColName = "LastUpdateOn" Then
                                TargetRow.Item(sColName) = Now()
                            ElseIf sColName = "College" Then
                                TargetRow.Item(sColName) = CollegeName
                            Else
                                TargetRow.Item(sColName) = val
                            End If
                        End If
                    Next
                End While
                db.Reader.Close()
                dbTarget.SaveDataTableToDB()

            End Using

            'now that we have a new college copy the child data

            Dim TargetSQL As String = ""
            Dim SourceSQL As String = ""
            Dim PrimaryKeyField As String = ""
            Dim NewOwnerKey As Integer = 0
            Dim NewOwnerKeyField As String = ""

            'copy College Notes
            TargetSQL = "SELECT * FROM Notes WHERE NoteID = 0"
            SourceSQL = "SELECT * FROM Notes WHERE CollegeID = " & nCollegeID
            PrimaryKeyField = "NoteID"
            NewOwnerKey = nNewTargetID
            NewOwnerKeyField = "CollegeID"

            CopyData(TargetSQL, SourceSQL, PrimaryKeyField, NewOwnerKey, NewOwnerKeyField)


            'Copy all Projects from source college
            db.FillDataTable("SELECT * FROM Projects WHERE CollegeID = " & nCollegeID)
            For Each row As DataRow In db.DataTable.Rows()
                CopyProject(row, nNewTargetID)
            Next


        End Sub

        Private Sub CopyProject(ByVal SourceRow As DataRow, ByVal nNewCollegeID As Integer)

            'This sub creates a complete copy of the currently passed project including all child records minus.

            'create the basic new project record
            Dim sql As String = "INSERT INTO Projects (CollegeID) "
            sql &= "VALUES (" & nNewCollegeID & ")"
            sql &= ";SELECT NewKey = Scope_Identity()"

            Dim nNewProjectID As Integer = db.ExecuteScalar(sql)

            'Copy all other Project info
            Using dbTarget As New PromptDataHelper
                dbTarget.FillDataTableForUpdate("SELECT * FROM Projects WHERE ProjectID = " & nNewProjectID)
                Dim TargetRow As DataRow = dbTarget.DataTable.Rows(0)
                For Each Col As DataColumn In dbTarget.DataTable.Columns
                    Dim sColName As String = Col.ColumnName
                    Dim val = SourceRow(sColName)
                    If sColName <> "ProjectID" Then      'skip primary key
                        If sColName = "LastUpdateBy" Then
                            TargetRow.Item(sColName) = "CreateCopy"
                        ElseIf sColName = "LastUpdateOn" Then
                            TargetRow.Item(sColName) = Now()
                        ElseIf sColName = "CollegeID" Then
                            TargetRow.Item(sColName) = nNewCollegeID   'this is here cause college id would be over written by subsequent update
                        Else
                            TargetRow.Item(sColName) = val
                        End If
                    End If
                Next
                dbTarget.SaveDataTableToDB()

            End Using

            'copy child data
            Dim TargetSQL As String = ""
            Dim SourceSQL As String = ""
            Dim PrimaryKeyField As String = ""
            Dim NewOwnerKey As Integer = 0
            Dim NewOwnerKeyField As String = ""

            'copy Project Notes
            TargetSQL = "SELECT * FROM Notes WHERE NoteID = 0"
            SourceSQL = "SELECT * FROM Notes WHERE ProjectID = " & SourceRow("ProjectID")
            PrimaryKeyField = "NoteID"
            NewOwnerKey = nNewProjectID
            NewOwnerKeyField = "ProjectID"

            CopyData(TargetSQL, SourceSQL, PrimaryKeyField, NewOwnerKey, NewOwnerKeyField)

            ''copy ProjectAdditionalData
            'TargetSQL = "SELECT * FROM PromptProjectData WHERE ProjectID = 0"
            'SourceSQL = "SELECT * FROM PromptProjectData WHERE ProjectID = " & SourceRow("ProjectID")
            'PrimaryKeyField = "PromptDataID"
            'NewOwnerKey = nNewProjectID
            'NewOwnerKeyField = "ProjectID"

            'CopyData(TargetSQL, SourceSQL, PrimaryKeyField, NewOwnerKey, NewOwnerKeyField)


            ''copy ProjectAppriseData
            'TargetSQL = "SELECT * FROM AppriseProjectData WHERE ProjectID = 0"
            'SourceSQL = "SELECT * FROM AppriseProjectData WHERE ProjectID = " & SourceRow("ProjectID")
            'PrimaryKeyField = "AppriseDataID"
            'NewOwnerKey = nNewProjectID
            'NewOwnerKeyField = "ProjectID"

            'CopyData(TargetSQL, SourceSQL, PrimaryKeyField, NewOwnerKey, NewOwnerKeyField)

            'copy BudgetItemsData
            TargetSQL = "SELECT * FROM BudgetItems WHERE ProjectID = 0"
            SourceSQL = "SELECT * FROM BudgetItems WHERE ProjectID = " & SourceRow("ProjectID")
            PrimaryKeyField = "BudgetItemID"
            NewOwnerKey = nNewProjectID
            NewOwnerKeyField = "ProjectID"

            CopyData(TargetSQL, SourceSQL, PrimaryKeyField, NewOwnerKey, NewOwnerKeyField, nNewCollegeID)

            'copy BudgetObjectCodeEstimates
            TargetSQL = "SELECT * FROM BudgetObjectCodeEstimates WHERE ProjectID = 0"
            SourceSQL = "SELECT * FROM BudgetObjectCodeEstimates WHERE ProjectID = " & SourceRow("ProjectID")
            PrimaryKeyField = "PrimaryKey"
            NewOwnerKey = nNewProjectID
            NewOwnerKeyField = "ProjectID"

            CopyData(TargetSQL, SourceSQL, PrimaryKeyField, NewOwnerKey, NewOwnerKeyField, nNewCollegeID)

            'copy BudgetObjectCodes
            TargetSQL = "SELECT * FROM BudgetObjectCodes WHERE ProjectID = 0"
            SourceSQL = "SELECT * FROM BudgetObjectCodes WHERE ProjectID = " & SourceRow("ProjectID")
            PrimaryKeyField = "PrimaryKey"
            NewOwnerKey = nNewProjectID
            NewOwnerKeyField = "ProjectID"

            CopyData(TargetSQL, SourceSQL, PrimaryKeyField, NewOwnerKey, NewOwnerKeyField, nNewCollegeID)

            'copy BudgetReporting
            TargetSQL = "SELECT * FROM BudgetReporting WHERE ProjectID = 0"
            SourceSQL = "SELECT * FROM BudgetReporting WHERE ProjectID = " & SourceRow("ProjectID")
            PrimaryKeyField = "PrimaryKey"
            NewOwnerKey = nNewProjectID
            NewOwnerKeyField = "ProjectID"

            CopyData(TargetSQL, SourceSQL, PrimaryKeyField, NewOwnerKey, NewOwnerKeyField)


            'NOTE: Does not do Ledger Accounts Yet or change history


            'Copy all Contracts from source Project
            db.FillDataTable("SELECT * FROM Contracts WHERE ProjectID = " & SourceRow("ProjectID"))
            For Each row As DataRow In db.DataTable.Rows()
                CopyContract(row, nNewCollegeID, nNewProjectID)
            Next


        End Sub

        Private Sub CopyContract(ByVal SourceRow As DataRow, ByVal nNewCollegeID As Integer, ByVal nNewProjectID As Integer)

            'This sub creates a complete copy of the currently passed project including all child records minus.

            'create the basic new project record
            Dim sql As String = "INSERT INTO Contracts (CollegeID,ProjectID) "
            sql &= "VALUES (" & nNewCollegeID & "," & nNewProjectID & ")"
            sql &= ";SELECT NewKey = Scope_Identity()"

            Dim nNewContractID As Integer = db.ExecuteScalar(sql)

            'Copy all other Project info
            Using dbTarget As New PromptDataHelper
                dbTarget.FillDataTableForUpdate("SELECT * FROM Contracts WHERE ContractID = " & nNewContractID)
                Dim TargetRow As DataRow = dbTarget.DataTable.Rows(0)
                For Each Col As DataColumn In dbTarget.DataTable.Columns
                    Dim sColName As String = Col.ColumnName
                    Dim val = SourceRow(sColName)
                    If sColName <> "ContractID" Then      'skip primary key
                        If sColName = "LastUpdateBy" Then
                            TargetRow.Item(sColName) = "CreateCopy"
                        ElseIf sColName = "LastUpdateOn" Then
                            TargetRow.Item(sColName) = Now()
                        ElseIf sColName = "CollegeID" Then
                            TargetRow.Item(sColName) = nNewCollegeID
                        ElseIf sColName = "ProjectID" Then
                            TargetRow.Item(sColName) = nNewProjectID
                        Else
                            TargetRow.Item(sColName) = val
                        End If
                    End If
                Next
                dbTarget.SaveDataTableToDB()

            End Using

            'copy child data
            Dim TargetSQL As String = ""
            Dim SourceSQL As String = ""
            Dim PrimaryKeyField As String = ""
            Dim NewOwnerKey As Integer = 0
            Dim NewOwnerKeyField As String = ""

            'copy Contract Notes
            TargetSQL = "SELECT * FROM Notes WHERE NoteID = 0"
            SourceSQL = "SELECT * FROM Notes WHERE ContractID = " & SourceRow("ContractID")
            PrimaryKeyField = "NoteID"
            NewOwnerKey = nNewContractID
            NewOwnerKeyField = "ContractID"

            CopyData(TargetSQL, SourceSQL, PrimaryKeyField, NewOwnerKey, NewOwnerKeyField)

            'copy ContractDetail
            TargetSQL = "SELECT * FROM ContractDetail WHERE ContractID = 0"
            SourceSQL = "SELECT * FROM ContractDetail WHERE ContractID = " & SourceRow("ContractID")
            PrimaryKeyField = "ContractDetailID"
            NewOwnerKey = nNewContractID
            NewOwnerKeyField = "ContractID"

            CopyData(TargetSQL, SourceSQL, PrimaryKeyField, NewOwnerKey, NewOwnerKeyField)

            'Copy all Transaction from source Contract
            db.FillDataTable("SELECT * FROM Transactions WHERE ContractID = " & SourceRow("ContractID"))
            For Each row As DataRow In db.DataTable.Rows()
                CopyTransaction(row, nNewCollegeID, nNewProjectID, nNewContractID)
            Next



        End Sub

        Private Sub CopyTransaction(ByVal SourceRow As DataRow, ByVal nNewCollegeID As Integer, ByVal nNewProjectID As Integer, ByVal nNewContractID As Integer)

            'This sub creates a complete copy of the currently passed project including all child records minus.

            'create the basic new project record
            Dim sql As String = "INSERT INTO Transactions (ProjectID) "
            sql &= "VALUES (" & nNewProjectID & ")"
            sql &= ";SELECT NewKey = Scope_Identity()"

            Dim nNewTransactionID As Integer = db.ExecuteScalar(sql)

            'Copy all other Transaction info
            Using dbTarget As New PromptDataHelper
                dbTarget.FillDataTableForUpdate("SELECT * FROM Transactions WHERE TransactionID = " & nNewTransactionID)
                Dim TargetRow As DataRow = dbTarget.DataTable.Rows(0)
                For Each Col As DataColumn In dbTarget.DataTable.Columns
                    Dim sColName As String = Col.ColumnName
                    Dim val = SourceRow(sColName)
                    If sColName <> "TransactionID" Then      'skip primary key
                        If sColName = "LastUpdateBy" Then
                            TargetRow.Item(sColName) = "CreateCopy"
                        ElseIf sColName = "LastUpdateOn" Then
                            TargetRow.Item(sColName) = Now()
                        ElseIf sColName = "ProjectID" Then
                            TargetRow.Item(sColName) = nNewProjectID
                        ElseIf sColName = "CollegeID" Then
                            TargetRow.Item(sColName) = nNewCollegeID
                        Else
                            TargetRow.Item(sColName) = val
                        End If
                    End If
                Next
                dbTarget.SaveDataTableToDB()

            End Using

            'copy child data
            Dim TargetSQL As String = ""
            Dim SourceSQL As String = ""
            Dim PrimaryKeyField As String = ""
            Dim NewOwnerKey As Integer = 0
            Dim NewOwnerKeyField As String = ""


            'copy ContractDetail
            TargetSQL = "SELECT * FROM ContractDetail WHERE ContractID = 0"
            SourceSQL = "SELECT * FROM ContractDetail WHERE ContractID = " & SourceRow("ContractID")
            PrimaryKeyField = "ContractDetailID"
            NewOwnerKey = nNewContractID
            NewOwnerKeyField = "ContractID"

            CopyData(TargetSQL, SourceSQL, PrimaryKeyField, NewOwnerKey, NewOwnerKeyField, 0, nNewProjectID)




        End Sub


        Private Sub CopyData(ByVal TargetSQL As String, ByVal SourceSQL As String, ByVal PrimaryKeyFldName As String, _
                             ByVal NewOwnerKey As Integer, ByVal NewOwnerKeyField As String, _
                            Optional ByVal nTargetCollegeID As Integer = 0, Optional ByVal nTargetProjectID As Integer = 0)

            'Copies all record from source to target and assigns new owner key 
            Using dbSource As New PromptDataHelper
                Using dbTarget As New PromptDataHelper
                    dbTarget.FillDataTableForUpdate(TargetSQL)
                    dbSource.FillReader(SourceSQL)
                    While dbSource.Reader.Read
                        Dim TargetRow As DataRow = dbTarget.DataTable.NewRow
                        For Each Col As DataColumn In dbTarget.DataTable.Columns
                            Dim sColName As String = Col.ColumnName
                            Dim val = dbSource.Reader(sColName)
                            If sColName <> PrimaryKeyFldName Then      'skip primary key
                                If sColName = "LastUpdateBy" Then
                                    TargetRow.Item(sColName) = "CreateCopy"
                                ElseIf sColName = "LastUpdateOn" Then
                                    TargetRow.Item(sColName) = Now()
                                ElseIf sColName = NewOwnerKeyField Then
                                    TargetRow.Item(sColName) = NewOwnerKey
                                Else
                                    TargetRow.Item(sColName) = val
                                End If
                            End If
                        Next

                        If nTargetCollegeID <> 0 Then      'fill in collegeid -- used to fill parent/parent id fields
                            TargetRow.Item("CollegeID") = nTargetCollegeID
                        End If
                        If nTargetProjectID <> 0 Then      'fill in ProjectID -- used to fill parent/parent id fields
                            TargetRow.Item("ProjectID") = nTargetProjectID
                        End If

                        dbTarget.DataTable.Rows.Add(TargetRow)

                    End While

                    dbSource.Reader.Close()
                    dbTarget.SaveDataTableToDB()

                End Using
            End Using

        End Sub







#End Region



#Region "IDisposable"

        Public Overridable Sub Dispose() Implements IDisposable.Dispose
            If Not db Is Nothing Then
                db.Dispose()
            End If
            If Not Reader Is Nothing Then
                Reader.Dispose()
            End If
            If Not DataTable Is Nothing Then
                DataTable.Dispose()
            End If
        End Sub

#End Region

    End Class

End Namespace
