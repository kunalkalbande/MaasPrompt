<%@ Page Language="VB" %>
<%@ Import Namespace="Prompt" %>
<%@ Register Assembly="Telerik.Web.UI" Namespace="Telerik.Web.UI" TagPrefix="telerik" %>

<script runat="server">
   
    Private CurrentUserFilter As String = ""
    Private CurrentDistrictFilter As Integer = 0
   
    Private Sub Page_Load(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MyBase.Load

        ProcLib.CheckSession(Page)

        ''set up help button
        Session("PageID") = "AdminUsers"
        
        Using db As New promptUser
            db.LoadAdminUserFilterList(lstDistrictFilter)
        End Using
        
        CurrentUserFilter = lstUserFilter.SelectedValue
        CurrentDistrictFilter = lstDistrictFilter.SelectedValue
 
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
            
            .ExportSettings.FileName = "PromptUsersExport"
            .ExportSettings.OpenInNewWindow = True
            .ExportSettings.Pdf.PageTitle = "User List"

        End With
        
        With UserPopups
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

          
    End Sub
    
    Protected Sub RadGrid1_NeedDataSource(ByVal source As Object, ByVal e As Telerik.Web.UI.GridNeedDataSourceEventArgs) Handles RadGrid1.NeedDataSource
        'loads the grid whenever it needs data (sorting, rebinding, etc...)
        Using db As New promptUser
 
            RadGrid1.DataSource = db.GetAllUsers(CurrentUserFilter, CurrentDistrictFilter)

        End Using
        

    End Sub
    
    Protected Sub RadGrid1_ItemCreated(ByVal sender As Object, ByVal e As Telerik.Web.UI.GridItemEventArgs) Handles RadGrid1.ItemCreated
        'This event allows us to customize the cell contents - fired before databound
        
        If (TypeOf e.Item Is GridDataItem) Then
            Dim item As GridDataItem = CType(e.Item, GridDataItem)
            Dim nUserID As Integer = item.OwnerTableView.DataKeyValues(item.ItemIndex)("UserID")
            'update the link button to open report window
            Dim linkButton As HyperLink = CType(item("UserName").Controls(0), HyperLink)
            'linkButton.Attributes("onclick") = "return EditUser(" & nUserID & ");"
            linkButton.ToolTip = "Edit selected User."
            linkButton.NavigateUrl = "admin_user_edit.aspx?UserID=" & nUserID
                       
            Dim linkButton1 As HyperLink = CType(item("LoginAs").Controls(0), HyperLink)
            linkButton1.ToolTip = "Log in as this users."
            linkButton1.NavigateUrl = "index.aspx?loginasanotheruser=100&otherid=" & nUserID
            linkButton1.ImageUrl = "images/loginAs.png"
            linkButton.Target = "_self"
            
            If item("AccountDisabled").Text = "1" Then
                item("AccountDisabled").Text = "Y"
            Else
                item("AccountDisabled").Text = " "
            End If
        End If
        
        
    End Sub
    
    Protected Sub RadGrid1_ItemDataBound(ByVal sender As Object, ByVal e As Telerik.Web.UI.GridItemEventArgs) Handles RadGrid1.ItemDataBound
        'This event allows us to customize the cell contents - fired after databound
        
        If (TypeOf e.Item Is GridDataItem) Then
            Dim item As GridDataItem = CType(e.Item, GridDataItem)
            Dim nUserID As Integer = item.OwnerTableView.DataKeyValues(item.ItemIndex)("UserID")
            If item("AccountDisabled").Text = "1" Then
                item("AccountDisabled").Text = "Y"
            Else
                item("AccountDisabled").Text = " "
            End If
        End If
        
        
    End Sub
    
    
 
    Protected Sub lstUserFilter_SelectedIndexChanged(ByVal sender As Object, ByVal e As System.EventArgs)
        CurrentUserFilter = sender.SelectedValue
        RadGrid1.Rebind()
    End Sub
    
    Protected Sub lstDistrictFilter_SelectedIndexChanged(ByVal sender As Object, ByVal e As System.EventArgs)
        CurrentDistrictFilter = sender.SelectedValue
        RadGrid1.Rebind()

    End Sub
 
</script>

<html xmlns="http://www.w3.org/1999/xhtml">
<head id="Head1" runat="server">
    <title>Admin User List </title>
    <link href="Styles.css" rel="stylesheet" type="text/css" />
    <link href="skins/Prompt/Grid.Prompt.css" rel="stylesheet" type="text/css"/>
<link href="skins/Prompt/Menu.Prompt.css" rel="stylesheet" type="text/css"/>
</head>
<body>
    <form id="Form1" method="post" runat="server">
    <telerik:RadScriptManager ID="RadScriptManager1" runat="server" />
    <br />
    <div align="right" id="header" style="float: right; z-index: 150; position: static;
        padding-right: 25px;">
        <asp:HyperLink ID="linkAddNew" runat="server" NavigateUrl="admin_user_edit.aspx?UserID=0"
            ImageUrl="images/button_add_new.gif">add new</asp:HyperLink>
    </div>
    <asp:Label ID="lbl999" runat="server">Filter:</asp:Label>
    <asp:DropDownList ID="lstUserFilter" runat="server" AutoPostBack="True" OnSelectedIndexChanged="lstUserFilter_SelectedIndexChanged">
        <asp:ListItem Value="Active">All Active Users</asp:ListItem>
        <asp:ListItem Value="Disabled">All Disabled Users</asp:ListItem>
         <asp:ListItem Value="All">All Users</asp:ListItem>
        <asp:ListItem Value="Tech">Tech Support</asp:ListItem>
    </asp:DropDownList>
    &nbsp;&nbsp;
    <asp:Label ID="Label1" runat="server">District:</asp:Label>
    <asp:DropDownList ID="lstDistrictFilter" runat="server" AutoPostBack="True" OnSelectedIndexChanged="lstDistrictFilter_SelectedIndexChanged">
        <asp:ListItem Selected="True" Value="0">All</asp:ListItem>
    </asp:DropDownList>
    <br />
    <br />
    <telerik:RadGrid ID="RadGrid1" runat="server" AllowSorting="true" AutoGenerateColumns="False"
        GridLines="None" Width="98%" EnableAJAX="True" Height="600px" Skin="Sitefinity">
        <ClientSettings>
            <Selecting AllowRowSelect="True" />
            <Scrolling AllowScroll="True" UseStaticHeaders="True" ScrollHeight="50%" SaveScrollPosition="true" />
        </ClientSettings>
        <MasterTableView Width="100%" GridLines="None" DataKeyNames="UserID" NoMasterRecordsText="No Users Found.">
            <Columns>
                <telerik:GridHyperLinkColumn UniqueName="UserName" HeaderText="User" DataTextField="UserName"
                    SortExpression="UserName">
                    <ItemStyle HorizontalAlign="Left" Width="20%" VerticalAlign="Top" />
                    <HeaderStyle HorizontalAlign="Left" Width="20%" />
                </telerik:GridHyperLinkColumn>
                <telerik:GridHyperLinkColumn UniqueName="LoginAs" HeaderText="LoginAs">
                    <ItemStyle HorizontalAlign="Left" Width="35px" />
                    <HeaderStyle HorizontalAlign="Left" Width="35px" />
                </telerik:GridHyperLinkColumn>
                <telerik:GridBoundColumn UniqueName="LoginID" HeaderText="LoginID" DataField="LoginID">
                    <ItemStyle HorizontalAlign="Left" Width="10%" VerticalAlign="Top" />
                    <HeaderStyle HorizontalAlign="Left" Width="10%" />
                </telerik:GridBoundColumn>
                <telerik:GridBoundColumn UniqueName="Password" HeaderText="Password" DataField="Password">
                    <ItemStyle HorizontalAlign="Left" Width="10%" VerticalAlign="Top" />
                    <HeaderStyle HorizontalAlign="Left" Width="10%" />
                </telerik:GridBoundColumn>
                <telerik:GridBoundColumn UniqueName="RoleName" HeaderText="Role" DataField="RoleName">
                    <ItemStyle HorizontalAlign="Left" Width="10%" VerticalAlign="Top" />
                    <HeaderStyle HorizontalAlign="Left" Width="10%" />
                </telerik:GridBoundColumn>
                
                                <telerik:GridBoundColumn UniqueName="Dashboard" HeaderText="Dashboard" DataField="Dashboard">
                    <ItemStyle HorizontalAlign="Left" Width="10%" VerticalAlign="Top" />
                    <HeaderStyle HorizontalAlign="Left" Width="10%" />
                </telerik:GridBoundColumn>
                
                <telerik:GridBoundColumn UniqueName="LastLoginOn" HeaderText="LastLogin" DataField="LastLoginOn"
                    DataFormatString="{0:MM/dd/yy}">
                    <ItemStyle HorizontalAlign="Left" Width="45" VerticalAlign="Top" />
                    <HeaderStyle HorizontalAlign="Left" Width="45" />
                </telerik:GridBoundColumn>
                <telerik:GridBoundColumn UniqueName="AccountDisabled" HeaderText="Disabled?" DataField="AccountDisabled">
                    <ItemStyle HorizontalAlign="Left" Width="25px" VerticalAlign="Top" />
                    <HeaderStyle HorizontalAlign="Left" Width="25px" />
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
    <telerik:RadWindowManager ID="UserPopups" runat="server">
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
