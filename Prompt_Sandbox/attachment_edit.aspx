<%@ Page Language="vb" %>

<%@ Import Namespace="System.IO" %>
<%@ Import Namespace="Prompt" %>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">

<script runat="server">
    Public nAttachmentID As Integer
    Private bAllowSave As Boolean = False
    
    Private Sub Page_Load(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MyBase.Load

        Session("PageID") = "AttachmentEdit"

        ProcLib.CheckSession(Page)

        ProcLib.LoadPopupJscript(Page)
        
        bAllowSave = Request.QueryString("allowedit")

        'set up help button
        butHelp.Attributes.Add("onclick", "openPopup('help_view.aspx','pophelp',550,450,'yes');")
        butHelp.NavigateUrl = "#"

        Dim strFullFileName As String = Request.QueryString("file")
        Dim strFileName As String = Path.GetFileName(strFullFileName)
        Dim strFilePath As String = Replace(strFullFileName, strFileName, "")

        'Strip the physical prefix out of the path for lookup
        Dim sStoredFilePath As String = ""
        sStoredFilePath = strFilePath.Replace(ProcLib.GetCurrentAttachmentPath(), "")
        
        'Response.Write(strFullFileName & "<br />")
        'Response.Write(strFileName & "<br />")
        'Response.Write(strFilePath & "<br />")
        'Response.Write(sStoredFilePath & "<br />")
        'Response.End()
        
        Using db As New promptAttachment
            If IsPostBack Then   'only do the following post back
                nAttachmentID = lblAttachmentID.Text
            Else  'only do the following on first load

                db.CallingPage = Page
                db.GetAttachmentData(sStoredFilePath, strFileName)
                
                If IsNumeric(lblFileSize.Text) Then
                    ProcLib.FormatFileSize(lblFileSize.Text)
                End If

                SetFocus("txtDescription")
            End If
        
        
            If db.IsInWorkflow(lblAttachmentID.Text) = True Then
                butDelete.Visible = False
            End If
        End Using
       
           
        If Not bAllowSave Then
            butSave.ImageUrl = "images/button_close.gif"
            butDelete.Visible = False
            txtComments.Enabled = False
            txtDescription.Enabled = false
        End If

    End Sub

    Private Sub butSave_Click(ByVal sender As System.Object, ByVal e As System.Web.UI.ImageClickEventArgs) Handles butSave.Click

        If bAllowSave Then
            Using rs As New promptAttachment
                rs.CallingPage = Page
                rs.SaveAttachmentData(nAttachmentID)
            End Using
           
        End If
        
        Session("RtnFromEdit") = True
        ProcLib.CloseAndRefresh(Page)
    End Sub

    Private Sub butDelete_Click(ByVal sender As System.Object, ByVal e As System.Web.UI.ImageClickEventArgs) Handles butDelete.Click

        Session("RtnFromEdit") = True
        Response.Redirect("delete_record.aspx?RecordType=Attachment&ID=" & nAttachmentID)

    End Sub
      
</script>

<html>
<head>
    <title>attachment_edit</title>
    <meta content="Microsoft Visual Studio .NET 7.1" name="GENERATOR">
    <meta content="Visual Basic .NET 7.1" name="CODE_LANGUAGE">
    <meta content="JavaScript" name="vs_defaultClientScript">
    <meta content="http://schemas.microsoft.com/intellisense/ie5" name="vs_targetSchema">
    <link href="Styles.css" type="text/css" rel="stylesheet">
</head>
<body>
    <form id="Form1" method="post" runat="server">
    <asp:Label ID="Label1" Style="z-index: 100; left: 8px; position: absolute; top: 8px"
        runat="server">ID:</asp:Label>
    <asp:ImageButton ID="butSave" Style="z-index: 113; left: 80px; position: absolute;
        top: 240px" TabIndex="5" runat="server" ImageUrl="images/button_save.gif"></asp:ImageButton>
    <asp:ImageButton ID="butDelete" Style="z-index: 103; left: 376px; position: absolute;
        top: 240px" TabIndex="6" runat="server" ImageUrl="images/button_delete.gif">
    </asp:ImageButton>
    <asp:HyperLink ID="butHelp" Style="z-index: 112; left: 472px; position: absolute;
        top: 16px" runat="server" ImageUrl="images/button_help.gif">HyperLink</asp:HyperLink>
    <asp:TextBox ID="txtComments" Style="z-index: 111; left: 80px; position: absolute;
        top: 120px" runat="server" Width="424px" Height="104px" TextMode="MultiLine"
        CssClass="EditDataDisplay"></asp:TextBox>
    <asp:TextBox ID="txtDescription" Style="z-index: 110; left: 80px; position: absolute;
        top: 72px" runat="server" Width="352px" CssClass="EditDataDisplay"></asp:TextBox>
    <asp:Label ID="lblFileSize" Style="z-index: 109; left: 392px; position: absolute;
        top: 32px" runat="server" Width="48px" CssClass="ViewDataDisplay">Label</asp:Label>
    <asp:Label ID="Label6" Style="z-index: 107; left: 8px; position: absolute; top: 120px"
        runat="server" Width="64px" Height="16px">Comments:</asp:Label>
    <asp:Label ID="Label3" Style="z-index: 106; left: 8px; position: absolute; top: 80px"
        runat="server">Description:</asp:Label>
    <asp:Label ID="Label2" Style="z-index: 104; left: 352px; position: absolute; top: 32px"
        runat="server">Size:</asp:Label>
    <asp:Label ID="lbl1" Style="z-index: 101; left: 8px; position: absolute; top: 32px"
        runat="server">File Name:</asp:Label>
    <asp:Label ID="lblFileName" Style="z-index: 108; left: 80px; position: absolute;
        top: 32px" runat="server" Width="232px" CssClass="ViewDataDisplay" Height="32px">Label</asp:Label>
    <asp:Label ID="lblAttachmentID" Style="z-index: 105; left: 32px; position: absolute;
        top: 8px" runat="server">999</asp:Label>
    </form>
</body>
</html>
