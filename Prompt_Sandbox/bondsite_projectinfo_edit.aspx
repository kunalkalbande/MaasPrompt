<%@ Page Language="vb" ValidateRequest="false" %>
<%--<%@ Import Namespace="System.IO.FileSystemInfo" %>
<%@ Import Namespace="System.IO" %>--%>
<%@ Register Assembly="Telerik.Web.UI" Namespace="Telerik.Web.UI" TagPrefix="telerik" %>
<%@ Import Namespace="Prompt" %>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">

<script runat="server">
    
    Private ProjectID As Integer = 0
    'Private strPhysicalPath As String = ""
    'Private strNewsReleaseFileName As String = ""
    
    Protected Sub Page_Init(ByVal sender As Object, ByVal e As System.EventArgs)
 
        Using db As New BondSite
            db.CallingPage = Page
            'Build the UDF part of the form and fill with data
            db.BuildBondProjectUDFEditForm(tblUDFs, Session("DistrictID"))
        End Using

    End Sub

    Private Sub Page_Load(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MyBase.Load

        Session("PageID") = "BondSiteProjectInfoEdit"
        ProcLib.LoadPopupJscript(Page)

        ProjectID = Request.QueryString("ProjectID")
        
        'strNewsReleaseFileName = "NewsRelease_" & ProjectID & ".pdf"

        'set up help button
        butHelp.Attributes.Add("onclick", "openPopup('help_view.aspx','pophelp',550,450,'yes');")
        butHelp.NavigateUrl = "#"
        
        'strPhysicalPath = ProcLib.GetCurrentAttachmentPath() & "DistrictID_" & Session("DistrictID") & "/_apprisedocs/_newsreleases/"
        'Dim folder As New DirectoryInfo(strPhysicalPath)
        'If Not folder.Exists Then  'create the folder
        '    folder.Create()
        'Else
        '    'look for a file
        '    Dim file As New FileInfo(strPhysicalPath & strNewsReleaseFileName)
        '    If file.Exists Then
        '        butRemoveFile.Visible = True
        '        lblReleaseFileName.Text = "Release Found."
        '    Else
        '        butRemoveFile.Visible = False
        '        lblReleaseFileName.Text = "(None Found)"
        '    End If
        'End If
       
        If Not IsPostBack() Then        'Fill the form with data
            Using db As New BondSite
                db.CallingPage = Page
                db.GetBondProjectInfoForEdit(ProjectID)
            End Using
        End If
    End Sub
     
    Private Sub butSave_Click(ByVal sender As System.Object, ByVal e As System.Web.UI.ImageClickEventArgs) Handles butSave.Click
  
        Using db As New BondSite
            db.CallingPage = Page
            db.SaveAppriseBondInfo(ProjectID)
        End Using
        
        'If uplNewsRelease.UploadedFiles.Count > 0 Then
        '    Dim fSavedFile As Telerik.Web.UI.UploadedFile = uplNewsRelease.UploadedFiles(0) ' we are only allowing one file for this upload funtion, but need the file name in the save routine
        '    fSavedFile.SaveAs(Path.Combine(strPhysicalPath, strNewsReleaseFileName), True)    'overwrite if there
        'End If

        ProcLib.CloseAndRefreshRADNoPrompt(Page)
        Session("RtnFromEdit") = True
    End Sub

 
    'Protected Sub butRemoveFile_Click(ByVal sender As Object, ByVal e As System.Web.UI.ImageClickEventArgs)

    '    Dim fileinfo As New FileInfo(strPhysicalPath & strNewsReleaseFileName)
    '    If fileinfo.Exists Then
    '        IO.File.Delete(strPhysicalPath & strNewsReleaseFileName)     'delete the file
    '    End If

    '    Session("RtnFromEdit") = True
    '    ProcLib.CloseAndRefreshRADNoPrompt(Page)

    'End Sub

</script>

<html>
<head>
    <title>Bondsite Info Edit</title>
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
    <table id="Table2">
        <tr>
            <td align="right" colspan="3">
                <asp:HyperLink ID="butHelp" runat="server" ImageUrl="images/button_help.gif">HyperLink</asp:HyperLink>
            </td>
        </tr>
        <tr>
            <td valign="top" height="6" nowrap="noWrap">
                <asp:Label ID="Label1" runat="server" Width="76px">Display Title:</asp:Label>
            </td>
            <td>
                <asp:TextBox ID="txtbondDisplayTitle" runat="server" Width="400px" CssClass="EditDataDisplay"></asp:TextBox>
                &nbsp;&nbsp;&nbsp;
            </td>
        </tr>
        <tr>
            <td colspan="2">
                <asp:Table ID="tblUDFs" runat="server" Width="100%">
                </asp:Table>
            </td>
        </tr>
<%--        <tr>
            <td>
                <asp:Label ID="Label2" runat="server" Text="News Release:"></asp:Label>
            </td>
            <td colspan="2">
                &nbsp;&nbsp;&nbsp;
                <asp:Label ID="lblReleaseFileName" Class="EditDataDisplay" runat="server" Height="24px">(None Found)</asp:Label>
                &nbsp;&nbsp;&nbsp;
                <asp:ImageButton ID="butRemoveFile" runat="server" ImageUrl="images/attachment_remove_small.gif"
                    OnClick="butRemoveFile_Click" ToolTip="Delete the uploaded News Release." />
                &nbsp;&nbsp;&nbsp;
            </td>
        </tr>--%>
    <%--    <tr>
            <td>
                &nbsp;&nbsp;&nbsp;
            </td>
            <td colspan="2">
                <telerik:RadUpload ID="uplNewsRelease" runat="server" ControlObjectsVisibility="None"
                    EnableFileInputSkinning="False" ReadOnlyFileInputs="True" AllowedFileExtensions=".pdf"
                    ToolTip="Upload News Release (PDF Only)" />
            </td>
        </tr>--%>
        <tr>
            <td style="width: 121px">
                <asp:CheckBox ID="chkPublishToWeb" runat="server" CssClass="smalltext" Text="Publish To Web"
                    Width="117px"></asp:CheckBox>
            </td>
            <td style="height: 33px; width: 945px;">
            </td>
        </tr>
        <tr>
            <td colspan="2" valign="middle" height="6">
                <asp:ImageButton ID="butSave" TabIndex="40" runat="server" ImageUrl="images/button_save.gif">
                </asp:ImageButton>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
            </td>
        </tr>
  <%--            <tr>
            <td colspan="3">
                <telerik:RadProgressArea id="RadProgressArea1" runat="server" >
                    <Localization Uploaded="Uploaded"></Localization>
                </telerik:RadProgressArea>
                <br />
                <telerik:radprogressmanager id="RadProgressManager1" runat="server" />
            </td>--%>
        </tr>
    </table>
    </form>
</body>
</html>
