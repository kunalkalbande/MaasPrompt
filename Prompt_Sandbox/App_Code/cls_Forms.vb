Imports System
Imports System.Web
Imports System.Web.UI.WebControls
Imports System.IO
Imports System.Data
Imports System.Data.SqlClient
Imports Telerik.Web.UI

Namespace Prompt

    Public Class promptForms
        Implements IDisposable

        Private db As PromptDataHelper
        Public Reader As SqlDataReader
        Public DataTable As DataTable
        Public sql As String

        Public Sub New()
            db = New PromptDataHelper
        End Sub

#Region "forms.aspx functions below"
        Public Function GetFormsList(ByVal ProjectID As Integer, collegeID As Integer, districtID As Integer) As DataTable
            Dim tbl As DataTable
            Dim bShowForm As Boolean = True
            Dim Sql As String
            If ProjectID = 0 Then
                Sql = "Select * From Forms Where CollegeID = " & collegeID & " AND DistrictID=" & districtID & " AND ProjectID = 0 and Status = 'Active' ORDER BY FormID DESC"
            Else
                Sql = "Select * From Forms Where ProjectID = " & ProjectID & " AND DistrictID=" & districtID & " and Status = 'Active' ORDER BY FormID DESC"
            End If

            'Return db.ExecuteDataTable("SELECT * FROM Forms WHERE ProjectID = " & ProjectID & " ORDER BY FormID DESC")
            tbl = db.ExecuteDataTable(Sql)
            Return tbl

        End Function

        Public Function getFormData(ProjectID As Integer, FormID As Integer) As DataTable
            Dim sql = "Select * From Forms "
            sql &= " Where ProjectID = " & ProjectID & " And FormID = " & FormID

            Dim mData As DataTable = db.ExecuteDataTable(sql)

            Return mData
        End Function

        Public Function getUserID(xLoginID As String) As Integer
            Dim sql As String = "Select UserID From Users Where LoginID = " & "'" & xLoginID & "'"
            Dim UserID As Integer = db.ExecuteScalar(sql)
            Return UserID
        End Function

        Public Function getUserNameByUserID(xUserID As Integer) As Object
            Dim sql As String = "Select * From Users Where UserID = " & xUserID
            Dim UserData As DataTable
            Dim SendData(3) As Object
            Try
                UserData = db.ExecuteDataTable(sql)
                SendData(0) = UserData.Rows(0).Item("UserID")
                SendData(1) = UserData.Rows(0).Item("UserName")
                SendData(2) = UserData.Rows(0).Item("LoginID")
            Catch
                SendData(0) = 0
                SendData(1) = ""
                SendData(2) = ""
            End Try

            Return SendData
        End Function


        Public Function getUserName(xLoginID As String) As String
            Dim sql As String = "Select UserName From Users Where LoginID = " & "'" & xLoginID & "'"
            Dim xUserName As String = db.ExecuteScalar(sql)
            Return xUserName
        End Function
#End Region

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

        Public Sub updateFormFileName(FormFileName As String, FormID As Integer)
            Dim sql As String = "Update Forms Set FormFileName = '" & FormFileName & "' Where FormID = " & FormID
            db.ExecuteNonQuery(sql)
        End Sub

        Public Function getFormTitle(FormID As Integer) As String
            Dim sql As String = "Select FormTitle From Forms Where FormID = " & FormID
            Return db.ExecuteScalar(sql)
        End Function

        Public Function getFormData(FormID As Integer) As DataTable
            Dim sql As String = "Select * From Forms Where FormID = " & FormID
            Dim tbl As DataTable = db.ExecuteDataTable(sql)

            Return tbl
        End Function

        Public Sub removeForm(FormID As Integer)
            Dim sql As String = "Update Forms Set Status='Disabled',DisableDate =" & Now & " Where FormID = " & FormID
            db.ExecuteNonQuery(sql)
        End Sub

        Public Function getAuthor(FormID As Integer) As Integer
            Dim sql As String = "Select DocumentOwner From Forms Where FormID = " & FormID
            Return db.ExecuteScalar(sql)
        End Function

        Public Function buildFormID(ProjectID As Integer, collegeID As Integer) As String
            Dim projNum As String

            If ProjectID = 0 Then
                sql = "Select max(FormID) from Forms Where CollegeID = " & collegeID & " AND ProjectID = 0 "
                projNum = collegeID
            Else
                sql = "Select max(FormID) from Forms Where ProjectID = " & ProjectID
                projNum = getProjectNumber(ProjectID)
            End If

            'Dim tbl As DataTable = db.ExecuteDataTable(sql)

            Dim count As Integer = 1

            Dim xFormID As String = db.ExecuteScalar(sql).ToString()

            If xFormID = "" Then
                xFormID = 0
            End If

            Dim rFormID As String = xFormID + count

            Return rFormID
        End Function

        Public Function buildFormNumber(ProjectID As Integer, collegeID As Integer, districtID As Integer) As String
            Dim projNum As String

            If ProjectID = 0 Then
                sql = "Select FormID from Forms Where CollegeID = " & collegeID & " AND ProjectID = 0 And DistrictID = " & districtID
                projNum = collegeID
            Else
                sql = "Select FormID from Forms Where ProjectID = " & ProjectID
                projNum = getProjectNumber(ProjectID)
            End If

            Dim tbl As DataTable = db.ExecuteDataTable(sql)

            Dim count As Integer = tbl.Rows.Count
            count = count + 1

            Dim FormNum As String = "Form-" & projNum & "-" & count

            Return FormNum
        End Function

        Public Function saveFormData(obj As Object) As String
            Dim sql As String = ""
            If obj(0) = "New" Then
                sql = "Insert Into Forms(FormNumber,ProjectID,DistrictID,FormDate,CreateDate,Description,LastUpdateBy,LastUpdateOn,FormFileName,DesignPhase,PhaseSubCategory,DocumentOwner,CollegeID,FormType,FormCategoryID,FormTitle,Status)"
                sql &= " values('" & obj(8) & "'," & obj(6) & "," & obj(5) & ",'" & obj(1) & "','" & Now & "','" & obj(2) & "','" & obj(4) & "','"
                sql &= Now & "','" & obj(7) & "','" & obj(3) & "','" & obj(11) & "'," & obj(12) & "," & obj(14) & ",'" & obj(15) & "','" & obj(16) & "','" & obj(17) & "','" & obj(13) & "')"

            ElseIf obj(0) = "Update" Then
                sql = "Update Forms Set Description = '" & obj(2) & "', DesignPhase = '" & obj(3) & "'"
                sql &= ", PhaseSubCategory = '" & obj(11) & "', Status = '" & obj(13) & "', FormType='" & obj(15) & "', FormTitle='" & obj(17) & "', FormCategoryID='" & obj(16) & "', LastUpdateBy='" & obj(4) & "', DisableDate='" & obj(18) & "', FormDate='" & obj(1) & "', LastUpdateOn='" & Now & "' Where FormID = " & obj(9)
            End If

            db.ExecuteNonQuery(sql)

            Return sql

        End Function

        Public Function getFormID(ProjectID As Integer, collegeID As Integer) As String
            Dim projNum As String

            If ProjectID = 0 Then
                sql = "Select max(FormID) from Forms Where CollegeID = " & collegeID & " AND ProjectID = 0 "
                projNum = collegeID
            Else
                sql = "Select max(FormID) from Forms Where ProjectID = " & ProjectID
                projNum = getProjectNumber(ProjectID)
            End If

            Dim xFormID As String = db.ExecuteScalar(sql)


            Return xFormID
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

