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

        Private db As PromptDataHelper

        Public Sub New()
            db = New PromptDataHelper

        End Sub

#Region "Project Meeting Minutes"

        Public Function GetAllProjectMeetingMinutes(ByVal ProjectID As Integer) As DataTable

            Return db.ExecuteDataTable("SELECT * FROM MeetingMinutes WHERE ProjectID = " & ProjectID & " ORDER BY MeetingDate DESC")

        End Function



        Public Sub GetMeetingMinuteEntryForEdit(ByVal MeetingID As Integer)

            db.FillForm(CallingPage.FindControl("Form1"), "SELECT * FROM MeetingMinutes WHERE MeetingID = " & MeetingID)

        End Sub

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

            If FileName <> "(None Attached)" Then
                Dim strPhysicalPath As String = ProcLib.GetCurrentAttachmentPath() & "DistrictID_" & httpcontext.current.Session("DistrictID")
                strPhysicalPath &= "/_apprisedocs/_meetingminutes/ProjectID_" & ProjectID & "/" & FileName
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
