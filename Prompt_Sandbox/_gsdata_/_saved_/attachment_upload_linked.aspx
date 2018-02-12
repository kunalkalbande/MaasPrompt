<%@ Page Language="vb" %>

<%@ Register Assembly="Telerik.Web.UI" Namespace="Telerik.Web.UI" TagPrefix="telerik" %>
<%@ Import Namespace="System.IO" %>
<%@ Import Namespace="Prompt" %>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">

<script runat="server">
    
    Private sParentType As String = ""
    Private nParentRecID As Integer = 0
    
    Private Sub Page_Load(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MyBase.Load
        
        ProcLib.LoadPopupJscript(Page)
        Session("PageID") = "LinkedAttachmentUpload"
        
        lblMessage.Text = ""

        If ProcLib.CheckExpiredSessionForPopup(Page) Then    'session died so close the page - this is to prevent orphaned popups
            ProcLib.CloseAndRefresh(Page)
        End If
        
        sParentType = Request.QueryString("ParentType")
        nParentRecID = Request.QueryString("ParentRecID")
        
        BuildMenu()

        
        RadUpload1.ControlObjectsVisibility = ControlObjectsVisibility.RemoveButtons Or ControlObjectsVisibility.ClearButtons Or ControlObjectsVisibility.AddButton
   

    End Sub
    
       
    Protected Sub butClose_Click(ByVal sender As Object, ByVal e As System.EventArgs)
        ProcLib.CloseOnlyRAD(Page)
        
    End Sub

    Protected Sub butUpload_Click(ByVal sender As Object, ByVal e As System.EventArgs)
        
        'save the file(s)
        For Each FileT As Telerik.Web.UI.UploadedFile In RadUpload1.UploadedFiles
            
            Dim strUploadFileName As String = FileT.GetName
            
            'Remove bad characters from file name
            strUploadFileName = strUploadFileName.Replace("[", "")
            strUploadFileName = strUploadFileName.Replace("]", "")
            strUploadFileName = strUploadFileName.Replace("'", "")
            strUploadFileName = strUploadFileName.Replace("#", "-")
            ' strUploadFileName = strUploadFileName.Replace("&", "")

            Using db As New promptAttachment
                With db
                    .CallingPage = Page
                    .Description = Request.Form("Description")
                    .Comments = Request.Form("Comments")
                    .UploadedFileName = strUploadFileName   'do not use the "filename" property as it fails in ie7
                    .ParentRecID = nParentRecID
                    .ParentType = sParentType
                    
                    .SetFullLinkedPhysicalFilePathAndFileName()

                End With
                
                Try         'don't save the db record if the file write fails
                    
                    'See if the file already exists
                    If File.Exists(db.FullPhysicalFilePathAndFileName) And db.DisableOverwrite = True Then
                        lblMessage.Text = "File Exists and is currently in Workflow - cannot be Overwritten."
                        Exit Sub
                        
                        'TODO: Detecting Overwrite conflicts is complicated in Web Apps - need to relook at this one.
                        
                        ' ElseIf File.Exists(db.FullPhysicalFilePathAndFileName) And db.DisableOverwrite = False Then
                        'lblMessage.Text = "<script language='javascript'> window.onload = function(){radconfirm('Do you want to replace existing file?', '',330, 210,'','File Already Exists');}</" & "script>"
                        'Exit Sub
                    Else
                        
                        FileT.SaveAs(db.FullPhysicalFilePathAndFileName, True)
                    End If

                Catch
                    lblMessage.Text = "ERROR: Upload Failed - Please try again or contact tech support."
                    Exit Sub
                End Try
                
                db.SaveLinkedFileToDatabase()
            
            End Using

        Next
        
        Response.Redirect("attachments_manage_linked.aspx?ParentRecID=" & nParentRecID & "&ParentType=" & sParentType)
        'ProcLib.CloseAndRefreshRAD(Page)

    End Sub
    
    Protected Sub BuildMenu()
        RadMenu1.Width = Unit.Percentage(100)

        Dim nTopLineHeight As Unit = Unit.Pixel(27)
        Dim nTopMenuItemWidths As Unit = Unit.Pixel(75)

        With RadMenu1
            .Items.Clear()
        End With
        Dim mm As Telerik.Web.UI.RadMenuItem

        '**********************************************
        mm = New Telerik.Web.UI.RadMenuItem
        With mm
            .Height = nTopLineHeight
            .Text = "Back"
            .NavigateUrl = "attachments_manage_linked.aspx?ParentRecID=" & nParentRecID & "&ParentType=" & sParentType
            .ImageUrl = "images/arrow_left_green.png"
            .Width = nTopMenuItemWidths
        End With
        RadMenu1.Items.Add(mm)
        

        mm = New Telerik.Web.UI.RadMenuItem
        With mm
            .Text = "Exit"
            .Height = nTopLineHeight
            .Width = nTopMenuItemWidths
            .ImageUrl = "images/exit.png"
        End With
        RadMenu1.Items.Add(mm)

        mm = New Telerik.Web.UI.RadMenuItem
        With mm
            .Text = "Help"
            .ImageUrl = "images/help.png"
            .Attributes("onclick") = "openPopup('help_view.aspx','pophelp',550,450,'yes');"
            .PostBack = False
            .Height = nTopLineHeight
            .Width = nTopMenuItemWidths
        End With
        RadMenu1.Items.Add(mm)


    End Sub
    
    Protected Sub RadMenu1_ItemClick(ByVal sender As Object, ByVal e As Telerik.Web.UI.RadMenuEventArgs) Handles RadMenu1.ItemClick
        Dim Item As Telerik.Web.UI.RadMenuItem = e.Item
        If Item.Text = "Exit" Then
            ProcLib.CloseOnlyRAD(Page)
        End If

    End Sub
    
    
</script>

<html>
<head>
    <title>Upload Linked Attachment</title>
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
   
    <form enctype="multipart/form-data" runat="server"> 
    <telerik:RadScriptManager ID="RadScriptManager1" runat="server" />
    <telerik:RadMenu ID="RadMenu1" runat="server" DefaultGroupSettings-Flow="Horizontal"
        Skin="Vista">
        <DefaultGroupSettings Flow="Horizontal"></DefaultGroupSettings>
    </telerik:RadMenu>
    <br />
    <table width="95%">
      
        <tr>
            <td colspan="2">
                <asp:Label ID="lblMessage" runat="server" Text="message" CssClass="smalltext" Font-Bold="True"
                    ForeColor="Red"></asp:Label>
            </td>
        </tr>
        <tr>
            <td class="ViewDataDisplay" style="height: 14px" width="40px" colspan="2">
                <telerik:RadUpload ID="RadUpload1" runat="server" EnableFileInputSkinning="False"
                    ControlObjectsVisibility="AddButton">
                </telerik:RadUpload>
            </td>
        </tr>
         <tr>
            <td colspan="2">
               <hr size="1" />
            </td>
            
        </tr>
        <tr>
            <td class="smalltext" colspan="2">
                Description:
                <br />
                <input id="Description" tabindex="3" type="text" size="35" name="Description" runat="server" />
            </td>
        </tr>
        <tr>
            <td class="smalltext" valign="top" colspan="2">
                Comments:
                <br />
                <textarea id="Comments" tabindex="5" name="Comments" rows="2" cols="35" runat="server"></textarea>
            </td>
        </tr>
        <tr>
            <td>
                <asp:Button ID="butUpload" runat="server" Text="Upload" OnClick="butUpload_Click" />
            </td>
            <td>
                <asp:Button ID="butClose" runat="server" Text="Close" OnClick="butClose_Click" />
            </td>
        </tr>
        <tr>
            <td colspan="2">
                <telerik:RadProgressManager ID="RadProgressManager1" runat="server" />
                <telerik:RadProgressArea ID="RadProgressArea1" runat="server">
                </telerik:RadProgressArea>
            </td>
        </tr>
    </table>
    <telerik:RadWindowManager ID="MasterPopups" runat="server">
    </telerik:RadWindowManager>
    </form>
</body>
</html>
