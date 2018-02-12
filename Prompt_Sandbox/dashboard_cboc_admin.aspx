<%@ Page Language="VB" MasterPageFile="~/prompt.master" Title="Prompt CBOC Reports Admin Dashboard" %>

<%@ Register Assembly="Telerik.Web.UI" Namespace="Telerik.Web.UI" TagPrefix="telerik" %>
<%@ Import Namespace="Prompt" %>
<%@ Import Namespace="System.IO" %>

<script runat="server">
    
    Dim strPhysicalPath As String = ""
    Dim strRelativePath As String = ""
    Private sCurrentFolder As String = ""
    Private lstCurrentView As RadComboBox

    Private Sub Page_Load(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MyBase.Load

        Session("PageID") = "Dashboard_CBOC_Admin"
        
        
        Master.Page.Title = "CBOC Report Admin Dashboard"
        
        'Set the Report Path 
        strPhysicalPath = ProcLib.GetCurrentAttachmentPath & "DistrictID_" & HttpContext.Current.Session("DistrictID")
        strRelativePath = "~/" & ProcLib.GetCurrentRelativeAttachmentPath & "DistrictID_" & HttpContext.Current.Session("DistrictID")
        
        strPhysicalPath &= "/_apprisedocs/CBOC Reports/"
        strRelativePath &= "/_apprisedocs/CBOC Reports/"
        
        If Not Directory.Exists(strPhysicalPath) Then       'create it if it does not exist already
            Directory.CreateDirectory(strPhysicalPath)
        End If

        If Not IsPostBack Then
           
            Dim paths As String() = New String() {strRelativePath}
            
            With RadFileExplorer1
                .Width = Unit.Percentage(100)
                .Height = Unit.Pixel(550)
                .Skin = "Windows7"
                
                'This code sets RadFileExplorer's paths
                .Configuration.ViewPaths = paths
                .Configuration.UploadPaths = paths
                .Configuration.DeletePaths = paths
                
                .VisibleControls = FileExplorer.FileExplorerControls.Grid + FileExplorer.FileExplorerControls.TreeView + FileExplorer.FileExplorerControls.Toolbar + FileExplorer.FileExplorerControls.ContextMenus

                'Sets Max file size
                .Configuration.MaxUploadFileSize = 150485760

                ' Enables Paging on the Grid
                .AllowPaging = False
                ' Sets the page size
                .PageSize = 20

                'Load the default FileSystemContentProvider
                .Configuration.ContentProviderTypeName = GetType(Telerik.Web.UI.Widgets.FileSystemContentProvider).AssemblyQualifiedName
            
            End With
          
            
          
        End If
        
        
        With InboxPopups
            .VisibleOnPageLoad = False
            .Skin = "Windows7"
                         
            Dim ww As New RadWindow
  
            ww = New RadWindow
            With ww
                .ID = "ShowAttachmentsWindow"
                .NavigateUrl = ""
                .Title = ""
                .Width = 525
                .Height = 300
                .Top = 200
                .Left = 20
                .Modal = False
                .VisibleStatusbar = False
                .ReloadOnShow = True
                .Behaviors = WindowBehaviors.Close + WindowBehaviors.Move
            End With
            .Windows.Add(ww)
                      
                 
        End With
        
        
 
    End Sub
    
    Protected Sub RadFileExplorer1_ItemCommand(ByVal sender As Object, ByVal e As RadFileExplorerEventArgs)
        Select Case e.Command
            Case "UploadFile"
                Exit Select
            Case "MoveDirectory"
                Exit Select
            Case "CreateDirectory"
                Exit Select
            Case "DeleteDirectory"
                Exit Select
                
            Case "DeleteFile"
                Exit Select
            Case "MoveFile"
                Exit Select

                ' e.Cancel = true; // Cancel the operation
        End Select
    End Sub
    
   


  
</script>

<asp:Content ID="Content1" ContentPlaceHolderID="mainBody" runat="Server">
    <telerik:RadWindowManager ID="InboxPopups" runat="server" />
    <div style="padding: 5px;">
        <telerik:RadFileExplorer runat="server" ID="RadFileExplorer1" Width="575px" EnableCopy="true"
            Height="375px" OnItemCommand="RadFileExplorer1_ItemCommand" OnClientFileOpen="OnExplorerFileOpen" 
            DisplayUpFolderItem="True" >
<Configuration SearchPatterns="*.pdf"></Configuration>
        </telerik:RadFileExplorer>
     <%--   <telerik:RadAjaxManager ID="RadAjaxManager1" runat="server">
            <AjaxSettings>
                <%-- <telerik:AjaxSetting AjaxControlID="RadGrid1">
                    <UpdatedControls>
                        <telerik:AjaxUpdatedControl ControlID="RadGrid1" LoadingPanelID="RadAjaxLoadingPanel1" />
                    </UpdatedControls>
                </telerik:AjaxSetting>
                
                <telerik:AjaxSetting AjaxControlID="RadMenu1">
                    <UpdatedControls>
                        <telerik:AjaxUpdatedControl ControlID="RadGrid1" LoadingPanelID="RadAjaxLoadingPanel1" />
                    </UpdatedControls>
                </telerik:AjaxSetting>
                
                
                <telerik:AjaxSetting AjaxControlID="lstCurrentView">
                    <UpdatedControls>
                        <telerik:AjaxUpdatedControl ControlID="RadGrid1" LoadingPanelID="RadAjaxLoadingPanel1" />
                        <telerik:AjaxUpdatedControl ControlID="RadMenu1"  />
                    </UpdatedControls>
                </telerik:AjaxSetting>
            </AjaxSettings>
        </telerik:RadAjaxManager>
        <telerik:RadAjaxLoadingPanel ID="RadAjaxLoadingPanel1" runat="server" Height="75px"
            Width="75px" Transparency="25">
            <img alt="Loading..." src='<%= RadAjaxLoadingPanel.GetWebResourceUrl(Page, "Telerik.Web.UI.Skins.Default.Ajax.loading.gif") %>'
                style="border: 0;" />
        </telerik:RadAjaxLoadingPanel>--%>
        
        
    </div>
    <telerik:RadCodeBlock ID="RadCodeBlock1" runat="server">

        <script type="text/javascript" language="javascript">

            var oWindowManager = oExplorer.get_windowManager();
            oWindowManager.add_show(windowIsShownHandler);

             // the following allows us to customzes the size of the preview window
            function OnExplorerFileOpen(oExplorer, args) {
                setTimeout(function() {
                    var oWindowManager = oExplorer.get_windowManager();
                    var previewWinow = oWindowManager.getActiveWindow(); // Gets the current active widow
                    previewWinow.setSize(600, 600); // Set the new size of the window
                }, 100); // Some timeout is required in order to allow the window to become active
            }

            // Called when a window is shown
            function windowIsShownHandler(oWindow, args) {
                setTimeout(function() {
                    handleOpenedWindow(oWindow);
                }, 100); // Some time out is required as well
            }

            function handleOpenedWindow(oWindow) {
                var oExplorer = $find("<%= RadFileExplorer1.ClientID %>");
                var windowTitile = oWindow.get_title();

                ////////////////////////////////////////////////////////////////////////////////////////
                /*
                Get the titles of the embedded radwindow objects. 
                */

                // The title set to the RadWindowManager is the title shown in the Upload dialog
                // This code respects localization
                var uploadDialogTitle = oExplorer.get_windowManager().get_title();

                // The confirm dialog's title.
                // This title cannot be localized
                var deleteConfirmDialogTitle = "Delete";

                // The new folder dialog's title.
                // This code respects localization
                var newFolderDialogTitle = oExplorer.get_localization()["CreateNewFolder"];

                ////////////////////////////////////////////////////////////////////////////////////////

                switch (windowTitile) {
                    case uploadDialogTitle:
                        {// The upload dialog is opened
                            oWindow.setSize(500, 500);
                        };
                        break;
                    case deleteConfirmDialogTitle:
                        {// The delete confirmation dialog is opened
                            oWindow.set_behaviors(oWindow.get_behaviors() // get existing behaviors 
                            +
                         Telerik.Web.UI.WindowBehaviors.Move); // add "Move" behavior to the current behaviors
                        };
                        break;
                    case newFolderDialogTitle:
                        {// The create new folder dialog is opened
                            oWindow.set_behaviors(oWindow.get_behaviors() // get existing behaviors 
                            +
                         Telerik.Web.UI.WindowBehaviors.Move); // add "Move" behavior to the current behaviors
                        };
                        break;
                }
            }
    
  
        </script>

    </telerik:RadCodeBlock>
</asp:Content>
