Imports System
Imports System.Web
Imports System.Web.UI.WebControls
Imports System.IO
Imports System.Data
Imports System.Data.SqlClient

Namespace Prompt

    '********************************************
    '*  Client Class
    '*  
    '*  Purpose: Processes data for the lookup object
    '*
    '*  Last Mod By:    Ford James
    '*  Last Mod On:    02/02/09
    '*
    '********************************************

    Public Class Lookup
        Implements IDisposable

        'Properties
        Public CallingPage As Page
        Private db As PromptDataHelper

        Public Sub New()
            db = New PromptDataHelper
        End Sub

#Region "Subs and Functions"

        Public Sub GetNewLookup()

            'get a blank  record and populate with initial info
            Dim dt As DataTable
            Dim row As DataRow
            dt = db.ExecuteDataTable("SELECT * FROM Lookups WHERE PrimaryKey = 0")
            row = dt.NewRow()

            LoadEditForm(row)


        End Sub

        Public Sub GetExistingLookup(ByVal LookupID As Integer)

            'get a existing  record and populate with  info
            Dim row As DataRow
            row = db.GetDataRow("SELECT * FROM Lookups WHERE PrimaryKey = " & LookupID)

            LoadEditForm(row)

        End Sub


        Private Sub LoadEditForm(ByVal row As DataRow)

            'loads a parent form with data from passed row
            Dim form As Control = CallingPage.FindControl("Form1")  ' get ref to calling form
            Dim sql As String = ""

            ''Fill the dropdown controls -- we are using the title for both val and display here
            'sql = "SELECT LookupValue As Val, LookupTitle as Lbl FROM dbo.Lookups WHERE "
            'sql &= "ParentTable = 'Transactions' AND ParentField = 'FiscalYear' ORDER By LookupTitle"
            'db.FillDropDown(sql, form.FindControl("lstFiscalYear"), True, False, False)

            'load form
            db.FillForm(form, row)

        End Sub

        Public Sub SaveLookup(ByVal LookupID As Integer, ByVal ParentTable As String, ByVal ParentField As String, ByVal IsGlobal As Boolean)

            If LookupID = 0 Then  'this is new so add new 
                Dim Sql As String = "INSERT INTO Lookups "
                Sql &= "(ParentTable,ParentField,DistrictID) "
                Sql &= "VALUES ('" & ParentTable & "','" & ParentField & "',"
                If IsGLobal Then
                    Sql &= "0)"
                Else
                    Sql &= CallingPage.Session("DistrictID") & ")"
                End If
                Sql &= ";SELECT NewKey = Scope_Identity()"  'return the new primary key
                LookupID = db.ExecuteScalar(Sql)
            End If

            'Saves record
            db.SaveForm(CallingPage.Form, "SELECT * FROM Lookups WHERE PrimaryKey = " & LookupID)

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

