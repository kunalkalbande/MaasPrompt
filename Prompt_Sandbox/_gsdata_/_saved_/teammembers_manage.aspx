<%@ Page Language="vb" ValidateRequest="false" %>
<%@ Register Assembly="Telerik.Web.UI" Namespace="Telerik.Web.UI" TagPrefix="telerik" %>
<%@ Import Namespace="Prompt" %>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">

<script runat="server">
    Private nProjectID As Integer = 0
    Private sFilter As String = ""
    
    Private Sub Page_Load(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MyBase.Load

        ProcLib.CheckSession(Page)
        ProcLib.LoadPopupJscript(Page)

        'set up help button
        Session("PageID") = "ManageTeamMembers"
        'butHelp.Attributes.Add("onclick", "openPopup('help_view.aspx','pophelp',550,450,'yes');")
        'butHelp.NavigateUrl = "#"

        nProjectID = Request.QueryString("ProjectID")
        
        If Not IsPostBack Then
            Using db As New TeamMember
                db.BuildSourceTree(treeSelectFrom)
                db.GetExistingMembersToManage(treeSelectedMembers, nProjectID)
            End Using
        End If
        
        'Configure the Popup Window(s)
        With contentPopups
            .VisibleOnPageLoad = False
            .Skin = "Windows7"
            Dim ww As New Telerik.Web.UI.RadWindow
            
            ww = New Telerik.Web.UI.RadWindow
            With ww
                .ID = "EditTeamMemberWindow"
                .NavigateUrl = ""
                .Title = ""
                .Width = 525
                .Height = 650
                .Modal = True
                .VisibleStatusbar = False
                .ReloadOnShow = True
            End With
            .Windows.Add(ww)
            
        End With
        

    End Sub
    
   
    Private Sub butSave_Click(ByVal sender As System.Object, ByVal e As System.Web.UI.ImageClickEventArgs) Handles butSave.Click

        Using db As New TeamMember
            db.CallingPage = Page
            db.SaveTeamMembers(treeSelectedMembers, nProjectID)
        End Using

        Session("RtnFromEdit") = True
        ProcLib.CloseAndRefreshRADNoPrompt(Page)
       
       
    End Sub
    
    Private Sub butClose_Click(ByVal sender As System.Object, ByVal e As System.Web.UI.ImageClickEventArgs) Handles butClose.Click
        ProcLib.CloseOnlyRAD(Page)
    End Sub
    
       
    Protected Sub treeSelectedMembers_NodeDrop(ByVal sender As Object, ByVal e As Telerik.Web.UI.RadTreeNodeDragDropEventArgs)
        Dim sourceNode As RadTreeNode = e.SourceDragNode
        Dim destNode As RadTreeNode = e.DestDragNode
        Dim dropPosition As RadTreeViewDropPosition = e.DropPosition
        sourceNode.AllowDrop = True   'Once this is in the Selected Members then we need to be able to move it around
        If Not IsNothing(destNode) Then
            If sourceNode.TreeView.SelectedNodes.Count <= 1 Then
                PerformDragAndDrop(dropPosition, sourceNode, destNode)
            ElseIf sourceNode.TreeView.SelectedNodes.Count > 1 Then
                For Each node As RadTreeNode In sourceNode.TreeView.SelectedNodes
                    PerformDragAndDrop(dropPosition, node, destNode)
                Next
            End If
            destNode.Expanded = True
            sourceNode.TreeView.ClearSelectedNodes()
            
        Else        'The target tree is empty
            If sourceNode.Attributes("Type") = "ProjectTeam" Then                'Add whole scheme to Selected
                Dim tempTree As New RadTreeView
                tempTree.LoadXmlString(treeSelectFrom.GetXml())         'clone the tree
                For Each node As RadTreeNode In sourceNode.Nodes
                    treeSelectedMembers.Nodes.Add(tempTree.FindNodeByValue(node.Value))
                Next
                
            Else            'Simply add it to the root
                sourceNode.Owner.Nodes.Remove(sourceNode)
                treeSelectedMembers.Nodes.Add(sourceNode)
            End If
 
        End If
    End Sub
    
       
    Private Shared Sub PerformDragAndDrop(ByVal dropPosition As RadTreeViewDropPosition, ByVal sourceNode As RadTreeNode, ByVal destNode As RadTreeNode)
 
        Select Case dropPosition
            Case RadTreeViewDropPosition.Over
                ' child
                If Not sourceNode.IsAncestorOf(destNode) Then
                    If sourceNode.Attributes("Type") = destNode.Attributes("Type") Then     'these are same so reorder
                        'sourceNode.Owner.Nodes.Remove(sourceNode)
                        destNode.InsertBefore(sourceNode)
                    ElseIf sourceNode.Attributes("Type") = "TeamGroup" And destNode.Attributes("Type") = "TeamMember" Then     'cannot drop a group on a member
                        Exit Sub
                    Else
                        sourceNode.Owner.Nodes.Remove(sourceNode)
                        destNode.Nodes.Add(sourceNode)
                    End If
  
                End If
                Exit Select
            Case RadTreeViewDropPosition.Above
                ' sibling - above
                sourceNode.Owner.Nodes.Remove(sourceNode)
                destNode.InsertBefore(sourceNode)
                sourceNode.AllowDrop = True
                Exit Select
            Case RadTreeViewDropPosition.Below
                ' sibling - below
                sourceNode.Owner.Nodes.Remove(sourceNode)
                destNode.InsertAfter(sourceNode)
                Exit Select
        End Select

    End Sub

  
 
    Protected Sub butRemove_Click(ByVal sender As Object, ByVal e As System.EventArgs)
        For Each node As RadTreeNode In treeSelectedMembers.GetAllNodes
            If node.Selected = True Then
                node.Remove()
                Exit Sub
            End If
            
        Next
    End Sub
    
    Protected Sub butAddGroup_Click(ByVal sender As Object, ByVal e As System.EventArgs)
        Dim node As New RadTreeNode
        With node
            .Text = "(new Team Group - click to edit)"
            .ImageUrl = "images/group_16x.png"
            .Attributes.Add("Type", "TeamGroup")
            .AllowDrop = True
            .AllowEdit = True
            .AllowDrag = True
        End With
        treeSelectedMembers.Nodes.Add(node)
    End Sub
    
       
</script>

<html>
<head>
    <title>Manager Team Members</title>
    <link href="Styles.css" type="text/css" rel="stylesheet" />

    <script type="text/javascript" language="javascript">

        function GetRadWindow() {
            var oWindow = null;
            if (window.RadWindow) oWindow = window.RadWindow;
            else if (window.frameElement.radWindow) oWindow = window.frameElement.radWindow;
            return oWindow;
        }

//        function EditTeamMember(id, projectid) {
//            var oWnd = window.radopen("teammember_edit.aspx?TeamMemberID=" + id + "&ProjectID=" + projectid, "EditTeamMemberWindow");
//            return false;
//        }


        function ClientNodeEdited(sender, args) {
            sender.trackChanges();
            args.get_node().set_text(args.get_node().get_text());
            sender.commitChanges();
        }

        function OnClientNodeClicking(sender, eventArgs) {
            var node = eventArgs.get_node();

            node.toggle();

            if (node.get_nodes().get_count()) {
                CollapseSiblings(node);
            }
        }

        function CollapseSiblings(node) {
            var parent = node.get_parent();
            var siblings = parent.get_nodes();
            var siblingsCount = siblings.get_count();

            for (var nodeIndex = 0; nodeIndex < siblingsCount; nodeIndex++) {
                var siblingNode = siblings.getNode(nodeIndex);

                if ((siblingNode != node) &&
   (siblingNode.get_expanded())) {
                    siblingNode.collapse();

                    return;
                }
            }
        }



    </script>

</head>
<body>
    <form id="Form1" method="post" runat="server">
    <telerik:RadScriptManager ID="RadScriptManager1" runat="server" />
    <telerik:RadWindowManager ID="contentPopups" runat="server" />

<%--    <telerik:RadStyleSheetManager ID="RadStyleSheetManager1" runat="server" />--%>
    
        
    <telerik:RadTreeView ID="treeSelectFrom" runat="server" Style="z-index: 104; left: 5px;
        position: absolute; top: 55px;" Skin="Vista" CheckBoxes="False" 
        Height="300px" Width="275px" BorderStyle="Solid" BorderWidth="1" 
        BackColor="#FFFFCC" EnableDragAndDrop="True"  OnNodeDrop="treeSelectedMembers_NodeDrop" OnClientNodeClicking="OnClientNodeClicking">
    </telerik:RadTreeView>
    <telerik:RadTreeView ID="treeSelectedMembers" runat="server" Style="z-index: 104; left: 310px;
        position: absolute; top: 55px;" CheckBoxes="False" Height="300px" 
        Width="275px"  BorderStyle="Solid" BorderWidth="1" BackColor="#FFFFCC" 
        Skin="Vista" EnableDragAndDrop="True" AllowNodeEditing="true" EnableDragAndDropBetweenNodes="True"  
        OnNodeDrop="treeSelectedMembers_NodeDrop" OnClientNodeEdited="ClientNodeEdited">
    </telerik:RadTreeView>
    
 
        
    <asp:Label ID="Label2" runat="server" Text="Select From:" Style="z-index: 104;
        left: 7px; position: absolute; top: 36px"></asp:Label>
    <asp:Label ID="Label3" runat="server" Text="Selected Members:" Style="z-index: 104;
        left: 295px; position: absolute; top: 36px"></asp:Label>

    <asp:ImageButton ID="butSave" Style="z-index: 104; left: 24px; position: absolute;
        top: 380px" TabIndex="5" runat="server" ImageUrl="images/button_save.gif"></asp:ImageButton>
    <asp:ImageButton ID="butClose" Style="z-index: 104; left: 201px; position: absolute;
        top: 380px" TabIndex="5" runat="server" ImageUrl="images/button_close.gif"></asp:ImageButton>
        
           <asp:Button ID="butAddGroup" Style="z-index: 34; left: 593px; position: absolute;
        top: 50px" TabIndex="5" runat="server" Text="New Team Group" 
        onclick="butAddGroup_Click"></asp:Button>
        
 <%--                  <asp:Button ID="butAddContact" Style="z-index: 34; left: 551px; position: absolute;
        top: 80px" TabIndex="5" runat="server" Text="New Contact" 
        onclick="butAddContact_Click"></asp:Button>--%>
        
          
           <asp:Button ID="butRemove" Style="z-index: 74; left: 597px; position: absolute;
        top: 110px" TabIndex="5" runat="server"  Text="Remove Selected" 
        onclick="butRemove_Click"></asp:Button>
        

  
 <telerik:RadAjaxManager ID="RadAjaxManager1" runat="server">
        <AjaxSettings>
            <telerik:AjaxSetting AjaxControlID="treeSelectFrom">
                <UpdatedControls>
                    <telerik:AjaxUpdatedControl ControlID="treeSelectedMembers" LoadingPanelID="RadAjaxLoadingPanel1" />
                </UpdatedControls>
            </telerik:AjaxSetting>
            <telerik:AjaxSetting AjaxControlID="treeSelectedMembers">
                <UpdatedControls>
                    <telerik:AjaxUpdatedControl ControlID="treeSelectedMembers" LoadingPanelID="RadAjaxLoadingPanel1" />
                     <telerik:AjaxUpdatedControl ControlID="treeSelectFrom" LoadingPanelID="RadAjaxLoadingPanel1" />
                </UpdatedControls>
            </telerik:AjaxSetting>
            <telerik:AjaxSetting AjaxControlID="butAddGroup">
                <UpdatedControls>
                    <telerik:AjaxUpdatedControl ControlID="treeSelectedMembers" LoadingPanelID="RadAjaxLoadingPanel1" />
                </UpdatedControls>
            </telerik:AjaxSetting>
              <telerik:AjaxSetting AjaxControlID="butRemove">
                <UpdatedControls>
                    <telerik:AjaxUpdatedControl ControlID="treeSelectedMembers" LoadingPanelID="RadAjaxLoadingPanel1" />
                </UpdatedControls>
            </telerik:AjaxSetting>            

        </AjaxSettings>
    </telerik:RadAjaxManager>
    <telerik:RadAjaxLoadingPanel ID="RadAjaxLoadingPanel1" runat="server" Height="75px"
        Width="75px" Transparency="25">
        <img alt="Loading..." src='<%= RadAjaxLoadingPanel.GetWebResourceUrl(Page, "Telerik.Web.UI.Skins.Default.Ajax.loading.gif") %>'
            style="border: 0;" />
    </telerik:RadAjaxLoadingPanel>
    
    </form>
</body>
</html>
