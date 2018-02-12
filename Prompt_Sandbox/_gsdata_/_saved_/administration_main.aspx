<%@ Page Language="VB" MasterPageFile="~/prompt.master" Title="Prompt Administration" %>
<%@ Register Assembly="Telerik.Web.UI" Namespace="Telerik.Web.UI" TagPrefix="telerik" %>
<%@ Import Namespace="Prompt" %>

<script runat="server">
    
    
    Private Sub Page_Load(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MyBase.Load

        ProcLib.CheckSession(Page)
        ProcLib.LoadPopupJscript(Page)
        
        ''set up help button
        Session("PageID") = "PromptAdministration"

        Using db As New NavMenu
            db.BuildAdminMenu(tree1)
        End Using

        'Set the targets to the content pane for all the nav items
        For Each node As RadTreeNode In tree1.GetAllNodes
            If node.Target = "contentPane" Then
                node.Target = contentPane.ClientID
            End If
        Next
        
        With MasterPopups
            .VisibleOnPageLoad = False
            .Skin = "Windows7"
                         
            Dim ww As New RadWindow

            ww = New RadWindow
            With ww
                .ID = "EditWindow"
                .NavigateUrl = "#"
                .Title = ""
                .Width = 550
                .Height = 275
                .Modal = True
                .VisibleStatusbar = False
                .ReloadOnShow = True
                .Behaviors = WindowBehaviors.Close + WindowBehaviors.Move
            End With
            .Windows.Add(ww)
            
   
        End With

          
    End Sub
    
         
</script>

<asp:Content ID="Content1" ContentPlaceHolderID="mainBody" runat="Server">

<asp:Label ID="lblPageTitle" runat="server" CssClass="admin_lbl">Administration</asp:Label>
<br />
    <br class="clear" />

    <telerik:RadSplitter ID="RadSplitter1" runat="server" Skin="Sitefinity" Width="100%" Height="90%">
        <telerik:RadPane ID="navPane" runat="server" Width="300">
            <telerik:RadTreeView ID="tree1" runat="server" EnableViewState="True"
                OnClientNodeClicked="ClientNodeClicked" ExpandDelay="0" Skin="Windows7" 
                SingleExpandPath="True">
            </telerik:RadTreeView>
        </telerik:RadPane>
        <telerik:RadSplitBar ID="RadSplitBar1" runat="server" CollapseMode="Forward" />
        <telerik:RadPane ID="contentPane" runat="server" Scrolling="Both" ContentUrl="about:blank">
            content pane</telerik:RadPane>
    </telerik:RadSplitter>
    <telerik:RadWindowManager ID="MasterPopups" runat="server">
    </telerik:RadWindowManager>
 
    <script type="text/javascript" language="javascript">

        function GetRadWindow() {
            var oWindow = null;
            if (window.RadWindow) oWindow = window.RadWindow;
            else if (window.frameElement.radWindow) oWindow = window.frameElement.radWindow;
            return oWindow;
        }

        function ClientNodeClicked(sender, eventArgs) {
            var node = eventArgs.get_node();
            node.toggle();
        }

    </script>

</asp:Content>
