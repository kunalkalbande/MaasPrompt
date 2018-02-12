<%@ Page Language="VB" MasterPageFile="~/content.master" Title="" %>

<%@ Register Assembly="Telerik.Web.UI" Namespace="Telerik.Web.UI" TagPrefix="telerik" %>
<%@ Import Namespace="Prompt" %>

<script runat="server">
    
    Private nProjectID As Integer = 0
    Private bTeamMembersReadOnly As Boolean = True
    Private bContractsReadOnly As Boolean = True
    Private bProjectReadOnly As Boolean = True

    Private TransAmount As Double = 0
    Private PassthroughAmount As Double = 0
    
    Private BondTotal As Double = 0
    Private StateTotal As Double = 0
    Private OtherTotal As Double = 0
    Private BudgetTotal As Double = 0
    
    Private Adjustments As Double = 0
    
    Private LedgerAccountAdjustments As Double = 0
    
    Private ContractTotals As Double = 0
    Private UnencumberedProjectBalance As Double = 0
    Private Uncommitted As Double = 0
    
    
    Protected Sub Page_Init(ByVal sender As Object, ByVal e As System.EventArgs)
        nProjectID = Request.QueryString("ProjectID")
        
        
        If Not IsPostBack Then
            Dim sSettings As String = ""
            Using db As New promptUserPrefs
                db.LoadGridSettings(gridTeamMembers, "PMTeamMemberWidgetGridSettings", "ProjectID", nProjectID)
                db.LoadGridColumnVisibility(gridTeamMembers, "PMTeamMemberWidgetColumnSettings", "ProjectID", nProjectID)

                sSettings = db.LoadGridGroupCollapseState("PMTeamMemberWidgetGroupSettings", "ProjectID", nProjectID)    'Load saved ExpandCollapse Settings
            End Using
        
            If sSettings <> "" Then
                Dim aSettings As String() = sSettings.Split("::")
                'Get current state pre click
                For Each item As GridItem In gridTeamMembers.MasterTableView.Controls(0).Controls
                    If item.ItemType = GridItemType.GroupHeader Then
                        Dim grp As GridGroupHeaderItem = item
                        Dim grptxt As String = grp.DataCell.Text
                    
                        For Each sset As String In aSettings
                            Dim sItem As String() = sset.Split(",")
                            Dim sTxt As String = sItem(0)
                            If sTxt = grptxt Then
                                If sItem(1) = "False" Then
                                    grp.Expanded = False
                                Else
                                    grp.Expanded = True
                                End If
                            
                            End If
                        
                        Next
                    
                    End If
                Next
            End If
            
                  
        End If
        
        
    End Sub
    
    Protected Sub Page_PreRender(ByVal sender As Object, ByVal e As System.EventArgs)
        Using db As New promptUserPrefs
            db.SaveGridSettings(gridTeamMembers, "PMTeamMemberWidgetGridSettings", "ProjectID", nProjectID)
                      
        End Using
        
 
    End Sub

    

    Private Sub Page_Load(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MyBase.Load

        Session("PageID") = "ProjectInfo"
        nProjectID = Request.QueryString("ProjectID")
        ProcLib.LoadPopupJscript(Page)                  'needed for project edit and add contract
        
        'Since this is the primary calling page from the Nav menu, we need to check if current view is something other than
        'Overview and if so redirect
        Dim masterTabs As RadTabStrip = Master.FindControl("tabMain")
        Dim sNewLocation As String = ""
        If Request.QueryString("t") <> "y" Then
            If Session("CurrentTab") <> "Overview" Then   'redirect to appropriate tab if available
                For Each radTab In masterTabs.GetAllTabs
                    If radTab.Value = Session("CurrentTab") Then
                        radTab.Selected = True
                        radTab.SelectParents()
                        Response.Redirect(radTab.NavigateUrl)
                        Exit For
                    End If
                Next
            End If
        End If
        Session("CurrentTab") = "Overview"
        'if we have not redirected then we are at the right place
        For Each radTab In masterTabs.GetAllTabs
            If radTab.Value = "Overview" Then
                radTab.Selected = True
                radTab.SelectParents()
                Exit For
            End If
        Next
        
        lblProjectName.Text = DirectCast(Master.FindControl("lblViewTitle"), Label).Text
        

        If Session("delproject") <> True Then    'to prevent reload on postback after deleting the record

            Using db As New promptProject      'get the project record 
                db.CallingPage = Page
            
                db.GetProjectInfo(contentPanel1, nProjectID)
            
                If db.IsPassthroughProject Then
                    lblPassthroughProject.Visible = True
                Else
                    lblPassthroughProject.Visible = False
                End If
                TransAmount = db.GetProjectTotals("Transactions", nProjectID)

                PassthroughAmount = db.GetProjectTotals("Passthrough", nProjectID)
                
                Adjustments = db.GetProjectTotals("Adjustments", nProjectID)
                
                LedgerAccountAdjustments = db.GetProjectTotals("LedgerAccount", nProjectID)
            
                BondTotal = db.GetProjectTotals("Bond", nProjectID)
                StateTotal = db.GetProjectTotals("State", nProjectID)
                OtherTotal = db.GetProjectTotals("Other", nProjectID)
                BudgetTotal = BondTotal + StateTotal + OtherTotal
            

                If Not db.CheckProjectBudgetWithJCAF(nProjectID, IIf(lblOrigBudget.Text <> "", lblOrigBudget.Text, 0)) Then
                    'lblBudgetWarning.Visible = True  commented out by roy 2/12/08
                End If
        
                If db.CheckForDupProjNumSubNum(nProjectID) Then
                    lblDuplicateProjectNum.Visible = True
                End If
            End Using
        
            'Look for flags
            lnkFlag.Visible = False
            Using db As New promptFlag
                db.ParentRecType = "Project"
                db.ParentRecID = nProjectID
                If db.FlagExists() Then
                    lnkFlag.Visible = True
                    lnkFlag.Attributes.Add("onclick", "openPopup('flag_edit.aspx?ParentRecID=" & nProjectID & "&ParentRecType=Project','showFlag',500,400,'yes');")
                End If
            End Using

            Dim nContTot As Decimal
            Using dbCont As New PromptDataHelper
                nContTot = dbCont.ExecuteScalar("SELECT IsNull(SUM(Amount),0) FROM ContractLineItems WHERE ProjectID = " & nProjectID)
            End Using
            
            
            ContractTotals = Math.Round(nContTot, 2, MidpointRounding.AwayFromZero)
            UnencumberedProjectBalance = Math.Round(BudgetTotal - ContractTotals - PassthroughAmount, 2, MidpointRounding.AwayFromZero)
        
            If UnencumberedProjectBalance < 0 Then
                lblBudgetWarning.Visible = True
                lblBudgetWarning.Text = "Warning:Project is Overencumbered!"
                lblBudgetWarning.CssClass = "red"
            End If
        
            lblJCAFTotalBudget.Text = FormatCurrency(BudgetTotal, -1, -2, -1, -2)
            lblJCAFTotalBudget.ToolTip = "All JCAF columns included"
            lblContractTotals.Text = FormatCurrency(ContractTotals, -1, -2, -1, -2)
            lblContractTotals.ToolTip = "Includes ALL Contract Line Items in the project (approved and unapproved)"
            lblTransAmount.Text = FormatCurrency(TransAmount, -1, -2, -1, -2)
            lblTransAmount.ToolTip = "All (paid and unpaid) Transactions to date"
            lblPassthrough.Text = FormatCurrency(PassthroughAmount, -1, -2, -1, -2)
            lblPassthrough.ToolTip = "Overhead Expenditures passed-on to this Project"
            lblUnencumberedProjectBalance.Text = FormatCurrency(UnencumberedProjectBalance, -1, -2, -1, -2)
            lblUnencumberedProjectBalance.ToolTip = "Unencumbered Project Balance = Total Budget - Total Contracts - Total Passthrough Expenses"
            
            lblLedgerAccountAdjustments.Text = FormatCurrency(LedgerAccountAdjustments, -1, -2, -1, -2)
            lblLedgerAccountAdjustments.ToolTip = "Sum of all Ledger Entries, debit & credit (including both, Interest and Credit Ledgers)"
 
            'TODO - move DB stuff to a class file
            'set up hyperlink for Budget Cost Report
            Dim nProjNum As String
            Using dbBCR As New PromptDataHelper
                nProjNum = dbBCR.ExecuteScalar("Select Cast(ProjectNumber as varchar(100)) + Coalesce(ProjectSubNumber,'') From Projects Where ProjectID = " & nProjectID)
            End Using
            'callBCR.NavigateUrl = "http://216.129.104.66/q34jf8sfa?/PromptReports/BudgetCost_Report&Dist=55&G_Projects=" & nProjNum & "&rc:Parameters=false"

            callBCR.Visible = False
            
            'Set color of status 
            If lblStatus.Text = "2-Proposed" Then
                lblStatus.Text = "Proposed"
                lblStatus.CssClass = "orange"
            ElseIf lblStatus.Text = "3-Suspended" Or lblStatus.Text = "4-Cancelled" Then
                lblStatus.Text = " " & Mid(lblStatus.Text, 3) & " "
                lblStatus.CssClass = "red"
            ElseIf lblStatus.Text = "5-Complete" Then
                lblStatus.Text = "Complete"
                lblStatus.CssClass = "blue"
            ElseIf lblStatus.Text = "6-Consolidated" Then
                lblStatus.Text = "Consolidated"
                lblStatus.CssClass = "orange"
            ElseIf lblStatus.Text = "7-Deferred" Then
                lblStatus.Text = "Deferred"
                lblStatus.ForeColor = Color.DarkViolet
            Else
                lblStatus.Text = "Active"
                lblStatus.CssClass = "green"
            End If
            
            If lblPriorQuarter_Status.text.Length > 3
                lblPriorQuarter_Status.text =  lblPriorQuarter_Status.text.Substring(2)
            End if

            'format the budget currency
            If lblOrigBudget.Text <> "" Then
                lblOrigBudget.Text = FormatCurrency(lblOrigBudget.Text)
            End If


 
            SetSecurity()
         
        Else
            Session("delproject") = False       'we just deleted a project so needed to load page, then redirect to parent college
        End If
        
        ConfigurePopupWindows()
        
        ConfigureWidgetGrids()

        BuildMenu()
   
    End Sub
    
    Private Sub ConfigurePopupWindows()
        'Configure the Popup Window(s)
        With contentPopups
            .VisibleOnPageLoad = False
            .Skin = "Windows7"
            Dim ww As New Telerik.Web.UI.RadWindow
            ww = New Telerik.Web.UI.RadWindow
            With ww
                .ID = "EditNoteWindow"
                .NavigateUrl = ""
                .Title = ""
                .Width = 500
                .Height = 475
                .Modal = True
                .VisibleStatusbar = False
                .ReloadOnShow = True
            End With
            .Windows.Add(ww)
            
            ww = New Telerik.Web.UI.RadWindow
            With ww
                .ID = "ManageTeamMembersWindow"
                .NavigateUrl = ""
                .Title = ""
                .Width = 750
                .Height = 475
                .Modal = True
                .VisibleStatusbar = False
                .ReloadOnShow = True
            End With
            .Windows.Add(ww)

            ww = New Telerik.Web.UI.RadWindow
            With ww
                .ID = "EditTeamMemberWindow"
                .NavigateUrl = ""
                .Title = ""
                .Width = 525
                .Height = 650
                .Modal = True
                .VisibleStatusbar = False
                .ReloadOnShow = True
            End With
            .Windows.Add(ww)
            
        End With
    End Sub
    
    Private Sub ConfigureWidgetGrids()
 
        'Set Team Member Grid Properties
        With gridTeamMembers
            .EnableEmbeddedSkins = False
            .Skin = "Prompt"
            .GroupingEnabled = True
            .AllowSorting = True
                        
            .ClientSettings.AllowColumnsReorder = True
            .ClientSettings.ColumnsReorderMethod = GridClientSettings.GridColumnsReorderMethod.Reorder
            .ClientSettings.Scrolling.AllowScroll = True
            .ClientSettings.Scrolling.ScrollHeight = Unit.Percentage(50)
            .ClientSettings.Scrolling.UseStaticHeaders = True
            .ClientSettings.Resizing.AllowColumnResize = True
            

            .MasterTableView.EnableHeaderContextMenu = False
            .MasterTableView.TableLayout = GridTableLayout.Fixed
            .MasterTableView.AllowMultiColumnSorting = False

            .Height = Unit.Pixel(250)
            
            .ExportSettings.FileName = "PromptTeamMembersExport"
            .ExportSettings.OpenInNewWindow = True
            .ExportSettings.Pdf.PageTitle = "Team Member List"
            
            'Set group by Level
            Dim expression As GridGroupByExpression = New GridGroupByExpression
            Dim gridGroupByField As GridGroupByField = New GridGroupByField
            gridTeamMembers.MasterTableView.GroupByExpressions.Clear()
        
            
            'NEED TO SORT BY DISPLAY ORDER... so need to change group heading to description when bound
            'Add select fields (before the "Group By" clause)
            gridGroupByField = New GridGroupByField
            gridGroupByField.FieldName = "TeamGroupDisplayOrder"
            
            gridGroupByField.HeaderText = " "
            gridGroupByField.HeaderValueSeparator = " "
            expression.SelectFields.Add(gridGroupByField)
            
            gridGroupByField = New GridGroupByField
            gridGroupByField.FieldName = "TeamGroupName"
            
            'gridGroupByField.HeaderText = " "
            'gridGroupByField.HeaderValueSeparator = " "
            expression.SelectFields.Add(gridGroupByField)

            'Add a field for group-by (after the "Group By" clause)
            gridGroupByField = New GridGroupByField
            gridGroupByField.FieldName = "TeamGroupDisplayOrder"
            
            expression.GroupByFields.Add(gridGroupByField)

    
            gridTeamMembers.MasterTableView.GroupByExpressions.Add(expression)

        End With
       

        'Set Grid Properties
        With radgridNotesWidget
            .EnableEmbeddedSkins = False
            .Skin = "Prompt"
            .GroupingEnabled = False
            .AllowSorting = True
                        
            .ClientSettings.AllowColumnsReorder = True
            .ClientSettings.ColumnsReorderMethod = GridClientSettings.GridColumnsReorderMethod.Reorder
            .ClientSettings.Scrolling.AllowScroll = True
            .ClientSettings.Scrolling.ScrollHeight = Unit.Percentage(50)
            .ClientSettings.Scrolling.UseStaticHeaders = True
            .ClientSettings.Resizing.AllowColumnResize = True

            .MasterTableView.EnableHeaderContextMenu = False
            .MasterTableView.TableLayout = GridTableLayout.Fixed
            .MasterTableView.AllowMultiColumnSorting = False

          
            .Height = Unit.Pixel(250)

            .ExportSettings.FileName = "PromptProjectNotesExport"
            .ExportSettings.OpenInNewWindow = True
            .ExportSettings.Pdf.PageTitle = "Project Notes List"
  
        End With
    End Sub
    
    Private Sub BuildMenu()
        
        If Not IsPostBack Then          'Configure main menu

            With RadMenu1
                .EnableEmbeddedSkins = False
                .Skin = "Prompt"
                .Width = Unit.Percentage(100)
                .EnableOverlay = False
            End With
            
            'build buttons
            Dim but As RadMenuItem
                
            If Not bContractsReadOnly Then
                but = New RadMenuItem
                With but
                    .Text = "Add New Contract"
                    .ImageUrl = "images/add.png"
                    .Attributes.Add("onclick", "openPopup('contract_edit.aspx?ContractID=0" & "&ProjectID=" & nProjectID & "','editcont',600,600,'yes');")
                    .ToolTip = "Add a New Contract."
                    .PostBack = False
                End With
                RadMenu1.Items.Add(but)
            End If
            
            but = New RadMenuItem
            With but
                .Text = "Printer friendly page"
                .ImageUrl = "images/printer.png"
                .Attributes("onclick") = "return printSelection(document.getElementById('printdiv'));return false"
                .ToolTip = "Show Printer Friendly Page."
                .PostBack = False
            End With
            RadMenu1.Items.Add(but)

        End If
        

    End Sub
    
    Private Sub SetSecurity()
        'Sets the security constraints for current page
        Using db As New EISSecurity
            db.ProjectID = nProjectID
			
            Dim dcmdExpand As New DockExpandCollapseCommand
            dockProjectOverview.Commands.Add(dcmdExpand)
			   
            If db.FindUserPermission("ProjectOverview", "Write") Then   'Only Admin and above can add edit projects
                bProjectReadOnly = False

                Dim dcmd As New DockCommand
                With dcmd
                    .Name = "ProjectEdit"
                    .Text = "Edit this Project"       'this is the tooltip
                    .OnClientCommand = "EditProject"
                    .AutoPostBack = "false"
                    .CssClass = "widgeteditbtn"
                End With
                dockProjectOverview.Commands.Add(dcmd)
            End If
            
            If db.FindUserPermission("ContractOverview", "Write") Then   'Only Admin and above can add contracts
                bContractsReadOnly = False
            End If
             
            If db.FindUserPermission("ProjectNotesWidget", "write") Then
                With lnkNewNote
                    .Visible = True
                    .Attributes("onclick") = "return EditNote(0," & nProjectID & ");"
                End With
            Else
                lnkNewNote.Visible = False
            End If
            
            If db.FindUserPermission("ProjectNotesWidget", "read") Then
                dockNotes.Visible = True
            Else
                dockNotes.Visible = False
            End If
            

            If db.FindUserPermission("ProjectTeamMembersWidget", "write") Then
                bTeamMembersReadOnly = False
                Dim dcmd As New DockCommand
                With dcmd
                    .Name = "ManageTeamMembers"
                    .Text = "Manage Team Members"       'this is the tooltip
                    .OnClientCommand = "ManageTeamMembers"
                    .CssClass = "widgeteditbtn"
                    .AutoPostBack = "false"

                End With
                dockTeamMembers.Commands.Add(dcmd)
            End If
            
            'visibility
            If db.FindUserPermission("ProjectTeamMembersWidget", "read") Then
                dockTeamMembers.Visible = True
            Else
                dockTeamMembers.Visible = False
            End If
            
            'trump any widget settings if district is turned off
            Dim tbl As DataTable = db.GetDistrictObjectVisibilitySettings("ProjectWidget")
            For Each row In tbl.Rows
                Select Case row("ObjectID")
                    Case "ProjectTeamMembersWidget"
                        If ProcLib.CheckNullNumField(row("Visibility")) = 0 Then
                            dockTeamMembers.Visible = False
                        End If
                    Case "ProjectNotesWidget"
                        If ProcLib.CheckNullNumField(row("Visibility")) = 0 Then
                            dockNotes.Visible = False
                        End If
                        
                End Select
                
            Next
  

        End Using
    End Sub
    
    '************************ Team Member Widget *********************************
    
    Protected Sub gridTeamMembers_NeedDataSource(ByVal source As Object, ByVal e As Telerik.Web.UI.GridNeedDataSourceEventArgs) Handles gridTeamMembers.NeedDataSource
        'loads the grid whenever it needs data (sorting, rebinding, etc...)
 
        
        Using db As New TeamMember
            db.CallingPage = Page

            'check to see if groups are used and if not then disable grouping
            Dim bHasGroups As Boolean = False
            Dim tbl As DataTable = db.GetExistingMembers(nProjectID)
            For Each row As DataRow In tbl.Rows
                If ProcLib.CheckNullDBField(row("TeamGroupName")) <> "" Then
                    bHasGroups = True
                    Exit For
                End If
            Next
            If bHasGroups = False Then
                gridTeamMembers.GroupingEnabled = False
            End If
            gridTeamMembers.DataSource = tbl
        End Using

    End Sub
    
    Protected Sub gridTeamMembers_ItemCommand(ByVal source As Object, ByVal e As Telerik.Web.UI.GridCommandEventArgs) Handles gridTeamMembers.ItemCommand
        Dim sSettings As String = ""
        If e.CommandName = "ExpandCollapse" Then       'save the expand collapse settings
            
            'Get current state pre click
            For Each item As GridItem In gridTeamMembers.MasterTableView.Controls(0).Controls
                If item.ItemType = GridItemType.GroupHeader Then
                    Dim grp As GridGroupHeaderItem = item
                    Dim clickItem As GridGroupHeaderItem = e.Item
                    
                    Dim grptxt As String = grp.DataCell.Text
                    Dim clktxt As String = clickItem.DataCell.Text
                    Dim bExpanded As Boolean = False
                    
                    If grptxt = clktxt Then 'save new click state
                        
                        If clickItem.Expanded = True Then
                            bExpanded = False
                        Else
                            bExpanded = True
                        End If
                    Else
                        bExpanded = grp.Expanded
                        
                    End If
                    sSettings &= "::" & grp.DataCell.Text & "," & bExpanded & "::"
                    
                End If
                

            Next
            
            Using db As New promptUserPrefs
                db.SaveGridGroupCollapseState(sSettings, "PMTeamMemberWidgetGroupSettings", "ProjectID", nProjectID)
            End Using
        End If
        
 
    End Sub
    
    Protected Sub gridTeamMembers_ItemCreated(ByVal sender As Object, ByVal e As Telerik.Web.UI.GridItemEventArgs) Handles gridTeamMembers.ItemCreated
        ''This event allows us to customize the cell contents - fired before databound

        If (TypeOf e.Item Is GridDataItem) Then

            Dim bEnableDelete As Boolean = True

            Dim item As GridDataItem = CType(e.Item, GridDataItem)
            Dim nContactID As Integer = ProcLib.CheckNullNumField(item.OwnerTableView.DataKeyValues(item.ItemIndex)("ContactID"))
            Dim nContractorID As Integer = ProcLib.CheckNullNumField(item.OwnerTableView.DataKeyValues(item.ItemIndex)("ContractorID"))
            Dim nPMID As Integer = ProcLib.CheckNullNumField(item.OwnerTableView.DataKeyValues(item.ItemIndex)("PMID"))
            Dim sName As String = ProcLib.CheckNullDBField(item.OwnerTableView.DataKeyValues(item.ItemIndex)("Name"))
            Dim sEmail As String = ProcLib.CheckNullDBField(item.OwnerTableView.DataKeyValues(item.ItemIndex)("Email"))
            Dim sTeamGroupName As String = ProcLib.CheckNullDBField(item.OwnerTableView.DataKeyValues(item.ItemIndex)("TeamGroupName"))
            
            'update the link button to delete file
            If bTeamMembersReadOnly Then
                item("Name").Controls.Clear()
                item("Name").Text = sName
            Else
                Dim linkButton As HyperLink = CType(item("Name").Controls(0), HyperLink)
                If nContactID > 0 Then
                    linkButton.Attributes("onclick") = "return EditContact(" & nContactID & ");"
                End If
                If nContractorID > 0 Then
                    linkButton.Attributes("onclick") = "return EditContractor(" & nContractorID & ");"
                End If
                If nPMID > 0 Then
                    linkButton.Attributes("onclick") = "return EditProjectManager(" & nPMID & ");"
                End If
                
                linkButton.ToolTip = "Edit this Team Member."
                linkButton.NavigateUrl = "#"
            End If
            
            If sEmail <> "" Then
                Dim linkEmail As HyperLink = CType(item("Email").Controls(0), HyperLink)
                linkEmail.NavigateUrl = "mailto:" & sEmail & "?Subject=" & lblProjectName.Text
                linkEmail.ToolTip = "Email this Team Member."
            End If
            

        End If
        
             
     
    End Sub
    
    Protected Sub gridTeamMembers_ItemDataBound(ByVal sender As Object, ByVal e As GridItemEventArgs) Handles gridTeamMembers.ItemDataBound

        If TypeOf e.Item Is GridGroupHeaderItem Then
            
            Dim item As GridGroupHeaderItem = CType(e.Item, GridGroupHeaderItem)
            Dim groupDataRow As DataRowView = CType(e.Item.DataItem, DataRowView)
                       
            item.DataCell.Text = groupDataRow("TeamGroupName")
        End If
    End Sub
    
   
    
    '************************ Notes Widget *********************************
    
    Protected Sub radgridNotesWidget_NeedDataSource(ByVal source As Object, ByVal e As Telerik.Web.UI.GridNeedDataSourceEventArgs) Handles radgridNotesWidget.NeedDataSource
        'loads the grid whenever it needs data (sorting, rebinding, etc...)
        Using db As New promptNote
            radgridNotesWidget.DataSource = db.GetNotes("ProjectID", nProjectID)
        End Using

    End Sub

    Protected Sub radgridNotesWidget_ItemCreated(ByVal sender As Object, ByVal e As Telerik.Web.UI.GridItemEventArgs) Handles radgridNotesWidget.ItemCreated

        'This event allows us to customize the cell contents - fired before databound

        If (TypeOf e.Item Is GridDataItem) Then
            Dim item As GridDataItem = CType(e.Item, GridDataItem)
            Dim nNoteID As Integer = item.OwnerTableView.DataKeyValues(item.ItemIndex)("NoteID")

            'update the link button to open report window
            Dim linkButton As HyperLink = CType(item("CreatedOn").Controls(0), HyperLink)
            linkButton.Attributes("onclick") = "return EditNote(" & nNoteID & "," & nProjectID & ");"
            linkButton.ToolTip = "Edit selected Note."
            linkButton.NavigateUrl = "#"
            
        End If
    End Sub
    
    '********************************** Docking *********************************
    Protected Sub RadDock1_DockPositionChanged(ByVal sender As Object, ByVal e As DockPositionChangedEventArgs)

        Dim dockState As String
        Dim serializer As New Script.Serialization.JavaScriptSerializer()
        Dim stateList As Generic.List(Of DockState) = RadDockLayout1.GetRegisteredDocksState()
        Dim serializedList As New StringBuilder()
        Dim i As Integer = 0
        While i < stateList.Count
            serializedList.Append(serializer.Serialize(stateList(i)))
            serializedList.Append("|")
            i += 1
        End While
        dockState = serializedList.ToString()

        'Save the dockState string into DB   
        Using db As New promptUserPrefs
            db.SaveDockState(dockState, "ProjectOverviewDockSettings", "ProjectID", nProjectID)
        End Using
    End Sub
    
    Protected Sub RadDockLayout1_SaveDockLayout(ByVal sender As Object, ByVal e As Telerik.Web.UI.DockLayoutEventArgs)

        Dim dockState As String
        Dim serializer As New Script.Serialization.JavaScriptSerializer()
        Dim stateList As Generic.List(Of DockState) = RadDockLayout1.GetRegisteredDocksState()
        Dim serializedList As New StringBuilder()
        Dim i As Integer = 0
        While i < stateList.Count
            serializedList.Append(serializer.Serialize(stateList(i)))
            serializedList.Append("|")
            i += 1
        End While
        dockState = serializedList.ToString()
        'Save the dockState string into DB 
        Using db As New promptUserPrefs
            db.SaveDockState(dockState, "ProjectOverviewDockSettings", "ProjectID", nProjectID)
        End Using
    End Sub
    
     
  
    Protected Sub RadDockLayout1_LoadDockLayout(ByVal sender As Object, ByVal e As Telerik.Web.UI.DockLayoutEventArgs)

        Dim serializer As New Script.Serialization.JavaScriptSerializer()
        'Get saved state string from the database - set it to dockState variable for example  
        Dim dockstate As String = ""
        Using db As New promptUserPrefs
            dockstate = db.GetDockState("ProjectOverviewDockSettings", "ProjectID", nProjectID)
        End Using
        If dockstate <> "" Then
            Dim currentDockStates As String() = dockstate.Split("|")
            For Each stringState As String In currentDockStates
                If stringState <> String.Empty Then
                    Dim state As DockState = serializer.Deserialize(Of DockState)(stringState)

                    Dim dock As RadDock = RadDockLayout1.FindControl(state.UniqueName)
                    Try
                        dock.ApplyState(state)
                    Catch ex As Exception
                        'error here so default config will prevail
                    End Try
                    
                    e.Positions(state.UniqueName) = state.DockZoneID
                    e.Indices(state.UniqueName) = state.Index

                End If
            Next
        End If
        
        'Reset the non changeable dock properties
        dockProjectOverview.Height = Unit.Pixel(400)
        CreateSaveStateTrigger(dockProjectOverview)
        
        dockBudgetOverview.Height = Unit.Pixel(450)
        CreateSaveStateTrigger(dockBudgetOverview)
        
        dockNotes.Height = Unit.Pixel(300)
        CreateSaveStateTrigger(dockNotes)
        
        dockTeamMembers.Height = Unit.Pixel(300)
        CreateSaveStateTrigger(dockTeamMembers)

    End Sub
    
    Private Sub CreateSaveStateTrigger(ByVal dock As RadDock)
        'Ensure that the RadDock control will initiate postback
        ' when its position changes on the client or any of the commands is clicked.
        'Using the trigger we will "ajaxify" that postback.
        dock.AutoPostBack = True
        dock.CommandsAutoPostBack = True

        Dim saveStateTrigger As New AsyncPostBackTrigger()
        saveStateTrigger.ControlID = dock.ID
        saveStateTrigger.EventName = "DockPositionChanged"
        UpdatePanel1.Triggers.Add(saveStateTrigger)

        saveStateTrigger = New AsyncPostBackTrigger()
        saveStateTrigger.ControlID = dock.ID
        saveStateTrigger.EventName = "Command"
        UpdatePanel1.Triggers.Add(saveStateTrigger)
    End Sub
    
    
  


</script>

<asp:Content ID="Content1" ContentPlaceHolderID="mainBody" runat="Server">
    <telerik:RadWindowManager ID="contentPopups" runat="server" />
    <div id="contentwrapper">
        <telerik:RadMenu ID="RadMenu1" runat="server" Style="z-index: 10;" />
        <div id="contentcolumn">
            <div id="printdiv" class="innertube">
                <span class="hdprint">Project:
                    <asp:Label ID="lblProjectName" runat="server"></asp:Label></span>
                <telerik:RadDockLayout ID="RadDockLayout1" runat="server" EnableEmbeddedSkins="False"
                    Skin="Prompt" OnSaveDockLayout="RadDockLayout1_SaveDockLayout" OnLoadDockLayout="RadDockLayout1_LoadDockLayout">
                    <telerik:RadDockZone ID="raddockLeft" runat="server" Orientation="Vertical" FitDocks="false"
                        CssClass="raddockzone">
                        <telerik:RadDock ID="dockProjectOverview" Title="Project Overview" runat="server"
                            Width="" Height="500px" DockHandle="TitleBar" DockMode="Docked" EnableRoundedCorners="True"
                            OnDockPositionChanged="RadDock1_DockPositionChanged" EnableAnimation="true" AutoPostBack="true">
                            <TitlebarTemplate>
                                <asp:Label runat="server" CssClass="widgetprojectoverviewtitle" Text="Project Overview" />
                            </TitlebarTemplate>
                            <ContentTemplate>
                                <asp:Panel ID="contentPanel1" runat="server">
                                    <table class="project_ov" cellpadding="3" cellspacing="0" width="100%" >
                                        <tr>
                                            <td width="20%">
                                                Status:
                                            </td>
                                            <td colspan="3">
                                                <asp:Label ID="lblStatus" runat="server" CssClass="green"></asp:Label>
                                                &nbsp; &nbsp; &nbsp; &nbsp;
                                                <asp:HyperLink ID="lnkFlag" runat="server" Visible="True" NavigateUrl="#" ImageUrl="images/alert.gif"></asp:HyperLink>
                                                &nbsp; &nbsp; &nbsp; &nbsp;
                                                <asp:Label ID="lblPassthroughProject" runat="server" Font-Bold="True" ForeColor="Magenta"
                                                    Font-Names="Verdana" Font-Size="11px">Passthrough Project</asp:Label>
                                            </td>
                                        </tr>
                                        <tr class="alt">
                                            <td>
                                                Project Manager:
                                            </td>
                                            <td colspan="3">
                                                <asp:Label ID="lblPM" runat="server"></asp:Label>&nbsp;
                                            </td>
                                        </tr>
                                        <tr>
                                            <td>
                                                General Contractor:
                                            </td>
                                            <td>
                                                <asp:Label ID="lblGC_Arch_ID" runat="server"></asp:Label>&nbsp;
                                            </td>
                                            <td>
                                                GC Proj#:
                                            </td>
                                            <td>
                                                <asp:Label ID="lblGC_Arch_ProjectNum" runat="server"></asp:Label>&nbsp;
                                            </td>
                                        </tr>
                                        <tr class="alt">
                                            <td>
                                                Architect:
                                            </td>
                                            <td>
                                                <asp:Label ID="lblArchID" runat="server"></asp:Label>&nbsp;
                                            </td>
                                            <td>
                                                Arch Proj#:
                                            </td>
                                            <td>
                                                <asp:Label ID="lblArchProjectNumber" runat="server"></asp:Label>&nbsp;
                                            </td>
                                        </tr>
                                        <tr>
                                            <td>
                                                Construction Mgr::
                                            </td>
                                            <td>
                                                <asp:Label ID="lblCMID" runat="server"></asp:Label>&nbsp;
                                            </td>
                                            <td>
                                                CM Ref#:
                                            </td>
                                            <td>
                                                <asp:Label ID="lblCMRefNumber" runat="server"></asp:Label>&nbsp;
                                            </td>
                                        </tr>
                                        <tr class="alt">
                                            <td>
                                                Project Number:
                                            </td>
                                            <td>
                                                <asp:Label ID="lblProjectNumber" runat="server"></asp:Label><asp:Label ID="lblDuplicateProjectNum"
                                                    runat="server" Font-Bold="True" ForeColor="Red" Text="Warning: Duplicate Project Number/SubNumber!"
                                                    Visible="False"></asp:Label>&nbsp;
                                            </td>
                                            <td>
                                                Sub#:
                                            </td>
                                            <td>
                                                <asp:Label ID="txtProjectSubNumber" runat="server"></asp:Label>&nbsp;
                                            </td>
                                        </tr>
                                        <tr>
                                            <td>
                                                Start Date:
                                            </td>
                                            <td>
                                                <asp:Label ID="lblStartDate" runat="server">Label</asp:Label>&nbsp;
                                            </td>
                                            <td>
                                                Est Complete Date:
                                            </td>
                                            <td>
                                                <asp:Label ID="lblEstCompleteDate" runat="server">Label</asp:Label>&nbsp;
                                            </td>
                                        </tr>
                                        <tr class="alt">
                                            <td>
                                                Org Code:
                                            </td>
                                            <td colspan="3">
                                                <asp:Label ID="lblOrgCode" runat="server"></asp:Label>&nbsp;
                                            </td>
                                        </tr>
                                        <tr>
                                            <td>
                                                Project Category:
                                            </td>
                                            <td>
                                                <asp:Label ID="lblCategory" runat="server"></asp:Label>&nbsp;
                                            </td>
                                            <td>
                                                Project Phase:
                                            </td>
                                            <td>
                                                <asp:Label ID="lblPhase" runat="server"></asp:Label>&nbsp;
                                            </td>
                                        </tr>
                                        <tr class="alt">
                                            <td valign="top">
                                                Description:
                                            </td>
                                            <td colspan="3" class="desc">
                                                <asp:Label ID="lblDescription" runat="server"></asp:Label>&nbsp;
                                            </td>
                                        </tr>
                                        <tr><td></td></tr>
                                        <tr>
                                            <td>
                                                Previous Quarter Status:
                                            </td>
                                            <td>
                                                <asp:Label ID="lblPriorQuarter_Status" runat="server"></asp:Label>&nbsp;
                                            </td>
                                            <td>
                                                Previous Quarter Phase:
                                            </td>
                                            <td>
                                                <asp:Label ID="lblPriorQuarter_Phase" runat="server"></asp:Label>&nbsp;
                                            </td>
                                        </tr>
                                    </table>
                                    <div class="id_display">
                                        College ID:<asp:Label ID="lblCollegeID" runat="server"></asp:Label>Project ID:
                                        <asp:Label ID="lblProjectID" runat="server"></asp:Label></div>
                                </asp:Panel>
                            </ContentTemplate>
                        </telerik:RadDock>
                        <telerik:RadDock ID="dockTeamMembers" runat="server" DockHandle="TitleBar" Title="Project Team Members"
                            DockMode="Docked" EnableRoundedCorners="True" Width="" Height="" OnDockPositionChanged="RadDock1_DockPositionChanged"
                            EnableAnimation="true" AutoPostBack="true">
                            <Commands>
                                <telerik:DockExpandCollapseCommand />
                            </Commands>
                            <TitlebarTemplate>
                                <asp:Label ID="Label1" runat="server" CssClass="widgetteammemberstitle" Text="Project Team Members" />
                            </TitlebarTemplate>
                            <ContentTemplate>
                                <telerik:RadGrid ID="gridTeamMembers" runat="server" AllowMultiRowSelection="False"
                                    AllowSorting="True" AutoGenerateColumns="False" GridLines="None" Width="99%"
                                    EnableAJAX="True" Height="375px" ShowHeader="True" BorderStyle="None">
                                    <ClientSettings>
                                        <Scrolling AllowScroll="True" UseStaticHeaders="True" ScrollHeight="50%" />
                                    </ClientSettings>
                                    <MasterTableView Width="98%" GridLines="None" DataKeyNames="Name,TeamMemberID,ContactID,Email"
                                        NoMasterRecordsText="No Team Members found.">
                                        <Columns>
                                            <telerik:GridHyperLinkColumn DataTextField="Name" UniqueName="Name" HeaderText="Name"
                                                SortExpression="Name">
                                                <ItemStyle HorizontalAlign="Left" Width="20%" Wrap="False" />
                                                <HeaderStyle HorizontalAlign="Left" Width="20%" Wrap="False" />
                                            </telerik:GridHyperLinkColumn>
                                            <telerik:GridBoundColumn DataField="Title" UniqueName="Title" HeaderText="Title">
                                                <ItemStyle HorizontalAlign="Left" Wrap="False" />
                                                <HeaderStyle HorizontalAlign="Left" Wrap="False" />
                                            </telerik:GridBoundColumn>
                                            <telerik:GridBoundColumn DataField="Company" UniqueName="Company" HeaderText="Company">
                                                <ItemStyle HorizontalAlign="Left" Wrap="False" />
                                                <HeaderStyle HorizontalAlign="Left" Wrap="False" />
                                            </telerik:GridBoundColumn>
                                            <telerik:GridBoundColumn DataField="Phone1" UniqueName="Phone1" HeaderText="Telephone">
                                                <ItemStyle HorizontalAlign="Left" />
                                                <HeaderStyle HorizontalAlign="Left" Wrap="False" />
                                            </telerik:GridBoundColumn>
                                            <telerik:GridBoundColumn DataField="Ext" UniqueName="Ext" HeaderText="Ext">
                                                <ItemStyle HorizontalAlign="Left" Wrap="False" />
                                                <HeaderStyle HorizontalAlign="Left" Width="25" Wrap="False" />
                                            </telerik:GridBoundColumn>
                                            <telerik:GridBoundColumn DataField="Cell" UniqueName="Cell" HeaderText="Cell">
                                                <ItemStyle HorizontalAlign="Left" />
                                                <HeaderStyle HorizontalAlign="Left" Wrap="False" />
                                            </telerik:GridBoundColumn>
                                            <telerik:GridHyperLinkColumn DataTextField="Email" UniqueName="Email" HeaderText="Email"
                                                SortExpression="Email">
                                                <ItemStyle HorizontalAlign="Left" />
                                                <HeaderStyle HorizontalAlign="Left" Wrap="False" />
                                            </telerik:GridHyperLinkColumn>
                                        </Columns>
                                    </MasterTableView>
                                </telerik:RadGrid>
                            </ContentTemplate>
                        </telerik:RadDock>
                    </telerik:RadDockZone>
                    <telerik:RadDockZone ID="raddockRight" runat="server" Orientation="Vertical" FitDocks="False"
                        CssClass="raddockzone">
                        <telerik:RadDock ID="dockBudgetOverview" runat="server" Width="" Height="448px" DockHandle="TitleBar"
                            DockMode="Docked" DefaultCommands="ExpandCollapse" EnableRoundedCorners="True"
                            OnDockPositionChanged="RadDock1_DockPositionChanged" 
                            EnableAnimation="true" AutoPostBack="true"
                            Resizable="false" Title="Budget Overview">
                            <TitlebarTemplate>
                                <asp:Label ID="Label2" runat="server" CssClass="widgetbudgetoverviewtitle">Budget Overview</asp:Label><asp:HyperLink
                                    ID="callBCR" runat="server" NavigateUrl="" Target="_blank">Run Budget Cost Report</asp:HyperLink></TitlebarTemplate>
                            <ContentTemplate>
                                <table class="project_ov" cellpadding="3" cellspacing="0" width="100%">
                                    <tr>
                                        <td>
                                            Total Budget:
                                        </td>
                                          <td align="right">
                                            <asp:Label ID="lblJCAFTotalBudget" runat="server"></asp:Label><br />
                                            <asp:Label ID="lblOrigBudget" runat="server" Visible="False"></asp:Label><asp:Label
                                                ID="lbl99" runat="server" Text="Budget Project Group:" Visible="False"></asp:Label><asp:Label
                                                    ID="lblBudgetChangeBatch" runat="server" Text="March 5, 2007" Visible="False"></asp:Label><asp:Label
                                                        ID="lblBudgetWarning" runat="server" Font-Bold="True" ForeColor="Red" Text="Does Not Match JCAF!"
                                                        Visible="False"></asp:Label>
                                        </td>
                                    </tr>
                                    <tr class="alt">
                                        <td>
                                            Total Contracts (incl. COs, Amends., Adj.):
                                        </td>
                                          <td align="right">
                                            <asp:Label ID="lblContractTotals" runat="server"></asp:Label>
                                        </td>
                                    </tr>
                                    <tr>
                                        <td>
                                            Total Transactions:
                                        </td>
                                         <td align="right">
                                            <asp:Label ID="lblTransAmount" runat="server"></asp:Label>
                                        </td>
                                    </tr>
                                    <tr class="alt">
                                        <td>
                                            Total Passthrough Expense:
                                        </td>
                                          <td align="right">
                                            <asp:Label ID="lblPassthrough" runat="server"></asp:Label>
                                        </td>
                                    </tr>
                                    <tr>
                                        <td>
                                            Unencumbered Project Balance:
                                        </td>
                                          <td align="right">
                                            <asp:Label ID="lblUnencumberedProjectBalance" runat="server"></asp:Label>
                                        </td>
                                    </tr>
                                    <tr class="alt"><td></td><td></td></tr>
                                    <tr class="alt"><td></td><td></td></tr>
                                    <tr>
                                        <td>
                                            Ledger Account Adjustments:
                                        </td>
                                         <td align="right">
                                            <asp:Label ID="lblLedgerAccountAdjustments" runat="server"></asp:Label>
                                        </td>
                                    </tr>                                   
                                </table>
                            </ContentTemplate>
                        </telerik:RadDock>
                        <telerik:RadDock ID="dockNotes" runat="server" Width="" Height="" Title="Notes" DockHandle="TitleBar"
                            DockMode="Docked" DefaultCommands="ExpandCollapse" OnDockPositionChanged="RadDock1_DockPositionChanged"
                            EnableAnimation="true" AutoPostBack="true" EnableRoundedCorners="True">
                            <TitlebarTemplate>
                                <asp:Label ID="Label3" runat="server" CssClass="widgetnotestitle">Notes</asp:Label><asp:HyperLink
                                    ID="lnkNewNote" NavigateUrl="#" CssClass="widgetaddbtn" runat="server">Add</asp:HyperLink></TitlebarTemplate>
                            <ContentTemplate>
                                <telerik:RadGrid ID="radgridNotesWidget" runat="server" AllowSorting="true" AutoGenerateColumns="False"
                                    GridLines="None" Width="100%" EnableAJAX="True" Height="360px" Skin="Windows7">
                                    <ClientSettings>
                                        <Selecting AllowRowSelect="False" />
                                        <Scrolling AllowScroll="True" UseStaticHeaders="True" ScrollHeight="50%" />
                                    </ClientSettings>
                                    <MasterTableView Width="100%" GridLines="None" DataKeyNames="NoteID" NoMasterRecordsText="No Notes found.">
                                        <Columns>
                                            <telerik:GridHyperLinkColumn UniqueName="CreatedOn" HeaderText="On" NavigateUrl="#"
                                                SortExpression="CreatedOn" DataTextField="CreatedOn" DataTextFormatString="{0:MM/dd/yy}">
                                                <ItemStyle HorizontalAlign="Left" VerticalAlign="Top" Width="20%" />
                                                <HeaderStyle HorizontalAlign="Left" Width="20%" />
                                            </telerik:GridHyperLinkColumn>
                                            <telerik:GridBoundColumn UniqueName="Description" HeaderText="Description" DataField="Description">
                                                <ItemStyle HorizontalAlign="Left" VerticalAlign="Top" />
                                                <HeaderStyle HorizontalAlign="Left" />
                                            </telerik:GridBoundColumn>
                                            <telerik:GridBoundColumn UniqueName="CreatedBy" HeaderText="By" DataField="CreatedBy">
                                                <ItemStyle HorizontalAlign="Left" Width="20%" VerticalAlign="Top" />
                                                <HeaderStyle Width="20%" HorizontalAlign="Left" />
                                            </telerik:GridBoundColumn>
                                        </Columns>
                                    </MasterTableView>
                                </telerik:RadGrid>
                            </ContentTemplate>
                        </telerik:RadDock>
                    </telerik:RadDockZone>
                </telerik:RadDockLayout>
                <div style="width: 0px; height: 0px; overflow: hidden; position: absolute; left: -10000px;">
                    Hidden UpdatePanel, which is used to help with saving state when minimizing, moving
                    and closing docks. This way the docks state is saved faster (no need to update the
                    docking zones).
                    <asp:UpdatePanel runat="server" ID="UpdatePanel1">
                    </asp:UpdatePanel>
                </div>
                <telerik:RadAjaxManager ID="RadAjaxManager1" runat="server">
                    <AjaxSettings>
                        <telerik:AjaxSetting AjaxControlID="radgridNotesWidget">
                            <UpdatedControls>
                                <telerik:AjaxUpdatedControl ControlID="radgridNotesWidget" LoadingPanelID="RadAjaxLoadingPanel1" />
                            </UpdatedControls>
                        </telerik:AjaxSetting>
                        <telerik:AjaxSetting AjaxControlID="gridTeamMembers">
                            <UpdatedControls>
                                <telerik:AjaxUpdatedControl ControlID="gridTeamMembers" LoadingPanelID="RadAjaxLoadingPanel1" />
                            </UpdatedControls>
                        </telerik:AjaxSetting>
                    </AjaxSettings>
                </telerik:RadAjaxManager>
                <telerik:RadAjaxLoadingPanel ID="RadAjaxLoadingPanel1" runat="server" Height="75px"
                    Width="75px" Transparency="25">
                    <img alt="Loading..." src='<%= RadAjaxLoadingPanel.GetWebResourceUrl(Page, "Telerik.Web.UI.Skins.Default.Ajax.loading.gif") %>'
                        style="border: 0;" /></telerik:RadAjaxLoadingPanel>
                <telerik:RadCodeBlock ID="RadCodeBlock1" runat="server">

                    <script type="text/javascript" language="javascript">

                        var projid = '<%=nProjectID%>';    // set projid for global

                        // Begin ******************* Menu Handlers ***********************

                        var sCancelAjax;    // flag to disable ajax for grid export functions

                        function ajaxRequestStart(sender, args) {
                            //Called when ajax request starts so we can disable for grid export controls.
                            if (sCancelAjax == 'Y') {
                                args.set_enableAjax(false);
                            }
                        }

                        function ajaxRequestEnd(sender, args) {
                            //Called when ajax request Ends.
                            args.set_enableAjax(true);
                        }

                        function OnClientItemClicking(sender, args) {
                            // set this var so that we can cancel ajax for grid export function
                            var button = args.get_item();
                            sCancelAjax = button.get_attributes().getAttribute("CancelAjax");
                        }


                        // End ******************* Menu Handlers ***********************


                        function EditProject() {
                            openPopup('project_edit.aspx?ProjectID=' + projid, 'EditProject', 650, 760, 'yes');

                        }

                        function EditNote(id, parentkey) {

                            var oWnd = window.radopen("note_edit.aspx?NoteID=" + id + "&CurrentView=project&KeyValue=" + parentkey + "&WinType=RAD", "EditNoteWindow");
                            return false;
                        }

                        function EditContact(id) {

                            var oWnd = window.radopen("contact_edit.aspx?ContactID=" + id, "EditTeamMemberWindow");
                            return false;
                        }

                        function EditContractor(id) {

                            var oWnd = window.radopen("contractor_edit.aspx?ContractorID=" + id + "&WinType=RAD", "EditTeamMemberWindow");
                            return false;
                        }

                        function EditProjectManager(id) {

                            var oWnd = window.radopen("ProjectManager_edit.aspx?PMID=" + id, "EditTeamMemberWindow");
                            return false;
                        }

                        function ManageTeamMembers() {

                            var oWnd = window.radopen("teammembers_manage.aspx?ProjectID=" + projid, "ManageTeamMembersWindow");
                            return false;
                        }


                        function GetRadWindow() {
                            var oWindow = null;
                            if (window.RadWindow) oWindow = window.RadWindow;
                            else if (window.frameElement.radWindow) oWindow = window.frameElement.radWindow;
                            return oWindow;
                        }

                    </script>

                </telerik:RadCodeBlock>
            </div>
        </div>
    </div>


</asp:Content>