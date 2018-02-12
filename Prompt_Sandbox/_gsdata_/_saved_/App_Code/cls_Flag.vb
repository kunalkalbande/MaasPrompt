Imports System
Imports System.Web
Imports System.Web.UI.WebControls
Imports System.IO
Imports System.Data.SqlClient

Namespace Prompt

    '********************************************
    '*  Flag Class
    '*  
    '*  Purpose: Processes data for the Flag Object
    '*
    '*  Last Mod By:    Ford James
    '*  Last Mod On:    4/2/08
    '* Note: Projects, Contracts and Transaction flags are stored in the flags db using just the 
    '*       Parent Id  - there is only one per project , etc. However, with budget items, there
    '*       can be many items for a given project so need combo of project ID and fieldname.
    '*
    '********************************************

    Public Class promptFlag
        Implements IDisposable

        'Properties
        Public CallingPage As Page
        Public ParentRecID As Integer = 0
        Public ParentRecType As String = ""
        Public BudgetItemField As String = ""

        Private db As PromptDataHelper

        Public Sub New()
            db = New PromptDataHelper
        End Sub

#Region "Subs and Functions"

        Public Function GetFlaggedTransactions(ByVal Status As String) As DataTable
            'gets workflow transactions for given status and district
            Dim sql As String = ""
            Dim DistrictID As Integer = HttpContext.Current.Session("DistrictID")

            sql = "SELECT * FROM qry_GetDashboardFlaggedTransactions WHERE DistrictID = " & DistrictID
            sql &= " AND FlagStatus = '" & Status & "' ORDER BY College,ProjectName"
            Dim tbl As DataTable = db.ExecuteDataTable(sql)

            Return tbl
        End Function

        Public Function GetAllOpenFlags() As DataTable
            'gets all open flags
            Dim sql As String = ""
            Dim DistrictID As Integer = HttpContext.Current.Session("DistrictID")

            sql = "SELECT * FROM qry_GetAllFlaggedTransactions WHERE DistrictID = " & DistrictID & " UNION ALL "
            sql &= "SELECT * FROM qry_GetAllFlaggedContracts WHERE DistrictID = " & DistrictID & " UNION ALL "
            sql &= "SELECT * FROM qry_GetAllFlaggedChangeOrders WHERE DistrictID = " & DistrictID & " UNION ALL "
            sql &= "SELECT * FROM qry_GetAllFlaggedBudgetItems WHERE DistrictID = " & DistrictID & " UNION ALL "
            sql &= "SELECT * FROM qry_GetAllFlaggedProjects WHERE DistrictID = " & DistrictID & "  "
            sql &= "  ORDER BY FlagType,ProjectName"

            Dim tbl As DataTable = db.ExecuteDataTable(sql)

            Return tbl
        End Function

        Public Sub GetFlagForEdit()

            Dim form As Control = CallingPage.FindControl("Form1")

            Dim sql As String = "Select * From Flags "

            Select Case ParentRecType
                Case "Project"
                    sql = sql & "WHERE ProjectID = " & ParentRecID & " AND BudgetItemField = ''"

                Case "Contract"
                    sql = sql & "WHERE ContractID = " & ParentRecID

                Case "ContractDetail"
                    sql = sql & "WHERE ContractDetailID = " & ParentRecID

                Case "Transaction"
                    sql = sql & "WHERE TransactionID = " & ParentRecID

                Case "BudgetItem"
                    sql = sql & "WHERE ProjectID = " & ParentRecID & " AND BudgetItemField = '" & BudgetItemField & "'"

            End Select
            Dim tbl As DataTable = db.ExecuteDataTable(sql)
            If tbl.Rows.Count > 0 Then
                'Fix the <BR> in the flag description if any
                Dim sVal As String = tbl.Rows(0).Item("FlagDescription")
                sVal = sVal.Replace("<br/>", vbCrLf)
                tbl.Rows(0).Item("FlagDescription") = sVal
                db.FillForm(form, tbl.Rows(0))
            End If


        End Sub

        Public Sub SaveFlag(ByVal flagid As Integer)
            Dim sql As String = ""
            Dim FlagDescription As TextBox = CallingPage.FindControl("txtFlagDescription")
            Dim AssignedUsers As CheckBoxList = CallingPage.FindControl("lstAssignedUsers")
            FlagDescription.Text = Replace(FlagDescription.Text, "'", "''")   'fix any quotes in string

            If flagid > 0 Then   'existing flag
                sql = "UPDATE Flags SET FlagDescription = '" & FlagDescription.Text & "', "
                sql = sql & "LastUpdateOn = '" & Now() & "', "
                sql = sql & "LastUpdateBy = '" & CallingPage.Session("UserName") & "' "
                sql = sql & "WHERE FlagID = " & flagid
                db.ExecuteNonQuery(sql)
                'remove existing assignments and repopulate
                sql = "DELETE FROM FlagsWorkflowRoles WHERE FlagID = " & flagid
                db.ExecuteNonQuery(sql)


            Else   'add new flag
                If ParentRecType = "BudgetItem" Then
                    ParentRecType = "Project" 'need this for budgetitem only 
                End If

                sql = "INSERT INTO Flags "
                sql &= "(FlagDescription,LastUpdateOn,LastUpdateBy,CreatedOn,CreatedBy,Status," & ParentRecType & "ID,BudgetItemField) "
                sql &= "VALUES('" & FlagDescription.Text & "',"
                sql &= "'" & Now() & "', "
                sql &= "'" & CallingPage.Session("UserName") & "', "
                sql &= "'" & Now() & "', "
                sql &= "'" & CallingPage.Session("UserName") & "', "
                sql &= "'Open', "
                sql &= ParentRecID & ",'" & BudgetItemField & "')"
                sql &= ";SELECT NewKey = Scope_Identity()"  'return the new primary key

                flagid = db.ExecuteScalar(sql)

            End If



        End Sub

        Public Sub FlagTransactionFromWorkflowRejection(ByVal TransactionID As Integer, ByVal message As String)

            'Creates or updates existing FLAG for transaction with message

            Dim sql As String = ""
            message = Replace(message, "'", "''")   'fix any quotes in string

            sql = "SELECT FlagID FROM Flags WHERE TransactionID = " & TransactionID
            Dim result = db.ExecuteScalar(sql)
            Dim flagid As Integer = 0
            If Not IsDBNull(result) Then
                flagid = result
            End If

            If flagid > 0 Then   'existing flag
                sql = "UPDATE Flags SET FlagDescription = '" & message & "', "
                sql = sql & "LastUpdateOn = '" & Now() & "', "
                sql = sql & "LastUpdateBy = '" & HttpContext.Current.Session("UserName") & "' "
                sql = sql & "WHERE FlagID = " & flagid
                db.ExecuteNonQuery(sql)


            Else   'add new flag

                sql = "INSERT INTO Flags "
                sql &= "(FlagDescription,LastUpdateOn,LastUpdateBy,CreatedOn,CreatedBy,Status,TransactionID) "
                sql &= "VALUES('" & message & "',"
                sql &= "'" & Now() & "', "
                sql &= "'" & HttpContext.Current.Session("UserName") & "', "
                sql &= "'" & Now() & "', "
                sql &= "'" & HttpContext.Current.Session("UserName") & "', "
                sql &= "'Open', "
                sql &= TransactionID & ")"
                sql &= ";SELECT NewKey = Scope_Identity()"  'return the new primary key

                flagid = db.ExecuteScalar(sql)

            End If

        End Sub


        Public Sub ResolveFlag(ByVal flagid As Integer, ByVal FlagDescription As String)

            FlagDescription = "Flag Resolved: " & Replace(FlagDescription, "'", "''")   'fix any quotes in string

            Dim nTargetParentID As Integer = ParentRecID
            Dim sql As String = "INSERT INTO Notes "
            sql &= "(DistrictID, NoteType,CreatedOn,CreatedBy,Description,LastUpdateOn,LastUpdateBy,"

            Select Case ParentRecType
                Case "Project"     'put in project notes
                    sql &= "ProjectID)"

                Case "Contract"  'put in contract notes
                    sql &= "ContractID)"

                Case "ContractDetail"   'put in contract notes
                    sql &= "ContractID)"
                    nTargetParentID = db.ExecuteScalar("SELECT ContractID FROM ContractDetail WHERE ContractDetailID = " & ParentRecID)

                Case "BudgetItem"     'put in project notes
                    sql &= "ProjectID)"

                Case "Transaction"   'need to get contract ID to put transaction flag into notes  
                    nTargetParentID = db.ExecuteScalar("SELECT ContractID FROM Transactions WHERE TransactionID = " & ParentRecID)
                    sql &= "ContractID)"

            End Select
            sql = sql & "VALUES(" & CallingPage.Session("DistrictID") & ",'Note','" & Now() & "','" & CallingPage.Session("UserName") & "',"
            sql = sql & "'" & FlagDescription & "','" & Now() & "',"
            sql = sql & "'" & CallingPage.Session("UserName") & "', "
            sql = sql & nTargetParentID & ")"

            db.ExecuteNonQuery(sql)

            ''delete flag
            'sql = "UPDATE Flags SET Status = 'Resolved', "
            'sql &= "LastUpdateBy = '" & CallingPage.Session("UserName") & "', "
            'sql &= "LastUpdateOn = '" & Now() & "' "
            'sql &= "WHERE FlagID = " & flagid

            ''delete flag
            sql = "DELETE FROM Flags WHERE FlagID = " & flagid
            db.ExecuteNonQuery(sql)



        End Sub

        Public Function FlagExists() As Boolean
            'determines if flag exists - called from all flaggable pages and save routine
            Dim sql As String = "SELECT COUNT(FlagID) AS FlagID FROM Flags "
            Select Case ParentRecType
                Case "Project"
                    sql &= "WHERE ProjectID = " & ParentRecID & " AND BudgetItemField = ''"

                Case "Contract"
                    sql &= "WHERE ContractID = " & ParentRecID

                Case "ContractDetail"
                    sql &= "WHERE ContractDetailID = " & ParentRecID

                Case "Transaction"
                    sql &= "WHERE TransactionID = " & ParentRecID

                Case "BudgetItem"
                    sql &= "WHERE ProjectID = " & ParentRecID & " AND BudgetItemField = '" & BudgetItemField & "'"

            End Select
            sql &= " AND Status <> 'Resolved' "

            If db.ExecuteScalar(sql) <> 0 Then
                Return True
            Else
                Return False
            End If

        End Function

#End Region

#Region "IDisposable"

        Public Overridable Sub Dispose() Implements IDisposable.Dispose
            If Not db Is Nothing Then
                db.Dispose()
            End If
        End Sub

#End Region

    End Class

End Namespace
