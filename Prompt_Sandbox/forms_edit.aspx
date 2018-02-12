<%@ Page Language="VB" %>
<%@ Register Assembly="Telerik.Web.UI" Namespace="Telerik.Web.UI" TagPrefix="telerik" %>
<%@ Import Namespace="System.IO" %>
<%@ Import Namespace="System.IO.FileSystemInfo" %>
<%@ Import Namespace="Prompt" %>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<script runat="server">
    Private sTitle As String
    Private EditType As String
    Private nProjectID As Integer
    Private nContactID As Integer
    Private strPhysicalPath As String
    Private FormID As Integer = 0
    Private sFormNumber As String = ""
    Private sFormFileName As String
    Private strFilePath As String = ""
    Private formStatus As String = ""
    Private userName As String
    Private currentUser As Integer
    Private saveType As String = ""
    Private xUserID As Integer = 0
    
    Private Sub Page_Load(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MyBase.Load
        
        ProcLib.CheckSession(Page)
        ProcLib.LoadPopupJscript(Page)

        Session("PageID") = "FormsEdit"
        Session("Disabled") = ""
        butHelp.Visible = False
        
        EditType = Request.QueryString("DisplayType")
        
        Dim sContactName As String        
        Using db As New RFI
            nContactID = db.getContactID(Session("UserID"), Session("DistrictID"))
            Dim ContactData As Object = db.getContactData(nContactID, Session("DistrictID"))
            Session("ParentContactID") = ContactData(0)
            Session("ContactType") = ContactData(1)
            'Session("userName") = ContactData(2) was causing failure, do not modify session username or will logout user
            sContactName = ContactData(2)
        End Using
        
        'Below applies to tech support since they are not required to be a contact, this will use the UserID in the user table
        Using dbsa As New promptForms
            Dim xLoginID As String = Trim(Session("LoginID"))
            xUserID = dbsa.getUserID(xLoginID)
        End Using
        If nContactID = 0 And HttpContext.Current.Session("UserRole") = "TechSupport" Then
            nContactID = xUserID
        End If
        
        FileAction.Visible = False 'Removed container box with dropdown action menu
        FileCategories.Visible = False 'Removed container box with dropdown categories menu and moved inside form details box

        userName = Session("UserName")
        currentUser = nContactID
        
        If EditType = "New" Then
            'If Not IsPostBack Then
            configNew()
            imgFileIcon.Visible = False
            roCurrentFile.Text = "No Form Selected"
            roCurrentFile.Style.Add("color", "red")
            roCurrentFile.Style.Add("left", "18px")
            lblReadyOnlyMessage.Visible = True
            lblReadyOnlyMessage.Text = "Preparing Form"
            Using pf As New promptForms
                Session("NewFormID") = pf.buildFormID(nProjectID, Session("CollegeID"))
                FormID = Session("NewFormID")
            End Using
            'lblMessage.Text = FormID
            'End If
        ElseIf EditType = "Existing" Then
            FormID = Request.QueryString("FormID")
            Using db As New promptForms
                Dim author As Integer = db.getAuthor(FormID)
                If author = nContactID Then
                    cboActionSelect.Visible = False
                Else
                    cboActionSelect.Visible = False
                End If
            End Using
            If Not IsPostBack Then
                getData()
                getFileImage()
                If configType.Value <> "RO" Then
                    configActionDropdown()
                    cboActionSelect.Visible = False
                    cboActionSelect.SelectedValue = "Edit Form"
                    lblAction.Visible = True
                    lblReadyOnlyMessage.Visible = False
                    butSave.Visible = True
                    uplFormFileName.Visible = True
                    lblFormUpload.Visible = True
                    configEdit()
                Else
                    cboActionSelect.Visible = False
                    lblReadyOnlyMessage.Visible = True
                    uplFormFileName.Visible = False
                    lblFormUpload.Visible = False
                    configReadOnly()
                End If
            End If
        End If
        
            lblUserDisplay.Text = userName & " - ID: " & currentUser '& " - " & " FormID - " & FormID

            If Not IsPostBack Then
                nProjectID = Request.QueryString("ProjectID")  
            End If
        
            'below determines the folder path and where the file goes when adding a NEW form that does not exist using "Add New"
            strPhysicalPath = ProcLib.GetCurrentAttachmentPath() & "DistrictID_" & HttpContext.Current.Session("DistrictID") & "/_apprisedocs/"
        strPhysicalPath &= "_forms/ProjectID_" & nProjectID & "/formID_" & FormID
    End Sub
        
    Private Sub configNew()
        EditType = "New"
        butDeleteFile.Visible = False
        Using db As New promptForms
            Dim ProjName As String
            If nProjectID = 0 Then
                ProjName = db.getCollegeName(Session("CollegeID"))
            Else
                ProjName = db.getProjectName(nProjectID)
            End If
            
            If ProjName = String.Empty Then
                ProjName = "Form Management"
            End If
            
            FormID = db.buildFormID(nProjectID, Session("CollegeID"))
            Session("NewFormID") = FormID
            
            Dim FormNum As String = db.buildFormNumber(nProjectID, Session("CollegeID"), HttpContext.Current.Session("DistrictID"))
            
            sTitle = ProjName & " -  New: " & FormNum & " - Form Status: Preparing"
            Session("newFormNumber") = FormNum
        End Using
        
        txtFormDate.Visible = True
        roFormDate.Visible = False
        txtDescription.Visible = True
        txtFormTitle.Visible = True
        roDescription.Visible = False
        roFormTitle.Visible = False
        devDisplay.Visible = False
        butSave.Visible = True
        uplFormFileName.Visible = True
        lblFormUpload.Visible = True
        lblAction.Visible = True
        lblReadyOnlyMessage.Visible = False
        cboActionSelect.Visible = False
        cboSubDesign.Visible = False
        lblFormFile.Visible = True
        roCurrentFile.Visible = True
        lblSubPhase.Visible = False
        roDocumentOwnerDisplay.Text = userName
        
        Dim alertText As String = ""
        alertText = "This action will Create a new Form entry.\n\nDo you want to continue?"
        butSave.OnClientClick = "return confirm('" & alertText & "')"
        butSave.Visible = True
        butSave.ImageUrl = "images/button_save.png"
        saveButton.Value = "New"
        butUploadForm.Visible = False
    End Sub
    
    Private Sub configReadOnly()
        txtFormTitle.Visible = true
        roFormDate.Visible = True
        txtFormDate.Visible = False
        roFormTitle.Visible = False
        txtFormTitle.Visible = True
        txtFormTitle.Enabled = False
        cboDesignPhase.Visible = False
        roDesignPhase.Visible = True
        txtDescription.Visible = True
        roDescription.Visible = False
        txtDescription.Enabled = False
        uplFormFileName.Visible = False
        butSave.Visible = False
        butUploadForm.Visible = False
    End Sub
    
    Private Sub configEdit()
        roFormDate.Visible = False
        txtFormDate.Enabled = True
        txtFormDate.Visible = True
        txtFormTitle.Visible = True
        txtFormTitle.Enabled = True
        roFormTitle.Visible = False
        cboDesignPhase.Visible = True
        roDesignPhase.Visible = False
        txtDescription.Visible = True
        txtDescription.Enabled = True
        roDescription.Visible = False
        uplFormFileName.Visible = True
        butUploadForm.Visible = False
        butSave.Visible = True
        butDeleteFile.Visible = True
        Dim alertTextDelete As String = ""
        alertTextDelete = "This action will remove the selected document from this page\nand it will no longer be available.\n\nDo you want to continue?"
        butDeleteFile.OnClientClick = "return confirm('" & alertTextDelete & "')"
        butSave.ImageUrl = "images/button_save.png"
        Dim alertText As String = "This action will update this Forms data,"
        alertText &= "\n\and replace the existing document if a new one was selected."
        alertText &= "\n\n\Do you want to continue?"
        butSave.OnClientClick = "return confirm('" & alertText & "')"
        saveButton.Value = "Edit"
    End Sub
    
    
    Private Sub configUpload()
        configReadOnly()
        uplFormFileName.Visible = True
        butSave.Visible = False
        saveButton.Value = "Upload"
        Dim alertText As String = "This action will replace the current file."
        alertText &= "\n\n\Do you want to continue?"
        butSave.OnClientClick = "return confirm('" & alertText & "')"
        butSave.ImageUrl = "images/button_save.png"
        butUploadForm.Visible = False
    End Sub
    
    Private Sub configRemove()
        configReadOnly()
        butSave.Visible = True
        butSave.ImageUrl = "images/button_remove.png"
        saveButton.Value = "Remove"
        Dim alertText As String = "This action will remove this form. All access will be lost."
        alertText &= "\n\n\Do you want to continue?"
        butSave.OnClientClick = "return confirm('" & alertText & "')"
        butUploadForm.Visible = False
    End Sub
    
    Private Sub removeForm()
        Using db As New promptForms
            db.removeForm(FormID)
        End Using
    End Sub
 
    Private Sub removeFile(file As String)
        Dim targetPath As String = strPhysicalPath & "\" & "DeletedFiles"
        Dim sourcePath As String = strPhysicalPath

        If saveButton.Value = "Remove" Or saveButton.Value = "Edit" Then
            sourcePath = strPhysicalPath
            checkDirectory(strPhysicalPath & "\DeletedFiles")
            Dim mData As DataTable
            Using db As New promptForms
                mData = db.getFormData(nProjectID, FormID)
                file = mData.Rows(0).Item("FormFileName")
            End Using
        End If
        
        Dim dinfo As New IO.DirectoryInfo(targetPath)
        Dim finfo As IO.FileInfo() = dinfo.GetFiles()
        Dim fileName As String
        Dim ext As String = Path.GetExtension(file)
        Dim count As Integer = 0
        Dim d As String = (Now).ToString("yyyy-MM-dd")
        For Each dra As IO.FileInfo In finfo
            count = count + 1
        Next
        Dim newFileName As String = ""
        fileName = Path.GetFileNameWithoutExtension(sourcePath & "/" & file)
        newFileName = count & "_" & d & "_" & fileName & "_" & nContactID & ext
        Try
            IO.File.Copy(sourcePath & "\" & file, targetPath & "\" & newFileName, True)
            IO.File.Delete(sourcePath & "\" & file)
        Catch ex As Exception
        End Try
    End Sub
    
    Private Sub configExistingAfterNewSave()
        'This sub is ONLY for after a new form is saved
        txtFormDate.Visible = False
        roFormDate.Visible = True
        txtDescription.Visible = False
        txtFormTitle.Visible = False
        'roDescription.Visible = True
        txtDescription.Visible = True
        txtDescription.Enabled = False
        roFormTitle.Visible = True
        cboDesignPhase.Visible = False
        
        If configType.Value <> "RO" Then
            cboActionSelect.Visible = False
            cboActionSelect.SelectedValue = "Edit Form"
            lblAction.Visible = True
            lblReadyOnlyMessage.Visible = False
            butSave.Visible = True
            uplFormFileName.Visible = True
            lblFormUpload.Visible = True
            saveType = "Update"
        Else
            cboActionSelect.Visible = False
            lblReadyOnlyMessage.Visible = True
            uplFormFileName.Visible = False
            lblFormUpload.Visible = False
            saveType = ""
        End If
       
        roDesignPhase.Visible = True
        roCurrentFile.Visible = True
        lblDocumentOwner.Visible = True
        roDocumentOwnerDisplay.Visible = True
        lblSubPhase.Visible = True
        lblFormFile.Visible = True
        butDeleteFile.Visible = True
        
        FormID = Convert.ToInt32(FormID) - 1
        saveButton.Value = "Edit"

        Dim curUl As String = (HttpContext.Current.Request.Url.Host).ToString()
        Dim port As String = (HttpContext.Current.Request.Url.Port).ToString()
        Dim protocal As String = ConfigurationManager.AppSettings("Protocol")
        
        Dim sFolderPath As String = ProcLib.GetCurrentRelativeAttachmentPath() & "DistrictID_" & Session("DistrictID") & "/_apprisedocs/"
        sFolderPath &= "_forms/ProjectID_" & nProjectID & "/formID_" & FormID & "/"
        
        Dim path As String
        If protocal = "https://" Then
            path = "<a target='blank' href='https://" & curUl & "/" & sFolderPath
        Else
            If port = "" Then
                curUl = curUl & "/"
            Else
                curUl = curUl & ":" & port & "/"
            End If
            path = "<a target='blank' href='http://" & curUl & sFolderPath
        End If
        path &= roCurrentFile.Text & "'>" & roCurrentFile.Text & "</a>"

        roCurrentFile.Text = path 'This only applies to a NEW form, not existing
        Response.Redirect("forms_edit.aspx?ProjectID= " & nProjectID & "&FormID=" & FormID & "&DisplayType=Existing")
        cboActionSelect.SelectedValue = "Edit Form"
        
        Select Case Trim(cboActionSelect.SelectedValue)
            Case "none"
                txtFormDate.Visible = False
                txtDescription.Visible = True
                txtDescription.Enabled = False
                txtFormTitle.Visible = False
                cboDesignPhase.Visible = False
                roFormDate.Visible = True
                roDescription.Visible = False
                roFormTitle.Visible = True
                cboSubDesign.Visible = False
                roSubDesign.Visible = True
                butSave.Visible = False
                butUploadForm.Visible = False
                butDeleteFile.Visible = False
            Case "Edit Form"
                txtFormDate.Visible = True
                cboActionSelect.Visible = False
                txtDescription.Visible = True
                txtDescription.Enabled = True
                txtFormTitle.Visible = True
                cboDesignPhase.Visible = True
                roDesignPhase.Visible = False
                roFormDate.Visible = False
                roDescription.Visible = False
                roFormTitle.Visible = False
                roCurrentFile.Visible = True
                cboSubDesign.Visible = False
                roSubDesign.Visible = False
                butUploadForm.Visible = False
        End Select
    End Sub
    
    Private Sub getData()
        Dim curUl As String = (HttpContext.Current.Request.Url.Host).ToString()
        Dim port As String = (HttpContext.Current.Request.Url.Port).ToString()
        Dim protocal As String = ConfigurationManager.AppSettings("Protocol")
        
        Dim sFolderPath As String = ProcLib.GetCurrentRelativeAttachmentPath() & "DistrictID_" & Session("DistrictID") & "/_apprisedocs/"
        sFolderPath &= "_forms/ProjectID_" & nProjectID & "/formID_" & FormID & "/"
        
        Dim path As String
        If protocal = "https://" Then
            path = "<a target='blank' href='https://" & curUl & "/" & sFolderPath
        Else
            If port = "" Then
                curUl = curUl & "/"
            Else
                curUl = curUl & ":" & port & "/"
            End If
            path = "<a target='blank' href='http://" & curUl & sFolderPath
        End If
        
        Dim mData As DataTable
        Using db As New promptForms
            Try
                Dim ProjName As String            
                mData = db.getFormData(nProjectID, FormID)

                If nProjectID = 0 Then
                    ProjName = db.getCollegeName(Session("CollegeID"))
                Else
                    ProjName = db.getProjectName(nProjectID)
                End If
            
                If ProjName = String.Empty Then
                    ProjName = "Form Management"
                End If
                
                'David D 8-15-17 below code changes the roDocumentOwnerDisplay to show the name instead of the number on the UI.  In the DB it remains the contactID
                Session("OwnerID") = mData.Rows(0).Item("DocumentOwner")
                
                Using dbs As New RFI
                    Dim ContactData As Object = dbs.getContactData(Session("OwnerID"), Session("DistrictID"))
                    Session("OwnerName") = ContactData(2)
                End Using

                'Below condition applies to TechSupport since they are not required to be a contact.  This will instead pull the document owner data from the user table
                If Session("OwnerName") = "" Then
                    Using dbsx As New promptForms
                        Dim UserData As Object = dbsx.getUserNameByUserID(Session("OwnerID"))
                        Session("OwnerName") = UserData(1)
                    End Using
                End If
                
                Dim editOrRead As String = ""
            
                If Session("OwnerID") = currentUser Then
                    editOrRead = " -  Edit: "
                Else
                    editOrRead = " -  Read Only: "
                End If
            
                sFormNumber = mData.Rows(0).Item("FormNumber")
                If EditType = "Delete" Or formStatus = "Disabled" Then
                    formStatus = "Disabled"
                    editOrRead = " -  Locked - "
                Else
                    formStatus = mData.Rows(0).Item("Status")
                End If
                sTitle = ProjName & editOrRead & mData.Rows(0).Item("FormNumber") & " - Form Status: " & formStatus
                
                If mData.Rows(0).Item("FormFileName") = "None Selected" Then
                    path = "None Selected"
                    Session("FormFileName") = ""
                    'imgFileIcon.ImageUrl = "images/paper_clip_small2.gif"
                Else
                    path &= mData.Rows(0).Item("FormFileName") & "'>" & mData.Rows(0).Item("FormFileName") & "</a>"
                    sFormFileName = mData.Rows(0).Item("FormFileName")
                    Session("FormFileName") = sFormFileName
                End If
                
                roFormDate.Text = mData.Rows(0).Item("FormDate")
                txtFormDate.DbSelectedDate = mData.Rows(0).Item("FormDate")
                roDescription.Text = mData.Rows(0).Item("Description")
                roFormTitle.Text = mData.Rows(0).Item("FormTitle")
                txtDescription.Text = mData.Rows(0).Item("Description")
                txtFormTitle.Text = mData.Rows(0).Item("FormTitle")
                roDesignPhase.Text = Trim(mData.Rows(0).Item("DesignPhase"))
                cboDesignPhase.SelectedValue = Trim(roDesignPhase.Text)
                lblFormFileName.Text = mData.Rows(0).Item("FormFileName")
                configPhaseDropdowns(Trim(mData.Rows(0).Item("DesignPhase")), "ro")
                roDocumentOwnerDisplay.Text = Session("OwnerName")
                If editOrRead = " -  Read Only: " Then
                    lblMessage.Text = "<p style='font-weight:bold;font-size:10pt;margin-bottom:-5px;'>Read Only</p><p>This form is currently in read only mode<br>"
                    lblMessage.Text += "Please contact the Document Owner<br> to make any changes or replace the form.</p>"
                    lblMessage.Style.Add("margin-top", "-100px")
                    lblMessage.Style.Add("margin-left", "-10px")
                    lblMessage.Style.Add("text-align", "center")
                    lblMessage.Style.Add("width", "250px")
                    lblMessage.Style.Add("background-color", "#eff2f1")
                    lblMessage.Style.Add("height", "105px")
                    lblMessage.Style.Add("padding-bottom", "5px")
                End If
                Session("Path") = path
            Catch ex As Exception

            End Try
            
            'This overrides the previous settings as there are no other views.
            Dim ConType As String
            Using dba As New RFI
                Dim contInfo As Object = dba.getContactData(nContactID, Session("DistrictID"))
                ConType = contInfo(1)
            End Using
            
            If Session("OwnerID") = nContactID Then
                configType.Value = "Organizer"
            ElseIf ConType = "Program Manager" Then
                Using dba As New RFI
                    Dim contInfo As Object = dba.getContactData(Session("OwnerID"), Session("DistrictID"))
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
        
        If Session("FormFileName") = "" Then
            roCurrentFile.Text = "No Form Selected"
            roCurrentFile.Style.Add("left", "18px")
        Else
            roCurrentFile.Text = path
        End If
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
            Case "PrePlanning", "Planning", "Bidding", "Construction"
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
                
            Case "Close-out"
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
    
    Private Sub configActionDropdown()
        Dim tbl As DataTable
        tbl = New DataTable("tbl")
        tbl.Columns.Add("Action", GetType(System.String))
        tbl.Columns.Add("ActionText", GetType(System.String))
        tbl.Rows.Add("none", "Review")
        
        Select Case configType.Value
            Case "PM"
                tbl.Rows.Add("Edit Form", "Edit Form")
                tbl.Rows.Add("Upload New Form", "Upload New Form")
            Case "Organizer"
                tbl.Rows.Add("Edit Form", "Edit Form")
                tbl.Rows.Add("Upload New Form", "Upload New Form")
        End Select
        With cboActionSelect
            .DataValueField = "Action"
            .DataTextField = "ActionText"
            .DataSource = tbl
            .DataBind()
        End With
    End Sub
           
    
    Private Sub formCategoryID() 'sets categoryID for grouping in the grid
        Select Case Trim(cboDesignPhase.SelectedValue)
            Case "PrePlanning"
                categoryID.Value = "1PRE"
            Case "Planning"
                categoryID.Value = "2PLN"
            Case "Design"
                categoryID.Value = "3DSN"
            Case "DSA"
                categoryID.Value = "4DSA"
            Case "Bidding"
                categoryID.Value = "5BID"
            Case "Construction"
                categoryID.Value = "6CON"
            Case "Close-out"
                categoryID.Value = "7CLS"
                'Case "Other"
                '    categoryID.Value = "8OTH"
        End Select
    End Sub
    
    Private Sub cboActionSelect_Change() Handles cboActionSelect.SelectedIndexChanged
        Select Case Trim(cboActionSelect.SelectedValue)
            Case "none"
                configReadOnly()
            Case "Edit Form"
                configEdit()
        End Select
    End Sub
    
    Private Sub checkDirectory(dir As String)
        Dim folder As New DirectoryInfo(dir)
        If Not folder.Exists Then  'create the folder
            folder.Create()
        End If
    End Sub
    
    Private Sub cboDesignPhase_Change() Handles cboDesignPhase.SelectedIndexChanged
        
    End Sub
    
    Private Sub saveFormData(saveType As String)
        Dim fileName As String = ""
        Dim obj(18) As Object
        Dim temp As String
        
        Try
            uploadFile()
        Catch ex As Exception
            lblMessage.Text = "There was a problem uploading this file."
            Exit Sub
        End Try
        
        For Each File As Telerik.Web.UI.UploadedFile In uplFormFileName.UploadedFiles
            fileName = File.GetName
        Next
        formCategoryID() 'sets categoryID for grouping in the grid
        
        Dim disableDate As String = ""
        
        If EditType = "Delete" Then
            formStatus = "Disabled"
            disableDate = Now.ToString
        Else
            formStatus = "Active"
            disableDate = ""
        End If
        Using dbs As New RFI
            Session("ResponderID") = dbs.getResponderName(nContactID)
        End Using
        
        Dim FormNum As String
        If EditType = "Existing" Then
            FormNum = sFormNumber
        Else
            FormNum = Session("newFormNumber")
        End If
        
        If Session("ResponderID") = "" And HttpContext.Current.Session("UserRole") = "TechSupport" Then
            Session("ResponderID") = Session("UserName")
        End If
        
        If nContactID = 0 And HttpContext.Current.Session("UserRole") = "TechSupport" Then
            nContactID = xUserID
        End If
                
        obj(0) = saveType
        obj(1) = txtFormDate.SelectedDate
        obj(2) = txtDescription.Text.Replace("'", "")
        obj(3) = cboDesignPhase.SelectedValue
        obj(4) = Session("ResponderID")
        obj(5) = Session("DistrictID")
        obj(6) = nProjectID
        obj(7) = roCurrentFile.Text
        obj(8) = FormNum
        obj(9) = FormID
        obj(10) = cboCurrentFile.SelectedValue
        obj(11) = ""
        obj(12) = nContactID
        obj(13) = formStatus
        obj(14) = Session("CollegeID")
        obj(15) = cboDesignPhase.SelectedValue
        obj(16) = categoryID.Value
        obj(17) = txtFormTitle.Text.Replace("'", "")
        obj(18) = disableDate
        
        Using db As New promptForms
            temp = db.saveFormData(obj)
            If saveType = "New" Then
                Threading.Thread.Sleep(1000)
                FormID = db.buildFormID(nProjectID, Session("CollegeID"))
            End If
        End Using
               
        If saveType = "Update" Then Session("UpdateData") = True
        
        'lblMessage.Text = temp
        If EditType = "Existing" Then
            Response.Redirect("forms_edit.aspx?ProjectID= " & nProjectID & "&FormID=" & FormID & "&DisplayType=Existing")
        End If
    End Sub
    
    Private Sub butCancel_Click() Handles butCancel.Click
        Session("RtnFromEdit") = True
        ProcLib.CloseAndRefreshRADNoPrompt(Page)
    End Sub
    
    Private Sub uploadFile()
        Dim filePath As String  
        filePath = strPhysicalPath
        checkDirectory(filePath)
        
        For Each File As Telerik.Web.UI.UploadedFile In uplFormFileName.UploadedFiles
            If EditType = "Existing" Then
                Using db As New promptForms
                    db.updateFormFileName(File.GetName, FormID)
                    roCurrentFile.Text = File.GetName
                End Using
            Else 
                roCurrentFile.Text = File.GetName
                Session("NewFileName") = roCurrentFile.Text
            End If
            
            Dim sSaveFile As String = Path.Combine(filePath, File.GetName)
            sSaveFile = sSaveFile.Replace("#", "")
            sSaveFile = sSaveFile.Replace(";", "")
            sSaveFile = sSaveFile.Replace(",", "")
            File.SaveAs(sSaveFile, True)    'overwrite if there
        Next
    End Sub
    
    Private Sub validationBoxStyle()
        lblMessage.Style.Add("top", "160px")
        lblMessage.Style.Add("margin-left", "-15px")
        lblMessage.Style.Add("text-align", "center")
        lblMessage.Style.Add("width", "220px")
        lblMessage.Style.Add("background-color", "#eff2f1")
        lblMessage.Style.Add("height", "35px")
        lblMessage.Style.Add("padding", "5px")
    End Sub
    
    Private Sub butSave_Click() Handles butSave.Click
        Dim validationText As String = "<strong>Please complete the following field:</strong> <br><li>Required - "
        Dim alertText As String
        Select Case saveButton.Value
            Case "New"
                If txtFormDate.SelectedDate Is Nothing Then
                    lblMessage.Text = validationText & "Form Date.</li>"
                    lblAsterisk.Text = "*"
                    lblAsterisk.Style.Add("left", "30px")
                    lblAsterisk.Style.Add("top", "73px")
                    lblReadyOnlyMessage.Visible = False
                    validationBoxStyle()
                    Exit Sub
                End If
        
                If cboDesignPhase.SelectedValue = "none" Then
                    lblMessage.Text = validationText & "Form Category.</li>"
                    lblAsterisk.Text = "*"
                    lblAsterisk.Style.Add("left", "30px")
                    lblAsterisk.Style.Add("top", "112px")
                    lblReadyOnlyMessage.Visible = False
                    validationBoxStyle()
                    Exit Sub
                End If
        
                If txtFormTitle.Text = "" Then
                    lblMessage.Text = validationText & "Form Title.</li>"
                    lblAsterisk.Text = "*"
                    lblAsterisk.Style.Add("left", "30px")
                    lblAsterisk.Style.Add("top", "148px")
                    lblReadyOnlyMessage.Visible = False
                    validationBoxStyle()
                    Exit Sub
                End If
        
                If txtDescription.Text = "" Then
                    lblMessage.Text = validationText & "Description.</li>"
                    lblAsterisk.Text = "*"
                    lblAsterisk.Style.Add("left", "30px")
                    lblAsterisk.Style.Add("top", "189px")
                    lblReadyOnlyMessage.Visible = False
                    validationBoxStyle()
                    Exit Sub
                End If
                lblMessage.Visible = True
                Dim isFile As String = "NO"
                
                For Each File As Telerik.Web.UI.UploadedFile In uplFormFileName.UploadedFiles
                    isFile = "YES"
                Next
                 
                If isFile = "NO" Then
                    lblMessage.Text = validationText & "Select a New Form.</li>"
                    lblAsterisk.Text = "*"
                    lblAsterisk.Style.Add("left", "455px")
                    lblAsterisk.Style.Add("top", "89px")
                    validationBoxStyle()
                ElseIf isFile = "YES" Then
                    lblMessage.Text = ""
                    lblAsterisk.Text = ""
                    saveFormData("New")
                    'roCurrentFile.Text = Session("Path")
                    'configReadOnly()
                    'configEdit()
                    configExistingAfterNewSave()
                End If
                
            Case "Edit"
                If txtFormDate.SelectedDate Is Nothing Then
                    lblMessage.Text = validationText & "Form Date.</li>"
                    lblAsterisk.Text = "*"
                    lblAsterisk.Style.Add("left", "30px")
                    lblAsterisk.Style.Add("top", "73px")
                    lblReadyOnlyMessage.Visible = False
                    validationBoxStyle()
                    Exit Sub
                End If
        
                If cboDesignPhase.SelectedValue = "none" Then
                    lblMessage.Text = validationText & "Form Category.</li>"
                    lblAsterisk.Text = "*"
                    lblAsterisk.Style.Add("left", "30px")
                    lblAsterisk.Style.Add("top", "112px")
                    lblReadyOnlyMessage.Visible = False
                    validationBoxStyle()
                    Exit Sub
                End If
        
                If txtFormTitle.Text = "" Then
                    lblMessage.Text = validationText & "Form Title.</li>"
                    lblAsterisk.Text = "*"
                    lblAsterisk.Style.Add("left", "30px")
                    lblAsterisk.Style.Add("top", "148px")
                    lblReadyOnlyMessage.Visible = False
                    validationBoxStyle()
                    Exit Sub
                End If
        
                If txtDescription.Text = "" Then
                    lblMessage.Text = validationText & "Description.</li>"
                    lblAsterisk.Text = "*"
                    lblAsterisk.Style.Add("left", "30px")
                    lblAsterisk.Style.Add("top", "189px")
                    lblReadyOnlyMessage.Visible = False
                    validationBoxStyle()
                    Exit Sub
                End If
                lblMessage.Visible = True
                Dim isFile As String = "NO"
                For Each File As Telerik.Web.UI.UploadedFile In uplFormFileName.UploadedFiles
                    isFile = "YES"
                Next
                If isFile = "YES" Then
                    removeFile(roCurrentFile.Text)
                End If
                saveFormData("Update")
            Case "Upload"
                uploadFile()
                cboActionSelect.SelectedValue = "Edit Form"
                configReadOnly()
            Case "Remove"
                removeForm()
                butCancel_Click()
        End Select
    End Sub
    
    Private Sub configDelete()
        Threading.Thread.Sleep(500)
        cboActionSelect.Visible = False
        butSave.Visible = False
        butDeleteFile.Visible = False
        txtFormDate.Visible = False
        roFormDate.Visible = True
        txtFormTitle.Enabled = False
        roFormTitle.Enabled = True
        txtDescription.Enabled = False
        cboDesignPhase.Visible = False
        roDesignPhase.Visible = True
        uplFormFileName.Visible = False
        lblFormUpload.Visible = False
        formStatus = "Disabled"
        getData()
        Threading.Thread.Sleep(500)
        roCurrentFile.Text = "File Removed"
        roCurrentFile.Style.Add("color", "red")
        imgFileIcon.ImageUrl = "images/status_red1.png"
        lblReadyOnlyMessage.Visible = True
        lblReadyOnlyMessage.Text = "File Removed"
        lblReadyOnlyMessage.Style.Add("color", "red")
    End Sub
    
    Private Sub butDelete_Click() Handles butDeleteFile.Click
        Session("Disabled") = "Disabled"
        EditType = "Delete"
        formStatus = "Disabled"
        saveButton.Value = "Remove"
        'Session("Disabled") = String.Empty
        saveFormData("Update")
        configDelete()
    End Sub
    
    Private Sub getFileImage()
        Dim FileIcon As String = ""
        Dim xFileName As String = ""
        xFileName = Session("FormFileName")
        If xFileName.Contains(".xls") Then
            FileIcon = "images/prompt_xls.gif"
        ElseIf xFileName.Contains(".xlsx") Then
            FileIcon = "images/prompt_xls.gif"
        ElseIf xFileName.Contains(".pdf") Then
            FileIcon = "images/prompt_pdf.gif"
        ElseIf xFileName.Contains(".doc") Then
            FileIcon = "images/prompt_doc.gif"
        ElseIf xFileName.Contains(".zip") Then
            FileIcon = "images/prompt_zip.gif"
        ElseIf xFileName = "" Then
            imgFileIcon.Visible = False
        Else
            FileIcon = "images/prompt_page.gif"
        End If
        imgFileIcon.ImageUrl = FileIcon
        'lblMessage.Text = xFileName
        'lblMessage.Style.Add("top", "270")
    End Sub
</script>
<html>
<head>
    <title id="title">
        <%= sTitle %></title>
    <link href="Styles.css" type="text/css" rel="stylesheet" />
    <script type="text/javascript" language="javascript">
        function GetRadWindow() {
            var oWindow = null;
            if (window.RadWindow) oWindow = window.RadWindow;
            else if (window.frameElement.radWindow) oWindow = window.frameElement.radWindow;
            return oWindow;
        }

        function ShowHelp()     //for help display
        {

            var oWnd = window.open("help_view.aspx?WinType=RAD", "ShowHelpWindow");
            return false;
        }
    </script>
    </script>
</head>
<body>
    <form id="form1" runat="server">
    <telerik:RadScriptManager ID="RadScriptManager1" runat="server" />
    <asp:HiddenField ID="saveButton" runat="server"></asp:HiddenField>
    <asp:HiddenField ID="configType" runat="server"></asp:HiddenField>
    <asp:HiddenField ID="categoryID" runat="server"></asp:HiddenField>
    <asp:HyperLink ID="butHelp" Style="position: absolute; left: 713px; top: 3px" runat="server" ImageUrl="images/button_help.gif">HyperLink</asp:HyperLink>

    <!--Form Details Box-->
    <div id="FormDetailBox" runat="server" style="position: absolute; display: block;
        float: left; clear: both; border: 4px solid #CCC; margin-top: 25px; width: 400px; height: 260px; margin-left: 16px;">
        <asp:Label ID="lblFormDetails" runat="server" Visible="true" Style="position: absolute; left: 60px; color: #666; top: -15px; font-weight: bold; font-size: 14px; background-color: #e7e9ed;
            padding: 3px;">Form Details:</asp:Label>
        <!--Document Owner-->
        <asp:Label ID="lblDocumentOwner" runat="server" Text="Document Owner:" Style="position: absolute;
            left: 15px; top: 15px;" Visible="True"></asp:Label>
        <asp:Label ID="roDocumentOwnerDisplay" runat="server" Text="" Style="position: absolute;
            left: 120px; top: 15px; font-weight: bold; float: left;" Visible="True"></asp:Label>
        <!--Form Date-->
        <asp:Label ID="lblFormDate" runat="server" Text="Form Date:" Style="position: absolute;
            left: 15px; top: 50px">
        </asp:Label>
        <telerik:RadDatePicker ID="txtFormDate" runat="server" Width="120px" Skin="Web20"
            Style="position: absolute; top: 45px; left: 90px">
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
        </telerik:RadDatePicker>
        <asp:Label ID="roFormDate" runat="server" Style="position: absolute; left: 90px;
            top: 50px; font-size: 12px; font-weight: bold">
        </asp:Label>
        <!--Form Categories and dropdown-->
        <asp:Label ID="lblPhase" runat="server" Style="position: absolute; left: 15px; top: 85px;
            z-index: 100">Category:</asp:Label>
        <telerik:RadComboBox ID="cboDesignPhase" Width="110" runat="server" Style="z-index: 508;
            left: 90px; position: absolute; top: 85px;" Skin="Vista" TabIndex="7" AutoPostBack="false"
            Visible="True" Text="(Status)">
            <Items>
                <telerik:RadComboBoxItem runat="server" Text="Not Selected" Value="none" />
                <telerik:RadComboBoxItem runat="server" Text="PrePlanning" Value="PrePlanning" />
                <telerik:RadComboBoxItem runat="server" Text="Planning" Value="Planning" />
                <telerik:RadComboBoxItem runat="server" Text="Design" Value="Design" />
                <telerik:RadComboBoxItem runat="server" Text="DSA" Value="DSA" />
                <telerik:RadComboBoxItem runat="server" Text="Bidding" Value="Bidding" />
                <telerik:RadComboBoxItem runat="server" Text="Construction" Value="Construction" />
                <telerik:RadComboBoxItem runat="server" Text="Close-out" Value="Close-out" />
            </Items>
        </telerik:RadComboBox>
        <asp:Label ID="roDesignPhase" runat="server" Style="position: absolute; left: 90px;
            top: 85px; font-size: 12px; font-weight: bold; z-index: 100">
        </asp:Label>
        <!-- Form Title -->
        <asp:Label ID="lblFormTitle" runat="server" Text="Form Title:" Style="position: absolute;
            left: 15px; top: 125px;">
        </asp:Label>
        <asp:TextBox ID="txtFormTitle" MaxLength="100" runat="server" Height="27px" Width="290px"
            Style="position: absolute; left: 90px; top: 120px; vertical-align: top; z-index: 100;"
            CssClass="EditDataDisplay">
        </asp:TextBox>
        <asp:Label ID="roFormTitle" runat="server" Style="position: absolute; left: 90px;
            top: 125px; font-size: 12px; font-weight: bold; width: 290px;">
        </asp:Label>
        <!--Description-->
        <asp:Label ID="lblDescription" runat="server" Text="Description:" Style="position: absolute;
            left: 15px; top: 165px">
        </asp:Label>
        <asp:TextBox ID="txtDescription" MaxLength="100" runat="server" Height="75px" Width="290px"
            TabIndex="2" Style="position: absolute; left: 90px; top: 160px; vertical-align: top;
            z-index: 100; resize: none;" TextMode="MultiLine" CssClass="EditDataDisplay"></asp:TextBox>
        <asp:Label ID="roDescription" runat="server" Style="position: absolute; left: 90px;
            top: 165px; font-size: 12px; font-weight: bold; width: 290px">
        </asp:Label>
    </div>
    <!--Form Action box-->
    <div id="FileAction" runat="server" style="position: absolute; display: block; float: left;
        clear: both; border: 2px solid #CCC; margin-top: 10px; width: 265px; height: 81px;
        margin-left: 455px;">
        <!--Form Action Management label-->
        <asp:Label ID="lblAction" runat="server" Style="position: absolute; left: 45px; color: #666;
            top: -15px; font-weight: bold; font-size: 14px; background-color: #e7e9ed; padding: 3px;">Form Action:</asp:Label>
        <telerik:RadComboBox ID="cboActionSelect" Width="130" runat="server" Style="z-index: 505;
            left: 45px; position: absolute; top: 25px;" Skin="Vista" TabIndex="7" AutoPostBack="true"
            Visible="True" Text="(Status)">
        </telerik:RadComboBox>
        <asp:Label ID="lblFormFileName" Visible="false" Class="EditDataDisplay" runat="server"
            Height="24px" Style="position: absolute; left: 120px; top: 130px">
        (None Attached)</asp:Label>
        <asp:Label ID="lblReadyOnlyMessage" runat="server" Style="left: 45px; position: absolute;
            color: Green; font-weight: bold; font-size: 16px; top: 25px;" Visible="True">Read Only</asp:Label>
    </div>
    <!--Form Categories box-->
    <div id="FileCategories" runat="server" style="border: 2px solid #CCC; float: left;
        clear: both; display: block; margin-top: 145px; width: 265px; height: 80px; margin-left: 455px;">
        <!--Categories Management label
    <asp:Label ID="lblCategoryManager" runat="server" Visible=true Style="position: absolute; left: 490px;color:#666;top: 145px;font-weight:bold;font-size:14px;background-color:#e7e9ed;padding:3px;">Category Management:</asp:Label>-->
        <!--Form Categories and dropdown-->
        <!--Sub Phase
    <asp:Label ID="lblSubPhase" runat="server" Style="position: absolute; left: 470px;
        top: 210px;">
        Sub-Category:</asp:Label>
    <telerik:RadComboBox ID="cboSubDesign" Width="160" runat="server" Style="z-index: 90;
        left: 560px; position: absolute; top: 210px; background-color: white !important;
        filter: chroma(color=white) !important;" Skin="Vista" TabIndex="7" AutoPostBack="false"
        Visible="True" Text="(Status)">
    </telerik:RadComboBox>
    <asp:Label ID="roSubDesign" runat="server" Style="position: absolute; left: 560px;
        top: 210px; font-size: 12px; font-weight: bold">
    </asp:Label>-->
    </div>

    <!--File Management box-->
    <div id="FileManagement" runat="server" style="position: absolute; display: block;
        float: left; clear: both; border: 4px solid #CCC; margin-top: 25px; width: 300px;
        height: 215px; margin-left: 444px;">
        <!--File Management label-->
        <asp:Label ID="lblFileManager" runat="server" Visible="true" Style="position: absolute;
            left: 60px; color: #666; top: -15px; font-weight: bold; font-size: 14px; background-color: #e7e9ed;
            padding: 3px;">File Management:</asp:Label>
        <!--Current Form File-->
        <asp:Label ID="lblFormFile" runat="server" Style="position: absolute; left: 15px;
            top: 15px">Current Form:</asp:Label>
        <asp:ImageButton ID="imgFileIcon" runat="server" Style="position: absolute; left: 15px;
            top: 35px" ImageUrl="images/prompt_page.gif" Visible="true" />
        <asp:Label ID="roCurrentFile" runat="server" wrap="true" rows=2 TextMode="MultiLine" BorderStyle="None" BorderWidth=0 Style="position: absolute; left: 35px; top: 35px; width:252px; overflow:hidden; font-weight: bold; font-size: 12px;word-wrap: normal; word-break: break-all;"></asp:Label>
        <telerik:RadComboBox ID="cboCurrentFile" Width="250" runat="server" Style="z-index: 507; left: 15px; position: absolute; top: 100px;" Skin="Vista" TabIndex="7" AutoPostBack="false"
            Visible="False" Text="(Status)">
        </telerik:RadComboBox>
        <!--Below RadUpload is the control to upload/select forms-->
        <asp:Label ID="lblFormUpload" runat="server" Style="position: absolute; z-index: 100;  left: 15px; top: 70px; width: 150px">Select a New Form: </asp:Label>
        <telerik:RadAsyncUpload ID="uplFormFileName" runat="server" Style="position: absolute; z-index: 100; left: 15px; top: 90px; width: 150px" MaxFileInputsCount="1" OnClientFileSelected="OnClientFileSelected"
            ControlObjectsVisibility="None" />
    </div>
    <!--buttons-->
    <asp:ImageButton ID="butUploadForm" TabIndex="5" runat="server" Style="position: absolute;
        left: 470px; top: 270px; z-index: 100" autopostback="true" ImageUrl="images/button_save.png" />
    <asp:ImageButton ID="butDeleteFile" TabIndex="5" runat="server" Style="position: absolute;
        left: 560px; top: 270px" ImageUrl="images/button_remove.png" Visible="false" />
    <asp:ImageButton ID="butSave" TabIndex="5" runat="server" Style="position: absolute;
        left: 470px; top: 270px; z-index: 2" autopostback="true" ImageUrl="images/button_save.png"
        Visible="false" />
    <asp:ImageButton ID="butCancel" TabIndex="5" runat="server" Style="position: absolute;
        left: 650px; top: 270px" autopostback="true" ImageUrl="images/button_cancel.png"
        Visible="true" />
    <!--Error message-->
    <asp:Label ID="lblAsterisk" runat="server" Height="24px" Font-Bold="True" ForeColor="Red"
        Style="position: absolute; left: 450px; top: 325px;">
    </asp:Label>
    <asp:Label ID="lblMessage" runat="server" Height="24px" ForeColor="Red" Style="position: absolute;
        left: 480px; top: 200px; width: 250px;">
    </asp:Label>
    <telerik:RadWindowManager ID="RadPopups" runat="server" />
    <asp:Label ID="devDisplay" runat="server" Style="position: absolute; left: 23px;
        top: 235px" Visible="false"></asp:Label>
    <!--Current User at bottom-->
    <asp:Label ID="lblCurrentUser" Style="z-index: 105; left: 35px; position: absolute;
        top: 298px" runat="server">Current User:</asp:Label>
    <asp:Label ID="lblUserDisplay" Style="z-index: 105; left: 110px; position: absolute;
        top: 298px" runat="server">Display</asp:Label>
    </form>
    <telerik:RadScriptBlock ID="RadScriptBlock1" runat="server">
        <script type="text/javascript" language="javascript">
            function OnClientFileSelected(sender, args) {

                var zfile = document.getElementById('<% = uplFormFileName.ClientID %>').file
                //alert(zfile);
                //document.getElementById('<% = butSave.ClientID %>').style.display = 'inline'
            }
        </script>
    </telerik:RadScriptBlock>
</body>
</html>
