<%@ Page Language="vb" %>

<%@ Register Assembly="Telerik.Web.UI" Namespace="Telerik.Web.UI" TagPrefix="telerik" %>
<%@ Import Namespace="System.IO" %>
<%@ Import Namespace="System.IO.FileSystemInfo" %>
<%@ Import Namespace="Prompt" %>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">

<script runat="server">
    
    Private nProjectID As Integer = 0
    Private nProgressReportID As Integer = 0
    Private strPhysicalPath As String = ""

    Private Sub Page_Load(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MyBase.Load

        Session("PageID") = "ProgressReportEdit"

        ProcLib.LoadPopupJscript(Page)
        nProjectID = Request.QueryString("ProjectID")
        nProgressReportID = Request.QueryString("ProgressReportID")

        'set up help button
        butHelp.Attributes.Add("onclick", "openPopup('help_view.aspx','pophelp',550,450,'yes');")
        butHelp.NavigateUrl = "#"
        
        lblMessage.Text = ""
        
        strPhysicalPath = ProcLib.GetCurrentAttachmentPath() & "DistrictID_" & Session("DistrictID") & "/_apprisedocs/_progressreports/ProjectID_" & nProjectID & "/"
        Dim folder As New DirectoryInfo(strPhysicalPath)
        If Not folder.Exists Then  'create the folder
            folder.Create()
        End If

        If Not IsPostBack() Then
            Using db As New ProgressReport
                db.CallingPage = Page
                db.GetProgressReportForEdit(nProjectID, nProgressReportID)
 
            End Using
            
            If lblReportFileName.Text = "(None Attached)" Then
                butRemoveFile.Visible = False
            Else
                butRemoveFile.Visible = True
            End If
            
            
            
        End If

    End Sub
     
    Private Sub butSave_Click(ByVal sender As System.Object, ByVal e As System.Web.UI.ImageClickEventArgs) Handles butSave.Click
        If Not IsDate(txtReportDate.SelectedDate) Then
            lblMessage.Text = "Please select a report date."
            Exit Sub
        End If
        If txtTitle.Text = "" Then
            lblMessage.Text = "Please enter a Title."
            Exit Sub
        End If
        
        Using db As New ProgressReport
            db.CallingPage = Page
            If uplFileName.UploadedFiles.Count > 0 Then
                Dim fSavedFile As Telerik.Web.UI.UploadedFile = uplFileName.UploadedFiles(0) ' we are only allowing one file for this upload funtion, but need the file name in the save routine
                Dim newSaveFilename As String = db.SaveProgressReport(nProjectID, nProgressReportID, txtReportDate.SelectedDate, fSavedFile.GetExtension())   'need to return unique file name for saving
                newSaveFilename = newSaveFilename.Replace("#", "")
                newSaveFilename = newSaveFilename.Replace(";", "")
                newSaveFilename = newSaveFilename.Replace(",", "")
                fSavedFile.SaveAs(Path.Combine(strPhysicalPath, newSaveFilename), True)    'overwrite if there
            
            Else     'just save the info
                Dim newSaveFilename As String = db.SaveProgressReport(nProjectID, nProgressReportID, txtReportDate.SelectedDate, "NOFILE")   'need to return unique file name for saving
            End If

        End Using

        ProcLib.CloseAndRefreshRADNoPrompt(Page)
        Session("RtnFromEdit") = True
        
        
    End Sub
    
    Private Sub butDelete_Click(ByVal sender As System.Object, ByVal e As System.Web.UI.ImageClickEventArgs) Handles butDelete.Click
     
        Using db As New ProgressReport
            db.CallingPage = Page
            db.DeleteProgressReport(nProjectID, nProgressReportID, lblReportFileName.Text)
        End Using

        Session("RtnFromEdit") = True
        ProcLib.CloseAndRefreshRADNoPrompt(Page)
    End Sub
    
    Protected Sub butRemoveFile_Click(ByVal sender As Object, ByVal e As System.Web.UI.ImageClickEventArgs)
        Using db As New ProgressReport
            db.CallingPage = Page
            db.DeleteAttachment(nProjectID, nProgressReportID, lblReportFileName.Text)
        End Using

        Session("RtnFromEdit") = True
        ProcLib.CloseAndRefreshRADNoPrompt(Page)
        
    End Sub

 
</script>

<html>
<head>
    <title>Progress Report Edit</title>
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
    <table id="Table1" cellspacing="1" cellpadding="1" width="96%" border="0">
        <tr>
            <td valign="top" colspan="2" align="right" height="6">
                <asp:HyperLink ID="butHelp" runat="server" ImageUrl="images/button_help.gif">HyperLink</asp:HyperLink>
            </td>
        </tr>
        <tr>
            <td width="75px">
                <asp:Label ID="Label9" runat="server" Text="Date:"></asp:Label>
            </td>
            <td>
                <telerik:RadDatePicker ID="txtReportDate" runat="server" TabIndex="10" Width="120px"
                    Culture="English (United States)">
                    <Calendar ID="Calendar1" runat="server" UseRowHeadersAsSelectors="False" UseColumnHeadersAsSelectors="False"
                        ViewSelectorText="x">
                        <SpecialDays>
                            <telerik:RadCalendarDay Repeatable="Today">
                                <ItemStyle BackColor="LightBlue" />
                            </telerik:RadCalendarDay>
                        </SpecialDays>
                    </Calendar>
                    <DatePopupButton ImageUrl="" HoverImageUrl="" TabIndex="10"></DatePopupButton>
                    <DateInput Skin="WebBlue" Font-Size="13px" ForeColor="Blue" Label="Begin">
                    </DateInput>
                </telerik:RadDatePicker>
            </td>
        </tr>
        <tr>
            <td width="75px">
                <asp:Label ID="Label1" runat="server" Text="Title:"></asp:Label>
            </td>
            <td>
                <asp:TextBox ID="txtTitle" runat="server" TabIndex="10" Width="250px" />
            </td>
        </tr>
        <tr>
            <td width="75px">
                <asp:Label ID="Label4" runat="server" Text="SubmittedBy:"></asp:Label>
            </td>
            <td>
                <telerik:RadComboBox ID="lstSubmittedByPMID" Skin="Windows7" Label="" runat="server"
                    TabIndex="40" DropDownWidth="420px" Width="250px" MaxHeight="125px" AppendDataBoundItems="True">
                </telerik:RadComboBox>
                <br />

            </td>
        </tr>
        <tr>
            <td colspan="2" valign="top">
                <br />
                <telerik:RadEditor ID="txtDescription" Width="98%" Height="350px" EnableDocking="False"
                    EnableEnhancedEdit="False" runat="server" SaveInFile="False" ShowHtmlMode="False"
                    ShowPreviewMode="False" ShowSubmitCancelButtons="False" UseFixedToolbar="True"
                    EditModes="Design">
                    <Tools>
                        <telerik:EditorToolGroup>
                            <telerik:EditorTool Name="Undo" />
                            <telerik:EditorTool Name="FindAndReplace" />
                            <telerik:EditorTool Name="InsertOrderedList" />
                            <telerik:EditorTool Name="Indent" />
                            <telerik:EditorTool Name="Outdent" />
                            <telerik:EditorTool Name="InsertUnorderedList" />
                            <telerik:EditorTool Name="Bold" />
                            <telerik:EditorTool Name="Copy" />
                            <telerik:EditorTool Name="Paste" />
                            <telerik:EditorTool Name="AjaxSpellCheck" />
                        </telerik:EditorToolGroup>
                    </Tools>
                    <Content>
                    </Content>
                </telerik:RadEditor>
            </td>
        </tr>
        
          <tr>
            <td height="35px" width="100px">
                <asp:Label ID="Label2" runat="server" Text="Attachment:"></asp:Label>
            </td>
            <td >
                <asp:Label ID="lblReportFileName" Class="EditDataDisplay" runat="server" Height="24px">(None Attached)</asp:Label>
                &nbsp;&nbsp;&nbsp;
                <asp:ImageButton ID="butRemoveFile" runat="server" 
                    ImageUrl="images/attachment_remove_small.gif" onclick="butRemoveFile_Click" tooltip="Delete the attachment."/>
            </td>
        </tr>
        <tr>
            <td height="35px" colspan="2">
                <telerik:radupload id="uplFileName" runat="server" controlobjectsvisibility="None"
                    enablefileinputskinning="False" readonlyfileinputs="True" allowedfileextensions=".pdf,.doc,.docx"
                    tooltip="Upload Attachement(PDF and Word Only)" />
            </td>
        </tr>
        
        
        <tr>
            <td colspan="2">
                <asp:ImageButton ID="butSave" TabIndex="40" runat="server" ImageUrl="images/button_save.gif">
                </asp:ImageButton>
                &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
                <asp:ImageButton ID="butDelete" TabIndex="400" runat="server" ImageUrl="images/button_delete.gif">
                </asp:ImageButton>
                <br />
                <asp:Label ID="lblMessage" runat="server" Text="" ForeColor="Red" Font-Bold="True"></asp:Label>
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
    </form>
</body>
</html>
