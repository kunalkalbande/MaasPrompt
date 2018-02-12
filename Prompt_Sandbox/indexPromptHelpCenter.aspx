<%@ Page Language="vb" %>
<%@ Import Namespace="Prompt" %>
<%--<html xmlns="http://www.w3.org/1999/xhtml" lang="en" xml:lang="en">--%>

<script runat="server">
    
    Private bAutoLoginForDevelopment As Boolean = False     'debug flag to enable autologin in debug mode
    Private nOtherUserID As Integer = 0     'For tech support to log in as another user without having to provide credientials

    Private Sub Page_Load(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MyBase.Load
        
        'Dim sDomain As String = HttpContext.Current.Request.ServerVariables("SERVER_NAME") ' capture the request object address
        'sDomain = UCase(sDomain) ' convert all to upper case
        'If sDomain = "APPS.EISPRO.NET" Then
        '    Response.Redirect("HTTPS://prompted.eispro.com")
        'End If
        
        
        bAutoLoginForDevelopment = True     'debug flag to enable autologin in debug mode
        'Session("DEBUGLiveTest") = "Y"             '---  Enable for Live Testing on Rollout to disallow non live test users -----
         
        'Check for Production Call and HTTPS if not there redirect to SSL
            If Request.ServerVariables("LOCAL_ADDR") = "69.36.227.214" Then    'this is production
                If Request.ServerVariables("HTTPS") <> "on" Then    'redirect to SSL
                    Response.Redirect("https://apps.eispro.net")
                End If
            End If
                
            Dim bNewLogin As Boolean = False
        
       
        If Request.QueryString("logout") = 1 Then
            Session.RemoveAll()
            If Request.QueryString("msg") = "resetpwd" Then
                message.Text = "<div class=login_ok>Your password has been changed. Please log in again.</div><br>"
            Else
                message.Text = "<div class=login_ok>Please log in again.</div><br>"
            End If
           
            bNewLogin = True
        End If
        
        If Request.QueryString("loginasanotheruser") = 100 Then      'log in as another user
            Session.RemoveAll()
            Session("backdoorlogin") = "y"
            bNewLogin = True
            nOtherUserID = Request.QueryString("otherid")
        End If

            If bNewLogin = True Or Session("UserName") = "" Then
            
                Using oLogin As New promptLogin
                    oLogin.ResetSessionVariables()
          
                    Select Case ProcLib.GetLocale()
                        Case "Local"   'FOR DEBUGG AND DEVELOPMENT
                            Session("Dev") = "DEVLOCAL"
                        If bAutoLoginForDevelopment And nOtherUserID = 0 Then      'bypass login and log user in manually
                            nOtherUserID = 299   'login as Programmer
                        End If
                   
                    Case "Beta", "VMBeta"
                        Session("Dev") = "DEVREMOTE"
                    
                        Case Else
                            'Production - do nothing
                    End Select
                
               
                    If nOtherUserID <> 0 Then   'log in as another user
                        oLogin.LogInAsAnotherUser(nOtherUserID)
                        SetCurrentView()
                    End If
                
                End Using
            Else    'user is already logged in and valid so setup
            
                SetCurrentView()
            End If

    End Sub
    
    Private Sub SetCurrentView()
    
        Using db As New promptLogin
            db.SetUserStartPage()
            Response.Redirect(Session("StartPageName"))
        End Using
       
    End Sub
    
    Private Sub lnkForgotPassword_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles lnkForgotPassword.Click
        If LoginID.Text = "" Then
            message.Text = "<div class=login_msg>Please enter your email address.</div><br>"
            Exit Sub
        End If

        Using db As New promptUser
            If db.ResetPasswordFromLoginPage(LoginID.Text) = "" Then
                message.Text = "<div class=login_ok>Your password has been sent to you.</div><br>"
            Else
                message.Text = "<div class=login_msg>Cannot find your email address. Please try again or contact Technical Support.</div><br>"
            End If

        End Using
    End Sub

    Private Sub butLogon_Click(ByVal sender As System.Object, ByVal e As System.Web.UI.ImageClickEventArgs) Handles butLogon.Click
        message.Text = ""
        Dim msg As String = ""
        Using db As New promptLogin
            Dim result As String = db.ValidateUser(LoginID.Text, Password.Text)
            
            If result = "Ok" Then   'good login
                SetCurrentView()
            ElseIf result = "ChangePassword" Then   'change password except tech support
       
                Session("LoginID") = LoginID.Text
                Session("CurrentPwd") = Password.Text
                Session("UserName") = "ChangePassword"
                Response.Redirect("password_change_expired.aspx")
                    
            Else      'bad login so see how many tries already
                If result = "BadLoginID" Then
                    msg = "<div class=login_msg>The <b>email address</b> you entered was not found. Please try again or contact Technical Support.</div><br><br>"
                ElseIf result = "AccountLocked" Then
                    msg = "<div class=login_msg>Your Account has been locked. Please wait 15 minutes and try again or contact Technical Support.</div><br><br>"
                ElseIf result = "AccountDisabled" Then
                    msg = "<div class=login_msg>Your Account has been disabled. Please contact Technical Support.</div><br><br>"
                ElseIf result = "LiveTestingErr" Then
                    msg = "<div class=login_msg>PROMPT is currently down for maintenance. Please try again later.</div><br><br>"
                ElseIf Val(result) < 1 Then
                    msg = "<div class=login_msg>The Password you entered was incorrect. Your account has been "
                    msg &= "temporarily disabled and will be reactivated in 15 minutes.</div><br><br>"
                Else
                    msg = "<div class=login_msg>The <b>password</b> you entered was incorrect. "
                    msg &= "You have " & result & " trys left.<br>Please try again or contact Tech Support for help.</div><br><br>"
                End If
                
                message.Text = msg
 
            End If
        End Using
    End Sub

</script>

<head>
<meta http-equiv="X-UA-Compatible" content="IE=8" />
    <title>Prompt</title>

    <script type="text/javascript" language="JavaScript">
/*  makes sure this page is always in top frame */
if (top.location.href != location.href)
top.location.href = location.href;

    </script>

     <link href="file:///C|/Users/Anh/Desktop/BUPPrompt81912/Prompt/Styles.css" type="text/css" rel="stylesheet" />
     <link rel="icon" type="image/png" href="file:///C|/Users/Anh/Desktop/BUPPrompt81912/Prompt/images/home.png" />
</head>
<body class="login"><h1>Prompt.ed</h1>
<form id="Form1" method="post" runat="server" style="width:450px;margin:20px auto 20px auto;-moz-border-radius:15px;-webkit-border-radius:15px;padding:30px;background:#9ac5f0;">
<h2>Log In</h2>
<asp:Label ID="message" runat="server" EnableViewState="False"></asp:Label>
<asp:Label ID="Label1" runat="server">Email Address:</asp:Label><br />
<asp:TextBox ID="LoginID" runat="server" CssClass="login_input" Height="30px"></asp:TextBox><br /><br />
<asp:Label ID="Label2" runat="server">Password:</asp:Label><br />
<asp:TextBox ID="Password" runat="server" TextMode="Password" 
    CssClass="login_input" Height="30px"></asp:TextBox><br /><br />
<asp:ImageButton ID="butLogon" runat="server" ImageUrl="images/button_login.gif"></asp:ImageButton>
<h3>Forget your password?</h3>
<asp:LinkButton ID="lnkForgotPassword" runat="server" EnableViewState="False" CausesValidation="False">Enter your email address and reset your password</asp:LinkButton>
<h3>Need help? (add users, report changes, other requests)</h3>
<a href="prompthelpcenter.html">Please enter PromptHelpCenter </a>
</form>
</body>
</html>
