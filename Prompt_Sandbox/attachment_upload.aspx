<%@ Page Language="vb" %>

<%@ Register Assembly="Telerik.Web.UI" Namespace="Telerik.Web.UI" TagPrefix="telerik" %>
<%@ Import Namespace="System.IO" %>
<%@ Import Namespace="Prompt" %>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">

<script runat="server">
    Private Att As New promptAttachment

    Protected Sub Page_PreInit(ByVal sender As Object, ByVal e As System.EventArgs)
        t1.Skin = "Vista"
        t1.CheckBoxes = True
  
    End Sub
    
    Private Sub Page_Load(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MyBase.Load

        Session("PageID") = "AttachmentUpload"

        ProcLib.CheckSession(Page)

        ProcLib.LoadPopupJscript(Page)
        
        message.Text = ""

        'set up help button
        butHelp.Attributes.Add("onclick", "openPopup('help_view.aspx','pophelp',550,450,'yes');")
        butHelp.NavigateUrl = "#"

        With Att
            .DistrictID = Session("DistrictID")
            .CollegeID = Request.QueryString("CollegeID")
            .ProjectID = Request.QueryString("ProjectID")
            .ContractID = Request.QueryString("ContractID")
            .CheckPath()
        End With

        
        If Not IsPostBack Then
            BuildSourceTree()
        End If

        
        
        lblErrorMessage.Text = ""
        
        RadUpload1.ControlObjectsVisibility = ControlObjectsVisibility.RemoveButtons Or ControlObjectsVisibility.ClearButtons Or ControlObjectsVisibility.AddButton
        


    End Sub
    
    Private Sub BuildSourceTree()
        With Att
            .DistrictID = Session("DistrictID")
            .CollegeID = Request.QueryString("CollegeID")
            .ProjectID = Request.QueryString("ProjectID")
            .ContractID = Request.QueryString("ContractID")
            .CheckPath()                         'simply checks that the attachment dir exists and if not creates it; also sets path in attachment object
            Dim rootFolder As String = Att.PhysicalPath
            Dim rootNode As New RadTreeNode(Path.GetFileName(rootFolder))
            With rootNode
                .ImageUrl = "Images/folder.gif"
                .Expanded = True
                .Checkable = True
                .Checked = True
                .Value = rootFolder
            End With

            t1.Nodes.Add(rootNode)

            CreateSourceNodes(rootFolder, rootNode)
        End With
    End Sub
    
    Private Sub CreateSourceNodes(ByVal dirPath As String, ByVal parentNode As RadTreeNode)
        'Builds the tree for the source tree
        Dim directories As String() = Directory.GetDirectories(dirPath)
        Dim directoryName As String
        For Each directoryName In directories
            'Need to get the last folder in the name and filter
            Dim sLastFolder As String = Mid(directoryName, directoryName.LastIndexOf("/") + 2)
            If InStr(sLastFolder, "ProjectID_") = 0 And InStr(sLastFolder, "ContractID_") = 0 And InStr(sLastFolder, "BidID_") = 0 And InStr(sLastFolder, "_appphotos") = 0 And InStr(sLastFolder, "_vti_cnf") = 0 Then 'filter out the project/contract sub folders
                Dim node As New RadTreeNode(Path.GetFileName(directoryName))
                node.ImageUrl = "Images/folder.gif"
                node.Checkable = True
                directoryName = directoryName.Replace("\", "/") 'Switch all the \ to /
                node.Value = directoryName & "/"
                parentNode.Nodes.Add(node)
                CreateSourceNodes(directoryName, node)
                
            End If
        Next

   
    End Sub
 
   
    Private Sub upload_ServerClick(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles upload.ServerClick
        Dim savePath As String = ""
        For Each node As RadTreeNode In t1.CheckedNodes
            savePath = node.Value   'should be only one target
            
        Next
        
        'save the file(s) 
        For Each File As Telerik.Web.UI.UploadedFile In RadUpload1.UploadedFiles

            Dim strUploadFileName As String = File.GetName
            'strUploadFileName = Path.GetFileName(strUploadFileName)

            'Remove bad characters from file name
            strUploadFileName = strUploadFileName.Replace("[", "")
            strUploadFileName = strUploadFileName.Replace("]", "")
            strUploadFileName = strUploadFileName.Replace("'", "")
            strUploadFileName = strUploadFileName.Replace("#", "-")
            'strUploadFileName = strUploadFileName.Replace("&", " and ")
            

            Dim strComments As String = Request.Form("Comments")
            Dim strDescription As String = Request.Form("Description")
            Dim strLastUpdateBy As String = Session("UserName")
            Dim strLastUpdateOn As String = Now()

            Dim bWriteFile As Boolean = True

            Dim sStoredFilePath As String  'strip off the physical prefix of full path
            sStoredFilePath = savePath.Replace(ProcLib.GetCurrentAttachmentPath(), "")

            Dim bFileExists As Boolean = False

            Dim rs As New PromptDataHelper
            rs.FillReader("SELECT * FROM attachments WHERE CollegeID = " & Att.CollegeID)
            'Check that the file does not already exist
            Dim strFullFileName As String
            While rs.Reader.Read()
                strFullFileName = rs.Reader("FilePath") & rs.Reader("FileName")
                If strFullFileName = (sStoredFilePath & strUploadFileName) Then
                    bFileExists = True
                    
                    'check for workflow use
                    If Not IsDBNull(rs.Reader("InWorkflow")) Then
                        If rs.Reader("InWorkflow") = 1 Then
                            bWriteFile = False
                            lblErrorMessage.Text = "File is currently in Workflow - Cannot overwrite. <br> Please rename the file before uploading."
                            Exit Sub
                        End If

                    End If
                    
                End If
            End While

            rs.Reader.Close()

            'If bFileExists Then
            '    If Request.Form("overwriteflag") = "warn" Then   'warn user if file exists and don't upload			
            '        message.Text = message.Text & "<br><br>File Aready Exists! <br> Please rename the file before uploading."
            '        bWriteFile = False
            '    End If
            'End If
            Dim sql As String = ""
            If bWriteFile = True Then
                If bFileExists = True Then  'update the current record
                    sql = "UPDATE Attachments SET Description = '" & strDescription & "', FilePath = '" & sStoredFilePath & "',FileSize = '" & File.ContentLength & "', Comments = '" & strComments & "', LastUpdateBy = '" & strLastUpdateBy & "', LastUpdateOn = '" & strLastUpdateOn & "' "
                    sql &= " WHERE FileName = '" & strUploadFileName & "' AND FilePath = '" & sStoredFilePath & "'"

                Else  'write a new record
                    sql = "INSERT INTO Attachments (ClientID,DistrictID, FilePath, FileName, FileSize, Description, ProjectID, CollegeID, ContractID, Comments, LastUpdateBy, LastUpdateOn) "
                    sql &= "VALUES (" & Session("ClientID") & ",'" & Att.DistrictID & "','" & sStoredFilePath & "','" & strUploadFileName & "','" & File.ContentLength & "','" & strDescription & "','" & Att.ProjectID & "','" & Att.CollegeID & "','" & Att.ContractID & "','" & strComments & "','" & strLastUpdateBy & "','" & strLastUpdateOn & "')"
                End If

                'write file info to database
                rs.ExecuteNonQuery(sql)


                'Save file to disk
                Dim strThisFullFileName As String = savePath & strUploadFileName   'Final file name/College

                File.SaveAs(strThisFullFileName, True)
            End If

        Next
        Session("RtnFromEdit") = True
        ProcLib.CloseAndRefresh(Page)


    End Sub
    
    
    
    
</script>

<html>
<head>
    <title>Upload Attachment</title>
    <link href="Styles.css" type="text/css" rel="stylesheet" />

    <script type="text/javascript" language="javascript">

        function AfterClientCheck(node) {   // Use to only alow single item checked at a time
            if (node.Checked) {
                for (var i = 0; i < t1.AllNodes.length; i++) {
                    if (t1.AllNodes[i] != node)
                        t1.AllNodes[i].UnCheck();
                }
            }
        }

           
    </script>

</head>
<body>
    <form enctype="multipart/form-data" runat="server">
    <telerik:RadScriptManager ID="RadScriptManager1" runat="server" />
    <table width="98%">
        <tr>
            <td colspan="2" align="right">
                <asp:HyperLink ID="butHelp" runat="server" ImageUrl="images/button_help.gif">HyperLink</asp:HyperLink>
            </td>
        </tr>
        <tr>
            <td class="smalltext" valign="top" style="height: 14px">
                Select File :
            </td>
            <td class="breadcrumb"  valign="top"  style="height: 14px">
                <telerik:RadUpload ID="RadUpload1" runat="server" EnableFileInputSkinning="False"
                    ControlObjectsVisibility="None" Skin="Vista">
                </telerik:RadUpload>
            </td>
        </tr>
               <tr>
            <td colspan="2">
               <hr size="1" />
            </td>
            
        </tr>
        <tr>
            <td class="smalltext">
                Description:
            </td>
            <td class="breadcrumb">
                <input id="Description" tabindex="3" type="text" size="45" name="Description" runat="server">
            </td>
        </tr>
        <tr>
            <td class="smalltext" valign="top">
                Comments:
            </td>
            <td class="breadcrumb" valign="top">
                <textarea id="Comments" tabindex="5" name="Comments" rows="5" cols="45" runat="server"></textarea>
            </td>
        </tr>
        <tr>
            <td class="breadcrumb">
                &nbsp;
            </td>
            <td class="breadcrumb">
                <input id="upload" tabindex="6" type="button" value="Upload" runat="server">
            </td>
        </tr>
        <tr>
            <td class="style1" colspan="2">
                <telerik:RadProgressManager ID="RadProgressManager1" runat="server" />
                <telerik:RadProgressArea ID="RadProgressArea1" runat="server">
                </telerik:RadProgressArea>
                <br>
                <asp:Label ID="lblErrorMessage" runat="server" ForeColor="Red" CssClass="smalltext">ErrorMessage</asp:Label><br />
                <asp:Label ID="message" runat="server" ForeColor="Red" CssClass="smalltext">message</asp:Label>
                <telerik:RadTreeView ID="t1" runat="server" EnableViewState="True" ShowLineImages="True"
                    BeforeClientClick="Toggle" AfterClientCheck="AfterClientCheck" ExpandDelay="0">
                </telerik:RadTreeView>
            </td>
            </td>
        </tr>
    </table>
    </form>
</body>
</html>
