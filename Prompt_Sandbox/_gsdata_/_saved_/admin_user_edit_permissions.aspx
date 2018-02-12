<%@ Page Language="vb" %>

<%@ Register Assembly="Telerik.Web.UI" Namespace="Telerik.Web.UI" TagPrefix="telerik" %>
<%@ Import Namespace="Prompt" %>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">

<script runat="server">

    
    Private nDistrictID As Integer = 0
    Private nCollegeID As Integer = 0
    Private nUserID As Integer = 0
    Private nProjectID As Integer = 0


    Private Sub Page_Load(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MyBase.Load
        ProcLib.CheckSession(Page)
        ProcLib.LoadPopupJscript(Page)

        Session("PageID") = "AdminEditUserPermissions"
        
        nCollegeID = Request.QueryString("CollegeID")
        nDistrictID = Request.QueryString("DistrictID")
        nUserID = Request.QueryString("UserID")
        nProjectID = Request.QueryString("ProjectID")
        
        'If Request.Browser.Browser = "IE" Then
        RadGrid1.Height = Unit.Pixel(700)
        'End If
 
         
        BuildMenu()
        
        
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
        RadGrid1.MasterTableView.GroupsDefaultExpanded = True
        
        If nProjectID = 0 Then
            butResetPermissions.Text = "Reset To User Role"
        Else
            butResetPermissions.Text = "Reset To Parent College"
        End If
        
   
    End Sub
    
    Private Sub BuildMenu()
        RadMenu1.Width = Unit.Percentage(100)

        Dim nTopLineHeight As Unit = Unit.Pixel(27)
        Dim nTopMenuItemWidths As Unit = Unit.Pixel(75)

        With RadMenu1
            .Items.Clear()
        End With
        Dim mm As Telerik.Web.UI.RadMenuItem

        '**********************************************
        mm = New Telerik.Web.UI.RadMenuItem
        With mm
            .Height = nTopLineHeight
            .Text = "Back"
            .NavigateUrl = "admin_user_edit.aspx?UserID=" & nUserID
            .ImageUrl = "images/arrow_left_green.png"
            .Width = nTopMenuItemWidths
        End With
        RadMenu1.Items.Add(mm)
        

        mm = New Telerik.Web.UI.RadMenuItem
        With mm
            .Text = "Save"
            .Height = nTopLineHeight
            .Width = nTopMenuItemWidths
            .ImageUrl = "images/prompt_savetodisk.gif"
        End With
        RadMenu1.Items.Add(mm)
        
        mm = New Telerik.Web.UI.RadMenuItem
        With mm
            .Text = "Exit"
            .Height = nTopLineHeight
            .Width = nTopMenuItemWidths
            .ImageUrl = "images/exit.png"
        End With
        RadMenu1.Items.Add(mm)

        mm = New Telerik.Web.UI.RadMenuItem
        With mm
            .Text = "Help"
            .ImageUrl = "images/help.png"
            .Attributes("onclick") = "openPopup('help_view.aspx','pophelp',550,450,'yes');"
            .PostBack = False
            .Height = nTopLineHeight
            .Width = nTopMenuItemWidths
        End With
        RadMenu1.Items.Add(mm)


    End Sub

      
    Protected Sub RadMenu1_ItemClick(ByVal sender As Object, ByVal e As Telerik.Web.UI.RadMenuEventArgs) Handles RadMenu1.ItemClick
        Dim Item As Telerik.Web.UI.RadMenuItem = e.Item
        If Item.Text = "Exit" Then
            ProcLib.CloseOnlyRAD(Page)
        End If
        If Item.Text = "Save" Then
            
            Using db As New EISSecurity
                db.CallingPage = Page
                db.SaveUserPermissions(RadGrid1, nDistrictID, nCollegeID, nUserID, nProjectID)
            End Using
            
            RadGrid1.Rebind()
                
        End If

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
            RadGrid1.DataSource = db.GetUserPermissionsForEdit(nUserID, nDistrictID, nCollegeID, nProjectID)
            lblTitle.Text = db.GetDistrictCollegeProjectName(nCollegeID, nProjectID)
        End Using
        

    End Sub

    

    Private Sub RadGrid1_ItemDataBound(ByVal sender As Object, ByVal e As Telerik.Web.UI.GridItemEventArgs) Handles RadGrid1.ItemDataBound
        
        If TypeOf e.Item Is GridDataItem Then
            Dim dataitem As GridDataItem = e.Item

            Dim sPermissions As String = ProcLib.CheckNullDBField(dataitem.OwnerTableView.DataKeyValues(dataitem.ItemIndex)("Permissions"))
            Dim sObjectID As String = dataitem.OwnerTableView.DataKeyValues(dataitem.ItemIndex)("ObjectID")
            Dim lstRights As DropDownList = dataitem.FindControl("lstRights")
 
            If sObjectID = "SpecifyProjectAccess" Then
                lstRights.Items.Clear()
                lstRights.Items.Add("No")
                lstRights.Items.Add("Yes")
            Else
                lstRights.Items.Clear()
                lstRights.Items.Add("none")
                lstRights.Items.Add("ReadOnly")
                lstRights.Items.Add("Write")
            End If
            
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



    Protected Sub butResetPermissions_Click(ByVal sender As Object, ByVal e As System.EventArgs)
        
        Using db As New EISSecurity
            If nProjectID = 0 Then
                db.ResetUserToRolePermissions(nUserID, nDistrictID, nCollegeID)
            Else
                db.ResetUserProjectToParentCollegePermissions(nUserID, nDistrictID, nCollegeID, nProjectID)
            End If
            
        End Using
        RadGrid1.Rebind()

    End Sub
    
    Protected Sub butExpandCollapse_Click(ByVal sender As Object, ByVal e As System.EventArgs)
        If butExpandCollapse.Text = "Expand All" Then
            RadGrid1.MasterTableView.GroupsDefaultExpanded = True
            butExpandCollapse.Text = "Collapse All"
        Else
            RadGrid1.MasterTableView.GroupsDefaultExpanded = False
            butExpandCollapse.Text = "Expand All"
        End If
    
        RadGrid1.Rebind()

    End Sub
    
    
</script>

<html>
<head>
    <title>Edit User Permissions</title>
    <link href="Styles.css" type="text/css" rel="stylesheet" />

    <script type="text/javascript" language="javascript">


        function GetRadWindow() {
            var oWindow = null;
            if (window.radWindow) oWindow = window.radWindow; //Will work in Moz in all cases, including clasic dialog
            else if (window.frameElement.radWindow) oWindow = window.frameElement.radWindow; //IE (and Moz az well)

            return oWindow;
        }

 	   
    </script>

</head>
<body>
    <form id="Form1" method="post" runat="server">
    <telerik:RadScriptManager ID="RadScriptManager1" runat="server" />
    <telerik:RadMenu ID="RadMenu1" runat="server" DefaultGroupSettings-Flow="Horizontal"
        Skin="Vista">
        <DefaultGroupSettings Flow="Horizontal"></DefaultGroupSettings>
    </telerik:RadMenu>
    <br />
    <br />

    <asp:Label ID="lblTitle" runat="server" Font-Bold="True" Font-Size="Larger" Text="Object Name Here"></asp:Label>
    &nbsp;&nbsp;&nbsp;&nbsp;&nbsp; &nbsp;&nbsp;&nbsp;
    <asp:Button ID="butResetPermissions" runat="server" Text="Reset To User Role Permissions"
        OnClick="butResetPermissions_Click" />
        
        &nbsp;&nbsp;&nbsp;&nbsp;&nbsp; &nbsp;&nbsp;&nbsp;
    <asp:Button ID="butExpandCollapse" runat="server" Text="Collapse All"
        OnClick="butExpandCollapse_Click" />
        
    <br />
    <telerik:RadGrid ID="RadGrid1" runat="server" AllowSorting="true" AutoGenerateColumns="False"
        GridLines="None" Width="98%" Height="80%" EnableAJAX="True" Skin="Sitefinity">
        <ClientSettings>
            <Selecting AllowRowSelect="True" />
            <Scrolling AllowScroll="True" UseStaticHeaders="True" ScrollHeight="50%" SaveScrollPosition="true" />
        </ClientSettings>
        <MasterTableView Width="100%" GridLines="None" DataKeyNames="ObjectID,ObjectType,UserID,Category,ScopeLevel,Permissions"
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
                            <asp:ListItem Value="None">--none--</asp:ListItem>
                            <asp:ListItem Value="ReadOnly">Read Only</asp:ListItem>
                            <asp:ListItem Value="ReadWrite">Write</asp:ListItem>
                        </asp:DropDownList>
                    </ItemTemplate>
                </telerik:GridTemplateColumn>
            </Columns>
        </MasterTableView>
    </telerik:RadGrid>
    </form>
</body>
</html>
