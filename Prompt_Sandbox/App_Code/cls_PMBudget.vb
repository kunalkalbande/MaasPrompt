Imports System
Imports System.Web
Imports System.Web.UI.WebControls
Imports System.IO
Imports System.Data
Imports System.Data.SqlClient

Namespace Prompt

    '********************************************
    '*  Budget Class
    '*  
    '*  Purpose: Processes data for the PM Budget Object
    '*
    '*  Last Mod By:    Scott McKown
    '*  Last Mod On:    03/31/2016
    '*
    '********************************************

    Public Class PMBudget
        Implements IDisposable

        'Properties
        Public CallingPage As Page
        Private db As PromptDataHelper

        Public TotalEncumberedIsGreaterThanAllocated As Boolean = False   'to flag legacy over encumbered
        Private sql As String
        Private tbl As DataTable



        Public Sub New()
            db = New PromptDataHelper
        End Sub

#Region "Subs and Functions"

        Public Function getOriginalContract(projectID As Integer) As Double
            sql = "Select OrigBudget From Projects Where ProjectID = " & projectID
            Dim origBudget As Integer = db.ExecuteScalar(sql)

            Return origBudget
        End Function

        Public Function getSectionData(projectID As Integer, section As String) As DataTable
            sql = "Select * From PMBudget Where ProjectID = " & projectID & " AND Section = '" & section & "' AND IsActive=1 Order By RowNum asc"
            tbl = db.ExecuteDataTable(sql)

            Return tbl
        End Function

        Public Function getSectionTemplateData(districtID As Integer, section As String) As DataTable
            sql = "Select * From PMBudgetTemplates Where DistrictID = " & districtID & " AND Section = '" & section & "' AND IsActive=1 Order By RowNum asc"
            tbl = db.ExecuteDataTable(sql)

            Return tbl
        End Function

        Public Function insertTemplateDataIntoPMBudget(tbl As DataTable, projectID As Integer, districtID As Integer) As String
            For Each row As DataRow In tbl.Rows
                sql = "Insert Into PMBudget(ProjectID,Section,RowType,SubMember,CreateDate,CreateBy,ItemNum,ItemDesc,RowNum,DistrictID,IsActive,SubSection)"
                sql &= " values(" & projectID & ",'" & row.Item("Section") & "','" & row.Item("RowType") & "','" & row.Item("SubMember") & "','" & Now() & "'," & 0 & ",'" & row.Item("ItemNum") & "','" & row.Item("ItemDesc") & "'," & row.Item("RowNum") & "," & districtID & "," & 1 & ",'" & row.Item("SubSection") & "')"
                db.ExecuteNonQuery(sql)
            Next


            Return sql
        End Function

        Public Function insertSectionRow_V2(projectID As Integer, section As String, insertRow As Integer, itemNum As String, itemDesc As String, subMember As String, contactID As Integer) As String
            sql = "Insert Into PMBudget(ProjectID,Section,RowType,SubMember,CreateDate,CreateBy,ItemNum,ItemDesc,RowNum)"
            sql &= " values(" & projectID & ",'" & section & "','Item','" & subMember & "','" & Now() & "'," & contactID & ",'" & itemNum & "','" & itemDesc & "'," & insertRow & ")"
            db.ExecuteNonQuery(sql)

            Return sql
        End Function

        Public Function insertSectionRow(projectID As Integer, section As String, insertRow As Integer, itemNum As String, itemDesc As String, subMember As String, contactID As Integer) As String
            sql = "Insert Into PMBudget(ProjectID,Section,RowType,SubMember,CreateDate,CreateBy,ItemNum,ItemDesc,RowNum)"
            sql &= " values(" & projectID & ",'" & section & "','Item','" & subMember & "','" & Now() & "'," & contactID & ",'" & itemNum & "','" & itemDesc & "'," & insertRow & ")"
            db.ExecuteNonQuery(sql)

            Return sql
        End Function

        Public Function renumberSectionRows(projectID As Integer, section As String, startRow As Integer) As String
            Dim str As String

            sql = "Select * From PMBudget Where ProjectID=" & projectID & " AND Section='" & section & "' AND RowNum > " & startRow - 1 & " AND IsActive=1 order By RowNum asc "
            tbl = db.ExecuteDataTable(sql)

            For Each row As DataRow In tbl.Rows
                sql = "Update PMBudget Set RowNum = " & row.Item("RowNum") + 1 & " Where RowID = " & row.Item("RowID")
                db.ExecuteNonQuery(sql)


                str &= "Old Row #: " & row.Item("RowNum") & " New Row #: " & row.Item("RowNum") + 1 & " RowID: " & row.Item("RowID") & " -- "

            Next

            'str = "Renumber Rows Successful!!!"

            Return str
        End Function

        Public Function updateSectionData(projectID As Integer, section As String, tbl As DataTable) As String
            Dim str As String
            Dim clmn As String



            For Each row As DataRow In tbl.Rows
                clmn = getColumnName(row.Item("Column"))

                sql = "Update PMBudget Set "
                If Convert.ToInt32(row.Item("Column")) < 7 Then
                    sql &= clmn & " = " & row.Item("Value")
                Else
                    sql &= clmn & " = '" & row.Item("Value") & "'"
                End If

                sql &= " Where ProjectID = " & projectID & " AND RowNum = " & row.Item("Row") & " AND SubMember = '" & row.Item("Sub") & "' AND IsActive=1"

                db.ExecuteNonQuery(sql)
            Next



            Return "Save was successful!"
        End Function

        Public Function getColumnName(col As String) As String
            Dim clmn As String

            Select Case col
                Case "2"
                    clmn = "OrigBudget"
                Case "3"
                    clmn = "Pending"              
                Case "4"
                    clmn = "Actual"
                Case "5"
                    clmn = "Unencumbered"
                Case "6"
                    clmn = "Company"
                Case "7"
                    clmn = "Comment"
            End Select

            Return clmn
        End Function


#End Region



#Region "IDisposable"

        Public Overridable Sub Dispose() Implements IDisposable.Dispose
            If Not db Is Nothing Then
                db.Dispose()
            End If
        End Sub

#End Region

    End Class

End Namespace
