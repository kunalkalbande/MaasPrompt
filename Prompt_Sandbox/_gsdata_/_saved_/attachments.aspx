<%@ Page Language="VB" MasterPageFile="~/content.master" Title="" %>
<%@ Register Assembly="Telerik.Web.UI" Namespace="Telerik.Web.UI" TagPrefix="telerik" %>
<%@ Import Namespace="Prompt" %>
<%@ Import Namespace="System.IO" %>
<%@ Import Namespace="System.Web.HTTPUtility" %>

<script runat="server">
    
    Private bAllowEdit As Boolean = False
    Private CurrentView As String = ""
    Private nProjectID As Integer = 0
    Private nCollegeID As Integer = 0
    Private nContractID As Integer = 0
    Private RecID As Integer = 0
    
    Private Att As New promptAttachment

    Private Sub Page_Load(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MyBase.Load

        ProcLib.CheckSession(Page)
        ProcLib.LoadPopupJscript(Page)

        ''set up help button
        Session("PageID") = "Notes"
        CurrentView = Request.QueryString("view")
        nProjectID = Request.QueryString("ProjectID")
        nCollegeID = Request.QueryString("CollegeID")
        nContractID = Request.QueryString("ContractID")
       
        
        Dim masterTabs As RadTabStrip = Master.FindControl("tabMain")
        Session("CurrentTab") = "Attachments"
        For Each radTab In masterTabs.GetAllTabs
            If radTab.Value = "Attachments" Then
                radTab.Selected = True
                radTab.SelectParents()
                Exit For
            End If
        Next
        
        Session("PageID") = "AttachmentsView"
        
        lblErrorMessage.Visible = False
        
        'Get the parms to build the file paths
        Using rs As New PromptDataHelper

            Using db As New EISSecurity
                db.CollegeID = Session("CollegeID")
                
                Select Case CurrentView
                    Case "college"
                        'college is easy as it is passed
                        db.ProjectID = nProjectID
                        bAllowEdit = db.FindUserPermission("CollegeAttachments", "Write")
                        

                    Case "project"
                        db.ProjectID = nProjectID
                        bAllowEdit = db.FindUserPermission("ProjectAttachments", "Write")

                    Case "contract"
                        rs.FillReader("SELECT CollegeID,ProjectID FROM Contracts WHERE ContractID = " & nContractID)
                        db.ProjectID = nProjectID
                        bAllowEdit = db.FindUserPermission("ContractAttachments", "Write")

                End Select
            End Using
            

            tblAttach.Rows.Clear()
            tblAttach.Width = Unit.Percentage(100)

            If bAllowEdit Then   'allow add and build menu

                Dim strParms As String
                'build querystring to tell upload page where base path is
                strParms = "?CollegeID=" & nCollegeID & "&ProjectID=" & nProjectID & "&ContractID=" & nContractID

                Dim r1 As New TableRow
                Dim r1c1 As New TableCell

                Dim tblMenu As New Table
                tblMenu.CellPadding = 5
                tblMenu.Width = Unit.Pixel(200)
                Dim r2 As New TableRow
                Dim r2c1 As New TableCell
                Dim r2c2 As New TableCell
                Dim r2c3 As New TableCell
                Dim r2c4 As New TableCell

                Dim ctrl1 As New HyperLink
                With ctrl1
                    .Attributes.Add("onclick", "openPopup('attachment_folder_adddel.aspx" & strParms & "&action=create','foladd',500,450,'yes');")
                    .NavigateUrl = "#"  'dummy value so that link line shows
                    .ImageUrl = "images/attachment_addfolder.gif"
                    .ID = "img1"
                End With
                r2c1.Controls.Add(ctrl1)

                Dim ctrl2 As New HyperLink
                With ctrl2
                    .Attributes.Add("onclick", "openPopup('attachment_folder_adddel.aspx" & strParms & "&action=delete','foldel',500,450,'yes');")
                    .NavigateUrl = "#"  'dummy value so that link line shows
                    .ImageUrl = "images/attachment_delfolder.gif"
                    .ID = "img2"
                End With
                r2c2.Controls.Add(ctrl2)


                Dim ctrl3 As New HyperLink
                With ctrl3
                    .Attributes.Add("onclick", "openPopup('attachment_upload.aspx" & strParms & "','upld',500,450,'yes');")
                    .NavigateUrl = "#"  'dummy value so that link line shows
                    .ImageUrl = "images/attachment_uploadfile.gif"
                    .ID = "img3"
                End With
                r2c3.Controls.Add(ctrl3)

                Dim ctrl4 As New HyperLink
                With ctrl4
                    .Attributes.Add("onclick", "openPopup('attachment_move.aspx" & strParms & "','attmove',600,550,'yes');")
                    .NavigateUrl = "#"  'dummy value so that link line shows
                    .ImageUrl = "images/attachment_movefile.gif"
                    .ID = "img4"
                End With
                r2c4.Controls.Add(ctrl4)

            
                With r2
                    .Cells.Add(r2c1)
                    .Cells.Add(r2c2)
                    .Cells.Add(r2c3)
                    .Cells.Add(r2c4)
                End With

                tblMenu.Rows.Add(r2)

                'now add the menu table to the main table first row
                With r1c1
                    .Controls.Add(tblMenu)
                    .HorizontalAlign = HorizontalAlign.Left
                End With
                r1.Cells.Add(r1c1)
                tblAttach.Rows.Add(r1)

                'Add line below menu 
            End If
        
        End Using

        BuildSourceTree()

    End Sub
    
    Private Sub BuildSourceTree()
        
        t1.Nodes.Clear()
        
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
                directoryName = directoryName.Replace("\", "/") 'Switch all the \ to /
                node.Value = directoryName & "/"
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
                
                With Att
                    .FileName = file
                    .PhysicalPath = FileFullPath
                End With
            
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
                
                
                Dim sParm As String = UrlEncode(Att.PhysicalPath)
                'Dim sDownloadLink As New Label
                'sDownloadLink.Text = "<a href=""javascript:;"" onClick=""openPopup('attachment_get.aspx?file=" & sParm & "','att_get',550,400,'yes');"">" & Path.GetFileName(file) & "</a>"

                'Allow direct download
                Dim sHref As String = Att.RelativePath
                Dim sDownloadLink As New HyperLink
                sDownloadLink.Text = Path.GetFileName(file)
                sDownloadLink.NavigateUrl = sHref
                sDownloadLink.Target = "_new"
                

 
                Dim sText As New Label
                sText.Text = "&nbsp;&nbsp;&nbsp; (" & Att.FileSize & " &nbsp;&nbsp;&nbsp; " & Att.LastModified & ")"
                
                Dim sEditLink As New Label
                sEditLink.Text = "&nbsp;&nbsp;<a href=""javascript:;"" onClick=""openPopup('attachment_edit.aspx?allowedit=" & bAllowEdit & "&file=" & sParm & "','att_edit',550,400,'yes');""><image src='images/prompt_page.gif' border=0></a>"

                node.Controls.Add(sDownloadLink)
                node.Controls.Add(sText)

                'If bAllowEdit Then
                node.Controls.Add(sEditLink)
                'End If
                 
                parentNode.Nodes.Add(node)
            End If
        Next
    End Sub
    

</script>

<asp:Content ID="Content1" ContentPlaceHolderID="mainBody" runat="Server">
    <telerik:RadWindowManager ID="contentPopup" runat="server">
    </telerik:RadWindowManager>
    <br />
<div id="contentwrapper">
    <div id="contentcolumn">
        <div class="innertube">
            <asp:Table ID="tblAttach" runat="server">
            </asp:Table>
            <asp:Label ID="lblErrorMessage" runat="server" ForeColor="Red" CssClass="smalltext">ErrorMessage</asp:Label><br />
            <telerik:RadTreeView ID="t1" runat="server" EnableViewState="True" ShowLineImages="True" Slin="Vista" CheckBoxes="false"
                BeforeClientClick="Toggle" ExpandDelay="0">
            </telerik:RadTreeView>
        </div>
    </div>
</div>

</asp:Content>
