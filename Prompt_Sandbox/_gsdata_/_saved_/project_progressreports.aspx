<%@ Page Language="VB" MasterPageFile="~/content.master" Title="" %>

<%@ Register Assembly="Telerik.Web.UI" Namespace="Telerik.Web.UI" TagPrefix="telerik" %>
<%@ Import Namespace="Prompt" %>

<script runat="server">
    
    Private bReadOnly As Boolean = True
    Private nProjectID As Integer = 0
        
    Protected Sub Page_PreRender(ByVal sender As Object, ByVal e As System.EventArgs)
        Using db As New promptUserPrefs
            db.SaveGridSettings(RadGrid1, "ProgressReportGridSettings", "ProjectID", nProjectID)
        End Using
    End Sub

    Protected Sub Page_Init(ByVal sender As Object, ByVal e As System.EventArgs)
        nProjectID = Request.QueryString("ProjectID")
        'set security
        Using dbsec As New EISSecurity
            dbsec.ProjectID = nProjectID
            If dbsec.FindUserPermission("PMProgressReport", "write") Then
                bReadOnly = False
            Else
                bReadOnly = True
            End If
        End Using
        If Not IsPostBack Then
            Using db As New promptUserPrefs
                db.LoadGridSettings(RadGrid1, "ProgressReportGridSettings", "ProjectID", nProjectID)
                db.LoadGridColumnVisibility(RadGrid1, "ProgressReportGridColumns", "ProjectID", nProjectID)
            End Using
        End If

    End Sub
    
    Private Sub Page_Load(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MyBase.Load

        ProcLib.CheckSession(Page)
        ProcLib.LoadPopupJscript(Page)

        ''set up help button
        Session("PageID") = "ProgressReports"
        nProjectID = Request.QueryString("ProjectID")
        
         
        Dim masterTabs As RadTabStrip = Master.FindControl("tabMain")
        Dim masterViewTitle As Label = Master.FindControl("lblViewTitle")
        
        Session("CurrentTab") = "PMProgressReports"
        For Each radTab In masterTabs.GetAllTabs
            If radTab.Value = "PMProgressReports" Then
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

            .ExportSettings.FileName = "PromptProgressReportExport"
            .ExportSettings.OpenInNewWindow = True
            .ExportSettings.Pdf.PageTitle = masterViewTitle.Text & " ProgressReports"
            
                   
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
                .Width = 700
                .Height = 675
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
                .Attributes("onclick") = "return EditProgressReport('0'," & nProjectID & ");"
                .ToolTip = "Add a New ProgressReport."
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
    
            
            RadMenu1.Items.Add(butDropDown)
 
            butDropDown = New RadMenuItem
            With butDropDown
                .Text = "Print"
                .ImageUrl = "images/printer.png"
                .PostBack = False
            End With
       
            RadMenu1.Items.Add(butDropDown)
            
            
            'but = New RadMenuItem
            'but.IsSeparator = True
            'RadMenu1.Items.Add(but)

               
            but = New RadMenuItem
            but.IsSeparator = True
            RadMenu1.Items.Add(but)
            
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
                If col.HeaderText <> "" And col.HeaderText <> "Date" Then
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
        
        Using db As New ProgressReport
            RadGrid1.DataSource = db.GetAllProgressReports(nProjectID)
        End Using
        
    End Sub
    
    Protected Sub RadGrid1_ItemCreated(ByVal sender As Object, ByVal e As Telerik.Web.UI.GridItemEventArgs) Handles RadGrid1.ItemCreated
        
        'This event allows us to customize the cell contents - fired before databound
        
        If (TypeOf e.Item Is GridDataItem) Then
            Dim item As GridDataItem = CType(e.Item, GridDataItem)
            Dim nProgressReportID As Integer = item.OwnerTableView.DataKeyValues(item.ItemIndex)("ProgressReportID")
            Dim sReport As String = ProcLib.CheckNullDBField(item.OwnerTableView.DataKeyValues(item.ItemIndex)("ReportFileName"))

            Dim linkButton As HyperLink

            If bReadOnly Then
                item("ReportDate").Controls.Clear()
                item("ReportDate").Text = nProgressReportID
            Else
                linkButton = CType(item("ReportDate").Controls(0), HyperLink)
                linkButton.Attributes("onclick") = "return EditProgressReport(" & nProgressReportID & "," & nProjectID & ");"
                linkButton.NavigateUrl = "#"
                linkButton.ToolTip = "Edit this ProgressReport."
            End If


            'Note: These do not use rad windows as they are external opens
            If Not sReport = "(None Attached)" Then
                Dim sPath As String = ProcLib.GetCurrentRelativeAttachmentPath() & "DistrictID_" & Session("DistrictID") & "/_apprisedocs/_progressreports/ProjectID_" & nProjectID & "/"
                Dim linkButton2 As HyperLink = CType(item("ReportFileName").Controls(0), HyperLink)
                linkButton2.ToolTip = "Show attachement for this Report."
                linkButton2.NavigateUrl = sPath & sReport
                linkButton2.ImageUrl = "images/paper_clip_small.gif"
                linkButton2.Target = "_new"
               
            Else            'remove the hyperlink and just display none
                item("ReportFileName").Controls.Clear()
                item("ReportFileName").Text = sReport
            End If
     

        End If
        
        
    End Sub
    
    Private Sub RadGrid1_ItemDataBound(ByVal sender As Object, ByVal e As Telerik.Web.UI.GridItemEventArgs) Handles RadGrid1.ItemDataBound
        'If (TypeOf e.Item Is GridDataItem) Then
        '    If TypeOf e.Item Is GridDataItem Then
        '        Dim dataitem As GridDataItem = e.Item
        '        Dim sReport As String = ProcLib.CheckNullDBField(dataitem.OwnerTableView.DataKeyValues(dataitem.ItemIndex)("ReportFileName"))
        '        If Not sReport = "(None Attached)" Then
        '            Dim linkButton2 As HyperLink = CType(dataitem("ReportFileName").Controls(0), HyperLink)
        '            linkButton2.Text = "Click to download"
        '        End If

        '    End If


        'End If
        
    End Sub
  
    Protected Sub RadMenu1_ItemClick(ByVal sender As Object, ByVal e As Telerik.Web.UI.RadMenuEventArgs)
       
        Dim btn As RadMenuItem = e.Item
        
        Select Case btn.Value
            
            Case "ExportExcel"
                RadGrid1.Columns.FindByUniqueName("ReportFileName").Visible = False
                RadGrid1.MasterTableView.ExportToExcel()
                
            Case "ExportPDF"
                RadGrid1.Columns.FindByUniqueName("ReportFileName").Visible = False
                For Each item As GridItem In RadGrid1.MasterTableView.Items
                    If TypeOf item Is GridDataItem Then
                        Dim dataItem As GridDataItem = CType(item, GridDataItem)
                        Dim lnk As HyperLink = CType(dataItem("ReportDate").Controls(0), HyperLink)
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
                    db.SaveGridColumnVisibility("ProgressReportGridColumns", btn.Attributes("ID"), btn.Attributes("Visibility"), "ProjectID", nProjectID)
                End Using
                RadGrid1.Rebind()
                
            Case "RestoreDefaultSettings"
                
                Using db As New promptUserPrefs
                    db.RemoveUserSavedSettings("ProgressReportGridSettings", "ProjectID", nProjectID)
                    db.RemoveUserSavedSettings("ProgressReportGridColumns", "ProjectID", nProjectID)
                End Using
                Response.Redirect(Page.Request.RawUrl)

        End Select
    End Sub

 
</script>

<asp:Content ID="Content1" ContentPlaceHolderID="mainBody" runat="Server">
    <telerik:RadWindowManager ID="contentPopup" runat="server">
    </telerik:RadWindowManager>
    <telerik:RadMenu ID="RadMenu1" runat="server" OnItemClick="RadMenu1_ItemClick" Style="z-index: 10;" />
    <telerik:RadGrid ID="RadGrid1" runat="server" AllowSorting="true" AutoGenerateColumns="False"
        GridLines="None" Width="99%" EnableEmbeddedSkins="false" enableajax="True" Skin="Prompt">
        <ClientSettings>
            <Selecting AllowRowSelect="False" />
            <Scrolling AllowScroll="True" UseStaticHeaders="True" ScrollHeight="50%" />
        </ClientSettings>
        <MasterTableView Width="100%" GridLines="None" DataKeyNames="ProgressReportID,ReportFileName"
            NoMasterRecordsText="No Progress Reports found.">
            <Columns>
                <telerik:GridHyperLinkColumn DataTextField="ReportDate" HeaderText="Date" UniqueName="ReportDate"
                    SortExpression="ReportDate" DataTextFormatString="{0:MM/dd/yy}">
                    <ItemStyle Width="65px" HorizontalAlign="Center" VerticalAlign="Top" />
                    <HeaderStyle Width="65px" Height="20px" HorizontalAlign="Center" />
                </telerik:GridHyperLinkColumn>
                <telerik:GridBoundColumn UniqueName="Title" HeaderText="Title" DataField="Title">
                    <ItemStyle HorizontalAlign="Left" VerticalAlign="Top" />
                    <HeaderStyle HorizontalAlign="Left"  />
                </telerik:GridBoundColumn>
                <telerik:GridBoundColumn UniqueName="SubmittedBy" HeaderText="By" DataField="SubmittedBy">
                    <ItemStyle HorizontalAlign="Left" Width="25%" VerticalAlign="Top" />
                    <HeaderStyle HorizontalAlign="Left" Width="25%" />
                </telerik:GridBoundColumn>
                
            <telerik:GridHyperLinkColumn UniqueName="Report" HeaderText="Rpt" DataTextField="Report">
                <ItemStyle HorizontalAlign="Left" Width="60px" />
                <HeaderStyle HorizontalAlign="Left" Width="60px" />
            </telerik:GridHyperLinkColumn>
               
             <telerik:GridHyperLinkColumn UniqueName="ReportFileName" HeaderText="Att" DataTextField="ReportFileName">
                <ItemStyle HorizontalAlign="Left" Width="60px" />
                <HeaderStyle HorizontalAlign="Left" Width="60px" />
            </telerik:GridHyperLinkColumn>
            </Columns>
        </MasterTableView>
        <ExportSettings OpenInNewWindow="True">
            <Pdf PageWidth="297mm" PageHeight="210mm" />
        </ExportSettings>
    </telerik:RadGrid>
    <telerik:RadAjaxManager ID="RadAjaxManager1" runat="server">
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
    </telerik:RadAjaxManager>
    <telerik:RadAjaxLoadingPanel ID="RadAjaxLoadingPanel1" runat="server" Height="75px"
        Width="75px" Transparency="25">
        <img alt="Loading..." src="images/loading.gif" style="border: 0;" />
    </telerik:RadAjaxLoadingPanel>
    <%--           </div>
        </div>
    </div>--%>
    <telerik:RadToolTipManager ID="RadToolTipManager1" runat="server" Sticky="True" Title=""
        Position="BottomCenter" Skin="Office2007" HideDelay="500" ManualClose="False"
        ShowEvent="OnMouseOver" ShowDelay="100" Animation="Fade" AutoCloseDelay="600"
        AutoTooltipify="False" Width="350" RelativeTo="Mouse" RenderInPageRoot="False">
    </telerik:RadToolTipManager>
    <telerik:RadScriptBlock ID="RadScriptBlock1" runat="server">

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

            function ManageAttachments(id)     //for attachments info display
            {

                var oWnd = window.radopen("apprisepm_attachments_manage.aspx?ParentType=ProgressReport&ParentID=" + id, "AttachmentsWindow");
                return false;
            }

            function EditProgressReport(id, projectid) {

                var oWnd = window.radopen("project_progressreport_edit.aspx?ProjectID=" + projectid + "&ProgressReportID=" + id, "EditWindow");
                return false;
            }
        </script>

    </telerik:RadScriptBlock>
</asp:Content>
