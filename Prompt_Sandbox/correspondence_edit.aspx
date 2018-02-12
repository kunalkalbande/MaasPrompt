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
    Private nContractID As Integer
    Private contID As Integer
    Private nContactID As Integer
    Private strPhysicalPath As String
    Private corrID As Integer
    Private isAuthor As Boolean
    
    Private Sub Page_Load(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MyBase.Load
        
        ProcLib.CheckSession(Page)
        ProcLib.LoadPopupJscript(Page)
        sTitle = "Correspondence Edit Window"
        'sTitle = Request.QueryString("ProjectID")
        Session("PageID") = "CorrespondenceEdit"
        
        EditType = Request.QueryString("DisplayType")
                                                             
        Dim sContactName As String
        Using db As New RFI
            nContactID = db.getContactID(Session("UserID"), Session("DistrictID"))
            Dim ContactData As Object = db.getContactData(nContactID, Session("DistrictID"))
            Session("ParentContactID") = ContactData(0)
            Session("ContactType") = ContactData(1)
            sContactName = ContactData(2)
        End Using
        
        If EditType = "New" Then
            If Not IsPostBack Then
                configNew()
                'cboProjectSelect.SelectedValue = Request.QueryString("ProjectID")
            End If
        End If
        
        If EditType = "Existing" Then
            corrID = Request.QueryString("corrID")
            Using db As New Correspondence
                Dim author As Integer = db.getAuthor(corrID)
                If author = nContactID Then
                    cboActionSelect.Visible = True
                Else
                    cboActionSelect.Visible = False
                End If
                'lblMessage.Text = author & " - " & nContactID
            End Using
            If Not IsPostBack Then
                configReadOnly()
            End If                   
        End If
        
        roDevelopmentData.Text = Session("UserName") & " - " & nContactID & " : " & corrID
        
        Using db As New RFI
            Try
                'contID = db.getContactID(Session("UserID"), Session("DistrictID"))
            Catch
            End Try
        End Using
        
        If Not IsPostBack Then
            'nProjectID = Request.QueryString("ProjectID")
            
            Using db As New RFI
                With cboProjectSelect
                    .DataValueField = "ProjectID"
                    .DataTextField = "ProjectName"
                    .DataSource = db.getUserProjects(nContactID)
                    .DataBind()
                End With
            End Using

            cboProjectSelect.SelectedValue = nProjectID
            
            getProjectContracts(nProjectID)
            
            With cboActionSelect
                .DataValueField = "Action"
                .DataTextField = "ActionText"
                .DataSource = buildActionDropdown()
                .DataBind()
            End With
            
            If Request.QueryString("Action") <> "" Then
                If Request.QueryString("Action") = "AddRecipient" Then
                    cboActionSelect.SelectedValue = "Select Recipients"
                ElseIf Request.QueryString("Action") = "RemoveRecipient" Then
                    cboActionSelect.SelectedValue = "Remove Recipients"
                End If
                cboActionSelect_Change()
            End If                    
        End If
        
        If Not IsPostBack Then
            If EditType = "Existing" Then getData(corrID)
        End If
            
        
        
        strPhysicalPath = ProcLib.GetCurrentAttachmentPath() & "DistrictID_" & HttpContext.Current.Session("DistrictID") & "/_apprisedocs/_Correspondence/"
        
    End Sub
        
    Private Sub configNew()
        lblActionSelect.Visible = False
        cboActionSelect.Visible = False
        chkOverwrite.Visible = False
        lblOverwrite.Visible = False
        lblFileName.Visible = False
        cboContractSelect.Visible = False
        uplCorrespondence.Visible = True
        cboRecipients.Visible = False
        roRecipients.Visible = False
        saveButton.Value = "New"
        Dim alertText As String = "This action will create a corespondence record and upload the selected file."
        alertText &= "\n\n\Do you want to continue?"
        butSave.OnClientClick = "return confirm('" & alertText & "')" 
    End Sub
    
    Private Sub configReadOnly()
        cboLevelSelect.Visible = False
        roLevelSelect.Visible = True
        cboProjectSelect.Visible = False
        roProjectSelect.Visible = True
        cboProjectSelect.Visible = False
        roProjectSelect.Visible = True
        cboContractSelect.Visible = False
        roContractSelect.Visible = True
        cboTypeSelect.Visible = False
        roTypeSelect.Visible = True
        txtCorrName.Visible = False
        roCorrName.Visible = True
        uplCorrespondence.Visible = False
        butSave.Visible = False
        chkOverwrite.Visible = False
        lblOverwrite.Visible = False
        cboRecipients.Visible = False
        roRecipients.Visible = False
    End Sub
    
    Private Sub configEdit()
        cboLevelSelect.Visible = False
        roLevelSelect.Visible = True
        cboProjectSelect.Visible = False
        roProjectSelect.Visible = True
        cboContractSelect.Visible = False
        roContractSelect.Visible = True
        cboTypeSelect.Visible = True
        roTypeSelect.Visible = False
        txtCorrName.Visible = True
        roCorrName.Visible = False
        uplCorrespondence.Visible = False
        butSave.Visible = True
        'butSave.Visible = False
        chkOverwrite.Visible = False
        lblOverwrite.Visible = False
        cboRecipients.Visible = False
        saveButton.Value = "Edit"
        butSave.ImageUrl = "images/button_save.png"
        Dim alertText As String = "This action will update this Correspondence data."
        alertText &= "\n\n\Do you want to continue?"
        butSave.OnClientClick = "return confirm('" & alertText & "')"
    End Sub
    
    Private Sub configUpload()
        configReadOnly()
        roRecipients.Visible = false
        uplCorrespondence.Visible = True
        butSave.Visible = False
        saveButton.Value = "Upload"
        Dim alertText As String = "This action will replace the current file."
        alertText &= "\n\n\Do you want to continue?"
        butSave.OnClientClick = "return confirm('" & alertText & "')"
        butSave.ImageUrl = "images/button_save.png"
    End Sub
    
    Private Sub configRemove()
        configReadOnly()
        butSave.Visible = True
        butSave.ImageUrl = "images/button_remove.png"
        saveButton.Value = "Remove"
        Dim alertText As String = "This action will remove this correspondence. All access will be lost."
        alertText &= "\n\n\Do you want to continue?"
        butSave.OnClientClick = "return confirm('" & alertText & "')"
    End Sub
    
    Private Sub configRecipients(proc As String)
        configReadOnly()
        cboRecipients.Visible = True
        roRecipients.Visible = False
        butSave.Visible = False            

        If proc = "Add" Then
            butSave.ImageUrl = "images/button_add.png"
            saveButton.Value = "AddRecipient"
        ElseIf proc = "Remove" Then
            butSave.ImageUrl = "images/button_remove.png"
            saveButton.Value = "RemoveRecipient"
        End If
    End Sub
    
    Private Sub removeCorrespondence()
        Using db As New Correspondence
            db.removeCorrespondence(corrID)
        End Using
    End Sub
 
    Private Sub removeFile(file As String)
        Dim targetPath As String
        Dim sourcePath As String
        If Trim(cboLevelSelect.SelectedValue) = "Project" Then
            targetPath = strPhysicalPath & "\_ProjectID_" & cboProjectSelect.SelectedValue & "\DeletedFiles"
            sourcePath = strPhysicalPath & "\_ProjectID_" & cboProjectSelect.SelectedValue & "\"
        Else
            targetPath = strPhysicalPath & "\_ProjectID_" & cboProjectSelect.SelectedValue & "\ContractID_" & cboContractSelect.SelectedValue & "\DeletedFiles"
            sourcePath = strPhysicalPath & "\_ProjectID_" & cboProjectSelect.SelectedValue & "\ContractID_" & cboContractSelect.SelectedValue & "\"
        End If
        
        checkDirectory(targetPath)
        'Dim file As String = roFileName.Text
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
        newFileName = count & "_" & d & "_" & fileName & "_" & contID & ext
        Try
            IO.File.Copy(sourcePath & "\" & file, targetPath & "\" & newFileName, True)
            IO.File.Delete(sourcePath & "\" & file)
        Catch ex As Exception
        End Try
        
    End Sub
    
    Private Sub getData(corrID As Integer)
        Dim tbl As DataTable
        
        Using db As New Correspondence
            tbl = db.getCorrespondenceData(corrID)
        End Using
        
        cboLevelSelect.SelectedValue = tbl.Rows(0).Item("CorrLevel")
        If Trim(tbl.Rows(0).Item("CorrLevel")) = "Contract" Then
            cboContractSelect.Visible = False
            roContractSelect.Visible = True
        End If
        roLevelSelect.Text = tbl.Rows(0).Item("CorrLevel")
        cboProjectSelect.SelectedValue = tbl.Rows(0).Item("ProjectID")
        Using db As New Correspondence
            roProjectSelect.Text = db.getProjectName(tbl.Rows(0).Item("ProjectID"))
        End Using
       
        If tbl.Rows(0).Item("ContractID") = 0 Then
            roContractSelect.Text = "Not Applicable"
        Else
            Session("ContractID") = tbl.Rows(0).Item("ContractID")
            roContractSelect.Text = tbl.Rows(0).Item("ContractID")
            cboContractSelect.SelectedValue = tbl.Rows(0).Item("ContractID")
        End If
        
        Session("ProjectID") = tbl.Rows(0).Item("ProjectID")
        cboTypeSelect.SelectedValue = tbl.Rows(0).Item("CorrType")
        roTypeSelect.Text = tbl.Rows(0).Item("CorrType")
        txtCorrName.Text = tbl.Rows(0).Item("CorrName")
        roCorrName.Text = tbl.Rows(0).Item("CorrName")
        roFileName.Text = tbl.Rows(0).Item("FileName")
        
        Using db As New Correspondence
            roRecipients.Text = db.createRecipientList(corrID)
        End Using
                                    
    End Sub
    
    Private Function buildActionDropdown() As DataTable
        
        Dim tbl As DataTable
        tbl = New DataTable("tbl")
                
        tbl.Columns.Add("Action", GetType(System.String))
        tbl.Columns.Add("ActionText", GetType(System.String))
        tbl.Rows.Add("none", "Review")
        tbl.Rows.Add("Edit", "Edit")
        'tbl.Rows.Add("Upload", "Upload/Replace File")
        'tbl.Rows.Add("Remove", "Remove Correspondence")
        'tbl.Rows.Add("Select Recipients", "Add Recipients")
        'tbl.Rows.Add("Remove Recipients", "Remove Recipients")
        Return tbl
    End Function
    
    Private Sub buildMembersDropdown()
        Dim switch As String
        Dim tbl As DataTable
        Dim tblChk As New DataTable
        Dim cboTbl As New DataTable
        
        cboTbl.Columns.Add("ContactID", GetType(System.Int32))
        cboTbl.Columns.Add("Name", GetType(System.String))
        cboTbl.Columns.Add("Company", GetType(System.String))
        
        Using db As New TeamMember
            tbl = db.GetExistingMembers(Session("ProjectID"))
        End Using
        
        If Not IsPostBack Then
            If cboActionSelect.SelectedValue = "Remove Recipients" Then
                switch = "Remove Recipients"
            Else
                switch = "Select Recipients"
            End If  
        Else
            switch = cboActionSelect.SelectedValue
        End If
               
        Using dbchk As New Correspondence
            For Each row As DataRow In tbl.Rows
                tblChk = dbchk.checkRecipient(corrID, row.Item("ContactID"))
                If row.Item("ContactID") <> nContactID Then
                    If tblChk.Rows.Count > 0 Then
                        If switch = "Select Recipients" Then
                            If tblChk.Rows(0).Item("IsActive") = 0 Then
                                cboTbl.Rows.Add(row.Item("ContactID"), row.Item("Name"), row.Item("Company"))
                            End If
                        ElseIf switch = "Remove Recipients" Then
                            If tblChk.Rows(0).Item("IsActive") = 1 Then
                                cboTbl.Rows.Add(row.Item("ContactID"), row.Item("Name"), row.Item("Company"))
                            End If
                        End If
                    Else
                        If switch = "Select Recipients" Then
                            cboTbl.Rows.Add(row.Item("ContactID"), row.Item("Name"), row.Item("Company"))
                        End If
                    End If
                End If
            Next
        End Using
        
        Dim newrow As DataRow = cboTbl.NewRow
        newrow("ContactID") = 0
        newrow("Name") = "None"
        newrow("Company") = "None"
        cboTbl.Rows.InsertAt(newrow, 0)
 
        cboRecipients.Items.Clear()
        
        With cboRecipients
            .DataValueField = "ContactID"
            .DataTextField = "Name"
            .DataSource = cboTbl
            .DataBind()
        End With
        
    End Sub
       
    Private Sub cboActionSelect_Change() Handles cboActionSelect.SelectedIndexChanged
        Select Case cboActionSelect.SelectedValue
            Case "none"
                configReadOnly()
            Case "Edit"
                configEdit()
            Case "Upload"
                configUpload()
            Case "Remove"
                configRemove()
            Case "Select Recipients"
                configRecipients("Add")
                buildMembersDropdown()
            Case "Remove Recipients"
                configRecipients("Remove")
                buildMembersDropdown()
        End Select
        'lblMessage.Text = cboLevelSelect.SelectedValue & " - " & cboContractSelect.SelectedValue
    End Sub
    
    Private Sub cboRecipients_change() Handles cboRecipients.SelectedIndexChanged
        If cboRecipients.SelectedValue <> 0 Then
            butSave.Visible = True
        Else
            butSave.Visible = False
        End If
    End Sub
    
    Private Sub checkDirectory(dir As String)
        Dim folder As New DirectoryInfo(dir)
        If Not folder.Exists Then  'create the folder
            folder.Create()
        End If
    End Sub
    
    Private Function createCorrespondenceNumber() As String
        Dim corrNum As String = ""
        Dim project As Integer = cboProjectSelect.SelectedValue
        Dim level As String = cboLevelSelect.SelectedValue
        Dim contID As Integer
        
        If level = "Project" Then
            contID = 0
        Else
            Try
                contID = cboContractSelect.SelectedValue
            Catch ex As Exception
            End Try           
        End If         
        
        Dim dir As String
        
        Using db As New Correspondence
            Dim tbl As DataTable = db.getRecordsCount(project, contID, level)
            Dim projNum As String = db.getProjectNumber(project)
            Dim count As Integer = tbl.Rows.Count
            If level = "Project" Then
                corrNum = "CORR-" & projNum & "-" & count + 1
                dir = strPhysicalPath & "_ProjectID_" & project
            Else
                corrNum = "CORR-" & projNum & "-" & contID & "-" & count + 1
                dir = strPhysicalPath & "_ProjectID_" & project & "/ContractID_" & contID
            End If
        End Using
        sTitle = "New Correspondence:# " & corrNum
        'checkDirectory(dir)
              
        Return corrNum
    End Function
    
    Private Sub getProjectContracts(projectID As Integer)
    
        Using db As New ChangeOrders
            Dim tbl As DataTable = db.getProjectContracts(projectID, Session("ContactType"), nContactID)
            'Dim tbl As DataTable = db.getAllProjectContracts(nProjectID, False, Session("ContactType"), "")
            Dim conTbl As DataTable
            conTbl = New DataTable("resTbl")
            conTbl.Columns.Add("ContractID", GetType(System.String))
            conTbl.Columns.Add("CompanyName", GetType(System.String))
            'conTbl.Rows.Add("0", "0")
                
            For Each row As DataRow In tbl.Rows
                conTbl.Rows.Add(row.Item("ContractID"), row.Item("ContractID") & " - " & row.Item("Name"))
            Next
                
            With cboContractSelect
                .DataValueField = "ContractID"
                .DataTextField = "CompanyName"
                .DataSource = conTbl
                .DataBind()
            End With
        End Using
        
        If EditType = "New" Then createCorrespondenceNumber()
    End Sub
    
    Private Sub butCancel_Click() Handles butCancel.Click
        Session("RtnFromEdit") = True
        ProcLib.CloseAndRefreshRADNoPrompt(Page)
    End Sub
    
    Private Sub cboProjectSelect_Change() Handles cboProjectSelect.SelectedIndexChanged
        getProjectContracts(cboProjectSelect.SelectedValue)     
    End Sub
    
    Private Sub cboTypeSelect_Change() Handles cboTypeSelect.SelectedIndexChanged
        
    End Sub
    
    Private Sub cboContractSelect_Change() Handles cboContractSelect.SelectedIndexChanged
        createCorrespondenceNumber()
    End Sub
    
    Private Sub cboLevelSelect_Change() Handles cboLevelSelect.SelectedIndexChanged
        If cboLevelSelect.SelectedValue = "Project" Then
            cboContractSelect.Visible = False
            roContractSelect.Visible = True
            roContractSelect.Text = "Not Applicable"
        ElseIf cboLevelSelect.SelectedValue = "Contract" Then
            cboContractSelect.Visible = True
            roContractSelect.Visible = False
        End If
        
        Dim corrNum As String
        Try
            corrNum = createCorrespondenceNumber()
        Catch ex As Exception

        End Try
        
        getProjectContracts(cboProjectSelect.SelectedValue)
        
        'sTitle = corrNum
             
    End Sub
    
    
    Private Sub saveCorrespondenceData(saveType As String)
        Dim fileName As String = ""
        Dim obj(12) As Object
        Dim temp As String
        
        If saveType = "New" Then
            Try
                uploadFile()
            Catch ex As Exception
                lblMessage.Text = "There was a problem uploading this file."
                Exit Sub
            End Try
        End If
        
        For Each File As Telerik.Web.UI.UploadedFile In uplCorrespondence.UploadedFiles
            fileName = File.GetName
        Next
                                  
        obj(0) = saveType
        Try
            obj(1) = createCorrespondenceNumber()
        Catch ex As Exception
            lblMessage.Text = "There was a problem creating the correspondence number."
            Exit Sub
        End Try
        obj(2) = cboLevelSelect.SelectedValue
        obj(3) = cboProjectSelect.SelectedValue
        If obj(2) = "Project" Then
            obj(4) = 0
        Else
            obj(4) = cboContractSelect.SelectedValue
        End If 
        obj(5) = cboTypeSelect.SelectedValue
        obj(6) = txtCorrName.Text
        obj(7) = fileName
        obj(8) = Session("DistrictID")
        obj(9) = Now
        obj(10) = nContactID
        obj(11) = corrID
        
        Using db As New Correspondence
            temp = db.saveCorrespondenceData(obj)
            If saveType = "New" Then
                Threading.Thread.Sleep(1000)
                corrID = db.getCorrID(obj(1))
            End If
        End Using
               
        If saveType = "Update" Then Session("UpdateData") = True
        
        'lblMessage.Text = temp
        
        Response.Redirect("correspondence_edit.aspx?ProjectID= " & nProjectID & "&corrID=" & corrID & "&DisplayType=Existing")
        
    End Sub
    
    Private Sub uploadFile()
        Dim filePath As String
        If EditType = "Existing" Then
            cboLevelSelect.SelectedValue = Trim(roLevelSelect.Text)
        End If
        
        If Trim(cboLevelSelect.SelectedValue) = "Contract" Then
            filePath = strPhysicalPath & "_ProjectID_" & cboProjectSelect.SelectedValue & "/ContractID_" & cboContractSelect.SelectedValue & "/" & nContactID & "/"
        Else
            filePath = strPhysicalPath & "_ProjectID_" & cboProjectSelect.SelectedValue & "/" & nContactID & "/"
        End If
        
        checkDirectory(filePath)
        
        For Each File As Telerik.Web.UI.UploadedFile In uplCorrespondence.UploadedFiles
            If EditType = "Existing" Then
                Using db As New Correspondence
                    db.updateFileName(File.GetName, corrID)
                    roFileName.Text = File.GetName
                End Using
            End If
            
            Dim sSaveFile As String = Path.Combine(filePath, File.GetName)
            sSaveFile = sSaveFile.Replace("#", "")
            sSaveFile = sSaveFile.Replace(";", "")
            sSaveFile = sSaveFile.Replace(",", "")
            File.SaveAs(sSaveFile, True)    'overwrite if there
            'lblMessage.Text = cboLevelSelect.SelectedValue & " - " & cboContractSelect.SelectedValue
        Next
       
    End Sub
    
    Private Sub maintainRecipients(opType As String)
        Dim Obj(6) As Object
        Dim saveType As String
        Using db As New Correspondence
            Dim tbl As DataTable = db.checkRecipient(corrID, cboRecipients.SelectedValue)
            If tbl.Rows.Count > 0 Then
                saveType = "Update"
            Else
                saveType = "Insert"
            End If
        End Using      
        
        Obj(0) = corrID
        Obj(1) = cboRecipients.SelectedValue
        Obj(2) = opType
        Obj(3) = nContactID
        Obj(4) = saveType
        If opType = "Remove" Then
            Obj(5) = 0
        ElseIf opType = "Add" Then
            Obj(5) = 1
        End If
        Using db As New Correspondence
            db.processRecipient(Obj)        
        End Using
        
    End Sub
    
    Private Sub butSave_Click() Handles butSave.Click
        Dim alertText As String
        Select Case saveButton.Value
            Case "New"
                lblMessage.Visible = True
                Dim isFile As String = "NO"
                
                For Each File As Telerik.Web.UI.UploadedFile In uplCorrespondence.UploadedFiles
                    isFile = "YES"                  
                Next
                 
                If isFile = "NO" Then
                    lblMessage.Text = "You must select a file to upload."
                ElseIf isFile = "YES" Then
                    lblMessage.Text = ""
                    saveCorrespondenceData("New")
                End If                                            
            Case "Edit"
                saveCorrespondenceData("Update")
            Case "Upload"
                cboContractSelect.SelectedValue = Session("ContractID")
                removeFile(roFileName.Text)
                uploadFile()
                cboActionSelect.SelectedValue = "none"
                configReadOnly()
            Case "Remove"
                removeCorrespondence()
                butCancel_Click()
            Case "AddRecipient"
                maintainRecipients("Add")
                Response.Redirect("Correspondence_edit.aspx?ProjectID=" & Session("ProjectID") & "&CorrID=" & corrID & "&DisplayType=Existing&Action=AddRecipient")
            Case "RemoveRecipient"
                maintainRecipients("Remove")
                Response.Redirect("Correspondence_edit.aspx?ProjectID=" & Session("ProjectID") & "&CorrID=" & corrID & "&DisplayType=Existing&Action=RemoveRecipient")
        End Select
    End Sub
    
</script>

<html>
<head runat="server">
    <link href="Styles.css" type="text/css" rel="stylesheet" />
    <script src="js/jquery-1.10.1.min.js" type="text/javascript"></script>
    <script type="text/javascript" language="javascript">
            function GetRadWindow() {
                var oWindow = null;
                if (window.RadWindow) oWindow = window.RadWindow;
                else if (window.frameElement.radWindow) oWindow = window.frameElement.radWindow;
                return oWindow;
            }
    </script>
    <title><%= sTitle %></title>
</head>
<body>
    <form id="form1" runat="server">
  <telerik:radscriptmanager id="RadScriptManager1" runat="server" />

    <asp:HiddenField ID="saveButton" runat="server">
    </asp:HiddenField>

     <asp:Label ID="lblLevelSelect" runat="server" Text="Correspondence Level:" style="Position:absolute;left:0px;top:12px">
     </asp:Label>

     <telerik:RadComboBox ID="cboLevelSelect" runat="server" Width="100px" Height="100px" Style="z-index: 200;left:130px;
        position:absolute;top:9px;" Skin="Vista"  TabIndex="7" AutoPostBack="true" Visible="true">
        <Items>
            <telerik:RadComboBoxItem runat="server" Text="Project" Value="Project" />
            <telerik:RadComboBoxItem runat="server" Text="Contract" Value="Contract" />    
        </Items>
    </telerik:RadComboBox>

    <asp:Label ID="roLevelSelect" runat="server" style="Position:absolute;left:130px;top:12px;font-weight:bold">
    </asp:Label>

    <asp:Label ID="lblProjectName" runat="server" Text="Project Name:" style="Position:absolute;left:45px;top:42px">
    </asp:Label>

    <telerik:RadComboBox ID="cboProjectSelect" runat="server" Width="300px" Height="100px" Style="z-index: 192; left: 130px;
        position: absolute; top: 42px;" Skin="Vista"  TabIndex="7" AutoPostBack="true" Visible="true">
    </telerik:RadComboBox>

    <asp:Label ID="roProjectSelect" runat="server" Text="Not Applicable" style="Position:absolute;left:130px;top:42px;font-weight:bold">
    </asp:Label>

    <asp:Label ID="lblContractSelect" runat="server" Text="Contract Select:" style="Position:absolute;left:35px;top:72px">
    </asp:Label>

    <telerik:RadComboBox ID="cboContractSelect" runat="server" Width="300px" Height="100px" Style="z-index: 191; left: 130px;
        position: absolute; top: 72px;" Skin="Vista"  TabIndex="7" AutoPostBack="true" Visible="true">
    </telerik:RadComboBox>

    <asp:Label ID="roContractSelect" runat="server" Text="Not Applicable" style="Position:absolute;left:130px;top:72px;font-weight:bold">
    </asp:Label>

     <asp:Label ID="lblCorrespondenceType" runat="server" Text="Correspondence Type:" style="Position:absolute;left:0px;top:102px">
     </asp:Label>

     <telerik:RadComboBox ID="cboTypeSelect" runat="server" Width="200px" Height="100px" Style="z-index: 190;left:130px;
        position:absolute;top:102px;" Skin="Vista"  TabIndex="7" AutoPostBack="false" Visible="true">
        <Items>
            <telerik:RadComboBoxItem runat="server" Text="Not Selected" Value="Not Selected" />
            <telerik:RadComboBoxItem runat="server" Text="DSA" Value="DSA" />
            <telerik:RadComboBoxItem runat="server" Text="Letters" Value="Letters" /> 
            <telerik:RadComboBoxItem runat="server" Text="Notice of Award" Value="Notice of Award" />  
            <telerik:RadComboBoxItem runat="server" Text="Notice of Completion" Value="Notice of Completion" /> 
            <telerik:RadComboBoxItem runat="server" Text="Notice of Intent" Value="Notice of Intent" /> 
            <telerik:RadComboBoxItem runat="server" Text="Notice to Proceed" Value="Notice to Proceed" /> 
            <telerik:RadComboBoxItem runat="server" Text="Sign-off Approval" Value="Sign-off Approval" /> 
            <telerik:RadComboBoxItem runat="server" Text="Transmittals" Value="Transmittals" /> 
            <telerik:RadComboBoxItem runat="server" Text="Other" Value="Other" />      
        </Items>
    </telerik:RadComboBox>

    <asp:Label ID="roTypeSelect" runat="server" style="Position:absolute;left:130px;top:102px;font-weight:bold">
    </asp:Label>


    <asp:Label ID="lblCorrName" runat="server" Text="Description:" style="Position:absolute;left:56px;top:132px">
    </asp:Label>

     <asp:TextBox ID="txtCorrName" runat="server" Height="30px" Width="300px" TabIndex="1"
          style="Position:absolute;left:130px;top:132px;vertical-align:top" textmode="MultiLine" Visible="true"></asp:TextBox>

    <asp:Label ID="roCorrName" runat="server" style="Position:absolute;left:130px;top:132px;font-weight:bold">
    </asp:Label>



    <asp:Label ID="lblFileName" runat="server" Text="Current File:" style="Position:absolute;left:55px;top:182px">
    </asp:Label>

    <asp:Label ID="roFileName" runat="server" style="Position:absolute;left:130px;top:182px;font-weight:bold">
    </asp:Label>

    <asp:Label ID="lblActionSelect" runat="server" Text="Action Select:" style="Position:absolute;left:45px;top:212px">
    </asp:Label>

    <telerik:RadComboBox ID="cboActionSelect" width="190" runat="server" Style="z-index: 180; left: 130px;
            position: absolute; top: 212px;" Skin="Vista"  TabIndex="7" AutoPostBack="true" Visible="True"
            Text="(Status)">              
     </telerik:RadComboBox>
    
    <asp:CheckBox ID="chkOverwrite" runat="server" autopostback="true" Visible="true" style="position:absolute;top:212px;left:130px"/>

    <asp:Label ID="lblOverwrite" runat="server" Text="Overwrite existing file?" style="Position:absolute;left:160px;top:212px;font-weight:bold">
    </asp:Label>


     <asp:ImageButton ID="butSave" runat="server" style="Position:absolute;left:340px;top:212px" visible="true"
            ImageUrl="images/button_save.png"/>

     <asp:ImageButton ID="butCancel" runat="server" style="Position:absolute;left:430px;top:212px" visible="true"
            ImageUrl="images/button_cancel.png" />

     <telerik:RadAsyncUpload ID="uplCorrespondence" runat="server" Style="Position:absolute;z-index:100;left:130px;top:250px;width:150px"
                MaxFileInputsCount=1 OnClientFileSelected="OnClientFileSelected"  ControlObjectsVisibility="None"  />

    <telerik:RadComboBox ID="cboRecipients" runat="server" width="190px" checkboxes="false" Style="z-index: 170;
        left: 130px; position: absolute; top: 250px;" Skin="Vista" Text="(Submitted To)"
        DropDownWidth="395px" MaxHeight="150px" AppendDataBoundItems="True" TabIndex="14" AutoPostBack="true" >
                                          <HeaderTemplate>
                                <table style="width: 390px; text-align: left">
                                    <tr>   
                                    <!--<td></td>-->                                   
                                       <td style="width: 125px;">
                                            Name
                                        </td>
                                        <td style="width: 225px;">
                                            Company
                                        </td>                                    
                                    </tr>
                                </table>
                            </HeaderTemplate>
                            <ItemTemplate>
                                <table style="width: 350px; text-align: left">
                                    <tr>       
                                    <!--<td>
                                        <asp:CheckBox runat="server" ID="chkport" Text="" onclick="stopPropagation(event);"/>
                                    </td>-->                         
                                        <td style="width: 125px;">
                                            <%#DataBinder.Eval(Container.DataItem, "Name")%>
                                        </td>
                                        <td style="width: 225px;">
                                            <%#DataBinder.Eval(Container.DataItem, "Company")%>
                                        </td>
                                    </tr>
                                </table>
                            </ItemTemplate>       
    </telerik:RadComboBox>

    <asp:Label ID="roRecipients" runat="server" text="No recipients selected" style="Position:absolute;left:130px;top:300px;width:300px;height:200px; background-color: #f2f5ff;overflow:auto;padding:5px">
    </asp:Label>

    <asp:Label ID="lblMessage" runat="server" style="Position:absolute;left:20px;top:290px;color:Red;font-weight:bold">
    </asp:Label>

    <asp:Label ID="roDevelopmentData" runat="server" style="Position:absolute;left:20px;top:520px">
    </asp:Label>
    </form>

    <telerik:RadScriptBlock ID="RadScriptBlock1" runat="server">
       <script type="text/javascript" language="javascript">
            function OnClientFileSelected(sender, args) {

                var zfile = document.getElementById('<% = uplCorrespondence.ClientID %>').file
                //alert(zfile);
                //document.getElementById('<% = butSave.ClientID %>').style.display = 'inline'

            }
     </script>
    </telerik:RadScriptBlock>
</body>
</html>
