<%@ Page Language="VB" %>

<%@ Register Assembly="Telerik.Web.UI" Namespace="Telerik.Web.UI" TagPrefix="telerik" %>
<%@ Import Namespace="System.IO" %>
<%@ Import Namespace="System.IO.FileSystemInfo" %>
<%@ Import Namespace="Prompt" %>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">

<script runat="server">
    Private sTitle As String = ""
    Private sEditType As String
    Private contID As Integer
    Private strPhysicalPath As String
    Private nScheduleID As Integer
    Private sSchType As String
    Private nProjectID As Integer
    
    Private Sub Page_Load(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MyBase.Load
        
        ProcLib.CheckSession(Page)
        ProcLib.LoadPopupJscript(Page)
        sTitle = "Schedules Upload/Edit Window"
        
        Session("PageID") = "SchedulesEdit"
        
        sEditType = Request.QueryString("displaytype")
        nScheduleID = Request.QueryString("ScheduleID")
        If Request.QueryString("SchType") = "Project" Then
            sSchType = Request.QueryString("SchType")
        End If
        
        'lblMessage.Text = sSchType
        nProjectID = Request.QueryString("ProjectID")
        
        Using db As New RFI
            Try
                contID = db.getContactID(Session("UserID"), Session("DistrictID"))
            Catch
            End Try
        End Using
        
        If IsPostBack Then
            'If uplScheduleName.InitialFileInputsCount > 0 Then
            'txtScheduleName.Text = "This is here dude"
            'End If
        End If
        
        If Not IsPostBack Then
            Using db As New RFI
                With cboProjectSelect
                    .DataValueField = "ProjectID"
                    .DataTextField = "ProjectName"
                    .DataSource = db.getUserProjects(contID)
                    .DataBind()
                End With
            End Using
            With cboActionSelect
                .DataValueField = "Action"
                .DataTextField = "ActionText"
                .DataSource = buildActionDropdown()
                .DataBind()
            End With
            
        End If

        If Not IsPostBack Then
            If sEditType = "New" Then
                configNew()
               
            ElseIf sEditType = "Edit" Then
                
                getData()
                configReadOnly()
            End If
        End If
        'lblMessage.Text = sSchType      
        'sTitle = createScheduleNumber()
        strPhysicalPath = ProcLib.GetCurrentAttachmentPath() & "DistrictID_" & HttpContext.Current.Session("DistrictID") & "/_apprisedocs/_schedules/"
        
        Using db As New Schedules
            Dim userName As String = db.getName(contID)
            roDevelopmentData.Text = userName & " " & contID & " - " & nScheduleID
        End Using
    End Sub
    
    Private Sub configNew()
       
        cboScheduleSelect.SelectedValue = Session("SchType")
        cboProjectSelect.Visible = False
        roProjectSelect.Visible = True
        If sSchType = "Project" Then
            Using db As New Schedules             
                roProjectSelect.Text = db.getProjectName(nProjectID)               
            End Using
            cboScheduleSelect.Visible = False
            roScheduleSelect.Visible = True
            roScheduleSelect.Text = "Project Specific/General Release"
            lblProjectGroup.Visible = True
            cboProjectGroup.Visible = True
            roProjectGroup.Visible = False
        Else
            roProjectSelect.Text = "Not Applicable"
            lblProjectGroup.Visible = False
            cboProjectGroup.Visible = False
        End If
       
        lblActionSelect.Visible = False
        cboActionSelect.Visible = False
        roFileName.Text = "Not Applicable"
                       
        saveButton.Value = "New"
        Dim alertText = "You are about to upload the selected file and save this schedule data.\n\nDo you want to continue?"
        butSave.OnClientClick = "return confirm('" & alertText & "')"
    End Sub
    
    Private Sub configEdit()
        uplScheduleName.Visible = False
        butSave.Visible = True
        If cboScheduleSelect.SelectedValue = "Project" Then
            cboProjectSelect.Visible = True
            roProjectSelect.Visible = False
        Else
            cboProjectSelect.Visible = False
            roProjectSelect.Visible = True
        End If            
        cboScheduleSelect.Visible = False
        roScheduleSelect.Visible = True
        txtScheduleName.Visible = True
        roScheduleName.Visible = False
    End Sub
    
    Private Sub configReadOnly()
        uplScheduleName.Visible = False
        butSave.Visible = False
        cboProjectSelect.Visible = False
        roProjectSelect.Visible = True
        If nProjectID = 0 Then
            roProjectSelect.Text = "Not Applicable"
        End If
        cboScheduleSelect.Visible = False
        roScheduleSelect.Visible = True
        txtScheduleName.Visible = False
        roScheduleName.Visible = True
        cboProjectGroup.Visible = False
        If roScheduleSelect.Text = "Project Specific/General Release" Then
            roProjectGroup.Visible = True
            lblProjectGroup.Visible = True
        Else
            roProjectGroup.Visible = False
            lblProjectGroup.Visible = False
        End If
             
    End Sub
    
    Private Sub getData()
        Dim tbl As DataTable
        Dim userName As String
        Using db As New Schedules
            tbl = db.getScheduleData(nScheduleID)
            userName = db.getName(contID)          
        End Using
        
        cboScheduleSelect.SelectedValue = Trim(tbl.Rows(0).Item("SchType"))           
        Session("SchType") = Trim(tbl.Rows(0).Item("SchType")) 'used for view persistance on parent page on exit
        sSchType = Session("SchType")
        
        If Session("SchType") = "Project" Then
            roScheduleSelect.Text = "Project Specific/General Release"
        Else
            roScheduleSelect.Text = cboScheduleSelect.SelectedItem.Text
        End If
        
        cboProjectSelect.SelectedValue = tbl.Rows(0).Item("ProjectID")
        roProjectGroup.Text = tbl.Rows(0).Item("ProjectGroup")
        
        Using db As New Schedules
            roProjectSelect.Text = db.getProjectName(tbl.Rows(0).Item("ProjectID"))
        End Using
       
        
        If tbl.Rows(0).Item("SchType") = "Project" Then
            cboProjectSelect.Visible = True
        Else
            cboProjectSelect.Visible = False
        End If
        
        txtScheduleName.Text = tbl.Rows(0).Item("ScheduleName")
        roScheduleName.Text = tbl.Rows(0).Item("ScheduleName")
        roFileName.Text = tbl.Rows(0).Item("ScheduleFileName")
        sTitle = tbl.Rows(0).Item("SchNumber")
        
    End Sub
    
    Private Function buildActionDropdown() As DataTable
        Dim tbl As DataTable
        tbl = New DataTable("tbl")
        
        tbl.Columns.Add("Action", GetType(System.String))
        tbl.Columns.Add("ActionText", GetType(System.String))
        tbl.Rows.Add("none", "Review")
        tbl.Rows.Add("Edit", "Edit Schedule")
        'tbl.Rows.Add("UpLoad", "Overwrite/Replace Current File")
        'tbl.Rows.Add("Deactivate", "Remove this schedule")
        Return tbl
    End Function
    
    Private Sub checkDirectory(dir As String)
        Dim folder As New DirectoryInfo(dir)
        If Not folder.Exists Then  'create the folder
            folder.Create()
        End If
    End Sub
    
    Private Sub cboProjectSelect_Change() Handles cboProjectSelect.SelectedIndexChanged
        Dim dir As String = strPhysicalPath & "Sch_" & cboProjectSelect.SelectedValue
        checkDirectory(dir)
    End Sub
    
    Private Sub cboScheduleSelect_change() Handles cboScheduleSelect.SelectedIndexChanged
        If cboScheduleSelect.SelectedValue = "Project" Then
            cboProjectSelect.Visible = True
            Dim dir As String = strPhysicalPath & "Sch_" & cboProjectSelect.SelectedValue
            checkDirectory(dir)
        Else
            cboProjectSelect.Visible = False
        End If
       
    End Sub
    
    Private Sub cboActionSelect_Change() Handles cboActionSelect.SelectedIndexChanged
        
        Select Case cboActionSelect.SelectedValue
            Case "none"
                configReadOnly()
            Case "Edit"
                configEdit()
                saveButton.Value = "Edit"
                butSave.ImageUrl = "images/button_save.png"
                Dim alertText = "You are about to update the data associated with this schedule.\n\nDo you want to continue?"
                butSave.OnClientClick = "return confirm('" & alertText & "')"
            Case "UpLoad"
                configReadOnly()
                butSave.Visible = True
                uplScheduleName.Visible = True
                saveButton.Value = "Upload"
                butSave.ImageUrl = "images/button_upload.png"
                Dim alertText = "You are about to upload this schedule which will overwrite the existing file.\n\nDo you want to continue?"
                butSave.OnClientClick = "return confirm('" & alertText & "')"
            Case "Deactivate"
                configReadOnly()
                saveButton.Value = "Deactivate"
                butSave.Visible = True
                uplScheduleName.Visible = False
                butSave.ImageUrl = "images/button_remove.png"
                Dim alertText = "You are about to remove this schedule. It will no longer be available to review.\n\nDo you want to continue?"
                butSave.OnClientClick = "return confirm('" & alertText & "')"
        End Select
               
    End Sub
    
    Private Sub chkOverwrite_Change() Handles chkOverwrite.CheckedChanged
        If chkOverwrite.Checked = True Then
            Dim alertText = "You are about to upload the selected file and save this schedule data.\n\n"
            alertText &= "You have selected to overwrite the file if it exists.\n\nDo you want to continue?"
            butSave.OnClientClick = "return confirm('" & alertText & "')"           
        Else
            Dim alertText = "You are about to upload the selected file and save this schedule data.\n\nDo you want to continue?"
            butSave.OnClientClick = "return confirm('" & alertText & "')"
        End If      
    End Sub
    
    Private Function checkFileExists() As String
        Dim fileName As String = ""
        Dim filePath As String = ""
        If Trim(cboScheduleSelect.SelectedValue) = "Project" Then
            filePath = strPhysicalPath & "/Sch_" & nProjectID & "/"
        Else
            filePath = strPhysicalPath & "/Global/"
        End If
        
        Dim isFile As String = "False"
        For Each File As Telerik.Web.UI.UploadedFile In uplScheduleName.UploadedFiles
            fileName = File.GetName
        Next
        Dim checkFile As String = Path.Combine(filePath, fileName)
        If System.IO.File.Exists(checkFile) Then
            isFile = "True"
        Else
            isFile = Nothing
        End If
        
        Return isFile
        
    End Function
    
    Private Function createScheduleNumber() As String
        Dim projectGroup As String
        Dim schNum As String = ""
        Dim schType As String = cboScheduleSelect.SelectedValue
        If sSchType = "Project" Then schType = "Project"
        Try
            Dim project As Integer = cboProjectSelect.SelectedValue
        Catch ex As Exception
            projectGroup = 0
        End Try
        Try
            projectGroup = cboProjectGroup.SelectedValue
        Catch ex As Exception
            projectGroup = "Master Program Schedule"
        End Try
        
        If sSchType <> "Project" Then projectGroup = ""
        Dim projectNumber As String
        Using db As New Schedules
            projectNumber = db.getProjectNumber(nProjectID)
        End Using
              
        Using db As New Schedules
            Dim tbl As DataTable = db.getScheduleTypes(schType, projectGroup, nProjectID, Session("DistrictID"))
            
            Dim count As Integer = tbl.Rows.Count
            If sSchType = "Project" Then
                
                schNum = "SCH-" & projectGroup & "-" & nProjectID & "-" & count + 1
            Else
                schNum = "SCH-" & schType & "-" & count + 1
            End If
        End Using
        Return schNum
    End Function
    
    Private Sub saveScheduleData(displayType As String)
        Dim objData(11) As Object
        Dim remFile As Boolean = False
        Dim isFile As String = checkFileExists()
        Dim fileName As String = ""
        Dim ProjectGroup As String = ""
        'If chkOverwrite.Checked <> True Then        
        If isFile = "True" Then
            lblMessage.Text = "The file you selected already exists! Select another file or change the file name."
            Exit Sub
        End If
        'ElseIf chkOverwrite.Checked = True Then
        'If isFile = "True" Then
        'rename and move the file first.
        'For Each File As Telerik.Web.UI.UploadedFile In uplScheduleName.UploadedFiles
        'fileName = File.GetName
        'Next
        'removeFile(fileName)
        'End If
        'End If
         
        Try
            Dim sfileName As String = ""
            If displayType = "New" Then
                sfileName = uploadFile()
                If sfileName = "" Then
                    lblMessage.Text = "You need to select a file to upload!!"
                    Exit Sub
                End If
            End If
            Dim SchType As String
            If sSchType = "Project" Then
                SchType = "Project"
                ProjectGroup = cboProjectGroup.SelectedValue
            Else
                SchType = cboScheduleSelect.SelectedValue
                ProjectGroup = ""
            End If
            
            objData(0) = SchType
            objData(1) = nProjectID 'cboProjectSelect.SelectedValue
            objData(2) = txtScheduleName.Text
            objData(3) = contID
            objData(4) = Now
            objData(5) = sfileName
            objData(6) = createScheduleNumber()
            objData(7) = displayType
            objData(8) = nScheduleID
            objData(9) = ProjectGroup
            objData(10) = Session("DistrictID")
            
            Using db As New Schedules
                Try
                    Dim tempID As Integer = db.saveScheduleData(objData)
                    'Dim tempID As Integer = 0
                    If displayType = "New" Then nScheduleID = tempID
                    Threading.Thread.Sleep(1000)
                    If displayType = "New" Then
                        Session("RtnFromEdit") = True
                        butCancel_click()
                    Else
                        Response.Redirect("schedule_edit.aspx?ProjectID=" & objData(1) & "&ScheduleID=" & nScheduleID & "&DisplayType=Edit")
                    End If
                    
                    Dim zStr As String = ""
                    'For i = 0 To 10
                    'zStr &= objData(i) & " - "
                    'Next
                    'lblMessage.Text = zStr
                Catch ex As Exception
                    lblMessage.Text = "Insideside - " & ex.ToString() & " - " & displayType
                    
                End Try                                         
            End Using
        
        Catch ex As Exception
            'lblMessage.Text = "There was a problem with the file upload. This task was not completed."
            lblMessage.Text = "Outside - " & ex.ToString() & " - " & Session("DistrictID")
            Exit Sub
        End Try
        'lblMessage.Text = sSchType
        
    End Sub
    
    Private Sub replaceFile()
        removeFile(roFileName.Text)
        Dim fileName As String = uploadFile()
        Using db As New Schedules
            db.updateFileName(fileName, nScheduleID)
        End Using
        Response.Redirect("schedule_edit.aspx?ProjectID=" & cboProjectSelect.SelectedValue & "&ScheduleID=" & nScheduleID & "&DisplayType=Edit")
    End Sub
    
    Private Sub removeFile(file As String)
        Dim targetPath As String
        Dim sourcePath As String
        If Trim(cboScheduleSelect.SelectedValue) = "Project" Then
            targetPath = strPhysicalPath & "\Sch_" & cboProjectSelect.SelectedValue & "\DeletedFiles"
            sourcePath = strPhysicalPath & "\Sch_" & cboProjectSelect.SelectedValue & "\"
        Else
            targetPath = strPhysicalPath & "\Global\DeletedFiles"
            sourcePath = strPhysicalPath & "\Global\"
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
    
    Private Sub deactivateSchedule()
        Using db As New Schedules
            db.deactivateSchedule(nScheduleID)            
        End Using
    End Sub
    
    Private Function uploadFile() As String
        Dim fileName As String = ""
        For Each File As Telerik.Web.UI.UploadedFile In uplScheduleName.UploadedFiles
           
            Dim filePath As String = ""
            If sSchType = "Project" Then
                filePath = strPhysicalPath & "/Sch_" & nProjectID & "/"
                checkDirectory(filePath)
            Else
                filePath = strPhysicalPath & "Global/"
                'checkDirectory(filePath)
            End If
            
            fileName = File.GetName
            Dim sSaveFile As String = Path.Combine(filePath, File.GetName)
            sSaveFile = sSaveFile.Replace("#", "")
            sSaveFile = sSaveFile.Replace(";", "")
            sSaveFile = sSaveFile.Replace(",", "")
            File.SaveAs(sSaveFile, True)    'overwrite if there
            'lblMessage.Text = filePath
        Next
        
        Return fileName
    End Function
    
    Private Sub butSave_Click() Handles butSave.Click
        Select Case saveButton.Value
            Case "Edit"
                saveScheduleData("Edit")
            Case "Upload"
                replaceFile()
            Case "New"
                saveScheduleData("New")
            Case "Deactivate"
                deactivateSchedule()
                butCancel_click()              
        End Select
    End Sub
    
    Private Sub butCancel_click() Handles butCancel.Click
        Session("RtnFromEdit") = True
        ProcLib.CloseAndRefreshRADNoPrompt(Page)
    End Sub
    
</script>

<html xmlns="http://www.w3.org/1999/xhtml">
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

       function ShowHelp()     //for help display
       {

           var oWnd = window.radopen("help_view.aspx?WinType=RAD", "ShowHelpWindow");
           return false;
       }

       function OnClientFileSelected(sender, args) {
            //alert('here'); 
          
       }

    </script>

    <title><%= sTitle %></title>
</head>
<body>
    <form id="Form1" method="post" runat="server">
    <telerik:radscriptmanager id="RadScriptManager1" runat="server" />

    <asp:HiddenField ID="saveButton" runat="server">
    </asp:HiddenField>

     <asp:Label ID="lblScheduleType" runat="server" Text="Schedule Type:" style="Position:absolute;left:15px;top:12px">
     </asp:Label>

     <telerik:RadComboBox ID="cboScheduleSelect" runat="server" Width="240px" Height="100px" Style="z-index: 200;left:100px;
        position:absolute;top:9px;" Skin="Vista"  TabIndex="7" AutoPostBack="true" Visible="true">
        <Items>
            <telerik:RadComboBoxItem runat="server" Text="Master Program Schedule" Value="MPS" />
            <telerik:RadComboBoxItem runat="server" Text="90 Day Look Ahead Schedule" Value="9DLAS" />    
            <telerik:RadComboBoxItem runat="server" Text="30 Day Look Ahead Schedule" Value="4DLAS" />    
            <telerik:RadComboBoxItem runat="server" Text="Planning/Programming Schedule" Value="PACS" />
           
        </Items>
    </telerik:RadComboBox>
     <!--<telerik:RadComboBoxItem runat="server" Text="Project Specific/General Release" Value="Project" />-->    
 <!--<telerik:RadComboBoxItem runat="server" Text="Future Bid Openings & Job Walks" Value="FBO&JW" />-->

    <asp:Label ID="roScheduleSelect" runat="server" style="Position:absolute;left:100px;top:12px;font-weight:bold">
    </asp:Label>

    <asp:Label ID="lblProjectName" runat="server" Text="Project Name:" style="Position:absolute;left:20px;top:42px">
    </asp:Label>

    <asp:Label ID="lblProjectGroup" runat="server" Text="Project Group:" style="Position:absolute;left:20px;top:72px">
    </asp:Label>

    <telerik:RadComboBox ID="cboProjectGroup" runat="server" Width="200px" Height="150px" Style="z-index: 190; left: 100px;
        position: absolute; top: 72px;" Skin="Vista"  TabIndex="7" AutoPostBack="true" Visible="true">
         <Items>
            <telerik:RadComboBoxItem runat="server" Text="A/E Schedule" Value="A/E Schedule" />
            <telerik:RadComboBoxItem runat="server" Text="MAAS Schedule" Value="MAAS Schedule" />  
            <telerik:RadComboBoxItem runat="server" Text="Campus Schedule" Value="Campus Schedule" />    
            <telerik:RadComboBoxItem runat="server" Text="CM Initial Schedule" Value="CM Initial Schedule" />    
            <telerik:RadComboBoxItem runat="server" Text="CM Construction Schedule" Value="CM Construction Schedule" />    
            <telerik:RadComboBoxItem runat="server" Text="CM Recovery Schedule" Value="CM Recovery Schedule" />             
        </Items>
    </telerik:RadComboBox>

            <!--<telerik:RadComboBoxItem runat="server" Text="Project" Value="Project" />
            <telerik:RadComboBoxItem runat="server" Text="Construction" Value="Construction" />-->    

    <asp:Label ID="roProjectGroup" runat="server" Text="" style="Position:absolute;left:100px;top:72px;font-weight:bold">
    </asp:Label>

    <telerik:RadComboBox ID="cboProjectSelect" runat="server" Width="300px" Height="100px" Style="z-index: 190; left: 100px;
        position: absolute; top: 42px;" Skin="Vista"  TabIndex="7" AutoPostBack="true" Visible="true">
    </telerik:RadComboBox>

    <asp:Label ID="roProjectSelect" runat="server" Text="Not Applicable" style="Position:absolute;left:100px;top:42px;font-weight:bold">
    </asp:Label>

    <asp:Label ID="lblScheduleName" runat="server" Text="Schedule Name:" style="Position:absolute;left:10px;top:103px">
    </asp:Label>

    <asp:TextBox ID="txtScheduleName" runat="server" Height="30px" Width="300px" TabIndex="1"
          style="Position:absolute;left:100px;top:105px;vertical-align:top" textmode="MultiLine" Visible="true"></asp:TextBox>

    <asp:Label ID="roScheduleName" runat="server" style="Position:absolute;left:100px;top:105px;font-weight:bold">
    </asp:Label>

    <asp:Label ID="lblFileName" runat="server" Text="Current File:" style="Position:absolute;left:30px;top:152px">
    </asp:Label>

    <asp:Label ID="roFileName" runat="server" style="Position:absolute;left:100px;top:152px;font-weight:bold">
    </asp:Label>

    <asp:Label ID="lblActionSelect" runat="server" Text="Action Select:" style="Position:absolute;left:20px;top:190px">
    </asp:Label>

    <telerik:RadComboBox ID="cboActionSelect" width="100" runat="server" Style="z-index: 180; left: 100px;
            position: absolute; top: 190px;" Skin="Vista"  TabIndex="7" AutoPostBack="true" Visible="True"
            Text="(Status)">              
     </telerik:RadComboBox>
    
    <asp:CheckBox ID="chkOverwrite" runat="server" autopostback="true" Visible="false" style="position:absolute;top:152px;left:100px"/>

    <asp:Label ID="lblOverwrite" runat="server" Text="Overwrite existing file?" Visible="false" style="Position:absolute;left:130px;top:152px;font-weight:bold">
    </asp:Label>

     <asp:ImageButton ID="butSave" runat="server" style="Position:absolute;left:250px;top:260px" visible="true"
            ImageUrl="images/button_save.png" />

     <asp:ImageButton ID="butCancel" runat="server" style="Position:absolute;left:340px;top:260px" visible="true"
            ImageUrl="images/button_cancel.png"/>

     <telerik:RadAsyncUpload ID="uplScheduleName" runat="server" Style="Position:absolute;z-index:100;left:20px;top:190px"
                MaxFileInputsCount=1 OnClientFileSelected="OnClientFileSelected"  ControlObjectsVisibility="None" Width="450px" />

    <asp:Label ID="lblMessage" runat="server" style="Position:absolute;left:20px;top:230px;color:Red;font-weight:bold">
    </asp:Label>

    <asp:Label ID="roDevelopmentData" runat="server" style="Position:absolute;left:20px;top:260px">
    </asp:Label>

    </form>

</body>
</html>
