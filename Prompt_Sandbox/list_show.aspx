<%@ Page Language="VB" %>
<%@ Import Namespace="Prompt" %>
<%@ Register Assembly="Telerik.Web.UI" Namespace="Telerik.Web.UI" TagPrefix="telerik" %>

<script runat="server">

    Private ListType As String = ""
    Private sDataSQL As String = ""
    Private sEditLink As String = ""
    Private sLookupParentTable As String = ""
    Private sLookupParentField As String = ""
    Private popWidth As String = "575"
    Private popHeight As String = "400"
    Private sScroll As String = "no"
    
    Private bReadOnly As Boolean = True
    
    
    
    Private Sub Page_Load(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MyBase.Load

        ProcLib.CheckSession(Page)
        ProcLib.LoadPopupJscript(Page)

        ListType = Request.QueryString("ListType")
        sLookupParentTable = Request.QueryString("ParentTable")
        sLookupParentField = Request.QueryString("ParentField")
        
        'Show hide columns        
        With RadGrid1.MasterTableView
            .Columns.FindByUniqueName("ReportNumber").Visible = False
            .Columns.FindByUniqueName("ReportType").Visible = False
            .Columns.FindByUniqueName("Description").Visible = False
        End With

        Select Case ListType
  
            Case "Help"
                sDataSQL = "SELECT HelpID AS ID, PageID AS Title, PageTitle AS Value FROM Help ORDER BY PageID"
                lnkAddNew.Attributes("onclick") = "openPopup('help_edit.aspx?new=y','winAdd',650,650,'yes');"
                sEditLink = "help_edit.aspx?HelpID="
                popWidth = "700"
                popHeight = "625"
                sScroll = "yes"
                Session("PageID") = "HelpList"
                
                With RadGrid1.MasterTableView
                    '.Columns.FindByUniqueName("Value").Visible = False
                    .Columns.FindByUniqueName("Title").HeaderText = "PageID"
                    .Columns.FindByUniqueName("Value").HeaderText = "Page Title"
                End With
                               
            Case "BudgetChangeBatch"
                lnkAddNew.Attributes("onclick") = "openPopup('budget_change_batch_edit.aspx?new=y','winAdd',400,250,'yes');"
                sDataSQL = "SELECT BudgetChangeBatchID AS ID , Description AS Descr FROM BudgetChangeBatches WHERE DistrictID = " & Session("DistrictID") & " ORDER BY BudgetChangeBatchID ASC"
                sEditLink = "budget_change_batch_edit.aspx?ID="
                popWidth = "400"
                popHeight = "350"
                Session("PageID") = "BudgetChangeBatchList"
                

                'Case "PaymentBatch"
                '    lnkAddNew.Attributes("onclick") = "openPopup('payment_batch_add.aspx','winAdd',650,650,'yes');"
                          
                
            Case "FE_Budgets"
                sDataSQL = "Select DivisionID as ID, Coalesce(DivName,'none') + ' --- Admin: ' + Coalesce(AdminName,'No Admin Assigned') + ' --- Budget: ' + Convert(varchar, Coalesce(Budget,0)) as Title From FE_Budgets Where DistrictID = " & Session("DistrictID") & " ORDER BY Title "
                sEditLink = "FE_divisions_edit.aspx?DivisionID="
                popWidth = 600
                popHeight = "450"
                Session("PageID") = "FE_DivisionList"
                lnkAddNew.Attributes("onclick") = "openPopup('FE_divisions_edit.aspx?new=y','winAdd',650,650,'yes');"
                RadGrid1.MasterTableView.Columns.FindByUniqueName("Value").Visible = False
                
            Case "FE_LogList"
                sDataSQL = "Select PrimaryKey as ID, Convert(char(12),CreatedOn) + ' - ' + Notes as Title From FE_BudgetLog Where DistrictID = " & Session("DistrictID") & " ORDER BY CreatedOn Desc "
                sEditLink = "x"
                popWidth = 600
                popHeight = "450"
                Session("PageID") = "FE_LogList"
                RadGrid1.MasterTableView.Columns.FindByUniqueName("Value").Visible = False
                
            Case "ReportAdmin"
                lnkAddNew.Attributes("onclick") = "openPopup('report_edit.aspx?new=y','winAdd',700,650,'yes');"
                sDataSQL = "SELECT ReportID as ID, ReportTitle AS Title, ReportNumber, Description, SecurityLevel, ReportType FROM Reports ORDER BY ReportTitle "
                sEditLink = "report_edit.aspx?ReportID="
                popWidth = "700"
                popHeight = "625"
                Session("PageID") = "ReportAdminList"
                
                With RadGrid1.MasterTableView
                    .Columns.FindByUniqueName("ReportNumber").Visible = True
                    .Columns.FindByUniqueName("ReportType").Visible = True
                    .Columns.FindByUniqueName("Description").Visible = True
                    .Columns.FindByUniqueName("Value").Visible = False
                End With
                
            Case "Lookups"
                lnkAddNew.Attributes("onclick") = "openPopup('lookup_edit.aspx?new=y&ParentTable=" & sLookupParentTable & "&ParentField=" & sLookupParentField & "','winAdd',550,350,'yes');"
                sDataSQL = "SELECT PrimaryKey as ID, LookupValue  AS Value, LookupTitle  AS Title, MaxLength FROM Lookups WHERE ParentTable = '" & sLookupParentTable & "' "
                sDataSQL &= "AND ParentField ='" & sLookupParentField & "' AND DistrictID = " & Session("DistrictID") & " ORDER BY LookupTitle"
                sEditLink = "lookup_edit.aspx?ParentTable=" & sLookupParentTable & "&ParentField=" & sLookupParentField & "&LookupID= "
                popWidth = "500"
                popHeight = "275"
                Session("PageID") = "LookupsList"
                
            Case "GlobalLookupAdmin"
                lnkAddNew.Attributes("onclick") = "openPopup('lookup_edit.aspx?Admin=y&new=y&ParentTable=" & sLookupParentTable & "&ParentField=" & sLookupParentField & "','winAdd',650,650,'yes');"
                sDataSQL = "SELECT PrimaryKey as ID, LookupTitle  AS Title FROM Lookups WHERE ParentTable = '" & sLookupParentTable & "' "
                sDataSQL &= "AND ParentField ='" & sLookupParentField & "' AND DistrictID = 0 ORDER BY LookupTitle"
                sEditLink = "lookup_edit.aspx?admin=y&LookupID="
                popWidth = "450"
                popHeight = "425"
                Session("PageID") = "GlobalLookupAdmin"
        End Select

        lnkAddNew.Visible = False
        Using dbsec As New EISSecurity
            If dbsec.FindUserPermission("TableMaintenance", "write") Then
                lnkAddNew.Visible = True
                bReadOnly = False
            End If
            
        End Using
        
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

            'If Request.Browser.Browser = "IE" Then
            RadGrid1.Height = Unit.Pixel(600)
            'Else
            '.Height = Unit.Percentage(88)
            'End If
            
            .ExportSettings.FileName = "PromptTableExport"
            .ExportSettings.OpenInNewWindow = True
            .ExportSettings.Pdf.PageTitle = "Table Export"

        End With
        
        With contentPopups
            .VisibleOnPageLoad = False
            .Skin = "Office2007"
                         
            Dim ww As New RadWindow

            ww = New RadWindow
            With ww
                .ID = "EditWindow"
                .NavigateUrl = "#"
                .Title = ""
                .Width = 800
                .Height = 600
                .Modal = True
                .VisibleStatusbar = False
                .ReloadOnShow = True
                .Behaviors = WindowBehaviors.Close
            End With
            .Windows.Add(ww)
            
    
        End With
        
        
        If Session("RtnFromEdit") = True Then
            RadGrid1.Rebind()
            Session("RtnFromEdit") = False
        End If
        

    End Sub

    
    Protected Sub RadGrid1_NeedDataSource(ByVal source As Object, ByVal e As Telerik.Web.UI.GridNeedDataSourceEventArgs) Handles RadGrid1.NeedDataSource
        Using db As New PromptDataHelper
            RadGrid1.DataSource = db.ExecuteDataTable(sDataSQL)
        End Using
    End Sub
    
    Protected Sub RadGrid1_ItemCreated(ByVal sender As Object, ByVal e As Telerik.Web.UI.GridItemEventArgs) Handles RadGrid1.ItemCreated
        'This event allows us to customize the cell contents - fired before databound
        
        If (TypeOf e.Item Is GridDataItem) Then
            Dim item As GridDataItem = CType(e.Item, GridDataItem)
            Dim nKey As Integer = item.OwnerTableView.DataKeyValues(item.ItemIndex)("ID")
            'update the link button to open edit window
            Dim hlnk As HyperLink = CType(item("Title").Controls(0), HyperLink)
            
            If Not bReadOnly Then
                hlnk.Attributes.Add("onclick", "openPopup('" & sEditLink & nKey & "','EditWin'," & popWidth & "," & popHeight & ",'" & sScroll & "');")
                hlnk.ToolTip = "Edit selected record."
                hlnk.NavigateUrl = "#"
            Else
                hlnk.NavigateUrl = ""
            End If
 
                       
        End If
        
        
    End Sub
    
    Protected Sub RadGrid1_ItemDataBound(ByVal sender As Object, ByVal e As Telerik.Web.UI.GridItemEventArgs) Handles RadGrid1.ItemDataBound
        ''This event allows us to customize the cell contents - fired after databound

        'If (TypeOf e.Item Is GridDataItem) Then
        '    Dim item As GridDataItem = CType(e.Item, GridDataItem)
        '    Dim nUserID As Integer = item.OwnerTableView.DataKeyValues(item.ItemIndex)("UserID")
        '    If item("AccountDisabled").Text = "1" Then
        '        item("AccountDisabled").Text = "Y"
        '    Else
        '        item("AccountDisabled").Text = " "
        '    End If
        'End If

        
    End Sub


</script>

<html xmlns="http://www.w3.org/1999/xhtml">
<head id="Head1" runat="server">
    <title>Admin Table Maint </title>
    <link href="Styles.css" rel="stylesheet" type="text/css" />
        <link href="skins/Prompt/Grid.Prompt.css" rel="stylesheet" type="text/css"/>
</head>
<body>
    <form id="Form1" method="post" runat="server">
    <telerik:RadScriptManager ID="RadScriptManager1" runat="server" />
    <br />
    <div align="right" id="header" style="float: right; z-index: 150; position: static; padding-right: 25px;">
        <asp:HyperLink ID="lnkAddNew" runat="server" NavigateUrl="#" ImageUrl="images/button_add_new.gif">add new</asp:HyperLink>
    </div>
    <br />
        <br />
    <telerik:RadGrid ID="RadGrid1" runat="server" AllowSorting="true" AutoGenerateColumns="False"
        GridLines="None" Width="98%" EnableAJAX="True" Height="600px" Skin="Sitefinity">
        <ClientSettings>
            <Selecting AllowRowSelect="True" />
            <Scrolling AllowScroll="True" UseStaticHeaders="True" ScrollHeight="50%" SaveScrollPosition="true" />
        </ClientSettings>
        <MasterTableView Width="100%" GridLines="None" DataKeyNames="ID" NoMasterRecordsText="No Items Found.">
            <Columns>
                <telerik:GridHyperLinkColumn UniqueName="Title" HeaderText="Title" DataTextField="Title"
                    SortExpression="Title">
                    <ItemStyle HorizontalAlign="Left" Width="10%" VerticalAlign="Top" />
                    <HeaderStyle HorizontalAlign="Left" Width="10%" />
                </telerik:GridHyperLinkColumn>
                <telerik:GridBoundColumn UniqueName="Value" HeaderText="Value" DataField="Value">
                    <ItemStyle HorizontalAlign="Left" Width="10%" />
                    <HeaderStyle HorizontalAlign="Left" Width="10%" />
                </telerik:GridBoundColumn>
                <telerik:GridBoundColumn UniqueName="ReportNumber" HeaderText="Number" DataField="ReportNumber">
                    <ItemStyle HorizontalAlign="Left" Width="10%" VerticalAlign="Top" />
                    <HeaderStyle HorizontalAlign="Left" Width="10%" />
                </telerik:GridBoundColumn>
               <telerik:GridBoundColumn UniqueName="Description" HeaderText="Description" DataField="Description">
                    <ItemStyle HorizontalAlign="Left" Width="10%" VerticalAlign="Top" />
                    <HeaderStyle HorizontalAlign="Left" Width="10%" />
                </telerik:GridBoundColumn>
  
                
                                              <telerik:GridBoundColumn UniqueName="ReportType" HeaderText="Type" DataField="ReportType">
                    <ItemStyle HorizontalAlign="Left" Width="10%" VerticalAlign="Top" />
                    <HeaderStyle HorizontalAlign="Left" Width="10%" />
                </telerik:GridBoundColumn> 
                
            </Columns>
        </MasterTableView>
    </telerik:RadGrid>
    <telerik:RadAjaxManager ID="RadAjaxManager1" runat="server">
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
    <telerik:RadWindowManager ID="contentPopups" runat="server">
    </telerik:RadWindowManager>
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
    </form>
</body>
</html>
