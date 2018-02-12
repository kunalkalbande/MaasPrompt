<%@ Page Language="vb" %>

<%@ Register Assembly="Telerik.Web.UI" Namespace="Telerik.Web.UI" TagPrefix="telerik" %>
<%@ Import Namespace="Prompt" %>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">

<script runat="server">
    
    '**** Notes *******
    ' This screen uses AJAX extensively which can be tricky. Some documentation:
    '
    ' Workflow Update - the workflow screen (routing) is called in a RAD popup window. This window allows
    ' users to route the transaction (approve/reject) to next person in workflow.
    ' Once transaction is assigned to new person workflow status is updated. To get this to work via 
    ' Ajax and prevent entire transaction screen from relaod once workflow status is updated, several steps
    ' are required in both the calling page (this one) and the popup window (workflow_route):
    '
    ' In calling page:
    '   1. Add hidden button to handle a click event
    '   2. Change Ajax setting in RADAJaxManager to designate what control gets updated when this click event is fired
    '   3. Add Jscript function to handle call from popup page
    '   4. Add click event for #1 above and code to execute.
    '
    '   In Popup:
    '   1. Add dummy label control (blank) to assign dynamic jscript to - this can also be used to handle alert windows as is the 
    '       case in the workflow popup window.
    '   2. Add JScript funciton to call the #3 item in the "calling page" list above.
    '   3. On post back inject jscript into text property of alert button to initiate sequence (call alert or calling page function)
    '
    '   NOTE: The above has also been implemeted for the linked attachments popup
    '
    '
   
    Private ContractID As Integer = 0
    Private TransID As Integer = 0
    Private ProjectID As Integer = 0
    Private RetentionPercent As Double = 0
    Private dLastFiscalYearEnd As Date
    Private bEnabled As Boolean = True
    
    Private bAllowObjectCodeChange As Boolean = False
    Private bTurnOffValidation As Boolean = False
    Private bDisableObjectCodeFilter As Boolean = False   'used for legacy conversion to allow change/assignment of object code
    
    'for custom JCAF column names if used
    Private sDonationColumnName As String = ""
    Private sHazmatColumnName As String = ""
    Private sGrantColumnName As String = ""
    Private sMaintColumnName As String = ""
     
    Private sAssignedWorkflowRoleType As String = ""    'to hold currently assigned workflow role type for this transaction
    Private nTransactionTotal As Double = 0

    Private Sub Page_Load(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MyBase.Load
          
        If ProcLib.CheckExpiredSessionForPopup(Page) Then    'session died so close the page - this is to prevent orphaned popups
            ProcLib.CloseAndRefresh(Page)
        End If
        

        Page.ClientScript.RegisterHiddenField("__EVENTTARGET", butSave.ClientID)
        
        'roy 9/21/10: used by javascript on this page to produce a popup for FHDA
        Page.ClientScript.RegisterHiddenField("thisDistrictID", Session("DistrictID"))

        lblMessage.Text = ""
        lblAllocationMessage.Text = ""
 
      
        TransID = Request.QueryString("ID")
        ProjectID = Request.QueryString("ProjectID")
        ContractID = Request.QueryString("ContractID")
        
        If Request.QueryString("CollegeID") <> "" Then   'HACK - incase this screen is called from dashboard or search need to set session var college id
            Session("CollegeId") = Request.QueryString("CollegeID")
        End If
 
        
        'Get the parent contract info and validation flags
        Using db As New promptTransaction
            db.CallingPage = Page

            db.SetParentContract(ContractID)
            ProjectID = db.ParentContract.ProjectID
            
            bDisableObjectCodeFilter = db.DisableObjectCodeFilter
            bAllowObjectCodeChange = db.AllowObjectCodeChange
            
            bTurnOffValidation = db.TurnOffValidation
            If db.IsPassthroughProject(ProjectID) Then   'turn off validation for passthrough projects
                bTurnOffValidation = True
            End If
        End Using
        
        'lstObjectCode.Enabled = False
  
          
        'Configure visiblility of Workflow Panel if enabled                    
        If HttpContext.Current.Session("EnableWorkflow") = "1" Then
            lblWorkflowScenerio.Visible = True
            lstxWorkflowScenerioID.Visible = True
            panelWorkflow.Visible = True
        Else                'turn off workflow info
            panelWorkflow.Visible = False
            lblWorkflowScenerio.Visible = False
            lstxWorkflowScenerioID.Visible = False
        End If
 
        If IsPostBack And Session("passback") = "" Then   'only do the following on post back or pass back
            TransID = lblID.Text
        Else  'only do the following on first load
 
            Using db As New promptTransaction
                db.CallingPage = Page

                If Request.QueryString("new") = "Inv" Then    'load new record for add
                    db.GetNewTransaction(ContractID)   'loads default values to record from parent contract
                    ProjectID = db.ParentContract.ProjectID
                    TransID = 0
                    lnkShowLastUpdateInfo.Visible = False

                    butFlag.Visible = False
                    panelWorkflow.Visible = False     'hide workflow on new transaction

                Else     'Existing transaction so slightly different configration
                                       
                    'load existing transaction record
                    db.GetExistingTransaction(TransID, ContractID)   'loads existing trans record
     
                    'txtComments.ToolTip = txtComments.Text
                    
                    lstxWorkflowScenerioID.SelectedValue = db.WorkflowScenerioID
                    nTransactionTotal = db.TotalGrossAmount
            
                    LoadLinkedAttachments()
                    
                    GetCurrentWorkflowStatus()
                    
                    'Configure the RAD LastUpdate Popup for existing transaction
                    SetUpRadWindowsForExistingTransaction()
 
                    lnkShowLastUpdateInfo.Attributes("onclick") = "return ShowLastUpdateInfo(this,'" & TransID & "','Transaction');"
                    lnkShowLastUpdateInfo.NavigateUrl = "#"
                    
                    butFlag.Attributes("onclick") = "return ShowFlag('" & TransID & "');"
                    butFlag.NavigateUrl = "#"
                    
                End If
                
                               
                lblID.Text = TransID
                dLastFiscalYearEnd = db.ParentContract.LastFiscalYearEnd
                
                
                                 
            End Using
            
            'Set up workflow buttons              
            lnkShowWorkflowHistory.Attributes("onclick") = "return ShowWorkflowHistory('" & TransID & "');"
            lnkShowWorkflowHistory.NavigateUrl = "#"
   
            SetUpRadWindows()
            
 
            'set up help button
            Session("PageID") = "TransactionEdit"
            butHelp.Attributes("onclick") = "return ShowHelp();"
            butHelp.NavigateUrl = "#"
          
            'set up attachments button
            lnkManageAttachments.Attributes("onclick") = "return ManageAttachments('" & TransID & "','Transaction');"
            lnkManageAttachments.NavigateUrl = "#"
            
           
            'HACK --------
                       
            If Session("DistrictID") <> 55 Then  ' only for fhda now
                lstCode1099.Visible = False
                lbl1099code1.Visible = False
                
                lstVerified.Visible = False
                lblVerified1.Visible = False
            End If
                                
            ViewState.Add("OldStatusValue", lstStatus.SelectedValue)
            'statusOldValue.Value = lstStatus.SelectedValue    'to save value for validation
            
            txtInvoiceDate.Focus()
             
        End If

        'Lock Down for Read Only
        If IsDate(txtInvoiceDate.SelectedDate) Then
            If txtInvoiceDate.SelectedDate <= dLastFiscalYearEnd Then  'locks down controls if appropriate
                bEnabled = False
                lblMessage.Text = "Note: Transaction is View Only because Invoice Date is in past Fiscal Year."
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
        
        'NOTE -  we may want to enhance this so cannot change transactions submitted to district or Paid.
        'If lstStatus.SelectedValue = "Payment Pending" Or lstStatus.SelectedValue = "Paid" Then
        '    bEnabled = False
        'End If
       
  
        BuildAllocationTable() 'NOTE: WE Do this here so we can tell if read only page before creating allocation cells

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
                If TypeOf cc Is Telerik.Web.UI.RadComboBox Then
                    CType(cc, Telerik.Web.UI.RadComboBox).Enabled = False
                End If
            Next

            lnkOverride.Visible = False
            butSave.ImageUrl = "images/button_close.gif"
            
            lnkManageAttachments.Visible = False
            
        End If

        'Set Due Date if not set already
        If Not IsDate(txtDueDate.SelectedDate) Then
            txtDueDate.SelectedDate = Format(DateAdd(DateInterval.Day, 30, Now), "MM/dd/yyyy")
        End If
        
        
        'HACK - hide bond series drop down and make visible checkdate for SJE
        If Session("DistrictID") = 67 Then
            lstBondSeries.Visible = False
            lblBondSeriesLabel.Visible = False
            
            lblCheckDateLabel.Visible = True
            txtCheckDate.Visible = True
            
        Else
            lstBondSeries.Visible = True
            lblBondSeriesLabel.Visible = True
            
            lblCheckDateLabel.Visible = False
            txtCheckDate.Visible = False
            
        End If
       
        
        
 
    End Sub
    
    Private Sub GetCurrentWorkflowStatus()
        
        If HttpContext.Current.Session("EnableWorkflow") = "1" Then       'get the limits and flags for approval amounts

            lstxWorkflowScenerioID.Enabled = True
            
            Dim bMaxWorkflowApprovalOk As Boolean = False
            Dim nMaxWorkflowApprovalAmount As Double = 0
        
            Using rs As New promptWorkflow
                lblCurrentWorkflowOwner.Text = rs.GetCurrentWorkflowOwner("Transaction", TransID)
                sAssignedWorkflowRoleType = rs.TransactionWorkflowRoleType

                Dim WorkflowScenerioID As Integer = 0
                If lstxWorkflowScenerioID.Items.Count > 0 Then
                    WorkflowScenerioID = lstxWorkflowScenerioID.SelectedValue
                End If
                
                nTransactionTotal = rs.TransactionTotalAmount
                
                Dim nmax As Double = rs.GetMaxApprovalLevel(WorkflowScenerioID)
                If nmax >= nTransactionTotal Then
                    bMaxWorkflowApprovalOk = True
                End If
         
                If rs.IsCurrentlyInWorkflow Then  'Check if in workflow already and if so disable scenerio selection
                    lstxWorkflowScenerioID.Enabled = False
                Else
                    lstxWorkflowScenerioID.Enabled = True
                End If
                       
                If lstxWorkflowScenerioID.Items.Count = 0 Then
                    If lstStatus.Text <> "Paid" Then
                        lblMessage.Text = "Warning: To enable workflow, please assign scenerio(s) to parent contract."
                        lblMessage.Visible = True
                        lstxWorkflowScenerioID.Enabled = False
                    End If
        
                ElseIf bMaxWorkflowApprovalOk = False Then
                    If lstStatus.SelectedItem.Text <> "Paid" Then
                        lblMessage.Text = "Warning: Transaction amount is " & FormatCurrency(nTransactionTotal) & " but Workflow Scenario has limit of " & FormatCurrency(nMaxWorkflowApprovalAmount)
                        lblMessage.Visible = True
                        lstxWorkflowScenerioID.Enabled = True
                    End If
                
                ElseIf lstStatus.SelectedItem.Text = "Paid" Or lblCurrentWorkflowOwner.Text = "Complete" Then   'disable
                    lstxWorkflowScenerioID.Enabled = False
                
                End If
            
 
            End Using
        
                    
        End If
        
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
                    li.Attributes("ondblclick") = "return OpenAttachment('" & li.Value & "');"   'NOTE:Does not work in IE for some reason
                    lstAttachments.Items.Add(li)
                Next

            Else '
                If HttpContext.Current.Session("EnableWorkflow") = "1" Then   'turn off workflow info
                    lstAttachments.Items.Add("(To EnableWorkflow Attach Invoice)")
                    
                Else
                    lstAttachments.Items.Add("No Attachments Found")
                End If
                
            End If
        End Using
        
 
       
    End Sub
    
 
    
    Private Sub SetUpRadWindowsForExistingTransaction()
        With RadPopups
            .Skin = "Office2007"
            .VisibleOnPageLoad = False
                         
            Dim ww As New Telerik.Web.UI.RadWindow
            ww = New Telerik.Web.UI.RadWindow
            With ww
                .ID = "OpenAttachmentWindow"
                .NavigateUrl = ""
                .Title = "Open Attachment"
                .Width = 500
                .Height = 300
                .Top = 200
                .Left = 20
                .Modal = False
                .VisibleStatusbar = False
                .ReloadOnShow = True
                .Behaviors = WindowBehaviors.Close + WindowBehaviors.Move
            End With
            .Windows.Add(ww)
                        
                        
            ww = New Telerik.Web.UI.RadWindow
            With ww
                .ID = "ShowLastUpdateInfo"
                .NavigateUrl = ""
                .Title = ""
                .Width = 350
                .Height = 150
                .Top = 200
                .Left = 20
                .Modal = False
                .VisibleStatusbar = False
                .ReloadOnShow = True
                .Behaviors = WindowBehaviors.Close + WindowBehaviors.Move
            End With
            .Windows.Add(ww)
                        
            ww = New Telerik.Web.UI.RadWindow
            With ww
                .ID = "ShowWorkflowHistory"
                .NavigateUrl = ""
                .Title = ""
                .Width = 550
                .Height = 250
                .Top = 200
                .Left = 20
                .Modal = False
                .VisibleStatusbar = False
                .ReloadOnShow = True
                .Behaviors = WindowBehaviors.Close + WindowBehaviors.Move
            End With
            .Windows.Add(ww)
                        
            ww = New Telerik.Web.UI.RadWindow
            With ww
                .ID = "ShowRouteTransaction"
                .NavigateUrl = ""
                .Title = ""
                .Width = 500
                .Height = 300
                .Top = 200
                .Left = 20
                .Modal = False
                .VisibleStatusbar = False
                .ReloadOnShow = True
                .Behaviors = WindowBehaviors.Close + WindowBehaviors.Move
            End With
            .Windows.Add(ww)
                        
            'Configure Flag Window
            ww = New Telerik.Web.UI.RadWindow
            With ww
                .ID = "ShowFlag"
                .NavigateUrl = ""
                .Title = ""
                .Width = 500
                .Height = 275
                .Top = 200
                .Left = 20
                .Modal = False
                .VisibleStatusbar = False
                .ReloadOnShow = True
                .Behaviors = WindowBehaviors.Close + WindowBehaviors.Move
            End With
            .Windows.Add(ww)

        End With
    End Sub
    
    Private Sub SetUpRadWindows()
        With RadPopups
            .Skin = "Office2007"
            .VisibleOnPageLoad = False
            Dim ww As New Telerik.Web.UI.RadWindow
            With ww
                .ID = "ShowHelp"
                .NavigateUrl = ""
                .Title = ""
                .Width = 450
                .Height = 550
                .Top = 20
                .Left = 20
                .Modal = False
                .VisibleStatusbar = False
                .ReloadOnShow = True
                .Behaviors = WindowBehaviors.Close + WindowBehaviors.Move
            End With
            .Windows.Add(ww)
           
                    
            ww = New Telerik.Web.UI.RadWindow
            With ww
                .ID = "ShowJCAFNotes"
                .NavigateUrl = ""
                .Title = ""
                .Width = 350
                .Height = 350
                .Top = 200
                .Left = 20
                .Modal = False
                .VisibleStatusbar = False
                .ReloadOnShow = True
                .Behaviors = WindowBehaviors.Close + WindowBehaviors.Move
            End With
            .Windows.Add(ww)
                
            ww = New Telerik.Web.UI.RadWindow
            With ww
                .ID = "ManageAttachments"
                .NavigateUrl = ""
                .Title = ""
                .Width = 500
                .Height = 450
                .Top = 200
                .Left = 20
                .Modal = False
                .VisibleStatusbar = False
                .ReloadOnShow = True
                .Behaviors = WindowBehaviors.Close + WindowBehaviors.Move
            End With
            .Windows.Add(ww)
           
 
        End With
    End Sub
    
    Private Sub BuildAllocationTable()
   
        With tblAlloc
            .Rows.Clear()
            .Width = Unit.Percentage(95)
        End With

        Dim r1 As New TableRow
        Dim r1c1 As New TableCell

        With r1c1
            .Text = "<b><u>Allocation</b></u>"
            .ColumnSpan = 4
            .HorizontalAlign = HorizontalAlign.Center
            .CssClass = "smalltext"
        End With
        r1.Cells.Add(r1c1)
        tblAlloc.Rows.Add(r1)


        'build header row
        Dim r2 As New TableRow
        Dim r2c1 As New TableCell
        Dim r2c1a As New TableCell
        Dim r2cLineNo As New TableCell
        Dim r2c2 As New TableCell
        Dim r2c2a As New TableCell
        Dim r2c2aa As New TableCell
        Dim r2c3 As New TableCell
        Dim r2c4 As New TableCell

        r2c1.Width = Unit.Percentage(60)
        r2c1.Text = "Contract Line/CO Description"
        r2c1.ToolTip = "Contract Line Item or Change Order amount."
        r2.Cells.Add(r2c1)
        
        r2c1a.Width = Unit.Pixel(3)
        r2c1a.Text = "T"
        r2c1a.ToolTip = "CL for Line Item or CO for Change Order Line"
        r2.Cells.Add(r2c1a)
        
        r2cLineNo.Width = Unit.Pixel(3)
        r2cLineNo.Text = "#"
        r2cLineNo.ToolTip = "PO Line #"
        r2.Cells.Add(r2cLineNo)

        r2c2.Width = Unit.Percentage(8)
        r2c2.Text = "Source"
        r2c2.ToolTip = "Funding source in JCAF for this amount."
        r2.Cells.Add(r2c2)
        
        r2c2aa.Width = Unit.Pixel(15)
        r2c2aa.Text = "ObjectCode"
        r2.Cells.Add(r2c2aa)
        
        r2c2a.Width = Unit.Pixel(3)
        r2c2a.Text = "Rmb"
        r2c2a.ToolTip = "R indicates amount is allocated to a Reimbursable Contract Line."
        r2.Cells.Add(r2c2a)

        r2c3.Width = Unit.Pixel(70)
        r2c3.Text = "Amount"
        r2c3.HorizontalAlign = HorizontalAlign.Right
        r2.Cells.Add(r2c3)

        r2c4.Width = Unit.Pixel(125)
        r2c4.Text = "Avail Amt"
        r2c4.Wrap = False
        r2c4.HorizontalAlign = HorizontalAlign.Right
        r2c4.ToolTip = "This is the remaining balance allocated to Contract Line Item. P indicates that amount is Pending Approval."
        r2.Cells.Add(r2c4)

        r2.CssClass = "smalltext"
        r2.BackColor = Color.Silver

        tblAlloc.Rows.Add(r2)

        Dim sCurrGroup As String = ""

        'Get the Detail Items for this Transaction
        Dim rsDet As DataTable
        'Dim rsAlloc As DataTable
        Using db As New promptTransaction
            db.CallingPage = Page
            db.SetParentContract(ContractID)
            db.SetDistrictValidationFlags()
            
            rsDet = db.GetTransactionDetailRecords(TransID, ContractID)  'get  existing detail records with associated contract line items
   

            RetentionPercent = db.ParentContract.RetentionPercent  'same for all records as stored in contract record
            AllocationRetPercent.Value = RetentionPercent   'hidden field for javascript calcs
            
            
        End Using
  
        For Each row As DataRow In rsDet.Rows()
 
            Dim bHide As Boolean = False
            If row("RemainingAvailableAmount") < 0 And row("Amount") = 0 Then
                bHide = True
            End If
            
            
            If Not bHide Then
                        
                'build detail row
                Dim r4 As New TableRow
                Dim r4c1 As New TableCell
                Dim r4c1a As New TableCell
                Dim r4cLineNo As New TableCell
                Dim r4c2 As New TableCell
                Dim r4c2aa As New TableCell
                Dim r4c2a As New TableCell
                
                Dim r4c3 As New TableCell
                Dim r4c4 As New TableCell
      
        
                'add the contract line description
                With r4c1
                    .Wrap = True
                    .Text = row("Description") & " - " & Left(row("JCAFLine"), 15) & "..."
                    .ToolTip = row("Description") & " - " & row("JCAFLine")
                    .ForeColor = Color.DarkBlue
                End With
            
                ''Check for Notes and add link to description if present -- NOTE: ONly in ObjectCodeFiltered status
                'If bDisableObjectCodeFilter = False Then
                '    Dim strNote As String = Trim(ProcLib.CheckNullDBField(row("Note")))
                '    If strNote <> "" Then   'there is a note so add the image and hover window code
                '        Dim strNoteParms As String = "Notes:" & ProjectID & ":" & row("ColumnName")    'concatonate the popup type, projectID and field name to use for hover window parm
                '        Dim strNoteLink As String = ""
                '        strNoteLink = "<span id='qqq1' onclick=""return ShowJCAFNotes('" & strNoteParms & "')"";>"
                '        strNoteLink = strNoteLink & "<img src='images/prompt_note.gif' width='15' height='14'></span>"

                '        r4c1.Text = r4c1.Text & "&nbsp;&nbsp" & strNoteLink
                '    End If
                'End If
                Dim stype As String = row("LineType")
                With r4c1a
                    .Width = Unit.Pixel(3)
                    .ToolTip = stype
                    If stype = "Contract" Then
                        stype = "CL"
                    Else
                        stype = "CO"
                    End If
                    .Text = stype
                    .ForeColor = Color.DarkBlue
                End With
                
                With r4cLineNo
                    .Text = IIf(IsDBNull(row("POLineNumber")), "", row("POLineNumber"))
                    .ForeColor = Color.DeepSkyBlue
                End With
            
                With r4c2
                    .Text = row("Source")
                    .ForeColor = Color.DarkBlue
                End With
            
                With r4c2a    'reimb line
                    If ProcLib.CheckNullNumField(row("Reimbursable")) = 1 Then
                        .Text = "R"
                    Else
                        .Text = " "
                    End If
                
                    .ForeColor = Color.DarkBlue
                End With
                
                With r4c2aa    'reimb line
                    .Text = row("ObjectCode")
                    .ForeColor = Color.DarkBlue
                End With

                Dim ctrlEdit As New Telerik.Web.UI.RadNumericTextBox 'create text box and fill with current value
                With ctrlEdit
                
                    If Not bTurnOffValidation Then
                        .ClientEvents.OnValueChanging = "CheckAllocation"            'to test that amount entered is not > than element remaining bal
                    Else
                        .ClientEvents.OnValueChanged = "RecalcOnly"                 'just recalc
                    End If

                    .ID = "txxt" & row("ContractLineItemID")
                    .Attributes.Add("ContractLineItemID", row("ContractLineItemID"))
                    .Attributes.Add("Reimbursable", row("Reimbursable"))
                    .Attributes.Add("Pending", row("Pending"))
                    .Attributes.Add("JCAFCellName", row("ColumnName"))
                    
                    .Attributes.Add("AccountNumber", proclib.CheckNullDBField(row("AccountNumber")))
                                        
                    .Width = Unit.Point(65)
                    .TabIndex = 99
                   
                    .Text = FormatNumber(row("Amount"), 2, TriState.False, TriState.False, TriState.False)
                      
                    'NOTE: we should look at validation for chaning paid transaction!!!
                    'If lstStatus.SelectedItem.Text = "Paid" And row("Pending") = "Y" Then
                    '    .Enabled = False
                    'Else
                    .Enabled = bEnabled
                    'End If
                    
                    .Type = Telerik.Web.UI.NumericType.Currency
                
                End With

                'add ajax support to this control
                'RadAjaxManager1.AjaxSettings.AddAjaxSetting(RadAjaxManager1, ctrlEdit, Nothing)
            
                With r4c3
                    .Controls.Add(ctrlEdit)
                    .HorizontalAlign = HorizontalAlign.Right
                End With
            
                'build aval alloc label
                Dim nBal As Double = 0
            
                nBal = row("RemainingAvailableAmount")
            
                'If bDisableObjectCodeFilter = False Then
                '    nBal = row("RemainingAllocBalance")
                'Else
                '    nBal = row("BudgetAmount") - IIf(IsDBNull(row("TransTotal")), 0, row("TransTotal"))
                'End If
 
                Dim ctrlBal As New HyperLink
        
                With ctrlBal
                    .Text = FormatCurrency(nBal)
                    
                    If row("Pending") = "Y" Then
                        .Text = .Text & "(P)"
                        .ForeColor = Color.OrangeRed
                        .ToolTip = "This is the remaining balance allocated to Contract Line Item. P indicates that amount is Pending Approval."
                    Else
                        .ToolTip = "This is the remaining balance allocated to Contract Line Item."
                    End If
                    
                    'If Not bTurnOffValidation Then
                    '    If Not IsDBNull(row("Check14DField")) Then      'Check 14D status
                    '        Dim s14Dfld As String = row("Check14DField")
                    '        If row(s14Dfld) <> "1" Then   '14D is not there for this field
                    '            .Text = .Text & " (14D!)"
                    '            ctrlEdit.Enabled = False
                    '            ctrlEdit.ToolTip = "You cannot allocate to this item until 14D is recieved."

                    '        End If
                    '    End If
                    'End If
                
                    '.NavigateUrl = "http://216.129.104.66/q34jf8sfa?/PromptReports/info_AllocationDetail&ProjID=" & ProjectID & "&bucket=" & row("ColumnName")
                    '.Target = "_blank"
                    If nBal < 0 Then
                        .ForeColor = Color.Red
                    End If
                    '.ID = "lnk" & row("ColumnName")
                    .ID = "lnk" & row("ContractLineItemID")

                    .Enabled = bEnabled

                End With
            
                'add ajax support to this control
                RadAjaxManager1.AjaxSettings.AddAjaxSetting(RadAjaxManager1, ctrlBal, Nothing)
            
                     
                With r4c4
                    .Controls.Add(ctrlBal)
                    .HorizontalAlign = HorizontalAlign.Right
                    .ToolTip = "This balance is the Contract Line Item Amount minus all posted transactions associated with this line item. "
                    .ToolTip = .ToolTip & "Click on this number for a report of all posted allocations."

                End With

                With r4
                    .Cells.Add(r4c1)
                    .Cells.Add(r4c1a)
                    .Cells.Add(r4cLineNo)
                    .Cells.Add(r4c2)
                    .Cells.Add(r4c2aa)
                    .Cells.Add(r4c2a)
                    
                    .Cells.Add(r4c3)
                    .Cells.Add(r4c4)
                    .CssClass = "ViewDataDisplay"
                End With

                tblAlloc.Rows.Add(r4)
            
            End If
            

        Next

        '------------- Totals ------------------
        Dim nGross As Double = 0
        Dim nRet As Double = 0
        Dim nPayable As Double = 0
        
        Dim nTaxAmount As Double = 0
        
        If TransID > 0 Then  'only get for existing
            Using db As New promptTransaction
                db.GetTransactionTotals(TransID)
                nGross = db.TotalGrossAmount
                nRet = db.TotalRetentionAmount
                nPayable = db.TotalPayableAmount
                nTaxAmount = db.TaxAmount
            End Using
        End If
   
        'build Totals rows
        Dim r5 As New TableRow
        Dim r5c1 As New TableCell

        With r5c1
            .Width = Unit.Percentage(100)
            .ColumnSpan = 7
            .Text = "<hr size=1>"
        End With

        r5.Cells.Add(r5c1)
        tblAlloc.Rows.Add(r5)

        'add gross amount
        Dim r6 As New TableRow
        Dim r6c1 As New TableCell
        Dim r6c1aaa As New TableCell
        Dim r6c1a As New TableCell
        Dim r6c1aa As New TableCell
        Dim r6c2 As New TableCell
        Dim r6c3 As New TableCell
        
        
        'Add the Tax Amount  
        
        Dim ctrlTax As New Telerik.Web.UI.RadNumericTextBox    'create text box
        With ctrlTax
            .ID = "txtTaxAdjustmentAmount"
            .Width = Unit.Point(65)
            .Text = FormatNumber(nTaxAmount, 2, TriState.False, TriState.False, TriState.False)
            .TabIndex = 99
            .Enabled = bEnabled
        End With
        
    
        
        With r6c1a
            .ColumnSpan = 1
            .HorizontalAlign = HorizontalAlign.Left
            .Text = ""
            .ForeColor = Color.DarkBlue
            .CssClass = "smalltext"
            
            Dim lblTax As New Label
            lblTax.Text = "Tax Adj Amount:"
            .Controls.Add(lblTax)
            .Controls.Add(ctrlTax)
        End With

   
        
        
        'Add the Gross AMount
        With r6c1
            .ColumnSpan = 4
            .HorizontalAlign = HorizontalAlign.Right
            .Text = "Gross Amount:"
            .ForeColor = Color.DarkBlue
            .CssClass = "smalltext"
        End With

        Dim ctrlGross As New Telerik.Web.UI.RadNumericTextBox    'create text box
        With ctrlGross
            .ID = "txtTotalAmount"
            .Width = Unit.Point(65)
            .Text = FormatNumber(nGross, 2, TriState.False, TriState.False, TriState.False)
            .TabIndex = 99
            .Enabled = False
        End With
   
        
        'add ajax support to this control
        RadAjaxManager1.AjaxSettings.AddAjaxSetting(RadAjaxManager1, ctrlGross, Nothing)

        
        
        With r6c2
            .Controls.Add(ctrlGross)
            .HorizontalAlign = HorizontalAlign.Right
        End With
        With r6c3
            .Text = "."
            .HorizontalAlign = HorizontalAlign.Right
        End With
        With r6
            .Cells.Add(r6c1a)
            .Cells.Add(r6c1)
            .Cells.Add(r6c2)
            .Cells.Add(r6c3)
        End With
        tblAlloc.Rows.Add(r6)

        'add Retention amount
        Dim r7 As New TableRow
        Dim r7c1 As New TableCell
        Dim r7c2 As New TableCell
        Dim r7c3 As New TableCell
        With r7c1
            .ColumnSpan = 5
            .HorizontalAlign = HorizontalAlign.Right
            .ForeColor = Color.DarkBlue
            .CssClass = "smalltext"
        End With
        Dim ctrlRetPercent As New Label   'create number display for ret percentage
        With ctrlRetPercent
            .ID = "lblRetentionPercent"
            .Text = "Retention Amount (" & RetentionPercent & "%):"
            .CssClass = "smalltext"
        End With
 
        r7c1.Controls.Add(ctrlRetPercent)


        Dim ctrlRet As New Telerik.Web.UI.RadNumericTextBox    'create text box
        With ctrlRet
            .ID = "txtRetentionAmount"
            .Width = Unit.Point(65)
            .Text = FormatNumber(nRet, 2, TriState.False, TriState.False, TriState.False)
            .TabIndex = 99
            .ClientEvents.OnValueChanged = "RecalcRetentionChange" 'just recalc if control is enable which means user override
            .Enabled = False
        End With
 
   
        
        With r7c2
            .Controls.Add(ctrlRet)
            .HorizontalAlign = HorizontalAlign.Right
        End With

        'Get Retention Override
        Dim bRetOverride As Boolean = False
        Using rs1 As New PromptDataHelper
            With rs1
                'get retention percent
                .FillReader("SELECT AllowRetentionOverride FROM Transactions WHERE TransactionID = " & TransID)
                While .Reader.Read
                    If Not IsDBNull(.Reader("AllowRetentionOverride")) Then
                        bRetOverride = .Reader("AllowRetentionOverride")
                    End If
                End While
                .Reader.Close()
            End With
        End Using
        
        Dim ctrlRecalcRet As New CheckBox   'create recalc link
        With ctrlRecalcRet
            .ID = "chkAllowRetentionOverride"
            .Attributes("onclick") = "return EnableRetentionOverride(this);"
            .Checked = bRetOverride
            .Text = "Override"
            .CssClass = "smalltext"
            .ToolTip = "This will allow you to override the retention recalculation from the on the default percentage."
            .Enabled = bEnabled
        End With

        With r7c3
            .HorizontalAlign = HorizontalAlign.Left
            .Controls.Add(ctrlRecalcRet)
        End With


        With r7
            .Cells.Add(r7c1)
            .Cells.Add(r7c2)
            .Cells.Add(r7c3)
        End With
        tblAlloc.Rows.Add(r7)

        'add Payable amount
        Dim r8 As New TableRow
        Dim r8c1 As New TableCell
        Dim r8c2 As New TableCell
        Dim r8c3 As New TableCell
        With r8c1
            .ColumnSpan = 5
            .HorizontalAlign = HorizontalAlign.Right
            .Text = "Payable Amount:"
            .CssClass = "smalltext"
            .ForeColor = Color.DarkBlue
        End With

        Dim ctrlTot As New Telerik.Web.UI.RadNumericTextBox
        With ctrlTot
            .ID = "txtPayableAmount"
            .Width = Unit.Point(65)
            .Text = FormatNumber(nPayable, 2, TriState.False, TriState.False, TriState.False)
            .TabIndex = 99
            .Enabled = False
        End With
        
        RadAjaxManager1.AjaxSettings.AddAjaxSetting(RadAjaxManager1, ctrlTot, Nothing)

        With r8c2
            .Controls.Add(ctrlTot)
            .HorizontalAlign = HorizontalAlign.Right
        End With
        With r8c3
            .Text = "."
            .HorizontalAlign = HorizontalAlign.Right
        End With
        With r8
            .Cells.Add(r8c1)
            .Cells.Add(r8c2)
            .Cells.Add(r8c3)
        End With
        tblAlloc.Rows.Add(r8)

    End Sub

    Private Sub butSave_Click(ByVal sender As System.Object, ByVal e As System.Web.UI.ImageClickEventArgs) Handles butSave.Click

        If bEnabled = True Then  'save transaction

            Using db As New promptTransaction
                db.CallingPage = Page
                Dim sNewInvNumber As String = DirectCast(Form.FindControl("txtInvoiceNumber"), TextBox).Text
                Dim result As String = db.ValidateForDuplicateInvoiceNumber(txtInvoiceNumber.Text, TransID, ContractID)
                If result <> "" Then
                    lblMessage.Text = result
                    Exit Sub
                Else
                    db.SaveTransaction(TransID)
                End If
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
            'db.SoftDeleteTransaction(TransID)        
        End Using
        Session("RtnFromEdit") = True
        ProcLib.CloseAndRefresh(Page)
            
    End Sub

    Protected Sub lstStatus_SelectedIndexChanged(ByVal sender As Object, ByVal e As System.EventArgs)
        
        Dim msg As String = ""
        If Session("DistrictID") = 55 Then 'HACK - only for FHDA at the moment
            If lstStatus.SelectedValue = "FDO Approved" Then
           
                If txtInvoiceNumber.Text = "" Or Not IsDate(txtDueDate.SelectedDate) Or Not IsDate(txtInvoiceDate.SelectedDate) Then
                    msg = "Please enter an Invoice Number, Invoice Date, and Due Date to approve payment."
                Else
                    Using db As New promptTransaction
                        'If Not db.ValidateDistrictContractorID(lstContractorID.SelectedValue) Then
                        '    msg = "The Contractor you have selected must have a valid District Contractor ID assigned to it to approve payment."
                        'End If
                        
                        'check for valid retention account number and valid tax account number if needed
                        Dim ctrlTax As Telerik.Web.UI.RadNumericTextBox = Form.FindControl("txtTaxAdjustmentAmount")
                        Dim ctrlRet As Telerik.Web.UI.RadNumericTextBox = Form.FindControl("txtRetentionAmount")
                        
                        Dim ctrlAccountNumber As HiddenField = Form.FindControl("txtAccountNumber")
                        
                        Dim retamt As Double = ctrlRet.Value
                        Dim taxamt As Double = ctrlTax.Value
                        If retamt > 0 Or taxamt > 0 Then
                            'check that project has tax account and/or retention account assigned
                            Dim result As String = db.ValidateProjectRetentionAndTaxAccounts(ProjectID)
                            If taxamt > 0 And result.Contains("Tax") = False Then
                                msg = "Project Edit screen must have Tax Acct Assigned to approve payment."
                            End If
                            If retamt > 0 And result.Contains("Retention") = False Then
                                msg = "Project Edit screen must have Retention Acct Assigned to approve payment."
                            End If
                        End If
                        
                        'Transaction must have allocation lines from contract line items that have account numbers in them
                        If ctrlAccountNumber.Value = "" Then
                            msg = "The Contract Line Item(s) you have allocated from must have Account Number before FDO Approval."
                        End If
                        
                        'Transaction must be assigned to Workflow scenerio
                        If lstxWorkflowScenerioID.SelectedValue = 0 Then
                            msg = "Transaction must be assigned to workflow scenario before FDO Approval."
                        End If
                        
                        'If Scenario is FFE then check REcd date
                        If db.IsFFEScenario(lstxWorkflowScenerioID.SelectedValue) = True Then
                            If Not IsDate(txtFandEReceivedDate.SelectedDate) Then
                                msg = "FF&E Transactions must have a F and E Received date for FDO Approval"
                            End If
                            
                        End If

                    End Using
                End If
            End If
        End If
        
        If bTurnOffValidation = False Then
            If lstStatus.SelectedValue = "Paid" Then   'make sure proper fields entered
          
                If Not IsDate(txtDatePaid.SelectedDate) Or txtCheckNumber.Text = "" Then
                    msg = "Please enter a Paid Date and Check Number to mark as paid."
                End If

                For i As Integer = 0 To Request.Form.Count - 1             'iterate each of the returned forms controls
                    Dim fldname As String = Request.Form.AllKeys(i)
                    Dim colValue = Request.Form.GetValues(i)(0)
                    If colValue = "" Then
                        colValue = 0
                    End If
                    If Left(fldname, 4) = "txxt" Then  'get the detail items only that have values
                        If colValue <> 0 And (Not fldname.EndsWith("_text")) Then  'HACK to circumvent RadAjax issue with creating additional control that ends with _text

                            'get reference to the Amount control (NOTE: 07/2010  THIS is newer and cleaner methodolgy for accessing objects... will need to update rest of code later)
                            Dim objAmountBox As RadNumericTextBox = Form.FindControl(fldname)
                            If objAmountBox.Attributes("Pending") = "Y" Then
                                msg = "You cannot change status to Paid when amounts are allocated to Pending Change Order."
                            End If
                            
                            
                        End If
                    End If
                Next

            End If
        End If

        If msg <> "" Then    'error so return to old value and set focus and warn
            lblMessage.Text = msg
            lstStatus.SelectedValue = ViewState("OldStatusValue").ToString
            lstStatus.Focus()
        End If

        ViewState.Add("OldStatusValue", lstStatus.SelectedValue)
        
          
    End Sub

    Protected Sub lnkOverride_Click(ByVal sender As Object, ByVal e As System.EventArgs)
        'This allows the status to be changed
        lstStatus.Enabled = True
    End Sub
    

    Protected Sub AttachmentsPopup_AjaxHiddenButton_Click(ByVal sender As Object, ByVal e As System.EventArgs) Handles AttachmentsPopup_AjaxHiddenButton.Click
        'This is method used to handle the workflow popup close to update the linked attachments list 
        LoadLinkedAttachments()
       
    End Sub
    
    Protected Sub lstxWorkflowScenerioID_SelectedIndexChanged(ByVal sender As Object, ByVal e As System.EventArgs)
        
        If HttpContext.Current.Session("EnableWorkflow") = "1" And bEnabled = True Then   'Check to see if we need to enable
            If lstStatus.SelectedItem.Text <> "Paid" Then
                Dim nTransAmt As Double = DirectCast(Form.FindControl("txtTotalAmount"), Telerik.Web.UI.RadNumericTextBox).Value
                Dim result As String = ""
                Using rs As New promptTransaction
                    result = rs.UpdateWorkflowScenerio(TransID, lstxWorkflowScenerioID.SelectedValue, nTransAmt)
                
                    If result = "fail" Then
                        lblMessage.Text = "Warning: Selected Workflow Scenario does not contain Owner with appropriate approval level."
                        lblMessage.Visible = True
                    Else
                        lblMessage.Text = ""
                        lblMessage.Visible = False
                        lblCurrentWorkflowOwner.Text = rs.CurrentWorkflowOwner
                    End If
                End Using
                
                If lstStatus.SelectedValue = "FDO Approved" Then   'check that selection is not to none
                    If lstxWorkflowScenerioID.SelectedValue = 0 Then
                        lblMessage.Text = "Warning: FDO Approved Transactions must be assinged a Workflow Scenario."
                        lblMessage.Visible = True
                    End If
                End If
            End If
        End If
        
        GetCurrentWorkflowStatus()
      
    End Sub

   
   
</script>

<html>
<head>
    <title>Edit Transaction</title>
    <link href="Styles.css" type="text/css" rel="stylesheet" />
        
    <link href="js/jquery-ui.css" type="text/css" rel="Stylesheet" />
    <script src="js/jquery-1.4.2.min.js" type="text/javascript"></script>
    <script src="js/jquery-ui.1.8.2.min.js" type="text/javascript"></script>
    <script src="js/jquery.tools.min.js" type="text/javascript"></script>

    <telerik:RadCodeBlock ID="RadCodeBlock1" runat="server">

        <script type="text/javascript" language="javascript">
            // this is the actual script for loading the RAD window popup objects from attribute assigned to page elements

            function ShowLastUpdateInfo(oButton, id, rectype)     //for LastUpdate info display
            {

                var oWnd = window.radopen("show_last_update_info.aspx?ID=" + id + "&RecType=" + rectype, "ShowLastUpdateInfo");
                return false;
            }

            function ShowHelp()     //for help display
            {

                var oWnd = window.radopen("help_view.aspx?WinType=RAD", "ShowHelp");
                return false;
            }

            function ShowFlag(id)     //for Flag display
            {

                var oWnd = window.radopen("flag_edit.aspx?ParentRecID=" + id + "&ParentRecType=Transaction&WinType=RAD", "ShowFlag");
                return false;

            }

            function ShowWorkflowHistory(id)     //for Workflow History display
            {

                var oWnd = window.radopen("workflow_history_view.aspx?rectype=Transaction&recid=" + id, "ShowWorkflowHistory");
                return false;

            }



            function ShowJCAFNotes(parms)     //for jcaf notes 
            {

                var oWnd = window.radopen("budget_view_popup.aspx?parms=" + escape(parms), "ShowJCAFNotes");
                return false;
            }


            function ManageAttachments(id, rectype)     //for managing attachments 
            {

                var oWnd = window.radopen("attachments_manage_linked.aspx?ParentRecID=" + id + "&ParentType=" + rectype, "ManageAttachments");
                return false;
            }


            function OpenAttachment(id)     //for opening attachments 
            {

                var oWnd = window.radopen("attachment_get_linked.aspx?ID=" + id, "OpenAttachmentWindow");
                return false;
            }



            function DisableSave()     //for diabling save to allow recalc 
            {

                document.getElementById('butSave').disabled = true;

            }
            function EnableSave()     //for diabling save to allow recalc 
            {

                document.getElementById('butSave').disabled = false;

            }


            //For handling ajax post back from Attachment Manage RAD Popup
            function HandleAjaxPostbackFromAttachmentsPopup() {
                var oButton = document.getElementById("<%=AttachmentsPopup_AjaxHiddenButton.ClientID%>");
                oButton.click();

            }



            function CheckAllocation(sender, eventArgs) {

                // called by dynamic allocation textboxes to validate the entry and perform recalc
                var sCtrlID = sender.get_id();                      // get the current textbox control id
                var sNewVal = eventArgs.get_newValue();             // get the new value
                var sOldVal = eventArgs.get_oldValue();             // get the old value

                if (sOldVal == "") {                                // MAKE ZERO IF BLANK
                    sOldVal = 0;
                }
                if (sNewVal == "") {
                    sNewVal = 0;
                }

                var lnkCtrl = sCtrlID.replace("txxt", "lnk");       //get the name of the corresponding remaining bal link for this item
                var objRemBal = document.getElementById(lnkCtrl);          // get ref to the rem bal link control
                var nBalRem = objRemBal.innerHTML;                         // get the text in the hyperlink
                nBalRem = nBalRem.slice(1);                                  // remove $ start of string
                nBalRem = nBalRem.replace(/,/g, '');                           //remove commas if any -- the //g are regular expressions which mean all occurances
                var nNewRemainingAllocBal = parseFloat(nBalRem) + parseFloat(sOldVal) - parseFloat(sNewVal);

                if (nNewRemainingAllocBal < 0) {
                    alert('Sorry, the new amount entered would be greater than the remaining amount for the allocation line.');
                    eventArgs.set_cancel(true);
                    window.setTimeout(function() { sender.focus(); }, 50);
                    return false;
                }

                //Remaining bal on line is good, so check that change is not going below contract balance

                var objContractBal = document.getElementById('lblContractBalance');
                var sContractBal = objContractBal.innerHTML;
                sContractBal = sContractBal.slice(1);                               // remove $ sign
                sContractBal = sContractBal.replace(/,/g, '');                         // remove comma if any -- the //g are regular expressions which mean all occurances
                var nNewContractBal = parseFloat(sContractBal) + parseFloat(sOldVal) - parseFloat(sNewVal);

                if (nNewContractBal < 0) {
                    alert('Sorry, the new amount entered would reduce the remaining Contract Balance to less than zero.');
                    eventArgs.set_cancel(true);
                    window.setTimeout(function() { sender.focus(); }, 50);
                    return false;
                }

                //All is good so update the remaininbal on the allocation and the contract balance
                objRemBal.innerHTML = '$' + nNewRemainingAllocBal.toFixed(2)
                objContractBal.innerHTML = '$' + nNewContractBal.toFixed(2)


                // recalculate totals

                var objTotalAmount = $find("txtTotalAmount");
                var objRetAmount = $find("txtRetentionAmount");
                var objRetOverride = document.getElementById('chkAllowRetentionOverride');
                var objRetentionPercent = document.getElementById('AllocationRetPercent');
                var objPayableAmount = $find("txtPayableAmount");

                var sOldTotalAmount = objTotalAmount.get_displayValue();
                var sOldRetAmount = objRetAmount.get_displayValue();


                sOldTotalAmount = sOldTotalAmount.replace(/,/g, '');                         // remove comma if any -- the //g are regular expressions which mean all occurances
                sOldRetAmount = sOldRetAmount.replace(/,/g, '');                         // remove comma if any -- the //g are regular expressions which mean all occurances

                var bRetOverride = objRetOverride.checked;
                var sRetPerc = objRetentionPercent.value;

                if (sOldTotalAmount == "") {                                // MAKE ZERO IF BLANK
                    sOldTotalAmount = 0;
                }
                if (sOldRetAmount == "") {
                    sOldRetAmount = 0;
                }
                var nNewTotalAmount = parseFloat(sOldTotalAmount) - parseFloat(sOldVal) + parseFloat(sNewVal)
                var nNewRetAmount = 0;
                var nNewPayableAmount = 0;


                if (bRetOverride == true) {                  //  user put in manual retention amount so use that in payable calc
                    nNewPayableAmount = nNewTotalAmount - parseFloat(sOldRetAmount);
                }
                else {
                    if (sRetPerc > 0) {
                        sRetPerc = sRetPerc / 100;
                        nNewRetAmount = Math.round((nNewTotalAmount * sRetPerc) * 100) / 100;
                    }
                    //get rid of rounding errors
                    nNewPayableAmount = Math.round((nNewTotalAmount - nNewRetAmount) * 100) / 100;
                    objRetAmount.set_value(nNewRetAmount);
                }

                objTotalAmount.set_value(nNewTotalAmount);
                objPayableAmount.set_value(nNewPayableAmount);
            }


            function RecalcOnly(sender, eventArgs) {

                //called by dynamic allocation textboxes to perform recalc

                var sCtrlID = sender.get_id();                      // get the current textbox control id
                var sNewVal = eventArgs.get_newValue();             // get the new value
                var sOldVal = eventArgs.get_oldValue();             // get the old value

                if (sOldVal == "") {                                // MAKE ZERO IF BLANK
                    sOldVal = 0;
                }
                if (sNewVal == "") {
                    sNewVal = 0;
                }

                var lnkCtrl = sCtrlID.replace("txxt", "lnk");       //get the name of the corresponding remaining bal link for this item
                var objRemBal = document.getElementById(lnkCtrl);          // get ref to the rem bal link control
                var nBalRem = objRemBal.innerHTML;                         // get the text in the hyperlink
                nBalRem = nBalRem.slice(1);                                  // remove $ start of string
                nBalRem = nBalRem.replace(/,/g, '');                           //remove commas if any -- the //g are regular expressions which mean all occurances
                var nNewRemainingAllocBal = parseFloat(nBalRem) + parseFloat(sOldVal) - parseFloat(sNewVal);

                var objContractBal = document.getElementById('lblContractBalance');
                var sContractBal = objContractBal.innerHTML;
                sContractBal = sContractBal.slice(1);                               // remove $ sign
                sContractBal = sContractBal.replace(/,/g, '');                         // remove comma if any -- the //g are regular expressions which mean all occurances
                var nNewContractBal = parseFloat(sContractBal) + parseFloat(sOldVal) - parseFloat(sNewVal);

                objRemBal.innerHTML = '$' + nNewRemainingAllocBal.toFixed(2)
                objContractBal.innerHTML = '$' + nNewContractBal.toFixed(2)

                // recalculate totals

                var objTotalAmount = $find("txtTotalAmount");
                var objRetAmount = $find("txtRetentionAmount");
                var objRetOverride = document.getElementById('chkAllowRetentionOverride');
                var objRetentionPercent = document.getElementById('AllocationRetPercent');
                var objPayableAmount = $find("txtPayableAmount");

                var sOldTotalAmount = objTotalAmount.get_displayValue();
                var sOldRetAmount = objRetAmount.get_displayValue();

                sOldTotalAmount = sOldTotalAmount.replace(/,/g, '');                         // remove comma if any -- the //g are regular expressions which mean all occurances
                sOldRetAmount = sOldRetAmount.replace(/,/g, '');                         // remove comma if any -- the //g are regular expressions which mean all occurances

                var bRetOverride = objRetOverride.checked;
                var sRetPerc = objRetentionPercent.value;


                if (sOldTotalAmount == "") {                                // MAKE ZERO IF BLANK
                    sOldTotalAmount = 0;
                }
                if (sOldRetAmount == "") {
                    sOldRetAmount = 0;
                }


                var nNewTotalAmount = parseFloat(sOldTotalAmount) - parseFloat(sOldVal) + parseFloat(sNewVal)
                var nNewRetAmount = 0;
                var nNewPayableAmount = 0;

                if (bRetOverride == true) {                         //  user put in manual retention amount so use that in payable calc
                    nNewPayableAmount = nNewTotalAmount - parseFloat(sOldRetAmount);
                }
                else {
                    if (sRetPerc > 0) {
                        sRetPerc = sRetPerc / 100;
                        nNewRetAmount = nNewTotalAmount * sRetPerc;
                    }

                    nNewPayableAmount = nNewTotalAmount - nNewRetAmount;
                    objRetAmount.set_value(nNewRetAmount);

                }

                objTotalAmount.set_value(nNewTotalAmount);
                objPayableAmount.set_value(nNewPayableAmount);

            }


            function EnableRetentionOverride(ctrl) {

                var objRetAmount = $find("txtRetentionAmount");
                if (ctrl.checked == true) {
                    objRetAmount.enable();
                    objRetAmount.focus();
                }
                else {
                    objRetAmount.disable();
                }
            }




            function RecalcRetentionChange(sender, eventArgs) {

                //called by dynamic allocation textboxes to perform recalc

                var objRetAmount = $find("txtRetentionAmount");
                if (objRetAmount.get_enabled() == false) {
                    return false;
                }

                var sCtrlID = sender.get_id();                      // get the current textbox control id
                var sNewVal = eventArgs.get_newValue();             // get the new value
                var sOldVal = eventArgs.get_oldValue();             // get the old value

                if (sOldVal == "") {                                // MAKE ZERO IF BLANK
                    sOldVal = 0;
                }
                if (sNewVal == "") {
                    sNewVal = 0;
                }

                // recalculate totals
                var objTotalAmount = $find("txtTotalAmount");
                var objRetAmount = $find("txtRetentionAmount");
                var objPayableAmount = $find("txtPayableAmount");

                var sOldTotalAmount = objTotalAmount.get_displayValue();
                var sOldRetAmount = objRetAmount.get_displayValue();

                sOldTotalAmount = sOldTotalAmount.replace(/,/g, '');                         // remove comma if any -- the //g are regular expressions which mean all occurances
                sOldRetAmount = sOldRetAmount.replace(/,/g, '');                         // remove comma if any -- the //g are regular expressions which mean all occurances

                if (sOldTotalAmount == "") {                                // MAKE ZERO IF BLANK
                    sOldTotalAmount = 0;
                }
                if (sOldRetAmount == "") {
                    sOldRetAmount = 0;
                }
                var nNewTotalAmount = parseFloat(sOldTotalAmount) - parseFloat(sOldVal) + parseFloat(sNewVal)
                if (nNewTotalAmount < sOldRetAmount) {
                    alert('Warning: Retention amount is greater than Total Amount of Transaction.');

                }

                var nNewPayableAmount = parseFloat(sOldTotalAmount) - parseFloat(sNewVal);
                objPayableAmount.set_value(nNewPayableAmount);

            }

            //document ready handler (executes when page loads); creates a popup specifically for FHDA indicating how to use the Status field
            $(function() {
                if ($('#thisDistrictID').val() == 55) {
                    $('span:contains("Status")')
                    .css('color', 'rgb(0,0,255)')
                    .bind('click', function() {
                        alert('How to use the Status field:\n\n•    Paid – item paid by Distirict\n•    Pending – item waiting for payment by District\n•    Payment Pending – used for accruals as a backup way to flag them (eventually will be used when electronic //payment process starts again to indicate approvals are complete and ready for a check to be cut)\n•    Open – as a flag that there is an issue (more research needed) on a transaction and it is not ready to be sent \nfor payment (mostly DA)\n•    FDO Approved (not used now) Will be used when electronic payment processing resumes as a sign that transaction //entered the approval process electronically\n');
                    });
                    $('span:contains("Workflow Sc")')
                    .css('color', 'rgb(0,0,255)')
                    //.qtip({content: 'test'});
                    .bind('click', function() {
                    alert('Workflow Requirements:\n\n•    Due Date required.\n•    Invoice Number required.\n•    Invoice Date required.\n•    Project Edit Screen must have Retention Account assigned.\n•    Contract Edit Screen must have Workflow Scenarios assigned.\n•    There must be at least one attachment to this transaction.\n•    Contract Line Item you are allocating from must have Account # assigned.\n');
                    });
                }
            });


            
            
            
            
    
        </script>

    </telerik:RadCodeBlock>

</head>
<body>
    <form id="Form1" method="post" runat="server">
    <telerik:RadScriptManager ID="RadScriptManager1" runat="server" />
    <table id="Table1" style="z-index: 161; left: 8px; position: absolute; top: 8px;
        height: 2px" cellspacing="1" cellpadding="1" width="96%" border="0">
        <tr>
            <td width="20%" valign="top">
                <asp:Label ID="Label16" runat="server" Text="ID:" />
                <asp:Label ID="lblID" runat="server" Text="999" />
            </td>
            <td width="40%" valign="top" align="right">
                <asp:HyperLink ID="lnkShowLastUpdateInfo" runat="server" ImageUrl="images/change_history.gif"
                    ToolTip="show last update information">HyperLink</asp:HyperLink>
            </td>
            <td width="40%" valign="top" align="right">
                <asp:HyperLink ID="butFlag" runat="server" ImageUrl="images/button_flag.gif"></asp:HyperLink>&nbsp;&nbsp;&nbsp;
                <asp:HyperLink ID="butHelp" runat="server" ImageUrl="images/button_help.gif">HyperLink</asp:HyperLink>
            </td>
        </tr>
        <tr>
            <td colspan="3" valign="top">
                <asp:Label ID="lblMessage" runat="server" ForeColor="Red">message</asp:Label>
            </td>
            <%--        <td width="40%" valign="top" align="right">
 
    
            </td>
           
            <td width="40%" valign="top" align="right">
   
            </td>--%>
        </tr>
    </table>
    <asp:Label ID="Label1" Style="z-index: 100; left: 246px; position: absolute; top: 56px"
        runat="server">Inv. Received:</asp:Label>
    &nbsp;
    <asp:Label ID="lblContractTotal" Style="z-index: 101; left: 109px; position: absolute;
        top: 472px" runat="server" Width="120px" CssClass="ViewDataDisplay">999999.99</asp:Label>
    <asp:Label ID="Label19" Style="z-index: 102; left: 15px; position: absolute; top: 470px"
        runat="server">Contract Total: </asp:Label>
    <telerik:RadDatePicker ID="txtDateReceived" Style="z-index: 103; left: 329px; position: absolute;
        top: 52px; right: 1120px;" TabIndex="1" runat="server" Width="120px" SharedCalendarID="sharedCalendar"
        Skin="Vista">
        <DateInput ID="DateInput1" runat="server" Skin="Vista" Font-Size="13px" ForeColor="Blue">
        </DateInput>
    </telerik:RadDatePicker>
    <telerik:RadDatePicker ID="txtCheckDate" Style="z-index: 103; left: 517px;
        position: absolute; top: 230px" TabIndex="67" runat="server" Width="120px" SharedCalendarID="sharedCalendar"
        Skin="Vista">
<Calendar UseRowHeadersAsSelectors="False" UseColumnHeadersAsSelectors="False" ViewSelectorText="x" Skin="Vista"></Calendar>

<DatePopupButton ImageUrl="" HoverImageUrl="" TabIndex="67"></DatePopupButton>

        <DateInput ID="DateInput6" runat="server" Skin="Vista" Font-Size="13px" 
            ForeColor="Blue">
        </DateInput>
    </telerik:RadDatePicker>
    <telerik:RadDatePicker ID="txtFandEReceivedDate" Style="z-index: 103; left: 313px;
        position: absolute; top: 229px" TabIndex="67" runat="server" Width="120px" SharedCalendarID="sharedCalendar"
        Skin="Vista">
        <DateInput ID="DateInput2" runat="server" Skin="Vista" Font-Size="13px" ForeColor="Blue">
        </DateInput>
    </telerik:RadDatePicker>
    <telerik:RadDatePicker ID="txtDatePaid" Style="z-index: 104; left: 297px; position: absolute;
        top: 120px" TabIndex="32" runat="server" Width="120px" SharedCalendarID="sharedCalendar"
        Skin="Vista">
        <DateInput ID="DateInput3" runat="server" Skin="Vista" Font-Size="13px" ForeColor="Blue">
        </DateInput>
    </telerik:RadDatePicker>
    <telerik:RadCalendar ID="sharedCalendar" Skin="Vista" runat="server" EnableMultiSelect="false">
    </telerik:RadCalendar>
    <asp:TextBox ID="txtComments" Style="z-index: 108; left: 105px; position: absolute;
        top: 295px; width: 520px; height: 52px;" TabIndex="70" runat="server" 
        CssClass="EditDataDisplay" TextMode="MultiLine"></asp:TextBox>
    <asp:TextBox ID="txtInternalInvNumber" Style="z-index: 111; left: 105px; position: absolute;
        top: 187px" TabIndex="40" runat="server" CssClass="EditDataDisplay" Width="96px"></asp:TextBox>
    <telerik:RadDatePicker ID="txtDueDate" runat="server" CssClass="EditDataDisplay"
        Style="z-index: 112; left: 104px; position: absolute; top: 227px" TabIndex="55"
        Width="120px" SharedCalendarID="sharedCalendar" Skin="Vista">
        <DateInput ID="DateInput4" runat="server" Skin="Vista" BackColor="#FFFFC0" Font-Size="13px"
            ForeColor="Blue">
        </DateInput>
    </telerik:RadDatePicker>
    <asp:TextBox ID="txtCheckNumber" Style="z-index: 113; left: 474px; position: absolute;
        top: 122px" TabIndex="35" runat="server" CssClass="EditDataDisplay" Width="96px"></asp:TextBox>
    <asp:TextBox ID="txtInvoiceNumber" Style="z-index: 114; left: 106px; position: absolute;
        top: 119px" TabIndex="9" runat="server" CssClass="EditDataDisplay" Width="96px"></asp:TextBox>
    <asp:DropDownList ID="lstStatus" Style="z-index: 115; left: 249px; position: absolute;
        top: 261px; height: 20px; width: 132px;" TabIndex="65" runat="server" CssClass="EditDataDisplay"
        OnSelectedIndexChanged="lstStatus_SelectedIndexChanged" AutoPostBack="True" BackColor="#FFFFC0"
        Width="175px">
    </asp:DropDownList>
    <asp:TextBox ID="txtDescription" Style="z-index: 116; left: 105px; position: absolute;
        top: 86px" TabIndex="5" runat="server" CssClass="EditDataDisplay" Width="304px"></asp:TextBox>
    <asp:Label ID="Label14" Style="z-index: 118; left: 42px; position: absolute; top: 299px"
        runat="server">Notes:</asp:Label>
    <asp:Label ID="Label11" Style="z-index: 123; left: 11px; position: absolute; top: 189px"
        runat="server">Internal Inv#:</asp:Label>
    <asp:Label ID="Label10" Style="z-index: 124; left: 420px; position: absolute; top: 124px"
        runat="server">Check#:</asp:Label>
    <asp:Label ID="Label9" Style="z-index: 125; left: 233px; position: absolute; top: 121px"
        runat="server">Date Paid:</asp:Label>
    <asp:Label ID="Label21" runat="server" Style="z-index: 126; left: 15px; position: absolute;
        top: 229px">Due Date:</asp:Label>
    <asp:Label ID="Label7" Style="z-index: 127; left: 9px; position: absolute; top: 55px"
        runat="server">Invoice Date:</asp:Label>
    <asp:Label ID="Label6" Style="z-index: 128; left: 25px; position: absolute; top: 119px;
        height: 3px;" runat="server">Invoice #:</asp:Label>
    <asp:Label ID="lblCheckDateLabel" Style="z-index: 129; left: 440px; position: absolute; top: 232px;
        height: 12px;" runat="server">Check Date:</asp:Label>
    <asp:Label ID="Label5" Style="z-index: 129; left: 244px; position: absolute; top: 231px;
        height: 12px;" runat="server">F&amp;E Recd:</asp:Label>
    <asp:Label ID="Label4" Style="z-index: 130; left: 13px; position: absolute; top: 87px"
        runat="server">Description:</asp:Label>
    <asp:Label ID="Label2" Style="z-index: 132; left: 465px; position: absolute; top: 56px;
        height: 15px;" runat="server">Type:</asp:Label>
    <asp:Label ID="Label25" runat="server" Style="z-index: 134; left: 220px; position: absolute;
        top: 160px; right: 1315px; height: 12px; width: 72px;">FY:</asp:Label>
    <asp:Label ID="Label23" runat="server" Style="z-index: 134; left: 348px; position: absolute;
        top: 164px; right: 1187px; height: 12px; width: 72px;">Acctg Mo:</asp:Label>
    <asp:Label ID="lbl1099code1" runat="server" Style="z-index: 136; left: 20px; position: absolute;
        top: 261px">1099 Code:</asp:Label>
    <asp:CheckBox ID="chkAccrual" Style="z-index: 137; left: 468px; position: absolute;
        top: 88px" TabIndex="4" runat="server" Text="Accrual" TextAlign="Left" ToolTip="This transaction is an Accrual Expense">
    </asp:CheckBox>
    <asp:DropDownList ID="lstTransType" Style="z-index: 138; left: 508px; position: absolute;
        top: 55px;" TabIndex="2" runat="server" CssClass="EditDataDisplay">
    </asp:DropDownList>
    &nbsp;
    <asp:DropDownList ID="lstAccountingMonth" Style="z-index: 139; left: 422px; position: absolute;
        top: 160px; right: 1140px;" TabIndex="52" runat="server" CssClass="EditDataDisplay"
        Width="45px">
        <asp:ListItem></asp:ListItem>
        <asp:ListItem>01</asp:ListItem>
        <asp:ListItem>02</asp:ListItem>
        <asp:ListItem>03</asp:ListItem>
        <asp:ListItem>04</asp:ListItem>
        <asp:ListItem>05</asp:ListItem>
        <asp:ListItem>06</asp:ListItem>
        <asp:ListItem>07</asp:ListItem>
        <asp:ListItem>08</asp:ListItem>
        <asp:ListItem>09</asp:ListItem>
        <asp:ListItem>10</asp:ListItem>
        <asp:ListItem>11</asp:ListItem>
        <asp:ListItem>12</asp:ListItem>
    </asp:DropDownList>
    <asp:DropDownList ID="lstFiscalYear" Style="z-index: 139; left: 253px; position: absolute;
        top: 158px" TabIndex="50" runat="server" CssClass="EditDataDisplay">
    </asp:DropDownList>
    <asp:DropDownList ID="lstBondSeries" Style="z-index: 140; left: 106px; position: absolute;
        top: 156px; right: 1456px;" TabIndex="45" runat="server" CssClass="EditDataDisplay"
        Width="75px">
    </asp:DropDownList>
    <asp:DropDownList ID="lstCode1099" Style="z-index: 143; left: 105px; position: absolute;
        top: 259px; width: 78px;" TabIndex="63" runat="server" CssClass="EditDataDisplay"
        BackColor="#FFFFC0">
    </asp:DropDownList>
    <telerik:RadDatePicker ID="txtInvoiceDate" Style="z-index: 145; left: 106px; position: absolute;
        top: 51px" runat="server" Width="120px" SharedCalendarID="sharedCalendar" Skin="Vista">
        <DateInput ID="DateInput5" runat="server" Skin="Vista" Font-Size="13px" ForeColor="Blue">
        </DateInput>
    </telerik:RadDatePicker>
    <asp:ImageButton ID="butSave" Style="z-index: 146; left: 21px; position: absolute;
        top: 423px" TabIndex="150" runat="server" 
        ImageUrl="images/button_save.gif">
    </asp:ImageButton>
    <asp:ImageButton ID="butDelete" Style="z-index: 147; left: 203px; position: absolute;
        top: 423px" TabIndex="200" runat="server" 
        OnClientClick="return confirm('You have selected to Delete this Transaction!\n\nAre you sure you want to delete this transaction?')"
        ImageUrl="images/button_delete.gif">
    </asp:ImageButton>
    &nbsp;
    <asp:Label ID="Label18" Style="z-index: 148; left: 249px; position: absolute; top: 472px;
        height: 12px;" runat="server">Contract Balance: </asp:Label>
    <asp:Label ID="lblContractBalance" Style="z-index: 149; left: 362px; position: absolute;
        top: 474px" runat="server" CssClass="ViewDataDisplay" Width="120px">999999.99</asp:Label>
    <asp:Label ID="lblAllocationMessage" runat="server" BackColor="Transparent" Font-Bold="True"
        ForeColor="Red" Style="z-index: 151; left: 22px; position: absolute; top: 499px"
        Width="585px">Note:</asp:Label>
    <asp:Table ID="tblAlloc" Style="z-index: 152; left: 22px; position: absolute; top: 519px"
        runat="server" Width="592px" Height="16px">
    </asp:Table>
    <asp:Label ID="lblBondSeriesLabel" Style="z-index: 122; left: 15px; position: absolute; top: 158px;
        height: 5px;" runat="server">Bond Series:</asp:Label>
    <telerik:RadAjaxManager ID="RadAjaxManager1" runat="server">
        <AjaxSettings>
            <telerik:AjaxSetting AjaxControlID="lstxWorkflowScenerioID">
                <UpdatedControls>
                    <telerik:AjaxUpdatedControl ControlID="lblCurrentWorkflowOwner" />
                    <telerik:AjaxUpdatedControl ControlID="lblMessage" />
                </UpdatedControls>
            </telerik:AjaxSetting>
            <telerik:AjaxSetting AjaxControlID="lstStatus">
                <UpdatedControls>
                    <telerik:AjaxUpdatedControl ControlID="lstStatus" />
                    <telerik:AjaxUpdatedControl ControlID="lblMessage" />
                </UpdatedControls>
            </telerik:AjaxSetting>
            <telerik:AjaxSetting AjaxControlID="WorkflowPopup_AjaxHiddenButton">
                <UpdatedControls>
                    <telerik:AjaxUpdatedControl ControlID="lblCurrentWorkflowOwner" />
                    <telerik:AjaxUpdatedControl ControlID="lstxWorkflowScenerioID" />
                    <telerik:AjaxUpdatedControl ControlID="lnkWorkflowRoute" />
                </UpdatedControls>
            </telerik:AjaxSetting>
            <telerik:AjaxSetting AjaxControlID="AttachmentsPopup_AjaxHiddenButton">
                <UpdatedControls>
                    <telerik:AjaxUpdatedControl ControlID="lstAttachments" />
                    <telerik:AjaxUpdatedControl ControlID="lnkWorkflowRoute" />
                    
                </UpdatedControls>
            </telerik:AjaxSetting>
            <telerik:AjaxSetting AjaxControlID="RadAjaxManager1">
                <UpdatedControls>
                    <telerik:AjaxUpdatedControl ControlID="lblAllocationMessage" />
                    <telerik:AjaxUpdatedControl ControlID="lblContractBalance" />
                </UpdatedControls>
            </telerik:AjaxSetting>
        </AjaxSettings>
    </telerik:RadAjaxManager>
    <asp:LinkButton ID="lnkOverride" runat="server" OnClick="lnkOverride_Click" Style="z-index: 153;
        left: 413px; position: absolute; top: 265px" TabIndex="500">Override</asp:LinkButton>
    <asp:HyperLink ID="lnkManageAttachments" runat="server" ImageUrl="images/button_folder_view.gif"
        Style="z-index: 155; left: 328px; position: absolute; top: 370px" TabIndex="73"
        ToolTip="Manage Attachments">Manage Attachments</asp:HyperLink>
    <asp:ListBox ID="lstAttachments" runat="server" Height="49px" Style="z-index: 156;
        left: 104px; position: absolute; top: 366px; width: 218px;" CssClass="smalltext"
        TabIndex="71"></asp:ListBox>
    <asp:Panel ID="panelWorkflow" runat="server" Style="z-index: 157; left: 362px; position: absolute;
        top: 399px; width: 240px; bottom: 455px; height: 50px;" BorderColor="Silver"
        BorderStyle="Solid" BorderWidth="1px">
        <asp:Label ID="lblCurrentWorkflowStatusLabel" runat="server" CssClass="smalltext"
            Style="z-index: 100; left: 5px; position: absolute; top: 0px" Width="113px">Workflow Owner:</asp:Label>
        <asp:Label ID="lblCurrentWorkflowOwner" runat="server" CssClass="EditDataDisplay"
            Style="z-index: 101; left: 7px; position: absolute; top: 19px; width: 225px;">none</asp:Label>
        <asp:HyperLink ID="lnkShowWorkflowHistory" runat="server" ImageUrl="images/workflow_history.png"
            ToolTip="Show Workflow history" Style="z-index: 102; left: 213px; position: absolute;
            top: 2px; width: 16px;">HyperLink</asp:HyperLink>
        &nbsp; &nbsp;&nbsp;
    </asp:Panel>
    <asp:Label ID="lblVerified1" runat="server" Style="z-index: 135; left: 223px; position: absolute;
        top: 194px">Verified:</asp:Label>
    <asp:Label ID="Label26" Style="z-index: 129; left: 208px; position: absolute; top: 262px;
        height: 12px;" runat="server">Status:</asp:Label>
    <asp:DropDownList ID="lstVerified" Style="z-index: 141; left: 280px; position: absolute;
        top: 192px" TabIndex="54" runat="server" CssClass="EditDataDisplay" 
        Width="100px">
    </asp:DropDownList>
    <%-- 
    Put Hidden button on form to handle ajax post back from rad window
    
    --%>
    <div style="display: none">
        <asp:Button ID="WorkflowPopup_AjaxHiddenButton" runat="server"></asp:Button>
    </div>
    <div style="display: none">
        <asp:Button ID="AttachmentsPopup_AjaxHiddenButton" runat="server"></asp:Button>
    </div>
    <asp:DropDownList ID="lstxWorkflowScenerioID" Style="z-index: 158; left: 371px; position: absolute;
        top: 370px; width: 150px;" TabIndex="80" runat="server" 
        AutoPostBack="true" CssClass="EditDataDisplay"
        OnSelectedIndexChanged="lstxWorkflowScenerioID_SelectedIndexChanged">
    </asp:DropDownList>
    <asp:Label ID="lblWorkflowScenerio" runat="server" Style="z-index: 162; left: 372px;
        position: absolute; top: 353px">Workflow Scenario:</asp:Label>
    <telerik:RadWindowManager ID="RadPopups" runat="server">
    </telerik:RadWindowManager>
    <asp:HiddenField ID="AllocationRetPercent" runat="server" />
    <asp:Label ID="Label8" runat="server" Style="z-index: 119; left: 11px; position: absolute;
        top: 368px; height: 10px;">Attachments:</asp:Label>
        
    <asp:HiddenField ID="txtAccountNumber" runat="server" />
        
        
    </form>
</body>
</html>
