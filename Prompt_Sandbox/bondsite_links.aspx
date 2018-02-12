<%@ Page Language="VB" %>
<%@ Import Namespace="Prompt" %>
<%@ Register Assembly="Telerik.Web.UI" Namespace="Telerik.Web.UI" TagPrefix="telerik" %>

<script runat="server">
    
    Private Sub Page_Load(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MyBase.Load

        ProcLib.CheckSession(Page)
        ProcLib.LoadPopupJscript(Page)

        ''set up help button
        Session("PageID") = "BondsiteLinks"
        
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
            .Height = Unit.Pixel(600)
            'Else
            '.Height = Unit.Percentage(88)
            'End If
            
            .ExportSettings.FileName = "PromptBondLinksExport"
            .ExportSettings.OpenInNewWindow = True
            .ExportSettings.Pdf.PageTitle = "Bond Website Link List"
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
                .Width = 550
                .Height = 275
                .Modal = True
                .VisibleStatusbar = False
                .ReloadOnShow = True
                .Behaviors = WindowBehaviors.Close + WindowBehaviors.Move
            End With
            .Windows.Add(ww)
            
   
        End With
        
        linkAddNew.Attributes("onclick") = "return AddNewLink();"
 
          
    End Sub
    
    Protected Sub RadGrid1_NeedDataSource(ByVal source As Object, ByVal e As Telerik.Web.UI.GridNeedDataSourceEventArgs) Handles RadGrid1.NeedDataSource
        'loads the grid whenever it needs data (sorting, rebinding, etc...)
        Using db As New BondSite
            RadGrid1.DataSource = db.GetAllBondLinks()
        End Using
        
    End Sub
    
    Protected Sub RadGrid1_ItemCreated(ByVal sender As Object, ByVal e As Telerik.Web.UI.GridItemEventArgs) Handles RadGrid1.ItemCreated
        
        'This event allows us to customize the cell contents - fired before databound
        
        If (TypeOf e.Item Is GridDataItem) Then
            Dim item As GridDataItem = CType(e.Item, GridDataItem)
            Dim nLinkID As Integer = item.OwnerTableView.DataKeyValues(item.ItemIndex)("PrimaryKey")
 
            'update the link button to open report window
            Dim linkButton As HyperLink = CType(item("EditLink").Controls(0), HyperLink)
            linkButton.Attributes("onclick") = "return EditLink(" & nLinkID & ");"
            linkButton.ToolTip = "Edit selected Link."
            linkButton.NavigateUrl = "#"
            linkButton.ImageUrl = "images/edit.png"
  
        End If
    End Sub
 
</script>

<html xmlns="http://www.w3.org/1999/xhtml">
<head id="Head1" runat="server">
    <title> </title>
    <link href="Styles.css" rel="stylesheet" type="text/css" />
</head>
<body>
    <form id="Form1" method="post" runat="server">
    <telerik:RadScriptManager ID="RadScriptManager1" runat="server" />
    <br />
<div align="right" id="header" style="float: right; z-index: 150; position: static;">
   <asp:HyperLink ID="linkAddNew" runat="server" NavigateURL="#"  ImageUrl="images/button_add_new.gif">add new</asp:HyperLink>
</div>
<br />
<br />
<telerik:RadGrid ID="RadGrid1" runat="server" AllowSorting="False" AutoGenerateColumns="False"
    GridLines="None" Width="100%" EnableAJAX="True" Height="95%" SkinsPath="" Skin="Simple">
    <ClientSettings>
        <Selecting AllowRowSelect="False" />
        <Scrolling AllowScroll="True" UseStaticHeaders="True" ScrollHeight="50%" />
    </ClientSettings>
    <MasterTableView Width="100%" GridLines="None" DataKeyNames="PrimaryKey" NoMasterRecordsText="No links found.">
        <Columns>
  
            <telerik:GridHyperLinkColumn UniqueName="EditLink" HeaderText="" >
                <ItemStyle HorizontalAlign="Left" Width="30px" />
                <HeaderStyle HorizontalAlign="Left" Width="30px" />
            </telerik:GridHyperLinkColumn>
           
           <telerik:GridBoundColumn UniqueName="Title" HeaderText="Title" DataField="Title" >
                <ItemStyle HorizontalAlign="Left" />
                <HeaderStyle HorizontalAlign="Left" Width="30%" />
            </telerik:GridBoundColumn>
            <telerik:GridBoundColumn UniqueName="Description" HeaderText="Description" DataField="Description">
                <ItemStyle HorizontalAlign="Left" />
                <HeaderStyle HorizontalAlign="Left" Width="60%" />
            </telerik:GridBoundColumn>
 
        </Columns>
    </MasterTableView>
</telerik:RadGrid>
<telerik:RadWindowManager ID="contentPopups" runat="server">
</telerik:RadWindowManager>

<script type="text/javascript" language="javascript">

    function EditLink(id) {

        var oWnd = window.radopen("bondsite_link_edit.aspx?LinkID=" + id, "EditWindow");
        return false;
    }


    function AddNewLink() {

        var oWnd = window.radopen("bondsite_link_edit.aspx?LinkID=0", "EditWindow");
        return false;
    }

    function refreshGrid() {
        RadGridNamespace.AsyncRequest('<%= RadGrid1.UniqueID %>', 'Rebind', '<%= RadGrid1.ClientID %>');
    }

    function GetRadWindow() {
        var oWindow = null;
        if (window.RadWindow) oWindow = window.RadWindow;
        else if (window.frameElement.radWindow) oWindow = window.frameElement.radWindow;
        return oWindow;
    }

</script>
    </form>
</body>
</html>
