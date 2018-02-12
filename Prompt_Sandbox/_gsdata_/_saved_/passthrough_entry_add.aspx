<%@ Page Language="vb" %>

<%@ Register Assembly="Telerik.Web.UI" Namespace="Telerik.Web.UI" TagPrefix="telerik" %>
<%@ Import Namespace="Prompt" %>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">

<script runat="server">
    
    Public nPassthroughEntryID As Integer = 0
    Public nProjectID As Integer = 0
    Public nLedgerAccountID As Integer = 0
    
    Private Sub Page_Load(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MyBase.Load

        ProcLib.CheckSession(Page)
        ProcLib.LoadPopupJscript(Page)

        lblMessage.Text = ""
        
        'set up help button
        Session("PageID") = "PassthroughEntryEdit"
        butHelp.Attributes.Add("onclick", "openPopup('help_view.aspx','pophelp',550,450,'yes');")
        butHelp.NavigateUrl = "#"


        nPassthroughEntryID = Request.QueryString("PassthroughEntryID")
        nProjectID = Request.QueryString("ProjectID")
        nLedgerAccountID = Request.QueryString("LedgerAccountID")
        
        If nPassthroughEntryID = 0 Then
            butDelete.Visible = False
        End If
        
        If IsPostBack Then   'only do the following post back
            nPassthroughEntryID = lblID.Text
        Else  'only do the following on first load
            Using db As New promptPassthrough
                db.CallingPage = Page
                If nPassthroughEntryID = 0 Then    'new entry
                    txtEntryDate.SelectedDate = Now()
                End If
                lblID.Text = nPassthroughEntryID
                db.FillObjectCodeList(lstObjectCode)
                db.FillBondSeriesList(lstBondSeries)

            End Using
            
            Using db As New PromptDataHelper
                Dim sql As String = "SELECT DISTINCT Category AS Val, Category as Lbl FROM Projects WHERE DistrictID=" & Session("DistrictID") & " ORDER BY Category"
                db.FillDropDown(sql, lstProjectCategory, False, False, False)
                
                sql = "SELECT LookupValue AS Val, LookupTitle as Lbl FROM Lookups WHERE ParentTable = 'Transactions' AND ParentField = 'FiscalYear' AND DistrictID=" & Session("DistrictID") & " ORDER BY LookupTitle"
                db.FillDropDown(sql, lstFiscalYear, False, False, False)
                
            End Using
            
            With lstJCAFSource
                Dim item As New ListItem
                item.Text = "Other - Bond"
                item.Value = "OtherBond"
                item.Selected = True
                .Items.Add(item)
                
                item = New ListItem
                item.Text = "Other - State"
                item.Value = "OtherSF"
                .Items.Add(item)
                
            End With
            
            txtAllocationPercent.Value = 0
            txtFrom.SelectedDate = Now()
            txtThru.SelectedDate = Now()
            
            FillProjectsList()
            
            
        End If

        txtEntryDate.Focus()

    End Sub
    
    Private Sub FillProjectsList()
        
        lstProjects.Items.Clear()
        
        Dim sCategory As String = lstProjectCategory.SelectedValue
        Dim sObjectCode As String = lstObjectCode.SelectedValue
        Dim sJCAFCellName As String = lstJCAFSource.SelectedValue
        
        Dim sql = "SELECT Colleges.College, Projects.ProjectID,Projects.ProjectNumber, Projects.ProjectName, "
        sql &= "  ISNULL(dbo.Projects.IsPassthroughProject, 0) AS IsPassthroughProject, "
        
        sql &= "(SELECT ISNull(SUM(Amount),0) AS Exp1 FROM BudgetObjectCodes WHERE ProjectID = Projects.ProjectID AND ObjectCode='" & sObjectCode & "' AND JCAFColumnName='" & sJCAFCellName & "') AS JCAFAmount,"
        sql &= "(SELECT ISNull(SUM(Amount),0) AS Exp1 FROM PassThroughEntries WHERE ProjectID = Projects.ProjectID AND ObjectCode='" & sObjectCode & "' AND JCAFCellName='" & sJCAFCellName & "') AS PassThroughExpenses,"
        sql &= "(SELECT ISNull(SUM(Amount),0) AS Exp1 FROM ContractLineItems WHERE ProjectID = Projects.ProjectID AND ObjectCode='" & sObjectCode & "' AND JCAFCellName='" & sJCAFCellName & "') AS ContractEncumberances "

        sql &= " FROM Projects INNER JOIN "
        sql &= "Colleges ON Projects.CollegeID = Colleges.CollegeID "
        sql &= "WHERE Colleges.DistrictID = " & HttpContext.Current.Session("DistrictID") & " AND (ISNULL(dbo.Projects.IsPassthroughProject, 0) <> 1) "
        sql &= "AND Projects.Category = '" & sCategory & "' "
        sql &= "ORDER BY Colleges.College, Projects.ProjectNumber, Projects.ProjectName"

        Using db As New PromptDataHelper
            
            Dim tbl As DataTable = db.ExecuteDataTable(sql)
            For Each Row In tbl.Rows
                Dim sBal As Double = Row("JCAFAmount") - Row("PassThroughExpenses") - Row("ContractEncumberances")
                Dim item As New RadListBoxItem
                item.Text = Row("College") & " : (" & Row("ProjectNumber") & ")" & Row("ProjectName")
                item.Value = Row("ProjectID")
                item.Checked = True
                
                'Now do a test allocation and see if there is enought in the JCAF
               
               
                Dim nPercent As Double = txtAllocationPercent.Value
                Dim nTotalAllocation As Double = 0
                Dim dFrom As Date = txtFrom.SelectedDate
                Dim dThru As Date = txtThru.SelectedDate
                Dim nTargetTotal As Double = 0
 
                sql = "SELECT ISNULL(SUM(TotalAmount), 0) AS Total FROM Transactions "
                sql &= "WHERE DatePaid BETWEEN '" & dFrom & "' AND '" & dThru & "' AND "
                sql &= "(Status = 'Paid' AND (TransType='Invoice' OR TransType='Credit') "
                sql &= " AND ProjectID = " & Row("ProjectID") & ")"

                nTargetTotal = db.ExecuteScalar(sql)
                If nTargetTotal > 0 Then
                    Dim nAllocationAmount As Double = ProcLib.Round(nTargetTotal * (nPercent / 100), 2)
                    If sBal < nAllocationAmount Then
                        item.ForeColor = Color.Red
                    End If
                End If

                lstProjects.Items.Add(item)
            Next
           
            
          
        End Using
 
    End Sub
   

    Private Sub butDelete_Click(ByVal sender As System.Object, ByVal e As System.Web.UI.ImageClickEventArgs) Handles butDelete.Click
        Using db As New promptPassthrough
            db.CallingPage = Page
            'db.DeleteLedgerEntry(nPassthroughEntryID)
        End Using
        Session("RtnFromEdit") = True
        ProcLib.CloseAndRefreshRAD(Page)
    End Sub


    Private Sub butSave_Click(ByVal sender As System.Object, ByVal e As System.Web.UI.ImageClickEventArgs) Handles butSave.Click
        
        
        If IsNothing(txtEntryDate.SelectedDate) Or IsNothing(txtFrom.SelectedDate) Or IsNothing(txtThru.SelectedDate) Or txtAllocationPercent.Text = "" Then
            lblMessage.Text = "Entry Date, Date From, Date Thru, and Allocation are Required."
            Exit Sub
        End If
        
        Dim nDiff As Integer = DateDiff("d", txtFrom.SelectedDate, txtThru.SelectedDate)
        
        If nDiff < 0 Then
            lblMessage.Text = "From Date must be earlier than Thru Date."
              
        Else
            
            Using db As New PromptDataHelper

                Dim nPercent As Double = txtAllocationPercent.Value
                Dim nTotalAllocation As Double = 0
                Dim dEntryDate As Date = txtEntryDate.SelectedDate
                Dim sDescription As String = txtDescription.Text
                Dim sObjectCode As String = lstObjectCode.SelectedValue
                Dim dFrom As Date = txtFrom.SelectedDate
                Dim dThru As Date = txtThru.SelectedDate
                Dim sBondSeries As String = lstBondSeries.SelectedValue
                Dim sJCAFCellName As String = lstJCAFSource.SelectedValue

                'go through each project and get amounts total amount
                Dim sTargetProjects As String = ""
                For Each item As RadListBoxItem In lstProjects.Items
                    If item.Checked = True Then
                        sTargetProjects &= item.Value & ","
                    End If
                Next

                'Create a placeholder parent entry so that we have parent key
                Dim sql As String = "INSERT INTO PassthroughEntries (ProjectID) VALUES (" & nProjectID & ") ;SELECT NewKey = Scope_Identity()"  'return the new primary key"
                Dim nNewParentPassthroughID As Integer = db.ExecuteScalar(sql)

                Dim nTargetTotal As Double = 0
                Dim nRows As Integer = 0
                Dim sAction As String = ""
                Dim sParentProjectName As String = db.ExecuteScalar("SELECT ProjectName + '(' + ProjectNumber + ')' FROM Projects WHERE ProjectID = " & nProjectID)
 
                Dim row As DataRow
                db.FillDataTableForUpdate("SELECT * FROM PassThroughEntries WHERE PassThroughEntryID = 0")   'fill passthrough table

                Dim aProjList() As String = sTargetProjects.Split(",")
                For Each sID As String In aProjList     'create child entries
                    If sID <> "" Then
                        sql = "SELECT ISNULL(SUM(TotalAmount), 0) AS Total FROM Transactions "
                        sql &= "WHERE DatePaid BETWEEN '" & dFrom & "' AND '" & dThru & "' AND "
                        sql &= "(Status = 'Paid' AND (TransType='Invoice' OR TransType='Credit') "
                        sql &= " AND ProjectID = " & sID & ")"

                        nTargetTotal = db.ExecuteScalar(sql)

                        If nTargetTotal <> 0 Then    'NOTE: We can allocate both positive expenses and negative credits to the overhead 
                            
                            Dim nAllocationAmount As Double = ProcLib.Round(nTargetTotal * (nPercent / 100), 2)
                            nTotalAllocation += nAllocationAmount

                            Dim sTargetProjectName As String = db.ExecuteScalar("SELECT ProjectName + '(' + ProjectNumber + ')' FROM Projects WHERE ProjectID = " & sID)
                            sAction = "Allocated " & nPercent & " % of " & FormatCurrency(nTargetTotal) & " total expenses "
                            sAction &= "to Object Code " & sObjectCode & " (from " & sParentProjectName & " to " & sTargetProjectName & ") "
                            sAction &= " for period " & FormatDateTime(dFrom, DateFormat.ShortDate) & " - " & FormatDateTime(dThru, DateFormat.ShortDate)

                            'Create TargetEntry
                            row = db.DataTable.NewRow
                            row("ProjectID") = sID
                            
                            row("ParentPassthroughEntryID") = nNewParentPassthroughID
                            row("PassthroughProjectID") = nProjectID
                            row("DistrictID") = HttpContext.Current.Session("DistrictID")
                            row("CollegeID") = HttpContext.Current.Session("CollegeID")
                            row("EntryDate") = dEntryDate
                            row("Description") = sDescription
                            row("ObjectCode") = sObjectCode
                            row("BondSeriesNumber") = sBondSeries
                            row("FiscalYear") = lstFiscalYear.SelectedValue
                            row("Amount") = nAllocationAmount
                            row("Action") = sAction
                            row("LastUpdateOn") = Now()
                            row("LastUpdateBy") = HttpContext.Current.Session("UserName")
                            row("AllocationFrom") = dFrom
                            row("AllocationThru") = dThru
                            row("JCAFCellName") = sJCAFCellName

                            db.DataTable.Rows.Add(row)
                            nRows += 1

                        End If
                    End If
                Next
                If nRows > 0 Then
                    db.SaveDataTableToDB()
                

                    'get new parent
                    db.FillDataTableForUpdate("SELECT * FROM PassThroughEntries WHERE PassThroughEntryID = " & nNewParentPassthroughID)   'fill passthrough table
                    row = db.DataTable.Rows(0)

                    sAction = "Allocated " & nPercent & " % of each target project expenses "
                    sAction &= "to Object Code " & sObjectCode & " for period " & FormatDateTime(dFrom, DateFormat.ShortDate) & " - " & FormatDateTime(dThru, DateFormat.ShortDate)

                    'Create Parent
                    row("ProjectID") = nProjectID
                
                    row("ParentPassthroughEntryID") = nNewParentPassthroughID
                    row("PassthroughProjectID") = nProjectID
                    row("DistrictID") = HttpContext.Current.Session("DistrictID")
                    row("CollegeID") = HttpContext.Current.Session("CollegeID")
                    row("EntryDate") = dEntryDate
                    row("Description") = sDescription
                    row("ObjectCode") = sObjectCode
                    row("BondSeriesNumber") = sBondSeries
                    row("FiscalYear") = lstFiscalYear.SelectedValue
                    row("Amount") = nTotalAllocation * -1   'make negative
                    row("Action") = sAction
                    row("LastUpdateOn") = Now()
                    row("LastUpdateBy") = HttpContext.Current.Session("UserName")
                    row("AllocationFrom") = dFrom
                    row("AllocationThru") = dThru
                    row("JCAFCellName") = sJCAFCellName

                    db.SaveDataTableToDB()
                
                    Session("RtnFromEdit") = True
                    ProcLib.CloseAndRefreshRAD(Page)
                Else
                    'There were no allocations so simply remove parent
                    db.ExecuteNonQuery("DELETE FROM PassThroughEntries WHERE PassThroughEntryID = " & nNewParentPassthroughID)
                    lblMessage.Text = "No Transactions in Target Projects for the Date Range Specified were found."
                
                End If
            End Using

            

        End If

    End Sub


    Protected Sub chkCheckAll_CheckedChanged(ByVal sender As Object, ByVal e As System.EventArgs) Handles chkCheckAll.CheckedChanged
        If chkCheckAll.Checked Then
            For Each item As RadListBoxItem In lstProjects.Items
                item.Checked = True
            Next
        Else
            For Each item As RadListBoxItem In lstProjects.Items
                item.Checked = False
            Next
        End If
        
        
    End Sub

    Protected Sub lstProjectCategory_SelectedIndexChanged(ByVal sender As Object, ByVal e As System.EventArgs) Handles lstProjectCategory.SelectedIndexChanged
        FillProjectsList()
    End Sub
    
    Protected Sub lstJCAFSource_SelectedIndexChanged(ByVal sender As Object, ByVal e As System.EventArgs) Handles lstJCAFSource.SelectedIndexChanged
        FillProjectsList()
    End Sub

    Protected Sub lstObjectCode_SelectedIndexChanged(ByVal sender As Object, ByVal e As System.EventArgs) Handles lstObjectCode.SelectedIndexChanged
        FillProjectsList()
    End Sub
</script>

<html>
<head>
    <title>Add Passthrough Allocation</title>
    <link href="Styles.css" type="text/css" rel="stylesheet" />

    <script type="text/javascript" language="javascript">


        function GetRadWindow() {
            var oWindow = null;
            if (window.radWindow) oWindow = window.radWindow; //Will work in Moz in all cases, including clasic dialog
            else if (window.frameElement.radWindow) oWindow = window.frameElement.radWindow; //IE (and Moz az well)

            return oWindow;
        }

 	   
    </script>

</head>
<body>
    <form id="Form1" method="post" runat="server">
    <telerik:RadScriptManager ID="RadScriptManager1" runat="server" />
    <asp:Label ID="Label11" runat="server" Style="z-index: 102; left: 12px; position: absolute;
        top: 75px; right: 1037px; width: 215px; height: 12px;">Include Paid Transactions From:</asp:Label>
    <asp:Label ID="Label15" runat="server" Style="z-index: 102; left: 11px; position: absolute;
        top: 139px; right: 1530px;">ObjectCode:</asp:Label>
    <asp:Label ID="Label14" runat="server" Style="z-index: 102; left: 11px; position: absolute;
        top: 168px; right: 1492px; width: 104px;">JCAF Source:</asp:Label>
    <asp:Label ID="Label17" runat="server" Style="z-index: 102; left: 16px; position: absolute;
        top: 197px; right: 1482px; width: 109px; height: 20px;">Project Category:</asp:Label>
    <asp:Label ID="Label16" runat="server" Style="z-index: 102; left: 250px; position: absolute;
        top: 168px; right: 1248px; width: 109px; height: 20px;">Fiscal Year:</asp:Label>
    <asp:Label ID="Label10" runat="server" Style="z-index: 102; left: 126px; position: absolute;
        top: 234px; right: 1101px; width: 380px; height: 20px;">(Note: Items Colored Red do not have enough $$ in JCAF Cell)</asp:Label>
    <asp:Label ID="Label13" runat="server" Style="z-index: 102; left: 11px; position: absolute;
        top: 109px">Allocation %:</asp:Label>
    <asp:Label ID="Label12" runat="server" Style="z-index: 102; left: 321px; position: absolute;
        top: 78px">Thru:</asp:Label>
    <asp:Label ID="Label9" runat="server" Style="z-index: 102; left: 212px; position: absolute;
        top: 13px">Bond Series:</asp:Label>
    <asp:HyperLink ID="butHelp" runat="server" ImageUrl="images/button_help.gif" Style="z-index: 113;
        left: 464px; position: absolute; top: 10px">help</asp:HyperLink>
    <telerik:RadDatePicker runat="server" Style="z-index: 20; left: 359px; position: absolute;
        top: 75px" ID="txtThru" Width="120px">
        <DateInput runat="server" Skin="Vista" Font-Size="13px" ForeColor="Blue">
        </DateInput>
    </telerik:RadDatePicker>
    <telerik:RadDatePicker runat="server" Style="z-index: 20; left: 193px; position: absolute;
        top: 74px" ID="txtFrom" Width="120px">
        <DateInput runat="server" Skin="Vista" Font-Size="13px" ForeColor="Blue">
        </DateInput>
    </telerik:RadDatePicker>
    <telerik:RadDatePicker runat="server" Style="z-index: 20; left: 52px; position: absolute;
        top: 10px" ID="txtEntryDate" runat="server" Width="120px">
        <DateInput runat="server" Skin="Vista" Font-Size="13px" ForeColor="Blue">
        </DateInput>
    </telerik:RadDatePicker>
    <asp:ImageButton ID="butDelete" Style="z-index: 107; left: 206px; position: absolute;
        top: 433px" TabIndex="6" runat="server" ImageUrl="images/button_delete.gif">
    </asp:ImageButton>
    <asp:TextBox ID="txtDescription" runat="server" CssClass="EditDataDisplay" Style="z-index: 111;
        left: 85px; position: absolute; top: 41px" TabIndex="40" Width="356px"></asp:TextBox>
    <asp:Label ID="Label1" Style="z-index: 100; left: 11px; position: absolute; top: 12px;
        height: 1px;" runat="server">Date:</asp:Label>
    <telerik:RadNumericTextBox Label="  " ID="txtAllocationPercent" runat="server" Style="z-index: 112;
        left: 89px; position: absolute; top: 107px; width: 40px;" SelectionOnFocus="SelectAll"
        MinValue="0" TabIndex="15" AutoPostBack="False" ToolTip="Percent of Target Project activity to take from passthrough.">
        <NumberFormat AllowRounding="False" />
    </telerik:RadNumericTextBox>
    <telerik:RadListBox ID="lstProjects" runat="server" Style="z-index: 1; left: 13px;
        top: 256px; position: absolute;" CheckBoxes="True" BorderStyle="Solid" BorderWidth="1px"
        Height="150px" Width="500px">
        <ButtonSettings TransferButtons="All"></ButtonSettings>
        <Items>
            <telerik:RadListBoxItem runat="server" Text="RadListBoxItem1" />
            <telerik:RadListBoxItem runat="server" Text="RadListBoxItem2" />
            <telerik:RadListBoxItem runat="server" Text="RadListBoxItem3" />
            <telerik:RadListBoxItem runat="server" Text="RadListBoxItem4" />
        </Items>
    </telerik:RadListBox>
    <asp:CheckBox ID="chkCheckAll" runat="server" Style="z-index: 1; left: 18px; top: 231px;
        position: absolute;" AutoPostBack="True" Text="Check All" OnCheckedChanged="chkCheckAll_CheckedChanged" />
    <asp:Label ID="lblID" runat="server" CssClass="ViewDataDisplay" Style="z-index: 109;
        left: 388px; position: absolute; top: 435px; height: 18px;">###</asp:Label>
    <asp:Label ID="lblMessage" runat="server" ForeColor="Red" Style="z-index: 115;
        left: 15px; position: absolute; top: 413px; height: 8px;" Width="422px"></asp:Label>
    <asp:DropDownList ID="lstFiscalYear" runat="server" Style="z-index: 115; left: 320px;
        position: absolute; top: 164px;" OnSelectedIndexChanged="lstProjectCategory_SelectedIndexChanged"
        AutoPostBack="True">
    </asp:DropDownList>
    <asp:DropDownList ID="lstProjectCategory" runat="server" Style="z-index: 115; left: 121px;
        position: absolute; top: 196px;" OnSelectedIndexChanged="lstProjectCategory_SelectedIndexChanged"
        AutoPostBack="True">
    </asp:DropDownList>
    <asp:Label ID="Label3" runat="server" Style="z-index: 102; left: 141px; position: absolute;
        top: 109px">(Percentage of Target Project Activity to debit from Parent)</asp:Label>
    <asp:DropDownList ID="lstJCAFSource" runat="server" Style="z-index: 115; left: 90px;
        position: absolute; top: 167px; right: 1057px;" 
        OnSelectedIndexChanged="lstJCAFSource_SelectedIndexChanged" AutoPostBack="True">
    </asp:DropDownList>
    <asp:DropDownList ID="lstObjectCode" runat="server" Style="z-index: 115; left: 91px;
        position: absolute; top: 137px;" 
        OnSelectedIndexChanged="lstObjectCode_SelectedIndexChanged" AutoPostBack="True">
    </asp:DropDownList>
    <asp:ImageButton ID="butSave" Style="z-index: 106; left: 14px; position: absolute;
        top: 433px" TabIndex="5" runat="server" ImageUrl="images/button_save.gif"></asp:ImageButton>
    <asp:DropDownList ID="lstBondSeries" runat="server" Style="z-index: 115; left: 289px;
        position: absolute; top: 10px; right: 895px;">
    </asp:DropDownList>
    <asp:Label ID="Label4" runat="server" Style="z-index: 103; left: 8px; position: absolute;
        top: 41px">Description:</asp:Label>
    <telerik:RadAjaxManager ID="RadAjaxManager1" runat="server">
        <AjaxSettings>
            <telerik:AjaxSetting AjaxControlID="chkCheckAll">
                <UpdatedControls>
                    <telerik:AjaxUpdatedControl ControlID="lstProjects" />
                </UpdatedControls>
            </telerik:AjaxSetting>
            <telerik:AjaxSetting AjaxControlID="lstProjectCategory">
                <UpdatedControls>
                    <telerik:AjaxUpdatedControl ControlID="lstProjects" />
                </UpdatedControls>
            </telerik:AjaxSetting>
            <telerik:AjaxSetting AjaxControlID="lstObjectCode">
                <UpdatedControls>
                    <telerik:AjaxUpdatedControl ControlID="lstProjects" />
                </UpdatedControls>
            </telerik:AjaxSetting>
            <telerik:AjaxSetting AjaxControlID="lstJCAFSource">
                <UpdatedControls>
                    <telerik:AjaxUpdatedControl ControlID="lstProjects" />
                </UpdatedControls>
            </telerik:AjaxSetting>
        </AjaxSettings>
    </telerik:RadAjaxManager>
    <asp:Label ID="Label2" runat="server" CssClass="smalltext" Height="16px" Style="z-index: 108;
        left: 360px; position: absolute; top: 434px; width: 13px;">ID:</asp:Label>
    </form>
</body>
</html>
