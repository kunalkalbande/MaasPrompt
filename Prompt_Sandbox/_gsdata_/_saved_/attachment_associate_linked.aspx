<%@ Page Language="vb" %>

<%@ Register Assembly="Telerik.Web.UI" Namespace="Telerik.Web.UI" TagPrefix="telerik" %>
<%@ Import Namespace="System.IO" %>
<%@ Import Namespace="Prompt" %>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">

<script runat="server">
    
    Private ParentRecordType As String = ""
    Private ParentRecID As Integer = 0
    
    Private Sub Page_Load(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MyBase.Load

        If ProcLib.CheckExpiredSessionForPopup(Page) Then    'session died so close the page - this is to prevent orphaned popups
            ProcLib.CloseAndRefresh(Page)
        End If
 
        ParentRecordType = Request.QueryString("ParentType")
        ParentRecID = Request.QueryString("ParentRecID")
        
        If Not IsPostBack Then
            
            treeFiles.Nodes.Clear()
            treeTransactions.Nodes.Clear()
            
            'Build File List
            Using db As New promptAttachment
                
                Dim nInvoices As New RadTreeNode
                With nInvoices
                    .Value = "InvoiceFiles"
                    .Text = "Invoices"
                    .ImageUrl = "images/folder.gif"

                    .Expanded = True
                End With
                
                Dim nContracts As New RadTreeNode
                With nContracts
                    .Value = "ContractFiles"
                    .Text = "Contract"
                    .ImageUrl = "images/folder.gif"
 
                    .Expanded = True
                End With
                
                Dim rs As DataTable
                rs = db.GetInvoiceFilesForAssociation(ParentRecID)
                For Each row As DataRow In rs.Rows()
                    
                    'NEED TO FILTER EXISTING ASSOCIATIONS OUT OF LIST

                    Dim nFile As New RadTreeNode
                    With nFile
                        .Value = row("AttachmentID")   'just ID means it is an attachment
                        .Text = row("FileName")
                        
                        Dim FileIcon As String = ""
                        If InStr(.Text, ".xls") > 0 Then
                            FileIcon = "prompt_xls.gif"
                        ElseIf InStr(.Text, ".pdf") > 0 Then
                            FileIcon = "prompt_pdf.gif"
                        ElseIf InStr(.Text, ".doc") > 0 Then
                            FileIcon = "prompt_doc.gif"
                        ElseIf InStr(.Text, ".zip") > 0 Then
                            FileIcon = "prompt_zip.gif"
                        Else
                            FileIcon = "prompt_page.gif"
                        End If
                        
                        .Attributes("ondblclick") = "return OpenAttachment('" & .Value & "');"
                        .ImageUrl = "images/" & FileIcon
 
                        .AllowDrag = True
                        .AllowDrop = False
                        .Expanded = True
                    End With

                    nInvoices.Nodes.Add(nFile)
                Next
                
                treeFiles.Nodes.Add(nInvoices)
                rs.Dispose()
                
                rs = db.GetContractFilesForAssociation(ParentRecID)
                For Each row As DataRow In rs.Rows()
                    
                    'NEED TO FILTER EXISTING ASSOCIATIONS OUT OF LIST

                    Dim nFile As New RadTreeNode
                    With nFile
                        .Value = row("AttachmentID")   'just ID means it is an attachment
                        .Text = row("FileName")
                        
                        Dim FileIcon As String = ""
                        If InStr(.Text, ".xls") > 0 Then
                            FileIcon = "prompt_xls.gif"
                        ElseIf InStr(.Text, ".pdf") > 0 Then
                            FileIcon = "prompt_pdf.gif"
                        ElseIf InStr(.Text, ".doc") > 0 Then
                            FileIcon = "prompt_doc.gif"
                        ElseIf InStr(.Text, ".zip") > 0 Then
                            FileIcon = "prompt_zip.gif"
                        Else
                            FileIcon = "prompt_page.gif"
                        End If
                        
                        .Attributes("ondblclick") = "return OpenAttachment('" & .Value & "');"
                        
                        
                        .ImageUrl = "images/" & FileIcon
                        .SkinID = "EIS-Prompt"
                        .CssClass = "ClientTreeNode"
                        .AllowDrag = True
                        .AllowDrop = False
                        .Expanded = True
                    End With

                    nContracts.Nodes.Add(nFile)
                Next
                
                treeFiles.Nodes.Add(nContracts)
                
                               
                
                'Build Transaction List
                Dim nParent As RadTreeNode = New RadTreeNode
                With nParent
                    .Value = "Transactions"
                    .Text = "Transactions (InvDate--Inv#--TotalAmt--Descr)"
                    .ImageUrl = "images/prompt_transactions.gif"
                    .AllowDrag = False
                    .AllowDrop = True
                    .Expanded = True
                End With

                rs = db.GetTransactionsForAssociation(ParentRecID)
                For Each row As DataRow In rs.Rows()
 
                    Dim nFile As New RadTreeNode
                    With nFile
                        .Value = "Trans" & row("TransactionID")
                        .Text = row("InvoiceDate") & " -- " & row("InvoiceNumber") & " -- " & FormatCurrency(row("TotalAmount")) & " -- " & row("Description")
                        .ImageUrl = "images/prompt_transactions.gif"
                        .Expanded = True
                        .AllowDrag = False
                        .AllowDrop = True
                    End With

                    nParent.Nodes.Add(nFile)
                  
                Next
                treeTransactions.Nodes.Add(nParent)
            End Using

        End If
        
        With RadPopups
            .Skin = "Office2007"
            .VisibleOnPageLoad = False
            Dim ww As New RadWindow
            With ww
                .ID = "ShowHelp"
                .NavigateUrl = ""
                .Title = ""
                .Width = 450
                .Height = 350
                .Modal = True
                .VisibleStatusbar = True
                .ReloadOnShow = True
                .Behaviors = WindowBehaviors.Close
            End With
            .Windows.Add(ww)
                        
            ww = New RadWindow
            With ww
                .ID = "OpenAttachment"
                .NavigateUrl = ""
                .Title = "Open Attachment"
                .Width = 400
                .Height = 300
                .Modal = True
                .VisibleStatusbar = True
                .ReloadOnShow = True
                .Behaviors = WindowBehaviors.Close
            End With
            .Windows.Add(ww)
            
        End With
        
        'set up help button
        Session("PageID") = "AttachmentsAsscociateLinked"
        butHelp.Attributes("onclick") = "return ShowHelp();"
        butHelp.NavigateUrl = "#"

    End Sub

    Protected Sub HandleDrop(ByVal sender As Object, ByVal e As RadTreeNodeDragDropEventArgs)
        Dim sourceNode As RadTreeNode = e.SourceDragNode
        Dim destNode As RadTreeNode = e.DestDragNode
        Dim dropPosition As RadTreeViewDropPosition = e.DropPosition
          
        If Not (destNode Is Nothing) Then 'drag&drop is performed between trees
            If sourceNode.TreeView.SelectedNodes.Count <= 1 Then    'single node selected
                If Not sourceNode.IsAncestorOf(destNode) Then
                    sourceNode.Owner.Nodes.Remove(sourceNode)
                    destNode.Nodes.Add(sourceNode)
                End If
            End If
        End If
            
        destNode.Expanded = True
    End Sub 'HandleDrop
    
      
    Protected Sub butClose_Click(ByVal sender As Object, ByVal e As System.Web.UI.ImageClickEventArgs)
        ProcLib.CloseOnly(Page)
    End Sub

    Protected Sub butSave_Click(ByVal sender As Object, ByVal e As System.Web.UI.ImageClickEventArgs)

        'Update the association
        Using db As New promptAttachment
            db.CallingPage = Page
            'Get the top node
            Dim topNode As RadTreeNode = treeTransactions.Nodes(0)
            For Each node As RadTreeNode In topNode.Nodes
                If InStr(node.Value, "Trans") Then    'this is a parent transaction so get the ID and any nodes below
                    If node.Nodes.Count > 0 Then
                        Dim nTransID As String = node.Value.Replace("Trans", "")
                        For Each filenode As RadTreeNode In node.Nodes()
                            Dim nAttachID As String = filenode.Value
                            db.SaveTransactionAssociation(nTransID, nAttachID)
                        Next
                    End If
                End If
                
            Next
        End Using
        Session("RtnFromEdit") = True
        ProcLib.CloseAndRefresh(Page)


    End Sub
</script>

<html>
<head>
    <title>Associate Exisiting Attachments</title>
    <meta content="Microsoft Visual Studio .NET 7.1" name="GENERATOR">
    <meta content="Visual Basic .NET 7.1" name="CODE_LANGUAGE">
    <meta content="JavaScript" name="vs_defaultClientScript">
    <meta content="http://schemas.microsoft.com/intellisense/ie5" name="vs_targetSchema">
    <link href="Styles.css" type="text/css" rel="stylesheet">

        <script type="text/javascript" language="javascript">


        function GetRadWindow() {
            var oWindow = null;
            if (window.radWindow) oWindow = window.radWindow; //Will work in Moz in all cases, including clasic dialog
            else if (window.frameElement.radWindow) oWindow = window.frameElement.radWindow; //IE (and Moz az well)

            return oWindow;
        }


        function ShowHelp()     //for help display
        {

            var oWnd = window.radopen("help_view.aspx?WinType=RAD", "ShowHelp");
            return false;
        }

        function OpenAttachment(id)     //for opening attachments 
        {

            var oWnd = window.radopen("attachment_get_linked.aspx?ID=" + id, "OpenAttachment");
            return false;
        }  
        
 	   
    </script>

</head>

<body>
   <form id="Form1" method="post" runat="server">
     <telerik:RadScriptManager ID="RadScriptManager1" runat="server" />
    <table id="Table1" style="z-index: 158; left: 8px; position: absolute; top: 8px;
        height: 2px" cellspacing="1" cellpadding="1" width="96%" border="0">
        <tr height="1">
            <td style="height: 6px" valign="top">
                <asp:Label ID="Label17" runat="server" CssClass="PageHeading" Width="275px" Height="24px">Associate Exisiting Attachment with Transaction</asp:Label>
            </td>
            <td style="height: 6px" valign="top" align="right">
                &nbsp;&nbsp;&nbsp;
                <asp:HyperLink ID="butHelp" runat="server" ImageUrl="images/button_help.gif">HyperLink</asp:HyperLink>
            </td>
        </tr>
    </table>
    <hr style="z-index: 157; left: 8px; position: absolute; top: 40px" width="95%" size="1">
    <asp:Label ID="Label1" runat="server" Style="z-index: 100; left: 12px; position: absolute;
        top: 47px" Text="Drag files from the left tree to the appropriate Transactions in the right tree to associate the attachment with the transaction. This will not move the actual file."
        Height="25px" Width="615px"></asp:Label>
    <telerik:RadTreeView ID="treeFiles" runat="server" Height="275px" Style="z-index: 101;
        left: 17px; position: absolute; top: 79px" Width="300px" DragAndDrop="True" OnNodeDrop="HandleDrop" EnableDragAndDrop="True">
        <Nodes>
            <telerik:RadTreeNode runat="server" Text="New Item">
            </telerik:RadTreeNode>
        </Nodes>
    </telerik:RadTreeView>
    <telerik:RadTreeView ID="treeTransactions" runat="server" Height="275px" Style="z-index: 102;
        left: 329px; position: absolute; top: 80px" Width="300px" DragAndDrop="True"
        OnNodeDrop="HandleDrop">
        <Nodes>
            <telerik:RadTreeNode runat="server" Text="New Item">
            </telerik:RadTreeNode>
        </Nodes>
    </telerik:RadTreeView>
    <asp:ImageButton ID="butSave" runat="server" ImageUrl="images/button_save.gif" Style="z-index: 103;
        left: 30px; position: absolute; top: 365px" TabIndex="5" OnClick="butSave_Click" />
    <asp:ImageButton ID="butClose" runat="server" ImageUrl="images/button_close.gif"
        Style="z-index: 105; left: 278px; position: absolute; top: 362px" TabIndex="5"
        OnClick="butClose_Click" />
    <telerik:RadWindowManager ID="RadPopups" runat="server">
    </telerik:RadWindowManager>
    </form>
</body>
</html>
