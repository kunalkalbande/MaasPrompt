<%@ Page Language="vb" %>

<%@ Register Assembly="Telerik.Web.UI" Namespace="Telerik.Web.UI" TagPrefix="telerik" %>
<%@ Import Namespace="Prompt" %>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">

<script runat="server">
         
    Private nContractDetailID As Integer = 0
    Private nContractID As Integer = 0
    Private nProjectID As Integer = 0
    Private nLineItemID As Integer = 0
    
    Dim bReadOnly As Boolean = True
    
    Private Sub Page_Load(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MyBase.Load

        If ProcLib.CheckExpiredSessionForPopup(Page) Then    'session died so close the page - this is to prevent orphaned popups
            ProcLib.CloseAndRefresh(Page)
        End If

        lblMsg.Text = ""

        'set up help button
        Session("PageID") = "ContractDetailEdit"
        butHelp.Attributes("onclick") = "return ShowHelp();"
        butHelp.NavigateUrl = "#"


        nContractDetailID = Request.QueryString("ContractDetailID")
        nContractID = Request.QueryString("ContractID")
        nProjectID = Request.QueryString("ProjectID")

        butFlag.Attributes.Add("onclick", "return ShowFlag(" & nContractDetailID & ");")
        butFlag.NavigateUrl = "#"
        
        lstReferenceNo.Visible = False    'TURN OFF FOR NOW
        
        
        If IsPostBack() Then   'only do the following post back
            nContractDetailID = lblContractDetailID.Text
        Else  'only do the following on first load

            Using db As New ContractChangeOrder
                db.CallingPage = Page

                If nContractDetailID = 0 Then    'load new record for add
                    db.GetNewAmendment(nContractID)   'loads default values to record from parent contract
                    butFlag.Visible = False
                    butDelete.Visible = False
                    
                    txtContractLineItemID.Value = 0
                    
                    txtAccountNumber.Text = db.ParentContract.AccountNumber
                    txtCreateDate.SelectedDate = Now()

                    
                Else
                    'load existing record
                    db.GetExistingAmendment(nContractDetailID)   'loads existing  record

                    LoadLinkedAttachments()

                    'set up attachments button
                    lnkManageAttachments.Attributes("onclick") = "return ManageAttachments('" & nContractDetailID & "','ContractDetail');"
                    lnkManageAttachments.NavigateUrl = "#"
                    
                    nLineItemID = db.ContractLineItemID
                    txtContractLineItemID.Value = nLineItemID
                    
                    txtContractLineItemID.Value = db.ContractLineItemID
                    txtObjectCode.Value = db.ContractLineItemObjectCode
                    txtJCAFCellName.Value = db.ContractLineItemJCAFCellName
                    txxtJCAFLine.Value = db.ContractLineItemJCAFLine
                    txtAccountNumber.Text = db.ContractLineItemAccountNumber
                    chkReimbursable.Checked = db.ContractLineItemReimbursable
                    
                    txtJCAFLine.Text = txxtJCAFLine.Value
                End If
                lblContractDetailID.Text = nContractDetailID
   
            End Using
                        
            'nLineItemID = txtContractLineItemID.Value
            
            
            'Get the contract oc info
           
            Using db As New promptContract
                db.CallingPage = Page
                db.ProjectID = nProjectID

                If nLineItemID > 0 Then
                    lblMinAmount.Value = db.GetTotalExpendedForContractLineItem(nLineItemID)   'store value to hidden field
                    If lblMinAmount.Value > 0 Then
                        butDelete.Visible = False
                    End If
                Else
                    lblMinAmount.Value = 0
                    butDelete.Visible = False
                    txtJCAFLine.Text = ""
                    txtAmount.Value = 0
                End If

                lblMaxAvailableAmt.Value = db.GetMaxOCJCAFCellAmountForContractLineItem(txtAmount.Value, txtObjectCode.Value, txtJCAFCellName.Value, nProjectID) 'store value to hidden field
 
               FillObjectCodeList()

                lstJCAFCellNameObjectCode.BackColor = Color.LightYellow
   
                'Set warning of overspent JCAF if there is a problem (legacy)
                If db.JCAFLineIsOverSpentForThisOC = True Then
                    lblMsg.Text = "WARNING: Budget bucket is over-encumbered for this selected ObjectCode/Budget Line."
                End If
                
            End Using
            
            lblShowAvailable.Text = FormatCurrency(lblMaxAvailableAmt.Value)  'store value to display field
            lblShowExpended.Text = FormatCurrency(lblMinAmount.Value)           'store value to display field
            

            txtAmount.ClientEvents.OnValueChanged = "ValidateAmounts"
            
            
        End If

        With RadPopups
            .Skin = "Windows7"
            .VisibleOnPageLoad = False
            Dim ww As New Telerik.Web.UI.RadWindow
            With ww
                .ID = "ShowHelpWindow"
                .NavigateUrl = ""
                .Title = ""
                .Width = 450
                .Height = 350
                .Top = 100
                .Left = 20
                .Modal = False
                .VisibleStatusbar = True
                .ReloadOnShow = True
                .Behaviors = WindowBehaviors.Close + WindowBehaviors.Resize
            End With
            .Windows.Add(ww)

            ww = New Telerik.Web.UI.RadWindow
            With ww
                .ID = "ShowFlagWindow"
                .NavigateUrl = ""
                .Title = ""
                .Width = 475
                .Height = 250
                .Top = 100
                .Left = 20
                .Modal = False
                .VisibleStatusbar = True
                .ReloadOnShow = True
                .Behaviors = WindowBehaviors.Close + WindowBehaviors.Resize
            End With
            .Windows.Add(ww)

            ww = New Telerik.Web.UI.RadWindow
            With ww
                .ID = "OpenAttachmentWindow"
                .NavigateUrl = ""
                .Title = "Open Attachment"
                .Width = 500
                .Height = 300
                .Top = 100
                .Left = 20
                .Modal = False
                .VisibleStatusbar = True
                .ReloadOnShow = True
                .Behaviors = WindowBehaviors.Close + WindowBehaviors.Resize
            End With
            .Windows.Add(ww)

            ww = New Telerik.Web.UI.RadWindow
            With ww
                .ID = "ManageAttachmentsWindow"
                .NavigateUrl = ""
                .Title = ""
                .Width = 500
                .Height = 450
                .Top = 100
                .Left = 20
                .Modal = False
                .VisibleStatusbar = True
                .ReloadOnShow = True
                .Behaviors = WindowBehaviors.Close + WindowBehaviors.Resize
            End With
            .Windows.Add(ww)


        End With
        
        Using db As New EISSecurity
            db.ProjectID = nProjectID
            If Not db.FindUserPermission("ContractLineItems", "Write") Then
                bReadOnly = True
            Else
                bReadOnly = False
            End If
        End Using

        If bReadOnly = True Then
            butDelete.Visible = False
            Dim c As Control = Me.FindControl("Form1")
            Dim cc As Control
            For Each cc In c.Controls
                If TypeOf cc Is System.Web.UI.WebControls.TextBox Then
                    CType(cc, System.Web.UI.WebControls.TextBox).Enabled = False
                End If
                If TypeOf cc Is DropDownList Then
                    CType(cc, DropDownList).Enabled = False
                End If
                If TypeOf cc Is Telerik.Web.UI.RadDatePicker Then
                    CType(cc, Telerik.Web.UI.RadDatePicker).Enabled = False
                End If
                If TypeOf cc Is Telerik.Web.UI.RadNumericTextBox Then
                    CType(cc, Telerik.Web.UI.RadNumericTextBox).Enabled = False
                End If
                If TypeOf cc Is CheckBox Then
                    CType(cc, CheckBox).Enabled = False
                End If
            Next
            
            butDelete.Visible = False
            lnkManageAttachments.Visible = False
            butSave.ImageUrl = "images/button_close.gif"
            
        End If

        txtCreateDate.Focus()

    End Sub
    
     
   
    Private Sub LoadLinkedAttachments()
               
        'get the linked attachements
        lstAttachments.Items.Clear()
        Using db1 As New promptAttachment
            Dim rs As DataTable = db1.GetLinkedAttachments(nContractDetailID, "ContractDetail")
            If rs.Rows.Count > 0 Then
                For Each Row As DataRow In rs.Rows
                    Dim li As New ListItem
                    li.Text = Row("FileName")
                    li.Value = Row("AttachmentID")
                    li.Attributes("ondblclick") = "return OpenAttachment('" & li.Value & "');"
                    lstAttachments.Items.Add(li)
                Next
            Else '
                lstAttachments.Items.Add("No Attachments Found")
            End If
        End Using
       
    End Sub
    
  
    Private Sub butSave_Click(ByVal sender As System.Object, ByVal e As System.Web.UI.ImageClickEventArgs) Handles butSave.Click
    
        If Not bReadOnly Then  'save transaction
            
            'check for valid date
            If Not IsDate(txtCreateDate.DbSelectedDate) Then
                lblMsg.Text = "Please enter a valid date."
                Exit Sub
            End If
            
            
            
            Using db As New PromptDataHelper
                
                Dim nCollegeID As Integer = db.ExecuteScalar("SELECT CollegeID FROM Projects WHERE ProjectID = " & nProjectID)
 
                Dim sql As String = ""
                Dim nLineID As Integer = 0

                If nContractDetailID = 0 Then  'this is new contract so add new 
                    sql = "Insert Into ContractDetail "
                    sql &= "(DistrictID,ProjectID,ContractID) "
                    sql &= "VALUES ("
                    sql &= Session("DistrictID") & "," & nProjectID & "," & nContractID & ")"
                    sql &= ";SELECT NewKey = Scope_Identity()"  'return the new primary key
                    nContractDetailID = db.ExecuteScalar(sql)

                    'create a contract line item for this CO 
                    sql = "Insert Into ContractLineItems "
                    sql &= "(DistrictID,ProjectID,ContractID,LineType) "
                    sql &= "VALUES ("
                    sql &= Session("DistrictID") & "," & nProjectID & "," & nContractID & ",'ChangeOrder')"
                    sql &= ";SELECT NewKey = Scope_Identity()"  'return the new primary key
                    nLineID = db.ExecuteScalar(sql)

                Else

                    nLineID = db.ExecuteScalar("SELECT LineID FROM ContractLineItems WHERE ContractChangeOrderID = " & nContractDetailID)

                End If

                'Saves the basic amendment fields
                db.SaveForm(Form1, "SELECT * FROM ContractDetail WHERE ContractDetailID = " & nContractDetailID)

                sql = ""

                'Update the rest of the info Directly
                
                Dim nAmount As Double = ProcLib.CheckNullNumField(txtAmount.Value)

                Dim sJCAFCellName As String = txtJCAFCellName.Value
                Dim sObjectCode As String = txtObjectCode.Value
                Dim sJCAFLine As String = txxtJCAFLine.Value
                Dim sLineObjectCodeDescription As String = txtLineObjectCodeDescription.Value

                Dim sAccountNumber As String = txtAccountNumber.Text
                Dim sDescription As String = txtDescription.Text
                Dim sReferenceNo As String = lstReferenceNo.Text
                
                Dim dItemDate As Date = txtCreateDate.SelectedDate


                Dim bReimbursable As Boolean = chkReimbursable.Checked
                Dim nReimbursable As Integer = 0
                If bReimbursable Then
                    nReimbursable = 1
                End If

                'update related transaction detail records with reimb status
                sql = "UPDATE TransactionDetail SET Reimbursable = " & nReimbursable & " WHERE ContractLineItemID = " & nLineID
                db.ExecuteNonQuery(sql)


                db.FillDataTableForUpdate("SELECT * FROM ContractLineItems WHERE LineID = " & nLineID)
                For Each row As DataRow In db.DataTable.Rows   'there will be only one

                    row("ItemDate") = dItemDate
                    row("ObjectCode") = sObjectCode
                    row("JCAFLine") = sJCAFLine
                    row("JCAFCellName") = sJCAFCellName
                    row("JCAFCellNameObjectCode") = sJCAFCellName & "::" & sObjectCode
                    row("LineObjectCodeDescription") = sLineObjectCodeDescription

                    row("CollegeID") = nCollegeID
                    row("ContractChangeOrderID") = nContractDetailID
                    row("Amount") = nAmount
                    row("LineType") = "ChangeOrder"
                    row("ReferenceNo") = sReferenceNo

                    row("AccountNumber") = sAccountNumber

                    row("Description") = sDescription
                    row("Reimbursable") = nReimbursable

                    row("LastUpdateOn") = Now()
                    row("LastUpdateBy") = HttpContext.Current.Session("UserName")
                Next

                db.SaveDataTableToDB()

 
            End Using
        End If
        
        Session("RtnFromEdit") = True
        Session("RtFromContractLineEdit") = True
        
        ProcLib.CloseAndRefresh(Page)
    
    End Sub

    Private Sub butDelete_Click(ByVal sender As System.Object, ByVal e As System.Web.UI.ImageClickEventArgs) Handles butDelete.Click

        Dim sErr As String = ""
        Using db As New ContractChangeOrder
            sErr = db.DeleteChangeOrder(nContractDetailID, txtContractLineItemID.Value)
        End Using
        
        If sErr <> "" Then    'there was a probl
            
            lblMsg.Text = sErr
            
        Else   'ok
            
            Session("RtnFromEdit") = True
            Session("RtFromContractLineEdit") = True
        
            ProcLib.CloseAndRefresh(Page)
            
        End If
 
        'Session("RtnFromEdit") = True

        'Response.Redirect("delete_record.aspx?RecordType=ContractDetail&ID=" & nContractDetailID)
    End Sub
    
      
    Protected Sub AttachmentsPopup_AjaxHiddenButton_Click(ByVal sender As Object, ByVal e As System.EventArgs) Handles AttachmentsPopup_AjaxHiddenButton.Click
        'This is method used to handle the workflow popup close to update the linked attachments list 
        LoadLinkedAttachments()
    End Sub
 
    

    Protected Sub lstDetailType_SelectedIndexChanged(ByVal sender As Object, ByVal e As System.EventArgs)
        FillObjectCodeList()

    End Sub
    
    Private Sub FillObjectCodeList()
        Using db As New promptContract
            Dim sLineType As String = lstDetailType.Text
            
            Dim tree As RadTreeView = DirectCast(lstJCAFCellNameObjectCode.Items(0).FindControl("RadTreeView1"), RadTreeView)
            tree.Nodes.Clear()
            
            If InStr(sLineType, "Adjustment") > 0 Then  'show all JCAF Items
                db.FillLineItemObjectCodeJCAFList(lstJCAFCellNameObjectCode, nProjectID, nLineItemID, True)  'show all lines for adjustments

            Else
                db.FillLineItemObjectCodeJCAFList(lstJCAFCellNameObjectCode, nProjectID, nLineItemID)
            End If
        End Using
    End Sub
    
    
</script>

<html>
<head>
    <title>Edit Change Order</title>
    <link href="Styles.css" type="text/css" rel="stylesheet" />
    <telerik:RadCodeBlock ID="RadCodeBlock1" runat="server">

        <script type="text/javascript" language="javascript">


            var OKCancel = false;

            // this is the actual script for loading the RAD window popup objects from attribute assigned to page elements

            function GetRadWindow() {
                var oWindow = null;
                if (window.radWindow) oWindow = window.radWindow; //Will work in Moz in all cases, including clasic dialog
                else if (window.frameElement.radWindow) oWindow = window.frameElement.radWindow; //IE (and Moz az well)

                return oWindow;
            }

            function ShowHelp()     //for help display
            {

                var oWnd = window.radopen("help_view.aspx?WinType=RAD", "ShowHelpWindow");
                return false;
            }

            function ShowFlag(id)     //for flag display
            {

                var oWnd = window.radopen("flag_edit.aspx?ParentRecID=" + id + "&ParentRecType=ContractDetail&WinType=RAD", "ShowFlagWindow");
                return false;
            }

            function ManageAttachments(id, rectype)     //for managing attachments 
            {

                var oWnd = window.radopen("attachments_manage_linked.aspx?ParentRecID=" + id + "&ParentType=" + rectype, "ManageAttachmentsWindow");
                return false;
            }


            function OpenAttachment(id)     //for opening attachments 
            {

                var oWnd = window.radopen("attachment_get_linked.aspx?ID=" + id, "OpenAttachmentWindow");
                return false;
            }

            //For handling ajax post back from Attachment Manage RAD Popup
            function HandleAjaxPostbackFromAttachmentsPopup() {
                var oButton = document.getElementById("<%=AttachmentsPopup_AjaxHiddenButton.ClientID%>");
                oButton.click();
            }


            function ValidateAmounts(sender, eventArgs) {

                // to fix loop
                if (OKCancel == true) {
                    //alert('here')
                    OKCancel = false;
                    return false;
                }

                // called by contract amount textboxes to validate the entry
                var oldamt = eventArgs.get_oldValue();

                var objMaxAmount = document.getElementById("lblMaxAvailableAmt");
                var nMaxAmt = Math.round((objMaxAmount.value) * 100) / 100;

                var objMinAmount = document.getElementById("lblMinAmount");
                var nMinAmt = objMinAmount.value;

                var nAmount = sender.get_value();
                var nNewTotal = parseFloat(nAmount);

                var sMax = formatCurrency(nMaxAmt);
                var sMin = formatCurrency(nMinAmt);

                if (nNewTotal > 0) {
                    if (nNewTotal < nMinAmt) {
                        alert('Sorry, This Change Order currently has Transactions applied to it than exceed the new amount you are trying to enter. The Amount must be at least ' + sMin);
                        eventArgs.set_cancel(true);
                        window.setTimeout(function() { sender.focus(); }, 50);
                        sender.set_value(oldamt);
                        return false;
                    }
                }

                if (nNewTotal > nMaxAmt) {
                    alert('Sorry, Amount cannot be more than ' + sMax + '. Check that you have assigned a budget Object Code to this Change Order that has a high enough Available Balance');


                    OKCancel = true;
                    //alert('here3');
                    //alert(OKCancel);
                    // alert('here4');

                    eventArgs.set_cancel(true);
                    window.setTimeout(function() { sender.focus(); }, 50);
                    sender.set_value(oldamt);
                    return false;
                }
            }



            //Tree view /Combo template code
            function nodeClicking(sender, args) {
                var comboBox = $find("<%= lstJCAFCellNameObjectCode.ClientID %>");

                var node = args.get_node()
                var nodevalue = node.get_value()

                //check available balance
                var attributes = node.get_attributes();
                var availbal = attributes.getAttribute("AvailableBalance");
                availbal = parseFloat(availbal);

                var ocdescription = attributes.getAttribute("OCDescription");
                var jcafline = attributes.getAttribute("JCAFLine");

                var objMaxAmount = document.getElementById("lblMaxAvailableAmt");
                var nMaxAmt = objMaxAmount.value;
                nMaxAmt = parseFloat(nMaxAmt);


                var objMinAmount = document.getElementById("lblMinAmount");
                var nMinAmt = objMinAmount.value;
                nMinAmt = parseFloat(nMinAmt);

                var sObjectcode = attributes.getAttribute("ObjectCode");

                var objCurrentAmount = $find("txtAmount");
                var nAmount = objCurrentAmount.get_value();
                nAmount = parseFloat(nAmount)
                if (isNaN(nAmount)) {
                    nAmount = 0;
                }


                if (sObjectcode != '--none--') {
                    if (nAmount > availbal) {
                        alert('Sorry, This line item has an amount that is greater than the available balance of the budget Object Code you are trying to select. Please reduce the amount before changing budget OC Line Association');
                        return;
                    }
                }

                if (nodevalue == 'justclose') {
                    return;
                }

                if (nodevalue == 'noselect') {
                    alert('Please select an Object Code entry');
                    return;
                }


                if (sObjectcode == '--none--') {
                    if (nMinAmt > 0) {
                        alert('Sorry, This line item has an expenses associated with it already. You cannot change this ObjectCode designation without reallocating Transactions.');
                        return;
                    }
                }


                // Update the form fields
                document.getElementById("lblShowAvailable").innerHTML = formatCurrency(availbal);
                document.getElementById("txtJCAFLine").innerHTML = jcafline;
                objMaxAmount.value = availbal;

                var sLineObjectCodeDescription = attributes.getAttribute("OCDescription");
                var sJCAFCellName = attributes.getAttribute("JCAFCellName");
                // var sObjectcode = attributes.getAttribute("ObjectCode");


                document.getElementById("txtObjectCode").value = sObjectcode;
                document.getElementById("txtJCAFCellName").value = sJCAFCellName;
                document.getElementById("txtLineObjectCodeDescription").value = sLineObjectCodeDescription;
                document.getElementById("txxtJCAFLine").value = jcafline;

                comboBox.set_text(ocdescription);

                comboBox.hideDropDown();
            }

            function StopPropagation(e) {
                if (!e) {
                    e = window.event;
                }

                e.cancelBubble = true;
            }

            function OnClientDropDownOpenedHandler(sender, eventArgs) {
                var tree = sender.get_items().getItem(0).findControl("RadTreeView1");
                var selectedNode = tree.get_selectedNode();
                if (selectedNode) {
                    selectedNode.scrollIntoView();
                }
            }

            function formatCurrency(strValue) {
                strValue = strValue.toString().replace(/\$|\,/g, '');
                dblValue = parseFloat(strValue);

                blnSign = (dblValue == (dblValue = Math.abs(dblValue)));
                dblValue = Math.floor(dblValue * 100 + 0.50000000001);
                intCents = dblValue % 100;
                strCents = intCents.toString();
                dblValue = Math.floor(dblValue / 100).toString();
                if (intCents < 10)
                    strCents = "0" + strCents;
                for (var i = 0; i < Math.floor((dblValue.length - (1 + i)) / 3); i++)
                    dblValue = dblValue.substring(0, dblValue.length - (4 * i + 3)) + ',' +
		            dblValue.substring(dblValue.length - (4 * i + 3));
                return (((blnSign) ? '' : '-') + '$' + dblValue + '.' + strCents);
            }

        
        
        
        
        
        
        
        
             
        </script>

    </telerik:RadCodeBlock>
</head>
<body>
    <form id="Form1" method="post" runat="server">
    <telerik:RadScriptManager ID="RadScriptManager1" runat="server" />
    <asp:Label ID="Label1" runat="server" CssClass="smalltext" Style="z-index: 142; left: 405px;
        position: absolute; top: 564px;">ID:</asp:Label>
    <asp:Label ID="lblContractDetailID" runat="server" Height="16px" CssClass="ViewDataDisplay"
        Style="z-index: 142; left: 431px; position: absolute; top: 565px;">###</asp:Label>
    <asp:HyperLink ID="butFlag" runat="server" ImageUrl="images/button_flag.gif" Style="z-index: 142;
        left: 423px; position: absolute; top: 11px;" />
    <asp:HyperLink ID="butHelp" runat="server" ImageUrl="images/button_help.gif" Style="z-index: 142;
        left: 484px; position: absolute; top: 11px;" />
    <asp:Label ID="Label7" Style="z-index: 100; left: 21px; position: absolute; top: 403px;
        height: 17px; right: 1471px; width: 115px;" runat="server" CssClass="smalltext">Dist Approve Date:</asp:Label>
    <telerik:RadDatePicker ID="txtBoardApprovalDate" Style="z-index: 101; left: 139px;
        position: absolute; top: 468px" TabIndex="55" runat="server" Skin="Default" SharedCalendarID="SharedCalendar"
        Width="120">
        <DatePopupButton ImageUrl="" HoverImageUrl=""></DatePopupButton>
        <DateInput runat="server" DisplayDateFormat="M/d/yyyy" DateFormat="M/d/yyyy">
        </DateInput>
    </telerik:RadDatePicker>
    <telerik:RadDatePicker ID="txtCompletionDate" Style="z-index: 102; left: 139px; position: absolute;
        top: 434px" TabIndex="50" runat="server" Skin="Default" SharedCalendarID="SharedCalendar"
        Width="120">
        <DatePopupButton ImageUrl="" HoverImageUrl=""></DatePopupButton>
        <DateInput ID="DateInput1" runat="server" DisplayDateFormat="M/d/yyyy" DateFormat="M/d/yyyy">
        </DateInput>
    </telerik:RadDatePicker>
    <telerik:RadDatePicker ID="txtDistrictApprovalDate" Style="z-index: 103; left: 139px;
        position: absolute; top: 399px" TabIndex="45" runat="server" Skin="Default" SharedCalendarID="SharedCalendar"
        Width="120">
        <DatePopupButton ImageUrl="" HoverImageUrl=""></DatePopupButton>
        <DateInput ID="DateInput2" runat="server" DisplayDateFormat="M/d/yyyy" DateFormat="M/d/yyyy">
        </DateInput>
    </telerik:RadDatePicker>
    <telerik:RadDatePicker ID="txtFDOApprovalDate" Style="z-index: 104; left: 139px;
        position: absolute; top: 368px" TabIndex="40" runat="server" Skin="Default" SharedCalendarID="SharedCalendar"
        Width="120">
        <DatePopupButton ImageUrl="" HoverImageUrl=""></DatePopupButton>
        <DateInput ID="DateInput2" runat="server" DisplayDateFormat="M/d/yyyy" DateFormat="M/d/yyyy">
        </DateInput>
    </telerik:RadDatePicker>
    <telerik:RadDatePicker ID="txtArchApprovalDate" Style="z-index: 105; left: 139px;
        position: absolute; top: 337px; height: 24px;" TabIndex="35" runat="server" Skin="Default"
        SharedCalendarID="SharedCalendar" Width="120">
        <DatePopupButton ImageUrl="" HoverImageUrl=""></DatePopupButton>
        <DateInput ID="DateInput3" runat="server" DisplayDateFormat="M/d/yyyy" DateFormat="M/d/yyyy">
        </DateInput>
    </telerik:RadDatePicker>
    <telerik:RadDatePicker ID="txtCreateDate" Style="z-index: 9134; left: 135px; position: absolute;
        top: 11px" runat="server" Skin="Default" SharedCalendarID="SharedCalendar" Width="120">
        <DatePopupButton ImageUrl="" HoverImageUrl=""></DatePopupButton>
        <DateInput ID="DateInput4" runat="server" DisplayDateFormat="M/d/yyyy" DateFormat="M/d/yyyy">
        </DateInput>
    </telerik:RadDatePicker>
    <asp:Label ID="Label8" Style="z-index: 106; left: 309px; position: absolute; top: 222px"
        runat="server" CssClass="smalltext">Increased Contract Days:</asp:Label>
    <asp:TextBox ID="txtIncreasedContractDays" Style="z-index: 107; left: 461px; position: absolute;
        top: 219px" TabIndex="30" runat="server" Width="48px" CssClass="EditDataDisplay"></asp:TextBox>
    <asp:Label ID="Label2" Style="z-index: 108; left: 16px; position: absolute; top: 371px"
        runat="server" Height="16px" CssClass="smalltext">FDO Approve Date:</asp:Label>
    <asp:TextBox ID="txtFundCode" Style="z-index: 109; left: 139px; position: absolute;
        top: 274px" TabIndex="25" runat="server" Width="104px" CssClass="EditDataDisplay"></asp:TextBox>
    <asp:TextBox ID="txtRequestedBy" runat="server" CssClass="EditDataDisplay" Style="z-index: 110;
        left: 139px; position: absolute; top: 304px" TabIndex="29" Width="105px"></asp:TextBox>
    <asp:Label ID="Label24" Style="z-index: 112; left: 309px; position: absolute; top: 67px"
        runat="server" Height="16px" CssClass="smalltext">Acct Number:</asp:Label>
    <%--<asp:Label ID="Label25" Style="z-index: 112; left: 97px; position: absolute; top: 40px"
        runat="server" Height="16px" CssClass="smalltext">Ref:</asp:Label>--%>
    <asp:Label ID="Label3" Style="z-index: 112; left: 60px; position: absolute; top: 67px"
        runat="server" Height="16px" CssClass="smalltext">Entry Type:</asp:Label>
    <asp:Label ID="Label15" runat="server" CssClass="smalltext" Style="z-index: 113;
        left: 57px; position: absolute; top: 248px; height: 17px;">Category:</asp:Label>
    <asp:Label ID="Label4" Style="z-index: 114; left: 89px; position: absolute; top: 13px"
        runat="server" Height="16px" CssClass="smalltext"> Date:</asp:Label>
    <asp:Label ID="Label6" Style="z-index: 115; left: 50px; position: absolute; top: 221px"
        runat="server" Height="16px" CssClass="smalltext">PO Number:</asp:Label>
    <asp:Label ID="Label12" runat="server" CssClass="smalltext" Height="16px" Style="z-index: 116;
        left: 269px; position: absolute; top: 12px">CO#:</asp:Label>
    <asp:Label ID="Label9" Style="z-index: 117; left: 55px; position: absolute; top: 278px"
        runat="server" CssClass="smalltext">Fund Code:</asp:Label>
    <asp:Label ID="Label19" runat="server" CssClass="smalltext" Style="z-index: 118;
        left: 43px; position: absolute; top: 305px">Requested By:</asp:Label>
    <asp:Label ID="Label18" runat="server" CssClass="smalltext" Height="24px" Style="z-index: 119;
        left: 295px; position: absolute; top: 396px" Width="262px">(This Change Order will NOT be included in reports and Totals until Approved by District).</asp:Label>
    <asp:Label ID="Label23" Style="z-index: 120; left: 55px; position: absolute; top: 96px;
        height: 35px;" runat="server" CssClass="smalltext">Description:</asp:Label>
    <asp:Label ID="Label10" Style="z-index: 120; left: 58px; position: absolute; top: 122px"
        runat="server" Height="16px" CssClass="smalltext">Budget Line:</asp:Label>
    <asp:Label ID="txtJCAFLine" Style="z-index: 120; left: 134px; position: absolute;
        top: 125px; height: 2px;" runat="server" Text="Budget Line description" Font-Bold="True"></asp:Label>
    <asp:Label ID="Label11" Style="z-index: 120; left: 53px; position: absolute; top: 146px"
        runat="server" Height="16px" CssClass="smalltext">Object Code:</asp:Label>
    <telerik:RadComboBox ID="lstJCAFCellNameObjectCode" Skin="Windows7" Label="" runat="server"
        Style="z-index: 4120; left: 137px; position: absolute; vertical-align: middle;
        top: 147px" ToolTip="If selected, this will associate this item with a specific line/funding source in the DOD Budget."
        ShowToggleImage="True" OnClientDropDownOpened="OnClientDropDownOpenedHandler"
        ExpandAnimation-Type="None" CollapseAnimation-Type="None" TabIndex="40" DropDownWidth="475px"
        Width="350px" MaxHeight="375px" OffsetX="0" OffsetY="0">
        <ItemTemplate>
            <div id="div1">
                <telerik:RadTreeView runat="server" ID="RadTreeView1" OnClientNodeClicking="nodeClicking"
                    Height="338px" Width="100%">
                    <Nodes>
                        
                    </Nodes>
                </telerik:RadTreeView>
            </div>
        </ItemTemplate>
        <Items>
            <telerik:RadComboBoxItem Text="" />
        </Items>
    </telerik:RadComboBox>

    <script type="text/javascript">
        var div1 = document.getElementById("div1");
        div1.onclick = StopPropagation;
    </script>

    <asp:Label ID="Label13" Style="z-index: 121; left: 15px; position: absolute; top: 341px;
        right: 1477px; width: 115px;" runat="server" Height="16px" CssClass="smalltext">Arch Approve Date:</asp:Label>
    <asp:Label ID="Label14" Style="z-index: 122; left: 22px; position: absolute; top: 438px"
        runat="server" Height="16px" CssClass="smalltext"> Completion Date:</asp:Label>
    <asp:Label ID="Label16" Style="z-index: 123; left: 50px; position: absolute; top: 517px;
        height: 19px; bottom: 368px;" runat="server" CssClass="smalltext">Comments:</asp:Label>
    <asp:TextBox ID="txtPONumber" Style="z-index: 124; left: 135px; position: absolute;
        top: 217px" TabIndex="20" runat="server" Width="104px" CssClass="EditDataDisplay"></asp:TextBox>
    &nbsp;
    <asp:TextBox ID="txtAccountNumber" Style="z-index: 125; left: 388px; position: absolute;
        top: 64px; width: 124px;" TabIndex="15" runat="server" CssClass="EditDataDisplay"></asp:TextBox>
    <asp:TextBox ID="txtDescription" Style="z-index: 125; left: 137px; position: absolute;
        top: 96px" TabIndex="15" runat="server" Width="376px" CssClass="EditDataDisplay"></asp:TextBox>
    <asp:TextBox ID="txtComments" Style="z-index: 126; left: 135px; position: absolute;
        top: 514px; height: 38px; width: 422px;" TabIndex="80" runat="server" TextMode="MultiLine"
        CssClass="EditDataDisplay"></asp:TextBox>
    <telerik:RadComboBox ID="lstReferenceNo" Style="z-index: 5128; left: 136px; position: absolute;
        top: 37px; width: 154px;" TabIndex="5" runat="server" AllowCustomText="True"
        ToolTip="Entering a reference will allow you to filter only this reference number in the grid">
    </telerik:RadComboBox>
    <asp:DropDownList ID="lstDetailType" Style="z-index: 128; left: 136px; position: absolute;
        top: 65px; width: 154px;" TabIndex="5" runat="server" CssClass="EditDataDisplay"
        AutoPostBack="True" OnSelectedIndexChanged="lstDetailType_SelectedIndexChanged">
    </asp:DropDownList>
    <asp:DropDownList ID="lstCategory" Style="z-index: 129; left: 139px; position: absolute;
        top: 244px" TabIndex="16" runat="server" CssClass="EditDataDisplay">
    </asp:DropDownList>
    <asp:TextBox ID="txtCONumber" Style="z-index: 130; left: 305px; position: absolute;
        top: 9px" TabIndex="1" runat="server" Width="65px" />
    <asp:Label ID="Label17" Style="z-index: 131; left: 11px; position: absolute; top: 472px"
        runat="server" Height="16px" CssClass="smalltext">Board Approve Date:</asp:Label>
    <telerik:RadNumericTextBox ID="txtAmount" runat="server" Style="z-index: 132; left: 137px;
        position: absolute; top: 182px" SelectionOnFocus="SelectAll" TabIndex="70">
    </telerik:RadNumericTextBox>
    <asp:Label ID="Label5" Style="z-index: 133; left: 77px; position: absolute; top: 183px"
        runat="server" Height="16px" CssClass="smalltext">Amount:</asp:Label>
    <asp:ImageButton ID="butSave" Style="z-index: 135; left: 59px; position: absolute;
        top: 569px" runat="server" ImageUrl="images/button_save.gif" TabIndex="100">
    </asp:ImageButton>
    <asp:ImageButton ID="butDelete" Style="z-index: 136; left: 253px; position: absolute;
        top: 568px" runat="server" 
        OnClientClick="return confirm('You have selected to delete this Change Order!\n\nAre you sure you want to delete this Change Order?')"        
        ImageUrl="images/button_delete.gif" TabIndex="200">
    </asp:ImageButton>
    <asp:Label ID="lblMsg" runat="server" ForeColor="Red" Style="z-index: 137; left: 17px;
        position: absolute; top: 492px; height: 16px; width: 498px;">Message</asp:Label>
    <asp:Label ID="Label20" runat="server" Style="z-index: 138; left: 286px; position: absolute;
        top: 276px" Width="1px">Attachments:</asp:Label>
    <asp:HyperLink ID="lnkManageAttachments" runat="server" ImageUrl="images/button_folder_view.gif"
        Style="z-index: 139; left: 524px; position: absolute; top: 299px" TabIndex="71"
        ToolTip="Manage Attachments" Width="1px">Manage Attachments</asp:HyperLink>
    <asp:ListBox ID="lstAttachments" runat="server" CssClass="smalltext" Height="49px"
        Style="z-index: 143; left: 285px; position: absolute; top: 296px" TabIndex="71"
        Width="227px"></asp:ListBox>
    <div style="display: none">
        <asp:Button ID="AttachmentsPopup_AjaxHiddenButton" runat="server"></asp:Button>
    </div>
    <telerik:RadCalendar ID="SharedCalendar" runat="server" EnableMonthYearFastNavigation="False"
        EnableMultiSelect="False" UseColumnHeadersAsSelectors="False" UseRowHeadersAsSelectors="False"
        Skin="Default">
    </telerik:RadCalendar>
    <telerik:RadAjaxManager ID="RadAjaxManager1" runat="server">
        <AjaxSettings>
            <telerik:AjaxSetting AjaxControlID="AttachmentsPopup_AjaxHiddenButton">
                <UpdatedControls>
                    <telerik:AjaxUpdatedControl ControlID="lstAttachments" />
                </UpdatedControls>
            </telerik:AjaxSetting>
           <telerik:AjaxSetting AjaxControlID="lstDetailType">
                <UpdatedControls>
                    <telerik:AjaxUpdatedControl ControlID="lstObjectCode" />
                </UpdatedControls>
            </telerik:AjaxSetting>
        </AjaxSettings>
    </telerik:RadAjaxManager>
    <telerik:RadWindowManager ID="RadPopups" runat="server">
    </telerik:RadWindowManager>
    <asp:Label ID="lblqqq" runat="server" Style="z-index: 112; left: 288px; position: absolute;
        top: 186px" Text="Expended: " />
    <asp:Label ID="lblShowExpended" runat="server" Style="z-index: 112; left: 350px;
        position: absolute; top: 187px; height: 15px;" Text="9999999 " Font-Bold="True" />
    &nbsp;&nbsp;
    <asp:Label ID="lblzzz" runat="server" Style="z-index: 112; left: 433px; position: absolute;
        top: 187px" Text="Available In Budget: " />
    <asp:Label ID="lblShowAvailable" runat="server" Style="z-index: 112; left: 545px;
        position: absolute; top: 188px" Text="9999999 " Font-Bold="True" />
    <asp:CheckBox ID="chkReimbursable" runat="server" Style="z-index: 124; left: 418px;
        position: absolute; top: 35px" Text="Reimbursable" />
    <asp:HiddenField ID="txtObjectCode" runat="server" />
    <asp:HiddenField ID="txtJCAFCellName" runat="server" />
    <asp:HiddenField ID="txxtJCAFLine" runat="server" />
    <asp:HiddenField ID="lblMinAmount" runat="server" />
    <asp:HiddenField ID="lblMaxAvailableAmt" runat="server" />
    <asp:HiddenField ID="txtContractLineItemID" runat="server" />
    <asp:HiddenField ID="txtCurrentTotalContract" runat="server" />
    <asp:HiddenField ID="txtLineObjectCodeDescription" runat="server" />
    </form>
</body>
</html>
