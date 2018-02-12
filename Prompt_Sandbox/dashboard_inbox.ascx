<%@ Control Language="vb" ClassName="InboxControl" %>
<%@ Register Assembly="Telerik.Web.UI" Namespace="Telerik.Web.UI" TagPrefix="telerik" %>
<%@ Import Namespace="Prompt" %>

<script runat="server">
    
    Private sDashboardType As String = ""
    Private CurrentView As String = ""
    Private IncludePaid As Boolean = False
    Dim view As String = ""
    
    Protected Sub Page_Init(ByVal sender As Object, ByVal e As System.EventArgs)
        
        If IsNothing(Session("inboxview")) Then
            Session("inboxview") = "MyOpenInboxItems"
        End If
        
        view = Session("inboxview")

 
    End Sub
    
    Private Sub Page_Load(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MyBase.Load

        'This Dashboard shows workflow items Normal workflow users of PROMPT (not dashboard only)
        
        Session("PageID") = "DashboardInboxIntegrated"

        sDashboardType = Request.QueryString("Type")

        ProcLib.LoadPopupJscript(Page)
        
        IncludePaid = Session("InboxShowPaid")
         
        lblAlert.Text = ""
        
        With grid_Inbox
            .EnableEmbeddedSkins = False
            .Skin = "Prompt"
            .GroupingEnabled = False
            .AllowSorting = True
            '.EnableViewState = False
            .AllowMultiRowSelection = True
            
            .ClientSettings.AllowColumnsReorder = False
            .ClientSettings.ColumnsReorderMethod = GridClientSettings.GridColumnsReorderMethod.Reorder
            .ClientSettings.Scrolling.AllowScroll = True
            .ClientSettings.Scrolling.ScrollHeight = Unit.Percentage(50)
            .ClientSettings.Scrolling.UseStaticHeaders = True
            .ClientSettings.Resizing.AllowColumnResize = True
            

            .MasterTableView.EnableHeaderContextMenu = False
            .MasterTableView.TableLayout = GridTableLayout.Fixed
            .MasterTableView.AllowMultiColumnSorting = False

            .Height = Unit.Pixel(310)
            
            .ExportSettings.FileName = "PromptInboxExport"
            .ExportSettings.OpenInNewWindow = True
            .ExportSettings.Pdf.PageTitle = "Prompt Inbox"
            
   
        End With
        
      
  
        'butMultiApprove.Visible = True
    
        With InboxPopups
            .VisibleOnPageLoad = False
            .Skin = "Windows7"
                         
            Dim ww As New RadWindow

            ww = New RadWindow
            With ww
                .ID = "WorkflowHistory"
                .NavigateUrl = ""
                .Title = ""
                .Width = 650
                .Height = 400
                .Top = 200
                .Left = 20
                .Modal = False
                .VisibleStatusbar = False
                .ReloadOnShow = True
                
                .Behaviors = WindowBehaviors.Close + WindowBehaviors.Move
            End With
            .Windows.Add(ww)
            
            
            ww = New RadWindow
            With ww
                .ID = "WorkflowApproval"
                .NavigateUrl = ""
                .Title = ""
                .Width = 500
                .Height = 300
                .Top = 200
                .Left = 20
                .Modal = False
                .VisibleStatusbar = False
                .ReloadOnShow = True
                .Behaviors = WindowBehaviors.Close + WindowBehaviors.Move
            End With
            .Windows.Add(ww)
            
            ww = New RadWindow
            With ww
                .ID = "ShowAttachmentsWindow"
                .NavigateUrl = ""
                .Title = ""
                .Width = 650
                .Height = 400
                .Top = 200
                .Left = 20
                .Modal = False
                .VisibleStatusbar = False
                .ReloadOnShow = True
                .Behaviors = WindowBehaviors.Close + WindowBehaviors.Move
            End With
            .Windows.Add(ww)
                      
            ww = New RadWindow
            With ww
                .ID = "ShowDialogPopup"
                .NavigateUrl = ""
                .Title = ""
                .Width = 400
                .Height = 200
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
    
   
    Protected Sub grid_Inbox_ItemDataBound(ByVal sender As Object, ByVal e As Telerik.Web.UI.GridItemEventArgs) Handles grid_Inbox.ItemDataBound

        'Customize the group column to show only the college name

        If TypeOf e.Item Is GridGroupHeaderItem Then

            Dim item As GridGroupHeaderItem = CType(e.Item, GridGroupHeaderItem)
            Dim groupDataRow As DataRowView = CType(e.Item.DataItem, DataRowView)

            item.DataCell.Text = ""    'Clear the present text of the cell
            Dim column As DataColumn
            For Each column In groupDataRow.DataView.Table.Columns
                If column.ColumnName = "College" Then
                    item.DataCell.Text = "<b>" + groupDataRow("College").ToString() + "</b>"
                    Exit For
                ElseIf column.ColumnName = "ProjectName" Then
                    item.DataCell.Text = "<b>" + groupDataRow("ProjectName").ToString() + "</b>"
                    Exit For
                End If
            Next column
      
        End If
    End Sub 
    
    
    Protected Sub grid_Inbox_NeedDataSource(ByVal source As Object, ByVal e As Telerik.Web.UI.GridNeedDataSourceEventArgs) Handles grid_Inbox.NeedDataSource
        'loads the grid whenever it needs data (sorting, rebinding, etc...)
          
        'Hide the approval columns by default
        With grid_Inbox.MasterTableView.Columns
            .FindByUniqueName("CurrentWorkflowOwner").Visible = False
            .FindByUniqueName("Select").Visible = False
            .FindByUniqueName("ApproveTransaction").Visible = False
            .FindByUniqueName("ReRouteTransaction").Visible = False
        End With
        
        Using db As New promptWorkflow
            db.CallingPage = Page

            Select Case view
                         
                Case "MyApproved"

                    grid_Inbox.DataSource = db.GetMyApprovedRejectedWorkflowItems("Approved", Session("WorkflowRoleID"))
                    grid_Inbox.MasterTableView.Columns.FindByUniqueName("CurrentWorkflowOwner").Visible = True
                    
                Case "MyRejected"

                    grid_Inbox.DataSource = db.GetMyApprovedRejectedWorkflowItems("Rejected", Session("WorkflowRoleID"))
                    grid_Inbox.MasterTableView.Columns.FindByUniqueName("CurrentWorkflowOwner").Visible = True

                Case "AllOpenWorkflowItems"
  
                    grid_Inbox.DataSource = db.GetAllOpenWorkflowItems()
                    grid_Inbox.MasterTableView.Columns.FindByUniqueName("CurrentWorkflowOwner").Visible = True
                    
                Case "AllFDOApproved"
  
                    grid_Inbox.DataSource = db.GetFDOApprovedTransactions()
                    grid_Inbox.MasterTableView.Columns.FindByUniqueName("CurrentWorkflowOwner").Visible = True
                
                Case Else    ' DEFAULT -- and MyOpenInboxItems
                    Session("inboxview") = "MyOpenInboxItems"
                    view = Session("inboxview")
 
                    grid_Inbox.DataSource = db.GetInboxWorkflowTransactions(Session("WorkflowRoleID"))
                  
            End Select
        End Using
    End Sub
        
    Protected Sub grid_Inbox_ItemCommand(ByVal source As Object, ByVal e As Telerik.Web.UI.GridCommandEventArgs)
        ' If multiple buttons are used in a Telerik RadGrid control, use the CommandName property to determine which button was clicked.
        If e.CommandName = "FindTransaction" Then       'autolocate the nav menu and main page to the contract show area for transaction
            Dim Args = Split(e.CommandArgument, ",")
            Dim RecID As Integer = Args(0)
            Dim ContractID As Integer = Args(1)
            Dim ProjectID As Integer = Args(2)
            Dim CollegeID As Integer = Args(3)
            Dim RecType As String = Args(4)
             
            Session("RefreshNav") = True
            Session("RtnFromEdit") = False
            Session("CollegeID") = CollegeID
            Session("DirectCallCount") = 1
         
            If RecType = "Transaction" Then
                Session("nodeid") = "Contract" & ContractID
                Session("DirectCallURL") = "transactions.aspx?view=contract&ContractID=" & ContractID & "&ProjectID=" & ProjectID & "&CollegeID=" & CollegeID & "&t=y"
            Else
                Session("nodeid") = "Project" & ProjectID
                Session("DirectCallURL") = "PADS.aspx?view=project&ProjectID=" & ProjectID & "&CollegeID=" & CollegeID & "&t=y"

            End If
            
 
            Response.Redirect("main.aspx")
      
            
        End If
        
        
        If e.CommandName = "ReRouteTransaction" Then       'reRoute this transaction to current user
            Dim TransID As Integer = e.CommandArgument
            Using db As New promptWorkflow
                With db
                    .CallingPage = Page
                    .Action = "ReRouted By Sender"
                    .TransactionID = TransID
                    .Target = Session("WorkflowRole")
                    .TargetRoleID = Session("WorkflowRoleID")
                End With
                db.RouteTransaction()
            End Using
            
            grid_Inbox.Rebind()
 
        End If
        
 
    End Sub
  
    Protected Sub grid_Inbox_ItemCreated(ByVal sender As Object, ByVal e As Telerik.Web.UI.GridItemEventArgs) Handles grid_Inbox.ItemCreated
        'This event allows us to customize the cell contents - fired before databound
          
        If (TypeOf e.Item Is GridDataItem) Then
 
            Dim item As GridDataItem = CType(e.Item, GridDataItem)
            Dim nContractID As Integer = item.OwnerTableView.DataKeyValues(item.ItemIndex)("ContractID")
            Dim nTranID As Integer = item.OwnerTableView.DataKeyValues(item.ItemIndex)("TransactionID")
            Dim nPADID As Integer = item.OwnerTableView.DataKeyValues(item.ItemIndex)("PADID")
            Dim nProjectID As Integer = item.OwnerTableView.DataKeyValues(item.ItemIndex)("ProjectID")
            Dim nCollegeID As Integer = item.OwnerTableView.DataKeyValues(item.ItemIndex)("CollegeID")
            Dim sTransType As String = item.OwnerTableView.DataKeyValues(item.ItemIndex)("TransType")
            Dim nAttachments As Integer = item.OwnerTableView.DataKeyValues(item.ItemIndex)("Attachments")
            Dim sStatus As String = item.OwnerTableView.DataKeyValues(item.ItemIndex)("Status")
            Dim sContractType As String = item.OwnerTableView.DataKeyValues(item.ItemIndex)("ContractType")
            Dim sLastWorkflowAction As String = IIf(IsDBNull(item.OwnerTableView.DataKeyValues(item.ItemIndex)("LastWorkflowAction")), " ", item.OwnerTableView.DataKeyValues(item.ItemIndex)("LastWorkflowAction"))
            
            Dim nPreviousWorkflowRoleID As Integer = IIf(IsDBNull(item.OwnerTableView.DataKeyValues(item.ItemIndex)("PreviousWorkflowRoleID")), 0, item.OwnerTableView.DataKeyValues(item.ItemIndex)("PreviousWorkflowRoleID"))
            
            'update the link button to open attachments/notes window
            Dim linkButton As HyperLink = CType(item("ShowAttachments").Controls(0), HyperLink)
            
            If sTransType = "PAD" Then
                linkButton.Attributes("onclick") = "return ShowPADAttachments('" & nPADID & "');"
                linkButton.ToolTip = "Shows any attachments linked to this PAD."
            Else
                linkButton.Attributes("onclick") = "return ShowAttachments('" & nTranID & "');"
                linkButton.ToolTip = "Shows any attachments linked to this Transaction."
            
            End If
            linkButton.ImageUrl = "images/paper_clip_small.gif"
            linkButton.NavigateUrl = "#"
            If nAttachments > 0 Then
                linkButton.Visible = True
            Else
                linkButton.Visible = False
            End If
            

            If view = "MyOpenInboxItems" And (sStatus = "FDO Approved" Or sStatus = "Pending Approval") And nAttachments > 0 Then
                'update the link button to approve/reject transactions
                Dim linkButton1a As HyperLink = CType(item("ApproveTransaction").Controls(0), HyperLink)
                If sTransType = "PAD" Then
                    linkButton1a.Attributes("onclick") = "return ShowWorkflowApproval('PAD','" & nPADID & "');"
                Else
                    linkButton1a.Attributes("onclick") = "return ShowWorkflowApproval('Transaction','" & nTranID & "');"
                End If
                
                linkButton1a.ToolTip = "Approve or Reject this item."
                linkButton1a.ImageUrl = "images/workflow_send.png"
                linkButton1a.NavigateUrl = "#"
                
                'show the column as there are records
                grid_Inbox.MasterTableView.Columns.FindByUniqueName("ApproveTransaction").Visible = True
  
            End If
            
            
            If view = "AllFDOApproved" Or view = "MyOpenInboxItems" Then
           
                grid_Inbox.MasterTableView.Columns.FindByUniqueName("ReRouteTransaction").Visible = False
            
            Else
                ''update the link button to reroute transaction
                Dim linkButton3a As ImageButton = CType(item("ReRouteTransaction").Controls(0), ImageButton)
                linkButton3a.CommandArgument = nTranID
                linkButton3a.ToolTip = "ReRoute this Transaction back to you."
                linkButton3a.ImageUrl = "images/route_undo.png"
            
                If Session("WorkflowRoleID") Is Nothing Then
                    Session("WorkflowRoleID") = 0
                Else
               
                    If Session("WorkflowRoleID") = nPreviousWorkflowRoleID And sStatus = "FDO Approved" Then   'this user was last to act so can reroute back
           
                        grid_Inbox.MasterTableView.Columns.FindByUniqueName("ReRouteTransaction").Visible = True  'only show the column if this is the previous owner (whole column will hide if no items qualify)
            
                    Else 'for this item, this is not previous owner, but there might be other items that are so column needs to show, but hide button
               
                        linkButton3a.Visible = False
                    End If
                End If
            
            End If

            'update the link button to view history
            Dim linkButton2 As HyperLink = CType(item("WorkflowHistory").Controls(0), HyperLink)
            If sTransType = "PAD" Then
                linkButton2.Attributes("onclick") = "return ShowWorkflowHistory('PAD','" & nPADID & "');"
            Else
                linkButton2.Attributes("onclick") = "return ShowWorkflowHistory('Transaction','" & nTranID & "');"
            End If
            
            linkButton2.ToolTip = "View Workflow History."
            linkButton2.ImageUrl = "images/workflow_history.png"
            linkButton2.NavigateUrl = "#"
                
            ''update the link button to find record
            Dim linkButton3 As ImageButton = CType(item("FindTransaction").Controls(0), ImageButton)
            If sTransType <> "PAD" Then
                linkButton3.CommandArgument = nTranID & "," & nContractID & "," & nProjectID & "," & nCollegeID & ",Transaction"
                linkButton3.ToolTip = "Go to Transaction."
                linkButton3.ImageUrl = "images/dashboard_transaction_goto.png"
            Else
                linkButton3.CommandArgument = nPADID & "," & nContractID & "," & nProjectID & "," & nCollegeID & ",PAD"
                linkButton3.ToolTip = "Go to PAD."
                linkButton3.ImageUrl = "images/dashboard_transaction_goto.png"
            End If

            
            
  
            'update the link button to open Transaction directly
            Dim linkButton4 As HyperLink = CType(item("OpenTransaction").Controls(0), HyperLink)
            If sTransType <> "PAD" Then
                
                If sTransType = "RetInvoice" Then
                    linkButton4.Attributes.Add("onclick", "openPopup('retention_edit.aspx?CollegeID=" & nCollegeID & "&ID=" & nTranID & "&ProjectID=" & nProjectID & "&ContractID=" & nContractID & "','editRetTrans',650,700,'yes');")
                Else
                    linkButton4.Attributes.Add("onclick", "openPopup('transaction_edit.aspx?CollegeID=" & nCollegeID & "&ID=" & nTranID & "&ProjectID=" & nProjectID & "&ContractID=" & nContractID & "','editTrans',650,700,'yes');")
                End If
                linkButton4.ToolTip = "Directly open this Transaction."
                linkButton4.ImageUrl = "images/transaction_dashboard_edit.png"
                linkButton4.NavigateUrl = "#"
            
            Else   'hide the direct edit link
                linkButton4.Visible = False
 
            End If
 
            

            
            
            'set the background color based on Transaction status
            If sLastWorkflowAction = "Rejected" Then    'if the item was rejected back to the user show color
                item.ForeColor = Color.Red
                item.Font.Bold = True
            Else
                Select Case sStatus
                    Case "Paid"
                        item.ForeColor = Color.Gray
                    
                    Case Else
                        item.ForeColor = Color.Green
                End Select
                
                'Append Flag to Type if Demand Check
                If (sContractType = "ICA" Or sContractType = "Check Request") And sStatus <> "Paid" Then
                    item.ForeColor = Color.Purple
               
                End If
                
            End If
            
            If sTransType = "Accrual" Then
                item.ForeColor = Color.Maroon
            End If
             
        End If
    End Sub
  
 
    Protected Sub butPrint_Click(ByVal sender As Object, ByVal e As System.Web.UI.ImageClickEventArgs)
        grid_Inbox.MasterTableView.ExportToExcel()
    End Sub

    Protected Sub butMultiApprove_Click1(ByVal sender As Object, ByVal e As System.Web.UI.ImageClickEventArgs)
        
        If Session("AlreadyCalled") = False Then   'needed to prevent reloading after close of child window
            'Get list of selected transactions
            Dim sTransList As String = ""
            For Each item As GridDataItem In grid_Inbox.MasterTableView.Items
                If item.Selected = True Then
                    sTransList &= item.GetDataKeyValue("TransactionID").ToString & ","
                End If
            
            Next
        
            If sTransList <> "" Then
                Session("AlreadyCalled") = True
                'call approval window
                lblAlert.Text = "<script language='javascript'> window.onload = function(){return ShowMultiWorkflowApproval('" & sTransList & "');}</" & "script>"
            Else
                lblAlert.Text = ""
            End If
            
        Else
            lblAlert.Text = ""
            Session("AlreadyCalled") = False
            grid_Inbox.Rebind()
        End If
 
 
    End Sub

 
</script>

    <telerik:RadGrid  ID="grid_Inbox"
        OnItemCommand="grid_Inbox_ItemCommand" runat="server" AllowSorting="True" AutoGenerateColumns="False"
        GridLines="None" Width="99%" EnableAJAX="True" Height=" " AllowMultiRowSelection="True">
       
        <ClientSettings>
            <Scrolling AllowScroll="True" UseStaticHeaders="True" ScrollHeight="50%" />
            <Selecting AllowRowSelect="true" />
            <Resizing AllowColumnResize="True" />
        </ClientSettings>
        <MasterTableView Width="98%" GridLines="None" NoMasterRecordsText="No Items Found."
            ShowHeadersWhenNoRecords="false" DataKeyNames="TransactionID,ContractID,ProjectID,TransType,CollegeID,PADID,
                PreviousWorkflowRoleID,Status,Attachments,LastWorkflowAction,ContractType,ModTransType">
            <Columns>
                <telerik:GridClientSelectColumn UniqueName="Select">
                    <ItemStyle Width="35px" HorizontalAlign="Center" VerticalAlign="Top" />
                    <HeaderStyle Width="35px" HorizontalAlign="Center" />
                </telerik:GridClientSelectColumn>
                <telerik:GridHyperLinkColumn HeaderText="Route" UniqueName="ApproveTransaction">
                    <ItemStyle Width="35px" HorizontalAlign="Center" VerticalAlign="Top" />
                    <HeaderStyle Width="35px" HorizontalAlign="Center" />
                </telerik:GridHyperLinkColumn>
                <telerik:GridButtonColumn ButtonType="ImageButton" Visible="True" CommandName="ReRouteTransaction"
                    HeaderText="" UniqueName="ReRouteTransaction" Reorderable="False" ShowSortIcon="False">
                    <ItemStyle Width="35px" HorizontalAlign="Center" VerticalAlign="Top" />
                    <HeaderStyle Width="35px" HorizontalAlign="Center" />
                </telerik:GridButtonColumn>
                <telerik:GridHyperLinkColumn HeaderText="Att" UniqueName="ShowAttachments">
                    <ItemStyle Width="35px" HorizontalAlign="Center" VerticalAlign="Top" />
                    <HeaderStyle Width="35px" HorizontalAlign="Center" />
                </telerik:GridHyperLinkColumn>
                <telerik:GridHyperLinkColumn HeaderText="Hist" UniqueName="WorkflowHistory">
                    <ItemStyle Width="35px" HorizontalAlign="Center" VerticalAlign="Top" />
                    <HeaderStyle Width="35px" HorizontalAlign="Center" />
                </telerik:GridHyperLinkColumn>
                <telerik:GridHyperLinkColumn HeaderText="Open" UniqueName="OpenTransaction">
                    <ItemStyle Width="40px" HorizontalAlign="Center" VerticalAlign="Top" />
                    <HeaderStyle Width="40px" HorizontalAlign="Center" />
                </telerik:GridHyperLinkColumn>
                <telerik:GridButtonColumn ButtonType="ImageButton" Visible="True" CommandName="FindTransaction"
                    HeaderText="Find" UniqueName="FindTransaction" Reorderable="False" ShowSortIcon="False">
                    <ItemStyle Width="35px" HorizontalAlign="Center" VerticalAlign="Top" />
                    <HeaderStyle Width="35px" HorizontalAlign="Center" />
                </telerik:GridButtonColumn>
                <telerik:GridBoundColumn DataField="College" UniqueName="College" HeaderText="College">
                    <ItemStyle Width="65px" HorizontalAlign="Left" VerticalAlign="Top" />
                    <HeaderStyle Width="65px" HorizontalAlign="Left" />
                </telerik:GridBoundColumn>
                <telerik:GridBoundColumn DataField="ProjectName" UniqueName="ProjectName" HeaderText="Project">
                    <ItemStyle HorizontalAlign="Left" VerticalAlign="Top" Width="65px" />
                    <HeaderStyle HorizontalAlign="Left" Width="65px" Height="15px" />
                </telerik:GridBoundColumn>
                <telerik:GridBoundColumn DataField="ProjectNumber" UniqueName="ProjectNumber" HeaderText="Proj#">
                    <ItemStyle HorizontalAlign="Left" Width="35px" VerticalAlign="Top" />
                    <HeaderStyle HorizontalAlign="Left" Width="35px" Height="15px" />
                </telerik:GridBoundColumn>
                <telerik:GridBoundColumn HeaderText="Contractor" UniqueName="Contractor" DataField="Contractor">
                    <ItemStyle HorizontalAlign="Left" Width="65px" Wrap="true" VerticalAlign="Top" />
                    <HeaderStyle HorizontalAlign="Left" Width="65px" Wrap="true" VerticalAlign="Top" />
                </telerik:GridBoundColumn>
                <telerik:GridBoundColumn DataField="InvoiceNumber" HeaderText="Inv#" UniqueName="InvoiceNumber">
                    <ItemStyle HorizontalAlign="Center" Width="65px" Wrap="false" VerticalAlign="Top" />
                    <HeaderStyle HorizontalAlign="Center" Width="65px" Wrap="false" />
                </telerik:GridBoundColumn>
                <telerik:GridBoundColumn DataField="ModTransType" HeaderText="Type" UniqueName="TransType">
                    <ItemStyle HorizontalAlign="Center" Width="65px" Wrap="true" VerticalAlign="Top" />
                    <HeaderStyle HorizontalAlign="Center" Width="65px" Wrap="true" />
                </telerik:GridBoundColumn>
                <telerik:GridBoundColumn DataField="InvoiceDate" HeaderText="InvDate" UniqueName="InvDate"
                    DataFormatString="{0:MM/dd/yy}">
                    <ItemStyle Width="65px" HorizontalAlign="Center" VerticalAlign="Top" />
                    <HeaderStyle Width="65px" Height="20px" HorizontalAlign="Center" />
                </telerik:GridBoundColumn>
                <telerik:GridBoundColumn DataField="AccountNumber" HeaderText="Acct#" UniqueName="AccountNumber">
                    <ItemStyle Width="75px" HorizontalAlign="Center" VerticalAlign="Top" />
                    <HeaderStyle Width="75px" Height="20px" HorizontalAlign="Center" />
                </telerik:GridBoundColumn>
                <telerik:GridBoundColumn DataField="POLineNumber" HeaderText="POLine" UniqueName="POLineNumber">
                    <ItemStyle Width="15px" HorizontalAlign="Center" VerticalAlign="Top" />
                    <HeaderStyle Width="15px" Height="20px" HorizontalAlign="Center" />
                </telerik:GridBoundColumn>
                <telerik:GridBoundColumn DataField="TotalAmount" HeaderText="Total" UniqueName="TotalAmount"
                    DataFormatString="{0:c}">
                    <ItemStyle Width="70px" HorizontalAlign="Right" VerticalAlign="Top" />
                    <HeaderStyle Width="70px" HorizontalAlign="Right" />
                </telerik:GridBoundColumn>
                <telerik:GridBoundColumn DataField="RetentionAmount" HeaderText="Retention" UniqueName="RetentionAmount"
                    DataFormatString="{0:c}">
                    <ItemStyle Width="70px" HorizontalAlign="Right" VerticalAlign="Top" />
                    <HeaderStyle Width="70px" HorizontalAlign="Right" />
                </telerik:GridBoundColumn>
                <telerik:GridBoundColumn DataField="RetentionAccountNumber" HeaderText="RetAcct#" UniqueName="RetentionAccountNumber">
                    <ItemStyle Width="75px" HorizontalAlign="Center" VerticalAlign="Top" />
                    <HeaderStyle Width="75px" Height="20px" HorizontalAlign="Center" />
                </telerik:GridBoundColumn>
                <telerik:GridBoundColumn DataField="PayableAmount" HeaderText="Payable" UniqueName="PayableAmount"
                    DataFormatString="{0:c}">
                    <ItemStyle Width="70px" HorizontalAlign="Right" VerticalAlign="Top" />
                    <HeaderStyle Width="70px" HorizontalAlign="Right" />
                </telerik:GridBoundColumn>
                <telerik:GridBoundColumn DataField="TaxAdjustmentAmount" HeaderText="TaxAdj" UniqueName="TaxAdjustmentAmount"
                    DataFormatString="{0:c}">
                    <ItemStyle Width="70px" HorizontalAlign="Right" VerticalAlign="Top" />
                    <HeaderStyle Width="70px" HorizontalAlign="Right" />
                </telerik:GridBoundColumn>
                <telerik:GridBoundColumn DataField="TaxLiabilityAccountNumber" HeaderText="TaxAcct#"
                    UniqueName="TaxLiabilityAccountNumber">
                    <ItemStyle Width="75px" HorizontalAlign="Center" VerticalAlign="Top" />
                    <HeaderStyle Width="75px" Height="20px" HorizontalAlign="Center" />
                </telerik:GridBoundColumn>
 
                <telerik:GridBoundColumn DataField="CurrentWorkflowOwner" HeaderText="Owner" UniqueName="CurrentWorkflowOwner">
                    <ItemStyle Width="75px" HorizontalAlign="Center" VerticalAlign="Top" />
                    <HeaderStyle Width="75px" HorizontalAlign="Center" />
                </telerik:GridBoundColumn>
                <telerik:GridBoundColumn DataField="Status" HeaderText="Status" UniqueName="Status">
                    <ItemStyle Width="75px" HorizontalAlign="Center" VerticalAlign="Top" />
                    <HeaderStyle Width="75px" HorizontalAlign="Center" />
                </telerik:GridBoundColumn>
            </Columns>
            <ExpandCollapseColumn Resizable="False">
                <HeaderStyle Width="20px" />
            </ExpandCollapseColumn>
            <RowIndicatorColumn Visible="False">
                <HeaderStyle Width="20px" />
            </RowIndicatorColumn>
            <GroupHeaderItemStyle VerticalAlign="Bottom" />
        </MasterTableView>
        <ExportSettings FileName="PromptInboxExport" OpenInNewWindow="True">
        </ExportSettings>
    </telerik:RadGrid>
   
   
   
    
    <%--for handling alerts and ajax callback--%>
   <asp:Label ID="lblAlert" runat="server" Height="24px" Style="z-index: 112; left: 370px;
        position: absolute; top: 83px"></asp:Label>
        
        
        
 <%--   <asp:Image ID="imgColorCode" Style="z-index: 112; left: 570px; position: absolute;
        top: 40px" runat="server" ImageUrl="images/workflow_colorcode.gif"></asp:Image>--%>
   <%-- <asp:CheckBox ID="chkShowPaid" Style="z-index: 112; left: 458px; position: absolute;
        top: 31px" runat="server" Text="Show Paid" AutoPostBack="True" />--%>
   
    <telerik:RadWindowManager ID="InboxPopups" runat="server">
    </telerik:RadWindowManager>
   
<telerik:RadCodeBlock ID="RadCodeBlock1" runat="server">
<script type="text/javascript" language="javascript">

       
    
        function ShowAttachments(id)     //for attachments info display
        {
            var oManager = $find("<%=InboxPopups.ClientID%>");
            var oWnd = oManager.open('dashboard_view_attachments.aspx?TransactionID=' + id, 'ShowAttachmentsWindow');
            return false;

        }

        function ShowPADAttachments(id)     //for attachments info display
        {
            var oManager = $find("<%=InboxPopups.ClientID%>");
            var oWnd = oManager.open('apprisepm_attachments_manage.aspx?ParentType=PAD&ParentID=' + id + '&ProjectID=0', 'ShowAttachmentsWindow');
            return false;
        }

        
        function ShowWorkflowApproval(rectype,id)     //for workflow approval display
        {
            var oManager = $find("<%=InboxPopups.ClientID%>");
            var oWnd = oManager.open('workflow_route.aspx?rectype=' + rectype + '&recid=' + id + '&CalledFrom=Dashboard', 'WorkflowApproval');
            return false;
        }

        function ShowMultiWorkflowApproval(slist)     //for workflow Multiple approval display
        {

            var oWnd = window.radopen("workflow_route_multiple.aspx?TransactionList=" + slist + "&CalledFrom=Dashboard", "WorkflowApproval");
            return false;
        }

        function ShowWorkflowHistory(rectype,id)     //for workflow history display
        {


            var oManager = $find("<%=InboxPopups.ClientID%>");
            var oWnd = oManager.open('workflow_history_view.aspx?rectype=' + rectype + '&recid=' + id, 'WorkflowHistory');
            return false;


        }

        function refreshGrid() {
            RadGridNamespace.AsyncRequest('<%= grid_Inbox.UniqueID %>', 'Rebind', '<%= grid_Inbox.ClientID %>');
        }

        function GetRadWindow() {
            var oWindow = null;
            if (window.RadWindow) oWindow = window.RadWindow;
            else if (window.frameElement.radWindow) oWindow = window.frameElement.radWindow;
            return oWindow;
        }

  

      
    </script>
</telerik:RadCodeBlock>

