<%@ Page Language="VB" MasterPageFile="~/content.master" Title="" %>
<%@ Register Assembly="Telerik.Web.UI" Namespace="Telerik.Web.UI" TagPrefix="telerik" %>
<%@ Import Namespace="Prompt" %>

<script runat="server">
    Private nCollegeID As Integer = 0
    Private LedgerAccountID As Integer = 0
    Private TotalAmount As Double = 0
    Private TotalCredits As Double = 0
    Private TotalDebits As Double = 0
    Private bAllowLedgerItemEdit As Boolean = False
    
    Private Sub Page_Load(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MyBase.Load

        Session("PageID") = "LedgerEntriesView"
        
        nCollegeID = Request.QueryString("CollegeID")
        LedgerAccountID = Request.QueryString("LedgerAccountID")
        
        'Since this is the primary calling page from the Nav menu, we need to check if current view is something other than
        'Overview and if so redirect
        Dim masterTabs As RadTabStrip = Master.FindControl("tabMain")
        Dim masterViewTitle As Label = Master.FindControl("lblViewTitle")
        
        Dim sNewLocation As String = ""
        If Request.QueryString("t") <> "y" Then
            If Session("CurrentTab") <> "Overview" Then   'redirect to appropriate tab if available
                For Each radTab In masterTabs.GetAllTabs
                    If radTab.Value = Session("CurrentTab") Then
                        radTab.Selected = True
                        radTab.SelectParents()
                        Response.Redirect(radTab.NavigateUrl)
                        Exit For
                    End If
                Next
            End If
        End If
        Session("CurrentTab") = "Overview"
        'if we have not redirected then we are at the right place
        For Each radTab In masterTabs.GetAllTabs
            If radTab.Value = "Overview" Then
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
                        
            .ClientSettings.AllowColumnsReorder = False
            .ClientSettings.ColumnsReorderMethod = GridClientSettings.GridColumnsReorderMethod.Reorder
            .ClientSettings.Scrolling.AllowScroll = True
            .ClientSettings.Scrolling.ScrollHeight = Unit.Percentage(50)
            .ClientSettings.Scrolling.UseStaticHeaders = True
            .ClientSettings.Resizing.AllowColumnResize = True

            .MasterTableView.EnableHeaderContextMenu = True
            .MasterTableView.TableLayout = GridTableLayout.Fixed
            .MasterTableView.AllowMultiColumnSorting = False

            .Height = Unit.Pixel(500)
            .FooterStyle.Height = Unit.Pixel(30)

            .ExportSettings.FileName = "PromptLedgerExport"
            .ExportSettings.OpenInNewWindow = True
            .ExportSettings.Pdf.PageTitle = masterViewTitle.Text & " Ledger Entries"

        End With
        

        With contentPopups
            .VisibleOnPageLoad = False
            .Skin = "Windows7"
                         
            Dim ww As New RadWindow

            ww = New RadWindow
            With ww
                .ID = "EditAccount"
                .NavigateUrl = ""
                .Title = ""
                .Width = 500
                .Height = 375
                .Modal = True
                .VisibleStatusbar = False
                .ReloadOnShow = True
                .Behaviors = WindowBehaviors.Close
            End With
            .Windows.Add(ww)
                        
            ww = New RadWindow
            With ww
                .ID = "EditEntry"
                .NavigateUrl = ""
                .Title = ""
                .Width = 500
                .Height = 375
                .Modal = True
                .VisibleStatusbar = False
                .ReloadOnShow = True
                .Behaviors = WindowBehaviors.Close
            End With
            .Windows.Add(ww)
            
                 
        End With
        
        
        'update the link button to open attachments/notes window
        lnkEditAccount.Attributes("onclick") = "return EditAccount('" & LedgerAccountID & "');"
        lnkEditAccount.NavigateUrl = "#"
        lnkEditAccount.Visible = False
        
        'update the link button to open attachments/notes window
        lnkAddEntry.Attributes("onclick") = "return AddEntry('" & LedgerAccountID & "','" & nCollegeID & "');"
        lnkAddEntry.NavigateUrl = "#"
        lnkAddEntry.Visible = False
        
        ''update the link button 
        'lnkAllocate.Attributes("onclick") = "return AddAllocationEntry('" & RecID & "');"
        'lnkAllocate.NavigateUrl = "#"
        lnkAllocate.Visible = False    'TODO: Hide this for now as not sure we want to allocate this way
        
        
        
        SetSecurity()
 
    End Sub
    
    Private Sub SetSecurity()
        'Sets the security constraints for current page
        Using db As New EISSecurity
            db.CollegeID = nCollegeID
            db.ProjectID = 0
            If db.FindUserPermission("LedgerList", "Write") Then   'Only Admin and above can Edit/Add Ledger Accounts
                lnkEditAccount.Visible = True
                lnkAddEntry.Visible = True
                bAllowLedgerItemEdit = True
            End If
  

        End Using
    End Sub
    
    Protected Sub RadGrid1_NeedDataSource(ByVal source As Object, ByVal e As Telerik.Web.UI.GridNeedDataSourceEventArgs) Handles RadGrid1.NeedDataSource
        'loads the grid whenever it needs data (sorting, rebinding, etc...)
        Using db As New promptLedgerAccount
            db.CallingPage = Page
            RadGrid1.DataSource = db.GetLedgerAccountEntries(LedgerAccountID)
        End Using

    End Sub
    
    Protected Sub RadGrid1_ItemCreated(ByVal sender As Object, ByVal e As Telerik.Web.UI.GridItemEventArgs) Handles RadGrid1.ItemCreated
        'This event allows us to customize the cell contents - fired before databound
        
        If (TypeOf e.Item Is GridDataItem) Then
            Dim item As GridDataItem = CType(e.Item, GridDataItem)
            Dim nLedgerEntryID As Integer = item.OwnerTableView.DataKeyValues(item.ItemIndex)("LedgerEntryID")
            Dim nLedgerAccountID As Integer = item.OwnerTableView.DataKeyValues(item.ItemIndex)("LedgerAccountID")
            Dim nBudgetObjectCodeID As Integer = item.OwnerTableView.DataKeyValues(item.ItemIndex)("BudgetObjectCodeID")
             
            'update the link button to open attachments/notes window
            Dim lnk As HyperLink = CType(item("EditEntry").Controls(0), HyperLink)
            lnk.Attributes("onclick") = "return EditEntry('" & nLedgerAccountID & "','" & nLedgerEntryID & "','" & nCollegeID & "');"
            lnk.ToolTip = "Edit this entry."
            lnk.ImageUrl = "images/edit.png"
            lnk.NavigateUrl = "#"
            
            If bAllowLedgerItemEdit = True Then
                lnk.Visible = True
            Else
                lnk.Visible = False
            End If
            
            'If the Entry has a JCAF Column ID then can old remove through JCAF
            If nBudgetObjectCodeID > 0 Then
                lnk.Visible = False
            End If
             
        End If
    End Sub
    
    Private Sub RadGrid1_ItemDataBound(ByVal sender As Object, ByVal e As Telerik.Web.UI.GridItemEventArgs) Handles RadGrid1.ItemDataBound
        If (TypeOf e.Item Is GridDataItem) Then
            Dim dataItem As GridDataItem = CType(e.Item, GridDataItem)
            Dim nDebitAmount As Double = dataItem.OwnerTableView.DataKeyValues(dataItem.ItemIndex)("Debit")
            Dim nCreditAmount As Double = dataItem.OwnerTableView.DataKeyValues(dataItem.ItemIndex)("Credit")
            Dim nAmount As Double = dataItem.OwnerTableView.DataKeyValues(dataItem.ItemIndex)("Amount")
            
            Dim sProjectName As String = ProcLib.CheckNullDBField(dataItem.OwnerTableView.DataKeyValues(dataItem.ItemIndex)("ProjectName"))
            Dim sProjectNumber As String = ProcLib.CheckNullDBField(dataItem.OwnerTableView.DataKeyValues(dataItem.ItemIndex)("ProjectNumber"))
            Dim sObjectCode As String = ProcLib.CheckNullDBField(dataItem.OwnerTableView.DataKeyValues(dataItem.ItemIndex)("ObjectCode"))
            Dim sObjectCodeDescription As String = ProcLib.CheckNullDBField(dataItem.OwnerTableView.DataKeyValues(dataItem.ItemIndex)("ObjectCodeDescription"))
            
            TotalCredits += nCreditAmount
            TotalDebits += nDebitAmount
            TotalAmount = TotalDebits + TotalCredits
            
            'If dataItem("Credit").Text = "$0.00" Then
            '    dataItem("Credit").Text = ""
            'End If
            'If dataItem("Debit").Text = "$0.00" Then
            '    dataItem("Debit").Text = ""
            'End If
            'If dataItem("Amount").Text = "$0.00" Then
            '    dataItem("Amount").Text = ""
            'End If
            
            If nAmount < 0 Then
                dataItem("Amount").ForeColor = Color.Red
            End If
            
            If Trim(sProjectName) <> "" Then
                sProjectName = sProjectNumber & "-" & sProjectName
                dataItem("ProjectName").Text = sProjectName
            End If
            
            If Trim(sObjectCode) <> "" Then
                sObjectCode = sObjectCode & " - " & sObjectCodeDescription
                dataItem("ObjectCode").Text = sObjectCode
            End If
  
        End If
        If (TypeOf e.Item Is GridFooterItem) Then
           
            Dim footerItem As GridFooterItem = CType(e.Item, GridFooterItem)
            footerItem("Description").Text = "Balance: "
            footerItem("Amount").Text = FormatCurrency(TotalAmount)
            If TotalAmount < 0 Then
                footerItem("Amount").ForeColor = Color.Red
            End If
            
            footerItem("Description").Font.Bold = True
            footerItem("Amount").Font.Bold = True
            
            

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
    <telerik:RadWindowManager ID="contentPopups" runat="server">
</telerik:RadWindowManager>
<div id="contentwrapper">
<div id="navrow">

<asp:HyperLink ID="lnkAddEntry" CssClass="addnew" runat="server">Add Entry</asp:HyperLink>
<asp:HyperLink ID="lnkEditAccount" CssClass="edit" runat="server">Edit Account</asp:HyperLink>
&nbsp;&nbsp;&nbsp;
<asp:HyperLink ID="lnkAllocate" ImageUrl="~/images/ledger_allocation_add.png" ToolTip="Add New Allocation." runat="server">Allocate</asp:HyperLink>
<asp:LinkButton ID="butExportToPdf" Text="Export to PDF" runat="server" onclick="butExportToPDF_Click" CssClass="pdf"></asp:LinkButton>
<asp:LinkButton ID="butExportToExcel" Text="Export to Excel" runat="server" CssClass="excel" onclick="butExportToExcel_Click"></asp:LinkButton>
</div>
<div id="contentcolumn">
<div class="innertube"><div id="printdiv"><span class="hdprint"><asp:Label ID="lblProjectName" runat="server"></asp:Label></span>
<telerik:RadGrid ID="RadGrid1" runat="server" AllowSorting="False" AutoGenerateColumns="False"
    GridLines="None" Width="100%" EnableAJAX="True">
    <ClientSettings>
        <Scrolling AllowScroll="False" UseStaticHeaders="True" />
    </ClientSettings>
    <MasterTableView Width="100%" GridLines="None" NoMasterRecordsText="No Ledger Entries Found."
        ShowHeadersWhenNoRecords="True" DataKeyNames="Amount,LedgerAccountID,LedgerEntryID,BudgetObjectCodeID,Debit,Credit,
        ObjectCode,ProjectName,ProjectNumber,ObjectCodeDescription" ShowFooter="true" >
        <Columns>
            <telerik:GridHyperLinkColumn HeaderText="" UniqueName="EditEntry">
                <ItemStyle Width="35px" HorizontalAlign="Left" />
                <HeaderStyle Width="35px" HorizontalAlign="Left" />
            </telerik:GridHyperLinkColumn>
            <telerik:GridBoundColumn DataField="EntryDate" HeaderText="Date" UniqueName="EntryDate"
                DataFormatString="{0:MM/dd/yyyy}">
                <ItemStyle Width="75px" HorizontalAlign="Left" VerticalAlign="Top" />
                <HeaderStyle Width="75px" Height="20px" HorizontalAlign="Left" />
            </telerik:GridBoundColumn>
            <telerik:GridBoundColumn DataField="Description" UniqueName="Description" HeaderText="Description">
                <ItemStyle HorizontalAlign="Left" VerticalAlign="Top" Width="50%" />
                <HeaderStyle HorizontalAlign="Left" Width="50%" Height="15px" />
                <FooterStyle HorizontalAlign="Right" Width="50%"  />
            </telerik:GridBoundColumn>
            
                       <telerik:GridBoundColumn DataField="ProjectName" UniqueName="ProjectName" HeaderText="Project">
                <ItemStyle HorizontalAlign="Left" VerticalAlign="Top" Width="20%" />
                <HeaderStyle HorizontalAlign="Left" Width="20%" Height="15px" />
                <FooterStyle HorizontalAlign="Right" Width="20%"  />
            </telerik:GridBoundColumn>
            
                       <telerik:GridBoundColumn DataField="ObjectCode" UniqueName="ObjectCode" HeaderText="Object Code">
                <ItemStyle HorizontalAlign="Left" VerticalAlign="Top" Width="75px" />
                <HeaderStyle HorizontalAlign="Left" Width="75px" Height="15px" />
                <FooterStyle HorizontalAlign="Right" Width="75px"  />
            </telerik:GridBoundColumn>
            
           <telerik:GridBoundColumn DataField="FiscalYear" UniqueName="FiscalYear" HeaderText="FY">
                <ItemStyle HorizontalAlign="Left" VerticalAlign="Top" Width="35px" />
                <HeaderStyle HorizontalAlign="Left" Width="35px" Height="75px" />
                <FooterStyle HorizontalAlign="Right" Width="35px"  />
            </telerik:GridBoundColumn>
            
           <telerik:GridBoundColumn DataField="BondSeries" UniqueName="BondSeries" HeaderText="Series">
                <ItemStyle HorizontalAlign="Left" VerticalAlign="Top" Width="40px" />
                <HeaderStyle HorizontalAlign="Left" Width="40px" Height="75px" />
                <FooterStyle HorizontalAlign="Right" Width="40px" />
            </telerik:GridBoundColumn>
            
   
     <%--       <telerik:GridBoundColumn DataField="Debit" HeaderText="Debit" UniqueName="Debit"
                DataFormatString="{0:c}">
                <ItemStyle Width="85px" HorizontalAlign="Right" VerticalAlign="Top" />
                <HeaderStyle Width="85px" HorizontalAlign="Right" />
                <FooterStyle HorizontalAlign="Right" Width="85px" Height="15px" />
            </telerik:GridBoundColumn>
            <telerik:GridBoundColumn DataField="Credit" HeaderText="Credit" UniqueName="Credit"
                DataFormatString="{0:c}">
                <ItemStyle Width="90px" HorizontalAlign="Right" VerticalAlign="Top" />
                <HeaderStyle Width="90px" HorizontalAlign="Right" />
                <FooterStyle HorizontalAlign="Right" Width="90px" Height="15px" />
            </telerik:GridBoundColumn>--%>
            <telerik:GridBoundColumn DataField="Amount" HeaderText="Amount" UniqueName="Amount"
                DataFormatString="{0:c}" Visible="True">
                <ItemStyle Width="90px" HorizontalAlign="Right" VerticalAlign="Top" />
                <HeaderStyle Width="90px" HorizontalAlign="Right" />
                <FooterStyle HorizontalAlign="Right" Width="90px" Height="15px" />
            </telerik:GridBoundColumn>
        </Columns>
     </MasterTableView>
    <ExportSettings OpenInNewWindow="True">
           <Pdf PageWidth = "297mm" PageHeight = "210mm" />    
    </ExportSettings>
</telerik:RadGrid>
</div>
</div></div></div>
<br class="clear" />
<div class="id_display">College ID: <asp:Label ID="lblCollegeID" runat="server"></asp:Label> Account ID: <asp:Label ID="lblLedgerAccountID" runat="server"></asp:Label></div>
        
    <telerik:RadCodeBlock ID="RadCodeBlock1" runat="server">

        <script type="text/javascript" language="javascript">

            function EditAccount(id) {

                var oWnd = window.radopen("ledger_account_edit.aspx?LedgerAccountID=" + id + "&WinType=RAD", "EditAccount");
                return false;

            }

            function AddEntry(acctid,collegeid)     //for adding entries
            {

                var oWnd = window.radopen("ledger_entry_edit.aspx?CollegeID=" + collegeid + "&LedgerEntryID=0&LedgerAccountID=" + acctid, "EditEntry");
                return false;
            }

            function AddAllocationEntry(acctid)     //for adding allocation entries
            {

                var oWnd = window.radopen("ledger_entry_allocation_edit.aspx?LedgerEntryID=0&LedgerAccountID=" + acctid, "EditEntry");
                return false;
            }

            function EditEntry(acctid, id,collegeid)     //for editing entries
            {

                var oWnd = window.radopen("ledger_entry_edit.aspx?CollegeID=" + collegeid + "&LedgerEntryID=" + id + "&LedgerAccountID=" + acctid, "EditEntry");
                return false;
            }

            function EditAllocationEntry(acctid, id)     //for editing allocation entries
            {

                var oWnd = window.radopen("ledger_entry_edit.aspx?LedgerEntryID=" + id + "&LedgerAccountID=" + acctid, "EditEntry");
                return false;
            }  
         
  

        </script>

    </telerik:RadCodeBlock>
</asp:Content>
