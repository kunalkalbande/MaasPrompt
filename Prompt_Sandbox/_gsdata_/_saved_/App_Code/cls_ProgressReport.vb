Imports System
Imports System.Web
Imports System.Web.UI.WebControls
Imports System.IO
Imports System.Data
Imports System.Data.SqlClient
Imports Telerik.Web.UI

Namespace Prompt

    '********************************************
    '*  ProgressReport Class
    '*  
    '*  Purpose: Processes data for the ProgressReport Objects
    '*
    '*  Last Mod By:    Ford James
    '*  Last Mod On:    04/1/10
    '*
    '********************************************

    Public Class ProgressReport
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

#Region "ProgressReport"

        Public Function GetAllProgressReports(ByVal ProjectID As Integer) As DataTable

            Dim sql As String = "SELECT ProjectProgressReports.*, ProjectManagers.Name AS SubmittedBy "
            sql &= "FROM dbo.ProjectProgressReports LEFT OUTER JOIN "
            sql &= "dbo.ProjectManagers ON dbo.ProjectProgressReports.SubmittedByPMID = ProjectManagers.PMID "
            sql &= "WHERE ProjectProgressReports.ProjectID = " & ProjectID

            Dim tbl As DataTable = db.ExecuteDataTable(sql)

            ''Now look for attachments for each Progress Report and if present then up the count
            'Dim strPhysicalPath As String = ProcLib.GetCurrentAttachmentPath() & "DistrictID_" & HttpContext.Current.Session("DistrictID")
            'strPhysicalPath &= "/_apprisedocs/_ProgressReports/"

            'Dim strRelativePath As String = ProcLib.GetCurrentRelativeAttachmentPath() & "DistrictID_" & HttpContext.Current.Session("DistrictID")
            'strRelativePath &= "/_apprisedocs/_ProgressReports/"

            ''Add an attachments column to the result table
            'Dim col As New DataColumn
            'col.DataType = Type.GetType("System.String")
            'col.ColumnName = "Attachments"
            'tbl.Columns.Add(col)

            'For Each row As DataRow In tbl.Rows
            '    Dim ifilecount As Integer = 0
            '    Dim sPath As String = strPhysicalPath & "ProgressReportID_" & row("ProgressReportID") & "/"
            '    Dim sRelPath As String = strRelativePath & "ProgressReportID_" & row("ProgressReportID") & "/"
            '    Dim folder As New DirectoryInfo(sPath)
            '    If Not folder.Exists Then  'There are not any files
            '        row("Attachments") = "N"
            '    Else                'there could be files so get all and list
            '        For Each fi As FileInfo In folder.GetFiles()
            '            ifilecount += 1
            '        Next
            '        If ifilecount > 0 Then
            '            row("Attachments") = "Y"
            '        Else
            '            row("Attachments") = "N"
            '        End If
            '    End If
            'Next

            Return tbl

        End Function



        Public Sub GetProgressReportForEdit(ByVal ProjectID As Integer, ByVal ProgressReportID As Integer)

            db.FillNewRADComboBox("SELECT PMID as Val, Name as Lbl FROM ProjectManagers WHERE DistrictID = " & HttpContext.Current.Session("DistrictID"), CallingPage.FindControl("lstSubmittedByPMID"), True, True, False)

            If ProgressReportID > 0 Then
                db.FillForm(CallingPage.FindControl("Form1"), "SELECT * FROM ProjectProgressReports WHERE ProgressReportID = " & ProgressReportID)

            End If


        End Sub

        Public Function SaveProgressReport(ByVal ProjectID As Integer, ByVal ProgressReportID As Integer, ByVal ReportDate As String, ByVal FileExtension As String) As String


            Dim sql As String = ""
            If ProgressReportID = 0 Then   'new record
                sql = "INSERT INTO ProjectProgressReports (DistrictID, ProjectID) "
                sql &= "VALUES (" & HttpContext.Current.Session("DistrictID") & "," & ProjectID & ")"
                sql &= ";SELECT NewKey = Scope_Identity()"

                ProgressReportID = db.ExecuteScalar(sql)

            End If

            'Update record
            db.SaveForm(CallingPage.Form, "SELECT * FROM ProjectProgressReports WHERE ProgressReportID = " & ProgressReportID)

            Dim savedfile As String = "ProgressReport-" & ReportDate & " (" & ProjectID & "-" & ProgressReportID & ")" & FileExtension
            savedfile = savedfile.Replace("/", "-")

            If Not FileExtension = "NOFILE" Then
                sql = "UPDATE ProjectProgressReports SET ReportFileName = '" & savedfile & "' WHERE ProgressReportID = " & ProgressReportID   'the upload control is not accessible in SaveForm routine
                db.ExecuteNonQuery(sql)
            End If

            Return savedfile   'pass this back so we can name the actual file being saved

        End Function

        Public Sub DeleteProgressReport(ByVal ProjectID As Integer, ByVal ProgressReportID As Integer, ByVal Filename As String)


            If Filename <> "(None Attached)" Then
                Dim strPhysicalPath As String = ProcLib.GetCurrentAttachmentPath() & "DistrictID_" & HttpContext.Current.Session("DistrictID")
                strPhysicalPath &= "/_apprisedocs/_progressreports/ProjectID_" & ProjectID & "/" & Filename
                Dim fileinfo As New FileInfo(strPhysicalPath)
                If fileinfo.Exists Then
                    IO.File.Delete(strPhysicalPath)     'delete the file
                End If
            End If

            db.ExecuteNonQuery("DELETE FROM ProjectProgressReports WHERE ProgressReportID = " & ProgressReportID)

        End Sub

        Public Sub DeleteAttachment(ByVal ProjectID As Integer, ByVal ProgressReportID As Integer, ByVal Filename As String)

            If Filename <> "(None Attached)" Then
                Dim strPhysicalPath As String = ProcLib.GetCurrentAttachmentPath() & "DistrictID_" & HttpContext.Current.Session("DistrictID")
                strPhysicalPath &= "/_apprisedocs/_progressreports/ProjectID_" & ProjectID & "/" & Filename
                Dim fileinfo As New FileInfo(strPhysicalPath)
                If fileinfo.Exists Then
                    IO.File.Delete(strPhysicalPath)     'delete the file
                End If
            End If

            db.ExecuteNonQuery("UPDATE ProjectProgressReports SET ReportFileName = '(None Attached)' WHERE ProgressReportID = " & ProgressReportID)

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
