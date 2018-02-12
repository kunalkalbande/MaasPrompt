<%@ Page Language="vb" %>
<%@ Import Namespace="Prompt" %>
<%@ Import Namespace="System" %>
<%@ Import Namespace="System.io" %>

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">
<script runat="server">
   
    Private Sub Page_Load(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MyBase.Load
        Proclib.CheckSession(Page)
        Session("PageID") = "ChangePassword"

    End Sub

    Protected Sub butSave_Click1(ByVal sender As Object, ByVal e As System.Web.UI.ImageClickEventArgs)
        Using rs As New promptUser
            rs.CallingPage = Page
            lblMessage.Text = rs.ChangePassword()
        End Using
    End Sub
</script>
<HTML>
	<HEAD>
		<title>Change Password</title>
		<meta content="Microsoft Visual Studio .NET 7.1" name="GENERATOR">
		<meta content="Visual Basic .NET 7.1" name="CODE_LANGUAGE">
		<meta content="JavaScript" name="vs_defaultClientScript">
		<meta content="http://schemas.microsoft.com/intellisense/ie5" name="vs_targetSchema">
		<LINK href="Styles.css" type="text/css" rel="stylesheet">
	</HEAD>
	<body>
		<form id="Form1" method="post" runat="server">
            <asp:Label ID="Label3" runat="server" Style="z-index: 100; left: 268px; position: absolute;
                top: 71px; right: 1018px; width: 243px;" 
                Text="(at least 8 characters including 1 number and 1 upper case letter - ie:Testpwd2)"></asp:Label>
            <asp:Label ID="Label1" runat="server" Style="z-index: 100; left: 18px; position: absolute;
                top: 40px; right: 1366px; width: 145px;" Text="Enter Current Password:"></asp:Label>
            <asp:Label ID="Label2" runat="server" Style="z-index: 101; left: 17px; position: absolute;
                top: 112px; width: 153px;" Text="Retype New Password:"></asp:Label>
            <asp:Label ID="Label4" runat="server" Style="z-index: 100; left: 16px; position: absolute;
                top: 76px; right: 1394px;" Text="Enter New Password:" Width="119px"></asp:Label>
            <asp:TextBox ID="txtNewPassword" runat="server" Style="z-index: 102; left: 158px; position: absolute;
                top: 72px" TextMode="Password" Width="97px"></asp:TextBox>
            <asp:TextBox ID="txtCurrentPassword" runat="server" Style="z-index: 102; left: 159px; position: absolute;
                top: 35px; " TextMode="Password" Width="97px"></asp:TextBox>
            <asp:TextBox ID="txtConfirmPassword" runat="server" Style="z-index: 103; left: 156px;
                position: absolute; top: 107px" TextMode="Password" Width="97px"></asp:TextBox>
              <asp:ImageButton ID="butSave" runat="server" Style="z-index: 104; left: 15px; position: absolute;
                top: 227px" ImageUrl="images/button_save.gif" onclick="butSave_Click1" />
            &nbsp;
            <asp:Label ID="lblMessage" runat="server" ForeColor="Red" Style="z-index: 107;
                left: 17px; position: absolute; top: 183px" Width="325px"></asp:Label>
		</form>
	</body>
</HTML>
