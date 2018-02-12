Imports System
Imports System.Web
Imports System.Web.UI.WebControls
Imports System.IO
Imports System.Data
Imports System.Data.SqlClient

Namespace Prompt

    '********************************************
    '*  Company Class
    '*  
    '*  Purpose: Processes data for the Company object
    '*
    '*  Last Mod By:    Ford James
    '*  Last Mod On:    08/02/10
    '*
    '********************************************

    Public Class Company
        Implements IDisposable

        'Properties
        Public CallingPage As Page
        Private db As PromptDataHelper

        Public Sub New()
            db = New PromptDataHelper
        End Sub

#Region "Subs and Functions"

        'Public Function GetAllCompanies(ByVal DistrictID As Integer) As DataTable

        '    Return db.ExecuteDataTable("SELECT * FROM Contacts WHERE DistrictID = " & DistrictID & " AND ContactType = 'Company' ORDER BY Name")

        'End Function

        Public Sub GetNewCompany()

            'get a blank contract record and populate with initial info
            Dim dt As DataTable
            Dim row As DataRow
            dt = db.ExecuteDataTable("SELECT * FROM Contractors WHERE ContractorID = -100") 'there is a "none" entry so to get new record have to call id we know is not there
            row = dt.NewRow()

            LoadEditForm(row)


        End Sub

        Public Sub GetExistingCompany(ByVal nContactID As Integer)

            'get a existing contractor record and populate with  info
            Dim row As DataRow
            row = db.GetDataRow("SELECT * FROM Contacts WHERE ContactID = " & nContactID)

            LoadEditForm(row)

        End Sub


        Private Sub LoadEditForm(ByVal row As DataRow)

            'loads a parent form with data from passed row
            Dim form As Control = CallingPage.FindControl("Form1")  ' get ref to calling form
            Dim sql As String = ""

            'Fill the dropdown controls -- we are using the title for both val and display here
            sql = "SELECT LookupTitle As Val, LookupTitle as Lbl FROM Lookups WHERE DistrictID = " & HttpContext.Current.Session("DistrictID") & " "
            sql &= "AND ParentTable = 'Contractors' AND ParentField = 'ContractorType' ORDER BY LookupTitle"
            db.FillRADComboBox(sql, form.FindControl("lstCompanyType"), True, False, False)

            'load form
            db.FillForm(form, row)

        End Sub

        Public Sub SaveCompany(ByVal nContactID As Integer)

            If nContactID = 0 Then  'this is new contractor so add new 
                Dim Sql As String = "INSERT INTO Contacts "
                Sql &= "(DistrictID,ContactType) "
                Sql &= "VALUES ("
                Sql &= CallingPage.Session("DistrictID") & ",'Company')"
                Sql &= ";SELECT NewKey = Scope_Identity()"  'return the new primary key
                nContactID = db.ExecuteScalar(Sql)
            End If

            'Saves record
            db.SaveForm(CallingPage.Form, "SELECT * FROM Contacts WHERE ContactID = " & nContactID)

            'For legacy
            db.ExecuteNonQuery("UPDATE Contacts SET CType = CompanyType WHERE ContactID = " & nContactID)

        End Sub

        Public Function DeleteCompany(ByVal nContactID As Integer) As String

            Dim msg As String = ""
            Dim sql As String = ""
            Dim cnt As Integer = 0
            sql = "SELECT COUNT(ProjectID) as TOT FROM Projects WHERE GC_Arch_ID = " & nContactID
            cnt = db.ExecuteScalar(sql)
            If cnt > 0 Then                 'display a popup warning and close edit page
                msg = "This Company is assigned as GC/Arch on " & cnt & " Projects. Please reassign to Delete, or simply make the Company inactive.  <br />"
            End If

            sql = "SELECT COUNT(ProjectID) as TOT FROM Projects WHERE ArchID = " & nContactID
            cnt = db.ExecuteScalar(sql)
            If cnt > 0 Then                 'display a popup warning and close edit page
                msg &= "This Company is assigned as Architect on " & cnt & " Projects. Please reassign to Delete, or simply make the Company inactive.  <br />"
            End If

            sql = "SELECT COUNT(ContractID) as TOT FROM Contracts WHERE ContractorID = " & nContactID
            cnt = db.ExecuteScalar(sql)
            If cnt > 0 Then                 'display a popup warning and close edit page
                msg &= "There are " & cnt & " Contracts assigned to this Company. Please reassign to Delete, or simply make the Company inactive.  <br />"
            End If

  
            sql = "SELECT COUNT(ProjectID) as TOT FROM Projects WHERE PM = " & nContactID
            cnt = db.ExecuteScalar(sql)
            If cnt > 0 Then                 'display a popup warning and close edit page
                msg &= "This Company is assigned as Project Manager on " & cnt & " Projects. Please reassign to Delete, or simply make the Contact inactive.  <br />"
            End If


            sql = "SELECT COUNT(InfoBulletinID) as TOT FROM InfoBulletins WHERE ToID = " & nContactID
            cnt = db.ExecuteScalar(sql)
            If cnt > 0 Then                 'display a popup warning and close edit page
                msg &= "There are " & cnt & " InfoBulletins assigned to this Company. Please reassign to Delete, or simply make the Company inactive.  <br />"
            End If
            sql = "SELECT COUNT(InfoBulletinID) as TOT FROM InfoBulletins WHERE FromID = " & nContactID
            cnt = db.ExecuteScalar(sql)
            If cnt > 0 Then                 'display a popup warning and close edit page
                msg &= "There are " & cnt & " InfoBulletins assigned to this Company. Please reassign to Delete, or simply make the Company inactive.  <br />"
            End If

            sql = "SELECT COUNT(SubmittalID) as TOT FROM Submittals WHERE SubmittedByID = " & nContactID
            cnt = db.ExecuteScalar(sql)
            If cnt > 0 Then                 'display a popup warning and close edit page
                msg &= "There are " & cnt & " Submittals assigned to this Company. Please reassign to Delete, or simply make the Company inactive.  <br />"
            End If
            sql = "SELECT COUNT(SubmittalID) as TOT FROM Submittals WHERE SubmittedToID = " & nContactID
            cnt = db.ExecuteScalar(sql)
            If cnt > 0 Then                 'display a popup warning and close edit page
                msg &= "There are " & cnt & " Submittals assigned to this Company. Please reassign to Delete, or simply make the Company inactive.  <br />"
            End If

            sql = "SELECT COUNT(TransmittalID) as TOT FROM Transmittals WHERE ToID = " & nContactID
            cnt = db.ExecuteScalar(sql)
            If cnt > 0 Then                 'display a popup warning and close edit page
                msg &= "There are " & cnt & " Transmittals assigned to this Company. Please reassign to Delete, or simply make the Company inactive.  <br />"
            End If
            sql = "SELECT COUNT(TransmittalID) as TOT FROM Transmittals WHERE FromID = " & nContactID
            cnt = db.ExecuteScalar(sql)
            If cnt > 0 Then                 'display a popup warning and close edit page
                msg &= "There are " & cnt & " Transmittals assigned to this Company. Please reassign to Delete, or simply make the Company inactive.  <br />"
            End If

            sql = "SELECT COUNT(RFIID) as TOT FROM RFIs WHERE TransmittedByID = " & nContactID
            cnt = db.ExecuteScalar(sql)
            If cnt > 0 Then                 'display a popup warning and close edit page
                msg &= "There are " & cnt & " RFIs assigned to this Company. Please reassign to Delete, or simply make the Company inactive.  <br />"
            End If
            sql = "SELECT COUNT(RFIID) as TOT FROM RFIs WHERE SubmittedToID = " & nContactID
            cnt = db.ExecuteScalar(sql)
            If cnt > 0 Then                 'display a popup warning and close edit page
                msg &= "There are " & cnt & " RFIs assigned to this Company. Please reassign to Delete, or simply make the Company inactive.  <br />"
            End If







            If msg = "" Then

                db.ExecuteNonQuery("DELETE FROM Contacts WHERE ContactID = " & nContactID)
                db.ExecuteNonQuery("DELETE FROM TeamMembers WHERE ContactID = " & nContactID)
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

