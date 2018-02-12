<%@ Page Language="vb" %>

<%@ Import Namespace="Prompt" %>
<%@ Register Assembly="Telerik.Web.UI" Namespace="Telerik.Web.UI" TagPrefix="telerik" %>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">

<script runat="server">
    Private ContractID As Integer = 0
    Private TransID As Integer = 0
    Private ProjectID As Integer = 0
    
    Private bEnabled As Boolean = True
    Private dLastFiscalYearEnd As Date

    Private Sub Page_Load(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MyBase.Load
        
        If ProcLib.CheckExpiredSessionForPopup(Page) Then    'session died so close the page - this is to prevent orphaned popups
            ProcLib.CloseAndRefresh(Page)
        End If

       
        lblMsg.Text = ""

        'set up help button
        Session("PageID") = "RetentionEdit"
        butHelp.Attributes("onclick") = "return ShowHelp();"
        butHelp.NavigateUrl = "#"

        TransID = Request.QueryString("ID")
        ProjectID = Request.QueryString("ProjectID")
        ContractID = Request.QueryString("ContractID")

        If IsPostBack Then   'only do the following post back
            TransID = lblID.Text
        Else  'only do the following on first load
            
            Using db As New promptTransaction
                db.CallingPage = Page
                db.TransactionType = "Retention"
               
                If TransID = 0 Then    'load new record for add
                    db.GetNewTransaction(ContractID)   'loads default values to record from parent contract
                    ProjectID = db.ParentContract.ProjectID
                    TransID = 0
                    lnkShowLastUpdateInfo.Visible = False
                    butDelete.Visible = False
                    butFlag.Visible = False
                                       
                Else
                    
                    'load existing transaction record
                    db.GetExistingTransaction(TransID, ContractID)   'loads existing trans record
                    
                    LoadLinkedAttachments()
 
                      
                    'Configure the RAD LastUpdate Popup for existing transaction
                    With RadPopups
                        .Skin = "Office2007"
                        .VisibleOnPageLoad = False
                         
                        'Configure LastUPdateWndow
                        Dim ww As New Telerik.Web.UI.RadWindow
                        
                        
                        
                        ww = New Telerik.Web.UI.RadWindow
                        With ww
                            .ID = "OpenAttachmentWindow"
                            .NavigateUrl = ""
                            .Title = "Open Attachment"
                            .Width = 500
                            .Height = 400
                            .Top = 20
                            .Modal = False
                            .VisibleStatusbar = True
                            .ReloadOnShow = True
                            .Behaviors = WindowBehaviors.Close + WindowBehaviors.Move
                        End With
                        .Windows.Add(ww)
                        
                        
                        
                        ww = New Telerik.Web.UI.RadWindow
                        With ww
                            .ID = "ShowLastUpdateInfoWindow"
                            .NavigateUrl = ""
                            .Title = ""
                            .Width = 350
                            .Height = 150
                            .Top = 20
                            .Modal = False
                            .VisibleStatusbar = True
                            .ReloadOnShow = True
                            .Behaviors = WindowBehaviors.Close + WindowBehaviors.Move
                        End With
                        .Windows.Add(ww)
                       
                   
                        'Configure Flag Window
                        ww = New Telerik.Web.UI.RadWindow
                        With ww
                            .ID = "ShowFlagWindow"
                            .NavigateUrl = ""
                            .Title = ""
                            .Width = 500
                            .Height = 400
                            .Top = 20
                            .Modal = False
                            .VisibleStatusbar = True
                            .ReloadOnShow = True
                            
                            .Behaviors = WindowBehaviors.Close + WindowBehaviors.Move
                        End With
                        .Windows.Add(ww)
                        
                        ww = New Telerik.Web.UI.RadWindow
                        With ww
                            .ID = "ManageAttachmentsWindow"
                            .NavigateUrl = ""
                            .Title = ""
                            .Width = 500
                            .Height = 450
                            .Top = 20
                            .Modal = False
                            .VisibleStatusbar = True
                            .ReloadOnShow = True
                            .Behaviors = WindowBehaviors.Close + WindowBehaviors.Move
                        End With
                        .Windows.Add(ww)
         
                    End With
                    lnkShowLastUpdateInfo.Attributes("onclick") = "return ShowLastUpdateInfo(this,'" & TransID & "','Transaction');"
                    lnkShowLastUpdateInfo.NavigateUrl = "#"
                    
                    butFlag.Attributes("onclick") = "return ShowFlag('" & TransID & "');"
                    butFlag.NavigateUrl = "#"
                    
                    'set up attachments button
                    lnkManageAttachments.Attributes("onclick") = "return ManageAttachments('" & TransID & "','Transaction');"
                    lnkManageAttachments.NavigateUrl = "#"
   
      
                End If
                lblID.Text = TransID
                lblNetRet.Text = FormatCurrency(db.ParentContract.RemainingRetentionDue)
                dLastFiscalYearEnd = db.ParentContract.LastFiscalYearEnd
                If txtPayableAmount.Text = "" Then
                    ViewState.Add("OldPayableAmount", 0)
                Else
                    ViewState.Add("OldPayableAmount", txtPayableAmount.Text)
                End If
                
                txtContractorID.Value = db.ParentContract.ContractorID
                
                                 
            End Using
            
            With RadPopups
                .Skin = "Office2007"
                .VisibleOnPageLoad = False
                Dim ww As New Telerik.Web.UI.RadWindow
                With ww
                    .ID = "ShowHelpWindow"
                    .NavigateUrl = ""
                    .Title = ""
                    .Width = 450
                    .Height = 550
                    .Top = 10
                    .Left = 20
                    .Modal = False
                    .VisibleStatusbar = True
                    .ReloadOnShow = True
                    .Behaviors = WindowBehaviors.Close + WindowBehaviors.Move
                End With
                .Windows.Add(ww)
                
                
  
           
            End With
        End If

        'Lock Down for Read Only
        If IsDate(txtInvoiceDate.SelectedDate) Then
            If txtInvoiceDate.SelectedDate <= dLastFiscalYearEnd Then  'locks down controls if appropriate
                bEnabled = False
                lblMsg.Text = "Note: Transaction is View Only because Invoice Date is in past Fiscal Year."
            End If
        End If
        
        Using db As New EISSecurity
            db.DistrictID = Session("DistrictID")
            db.CollegeID = Session("CollegeID")
            db.UserID = Session("UserID")
            db.ProjectID = Request.QueryString("ProjectID")
            If db.FindUserPermission("Transactions", "Write") Then
                bEnabled = True
            Else
                bEnabled = False
            End If
        End Using
        
 
        If bEnabled = False Then
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
            
            lnkManageAttachments.Visible = False
            
            butSave.ImageUrl = "images/button_close.gif"

        End If

         
        txtInvoiceDate.Focus()
        
       
        
    End Sub
    
    Private Sub LoadLinkedAttachments()
        'get the linked attachements
        lstAttachments.Items.Clear()
        Using db As New promptTransaction
            Dim rs As DataTable = db.GetLinkedAttachments(TransID)
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
       
  
        If bEnabled = True Then  'save transaction
            Using db As New promptTransaction
                db.CallingPage = Page
                db.TransactionType = "Retention"
                db.SaveTransaction(TransID)
            End Using
       
            Session("RtnFromEdit") = True
            ProcLib.CloseAndRefresh(Page)
            
        Else
            
            ProcLib.CloseOnly(Page)
       
        End If
        
       
    
    End Sub

    Private Sub butDelete_Click(ByVal sender As System.Object, ByVal e As System.Web.UI.ImageClickEventArgs) Handles butDelete.Click
        Using db As New promptTransaction
            db.DeleteTransaction(TransID)
        End Using
        Session("RtnFromEdit") = True
        ProcLib.CloseAndRefresh(Page)
    End Sub


    Protected Sub txtPayableAmount_TextChanged(ByVal sender As Object, ByVal e As System.EventArgs)
           
        'validate new amount
        Dim nMax As Double = lblNetRet.Text
        Dim nNewAmt As Double = sender.text
        Dim nOldAmt As Double = ViewState("OldPayableAmount")
        If nNewAmt > nMax + nOldAmt Then
            lblMsg.Text = "Sorry, Payable Amount cannot exceed " & FormatCurrency(nMax + nOldAmt)
            DirectCast(Form.FindControl(sender.ID), Telerik.Web.UI.RadNumericTextBox).Text = nOldAmt
            RadAjaxManager1.FocusControl(sender.ID + "_text")  'set focus back to sending control
        End If
       
    End Sub
    
    Protected Sub AttachmentsPopup_AjaxHiddenButton_Click(ByVal sender As Object, ByVal e As System.EventArgs) Handles AttachmentsPopup_AjaxHiddenButton.Click
        'This is method used to handle the workflow popup close to update the linked attachments list 
        LoadLinkedAttachments()
    End Sub
    
    
</script>

<html>
<head>
    <title>Prompt - Edit Retention Transaction</title>
    <link href="Styles.css" type="text/css" rel="stylesheet" />

    <script type="text/javascript" language="javascript">
        // this is the actual script for loading the RAD window popup objects from attribute assigned to page elements

        function ShowLastUpdateInfo(oButton, id, rectype)     //for LastUpdate info display
        {

            var oWnd = window.radopen("show_last_update_info.aspx?ID=" + id + "&RecType=" + rectype, "ShowLastUpdateInfoWindow");
            return false;
        }

        function ShowHelp()     //for help display
        {

            var oWnd = window.radopen("help_view.aspx?WinType=RAD", "ShowHelpWindow");
            return false;
        }

        function ShowFlag(id)     //for Flag display
        {

            var oWnd = window.radopen("flag_edit.aspx?ParentRecID=" + id + "&ParentRecType=Transaction&WinType=RAD", "ShowFlagWindow");
            return false;

        }

        function GetRadWindow() {
            var oWindow = null;
            if (window.RadWindow) oWindow = window.RadWindow;
            else if (window.frameElement.radWindow) oWindow = window.frameElement.radWindow;
            return oWindow;
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
    </script>

</head>
<body>
 <form id="Form1" method="post" runat="server">
     <telerik:RadScriptManager ID="RadScriptManager1" runat="server" />
 <td style="height: 6px" valign="top" align="right">
                <asp:HyperLink ID="butFlag" runat="server" 
         Style="z-index: 100; left: 463px; position: absolute; top: 12px" 
         ImageUrl="images/button_flag.gif"></asp:HyperLink>&nbsp;&nbsp;&nbsp;
                <asp:HyperLink ID="butHelp" runat="server" 
         Style="z-index: 100; left: 525px; position: absolute; top: 13px" 
         ImageUrl="images/button_help.gif">HyperLink</asp:HyperLink>

   
    <asp:Label ID="Label1" Style="z-index: 100; left: 240px; position: absolute; top: 43px"
        runat="server" EnableViewState="False">Date Received:</asp:Label>
    <asp:Label ID="Label19" runat="server" EnableViewState="False" Style="z-index: 100;
        left: 454px; position: absolute; top: 46px">Fiscal Year:</asp:Label>
    <asp:DropDownList ID="lstFiscalYear" Style="z-index: 102; left: 522px; position: absolute;
        top: 44px" runat="server" CssClass="EditDataDisplay">
    </asp:DropDownList>
    <telerik:RadDatePicker ID="txtDatePaid" Style="z-index: 101; left: 102px; position: absolute;
        top: 116px" runat="server" TabIndex="30" Width="120px" 
         SharedCalendarID="sharedCalendar" Skin="Vista">
        <DateInput runat="server" Skin="Vista" Font-Size="13px" ForeColor="Blue">
        </DateInput>
    </telerik:RadDatePicker>
    <telerik:RadDatePicker ID="txtDateReceived" Style="z-index: 102; left: 325px; position: absolute;
        top: 45px" runat="server" TabIndex="5" Width="120px" 
         SharedCalendarID="sharedCalendar" Skin="Vista">
        <DateInput runat="server" Skin="Vista" Font-Size="13px" ForeColor="Blue">
        </DateInput>
    </telerik:RadDatePicker>
    <asp:Label ID="lblID" Style="z-index: 103; left: 52px; position: absolute; top: 14px"
        runat="server">9999</asp:Label>
    <asp:Label ID="Label2" Style="z-index: 104; left: 17px; position: absolute; top: 13px; width: 14px;"
        runat="server" EnableViewState="False">ID:</asp:Label>
    <asp:Label ID="lblMsg" runat="server" ForeColor="Red" Style="z-index: 105; left: 26px;
        position: absolute; top: 480px" Width="396px">Message</asp:Label>
    <asp:Label ID="lblNetRet" Style="z-index: 106; left: 152px; position: absolute; top: 382px"
        runat="server" Width="56px" CssClass="EditDataDisplay"> 9999</asp:Label>
    &nbsp;
    <asp:Label ID="Label16" Style="z-index: 107; left: 42px; position: absolute; top: 412px"
        runat="server" EnableViewState="False">Payable Amount:</asp:Label>
    <asp:Label ID="Label15" Style="z-index: 108; left: 16px; position: absolute; top: 378px"
        runat="server"> Net Unpaid Retention:</asp:Label>
    <asp:TextBox ID="txtComments" Style="z-index: 109; left: 104px; position: absolute;
        top: 316px" runat="server" Width="416px" Height="48px" TextMode="MultiLine" TabIndex="60"
        CssClass="EditDataDisplay"></asp:TextBox>
    <asp:TextBox ID="txtPurchaseOrderNumber" Style="z-index: 110; left: 287px; position: absolute;
        top: 153px" runat="server" Width="96px" TabIndex="50" 
         CssClass="EditDataDisplay"></asp:TextBox>
    <asp:TextBox ID="txtBondSeries" Style="z-index: 111; left: 99px; position: absolute;
        top: 154px" runat="server" Width="40px" TabIndex="45" 
         CssClass="EditDataDisplay"></asp:TextBox>
    <asp:TextBox ID="txtInternalInvNumber" Style="z-index: 112; left: 102px; position: absolute;
        top: 199px" runat="server" Width="96px" TabIndex="40" 
         CssClass="EditDataDisplay"></asp:TextBox>
    <asp:TextBox ID="txtCheckNumber" Style="z-index: 113; left: 287px; position: absolute;
        top: 115px" runat="server" Width="96px" TabIndex="35" 
         CssClass="EditDataDisplay"></asp:TextBox>
    <asp:TextBox ID="txtFundCode" Style="z-index: 114; left: 496px; position: absolute;
        top: 154px" runat="server" Width="96px" TabIndex="55" 
         CssClass="EditDataDisplay"></asp:TextBox>
    <asp:TextBox ID="txtInvoiceNumber" Style="z-index: 115; left: 483px; position: absolute;
        top: 78px" runat="server" Width="96px" TabIndex="15" 
         CssClass="EditDataDisplay"></asp:TextBox>
    <asp:DropDownList ID="lstStatus" Style="z-index: 116; left: 480px; position: absolute;
        top: 114px" runat="server" TabIndex="25" CssClass="EditDataDisplay">
    </asp:DropDownList>
    <asp:TextBox ID="txtDescription" Style="z-index: 117; left: 102px; position: absolute;
        top: 77px" runat="server" Width="304px" TabIndex="20" 
         CssClass="EditDataDisplay"></asp:TextBox>
    <asp:Label ID="Label14" Style="z-index: 119; left: 22px; position: absolute; top: 313px"
        runat="server">Comments:</asp:Label>
    <asp:Label ID="Label13" Style="z-index: 120; left: 203px; position: absolute; top: 156px"
        runat="server">P.O. Number:</asp:Label>
    <asp:Label ID="Label12" Style="z-index: 121; left: 27px; position: absolute; top: 155px"
        runat="server" Height="16px">Bond Series:</asp:Label>
    <asp:Label ID="Label18" runat="server" Height="16px" Style="z-index: 122; left: 21px;
        position: absolute; top: 250px">Attachments:</asp:Label>
    <asp:Label ID="Label11" Style="z-index: 123; left: 21px; position: absolute; top: 196px"
        runat="server">Internal Inv#:</asp:Label>
    <asp:Label ID="Label10" Style="z-index: 124; left: 230px; position: absolute; top: 118px"
        runat="server">Check#:</asp:Label>
    <asp:Label ID="Label9" Style="z-index: 125; left: 35px; position: absolute; top: 114px"
        runat="server">Date Paid:</asp:Label>
    <asp:Label ID="Label8" Style="z-index: 126; left: 421px; position: absolute; top: 157px"
        runat="server">Fund Code:</asp:Label>
    <asp:Label ID="Label7" Style="z-index: 127; left: 25px; position: absolute; top: 39px"
        runat="server">Invoice Date:</asp:Label>
    <asp:Label ID="Label6" Style="z-index: 128; left: 424px; position: absolute; top: 78px"
        runat="server">Invoice #:</asp:Label>
    <asp:Label ID="Label5" Style="z-index: 129; left: 434px; position: absolute; top: 118px"
        runat="server">Status:</asp:Label>
    <asp:Label ID="Label4" Style="z-index: 130; left: 28px; position: absolute; top: 74px"
        runat="server">Description:</asp:Label>
    &nbsp;
    <telerik:RadDatePicker ID="txtInvoiceDate" Style="z-index: 132; left: 103px; position: absolute;
        top: 37px" runat="server" Width="120px" SharedCalendarID="sharedCalendar" 
         Skin="Vista">
        <DateInput runat="server" Skin="Vista" Font-Size="13px" ForeColor="Blue">
        </DateInput>
    </telerik:RadDatePicker>
    <asp:ImageButton ID="butSave" Style="z-index: 133; left: 28px; position: absolute;
        top: 453px" runat="server" ImageUrl="images/button_save.gif" TabIndex="100">
    </asp:ImageButton>
    <asp:ImageButton ID="butDelete" Style="z-index: 134; left: 310px; position: absolute;
        top: 452px" runat="server" ImageUrl="images/button_delete.gif" TabIndex="200">
    </asp:ImageButton>
    &nbsp;
    <telerik:RadNumericTextBox ID="txtPayableAmount" runat="server" Style="z-index: 135;
        left: 152px; position: absolute; top: 410px"
        SelectionOnFocus="SelectAll" MinValue="0" AutoPostBack="True" OnTextChanged="txtPayableAmount_TextChanged"
        TabIndex="70">
    </telerik:RadNumericTextBox>
    <telerik:RadAjaxManager ID="RadAjaxManager1" runat="server">
        <AjaxSettings>
            <telerik:AjaxSetting AjaxControlID="txtPayableAmount">
                <UpdatedControls>
                    <telerik:AjaxUpdatedControl ControlID="lblMsg" />
                    <telerik:AjaxUpdatedControl ControlID="txtPayableAmount" />
                </UpdatedControls>
            </telerik:AjaxSetting>
            <telerik:AjaxSetting AjaxControlID="AttachmentsPopup_AjaxHiddenButton">
                <UpdatedControls>
                    <telerik:AjaxUpdatedControl ControlID="lstAttachments" />
                </UpdatedControls>
            </telerik:AjaxSetting>
        </AjaxSettings>
    </telerik:RadAjaxManager>
    <asp:HyperLink ID="lnkShowLastUpdateInfo" runat="server" ImageUrl="images/change_history.gif"
        Style="z-index: 135; left: 423px; position: absolute; top: 12px" 
         ToolTip="show last update information">HyperLink</asp:HyperLink>
    <asp:HyperLink ID="lnkManageAttachments" runat="server" ImageUrl="images/button_folder_view.gif"
        Style="z-index: 136; left: 347px; position: absolute; top: 252px" TabIndex="71"
        ToolTip="Manage Attachments">Manage Attachments</asp:HyperLink>
    <asp:ListBox ID="lstAttachments" runat="server" Height="49px" Style="z-index: 137;
        left: 105px; position: absolute; top: 251px; width: 224px;" CssClass="smalltext"
        TabIndex="71"></asp:ListBox>
    <telerik:RadWindowManager ID="RadPopups" runat="server">
    </telerik:RadWindowManager>
    <asp:CheckBox ID="chkUsesRetentionEscrow0" runat="server" Style="z-index: 141; left: 300px;
        position: absolute; top: 379px" Text="Uses Escrow Account" />
    <asp:CheckBox ID="chkAccrual" runat="server" Style="z-index: 141; left: 273px; position: absolute;
        top: 201px" Text="Accrual" />
    <%-- 
            Put Hidden button on form to handle ajax post back from rad window
            AJAXPostBack
            --%>
    <div style="display: none">
        <asp:Button ID="AttachmentsPopup_AjaxHiddenButton" runat="server"></asp:Button>
    </div>
    <div style="display: none">
        <telerik:RadCalendar ID="sharedCalendar" Skin="Vista" runat="server" EnableMultiSelect="false">
        </telerik:RadCalendar>
    </div>
    
     <asp:HiddenField ID="txtContractorID" runat="server" />
    
    
    </form>
</body>
</html>
