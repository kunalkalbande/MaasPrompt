<%@ Page Language="VB" MasterPageFile="~/content.master" Title="" %>

<%@ Register Assembly="Telerik.Web.UI" Namespace="Telerik.Web.UI" TagPrefix="telerik" %>
<%@ Import Namespace="Prompt" %>

<script runat="server">
    
    Private bReadOnly As Boolean = True
    Private nProjectID As Integer = 0
    Private parentID As Integer
    Private bHideAnswered As Boolean = False
    Private nContractID As Integer = 0
    
    Protected Sub Page_PreRender(ByVal sender As Object, ByVal e As System.EventArgs)
        Using db As New promptUserPrefs
            db.SaveGridSettings(RadGrid1, "SubmittalGridSettings", "ProjectID", nProjectID)
        End Using
 
    End Sub

    Protected Sub Page_Init(ByVal sender As Object, ByVal e As System.EventArgs)
        nProjectID = Request.QueryString("ProjectID")
        'set security
        Using dbsec As New EISSecurity
            dbsec.ProjectID = nProjectID
            If dbsec.FindUserPermission("SubmittalLog", "write") Then
                bReadOnly = False
            Else
                bReadOnly = True
            End If
        End Using
        If Not IsPostBack Then
            Using db As New promptUserPrefs
                db.LoadGridSettings(RadGrid1, "SubmittalGridSettings", "ProjectID", nProjectID)
                db.LoadGridColumnVisibility(RadGrid1, "SubmittalGridColumns", "ProjectID", nProjectID)
            End Using
        End If

    End Sub
    
    Private Sub Page_Load(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MyBase.Load

        ProcLib.CheckSession(Page)
        ProcLib.LoadPopupJscript(Page)

        ''set up help button
        Session("PageID") = "Submittals"
        nProjectID = Request.QueryString("ProjectID")
        
        'If Request.Browser.Browser = "IE" Then
        RadGrid1.Height = Unit.Pixel(600)
        'Else
        '.Height = Unit.Percentage(88)
        'End If
        
        Dim masterTabs As RadTabStrip = Master.FindControl("tabMain")
        Session("CurrentTab") = "Submittals"
        For Each radTab In masterTabs.GetAllTabs
            If radTab.Value = "Submittals" Then
                radTab.Selected = True
                radTab.SelectParents()
                Exit For
            End If
        Next
        
       
        
        If Session("RtnFromEdit") <> True Then
            Session("ContractID") = Nothing
        ElseIf Session("RtnFromEdit") = True Then
            nContractID = Session("ContractID")
            Session("RtnFromEdit") = Nothing
        End If
       
        
        'get current user information which is used in the popup edit window.
        Try
            Using db As New RFI
                Session("ContactID") = db.getContactID(Session("UserID"), Session("DistrictID"))
                Dim contactData As Object = db.getContactData(Session("ContactID"), Session("DistrictID"))
                parentID = contactData(0)
                Session("ParentContactID") = parentID
                Dim contactType As String = contactData(1)
                Session("ContactType") = contactType.Trim()

                'errorMsg.Text = Session("ContactID") & " - Here!"
            End Using
            
        Catch ex As Exception

        End Try
        
       
        
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
            
            .ExportSettings.FileName = "PromptSubmittalsExport"
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
                .Width = 900
                .Height = 540
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
 
        BuildMenu()
          
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
                .Text = "Add New Submittal"
                .ImageUrl = "images/add.png"
                .Attributes("onclick") = "return EditSubmittal('0'," & nProjectID & ",'New');"
                .ToolTip = "Add a New Submittal."
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
 
            but = New RadMenuItem
            With but
                .Text = "Hide Closed"
                .Value = "HideAnswered"
                .ImageUrl = "images/funnel.png"
                .Attributes("Filter") = "Off"
                .Visible = True
            End With
            RadMenu1.Items.Add(but)
            
            'butSub = New RadMenuItem
            'With butSub
            '    .Text = "Print Submittals Log"
            '    .ImageUrl = "images/printer.png"
            '    .Target = "_new"
            '    .NavigateUrl = "http://216.129.104.66/Q34JF8SFA/Pages/ReportViewer.aspx?%2fPromptReports%2fSubmittal_log&Proj=" & nProjectID & "&rs:Command=Render&rs:Format=PDF&rs:ClearSession=True"
            '    .PostBack = False
            'End With
            'butDropDown.Items.Add(butSub)
            
            RadMenu1.Items.Add(butDropDown)

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
                        Dim lnk As HyperLink = CType(dataItem("SubmittalID").Controls(0), HyperLink)
                        lnk.NavigateUrl = ""
                    End If
                Next
                RadGrid1.MasterTableView.ExportToPdf()
                
            Case "HideAnswered"
                If btn.Attributes("Filter") = "Off" Then
                    btn.Attributes("Filter") = "On"
                    bHideAnswered = True
                    Session("HideClosed") = "Closed"
                    btn.ImageUrl = "images/funnel_down.png"
                Else
                    btn.Attributes("Filter") = "Off"
                    bHideAnswered = False
                    Session("HideClosed") = ""
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
                    db.SaveGridColumnVisibility("SubmittalGridColumns", btn.Attributes("ID"), btn.Attributes("Visibility"), "ProjectID", nProjectID)
                End Using
                RadGrid1.Rebind()
                
            Case "RestoreDefaultSettings"
                
                Using db As New promptUserPrefs
                    db.RemoveUserSavedSettings("SubmittalGridSettings", "ProjectID", nProjectID)
                    db.RemoveUserSavedSettings("SubmittalGridColumns", "ProjectID", nProjectID)
                End Using
                Response.Redirect(Page.Request.RawUrl)

        End Select
    End Sub
    
    Protected Sub RadGrid1_NeedDataSource(ByVal source As Object, ByVal e As Telerik.Web.UI.GridNeedDataSourceEventArgs) Handles RadGrid1.NeedDataSource
        'loads the grid whenever it needs data (sorting, rebinding, etc...)
        
        Using db As New RFI
            Try
                RadGrid1.DataSource = db.getAllProjectContracts(nProjectID, False, Session("ContactType"), "Submittals")
            Catch ex As Exception
                'errorMsg.Text = ex.ToString()
            End Try
        
        End Using
        
    End Sub   
    
    Protected Sub RadGrid1_DetailTableDataBind(ByVal source As Object, ByVal e As GridDetailTableDataBindEventArgs) Handles RadGrid1.DetailTableDataBind
        Dim parentItem As GridDataItem = CType(e.DetailTableView.ParentItem, GridDataItem)
        Dim contID As Integer = parentItem("ContractID").Text
                                           
        Using db As New Submittal
            e.DetailTableView.DataSource = db.getAllContractSubmittals(contID, Session("ContactID"), Session("ContactType"), Session("HideClosed"))
        End Using
        
    End Sub
    
    Protected Sub RadGrid1_ItemCreated(ByVal sender As Object, ByVal e As Telerik.Web.UI.GridItemEventArgs) Handles RadGrid1.ItemCreated       
        'This event allows us to customize the cell contents - fired before databound     
       
        If nContractID <> 0 Then
            For Each dataitem As GridDataItem In RadGrid1.MasterTableView.Items
                If dataitem("ContractID").Text = nContractID Then
                    dataitem.Expanded = True
                End If
            Next
        End If
        
        If (TypeOf e.Item Is GridDataItem) Then
            Dim item As GridDataItem = CType(e.Item, GridDataItem)
            Dim nSubmittalID As Integer = item.OwnerTableView.DataKeyValues(item.ItemIndex)("SubmittalID")
            Dim sAttachments As String = ProcLib.CheckNullDBField(item.OwnerTableView.DataKeyValues(item.ItemIndex)("Attachments"))
            Dim sDateSent As String = ProcLib.CheckNullDBField(item.OwnerTableView.DataKeyValues(item.ItemIndex)("DateSent"))
            Dim sSubmittalNo As String = item.OwnerTableView.DataKeyValues(item.ItemIndex)("SubmittalNo")
            'update the link button to open report window
            
            Dim linkButton As HyperLink
            
            If bReadOnly Then
                item("Description").Controls.Clear()
                item("Description").Text = nSubmittalID
            Else
                Try
                    linkButton = CType(item("SubmittalNo").Controls(0), HyperLink)
                    linkButton.Attributes("onclick") = "return EditSubmittal(" & nSubmittalID & "," & nProjectID & ",'Edit');"
                    linkButton.NavigateUrl = "#"
                    linkButton.ToolTip = "Edit this Submittal."
                Catch ex As Exception
                End Try           
            End If
            
        End If
        
        
    End Sub
    
    Private Sub RadGrid1_ItemDataBound(ByVal sender As Object, ByVal e As Telerik.Web.UI.GridItemEventArgs) Handles RadGrid1.ItemDataBound
        If (TypeOf e.Item Is GridDataItem) Then
            Dim dataItem As GridDataItem = CType(e.Item, GridDataItem)
            Dim dRequiredBy As String = ProcLib.CheckNullDBField(dataItem.OwnerTableView.DataKeyValues(dataItem.ItemIndex)("DateRequired"))
            Dim sStatus As String = ProcLib.CheckNullDBField(dataItem.OwnerTableView.DataKeyValues(dataItem.ItemIndex)("Status"))
            Dim dDate As Date
            
            dataItem.CssClass = "rfi_unassigned" 'Style for all lines
            
            If sStatus = "Active" Then
                dataItem.Item("DateRequired").CssClass = "rfi_pending"
            ElseIf sStatus = "Closed" Then
                
            End If
            
            If dRequiredBy <> "" Then
                dDate = DateTime.Parse(dRequiredBy)
            End If
                               
            If IsDate(dDate) Then
                If dDate = DateAdd(DateInterval.Day, 1, Date.Today) Or dDate = DateAdd(DateInterval.Day, 2, Date.Today) Then
                    dataItem.Item("DateRequired").CssClass = "rfi_warning"
                ElseIf CDate(dDate) < CDate(Now()) Then
                    Try
                        dataItem.Item("DateRequired").CssClass = "rfi_overdue"
                    Catch ex As Exception
                    End Try
                  
                End If
            End If
            If sStatus = "Closed" Then
                dataItem.Item("DateRequired").CssClass = "rfi_answered"
            ElseIf sStatus = "Preparing" Then
                dataItem.Item("DateRequired").CssClass = "rfi_preparing"
            End If
        
        End If
        
        
    End Sub
    
</script>

<asp:Content ID="Content1" ContentPlaceHolderID="mainBody" runat="Server">
    <telerik:RadWindowManager ID="contentPopup" runat="server" />
    <telerik:RadMenu ID="RadMenu1" runat="server" OnItemClick="RadMenu1_ItemClick" Style="z-index: 10;" />

     <div style="height:16px;border-style:solid;border-width:0px;width:1050px;position:relative;top:0px;">
            <div style="position:relative;width:100px;display:inline-block;height:16px;
                line-height:16px;vertical-align:top;text-align:right;font-size:10px;font-weight:bold">Status Indicator:&nbsp;&nbsp;</div>
            <div class="rfi_preparing" style="width:150px;height:16px;position:relative;display:inline-block;text-align:center;font-size:10px">Preparing</div>
            <div style="position:absolute;display:inline-block;width:5px"></div>
            <div class="rfi_unassigned" style="width:150px;height:16px;position:relative;display:inline-block;text-align:center;font-size:10px">Unassigned to DP</div>
            <div style="position:absolute;display:inline-block;width:5px"></div>
            <div class="rfi_pending" style="width:150px;height:16px;position:relative;display:inline-block;text-align:center;font-size:10px">Active</div>
            <div style="position:absolute;display:inline-block;width:5px"></div>

            <div class="rfi_warning" style="width:150px;height:16px;position:relative;display:inline-block;text-align:center;font-size:10px">Near Overdue</div>
            <div style="position:absolute;display:inline-block;width:5px"></div>

            <div class="rfi_overdue" style="width:150px;height:16px;position:relative;display:inline-block;text-align:center;font-size:10px">Overdue</div>
            <div style="position:absolute;display:inline-block;width:5px"></div>
            <div class="rfi_answered" style="width:150px;height:16px;position:relative;display:inline-block;text-align:center;font-size:10px">Complete/Closed</div>
        </div>   
   
    <div id="contentwrapper" style="top:0px">

     <asp:Label ID="errorMsg" runat="server" Text="No message" style="z-index:100;top:20px;position:relative"></asp:Label>

     <telerik:RadGrid ID="RadGrid1" runat="server" AllowSorting="true" AutoGenerateColumns="False" Style="Top:28px;position:relative"
        GridLines="None" Width="99%" EnableEmbeddedSkins="false" enableajax="True">
        <ClientSettings>
            <Selecting AllowRowSelect="False" />
            <Scrolling AllowScroll="True" UseStaticHeaders="True" ScrollHeight="50%" />
        </ClientSettings>

        <MasterTableView Width="99%" GridLines="None" DataKeyNames="ContractID,BidPackNumber"
            NoMasterRecordsText="No Contracts with Submittal(s) found.">
            <Columns>

                <telerik:GridBoundColumn UniqueName="ContractID" HeaderText="Contract ID" DataField="ContractID">
                    <ItemStyle HorizontalAlign="Left" Width="70px" VerticalAlign="Top" />
                    <HeaderStyle HorizontalAlign="Left" Width="70px" />
                </telerik:GridBoundColumn>

                <telerik:GridBoundColumn UniqueName="BidPackNumber" HeaderText="Bid Pack Number" DataField="BidPackNumber">
                    <ItemStyle HorizontalAlign="Left" Width="120px" VerticalAlign="Top" />
                    <HeaderStyle HorizontalAlign="Left" Width="120px"  />
                </telerik:GridBoundColumn>

                 <telerik:GridBoundColumn UniqueName="Description" HeaderText="Description" DataField="Description">
                    <ItemStyle HorizontalAlign="Left" Width="250px" VerticalAlign="Top" />
                    <HeaderStyle HorizontalAlign="Left" Width="250px"   />
                </telerik:GridBoundColumn>

                <telerik:GridBoundColumn UniqueName="Contractor" HeaderText="Contractor" DataField="Contractor">
                    <ItemStyle HorizontalAlign="Left" Width="200px" VerticalAlign="Top" />
                    <HeaderStyle HorizontalAlign="Left" Width="200px" />
                </telerik:GridBoundColumn>
 
                 <telerik:GridBoundColumn UniqueName="Contact" HeaderText="Contact" DataField="Contact">
                    <ItemStyle HorizontalAlign="Left" Width="150px" VerticalAlign="Top" />
                    <HeaderStyle HorizontalAlign="Left" Width="150px" />
                </telerik:GridBoundColumn>

                 <telerik:GridBoundColumn UniqueName="Phone1" HeaderText="Phone Number" DataField="Phone1">
                    <ItemStyle HorizontalAlign="Left" Width="80px" VerticalAlign="Top" />
                    <HeaderStyle HorizontalAlign="Left" Width="80px"  />
                </telerik:GridBoundColumn>  
                
            </Columns>
            <DetailTables>
              <telerik:GridTableView runat="server" Name="Submittals" DataKeyNames="ContractID, SubmittalNo, SubmittalID, DateRequired, Status"  
                 TableLayout="Auto" >
                <ParentTableRelation>
                  <telerik:GridRelationFields DetailKeyField="ContractID" MasterKeyField="ContractID" />
                </ParentTableRelation>
               <ItemStyle CssClass="InnerItemStyle" />
                <Columns>               
                
                 <telerik:GridHyperLinkColumn UniqueName="SubmittalNo" HeaderText="Submittal Number" DataTextField="SubmittalNo"
                        SortExpression="SubmittalNo">
                        <ItemStyle HorizontalAlign="Left" Width="100px" VerticalAlign="top" CssClass="InnerItemStyle"   />
                        <HeaderStyle HorizontalAlign="Left" Width="100px" />
                </telerik:GridHyperLinkColumn>

                <telerik:GridBoundColumn UniqueName="Revision" HeaderText="Revision" DataField="RevNo">
                    <ItemStyle HorizontalAlign="Left" Width="70px" VerticalAlign="Top" />
                    <HeaderStyle HorizontalAlign="Left" Width="70px" />
                </telerik:GridBoundColumn>       

                <telerik:GridBoundColumn UniqueName="WorkFlowPosition" HeaderText="Workflow Position" DataField="WorkFlowPosition">
                    <ItemStyle HorizontalAlign="Left" Width="150px" VerticalAlign="Top" />
                    <HeaderStyle HorizontalAlign="Left" Width="150px" />
                </telerik:GridBoundColumn>       

                <telerik:GridBoundColumn UniqueName="Status" HeaderText="Status" DataField="Status">
                    <ItemStyle HorizontalAlign="Left" Width="150px" VerticalAlign="Top" />
                    <HeaderStyle HorizontalAlign="Left" Width="150px" />
                </telerik:GridBoundColumn>       

                <telerik:GridBoundColumn UniqueName="CreatedBy" HeaderText="Created By" DataField="Name">
                    <ItemStyle HorizontalAlign="Left" Width="150px" VerticalAlign="Top" />
                    <HeaderStyle HorizontalAlign="Left" Width="150px" />
                </telerik:GridBoundColumn>       

                <telerik:GridBoundColumn UniqueName="CreateDate" HeaderText="Date Created" DataField="CreateDate" DataFormatString="{0:MM/dd/yy}">
                    <ItemStyle HorizontalAlign="Left" Width="80px" VerticalAlign="Top" />
                    <HeaderStyle HorizontalAlign="Left" Width="80px" />
                </telerik:GridBoundColumn>       

                <telerik:GridBoundColumn UniqueName="DateRequired" HeaderText="Date Required" DataField="DateRequired" DataFormatString="{0:MM/dd/yy}">
                    <ItemStyle HorizontalAlign="Left" Width="80px" VerticalAlign="Top" />
                    <HeaderStyle HorizontalAlign="Left" Width="80px" />
                </telerik:GridBoundColumn> 
                
                <telerik:GridBoundColumn UniqueName="Description" HeaderText="Description" DataField="Description">
                    <ItemStyle HorizontalAlign="Left" Width="250px" VerticalAlign="Top" />
                    <HeaderStyle HorizontalAlign="Left" Width="250px" />
                </telerik:GridBoundColumn>                  
                
                
                
                
                      
                </Columns>
              </telerik:GridTableView>
            </DetailTables>

          

        </MasterTableView>
          <ExportSettings OpenInNewWindow="True">
            <Pdf PageWidth="297mm" PageHeight="210mm" />
        </ExportSettings>
  </telerik:RadGrid>




    <!-- ----------------------------------------------------------------------- -->
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

            function ManageAttachments(id, projectid)     //for attachments info display
            {

                var oWnd = window.radopen("apprisepm_attachments_manage.aspx?ParentType=Submittal&ParentID=" + id + "&ProjectID=" + projectid, "AttachmentsWindow");
                return false;
            }

            function EditSubmittal(id, projectid, type) {
                var oWnd = window.radopen("submittal_edit.aspx?SubmittalID=" + id + "&ProjectID=" + projectid + "&type=" + type, "EditWindow");
                return false;
            }


  
        </script>

    </telerik:RadScriptBlock>


</asp:Content>
