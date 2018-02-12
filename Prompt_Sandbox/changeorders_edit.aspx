<%@ Page Language="vb" %>

<%@ Register Assembly="Telerik.Web.UI" Namespace="Telerik.Web.UI" TagPrefix="telerik" %>
<%@ Import Namespace="System.IO" %>
<%@ Import Namespace="System.IO.FileSystemInfo" %>
<%@ Import Namespace="Prompt" %>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">
<script runat="server">

    Private nProjectID As Integer = 0
    Private strPhysicalPath As String = ""
    Private strFilePath As String = ""
    Private sDisplayType As String = ""
    Private nContactID As Integer
    Private sTitle As String = ""
    Private sTitleDetail As String = ""
    Private sContactName As String
    Private nCOID As Integer
    Private alertText As String
    Private isUpload As Boolean
    Private COStatus As String
    Private sCoType As String
    Private nRev As Integer
    Private nSeq As Integer
    Private isPMtheCM As String
    
    Private Sub Page_Load(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MyBase.Load

        If Not IsPostBack Then
            sResponse.Value = ""
            sIssue.Value = ""
        Else
            If responseOut.Value <> "response out" Then
                sResponse.Value = txtResponse.Text
            End If
            sIssue.Value = txtIssue.Text
            hRequestedCOAmount.Value = txtRequestedCOAmount.Text
            dRequiredBy.Value = txtRequiredBy.DbSelectedDate
        End If
        
        ProcLib.CheckSession(Page)
        ProcLib.LoadPopupJscript(Page)
        nRev = 0
        
        'David D 6/12/17 added below to handle txtResponse field validation, this was needed.
        If txtResponse.Text <> "" Or txtResponse.Text <> String.Empty Then
            TextBoxRequiredValidatorResponse.Enabled = False
        Else
            If txtResponse.Visible = True Then
                TextBoxRequiredValidatorResponse.Enabled = True 'comm out to test stuff
            End If
        End If
        'David D 6/12/17 added for validation control of txtIssue during a revision by the GC
        If txtIssue.Text = "" Or txtIssue.Text = String.Empty Then
            TextBoxRequiredValidatorIssue.Enabled = True 'Temporary comment out to continue testing.
        Else
            TextBoxRequiredValidatorIssue.Enabled = False
        End If
        'David D 6/12/17 added below to prevent second summary from showing on load
        TextBoxRequiredValidatorSummaryCO.Enabled = False
        TextBoxRequiredValidatorResponse.Enabled = False
        TextBoxRequiredValidatorIssue.Enabled = False
        TextBoxRequiredValidatorSubject.Enabled = False
        
        If Session("SetAction") = True Then
            Session("SetAction") = False
            'cboActionSelect.SelectedValue = "Existing"
        End If
        
        Session("PageID") = "ChangeOrdersEdit"
        
        Try
            nProjectID = Request.QueryString("ProjectID")
        Catch ex As Exception
            nProjectID = Session("ProjectID")
        End Try
        sDisplayType = Request.QueryString("DisplayType")
        Try
            nCOID = Request.QueryString("ChangeOrderID")
        Catch ex As Exception
        End Try
        If sDisplayType = "New" Then
            Session("COType") = Request.QueryString("coType")
        Else
        End If
        sCoType = Session("COType")
        
        Using db As New RFI
            nContactID = db.getContactID(Session("UserID"), Session("DistrictID"))
            Dim ContactData As Object = db.getContactData(nContactID, Session("DistrictID"))
            Session("ParentContactID") = ContactData(0)
            Session("ContactType") = ContactData(1)
            sContactName = ContactData(2)
            Dim thObj As Object = db.getCM(Request.QueryString("ProjectID"), Request.QueryString("ContractID"))
            Session("CMID") = thObj(0)
            Session("ContractorID") = thObj(1)
            If Session("CMID") = 0 Then isPMtheCM = True Else isPMtheCM = False ' gives pm cm privilages if no cm specified
        End Using
        'set up help button
        butHelp.Attributes("onclick") = "return ShowHelp();"
        butHelp.NavigateUrl = "#"
        
        If Session("Redirect") = True Then
            getData()
            Session("Redirect") = Nothing
        End If

        If Not IsPostBack Then
            Session("ActionChange") = Nothing
            activeRevision.Value = 0
            
            Session("TempRev") = Nothing
            Using db As New ChangeOrders
                Dim tbl As DataTable = db.getProjectContracts(nProjectID, Session("ContactType"), nContactID)
                
                Dim conTbl As DataTable
                conTbl = New DataTable("resTbl")
                conTbl.Columns.Add("ContractID", GetType(System.String))
                conTbl.Columns.Add("CompanyName", GetType(System.String))
                conTbl.Rows.Add("0", "0")
                
                For Each row As DataRow In tbl.Rows
                    conTbl.Rows.Add(row.Item("ContractID"), row.Item("ContractID") & " - " & row.Item("Description"))
                Next
                
                With cboContractID
                    .DataValueField = "ContractID"
                    .DataTextField = "CompanyName"
                    .DataSource = conTbl
                    .DataBind()
                End With
            End Using
            
            Using db As New RFI
                Try
                    Dim contractID As Integer
                    If sDisplayType = "New" Then
                        contractID = cboContractID.SelectedValue
                    Else
                        contractID = db.getContractID(nCOID)
                    End If
                Catch ex As Exception
                End Try
            End Using
                       
            Try
                Using db As New TeamMember
                    With cboDPSelect
                        .DataValueField = "ContactID"
                        .DataTextField = "Name"
                        .DataSource = db.GetExistingMembersForDropDowns(nProjectID, "Design Professional", "N/A")
                        .DataBind()
                    End With
                End Using
            Catch ex As Exception
            End Try
                                       
            Using db As New TeamMember
                Dim tbl As DataTable = db.GetExistingMembers(nProjectID)
                tbl.DefaultView.Sort = "LastName"
                       
                Dim newrow As DataRow = tbl.NewRow
                newrow("ContactID") = 0
                newrow("TeamMemberID") = 0
                newrow("TeamGroupName") = "None"
                newrow("Name") = "None"
                tbl.Rows.InsertAt(newrow, 0)   'put it first
            End Using
            
            Using db As New ChangeOrders
                Dim revTbl As DataTable = db.getRevisionData(0, 0)
                Dim row As DataRow = revTbl.NewRow
                row("Revision") = 0
                revTbl.Rows.InsertAt(row, 0)   'put it first
                With cboRevisions
                    .DataValueField = "Revision"
                    .DataTextField = "Revision"
                    .DataSource = revTbl
                    Try
                        .DataBind()
                    Catch ex As Exception
                    End Try
                End With
            End Using
        End If
        
        If sDisplayType = "Existing" Then
            'configActionDropdown()
            If Not IsPostBack Then
                getData()
                getResponseData("")
                'buildResponseDropdown("Released")
                'If Not IsPostBack Then
                buildResponseDropdown("")
                'End If
                configReadOnly()
                Session("UpdateData") = False
            Else
            End If
            'If Session("ContactType") <> "Design Professional" Then
            conflictID.Value = 0
            Session("RevisionPreparing") = False
            Dim sessionConflict As Boolean = False
            Select Case Trim(WorkFlowPosition.Value)
                Case "CM:Distribution Pending"
                    Dim tbl As DataTable = Nothing
                    Using db As New RFI
                        tbl = db.checkForRevisionPreparing(nCOID)
                        If tbl.Rows.Count > 0 Then Session("RevisionPreparing") = True
                    End Using
                    sessionConflict = checkForSessionConflict()
                Case "CM:Review Pending"
                    If Session("ContactType") <> "General Contractor" Then
                        sessionConflict = checkForSessionConflict()
                    End If
                Case "GC:Acceptance Pending"
                    If Session("ContactType") <> "Construction Manager" Then
                        sessionConflict = checkForSessionConflict()
                    End If
                Case "GC:Receipt Pending"
                    If Session("ContactType") = "ProjectManager" Or Session("ContactType") = "General Contractor" Then
                        sessionConflict = checkForSessionConflict()
                    End If
                Case "CM:Completion Pending"
                    If Session("ContactType") = "General Contractor" Or Session("ContactType") = "District" Then
                    Else
                        sessionConflict = checkForSessionConflict()
                    End If
                Case "DP:Review Pending"
                    If Session("ContactType") = "General Contractor" Or Session("ContactType") = "District" Then
                    Else
                        sessionConflict = checkForSessionConflict()
                    End If
                Case Else
                    sessionConflict = checkForSessionConflict()
            End Select
            Session("SessionConflict") = sessionConflict
            Select Case Trim(WorkFlowPosition.Value)
                Case "DP:Response Pending", "DP:Review Pending"
                    If Session("ContactType") = "Design Professional" Then
                        setNewWorkflowStatus()
                    End If
                Case "GC:Acceptance Pending", "GC:Receipt Pending"
                    If Session("ContactType") = "General Contractor" Then
                        setNewWorkflowStatus()
                    End If
                Case "CM:Review Pending", "CM:Distribution Pending", "CM:Acceptance Pending", "CM:Completion Pending", "CM:Response Pending"
                    If Session("ContactType") = "Construction Manager" Or isPMtheCM = True Then
                        setNewWorkflowStatus()
                    End If
                Case "PM:Review Pending", "PM:BOD Approval Pending", "PM:Approval Pending", "PM:Completion Pending"
                    If Session("ContactType") = "ProjectManager" Then
                        'David D 6/19/17 added below for PM was missing
                        setNewWorkflowStatus()
                    End If
            End Select
            'Else
            'conflictID.Value = 0
            'End If
            If Not IsPostBack Then
                conflictCheckRecord()
                butLeftPanelSelect_Click()
                Session("SeqNum") = 1
            End If
            cboActionSelect_Change() 'Routs useres to the configuration functions          
        ElseIf sDisplayType = "New" Then
            If Not IsPostBack Then
                configNoSelection()
            End If
        End If
    End Sub
    
    Private Sub responseAttach_click() Handles butResponseAttach.Click
        responseOut.Value = "response out"
        If WorkFlowPosition.Value = "PM:Approval Pending" Then
            txtResponse.Text = sResponse.Value
            txtRequiredBy.DbSelectedDate = dRequiredBy.Value
        End If
        uploadPanel.Visible = True
        butCloseUpload.Visible = True
        lblUploadPanel.Text = "Response Uploads"
        uploadFrame1.Visible = True
        uploadFrame1.Attributes.Add("src", Session("responseAttach"))
    End Sub

    Private Sub issueAttach_click() Handles butIssueAttach.Click
        issueOut.Value = "issue out"
        If cboActionSelect.SelectedValue = "CMCreateCORRevision" Or cboActionSelect.SelectedValue = "CreateRevision" Then
            txtRequestedCOAmount.Text = hRequestedCOAmount.Value
            roRequestedCOAmount.Text = hRequestedCOAmount.Value
            txtIssue.Text = sIssue.Value
        End If
        If sResponse.Value <> "" Then
            txtResponse.Text = sResponse.Value
        End If
        txtRequiredBy.DbSelectedDate = dRequiredBy.Value
        uploadPanel.Visible = True
        butCloseUpload.Visible = True
        lblUploadPanel.Text = "Issue Uploads"
        uploadFrame1.Visible = True
        uploadFrame1.Attributes.Add("src", Session("issueAttach"))
    End Sub
    
    Private Sub butCloseUpload_click() Handles butCloseUpload.Click
        If cboActionSelect.SelectedValue = "CMCreateCORRevision" OR cboActionSelect.SelectedValue = "CreateRevision" Then
            txtRequestedCOAmount.Text = hRequestedCOAmount.Value
            roRequestedCOAmount.Text = hRequestedCOAmount.Value
            txtIssue.Text = sIssue.Value
        End If
        If sResponse.Value <> "" Then
            txtResponse.Text = sResponse.Value
            responseOut.Value = ""
        End If
        txtRequiredBy.DbSelectedDate = dRequiredBy.Value
        uploadPanel.Visible = False
        butCloseUpload.Visible = False
        updateAttachCount()
    End Sub
    
    Private Sub updateResponseAttachment(Seq As Integer, parentID As Integer, isUpload As Boolean, rev As Integer)
        Session("responseAttach") = "RFI_attachments_manage.aspx?ParentType=CoResponse&ParentID=" & parentID & "&ProjectID=" _
                                             & nProjectID & "&Revision=" & rev & "&UserType=" & Session("UserType") & "&Type=" & sDisplayType & "&Closed=" _
                                             & Session("Closed") & "&Seq=" & Seq & "&Upload=" & isUpload
        uploadFrame1.Attributes.Add("src", Session("responseAttach"))
    End Sub
    
    Private Sub updateIssueAttachment(sUser As String, parentID As Integer, isUpload As Boolean, rev As Integer)
        Session("issueAttach") = "RFI_attachments_manage.aspx?ParentType=CoIssue&ParentID=" & parentID & "&ProjectID=" _
                                             & nProjectID & "&Revision=" & rev & "&UserType=" & Session("UserType") & "&Type=" & sDisplayType & "&Closed=" _
                                             & Session("Closed") & "&User=" & sUser & "&Upload=" & isUpload
        uploadFrame1.Attributes.Add("src", Session("issueAttach"))
    End Sub
          
    Private Sub configReadOnly()
        conflictMessage.Visible = False
        lblCreateDate.Visible = True
        roCreateDate.Visible = True
        lblContractID.Visible = True
        cboContractID.Visible = False
        roContractID.Visible = True
        txtRequiredBy.Visible = False
        roRequiredBy.Visible = False
        lblRequiredBy.Visible = False
        lblInitiatedBy.Visible = True
        roInitiatedBy.Visible = True
        lblRFIReference.Visible = True
        cboRFIReference.Visible = False
        lblSubject.Visible = True
        roSubject.Visible = True
        txtSubject.Visible = False
        butSend.Visible = False
        butCancel.Visible = True
        saveButton.Value = "Existing"
        lblChangeOrderID.Visible = False
        butSave.Visible = False
        cboDPSelect.Visible = False
        If roDPSelect.Text <> "" Then
            lblDPSelect.Visible = True
        Else
            lblDPSelect.Visible = False
        End If
        roDPSelect.Visible = True       
        butResponseAttach.ImageUrl = "images/button_view.png"
        butIssueAttach.ImageUrl = "images/button_view.png"
        lblContractAmount.Visible = True
        roContractAmount.Visible = True
        txtResponse.Visible = False
        roResponse.Visible = True
        lblResponse.Visible = True
        roCurrentResponse.Visible = False
        txtIssue.Visible = False
        roIssue.Visible = True
        lblIssue.Visible = True
        lblIssue.Text = "Issue/Explanation:"
        butLeftPanelSelect.Visible = True
        responseMsg.Visible = False
        'cboResponses.Visible = False 'David D 6/6/17 commented out because the dropdown disapears after toggling for GC
        If showRevisions.Value = True Then
            cboRevisions.Visible = True
            lblRevisions.Visible = True
            'roRevisions.Visible = True
        Else
            cboRevisions.Visible = False
            roRevisions.Visible = False
            lblRevisions.Visible = False
        End If
        cboRFISelectSwitch.Visible = False
        configActionDropdown()
        If Not IsPostBack Then
            cboActionSelect.OpenDropDownOnLoad = True
            RFISelectPanel.Visible = False
        End If
        showRFI.Visible = False
        lblHistory.Visible = False
        roRFIDetail.Visible = False
        cboInitiatedBy.Visible = False
        roRequestedCOAmount.Visible = True
        txtRequestedCOAmount.Visible = False
        roFinanceVerified.Visible = True
        txtFinanceVerified.Visible = False
        lblFinanceVerified.Visible = True
        txtAltReference.Visible = True
        txtAltReference.Enabled = False
                
        If Not IsPostBack Then
            If sCoType = "COR" Then
                butLeftPanelSelect.ImageUrl = "images/button_pcos.png"
                CORequestAmountDateChange.Visible = True
                txtRequestedCOAmount.Visible = False
                roRequestedCOAmount.Visible = True
                butLeftPanelSelect_Click()
            ElseIf sCoType = "CO" Then
                butLeftPanelSelect.ImageUrl = "images/button_cors.png"
                CORequestAmountDateChange.Visible = True
                txtRequestedCOAmount.Visible = False
                roRequestedCOAmount.Visible = True
            ElseIf sCoType = "PCO" Then
                butLeftPanelSelect.Visible = True
                butLeftPanelSelect.ImageUrl = "images/button_contract.png"
                ContractDetailPanel_B.Visible = True
            End If
            updateIssueAttachment(0, nCOID, False, cboRevisions.SelectedValue)
            updateResponseAttachment(Session("SeqNum"), nCOID, False, cboRevisions.SelectedValue)
        End If
        If sCoType = "PCO" Then
            lblDaysInProcess.Visible = False
            roDaysInProcess.Visible = False
            lblFinanceVerified.Visible = False
            lblDPSelect.Visible = False
            lblRequiredBy.Visible = True
            roRequiredBy.Visible = True
        ElseIf sCoType = "COR" Then
            lblDaysInProcess.Visible = True
            roDaysInProcess.Visible = True
            lblFinanceVerified.Visible = True
            roFinanceVerified.Visible = True
            lblBoardApproved.Visible = True
            roBoardApproved.Visible = True
        End If
            
        updateAttachCount()
        cboActionSelect.Visible = False
        If lblUploadPanel.Text = "Issue Uploads" And uploadFrame1.Visible = True Then
            issueAttach_click()
        ElseIf lblUploadPanel.Text = "Response Uploads" And uploadFrame1.Visible = True Then
            responseAttach_click()
        End If
        If cboRevisions.SelectedValue > 0 Then
            checkForResponse(cboRevisions.SelectedValue, "Released")
        End If
        If butLeftPanelSelect.ImageUrl = "images/button_contract.png" Then
            ContractDetailPanel_A.Visible = False
            ContractDetailPanel_B.Visible = False
        End If
    End Sub
    
    Private Sub checkForResponse(rev As Integer, type As String)
        'type = ""
        Using db As New ChangeOrders
            Dim tbl As DataTable = db.getCOResponses(nCOID, rev, type, nContactID)
            If tbl.Rows.Count > 0 Then
                initResponseID.Value = tbl.Rows(0).Item("ResponseBy")
            End If
          
            If tbl.Rows.Count = 0 Then
                cboResponses.Visible = False
                roResponse.Visible = False
                lblResponse.Visible = False
                lblResponseAttachments.Visible = False
                responseAttachNum.Visible = False
                butResponseAttach.Visible = False
                roCurrentResponse.Visible = False
            Else
                roResponse.Visible = True
                lblResponse.Visible = True
                lblResponseAttachments.Visible = True
                responseAttachNum.Visible = True
                butResponseAttach.Visible = True
                roCurrentResponse.Visible = True
            End If
        End Using
        updateResponseAttachment(Session("SeqNum"), nCOID, isUpload, cboRevisions.SelectedValue)
        updateAttachCount()
        configRequiredByDate()
    End Sub
    
    Private Sub configCoEdit()
        'David D 6/9/17 below control disables validation on the txtResponse for edit
        TextBoxRequiredValidatorResponse.Enabled = False
        'David D 6/9/17 below condition blocks the lblFinanceVerified since it was overlaying the "Required By" lbl
        If Session("CoType") = "PCO" Then
            lblFinanceVerified.Visible = False
        End If
        lblCreateDate.Visible = True
        roCreateDate.Visible = True
        roCreateDate.Text = Now().ToString("d")
        lblContractID.Visible = True
        txtRequiredBy.Visible = True
        lblRequiredBy.Visible = True
        lblInitiatedBy.Visible = True
        roInitiatedBy.Visible = True
        lblRFIReference.Visible = True
        lblSubject.Visible = True
        roSubject.Visible = False
        txtSubject.Visible = True
        txtIssue.Visible = True
        butSave.Visible = True
        butSend.Visible = True
        butCancel.Visible = True
        saveButton.Value = "Existing"
        sendButton.Value = "GCSendToCM"
        lblChangeOrderID.Visible = False
        lblActionSelect.Visible = True
        cboActionSelect.Visible = True
        cboDPSelect.Visible = False
        alertText = "This action will save this PCO edit.\nIt will not advance to the next workflow position.\n\nDo you want to continue?\n\n"
        butSave.OnClientClick = "return confirm('" & alertText & "')"
        alertText = "This action will save this PCO edit.\nand send to the CM/PM for review.\n\nDo you want to continue?\n\n"
        butSend.OnClientClick = "return confirm('" & alertText & "')"
        lblContractAmount.Visible = True
        roContractAmount.Visible = True
        cboRFISelectSwitch.Visible = True
        cboRFIReference.Visible = True
        updateAttachCount()
        strPhysicalPath = ProcLib.GetCurrentAttachmentPath() & "DistrictID_" & HttpContext.Current.Session("DistrictID") & "/_apprisedocs/"
        configActionDropdown()
         If lblUploadPanel.Text = "Issue Uploads" And uploadFrame1.Visible = True Then
            issueAttach_click()
        End If
    End Sub
    
    Private Sub showRfiSelectPanel()
        RFISelectPanel.Visible = True
        cboRFIReference.Visible = True
        cboRFISelectSwitch.Visible = True
        roRFIItems.Visible = True
        Dim rev As Integer
        Try
            If Session("TempRev") <> Nothing Then rev = Session("TempRev") Else rev = cboRevisions.SelectedValue
        Catch ex As Exception
            rev = 0
        End Try     
        If cboActionSelect.SelectedValue = "Edit" Or cboActionSelect.SelectedValue = "CreateRevision" Then
            RFISelectPanel.Visible = True
            Using db As New ChangeOrders
                If Session("TempRev") <> Nothing Then rev = Session("TempRev") Else rev = cboRevisions.SelectedValue
                roRFIItems.Text = db.buildItemsList(nCOID, rev, "RFI", nContactID)
            End Using
        Else
            RFISelectPanel.Visible = False
        End If
    End Sub
    
    Private Sub updateAttachCount()
        Dim sUser As String
        sUser = getContactTypeAbbr(Session("ContactType"))
        Session("sUser") = sUser        
        Using db As New ChangeOrders
            responseAttachNum.Text = db.countChangeOrderAttachments(nCOID, "Response", sUser, cboRevisions.SelectedValue, Session("SeqNum"))
            issueAttachNum.Text = db.countChangeOrderAttachments(nCOID, "Issue", sUser, cboRevisions.SelectedValue, Session("SeqNum"))
        End Using
    End Sub
    
    Private Sub cboActionSelect_Change() Handles cboActionSelect.SelectedIndexChanged
        setNewCORValue()
        Select Case Session("ContactType")
            Case "ProjectManager"
                configPM()
            Case "General Contractor", "Contractor"
                configGC()
            Case "Construction Manager"
                configCM()
            Case "Design Professional"
                configDP()
            Case "District"
                If Not IsPostBack Then
                    'cboRevisions.SelectedValue = 0
                End If
                'configPMReviewPending()
                Select Case WorkFlowPosition.Value
                    Case "PM:Review Pending", "PM:BOD Approval Pending"
                        'configPMReviewPending()
                End Select
                checkForResponse(cboRevisions.SelectedValue, "Released")
                'configPMReviewPending() this item causes the response window to change when toggling contract and rfi.
               
                If Not IsPostBack Then
                    checkRevisionRelease()
                    cboRevisions_Change()
                    buildResponseDropdown("Released")
                    butLeftPanelSelect.ImageUrl = "images/button_contract.png"
                    butLeftPanelSelect_Click()
                    'roRFIItems.Visible = True
                End If
                updateAttachCount()
            Case "Inspector Of Record"
                configReadOnly()
                updateResponseAttachment(Session("SeqNum"), nCOID, isUpload, cboRevisions.SelectedValue)
        End Select
    End Sub
          
    Private Sub getResponseData(responseType As String)      
        Using db As New ChangeOrders
            Dim tbl As DataTable = db.getCOResponses(nCOID, cboRevisions.SelectedValue, "Released", nContactID)
            Dim sUser As String = ""
            Try
                If Session("UpdateData") <> True Then
                    txtResponse.Text = Replace(tbl.Rows(0).Item("Response"), "~", "'")
                End If
                If tbl.Rows.Count > 1 Then
                    cboResponses.Visible = True
                    showResponses.Value = True
                Else
                    showResponses.Value = False
                End If
                roResponse.Text = Replace(tbl.Rows(0).Item("Response"), "~", "'")
                txtResponse.Text = Replace(tbl.Rows(0).Item("Response"), "~", "'")
                sUser = getContactTypeAbbr(tbl.Rows(0).Item("ContactType"))
                roCurrentResponse.Text = tbl.Rows(0).Item("ResponseType") & ": " & tbl.Rows(0).Item("Name")
                responseAttachNum.Text = db.countChangeOrderAttachments(nCOID, "Response", sUser, 0, Session("SeqNum"))
                updateResponseAttachment(tbl.Rows(0).Item("SeqNum"), nCOID, False, cboRevisions.SelectedValue)
                lblResponse.Visible = True
                roResponse.Visible = True
                txtResponse.Visible = False
                roCurrentResponse.Visible = True
                lblResponseAttachments.Visible = True
                responseAttachNum.Visible = True
                butResponseAttach.Visible = True
            Catch ex As Exception
                lblResponse.Visible = False
                roResponse.Visible = False
                txtResponse.Visible = False
                roCurrentResponse.Visible = False
                lblResponseAttachments.Visible = False
                responseAttachNum.Visible = False
                butResponseAttach.Visible = False
                cboResponses.Visible = False
            End Try
        End Using
    End Sub
    
    Private Sub configDP()
        If Session("SessionConflict") = True Then
            Dim obj As Object = getSessionConflictData()
        End If
        If Session("CoType") = "COR" Then
            butLeftPanelSelect.Visible = True
        ElseIf Session("CoType") = "PCO" Then
            butLeftPanelSelect.Visible = True
        Else
            butLeftPanelSelect.Visible = False
        End If
        Select Case Trim(WorkFlowPosition.Value)
            Case "None"
                updateResponseAttachment(Session("SeqNum"), nCOID, False, cboRevisions.SelectedValue)
                updateAttachCount()
            Case "DP:Response Pending", "DP:Review Pending"
                If Session("SessionConflict") = True Then
                    setConflictMessage()
                Else
                    If Not IsPostBack Then
                        getResponseData("")
                        updateResponseAttachment(Session("SeqNum"), nCOID, False, cboRevisions.SelectedValue)
                        updateAttachCount()
                        'buildResponseDropdown("Released")                   
                    End If
                    Select Case cboActionSelect.SelectedValue
                        Case "None"
                            Session("SeqNum") = 1
                            Dim isrev As Boolean = checkForOverride()
                            If isrev = True Then
                                lblRevisionMsg.Visible = True
                                configResponseForPM("Edit")
                                itemSelectPanel.Visible = False
                                cboActionSelect.Visible = False
                                cboActionSelect.Visible = False
                            End If
                            configReadOnly()
                            If Not IsPostBack Then
                                cboRevisions.SelectedValue = activeRevision.Value
                                cboRevisions_Change()
                                setCurrentRevision()
                            End If
                            configRevisionDD()
                            updateResponseAttachment(Session("SeqNum"), nCOID, False, cboRevisions.SelectedValue)
                            updateAttachCount()
                            sTitle = "Review Change Order: # " & Session("sTitleDetail")
                            If isrev <> True Then cboActionSelect.Visible = True
                            cboActionSelect.OpenDropDownOnLoad = True
                            butResponseAttach.ImageUrl = "images/button_view.png"
                        Case "Prepare"
                            saveButton.Value = "saveDPResponse"
                            sendButton.Value = "DPSendToPM"
                            configResponsePrepare()
                            'buildResponseDropdown("Released")
                            roCurrentResponse.Visible = False
                            
                            If Session("UpdateData") <> True Then
                                Using db As New ChangeOrders
                                    Dim tbl As DataTable = db.getExistingResponse(nCOID, "DPResponseToCM", nContactID, cboRevisions.SelectedValue)
                                    Try
                                        txtResponse.Text = Replace(tbl.Rows(0).Item("Response"), "~", "'")
                                    Catch ex As Exception
                                        txtResponse.Text = ""
                                    End Try
                                End Using
                            End If
                            updateAttachCount()
                            cboResponses.Visible = False
                            updateResponseAttachment(Session("SeqNum"), nCOID, True, cboRevisions.SelectedValue)
                            'configRevisionDD()
                            cboRevisions.Enabled = False
                        Case "Reject"
                            saveButton.Value = "saveDPResponse"
                            sendButton.Value = "DPSendBackToCM"
                            configResponsePrepare()
                            cboActionSelect.OpenDropDownOnLoad = False
                    End Select
                End If
            Case "PM:Distribution Pending"
                butResponseAttach.ImageUrl = "images/button_view.png"
            Case "PM:Approval Pending", "PM:Review Pending"
                checkForResponse(cboRevisions.SelectedValue, "Released")
                If Not IsPostBack Then
                    buildResponseDropdown("Released")
                End If
                If Not IsPostBack Then
                    cboRevisions.SelectedValue = activeRevision.Value
                    cboRevisions_Change()
                    setCurrentRevision()
                End If
            Case "PM:Approval Pendingxxx"
                Select Case Session("COType")
                    Case "COR"
                        Select Case cboActionSelect.SelectedValue
                            Case "None"
                                cboActionSelect.OpenDropDownOnLoad = True
                                If Not IsPostBack Then
                                    'checkForResponse(cboRevisions.SelectedValue, "")
                                    'getResponseData("COR")
                                    configPMReviewPending()
                                    cboActionSelect.Visible = True
                                    buildResponseDropdown("")
                                End If
                            Case "Prepare"
                                configResponsePrepare()
                                updateAttachCount()
                                cboActionSelect.Visible = True
                                saveButton.Value = "PrepareCORResponse"
                                sendButton.Value = "SubmitCORResponse"
                                alertText = "This action will save your work but will not\nadvance the work flow.\n\nDo you want to continue?"
                                butSave.OnClientClick = "return confirm('" & alertText & "')"
                                alertText = "This action will save your work and advance\nthis item in the work flow.\n\nFurther editing\nwill not be possible.\n\nDo you want to continue?"
                                butSend.OnClientClick = "return confirm('" & alertText & "')"
                                configResponseForPM("Edit")
                        End Select
                    Case Else
                End Select
            Case "CM:Distribution Pending"
                If Not IsPostBack Then
                    checkRevisionRelease()
                    cboRevisions_Change()
                End If
            Case "GC:Receipt Pending", "CM:Completion Pending", "COR Complete", "PM:Completion Pending", "PM:Approval Pending"
                Select Case sCoType
                    Case "COR"
                        checkForResponse(cboRevisions.SelectedValue, "Released")
                        If Not IsPostBack Then
                            buildResponseDropdown("Released")
                        End If
                        If Not IsPostBack Then
                            cboRevisions.SelectedValue = activeRevision.Value
                            cboRevisions_Change()
                            setCurrentRevision()
                        End If
                        updateAttachCount()
                End Select
            Case Else
                configReadOnly()
        End Select
        If Not IsPostBack Then
            butLeftPanelSelect.ImageUrl = "images/button_contract.png"
            butLeftPanelSelect_Click()
        End If
    End Sub
        
    Private Sub configPM()
        If Session("SessionConflict") = True Then
            Dim obj As Object = getSessionConflictData()
        End If
        Dim dec As String = hDecision.Value
        Dim esc As Integer = hEscalate.Value
        Dim strEsc As String = ""
        Dim strRev As String
        If cboRevisions.SelectedValue > 0 Then
            strRev = "Revision #" & cboRevisions.SelectedValue
        Else
            strRev = ""
        End If
        Select Case Trim(WorkFlowPosition.Value)
            Case "PM:Approval Pending"
                If Not IsPostBack Then
                    cboActionSelect.Visible = True
                    cboResponses.SelectedValue = activeRevision.Value
                    checkForResponse(cboRevisions.SelectedValue, "")
                    buildResponseDropdown("")
                    
                End If
                  Select Case cboActionSelect.SelectedValue
                    Case "None"
                        checkForResponse(cboRevisions.SelectedValue, "")
                        sTitle = "Review Change Order:" & strRev & " : " & Session("sTitleDetail")
                        If editReturn.Value = "True" Then
                            'buildResponseDropdown("")
                            configPMReviewPending()
                            editReturn.Value = "False"
                        End If
                       
                        If Not IsPostBack Then
                            cboRevisions.SelectedValue = activeRevision.Value
                            cboRevisions_Change()
                            setCurrentRevision()
                        End If
                        If Trim(activeRevision.Value) = (cboRevisions.SelectedValue).ToString() Then
                            cboActionSelect.Visible = True
                        Else
                            cboActionSelect.Visible = True     '?????? Really?
                        End If
                        updateResponseAttachment(Session("SeqNum"), nCOID, False, cboRevisions.SelectedValue)
                        updateAttachCount()
                        lblFinanceVerified.Visible = True
                        txtFinanceVerified.Visible = False
                        'cboRevisions.Visible = True
                        configRevisionDD()
                        txtResponse.Visible = False
                    Case "PrepApproval"
                        sTitle = "Prepare CO Approved: # " & Session("sTitleDetail")
                        configReadOnly()
                        cboActionSelect.Visible = True
                        cboActionSelect.OpenDropDownOnLoad = False
                        butSave.Visible = True
                        cboResponses_Change()
                        butSave.ImageUrl = "images/button_approve.png"
                        saveButton.Value = "PMApprove"
                        alertText = "This action will set the status of this Change Order to 'Approved'\n and advance to the next work flow position.\n\nDo you want to continue?"
                        butSave.OnClientClick = "return confirm('" & alertText & "')"
                    Case "PMApproveAllowance", "PMApproveChangeOrder"
                        editReturn.Value = "True"
                        updateResponseAttachment(Session("SeqNum"), nCOID, True, cboRevisions.SelectedValue)
                        configReadOnly()
                        lblFinanceVerified.Visible = True
                        txtFinanceVerified.Visible = True
                        sTitle = "Approve Change Order Request: " & strRev & " : " & Session("sTitleDetail")
                        cboActionSelect.OpenDropDownOnLoad = False
                        configResponsePrepare()
                        'cboRevisions.Visible = False
                        'roRevisions.Visible = True
                        
                        'lblDPSelect.Visible = True
                        'cboDPSelect.Visible = True
                        updateAttachCount()
                        saveButton.Value = "savePMResponse"
                        If cboActionSelect.SelectedValue = "PMApproveAllowance" Then
                            sendButton.Value = "PMApproveAllowance"
                        ElseIf cboActionSelect.SelectedValue = "PMApproveChangeOrder" Then
                            sendButton.Value = "PMApproveChangeOrder"
                        End If
                        alertText = "This action will save your work but will not\nadvance the work flow.\n\nDo you want to continue?"
                        butSave.OnClientClick = "return confirm('" & alertText & "')"
                        alertText = "This action will set the status of this Change Order Request\nto Approved and advance to the next work flow position.\n\nDo you want to continue?"
                        butSend.OnClientClick = "return confirm('" & alertText & "')"
                        configRevisionDD()
                    Case "PMRejectCOR"
                        updateResponseAttachment(Session("SeqNum"), nCOID, True, cboRevisions.SelectedValue)
                        configReadOnly()
                        sTitle = "Reject Change Order Request: # " & Session("sTitleDetail")
                        cboActionSelect.OpenDropDownOnLoad = False
                        configResponsePrepare()
                        saveButton.Value = "savePMResponse"
                        sendButton.Value = "PMRejectCOR"
                        alertText = "This action will save your work but will not\nadvance the work flow.\n\nDo you want to continue?"
                        butSave.OnClientClick = "return confirm('" & alertText & "')"
                        alertText = "This action will set the status of this Change Order Request to Not Approved\n and advance to the next work flow position.\n\nDo you want to continue?"
                        butSend.OnClientClick = "return confirm('" & alertText & "')"
                    Case Else
                        buildResponseDropdown("")
                End Select
            Case "PM:Review Pending", "DP:Review Pending", "PM:Review DP Response"
                If Session("SessionConflict") = True Then
                    setConflictMessage()
                Else
                    Select Case cboActionSelect.SelectedValue
                        Case "None"
                            If Not IsPostBack Then
                                cboRevisions.SelectedValue = activeRevision.Value
                                cboRevisions_Change()
                            End If
                            Session("SeqNum") = 1
                            If editReturn.Value = "True" Then
                                configReadOnly()
                                configPMReviewPending()
                                checkForResponse(cboRevisions.SelectedValue, "")
                                butLeftPanelSelect.Visible = True
                                buildResponseDropdown("")
                                editReturn.Value = "False"
                            End If
                            If activeRevision.Value = cboRevisions.SelectedValue Then
                                cboActionSelect.Visible = True
                                cboActionSelect.OpenDropDownOnLoad = True
                            Else
                                cboActionSelect.Visible = False
                            End If
                            updateResponseAttachment(Session("SeqNum"), nCOID, False, cboRevisions.SelectedValue)
                            configRevisionDD()
                            cboRevisions.Enabled = True
                            If Not IsPostBack Then
                                lblResponse.Visible = False
                                roResponse.Visible = False
                                setCurrentRevision()
                            End If
                            responseMsg.Visible = False
                        Case "PMToApprovalPending"
                            editReturn.Value = "True"
                            configResponsePrepare()
                            lblDPSelect.Visible = False
                            cboDPSelect.Visible = False
                            butLeftPanelSelect.Visible = True
                            saveButton.Value = "savePMResponse"
                            sendButton.Value = "PMToApprovalPending"
                            alertText = "This action will save your work but will not\nadvance the work flow.\n\nDo you want to continue?"
                            butSave.OnClientClick = "return confirm('" & alertText & "')"
                            alertText = "This action will advance the work flow to Approval Pending.\n\nDo you want to continue?"
                            butSend.OnClientClick = "return confirm('" & alertText & "')"
                            updateResponseAttachment(Session("SeqNum"), nCOID, True, cboRevisions.SelectedValue)
                            configRevisionDD()
                            configResponseForPM("Edit")
                        Case "PMSendToDP"
                            editReturn.Value = "True"
                            configResponsePrepare()
                            lblDPSelect.Visible = True
                            cboDPSelect.Visible = True
                            butLeftPanelSelect.Visible = True
                            saveButton.Value = "savePMResponse"
                            sendButton.Value = "PMSendToDP"
                            alertText = "This action will save your work but will not\nadvance the work flow.\n\nDo you want to continue?"
                            butSave.OnClientClick = "return confirm('" & alertText & "')"
                            alertText = "This action will set the selected design professinal as the reviewer.\n\nDo you want to continue?"
                            butSend.OnClientClick = "return confirm('" & alertText & "')"
                            configRevisionDD()
                            configResponseForPM("Edit")
                        Case "PMSendBackToCM"
                            editReturn.Value = "True"
                            configResponsePrepare()
                            lblDPSelect.Visible = False
                            cboDPSelect.Visible = False
                            butLeftPanelSelect.Visible = True
                            saveButton.Value = "savePMResponse"
                            sendButton.Value = "PMSendBackToCM"
                            alertText = "This action will save your work but will not\nadvance the work flow.\n\nDo you want to continue?"
                            butSave.OnClientClick = "return confirm('" & alertText & "')"
                            alertText = "This action will send this change order back to the CM.\n\nDo you want to continue?"
                            butSend.OnClientClick = "return confirm('" & alertText & "')"
                            updateResponseAttachment(Session("SeqNum"), nCOID, True, cboRevisions.SelectedValue)
                            configResponseForPM("Edit")
                        Case Else
                    End Select
                End If
            Case "PM:BOD Approval Pending", "PM:Completion Pending"
                'configReadOnly()
                If activeRevision.Value = cboRevisions.SelectedValue Then
                    cboActionSelect.Visible = True
                    cboActionSelect.OpenDropDownOnLoad = True
                Else
                    cboActionSelect.Visible = False
                End If
                Select Case cboActionSelect.SelectedValue
                    Case "None"
                        If editReturn.Value = "True" Then
                            'Session("SeqNum") = 1
                            buildResponseDropdown("")
                            editReturn.Value = "False"
                        End If
                        If Not IsPostBack Then
                            cboRevisions.SelectedValue = activeRevision.Value
                            cboRevisions_Change()
                            setCurrentRevision()
                        End If
                        roBoardApproved.Visible = True
                        txtBoardApproved.Visible = False
                        If Trim(hDecision.Value) = "Approved-Change Order" Then
                            roBoardApproved.Text = "Required"
                        Else
                            roBoardApproved.Text = "Not Required"
                        End If
                        cboRevisions.Enabled = True
                        txtResponse.Visible = False
                        updateResponseAttachment(Session("SeqNum"), nCOID, False, cboRevisions.SelectedValue)
                        sTitle = "Review Change Order: # " & Session("sTitleDetail")
                        cboActionSelect.Visible = True
                        lblBoardApproved.Visible = True
                    Case "PMCloseCOR"
                        Using db As New ChangeOrders
                            Dim decision As String = db.checkDecision(nCOID, activeRevision.Value)
                            decision = Trim(hDecision.Value)
                            If decision = "Approved-Change Order" Then
                                txtBoardApproved.Visible = True
                                roBoardApproved.Visible = False
                            Else
                                roBoardApproved.Text = "Not Required"
                                roBoardApproved.Visible = True
                            End If
                        End Using
                        editReturn.Value = "True"
                        updateResponseAttachment(Session("SeqNum"), nCOID, True, cboRevisions.SelectedValue)
                        updateAttachCount()
                        sTitle = "BOD Approved Change Order: # " & Session("sTitleDetail")
                        configResponsePrepare()
                        saveButton.Value = "PMCloseCOR"
                        butSend.Visible = False
                        butSave.ImageUrl = "images/button_closeCOR.png"
                        'David D 6/20/17 added close COR button image instead of send button since this is the end. Need a Close COR/PCO button as this is only a temp
                        'butSend.ImageUrl = "images/button_closeCOR.png"
                        'David D 6/20/17 close COR button was too close to the cancel button, added styling below
                        'butSend.Style.Add("margin-Left", "-1em")
                        alertText = "This action will save your work but will not\nadvance the work flow.\n\nDo you want to continue?"
                        butSave.OnClientClick = "return confirm('" & alertText & "')"
                        alertText = "This action will close this change order request. No further action will be required.\n\nDo you want to continue?"
                        butSend.OnClientClick = "return confirm('" & alertText & "')"
                        editReturn.Value = "True"
                        configRevisionDD()
                    Case "PMBODApprove" 'this can be removed
                        editReturn.Value = "True"
                        updateResponseAttachment(Session("SeqNum"), nCOID, True, cboRevisions.SelectedValue)
                        sTitle = "BOD Approved Change Order: # " & Session("sTitleDetail")
                        configResponsePrepare()
                        saveButton.Value = "savePMResponse"
                        sendButton.Value = "PMBODApprove"
                        alertText = "This action will save your work but will not\nadvance the work flow.\n\nDo you want to continue?"
                        butSave.OnClientClick = "return confirm('" & alertText & "')"
                        alertText = "This action will send this change order To the CM for acknowledgement.\n\nDo you want to continue?"
                        butSend.OnClientClick = "return confirm('" & alertText & "')"
                        editReturn.Value = "True"
                    Case "PMBODReject" 'this can be removed.
                        editReturn.Value = "True"
                        sTitle = "BOD Not Approved Change Order: # " & Session("sTitleDetail")
                        configResponsePrepare()
                        saveButton.Value = "savePMResponse"
                        sendButton.Value = "PMBODReject"
                        alertText = "This action will save your work but will not\nadvance the work flow.\n\nDo you want to continue?"
                        butSave.OnClientClick = "return confirm('" & alertText & "')"
                        alertText = "This action will send this change order back to the CM for further processing.\n\nDo you want to continue?"
                        butSend.OnClientClick = "return confirm('" & alertText & "')"
                        updateResponseAttachment(Session("SeqNum"), nCOID, True, cboRevisions.SelectedValue)
                    Case Else
                        buildResponseDropdown("")
                End Select
            Case "PM:BOD Not Approved"
                getRevisions()
                cboActionSelect.Visible = True
                Select Case cboActionSelect.SelectedValue
                    Case "None"
                        If cboRevisions.SelectedValue > 0 Then
                            sTitle = "Review Change Order: Revision #" & cboRevisions.SelectedValue & " : " & Session("sTitleDetail")
                        Else
                            sTitle = "Review Change Order: " & cboRevisions.SelectedValue & " : " & Session("sTitleDetail")
                        End If
                        configPMReviewPending()
                    Case "PMReturnCOToCM"
                        configResponsePrepare()
                       
                        getRevisions()
                        If cboRevisions.SelectedValue > 0 Then
                            sTitle = "Review Change Order: Revision #" & cboRevisions.SelectedValue & " : " & Session("sTitleDetail")
                        Else
                            sTitle = "Review Change Order: " & cboRevisions.SelectedValue & " : " & Session("sTitleDetail")
                        End If
                        saveButton.Value = "savePMResponse"
                        sendButton.Value = "PMReturnCOToCM"
                        alertText = "This action will save your work but will not\nadvance the work flow.\n\nDo you want to continue?"
                        butSave.OnClientClick = "return confirm('" & alertText & "')"
                        alertText = "This action will send this change order back to the CM for further processing.\n\nDo you want to continue?"
                        butSend.OnClientClick = "return confirm('" & alertText & "')"
                End Select
            Case "GC:Receipt Pending"
                If Session("SessionConflict") = True Then
                    If editReturn.Value = "True" Then
                        getResponseData("COR")
                        buildResponseDropdown("")
                        configPMReviewPending()
                        editReturn.Value = "False"
                    End If
                    If Not IsPostBack Then
                        cboRevisions.SelectedValue = activeRevision.Value
                        getRevisions()
                        If revisionExists.Value = "True" Then
                            cboRevisions.Visible = True
                        End If
                    End If
                    checkForResponse(cboRevisions.SelectedValue, "Released")
                    setConflictMessage()
                Else
                    If editReturn.Value = "True" Then
                        getResponseData("COR")
                        buildResponseDropdown("")
                        configPMReviewPending()
                        editReturn.Value = "False"
                    End If
                    Select Case cboActionSelect.SelectedValue
                        Case "None"
                            If Not IsPostBack Then
                                configPMReviewPending()
                                checkRevisionRelease()
                                cboRevisions.SelectedValue = activeRevision.Value
                                cboRevisions_Change()
                            End If
                            If revisionExists.Value = "True" Then
                                cboRevisions.Visible = True
                            End If
                            buildResponseDropdown("Released")
                            txtResponse.Visible = False
                            updateResponseAttachment(Session("SeqNum"), nCOID, False, cboRevisions.SelectedValue)
                            updateAttachCount()
                            getRevisions()
                            cboRevisions.Enabled = True
                            If activeRevision.Value = 0 Then
                                cboRevisions.Visible = False
                            End If
                            If revisionExists.Value = "True" Then
                                cboRevisions.Visible = True
                            End If
                            If roDPSelect.Text <> "" Then
                                roDPSelect.Visible = True
                                lblDPSelect.Visible = True
                            End If
                            If sCoType = "PCO" Then
                                roDPSelect.Visible = False
                                lblDPSelect.Visible = False
                            End If
                        Case "PMOverrideGC"
                            sTitle = "Override GC Accept: " & strRev & " : " & Session("sTitleDetail")
                            cboActionSelect.OpenDropDownOnLoad = False
                            configResponsePrepare()
                            getRevisions()
                            cboRevisions.Visible = False
                            butSend.Visible = False
                            butSave.ImageUrl = "images/button_send.png"
                            saveButton.Value = "PMOverrideGCAccept"
                            alertText = "This action will override the GC acceptance step\nand advance to the next work flow position.\n\nDo you want to continue?"
                            butSend.OnClientClick = "return confirm('" & alertText & "')"
                        Case Else
                            editReturn.Value = True
                            sTitle = "Override GC Accept: " & strRev & " : " & Session("sTitleDetail")
                            cboActionSelect.OpenDropDownOnLoad = False
                            configResponsePrepare()
                            getRevisions()
                            cboRevisions.Visible = False
                            'lblRevisions.Visible = True
                            saveButton.Value = "savePMResponse"
                            sendButton.Value = "PMApproveCOR"
                            alertText = "This action will save your work but will not\nadvance the work flow.\n\nDo you want to continue?"
                            butSave.OnClientClick = "return confirm('" & alertText & "')"
                            alertText = "This action will set the status of this Change Order Request\nto Approved and advance to the next work flow position.\n\nDo you want to continue?"
                            butSend.OnClientClick = "return confirm('" & alertText & "')"
                    End Select
                    
                    If activeRevision.Value = cboRevisions.SelectedValue Then
                        cboActionSelect.Visible = True
                    Else
                        cboActionSelect.Visible = False
                    End If
                    
                End If
            Case "CM:Response Pending"
                'configReadOnly()
                cboActionSelect.Visible = False
                'checkForResponse(cboRevisions.SelectedValue, "Released")
                If Not IsPostBack Then
                    buildResponseDropdown("CO")
                End If
                getRevisions()
            Case Else
                configCM()
        End Select
        If Not IsPostBack Then
            butLeftPanelSelect.ImageUrl = "images/button_contract.png"
            butLeftPanelSelect_Click()
            buildResponseDropdown("")
            'getRevisions()
            If WorkFlowPosition.Value = "PM:Approval Pending" Or WorkFlowPosition.Value = "PM:BOD Approval Pending" Or WorkFlowPosition.Value = "PM:Review Pending" Then
                'configResponsePrepare()
                buildResponseDropdown("CO")
                'lblResponse.Visible = True
                'roResponse.Visible = True
            End If
            'checkForResponse(cboRevisions.SelectedValue, "Released")
        End If
    End Sub
    
    Private Sub checkRevisionRelease()
        Using db As New ChangeOrders
            Dim obj As Object = db.checkRevisionRelease(nCOID)
            If obj(1) > 0 Then
                If obj(0) = "Released" Then
                    cboRevisions.SelectedValue = obj(1)
                    roRevisions.Text = obj(1)
                Else
                    cboRevisions.SelectedValue = obj(1) - 1
                    roRevisions.Text = obj(1) - 1
                End If
            Else
                cboRevisions.SelectedValue = 0
                cboRevisions.Visible = False
                lblRevisions.Visible = False
            End If
        End Using
    End Sub
    
    Private Sub setCurrentRevision()
        If activeRevision.Value > 0 Then
            Using db As New ChangeOrders
                Dim tbl As DataTable = db.getRevisionData(nCOID, activeRevision.Value)
                roIssue.Text = Replace(tbl.Rows(0).Item("Issue"), "~", "'")
                txtIssue.Text = Replace(tbl.Rows(0).Item("Issue"), "~", "'")
                txtRequestedCOAmount.Text = tbl.Rows(0).Item("RequestedCOIncrease")
                roRequestedCOAmount.Text = tbl.Rows(0).Item("RequestedCOIncrease")
                updateIssueAttachment("", nCOID, False, activeRevision.Value)
            End Using
        End If
    End Sub
      
    Private Sub setConflictMessage()
        Dim name As String
        cboActionSelect.Visible = False
        Using db As New ChangeOrders
            If conflictID.Value <> "" Then
                name = db.getResponderName(conflictID.Value)
            End If
            conflictMessage.Visible = True
            conflictMessage.Text = "Attention: User Conflict! " & name & " currently has this " & sCoType & " open. Editing is not possible until it is closed."
        End Using
    End Sub
    
    Private Sub configCM()
        Dim rev As Integer
        If Session("SessionConflict") = True Then
            Dim obj As Object = getSessionConflictData()
            setConflictMessage()
        End If
        Select Case Trim(WorkFlowPosition.Value)
            Case "None"
                configNewCO()
                If WorkFlowPosition.Value = "PCO Complete" Or WorkFlowPosition.Value = "COR Complete" Then
                    getResponseData("PCO")
                    cboActionSelect.Visible = False
                End If
            Case "PCO Complete", "PM:Review Pending", "COR Complete", "CO Complete", "PM:BOD Approval Pending", "PM:Approval Pending", "GC:Receipt Pending", "PM:Completion Pending", "DP:Review Pending"
                If Not IsPostBack Then
                    configPMReviewPending()
                    buildPCOList("<b><br/>Related Items<br/><br/>", "PCO")
                End If
                getRevisions()
                If Not IsPostBack Then
                    cboRevisions.SelectedValue = activeRevision.Value
                End If
                updateIssueAttachment(Session("SeqNum"), nCOID, isUpload, cboRevisions.SelectedValue)
                updateAttachCount()
                cboActionSelect.Visible = False
                If Not IsPostBack Then
                    buildResponseDropdown("Released")
                    cboRevisions_Change()
                End If
                If roDPSelect.Text <> "" Then
                    lblDPSelect.Visible = True
                    roDPSelect.Visible = True
                Else
                    lblDPSelect.Visible = False
                    roDPSelect.Visible = False
                End If
                conflictMessage.Visible = False
                If sCoType = "PCO" Then
                    roDPSelect.Visible = False
                    lblDPSelect.Visible = False
                End If
                If sCoType = "COR" Then
                    roBoardApproved.Visible = True
                    lblBoardApproved.Visible = True
                End If
            Case "CM:Completion Pending"
                If Session("sessionConflict") = True Then
                    setConflictMessage()
                    If Not IsPostBack Then
                        cboRevisions_Change()
                    End If
                    If Not IsPostBack Then
                        cboRevisions.SelectedValue = activeRevision.Value
                        getRevisions()
                    End If
                Else
                    Select Case cboActionSelect.SelectedValue
                        Case "None"
                            Select Case Session("CoType")
                                Case "PCO"
                                    sTitle = "Review Potential Change Order: # " & Session("sTitleDetail")
                                    If Not IsPostBack Then
                                        cboRevisions.SelectedValue = activeRevision.Value
                                        getRevisions()
                                        cboRFISelectSwitch.Visible = False
                                        cboRFIReference.Visible = False
                                    End If
                                Case "COR"
                                    If editReturn.Value = "True" Then
                                        getResponseData("COR")
                                        cboResponses_Change()
                                        editReturn.Value = "False"
                                    End If
                                    If Not IsPostBack Then
                                        cboRevisions_Change()
                                    End If
                                    sTitle = "Review Change Order Request: # " & Session("sTitleDetail")
                                Case "CO"
                                    sTitle = "Review Change Order: # " & Session("sTitleDetail")
                            End Select
                            If editReturn.Value = "True" Then
                                Session("SeqNum") = 1
                                editReturn.Value = "False"
                            End If
                            configReadOnly()
                            updateResponseAttachment(Session("SeqNum"), nCOID, False, cboRevisions.SelectedValue)
                            'cboResponses.Visible = True
                            If activeRevision.Value = cboRevisions.SelectedValue Then
                                cboActionSelect.Visible = True
                            Else
                                cboActionSelect.Visible = False
                            End If
                            If Not IsPostBack Then
                                buildResponseDropdown("")
                            End If
                        Case "CMClosePCO"
                            sTitle = "Close Potential Change Order Request: # " & Session("sTitleDetail")
                            configResponsePrepare()
                            updateResponseAttachment(Session("SeqNum"), nCOID, True, cboRevisions.SelectedValue)
                            saveButton.Value = "CMclosePCO"
                            butSave.ImageUrl = "images/button_closePCO.png" 'David D 6/23/17 new close button for PCO's
                            butSend.Visible = False
                            butSave.Visible = True
                            cboActionSelect.OpenDropDownOnLoad = False
                            alertText = "This action will close this PCO.\nNo further action will be required.\n\nDo you want to continue?"
                            butSave.OnClientClick = "return confirm('" & alertText & "')"
                            cboRFISelectSwitch.Visible = False
                            cboRFIReference.Visible = False
                        Case "CMCloseCOR"
                            editReturn.Value = "True"
                            sTitle = "Close Change Order Request: # " & Session("sTitleDetail")
                            configResponsePrepare()
                            updateResponseAttachment(Session("SeqNum"), nCOID, True, cboRevisions.SelectedValue)
                            saveButton.Value = "CMcloseCOR"
                            butSave.ImageUrl = "images/button_closeCOR.png" 'David D 6/23/17 new close button for COR's
                            butSend.Visible = False
                            butSave.Visible = True
                            cboActionSelect.OpenDropDownOnLoad = False
                            updateResponseAttachment(cboResponses.SelectedValue, nCOID, True, cboRevisions.SelectedValue)
                            alertText = "This action will close this COR.\nNo further action will be required.\n\nDo you want to continue?"
                            butSave.OnClientClick = "return confirm('" & alertText & "')"
                        Case "CMCloseCO"
                            editReturn.Value = "True"
                            sTitle = "Close Change Order Request: # " & Session("sTitleDetail")
                            configResponsePrepare()
                            updateResponseAttachment(Session("SeqNum"), nCOID, True, cboRevisions.SelectedValue)
                            saveButton.Value = "CMCloseCO"
                            butSave.ImageUrl = "images/button_close.png"
                            butSend.Visible = False
                            butSave.Visible = True
                            cboActionSelect.OpenDropDownOnLoad = False
                            alertText = "This action will close this Change Order.\nNo further action will be required.\n\nDo you want to continue?"
                            butSave.OnClientClick = "return confirm('" & alertText & "')"
                    End Select
                    updateAttachCount()
                End If
            Case "CM:Review Pending"
                If Session("sessionConflict") = True Then
                    checkForResponse(cboRevisions.SelectedValue, "")
                    buildResponseDropdown("")
                    'configPMReviewPending()
                    setConflictMessage()
                    cboRevisions.SelectedValue = activeRevision.Value
                    If activeRevision.Value > 0 Then
                        setCurrentRevision()
                        getRevisions()
                        cboRevisions_Change()
                    End If
                Else
                    Select Case Session("COType")
                        Case "PCO"
                            cboDPSelect.Visible = False
                            Select Case cboActionSelect.SelectedValue
                                Case "None"
                                    configReadOnly()
                                    sTitle = "Review Potential Change Order: # " & Session("sTitleDetail")
                                    If Not IsPostBack Then
                                        cboRevisions.SelectedValue = activeRevision.Value
                                        refreshRFIDropdown(Request.QueryString("ContractID"))
                                    End If
                                    lblRequiredBy.Visible = True
                                    roRequiredBy.Visible = True
                                    If activeRevision.Value > 0 Then
                                        setCurrentRevision()
                                        getRevisions()
                                        cboRevisions_Change()
                                    End If
                                    updateResponseAttachment(Session("SeqNum"), nCOID, False, cboRevisions.SelectedValue)
                                    updateAttachCount()
                                    updateIssueAttachment(0, nCOID, False, cboRevisions.SelectedValue)
                                    txtResponse.Visible = False
                                    cboRevisions.Enabled = True
                                    'roResponse.Visible = True
                                    If Not IsPostBack Then
                                        checkForResponse(cboRevisions.SelectedValue, "")
                                        'cboRevisions_Change()
                                    End If
                                    'David D 6/7/17 added below condition to hide action menu on lower revisions to match configGC
                                    If Trim(activeRevision.Value) = (cboRevisions.SelectedValue).ToString() Then
                                        cboActionSelect.Visible = True
                                    Else
                                        If Trim(SaveStatus.Value) = "Released" Then
                                            cboActionSelect.Visible = False
                                        Else
                                            cboActionSelect.Visible = True
                                        End If
                                    End If
                                    configResponseForPM("None")
                                    buildResponseDropdown("")
                                Case "Edit", "EditCORRequired"
                                    txtAltReference.Enabled = True
                                    roRequiredBy.Visible = False
                                    txtRequiredBy.Visible = True
                                    editReturn.Value = "True"
                                    If cboActionSelect.SelectedValue = "EditCORRequired" Then
                                        sTitle = "Edit Potential Change Order: # " & Session("sTitleDetail") & " : COR Required"
                                    Else
                                        sTitle = "Edit Potential Change Order: # " & Session("sTitleDetail")
                                    End If
                                    lblDaysInProcess.Visible = False
                                    roDaysInProcess.Visible = False
                                    lblFinanceVerified.Visible = False
                                    updateResponseAttachment(Session("SeqNum"), nCOID, True, cboRevisions.SelectedValue)
                                    updateAttachCount()
                                    updateIssueAttachment(0, nCOID, False, cboRevisions.SelectedValue)
                                    saveButton.Value = "saveCMResponse"
                                    sendButton.Value = "CMSaveSendToGC"
                                    cboRevisions.Visible = False
                                    'lblRevisions.Visible = True 'David D 6/7/17 changed from false to true since the label was missing
                                    configResponseForPM("Edit")
                                    alertText = "This action will save the response and advance\nthis item in the work flow.\n\nA COR will also be automatically generated\nand opened for editing.\n\nDo you want to continue?"
                                    butSend.OnClientClick = "return confirm('" & alertText & "')"
                            End Select
                        Case "CO"
                            Select Case cboActionSelect.SelectedValue
                                Case "None"
                                Case "Edit", "Prepare"
                                    saveButton.Value = "saveCMResponse"
                                    sendButton.Value = "CMSendToPM"
                                Case "CMReturnToGC"
                                    saveButton.Value = "saveGCReturn"
                                    sendButton.Value = "CMReturnToGC"
                            End Select
                            configReadOnly()
                            buildResponseDropdown("Released")
                            configResponsePrepare()
                            If Session("UpdateData") <> True Then
                                Using db As New ChangeOrders
                                    Dim tbl As DataTable = db.getExistingResponse(nCOID, "PMResponseToBoard", nContactID, cboRevisions.SelectedValue)
                                    Try
                                        txtResponse.Text = Replace(tbl.Rows(0).Item("Response"), "~", "'")
                                        Dim sUser As String = getContactTypeAbbr(tbl.Rows(0).Item("R"))
                                        updateResponseAttachment(Session("SeqNum"), nCOID, True, cboRevisions.SelectedValue)
                                    Catch ex As Exception
                                        txtResponse.Text = ""
                                    End Try
                                End Using
                            Else
                                Session("updatedata") = False
                            End If
                    End Select
                End If
            Case "DP:Response Pending"
                sTitle = "Review Change Order: # " & Session("sTitleDetail")
                cboActionSelect.Visible = False
                butResponseAttach.ImageUrl = "images/button_view.png"
                cboDPSelect.Visible = False
            Case "PM:Approval Pendingxxx"
                If Session("ContactType") = "ProjectManager" Then
                Else
                    sTitle = "Review Change Order: # " & Session("sTitleDetail")
                    configReadOnly()
                    If Not IsPostBack Then
                        cboRevisions_Change()
                    End If
                    cboActionSelect.Visible = False
                    butResponseAttach.ImageUrl = "images/button_view.png"
                    updateResponseAttachment(Session("SeqNum"), nCOID, isUpload, cboRevisions.SelectedValue)
                End If
            Case "CM:Distribution Pending"
                If Session("sessionConflict") = True Then
                    If Not IsPostBack Then
                        configReadOnly()
                        cboRevisions_Change()
                        getResponseData("COR")
                    End If
                    If Not IsPostBack Then
                        cboRevisions.SelectedValue = activeRevision.Value
                        cboRevisions_Change()
                        setCurrentRevision()
                    End If
                    setConflictMessage()
                    If txtResponse.Visible = False Then cboResponses.Visible = False
                    If responseAttachNum.Visible = True Then cboResponses.Visible = True
                Else
                    Dim titleTag As String = ""
                    Using db As New ChangeOrders
                        Dim tbl As DataTable = db.getCOIDdata(nCOID)
                        titleTag = " : " & tbl.Rows(0).Item("Decision")
                    End Using
                    Select Case Session("CoType")
                        Case "COR"
                            Select Case cboActionSelect.SelectedValue
                                Case "None"
                                    configReadOnly()
                                    If Not IsPostBack Then
                                        cboActionSelect.Visible = True
                                        cboRevisions.SelectedValue = activeRevision.Value
                                        'cboRevisions_Change()
                                        'setCurrentRevision()
                                        'getRevisions()
                                        cboActionSelect.Visible = True
                                        'checkForExistingRevision("COR")
                                        'checkRevisionRelease()
                                    End If
                                    getRevisions()
                                    configRevisionDD()
                                    cboRevisions.Enabled = True
                                    If cboRevisions.SelectedValue <> activeRevision.Value And cboActionSelect.SelectedValue > activeRevision.Value Then
                                        lblRevisionMsg.Text = "Select active revision #" & activeRevision.Value & " to provide response. Non-active revisions will be canceled."
                                        lblRevisionMsg.Visible = True
                                    Else
                                        lblRevisionMsg.Visible = False
                                    End If
                                    If activeRevision.Value > 0 Then
                                        setCurrentRevision() 'This item gets the current revision not the latest revision that is being prepareed
                                        cboRevisions.Visible = True
                                    End If
                                    
                                    Session("TempRev") = Nothing
                                    sTitle = "Review Change Order Request: # " & Session("sTitleDetail") & titleTag
                                    updateResponseAttachment(Session("SeqNum"), nCOID, False, cboRevisions.SelectedValue)
                                    If responseVisible.Value = "False" Then roCurrentResponse.Visible = True
                                    If revisionExists.Value = "True" Then cboRevisions.Visible = True
                                    If showRevisions.Value = "False" Then cboRevisions.Visible = "False" Else cboRevisions.Visible = "True"
                                    
                                    If Trim(activeRevision.Value) = (cboRevisions.SelectedValue).ToString() Then
                                        cboActionSelect.Visible = True
                                    Else
                                        cboActionSelect.Visible = False
                                    End If
                                   
                                    If Session("ContactType") = "Construction Manager" Then
                                        Dim isrev As Boolean = checkForOverride()
                                        If isrev = True Then
                                            lblRevisionMsg.Visible = True
                                            configResponseForPM("Edit")
                                            itemSelectPanel.Visible = False
                                            cboActionSelect.Visible = False
                                            roDPSelect.Visible = False
                                            lblDPSelect.Visible = False
                                            If responseMsg.Visible = True Then lblRevisionMsg.Visible = False
                                        Else
                                            configResponseForPM("None")
                                        End If
                                    Else
                                        configResponseForPM("None")
                                    End If
                                    If responseMsg.Visible <> True Then
                                        'If roResponse.Visible = False Then cboResponses.Visible = False
                                        'itemSelectPanel.Visible = False
                                        'updateAttachCount()
                                        'setCurrentRevision()
                                        'configRevisionDD()
                                    End If
                                    itemSelectPanel.Visible = False
                                    cboActionSelect.Visible = True
                                    
                                Case "CMReleaseCORGC"
                                    editReturn.Value = "True"
                                    configReadOnly()
                                    getRevisions()
                                    If Session("ContactType") = "Construction Manager" Then
                                        Dim isrev As Boolean = checkForOverride()
                                        If isrev = True Then
                                            lblRevisionMsg.Visible = True
                                            configResponseForPM("Edit")
                                            itemSelectPanel.Visible = False
                                            cboActionSelect.Visible = False
                                        End If
                                    End If
                                    sTitle = "Release Change Order Request to GC: # " & Session("sTitleDetail") & titleTag
                                    Session("TempRev") = Nothing
                                    cboActionSelect.OpenDropDownOnLoad = False
                                    saveButton.Value = "saveCMResponse"
                                    sendButton.Value = "CMReleaseCORGC"
                                    configResponsePrepare()
                                    itemSelectPanel.Visible = False
                                    updateResponseAttachment(Session("SeqNum"), nCOID, True, cboRevisions.SelectedValue)
                                    alertText = "This action will save the response.\nThis will not advance the work flow position.\n\nDo you want to continue?"
                                    butSave.OnClientClick = "return confirm('" & alertText & "')"
                                    alertText = "This action will save the response and release this COR to the General Contractor.\n\nDo you want to continue?"
                                    butSend.OnClientClick = "return confirm('" & alertText & "')"
                                    configRevisionDD()
                                    configResponseForPM("Edit")
                                Case "CMMoveToCONotifyGC"
                                    If Not IsPostBack Then
                                        getResponseData("COR")
                                        cboResponses_Change()
                                    End If
                                    editReturn.Value = True
                                    updateAttachCount()
                                    Session("TempRev") = Nothing
                                    sTitle = "Escalate COR to Change Order: # " & Session("sTitleDetail") & titleTag
                                    cboActionSelect.OpenDropDownOnLoad = False
                                    saveButton.Value = "saveCMResponse"
                                    sendButton.Value = "CMCreateCONotifyGC"
                                    configResponsePrepare()
                                    updateResponseAttachment(Session("SeqNum"), nCOID, True, cboRevisions.SelectedValue)
                                    alertText = "This action will save the response.\nThis will not advance the work flow position.\n\nDo you want to continue?"
                                    butSave.OnClientClick = "return confirm('" & alertText & "')"
                                    alertText = "This action will save the response and notify the\nGeneral Contractor that a Change Order is being created.\n\nDo you want to continue?"
                                    butSend.OnClientClick = "return confirm('" & alertText & "')"
                                Case "CMCreateCORRevision"
                                    If issueOut.Value = "issue out" Then
                                        txtRequestedCOAmount.Text = hRequestedCOAmount.Value
                                        roRequestedCOAmount.Text = hRequestedCOAmount.Value
                                        txtIssue.Text = sIssue.Value
                                        issueOut.Value = ""
                                    End If
                                    TextBoxRequiredValidatorResponse.Enabled = False
                                    editReturn.Value = "True"
                                    getRevisions()
                                    lblRevisionMsg.Visible = False
                                    If Session("ContactType") = "Construction Manager" Then
                                        Dim isrev As Boolean = checkForOverride()
                                        If isrev = True Then
                                            lblRevisionMsg.Visible = True
                                            configResponseForPM("Edit")
                                            itemSelectPanel.Visible = False
                                        Else
                                            configResponseForPM("None")
                                            configNewRevision()
                                            roResponse.Visible = False
                                            itemSelectPanel.Visible = True
                                        End If
                                    Else
                                        configNewRevision()
                                        itemSelectPanel.Visible = True
                                    End If
                                    If Session("ActionChange") = "True" Then
                                        updateSelectedItems(Session("TempRev"))
                                        buildPCOList("<b><br/>Related Items<br/><br/>", "PCO")
                                        configPCODropdown()
                                        Session("ActionChange") = "PCODropdownSet"
                                    End If
                                    cboResponses.Visible = False
                                    butLeftPanelSelect.Visible = False
                                    saveButton.Value = "saveCMCORRevision"
                                    sendButton.Value = "CMReleaseRevisionPM"
                                    alertText = "This action will save the revision.\nThis will not advance the work flow position.\n\nDo you want to continue?"
                                    butSave.OnClientClick = "return confirm('" & alertText & "')"
                                    alertText = "This action will save the revision and notify the\nPM about the new revision.\n\nDo you want to continue?"
                                    butSend.OnClientClick = "return confirm('" & alertText & "')"
                                    If Session("ContactType") = "Construction Manager" Then
                                        txtAltReference.Enabled = True
                                    End If
                                Case "CMEditCORRevision"
                                    configCoEdit()
                                    lblRequiredBy.Visible = False
                                    txtFinanceVerified.Visible = False
                                    txtRequiredBy.Visible = False
                                    configRevisionDD()
                                    'lblFinanceVerified.Visible = False
                                    setCurrentRevision()
                                    saveButton.Value = "saveCMCORRevision"
                                    sendButton.Value = "CMReleaseRevisionPM"
                                    alertText = "This action will save the revision.\nThis will not advance the work flow position.\n\nDo you want to continue?"
                                    butSave.OnClientClick = "return confirm('" & alertText & "')"
                                    alertText = "This action will save the revision and notify the\nPM about the new revision.\n\nDo you want to continue?"
                                    butSend.OnClientClick = "return confirm('" & alertText & "')"
                                    'configNewRevision()
                            End Select
                    End Select
                End If
            Case "GC:Receipt Pendingxxx"
                If Session("sessionConflict") = True Then
                    setConflictMessage()
                Else
                    updateAttachCount()
                    Select Case sCoType
                        Case "PCO", "COR"
                            If Not IsPostBack Then
                                buildResponseDropdown("Released")
                                configPMReviewPending()
                                getRevisions()
                            End If
                            cboActionSelect.Visible = False
                            updateResponseAttachment(Session("SeqNum"), nCOID, False, cboRevisions.SelectedValue)
                        Case "CO"
                            configReadOnly()
                            sTitle = "Review Change Order: # " & Session("sTitleDetail")
                            cboActionSelect.Visible = False
                            butResponseAttach.ImageUrl = "images/button_view.png"
                    End Select
                    If Not IsPostBack Then
                        checkRevisionRelease()
                    End If
                End If
            Case "CM:Response Pending"
                Select Case cboActionSelect.SelectedValue
                    Case "None"
                        If editReturn.Value = "True" Then
                            buildResponseDropdown("")
                            butLeftPanelSelect.ImageUrl = "images/button_contract.png"
                            butLeftPanelSelect_Click()
                            configPMReviewPending()
                            getRevisions()
                            editReturn.Value = "False"
                        End If
                       
                        txtRequestedCOAmount.Visible = False
                        roRequestedCOAmount.Visible = True
                        itemSelectPanel.Visible = False
                        If activeRevision.Value = cboRevisions.SelectedValue Then
                            cboActionSelect.Visible = True
                            cboActionSelect.OpenDropDownOnLoad = True
                        Else
                            cboActionSelect.Visible = False
                        End If
                        Session("TempRev") = Nothing
                    Case "CMCreateRevision"
                        If editReturn.Value <> "True" Then
                            butLeftPanelSelect.ImageUrl = "images/button_contract.png"
                            butLeftPanelSelect_Click()
                        End If
                        txtRequestedCOAmount.Visible = True
                        editReturn.Value = "True"
                        configNewRevision()
                        cboResponses.Visible = False
                        saveButton.Value = "CMSaveCORevision"
                        sendButton.Value = "CMSendCORevision"
                        alertText = "This action will save the revision.\nThis will not advance the work flow position.\n\nDo you want to continue?"
                        butSave.OnClientClick = "return confirm('" & alertText & "')"
                        alertText = "This action will save the revision and notify the\nPM about the new revision.\n\nDo you want to continue?"
                        butSend.OnClientClick = "return confirm('" & alertText & "')"
                End Select
        End Select
        If Not IsPostBack Then
            roRequestedCOAmount.Visible = True
            butLeftPanelSelect.ImageUrl = "images/button_contract.png"
            butLeftPanelSelect_Click()
            If WorkFlowPosition.Value = "PM:Approval Pending" Then
                buildResponseDropdown("Released")
            End If
           
        End If
    End Sub
       
    Private Sub configResponseForPM(type As String)
        Dim str As String
        Using db As New ChangeOrders
            str = db.checkForResponsePrepare(nCOID, nContactID)
        End Using
        
        If type = "None" Then
            responseMsg.Visible = False
            'roResponse.Visible = False
            If Session("ContactType") <> "ProjectManager" Then
                If str <> "none" Then
                    cboResponses.Visible = False
                    roResponse.Visible = False
                    lblResponse.Visible = False
                    lblResponseAttachments.Visible = False
                    responseAttachNum.Visible = False
                    butResponseAttach.Visible = False
                    roCurrentResponse.Visible = False
                    txtResponse.Visible = False
                Else
                    roResponse.Visible = True
                End If
            End If
            
            If cboResponses.Visible = True Then
                roResponse.Visible = True
            End If
            Try
                If initResponseID.Value = nContactID Then
                    roResponse.Visible = True
                End If
            Catch ex As Exception
            End Try
        ElseIf type = "Edit" Then
            If str <> "none" Then
                If Session("ContactType") = "Construction Manager" Or Session("ContactType") = "Design Professional" Then
                    If type <> "None" Then
                        responseMsg.Text = str & " has a response that is being prepared. Another response or revision cannot be created at this time!"
                        responseMsg.Visible = True
                    Else
                        responseMsg.Visible = False
                        roResponse.Visible = False
                    End If
                    cboResponses.Visible = False
                    roResponse.Visible = False
                    lblResponse.Visible = False
                    lblResponseAttachments.Visible = False
                    responseAttachNum.Visible = False
                    butResponseAttach.Visible = False
                    roCurrentResponse.Visible = False
                    txtResponse.Visible = False
                    butSave.Visible = False
                    butSend.Visible = False
                Else
                    responseMsg.Text = str & " has a response that is being prepared. Creating a response here will cancel the other response!"
                    responseMsg.Visible = True
                    configResponsePrepare()
                End If
            Else
                responseMsg.Visible = False
                'Dim tbl As DataTable = db.getCOResponses(nCOID, cboRevisions.SelectedValue, "", nContactID)
                checkForResponse(cboRevisions.SelectedValue, "")
                roResponse.Visible = True
                configResponsePrepare()
            End If
        End If
    End Sub
    
    Private Sub configRevisionDD()
        Try
            If revisionExists.Value = True Then
                If cboActionSelect.SelectedValue <> "None" Then
                    cboRevisions.Enabled = False
                Else
                    cboRevisions.Enabled = True
                End If
            Else
                cboRevisions.Enabled = True
            End If
        Catch ex As Exception
        End Try
    End Sub
    
    Private Sub configPMReviewPending()
        configReadOnly()
        getRevisions()
        cboActionSelect.Visible = False
        getResponseData(sCoType)
        Dim strRev As String = ""
        If cboRevisions.SelectedValue > 0 Then
            strRev = "Revision #" & cboRevisions.SelectedValue & " : "
        Else
            strRev = ""
        End If
        Select Case sCoType
            Case "PCO"
                sTitle = "Review Potential Change Order: " & strRev & "# " & Session("sTitleDetail")
            Case "COR"
                sTitle = "Review Change Order Request: " & strRev & "# " & Session("sTitleDetail")
            Case "CO"
                sTitle = "Review Change Order: " & strRev & "# " & Session("sTitleDetail")
        End Select
        updateResponseAttachment(Session("SeqNum"), nCOID, False, cboRevisions.SelectedValue)
    End Sub
    
    Private Sub configGC()
        If Session("sessionConflict") = True Then
            Dim obj As Object = getSessionConflictData()
            setConflictMessage()
        End If
        lblRequiredBy.Visible = False
        txtRequiredBy.Visible = False
        Select Case Trim(WorkFlowPosition.Value)
            Case "None", "PCO Complete", "COR Complete", "PM:BOD Approval Pending", "CO Complete"
                Select Case sCoType
                    Case "PCO"
                        configReadOnly()
                        sTitle = "Review Potential Change Order: # " & Session("sTitleDetail")
                        If Not IsPostBack Then
                            
                        End If
                    Case "COR", "CO"
                        configReadOnly()
                        roResponse.Visible = True
                        lblResponseAttachments.Visible = True
                        responseAttachNum.Visible = True
                        butResponseAttach.Visible = True
                        If Not IsPostBack Then
                            cboRevisions.SelectedValue = activeRevision.Value
                            cboRevisions_Change()
                            setCurrentRevision()
                        End If
                        If sCoType = "COR" Then
                            sTitle = "Review Change Order Request: # " & Session("sTitleDetail")
                        ElseIf sCoType = "CO" Then
                            sTitle = "Review Change Order: # " & Session("sTitleDetail")
                        End If
                End Select
                updateAttachCount()
                If isInitiator.Value = True Then
                    configReadOnly()
                    Select Case cboActionSelect.SelectedValue
                        Case "None"
                            cboActionSelect.Visible = True
                            updateIssueAttachment(0, nCOID, False, cboRevisions.SelectedValue)
                            updateResponseAttachment(Session("SeqNum"), nCOID, False, cboRevisions.SelectedValue)
                            txtAltReference.Enabled = False
                        Case "Edit"
                            configCoEdit()
                            If butLeftPanelSelect.ImageUrl = "images/button_contract.png" Then
                                RFISelectPanel.Visible = True
                            End If
                            updateResponseAttachment(Session("SeqNum"), nCOID, True, cboRevisions.SelectedValue)
                            updateIssueAttachment(0, nCOID, True, cboRevisions.SelectedValue)
                            txtAltReference.Enabled = True
                        Case Else
                            configNewCO()
                            cboDPSelect.Visible = False
                            cboActionSelect.Visible = True
                            sendButton.Value = "GCSendToCM"
                            lblRequiredBy.Visible = False
                            txtRequiredBy.Visible = False
                    End Select
                Else
                    If WorkFlowPosition.Value = "None" Then
                        configReadOnly()
                        isUpload = False
                        cboActionSelect.Visible = False
                        lblResponseAttachments.Visible = False
                        responseAttachNum.Visible = False
                        butResponseAttach.Visible = False
                        lblResponse.Visible = False
                        roResponse.Visible = False
                    End If
                End If
                If WorkFlowPosition.Value = "None" Then
                    roResponse.Visible = False
                    txtResponse.Visible = False
                    lblResponse.Visible = False
                    lblResponseAttachments.Visible = False
                    responseAttachNum.Visible = False
                    butResponseAttach.Visible = False
                    'updateIssueAttachment(0, nCOID, False, cboRevisions.SelectedValue)
                End If
                If WorkFlowPosition.Value = "PCO Complete" Or WorkFlowPosition.Value = "COR Complete" Then
                    If Not IsPostBack Then
                        getResponseData("PCO")
                    End If
                    cboActionSelect.Visible = False
                End If
                If WorkFlowPosition.Value = "PCO Complete" Then
                    lblFinanceVerified.Visible = False
                    lblDaysInProcess.Visible = False
                    roDaysInProcess.Visible = False
                ElseIf WorkFlowPosition.Value = "COR Complete" Then
                    lblFinanceVerified.Visible = True
                    roFinanceVerified.Visible = True
                    lblDaysInProcess.Visible = True
                    roDaysInProcess.Visible = True
                    lblBoardApproved.Visible = True
                    roBoardApproved.Visible = True
                End If
            Case "CM:Review Pending"
                configPMReviewPending()
            Case "DP:Response Pending", "PM:Approval Pending"
                sTitle = "Review Change Order: # " & Session("sTitleDetail")
                If WorkFlowPosition.Value = "PM:Approval Pending" Then
                    If Not IsPostBack Then
                        cboRevisions.SelectedValue = 0
                    End If
                    cboRevisions_Change()
                End If
                configPMReviewPending()
            Case "GC:Receipt Pending"
                If Session("sessionConflict") = True Then
                    setConflictMessage()
                Else
                    Select Case sCoType
                        Case "PCO", "COR"
                            Dim dec As String = hDecision.Value
                            Dim esc As Integer = hEscalate.Value
                            Dim strEsc As String = ""
                            Dim strRev As String
                            'cboRevisions.SelectedValue = activeRevision.Value
                            If cboRevisions.SelectedValue > 0 Then
                                strRev = "Revision #" & cboRevisions.SelectedValue & " : "
                            Else
                                strRev = ""
                            End If
                            Select Case sCoType
                                Case "PCO"
                                    If esc = 1 Then strEsc = "COR Required"
                                    sTitle = "Review Potential Change Order: " & strRev & Session("sTitleDetail") & " : " & dec & " : " & strEsc
                                Case "COR"
                                    If esc = 1 Then strEsc = "CO Required"
                                    sTitle = "Review Change Order Request: " & strRev & Session("sTitleDetail") & " : " & dec & " : " & strEsc
                            End Select
                            If cboRevisions.SelectedValue <> activeRevision.Value And cboActionSelect.SelectedValue > activeRevision.Value Then
                                lblRevisionMsg.Text = "Select active revision #" & activeRevision.Value & " to provide response. Non-active revisions will be canceled."
                                lblRevisionMsg.Visible = True
                            Else
                                lblRevisionMsg.Visible = False
                            End If
                            Select Case cboActionSelect.SelectedValue
                                Case "None"
                                    'David D 6/7/17 matched below code to the configCM "None" case (commented out code not needed)
                                    configReadOnly()
                                    'David D 6/7/17 added below condition to set current value for revisions
                                    If activeRevision.Value > 0 Then
                                        setCurrentRevision() 'This item gets the current revision not the latest revision that is being prepareed
                                        cboRevisions.Visible = True
                                    End If
                                    'cboRevisions_Change()                                    
                                    'buildResponseDropdown("")
                                   
                                    If Not IsPostBack Then
                                        configRevisionDD()
                                    End If
                                    If Trim(activeRevision.Value) = (cboRevisions.SelectedValue).ToString() Then
                                        cboActionSelect.Visible = True
                                    Else
                                        If Trim(SaveStatus.Value) = "Released" Then
                                            cboActionSelect.Visible = True
                                        Else
                                            cboActionSelect.Visible = False
                                        End If
                                    End If
                                    Try
                                        If showResponses.Value = True Then
                                            cboResponses.Visible = True
                                        End If
                                    Catch ex As Exception
                                    End Try
                                    cboRevisions.Enabled = True
                                    configResponseForPM("None")
                                    updateResponseAttachment(Session("SeqNum"), nCOID, False, cboRevisions.SelectedValue)
                                    updateIssueAttachment(0, nCOID, False, cboRevisions.SelectedValue)
                                    updateAttachCount()
                                Case "GCAcceptCMResponse"
                                    configReadOnly()
                                    getRevisions()
                                    cboRevisions.Visible = False
                                    roRevisions.Text = activeRevision.Value
                                    
                                    txtIssue.Visible = False
                                    roIssue.Visible = True
                                    cboActionSelect.Visible = True
                                    cboActionSelect.OpenDropDownOnLoad = False
                                    configResponsePrepare()
                                    butSave.Visible = False
                                    butSend.Visible = True
                                    If Session("UpdateData") <> True Then
                                        txtResponse.Text = ""
                                    Else
                                        Session("UpdateData") = False
                                    End If
                                    updateResponseAttachment(Session("SeqNum"), nCOID, True, cboRevisions.SelectedValue)
                                    sendButton.Value = "GCAcceptCMResponse"
                                    updateAttachCount()
                                    alertText = "This action will accept the response from the CM\nand advance to the next work flow position.\n\nDo you want to continue?"
                                    butSend.OnClientClick = "return confirm('" & alertText & "')"
                                    
                                    'ContractDetailPanel_B.Visible = False
                                    'RFISelectPanel.Visible = False
                                    
                                    cboRFISelectSwitch.Visible = False
                                    cboRFIReference.Visible = False
                                    
                                    'lblRFIItems.Visible = True
                                    'roRFIItems.Visible = True
                                   
                                    'Exit Sub
                                Case "CreateRevision"
                                    TextBoxRequiredValidatorResponse.Enabled = False 'David D added to stop text validation when creating a revision
                                    configReadOnly()
                                    configNewRevision()
                                    setActionVisibility()
                                    configRequiredByDate()
                                    Using db As New ChangeOrders
                                        Dim tbl As DataTable = db.checkForRevision(nCOID, nContactID, Session("ContactType"), "owner")
                                        'If Session("TempRev") > activeRevision.Value Then
                                        If tbl.Rows.Count = 0 Then
                                            ContractDetailPanel_B.Visible = False
                                            RFISelectPanel.Visible = False
                                            butLeftPanelSelect.Visible = False
                                            butSend.Visible = False
                                            lblRFIItems.Visible = False
                                            roRFIItems.Visible = False
                                            lblRequiredBy.Visible = False
                                        Else
                                            txtRequiredBy.Visible = True
                                        End If
                                    End Using
                                    'lblRevisions.Visible = True 'David D 6/7/17 added missing label
                                    cboRevisions.Visible = False 'David D 6/7/17 added to eliminate dropdown for revision
                                    roRevisions.Text = Session("TempRev").ToString 'David D 6/7/17 added to show new revision number
                                    If cboRevisions.SelectedValue < Session("TempRev") Then
                                        butLeftPanelSelect_Click()
                                        cboRevisions.SelectedValue = Session("TempRev")
                                    End If
                                    roRevisions.Visible = True
                                    cboActionSelect.Visible = True 'David D 6/7/17 added to allow user to change their mind on the revision and accept or review as well
                                    cboActionSelect.OpenDropDownOnLoad = False 'David D 6/7/17 added to prevent too many moving parts
                                    lblRevisionMsg.Visible = False
                                    Dim revCheck As Boolean = checkForExistingRevision("owner")
                                    'David D 6/7/17 added condition below to change the create button to the save button after a revision is created
                                    If activeRevision.Value < Session("TempRev") And revCheck = False Then
                                        butSave.ImageUrl = "images/button_create.gif"
                                        'butSave.Visible = False
                                        saveButton.Value = "GCRevisionCreate"
                                        butSave.Visible = True
                                        butSend.Visible = False
                                        ContractDetailPanel_B.Visible = False
                                        txtIssue.Text = ""
                                    Else
                                        butSave.ImageUrl = "images/button_save.gif"
                                        saveButton.Value = "GCSaveRevision"
                                    End If
                                    itemSelectPanel.Visible = False
                                    If butLeftPanelSelect.ImageUrl = "images/button_contract.png" Then
                                        RFISelectPanel.Visible = True
                                        ContractDetailPanel_A.Visible = False
                                        ContractDetailPanel_B.Visible = False
                                        cboRFISelectSwitch.Visible = True
                                        cboRFIReference.Visible = True
                                    End If
                                    'David D 6/7/17 added below condition to set the current revision
                                    If activeRevision.Value > Session("TempRev") Then
                                        setCurrentRevision()
                                        cboRevisions.Visible = True
                                    End If
                                    sendButton.Value = "GCSendRevisionToCM"
                                    'David D 6/8/17 created below condition to toggle click/altertext  and tool tip for create/save buttons
                                    If saveButton.Value = "GCRevisionCreate" Then
                                        alertText = "This action will create and save the new revision \nand will not advance to the next work flow position.\n\nDo you want to continue?"
                                        butSave.OnClientClick = "return confirm('" & alertText & "')"
                                        'David D 6/7/17 added tooltip below - can be removed
                                        butSave.ToolTip = "This action will create and save the new revision and will not advance to the next work flow position."
                                    ElseIf saveButton.Value = "GCSaveRevision" Then
                                        alertText = "This action will save the new revision \nand will not advance to the next work flow position.\n\nDo you want to continue?"
                                        butSave.OnClientClick = "return confirm('" & alertText & "')"
                                        'David D 6/7/17 added tooltip below - can be removed
                                        butSave.ToolTip = "This action will save the new revision and will not advance to the next work flow position."
                                    End If
                                    alertText = "This action will save the new revision, send to the CM\nand advance to the next work flow position.\n\nDo you want to continue?"
                                    butSend.OnClientClick = "return confirm('" & alertText & "')"
                                    'David D 6/7/17 added tooltip below - can be removed
                                    butSend.ToolTip = "This action will save the new revision, send to the CM and advance to the next work flow position."
                                    'David D 6/7/17 added the below cancel button text alert and tool tip - can be removed
                                    alertText = "This action will close the current screen and any unsaved information will be lost.\n\nDo you want to continue?"
                                    butCancel.OnClientClick = "return confirm('" & alertText & "')"
                                    butCancel.ToolTip = "This action will close the current screen and any unsaved information will be lost."
                                Case "GCAcceptCORApproval"
                                    editReturn.Value = "True"
                                    sTitle = "Acknowledge Recipt of Approved Change Order: # " & Session("sTitleDetail")
                                    'cboRevisions.Visible = False
                                    'lblRevisions.Visible = False
                                    configRevisionDD()
                                    
                                    configResponsePrepare()
                                    Using db As New ChangeOrders
                                        responseAttachNum.Text = db.countChangeOrderAttachments(nCOID, "Response", "GC", cboRevisions.SelectedValue, Session("SeqNum"))
                                    End Using
                                    updateResponseAttachment(Session("SeqNum"), nCOID, True, cboRevisions.SelectedValue)
                               
                                    butSend.Visible = False
                                    butSave.ImageUrl = "images/button_send.png"
                                    saveButton.Value = "AcknowledgeCORApproval"
                                    alertText = "This action will save your response, and acknowlege reciept of this approved COR. No further action is required.\n\nDo you want to continue?"
                                    butSave.OnClientClick = "return confirm('" & alertText & "')"
                            End Select
                        Case "CO"
                            Select Case cboActionSelect.SelectedValue
                                Case "None"
                                    configReadOnly()
                                    cboActionSelect.Visible = True
                                    buildResponseDropdown("Released")
                                    butSave.Visible = False
                                    sTitle = "Review Change Order: # " & Session("sTitleDetail")
                                Case "GCSendReceipt"
                                    configReadOnly()
                                    sTitle = "Confirm Change Order Received: # " & Session("sTitleDetail")
                                    cboActionSelect.Visible = True
                                    cboActionSelect.OpenDropDownOnLoad = False
                                    sendButton.Value = "GCReceiveReceipt"
                                    butResponseAttach.ImageUrl = "images/button_view.png"
                                    buildResponseDropdown("Released")
                                    butSave.Visible = True
                                    saveButton.Value = "GCSendReceived"
                                    butSave.ImageUrl = "images/button_confirm.png"
                                    alertText = "This action will confirm that you have receiving this\napproved Change Order. No further action will be required.\n\nDo you want to continue?"
                                    butSave.OnClientClick = "return confirm('" & alertText & "')"
                            End Select
                    End Select
                End If
            Case "CM:Distribution Pending"
                configReadOnly()
                If Not IsPostBack Then
                    cboRevisions_Change()
                    butLeftPanelSelect.ImageUrl = "images/button_contract.png"
                    butLeftPanelSelect_Click()
                End If
                'getResponseData("COR")
                roResponse.Visible = True
                updateResponseAttachment(Session("SeqNum"), nCOID, False, cboRevisions.SelectedValue)
                'updateAttachCount()         
            Case "CM:Completion Pending"
                'configReadOnly()
                If Not IsPostBack Then
                    cboRevisions_Change()
                End If
                updateAttachCount()
            Case Else
                'If Not IsPostBack Then
                configReadOnly()
                'End If
        End Select
        If Not IsPostBack Then
            butLeftPanelSelect.ImageUrl = "images/button_contract.png"
            butLeftPanelSelect_Click()
            buildResponseDropdown("Released")
            updateAttachCount()
        End If
        If WorkFlowPosition.Value = "PCO Complete" Then
            'buildResponseDropdown("Released")
            cboResponses.Visible = True
            updateAttachCount()
        End If
    End Sub
    
    Private Sub configRequiredByDate()
        Dim zDate As String
        Using db As New ChangeOrders
            zDate = db.getRequiredByDate(nCOID, cboRevisions.SelectedValue)
            Try
                txtRequiredBy.DbSelectedDate = zDate
            Catch ex As Exception
            End Try
            roRequiredBy.Text = zDate
        End Using
    End Sub
    
    Private Function checkForExistingRevision(type As String) As Boolean
        Using db As New ChangeOrders
            Dim tbl As DataTable = db.checkForRevision(nCOID, nContactID, Session("ContactType"), type)
            If tbl.Rows.Count > 0 Then
                Return True
            Else
                Return False
            End If
        End Using
    End Function
    
    Private Function checkForOverride() As Boolean
        Dim tbl As DataTable = Nothing
        Using db As New ChangeOrders
            tbl = db.checkForRevision(nCOID, nContactID, Session("ContactType"), "non-owner")
            If tbl.Rows.Count > 0 Then
                Return True
            Else
                tbl = db.checkForResponse(nCOID, nContactID, Session("ContactType"))
                If tbl.Rows.Count > 0 Then
                    Return True
                Else
                    Return False
                End If
            End If
        End Using
    End Function
    
    Private Sub setActionVisibility()
        If cboRevisions.SelectedValue <> activeRevision.Value + 1 Then
            cboActionSelect.Visible = False
        Else
            If showAction.Value = "True" Then
                cboActionSelect.Visible = True
            End If
        End If
    End Sub
    
    Private Sub configResponsePrepare()
        Select Case cboActionSelect.SelectedValue
            Case "none"
                txtResponse.Visible = False
                roResponse.Visible = True
                butSave.Visible = False
                butSend.Visible = False
                cboActionSelect.Visible = True
                cboDPSelect.Visible = False
                roDPSelect.Visible = True
                cboRevisions.Enabled = True
            Case Else '"Edit", "Prepare", "CMReturnToGC", "Reject", "GCAcceptCMResponse", "CMClosePCO", "ApproveCOR", "RejectCOR"
                txtResponse.Enabled = True
                lblResponse.Visible = True
                txtResponse.Visible = True
                roResponse.Visible = False
                alertText = "This action will save your work but will not\nadvance the work flow.\n\nDo you want to continue?\n\n"
                butSave.OnClientClick = "return confirm('" & alertText & "')"
                alertText = "This action will save your work and advance\nthis item in the work flow.\n\n Further editing will not be possible.\n\nDo you want to continue?\n\n"
                butSend.OnClientClick = "return confirm('" & alertText & "')"
                cboRFISelectSwitch.Visible = True
                cboRFIReference.Visible = True
                cboResponses.Visible = False
                roCurrentResponse.Visible = False
                cboActionSelect.Visible = True
                cboActionSelect.OpenDropDownOnLoad = False
                butSave.Visible = True
                butSend.Visible = True
                isUpload = False
                butResponseAttach.ImageUrl = "images/button_upload_view.png"
                butIssueAttach.ImageUrl = "images/button_upload_view.png"
                lblResponseAttachments.Visible = True
                butResponseAttach.Visible = True
                responseAttachNum.Visible = True
               
                If Session("COType") = "CO" Then
                    roDPSelect.Visible = True
                    cboDPSelect.Visible = False
                End If
                txtIssue.Visible = False
                roIssue.Visible = True
                cboRevisions.Enabled = False
                If Session("ContactType") = "Construction Manager" Then
                    txtAltReference.Enabled = True
                End If
        End Select
        
        Dim tbl As DataTable
        Using db As New ChangeOrders
            tbl = db.getPreparingResponse(nCOID, cboRevisions.SelectedValue, nContactID, Session("ContactType"))
        End Using
        If tbl.Rows.Count > 0 Then
            For Each row As DataRow In tbl.Rows
                If row.Item("ResponseBy") = nContactID Then
                    txtResponse.Text = Replace(tbl.Rows(0).Item("Response"), "~", "'")
                    roResponse.Text = Replace(tbl.Rows(0).Item("Response"), "~", "'")
                    Session("SeqNum") = tbl.Rows(0).Item("SeqNum")
                End If
            Next
        Else
            txtResponse.Text = ""
            Using db As New ChangeOrders
                Dim countTbl As DataTable = db.countResponses(nCOID, cboRevisions.SelectedValue)
                Session("SeqNum") = countTbl.Rows.Count + 1
            End Using
        End If
        updateResponseAttachment(Session("SeqNum"), nCOID, True, cboRevisions.SelectedValue)
    End Sub
    
    Private Sub configNewCO()
        configReadOnly()
        Select Case cboActionSelect.SelectedValue
            Case "None"
                cboActionSelect.Visible = True
                isUpload = False
                configRightBox()
                cboInitiatedBy.Visible = False
                roInitiatedBy.Visible = True
                lblResponseAttachments.Visible = False
                responseAttachNum.Visible = False
                butResponseAttach.Visible = False
                lblResponse.Visible = False
                roResponse.Visible = False
                roRequestedCOAmount.Visible = True
                cboDPSelect.Visible = False
                txtRequestedCOAmount.Visible = False
                butLeftPanelSelect.Visible = True
                itemSelectPanel.Visible = False
                If editReturn.Value = "True" Then
                    butLeftPanelSelect_Click()
                    editReturn.Value = "False"
                End If
                lblFinanceVerified.Visible = False
            Case "Edit"
                'David D 6/12/17 condition with roPCODisplay was needed for PCO to COR conversion by CM
                If roPCODisplay.Visible = True Then
                    TextBoxRequiredValidatorResponse.Enabled = False
                    TextBoxRequiredValidatorSummary.Enabled = False
                    TextBoxRequiredValidatorSummaryCO.Enabled = True
                End If
                editReturn.Value = "True"
                'sTitle = "Edit Change Order: # " & Session("sTitleDetail")
                configInitiatedBy()
                Using db As New ChangeOrders
                    cboInitiatedBy.SelectedValue = db.getInitiatedBy(nCOID)
                End Using
                cboActionSelect.OpenDropDownOnLoad = False
                lblDPSelect.Visible = False
                cboDPSelect.Visible = False
                cboActionSelect.Visible = True
                alertText = "This action will save your work but will not\nadvance the work flow.\n\nDo you want to continue?"
                butSave.OnClientClick = "return confirm('" & alertText & "')"
                alertText = "This action will save your work and advance\nthis item in the work flow. Further editing\nwill not be possible.\n\nDo you want to continue?"
                butSend.OnClientClick = "return confirm('" & alertText & "')"
                isUpload = True
                lblResponseAttachments.Visible = False
                responseAttachNum.Visible = False
                butResponseAttach.Visible = False
                lblResponse.Visible = False
                roResponse.Visible = False
                roRequestedCOAmount.Visible = False
                txtRequestedCOAmount.Visible = True
                roInitiatedBy.Visible = True
                cboInitiatedBy.Visible = False
                itemSelectPanel.Visible = True
                txtRequestedCOAmount.Visible = True
                CORequestAmountDateChange.Visible = True
                sendButton.Value = "CMSendToPM"
                ContractDetailPanel_A.Visible = False
                ContractDetailPanel_B.Visible = False
                roItemsDisplay.Visible = True
                txtIssue.Visible = True
                SelectedItemDetailPanel.Visible = True
                txtSubject.Visible = True
                roSubject.Visible = False
                butLeftPanelSelect.Visible = False
                butSave.Visible = True
                butSend.Visible = True
                If Session("ContactType") = "Construction Manager" Then
                    txtAltReference.Enabled = True
                End If
        End Select
        If cboActionSelect.SelectedValue <> "None" Then
            updateIssueAttachment(Session("SeqNum"), nCOID, True, cboRevisions.SelectedValue)
            butIssueAttach.ImageUrl = "images/button_upload_view.png"
        Else
            updateIssueAttachment(Session("SeqNum"), nCOID, False, cboRevisions.SelectedValue)
            butIssueAttach.ImageUrl = "images/button_view.png"
        End If
        Select Case sCoType
            Case "PCO"
                lblRequiredBy.Visible = False
                txtRequiredBy.Visible = False
                ContractDetailPanel_A.Visible = True
            Case "COR"
                sendButton.Value = "CMSendToPM"
            Case "CO"
                sendButton.Value = "CMSendCOToPM"
            Case Else
        End Select
    End Sub
    
    Private Sub buildResponseDropdown(type As String)
        Using db As New ChangeOrders
            Dim tbl As DataTable = db.getCOResponses(nCOID, cboRevisions.SelectedValue, type, nContactID)
            
            If tbl.Rows.Count > 1 Then
                Dim i As Integer = 0
                Dim u As Integer = 0
                Dim resTbl As DataTable
                resTbl = New DataTable("resTbl")
                resTbl.Columns.Add("Action", GetType(System.String))
                resTbl.Columns.Add("ActionText", GetType(System.String))
                For Each row As DataRow In tbl.Rows
                    If row.Item("ResponseBy") = nContactID Or Trim(row.Item("SaveStatus")) = "Released" Then
                        i = i + 1
                        If row.Item("ResponseBy") = nContactID And Trim(row.Item("SaveStatus")) <> "Released" Then
                            u = row.Item("SeqNum") - 1
                            If Session("ContactType") = "Design Professional" Then
                                If Trim(row.Item("SaveStatus")) = "Released" Then cboActionSelect.Visible = False
                            End If
                        Else
                            u = i - 1
                        End If
                        resTbl.Rows.Add(row.Item("PMCOResponseID"), i & " - " & row.Item("ResponseType") & ": " & row.Item("Name"))
                    End If
                Next
                
                'If Not IsPostBack Then
                Try
                    With cboResponses
                        .DataValueField = "Action"
                        .DataTextField = "ActionText"
                        .DataSource = resTbl
                        '.SelectedIndex = resTbl.Rows.Count
                        .DataBind()
                    End With
                Catch ex As Exception
                End Try
                If i > 1 Then
                    cboResponses.Visible = True
                    roCurrentResponse.Visible = False
                    responseVisible.Value = "True"
                    'editReturn.Value = "True"
                Else
                    cboResponses.Visible = False
                    roCurrentResponse.Visible = True
                    responseVisible.Value = "False"
                End If
                ' If Not IsDBNull(tbl.Rows(u).Item("Response")) Then
                roResponse.Text = Replace(tbl.Rows(u).Item("Response"), "~", "'")
                roResponse.Visible = True
                lblResponse.Visible = True
                lblResponseAttachments.Visible = True
                responseAttachNum.Visible = True
                butResponseAttach.Visible = True
                'txtResponse.Text = Replace(tbl.Rows(0).Item("Response"), "~", "'")
                Session("SeqNum") = tbl.Rows(u).Item("SeqNum")
                cboResponses.SelectedValue = tbl.Rows(u).Item("PMCOResponseID")
                Dim sUser As String = getContactTypeAbbr(tbl.Rows(u).Item("ContactType"))
                roCurrentResponse.Text = sUser & ":" & tbl.Rows(u).Item("ResponseType")
                responseAttachNum.Text = db.countChangeOrderAttachments(nCOID, "Response", sUser, cboRevisions.SelectedValue, Session("SeqNum"))
                updateResponseAttachment(Session("SeqNum"), nCOID, False, cboRevisions.SelectedValue)
                itemSelectPanel.Visible = False
                'End If
            Else
                If tbl.Rows.Count > 0 Then
                    roCurrentResponse.Text = tbl.Rows(0).Item("ResponseType") & ": " & tbl.Rows(0).Item("Name")
                    txtResponse.Text = Replace(tbl.Rows(0).Item("Response"), "~", "'")
                    'roCurrentResponse.Text = "You are Here"
                    roCurrentResponse.Visible = True
                    roResponse.Text = Replace(tbl.Rows(0).Item("Response"), "~", "'")
                    Dim sUser As String = getContactTypeAbbr(tbl.Rows(0).Item("ContactType"))
                    responseAttachNum.Text = db.countChangeOrderAttachments(nCOID, "Response", sUser, 0, Session("SeqNum"))
                    updateResponseAttachment(Session("SeqNum"), nCOID, False, cboRevisions.SelectedValue)
                    If tbl.Rows(0).Item("ResponseBy") = nContactID Or Trim(tbl.Rows(0).Item("SaveStatus")) = "Released" Then
                        lblResponse.Visible = True
                        cboResponses.Visible = False
                        roResponse.Visible = True
                        lblResponseAttachments.Visible = True
                        responseAttachNum.Visible = True
                        butResponseAttach.Visible = True
                    Else
                        roResponse.Visible = False
                        cboResponses.Visible = False
                        butResponseAttach.Visible = False
                        responseAttachNum.Visible = False
                        lblResponseAttachments.Visible = False
                        lblResponse.Visible = False
                        roCurrentResponse.Visible = False
                    End If
                Else
                    roResponse.Visible = False
                    cboResponses.Visible = False
                    butResponseAttach.Visible = False
                    responseAttachNum.Visible = False
                    lblResponseAttachments.Visible = False
                    lblResponse.Visible = False
                    roCurrentResponse.Visible = False
                End If
            End If
        End Using
    End Sub
 
    Private Function getContactTypeAbbr(contactType As String) As String
        Dim sUser As String
        Select Case contactType
            Case "Construction Manager"
                sUser = "CM"
            Case "ProjectManager"
                sUser = "PM"
            Case "Design Professional"
                sUser = "DP"
            Case "General Contractor"
                sUser = "GC"
            Case Else
                sUser = "NA"
        End Select
        Return sUser
    End Function
    
    Private Sub cboResponses_Change() Handles cboResponses.SelectedIndexChanged
        Dim seq As Integer
        Using db As New ChangeOrders
            Try
                Dim response As String = db.getSingleResponse(cboResponses.SelectedValue)
                roResponse.Text = Replace(response, "~", "'")
            Catch ex As Exception
            End Try
            Try
                Dim tbl As DataTable = db.getResponseContactType(cboResponses.SelectedValue)
                Dim sUser As String = getContactTypeAbbr(tbl.Rows(0).Item("ContactType"))
                Session("SeqNum") = db.getResponseSeqNum(cboResponses.SelectedValue)
                'updateResponseAttachment(cboResponses.SelectedValue, nCOID, False, cboRevisions.SelectedValue)
                seq = db.getResponseSeqNum(cboResponses.SelectedValue)
                responseAttachNum.Text = db.countChangeOrderAttachments(nCOID, "Response", sUser, cboRevisions.SelectedValue, seq)
            Catch ex As Exception
            End Try
            updateResponseAttachment(Session("SeqNum"), nCOID, False, cboRevisions.SelectedValue)
        End Using
    End Sub
    
    Private Function checkPreviousCOAmounts(COID As Integer, ContractID As Integer, previousCOs As Double) As Boolean
        Dim redo As Boolean
        Using db As New ChangeOrders
            Dim netChange As Double = db.getTotalChangeOrders(ContractID)
            If netChange <> previousCOs Then
                db.updatePreviousChangeOrderAmount(COID, netChange)
                redo = True
            Else
                redo = False
            End If
        End Using
        Return redo
    End Function
       
    Private Sub configPCODropdown()
        Dim itemType As String = ""
        If sCoType = "COR" Then
            itemType = "PCO"
        ElseIf sCoType = "CO" Then
            itemType = "COR"
        End If
        Using db As New ChangeOrders
            Dim rev As Integer
          
            If IsNumeric(Session("TempRev")) Then
                rev = Session("TempRev")
            Else
                rev = cboRevisions.SelectedValue
            End If
            
            Dim pcoTbl As DataTable
            If cboActionSelect.SelectedValue = "CMCreateCORRevision" Then
                Dim cntTable As DataTable = db.getCORevisions(nCOID)
                Dim count As Integer = cntTable.Rows.Count
                If count = 0 Then
                    count = 1
                End If
                pcoTbl = db.getCOSelect(Session("DistrictID"), cboContractID.SelectedValue, itemType, count)
                'rev = count                
            Else
                pcoTbl = db.getCOSelect(Session("DistrictID"), cboContractID.SelectedValue, itemType, rev)
            End If
           
            Dim tbl As New DataTable
            Dim tblCheck As New DataTable
            Dim switch As String
            tbl.Columns.Add("COID", GetType(System.Int32))
            tbl.Columns.Add("CONumber", GetType(System.String))
            
            If Not IsPostBack Then
                switch = "Select"
            Else
                switch = cboPCOSelectSwitch.SelectedValue
            End If
            
            For Each row As DataRow In pcoTbl.Rows
                tblCheck = db.checkSelectedItem(nCOID, row.Item("COID"), rev, itemType)
                If tblCheck.Rows.Count > 0 Then
                    If switch = "Select" Then
                        If tblCheck.Rows(0).Item("IsActive") = 0 Or tblCheck.Rows(0).Item("CreateBy") <> nContactID Then
                            tbl.Rows.Add(row.Item("COID"), row.Item("CONumber"))
                        End If
                    ElseIf switch = "Un-Select" Then
                        If tblCheck.Rows(0).Item("IsActive") = 1 AND tblCheck.Rows(0).Item("CreateBy") = nContactID Then
                            tbl.Rows.Add(row.Item("COID"), row.Item("CONumber"))
                        End If
                    End If
                Else
                    If switch = "Select" Then
                        tbl.Rows.Add(row.Item("COID"), row.Item("CONumber"))
                    End If
                End If
            Next
            Dim sRow As DataRow = tbl.NewRow
            sRow("COID") = 0
            sRow("CONumber") = "Not Applicable"
            tbl.Rows.InsertAt(sRow, 0)
            With cboPCOSelect
                .DataValueField = "COID"
                .DataTextField = "CONumber"
                .DataSource = tbl
                .DataBind()
            End With
        End Using
    End Sub
    
    Private Sub getData()
        getRevisions()
        Dim tbl As DataTable = Nothing
        Using db As New ChangeOrders
            tbl = db.getCOIDdata(nCOID)
            Dim redo As Boolean
            Try
                redo = checkPreviousCOAmounts(nCOID, tbl.Rows(0).Item("ContractID"), tbl.Rows(0).Item("previousCOSum"))
            Catch ex As Exception
                redo = True
            End Try
            If redo = True Then
                tbl = db.getCOIDdata(nCOID)
            End If
        End Using
       
        Using db As New ChangeOrders
            roContractID.Text = db.getCompanyName(tbl.Rows(0).Item("ContractID"))
        End Using
        cboContractID.SelectedValue = tbl.Rows(0).Item("ContractID")
        Session("ContractID") = tbl.Rows(0).Item("ContractID")
        
        roCreateDate.Text = tbl.Rows(0).Item("CreateDate")
        If activeRevision.Value = 0 Then
            roRequiredBy.Text = tbl.Rows(0).Item("RequiredBy")
            Try
                txtRequiredBy.DbSelectedDate = tbl.Rows(0).Item("RequiredBy")
            Catch ex As Exception
            End Try
        End If
        If tbl.Rows(0).Item("RFIReference") = 0 Then
            'roRFIReference.Text = "Not Applicable"
        Else
            Using db As New ChangeOrders
                Dim refNum As String = db.getRefNumber(tbl.Rows(0).Item("RFIReference"))
            End Using
        End If
       
        txtSubject.Text = Replace(tbl.Rows(0).Item("Subject"), "~", "'")
        roSubject.Text = Replace(tbl.Rows(0).Item("Subject"), "~", "'")
        lblChangeOrderID.Text = ""
        Try
            txtRequiredBy.SelectedDate = tbl.Rows(0).Item("RequiredBy")
        Catch ex As Exception
        End Try
        Try
            txtFinanceVerified.DbSelectedDate = tbl.Rows(0).Item("FinanceVerified")
            roFinanceVerified.Text = tbl.Rows(0).Item("FinanceVerified")
        Catch ex As Exception
        End Try
        Try
            txtBoardApproved.SelectedDate = tbl.Rows(0).Item("BoardApproved")
            roBoardApproved.Text = tbl.Rows(0).Item("BoardApproved")
        Catch ex As Exception
        End Try
        
        'Dim daysProc As Integer = Now.Subtract(tbl.Rows(0).Item("CreateDate")).Days
        Dim daysProc As String = ""
        If Trim(tbl.Rows(0).Item("WorkFlowPosition")) = "COR Complete" Then
            daysProc = tbl.Rows(0).Item("DaysInProcess")
        Else
            daysProc = (DateDiff("d", tbl.Rows(0).Item("CreateDate"), Today)) + 1
        End If
        
        roDaysInProcess.Text = daysProc
        
        txtIssue.Text = Replace(tbl.Rows(0).Item("Issue"), "~", "'")
        roIssue.Text = Replace(tbl.Rows(0).Item("Issue"), "~", "'")
        hDecision.Value = tbl.Rows(0).Item("Decision")
        hEscalate.Value = tbl.Rows(0).Item("Escalate")
        txtAltReference.Text = Trim(tbl.Rows(0).Item("AltRefNumber"))
        
        'If Session("UpdateData") <> True Then
        txtRequestedCOAmount.Text = FormatNumber(tbl.Rows(0).Item("RequestedCOIncrease"), 2, TriState.True, TriState.False)
        roRequestedCOAmount.Text = FormatCurrency(tbl.Rows(0).Item("RequestedCOIncrease"))
        hRequestedCOAmount.Value = tbl.Rows(0).Item("RequestedCOIncrease")
        Session("UpdateData") = Nothing
        'End If
        If Session("Redirect") = True Then
            txtRequestedCOAmount.Text = FormatNumber(tbl.Rows(0).Item("RequestedCOIncrease"), 2, TriState.True, TriState.False)
            roRequestedCOAmount.Text = FormatCurrency(tbl.Rows(0).Item("RequestedCOIncrease"))
            hRequestedCOAmount.Value = tbl.Rows(0).Item("RequestedCOIncrease")
            Session("Redirect") = Nothing
        End If
        Try
            'roContractAmount.Text = FormatCurrency(tbl.Rows(0).Item("OriginalContractSum"))
        Catch ex As Exception
        End Try
          
        Dim origDate As String = ""
        Try
            Using db As New ChangeOrders
                origDate = db.getOriginalCompletionDate(cboContractID.SelectedValue)
              
                'roCompletionDate.Text = "Unknown"
            End Using
        Catch ex As Exception
           
        End Try
        
        Try
            Dim dDate As Date = DateTime.Parse(origDate)
            dDate = DateAdd(DateInterval.Day, tbl.Rows(0).Item("ContractDaysChange"), dDate)
           
        Catch ex As Exception
        End Try
                    
        Try
            COStatus = tbl.Rows(0).Item("Status")
        Catch ex As Exception
        End Try
         
        Dim strTitle As String = setTitleName()
        
        If cboActionSelect.SelectedValue = "None" Then
            sTitle = "Review " & strTitle & ": # "
        Else
            sTitle = "Edit " & strTitle & ": # "
        End If
        
        Dim lgt As Integer = Len(tbl.Rows(0).Item("CONumber"))
        Dim loc As Integer = InStr(5, tbl.Rows(0).Item("CONumber"), "-",0)

        Dim coNum As String = Right(tbl.Rows(0).Item("CONumber"), 3)
        Session("sTitleDetail") = coNum & "&nbsp;&nbsp;&nbsp;   : " & tbl.Rows(0).Item("WorkFlowPosition") & " - " & tbl.Rows(0).Item("Status")
        sTitle &= Session("sTitleDetail")
        Try
            configInitiatedBy()
        Catch ex As Exception
        End Try
        
        roInitiatedBy.Text = tbl.Rows(0).Item("Name")
        cboInitiatedBy.SelectedValue = tbl.Rows(0).Item("InitiatedBy")
        
        If tbl.Rows(0).Item("InitiatedBy") = nContactID Then
            isInitiator.Value = True
        Else
            isInitiator.Value = False
        End If
        
        SaveStatus.Value = tbl.Rows(0).Item("SaveStatus")
        refreshRFIDropdown(tbl.Rows(0).Item("ContractID"))
        Try
            cboDPSelect.SelectedValue = tbl.Rows(0).Item("DPSelect")
        Catch ex As Exception
        End Try
        Try
            Using db As New RFI
                roDPSelect.Text = db.getResponderName(tbl.Rows(0).Item("DPSelect"))
            End Using
        Catch ex As Exception
        End Try
        Try
            Using db As New RFI
                roRFIDetail.Text = db.buildRFIQAndA(tbl.Rows(0).Item("RFIReference"), Session("ContactType"))
            End Using
        Catch ex As Exception
        End Try
        WorkFlowPosition.Value = tbl.Rows(0).Item("WorkFlowPosition")
        Using db As New RFI
            Dim name As String = db.getResponderName(nContactID)
            ProgrammerData.Text = name & " - " & nContactID & " COID: " & nCOID & " ProjID: " & nProjectID
        End Using
        If Not IsPostBack Then
            Try
                configPCODropdown()
            Catch ex As Exception
            End Try
        End If
        Try
            updateSelectedItems(cboRevisions.SelectedValue)
        Catch ex As Exception
        End Try
        configContractItems()
    End Sub
    
    Private Function setTitleName() As String
        Dim title As String
        Select Case sCoType
            Case "PCO"
                title = "Potential Change Order"
            Case "COR"
                title = "Change Order Request"
            Case "CO"
                title = "Change Order"
            Case Else
                title = "Boluxed up"
        End Select
        Return title
    End Function
    
    Private Sub cboRFISelectSwitch_Change() Handles cboRFISelectSwitch.SelectedIndexChanged
        refreshRFIDropdown(Session("ContractID"))
        txtResponse.Text = sResponse.Value
        txtIssue.Text = sIssue.Value
        txtRequiredBy.DbSelectedDate = dRequiredBy.Value
    End Sub
    
    Private Sub refreshRFIDropdown(ContractID As Integer)
        If ContractID <> 0 Then
            Using db As New ChangeOrders
                Dim tblRfi As DataTable = db.getContractRFIs(ContractID)
                Dim tbl As New DataTable
                Dim tblCheck As New DataTable
                
                Dim rev As Integer
                Try
                    'If Session("TempRev") <> Nothing Then rev = Session("TempRev") Else rev = cboRevisions.SelectedValue
                    rev = cboRevisions.SelectedValue
                Catch ex As Exception
                    rev = activeRevision.Value
                End Try
               
                Dim switch As String
                tbl.Columns.Add("RFIID", GetType(System.Int32))
                tbl.Columns.Add("RefNumber", GetType(System.String))
            
                If Not IsPostBack Then
                    switch = "Select"
                Else
                    switch = cboRFISelectSwitch.SelectedValue
                End If
                
                For Each row As DataRow In tblRfi.Rows
                    tblCheck = db.checkSelectedItem(nCOID, row.Item("RFIID"), rev, "RFI")
                    If tblCheck.Rows.Count > 0 Then
                        If switch = "Select" Then
                            If tblCheck.Rows(0).Item("IsActive") = 0 Then
                                tbl.Rows.Add(row.Item("RFIID"), row.Item("RefNumber"))
                            End If
                        ElseIf switch = "Un-Select" Then
                            If tblCheck.Rows(0).Item("IsActive") = 1 Then
                                tbl.Rows.Add(row.Item("RFIID"), row.Item("RefNumber"))
                            End If
                        End If
                    Else
                        If switch = "Select" Then
                            tbl.Rows.Add(row.Item("RFIID"), row.Item("RefNumber"))
                        End If
                    End If
                Next
                Dim rfiRow As DataRow = tbl.NewRow
                rfiRow("RFIID") = 0
                rfiRow("RefNumber") = "Not Applicable"
                tbl.Rows.InsertAt(rfiRow, 0)
                cboRFIReference.Items.Clear()
                With cboRFIReference
                    .DataValueField = "RFIID"
                    .DataTextField = "RefNumber"
                    .DataSource = tbl
                    Try
                        .DataBind()
                    Catch ex As Exception
                    End Try
                End With
                roRFIItems.Text = db.buildItemsList(nCOID, rev, "RFI", nContactID)
            End Using
        End If
    End Sub
    
    Private Sub configNoSelection()
        If sDisplayType = "New" Then
            Select Case sCoType
                Case "PCO"
                    sTitle = "New Potential Change Order - Contract # " & cboContractID.SelectedValue
                Case "COR"
                    sTitle = "New Change Order Request - Contract # " & cboContractID.SelectedValue
                Case "CO"
                    sTitle = "New Change Order - Contract # " & cboContractID.SelectedValue
                Case Else
                    sTitle = "New Potential Change Order - Contract # " & cboContractID.SelectedValue
            End Select
        End If
        lblCreateDate.Visible = False
        cboContractID.Visible = True
        roContractID.Visible = False
        roCreateDate.Visible = False
        lblChangeOrderID.Visible = False
        txtRequiredBy.Visible = False
        lblRequiredBy.Visible = False
        lblRequiredBy.Visible = False
        lblInitiatedBy.Visible = False
        roInitiatedBy.Visible = False
        lblRFIReference.Visible = False
        'roRFIReference.Visible = False
        cboRFIReference.Visible = False
        lblSubject.Visible = False
        roSubject.Visible = False
        txtSubject.Visible = False
        butSave.Visible = False
        butSend.Visible = False
        butCancel.Visible = True
        lblActionSelect.Visible = False
        cboActionSelect.Visible = False
        lblDPSelect.Visible = False
        cboDPSelect.Visible = False
        lblResponseAttachments.Visible = False
        responseAttachNum.Visible = False
        butResponseAttach.Visible = False
        lblContractAmount.Visible = False
        roContractAmount.Visible = False
        butLeftPanelSelect.Visible = False
        ContractDetailPanel_A.Visible = False
        ContractDetailPanel_B.Visible = False
        showRFI.Visible = False
        lblIssue.Visible = False
        txtIssue.Visible = False
        roIssue.Visible = False
        lblHistory.Visible = False
        roRFIDetail.Visible = False
        lblIssueAttach.Visible = False
        issueAttachNum.Visible = False
        butIssueAttach.Visible = False
        cboInitiatedBy.Visible = False
        cboRevisions.Visible = False
        lblRevisions.Visible = False
        lblDaysInProcess.Visible = False
        lblAltReference.Visible = False
        txtAltReference.Visible = False
    End Sub
    
    Private Sub configNew()
        'David D 6/9/17 below control disables validation on the txtResponse for new CO's
        TextBoxRequiredValidatorResponse.Enabled = False
        lblDaysInProcess.Visible = False
        lblCreateDate.Visible = True
        roCreateDate.Visible = True
        roCreateDate.Text = Now().ToString("d")
        lblContractID.Visible = True
        txtRequiredBy.Visible = False
        lblRequiredBy.Visible = False
        lblInitiatedBy.Visible = True
        roInitiatedBy.Visible = True
        roInitiatedBy.Text = sContactName
        lblRFIReference.Visible = True
        cboRFIReference.Visible = True
        If cboRFIReference.SelectedValue <> 0 Then
            'showRFI.Visible = True
        Else
            showRFI.Visible = False
        End If
        lblSubject.Visible = True
        roSubject.Visible = False
        txtSubject.Visible = True
        lblHistory.Visible = False
        roRFIDetail.Visible = False
        
        butSave.Visible = True
        butSend.Visible = False
        saveButton.Value = "New"
        lblActionSelect.Visible = False
        cboActionSelect.Visible = False
        lblAltReference.Visible = False
        txtAltReference.Visible = False
        
        lblContractAmount.Visible = True
        roContractAmount.Visible = True
                                    
        lblIssue.Visible = True
        txtIssue.Visible = True
        butIssueAttach.Visible = False
        issueAttachNum.Visible = False
        lblIssueAttach.Visible = False
        butLeftPanelSelect.Visible = False
        If sCoType = "COR" Then
            CORequestAmountDateChange.Visible = True
        Else
            CORequestAmountDateChange.Visible = False
        End If
        txtRequestedCOAmount.Visible = False
        lblRequestedCOAmount.Visible = False
        butSave.ImageUrl = "images/button_create.gif"
        responseMsg.Visible = False
        
    End Sub
 
    Private Sub configRightBox() 'Congigurs the upper right issue box
        Select Case sCoType
            Case "PCO", "COR", "CO"
                lblIssue.Visible = True
                issueAttachNum.Visible = True
                butIssueAttach.Visible = True
                If cboActionSelect.SelectedValue = "None" Then
                    lblIssue.Visible = True
                    txtIssue.Visible = False
                    roIssue.Visible = True
                    butIssueAttach.ImageUrl = "images/button_view.png"
                    updateIssueAttachment(0, nCOID, False, cboRevisions.SelectedValue)
                ElseIf cboActionSelect.SelectedValue = "Edit" Then
                    lblIssue.Visible = True
                    txtIssue.Visible = True
                    roIssue.Visible = False
                    butIssueAttach.ImageUrl = "images/button_upload_view.png"
                    updateIssueAttachment(0, nCOID, True, cboRevisions.SelectedValue)
                End If
                Try
                    If cboRFIReference.SelectedValue <> 0 Then
                        'showRFI.Visible = True
                    End If
                Catch ex As Exception
                End Try
        End Select
    End Sub
    
    Private Sub getRevisions()
        Using db As New ChangeOrders
            Dim tbl As DataTable = db.getChangeOrderRevisions(nCOID)
            Dim tbl2 As DataTable = db.getCORevisions(nCOID)
            If tbl2.Rows.Count > 0 Then
                If tbl2.Rows.Count = 1 Then
                    If Trim(tbl2.Rows(0).Item("SaveStatus")) = "Preparing" Then
                        revisionExists.Value = "True"
                    Else
                        revisionExists.Value = "True"
                    End If
                End If
            Else
                revisionExists.Value = "False"
            End If
            If tbl2.Rows.Count > 0 Then
                If tbl2.Rows(0).Item("SaveStatus") = "Preparing" Then
                    'If tbl2.Rows(0).Item("CreatedBy") = nContactID Or Session("ContactType") = "ProjectManager" Then
                    If tbl2.Rows(0).Item("CreatedBy") = nContactID Or tbl2.Rows.Count > 1 Then
                        showRevisions.Value = True
                        lblRevisions.Visible = True
                    Else
                        showRevisions.Value = False
                        lblRevisions.Visible = False
                    End If
                Else
                    showRevisions.Value = True
                    cboRevisions.Visible = True
                    lblRevisions.Visible = True
                End If
                
                roRequiredBy.Text = tbl2.Rows(0).Item("RequiredBy")
                Try
                    txtRequiredBy.DbSelectedDate = tbl2.Rows(0).Item("RequiredBy")
                Catch ex As Exception
                End Try
                
                If tbl2.Rows.Count = 1 And Trim(tbl2.Rows(0).Item("SaveStatus")) = "Preparing" Then
                    activeRevision.Value = 0
                Else
                    If tbl2.Rows.Count > 1 Then
                        If Trim(tbl2.Rows(tbl2.Rows.Count - 1).Item("SaveStatus")) = "Preparing" Then
                            activeRevision.Value = tbl2.Rows.Count - 1
                        Else
                            activeRevision.Value = tbl2.Rows.Count
                        End If
                    Else
                        activeRevision.Value = 1
                    End If
                End If
                
                Dim revTbl As DataTable
                revTbl = New DataTable("revTbl")
                revTbl.Columns.Add("Revision", GetType(System.String))
                'revTbl.Columns.Add("RevisionText", GetType(System.String))
                revTbl.Rows.Add("0")
                Dim name As String
                For Each row As DataRow In tbl2.Rows
                    If row.Item("SaveStatus") = "Preparing" Then
                        If row.Item("CreatedBy") = nContactID 'Or Session("ContactType") = "ProjectManager" Then
                            revTbl.Rows.Add(row.Item("Revision"))
                        End If
                        name = getName(row.Item("CreatedBy"))
                    Else
                        revTbl.Rows.Add(row.Item("Revision"))
                    End If
                Next
                If Not IsPostBack Or sSaveType.Value = "Insert" Then
                    Dim newrow As DataRow = tbl2.NewRow
                    newrow("Revision") = 0
                    tbl2.Rows.InsertAt(newrow, 0)   'put it first                 
                    With cboRevisions
                        .DataValueField = "Revision"
                        .DataTextField = "Revision"
                        .DataSource = revTbl
                        .DataBind()
                    End With
                    If Session("ContactType") = "General Contractor" Or Session("ContactType") = "Construction Manager" Then
                        cboRevisions.SelectedValue = tbl2.Rows.Count - 1
                    End If
                    roRevisions.Text = tbl2.Rows.Count - 1
                    cboRevisions_Change()
                End If
                If Session("ContactType") = "ProjectManager" Then
                    If tbl2.Rows.Count > activeRevision.Value Then
                        If tbl2.Rows(tbl2.Rows.Count - 1).Item("CreatedBy") <> nContactID Then
                            lblRevisionMsg.Text = "A revision is being prepared by " & name & ". Overriding will cancel the revision being prepared."
                            lblDPSelect.Visible = False
                            roDPSelect.Visible = False
                        Else
                            lblDPSelect.Visible = True
                        End If
                        If cboActionSelect.SelectedValue <> "None" Then
                            lblRevisionMsg.Visible = True
                        Else
                            lblRevisionMsg.Visible = False
                        End If
                    Else
                        lblRevisionMsg.Visible = False
                    End If
                ElseIf Session("ContactType") = "Construction Manager" Then
                    If tbl2.Rows(tbl2.Rows.Count - 1).Item("CreatedBy") <> nContactID Then
                        lblRevisionMsg.Text = "A revision is being prepared by " & name & ". Distribution of this COR is not possible at this time."
                        lblDPSelect.Visible = False
                        roDPSelect.Visible = False
                    End If
                End If
            Else
                activeRevision.Value = 0
                cboRevisions.Visible = False
                lblRevisions.Visible = False
                showRevisions.Value = False
            End If
        End Using
    End Sub
    
    Private Function getName(contactID As Integer) As String
        Dim name As String = ""
        Using db As New RFI
            Dim obj(5) As Object
            obj = db.getContactData(contactID, Session("DistrictID"))
            Return obj(2)
        End Using
    End Function
    
    Private Function createCoNumber(newCOType As String) As String

        If cboContractID.SelectedValue <> 0 Then
            Using db As New ChangeOrders
                Dim tbl As DataTable = db.countAllContractCOs(cboContractID.SelectedValue, newCOType)
                Dim len As Integer = tbl.Rows.Count + 1
                Dim rTag As String = "00"
            
                If len > 99 Then
                    rTag = "" & len
                ElseIf len > 9 Then
                    rTag = "0" & len
                    'ElseIf len > 99 Then
                    'rTag = len
                ElseIf len < 10 Then
                    rTag = "00" & len
                End If
                    
                Dim sRefNum As String = newCOType & "-" & cboContractID.SelectedValue & "-" & rTag
                Dim coNum As String = sRefNum
                Return coNum
            End Using
        Else
            Return ""
        End If
    End Function
    
    Private Sub Contract_change() Handles cboContractID.SelectedIndexChanged
        If sDisplayType = "New" Then
            Select Case sCoType
                Case "PCO"
                    sTitle = "New Potential Change Order - Contract # " & cboContractID.SelectedValue
                Case "COR"
                    sTitle = "New Change Order Request - Contract # " & cboContractID.SelectedValue
                Case "CO"
                    sTitle = "New Change Order - Contract # " & cboContractID.SelectedValue
                Case Else
                    sTitle = "New Potential Change Order - Contract # " & cboContractID.SelectedValue
            End Select
        End If
        
        If cboContractID.SelectedValue <> 0 Then
            refreshRFIDropdown(cboContractID.SelectedValue)
        End If
        
        If cboContractID.SelectedValue <> 0 Then
            configNew()
            configInitiatedBy()
        Else
            configNoSelection()
        End If
        configContractItems()
    End Sub
    
    Private Sub configInitiatedBy()
        If Session("ContactType") = "Construction Manager" Or Session("ContactType") = "ProjectManager" Then
            If sCoType = "PCO" Then
                roInitiatedBy.Visible = False
                cboInitiatedBy.Visible = True
            End If
        End If
        Using db As New ChangeOrders
            With cboInitiatedBy
                .DataValueField = "ContactID"
                .DataTextField = "Name"
                .DataSource = db.getContractTeamMembers(cboContractID.SelectedValue, nProjectID)
                Try
                    .DataBind()
                Catch ex As Exception
                End Try
            End With
        End Using
    End Sub
    
    Private Sub rfiReference_change() Handles cboRFIReference.SelectedIndexChanged
        txtResponse.Text = sResponse.Value
        txtIssue.Text = sIssue.Value
        txtRequiredBy.DbSelectedDate = dRequiredBy.Value
        itemSelectPanel.Visible = False
        If cboActionSelect.SelectedValue = "Edit" Or cboActionSelect.SelectedValue = "CreateRevision" Then
            showRfiSelectPanel()
        End If
       
        If cboRFIReference.SelectedValue <> 0 Then
            butSelectRFI.Visible = True
            showRFI.Visible = True
            roRFIDetail.Visible = True
            lblIssue.Text = cboRFIReference.Text & " History"
            Try
                Using db As New RFI
                    roRFIDetail.Text = db.buildRFIQAndA(cboRFIReference.SelectedValue, Session("ContactType"))
                End Using
            Catch ex As Exception
            End Try
        Else
            showRFI.Visible = False
            butSelectRFI.Visible = False
            roRFIDetail.Visible = False
        End If
    End Sub
    
    Private Sub configActionDropdown()
        Dim reBind As Boolean = False
        Dim tbl As DataTable
        tbl = New DataTable("tbl")
        tbl.Columns.Add("Action", GetType(System.String))
        tbl.Columns.Add("ActionText", GetType(System.String))
        tbl.Rows.Add("None", "Review: Action Select")
       
        Select Case Session("ContactType")
            Case "General Contractor", "Contractor"
                Select Case Trim(WorkFlowPosition.Value)
                    Case "None"
                        tbl.Rows.Add("Edit", "Edit/Send To CM")
                    Case "GC:Receipt Pending"
                        Select Case Session("CoType")
                            Case "PCO"
                                If Trim(activeRevision.Value) = (cboRevisions.SelectedValue).ToString() Then
                                    Dim coCheck As Boolean = checkForExistingRevision("non-owner")
                                    tbl.Rows.Add("GCAcceptCMResponse", "Accept CM Response")
                                    If coCheck <> True Then
                                        tbl.Rows.Add("CreateRevision", "Revise and Send To CM")
                                    End If
                                    If revChange.Value = "True" Then
                                        reBind = True
                                        revChange.Value = Nothing
                                    End If
                                Else
                                    tbl.Rows.Add("CreateRevision", "Revise and Send To CM")
                                    If revChange.Value = "True" Then
                                        reBind = True
                                        revChange.Value = Nothing
                                    End If
                                End If
                            Case "COR"
                                tbl.Rows.Add("GCAcceptCORApproval", "Acknowledge COR Approval")
                            Case "CO"
                                tbl.Rows.Add("GCSendReceipt", "Confirm CO Received")
                        End Select
                    Case Else
                        cboActionSelect.Visible = False
                End Select
            Case "Construction Manager", "ProjectManager"
                Select Case Trim(WorkFlowPosition.Value)
                    Case "None"
                        If sCoType = "PCO" Then
                            tbl.Rows.Add("Edit", "Edit/Activate PCO For GC")
                        ElseIf sCoType = "COR" Then
                            tbl.Rows.Add("Edit", "Edit/Send To PM/DP")
                        ElseIf sCoType = "CO" Then
                            tbl.Rows.Add("Edit", "Edit/Send To PM")
                        End If
                    Case "CM:Review Pending"
                        Select Case Session("COType")
                            Case "PCO"
                                tbl.Rows.Add("Edit", "Edit/Respond To GC")
                                tbl.Rows.Add("EditCORRequired", "Edit/COR Required")
                            Case "CO"
                                tbl.Rows.Add("Edit", "Edit/Send To PM")
                                tbl.Rows.Add("CMReturnToGC", "Return to GC")
                        End Select
                    Case "PM:Approval Pending"
                        Select Case Session("COType")
                            Case "COR"
                                tbl.Rows.Add("PMApproveAllowance", "Approve - Allowance")
                                tbl.Rows.Add("PMApproveChangeOrder", "Approve - Change Order")
                                tbl.Rows.Add("PMRejectCOR", "COR Declined")
                            Case "CO"
                                Select Case COStatus
                                    Case "Active"
                                        tbl.Rows.Add("PrepBOD", "Prepare/Release To BOD")
                                    Case "At BOD"
                                        tbl.Rows.Add("PrepApproval", "Mark As Approved")
                                End Select
                                tbl.Rows.Add("RejectCO", "CO Not Approved")
                        End Select
                    Case "CM:Distribution Pending"
                        Select Case Session("COtype")
                            Case "PCO"
                                tbl.Rows.Add("CMReleaseGC", "Release To GC")
                            Case "COR"
                                'David D 6/19/17 This is needed for validation summary during a COR revision
                                If roPCODisplay.Visible = True Then
                                    TextBoxRequiredValidatorResponse.Enabled = False
                                    TextBoxRequiredValidatorSummary.Enabled = False
                                    TextBoxRequiredValidatorSummaryCO.Enabled = True
                                End If
                                
                                Using db As New ChangeOrders
                                    Dim dataTbl As DataTable
                                    If cboRevisions.SelectedValue = 0 Then
                                        dataTbl = db.getCOIDdata(nCOID)
                                    Else
                                        dataTbl = db.getRevisionData(nCOID, cboRevisions.SelectedValue)
                                    End If
                                    Dim decision As String = dataTbl.Rows(0).Item("Decision")
                                    If Trim(activeRevision.Value) = (cboRevisions.SelectedValue).ToString() Then
                                        Dim coCheck As Boolean = checkForExistingRevision("non-owner")
                                        If Trim(decision) = "Approved-Allowance" Or Trim(decision) = "Approved-Change Order" Then
                                            tbl.Rows.Add("CMReleaseCORGC", "Release To GC-Approved")
                                            'tbl.Rows.Add("CMMoveToCONotifyGC", "Move To CO-Notify GC")
                                            'testPlace.Value = "#1"
                                        ElseIf Trim(decision) = "Not Approved" Then
                                            tbl.Rows.Add("CMReleaseCORGC", "Release To GC")
                                            If coCheck <> True Then
                                                tbl.Rows.Add("CMCreateCORRevision", "Create COR Revision")
                                            End If
                                            'testPlace.Value = "#2"
                                        Else
                                            tbl.Rows.Add("CMCreateCORRevision", "Edit COR Revision")
                                            'estPlace.Value = "#3"
                                        End If
                                        If revChange.Value = "True" Then
                                            reBind = True
                                            revChange.Value = Nothing
                                        End If
                                    Else
                                        tbl.Rows.Add("CMCreateCORRevision", "Edit COR Revision")
                                        'testPlace.Value = "#4"
                                        If revChange.Value = "True" Then
                                            reBind = True
                                            revChange.Value = Nothing
                                        End If
                                    End If
                                End Using
                            Case "CO"
                                tbl.Rows.Add("CMCreateCORRevision", "Create COR Revision")
                            Case Else
                        End Select
                    Case "CM:Completion Pending", "PM:Completion Pending"
                        Select Case Session("CoType")
                            Case "PCO"
                                tbl.Rows.Add("CMClosePCO", "Close PCO")
                            Case "COR"
                                tbl.Rows.Add("PMCloseCOR", "Close COR")
                            Case "CO"
                                tbl.Rows.Add("CMCloseCO", "Close Change Order")
                        End Select
                    Case "PM:Review Pending", "DP:Review Pending", "PM:Review DP Response"
                        If Session("ContactType") = "ProjectManager" Then
                            tbl.Rows.Add("PMToApprovalPending", "Move To Approval Pending")
                            If Trim(WorkFlowPosition.Value) = "PM:Review Pending" Then
                                tbl.Rows.Add("PMSendToDP", "Send To DP For Review")
                            End If
                            tbl.Rows.Add("PMSendBackToCM", "Return To CM")
                        End If
                    Case "CM:Response Pending"
                        tbl.Rows.Add("CMCreateRevision", "Edit/Submit Revision")
                    Case "GC:Receipt Pending"
                        If Session("ContactType") = "ProjectManager" Then
                            tbl.Rows.Add("PMOverrideGC", "Override GC Accept")
                        End If
                End Select
            Case "Design Professional"
                Select Case Session("COType")
                    Case "CO"
                        tbl.Rows.Add("Prepare", "Prepare/Send For Approval to PM")
                        tbl.Rows.Add("Reject", "Declined/Send Back to CM")
                    Case "COR"
                        tbl.Rows.Add("Prepare", "Prepare/Submit Response")
                End Select
            Case "Board of Directors"
        End Select
        
        If Not IsPostBack Or reBind = True Then
            If reBind = True Then reBind = False
            Try
                With cboActionSelect
                    .DataValueField = "Action"
                    .DataTextField = "ActionText"
                    .DataSource = tbl
                    .DataBind()
                End With
            Catch ex As Exception
            End Try
        End If
    End Sub
       
    Private Sub configNewRevision()
        Select Case sCoType
            Case "PCO", "COR", "CO"
                lblResponse.Visible = False
                txtResponse.Visible = False
                roResponse.Visible = False
                lblResponseAttachments.Visible = False
                responseAttachNum.Visible = False
                butResponseAttach.Visible = False
                roIssue.Visible = False
                roCurrentResponse.Visible = False
                butSave.Visible = True
                butSend.Visible = True
                cboActionSelect.OpenDropDownOnLoad = False
                roRequiredBy.Visible = False
                txtRequiredBy.Visible = True
                SelectedItemDetailPanel.Visible = False
                butLeftPanelSelect.Visible = True
                txtRequiredBy.Visible = False
                cboRevisions.Visible = False
                'David D added for textbox validation of txtIssue on a revision by the GC
                If txtIssue.Text <> String.Empty Or txtIssue.Text <> "" Then
                    TextBoxRequiredValidatorIssue.Enabled = False
                End If
                
                If Session("ContactType") = "General Contractor" Or Session("ContactType") = "Design Professional" Then
                    ContractDetailPanel_A.Visible = False
                    ContractDetailPanel_B.Visible = True
                Else
                    ContractDetailPanel_A.Visible = True
                    ContractDetailPanel_B.Visible = False
                End If
                If sCoType = "COR" Then
                    'roRequestedCOAmount.Visible = False
                    txtRequestedCOAmount.Visible = True
                    lblRequestedCOAmount.Visible = True
                    butLeftPanelSelect.ImageUrl = "images/button_rfis.png"
                    butLeftPanelSelect_Click()
                    butLeftPanelSelect.Visible = True
                    cboResponses.Visible = False
                End If
                Using db As New ChangeOrders
                    Dim tbl As DataTable = db.checkForRevision(nCOID, nContactID, Session("ContactType"), "owner")
                    Dim Rev As Integer
                    If tbl.Rows.Count = 0 Then
                        Rev = db.getRevisionNumber(nCOID) + 1
                        txtRequiredBy.SelectedDate = Today.AddDays(2)
                        If Session("UpdateDate") <> True Then
                            txtIssue.Text = ""
                        End If
                        txtRequestedCOAmount.Text = 0
                        roItemList.Text = ""
                        'duplicateSelectedItems(nCOID, Rev)
                    Else
                        If tbl.Rows(0).Item("CreatedBy") <> nContactID Then 'This can only happen if there is a revision being prepared and an override is being attempted.
                            Rev = db.getRevisionNumber(nCOID) 'Need to decide about how to number the Revisions in case of a 'Canceled' situation
                            cboActionSelect.Visible = True
                            getRevisions()
                            txtIssue.Text = ""
                            txtRequestedCOAmount.Text = 0
                        Else
                            Rev = tbl.Rows(0).Item("Revision")
                            Try
                                configRequiredByDate()
                                'txtRequiredBy.DbSelectedDate = tbl.Rows(0).Item("RequiredBy")
                            Catch ex As Exception
                            End Try
                            txtIssue.Text = Replace(tbl.Rows(0).Item("Issue"), "~", "'")
                            cboActionSelect.Visible = True
                            If sCoType = "COR" Then
                                txtRequestedCOAmount.Text = tbl.Rows(0).Item("RequestedCOincrease")
                                roRequestedCOAmount.Text = tbl.Rows(0).Item("RequestedCOIncrease")
                            End If
                            'roItemList.Text = ""
                        End If
                    End If
                    Session("TempRev") = Rev
                    If Session("ActionChange") = "True" Then
                        configPCODropdown()
                    End If
                                       
                    txtIssue.Visible = True
                    issueAttachNum.Text = db.countChangeOrderAttachments(nCOID, "Issue", "", Rev, Session("SeqNum"))
                    updateIssueAttachment(0, nCOID, True, Rev)
                    butIssueAttach.ImageUrl = "images/button_upload_view.png"
                    If sCoType = "PCO" Then
                        sTitle = "Potential Change Order Revision # " & Rev & " : " & Session("sTitleDetail")
                    ElseIf sCoType = "COR" Then
                        sTitle = "Change Order Request Revision - Revision # " & Rev & " : " & Session("sTitleDetail")
                    ElseIf sCoType = "CO" Then
                        sTitle = "Change Order Revision - Revision # " & Rev & " : " & Session("sTitleDetail")
                    End If
                End Using
                'updateSelectedItems(Session("TempRev"))
                cboRevisions.Visible = False
                lblRevisions.Visible = True
                itemSelectPanel.Visible = True
                'configPCODropdown()
                responseMsg.Visible = False
        End Select
    End Sub
    
    Private Sub duplicateSelectedItems(COID As Integer, Rev As Integer)
        Using db As New ChangeOrders
            Dim tblchk As DataTable = db.getLatestItems(COID, Rev)
            Dim obj(8) As Object
            If tblchk.Rows.Count = 0 Then
                Dim tbl As DataTable = db.getLatestItems(COID, Rev - 1)
                If tbl.Rows.Count > 0 Then
                    For Each row As DataRow In tbl.Rows
                        obj(0) = row.Item("ItemCOID")
                        obj(1) = "Insert"
                        obj(2) = row.Item("ParentCOID")
                        obj(3) = nContactID
                        obj(4) = 0
                        obj(5) = 1
                        obj(6) = Rev
                        obj(7) = sCoType
                        'roPCODisplay.Text = obj(0) & " - " & Rev                                 
                        db.saveSelectedItem(obj)
                    Next
                End If
            Else
                'roPCODisplay.Text = "Already there"
            End If
           
        End Using
    End Sub
    
    Private Function getFileImage(file As String) As String
        Dim FileIcon As String = ""
        If InStr(file, ".xls") > 0 Then
            FileIcon &= "prompt_xls.gif"
        ElseIf InStr(file, ".pdf") > 0 Then
            FileIcon &= "prompt_pdf.gif"
        ElseIf InStr(file, ".doc") > 0 Then
            FileIcon &= "prompt_doc.gif"
        ElseIf InStr(file, ".zip") > 0 Then
            FileIcon &= "prompt_zip.gif"
        Else
            FileIcon &= "prompt_page.gif"
        End If
        Return FileIcon
    End Function
    
    Private Sub cboRevisions_Change() Handles cboRevisions.SelectedIndexChanged
        revChange.Value = "True"
        configActionDropdown()
        
        If Session("ContactType") = "District" Then
            configReadOnly()
        End If
        If cboRevisions.SelectedValue < activeRevision.Value Then
            'configReadOnly()
            cboActionSelect.Visible = False
        End If
        cboActionSelect.SelectedValue = "None"
        Dim tbl As DataTable
        Dim getItem As String = ""
        If sCoType = "PCO" Then
            getItem = "RFI"
            configRequiredByDate()
        ElseIf sCoType = "COR" Then
            getItem = "PCO"
        End If
        getItem = "RFI"
        Using db As New ChangeOrders
            If cboRevisions.SelectedValue = 0 Then
                tbl = db.getCOIDdata(nCOID)
                'Title = "Edit Potential Change Order: Original PCO: " & Session("sTitleDetail")
            Else
                tbl = db.getRevisionData(nCOID, cboRevisions.SelectedValue)
                'sTitle = "Edit Potential Change Order: Revision # " & cboRevisions.SelectedValue & " - " & Session("sTitleDetail")
            End If
            roIssue.Text = Replace(tbl.Rows(0).Item("Issue"), "~", "'")
            issueAttachNum.Text = db.countChangeOrderAttachments(nCOID, "Issue", "", cboRevisions.SelectedValue, Session("SeqNum"))
            updateIssueAttachment("", nCOID, False, cboRevisions.SelectedValue)
            responseAttachNum.Text = db.countChangeOrderAttachments(nCOID, "Response", "", cboRevisions.SelectedValue, Session("SeqNum"))
            updateResponseAttachment(Session("SeqNum"), nCOID, False, cboRevisions.SelectedValue)
            If cboRevisions.SelectedValue = activeRevision.Value Then
                If tbl.Rows(0).Item("SaveStatus") = "Preparing" Then
                    cboResponses.Visible = False
                End If
            End If
            Try
                roRequestedCOAmount.Text = FormatCurrency(tbl.Rows(0).Item("RequestedCOIncrease"))
                txtRequestedCOAmount.Text = tbl.Rows(0).Item("RequestedCOIncrease")
            Catch ex As Exception
            End Try
        End Using
        If WorkFlowPosition.Value = "PM:Approval Pending" Then
            editReturn.Value = "True"
        End If
        If butLeftPanelSelect.ImageUrl = "images/button_contract.png" Then
            butLeftPanelSelect.ImageUrl = "images/button_rfis.png"
        Else
            butLeftPanelSelect.ImageUrl = "images/button_contract.png"
        End If
        butLeftPanelSelect_Click()
        If Session("ContactType") = "Design Professional" Then
            buildResponseDropdown("Released")
        Else
            If responseMsg.Visible <> True Then
                buildResponseDropdown("")
            End If
        End If
        updateIssueAttachment(0, nCOID, False, cboRevisions.SelectedValue)
        updateAttachCount()
       
    End Sub
    
    Private Sub cboPCOSelect_Change() Handles cboPCOSelect.SelectedIndexChanged
        If cboActionSelect.SelectedValue = "CMCreateCORRevision" Then
            txtRequestedCOAmount.Text = hRequestedCOAmount.Value
            roRequestedCOAmount.Text = hRequestedCOAmount.Value
            txtIssue.Text = sIssue.Value
        End If
        If cboPCOSelect.SelectedValue <> 0 Then
            butSelectItem.Visible = True
            If cboPCOSelectSwitch.SelectedValue = "Select" Then
                butSelectItem.ImageUrl = "images/button_select.png"
            ElseIf cboPCOSelectSwitch.SelectedValue = "Un-Select" Then
                'butSelectItem.ImageUrl = "images/button_unselect.png"
                butSelectItem.ImageUrl = "images/button_select.png"
            End If
            Using db As New ChangeOrders
                roPCODisplay.Text = db.buildPCOReadout(cboPCOSelect.SelectedValue, nContactID)
            End Using
            ContractDetailPanel_A.Visible = False
            ContractDetailPanel_B.Visible = False
            roItemsDisplay.Visible = True
        Else
            butSelectItem.Visible = False
            roPCODisplay.Text = ""
        End If
    End Sub
    
    Private Sub cboPCOSelectSwitch_Change() Handles cboPCOSelectSwitch.SelectedIndexChanged
        If cboActionSelect.SelectedValue = "CMCreateCORRevision" Then
            txtRequestedCOAmount.Text = hRequestedCOAmount.Value
            roRequestedCOAmount.Text = hRequestedCOAmount.Value
            txtIssue.Text = sIssue.Value
        End If
        roPCODisplay.Text = ""
        butSelectItem.Visible = False
        configPCODropdown()
    End Sub
    
    Private Sub updateSelectedItems(Rev As Integer)
        Using db As New ChangeOrders
            roItemList.Text = db.buildItemsList(nCOID, Rev, "PCO", nContactID)
        End Using
    End Sub
    
    Private Sub butSelectItem_click() Handles butSelectItem.Click
        If cboActionSelect.SelectedValue = "CMCreateCORRevision" Then
            txtRequestedCOAmount.Text = hRequestedCOAmount.Value
            roRequestedCOAmount.Text = hRequestedCOAmount.Value
            txtIssue.Text = sIssue.Value
        End If
        Dim item As String = ""
        If sCoType = "COR" Then
            item = "PCO"
        ElseIf sCoType = "CO" Then
            item = "COR"
        End If
        processItemReference(item)
        butLeftPanelSelect.ImageUrl = "images/button_rfis.png"
        butLeftPanelSelect_Click()
    End Sub
    
    Private Sub butSelectRFI_click() Handles butSelectRFI.Click
        txtResponse.Text = sResponse.Value
        txtRequiredBy.DbSelectedDate = dRequiredBy.Value
        processItemReference("RFI")
        ContractDetailPanel_A.Visible = False
        ContractDetailPanel_B.Visible = False
        butSelectRFI.Visible = False
        roRFIDetail.Visible = False
    End Sub
            
    Private Sub processItemReference(referenceType As String)
        Using db As New ChangeOrders
            Dim saveType As String
            Dim coReference As Integer
            Dim isActive As Integer
            Dim rev As Integer
            Dim itemID As Integer
            
            If Session("TempRev") <> Nothing Then rev = Session("TempRev") Else rev = cboRevisions.SelectedValue
               
            If referenceType = "PCO" Then
                itemID = cboPCOSelect.SelectedValue
            ElseIf referenceType = "RFI" Then
                itemID = cboRFIReference.SelectedValue
            ElseIf referenceType = "COR" Then
                itemID = cboPCOSelect.SelectedValue
            End If
            
            Dim tbl As DataTable = db.checkSelectedItem(nCOID, itemID, rev, referenceType)
            
            If tbl.Rows.Count > 0 Then
                saveType = "Update"
                
                coReference = tbl.Rows(0).Item("COReferenceID")
                If referenceType = "PCO" Or referenceType = "COR" Then
                    If cboPCOSelectSwitch.SelectedValue = "Un-Select" Then
                        isActive = 0
                    ElseIf cboPCOSelectSwitch.SelectedValue = "Select" Then
                        isActive = 1
                    End If
                ElseIf referenceType = "RFI" Then
                    If cboRFISelectSwitch.SelectedValue = "Un-Select" Then
                        isActive = 0
                    ElseIf cboRFISelectSwitch.SelectedValue = "Select" Then
                        isActive = 1
                    End If
                End If
            Else
                saveType = "Insert"
                coReference = 0
                isActive = 1
            End If
            
            Dim objData(8) As Object
            
            objData(0) = itemID
            objData(1) = saveType
            objData(2) = nCOID
            objData(3) = nContactID
            objData(4) = coReference
            objData(5) = isActive
            objData(6) = rev
            objData(7) = referenceType
     
            db.saveSelectedItem(objData)
            
        End Using
        updateSelectedItems(Session("TempRev"))
        configPCODropdown()
        roPCODisplay.Text = ""
        butSelectItem.Visible = False
        If referenceType = "RFI" Then
            refreshRFIDropdown(cboContractID.SelectedValue)
        End If
    End Sub
    
    Private Sub configContractItems()
        Using db As New ChangeOrders
            Dim obj As Object = db.getContractItems(cboContractID.SelectedValue, nCOID)
            roContractAmount.Text = FormatCurrency((obj(0) + obj(1)).ToString())
            roContractAllowance.Text = FormatCurrency(obj(1).ToString())
            roAllowanceSpent.Text = FormatCurrency(obj(3))
            roAllowanceRemaining.Text = FormatCurrency(obj(1) - obj(3))
            Dim alowCO As Double = (obj(0) + obj(1)) * 0.1
            roAllowableAmendments.Text = FormatCurrency(alowCO)
            roProposedAmendments.Text = FormatCurrency(0)
            roApprovedAmendments.Text = FormatCurrency(obj(4))
            Dim remCO As Double = alowCO - obj(4)
            roRemainingForCOs.Text = FormatCurrency(remCO)
            roRevisedContract.Text = FormatCurrency((obj(0) + obj(1)) + obj(4))
            roProposedAmendments.Text = FormatCurrency(obj(5))
            roGCContractAmount.Text = FormatCurrency((obj(0) + obj(1)).ToString())
            roGCApprovedAmendments.Text = FormatCurrency(obj(4))
            roGCRevisedContract.Text = FormatCurrency((obj(0) + obj(1)) + obj(4))
        End Using
    End Sub
    
    Private Sub saveChangeOrder(saveType As String, wfp As String, saveStatus As String, COStatus As String)
        Dim dataObj(26) As Object
                        
        If txtSubject.Text = "" Then
            Session("ValidationError") = True
            responseMsg.Text = "You need to enter a subject!"
            responseMsg.Visible = True
            Exit Sub
        End If
        
        If txtIssue.Text = "" Then
            Session("ValidationError") = True
            responseMsg.Text = "You need to enter an issue!"
            responseMsg.Visible = True
            Exit Sub
        End If
        
        Session("UpdateData") = True
        
        dataObj(0) = Session("DistrictID")
        dataObj(1) = nProjectID
        dataObj(2) = cboContractID.SelectedValue
        dataObj(3) = createCoNumber(sCoType)
        If sCoType = "PCO" And Session("ContactType") = "Construction Manager" Then
            dataObj(4) = cboInitiatedBy.SelectedValue
        Else
            dataObj(4) = nContactID
        End If
        dataObj(5) = cboRFIReference.SelectedValue
        dataObj(6) = Now()
        dataObj(7) = txtRequiredBy.DbSelectedDate
        dataObj(8) = Replace(txtSubject.Text, "'", "~")
        dataObj(9) = "" 'txtReference.Text
        dataObj(10) = "" 'txtCostBreakdown.Text
        dataObj(11) = "" 'txtRequest.Text
        dataObj(12) = saveType
        dataObj(13) = nCOID
        dataObj(14) = saveStatus
        dataObj(15) = cboDPSelect.SelectedValue
        dataObj(16) = wfp
        dataObj(17) = COStatus
        
        'If saveType = "Insert" Then
        Using db As New ChangeOrders
            'dataObj(18) = db.getOriginalContractAmount(dataObj(2))
            'dataObj(19) = db.getTotalChangeOrders(dataObj(2))
            dataObj(18) = 0
            dataObj(19) = 0
        End Using
        ' End If
        
        If saveType = "Insert" Then
            dataObj(20) = 0 'Requested CO Increase
            'dataObj(20) = txtRequestedCOAmount.Text 
        Else
            dataObj(20) = txtRequestedCOAmount.Text 'Requested CO Increase
        End If

        dataObj(21) = 0 'txtDaysAdded.Text
        dataObj(22) = sCoType
        dataObj(23) = Replace(txtIssue.Text, "'", "~")
        dataObj(24) = nContactID
        dataObj(25) = txtAltReference.Text
        
        Using db As New ChangeOrders
            Dim sql As String = db.saveChangeOrder(dataObj)
            txtIssue.Text = sql
            If saveType = "Insert" Then
                'Session("addNew") = True
                Session("NewID") = db.getNewCOIDNumber(dataObj(3))
            End If
        End Using
        Try
            getData()
        Catch ex As Exception
        End Try
       
    End Sub
    
    Private Sub saveChangeOrderResponse(responseType As String, saveStatus As String, nextWfp As String, COStatus As String, validate As Boolean, decision As String, escalate As Integer)
        'saveChangeOrder("Update", "NoChange", "Preparing", "Preparing")          
        Dim saveType As String
        Dim responseID As Integer
        Dim seq As Integer = 0
        
        Using db As New ChangeOrders
            'Dim tbl As DataTable = db.getExistingResponse(nCOID, responseType, nContactID)
            Dim tbl As DataTable = db.getPreparingResponse(nCOID, cboRevisions.SelectedValue, nContactID, Session("ContactType"))
            If tbl.Rows.Count > 0 Then
                saveType = "Update"
                responseID = tbl.Rows(0).Item("PMCOResponseID")
            Else
                Dim countTbl As DataTable = db.countResponses(nCOID, cboRevisions.SelectedValue)
                seq = countTbl.Rows.Count + 1
                saveType = "Insert"
                responseID = 0
            End If
        End Using
        
        If sResponse.Value = "" Then
            Session("ValidationError") = True
            responseMsg.Text = "You need to provide a response to send!"
            responseMsg.Visible = True
            Exit Sub
        End If
        
        Session("UpdateData") = True
        
        Dim dataObj(20) As Object
        
        dataObj(0) = nCOID
        dataObj(1) = Replace(sResponse.Value, "'", "~")
        dataObj(2) = responseType
        dataObj(3) = Now
        dataObj(4) = nContactID
        dataObj(5) = saveStatus
        dataObj(6) = saveType
        dataObj(7) = responseID
        dataObj(8) = nextWfp
        dataObj(9) = COStatus
        dataObj(10) = cboDPSelect.SelectedValue
        dataObj(11) = cboRevisions.SelectedValue
        dataObj(12) = seq
        dataObj(13) = escalate
        dataObj(14) = decision
        dataObj(17) = roDaysInProcess.Text
        dataObj(18) = Left(txtAltReference.Text, 25)
        dataObj(19) = dRequiredBy.Value
       
        
        If cboActionSelect.SelectedValue = "PMApproveAllowance" Or cboActionSelect.SelectedValue = "PMApproveChangeOrder" Then
            dataObj(15) = txtFinanceVerified.DbSelectedDate
        End If
        
        If saveButton.Value = "PMCloseCOR" Then
            dataObj(16) = txtBoardApproved.DbSelectedDate
        End If
        
        Using db As New ChangeOrders
            db.saveChangeOrderResponse(dataObj)
            If cboRevisions.SelectedValue > 0 Then
                db.updateRevisionDecision(decision, nCOID, dataObj(11))
            End If
        End Using
        
        ProgrammerData.Text = dataObj(1)
        If saveStatus = "Preparing" Then
            getData()
        End If
    End Sub
    
    Private Sub saveChangeOrderRevision(Rev As Integer, saveStatus As String, status As String, saveType As String, wfp As String, revID As Integer)
        Session("UpdateData") = True
        Dim dataObj(13) As Object
        
        If txtIssue.Text = "" Then
            Session("ValidationError") = True
            responseMsg.Text = "You need to provide an issue to continue!"
            responseMsg.Visible = True
        End If
        
        dataObj(0) = dRequiredBy.Value 'New required by date
        dataObj(1) = nCOID
        dataObj(2) = Rev
        dataObj(3) = Replace(sIssue.Value, "'", "~")
        dataObj(4) = saveStatus
        dataObj(5) = status
        dataObj(6) = saveType
        dataObj(7) = wfp
        dataObj(8) = revID
        dataObj(11) = nContactID
        'dataObj(12) = txtRequestedCOAmount.Text
        dataObj(12) = hRequestedCOAmount.Value
        
        If cboActionSelect.SelectedValue = "EditCORRequired" Then
            dataObj(9) = 1
            dataObj(10) = "Approved"
        Else
            dataObj(9) = 0
            dataObj(10) = ""
        End If
        Using db As New ChangeOrders
            db.saveChangeOrderRevision(dataObj)
        End Using
        roIssue.Text = dataObj(3)
    End Sub
      
    Private Sub coUpdateWFP(wfp As String, status As String, newWorkflow As Boolean)
        Using db As New ChangeOrders
            db.coUpdateWFP(nCOID, wfp, status, newWorkflow)
        End Using
    End Sub
    
    Private Sub escalateChangeOrder(coType As String)
       
        Dim dataObj(11) As Object
        Dim obj(7) As Object
        
        dataObj(0) = Session("DistrictID")
        dataObj(1) = cboContractID.SelectedValue
        dataObj(2) = nProjectID
        dataObj(3) = createCoNumber(coType)
        dataObj(4) = nContactID
        dataObj(5) = Now
        dataObj(6) = coType
        dataObj(7) = nCOID
        dataObj(8) = hRequestedCOAmount.Value
        'dataObj(8) = 1005
        dataObj(9) = Today.AddDays(2)
        dataObj(10) = "Auto Generated " & coType
        
        Using db As New ChangeOrders
            db.escalateCO(dataObj)
            Threading.Thread.Sleep(1000)
           
            obj(0) = nCOID
            obj(1) = "Insert"
            obj(2) = db.getNewCOIDNumber(dataObj(3))
            obj(3) = nContactID
            obj(4) = 1
            obj(6) = 0
            
            db.saveSelectedItem(obj)
        End Using
        
        Session("CoType") = coType
        sCoType = coType
        Response.Redirect("changeorders_edit.aspx?ProjectID=" & nProjectID & "&ChangeOrderID=" & obj(2) & "&DisplayType=Existing&coType=" & Session("CoType"))
    End Sub
    
    Private Sub checkForAndCancelResponse()
        Using db As New ChangeOrders
            db.checkCancelResponse(nCOID)
        End Using
    End Sub
    
    Private Sub checkForAndCancelRevision(owner As String)
        Using db As New ChangeOrders
            db.cancelCORRevision(nCOID, Session("TempRev"), nContactID, owner)
        End Using
    End Sub
    
    Private Sub processSave(svbutton As String)
        Dim escalate As Integer = 0
        Dim decision As String = ""
        Select Case svbutton
            Case "New"
                WorkFlowPosition.Value = "None"
                'cboActionSelect.SelectedValue = "None"
                saveChangeOrder("Insert", "None", "Preparing", "Preparing")
                If Session("ValidationError") = True Then
                    Session("ValidationError") = False
                    cboActionSelect.SelectedValue = "Edit"
                Else
                    Response.Redirect("changeorders_edit.aspx?ProjectID=" & nProjectID & "&ChangeOrderID=" & Session("NewID") & "&DisplayType=Existing&coType=" & Session("CoType"))
                End If
           Case "Existing"
                saveChangeOrder("Update", "NoChange", "Preparing", "Preparing")
                If Session("ValidationError") = True Then
                    Session("ValidationError") = False
                    cboActionSelect.SelectedValue = "Edit"
                Else
                    butCancel_click()
                    cboActionSelect.SelectedValue = "None"
                End If
                'Session("Redirect") = True                
                'Response.Redirect("changeorders_edit.aspx?ProjectID=" & nProjectID & "&ChangeOrderID=" & nCOID & "&DisplayType=Existing&coType=" & Session("CoType"))
            Case "GCSendToCM"
                saveChangeOrder("Update", "CM:Review Pending", "Released", "Active")
                If Session("ValidationError") = True Then
                    Session("ValidationError") = False
                    cboActionSelect.SelectedValue = "Edit"
                Else
                    butCancel_click()
                End If
        
            Case "GCAcceptCMResponse"
                'David D added variable PMandCMFlip for conflict with "Completion Pending" which was going to PM for PCO, now it goes to the CM as designed
                
                Dim flipCMandPM As String
                If Session("CoType") = "PCO" Then
                    flipCMandPM = "CM"
                Else
                    flipCMandPM = "PM"
                End If
                saveChangeOrderResponse("GCAcceptResponseCM", "Released", flipCMandPM & ":Completion Pending", "Active", False, "NoChange", 0)
                If Session("ValidationError") = True Then
                    Session("ValidationError") = False
                Else
                    checkForAndCancelRevision("owner")
                    butCancel_click()
                End If
                'David D 6/8/17 created new saveButton.Value below of "GCRevisionCreate" to handle create/save toggle
            Case "GCSaveRevision", "GCSendRevisionToCM", "GCRevisionCreate"
                Dim saveType As String = ""
                Dim Rev As Integer
                Dim revID As Integer
                lblResponse.Text = ""
                Using db As New ChangeOrders
                    Dim tbl As DataTable = db.checkForRevision(nCOID, nContactID, Session("ContactType"), "owner")
                    If tbl.Rows.Count = 0 Then
                        saveType = "Insert"
                        Rev = db.getRevisionNumber(nCOID) + 1
                        revID = 0
                    Else
                        saveType = "Update"
                        Rev = tbl.Rows(0).Item("Revision")
                        revID = tbl.Rows(0).Item("CORevisionID")
                    End If
                    sSaveType.Value = saveType
                End Using
                'David D 6/8/17 changed below conditions and code blocks to allow create/save toggle
                If svbutton = "GCRevisionCreate" And Session("TempRev") > activeRevision.Value Then
                    saveChangeOrderRevision(Rev, "Preparing", "Preparing", saveType, "NoChange", revID)
                    cboActionSelect_Change()
                    butLeftPanelSelect.ImageUrl = "images/button_contract.png"
                    butLeftPanelSelect_Click()
                    saveButton.Value = "GCSaveRevision"
                    svbutton = saveButton.Value
                    butSave.ImageUrl = "images/button_save.png"
                    getRevisions()
                    cboRevisions.Visible = False
                    roRevisions.Visible = True
                    cboActionSelect.SelectedValue = "CreateRevision"
                    'David D 6/8/17 created below click/altertext and tool tip when the create buttons turns into the save button
                    alertText = "This action will save the new revision \nand will not advance to the next work flow position.\n\nDo you want to continue?"
                    butSave.OnClientClick = "return confirm('" & alertText & "')"
                    'David D 6/7/17 added tooltip below - can be removed
                    butSave.ToolTip = "This action will save the new revision and will not advance to the next work flow position."
                ElseIf svbutton = "GCSaveRevision" Then
                    saveChangeOrderRevision(Rev, "Preparing", "Preparing", saveType, "NoChange", revID)
                    cboActionSelect_Change()
                    butLeftPanelSelect.ImageUrl = "images/button_contract.png"
                    butLeftPanelSelect_Click()
                    butSave.Visible = True
                    butSave.ImageUrl = "images/button_save.png"
                    'David D 6/8/17 created below click/altertext and tool tip for save button
                    alertText = "This action will save the new revision \nand will not advance to the next work flow position.\n\nDo you want to continue?"
                    butSave.OnClientClick = "return confirm('" & alertText & "')"
                    'David D 6/7/17 added tooltip below - can be removed
                    butSave.ToolTip = "This action will save the new revision and will not advance to the next work flow position."
                    butCancel_click()
                ElseIf svbutton = "GCSendRevisionToCM" Then
                    saveChangeOrderRevision(Rev, "Released", "Active", saveType, "CM:Review Pending", revID)
                    butCancel_click()
                End If
            Case "GCSendReceived"
                coUpdateWFP("CO Complete", "Closed", "")
                butCancel_click()
            Case "AcknowledgeCORApproval"
                saveChangeOrderResponse("GCResponseToCM", "Released", "PM:Completion Pending", "NoChange", False, "NoChange", 0)
                If Session("ValidationError") = True Then
                    Session("ValidationError") = False
                Else
                    butCancel_click()
                End If
                ' Construction Manager case selections ---------------------------------  
            Case "CMActivatePCOForGC"
                saveChangeOrder("Update", "CM:Review Pending", "Released", "Active")
                If Session("ValidationError") = True Then
                    Session("ValidationError") = False
                Else
                    butCancel_click()
                End If
            Case "CMResponseToGC"
                saveChangeOrder("Update", "GC:Receipt Pending", "Released", "Active")
                If Session("ValidationError") = True Then
                    Session("ValidationError") = False
                Else
                    butCancel_click()
                End If
            Case "CMSendToDP"
                saveChangeOrderResponse("CMResponseToDP", "Released", "DP:Response Pending", "Active", False, "NoChange", 0)
                If Session("ValidationError") = True Then
                    Session("ValidationError") = False
                Else
                    butCancel_click()
                End If
                
            Case "saveCMResponse"
                escalate = hEscalate.Value
                decision = hDecision.Value
                If Session("ContactType") = "ProjectManager" Then
                    checkForAndCancelResponse()
                    checkForAndCancelRevision("non")
                End If
                saveChangeOrderResponse("CMResponseToGC", "Preparing", "", "Active", False, decision, escalate)
                If Session("ValidationError") = True Then
                    responseMsg.Text = "You need to provide a response!"
                    Session("ValidationError") = False
                Else
                    butCancel_click()
                End If
                'Session("Redirect") = True
                'Response.Redirect("changeorders_edit.aspx?ProjectID=" & nProjectID & "&ChangeOrderID=" & nCOID & "&DisplayType=Existing&coType=" & Session("CoType"))               
            Case "CMSaveSendToGC"
                If cboActionSelect.SelectedValue = "EditCORRequired" Then
                    escalate = 1
                    decision = "Approved"
                Else
                    escalate = 0
                End If
                saveChangeOrderResponse("CMResponseToGC", "Released", "GC:Receipt Pending", "Active", False, "NoChange", escalate)
                If Session("ValidationError") = True Then
                    Session("ValidationError") = False
                Else
                    If Session("ContactType") = "ProjectManager" Then
                        responseMsg.Visible = True
                        checkForAndCancelResponse()
                    End If
                    
                    If escalate = 1 Then
                        Session("Redirect") = True
                        escalateChangeOrder("COR")
                    Else
                        butCancel_click()
                    End If
                    'butCancel_click()
                End If
               
            Case "CMclosePCO"
                saveChangeOrderResponse("CMClosePCONote", "Released", "PCO Complete", "Closed", False, "NoChange", 0)
                If Session("ValidationError") = True Then
                    Session("ValidationError") = False
                Else
                    butCancel_click()
                End If
            Case "CMCloseCO"
                saveChangeOrderResponse("CMCloseCONote", "Released", "CO Complete", "Closed", False, "NoChange", 0)
                If Session("ValidationError") = True Then
                    Session("ValidationError") = False
                Else
                    butCancel_click()
                End If
            Case "CMSendToPM"
                saveChangeOrder("Update", "PM:Review Pending", "Released", "Active")
                If Session("ValidationError") = True Then
                    Session("ValidationError") = False
                Else
                    butCancel_click()
                End If
            Case "CMSendCOToPM"
                saveChangeOrder("Update", "PM:Review Pending", "Released", "Active")
                If Session("ValidationError") = True Then
                    Session("ValidationError") = False
                Else
                    butCancel_click()
                End If
            Case "CMReleaseToGC"
                coUpdateWFP("GC:Receipt Pending", "Active", True)
                butCancel_click()
            Case "CMReleaseCORGC"
                If Session("ContactType") = "ProjectManager" Then
                    checkForAndCancelResponse()
                End If
                saveChangeOrderResponse("CMResponseToGC", "Released", "GC:Receipt Pending", "Active", False, "NoChange", 0)
                If Session("ValidationError") = True Then
                    Session("ValidationError") = False
                Else
                    butCancel_click()
                End If
            Case "CMCreateCONotifyGC"
                If cboActionSelect.SelectedValue = "CMMoveToCONotifyGC" Then
                    escalate = 1
                    decision = "Approved"
                End If
                saveChangeOrderResponse("CMResponseToGC", "Released", "GC:Receipt Pending", "Active", False, "NoChange", escalate)
                If Session("ValidationError") = True Then
                    Session("ValidationError") = False
                Else
                    Session("Redirect") = True
                    escalateChangeOrder("CO")
                End If
            Case "CMcloseCOR"
                saveChangeOrderResponse("CMResponseToGC", "Released", "COR Complete", "Closed", False, "NoChange", 0)
                If Session("ValidationError") = True Then
                    Session("ValidationError") = False
                Else
                    butCancel_click()
                End If
            Case "saveCMCORRevision", "CMReleaseRevisionPM", "CMSaveCORevision", "CMSendCORevision"
                Dim saveType As String = ""
                Dim Rev As Integer
                Dim revID As Integer
                Using db As New ChangeOrders
                    Dim tbl As DataTable = db.checkForRevision(nCOID, nContactID, Session("ContactType"), "owner")
                    If tbl.Rows.Count = 0 Then
                        saveType = "Insert"
                        Rev = db.getRevisionNumber(nCOID) + 1
                        revID = Rev
                    Else
                        saveType = "Update"
                        Rev = tbl.Rows(0).Item("Revision")
                        revID = tbl.Rows(0).Item("CORevisionID")
                    End If
                End Using
                testPlace.Value = svbutton
                sSaveType.Value = saveType
                If svbutton = "saveCMCORRevision" Then
                    saveChangeOrderRevision(Rev, "Preparing", "Preparing", saveType, "NoChange", revID)
                    If Session("ValidationError") = True Then
                        Session("ValidationError") = False
                    Else
                        checkForAndCancelRevision("non")
                        Session("TempRev") = Nothing
                        butCancel_click()
                    End If
                ElseIf svbutton = "CMReleaseRevisionPM" Then
                    saveChangeOrderRevision(Rev, "Released", "Active", saveType, "PM:Review Pending", revID)
                    If Session("ValidationError") = True Then
                        Session("ValidationError") = False
                    Else
                        checkForAndCancelRevision("non")
                        Session("TempRev") = Nothing
                        butCancel_click()
                    End If
                ElseIf svbutton = "CMSaveCORevision" Then
                    saveChangeOrderRevision(Rev, "Preparing", "Preparing", saveType, "NoChange", revID)
                    If Session("ValidationError") = True Then
                        Session("ValidationError") = False
                    Else
                        cboActionSelect.SelectedValue = "None"
                        configReadOnly()
                        buildResponseDropdown("")
                        configPMReviewPending()
                        getRevisions()
                        cboRevisions.Visible = True
                        cboActionSelect.Visible = True
                    End If
                ElseIf svbutton = "CMSendCORevision" Then
                    saveChangeOrderRevision(Rev, "Released", "Active", saveType, "PM:Review Pending", revID)
                    If Session("ValidationError") = True Then
                        Session("ValidationError") = False
                    Else
                        butCancel_click()
                    End If
                End If
                '----------- Design Professionals ------------------------------------------------------------
            Case "DPSendToPM"
                'saveChangeOrderResponse("DPResponseToCM", "Released", "PM:Review DP Response", "Active", False, "NoChange", 0)
                saveChangeOrderResponse("DPResponseToCM", "Released", "PM:Approval Pending", "Active", False, "NoChange", 0)
                If Session("ValidationError") = True Then
                    Session("ValidationError") = False
                Else
                    butCancel_click()
                End If
            Case "saveDPResponse"
                saveChangeOrderResponse("DPResponseToCM", "Preparing", "", "Active", False, "", 0)
                If Session("ValidationError") = True Then
                    Session("ValidationError") = False
                    responseMsg.Text = "You need to provide a response to save!"
                Else
                    cboActionSelect.SelectedValue = "None"
                    configResponsePrepare()
                    buildResponseDropdown("Released")
                    butCancel_click()
                End If
            Case "DPSendBackToCM"
                saveChangeOrderResponse("DPResponseToCM", "Released", "CM:Review Pending", "Active", False, "NoChange", 0)
                If Session("ValidationError") = True Then
                    Session("ValidationError") = False
                Else
                    butCancel_click()
                End If
                butCancel_click()
            Case "PrepareCORResponse"
                saveChangeOrderResponse("DPCORResponse", "Preparing", "NoChange", "NoChange", False, "NoChange", 0)
                cboActionSelect.SelectedValue = "None"
                configResponsePrepare()
                buildResponseDropdown("Released")
            Case "SubmitCORResponse"
                saveChangeOrderResponse("DPCORResponse", "Released", "NoChange", "NoChange", False, "NoChange", 0)
                butCancel_click()
                '------------ Project Manager ----------------------------------------------------------------           
            Case "PMSendBackToCM"
                saveChangeOrderResponse("PMResponseToCM", "Released", "CM:Distribution Pending", "Active", False, "Not Approved", 0)
                If Session("ValidationError") = True Then
                    Session("ValidationError") = False
                Else
                    butCancel_click()
                End If
            Case "PMSendToDP"
                If cboDPSelect.SelectedValue = "0" Then
                    conflictMessage.Visible = True
                    conflictMessage.Text = "You need to select a Design Professional before sending!"
                    conflictMessage.Height = "29"
                    Exit Sub
                Else
                    saveChangeOrderResponse("PMResponseToDP", "Released", "DP:Review Pending", "Active", False, "NoChange", 0)
                    If Session("ValidationError") = True Then
                        Session("ValidationError") = False
                    Else
                        butCancel_click()
                    End If
                End If
            Case "PMToApprovalPending"
                'coUpdateWFP("PM:Approval Pending", "Active", True)
                If Session("ContactType") = "ProjectManager" Then
                    checkForAndCancelResponse()
                End If
                saveChangeOrderResponse("PMReviewPendingNote", "Released", "PM:Approval Pending", "Active", False, "NoChange", 0)
                If Session("ValidationError") = True Then
                    Session("ValidationError") = False
                Else
                    butCancel_click()
                End If
            Case "savePMResponse"
                If Session("ContactType") = "ProjectManager" Then
                    checkForAndCancelResponse()
                    checkForAndCancelRevision("non")
                End If
                saveChangeOrderResponse("PMResponseSave", "Preparing", "NoChange", "Active", False, "NoChange", 0)
                If Session("ValidationError") = True Then
                    Session("ValidationError") = False
                    responseMsg.Text = "You need to provide a respone!"
                Else
                    butCancel_click()
                End If
            Case "PMApproveAllowance", "PMApproveChangeOrder"
                If IsNothing(txtFinanceVerified.DbSelectedDate) Then
                    conflictMessage.Visible = True
                    conflictMessage.Text = "You need to select a 'Finance Verified' date before you can move to the next workflow position!"
                    Exit Sub
                End If
                Dim type As String = ""
                'David D 6/20/17 decision in DB is only 15 nchar, had to shorten decision values "type" was causing server error "string or binary data would be truncated"
                If cboActionSelect.SelectedValue = "PMApproveAllowance" Then
                    type = "Approved-Allowance"
                ElseIf cboActionSelect.SelectedValue = "PMApproveChangeOrder" Then
                    type = "Approved-Change Order"
                End If
                saveChangeOrderResponse("PMApprovalNoteToCM", "Released", "CM:Distribution Pending", "Active", False, type, 0)
                If Session("ValidationError") = True Then
                    Session("ValidationError") = False
                Else
                    butCancel_click()
                End If
            Case "PMCloseCOR"
                If IsNothing(txtBoardApproved.DbSelectedDate) And Trim(hDecision.Value) = "Approved-Change Order" Then
                    'conflictMessage.Visible = True
                    'conflictMessage.Text = "You need to select a board approved date!"
                    responseMsg.Visible = True
                    responseMsg.Text = "You need to select a board approved date!"
                Else
                    saveChangeOrderResponse("PMCloseNote", "Released", "COR Complete", "Closed", False, "NoChange", 0)
                    If Session("ValidationError") = True Then
                        Session("ValidationError") = False
                    Else
                        butCancel_click()
                    End If
                End If
            Case "PMApprove" '###########################
                coUpdateWFP("CM:Distribution Pending", "Active", True)
                cboActionSelect.SelectedValue = "None"
                getData()
                configResponsePrepare()
                getResponseData("")
                buildResponseDropdown("Released")
            Case "PMOverrideGCAccept"
                saveChangeOrderResponse("PMOverridGCNote", "Released", "PM:Completion Pending", "Active", False, "NoChange", 0)
                If Session("ValidationError") = True Then
                    Session("ValidationError") = False
                Else
                    butCancel_click()
                End If
            Case "PMApproveCOR" '############################
                'David D 6/6/17 for PCO this case should go to Completion Pending and not Distribution pending variable below handles this
                Dim workflowFlipPCO As String
                If Session("CoType") = "PCO" Then
                    workflowFlipPCO = "Completion Pending"
                Else 'if CO
                    workflowFlipPCO = "Distribution Pending"
                End If
                saveChangeOrderResponse("PMApproveResponseCM", "Released", "CM:" & workflowFlipPCO, "Active", False, "Approved", 0)
                If Session("ValidationError") = True Then
                    Session("ValidationError") = False
                Else
                    butCancel_click()
                End If
            Case "PMRejectCOR" '##############################
                Dim wfp As String
                If sCoType = "COR" Then
                    wfp = "CM:Distribution Pending"
                ElseIf sCoType = "CO" Then
                    wfp = "CM:Response Pending"
                End If
                saveChangeOrderResponse("PMRejectResponseCM", "Released", wfp, "Active", False, "Not Approved", 0)
                If Session("ValidationError") = True Then
                    Session("ValidationError") = False
                Else
                    butCancel_click()
                End If
            Case "PMSaveBoardResponse" 'this can be removed #########################################
                saveChangeOrderResponse("PMResponseToBoard", "Preparing", "PM:Approval Pending", "Active", False, "", 0)
                cboActionSelect.SelectedValue = "None"
                configResponsePrepare()
                buildResponseDropdown("")
                checkForResponse(cboRevisions.SelectedValue, "")
            Case "PMSendToBoard" 'this can be removed ###############################################
                saveChangeOrderResponse("PMResponseToBoard", "Released", "PM:BOD Approval Pending", "Active", False, "Approved", 0)
                butCancel_click()
            Case "PMBODApprove" 'this can be removed ##################################################
                saveChangeOrderResponse("PMBODApproveToCM", "Released", "CM:Completion Pending", "Active", False, "", 0)
                butCancel_click()
            Case "PMBODReject" 'this can be removed ###################################################
                saveChangeOrderResponse("PMBODRejectToCM", "Released", "CM:Response Pending", "Active", False, "", 0)
                butCancel_click()
        End Select
    End Sub
    
    Private Sub butLeftPanelSelect_Click() Handles butLeftPanelSelect.Click
        If sResponse.Value <> "" Then
            txtResponse.Text = sResponse.Value
        End If
        If sIssue.Value <> "" Then
            txtIssue.Text = sIssue.Value
        End If
        txtRequiredBy.DbSelectedDate = dRequiredBy.Value
        cboActionSelect.OpenDropDownOnLoad = False
        Dim strOut As String = ""
        Dim getItem As String = ""
        Dim rev As Integer = 0
        roRFIDetail.Visible = False
        lblIssue.Text = "Issue/Explanation:"
        If sCoType = "COR" Then
            SelectedItemDetailPanel.Visible = True
            strOut = "<b><br/>Related Items<br/><br/>"
            getItem = "PCO"
        ElseIf sCoType = "PCO" Then
            lblRFIItems.Visible = True
            RFISelectPanel.Visible = True
            cboRFIReference.SelectedValue = "Not Applicable"
            butSelectRFI.Visible = False
            If cboActionSelect.SelectedValue <> "None" Then
                If cboActionSelect.SelectedValue <> "CMClosePCO" Then
                    cboRFIReference.Visible = True
                    cboRFISelectSwitch.Visible = True
                End If
            Else
                cboRFIReference.Visible = False
                cboRFISelectSwitch.Visible = False
            End If
            getItem = "RFI"
        ElseIf sCoType = "CO" Then
            getItem = "COR"
            SelectedItemDetailPanel.Visible = True
            strOut = "<b><br/>Related Items<br/><br/>"
        End If
        buildPCOList(strOut, getItem)
        If butLeftPanelSelect.ImageUrl <> "images/button_contract.png" Then
            butLeftPanelSelect.ImageUrl = "images/button_contract.png"
            ContractDetailPanel_A.Visible = False
            ContractDetailPanel_B.Visible = False
            If WorkFlowPosition.Value = "CM:Review Pending" Or WorkFlowPosition.Value = "GC:Receipt Pending" Then
                refreshRFIDropdown(Session("ContractID"))
                If cboActionSelect.SelectedValue = "GCAcceptCMResponse" Then
                    cboRFIReference.Visible = False
                    cboRFISelectSwitch.Visible = False
                End If
            End If
        ElseIf butLeftPanelSelect.ImageUrl = "images/button_contract.png" Then
            If sCoType = "COR" Then
                butLeftPanelSelect.ImageUrl = "images/button_pcos.png"
            ElseIf sCoType = "CO" Then
                butLeftPanelSelect.ImageUrl = "images/button_cors.png"
            ElseIf sCoType = "PCO" Then
                butLeftPanelSelect.ImageUrl = "images/button_rfis.png"
                'RFISelectPanel.Visible = True
                SelectedItemDetailPanel.Visible = True
            End If
            If Session("ContactType") = "General Contractor" Or Session("ContactType") = "Design Professional" Then
                ContractDetailPanel_A.Visible = False
                ContractDetailPanel_B.Visible = True
            Else
                ContractDetailPanel_A.Visible = True
                ContractDetailPanel_B.Visible = False
            End If
            RFISelectPanel.Visible = False
            SelectedItemDetailPanel.Visible = False
        End If
    End Sub
    
    Private Sub buildPCOList(strOut As String, getItem As String)
        Using db As New ChangeOrders
            Dim rev As Integer
            If IsNumeric(Session("TempRev")) Then
                rev = Session("TempRev")
            Else
                rev = cboRevisions.SelectedValue
            End If
            Try
                If cboActionSelect.SelectedValue = "CMCreateCORRevision" Then
                    Dim tbl As DataTable = db.getCORevisions(nCOID)
                    Dim count As Integer = tbl.Rows.Count
                    
                    strOut &= db.buildItemsList(nCOID, rev, getItem, nContactID) & "</b>"
                Else
                    strOut &= db.buildItemsList(nCOID, rev, getItem, nContactID) & "</b>"
                End If
                roItemsDisplay.Text = strOut
                roRFIItems.Text = strOut
            Catch ex As Exception
            End Try
        End Using
    End Sub
    
    Private Function checkForSessionConflict() As Boolean
        Dim checkCO As Boolean = False
        Using db As New ChangeOrders
            Dim tbl As DataTable = db.checkForActiveCOSession(nCOID, nContactID)
            'Session("tSimeSpan") = Nothing
            If tbl.Rows.Count > 0 Then
                Dim timeSpan As DateTime = tbl.Rows(0).Item("StartTime")
                Dim timeElapse As Integer = (DateTime.Now - timeSpan).TotalSeconds
               
                If timeElapse > 1800 Then
                    db.sessionEnd(nCOID, "", tbl.Rows(0).Item("ContactID"))
                    recordSessionStart()
                Else
                    conflictID.Value = tbl.Rows(0).Item("ContactID")
                    If tbl.Rows(0).Item("ContactID") = nContactID Then
                        checkCO = False
                    Else
                        checkCO = True
                    End If
                End If
            Else
                checkCO = False
                conflictID.Value = 0
            End If
        End Using
        Return checkCO
    End Function
    
    Private Sub recordSessionStart()
        Dim sesID As String = Session.SessionID
        Using db As New ChangeOrders
            db.sessionStart(nContactID, nCOID, WorkFlowPosition.Value, Session.SessionID)
        End Using
    End Sub
    
    Private Function getSessionConflictData() As Object
        Dim obj(2) As Object
        Using db As New ChangeOrders
            Dim rfiConflict As DataTable = db.checkForActiveCOSession(nCOID, nContactID)
            Try
                conflictID.Value = rfiConflict.Rows(0).Item("ContactID")
                Dim name As String = db.getResponderName(rfiConflict.Rows(0).Item("ContactID"))
                obj(0) = name
                obj(1) = rfiConflict.Rows(0).Item("StartTime")
            Catch ex As Exception
                Session("sessionConflict") = False
            End Try
        End Using
        Return obj
    End Function
    
    Private Sub conflictCheckRecord()
        If Session("sessionConflict") <> True Then
            Try
                If conflictID.Value <> nContactID Then
                    'If Session("ContactType") <> "Design Professional" Then
                    Select Case Trim(WorkFlowPosition.Value)
                        Case "CM:Distribution Pending"
                            If Session("ContactType") = "General Contractor" Or Session("ContactType") = "District" Then
                            Else
                                recordSessionStart()
                            End If
                        Case "CM:Review Pending"
                            If Session("ContactType") = "General Contractor" Or Session("ContactType") = "District" Then
                            Else
                                recordSessionStart()
                            End If
                        Case "CM:Acceptance Pending"
                            If Session("ContactType") = "General Contractor" Or Session("ContactType") = "District" Then
                            Else
                                recordSessionStart()
                            End If
                        Case "CM:Completion Pending"
                            If Session("ContactType") = "General Contractor" Or Session("ContactType") = "District" Then
                            Else
                                recordSessionStart()
                            End If
                        Case "GC:Acceptance Pending", "GC:Receipt Pending"
                            If Session("ContactType") = "Construction Manager" Or Session("ContactType") = "District" Then
                            Else
                                recordSessionStart()
                            End If
                        Case "DP:Response Pending", "DP:Review Pending"
                            If Session("ContactType") = "District" Then
                            Else
                                recordSessionStart()
                            End If
                        Case Else
                    End Select
                    'End If
                End If
            Catch ex As Exception
        End Try
        End If
    End Sub
   
    Private Sub setNewWorkflowStatus()
        Using db As New ChangeOrders
            db.setNewWorkflowStatus(nCOID)
        End Using
    End Sub
    
    Private Sub setNewCORValue() 'sets values to control when the PCO dropdown gets updated.
        If cboActionSelect.SelectedValue = "CMCreateCORRevision" Then
            If Session("ActionChange") = Nothing Or Session("ActionChange") <> "PCODropdownSet" Then
                Session("ActionChange") = "True"
            ElseIf Session("ActionChange") = "PCODropdownSet" Then
            End If
        Else
            Session("ActionChange") = Nothing
        End If
    End Sub
    
    Private Sub butSend_click() Handles butSend.Click
        
        'responseOut.Value = "response out"
        'If WorkFlowPosition.Value = "PM:Review Pending" Or WorkFlowPosition.Value = "GC:Receipt Pending" Then
        txtResponse.Text = sResponse.Value
        ' End If
        If Page.IsValid Then
            processSave(sendButton.Value)
        End If
    End Sub
        
    Private Sub butSave_click() Handles butSave.Click
        'This traps an error caused by shutting down the validation stuff necesssary for testing 
        'responseOut.Value = "response out"
        'If WorkFowPosition.Value = "PM:Review Pending" Or WorkFlowPosition.Value = "GC:Receipt Pending" Then
        txtResponse.Text = sResponse.Value
        'testPlace.Value = "here"
        'End If
        Try
            If Page.IsValid Then
                processSave(saveButton.Value)
            End If
        Catch ex As Exception
            processSave(saveButton.Value)
        End Try
    End Sub
         
    Private Sub butCancel_click() Handles butCancel.Click
        Session("RtnFromEdit") = True
        ProcLib.CloseAndRefreshRADNoPrompt(Page)
    End Sub
       
</script>
<html>
<head>
    <title id="title">
        <% = sTitle%></title>
    <link href="Styles.css" type="text/css" rel="stylesheet" />
    <style type="text/css">
    .alignTop
    {
        top:185px;
    }
    </style>
    <script type="text/javascript" language="javascript">

        //$(document).ready(function () {
            //alert('This is here')

        //});

        function GetRadWindow() {
            var oWindow = null;
            if (window.RadWindow) oWindow = window.RadWindow;
            else if (window.frameElement.radWindow) oWindow = window.frameElement.radWindow;
            return oWindow;
        }
        function ShowHelp()     //for help display
        {
            var oWnd = window.radopen("help_view.aspx?WinType=RAD", "ShowHelpWindow");
            return false;
        } 
    </script>
</head>
<body>
    <form id="Form1" method="post" runat="server">
    <telerik:RadScriptManager ID="RadScriptManager1" runat="server" />
    <asp:HiddenField ID="sSaveType" runat="server" />
    <asp:HiddenField ID="revisionExists" runat="server" />
    <asp:HiddenField ID="activeRevision" runat="server" />
    <asp:HiddenField ID="showRevisions" runat="server" />
    <asp:HiddenField ID="showAction" runat="server" />
    <asp:HiddenField ID="showResponses" runat="server" />
    <asp:HiddenField ID="editReturn" runat="server" />
    <asp:HiddenField ID="conflictID" runat="server" />                                                                      
    <asp:HiddenField ID="saveButton" runat="server" /> 
    <asp:HiddenField ID="sendButton" runat="server" /> 
    <asp:HiddenField ID="commentButton" runat="server" />
    <asp:HiddenField ID="configType" runat="server" />  
    <asp:HiddenField ID="SaveStatus" runat="server" />
    <asp:HiddenField ID="WorkFlowPosition" runat="server" />
    <asp:HiddenField ID="isInitiator" runat="server" />  
    <asp:HiddenField ID="hEscalate" runat="server" />   
    <asp:HiddenField ID="hDecision" runat="server" />
    <asp:HiddenField ID="hRequestedCOAmount" runat="server" />
    <asp:HiddenField ID="sResponse" runat="server" />
    <asp:HiddenField ID="sIssue" runat="server" />
    <asp:HiddenField ID="responseVisible" runat="server" />
    <asp:HiddenField ID="revChange" runat="server" />
    <asp:HiddenField ID="initResponseID" runat="server" />
    <asp:HiddenField ID="responseOut" runat="server" />
    <asp:HiddenField ID="issueOut" runat="server" />
    <asp:HiddenField ID="dRequiredBy" runat="server" />
    <asp:HiddenField ID="testPlace" runat="server" />

    <asp:Panel ID="uploadPanel" runat="server" Visible="false" style="z-index:106;height:440px;width:445px;
                        left:330px;top:43px;position:absolute;background-color:e7e9ed"> 

         <asp:Label ID="lblUploadPanel" runat="server" Text="Contract Select:" style="Position:absolute;left:5px;top:0px;font-weight:bold">
         </asp:Label>                        
        
        <iframe ID="uploadFrame1" src="" runat="server"
            style="position:absolute;width:445px;height:360px;top:30px;border-style:none">              
         </iframe>
           
    </asp:Panel>

    <asp:Label ID="lblAltReference" runat="server" Text="Alternate Reference Number:" style="position:absolute;top:12px;left:340px"></asp:Label>

    <asp:TextBox ID="txtAltReference" runat="server" style="position:absolute;top:12px;left:500px"></asp:TextBox>

    <asp:Panel ID="itemSelectPanel" runat="server" Visible="false" style="height:240px;width:435px;left:340px;top:265px;
                            position:absolute;background-color:transparent">

         <telerik:RadComboBox ID="cboPCOSelectSwitch" runat="server" Style="left:5px;width:130px;position:absolute;top:19px;" autopostback="True"  
            Skin="Vista" TabIndex="0">
             <Items>
            <telerik:RadComboBoxItem runat="server" Text="Add PCO" Value="Select" />
            <telerik:RadComboBoxItem runat="server" Text="Remove PCO" Value="Un-Select" />
        </Items>
        </telerik:RadComboBox>

        <telerik:RadComboBox ID="cboPCOSelect" runat="server" Style="left:5px;width:130px;position:absolute;top:42px;" autopostback="True"  
            Skin="Vista"  TabIndex="0">
        </telerik:RadComboBox>

        <asp:ImageButton ID="butSelectItem" Style="z-index: 100; left: 5px; position: absolute;
            top:70px" runat="server" 
            ImageUrl="images/button_select.png" Visible="false">
        </asp:ImageButton>

        <asp:Label ID="roPCODisplay" runat="server" Text="" style="Position:absolute;left:150px;height:180px;width:270px;top:20px;background-color: #f2f5ff;padding:5px">
        </asp:Label>  
          
        <asp:Label ID="roItemList" runat="server" Text="" style="Position:absolute;left:5px;height:140px;width:140px;top:100px;border-style:solid;border-width:0px;font-weight:bold">
        </asp:Label>     
            
    </asp:Panel>

    <asp:HyperLink ID="butHelp" style="Position:absolute;left:730px;top:8px;width:45px" runat="server" ImageUrl="images/button_help.gif">HyperLink</asp:HyperLink>

     <asp:Label ID="conflictMessage" Style="z-index: 109; left: 10px; position: absolute; top: 242px;
            font-weight:bold;font-size:14px;line-height:15px;background-color:#ffffff;padding:5px"
        runat="server" Height="50px" Width="300px"  ForeColor="red" Visible="false" >
     </asp:Label>

     <asp:Label ID="lblContractID" runat="server" Text="Contract Select:" style="Position:absolute;left:5px;top:12px">
     </asp:Label>

     <telerik:RadComboBox ID="cboContractID" runat="server" Style="z-index: 605; left: 97px; 
        position: absolute; top: 10px;" autopostback="True"  
        Skin="Vista"  Width="525px"  TabIndex="0">
    </telerik:RadComboBox>

    <asp:Label ID="lblBoardApproved" runat="server" Text="" visible="false" style="Position:absolute;left:5px;top:215px;">BOD Approved:
    </asp:Label>

     <telerik:RadDatePicker ID="txtBoardApproved" Style="z-index: 103; left: 100px; position: absolute;
        top: 213px;" runat="server" Width="100px" Skin="Web20" visible="false"
        TabIndex="3" >
        <DateInput ID="DateInput1" runat="server" Skin="WebBlue" Font-Size="13px" ForeColor="Blue" 
            TabIndex="3">
        </DateInput>
        <Calendar ID="Calendar1" runat="server" UseRowHeadersAsSelectors="False" UseColumnHeadersAsSelectors="False"
            ViewSelectorText="x" Skin="Web20">
             <SpecialDays> 
            <telerik:RadCalendarDay Repeatable="Today"> 
                <ItemStyle BackColor="LightBlue" /> 
            </telerik:RadCalendarDay> 
        </SpecialDays> 
        </Calendar>
        <DatePopupButton ImageUrl="" HoverImageUrl="" TabIndex="3"></DatePopupButton>
    </telerik:RadDatePicker>

    <asp:Label ID="roBoardApproved" runat="server" Text="" visible="false" style="Position:absolute;left:97px;top:215px;font-weight:bold">
    </asp:Label>

    <telerik:RadComboBox ID="cboRevisions" runat="server" Style="z-index: 605; left: 290px; 
        position: absolute; top: 60px;" autopostback="True"  
        Skin="Vista"  Width="30px"  TabIndex="0">
    </telerik:RadComboBox>

     <asp:Label ID="roRevisions" runat="server" Text="" style="Position:absolute;left:290px;top:62px;">
     </asp:Label>

     <asp:Label ID="lblRevisions" runat="server" Text="" style="Position:absolute;left:240px;top:62px;">Revision:
     </asp:Label>

     <asp:Label ID="roContractID" runat="server" Text="" style="Position:absolute;left:100px;top:12px;font-weight:bold">
     </asp:Label>

     <asp:Label ID="lblChangeOrderID" runat="server" Text="" style="Position:absolute;left:255px;top:12px;font-weight:bold">
     </asp:Label>


     <asp:Label ID="lblCreateDate" runat="server" Text="Create Date:" style="Position:absolute;left:21px;top:35px">
     </asp:Label>

     <asp:Label ID="roCreateDate" runat="server" Text="" style="Position:absolute;left:97px;top:35px;font-weight:bold">
     </asp:Label>

     <asp:Label ID="lblDaysInProcess" runat="server" style="Position:absolute;left:190px;top:35px">Days In Process:</asp:Label>

      <asp:Label ID="roDaysInProcess" runat="server" style="Position:absolute;left:278px;top:35px;font-weight:bold"></asp:Label>
     
     <asp:Label ID="lblFinanceVerified" runat="server" Text="Finance Verified:" visible="false" style="Position:absolute;left:0px;top:190px">
     </asp:Label>

      <asp:Label ID="roFinanceVerified" runat="server" Text="" visible="false" style="Position:absolute;left:97px;top:190px;font-weight:bold">
     </asp:Label>

     <telerik:RadDatePicker ID="txtFinanceVerified" Style="z-index: 103; left: 97px; position: absolute;
        top: 190px;" runat="server" Width="120px" Skin="Web20" visible="false"
        TabIndex="3" >
        <DateInput ID="DateInput1" runat="server" Skin="WebBlue" Font-Size="13px" ForeColor="Blue" 
            TabIndex="3">
        </DateInput>
        <Calendar ID="Calendar1" runat="server" UseRowHeadersAsSelectors="False" UseColumnHeadersAsSelectors="False"
            ViewSelectorText="x" Skin="Web20">
             <SpecialDays> 
            <telerik:RadCalendarDay Repeatable="Today"> 
                <ItemStyle BackColor="LightBlue" /> 
            </telerik:RadCalendarDay> 
        </SpecialDays> 
        </Calendar>
        <DatePopupButton ImageUrl="" HoverImageUrl="" TabIndex="3"></DatePopupButton>
    </telerik:RadDatePicker>

     <asp:Label ID="lblRequiredBy" runat="server" Text="Required By:" Visible="false" style="Position:absolute;left:18px;top:215px">
     </asp:Label>

      <telerik:RadDatePicker ID="txtRequiredBy" Style="z-index: 103; left: 97px; position: absolute;
        top: 215px;" runat="server" Width="120px" Skin="Web20" visible="false"
        TabIndex="3" >
        <DateInput ID="DateInput1" runat="server" Skin="WebBlue" Font-Size="13px" ForeColor="Blue" 
            TabIndex="3">
        </DateInput>
        <Calendar ID="Calendar1" runat="server" UseRowHeadersAsSelectors="False" UseColumnHeadersAsSelectors="False"
            ViewSelectorText="x" Skin="Web20">
             <SpecialDays> 
            <telerik:RadCalendarDay Repeatable="Today"> 
                <ItemStyle BackColor="LightBlue" /> 
            </telerik:RadCalendarDay> 
        </SpecialDays> 
        </Calendar>
        <DatePopupButton ImageUrl="" HoverImageUrl="" TabIndex="3"></DatePopupButton>
    </telerik:RadDatePicker>

     <asp:Label ID="roRequiredBy" runat="server" Text="" Visible="false" style="Position:absolute;left:97px;top:215px;font-weight:bold">
     </asp:Label>

     <asp:Label ID="lblInitiatedBy" runat="server" Text="Initiated By/For:" Visible="false" style="Position:absolute;left:2px;top:60px">
     </asp:Label>

     <asp:Label ID="roInitiatedBy" runat="server" Text="" Visible="false" style="Position:absolute;left:97px;top:60px;font-weight:bold">
     </asp:Label>

     <telerik:RadComboBox ID="cboInitiatedBy" runat="server" Style="z-index: 106; left: 97px; 
        position: absolute; top: 60px;" autopostback="True" visible="true" 
        Skin="Vista"  Width="200px"  TabIndex="0" ExpandDirection="Up">
    </telerik:RadComboBox>

     <asp:Label ID="lblActionSelect" runat="server" Text="Action Select:" Visible="true" style="Position:absolute;left:15px;top:265px">
     </asp:Label>
     
     <asp:Label ID="lblRevisionMsg" runat="server" Visible="false" style="position:absolute;left:14px;top:230px;color:Red;font-weight:bold;width:310px;z-index:110" ></asp:Label>

    <telerik:RadComboBox ID="cboActionSelect" runat="server" Style="z-index: 105; left: 97px;
        position: absolute; top: 265px;" autopostback="True" visible="true" 
        Skin="Vista"  Width="200px"  TabIndex="0" ExpandDirection="Down">
    </telerik:RadComboBox>

     <!--<asp:Label ID="lblRFIReference" runat="server" Text="RFI Reference:" Visible="false" style="Position:absolute;left:13px;top:135px">
     </asp:Label>-->
     
     <asp:Label ID="lblDPSelect" runat="server" Text="DP Select:" Visible="false" style="Position:absolute;left:34px;top:165px">
     </asp:Label>

     <telerik:RadComboBox ID="cboDPSelect" runat="server" Style="z-index: 110; left: 97px; 
        position: absolute; top: 165px;" autopostback="False"  
        Skin="Vista"  Width="160px"  TabIndex="0" ExpandDirection="Down">
      </telerik:RadComboBox>

     <asp:Label ID="roDPSelect" runat="server" Text="" Visible="false" style="Position:absolute;left:97px;top:165px;font-weight:bold">
     </asp:Label>

     <asp:Label ID="lblSubject" runat="server" Text="Subject:" Visible="false" style="Position:absolute;left:45px;top:85px;z-index:50">
     </asp:Label>

     <asp:TextBox ID="txtSubject" Style="z-index: 50; left: 97px; position: absolute;resize:none;
        top: 85px; width: 220px;height:70px" runat="server" TabIndex="12" CssClass="EditDataDisplay"
        TextMode="MultiLine" visible="false"></asp:TextBox>

     <asp:Label ID="roSubject" runat="server" Text="" Visible="false" 
     style="Position:absolute;left:97px;top:85px;width:210px;height:68px;overflow:auto;background-color:#f2f5ff;padding:5px">
     </asp:Label>

     <asp:Label ID="lblHistory" Style="z-index: 116; left: 340px; position: absolute; top: 10px;
        width: 150px; font-weight: bold" runat="server" Height="24px" visible="false">RFI History:</asp:Label> 

      <asp:Label ID="roRFIDetail" Style="z-index: 116; left: 340px; position: absolute; top: 30px;
        width: 422px; font-weight: bold;background-color: #f2f5ff;padding:5px;overflow:auto" runat="server" Height="420px" visible="false"></asp:Label> 

     <!-- PCO and COR Stuff ------------------------------------------------------------------------ -->
    <asp:Panel id="IssuePanel" Style="position:absolute;top:28px" runat="server">
 
     <asp:Label ID="lblIssue" runat="server" Text="Issue/Explanation:" Visible="false" style="Position:absolute;left:340px;top:12px">
     </asp:Label>

     <asp:TextBox ID="txtIssue" Style="z-index: 50; left: 340px; position: absolute;
        top: 30px; height: 180px; width: 432px;resize:none" runat="server" TabIndex="12" CssClass="EditDataDisplay"
        TextMode="MultiLine" visible="false"></asp:TextBox>

     <asp:Label ID="roIssue" runat="server" Text="" Visible="false" 
        style="Position:absolute;left:340px;top:30px;height:167px;width:422px;background-color:  #f2f5ff;overflow:auto;padding:5px">
     </asp:Label>

     <asp:Label ID="lblIssueAttach" Style="z-index: 104; left: 525px; position: absolute; top: 212px;width:250px"
        runat="server" Height="24px" >Attachments (Count):</asp:Label>

     <asp:Label ID="issueAttachNum" Style="z-index: 104; left: 640px; position: absolute; top: 212px;font-weight:bold"
        runat="server" Height="24px" Visible="true" >0</asp:Label>

     <asp:ImageButton ID="butIssueAttach" Style="z-index: 104; left: 665px; position: absolute;
            top:212px" runat="server" 
            ImageUrl="images/button_upload_view.png" Visible="true">
    </asp:ImageButton>

    </asp:Panel>


     <asp:Label ID="lblResponse" runat="server" Text="Response:" Visible="false" style="Position:absolute;left:340px;top:298px">
      </asp:Label>

    <telerik:RadComboBox ID="cboResponses" runat="server" Style="z-index: 105; left: 415px; 
        position: absolute; top:292px;" autopostback="True" visible="false" 
        Skin="Vista"  Width="300px" TabIndex="0">
    </telerik:RadComboBox>

    <asp:Label ID="roCurrentResponse" runat="server" Text="" Visible="false" style="Position:absolute;left:415px;top:298px;">
      </asp:Label>

     <asp:Label ID="responseMsg" Visible="false" runat="server" style="position:absolute;top:260;left:340;color:red;word-wrap:break-word;font-weight:bold" ></asp:Label>

     <asp:TextBox ID="txtResponse" Style="z-index: 50; left: 340px; position: absolute;
        top: 318px; height: 100px; width: 432px;" runat="server" TabIndex="12" CssClass="EditDataDisplay"
        TextMode="MultiLine" visible="false"></asp:TextBox>

     <asp:Label ID="roResponse" runat="server" Text="" Visible="false" 
      style="Position:absolute;left:340px;top:318px;height:90px;width:422px;background-color:  #f2f5ff;overflow:auto;padding:5px">
     </asp:Label>


     <asp:Label ID="lblResponseAttachments" Style="z-index: 104; left: 525px; position: absolute; top: 418px"
        runat="server" Height="24px" >Attachments (Count):</asp:Label>

     <asp:Label ID="responseAttachNum" Style="z-index: 104; left: 640px; position: absolute; top: 418px;font-weight:bold"
        runat="server" Height="24px" Visible="true" >0</asp:Label>

   <asp:ImageButton ID="butResponseAttach" Style="z-index: 104; left: 665px; position: absolute;
            top:420px" runat="server" 
            ImageUrl="images/button_upload_view.png" Visible="true">
    </asp:ImageButton>



     <asp:Label ID="CoLine" Style="z-index: 10; left: 12px; position: absolute; top: 290px;width:300px;border-style:solid;border-width:1px;border-color:#bdbdbd"
        runat="server" Height="0px" Visible="true" ></asp:Label>



   <asp:ImageButton ID="butLeftPanelSelect" Style="z-index: 104; left: 5px; position: absolute;
            top:294px" runat="server" 
            ImageUrl="images/button_contract.png" Visible="true">
    </asp:ImageButton>

    <!-- --------------- Requested CO Amount -----------------------------------------------------------------------------------  -->
     <asp:Panel ID="CORequestAmountDateChange" runat="server" Visible="false" style="height:30px;width:300px;left:12px;top:294px;
                            position:absolute;background-color:none;border-style:solid;border-width:0px;z-index:100">

            <asp:Label ID="lblRequestedCOAmount" Style="z-index: 10; left: 79px; position: absolute; top: 2px"
                    runat="server" Height="24px" Visible="true" >Requested CO Amount:</asp:Label>

            <asp:TextBox ID="txtRequestedCOAmount" Style="z-index: 50; left: 210px; position: absolute;
                    top: 2px; height: 20px; width: 90px;" runat="server" TabIndex="12" CssClass="EditDataDisplay"
                    visible="true"></asp:TextBox>

            <asp:Label ID="roRequestedCOAmount" Style="z-index: 10; left: 210px; position: absolute; top: 2px;font-weight:bold"
                    runat="server" Height="24px" Visible="false" ></asp:Label>

      </asp:Panel> 
    <!-- ------------- PM, CM & District View Contract Items -------------------------------------------------------------------- -->
    <asp:Panel ID="ContractDetailPanel_A" runat="server" Visible="true" style="height:150px;width:300px;left:12px;top:320px;
                            position:absolute;background-color:none;border-style:solid;border-width:0px;z-index:100">

        
         <asp:Label ID="lblContractAmount" Style="z-index: 10; left: 0px; position: absolute; top: 2px"
            runat="server" Height="24px" Visible="true" >Original Contract(Including Allowance):</asp:Label>

         <asp:Label ID="roContractAmount" Style="z-index: 10; left: 210px; position: absolute; top: 2px;font-weight:bold"
            runat="server" Height="24px" Visible="true" ></asp:Label>

         <asp:Label ID="lblAllowance" Style="z-index: 10; left:27px; position: absolute; top: 17px"
            runat="server" Height="24px" Visible="true" >Contract Allowance(If Applicable):</asp:Label>

         <asp:Label ID="roContractAllowance" Style="z-index: 10; left: 210px; position: absolute; top: 17px;font-weight:bold"
            runat="server" Height="24px" Visible="true" ></asp:Label>

         <asp:Label ID="lblAllowanceSpent" Style="z-index: 10; left: 115px; position: absolute; top: 32px"
            runat="server" Height="24px" Visible="true" >Allowance Spent:</asp:Label>
        
         <asp:Label ID="roAllowanceSpent" Style="z-index: 10; left: 210px; position: absolute; top: 32px;font-weight:bold"
            runat="server" Height="24px" Visible="true" ></asp:Label>

        <asp:Label ID="lblAlowanceRemaining" Style="z-index: 10; left: 88px; position: absolute; top: 47px"
            runat="server" Height="24px" Visible="true" >Allowance Remaining:</asp:Label>
        
         <asp:Label ID="roAllowanceRemaining" Style="z-index: 10; left: 210px; position: absolute; top: 47px;font-weight:bold"
            runat="server" Height="24px" Visible="true" ></asp:Label>

        <asp:Label ID="lblAllowableAmendments" Style="z-index: 10; left: 20px; position: absolute; top: 62px;color:red"
            runat="server" Height="24px" Visible="true" >Allowable Amendments/COs(10%):</asp:Label>

         <asp:Label ID="roAllowableAmendments" Style="z-index: 10; left: 210px; position: absolute; top: 62px;font-weight:bold;color:red"
            runat="server" Height="24px" Visible="true" ></asp:Label>

        <asp:Label ID="lblProposedAmendments" Style="z-index: 10; left: 50px; position: absolute; top: 77px;color:red"
            runat="server" Height="24px" Visible="true" >Proposed Amendments/COs:</asp:Label>

         <asp:Label ID="roProposedAmendments" Style="z-index: 10; left: 210px; position: absolute; top: 77px;font-weight:bold;color:red"
            runat="server" Height="24px" Visible="true" ></asp:Label>

        <asp:Label ID="lblApprovedAmendments" Style="z-index: 10; left: 48px; position: absolute; top: 92px;color:red"
            runat="server" Height="24px" Visible="true" >Approved Amendments/COs:</asp:Label>

         <asp:Label ID="roApprovedAmendments" Style="z-index: 10; left: 210px; position: absolute; top: 92px;font-weight:bold;color:red"
            runat="server" Height="24px" Visible="true" ></asp:Label>

         <asp:Label ID="lblRemainingForCOs" Style="z-index: 10; left: 6px; position: absolute; top: 107px;color:red"
            runat="server" Height="24px" Visible="true" >Remaining Available for Amend/COs:</asp:Label>

         <asp:Label ID="roRemainingForCOs" Style="z-index: 10; left: 210px; position: absolute; top: 107px;font-weight:bold;color:red"
            runat="server" Height="24px" Visible="true" ></asp:Label>

         <asp:Label ID="lblRevisedContract" Style="z-index: 10; left: 35px; position: absolute; top: 122px"
            runat="server" Height="24px" Visible="true" >Total Revised Contract Amount:</asp:Label>

         <asp:Label ID="roRevisedContract" Style="z-index: 10; left: 210px; position: absolute; top: 122px;font-weight:bold"
            runat="server" Height="24px" Visible="true" ></asp:Label>



     </asp:Panel> 

    <!-- ----------- GC & DP View ----------------------------------------------------------------------------------------------------- -->
    <asp:Panel ID="ContractDetailPanel_B" runat="server" Visible="true" style="height:150px;width:300px;left:12px;top:320px;
                            position:absolute;background-color:none;border-style:solid;border-width:0px;z-index:100">

        <asp:Label ID="lblGCContractAmount" Style="z-index: 10; left: 0px; position: absolute; top: 2px"
            runat="server" Height="24px" Visible="true" >Original Contract(Including Allowance):</asp:Label>

         <asp:Label ID="roGCContractAmount" Style="z-index: 10; left: 210px; position: absolute; top: 2px;font-weight:bold"
            runat="server" Height="24px" Visible="true" ></asp:Label>

        <asp:Label ID="lblGCApprovedAmendments" Style="z-index: 10; left: 51px; position: absolute; top: 17px;color:red"
            runat="server" Height="24px" Visible="true" >Approved Amendments/COs:</asp:Label>

         <asp:Label ID="roGCApprovedAmendments" Style="z-index: 10; left: 210px; position: absolute; top: 17px;font-weight:bold;color:red"
            runat="server" Height="24px" Visible="true" ></asp:Label>

         <asp:Label ID="lblGCRevisedContract" Style="z-index: 10; left: 38px; position: absolute; top: 32px"
            runat="server" Height="24px" Visible="true" >Total Revised Contract Amount:</asp:Label>

         <asp:Label ID="roGCRevisedContract" Style="z-index: 10; left: 210px; position: absolute; top: 32px;font-weight:bold"
            runat="server" Height="24px" Visible="true" ></asp:Label>


    </asp:Panel> 


    <!-- ------------------------------------------------------------------------------------------------------------------------------ -->
    <asp:Panel ID="SelectedItemDetailPanel" runat="server" Visible="false" style="height:150px;width:300px;left:12px;top:312px;
                            position:absolute;background-color:none;border-style:solid;border-width:0px;z-index:100">
       
         <asp:Label ID="roItemsDisplay" Style="z-index:10;left:0px;position:absolute;top:2px;width:100%;height:100%"
            runat="server" Height="24px" Visible="true" ></asp:Label>
              
    </asp:Panel>
    <!-- ------------------------------------------------------------------------------------------------------------------------------ -->
        <asp:Panel ID="RFISelectPanel" runat="server" Visible="false" style="height:115px;width:235px;left:12px;top:325px;
                            position:absolute;background-color:transparent">

        <asp:Label ID="lblRFIItems" runat="server" Text="" Visible="True" style="width:200px;Position:absolute;left:5px;top:-8px">
            RFI References
        </asp:Label>

        <asp:Label ID="roRFIItems" runat="server" Text="" style="Position:absolute;left:5px;height:140px;width:140px;top:10px;border-style:solid;border-width:0px;font-weight:bold;overflow:auto">
      </asp:Label> 

        <telerik:RadComboBox ID="cboRFISelectSwitch" runat="server" Style="left:160px;width:130px;position:absolute;top:5px;" autopostback="True"  
            Skin="Vista" TabIndex="0">
             <Items>
            <telerik:RadComboBoxItem runat="server" Text="Add RFI" Value="Select" />
            <telerik:RadComboBoxItem runat="server" Text="Remove RFI" Value="Un-Select" />
        </Items>
        </telerik:RadComboBox>
            <!-- This is the RFI stuff to be moved -->

     <telerik:RadComboBox ID="cboRFIReference" runat="server" Style="z-index: 117; left: 160px; 
        position: absolute; top: 30px;" autopostback="True"  
        Skin="Vista"  Width="130px"  TabIndex="0" ExpandDirection="Down">
     </telerik:RadComboBox>

     <asp:ImageButton ID="butSelectRFI" Style="z-index: 100; left: 160px; position: absolute;
            top:70px" runat="server" 
            ImageUrl="images/button_select.png" Visible="false">
     </asp:ImageButton>

    
    
       

     <!--<asp:ImageButton ID="showRFI" Style="z-index: 115; left: 263px; position: absolute;
            top:137px" runat="server" 
            ImageUrl="images/button_small_view.png" Visible="false">
    </asp:ImageButton>-->

     <!-- ------------------------------- -->
                
    </asp:Panel>
    <!-- ------------------------------------------------------------------------------------------------------------------------------ -->
    <!--David D 6/9/17 error validation for text boxes is below and in configCoEdit, configNew, and both save/send button click events-->
    <asp:RequiredFieldValidator ID="TextBoxRequiredValidatorSubject" EnableClientScript="true"
        Display="Dynamic" ValidationGroup="TextFieldValidation" Style="z-index: 50; left: 38px;
        position: absolute; top: 135px;" ControlToValidate="txtSubject" ErrorMessage="Subject is required"
        Text="*" runat="server" />
    <asp:RequiredFieldValidator ID="TextBoxRequiredValidatorIssue" EnableClientScript="true"
        Display="Dynamic" ValidationGroup="TextFieldValidation" Style="z-index: 50; left: 333px;
        position: absolute; top: 10px;" ControlToValidate="txtIssue" ErrorMessage="Issue/Explanation is required"
        Text="*" runat="server" />
    <asp:RequiredFieldValidator ID="TextBoxRequiredValidatorResponse" EnableClientScript="true"
        Display="Dynamic" ValidationGroup="TextFieldValidation" Style="z-index: 50; left: 333px;
        position: absolute; top: 288px;" ControlToValidate="txtResponse" ErrorMessage="Response is required"
        Text="*" runat="server" />
    <asp:ValidationSummary ID="TextBoxRequiredValidatorSummary" EnableClientScript="true"
        ForeColor="red" BackColor="ControlLight" BorderColor="ControlLight" Width="250px"
        BorderStyle="Solid" BorderWidth="5px" runat="server" ValidationGroup="TextFieldValidation"
        Style="margin-top: 235px; margin-left: 425px;" HeaderText="Please complete the required fields to proceed:" />
    <asp:ValidationSummary ID="TextBoxRequiredValidatorSummaryCO" EnableClientScript="true"
        ForeColor="red" BackColor="ControlLight" BorderColor="ControlLight" Width="190px"
        BorderStyle="Solid" BorderWidth="5px" runat="server" ValidationGroup="TextFieldValidation"
        Style="margin-top: 300px; margin-left: 120px;" HeaderText="Please complete the required fields to proceed:" />
    <!--end error validation for text boxes-->
    <!-- ------------------------------------------------------------------------------------------------------------------------------ -->
    <!--added TextFieldValidation group and causesvalidation to true on butSave and butSend below-->
    <asp:ImageButton ID="butSave" ValidationGroup="TextFieldValidation" CausesValidation="false"
        Style="z-index: 50; left: 15px; position: absolute; top: 480px" TabIndex="99"
        runat="server" ImageUrl="images/button_save.png" Visible="false"></asp:ImageButton>
    <asp:ImageButton ID="butSend" ValidationGroup="TextFieldValidation" CausesValidation="true"
        Style="z-index: 50; left: 115px; position: absolute; top: 480px" TabIndex="99"
        runat="server" ImageUrl="images/button_send.png" Visible="false"></asp:ImageButton>
      <asp:ImageButton ID="butCancel" Style="z-index: 50; left: 215px; position: absolute;
            top:480px" TabIndex="99" runat="server" 
            ImageUrl="images/button_cancel.png" Visible="false">
         </asp:ImageButton>

       <asp:ImageButton ID="butCloseUpload" Style="z-index: 106; left: 675px; position: absolute;
            top:435px" TabIndex="99" runat="server" 
            ImageUrl="images/button_close.png" Visible="false">
         </asp:ImageButton>

    <asp:Label ID="ProgrammerData" runat="server" Text="" Visible="true" style="Position:absolute;left:350px;top:490px">
     </asp:Label>

    <asp:Label ID="HorizLine" runat="server" Text="" Visible="true" style="Position:absolute;left:328px;top:20px;
        border-style:solid;height:475px;border-width:1px;border-color:#bdbdbd">
     </asp:Label>

    </form>
</body>
</html>
