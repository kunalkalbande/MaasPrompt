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
        
       
        t2.Skin = "Vista"
        t2.CheckBoxes = True
        
    End Sub

    Private Sub Page_Load(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MyBase.Load

        Proclib.CheckSession(Page)

        Session("PageID") = "AttachmentMove"

        Proclib.LoadPopupJscript(Page)
   
        'set up help button
        butHelp.Attributes.Add("onclick", "openPopup('help_view.aspx','pophelp',550,450,'yes');")
        butHelp.NavigateUrl = "#"

        If Not IsPostBack Then
                        
            lblMessage.Text = ""
 
            BuildSourceTree()
            LoadTargetNodes()
            Session("treeViewState") = t2.GetXml()  'save target tree config for load on demand

        End If
 
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
                .Checkable = False
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
                node.Checkable = False
                parentNode.Nodes.Add(node)
                CreateSourceNodes(directoryName, node)
                
            End If
        Next

        Dim files As String() = Directory.GetFiles(dirPath)
        Dim file As String
        For Each file In files
            If InStr(file, "_collegelogo_.jpg") = 0 Then 'fiter out the logo for the college
                Dim node As New RadTreeNode(Path.GetFileName(file))
                Dim FileFullPath As String = Path.GetFullPath(file)
                FileFullPath = FileFullPath.Replace("\", "/") 'Switch all the \ to /
                Dim FileIcon As String = "images/"
            
                'Select image depending on file type
                If InStr(file, ".xls") > 0 Then
                    FileIcon &= "prompt_xls.gif"
                ElseIf InStr(file, ".pdf") > 0 Then
                    FileIcon &= "prompt_pdf.gif"
                ElseIf InStr(file, ".doc") > 0 Then
                    FileIcon &= "prompt_doc.gif"
                ElseIf InStr(file, ".zip") > 0 Then
                    FileIcon &= "prompt_zip.gif"
                Else
                    FileIcon &= "prompt_page.gif"
                End If
                node.ImageUrl = FileIcon
            
                node.Checkable = True
                node.Value = FileFullPath      'store the file path to the value of the node
                parentNode.Nodes.Add(node)
            End If
        Next
    End Sub
    
     
    Private Sub LoadTargetNodes()
        'Loads the target nodes 
        Dim nodeCollege As RadTreeNode
        Dim nodeProject As RadTreeNode
               
        Dim strLastCollege As String = ""
        Dim strLastProject As String = ""
        Dim dt As DataTable = Att.GetTargetMoveDirectories()
        Dim row As DataRow
        For Each row In dt.Rows
               
            If Not IsDBNull(row("College")) Then
                If strLastCollege <> row("College") Then
                    nodeCollege = New RadTreeNode()
                    strLastCollege = row("College")
                    With Att
                        .CollegeID = row("CollegeID")
                        .ProjectID = 0
                        .ContractID = 0
                        .SetPath()
                    End With

                    nodeCollege = New RadTreeNode(strLastCollege)
                    With nodeCollege
                        .Value = Att.PhysicalPath
                        .ImageUrl = "images/prompt_college.gif"
                        .Checkable = True
                        .Category = "College"
                    End With
                                               
                    t2.Nodes.Add(nodeCollege) 'add a new college level

                    strLastProject = ""  'Clear project names
                    'Get the user folders and files under the college level
                    AddUserFolders(Att.PhysicalPath, nodeCollege)
                End If
                If Not IsDBNull(row("ProjectName")) Then
                    If strLastProject <> row("ProjectName") Then
                        nodeProject = New RadTreeNode()
                        strLastProject = row("ProjectName")

                        With Att
                            .ProjectID = row("ProjectID")
                            .ContractID = 0
                            .SetPath()
                        End With

                              
                        'Set project icon based on status like in nav tree
                        Dim strProjIcon As String = "prompt_project.gif"
                        If Not IsDBNull(row("Status")) Then
                            If row("Status") = "2-Proposed" Then
                                strProjIcon = "prompt_project_proposed.gif"
                            ElseIf row("Status") = "4-Cancelled" Then
                                strProjIcon = "prompt_project_cancelled.gif"
                            ElseIf row("Status") = "3-Suspended" Then
                                strProjIcon = "prompt_project_suspended.gif"
                            ElseIf row("Status") = "5-Complete" Then
                                strProjIcon = "prompt_project_complete.gif"
                            ElseIf row("Status") = "6-Consolidated" Then
                                strProjIcon = "prompt_project_consolodated.gif"
                            End If
                        End If

                        nodeProject = New RadTreeNode(strLastProject)
                        With nodeProject
                            .Value = Att.PhysicalPath
                            .Attributes.Add("ProjectID", row("ProjectID"))
                            .ImageUrl = "images/" & strProjIcon
                            .Checkable = True
                            .Category = "Project"
                            .ExpandMode = TreeNodeExpandMode.ServerSide
                        End With
                            
                        nodeCollege.Nodes.Add(nodeProject) 'add a new Project level

                        'Get the user folders and files under the project level
                        AddUserFolders(Att.PhysicalPath, nodeProject)



                    End If
                End If
            End If
                
        Next row

    End Sub
    
    Private Sub t2_NodeExpand(ByVal o As Object, ByVal e As Telerik.Web.UI.RadTreeNodeEventArgs) Handles t2.NodeExpand
        'Called when user clicks to expand project (load on demand)
        GetContractTargets(e.Node)
         
        Dim treeViewState As String = CStr(Session("treeViewState"))
        Dim cachedTreeView As New RadTreeView()
        cachedTreeView.LoadXmlString(treeViewState)

        Dim cachedNodeClicked As RadTreeNode = cachedTreeView.FindNodeByValue(e.Node.Value)
        GetContractTargets(cachedNodeClicked)
        cachedNodeClicked.ExpandMode = TreeNodeExpandMode.ClientSide
        cachedNodeClicked.Expanded = True

        Session("treeViewState") = cachedTreeView.GetXml()
    End Sub
    
    Private Sub GetContractTargets(ByVal nodeProject As RadTreeNode)
       
        'Gets the target contracts after project node is clicked (load on demand)
        Dim nProjectID As Integer = nodeProject.Attributes("ProjectID")
        If nProjectID <> 0 Then

            Dim dt As DataTable = Att.GetTargetMoveDirectoriesFromProjectID(nProjectID)
              
            Dim row As DataRow
            For Each row In dt.Rows
                If Not IsDBNull(row("ContractDescription")) Then
                    
                    'change icon depending on status
                    Dim strContractIcon As String = "prompt_contract_open.gif"
                    If Not IsDBNull(row("ContractStatus")) Then
                        If row("ContractStatus") = "3-Pending" Then
                            strContractIcon = "prompt_contract_pending.gif"
                        ElseIf row("ContractStatus") = "2-Closed" Then
                            strContractIcon = "prompt_contract_closed.gif"
                        End If
                    End If

                    Dim strContractorName As String = row("ContractorName")
                    If IsDBNull(strContractorName) Or strContractorName Is Nothing Then
                        strContractorName = ""
                    Else
                        If Len(strContractorName) > 10 Then
                            strContractorName = Left(strContractorName, 10)
                        End If
                    End If
                    Dim strContractDescription As String = row("ContractDescription")
                    If Len(strContractDescription) > 20 Then
                        strContractDescription = Left(strContractDescription, 10)
                    End If

                    strContractDescription = strContractorName & "<span class='small'>-(" & strContractDescription & ")</span>"

                    'With Att
                    '    .DistrictID = Session("DistrictID")
                    '    .ProjectID = nProjectID
                    '    .ContractID = row("ContractID")
                    '    .SetPath()
                    'End With
                    
                    With Att
                        .DistrictID = row("DistrictID")
                        .CollegeID = row("CollegeID")
                        .ProjectID = row("ProjectID")
                        .ContractID = row("ContractID")
                        .SetPath()
                    End With

                    Dim nodeContract As New RadTreeNode
                    With nodeContract
                        .Text = strContractDescription
                        .Value = Att.PhysicalPath
                        .Category = "Contract"
                        .ImageUrl = "images/" & strContractIcon
                        .Checkable = True
                    End With
                    
                    nodeProject.Nodes.Add(nodeContract) 'add a new contract level

                    AddUserFolders(Att.PhysicalPath, nodeContract) 'Get the user folders and files under the contract level
                    

                End If
        
            Next
                    
        End If
    End Sub
      
    Sub AddUserFolders(ByVal PhysicalPath As String, ByVal ParentNode As RadTreeNode)

        'This function adds the user-created folders under each target college/project/contract
        
        Dim sPath As String = ""
        Dim sFolderName As String = ""
        Dim sDir As String = ""
        Dim sNodeText As String = ""

        ' Display Subfolders.
        If Not Directory.Exists(PhysicalPath) Then
            Directory.CreateDirectory(PhysicalPath)  'create any directories that are not there
        End If
        For Each sDir In Directory.GetDirectories(PhysicalPath)
            sFolderName = Path.GetFileName(sDir)
            If InStr(sFolderName, "ProjectID_") = 0 And InStr(sFolderName, "ContractID_") = 0 And InStr(sFolderName, "BidID_") = 0 And InStr(sFolderName, "_appphotos") = 0 And InStr(sFolderName, "_vti_cnf") = 0 Then 'filter out the project/contract sub folders
                
                Dim nodeFolder As New RadTreeNode(sFolderName)
                Dim FileFullPath As String = sDir
                nodeFolder.Value = FileFullPath & "/"
                nodeFolder.ImageUrl = "images/folder.gif"
                nodeFolder.Checkable = True
                    
                ParentNode.Nodes.Add(nodeFolder) 'add folder
 
                sPath = PhysicalPath & sFolderName + "/"
                AddUserFolders(sPath, nodeFolder)
            End If
        Next
    End Sub
  
    Protected Sub Page_Unload(ByVal sender As Object, ByVal e As System.EventArgs)
        
        Att.Dispose()
        
    End Sub

  
    Protected Sub butCancel_Click1(ByVal sender As Object, ByVal e As System.Web.UI.ImageClickEventArgs)
        Proclib.CloseOnly(Page)
    End Sub

 
    Protected Sub butSave_Click(ByVal sender As Object, ByVal e As System.Web.UI.ImageClickEventArgs)

        Dim msg As String = ""

        If t1.CheckedNodes.Count = 0 Then
            msg = "Please select file(s) to move."
        End If
        If t2.CheckedNodes.Count = 0 Then
            msg = "Please select a target location to move file(s)."
        End If

        If msg = "" Then

            With Att
                .Parent = Page
                For Each node As RadTreeNode In t2.CheckedNodes
                    .TargetMovePath = node.Value   'should be only one target
                Next

                If .TargetMovePath <> "" Then
                    'Move the file(s)
                    For Each nodeSource As RadTreeNode In t1.CheckedNodes

                        Dim strSourceFilePath As String = nodeSource.Value
                        Dim strSourceFileName As String = Path.GetFileName(strSourceFilePath)

                        'strip the file name out of the path
                        strSourceFilePath = Replace(strSourceFilePath, strSourceFileName, "")

                        .FileName = strSourceFileName
                        .SourceMovePath = strSourceFilePath
                        .MoveFile()
                    Next
                End If
            End With

            Session("RtnFromEdit") = True
            Proclib.CloseAndRefresh(Page)

        Else
            lblMessage.Text = msg
        End If

    End Sub
    
    
   
    
    
    
    
    
    
</script>

<html>
<head>
    <title>Move Files</title>
    <link href="Styles.css" type="text/css" rel="stylesheet" />

        <script type="text/javascript" language="javascript">

        function AfterClientCheck(node) {   // Use to only alow single item checked at a time
            if (node.Checked) {
                for (var i = 0; i < t2.AllNodes.length; i++) {
                    if (t2.AllNodes[i] != node)
                        t2.AllNodes[i].UnCheck();
                }
            }
        }

           
    </script>

</head>
 
<body>
    <form id="Form1" method="post" runat="server">
     <telerik:RadScriptManager ID="RadScriptManager1" runat="server" />
    <table cellspacing="2" cellpadding="2" width="100%" border="0">
        <tr>
            <td style="height: 27px">
                <asp:Label ID="lblTitle" runat="server" CssClass="PageHeading" Font-Underline="True">Move Files</asp:Label>
            </td>
            <td style="height: 27px" align="right">
                <asp:HyperLink ID="butHelp" runat="server" ImageUrl="images/button_help.gif">HyperLink</asp:HyperLink>
            </td>
        </tr>
        <tr>
            <td colspan="2" style="height: 1px">
                <asp:ImageButton ID="butSave" runat="server" Text="Save" ImageUrl="images/button_save.gif"
                    OnClick="butSave_Click"></asp:ImageButton>
                &nbsp;&nbsp;&nbsp;&nbsp;
                <asp:ImageButton ID="butCancel" runat="server" Text="Cancel" ImageUrl="images/button_cancel.gif"
                    OnClick="butCancel_Click1"></asp:ImageButton>
                <br />
                <asp:Label ID="lblMessage" runat="server" CssClass="smalltext" ForeColor="Red">message</asp:Label>
            </td>
        </tr>
        <tr>
            <td class="smalltext" bgcolor="#cccccc">
                Select File(s) to Move
            </td>
            <td colspan="2" class="smalltext" bgcolor="#cccccc">
                Select New Destination
            </td>
        </tr>
        <tr>
            <td valign="top" width="50%">
                <telerik:RadTreeView ID="t1" runat="server" EnableViewState="True" ShowLineImages="True"
                    BeforeClientClick="Toggle" ExpandDelay="0">
                </telerik:RadTreeView>
            </td>
            <td valign="top" width="50%">
                <telerik:RadTreeView ID="t2" runat="server" AfterClientCheck="AfterClientCheck" ExpandDelay="0">
                </telerik:RadTreeView>
            </td>
        </tr>
    </table>
    </form>
</body>
</html>
