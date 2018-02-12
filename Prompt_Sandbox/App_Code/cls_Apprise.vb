Imports System
Imports System.Web
Imports System.Web.UI.WebControls
Imports System.IO
Imports System.Data
Imports System.Data.SqlClient
Imports Telerik.Web.UI

Namespace Prompt

    '********************************************
    '*  Apprise BL Class
    '*  
    '*  Purpose: Processes data for the Apprise Objects
    '*
    '*  Last Mod By:    Ford James
    '*  Last Mod On:    07/12/09
    '*
    '********************************************

    Public Class AppriseBL
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

#Region "General"

        Public Function GetDistrictName(ByVal DistrictID) As String

            Return db.executescalar("SELECT Name FROM Districts WHERE DistrictID = " & DistrictID)

        End Function


#End Region


#Region "Projects"

        Public Function GetAllProjects(ByVal Filter As String) As DataTable
            Dim sql As String = "SELECT * FROM qry_Apprise_GetAllProjects WHERE DistrictID = " & httpcontext.current.Session("DistrictID") & " "
            Select Case filter
                Case "Active", "Complete", "Suspended", "Cancelled", "Proposed"
                    sql &= "AND AppriseStatus = '" & filter & "' "

                Case "MyProjects"

                    sql &= "AND ProjectManager = '" & httpcontext.current.Session("UserName") & "' "
                Case Else         'All Projects

            End Select

            sql &= " ORDER BY ProjectTitle "

            Return db.ExecuteDataTable(sql)

        End Function


        Public Function GetAllPublishedProjects() As DataTable

            Return db.ExecuteDataTable("SELECT * FROM qry_Apprise_GetAllProjects WHERE DistrictID = " & httpcontext.current.Session("DistrictID") & " AND PublishToWeb = 1 ORDER BY ProjectTitle ")

        End Function


        Public Function GetProject(ByVal ProjectID) As DataTable
            'FOR PROMPT Project

            Return db.ExecuteDataTable("SELECT * FROM Projects WHERE ProjectID = " & ProjectID)

        End Function

        'Public Sub GetProjectForEdit(ByVal ProjectID As Integer)

        '    db.FillNewRADComboBox("SELECT CollegeID as Val, College as Lbl FROM Colleges WHERE DistrictID = " & HttpContext.Current.Session("DistrictID"), CallingPage.FindControl("cboCollegeID"), False)
        '    db.FillNewRADComboBox("SELECT PMID as Val, Name as Lbl FROM ProjectManagers WHERE DistrictID = " & HttpContext.Current.Session("DistrictID"), CallingPage.FindControl("cboProjectManagerID"), True)


        '    If ProjectID > 0 Then
        '        db.FillForm(CallingPage.FindControl("Form1"), "SELECT * FROM Projects WHERE ProjectID = " & ProjectID)

        '    End If


        'End Sub

        Public Sub GetAppriseProjectInfo(ByVal ctrl As control, ByVal ProjectID As Integer)

            db.FillForm(ctrl, "SELECT * FROM qry_Apprise_GetProjectInfo WHERE ProjectID = " & ProjectID)

        End Sub

        Public Function SaveProject(ByVal ProjectID As Integer) As Integer


            Dim sql As String = ""
            If ProjectID = 0 Then   'new record - 
                sql = "INSERT INTO Projects (DistrictID, CollegeID) "
                sql &= "VALUES (" & HttpContext.Current.Session("DistrictID") & "," & HttpContext.Current.Session("CollegeID") & ")"
                sql &= ";SELECT NewKey = Scope_Identity()"

                ProjectID = db.ExecuteScalar(sql)

            End If

            'Update record
            db.SaveForm(CallingPage.Form, "SELECT * FROM Projects WHERE ProjectID = " & ProjectID)

            Return ProjectID

        End Function

        Public Function DeleteProject(ByVal ProjectID As Integer) As String

            Dim msg As String = ""
            Dim sql As String = "SELECT IsPromptProject FROM Projects WHERE ProjectID =" & ProjectID
            Dim result As Integer = db.ExecuteScalar(sql)
            If result = 0 Then    'this project is not a Prompt Project

                'need to check for existing attributes before deleting

                'Dim strPhysicalPath As String = ProcLib.GetCurrentAttachmentPath() & "DistrictID_" & httpcontext.current.Session("DistrictID")
                'strPhysicalPath &= "/_apprisedocs/_Submittals/SubmittalID_" & SubmittalID & "/"
                'Dim fileinfo As New FileInfo(strPhysicalPath)
                'If fileinfo.Exists Then
                '    IO.File.Delete(strPhysicalPath)     'delete the file
                'End If

                db.ExecuteNonQuery("DELETE FROM Projects WHERE ProjectID = " & ProjectID)
            Else
                msg = "You cannot delete this project as it is currently being tracked in PROMPT"
            End If

            Return msg



        End Function

 



#End Region

#Region "Attachments"


        'Public Function GetAttachments(ByVal ParentID As Integer, ByVal ParentType As String) As DataTable

        '    Dim sPhysicalPath As String = ProcLib.GetCurrentAttachmentPath() & "DistrictID_" & httpcontext.current.Session("DistrictID") & "/_apprisedocs/"
        '    Dim sRelativePath As String = ProcLib.GetCurrentRelativeAttachmentPath() & "DistrictID_" & httpcontext.current.Session("DistrictID") & "/_apprisedocs/"
        '    Select Case ParentType
        '        Case "RFIQuestion"
        '            sPhysicalPath &= "_RFIs/RFIID_" & ParentID & "/"
        '            sRelativePath &= "_RFIs/RFIID_" & ParentID & "/"

        '        Case "RFIAnswer"
        '            sPhysicalPath &= "_RFIs/RFIID_" & ParentID & "/_answers/"
        '            sRelativePath &= "_RFIs/RFIID_" & ParentID & "/_answers/"

        '        Case "Submittal"
        '            sPhysicalPath &= "_Submittals/SubmittalID_" & ParentID & "/"
        '            sRelativePath &= "_Submittals/SubmittalID_" & ParentID & "/"

        '        Case "InfoBulletin"
        '            sPhysicalPath &= "_InfoBulletins/InfoBulletinID_" & ParentID & "/"
        '            sRelativePath &= "_InfoBulletins/InfoBulletinID_" & ParentID & "/"

        '        Case "Procurement"
        '            sPhysicalPath &= "_ProcurementLogs/ProcurementID_" & ParentID & "/"
        '            sRelativePath &= "_ProcurementLogs/ProcurementID_" & ParentID & "/"

        '        Case "Transmittal"
        '            sPhysicalPath &= "_Transmittals/TransmittalID_" & ParentID & "/"
        '            sRelativePath &= "_Transmittals/TransmittalID_" & ParentID & "/"

        '        Case "ProgressReport"
        '            sPhysicalPath &= "_ProgressReports/ProgressReportID_" & ParentID & "/"
        '            sRelativePath &= "_ProgressReports/ProgressReportID_" & ParentID & "/"

        '    End Select

        '    Dim tbl As New datatable

        '    Dim col As New DataColumn
        '    col.DataType = Type.GetType("System.String")
        '    col.ColumnName = "FileName"
        '    tbl.Columns.Add(col)

        '    col = New DataColumn
        '    col.DataType = Type.GetType("System.String")
        '    col.ColumnName = "FileSize"
        '    tbl.Columns.Add(col)

        '    col = New DataColumn
        '    col.DataType = Type.GetType("System.String")
        '    col.ColumnName = "FileIcon"
        '    tbl.Columns.Add(col)

        '    col = New DataColumn
        '    col.DataType = Type.GetType("System.String")
        '    col.ColumnName = "LinkURL"
        '    tbl.Columns.Add(col)

        '    Dim folder As New DirectoryInfo(sPhysicalPath)
        '    If folder.Exists Then  'Look for files

        '        For Each fi As FileInfo In folder.GetFiles()
        '            Dim newrow As datarow = tbl.newrow
        '            newrow("FileName") = fi.name

        '            Dim FileSize As String = FormatNumber(fi.Length, 0, ) & " bytes"
        '            If fi.Length > 1000 Then
        '                FileSize = FormatNumber(fi.Length / 1000, 1) & "Kb"
        '            End If
        '            If fi.Length > 1000000 Then
        '                FileSize = FormatNumber(fi.Length / 1000000, 1) & "Mb"
        '            End If

        '            newrow("FileSize") = FileSize

        '            'Select image depending on file type
        '            If InStr(fi.name, ".xls") > 0 Then
        '                newrow("FileIcon") = "images/prompt_xls.gif"
        '            ElseIf InStr(fi.name, ".pdf") > 0 Then
        '                newrow("FileIcon") = "images/prompt_pdf.gif"
        '            ElseIf InStr(fi.name, ".doc") > 0 Then
        '                newrow("FileIcon") = "images/prompt_doc.gif"
        '            ElseIf InStr(fi.name, ".docx") > 0 Then
        '                newrow("FileIcon") = "images/prompt_doc.gif"
        '            ElseIf InStr(fi.name, ".zip") > 0 Then
        '                newrow("FileIcon") = "images/prompt_zip.gif"
        '            Else
        '                newrow("FileIcon") = "prompt_page.gif"
        '            End If

        '            newrow("LinkURL") = sRelativePath & fi.name

        '            tbl.rows.add(newrow)
        '        Next

        '    End If

        '    Return tbl

        'End Function
  
        'Public Sub DeleteAttachment(ByVal ParentID As Integer, ByVal ParentType As String, ByVal FileName As String)

        '    Dim sPhysicalPath As String = ProcLib.GetCurrentAttachmentPath() & "DistrictID_" & httpcontext.current.Session("DistrictID") & "/_apprisedocs/"
        '    Select Case ParentType
        '        Case "RFIQuestion"
        '            sPhysicalPath &= "_RFIs/RFIID_" & ParentID & "/" & FileName

        '        Case "RFIAnswer"
        '            sPhysicalPath &= "_RFIs/RFIID_" & ParentID & "/_answers/" & FileName

        '        Case "Submittal"
        '            sPhysicalPath &= "_Submittals/SubmittalID_" & ParentID & "/" & FileName

        '        Case "InfoBulletin"
        '            sPhysicalPath &= "_InfoBulletins/InfoBulletinID_" & ParentID & "/" & FileName

        '        Case "Procurement"
        '            sPhysicalPath &= "_ProcurementLogs/ProcurementID_" & ParentID & "/" & FileName

        '        Case "Transmittal"
        '            sPhysicalPath &= "_Transmittals/TransmittalID_" & ParentID & "/" & FileName

        '        Case "ProgressReport"
        '            sPhysicalPath &= "_ProgressReports/ProgressReportID_" & ParentID & "/" & FileName

        '    End Select

        '    'Remove file
        '    Dim objFileInfo As FileInfo
        '    objFileInfo = New FileInfo(sPhysicalPath)
        '    objFileInfo.Delete()

        'End Sub


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
