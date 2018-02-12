<%@ Page Language="vb" %>

<%@ Register Assembly="Telerik.Web.UI" Namespace="Telerik.Web.UI" TagPrefix="telerik" %>
<%@ Import Namespace="System.IO" %>
<%@ Import Namespace="System.IO.FileSystemInfo" %>
<%@ Import Namespace="Prompt" %>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">

<script runat="server">

    Private nMeetingID As Integer = 0
    Private nProjectID As Integer = 0
    Private nCollegeID As Integer = 0
    Private strPhysicalPath As String = ""
    Private strFilePath As String = ""
    Private sDisplayType As String = ""
    Private nContactID As Integer
    Private sTitle As String = ""
    Private sMeetingNumber As String = ""
    Private sMinutesFileName As String
    
    Private Sub Page_Load(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MyBase.Load
        
        ProcLib.CheckSession(Page)
        ProcLib.LoadPopupJscript(Page)

        Session("PageID") = "MeetingMinutesEdit"
        
        lblMessage.Text = ""

        If Session("addNew") = True Then
            nMeetingID = Session("NewID")
            nProjectID = Session("ProjID")
            sDisplayType = "Existing"
            Session("addNew") = Nothing
            Session("NewID") = Nothing
            Session("ProjID") = Nothing
            getData()
        Else
            nMeetingID = Request.QueryString("MeetingID")
            nProjectID = Request.QueryString("ProjectID")
            nCollegeID = Request.QueryString("CollegeID")
            sDisplayType = Request.QueryString("DisplayType")
            
        End If
        
        devDisplay.Text = "Project ID: " & nProjectID
        
        Using db As New RFI
            nContactID = db.getContactID(Session("UserID"), Session("DistrictID"))
            Dim ContactData As Object = db.getContactData(nContactID, Session("DistrictID"))
            Session("ParentContactID") = ContactData(0)
            Session("ContactType") = ContactData(1)
        End Using      
    
        'set up help button
        butHelp.Attributes("onclick") = "return ShowHelp();"
        butHelp.NavigateUrl = "#"

        If Not IsPostBack Then
            Using db As New MeetingMinute
                db.CallingPage = Page
                If nMeetingID = 0 Then
                    'butDelete.Visible = False
                Else
                    'db.GetMeetingMinuteEntryForEdit(nMeetingID)
                End If
            End Using
            
            If lblMinutesFileName.Text = "(None Attached)" Then
                'butRemoveFile.Visible = False
            Else
                'butRemoveFile.Visible = True
            End If
                            
            'buildMembersDropdown("Participants")
            buildMembersDropdown_B()
            Session("Members") = Nothing 
        End If
        
        With RadPopups
            .Skin = "Office2007"
            .VisibleOnPageLoad = False
            Dim ww As New RadWindow
            With ww
                .ID = "ShowHelpWindow"
                .NavigateUrl = ""
                .Title = ""
                .Width = 400
                .Height = 300
                .Top = 30
                .Left = 10
                .Modal = False
                .VisibleStatusbar = True
                .ReloadOnShow = True
                .Behaviors = WindowBehaviors.Close + WindowBehaviors.Move
            End With
            .Windows.Add(ww)
           
        End With
        
        txtMeetingDate.Focus()
        
        'If Not IsPostBack Then
        If sDisplayType = "Existing" Then
            If Session("UpdateData") <> True Then
                configExisting()
            Else
                Session("UpdateData") = Nothing
                
            End If
        ElseIf sDisplayType = "New" Then
            configNew()
        End If
        'End If
    End Sub
    
    Private Sub buildMembersDropdown_B()
        Dim switch As String
        Dim tbl As DataTable
        Dim tblChk As New DataTable
        Dim cboTbl As New DataTable
        
        cboTbl.Columns.Add("ContactID", GetType(System.Int32))
        cboTbl.Columns.Add("Name", GetType(System.String))
        cboTbl.Columns.Add("Company", GetType(System.String))
        
        If nProjectID = 0 Then
            Using db As New MeetingMinute
                tbl = db.getDistrictContacts(Session("DistrictID"))
            End Using
        Else
            Using db As New TeamMember
                tbl = db.GetExistingMembers(nProjectID)
            End Using
        End If     
        
        If Not IsPostBack Then
            switch = "Select Participants"
        Else
            switch = cboActionSelect.SelectedValue
        End If
               
        Using dbchk As New MeetingMinute
            For Each row As DataRow In tbl.Rows
                tblChk = dbchk.checkParticipant(nMeetingID, row.Item("ContactID"))
                
                If tblChk.Rows.Count > 0 Then
                    If switch = "Select Participants" Then
                        If tblChk.Rows(0).Item("IsActive") = 0 Then
                            cboTbl.Rows.Add(row.Item("ContactID"), row.Item("Name"), row.Item("Company"))
                        End If
                    ElseIf switch = "Remove Participants" Then
                        If tblChk.Rows(0).Item("IsActive") = 1 Then
                            If tblChk.Rows(0).Item("IsLead") = 0 Then
                                cboTbl.Rows.Add(row.Item("ContactID"), row.Item("Name"), row.Item("Company"))
                            End If
                         End If
                    End If
                Else
                    If switch = "Select Participants" Then
                        cboTbl.Rows.Add(row.Item("ContactID"), row.Item("Name"), row.Item("Company"))
                    End If
                End If                                                                                                                
            Next            
        End Using
        
        Dim newrow As DataRow = cboTbl.NewRow
        newrow("ContactID") = 0
        newrow("Name") = "None"
        newrow("Company") = "None"
        cboTbl.Rows.InsertAt(newrow, 0)
 
        cboMeetingParticipants.Items.Clear()
        
        With cboMeetingParticipants
            .DataValueField = "ContactID"
            .DataTextField = "Name"
            .DataSource = cboTbl
            .DataBind()
        End With
        
    End Sub
    
    Private Sub buildMembersDropdown(ddType As String)
        Dim tbl As DataTable
        If ddType = "Participants" Then
            Using db As New TeamMember
                tbl = db.GetExistingMembers(nProjectID)
                tbl.DefaultView.Sort = "LastName"
                       
                Dim newrow As DataRow = tbl.NewRow
                newrow("ContactID") = 0
                newrow("TeamMemberID") = 0
                newrow("TeamGroupName") = "None"
                newrow("Name") = "None"
                tbl.Rows.InsertAt(newrow, 0)   'put it first
            End Using
            cboMeetingParticipants.Items.Clear()
        ElseIf ddType = "Permissions" Then
            Using db As New MeetingMinute
                Dim tblObj As Object = db.getMeetingParticipants(nMeetingID, nContactID)
                tbl = tblObj(4)
                cboMeetingParticipants.Items.Clear()
            End Using                                         
        End If
        
        With cboMeetingParticipants
            .DataValueField = "ContactID"
            .DataTextField = "Name"
            .DataSource = tbl
            .DataBind()
        End With
            
    End Sub
    
    Private Sub configExisting()
       
        If Not IsPostBack Then
            getData()
            configActionDropdown()
        End If
        
        txtMeetingDate.Visible = False
        roMeetingDate.Visible = True
        txtDescription.Visible = False
        roDescription.Visible = True
        cboDesignPhase.Visible = False
        
        If configType.Value <> "RO" Then
            cboActionSelect.Visible = True
            lblAction.Visible = True
        Else
            cboActionSelect.Visible = False
            lblAction.Visible = False
        End If
       
        roDesignPhase.Visible = True
        txtMeetingHistory.Visible = False
        lblComment.Visible = False
        txtComment.Visible = False
        uplMinutesFileName.Visible = False
                
        butSave.Visible = False
        butSaveComment.Visible = False
        cboMeetingParticipants.Visible = False
        roParticipants.Visible = True
        lblParticipants.Visible = True
        butAddParticipant.Visible = False
        roCurrentFile.Visible = True
        lblOrganizer.Visible = True
        roOrganizerDisplay.Visible = True
        lblSubPhase.Visible = True
        lblMinutesFile.Visible = True
        butDeleteFile.Visible = False
        cboDeleteFiles.Visible = False
        cboStatus.Visible = False
        roStatus.Visible = False
        lblStatus.Visible = False
        
        saveButton.Value = "UploadAttachment"
        commentButton.Value = "SaveComment"
       
        strPhysicalPath = ProcLib.GetCurrentAttachmentPath() & "DistrictID_" & HttpContext.Current.Session("DistrictID") & "/_apprisedocs/"
        strPhysicalPath &= "_meetingminutes/ProjectID_" & nProjectID & "/meetingID_" & nMeetingID
        
        strFilePath = ProcLib.GetCurrentRelativeAttachmentPath() & "DistrictID_" & HttpContext.Current.Session("DistrictID") & "/_apprisedocs/"
        strFilePath &= "_meetingminutes/ProjectID_" & nProjectID & "/meetingID_" & nMeetingID
        
        checkDirectory(strPhysicalPath)
        checkDirectory(strPhysicalPath & "\DeletedFiles")
        
        getAttachments()
       
        Dim alertText As String = ""
        
        Select Case Trim(cboActionSelect.SelectedValue)
            Case "none"
                getData()
                txtMeetingDate.Visible = False
                txtDescription.Visible = False
                cboDesignPhase.Visible = False
                roMeetingDate.Visible = True
                roDescription.Visible = True
                cboSubDesign.Visible = False
                roSubDesign.Visible = True
                butSave.Visible = False
                cboMeetingParticipants.SelectedValue = "None"
            Case "Edit Meeting"
                txtMeetingDate.Visible = True
                txtDescription.Visible = True
                cboDesignPhase.Visible = True
                roMeetingDate.Visible = False
                roDescription.Visible = False
                roCurrentFile.Visible = True
                cboActionSelect.Visible = True
                roStatus.Visible = False
                cboStatus.Visible = False
                cboSubDesign.Visible = False
                roSubDesign.Visible = False
                alertText = "This action will save any changes you made.\n\nDo you want to continue?"
                butSave.OnClientClick = "return confirm('" & alertText & "')"
                butSave.Visible = True
                butSave.ImageUrl = "images/button_save.png"
                saveButton.Value = "Existing"
            Case "Edit Meeting Participants", "Remove Participants"
                If Session("Members") <> "Edit Participants" Then
                    buildMembersDropdown_B()
                    Session("Members") = "Edit Participants"
                End If
                cboMeetingParticipants.Visible = True
                If cboMeetingParticipants.SelectedValue = 0 Then
                    lblOrganizer.Visible = True
                Else
                    butAddParticipant.Visible = True
                    alertText = "This action will Remove the selected participant\nfrom your Meeting Participants List.\n\nDo you want to continue?"
                    butAddParticipant.OnClientClick = "return confirm('" & alertText & "')"
       
                End If
                saveButton.Value = ""
            Case "Edit Meeting Participants", "Select Participants"
                If Session("Members") <> "Edit Participants" Then
                    buildMembersDropdown_B()
                    Session("Members") = "Edit Participants"
                End If
                cboMeetingParticipants.Visible = True
                If cboMeetingParticipants.SelectedValue = 0 Then
                    lblOrganizer.Visible = True
                Else
                    butAddParticipant.Visible = True
                    alertText = "This action will Add the selected participant\nto your Meeting Participants List.\n\nDo you want to continue?"
                    butAddParticipant.OnClientClick = "return confirm('" & alertText & "')"
       
                End If
                saveButton.Value = ""
            Case "Assign Upload Permissions"
                Using db As New MeetingMinute
                    If Session("Members") <> "Assign Permissions" Then
                        buildMembersDropdown_B()
                        Session("Members") = "Assign Permissions"
                    End If
                End Using
                cboMeetingParticipants.Visible = True
                If cboMeetingParticipants.SelectedValue = 0 Then
                    butAddParticipant.Visible = False
                Else
                    butAddParticipant.Visible = True
                End If
                
            Case "Set List Minutes"
                alertText = "This action will set the list Minutes document\nto the current file selected document.\n\nDo you want to continue?"
                butSave.OnClientClick = "return confirm('" & alertText & "')"
                saveButton.Value = "SetMinutes"
                butSave.Visible = True
                butSave.ImageUrl = "images/button_save.png"
                'cboCurrentFile.Visible = False
                roCurrentFile.Visible = True
            Case "Upload Minutes"
                uplMinutesFileName.Visible = True
                saveButton.Value = "UploadAttachment"
                butAddParticipant.Visible = True
                butAddParticipant.ImageUrl = "images/button_upload.png"
                alertText = "This action will upload the selected files\nto the meeting minutes directory.\n\nDo you want to continue?"
                butAddParticipant.OnClientClick = "return confirm('" & alertText & "')"
            Case "Upload Supporting Documents"
                uplMinutesFileName.Visible = True
                saveButton.Value = "UploadSupportAttachment"
                butAddParticipant.Visible = True
                butAddParticipant.ImageUrl = "images/button_upload.png"
                alertText = "This action will upload the selected files\nto your supporting documents directory.\n\nDo you want to continue?"
                butAddParticipant.OnClientClick = "return confirm('" & alertText & "')"
            Case "Remove Meeting Minutes"
                cboDeleteFiles.Visible = True
                butDeleteFile.Visible = True
                saveButton.Value = "RemoveMeetingFile"
                If Session("FileDelete") = True Then
                    Session("FileDelete") = Nothing
                Else
                    bindFileDropdown(buildDirFileDropdown(strPhysicalPath), cboDeleteFiles)
                End If
                alertText = "This action will remove the selected file from the meeting minutes directory.\nThis document will no longer be available.\n\nDo you want to continue?"
                butDeleteFile.OnClientClick = "return confirm('" & alertText & "')"
            Case "Remove Supporting Documents"
                cboDeleteFiles.Visible = True
                butDeleteFile.Visible = True
                saveButton.Value = "RemoveSupportingFile"
                If Session("FileDelete") = True Then
                    Session("FileDelete") = Nothing
                End If
                alertText = "This action will remove the selected file from your supporting documents directory.\nThis document will no longer be availabe.\n\nDo you want to continue?"
                butDeleteFile.OnClientClick = "return confirm('" & alertText & "')"
            Case Else
                
        End Select
    End Sub
    
    Private Sub configActionDropdown()
        Dim tbl As DataTable
        tbl = New DataTable("tbl")
        tbl.Columns.Add("Action", GetType(System.String))
        tbl.Columns.Add("ActionText", GetType(System.String))
        tbl.Rows.Add("none", "Review")
        
        Select Case configType.Value
            Case "PM"
                tbl.Rows.Add("Edit Meeting", "Edit Meeting")
                'tbl.Rows.Add("Edit Meeting Participants", "Edit/Select Participants")
                tbl.Rows.Add("Select Participants", "Add Participants")
                tbl.Rows.Add("Remove Participants", "Remove Participants")
                tbl.Rows.Add("Upload Minutes", "Upload Minutes")
                tbl.Rows.Add("Upload Supporting Documents", "Upload Supporting Documents")              
                tbl.Rows.Add("Remove Supporting Documents", "Remove Supporting Documents")
            Case "RO"
            Case "Upload"
                tbl.Rows.Add("Upload Supporting Documents", "Upload Supporting Documents")
                tbl.Rows.Add("Remove Supporting Documents", "Remove Supporting Documents")
            Case "Organizer"
                tbl.Rows.Add("Edit Meeting", "Edit Meeting")
                'tbl.Rows.Add("Edit Meeting Participants", "Edit/Select Participants")
                tbl.Rows.Add("Select Participants", "Add Participants")
                tbl.Rows.Add("Remove Participants", "Remove Participants")
                tbl.Rows.Add("Upload Minutes", "Upload Minutes")
                tbl.Rows.Add("Upload Supporting Documents", "Upload Supporting Documents")                
                tbl.Rows.Add("Remove Supporting Documents", "Remove Supporting Documents")
        End Select
        With cboActionSelect
            .DataValueField = "Action"
            .DataTextField = "ActionText"
            .DataSource = tbl
            .DataBind()
        End With
    End Sub
   
    Private Sub configPhaseDropdowns(DesignPhase As String, editType As String)
        Dim tbl As DataTable
        tbl = New DataTable("tbl")
        tbl.Columns.Add("Action", GetType(System.String))
        tbl.Columns.Add("ActionText", GetType(System.String))
        tbl.Rows.Add("None Selected", "None Selected")
        
        Select Case DesignPhase
            Case "Not Selected"
                cboSubDesign.Visible = False
                roSubDesign.Visible = True
            Case "Pre-Design", "Bidding", "Construction"
                cboSubDesign.Visible = False
                roSubDesign.Visible = True
            Case "Design"
                If editType = "edit" Then
                    cboSubDesign.Visible = True
                    roSubDesign.Visible = False
                Else
                    cboSubDesign.Visible = False
                    roSubDesign.Visible = True
                End If
                tbl.Rows.Add("Programming", "Programming")
                tbl.Rows.Add("Schematic Design", "Schematic Design")
                tbl.Rows.Add("Design Development", "Design Development")
                tbl.Rows.Add("Construction Documents", "Construction Documents")
                'tbl.Rows.Add("DSA Review", "DSA Review")
                
            Case "Close Out"
                If editType = "edit" Then
                    cboSubDesign.Visible = True
                    roSubDesign.Visible = False
                Else
                    cboSubDesign.Visible = False
                    roSubDesign.Visible = True
                End If
                tbl.Rows.Add("DSA", "DSA")
                tbl.Rows.Add("LEED", "LEED")
                tbl.Rows.Add("Commissioning", "Commissioning")
                tbl.Rows.Add("Relocations", "Relocations")
                
            Case Else
                cboSubDesign.Visible = False
                roSubDesign.Visible = True
        End Select
        
        If editType = "edit" Then
            With cboSubDesign
                .DataValueField = "Action"
                .DataTextField = "ActionText"
                .DataSource = tbl
                .DataBind()
            End With
            cboSubDesign.SelectedValue = roSubDesign.Text
            
        End If
    End Sub
    
    Private Sub cboDesignPhase_Change() Handles cboDesignPhase.SelectedIndexChanged
        Dim editType As String = ""
        If cboActionSelect.SelectedValue = "Edit Meeting" Or sDisplayType = "New" Then
            editType = "edit"
        Else
            editType = "ro"
        End If
        configPhaseDropdowns(cboDesignPhase.SelectedValue, editType)       
    End Sub
    
    Private Sub cboActionSelect_Change() Handles cboActionSelect.SelectedIndexChanged
        'Dim alertText As String
        Session("PhaseCheck") = "ON"      
        cboDesignPhase_Change()
        
        Select Case cboActionSelect.SelectedValue
            Case "Select Participants", "Remove Participants"
                Session("Members") = "Edit Participants"
                buildMembersDropdown_B
            Case "Remove Meeting Minutes"
                checkDirectory(strPhysicalPath & "\DeletedFiles")
                bindFileDropdown(buildDirFileDropdown(strPhysicalPath), cboDeleteFiles)
            Case "Remove Supporting Documents"
                checkDirectory(strPhysicalPath & "\" & nContactID)
                bindFileDropdown(buildDirFileDropdown(strPhysicalPath & "/" & nContactID), cboDeleteFiles)
            Case Else
                cboMeetingParticipants.SelectedValue = 0
        End Select
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
           
    Private Sub getAttachments()
        Dim curUl As String = (HttpContext.Current.Request.Url.Host).ToString()
        Dim port As String = (HttpContext.Current.Request.Url.Port).ToString()
        Dim protocol As String = ConfigurationManager.AppSettings("Protocol")
        
        
        Dim tbl As DataTable
        tbl = New DataTable("tbl")
        tbl.Columns.Add("Action", GetType(System.String))
        tbl.Columns.Add("ActionText", GetType(System.String))
        tbl.Rows.Add("None Selected", "None Selected")
                     
        Try ' getting meeting minutes
            Dim dinfo As New IO.DirectoryInfo(strPhysicalPath)
            Dim finfo As IO.FileInfo() = dinfo.GetFiles()
            Dim dra As IO.FileInfo
            Dim path As String          
            
            If protocol = "https://" Then
                'path = "<a href='https://" & curUl & "/" & strFilePath & "/"
                path = "<a href='" & protocol & curUl & "/" & strFilePath & "/"
            Else
                If port = "" Then
                    curUl = curUl & "/"
                Else
                    curUl = curUl & ":" & port & "/" 'This blows the url online with SSL
                End If
                path = "<a href='" & protocol & curUl & strFilePath & "/"
            End If
            
            Dim strFiles As String = ""
            Dim Icon As String = ""
            
            For Each dra In finfo
                Icon = "<img src='images/" & getFileImage(dra.ToString()) & "'/>"
                strFiles &= path & dra.ToString() & "'>" & Icon & "&nbsp;&nbsp;" & dra.ToString() & "</a><br/>"
                tbl.Rows.Add(dra.ToString(), dra.ToString())
            Next
            'showAttachments.Text = strFiles
                                   
        Catch ex As Exception
            'showAttachments.Text = "No Files Found!"
            'showAttachments.Text = "Exception Caught"
            'bindFileDropdown(tbl)
        End Try
        
        Try 'getting supporting attachments        
            Dim dinfo As New IO.DirectoryInfo(strPhysicalPath)
            Dim dirs() As IO.DirectoryInfo = dinfo.GetDirectories()
            Dim strFiles As String = ""
            Dim finfo As IO.FileInfo()
            Dim icon As String
            'Dim path As String = "<a href='http://" & curUl & strFilePath & "/"
            
            Dim path As String = "<a href='" & protocol & curUl & "/" & strFilePath & "/"
            
            For Each Dir As IO.DirectoryInfo In dirs
                If Dir.Name <> "DeletedFiles" Then
                                 
                    Using db As New RFI
                        Try
                       
                            Dim dirInfo As New IO.DirectoryInfo(strPhysicalPath & "/" & Dir.Name)
                            finfo = dirInfo.GetFiles()
                            Dim count As Integer = 0
                            For Each dra As IO.FileInfo In finfo
                                count = count + 1
                            Next
                        
                            If count > 0 Then
                                'strFiles &= db.getResponderName(Dir.Name) & "<br/>"
                        
                                For Each dra As IO.FileInfo In finfo
                                    icon = "<img src='images/" & getFileImage(dra.ToString()) & "'/>"
                                    strFiles &= path & Dir.Name & "/" & dra.ToString() & "'>" & icon & "&nbsp;&nbsp;" & dra.ToString() & "</a><br/>"
                                Next
                            End If
                        Catch ex As Exception
                        End Try
                    End Using
                    
                End If
            Next
            If strFiles = "" Then
                supportingAttachments.Text = "No Files Found!"
            Else
                supportingAttachments.Text = strFiles
            End If
            
        Catch ex As Exception
            'supportingAttachments.Text = "No Files Found!"
            supportingAttachments.Text = "Exception Caught."
        End Try
       
        
        If Not IsPostBack Then
            Try
                'bindFileDropdown(tbl, cboCurrentFile)
            Catch ex As Exception
            End Try
        End If
        If Session("FileUpload") = True Then
            'bindFileDropdown(tbl, cboCurrentFile)
            Session("FileUpload") = Nothing
        End If
               
    End Sub
    
    Private Sub bindFileDropdown(tbl As DataTable, comboName As Telerik.Web.UI.RadComboBox)
        With comboName
            .DataValueField = "Action"
            .DataTextField = "ActionText"
            .DataSource = tbl
            .DataBind()
        End With
    End Sub
    
    Private Function buildDirFileDropdown(dir As String) As DataTable
        
        Dim tbl As DataTable
        tbl = New DataTable("tbl")
        tbl.Columns.Add("Action", GetType(System.String))
        tbl.Columns.Add("ActionText", GetType(System.String))
        tbl.Rows.Add("None Selected", "None Selected")
        
        Dim dinfo As New IO.DirectoryInfo(dir)
        Dim finfo As IO.FileInfo() = dinfo.GetFiles()
        Dim dra As IO.FileInfo
        
        For Each dra In finfo
            tbl.Rows.Add(dra.ToString(), dra.ToString())
        Next
        
        Return tbl        
    End Function
    
    Private Sub getData()
        Dim curUl As String = (HttpContext.Current.Request.Url.Host).ToString()
        Dim port As String = (HttpContext.Current.Request.Url.Port).ToString()
        Dim protocal As String = ConfigurationManager.AppSettings("Protocol")
        
       
        
        Dim path As String
        
        If protocal = "https://" Then
            path = "<a href='https://" & curUl & "/" & strFilePath & "/"
        Else
            If port = "" Then
                curUl = curUl & "/"
            Else
                curUl = curUl & ":" & port & "/"
            End If
            path = "<a href='http://" & curUl & strFilePath & "/"
        End If
                    
        Dim mData As DataTable
        Using db As New MeetingMinute
            Dim ProjName As String
            
            mData = db.getMeetingData(nProjectID, nMeetingID)
            txtMeetingHistory.Text = db.buildMeetingComments(nProjectID, nMeetingID)
            
            If nProjectID = 0 Then
                ProjName = db.getCollegeName(Session("CollegeID"))
            Else
                ProjName = db.getProjectName(nProjectID)
            End If
            
            sTitle = ProjName & " -  Edit Meeting Minutes - " & mData.Rows(0).Item("Meetingnumber")
            sMeetingNumber = mData.Rows(0).Item("MeetingNumber")
            Dim obj As Object = db.getMeetingParticipants(nMeetingID, nContactID)
            roParticipants.Text = obj(0)
            roOrganizerDisplay.Text = obj(1)
            'lblOrgCompany.Text = obj(2)
            If mData.Rows(0).Item("MinutesFileName") = "None Selected" Then
                path = "None Selected"
            Else
                path &= mData.Rows(0).Item("MinutesFileName") & "'>" & mData.Rows(0).Item("MinutesFileName") & "</a>"
                sMinutesFileName = mData.Rows(0).Item("MinutesFileName")
            End If
                        
            Select Case Session("ContactType")
                Case "Program Manager"
                     configType.Value = "PM"
                Case "ProjectManager"
                    configType.Value = "PM"
                Case "Construction Manager"
                    If mData.Rows(0).Item("CreatedBy") = nContactID Then
                        configType.Value = "PM"
                    ElseIf obj(3) = nContactID Then
                        configType.Value = "Organizer"
                    ElseIf obj(5) = True Then
                        configType.Value = "Upload"
                    Else
                        configType.Value = "RO"
                    End If
                Case "Design Professional"
                    If mData.Rows(0).Item("CreatedBy") = nContactID Then
                        configType.Value = "PM"
                    ElseIf obj(3) = nContactID Then
                        configType.Value = "Organizer"
                    ElseIf obj(5) = True Then
                        configType.Value = "Upload"
                    Else
                        configType.Value = "RO"
                    End If
                Case Else
                    If obj(3) = nContactID Then
                        configType.Value = "Organizer"
                    Else
                        If obj(5) = True Then
                            configType.Value = "Upload"
                        Else
                            configType.Value = "RO"
                        End If
                    End If
            End Select
            
            'This overrides the previous settings as there are no other views.
            Dim ConType As String
            Using dba As New RFI
                Dim contInfo As Object = dba.getContactData(nContactID, Session("DistrictID"))
                ConType = contInfo(1)
            End Using
            
            If obj(3) = nContactID Then
                configType.Value = "Organizer"
            ElseIf ConType = "Program Manager" Then
                Using dba As New RFI
                    Dim contInfo As Object = dba.getContactData(obj(3), Session("DistrictID"))
                    If contInfo(1) = "ProjectManager" Then
                        configType.Value = "Organizer"
                    Else
                        configType.Value = "RO"
                    End If
                End Using
            Else
                configType.Value = "RO"
            End If
        End Using
        
        roMeetingDate.Text = mData.Rows(0).Item("MeetingDate")
        txtMeetingDate.DbSelectedDate = mData.Rows(0).Item("MeetingDate")
        roDescription.Text = mData.Rows(0).Item("Description")
        txtDescription.Text = mData.Rows(0).Item("Description")
        roDesignPhase.Text = mData.Rows(0).Item("DesignPhase")
        cboDesignPhase.SelectedValue = mData.Rows(0).Item("DesignPhase")
        lblMinutesFileName.Text = mData.Rows(0).Item("MinutesFileName")
        'roMeetingNumber.Text = mData.Rows(0).Item("MeetingNumber")
        roCurrentFile.Text = path
        'cboCurrentFile.SelectedValue = mData.Rows(0).Item("MinutesFileName")
        cboSubDesign.SelectedValue = mData.Rows(0).Item("PhaseSubCategory")
        roSubDesign.Text = mData.Rows(0).Item("PhaseSubCategory")
        'chkOrganizer.Checked = False
        configPhaseDropdowns(mData.Rows(0).Item("DesignPhase"), "ro")
        roStatus.Text = mData.Rows(0).Item("Status")
        cboStatus.SelectedValue = mData.Rows(0).Item("Status")
        
    End Sub
    
    Private Sub configNew()
        txtMeetingDate.Visible = True
        roMeetingDate.Visible = False
        txtDescription.Visible = True
        roDescription.Visible = False
        txtMeetingHistory.Visible = False
        lblComment.Visible = False
        txtComment.Visible = False
        butSaveComment.Visible = False
        devDisplay.Visible = False
        butSave.Visible = True
        uplMinutesFileName.Visible = False
        cboMeetingParticipants.Visible = False
        lblAction.Visible = False
        cboActionSelect.Visible = False
        butAddParticipant.Visible = False
        cboSubDesign.Visible = False
        'cboCurrentFile.Visible = False
        lblMinutesFile.Visible = True
        lblSubPhase.Visible = False
        'lblMinutesAttachments.Visible = False
        lblMinutesFile.Visible = False
        lblSupportingAttachments.Visible = False
        supportingAttachments.Visible = False
        lblStatus.Visible = False
        roStatus.Visible = False
        cboStatus.Visible = False
               
        saveButton.Value = "New"
        Using db As New MeetingMinute
            Dim ProjName As String
            If nProjectID = 0 Then
                ProjName = db.getCollegeName(Session("CollegeID"))
            Else
                ProjName = db.getProjectName(nProjectID)
            End If
            
            sTitle = ProjName & " -  Create Meeting Minutes Entry - " & db.buildMeetingNumber(nProjectID, Session("CollegeID"))
            Dim MeetingNum As String = db.buildMeetingNumber(nProjectID, Session("CollegeID"))
            roMeetingNumber.Text = MeetingNum
            sMeetingNumber = MeetingNum
        End Using
                      
    End Sub
    
    Private Sub addParticipant() Handles butAddParticipant.Click
        If saveButton.Value = "UploadSupportAttachment" Then
            Dim svbutton As String = saveButton.Value
            processSave(svbutton)
        ElseIf saveButton.Value = "UploadAttachment" Then
            Dim svbutton As String = saveButton.Value
            processSave(svbutton)
        Else
            Dim saveType As String = ""
            Dim isActive As Integer
            Dim isOrganizer As Integer = 0
            Dim isAllowUpload As Integer = 0
            'If chkOrganizer.Checked = True Then isOrganizer = 1
            'If chkAllowUpload.Checked = True Then isAllowUpload = 1
            Dim dataObj(6) As Object
        
            Using db As New MeetingMinute
                Dim tbl As DataTable = db.checkParticipant(nMeetingID, cboMeetingParticipants.SelectedValue)
                If tbl.Rows.Count > 0 Then
                    saveType = "Update"
                    isActive = tbl.Rows(0).Item("IsActive")
                    If isActive = 0 Then
                        isActive = 1
                    Else
                        isActive = 0
                    End If
                Else
                    saveType = "Insert"
                    isActive = 1
                End If
                Try
                    'dataObj(5) = tbl.Rows(0).Item("IsLead")
                Catch ex As Exception
                    'dataObj(5) = 0
                End Try
            
            End Using
                     
            dataObj(0) = cboMeetingParticipants.SelectedValue
            dataObj(1) = nMeetingID
            dataObj(2) = isActive 'IsActive'
            dataObj(3) = isOrganizer 'Is Organizer"
            dataObj(4) = saveType
            dataObj(5) = isAllowUpload
                      
            Using db As New MeetingMinute
                db.maintainParticipants(dataObj)
            End Using
            If isOrganizer = 1 Then
            
            End If
            getData()
            configExisting()
            participantChange()
            'roParticipants.Text = saveType & " - " & isActive
          
        End If               
    End Sub
        
    Private Sub participantChange() Handles cboMeetingParticipants.SelectedIndexChanged
        'Session("Members") = Nothing
        
        Using db As New MeetingMinute
            Dim tbl As DataTable = db.checkParticipant(nMeetingID, cboMeetingParticipants.SelectedValue)
            If cboMeetingParticipants.SelectedValue = 0 Then
                lblOrganizer.Visible = True
             Else
                If tbl.Rows.Count > 0 Then
                    If tbl.Rows(0).Item("IsActive") = 1 Then
                        butAddParticipant.ImageUrl = "images/button_remove.png"
                        lblOrganizer.Visible = True
                     ElseIf tbl.Rows(0).Item("IsActive") = 0 Then
                        butAddParticipant.ImageUrl = "images/button_add.png"
                        lblOrganizer.Visible = True
                    End If
                Else
                    butAddParticipant.ImageUrl = "images/button_add.png"
                    lblOrganizer.Visible = True
                End If
            End If
        End Using
    End Sub
    
    Private Sub saveMeeting(saveType As String)
        If txtMeetingDate.SelectedDate Is Nothing Then
            lblMessage.Text = "Please enter a Meeting Date."
            Exit Sub
        End If
        
        If txtDescription.Text = "" Then
            lblMessage.Text = "Please enter a Meeting Description."
            Exit Sub
        End If
        
        If cboDesignPhase.SelectedValue = "none" Then
            lblMessage.Text = "Please select a Design Phase."
            Exit Sub
        End If
        
        Dim subPhase As String = ""
        Select Case cboDesignPhase.SelectedValue
            Case "Design", "Close Out"
                subPhase = cboSubDesign.SelectedValue
            Case Else
                subPhase = "N/A"
        End Select
        
        Dim saveData(14) As Object
        Using db As New RFI
            saveData(0) = txtMeetingDate.SelectedDate
            saveData(1) = txtDescription.Text
            saveData(2) = cboDesignPhase.SelectedValue
            saveData(3) = db.getResponderName(nContactID)
            saveData(4) = Session("DistrictID")
            saveData(5) = nProjectID
            saveData(6) = saveType
            saveData(7) = sMeetingNumber
            saveData(8) = nMeetingID
            saveData(9) = cboCurrentFile.SelectedValue
            saveData(10) = subPhase
            saveData(11) = nContactID
            saveData(12) = cboStatus.SelectedValue
            saveData(13) = Session("CollegeID")
            
        End Using
        
        If saveType = "Update" Then Session("UpdateData") = True
        
        Dim rec As Integer
        Using dba As New MeetingMinute
            rec = dba.saveMeeting(saveData)
            
            If saveType = "Insert" Then
                nMeetingID = rec
                Session("NewAdd") = True
                Session("newID") = rec
                Session("ProjID") = nProjectID
                Dim dataObj(6) As Object
                dataObj(0) = nContactID
                dataObj(1) = nMeetingID
                dataObj(2) = 1
                dataObj(3) = 1
                dataObj(4) = "Insert"
                dataObj(5) = 0
                dba.maintainParticipants(dataObj)               
            End If
        
        End Using
        
        cboActionSelect.SelectedValue = "none"
        
        If saveType = "Insert" Then
            Response.Redirect("meetingminutes_edit.aspx?MeetingID=" & nMeetingID & "&ProjectID=" & nProjectID & "&DisplayType=Existing") 
        Else
            getData()
            configExisting()
        End If
       
    End Sub
    
    Private Sub insertComment()
        If txtComment.Text = "" Then
            commentMessage.Text = "Please enter a comment."
            txtComment.Focus()
            Exit Sub
        End If
    
        Dim insDat(6) As Object
        insDat(0) = nProjectID
        insDat(1) = nMeetingID
        insDat(2) = Today
        Using db As New MeetingMinute
            insDat(3) = db.getCommentSequence(nProjectID, nMeetingID) + 1
        End Using
        insDat(4) = nContactID
        insDat(5) = (txtComment.Text).Replace("'", "~")
        
        Using db As New MeetingMinute
            db.insertComment(insDat)
            txtMeetingHistory.Text = db.buildMeetingComments(nProjectID, nMeetingID)
        End Using
        txtComment.Text = ""
        commentMessage.Text = ""
        
    End Sub
    
    Private Sub updateAttachments_Change() Handles uplMinutesFileName.DataBinding
        'lblMessage.Text = "This"
        butSave.Visible = True        
    End Sub
    
    Private Sub uploadAttachment(sType As String)       
        Dim filePath As String = ""
        Select Case sType
            Case "minutes"
                filePath = strPhysicalPath
                deleteFiles("Minutes")
            Case "supporting"
                filePath = strPhysicalPath & "/" & nContactID
        End Select
        
        Dim folder As New DirectoryInfo(filePath)
        
        If Not folder.Exists Then  'create the folder
            folder.Create()
        End If
        
        For Each File As Telerik.Web.UI.UploadedFile In uplMinutesFileName.UploadedFiles
            If sType = "minutes" Then
                updateMinutesfile(File.GetName)
            End If
            
            Dim sSaveFile As String = Path.Combine(filePath, File.GetName)
            sSaveFile = sSaveFile.Replace("#", "")
            sSaveFile = sSaveFile.Replace(";", "")
            sSaveFile = sSaveFile.Replace(",", "")
            File.SaveAs(sSaveFile, True)    'overwrite if there
        Next
        Session("FileUpload") = True
        
        bindFileDropdown(buildDirFileDropdown(strPhysicalPath), cboDeleteFiles)
        getData()
        configExisting()
        
    End Sub
    
    Private Sub updateMinutesfile(file As String)
        Using db As New MeetingMinute
            db.updateListMinutes(nMeetingID, file)
        End Using
    End Sub
    
    Private Sub processSave(svbutton As String)
        Select Case svbutton
            Case "New"
                saveMeeting("Insert")
                'ProcLib.CloseAndRefreshRADNoPrompt(Page)
                'closeWindow()
            Case "Existing"
                saveMeeting("Update")
                'ProcLib.CloseAndRefreshRADNoPrompt(Page)
            Case "SaveComment"
                insertComment()
                'lblMessage.Text = "SaveComment"
            Case "UploadAttachment"
                uploadAttachment("minutes")
            Case "UploadSupportAttachment"
                uploadAttachment("supporting")
            Case "SetMinutes"
                Using db As New MeetingMinute
                    'db.updateListMinutes(nMeetingID, cboCurrentFile.SelectedValue)   
                End Using
                'ProcLib.CloseAndRefreshRADNoPrompt(Page)
                closeWindow()
                
                
            Case Else
        End Select
    End Sub
    
    Private Sub checkDirectory(dir As String)
        Dim folder As New DirectoryInfo(dir)    
        If Not folder.Exists Then  'create the folder
            folder.Create()
        End If
    End Sub
    
    Private Sub butSave_Click(ByVal sender As System.Object, ByVal e As System.Web.UI.ImageClickEventArgs) Handles butSave.Click
        Dim svbutton As String = saveButton.Value
        processSave(svbutton)        
    End Sub
    
    Private Sub deleteFiles(minuteChk As String)
        Dim targetPath As String = strPhysicalPath & "\" & "DeletedFiles"
        Dim sourcePath As String = strPhysicalPath
        
        Dim dinfo As New IO.DirectoryInfo(targetPath)
        Dim finfo As IO.FileInfo() = dinfo.GetFiles()
                   
        Dim file As String = ""              
        
        If saveButton.Value = "RemoveMeetingFile" Or minuteChk = "Minutes" Then
            sourcePath = strPhysicalPath
            'checkCurrentMinutesFile(file)
            Dim mData As DataTable
            Using db As New MeetingMinute
                mData = db.getMeetingData(nProjectID, nMeetingID)
                file = mData.Rows(0).Item("MinutesFileName")                
            End Using            
        ElseIf saveButton.Value = "RemoveSupportingFile" Then
            file = cboDeleteFiles.SelectedValue
            sourcePath = strPhysicalPath & "\" & nContactID
        End If
        
        Dim fileName As String
        Dim ext As String = Path.GetExtension(file)
        Dim count As Integer = 0
        checkDirectory(targetPath)
        For Each dra As IO.FileInfo In finfo
            count = count + 1
        Next
        Dim newFileName As String = ""
        Session("FileDelete") = True
        
        If file <> "None Selected" Then
            fileName = Path.GetFileNameWithoutExtension(targetPath & "/" & file)
            newFileName = count & "_" & fileName & "_" & nContactID & ext
            Try
                IO.File.Copy(sourcePath & "\" & file, targetPath & "\" & newFileName, True)
                IO.File.Delete(sourcePath & "\" & file)
            Catch ex As Exception
            End Try           
        End If
        
        bindFileDropdown(buildDirFileDropdown(sourcePath), cboDeleteFiles)
        getAttachments()
    End Sub
    
    Private Sub checkCurrentMinutesFile(file As String)
        'If cboCurrentFile.SelectedValue = file Then
        'Using db As New MeetingMinute
        'db.updateListMinutes(nMeetingID, "None Selected")
        'End Using
        'End If
    End Sub
    
    Private Sub butDelete_Click() Handles butDeleteFile.Click 
        deleteFiles("")
    End Sub

    Private Sub butSaveComment_Click() Handles butSaveComment.Click
        Dim svbutton As String = commentButton.Value
        processSave(svbutton)
    End Sub
    
    Private Sub butCancel_Click() Handles butCancel.Click
        'ProcLib.CloseAndRefreshRADNoPrompt(Page)
        closeWindow()
    End Sub
    
    Private Sub closeWindow()
        Session("RtnFromEdit") = True
        ProcLib.CloseAndRefreshRADNoPrompt(Page)
    End Sub
    
    Protected Sub butRemoveFile_Click(ByVal sender As Object, ByVal e As System.Web.UI.ImageClickEventArgs)
        Using db As New MeetingMinute
            db.CallingPage = Page
            db.DeleteMeetingMinuteAttachment(nProjectID, nMeetingID, lblMinutesFileName.Text)
        End Using

        Session("RtnFromEdit") = True
        'ProcLib.CloseAndRefreshRADNoPrompt(Page)
        closeWindow()
    End Sub
</script>

<html>
<head>
    <title id="title"><%= sTitle %></title>
    <link href="Styles.css" type="text/css" rel="stylesheet" />
    <style type="text/css">
    .alignTop
    {
        top:185px;
    }
    
    </style>
    <script type="text/javascript" language="javascript">
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

        /*David D 7/27/17 added this to refresh parent page if user clicks the red close button at the top right of pop-up radwindow*/
        function OnClientClose(sender, args) {
            //window.location.reload();//- will reload the page (equal to pressing F5)  
            window.location.href = window.location.href; // - will refresh the page by reloading the URL   
        }
 
    </script>

</head>
<body>
    <form id="Form1" method="post" runat="server">
    <telerik:radscriptmanager id="RadScriptManager1" runat="server" />

    <asp:HiddenField ID="saveButton" runat="server">
    </asp:HiddenField>

    <asp:HiddenField ID="commentButton" runat="server">
    </asp:HiddenField>

    <asp:HiddenField ID="configType" runat="server">
    </asp:HiddenField>

    <asp:HyperLink ID="butHelp" style="Position:absolute;left:630px;top:8px" runat="server" ImageUrl="images/button_help.gif">HyperLink</asp:HyperLink>

     <asp:Label ID="Label9" runat="server" Text="Meeting Date:" style="Position:absolute;left:15px;top:12px">
     </asp:Label>

     <telerik:raddatepicker id="txtMeetingDate" runat="server" width="120px" skin="Web20" style="position:absolute;top:10px;left:100px">
            <DateInput ID="DateInput1" runat="server" Skin="WebBlue" Font-Size="13px" ForeColor="Blue" />
            <Calendar ID="Calendar1" runat="server" UseRowHeadersAsSelectors="False" UseColumnHeadersAsSelectors="False"
            ViewSelectorText="x" Skin="Web20">
                <SpecialDays> 
                    <telerik:RadCalendarDay Repeatable="Today"> 
                    <ItemStyle BackColor="LightBlue" /> 
                    </telerik:RadCalendarDay> 
                </SpecialDays> 
            </Calendar>
            <DatePopupButton ImageUrl="" HoverImageUrl="" />
        </telerik:raddatepicker>

        <asp:Label ID="roMeetingDate" runat="server" style="Position:absolute;left:100px;top:12px;font-size:12px;font-weight:bold">
        </asp:Label>

      <asp:Label ID="lblOrganizer" runat="server" Text="Organizer:" style="position:absolute;left:33px;top:40px;" visible="True" ></asp:Label>
      <asp:Label ID="roOrganizerDisplay" runat="server" Text="" style="position:absolute;left:100px;top:40px;font-weight:bold" visible="True" ></asp:Label>


       <!--<asp:Label ID="roMeetingNumber" runat="server" style="Position:absolute;left:250px;top:12px;font-size:14px;font-weight:bold">
       
        </asp:Label>-->

        <asp:Label ID="Label2" runat="server" Text="Topic:"  style="Position:absolute;left:55px;top:69px">
        </asp:Label>

        <asp:TextBox ID="txtDescription" runat="server" Height="50px" Width="290px" TabIndex="2" TextMode="MultiLine"
          style="Position:absolute;left:100px;top:69px;vertical-align:top;z-index:100" CssClass="EditDataDisplay"></asp:TextBox>

        <asp:Label ID="roDescription" runat="server" style="Position:absolute;left:100px;top:69px;font-size:12px;font-weight:bold;width:290px">
        </asp:Label>

        <asp:Label ID="lblPhase" runat="server" style="position:absolute;left:52px;top:131px;z-index:100" >Phase:</asp:Label>

        <telerik:RadComboBox ID="cboDesignPhase" width="190" runat="server" Style="z-index: 508; left: 100px;
            position: absolute; top: 131px;" Skin="Vista"  TabIndex="7" AutoPostBack="true" Visible="True"
            Text="(Status)">
                <Items>
                    <telerik:RadComboBoxItem runat="server" Text="Not Selected" Value="none" />
                    <telerik:RadComboBoxItem runat="server" Text="Other" Value="Other" />
                    <telerik:RadComboBoxItem runat="server" Text="Pre-Design" Value="Pre-Design" />
                    <telerik:RadComboBoxItem runat="server" Text="Design" Value="Design" />
                    <telerik:RadComboBoxItem runat="server" Text="DSA" Value="DSA" />
                    <telerik:RadComboBoxItem runat="server" Text="Bidding" Value="Bidding" />
                    <telerik:RadComboBoxItem runat="server" Text="Construction" Value="Construction" />
                    <telerik:RadComboBoxItem runat="server" Text="Close Out" Value="Close Out" />
                </Items>
        </telerik:RadComboBox>

        <asp:Label ID="roDesignPhase" runat="server" style="Position:absolute;left:100px;top:131px;font-size:12px;font-weight:bold;z-index:100">
        </asp:Label>

        <asp:Label ID="lblSubPhase" runat="server" style="Position:absolute;left:29px;top:163px;">
        Sub-Phase:</asp:Label>

        <telerik:RadComboBox ID="cboSubDesign" width="190" runat="server" Style="z-index: 90; left: 100px;
            position: absolute; top: 163px;" Skin="Vista"  TabIndex="7" AutoPostBack="false" Visible="True"
            Text="(Status)">            
        </telerik:RadComboBox>

        <asp:Label ID="roSubDesign" runat="server" style="Position:absolute;left:100px;top:163px;font-size:12px;font-weight:bold">
        </asp:Label>

        <asp:Label ID="formLine" runat="server" Visible="true" style="Position:absolute;left:29px;top:195px;width:625px;border-style:solid;
            border-width:1px;border-color:#bdbdbd">
        </asp:Label>

        <asp:Label ID="lblMinutesFile" runat="server" style="position:absolute;left:35px;top:210px" >Minutes:</asp:Label>
        <asp:Label ID="roCurrentFile" runat="server" style="position:absolute;left:100px;top:210px;font-weight:bold;font-size:12px" ></asp:Label>
        <telerik:RadComboBox ID="cboCurrentFile" width="250" runat="server" Style="z-index: 507; left: 100px;
            position: absolute; top: 100px;" Skin="Vista"  TabIndex="7" AutoPostBack="false" Visible="False"
            Text="(Status)">
              
        </telerik:RadComboBox>


        <asp:Label ID="lblSupportingAttachments" runat="server" Text="" style="position:absolute;left:35px;top:235px" visible="true" >Supporting Attachments:</asp:Label>
        
        <asp:Label ID="supportingAttachments" runat="server" Text="No Supporting Attachments" style="position:absolute;left:35px;top:255px;border-style:solid;
            border-width:1px;border-color:#ffffff;height:160px;width:268px;padding:5px;overflow:auto;box-shadow: 2px 2px 5px #000000" visible="true" ></asp:Label>

        <asp:Label ID="lblParticipants" runat="server" Text="Meeting Participants:" style="position:absolute;left:370px;top:235px" visible="false" ></asp:Label>

        <asp:Label ID="roParticipants" runat="server" Text="" 
            style="position:absolute;left:370px;top:255px;border-style:solid;border-width:0px;border-color: #ffffff;height:160px;width:270px
            ;padding:5px;line-height:20px;text-align:center;font-size:12px;overflow:auto;box-shadow: 2px 2px 5px #000000"       
         visible="false" ></asp:Label>




        <telerik:RadComboBox ID="cboStatus" width="160" runat="server" Style="z-index: 507; left: 415px;
            position: absolute; top: 100px;" Skin="Vista"  TabIndex="7" AutoPostBack="false" Visible="True"
            Text="(Status)">
              <Items>
                    <telerik:RadComboBoxItem runat="server" Text="Not Selected" Value="Not Selected" />
                    <telerik:RadComboBoxItem runat="server" Text="Open" Value="Open" />
                    <telerik:RadComboBoxItem runat="server" Text="Minutes Approval Pending" Value="Minutes Approval Pending" />
                    <telerik:RadComboBoxItem runat="server" Text="Closed" Value="Closed" />
              </Items> 
        </telerik:RadComboBox>
        <asp:Label ID="lblStatus" runat="server" style="position:absolute;left:370px;top:100px" >Status:</asp:Label>
        <asp:Label ID="roStatus" runat="server" style="position:absolute;left:415px;top:100px;font-weight:bold;font-size:12px" ></asp:Label>
 

        <asp:Label ID="lblAction" runat="server" style="position:absolute;left:400px;top:10px;z-index:506" >Action Items:</asp:Label>

        <telerik:RadComboBox ID="cboActionSelect" width="190" runat="server" Style="z-index: 505; left: 400px;
            position: absolute; top: 30px;" Skin="Vista"  TabIndex="7" AutoPostBack="true" Visible="True"
            Text="(Status)">
               
        </telerik:RadComboBox>

        <telerik:RadComboBox ID="cboMeetingParticipants" runat="server" Style="z-index: 500;
        left: 400px; position: absolute; top: 60px;" Skin="Vista" Text="(Submitted To)"
        DropDownWidth="400px" MaxHeight="150px" AppendDataBoundItems="True" TabIndex="14" AutoPostBack="true" >
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
                                           
                                        </td>-->
                                    </tr>
                                </table>
                            </ItemTemplate>       
    </telerik:RadComboBox>

    <!--<asp:CheckBox ID="chkOrganizer" runat="server" style="position:absolute;top:220px;left:120px" value="Organizer" Visible="false" />-->
 
    <!--<asp:CheckBox ID="chkAllowUpload" runat="server" style="position:absolute;top:240px;left:120px" value="Organizer" Visible="false" />-->
    <!--<asp:Label ID="lblAllowUpload" runat="server" Text="Allow Upload:" style="position:absolute;left:40px;top:240px;" visible="false" ></asp:Label>-->


    <asp:ImageButton ID="butAddParticipant" TabIndex="5" runat="server" style="Position:absolute;left:400px;top:150px;z-index:100"
           autopostback=true ImageUrl="images/button_save.gif" />


         <telerik:RadComboBox ID="cboDeleteFiles" width="250" runat="server" Style="z-index: 100; left: 400px;
            position: absolute; top: 80px;" Skin="Vista"  TabIndex="7" AutoPostBack="false" Visible="false"
            Text="(Status)">
              
        </telerik:RadComboBox>

        <!--<asp:Label ID="lblMinutesAttachments" runat="server" Text="-------  Meeting Minutes  -------" style="position:absolute;left:50px;top:370px;font-weight:bold" visible="true" ></asp:Label>-->

        <!--<asp:Label ID="showAttachments" runat="server" Text="Attachment:" style="position:absolute;left:10px;top:390px;border-style:solid;
            border-width:1px;border-color:#ffffff;height:150px;width:250px;padding:5px;overflow:auto;box-shadow: 2px 2px 5px #000000" visible="false" ></asp:Label>-->




        <asp:Label ID="Label1" runat="server" Text="Attachment:" style="position:absolute;left:23px;top:130px" visible="false" ></asp:Label>

        <asp:Label ID="lblMinutesFileName" Visible="false" Class="EditDataDisplay" runat="server" Height="24px" style="Position:absolute;left:100px;top:130px">
        (None Attached)</asp:Label>

        <telerik:RadUpload ID="uplMinutesFileName" runat="server" Style="Position:absolute;z-index:100;left:400px;top:60px;width:150px"
                     ControlObjectsVisibility="None" />

        <asp:Label ID="lblHideUpload" runat="server" Height="28px" Width="210px" style="Position:absolute;left:10px;top:115px;z-index:1;background-color:#e6e7ed">
        </asp:Label>


        <asp:ImageButton ID="butRemoveFile" runat="server" style="Position:absolute;left:400px;top:100px" visible="false"
            ImageUrl="images/attachment_remove_small.gif" onclick="butRemoveFile_Click" />

        <asp:Label ID="lblMessage" runat="server" Height="24px" Font-Bold="True" ForeColor="Red" style="Position:absolute;left:20px;top:185px">
        </asp:Label>
       

        <asp:TextBox ID="txtMeetingHistory" runat="server" Height="260px" Width="465px" TabIndex="1"
          style="Position:absolute;left:10px;top:145px;vertical-align:top" textmode="MultiLine" Visible="false"></asp:TextBox>

        <asp:Label ID="lblComment" runat="server" style="position:absolute;left:10px;top:410px" visible="false" >Comment:</asp:Label>

        <asp:Label ID="commentMessage" runat="server" Height="24px" Font-Bold="True" ForeColor="Red" style="Position:absolute;left:90px;top:410px" visible="false">
        </asp:Label>


        <asp:TextBox ID="txtComment" runat="server" Height="100px" Width="465px" TabIndex="1"
          style="Position:absolute;left:10px;top:430px;vertical-align:top" textmode="MultiLine" visible="false"></asp:TextBox>

        <telerik:radwindowmanager id="RadPopups" runat="server" />

         <asp:ImageButton ID="butDeleteFile" TabIndex="5" runat="server" style="Position:absolute;left:400px;top:150px"
            ImageUrl="images/button_remove.png" visible="false"/>

        <asp:ImageButton ID="butSaveComment" TabIndex="5" runat="server" style="Position:absolute;left:300px;top:535px"
            ImageUrl="images/button_save.gif" visible="false"/>

       <asp:ImageButton ID="butSave" TabIndex="5" runat="server" style="Position:absolute;left:400px;top:150px;z-index:2"
           autopostback=true ImageUrl="images/button_save.gif" Visible="false" />

        <asp:ImageButton ID="butCancel" TabIndex="5" runat="server" style="Position:absolute;left:580px;top:150px"
           autopostback=true ImageUrl="images/button_cancel.png" visible="true"/>

       <asp:Label ID="devDisplay" runat="server" style="position:absolute;left:23px;top:535px" visible="false" ></asp:Label>


    </form>
</body>
</html>
