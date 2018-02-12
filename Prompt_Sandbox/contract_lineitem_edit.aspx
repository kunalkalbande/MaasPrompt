<%@ Page Language="vb" %>

<%@ Register Assembly="Telerik.Web.UI" Namespace="Telerik.Web.UI" TagPrefix="telerik" %>
<%@ Import Namespace="Prompt" %>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">

<script runat="server">
    Private nLineItemID As Integer = 0
    Private nContractID As Integer = 0
    Private nProjectID As Integer = 0
    
    Private sLineType As String = ""
    
    Private bReadOnly As Boolean = False
    
    Private Sub Page_Load(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MyBase.Load

        ProcLib.CheckSession(Page)
        ProcLib.LoadPopupJscript(Page)
        
        'set up help button
        Session("PageID") = "ContractLineItemEdit"
        butHelp.Attributes.Add("onclick", "openPopup('help_view.aspx','pophelp',550,450,'yes');")
        butHelp.NavigateUrl = "#"

        nLineItemID = Request.QueryString("ID")
        nContractID = Request.QueryString("ContractID")
        nProjectID = Request.QueryString("ProjectID")
        
        lstReferenceNo.Visible = False  'TURN OFF FOR NOW
        
        If nLineItemID = 0 Then
            Page.Title = "Add New Line Item"
        Else
            Page.Title = "Edit Line Item"
        End If
        
        lblMessage.Text = ""
        
        If Not IsPostBack Then
            Using db As New promptContract
                db.CallingPage = Page
                db.GetLineItemForEdit(nLineItemID, nContractID)
                nProjectID = db.ProjectID
                
  
                If nLineItemID > 0 Then
                    lblMinAmount.Value = db.GetTotalExpendedForContractLineItem(nLineItemID)   'store value to hidden field
                    
                    If lblMinAmount.Value <> 0 Then   'could be neg or pos associtated items
                        butDelete.Visible = False
                        cboLineType.Enabled = False
                    End If
                Else
                    lblMinAmount.Value = 0
                    butDelete.Visible = False
                    txtJCAFLine.Text = ""
                    txtAmount.Value = 0
                    txtAccountNumber.Text = db.AccountNumber
                    
                    txtItemDate.SelectedDate = Now()
   
                End If
                
                lblMaxAvailableAmt.Value = db.GetMaxOCJCAFCellAmountForContractLineItem(txtAmount.Value, txtObjectCode.Value, txtJCAFCellName.Value, nProjectID) 'store value to hidden field
                
                txtCurrentTotalContract.Value = db.ContractTotal
  
                'for some reason this is not updating on fill
                txxtJCAFLine.Value = txtJCAFLine.Text
                
               FillObjectCodeList
                
                lstJCAFCellNameObjectCode.BackColor = Color.LightYellow
                
                
                'Set warning of overspent JCAF if there is a problem (legacy)
                If db.JCAFLineIsOverSpentForThisOC = True Then
                    lblMessage.Text = "WARNING: JCAF bucket is over-encumbered for this selected ObjectCode/JCAF Line."
                End If
                
            End Using
        End If
 
        
        lblxxLineID.Text = "ID: " & nLineItemID
        
        lblShowAvailable.Text = FormatCurrency(lblMaxAvailableAmt.Value)  'store value to display field
        lblShowExpended.Text = FormatCurrency(lblMinAmount.Value)           'store value to display field
        
        txtItemDate.Focus()
        
               
        
        If bReadOnly Then
            txtAmount.Enabled = False
            lstJCAFCellNameObjectCode.Enabled = False
            chkReimbursable.Enabled = False
            txtAccountNumber.Enabled = False
            txtPOLineNumber.Enabled = False
            txtItemDate.Enabled = False
            cboLineType.Enabled = False
        End If
        
        
        

    End Sub
   

    Private Sub butSave_Click(ByVal sender As System.Object, ByVal e As System.Web.UI.ImageClickEventArgs) Handles butSave.Click

        If Trim(txtDescription.Text) = "" Then
            lblMessage.Text = "Please enter a Description."
            Exit Sub
        End If
        
        If txtAmount.Value = 0 Then
            lblMessage.Text = "Please enter an Amount."
            Exit Sub
        End If
        
        'check for valid date
        If Not IsDate(txtItemDate.DbSelectedDate) Then
            lblMessage.Text = "Please enter a valid date."
            Exit Sub
        End If
        
        'fix the apostrophe problem
        txtDescription.Text = Replace(txtDescription.Text, "'", "''")
        
        Using db As New promptContract
            db.CallingPage = Page
            db.SaveLineItem(nContractID, nLineItemID)
        End Using

        Session("RtnFromEdit") = True
        Session("RtFromContractLineEdit") = True
        
        'ProcLib.CloseAndRefreshRAD(Page)
        ProcLib.CloseAndRefresh(Page)
       
    End Sub

    Protected Sub butDelete_Click(ByVal sender As Object, ByVal e As System.Web.UI.ImageClickEventArgs) Handles butDelete.Click

        Dim sErr As String = ""
        Using db As New promptContract
            sErr = db.DeleteLineItem(nLineItemID)
        End Using
        
        If sErr <> "" Then    'there was a probl
            
            lblMessage.Text = sErr
            
        Else   'ok
            
            Session("RtnFromEdit") = True
            Session("RtFromContractLineEdit") = True
        
            'ProcLib.CloseAndRefreshRAD(Page)
            ProcLib.CloseAndRefresh(Page)
            
        End If
        
        
        
    End Sub
    
      
    Protected Sub cboLineType_SelectedIndexChanged(ByVal o As Object, ByVal e As Telerik.Web.UI.RadComboBoxSelectedIndexChangedEventArgs)

       FillObjectCodeList

    End Sub
    
    Private Sub FillObjectCodeList()
        Using db As New promptContract
            Dim sLineType As String = cboLineType.Text
            
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
<head runat="server">
    <title>Edit Line Item</title>
    <link href="Styles.css" type="text/css" rel="stylesheet" />
    <style type="text/css">
        .style1
        {
            height: 30px;
        }
    </style>
</head>
<body>
    <form id="Form1" method="post" runat="server">
    <telerik:RadScriptManager ID="RadScriptManager1" runat="server" />
    <table width="100%">
        <tr>
            <td>
                <asp:Label ID="Label7" runat="server" Text="Date:"></asp:Label>
            </td>
            <td>
                <telerik:RadDatePicker ID="txtItemDate" runat="server" TabIndex="10" Width="120px"
                    SharedCalendarID="sharedCalendar">
                    <DateInput Skin="WebBlue" Font-Size="13px" ForeColor="Blue">
                    </DateInput>
                </telerik:RadDatePicker>
                <telerik:RadCalendar ID="sharedCalendar" runat="server" EnableMultiSelect="false">
                </telerik:RadCalendar>
            </td>
            <td width="150px" align="right">
                <asp:HyperLink ID="butHelp" runat="server" ImageUrl="images/button_help.gif">help</asp:HyperLink>
            </td>
        </tr>
        
      <%--         <tr>
            <td>
                <asp:Label ID="Label8" runat="server" Text="Reference:"></asp:Label>
            </td>
            <td colspan="2">--%>
                <telerik:RadComboBox ID="lstReferenceNo" Style="z-index: 5128; " TabIndex="5" runat="server" AllowCustomText="True" 
        ToolTip="Entering a reference will allow you to filter only this reference number in the grid">
    </telerik:RadComboBox>
          <%--   </td>
           
        </tr>--%>
        
          
        
        
        <tr>
            <td>
                <asp:Label ID="Label3" runat="server" Text="Description:"></asp:Label>
            </td>
            <td colspan="2">
                <asp:TextBox ID="txtDescription" Width="280px" TabIndex="1" runat="server"></asp:TextBox>
            </td>
        </tr>
        
        
                    <tr>
            <td>
                <asp:Label ID="Label6" runat="server" Text="Line Type:"></asp:Label>
            </td>
            <td colspan="2" align="left">
                <telerik:RadComboBox ID="cboLineType" runat="server" TabIndex="61" 
                    AutoPostBack="True" onselectedindexchanged="cboLineType_SelectedIndexChanged">
                    <Items>
                        <telerik:RadComboBoxItem runat="server" Text="Contract" Value="Contract" />
                        <telerik:RadComboBoxItem runat="server" Text="Adjustment" Value="Adjustment" />
                    </Items>
                </telerik:RadComboBox>
            </td>
        </tr>
        
        <tr>
            <td class="style1">
                <asp:Label ID="Label1" runat="server" Text="JCAF Line:"></asp:Label>
            </td>
            <td colspan="2" class="style1">
                <asp:Label ID="txtJCAFLine" runat="server" Text="JCAF Line description" Font-Bold="True"></asp:Label>
            </td>
        </tr>
        
    
        
        <tr>
            <td>
                <asp:Label ID="Label21" runat="server" Text="Object Code:"></asp:Label>
            </td>
            <td colspan="2">
                <telerik:RadComboBox ID="lstJCAFCellNameObjectCode" Skin="Windows7" Label="" runat="server"
                    ToolTip="If selected, this will associate this item with a specific line/funding source in the JCAF Budget."
                    ShowToggleImage="True" Style="vertical-align: middle;" OnClientDropDownOpened="OnClientDropDownOpenedHandler"
                    ExpandAnimation-Type="None" CollapseAnimation-Type="None" TabIndex="40" DropDownWidth="475px"
                    Width="350px" MaxHeight="175px" OffsetX="-75" OffsetY="-25">
                    <ItemTemplate>
                        <div id="div1">
                            <telerik:RadTreeView runat="server" ID="RadTreeView1" OnClientNodeClicking="nodeClicking"
                                Height="138px" Width="100%">
                                <Nodes>
                                    <%-- <telerik:RadTreeNode runat="server" Text="Any JCAF Line" Expanded="False" />--%>
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

            </td>
        </tr>
        <tr>
            <td>
                &nbsp;
            </td>
            <td colspan="2">
                <asp:Label ID="lblzzz" runat="server" Text="Avail in JCAF Line for this ObjectCode (Including this line): " />&nbsp;&nbsp;
                <asp:Label ID="lblShowAvailable" runat="server" Text="9999999 " Font-Bold="True" />
                <br />
                <asp:Label ID="lblqqq" runat="server" Text="Amount already expended against this Line: " />&nbsp;&nbsp;
                <asp:Label ID="lblShowExpended" runat="server" Text="9999999 " Font-Bold="True" />
            </td>
        </tr>
        <tr>
            <td>
                <asp:Label ID="Label5" runat="server" Text="Amount:"></asp:Label>
            </td>
            <td colspan="2">
                <telerik:RadNumericTextBox ID="txtAmount" runat="server" TabIndex="20" SelectionOnFocus="SelectAll"
                    MinValue="-500000000" ClientEvents-OnValueChanged="ValidateAmounts" />
            </td>
        </tr>
        <tr>
            <td>
                <asp:Label ID="Label4" runat="server" Text="Account Number:"></asp:Label>
            </td>
            <td colspan="2">
                <asp:TextBox ID="txtAccountNumber" Width="192px" TabIndex="1" runat="server"></asp:TextBox>
            </td>
        </tr>
        <tr>
            <td>
                <asp:Label ID="Label2" runat="server" Text="P.O. Line#:"></asp:Label>
            </td>
            <td>
                <asp:TextBox ID="txtPOLineNumber" runat="server" TabIndex="61" Width="45px" />
            </td>
            <td>
                <asp:CheckBox ID="chkReimbursable" runat="server" Text="Reimbursable" />
            </td>
        </tr>

        <tr>
            <td colspan="3">
                <asp:Label ID="lblMessage" runat="server" Text="message" Font-Bold="True" ForeColor="Red"></asp:Label>
            </td>
        </tr>
        <tr>
            <td height="65px">
                <asp:ImageButton ID="butSave" TabIndex="5" runat="server" ImageUrl="images/button_save.gif">
                </asp:ImageButton>
            </td>
            <td align="right">
                <asp:ImageButton ID="butDelete" TabIndex="5" runat="server" ImageUrl="images/button_delete.gif"
                 OnClientClick="return confirm('You are about to delete this contract.\nAre you sure you want to delete this contract?')" />
         
               </asp:ImageButton>
            </td>
            <td align="right">
                <asp:Label ID="lblxxLineID" runat="server" Text="LineID"></asp:Label>
            </td>
        </tr>
    </table>
    <asp:HiddenField ID="txtCurrentTotalContract" runat="server" />
    <asp:HiddenField ID="lblMinAmount" runat="server" />
    <asp:HiddenField ID="lblMaxAvailableAmt" runat="server" />
    <asp:HiddenField ID="txtObjectCode" runat="server" />
    <asp:HiddenField ID="txtJCAFCellName" runat="server" />
    <asp:HiddenField ID="txxtJCAFLine" runat="server" />
    <asp:HiddenField ID="txtLineObjectCodeDescription" runat="server" />
    <asp:HiddenField ID="txtLastUpdateBy" runat="server" />
    <%-- lets us disable edit for conversion created items --%>
    <%--  <telerik:RadAjaxManager ID="RadAjaxManager1" runat="server">
        <AjaxSettings>
            <telerik:AjaxSetting AjaxControlID="lstJCAFCellName">
                <UpdatedControls>
                    <telerik:AjaxUpdatedControl ControlID="lstObjectCode" LoadingPanelID="RadAjaxLoadingPanel1" />
                </UpdatedControls>
            </telerik:AjaxSetting>
        </AjaxSettings>
    </telerik:RadAjaxManager>
    <telerik:RadAjaxLoadingPanel ID="RadAjaxLoadingPanel1" runat="server" Height="15px"
        Width="15px" Transparency="25">
        <img alt="Loading..." src='<%= RadAjaxLoadingPanel.GetWebResourceUrl(Page, "Telerik.Web.UI.Skins.Default.Ajax.loading.gif") %>'
            style="border: 0;" />
    </telerik:RadAjaxLoadingPanel>--%>
    <telerik:RadCodeBlock ID="RadCodeBlock1" runat="server">

        <script type="text/javascript" language="javascript">

            var OKCancel = false;

            function GetRadWindow() {
                var oWindow = null;
                if (window.RadWindow) oWindow = window.RadWindow;
                else if (window.frameElement.radWindow) oWindow = window.frameElement.radWindow;
                return oWindow;
            }

            function ValidateAmounts(sender, eventArgs) {
                //alert(OKCancel);
                // to fix loop
                if (OKCancel == true) {
                    //alert('here')
                    OKCancel = false;
                    return false;
                }

                //alert('here2');
                // called by contract amount textboxes to validate the entry
                var oldamt = eventArgs.get_oldValue();

                var objMaxAmount = document.getElementById("lblMaxAvailableAmt");
                //get rid of rounding errors
                var nMaxAmt = Math.round(objMaxAmount.value * 100) / 100;

                var objMinAmount = document.getElementById("lblMinAmount");
                var nMinAmt = objMinAmount.value;

                var nAmount = sender.get_value();
                var nNewTotal = parseFloat(nAmount);

                var sMax = formatCurrency(nMaxAmt);
                var sMin = formatCurrency(nMinAmt);

                if (nMinAmt > 0) {
                    if (nNewTotal < nMinAmt) {
                        alert('Sorry, This Contract currently has Transactions applied to it than exceed the new amount you are trying to enter. The Line Item Amount must be at least ' + sMin);
                        eventArgs.set_cancel(true);
                        window.setTimeout(function() { sender.focus(); }, 50);
                        sender.set_value(oldamt);
                        return false;
                    }
                }

                if (nNewTotal > nMaxAmt) {
                    alert('Sorry, Line Item Amount cannot be more than ' + sMax + '. Check that you have assigned a JCAF Object Code to this Line that has a high enough Available Balance');


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
                        alert('Sorry, This line item has an amount that is greater than the available balance of the JCAF Object Code you are trying to select. Please reduce the amount before changing JCAF OC Line Association');
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
    </form>
</body>
</html>
