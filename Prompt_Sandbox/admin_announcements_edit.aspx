<%@ Page Language="vb" %>

<%@ Register Assembly="Telerik.Web.UI" Namespace="Telerik.Web.UI" TagPrefix="telerik" %>
<%@ Import Namespace="Prompt" %>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">

<script runat="server">

    Private Sub Page_Load(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MyBase.Load

        Session("PageID") = "AnnouncementsEdit"

        If Not IsPostBack() Then
            Using db As New promptAdmin
                db.CallingPage = Page
                txtAnnouncement.Content = db.GetPromptAnnouncements()
 
            End Using
        End If


    End Sub
     
    Private Sub butSave_Click(ByVal sender As System.Object, ByVal e As System.Web.UI.ImageClickEventArgs) Handles butSave.Click
  
        Using db As New promptAdmin
            db.CallingPage = Page
            db.SavePromptAnnouncements()
        End Using

        ProcLib.CloseAndRefreshRADNoPrompt(Page)
        Session("RtnFromEdit") = True
        
        
    End Sub

 
</script>

<html>
<head>
    <title>Prompt Announcements Edit</title>
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
    <telerik:RadEditor ID="txtAnnouncement" Width="98%" Height="500px" EnableDocking="False"
        EnableEnhancedEdit="False" runat="server" SaveInFile="False" ShowHtmlMode="False"
        ShowPreviewMode="False" ShowSubmitCancelButtons="False" UseFixedToolbar="True"
        ToolsFile="EISToolsFile.xml">
    </telerik:RadEditor>
    <br />
    <br />
    <asp:ImageButton ID="butSave" TabIndex="40" runat="server" ImageUrl="images/button_save.gif">
    </asp:ImageButton>
    </form>
</body>
</html>
