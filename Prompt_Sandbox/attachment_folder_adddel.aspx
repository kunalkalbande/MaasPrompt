<%@ Page Language="vb" %>

<%@ Import Namespace="System.IO" %>
<%@ Import Namespace="Prompt" %>
<%@ Register Assembly="Telerik.Web.UI" Namespace="Telerik.Web.UI" TagPrefix="telerik" %>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">

<script runat="server">
    
    Private Att As New promptAttachment
    
  Protected Sub Page_PreInit(ByVal sender As Object, ByVal e As System.EventArgs)
        
        t1.Skin = "Vista"
        t1.CheckBoxes = True
  
    End Sub
    
    Private Sub Page_Load(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MyBase.Load
        Proclib.CheckSession(Page)

        Proclib.LoadPopupJscript(Page)

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

        lblTitle.CssClass = "smalltext"
        lblCreate.CssClass = "smalltext"

        If Request.QueryString("action") = "create" Then
            lblTitle.Text = "Please select a location for the new folder:"
            butSave.ImageUrl = "images/button_save.gif"
            Session("PageID") = "AttachmentFolderCreate"
            pageTitle.Innertext = "Create Folder"
        Else
            lblTitle.Text = "Please select the folder to delete:"
            butSave.ImageUrl = "images/button_delete.gif"
            lblCreate.Visible = False
            txtNewFolder.Visible = False
            Session("PageID") = "AttachmentFolderDelete"
            pageTitle.InnerText = "Delete Folder"
        End If

        If Not IsPostBack Then
            BuildSourceTree()
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
                .Checkable = True
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
  
    Private Sub butSave_Click(ByVal sender As System.Object, ByVal e As System.Web.UI.ImageClickEventArgs) Handles butSave.Click
   
        Dim savePath As String = ""
        For Each node As RadTreeNode In t1.CheckedNodes
            savePath = node.Value   'should be only one target
        Next
        
        If savePath <> "" then
            If Request.QueryString("action") = "create" Then
                Dim sFolder As String = txtNewFolder.Text
                sFolder = sFolder.Replace("[", "")
                sFolder = sFolder.Replace("]", "")
                sFolder = sFolder.Replace("'", "")
                sFolder = sFolder.Replace("#", "-")
                Directory.CreateDirectory(savePath & sFolder)
            Else
                Try
                    Directory.Delete(savePath, False)
                Catch ex As Exception

                    Dim alertmessage As String
                    alertmessage = "Folder is not empty. Please delete file(s) before deleting folder."
                    ProcLib.CreateMessageAlert(Me, alertmessage, "alertKey")

                End Try
            End If
        
                Session("RtnFromEdit") = True
                Proclib.CloseAndRefresh(Page)
        
        End If
    End Sub
    
    
</script>

<html>
<head>
    <title runat="server" id="pageTitle">Attachment AddDel</title>
    <meta content="Microsoft Visual Studio .NET 7.1" name="GENERATOR">
    <meta content="Visual Basic .NET 7.1" name="CODE_LANGUAGE">
    <meta content="JavaScript" name="vs_defaultClientScript">
    <meta content="http://schemas.microsoft.com/intellisense/ie5" name="vs_targetSchema">
    <link href="Styles.css" type="text/css" rel="stylesheet">

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
    <form id="Form1" method="post" runat="server">
     <telerik:RadScriptManager ID="RadScriptManager1" runat="server" />
    <table id="Table1" cellspacing="1" cellpadding="3" width="96%" border="0">
        <tr>
            <td>
                <asp:Label ID="lblTitle" runat="server">Label</asp:Label>
            </td>
            <td align="right">
                <asp:HyperLink ID="butHelp" runat="server" ImageUrl="images/button_help.gif">HyperLink</asp:HyperLink>
            </td>
        </tr>
        <tr>
            <td colspan="2">
                <telerik:RadTreeView ID="t1" runat="server" EnableViewState="True" ShowLineImages="True"
                    BeforeClientClick="Toggle" AfterClientCheck="AfterClientCheck" ExpandDelay="0">
                </telerik:RadTreeView>
            </td>
        </tr>
        <tr>
            <td colspan="2">
                <asp:Label ID="lblCreate" runat="server">Enter Name for New Folder:</asp:Label><asp:TextBox
                    ID="txtNewFolder" runat="server" CssClass="EditDataDisplay"></asp:TextBox>
            </td>
        </tr>
        <tr>
            <td colspan="2">
                <asp:ImageButton ID="butSave" TabIndex="5" runat="server" ImageUrl="images/button_save.gif">
                </asp:ImageButton>
            </td>
        </tr>
    </table>
    </form>
</body>
</html>
