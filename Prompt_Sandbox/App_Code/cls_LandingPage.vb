Imports Microsoft.VisualBasic
Imports System
Imports System.Web
Imports System.Web.UI.WebControls
Imports System.IO
Imports System.Data
Imports System.Data.SqlClient
Imports Telerik.Web.UI
Imports System.Timers
Imports System.Net.Mail


Namespace Prompt

    Public Class LandingPage
        Implements IDisposable

        'Properties
        Public CallingPage As Page
        Public CallingUserControl As UserControl   'used for refernce to dynamic UC as cannot get through calling page
        Public Reader As SqlDataReader
        Public DataTable As DataTable
        Private db As PromptDataHelper
        Private Shared aTimer As System.Timers.Timer
        Public sql As String
        Public tbl As DataTable

        Public Sub New()
            db = New PromptDataHelper
        End Sub

#Region "District Landing Page"

        Public Function buildProjectLists(collegeID As Integer) As String
            Dim str As String = ""
            sql = "Select ProjectID, collegeID , status, ProjectName From Projects "
            sql &= " Where CollegeID = " & collegeID & " AND Status='1-Active' Order By ProjectName"

            Try
                tbl = db.ExecuteDataTable(sql)
            Catch ex As Exception
                'str = ex.ToString()
                str = "This is this"
                Return str
            End Try

            Dim div_1 As String = "<div><img src='images/clipboard.png' alt='clipboard' style='position:relative;top:4px;margin-right:5px'/>"
            div_1 &= " <a style='font-family:Segoe UI, Arial, sans-serif;font-size:13px;font-weight:bold;text-decoration:none' href='project_overview.aspx?view=project&ProjectID="

            Dim projName As String = ""

            If tbl.Rows.Count > 0 Then
                For Each row As DataRow In tbl.Rows
                    projName = row.Item("ProjectName")

                    If projName.Length() > 34 Then
                        projName = projName.Substring(0, 29) & " . . . ."
                    End If

                    str &= div_1 & row.Item("ProjectID") & "&collegeID=" & collegeID & "'>" & projName & "</a></div>"
                Next
            Else
                str = "No Active Projects"
            End If

            Return str
        End Function

        Public Function getCollegeBondAmount(collegeID As Integer) As Integer
            sql = "Select BondAmount From Colleges Where CollegeID = " & collegeID
            Dim num As Integer = db.ExecuteScalar(sql)
            Return num
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

