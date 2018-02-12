Imports System
Imports System.Web
Imports System.Web.UI.WebControls
Imports System.IO
Imports System.Data
Imports System.Data.SqlClient

Namespace Prompt

    '********************************************
    '*  Passthrough Class
    '*  
    '*  Purpose: Processes data for the Passhthrough Projects/Entries 
    '*
    '*  Last Mod By:    Ford James
    '*  Last Mod On:    06/28/08
    '*
    '********************************************

    Public Class promptPassthrough
        Implements IDisposable

        'Properties

        Public CallingPage As Page

        Private db As PromptDataHelper

        Public Sub New()
            db = New PromptDataHelper
        End Sub

#Region "Subs and Functions"


        Public Function GetPassthroughEntries(ByVal ProjectID As Integer) As datatable
            'Gets passthrough entries for project
            Dim sql As String = ""

            sql = "Select * from PassthroughEntries where ProjectID = " & ProjectID

            Return db.ExecuteDataTable(sql)

        End Function

        Public Function GetTargetEntries(ByVal ProjectID As Integer) As DataTable
            'Gets target entries from a passthrough parent record
            Dim sql As String = ""

            sql = "Select * from PassthroughEntries where PassThroughProjectID = " & ProjectID & " AND ProjectID <> " & ProjectID    'don't include parent

            Return db.ExecuteDataTable(sql)

        End Function

        Public Sub GetExistingPassthroughEntry(ByVal ProjectID As Integer)

            'get LedgerAccount record and populate with info
            Dim row As DataRow
            row = db.GetDataRow("Select * from PassthroughEntries where PassthroughEntryID = " & ProjectID)
            Dim form As Control = CallingPage.FindControl("Form1")  ' get ref to calling form
            'pass the row to routine to populate form
            db.FillForm(form, row)

        End Sub


        Public Function IsPassthroughProject(ByVal ProjectID) As Boolean
            'Gets passthrough entries for project
            Dim sql As String = "Select IsPassthroughProject FROM Projects WHERE ProjectID = " & ProjectID
            Dim result = db.ExecuteScalar(sql)
            If Not IsDBNUll(result) Then
                If result = 1 Then
                    Return True
                End If
            End If
        End Function

        'Public Sub FillProjectList(ByRef lst As CheckBoxList)

        '    Dim sql = "SELECT Colleges.College, Projects.ProjectID,Projects.ProjectNumber, Projects.ProjectName, "
        '    sql &= "  ISNULL(dbo.Projects.IsPassthroughProject, 0) AS IsPassthroughProject "
        '    sql &= " FROM Projects INNER JOIN "
        '    sql &= "Colleges ON Projects.CollegeID = Colleges.CollegeID "
        '    sql &= "WHERE Colleges.DistrictID = " & HttpContext.Current.Session("DistrictID") & " AND (ISNULL(dbo.Projects.IsPassthroughProject, 0) <> 1) "
        '    sql &= "ORDER BY Colleges.College, Projects.ProjectNumber, Projects.ProjectName"

        '    db.FillReader(sql)
        '    While db.Reader.Read

        '        Dim item As New ListItem
        '        item.Text = db.Reader("College") & " : (" & db.Reader("ProjectNumber") & ")" & db.Reader("ProjectName")
        '        item.Value = db.Reader("ProjectID")

        '        lst.Items.Add(item)
        '    End While

        '    db.Reader.Close()

        'End Sub
        Public Sub FillObjectCodeList(ByRef lst As DropDownList)

            Dim sql = "SELECT * FROM ObjectCodes WHERE DistrictID =" & HttpContext.Current.Session("DistrictID") & " ORDER BY ObjectCode "

            Dim tbl As DataTable = db.ExecuteDataTable(sql)
            For Each row As DataRow In tbl.Rows
                Dim item As New ListItem
                item.Text = row("ObjectCode") & " - " & row("ObjectCodeDescription")
                item.Value = row("ObjectCode")

                lst.Items.Add(item)
            Next



        End Sub


        Public Sub FillBondSeriesList(ByRef lst As DropDownList)

            Dim sql As String = "SELECT LookupValue As Val, LookupTitle as Lbl FROM dbo.Lookups WHERE ParentTable = 'Projects' AND ParentField = 'BondSeriesNumber' "
            sql = sql & "AND DistrictID = " & CallingPage.Session("DistrictID") & " ORDER By LookupTitle"
            Dim tbl As DataTable = db.ExecuteDataTable(sql)

            Dim item As New ListItem
            item.Value = "none"
            item.Text = "-- none --"
            lst.Items.Add(item)


            For Each row As DataRow In tbl.Rows
                item = New ListItem
                item.Value = ProcLib.CheckNullDBField(row("Val"))
                item.Text = ProcLib.CheckNullDBField(row("Lbl"))
                lst.Items.Add(item)
            Next

        End Sub

        Public Sub FillFiscalYearList(ByRef lst As DropDownList)
            Dim thisyear As Integer = DatePart(DateInterval.Year, Now())
            Dim twoyearsago As Integer = thisyear - 2
            Dim lastyear As Integer = thisyear - 1
            Dim nextyear As Integer = thisyear + 1

            With lst
                Dim item As New ListItem
                item.Value = Mid(CType(twoyearsago, String), 3) + Mid(CType(lastyear, String), 3)
                item.Text = Mid(CType(twoyearsago, String), 3) + "-" + Mid(CType(lastyear, String), 3)
                lst.Items.Add(item)

                item = New ListItem
                item.Value = Mid(CType(lastyear, String), 3) + Mid(CType(thisyear, String), 3)
                item.Text = Mid(CType(lastyear, String), 3) + "-" + Mid(CType(thisyear, String), 3)
                lst.Items.Add(item)

                item = New ListItem
                item.Value = Mid(CType(thisyear, String), 3) + Mid(CType(nextyear, String), 3)
                item.Text = Mid(CType(thisyear, String), 3) + "-" + Mid(CType(nextyear, String), 3)
                lst.Items.Add(item)

            End With

        End Sub


        Public Function GetProjectName(ByVal ProjectID) As String
            Return db.ExecuteScalar("SELECT ProjectName + '(' + ProjectNumber + ')' FROM Projects WHERE ProjectID = " & ProjectID)
        End Function

        Public Sub SavePassthroughAllocation(ByVal ParentProjectID As Integer)

            'Dim nPercent As Double = DirectCast(CallingPage.Form.FindControl("txtAllocationPercent"), Telerik.Web.UI.RadNumericTextBox).Value
            'Dim nTotalAllocation As Double = 0
            'Dim dEntryDate As Date = DirectCast(CallingPage.Form.FindControl("txtEntryDate"), Telerik.Web.UI.RadDatePicker).SelectedDate
            'Dim sDescription As String = DirectCast(CallingPage.Form.FindControl("txtDescription"), TextBox).Text
            'Dim sObjectCode As String = DirectCast(CallingPage.Form.FindControl("lstObjectCode"), DropDownList).SelectedValue
            'Dim sFiscalYear As String = DirectCast(CallingPage.Form.FindControl("lstFiscalYear"), DropDownList).SelectedValue
            'Dim sBondSeries As String = DirectCast(CallingPage.Form.FindControl("lstBondSeries"), DropDownList).SelectedValue


            'Dim lstProjects As CheckBoxList = DirectCast(CallingPage.Form.FindControl("lstProjects"), CheckBoxList)
            ''go through each project and get amounts total amount
            'Dim sTargetProjects As String = ""
            'For Each item As ListItem In lstProjects.Items
            '    If item.Selected = True Then
            '        sTargetProjects &= item.Value & ","
            '    End If
            'Next


            ''Create a placeholder parent entry so that we have parent key
            'Dim sql As String = "INSERT INTO PassthroughEntries (ProjectID) VALUES (" & ParentProjectID & ") ;SELECT NewKey = Scope_Identity()"  'return the new primary key"
            'Dim nNewParentPassthroughID As Integer = db.ExecuteScalar(sql)

            'Dim nTargetTotal As Double = 0
            'Dim nRows As Integer = 0
            'Dim sAction As String = ""
            'Dim sParentProjectName As String = GetProjectName(ParentProjectID)

            'Using dbTarget As New PromptDataHelper
            '    Dim row As DataRow
            '    dbTarget.FillDataTableForUpdate("SELECT * FROM PassThroughEntries WHERE PassThroughEntryID = 0")   'fill passthrough table

            '    Dim aProjList() As String = sTargetProjects.Split(",")
            '    For Each sID As String In aProjList     'create child entries
            '        If sID <> "" Then
            '            sql = "SELECT ISNULL(SUM(TotalAmount), 0) AS Total FROM Transactions "
            '            sql &= "WHERE ((Status = 'Paid' AND (TransType='Invoice' OR TransType='Credit')) OR TransType='Accrual') "
            '            sql &= " AND ProjectID = " & sID & " AND FiscalYear = '" & sFiscalYear & "' "

            '            nTargetTotal = db.ExecuteScalar(sql)

            '            If nTargetTotal > 0 Then
            '                Dim nAllocationAmount As Double = Proclib.Round(nTargetTotal * (nPercent / 100), 2)
            '                nTotalAllocation += nAllocationAmount

            '                Dim sTargetProjectName As String = GetProjectName(sID)
            '                sAction = "Allocated " & nPercent & " % of " & FormatCurrency(nTargetTotal) & " total expenses "
            '                sAction &= "to Object Code " & sObjectCode & " (from " & sParentProjectName & " to " & sTargetProjectName & ")"

            '                'Create TargetEntry
            '                row = dbTarget.DataTable.NewRow
            '                row("ProjectID") = sID
            '                row("ParentPassthroughEntryID") = nNewParentPassthroughID
            '                row("PassthroughProjectID") = ParentProjectID
            '                row("DistrictID") = HttpContext.Current.Session("DistrictID")
            '                row("CollegeID") = HttpContext.Current.Session("CollegeID")
            '                row("EntryDate") = dEntryDate
            '                row("Description") = sDescription
            '                row("ObjectCode") = sObjectCode
            '                row("BondSeriesNumber") = sBondSeries
            '                row("Amount") = nAllocationAmount
            '                row("Action") = sAction
            '                row("LastUpdateOn") = Now()
            '                row("LastUpdateBy") = HttpContext.Current.Session("UserName")
            '                row("FiscalYear") = sFiscalYear

            '                dbTarget.DataTable.Rows.Add(row)
            '                nRows += 1

            '            End If
            '        End If
            '    Next
            '    If nRows > 0 Then
            '        dbTarget.SaveDataTableToDB()
            '    End If

            '    'get new parent
            '    dbTarget.FillDataTableForUpdate("SELECT * FROM PassThroughEntries WHERE PassThroughEntryID = " & nNewParentPassthroughID)   'fill passthrough table
            '    row = dbTarget.DataTable.Rows(0)

            '    sAction = "Allocated " & nPercent & " % of each target project expenses "
            '    sAction &= "to Object Code " & sObjectCode & " for FY " & sFiscalYear

            '    'Create Parent
            '    row("ProjectID") = ParentProjectID
            '    row("ParentPassthroughEntryID") = nNewParentPassthroughID
            '    row("PassthroughProjectID") = ParentProjectID
            '    row("DistrictID") = HttpContext.Current.Session("DistrictID")
            '    row("CollegeID") = HttpContext.Current.Session("CollegeID")
            '    row("EntryDate") = dEntryDate
            '    row("Description") = sDescription
            '    row("ObjectCode") = sObjectCode
            '    row("BondSeriesNumber") = sBondSeries
            '    row("Amount") = nTotalAllocation * -1   'make negative
            '    row("Action") = sAction
            '    row("LastUpdateOn") = Now()
            '    row("LastUpdateBy") = HttpContext.Current.Session("UserName")
            '    row("FiscalYear") = sFiscalYear

            '     dbTarget.SaveDataTableToDB()

            'End Using

        End Sub

        Public Sub SaveEntry(ByVal EntryID As Integer)

            Dim dEntryDate As Date = DirectCast(CallingPage.Form.FindControl("txtEntryDate"), Telerik.Web.UI.RadDatePicker).SelectedDate
            Dim sDescription As String = DirectCast(CallingPage.Form.FindControl("txtDescription"), TextBox).Text
            Dim nAmount As Double = DirectCast(CallingPage.Form.FindControl("txtAmount"), Telerik.Web.UI.RadNumericTextBox).Value
            Dim nOldEntryAmt As Double = DirectCast(CallingPage.Form.FindControl("oldAmount"), HiddenField).Value

            Using dbTarget As New PromptDataHelper

                dbTarget.FillDataTableForUpdate("SELECT * FROM PassThroughEntries WHERE PassThroughEntryID = " & EntryID)   'fill passthrough table
                Dim row As DataRow = dbTarget.DataTable.Rows(0)

                'Get the parent entry ID 
                Dim nParentID As Integer = row("ParentPassthroughEntryID")

                'Create TargetEntry
                row("EntryDate") = dEntryDate
                row("Description") = sDescription
                row("Amount") = nAmount

                row("LastUpdateOn") = Now()
                row("LastUpdateBy") = HttpContext.Current.Session("UserName")

                dbTarget.SaveDataTableToDB()

                AdjustParentEntry(nOldEntryAmt, nAmount, nParentID) 'Must add the amount back to parent if changed

            End Using

        End Sub
        Private Sub AdjustParentEntry(ByVal OldAmount As Double, ByVal NewAmount As Double, ByVal ParentEntryID As Integer)
            'adjusts the parent entry when child entry is deleted or changed

            'Get the parent entry amount
            Dim nParentAmt As Double = db.ExecuteScalar("SELECT Amount FROM PassthroughEntries WHERE PassthroughEntryID = " & ParentEntryID)  'amount is negative number
            Dim nNewParentAmt As Double = nParentAmt + OldAmount - NewAmount
            db.ExecuteNonQuery("UPDATE PassthroughEntries SET Amount = " & nNewParentAmt & " WHERE PassthroughENtryID = " & ParentEntryID)


        End Sub

        Public Sub DeleteEntry(ByVal nEntryID As Integer, ByVal nProjectID As Integer)

            If IsPassthroughProject(nProjectID) Then
                db.ExecuteNonQuery("DELETE FROM PassThroughEntries WHERE PassthroughEntryID = " & nEntryID)
                db.ExecuteNonQuery("DELETE FROM PassThroughEntries WHERE ParentPassthroughEntryID = " & nEntryID)
            Else
                Dim nOldEntryAmt As Double = DirectCast(CallingPage.Form.FindControl("oldAmount"), HiddenField).Value
                Dim nEntryAmt As Double = 0     'will be zero as we are deleting
                Dim nParentID As Double = db.ExecuteScalar("SELECT ParentPassthroughEntryID FROM PassthroughEntries WHERE PassthroughEntryID = " & nEntryID)

                AdjustParentEntry(nOldEntryAmt, nEntryAmt, nParentID) 'Must add the amount back to parent if changed
                db.ExecuteNonQuery("DELETE FROM PassThroughEntries WHERE PassthroughEntryID = " & nEntryID)
            End If

        End Sub


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
