Imports System
Imports System.Web
Imports System.Web.UI.WebControls
Imports System.IO
Imports System.Data
Imports System.Data.SqlClient
Imports Telerik.Web.UI


Namespace Prompt

    Public Class Schedules
        Implements IDisposable

        Private db As PromptDataHelper
        Public Reader As SqlDataReader
        Public DataTable As DataTable

        Public Sub New()
            db = New PromptDataHelper
        End Sub

        Public Function getScheduleTypes(SchType As String, group As String, projID As Integer, districtID As Integer) As DataTable
            Dim sql As String

            If SchType = "Project" Then
                sql = "Select * From PMSchedules Where schType='" & SchType & "' AND ProjectGroup='" & group & "' AND ProjectID=" & projID & " AND DistrictID=" & districtID
            Else
                sql = "Select * From PMSchedules Where schType='" & SchType & "' AND DistrictID=" & districtID
            End If

            sql &= " AND IsActive=1"

            Return db.ExecuteDataTable(sql)
        End Function

        Public Function getScheduleData(ScheduleID As Integer) As DataTable
            Dim sql As String = "Select * From PMSchedules where ScheduleID = " & ScheduleID & " AND IsActive=1"
            Return db.ExecuteDataTable(sql)
        End Function

        Public Function getProjectName(ProjectID As Integer) As String
            Dim sql As String = "Select ProjectName From Projects Where ProjectID=" & ProjectID
            Return db.ExecuteScalar(sql)
        End Function

        Public Function getProjectNumber(projectID As Integer) As String
            Dim sql As String = "Select ProjectNumber from Projects Where ProjectID=" & projectID

            Return db.ExecuteScalar(sql)
        End Function

        Public Function getName(ContactID As Integer) As String
            Dim sql As String = "Select Name From Contacts Where ContactID = " & ContactID
            Return db.ExecuteScalar(sql)
        End Function

        Public Sub updateFileName(fileName As String, schID As Integer)
            Dim sql As String = "Update PMSchedules Set ScheduleFileName = '" & fileName & "' Where ScheduleID=" & schID
            db.ExecuteNonQuery(sql)
        End Sub

        Public Sub deactivateSchedule(ScheduleID As Integer)
            Dim sql As String = "Update PMSchedules Set IsActive=0 where ScheduleID = " & ScheduleID
            db.ExecuteNonQuery(sql)

        End Sub

        Public Function buildGlobalScheduleGrid() As DataTable
            Dim tbl As DataTable
            tbl = New DataTable("tbl")

            tbl.Columns.Add("SchID", GetType(System.String))
            tbl.Columns.Add("ScheduleName", GetType(System.String))
            tbl.Rows.Add("MPS", "Master Program Schedule")
            tbl.Rows.Add("9DLAS", "90 Day Look Ahead Schedule")
            tbl.Rows.Add("4DLAS", "30 Day Look Ahead Schedule")
            tbl.Rows.Add("PACS", "Planning/Programming Schedule")
            'tbl.Rows.Add("FBO&JW", "Future Bid Openings & Job Walks")

            Return tbl
        End Function

        Public Function buildProjectScheduleGrid() As DataTable
            Dim tbl As DataTable
            tbl = New DataTable("tbl")

            tbl.Columns.Add("ProjectGroup", GetType(System.String))
            tbl.Columns.Add("ProjName", GetType(System.String))
            'tbl.Rows.Add("Projects", "Project")
            'tbl.Rows.Add("Construction", "Construction")
            tbl.Rows.Add("A/E Schedule", "A/E Schedule")
            tbl.Rows.Add("MAAS Schedule", "MAAS Schedule")
            tbl.Rows.Add("Campus Schedule", "Campus Schedule")
            tbl.Rows.Add("CM Initial Schedule", "CM Initial Schedule")
            tbl.Rows.Add("CM Construction Schedule", "CM Construction Schedule")
            tbl.Rows.Add("CM Recovery Schedule", "CM Recovery Schedule")

            Return tbl
        End Function

        Public Function getGlobalSchedules(schType As String, districtID As Integer) As DataTable
            Dim sql As String = "Select * From PMSchedules Where SchType = '" & schType & "' AND DistrictID=" & districtID & " AND IsActive=1"
            Dim tbl As DataTable = db.ExecuteDataTable(sql)

            Return tbl
        End Function

        Public Function getProjectSchedules(projectID As Integer, ProjGroup As String, districtID As Integer) As DataTable
            Dim sql As String = "Select * From PMSchedules Where ProjectID = " & projectID & " AND ProjectGroup = '" & Trim(ProjGroup) & "' AND DistrictID=" & districtID & " AND IsActive=1"
            Dim tbl As DataTable = db.ExecuteDataTable(sql)

            Return tbl
        End Function

        Public Function saveScheduleData(obj As Object) As String
            Dim sql As String = ""
            If obj(7) = "New" Then
                sql = "Insert Into PMSchedules(ProjectID,ScheduleName,IsActive,CreatedBy,CreateDate,SchNumber,ScheduleFileName,EffectiveDate,SchType,ProjectGroup,DistrictID)"
                sql &= " Values(" & obj(1) & ",'" & obj(2) & "'," & 1 & "," & obj(3) & ",'" & obj(4) & "','" & obj(6) & "','" & obj(5) & "','" & obj(4) & "','" & obj(0) & "','" & obj(9) & "'," & obj(10) & ")"
            ElseIf obj(7) = "Edit" Then
                'sql = "Update PMSchedules Set SchType='" & obj(0) & "', ProjectID = " & obj(1) & ", ScheduleName='" & obj(2) & "'"
                sql = "Update PMSchedules Set ScheduleName='" & obj(2) & "'"
                sql &= " Where ScheduleID = " & obj(8)
            End If

            db.ExecuteNonQuery(sql)
            Dim schID As Integer = 0
            If obj(7) = "New" Then
                sql = "Select ScheduleID From PMSchedules Where SchNumber='" & obj(6) & "'"
                schID = db.ExecuteScalar(sql)
            Else
                schID = 0
            End If
           
            Return schID
        End Function

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

