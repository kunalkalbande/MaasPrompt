Imports System
Imports System.Web
Imports System.Web.UI.WebControls
Imports System.IO
Imports System.Data
Imports System.Data.SqlClient
Imports Telerik.Web.UI

Namespace Prompt

    '********************************************
    '*  Admin BL Class
    '*  
    '*  Purpose: Processes misc Admin tasks
    '*
    '*  Last Mod By:    Ford James
    '*  Last Mod On:    03/12/10
    '*
    '********************************************

    Public Class promptAdmin
        Implements IDisposable

        'Properties
        Public CallingPage As Page
        Public CallingUserControl As UserControl   'used for refernce to dynamic UC as cannot get through calling page
        Public Reader As SqlDataReader
        Public DataTable As DataTable

        Public LastAnnouncementTimeStamp As String = ""

        Private db As PromptDataHelper

        Public Sub New()
            db = New PromptDataHelper

        End Sub

#Region "General"

        Public Function GetPromptAnnouncements() As String
            Dim sAnnoun As String = ""
            Dim tbl As DataTable = db.ExecuteDataTable("SELECT * FROM Announcements")
            For Each row As DataRow In tbl.Rows
                LastAnnouncementTimeStamp = row("LastUpdateOn")
                sAnnoun = row("Announcement")
            Next

            Return sAnnoun

        End Function

        Public Sub SavePromptAnnouncements()

            db.SaveForm(CallingPage.FindControl("Form1"), "SELECT * FROM Announcements")


        End Sub

        Public Function ShowLatestAnnouncement() As Boolean
            'Check to see if user has seen latest annoucement
            Dim dLatestAnnouncementTimestamp As String = ""
            Dim dLatestViewedAnnouncement As String = ""
            Dim tbl As DataTable = db.ExecuteDataTable("SELECT * FROM Announcements")
            For Each row As DataRow In tbl.Rows
                dLatestAnnouncementTimestamp = row("LastUpdateOn")
            Next
            dLatestViewedAnnouncement = db.ExecuteScalar("SELECT SettingValue FROM UsersPrefs WHERE SettingName='LastAnnouncementViewed' AND UserID=" & HttpContext.Current.Session("UserID"))
           
            If dLatestAnnouncementTimestamp <> dLatestViewedAnnouncement Then
                Return True
            Else
                Return False

            End If

        End Function

     


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
