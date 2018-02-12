<%@ Page Language="vb" %>

<%@ Register Assembly="Telerik.Web.UI" Namespace="Telerik.Web.UI" TagPrefix="telerik" %>
<%@ Import Namespace="Prompt" %>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">

<script runat="server">

    Private nRoleID As Integer = 0

    Private Sub Page_Load(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MyBase.Load

        ProcLib.CheckSession(Page)
        ProcLib.LoadPopupJscript(Page)

        'set up help button
        Session("PageID") = "UserRoleEdit"
        butHelp.Attributes.Add("onclick", "openPopup('help_view.aspx','pophelp',550,450,'yes');")
        butHelp.NavigateUrl = "#"

        nRoleID = Request.QueryString("RoleID")
        
        ''keep these un editable for now as they are hard coded to users at present
        'txtRoleName.Enabled = True
        'txtDescription.Enabled = False
        
 
        If IsPostBack Then   'only do the following post back
            nRoleID = lblID.Text
            
        Else  'only do the following on first load
             
            Using db As New promptUser
                db.CallingPage = Page
 
                If nRoleID = 0 Then    'load new record 
                    butDelete.Visible = False           'new record so hide delete button
                End If
                db.GetRoleForEdit(nRoleID)   'loads existing record
                txtRoleName.Focus()
                lblID.Text = nRoleID
               
            End Using
            
            
         
        End If
        
        butDelete.Visible = False   'for now no delete
        
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
        
        'Set group by Spec Package
        Dim expression As GridGroupByExpression = New GridGroupByExpression
        Dim gridGroupByField As GridGroupByField = New GridGroupByField
        RadGrid1.MasterTableView.GroupByExpressions.Clear()
        'Add select fields (before the "Group By" clause)
        gridGroupByField = New GridGroupByField
        gridGroupByField.FieldName = "Category"
        gridGroupByField.HeaderText = " "
        gridGroupByField.HeaderValueSeparator = " "
        expression.SelectFields.Add(gridGroupByField)

        'Add a field for group-by (after the "Group By" clause)
        gridGroupByField = New GridGroupByField
        gridGroupByField.FieldName = "Category"
        expression.GroupByFields.Add(gridGroupByField)

        RadGrid1.MasterTableView.GroupByExpressions.Add(expression)
        

    End Sub

    Private Sub butSave_Click(ByVal sender As System.Object, ByVal e As System.Web.UI.ImageClickEventArgs) Handles butSave.Click
        
        Dim sMessage As String = ""
        If txtRoleName.Text <> "" Then
            Using db As New promptUser
                db.CallingPage = Page
                sMessage = db.SaveRole(nRoleID)
            End Using
        Else
            sMessage = "You must have a Role Name"
        End If
        If sMessage = "" Then
            ProcLib.CloseAndRefreshRAD(Page)
        Else
            lblMessage.Text = sMessage
        End If
        
    End Sub

    Private Sub butDelete_Click(ByVal sender As System.Object, ByVal e As System.Web.UI.ImageClickEventArgs) Handles butDelete.Click
        'Using db As New promptUser
        '    db.CallingPage = Page
        '    db.DeleteUserRole(nRoleID)
        'End Using
        'ProcLib.CloseAndRefresh(Page)
    End Sub

    
      
    Protected Sub RadGrid1_ItemCreated(ByVal sender As Object, ByVal e As Telerik.Web.UI.GridItemEventArgs) Handles RadGrid1.ItemCreated
        'This event allows us to customize the cell contents - fired before databound
        
        'If (TypeOf e.Item Is GridDataItem) Then
        '    Dim item As GridDataItem = CType(e.Item, GridDataItem)
        '    Dim nObjectID As Integer = item.OwnerTableView.DataKeyValues(item.ItemIndex)("ObjectID")

        '    'Dim linkButton As HyperLink = CType(item("Rights").Controls(0), HyperLink)
        '    ''linkButton.Attributes("onclick") = "return EditPermissions(" & nObjectID & ");"
        '    'linkButton.ToolTip = "Edit permissions for selected College/Project."
        '    'linkButton.NavigateUrl = "admin_user_edit_permissions.aspx?ObjectID=" & nObjectID & "&UserID=" & nUserID
        '    'linkButton.ImageUrl = "images/edit.gif"


        'End If
    End Sub
    
          
    Protected Sub RadGrid1_NeedDataSource(ByVal source As Object, ByVal e As Telerik.Web.UI.GridNeedDataSourceEventArgs) Handles RadGrid1.NeedDataSource
        'loads the grid whenever it needs data (sorting, rebinding, etc...)
        Using db As New EISSecurity
            RadGrid1.DataSource = db.GetRolePermissionsForEdit(nRoleID)
        End Using
        

    End Sub

    

    Private Sub RadGrid1_ItemDataBound(ByVal sender As Object, ByVal e As Telerik.Web.UI.GridItemEventArgs) Handles RadGrid1.ItemDataBound
        
        If TypeOf e.Item Is GridDataItem Then
            Dim dataitem As GridDataItem = e.Item

            Dim sPermissions As String = dataitem.OwnerTableView.DataKeyValues(dataitem.ItemIndex)("Permissions")
            Dim sObjectID As String = dataitem.OwnerTableView.DataKeyValues(dataitem.ItemIndex)("ObjectID")
            Dim lstRights As DropDownList = dataitem.FindControl("lstRights")
 
                 
            For Each item As ListItem In lstRights.Items
                If item.Value = sPermissions Then
                    item.Selected = True
                End If
            Next
            
            If lstRights.SelectedValue = "Yes" Or lstRights.SelectedValue = "Write" Then
                lstRights.BackColor = Color.LightGreen
                dataitem.BackColor = Color.LightYellow
                dataitem.Font.Bold = True
            End If
            If lstRights.SelectedValue = "ReadOnly" Then
                dataitem.BackColor = Color.LightYellow
                lstRights.BackColor = Color.LightSalmon
                dataitem.Font.Bold = True
            End If
            
   
        End If

    End Sub
    
    
    Protected Sub butResetUserRolePermissions_Click(ByVal sender As Object, ByVal e As System.EventArgs)
        
        Using db As New EISSecurity
            db.ResetAllUserRolePermissions(nRoleID)
        End Using

    End Sub

 
</script>

<html>
<head>
    <title>Edit User Role</title>
    <meta content="Microsoft Visual Studio .NET 7.1" name="GENERATOR" />
    <link href="Styles.css" type="text/css" rel="stylesheet" />

    <script type="text/javascript" language="javascript">


        function GetRadWindow() {
            var oWindow = null;
            if (window.RadWindow) oWindow = window.RadWindow;
            else if (window.frameElement.radWindow) oWindow = window.frameElement.radWindow;
            return oWindow;
        }

 

    </script>

</head>
<body>
    <form id="Form1" method="post" runat="server">
    <telerik:RadScriptManager ID="RadScriptManager1" runat="server" />
    <asp:TextBox ID="txtDescription" Style="z-index: 100; left: 299px; position: absolute;
        top: 72px; width: 273px;" runat="server" EnableViewState="False" 
        CssClass="EditDataDisplay"></asp:TextBox>
    <asp:TextBox ID="txtRoleName" Style="z-index: 100; left: 50px; position: absolute;
        top: 72px" runat="server" EnableViewState="False" Width="168px" 
        CssClass="EditDataDisplay"></asp:TextBox>
    <asp:ImageButton ID="butDelete" Style="z-index: 101; left: 568px; position: absolute;
        top: 499px" runat="server" ImageUrl="images/button_delete.gif" 
        TabIndex="41">
    </asp:ImageButton>
    <asp:Label ID="lblID" Style="z-index: 102; left: 40px; position: absolute; top: 48px"
        runat="server" Height="8px" TabIndex="77">999</asp:Label>
    <asp:Label ID="Label2" Style="z-index: 103; left: 16px; position: absolute; top: 48px"
        runat="server" EnableViewState="False" Height="8px" CssClass="FieldLabel">ID:</asp:Label>
    <asp:Label ID="Label10" Style="z-index: 109; left: 238px; position: absolute; top: 73px"
        runat="server" EnableViewState="False" CssClass="FieldLabel">Description:</asp:Label>
    <asp:Label ID="Label7" Style="z-index: 109; left: 16px; position: absolute; top: 72px"
        runat="server" EnableViewState="False" CssClass="FieldLabel">Role:</asp:Label>
  <asp:Label ID="Label9" runat="server" CssClass="FieldLabel" EnableViewState="False"
        
        
        Style="z-index: 113; left: 15px; position: absolute; top: 103px; height: 16px;">Permissions:</asp:Label>
    <asp:Label ID="lblMessage" Style="z-index: 116; left: 16px; position: absolute; top: 531px;
        height: 15px;" runat="server" EnableViewState="False" 
        CssClass="FieldLabel" TabIndex="99"
        Font-Bold="True" ForeColor="Red"></asp:Label>
    <table id="Table1" style="z-index: 123; left: 16px; position: absolute; top: 8px;
        height: 2px" cellspacing="1" cellpadding="1" border="0" width="96%">
        <tr>
            <td valign="top" style="height: 6px">
                <asp:Label ID="Label8" runat="server" Width="88px" CssClass="PageHeading" Height="24px"
                    EnableViewState="False" TabIndex="99">Edit User Role</asp:Label>
            </td>
            <td align="right" valign="top" style="height: 6px">
                <asp:HyperLink ID="butHelp" runat="server" ImageUrl="images/button_help.gif" TabIndex="77">HyperLink</asp:HyperLink>
            </td>
        </tr>
        <tr>
            <td valign="top" colspan="2">
                <hr size="1" width="100%" />
            </td>
        </tr>
    </table>
    <telerik:RadGrid ID="RadGrid1" runat="server" AllowSorting="true" AutoGenerateColumns="False"
        Style="z-index: 112; left: 10px; position: absolute; top: 130px" GridLines="None"
        Width="98%" Height="350px" EnableAJAX="True" Skin="Sitefinity">
        <ClientSettings>
            <Selecting AllowRowSelect="True" />
            <Scrolling AllowScroll="True" UseStaticHeaders="True" ScrollHeight="50%" SaveScrollPosition="true" />
        </ClientSettings>
        <MasterTableView Width="100%" GridLines="None" DataKeyNames="ObjectID,ObjectType,Category,RoleID,Permissions"
            NoMasterRecordsText="No Permissions Found.">
            <Columns>

                <telerik:GridBoundColumn UniqueName="Description" HeaderText="Description" DataField="Description">
                    <ItemStyle HorizontalAlign="Left" VerticalAlign="Top" />
                    <HeaderStyle HorizontalAlign="Left" />
                </telerik:GridBoundColumn>

                
                <telerik:GridTemplateColumn UniqueName="Rights" HeaderText="">
                    <ItemStyle HorizontalAlign="Center" Width="175px" VerticalAlign="Top" />
                    <HeaderStyle HorizontalAlign="Center" Width="175px" VerticalAlign="Top" />
                    <ItemTemplate>
                        <asp:DropDownList ID="lstRights" runat="server">
                             <asp:ListItem Value="none">none</asp:ListItem>
                             <asp:ListItem Value="ReadOnly">Read Only</asp:ListItem>
                             <asp:ListItem Value="Write">Write</asp:ListItem>
                        </asp:DropDownList>
                    </ItemTemplate>
                </telerik:GridTemplateColumn>
            </Columns>
        </MasterTableView>
    </telerik:RadGrid>
    <asp:ImageButton ID="butSave" Style="z-index: 121; left: 17px; position: absolute;
        top: 499px" runat="server" ImageUrl="images/button_save.gif" TabIndex="40"></asp:ImageButton>
   
       <asp:Button ID="butResetUserRolePermissions" runat="server"  Style="z-index: 121; left: 198px; position: absolute;
        top: 498px"
         Text="Reset All Users Role Permissions" 
        onclick="butResetUserRolePermissions_Click" />
         
    </form>
    <telerik:RadWindowManager ID="UserPopups" runat="server">
    </telerik:RadWindowManager>
</body>
</html>
