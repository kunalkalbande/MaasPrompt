<%@ Page Language="VB" MasterPageFile="~/prompt.master" Title="" %>

<%@ Register Assembly="Telerik.Web.UI" Namespace="Telerik.Web.UI" TagPrefix="telerik" %>
<%@ Import Namespace="Prompt" %>

<script runat="server">

    Private bReadOnly As Boolean = True
    Private bFilterPMs As Boolean = False
    
    Protected Sub Page_PreRender(ByVal sender As Object, ByVal e As System.EventArgs)
        Using db As New promptUserPrefs
            db.SaveGridSettings(RadGrid1, "ContactsGridSettings", "DistrictID", Session("DistrictID"))
        End Using
 
    End Sub

    Protected Sub Page_Init(ByVal sender As Object, ByVal e As System.EventArgs)
        'set security
        Using db As New EISSecurity
            If db.FindUserPermission("ContactList", "write") Then
                bReadOnly = False
            End If
        End Using

        If Not IsPostBack Then
            Using db As New promptUserPrefs
                db.LoadGridSettings(RadGrid1, "ContactsGridSettings", "DistrictID", Session("DistrictID"))
                db.LoadGridColumnVisibility(RadGrid1, "ContactsGridColumns", "DistrictID", Session("DistrictID"))
            End Using
        End If

    End Sub
    
    Private Sub Page_Load(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MyBase.Load

        ProcLib.CheckSession(Page)
        ProcLib.LoadPopupJscript(Page)
        
        Session("PageID") = "ContactsList"
        Page.Title = "Prompt Contacts"
        
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

            .MasterTableView.EnableHeaderContextMenu = True
            .MasterTableView.TableLayout = GridTableLayout.Fixed
            .MasterTableView.AllowMultiColumnSorting = False

            .Height = Unit.Pixel(600)
            .ExportSettings.FileName = "PromptContactsListExport"
            .ExportSettings.OpenInNewWindow = True
            .ExportSettings.Pdf.PageTitle = "PROMPT Contacts List"
        End With
        
        BuildMenu()
        
        With contentPopups
            .VisibleOnPageLoad = False
            .Skin = "Windows7"
                     
            Dim ww As New RadWindow

            ww = New RadWindow
            With ww
                .ID = "EditWindow"
                .NavigateUrl = "#"
                .Title = ""
                .Width = 570
                .Height = 675
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
            
            With RadMenuPage
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
                .Attributes("onclick") = "return EditContact(0);"
                .ToolTip = "Add a New Contact."
                .PostBack = False
                If bReadOnly Then
                    .Visible = False
                Else
                    .Visible = True
                End If
            End With
            RadMenuPage.Items.Add(but)

            Dim butDropDown As New RadMenuItem
            With butDropDown
                .Text = "Export"
                .ImageUrl = "images/data_down.png"
                .PostBack = True
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
            
            'butSub = New RadMenuItem
            'With butSub
            '    .Text = "Export To PDF"
            '    .Value = "ExportPDF"
            '    .Attributes("CancelAjax") = "Y"   'NOTE: This is needed to cancel ajax call and do regular postback as grid export to pdf/execl does not work with ajax
            '    .ImageUrl = "images/prompt_pdf.gif"
            '    .PostBack = True
            'End With
            'butDropDown.Items.Add(butSub)
            
            RadMenuPage.Items.Add(butDropDown)
                
            but = New RadMenuItem
            but.IsSeparator = True
            RadMenuPage.Items.Add(but)
            
            butSub = New RadMenuItem
            With butSub
                .Text = "Show PM's Only"
                .Value = "FilterList"
                .PostBack = True
            End With
            RadMenuPage.Items.Add(butSub)
            
            but = New RadMenuItem
            but.IsSeparator = True
            RadMenuPage.Items.Add(but)
            
            'Add grid configurator       
            Dim butConfig As New RadMenuItem
            With butConfig
                .Text = "Preferences"
                .ImageUrl = "images/gear.png"
                .PostBack = False
            End With
            RadMenuPage.Items.Add(butConfig)
            
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
                    If col.HeaderText <> "First" And col.HeaderText <> "Last" Then
                        butConfigSub.Items.Add(butCol)
                    End If
                    
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
        
        Dim but As RadMenuItem = RadMenuPage.FindItemByValue("FilterList")
        Dim txt As String = but.Text
        If txt = "Show All" Then  'seems counterintuative but text changes to oposite of filter
            bFilterPMs = True
        Else
            bFilterPMs = False
        End If
               
        Using db As New Contact
            RadGrid1.DataSource = db.GetAllContacts(Session("DistrictID"), bFilterPMs)
        End Using

    End Sub
    
    Protected Sub RadGrid1_ItemCreated(ByVal sender As Object, ByVal e As Telerik.Web.UI.GridItemEventArgs) Handles RadGrid1.ItemCreated
        
        'This event allows us to customize the cell contents - fired before databound
        
        If (TypeOf e.Item Is GridDataItem) Then
            Dim item As GridDataItem = CType(e.Item, GridDataItem)
            Dim nID As Integer = item.OwnerTableView.DataKeyValues(item.ItemIndex)("ContactID")
            Dim sEmail As String = ProcLib.CheckNullDBField(item.OwnerTableView.DataKeyValues(item.ItemIndex)("Email"))
            Dim sType As String = ProcLib.CheckNullDBField(item.OwnerTableView.DataKeyValues(item.ItemIndex)("ContactType"))
  
            If bReadOnly = False Then
                Dim linkButton As HyperLink = CType(item("FirstName").Controls(0), HyperLink)
                
                linkButton.NavigateUrl = "#"
                linkButton.Attributes("onclick") = "return EditContact(" & nID & ");"
                linkButton.ToolTip = "Edit selected Contact."
            End If
            
            If sEmail <> "" Then
                Dim linkEmail As HyperLink = CType(item("Email").Controls(0), HyperLink)
                linkEmail.NavigateUrl = "mailto:" & sEmail
                linkEmail.ToolTip = "Email this Contact."
            End If
            
            
            Dim img As System.Web.UI.WebControls.Image = CType(item("ContactType").Controls(0), System.Web.UI.WebControls.Image)
            If sType = "ProjectManager" Then
                img.ImageUrl = "images/projectmanager_small.png"
            Else
                img.ImageUrl = "images/contact_small.png"
            End If
            
            

        End If
    
    End Sub
    
    Protected Sub RadGrid1_ItemDataBound(ByVal sender As Object, ByVal e As Telerik.Web.UI.GridItemEventArgs) Handles RadGrid1.ItemDataBound
        'This event allows us to customize the cell contents - fired after databound
        
        If (TypeOf e.Item Is GridDataItem) Then
 
            Dim item As GridDataItem = CType(e.Item, GridDataItem)
            If item("Company").Text = "-- Not Selected --" Then
                item("Company").Text = ""
            End If
            
            Dim linkButton As HyperLink = CType(item("FirstName").Controls(0), HyperLink)
            If Trim(linkButton.Text) = "" Then
                linkButton.Text = "-none-"
            End If

        End If
        
        
    End Sub
    
    Protected Sub butExportToPDF_Click(ByVal sender As Object, ByVal e As System.EventArgs)
        For Each item As GridItem In RadGrid1.MasterTableView.Items
            If TypeOf item Is GridDataItem Then
                Dim dataItem As GridDataItem = CType(item, GridDataItem)
                Dim lnk As HyperLink = CType(dataItem("FirstName").Controls(0), HyperLink)
                lnk.NavigateUrl = ""
            End If
        Next
        RadGrid1.MasterTableView.ExportToPdf()
    End Sub

    Protected Sub butExportToExcel_Click(ByVal sender As Object, ByVal e As System.EventArgs)
        RadGrid1.MasterTableView.ExportToExcel()
    End Sub
    
    
 
    
    Protected Sub RadMenuPage_ItemClick(ByVal sender As Object, ByVal e As Telerik.Web.UI.RadMenuEventArgs)
       
        Dim btn As RadMenuItem = e.Item
        
        Select Case btn.Value
            
            Case "FilterList"
                If btn.Text = "Show All" Then
                    btn.Text = "Show PM's Only"
                Else
                    btn.Text = "Show All"
                End If
                RadGrid1.Rebind()
            
            Case "ExportExcel"
                For Each item As GridItem In RadGrid1.MasterTableView.Items
                    If TypeOf item Is GridDataItem Then
                        Dim dataItem As GridDataItem = CType(item, GridDataItem)
                        Dim lnk As HyperLink = CType(dataItem("FirstName").Controls(0), HyperLink)
                        lnk.NavigateUrl = ""
                    End If
                Next
                RadGrid1.MasterTableView.ExportToExcel()
                
            Case "ExportPDF"
                For Each item As GridItem In RadGrid1.MasterTableView.Items
                    If TypeOf item Is GridDataItem Then
                        Dim dataItem As GridDataItem = CType(item, GridDataItem)
                        Dim lnk As HyperLink = CType(dataItem("FirstName").Controls(0), HyperLink)
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
                    db.SaveGridColumnVisibility("ContactsGridColumns", btn.Attributes("ID"), btn.Attributes("Visibility"), "DistrictID", Session("DistrictID"))
                End Using
                RadGrid1.Rebind()
                
            Case "RestoreDefaultSettings"
                
                Using db As New promptUserPrefs
                    db.RemoveUserSavedSettings("ContactsGridSettings", "DistrictID", Session("DistrictID"))
                    db.RemoveUserSavedSettings("ContactsGridColumns", "DistrictID", Session("DistrictID"))
                End Using
                Response.Redirect(Page.Request.RawUrl)

        End Select
    End Sub
    
    
    
</script>

<asp:Content ID="Content1" ContentPlaceHolderID="mainBody" runat="Server">
<div class="title">
<div class="innertube">
     <asp:Label ID="lblPageTitle" runat="server" CssClass="contacts_lbl" Style="float:left;margin: 10px 10px 5px 10px;">Contacts</asp:Label>
     <br /><br />
         
    <telerik:RadMenu ID="RadMenuPage" runat="server" OnItemClick="RadMenuPage_ItemClick" Style="z-index: 10;" />
    <br class="clear" />
    <telerik:RadGrid ID="RadGrid1" runat="server" AllowSorting="true" AutoGenerateColumns="False"
        EnableEmbeddedSkins="false" GridLines="None" Width="100%" EnableAJAX="True" Height="600"
        Skin="Prompt">
        <ClientSettings>
            <Selecting AllowRowSelect="False" />
            <Scrolling AllowScroll="True" UseStaticHeaders="True" ScrollHeight="50%" />
        </ClientSettings>
        <MasterTableView Width="100%" GridLines="None" DataKeyNames="ContactID,Email,ContactType" NoMasterRecordsText="No Contacts found.">
            <Columns>
                
                <telerik:GridImageColumn UniqueName="ContactType" HeaderText="">
                    <ItemStyle HorizontalAlign="Left" VerticalAlign="Top" Width="25px" />
                    <HeaderStyle HorizontalAlign="Left"  Width="25px" />
                </telerik:GridImageColumn>
                
                
                <telerik:GridHyperLinkColumn UniqueName="FirstName" HeaderText="First" DataTextField="FirstName"
                    SortExpression="FirstName">
                    <ItemStyle HorizontalAlign="Left" VerticalAlign="Top" Width="75px" />
                    <HeaderStyle HorizontalAlign="Left" Width="75px" />
                </telerik:GridHyperLinkColumn>
                <telerik:GridBoundColumn UniqueName="LastName" HeaderText="Last" DataField="LastName"
                    SortExpression="LastName">
                    <ItemStyle HorizontalAlign="Left" VerticalAlign="Top" Width="100px" />
                    <HeaderStyle HorizontalAlign="Left" Width="100px" />
                </telerik:GridBoundColumn>
                <telerik:GridBoundColumn UniqueName="Company" HeaderText="Company" DataField="Company">
                    <ItemStyle HorizontalAlign="Left" VerticalAlign="Top" />
                    <HeaderStyle HorizontalAlign="Left" />
                </telerik:GridBoundColumn>
                <telerik:GridBoundColumn UniqueName="Title" HeaderText="Title" DataField="Title">
                    <ItemStyle HorizontalAlign="Left" VerticalAlign="Top" />
                    <HeaderStyle HorizontalAlign="Left" />
                </telerik:GridBoundColumn>
                <telerik:GridBoundColumn UniqueName="Address1" HeaderText="Address1" DataField="Address1">
                    <ItemStyle HorizontalAlign="Left" VerticalAlign="Top" />
                    <HeaderStyle HorizontalAlign="Left" />
                </telerik:GridBoundColumn>
                <telerik:GridBoundColumn UniqueName="ContactType" HeaderText="Contact Type" DataField="ContactType">
                    <ItemStyle HorizontalAlign="Left" VerticalAlign="Top" />
                    <HeaderStyle HorizontalAlign="Left" />
                </telerik:GridBoundColumn>
                <telerik:GridBoundColumn UniqueName="Phone1" HeaderText="Phone1" DataField="Phone1">
                    <ItemStyle HorizontalAlign="Left" VerticalAlign="Top" />
                    <HeaderStyle HorizontalAlign="Left" />
                </telerik:GridBoundColumn>
                <telerik:GridBoundColumn UniqueName="Ext" HeaderText="Ext" DataField="Ext">
                    <ItemStyle HorizontalAlign="Left" VerticalAlign="Top" />
                    <HeaderStyle HorizontalAlign="Left" />
                </telerik:GridBoundColumn>
                <telerik:GridBoundColumn UniqueName="Phone2" HeaderText="Phone2" DataField="Phone2">
                    <ItemStyle HorizontalAlign="Left" VerticalAlign="Top" />
                    <HeaderStyle HorizontalAlign="Left" />
                </telerik:GridBoundColumn>
                <telerik:GridBoundColumn UniqueName="Cell" HeaderText="Cell" DataField="Cell">
                    <ItemStyle HorizontalAlign="Left" VerticalAlign="Top" />
                    <HeaderStyle HorizontalAlign="Left" />
                </telerik:GridBoundColumn>
                <telerik:GridHyperLinkColumn UniqueName="Email" HeaderText="Email" DataTextField="Email" SortExpression="Email">
                    <ItemStyle HorizontalAlign="Left" VerticalAlign="Top" />
                    <HeaderStyle HorizontalAlign="Left" />
                </telerik:GridHyperLinkColumn>
                <telerik:GridBoundColumn UniqueName="Fax" HeaderText="Fax" DataField="Fax">
                    <ItemStyle HorizontalAlign="Left" VerticalAlign="Top" />
                    <HeaderStyle HorizontalAlign="Left" />
                </telerik:GridBoundColumn>
                <telerik:GridBoundColumn UniqueName="Comments" HeaderText="Comments" DataField="Comments">
                    <ItemStyle HorizontalAlign="Left" VerticalAlign="Top" />
                    <HeaderStyle HorizontalAlign="Left" />
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
            <telerik:AjaxSetting AjaxControlID="RadMenuPage">
                <UpdatedControls>
                    <telerik:AjaxUpdatedControl ControlID="RadGrid1" LoadingPanelID="RadAjaxLoadingPanel1" />
                    <telerik:AjaxUpdatedControl ControlID="RadMenuPage" />
                </UpdatedControls>
            </telerik:AjaxSetting>
        </AjaxSettings>
    </telerik:RadAjaxManager>
    <telerik:RadAjaxLoadingPanel ID="RadAjaxLoadingPanel1" runat="server" Height="275px"
        Width="275px" Transparency="1">
        <img alt="Loading..." src="images/loading.gif" />
    </telerik:RadAjaxLoadingPanel>
    <telerik:RadWindowManager ID="contentPopups" runat="server">
    </telerik:RadWindowManager>
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


            function EditContact(id) {

                var oWnd = window.radopen("contact_edit.aspx?ContactID=" + id, "EditWindow");
                return false;
            }


//            function refreshGrid() {
//                RadGridNamespace.AsyncRequest('<%= RadGrid1.UniqueID %>', 'Rebind', '<%= RadGrid1.ClientID %>');
//            }

            function GetRadWindow() {
                var oWindow = null;
                if (window.RadWindow) oWindow = window.RadWindow;
                else if (window.frameElement.radWindow) oWindow = window.frameElement.radWindow;
                return oWindow;
            }

        </script>
</telerik:RadScriptBlock></div></div>
</asp:Content>
