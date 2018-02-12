<%@ Page Language="vb" %>

<%@ Register Assembly="Telerik.Web.UI" Namespace="Telerik.Web.UI" TagPrefix="telerik" %>
<%@ Import Namespace="System.IO" %>
<%@ Import Namespace="System.IO.FileSystemInfo" %>
<%@ Import Namespace="System.Drawing" %>
<%@ Import Namespace="System.Drawing.Imaging" %>
<%@ Import Namespace="System.Drawing.Drawing2D" %>
<%@ Import Namespace="Prompt" %>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">

<script runat="server">
 
    Private nPhotoID As Integer = 0
    Private nProjectID As Integer = 0
    Private sPhotoCategory As String = ""

    Private strImageName As String = ""
    
    Dim strImageBasePath As String = ""
    Dim strImagePath As String = ""
    Dim strFullMainImageFilename As String = ""
        
    Dim strRealPhotoPath As String = ""
    Dim strRealImageFilename As String = ""
    Dim strRealMainImageFilename As String = ""

    Private Sub Page_Load(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MyBase.Load
        ProcLib.CheckSession(Page)
        ProcLib.LoadPopupJscript(Page)

        Session("PageID") = "UploadMainPhoto"
        nPhotoID = Request.QueryString("ID")
        nProjectID = Request.QueryString("ProjectID")
        
        
        strImageBasePath = "DistrictID_" & Session("DistrictID") & "/_apprisedocs/_photos/" & "ProjectID_" & nProjectID & "/"
        strImagePath = ProcLib.GetCurrentRelativeAttachmentPath() & strImageBasePath
        strRealPhotoPath = ProcLib.GetCurrentAttachmentPath() & strImageBasePath

        
        If Request.QueryString("new") = "y" Then
            butDelete.Visible = False
        End If

        'set up help button
        butHelp.Attributes.Add("onclick", "openPopup('help_view.aspx','pophelp',550,450,'yes');")
        butHelp.NavigateUrl = "#"

    End Sub

    Private Sub butUpload_Click(ByVal sender As System.Object, ByVal e As System.Web.UI.ImageClickEventArgs) Handles butUpload.Click

        'save the file - we are only allowing one file for this upload funtion
        For Each File As Telerik.Web.UI.UploadedFile In RadUpload1.UploadedFiles

            sPhotoCategory = "MainPhoto"
            strImageName = strRealPhotoPath & "main.jpg"
 
            Dim folder As New DirectoryInfo(strRealPhotoPath)
            If Not folder.Exists Then  'create the folder
                folder.Create()
            End If

            SaveOriginal(File)
            ResizePhoto(File)
            CreateThumbnail(File)

        Next
        Session("RtnFromEdit") = True
        ProcLib.CloseAndRefreshRADNoPrompt(Page)

    End Sub
    
    Private Sub SaveOriginal(ByVal f As Telerik.Web.UI.UploadedFile)
        
        'Save original file

        Dim strOrigImageName As String = Replace(strImageName, ".jpg", "_ORIG.jpg")
        
        '***************************

        'Dim contentType As String = f.ContentType
        'Dim contentLength As Integer = f.ContentLength

        f.SaveAs(strOrigImageName)


    End Sub
    
    Private Sub CreateThumbnail(ByVal f As Telerik.Web.UI.UploadedFile)

        Dim MaxWidth As Integer = 75    'Max width of the uploaded image, set to 0 to not resize
        Dim MaxHeight As Integer = 60    'Max width of the uploaded image, set to 0 to not resize

        strImageName = Replace(strImageName, ".jpg", "_thumb.jpg")
        
        '***************************

        Dim contentType As String = f.ContentType
        Dim contentLength As Integer = f.ContentLength

        Dim strTempImageName As String = strRealPhotoPath & "tmp3.jpg"   'Temp file name/location
        f.SaveAs(strTempImageName)

        'Resize Image if needed
        Dim ThisImage As System.Drawing.Image = System.Drawing.Image.FromFile(strTempImageName)

        'If we have MaxWidth turned on (not set to zero) and the uploaded image is wider, then resize
        Dim NewWidth As Integer  'Holds Resized Width
        Dim NewHeight As Integer  'Holds Resized Height
        If (MaxWidth > 0) And (ThisImage.Width > MaxWidth) Then
            'Calculate New Width and Height Height
            NewWidth = MaxWidth
            NewHeight = CInt(CInt(ThisImage.Height) / (CInt(ThisImage.Width) / NewWidth))
        Else
            'We didn't have to resize, so just assign Width and Height to what it is now
            NewWidth = ThisImage.Width
            NewHeight = ThisImage.Height
        End If

        'If after checking width and resizing, the height is still wrong then resize again
        If (MaxHeight > 0) And (NewHeight > MaxHeight) Then
            'Calculate New Width and Height Height

            NewWidth = CInt(NewWidth / (NewHeight / MaxHeight))
            NewHeight = MaxHeight
        End If

        'Create new image which is now sized properly
        Dim g As System.Drawing.Image = System.Drawing.Image.FromFile(strTempImageName)
        Dim imgOutput As New Bitmap(g, NewWidth, NewHeight)

        'Save sized image with text!
        imgOutput.Save(strImageName, System.Drawing.Imaging.ImageFormat.Jpeg)
        imgOutput.Dispose()

        'Clean Up
        g.Dispose()
        ThisImage.Dispose()

        'Remove "temp" file
        Dim objFileInfo As FileInfo
        objFileInfo = New FileInfo(strTempImageName)
        objFileInfo.Delete()

        f = Nothing

    End Sub
    
    Private Sub ResizePhoto(ByVal f As Telerik.Web.UI.UploadedFile)

        Dim MaxWidth As Integer = 500    'Max width of the uploaded image, set to 0 to not resize
        Dim MaxHeight As Integer = 375    'Max width of the uploaded image, set to 0 to not resize
        '***************************

        Dim contentType As String = f.ContentType
        Dim contentLength As Integer = f.ContentLength

        Dim strTempImageName As String = strRealPhotoPath & "tmp2.jpg"   'Temp file name/location
        f.SaveAs(strTempImageName)

        'Resize Image if needed
        Dim ThisImage As System.Drawing.Image = System.Drawing.Image.FromFile(strTempImageName)

        'If we have MaxWidth turned on (not set to zero) and the uploaded image is wider, then resize
        Dim NewWidth As Integer  'Holds Resized Width
        Dim NewHeight As Integer  'Holds Resized Height
        If (MaxWidth > 0) And (ThisImage.Width > MaxWidth) Then
            'Calculate New Width and Height Height
            NewWidth = MaxWidth
            NewHeight = CInt(CInt(ThisImage.Height) / (CInt(ThisImage.Width) / NewWidth))
        Else
            'We didn't have to resize, so just assign Width and Height to what it is now
            NewWidth = ThisImage.Width
            NewHeight = ThisImage.Height
        End If

        'If after checking width and resizing, the height is still wrong then resize again
        If (MaxHeight > 0) And (NewHeight > MaxHeight) Then
            'Calculate New Width and Height Height

            NewWidth = CInt(NewWidth / (NewHeight / MaxHeight))
            NewHeight = MaxHeight
        End If

        'Create new image which is now sized properly
        Dim g As System.Drawing.Image = System.Drawing.Image.FromFile(strTempImageName)
        Dim imgOutput As New Bitmap(g, NewWidth, NewHeight)

        'Save sized image with text!
        imgOutput.Save(strImageName, System.Drawing.Imaging.ImageFormat.Jpeg)
        imgOutput.Dispose()

        'Clean Up
        g.Dispose()
        ThisImage.Dispose()

        'Remove "temp" file
        Dim objFileInfo As FileInfo
        objFileInfo = New FileInfo(strTempImageName)
        objFileInfo.Delete()

        f = Nothing
 
    End Sub



    Protected Sub butDelete_Click(ByVal sender As Object, ByVal e As System.Web.UI.ImageClickEventArgs)
        
        Dim strBasePhotoPath As String = ProcLib.GetCurrentAttachmentPath() & "DistrictID_" & HttpContext.Current.Session("DistrictID") & "\_apprisedocs\_photos\ProjectID_" & nProjectID & "\"
        Dim strPhotoPath As String = strBasePhotoPath & "main.jpg"
        Dim strThumbPhotoPath As String = strBasePhotoPath & "main_thumb.jpg"
        Dim strOrigPhotoPath As String = strBasePhotoPath & "main_ORIG.jpg"

        'Delete photo if present
        Dim file As New FileInfo(strPhotoPath)
        If file.Exists Then
            file.Delete()
        End If

        Dim fileThumb As New FileInfo(strThumbPhotoPath)
        If fileThumb.Exists Then
            fileThumb.Delete()
        End If
        
        Dim fileORIG As New FileInfo(strOrigPhotoPath)
        If fileORIG.Exists Then
            fileORIG.Delete()
        End If

           
        Session("RtnFromEdit") = True
        ProcLib.CloseAndRefreshRADNoPrompt(Page)
                
    End Sub
</script>

<html>
<head>
    <title>Main Photo Upload</title>
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
    <table width="100%">
        <tr>
            <td class="pageheading" style="height: 15px" align="left">
                Upload Main Photo
            </td>
            <td class="pageheading" style="height: 15px" align="right">
                <asp:HyperLink ID="butHelp" runat="server" ImageUrl="images/button_help.gif">HyperLink</asp:HyperLink>
            </td>
        </tr>
        <tr>
            <td colspan="2" style="height: 26px">
                <asp:Label ID="Label1" runat="server">Select File:</asp:Label>
            </td>
        </tr>
        <tr>
            <td colspan="2" style="height: 21px">
                <telerik:RadUpload ID="RadUpload1" runat="server" Style="z-index: 100; left: 8px;
                    top: 54px" AllowedFileExtensions=".jpg,.gif,.jpe,.png,.jpeg" ControlObjectsVisibility="None" />
            </td>
        </tr>
        <tr>
            <td >
                <asp:ImageButton ID="butUpload" runat="server" ImageUrl="images/button_save.gif" />
            </td>
                       <td>
                <asp:ImageButton ID="butDelete" runat="server" ImageUrl="images/button_delete.gif" 
                               onclick="butDelete_Click" />
            </td>
        </tr>
    </table>
    <telerik:RadProgressArea ID="RadProgressArea1" runat="server" Style="z-index: 100;
        left: 3px; position: absolute; top: 146px;" Left="3px" />
    <telerik:RadProgressManager ID="RadProgressManager1" runat="server" />
    </form>
</body>
</html>
