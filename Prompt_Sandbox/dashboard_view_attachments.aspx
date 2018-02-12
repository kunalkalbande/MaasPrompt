<%@ Page Language="vb" %>

<%@ Register Assembly="Telerik.Web.UI" Namespace="Telerik.Web.UI" TagPrefix="telerik" %>
<%@ Import Namespace="Prompt" %>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">

<script runat="server">

    Private TransactionID As String = 0

    Private Sub Page_Load(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MyBase.Load

        If ProcLib.CheckExpiredSessionForPopup(Page) Then    'session died so close the page - this is to prevent orphaned popups
            ProcLib.CloseAndRefresh(Page)
        End If

        Session("PageID") = "DashboardViewAttachments"
        TransactionID = Request.QueryString("TransactionID")
 
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
                .Modal = False
                .VisibleStatusbar = True
                .ReloadOnShow = True
                .Behaviors = WindowBehaviors.Close + WindowBehaviors.Move
            End With
            .Windows.Add(ww)
            
           
            
            'ww = New RadWindow
            'With ww
            '    .ID = "ShowDialogPopup"
            '    .NavigateUrl = ""
            '    .Title = ""
            '    .Width = 350
            '    .Height = 150
            '    .Modal = False
            '    .VisibleStatusbar = True
            '    .ReloadOnShow = True
            '    .Behaviors = WindowBehaviors.Close + WindowBehaviors.Move
            'End With
            '.Windows.Add(ww)
                        
            'ww = New RadWindow
            'With ww
            '    .ID = "OpenAttachmentWindow"
            '    .NavigateUrl = ""
            '    .Title = "Open Attachment"
            '    .Width = 400
            '    .Height = 300
            '    .Top = 20
            '    .Modal = False
            '    .VisibleStatusbar = True
            '    .ReloadOnShow = True
            '    .Behaviors = WindowBehaviors.Close + WindowBehaviors.Move
            'End With
            '.Windows.Add(ww)
   
 
        End With

    End Sub
    
  
    Public Sub BuildMenu()
        RadMenu1.Width = Unit.Percentage(100)
        
        Dim nTopLineHeight As Unit = Unit.Pixel(27)
        Dim nTopMenuItemWidths As Unit = Unit.Pixel(125)
        
        RadMenu1.Items.Clear()
        
        Dim mm As RadMenuItem

        mm = New RadMenuItem
        With mm
            .Text = "Exit"
            .Value = "Exit"
            .ImageUrl = "images/exit_big.png"
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
 
        Using db As New promptAttachment
            db.CallingPage = Page
            
            Dim tbl As DataTable = db.GetLinkedAttachments(TransactionID, "Transaction")
            Dim col As New DataColumn
            col.DataType = Type.GetType("System.String")
            col.ColumnName = "NavLink"
            tbl.Columns.Add(col)
            
            'Now go through and set a new column with relative link for download
            For Each row As DataRow In tbl.Rows
                db.GetLinkedAttachment(row("AttachmentID"))
                Dim strFileName As String = db.FileName
                Dim strFilePath As String = db.RelativePath
            
                row("NavLink") = strFilePath & strFileName
            Next

            RadGrid1.DataSource = tbl
        End Using

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
                
                Dim item As GridDataItem = CType(e.Item, GridDataItem)
                Dim nAttachmentID As Integer = item.OwnerTableView.DataKeyValues(item.ItemIndex)("AttachmentID")
                Dim sLink As String = item.OwnerTableView.DataKeyValues(item.ItemIndex)("NavLink")

                'update the link button to view file
                Dim linkButton As HyperLink = CType(item("FileName").Controls(0), HyperLink)
                linkButton.ToolTip = "Get this Attachment."
                linkButton.NavigateUrl = sLink
                linkButton.Target = "_new"
 

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
        
        ProcLib.CloseOnlyRAD(Me)
        
        ''Add Jscript to close the window and update the grid.
        'Dim jscript As New StringBuilder
        'With jscript
        '    .Append("<script language='javascript'>")
        '    '.Append("GetRadWindow().BrowserWindow.location.reload(true);")
        '    .Append("GetRadWindow().Close();")
        '    .Append("</" & "script>")
        'End With
        'ClientScript.RegisterStartupScript(GetType(String), "CloseMe", jscript.ToString)
        
    End Sub

        
</script>

<html>
<head>
    <title>View Linked Attachments</title>
     <link rel="stylesheet" type="text/css" href="http://localhost/Prompt/Styles.css" />

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

//        function OpenAttachment(id)     //for opening attachments 
//        {

//            var oWnd = window.radopen("attachment_get_linked.aspx?ID=" + id, "OpenAttachmentWindow");
//            return false;
//        }

//        // to allow popup to call refresh in this form after edit
//        function refreshGrid() {
//            RadGridNamespace.AsyncRequest('<%= RadGrid1.UniqueID %>', 'Rebind', '<%= RadGrid1.ClientID %>');
//        }        
	   
    </script>

</head>
<body>
   <form id="Form1" method="post" runat="server">
     <telerik:RadScriptManager ID="RadScriptManager1" runat="server" />
    <telerik:RadMenu ID="RadMenu1" runat="server" Style="z-index: 104; left: 11px; position: absolute;
        top: 5px">
        <Items>
            <telerik:RadMenuItem ID="RadMenuItem1" runat="server" Text="Menu1">
            </telerik:RadMenuItem>
            <telerik:RadMenuItem ID="RadMenuItem2" runat="server" Text="Menu2">
            </telerik:RadMenuItem>
        </Items>
    </telerik:RadMenu>
    <telerik:RadGrid Style="z-index: 100; left: 9px; position: absolute; top: 42px" ID="RadGrid1"
        runat="server" AllowMultiRowSelection="False" AllowSorting="True" AutoGenerateColumns="False"
        GridLines="None" Width="95%" EnableAJAX="True" Skin="Office2007" Height="150px">
        <ClientSettings>
            <Scrolling AllowScroll="True" UseStaticHeaders="True" ScrollHeight="80%" />
        </ClientSettings>
        <MasterTableView Width="98%" GridLines="None" DataMember="dataAttachments" DataKeyNames="AttachmentID,NavLink"
            NoMasterRecordsText="No Linked Attachments were found to display.">
            <Columns>
                <telerik:GridBoundColumn DataField="AttachmentID" UniqueName="AttachmentID" HeaderText="AttachmentID"
                    Visible="False">
                    <ItemStyle HorizontalAlign="Left" />
                    <HeaderStyle HorizontalAlign="Left" />
                </telerik:GridBoundColumn>
 
                <telerik:GridHyperLinkColumn DataTextField="FileName" HeaderText="Name" UniqueName="FileName" SortExpression="FileName">
                    <ItemStyle HorizontalAlign="Left" Width="50%"/>
                    <HeaderStyle HorizontalAlign="Left" Width="50%" />
                </telerik:GridHyperLinkColumn>
                
                <telerik:GridBoundColumn DataField="FileSize" UniqueName="FileSize" HeaderText="Size">
                    <ItemStyle HorizontalAlign="Left" Width="50px"/>
                    <HeaderStyle HorizontalAlign="Left" Wrap="False" Width="50px"/>
                </telerik:GridBoundColumn>
                
                <telerik:GridBoundColumn DataField="LastUpdateBy" UniqueName="LastUpdateBy" HeaderText="LastUpdateBy">
                    <ItemStyle HorizontalAlign="Left" />
                    <HeaderStyle HorizontalAlign="Left" Wrap="False" />
                </telerik:GridBoundColumn>
                
                  
            </Columns>
            <ExpandCollapseColumn Resizable="False" Visible="False">
                <HeaderStyle Width="20px" />
            </ExpandCollapseColumn>
            <RowIndicatorColumn Visible="False">
                <HeaderStyle Width="20px" />
            </RowIndicatorColumn>
        </MasterTableView>
        <ExportSettings>
            <Pdf PageBottomMargin="" PageFooterMargin="" PageHeaderMargin="" PageHeight="11in"
                PageLeftMargin="" PageRightMargin="" PageTopMargin="" PageWidth="8.5in" />
        </ExportSettings>
    </telerik:RadGrid>
    <telerik:RadWindowManager ID="RadPopups" runat="server">
    </telerik:RadWindowManager>
    </form>
</body>
</html>
