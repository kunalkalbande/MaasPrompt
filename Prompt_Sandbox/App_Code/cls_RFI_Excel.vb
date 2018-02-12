Imports Microsoft.VisualBasic
Imports System
Imports System.Web
Imports System.Web.UI.WebControls
Imports System.IO
Imports System.Data
Imports System.Data.SqlClient
Imports Microsoft.Office.Interop
Imports Microsoft.Office.Interop.Excel



Namespace Prompt




    Public Class RFIExcel
        Implements IDisposable
        Private db As PromptDataHelper
        Public Reader As SqlDataReader
        Public DataTable As System.Data.DataTable

#Region "Excel Builder Function"


        Public Sub BuildExcel(ByVal RFIID As Integer)
            Dim isTo = True
            Dim RFIdata As System.Data.DataRow = GetRFIdata(RFIID)
            Dim contTo As System.Data.DataRow = Nothing
            Dim projName As String = getProjectName(RFIdata("ProjectID"))


            If RFIdata("SubmittedToID") = 0 Then
                isTo = False
            Else
                contTo = getContractorTo(RFIdata("SubmittedToID"))
            End If



            Dim xlApp As Microsoft.Office.Interop.Excel.Application
            Dim xlWorkbook As Microsoft.Office.Interop.Excel.Workbook
            Dim xlWorksheet As Microsoft.Office.Interop.Excel.Worksheet

            xlApp = New Microsoft.Office.Interop.Excel.Application
            xlApp.Visible = True

            xlWorkbook = xlApp.Workbooks.Open("C:/Websites/Prompt-Scott_2014/docs/RFI_Template.xls")
            xlWorksheet = xlWorkbook.ActiveSheet

            xlWorksheet.Cells(4, 1).value = "RFI Number: " & RFIID
            xlWorksheet.Cells(5, 1).value = "Date of RFI: " & Date.Today

            xlWorksheet.Cells(7, 1).value = "College of the Desert"
            xlWorksheet.Cells(8, 1).value = projName
            xlWorksheet.Cells(9, 1).value = "Project Number: " & (RFIdata("ProjectID")).ToString

            xlWorksheet.Cells(11, 1).value = "TO:"
            If isTo = False Then
                xlWorksheet.Cells(12, 1).value = "No one selected"
            Else
                xlWorksheet.Cells(12, 1).value = contTo("Name")
                xlWorksheet.Cells(13, 1).value = contTo("Address1")
                xlWorksheet.Cells(14, 1).value = contTo("City") & ", " & contTo("State") & " " & contTo("zip")
            End If

            xlWorksheet.Cells(17, 1).value = RFIdata("Question")

            xlApp.Visible = True

            xlApp.UserControl = True

            xlWorksheet = Nothing
            xlWorkbook = Nothing
            xlApp = Nothing

        End Sub

        Public Function GetRFIdata(ByVal RFIID As Integer) As System.Data.DataRow

            Dim sql As String = "Select * From RFIs Where RFIID = " & RFIID
            Dim zRFI As System.Data.DataRow
            Using db As New PromptDataHelper
                zRFI = db.GetDataRow(sql)
            End Using

            Return zRFI

        End Function
        Public Function getContractorTo(ByVal ContID As Integer) As System.Data.DataRow
            Dim sql As String = "Select * from Contacts where contactid = " & ContID
            Dim row As System.Data.DataRow
            Using db As New PromptDataHelper
                row = db.GetDataRow(sql)
            End Using
            Return row
        End Function
        Public Function getProjectName(ByVal projID As Integer) As String
            Dim sql As String = "Select ProjectName from projects where projectid = " & projID
            Dim row As String
            Using db As New PromptDataHelper
                row = db.ExecuteScalar(sql)
            End Using
            Return row
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

