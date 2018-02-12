<%@ Page Language="vb" %>

<%@ Import Namespace="Prompt" %>
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
            If lblMessage.Text = "Your Password has been changed." Then
                Session("CurrentPwd") = ""
                Response.Redirect("index.aspx?logout=1&msg=resetpwd")
            End If
        End Using
    End Sub
</script>

<html>
<head>
    <title>Change your Password</title>

    <meta content="False" name="vs_snapToGrid" />
    <meta content="Microsoft Visual Studio .NET 7.1" name="GENERATOR" />
    <meta content="Visual Basic .NET 7.1" name="CODE_LANGUAGE" />
    <meta content="JavaScript" name="vs_defaultClientScript" />
    <meta content="http://schemas.microsoft.com/intellisense/ie5" name="vs_targetSchema" />
    <link href="Styles.css" type="text/css" rel="stylesheet" />
     <link rel="icon" type="image/png" href="images/home.png" />
</head>
<body class="login">
    <form id="Form1" method="post" runat="server" style="width:450px;margin:120px auto 20px auto;-moz-border-radius:15px;-webkit-border-radius:15px;padding:30px;background:#9ac5f0;">
    <h2>Password Update</h2> 
    <asp:Label ID="Label5" runat="server" Text="<div class=login_msg><b>Your password has expired.</b> Please change it now to continue.<br><i>Your new password will expire in 60 days.</i></div>"></asp:Label><br>
    <asp:Label ID="Label4" runat="server" Text="Enter New Password:"></asp:Label><br>
    <asp:TextBox ID="txtNewPassword" runat="server" TextMode="Password" CssClass="login_input"></asp:TextBox><br>
    <asp:Label ID="Label3" runat="server" CssClass="login_sm" Text="(at least 8 characters including 1 number and 1 upper case letter - ie:Testpwd2)"></asp:Label><br><br>
    <asp:Label ID="Label2" runat="server" Text="Retype New Password:"></asp:Label><br>
    <asp:TextBox ID="txtConfirmPassword" runat="server" TextMode="Password" CssClass="login_input"></asp:TextBox><br><br>
    <asp:ImageButton ID="butSave" runat="server" ImageUrl="images/button_save.gif" onclick="butSave_Click1" />
    <asp:Label ID="lblMessage" runat="server" ForeColor="Red" Width="325px"></asp:Label>
    
    </form>
</body>
</html>

