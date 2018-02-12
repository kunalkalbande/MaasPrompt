<%@ Page Language="VB" MasterPageFile="~/content.master" Title="" %>

<%@ Register Assembly="Telerik.Web.UI" Namespace="Telerik.Web.UI" TagPrefix="telerik" %>
<%@ Import Namespace="Prompt" %>

<script runat="server">
    
    Private bReadOnly As Boolean = True
    Private nProjectID As Integer = 0
    Private bHideAnswered As Boolean = False
    
    Protected Sub Page_PreRender(ByVal sender As Object, ByVal e As System.EventArgs)
        Using db As New promptUserPrefs
            db.SaveGridSettings(RadGrid1, "InfoBulletinGridSettings", "ProjectID", nProjectID)
        End Using
    End Sub

    Protected Sub Page_Init(ByVal sender As Object, ByVal e As System.EventArgs)
        nProjectID = Request.QueryString("ProjectID")
        'set security
        Using dbsec As New EISSecurity
            dbsec.ProjectID = nProjectID
            If dbsec.FindUserPermission("InfoBulletinLog", "write") Then
                bReadOnly = False
            Else
                bReadOnly = True
            End If
        End Using
        If Not IsPostBack Then
            Using db As New promptUserPrefs
                db.LoadGridSettings(RadGrid1, "InfoBulletinGridSettings", "ProjectID", nProjectID)
                db.LoadGridColumnVisibility(RadGrid1, "InfoBulletinGridColumns", "ProjectID", nProjectID)
            End Using
        End If

    End Sub
    
    Private Sub Page_Load(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MyBase.Load

        ProcLib.CheckSession(Page)
        ProcLib.LoadPopupJscript(Page)

        ''set up help button
        Session("PageID") = "InfoBulletins"
        nProjectID = Request.QueryString("ProjectID")
        
         
        Dim masterTabs As RadTabStrip = Master.FindControl("tabMain")
        Dim masterViewTitle As Label = Master.FindControl("lblViewTitle")
        
        Session("CurrentTab") = "InfoBulletins"
        For Each radTab In masterTabs.GetAllTabs
            If radTab.Value = "InfoBulletins" Then
                radTab.Selected = True
                radTab.SelectParents()
                Exit For
            End If
        Next
 
        'Set Grid Properties
        With RadGrid1
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

            .Height = Unit.Pixel(600)

            .ExportSettings.FileName = "PromptInfoBulletinExport"
            .ExportSettings.OpenInNewWindow = True
            .ExportSettings.Pdf.PageTitle = masterViewTitle.Text & " InfoBulletins"
        End With
        

        BuildMenu()

        With contentPopup
            .VisibleOnPageLoad = False
            .Skin = "Windows7"
                         
            Dim ww As New RadWindow

            ww = New RadWindow
            With ww
                .ID = "EditWindow"
                '.NavigateUrl = "#"
                
                .Title = ""
                .Width = 600
                .Height = 450
                .Modal = True
                .VisibleStatusbar = False
                .ReloadOnShow = True
                .Behaviors = WindowBehaviors.Close + WindowBehaviors.Move
            End With
            .Windows.Add(ww)
            
            ww = New RadWindow
            With ww
                .ID = "AttachmentsWindow"
                .NavigateUrl = "#"
                .Title = ""
                .Width = 500
                .Height = 350
                .Modal = True
                .VisibleStatusbar = False
                .ReloadOnShow = True
                .Behaviors = WindowBehaviors.Close + WindowBehaviors.Move
            End With
            .Windows.Add(ww)
        End With

    End Sub
    
    Private Sub BuildMenu()
        
        If Not IsPostBack Then          'Configure Tool Bar
            
            With RadMenu1
                .EnableEmbeddedSkins = False
                .Skin = "Prompt"
                .Width = Unit.Percentage(100)
                .EnableOverlay = False
                .OnClientItemClicking = "OnClientItemClicking"
 
                .CollapseAnimation.Duration = "200"
                .CollapseAnimation.Type = AnimationType.InOutBounce
                .ExpandAnimation.Duration = "200"
                .ExpandAnimation.Type = AnimationType.InOutBounce
            End With
            
            'build buttons
            Dim but As RadMenuItem
                
            but = New RadMenuItem
            With but
                .Text = "Add New"
                .ImageUrl = "images/add.png"
                .Attributes("onclick") = "return EditInfoBulletin('0'," & nProjectID & ");"
                .ToolTip = "Add a New InfoBulletin."
                .PostBack = False
                If bReadOnly Then
                    .Visible = False
                Else
                    .Visible = True
                End If
            End With
            RadMenu1.Items.Add(but)

            Dim butDropDown As New RadMenuItem
            With butDropDown
                .Text = "Export"
                .ImageUrl = "images/data_down.png"
                .PostBack = False
            End With
            
            'Add sub items
            Dim butSub As New RadMenuItem
            With butSub
                .Text = "Export To Excel"
                .Value = "ExportExcel"
                .Attributes("CancelAjax") = "Y"   'NOTE: This is needed to cancel ajax call and do regular postback as grid export to pdf/execl does not work with ajax
                .ImageUrl = "images/excel.gif"
                .PostBack = True
            End With
            butDropDown.Items.Add(butSub)
            
            butSub = New RadMenuItem
            With butSub
                .Text = "Export To PDF"
                .Value = "ExportPDF"
                .Attributes("CancelAjax") = "Y"   'NOTE: This is needed to cancel ajax call and do regular postback as grid export to pdf/execl does not work with ajax
                .ImageUrl = "images/prompt_pdf.gif"
                .PostBack = True
            End With
            butDropDown.Items.Add(butSub)
            RadMenu1.Items.Add(butDropDown)
 
            butDropDown = New RadMenuItem
            With butDropDown
                .Text = "Print"
                .ImageUrl = "images/printer.png"
                .PostBack = False
            End With
 
            'butSub = New RadMenuItem
            'With butSub
            '    .Text = "Print InfoBulletin Log"
            '    .ImageUrl = "images/printer.png"
            '    .Target = "_new"
            '    '.NavigateUrl = "http://216.129.104.66/Q34JF8SFA/Pages/ReportViewer.aspx?%2fPromptReports%2fInfoBulletin_log&Dist=56&Proj=" & nProjectID
            '    .PostBack = False
            'End With
            'butDropDown.Items.Add(butSub)
            
            RadMenu1.Items.Add(butDropDown)
            
            
            but = New RadMenuItem
            but.IsSeparator = True
            RadMenu1.Items.Add(but)
            
            'but = New RadMenuItem
            'With but
            '    .Text = "Hide Answered"
            '    .Value = "HideAnswered"
            '    .ImageUrl = "images/funnel.png"
            '    .Attributes("Filter") = "Off"
            'End With
            'RadMenu1.Items.Add(but)
 
               
            'but = New RadMenuItem
            'but.IsSeparator = True
            'RadMenu1.Items.Add(but)
            
            'Add grid configurator       
            Dim butConfig As New RadMenuItem
            With butConfig
                .Text = "Preferences"
                .ImageUrl = "images/gear.png"
                .PostBack = False
            End With
            RadMenu1.Items.Add(butConfig)
            
            'Add sub items
            Dim butConfigSub As New RadMenuItem
            With butConfigSub
                .Text = "Visible Columns"
                .ImageUrl = "images/column_preferences.png"
                .PostBack = False
            End With
            
            'Load the avaialble columns as checkbox items
            For Each col As GridColumn In RadGrid1.Columns
                If col.HeaderText <> "" Then
                    Dim butCol As New RadMenuItem
                    With butCol
                        .Text = col.HeaderText
                        .Value = "ColumnVisibility"
                        If col.Visible = True Then
                            .ImageUrl = "images/check2.png"
                            .Attributes("Visibility") = "On"
                        Else
                            .ImageUrl = ""
                            .Attributes("Visibility") = "Off"
                        End If
                        
                        .Attributes("ID") = col.UniqueName
                    End With
                    butConfigSub.Items.Add(butCol)
                End If
 
            Next
            butConfig.Items.Add(butConfigSub)
            
            'Add sub items
            butConfigSub = New RadMenuItem
            With butConfigSub
                .Text = "Restore Default Settings"
                .Value = "RestoreDefaultSettings"
                .ImageUrl = "images/gear_refresh.png"
            End With
            butConfig.Items.Add(butConfigSub)
        End If

    End Sub
    
    
    Protected Sub RadGrid1_NeedDataSource(ByVal source As Object, ByVal e As Telerik.Web.UI.GridNeedDataSourceEventArgs) Handles RadGrid1.NeedDataSource
        
        Using db As New InfoBulletin
            RadGrid1.DataSource = db.GetAllProjectInfoBulletins(nProjectID)
        End Using
        
    End Sub
    
    Protected Sub RadGrid1_ItemCreated(ByVal sender As Object, ByVal e As Telerik.Web.UI.GridItemEventArgs) Handles RadGrid1.ItemCreated
        
        'This event allows us to customize the cell contents - fired before databound
        
        If (TypeOf e.Item Is GridDataItem) Then
            Dim item As GridDataItem = CType(e.Item, GridDataItem)
            Dim nInfoBulletinID As Integer = item.OwnerTableView.DataKeyValues(item.ItemIndex)("InfoBulletinID")
            Dim sInfoBulletinRef As String = item.OwnerTableView.DataKeyValues(item.ItemIndex)("Reference")
            Dim sAttachments As String = item.OwnerTableView.DataKeyValues(item.ItemIndex)("Attachments")
                        
            Dim linkButton As HyperLink

            If bReadOnly Then
                item("InfoBulletinID").Controls.Clear()
                item("InfoBulletinID").Text = nInfoBulletinID
            Else
                linkButton = CType(item("InfoBulletinID").Controls(0), HyperLink)
                linkButton.Attributes("onclick") = "return EditInfoBulletin(" & nInfoBulletinID & "," & nProjectID & ");"
                linkButton.NavigateUrl = "#"
                linkButton.ToolTip = "Edit this Information Bulletin."
            End If
            
            
            'update the link button to open attachments/notes window
            linkButton = CType(item("Attachments").Controls(0), HyperLink)
            linkButton.ToolTip = "Upload Attachments."
            linkButton.NavigateUrl = "#"
            linkButton.ImageUrl = "images/add.png"
            
            linkButton.Attributes("onclick") = "return ManageAttachments('" & nInfoBulletinID & "','" & nProjectID & "');"
            
            If sAttachments = "Y" Then    'update image
                linkButton.ImageUrl = "images/paper_clip_small.gif"
            End If
            
            
        End If
        
        
    End Sub
    
    Private Sub RadGrid1_ItemDataBound(ByVal sender As Object, ByVal e As Telerik.Web.UI.GridItemEventArgs) Handles RadGrid1.ItemDataBound
        'If (TypeOf e.Item Is GridDataItem) Then

        'End If
        
    End Sub
 
  
    Protected Sub RadMenu1_ItemClick(ByVal sender As Object, ByVal e As Telerik.Web.UI.RadMenuEventArgs)
       
        Dim btn As RadMenuItem = e.Item
        
        Select Case btn.Value
            
            Case "ExportExcel"
                RadGrid1.Columns.FindByUniqueName("Attachments").Visible = False
                RadGrid1.MasterTableView.ExportToExcel()
                
            Case "ExportPDF"
                RadGrid1.Columns.FindByUniqueName("Attachments").Visible = False
                For Each item As GridItem In RadGrid1.MasterTableView.Items
                    If TypeOf item Is GridDataItem Then
                        Dim dataItem As GridDataItem = CType(item, GridDataItem)
                        Dim lnk As HyperLink = CType(dataItem("InfoBulletinID").Controls(0), HyperLink)
                        lnk.NavigateUrl = ""
                    End If
                Next
                RadGrid1.MasterTableView.ExportToPdf()
            
                    
            Case "ColumnVisibility"
                If btn.Attributes("Visibility") = "Off" Then
                    btn.ImageUrl = "images/check2.png"
                    btn.Attributes("Visibility") = "On"
                    RadGrid1.Columns.FindByUniqueName(btn.Attributes("ID")).Visible = True
                Else
                    btn.ImageUrl = ""
                    btn.Attributes("Visibility") = "Off"
                    RadGrid1.Columns.FindByUniqueName(btn.Attributes("ID")).Visible = False
                End If
                Using db As New promptUserPrefs
                    db.SaveGridColumnVisibility("InfoBulletinGridColumns", btn.Attributes("ID"), btn.Attributes("Visibility"), "ProjectID", nProjectID)
                End Using
                RadGrid1.Rebind()
                
            Case "RestoreDefaultSettings"
                
                Using db As New promptUserPrefs
                    db.RemoveUserSavedSettings("InfoBulletinGridSettings", "ProjectID", nProjectID)
                    db.RemoveUserSavedSettings("InfoBulletinGridColumns", "ProjectID", nProjectID)
                End Using
                Response.Redirect(Page.Request.RawUrl)

        End Select
    End Sub

 
</script>

<asp:Content ID="Content1" ContentPlaceHolderID="mainBody" runat="Server">
    <telerik:radwindowmanager id="contentPopup" runat="server" />
    <telerik:radmenu id="RadMenu1" runat="server" onitemclick="RadMenu1_ItemClick" style="z-index: 10;" />
    <telerik:radgrid id="RadGrid1" runat="server" allowsorting="true" autogeneratecolumns="False"
        gridlines="None" width="99%" enableembeddedskins="false" enableajax="True" skin="Prompt">
        <ClientSettings>
            <Selecting AllowRowSelect="False" />
            <Scrolling AllowScroll="True" UseStaticHeaders="True" ScrollHeight="50%" />
        </ClientSettings>
        <MasterTableView Width="99%" GridLines="None" DataKeyNames="InfoBulletinID,Attachments"
            NoMasterRecordsText="No Information Bulletins found.">
            <Columns>
                <telerik:GridHyperLinkColumn UniqueName="InfoBulletinID" HeaderText="No." DataTextField="InfoBulletinID"
                    SortExpression="InfoBulletinID">
                    <ItemStyle HorizontalAlign="Left" Width="35px" VerticalAlign="Top" />
                    <HeaderStyle HorizontalAlign="Left" Width="35px" />
                </telerik:GridHyperLinkColumn>
                <telerik:GridBoundColumn DataField="IBDate" HeaderText="Date" UniqueName="IBDate"
                    DataFormatString="{0:MM/dd/yy}">
                    <ItemStyle Width="55px" HorizontalAlign="Center" VerticalAlign="Top" />
                    <HeaderStyle Width="55px" HorizontalAlign="Center" />
                </telerik:GridBoundColumn>
                <telerik:GridBoundColumn UniqueName="Reference" HeaderText="Reference" DataField="Reference">
                    <ItemStyle HorizontalAlign="Left" Width="45px" VerticalAlign="Top" />
                    <HeaderStyle HorizontalAlign="Left" Width="45px" />
                </telerik:GridBoundColumn>
                <telerik:GridBoundColumn UniqueName="IBFromName" HeaderText="From" DataField="IBFromName">
                    <ItemStyle HorizontalAlign="Left" Width="55px" VerticalAlign="Top" />
                    <HeaderStyle HorizontalAlign="Left" Width="55px" />
                </telerik:GridBoundColumn>
                <telerik:GridBoundColumn UniqueName="IBToName" HeaderText="To" DataField="IBToName">
                    <ItemStyle HorizontalAlign="Left" Width="55px" VerticalAlign="Top" />
                    <HeaderStyle HorizontalAlign="Left" Width="55px" />
                </telerik:GridBoundColumn>
                <telerik:GridBoundColumn UniqueName="Description" HeaderText="Description" DataField="Description">
                    <ItemStyle HorizontalAlign="Left" Width="25%" VerticalAlign="Top" />
                    <HeaderStyle HorizontalAlign="Left" Width="25%" />
                </telerik:GridBoundColumn>
                <telerik:GridBoundColumn UniqueName="Location" HeaderText="Location" DataField="Location">
                    <ItemStyle HorizontalAlign="Left" Width="75px" VerticalAlign="Top" />
                    <HeaderStyle HorizontalAlign="Left" Width="75px" />
                </telerik:GridBoundColumn>
                <telerik:GridHyperLinkColumn HeaderText="Att" UniqueName="Attachments">
                    <ItemStyle Width="20px" HorizontalAlign="Center" VerticalAlign="Top" />
                    <HeaderStyle Width="20px" HorizontalAlign="Center" />
                </telerik:GridHyperLinkColumn>
            </Columns>
        </MasterTableView>
        <ExportSettings OpenInNewWindow="True">
            <Pdf PageWidth="297mm" PageHeight="210mm" />
        </ExportSettings>
    </telerik:radgrid>
    <telerik:radajaxmanager id="RadAjaxManager1" runat="server">
        <ClientEvents OnRequestStart="ajaxRequestStart" OnResponseEnd="ajaxRequestEnd" />
        <AjaxSettings>
            <telerik:AjaxSetting AjaxControlID="RadGrid1">
                <UpdatedControls>
                    <telerik:AjaxUpdatedControl ControlID="RadGrid1" LoadingPanelID="RadAjaxLoadingPanel1" />
                </UpdatedControls>
            </telerik:AjaxSetting>
            <telerik:AjaxSetting AjaxControlID="RadMenu1">
                <UpdatedControls>
                    <telerik:AjaxUpdatedControl ControlID="RadGrid1" LoadingPanelID="RadAjaxLoadingPanel1" />
                    <telerik:AjaxUpdatedControl ControlID="RadMenu1" LoadingPanelID="RadAjaxLoadingPanel1" />
                </UpdatedControls>
            </telerik:AjaxSetting>
        </AjaxSettings>
    </telerik:radajaxmanager>
    <telerik:radajaxloadingpanel id="RadAjaxLoadingPanel1" runat="server" height="75px"
        width="75px" transparency="25">
        <img alt="Loading..." src="images/loading.gif" style="border: 0;" />
    </telerik:radajaxloadingpanel>

    <telerik:radtooltipmanager id="RadToolTipManager1" runat="server" sticky="True" title=""
        position="BottomCenter" skin="Office2007" hidedelay="500" manualclose="False"
        showevent="OnMouseOver" showdelay="100" animation="Fade" autoclosedelay="6000"
        AutoTooltipify="False" width="350" relativeto="Mouse" renderinpageroot="False">
    </telerik:radtooltipmanager>
    <telerik:radscriptblock id="RadScriptBlock1" runat="server">

        <script type="text/javascript" language="javascript">

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

            function ManageAttachments(id, projectid)     //for attachments info display
            {

                var oWnd = window.radopen("apprisepm_attachments_manage.aspx?ParentType=InfoBulletin&ParentID=" + id + "&ProjectID=" + projectid, "AttachmentsWindow");
                return false;
            }


            function EditInfoBulletin(id, projectid) {

                var oWnd = window.radopen("infobulletin_edit.aspx?InfoBulletinID=" + id + "&ProjectID=" + projectid, "EditWindow");
                return false;
            }



        </script>

    </telerik:radscriptblock>
</asp:Content>
