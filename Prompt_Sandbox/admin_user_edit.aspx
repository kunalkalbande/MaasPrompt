<%@ Page Language="vb" %>

<%@ Register Assembly="Telerik.Web.UI" Namespace="Telerik.Web.UI" TagPrefix="telerik" %>
<%@ Import Namespace="Prompt" %>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">

<script runat="server">

    Private nUserID As Integer = 0
    Private bShowAllColleges As Boolean = False

    Private Sub Page_Load(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MyBase.Load

        ProcLib.CheckSession(Page)

        ProcLib.LoadPopupJscript(Page)

        Session("PageID") = "UserEdit"
        nUserID = Request.QueryString("UserID")
        
       
        If IsPostBack Then   'only do the following post back
            nUserID = lblID.Text
            
        Else  'only do the following on first load
             
            Using db As New promptUser
                db.CallingPage = Page

                db.GetUserForEdit(nUserID)   'loads existing record
                txtUserName.Focus()
                lblID.Text = nUserID
                
                If nUserID = 0 Then
                    lstDashboardID.SelectedValue = 12
                End If
               
            End Using
            
            
         
        End If
        
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
                .Behaviors = WindowBehaviors.Close + WindowBehaviors.Move
            End With
            .Windows.Add(ww)
            
    
        End With
        
        BuildMenu()
 

    End Sub

 

    Protected Sub butResetPassword_Click(ByVal sender As Object, ByVal e As System.EventArgs)
        'Sends the login ID a temporary password that they must change once they login in
        Using db As New promptUser
            db.CallingPage = Page
            lblMessage.Text = db.ResetPassword(txtLoginID.Text)
        End Using
    End Sub

    Protected Sub butResetPasswordDesignate_Click(ByVal sender As Object, ByVal e As System.EventArgs)
        'Resets password as designated and resets expire date - does not send email
        Using db As New promptUser
            db.CallingPage = Page
            db.ChangePasswordToDesignated(txtLoginID.Text, txtNewPwd.Text)
        End Using
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
            .NavigateUrl = "admin_users.aspx"
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
        
        If nUserID > 0 Then
            mm = New Telerik.Web.UI.RadMenuItem
            With mm
                .Text = "Delete"
                .Height = nTopLineHeight
                .Width = nTopMenuItemWidths
                .ImageUrl = "images/attachment_remove_small.gif"
            End With
            RadMenu1.Items.Add(mm)

        End If
 
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
 
        If Item.Text = "Save" Then

            Dim sMessage As String = ""
            If Trim(txtUserName.Text) = "" Or Trim(txtLoginID.Text) = "" Then
                sMessage = "User Name and LogonID are required."
            Else
                
                Using db As New PromptDataHelper
                    'Takes data from the form and writes it to the database
                    Dim message As String = ""
                    Dim sql As String = ""
 
                    If nUserID = 0 Then      'new record 

                        'check to see that the loginID does not already exist
                        sql = "SELECT COUNT(UserID) FROM Users WHERE LoginID = '" & txtLoginID.Text & "'"
                        Dim result As Integer = db.ExecuteScalar(sql)
                        If result <> 0 Then   'already there so bail
                            message = "Sorry, that Login ID is already being used. Please use another."
                            lblMessage.Text = sMessage
                            Exit Sub
                        
                        Else
                            sql = "INSERT INTO Users "
                            sql &= "(ClientID,PasswordExpiresOn,Password)"
                            sql &= "VALUES (1,'" & Now() & "','maUbi2020') "      'client ID forced to 1
                            sql &= "SELECT CAST(SCOPE_IDENTITY() AS int) AS ID"

                            nUserID = db.ExecuteScalar(sql)
                            
                            
                        End If
                        
                        'set initial password
                        Dim sNewEncPwd As String = ProcLib.EncryptString("maUbi2020" & txtLoginID.Text) 'Encrypt and salt with login ID

                        'Write new password to database and reset the PasswordExpireDate for the user
                        sql = "UPDATE Users SET EncryptedPassword = '" & sNewEncPwd & "',"
                        sql &= "Password = '" & "maUbi2020" & "',"     'NOTE: Testing only to log temp password
                        sql &= "PasswordExpiresOn = '" & DateAdd(DateInterval.Day, 60, Now()) & "',"       'pwds expire every 60 days
                        sql &= "LastUpdateBy = '" & Session("UserName") & "',"
                        sql &= "LastUpdateOn = '" & Now() & "' "
                        sql &= "WHERE UserID = '" & nUserID & "'"
                        db.ExecuteNonQuery(sql)
                        
                        
            End If

                    sql = "SELECT * FROM Users WHERE UserID = " & nUserID
                    'pass the form and sql to fill routine
                    db.SaveForm(Form1, sql)

                    lblMessage.Text = "User Saved!"
                
                End Using

            End If
   
        End If
        
        If Item.Text = "Delete" Then
            Using db As New promptUser
                db.CallingPage = Page
                db.DeleteUser(nUserID)
            End Using
            
            Response.Redirect("admin_users.aspx")

        End If
        
    End Sub

    Protected Sub chkHideUnassignedColleges_CheckedChanged(ByVal sender As Object, ByVal e As System.EventArgs)

        If chkHideUnassignedColleges.Checked = True Then
            bShowAllColleges = False
        Else
            bShowAllColleges = True
        End If
        
        RadGrid1.Rebind()
        
    End Sub
    
    
          
    Protected Sub RadGrid1_NeedDataSource(ByVal source As Object, ByVal e As Telerik.Web.UI.GridNeedDataSourceEventArgs) Handles RadGrid1.NeedDataSource
        'loads the grid whenever it needs data (sorting, rebinding, etc...)
        Using db As New EISSecurity
            RadGrid1.DataSource = db.GetUserCollegeAccessList(nUserID, bShowAllColleges)
        End Using
        
        'Dim bShowProjectLevelPermissions As Boolean = False
        'For Each item As GridItem In RadGrid1.MasterTableView.Items
        '    If TypeOf item Is GridDataItem Then
        '        Dim nProjectPermissions As Integer = item.OwnerTableView.DataKeyValues(item.ItemIndex)("ProjectPermissions")
        '        If nProjectPermissions > 0 Then
        '            bShowProjectLevelPermissions = True
        '        End If
        '    End If
        'Next
        'If Not bShowProjectLevelPermissions Then
        '    RadGrid1.MasterTableView.ExpandCollapseColumn.Visible = False
        'Else
        '    RadGrid1.MasterTableView.ExpandCollapseColumn.Visible = True
        'End If

    End Sub
    
    Private Sub RadGrid1_DetailTableDataBind(ByVal source As Object, ByVal e As Telerik.Web.UI.GridDetailTableDataBindEventArgs) Handles RadGrid1.DetailTableDataBind
       
 
        Dim ParentDataItem As GridDataItem = CType(e.DetailTableView.ParentItem, GridDataItem)
        Dim nPermissions As Integer = ParentDataItem.OwnerTableView.DataKeyValues(ParentDataItem.ItemIndex)("Permissions")
        Dim nProjectPermissions As Integer = ParentDataItem.OwnerTableView.DataKeyValues(ParentDataItem.ItemIndex)("ProjectPermissions")
        Dim nCollegeID As Integer = ParentDataItem.GetDataKeyValue("CollegeID")
        'Dim nUserID As Integer = ParentDataItem.GetDataKeyValue("UserID")
        
        If (e.DetailTableView.DataMember = "Projects") Then
            If nProjectPermissions > 0 Then
                Using db As New EISSecurity
                    e.DetailTableView.DataSource = db.GetUserProjectAccessList(nCollegeID, nUserID)
                End Using
            End If

        End If

         
  
    End Sub

    Protected Sub RadGrid1_ItemCreated(ByVal sender As Object, ByVal e As Telerik.Web.UI.GridItemEventArgs) Handles RadGrid1.ItemCreated
        'This event allows us to customize the cell contents - fired before databound
        
        If (TypeOf e.Item Is GridDataItem) Then
            If e.Item.OwnerTableView.DataMember = "Colleges" Then
                Dim item As GridDataItem = CType(e.Item, GridDataItem)
                Dim nCollegeID As Integer = item.OwnerTableView.DataKeyValues(item.ItemIndex)("CollegeID")
                Dim nDistrictID As Integer = item.OwnerTableView.DataKeyValues(item.ItemIndex)("DistrictID")
            
                Dim linkButton As HyperLink = CType(item("Rights").Controls(0), HyperLink)
                linkButton.ToolTip = "Edit permissions for selected College."
                linkButton.NavigateUrl = "admin_user_edit_permissions.aspx?DistrictID=" & nDistrictID & "&CollegeID=" & nCollegeID & "&UserID=" & nUserID & "&ProjectID=0"
                linkButton.ImageUrl = "images/edit.png"
            End If
            
            If e.Item.OwnerTableView.DataMember = "Projects" Then
                Dim item As GridDataItem = CType(e.Item, GridDataItem)
                Dim nCollegeID As Integer = item.OwnerTableView.DataKeyValues(item.ItemIndex)("CollegeID")
                Dim nProjectID As Integer = item.OwnerTableView.DataKeyValues(item.ItemIndex)("ProjectID")
                Dim nDistrictID As Integer = item.OwnerTableView.DataKeyValues(item.ItemIndex)("DistrictID")
            
                Dim linkButton As HyperLink = CType(item("ProjectRights").Controls(0), HyperLink)
                linkButton.ToolTip = "Edit permissions for selected Project."
                linkButton.NavigateUrl = "admin_user_edit_permissions.aspx?DistrictID=" & nDistrictID & "&CollegeID=" & nCollegeID & "&UserID=" & nUserID & "&ProjectID=" & nProjectID
                linkButton.ImageUrl = "images/edit.png"
            End If
        End If
    End Sub

    Private Sub RadGrid1_ItemDataBound(ByVal sender As Object, ByVal e As Telerik.Web.UI.GridItemEventArgs) Handles RadGrid1.ItemDataBound
        If TypeOf e.Item Is GridDataItem Then
            If e.Item.OwnerTableView.DataMember = "Colleges" Then
                Dim item As GridDataItem = e.Item
                Dim nPermissions As Integer = item.OwnerTableView.DataKeyValues(item.ItemIndex)("Permissions")
                Dim nProjectPermissions As Integer = item.OwnerTableView.DataKeyValues(item.ItemIndex)("ProjectPermissions")
                Dim nDistrictID As Integer = item.OwnerTableView.DataKeyValues(item.ItemIndex)("DistrictID")
                Dim nCollegeID As Integer = item.OwnerTableView.DataKeyValues(item.ItemIndex)("CollegeID")
                Dim EditLink As HyperLink = CType(item("Rights").Controls(0), HyperLink)

                If nPermissions > 0 Then
                    item.BackColor = Color.LightGreen
                    item.Font.Bold = True
                End If

                If nUserID = 0 Then '' new user so no rights until saved
                    EditLink.Visible = False
                End If
                
                If nProjectPermissions > 0 Then  'show the heierachy link to projects otherwise hide
                    item("AssignProjectRights").Text = "Yes"
                Else
                    Dim cell As TableCell = item("ExpandColumn")
                    cell.Controls(0).Visible = False
                End If

            End If

            If e.Item.OwnerTableView.DataMember = "Projects" Then
                Dim item As GridDataItem = e.Item
                Dim nPermissions As Integer = item.OwnerTableView.DataKeyValues(item.ItemIndex)("Permissions")
                Dim nProjectID As Integer = item.OwnerTableView.DataKeyValues(item.ItemIndex)("ProjectID")
                Dim nCollegeID As Integer = item.OwnerTableView.DataKeyValues(item.ItemIndex)("CollegeID")
                Dim EditLink As HyperLink = CType(item("ProjectRights").Controls(0), HyperLink)

                If nPermissions > 0 Then
                    item.BackColor = Color.LightSkyBlue
                    item.Font.Bold = True
                End If

            End If
        End If
    End Sub
    
  
 
</script>

<html>
<head>
    <title>Edit User</title>
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
    <telerik:RadMenu ID="RadMenu1" runat="server" DefaultGroupSettings-Flow="Horizontal"
        Skin="Vista">
        <DefaultGroupSettings Flow="Horizontal"></DefaultGroupSettings>
    </telerik:RadMenu>
    <br />
    <br />
    <asp:TextBox ID="txtNewPwd" Style="z-index: 100; left: 125px; position: absolute;
        top: 140px; width: 91px;" runat="server" EnableViewState="False" CssClass="EditDataDisplay"></asp:TextBox>
    <asp:TextBox ID="txtUserName" Style="z-index: 100; left: 88px; position: absolute;
        top: 72px" runat="server" EnableViewState="False" Width="168px" CssClass="EditDataDisplay"></asp:TextBox>
    <asp:Label ID="lblID" Style="z-index: 102; left: 40px; position: absolute; top: 48px"
        runat="server" Height="8px" TabIndex="77">999</asp:Label>
    <asp:Label ID="Label2" Style="z-index: 103; left: 16px; position: absolute; top: 48px"
        runat="server" EnableViewState="False" Height="8px" CssClass="FieldLabel">ID:</asp:Label>
    <asp:TextBox ID="txtLoginID" Style="z-index: 108; left: 118px; position: absolute;
        top: 103px; width: 224px;" runat="server" EnableViewState="False" TabIndex="1"
        CssClass="EditDataDisplay"></asp:TextBox>
    <asp:Label ID="Label7" Style="z-index: 109; left: 16px; position: absolute; top: 72px"
        runat="server" EnableViewState="False" CssClass="FieldLabel">User Name:</asp:Label>
    <asp:Label ID="Label6" Style="z-index: 110; left: 16px; position: absolute; top: 104px"
        runat="server" EnableViewState="False" CssClass="FieldLabel">Logon ID (email):</asp:Label>
    <asp:Label ID="lblMessage" Style="z-index: 116; left: 166px; position: absolute;
        top: 51px; height: 12px;" runat="server" EnableViewState="False" CssClass="FieldLabel"
        TabIndex="99" Font-Bold="True" ForeColor="Red"></asp:Label>
    &nbsp;&nbsp;
    <asp:DropDownList ID="lstDashboardID" Style="z-index: 118; left: 462px; position: absolute;
        top: 105px; height: 19px; width: 147px;" runat="server" TabIndex="3" CssClass="EditDataDisplay">
    </asp:DropDownList>
    <asp:DropDownList ID="lstUserRoleID" Style="z-index: 118; left: 325px; position: absolute;
        top: 71px; height: 19px; width: 159px;" runat="server" TabIndex="3" CssClass="EditDataDisplay">
    </asp:DropDownList>
    <telerik:RadGrid ID="RadGrid1" Style="z-index: 500; left: 10px; position: absolute;
        top: 231px;" runat="server" AllowSorting="true" Height="50%" AutoGenerateColumns="False"
        GridLines="None" Width="98%" EnableAJAX="True" Skin="Sitefinity">
        <ClientSettings>
            <Selecting AllowRowSelect="True" />
            <Scrolling AllowScroll="True" UseStaticHeaders="True" ScrollHeight="50%" SaveScrollPosition="true" />
        </ClientSettings>
        <MasterTableView Width="100%" GridLines="None" DataKeyNames="Permissions,DistrictID,CollegeID,ProjectPermissions"
            NoMasterRecordsText="No Districts/Colleges Found." DataMember="Colleges"  HierarchyLoadMode="ServerBind" >
            <DetailTables>
                <telerik:GridTableView DataKeyNames="Permissions,ProjectID,CollegeID,DistrictID"
                    Width="100%" runat="server" Name="Projects" DataMember="Projects" NoDetailRecordsText="No Projects Found."
                    ShowHeadersWhenNoRecords="true">
                    <Columns>
                        <telerik:GridHyperLinkColumn UniqueName="ProjectRights">
                            <ItemStyle Width="35px" HorizontalAlign="Center" VerticalAlign="Top" />
                            <HeaderStyle Width="35px" HorizontalAlign="Center" />
                        </telerik:GridHyperLinkColumn>
                        <telerik:GridBoundColumn DataField="ProjectName" UniqueName="ProjectName" HeaderText="Project">
                            <ItemStyle HorizontalAlign="Left" VerticalAlign="Top" />
                            <HeaderStyle HorizontalAlign="Left" />
                        </telerik:GridBoundColumn>
                        <telerik:GridBoundColumn DataField="ProjectNumber" UniqueName="ProjectNumber" HeaderText="Project Number">
                            <ItemStyle HorizontalAlign="Left" VerticalAlign="Top" />
                            <HeaderStyle HorizontalAlign="Left" />
                        </telerik:GridBoundColumn>
                                             <telerik:GridBoundColumn DataField="Status" UniqueName="Status" HeaderText="Project Status">
                            <ItemStyle HorizontalAlign="Left" VerticalAlign="Top" />
                            <HeaderStyle HorizontalAlign="Left" />
                        </telerik:GridBoundColumn>
                    </Columns>
                </telerik:GridTableView>
            </DetailTables>
            <Columns>
                <telerik:GridHyperLinkColumn UniqueName="Rights" HeaderText="Rights">
                    <ItemStyle HorizontalAlign="Center" Width="65px" />
                    <HeaderStyle HorizontalAlign="Center" Width="65px" />
                </telerik:GridHyperLinkColumn>
                <telerik:GridBoundColumn UniqueName="District" HeaderText="District" DataField="District">
                    <ItemStyle HorizontalAlign="Left" VerticalAlign="Top" />
                    <HeaderStyle HorizontalAlign="Left" />
                </telerik:GridBoundColumn>
                <telerik:GridBoundColumn UniqueName="College" HeaderText="College" DataField="College">
                    <ItemStyle HorizontalAlign="Left" VerticalAlign="Top" />
                    <HeaderStyle HorizontalAlign="Left" />
                </telerik:GridBoundColumn>
                <telerik:GridBoundColumn UniqueName="AssignProjectRights" HeaderText="Specify Projects?"
                    DataField="AssignProjectRights">
                    <ItemStyle HorizontalAlign="Left" VerticalAlign="Top" />
                    <HeaderStyle HorizontalAlign="Left" />
                </telerik:GridBoundColumn>
            </Columns>
        </MasterTableView>
    </telerik:RadGrid>
    <asp:CheckBox ID="chkAccountDisabled" runat="server" Style="z-index: 122; left: 527px;
        position: absolute; top: 73px" Text=" Account Disabled" ToolTip="Disable the account" />
    <asp:CheckBox ID="chkHideUnassignedColleges" runat="server" Style="z-index: 122;
        left: 441px; position: absolute; top: 176px" Text="Display Assigned Colleges Only"
        ToolTip="Check if this user will use dashboards and participate in Workflow"
        Checked="True" OnCheckedChanged="chkHideUnassignedColleges_CheckedChanged" AutoPostBack="True" />
    <asp:CheckBox ID="chkIsPM" runat="server" Style="z-index: 122;
        left: 14px; position: absolute; top: 180px; " Text=" Is PM?"
        ToolTip="Check if this user is a Project Manager" />
    <asp:CheckBox ID="chkSuppressWorkflowNotification" runat="server" Style="z-index: 122;
        left: 251px; position: absolute; top: 180px" Text="Suppress Workflow Notify"
        
        
        ToolTip="Check if this user will use dashboards and participate in Workflow" />
    <asp:CheckBox ID="chkIsWorkflowUser" runat="server" Style="z-index: 122; left: 108px;
        position: absolute; top: 181px" Text="Is Workflow User" 
        ToolTip="Check if this user will use dashboards and participate in Workflow" />
    <asp:Button ID="butResetPassword" Style="z-index: 121; left: 266px; position: absolute;
        top: 141px; height: 21px; width: 174px; right: 1167px;" runat="server" Text="Send User New Password"
        OnClick="butResetPassword_Click" ToolTip="Sends user a random password that they must change at next login." />
    <asp:Button ID="butResetPasswordDesignate" Style="z-index: 121; left: 17px; position: absolute;
        top: 142px; height: 21px; width: 94px;" runat="server" Text="Set Password:" ToolTip="Sets user password as designated and resets expire date - does not send email."
        OnClick="butResetPasswordDesignate_Click" />
    <telerik:RadWindowManager ID="UserPopups" runat="server">
    </telerik:RadWindowManager>
    <asp:Label ID="lblxSecurityLevel" Style="z-index: 112; left: 10px; position: absolute;
        top: 218px" runat="server" EnableViewState="False" CssClass="FieldLabel">Access and Permissions: (Save new user before assigning rights)</asp:Label>
    <p>
        <asp:Label ID="Label10" runat="server" CssClass="FieldLabel" EnableViewState="False"
            Style="z-index: 113; left: 286px; position: absolute; top: 72px; height: 15px;
            right: 1295px;">Role:</asp:Label>
    </p>
    <asp:Label ID="Label4" runat="server" CssClass="FieldLabel" EnableViewState="False"
        Style="z-index: 113; left: 382px; position: absolute; top: 106px; height: 16px;">Landing Page:</asp:Label>
    </form>
</body>
</html>
