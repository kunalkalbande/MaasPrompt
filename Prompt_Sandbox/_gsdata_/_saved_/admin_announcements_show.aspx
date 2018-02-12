<%@ Page Language="vb" %>

<%@ Register Assembly="Telerik.Web.UI" Namespace="Telerik.Web.UI" TagPrefix="telerik" %>
<%@ Import Namespace="Prompt" %>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">

<script runat="server">
    
    Private Sub Page_Load(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MyBase.Load

        Session("PageID") = "AnnouncementsShow"
        If Not IsPostBack Then
            Using db As New promptAdmin
                db.CallingPage = Page
                lblAnnouncement.Text = db.GetPromptAnnouncements()
                LatestTimeStamp.Value = db.LastAnnouncementTimeStamp
            End Using
        End If


    End Sub
     
    Private Sub butClose_Click(ByVal sender As System.Object, ByVal e As System.Web.UI.ImageClickEventArgs) Handles butClose.Click
  
        Using db As New promptUserPrefs
            db.CallingPage = Page
            db.SetUserViewedLatestAnnouncement(LatestTimeStamp.Value)
        End Using

        ProcLib.CloseOnlyRAD(Page)
         
    End Sub

 
</script>

<html>
<head>
    <title>Latest Prompt Announcements</title>
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
     <asp:Label ID="lblAnnouncement" runat="server" Text="" Width="100%" ></asp:Label>
    <br />
    <br />
    <asp:ImageButton ID="butClose" TabIndex="40" runat="server" ImageUrl="images/button_close.gif">
    </asp:ImageButton>
     <asp:HiddenField ID="LatestTimeStamp" runat="server" />
    </form>
</body>
</html>
