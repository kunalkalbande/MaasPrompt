<%@ Page Language="vb" %>
<%@ Import Namespace="System.IO" %>
<%@ Import Namespace="System.Web.HTTPUtility" %>
<%@ Import Namespace="Prompt" %>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">
<script runat="server">
    
    Private AttachmentID As Integer = 0
    
    Private Sub Page_Load(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MyBase.Load
        
        If Proclib.CheckExpiredSessionForPopup(Page) Then    'session died so close the page - this is to prevent orphaned popups
            Proclib.CloseAndRefresh(Page)
        End If

        Proclib.LoadPopupJscript(Page)
        
        AttachmentID = Request.QueryString("ID")

        If Not IsPostBack Then
            Session("PageID") = "AttachmentGetLinked"

            'set up help button
            butHelp.Attributes.Add("onclick", "openPopup('help_view.aspx','pophelp',550,450,'yes');")
            butHelp.NavigateUrl = "#"

            lblMessage.Text = ""

            lnkGetFile.ImageUrl = "images/button_download.gif"
            lnkClose.ImageUrl = "images/button_close.gif"
            
            Dim strFileName As String = ""
            Dim strFilePath As String = ""
            Using db As New promptAttachment
                db.GetLinkedAttachment(AttachmentID)
                strFileName = db.FileName
                strFilePath = db.PhysicalPath
                        
                'Strip the physical prefix out of the path for lookup
                Dim sStoredFilePath As String = strFilePath.Replace(Proclib.GetCurrentAttachmentPath(), "")
            
                lblFileName.Text = strFileName
                If IsNumeric(db.LinkedAttachmentFileSize) Then
                    lblSize.Text = proclib.FormatFileSize(db.LinkedAttachmentFileSize)
                Else
                    lblSize.Text = db.LinkedAttachmentFileSize
                End If
            
                lblDescription.Text = db.Description
                lblComments.Text = db.Comments
                lblLastUpdateBy.Text = db.LastUpdateBy
                lblLastUpdateOn.Text = db.LastUpdateOn
            
            
                lnkGetFile.NavigateUrl = db.RelativePath & strFileName
                lnkGetFile.Target = "_new"
            
            End Using

           

        Else
            lblMessage.Text = "No File Found."
        End If

    End Sub

    Private Sub CloseMe()
        'Add Jscript to close the window and update the grid.
        Dim jscript As New StringBuilder
        With jscript
            .Append("<script language='javascript'>")
            .Append("GetRadWindow().Close();")
            .Append("</" & "script>")
        End With
        ClientScript.RegisterStartupScript(GetType(String), "CloseMe", jscript.ToString)
        
    End Sub
    
    Private Sub lnkClose_Click(ByVal sender As System.Object, ByVal e As System.Web.UI.ImageClickEventArgs) Handles lnkClose.Click
        CloseMe
    End Sub
    
      
</script>

<HTML>
	<HEAD>
		<title>Open Linked Attachment</title>
		<meta content="Microsoft Visual Studio .NET 7.1" name="GENERATOR">
		<meta content="Visual Basic .NET 7.1" name="CODE_LANGUAGE">
		<meta content="JavaScript" name="vs_defaultClientScript">
		<meta content="http://schemas.microsoft.com/intellisense/ie5" name="vs_targetSchema">
		<LINK href="Styles.css" type="text/css" rel="stylesheet">
		
      <script type="text/javascript" language="javascript">
    
       function GetRadWindow()
		{
			var oWindow = null;
			if (window.radWindow) oWindow = window.radWindow; //Will work in Moz in all cases, including clasic dialog
			else if (window.frameElement.radWindow) oWindow = window.frameElement.radWindow;//IE (and Moz az well)
				
			return oWindow;
		}

     
   
    </script>

		
	</HEAD>
	<body>
		<form id="Form1" method="post" runat="server">
			<asp:label id="lblMessage" style="Z-INDEX: 101; LEFT: 24px; POSITION: absolute; TOP: 16px"
				runat="server">lblMessage</asp:label><asp:hyperlink id="butHelp" style="Z-INDEX: 115; LEFT: 352px; POSITION: absolute; TOP: 15px" runat="server"
				ImageUrl="images/button_help.gif">HyperLink</asp:hyperlink><asp:label id="lblLastUpdateOn" style="Z-INDEX: 114; LEFT: 120px; POSITION: absolute; TOP: 120px"
				runat="server" Width="152px" CssClass="ViewDataDisplay">Label</asp:label><asp:label id="lblLastUpdateBy" style="Z-INDEX: 113; LEFT: 128px; POSITION: absolute; TOP: 152px"
				runat="server" Width="104px" CssClass="ViewDataDisplay">Label</asp:label><asp:label id="lblComments" style="Z-INDEX: 112; LEFT: 32px; POSITION: absolute; TOP: 198px"
				runat="server" Width="354px" CssClass="ViewDataDisplay" Height="35px">Label</asp:label><asp:label id="lblDescription" style="Z-INDEX: 111; LEFT: 109px; POSITION: absolute; TOP: 92px"
				runat="server" Width="293px" CssClass="ViewDataDisplay" Height="16px">Label</asp:label><asp:label id="lblSize" style="Z-INDEX: 110; LEFT: 97px; POSITION: absolute; TOP: 69px" runat="server"
				Width="64px" CssClass="ViewDataDisplay">Label</asp:label><asp:label id="Label5" style="Z-INDEX: 108; LEFT: 25px; POSITION: absolute; TOP: 151px" runat="server">Last Update By:</asp:label><asp:label id="Label4" style="Z-INDEX: 107; LEFT: 24px; POSITION: absolute; TOP: 120px" runat="server">Last Update On:</asp:label><asp:label id="Label1" style="Z-INDEX: 106; LEFT: 28px; POSITION: absolute; TOP: 175px" runat="server"
				Width="64px" Height="16px">Comments:</asp:label><asp:label id="Label3" style="Z-INDEX: 105; LEFT: 28px; POSITION: absolute; TOP: 93px" runat="server">Description:</asp:label><asp:label id="Label2" style="Z-INDEX: 104; LEFT: 27px; POSITION: absolute; TOP: 71px" runat="server">Size:</asp:label><asp:label id="lbl1" style="Z-INDEX: 103; LEFT: 24px; POSITION: absolute; TOP: 40px" runat="server">File Name:</asp:label><asp:hyperlink id="lnkGetFile" style="Z-INDEX: 102; LEFT: 32px; POSITION: absolute; TOP: 251px"
				runat="server" ImageUrl="images/button_download.gif" EnableViewState="False" Font-Names="Verdana" Font-Size="11pt">Download</asp:hyperlink><asp:label id="lblFileName" style="Z-INDEX: 109; LEFT: 96px; POSITION: absolute; TOP: 40px"
				runat="server" Width="304px" CssClass="ViewDataDisplay" Height="24px">Label</asp:label><asp:imagebutton id="lnkClose" style="Z-INDEX: 116; LEFT: 274px; POSITION: absolute; TOP: 251px"
				runat="server" ImageUrl="images/button_close.gif"></asp:imagebutton></form>
	</body>
</HTML>
