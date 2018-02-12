<%@ Page Language="vb" %>

<%@ Register Assembly="Telerik.Web.UI" Namespace="Telerik.Web.UI" TagPrefix="telerik" %>
<%@ Import Namespace="Prompt" %>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">
<script runat="server">
    Private nRFIID As Integer = 0
    Private nProjectID As Integer = 0
    Private nContractID As Integer = 0
    Private strPhysicalPath As String = ""
    Private sRefNum As String = ""
    Private Rev As Integer = 0
    Private Seq As Integer = 1
    Private nContactID As Integer = 0
    Private userName As String
    Private currentUser As Integer 'Swith with nContactID for development
    Private sType As String
    Private sUserType As String
    Private bNoRespond As Boolean
    Private parentID As Integer
    Private sContactType As String
    Private bClosed As Boolean
    Private isRFIPending As Boolean
    Private isPMtheCM As Integer = 0
    Private WorkFlowPosition As String = ""
    Private reqUpload As Boolean = False
    Private resUpload As Boolean = False
    Private nextID As Integer
    Private RFIType As String
    Private PMContactID As Integer 'PM of record from project table
    Private CMContactID As Integer 'CM from TeamMembers table
    Private sTitle As String
    Private sRequestStatus As String
    Private nReportID As Integer
    
    Private Sub Page_Load(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MyBase.Load
           
        Session("tempCheck") = Nothing
        If IsPostBack Then
            Session("txtAnswer") = txtAnswer.Text
            Session("txtProposed") = txtProposed.Text
            Session("txtQuestion") = txtQuestion.Text
        Else
            Session("txtAnswer") = ""
            Session("txtProposed") = ""
            Session("txtQuestion") = txtQuestion.Text
            Session("NewAnswer") = Nothing
        End If
        
        If Not IsPostBack Then
            sRequest.Value = ""
            sResponse.Value = ""
            Session("ValidationError") = Nothing
        Else
            sRequest.Value = txtQuestion.Text
            sResponse.Value = txtAnswer.Text
        End If
        
        If Session("ContactType") = "ProjectManager" Then
            Flag.Visible = True
        Else
            Flag.Visible = False
        End If
       
        butHelp.Visible = False
        
        cboTransmittedByID.Visible = False
        useDropdown.Visible = False
        
        ProcLib.CheckSession(Page)
        ProcLib.LoadPopupJscript(Page)
        
        Session("PageID") = "RFIEdit"
        lblMessage.Text = ""
       
        sType = Request.QueryString("EditType")
        
        Using db As New RFI
            nContactID = db.getContactID(Session("UserID"), Session("DistrictID"))
            If IsNothing(nContactID) Then
                butClose_Click()
            End If
            
        End Using

        If useDropdown.Checked = True Then 'this is for development
            userName = cboTransmittedByID.Text
            currentUser = cboTransmittedByID.SelectedValue
            preSets(currentUser)
            lblUserDisplay.Text = userName & " - " & currentUser
        Else
            userName = Session("UserName")
            currentUser = nContactID
            preSets(currentUser)
            lblUserDisplay.Text = userName & " - " & currentUser
        End If
        
        Using db As New RFI
            Dim thObj As Object = db.getCM(Request.QueryString("ProjectID"), Request.QueryString("ContractID"))
            Session("CMID") = thObj(0)
            Session("ContractorID") = thObj(1)
            If Session("CMID") = 0 Then isPMtheCM = True Else isPMtheCM = False ' gives pm cm privilages if no cm specified
            'If no CM is assigned in the "Project Overview" Session("CMID") = 0 and isPMtheCM = True
            Dim emailIDs As Object = db.getPMAndCMid(Request.QueryString("ProjectID"))
            CMContactID = emailIDs(0)
            PMContactID = emailIDs(1)
        End Using

        nContractID = Request.QueryString("ContractID")
        
        If sType = "New" Then
            sType = "New"
            sUserType = "Origin"
            Session("UserType") = "Origin"
            nProjectID = Request.QueryString("ProjectID")
            projectID.Value = nProjectID
            nContractID = Request.QueryString("ContractID")
            sRefNum = txtRefNumber.Text
            If sRefNum = "" Then
                'RefNum.Text = "New Ref Number:"
            End If
            configNew()
            cboTransmittedByID.Visible = False
            useDropdown.Visible = False
            'labelContractID.Text = Request.QueryString("ContractID")
        End If
        
        If sType = "Edit" Then
            nRFIID = Request.QueryString("RFIID")
            showPrint.Value = "Yes"
            
            Using db As New RFI
                Dim chkTbl As DataTable = db.checkForRevisionAnswers(nRFIID, 1)
                If chkTbl.Rows.Count > 0 Then
                    nReportID = 242 'Local VM
                    'nReportID = 267 'PromptCODQA
                Else
                    nReportID = 243 'Local VM
                    'nReportID = 266 'PromptCODQA
                End If
            End Using
            nProjectID = Request.QueryString("ProjectID")
            nContractID = Request.QueryString("ContractID")
            'labelContractID.Text = nContractID
            If IsPostBack Then
                Rev = multiQuestions.SelectedValue
                Try
                    Seq = multiAnswers.SelectedValue
                    If Seq = 0 Then Seq = 1
                Catch ex As Exception
                    Seq = 1
                End Try
            End If
            
            If Not IsPostBack Then
                Session("ConfigAns") = False
                Session("NewAnswer") = False
                getEditData()
                'Session("RtnFromEdit") = True
            End If
            
            'If Session("ContactType") <> "Design Professional" Then
            conflictID.Value = 0
            Session("RevisionPreparing") = False
            Dim sessionConflict As Boolean = False
            Select Case Trim(WorkFlowPosition)
                Case "CM:Distribution Pending"
                    sessionConflict = checkForSessionConflict()
                    Dim tbl As DataTable = Nothing
                    Using db As New RFI
                        tbl = db.checkForRevisionPreparing(nRFIID)
                        If tbl.Rows.Count > 0 Then Session("RevisionPreparing") = True
                    End Using
                Case "CM:Review Pending"
                    If Session("ContactType") <> "General Contractor" Then
                        sessionConflict = checkForSessionConflict()
                    End If
                Case "GC:Acceptance Pending"
                    If Session("ContactType") <> "Construction Manager" Then
                        sessionConflict = checkForSessionConflict()
                    End If
                Case "CM:Completion Pending"
                    If Session("ContactType") = "General Contractor" Or Session("ContactType") = "District" Then
                    Else
                        sessionConflict = checkForSessionConflict()
                    End If
                Case "DP:Response Pending"
                    If Session("ContactType") = "ProjectManager" Or Session("ContactType") = "Design Professional" Then
                        sessionConflict = checkForSessionConflict()
                    End If
                Case Else
                    sessionConflict = checkForSessionConflict()
            End Select
            Session("SessionConflict") = sessionConflict
            
            Select Case Trim(WorkFlowPosition)
                Case "DP:Response Pending"
                    If Session("ContactType") = "Design Professional" Then
                        setNewWorkflowStatus()
                    End If
                Case "GC:Acceptance Pending"
                    If Session("ContactType") = "General Contractor" Then
                        setNewWorkflowStatus()
                    End If
                    'David D 6/1/17 Updated below case to restrict NewWorkFlowStatus Change based on if the CM views the RFI or the PM does.
                Case "CM:Review Pending", "CM:Distribution Pending", "CM:Acceptance Pending", "CM:Completion Pending"
                    If Session("ContactType") = "Construction Manager" And isPMtheCM = False Then
                        setNewWorkflowStatus()
                    ElseIf Session("ContactType") = "ProjectManager" And isPMtheCM = True Then
                        setNewWorkflowStatus()
                    End If
            End Select
            If Session("ContactType") = "ProjectManager" Then
                If Not IsPostBack Then
                    chkAugment.Enabled = True
                End If
            Else
                chkAugment.Visible = False
            End If
            'If Not IsPostBack Then
            configEdit()
            'End If
        End If
                               
        'set up help button
        butHelp.Attributes.Add("onclick", "openPopup('help_view.aspx','pophelp',550,450,'yes');")
        butHelp.NavigateUrl = "#"
        
        'set up Flag button
        Flag.Attributes.Add("onclick", "openPopup('PM_flag_edit.aspx?ParentRecID=" & nRFIID & "&ParentRecType=RFI&BudgetItem=" & "" & "&RFIID=" & nRFIID & "','pophelp',550,450,'yes');")
        Flag.NavigateUrl = "#"
        Dim parentID As Integer = 0
        If nRFIID = 0 Then
            Using db As New RFI
                parentID = db.GetSuggestedNextRefNumber()
            End Using
        Else
            parentID = nRFIID
        End If
        
        If Not IsPostBack Then
            activeEditWFP.Value = False 'This value is used to determine if the "Select active revision" message shows
            Try
                Session("SequenceNum") = multiAnswers.SelectedValue
                If Session("SquenceNum") = "" Then Session("SequenceNum") = 1
            Catch
                Session("SequenceNum") = 1
            End Try
        End If
        
        printValidationMessage.Text = ""
        
        If Session("Error") = True Then
            Session("Error") = False
            'newAnswerButton_Click()
            ' Exit Sub
        End If
        
        If Not IsPostBack Then
            PrintRFI.NavigateUrl = "report_viewer.aspx?reportID=" & nReportID & "&RFIID=" & nRFIID
            
            
            Session("IsResponse") = False
           
            'fill the from/to fields
            Using db As New TeamMember
                
                With cboSubmittedToID
                    .DataValueField = "ContactID"
                    .DataTextField = "Name"
                    .DataSource = db.GetExistingMembersForDropDowns(nProjectID, "Design Professional", "Pending")
                    .DataBind()
                End With
                
                Try
                    With cboTransmittedByID
                        .DataValueField = "ContactID"
                        .DataTextField = "Name"
                        .DataSource = db.GetExistingMembersForDropDowns(nProjectID, "Design Professional", "Pending")
                        .DataBind()
                    End With
                Catch
                End Try
                Try
                    cboTransmittedByID.SelectedValue = currentUser
                Catch
                End Try
               
            End Using
            
            Using db As New RFI
                db.CallingPage = Page
                If nRFIID = 0 Then
                    butDelete.Visible = False
                    Flag.Visible = False
                    printLabel.Visible = False
                    'printRFI.Visible = False
                    'printRFIMessage.Visible = False
                    Session("newRFI") = "True"
                    numAns.Text = ""
                Else
                    Session("newRFI") = ""
                End If
                
                Try
                    'db.GetRFIForEdit(nRFIID)
                Catch
                End Try
                
                With cboContractID
                    .DataValueField = "ContractID"
                    .DataTextField = "ContractName"
                    If sType = "New" Then
                        .DataSource = db.getAddRFIContracts(nProjectID, Session("ContactType"), Session("ParentContactID"), currentUser)
                    ElseIf sType = "Edit" Then
                        .DataSource = db.getAllProjectContracts(nProjectID, True, Session("ContactType"), "RFIs")
                    End If
                    Try
                        .DataBind()
                    Catch ex As Exception
                    End Try
                End With
                   
                Dim tbl As DataTable = buildActionDropdown(Session("ContactType"), "")
                              
                With cboAcceptRevise
                    'David D 6/2/17 added Try to prevent server error for Project Manager
                    Try
                        .DataValueField = "Action"
                        .DataTextField = "ActionText"
                        .DataSource = tbl
                        .DataBind()
                    Catch ex As Exception
                    End Try
                End With
                
                cboContractID.OpenDropDownOnLoad = "True"
   
            End Using
            
            'fill in the answer dropdown
            If sType <> "New" Then
                updateQuestionDropdown(True)
                Try
                    updateAnswerDropdown()
                Catch ex As Exception
                End Try
            End If
 
        Else
            cboContractID.OpenDropDownOnLoad = "False"
            
        End If
        
        lblxRFIID.Text = nRFIID
        'RefNum.Text = txtRefNumber.Text
        
        If Not IsPostBack Then
            If Session("sessionConflict") <> True Then
                Try
                    If conflictID.Value <> nContactID Then
                        'If Session("ContactType") <> "Design Professional" Then
                        Select Case WorkFlowPosition
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
                            Case "CM:Acceptance Pending", "CM:Completion Pending"
                                If Session("ContactType") = "General Contractor" Or Session("ContactType") = "District" Then
                                Else
                                    recordSessionStart()
                                End If
                            Case "GC:Acceptance Pending"
                                If Session("ContactType") = "Construction Manager" Or Session("ContactType") = "District" Then
                                Else
                                    recordSessionStart()
                                End If
                            Case "DP:Response Pending"
                                If Session("ContactType") = "ProjectManager" Or Session("ContactType") = "Design Professional" Then
                                    recordSessionStart()
                                End If
                            Case Else
                        End Select
                        'End If
                    End If
                Catch ex As Exception
            End Try
            End If
        End If
        Using db As New RFI
            Dim obj As Object
            If Session("ContactType") = "ProjectManager" Then
                Session("Override") = 1
            Else
                Session("Override") = 0
            End If
            obj = db.configResponseSave(nRFIID, nContactID, Rev, Session("Override"))
            'testPlace.Value = "Save Type = " & obj(0) & " Sequence = " & obj(1) & " Is Answer " & obj(2) & " AnswerID: " & obj(4) & " Answer: " & obj(3)
        End Using
    End Sub
    
    Private Sub setNewWorkflowStatus()
        Using db As New RFI
            db.setNewWorkflowStatus(nRFIID)
        End Using
    End Sub
    
    Private Sub preSets(ContID As Integer)
        Using db As New RFI
            Dim ContactData As Object = db.getContactData(ContID, Session("DistrictID"))
            Session("ParentContactID") = ContactData(0)
            Session("ContactType") = ContactData(1)
        End Using
    End Sub
  
    Private Function checkForSessionConflict() As Boolean
        Dim checkRFI As Boolean = False
        Using db As New RFI
            Dim tbl As DataTable = db.checkForActiveRFISession(nRFIID, nContactID)
            'Session("timeSpan") = Nothing
            If tbl.Rows.Count > 0 Then
                Dim timeSpan As DateTime = tbl.Rows(0).Item("StartTime")
                Dim timeElapse As Integer = (DateTime.Now - timeSpan).TotalSeconds
               
                If timeElapse > 108000 Then
                    db.sessionEnd(nRFIID, "", tbl.Rows(0).Item("ContactID"))
                    recordSessionStart()
                Else
                    conflictID.Value = tbl.Rows(0).Item("ContactID")
                    If tbl.Rows(0).Item("ContactID") = nContactID Then
                        checkRFI = False
                    Else
                        checkRFI = True
                    End If
                End If
            Else
                checkRFI = False
                conflictID.Value = 0
            End If
        End Using
        Return checkRFI
    End Function
    
    Private Sub recordSessionStart()
        Dim sesID As String = Session.SessionID
        Using db As New RFI
            db.sessionStart(nContactID, nRFIID, WorkFlowPosition, Session.SessionID)
        End Using
    End Sub
    
    Private Sub QuestionAttachments_click() Handles QuestionAttachments.Click
        txtAnswer.Text = sResponse.Value
        If QuestionAttachments.ImageUrl = "images/button_upload_view.png" Then
            roRFIDetail.Visible = False
            lblHistory.Visible = False
            uploadPanel.Visible = True
            'butCloseUpload.Visible = True
            lblUploadPanel.Text = "Question Attachments:"
            uploadFrame1.Visible = True
            uploadFrame1.Attributes.Add("src", Session("QAttachments"))
            QuestionAttachments.ImageUrl = "images/button_show_history.png"
            QuestionAttachments.Width = 100
            ResponseAttachments.ImageUrl = "images/button_upload_view.png"
        ElseIf QuestionAttachments.ImageUrl = "images/button_show_history.png" Then
            uploadPanel.Visible = False
            'butCloseUpload.Visible = False
            roRFIDetail.Visible = True
            lblHistory.Visible = True
            QuestionAttachments.ImageUrl = "images/button_upload_view.png"
        End If
       
    End Sub
    
    Private Sub ResponseAttachments_click() Handles ResponseAttachments.Click
        txtAnswer.Text = sResponse.Value
        If ResponseAttachments.ImageUrl = "images/button_upload_view.png" Then
            lblHistory.Visible = False
            roRFIDetail.Visible = False
            uploadPanel.Visible = True
            'butCloseUpload.Visible = True
            lblUploadPanel.Text = "Response Attachments:"
            uploadFrame1.Visible = True
            uploadFrame1.Attributes.Add("src", Session("AnsAttachments"))
            ResponseAttachments.ImageUrl = "images/button_show_history.png"
            ResponseAttachments.Width = 100
            QuestionAttachments.ImageUrl = "images/button_upload_view.png"
        ElseIf ResponseAttachments.ImageUrl = "images/button_show_history.png" Then
            uploadPanel.Visible = False
            butCloseUpload.Visible = False
            roRFIDetail.Visible = True
            lblHistory.Visible = True
           ResponseAttachments.ImageUrl = "images/button_upload_view.png"
        End If
        
    End Sub
       
    Private Sub butCloseUpload_click() Handles butCloseUpload.Click
        uploadPanel.Visible = False
        butCloseUpload.Visible = False
        roRFIDetail.Visible = True
        lblHistory.Visible = True
    End Sub
    
    Private Sub updateRequestAttachment(Rev As Integer, parentID As Integer, isUpload As Boolean)
        Session("QAttachments") = "RFI_attachments_manage.aspx?ParentType=RFIQuestion&ParentID=" & parentID & "&ProjectID=" _
                                            & nProjectID & "&Revision=" & Rev & "&UserType=" & Session("UserType") & "&Type=" & sType & "&Closed=" _
                                            & Session("Closed") & "&Upload=" & isUpload
        uploadFrame1.Attributes.Add("src", Session("QAttachments"))
    End Sub
    
    Private Sub updateResponseAttachment(Seq As Integer, parentID As Integer, isUpload As Boolean)
        If Seq = 0 Then Seq = 1
        Session("AnsAttachments") = "RFI_attachments_manage.aspx?ParentType=RFIAnswer&ParentID=" & parentID & "&ProjectID=" _
                                             & nProjectID & "&Revision=" & Rev & "&UserType=" & Session("UserType") & "&Type=" & sType & "&Closed=" _
                                             & Session("Closed") & "&Seq=" & Seq & "&Upload=" & isUpload
        uploadFrame1.Attributes.Add("src", Session("AnsAttachments"))
    End Sub
    
    Private Sub getEditData()
       
        Using db As New RFI
            Dim rfiData As DataTable = Nothing
            Dim ansData As DataTable
            rfiData = db.getRFIData(nRFIID)
            Dim q As String = rfiData.Rows(0).Item("Question").ToString
            WorkFlowPosition = rfiData.Rows(0).Item("WFPosition").ToString
            RFIType = rfiData.Rows(0).Item("RFIType").ToString
            roQuestion.Text = q.Replace("~", "'")
            txtQuestion.Text = q.Replace("~", "'")
            
            Session("RefNumber") = Right(rfiData.Rows(0).Item("RefNumber"), 3)
            Session("ContractID") = rfiData.Rows(0).Item("ContractID")
            'sTitle = "RFI Number: " & Session("RefNumber") & "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Work Flow Position: " & WorkFlowPosition
            sTitle = "RFI Edit" & "&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;Work Flow Position - " & WorkFlowPosition
            roTransmittedByID.Text = rfiData.Rows(0).Item("FromName").ToString
           
            
            Dim chkData As DataTable
            chkData = db.getCheckBoxData(nRFIID)
            If chkData.Rows.Count > 0 Then
                CheckBox1.Checked = Convert.ToBoolean(chkData.Rows(0).Item("CIVIL"))
                CheckBox2.Checked = Convert.ToBoolean(chkData.Rows(0).Item("ARCH"))
                CheckBox3.Checked = Convert.ToBoolean(chkData.Rows(0).Item("STRUCT"))
                CheckBox4.Checked = Convert.ToBoolean(chkData.Rows(0).Item("PLUMBING"))
                CheckBox5.Checked = Convert.ToBoolean(chkData.Rows(0).Item("MECH"))
                CheckBox6.Checked = Convert.ToBoolean(chkData.Rows(0).Item("FP"))
                CheckBox7.Checked = Convert.ToBoolean(chkData.Rows(0).Item("ELECT"))
                CheckBox8.Checked = Convert.ToBoolean(chkData.Rows(0).Item("OTHER"))
                CheckBox9.Checked = Convert.ToBoolean(chkData.Rows(0).Item("NotShown"))
                CheckBox10.Checked = Convert.ToBoolean(chkData.Rows(0).Item("CoordProb"))
                CheckBox11.Checked = Convert.ToBoolean(chkData.Rows(0).Item("Interpretation"))
                CheckBox12.Checked = Convert.ToBoolean(chkData.Rows(0).Item("CostImpact"))
                CheckBox13.Checked = Convert.ToBoolean(chkData.Rows(0).Item("Conflict"))
                CheckBox14.Checked = Convert.ToBoolean(chkData.Rows(0).Item("TimeImpact"))
                OtherDescription.Text = chkData.Rows(0).Item("OtherDescription")
                       
                If Trim(chkData.Rows(0).Item("CIVIL")) = "True" Then CheckBox1.CssClass = "checkBox_bold"
                If Trim(chkData.Rows(0).Item("ARCH")) = "True" Then CheckBox2.CssClass = "checkBox_bold"
                If Trim(chkData.Rows(0).Item("STRUCT")) = "True" Then CheckBox3.CssClass = "checkBox_bold"
                If Trim(chkData.Rows(0).Item("PLUMBING")) = "True" Then CheckBox4.CssClass = "checkBox_bold"
                If Trim(chkData.Rows(0).Item("MECH")) = "True" Then CheckBox5.CssClass = "checkBox_bold"
                If Trim(chkData.Rows(0).Item("FP")) = "True" Then CheckBox6.CssClass = "checkBox_bold"
                If Trim(chkData.Rows(0).Item("ELECT")) = "True" Then CheckBox7.CssClass = "checkBox_bold"
                If Trim(chkData.Rows(0).Item("OTHER")) = "True" Then CheckBox8.CssClass = "checkBox_bold"
                If Trim(chkData.Rows(0).Item("NotShown")) = "True" Then CheckBox9.CssClass = "checkBox_bold"
                If Trim(chkData.Rows(0).Item("CoordProb")) = "True" Then CheckBox10.CssClass = "checkBox_bold"
                If Trim(chkData.Rows(0).Item("Interpretation")) = "True" Then CheckBox11.CssClass = "checkBox_bold"
                If Trim(chkData.Rows(0).Item("CostImpact")) = "True" Then CheckBox12.CssClass = "checkBox_bold"
                If Trim(chkData.Rows(0).Item("Conflict")) = "True" Then CheckBox13.CssClass = "checkBox_bold"
                If Trim(chkData.Rows(0).Item("TimeImpact")) = "True" Then CheckBox14.CssClass = "checkBox_bold"
            End If
            
            If CheckBox8.Checked = False Then
                OtherDescription.Text = ""
            End If
            
            roRFIDetail.Text = db.buildRFIQAndA(nRFIID, Session("ContactType"))
            
            activeRevision.Value = db.getActiveRFIRevision(nRFIID)
            
            If activeRevision.Value = 0 Then
                lblRFINum.Text = "RFI #: " & Session("RefNumber")
            Else
                lblRFINum.Text = "RFI #: " & Session("RefNumber") & " : Revision - " & activeRevision.Value
            End If
            
            If rfiData.Rows(0).Item("SubmittedToID") < 2 Then
                Session("isRFIPending") = True
                roReturnedOn.Text = ""
                roSubmittedToID.Text = "Pending"
            Else
                Session("isRFIPending") = False
                Dim submitName As String = db.getSubmittedTo(rfiData.Rows(0).Item("SubmittedToID"))
                roSubmittedToID.Visible = True
                cboSubmittedToID.Visible = False
                roSubmittedToID.Text = submitName
            End If
                 
            If rfiData.Rows(0).Item("WorkFlowPosition") = "None" Then
                cboSubmittedToID.SelectedValue = rfiData.Rows(0).Item("SubmittedToId")
            End If
            
            Session("SenderID") = rfiData.Rows(0).Item("TransmittedById")
            If rfiData.Rows(0).Item("Status") = "Closed" Then Session("Closed") = True Else Session("Closed") = False
            
            roReceivedOn.Text = FormatDateTime(rfiData.Rows(0).Item("ReceivedOn"), 2)
            roRequiredBy.Text = FormatDateTime(rfiData.Rows(0).Item("RequiredBy"), 2)
            txtRequiredBy.DbSelectedDate = rfiData.Rows(0).Item("RequiredBy")
            roProposed.Text = (rfiData.Rows(0).Item("Proposed")).Replace("~", "'")
            
            txtProposed.Text = (rfiData.Rows(0).Item("Proposed")).Replace("~", "'")
            
            txtAltRefNumber.Text = Trim(rfiData.Rows(0).Item("AltRefNumber"))
            
            Dim isShow As Boolean = configHideAnswer(Seq, Rev, rfiData.Rows(0).Item("RFIType"))
            Dim abbr As String = ""
            Try
                Dim contactData As Object = db.getContactData(rfiData.Rows(0).Item("RespondedBy"), Session("DistrictID"))
                abbr = " (" & getTypeAbbr(contactData(1)) & ")"
            Catch ex As Exception
            End Try
                      
            If rfiData.Rows(0).Item("Answer") <> "" Then
                If isShow = True Then
                    If Trim(rfiData.Rows(0).Item("ResponseStatus")) = "Canceled" Then
                        ansData = db.GetAnswersForRFI(nRFIID, Rev, False)
                        If ansData.Rows.Count > 0 Then
                            txtAnswer.Text = (ansData.Rows(0).Item("Answer")).replace("~", "'")
                        Else
                            txtAnswer.Text = ""
                        End If
                    Else
                        roAnswer.Text = (rfiData.Rows(0).Item("Answer")).Replace("~", "'")
                        txtAnswer.Text = (rfiData.Rows(0).Item("Answer")).Replace("~", "'")
                    End If
                Else
                    roAnswer.Text = "Response Pending"
                    txtAnswer.Text = "Response Pending"
                    hideResponseInfo()
                End If
               
                Try
                    roReturnedOn.Text = FormatDateTime(rfiData.Rows(0).Item("ReturnedOn"), 2)
                Catch
                End Try
                                              
                Try
                    roReturnedBy.Text = db.getReturnedBy(rfiData.Rows(0).Item("RespondedBy")) & abbr
                Catch
                End Try
            Else
                'roAnswer.Text = "No response for this request."
                roAnswer.Text = ""
                txtAnswer.Text = ""
            End If
            If Not IsPostBack Then
                Try
                    multiAnswers_Change()
                    'multiQuestions_Change()
                Catch ex As Exception
                End Try
            End If
        End Using
    End Sub
    
    Private Sub hideResponseInfo()
        lblRespondedOn.Visible = False
        lblReturnedBy.Visible = False
        roReturnedOn.Visible = False
        roReturnedBy.Visible = False
        lblResponseAttachments.Visible = False
        responseAttachNum.Visible = False
        
    End Sub
    
    Private Sub configCheckBoxes(switch As Boolean)
        If switch = False Then
            CheckBox1.Enabled = False
            CheckBox2.Enabled = False
            CheckBox3.Enabled = False
            CheckBox4.Enabled = False
            CheckBox5.Enabled = False
            CheckBox6.Enabled = False
            CheckBox7.Enabled = False
            CheckBox8.Enabled = False
            CheckBox9.Enabled = False
            CheckBox10.Enabled = False
            CheckBox11.Enabled = False
            CheckBox12.Enabled = False
            CheckBox13.Enabled = False
            CheckBox14.Enabled = False
            OtherDescription.Enabled = False
        ElseIf switch = True Then
            CheckBox1.Enabled = True
            CheckBox2.Enabled = True
            CheckBox3.Enabled = True
            CheckBox4.Enabled = True
            CheckBox5.Enabled = True
            CheckBox6.Enabled = True
            CheckBox7.Enabled = True
            CheckBox8.Enabled = True
            CheckBox9.Enabled = True
            CheckBox10.Enabled = True
            CheckBox11.Enabled = True
            CheckBox12.Enabled = True
            CheckBox13.Enabled = True
            CheckBox14.Enabled = True
            OtherDescription.Enabled = False 'David D was true set to False using JavaScript function EnableOtherDesc() and OnClick event in asp:CheckBox ID="CheckBox8" 5/23/17
        End If
        'David D 6/21/17 fixed "OTHER" checkbox and "OtherDescription" functionality with the below condition in addition to JavaScript
        If OtherDescription.Text <> String.Empty And cboAcceptRevise.SelectedValue <> "none" And cboAcceptRevise.Visible = True _
            And WorkFlowPosition <> "CM:Completion Pending" Then
            OtherDescription.Enabled = True
            'David D 6/22/17 added below condition for GC after create revision
        ElseIf OtherDescription.Text <> String.Empty And cboAcceptRevise.SelectedValue <> "none" _
            And cboAcceptRevise.Visible = False And Session("ContactType") = "General Contractor" _
            And WorkFlowPosition = "GC:Acceptance Pending" Then
            OtherDescription.Enabled = True
        End If
    End Sub
    
    Private Function getTypeAbbr(contactType As String) As String
        Dim abbr As String = ""
        Select Case contactType
            Case "General Contractor"
                abbr = "GC"
            Case "Construction Manager"
                abbr = "CM"
            Case "ProjectManager"
                abbr = "PM"
            Case "Design Professional"
                abbr = "DP"
            Case "District"
                abbr = "Dist"
        End Select
        
        Return abbr
    End Function
    
    Private Sub updateQuestionDropdown(load As Boolean)
        Using db As New RFI
            
            With multiQuestions
                .DataValueField = "Revision"
                .DataTextField = "Revision"
                .DataSource = db.getQuestionsForRFI(nRFIID, Session("ContactType"), WorkFlowPosition, nContactID)
                .DataBind()
            End With
            Dim tbl As DataTable = db.getQuestionsForRFI(nRFIID, Session("ContactType"), WorkFlowPosition, nContactID)
            Dim count As Integer = tbl.Rows.Count
           
            If count > 1 Then
                multiQuestions.Visible = True
                lblQuestion.Text = "Revision # "
                Dim confVw As Object = buildConfVwObject()
                multiQuestions.SelectedValue = confVw(0) - 1
                Rev = confVw(0) - 1
                multiQuestions_Change()
                updateAnswerDropdown()
                multiAnswers_Change()
                'lblMessage.Text = confVw(0) - 1
            Else
                multiQuestions.Visible = False
              
            End If
        End Using
    End Sub
    
    Private Sub updateAnswerDropdown()
        Dim Rev As Integer
        Try
            Rev = multiQuestions.SelectedValue
        Catch
            Rev = 0
        End Try
       
        Using db As New RFI
                
            With multiAnswers
                .DataValueField = "SequenceNum"
                .DataTextField = "SequenceNum"
                .DataSource = db.GetAnswersForRFI(nRFIID, Rev, False)
                Try
                    .DataBind()
                Catch ex As Exception
                End Try
            End With
            
            Dim tbl As DataTable = db.GetAnswersForRFI(nRFIID, Rev, False)
            Dim count As Integer = tbl.Rows.Count()
            
            If count > 1 Then
                multiAnswers.Visible = True
                Label10.Text = "Response # "
                If Not IsPostBack Then
                    getRevisionAnswers(multiAnswers.Items.Count, Rev)
                Else
                    getRevisionAnswers(multiAnswers.SelectedValue, Rev)
                End If
            Else
                multiAnswers.Visible = False
                Label10.Text = "Response # 1"
                If Not IsPostBack Then
                    getRevisionAnswers(1, Rev)
                End If
            End If
            'roAnswer.Text = multiAnswers.Items.Count            
        End Using
    End Sub
    
    Private Sub multiQuestions_Change() Handles multiQuestions.SelectedIndexChanged
        Dim confVw As Object = buildConfVwObject()
        configReadOnly(confVw)
        Dim Rev As Integer = multiQuestions.SelectedValue
        Seq = 1
        Try
            Dim Seq As Integer = multiAnswers.SelectedValue
            Seq = 1
        Catch ex As Exception
        End Try
        If Rev <> activeRevision.Value Then
            activeEditWFP.Value = False
        End If
         activeEditWFP.Value = False
        configEdit()
        getRevisionAnswers(Seq, Rev)
        txtAnswer.Text = ""
        roAnswer.Text = ""
        'cancelNewAnswer_Click()
        If WorkFlowPosition <> "Complete" Then
            If confVw(2) <> "Active" Then
                If activeEditWFP.Value = True Then 'This value is used to determine if the "Select active revision" message shows
                    lblMessage.Text = "Select active revision #" & activeRevision.Value & " to provide response."
                Else
                    lblMessage.Text = ""
                End If
            Else
                lblMessage.Text = ""
            End If
        End If
        
        If Rev > 0 Then
            getEditData()
            Using db As New RFI
                Dim tbl As DataTable = db.getRFIQuestion(nRFIID, Rev)
                txtQuestion.Text = (tbl.Rows(0).Item("Question")).Replace("~", "'")
                roQuestion.Text = (tbl.Rows(0).Item("Question")).Replace("~", "'")
                txtProposed.Text = (tbl.Rows(0).Item("Proposed")).Replace("~", "'")
                roProposed.Text = (tbl.Rows(0).Item("Proposed")).Replace("~", "'")
                txtReceivedOn.SelectedDate = tbl.Rows(0).Item("ResubmittedOn")
                roReceivedOn.Text = FormatDateTime(tbl.Rows(0).Item("ResubmittedOn"), 2)
                roRequiredBy.Text = tbl.Rows(0).Item("RequiredBy")
                txtRequiredBy.DbSelectedDate = tbl.Rows(0).Item("RequiredBy")
                
                Dim getName As String
                
                If tbl.Rows(0).Item("SubmittedToId") < 2 Then
                    bNoRespond = True
                    Session("isRFIPending") = True
                Else
                    bNoRespond = False
                    Session("isRFIPending") = False
                    getName = db.getSubmittedTo(tbl.Rows(0).Item("SubmittedToId"))
                    roSubmittedToID.Text = getName
                    roSubmittedToID.Visible = True
                    cboSubmittedToID.Visible = False
                End If
                getName = db.getSubmittedTo(tbl.Rows(0).Item("SubmittedByID"))
                roTransmittedByID.Text = getName
                If IsDBNull(tbl.Rows(0).Item("Answer")) = True Then
                    hideResponseInfo()
                    lblRespondedOn.Visible = True
                    lblReturnedBy.Visible = True
                End If
                
                If Trim(tbl.Rows(0).Item("RequestStatus")) = "Preparing" Then
                    hideResponseInfo()
                End If
            End Using
            getRevisionAnswers(Seq, Rev)
            multiQuestions.Visible = True
            lblQuestion.Text = "Revision # "
          
        Else
            getEditData()
        End If
        updateAnswerDropdown()
        Try
            refreshActionDropdown("")
        Catch ex As Exception
        End Try
        
        uploadFrame1.Attributes.Add("src", Session("QAttachments"))
    End Sub
    
    Private Sub multiAnswers_Change() Handles multiAnswers.SelectedIndexChanged
        Try
            Dim Seq As Integer = multiAnswers.SelectedValue
        Catch ex As Exception
        End Try
        Try
            Dim Rev As Integer = multiQuestions.SelectedValue
        Catch ex As Exception
        End Try
       
        getRevisionAnswers(Seq, Rev)
        If lblUploadPanel.Visible = True Then
            ResponseAttachments_click()
        End If
        configEdit()
    End Sub
  
    Private Function configHideAnswer(Seq As Integer, Rev As Integer, RFIType As String) As Boolean
        Dim isShow As Boolean = True
        Dim answerData As DataTable
        Dim requestStatus As String = ""
        Dim responseType As String = ""
        Dim responseStatus As String = ""
        
        Using db As New RFI
            answerData = db.getOriginalAnswer(nRFIID, Rev)
            Try
                requestStatus = answerData.Rows(0).Item("RequestStatus")
            Catch ex As Exception
            End Try
                  
            If Seq > 1 Then
                answerData = db.getRFIAnswer(nRFIID, Seq, Rev)
            End If
            
            Try
                responseType = answerData.Rows(0).Item("ResponseType")
                responseStatus = answerData.Rows(0).Item("ResponseStatus")
            Catch ex As Exception
            End Try
           
        End Using
     
        Select Case Session("ContactType")
            Case "ProjectManager"
                
            Case "General Contractor", "Design Professional", "District", "Construction Manager"
                Try
                    If Trim(requestStatus) = "Revision Override" Then
                        Dim stat As String
                        If Trim(responseStatus) = "Released" Then
                            'Commented out on 6-27-2017 by Scott. If requests are in "Revision Override", they should be visible.
                            If Session("ContactType") = "General Contractor" And WorkFlowPosition = "DP:Response Pending" Or WorkFlowPosition = "CM:Distribution Pending" Then
                                isShow = False
                            Else
                                isShow = True
                            End If
                            isShow = True
                        Else
                            If Rev = 0 Then
                                Using db As New RFI
                                    stat = db.CheckRFIAnswerData(nRFIID, Rev + 1)
                                    If Trim(stat) = "Released" Then
                                        isShow = True
                                    Else
                                        isShow = False
                                    End If
                                End Using
                            Else
                                isShow = False
                            End If
                        End If
                        isShow = True
                    Else
                        If Trim(answerData.Rows(0).Item("ResponseStatus")) = "Hold" And answerData.Rows(0).Item("ResponderID") = nContactID Then
                            Select Case WorkFlowPosition
                                Case "DP:Response Pending", "CM:Distribution Pending"
                                    If Session("ContactType") = "Design Professional" Or Session("ContactType") = "District" Then
                                        isShow = True
                                    Else
                                        isShow = False
                                    End If
                                Case Else
                                    If answerData.Rows(0).Item("ResponderID") = nContactID Then
                                        isShow = True
                                    Else
                                        isShow = False
                                    End If
                            End Select
                        Else
                            If requestStatus = "Active" Then
                                'If roStatus.Text = "GC:Acceptance Pending" Or roStatus.Text = "CM:Completion Pending" Or roStatus.Text = "CM:Review Pending" Then
                                If WorkFlowPosition = "GC:Acceptance Pending" Or WorkFlowPosition = "CM:Completion Pending" Or WorkFlowPosition = "CM:Review Pending" Then
                                    isShow = True
                                Else
                                    If RFIType = "CM" Then
                                        isShow = True
                                    Else
                                        If responseType = "DP-Solution" Or responseType = "CM-DPReleaseNote" Then
                                            If responseStatus.Trim() <> "Hold" Then
                                                If WorkFlowPosition = "CM:Distribution Pending" Or WorkFlowPosition = "DP:Response Pending" Then
                                                    If Session("ContactType") = "General Contractor" Then
                                                        isShow = False
                                                    Else
                                                        isShow = True
                                                    End If
                                                Else
                                                    isShow = True
                                                End If
                                            Else
                                                If Session("Contacttype") = "General Contractor" Then
                                                    isShow = False
                                                Else
                                                    isShow = True
                                                End If
                                            End If
                                        Else
                                            isShow = True
                                        End If
                                    End If
                                End If
                            Else
                                isShow = True
                            End If
                            'isShow = True
                        End If
                    End If
                    
                Catch ex As Exception
                End Try
                'Case "Design Professional"                
        End Select
        Return isShow
    End Function
    
    Private Sub getRevisionAnswers(ByVal Seq As Integer, ByVal Rev As Integer)
        
        Dim confVw As Object = buildConfVwObject()
        Dim abbr As String = ""
        Dim isShow As Boolean = configHideAnswer(Seq, Rev, confVw(7))
        
        If confVw(1) > 1 Then
            Label10.Text = "Response # "
            multiAnswers.Visible = True
        Else
            Label10.Text = "Response # 1"
        End If
        
        Dim count As Integer
        Dim rfiAns As DataTable
        Dim ansCount As Integer
        
        Using db As New RFI
            responseAttachNum.Text = db.countRFIAttachmentsNew(nRFIID, Rev, Seq, "Response")
        End Using
        
        Using db As New RFI
            rfiAns = db.getRFIAnswer(nRFIID, 2, Rev)
            ansCount = rfiAns.Rows.Count
            If ansCount > 0 Then
                'Seq = 2
            End If
        End Using         
        Select Case Seq
            Case 1 'this uses the answer in the RFIs table// Need to update this. Seq 1 could be in the Answer table
                Using db As New RFI
                   
                    rfiAns = db.getOriginalAnswer(nRFIID, Rev)
                    
                    If rfiAns.Rows.Count > 0 Then
                        If Trim(rfiAns.Rows(0).Item("ResponseStatus")) = "Canceled" Then
                            rfiAns = db.getRFIAnswer(nRFIID, 1, Rev)
                        End If
                    End If
                    
                    count = rfiAns.Rows.Count
                    Try
                        abbr = " (" & getTypeAbbr(rfiAns.Rows(0).Item("ContactType")) & ")"
                    Catch ex As Exception
                    End Try

                    If isShow = True Then
                        Try
                            If rfiAns.Rows(0).Item("Answer") <> "" Then
                                If rfiAns.Rows(0).Item("ResponseStatus") = "Canceled" Then
                                    roAnswer.Text = ""
                                    txtAnswer.Text = ""
                                Else
                                    roAnswer.Text = (rfiAns.Rows(0).Item("Answer")).Replace("~", "'")
                                    txtAnswer.Text = (rfiAns.Rows(0).Item("Answer")).Replace("~", "'")
                                End If
                            Else
                                roAnswer.Text = ""
                            End If
                        Catch ex As Exception
                            hideResponseInfo()
                            ResponseAttachments.Visible = False
                            txtAnswer.Visible = False
                            Label10.Visible = False
                        End Try
                    Else
                        roAnswer.Text = "Response Pending"
                        txtAnswer.Text = "Response Pending"
                        ResponseAttachments.Visible = False
                        responseAttachNum.Visible = False
                        hideResponseInfo()
                    End If
                    
                    If rfiAns.Rows.Count > 0 Then
                        Try
                            roReturnedOn.Text = FormatDateTime(rfiAns.Rows(0).Item("ReturnedOn"), 2)
                        Catch ex As Exception
                        End Try
                        roReturnedBy.Text = rfiAns.Rows(0).Item("name") & abbr
                        lblRespondedOn.Visible = True
                        lblReturnedBy.Visible = True
                    End If
                                       
                End Using
                updateAnswer.Visible = False
            Case Else
               
                Using db As New RFI
                    rfiAns = db.getRFIAnswer(nRFIID, Seq, Rev)
                    Try
                        Seq = rfiAns.Rows(0).Item("SequenceNum")
                        multiAnswers.SelectedValue = Seq
                    Catch ex As Exception
                        Seq = 1
                    End Try
                    
                    Try
                        abbr = " (" & getTypeAbbr(rfiAns.Rows(0).Item("ContactType")) & ")"
                    Catch ex As Exception
                    End Try
                    count = rfiAns.Rows.Count
                    Try
                        If isShow = True Then
                            txtAnswer.Text = (rfiAns.Rows(0).Item("Answer")).Replace("~", "'")
                            roAnswer.Text = (rfiAns.Rows(0).Item("Answer")).Replace("~", "'")
                        Else
                            roAnswer.Text = "Response Pending"
                            txtAnswer.Text = "Response Pending"
                            ResponseAttachments.Visible = False
                            responseAttachNum.Visible = False
                            lblResponseAttachments.Visible = False
                            hideResponseInfo()
                        End If
                    Catch
                    End Try
                    Try
                        roReturnedOn.Text = FormatDateTime(rfiAns.Rows(0).Item("ReturnedOn"), 2)
                        roReturnedBy.Text = rfiAns.Rows(0).Item("name") & abbr
                        lblRespondedOn.Visible = True
                        lblReturnedBy.Visible = True
                    Catch
                    End Try
                End Using
        End Select
        
        If count > 0 Then
            If count = 1 And Seq > 1 Then
                multiAnswers.Visible = True
            ElseIf ansCount = 0 Then
                multiAnswers.Visible = False
            Else
                'ultiAnswers.Visible = True
            End If
        Else
            multiAnswers.Visible = False
        End If
        If ansCount > 0 Then
            multiAnswers.Visible = True
        Else
            multiAnswers.Visible = False
            
        End If
    End Sub
    
    Private Sub newAnswerButton_Click() Handles newAnswerButton.Click
        Dim confVw As Object = buildConfVwObject()
        
        Try
            Rev = multiQuestions.SelectedValue
        Catch ex As Exception
            Rev = 0
        End Try
        
        Using db As New RFI
            Dim nextId As Integer = db.getNextRFIAnswerID(nRFIID, Rev)
            If Trim(confVw(4)) = "Hold" Then
                'nextId = nextId - 1
                
            End If
            Seq = nextId
            If Seq = 0 Then Seq = 1
            updateResponseAttachment(Seq, nRFIID, True)
            Label10.Text = "New Response #: " & nextId
        End Using
        'If Session("ConfigAns") <> True Then
        txtAnswer.Text = ""
        'End If
        cancelNewAnswer.Visible = False
        newAnswerButton.Visible = False
        multiAnswers.Visible = False
        'txtAnswer.BackColor = Color.Yellow
        txtAnswer.Focus()
        updateAnswer.Visible = False
        'showAllAnswers.Visible = False
        numAns.Visible = False
        txtAnswer.Visible = True
        roAnswer.Visible = False
        roReturnedOn.Visible = True
        roReturnedOn.Text = Today
        lblReturnedBy.Visible = False
        roReturnedBy.Visible = False
        ResponseAttachments.Visible = True
        lblResponseAttachments.Visible = True
        
        butSave.Visible = True
        Session("NewAnswer") = True
    End Sub
      
    Public Sub downloadFile(ByVal newFile As String)
            
        Dim targetFile As New System.IO.FileInfo(newFile)
        Response.Clear()
        Response.AddHeader("content-Disposition", "attachment; filename=" & targetFile.Name)
        Response.AddHeader("Content-Length", targetFile.Length.ToString())
        Response.ContentType = "application/octet-stream"
        Response.WriteFile(targetFile.FullName)
        Response.End()
            
    End Sub
    
    Public Sub printRFISingle() 'Handles printRFI.Click
        
        Using db As New OpenXML
            Dim dwnData As String = db.RFIPrint(nRFIID)
            Dim targetFile As New System.IO.FileInfo(dwnData)
           
            Response.Clear()
            Response.AddHeader("content-Disposition", "attachment; filename=" & targetFile.Name)
            Response.AddHeader("Content-Length", targetFile.Length.ToString())
            Response.ContentType = "application/octet-stream"
            Response.WriteFile(targetFile.FullName)
            Response.End()
            
            db.callbackDeleteFile(dwnData)
            
        End Using
    End Sub
    
    Public Sub ShowHideHistory_Click() Handles ShowHideHistory.Click
        If Session("ShowDetail") = True Then
            Session("ShowDetail") = False
            roRFIDetail.Visible = False
            ShowHideHistory.ImageUrl = "images/button_show_history.png"
        Else
            Session("ShowDetail") = True
            roRFIDetail.Visible = True
            cboAcceptRevise.Visible = False
            Using db As New RFI
                roRFIDetail.Text = db.buildRFIQAndA(nRFIID, Session("ContactType"))
            End Using
            ShowHideHistory.ImageUrl = "images/button_hide_History.png"
        End If
    End Sub
    
    Public Sub createRFInumber()
        If cboContractID.SelectedValue <> 0 Then
            Using db As New RFI
                Dim tbl As DataTable = db.countAllRFIs(nProjectID)
                Dim len As Integer = tbl.Rows.Count + 1
                Dim rTag As String = "00"
            
                If len > 99 Then
                    rTag = len
                ElseIf len > 9 Then
                    rTag = "0" & len
                ElseIf len < 10 Then
                    rTag = "00" & len
                End If
                    
                Dim sRefNum As String = "RFI-" & nProjectID & "-" & rTag
                txtRefNumber.Text = sRefNum
                refNumber.Value = sRefNum
                'nContractID = cboContractID.SelectedValue
            End Using
        Else
            QuestionAttachments.Visible = False
            txtRefNumber.Text = ""
            nContractID = 0
        End If
    End Sub
          
    Private Sub responseAction_Change() Handles cboAcceptRevise.TextChanged
        'butCloseUpload_click()
        uploadFrame1.Attributes.Add("src", Session("QAttachments"))
        uploadFrame1.Attributes.Add("src", Session("AnsAttachments"))
        Dim msg As String = ""
    End Sub
    
    Private Sub configNew()
        Session("Closed") = False
        PrintRFI.Visible = False 'David D 6/23/17 link was flickering on cboContractId toggle for a new RFI.
        If Rev > 0 Then
            lblQuestion.Text = "Revision # " & Rev
        Else
            lblQuestion.Text = "Original Question"
        End If
        txtQuestion.Visible = True
        roQuestion.Visible = False
        txtProposed.Visible = True
        roProposed.Visible = False
        txtAnswer.Visible = False
        roAnswer.Visible = False
        updateAnswer.Visible = False
        saveNewAnswer.Visible = False
        cancelNewAnswer.Visible = False
        'showAllAnswers.Visible = False
        multiAnswers.Visible = False
        Label10.Visible = False
        numAns.Visible = False
        newAnswerButton.Visible = False
        lblReturnedBy.Visible = False
        roReturnedOn.Visible = False
        roReturnedBy.Visible = False
        lblRespondedOn.Visible = False
        butClose.ImageUrl = "images\button_cancel.png"
        lblMessage.Text = ""
        QuestionAttachments.Visible = False
        lblQAttachments.Visible = False
        butSave.Visible = False
        butSend.Visible = False
        saveButton.Value = ""
        sendButton.Value = ""
        cboAcceptRevise.OpenDropDownOnLoad = False
        cboSubmittedToID.Visible = False
        responseAttachNum.Visible = False
        requestAttachNum.Visible = False
        ShowHideHistory.Visible = False
        conflictMessage.Visible = False
        uploadPanel.Visible = False
        checkBoxContainer.Visible = False
        roRFIDetail.Visible = False
        lblHistory.Visible = False
        chkAugment.Visible = False
        If Session("ContactType") = "General Contractor" Then
            Label7.Visible = False
            txtRequiredBy.Visible = False
        Else
            Label7.Visible = True
            txtRequiredBy.Visible = True
        End If
        Try
            If cboContractID.SelectedValue > 0 Then
                lblAcceptRevise.Visible = False
                cboAcceptRevise.Visible = False
                'If cboAcceptRevise.SelectedValue <> "none" Then
                lblQAttachments.Text = "Attachments (Count):"
                butSave.Visible = True
                butSave.ImageUrl = "images/button_create.gif"
                butSend.Visible = True
                'QuestionAttachments.Visible = True
                lblQAttachments.Visible = True
                If Session("ContactType") = "Construction Manager" Then
                    cboSubmittedToID.Visible = True
                    saveButton.Value = "CMSave"
                    sendButton.Value = "CMSaveSendDP"
                ElseIf Session("ContactType") = "ProjectManager" Then
                    cboSubmittedToID.Visible = True
                    saveButton.Value = "PMSave"
                    sendButton.Value = "PMSaveSendDP"
                ElseIf Session("ContactType") = "General Contractor" Then
                    saveButton.Value = "GCSave"
                    sendButton.Value = "GCSaveAndSendCM"
                End If
                cboSubmittedToID.AutoPostBack = False
            End If
        Catch ex As Exception
        End Try
        txtReceivedOn.Visible = False
        txtReceivedOn.DbSelectedDate = Today
        roReceivedOn.Visible = True
        roReceivedOn.Text = Today
        If Not IsPostBack Then
            txtRequiredBy.DbSelectedDate = Today.AddDays(7)
        End If

        Try
            cboTransmittedByID.SelectedValue = currentUser
        Catch
        End Try
           
        roTransmittedByID.Visible = True
        roTransmittedByID.Text = userName
        cboStatus.Visible = False
        If sType = "Edit" Then
            
        Else
            roSubmittedToID.Text = "Pending"
        End If
       
        roSubmittedToID.Visible = True
        ResponseAttachments.Visible = False
        responseAttachNum.Visible = False
        lblResponseAttachments.Visible = False
        multiQuestions.Visible = False
         
        Dim currentAction As String = cboAcceptRevise.SelectedValue
        Dim sendTo As String = ""
        
        Select Case Session("ContactType")
            Case "General Contractor"
                sendTo = "CM"
            Case "Construction Manager"
                sendTo = "DP"
        End Select
        
        Dim confirmTxt As String = "Continuing will create a new RFI. However, it will not be sent to the " & sendTo & " for review now.\n\n"
        confirmTxt &= "You will be able to edit and upload attachments to this RFI by accessing it from your dashboard.\n\n"
        confirmTxt &= " When completed, you can send this RFI to the " & sendTo & " for review.\n\n\n Do you wish to continue?"
        butSave.OnClientClick = "return confirm('" & confirmTxt & "')"
        'butSave.ImageUrl = "images/button_save.png"
        txtQuestion.Focus()
        Dim alertText As String = "Continuing will create a new RFI and send to the " & sendTo & " for review."
        alertText &= "\n\n\When created and sent, you will no longer be able to edit this RFI.\n\n\Do you want to continue?"
        butSend.OnClientClick = "return confirm('" & alertText & "')"
        butSend.ImageUrl = "images/button_Send.png"
         
        If cboAcceptRevise.SelectedValue = "GCSave" Then
        ElseIf cboAcceptRevise.SelectedValue = "GCSaveAndSendCM" Then
        End If
        
    End Sub
    
    Private Sub configEdit()
        QuestionAttachments.Visible = True
        lblQAttachments.Visible = True
        cboContractID.Visible = False
        lblRFINum.Visible = True
        txtQuestion.Visible = True 'David D Was False Changed to True to fix word wrap issue 5/23/17
        roQuestion.Visible = True
        txtProposed.Visible = True 'David D Was False Changed to True to fix word wrap issue 5/23/17
        roProposed.Visible = False 'David D Change to False  to fix word wrap issue 5/23/17
        roProposed.Enabled = False 'David D added  to fix word wrap issue 5/23/17
        Label10.Visible = True
        cboTransmittedByID.Visible = False
        roReceivedOn.Visible = True
        txtReceivedOn.Visible = False
        roRequiredBy.Visible = True
        txtRequiredBy.Visible = False
        cboStatus.Visible = False
        roAnswer.Visible = False 'David D Changed from True to False to fix word wrap issue 5/23/17
        roAnswer.Enabled = False 'David D added to fix word wrap issue 5/23/17
        txtAnswer.Visible = True 'David D added to fix word wrap issue 5/23/17
        'txtAnswer.Enabled = False 'David D added to fix word wrap issue 5/23/17
        numAns.Visible = True
        txtAnswer.Enabled = True 'David D added to fix word wrap in config read only  5/23/17
        lblRespondedOn.Visible = True
        lblReturnedBy.Visible = True
        roReturnedBy.Visible = True
        conflictMessage.Visible = False
        roTransmittedByID.Visible = True
        cboTransmittedByID.Visible = False
         
        butSave.Visible = True
        butDelete.Visible = False
        
        Dim confVw As Object = buildConfVwObject()
        
        'Below condition allows edit txtQuestion and txtProposed if New RFI Edit, but not for GC Revision David D 5/24/17
        If Session("ContactType") = "General Contractor" And cboAcceptRevise.SelectedValue <> "GCReleaseRFI" Then

            txtQuestion.Enabled = True 'David D added for Pathway#4 for GC only 5/24/17
            txtProposed.Enabled = True 'David D added for Pathway#4 for GC only 5/24/17
                
        End If
        
        Dim isShow As Boolean = configHideAnswer(Seq, Rev, confVw(7))
        If isShow = True Then
            responseAttachNum.Visible = True
        ElseIf isShow = False Then
            responseAttachNum.Visible = False
        End If
        
        requestAttachNum.Visible = True
             
        If Session("Closed") = True Then
            cboAcceptRevise.Visible = False
            lblAcceptRevise.Visible = False
        End If
                                                           
        If WorkFlowPosition = "" Then
            Using db As New RFI
                Dim tbl As DataTable = db.getRFIData(nRFIID)
                WorkFlowPosition = tbl.Rows(0).Item("WFPosition")
            End Using
        End If
                                                            
        Select Case Session("ContactType")
            Case "Construction Manager"
                configCM(confVw)
            Case "General Contractor"
                configGC(confVw)
            Case "Design Professional"
                configDP(confVw)
            Case "ProjectManager"
                configPM(confVw)
            Case "District"
                updateRequestAttachment(Rev, nRFIID, reqUpload)
                updateResponseAttachment(Seq, nRFIID, resUpload)
                configReadOnly(confVw)
                If Not IsPostBack Then
                    multiAnswers.SelectedValue = confVw(1)
                    Using db As New RFI
                        responseAttachNum.Text = db.countRFIAttachmentsNew(nRFIID, Rev, confVw(1), "Response")
                    End Using
                End If
            Case "Inspector Of Record"
                configReadOnly(confVw)
                updateRequestAttachment(Rev, nRFIID, reqUpload)
                updateResponseAttachment(Seq, nRFIID, resUpload)
        End Select
       
        If Not IsPostBack Then
            reqUpload = False
            resUpload = False
            multiAnswers.SelectedValue = confVw(1)
            Using db As New RFI
                requestAttachNum.Text = db.countRFIAttachmentsNew(nRFIID, Rev, Seq, "Request")
                responseAttachNum.Text = db.countRFIAttachmentsNew(nRFIID, Rev, Seq, "Response")
            End Using
            Try
                Seq = multiAnswers.SelectedValue
                If Seq = 0 Then Seq = 1
            Catch ex As Exception
                Seq = 1
            End Try
        End If
    End Sub
    
    Private Function buildConfVwObject() As Object
        Dim rowExists As Boolean
        Dim count As Integer
        Dim requestStatus As String = ""
        Dim responseStatus As String = ""
        Dim qcount As Integer 'number of questions/revisions
        Dim lastResponseAns As String = ""
        Dim lastResponseStatus As String = ""
        Dim rfiType As String = ""
        Dim showGC As Integer = 0
        Dim responseType As String = ""
        Dim responseBy As Integer
        Dim lastResponderID As Integer
        Dim ansRecId As Integer
        Dim BlaBla As String = ""
        
        ' If BlaBla = ";lkjlk;lj;lkjl;klj;" Then                    
            Using db As New RFI
            
                Dim rfiQue As DataTable = db.getQuestionsForRFI(nRFIID, Session("ContactType"), WorkFlowPosition, nContactID)
                        
                qcount = rfiQue.Rows.Count()
                If qcount > 1 Then
                    Try
                        Rev = multiQuestions.SelectedValue
                        multiQuestions.Visible = True
                    ' lblQuestion.Text = "Revision:"
                    Catch
                        Rev = 0
                        multiQuestions.Visible = False
                        'lblQuestion.Text = "Revision:"
                    End Try
                Else
                    Rev = 0
                    multiQuestions.Visible = False
                    'lblQuestion.Text = "Question:"
                End If
                Dim tbl As DataTable
                Try
                    tbl = db.GetAnswersForRFI(nRFIID, Rev, False)
                    count = tbl.Rows.Count()
                    lastResponseStatus = tbl.Rows(count - 1).Item("responseStatus")
                    lastResponseAns = tbl.Rows(count - 1).Item("Answer")
                    lastResponderID = tbl.Rows(count - 1).Item("ResponderID")
                    ansRecId = tbl.Rows(count - 1).Item("AnswerID")
                Catch ex As Exception
                    count = 0
                End Try
            
                Dim rfiData As DataTable = db.getRFIData(nRFIID)
           
                If Rev = 0 Then
                    If rfiData.Rows.Count > 0 Then
                        requestStatus = rfiData.Rows(0).Item("RequestStatus")
                        responseStatus = rfiData.Rows(0).Item("ResponseStatus")
                        responseType = rfiData.Rows(0).Item("ResponseType")
                        responseBy = rfiData.Rows(0).Item("TransmittedByID")
                    End If
               
                Else
                    requestStatus = rfiQue.Rows(Rev).Item("RequestStatus")
                    responseStatus = rfiQue.Rows(Rev).Item("ResponseStatus")
                    responseBy = rfiQue.Rows(Rev).Item("SubmittedByID")
                    responseType = rfiData.Rows(0).Item("ResponseType")
                End If
                Try
                
                Catch ex As Exception
                    rfiType = rfiData.Rows(0).Item("RFIType")
                End Try
                Try
                    showGC = rfiData.Rows(0).Item("CMShowToGC")
                Catch ex As Exception
                End Try
                     
                sRequestStatus = requestStatus
            
            If BlaBla = "lskjdflkjlkjf" Then
                If count > 1 Then 'There are multiple responses to the question  
                    'If count = 2 Then
                    'multiAnswers.Visible = False
                    'Label10.Text = "Response # 1"
                    'numAns.Text = ""
                    'Else
                    numAns.Text = "of " & count
                    Label10.Text = "Response #"
                    If Seq > 1 Then
                        Try
                            responseStatus = tbl.Rows(Seq - 1).Item("ResponseStatus")
                        Catch ex As Exception
                        End Try
                    End If
                    'multiAnswers.Visible = True ' this line makes the dd show in create view
                    'End If
               
                Else 'There are not multiple responses for this question
                    updateAnswer.Visible = False
                    multiAnswers.Visible = False
                    Label10.Text = "Response # 1"
                    numAns.Text = ""
                    Dim rfiAns As DataTable = db.getOriginalAnswer(nRFIID, Rev) 'Checking to see if an original response exists for this question                      
                    Try
                        Dim check As String = rfiAns.Rows(0).Item("Answer") 'check if there is a row
                        If rfiAns.Rows(0).Item("Answer") = "" Then
                            rowExists = False
                        Else
                            rowExists = True
                        End If
                    Catch
                        rowExists = False
                    End Try
                End If
            End If
        End Using
            'End If
        
            Dim confVw(14) As Object
            confVw(0) = qcount 'rows in rfiquestions table
            confVw(1) = count 'rows in answers table
            confVw(2) = requestStatus 'current requestStatus
            confVw(3) = rowExists 'original answer exists 
            confVw(4) = responseStatus 'current responseStatus
            confVw(5) = lastResponseStatus 'most recent response status
            confVw(6) = lastResponseAns 'most recent response answer 
            confVw(7) = rfiType 'RFIType either GC or CM
            confVw(8) = showGC 'Value of CMShowToGC
            confVw(9) = responseType 'ResponseType of most recent response
            confVw(10) = responseBy  'ownerID of the response or question
            If requestStatus = "Active" And qcount > Rev Then
                confVw(11) = True 'This indicates there is a revision preparing. Used to config action dropdown.
            End If
        confVw(12) = lastResponderID
        confVw(13) = ansRecId 'Answer record ID          
        'testPlace.Value = "0-" & confVw(0) & " 1- " & confVw(1) & " 2- " & confVw(2) & " 3- " & confVw(3) & " 4- " & confVw(4) & " 5- " & confVw(5) & " 10-" & confVw(12) & " - " & Session("ConfigAns")
        Return confVw
    End Function
    
    Private Function getSessionConflictData() As Object
        Dim obj(2) As Object
        Using db As New RFI
            Dim rfiConflict As DataTable = db.checkForActiveRFISession(nRFIID, nContactID)
            Try
                Dim name As String = db.getResponderName(rfiConflict.Rows(0).Item("ContactID"))
                obj(0) = name
                obj(1) = rfiConflict.Rows(0).Item("StartTime")
            Catch ex As Exception
                Session("sessionConflict") = False
                closeWindow()
            End Try
        End Using
        Return obj
    End Function
    
    Private Sub configCM(confVw As Object)
        cboSubmittedToID.Visible = False
        roSubmittedToID.Visible = True
        OtherDescription.Enabled = False 'David D added to disable onload JavaScript function will enable this box when "OTHER" CheckBox8 is clicked 5/25/17
        Dim alertText As String = ""
        Dim configResponseAttach As Boolean = False
        
        If Session("sessionConflict") = True Then
            Dim obj As Object = getSessionConflictData()
            activeEditWFP.Value = False 'This value is used to determine if the "Select active revision" message shows
        End If
        'cboSubmittedToID.AutoPostBack = False
        
        Select Case WorkFlowPosition
            Case "GC:Acceptance Pending"
                cboAcceptRevise.Visible = False
                activeEditWFP.Value = False 'This value is used to determine if the "Select active revision" message shows
            Case "CM:Review Pending"
                If Session("sessionConflict") = True Then
                    cboAcceptRevise.Visible = False
                    Using db As New RFI
                        Dim name As String = db.getResponderName(conflictID.Value)
                        conflictMessage.Visible = True
                        conflictMessage.Text = "Attention: User Conflict! " & name & " currently has this RFI open. Editing is not possible until it is closed."
                    End Using
                    activeEditWFP.Value = False 'This value is used to determine if the "Select active revision" message shows
                Else
                    cboSubmittedToID.Visible = True
                    conflictMessage.Visible = False
                    cboAcceptRevise.OpenDropDownOnLoad = False
                    cboAcceptRevise.Visible = True
                    If Not IsPostBack Then
                        multiAnswers.SelectedValue = confVw(1)
                    End If
                    configCheckBoxes(True)
                    activeEditWFP.Value = True 'This value is used to determine if the "Select active revision" message shows                  
                End If
            Case "CM:Distribution Pending", "CM:Acceptance Pending"
                'lblMessage.Text = cboAcceptRevise.SelectedValue
                If Session("sessionConflict") = True Then
                    cboAcceptRevise.Visible = False
                    activeEditWFP.Value = False 'This value is used to determine if the "Select active revision" message shows
                Else
                    cboAcceptRevise.Visible = True
                    configCheckBoxes(True)
                    QuestionAttachments.Visible = True
                    activeEditWFP.Value = True 'This value is used to determine if the "Select active revision" message shows
                End If
            Case "CM:Completion Pending"
                butSave.OnClientClick = "return confirm('This action will close this RFI and complete the work flow.\n\n\nDo you want to continue?')"
                If Session("ConfigAns") <> True Then
                    'Session("ConfigAns") = True
                End If
                cboAcceptRevise.Visible = True
                cancelNewAnswer.Visible = False
                resUpload = True
                cboAcceptRevise.OpenDropDownOnLoad = False
                txtAnswer.Focus()
                butSave.ImageUrl = "images/button_closeRFI.png"
                If Session("ContactType") = "ProgramManager" Then
                    saveButton.Value = "CMRFIClose"
                ElseIf Session("ContactType") = "Construction Manager" Then
                    saveButton.Value = "PMRFIClose"
                End If
                activeEditWFP.Value = True 'This value is used to determine if the "Select active revision" message shows
            Case "None"
                configRequestPrepare()
                If Session("ContactType") = "Construction Manager" Then
                    txtAltRefNumber.Visible = True
                    
                End If
                QuestionAttachments.Visible = True
                reqUpload = True
                cboAcceptRevise.Visible = False
                cboAcceptRevise.OpenDropDownOnLoad = False
                cboSubmittedToID.Visible = True
                If Session("ContactType") = "Construction Manager" Then
                    saveButton.Value = "CMSave"
                    sendButton.Value = "CMSaveSendDP"
                ElseIf Session("ContactType") = "ProjectManager" Then
                    saveButton.Value = "PMSave"
                    sendButton.Value = "PMSaveSendDP"
                End If
                butSave.Visible = True
                butSend.Visible = True
                butSave.ImageUrl = "images/button_save.png"
                butSend.ImageUrl = "images/button_send.png"
                alertText = "This will save your changes to this RFI."
                alertText &= "\n\n\Howerver, this will not send the RFI to the DP for further processing.\n\n\Do you want to continue?"
                butSave.OnClientClick = "return confirm('" & alertText & "')"
                alertText = "This action will assign this RFI to the selected DP as well as send it to the DP for response preparation."
                alertText &= "If you have not assigned a DP in the Assigned To dropdown, the RFI will not be assigned and any changes you have not saved will be lost."
                alertText &= "\n\n\Do you want to continue?"
                butSend.OnClientClick = "return confirm('" & alertText & "')"
                cboAcceptRevise.SelectedValue = "CMPrepare"
                'lblMessage.Text = cboAcceptRevise.SelectedValue & " - " & cboSubmittedToID.SelectedValue               
            Case "Complete"
                buildHiddenDropdown("", "")
                cboAcceptRevise.Visible = False
                If Not IsPostBack Then
                    multiAnswers.SelectedValue = confVw(1)
                    Using db As New RFI
                        responseAttachNum.Text = db.countRFIAttachmentsNew(nRFIID, Rev, confVw(1), "Response")
                    End Using
                End If
        End Select
        
        If Session("SessionConflict") = True Then
            cboAcceptRevise.Visible = False
            Using db As New RFI
                configReadOnly(confVw)
                Dim name As String = db.getResponderName(conflictID.Value)
                conflictMessage.Visible = True
                conflictMessage.Text = "Attention: User Conflict! " & name & " currently has this RFI open. Editing is not possible until it is closed."
                'roProposed.Text = conflictID.Value
                
            End Using
        Else
            Select Case (cboAcceptRevise.SelectedValue).Trim()
                Case "none", ""
                    If WorkFlowPosition <> "None" Then
                        'If WorkFlowPosition <> "CM:Review Pending" Then                                         
                        configReadOnly(confVw)
                        txtAltRefNumber.Enabled = False
                        resUpload = False
                        If confVw(2) = "Revision Override" Then
                            cboAcceptRevise.OpenDropDownOnLoad = False
                            cboAcceptRevise.Visible = False
                        Else
                            If Session("sessionConflict") = True Then
                                cboAcceptRevise.Visible = False
                                Using db As New RFI
                                    Dim name As String = db.getResponderName(conflictID.Value)
                                    conflictMessage.Visible = True
                                    conflictMessage.Text = "Attention: User Conflict! " & name & " currently has this RFI open. Editing is not possible until it is closed."
                                End Using
                            Else
                                conflictMessage.Visible = False
                                cboAcceptRevise.OpenDropDownOnLoad = False
                                cboAcceptRevise.Visible = True
                            End If
                        End If
                                       
                        If Session("RevisionPreparing") = True Then
                            If Session("ContactType") = "Construction Manager" Then
                                Using db As New RFI
                                    Dim tbl As DataTable = db.checkForRevisionPreparing(nRFIID)
                                    Try
                                        If tbl.Rows(0).Item("ContactType") = "ProjectManager" Then
                                            conflictMessage.Visible = True
                                            cboAcceptRevise.Visible = False
                                            conflictMessage.Text = "Attention: " & tbl.Rows(0).Item("Name") & " has a saved revision with a status of Preparing. Editing is not possible while this revision is pending."
                                        End If
                                    Catch ex As Exception
                                    End Try
                                End Using
                            End If
                        End If
                    
                        Session("ConfigAns") = False
                        'End If
                    End If
                    If WorkFlowPosition = "GC:Acceptance Pending" Then
                        cboAcceptRevise.Visible = False
                    ElseIf WorkFlowPosition = "DP:Response Pending" Then
                        cboAcceptRevise.Visible = False
                    End If
                    
                Case "CMPrepare", "CMEditSendRevisionDP", "PMEditSendRevisionDP", "PMPrepare"  ', "CMSave", "CMSaveSendDP"                             
                    configRequestPrepare()
                    If Session("ContactType") = "Construction Manager" Then
                        txtAltRefNumber.Enabled = True
                    Else
                        txtAltRefNumber.Enabled = False
                    End If
                    If cboAcceptRevise.SelectedValue = "CMEditSendRevisionDP" Then
                        cboSubmittedToID.Visible = False
                    Else
                        If confVw(0) = 0 Or Rev = 0 Then
                            cboSubmittedToID.Visible = True
                            roRequiredBy.Visible = False
                            txtRequiredBy.Visible = True
                        Else
                            cboSubmittedToID.Visible = False
                            roRequiredBy.Visible = False
                            txtRequiredBy.Visible = True
                        End If
                    End If
                    roRequiredBy.Visible = False
                    txtRequiredBy.Visible = True
                    'lblMessage.Text = cboAcceptRevise.SelectedValue & " - " & Rev
                    txtProposed.Enabled = True 'David D 5/26/17 enabled the Proposed Resolution for cboAcceptRevise.SelectedValue "CMEditSendRevisionDP", without this the CM could not edit the revision Proposed Resolution
                    reqUpload = True
                    cboAcceptRevise.Visible = False
                    cboAcceptRevise.OpenDropDownOnLoad = False
                    'txtProposed.Text = ""
                    roRFIDetail.Visible = False
                    lblHistory.Visible = False
                    uploadPanel.Visible = True
                    'butCloseUpload.Visible = False
                    lblUploadPanel.Text = "Question Attachments:"
                    uploadFrame1.Visible = True
                    'butCloseUpload.Visible = True
                    updateRequestAttachment(Rev, nRFIID, reqUpload)
                    uploadFrame1.Attributes.Add("src", Session("QAttachments"))
                    QuestionAttachments.Visible = False
                    'If cboAcceptRevise.SelectedValue = "CMEditSendRevisionDP" Or cboAcceptRevise.SelectedValue = "CMPrepare" Then
                    QuestionAttachments.Visible = True
                    uploadFrame1.Visible = False
                    roRFIDetail.Visible = True
                        
                    If Trim(cboAcceptRevise.SelectedValue) = "CMEditSendRevisionDP" Then
                        'cboAcceptRevise.Visible = True
                    End If
                    'End If
                    saveButton.Value = "CMPrepare"
                    sendButton.Value = "CMSaveReleaseDP"
                    butSave.Visible = True
                    butSend.Visible = True
                    butSave.ImageUrl = "images/button_save.png"
                    butSend.ImageUrl = "images/button_send.png"
                    alertText = "This will save your changes to this RFI."
                    alertText &= "\n\n\Howerver, this will not send the RFI to the DP for further processing.\n\n\Do you want to continue?"
                    butSave.OnClientClick = "return confirm('" & alertText & "')"
                    alertText = "This action will assign this RFI to the selected DP as well as \nsend it to the DP for response preparation.\n\n"
                    alertText &= "If you have not assigned a DP in the Assigned To dropdown, the \nRFI will not be assigned and any changes you have not saved will be lost."
                    alertText &= "\n\n\Do you want to continue?"
                    butSend.OnClientClick = "return confirm('" & alertText & "')"
                Case "CMEditResponseDP", "CMSaveResponse", "PMEditResponseDP", "PMSaveResponse"
                    resUpload = True
                    If Session("ContactType") = "Construction Manager" Then
                        txtAltRefNumber.Enabled = True
                    Else
                        txtAltRefNumber.Enabled = False
                    End If
                    cboAcceptRevise.OpenDropDownOnLoad = False
                    multiAnswers.SelectedValue = confVw(1)
                    alertText = "This option will save this response."
                    alertText &= "\n\n\Howerver, this will not send the RFI to the DP for further processing.\n\n\Do you want to continue?"
                    butSave.OnClientClick = "return confirm('" & alertText & "')"
                    alertText = "This action will send this RFI to the DP for response preparation."
                    alertText &= "\n\n\Do you want to continue?"
                    butSend.OnClientClick = "return confirm('" & alertText & "')"
                    configResponseAttach = True
                    Session("ConfigAns") = True
                    configResponseAlgorithm()
                    txtRequiredBy.Visible = True
                    roRequiredBy.Visible = False
                    multiQuestions.Visible = False
                    'lblQuestion.Text = "Revision: # " & Rev
                    butSave.Visible = True
                    butSend.Visible = True
                    butSave.ImageUrl = "images/button_save.png"
                    butSend.ImageUrl = "images/button_send.png"
                    If Session("ContactType") = "Construction Manager" Or isPMtheCM = True Then
                        saveButton.Value = "CMSaveResponse"
                        sendButton.Value = "CMAssignAndSendDP"
                    Else
                        saveButton.Value = "PMSaveResponse"
                        sendButton.Value = "PMAssignAndSendDP"
                    End If
                    updateResponseAttachment(Seq, nRFIID, True)
                    uploadFrame1.Attributes.Add("src", Session("AnsAttachments"))
                    cboSubmittedToID.Visible = False
                    configForResponseConflict("Edit")
                    uploadFrame1.Visible = True
                Case "CMAssignDP", "PMAssignDP"
                    If Session("ContactType") = "Construction Manager" Then
                        txtAltRefNumber.Enabled = True
                    Else
                        txtAltRefNumber.Enabled = False
                    End If
                    alertText = "This will assign the RFI to the selected DP."
                    alertText &= "\n\n\However, this will not send the RFI to the DP for further processing.\n\n\Do you want to continue?"
                    butSave.OnClientClick = "return confirm('" & alertText & "')"
                    alertText = "This action will assign this RFI to the selected DP as well as send it to the DP for response preparation."
                    alertText &= "\n\n\Do you want to continue?"
                    butSend.OnClientClick = "return confirm('" & alertText & "')"
                    'configResponse(confVw)
                    configResponseAlgorithm()
                    roRequiredBy.Visible = False
                    txtRequiredBy.Visible = True
                    multiQuestions.Visible = False
                    'lblQuestion.Text = "Revision: # " & Rev
                    resUpload = True
                    Session("ConfigAns") = True
                    cboSubmittedToID.Visible = True
                    roSubmittedToID.Visible = False
                    'cboSubmittedToID.OpenDropDownOnLoad = "True"
                    butSave.ImageUrl = "images/button_save.png"
                    butSend.Visible = True
                    butSend.ImageUrl = "images/button_send.png"
                    If cboSubmittedToID.SelectedValue = 0 Then
                        butSave.Visible = False
                        butSend.Visible = False
                        txtAnswer.Visible = False
                        lblRespondedOn.Visible = False
                        lblReturnedBy.Visible = False
                        roReturnedOn.Visible = False
                        roReturnedBy.Visible = False
                        responseAttachNum.Visible = False 'David D 5/30/17 added to prevent attachement count from showing until assigned (left a '0' floating at the bottom of the RFI_edit, this resolved it)
                        lblResponseAttachments.Visible = False
                        ResponseAttachments.Visible = False
                        Label10.Visible = False
                    End If
                    If Session("ContactType") = "Construction Manager" Or isPMtheCM = True Then
                        saveButton.Value = "CMAssignDP"
                        sendButton.Value = "CMAssignAndSendDP"
                    Else
                        saveButton.Value = "PMAssignDP"
                        sendButton.Value = "PMAssignAndSendDP"
                    End If
                Case "CMAssignAndSendDP", "PMAssignAndSendDP"
                    If Session("ContactType") = "Construction Manager" Then
                        txtAltRefNumber.Enabled = True
                    Else
                        txtAltRefNumber.Enabled = False
                    End If
                    'lblMessage.Text = "This RFI will be assigned to the selected DP and sent."
                    alertText = "This action will assign this RFI to the selected DP as well as send it to the DP for response preparation."
                    alertText &= "\n\n\Do you want to continue?"
                    butSave.OnClientClick = "return confirm('" & alertText & "')"
                    'configResponse(confVw)
                    configResponseAlgorithm()
                    cboSubmittedToID.Visible = True
                    roSubmittedToID.Visible = False
                    If confVw(3) = True Then
                        If Session("ConfigAns") <> True Then
                            'newAnswerButton_Click()
                            Session("ConfigAns") = True
                        End If
                    End If
                    'cboSubmittedToID.OpenDropDownOnLoad = "True"
                    butSave.ImageUrl = "images/button_send.png"
                
                    If Session("ContactType") = "Construction Manager" Or isPMtheCM = True Then
                        saveButton.Value = "CMAssignDP"
                        sendButton.Value = "CMAssignAndSendDP"
                    Else
                        saveButton.Value = "PMAssignDP"
                        sendButton.Value = "PMAssignAndSendDP"
                    End If
                Case "CMReleaseGC", "PMReleaseGC"
                    If Session("ContactType") = "Construction Manager" Then
                        txtAltRefNumber.Enabled = True
                    Else
                        txtAltRefNumber.Enabled = False
                    End If
                    butSave.OnClientClick = "return confirm('This action will send this RFI solution to the General Contractor for their review and acceptance.\n\nAny comments that you have entered will be saved.\n\nYou will no longer be able to edit the current comments.\n\n\nDo you want to continue?')"
                    configResponseAlgorithm()
       
                    If confVw(2) <> "Active" Then
                    Else
                        'roQuestion.Text = confVw(2)
                        multiQuestions.Visible = False
                        'lblQuestion.Text = "Revision: # " & Rev
                    End If
                
                    cboAcceptRevise.OpenDropDownOnLoad = False
                    Session("ConfigAns") = True
                    txtAnswer.Focus()
                    'txtAnswer.Text = ""
                    resUpload = True
                    butSave.ImageUrl = "images/button_send.png"
                    cancelNewAnswer.Visible = False
                    If Session("ContactType") = "Construction Manager" Or isPMtheCM = True Then
                        saveButton.Value = "CMReleaseGC"
                    Else
                        saveButton.Value = "PMReleaseGC"
                    End If
                    configForResponseConflict("Edit")
                Case "CMSendBackDP", "PMSendBackDP"
                    If Session("ContactType") = "Construction Manager" Then
                        txtAltRefNumber.Enabled = True
                    Else
                        txtAltRefNumber.Enabled = False
                    End If
                    Dim nextRev As Integer
                
                    configNew()
                    configRevision()
                    cboSubmittedToID.Visible = False
                    cboAcceptRevise.Visible = False
                    nextRev = getNextRevision() + 1
                    reqUpload = True
                    Rev = nextRev
                    If Session("ContactType") = "ProjectManager" Then
                        Using db As New RFI
                            Dim tbl As DataTable = db.checkForRevisionPreparing(nRFIID)
                            Dim chk As Integer = tbl.Rows.Count
                            If chk > 0 Then
                                'lblMessage.Text = "There is an existing revision"
                                Dim msg As String = "Attention! " & tbl.Rows(0).Item("name") & " has a saved revision in preperation "
                                msg &= "that will be canceled by creating a revision here. "
                                conflictMessage.Text = msg
                                conflictMessage.Visible = True
                            
                            End If
                        End Using
                    End If
                    lblQuestion.Text = "Revision # " & Rev
                    butSend.Visible = False
                    updateRequestAttachment(Rev, nRFIID, reqUpload)
                    QuestionAttachments_click()
                    QuestionAttachments.Visible = True
                    butCloseUpload.Visible = False
                    butSend.OnClientClick = "return confirm('This action will return this RFI to the Design Professional for further processing.\n\nAny comments that you have entered will be saved.\n\nYou will no longer be able to edit the current comments.\n\n\nDo you want to continue?')"
                    butSave.OnClientClick = "return confirm('This action will create and save a revision to this RFI.\n\nHowever, it will not be sent to the design professional at this time.\n\nYou will be able to edit and send the new revision at a later time.\n\n\nDo you want to continue?')"
                    cancelNewAnswer.Visible = False
                    butSave.ImageUrl = "images/button_create.gif"
                               
                    If Session("ContactType") = "Construction Manager" Or isPMtheCM = True Then
                        saveButton.Value = "CMCreateSaveRevisionDP"
                        sendButton.Value = "CMCreateSendRevisionDP"
                    Else
                        saveButton.Value = "PMCreateSaveRevisionDP"
                        sendButton.Value = "PMCreateSendRevisionDP"
                    End If
                    uploadPanel.Visible = False
                    PrintRFI.Visible = False
                    QuestionAttachments.Visible = False
                    butSave.Visible = True
                Case "CMReturnGC", "PMReturnGC"
                    If Session("ContactType") = "Construction Manager" Then
                        txtAltRefNumber.Enabled = True
                    Else
                        txtAltRefNumber.Enabled = False
                    End If
                    butSave.OnClientClick = "return confirm('This action will return this RFI back to the General Contractor for clarification or acceptance. Any comments that you have entered will be saved.\n\nThis will give the GC an option to accept or revise this RFI.\n\n\nDo you want to continue?')"
                    configResponseAlgorithm()
                    roRequiredBy.Visible = False
                    txtRequiredBy.Visible = True
                    resUpload = True
                    cboAcceptRevise.OpenDropDownOnLoad = False
                    Session("ConfigAns") = True
                    txtAnswer.Focus()
                    butSend.Visible = False
                    butSave.Visible = True
                    butSave.ImageUrl = "images/button_return.png"
                    cboSubmittedToID.SelectedValue = 0
                    multiQuestions.Visible = False
                    'lblQuestion.Text = "Revision: # " & Rev
                    If Session("ContactType") = "Construction Manager" Or isPMtheCM = True Then
                        saveButton.Value = "CMReturnGC"
                    Else
                        saveButton.Value = "PMReturnGC"
                    End If
                    cboSubmittedToID.Visible = False
                    configForResponseConflict("Edit")
                Case "CMReleaseDP", "PMReleaseDP"
                    If Session("ContactType") = "Construction Manager" Then
                        txtAltRefNumber.Enabled = True
                    Else
                        txtAltRefNumber.Enabled = False
                    End If
                    butSave.OnClientClick = "return confirm('This action will send this RFI to the assigned design professional for response preparation.\n\n\nDo you want to continue?')"
                    configResponseAlgorithm()
                    cboAcceptRevise.OpenDropDownOnLoad = False
                    txtAnswer.Focus()
                    butSave.ImageUrl = "images/button_send.png"
                
                    If Session("ContactType") = "Construction Manager" Or isPMtheCM = True Then
                        saveButton.Value = "CMReleaseDP"
                    Else
                        saveButton.Value = "PMReleaseDP"
                    End If
                Case "CMRFIClose", "PMRFIClose"
                    If Session("ContactType") = "Construction Manager" Then
                        txtAltRefNumber.Enabled = True
                    Else
                        txtAltRefNumber.Enabled = False
                    End If
                    butSave.OnClientClick = "return confirm('This action will close this RFI and complete the work flow.\n\n\nDo you want to continue?')"
                    configResponseAlgorithm()
                    configCheckBoxes(False) 'David D 6/22/17 added to prevent checkboxes edit during RFI Close 
                    multiQuestions.Visible = False
                    'lblQuestion.Text = "Revision: # " & Rev
                    Session("ConfigAns") = True
                    cancelNewAnswer.Visible = False
                    resUpload = True
                    cboAcceptRevise.OpenDropDownOnLoad = False
                    txtAnswer.Focus()
                    OtherDescription.Enabled = False 'David D 6/22/17 added to prevent OtherDescription edit during RFI Close 
                    butSave.ImageUrl = "images/button_closeRFI.png"
                
                    If Session("ContactType") = "Construction Manager" Or isPMtheCM = True Then
                        saveButton.Value = "CMRFIClose"
                    Else
                        saveButton.Value = "PMRFIClose"
                    End If
                Case "PMCloseOverride"
                    configResponseAlgorithm()
                    If Session("ContactType") = "Construction Manager" Then
                        txtAltRefNumber.Enabled = True
                    Else
                        txtAltRefNumber.Enabled = False
                    End If
                    If Session("ConfigAns") <> True Then
                        Session("ConfigAns") = True
                    End If
                    cboAcceptRevise.OpenDropDownOnLoad = False
                    multiQuestions.Visible = False
                    'lblQuestion.Text = "Revision: # " & Rev
                    txtAnswer.Focus()
                    butSave.ImageUrl = "images/button_closeRFI.png"
                    resUpload = True
                    cancelNewAnswer.Visible = False
                    butSave.OnClientClick = "return confirm('This action will close this RFI with no additional options to respond or revise.\n\nNo further actions will be allowed.\n\n\nDo you want to continue?')"
                    'lblMessage.Text = "This action will close this RFI and complete the work flow."
                    saveButton.Value = "PMCloseOverride"
                    configForResponseConflict("Edit")
                Case "CMShowToGC", "PMShowToGC"
                    If Session("ContactType") = "Construction Manager" Then
                        txtAltRefNumber.Enabled = True
                    Else
                        txtAltRefNumber.Enabled = False
                    End If
                    'David D 5/26/17 added below new block of code to handle CM Pathway #2 position [4]
                    'configResponse(confVw)
                    configResponseAlgorithm()
                    resUpload = True
                    cancelNewAnswer.Visible = False
                    multiQuestions.Visible = False
                    'lblQuestion.Text = "Revision: # " & Rev
                    txtAnswer.Focus()
                    'end of block of new code to handle CM Pathway #2 position [4]
                    butSave.OnClientClick = "return confirm('This action will send this RFI to the GC of record. The work flow will revert to GC:Acceptance Pending and follow regular order.\n\nDo you want to continue?')"
                    butSave.ImageUrl = "images/button_save.png"
                    'David D changed the below condition for PM override in CM Pathway #2 position [4]
                    If Session("ContactType") = "Construction Manager" Or isPMtheCM = True Then
                        saveButton.Value = "CMShowToGC"
                        sendButton.Value = "CMShowToGC"
                    Else
                        saveButton.Value = "PMShowToGC"
                        sendButton.Value = "PMShowToGC"
                    End If
                    butSave.ImageUrl = "images/button_send.png" 'David D 5/26/17 changed from gif to png
                Case "CMHideFromGC", "PMHideFromGC"
                    If Session("ContactType") = "Construction Manager" Then
                        txtAltRefNumber.Enabled = True
                    Else
                        txtAltRefNumber.Enabled = False
                    End If
                    butSave.OnClientClick = "return confirm('This action will hide this RFI from the GC of record.\n\nDo you want to continue?')"
                    cboAcceptRevise.OpenDropDownOnLoad = False
                    butSave.Visible = True
                    If Session("ContactType") = "Construction Manager" Then
                        saveButton.Value = "CMHideFromGC"
                    ElseIf Session("ContactType") = "ProjectManager" Then
                        saveButton.Value = "PMHideFromGC"
                    End If
                Case Else
                    configReadOnly(confVw)
            End Select
        End If
       
        updateRequestAttachment(Rev, nRFIID, reqUpload)
        If configResponseAttach = True Then
            updateResponseAttachment(confVw(1), nRFIID, resUpload)
        Else
            updateResponseAttachment(Seq, nRFIID, resUpload)
        End If
        uploadFrame1.Attributes.Add("src", Session("QAttachments"))
        uploadFrame1.Attributes.Add("src", Session("AnsAttachments")) 'David D 6/2/17 added so the different uploaded documents can be viewed based on the multiAnswer dropdown        
    End Sub
    
    Private Sub configPM(confVw As Object)
        Dim alertText As String
        If isPMtheCM = True Then
            configCM(confVw)
        Else
            configCM(confVw)
        End If
        If WorkFlowPosition <> "None" Then
            cboAcceptRevise.Visible = True
        End If
        'If WorkFlowPosition = "GC:Acceptance Pending" Then
        If Session("sessionConflict") = True Then
            activeEditWFP.Value = False 'This value is used to determine if the "Select active revision" message shows
            cboAcceptRevise.Visible = False
            Using db As New RFI
                Dim name As String = db.getResponderName(conflictID.Value)
                conflictMessage.Visible = True
                conflictMessage.Text = "Attention: User Conflict! " & name & " currently has this RFI open. Editing is not possible until it is closed."
            End Using
        Else
            activeEditWFP.Value = True 'This value is used to determine if the "Select active revision" message shows
            'conflictMessage.Visible = False
            cboAcceptRevise.OpenDropDownOnLoad = False
            'cboAcceptRevise.Visible=true                  
            Select Case Trim(WorkFlowPosition)
                Case "DP:Response Pending", "GC:Acceptance Pending", "CM:Distribution Pending", "CM:Completion Pending", "CM:Review Pending"
                    If WorkFlowPosition = "DP:Response Pending" Then
                        activeEditWFP.Value = True 'This value is used to determine if the "Select active revision" message shows            
                        saveButton.Value = "DPPrepare"
                        sendButton.Value = "DPReleaseCM"
                        butSave.OnClientClick = "return confirm('This action will save your response without sending to the CM for review.\n\nYou will be able to retrieve and edit as well as attach files.\n\n\nDo you want to continue?')"
                        'configReadOnly(confVw)
                        cboAcceptRevise.OpenDropDownOnLoad = False
                        If confVw(4) = "Hold" Then
                        Else
                            If Session("ConfigAns") <> True Then
                                'Session("ConfigAns") = True
                            End If
                        End If
                        resUpload = True
                        'reqUpload = False
                        'butSave.Visible = True
                        'butSend.Visible = True
                        cboAcceptRevise.Visible = True
                        cancelNewAnswer.Visible = False
                        butSave.ImageUrl = "images/button_save.png"
                        butSend.OnClientClick = "return confirm('This action will save any changes you have made and send your response to the CM for review.\n\nYou will not be able to edit this response once sent.\n\n\nDo you want to continue?')"
                        butSend.ImageUrl = "images/button_send.png"
                        butClose.ImageUrl = "images/button_cancel.png"
                    Else
                        activeEditWFP.Value = False 'This value is used to determine if the "Select active revision" message shows
                    End If
                    Select Case cboAcceptRevise.SelectedValue
                        Case ""
                            configReadOnly(confVw)
                            cboAcceptRevise.Visible = True
                        Case "none", ""
                            configReadOnly(confVw)
                            cboAcceptRevise.Visible = True
                            Session("ConfigAns") = False
                        Case "PMChangeDate"
                            txtRequiredBy.Visible = True
                            roRequiredBy.Visible = False
                            butSave.Visible = True
                            saveButton.Value = "PMSaveRequiredDate"
                            butSave.OnClientClick = "return confirm('This action will update the required by date of this RFI.\n\nThe edit window will not be close.\n\nUse the cancel button to close the edit window\n\n\nDo you want to continue?')"
                            butSave.ImageUrl = "images/button_save.png"
                        Case "DPPrepare"
                            configCheckBoxes(True)
                            butSave.OnClientClick = "return confirm('This action will save your response without sending to the CM for review.\n\nYou will be able to retrieve and edit as well as attach files.\n\n\nDo you want to continue?')"
                            Session("ConfigAns") = True
                            configResponseAlgorithm()
                            multiQuestions.Visible = False
                            'lblQuestion.Text = "Revision: # " & Rev
                            txtAnswer.Enabled = True
                            resUpload = True
                            reqUpload = False
                            butSave.Visible = True
                            butSend.Visible = True
                            cancelNewAnswer.Visible = False
                            butSave.ImageUrl = "images/button_save.png"
                            butSend.OnClientClick = "return confirm('This action will save any changes you have made and send your response to the CM for review.\n\nYou willw(10) not be able to edit this response once sent.\n\n\nDo you want to continue?')"
                            butSend.ImageUrl = "images/button_send.png"
                            butSend.Visible = True
                            cancelNewAnswer.Visible = False
                            saveButton.Value = "DPPrepare"
                            sendButton.Value = "DPReleaseCM"
                            configForResponseConflict("Edit")
                        Case "GCReleaseRFI"
                            alertText = "This action will accept the solution and send to the CM for final close. No other action will be required."
                            alertText &= "\n\n\Do you want to continue?"
                            butSave.OnClientClick = "return confirm('" & alertText & "')"
                            configResponseAlgorithm()
                            multiQuestions.Visible = False
                            'lblQuestion.Text = "Revision: # " & Rev
                            If Session("ConfigAns") <> True Then
                                Session("ConfigAns") = True
                            End If
                            butSave.ImageUrl = "images/button_accept.png"
                            resUpload = True
                            cancelNewAnswer.Visible = False
                            saveButton.Value = "GCReleaseRFI"
                            butSave.Visible = True
                            configForResponseConflict("Edit")
                    End Select
                Case "Complete"
                    cboAcceptRevise.Visible = False
            End Select
        End If
    End Sub
   
    Private Sub configDP(confVw As Object)
        txtAltRefNumber.Visible = True
        txtAltRefNumber.Enabled = False
        If Session("sessionConflict") = True Then
            configReadOnly(confVw)
            activeEditWFP.Value = False 'This value is used to determine if the "Select active revision" message shows
            cboAcceptRevise.Visible = False
            Using db As New RFI
                Dim name As String = db.getResponderName(conflictID.Value)
                conflictMessage.Visible = True
                conflictMessage.Text = "Attention: User Conflict! " & name & " currently has this RFI open. Editing is not possible until it is closed."
            End Using
        Else
            Dim configResponseAttach As Boolean = False
            If Not IsPostBack Then
                multiAnswers.SelectedValue = confVw(1)
                Using db As New RFI
                    responseAttachNum.Text = db.countRFIAttachmentsNew(nRFIID, Rev, confVw(1), "Response")
                End Using
            End If
            resUpload = False
            If WorkFlowPosition = "DP:Response Pending" Then
                activeEditWFP.Value = True 'This value is used to determine if the "Select active revision" message shows            
                saveButton.Value = "DPPrepare"
                sendButton.Value = "DPReleaseCM"
                butSave.OnClientClick = "return confirm('This action will save your response without sending to the CM for review.\n\nYou will be able to retrieve and edit as well as attach files.\n\n\nDo you want to continue?')"
                cboAcceptRevise.OpenDropDownOnLoad = False
                If confVw(4) = "Hold" Then
                Else
                    If Session("ConfigAns") <> True Then
                        'Session("ConfigAns") = True
                    End If
                End If
                resUpload = True
                butSave.Visible = True
                cboAcceptRevise.Visible = True
                cancelNewAnswer.Visible = False
                butSave.ImageUrl = "images/button_save.png"
                butSend.OnClientClick = "return confirm('This action will save any changes you have made and send your response to the CM for review.\n\nYou will not be able to edit this response once sent.\n\n\nDo you want to continue?')"
                butSend.ImageUrl = "images/button_send.png"
                butSend.Visible = True
                butClose.ImageUrl = "images/button_cancel.png"
            Else
                activeEditWFP.Value = False 'This value is used to determine if the "Select active revision" message shows
                cboAcceptRevise.Visible = False
            End If
            If WorkFlowPosition = "DP:Response Pending" Then
                Select Case cboAcceptRevise.SelectedValue
                    Case "none", ""
                        'configResponse(confVw) 'David D 6/23/17 removed, this was causing question and response to be blank on toggle multiquestion/answer dropdowns
                        configReadOnly(confVw)
                        cboAcceptRevise.Visible = True
                        'updateResponseAttachment(confVw(1), nRFIID, False)                
                        Session("ConfigAns") = False
                        cboAcceptRevise.OpenDropDownOnLoad = False
                        resUpload = False
                        reqUpload = False
                        Session("DPPrepare") = False
                        If confVw(1) > 2 Then
                            Seq = multiAnswers.SelectedValue
                            If Seq = 0 Then Seq = 1
                        End If
 
                        If WorkFlowPosition <> "DP:Response Pending" Then
                            'cboAcceptRevise.Visible = False
                        Else
                            Using db As New RFI
                                responseAttachNum.Text = db.countRFIAttachmentsNew(nRFIID, Rev, confVw(1), "Response")
                                If ResponseAttachments.Visible = True Then
                                    responseAttachNum.Visible = True
                                End If
                            End Using
                        End If
                    Case "DPPrepare"
                        configCheckBoxes(True)
                        butSave.OnClientClick = "return confirm('This action will save your response without sending to the CM for review.\n\nYou will be able to retrieve and edit as well as attach files.\n\n\nDo you want to continue?')"
                        Session("ConfigAns") = True
                        configResponseAlgorithm()
                        multiQuestions.Visible = False
                        'lblQuestion.Text = "Revision: # " & Rev
                        resUpload = True
                        reqUpload = False
                        butSave.Visible = True
                        cancelNewAnswer.Visible = False
                        butSave.ImageUrl = "images/button_save.png"
                        butSend.OnClientClick = "return confirm('This action will save any changes you have made and send your response to the CM for review.\n\nYou will not be able to edit this response once sent.\n\n\nDo you want to continue?')"
                        butSend.ImageUrl = "images/button_send.png"
                        butSend.Visible = True
                        cancelNewAnswer.Visible = False
                        saveButton.Value = "DPPrepare"
                        sendButton.Value = "DPReleaseCM"
                        configForResponseConflict("Edit")
                    Case "DPReleaseCMxxxxx" 'This selection can be removed.
                        butSave.OnClientClick = "return confirm('This action will save any changes you have made and send your response to the CM for review.\n\nYou will not be able to edit this response once sent.\n\n\nDo you want to continue?')"
                        configResponseAlgorithm()
                        If Session("ConfigAns") <> True Then
                            Session("ConfigAns") = True
                        End If
                        butSave.ImageUrl = "images/button_send.png"
                        resUpload = True
                        butSave.Visible = True
                        cancelNewAnswer.Visible = False
                        reqUpload = False
                    Case Else
                        configReadOnly(confVw)
                End Select
            Else
                 configReadOnly(confVw)
            End If
            updateRequestAttachment(Rev, nRFIID, reqUpload)
            'If Not IsPostBack Or cboAcceptRevise.SelectedValue = "DPPrepare" Then
            If configResponseAttach = True Then
                updateResponseAttachment(confVw(1), nRFIID, resUpload)
            Else
                updateResponseAttachment(Seq, nRFIID, resUpload)
            End If
            uploadFrame1.Attributes.Add("src", Session("QAttachments"))
            uploadFrame1.Attributes.Add("src", Session("AnsAttachments")) 'David D 6/2/17 added so the different uploaded documents can be viewed based on the multiAnswer dropdown
            End If
    End Sub
            
    Private Sub configGC(confVw As Object)
        'cboAcceptRevise.SelectedValue = "none"
        cboSubmittedToID.Visible = False
        roSubmittedToID.Visible = True
        Dim nextRev As Integer
        Dim alertText As String = ""
        Dim msgText As String = ""

        Select Case WorkFlowPosition
            Case "None"
                configCheckBoxes(True)
                configRequestPrepare()
                Label7.Visible = False
                txtRequiredBy.Visible = False
                cboAcceptRevise.SelectedValue = "GCPrepare"
                ShowHideHistory.Visible = False
                cboAcceptRevise.Visible = False
                txtAltRefNumber.Enabled = True
                txtAltRefNumber.Visible = True
                butSave.Visible = True
                butSend.Visible = True
                saveButton.Value = "GCPrepare"
                sendButton.Value = "GCReleaseCM"
            
                alertText = "This action will update your RFI. You will be able to access for editing in the future.\n\n\Do you want to continue?"
                butSave.OnClientClick = "return confirm('" & alertText & "')"
                reqUpload = True
                butSave.ImageUrl = "images/button_save.png"

                alertText = "This action will update your RFI and send to the CM for further processing."
                alertText &= "\n\n\When sent, you will no longer be able to edit this RFI.\n\n\Do you want to continue?"
                butSend.OnClientClick = "return confirm('" & alertText & "')"
                reqUpload = True
                butSend.ImageUrl = "images/button_send.png"
                multiAnswers.Visible = False
                txtRequiredBy.Visible = False
            Case "CM:Review Pending", "DP:Response Pending", "CM:Completion Pending", "CM:Acceptance Pending", "CM:Distribution Pending", "Complete"
                configReadOnly(confVw)
                activeEditWFP.Value = False 'This value is used to determine if the "Select active revision" message shows
            Case "GC:Acceptance Pending"
                If Session("sessionConflict") = True Then
                    cboAcceptRevise.Visible = False
                    activeEditWFP.Value = False 'This value is used to determine if the "Select active revision" message shows
                    Using db As New RFI
                        Dim name As String = db.getResponderName(conflictID.Value)
                        conflictMessage.Visible = True
                        conflictMessage.Text = "Attention: User Conflict! " & name & " currently has this RFI open. Editing is not possible until it is closed."
                    End Using
                Else
                    cboAcceptRevise.Visible = True
                    activeEditWFP.Value = True 'This value is used to determine if the "Select active revision" message shows
                End If
                cboAcceptRevise.OpenDropDownOnLoad = False 'David D 6/2/17 added to show dropdown after clicking "Create" for Revision
            Case "Complete"
                If Not IsPostBack Then
                    multiAnswers.SelectedValue = confVw(1)
                    Using db As New RFI
                        responseAttachNum.Text = db.countRFIAttachmentsNew(nRFIID, Rev, confVw(1), "Response")
                    End Using
                End If
        End Select
        txtQuestion.Focus()
        Select Case cboAcceptRevise.SelectedValue
            Case "none", ""
                If WorkFlowPosition <> "None" Or cboAcceptRevise.SelectedValue = "" Then
                    configReadOnly(confVw)
                    testPlace.Value = "you are here"
                    cboAcceptRevise.Visible = False
                End If
                If WorkFlowPosition = "CM:Review Pending" Then
                    cboAcceptRevise.Visible = False
                ElseIf WorkFlowPosition = "DP:Response Pending" Then
                    cboAcceptRevise.Visible = False
                ElseIf WorkFlowPosition = "CM:Distribution Pending" Then
                    cboAcceptRevise.Visible = False
                ElseIf WorkFlowPosition = "GC:Acceptance Pending" Then
                    If Session("sessionConflict") = True Then
                        cboAcceptRevise.Visible = False
                        Using db As New RFI
                            Dim name As String = db.getResponderName(conflictID.Value)
                            conflictMessage.Visible = True
                            conflictMessage.Text = "Attention: User Conflict! " & name & " currently has this RFI open. Editing is not possible until it is closed."
                        End Using
                    Else
                        If Trim(WorkFlowPosition) = "None" Then
                            cboAcceptRevise.Visible = False
                        Else
                            Using db As New RFI
                                Dim obj(2) As Object
                                Try
                                    obj = db.checkForActiveRevision(nRFIID, multiQuestions.SelectedValue)
                                Catch ex As Exception
                                    obj(0) = "Active"
                                End Try
                                If obj(0) = "Active" Then
                                    cboAcceptRevise.Visible = True
                                    cboAcceptRevise.OpenDropDownOnLoad = False
                                Else
                                    If obj(0) = "Preparing" Then
                                        cboAcceptRevise.Visible = True
                                    Else
                                        cboAcceptRevise.Visible = False
                                    End If
                                End If
                            End Using
                        End If
                    End If
                End If
                Session("ConfigAns") = False
                If Not IsPostBack Then
                    multiAnswers.SelectedValue = confVw(1)
                    Using db As New RFI
                        responseAttachNum.Text = db.countRFIAttachmentsNew(nRFIID, Rev, confVw(1), "Response")
                    End Using
                End If
            Case "GCSave"
                             
            Case "GCReleaseCM"
                lblMessage.Text = "This action will save any changes and send to the CM for processing."
                alertText = "This action will update your RFI and send to the CM for further processing."
                alertText &= "\n\n\When sent, you will no longer be able to edit this RFI.\n\n\Do you want to continue?"
                butSave.OnClientClick = "return confirm('" & alertText & "')"
                configRequestPrepare()
                reqUpload = True
                butSave.ImageUrl = "images/button_send.png"
            Case "GCPrepare"
                alertText = "This action will update your RFI. You will be able to access for editing in the future.\n\n\Do you want to continue?"
                butSave.OnClientClick = "return confirm('" & alertText & "')"
                alertText = "This action will update your RFI and send to the CM for further processing."
                alertText &= "\n\n\When sent, you will no longer be able to edit this RFI.\n\n\Do you want to continue?"
                butSend.OnClientClick = "return confirm('" & alertText & "')"
                configRequestPrepare()
                cboAcceptRevise.Visible = False
                configCheckBoxes(True) 'David D 6/2/17 enabled checkboxes for "Edit/Send" for revision
                reqUpload = True
                butSave.ImageUrl = "images/button_save.png"
                butSend.ImageUrl = "images/button_send.png"
                saveButton.Value = "GCPrepare"
                sendButton.Value = "GCReleaseCM"
                butSave.Visible = True
                butSend.Visible = True
                multiQuestions.Visible = False
                reqUpload = True
                txtAltRefNumber.Enabled = True
            Case "GCRevise", "GCReviseSendCM", "GCSaveRevision"
                alertText = "This action will create a new revision but will not send to the CM.\n\nYou will be able to edit once saved."
                alertText &= "\n\nDo you want to continue?"
                butSave.OnClientClick = "return confirm('" & alertText & "')"
                alertText = "This action will create a new revision and send to the CM.\n\nYou will NOT be able to edit once sent."
                alertText &= "\n\nDo you want to continue?"
                butSend.OnClientClick = "return confirm('" & alertText & "')"
                butSend.ImageUrl = "images/button_send.png"
                nextRev = getNextRevision() + 1
                reqUpload = True
                Rev = nextRev
                configNew()
                configRevision()
                lblQAttachments.Visible = False
                uploadPanel.Visible = False
                roRFIDetail.Visible = False
                butSave.ImageUrl = "images/button_create.gif"
                updateRequestAttachment(Rev, nRFIID, reqUpload)
                'QuestionAttachments_click()
                QuestionAttachments.Visible = False
                butCloseUpload.Visible = False
                saveButton.Value = "GCSaveRevision"
                sendButton.Value = "GCSaveAndSendRevision"
                butSend.Visible = False
                uploadPanel.Visible = False
                PrintRFI.Visible = False
                butSave.Visible = True
                txtAltRefNumber.Enabled = True
            Case "GCReleaseRFI"
                alertText = "This action will accept the solution and send to the CM for final close. No other action will be required."
                alertText &= "\n\n\Do you want to continue?"
                butSave.OnClientClick = "return confirm('" & alertText & "')"
                configResponseAlgorithm()
                multiQuestions.Visible = False
                'lblQuestion.Text = "Revision: # " & Rev
                If Session("ConfigAns") <> True Then
                    Session("ConfigAns") = True
                End If
                butSave.ImageUrl = "images/button_accept.png"
                resUpload = True
                cancelNewAnswer.Visible = False
                saveButton.Value = "GCReleaseRFI"
            Case "GCRespondCM" 'no longer used in any dropdown
                alertText = "This action will send a response to the CM for clarification. This will not create a revision."
                alertText &= "\n\n\Do you want to continue?"
                butSave.OnClientClick = "return confirm('" & alertText & "')"
                configResponseAlgorithm()
                configResponseEdit(confVw)
                butSave.Visible = True
                Session("ConfigAns") = True
                butSave.ImageUrl = "images/button_send.png"
                resUpload = True
                cancelNewAnswer.Visible = False
                saveButton.Value = "GCRespondCM"
            Case Else
                configReadOnly(confVw) 'David D had to uncomment this else case for position [5] if commented out the read only for GC is editable              
        End Select
        updateResponseAttachment(Seq, nRFIID, resUpload)
        If cboAcceptRevise.SelectedValue = "GCRevise" Or cboAcceptRevise.SelectedValue = "GCReviseSendCM" Then
            updateRequestAttachment(nextRev, nRFIID, reqUpload)
        Else
            updateRequestAttachment(Rev, nRFIID, reqUpload)
        End If
        uploadFrame1.Attributes.Add("src", Session("QAttachments"))
        uploadFrame1.Attributes.Add("src", Session("AnsAttachments")) 'David D 6/2/17 added so the different uploaded documents can be viewed based on the multiAnswer dropdown        
        
    End Sub
    
    Private Function getNextRevision() As Integer
        Dim nextRev As Integer
        Using revNum As New RFI
            nextRev = revNum.checkForRevisions(nRFIID)
        End Using
        Return nextRev
    End Function
    
    Private Sub configRequestPrepare()
        txtQuestion.Enabled = True
        txtQuestion.Visible = True
        txtQuestion.Text = (txtQuestion.Text).Replace("~", "'")
        roProposed.Visible = False
        txtProposed.Visible = True
        txtProposed.Text = (txtProposed.Text).Replace("~", "'")
        roAnswer.Visible = False
        txtAnswer.Visible = False
        lblRespondedOn.Visible = False
        lblReturnedBy.Visible = False
        Label10.Visible = False
        roRequiredBy.Visible = False
        If Session("ContactType") = "General Contractor" Then
            txtRequiredBy.Visible = False
            Label7.Visible = False
        Else
            txtRequiredBy.Visible = True
        End If
        cboAcceptRevise.Visible = True
        roReceivedOn.Text = Today
        roReceivedOn.Visible = True
        multiAnswers.Visible = False
        numAns.Visible = False
        newAnswerButton.Visible = False
        QuestionAttachments.Visible = True
        lblResponseAttachments.Visible = False
        ResponseAttachments.Visible = False
        responseAttachNum.Visible = True
        multiQuestions.Visible = False
        lblQuestion.Text = "Revision # " & Rev
        multiAnswers.Visible = False
        roReturnedOn.Visible = False
        roReturnedBy.Visible = False
        lblQAttachments.Text = "Attachments (Count):"
        responseAttachNum.Visible = False
        Using db As New RFI
            Dim isRev As DataTable = db.checkForExistingRevision(nContactID, nRFIID)
            If isRev.Rows.Count > 0 Then
                Rev = isRev.Rows(0).Item("Revision")
                multiQuestions.SelectedValue = Rev
                lblQuestion.Text = "Revision # " & Rev
            Else
                lblQuestion.Text = "Original Question"
            End If
        End Using
    End Sub
    
    Private Sub configRevision()
        If Session("ContactType") = "General Contractor" Then
            roRequiredBy.Visible = False
            txtRequiredBy.Visible = False
            Label7.Visible = False
        Else
            roRequiredBy.Visible = False
            txtRequiredBy.Visible = True
        End If
        cboAcceptRevise.Visible = False
        cboSubmittedToID.Visible = False
        txtProposed.Enabled = True 'David D Added to block Proposed Resolution of GC unless it is a Revision to the DP by CM 5/24/17
        txtQuestion.Enabled = True 'added by David D to enable proposed resolution to DP (text box was disabled to to text wraping issues, this allowed it to be editable again) 5/23/17        
        Dim tbl As DataTable
        tbl = New DataTable("tbl")
        tbl.Columns.Add("Action", GetType(System.String))
        tbl.Columns.Add("ActionText", GetType(System.String))
        If cboAcceptRevise.SelectedValue = "GCRevise" Then
            tbl.Rows.Add("GCSaveRevision", "")
        ElseIf cboAcceptRevise.SelectedValue = "GCReviseSendCM" Then
            tbl.Rows.Add("GCSaveAndSendRevision", "")
        End If
        With cboAcceptRevise
            .DataValueField = "Action"
            .DataTextField = "ActionText"
            .DataSource = tbl
            Try
                .DataBind()
            Catch ex As Exception
            End Try
        End With
        lblQAttachments.Text = "Attachments (Count):"
        txtQuestion.Text = ""
        txtProposed.Text = ""
        txtAltRefNumber.Enabled = True
    End Sub
    
    Private Sub configReadOnly(confVw As Object)
        configCheckBoxes(False)
        Dim qcount As Integer = confVw(0) 'rows in rfiquestion table
        Dim count As Integer = confVw(1) 'rows in answer table
        Dim requestStatus As String = confVw(2) 'current request status
        Dim rowExists As Boolean = confVw(3) 'original answer exists
        Dim responseStatus As String = confVw(4) 'current response status
        newAnswerButton.Visible = False
        butSave.Visible = False
        butSend.Visible = False
        txtQuestion.Visible = True 'David D Changed from False to True to fix word wraping issue 5/23/17
        txtQuestion.Enabled = False 'David D added to fix text wrap issue 5/23/17
        roQuestion.Visible = False 'David D added to fix text wrap issue 5/23/17
        roQuestion.Enabled = True 'David D added to fix text wrap issue 5/23/17
        'roQuestion_xxx.Visible = False
        OtherDescription.Enabled = False 'David D 6/21/17 added after recent update to configCheckBoxes()       
        txtProposed.Visible = True
        roProposed.Visible = False 'David D added this for GC initiated flow 5/24/17
        txtProposed.Enabled = False 'David D added to fix word wrap issue 5/24/17
        roProposed.Enabled = False 'David D added to fix word wrap issue 5/24/17
        txtAnswer.Visible = True 'David D Changed from False to True to fix word wraping issue 5/23/17
        roAnswer.Visible = False 'David D added this and the roAnswer disapeared and the above txtAnswer is now true and editable  5/23/17
        txtAnswer.Enabled = False 'David D added this after roAnswer to disable the txtAnswer in ReadOnly mode this wraps text and makes it scrollable  5/23/17        
        txtAltRefNumber.Visible = True
        txtAltRefNumber.Enabled = False
        
        If Session("ContactType") <> "ProjectManager" Then
            chkAugment.Visible = False
            chkAugment.Enabled = False
        End If
        
        If WorkFlowPosition = "CM:Review Pending" Then
            If Session("ContactType") = "General Contractor" Then
                lblRespondedOn.Visible = False
                lblReturnedBy.Visible = False
            End If
        Else
            lblRespondedOn.Visible = True
            lblReturnedBy.Visible = True
        End If
        
        saveNewAnswer.Visible = False
        cancelNewAnswer.Visible = False
        
        If count > 2 Then
            multiAnswers.Visible = True
            Label10.Text = "Response # "
        Else
            Label10.Text = "Response # 1"
        End If
        If qcount > 1 Then
            multiQuestions.Visible = True
            lblQuestion.Text = "Revision # "
        End If
        
        If Trim(responseStatus) = "Hold" Then
            roReturnedOn.Text = ""
            roReturnedBy.Text = ""
        End If
        lblResponseAttachments.Visible = True
        roReturnedOn.Visible = True
        ResponseAttachments.Visible = True
        If count > 1 Then
            getRevisionAnswers(Seq, Rev)
        End If
        
        If requestStatus <> "Active" Then
            cboAcceptRevise.Visible = False
        ElseIf requestStatus = "Active" Then
            'cboAcceptRevise.Visible = True           
        End If
        
        lblQAttachments.Text = "Attachments (Count):"
        lblResponseAttachments.Text = "Attachments (Count):"
        cboSubmittedToID.Visible = False
       
        If count = 1 Then
            If rowExists = True Then
                If confVw(4) = "Released" Or confVw(10) = nContactID Then
                    If Session("ContactType") = "General Contractor" 'And confVw(4) = "Hold" Then
                    Else
                        roReturnedOn.Visible = True
                        lblResponseAttachments.Visible = True
                        ResponseAttachments.Visible = True
                        responseAttachNum.Visible = True
                    End If
                End If
            Else
                roReturnedOn.Text = ""
                roReturnedBy.Text = ""
                lblResponseAttachments.Visible = False
                ResponseAttachments.Visible = False
                responseAttachNum.Visible = False
            End If
        End If
        getRevisionAnswers(Seq, Rev)
    End Sub
   
    Private Sub configResponseAlgorithm()
        '0 = saveType - 1 = Sequence - 2 = Is Answer - 3 = Answer
        Dim obj As Object
        Using db As New RFI
            obj = db.configResponseSave(nRFIID, nContactID, Rev, Session("Override"))
        End Using
        
        txtAnswer.Visible = True
        txtAnswer.Enabled = True
        multiAnswers.Visible = False
        If multiQuestions.SelectedValue > 0 Then
            lblQuestion.Text = "Revision # " & multiQuestions.SelectedValue
        Else
            lblQuestion.Text = "Original Question"
        End If
        multiQuestions.Visible = False
        numAns.Visible = False
        Seq = obj(1)
        updateResponseAttachment(obj(1), nRFIID, True)
        lblRespondedOn.Visible = True
        ResponseAttachments.Visible = True
        responseAttachNum.Visible = True
        lblResponseAttachments.Visible = True
        cboAcceptRevise.OpenDropDownOnLoad = False
        
        If obj(2) = 1 Then
            txtAnswer.Text = obj(3)
            roReturnedOn.Visible = True
            roReturnedBy.Visible = True
            Label10.Text = "Response # " & obj(1)
            roReturnedOn.Visible = True
            roReturnedOn.Text = Today
            lblReturnedBy.Visible = False
            ResponseAttachments.Visible = True
        Else
            txtAnswer.Text = ""
            roReturnedOn.Text = Today
            roReturnedOn.Visible = True
            lblReturnedBy.Visible = False
            roReturnedBy.Visible = False
            Label10.Text = "New Response # " & obj(1)
        End If
        Using db As New RFI
            responseAttachNum.Text = db.countRFIAttachmentsNew(nRFIID, Rev, obj(1), "Response")
        End Using
        uploadFrame1.Attributes.Add("src", Session("AnsAttachments"))
        
        If ResponseAttachments.ImageUrl = "images/button_show_history.png" Then
            'ResponseAttachments_click()                            
        End If
    End Sub
    
    Private Sub configResponseEdit(confVw As Object)
        Dim qcount As Integer = confVw(0)
        Dim count As Integer = confVw(1)
        Dim requestStatus As String = confVw(2)
        Dim rowExists As Boolean = confVw(3)
        Dim responseStatus As String = confVw(4)
        
        If Trim(responseStatus) = "Hold" Then
            roAnswer.Visible = False
            txtAnswer.Visible = True
            txtAnswer.Enabled = True
            lblQuestion.Text = "Revision # " & confVw(1)
            resUpload = True
            newAnswerButton.Visible = False
        ElseIf Trim(responseStatus) = "Released" Then
            If rowExists = False And count = 1 Then
                butSave.Visible = True
                'lblMessage.Text = "1"
                If multiAnswers.SelectedValue < confVw(1) Then
                    newAnswerButton.Visible = False
                    lblQuestion.Text = "Revision # " & confVw(1)
                End If
                multiQuestions.Visible = False
            Else
                butSave.Visible = False
                cancelNewAnswer.Visible = False
                'lblMessage.Text = "2"
                If multiAnswers.SelectedValue < confVw(1) Then
                    newAnswerButton.Visible = False
                    lblQuestion.Text = "Revision # " & confVw(1)
                End If
            End If
        End If
    End Sub

    Private Sub configForResponseConflict(Type As String)
        Dim obj(2) As Object
        Using db As New RFI
            obj = db.checkForResponsePrepare(nRFIID, nContactID)
        End Using
        
        If Type = "None" Then

        ElseIf Type = "Edit" Then
            If obj(0) <> "none" Then
                If Session("ContactType") <> "ProjectManager" Then
                    If Type = "Edit" Then
                        conflictMessage.Text = obj(0) & " has a " & obj(5) & " that is being prepared. Another response or revision cannot be created at this time!"
                        conflictMessage.Visible = True
                        txtAnswer.Visible = True
                        txtAnswer.Enabled = False
                        butSave.Visible = False
                        butSend.Visible = False
                        cboAcceptRevise.OpenDropDownOnLoad = False
                    Else
                        conflictMessage.Visible = False
                    End If
                Else
                    conflictMessage.Text = obj(0) & " has a " & obj(5) & " that is being prepared. Creating a response here will cancel the other response or revision!"
                    conflictMessage.Visible = True
                    txtAnswer.Text = ""
                End If
            Else
                
            End If
        End If
        
    End Sub
    
    Private Function buildActionDropdown(UserType As String, subType As String) As DataTable
        
        Dim tbl As DataTable
        tbl = New DataTable("tbl")
        Dim isRev As DataTable
        Dim count As Integer
        Dim confVw As Object = Nothing
        Try
            confVw = buildConfVwObject()
        Catch ex As Exception
        End Try
        
        tbl.Columns.Add("Action", GetType(System.String))
        tbl.Columns.Add("ActionText", GetType(System.String))
        If WorkFlowPosition <> "None" Then
            tbl.Rows.Add("none", "Review")
        End If
       
        Select Case (UserType)
            Case "General Contractor"
                Select Case Trim(WorkFlowPosition)
                    Case "New"
                        tbl.Rows.Add("GCSave", "Create Without Sending to CM")
                        tbl.Rows.Add("GCSaveAndSendCM", "Create and SEND To CM")
                    Case "None"
                        tbl.Rows.Add("GCPrepare", "Edit RFI")
                        tbl.Rows.Add("GCReleaseCM", "Edit and SEND To CM")
                    Case "GCRevise"
                    Case "CM:Completion Pending"
                    Case "DP:Response Pending"
                    Case "CM:Review Pending"
                    Case "CM:Distribution Pending"
                    Case "GC:Acceptance Pending", "SaveRevision"
                        If confVw(2) <> "Preparing" Then
                            tbl.Rows.Add("GCReleaseRFI", "Accept Response")
                        End If
                        'David D 6/21/17 fixed "OTHER" checkbox adn "OtherDescription" functionality with the below condition in addition to JavaScript
                        If OtherDescription.Text <> String.Empty And cboAcceptRevise.SelectedValue <> "" And cboAcceptRevise.Visible = True Then
                            OtherDescription.Enabled = True
                        End If
                        Using db As New RFI
                            isRev = db.checkForExistingRevision(nContactID, nRFIID)
                            count = isRev.Rows.Count
                            'tbl.Rows.Add("GCRespondCM", "Respond to CM")
                            'If Trim(roRequestStatus.Text) = "Preparing" Or confVw(2) = "Preparing" Then
                            If count > 0 Then
                                If Rev = count Or isRev.Rows(count - 1).Item("Revision") = Rev Then
                                    If isRev.Rows(count - 1).Item("Revision") = Rev Then
                                        tbl.Rows.Add("GCPrepare", "Edit/Send RFI")
                                    Else
                                    End If
                                End If
                            Else
                                tbl.Rows.Add("GCRevise", "Create Revision")
                            End If
                        End Using
                    Case Else
                End Select
            Case "Construction Manager", "ProjectManager"
                If UserType = "Construction Manager" Or isPMtheCM = True Then
                    Select Case WorkFlowPosition
                        Case "New", "None"
                            tbl.Rows.Add("CMPrepare", "Prepare RFI")
                        Case "CMPrepare"
                            tbl.Rows.Add("CMSave", "")
                            tbl.Rows.Add("CMSaveSendDP", "")
                        Case "CM:Review Pending"
                            'If roRequestStatus.Text = "Active" Then
                            Using db As New RFI
                                Dim isSolution As Boolean = db.isDPSolution(nRFIID, Rev)
                                'If isSolution = False Then
                                If roSubmittedToID.Text = "Pending" Then
                                    tbl.Rows.Add("CMAssignDP", "Assign To DP")
                                Else
                                    tbl.Rows.Add("CMEditResponseDP", "Edit/Send DP")
                                End If
                                'End If
                                tbl.Rows.Add("CMReturnGC", "Return To GC")
                            End Using
                            'End If
                        Case "DP:Response Pending"
                        Case "CM:Distribution Pending", "CM:Acceptance Pending"
                            Using db As New RFI
                                isRev = db.checkForExistingRevision(nContactID, nRFIID)
                                count = isRev.Rows.Count()
                            End Using
                            If RFIType = "GC" Then
                                If confVw(2) <> "Preparing" Then
                                    tbl.Rows.Add("CMReleaseGC", "Send To GC")
                                End If
                            End If
                            If RFIType = "CM" Or RFIType = "PM" Then
                                If confVw(2) <> "Preparing" Then
                                    tbl.Rows.Add("CMShowToGC", "Route to GC of Record")
                                    tbl.Rows.Add("CMRFIClose", "Close Current RFI")
                                End If
                            End If
                            If count > 0 Then
                                If isRev.Rows(0).Item("RequestStatus") = "Preparing" Then
                                    If confVw(11) <> True Then
                                        tbl.Rows.Add("CMEditSendRevisionDP", "Edit Revision/Return To DP")
                                    End If
                                End If
                            Else
                                tbl.Rows.Add("CMSendBackDP", "Revise/Return To DP")
                            End If
                        Case "GC:Acceptance Pending"
                            If UserType = "ProjectManager" Then
                                tbl.Rows.Add("GCReleaseRFI", "Accept Response")
                            End If
                        Case "CM:Completion Pending"
                            If sRequestStatus = "Active" Then
                                tbl.Rows.Add("CMRFIClose", "Close Current RFI")
                            End If
                        Case Else
                    End Select
                Else 'The user is the ProjectManager
                    Select Case WorkFlowPosition
                        Case "CM:Review Pending"
                            If sRequestStatus = "Active" Then
                                'tbl.Rows.Add("PMChangeDate", "Change Required By Date")
                                Using db As New RFI
                                    Dim isSolution As Boolean = db.isDPSolution(nRFIID, Rev)
                                    If isSolution = False Then
                                        If roSubmittedToID.Text = "Pending" Then
                                            tbl.Rows.Add("PMAssignDP", "Assign To DP")
                                        Else
                                            tbl.Rows.Add("PMEditResponseDP", "Edit/Send DP")
                                        End If
                                    End If
                                    tbl.Rows.Add("PMReturnGC", "Return To GC")
                                End Using
                            End If
                        Case "CM:Distribution Pending", "CM:Acceptance Pending"
                            'tbl.Rows.Add("PMChangeDate", "Change Required By Date")
                            Using db As New RFI
                                isRev = db.checkForExistingRevision(nContactID, nRFIID)
                                count = isRev.Rows.Count()
                            End Using
                            If RFIType = "GC" Then
                                If confVw(2) <> "Preparing" Then
                                    tbl.Rows.Add("PMReleaseGC", "Send To GC")
                                End If
                            End If
                            If RFIType = "CM" Or RFIType = "PM" Then
                                If confVw(2) <> "Preparing" Then
                                    tbl.Rows.Add("PMShowToGC", "Route to GC of Record")
                                    tbl.Rows.Add("PMRFIClose", "Close Current RFI")
                                End If
                            End If
                            If count > 0 Then
                                If isRev.Rows(0).Item("RequestStatus") = "Preparing" Then
                                    If confVw(11) <> True Then
                                        tbl.Rows.Add("PMEditSendRevisionDP", "Edit Revision/Return To DP")
                                    End If
                                End If
                            Else
                                tbl.Rows.Add("PMSendBackDP", "Revise/Return To DP")
                            End If
                        Case "CM:Completion Pending"
                            'David D 6/2/17 updated conditions below for case isPMtheCM, previously this showed the override close and normal close in the dropdown, but this is now fixed
                            If sRequestStatus = "Active" And Session("ContactType") = "Construction Manager" Then
                                tbl.Rows.Add("PMRFIClose", "Close Current RFI")
                            ElseIf sRequestStatus = "Active" And Session("ContactType") = "ProjectManager" And isPMtheCM = True Then
                                tbl.Rows.Add("PMRFIClose", "Close Current RFI")
                            End If
                        Case "DP:Response Pending"
                            'tbl.Rows.Add("PMChangeDate", "Change Required By Date")
                            tbl.Rows.Add("DPPrepare", "Prepare Response")
                        Case "GC:Acceptance Pending"
                            'tbl.Rows.Add("PMChangeDate", "Change Required By Date")
                            tbl.Rows.Add("GCReleaseRFI", "Accept Response")
                    End Select
                    If WorkFlowPosition = "CM:Completion Pending" Then
                        'tbl.Rows.Add("PMChangeDate", "Change Required By Date")
                        tbl.Rows.Add("PMCloseOverride", "Override Close Current RFI")
                    End If
                End If
            Case "Design Professional"
                Select Case WorkFlowPosition
                    Case "DP:Response Pending"
                        tbl.Rows.Add("DPPrepare", "Prepare Response")
                    Case Else
                End Select
            Case Else
        End Select
        Return tbl
    End Function
    '-------------------------------  SAVE/UPDATE Functions  ----------------------------  
    Private Sub releaseRFI() ' Releases RFI from the GC needing any further action.
        Using db As New RFI
            db.releaseRFI(nRFIID)
            'butClose_Click()
        End Using
    End Sub
       
    Private Sub assignDP(responseType As String)
        If cboSubmittedToID.SelectedValue = 0 Then
            lblMessage.Text = "You need to select the person you want to assign this RFI to!"
            Exit Sub
        End If
        Using db As New RFI
            db.updateSentTo(nRFIID, cboSubmittedToID.SelectedValue, multiQuestions.SelectedValue, (txtAnswer.Text).Replace("'", "~"), responseType)
            'db.updateSentTo(nRFIID, cboSubmittedToID.SelectedValue, Rev, (txtAnswer.Text).Replace("'", "~"), responseType)           
        End Using
        buildActionDropdown(Session("ContactType"), "")
    End Sub
    
    Private Sub releaseToDP()
        Dim wfp As String = "DP:Response Pending"
        processResponse(wfp, "Released", "", "", "True")
    End Sub
    
    Private Sub releaseToGC(RFIID As Integer, sequenceNum As Integer)
        Using db As New RFI
            db.releaseToGC(RFIID, sequenceNum)
        End Using
    End Sub
    
    Private Sub processResponse(wfp As String, responseStatus As String, noValidation As String, responseType As String, updateCheckBoxes As String)
        
        If Session("txtAnswer") = "" And noValidation <> "Skip" Then
            'If txtAnswer.Text = "" Then
            conflictMessage.Visible = False
            lblMessage.Text = "You have not entered a response!"
            Session("ValidationError") = True
            Exit Sub
        End If
        
        If multiQuestions.SelectedValue = Nothing Then
            Rev = 0
        Else
            Rev = multiQuestions.SelectedValue
        End If
  
        Dim confVw As Object = buildConfVwObject()
        Dim Action As String = cboAcceptRevise.SelectedValue
        Dim obj(5) As Object
           
        Dim resObj(20) As Object

        resObj(0) = Session("txtAnswer").replace("'", "~") '(txtAnswer.Text).Replace("'", "~")
        resObj(1) = nRFIID
        resObj(2) = Rev
        resObj(3) = Seq 'current answer sequence number selected (for updates)
        resObj(4) = DateTime.Now
        resObj(5) = nContactID 'currentUser
        resObj(6) = cboSubmittedToID.SelectedIndex
        resObj(7) = wfp 'noChange or WFPosition. Next WFP
        resObj(8) = responseStatus 'ResponseStatus
        resObj(9) = Action
        resObj(10) = "Active" 'RFI Status
        resObj(11) = "" 'Save type
        resObj(12) = confVw(3) 'original answer exists
        If Trim(confVw(4)) = "Hold" Then
            resObj(13) = confVw(1)
        Else
            resObj(13) = confVw(1) + 1 'next added answer sequence number (for inserts)
        End If
       
        resObj(14) = responseType 'This is the type of the response [DP-Solution][Message]
        resObj(15) = txtRequiredBy.SelectedDate 'Required By Date
        resObj(16) = txtAltRefNumber.Enabled 'Gets the value on the AltRefNumber enabled
        resObj(17) = Left(txtAltRefNumber.Text, 25) 'The Alternate Reverence Number
        resObj(18) = txtRequiredBy.Enabled
        resObj(19) = confVw(13) ' AnswerID
        
        Using db As New RFI
            obj = db.configResponseSave(nRFIID, nContactID, Rev, Session("Override"))
        End Using
        
        resObj(11) = obj(0)
        resObj(13) = obj(1)
        resObj(19) = obj(4)
        'testPlace.Value = "Save Type = " & obj(0) & " Sequence = " & obj(1) & " Is Answer " & obj(2) & " AnswerID: " & obj(4) & " Answer: " & obj(3)
                
        Session("NewAnswer") = False
        Session("ConfigAns") = False
        
        'If Session("dontknow") = "xxxxx" Then
        Using db As New RFI
            db.processRFIResponse(resObj)
            getRevisionAnswers(Seq, Rev)
            If updateCheckBoxes = "True" Then
                updateCheckBoxValues("Update")
            End If
                       
            'These WFPs are not the current position but the next WFP as they are the changed position.
            Select Case wfp 'This will update dates for critical work flow position changes.
                Case "DP:Response Pending"
                    Dim str As String = db.updateReleaseData(resObj, True)
                    'lblMessage.Text = str
                    butClose_Click()
                Case "GC:Acceptance Pending"
                    If saveButton.Value <> "GCReturnCM" Then
                        Dim str As String = db.updateReleaseData(resObj, True)
                        db.cancelOpenRevisions(nContactID, nRFIID)
                        butClose_Click()
                    End If
                Case "CM:Completion Pending"
                    Dim str As String = db.updateReleaseData(resObj, True)
                    lblMessage.Text = str
                    db.cancelOpenRevisions(nContactID, nRFIID)
                    butClose_Click()
                Case "Complete"
                    Dim str As String = db.updateReleaseData(resObj, True)
                    db.cancelOpenRevisions(nContactID, nRFIID)
                    'lblMessage.Text = str
                    butClose_Click()
                Case "CM:Distribution Pending"
                    butClose_Click()
                Case "CM:Review Pending"
                    If cboAcceptRevise.SelectedValue = "GCRespondCM" Then
                        'butClose_Click()
                    End If
                Case "noChange"
                    If Session("ContactType") = "Design Professional" Then
                        'butClose_Click()
                    End If
                    cboAcceptRevise.SelectedValue = "none"
                    updateAnswerDropdown()
                    lblMessage.Text = ""
                    configReadOnly(confVw)
            End Select
        End Using
        'End If
        Select Case cboAcceptRevise.SelectedValue
            Case ""
        End Select
        'lblMessage.Text = ""        
    End Sub
    
    Public Sub processRFIRequest(saveType As String, wfPosition As String, requestStatus As String, updateReqBy As String)

        Dim sRFIType As String = "GC"
        If Session("ContactType") = "General Contractor" Then
            sRFIType = "GC"
        ElseIf Session("ContactType") = "Construction Manager" Then
            sRFIType = "CM"
        ElseIf Session("ContactType") = "ProjectManager" Then
            sRFIType = "PM"
        End If
        
        'If cboContractID.SelectedValue = 0 Then
        'lblMessage.Text = "Please select a Contract and complete this form."
        'Session("ValidationError") = True
        'Exit Sub
        'End If
        
        If txtRequiredBy.SelectedDate Is Nothing Then
            'lblMessage.Text = "Please enter a RequiredBy Date." not required
            'txtRequiredBy.Focus()
            'Session("ValidationError") = True
            'Exit Sub
        End If
        
        If Today.Date >= txtRequiredBy.DbSelectedDate Then
            If saveType <> "InsertRev" Then
                If saveType <> "Update" Then
                    lblMessage.Text = "Required By date must be later than the created on Date."
                    txtRequiredBy.Focus()
                    Session("ValidationError") = True
                    Exit Sub
                End If
            End If
        End If
        
        If Trim(Session("txtQuestion")) = "" Then
            lblMessage.Text = "Please enter a Question."
            txtQuestion.Focus()
            Session("ValidationError") = True
            Exit Sub
        End If
               
        Session("isReqUpdate") = False
        
        Dim reqObj(20) As Object
        
        reqObj(0) = nProjectID
        reqObj(1) = cboContractID.SelectedValue
        reqObj(2) = refNumber.Value
        reqObj(3) = Session("UserName")
        reqObj(4) = Session("DistrictID")
        reqObj(5) = DateTime.Now
        reqObj(6) = txtRequiredBy.DbSelectedDate
        reqObj(7) = cboTransmittedByID.SelectedValue
        reqObj(8) = (Session("txtQuestion")).replace("'", "~") '(txtQuestion.Text).Replace("'", "~")
        reqObj(9) = (Session("txtProposed")).Replace("'", "~")
        reqObj(10) = Rev
        reqObj(11) = nRFIID
        reqObj(12) = wfPosition
        reqObj(13) = nContactID
        reqObj(14) = requestStatus
        reqObj(15) = sRFIType
        reqObj(16) = cboSubmittedToID.SelectedValue
        reqObj(17) = updateReqBy
        reqObj(18) = Left(txtAltRefNumber.Text, 25)
        
        Dim chkObj(17) As Object
        
        chkObj(0) = nRFIID
        chkObj(1) = CheckBox1.Checked
        chkObj(2) = CheckBox2.Checked
        chkObj(3) = CheckBox3.Checked
        chkObj(4) = CheckBox4.Checked
        chkObj(5) = CheckBox5.Checked
        chkObj(6) = CheckBox6.Checked
        chkObj(7) = CheckBox7.Checked
        chkObj(8) = CheckBox8.Checked
        chkObj(9) = CheckBox9.Checked
        chkObj(10) = CheckBox10.Checked
        chkObj(11) = CheckBox11.Checked
        chkObj(12) = CheckBox12.Checked
        chkObj(13) = CheckBox13.Checked
        chkObj(14) = CheckBox14.Checked
        chkObj(15) = nContactID
        If CheckBox8.Checked = True Then
            chkObj(16) = OtherDescription.Text
        Else
            chkObj(16) = ""
        End If
               
        'nContractID = cboContractID.SelectedValue
        'If Session("whatabing") = "xxxxxx" Then
        Using db As New RFI
            If saveType = "Insert" Then
                nRFIID = db.insertNewRFI(reqObj)
                Session("RFID") = nRFIID
                chkObj(0) = nRFIID
                db.insertNewCheckBoxValues(chkObj)
               
            ElseIf saveType = "InsertRev" Then
                db.cancelOpenRevisions(nContactID, nRFIID)
                reqObj(10) = Rev + 1
                db.insertRFIRevision(reqObj)
                If reqObj(14) = "Active" Then
                    db.overrideRevision(Rev, nRFIID)
                End If
                If wfPosition <> "noChange" Then
                    db.updateWorkFlowPosition(nRFIID, wfPosition)
                End If
                'getEditData()
                'configEdit()
            ElseIf saveType = "Update" Then
                db.updateRFIRequest(reqObj)
                
                Dim isRecord As String = db.checkForCheckBoxRecord(nRFIID)
                If isRecord = "False" Then
                    db.insertNewCheckBoxValues(chkObj)
                Else
                    db.updateCheckBoxValues(chkObj)
                End If
                
                If reqObj(14) = "Active" Then
                    If Rev > 0 Then
                        db.overrideRevision(Rev - 1, nRFIID)
                    End If
                End If
                If reqObj(16) > 0 Then
                    
                End If
                If Rev > 0 Then
                    multiQuestions_Change()
                Else
                    Try
                        'getEditData()
                    Catch ex As Exception
                    End Try
                End If
                
                If cboAcceptRevise.SelectedValue = "GCReleaseCM" Then
                    'butClose_Click()
                End If
                'getEditData()
                'configEdit()
                
                Session("isReqUpdate") = True
            End If
        End Using
        'End If
    End Sub
    
    Private Sub updateCheckBoxValues(saveType As String)
        Dim chkObj(17) As Object
        
        chkObj(0) = nRFIID
        chkObj(1) = CheckBox1.Checked
        chkObj(2) = CheckBox2.Checked
        chkObj(3) = CheckBox3.Checked
        chkObj(4) = CheckBox4.Checked
        chkObj(5) = CheckBox5.Checked
        chkObj(6) = CheckBox6.Checked
        chkObj(7) = CheckBox7.Checked
        chkObj(8) = CheckBox8.Checked
        chkObj(9) = CheckBox9.Checked
        chkObj(10) = CheckBox10.Checked
        chkObj(11) = CheckBox11.Checked
        chkObj(12) = CheckBox12.Checked
        chkObj(13) = CheckBox13.Checked
        chkObj(14) = CheckBox14.Checked
        chkObj(15) = nContactID
        chkObj(16) = OtherDescription.Text
        
        Using db As New RFI
            Dim isRecord As String = db.checkForCheckBoxRecord(nRFIID)
            If isRecord = "False" Then
                db.insertNewCheckBoxValues(chkObj)
            Else
                db.updateCheckBoxValues(chkObj)
            End If
        End Using
      
    End Sub
    
    Private Sub cancelResponse()
        Using db As New RFI
            db.checkCancelResponse(nRFIID, nContactID)
        End Using
    End Sub
    
    Private Sub refreshActionDropdown(subType As String)
        Dim tbl As DataTable = buildActionDropdown(Session("ContactType"), subType)
        Try
            With cboAcceptRevise
                .DataValueField = "Action"
                .DataTextField = "ActionText"
                .DataSource = tbl
                .DataBind()
            End With
        Catch ex As Exception
        End Try
        'lblMessage.Text = "Done"     
    End Sub
    
    Private Sub buildHiddenDropdown(Action1 As String, Action2 As String)
        Dim tbl As DataTable
        tbl = New DataTable("tbl")
        tbl.Columns.Add("Action", GetType(System.String))
        tbl.Columns.Add("ActionText", GetType(System.String))
        tbl.Rows.Add(Action1, Action1)
        tbl.Rows.Add(Action2, Action2)
        With cboAcceptRevise
            .DataValueField = "Action"
            .DataTextField = "ActionText"
            .DataSource = tbl
            .DataBind()
        End With
    End Sub
   
    Private Sub butSend_Click() Handles butSend.Click
        Select Case sendButton.Value
            Case "DPReleaseCM"
                buildHiddenDropdown("DPPrepare", "DPReleaseCM")
            Case "CMSaveSendDP"
                buildHiddenDropdown("CMSave", "CMSaveSendDP")
            Case "CMAssignAndSendDP"
                buildHiddenDropdown("CMAssignDP", "CMAssignAndSendDP")
            Case "PMSaveSendDP"
                buildHiddenDropdown("PMSaveSendDP", "")
            Case "PMAssignAndSendDP"
                buildHiddenDropdown("PMAssignAndSendDP", "")
            Case "CMSaveReleaseDP"
                buildHiddenDropdown("CMPrepare", "CMSaveReleaseDP")
            Case "GCSaveAndSendRevision", "GCSaveRevision"
                buildHiddenDropdown("GCSaveRevision", "GCSaveAndSendRevision")
                'Case "GCSaveAndSendCM"
                'buildHiddenDropdown("GCsave", "GCSaveAndSendCM")
            Case "GCReleaseCM"
                buildHiddenDropdown("GCPrepare", "GCReleaseCM")
            Case "CMCreateSendRevisionDP"
                buildHiddenDropdown("CMCreateSendRevisionDP", "")
            Case "CMShowToGC", "PMShowToGC"
                If sendButton.Value = "CMShowToGC" Then
                    buildHiddenDropdown("CMShowToGC", "")
                Else
                    buildHiddenDropdown("PMShowToGC", "")
                End If
        End Select
        cboAcceptRevise.SelectedValue = sendButton.Value
        'lblMessage.Text = cboAcceptRevise.SelectedValue & " - " & Rev
        'lblMessage.Text = sendButton.Value
        If Session("SessionConflict") <> True Then
            processSave()
        End If
    End Sub
    
    Private Sub butSave_Click() Handles butSave.Click
        Select Case saveButton.Value
            Case "GCSave"
                buildHiddenDropdown("GCSave", "GCSaveAndSendCM")
            Case "GCSaveRevision"
                buildHiddenDropdown("GCSaveRevision", "GCSaveAndSendRevision")
            Case "CMSave"
                buildHiddenDropdown("CMSave", "CMSaveSendDP")
            Case "CMPrepare"
                buildHiddenDropdown("CMPrepare", "")
            Case "PMSave"
                buildHiddenDropdown("PMSave", "")
            Case "GCPrepare"
                buildHiddenDropdown("GCPrepare", "GCReleaseCM")
            Case "CMCreateSaveRevisionDP"
                buildHiddenDropdown("CMCreateSaveRevisionDP", "")
            Case "CMSaveResponse"
                buildHiddenDropdown("CMSaveResponse", "")
            Case "PMSaveResponse"
                buildHiddenDropdown("PMSaveResponse", "")
            Case "PMSaveRequiredDate"
                buildHiddenDropdown("PMSaveRequiredDate", "")
            Case Else
        End Select
        cboAcceptRevise.SelectedValue = saveButton.Value
        'lblMessage.Text = cboAcceptRevise.SelectedValue
        'lblMessage.Text = saveButton.Value
        If Session("SessionConflict") <> True Then
            processSave()
        End If
    End Sub
    
    'Private Sub butSave_Click(ByVal sender As System.Object, ByVal e As System.Web.UI.ImageClickEventArgs) Handles butSave.Click
    Private Sub processSave()
        
        Dim isSkip As String = ""
        Dim responseType As String = ""
        Dim selVal As String = cboAcceptRevise.SelectedValue
        Dim confVw As Object = Nothing
        Try
            confVw = buildConfVwObject()
        Catch ex As Exception
        End Try
                
        Select Case cboAcceptRevise.SelectedValue
            Case "GCSaveRevision" '>>>>>>>>>>> Begin GC cases  <<<<<<<<<<<<<<
                'lblMessage.Text = "Save Revision"
                processRFIRequest("InsertRev", "noChange", "Preparing", "")
                If Session("ValidationError") = True Then
                    Session("ValidationError") = Nothing
                    multiQuestions.Visible = False
                    
                    'QuestionAttachments.Visible = False
                    'butSave.ImageUrl = "images/button_create.gif"
                Else
                    Response.Redirect("RFI_edit.aspx?RFIID=" & nRFIID & "&ProjectID=" & nProjectID & "&ContractID=" & nContractID & "&EditType=Edit")
                    'refreshActionDropdown("")
                    butClose_Click()
                End If
                Exit Sub
            Case "GCSaveAndSendRevision"
                processRFIRequest("InsertRev", "CM:Review Pending", "Active", "")
                If Session("ValidationError") = True Then
                    Session("ValidationError") = Nothing
                    multiQuestions.Visible = False
                Else
                    butClose_Click()
                End If
                Exit Sub
            Case "GCSave"
                processRFIRequest("Insert", "None", "Preparing", "")
                If Session("ValidationError") = True Then
                    butSend.Visible = False
                    Session("ValidationError") = Nothing
                    multiQuestions.Visible = False
                Else
                    If sType = "New" Then
                        sType = "Edit"
                        WorkFlowPosition = "None"
                        ' lblMessage.Text = nContractID
                        Response.Redirect("RFI_edit.aspx?RFIID=" & nRFIID & "&ProjectID=" & nProjectID & "&ContractID=" & nContractID & "&EditType=Edit")
                    Else
                        butClose_Click()
                    End If
                End If
                Exit Sub
            Case "GCSaveAndSendCM"
                processRFIRequest("Insert", "CM:Review Pending", "Active", "")
                If Session("ValidationError") = True Then
                    Session("ValidationError") = Nothing
                    multiQuestions.Visible = False
                Else
                    butClose_Click()
                End If
                Exit Sub
            Case "GCPrepare"
                processRFIRequest("Update", "noChange", "Preparing", "")
                If Session("ValidationError") = True Then
                    Session("ValidationError") = Nothing
                    multiQuestions.Visible = False
                Else
                    butClose_Click()
                End If
                Exit Sub
            Case "GCRevise"
                processRFIRequest("InsertRev", "noChange", "Active", "")
                If Session("ValidationError") = True Then
                    Session("ValidationError") = Nothing
                    multiQuestions.Visible = False
                    configRevision()
                End If
                
                Exit Sub
            Case "GCReleaseCM"
                processRFIRequest("Update", "CM:Review Pending", "Active", "UpdateReqBy")
                If Session("ValidationError") = True Then
                    Session("ValidationError") = Nothing
                    multiQuestions.Visible = False
                Else
                    butClose_Click()
                End If
                Exit Sub
            Case "GCReleaseRFI"
                processResponse("CM:Completion Pending", "Released", "", "GC-ReleaseRFINote", "True")
                If Session("ValidationError") = True Then
                    Session("ValidtionError") = Nothing
                    multiQuestions.Visible = False
                End If
                Exit Sub
            Case "GCRespondCM" 'No longer used
                processResponse("CM:Review Pending", "Released", "", "GC-RespondCMNote", "False")
                'butClose_Click()
                Exit Sub
            Case "CMSave", "PMSave"  '>>>>>>>>>>> Begin CM cases  <<<<<<<<<<<<<<
                processRFIRequest("Insert", "None", "Preparing", "")
                If Session("ValidationError") = True Then
                    butSend.Visible = False
                    Session("ValidationError") = Nothing
                    multiQuestions.Visible = False
                Else
                    If sType = "New" Then
                        sType = "Edit"
                        WorkFlowPosition = "None"
                        'lblMessage.Text = nContractID
                        Response.Redirect("RFI_edit.aspx?RFIID=" & nRFIID & "&ProjectID=" & nProjectID & "&ContractID=" & nContractID & "&EditType=Edit")
                    Else
                        butClose_Click()
                    End If
                End If
                Exit Sub
            Case "CMSaveSendDP", "PMSaveSendDP"
                If cboSubmittedToID.SelectedValue = 0 Then
                    'lblMessage.Text = "Please select a Design Professional from the dropdown!"
                    'cboSubmittedToID.Focus()
                    'Exit Sub
                End If
                processRFIRequest("Insert", "DP:Response Pending", "Active", "")
                butClose_Click()
                Exit Sub
            Case "CMPrepare"
                processRFIRequest("Update", "noChange", "Preparing", "")
                If Session("ValidationError") = True Then
                    Session("ValidationError") = Nothing
                    multiQuestions.Visible = False
                Else
                    butClose_Click()
                End If
                Exit Sub
            Case "CMSaveReleaseDP"
                If cboSubmittedToID.SelectedValue = 0 Then
                    'lblMessage.Text = "Please select a Design Professional from the dropdown!"
                    'txtProposed.Text = Session("txtProposed")
                    'txtQuestion.Text = Session("txtQuestion")
                    'configRequestPrepare()
                    'cboAcceptRevise.Visible = False
                    'cboSubmittedToID.Focus()
                    'Exit Sub
                End If
                processRFIRequest("Update", "DP:Response Pending", "Active", "")
                If Session("ValidationError") = True Then
                    Session("ValidationError") = Nothing
                    multiQuestions.Visible = False
                Else
                    butClose_Click()
                End If
                Exit Sub
            Case "CMAssignDP", "PMAssignDP" '>>>>>>>>>  Begin CM/PM cases  <<<<<<<<<<<<
                If selVal = "CMAssignDP" Then responseType = "CM-DPAssignNote" Else If selVal = "PMAssignDP" Then responseType = "PM-DPAssignNote"
                processResponse("noChange", "Hold", "Skip", responseType, "True")
                assignDP(responseType)
                If Session("ValidationError") = True Then
                    Session("ValidationError") = False
                    multiQuestions.Visible = False
                Else
                    butClose_Click()
                End If
                Exit Sub
            Case "CMSaveResponse", "PMSaveResponse"
                If selVal = "CMSaveResponse" Then responseType = "CM-ResponseOnHold" Else If selVal = "PMSaveResponse" Then responseType = "PM-ResponseOnHold"
                processResponse("noChange", "Hold", "", responseType, "True")
                If Session("ContactType") = "ProjectManager" Then
                    cancelResponse()
                End If
                If Session("ValidationError") = True Then
                    Session("ValidationError") = False
                    Try
                        refreshActionDropdown("")
                    Catch ex As Exception
                    End Try
                    If selVal = "CMSaveResponse" Then
                        cboAcceptRevise.SelectedValue = "CMEditResponseDP"
                    Else
                        cboAcceptRevise.SelectedValue = "PMEditResponseDP"
                    End If
                    configEdit()
                    cboAcceptRevise.OpenDropDownOnLoad = False
                    multiQuestions.Visible = False
                Else
                    butClose_Click()
                End If
                Exit Sub
            Case "CMReleaseDP", "PMReleaseDP" 'No longer used
                If selVal = "CMReleaseDP" Then responseType = "CM-DPReleaseNote" Else If selVal = "PMReleaseDP" Then responseType = "PM-DPReleaseNote"
                processResponse("DP:Response Pending", "Released", "", responseType, "True")
                butClose_Click()
                Exit Sub
            Case "CMAssignAndSendDP", "PMAssignAndSendDP"
                If selVal = "CMAssignAndSendDP" Then responseType = "CM-DPReleaseNote" Else If selVal = "PMAssignAndSendDP" Then responseType = "PM-DPReleaseNote"
                processResponse("DP:Response Pending", "Released", "", responseType, "True")
                assignDP(responseType)
                If Session("ContactType") = "ProgramManager" Then
                    cancelResponse()
                End If
                If Session("ValidationError") = True Then
                    Session("ValidationError") = False
                    Try
                        refreshActionDropdown("")
                    Catch ex As Exception
                    End Try
                    If selVal = "CMAssignAndSendDP" Then
                        cboAcceptRevise.SelectedValue = "CMEditResponseDP"
                    Else
                        cboAcceptRevise.SelectedValue = "PMEditResponseDP"
                    End If
                    'configEdit()
                    cboAcceptRevise.OpenDropDownOnLoad = False
                    multiQuestions.Visible = False
                Else
                    butClose_Click()
                End If
                Exit Sub
            Case "CMCreateSaveRevisionDP", "PMCreateSaveRevisionDP"
                processRFIRequest("InsertRev", "noChange", "Preparing", "")
                If Session("ValidationError") = True Then
                    Session("ValidationError") = Nothing
                    'configNew()
                    configRevision()
                    hideResponseInfo()
                    Label10.Visible = False
                    txtAnswer.Visible = False
                    butSave.Visible = True
                    QuestionAttachments.Visible = False
                    multiQuestions.Visible = False
                    requestAttachNum.Visible = False
                    ResponseAttachments.Visible = False
                    multiAnswers.Visible = False
                    numAns.Visible = False
                Else
                    Response.Redirect("RFI_edit.aspx?RFIID=" & nRFIID & "&ProjectID=" & nProjectID & "&ContractID=" & nContractID & "&EditType=Edit")
                End If
                'butClose_Click()
                Exit Sub
            Case "CMCreateSendRevisionDP", "PMCreateSendRevisionDP"
                processRFIRequest("InsertRev", "DP:Response Pending", "Active", "")
                Response.Redirect("RFI_edit.aspx?RFIID=" & nRFIID & "&ProjectID=" & nProjectID & "&ContractID=" & nContractID & "&EditType=Edit")
                Exit Sub
            Case "CMReturnGC", "PMReturnGC"
                If selVal = "CMReturnGC" Then responseType = "CM-GCReturnNote" Else If selVal = "PMReturnGC" Then responseType = "PM-GCReturnNote"
                processResponse("GC:Acceptance Pending", "Released", "", responseType, "True")
                If Session("ValidationError") = True Then
                    Session("ValidationError") = False
                    multiQuestions.Visible = False
                Else
                    butClose_Click()
                End If
                Exit Sub
            Case "CMReleaseGC", "PMReleaseGC"
                If selVal = "CMReleaseGC" Then responseType = "CM-GCReleaseNote" Else If selVal = "PMReleaseGC" Then responseType = "PM-GCReleaseNote"
                processResponse("GC:Acceptance Pending", "Released", "", responseType, "True")
                updateCheckBoxValues("")
                If Session("ValidationError") = True Then
                    Session("ValidationError") = Nothing
                    multiQuestions.Visible = False
                Else
                    butClose_Click()
                End If
                Exit Sub
            Case "CMRedirectDP", "PMRedirectDP" 'No longer used
                If selVal = "CMRedirectDP" Then responseType = "CM-DPRedirectNote" Else If selVal = "PMRedirectDP" Then responseType = "PM-DPRedirectNote"
                processResponse("DP:Response Pending", "Released", "", responseType, "True")
                Exit Sub
            Case "CMRFIClose", "PMRFIClose"
                If selVal = "CMRFIClose" Then responseType = "CM-CloseRFINote" Else If selVal = "PMRFIClose" Then responseType = "PM-CloseRFINote"
                processResponse("Complete", "Released", "", responseType, "False")
                If Session("ValidationError") = True Then
                    Session("ValidationError") = False
                    multiQuestions.Visible = False
                Else
                    
                End If
                Exit Sub
            Case "CMShowToGC", "PMShowToGC"
                'David D 5/30/17 added below block of code to save the CM/PM Response during CM initiated RFI Pathway #2 position [4]
                If selVal = "CMShowToGC" Then responseType = "CM-RouteToGCNote" Else If selVal = "PMShowToGC" Then responseType = "PM-RouteToGCNote"
                processResponse("GC:Acceptance Pending", "Released", "", responseType, "True")
                'releaseToGC(nRFIID, confVw(1))
                updateCheckBoxValues("")
                If Session("ValidationError") = True Then
                    Session("ValidationError") = False
                    multiQuestions.Visible = False
                Else
                    'butClose_Click()               
                    'David D end of added code block above for CM initiated RFI Pathway #2 position [4]
                    Using db As New RFI
                        db.updateRFICMShowToGC(nRFIID, nContactID, 1)
                    End Using
                    closeWindow()
                    Exit Sub
                End If
            Case "CMHideFromGC", "PMHideFromGC"
                Using db As New RFI
                    'db.updateRFICMShowToGC(nRFIID, nContactID, 0)
                End Using
                closeWindow()
                Exit Sub
            Case "PMCloseOverride"  '>>>>>>>>> Begin PM cases  <<<<<<<<<<
                processResponse("Complete", "Released", "", "PM-OverrideCloseNote", "False")
                If Session("ValidationError") = True Then
                    Session("ValidationError") = False
                    multiQuestions.Visible = False
                    
                End If
                Exit Sub
            Case "DPPrepare"  '>>>>>>>>>>>  Begin DP cases  <<<<<<<<<<<           
                multiAnswers.SelectedValue = confVw(1)
                'Seq = confVw(1)
                processResponse("noChange", "Hold", "", "DP-Solution", "True")
                If Session("ValidationError") = True Then
                    Session("ValidationError") = False
                    multiQuestions.Visible = False
                Else
                    roAnswer.Visible = False
                    txtAnswer.Visible = True
                    resUpload = True
                    butSave.Visible = True
                    butSend.Visible = True
                    butSave.OnClientClick = "return confirm('This action will save your response without sending to the CM for review.\n\nYou will be able to retrieve and edit as well as attach files.\n\n\nDo you want to continue?')"
                    updateResponseAttachment(Seq, nRFIID, resUpload)
                    updateCheckBoxValues("")
                    butClose_Click()
                    If Session("ContactType") = "ProjectManager" Then
                        cancelResponse()
                    End If
                End If
                Exit Sub
            Case "DPReleaseCM"
                Dim wfp As String = ""
                Session("DPPrepare") = False
                'Seq = confVw(1)
                If confVw(7) = "GC" Then wfp = "CM:Distribution Pending" Else If confVw(7) = "CM" Then wfp = "CM:Acceptance Pending" Else wfp = "CM:Distribution Pending"
                processResponse(wfp, "CMPending", "", "DP-Solution", "True")
                If Session("ContactType") = "ProjectManager" Then
                    cancelResponse()
                End If
                updateCheckBoxValues("")
                If Session("ValidationError") = True Then
                    Session("ValidationError") = False
                    refreshActionDropdown("")
                    cboAcceptRevise.SelectedValue = "DPPrepare"
                    cboAcceptRevise.OpenDropDownOnLoad = False
                    multiQuestions.Visible = False
                Else
                    butClose_Click()
                End If
                Exit Sub
            Case "PMSaveRequiredDate"
                Using db As New RFI
                    db.saveRequiredDate(txtRequiredBy.DbSelectedDate, nRFIID, Rev)
                End Using
                Response.Redirect("RFI_edit.aspx?RFIID=" & nRFIID & "&ProjectID=" & nProjectID & "&ContractID=" & nContractID & "&EditType=Edit")
            Case Else
        End Select
      
    End Sub
    
    Private Sub processNotifications(NotifyType As String)
        Dim tbl As Object
        Dim subject As String = ""
        Dim msgText As String = ""
        Dim sendEmail As String = ""
        Dim rfiData As DataTable
        
        Using db As New RFI
            rfiData = db.getRFIData(nRFIID)
        End Using
        
        Dim mailObj(12) As Object
        Using db As New RFI
            tbl = db.getContactData(CMContactID, Session("DistrictID"))
            mailObj(0) = tbl(2) 'CM full name
            mailObj(1) = tbl(3) 'CM Phone
            mailObj(2) = tbl(5) 'CM email
            tbl = db.getContactData(PMContactID, Session("DistrictID"))
            mailObj(3) = tbl(2) 'PM full name
            mailObj(4) = tbl(3) 'PM phone
            mailObj(5) = tbl(5) 'PM email          
            tbl = db.getContactData(rfiData.Rows(0).Item("SubmittedToId"), Session("DistrictID"))
            mailObj(6) = tbl(2) 'DP full name
            mailObj(7) = tbl(3) 'DP phone
            mailObj(8) = tbl(5) 'DP email
            tbl = db.getContactData(rfiData.Rows(0).Item("TransmittedByID"), Session("DistrictID"))
            mailObj(9) = tbl(2) 'GC full name
            mailObj(10) = tbl(3) 'GC phone
            mailObj(11) = tbl(5) 'GC email
            
            Select Case NotifyType
                Case "New RFI"
                    subject = "New RFI Created"
                    msgText = buildMsgText(NotifyType, "No", mailObj, rfiData)
                    sendEmail = configTestEmail(mailObj(2)) 'CM
                    db.sendEmailNotification(sendEmail, subject, msgText)
                    'roAnswer.Text = msgText
                    msgText = buildMsgText(NotifyType, "Yes", mailObj, rfiData)
                    sendEmail = configTestEmail(mailObj(5)) 'PM
                    db.sendEmailNotification(sendEmail, subject, msgText)
                Case "Send DP"
                    subject = "RFI Assigned and Sent to DP:"
                    msgText = buildMsgText(NotifyType, "No", mailObj, rfiData)
                    sendEmail = configTestEmail(mailObj(8)) 'DP
                    db.sendEmailNotification(sendEmail, subject, msgText)
                    msgText = buildMsgText(NotifyType, "Yes", mailObj, rfiData)
                    sendEmail = configTestEmail(mailObj(5)) 'PM
                    db.sendEmailNotification(sendEmail, subject, msgText)
                Case "DP Send CM"
                    subject = "RFI Solution Completed:"
                    msgText = buildMsgText(NotifyType, "No", mailObj, rfiData)
                    sendEmail = configTestEmail(mailObj(2)) 'CM
                    db.sendEmailNotification(sendEmail, subject, msgText)
                    'roAnswer.Text = msgText
                    msgText = buildMsgText(NotifyType, "Yes", mailObj, rfiData)
                    sendEmail = configTestEmail(mailObj(5)) 'PM
                    db.sendEmailNotification(sendEmail, subject, msgText)
                Case "CM Forward GC"
                    subject = "RFI Solution Released to General Contractor:"
                    msgText = buildMsgText(NotifyType, "No", mailObj, rfiData)
                    sendEmail = configTestEmail(mailObj(11)) 'GC
                    db.sendEmailNotification(sendEmail, subject, msgText)
                    msgText = buildMsgText(NotifyType, "Yes", mailObj, rfiData)
                    sendEmail = configTestEmail(mailObj(2)) 'CM
                    db.sendEmailNotification(sendEmail, subject, msgText)
                    msgText = buildMsgText(NotifyType, "Yes", mailObj, rfiData)
                    sendEmail = configTestEmail(mailObj(5)) 'PM
                    db.sendEmailNotification(sendEmail, subject, msgText)
                Case "GC Accept"
                    subject = "GC Accepted Solution:"
                    msgText = buildMsgText(NotifyType, "No", mailObj, rfiData)
                    sendEmail = configTestEmail(mailObj(2)) 'CM
                    db.sendEmailNotification(sendEmail, subject, msgText)
                    msgText = buildMsgText(NotifyType, "Yes", mailObj, rfiData)
                    sendEmail = configTestEmail(mailObj(5)) 'PM
                    db.sendEmailNotification(sendEmail, subject, msgText)
                Case "CM Complete"
                    subject = "RFI Complete:"
                    msgText = buildMsgText(NotifyType, "Yes", mailObj, rfiData)
                    sendEmail = configTestEmail(mailObj(5)) 'PM
                    db.sendEmailNotification(sendEmail, subject, msgText)
                Case Else
            End Select
        End Using
    End Sub
    
    Private Function buildMsgText(NotifyType As String, isCopy As String, mailObj As Object, rfiData As DataTable) As String
        Dim msgText As String = ""
        Dim subject As String = ""
        Dim DPName As String = ""
        
        Select Case NotifyType
            Case "New RFI"
                msgText = "A New RFI has been created by " & rfiData.Rows(0).Item("FromName") & vbCrLf & vbCrLf
                msgText &= "RFI Number: " & rfiData.Rows(0).Item("RefNumber") & vbCrLf
                msgText &= "Sent On: " & rfiData.Rows(0).Item("ReceivedOn") & vbCrLf & "Required By: " & rfiData.Rows(0).Item("RequiredBy") & vbCrLf
                msgText &= "Sender Email: " & rfiData.Rows(0).Item("Email") & vbCrLf & "Sender Phone: " & rfiData.Rows(0).Item("Phone1") & vbCrLf & vbCrLf
                msgText &= "Work Flow Position: CM:Review Pending" & vbCrLf & vbCrLf
            Case "Send DP"
                msgText = "A RFI has been assigned and sent to a design professional for processing." & vbCrLf & vbCrLf
                msgText &= "RFI Number: " & rfiData.Rows(0).Item("RefNumber") & vbCrLf
                msgText &= "DP Forward Date: " & rfiData.Rows(0).Item("ToDPReleaseDate") & vbCrLf & vbCrLf
                msgText &= "Design Professional: " & mailObj(6) & vbCrLf
                msgText &= "Phone Number: " & mailObj(7) & vbCrLf & "Email: " & mailObj(8) & vbCrLf
                msgText &= "Work Flow Position: DP:Response Pending" & vbCrLf & vbCrLf
            Case "DP Send CM"
                msgText = "A Request Solution has been prepared by a design professional and released to the Construction Manager." & vbCrLf & vbCrLf
                msgText &= "RFI Number: " & rfiData.Rows(0).Item("RefNumber") & vbCrLf
                msgText &= "DP Returned Date: " & rfiData.Rows(0).Item("ReturnedOn") & vbCrLf & vbCrLf
                msgText &= "Construction Manager: " & mailObj(0) & vbCrLf
                msgText &= "Phone Number: " & mailObj(1) & vbCrLf & "Email: " & mailObj(2) & vbCrLf
                msgText &= "Work Flow Position: CM:Distribution Pending" & vbCrLf & vbCrLf
            Case "CM Forward GC"
                msgText = "A Request Solution has been sent to the general contractor." & vbCrLf & vbCrLf
                msgText &= "RFI Number: " & rfiData.Rows(0).Item("RefNumber") & vbCrLf
                msgText &= "CM Distribution Date: " & rfiData.Rows(0).Item("ToGCReleaseDate") & vbCrLf & vbCrLf
                msgText &= "General Contractor: " & rfiData.Rows(0).Item("FromName") & vbCrLf
                msgText &= "Phone Number: " & rfiData.Rows(0).Item("Phone1") & vbCrLf & "Email: " & rfiData.Rows(0).Item("Email") & vbCrLf
                msgText &= "Work Flow Position: GC:Acceptance Pending" & vbCrLf & vbCrLf
            Case "GC Accept"
                msgText = "The general contractor has accepted the solution for this RFI." & vbCrLf & vbCrLf
                msgText &= "RFI Number: " & rfiData.Rows(0).Item("RefNumber") & vbCrLf
                msgText &= "GC Accept Date: " & rfiData.Rows(0).Item("RequestReleaseDate") & vbCrLf & vbCrLf
                msgText &= "Construction Manager: " & mailObj(0) & vbCrLf
                msgText &= "Phone Number: " & mailObj(1) & vbCrLf & "Email: " & mailObj(2) & vbCrLf
                msgText &= "Work Flow Position: CM:Completion Pending" & vbCrLf & vbCrLf
            Case "CM Complete"
                msgText = "The Consturction manager has closed this RFI. No additional action is required." & vbCrLf & vbCrLf
                msgText &= "RFI Number: " & rfiData.Rows(0).Item("ClosedOn") & vbCrLf
                msgText &= "Completion Date: " & rfiData.Rows(0).Item("RequestReleaseDate") & vbCrLf & vbCrLf
                msgText &= "Work Flow Position: Complete" & vbCrLf & vbCrLf
            Case Else
                
        End Select
        If isCopy = "No" Then
            msgText &= "Records indicate that this is now in your work flow." & vbCrLf & vbCrLf
        End If
        msgText &= "http://promptdev.maasco.com" & vbCrLf
        msgText &= "This is a curtosy notification" & vbCrLf & "Maasco RFI Tracking Systems" & vbCrLf & "Do Not Reply To This Message"
         
        Return msgText
    End Function
    
    Private Function configTestEmail(email As String) As String
        Dim sendEmail As String
        
        Select Case email
            Case "mac@nothing.com"
                sendEmail = "scottmckown@maasco.com"
            Case "ryan@nothing.com"
                sendEmail = "scottmckown@maasco.com"
            Case "mckool@nothing.com"
                sendEmail = "scottmckown@maasco.com"
            Case "smith@nothing.com", "jsmith@nothing.com"
                sendEmail = "scottmckown@maasco.com"
            Case Else
                sendEmail = "scottmckown@maasco.com"
        End Select
        
        Return sendEmail
    End Function
                    
    Private Sub mailTest_click() Handles mailTest.Click
        processNotifications("GC Accept")
    End Sub
    
    Public Sub ContractDropDown_Change() Handles cboContractID.SelectedIndexChanged
        nContractID = cboContractID.SelectedValue
        'labelContractID.Text = nContractID
        configNewDropdown()
    End Sub
    
    Public Sub configNewDropdown()
        'lblMessage.Text = nContractID
        butSend.Visible = False
        If cboContractID.SelectedValue <> 0 Then
            WorkFlowPosition = "New"
            refreshActionDropdown("")
            createRFInumber()
            Using db As New RFI
                parentID = db.GetSuggestedNextRefNumber()
            End Using
            
            'updateRequestAttachment(Rev, parentID, True)
            reqUpload = True
            updateRequestAttachment(Rev, nRFIID, reqUpload)
            QuestionAttachments.Visible = False
            butCloseUpload.Visible = False
            butSave.Visible = True
            butSave.ImageUrl = "images/button_create.gif"
        Else
            lblQAttachments.Visible = False
            QuestionAttachments.Visible = False
            cboAcceptRevise.Visible = False
            lblAcceptRevise.Visible = False
            cboContractID.OpenDropDownOnLoad = "True"
        End If
    End Sub
    
    Private Sub processLineItemAugment()
        Dim augment As String
        If chkAugment.Checked = True Then
            augment = "True"
        Else
            augment = "False"
        End If
        Using db As New RFI
            db.updateLineItemAugment(nRFIID, augment)
        End Using
    End Sub
     
    Private Sub closeWindow()
        If Session("ContactType") = "ProjectManager" Then
            processLineItemAugment()
        End If
        Session("RtnFromEdit") = True
        ProcLib.CloseAndRefreshRADNoPrompt(Page)
    End Sub
    
    Private Sub butClose_Click() Handles butClose.Click
        If Session("ContactType") = "ProjectManager" Then
            processLineItemAugment()
        End If
        Session("RtnFromEdit") = True
        ProcLib.CloseAndRefreshRADNoPrompt(Page)
    End Sub

    Private Sub createPrintOut()
        Dim zObj As Object
        Dim strOut As String = ""
        
        Using db As New RFI
            zObj = db.getRFIQAndAData(nRFIID)
        End Using
        'strOut = "RFI Number: " & RefNum.Text & vbCrLf
        
        'roRFIDetail.Text = strOut
        
    End Sub
      
    Private Sub butDelete_Click(ByVal sender As System.Object, ByVal e As System.Web.UI.ImageClickEventArgs) Handles butDelete.Click
     
        Using db As New RFI
            'db.CallingPage = Page
            'db.DeleteRFI(nProjectID, nRFIID)
        End Using

        Session("RtnFromEdit") = True
        ProcLib.CloseAndRefreshRADNoPrompt(Page)
    End Sub
    
    Private Sub SubmittedToChange() Handles cboSubmittedToID.SelectedIndexChanged
        'WorkFlowPosition = Trim(roStatus.Text)
        'getEditData()
        If sendButton.Value = "CMSaveReleaseDP" Then
            txtProposed.Text = Session("txtProposed")
            
        End If
        Dim subSelect As Integer = cboSubmittedToID.SelectedIndex
        cboSubmittedToID.OpenDropDownOnLoad = "False"
        
        If subSelect > 1 Or cboSubmittedToID.SelectedValue = "Unassigned" Then
            butSave.Visible = True
        End If
        QuestionAttachments.Visible = False
        
    End Sub
       
</script>
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
    <title id="PageTitle" ><% = sTitle%></title>
    <link href="Styles.css" type="text/css" rel="stylesheet" />
    <script src="/js/new_2014.js" type="text/javascript"></script>
    <script src="js/jquery-1.10.1.min.js" type="text/javascript"></script>
    <script type="text/javascript" language="javascript">
        $(document).ready(function () {
            var open = document.getElementById('showPrint').value;
            if (open === "Yes") {
                //if(document.getElementById('PrintRFI'){
                    document.getElementById('PrintRFI').style.display = 'block';
                //}
            } else {
                document.getElementById('PrintRFI').style.display = 'none';
            }
        });
        function writeToDiv() {
            if (document.getElementById('ShowAndHideHistory').innerHTML = 'Show History') {
                document.getElementById('divRFIHistory').style.display = 'block';
                document.getElementById('ShowAndHideHistory').innerHTML = 'Hide History';
                //document.getElementById('divRFIHistory').innerHTML = "";
            } else {
                document.getElementById('divRFIHistory').style.display = 'none';
                //document.getElementById('ShowAndHideHistory').innerHTML = 'Show History';
                //document.getElementById('ShowAndHideHistory')
                document.getElementById('divRFIHistory').innerHTML = '';
            }
        }
        function GetRadWindow() {
            var oWindow = null;
            if (window.RadWindow) oWindow = window.RadWindow;
            else if (window.frameElement.radWindow) oWindow = window.frameElement.radWindow;
            return oWindow;
        }

        /*Below JavaScript is for the "OtherDescription" element to only be editable if the CheckBox8 "OTHER" is checked David D 5/23/17 */
        function EnableOtherDesc(CheckBox8, OtherDescription) {

            if (document.getElementById("CheckBox8").checked)
                document.getElementById("OtherDescription").disabled = false;
            else
                document.getElementById("OtherDescription").disabled = true;
        }

    </script>
    <style type="text/css">
        .firefoxtext
        {
            font-size:13px;
        }
        .moveButton
        {
            top: 350px;
        }
        .floatingHelp
        {
            position: relative;
            display: none;
            height: 50px;
            width: 200px;
            padding: 10px;
            background-color: #926DB5;
            border-style: solid;
            border-width: 1px;
            top: 10px;
            left: 225px;
            box-shadow: 2px 2px 8px #000000;
            z-index: 900;
        }
        .checkBox
        {
            font-family: Arial;
        }
        .checkBox_bold
        {
            font-weight: bold;
        }
    </style>
</head>
<body>
    <form id="Form1" method="post" runat="server">
    <asp:Label ID="floatingHelp" class="floatingHelp" runat="server" Text="Select the contract from this drop down."></asp:Label>
    <telerik:RadComboBox ID="cboContractID" runat="server" Style="z-index: 605; left: 97px;
        position: absolute; top: 10px;" AutoPostBack="True" onselectedindexchange="ContractID_Change"
        Skin="Vista" Width="500px" TabIndex="0">
    </telerik:RadComboBox>
    <asp:HiddenField ID="conflictID" runat="server"></asp:HiddenField>
    <asp:HiddenField ID="saveButton" runat="server"></asp:HiddenField>
    <asp:HiddenField ID="sendButton" runat="server"></asp:HiddenField>
    <asp:HiddenField ID="activeEditWFP" runat="server"></asp:HiddenField>
    <asp:HiddenField ID="showPrint" runat="server"></asp:HiddenField>
    <asp:HiddenField ID="activeRevision" runat="server"></asp:HiddenField>
    <asp:HiddenField ID="refNumber" runat="server"></asp:HiddenField>    
    <asp:HiddenField ID="projectID" runat="server"></asp:HiddenField>
    <asp:HiddenField ID="sRequest" runat="server"></asp:HiddenField>
    <asp:HiddenField ID="sResponse" runat="server"></asp:HiddenField>
    <asp:HiddenField ID="testPlace" runat="server"></asp:HiddenField>

    <asp:Label ID="lblRFINum" Style="z-index: 105; left: 47px; position: absolute; top: 14px;font-weight:bold"
        runat="server" Height="24px">RFI #:</asp:Label>

    <asp:TextBox ID="txtRefNumber" Style="z-index: 103; left: 97px; position: absolute;
        top: 8px; width: 135px;" runat="server" Height="24px" TabIndex="1" Visible="false"
        CssClass="EditDataDisplay"></asp:TextBox>

    <asp:Label  runat="server" Style="position:absolute;left:242px;top:10px" Text="Label">Alt Ref #:</asp:Label>

    <asp:TextBox ID="txtAltRefNumber" Style="z-index: 103; left: 300px; position: absolute;
        top: 8px; width: 120px;text-align:left" runat="server" Height="24px" TabIndex="1" Visible="false"
        CssClass="EditDataDisplay"></asp:TextBox>


    <!--<asp:Label ID="RefNum" Style="z-index: 105; left: 230px; position: absolute; top: 13px"
        runat="server" Height="24px" Font-Bold="True" ForeColor="black" visible="true"></asp:Label>

    <asp:Label ID="RevisionNum" Style="z-index: 105; left: 330px; position: absolute; top: 13px"
        runat="server" Height="24px" Font-Bold="True" ForeColor="black" visible="true"></asp:Label>-->

    <asp:HyperLink ID="Flag" Style="z-index: 112; left: 820px; position: absolute; top: 5px;
        height: 20px;" runat="server" ImageUrl="images/button_flag.gif">Flag</asp:HyperLink>

    <asp:HyperLink ID="butHelp" Style="z-index: 112; left: 350px; position: absolute;
        top: 9px; height: 20px;" runat="server" ImageUrl="images/button_help.gif">HyperLink</asp:HyperLink>
    <asp:Label ID="Label2" Style="z-index: 105; left: 15px; position: absolute; top: 35px"
        runat="server" Height="24px">Created On:</asp:Label>
    <asp:Label ID="roReceivedOn" Style="z-index: 105; left: 85px; position: absolute;
        top: 35px; font-weight: bold" runat="server" Height="24px" Visible="false"></asp:Label>
    <telerik:RadDatePicker ID="txtReceivedOn" Style="z-index: 103; left: 97px; position: absolute;
        top: 39px;" runat="server" Width="120px" Skin="Web20" TabIndex="3">
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
    <asp:Label ID="Label7" Style="z-index: 105; left: 225px; position: absolute; top: 35px"
        runat="server" Height="24px">Required By:</asp:Label>
    <asp:Label ID="roRequiredBy" Style="z-index: 105; left: 300px; position: absolute;
        top: 35px; font-weight: bold" runat="server" Height="24px" Visible="false"></asp:Label>
    <telerik:RadDatePicker ID="txtRequiredBy" Style="z-index: 103; left: 300px; position: absolute;
        top: 35px" runat="server" Width="120px" Skin="Web20" TabIndex="4">
        <DateInput ID="DateInput2" runat="server" Skin="WebBlue" Font-Size="13px" ForeColor="Blue"
            TabIndex="4">
        </DateInput>
        <Calendar ID="Calendar2" runat="server" UseRowHeadersAsSelectors="False" UseColumnHeadersAsSelectors="False"
            ViewSelectorText="x" Skin="Web20">
            <SpecialDays>
                <telerik:RadCalendarDay Repeatable="Today">
                    <ItemStyle BackColor="LightBlue" />
                </telerik:RadCalendarDay>
            </SpecialDays>
        </Calendar>
        <DatePopupButton ImageUrl="" HoverImageUrl="" TabIndex="4"></DatePopupButton>
    </telerik:RadDatePicker>
    <!--<asp:Label ID="Label15" Style="z-index: 105; left: 14px; position: absolute; top: 58px"
        runat="server" Height="24px">WF Position:</asp:Label>

   <asp:Label ID="roStatus" Style="z-index: 105; left: 97px; position: absolute; top: 58px; font-weight: bold"
        runat="server" Height="24px" Visible="false"></asp:Label>-->
    <!--<asp:Label ID="lbl12345" Style="z-index: 105; left: 0px; position: absolute; top: 78px"
        runat="server" Height="24px">Revision Status:</asp:Label>

   <asp:Label ID="roRequestStatus" Style="z-index: 105; left: 97px; position: absolute; top: 78px; font-weight: bold"
        runat="server" Height="24px" Visible="false"></asp:Label>-->
    <telerik:RadComboBox ID="cboStatus" runat="server" Style="z-index: 505; left: 97px;
        position: absolute; top: 73px;" Skin="Vista" TabIndex="7" Visible="false" Text="(Status)"
        Filter="Contains" EnableLoadOnDemand="true" EmptyMessage="Select Action" >
        <Items>
            <telerik:RadComboBoxItem runat="server" Text="Pending" Value="Pending" />
            <telerik:RadComboBoxItem runat="server" Text="Answered" Value="Answered" />
        </Items>
    </telerik:RadComboBox>
    <asp:Label ID="lblAcceptRevise" Style="z-index: 105; left: 300px; position: absolute;
        top: 76px" runat="server" Height="24px" ForeColor="black" Visible="false">Action: </asp:Label>
    <asp:Label ID="conflictMessage" Style="z-index: 106; left: 85px; position: absolute;
        top: 90px; font-weight: bold; font-size: 14px; line-height: 15px; background-color: #ffffff;
        padding: 3px" runat="server" Height="50px" Width="327px" ForeColor="red" Visible="true">
    </asp:Label>
    <telerik:RadComboBox ID="cboAcceptRevise" Width="190" runat="server" Style="z-index: 506;
        left: 225px; position: absolute; top: 63px;" Skin="Vista" TabIndex="7" AutoPostBack="true"
        Filter="Contains" EnableLoadOnDemand="true" EmptyMessage="Select Action" 
        Visible="false">
    </telerik:RadComboBox>
    <asp:Label ID="printLabel" Style="z-index: 105; left: 425px; position: absolute;
        top: 38px" runat="server" Height="24px" Font-Bold="True" ForeColor="black" Visible="false">Printing Options</asp:Label>
    <asp:Label ID="Label8" Style="z-index: 105; left: 11px; position: absolute; top: 100px;
        width: 110px;" runat="server" Height="24px">Assigned To:</asp:Label>
    <asp:Label ID="roSubmittedToID" Style="z-index: 100; left: 85px; position: absolute;
        top: 100px; width: 150px; font-weight: bold" runat="server" Height="24px" Visible="false"></asp:Label>
    <telerik:RadComboBox ID="cboSubmittedToID" runat="server" Style="z-index: 505; left: 86px;
        position: absolute; top: 100px;" Skin="Vista" DropDownWidth="400px"
        Text="Action Select"
        MaxHeight="150px" AppendDataBoundItems="True" TabIndex="14" AutoPostBack="true">
        <HeaderTemplate>
            <table style="width: 390px; text-align: left">
                <tr>
                    <td style="width: 125px;">
                        Name
                    </td>
                    <td style="width: 225px;">
                        Company
                    </td>
                    <!--<td style="width: 125px;">
                                            Group
                                        </td>-->
                </tr>
            </table>
        </HeaderTemplate>
        <ItemTemplate>
            <table style="width: 350px; text-align: left">
                <tr>
                    <td style="width: 125px;">
                        <%#DataBinder.Eval(Container.DataItem, "Name")%>
                    </td>
                    <td style="width: 225px;">
                        <%#DataBinder.Eval(Container.DataItem, "Company")%>
                    </td>
                    <!--<td style="width: 125px;">
                                            <%#DataBinder.Eval(Container.DataItem, "TeamGroupName")%>
                                        </td>-->
                </tr>
            </table>
        </ItemTemplate>
    </telerik:RadComboBox>
    <asp:Label ID="lblSubmittedBy" Style="z-index: 105; left: 33px; position: absolute;
        top: 58px; width: 122px;" runat="server" Height="24px">Sent By:</asp:Label>
    <asp:Label ID="roTransmittedByID" Style="z-index: 105; left: 85px; position: absolute;
        top: 58px; width: 150px; font-weight: bold" runat="server" Height="24px" Visible="false"></asp:Label>
    <!--<asp:TextBox ID="roRFIDetailxx" Style="z-index: 120; left: 430px; position: absolute;
        top: 30px; height: 450px; width: 450px;" runat="server" TabIndex="20" CssClass="EditDataDisplay"
        TextMode="MultiLine" visible="true"></asp:TextBox>-->
    <asp:Panel ID="checkBoxContainer" runat="server" Style="position: absolute; left: 430px;
        top: 4px; border-style: solid; border-width: 0px; width: 450px; height: 110px;
        z-index: 100">
        <asp:CheckBox ID="CheckBox1" Checked="false" runat="server" Text="CIVIL" class="checkBox" />
        <asp:CheckBox ID="CheckBox2" runat="server" Text="ARCH" class="checkBox" />
        <asp:CheckBox ID="CheckBox3" runat="server" Text="STRUCT" class="checkBox" />
        <asp:CheckBox ID="CheckBox4" runat="server" Text="PLUMBING" class="checkBox" />
        <asp:CheckBox ID="CheckBox5" runat="server" Text="MECH" class="checkBox" />
        <asp:CheckBox ID="CheckBox6" runat="server" Text="FP" class="checkBox" /><br />
        <asp:CheckBox ID="CheckBox7" runat="server" Text="ELECT" class="checkBox" />
        <asp:CheckBox ID="CheckBox8" runat="server" Text="OTHER" class="checkBox" OnClick="EnableOtherDesc()" />
        <!--EnableOtherDesc() in above CheckBox8 is used to enable or disable the OtherDescription below David D 5/23/17-->
        <asp:TextBox ID="OtherDescription" runat="server" Style="height: 25px; width: 320px;"
            MaxLength="254"></asp:TextBox>
        <p />
        <asp:CheckBox ID="CheckBox9" runat="server" Text="INFORMATION NOT SHOWN ON CD'S"
            class="checkBox" />
        <asp:CheckBox ID="CheckBox10" runat="server" Text="COORDINATION PROBLEM" class="checkBox"
            Style="position: absolute; left: 250px" />
        <br />
        <asp:CheckBox ID="CheckBox11" runat="server" Text="INTERPRETATION OF CD'S" class="checkBox" />
        <asp:CheckBox ID="CheckBox12" runat="server" Text="POSSIBLE COST IMPACT" class="checkBox"
            Style="position: absolute; left: 250px" />
        <br />
        <asp:CheckBox ID="CheckBox13" runat="server" Text="CONFLICT CD'S" class="checkBox" />
        <asp:CheckBox ID="CheckBox14" runat="server" Text="POSSIBLE TIME IMPACT" class="checkBox"
            Style="position: absolute; left: 250px" />
    </asp:Panel>
    <asp:Label ID="lblHistory" Style="z-index: 105; left: 430px; position: absolute;
        top: 132px; width: 150px; font-weight: bold" runat="server" Height="24px" Visible="true">RFI History:</asp:Label>
    <!--<asp:Label id="printHide" style="position:absolute;left:800px;top:132px;hieght:10px;width:90px;border-style:solid;border-width:1px" ></asp:Label>-->
    <!--<a id="PrintRFIxxx" style="position: absolute; left: 800px; top: 132px; font-family: Aireal;
        font-weight: bold; text-decoration: none;" href="report_viewer.aspx?reportID=&RFIID="
        target="_blank">Print RFI</a>-->

    <asp:HyperLink ID="PrintRFI"  target="_blank" style="position: absolute; left: 800px; top: 132px; font-family: Aireal;
        font-weight: bold; text-decoration: none;" runat="server">Print RFI</asp:HyperLink>

    <!--David D 5/30/17 added overflow y and x, and word-wrap to Label ID="roRFIDetail" below to wrap text/words-->
    <asp:Label ID="roRFIDetail" Style="z-index: 105; left: 430px; position: absolute;
        top: 152px; width: 440px; font-weight: bold; background-color: #f2f5ff; padding: 5px;
        overflow-y: auto; overflow-x: auto; word-wrap: break-word;" runat="server" Height="390px"
        Visible="True"></asp:Label>
    <div id="divRFIHistory" style="position: absolute; left: 18px; width: 530px; height: 300px;
        top: 125px; z-index: 120; overflow-y: auto; background-color: #ffffff; display: none">
    </div>
    <asp:Panel ID="uploadPanel" runat="server" Visible="false" Style="z-index: 000; height: 370px;
        width: 445px; left: 430px; top: 132px; position: absolute; background-color: #e8e8e8">
        <asp:Label ID="lblUploadPanel" runat="server" Text="Contract Select:" Style="position: absolute;
            left: 5px; top: 0px; font-weight: bold">
        </asp:Label>
        <iframe id="uploadFrame1" src="" runat="server" style="position: absolute; width: 445px;
            height: 380px; top: 20px; border-style: none"></iframe>
    </asp:Panel>
    <!--<asp:Literal runat="server" id="RFIHistory"></asp:Literal>-->
    <asp:Label ID="lblMessage" Style="z-index: 105; left: 116px; position: absolute;
        top: 135px" runat="server" Height="24px" Font-Bold="True" ForeColor="Red">Error Message</asp:Label>
    <asp:Label ID="lblQuestion" Style="z-index: 105; left: 20px; position: absolute;
        top: 133px" runat="server" Height="24px">Original Question</asp:Label>

    <telerik:RadComboBox ID="multiQuestions" runat="server" Style="z-index: 105; left: 80px;
        position: absolute; top: 128px;" AutoPostBack="True" onselectedindexchange="multiQuestions_Change"
        
        Skin="Vista" Width="30px" TabIndex="6">
    </telerik:RadComboBox>
    <asp:Label ID="roQuestion" Style="z-index: 103; left: 18px; position: absolute; top: 153px;
        height: 50px; width: 390px; background-color: #f2f5ff; overflow: auto; padding: 5px"
        runat="server" TabIndex="12" CssClass="EditDataDisplay" TextMode="MultiLine"></asp:Label>
    <asp:TextBox ID="txtQuestion" Style="z-index: 103; left: 18px; position: absolute;
        top: 153px; height: 60px; width: 400px;resize:none" runat="server" TabIndex="12" CssClass="EditDataDisplay"
        TextMode="MultiLine"></asp:TextBox>
    <asp:Label ID="lblResolution" Style="z-index: 100; left: 20px; position: absolute;
        top: 216px" runat="server" Height="24px">Proposed Resolution:</asp:Label>
    <asp:Label ID="lblQAttachments" Style="z-index: 105; left: 160px; position: absolute;
        top: 216px" runat="server" Height="24px">Attachments (Count):</asp:Label>
    <!--<asp:HyperLink ID="QuestionAttachmentsxx" Style="z-index: 112; left: 310px; position: absolute;
        top: 216px; height: 20px;" runat="server" ImageUrl="images/button_upload_view.png"></asp:HyperLink>-->
    <asp:ImageButton ID="QuestionAttachments" Style="z-index: 107; left: 310px; position: absolute;
        top: 216px" TabIndex="99" runat="server" ImageUrl="images/button_upload_view.png"
        Visible="false"></asp:ImageButton>
    <asp:Label ID="requestAttachNum" Style="z-index: 105; left: 275px; position: absolute;
        top: 217px; font-weight: bold" runat="server" Height="24px" Visible="false">0</asp:Label>
    <asp:TextBox ID="txtProposed" Style="z-index: 103; left: 18px; position: absolute;
        top: 237px; height: 60px; width: 400px;resize:none" runat="server" TabIndex="12" CssClass="EditDataDisplay"
        TextMode="MultiLine"></asp:TextBox>
    <asp:Label ID="roProposed" Style="z-index: 103; left: 18px; position: absolute; top: 237px;
        height: 50px; width: 390px; background-color: #f2f5ff; padding: 5px; overflow-y: auto"
        runat="server" TabIndex="12" CssClass="EditDataDisplay" TextMode="MultiLine"
        Visible="false"></asp:Label>
    <asp:ImageButton ID="updateAnswer" Style="z-index: 107; left: 150px; position: absolute;
        top: 300px" TabIndex="99" runat="server" ImageUrl="images/update_answer.png"
        Visible="false"></asp:ImageButton>
    <asp:ImageButton ID="saveNewAnswer" Style="z-index: 107; left: 223px; position: absolute;
        top: 300px" TabIndex="99" runat="server" ImageUrl="images/save_new_answer.png"
        Visible="false"></asp:ImageButton>
    <asp:ImageButton ID="cancelNewAnswer" Style="z-index: 107; left: 363px; position: absolute;
        top: 300px" TabIndex="99" runat="server" ImageUrl="images/cancel_new_response.png"
        Visible="false"></asp:ImageButton>
    <asp:ImageButton ID="newAnswerButton" Style="z-index: 107; left: 380px; position: absolute;
        top: 300px" TabIndex="99" runat="server" ImageUrl="images/new_response_button.png"
        Visible="false"></asp:ImageButton>
    <!--<asp:ImageButton ID="showAllAnswers" Style="z-index: 107; left: 273px; position: absolute;
        top:300px" TabIndex="99" runat="server" 
        ImageUrl="images/all_answers.png" >
     </asp:ImageButton>-->
    <!--<asp:ImageButton ID="backToEditing" Style="z-index: 107; left: 350px; position: absolute;
        top:300px" TabIndex="99" runat="server" 
        ImageUrl="images/back_to_editing.png" Visible="false">
     </asp:ImageButton>-->
    <telerik:RadComboBox ID="multiAnswers" runat="server" Style="z-index: 115; left: 85px;
        position: absolute; top: 300px;" AutoPostBack="True" onselectedindexchange="multiAnswers_Change"        
        Skin="Vista" Width="35px" TabIndex="6">
    </telerik:RadComboBox>
    <asp:Label ID="Label10" Style="z-index: 105; left: 18px; position: absolute; top: 305px"
        runat="server" Height="24px">Response #:</asp:Label>
    <asp:Label ID="numAns" Style="z-index: 105; left: 125px; position: absolute; top: 305px"
        runat="server" Height="24px"></asp:Label>
    <asp:TextBox ID="txtAnswer" Style="z-index: 103; left: 18px; position: absolute;
        top: 325px; height: 90px; width: 400px;resize:none" runat="server" TabIndex="20" CssClass="EditDataDisplay"
        TextMode="MultiLine"></asp:TextBox>
    <asp:Label ID="roAnswer" Style="z-index: 103; left: 18px; position: absolute; top: 325px;
        height: 80px; width: 390px; background-color: #F2F5FF; overflow: auto; font-size: 12px;
        padding: 5px" runat="server" TabIndex="20" CssClass="EditDataDisplay" Visible="true">
    </asp:Label>
    <asp:Label ID="lblRespondedOn" Style="z-index: 105; left: 18px; position: absolute;
        top: 440px" runat="server" Height="24px">Responded On:</asp:Label>
    <asp:Label ID="roReturnedOn" Style="z-index: 105; left: 110px; position: absolute;
        top: 440px; font-weight: bold;" runat="server" Height="24px"></asp:Label>
    <asp:Label ID="lblReturnedBy" Style="z-index: 105; left: 20px; position: absolute;
        top: 460px" runat="server" Height="24px" Visible="false">Responded By:</asp:Label>
    <asp:Label ID="roReturnedBy" Style="z-index: 105; left: 110px; position: absolute;
        top: 460px; font-weight: bold;" runat="server" Height="24px" Visible="false"></asp:Label>
    <telerik:RadDatePicker ID="txtReturnedOn" Visible="false" Style="z-index: 103; left: 96px;
        position: absolute; top: 420px;" runat="server" Width="120px" Skin="Web20" TabIndex="30">
        <DateInput ID="DateInput3" runat="server" Skin="WebBlue" Font-Size="13px" ForeColor="Blue"
            TabIndex="30">
        </DateInput>
        <Calendar ID="Calendar3" runat="server" UseRowHeadersAsSelectors="False" UseColumnHeadersAsSelectors="False"
            ViewSelectorText="x" Skin="Web20">
            <SpecialDays>
                <telerik:RadCalendarDay Repeatable="Today">
                    <ItemStyle BackColor="LightBlue" />
                </telerik:RadCalendarDay>
            </SpecialDays>
        </Calendar>
        <DatePopupButton ImageUrl="" HoverImageUrl="" TabIndex="30"></DatePopupButton>
    </telerik:RadDatePicker>
    <asp:Label ID="lblResponseAttachments" Style="z-index: 105; left: 160px; position: absolute;
        top: 420px" runat="server" Height="24px">Attachments (Count):</asp:Label>
    <!--<asp:HyperLink ID="ResponseAttachmentsxx" Style="z-index: 112; left: 310px; position: absolute;
        top: 420px; height: 20px;" runat="server" ImageUrl="images/button_upload_view.png"></asp:HyperLink>-->
    <asp:ImageButton ID="ResponseAttachments" Style="z-index: 113; left: 310px; position: absolute;
        top: 420px" TabIndex="50" runat="server" ImageUrl="images/button_upload_view.png">
    </asp:ImageButton>
    <asp:Label ID="responseAttachNum" Style="z-index: 105; left: 275px; position: absolute;
        top: 421px; font-weight: bold" runat="server" Height="24px" Visible="false">0</asp:Label>
    <asp:ImageButton ID="butSave" Style="z-index: 113; left: 18px; position: absolute;
        top: 500px" TabIndex="50" runat="server" ImageUrl="images/button_save.png"></asp:ImageButton>
    <asp:ImageButton ID="butSend" Style="z-index: 113; left: 113px; position: absolute;
        top: 500px" TabIndex="50" runat="server" ImageUrl="images/button_send.png"></asp:ImageButton>
    <asp:ImageButton ID="butClose" Style="z-index: 113; left: 330px; position: absolute;
        top: 500px" runat="server" ImageUrl="images/button_cancel.png"></asp:ImageButton>
    <asp:ImageButton ID="butDelete" Style="z-index: 107; left: 273px; position: absolute;
        top: 500px" TabIndex="99" runat="server" Visible="false" OnClientClick="return confirm('You are about to delete this RFI.\nAre you sure you want to delete this RFI?')"
        ImageUrl="images/button_delete.gif"></asp:ImageButton>
    <asp:ImageButton ID="butCloseUpload" Style="z-index: 50; left: 775px; position: absolute;
        top: 530px" TabIndex="99" runat="server" ImageUrl="images/button_close.png" Visible="false">
    </asp:ImageButton>
    <asp:CheckBox ID="useDropdown" Style="z-index: 102; left: 300px; position: absolute;
        top: 470px" runat="server" runat="server" Text="Use Dropdown User" AutoPostBack="true" />
    <telerik:RadComboBox ID="cboTransmittedByID" runat="server" Style="z-index: 7505;
        left: 300px; position: absolute; top: 490px; width: 225px" Skin="Vista" Text="(Transmitted By)"
        Filter="Contains" EnableLoadOnDemand="true" EmptyMessage="Select Action" 
        DropDownWidth="475px" TabIndex="16" MaxHeight="150px" AutoPostBack="true">
        <HeaderTemplate>
            <table style="width: 300px; text-align: left">
                <tr>
                    <td style="width: 225px;">
                        Name
                    </td>
                    <!--<td style="width: 125px;">
                                            Company
                                        </td>
                                        <td style="width: 125px;">
                                            Group
                                        </td>-->
                </tr>
            </table>
        </HeaderTemplate>
        <ItemTemplate>
            <table style="width: 300px; text-align: left">
                <tr>
                    <td style="width: 225px;">
                        <%#DataBinder.Eval(Container.DataItem, "Name")%>
                    </td>
                    <!--<td style="width: 125px;">
                                            <%#DataBinder.Eval(Container.DataItem, "Company")%>
                                        </td>
                                        <td style="width: 125px;">
                                            <%#DataBinder.Eval(Container.DataItem, "TeamGroupName")%>
                                        </td>-->
                </tr>
            </table>
        </ItemTemplate>
    </telerik:RadComboBox>

   
    <asp:ImageButton ID="ShowHideHistory" Style="z-index: 107; left: 400px; position: absolute;
        top: 535px" TabIndex="99" runat="server" Visible="false" ImageUrl="images/button_show_history.png">
    </asp:ImageButton>
    <div id="ShowAndHideHistory" style="position: absolute; z-index: 108; height: 20px;
        width: 100px; top: 535px; left: 430; cursor: pointer; background-color: #ffffff;
        text-align: center; display: none" imageurl="Images/Show History Button.png"
        onclick="writeToDiv()">
    </div>
    <telerik:RadScriptManager ID="RadScriptManager1" runat="server" />
    <asp:ImageButton ID="mailTest" Style="z-index: 107; left: 520px; position: absolute;
        top: 500px" TabIndex="99" runat="server" Visible="false" ImageUrl="images/prompt_submittals.gif">
    </asp:ImageButton>  

    <asp:Label ID="printValidationMessage" Style="z-index: 105; left: 110px; position: absolute;
        top: 289px" runat="server" Height="24px" Font-Bold="True" ForeColor="Red"></asp:Label>
    <asp:Label ID="Label13" Style="z-index: 105; left: 388px; position: absolute; top: 70px"
        runat="server" Height="24px" Visible="false">Type:</asp:Label>    

    <asp:CheckBox ID="chkAugment" runat="server" style="position:absolute;top:535;left:10;line-height:15px;verical-align:middle" Text="   Augment RFI Line Item" class="checkBox"/>

    <asp:Label ID="lblCurrentUser" Style="z-index: 105; left: 180px; position: absolute;
        top: 535px" runat="server" Height="24px">Current User:</asp:Label>
        
    <asp:Label ID="lblUserDisplay" Style="z-index: 105; left: 250px; position: absolute;
        top: 535px" runat="server" Height="24px">Display</asp:Label>


    <asp:Label ID="Label9" Style="z-index: 105; left: 370px; position: absolute; top: 535px"
        runat="server" Height="24px">ID:</asp:Label>

    <asp:Label ID="lblxRFIID" Style="z-index: 105; left: 390px; position: absolute; top: 535px"
        runat="server" Height="24px"></asp:Label>
    </form>
</body>
</html>
