Imports System
Imports System.Web
Imports System.Web.UI.WebControls
Imports System.IO
Imports System.Data
Imports System.Data.SqlClient

Namespace Prompt

    '********************************************
    '*  Furniture and Equipment Budgets Class (for: Foothill College / Shirley/Asha)
    '*  
    '*  Purpose: Processes data for the Dean objects
    '*
    '*  Last Mod By:    Roy Menezes
    '*  Last Mod On:    12/02/08
    '*
    '********************************************

    Public Class PromptFE_Budgets
        Implements IDisposable

        'Properties
        Public CallingPage As Page
        Private db As PromptDataHelper

        Public Reader As SqlDataReader
        Public DataTable As DataTable

        Public Sub New()
            db = New PromptDataHelper
        End Sub

#Region "Subs and Functions"


        Public Sub GetDivisionForEdit(ByVal DeanID As Integer)

            Dim form As Control = CallingPage.FindControl("Form1")  ' get ref to calling form

            'get record for edit
            If DeanID <> 0 Then
                Dim row As DataRow = db.GetDataRow("SELECT * FROM FE_Budgets WHERE DivisionID = " & DeanID)
                db.FillForm(form, row)
            End If


        End Sub

        Public Sub DeleteDivision(ByVal id As Integer)

            Dim sql As String = "DELETE FROM FE_Budgets WHERE DivisionID = " & id
            db.ExecuteNonQuery(sql)

        End Sub


        Public Sub SaveDivision(ByVal Key As Integer)
            Dim sql As String = ""
            'Takes data from the form and writes it to the database
            If Key = 0 Then      'new record
                sql = "INSERT INTO FE_Budgets (DistrictID,DivName) VALUES (" & CallingPage.Session("DistrictID") & ",'') SELECT CAST(SCOPE_IDENTITY() AS int) AS ID"
                Key = db.ExecuteScalar(sql)
            End If
            sql = "SELECT * FROM FE_Budgets WHERE DivisionID = " & Key
            'pass the form and sql to fill routine
            Dim form As Control = CallingPage.FindControl("Form1")
            db.SaveForm(form, sql)

            'write this change into the Furniture and Equipment Budget Log
            Dim strChangeText As String = "(DivisionName,AdminName,Budget,UpdateBy) => "
            sql = "Select DivName + ', ' + AdminName + ', ' + Convert(varchar,Budget) + ', ' From FE_Budgets Where DivisionID = " & Key
            strChangeText += db.ExecuteScalar(sql)
            strChangeText += CallingPage.Session("UserName")
            sql = "Insert into FE_BudgetLog (DistrictID, CollegeID, CreatedOn, Notes) Values (" & CallingPage.Session("DistrictID") _
                & "," & "1111" & ",'" & Now() & "','" & strChangeText & "')"
            db.ExecuteNonQuery(sql)
        End Sub

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

