<%@ Page Language="vb" %>

<%@ Register Assembly="Telerik.Web.UI" Namespace="Telerik.Web.UI" TagPrefix="telerik" %>
<%@ Import Namespace="Prompt" %>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">

<script runat="server">

    Private ParentRecordType As String = ""
    Private ParentRecID As Integer = 0
    Private bReadOnly As Boolean = True

    Private Sub Page_Load(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MyBase.Load

        If ProcLib.CheckExpiredSessionForPopup(Page) Then    'session died so close the page - this is to prevent orphaned popups
            ProcLib.CloseAndRefresh(Page)
        End If
        
        ProcLib.LoadPopupJscript(Page)

        Session("PageID") = "AttachmentsManageLinked"

        ParentRecordType = Request.QueryString("ParentType")
        ParentRecID = Request.QueryString("ParentRecID")
 
        BuildMenu()
        
        If Not IsPostBack Then

        End If
        
        With RadPopups
            .Skin = "Office2007"
            .VisibleOnPageLoad = False
            Dim ww As New RadWindow
            With ww
                .ID = "ShowHelp"
                .NavigateUrl = ""
                .Title = ""
                .Width = 350
                .Height = 350
                .Top = 20
                .Modal = False
                .VisibleStatusbar = True
                .ReloadOnShow = True
                .Behaviors = WindowBehaviors.Close + WindowBehaviors.Resize
            End With
            .Windows.Add(ww)
           
           
               
            ww = New RadWindow
            With ww
                .ID = "ShowDialogPopup"
                .NavigateUrl = ""
                .Title = ""
                .Width = 350
                .Height = 150
                .Top = 20
                .Modal = False
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
                .Width = 450
                .Height = 400
                .Top = 20
                .Modal = False
                .VisibleStatusbar = True
                .ReloadOnShow = True
                .Behaviors = WindowBehaviors.Close
            End With
            .Windows.Add(ww)
             
        End With

        SetSecurity()
        
    End Sub
    
    Private Sub SetSecurity()
           
        Using db As New EISSecurity
            Select Case ParentRecordType
                Case "Transaction"
                    db.ProjectID = ParentRecID
                    If db.FindUserPermission("Transactions", "Write") Then
                        bReadOnly = False
                    Else
                        bReadOnly = True
                    End If

                Case Else     'This is a contract or CO
                    db.ProjectID = ParentRecID
                    If db.FindUserPermission("ContractOverview", "Write") Then
                        bReadOnly = False
                    Else
                        bReadOnly = True
                    End If
                
            End Select
            
            If bReadOnly Then
                RadMenu1.FindItemByValue("Upload").Visible = False
            End If
  
           
        End Using
        
        
    End Sub
    
  
    Public Sub BuildMenu()
        RadMenu1.Width = Unit.Percentage(100)
        
        Dim nTopLineHeight As Unit = Unit.Pixel(27)
        Dim nTopMenuItemWidths As Unit = Unit.Pixel(125)
        
        With RadMenu1
            .Skin = "Vista"
            .Items.Clear()
        End With
        Dim mm As RadMenuItem

        '**********************************************
        mm = New RadMenuItem
        With mm
            .Height = nTopLineHeight
            .Text = "Upload"
            .Value = "Upload"
            .NavigateUrl = "attachment_upload_linked.aspx?ParentRecID=" & ParentRecID & "&ParentType=" & ParentRecordType
            .ImageUrl = "images/document_up.png"
            
            .Width = nTopMenuItemWidths
        End With
        RadMenu1.Items.Add(mm)
        
   
        mm = New RadMenuItem
        With mm
            .Text = "Exit"
            .Value = "Exit"
            .ImageUrl = "images/exit_big.png"
            .Height = nTopLineHeight
            .Width = nTopMenuItemWidths
        End With
        RadMenu1.Items.Add(mm)
        
        mm = New RadMenuItem
        With mm
            .Text = "Help"
            .Value = "Help"
            .ImageUrl = "images/help.png"
            .Attributes("onclick") = "openPopup('help_view.aspx','pophelp',550,450,'yes');"
            .Height = nTopLineHeight
            .Width = nTopMenuItemWidths
        End With
        RadMenu1.Items.Add(mm)
        
           
    End Sub
    
    Protected Sub RadMenu1_ItemClick(ByVal sender As Object, ByVal e As Telerik.Web.UI.RadMenuEventArgs) Handles RadMenu1.ItemClick
        Dim Item As Telerik.Web.UI.RadMenuItem = e.Item
        If Item.Text = "Exit" Then
            CloseMe()
        End If

    End Sub

 
    Protected Sub RadGrid1_NeedDataSource(ByVal source As Object, ByVal e As Telerik.Web.UI.GridNeedDataSourceEventArgs) Handles RadGrid1.NeedDataSource
        'loads the grid whenever it needs data (sorting, rebinding, etc...)
        If Not e.IsFromDetailTable Then
            Using db As New promptAttachment
                db.CallingPage = Page
                RadGrid1.DataSource = db.GetLinkedAttachments(ParentRecID, ParentRecordType)
            End Using
        End If
    End Sub
  
       
    Private Sub RadGrid1_ItemDataBound(ByVal sender As Object, ByVal e As Telerik.Web.UI.GridItemEventArgs) Handles RadGrid1.ItemDataBound
        'This event allows us to change the contents of cells after binding, before rendering
        'If (TypeOf e.Item Is GridDataItem) Then
        '    Dim dataItem As GridDataItem = CType(e.Item, GridDataItem)
        '    Dim nBatchID As Integer = dataItem.OwnerTableView.DataKeyValues(dataItem.ItemIndex)("AttachmentID")
            
        '    'Hide the image if needed
        '    Dim lnk As HyperLink = CType(dataItem("DeleteFile").Controls(0), HyperLink)
                     
        'End If
    End Sub
    
    Protected Sub RadGrid1_ItemCreated(ByVal sender As Object, ByVal e As Telerik.Web.UI.GridItemEventArgs) Handles RadGrid1.ItemCreated
        'This event allows us to customize the cell contents - fired before databound
          
        If (TypeOf e.Item Is GridDataItem) Then
            If e.Item.OwnerTableView.DataMember = "dataAttachments" Then
                'This looks at the row as it is created and finds the hyperlink 
                'and wiresd it to a Java Script function that calls a RAD window.
                
                Dim bEnableDelete As Boolean = True
                                
                Dim item As GridDataItem = CType(e.Item, GridDataItem)
                Dim nAttachmentID As Integer = item.OwnerTableView.DataKeyValues(item.ItemIndex)("AttachmentID")
                Dim nInWorkflow = item.OwnerTableView.DataKeyValues(item.ItemIndex)("InWorkflow")
                'Disable the delete and unlink option if is in workflow
                If Not IsDBNull(nInWorkflow) Then
                    If nInWorkflow = 1 Then
                        bEnableDelete = False
                    End If
                End If
                
                If bReadOnly Then
                    bEnableDelete = False
                End If
                
                'update the link button to delete file
                Dim linkButton As HyperLink = CType(item("DeleteFile").Controls(0), HyperLink)
                ' linkButton.Attributes("onclick") = "return ConfirmDelete(this,'" & nAttachmentID & "','" & ParentRecordType & "');"
                linkButton.ToolTip = "Delete this Attachment."
                linkButton.ImageUrl = "images/trash.gif"
                linkButton.NavigateUrl = "attachment_dialog_confirm_delete.aspx?recid=" & nAttachmentID & "&ParentType=" & ParentRecordType & "&ParentRecID=" & ParentRecID
                linkButton.Visible = bEnableDelete
                
                'update the link button to delete file
                linkButton = CType(item("UnlinkAttachment").Controls(0), HyperLink)
                'linkButton.Attributes("onclick") = "return ConfirmUnlink(this,'" & nAttachmentID & "','" & ParentRecordType & "','" & ParentRecID & "');"
                linkButton.ToolTip = "Unlink this Attachment."
                linkButton.NavigateUrl = "attachment_dialog_confirm_delete.aspx?recid=" & nAttachmentID & "&ParentType=" & ParentRecordType & "&Unlink=1&ParentRecID=" & ParentRecID
                linkButton.ImageUrl = "images/attachment_remove_small.gif"
                linkButton.Visible = bEnableDelete
                
                ''update the link button to view file
                'linkButton = CType(item("ViewFile").Controls(0), HyperLink)
                'linkButton.Attributes("onclick") = "return OpenAttachment('" & nAttachmentID & "');"
                'linkButton.ToolTip = "Get this Attachment."
                'linkButton.ImageUrl = "images/data_down.png"
                'linkButton.NavigateUrl = "#"
                
  
                
                  Dim strFileName As String = ""
            Dim strFilePath As String = ""
            Using db As New promptAttachment
                db.GetLinkedAttachment(nAttachmentID)
                strFileName = db.FileName
                strFilePath = db.PhysicalPath
                        
                'Strip the physical prefix out of the path for lookup
                Dim sStoredFilePath As String = strFilePath.Replace(Proclib.GetCurrentAttachmentPath(), "")

                'update the link button to view file
                linkButton = CType(item("ViewFile").Controls(0), HyperLink)
                'linkButton.Attributes("onclick") = "return OpenAttachment('" & nAttachmentID & "');"
                linkButton.ToolTip = "Get this Attachment."
                linkButton.ImageUrl = "images/data_down.png"
                 linkButton.NavigateUrl = db.RelativePath & strFileName
                linkButton.Target = "_new"
                
  End Using
           
            End If
   
        End If
    End Sub
    
    Protected Overrides Sub RaisePostBackEvent(ByVal source As IPostBackEventHandler, ByVal eventArgument As String)
        'Listens for pop window calling to refresh grid after some edit.
        MyBase.RaisePostBackEvent(source, eventArgument)
        If TypeOf source Is RadGrid Then
            Select Case eventArgument
                Case "Rebind"
                    RadGrid1.Rebind()
            End Select
        End If
    End Sub
    
    Private Sub CloseMe()
          
        lblAlert.Text = "<script>UpdateParentPage()</" + "script>"   'calls a function in parent form that updates control via ajax
        ProcLib.CloseOnlyRAD(Page)
        
        
        
    End Sub

        
</script>

<html>
<head>
    <title>Manage Linked Attachments</title>
    <link rel="stylesheet" type="text/css" href="http://localhost/Prompt/Styles.css" />

    <script type="text/javascript" language="javascript">



        //        function ConfirmDelete(oButton, id, rectype)   //for dialog window display - pass the record id and the record type
        //        {

        //            var oWnd = window.radopen("attachment_dialog_confirm_delete.aspx?recid=" + id + "&ParentType=" + rectype, "ShowDialogPopup");
        //            return false;
        //        }

        //        function ConfirmUnlink(oButton, id, rectype, parentrecid)   //for dialog window display - pass the record id and the record type
        //        {

        //            var oWnd = window.radopen("attachment_dialog_confirm_delete.aspx?recid=" + id + "&ParentType=" + rectype + "&Unlink=1&ParentRecID=" + parentrecid, "ShowDialogPopup");
        //            return false;
        //        }

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

        // to allow popup to call refresh in this form after edit
        function refreshGrid() {
            RadGridNamespace.AsyncRequest('<%= RadGrid1.UniqueID %>', 'Rebind', '<%= RadGrid1.ClientID %>');
        }

        function UpdateParentPage()
        //This call is used when record saved to update specific control on calling page -
        //in this case it is the HandleAjaxPostbackFromAttachmentsPopup method on the calling page
        {
            GetRadWindow().BrowserWindow.HandleAjaxPostbackFromAttachmentsPopup();
        }      
	   
    </script>

</head>
<body>
    <form id="Form1" method="post" runat="server">
    <telerik:RadScriptManager ID="RadScriptManager1" runat="server" />
    <telerik:RadMenu ID="RadMenu1" runat="server" Style="z-index: 104; left: 11px; position: absolute;
        top: 5px">
    </telerik:RadMenu>
    <telerik:RadGrid Style="z-index:100 ; left: 9px; position: absolute; top: 42px" ID="RadGrid1"
        runat="server" AllowRowSize="True" AllowMultiRowSelection="False" AllowSorting="True" AutoGenerateColumns="False"
        GridLines="None" Width="95%" EnableAJAX="True" Skin="Office2007" Height="150px">
        <ClientSettings>
            <Scrolling AllowScroll="True" UseStaticHeaders="True" ScrollHeight="80%" />
        </ClientSettings>
        <MasterTableView Width="98%" GridLines="None" DataMember="dataAttachments" DataKeyNames="AttachmentID,InWorkflow"
            NoMasterRecordsText="No Linked Attachments were found to display.">
            <Columns>
                <telerik:GridBoundColumn DataField="AttachmentID" UniqueName="AttachmentID" HeaderText="AttachmentID"
                    Visible="False">
                    <ItemStyle HorizontalAlign="Left" />
                    <HeaderStyle HorizontalAlign="Left" />
                </telerik:GridBoundColumn>
                <telerik:GridHyperLinkColumn UniqueName="ViewFile">
                    <ItemStyle HorizontalAlign="Left" Width="25px" />
                    <HeaderStyle HorizontalAlign="Left" Width="25px" />
                </telerik:GridHyperLinkColumn>
                <telerik:GridBoundColumn DataField="FileName" HeaderText="File Name" UniqueName="FileName">
                    <ItemStyle HorizontalAlign="Left" VerticalAlign="Top" Width="70%" />
                    <HeaderStyle HorizontalAlign="Left" VerticalAlign="Top" Width="70%" Height="15px" />
                </telerik:GridBoundColumn>
                <telerik:GridBoundColumn DataField="FileSize" UniqueName="FileSize" HeaderText="Size">
                    <ItemStyle HorizontalAlign="Left" VerticalAlign="Top" Width="15%" />
                    <HeaderStyle HorizontalAlign="Left" Wrap="False" VerticalAlign="Top" Width="15%" />
                </telerik:GridBoundColumn>
                <telerik:GridHyperLinkColumn UniqueName="UnlinkAttachment">
                    <ItemStyle HorizontalAlign="Right" VerticalAlign="Top" Width="25px" />
                    <HeaderStyle HorizontalAlign="Right" VerticalAlign="Top" Width="25px" />
                </telerik:GridHyperLinkColumn>
                <telerik:GridHyperLinkColumn UniqueName="DeleteFile">
                    <ItemStyle HorizontalAlign="Right" VerticalAlign="Top" Width="25px" />
                    <HeaderStyle HorizontalAlign="Right" VerticalAlign="Top" Width="25px" />
                </telerik:GridHyperLinkColumn>
            </Columns>
        </MasterTableView>
        <ExportSettings>
            <Pdf PageBottomMargin="" PageFooterMargin="" PageHeaderMargin="" PageHeight="11in"
                PageLeftMargin="" PageRightMargin="" PageTopMargin="" PageWidth="8.5in" />
        </ExportSettings>
    </telerik:RadGrid>
    <%--Hidden lable to handle jscript code--%>
    <asp:Label ID="lblAlert" runat="server" Height="24px" Style="z-index: 111; left: 370px;
        position: absolute; top: 83px"></asp:Label>
    <telerik:RadWindowManager ID="RadPopups" runat="server">
    </telerik:RadWindowManager>
    </form>
</body>
</html>
