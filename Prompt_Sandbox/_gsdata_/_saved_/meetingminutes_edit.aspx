<%@ Page Language="vb" %>

<%@ Register Assembly="Telerik.Web.UI" Namespace="Telerik.Web.UI" TagPrefix="telerik" %>
<%@ Import Namespace="System.IO" %>
<%@ Import Namespace="System.IO.FileSystemInfo" %>
<%@ Import Namespace="Prompt" %>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">

<script runat="server">

    Private nMeetingID As Integer = 0
    Private nProjectID As Integer = 0
    Private strPhysicalPath As String = ""

    Private Sub Page_Load(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MyBase.Load

        ProcLib.CheckSession(Page)
        ProcLib.LoadPopupJscript(Page)

        Session("PageID") = "MeetingMinutesEdit"
        
        lblMessage.Text = ""

        nMeetingID = Request.QueryString("MeetingID")
        nProjectID = Request.QueryString("ProjectID")
        
        strPhysicalPath = ProcLib.GetCurrentAttachmentPath() & "DistrictID_" & Session("DistrictID") & "/_apprisedocs/_meetingminutes/ProjectID_" & nProjectID & "/"
        Dim folder As New DirectoryInfo(strPhysicalPath)
        If Not folder.Exists Then  'create the folder
            folder.Create()
        End If
        
    
        'set up help button
        butHelp.Attributes("onclick") = "return ShowHelp();"
        butHelp.NavigateUrl = "#"

        If Not IsPostBack Then
            Using db As New MeetingMinute
                db.CallingPage = Page
                If nMeetingID = 0 Then
                    butDelete.Visible = False
                Else
                    db.GetMeetingMinuteEntryForEdit(nMeetingID)
                End If
            End Using
            
            If lblMinutesFileName.Text = "(None Attached)" Then
                butRemoveFile.Visible = False
            Else
                butRemoveFile.Visible = True
            End If
            
        End If
        
        
        With RadPopups
            .Skin = "Office2007"
            .VisibleOnPageLoad = False
            Dim ww As New RadWindow
            With ww
                .ID = "ShowHelpWindow"
                .NavigateUrl = ""
                .Title = ""
                .Width = 400
                .Height = 300
                .Top = 30
                .Left = 10
                .Modal = False
                .VisibleStatusbar = True
                .ReloadOnShow = True
                .Behaviors = WindowBehaviors.Close + WindowBehaviors.Move
            End With
            .Windows.Add(ww)
           
        End With
        

        txtMeetingDate.Focus()

    End Sub
    

    Private Sub butSave_Click(ByVal sender As System.Object, ByVal e As System.Web.UI.ImageClickEventArgs) Handles butSave.Click
    
        If txtMeetingDate.SelectedDate Is Nothing Then
            lblMessage.Text = "Please enter a Meeting Date."
            Exit Sub
        End If
        
        Using db As New MeetingMinute
            db.CallingPage = Page
            If uplMinutesFileName.UploadedFiles.Count > 0 Then
                Dim fSavedFile As Telerik.Web.UI.UploadedFile = uplMinutesFileName.UploadedFiles(0) ' we are only allowing one file for this upload funtion, but need the file name in the save routine
                Dim newSaveFilename As String = db.SaveMeetingMinuteEntry(nProjectID, nMeetingID, txtMeetingDate.SelectedDate, fSavedFile.GetExtension())   'need to return unique file name for saving
                newSaveFilename = newSaveFilename.Replace("#", "")
                newSaveFilename = newSaveFilename.Replace(";", "")
                newSaveFilename = newSaveFilename.Replace(",", "")
                fSavedFile.SaveAs(Path.Combine(strPhysicalPath, newSaveFilename), True)    'overwrite if there
            
            Else     'just save the info
                Dim newSaveFilename As String = db.SaveMeetingMinuteEntry(nProjectID, nMeetingID, txtMeetingDate.SelectedDate, "NOFILE")   'need to return unique file name for saving
            End If

        End Using

        Session("RtnFromEdit") = True
        ProcLib.CloseAndRefreshRADNoPrompt(Page)
    End Sub

    Private Sub butDelete_Click(ByVal sender As System.Object, ByVal e As System.Web.UI.ImageClickEventArgs) Handles butDelete.Click
     
        Using db As New MeetingMinute
            db.CallingPage = Page
            db.DeleteMeetingMinuteEntry(nProjectID, nMeetingID, lblMinutesFileName.Text)
        End Using

        Session("RtnFromEdit") = True
        ProcLib.CloseAndRefreshRADNoPrompt(Page)
    End Sub


    Protected Sub butRemoveFile_Click(ByVal sender As Object, ByVal e As System.Web.UI.ImageClickEventArgs)
        Using db As New MeetingMinute
            db.CallingPage = Page
            db.DeleteMeetingMinuteAttachment(nProjectID, nMeetingID, lblMinutesFileName.Text)
        End Using

        Session("RtnFromEdit") = True
        ProcLib.CloseAndRefreshRADNoPrompt(Page)
        
    End Sub
</script>

<html>
<head>
    <title>Meeting Minute Entry</title>
    <link href="Styles.css" type="text/css" rel="stylesheet" />

    <script type="text/javascript" language="javascript">
        function GetRadWindow() {
            var oWindow = null;
            if (window.RadWindow) oWindow = window.RadWindow;
            else if (window.frameElement.radWindow) oWindow = window.frameElement.radWindow;
            return oWindow;
        }

        function ShowHelp()     //for help display
        {

            var oWnd = window.radopen("help_view.aspx?WinType=RAD", "ShowHelpWindow");
            return false;
        } 

 
    </script>

</head>
<body>
    <form id="Form1" method="post" runat="server">
    <telerik:radscriptmanager id="RadScriptManager1" runat="server" />
    <table id="Table1" cellspacing="0" cellpadding="0" width="97%" border="0">
        <tr>
            <td height="35px" width="100px">
                <asp:Label ID="Label9" runat="server" Text="Meeting Date:"></asp:Label>
            </td>
            <td>
                <telerik:raddatepicker id="txtMeetingDate" runat="server" width="120px" skin="Web20">
                    <DateInput runat="server" Skin="WebBlue" Font-Size="13px" ForeColor="Blue" />
                        <Calendar runat="server" UseRowHeadersAsSelectors="False" UseColumnHeadersAsSelectors="False"
                            ViewSelectorText="x" Skin="Web20">
                             <SpecialDays> 
                            <telerik:RadCalendarDay Repeatable="Today"> 
                                <ItemStyle BackColor="LightBlue" /> 
                            </telerik:RadCalendarDay> 
                        </SpecialDays> 
                        </Calendar>
                        <DatePopupButton ImageUrl="" HoverImageUrl="" />
                    </telerik:raddatepicker>
            </td>
            <td height="35px" valign="top" colspan="3" align="right">
                <asp:HyperLink ID="butHelp" runat="server" ImageUrl="images/button_help.gif">HyperLink</asp:HyperLink>
            </td>
        </tr>
        <tr>
            <td height="35px" width="100px">
                <asp:Label ID="Label2" runat="server" Text="Description:"></asp:Label>
            </td>
            <td colspan="2">
                <asp:TextBox ID="txtDescription" runat="server" Height="24px" Width="352px" TabIndex="2"
                    CssClass="EditDataDisplay"></asp:TextBox>
            </td>
        </tr>
        <tr>
            <td height="35px" width="100px">
                <asp:Label ID="Label1" runat="server" Text="Attachment:"></asp:Label>
            </td>
            <td colspan="2">
                <asp:Label ID="lblMinutesFileName" Class="EditDataDisplay" runat="server" Height="24px">(None Attached)</asp:Label>
                &nbsp;&nbsp;&nbsp;
                <asp:ImageButton ID="butRemoveFile" runat="server" 
                    ImageUrl="images/attachment_remove_small.gif" onclick="butRemoveFile_Click" tooltip="Delete the attachment."/>
            </td>
        </tr>
        <tr>
            <td height="35px" colspan="3">
                <telerik:radupload id="uplMinutesFileName" runat="server" controlobjectsvisibility="None"
                    enablefileinputskinning="False" readonlyfileinputs="True" allowedfileextensions=".pdf,.doc,.docx"
                    tooltip="Upload Attachement(PDF and Word Only)" />
            </td>
        </tr>
        <tr>
            <td height="35px">
                <asp:ImageButton ID="butSave" TabIndex="5" runat="server" ImageUrl="images/button_save.gif" />
            </td>
            <td colspan="2" align="center">
                <asp:ImageButton ID="butDelete" TabIndex="6" runat="server" ImageUrl="images/button_delete.gif" />
            </td>
        </tr>
        <tr>
            <td colspan="3">
                <asp:Label ID="lblMessage" runat="server" Height="24px" Font-Bold="True" ForeColor="Red">Error Message</asp:Label>
            </td>
        </tr>
        <tr>
            <td colspan="3">
                <telerik:RadProgressArea id="RadProgressArea1" runat="server" >
                    <Localization Uploaded="Uploaded"></Localization>
                </telerik:RadProgressArea>
                <br />
                <telerik:radprogressmanager id="RadProgressManager1" runat="server" />
            </td>
        </tr>
    </table>
    <telerik:radwindowmanager id="RadPopups" runat="server" />
    </form>
</body>
</html>
