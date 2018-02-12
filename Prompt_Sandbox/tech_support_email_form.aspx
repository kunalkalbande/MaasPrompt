<%@ Page Language="vb" %>

<%@ Import Namespace="System.Net.Mail" %>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">

<script runat="server">
 
    Private Sub butSubmit_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles butSubmit.Click
        Dim sCalledFrom As String = Request.QueryString("CalledFrom")
        'Send an email to the support address
        Dim msg As New MailMessage
        With msg
            '.From = New MailAddress(Session("LoginID")) removed for error on dev
            .From = New MailAddress("promptsupport@maasco.com")
            .To.Add(New MailAddress("promptsupport@maasco.com"))
            .Subject = txtIssue.Text
            .Body = "<strong>Issue Reported by User:</strong>  " & txtDescription.Text & "<br><h3>Technical Details:</h3><strong>Help submttied from Page:</strong>  " & Request.QueryString("PageID") & "<br><strong>Submit Date/Time:</strong>  " & Now() & "<br><strong>User:</strong>  " & Request.QueryString("U") & "<br><strong>LoginID:</strong>  " & Request.QueryString("LoginID") & "<br><strong>DistrictID:</strong> " & Request.QueryString("DI") & "<br><strong>District:</strong>  " & Request.QueryString("DistrictName") & "<br><strong>CollegeID:</strong>  " & Request.QueryString("CollegeID") & "<br><strong>College Name:</strong>  " & Request.QueryString("CollegeName") & "<br><strong>ProjectID:</strong>  " & Request.QueryString("ProjectID") & "<br><strong>Project Name:</strong>  " & Request.QueryString("ProjectName")
            .IsBodyHtml = True
        End With
        Dim smtpClient As New SmtpClient
        With smtpClient
            .Host = "mail.maasco.com"
            .UseDefaultCredentials = False
            '.Host = "localhost"
            .Credentials = New System.Net.NetworkCredential("promptsupport@maasco.com", "suprMci#949")
            .Send(msg)
        End With
        
        'original code below below
        'With msg
        '    .From = New MailAddress(Session("LoginID"))
        '    .To.Add(New MailAddress("promptsupport@eispro.com"))
        '    .Subject = txtIssue.Text
        '    .Body = txtDescription.Text
        '    .IsBodyHtml = False
        'End With
        'Dim smtpClient As New SmtpClient
        'With smtpClient
        '    .Host = "mail.eispro.com"
        '    .UseDefaultCredentials = False
        '    '.Host = "localhost"
        '    .Credentials = New System.Net.NetworkCredential("support@eispro.com", "maubi2007")
        '    .Send(msg)
        'End With
        'Response.Write(msg.From)
        'Response.Write(msg.To.ToString)
        Response.Redirect("tech_support_response.aspx?CalledFrom=" & sCalledFrom)

    End Sub


</script>

<html>
<head>
    <title>tech_support_email_form</title>
    <link href="Styles.css" type="text/css" rel="stylesheet" />
</head>
<body>
    <form id="Form1" method="post" runat="server">
    <asp:TextBox ID="txtIssue" Style="z-index: 101; left: 24px; position: absolute; top: 48px"
        runat="server" Width="400px"></asp:TextBox>
    <asp:Label ID="Label2" Style="z-index: 105; left: 24px; position: absolute; top: 80px"
        runat="server">Description:</asp:Label>
    <asp:TextBox ID="txtDescription" Style="z-index: 102; left: 24px; position: absolute;
        top: 96px" runat="server" Width="400px" Height="224px" TextMode="MultiLine"></asp:TextBox>
    <asp:Label ID="Label1" Style="z-index: 103; left: 24px; position: absolute; top: 8px"
        runat="server" Font-Bold="True" Font-Underline="True">Contact PROMPT Technical Support</asp:Label>
    <asp:Label ID="lbl1" Style="z-index: 104; left: 24px; position: absolute; top: 32px"
        runat="server">Issue:</asp:Label>
    <asp:Button ID="butSubmit" Style="z-index: 106; left: 24px; position: absolute; top: 336px"
        runat="server" Text="Submit"></asp:Button>
    </form>
</body>
</html>