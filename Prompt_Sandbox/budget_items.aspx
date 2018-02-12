<%@ Page Language="vb" %>

<%@ Register Assembly="Telerik.Web.UI" Namespace="Telerik.Web.UI" TagPrefix="telerik" %>
<%@ Import Namespace="Prompt" %>

<script runat="server">
    
    Private JCAFColumnName As String
    Private ProjectID As Integer
    Private CollegeID As Integer
      
    
    Private nTotalEncumbered As Double = 0
    Private nTotalPassthroughEncumbered As Double = 0
    Private nTotalNonEncumbered As Double = 0
    Private nTotalBudgetItems As Double = 0
    
    Private bReadOnly As Boolean = True
        
    Private Sub Page_Load(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MyBase.Load

        JCAFColumnName = Request.QueryString("FieldName")
        ProjectID = Request.QueryString("ProjectID")
        CollegeID = Session("CollegeID")
          
        ProcLib.LoadPopupJscript(Page)

        'set up help button
        Session("PageID") = "JCAFBudgetItems"
        
        If Not IsPostBack Then     'populate the fields
            
            
            Using db As New PromptDataHelper
                Page.Header.Title = db.ExecuteScalar("SELECT JCAFShortDescription FROM BudgetFieldsTable WHERE ColumnName ='" & JCAFColumnName & "' ")
           
            End Using
           
        End If
 
        
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

            .MasterTableView.EnableHeaderContextMenu = False
            .MasterTableView.TableLayout = GridTableLayout.Fixed
            .MasterTableView.AllowMultiColumnSorting = False
            .MasterTableView.NoMasterRecordsText = "No Allocations Found."

            .Height = Unit.Pixel(250)
            
            .ExportSettings.FileName = "PromptJCAFExport"
            .ExportSettings.OpenInNewWindow = True
            .ExportSettings.Pdf.PageTitle = "JCAF Budget Items"

        End With
        
   
        'Lock down view only Clients
        Using db As New EISSecurity
            db.CollegeID = Session("CollegeID")
            db.ProjectID = ProjectID
            If db.FindUserPermission("JCAFBudget", "Write") = False Then
                bReadOnly = True
            Else
                bReadOnly = False
                
            End If

        End Using
        
               
        BuildMenu()
        
    
    End Sub

               
    Private Sub BuildMenu()
        
        If Not IsPostBack Then          'Configure Tool Bar
            
            With RadMenu1
                .EnableEmbeddedSkins = True
                .Skin = "Vista"
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
                .Text = "Add New Line"
                .ImageUrl = "images/add.png"
                .ToolTip = "Add a New Line."
                .NavigateUrl = "budget_item_edit.aspx?PrimaryKey=0&CollegeID=" & CollegeID & "&ProjectID=" & ProjectID & "&FieldName=" & JCAFColumnName
                .PostBack = True
                If bReadOnly Then
                    .Visible = False
                Else
                    .Visible = True
                End If
            End With
            RadMenu1.Items.Add(but)
            
            but = New RadMenuItem
            With but
                .Text = "Transfer"
                .Value = "Transfer"
                .ImageUrl = "images/exchange.png"
                .ToolTip = "Transfer unencumbered amount to different Project."
                .NavigateUrl = "budget_item_transfer.aspx?PrimaryKey=0&CollegeID=" & CollegeID & "&ProjectID=" & ProjectID & "&FieldName=" & JCAFColumnName
                .PostBack = True
                If bReadOnly Then
                    .Visible = False
                Else
                    .Visible = True
                End If
            End With
            RadMenu1.Items.Add(but)

            but = New RadMenuItem
            but.IsSeparator = True
            but.Width = Unit.Pixel(5)
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
            
 
            RadMenu1.Items.Add(butDropDown)
            
            
            'butDropDown = New RadMenuItem
            'With butDropDown
            '    .Text = "Print"
            '    .Value = "Print"
            '    .ImageUrl = "images/printer.png"
            '    .PostBack = False
            'End With

            'butSub = New RadMenuItem
            'With butSub
            '    .Text = "Budget Allocation Detail Report"
            '    .Value = "BudgetAllocationReport"
            '    .ImageUrl = "images/printer.png"
            '    .NavigateUrl = "report_run.aspx?DirectCall=1&rpt=Allocation_Detail_By_Project&Item=" & JCAFColumnName & "&ProjectID=" & ProjectID
            '    .Target = "_new"
            '    .PostBack = True
            'End With
            'butDropDown.Items.Add(butSub)

            'RadMenu1.Items.Add(butDropDown)
            
                        
            but = New Telerik.Web.UI.RadMenuItem
            With but
                .Text = "Exit"
                .Value = "Exit"

                .ImageUrl = "images/exit.png"
            End With
            RadMenu1.Items.Add(but)
            
            but = New RadMenuItem
            but.IsSeparator = True
            but.Width = Unit.Pixel(200)
            RadMenu1.Items.Add(but)
            
            but = New Telerik.Web.UI.RadMenuItem
            With but
                .Text = "Flag"
                .Value = "Flag"
                .ImageUrl = "images/flag.gif"
                .Attributes("onclick") = "openPopup('flag_edit.aspx?ParentRecID=" & ProjectID & "&ParentRecType=BudgetItem&BudgetItem=" & JCAFColumnName & "','pophelp',550,450,'yes');"
                .PostBack = False

            End With
            RadMenu1.Items.Add(but)
            
   
            but = New Telerik.Web.UI.RadMenuItem
            With but
                .Text = "Help"
                .Value = "Help"
                .ImageUrl = "images/help.png"
                .Attributes("onclick") = "openPopup('help_view.aspx','pophelp',550,450,'yes');"
                .PostBack = False

            End With
            RadMenu1.Items.Add(but)

 
    
        End If

    End Sub
    
    Protected Sub RadMenu1_ItemClick(ByVal sender As Object, ByVal e As Telerik.Web.UI.RadMenuEventArgs) Handles RadMenu1.ItemClick
       
        Dim btn As RadMenuItem = e.Item
        
        Select Case btn.Value
            
            Case "Exit"
                
                Session("RtnFromEdit") = True
                ProcLib.CloseAndRefreshRADNoPrompt(Page)
               

            Case "ExportExcel"
 
                RadGrid1.MasterTableView.ExportToExcel()
                
 

        End Select
        
    End Sub
   
    'Private Sub butAllocationReport_Click(ByVal sender As System.Object, ByVal e As System.Web.UI.ImageClickEventArgs) Handles butAllocationReport.Click

    '    Dim slnk As String
    '    slnk = "report_run.aspx?DirectCall=1&rpt=Allocation_Detail_By_Project&Item=" & JCAFColumnName & "&ProjectID=" & ProjectID

    '    Dim jscript As String
    '    'popup edit page
    '    jscript = "<script language='javascript'>"
    '    jscript = jscript & "openPopup('" & slnk & "','projedit',700,700,'yes');"
    '    jscript = jscript & "</" & "script>"
    '    Page.ClientScript.RegisterStartupScript(GetType(String), "PopupClose", jscript)
    'End Sub
    
    Protected Sub RadGrid1_NeedDataSource(ByVal source As Object, ByVal e As Telerik.Web.UI.GridNeedDataSourceEventArgs) Handles RadGrid1.NeedDataSource
        'loads the grid whenever it needs data (sorting, rebinding, etc...)
        Using db As New PromptDataHelper
            Dim sql As String = "SELECT BudgetObjectCodes.*, "

            sql &= " (SELECT SUM(Amount) AS Expr1 FROM ContractLineItems WHERE ProjectID = BudgetObjectCodes.ProjectID AND "
            sql &= " JCAFCellName = BudgetObjectCodes.JCAFColumnName) AS TotalEncumbered, "
            sql &= " (SELECT SUM(Amount) AS Expr1 FROM ContractLineItems WHERE ProjectID = BudgetObjectCodes.ProjectID AND ObjectCode = BudgetObjectCodes.ObjectCode AND "
            sql &= " JCAFCellName = BudgetObjectCodes.JCAFColumnName) AS OCEncumberedAmount, "

            sql &= " (SELECT SUM(Amount) AS Expr1 FROM PassThroughEntries WHERE ProjectID = BudgetObjectCodes.ProjectID AND ObjectCode = BudgetObjectCodes.ObjectCode AND "
            sql &= " JCAFCellName = BudgetObjectCodes.JCAFColumnName) AS OCPassThroughEncumberedAmount, "

            sql &= " (SELECT SUM(Amount) AS Expr1 FROM BudgetObjectCodes AS Bud2 WHERE ProjectID = BudgetObjectCodes.ProjectID AND ObjectCode = BudgetObjectCodes.ObjectCode AND "
            sql &= "JCAFColumnName = BudgetObjectCodes.JCAFColumnName) AS OCTotalAmount, "
            sql &= "LedgerAccounts.LedgerName AS LedgerAccountName "
            sql &= "FROM BudgetObjectCodes LEFT OUTER JOIN LedgerAccounts ON BudgetObjectCodes.LedgerAccountID = LedgerAccounts.LedgerAccountID "
            sql &= "WHERE ProjectID = " & ProjectID & " AND JCAFColumnName = '" & JCAFColumnName & "'"

            RadGrid1.DataSource = db.ExecuteDataTable(sql)
            
        End Using
        
    End Sub
    
    
    Protected Sub RadGrid1_ItemCreated(ByVal sender As Object, ByVal e As Telerik.Web.UI.GridItemEventArgs) Handles RadGrid1.ItemCreated
        'This event allows us to customize the cell contents - fired before databound
        
        If (TypeOf e.Item Is GridDataItem) Then
            Dim item As GridDataItem = CType(e.Item, GridDataItem)
            
            Dim nID As Integer = item.OwnerTableView.DataKeyValues(item.ItemIndex)("PrimaryKey")
  
            'update the link button to open attachments/notes window
            Dim lnk As HyperLink = CType(item("Description").Controls(0), HyperLink)
            lnk.NavigateUrl = "budget_item_edit.aspx?PrimaryKey=" & nID & "&CollegeID=" & CollegeID & "&ProjectID=" & ProjectID & "&FieldName=" & JCAFColumnName

   
  
               
        End If
    End Sub
    
    Private Sub RadGrid1_ItemDataBound(ByVal sender As Object, ByVal e As Telerik.Web.UI.GridItemEventArgs) Handles RadGrid1.ItemDataBound
        If (TypeOf e.Item Is GridDataItem) Then
            Dim dataItem As GridDataItem = CType(e.Item, GridDataItem)

            Dim nAmount As Double = dataItem.OwnerTableView.DataKeyValues(dataItem.ItemIndex)("Amount")
            
            nTotalBudgetItems += nAmount
            nTotalEncumbered = ProcLib.CheckNullNumField(dataItem.OwnerTableView.DataKeyValues(dataItem.ItemIndex)("TotalEncumbered"))  'NOTE: This is summed in the SQL and is same for all lines -- grand total
           
            If nTotalPassthroughEncumbered = 0 Then
                nTotalPassthroughEncumbered = ProcLib.CheckNullNumField(dataItem.OwnerTableView.DataKeyValues(dataItem.ItemIndex)("OCPassThroughEncumberedAmount"))  'NOTE: This is summed in the SQL and will be present on cooresponding oc only
            End If
           
          
            'update the link button to open attachments/notes window
            Dim lnk As HyperLink = CType(dataItem("Description").Controls(0), HyperLink)
            If IsDBNull(lnk.Text) Then
                lnk.Text = "--none--"
            Else
                If Len(lnk.Text) > 25 Then
                    lnk.Text = Left(lnk.Text, 25) & "..."
                End If
            End If
            
            Dim sText As String = ""
            'If nAmount > nRemaining Then
            'sText = "You cannot remove this line as the Amount is greater than the Total Unencumbered for this Object Code"
            '    lnk.ForeColor = Color.DarkRed

            'Else
            '    lnk.ForeColor = Color.DarkGreen
            '    sText = "This Allocation line is Unencumbered."
            'End If
            
            'dataItem("Description").ToolTip = ""
            'lnk.ToolTip = sText
            'dataItem("Description").Attributes.Add("OCUnencumbered", nRemaining)
            
  
            
            Dim sNote As String = Trim(dataItem("Notes").Text)
            dataItem("Notes").ToolTip = sNote
            If Len(sNote) > 50 Then
                dataItem("Notes").Text = Left(sNote, 50) & "..."
            End If
       
        End If
        
        If (TypeOf e.Item Is GridFooterItem) Then
            
            nTotalNonEncumbered = nTotalBudgetItems - nTotalEncumbered - nTotalPassthroughEncumbered
            
            Dim footerItem As GridFooterItem = CType(e.Item, GridFooterItem)
            Dim sText As String = ""
            sText = "Total Budget: <br /> Total Contract Encumbered: <br />  Total Passthrough Encumbered: <br /> Total Non Encumbered: "
            footerItem("Description").Text = sText
            footerItem("Description").HorizontalAlign = HorizontalAlign.Right
            footerItem("Description").ColumnSpan = 2
            
            sText = FormatCurrency(nTotalBudgetItems) & "<br />" & FormatCurrency(nTotalEncumbered) & "<br />" & FormatCurrency(nTotalPassthroughEncumbered) & "<br />" & FormatCurrency(nTotalNonEncumbered)
            footerItem("Amount").Text = sText
            footerItem("Amount").HorizontalAlign = HorizontalAlign.Right
            
            If bReadOnly = False Then
                If nTotalNonEncumbered > 0 Then
                    RadMenu1.FindItemByValue("Transfer").Visible = True
                Else
                    RadMenu1.FindItemByValue("Transfer").Visible = False
                End If
            End If
            
        End If
  
        
    End Sub


</script>

<html>
<head runat="server">
    <title>JCAF Budget Items</title>
    <link href="Styles.css" type="text/css" rel="stylesheet" />
    <link href="skins/Prompt/Grid.Prompt.css" rel="stylesheet" type="text/css" />
    <link href="skins/Prompt/Menu.Prompt.css" rel="stylesheet" type="text/css" />
    
    
    
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

            function GetRadWindow() {
                var oWindow = null;
                if (window.RadWindow) oWindow = window.RadWindow;
                else if (window.frameElement.radWindow) oWindow = window.frameElement.radWindow;
                return oWindow;
            }


        </script>

    </telerik:RadCodeBlock>  

</head>
<body>
    <form id="Form1" method="post" runat="server">
    <telerik:RadScriptManager ID="RadScriptManager1" runat="server" />
    
    <telerik:RadMenu ID="RadMenu1" runat="server" OnItemClick="RadMenu1_ItemClick" />
<br />
<br />
    <telerik:RadGrid ID="RadGrid1" runat="server" AllowMultiRowSelection="False" AutoGenerateColumns="False"
        Skin="" GridLines="None" AllowSorting="true">
        <ClientSettings>
            <Selecting AllowRowSelect="True" />
            <Scrolling AllowScroll="True" UseStaticHeaders="True" ScrollHeight="50%" />
        </ClientSettings>
        <MasterTableView Width="100%" GridLines="None" DataKeyNames="Notes,ObjectCode,PrimaryKey,Amount,OCTotalAmount,OCEncumberedAmount,OCPassThroughEncumberedAmount,TotalEncumbered"
            ShowFooter="true" FooterStyle-Height="40px">
            <Columns>
                <telerik:GridHyperLinkColumn DataTextField="Description" UniqueName="Description" HeaderText="Object Code" SortExpression="Description">
                    <ItemStyle HorizontalAlign="Left" Width="150px" />
                    <HeaderStyle HorizontalAlign="Left" Width="150px" />
                </telerik:GridHyperLinkColumn>
                <telerik:GridBoundColumn DataField="ItemDate" HeaderText="Date" UniqueName="ItemDate"
                    DataFormatString="{0:MM/dd/yyyy}" SortExpression="ItemDate">
                    <ItemStyle Width="70px" HorizontalAlign="Center" VerticalAlign="Top" />
                    <HeaderStyle Width="70px" HorizontalAlign="Center" />
                </telerik:GridBoundColumn>
                <telerik:GridBoundColumn DataField="Notes" UniqueName="Notes" HeaderText="Note">
                    <ItemStyle HorizontalAlign="Left" Width="170px" />
                    <HeaderStyle HorizontalAlign="Left" Width="170px" />
                </telerik:GridBoundColumn>
                <telerik:GridBoundColumn DataField="LedgerAccountName" UniqueName="LedgerAccountName" HeaderText="From">
                    <ItemStyle HorizontalAlign="Left" Width="45px" />
                    <HeaderStyle HorizontalAlign="Left" Width="45px" />
                </telerik:GridBoundColumn>
                <telerik:GridBoundColumn DataField="Amount" HeaderText="Amount" UniqueName="Amount"
                    DataFormatString="{0:c}">
                    <ItemStyle HorizontalAlign="Right" Width="150px" />
                    <HeaderStyle HorizontalAlign="Right" Width="150px" />
                </telerik:GridBoundColumn>
            </Columns>
 
        </MasterTableView>
    </telerik:RadGrid>

        
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
 
    </form>
</body>
</html>
