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
    '*  Purpose: Processes data for the contractor object
    '*
    '*  Last Mod By:    Ford James
    '*  Last Mod On:    02/02/09
    '*
    '********************************************

    Public Class Contractor
        Implements IDisposable

        'Properties
        Public CallingPage As Page
        Private db As PromptDataHelper

        Public Sub New()
            db = New PromptDataHelper
        End Sub

#Region "Subs and Functions"

        Public Function GetAllContractors(ByVal DistrictID As Integer) As DataTable

            Return db.ExecuteDataTable("SELECT * FROM Contractors WHERE DistrictID = " & DistrictID & " ORDER BY Name")

        End Function

        Public Sub GetNewContractor()

            'get a blank contract record and populate with initial info
            Dim dt As DataTable
            Dim row As DataRow
            dt = db.ExecuteDataTable("SELECT * FROM Contractors WHERE ContractorID = -100") 'there is a "none" entry so to get new record have to call id we know is not there
            row = dt.NewRow()

            LoadEditForm(row)


        End Sub

        Public Sub GetExistingContractor(ByVal nContractorID As Integer)

            'get a existing contractor record and populate with  info
            Dim row As DataRow
            row = db.GetDataRow("SELECT * FROM Contractors WHERE ContractorID = " & nContractorID)

            LoadEditForm(row)

        End Sub


        Private Sub LoadEditForm(ByVal row As DataRow)

            'loads a parent form with data from passed row
            Dim form As Control = CallingPage.FindControl("Form1")  ' get ref to calling form
            Dim sql As String = ""

            'Fill the dropdown controls -- we are using the title for both val and display here
            sql = "SELECT LookupTitle As Val, LookupTitle as Lbl FROM Lookups WHERE DistrictID = " & HttpContext.Current.Session("DistrictID") & " "
            sql &= "AND ParentTable = 'Contractors' AND ParentField = 'ContractorType' ORDER BY LookupTitle"
            db.FillDropDown(sql, form.FindControl("lstcType"), True, False, False)

            'load form
            db.FillForm(form, row)

        End Sub

        Public Sub SaveContractor(ByVal nContractorID As Integer)

            If nContractorID = 0 Then  'this is new contractor so add new 
                Dim Sql As String = "INSERT INTO Contractors "
                Sql &= "(DistrictID) "
                Sql &= "VALUES ("
                Sql &= CallingPage.Session("DistrictID") & ")"
                Sql &= ";SELECT NewKey = Scope_Identity()"  'return the new primary key
                nContractorID = db.ExecuteScalar(Sql)
            End If

            'Saves record
            db.SaveForm(CallingPage.Form, "SELECT * FROM Contractors WHERE ContractorID = " & nContractorID)

        End Sub

        Public Function DeleteContractor(ByVal nContractorID As Integer) As String

            Dim msg As String = ""
            Dim sql As String = ""
            Dim cnt As Integer = 0
            sql = "SELECT COUNT(ProjectID) as TOT FROM Projects WHERE GC_Arch_ID = " & nContractorID
            cnt = db.ExecuteScalar(sql)
            If cnt > 0 Then                 'display a popup warning and close edit page
                msg = "This Contractor is assigned as GC/Arch on " & cnt & " Projects. Please reassign to Delete, or simply make the Contractor inactive. "
            End If

            sql = "SELECT COUNT(ProjectID) as TOT FROM Projects WHERE ArchID = " & nContractorID
            cnt = db.ExecuteScalar(sql)
            If cnt > 0 Then                 'display a popup warning and close edit page
                msg &= "This Contractor is assigned as Architect on " & cnt & " Projects. Please reassign to Delete, or simply make the Contractor inactive. "
            End If

            sql = "SELECT COUNT(ContractID) as TOT FROM Contracts WHERE ContractorID = " & nContractorID
            cnt = db.ExecuteScalar(sql)
            If cnt > 0 Then                 'display a popup warning and close edit page
                msg &= "There are " & cnt & " Contracts assigned to this Contractor. Please reassign to Delete, or simply make the Contractor inactive. "
            End If

            If msg = "" Then

                db.ExecuteNonQuery("DELETE FROM Contractors WHERE ContractorID = " & nContractorID)

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

