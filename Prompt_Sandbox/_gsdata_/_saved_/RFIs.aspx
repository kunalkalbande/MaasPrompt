<%@ Page Language="VB" MasterPageFile="~/content.master" Title="" %>

<%@ Register Assembly="Telerik.Web.UI" Namespace="Telerik.Web.UI" TagPrefix="telerik" %>
<%@ Import Namespace="Prompt" %>

<script runat="server">
    
    Private bReadOnly As Boolean = True
    Private nProjectID As Integer = 0
    Private bHideAnswered As Boolean = False
    
    Protected Sub Page_PreRender(ByVal sender As Object, ByVal e As System.EventArgs)
        Using db As New promptUserPrefs
            db.SaveGridSettings(RadGrid1, "RFIGridSettings", "ProjectID", nProjectID)
        End Using
 
    End Sub

    Protected Sub Page_Init(ByVal sender As Object, ByVal e As System.EventArgs)
        nProjectID = Request.QueryString("ProjectID")
        'set security
        Using dbsec As New EISSecurity
            dbsec.ProjectID = nProjectID
            If dbsec.FindUserPermission("RFILog", "write") Then
                bReadOnly = False
            Else
                bReadOnly = True
            End If
        End Using
        If Not IsPostBack Then
            Using db As New promptUserPrefs
                db.LoadGridSettings(RadGrid1, "RFIGridSettings", "ProjectID", nProjectID)
                db.LoadGridColumnVisibility(RadGrid1, "RFIGridColumns", "ProjectID", nProjectID)
            End Using
        End If

    End Sub
    
    Private Sub Page_Load(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MyBase.Load

        ProcLib.CheckSession(Page)
        ProcLib.LoadPopupJscript(Page)

        ''set up help button
        Session("PageID") = "RFIs"
        nProjectID = Request.QueryString("ProjectID")
        
         
        Dim masterTabs As RadTabStrip = Master.FindControl("tabMain")
        Dim masterViewTitle As Label = Master.FindControl("lblViewTitle")
        
        Session("CurrentTab") = "RFIs"
        For Each radTab In masterTabs.GetAllTabs
            If radTab.Value = "RFIs" Then
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

            .ExportSettings.FileName = "PromptRFIExport"
            .ExportSettings.OpenInNewWindow = True
            .ExportSettings.Pdf.PageTitle = masterViewTitle.Text & " RFIs"
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
                .Height = 600
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
                .Attributes("onclick") = "return EditRFI('0'," & nProjectID & ");"
                .ToolTip = "Add a New RFI."
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
 
            butSub = New RadMenuItem
            With butSub
                .Text = "Print RFI Log"
                .ImageUrl = "images/printer.png"
                .Target = "_new"
                .NavigateUrl = "http://216.129.104.66/Q34JF8SFA/Pages/ReportViewer.aspx?%2fPromptReports%2fRFI_log&Dist=56&Proj=" & nProjectID
                .PostBack = False
            End With
            butDropDown.Items.Add(butSub)
            
            RadMenu1.Items.Add(butDropDown)
            
            
            but = New RadMenuItem
            but.IsSeparator = True
            RadMenu1.Items.Add(but)
            
            but = New RadMenuItem
            With but
                .Text = "Hide Answered"
                .Value = "HideAnswered"
                .ImageUrl = "images/funnel.png"
                .Attributes("Filter") = "Off"
            End With
            RadMenu1.Items.Add(but)
 
               
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
        
        Using db As New RFI
            RadGrid1.DataSource = db.GetAllProjectRFIs(nProjectID, bHideAnswered)
        End Using
        
    End Sub
    
    Protected Sub RadGrid1_ItemCreated(ByVal sender As Object, ByVal e As Telerik.Web.UI.GridItemEventArgs) Handles RadGrid1.ItemCreated
        
        'This event allows us to customize the cell contents - fired before databound
        
        If (TypeOf e.Item Is GridDataItem) Then
            Dim item As GridDataItem = CType(e.Item, GridDataItem)
            Dim nRFIID As Integer = item.OwnerTableView.DataKeyValues(item.ItemIndex)("RFIID")
            Dim sRFIRef As String = item.OwnerTableView.DataKeyValues(item.ItemIndex)("RefNumber")
            Dim sQuestionAttachments As String = ProcLib.CheckNullDBField(item.OwnerTableView.DataKeyValues(item.ItemIndex)("QuestionAttachments"))
            Dim sAnswerAttachments As String = ProcLib.CheckNullDBField(item.OwnerTableView.DataKeyValues(item.ItemIndex)("AnswerAttachments"))
            
            Dim linkButton As HyperLink

            If bReadOnly Then
                item("RefNumber").Controls.Clear()
                item("RefNumber").Text = nRFIID
            Else
                linkButton = CType(item("RefNumber").Controls(0), HyperLink)
                linkButton.Attributes("onclick") = "return EditRFI(" & nRFIID & "," & nProjectID & ");"
                linkButton.NavigateUrl = "#"
                linkButton.ToolTip = "Edit this RFI."
            End If
            
            
            'update the link button to open attachments/notes window
            linkButton = CType(item("QuestionAttachments").Controls(0), HyperLink)
            linkButton.ToolTip = "Upload Question Attachments."
            linkButton.NavigateUrl = "#"
            linkButton.ImageUrl = "images/add.png"
            
            linkButton.Attributes("onclick") = "return ManageQuestionAttachments('" & nRFIID & "','" & nProjectID & "');"
            
            If sQuestionAttachments = "Y" Then    'add link for each file
                linkButton.ImageUrl = "images/paper_clip_small.gif"
            End If
            
            
            'update the link button to open attachments/notes window
            linkButton = CType(item("AnswerAttachments").Controls(0), HyperLink)
            linkButton.ToolTip = "Upload Answer Attachments."
            linkButton.NavigateUrl = "#"
            linkButton.ImageUrl = "images/add.png"
            
            linkButton.Attributes("onclick") = "return ManageAnswerAttachments('" & nRFIID & "','" & nProjectID & "');"
            
            If sAnswerAttachments = "Y" Then    'add link for each file
                linkButton.ImageUrl = "images/paper_clip_small.gif"
            End If

        End If
        
        
    End Sub
    
    Private Sub RadGrid1_ItemDataBound(ByVal sender As Object, ByVal e As Telerik.Web.UI.GridItemEventArgs) Handles RadGrid1.ItemDataBound
        If (TypeOf e.Item Is GridDataItem) Then
            Dim dataItem As GridDataItem = CType(e.Item, GridDataItem)
            Dim dRequiredBy As String = ProcLib.CheckNullDBField(dataItem.OwnerTableView.DataKeyValues(dataItem.ItemIndex)("RequiredBy"))
            Dim dReturnedOn As String = ProcLib.CheckNullDBField(dataItem.OwnerTableView.DataKeyValues(dataItem.ItemIndex)("ReturnedOn"))
            Dim sStatus As String = ProcLib.CheckNullDBField(dataItem.OwnerTableView.DataKeyValues(dataItem.ItemIndex)("Status"))

            'Clear the css for the item
            'dataItem.CssClass = ""
            
            If sStatus = "Pending" Then
                dataItem.CssClass = "rfi_pending"
                If IsDate(dRequiredBy) Then
                    Dim dDate As Date = dRequiredBy
                    If dDate = DateAdd(DateInterval.Day, 1, Now()) Then
                        dataItem.ForeColor = Color.Yellow
                    ElseIf dDate < Now() Then
                        dataItem.CssClass = "rfi_overdue"

                        
                    End If

                End If
            End If
            If sStatus = "Answered" Then
                dataItem.Font.Bold = False
            End If
            
            dataItem("Answer").ToolTip = dataItem("Answer").Text
            dataItem("Question").ToolTip = dataItem("Question").Text
            
            If Len(dataItem("Answer").Text) > 55 Then
                dataItem("Answer").Text = Left(dataItem("Answer").Text, 55) & "..."
            End If
            
            If Len(dataItem("Question").Text) > 55 Then
                dataItem("Question").Text = Left(dataItem("Question").Text, 55) & "..."
            End If
            
            
        End If
        
    End Sub
 
  
    Protected Sub RadMenu1_ItemClick(ByVal sender As Object, ByVal e As Telerik.Web.UI.RadMenuEventArgs)
       
        Dim btn As RadMenuItem = e.Item
        
        Select Case btn.Value
            
            Case "ExportExcel"
                RadGrid1.Columns.FindByUniqueName("QuestionAttachments").Visible = False
                RadGrid1.Columns.FindByUniqueName("AnswerAttachments").Visible = False
                RadGrid1.MasterTableView.ExportToExcel()
                
            Case "ExportPDF"
                RadGrid1.Columns.FindByUniqueName("QuestionAttachments").Visible = False
                RadGrid1.Columns.FindByUniqueName("AnswerAttachments").Visible = False
                For Each item As GridItem In RadGrid1.MasterTableView.Items
                    If TypeOf item Is GridDataItem Then
                        Dim dataItem As GridDataItem = CType(item, GridDataItem)
                        Dim lnk As HyperLink = CType(dataItem("RefNumber").Controls(0), HyperLink)
                        lnk.NavigateUrl = ""
                    End If
                Next
                RadGrid1.MasterTableView.ExportToPdf()
            
            Case "HideAnswered"
                If btn.Attributes("Filter") = "Off" Then
                    btn.Attributes("Filter") = "On"
                    bHideAnswered = True
                    btn.ImageUrl = "images/funnel_down.png"
                Else
                    btn.Attributes("Filter") = "Off"
                    bHideAnswered = False
                    btn.ImageUrl = "images/funnel.png"
                End If
                RadGrid1.Rebind()
                
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
                    db.SaveGridColumnVisibility("RFIGridColumns", btn.Attributes("ID"), btn.Attributes("Visibility"), "ProjectID", nProjectID)
                End Using
                RadGrid1.Rebind()
                
            Case "RestoreDefaultSettings"
                
                Using db As New promptUserPrefs
                    db.RemoveUserSavedSettings("RFIGridSettings", "ProjectID", nProjectID)
                    db.RemoveUserSavedSettings("RFIGridColumns", "ProjectID", nProjectID)
                End Using
                Response.Redirect(Page.Request.RawUrl)

        End Select
    End Sub

 
</script>

<asp:Content ID="Content1" ContentPlaceHolderID="mainBody" runat="Server">
    <telerik:RadWindowManager ID="contentPopup" runat="server" />
    <telerik:RadMenu ID="RadMenu1" runat="server" OnItemClick="RadMenu1_ItemClick" Style="z-index: 10;" />
    <telerik:RadGrid ID="RadGrid1" runat="server" AllowSorting="true" AutoGenerateColumns="False"
        GridLines="None" Width="99%" EnableEmbeddedSkins="false" enableajax="True" Skin="Prompt">
        <ClientSettings>
            <Selecting AllowRowSelect="False" />
            <Scrolling AllowScroll="True" UseStaticHeaders="True" ScrollHeight="50%" />
        </ClientSettings>
        <MasterTableView Width="99%" GridLines="None" DataKeyNames="RFIID,RefNumber,QuestionAttachments,AnswerAttachments,ReceivedOn,RequiredBy,Status"
            NoMasterRecordsText="No RFIs found.">
            <Columns>
                <telerik:GridHyperLinkColumn UniqueName="RefNumber" HeaderText="No." DataTextField="RefNumber"
                    SortExpression="RefNumber">
                    <ItemStyle HorizontalAlign="Left" Width="55px" VerticalAlign="Top" />
                    <HeaderStyle HorizontalAlign="Left" Width="55px" />
                </telerik:GridHyperLinkColumn>
                <telerik:GridBoundColumn UniqueName="Title" HeaderText="Title" DataField="Title">
                    <ItemStyle HorizontalAlign="Left" Width="55px" VerticalAlign="Top" />
                    <HeaderStyle HorizontalAlign="Left" Width="55px" />
                </telerik:GridBoundColumn>
                <telerik:GridBoundColumn UniqueName="Status" HeaderText="Status" DataField="Status">
                    <ItemStyle HorizontalAlign="Left" Width="45px" VerticalAlign="Top" />
                    <HeaderStyle HorizontalAlign="Left" Width="45px" />
                </telerik:GridBoundColumn>
                <telerik:GridBoundColumn DataField="ReceivedOn" HeaderText="Received On" UniqueName="ReceivedOn"
                    DataFormatString="{0:MM/dd/yy}">
                    <ItemStyle Width="55px" HorizontalAlign="Center" VerticalAlign="Top" />
                    <HeaderStyle Width="55px" HorizontalAlign="Center" />
                </telerik:GridBoundColumn>
                <telerik:GridBoundColumn UniqueName="Trade" HeaderText="Trade" DataField="Trade">
                    <ItemStyle HorizontalAlign="Left" Width="55px" VerticalAlign="Top" />
                    <HeaderStyle HorizontalAlign="Left" Width="55px" />
                </telerik:GridBoundColumn>
                <telerik:GridHyperLinkColumn HeaderText="" UniqueName="QuestionAttachments">
                    <ItemStyle Width="20px" HorizontalAlign="Center" VerticalAlign="Top" />
                    <HeaderStyle Width="20px" HorizontalAlign="Center" />
                </telerik:GridHyperLinkColumn>
                <telerik:GridBoundColumn UniqueName="Question" HeaderText="Question" DataField="Question">
                    <ItemStyle HorizontalAlign="Left" Width="15%" VerticalAlign="Top" Wrap="true" />
                    <HeaderStyle HorizontalAlign="Left" Width="15%" />
                </telerik:GridBoundColumn>
                <telerik:GridHyperLinkColumn HeaderText="" UniqueName="AnswerAttachments">
                    <ItemStyle Width="20px" HorizontalAlign="Center" VerticalAlign="Top" />
                    <HeaderStyle Width="20px" HorizontalAlign="Center" />
                </telerik:GridHyperLinkColumn>
                <telerik:GridBoundColumn UniqueName="Answer" HeaderText="Answer" DataField="Answer">
                    <ItemStyle HorizontalAlign="Left" Width="15%" VerticalAlign="Top" Wrap="true" />
                    <HeaderStyle HorizontalAlign="Left" Width="15%" />
                </telerik:GridBoundColumn>
                <telerik:GridBoundColumn UniqueName="SubmittedTo" HeaderText="Submitted To" DataField="SubmittedTo">
                    <ItemStyle HorizontalAlign="Left" Width="50px" VerticalAlign="Top" />
                    <HeaderStyle HorizontalAlign="Left" Width="50px" />
                </telerik:GridBoundColumn>
                <telerik:GridBoundColumn UniqueName="TransmittedBy" HeaderText="Transmitted By" DataField="TransmittedBy">
                    <ItemStyle HorizontalAlign="Left" Width="50px" VerticalAlign="Top" />
                    <HeaderStyle HorizontalAlign="Left" Width="50px" />
                </telerik:GridBoundColumn>
                <telerik:GridBoundColumn DataField="RequiredBy" HeaderText="Date Required" UniqueName="RequiredBy"
                    DataFormatString="{0:MM/dd/yy}">
                    <ItemStyle Width="50px" HorizontalAlign="Center" VerticalAlign="Top" />
                    <HeaderStyle Width="50px" Height="20px" HorizontalAlign="Center" />
                </telerik:GridBoundColumn>
                <telerik:GridBoundColumn DataField="ReturnedOn" HeaderText="Date Returned" UniqueName="ReturnedOn"
                    DataFormatString="{0:MM/dd/yy}">
                    <ItemStyle Width="50px" HorizontalAlign="Center" VerticalAlign="Top" />
                    <HeaderStyle Width="50px" Height="20px" HorizontalAlign="Center" />
                </telerik:GridBoundColumn>
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
    <telerik:RadToolTipManager ID="RadToolTipManager1" runat="server" Sticky="True" Title=""
        Position="BottomCenter" Skin="Office2007" HideDelay="500" ManualClose="False"
        ShowEvent="OnMouseOver" ShowDelay="100" Animation="Fade" AutoCloseDelay="6000"
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

            function ManageQuestionAttachments(id, projectid)     //for attachments info display
            {

                var oWnd = window.radopen("apprisepm_attachments_manage.aspx?ParentType=RFIQuestion&ParentID=" + id + "&ProjectID=" + projectid, "AttachmentsWindow");
                return false;
            }

            function ManageAnswerAttachments(id, projectid)     //for attachments info display
            {

                var oWnd = window.radopen("apprisepm_attachments_manage.aspx?ParentType=RFIAnswer&ParentID=" + id + "&ProjectID=" + projectid, "AttachmentsWindow");
                return false;
            }

            function EditRFI(id, projectid) {

                var oWnd = window.radopen("RFI_edit.aspx?RFIID=" + id + "&ProjectID=" + projectid, "EditWindow");
                return false;
            }


//            function GetRadWindow() {
//                var oWindow = null;
//                if (window.RadWindow) oWindow = window.RadWindow;
//                else if (window.frameElement.radWindow) oWindow = window.frameElement.radWindow;
//                return oWindow;
//            }

        </script>

    </telerik:RadScriptBlock>
</asp:Content>
