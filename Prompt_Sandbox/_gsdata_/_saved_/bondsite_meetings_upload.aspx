<%@ Page Language="vb" %>

<%@ Register Assembly="Telerik.Web.UI" Namespace="Telerik.Web.UI" TagPrefix="telerik" %>
<%@ Import Namespace="System.IO" %>
<%@ Import Namespace="System.IO.FileSystemInfo" %>
<%@ Import Namespace="Prompt" %>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">

<script runat="server">

    'TODO NOTE: The upload control on this page is currently old version - this is because the upload progress ajax element in the web.config 
    '       must be upgraded, which means that all upload controls need to be migrated at the same time.


    Private nMeetingID As Integer = 0
    Private sUploadType As String = ""

    Private strPhysicalPath As String = ""
    Private strRelativePath As String = ""

    Private Sub Page_Load(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MyBase.Load
        
        If ProcLib.CheckExpiredSessionForPopup(Page) Then
            ProcLib.CloseAndRefreshRAD(Page)
        End If
       

        ProcLib.LoadPopupJscript(Page)
        Session("PageID") = "UploadAppriseAgendaMinutes"
        
        nMeetingID = Request.QueryString("MeetingID")
        sUploadType = Request.QueryString("UploadType")
 

        strPhysicalPath = ProcLib.GetCurrentAttachmentPath() & "DistrictID_" & Session("DistrictID") & "/_apprisedocs/_bondsite/_meetingID_" & nMeetingID
        Dim folder As New DirectoryInfo(strPhysicalPath)
        If Not folder.Exists Then  'create the folder
            folder.Create()
        End If
        
        RadUpload1.OverwriteExistingFiles = True
        RadUpload1.TargetPhysicalFolder = strPhysicalPath

        'set up help button
        butHelp.Attributes.Add("onclick", "openPopup('help_view.aspx','pophelp',550,450,'yes');")
        butHelp.NavigateUrl = "#"
 
    End Sub

    Private Sub butUpload_Click(ByVal sender As System.Object, ByVal e As System.Web.UI.ImageClickEventArgs) Handles butUpload.Click

        'save the file - we are only allowing one file for this upload funtion
        For Each File As Telerik.Web.UI.UploadedFile In RadUpload1.UploadedFiles
            Using db As New BondSite
            
                db.SaveBondsiteAgendaMinutesPath(nMeetingID, File.GetName, sUploadType)
            End Using

        Next
        Session("RtnFromEdit") = True
        ProcLib.CloseAndRefreshRADNoPrompt(Page)

    End Sub

</script>

<html>
<head>
    <title>Bondsite Agenda/Minutes Upload</title>
    <meta content="Microsoft Visual Studio .NET 7.1" name="GENERATOR" />
    <meta content="Visual Basic .NET 7.1" name="CODE_LANGUAGE" />
    <meta content="JavaScript" name="vs_defaultClientScript" />
    <meta content="http://schemas.microsoft.com/intellisense/ie5" name="vs_targetSchema" />
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
                Upload Agenda/Minutes
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
                    top: 54px" AllowedFileExtensions=".docx,.doc,.pdf" ControlObjectsVisibility="None"
                    EnableFileInputSkinning="False" />
            </td>
        </tr>
        <tr>
            <td colspan="2">
                <asp:ImageButton ID="butUpload" runat="server" ImageUrl="images/button_save.gif">
                </asp:ImageButton>
            </td>
        </tr>
        <tr>
            <td colspan="2" align="left">
                <br />
                &nbsp;
            </td>
        </tr>
    </table>
    <telerik:RadProgressArea ID="RadProgressArea1" runat="server" Style="z-index: 100;
        left: 3px; position: absolute; top: 146px;" Left="3px" />
    <telerik:RadProgressManager ID="RadProgressManager1" runat="server" />
    </form>
</body>
</html>
