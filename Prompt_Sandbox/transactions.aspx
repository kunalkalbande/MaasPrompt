<%@ Page Language="VB" MasterPageFile="~/content.master" Title="" %>

<%@ Register Assembly="Telerik.Web.UI" Namespace="Telerik.Web.UI" TagPrefix="telerik" %>
<%@ Import Namespace="Prompt" %>

<script runat="server">
    
    Private ContractorID As Integer = 0
    Private ProjectID As Integer = 0
    Private bEnableWorkflow As Boolean = False
    Private nTotalTotal As Double = 0
    Private nTotalPayable As Double = 0
    Private nTotalRetention As Double = 0
    Private nProjectID As Integer = 0
    Private nContractID As Integer = 0
    Private nCollegeID As Integer = 0
    
    Private bReadOnly As Boolean = True
    Private bValidContract As Boolean = True
    Private sErrorText As String = ""
        
   
    Protected Sub Page_PreRender(ByVal sender As Object, ByVal e As System.EventArgs)
        'Using db As New promptUserPrefs
        '    db.SaveGridSettings(RadGrid1, "TransactionGridSettings", "ContractID", nContractID) ''NOTE: Removed as was causing rendeing problems 
        'End Using
 
    End Sub

    Protected Sub Page_Init(ByVal sender As Object, ByVal e As System.EventArgs)
        nProjectID = Request.QueryString("ProjectID")
        nContractID = Request.QueryString("ContractID")
        nCollegeID = Request.QueryString("CollegeID")
        Session("CollegeID") = nCollegeID   'to fix missing add button problem
        
        'set security
        Using dbsec As New EISSecurity
            dbsec.ProjectID = nProjectID
            If dbsec.FindUserPermission("Transactions", "write") Then
                bReadOnly = False
            Else
                bReadOnly = True
            End If
        End Using
        'If Not IsPostBack Then       ''NOTE: Removed as was causing rendeing problems 
        '    Using db As New promptUserPrefs
        '        db.LoadGridSettings(RadGrid1, "TransactionGridSettings", "ContractID", nContractID)
        '        db.LoadGridColumnVisibility(RadGrid1, "TransactionGridColumns", "ContractID", nContractID)
        '    End Using
        'End If

    End Sub
   
   
    Private Sub Page_Load(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MyBase.Load

        Session("PageID") = "TransactionView"
        nProjectID = Request.QueryString("ProjectID")
        nContractID = Request.QueryString("ContractID")
         
        Dim masterViewTitle As Label = Master.FindControl("lblViewTitle")
        'Set Grid Properties
        With RadGrid1
            .EnableEmbeddedSkins = False
            .Skin = "Prompt"
            .GroupingEnabled = False
            .AllowSorting = True
                        
            .ClientSettings.AllowColumnsReorder = True
            .ClientSettings.ColumnsReorderMethod = GridClientSettings.GridColumnsReorderMethod.Reorder
            .ClientSettings.Scrolling.AllowScroll = True
            .ClientSettings.Scrolling.ScrollHeight = Unit.Percentage(50)
            .ClientSettings.Scrolling.UseStaticHeaders = True
            .ClientSettings.Resizing.AllowColumnResize = True

            .MasterTableView.EnableHeaderContextMenu = True
            .MasterTableView.TableLayout = GridTableLayout.Fixed
            .MasterTableView.AllowMultiColumnSorting = False

            'If Request.Browser.Browser = "IE" Then
            RadGrid1.Height = Unit.Pixel(500)
            'Else
            '.Height = Unit.Percentage(88)
            'End If
            
            .ExportSettings.FileName = "PromptTransactionsExport"
            .ExportSettings.OpenInNewWindow = True
            'must replace ampersand so Radgrid's ExportToPDF doesn't blow up when contractor name contains '&', for example 'AT&T' (needs valid XHTML, and ampersand doesn't cut it)
            .ExportSettings.Pdf.PageTitle = masterViewTitle.Text.Replace("&", "&#38;") & " Transactions"

        End With
        
        Dim masterTabs As RadTabStrip = Master.FindControl("tabMain")
        Session("CurrentTab") = "Transactions"
        For Each radTab In masterTabs.GetAllTabs
            If radTab.Value = "Transactions" Then
                radTab.Selected = True
                radTab.SelectParents()
                Exit For
            End If
        Next
        
        'check for valid object code in contract - this text will be used for popup on edit buttons if not valid

        Using objContract As New promptContract
            objContract.LoadContractInfo(nContractID)
           
        End Using
        
        
        'Set up Windows
        With contentPopups
            .Skin = "Windows7"
            .VisibleOnPageLoad = False
            Dim ww As New RadWindow
            With ww
                .ID = "ShowTransactionWorkflowHistory"
                .NavigateUrl = ""
                .Title = ""
                .Width = 500
                .Height = 350
                .Top = 200
                .Left = 200
                
                .Modal = False
                .VisibleStatusbar = True
                .ReloadOnShow = True
                .Behaviors = WindowBehaviors.Close + WindowBehaviors.Resize
            End With

            .Windows.Add(ww)
                                      
                            
            ww = New RadWindow
            With ww
                .ID = "ShowTransactionAttachments"
                .NavigateUrl = ""
                .Title = ""
                .Width = 450
                .Height = 350
                .Top = 200
                .Left = 200
                .Modal = False
                .VisibleStatusbar = True
                .ReloadOnShow = True
                .Behaviors = WindowBehaviors.Close + WindowBehaviors.Resize
            End With

            .Windows.Add(ww)
                         
        End With
        
        BuildMenu()
        
        
        If Session("RtnFromEdit") = True Then
            RadGrid1.Rebind()
            Session("RtnFromEdit") = False
        End If

    End Sub
    
      
    Protected Sub RadGrid1_NeedDataSource(ByVal source As Object, ByVal e As Telerik.Web.UI.GridNeedDataSourceEventArgs) Handles RadGrid1.NeedDataSource
        'loads the grid whenever it needs data (sorting, rebinding, etc...)
        Using db As New promptTransaction
            db.CallingPage = Page
            RadGrid1.DataSource = db.GetTransactions(nContractID)
        End Using

    End Sub
    
    Protected Sub RadGrid1_ItemCreated(ByVal sender As Object, ByVal e As Telerik.Web.UI.GridItemEventArgs) Handles RadGrid1.ItemCreated
        'This event allows us to customize the cell contents - fired before databound
        
        If (TypeOf e.Item Is GridDataItem) Then
            Dim item As GridDataItem = CType(e.Item, GridDataItem)
            Dim nTransactionID As Integer = item.OwnerTableView.DataKeyValues(item.ItemIndex)("TransactionID")
            Dim nProjectID As Integer = item.OwnerTableView.DataKeyValues(item.ItemIndex)("ProjectID")
            Dim nContractID As Integer = item.OwnerTableView.DataKeyValues(item.ItemIndex)("ContractID")
            Dim nAttachments As Integer = item.OwnerTableView.DataKeyValues(item.ItemIndex)("Attachments")
            Dim sTransType As String = item.OwnerTableView.DataKeyValues(item.ItemIndex)("TransType")
                        
            'update the link button to open attachments/notes window
            Dim lnk As HyperLink = CType(item("InvoiceDate").Controls(0), HyperLink)
            If IsDBNull(lnk.Text) Then
                lnk.Text = "--none--"
            End If
            
            If sTransType = "RetInvoice" Then
                lnk.Attributes.Add("onclick", "openPopup('retention_edit.aspx?ID=" & nTransactionID & "&ProjectID=" & nProjectID & "&ContractID=" & nContractID & "','editRet',650,500,'yes');")
            Else
                lnk.Attributes.Add("onclick", "openPopup('transaction_edit.aspx?ID=" & nTransactionID & "&ProjectID=" & nProjectID & "&ContractID=" & nContractID & "','editTrans',650,700,'yes');")
            End If
            lnk.ToolTip = "Edit this Transaction."
            lnk.NavigateUrl = "#"
            
            'Check for flag and if so need to insert
            Using db As New promptFlag
                db.ParentRecID = nTransactionID
                db.ParentRecType = "Transaction"
                If db.FlagExists Then
                    Dim ctrlFlag As New HyperLink
                    With ctrlFlag
                        .ImageUrl = "images/alert.gif"
                        .NavigateUrl = "#"
                        .Attributes.Add("onclick", "openPopup('flag_edit.aspx?ParentRecID=" & nTransactionID & "&ParentRecType=Transaction','pophelp',500,250,'yes');")
                    End With
                    item("InvoiceDate").Controls.Add(ctrlFlag)
                End If
            End Using
            
            If nAttachments > 0 Then
                Dim lnkAttachments As HyperLink = CType(item("Attachments").Controls(0), HyperLink)
                lnkAttachments.Attributes("onclick") = "return ShowAttachments(" & nTransactionID & ");"
                lnkAttachments.ImageUrl = "images/tab_attachments.png"
                lnkAttachments.NavigateUrl = "#"
                lnkAttachments.ToolTip = "See attachments associated with this Transaction."
            End If
               
            If bEnableWorkflow Then
                Dim lnkWorkflowHistory As HyperLink = CType(item("Wkfl").Controls(0), HyperLink)
                lnkWorkflowHistory.Attributes("onclick") = "return ShowWorkflowHistory(" & nTransactionID & ");"
                lnkWorkflowHistory.ImageUrl = "images/workflow_history_small.png"
                lnkWorkflowHistory.NavigateUrl = "#"
                lnkWorkflowHistory.ToolTip = "Click here to see Workflow History for this Transaction."
            End If
  
               
        End If
    End Sub
    
    Private Sub RadGrid1_ItemDataBound(ByVal sender As Object, ByVal e As Telerik.Web.UI.GridItemEventArgs) Handles RadGrid1.ItemDataBound
        If (TypeOf e.Item Is GridDataItem) Then
            Dim dataItem As GridDataItem = CType(e.Item, GridDataItem)
            Dim sAccrual As String = dataItem.OwnerTableView.DataKeyValues(dataItem.ItemIndex)("Accrual")
            Dim nTotalAmount As Double = dataItem.OwnerTableView.DataKeyValues(dataItem.ItemIndex)("TotalAmount")
            Dim nPayableAmount As Double = dataItem.OwnerTableView.DataKeyValues(dataItem.ItemIndex)("PayableAmount")
            Dim nRetentionAmount As Double = dataItem.OwnerTableView.DataKeyValues(dataItem.ItemIndex)("RetentionAmount")
            Dim sTransType As String = dataItem.OwnerTableView.DataKeyValues(dataItem.ItemIndex)("TransType")
            Dim dInvoiceDate As String = ProcLib.CheckNullDBField(dataItem.OwnerTableView.DataKeyValues(dataItem.ItemIndex)("InvoiceDate"))
            
            Dim nDetReimb As Integer = ProcLib.CheckNullNumField(dataItem.OwnerTableView.DataKeyValues(dataItem.ItemIndex)("DetailReimbursables"))
            
            'Format the amounts in the appropriate colums and accumulate totals
            dataItem("DetailReimbursables").ToolTip = "Shows R if any allocations of this transaction are Reimbursables as defined in Contract Line Item."
            If nDetReimb > 0 Then
                dataItem("DetailReimbursables").Text = "R"
            Else
                dataItem("DetailReimbursables").Text = ""
            End If
            
            If sAccrual = "1" Then
                dataItem.CssClass = "bgyellow"
                'dataItem("Description").BackColor = Color.Yellow
            End If
            
            If dInvoiceDate = " " Then
                Dim lnk As HyperLink = CType(dataItem("InvoiceDate").Controls(0), HyperLink)
                lnk.Text = "--none--"
            End If
            
            If nPayableAmount = 0 Then
                dataItem("PayableAmount").Text = ""
            End If
            If nRetentionAmount = 0 Then
                dataItem("RetentionAmount").Text = ""
            Else
                Dim nNewRet As Double = nRetentionAmount * -1
                dataItem("RetentionAmount").Text = FormatCurrency(nNewRet, 2)
            End If
            If nTotalAmount = 0 Then
                dataItem("TotalAmount").Text = ""
            End If
            
            nTotalTotal = nTotalTotal + nTotalAmount
            nTotalPayable = nTotalPayable + nPayableAmount
            'If sTransType = "RetInvoice" Then
            '    nTotalRetention = nTotalRetention - nPayableAmount
            'Else
            nTotalRetention = nTotalRetention + nRetentionAmount
            'End If
            
 
        End If
        If (TypeOf e.Item Is GridFooterItem) Then
            Dim footerItem As GridFooterItem = CType(e.Item, GridFooterItem)
            footerItem("TotalAmount").Text = FormatCurrency(nTotalTotal)
            footerItem("PayableAmount").Text = FormatCurrency(nTotalPayable)
            footerItem("RetentionAmount").Text = FormatCurrency(nTotalRetention)
            footerItem("Description").Text = "Total Transactions: "
            
            footerItem.Font.Bold = True


        End If
        
    End Sub
    
    Protected Sub butExportToPDF_Click(ByVal sender As Object, ByVal e As System.EventArgs)
        'Hide uneeded columns and remove links because it breaks the export 
        RadGrid1.MasterTableView.Columns.FindByUniqueName("Attachments").Visible = False
        RadGrid1.MasterTableView.Columns.FindByUniqueName("Wkfl").Visible = False
        For Each item As GridItem In RadGrid1.MasterTableView.Items
            If TypeOf item Is GridDataItem Then
                Dim dataItem As GridDataItem = CType(item, GridDataItem)
                Dim lnk As HyperLink = CType(dataItem("InvoiceDate").Controls(0), HyperLink)
                lnk.NavigateUrl = ""
            End If
        Next

        RadGrid1.MasterTableView.ExportToPdf()
    End Sub

    Protected Sub butExportToExcel_Click(ByVal sender As Object, ByVal e As System.EventArgs)
        RadGrid1.MasterTableView.Columns.FindByUniqueName("Attachments").Visible = False
        RadGrid1.MasterTableView.Columns.FindByUniqueName("Wkfl").Visible = False
        For Each item As GridItem In RadGrid1.MasterTableView.Items
            If TypeOf item Is GridDataItem Then
                Dim dataItem As GridDataItem = CType(item, GridDataItem)
                Dim lnk As HyperLink = CType(dataItem("InvoiceDate").Controls(0), HyperLink)
                lnk.NavigateUrl = ""
            End If
        Next
        RadGrid1.MasterTableView.ExportToExcel()
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
            Dim but As RadMenuItem
                
            but = New RadMenuItem
            With but
                .Text = "Add New"
                .ImageUrl = "images/add.png"
                If bValidContract Then
                    .Attributes.Add("onclick", "openPopup('transaction_edit.aspx?new=Inv&ContractID=" & nContractID & "','editTrans',700,750,'yes');")
                Else
                    .Attributes("onclick") = "return ShowRADMessage('" & sErrorText & "',400,100,'Contract Data Incomplete');"
                End If
                .ToolTip = "Add a New Transaction."
                .PostBack = False
                If bReadOnly Then
                    .Visible = False
                Else
                    .Visible = True
                End If
            End With
            RadMenu1.Items.Add(but)
            
            but = New RadMenuItem
            With but
                .Text = "Add Retention"
                .ImageUrl = "images/add.png"
                If bValidContract Then
                    .Attributes.Add("onclick", "openPopup('retention_edit.aspx?new=Ret&ProjectID=" & ProjectID & "&ContractID=" & nContractID & "','editRet',750,500,'yes');")
                Else
                    .Attributes("onclick") = "return ShowRADMessage('" & sErrorText & "',400,100,'Contract Data Incomplete');"
                End If
                .ToolTip = "Add a New Retention Transaction."
                .PostBack = False
                If bReadOnly Then
                    .Visible = False
                Else
                    .Visible = True
                End If
            End With
            RadMenu1.Items.Add(but)
            
            
            but = New RadMenuItem
            With but
                .Text = "Associate with Attachments"
                .ImageUrl = "images/tab_attachments.png"
                .Attributes.Add("onclick", "openPopup('attachment_associate_linked.aspx?ParentRecID=" & nContractID & "&ParentRecordType=Contract','assoc',750,500,'yes');")
                .ToolTip = "Associate with Attachments."
                .PostBack = False
                If bReadOnly Then
                    .Visible = False
                Else
                    .Visible = True
                End If
            End With
            RadMenu1.Items.Add(but)
			
            but = New RadMenuItem
            but.IsSeparator = True
            RadMenu1.Items.Add(but)

            Dim butDropDown As New RadMenuItem
            With butDropDown
                .Text = "Export"
                .ImageUrl = "images/data_down.png"
                .PostBack = False
            End With
            
            'Add sub items
            Dim butSub As New RadMenuItem
            With butSub
                .Text = "Export To Excel"
                .Value = "ExportExcel"
                .Attributes("CancelAjax") = "Y"   'NOTE: This is needed to cancel ajax call and do regular postback as grid export to pdf/execl does not work with ajax
                .ImageUrl = "images/excel.gif"
                .PostBack = True
            End With
            butDropDown.Items.Add(butSub)
            
            butSub = New RadMenuItem
            With butSub
                .Text = "Export To PDF"
                .Value = "ExportPDF"
                .Attributes("CancelAjax") = "Y"   'NOTE: This is needed to cancel ajax call and do regular postback as grid export to pdf/execl does not work with ajax
                .ImageUrl = "images/prompt_pdf.gif"
                .PostBack = True
            End With
            butDropDown.Items.Add(butSub)
            RadMenu1.Items.Add(butDropDown)
 
            'butDropDown = New RadMenuItem
            'With butDropDown
            '    .Text = "Print"
            '    .ImageUrl = "images/printer.png"
            '    .PostBack = False
            'End With
 
            'butSub = New RadMenuItem
            'With butSub
            '    .Text = "Print RFI Log"
            '    .ImageUrl = "images/printer.png"
            '    .Target = "_new"
            '    .NavigateUrl = "http://216.129.104.66/Q34JF8SFA/Pages/ReportViewer.aspx?%2fPromptReports%2fRFI_log&Dist=56&Proj=" & nProjectID
            '    .PostBack = False
            'End With
            'butDropDown.Items.Add(butSub)
            
            'RadMenu1.Items.Add(butDropDown)

  
            
            'Add grid configurator       
            Dim butConfig As New RadMenuItem
            With butConfig
                .Text = "Preferences"
                .ImageUrl = "images/gear.png"
                .PostBack = False
            End With
            RadMenu1.Items.Add(butConfig)
            
            'Add sub items
            Dim butConfigSub As New RadMenuItem
            With butConfigSub
                .Text = "Visible Columns"
                .ImageUrl = "images/column_preferences.png"
                .PostBack = False
            End With
            
            'Load the avaialble columns as checkbox items
            For Each col As GridColumn In RadGrid1.Columns
                If col.HeaderText <> "" Then
                    Dim butCol As New RadMenuItem
                    With butCol
                        .Text = col.HeaderText
                        .Value = "ColumnVisibility"
                        If col.Visible = True Then
                            .ImageUrl = "images/check2.png"
                            .Attributes("Visibility") = "On"
                        Else
                            .ImageUrl = ""
                            .Attributes("Visibility") = "Off"
                        End If
                        
                        .Attributes("ID") = col.UniqueName
                    End With
                    butConfigSub.Items.Add(butCol)
                End If
 
            Next
            butConfig.Items.Add(butConfigSub)
            
            'Add sub items
            butConfigSub = New RadMenuItem
            With butConfigSub
                .Text = "Restore Default Settings"
                .Value = "RestoreDefaultSettings"
                .ImageUrl = "images/gear_refresh.png"
            End With
            butConfig.Items.Add(butConfigSub)
        End If

    End Sub
    Protected Sub RadMenu1_ItemClick(ByVal sender As Object, ByVal e As Telerik.Web.UI.RadMenuEventArgs)
       
        Dim btn As RadMenuItem = e.Item
        
        Select Case btn.Value
            
            Case "ExportExcel"
                RadGrid1.Columns.FindByUniqueName("Attachments").Visible = False
                RadGrid1.MasterTableView.Columns.FindByUniqueName("Wkfl").Visible = False
                RadGrid1.MasterTableView.ExportToExcel()
                
            Case "ExportPDF"
                RadGrid1.Columns.FindByUniqueName("Attachments").Visible = False
                RadGrid1.MasterTableView.Columns.FindByUniqueName("Wkfl").Visible = False
                For Each item As GridItem In RadGrid1.MasterTableView.Items
                    If TypeOf item Is GridDataItem Then
                        Dim dataItem As GridDataItem = CType(item, GridDataItem)
                        Dim lnk As HyperLink = CType(dataItem("InvoiceDate").Controls(0), HyperLink)
                        lnk.NavigateUrl = ""
                    End If
                Next
                RadGrid1.MasterTableView.ExportToPdf()
            
                   
            Case "ColumnVisibility"
                If btn.Attributes("Visibility") = "Off" Then
                    btn.ImageUrl = "images/check2.png"
                    btn.Attributes("Visibility") = "On"
                    RadGrid1.Columns.FindByUniqueName(btn.Attributes("ID")).Visible = True
                Else
                    btn.ImageUrl = ""
                    btn.Attributes("Visibility") = "Off"
                    RadGrid1.Columns.FindByUniqueName(btn.Attributes("ID")).Visible = False
                End If
                Using db As New promptUserPrefs
                    db.SaveGridColumnVisibility("TransactionGridColumns", btn.Attributes("ID"), btn.Attributes("Visibility"), "ContractID", nContractID)
                End Using
                RadGrid1.Rebind()
                
            Case "RestoreDefaultSettings"
                
                Using db As New promptUserPrefs
                    db.RemoveUserSavedSettings("TransactionGridSettings", "ContractID", nContractID)
                    db.RemoveUserSavedSettings("TransactionGridColumns", "ContractID", nContractID)
                End Using
                Response.Redirect(Page.Request.RawUrl)

        End Select
    End Sub


</script>

<asp:Content ID="Content1" ContentPlaceHolderID="mainBody" runat="Server">
    <telerik:RadWindowManager ID="contentPopups" runat="server" />
    <telerik:RadMenu ID="RadMenu1" runat="server" OnItemClick="RadMenu1_ItemClick" Style="z-index: 10;margin-bottom:-6px;" />
    <div id="contentcolumn">
        <telerik:RadGrid ID="RadGrid1" runat="server" AllowSorting="true" AutoGenerateColumns="False"
            GridLines="None" Width="100%" Height="600px" EnableAJAX="True" Skin="" EnableEmbeddedSkins="false"
            GroupingEnabled="False">
            <ClientSettings AllowColumnsReorder="true" ColumnsReorderMethod="Reorder">
                <Scrolling AllowScroll="True" ScrollHeight="50%" UseStaticHeaders="True" />
                <Resizing AllowColumnResize="True" />
            </ClientSettings>
            <MasterTableView Width="100%" GridLines="None" NoMasterRecordsText="No Transactions Found."
                EnableHeaderContextMenu="true" TableLayout="Fixed" AllowMultiColumnSorting="false"
                ShowHeadersWhenNoRecords="True" DataKeyNames="InvoiceDate,ProjectID,ContractID,TransactionID,TransType,DetailReimbursables,Attachments,Accrual,TotalAmount,PayableAmount,RetentionAmount"
                ShowFooter="true" FooterStyle-Height="30px">
                <Columns>
                    <telerik:GridHyperLinkColumn DataTextField="InvoiceDate" HeaderText="Invoice Date"
                        UniqueName="InvoiceDate" DataTextFormatString="{0:MM/dd/yyyy}" SortExpression="InvoiceDate">
                        <ItemStyle Width="70px" HorizontalAlign="Left" VerticalAlign="Top" />
                        <HeaderStyle Width="70px" Height="20px" HorizontalAlign="Left" />
                    </telerik:GridHyperLinkColumn>
                    <telerik:GridBoundColumn DataField="TransType" UniqueName="TransType" HeaderText="Type">
                        <ItemStyle HorizontalAlign="Left" Width="60px" VerticalAlign="Top" />
                        <HeaderStyle HorizontalAlign="Left" Width="60px" Height="15px" />
                    </telerik:GridBoundColumn>
                    <telerik:GridBoundColumn DataField="Status" UniqueName="Status" HeaderText="Status">
                        <ItemStyle HorizontalAlign="Left" Width="60px" VerticalAlign="Top" />
                        <HeaderStyle HorizontalAlign="Left" Width="60px" Height="15px" />
                    </telerik:GridBoundColumn>
                    <telerik:GridBoundColumn DataField="InvoiceNumber" UniqueName="InvoiceNumber" HeaderText="Invoice#">
                        <ItemStyle HorizontalAlign="Left" Width="90px" VerticalAlign="Top" />
                        <HeaderStyle HorizontalAlign="Left" Width="90px" Height="15px" />
                    </telerik:GridBoundColumn>
                    <telerik:GridBoundColumn DataField="Description" UniqueName="Description" HeaderText="Description">
                        <ItemStyle HorizontalAlign="Left" VerticalAlign="Top" />
                        <HeaderStyle HorizontalAlign="Left" Width="25%" Height="15px" />
                        <FooterStyle HorizontalAlign="Right" Width="25%" Height="15px" />
                    </telerik:GridBoundColumn>
                    <telerik:GridBoundColumn DataField="DetailReimbursables" UniqueName="DetailReimbursables" HeaderText="Reimb">
                        <ItemStyle HorizontalAlign="Left" Width="35px" VerticalAlign="Top" />
                        <HeaderStyle HorizontalAlign="Left" Width="35px" Height="15px" />
                    </telerik:GridBoundColumn>
                    <telerik:GridHyperLinkColumn UniqueName="Attachments" HeaderText="Att">
                        <ItemStyle HorizontalAlign="Left" Width="25px" VerticalAlign="Top" />
                        <HeaderStyle HorizontalAlign="Left" Width="25px" Height="15px" />
                    </telerik:GridHyperLinkColumn>
                    <telerik:GridHyperLinkColumn UniqueName="Wkfl" HeaderText="Wkfl">
                        <ItemStyle HorizontalAlign="Left" Width="35px" VerticalAlign="Top" />
                        <HeaderStyle HorizontalAlign="Left" Width="35px" Height="15px" />
                    </telerik:GridHyperLinkColumn>
                    <telerik:GridBoundColumn DataField="TotalAmount" HeaderText="Total Amount" UniqueName="TotalAmount"
                        DataFormatString="{0:c}">
                        <ItemStyle Width="85px" HorizontalAlign="Right" VerticalAlign="Top" />
                        <HeaderStyle Width="85px" HorizontalAlign="Right" />
                        <FooterStyle HorizontalAlign="Right" Width="85px" Height="15px" />
                    </telerik:GridBoundColumn>
                    <telerik:GridBoundColumn DataField="RetentionAmount" HeaderText="Retention Amount"
                        UniqueName="RetentionAmount" DataFormatString="{0:c}">
                        <ItemStyle Width="90px" HorizontalAlign="Right" VerticalAlign="Top" />
                        <HeaderStyle Width="90px" HorizontalAlign="Right" />
                        <FooterStyle HorizontalAlign="Right" Width="90px" Height="15px" />
                    </telerik:GridBoundColumn>
                    <telerik:GridBoundColumn DataField="PayableAmount" HeaderText="Payable Amount" UniqueName="PayableAmount"
                        DataFormatString="{0:c}">
                        <ItemStyle Width="90px" HorizontalAlign="Right" VerticalAlign="Top" />
                        <HeaderStyle Width="90px" HorizontalAlign="Right" />
                        <FooterStyle HorizontalAlign="Right" Width="90px" Height="15px" />
                    </telerik:GridBoundColumn>
                </Columns>
                <FooterStyle Height="30px"></FooterStyle>
            </MasterTableView>
            <ExportSettings OpenInNewWindow="True">
                <Pdf PageWidth="297mm" PageHeight="210mm" />
            </ExportSettings>
        </telerik:RadGrid>
    </div>
    <telerik:RadAjaxManager ID="RadAjaxManager1" runat="server">
        <ClientEvents OnRequestStart="ajaxRequestStart" OnResponseEnd="ajaxRequestEnd" />
        <AjaxSettings>
            <telerik:AjaxSetting AjaxControlID="RadGrid1">
                <UpdatedControls>
                    <telerik:AjaxUpdatedControl ControlID="RadGrid1" LoadingPanelID="RadAjaxLoadingPanel1" />
                </UpdatedControls>
            </telerik:AjaxSetting>
        </AjaxSettings>
    </telerik:RadAjaxManager>
    <telerik:RadAjaxLoadingPanel ID="RadAjaxLoadingPanel1" runat="server" Height="75px"
        Width="75px" Transparency="25">
        <img alt="Loading..." src='<%= RadAjaxLoadingPanel.GetWebResourceUrl(Page, "Telerik.Web.UI.Skins.Default.Ajax.loading.gif") %>'
            style="border: 0;" />
    </telerik:RadAjaxLoadingPanel>
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

            function ShowWorkflowHistory(id) {
                var oWnd = window.radopen("workflow_history_view.aspx?rectype=Transaction&recid=" + id, "ShowTransactionWorkflowHistory");
                return false;

            }

            function ShowAttachments(id)     //for opening attachments 
            {
                var oWnd = window.radopen("attachments_manage_linked.aspx?ParentRecID=" + id + "&ParentType=Transaction", "ShowTransactionAttachments");
                return false;
            }

  
        </script>
        

    </telerik:RadCodeBlock>

  

</asp:Content>
