Imports System
Imports System.Web
Imports System.Web.UI.WebControls
Imports System.IO
Imports System.Data
Imports System.Data.SqlClient

Namespace Prompt

    '********************************************
    '*  Budget Class
    '*  
    '*  Purpose: Processes data for the JCAF Budget Object
    '*
    '*  Last Mod By:    Ford James
    '*  Last Mod On:    11/15/07
    '*
    '********************************************

    Public Class promptBudget
        Implements IDisposable

        'Properties
        Public CallingPage As Page
        Private db As PromptDataHelper

        Public TotalEncumberedIsGreaterThanAllocated As Boolean = False   'to flag legacy over encumbered


        Public Sub New()
            db = New PromptDataHelper
        End Sub

#Region "Subs and Functions"

        Public Function GetBudgetColumnSettings(ByVal ProjectID As Integer) As DataTable

            Return db.ExecuteDataTable("SELECT * FROM Projects WHERE ProjectID = " & ProjectID)

        End Function


        Public Sub GetBudgetColumnSettingsForEdit(ByVal ProjectID As Integer)

            'Get the custom JCAF column name if any
            Dim tblHeaders As DataTable = db.ExecuteDataTable("SELECT * FROM Districts WHERE DistrictID = " & HttpContext.Current.Session("DistrictID"))
            For Each row As DataRow In tblHeaders.Rows
                If Not IsDBNull(row("JCAFDonationColumnName")) Then
                    If row("JCAFDonationColumnName") <> "" Then
                        Dim chk As CheckBox = CallingPage.Form.FindControl("chkBudgetHideDonationColumn")
                        chk.Text = "Hide " & row("JCAFDonationColumnName") & " Column"
                    End If
                End If
                If Not IsDBNull(row("JCAFGrantColumnName")) Then
                    If row("JCAFGrantColumnName") <> "" Then
                        Dim chk As CheckBox = CallingPage.Form.FindControl("chkBudgetHideGrantColumn")
                        chk.Text = "Hide " & row("JCAFGrantColumnName") & " Column"

                    End If
                End If
                If Not IsDBNull(row("JCAFHazmatColumnName")) Then
                    If row("JCAFHazmatColumnName") <> "" Then
                        Dim chk As CheckBox = CallingPage.Form.FindControl("chkBudgetHideHazmatColumn")
                        chk.Text = "Hide " & row("JCAFHazmatColumnName") & " Column"

                    End If
                End If
                If Not IsDBNull(row("JCAFMaintColumnName")) Then
                    If row("JCAFMaintColumnName") <> "" Then
                        Dim chk As CheckBox = CallingPage.Form.FindControl("chkBudgetHideMaintColumn")
                        chk.Text = "Hide " & row("JCAFMaintColumnName") & " Column"

                    End If
                End If
            Next

            db.FillForm(CallingPage.FindControl("Form1"), "SELECT * FROM Projects WHERE ProjectID = " & ProjectID)

        End Sub

        Public Sub SaveBudgetColumnSettings(ByVal ProjectID As Integer)

            db.SaveForm(CallingPage.FindControl("Form1"), "SELECT * FROM Projects WHERE ProjectID = " & ProjectID)

        End Sub


        'Public Sub GetBudgetBatch(ByVal form As Control, ByVal id As Integer)

        '    Dim tbl As DataTable = db.ExecuteDataTable("SELECT * FROM BudgetChangeBatches WHERE BudgetChangeBatchID = " & id)
        '    'pass the form and table to fill routine
        '    db.FillForm(form, tbl)

        'End Sub

        'Public Sub SaveBudgetBatch()

        '    'Takes data from the form and writes it to the database
        '    Dim newID As Integer = 0
        '    Dim sql As String = ""
        '    'Dim dt As DataTable
        '    Dim id As String = DirectCast(CallingPage.FindControl("lblBatchID"), Label).Text
        '    If id = "0" Then   'this is a new record
        '        sql = "INSERT INTO BudgetChangeBatches (ClientID,DistrictID)"
        '        sql &= " SELECT CAST(SCOPE_IDENTITY() AS int) AS ID"
        '        newID = db.ExecuteScalar(sql)

        '        'Now we need to update all the colleges associated with this district with the new current batch
        '        sql = "UPDATE Colleges SET CurrentBudgetBatchID = " & newID & " WHERE DistrictID = " & CallingPage.Session("DistrictID")
        '        db.ExecuteNonQuery(sql)

        '        'Now we need to update the budgetchangelog with projects associated with this district with the new current batch entries
        '        sql = "SELECT Projects.DistrictID, Projects.CollegeID,Colleges.CurrentBudgetBatchID, Projects.ProjectID "
        '        sql &= "FROM Colleges INNER JOIN Projects ON Colleges.CollegeID = Projects.CollegeID "
        '        'sql &= "INNER JOIN PromptProjectData ON Projects.ProjectID = PromptProjectData.ProjectID "
        '        sql &= "WHERE Projects.DistrictID = " & CallingPage.Session("DistrictID")

        '        db.FillReader(sql)  'for list of project

        '        Using rs As New PromptDataHelper
        '            rs.FillDataTableForUpdate("SELECT * FROM BudgetChangeLog ")  'target table
        '            While db.Reader.Read
        '                Dim row As DataRow = rs.DataTable.NewRow
        '                row("CollegeID") = db.Reader("CollegeID")
        '                row("ProjectID") = db.Reader("ProjectID")
        '                row("BudgetChangeBatchID") = db.Reader("CurrentBudgetBatchID")
        '                row("LastBudgetBatchAmount") = db.Reader("OrigBudget")
        '                row("NewAmount") = db.Reader("OrigBudget")
        '                row("LastUpdateBy") = CallingPage.Session("UserName")
        '                row("LastUpdateOn") = Now()

        '                rs.DataTable.Rows.Add(row)
        '            End While

        '            rs.SaveDataTableToDB()

        '        End Using
        '        db.Reader.Close()


        '    Else        'this is an edit

        '        sql = "SELECT * FROM BudgetChangeBatches WHERE BudgetChangeBatchID = " & id
        '        db.SaveForm(CallingPage.FindControl("Form1"), sql)

        '    End If

        'End Sub

        Public Sub GetBudgetAssumptionsData(ByVal projectid As Integer)
            'pass the form and sql to fill routine
            db.FillForm(CallingPage.FindControl("Form1"), "SELECT * FROM Projects WHERE ProjectID = " & projectid)

        End Sub
        Public Sub SaveBudgetAssumptionsData(ByVal projectid As Integer)

            'pass the form and sql to fill routine
            db.SaveForm(CallingPage.FindControl("Form1"), "SELECT * FROM Projects WHERE ProjectID = " & projectid)

        End Sub

        'Public Sub GetProjectBudgetChangeLogItem()

        '    Dim ProjectID As Integer = CallingPage.Request.QueryString("ProjectID")
        '    Dim BatchID As Integer = CallingPage.Request.QueryString("BatchID")

        '    'gets a project budget change item for the current budget change batch for 
        '    'the given project.
        '    Dim sql As String = "SELECT BudgetChangeLog.*, BudgetChangeBatches.Description FROM BudgetChangeLog "
        '    sql = sql & "INNER JOIN BudgetChangeBatches ON BudgetChangeLog.BudgetChangeBatchID = BudgetChangeBatches.BudgetChangeBatchID "
        '    sql = sql & "WHERE ProjectID = " & ProjectID & " AND BudgetChangeLog.BudgetChangeBatchID = " & BatchID
        '    db.FillForm(CallingPage.FindControl("Form1"), sql)

        '    'display the current batch description
        '    sql = "SELECT Description FROM BudgetChangeBatches WHERE BudgetChangeBatchID = " & BatchID
        '    DirectCast(CallingPage.FindControl("lblCurrentBudgetBatch"), Label).Text = db.ExecuteScalar(sql)

        'End Sub


        'Public Sub SaveProjectBudgetChangeLogItem()
        '    Dim id As Integer = DirectCast(CallingPage.FindControl("lblBudgetChangeBatchID"), Label).Text
        '    Dim sql As String = ""
        '    If id = 0 Then   'this is a new one so  write it then populate (HACK)
        '        sql = "INSERT INTO BudgetChangeLog (CollegeID,ProjectID, BudgetChangeBatchID) VALUES(" & CallingPage.Session("CollegeID") & "," & CallingPage.Request.QueryString("ProjectID") & "," & CallingPage.Request.QueryString("BatchID") & ") "
        '        sql = sql & "SELECT CAST(SCOPE_IDENTITY() AS int) AS ID"
        '        id = db.ExecuteScalar(sql)
        '    End If

        '    sql = "SELECT * FROM BudgetChangeLog WHERE BudgetChangeLogID = " & id
        '    'pass the form and table to fill routine
        '    db.SaveForm(CallingPage.FindControl("Form1"), sql)


        'End Sub

        'Public Sub LoadEditForm(ByVal PrimaryKey As Integer, ByVal ProjectID As Integer, ByVal JCAFColumnName As String)

        '    Dim sql As String = ""

        '    'Find out if limiting object codes to only assigned
        '    sql = "SELECT IncludeAllObjectCodesInJCAF FROM Districts WHERE DistrictID = " & CallingPage.Session("DistrictID")
        '    If db.ExecuteScalar(sql) = 0 Then
        '        sql = "SELECT ObjectCodes.ObjectCode as Val, ObjectCodes.ObjectCodeDescription AS Lbl "
        '        sql &= "FROM ObjectCodes INNER JOIN ObjectCodesJCAFLines ON ObjectCodes.ObjectCode = ObjectCodesJCAFLines.ObjectCode AND "
        '        sql &= "ObjectCodes.DistrictID = ObjectCodesJCAFLines.DistrictID "
        '        sql &= "WHERE ObjectCodes.DistrictID = " & CallingPage.Session("DistrictID") & " AND "
        '        sql &= "ObjectCodesJCAFLines.JCAFItemName = '" & JCAFColumnName & "' "
        '        sql &= "ORDER BY ObjectCodes.ObjectCode + ' - ' + ObjectCodes.ObjectCodeDescription"

        '    Else
        '        sql = "SELECT ObjectCodes.ObjectCode AS Val, ObjectCodes.ObjectCodeDescription AS Lbl "
        '        sql &= "FROM ObjectCodes WHERE ObjectCodes.DistrictID = " & CallingPage.Session("DistrictID") & " "
        '        sql &= "ORDER BY ObjectCodes.ObjectCode + ' - ' + ObjectCodes.ObjectCodeDescription"
        '    End If

        '    db.FillDropDown(sql, CallingPage.FindControl("lstObjectCode"), False, False, True)

        '    'Fill Interest Account Dropdown
        '    sql = "SELECT LedgerAccountID AS Val, LedgerName AS Lbl FROM LedgerAccounts WHERE CollegeID =" & HttpContext.Current.Session("CollegeID") & " ORDER BY LedgerName"
        '    db.FillDropDown(sql, CallingPage.FindControl("lstLedgerAccounts"), False, False, False)

        '    'Load form data
        '    If PrimaryKey > 0 Then
        '        sql = "SELECT * FROM BudgetObjectCodes WHERE PrimaryKey = " & PrimaryKey
        '        db.FillForm(CallingPage.FindControl("Form1"), sql)
        '    End If



        '    'While db.Reader.Read
        '    '    sNote = ProcLib.CheckNullDBField(db.Reader("Note"))
        '    '    nCurAlloc = db.Reader("Amount")
        '    'End While
        '    'DirectCast(CallingPage.FindControl("txtNotes"), TextBox).Text = sNote

        '    'db.Reader.Close()

        '    ''Get current total Encumberances
        '    'sql = "SELECT (CASE WHEN SUM(Amount) IS NULL THEN 0 ELSE Sum(Amount) END) as tot FROM ContractLineItems WHERE ProjectID = " & ProjectID & " AND JCAFCellName = '" & JCAFColumnName & "' "
        '    'Dim nTotEncumb As Double = db.ExecuteScalar(sql)
        '    '' DirectCast(CallingPage.FindControl("lblCurrentEncumb"), Label).Text = FormatCurrency(nTotEncumb)



        '    ''Get current total allocated
        '    'sql = "SELECT (CASE WHEN SUM(Amount) IS NULL THEN 0 ELSE Sum(Amount) END) as tot FROM BudgetItems WHERE ProjectID = " & ProjectID & " AND BudgetField = '" & JCAFColumnName & "' "
        '    'Dim nTotAlloc As Double = db.ExecuteScalar(sql)


        '    'If nTotEncumb > nTotAlloc Then
        '    '    TotalEncumberedIsGreaterThanAllocated = True
        '    'End If



        'End Sub
        'Public Function GetBudgetObjectCodes(ByVal ProjectID As Integer, ByVal JCAFColumnName As String) As DataTable
        '    'returns the object codes for a given JCAF line and Project
        '    Dim sql As String = "SELECT BudgetObjectCodes.*, "

        '    sql &= " (SELECT SUM(Amount) AS Expr1 FROM ContractLineItems WHERE ProjectID = BudgetObjectCodes.ProjectID AND "
        '    sql &= " JCAFCellName = BudgetObjectCodes.JCAFColumnName) AS TotalEncumbered, "
        '    sql &= " (SELECT SUM(Amount) AS Expr1 FROM ContractLineItems WHERE ProjectID = BudgetObjectCodes.ProjectID AND ObjectCode = BudgetObjectCodes.ObjectCode AND "
        '    sql &= " JCAFCellName = BudgetObjectCodes.JCAFColumnName) AS OCEncumberedAmount, "

        '    sql &= " (SELECT SUM(Amount) AS Expr1 FROM PassThroughEntries WHERE ProjectID = BudgetObjectCodes.ProjectID AND ObjectCode = BudgetObjectCodes.ObjectCode AND "
        '    sql &= " JCAFCellName = BudgetObjectCodes.JCAFColumnName) AS OCPassThroughEncumberedAmount, "

        '    sql &= " (SELECT SUM(Amount) AS Expr1 FROM BudgetObjectCodes AS Bud2 WHERE ProjectID = BudgetObjectCodes.ProjectID AND ObjectCode = BudgetObjectCodes.ObjectCode AND "
        '    sql &= "JCAFColumnName = BudgetObjectCodes.JCAFColumnName) AS OCTotalAmount, "
        '    sql &= "LedgerAccounts.LedgerName AS LedgerAccountName "
        '    sql &= "FROM BudgetObjectCodes LEFT OUTER JOIN LedgerAccounts ON BudgetObjectCodes.LedgerAccountID = LedgerAccounts.LedgerAccountID "
        '    sql &= "WHERE ProjectID = " & ProjectID & " AND JCAFColumnName = '" & JCAFColumnName & "'"




        '    Return db.ExecuteDataTable(sql)


        'End Function


        Public Sub DeleteBudgetObjectCodeEstimate(ByVal id As Integer)
            Dim sql As String = "DELETE FROM BudgetObjectCodeEstimates WHERE PrimaryKey = " & id
            db.ExecuteNonQuery(sql)
        End Sub
        Public Function GetObjectCodeDescription(ByVal objectcode As String)
            Dim sql As String = "Select ObjectCodeDescription From ObjectCodes Where DistrictID = " & CallingPage.Session("DistrictID") & " and ObjectCode = '" & objectcode & "' "
            Return db.ExecuteScalar(sql)
        End Function

        Public Sub SaveBudgetObjectCodeEstimate(ByVal Key As Integer, ByVal CollID As Integer, ByVal ProjID As Integer)
            Dim sql As String = ""
            'Takes data from the form and writes it to the database
            If Key = 0 Then      'new record
                sql = "INSERT INTO BudgetObjectCodeEstimates "
                sql &= "(DistrictID,CollegeID,ProjectID, LastUpdateBy, LastUpdateOn)"
                sql &= "VALUES (" & CallingPage.Session("DistrictID") & "," & CollID & "," & ProjID & ",'" & db.CurrentUserName & "','" & Now() & "')"
                sql &= "SELECT CAST(SCOPE_IDENTITY() AS int) AS ID"

                Key = db.ExecuteScalar(sql)
            End If

            sql = "SELECT * FROM BudgetObjectCodeEstimates WHERE PrimaryKey = " & Key
            Dim form As Control = CallingPage.FindControl("Form1")
            db.SaveForm(form, sql)                       'pass the form and sql to fill routine

            'Update the ObjectCode description - because the description is not part of the value field in the cbo box, won't write in saveform
            Dim lst As Telerik.Web.UI.RadComboBox = form.FindControl("rcbObjectCode")   'get refernce to the cbo
            Dim sDescription As String = lst.SelectedItem.Text                          'get the item
            sDescription = Trim(Mid(sDescription, InStr(sDescription, "::") + 2))   'strip out the object code part
            sql = "UPDATE BudgetObjectCodeEstimates SET Description = '" & sDescription & "' WHERE PrimaryKey = " & Key
            db.ExecuteNonQuery(sql)


        End Sub

        Public Sub SaveBudgetReportingEstimates(ByVal CollegeID As Integer, ByVal ProjID As Integer)

            Dim sql As String = ""
            Dim nkey As String
            Dim fldName As String
            Dim val As String = "0"
            Dim i As Integer

            For i = 0 To CallingPage.Request.Form.Count - 1             'iterate each of the returned forms controls
                fldName = CallingPage.Request.Form.AllKeys(i)
                'If Not InStr(fldName, "_text") And Not InStr(fldName, "_ClientState") Then
                If InStr(fldName, "txtBudget") > 0 Then
                    If Not InStr(fldName, "_ClientState") > 0 Then
                        If CallingPage.Request.Form(fldName) = "" Then
                            val = "0"
                        Else
                            val = CallingPage.Request.Form(fldName)
                        End If

                        val = CDbl(val)
                        nkey = Mid(fldName, 10)
                        nkey = nkey.Replace("_text", "")
                        sql = "UPDATE BudgetReporting SET Budget = " & val & ",LastUPdateOn = '" & Now() & "',LastUpdateBy ='" & CallingPage.Session("UserName") & "'  WHERE PrimaryKey = " & nkey
                        db.ExecuteNonQuery(sql)
                    End If
                End If


            Next

        End Sub

        'Public Function GetBudgetObjectCodeEstimatesToo(ByVal ProjID As Integer) As DataTable
        '    'Gets a list of budget object code estimates for the current project

        '    Dim sql As String = "Select * From BudgetObjectCodeEstimates Where ProjectID = " & ProjID & " ORDER BY ObjectCode"
        '    Return db.ExecuteDataTable(sql)

        'End Function

        Public Function GetObjectCodes() As DataTable
            'Gets a distinct list of object codes for the current district for the combo box

            Dim sql As String = "SELECT DISTINCT ObjectCode, ObjectCodeDescription AS Description FROM ObjectCodes WHERE DistrictID = " & CallingPage.Session("DistrictID") & " ORDER BY ObjectCode"
            Return db.ExecuteDataTable(sql)

        End Function


        Public Function GetBudgetObjectCodeEstimates(ByVal ProjectID As Integer) As DataTable
            'returns the ObjectCOde Estimates and Pending entries for given project ID
            Dim tbl As DataTable
            tbl = db.ExecuteDataTable("SELECT * FROM BudgetObjectCodeEstimates WHERE ProjectID = " & ProjectID & " ORDER BY ObjectCode")

            If tbl.Rows.Count() = 0 Then  'build empty rows for data entry  -FOR FHDA


                AddBlankBudgetObjectCodeEstimateRow(tbl, "2110", "District Labor - CL Managers Sal")
                AddBlankBudgetObjectCodeEstimateRow(tbl, "2170", "District Labor - CL Contr Non-Ins")
                AddBlankBudgetObjectCodeEstimateRow(tbl, "2180", "District Labor - Clas Sal Unit A")
                AddBlankBudgetObjectCodeEstimateRow(tbl, "2350", "District Labor - CL Hrly Non-Inst")
                AddBlankBudgetObjectCodeEstimateRow(tbl, "2360", "District Labor - CL Prem Overtime")
                AddBlankBudgetObjectCodeEstimateRow(tbl, "3100", "District Labor - Benefit Budget/Enc-A")
                AddBlankBudgetObjectCodeEstimateRow(tbl, "3200", "District Labor - Benefit Budget/Enc-B")

                AddBlankBudgetObjectCodeEstimateRow(tbl, "4010", "Supplies")

                AddBlankBudgetObjectCodeEstimateRow(tbl, "4062", "Reprographics")
                AddBlankBudgetObjectCodeEstimateRow(tbl, "5042", "Attorney Fees")
                AddBlankBudgetObjectCodeEstimateRow(tbl, "5066", "Chargeback-PLNT SVCS")
                AddBlankBudgetObjectCodeEstimateRow(tbl, "5201", "Architect and Design")
                AddBlankBudgetObjectCodeEstimateRow(tbl, "5202", "Inspection")
                AddBlankBudgetObjectCodeEstimateRow(tbl, "5203", "CAP Proj Testing")
                AddBlankBudgetObjectCodeEstimateRow(tbl, "5204", "Construction MGMT")
                AddBlankBudgetObjectCodeEstimateRow(tbl, "5205", "Blueprints")
                AddBlankBudgetObjectCodeEstimateRow(tbl, "5207", "Other Consultants")
                AddBlankBudgetObjectCodeEstimateRow(tbl, "5209", "Contracted Services")
                AddBlankBudgetObjectCodeEstimateRow(tbl, "5214", "Tech and Prop Serv")
                AddBlankBudgetObjectCodeEstimateRow(tbl, "5228", "Operatnal Moving Exp")
                AddBlankBudgetObjectCodeEstimateRow(tbl, "5231", "Blueprint Reimbrsmnt")
                AddBlankBudgetObjectCodeEstimateRow(tbl, "5239", "DSA Fees")
                AddBlankBudgetObjectCodeEstimateRow(tbl, "5241", "Consultants Labor Comp")

                AddBlankBudgetObjectCodeEstimateRow(tbl, "5237", "ETS Standards Gen OH")

                AddBlankBudgetObjectCodeEstimateRow(tbl, "5270", "Progrm Mgmt Genrl OH")
                AddBlankBudgetObjectCodeEstimateRow(tbl, "5271", "CM and DM")
                AddBlankBudgetObjectCodeEstimateRow(tbl, "5310", "Equip Rent/Lease")

                AddBlankBudgetObjectCodeEstimateRow(tbl, "5735", "Postage and Delivery")
                AddBlankBudgetObjectCodeEstimateRow(tbl, "5745", "Advertising")
                AddBlankBudgetObjectCodeEstimateRow(tbl, "5823", "Overhead Contingency")

                AddBlankBudgetObjectCodeEstimateRow(tbl, "5913", "DSA Fees")

                AddBlankBudgetObjectCodeEstimateRow(tbl, "6420", "Equip/Furniture")

                AddBlankBudgetObjectCodeEstimateRow(tbl, "6500", "Princ Const Contract")
                AddBlankBudgetObjectCodeEstimateRow(tbl, "7900", "Construction Contingency")

            End If

            Return tbl

        End Function
        Private Sub AddBlankBudgetObjectCodeEstimateRow(ByRef tbl As DataTable, ByVal code As String, ByVal descr As String)
            'pass refence to table we are building and add rows to it
            Dim row As DataRow = tbl.NewRow
            row("ObjectCode") = code
            row("Description") = descr
            row("EstimateToComplete") = 0
            row("PendingExpenses") = 0
            tbl.Rows.Add(row)

        End Sub

        'Public Sub SaveBudgetObjectCodeEstimates(ByVal ProjectID As Integer)

        '    'saves the object code estimate numbers 

        '    'remove existing numbers for this project
        '    db.ExecuteNonQuery("DELETE FROM BudgetObjectCodeEstimates WHERE ProjectID = " & ProjectID)

        '    'Add records from page to table
        '    For i As Integer = 1 To 34

        '        Dim sObjectCode As String = CallingPage.Request.Form("lblOC" & i)
        '        Dim sDescr As String = CallingPage.Request.Form("lblDescr" & i)
        '        Dim nPending As Double = CallingPage.Request.Form("txtPending" & i)
        '        Dim nEstimate As Double = CallingPage.Request.Form("txtEstimate" & i)

        '        'Write the values to DB
        '        Dim sql As String = "INSERT INTO BudgetObjectCodeEstimates "
        '        sql &= "(DistrictId,CollegeID,ProjectID,ObjectCode,Description,PendingExpenses,EstimateToComplete,LastUpdateby,LastUpdateOn) "
        '        sql &= "VALUES(" & CallingPage.Session("DistrictId") & "," & CallingPage.Session("CollegeID") & ","
        '        sql &= ProjectID & ",'" & sObjectCode & "','" & sDescr & "'," & nPending & "," & nEstimate & ",'"
        '        sql &= CallingPage.Session("UserName") & "','" & Now() & "')"

        '        db.ExecuteNonQuery(sql)

        '    Next


        'End Sub

        Private Sub LogChange(ByVal CollegeID As Integer, ByVal ProjectID As Integer, ByVal JCAFColumnName As String, ByVal Description As String)
            Using db1 As New PromptDataHelper
                Dim sql As String = "INSERT INTO JCAFChangeLog (DistrictID,CollegeID,ProjectID,JCAFCOlumnName,ChangeDescription,LastUpdateOn,LastUpdateBy) "
                sql &= "VALUES(" & CallingPage.Session("DistrictID") & "," & CollegeID & "," & ProjectID & ","
                sql &= "'" & JCAFColumnName & "','" & Description & "','" & Now() & "','" & CallingPage.Session("UserName") & "')"
                db1.ExecuteNonQuery(sql)
            End Using

        End Sub


        'Public Sub SaveBudgetLineItem(ByVal PrimaryKey As Integer, ByVal CollegeID As Integer, ByVal ProjectID As Integer, ByVal JCAFColumnName As String)

        'Dim bUpdate As Boolean = True
        'Dim bAllocationsExist As Boolean = False
        'Dim nEncumbranceAmount As Double = 0
        'Dim nAllocationTotal As Double = 0
        'Dim sMessage As String = ""
        'Dim sql As String = ""

        'Dim bLogChanges As Boolean = False
        'Dim sLogDescription As String = ""


        'If ProjectID = 0 Then       'DEBUG: Need to test for zero in ProjectID to prevent wipeout wen global project
        '    sMessage = "ERROR: Lost PROJECT ID. Please contact Tech Support."
        '    Return sMessage
        'End If


        ''Check to see if JCAF Budget Change tracking is on and if so get old values
        'sql = "SELECT IsNull(TrackJCAFBudgetChanges,0) FROM Colleges WHERE CollegeID = " & CollegeID
        'Dim nresult As Integer = db.ExecuteScalar(sql)
        'If nresult > 0 Then bLogChanges = True

        'Dim txtNotes As TextBox = CallingPage.FindControl("txtNotes")
        ''txtNotes.Text = txtNotes.Text.Replace("'", "''")

        ''Check the total of any existing encumbrances
        'Dim lblEncumb As Label = CallingPage.FindControl("lblCurrentEncumb")
        'nEncumbranceAmount = Val(lblEncumb.Text)

        ''Get the total allocations
        'For Each r As DataRow In tblAlloc.Rows()
        '    nAllocationTotal = nAllocationTotal + r("Amount")
        'Next

        ''check to see current allocation is not less than current encumberance
        'If nAllocationTotal < nEncumbranceAmount Then

        '    sMessage = "Sorry, you cannot reduce the allocation below existing encumbrance amount."

        'Else     'okay to update

        '    'Update the change log
        '    'If bLogChanges Then
        '    '    Dim sOldNote As String = ""
        '    '    Dim sOldAmount As Double = 0
        '    '    Dim sChangeDescription As String = ""

        '    '    sql = "SELECT * FROM BudgetItems WHERE ProjectID = " & ProjectID & " AND BudgetField = '" & JCAFColumnName & "'"
        '    '    Dim reader As SqlDataReader = db.ExecuteReader(sql)
        '    '    While reader.Read
        '    '        sOldNote = Proclib.CheckNullDBField(reader("Note"))
        '    '        sOldNote = sOldNote.Replace("'", "''")
        '    '        sOldAmount = reader("Amount")
        '    '    End While
        '    '    reader.Close()

        '    '    If sOldAmount = 0 Then   'this is a new record
        '    '        sOldNote = "Added new Budget Amount"
        '    '    End If

        '    '    LogChange(CollegeID, ProjectID, JCAFColumnName, sChangeDescription)

        '    'End If

        '    Dim sNote As String = Replace(txtNotes.Text, "'", "''")   'clean up notes field and remove any bad characters


        '    'Update the BudgetItem with new amount if exists
        '    'Note: BudgetItem and BudgetObjectCodes table are parent/child related by ProjectId and JCAF Field name only


        '    If nAllocationTotal = 0 Then    'there is no allocation so delete all

        '        If bLogChanges Then  'get existing and log removal

        '            sLogDescription = "Budget Allocation Was Deleted. "
        '            LogChange(CollegeID, ProjectID, JCAFColumnName, sLogDescription)

        '            sql = "SELECT * FROM BudgetObjectCodes WHERE ProjectID = " & ProjectID & " AND JCAFColumnName = '" & JCAFColumnName & "'"
        '            Dim reader As SqlDataReader = db.ExecuteReader(sql)
        '            While reader.Read
        '                sLogDescription = "Allocation to ObjectCode " & reader("Description") & " for " & FormatCurrency(reader("Amount")) & " was Deleted."
        '                LogChange(CollegeID, ProjectID, JCAFColumnName, sLogDescription)
        '            End While
        '            reader.Close()
        '        End If

        '        'Remove all BudgetObjectCodes that have been removed by user
        '        sql = "DELETE FROM BudgetObjectCodes WHERE ProjectID = " & ProjectID & " AND JCAFColumnName = '" & JCAFColumnName & "'"
        '        db.ExecuteNonQuery(sql)

        '        'Remove all Ledger Entries related to BudgetObjectCodes that have been removed by user
        '        sql = "DELETE FROM LedgerAccountEntries WHERE ProjectID = " & ProjectID & " AND BudgetJCAFCOlumn = '" & JCAFColumnName & "'"
        '        db.ExecuteNonQuery(sql)

        '        sql = "DELETE FROM BudgetItems WHERE ProjectID = " & ProjectID & " AND BudgetField = '" & JCAFColumnName & "'"
        '        db.ExecuteNonQuery(sql)



        '    Else            'Update existing or add new allocations

        '        'Determine if BudgetItem already exists 
        '        sql = "SELECT Count(BudgetItemID) FROM BudgetItems WHERE ProjectID = " & ProjectID & " AND BudgetField = '" & JCAFColumnName & "'"
        '        Dim nBudgetItemID As Integer = db.ExecuteScalar(sql)
        '        If nBudgetItemID = 0 Then  'this is new record so add

        '            If bLogChanges Then  'log addition
        '                sLogDescription = "Budget Allocation Created: " & vbCrLf & "New Amount: " & FormatCurrency(nAllocationTotal) & vbCrLf & "Notes: " & sNote
        '                LogChange(CollegeID, ProjectID, JCAFColumnName, sLogDescription)
        '            End If

        '            'Add new budget line
        '            sql = "INSERT INTO BudgetItems (DistrictID,CollegeID,ProjectID,Amount,BudgetField,Note,LastUpdateBy,LastUpdateOn) "
        '            sql &= " VALUES(" & CallingPage.Session("DistrictID") & "," & CallingPage.Session("CollegeID")
        '            sql &= "," & ProjectID & "," & nAllocationTotal & ",'" & JCAFColumnName & "','" & sNote & "','"
        '            sql &= CallingPage.Session("UserName") & "','" & Now() & "')"

        '            db.ExecuteNonQuery(sql)
        '        Else                'Update existing record

        '            If bLogChanges Then  'log addition
        '                sLogDescription = "Budget Allocation Changed:" & vbCrLf & "New Amount:  " & FormatCurrency(nAllocationTotal) & vbCrLf & "Notes: " & sNote
        '                LogChange(CollegeID, ProjectID, JCAFColumnName, sLogDescription)
        '            End If

        '            sql = "UPDATE BudgetItems SET Amount = " & nAllocationTotal & ", LastUpdateBy = '" & HttpContext.Current.Session("UserName") & "',"
        '            sql &= "LastUpdateOn = '" & Now() & "', Note = '" & sNote & "' "
        '            sql &= "WHERE ProjectID = " & ProjectID & " AND BudgetField = '" & JCAFColumnName & "'"
        '            db.ExecuteNonQuery(sql)
        '        End If

        '        'update allocation records with any additions/deletions

        '        'Get all the remaining allocation primary keys from the form table
        '        Dim sKeys As String = ""
        '        If tblAlloc.Rows.Count > 0 Then
        '            For Each row As DataRow In tblAlloc.Rows()
        '                sKeys &= row("PrimaryKey") & ","
        '            Next
        '            sKeys = sKeys.Remove(Len(sKeys) - 1, 1)   'strip last comma
        '        End If

        '        'Remove all BudgetObjectCodes that have been removed by user
        '        If bLogChanges Then  'get existing and log removal
        '            sql = "SELECT * FROM BudgetObjectCodes WHERE ProjectID = " & ProjectID & " AND JCAFColumnName = '" & JCAFColumnName & "' AND PrimaryKey Not In (" & sKeys & ")"
        '            Dim reader As SqlDataReader = db.ExecuteReader(sql)
        '            While reader.Read
        '                sLogDescription = "Allocation to ObjectCode " & reader("Description") & " for " & FormatCurrency(reader("Amount")) & " was Deleted."
        '                LogChange(CollegeID, ProjectID, JCAFColumnName, sLogDescription)
        '            End While
        '            reader.Close()
        '        End If

        '        sql = "DELETE FROM BudgetObjectCodes WHERE ProjectID = " & ProjectID & " AND JCAFColumnName = '" & JCAFColumnName & "' AND PrimaryKey Not In (" & sKeys & ")"
        '        db.ExecuteNonQuery(sql)

        '        'Remove all Ledger Entries related to BudgetObjectCodes that have been removed by user
        '        sql = "DELETE FROM LedgerAccountEntries WHERE ProjectID = " & ProjectID & " AND BudgetJCAFColumn = '" & JCAFColumnName & "' AND BudgetObjectCodeID Not In (" & sKeys & ")"
        '        db.ExecuteNonQuery(sql)

        '        'go through the remaining object ccode allocations (in form) and  if not in the db then add
        '        'Add new entries to BudgetObjectCodes
        '        sql = "SELECT PrimaryKey FROM BudgetObjectCodes WHERE ProjectID = " & ProjectID & " AND JCAFColumnName = '" & JCAFColumnName & "'"
        '        Dim tblOld As DataTable = db.ExecuteDataTable(sql)

        '        For Each allocrow As DataRow In tblAlloc.Rows   'loop through new allocations
        '            Dim bfound As Boolean = False
        '            For Each row As DataRow In tblOld.Rows    'look for existing in current database
        '                If row("PrimaryKey") = allocrow("PrimaryKey") Then
        '                    bfound = True
        '                    Exit For
        '                End If
        '            Next
        '            If Not bfound Then    'add the new entry

        '                If bLogChanges Then  'log added allocations
        '                    sLogDescription = FormatCurrency(allocrow("Amount")) & " allocated to ObjectCode " & allocrow("Description")
        '                    LogChange(CollegeID, ProjectID, JCAFColumnName, sLogDescription)
        '                End If


        '                Dim nBudgetObjectCodeID As Integer = 0
        '                sql = "INSERT INTO BudgetObjectCodes (DistrictID,CollegeID,ProjectID,ObjectCode,Description,"
        '                sql &= "Amount,JCAFColumnName,LedgerAccountID,ItemDate,Notes,LastUpdateBy,LastUpdateOn) "
        '                sql &= " VALUES(" & CallingPage.Session("DistrictID") & "," & CallingPage.Session("CollegeID")
        '                sql &= "," & ProjectID & ","
        '                sql &= "'" & allocrow("ObjectCode") & "',"
        '                sql &= "'" & allocrow("Description") & "',"
        '                sql &= allocrow("Amount") & ","
        '                sql &= "'" & JCAFColumnName & "',"
        '                sql &= allocrow("LedgerAccountID") & ","
        '                sql &= "'" & allocrow("ItemDate") & "',"
        '                sql &= "'" & allocrow("Notes") & "',"
        '                sql &= "'" & CallingPage.Session("UserName") & "','" & Now() & "')"
        '                sql &= "SELECT CAST(SCOPE_IDENTITY() AS int) AS ID"

        '                nBudgetObjectCodeID = db.ExecuteScalar(sql)

        '                If allocrow("LedgerAccountID") > 0 Then    'add Ledger Account entry 

        '                    'Get the project name 
        '                    Dim sProjName As String = db.ExecuteScalar("SELECT ProjectName FROM Projects WHERE ProjectID = " & ProjectID)
        '                    Dim sJCAFDescr As String = db.ExecuteScalar("SELECT Description FROM BudgetFieldsTable WHERE ColumnName = '" & JCAFColumnName & "'")

        '                    Dim sDescr As String = "Allocation to " & sProjName & ", JCAF Line - " & sJCAFDescr & ", ObjectCode - " & allocrow("ObjectCode")
        '                    If Trim(allocrow("Notes")) <> "" Then
        '                        sDescr = allocrow("Notes")
        '                    End If


        '                    Dim sEntryDate As String = ProcLib.CheckNullDBField(allocrow("ItemDate"))
        '                    If Not IsDate(sEntryDate) = True Then
        '                        sEntryDate = Now.ToShortDateString
        '                    End If

        '                    sql = "INSERT INTO LedgerAccountEntries (DistrictID,CollegeID,ProjectID,Description,BudgetJCAFColumn,"
        '                    sql &= "EntryType,EntryDate,Amount,LedgerAccountID,BudgetObjectCodeID,LastUpdateBy,LastUpdateOn) "
        '                    sql &= " VALUES(" & CallingPage.Session("DistrictID") & ","
        '                    sql &= CallingPage.Session("CollegeID") & ","
        '                    sql &= ProjectID & ","
        '                    sql &= "'" & sDescr & "',"
        '                    sql &= "'" & JCAFColumnName & "',"
        '                    sql &= "'Debit',"
        '                    sql &= "'" & sEntryDate & "',"

        '                    sql &= (allocrow("Amount") * -1) & ","
        '                    sql &= allocrow("LedgerAccountID") & ","
        '                    sql &= nBudgetObjectCodeID & ","
        '                    sql &= "'" & CallingPage.Session("UserName") & "','" & Now() & "')"

        '                    db.ExecuteNonQuery(sql)   'get the new primary key for this allocation for ledger account entry
        '                End If
        '            End If
        '        Next
        '    End If
        'End If


        'Return sMessage

        'End Sub




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
