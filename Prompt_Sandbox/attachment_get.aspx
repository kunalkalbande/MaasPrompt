<%@ Page Language="vb" %>

<%@ Import Namespace="System.IO" %>
<%@ Import Namespace="Prompt" %>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">

<script runat="server">
    Private Sub Page_Load(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MyBase.Load
        ProcLib.CheckSession(Page)

        ProcLib.LoadPopupJscript(Page)

        If Not IsPostBack Then
            Session("PageID") = "AttachmentGet"

            'set up help button
            butHelp.Attributes.Add("onclick", "openPopup('help_view.aspx','pophelp',550,450,'yes');")
            butHelp.NavigateUrl = "#"

            lblMessage.Text = ""

            lnkGetFile.ImageUrl = "images/button_download.gif"
            lnkClose.ImageUrl = "images/button_close.gif"

            Dim strFullFileName As String = Request.QueryString("file")
            Dim strFileName As String = Path.GetFileName(strFullFileName)
            Dim strFilePath As String = Replace(strFullFileName, strFileName, "")
        
            If InStr(strFileName, "#") > 0 Then
                'this is a hack to fix legacy bad filenames with # in name. # prevents link from working
                FixBadFilename(strFilePath, strFileName)
                strFileName = strFileName.Replace("#", "-")

            End If

            'Strip the physical prefix out of the path for lookup
            Dim sStoredFilePath As String
            sStoredFilePath = strFilePath.Replace(ProcLib.GetCurrentAttachmentPath(), "")

            Dim att As New promptAttachment
            Dim rs As New PromptDataHelper

            rs.FillReader("SELECT * FROM Attachments WHERE CHARINDEX('" & UCase(sStoredFilePath & strFileName) & "',UPPER(FilePath + FileName)) > 0")
            If rs.Reader.HasRows Then
                While rs.Reader.Read()
 
                    lblFileName.Text = ProcLib.CheckNullDBField(rs.Reader("FileName"))
                    If IsNumeric(rs.Reader("FileSize")) Then
                        lblSize.Text = ProcLib.FormatFileSize(ProcLib.CheckNullDBField(rs.Reader("FileSize")))
                    Else
                        lblSize.Text = ProcLib.CheckNullDBField(rs.Reader("FileSize"))
                    End If

                    lblDescription.Text = ProcLib.CheckNullDBField(rs.Reader("Description"))
                    lblComments.Text = ProcLib.CheckNullDBField(rs.Reader("Comments"))
                    lblLastUpdateBy.Text = ProcLib.CheckNullDBField(rs.Reader("LastUpdateBy"))
                    lblLastUpdateOn.Text = ProcLib.CheckNullDBField(rs.Reader("LastUpdateOn"))
                End While


                att.PhysicalPath = strFilePath
                lnkGetFile.NavigateUrl = att.RelativePath & strFileName
                lnkGetFile.Target = "_new"

            Else
                lblMessage.Text = "No File Found."
            End If

            rs.Reader.Close()
            rs.Close()
        End If

    End Sub


    Private Sub lnkClose_Click(ByVal sender As System.Object, ByVal e As System.Web.UI.ImageClickEventArgs) Handles lnkClose.Click
        Session("RtnFromEdit") = True
        ProcLib.CloseAndRefresh(Page)
    End Sub
    
    Private Sub FixBadFilename(ByVal spath As String, ByVal sname As String)

        Dim sql As String = ""
        
        Dim sNewName As String = sname
        sNewName = sNewName.Replace("#", "-")
        
        Dim sStoredPath As String = spath
        sStoredPath = sStoredPath.Replace(ProcLib.GetCurrentAttachmentPath(), "")
        'fix record
        sql = "UPDATE Attachments SET Filename = '" & sNewName & "' WHERE"
        sql = sql & " CHARINDEX('" & UCase(sStoredPath & sname) & "',UPPER(FilePath + FileName)) > 0"
        
        Using rs As New PromptDataHelper
            rs.ExecuteNonQuery(sql)
        End Using
       
        
        'fix file
        On Error Resume Next   'ignore any errors
        File.Copy(spath & sname, spath & sNewName)
        File.Delete(spath & sname)
        On Error GoTo 0
          
    End Sub

    
</script>

<html>
<head>
    <title>Get Attachment</title>
    <meta content="Microsoft Visual Studio .NET 7.1" name="GENERATOR">
    <meta content="Visual Basic .NET 7.1" name="CODE_LANGUAGE">
    <meta content="JavaScript" name="vs_defaultClientScript">
    <meta content="http://schemas.microsoft.com/intellisense/ie5" name="vs_targetSchema">
    <link href="Styles.css" type="text/css" rel="stylesheet">
</head>
<body>
    <form id="Form1" method="post" runat="server">
    <asp:Label ID="lblMessage" Style="z-index: 101; left: 24px; position: absolute; top: 16px"
        runat="server">lblMessage</asp:Label>
    <asp:HyperLink ID="butHelp" Style="z-index: 115; left: 472px; position: absolute;
        top: 8px" runat="server" ImageUrl="images/button_help.gif">HyperLink</asp:HyperLink>
    <asp:Label ID="lblLastUpdateOn" Style="z-index: 114; left: 120px; position: absolute;
        top: 120px" runat="server" Width="152px" CssClass="ViewDataDisplay">Label</asp:Label>
    <asp:Label ID="lblLastUpdateBy" Style="z-index: 113; left: 392px; position: absolute;
        top: 120px" runat="server" Width="104px" CssClass="ViewDataDisplay">Label</asp:Label>
    <asp:Label ID="lblComments" Style="z-index: 112; left: 96px; position: absolute;
        top: 144px" runat="server" Width="416px" CssClass="ViewDataDisplay" Height="48px">Label</asp:Label>
    <asp:Label ID="lblDescription" Style="z-index: 111; left: 96px; position: absolute;
        top: 80px" runat="server" Width="408px" CssClass="ViewDataDisplay" Height="24px">Label</asp:Label>
    <asp:Label ID="lblSize" Style="z-index: 110; left: 448px; position: absolute; top: 40px"
        runat="server" Width="64px" CssClass="ViewDataDisplay">Label</asp:Label>
    <asp:Label ID="Label5" Style="z-index: 108; left: 288px; position: absolute; top: 120px"
        runat="server">Last Update By:</asp:Label>
    <asp:Label ID="Label4" Style="z-index: 107; left: 24px; position: absolute; top: 120px"
        runat="server">Last Update On:</asp:Label>
    <asp:Label ID="Label1" Style="z-index: 106; left: 24px; position: absolute; top: 144px"
        runat="server" Width="64px" Height="16px">Comments:</asp:Label>
    <asp:Label ID="Label3" Style="z-index: 105; left: 24px; position: absolute; top: 80px"
        runat="server">Description:</asp:Label>
    <asp:Label ID="Label2" Style="z-index: 104; left: 416px; position: absolute; top: 40px"
        runat="server">Size:</asp:Label>
    <asp:Label ID="lbl1" Style="z-index: 103; left: 24px; position: absolute; top: 40px"
        runat="server">File Name:</asp:Label>
    <asp:HyperLink ID="lnkGetFile" Style="z-index: 102; left: 24px; position: absolute;
        top: 216px" runat="server" ImageUrl="images/button_download.gif" EnableViewState="False"
        Font-Names="Verdana" Font-Size="11pt">Download</asp:HyperLink>
    <asp:Label ID="lblFileName" Style="z-index: 109; left: 96px; position: absolute;
        top: 40px" runat="server" Width="304px" CssClass="ViewDataDisplay" Height="24px">Label</asp:Label>
    <asp:ImageButton ID="lnkClose" Style="z-index: 116; left: 288px; position: absolute;
        top: 216px" runat="server" ImageUrl="images/button_close.gif"></asp:ImageButton>
    </form>
</body>
</html>
