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
    '*  Purpose: Processes data for the district object
    '*
    '*  Last Mod By:    Ford James
    '*  Last Mod On:    02/02/09
    '*
    '********************************************

    Public Class District
        Implements IDisposable

        'Properties
        Public CallingPage As Page
        Private db As PromptDataHelper

        Public Sub New()
            db = New PromptDataHelper
        End Sub

#Region "Subs and Functions"


        Public Sub GetDistrictForEdit(ByVal DistrictID As Integer)

            'loads a parent form with data from passed row
            Dim form As Control = CallingPage.FindControl("Form1")  ' get ref to calling form
            Dim sql As String = ""

            'Fill the dropdown controls -- we are using the title for both val and display here
            sql = "SELECT LookupValue As Val, LookupTitle as Lbl FROM dbo.Lookups WHERE "
            sql &= "ParentTable = 'Transactions' AND ParentField = 'FiscalYear' ORDER By LookupTitle"
            db.FillDropDown(sql, form.FindControl("lstFiscalYear"), True, False, False)

            'load form
            If DistrictID > 0 Then    'get a existing  record and populate with  info
                db.FillForm(form, "SELECT * FROM Districts WHERE DistrictID = " & DistrictID)
            End If
        End Sub

        Public Function GetDistrictList(ByVal clientid As Integer) As DataTable
            Return db.ExecuteDataTable("SELECT * FROM Districts WHERE ClientID = " & clientid & " ORDER BY Name")
        End Function


        Public Sub SaveDistrict(ByVal DistrictID As Integer, ByVal ClientID As Integer)

            If DistrictID = 0 Then  'this is new contractor so add new 
                Dim Sql As String = "INSERT INTO Districts "
                Sql &= "(ClientID) "
                Sql &= "VALUES (" & ClientID & ")"
                Sql &= ";SELECT NewKey = Scope_Identity()"  'return the new primary key
                DistrictID = db.ExecuteScalar(Sql)

            End If

            'Saves record
            db.SaveForm(CallingPage.Form, "SELECT * FROM Districts WHERE DistrictID = " & DistrictID)

        End Sub

        Public Function DeleteDistrict(ByVal DistrictID As Integer) As String
            Dim msg As String = ""
            Dim sql As String = "SELECT COUNT(CollegeID) as TOT FROM Colleges WHERE DistrictID = " & DistrictID
            Dim cnt As Integer = db.ExecuteScalar(sql)
            If cnt > 0 Then
                msg = "There are " & cnt & " Colleges associtated with this District. Please Delete all associated records before deleting this District. "
            Else
                db.ExecuteNonQuery("DELETE FROM Districts WHERE DistrictID = " & DistrictID)
            End If

            Return msg

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

