<%@ Page Language="VB" MasterPageFile="~/content.master" Title="" %>

<%@ Import Namespace="System.IO" %>

<%@ Register Assembly="Telerik.Web.UI" Namespace="Telerik.Web.UI" TagPrefix="telerik" %>
<%@ Import Namespace="Prompt" %>

<script runat="server">
    
    Private bReadOnly As Boolean = True
    Private nProjectID As Integer = 0
    
    'Protected Sub Page_PreRender(ByVal sender As Object, ByVal e As System.EventArgs)
    '    Using db As New promptUserPrefs
    '        db.SaveGridSettings(RadGrid1, "PADGridSettings", "ProjectID", nProjectID)
    '    End Using

    'End Sub

    Protected Sub Page_Init(ByVal sender As Object, ByVal e As System.EventArgs)
        nProjectID = Request.QueryString("ProjectID")
        'set security
        Using dbsec As New EISSecurity
            dbsec.ProjectID = nProjectID
            If dbsec.FindUserPermission("PADLog", "write") Then
                bReadOnly = False
            Else
                bReadOnly = True
            End If
        End Using
        'If Not IsPostBack Then
        '    Using db As New promptUserPrefs
        '        db.LoadGridSettings(RadGrid1, "PADGridSettings", "ProjectID", nProjectID)
        '        db.LoadGridColumnVisibility(RadGrid1, "PADGridColumns", "ProjectID", nProjectID)
        '    End Using
        'End If

    End Sub
    
    Private Sub Page_Load(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MyBase.Load

        ProcLib.CheckSession(Page)
        ProcLib.LoadPopupJscript(Page)

        ''set up help button
        Session("PageID") = "PADs"
        nProjectID = Request.QueryString("ProjectID")
        
        'If Request.Browser.Browser = "IE" Then
        RadGrid1.Height = Unit.Pixel(600)
        'Else
        '.Height = Unit.Percentage(88)
        'End If
        
        Dim masterTabs As RadTabStrip = Master.FindControl("tabMain")
        Session("CurrentTab") = "PADs"
        For Each radTab In masterTabs.GetAllTabs
            If radTab.Value = "PADs" Then
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

            'If Request.Browser.Browser = "IE" Then
            RadGrid1.Height = Unit.Pixel(600)
            'Else
            '.Height = Unit.Percentage(88)
            'End If
            
            .ExportSettings.FileName = "PromptPADsExport"
            .ExportSettings.OpenInNewWindow = True
        End With
        
        With contentPopup
            .VisibleOnPageLoad = False
            .Skin = "Windows7"
                         
            Dim ww As New RadWindow

            ww = New RadWindow
            With ww
                .ID = "EditWindow"
                .NavigateUrl = "#"
                .Title = ""
                .Width = 570
                .Height = 475
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
            
                       ww = New RadWindow
            With ww
                .ID = "WorkflowHistory"
                .NavigateUrl = ""
                .Title = ""
                .Width = 650
                .Height = 400
                .Top = 200
                .Left = 20
                .Modal = False
                .VisibleStatusbar = False
                .ReloadOnShow = True
                
                .Behaviors = WindowBehaviors.Close + WindowBehaviors.Move
            End With
            .Windows.Add(ww)
            
            
            ww = New RadWindow
            With ww
                .ID = "WorkflowApproval"
                .NavigateUrl = ""
                .Title = ""
                .Width = 500
                .Height = 300
                .Top = 200
                .Left = 20
                .Modal = False
                .VisibleStatusbar = False
                .ReloadOnShow = True
                .Behaviors = WindowBehaviors.Close + WindowBehaviors.Move
            End With
            .Windows.Add(ww)
            
              
            
        End With
 
        BuildMenu()
          
    End Sub
    
    Protected Sub RadGrid1_NeedDataSource(ByVal source As Object, ByVal e As Telerik.Web.UI.GridNeedDataSourceEventArgs) Handles RadGrid1.NeedDataSource
        'loads the grid whenever it needs data (sorting, rebinding, etc...)
        Using db As New PromptDataHelper
            
            Dim tbl As DataTable
            tbl = db.ExecuteDataTable("SELECT * FROM ProjectApprovalDocuments WHERE ProjectID = " & nProjectID)
            
            
            'Now look for attachments for each Submittal and if present then up the count
            Dim strPhysicalPath As String = ProcLib.GetCurrentAttachmentPath() & "DistrictID_" & HttpContext.Current.Session("DistrictID")
            strPhysicalPath &= "/_apprisedocs/_PADS/"

            Dim strRelativePath As String = ProcLib.GetCurrentRelativeAttachmentPath() & "DistrictID_" & HttpContext.Current.Session("DistrictID")
            strRelativePath &= "/_apprisedocs/_PADS/"

            'Add an attachments column to the result table
            Dim col As New DataColumn
            col.DataType = Type.GetType("System.String")
            col.ColumnName = "Attachments"
            tbl.Columns.Add(col)

            For Each row As DataRow In tbl.rows
                Dim sPath As String = strPhysicalPath & "PADID_" & row("PADID") & "/"
                Dim sRelPath As String = strRelativePath & "PADID_" & row("PADID") & "/"
                Dim folder As New DirectoryInfo(sPath)
                
                row("Attachments") = ""
                If folder.Exists Then  'there could be files so get all and list
 
                    For Each fi As FileInfo In folder.GetFiles()
                        Dim sfilename As String = fi.Name
                        If Len(sfilename) > 20 Then
                            sfilename = Left(sfilename, 15) & "..." & Right(sfilename, 4)
                        End If

                        Dim sfilelink As String = "<a target='_new' href='" & sRelPath & fi.Name & "'>"
                        row("Attachments") = sfilelink & sfilename & "</a>"
                    Next

                End If
            Next

            RadGrid1.DataSource = tbl
        End Using
        
    End Sub
    
    Protected Sub RadGrid1_ItemCreated(ByVal sender As Object, ByVal e As Telerik.Web.UI.GridItemEventArgs) Handles RadGrid1.ItemCreated
        
        'This event allows us to customize the cell contents - fired before databound
        
        If (TypeOf e.Item Is GridDataItem) Then
            Dim item As GridDataItem = CType(e.Item, GridDataItem)
            Dim nPADID As Integer = item.OwnerTableView.DataKeyValues(item.ItemIndex)("PADID")
            Dim sPADDate As String = item.OwnerTableView.DataKeyValues(item.ItemIndex)("PADDate")
            Dim sAttachments As String = ProcLib.CheckNullDBField(item.OwnerTableView.DataKeyValues(item.ItemIndex)("Attachments"))
  
 
            'update the link button to open report window
            
            Dim linkButton As HyperLink
            
            If bReadOnly Then
                item("PADDate").Controls.Clear()
                item("PADDate").Text = sPADDate
            Else
                linkButton = CType(item("PADDate").Controls(0), HyperLink)
                linkButton.Attributes("onclick") = "return EditPAD(" & nPADID & "," & nProjectID & ");"
                linkButton.NavigateUrl = "#"
                linkButton.ToolTip = "Edit this PAD."
            End If
            
               
            'update the link button to open attachments/notes window
            linkButton = CType(item("ShowAttachments").Controls(0), HyperLink)
            linkButton.ToolTip = "Manage Attachments."
            linkButton.NavigateUrl = "#"
            linkButton.ImageUrl = "images/add.png"
            
            linkButton.Attributes("onclick") = "return ManageAttachments('" & nPADID & "','" & nProjectID & "');"
            
            If sAttachments <> "" Then    'add link for each file
                linkButton.ImageUrl = "images/paper_clip_small.gif"
            End If
            
            'update the link button to view history
            Dim linkButton2 As HyperLink = CType(item("WorkflowHistory").Controls(0), HyperLink)
            linkButton2.Attributes("onclick") = "return ShowWorkflowHistory('" & nPADID & "');"
            linkButton2.ToolTip = "View Workflow History."
            linkButton2.ImageUrl = "images/workflow_history.png"
            linkButton2.NavigateUrl = "#"
            
            
        End If
        
        
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
                .Attributes("onclick") = "return EditPAD('0'," & nProjectID & ");"
                .ToolTip = "Add a New PAD."
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
            'With butSub
            '    .Text = "Export To Excel"
            '    .Value = "ExportExcel"
            '    .Attributes("CancelAjax") = "Y"   'NOTE: This is needed to cancel ajax call and do regular postback as grid export to pdf/execl does not work with ajax
            '    .ImageUrl = "images/excel.gif"
            '    .PostBack = True
            'End With
            'butDropDown.Items.Add(butSub)

            'butSub = New RadMenuItem
            With butSub
                .Text = "Export To PDF"
                .Value = "ExportPDF"
                .Attributes("CancelAjax") = "Y"   'NOTE: This is needed to cancel ajax call and do regular postback as grid export to pdf/execl does not work with ajax
                .ImageUrl = "images/prompt_pdf.gif"
                .PostBack = True
            End With
            butDropDown.Items.Add(butSub)
            RadMenu1.Items.Add(butDropDown)
 
            'butDropDown = New RadMenuItem
            'With butDropDown
            '    .Text = "Print"
            '    .ImageUrl = "images/printer.png"
            '    .PostBack = False
            'End With
 
            'butSub = New RadMenuItem
            'With butSub
            '    .Text = "Print PADs Log"
            '    .ImageUrl = "images/printer.png"
            '    .Target = "_new"
            '    .NavigateUrl = "http://216.129.104.66/Q34JF8SFA/Pages/ReportViewer.aspx?%2fPromptReports%2fPAD_log&Proj=" & nProjectID & "&rs:Command=Render&rs:Format=PDF&rs:ClearSession=True"
            '    .PostBack = False
            'End With
            'butDropDown.Items.Add(butSub)
            
            RadMenu1.Items.Add(butDropDown)

            'but = New RadMenuItem
            'but.IsSeparator = True
            'RadMenu1.Items.Add(but)

            ''Add grid configurator       
            'Dim butConfig As New RadMenuItem
            'With butConfig
            '    .Text = "Preferences"
            '    .ImageUrl = "images/gear.png"
            '    .PostBack = False
            'End With
            'RadMenu1.Items.Add(butConfig)

            ''Add sub items
            'Dim butConfigSub As New RadMenuItem
            'With butConfigSub
            '    .Text = "Visible Columns"
            '    .ImageUrl = "images/column_preferences.png"
            '    .PostBack = False
            'End With

            ''Load the avaialble columns as checkbox items
            'For Each col As GridColumn In RadGrid1.Columns
            '    If col.HeaderText <> "" Then
            '        Dim butCol As New RadMenuItem
            '        With butCol
            '            .Text = col.HeaderText
            '            .Value = "ColumnVisibility"
            '            If col.Visible = True Then
            '                .ImageUrl = "images/check2.png"
            '                .Attributes("Visibility") = "On"
            '            Else
            '                .ImageUrl = ""
            '                .Attributes("Visibility") = "Off"
            '            End If

            '            .Attributes("ID") = col.UniqueName
            '        End With
            '        butConfigSub.Items.Add(butCol)
            '    End If

            'Next
            'butConfig.Items.Add(butConfigSub)

            ''Add sub items
            'butConfigSub = New RadMenuItem
            'With butConfigSub
            '    .Text = "Restore Default Settings"
            '    .Value = "RestoreDefaultSettings"
            '    .ImageUrl = "images/gear_refresh.png"
            'End With
            'butConfig.Items.Add(butConfigSub)
        End If

    End Sub
    Protected Sub RadMenu1_ItemClick(ByVal sender As Object, ByVal e As Telerik.Web.UI.RadMenuEventArgs)
       
        Dim btn As RadMenuItem = e.Item
        
        Select Case btn.Value
            
            'Case "ExportExcel"
            '    RadGrid1.Columns.FindByUniqueName("Attachments").Visible = False
            '    RadGrid1.MasterTableView.ExportToExcel()
                
            Case "ExportPDF"
                RadGrid1.Columns.FindByUniqueName("ShowAttachments").Visible = False
                For Each item As GridItem In RadGrid1.MasterTableView.Items
                    If TypeOf item Is GridDataItem Then
                        Dim dataItem As GridDataItem = CType(item, GridDataItem)
                        Dim lnk As HyperLink = CType(dataItem("PADDate").Controls(0), HyperLink)
                        lnk.NavigateUrl = ""
                    End If
                Next
                RadGrid1.MasterTableView.ExportToPdf()
            
                   
                'Case "ColumnVisibility"
                '    If btn.Attributes("Visibility") = "Off" Then
                '        btn.ImageUrl = "images/check2.png"
                '        btn.Attributes("Visibility") = "On"
                '        RadGrid1.Columns.FindByUniqueName(btn.Attributes("ID")).Visible = True
                '    Else
                '        btn.ImageUrl = ""
                '        btn.Attributes("Visibility") = "Off"
                '        RadGrid1.Columns.FindByUniqueName(btn.Attributes("ID")).Visible = False
                '    End If
                '    Using db As New promptUserPrefs
                '        db.SaveGridColumnVisibility("PADGridColumns", btn.Attributes("ID"), btn.Attributes("Visibility"), "ProjectID", nProjectID)
                '    End Using
                '    RadGrid1.Rebind()
                
                'Case "RestoreDefaultSettings"

                '    Using db As New promptUserPrefs
                '        db.RemoveUserSavedSettings("PADGridSettings", "ProjectID", nProjectID)
                '        db.RemoveUserSavedSettings("PADGridColumns", "ProjectID", nProjectID)
                '    End Using
                '    Response.Redirect(Page.Request.RawUrl)

        End Select
    End Sub
    
    
    
    
</script>

<asp:Content ID="Content1" ContentPlaceHolderID="mainBody" runat="Server">
    <telerik:RadWindowManager ID="contentPopup" runat="server" />
    <telerik:RadMenu ID="RadMenu1" runat="server" OnItemClick="RadMenu1_ItemClick" Style="z-index: 10;" />
    <div id="contentwrapper">
        <telerik:RadGrid ID="RadGrid1" runat="server" AllowSorting="True" AutoGenerateColumns="False"
            GridLines="None" Width="100%" EnableAJAX="True" Skin="prompt">
            <ClientSettings>
                <Selecting AllowRowSelect="False" />
                <Scrolling AllowScroll="True" UseStaticHeaders="True" ScrollHeight="50%" />
            </ClientSettings>
            <MasterTableView Width="99%" GridLines="None" DataKeyNames="PADID,PADDate,Attachments"
                NoMasterRecordsText="No PADs found.">
                <Columns>
                
             <telerik:GridHyperLinkColumn HeaderText="Att" UniqueName="ShowAttachments">
                    <ItemStyle Width="35px" HorizontalAlign="Center" VerticalAlign="Top" />
                    <HeaderStyle Width="35px" HorizontalAlign="Center" />
                </telerik:GridHyperLinkColumn>
                <telerik:GridHyperLinkColumn HeaderText="Hist" UniqueName="WorkflowHistory">
                    <ItemStyle Width="35px" HorizontalAlign="Center" VerticalAlign="Top" />
                    <HeaderStyle Width="35px" HorizontalAlign="Center" />
                </telerik:GridHyperLinkColumn>

                    <telerik:GridHyperLinkColumn DataTextField="PADDate" HeaderText="Date" UniqueName="PADDate"
                        DataTextFormatString="{0:MM/dd/yyyy}" SortExpression="PADDate">
                        <ItemStyle Width="75px" HorizontalAlign="Left" VerticalAlign="Top" />
                        <HeaderStyle Width="75px" Height="20px" HorizontalAlign="Left" />
                    </telerik:GridHyperLinkColumn>
                    
                                       <telerik:GridBoundColumn UniqueName="Description" HeaderText="Description" DataField="Description">
                        <ItemStyle  HorizontalAlign="Left" VerticalAlign="Top" />
                        <HeaderStyle  HorizontalAlign="Left" />
                    </telerik:GridBoundColumn>
 
                    <telerik:GridBoundColumn UniqueName="CurrentPhase" HeaderText="CurrentPhase" DataField="CurrentPhase">
                        <ItemStyle HorizontalAlign="Left" Width="125px" VerticalAlign="Top" />
                        <HeaderStyle HorizontalAlign="Left" Width="125px" />
                    </telerik:GridBoundColumn>
                                        <telerik:GridBoundColumn UniqueName="Status" HeaderText="Status" DataField="Status">
                        <ItemStyle HorizontalAlign="Left" Width="125px" VerticalAlign="Top" />
                        <HeaderStyle HorizontalAlign="Left" Width="125px" />
                    </telerik:GridBoundColumn>
                    
                                      <telerik:GridBoundColumn UniqueName="CurrentWorkflowOwner" HeaderText="Workflow Location" DataField="CurrentWorkflowOwner">
                        <ItemStyle HorizontalAlign="Left" Width="175px" VerticalAlign="Top" />
                        <HeaderStyle HorizontalAlign="Left" Width="175px" />
                    </telerik:GridBoundColumn>
 
    
  
                </Columns>
            </MasterTableView>
        </telerik:RadGrid>
        <telerik:RadAjaxManager ID="RadAjaxManager1" runat="server">
            <ClientEvents OnRequestStart="ajaxRequestStart" OnResponseEnd="ajaxRequestEnd" />
            <AjaxSettings>
                <telerik:AjaxSetting AjaxControlID="RadGrid1">
                    <UpdatedControls>
                        <telerik:AjaxUpdatedControl ControlID="RadGrid1" LoadingPanelID="RadAjaxLoadingPanel1" />
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

            function ManageAttachments(id, projectid)     //for attachments info display
            {

                var oWnd = window.radopen("apprisepm_attachments_manage.aspx?ParentType=PAD&ParentID=" + id + "&ProjectID=" + projectid, "AttachmentsWindow");
                return false;
            }

            function EditPAD(id, projectid) {
                var oWnd = window.radopen("PADS_edit.aspx?PADID=" + id + "&ProjectID=" + projectid, "EditWindow");
                return false;
            }

            function ShowWorkflowHistory(id)     //for workflow history display
            {
                var oWnd = window.radopen('workflow_history_view.aspx?rectype=PAD&recid=' + id, 'WorkflowHistory');
                return false;


            }


  
        </script>

    </telerik:RadScriptBlock>


</asp:Content>
