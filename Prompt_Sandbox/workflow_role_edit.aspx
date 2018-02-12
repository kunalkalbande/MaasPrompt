<%@ Page Language="vb" %>

<%@ Register Assembly="Telerik.Web.UI" Namespace="Telerik.Web.UI" TagPrefix="telerik" %>
<%@ Import Namespace="Prompt" %>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">

<script runat="server">
   
    Private nWorkflowRoleID As Integer = 0
         
    Private Sub Page_Load(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MyBase.Load
        
        If ProcLib.CheckExpiredSessionForPopup(Page) Then    'session died so close the page - this is to prevent orphaned popups
            ProcLib.CloseOnlyRAD(Page)
        End If
        
        'set help info - note: no need for help button as one on page top will suffice here
        Session("PageID") = "WorkflowRoleEdit"
        
        lblMessage.Text = ""
        
        nWorkflowRoleID = Request.QueryString("WorkflowRoleID")
  
        If IsPostBack Then   'only do the following on post back or pass back
            nWorkflowRoleID = lblID.Text
        Else  'only do the following on first load
                
            Using db As New PromptDataHelper
                
                If nWorkflowRoleID = 0 Then    'load new record 
                    'new record so hide delete button
                    butDelete.Visible = False
                End If
                'db.GetWorkflowRoleForEdit(nWorkflowRoleID)   'loads existing record
 
                'Now get the available users for this district to assign to this role
                'this list only includes those users that have "IsWorkflowUser" checked in thier
                'user record and also are assigned to the current District.

                ''get list of currently assigned userIDs - we do not want to assign user to multiple roles
                'Dim sExclude As String = ""
                'Dim sql As String = "SELECT DISTINCT UserID FROM WorkflowRoles WHERE DistrictID = " & Session("DistrictID")
                'db.FillReader(sql)
                'While db.Reader.Read
                '    sExclude &= db.Reader("UserID") & ","
                'End While
                'db.Reader.Close()
                'If sExclude <> "" Then  'remove last ,
                '    sExclude = Left(sExclude, Len(sExclude) - 1)
                '    sql = "SELECT DISTINCT Users.UserID as val, Users.UserName as lbl FROM Users "
                '    sql &= "INNER JOIN SecurityPermissions ON Users.UserID = SecurityPermissions.UserID "
                '    sql &= "WHERE DistrictID = " & HttpContext.Current.Session("DistrictID") & " "
                '    sql &= " AND Users.IsWorkflowUser > 0  AND Users.UserID NOT IN(" & sExclude & ") ORDER BY Users.UserName "

                'Else
                '    sql = "SELECT Users.UserID as val, Users.UserName as lbl FROM Users "
                '    sql &= "INNER JOIN SecurityPermissions ON Users.UserID = SecurityPermissions.UserID "
                '    sql &= "WHERE DistrictID = " & HttpContext.Current.Session("DistrictID") & " "
                '    sql &= " AND Users.IsWorkflowUser > 0 ORDER BY Users.UserName "

                'End If
                
                Dim sql As String = ""
                sql = "SELECT DISTINCT Users.UserID as val, Users.UserName as lbl FROM Users "
                sql &= "INNER JOIN SecurityPermissions ON Users.UserID = SecurityPermissions.UserID "
                sql &= "WHERE DistrictID = " & HttpContext.Current.Session("DistrictID") & " "
                sql &= " AND Users.IsWorkflowUser > 0 ORDER BY Users.UserName "

                db.FillDropDown(sql, Form.FindControl("lstUserID"), True, True, False)

                'get record for edit
                If nWorkflowRoleID <> 0 Then
                    Dim row As DataRow = db.GetDataRow("SELECT * FROM WorkflowRoles WHERE WorkflowRoleID = " & nWorkflowRoleID)
                    db.FillForm(Form1, row)

                    ''now get the assigned person and add back to list
                    'Dim lst As DropDownList = Form.FindControl("lstUserID")
                    'sql = "SELECT Users.UserID as val, Users.UserName as lbl FROM Users WHERE UserID = " & row("UserID")
                    'db.FillReader(sql)
                    'While db.Reader.Read
                    '    Dim ii As New ListItem
                    '    ii.Text = db.Reader("lbl")
                    '    ii.Value = db.Reader("val")
                    '    ii.Selected = True
                    '    lst.Items.Add(ii)
                    'End While
                    'db.Reader.Close()

                End If
                
                txtWorkflowRole.Focus()
                lblID.Text = nWorkflowRoleID
               
            End Using
            'Store the old code value in the view state for retrival in validation
            ViewState.Add("OldRole", txtWorkflowRole.Text)   'save the original value to view state for later
        End If
    End Sub

    Private Sub butSave_Click(ByVal sender As System.Object, ByVal e As System.Web.UI.ImageClickEventArgs) Handles butSave.Click
        If trim(txtWorkflowRole.Text) <> "" Then
            Using db As New promptDataHelper
                Dim sql As String = ""
                'Takes data from the form and writes it to the database
                If nWorkflowRoleID = 0 Then      'new record
                    sql = "INSERT INTO WorkflowRoles "
                    sql &= "(DistrictID)"
                    sql &= "VALUES (" & Session("DistrictID") & ")"
                    sql &= "SELECT CAST(SCOPE_IDENTITY() AS int) AS ID"

                    nWorkflowRoleID = db.ExecuteScalar(sql)
                End If

                sql = "SELECT * FROM WorkflowRoles WHERE WorkflowRoleID = " & nWorkflowRoleID
                db.SaveForm(Form1, sql)

                'Update the target file with new description
                Dim sDesc As String = db.ExecuteScalar("SELECT WorkflowRole FROM WorkflowRoles WHERE WorkflowRoleID = " & nWorkflowRoleID)
                db.ExecuteNonQuery("UPDATE WorkflowSCenerioOwnerTargets SET TargetRoleName = '" & sDesc & "' WHERE TargetRoleID = " & nWorkflowRoleID)
            End Using
        End If
        ProcLib.CloseAndRefreshRADNoPrompt(Page)
    
    End Sub

    Private Sub butDelete_Click(ByVal sender As System.Object, ByVal e As System.Web.UI.ImageClickEventArgs) Handles butDelete.Click
        Using db As New PromptDataHelper
            'remove all the Owners this role is assigned to and related targets
            Dim sql As String = "SELECT * FROM WorkflowScenerioOwners WHERE WorkflowRoleID = " & nWorkflowRoleID
            Dim rs As DataTable = db.ExecuteDataTable(sql)
            For Each row As DataRow In rs.Rows
                sql = "DELETE FROM WorkflowScenerioOwnerTargets WHERE WorkflowScenerioOwnerID = " & row("WorkflowScenerioOwnerID")
                db.ExecuteNonQuery(sql)

                sql = "DELETE FROM WorkflowScenerioOwnerNotifyList WHERE WorkflowScenerioOwnerID = " & row("WorkflowScenerioOwnerID")
                db.ExecuteNonQuery(sql)
            Next

            sql = "DELETE FROM WorkflowScenerioOwners WHERE WorkflowRoleID = " & nWorkflowRoleID
            db.ExecuteNonQuery(sql)

            sql = "DELETE FROM WorkflowRoles WHERE WorkflowRoleID = " & nWorkflowRoleID
            db.ExecuteNonQuery(sql)
        End Using
        
        ProcLib.CloseAndRefreshRADNoPrompt(Page)

    End Sub
 
 
</script>

<html>
<head>
    <title>Prompt - Edit Workflow Role</title>
    <link href="Styles.css" type="text/css" rel="stylesheet" />

    <script type="text/javascript" language="javascript">

        function GetRadWindow()   //note: sometimes this needs to be in HEAD tag to work properly
        {
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
    <asp:Label ID="lblID" Style="z-index: 100; left: 42px; position: absolute; top: 15px"
        runat="server">999</asp:Label>
    <asp:Label ID="Label16" Style="z-index: 101; left: 10px; position: absolute; top: 14px"
        runat="server">ID:</asp:Label>
    <asp:TextBox ID="txtWorkflowRole" Style="z-index: 102; left: 111px; position: absolute;
        top: 37px" runat="server" CssClass="EditDataDisplay" Width="157px"></asp:TextBox>
    <asp:TextBox ID="txtDescription" Style="z-index: 103; left: 111px; position: absolute;
        top: 100px" TabIndex="5" runat="server" CssClass="EditDataDisplay" Width="304px"></asp:TextBox>
    <asp:Label ID="Label4" runat="server" Style="z-index: 104; left: 14px; position: absolute;
        top: 103px">Description:</asp:Label>
    <asp:Label ID="Label20" runat="server" Style="z-index: 105; left: 15px; position: absolute;
        top: 38px">Role:</asp:Label>
    <asp:ImageButton ID="butSave" Style="z-index: 106; left: 19px; position: absolute;
        top: 206px" TabIndex="150" runat="server" ImageUrl="images/button_save.gif">
    </asp:ImageButton>
    <asp:ImageButton ID="butDelete" Style="z-index: 107; left: 247px; position: absolute;
        top: 206px; height: 23px;" TabIndex="151" runat="server" 
        ImageUrl="images/button_delete.gif" OnClick="butDelete_Click" OnClientClick="if(!confirm('Are you sure?')) return false;"/>
    </asp:ImageButton>
    <asp:Label ID="lblMessage" Style="z-index: 108; left: 114px; position: absolute;
        top: 15px" runat="server" Width="382px" ForeColor="Red" Height="11px" TabIndex="500">Note:</asp:Label>
    &nbsp; &nbsp;
    <asp:Label ID="Label21" runat="server" Style="z-index: 109; left: 15px; position: absolute;
        top: 73px">Routing Type:</asp:Label>
    <asp:Label ID="Label22" runat="server" Style="z-index: 109; left: 15px; position: absolute;
        top: 168px">Approval Limit:</asp:Label>
    <asp:Label ID="Label2" runat="server" Style="z-index: 109; left: 15px; position: absolute;
        top: 134px">User:</asp:Label>
    &nbsp; &nbsp; &nbsp;&nbsp;
    <telerik:RadWindowManager ID="RadPopups" runat="server" Style="z-index: 110; left: 16px;
        position: absolute; top: 245px">
    </telerik:RadWindowManager>
    &nbsp;&nbsp;
    <asp:DropDownList ID="lstRoleType" runat="server" Style="z-index: 111; left: 111px;
        position: absolute; top: 70px" CssClass="EditDataDisplay" ToolTip="This field is used when configuring parameters to prompt for in the Routing screen.">
        <asp:ListItem>FDO Accountant</asp:ListItem>
        <asp:ListItem>FET Coordinator</asp:ListItem>
        <asp:ListItem>Bond Accountant</asp:ListItem>
        <asp:ListItem>District AP</asp:ListItem>
        <asp:ListItem>Signator</asp:ListItem>
    </asp:DropDownList>
    <asp:DropDownList ID="lstUserID" runat="server" Style="z-index: 111; left: 111px;
        position: absolute; top: 129px" CssClass="EditDataDisplay">
    </asp:DropDownList>
    <telerik:RadNumericTextBox ID="txtApprovalDollarLimit" Label="  " Style="z-index: 111;
        left: 114px; position: absolute; top: 166px" runat="server" MinValue="0" ToolTip="This is the $$ approval limit for this Role">
        <NumberFormat AllowRounding="True"></NumberFormat>
    </telerik:RadNumericTextBox>
    </form>
</body>
</html>
