<%@ Page Language="VB" %>
<%@ Import Namespace="Prompt" %>
<%@ Register Assembly="Telerik.Web.UI" Namespace="Telerik.Web.UI" TagPrefix="telerik" %>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">

<script runat="server">
   
  
    Private Sub Page_Load(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MyBase.Load

        ProcLib.CheckSession(Page)

        ''set up help button
        Session("PageID") = "AdminUserRoles"
       
        ' linkAddNew.Attributes("onclick") = "return EditUser(0);"

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
            RadGrid1.DataSource = db.GetAllUserRoles()
        End Using
        

    End Sub
    
    Protected Sub RadGrid1_ItemCreated(ByVal sender As Object, ByVal e As Telerik.Web.UI.GridItemEventArgs) Handles RadGrid1.ItemCreated
        'This event allows us to customize the cell contents - fired before databound
        
        If (TypeOf e.Item Is GridDataItem) Then
            Dim item As GridDataItem = CType(e.Item, GridDataItem)
            Dim nRoleID As Integer = item.OwnerTableView.DataKeyValues(item.ItemIndex)("UserRoleID")
            Dim nRoleName As String = item.OwnerTableView.DataKeyValues(item.ItemIndex)("RoleName")
            'update the link button to open report window
            Dim linkButton As HyperLink = CType(item("Edit").Controls(0), HyperLink)
            If nRoleName <> "TechSupport" Then
                linkButton.Attributes("onclick") = "return EditRole(" & nRoleID & ");"
            End If
            
            linkButton.ToolTip = "Edit selected User."
            linkButton.NavigateUrl = "#"
            linkButton.ImageUrl = "images/edit.png"
            
 
        End If
        
        
    End Sub
    
    Protected Sub RadGrid1_ItemDataBound(ByVal sender As Object, ByVal e As Telerik.Web.UI.GridItemEventArgs) Handles RadGrid1.ItemDataBound
        'This event allows us to customize the cell contents - fired after databound
        
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
    <title>Admin User Roles </title>
    <link href="Styles.css" rel="stylesheet" type="text/css" />
</head>
<body>
    <form id="Form1" method="post" runat="server">
     <telerik:RadScriptManager ID="RadScriptManager1" runat="server" />
    <br />
    <div align="right" id="header" style="float: right; z-index: 150; position: static;
        padding-right: 25px;">
        <asp:HyperLink ID="linkAddNew" runat="server" NavigateUrl="#" ImageUrl="images/button_add_new.gif">add new</asp:HyperLink>
    </div>
     <br />
    <br />
    <telerik:RadGrid ID="RadGrid1" runat="server" AllowSorting="true" AutoGenerateColumns="False"
        GridLines="None" Width="98%" EnableAJAX="True" Height="600px" Skin="Sitefinity"
        RegisterWithScriptManager="False">
        <ClientSettings>
            <Selecting AllowRowSelect="True" />
            <Scrolling AllowScroll="True" UseStaticHeaders="True" ScrollHeight="50%" SaveScrollPosition="true" />
        </ClientSettings>
        <MasterTableView Width="100%" GridLines="None" DataKeyNames="UserRoleID,RoleName" NoMasterRecordsText="No User Roles Found.">
            <Columns>
                <telerik:GridHyperLinkColumn UniqueName="Edit" HeaderText="">
                    <ItemStyle HorizontalAlign="Left" Width="35px" />
                    <HeaderStyle HorizontalAlign="Left" Width="35px" />
                </telerik:GridHyperLinkColumn>
                <telerik:GridBoundColumn UniqueName="RoleName" HeaderText="Role" DataField="RoleName">
                    <ItemStyle HorizontalAlign="Left" VerticalAlign="Top" />
                    <HeaderStyle HorizontalAlign="Left" />
                </telerik:GridBoundColumn>
                               <telerik:GridBoundColumn UniqueName="Description" HeaderText="Description" DataField="Description">
                    <ItemStyle HorizontalAlign="Left" VerticalAlign="Top" />
                    <HeaderStyle HorizontalAlign="Left" />
                </telerik:GridBoundColumn>
  
             </Columns>
        </MasterTableView>
    </telerik:RadGrid>
    <telerik:RadWindowManager ID="UserPopups" runat="server">
    </telerik:RadWindowManager>
    </form>

    <script type="text/javascript" language="javascript">


        function EditRole(id) {

            var oWnd = window.radopen("admin_user_role_edit.aspx?RoleID=" + id, "EditWindow");
            return false;
        }

        function GetRadWindow() {
            var oWindow = null;
            if (window.RadWindow) oWindow = window.RadWindow;
            else if (window.frameElement.radWindow) oWindow = window.frameElement.radWindow;
            return oWindow;
        }

   
    </script>

</body>
</html>
