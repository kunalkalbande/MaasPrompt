<%@ Page Language="VB" %>

<%@ Register Assembly="Telerik.Web.UI" Namespace="Telerik.Web.UI" TagPrefix="telerik" %>
<%@ Import Namespace="Prompt" %>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">

<script runat="server">
    
    Private nRecID As Integer = 0
    Private sRecordType As String = ""
    
    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs)
        nRecID = Request.QueryString("recid")
        sRecordType = Request.QueryString("rectype")
        PageTitle.Text = "Workflow History"
        
        With RadGrid1
            .EnableEmbeddedSkins = False
            .Skin = "Prompt"
            .GroupingEnabled = False
            .AllowSorting = True
            '.EnableViewState = False
            .AllowMultiRowSelection = False
            
            .ClientSettings.AllowColumnsReorder = False
            .ClientSettings.ColumnsReorderMethod = GridClientSettings.GridColumnsReorderMethod.Reorder
            .ClientSettings.Scrolling.AllowScroll = True
            .ClientSettings.Scrolling.ScrollHeight = Unit.Percentage(50)
            .ClientSettings.Scrolling.UseStaticHeaders = True
            .ClientSettings.Resizing.AllowColumnResize = True
            

            .MasterTableView.EnableHeaderContextMenu = False
            .MasterTableView.TableLayout = GridTableLayout.Fixed
            .MasterTableView.AllowMultiColumnSorting = False

            .Height = Unit.Pixel(400)
            
            .ExportSettings.FileName = "PromptWorkflowHistoryExport"
            .ExportSettings.OpenInNewWindow = True
            .ExportSettings.Pdf.PageTitle = "Prompt Workflow History"
            
   
        End With
        
        With winPops
            .VisibleOnPageLoad = False
            .Skin = "Windows7"
                         
            Dim ww As New RadWindow

            ww = New RadWindow
            With ww
                .ID = "AddNote"
                .NavigateUrl = ""
                .Title = ""
                .Width = 500
                .Height = 250
                '.Top = 200
                '.Left = 20
                .Modal = True
                .VisibleStatusbar = False
                .ReloadOnShow = True
                
                .Behaviors = WindowBehaviors.Close + WindowBehaviors.Move
            End With
            .Windows.Add(ww)
    
        End With
        
        lnkAddNote.Attributes("onclick") = "return AddNote(" & nRecID & ");"
        
        Dim DistrictID As Integer
        Using db As New PromptDataHelper
            DistrictID = db.ExecuteScalar("Select DistrictID From Transactions Where TransactionID = " & nRecID)
        End Using
        
        If sRecordType = "Transaction" Then
            lnkPrintHistory.NavigateUrl = "report_viewer.aspx?DirectCall=y&ReportID=178&TransID=" & nRecID & "&Dist=" & DistrictID
            lnkPrintHistory.Target = "_new"
            'lnkPrintHistory.NavigateUrl = "http://localhost/ReportServer?/PromptReports/WorkflowHistory&rs:Command=Render&rs:Format=PDF&Dist=" & DistrictID & "&TransID=" & TransactionID
        Else
            lnkPrintHistory.Visible = False   'HACK: hide until report is modified
        End If
                   
    End Sub
    
    Protected Sub RadGrid1_NeedDataSource(ByVal source As Object, ByVal e As Telerik.Web.UI.GridNeedDataSourceEventArgs) Handles RadGrid1.NeedDataSource
        
        Using db As New PromptDataHelper
                        
            Dim sql As String = ""
            If sRecordType = "Transaction" Then
                'get workflow history 
                sql = "SELECT *, CONVERT(CHAR(10),CreatedOn,101) as CreatedOnDate FROM WorkflowLog WHERE TransactionID = " & nRecID & " ORDER BY CreatedOn DESC "
                RadGrid1.DataSource = db.ExecuteDataTable(sql)
            
                'Get days since last action
                sql = "SELECT LastWorkFlowActionOn FROM Transactions WHERE TransactionID = " & nRecID
                Dim result = db.ExecuteScalar(sql)
                If IsDBNull(result) Then
                    result = Now()
                End If
                lblDaysSinceLastAction.Text = DateDiff(DateInterval.Day, result, Now())
                
            
            Else            'this is PAD
                'get workflow history 
                sql = "SELECT *, CONVERT(CHAR(10),CreatedOn,101) as CreatedOnDate FROM WorkflowLog WHERE PADID = " & nRecID & " ORDER BY CreatedOn DESC "
                RadGrid1.DataSource = db.ExecuteDataTable(sql)
                
                'Get days since last action
                sql = "SELECT LastWorkFlowActionOn FROM ProjectApprovalDocuments WHERE PADID = " & nRecID
                Dim result = db.ExecuteScalar(sql)
                If IsDBNull(result) Then
                    result = Now()
                End If
                lblDaysSinceLastAction.Text = DateDiff(DateInterval.Day, result, Now())
               
            End If
  
        End Using
        
        Using rs As New promptWorkflow
            If sRecordType = "Transaction" Then
                lblCurrentlyAt.Text = rs.GetCurrentWorkflowOwner("Transaction", nRecID)
            Else
                lblCurrentlyAt.Text = rs.GetCurrentWorkflowOwner("PAD", nRecID)
            End If
        End Using

       
    End Sub
    
   
    Protected Sub RadGrid1_ItemCreated(ByVal sender As Object, ByVal e As Telerik.Web.UI.GridItemEventArgs) Handles RadGrid1.ItemCreated
        'This event allows us to customize the cell contents - fired before databound

        'If (TypeOf e.Item Is GridDataItem) Then
        '    Dim item As GridDataItem = CType(e.Item, GridDataItem)
        '    Dim strReportName As String = item.OwnerTableView.DataKeyValues(item.ItemIndex)("ReportFileName")
                
        '    'update the link button to open attachments/notes window
        '    Dim linkButton As HyperLink = CType(item("ReportTitle").Controls(0), HyperLink)
        '    linkButton.Attributes("onclick") = "return ShowReport(this,'" & 0 & "', '" & strReportName & "');"
        '    linkButton.ToolTip = "Click on the report title to generate the report"
        'End If

    End Sub
    
    Private Sub RadGrid1_ItemDataBound(ByVal sender As Object, ByVal e As Telerik.Web.UI.GridItemEventArgs) Handles RadGrid1.ItemDataBound
        ' TODO: For some reason cannot find and replace vbcrlf in these test strings
        
        'If (TypeOf e.Item Is GridDataItem) Then
        '    Dim dataItem As GridDataItem = CType(e.Item, GridDataItem)
        '    Dim fieldValue As String = dataItem("Notes").Text
        '    Dim newVal As String = fieldValue
        '    Dim sChar As String = Chr(10) + Chr(13)
        '    If newVal.Contains(sChar) Then
        '        newVal = "test"
        '    End If
        '    'For i As Integer = 1 To fieldValue.Length - 1
        '    '    Dim ss = Mid(fieldValue, i, 1)
        '    '    If Asc(ss) = 10 Or Asc(ss) = 13 Then
                   
        '    '    End If
        '    'Next
                
                
                
                
        '    dataItem("Notes").Text = fieldValue & "<br/>" & "test" & "<br/>" & "Another"
        'End If
 
    End Sub
  

</script>

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title id="PageTitle" runat="server"></title>
    <link href="Styles.css" type="text/css" rel="stylesheet" />
    <link href="skins/Prompt/Grid.Prompt.css" rel="stylesheet" type="text/css" />
</head>
<body>
    <form id="Form1" method="post" runat="server">
    <telerik:RadScriptManager ID="RadScriptManager1" runat="server" />
    <telerik:RadWindowManager ID="winPops" runat="server" />
    <div>
        &nbsp;&nbsp;
        <asp:Label ID="Label1" runat="server" CssClass="smalltext" Style="z-index: 101; left: 8px;
            position: absolute; top: 8px" Text="Currently at: "></asp:Label>
        <asp:Label ID="Label2" runat="server" CssClass="smalltext" Style="z-index: 102; left: 390px;
            position: absolute; top: 8px" Text="Last Action(days): "></asp:Label>
        <asp:Label ID="lblCurrentlyAt" runat="server" CssClass="EditDataDisplay" Style="z-index: 103;
            left: 78px; position: absolute; top: 7px" Text="xxxxxxxx" Font-Bold="True" 
            ForeColor="Blue"></asp:Label>
        <asp:HyperLink ID="lnkPrintHistory" runat="server" Style="z-index: 105; left: 295px; position: absolute; top: 8px">
            Print History</asp:HyperLink>
        <asp:Label ID="lblDaysSinceLastAction" runat="server" CssClass="EditDataDisplay"
            Style="z-index: 105; left: 490px; position: absolute; top: 8px" 
            Text="xxxxxxxx" Font-Bold="True" ForeColor="Blue"></asp:Label>
        <asp:HyperLink ID="lnkAddNote" runat="server" 
        Style="z-index: 105; left: 560px; position: absolute; top: 8px" 
        ImageURL="images/note_add.png" ToolTip="Add a note to the workflow">Add Note</asp:HyperLink>
    </div>
    <telerik:RadGrid ID="RadGrid1" runat="server" AllowSorting="True" AutoGenerateColumns="False"
        EnableAJAX="True" GridLines="None" Height="90%" Skin="Prompt" EnableEmbeddedSkins="False" Style="z-index: 100;
        left: 0px; position: absolute; top: 38px" Width="98%">
        <ClientSettings>
            <Selecting AllowRowSelect="True" />
            <Scrolling AllowScroll="True" ScrollHeight="1px" UseStaticHeaders="True" />
        </ClientSettings>
        <MasterTableView DataKeyNames="PrimaryKey" GridLines="None" NoMasterRecordsText="No Workflow History available for this Transaction."
            Width="98%">
            <Columns>
                <telerik:GridBoundColumn DataField="WorkflowAction" HeaderText="Last Action" UniqueName="WorkflowAction">
                    <ItemStyle HorizontalAlign="Left" Width="20%" Wrap="True" />
                    <HeaderStyle Height="15px" Width="20%" Wrap="False" HorizontalAlign="Left" />
                </telerik:GridBoundColumn>
                <telerik:GridBoundColumn DataField="CreatedOnDate" HeaderText="On" UniqueName="CreatedOnDate">
                    <ItemStyle HorizontalAlign="Left" Width="15%" />
                    <HeaderStyle Height="15px" Width="15%" HorizontalAlign="Left" />
                </telerik:GridBoundColumn>
                <telerik:GridBoundColumn DataField="Notes" HeaderText="Notes" UniqueName="Notes">
                    <ItemStyle HorizontalAlign="Left" Width="30%" Wrap="true" />
                    <HeaderStyle Height="15px" Width="30%" HorizontalAlign="Left" />
                </telerik:GridBoundColumn>
                <telerik:GridBoundColumn DataField="CreatedBy" HeaderText="User" UniqueName="CreatedBy">
                    <ItemStyle HorizontalAlign="Left" Width="15%" />
                    <HeaderStyle Height="15px" Width="15%" HorizontalAlign="Left" />
                </telerik:GridBoundColumn>
            </Columns>
            <ExpandCollapseColumn Resizable="False" Visible="False">
                <HeaderStyle Width="20px" />
            </ExpandCollapseColumn>
            <RowIndicatorColumn Visible="False">
                <HeaderStyle Width="20px" />
            </RowIndicatorColumn>
            <HeaderStyle Wrap="False" />
        </MasterTableView>
    </telerik:RadGrid>
    
       <telerik:RadCodeBlock ID="RadCodeBlock1" runat="server">

        <script type="text/javascript" language="javascript">

            // Begin ******************* Menu Handlers ***********************

            var sCancelAjax;    // flag to disable ajax for grid export functions

            function ajaxRequestStart(sender, args) {
                //Called when ajax request starts so we can disable for grid export controls.
                if (sCancelAjax == 'Y') {
                    args.set_enableAjax(false);
                }
            }

            function ajaxRequestEnd(sender, args) {
                //Called when ajax request Ends.
                args.set_enableAjax(true);
            }

            function OnClientItemClicking(sender, args) {
                // set this var so that we can cancel ajax for grid export function
                var button = args.get_item();
                sCancelAjax = button.get_attributes().getAttribute("CancelAjax");
            }


            // End ******************* Menu Handlers ***********************

   
            function AddNote(id)    
            {

                var oManager = $find("<%=WinPops.ClientID%>");
                var oWnd = oManager.open('workflow_history_note_add.aspx?recid=' + id, 'AddNote');
                return false;

            }
        </script>

    </telerik:RadCodeBlock>
    
    
    
    
    
    
    
    
    
    
    
    </form>
</body>
</html>
