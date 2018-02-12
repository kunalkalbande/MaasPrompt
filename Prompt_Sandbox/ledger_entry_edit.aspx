<%@ Page Language="vb" ValidateRequest="false" %>

<%@ Register Assembly="Telerik.Web.UI" Namespace="Telerik.Web.UI" TagPrefix="telerik" %>
<%@ Import Namespace="Prompt" %>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">

<script runat="server">
    
    Public nLedgerEntryID As Integer = 0
    Public nLedgerAccountID As Integer = 0
    Public nCollegeID As Integer = 0    
    Private Sub Page_Load(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MyBase.Load

        ProcLib.CheckSession(Page)
        ProcLib.LoadPopupJscript(Page)

        lblDateRequired.Visible = False
        
        'set up help button
        Session("PageID") = "LedgerEntryEdit"
        butHelp.Attributes.Add("onclick", "openPopup('help_view.aspx','pophelp',550,450,'yes');")
        butHelp.NavigateUrl = "#"


        nLedgerEntryID = Request.QueryString("LedgerEntryID")
        nLedgerAccountID = Request.QueryString("LedgerAccountID")
        nCollegeID = Request.QueryString("CollegeID")
        
        If nLedgerEntryID = 0 Then
            butDelete.Visible = False
        End If
        
        If IsPostBack Then   'only do the following post back
            nLedgerEntryID = lblID.Text
        Else  'only do the following on first load
            Using db As New PromptDataHelper
                
                'Fill the dropdown controls on parent form
                Dim sql As String = ""
 
                sql = "SELECT ProjectID As Val, ProjectNumber + '-' + ProjectName as Lbl FROM dbo.Projects WHERE CollegeID = " & nCollegeID & " ORDER By ProjectNumber + '-' + ProjectName"
                db.FillNewRADComboBox(sql, Form.FindControl("lstProjectID"), True, True, False)

                sql = "SELECT ObjectCode As Val, ObjectCode + '-' + ObjectCodeDescription as Lbl FROM dbo.ObjectCodes WHERE DistrictID = " & Session("DistrictID") & " ORDER By ObjectCode"
                db.FillNewRADComboBox(sql, Form.FindControl("lstObjectCode"), True, False, False)
                
                sql = "SELECT LookupValue As Val, LookupTitle as Lbl FROM dbo.Lookups WHERE DistrictID = " & Session("DistrictID") & " AND ParentTable = 'Transactions' AND ParentField = 'FiscalYear' ORDER By LookupTitle"
                db.FillNewRADComboBox(sql, Form.FindControl("lstFiscalYear"), True, False, False)

                sql = "SELECT LookupValue As Val, LookupTitle as Lbl FROM dbo.Lookups WHERE DistrictID = " & Session("DistrictID") & " AND ParentTable = 'Projects' AND ParentField = 'BondSeriesNumber'  ORDER By LookupTitle"
                db.FillNewRADComboBox(sql, Form.FindControl("lstBondSeries"))


                If nLedgerEntryID > 0 Then
                   
                    db.FillForm(Form, "SELECT * FROM LedgerAccountEntries WHERE LedgerEntryID = " & nLedgerEntryID)
                End If
  
                lblID.Text = nLedgerEntryID
            End Using
        End If
        
        txtEntryDate.Focus()

    End Sub
   

    Private Sub butDelete_Click(ByVal sender As System.Object, ByVal e As System.Web.UI.ImageClickEventArgs) Handles butDelete.Click
        Using db As New PromptDataHelper
            'Check if this entry is associated with JCAF Line
            Dim nEntryAmt As Double = txtAmount.Value
            Dim nJCAFCode As Integer = txtBudgetObjectCodeID.Value
            If nJCAFCode > 0 Then   'need to adjust JCAF
                Dim nJCAFAmount As Double = db.ExecuteScalar("SELECT Amount FROM BudgetObjectCodes WHERE PrimaryKey = " & nJCAFCode)
                If nEntryAmt < nJCAFAmount Then
                    nJCAFAmount = nJCAFAmount - nEntryAmt
                    If nJCAFAmount = 0 Then  'just delete the entry
                        db.ExecuteNonQuery("DELETE FROM WHERE PrimaryKey = " & nJCAFCode)
                    Else 'reduce JCAF amount by this amount
                        db.ExecuteNonQuery("UPDATE BudgetObjectCodes SET Amount = " & nJCAFAmount & " WHERE PrimaryKey = " & nJCAFCode)
                    End If
                End If
            End If

            Dim sql As String = "DELETE FROM LedgerAccountEntries WHERE LedgerEntryID = " & nLedgerEntryID
            db.ExecuteNonQuery(sql)
        End Using
        Session("RtnFromEdit") = True
        ProcLib.CloseAndRefreshRAD(Page)
    End Sub


    Private Sub butSave_Click(ByVal sender As System.Object, ByVal e As System.Web.UI.ImageClickEventArgs) Handles butSave.Click
        If txtEntryDate.SelectedDate Is Nothing Or txtAmount.Text = "" Then
            lblDateRequired.Visible = True
      
        Else
            Using db As New PromptDataHelper
                Dim sql As String = ""
                'Check if this is a new LedgerEntry
                If nLedgerEntryID = 0 Then
                    'Add Master LedgerEntry Record
                    sql = "INSERT INTO LedgerAccountEntries "
                    sql = sql & "(LedgerAccountID,DistrictID,CollegeID) "
                    sql = sql & "VALUES  (" & nLedgerAccountID & "," & Session("DistrictID") & "," & Session("CollegeID") & ") "
                    sql = sql & ";SELECT NewKey = Scope_Identity()"  'return the new primary key

                    nLedgerEntryID = db.ExecuteScalar(sql)

                End If

                'Update the LedgerEntryID label on the form as it will be included in save form
                lblID.Text = nLedgerEntryID

                Dim sDate As Date = txtEntryDate.SelectedDate
                Dim sType As String = ""
                Dim sDescr As String = txtDescription.Text
                Dim nAmt As Double = txtAmount.Value
                Dim sObjectCode As String = lstObjectCode.SelectedValue
                Dim nProjectID As Integer = lstProjectID.SelectedValue
                Dim sFiscalYear As String = lstFiscalYear.SelectedValue
                Dim sSeries As String = lstBondSeries.SelectedValue
                Dim interestIncome As Boolean = Convert.ToBoolean(chkInterestIncomeReceived.Checked)
                

                If sObjectCode = "none" Then
                    sObjectCode = ""
                End If

                If nAmt < 0 Then
                    sType = "Credit"
                Else
                    sType = "Debit"
                End If

                'Update LedgerEntry Record
                sql = "UPDATE LedgerAccountEntries SET "
                sql &= "EntryDate = '" & sDate & "',"
                sql &= "EntryType = '" & sType & "',"
                sql &= "Description = '" & sDescr & "',"
                sql &= "Amount = " & nAmt & ","
                sql &= "ObjectCode = '" & sObjectCode & "',"
                sql &= "FiscalYear = '" & sFiscalYear & "',"
                sql &= "BondSeries = '" & sSeries & "',"
                sql &= "ProjectID = " & nProjectID & ","
                sql &= "LastUpdateOn = '" & Now() & "',"
                sql &= "LastUpdateBy = '" & Session("UserName") & "',"
                sql &= "InterestIncomeReceived = '" & interestIncome & "'"
                sql &= " WHERE LedgerEntryID = " & nLedgerEntryID

                db.ExecuteNonQuery(sql)
 
          
                
            End Using
            Session("RtnFromEdit") = True
            ProcLib.CloseAndRefreshRAD(Page)
        End If

    End Sub


   
</script>

<html>
<head>
    <title>Edit Ledger Entry</title>
    
    <link href="Styles.css" type="text/css" rel="stylesheet">

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
    <asp:Label ID="Label1" Style="z-index: 100; left: 13px; position: absolute; top: 22px; width: 27px;"
        runat="server">Date:</asp:Label>
    <asp:Label ID="Label4" runat="server" Style="z-index: 103; left: 10px; position: absolute;
        top: 95px; height: 28px;">Description:</asp:Label>
    <asp:Label ID="Label6" runat="server" Style="z-index: 104; left: 9px; position: absolute;
        top: 193px">Object Code:</asp:Label>
   
    <asp:Label ID="Label7" runat="server" Style="z-index: 104; left: 17px; position: absolute;
        top: 126px; height: 31px;">Amount:</asp:Label>
   
    <asp:Label ID="Label5" runat="server" Style="z-index: 104; left: 18px; position: absolute;
        top: 163px">Project:</asp:Label>
   
                <asp:HyperLink ID="butHelp" runat="server" 
         style="z-index: 114; left: 361px; position: absolute; top: 14px;" 
         ImageUrl="images/button_help.gif">HyperLink</asp:HyperLink>

    <telerik:RadDatePicker ID="txtEntryDate" runat="server" Style="z-index: 105; left: 88px;
        position: absolute; top: 20px" Width="120px" TabIndex="1" >
<Calendar UseRowHeadersAsSelectors="False" UseColumnHeadersAsSelectors="False" ViewSelectorText="x"></Calendar>

<DatePopupButton ImageUrl="" HoverImageUrl="" TabIndex="1"></DatePopupButton>

        <DateInput Skin="Vista" Font-Size="13px" ForeColor="Blue" TabIndex="1">
        </DateInput>
    </telerik:RadDatePicker>
  
    <asp:ImageButton ID="butSave" Style="z-index: 106; left: 11px; position: absolute;
        top: 259px" TabIndex="80" runat="server" ImageUrl="images/button_save.gif"></asp:ImageButton>
    <asp:ImageButton ID="butDelete" Style="z-index: 107; left: 223px; position: absolute;
        top: 260px" TabIndex="90" runat="server" 
        OnClientClick="return confirm('You have selected to Delete this Ledger Entry!\n\nAre you sure you want to delete this ledger entry?')"
      
         ImageUrl="images/button_delete.gif">
    </asp:ImageButton>
    <asp:Label ID="Label2" runat="server" CssClass="smalltext" Height="16px" Style="z-index: 108;
        left: 340px; position: absolute; top: 262px">ID:</asp:Label>
    <asp:Label ID="lblID" runat="server" CssClass="ViewDataDisplay" Height="16px" Style="z-index: 109;
        left: 369px; position: absolute; top: 263px">###</asp:Label>
    <telerik:RadComboBox ID="lstProjectID" runat="server" CssClass="EditDataDisplay" 
         Style="left: 88px; position: absolute; top: 157px; width: 348px;" TabIndex="60" 
         MaxHeight="150px" Width="175px">
    </telerik:RadComboBox>
    <telerik:RadComboBox ID="lstObjectCode" runat="server" CssClass="EditDataDisplay" Style="left: 89px; position: absolute; top: 190px; width: 291px;" TabIndex="70">
    </telerik:RadComboBox>
    <telerik:RadComboBox ID="lstBondSeries" runat="server" CssClass="EditDataDisplay" Style="left: 317px; position: absolute; top: 59px" TabIndex="5" ZIndex="19000" Width="50px" MaxHeight="150px">
    </telerik:RadComboBox>
    <telerik:RadComboBox ID="lstFiscalYear" runat="server" 
         CssClass="EditDataDisplay" Style="left: 87px; position: absolute; top: 60px" 
         TabIndex="3" MaxHeight="150px" Width="100px">
    </telerik:RadComboBox>
    <asp:TextBox ID="txtDescription" runat="server" CssClass="EditDataDisplay" Style="z-index: 111;
        left: 87px; position: absolute; top: 92px" TabIndex="40" Width="356px"></asp:TextBox>
    &nbsp;
    <telerik:RadNumericTextBox Label="  " ID="txtAmount" runat="server" Style="z-index: 112;
        left: 84px; position: absolute; top: 125px" Width="112px"  
         SelectionOnFocus="SelectAll" MinValue="-1000000000" TabIndex="50"
        AutoPostBack="False" NumberFormat-DecimalDigits="2">
        <NumberFormat AllowRounding="True" DecimalDigits="2" PositivePattern="$ n"></NumberFormat>
    </telerik:RadNumericTextBox>
    &nbsp;
    <asp:HiddenField ID="txtBudgetObjectCodeID" runat="server" />
   
    <asp:Label ID="Label8" runat="server" Style="z-index: 104; left: 243px; position: absolute;
        top: 63px">Bond Series:</asp:Label>
   
    <asp:Label ID="Label9" runat="server" Style="z-index: 104; left: 9px; position: absolute;
        top: 63px">Fiscal Year:</asp:Label>
   
          <asp:CheckBox  ID="chkInterestIncomeReceived" runat="server" 
         EnableViewState="true" Checked="false" Style="z-index: 109;
        left: 23px; position: absolute; top: 228px" 
         Text="Interest Income Received" AutoPostBack="True"/>
   
    <asp:Label ID="lblDateRequired" runat="server" ForeColor="Red" Style="z-index: 115;
        left: 228px; position: absolute; top: 230px; width: 191px;">Date and Amount are Required</asp:Label>
   
    </form>
</body>
</html>
