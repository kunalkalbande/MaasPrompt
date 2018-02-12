<%@ Page Language="vb" %>

<%@ Import Namespace="Prompt" %>
<%@ Import Namespace="System.Configuration" %>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">

<script runat="Server">
    
    Private nProjectID As Integer = 0
    Private nCollegeID As Integer = 0
    Private nDistrictID As Integer = 0
    Private strPhase As String = ""
    Private strTitle As String = ""
    Private strDescription As String = ""

    Private strGetMode As String

    Private Sub Page_Load(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MyBase.Load

        nDistrictID = 55
        
        If Not IsPostBack Then
            GetPhoto(Request.QueryString("ID"))
        End If

    End Sub
    Private Sub GetPhoto(ByVal ID As String)

        Dim nProjectID As Integer = Request.QueryString("ProjectID")
        Dim strPhase As String = Request.QueryString("Phase")
        Dim nPhotoID As Integer

        'Get all photos in the same project/phase and set up next/back
        Using rs As New PromptDataHelper
            rs.FillReader("SELECT * FROM ApprisePhotos WHERE ProjectID = " & nProjectID & " ORDER BY DisplayOrder")
            Try
                Dim i As Integer = 0
                While rs.Reader.Read()
                    i = i + 1
                    If CStr(i) = ID Then  'we got what we want
                        nPhotoID = rs.Reader("ApprisePhotoID")
                        nCollegeID = rs.Reader("CollegeID")
                        nDistrictID = rs.Reader("DistrictID")
                        strTitle = ProcLib.CheckNullDBField(rs.Reader("Title"))
                        strDescription = ProcLib.CheckNullDBField(rs.Reader("Description"))

                        'set the command arguments for the back and next button
                        butNext.CommandArgument = CStr(i + 1)
                        butBack.CommandArgument = CStr(i - 1)
                    End If

                End While

                If butNext.CommandArgument > i Then  'set next to first
                    butNext.CommandArgument = "1"
                End If
                If butBack.CommandArgument = 0 Then  'set back  to last
                    butBack.CommandArgument = CStr(i)
                End If

            Catch ex As Exception
                lblDescription.Text = "Database Error: " & ex.Message
            End Try
            rs.Reader.Close()
            rs.Close()
        End Using


        lblTitle.Text = strTitle
        lblDescription.Text = strDescription
        imgPhoto.ImageUrl = ProcLib.GetCurrentRelativeAttachmentPath() & "DistrictID_" & nDistrictID & "/_apprisedocs/_photos/ProjectID_" & nProjectID & "/"
        imgPhoto.ImageUrl = imgPhoto.ImageUrl & nPhotoID & ".jpg"
    End Sub


    Private Sub butBack_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles butBack.Click
        GetPhoto(sender.CommandArgument)
    End Sub

    Private Sub butNext_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles butNext.Click
        GetPhoto(sender.CommandArgument)
    End Sub

    Private Sub butClose_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles butClose.Click
        Dim jscript As String
        'Pass the jscript back to the page to close it and refresh the data on the calling page
        jscript = "<script language='javascript'>"
        jscript = jscript & "self.close(); "
        jscript = jscript & "</" & "script>"
        ClientScript.RegisterStartupScript(GetType(String), "PopupClose", jscript)
    End Sub
     
    
    
    
</script>

<html>
<head>
    <title>photo_view</title>
    <link rel="stylesheet" type="text/css" href="Styles.css" />
</head>
<body>
    <form id="Form1" method="post" runat="server">
    <table id="Table1" cellspacing="1" cellpadding="1" width="100%" border="0">
        <tr>
            <td height="58" align="center" style="height: 58px">
                <asp:Label ID="lblTitle" runat="server" CssClass="PageProjectTitle">title</asp:Label>
            </td>
        </tr>
        <tr>
            <td align="center" style="height: 90px">
                <asp:Image ID="imgPhoto" runat="server" EnableViewState="False"></asp:Image><br>
                <asp:Label ID="lblDescription" runat="server" EnableViewState="False" CssClass="PageProjectDescription">Description</asp:Label><br>
            </td>
        </tr>
        <tr>
            <td align="center">
                <asp:Button ID="butBack" runat="server" Text="<<"></asp:Button>&nbsp;&nbsp;&nbsp;&nbsp;
                <asp:Button ID="butClose" runat="server" Text="Close"></asp:Button>&nbsp;&nbsp;&nbsp;&nbsp;
                <asp:Button ID="butNext" runat="server" Text=">>"></asp:Button>
            </td>
        </tr>
    </table>
    </form>
</body>
</html>
