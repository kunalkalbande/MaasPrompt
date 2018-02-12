<%@ Page Language="vb" %>

<%@ Register Assembly="Telerik.Web.UI" Namespace="Telerik.Web.UI" TagPrefix="telerik" %>
<%@ Import Namespace="Prompt" %>

<script runat="server">  
    
    Private JCAFColumnName As String = ""
    Private ObjectCode As String = ""
    Private ProjectID As Integer = 0
    Private CollegeID As Integer = 0
 
    Private Sub Page_Load(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MyBase.Load

        JCAFColumnName = Request.QueryString("FieldName")
        ProjectID = Request.QueryString("ProjectID")
        CollegeID = Request.QueryString("CollegeID")
 
        lblMessage.Text = ""

        ProcLib.LoadPopupJscript(Page)
        Session("PageID") = "BudgetItemTransfer"
        Page.Header.Title = "Transfer Budget Amount"

        If Not IsPostBack Then
            
            Dim sql As String = ""
            Using db As New PromptDataHelper
                
                'Load transfer from combo
                sql = "SELECT *, TotalAmount - EncumberedAmount AS AvailableAmount FROM qry_GetJCAFObjectCodeBudgetAmounts "
                sql &= "WHERE ProjectID = " & ProjectID & " AND JCAFColumnName = '" & JCAFColumnName & "' AND "
                sql &= "TotalAmount - EncumberedAmount > 0 "
                sql &= "ORDER BY ObjectCode"
                Dim tbl As DataTable = db.ExecuteDataTable(sql)

                Dim item As New RadComboBoxItem
                item.Text = "-- Please Select --"
                item.Value = "-none-"
                lstTransferFrom.Items.Add(item)
            
                With lstTransferFrom
                    .DataValueField = "ObjectCode"
                    .DataTextField = "Description"
                    .DataSource = tbl
                    .DataBind()
                End With
                
                'Load transfer to projects 
                sql = "SELECT Projects.*, Colleges.College as College FROM Projects INNER JOIN Colleges ON Projects.CollegeID = Colleges.CollegeID "
                sql &= "WHERE Projects.DistrictID = " & Session("DistrictID") & " "
                If Session("DistrictID") = 56 Then  'HACK
                    sql &= "ORDER BY College, ProjectName "
                Else
                    sql &= "ORDER BY College, ProjectNumber, ProjectName "
                End If
                
                tbl = db.ExecuteDataTable(sql)

                item = New RadComboBoxItem
                item.Text = "-- Please Select --"
                item.Value = "-none-"
                lstTransferToProject.Items.Add(item)
                Dim sLastCollege As String = ""
                
                For Each row As DataRow In tbl.Rows
                    If sLastCollege <> row("College") Then
                        sLastCollege = row("College")
                        item = New RadComboBoxItem
                        item.Text = sLastCollege
                        item.Value = "-none-"
                        item.IsSeparator = True
                        lstTransferToProject.Items.Add(item)
                        
                    End If
                    item = New RadComboBoxItem
                    If Session("DistrictID") = 56 Then  'HACK
                        item.Text = row("ProjectName")
                    Else
                        item.Text = row("ProjectNumber") & " - " & row("ProjectName")
                    End If
                   
                    item.Value = row("ProjectID")
                    item.Attributes.Add("CollegeID", row("CollegeID"))
                    lstTransferToProject.Items.Add(item)
                Next
                
                'Load transfer to funding source
                sql = "SELECT DISTINCT PMFundingSource,PMFundingSource AS OrigFundingSource FROM BudgetFieldsTable "
                sql &= "WHERE PMFundingSource <> 'DistrictNonStateSup' AND PMFundingSource <> 'SiteAquisition' AND PMFundingSource <> 'District'"
                sql &= "ORDER BY PMFundingSource "
                tbl = db.ExecuteDataTable(sql)

                'Get the custom JCAF column name if any
                Dim tblHeaders As DataTable = db.ExecuteDataTable("SELECT * FROM Districts WHERE DistrictID = " & HttpContext.Current.Session("DistrictID"))
                For Each row As DataRow In tblHeaders.Rows
                    If Not IsDBNull(row("JCAFDonationColumnName")) Then
                        If row("JCAFDonationColumnName") <> "" Then
                            For Each rowsource As DataRow In tbl.Rows
                                If rowsource("PMFundingSource") = "Donation" Then
                                    rowsource("PMFundingSource") = row("JCAFDonationColumnName")
                                End If
                            Next
                        End If
                    End If
                    
                    If Not IsDBNull(row("JCAFGrantColumnName")) Then
                        If row("JCAFGrantColumnName") <> "" Then
                            For Each rowsource As DataRow In tbl.Rows
                                If rowsource("PMFundingSource") = "Grant" Then
                                    rowsource("PMFundingSource") = row("JCAFGrantColumnName")
                                End If
                            Next
                        End If
                    End If
                    If Not IsDBNull(row("JCAFHazmatColumnName")) Then
                        If row("JCAFHazmatColumnName") <> "" Then
                            For Each rowsource As DataRow In tbl.Rows
                                If rowsource("PMFundingSource") = "Hazmat" Then
                                    rowsource("PMFundingSource") = row("JCAFHazmatColumnName")
                                End If
                            Next
                        End If
                    End If
                    If Not IsDBNull(row("JCAFMaintColumnName")) Then
                        If row("JCAFMaintColumnName") <> "" Then
                            For Each rowsource As DataRow In tbl.Rows
                                If rowsource("PMFundingSource") = "Maint" Then
                                    rowsource("PMFundingSource") = row("JCAFMaintColumnName")
                                End If
                            Next
                        End If
                    End If
                    
       
                Next
                item = New RadComboBoxItem
                item.Text = "-- Please Select --"
                item.Value = "-none-"
                lstTargetFundingSource.Items.Add(item)
                                
                For Each row As DataRow In tbl.Rows
                    item = New RadComboBoxItem
                    item.Text = row("PMFundingSource")
                    item.Value = row("OrigFundingSource")
                    lstTargetFundingSource.Items.Add(item)
                Next
                
                
                ''Load transfer to Object Codes
                sql = "SELECT * FROM ObjectCodes WHERE DistrictID = " & Session("DistrictID") & "  "
                sql &= "ORDER BY ObjectCode "

                tbl = db.ExecuteDataTable(sql)

                item = New RadComboBoxItem
                item.Text = "-- Please Select --"
                item.Value = "-none-"
                lstTargetObjectCode.Items.Add(item)

                For Each row As DataRow In tbl.Rows
                    item = New RadComboBoxItem
                    item.Text = row("ObjectCode") & " - " & row("ObjectCodeDescription")
                    item.Value = row("ObjectCode")
                    lstTargetObjectCode.Items.Add(item)
                Next
                
                
                  
            End Using
            
            
            BuildMenu()
            
        End If
    End Sub
        
    Private Sub BuildMenu()
        
        Dim bReadOnly As Boolean
        
        If Not IsPostBack Then          'Configure Tool Bar
            
            'get security setting
            Using db As New EISSecurity
                db.CollegeID = Session("CollegeID")
                db.ProjectID = ProjectID
                If db.FindUserPermission("JCAFBudget", "Write") = False Then
                    bReadOnly = True
                End If
            End Using
            
            With RadMenu1
                .EnableEmbeddedSkins = True
                .Skin = "Vista"
                .Width = Unit.Percentage(100)
                .EnableOverlay = False
  
                .CollapseAnimation.Duration = "200"
                .CollapseAnimation.Type = AnimationType.InOutBounce
                .ExpandAnimation.Duration = "200"
                .ExpandAnimation.Type = AnimationType.InOutBounce
            End With
            
                 
            'build buttons
            Dim but As RadMenuItem
                
            'If bReadOnly = False Then
            '    but = New RadMenuItem
            '    With but
            '        .Text = "Save"
            '        .Value = "Save"
            '        .ImageUrl = "images/prompt_savetodisk.gif"
            '    End With
            '    RadMenu1.Items.Add(but)
            'End If
                        
            but = New Telerik.Web.UI.RadMenuItem
            With but
                .Text = "Cancel"
                .Value = "Exit"
                .ImageUrl = "images/exit.png"
                .PostBack = True
            End With
            RadMenu1.Items.Add(but)

            but = New RadMenuItem
            but.IsSeparator = True
            but.Width = Unit.Pixel(300)
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
    
    Private Sub LoadJCAFTargetLines()
        'Load transfer to JCAF Lines
        lstTargetJCAFLine.Text = ""
        lstTargetJCAFLine.SelectedValue = ""
        lstTargetJCAFLine.Items.Clear()
        
        Using db As New PromptDataHelper
            Dim sql As String = "SELECT * FROM BudgetFieldsTable WHERE Source IS NOT NULL AND PMFundingSource = '" & lstTargetFundingSource.SelectedValue & "' "
            sql &= "ORDER BY PMGroupDisplayOrder   "
            Dim tbl As DataTable = db.ExecuteDataTable(sql)

            Dim item As New RadComboBoxItem
            item.Text = "-- Please Select --"
            item.Value = "-none-"
            lstTargetJCAFLine.Items.Add(item)
                                
            For Each row As DataRow In tbl.Rows
                item = New RadComboBoxItem
                
                'Clean up target JCAF line descriptions
                Dim sDescr As String = ""
                If row("JCAFSection") = row("JCAFLine") Or InStr(row("JCAFSection"), "Furniture/Group II") > 0 Then
                    sDescr = row("JCAFLine")
                Else
                    sDescr = row("JCAFSection") & " - " & row("JCAFLine")
                End If
                item.Text = sDescr
                item.Value = row("JCAFCellName")
                lstTargetJCAFLine.Items.Add(item)
            Next
        
        End Using
        
    End Sub
    
    
    Protected Sub RadMenu1_ItemClick(ByVal sender As Object, ByVal e As Telerik.Web.UI.RadMenuEventArgs) Handles RadMenu1.ItemClick
       
        Dim btn As RadMenuItem = e.Item
        
        Select Case btn.Value
            
            Case "Exit"
                
                Response.Redirect("budget_items.aspx?CollegeID=" & CollegeID & "&ProjectID=" & ProjectID & "&FieldName=" & JCAFColumnName)

        End Select
        
    End Sub
    
    
    Protected Sub lstTransferFrom_ItemDataBound(ByVal sender As Object, ByVal e As RadComboBoxItemEventArgs) Handles lstTransferFrom.ItemDataBound
        'add the amount as an attribute to the items
        Dim dataItem As DataRowView = CType(e.Item.DataItem, DataRowView)
        e.Item.Attributes("AvailableAmount") = dataItem("AvailableAmount")
    End Sub
    
    Protected Sub lstTransferFrom_SelectedIndexChanged(ByVal sender As Object, ByVal e As Telerik.Web.UI.RadComboBoxSelectedIndexChangedEventArgs) Handles lstTransferFrom.SelectedIndexChanged

        Dim sVal As Double = lstTransferFrom.SelectedItem.Attributes("AvailableAmount")
        lblMaxAmt.Text = "Maximum Amt:   <b>" & FormatCurrency(sVal) & "<b/>"
        hfMaximumAmount.Value = sVal
        txtAmount.Value = sVal
        
    End Sub

    Protected Sub lstTargetFundingSource_SelectedIndexChanged(ByVal sender As Object, ByVal e As Telerik.Web.UI.RadComboBoxSelectedIndexChangedEventArgs) Handles lstTargetFundingSource.SelectedIndexChanged
        'load the target buckets based on funding source as each is unique
        LoadJCAFTargetLines()
    
    End Sub
    
    Protected Sub butTransfer_Click(ByVal sender As Object, ByVal e As System.EventArgs)
        
        If Not IsDate(txtItemDate.SelectedDate) Or lstTransferFrom.SelectedValue = "-none-" Or lstTargetFundingSource.SelectedValue = "-none-" _
        Or lstTargetObjectCode.SelectedValue = "-none-" Or lstTargetJCAFLine.SelectedValue = "-none-" Or lstTransferToProject.SelectedValue = "-none-" _
        Or txtAmount.Value = 0 Then
            lblMessage.Text = "Please make sure you have entered a valid data in every field (except Notes)."
        
        Else

            'Valid Entries so Transfer
            
            Using db As New PromptDataHelper

                Dim sql As String = ""
                Dim sNotes As String = ""
                Dim sFromProjectName As String = db.ExecuteScalar("SELECT ProjectName FROM Projects WHERE ProjectID = " & ProjectID)
                               
                sql = "SELECT * FROM BudgetObjectCodes WHERE PrimaryKey = 0 "
                db.FillDataTableForUpdate(sql)
                Dim newrow As DataRow = db.DataTable.NewRow
                
                'Create new FROM record
                newrow("DistrictID") = Session("DistrictID")
                newrow("CollegeID") = CollegeID
                newrow("ProjectID") = ProjectID
                newrow("ObjectCode") = lstTransferFrom.SelectedValue
                newrow("Description") = lstTransferFrom.SelectedItem.Text
                newrow("JCAFColumnName") = JCAFColumnName
                newrow("Amount") = txtAmount.Value * -1
                newrow("ItemDate") = txtItemDate.SelectedDate
                
                sNotes = txtNotes.Text & vbCrLf & "-- Transferred To Project: " & lstTransferToProject.Text & " " & vbCrLf
                sNotes &= "JCAF Line: " & lstTargetJCAFLine.SelectedItem.Text & " " & vbCrLf
                sNotes &= "Object Code: " & lstTargetObjectCode.SelectedValue & " -- "
                newrow("Notes") = sNotes
                
                newrow("LedgerAccountID") = 0
                newrow("LastUpdateBy") = Session("UserName")
                newrow("LastUpdateOn") = Now()
                
                db.DataTable.Rows.Add(newrow)
                newrow = db.DataTable.NewRow
                
                'Create new TO record
                newrow("DistrictID") = Session("DistrictID")
                newrow("CollegeID") = lstTransferToProject.SelectedItem.Attributes("CollegeID")
                newrow("ProjectID") = lstTransferToProject.SelectedValue
                newrow("ObjectCode") = lstTargetObjectCode.SelectedValue
                newrow("Description") = lstTargetObjectCode.SelectedItem.Text
                newrow("JCAFColumnName") = lstTargetJCAFLine.SelectedValue
                newrow("Amount") = txtAmount.Value
                newrow("ItemDate") = txtItemDate.SelectedDate
                
                sNotes = txtNotes.Text & vbCrLf & "-- Transferred From Project: " & sFromProjectName & " " & vbCrLf
                sNotes &= "JCAF Line: " & lstTransferFrom.SelectedItem.Text & " " & vbCrLf
                sNotes &= "Object Code: " & lstTransferFrom.SelectedValue & " -- "
                newrow("Notes") = sNotes
                
                newrow("LedgerAccountID") = 0
                newrow("LastUpdateBy") = Session("UserName")
                newrow("LastUpdateOn") = Now()

                db.DataTable.Rows.Add(newrow)
                newrow = db.DataTable.NewRow
  
                db.SaveDataTableToDB()
                
                'LEGACY - Update the parent TO BudgetItem
                'Check to see that there is a BudgetItem already
                Dim nBudgetItemID As Integer = ProcLib.CheckNullNumField(db.ExecuteScalar("SELECT BudgetItemID FROM BudgetItems WHERE BudgetField = '" & lstTargetJCAFLine.SelectedValue & "' AND ProjectID = " & lstTransferToProject.SelectedValue))
                If nBudgetItemID = 0 Then
                    Sql = "INSERT INTO BudgetItems (DistrictID,CollegeID,ProjectID,BudgetField) "
                    sql &= " VALUES(" & Session("DistrictID") & "," & lstTransferToProject.SelectedItem.Attributes("CollegeID") & "," & lstTransferToProject.SelectedValue & ",'" & lstTargetJCAFLine.SelectedValue & "') "
                    Sql &= "SELECT CAST(SCOPE_IDENTITY() AS int) AS ID"
                    nBudgetItemID = db.ExecuteScalar(Sql)
                End If

                sql = "SELECT SUM(Amount) AS Amount FROM BudgetObjectCodes WHERE  JCAFColumnName = '" & lstTargetJCAFLine.SelectedValue & "' AND ProjectID = " & lstTransferToProject.SelectedValue
                Dim nBudgetItemAmount As Double = ProcLib.CheckNullNumField(db.ExecuteScalar(Sql))

                Sql = "UPDATE BudgetItems SET Amount = " & nBudgetItemAmount & ", LastUpdateOn = '" & Now() & "', LastUpdateBy = '" & Session("UserName") & "' "
                sql &= "WHERE BudgetItemID = " & nBudgetItemID
                db.ExecuteNonQuery(Sql)

                'Update the parent FROM BudgetItem
                sql = "SELECT SUM(Amount) AS Amount FROM BudgetObjectCodes WHERE  JCAFColumnName = '" & JCAFColumnName & "' AND ProjectID = " & ProjectID
                nBudgetItemAmount = ProcLib.CheckNullNumField(db.ExecuteScalar(sql))

                sql = "UPDATE BudgetItems SET Amount = " & nBudgetItemAmount & ", LastUpdateOn = '" & Now() & "', LastUpdateBy = '" & Session("UserName") & "' "
                sql &= "WHERE BudgetField = '" & JCAFColumnName & "' AND ProjectID = " & ProjectID
                db.ExecuteNonQuery(sql)
 
            End Using

            Response.Redirect("budget_items.aspx?CollegeID=" & CollegeID & "&ProjectID=" & ProjectID & "&FieldName=" & JCAFColumnName)
        
        End If

    End Sub
</script>

<html>
<head runat="server">
    <title>Transfer Budget Amount</title>
    <link href="Styles.css" type="text/css" rel="stylesheet" />
    <link href="skins/Prompt/Menu.Prompt.css" rel="stylesheet" type="text/css" />
    <style type="text/css">
        .style1
        {
            width: 75px;
        }
    </style>
    <telerik:RadCodeBlock ID="RadCodeBlock1" runat="server">

        <script type="text/javascript" language="javascript">

            function ValidateAmount(sender, eventArgs) {

                var objMaxVal = document.getElementById('hfMaximumAmount');
                var nMaxVal = objMaxVal.value;

                var sCtrlID = sender.get_id();                      // get the current textbox control id
                var sNewVal = eventArgs.get_newValue();             // get the new value
                var sOldVal = eventArgs.get_oldValue();             // get the old value

                //alert(sNewVal);
                //alert(nMaxVal);

                if (sNewVal > nMaxVal) {
                    alert('Sorry, the new amount entered exceeds the available amount to transfer for this object code.');
                    sender.set_value(sOldVal);
                    eventArgs.set_cancel(true);

                    window.setTimeout(function() { sender.focus(); }, 50);
                    return false;
                }

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
    <table width="100%">
        <tr>
            <td class="style1">
                <asp:Label ID="Label6" runat="server" Text="Date:" />
            </td>
            <td colspan="2" valign="center">
                <telerik:RadDatePicker ID="txtItemDate" runat="server" TabIndex="55" Width="120px"
                    SharedCalendarID="sharedCalendar" Skin="Vista">
                    <DateInput ID="DateInput4" runat="server" Skin="Vista" BackColor="#FFFFC0" Font-Size="13px"
                        ForeColor="Blue">
                    </DateInput>
                </telerik:RadDatePicker>
            </td>
        </tr>
        <tr>
            <td class="style1">
                <asp:Label ID="Label4" runat="server" Text="Transfer From:" />
            </td>
            <td colspan="3">
                <telerik:RadComboBox ID="lstTransferFrom" Skin="Windows7" Label="" runat="server"
                    ToolTip="Select the Obect Code amount to transfer." ShowToggleImage="True" ExpandAnimation-Type="None"
                    CollapseAnimation-Type="None" TabIndex="40" DropDownWidth="475px" Width="350px"
                    MaxHeight="175px" AppendDataBoundItems="True" OnSelectedIndexChanged="lstTransferFrom_SelectedIndexChanged"
                    AutoPostBack="True">
                    <CollapseAnimation Type="None"></CollapseAnimation>
                    <HeaderTemplate>
                        <table style="width: 415px; text-align: left">
                            <tr>
                                <td style="width: 125px;">
                                    Description
                                </td>
                                <td align="right" style="width: 125px;">
                                    Available Amount
                                </td>
                            </tr>
                        </table>
                    </HeaderTemplate>
                    <ExpandAnimation Type="None"></ExpandAnimation>
                    <ItemTemplate>
                        <table style="width: 415px; text-align: left">
                            <tr>
                                <td style="width: 125px;">
                                    <%#DataBinder.Eval(Container.DataItem, "Description")%>
                                </td>
                                <td align="right" style="width: 125px;">
                                    <%#FormatCurrency(DataBinder.Eval(Container.DataItem, "AvailableAmount"))%>
                                </td>
                            </tr>
                        </table>
                    </ItemTemplate>
                </telerik:RadComboBox>
            </td>
        </tr>
        <tr>
            <td class="style1">
                <asp:Label ID="Label8" runat="server" Text="Amount:" />
            </td>
            <td>
                <telerik:RadNumericTextBox ID="txtAmount" runat="server" MinValue="0" Width="125px"
                    Type="Currency" NumberFormat-KeepTrailingZerosOnFocus="True" NumberFormat-KeepNotRoundedValue="True"
                    NumberFormat-DecimalDigits="2">
                    <ClientEvents OnValueChanged="ValidateAmount" />
                </telerik:RadNumericTextBox>
            </td>
            <td align="left" colspan="2">
                <asp:Label ID="lblMaxAmt" runat="server" Text="Maximum Amount: <b> $0.00 </b>" />
            </td>
        </tr>
        <tr>
            <td colspan="4">
                &nbsp
            </td>
        </tr>
        <tr>
            <td class="style1">
                <asp:Label ID="Label2" runat="server" Text="Target Project:" />
            </td>
            <td colspan="3">
                <telerik:RadComboBox ID="lstTransferToProject" Skin="Windows7" Label="" runat="server"
                    ToolTip="Select the target Project." ShowToggleImage="True" ExpandAnimation-Type="None"
                    CollapseAnimation-Type="None" TabIndex="40" DropDownWidth="475px" Width="350px"
                    MaxHeight="75px" AppendDataBoundItems="True">
                    <CollapseAnimation Type="None"></CollapseAnimation>
                </telerik:RadComboBox>
            </td>
        </tr>
        <tr>
            <td nowrap="nowrap" class="style1">
                <asp:Label ID="Label5" runat="server" Text="Target Funding Source:" />
            </td>
            <td colspan="3">
                <telerik:RadComboBox ID="lstTargetFundingSource" Skin="Windows7" Label="" runat="server"
                    ToolTip="Select the target JCAF Funding Source." ShowToggleImage="True" ExpandAnimation-Type="None"
                    CollapseAnimation-Type="None" TabIndex="40" DropDownWidth="150px" Width="150px"
                    MaxHeight="75px" AppendDataBoundItems="True" OnSelectedIndexChanged="lstTargetFundingSource_SelectedIndexChanged"
                    AutoPostBack="True">
                    <CollapseAnimation Type="None"></CollapseAnimation>
                </telerik:RadComboBox>
            </td>
        </tr>
        <tr>
            <td class="style1">
                <asp:Label ID="Label1" runat="server" Text="Target JCAF Line:" />
            </td>
            <td colspan="3">
                <telerik:RadComboBox ID="lstTargetJCAFLine" Skin="Windows7" Label="" runat="server"
                    ToolTip="Select the target JCAF Line." ShowToggleImage="True" ExpandAnimation-Type="None"
                    CollapseAnimation-Type="None" TabIndex="40" DropDownWidth="475px" Width="350px"
                    MaxHeight="75px" AppendDataBoundItems="True">
                    <CollapseAnimation Type="None"></CollapseAnimation>
                </telerik:RadComboBox>
            </td>
        </tr>
        <tr>
            <td nowrap="nowrap" class="style1">
                <asp:Label ID="Label3" runat="server" Text="Target Object Code:" />
            </td>
            <td colspan="3">
                <telerik:RadComboBox ID="lstTargetObjectCode" Skin="Windows7" Label="" runat="server"
                    ToolTip="Select the target Object Code." ShowToggleImage="True" ExpandAnimation-Type="None"
                    CollapseAnimation-Type="None" TabIndex="40" DropDownWidth="375px" Width="300px"
                    MaxHeight="125px" AppendDataBoundItems="True">
                    <CollapseAnimation Type="None"></CollapseAnimation>
                </telerik:RadComboBox>
            </td>
        </tr>
        <tr>
            <td class="style1" valign="top">
                <asp:Label ID="Label7" runat="server" Text="Notes:" />
            </td>
            <td colspan="3">
                <asp:TextBox ID="txtNotes" runat="server" TabIndex="1" Width="470px" Height="30px"
                    TextMode="MultiLine" />
            </td>
        </tr>
        <tr>
            <td class="style1" valign="top">
                &nbsp;
            </td>
            <td>
                <asp:Button ID="butTransfer" runat="server" Text="Transfer" OnClick="butTransfer_Click" />
            </td>
            <td colspan="2">
                <asp:Label ID="lblMessage" runat="server" Font-Bold="True" ForeColor="Red" Text="message" />
            </td>
        </tr>
    </table>
    <telerik:RadCalendar ID="sharedCalendar" Skin="Vista" runat="server" EnableMultiSelect="false">
    </telerik:RadCalendar>
    <asp:HiddenField runat="server" ID="hfMaximumAmount" Value="0" />
    <asp:HiddenField runat="server" ID="txtJCAFColumnName" Value="" />
    <telerik:RadAjaxManager ID="RadAjaxManager1" runat="server">
        <AjaxSettings>
            <telerik:AjaxSetting AjaxControlID="lstTransferFrom">
                <UpdatedControls>
                    <telerik:AjaxUpdatedControl ControlID="lblMaxAmt" LoadingPanelID="RadAjaxLoadingPanel1" />
                    <telerik:AjaxUpdatedControl ControlID="hfMaximumAmount" />
                    <telerik:AjaxUpdatedControl ControlID="txtAmount" />
                </UpdatedControls>
            </telerik:AjaxSetting>
            <telerik:AjaxSetting AjaxControlID="lstTargetFundingSource">
                <UpdatedControls>
                    <telerik:AjaxUpdatedControl ControlID="lstTargetJCAFLine" LoadingPanelID="RadAjaxLoadingPanel1" />
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
