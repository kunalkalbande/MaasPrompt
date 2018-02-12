Imports System
Imports System.Web
Imports System.Web.UI.WebControls
Imports System.IO
Imports System.Data
Imports System.Data.SqlClient
Imports Telerik.Web.UI
Imports System.Text

Namespace Prompt

    '********************************************
    '*  Project Class
    '*  
    '*  Purpose: Processes data for the Project Object
    '*
    '*  Last Mod By:    Ford James
    '*  Last Mod On:    10/11/09
    '*
    '********************************************

    Public Class promptProject
        Implements IDisposable

        'Properties
        Public CallingPage As Page
        Public ProjectID As Integer = 0
        Public IsOriginalBudget As Boolean = False
        Public IsGlobalProject As Boolean = False
        Public IsPassthroughProject As Boolean = False
        Public BudgetBatchDescription As String = ""
        Public BudgetAmount As Double = 0
        Public LockCurrentBudgets As Boolean = False


        Private db As PromptDataHelper

        Public Sub New()
            db = New PromptDataHelper
        End Sub

#Region "Project Groups"

        Public Sub GetProjectGroupForEdit(ByVal nProjectGroupID As Integer)

            Dim sql As String = "SELECT LookupValue As Val, LookupTitle as Lbl FROM dbo.Lookups WHERE ParentTable = 'Projects' AND ParentField = 'Status' ORDER By LookupTitle"
            db.FillDropDown(sql, CallingPage.FindControl("lstStatus"))

            sql = "Select Name as Val, Name as Lbl From ProjectManagers Where DistrictID = (Select DistrictID From ProjectGroups Where ProjectGroupID = " & nProjectGroupID & ")"
            db.FillDropDown(sql, CallingPage.FindControl("lstProjectManager"))

            sql = "Select Name as Val, Name as Lbl From Contractors Where DistrictID = (Select DistrictID From ProjectGroups Where ProjectGroupID = " & nProjectGroupID & ")"
            db.FillDropDown(sql, CallingPage.FindControl("lstArchitect"))

            If nProjectGroupID > 0 Then
                db.FillForm(CallingPage.FindControl("Form1"), "SELECT * FROM ProjectGroups WHERE ProjectGroupID = " & nProjectGroupID)
            End If

        End Sub

        Public Function GetAllCollegeProjects(ByVal lst As Telerik.Web.UI.RadListBox, ByVal nCollegeID As Integer, ByVal ProjectGroupID As Integer) As String

            'Fill the sub project list - we also need to pass back a ProjectID/Status list to Validate the save to prevent changing Group
            'project status to any other status while there are active projects.
            Dim sProjectStatus As String = ""

            Dim sql As String = "SELECT ProjectID As Val, ProjectNumber + '-' + ProjectName as Lbl, ProjectGroupID, Status FROM Projects WHERE CollegeID = " & nCollegeID & " "
            sql &= "ORDER BY ProjectNumber + '-' + ProjectName "
            db.FillReader(sql)
            While db.Reader.Read()
                Dim bAdd As Boolean = True
                Dim nChildPGID As Integer = 0
                If Not IsDBNull(db.Reader("ProjectGroupID")) Then
                    nChildPGID = db.Reader("ProjectGroupID")
                End If
                If (nChildPGID > 0 And nChildPGID <> ProjectGroupID) Then   'Already Assigned Elsewhere so ignore
                    bAdd = False
                End If

                If bAdd Then
                    Dim item As New Telerik.Web.UI.RadListBoxItem
                    item.Text = db.Reader("Lbl")
                    item.Value = db.Reader("Val")

                    lst.Items.Add(item)

                    If nChildPGID = ProjectGroupID And ProjectGroupID > 0 Then
                        item.Checked = True
                    End If
                End If

                'Build the status/id string
                sProjectStatus &= "::" & db.Reader("Val") & "," & db.Reader("Status") & "::"

            End While
            db.Reader.Close()

            Return sProjectStatus

        End Function

        Public Sub GetProjectGroupInfo(ByVal UserCtrl As Control, ByVal ProjectGroupID As Integer)

            db.FillForm(UserCtrl, "SELECT * FROM ProjectGroups WHERE ProjectGroupID=" & ProjectGroupID)

            'Dim lblID As Label = UserCtrl.FindControl("lblProjectGroupID")
            'lblID.Text = ProjectGroupID


            ''get the PM name and display
            'Dim pm As Label = UserCtrl.FindControl("lblPM")
            'If Len(pm.Text) < 2 Then
            '    pm.Text = "-- Not Selected --"
            'Else
            '    'get the name of the PM from the id in the text
            '    sql = "SELECT Name FROM ProjectManagers WHERE PMID = " & pm.Text
            '    pm.Text = db.ExecuteScalar(sql)
            'End If

            ''get the GC name and display
            'Dim GC As Label = UserCtrl.FindControl("lblGC_Arch_ID")
            'If Len(GC.Text) < 2 Then
            '    GC.Text = "-- Not Selected --"
            'Else
            '    sql = "SELECT Name FROM Contractors WHERE ContractorID = " & GC.Text
            '    GC.Text = db.ExecuteScalar(sql)
            'End If

            ''get the ARch name and display
            'Dim arch As Label = UserCtrl.FindControl("lblArchID")
            'If Len(arch.Text) < 2 Then
            '    arch.Text = "-- Not Selected --"
            'Else
            '    sql = "SELECT Name FROM Contractors WHERE ContractorID = " & arch.Text
            '    arch.Text = db.ExecuteScalar(sql)
            'End If

        End Sub

        Public Function GetProjectGroupTotals(ByVal Category As String, ByVal ProjectGroupID As Integer) As Double

            'Calculates the totals in the summary box and returns number
            Dim result As Double = 0

            Dim sql As String = "SELECT * FROM Projects WHERE ProjectGroupID = " & ProjectGroupID
            Dim tbl As DataTable = db.ExecuteDataTable(sql)
            For Each Row As DataRow In tbl.Rows
                Dim rr = GetProjectTotals(Category, Row("ProjectID"))   'do not type cast because we don't know what is coming back
                If IsDBNull(rr) Then rr = 0
                result += rr
            Next

            Return result

        End Function

        Public Function SaveProjectGroup(ByVal nProjectGroupID As Integer, ByVal CollegeID As Integer) As Integer


            Dim sql As String = ""
            If nProjectGroupID = 0 Then   'new record
                sql = "INSERT INTO ProjectGroups (DistrictID, CollegeID) "
                sql &= "VALUES (" & HttpContext.Current.Session("DistrictID") & "," & CollegeID & ")"
                sql &= ";SELECT NewKey = Scope_Identity()"

                nProjectGroupID = db.ExecuteScalar(sql)

            End If

            'Update record
            db.SaveForm(CallingPage.Form, "SELECT * FROM ProjectGroups WHERE ProjectGroupID = " & nProjectGroupID)

            'Save SubProject Allocation 

            'set all existing assignments for this groupid = 0 
            sql = "UPDATE Projects SET ProjectGroupID = 0 WHERE ProjectGroupID = " & nProjectGroupID
            db.ExecuteNonQuery(sql)

            'Now reassign those that are still included
            Dim lst As Telerik.Web.UI.RadListBox = CallingPage.Form.FindControl("lstProjects")
            Dim sProjectList As String = ""
            For Each item As Telerik.Web.UI.RadListBoxItem In lst.CheckedItems
                sProjectList &= item.Value & ","
            Next
            If sProjectList <> "" Then
                sProjectList = Left(sProjectList, Len(sProjectList) - 1)      'remove last comma
                sql = "UPDATE Projects SET ProjectGroupID = " & nProjectGroupID & " WHERE ProjectID IN (" & sProjectList & ")"
                db.ExecuteNonQuery(sql)
            End If

            Return nProjectGroupID      'so that adding new have access on refresh

        End Function

        Public Sub DeleteProjectGroup(ByVal nProjectGroupID As Integer)

            db.ExecuteNonQuery("UPDATE Projects SET ProjectGroupID = 0 WHERE ProjectGroupID = " & nProjectGroupID)
            db.ExecuteNonQuery("DELETE FROM ProjectGroups WHERE ProjectGroupID = " & nProjectGroupID)

        End Sub

#End Region

#Region "Apprise Data"
        Public Function GetAppriseRecord(ByVal ProjectID As Integer) As DataTable
            ''this is kind of legacy from when apprise could be stand-alone
            ''checks to see if the apprise record exisits and adds if needed
            'Dim result As Integer = db.ExecuteScalar("SELECT Count(AppriseDataID) as recs FROM AppriseProjectData WHERE ProjectID = " & ProjectID)
            'If result = 0 Then
            '    db.ExecuteNonQuery("INSERT INTO AppriseProjectData (ProjectID) VALUES (" & ProjectID & ")")
            'End If
            Return db.ExecuteDataTable("SELECT * FROM Projects WHERE ProjectID = " & ProjectID)

        End Function

        Public Sub SaveAppriseData(ByVal ProjectID As Integer)

            Dim da As SqlDataAdapter
            da = New SqlDataAdapter("SELECT * FROM Projects WHERE ProjectID = " & ProjectID, ProcLib.GetDataConnectionString())
            Dim scb As New SqlCommandBuilder(da)

            Dim ds As New DataSet
            da.Fill(ds, "tbl")  'fill the dataset and name it
            Dim row As DataRow = ds.Tables("tbl").Rows(0)

            row("ProjectTitle") = DirectCast(CallingPage.Form.FindControl("txtProjectTitle"), TextBox).Text
            row("Description") = DirectCast(CallingPage.Form.FindControl("txtDescription"), Telerik.Web.UI.RadEditor).Content
            row("UsePromptName") = DirectCast(CallingPage.Form.FindControl("chkUsePromptTitle"), CheckBox).Checked
            row("UsePromptDescr") = DirectCast(CallingPage.Form.FindControl("chkUsePromptDescription"), CheckBox).Checked
            row("FundingSource") = DirectCast(CallingPage.Form.FindControl("txtFundingSource"), TextBox).Text
            row("FundingDescription") = DirectCast(CallingPage.Form.FindControl("txtFundingDescription"), TextBox).Text
            row("CurrentProjectCost") = DirectCast(CallingPage.Form.FindControl("txtCurrentProjectCost"), Telerik.Web.UI.RadNumericTextBox).Value

            row("PercentComplete") = Val(DirectCast(CallingPage.Form.FindControl("txtPercentComplete"), TextBox).Text)
            row("EstCompleteDate") = ProcLib.CheckDateField(DirectCast(CallingPage.Form.FindControl("txtEstCompleteDate"), Telerik.Web.UI.RadDatePicker).DbSelectedDate)

            row("UsePromptCompletionDate") = DirectCast(CallingPage.Form.FindControl("chkUsePromptCompletionDate"), CheckBox).Checked
            row("HideCompletionDate") = DirectCast(CallingPage.Form.FindControl("chkHideCompletionDate"), CheckBox).Checked

            row("UsePromptBudget") = DirectCast(CallingPage.Form.FindControl("chkUsePromptBudget"), CheckBox).Checked
            row("HidePercentComplete") = DirectCast(CallingPage.Form.FindControl("chkHidePercentComplete"), CheckBox).Checked

            row("UseManualBudgetAmount") = DirectCast(CallingPage.Form.FindControl("chkUseManualBudgetAmount"), CheckBox).Checked


            row("PublishToWeb") = DirectCast(CallingPage.Form.FindControl("chkPostToWeb"), CheckBox).Checked
            row("LastUpdateBy") = HttpContext.Current.Session("UserName")
            row("LastUpdateOn") = Now()


            da.Update(ds, "tbl")

            da = Nothing


        End Sub



#End Region



#Region "Projects"
        Public Function GetAllPMProjects(ByVal view As String) As DataTable

            If view = "" Then
                view = "MyProjects"
            End If

            Dim tbl As DataTable
            Dim sql As String = "SELECT Projects.DistrictID, Projects.ProjectName,Projects.Status, Projects.CollegeID, Projects.ProjectID, Contacts.Name AS PMName,"

            sql &= "(SELECT COUNT(RFIID) AS Tot FROM RFIs WHERE ProjectID = Projects.ProjectID) AS RFITotal, "
            sql &= "(SELECT COUNT(RFIID) AS Tot FROM RFIs WHERE ProjectID = Projects.ProjectID AND Status <> 'Answered' AND RequiredBy < '" & Now() & "') AS RFILate, "
            sql &= "(SELECT COUNT(RFIID) AS Tot FROM RFIs WHERE ProjectID = Projects.ProjectID AND Status <> 'Answered' AND RequiredBy BETWEEN '" & Now() & "' AND '" & DateAdd(DateInterval.Day, 3, Now()) & "') AS RFIWarning, "
            sql &= "(SELECT COUNT(RFIID) AS Tot FROM RFIs WHERE ProjectID = Projects.ProjectID AND Status <> 'Answered' AND RequiredBy > '" & DateAdd(DateInterval.Day, 3, Now()) & "') AS RFIOpen "
            sql &= ","
            sql &= "(SELECT COUNT(SubmittalID) AS Tot FROM Submittals WHERE ProjectID = Projects.ProjectID) AS SubmittalTotal, "
            sql &= "(SELECT COUNT(SubmittalID) AS Tot FROM Submittals WHERE ProjectID = Projects.ProjectID AND Status <> 'Closed' AND DateRequired < '" & Now() & "') AS SubmittalLate, "
            sql &= "(SELECT COUNT(SubmittalID) AS Tot FROM Submittals WHERE ProjectID = Projects.ProjectID AND Status <> 'Closed' AND DateRequired BETWEEN '" & Now() & "' AND '" & DateAdd(DateInterval.Day, 3, Now()) & "') AS SubmittalWarning, "
            sql &= "(SELECT COUNT(SubmittalID) AS Tot FROM Submittals WHERE ProjectID = Projects.ProjectID AND Status <> 'Closed' AND DateRequired > '" & DateAdd(DateInterval.Day, 3, Now()) & "') AS SubmittalOpen "
            sql &= " "

            sql &= "FROM Contacts INNER JOIN Projects ON Contacts.ContactID = Projects.PM "

            If view = "MyProjects" Then
                sql &= "WHERE Projects.Status='1-Active' AND Contacts.UserID = " & HttpContext.Current.Session("UserID") & " AND Projects.DistrictID = " & HttpContext.Current.Session("DistrictID") & " ORDER BY ProjectName"
            ElseIf view = "AllProjects" Then
                sql &= "WHERE Projects.Status='1-Active' AND Projects.DistrictID = " & HttpContext.Current.Session("DistrictID") & " ORDER BY Contacts.Name,ProjectName"

            Else   'this is other specific user

                sql &= "WHERE Projects.Status='1-Active' AND Contacts.ContactID = " & view & " AND Projects.DistrictID = " & HttpContext.Current.Session("DistrictID") & " ORDER BY ProjectName"


            End If

            tbl = db.ExecuteDataTable(sql)

            Dim col As New DataColumn
            col.DataType = Type.GetType("System.String")
            col.ColumnName = "RFIToolTip"
            tbl.Columns.Add(col)

            col = New DataColumn
            col.DataType = Type.GetType("System.String")
            col.ColumnName = "RFIStatus"
            tbl.Columns.Add(col)

            col = New DataColumn
            col.DataType = Type.GetType("System.String")
            col.ColumnName = "SubmittalToolTip"
            tbl.Columns.Add(col)

            col = New DataColumn
            col.DataType = Type.GetType("System.String")
            col.ColumnName = "SubmittalStatus"
            tbl.Columns.Add(col)

            col = New DataColumn
            col.DataType = Type.GetType("System.String")
            col.ColumnName = "ScheduleToolTip"
            tbl.Columns.Add(col)

            col = New DataColumn
            col.DataType = Type.GetType("System.String")
            col.ColumnName = "ScheduleStatus"
            tbl.Columns.Add(col)


            For Each row As DataRow In tbl.Rows

                Dim sTip As String = ""
                Dim sItem As String = "RFI"
                Dim nTotal As Integer = row(sItem & "Total")
                Dim nLate As Integer = row(sItem & "Late")
                Dim nWarning As Integer = row(sItem & "Warning")
                Dim nOpen As Integer = row(sItem & "Open")

                If nTotal = 0 Then
                    row(sItem & "Status") = "none"
                ElseIf nLate > 0 Then
                    row(sItem & "Status") = "late"
                ElseIf nWarning > 0 Then
                    row(sItem & "Status") = "warning"
                Else
                    row(sItem & "Status") = "ok"
                End If


                sTip = "   Total RFIs: " & nTotal & " <Br/>"
                sTip &= "   Late RFIs: " & nLate & " <Br/>"
                sTip &= "Warning RFIs: " & nWarning & " <Br/>"
                sTip &= "   Open RFIs: " & nOpen

                row(sItem & "ToolTip") = sTip


                sItem = "Submittal"
                nTotal = row(sItem & "Total")
                nLate = row(sItem & "Late")
                nWarning = row(sItem & "Warning")
                nOpen = row(sItem & "Open")

                If nTotal = 0 Then
                    row(sItem & "Status") = "none"
                ElseIf nLate > 0 Then
                    row(sItem & "Status") = "late"
                ElseIf nWarning > 0 Then
                    row(sItem & "Status") = "warning"
                Else
                    row(sItem & "Status") = "ok"
                End If

                sTip = "Total Submittals: " & nTotal & " <Br/>"
                sTip &= "Late Submittals: " & nLate & " <Br/>"
                sTip &= "Warning Submittals: " & nWarning & " <Br/>"
                sTip &= "Open Submittals: " & nOpen
                row(sItem & "ToolTip") = sTip

                sItem = "Schedule"
                nTotal = row(sItem & "Total")
                nLate = row(sItem & "Late")
                nWarning = row(sItem & "Warning")

                If nTotal = 0 Then
                    row(sItem & "Status") = "none"
                ElseIf nLate > 0 Then
                    row(sItem & "Status") = "late"
                ElseIf nWarning > 0 Then
                    row(sItem & "Status") = "warning"
                Else
                    row(sItem & "Status") = "ok"
                End If

                sTip = "Total Schedule Items: " & nTotal & " <Br/>"
                sTip &= "Late Schedule Items: " & nLate & " <Br/>"
                sTip &= "Warning Schedule Items: " & nWarning & " <Br/>"
                row(sItem & "ToolTip") = sTip



            Next


            Return tbl
        End Function

        Public Sub LoadDashboardProjectManagers(ByVal lst As DropDownList)
            'loads the pm list for the pm dashboard
            Dim nCurUserID As Integer = HttpContext.Current.Session("UserID")
            Dim sql As String = "SELECT Contacts.* FROM Contacts "
            sql &= "WHERE DistrictID = " & HttpContext.Current.Session("DistrictID") & " AND ContactType='ProjectManager' AND Inactive <> 1 ORDER BY Name"

            Dim tbl As DataTable = db.ExecuteDataTable(sql)

            Dim item As New ListItem
            item.Text = "My Active Projects"
            item.Value = "MyProjects"
            item.Selected = True
            lst.Items.Add(item)

            item = New ListItem
            item.Text = "All Active Projects"
            item.Value = "AllProjects"
            lst.Items.Add(item)

            For Each row As DataRow In tbl.Rows
                'Dim uid As Integer = ProcLib.CheckNullNumField(row("UserID"))
                item = New ListItem
                item.Text = row("Name")
                item.Value = row("ContactID")
                lst.Items.Add(item)
            Next

        End Sub


        Public Sub GetProjectInfo(ByVal UserCtrl As Control, ByVal ProjectID As Integer)

            Dim sql As String = ""

            Dim row As DataRow = db.GetDataRow("SELECT * FROM qry_GetPromptProject WHERE ProjectID=" & ProjectID)
            db.FillForm(UserCtrl, row)

            Dim lblID As Label = UserCtrl.FindControl("lblProjectID")
            lblID.Text = row("ProjectID")

            If Not IsDBNull(row("IsPassthroughProject")) Then
                If row("IsPassthroughProject") = 1 Then
                    IsPassthroughProject = True
                End If
            End If


            ''Get the current budget batch description
            'Dim Batch As Label = UserCtrl.FindControl("lblBudgetChangeBatch")
            'If row("CurrentBudgetBatchID") = 0 Then
            '    Batch.Text = "(Initial Budget)"
            'Else
            '    'look up the description
            '    sql = "SELECT Description FROM BudgetChangeBatches WHERE BudgetChangeBatchID = " & row("CurrentBudgetBatchID")
            '    Batch.Text = db.ExecuteScalar(sql)
            'End If

            'get the PM name and display
            Dim pm As Label = UserCtrl.FindControl("lblPM")
            If Len(pm.Text) < 2 Then
                pm.Text = "-- Not Selected --"
            Else
                'get the name of the PM from the id in the text
                sql = "SELECT Name FROM Contacts WHERE ContactID = " & pm.Text
                pm.Text = db.ExecuteScalar(sql)
            End If

            'get the GC name and display
            Dim GC As Label = UserCtrl.FindControl("lblGC_Arch_ID")
            If Len(GC.Text) < 2 Then
                GC.Text = "-- Not Selected --"
            Else
                sql = "SELECT Name FROM Contacts WHERE ContactID = " & GC.Text
                GC.Text = db.ExecuteScalar(sql)
            End If

            'get the ARch name and display
            Dim arch As Label = UserCtrl.FindControl("lblArchID")
            If Len(arch.Text) < 2 Then
                arch.Text = "-- Not Selected --"
            Else
                sql = "SELECT Name FROM Contacts WHERE ContactID = " & arch.Text
                arch.Text = db.ExecuteScalar(sql)
            End If

            'get the CM name and display
            Dim CM As Label = UserCtrl.FindControl("lblCMID")
            If Len(CM.Text) < 2 Then
                CM.Text = "-- Not Selected --"
            Else
                sql = "SELECT Name FROM Contacts WHERE ContactID = " & CM.Text
                CM.Text = db.ExecuteScalar(sql)
            End If

        End Sub

        Public Sub GetNewProject()

            'populates the parent form with new project record
            'get a blank record and populate with initial info
            Dim sql As String = "select * from projects where projectid = 0"
            Dim dt As DataTable
            Dim row As DataRow
            dt = db.ExecuteDataTable(sql)
            row = dt.NewRow()
            LoadEditForm(row)

        End Sub

        Public Sub GetExistingProject(ByVal nProjectID As Integer)

            'populates the parent form with project record
            ProjectID = nProjectID   'set class property with passed id

            'get project record and populate with info
            Dim row As DataRow
            row = db.GetDataRow("SELECT * FROM qry_GetPromptProject WHERE ProjectID = " & ProjectID)

            'pass the row to routine to populate form
            LoadEditForm(row)

            ''Check to see if this is the original budget and if so, then allow direct editing of the 
            ''budget with no explanation

            'BudgetBatchDescription = "(Inital Budget)"
            'If row("CurrentBudgetBatchID") > 0 Then  'this is not the original budget
            '    IsOriginalBudget = False

            '    'Check to see if current budget = 0  -- if so allow direct change
            '    If row("OrigBudget") = 0 Then
            '        If row("LockCurrentProjectBudgets") = 0 Then  'allow changes
            '            LockCurrentBudgets = False
            '        End If
            '    Else
            '        'get the batch description
            '        Dim ss As String = "SELECT Description FROM BudgetChangeBatches WHERE BudgetChangeBatchID = " & row("CurrentBudgetBatchID")
            '        BudgetBatchDescription = db.ExecuteScalar(ss)
            '        If row("LockCurrentProjectBudgets") = 1 Then  'project budget is locked so disallow changes
            '            LockCurrentBudgets = True
            '        Else
            '            LockCurrentBudgets = True
            '        End If
            '    End If
            'Else      'there are no budget change batches
            '    If row("LockCurrentProjectBudgets") = 0 Then  'allow changes
            '        LockCurrentBudgets = False
            '    End If
            'End If

            ''check to see if this project has any global contracts allocated to it and if so disable makeing this project global
            'Dim sql As String = "SELECT Count(GlobalContractID) as CNT FROM Contracts WHERE ProjectID = " & ProjectID & " AND GLobalContractID > 0 "
            'Dim cnt As Integer = db.ExecuteScalar(sql)
            'If cnt > 0 Then
            '    IsGlobalProject = True
            'End If

        End Sub

        Public Sub GetAdditionalProjectData(ByVal nProjectID As Integer)

            Dim sql As String = "SELECT * FROM Projects WHERE ProjectID = " & nProjectID
            db.FillForm(CallingPage.FindControl("Form1"), sql)

        End Sub

        Public Sub GetSubmittalData(ByVal nProjectID As Integer)

            Dim sql As String = "SELECT * FROM Projects WHERE ProjectID = " & nProjectID
            db.FillForm(CallingPage.FindControl("Form1"), sql)

        End Sub


        Private Sub LoadEditForm(ByVal row As DataRow)

            'loads a parent form with data from passed row

            Dim form As Control = CallingPage.FindControl("Form1")  ' get ref to calling form

            Dim nDistrictID As Integer = CallingPage.Session("DistrictID")
            Dim sql As String = ""

            'Fill the dropdown controls on parent form
            sql = "SELECT ContactID As Val, Name as Lbl FROM dbo.Contacts WHERE ContactType='ProjectManager' AND (DistrictID = " & CallingPage.Session("DistrictID") & " OR DistrictID = 0) ORDER BY Name ASC"
            db.FillDropDown(sql, form.FindControl("lstPM"), False, True, False)

            sql = "SELECT LookupValue As Val, LookupTitle as Lbl FROM dbo.Lookups WHERE ParentTable = 'Projects' AND ParentField = 'Status' ORDER By LookupTitle"
            db.FillDropDown(sql, form.FindControl("lstStatus"))

            sql = "SELECT ContactID As Val, Name as Lbl FROM Contacts WHERE ContactType='Company' AND (DistrictID = " & CallingPage.Session("DistrictID") & " OR DistrictID = 0) ORDER BY NAME"
            db.FillDropDown(sql, form.FindControl("lstGC_Arch_ID"), True, True, False)

            sql = "SELECT ContactID As Val, Name as Lbl FROM Contacts WHERE ContactType='Company' AND (DistrictID = " & CallingPage.Session("DistrictID") & " OR DistrictID = 0) ORDER BY NAME"
            db.FillDropDown(sql, form.FindControl("lstArchID"), True, True, False)

            sql = "SELECT ContactID As Val, Name as Lbl FROM Contacts WHERE ContactType='Company' AND (DistrictID = " & CallingPage.Session("DistrictID") & " OR DistrictID = 0) ORDER BY NAME"
            db.FillDropDown(sql, form.FindControl("lstCMID"), True, True, False)

            sql = "SELECT LookupValue As Val, LookupTitle as Lbl FROM dbo.Lookups WHERE ParentTable = 'Projects' AND ParentField = 'BondSeriesNumber' "
            sql = sql & "AND DistrictID = " & CallingPage.Session("DistrictID") & " ORDER By LookupTitle"
            db.FillDropDown(sql, form.FindControl("lstBondSeriesNumber"), False, False, False)


            sql = "SELECT LookupValue As Val, LookupTitle as Lbl FROM dbo.Lookups WHERE ParentTable = 'Projects' AND ParentField = 'ActivityCode' AND "
            sql = sql & "DistrictID = " & CallingPage.Session("DistrictID") & " ORDER By LookupValue"
            db.FillDropDown(sql, form.FindControl("lstActivityCode"), True, False, True)

            sql = "SELECT LookupValue As Val, LookupTitle as Lbl FROM dbo.Lookups WHERE ParentTable = 'Projects' AND ParentField = 'Category' AND "
            sql = sql & "DistrictID = " & CallingPage.Session("DistrictID") & " ORDER By LookupValue"
            db.FillDropDown(sql, form.FindControl("lstCategory"), True, False, False)

            sql = "SELECT LookupValue As Val, LookupTitle as Lbl FROM dbo.Lookups WHERE ParentTable = 'Projects' AND ParentField = 'Phase' AND "
            sql = sql & "DistrictID = " & CallingPage.Session("DistrictID") & " ORDER By LookupValue"
            db.FillDropDown(sql, form.FindControl("lstPhase"), True, False, False)

            sql = "Select State as Val, State as Lbl From (Select 'ok' as State Union Select 'caution' Union Select 'problem' Union Select 'N/A' Union Select '') as qry"
            db.FillDropDown(sql, form.FindControl("lstPE_Status_Cost"), False, False, False)

            sql = "Select State as Val, State as Lbl From (Select 'ok' as State Union Select 'caution' Union Select 'problem' Union Select 'N/A' Union Select '') as qry"
            db.FillDropDown(sql, form.FindControl("lstPE_Status_Schedule"), False, False, False)

            'sql = "Select State as Val, State as Lbl From (Select 'ok' as State Union Select 'caution' Union Select 'problem' Union Select 'N/A' Union Select '') as qry"
            'db.FillDropDown(sql, form.FindControl("lstCMDM_Status"), False, False, False)

            db.FillForm(form, row)


        End Sub

        Public Sub SaveProject(ByVal CollegeID As Integer, ByVal nProjectID As Integer)

            Dim bIsNew As Boolean = False

            ProjectID = nProjectID   'set class property with passed id

            Dim sql As String = ""
            'Check if this is a new project
            If ProjectID = 0 Then
                'Add Master Project Record
                sql = "INSERT INTO Projects "
                sql = sql & "(ClientID,DistrictID,CollegeID) "
                sql = sql & "VALUES  (" & CallingPage.Session("ClientID") & "," & CallingPage.Session("DistrictID") & "," & CollegeID & ") "
                sql = sql & ";SELECT NewKey = Scope_Identity()"  'return the new primary key

                ProjectID = db.ExecuteScalar(sql)
                bIsNew = True

                'Create the Attachments Dir
                Dim att As New promptAttachment
                With att
                    .DistrictID = CallingPage.Session("DistrictID")
                    .CollegeID = CollegeID
                    .ProjectID = ProjectID
                    .CreateAttachmentDir()
                End With

            End If

            'Update the ProjectID label on the form as it will be included in save form
            DirectCast(CallingPage.Form.FindControl("lblProjectID"), Label).Text = ProjectID

            'Update Projects 
            db.SaveForm(CallingPage.Form, "SELECT * FROM Projects WHERE ProjectID = " & ProjectID)

            If bIsNew Then    ''Update ProjectTitle and bondTitle
                sql = "UPDATE Projects SET ProjectTitle = ProjectName, bondDisplayTitle = ProjectName, IsPromptProject = 1 WHERE ProjectID = " & ProjectID
                db.ExecuteNonQuery(sql)
            End If


            ProcLib.VerifyBudgetReportingTable(ProjectID)    'make sure any changes to Start/End date are accomodated in budgetreproting table

            'HACK: Make sure that BondFundCategory = Category -- This is legacy in case reports are depending on bond fund category field
            Dim lstcat As DropDownList = DirectCast(CallingPage.Form.FindControl("lstCategory"), DropDownList)
            sql = "UPDATE Projects SET BondFundCategory = '" & lstcat.SelectedValue & "' WHERE ProjectID = " & ProjectID
            db.ExecuteNonQuery(sql)



        End Sub



        Public Function DeleteProject(ByVal ProjectID As Integer) As String

            Dim msg As String = ""
            Dim bQuit As Boolean = False

            Dim sql As String = "SELECT COUNT(ContractID) as TOT FROM Contracts WHERE ProjectID =" & ProjectID
            Dim cnt As Integer = db.ExecuteScalar(sql)
            If cnt > 0 Then
                bQuit = True
                msg = msg & ";Contracts;"
            End If

            sql = "SELECT COUNT(NoteID) as TOT FROM Notes WHERE ProjectID = " & ProjectID
            cnt = db.ExecuteScalar(sql)
            If cnt > 0 Then
                bQuit = True
                msg = msg & ";Notes;"
            End If

            sql = "SELECT COUNT(AttachmentID) as TOT FROM Attachments WHERE ProjectID = " & ProjectID
            cnt = db.ExecuteScalar(sql)
            If cnt > 0 Then
                bQuit = True
                msg = msg & ";Attachments;"
            End If

            sql = "SELECT COUNT(BudgetItemID) as TOT FROM BudgetItems WHERE ProjectID = " & ProjectID
            cnt = db.ExecuteScalar(sql)
            If cnt > 0 Then
                bQuit = True
                msg = msg & ";BudgetItems;"
            End If



            If bQuit = True Then
                msg = "There are various associated records (" & msg & ") related to this Project so it cannot be deleted."
            Else
                db.ExecuteNonQuery("DELETE FROM Projects WHERE ProjectID = " & ProjectID)
            End If

            Return msg

        End Function


        Public Sub SaveAdditionalData(ByVal nProjectID As Integer)

            ProjectID = nProjectID   'set class property with passed id

            'Update PromptProjectData
            db.SaveForm(CallingPage.Form, "SELECT * FROM Projects WHERE ProjectID = " & nProjectID)


        End Sub

        Public Sub SaveSubmittalData(ByVal nProjectID As Integer)

            ProjectID = nProjectID   'set class property with passed id

            'Update PromptProjectData
            db.SaveForm(CallingPage.Form, "SELECT * FROM Projects WHERE ProjectID = " & nProjectID)


        End Sub

        Public Function GetProjectTotals(ByVal Category As String, ByVal id As Integer) As Double

            'Calculates the totals in the summary box and returns number

            Dim sql As New StringBuilder
            With sql
                Select Case Category
                    Case "Contracts"
                        .Append("SELECT SUM(Amount) AS nAmt FROM ContractLineItems WHERE ProjectID = " & id & " AND LineType = 'Contract'  AND Reimbursable = 0")

                    Case "Adjustments"
                        .Append("SELECT SUM(Amount) AS nAmt FROM ContractLineItems WHERE ProjectID = " & id & " AND LineType = 'Adjustment' ")

                    Case "Reimbursables"
                        .Append("Select Sum(Amount) as nAmt From ContractLineItems Where ProjectID = " & id & " AND Reimbursable = 1")
                    Case "Transactions"
                        .Append("SELECT SUM(Amount) AS nAmt FROM TransactionDetail ")
                        .Append("WHERE ProjectID = " & id)

                    Case "Amendments"
                        .Append("SELECT SUM(Amount) AS nAmt FROM ContractLineItems WHERE ProjectID = " & id & " AND LineType = 'ChangeOrder'")

                    Case "Bond"
                        .Append("SELECT SUM(Amount) AS nAmt FROM BudgetItems ")
                        .Append("WHERE BudgetField LIKE '%Bond%' AND ProjectID = " & id)

                    Case "State"
                        .Append("SELECT SUM(Amount) AS nAmt FROM BudgetItems ")
                        .Append("WHERE BudgetField LIKE '%SF%' AND ProjectID = " & id)

                    Case "Other"   'donation,grant,maint,hazmat
                        .Append("SELECT SUM(Amount) AS nAmt FROM BudgetItems ")
                        .Append("WHERE (BudgetField Like '%Donation%' OR BudgetField LIKE '%Maint%' ")
                        .Append(" OR BudgetField LIKE '%Hazmat%' OR BudgetField LIKE '%Grant%') AND ProjectID = " & id)

                    Case "Passthrough"   'Passthrough Account
                        .Append("SELECT SUM(Amount) AS nAmt FROM PassThroughEntries ")
                        .Append("WHERE  ProjectID = " & id)

                    Case "LedgerAccount"
                        .Append("SELECT SUM(Amount) AS nAmt FROM LedgerAccountEntries WHERE BudgetObjectCodeID = 0 AND ProjectID = " & id)

                End Select
            End With
            Dim rr = db.ExecuteScalar(sql.ToString)   'do not type cast because we don't know what is coming back
            If IsDBNull(rr) Then rr = 0
            Return rr

        End Function

        Public Function CheckProjectBudgetWithJCAF(ByVal id As Integer, ByVal ProjectBudget As Double) As Boolean

            'Checks that the JCAF total matches the Project Budget Total
            Dim sql As String
            Dim JCAF
            sql = "SELECT SUM(Amount) AS Total FROM BudgetItems WHERE ProjectID =" & id
            JCAF = db.ExecuteScalar(sql)
            If IsDBNull(JCAF) Then
                JCAF = 0
            End If

            If JCAF <> ProjectBudget Then
                Return False
            Else
                Return True
            End If

        End Function

        Public Function CheckForDupProjNumSubNum(ByVal id As Integer) As Boolean

            'Checks for duplicate ProjectNumber-ProjectSubNumber
            Dim nDistrictID As Integer = CallingPage.Session("DistrictID")
            Dim Duplicate As Integer
            Dim sql As String
            sql = "Declare @Dist int, @ProjID int; Set @Dist =" & nDistrictID & "; Set @ProjID =" & id
            sql += "; Declare @PN varchar(100), @PSN varchar(100); "
            sql += "Select @PN = ProjectNumber, @PSN = ProjectSubNumber From Projects Where ProjectID = @ProjID; "
            sql += "Select Count(*) From Projects P Where DistrictID = @Dist and P.ProjectNumber = @PN and P.ProjectSubNumber = @PSN"
            Duplicate = db.ExecuteScalar(sql)
            If Duplicate > 1 Then
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
