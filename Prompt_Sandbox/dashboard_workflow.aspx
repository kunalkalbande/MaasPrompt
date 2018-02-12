<%@ Page Language="VB" MasterPageFile="~/prompt.master" Title="Prompt Workflow Dashboard" %>

<%@ Register Assembly="Telerik.Web.UI" Namespace="Telerik.Web.UI" TagPrefix="telerik" %>
<%@ Import Namespace="Prompt" %>

<script runat="server">
    
    'NOTE:  Currently this page is only used for FHDA District AP dashboard
    
    Private CurrentRoleID As Integer = 0
    Private CurrentRoleType As String = ""
    
    Private CurrentView As String = ""
    Private lstCurrentView As RadComboBox
    
    Private nInBoxItemCount As Integer = 0
    
    Private bWorkflowDataTransferEnabled As Boolean = False

    Private Sub Page_Load(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MyBase.Load

        Session("PageID") = "WorkflowDashboard_Standalone"
         
        CurrentRoleID = Session("WorkflowRoleID")
        CurrentRoleType = Session("WorkflowRoleType")
        
        'check to see if this district has electronic data transfer turned on 
        Using db As New PromptDataHelper
            Dim result As Integer = db.ExecuteScalar("SELECT EnableWorkflowDataTransfer FROM Districts WHERE DistrictID = " & Session("DistrictID"))
            If result = 1 Then
                bWorkflowDataTransferEnabled = True
            End If
        End Using
                
        'Reconfigure some master page elements
        Dim masterMenu As RadMenu = Master.FindControl("RadMenu1")
        masterMenu.FindItemByValue("Reports").Visible = False
        masterMenu.FindItemByValue("Administration").Visible = False
        masterMenu.FindItemByValue("Home").NavigateUrl = Session("StartPageName")
        
        Master.Page.Title = "EIS " & CurrentRoleType & " Workflow Dashboard"
        
        Dim lstmenu As RadMenuItem = RadMenu1.FindItemByValue("DDBOX")
        lstCurrentView = DirectCast(lstmenu.FindControl("lstCurrentViewTemplate"), RadComboBox)

        
        With RadGrid1
            .EnableEmbeddedSkins = False
            .Skin = "Prompt"
            .GroupingEnabled = False
            .AllowSorting = True
            .AllowMultiRowSelection = True
            
            .ClientSettings.AllowColumnsReorder = False
            .ClientSettings.ColumnsReorderMethod = GridClientSettings.GridColumnsReorderMethod.Reorder
            .ClientSettings.Scrolling.AllowScroll = True
            .ClientSettings.Scrolling.ScrollHeight = Unit.Percentage(50)
            .ClientSettings.Scrolling.UseStaticHeaders = True
            .ClientSettings.Resizing.AllowColumnResize = True
            .ClientSettings.Scrolling.FrozenColumnsCount = 3    'locks left 3 columns
            

            .MasterTableView.EnableHeaderContextMenu = False
            .MasterTableView.TableLayout = GridTableLayout.Fixed
            .MasterTableView.AllowMultiColumnSorting = False

            .Height = Unit.Pixel(500)
            
            .ExportSettings.FileName = "PromptInboxExport"
            .ExportSettings.OpenInNewWindow = True
            .ExportSettings.Pdf.PageTitle = "Prompt Inbox"
            
   
        End With
        
        RadGrid1.MasterTableView.ClearSelectedItems()
        
        BuildMenu()

        If Not IsPostBack Then
           
            CurrentView = "Inbox"
            
            
            'Add list box items
             
            Dim item As RadComboBoxItem

            item = New RadComboBoxItem
            item.Value = "Inbox"
            item.Text = "Inbox"
            item.Selected = True
            lstCurrentView.Items.Add(item)

            item = New RadComboBoxItem
            item.Value = "Unpaid Approved or Rejected"
            item.Text = "Unpaid Approved or Rejected"
            lstCurrentView.Items.Add(item)
            
            item = New RadComboBoxItem
            item.Value = "All Paid"
            item.Text = "All Paid"
            lstCurrentView.Items.Add(item)
            
            
            If CurrentRoleType = "District AP" Then
                item = New RadComboBoxItem
                item.Value = "District for Payment"
                item.Text = "District for Payment"
                lstCurrentView.Items.Add(item)
            
                If bWorkflowDataTransferEnabled Then   'only relavent when data transfer is enabled
                    item = New RadComboBoxItem
                    item.Value = "Ready To Transfer"
                    item.Text = "Ready To Transfer"
                    lstCurrentView.Items.Add(item)
                End If
            End If

            SetCurrentView()
 
        Else
            CurrentView = lstCurrentView.Text
        End If
        
        
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
    
    Private Sub BuildMenu()
        
        If Not IsPostBack Then          'Configure Tool Bar
            
            With RadMenu1
                .EnableEmbeddedSkins = False
                .Skin = "Prompt"
                .Width = Unit.Percentage(100)
                .EnableOverlay = False
                .OnClientItemClicking = "OnClientItemClicking"
 
                .CollapseAnimation.Duration = "200"
                .CollapseAnimation.Type = AnimationType.InOutBounce
                .ExpandAnimation.Duration = "200"
                .ExpandAnimation.Type = AnimationType.InOutBounce
            End With
            
            'build buttons
            Dim but As New RadMenuItem
            With but
                .Text = "Approve Selected"
                .Value = "Approve Selected"
                .ImageUrl = "images/workflow_send.png"
                .ToolTip = "Approve Selected Transactions"
                .Attributes.Add("onclick", "ShowMultiWorkflowApproval();")
                .PostBack = False
            End With
            RadMenu1.Items.Add(but)
  
            Dim butDropDown As New RadMenuItem
            With butDropDown
                .Text = "Transfer To District"
                .Value = "Transfer To District"
                .ImageUrl = "images/data_down.png"
                .PostBack = True
            End With
            RadMenu1.Items.Add(butDropDown)

            ''Add sub items
            'Dim butSub As New RadMenuItem
            'With butSub
            '    .Text = "Export To Excel"
            '    .Value = "ExportExcel"
            '    .Attributes("CancelAjax") = "Y"   'NOTE: This is needed to cancel ajax call and do regular postback as grid export to pdf/execl does not work with ajax
            '    .ImageUrl = "images/excel.gif"
            '    .PostBack = True
            'End With
            'butDropDown.Items.Add(butSub)
            
            'butDropDown = New RadMenuItem
            'With butDropDown
            '    .Text = "Print"
            '    .ImageUrl = "images/printer.png"
            '    .PostBack = False
            'End With
 
            'butSub = New RadMenuItem
            'With butSub
            '    .Text = "Workflow Aging Report"
            '    .ImageUrl = "images/printer.png"
            '    .Target = "_new"
            '    .NavigateUrl = "http://216.129.104.66/q34jf8sfa?/PromptReports/FHDA_FRSDailyComparison&Dist=55"
            '    .PostBack = False
            'End With
            'butDropDown.Items.Add(butSub)
            
            'RadMenu1.Items.Add(butDropDown)
            
            but = New RadMenuItem
            but.IsSeparator = True
            RadMenu1.Items.Add(but)
            
            but = New RadMenuItem
            With but
                .Text = " "
                .ImageUrl = "images/workflow_colorcode.gif"
                .PostBack = False
            End With
            RadMenu1.Items.Add(but)
            
 
        End If

    End Sub
    
    Private Sub SetCurrentView()
          
        RadMenu1.FindItemByText("Approve Selected").Visible = False
        RadMenu1.FindItemByText("Transfer To District").Visible = False
        
        Select Case CurrentView
            Case "Inbox"
                RadGrid1.Columns.FindByUniqueName("ApproveTransaction").Visible = True
                RadGrid1.Columns.FindByUniqueName("CurrentWorkflowOwner").Visible = False
                RadGrid1.Columns.FindByUniqueName("ReRouteTransaction").Visible = False
                RadGrid1.Columns.FindByUniqueName("Status").Visible = False
                RadGrid1.Columns.FindByUniqueName("Select").Visible = True

                RadGrid1.MasterTableView.ClearSelectedItems()
                
            Case "Unpaid Approved or Rejected"

                RadGrid1.Columns.FindByUniqueName("ApproveTransaction").Visible = False
                RadGrid1.Columns.FindByUniqueName("CurrentWorkflowOwner").Visible = True
                RadGrid1.Columns.FindByUniqueName("ReRouteTransaction").Visible = True
                RadGrid1.Columns.FindByUniqueName("Status").Visible = True
                RadGrid1.Columns.FindByUniqueName("Select").Visible = False
 
                
            Case "All Paid"

                RadGrid1.Columns.FindByUniqueName("ApproveTransaction").Visible = False
                RadGrid1.Columns.FindByUniqueName("CurrentWorkflowOwner").Visible = False
                RadGrid1.Columns.FindByUniqueName("ReRouteTransaction").Visible = False
                RadGrid1.Columns.FindByUniqueName("Status").Visible = True
                RadGrid1.Columns.FindByUniqueName("Select").Visible = False
                
            Case "District for Payment"

                RadGrid1.Columns.FindByUniqueName("ApproveTransaction").Visible = False
                RadGrid1.Columns.FindByUniqueName("ReRouteTransaction").Visible = True
                RadGrid1.Columns.FindByUniqueName("CurrentWorkflowOwner").Visible = False
                RadGrid1.Columns.FindByUniqueName("Status").Visible = True
                RadGrid1.Columns.FindByUniqueName("Select").Visible = False
 
            
            Case "Ready To Transfer"

                RadGrid1.Columns.FindByUniqueName("ApproveTransaction").Visible = False
                RadGrid1.Columns.FindByUniqueName("ReRouteTransaction").Visible = True
                RadGrid1.Columns.FindByUniqueName("CurrentWorkflowOwner").Visible = False
                RadGrid1.Columns.FindByUniqueName("Status").Visible = False
                RadGrid1.Columns.FindByUniqueName("Select").Visible = False

        End Select
 
    End Sub
    
      
    Protected Sub RadGrid1_ItemCommand(ByVal source As Object, ByVal e As Telerik.Web.UI.GridCommandEventArgs)
        ' If multiple buttons are used in a Telerik RadGrid control, use the
        ' CommandName property to determine which button was clicked.
          
        Select Case e.CommandName
            
            Case "ReRouteTransaction"        'reRoute this transaction to current user
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

        
        End Select
 
        RadGrid1.Rebind()
 
    End Sub
    
    Protected Sub RadGrid1_NeedDataSource(ByVal source As Object, ByVal e As Telerik.Web.UI.GridNeedDataSourceEventArgs) Handles RadGrid1.NeedDataSource
        'loads the grid whenever it needs data (sorting, rebinding, etc...)
        
        Dim tbl As DataTable
        'nInBoxItemCount = 0
        
        Using db As New promptWorkflow
            db.CallingPage = Page
            
            Select Case CurrentView
                
                Case "Unpaid Approved or Rejected"
                    tbl = db.GetPendingWorkflowTransactions(CurrentRoleID)
                     
                    'Case "District for Payment"
                    '    tbl = db.GetDistrictForPaymentTransactions()

                    'Case "Ready To Transfer"
                    '    tbl = db.GetDistrictTransactionsForTransfer()
                    
                    If tbl.Rows.Count > 0 Then
                        RadMenu1.FindItemByText("Transfer To District").Visible = True
                    Else
                        RadMenu1.FindItemByText("Transfer To District").Visible = False
                    
                    End If
                    
                Case "All Paid"
                    tbl = db.GetPaidWorkflowTransactions(CurrentRoleID)

                Case Else   'inbox
                    tbl = db.GetInboxWorkflowTransactions(CurrentRoleID)
 
                    If tbl.Rows.Count > 1 Then
                        
                        If CurrentRoleType = "District AP" Then
                            If bWorkflowDataTransferEnabled Then
                                RadGrid1.Columns.FindByUniqueName("Select").Visible = True
                                RadMenu1.FindItemByText("Approve Selected").Visible = True
                            Else                                                            'we are manually approving each one so disable multi
                                RadGrid1.Columns.FindByUniqueName("Select").Visible = False
                                RadMenu1.FindItemByText("Approve Selected").Visible = False
                            End If
                        
                        Else            'this is a signator so enable multi
                            
                            RadMenu1.FindItemByText("Approve Selected").Visible = True
                            RadGrid1.Columns.FindByUniqueName("Select").Visible = True
                        End If

                    Else    ' there is one item or less so just manually approve
                        RadMenu1.FindItemByText("Approve Selected").Visible = False
                        RadGrid1.Columns.FindByUniqueName("Select").Visible = False
                    End If
                    
                    'TODO:Disable multi route for everyone except Ellen for time being
                    If CurrentRoleType <> "District AP" Then
                        RadGrid1.Columns.FindByUniqueName("Select").Visible = False
                        RadMenu1.FindItemByText("Approve Selected").Visible = False
                    End If
                    
                    
            End Select
            
            RadGrid1.DataSource = tbl
            
        End Using
        
    End Sub
    
    Protected Sub RadGrid1_ItemCreated(ByVal sender As Object, ByVal e As Telerik.Web.UI.GridItemEventArgs) Handles RadGrid1.ItemCreated
        'This event allows us to customize the cell contents - fired before databound
        
        If (TypeOf e.Item Is GridDataItem) Then
            
            Dim item As GridDataItem = CType(e.Item, GridDataItem)
            Dim nContractID As Integer = item.OwnerTableView.DataKeyValues(item.ItemIndex)("ContractID")
            Dim nTranID As Integer = item.OwnerTableView.DataKeyValues(item.ItemIndex)("TransactionID")
            Dim sStatus As String = item.OwnerTableView.DataKeyValues(item.ItemIndex)("Status")
            Dim sLastWorkflowAction As String = IIf(IsDBNull(item.OwnerTableView.DataKeyValues(item.ItemIndex)("LastWorkflowAction")), " ", item.OwnerTableView.DataKeyValues(item.ItemIndex)("LastWorkflowAction"))
 
            Dim nAttachments As Integer = item.OwnerTableView.DataKeyValues(item.ItemIndex)("Attachments")
            Dim nPreviousWorkflowRoleID As Integer = IIf(IsDBNull(item.OwnerTableView.DataKeyValues(item.ItemIndex)("PreviousWorkflowRoleID")), 0, item.OwnerTableView.DataKeyValues(item.ItemIndex)("PreviousWorkflowRoleID"))
            Dim sCurrOwner As String = item.OwnerTableView.DataKeyValues(item.ItemIndex)("CurrentWorkflowOwner")
            
            Dim sContractType As String = item.OwnerTableView.DataKeyValues(item.ItemIndex)("ContractType")

            'update the link button to open attachments/notes window
            Dim linkButton As HyperLink = CType(item("ShowAttachments").Controls(0), HyperLink)
            linkButton.Attributes("onclick") = "return ShowAttachments('" & nTranID & "');"
            linkButton.ToolTip = "Shows any attachments linked to this Transaction."
            linkButton.ImageUrl = "images/paper_clip_small.gif"
            linkButton.NavigateUrl = "#"
            If nAttachments > 0 Then
                linkButton.Visible = True
            Else
                linkButton.Visible = False
            End If

            'update the link button to open reject transactions
            Dim linkButton1a As HyperLink = CType(item("ApproveTransaction").Controls(0), HyperLink)
 
            linkButton1a.Attributes("onclick") = "return ShowWorkflowApproval('" & nTranID & "');"
            linkButton1a.ToolTip = "Approve or Reject this transaction."
            linkButton1a.ImageUrl = "images/workflow_send.png"
            linkButton1a.NavigateUrl = "#"
            
            ''update the link button to reroute transaction
            Dim linkButton3a As ImageButton = CType(item("ReRouteTransaction").Controls(0), ImageButton)
            linkButton3a.CommandArgument = nTranID
            linkButton3a.ToolTip = "ReRoute this Transaction back to you."
            linkButton3a.ImageUrl = "images/route_undo.png"
            
            If Session("WorkflowRoleID") = nPreviousWorkflowRoleID And sCurrOwner <> "District For Payment" Then   'this user was last to act so can reroute back
                linkButton3a.Visible = True
            Else
                linkButton3a.Visible = False
            End If
            
            If sStatus = "Paid" Then   'no more workflow routing to do
                linkButton3a.Visible = False
            End If
            
            'update the link button to view history
            Dim linkButton2 As HyperLink = CType(item("WorkflowHistory").Controls(0), HyperLink)
            linkButton2.Attributes("onclick") = "return ShowWorkflowHistory('" & nTranID & "');"
  
            'follwing allows hover open - kind of slow so disabled for now
            'linkButton2.Attributes("onclick") = "HandleClick()"
            'linkButton2.Attributes("onmouseover") = "OpenWindowWithParam('popupWindow', '" & nTranID & "', this)"
            'linkButton2.Attributes("onmouseout") = "CloseWindow('popupWindow')"
            
            linkButton2.ToolTip = "View Workflow History."
            linkButton2.ImageUrl = "images/workflow_history.png"
            linkButton2.NavigateUrl = "#"
            
          
            

            'set the background color based on status
            If InStr(sLastWorkflowAction, "Rejected") Then    'if the item was rejected back to the user show color
                item.ForeColor = Color.Red
                ' item.Font.Bold = True
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

        End If
    End Sub
    
    Private Sub RadGrid1_ItemDataBound(ByVal sender As Object, ByVal e As Telerik.Web.UI.GridItemEventArgs) Handles RadGrid1.ItemDataBound
        If (TypeOf e.Item Is GridDataItem) Then
            Dim item As GridDataItem = CType(e.Item, GridDataItem)
            'Clear any checked item on postback
            Dim chk1 As CheckBox = CType(item("Select").Controls(0), CheckBox)
            chk1.Checked = False
        End If
        
    End Sub
  
    
    Protected Sub lstCurrentView_SelectedIndexChanged(ByVal o As Object, ByVal e As Telerik.Web.UI.RadComboBoxSelectedIndexChangedEventArgs)
        CurrentView = lstCurrentView.SelectedValue
        SetCurrentView()
        RadGrid1.Rebind()
    End Sub

 
    
    Protected Sub RadMenu1_ItemClick(ByVal sender As Object, ByVal e As Telerik.Web.UI.RadMenuEventArgs)
       
        Dim btn As RadMenuItem = e.Item
        
        Select Case btn.Value
            
            Case "Transfer To District"
                Using db As New promptWorkflowTransfer
                    db.ExportBannerTransactions()
                End Using
                
                RadGrid1.Rebind()
            
            Case "ExportExcel"
                RadGrid1.MasterTableView.ExportToExcel()
  
        End Select
    End Sub

  
</script>

<asp:Content ID="Content1" ContentPlaceHolderID="mainBody" runat="Server">
    <telerik:RadWindowManager ID="InboxPopups" runat="server" />

    <div style="padding: 5px;">
        <telerik:RadMenu ID="RadMenu1" runat="server" OnItemClick="RadMenu1_ItemClick" Style="z-index: 10;">
            <Items>
                <telerik:RadMenuItem runat="server" Value="DDBOX" Text=" ">
                    <ItemTemplate>
                        <telerik:RadComboBox ID="lstCurrentViewTemplate" runat="server" OnSelectedIndexChanged="lstCurrentView_SelectedIndexChanged"
                            AutoPostBack="True" NoWrap="True" ToolTip="Select View you wish to see." Width="190px"
                            MaxHeight="250px">
                        </telerik:RadComboBox>
                    </ItemTemplate>
                </telerik:RadMenuItem>
            </Items>
        </telerik:RadMenu>
        <telerik:RadGrid ID="RadGrid1" runat="server" AllowSorting="True" AutoGenerateColumns="False"
            OnItemCommand="RadGrid1_ItemCommand" GridLines="None" Width="100%" EnableAJAX="True"
            Skin="Office2007" Height="60%" AllowMultiRowSelection="True">
            <ClientSettings>
                <Scrolling AllowScroll="True" UseStaticHeaders="True" ScrollHeight="50%" />
                <Selecting AllowRowSelect="true" />
            </ClientSettings>
            <MasterTableView Width="100%" GridLines="None" DataKeyNames="ContractID,TransactionID,PreviousWorkflowRoleID,CurrentWorkflowOwner,Attachments,Status,LastWorkflowAction,ContractType"
                NoMasterRecordsText="No Transactions Found." ShowHeadersWhenNoRecords="False"  ClientDataKeyNames="TransactionID">
                <Columns>

                 <telerik:GridClientSelectColumn UniqueName="Select">
                        <ItemStyle Width="28px" HorizontalAlign="Center" VerticalAlign="Top" />
                        <HeaderStyle Width="28px" HorizontalAlign="Center" />
                    </telerik:GridClientSelectColumn>
                    <telerik:GridHyperLinkColumn HeaderText="Aprv" UniqueName="ApproveTransaction">
                        <ItemStyle Width="35px" HorizontalAlign="Center" />
                        <HeaderStyle Width="35px" HorizontalAlign="Center" />
                    </telerik:GridHyperLinkColumn>
                    <telerik:GridButtonColumn ButtonType="ImageButton" Visible="True" CommandName="ReRouteTransaction"
                        HeaderText="" UniqueName="ReRouteTransaction" Reorderable="False" ShowSortIcon="False">
                        <ItemStyle Width="35px" HorizontalAlign="Center" VerticalAlign="Top" />
                        <HeaderStyle Width="35px" HorizontalAlign="Center" />
                    </telerik:GridButtonColumn>
                    <telerik:GridHyperLinkColumn HeaderText="Att" UniqueName="ShowAttachments">
                        <ItemStyle Width="35px" HorizontalAlign="Center" />
                        <HeaderStyle Width="35px" HorizontalAlign="Center" />
                    </telerik:GridHyperLinkColumn>
                    <telerik:GridHyperLinkColumn HeaderText="Hist" UniqueName="WorkflowHistory">
                        <ItemStyle Width="35px" HorizontalAlign="Center" />
                        <HeaderStyle Width="35px" HorizontalAlign="Center" />
                    </telerik:GridHyperLinkColumn>
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
                        <ItemStyle Width="20px" HorizontalAlign="Center" VerticalAlign="Top" />
                        <HeaderStyle Width="20px" Height="20px" HorizontalAlign="Center" />
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
                    <telerik:GridBoundColumn DataField="RetentionAccountNumber" HeaderText="RetAcct#"
                        UniqueName="RetentionAccountNumber">
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
                    <telerik:GridBoundColumn DataField="CurrentWorkflowOwner" HeaderText="Current Owner"
                        UniqueName="CurrentWorkflowOwner">
                        <ItemStyle Width="10%" HorizontalAlign="Right" VerticalAlign="Top" />
                        <HeaderStyle Width="10%" HorizontalAlign="Right" />
                    </telerik:GridBoundColumn>
                    <telerik:GridBoundColumn DataField="Status" HeaderText="Status" UniqueName="Status">
                        <ItemStyle Width="75px" HorizontalAlign="Center" VerticalAlign="Top" />
                        <HeaderStyle Width="75px" HorizontalAlign="Center" />
                    </telerik:GridBoundColumn>
                    <telerik:GridBoundColumn DataField="CheckNumber" HeaderText="Chk#" UniqueName="CheckNumber">
                        <ItemStyle Width="75px" HorizontalAlign="Center" VerticalAlign="Top" />
                        <HeaderStyle Width="75px" HorizontalAlign="Center" />
                    </telerik:GridBoundColumn>
                    <telerik:GridBoundColumn DataField="DatePaid" HeaderText="PaidOn" UniqueName="DatePaid"
                        DataFormatString="{0:MM/dd/yy}">
                        <ItemStyle Width="75px" HorizontalAlign="Center" VerticalAlign="Top" />
                        <HeaderStyle Width="75px" HorizontalAlign="Center" />
                    </telerik:GridBoundColumn>
                </Columns>
            </MasterTableView>
            <ExportSettings FileName="PromptDashboardExport" OpenInNewWindow="True">
            </ExportSettings>
        </telerik:RadGrid>
        <telerik:RadAjaxManager ID="RadAjaxManager1" runat="server">
            <AjaxSettings>
                <telerik:AjaxSetting AjaxControlID="RadGrid1">
                    <UpdatedControls>
                        <telerik:AjaxUpdatedControl ControlID="RadGrid1" LoadingPanelID="RadAjaxLoadingPanel1" />
                    </UpdatedControls>
                </telerik:AjaxSetting>
                
                <telerik:AjaxSetting AjaxControlID="RadMenu1">
                    <UpdatedControls>
                        <telerik:AjaxUpdatedControl ControlID="RadGrid1" LoadingPanelID="RadAjaxLoadingPanel1" />
                         <telerik:AjaxUpdatedControl ControlID="RadMenu1"  />
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
        </telerik:RadAjaxLoadingPanel>
    </div>
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

            // to allow popup to call refresh in this form after edit
            function refreshGrid() {
                RadGridNamespace.AsyncRequest('<%= RadGrid1.UniqueID %>', 'Rebind', '<%= RadGrid1.ClientID %>');

            }

            function ShowAttachments(id)     //for attachments info display
            {

                var oManager = $find("<%=InboxPopups.ClientID%>");
                var oWnd = oManager.open('dashboard_view_attachments.aspx?TransactionID=' + id, 'ShowAttachmentsWindow');
                return false;

            }

            function ShowWorkflowApproval(id)     //for workflow approval display
            {
                var oManager = $find("<%=InboxPopups.ClientID%>");
                var oWnd = oManager.open("workflow_route.aspx?rectype=Transaction&recid=" + id + "&CalledFrom=Dashboard", "WorkflowApproval");
                return false;
            }


                function ShowMultiWorkflowApproval()     //for workflow Multiple approval display
                {
                    //alert('here');
                    var grid = $find("<%=RadGrid1.ClientID %>");
                    var MasterTable = grid.get_masterTableView();
                    var slist = '';
                    var selectedRows = MasterTable.get_selectedItems();    // get all the selected rows and extract datakeys for transactionid
                    for (var i = 0; i < selectedRows.length; i++) {
                        var row = selectedRows[i];
                        var nTranID = row.getDataKeyValue('TransactionID');
                        slist +=  nTranID + ',';

                    }
                    if(slist == '') {
                        alert("There are no items selected for approval.")
                        return false;
                        }
                    else {
                    
                        var oWnd = window.radopen("workflow_route_multiple.aspx?TransactionList=" + slist + "&CalledFrom=Dashboard", "WorkflowApproval");
                        return false;
                    }

 
                }

            function ShowWorkflowHistory(id)     //for workflow history display
            {


                var oManager = $find("<%=InboxPopups.ClientID%>");
                var oWnd = oManager.open('workflow_history_view.aspx?rectype=Transaction&recid=' + id, 'WorkflowHistory');
                return false;


            }

        </script>

    </telerik:RadCodeBlock>
</asp:Content>
