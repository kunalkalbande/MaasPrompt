<%@ Page Language="VB" %>

<%@ Register Assembly="Telerik.Web.UI" Namespace="Telerik.Web.UI" TagPrefix="telerik" %>
<%@ Import Namespace="Prompt" %>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">

<script runat="server">
    
    Private sRecType As String = ""
    Private nRecID As Integer = 0
    Private Source As String = ""
    Private CalledFromDashboard As Boolean = False
    Private CurrentView As String = ""
    Private bWorkflowDataTransferEnabled As Boolean = False
   
    
    Private IsRetentionScenario As Boolean = False
    
    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs)
        
        If Request.QueryString("CalledFrom") = "Dashboard" Then   'flag to allow refresh of grid in calling page
            CalledFromDashboard = True
        End If
        
        sRecType = Request.QueryString("rectype")
        nRecID = Request.QueryString("recid")
        Source = Request.QueryString("Source")
        CurrentView = Request.QueryString("CurrentView")
        
        'check to see if this district has electronic data transfer turned on 
        Using db As New PromptDataHelper
            Dim result As Integer = db.ExecuteScalar("SELECT EnableWorkflowDataTransfer FROM Districts WHERE DistrictID = " & Session("DistrictID"))
            If result = 1 Then
                bWorkflowDataTransferEnabled = True
            End If
        End Using
        

        lblAlert.Text = ""
       
        If Not IsPostBack Then

            'load the drop down boxes
            Using db As New promptWorkflow
                db.CallingPage = Page
                db.RecordType = sRecType
                db.TransactionID = nRecID
                db.PADID = nRecID
                db.LoadRoutingTargetListBoxes()
                
                IsRetentionScenario = db.IsRetentionScenario(db.WorkflowScenerioID)
                If db.IsFinalApprover Then
                    bIsFinalApprover.Value = "Yes"
                End If
                
                
                ViewState("TransactionRetentionAmount") = db.TransactionRetentionAmount   'to get later upon approval
               
                If db.MaxDollarApprovalLevel >= db.TransactionTotalAmount Then
                    ViewState("SignatorApprovalDollarAmountOk") = True
                End If
                
                'Configure the screen layout depending on various conditions
                
                chkApproveRetentionAmount.Visible = False
                chkFRSCutSingleCheck.Visible = False
                lblCheckCode.Visible = False
                lstFRSCheckMessageCode.Visible = False
                
                lblRetCheckCode.Visible = False
                lstFRSRetentionCheckMessageCode.Visible = False
                
                lblNotesReason.Visible = False
                lstWorkflowRejectReason.Visible = False

                If lstApproveTarget.Items.Count = 0 Then
                    butApprove.Visible = False
                    lstApproveTarget.Visible = False
                    
                Else
                    butApprove.Visible = True
                    lstApproveTarget.Visible = True
                End If
                
                
                If lstRejectTarget.Items.Count = 0 Then
                    butReject.Visible = False
                    lstRejectTarget.Visible = False
                Else
                    butReject.Visible = True
                    lstRejectTarget.Visible = True
                End If
                
                If sRecType <> "PAD" Then                    'enable certain fields for some roles
                    Select Case Session("WorkflowRoleType")
                    
                        Case "Bond Accountant"   'for district staff
                        
                            If IsRetentionScenario Then
                                chkApproveRetentionAmount.Visible = True
                                chkApproveRetentionAmount.Style.Item("Top") = "140px"
                            End If

                            'Show/Hide controls
                            If db.TransactionRetentionAmount > 0 Then
                                lstFRSRetentionCheckMessageCode.Visible = True
                                lblRetCheckCode.Visible = True
                            Else
                           
                                lstFRSRetentionCheckMessageCode.Visible = False
                                lblRetCheckCode.Visible = False
                                                  
                                lstFRSCheckMessageCode.Visible = True
                                lblCheckCode.Visible = True
                                lblCheckCode.Style.Item("Top") = "135px"
                                lstFRSCheckMessageCode.Style.Item("Top") = "135px"
                            
                                lblNotesReason.Style.Item("Top") = "116px"
                                lstWorkflowRejectReason.Style.Item("Top") = "116px"
                            
                            
                                txtNotes.Style.Item("Top") = "163px"
                                butClose.Style.Item("Top") = "230px"
                                butSave.Style.Item("Top") = "230px"
                    
                            End If

                            If lstApproveTarget.Items.Count = 0 Then
                                butApprove.Visible = False
                                lstApproveTarget.Visible = False
                            Else
                                butApprove.Visible = True
                                lstApproveTarget.Visible = True
                            End If
                            If lstRejectTarget.Items.Count = 0 Then
                                butReject.Visible = False
                                lstRejectTarget.Visible = False
                            Else
                                butReject.Visible = True
                                lstRejectTarget.Visible = True
                            End If
                         
                        
                            db.LoadCheckMessageListBoxes()     'fill the list boxes for message codes
                   
                        Case "District AP"
                            'add default pick for approval
                            Dim item As New ListItem
                        

                            If bWorkflowDataTransferEnabled = True Then
                                item.Text = "Ready To Transfer"    'NOTE: This is only next step when DATA TRANSFER is working
                                item.Value = -100
                                item.Selected = True
                                lstApproveTarget.Items.Add(item)
                            
                            Else
                                                   
                                item.Text = "District for Payment"    'NOTE: This is only next step when DATA TRANSFER is NOT working
                                item.Value = -100
                                item.Selected = True
                                lstApproveTarget.Items.Add(item)
                            
                            End If
         
                            chkFRSCutSingleCheck.Visible = False
                        
                            butApprove.Visible = True
                            lstApproveTarget.Visible = True
                        
                            lblNotesReason.Style.Item("Top") = "120px"
                            lstWorkflowRejectReason.Style.Item("Top") = "120px"
                            chkFRSCutSingleCheck.Style.Item("Top") = "120px"
                            txtNotes.Style.Item("Top") = "140px"
                            butClose.Style.Item("Top") = "220px"
                            butSave.Style.Item("Top") = "220px"
                        
                        Case Else
                            If butReject.Visible = False Then    'move up the notes and command buttons
                                lblNotesReason.Style.Item("Top") = "100px"
                                txtNotes.Style.Item("Top") = "120px"
                                butClose.Style.Item("Top") = "200px"
                                butSave.Style.Item("Top") = "200px"
                            Else
                            
                                lblNotesReason.Style.Item("Top") = "120px"
                                lstWorkflowRejectReason.Style.Item("Top") = "120px"
                                txtNotes.Style.Item("Top") = "140px"
                                butClose.Style.Item("Top") = "220px"
                                butSave.Style.Item("Top") = "220px"
                            
                            End If
                   
                    End Select
                    
                Else   'this is PAD
                    
                    If bIsFinalApprover.Value = "Yes" Then    'clear out targets if any and add item to approve
                        lstApproveTarget.Items.Clear()
                        Dim item As New ListItem
                        item.Text = "Final Approval"
                        item.Value = 0
                        lstApproveTarget.Items.Add(item)
                        lstApproveTarget.Visible = True
                        butApprove.Visible = True
                       
                    End If

                    If butReject.Visible = False Then    'move up the notes and command buttons
                        'lblNotesReason.Style.Item("Top") = "100px"
                        txtNotes.Style.Item("Top") = "120px"
                        butClose.Style.Item("Top") = "200px"
                        butSave.Style.Item("Top") = "200px"
                        
                    Else
                            
                        'lblNotesReason.Style.Item("Top") = "120px"
                        lstWorkflowRejectReason.Style.Item("Top") = "120px"
                        txtNotes.Style.Item("Top") = "140px"
                        butClose.Style.Item("Top") = "220px"
                        butSave.Style.Item("Top") = "220px"
                       
                            
                    End If
                    
                End If
                
            End Using

        End If
    End Sub
    
    
    Private Function ValidateEntries() As String
        Dim msg As String = ""
        If butApprove.Checked = False And butReject.Checked = False Then
            msg = "You must either approve or reject the transaction"
        
        ElseIf butReject.Checked = True And txtNotes.Text = "" And lstWorkflowRejectReason.Text = "" Then
            msg = "You must enter a reason for Rejecting this transaction"
        
        End If
        
        If Session("WorkflowRoleType") = "Bond Accountant" Then
            If chkApproveRetentionAmount.Visible = True Then   'force approval of retention for designated transactions
                If butApprove.Checked = True Then
                    If chkApproveRetentionAmount.Checked = False Then
                        msg = "You must approve the Retention Amount to approve this transaction."
                    End If
                End If
            End If
        End If
                  
        'Check that there is a signator in the chain that can sign for the amount of the transaction
        If ViewState("SignatorApprovalDollarAmountOk") = False Then
            msg = "Sorry, There are no Workflow Owners in this scenerio that have $$ approval level high enough for this Transaction Amount."
        End If
        Return msg
    End Function

    Protected Sub butSave_Click(ByVal sender As Object, ByVal e As System.Web.UI.ImageClickEventArgs)
        Dim msg As String = ValidateEntries()
        If msg <> "" Then
            lblAlert.Text = "<script language='javascript'> window.onload = function(){radalert('" & msg & "', 325, 150);}</" & "script>"
 
        Else        'Save record
            
            Dim sTarget As String = ""
            Dim nTargetID As Integer = 0
            Dim sAction As String = ""
            If butApprove.Checked Then
                sTarget = lstApproveTarget.SelectedItem.Text
                nTargetID = lstApproveTarget.SelectedItem.Value
                sAction = "Approved"
                If sTarget = "Final Approval" Then
                    sAction = "FinalApproval"
                End If
            End If
            If butReject.Checked Then
                sTarget = lstRejectTarget.SelectedItem.Text
                nTargetID = lstRejectTarget.SelectedItem.Value
                sAction = "Rejected"
            End If
            
            If Session("WorkflowRoleType") = "Bond Accountant" Then
                If chkApproveRetentionAmount.Checked Then
                    txtNotes.Text &= "<br>-----------<br>Retention Amount Approved."
                    'Else
                    '    If butApprove.Checked Then
                    '        If ViewState("TransactionRetentionAmount") > 0 Then
                    '            txtNotes.Text &= "<br>-----------<br>Retention Amount NOT Approved."
                    '        End If
                    '    End If
                    
                End If
            End If
 
                        
            Using db As New promptWorkflow
                With db
                    .CallingPage = Page
                    .Action = sAction
                    
                    .TransactionID = nRecID
                    .PADID = nRecID
                    .RecordType = sRecType
                    
                    .Target = sTarget
                    .TargetRoleID = nTargetID
                    
                    .FRSCheckMessageCode = lstFRSCheckMessageCode.SelectedValue
                    .FRSRetentionCheckMessageCode = lstFRSRetentionCheckMessageCode.SelectedValue
 
                    
                    If chkFRSCutSingleCheck.Checked = True Then
                        .FRSCutSingleCheck = "S"
                    End If
                    
                End With
                
                If sRecType = "PAD" Then
                    db.RoutePAD()
                Else
                    db.RouteTransaction()
                End If
                
            End Using
            
            If CalledFromDashboard = False Then  'only update parent form when called from within PROMPT
                lblAlert.Text = "<script>UpdateParentPage()</" + "script>"   'calls a function in parent form that updates control via ajax
                ProcLib.CloseOnlyRAD(Page)
            Else
                ProcLib.CloseAndRefreshRAD(Page)
            End If
            
        End If

    End Sub

    Protected Sub butClose_Click1(ByVal sender As Object, ByVal e As System.Web.UI.ImageClickEventArgs)
        
        ProcLib.CloseOnlyRAD(Page)
    End Sub

    Protected Sub butApprove_CheckedChanged(ByVal sender As Object, ByVal e As System.EventArgs)
        If butApprove.Checked Then
            lstWorkflowRejectReason.Visible = False
        Else
            lstWorkflowRejectReason.Visible = True
        End If
    End Sub

    Protected Sub butReject_CheckedChanged(ByVal sender As Object, ByVal e As System.EventArgs)
        
        If sRecType = "PAD" Then
            lblRetCheckCode.Visible = False
            lstFRSRetentionCheckMessageCode.Visible = False
                
            lblNotesReason.Visible = False
            lstWorkflowRejectReason.Visible = False
  
        Else
            
            If DirectCast(sender, RadioButton).Checked Then
                lblRetCheckCode.Visible = False
                lstFRSRetentionCheckMessageCode.Visible = False
                
                lblNotesReason.Visible = True
                lstWorkflowRejectReason.Visible = True
            Else
                lblRetCheckCode.Visible = False
                lstFRSRetentionCheckMessageCode.Visible = False
                lblNotesReason.Visible = False
                lstWorkflowRejectReason.Visible = False
            End If
        End If
  
       
    End Sub

    'Protected Sub butFinalApproval_Click(ByVal sender As Object, ByVal e As System.EventArgs) Handles butFinalApproval.Click

    '    'this only shows if the approver is last in the approval chain
    '    If sRecType = "PAD" And bIsFinalApprover.Value = "Yes" Then        'Approve the PAD

    '        Using db As New promptWorkflow
    '            With db
    '                .CallingPage = Page
    '                .Action = "FinalApproval"
    '                .PADID = nRecID
    '                .RecordType = "PAD"
    '                .RoutePAD()
    '            End With

    '        End Using

    '    End If

    '    If CalledFromDashboard = False Then  'only update parent form when called from within PROMPT
    '        lblAlert.Text = "<script>UpdateParentPage()</" + "script>"   'calls a function in parent form that updates control via ajax
    '        ProcLib.CloseOnlyRAD(Page)
    '    Else
    '        ProcLib.CloseAndRefreshRAD(Page)
    '    End If

    'End Sub
</script>

<html>
<head>
    <title>Route Transaction</title>
    <link href="Styles.css" type="text/css" rel="stylesheet" />

    <script type="text/javascript" language="javascript">

        function GetRadWindow() {
            var oWindow = null;
            if (window.RadWindow) oWindow = window.RadWindow;
            else if (window.frameElement.radWindow) oWindow = window.frameElement.radWindow;
            return oWindow;
        }


        function confirmCallBackFn(arg) {
            alert(arg);
        }

        function promptCallBackFn(arg) {
            alert(arg);
        }

        function UpdateParentPage()
        //This call is used when record saved to update specific control on calling page -
        //in this case it is the HandleAjaxPostbackFromWorkflowPopup method on the calling page
        {
            GetRadWindow().BrowserWindow.HandleAjaxPostbackFromWorkflowPopup();
        }

    </script>

</head>
<body>
    <form id="Form1" method="post" runat="server">
    <telerik:RadScriptManager ID="RadScriptManager1" runat="server" />
    <asp:Panel ID="panelApproval" Style="z-index: 112; left: 16px; position: absolute;
        top: 3px; height: 347px; width: 441px;" runat="server">
        <asp:Label ID="lblNotesReason" Style="z-index: 100; left: 13px; position: absolute;
            top: 216px" runat="server" Height="24px">Notes/Reason:</asp:Label>
        &nbsp;
        <asp:Label ID="lblRetCheckCode" runat="server" Height="24px" Style="z-index: 102;
            left: 5px; position: absolute; top: 182px" Visible="False">Ret Check Memo:</asp:Label>
        <asp:Label ID="lblCheckCode" runat="server" Height="24px" Style="z-index: 102; left: 9px;
            position: absolute; top: 145px" Visible="False">Check Memo:</asp:Label>
        &nbsp; &nbsp; &nbsp; &nbsp; &nbsp;&nbsp;
        <asp:HyperLink ID="butHelp" runat="server" ImageUrl="images/button_help.gif" Style="z-index: 103;
            left: 349px; position: absolute; top: 8px">HyperLink</asp:HyperLink>
        <asp:TextBox ID="txtNotes" Style="z-index: 103; left: 16px; position: absolute; top: 244px;
            height: 51px;" TabIndex="1" runat="server" CssClass="EditDataDisplay" TextMode="MultiLine"
            Width="383px"></asp:TextBox>
        &nbsp; &nbsp;&nbsp;
        <asp:ImageButton ID="butClose" runat="server" ImageUrl="images/button_cancel.gif"
            Style="z-index: 105; left: 306px; position: absolute; top: 304px" TabIndex="6"
            OnClick="butClose_Click1" />
        <asp:ImageButton ID="butSave" runat="server" ImageUrl="images/button_route.gif" Style="z-index: 106;
            left: 13px; position: absolute; top: 304px" TabIndex="6" OnClick="butSave_Click" />
            
  <%--      <asp:Button ID="butFinalApproval" runat="server"  Style="z-index: 106;
            left: 124px; position: absolute; top: 305px; height: 28px; width: 136px;" 
            TabIndex="6" Text="Give Final Approval" ToolTip="Click this button to give final approval to this item." />--%>
        
        <asp:DropDownList ID="lstRejectTarget" runat="server" CssClass="EditDataDisplay"
            Style="z-index: 107; left: 43px; position: absolute; top: 89px; width: 266px;">
        </asp:DropDownList>
        <asp:DropDownList ID="lstApproveTarget" runat="server" CssClass="EditDataDisplay"
            Style="z-index: 108; left: 40px; position: absolute; top: 27px; width: 269px;
            height: 21px;">
        </asp:DropDownList>
        <asp:DropDownList ID="lstFRSCheckMessageCode" runat="server" CssClass="EditDataDisplay"
            Style="z-index: 108; left: 105px; position: absolute; top: 143px; height: 17px;
            width: 168px;">
        </asp:DropDownList>
        <asp:DropDownList ID="lstFRSRetentionCheckMessageCode" runat="server" CssClass="EditDataDisplay"
            Style="z-index: 108; left: 107px; position: absolute; top: 181px; height: 16px;
            width: 158px;">
        </asp:DropDownList>
        <asp:DropDownList ID="lstWorkflowRejectReason" runat="server" CssClass="EditDataDisplay"
            Style="z-index: 109; left: 97px; position: absolute; top: 214px" Width="125px"
            Visible="False">
            <asp:ListItem></asp:ListItem>
            <asp:ListItem>Damaged</asp:ListItem>
            <asp:ListItem>Wrong</asp:ListItem>
        </asp:DropDownList>
        <asp:RadioButton ID="butApprove" runat="server" GroupName="Routing" Style="z-index: 110;
            left: 7px; position: absolute; top: 5px" Text="Approve this transaction and route to:"
            AutoPostBack="True" OnCheckedChanged="butApprove_CheckedChanged" Checked="True" />
        <asp:RadioButton ID="butReject" runat="server" GroupName="Routing" Style="z-index: 111;
            left: 7px; position: absolute; top: 58px" Text="Reject this transaction and route to:"
            AutoPostBack="True" OnCheckedChanged="butReject_CheckedChanged" />
        <asp:CheckBox ID="chkFRSCutSingleCheck" runat="server" Style="z-index: 111; left: 294px; position: absolute;
            top: 189px" Text="Cut Single Check" />
        <asp:CheckBox ID="chkApproveRetentionAmount" Style="z-index: 111; left: 296px; position: absolute;
            top: 217px" runat="server" Text="Retention Amount Ok" />
    </asp:Panel>
    <telerik:RadWindowManager ID="RadPopups" runat="server" Skin="Office2007">
    </telerik:RadWindowManager>
    <%--for handling alerts and ajax callback--%>
    <asp:Label ID="lblAlert" runat="server" Height="24px" Style="z-index: 112; left: 32px;
        position: absolute; top: 328px"></asp:Label>
    <asp:Panel ID="panelReRoute" Style="z-index: 112; left: 19px; position: absolute;
        top: 527px; height: 215px; width: 449px;" runat="server" Visible="False">
        <asp:ImageButton ID="butSave0" runat="server" ImageUrl="images/button_route.gif"
            OnClick="butSave_Click" Style="z-index: 106; left: 15px; position: absolute;
            top: 166px" TabIndex="6" />
        <asp:ImageButton ID="butClose0" runat="server" ImageUrl="images/button_cancel.gif"
            OnClick="butClose_Click1" Style="z-index: 105; left: 322px; position: absolute;
            top: 164px" TabIndex="6" />
        <asp:Label ID="lblReRoute" runat="server" Height="24px" Style="z-index: 102; left: 10px;
            position: absolute; top: 9px" Visible="False">ReRoute this transaction without Approval or Rejection to:</asp:Label>
        <asp:DropDownList ID="lstApproveTarget0" runat="server" CssClass="EditDataDisplay"
            Style="z-index: 108; left: 10px; position: absolute; top: 30px; width: 243px;">
        </asp:DropDownList>
        <asp:Label ID="lblNotesReason0" runat="server" Height="24px" Style="z-index: 100;
            left: 10px; position: absolute; top: 60px">Notes:</asp:Label>
        <asp:TextBox ID="txtNotes0" runat="server" CssClass="EditDataDisplay" Height="60px"
            Style="z-index: 103; left: 11px; position: absolute; top: 88px" TabIndex="1"
            TextMode="MultiLine" Width="383px"></asp:TextBox>
    </asp:Panel>
    
    <asp:HiddenField ID="bIsFinalApprover" runat="server" Value="No" />
    
    
    </form>
</body>
</html>
