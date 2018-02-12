<%@ Page Language="VB" %>
<%@ Register Assembly="Telerik.Web.UI" Namespace="Telerik.Web.UI" TagPrefix="telerik" %>
<%@ Import Namespace="Prompt" %>

<script runat="server">
    
    Private sDashboardType As String = ""
    Private CurrentView As String = ""
    Private IncludePaid As Boolean = False
    Private nDistrictID As Integer = 0
    
    Private dLastAnnouncementTimeStamp As String
    
    Protected Sub Page_Init(ByVal sender As Object, ByVal e As System.EventArgs)
        nDistrictID = Session("DistrictID")    'needed here for docks
        sDashboardType = Request.QueryString("Type")
        
        If Not IsPostBack then
                      
            Dim zItem As RadComboBoxItem
            
            zItem = New RadComboBoxItem
            zItem.Text = "All Alerts"
            zItem.Value = "AllAlerts"
            cboAlertsView.Items.Add(zItem)
            
            zItem = New RadComboBoxItem
            zItem.Text = "Flagged Items"
            zItem.Value = "FlaggedItems"
            zItem.Selected = True
            cboAlertsView.Items.Add(zItem)
            
            zItem = New RadComboBoxItem
            zItem.Text = "Expired Contracts"
            zItem.Value = "ExpiredContracts"
            cboAlertsView.Items.Add(zItem)

            zItem = New RadComboBoxItem
            zItem.Text = "Expired Insurance"
            zItem.Value = "ExpiredInsurance"
            cboAlertsView.Items.Add(zItem)
            
            Using db As New promptProject
                db.LoadDashboardProjectManagers(cboPMProjectView)
            End Using
            
            zItem = New RadComboBoxItem
            zItem.Text = "My Open Items"
            zItem.Value = "MyOpenInboxItems"
            cboInboxView.Items.Add(zItem)
            
            zItem = New RadComboBoxItem
            zItem.Text = "My Approved Items"
            zItem.Value = "MyApproved"
            cboInboxView.Items.Add(zItem)
            
            zItem = New RadComboBoxItem
            zItem.Text = "My Rejected Items"
            zItem.Value = "MyRejected"
            cboInboxView.Items.Add(zItem)
                                                                
            If Session("UserRole") = "Project Accountant" Or Session("UserRole") = "TechSupport" Then
                
                zItem = New RadComboBoxItem
                zItem.Text = "All FDO Approved Items"
                zItem.Value = "AllFDOApproved"
                cboInboxView.Items.Add(zItem)

            End If
            
            If Session("UserRole") = "TechSupport" Then
                
                zItem = New RadComboBoxItem
                zItem.Text = "All Open Workflow Items"
                zItem.Value = "AllOpenWorkflowItems"
                cboInboxView.Items.Add(zItem)

            End If
   
        End If
        
        SetSecurity()

    End Sub
        
    Private Sub Page_Load(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MyBase.Load

        Session("PageID") = "Dashboard"
        Page.Title = "Prompt Dashboard"
        sDashboardType = Request.QueryString("Type")
        
        nDistrictID = Session("DistrictID")

        ProcLib.LoadPopupJscript(Page)
        
        
        'Configure the Popup Window(s)
        With dashboardPopups
            .VisibleOnPageLoad = False
            .Skin = "Windows7"
            
            'Dim ww As Telerik.Web.UI.RadWindow
            
            'show the modal load window if user has not seen latest announcement       
            'Using db As New promptAdmin
            '    If db.ShowLatestAnnouncement = True Then
            '        ww = New Telerik.Web.UI.RadWindow
            '        With ww
            '            .ID = "PromptAnnouncementsWindow"
            '            .NavigateUrl = ""
            '            .IconUrl = "images/message.png"
            '            .Title = ""
            '            .Width = 500
            '            .Height = 500
            '            .Modal = True
            '            .NavigateUrl = "admin_announcements_show.aspx"
            '            .VisibleOnPageLoad = True
            '            .VisibleStatusbar = False
            '            .ReloadOnShow = True
            '            .Behaviors = WindowBehaviors.None
            '        End With
            '        .Windows.Add(ww)
            '    End If
            'End Using

        End With
        
        
        
    End Sub
    
    Private Sub SetSecurity()
        'Sets the security constraints for current page
        Using db As New EISSecurity
            Dim tbl As DataTable = db.GetDistrictObjectVisibilitySettings("Dashboard")
            For Each row In tbl.Rows
                Select Case row("ObjectID")
                    
                                      
                    Case "InboxWidget"
                        If ProcLib.CheckNullNumField(row("Visibility")) = 0 Then
                            dockInbox.Visible = False
                        Else
                            If db.FindUserPermission("InboxWidget", "Read") Then   'load user controls into appropriate widget
                                LoadInboxWidget()
                            Else
                                dockInbox.Visible = False
                            End If
                        End If

                    Case "PMOverviewWidget"
                        If ProcLib.CheckNullNumField(row("Visibility")) = 0 Then
                            dockPMOverview.Visible = False
                        Else
                            If db.FindUserPermission("PMOverviewWidget", "Read") Then   'load user controls into appropriate widget
                                LoadPMOverviewWidget()
                            Else
                                dockPMOverview.Visible = False
                            End If
                            
                        End If
                        
                    Case "AlertsWidget"
                        If ProcLib.CheckNullNumField(row("Visibility")) = 0 Then
                            dockAlerts.Visible = False
                        Else
                            If db.FindUserPermission("AlertsWidget", "Read") Then   'load user controls into appropriate widget
                                LoadAlertsWidget()
                            Else
                                dockAlerts.Visible = False
                            End If
                            
                        End If
                        
                        
                End Select

            Next
  

        End Using
    End Sub
    
    Private Sub LoadPMOverviewWidget()

        dockPMOverview.ContentContainer.Controls.Clear()
        Dim widget As Control = LoadControl("dashboard_pmoverview.ascx")
        dockPMOverview.ContentContainer.Controls.Add(widget)
    End Sub
    
    Private Sub LoadAlertsWidget()

        dockAlerts.ContentContainer.Controls.Clear()
        Dim widget As Control = LoadControl("dashboard_alerts.ascx")
        dockAlerts.ContentContainer.Controls.Add(widget)
    End Sub
    
    Private Sub LoadInboxWidget()
        dockInbox.ContentContainer.Controls.Clear()
        Dim widget As Control = LoadControl("dashboard_inbox.ascx")
        dockInbox.ContentContainer.Controls.Add(widget)
    End Sub
    
    Protected Sub cboAlertsView_SelectedIndexChanged(ByVal sender As Object, ByVal e As System.EventArgs) Handles cboAlertsView.SelectedIndexChanged
        Session("alertsview") = cboAlertsView.SelectedValue
        LoadAlertsWidget()

    End Sub

    Protected Sub cboPMProjectView_SelectedIndexChanged(ByVal sender As Object, ByVal e As System.EventArgs) Handles cboPMProjectView.SelectedIndexChanged
        Session("pmview") = cboPMProjectView.SelectedValue
        LoadPMOverviewWidget()

    End Sub
    
    Protected Sub cboInboxView_SelectedIndexChanged(ByVal sender As Object, ByVal e As System.EventArgs) Handles cboInboxView.SelectedIndexChanged
        
        Session("inboxview") = cboInboxView.SelectedValue
        LoadInboxWidget()

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
            db.SaveDockState(dockState, "DashboardDockSettings", "DistrictID", nDistrictID)
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
            db.SaveDockState(dockState, "DashboardDockSettings", "DistrictID", nDistrictID)
        End Using
    End Sub
    
    Protected Sub RadDockLayout1_LoadDockLayout(ByVal sender As Object, ByVal e As Telerik.Web.UI.DockLayoutEventArgs)

        If Request.Browser.Browser <> "IE" Then   'IE9 has prblems with dock control -- dfj 01/2012
            
        
            Dim serializer As New Script.Serialization.JavaScriptSerializer()
            'Get saved state string from the database - set it to dockState variable for example  
            Dim dockstate As String = ""
            Using db As New promptUserPrefs
                dockstate = db.GetDockState("DashboardDockSettings", "DistrictID", nDistrictID)
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
                            'error here so do nothing --  default config will prevail
                        End Try


                        e.Positions(state.UniqueName) = state.DockZoneID
                        e.Indices(state.UniqueName) = state.Index

                    End If
                Next
            End If
        End If

        dockInbox.Height = Unit.Pixel(350)
        CreateSaveStateTrigger(dockInbox)

        dockPMOverview.Height = Unit.Pixel(355)
        CreateSaveStateTrigger(dockPMOverview)

        
        dockAlerts.Height = Unit.Pixel(355)
        CreateSaveStateTrigger(dockAlerts)
  
  
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
<html>
<head runat="server" > 
<title ></title>
<meta http-equiv="X-UA-Compatible" content="IE=8" />
<%--NOTE: The metta tag above forces IE to render in IE8 compatibilty mode as the RAD dock breaking in IE9 - dfj 1/2012--%>
    <link href="Styles.css" rel="stylesheet" type="text/css" />
    <link href="skins/Prompt/Grid.Prompt.css" rel="stylesheet" type="text/css" />
    <link href="skins/Prompt/Dock.Prompt.css" rel="stylesheet" type="text/css" />
    <link href="skins/Prompt/Menu.Prompt.css" rel="stylesheet" type="text/css" />
</head>
<body>
    <form id="Form1" method="post" runat="server">
    <telerik:RadWindowManager ID="dashboardPopups" runat="server">
    </telerik:RadWindowManager>
    <telerik:RadScriptManager ID="RadScriptManager1" runat="server" />
    <telerik:RadStyleSheetManager ID="RadStyleSheetManager1" runat="server" />
    <div id="contentwrapper">
        <div class="innertube">
            <telerik:RadDockLayout ID="RadDockLayout1" runat="server" EnableEmbeddedSkins="false"
                Skin="Prompt" OnSaveDockLayout="RadDockLayout1_SaveDockLayout" OnLoadDockLayout="RadDockLayout1_LoadDockLayout">
                <telerik:RadDockZone ID="RadDockZone1" runat="server" Orientation="Vertical" FitDocks="True" Width="98%">
                 
                 <telerik:RadDock ID="dockAlerts" runat="server" Width="" Height="" Title="Alerts"
                        DockHandle="TitleBar" OnDockPositionChanged="RadDock1_DockPositionChanged"
                        EnableAnimation="true" AutoPostBack="false" EnableRoundedCorners="True" Resizable="false">
                        <Commands>
                            <telerik:DockCloseCommand />
                            <telerik:DockExpandCollapseCommand />
                        </Commands>
                        <TitlebarTemplate>
                            <asp:Label ID="Label1" runat="server" CssClass="widgetalertstitle" Text="Alerts"></asp:Label>
                       
                             <telerik:RadComboBox ID="cboAlertsView" runat="server" TabIndex="61" 
                                AutoPostBack="True" onselectedindexchanged="cboAlertsView_SelectedIndexChanged">
                               
                            </telerik:RadComboBox>

                        </TitlebarTemplate>
                        <ContentTemplate>
                        </ContentTemplate>
                    </telerik:RadDock>
                    

                    
                   <telerik:RadDock ID="dockPMOverview" runat="server" Width="" Height="" Title="My Projects"
                        DockHandle="TitleBar" DefaultCommands="ExpandCollapse" OnDockPositionChanged="RadDock1_DockPositionChanged"
                        EnableAnimation="true" AutoPostBack="false" EnableRoundedCorners="True" Resizable="false">
                        <Commands>
                            <telerik:DockCloseCommand />
                            <telerik:DockExpandCollapseCommand />
                        </Commands>
                        <TitlebarTemplate>
                            <asp:Label ID="Label4" runat="server" CssClass="widgetpmoverviewtitle">Project Health Dashboard</asp:Label>
                            <asp:DropDownList ID="cboPMProjectView" runat="server" AutoPostBack="True" 
                                onselectedindexchanged="cboPMProjectView_SelectedIndexChanged" Width="200px">
                               
                            </asp:DropDownList>
                        </TitlebarTemplate>
                        <ContentTemplate>
                        </ContentTemplate>
                    </telerik:RadDock>
                                       
                    <telerik:RadDock ID="dockInbox" runat="server" Width="" Height="325px" Title="Inbox"
                        DockHandle="TitleBar" DefaultCommands="ExpandCollapse" OnDockPositionChanged="RadDock1_DockPositionChanged"
                        EnableAnimation="true" AutoPostBack="false" EnableRoundedCorners="True" Resizable="false">
                         <Commands>
                            <telerik:DockCloseCommand />
                            <telerik:DockExpandCollapseCommand />
                        </Commands>
                          <TitlebarTemplate>
                            <asp:Label ID="Label2" runat="server" CssClass="widgetinboxtitle">Inbox</asp:Label>

                           <telerik:RadComboBox ID="cboInboxView" runat="server" TabIndex="61" 
                                AutoPostBack="True" onselectedindexchanged="cboInboxView_SelectedIndexChanged">
                               
                            </telerik:RadComboBox>
                                                   
                        </TitlebarTemplate>
                        <ContentTemplate>
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
                    <telerik:AjaxSetting AjaxControlID="grid_Inbox">
                        <UpdatedControls>
                            <telerik:AjaxUpdatedControl ControlID="grid_Inbox" LoadingPanelID="RadAjaxLoadingPanel1" />
                        </UpdatedControls>
                    </telerik:AjaxSetting>
                    
                      <telerik:AjaxSetting AjaxControlID="cboInboxView">
                        <UpdatedControls>

                          <telerik:AjaxUpdatedControl ControlID="grid_Inbox" LoadingPanelID="RadAjaxLoadingPanel1" />
                                                       
                        </UpdatedControls>
                    </telerik:AjaxSetting>
                    
                   <telerik:AjaxSetting AjaxControlID="chkShowPaid">
                        <UpdatedControls>
                              <telerik:AjaxUpdatedControl ControlID="grid_Inbox" LoadingPanelID="RadAjaxLoadingPanel1" />
                        </UpdatedControls>
                    </telerik:AjaxSetting>
                    
                     <telerik:AjaxSetting AjaxControlID="grid_PMOverview">
                        <UpdatedControls>
                            <telerik:AjaxUpdatedControl ControlID="grid_PMOverview" LoadingPanelID="RadAjaxLoadingPanel1" />
                        </UpdatedControls>
                    </telerik:AjaxSetting>
                   <telerik:AjaxSetting AjaxControlID="cboPMProjectView">
                        <UpdatedControls>
                            <telerik:AjaxUpdatedControl ControlID="grid_PMOverview" LoadingPanelID="RadAjaxLoadingPanel1" />
                        </UpdatedControls>
                    </telerik:AjaxSetting>
                     <telerik:AjaxSetting AjaxControlID="grid_Alerts">
                        <UpdatedControls>
                            <telerik:AjaxUpdatedControl ControlID="grid_Alerts" LoadingPanelID="RadAjaxLoadingPanel1" />
                        </UpdatedControls>
                    </telerik:AjaxSetting>
                   <telerik:AjaxSetting AjaxControlID="cboAlertsView">
                        <UpdatedControls>
                            <telerik:AjaxUpdatedControl ControlID="grid_Alerts" LoadingPanelID="RadAjaxLoadingPanel1" />
                        </UpdatedControls>
                    </telerik:AjaxSetting>
                </AjaxSettings>
            </telerik:RadAjaxManager>
            <telerik:RadAjaxLoadingPanel ID="RadAjaxLoadingPanel1" runat="server" Height="75px"
                Width="75px" Transparency="25">
                <img alt="Loading..." src='<%= RadAjaxLoadingPanel.GetWebResourceUrl(Page, "Telerik.Web.UI.Skins.Default.Ajax.loading.gif") %>'
                    style="border: 0;" />
            </telerik:RadAjaxLoadingPanel>
        </div>
    </div>
    </form>
    <telerik:RadCodeBlock ID="RadCodeBlock1" runat="server">

        <script type="text/javascript" language="javascript">

            function GetRadWindow() {
                var oWindow = null;
                if (window.RadWindow) oWindow = window.RadWindow;
                else if (window.frameElement.radWindow) oWindow = window.frameElement.radWindow;
                return oWindow;
            }
        
 
    
        </script>

    </telerik:RadCodeBlock>
</body>
</html>
