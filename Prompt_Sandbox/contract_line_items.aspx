<%@ Page Language="VB" MasterPageFile="~/content.master" Title="" %>

<%@ Register Assembly="Telerik.Web.UI" Namespace="Telerik.Web.UI" TagPrefix="telerik" %>
<%@ Import Namespace="Prompt" %>

<script runat="server">
    
     
    Private nContractID As Integer = 0
    Private nProjectID As Integer = 0
    Private ContractAmount As Double = 0
    Private AmmendAmount As Double = 0
    Private nNewContractTotal As Double = 0
      
    Private bReadOnly As Boolean = True
    Private nTotalContractAmount As Double = 0
    Private nTotalNonReimbAmount As Double = 0
    Private nTotalReimbAmount As Double = 0
    Private nTotalExpended As Double = 0
    Private nTotalChangeOrders As Double = 0
    Private nContractGrandTotal As Double = 0
    
    Private nTotalAdjustments As Double = 0
    
    Private nTotalGridAmount As Double = 0
    
    
    Private nTotalCOPending As Double = 0
    Private nTotalCOApproved As Double = 0
    
    Private nBalRemaining As Double = 0
    
    Private Sub Page_Load(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MyBase.Load

        ''set up help button
        Session("PageID") = "ContractLineItems"
        nProjectID = Request.QueryString("ProjectID")
        nContractID = Request.QueryString("ContractID")
   
        
        Dim masterTabs As RadTabStrip = Master.FindControl("tabMain")
        Session("CurrentTab") = "ContractLineItems"
        For Each radTab In masterTabs.GetAllTabs
            If radTab.Value = "ContractLineItems" Then
                radTab.Selected = True
                radTab.SelectParents()
                Exit For
            End If
        Next
        
        'Set Grid Properties
        With RadGrid1
            .EnableEmbeddedSkins = False
            .Skin = "Prompt"
            .GroupingEnabled = False
            .AllowSorting = True
          
            .Height = Unit.Pixel(450)
           
            .ClientSettings.AllowColumnsReorder = True
            .ClientSettings.ColumnsReorderMethod = GridClientSettings.GridColumnsReorderMethod.Reorder
            .ClientSettings.Scrolling.AllowScroll = True
            .ClientSettings.Scrolling.ScrollHeight = Unit.Percentage(50)
            .ClientSettings.Scrolling.UseStaticHeaders = True
            .ClientSettings.Resizing.AllowColumnResize = True

            .MasterTableView.EnableHeaderContextMenu = True
            .MasterTableView.TableLayout = GridTableLayout.Fixed
            .MasterTableView.AllowMultiColumnSorting = False
            
            .ExportSettings.FileName = "PromptLineItemExport"
            .ExportSettings.OpenInNewWindow = True
        End With
   
        Using db As New EISSecurity
            db.ProjectID = nProjectID
            If db.FindUserPermission("ContractLineItems", "Write") Then
                bReadOnly = False
            Else
                bReadOnly = True
            End If
        End Using

        'get the Contract total amount
        Using db As New promptContract
            db.LoadContractInfo(nContractID)
            ContractAmount = db.ContractTotal
            AmmendAmount = db.AmendTotal
        End Using
        
        BuildMenu()
          
        If Session("RtnFromEdit") = True Then
            RadGrid1.Rebind()
            Session("RtnFromEdit") = False
        End If
        
        With contentPopup
            .Skin = "Windows7"
            .VisibleOnPageLoad = False
            Dim ww As New Telerik.Web.UI.RadWindow
            With ww
                .ID = "ShowHelpWindow"
                '.NavigateUrl = ""
                .Title = ""
                .Width = 450
                .Height = 450
                .Top = 100
                .Left = 20
                .Modal = False
                .VisibleStatusbar = False
                .ReloadOnShow = True
                .Behaviors = WindowBehaviors.Close + WindowBehaviors.Resize
            End With
            .Windows.Add(ww)
            
            ww = New Telerik.Web.UI.RadWindow
            With ww
                .ID = "EditLineItemWindow"
                '.NavigateUrl = ""
                .Title = "Edit Line Item"
                .Width = 620
                .Height = 375
                .Top = 100
                .Left = 4
                .Modal = True
                .VisibleStatusbar = False
                .ReloadOnShow = True
                .Behaviors = WindowBehaviors.Close + WindowBehaviors.Resize
            End With
            .Windows.Add(ww)
            
            ww = New Telerik.Web.UI.RadWindow
            With ww
                .ID = "EditChangeOrderWindow"
                '.NavigateUrl = ""
                .Title = "Edit Line Item"
                .Width = 600
                .Height = 675
                .Top = 100
                .Left = 4
                .Modal = False
                .VisibleStatusbar = False
                .ReloadOnShow = True
                .Behaviors = WindowBehaviors.Close + WindowBehaviors.Resize
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
            Dim but As RadMenuItem
                
            but = New RadMenuItem
            With but
                .Text = "Add Line Item"
                .ImageUrl = "images/add.png"
                If bReadOnly Then
                    .Visible = False
                Else
                    .Visible = True
                    .Attributes("onclick") = "return EditLineItem(0," & nProjectID & "," & nContractID & ");"
                    .ToolTip = "Add a New Contract Line Item."
                    .PostBack = False
                End If
            End With
            RadMenu1.Items.Add(but)
            
            but = New RadMenuItem
            With but
                .Text = "Add Change Order"
                .ImageUrl = "images/add.png"
                If bReadOnly Then
                    .Visible = False
                Else
                    .Visible = True
                    .Attributes("onclick") = "return EditChangeOrder(0," & nProjectID & "," & nContractID & ");"
                    .ToolTip = "Add a New Change Order."
                    .PostBack = False
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
 
               
            '    'Add grid configurator       
            '    Dim butConfig As New RadMenuItem
            '    With butConfig
            '        .Text = "Preferences"
            '        .ImageUrl = "images/gear.png"
            '        .PostBack = False
            '    End With
            '    RadMenu1.Items.Add(butConfig)

            '    'Add sub items
            '    Dim butConfigSub As New RadMenuItem
            '    With butConfigSub
            '        .Text = "Visible Columns"
            '        .ImageUrl = "images/column_preferences.png"
            '        .PostBack = False
            '    End With

            '    'Load the avaialble columns as checkbox items
            '    For Each col As GridColumn In RadGrid1.Columns
            '        If col.HeaderText <> "" Then
            '            Dim butCol As New RadMenuItem
            '            With butCol
            '                .Text = col.HeaderText
            '                .Value = "ColumnVisibility"
            '                If col.Visible = True Then
            '                    .ImageUrl = "images/check2.png"
            '                    .Attributes("Visibility") = "On"
            '                Else
            '                    .ImageUrl = ""
            '                    .Attributes("Visibility") = "Off"
            '                End If

            '                .Attributes("ID") = col.UniqueName
            '            End With
            '            butConfigSub.Items.Add(butCol)
            '        End If

            '    Next
            '    butConfig.Items.Add(butConfigSub)

            '    'Add sub items
            '    butConfigSub = New RadMenuItem
            '    With butConfigSub
            '        .Text = "Restore Default Settings"
            '        .Value = "RestoreDefaultSettings"
            '        .ImageUrl = "images/gear_refresh.png"
            '    End With
            '    butConfig.Items.Add(butConfigSub)
        End If

    End Sub
    Protected Sub RadMenu1_ItemClick(ByVal sender As Object, ByVal e As Telerik.Web.UI.RadMenuEventArgs)
       
        Dim btn As RadMenuItem = e.Item
        
        Select Case btn.Value
            
            Case "ExportExcel"
                'RadGrid1.Columns.FindByUniqueName("Attachments").Visible = False
                'RadGrid1.MasterTableView.Columns.FindByUniqueName("Wkfl").Visible = False
                RadGrid1.MasterTableView.ExportToExcel()
                
            Case "ExportPDF"
                'RadGrid1.Columns.FindByUniqueName("Attachments").Visible = False
                'RadGrid1.MasterTableView.Columns.FindByUniqueName("Wkfl").Visible = False
                For Each item As GridItem In RadGrid1.MasterTableView.Items
                    If TypeOf item Is GridDataItem Then
                        Dim dataItem As GridDataItem = CType(item, GridDataItem)
                        Dim lnk As HyperLink = CType(dataItem("Description").Controls(0), HyperLink)
                        lnk.NavigateUrl = ""
                    End If
                Next
                RadGrid1.MasterTableView.ExportToPdf()
            
                   
                'Case "ColumnVisibility"
                '    If btn.Attributes("Visibility") = "Off" Then
                '        btn.ImageUrl = "images/check2.png"
                '        btn.Attributes("Visibility") = "On"
                '        RadGrid1.Columns.FindByUniqueName(btn.Attributes("ID")).Visible = True
                '    Else
                '        btn.ImageUrl = ""
                '        btn.Attributes("Visibility") = "Off"
                '        RadGrid1.Columns.FindByUniqueName(btn.Attributes("ID")).Visible = False
                '    End If
                '    Using db As New promptUserPrefs
                '        db.SaveGridColumnVisibility("TransactionGridColumns", btn.Attributes("ID"), btn.Attributes("Visibility"), "ContractID", nContractID)
                '    End Using
                '    RadGrid1.Rebind()
                
                'Case "RestoreDefaultSettings"

                '    Using db As New promptUserPrefs
                '        db.RemoveUserSavedSettings("ContractLineItemGridSettings", "ContractID", nContractID)
                '        db.RemoveUserSavedSettings("ContractLineItemGridColumns", "ContractID", nContractID)
                '    End Using
                '    Response.Redirect(Page.Request.RawUrl)

        End Select
    End Sub
   
    Protected Sub RadGrid1_NeedDataSource(ByVal source As Object, ByVal e As Telerik.Web.UI.GridNeedDataSourceEventArgs) Handles RadGrid1.NeedDataSource
        'loads the grid whenever it needs data (sorting, rebinding, etc...)
        Using db As New promptContract
            db.CallingPage = Page
            RadGrid1.DataSource = db.GetContractLineItems(nContractID)
        End Using

    End Sub
    
    Protected Sub RadGrid1_ItemCreated(ByVal sender As Object, ByVal e As Telerik.Web.UI.GridItemEventArgs) Handles RadGrid1.ItemCreated
        'This event allows us to customize the cell contents - fired before databound
          
        If (TypeOf e.Item Is GridDataItem) Then
                                
            Dim item As GridDataItem = CType(e.Item, GridDataItem)
            Dim LineID As Integer = item.OwnerTableView.DataKeyValues(item.ItemIndex)("LineID")
            Dim nContractDetailID As Integer = item.OwnerTableView.DataKeyValues(item.ItemIndex)("ContractChangeOrderID")
            Dim sLineType As String = item.OwnerTableView.DataKeyValues(item.ItemIndex)("LineType")

            'Check for flag and if so need to insert
            Using db As New promptFlag
                db.ParentRecID = nContractDetailID
                db.ParentRecType = "ContractDetail"
                If db.FlagExists Then
                    Dim ctrlFlag As New HyperLink
                    With ctrlFlag
                        .ImageUrl = "images/alert.gif"
                        .NavigateUrl = "#"
                        .Attributes.Add("onclick", "openPopup('flag_edit.aspx?ParentRecID=" & nContractDetailID & "&ParentRecType=ContractDetail','pophelp',500,250,'yes');")
                    End With
                    item("CreateDate").Controls.Add(ctrlFlag)
                End If
            End Using
            
            
            
            Dim lnk As HyperLink = CType(item("Description").Controls(0), HyperLink)
                      
            If sLineType = "CO" Then
                
                lnk.Attributes("onclick") = "return EditChangeOrder(" & nContractDetailID & "," & nProjectID & "," & nContractID & ");"
                lnk.NavigateUrl = "#"
                lnk.ToolTip = "Edit this Change Order."
                
                
                
            Else  'Adj or Line Item
                lnk.Attributes("onclick") = "return EditLineItem(" & LineID & "," & nProjectID & "," & nContractID & ");"
                lnk.NavigateUrl = "#"
                lnk.ToolTip = "Edit this Line Item."
               
                
            End If
                
                     
        End If
  
    End Sub
    
    Private Sub RadGrid1_ItemDataBound(ByVal sender As Object, ByVal e As Telerik.Web.UI.GridItemEventArgs) Handles RadGrid1.ItemDataBound

        If (TypeOf e.Item Is GridDataItem) Then
            Dim dataItem As GridDataItem = CType(e.Item, GridDataItem)
            Dim LineID As Integer = dataItem.OwnerTableView.DataKeyValues(dataItem.ItemIndex)("LineID")
            Dim nAmount As Double = ProcLib.CheckNullNumField(dataItem.OwnerTableView.DataKeyValues(dataItem.ItemIndex)("Amount"))
            Dim nPendingAmount As Double = ProcLib.CheckNullNumField(dataItem.OwnerTableView.DataKeyValues(dataItem.ItemIndex)("PendingAmount"))
            Dim nExpended As Double = ProcLib.CheckNullNumField(dataItem.OwnerTableView.DataKeyValues(dataItem.ItemIndex)("Expended"))
            Dim nReimb As Integer = ProcLib.CheckNullNumField(dataItem.OwnerTableView.DataKeyValues(dataItem.ItemIndex)("Reimbursable"))
            Dim sLineType As String = dataItem.OwnerTableView.DataKeyValues(dataItem.ItemIndex)("LineType")
            
            Dim dItemDate As String = ProcLib.CheckNullDBField(dataItem.OwnerTableView.DataKeyValues(dataItem.ItemIndex)("ItemDate"))
            
           
            nTotalGridAmount += nAmount
            nTotalExpended += nExpended
                                  
            'Format the amounts in the appropriate colums and accumulate totals
            Dim reimb As String = dataItem("Reimbursable").Text
            If reimb = "1" Then
                dataItem("Reimbursable").Text = "R"
            Else
                dataItem("Reimbursable").Text = ""
            End If
            
            If sLineType = "CO" Then
                nTotalCOApproved += nAmount
                nTotalCOPending += nPendingAmount
                dataItem("LineType").BackColor = Color.LightYellow
                
            ElseIf sLineType = "AD" Then
                
                nTotalAdjustments += nAmount
                nTotalContractAmount += nAmount
                dataItem("LineType").BackColor = Color.LightPink
                If IsDate(dItemDate) Then
                    dataItem("CreateDate").Text = dItemDate
                End If
                
            Else
                nTotalContractAmount += nAmount
                dataItem("LineType").BackColor = Color.LightGreen
                
                If nReimb = 1 Then
                    nTotalReimbAmount += nAmount
                Else
                    nTotalNonReimbAmount += nAmount
                End If
                
                If IsDate(dItemDate) Then
                    dataItem("CreateDate").Text = dItemDate
                End If
            
            End If
                
                        
            If dataItem("Amount").Text = "$0.00" Then
                dataItem("Amount").Text = ""
            End If
            If dataItem("PendingAmount").Text = "$0.00" Then
                dataItem("PendingAmount").Text = ""
            End If
            
            
            Dim lnk As HyperLink = CType(dataItem("Description").Controls(0), HyperLink)
            Dim sText As String = lnk.Text
            If bReadOnly Then
                dataItem("Description").Controls.Clear()
                dataItem("Description").Text = sText
            Else
                If lnk.Text = "" Then
                    lnk.Text = "--none--"
                End If
           End If

        End If
        
        
        
        If (TypeOf e.Item Is GridFooterItem) Then
            Dim footerItem As GridFooterItem = CType(e.Item, GridFooterItem)
            
            nTotalContractAmount = nTotalNonReimbAmount + nTotalReimbAmount
            nTotalChangeOrders = nTotalCOApproved + nTotalCOPending
            
            nContractGrandTotal = nTotalContractAmount + nTotalChangeOrders + nTotalAdjustments
            
            nBalRemaining = nContractGrandTotal - nTotalExpended
            
            Dim sLineText As String = ""
            
 
            sLineText &= "Total Orig Contract:  <br />"
            sLineText &= "Total Change Orders:  <br />"
            sLineText &= "Total Adjustments:  <br /><br />"
            sLineText &= "Contract Grand Total:  <br />"
            sLineText &= "Total Spent: <br />"
            sLineText &= "Remaining Bal:"
            'footerItem("ObjectCodeDescription").HorizontalAlign = HorizontalAlign.Right
            'footerItem("ObjectCodeDescription").VerticalAlign = VerticalAlign.Top
            'footerItem("ObjectCodeDescription").Text = sLineText
            
            footerItem("Description").HorizontalAlign = HorizontalAlign.Right
            footerItem("Description").VerticalAlign = VerticalAlign.Top
            footerItem("Description").Text = sLineText
            
            sLineText = FormatCurrency(nTotalContractAmount) & "<br />"
            sLineText &= FormatCurrency(nTotalChangeOrders) & "<br />"
            sLineText &= FormatCurrency(nTotalAdjustments) & "<br /><br />"
            sLineText &= FormatCurrency(nContractGrandTotal) & "<br />"
            sLineText &= FormatCurrency(nTotalExpended) & "<br />"
            sLineText &= FormatCurrency(nBalRemaining) & "<br />"
            
            footerItem("JCAFLine").HorizontalAlign = HorizontalAlign.Right
            footerItem("JCAFLine").VerticalAlign = VerticalAlign.Top
            footerItem("JCAFLine").Text = sLineText
            
            
  
            sLineText = "Totals : "
            footerItem("ObjectCodeDescription").HorizontalAlign = HorizontalAlign.Right
            footerItem("ObjectCodeDescription").VerticalAlign = VerticalAlign.Top
            footerItem("ObjectCodeDescription").Text = sLineText
            
            sLineText = FormatCurrency(nTotalExpended)
            footerItem("Expended").VerticalAlign = VerticalAlign.Top
            footerItem("Expended").Text = sLineText
            
            sLineText = FormatCurrency(nTotalCOPending)
            footerItem("PendingAmount").VerticalAlign = VerticalAlign.Top
            footerItem("PendingAmount").Text = sLineText
 
            sLineText = FormatCurrency(nTotalGridAmount)
            footerItem("Amount").VerticalAlign = VerticalAlign.Top
            footerItem("Amount").Text = sLineText
            
            
            footerItem.Font.Bold = True
            
            footerItem.ToolTip = "You may not reduce the contract amount below the total transactions booked to date, and you may not exceed your current JCAF budget allocated to contract Object Code. "

        End If
        
    End Sub

    Protected Sub butExportToPDF_Click(ByVal sender As Object, ByVal e As System.EventArgs)
        RadGrid1.MasterTableView.ExportToPdf()
    End Sub

    Protected Sub butExportToExcel_Click(ByVal sender As Object, ByVal e As System.EventArgs)
        RadGrid1.MasterTableView.ExportToExcel()
    End Sub

</script>

<asp:Content ID="Content1" ContentPlaceHolderID="mainBody" runat="Server">
    <telerik:RadWindowManager ID="contentPopup" runat="server">
    </telerik:RadWindowManager>
    <telerik:RadMenu ID="RadMenu1" runat="server" OnItemClick="RadMenu1_ItemClick" Style="z-index: 10;" />
    <telerik:RadGrid ID="RadGrid1" runat="server" AllowSorting="true" AutoGenerateColumns="False"
        GridLines="None" Width="100%" Height="450px" EnableAJAX="True" Skin="" EnableEmbeddedSkins="false"
        GroupingEnabled="False">
        <ClientSettings AllowColumnsReorder="true" ColumnsReorderMethod="Reorder">
            <Scrolling AllowScroll="True" ScrollHeight="50%" UseStaticHeaders="True" />
            <Resizing AllowColumnResize="True" />
        </ClientSettings>
        <MasterTableView Width="100%" GridLines="None" NoMasterRecordsText="No Contract Line Items Found."
            EnableHeaderContextMenu="true" TableLayout="Fixed" AllowMultiColumnSorting="false"
            ShowHeadersWhenNoRecords="True" DataKeyNames="LineID,LineType,ContractChangeOrderID,ItemDate,PendingAmount,Amount,Expended,Reimbursable,ObjectCode,JCAFCellName"
            ShowFooter="true" FooterStyle-Height="30px">
            <Columns>
            
                          <telerik:GridBoundColumn DataField="LineType" UniqueName="LineType" HeaderText="Type">
                    <ItemStyle HorizontalAlign="Left" Width="25px" VerticalAlign="Top" />
                    <HeaderStyle HorizontalAlign="Left" Width="25px" Height="15px" />
                </telerik:GridBoundColumn>
                
                <telerik:GridHyperLinkColumn DataTextField="Description" UniqueName="Description"
                    HeaderText="Description" SortExpression="Description">
                    <ItemStyle HorizontalAlign="Left" Width="150px" VerticalAlign="Top" Wrap="false" />
                    <HeaderStyle HorizontalAlign="Left" Width="150px" Height="15px" />
                </telerik:GridHyperLinkColumn>
  
 <%--               
                                <telerik:GridBoundColumn DataField="ReferenceNo" UniqueName="ReferenceNo" HeaderText="Ref">
                    <ItemStyle HorizontalAlign="Left" Width="25px" VerticalAlign="Top" />
                    <HeaderStyle HorizontalAlign="Left" Width="25px" Height="15px" />
                </telerik:GridBoundColumn>
                --%>
                <telerik:GridBoundColumn DataField="CreateDate" HeaderText="Date" UniqueName="CreateDate"
                    DataFormatString="{0:MM/dd/yyyy}" SortExpression="CreateDate">
                    <ItemStyle Width="60px" HorizontalAlign="Left" VerticalAlign="Top" />
                    <HeaderStyle Width="60px" Height="20px" HorizontalAlign="Left" />
                </telerik:GridBoundColumn>
                <telerik:GridBoundColumn DataField="No" UniqueName="No" HeaderText="No">
                    <ItemStyle HorizontalAlign="Left" Width="25px" VerticalAlign="Top" />
                    <HeaderStyle HorizontalAlign="Left" Width="25px" Height="15px" />
                </telerik:GridBoundColumn>
                <telerik:GridBoundColumn DataField="JCAFLine" UniqueName="JCAFLine" HeaderText="JCAF Line">
                    <ItemStyle HorizontalAlign="Left" Width="100px" VerticalAlign="Top" Wrap="false" />
                    <HeaderStyle HorizontalAlign="Left" Width="100px" Height="15px" />
                </telerik:GridBoundColumn>
                <telerik:GridBoundColumn DataField="FundingSource" UniqueName="FundingSource" HeaderText="Funding">
                    <ItemStyle HorizontalAlign="Left" Width="75px" VerticalAlign="Top" />
                    <HeaderStyle HorizontalAlign="Left" Width="75px" Height="15px" />
                </telerik:GridBoundColumn>
                <telerik:GridBoundColumn DataField="ObjectCodeDescription" UniqueName="ObjectCodeDescription"
                    HeaderText="ObjectCode">
                    <ItemStyle HorizontalAlign="Left" Width="175px" VerticalAlign="Top" />
                    <HeaderStyle HorizontalAlign="Left" Width="175px" Height="15px" />
                </telerik:GridBoundColumn>
                <telerik:GridBoundColumn DataField="Expended" HeaderText="Expended" UniqueName="Expended"
                    DataFormatString="{0:c}">
                    <ItemStyle Width="125px" HorizontalAlign="Right" VerticalAlign="Top" />
                    <HeaderStyle Width="125px" HorizontalAlign="Right" />
                    <FooterStyle HorizontalAlign="Right" Width="125px" Height="15px" />
                </telerik:GridBoundColumn>
                <telerik:GridBoundColumn DataField="PendingAmount" HeaderText="Pending Amount" UniqueName="PendingAmount"
                    DataFormatString="{0:c}">
                    <ItemStyle Width="90px" HorizontalAlign="Right" VerticalAlign="Top" />
                    <HeaderStyle Width="90px" HorizontalAlign="Right" />
                    <FooterStyle HorizontalAlign="Right" Width="90px" Height="15px" />
                </telerik:GridBoundColumn>
                <telerik:GridBoundColumn DataField="Amount" HeaderText="Amount" UniqueName="Amount"
                    DataFormatString="{0:c}">
                    <ItemStyle Width="125px" HorizontalAlign="Right" VerticalAlign="Top" />
                    <HeaderStyle Width="125px" HorizontalAlign="Right" />
                    <FooterStyle HorizontalAlign="Right" Width="125px" Height="15px" />
                </telerik:GridBoundColumn>
                <telerik:GridBoundColumn DataField="Reimbursable" UniqueName="Reimbursable" HeaderText="R">
                    <ItemStyle HorizontalAlign="Left" Width="45px" VerticalAlign="Top" />
                    <HeaderStyle HorizontalAlign="Left" Width="45px" Height="15px" />
                </telerik:GridBoundColumn>
            </Columns>
            <FooterStyle Height="30px"></FooterStyle>
        </MasterTableView>
        <ExportSettings OpenInNewWindow="True">
            <Pdf PageWidth="297mm" PageHeight="210mm" />
        </ExportSettings>
    </telerik:RadGrid>
    <asp:HiddenField ID="txtAmount" runat="server" />
    <asp:HiddenField ID="txtReimbAmount" runat="server" />
    <asp:HiddenField ID="lblMinAmount" runat="server" />
    <asp:HiddenField ID="lblMaxAmount" runat="server" />
    <asp:HiddenField ID="txtxHasDependants" runat="server" />
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

            function EditLineItem(id, projectid,contractid) {

                //var oWnd = window.radopen("contract_lineitem_edit.aspx?ID=" + id + "&ContractID=" + contractid, "EditLineItemWindow");
                openPopup('contract_lineitem_edit.aspx?ID=' + id + '&ProjectID=' + projectid + '&ContractID=' + contractid ,'editTrans',525,400,'yes');

                
                return false;
            }

            function EditChangeOrder(id, projectid, contractid) {

               // var oWnd = window.radopen("contract_changeorder_edit.aspx?ContractDetailID=" + id + "&ProjectID=" + projectid + "&ContractID=" + contractid, "EditChangeOrderWindow");
                openPopup('contract_changeorder_edit.aspx?ContractDetailID=' + id + '&ProjectID=' + projectid + '&ContractID=' + contractid, 'editTrans', 650, 600, 'yes');
                
                return false;
            }
  
        </script>

    </telerik:RadCodeBlock>
</asp:Content>
