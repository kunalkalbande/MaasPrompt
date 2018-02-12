<%@ Page Language="vb" %>
<%@ Register Assembly="Telerik.Web.UI" Namespace="Telerik.Web.UI" TagPrefix="telerik" %>
<%@ Import Namespace="Prompt" %>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">

<script runat="server">
   
    Private Sub Page_Load(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MyBase.Load
        ProcLib.CheckSession(Page)
        Session("PageID") = "DashboardSettings"

    End Sub

   
    Protected Sub butResetSettings_Click(ByVal sender As Object, ByVal e As System.EventArgs)

        Using db As New promptUserPrefs
            db.RemoveAllUserSavedSettings()
        End Using
        
        
    End Sub
</script>

<html>
<head>
    <title>Dashboard Settings</title>
    <link href="Styles.css" type="text/css" rel="stylesheet" />
</head>
<body>
    <form id="Form1" method="post" runat="server">

        <asp:Button ID="butResetSettings" runat="server" 
            Text="Reset All Saved Grid and Dashboard Settings" onclick="butResetSettings_Click" />


       

    </form>
</body>
</html>
