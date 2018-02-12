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

        Session("PageID") = "UploadApprisePhoto"
        nPhotoID = Request.QueryString("ID")
        nProjectID = Request.QueryString("ProjectID")
        
        lblMessage.Visible = False
        
        
        strImageBasePath = "DistrictID_" & Session("DistrictID") & "/_apprisedocs/_photos/" & "ProjectID_" & nProjectID & "/"
        strImagePath = ProcLib.GetCurrentRelativeAttachmentPath() & strImageBasePath
        strRealPhotoPath = ProcLib.GetCurrentAttachmentPath() & strImageBasePath


        'set up help button
        butHelp.Attributes.Add("onclick", "openPopup('help_view.aspx','pophelp',550,450,'yes');")
        butHelp.NavigateUrl = "#"
        
        Using rs As New Photo
            If Not IsPostBack Then   'only do the following post back
                If nPhotoID = 0 Then    'add the new record
                    butDelete.Visible = False
                Else
                    rs.CallingPage = Page
                    rs.GetPhotoForEdit(nPhotoID)
                End If
            End If
        End Using
    End Sub

    Private Sub butSave_Click(ByVal sender As System.Object, ByVal e As System.Web.UI.ImageClickEventArgs) Handles butSave.Click

        If txtTitle.Text = "" Then
            lblMessage.Text = "Please enter a title for this photo."
            lblMessage.Visible = True
            Exit Sub
        End If
        
        'Save the form data first
        Using db As New Photo
            db.CallingPage = Page
            nPhotoID = db.SavePhoto(nProjectID, nPhotoID)   'need to return id of new entries
        End Using

        'save the file - we are only allowing one file for this upload funtion
        For Each File As Telerik.Web.UI.UploadedFile In RadUpload1.UploadedFiles

            strImageName = strRealPhotoPath & nPhotoID & ".jpg"

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
        
        Using db As New PromptDataHelper
        
        
            Dim strBasePhotoPath As String = ProcLib.GetCurrentAttachmentPath() & "DistrictID_" & HttpContext.Current.Session("DistrictID") & "\_apprisedocs\_photos\ProjectID_" & nProjectID & "\"
            Dim strPhotoPath As String = strBasePhotoPath & nPhotoID & ".jpg"
            Dim strThumbPhotoPath As String = strBasePhotoPath & nPhotoID & "_thumb.jpg"
            Dim strOrigPhotoPath As String = strBasePhotoPath & nPhotoID & "_ORIG.jpg"

            db.ExecuteNonQuery("DELETE FROM ApprisePhotos WHERE ApprisePhotoId = " & nPhotoID)

            'Delete photo if present
            Dim file As New FileInfo(strPhotoPath)
            If file.Exists Then
                file.Delete()
            End If

            Dim fileThumb As New FileInfo(strThumbPhotoPath)
            If fileThumb.Exists Then
                fileThumb.Delete()
            End If
            
            Dim fileOrig As New FileInfo(strOrigPhotoPath)
            If fileOrig.Exists Then
                fileOrig.Delete()
            End If
            
        End Using
        
        
        
        Session("RtnFromEdit") = True
        ProcLib.CloseAndRefreshRADNoPrompt(Page)
    End Sub
</script>

<html>
<head>
    <title>Edit Photo</title>
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
             <td colspan="2" class="pageheading" style="height: 15px" align="right">
                <asp:HyperLink ID="butHelp" runat="server" ImageUrl="images/button_help.gif">HyperLink</asp:HyperLink>
            </td>
        </tr>
        <tr>
            <td colspan="2">
                <asp:Label ID="Label2" runat="server"  CssClass="SmallText" Text="Title:"></asp:Label> <br />
                <asp:TextBox ID="txtTitle" runat="server" Height="24px" Width="352px" CssClass="EditDataDisplay"
                    MaxLength="100"></asp:TextBox>
            </td>
        </tr>
              <tr>
            <td colspan="2">
                <asp:Label ID="Label4" runat="server"  CssClass="SmallText" Text="Description:"></asp:Label> <br />
                <asp:TextBox ID="txtDescription" runat="server" Height="24px" Width="352px" CssClass="EditDataDisplay"
                    MaxLength="100"></asp:TextBox>
            </td>
        </tr>
        <tr>
                <td >
                <asp:Label ID="Label5" runat="server"  CssClass="SmallText" Text="Display Order:"></asp:Label> <br />
                
                  <telerik:RadNumericTextBox ID="txtDisplayOrder" runat="server"  TabIndex="15" SelectionOnFocus="SelectAll"
        MinValue="0" AutoPostBack="False" NumberFormat-DecimalDigits="0">
        <NumberFormat AllowRounding="True" DecimalDigits="0" ></NumberFormat>
    </telerik:RadNumericTextBox>
               
            </td>
            <td >
                <asp:CheckBox ID="chkPostToWeb" runat="server"  CssClass="SmallText" Text="Post to web"></asp:CheckBox>
            </td>
        </tr>
        <tr>
            <td colspan="2" style="height: 26px">
                <asp:Label ID="Label1"  CssClass="SmallText" runat="server">Select File (to replace or add new):</asp:Label>
            </td>
        </tr>
        <tr>
            <td colspan="2" style="height: 21px">
                <telerik:RadUpload ID="RadUpload1" runat="server" Style="z-index: 100; left: 8px;
                    top: 54px" AllowedFileExtensions=".jpg,.gif,.jpe,.png,.jpeg" ControlObjectsVisibility="None" />
            </td>
        </tr>
        <tr>
            <td>
                <asp:ImageButton ID="butSave" runat="server" ImageUrl="images/button_save.gif" /> <br />
                 <asp:Label ID="lblMessage" runat="server"  CssClass="SmallText" Text="message" 
                    Font-Bold="True" ForeColor="Red"></asp:Label> <br />
            </td>
            <td>
                <asp:ImageButton ID="butDelete" runat="server" 
                    ImageUrl="images/button_delete.gif" onclick="butDelete_Click" />
            </td>
        </tr>
    </table>
    <telerik:RadProgressArea ID="RadProgressArea1" runat="server" Style="z-index: 100;
        left: 3px; position: absolute; top: 146px;" Left="3px" />
    <telerik:RadProgressManager ID="RadProgressManager1" runat="server" />
    </form>
</body>
</html>
