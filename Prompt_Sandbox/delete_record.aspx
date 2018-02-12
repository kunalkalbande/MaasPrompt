<%@ Page Language="vb" %>

<%@ Import Namespace="System.IO" %>
<%@ Import Namespace="Prompt" %>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">

<script runat="server">

    Private RecordType As String = ""
    Private message As String = ""
    Private RecID As Integer

    Private Sub Page_Load(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MyBase.Load

        Session("PageID") = "DeleteRecord"

        RecordType = Request.QueryString("RecordType")
        RecID = Request.QueryString("ID")

        If Not IsPostBack Then
            CheckDependants()
        End If

    End Sub

    Private Sub CheckDependants()

        'checks for dependant records prior to deletion
        Dim cnt As Integer = 0
        Dim sql As String = ""
        Using rs As New PromptDataHelper

            Select Case RecordType

                Case "ContractDetail"
                    
                    sql = "SELECT LineID FROM ContractLineItems WHERE ContractChangeOrderID = " & RecID
                    Dim result As Integer = rs.ExecuteScalar(sql)

                    sql = "SELECT COUNT(TransactionID) as TOT FROM TransactionDetail WHERE ContractLineItemID = " & result
                    cnt = rs.ExecuteScalar(sql)

                    If cnt > 0 Then                 'display a popup warning and close edit page
                        message = "There are Transactions associtated with this ChangeOrder. Please ReAllocate all related Transactions before deleting this ChangeOrder. "
                        butDelete.Visible = False
                        butCancel.Text = " Ok  "
                    End If


                Case "Contractor"

                    sql = "SELECT COUNT(ContractID) as TOT FROM Contracts WHERE ContractorID = " & RecID
                    cnt = rs.ExecuteScalar(sql)
                    If cnt > 0 Then                 'display a popup warning and close edit page
                        message = "There are " & cnt & " Contracts associtated with this Contractor. Please Delete all associated records before deleting this contractor. <br><br> " & vbCrLf
                        butDelete.Visible = False
                        butCancel.Text = " Ok  "
                    End If

                    sql = "SELECT COUNT(TransactionID) as TOT FROM Transactions WHERE ContractorID = " & RecID
                    cnt = rs.ExecuteScalar(sql)
                    If cnt > 0 Then                 'display a popup warning and close edit page
                        message = message & "There are " & cnt & " Transactions associtated with this Contractor. Please Delete all associated records before deleting this contractor. "
                        butDelete.Visible = False
                        butCancel.Text = " Ok  "
                    End If

                    'Case "ProjectManager"

                    '    sql = "SELECT COUNT(ProjectID) as TOT FROM Projects WHERE PM = " & RecID
                    '    cnt = rs.ExecuteScalar(sql)
                    '    If cnt > 0 Then                 'display a popup warning and close edit page
                    '        message = "There are " & cnt & " Projects associtated with this Project Manager. Please un-associate all associated records before deleting this Project Manager. <br><br> " & vbCrLf
                    '        butDelete.Visible = False
                    '        butCancel.Text = " Ok  "
                    '    End If

                    '    sql = "SELECT COUNT(TransactionID) as TOT FROM Transactions WHERE ContractorID = " & RecID
                    '     cnt = rs.ExecuteScalar(sql)
                    '    If cnt > 0 Then                 'display a popup warning and close edit page
                    '        message = message & "There are " & cnt & " Transactions associtated with this Contractor. Please Delete all associated records before deleting this contractor. "
                    '        butDelete.Visible = False
                    '        butCancel.Text = " Ok  "
                    '    End If

                    'Case "Project"

                    '    sql = "SELECT COUNT(ContractID) as TOT FROM Contracts WHERE ProjectID = " & RecID
                    '    cnt = rs.ExecuteScalar(sql)

                    '    If cnt > 0 Then
                    '        message = "There are " & cnt & " Contracts associtated with this Project. Please Delete them before Deleting the Project. <br><br>"
                    '    End If

                    '    sql = "SELECT COUNT(NoteID) as TOT FROM Notes WHERE ProjectID = " & RecID
                    '     cnt = rs.ExecuteScalar(sql)

                    '    If cnt > 0 Then
                    '        message = message & "There are " & cnt & " Notes associtated with this Project. Please Delete them before Deleting the Project." & vbCrLf
                    '    End If

                    '    If message <> "" Then
                    '        butDelete.Visible = False
                    '        butCancel.Text = " Ok  "
                    '    End If

                    'Case "College"

                    '    sql = "SELECT COUNT(ProjectID) as TOT FROM Projects WHERE CollegeID = " & RecID
                    '   cnt = rs.ExecuteScalar(sql)
                    '    If cnt > 0 Then                 'display a popup warning and close edit page
                    '        message = "There are " & cnt & " Projects associtated with this College. Please Delete all associated records before deleting this College. "
                    '        butDelete.Visible = False
                    '        butCancel.Text = " Ok  "
                    '    End If

                    'Case "District"

                    '    sql = "SELECT COUNT(CollegeID) as TOT FROM Colleges WHERE DistrictID = " & RecID
                    '     cnt = rs.ExecuteScalar(sql)
                    '    If cnt > 0 Then                 'display a popup warning and close edit page
                    '        message = "There are " & cnt & " Colleges associtated with this District. Please Delete all associated records before deleting this District. "
                    '        butDelete.Visible = False
                    '        butCancel.Text = " Ok  "
                    '    End If

                    'Case "Client"

                    '    sql = "SELECT COUNT(ClientID) as TOT FROM Users WHERE ClientID = " & RecID
                    '     cnt = rs.ExecuteScalar(sql)

                    '    If cnt > 0 Then
                    '        message = "There are " & cnt & " Users associtated with this Client. Please Delete them before Deleting the Client. <br><br>"
                    '    End If

                    '    sql = "SELECT COUNT(DistrictID) as TOT FROM Districts WHERE ClientID = " & RecID
                    '   cnt = rs.ExecuteScalar(sql)
                    '    If cnt > 0 Then                 'display a popup warning and close edit page
                    '        message = "There are " & cnt & " Districts associtated with this Client. Please Delete all associated records before deleting this Client. "
                    '        butDelete.Visible = False
                    '        butCancel.Text = " Ok  "
                    '    End If


                    'Case "ApprisePhoto","ApprisePMPhoto"

                    '    Session("RtnFromEdit") = True
                    '    message = "Are you sure you want to delete this photo? "
                    '    butDelete.Text = "Delete Photo"

                Case Else
                    'do no checks

            End Select

        End Using

        If message = "" Then   'no dependants so go ahead and delete
            DeleteRecord()
        End If

        lblMessage.Text = message

    End Sub

    Private Sub DeleteRecord()

        Using rs As New PromptDataHelper
            rs.callingpage = Page
            Select Case RecordType

                Case "ApprisePhoto"

                    'Deletes a photo from apprise project
                    Dim strPhotoPath As String = ""
                    Dim strMainPhoto As String = ""
                    Dim strThumbPhoto As String = ""
                    Dim CollegeID As Integer = Request.QueryString("CollegeID")
                    Dim ProjectID As Integer = Request.QueryString("ProjectID")
                    strPhotoPath = ProcLib.GetCurrentAttachmentPath()
                    strPhotoPath = strPhotoPath & "DistrictID_" & Session("DistrictID") & "\CollegeID_" & CollegeID & "\ProjectID_" & ProjectID & "\_appphotos\"

                    If Request.QueryString("main") = "y" Then
                        strMainPhoto = strPhotoPath & "main.jpg"
                        strThumbPhoto = strPhotoPath & "main_thumb.jpg"
                    End If

                    'Delete photo if present
                    Dim file As New FileInfo(strMainPhoto)
                    If file.Exists Then
                        file.Delete()
                    End If
                    
                    'Delete thumb if present
                    Dim filethumb As New FileInfo(strThumbPhoto)
                    If filethumb.Exists Then
                        filethumb.Delete()
                    End If

                    Session("RtnFromEdit") = True
                    ProcLib.CloseAndRefresh(Page)

                
                    'Case "ApprisePMPhoto"

                    ''Deletes a photo from apprise project
                    'Dim strPhotoPath As String = ""
                    'Dim strMainPhoto As String = ""
                    'Dim strThumbPhoto As String = ""

                    'Dim ProjectID As Integer = Request.QueryString("ProjectID")
                    'strPhotoPath = ProcLib.GetCurrentAttachmentPath()
                    'strPhotoPath = strPhotoPath & "DistrictID_" & Session("DistrictID") & "\_apprisedocs\_photos\ProjectID_" & ProjectID & "\"

                    'If Request.QueryString("main") = "y" Then
                    '    strMainPhoto = strPhotoPath & "main.jpg"
                    '    strThumbPhoto = strPhotoPath & "main_thumb.jpg"
                    'End If

                    ''Delete photo if present
                    'Dim file As New FileInfo(strMainPhoto)
                    'If file.Exists Then
                    '    file.Delete()
                    'End If

                    ''Delete thumb if present
                    'Dim filethumb As New FileInfo(strThumbPhoto)
                    'If filethumb.Exists Then
                    '    filethumb.Delete()
                    'End If

                    'Session("RtnFromEdit") = True
                    'ProcLib.CloseAndRefreshRADNoPrompt(Page)
                
                
                Case "Attachment"

                    Dim strFile As String
                    rs.FillReader("SELECT FilePath,FileName FROM Attachments WHERE AttachmentID = " & RecID)
                    While rs.Reader.Read
                        strFile = ProcLib.GetCurrentAttachmentPath() & rs.Reader("FilePath") & rs.Reader("FileName")
                    End While
                    rs.Reader.Close()

                    'delete the record
                    rs.ExecuteNonQuery("DELETE FROM Attachments WHERE AttachmentID = " & RecID)

                    If File.Exists(strFile) Then
                        File.Delete(strFile)
                    End If
                    ProcLib.CloseAndRefresh(Page)

                Case "Contractor"


                    'delete the record
                    rs.ExecuteNonQuery("DELETE FROM Contractors WHERE ContractorID = " & RecID)
                    ProcLib.CloseAndRefresh(Page)

                    'Case "ProjectManager"


                    '    'delete the record
                    '    rs.ExecuteNonQuery("DELETE FROM ProjectManagers WHERE PMID = " & RecID)
                    '    ProcLib.CloseAndRefresh(Page)

                Case "ContractDetail"

                    'delete the record
                    rs.ExecuteNonQuery("DELETE FROM ContractDetail WHERE ContractDetailID = " & RecID)
                    
                    'delete the record
                    rs.ExecuteNonQuery("DELETE FROM ContractLineItems WHERE ContractChangeOrderID = " & RecID)

                    ''delete the record
                    'rs.ExecuteNonQuery("DELETE FROM ContractDetail WHERE GlobalContractDetailID = " & RecID)
                    ProcLib.CloseAndRefresh(Page)

                    'Case "Contract"

                    '    'Dim att As New promptAttachment
                    '    ''Get the parent Node for the deleted Contract and Parms for removal of Attachment Dir
                    '    'rs.FillDataTable("SELECT DistrictID,CollegeID,ProjectID FROM Contracts WHERE ContractID = " & RecID)

                    '    'With att                'Remove the Attachment Directory
                    '    '    .DistrictID = rs.DataTable.Rows(0).Item("DistrictID")
                    '    '    .CollegeID = rs.DataTable.Rows(0).Item("CollegeID")
                    '    '    .ProjectID = rs.DataTable.Rows(0).Item("ProjectID")
                    '    '    .ContractID = RecID
                    '    '    .DeleteAttachmentDir()
                    '    'End With



                    '    Session("nodeid") = "ContractGroup" & rs.DataTable.Rows(0).Item("ProjectID")
                    '    Session("RefreshNav") = True

                    '    'delete the record
                    '    rs.ExecuteNonQuery("DELETE FROM Contracts WHERE ContractID = " & RecID)
                    '    rs.Close()
                    '    ProcLib.CloseAndRefreshSpecific(Page, "window.opener.document.location.href='frame_default.aspx?view=Contract&ProjectID=" & att.ProjectID & "&CollegeID=" & att.CollegeID & "';")

                    '    ' NOTE:TESTALL ABOVE HERE FOR CLOSE
                
                
                Case "Project"

                    Using att As New promptAttachment
 
                        'Get the parent Node for the deleted Project and Parms for removal of Attachment Dir
                        rs.FillDataTable("SELECT DistrictID,CollegeID,ProjectID,GlobalProject FROM Projects WHERE ProjectID = " & RecID)
  
                        Session("nodeid") = "College" & rs.datatable.Rows(0).Item("CollegeID")
 
                        With att                'Remove the Attachment Directory
                            .DistrictID = rs.datatable.Rows(0).Item("DistrictID")
                            .CollegeID = rs.datatable.Rows(0).Item("CollegeID")
                            .ProjectID = rs.datatable.Rows(0).Item("ProjectID")
                            .DeleteAttachmentDir()
                        End With
                       
                        'delete the project master record
                        rs.ExecuteNonQuery("DELETE FROM Projects WHERE ProjectID = " & RecID)
                       
                        ''delete the prompt project data record
                        'rs.ExecuteNonQuery("DELETE FROM PromptProjectData WHERE ProjectID = " & RecID)
                        
                        'delete the prompt budget data 
                        rs.ExecuteNonQuery("DELETE FROM BudgetItems WHERE ProjectID = " & RecID)
                        
                        ''delete the apprise project data 
                        'rs.ExecuteNonQuery("DELETE FROM AppriseProjectData WHERE ProjectID = " & RecID)
                       
                        'delete the apprise photo data 
                        rs.ExecuteNonQuery("DELETE FROM ApprisePhotos WHERE ProjectID = " & RecID)
                        
                        'delete the attachment data 
                        rs.ExecuteNonQuery("DELETE FROM Attachments WHERE ProjectID = " & RecID)

                        Session("RefreshNav") = True
                        rs.Close()
                        proclib.CloseAndRefreshSpecific(Page, "window.opener.document.location.href='frame_default.aspx?view=Project&ProjectID=" & att.ProjectID & "&CollegeID=" & att.CollegeID & "';")
                    End Using

                        
                Case "College"

                    Using att As New promptAttachment
                        
                    
                        'Get the parent Node for the deleted College and Parms for removal of Attachment Dir
                        rs.FillDataTable("SELECT DistrictID,CollegeID FROM Colleges WHERE CollegeID = " & RecID)
                      
                        With att                'Remove the Attachment Directory
                            .DistrictID = rs.Datatable.Rows(0).Item("DistrictID")
                            .CollegeID = rs.Datatable.Rows(0).Item("CollegeID")
                            .DeleteAttachmentDir()
                        End With
                       
                        Session("RefreshNav") = True

                        'delete the College record
                        rs.executenonquery("DELETE FROM Colleges WHERE CollegeID = " & RecID)
  
                        'delete the attachment data 
                        rs.executenonquery("DELETE FROM Attachments WHERE CollegeID = " & RecID)

                    End Using
                    rs.Close()
                    ProcLib.CloseAndRefresh(Page)

                Case "District"

                    Dim att As New promptAttachment
                    With att                'Remove the Attachment Directory
                        .DistrictID = RecID
                        .DeleteAttachmentDir()
                    End With

                    Session("RefreshNav") = True

                    'delete the District record
                    rs.executenonquery("DELETE FROM Districts WHERE DistrictID = " & RecID)
 

                    ProcLib.CloseAndRefresh(Page)

                Case "Client"

                    Session("RefreshNav") = True

                    'delete the Client record
                    rs.executenonquery("DELETE FROM Clients WHERE ClientID = " & RecID)
  

                    ProcLib.CloseAndRefresh(Page)

                Case "Help"

                    'delete the help record
                    rs.executenonquery("DELETE FROM Help WHERE HelpID = " & RecID)
  

                    ProcLib.CloseAndRefresh(Page)
                Case "User"

                    'delete the User record
                    rs.executenonquery("DELETE FROM Users WHERE UserID = " & RecID)

                    ProcLib.CloseAndRefresh(Page)


                Case "Lookup"

                    'delete the User record
                    rs.executenonquery("DELETE FROM Lookups WHERE PrimaryKey = " & RecID)
 

                    ProcLib.CloseAndRefresh(Page)

                Case "Report"

                    'delete the User record
                    rs.executenonquery("DELETE FROM Reports WHERE ReportID = " & RecID)
  
                    ProcLib.CloseAndRefresh(Page)

            End Select
   
        End Using
        
        
        
    End Sub

    Private Sub butDelete_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles butDelete.Click
        DeleteRecord()
    End Sub

    Private Sub butCancel_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles butCancel.Click
        ProcLib.CloseAndRefresh(Page)
    End Sub


</script>

<html>
<head>
    <title>Delete Record</title>
    <meta name="GENERATOR" content="Microsoft Visual Studio .NET 7.1">
    <meta name="CODE_LANGUAGE" content="Visual Basic .NET 7.1">
    <meta name="vs_defaultClientScript" content="JavaScript">
    <meta name="vs_targetSchema" content="http://schemas.microsoft.com/intellisense/ie5">
    <link rel="stylesheet" type="text/css" href="http://localhost/Prompt/Styles.css">

        <script type="text/javascript" language="javascript">


       function GetRadWindow() {
           var oWindow = null;
           if (window.radWindow) oWindow = window.radWindow; //Will work in Moz in all cases, including clasic dialog
           else if (window.frameElement.radWindow) oWindow = window.frameElement.radWindow; //IE (and Moz az well)

           return oWindow;
       }

 	   
    </script>

</head>
<body>
    <form id="Form1" method="post" runat="server">
    <asp:Label ID="lblMessage" Style="z-index: 100; left: 16px; position: absolute; top: 16px"
        runat="server" Width="448px" Height="136px" CssClass="ViewDataDisplay">message</asp:Label>
    <asp:Button ID="butDelete" Style="z-index: 103; left: 16px; position: absolute; top: 168px"
        runat="server" Width="104px" Height="32px" Text="Delete Record"></asp:Button>
    <asp:Button ID="butCancel" Style="z-index: 102; left: 200px; position: absolute;
        top: 168px" runat="server" Width="104px" Height="32px" Text="Cancel"></asp:Button>
    </form>
</body>
</html>
