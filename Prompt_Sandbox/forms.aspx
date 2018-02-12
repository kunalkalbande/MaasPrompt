<%@ Page Language="VB" MasterPageFile="~/prompt.master" Title="Welcome to Prompt" %>
<%@ Import Namespace="Prompt.promptForms" %>
<%@ Register Assembly="Telerik.Web.UI" Namespace="Telerik.Web.UI" TagPrefix="telerik" %>
<%@ Import Namespace="Prompt" %>
<script runat="server">
    Private CurrentProjectFilter As String = ""
    Private CurrentProjectGroupBy As String = ""
    Private bReadOnly As Boolean = True
    Private nProjectID As Integer = 0
    Private nCollegeID As Integer = 0
    
    Protected Sub Page_PreRender(ByVal sender As Object, ByVal e As System.EventArgs)
        Using db As New promptUserPrefs
            db.SaveGridSettings(RadGrid1, "FormsGridSettings", "ProjectID", nProjectID)
        End Using
    End Sub
    
    Protected Sub Page_Init(ByVal sender As Object, ByVal e As System.EventArgs)
        nProjectID = Request.QueryString("ProjectID")
        'set security
        Using dbsec As New EISSecurity
            dbsec.ProjectID = nProjectID
            If dbsec.FindUserPermission("FormsManagement", "write") Then
                bReadOnly = False
            Else
                bReadOnly = True
            End If
        End Using
    End Sub
    
    Private Sub Page_Load(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MyBase.Load

        ProcLib.CheckSession(Page)

        'set up help button
        Session("PageID") = "Forms"
        
        Dim sLocale As String = ProcLib.GetLocale()
        testPlace.Value = sLocale
        nProjectID = Request.QueryString("ProjectID")
        If Not IsPostBack Then
            nCollegeID = Request.QueryString("CollegeID")
            Session("CollegeID") = nCollegeID
        End If
        
        'Set Grid Properties
        With RadGrid1
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

            .MasterTableView.EnableHeaderContextMenu = True
            .MasterTableView.TableLayout = GridTableLayout.Fixed
            .MasterTableView.AllowMultiColumnSorting = False

            .Height = Unit.Pixel(600)
            .ExportSettings.FileName = "PromptCompaniesListExport"
            .ExportSettings.OpenInNewWindow = True
            .ExportSettings.Pdf.PageTitle = "PROMPT Forms List"
        End With
 
        'Set group by Level
        Dim expression As GridGroupByExpression = New GridGroupByExpression
        Dim gridGroupByField As GridGroupByField = New GridGroupByField
        RadGrid1.MasterTableView.GroupByExpressions.Clear()
        
        'Add select fields (before the "Group By" clause)
        gridGroupByField = New GridGroupByField
        gridGroupByField.FieldName = "FormType"
        gridGroupByField.HeaderText = " "
        gridGroupByField.HeaderValueSeparator = ""
        expression.SelectFields.Add(gridGroupByField)

        'Add a field for group-by (after the "Group By" clause)
        gridGroupByField = New GridGroupByField
        gridGroupByField.FieldName = "FormCategoryID"
        expression.GroupByFields.Add(gridGroupByField)

        RadGrid1.MasterTableView.GroupByExpressions.Add(expression)
     
        BuildMenu()

        With contentPopup
            .VisibleOnPageLoad = False
            .Skin = "Windows7"
                         
            Dim ww As New RadWindow
            ww = New RadWindow
            With ww
                .ID = "EditWindow"
                .Title = " "
                .Width = 785
                .Height = 360
                .Modal = True
                .VisibleStatusbar = False
                .ReloadOnShow = True
                .Behaviors = WindowBehaviors.Close + WindowBehaviors.Move
                .OnClientClose = "OnClientClose"
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
                If bReadOnly = True Then
                    .Style.Add("width", "105px")
                End If
            End With
            'build buttons
            Dim but As RadMenuItem
                
            but = New RadMenuItem
            With but

                .PostBack = False
                If bReadOnly = True Then
                    .Visible = False
                    .Enabled = False
                Else
                    .Visible = True
                    .Text = "Add New"
                    .ImageUrl = "images/add.png"
                    .Attributes("onclick") = "return EditForm(" & nProjectID & ",0,'New');"
                    .ToolTip = "Add a New Form."
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
            'RadMenu1.Items.Add(butDropDown)
 
            butDropDown = New RadMenuItem
            With butDropDown
                .Text = "Print"
                .ImageUrl = "images/printer.png"
                .PostBack = False
            End With
                           
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
                If col.HeaderText <>  "Category ID" And col.HeaderText <> "Form ID" And col.HeaderText <> "Form Number" Then
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
        'loads the grid whenever it needs data (sorting, rebinding, etc...)
        Using db As New promptForms
            RadGrid1.DataSource = db.GetFormsList(nProjectID, Session("CollegeID"), Session("DistrictID"))
        End Using
    End Sub
    
    Protected Sub RadGrid1_ItemCreated(ByVal sender As Object, ByVal e As Telerik.Web.UI.GridItemEventArgs) Handles RadGrid1.ItemCreated
        'This event allows us to customize the cell contents - fired before databound
        Dim file As String = ""
        Dim textTitle As String = ""
        If (TypeOf e.Item Is GridDataItem) Then
            Dim item As GridDataItem = CType(e.Item, GridDataItem)
            Dim nFormID As Integer = item.OwnerTableView.DataKeyValues(item.ItemIndex)("FormID")
            'David D 8/14/17 added below to pull the FormFileName
            Dim mData As DataTable
            Using db As New promptForms
                mData = db.getFormData(nProjectID, nFormID)
                file = mData.Rows(0).Item("FormFileName")
                textTitle = mData.Rows(0).Item("FormTitle")
            End Using
            
            Dim sForms As String = ProcLib.CheckNullDBField(item.OwnerTableView.DataKeyValues(item.ItemIndex)("FileName"))
            Dim sFormNumber As String = ProcLib.CheckNullDBField(item.OwnerTableView.DataKeyValues(item.ItemIndex)("FormNumber"))
            Dim sFormTitle As String = ProcLib.CheckNullDBField(item.OwnerTableView.DataKeyValues(item.ItemIndex)("FormTitle"))
            
            'update the link button to open form edit window
            Dim linkButton As HyperLink
            If bReadOnly Then
                item("FormTitle").Controls.Clear()
                item("FormTitle").Text = textTitle 'no link to edit
            Else
                linkButton = CType(item("FormTitle").Controls(0), HyperLink)
                linkButton.Attributes("onclick") = "return EditForm(" & nProjectID & "," & nFormID & ",'Existing');"
            End If
           
            'Note: These do not use rad windows as they are external opens
            If Not file = "None Selected" Then
                Dim sPath As String = ProcLib.GetCurrentRelativeAttachmentPath() & "DistrictID_" & Session("DistrictID") & "/_apprisedocs/"
                sPath &= "_forms/ProjectID_" & nProjectID & "/formID_" & nFormID & "/"

                Dim linkButton2 As HyperLink = CType(item("FileName").Controls(0), HyperLink)
                linkButton2.ToolTip = "Show currently posted Forms."
                linkButton2.NavigateUrl = sPath & file
                linkButton2.Target = "_new"
               
            Else            'remove the hyperlink and just display none
                item("FileName").Controls.Clear()
                item("FileName").Text = file
            End If
        End If
    End Sub

    Protected Sub RadGrid1_ItemDataBound(ByVal sender As Object, ByVal e As Telerik.Web.UI.GridItemEventArgs) Handles RadGrid1.ItemDataBound
        'This event allows us to customize the cell contents - fired after databound
        
        'If (TypeOf e.Item Is GridDataItem) Then
        '    Dim item As GridDataItem = DirectCast(e.Item, GridDataItem)
        '    Dim rowValue = DataBinder.Eval(item.DataItem, "FormTitle")
        '    Session("FormTitle") = rowValue.ToString().Replace("~", "'")
        'End If
    End Sub

    Private Sub CollapseAll()
        Dim item As GridItem
        For Each item In RadGrid1.MasterTableView.Controls(0).Controls
            If TypeOf item Is GridGroupHeaderItem Then
                item.Expanded = False
            End If
        Next item
    End Sub 'CollapseAll

    Protected Sub RadMenu1_ItemClick(ByVal sender As Object, ByVal e As Telerik.Web.UI.RadMenuEventArgs)
       
        Dim btn As RadMenuItem = e.Item
        
        Select Case btn.Value
            
            Case "ExportExcel"
                'RadGrid1.Columns.FindByUniqueName("Attachments").Visible = False
                RadGrid1.MasterTableView.ExportToExcel()
                
            Case "ExportPDF"
                'RadGrid1.Columns.FindByUniqueName("Attachments").Visible = False
                For Each item As GridItem In RadGrid1.MasterTableView.Items
                    If TypeOf item Is GridDataItem Then
                        Dim dataItem As GridDataItem = CType(item, GridDataItem)
                        Dim lnk As HyperLink = CType(dataItem("FormTitle").Controls(0), HyperLink)
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
                    db.SaveGridColumnVisibility("FormGridColumns", btn.Attributes("ID"), btn.Attributes("Visibility"), "ProjectID", nProjectID)
                End Using
                RadGrid1.Rebind()
                
            Case "RestoreDefaultSettings"
                
                Using db As New promptUserPrefs
                    db.RemoveUserSavedSettings("FormGridSettings", "ProjectID", nProjectID)
                    db.RemoveUserSavedSettings("FormGridColumns", "ProjectID", nProjectID)
                End Using
                Response.Redirect(Page.Request.RawUrl)

        End Select
    End Sub
</script>

<asp:Content ID="Content1" ContentPlaceHolderID="mainBody" runat="Server">
    <telerik:RadWindowManager ID="contentPopup" runat="server" />
    
<div class="title">

<div class="innertube">

<%--<asp:Image ID="Image1" runat="server" ImageUrl="images/reports.png" Style="margin:5px 10px;position:relative;top:10px;left:0;" />--%>

<asp:Label ID="lblPageTitle" runat="server" CssClass="forms_lbl">Form Management</asp:Label>
<telerik:radmenu id="RadMenu1" runat="server" onitemclick="RadMenu1_ItemClick" style="display:inline-block;z-index:10;clear:both;float:right;position:sticky;width:195px;right:-1px;margin-top:-30px;"/>
<br /><br class="clear" />

    <asp:HiddenField id="testPlace" Value="" runat="server" />

    <telerik:RadGrid ID="RadGrid1" runat="server" AllowSorting="True" AutoGenerateColumns="false"
        GridLines="none" Width="100%" EnableAJAX="True" Height="100%" Skin="Sitefinity">
        <ClientSettings>
            <Selecting AllowRowSelect="True" />
            <Scrolling AllowScroll="True" UseStaticHeaders="True" ScrollHeight="50%" SaveScrollPosition="true" />
        </ClientSettings>
        <MasterTableView Width="100%"  HeaderStyle-Height="10px" HeaderStyle-Font-Size=Small DataKeyNames="FormID" NoMasterRecordsText="No Forms available.">
            <Columns>
             <telerik:GridBoundColumn UniqueName="FormNumber" HeaderText="Form Number" DataField="FormNumber" Display=false Visible=false AllowFiltering=false>
                    <ItemStyle HorizontalAlign="Left"  Width="10%" VerticalAlign="Top" />
                    <HeaderStyle HorizontalAlign="Left" Width="10%" />
             </telerik:GridBoundColumn>
             <telerik:GridHyperLinkColumn UniqueName="FormTitle" HeaderText="Form Title" DataTextField="FormTitle" HeaderStyle-Font-Size="11px" >
                    <ItemStyle HorizontalAlign="Left"  Width="20%" VerticalAlign="Top" Wrap=true />
                    <HeaderStyle HorizontalAlign="Left" Width="20%" />
              </telerik:GridHyperLinkColumn>
              <telerik:GridBoundColumn UniqueName="FormID" HeaderText="Form ID" DataField="FormID" Display=false AllowFiltering="false" Visible=false>
                    <ItemStyle HorizontalAlign="Left"  Width="15%" VerticalAlign="Top" />
                    <HeaderStyle HorizontalAlign="Left" Width="15%" />
              </telerik:GridBoundColumn>
              <telerik:GridHyperLinkColumn UniqueName="FileName" HeaderText="Document Name" DataTextField="FormFileName"  HeaderStyle-Font-Size="11px" >
                    <ItemStyle HorizontalAlign="Left" Width="30%" VerticalAlign="Top" Wrap=true />
                    <HeaderStyle HorizontalAlign="Left" Width="30%" />
              </telerik:GridHyperLinkColumn>
              <telerik:GridBoundColumn UniqueName="Description" HeaderText="Form Description" DataField="Description"  AllowSorting=true>
                    <ItemStyle HorizontalAlign="Left" Width="30%" VerticalAlign="Top" Wrap="true" />
                    <HeaderStyle HorizontalAlign="Left" Width="30%" Wrap="true" />
              </telerik:GridBoundColumn>
              <telerik:GridBoundColumn UniqueName="FormType" HeaderText="Form Type" DataField="FormType" AllowSorting=true>
                    <ItemStyle HorizontalAlign="Left" Width="10%" VerticalAlign="Top" Wrap="true" />
                    <HeaderStyle HorizontalAlign="Left" Width="10%" Wrap="true" />
              </telerik:GridBoundColumn>
              <telerik:GridBoundColumn UniqueName="LastUpdateOn" HeaderText="Update Date" DataField="LastUpdateOn" AllowSorting=true>
                    <ItemStyle HorizontalAlign="Left" Width="10%" VerticalAlign="Top" />
                    <HeaderStyle HorizontalAlign="Left" Width="10%" />
              </telerik:GridBoundColumn>
              <telerik:GridBoundColumn UniqueName="LastUpdateBy" HeaderText="Document Owner" DataField="LastUpdateBy" AllowSorting=true>
                    <ItemStyle HorizontalAlign="Left" Width="10%" VerticalAlign="Top" />
                    <HeaderStyle HorizontalAlign="Left" Width="10%" />
              </telerik:GridBoundColumn>
              <telerik:GridBoundColumn UniqueName="FormCategoryID" HeaderText="Category ID" DataField="FormCategoryID" display="false" AllowFiltering="false" Visible=false >
                    <ItemStyle HorizontalAlign="Left" Width="5%" VerticalAlign="Top" />
                    <HeaderStyle HorizontalAlign="Left" Width="5%" />
              </telerik:GridBoundColumn>
            </Columns>
        </MasterTableView>
    </telerik:RadGrid>
    <telerik:RadScriptBlock ID="RadScriptBlock1" runat="server">

<script type="text/javascript" language="javascript">
        function GetRadWindow() {
            var oWindow = null;
            if (window.RadWindow) oWindow = window.RadWindow;
            else if (window.frameElement.radWindow) oWindow = window.frameElement.radWindow;
            return oWindow;
        }

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

    function EditForm(projectid, id, displaytype) {

        var oWnd = window.radopen("forms_edit.aspx?ProjectID=" + projectid + "&FormID=" + id + "&DisplayType=" + displaytype, "EditWindow");
        return false;
    }

    /*David D 8/21/17 added this to refresh parent page if user clicks the red close button at the top right of pop-up radwindow*/
    function OnClientClose(sender, args) {
        //window.location.reload();//- will reload the page (equal to pressing F5)  
        window.location.href = window.location.href; // - will refresh the page by reloading the URL   
    }

</script>
</telerik:RadScriptBlock>
    </div>
    </div>
</asp:Content>
