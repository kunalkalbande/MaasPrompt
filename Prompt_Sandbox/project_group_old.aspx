<%@ Page Language="VB" MasterPageFile="~/content.master" Title="" %>

<%@ Register Assembly="Telerik.Web.UI" Namespace="Telerik.Web.UI" TagPrefix="telerik" %>
<%@ Import Namespace="Prompt" %>

<script runat="server">
    
    Public nProjectGroupID As Integer = 0
    Public nCollegeID As Integer = 0

    Private ContractAmount As Double = 0
    Private ReimbursablesAmount As Double = 0
    Private AmmendAmount As Double = 0
    Private TransAmount As Double = 0
    Private PassthroughAmount As Double = 0
    
    Private BondTotal As Double = 0
    Private StateTotal As Double = 0
    Private OtherTotal As Double = 0
    Private BudgetTotal As Double = 0
    
    Private Adjustments As Double = 0
    
    Private ContractBalance As Double = 0
    Private ProjectBalance As Double = 0
    Private Uncommitted As Double = 0
    
    Protected Sub Page_Init(ByVal sender As Object, ByVal e As System.EventArgs)
        
        nProjectGroupID = Request.QueryString("ProjectGroupID")
        nCollegeID = Request.QueryString("CollegeID")
        
    End Sub
      

    Private Sub Page_Load(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MyBase.Load

        Session("PageID") = "ProjectGroupInfo"
        
        nProjectGroupID = Request.QueryString("ProjectGroupID")
        Session("CollegeID") = Request.QueryString("CollegeID")
        
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
        
        'Configure the Popup Window(s)
        With contentPopups
            .VisibleOnPageLoad = False
            .Skin = "Windows7"

            Dim ww As New Telerik.Web.UI.RadWindow
            
            ww = New Telerik.Web.UI.RadWindow
            With ww
                .ID = "EditWindow"
                .NavigateUrl = ""
                .Title = ""
                .Width = 500
                .Height = 625
                .Modal = False
                .VisibleStatusbar = False
                .ReloadOnShow = True
            End With
            .Windows.Add(ww)
            
  
        End With
        

        If Session("delproject") <> True Then    'to prevent reload on postback after deleting the record

            Using db As New promptProject      'get the project record 
                db.CallingPage = Page
                db.GetProjectGroupInfo(contentPanel1, nProjectGroupID)
            
                'remove the number from the status
                lblStatus.Text = Mid(lblStatus.Text, 3)

                TransAmount = db.GetProjectGroupTotals("Transactions", nProjectGroupID)
                AmmendAmount = db.GetProjectGroupTotals("Amendments", nProjectGroupID)
                ContractAmount = db.GetProjectGroupTotals("Contracts", nProjectGroupID)
                ReimbursablesAmount = db.GetProjectGroupTotals("Reimbursables", nProjectGroupID)
                PassthroughAmount = db.GetProjectGroupTotals("Passthrough", nProjectGroupID)
                Adjustments = db.GetProjectGroupTotals("Adjustments", nProjectGroupID)
            
                BondTotal = db.GetProjectGroupTotals("Bond", nProjectGroupID)
                StateTotal = db.GetProjectGroupTotals("State", nProjectGroupID)
                OtherTotal = db.GetProjectGroupTotals("Other", nProjectGroupID)
                BudgetTotal = BondTotal + StateTotal + OtherTotal

 
            End Using
        
                 
            ContractBalance = ContractAmount + ReimbursablesAmount + AmmendAmount - TransAmount + Adjustments
            ProjectBalance = BudgetTotal - TransAmount - PassthroughAmount
            Uncommitted = ProjectBalance - ContractBalance
         
            lblJCAFBondBudget.Text = FormatCurrency(BondTotal, -1, -2, -1, -2)
            lblJCAFStateBudget.Text = FormatCurrency(StateTotal, -1, -2, -1, -2)
            lblJCAFOtherBudget.Text = FormatCurrency(OtherTotal, -1, -2, -1, -2)
            lblJCAFTotalBudget.Text = FormatCurrency(BudgetTotal, -1, -2, -1, -2)
        
            lblContractAmount.Text = FormatCurrency(ContractAmount, -1, -2, -1, -2)
            lblContractReimbursables.Text = FormatCurrency(ReimbursablesAmount, -1, -2, -1, -2)
            lblAmmendAmount.Text = FormatCurrency(AmmendAmount, -1, -2, -1, -2)
            lblTransAmount.Text = FormatCurrency(TransAmount, -1, -2, -1, -2)
            lblContractBalance.Text = FormatCurrency(ContractBalance, -1, -2, -1, -2)
            lblProjectBalance.Text = FormatCurrency(ProjectBalance, -1, -2, -1, -2)
            lblUncommitted.Text = FormatCurrency(Uncommitted, -1, -2, -1, -2)
            
            lblAdjustments.Text = FormatCurrency(Adjustments, -1, -2, -1, -2)
        
            lblPassthrough.Text = FormatCurrency(PassthroughAmount, -1, -2, -1, -2)
 

            'set up report quick links
            Dim slnk As String
            slnk = "report_run.aspx?DirectCall=1&rpt=Project_Summary&ProjectID=" & nProjectGroupID
            With lblContractAmount
                '.NavigateUrl = slnk
                .Target = "_new"
            End With
            slnk = "report_run.aspx?DirectCall=1&rpt=Project_Summary&ProjectID=" & nProjectGroupID
            With lblContractReimbursables
                '.NavigateUrl = slnk
                .Target = "_new"
            End With
            slnk = "report_run.aspx?DirectCall=1&rpt=Change_Order_Log_All&ProjectID=" & nProjectGroupID
            With lblAmmendAmount
                '.NavigateUrl = slnk
                .Target = "_new"
            End With
            slnk = "report_run.aspx?DirectCall=1&rpt=Check_Run_All&ProjectID=" & nProjectGroupID
            With lblTransAmount
                '.NavigateUrl = slnk
                .Target = "_new"
            End With
            slnk = "report_run.aspx?DirectCall=1&rpt=Project_Summary&ProjectID=" & nProjectGroupID
            With lblContractBalance
                '.NavigateUrl = slnk
                .Target = "_new"
            End With
            
            SetSecurity()
        
    
        
        Else
            Session("delproject") = False       'we just deleted a project so needed to load page, then redirect to parent college
        
        End If
        
  
    End Sub
    
    
    
    Private Sub SetSecurity()
        'Sets the security constraints for current page
        
        Using db As New EISSecurity
            db.CollegeID = Session("CollegeID")
            db.ProjectID = 0
            
            If db.FindUserPermission("ProjectGroupOverview", "Write") Then   'Only Admin and above can add contracts
                'With lnkEdit
                '    .Visible = True
                '    .Attributes("onclick") = "return EditProjectGroup(" & Session("CollegeID") & "," & nProjectGroupID & ",this);"
                'End With
            End If

        End Using
        
        
        
        
        
        
        Using db As New EISSecurity
            db.CollegeID = Session("CollegeID")
            db.ProjectID = 0
			
            Dim dcmdExpand As New DockExpandCollapseCommand
            dockProjectOverview.Commands.Add(dcmdExpand)
			   
            If db.FindUserPermission("ProjectGroupOverview", "Write") Then   'Only Admin and above can add edit projects
                Dim dcmd As New DockCommand
                With dcmd
                    .Name = "ProjectEdit"
                    .Text = "Edit this Project Group"       'this is the tooltip
                    .OnClientCommand = "EditProjectGroup"
                    .AutoPostBack = "false"
                    .CssClass = "widgeteditbtn"
                End With
                dockProjectOverview.Commands.Add(dcmd)
            End If
            
  

        End Using
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
            db.SaveDockState(dockState, "ProjectGroupOverviewDockSettings", "ProjectID", nProjectGroupID)
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
            db.SaveDockState(dockState, "ProjectGroupOverviewDockSettings", "ProjectID", nProjectGroupID)
        End Using
    End Sub
    
     
  
    Protected Sub RadDockLayout1_LoadDockLayout(ByVal sender As Object, ByVal e As Telerik.Web.UI.DockLayoutEventArgs)

        Dim serializer As New Script.Serialization.JavaScriptSerializer()
        'Get saved state string from the database - set it to dockState variable for example  
        Dim dockstate As String = ""
        Using db As New promptUserPrefs
            dockstate = db.GetDockState("ProjectGroupOverviewDockSettings", "ProjectID", nProjectGroupID)
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
        
        dockBudgetOverview.Height = Unit.Pixel(350)
        CreateSaveStateTrigger(dockBudgetOverview)
        
   
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
        <div id="contentcolumn">
            <div id="printdiv" class="innertube">
                <span class="hdprint">Project:
                    <asp:Label ID="lblProjectName" runat="server"></asp:Label></span>
                <telerik:RadDockLayout ID="RadDockLayout1" runat="server" EnableEmbeddedSkins="False"
                    Skin="Prompt" OnSaveDockLayout="RadDockLayout1_SaveDockLayout" OnLoadDockLayout="RadDockLayout1_LoadDockLayout">
                    <telerik:RadDockZone ID="raddockLeft" runat="server" Orientation="Vertical" FitDocks="false"
                        CssClass="raddockzone">
                        <telerik:RadDock ID="dockProjectOverview" Title="Project Overview" runat="server"
                            Width="" Height="400px" DockHandle="TitleBar" DockMode="Docked" EnableRoundedCorners="True"
                            OnDockPositionChanged="RadDock1_DockPositionChanged" EnableAnimation="true" AutoPostBack="true">
                            <TitlebarTemplate>
                                <asp:Label ID="Label1" runat="server" CssClass="widgetprojectoverviewtitle" Text="Project Group Overview" />
                            </TitlebarTemplate>
                            <ContentTemplate>
                                <asp:Panel ID="contentPanel1" runat="server">
                                    <table cellpadding="3" cellspacing="0" class="project_ov" width="100%">
                                        <tr>
                                            <td>
                                                Project Number:
                                            </td>
                                            <td>
                                                <asp:Label ID="lblProjectNumber" runat="server"></asp:Label>&nbsp;
                                            </td>
                                        </tr>
                                        <tr class="alt">
                                            <td>
                                                Status:
                                            </td>
                                            <td>
                                                <asp:Label ID="lblStatus" runat="server" CssClass="green"></asp:Label>&nbsp;
                                            </td>
                                        </tr>
                                        <tr>
                                            <td>
                                                Phase:
                                            </td>
                                            <td>
                                                <asp:Label ID="lblPhase" runat="server" CssClass="blue"></asp:Label>&nbsp;
                                            </td>
                                        </tr>
                                        <tr class="alt">
                                            <td>
                                                Start Date:
                                            </td>
                                            <td>
                                                <asp:Label ID="lblStartDate" runat="server"></asp:Label>&nbsp;
                                            </td>
                                        </tr>
                                        <tr>
                                            <td>
                                                End Date:
                                            </td>
                                            <td>
                                                <asp:Label ID="lblEndDate" runat="server"></asp:Label>&nbsp;
                                            </td>
                                        </tr>
                                        <tr class="alt">
                                            <td>
                                                Prev Budget:
                                            </td>
                                            <td>
                                                <asp:Label ID="lblPreviousBudget" runat="server"></asp:Label>&nbsp;
                                            </td>
                                        </tr>
                                        <tr>
                                            <td>
                                                Prev Expenses:
                                            </td>
                                            <td>
                                                <asp:Label ID="lblPreviousExpenses" runat="server"></asp:Label>&nbsp;
                                            </td>
                                        </tr>
                                        <tr class="alt">
                                            <td>
                                                &nbsp;
                                            </td>
                                            <td align="right">
                                                ID:<asp:Label ID="lblProjectGroupID" runat="server" />
                                            </td>
                                        </tr>
                                    </table>
                                </asp:Panel>
                            </ContentTemplate>
                        </telerik:RadDock>
                    </telerik:RadDockZone>
                    <telerik:RadDockZone ID="raddockRight" runat="server" Orientation="Vertical" FitDocks="False"
                        CssClass="raddockzone">
                        <telerik:RadDock ID="dockBudgetOverview" runat="server" Width="" Height="325px" DockHandle="TitleBar"
                            DockMode="Docked" DefaultCommands="ExpandCollapse" EnableRoundedCorners="True"
                            OnDockPositionChanged="RadDock1_DockPositionChanged" EnableAnimation="true" AutoPostBack="true"
                            Resizable="false" Title="Budget Overview">
                            <TitlebarTemplate>
                                <asp:Label ID="Label7" runat="server" CssClass="widgetbudgetoverviewtitle">Budget Overview</asp:Label>
                            </TitlebarTemplate>
                            <ContentTemplate>
                                <table cellpadding="3" cellspacing="0" width="100%" class="project_ov">
                                    <tr class="alt">
                                        <td>
                                            Bond Budget:
                                        </td>
                                        <td align="right">
                                            <asp:HyperLink ID="lblJCAFBondBudget" runat="server"></asp:HyperLink>
                                        </td>
                                    </tr>
                                    <tr>
                                        <td>
                                            State Budget:
                                        </td>
                                          <td align="right">
                                            <asp:HyperLink ID="lblJCAFStateBudget" runat="server"></asp:HyperLink>
                                        </td>
                                    </tr>
                                    <tr class="alt">
                                        <td>
                                            Other Budget:
                                        </td>
                                        <td align="right">
                                            <asp:HyperLink ID="lblJCAFOtherBudget" runat="server"></asp:HyperLink>
                                        </td>
                                    </tr>
                                    <tr>
                                        <td>
                                            Total&nbsp; Budget:
                                        </td>
                                        <td align="right">
                                            <asp:HyperLink ID="lblJCAFTotalBudget" runat="server"></asp:HyperLink>
                                        </td>
                                    </tr>
                                    <tr class="alt">
                                        <td>
                                            Total Contracts:
                                        </td>
                                         <td align="right">
                                            <asp:HyperLink ID="lblContractAmount" runat="server"></asp:HyperLink>
                                        </td>
                                    </tr>
                                    <tr>
                                        <td>
                                            Total Contract Reimbursables:
                                        </td>
                                        <td align="right">
                                            <asp:HyperLink ID="lblContractReimbursables" runat="server"></asp:HyperLink>
                                        </td>
                                    </tr>
                                    <tr class="alt">
                                        <td>
                                            Total Amend/CO's:
                                        </td>
                                         <td align="right">
                                            <asp:HyperLink ID="lblAmmendAmount" runat="server"></asp:HyperLink>
                                        </td>
                                    </tr>
                                    
                                                                      <tr>
                                        <td>
                                            Total Contract Adjustments:
                                        </td>
                                         <td align="right">
                                            <asp:HyperLink ID="lblAdjustments" runat="server"></asp:HyperLink>
                                        </td>
                                    </tr>
                                    
                                    <tr>
                                        <td>
                                            Total Transactions:
                                        </td>
                                         <td align="right">
                                            <asp:HyperLink ID="lblTransAmount" runat="server"></asp:HyperLink>
                                        </td>
                                    </tr>
                                    <tr class="alt">
                                        <td>
                                            Total Passthrough Expense:
                                        </td>
                                         <td align="right">
                                            <asp:HyperLink ID="lblPassthrough" runat="server"></asp:HyperLink>
                                        </td>
                                    </tr>
                                    <tr>
                                        <td>
                                            Contract Balance:
                                        </td>
                                        <td align="right">
                                            <asp:HyperLink ID="lblContractBalance" runat="server">[lblContractBalance]</asp:HyperLink>
                                        </td>
                                    </tr>
                                    <tr class="alt">
                                        <td>
                                            Uncommitted:
                                        </td>
                                         <td align="right">
                                            <asp:HyperLink ID="lblUncommitted" runat="server">[lblContractBalance]</asp:HyperLink>
                                        </td>
                                    </tr>
                                    <tr>
                                        <td>
                                            Project Balance:
                                        </td>
                                          <td align="right">
                                            <asp:HyperLink ID="lblProjectBalance" runat="server"></asp:HyperLink>
                                        </td>
                                    </tr>
                                </table>
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
                    </AjaxSettings>
                </telerik:RadAjaxManager>
                <telerik:RadAjaxLoadingPanel ID="RadAjaxLoadingPanel1" runat="server" Height="75px"
                    Width="75px" Transparency="25">
                    <img alt="Loading..." src='<%= RadAjaxLoadingPanel.GetWebResourceUrl(Page, "Telerik.Web.UI.Skins.Default.Ajax.loading.gif") %>'
                        style="border: 0;" /></telerik:RadAjaxLoadingPanel>
            </div>
        </div>
    </div>
    <telerik:RadCodeBlock ID="RadCodeBlock1" runat="server">

        <script type="text/javascript" language="javascript">
            var projectid = '<%=nProjectGroupID%>';
            var collegeid = '<%=nCollegeID%>';
            
              
            function EditProjectGroup() {

                var oWnd = window.radopen("project_group_edit.aspx?CollegeID=" + collegeid + "&ProjectGroupID=" + projectid, "EditWindow");
                 return false;
            }


            function GetElementPosition(el) {
                var parent = null;
                var pos = { x: 0, y: 0 };
                var box;

                if (el.getBoundingClientRect) {
                    // IE   
                    box = el.getBoundingClientRect();
                    var scrollTop = document.documentElement.scrollTop || document.body.scrollTop;
                    var scrollLeft = document.documentElement.scrollLeft || document.body.scrollLeft;

                    pos.x = box.left + scrollLeft - 2;
                    pos.y = box.top + scrollTop - 2;

                    return pos;
                }
                else if (document.getBoxObjectFor) {
                    // gecko   
                    box = document.getBoxObjectFor(el);
                    pos.x = box.x - 2;
                    pos.y = box.y - 2;
                }
                else {
                    // safari/opera   
                    pos.x = el.offsetLeft;
                    pos.y = el.offsetTop;
                    parent = el.offsetParent;
                    if (parent != el) {
                        while (parent) {
                            pos.x += parent.offsetLeft;
                            pos.y += parent.offsetTop;
                            parent = parent.offsetParent;
                        }
                    }
                }


                if (window.opera) {
                    parent = el.offsetParent;

                    while (parent && parent.tagName != 'BODY' && parent.tagName != 'HTML') {
                        pos.x -= parent.scrollLeft;
                        pos.y -= parent.scrollTop;
                        parent = parent.offsetParent;
                    }
                }
                else {
                    parent = el.parentNode;
                    while (parent && parent.tagName != 'BODY' && parent.tagName != 'HTML') {
                        pos.x -= parent.scrollLeft;
                        pos.y -= parent.scrollTop;

                        parent = parent.parentNode;
                    }
                }
                return pos;
            }


            function GetRadWindow() {
                var oWindow = null;
                if (window.RadWindow) oWindow = window.RadWindow;
                else if (window.frameElement.radWindow) oWindow = window.frameElement.radWindow;
                return oWindow;
            }

        </script>

    </telerik:RadCodeBlock>
</asp:Content>
