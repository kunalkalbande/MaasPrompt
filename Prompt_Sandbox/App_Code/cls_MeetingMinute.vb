Imports System
Imports System.Web
Imports System.Web.UI.WebControls
Imports System.IO
Imports System.Data
Imports System.Data.SqlClient
Imports Telerik.Web.UI

Namespace Prompt

    '********************************************
    '*  MeetingMinute Class
    '*  
    '*  Purpose: Processes data for the MeetingMinute Objects
    '*
    '*  Last Mod By:    Ford James
    '*  Last Mod On:    07/12/09
    '*
    '********************************************

    Public Class MeetingMinute
        Implements IDisposable

        'Properties
        Public CallingPage As Page
        Public CallingUserControl As UserControl   'used for refernce to dynamic UC as cannot get through calling page
        Public Reader As SqlDataReader
        Public DataTable As DataTable
        Public sql As String
        Public tbl As DataTable


        Private db As PromptDataHelper

        Public Sub New()
            db = New PromptDataHelper

        End Sub

#Region "Project Meeting Minutes"

        Public Function GetAllProjectMeetingMinutes(ByVal ProjectID As Integer, collegeID As Integer, districtID As Integer) As DataTable
            If ProjectID = 0 Then
                sql = "Select * From MeetingMinutes Where CollegeID = " & collegeID & " AND DistrictID=" & districtID & " AND ProjectID = 0 ORDER BY MeetingID DESC"
            Else
                sql = "Select * From MeetingMinutes Where ProjectID = " & ProjectID & " AND DistrictID=" & districtID & " ORDER BY MeetingID DESC"
            End If

            'Return db.ExecuteDataTable("SELECT * FROM MeetingMinutes WHERE ProjectID = " & ProjectID & " ORDER BY MeetingID DESC")
            tbl = db.ExecuteDataTable(sql)
            Return tbl

        End Function

        Public Function getMemberMeetings(ProjectID As Integer, ContactID As Integer, contactType As String) As DataTable
            Dim sql As String = "Select *  From MeetingMinutes x "

            If contactType = "General Contractor" Then
                sql &= "JOIN MeetingParticipants y ON y.MeetingID=x.MeetingID "
            End If

            sql &= " Where ProjectID = " & ProjectID

            If contactType = "General Contractor" Then
                sql &= " AND y.ContactID = " & ContactID
            End If

            sql &= "Order By x.MeetingID desc"

            Dim tbl As DataTable = db.ExecuteDataTable(sql)

            Return tbl
        End Function

        Public Function getMeetingData(ProjectID As Integer, MeetingID As Integer) As DataTable
            Dim sql = "Select * From MeetingMinutes "
            sql &= " Where ProjectID = " & ProjectID & " And MeetingID = " & MeetingID

            Dim mData As DataTable = db.ExecuteDataTable(sql)

            Return mData
        End Function

        Public Function buildMeetingComments(ProjectID As Integer, MeetingID As Integer) As String
            Dim sql As String = "Select * From MeetingComments where ProjectID = " & ProjectID & " AND MeetingID = " & MeetingID & " order by CommentSequence desc"
            Dim tbl As DataTable = db.ExecuteDataTable(sql)
            Dim outString As String = ""

            For Each row As DataRow In tbl.Rows
                Dim name As String
                Using nR As New RFI
                    name = nR.getSubmittedTo(row.Item("CommenterID"))
                End Using
                outString &= "Comment #: " & row.Item("CommentSequence") & vbCrLf
                outString &= "Comment By: " & name & vbCrLf & "Date: " & row.Item("CommentDate") & vbCrLf & vbCrLf
                outString &= row.Item("Comment") & vbCrLf & "--------------------------" & vbCrLf
            Next

            Return outString
        End Function

        Public Function buildMeetingNumber(ProjectID As Integer, collegeID As Integer) As String
            Dim projNum As String

            If ProjectID = 0 Then
                sql = "Select MeetingID from MeetingMinutes Where CollegeID = " & collegeID & " AND ProjectID = 0 "
                projNum = collegeID
            Else
                sql = "Select MeetingID from MeetingMinutes Where ProjectID = " & ProjectID
                projNum = getProjectNumber(ProjectID)
            End If

            Dim tbl As DataTable = db.ExecuteDataTable(sql)

            Dim count As Integer = tbl.Rows.Count
            count = count + 1

            Dim MeetingNum As String = "Meeting-" & projNum & "-" & count

            Return MeetingNum
        End Function

        Public Function getProjectNumber(ProjectID As Integer) As String
            Dim sql As String = "Select ProjectNumber From Projects Where ProjectID=" & ProjectID
            Dim projNum As String = db.ExecuteScalar(sql)

            Return projNum
        End Function

        Public Function getProjectName(ProjectID As Integer) As String
            Dim sql = "Select ProjectName from Projects where ProjectID = " & ProjectID
            Dim ProjName As String = db.ExecuteScalar(sql)

            Return ProjName
        End Function

        Public Function getCollegeName(CollegeID As Integer) As String
            sql = "Select College From Colleges Where CollegeID=" & CollegeID
            Dim collegeName As String = db.ExecuteScalar(sql)

            Return collegeName
        End Function

        Public Function getCommentSequence(ProjectID As Integer, MeetingID As Integer) As Integer
            Dim sql As String = "Select MeetingCommentID From MeetingComments Where ProjectID = " & ProjectID & " AND MeetingID = " & MeetingID
            Dim tbl As DataTable = db.ExecuteDataTable(sql)
            Dim seq As Integer = tbl.Rows.Count

            Return seq
        End Function

        Public Sub insertComment(insDat As Object)
            Dim sql As String = "Insert Into MeetingComments (ProjectID,MeetingID,Comment,CommentSequence,CommenterID,CommentDate)"
            sql &= " values(" & insDat(0) & "," & insDat(1) & ",'" & insDat(5) & "'," & insDat(3) & "," & insDat(4) & ",'" & insDat(2) & "')"

            db.ExecuteScalar(sql)
        End Sub

        Public Function saveMeeting(saveData As Object) As Integer
            Dim sql As String = ""
            Dim rec As Integer

            Select Case Trim(saveData(6))
                Case "Insert"
                    sql = "Insert Into MeetingMinutes (MeetingNumber,ProjectID,DistrictID,MeetingDate,Description,LastUpdateBy,LastUpdateOn,MinutesFileName,DesignPhase,PhaseSubCategory,CreatedBy,CollegeID)"
                    sql &= " values('" & saveData(7) & "'," & saveData(5) & "," & saveData(4) & ",'" & saveData(0) & "','" & saveData(1) & "','" & saveData(3) & "','"
                    sql &= Today & "','" & "None Selected" & "','" & saveData(2) & "','" & saveData(10) & "'," & saveData(11) & "," & saveData(13) & ")"
                    sql &= ";SELECT NewKey = Scope_Identity()"
                    rec = db.ExecuteScalar(sql)
                Case "Update"
                    sql = "Update MeetingMinutes Set MeetingDate = '" & saveData(0) & "', Description = '" & saveData(1) & "', DesignPhase = '" & saveData(2) & "'"
                    sql &= ", PhaseSubCategory = '" & saveData(10) & "', Status = '" & saveData(12) & "' Where MeetingID = " & saveData(8)
                    db.ExecuteScalar(sql)
                    rec = 0
                Case Else

            End Select

            Return rec

        End Function

        Public Sub updateListMinutes(MeetingID As Integer, fileName As String)
            Dim sql As String = "Update MeetingMinutes Set MinutesFileName = '" & fileName & "' Where MeetingID = " & MeetingID
            db.ExecuteNonQuery(sql)
        End Sub

        Public Sub GetMeetingMinuteEntryForEdit(ByVal MeetingID As Integer)

            db.FillForm(CallingPage.FindControl("Form1"), "SELECT * FROM MeetingMinutes WHERE MeetingID = " & MeetingID)

        End Sub

        Public Function getProjectList(nContactID As Integer) As DataTable
            Dim sql As String = "Select Projects.ProjectID as ProjectID, Projects.ProjectName as ProjectName from TeamMembers Join Projects ON Projects.ProjectID = TeamMembers.ProjectID"
            sql &= " Where TeamMembers.ContactID = " & nContactID & " Order By ProjectName"
            Dim tbl As DataTable = db.ExecuteDataTable(sql)
            Return tbl
        End Function

        Public Function checkParticipant(MeetingNumber As String, ContactID As Integer) As DataTable
            Dim sql As String = "Select * From MeetingParticipants Where MeetingID = '" & MeetingNumber & "' AND ContactID = " & ContactID
            Dim tbl As DataTable = db.ExecuteDataTable(sql)

            Return tbl
        End Function

        Public Sub maintainParticipants(data As Object)
            Dim sql As String = ""

            If data(3) = 1 Then
                sql = "Update MeetingParticipants Set IsLead = " & 0 & " Where MeetingID = " & data(1)
                db.ExecuteNonQuery(sql)
                sql = ""
                Dim obj As Object

                Using newdb As New RFI
                    obj = newdb.getContactData(data(0), HttpContext.Current.Session("DistrictID"))
                End Using

                sql = "Update MeetingMinutes set OrganizerName = '" & obj(2) & "' Where MeetingID = " & data(1)
                db.ExecuteNonQuery(sql)
            End If

            If data(2) = 0 And data(5) = 1 Then
                sql = "Update MeetingMinutes set OrganizerName = 'Not Selected' Where MeetingID = " & data(1)
                db.ExecuteNonQuery(sql)
            End If

            If data(4) = "Insert" Then
                sql = "Insert Into MeetingParticipants(MeetingID,ContactID,IsActive,IsLead,IsUpload)"
                sql &= " values('" & data(1) & "'," & data(0) & "," & data(2) & "," & data(3) & "," & data(5) & ")"
            ElseIf data(4) = "Update" Then
                sql = "Update MeetingParticipants Set IsActive = " & data(2) & ", IsUpload = " & data(5) & " Where MeetingID =" & data(1) & " AND ContactID = " & data(0)

            End If

            db.ExecuteNonQuery(sql)

        End Sub

        Public Function getDistrictContacts(nDistrictID As Integer) As DataTable
            sql = "Select con.ContactID, con.Name, conx.Name as Company From Contacts con "
            sql &= "JOIN Contacts conx ON conx.ContactID=con.ParentContactID "
            sql &= " Where con.DistrictID = " & nDistrictID & " AND con.ContactType <> 'Company' "

            tbl = db.ExecuteDataTable(sql)

            Return tbl
        End Function

        Public Function getMeetingParticipants(MeetingID As Integer, ContactID As Integer) As Object
            Dim stringOut As String = ""
            Dim organizer As String = "Organizer: Not Selected"
            Dim orgCo As String = ""
            Dim orgID As Integer
            Dim strTag As String = ""
            Dim isUpload As Boolean

            Dim sql As String = "Select *, x.Name as Company, x.ContactType as ContactType from MeetingParticipants Join Contacts ON Contacts.ContactID = MeetingParticipants.ContactID "
            sql &= " Join Contacts x ON x.ContactID=Contacts.ParentContactID "
            sql &= " Where MeetingID = " & MeetingID & " AND IsActive = 1"
            sql &= " Order By Contacts.LastName "

            Dim tbl As DataTable = db.ExecuteDataTable(sql)

            If tbl.Rows.Count > 0 Then
                For Each row As DataRow In tbl.Rows
                    If row.Item("IsUpload") = 1 Then strTag = " - <b>^</b> " Else strTag = ""
                    If row.Item("ContactID") = ContactID And row.Item("isUpload") = 1 Then isUpload = True
                    If row.Item("IsLead") = 0 Then
                        stringOut &= row.Item("Name") & " - " & row.Item("Company") & strTag & "<br/>"
                    Else
                        organizer = row.Item("Name") & " - " & row.Item("Company")
                        orgCo = row.Item("Company")
                        orgID = row.Item("ContactID")
                    End If
                Next
            Else
                stringOut = "No Participants Selected"
            End If

            Dim obj(6) As Object
            obj(0) = stringOut
            obj(1) = organizer
            obj(2) = orgCo
            obj(3) = orgID
            obj(4) = tbl
            obj(5) = isUpload

            Return obj
        End Function

        Public Function SaveMeetingMinuteEntry(ByVal ProjectID As Integer, ByVal MeetingID As Integer, ByVal MeetingDate As String, ByVal FileExtension As String) As String


            Dim sql As String = ""
            If MeetingID = 0 Then   'new record
                sql = "INSERT INTO MeetingMinutes (DistrictID, ProjectID) "
                sql &= "VALUES (" & HttpContext.Current.Session("DistrictID") & "," & ProjectID & ")"
                sql &= ";SELECT NewKey = Scope_Identity()"

                MeetingID = db.ExecuteScalar(sql)

            End If

            'Update record
            db.SaveForm(CallingPage.Form, "SELECT * FROM MeetingMinutes WHERE MeetingID = " & MeetingID)

            Dim savedfile As String = "Minutes-" & MeetingDate & " (" & ProjectID & "-" & MeetingID & ")" & FileExtension
            savedfile = savedfile.Replace("/", "-")

            If Not FileExtension = "NOFILE" Then
                sql = "UPDATE MeetingMinutes SET MinutesFileName = '" & savedfile & "' WHERE MeetingID = " & MeetingID   'the upload control is not accessible in SaveForm routine
                db.ExecuteNonQuery(sql)
            End If

            Return savedfile   'pass this back so we can name the actual file being saved

        End Function

        Public Sub DeleteMeetingMinuteEntry(ByVal ProjectID As Integer, ByVal MeetingID As Integer, ByVal Filename As String)

            If Filename <> "(None Attached)" Then
                Dim strPhysicalPath As String = ProcLib.GetCurrentAttachmentPath() & "DistrictID_" & HttpContext.Current.Session("DistrictID")
                strPhysicalPath &= "/_apprisedocs/_meetingminutes/ProjectID_" & ProjectID & "/" & Filename
                Dim fileinfo As New FileInfo(strPhysicalPath)
                If fileinfo.Exists Then
                    IO.File.Delete(strPhysicalPath)     'delete the file
                End If
            End If

            db.ExecuteNonQuery("DELETE FROM MeetingMinutes WHERE MeetingID = " & MeetingID)

        End Sub

        Public Sub DeleteMeetingMinuteAttachment(ByVal ProjectID As Integer, ByVal MeetingID As Integer, ByVal Filename As String)

            If Filename <> "(None Attached)" Then
                Dim strPhysicalPath As String = ProcLib.GetCurrentAttachmentPath() & "DistrictID_" & HttpContext.Current.Session("DistrictID")
                strPhysicalPath &= "/_apprisedocs/_meetingminutes/ProjectID_" & ProjectID & "/" & Filename
                Dim fileinfo As New FileInfo(strPhysicalPath)
                If fileinfo.Exists Then
                    IO.File.Delete(strPhysicalPath)     'delete the file
                End If
            End If

            db.ExecuteNonQuery("UPDATE MeetingMinutes SET MinutesFileName = '(None Attached)' WHERE MeetingID = " & MeetingID)

        End Sub


#End Region


#Region "IDisposable"

        Public Overridable Sub Dispose() Implements IDisposable.Dispose
            If Not db Is Nothing Then
                db.Dispose()
            End If
            If Not Reader Is Nothing Then
                Reader.Dispose()
            End If
            If Not DataTable Is Nothing Then
                DataTable.Dispose()
            End If
        End Sub

#End Region

    End Class

End Namespace
