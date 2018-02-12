Imports System
Imports System.Web
Imports System.Web.UI.WebControls
Imports System.IO
Imports System.Data
Imports System.Data.SqlClient
Imports Telerik.Web.UI

Namespace Prompt

    '********************************************
    '*  Client Class
    '*  
    '*  Purpose: Processes data for the contact object
    '*
    '*  Last Mod By:    Ford James
    '*  Last Mod On:    02/02/10
    '*
    '********************************************

    Public Class Contact
        Implements IDisposable

        'Properties
        Public CallingPage As Page
        Private db As PromptDataHelper

        Public Sub New()
            db = New PromptDataHelper
        End Sub

#Region "Subs and Functions"

        Public Function GetAllContacts(ByVal DistrictID As Integer, Optional ByVal bFilterPMs As Boolean = False) As DataTable

            Dim sql As String = ""
            sql = "SELECT Contacts.*, "
            sql &= "Companies.Name AS Company FROM Contacts LEFT OUTER JOIN "
            sql &= "Contacts AS Companies ON Contacts.ParentContactID = Companies.ContactID "

            If bFilterPMs = True Then
                sql &= "WHERE Contacts.DistrictID = " & DistrictID & " AND Contacts.ContactType = 'ProjectManager' "
            Else
                sql &= "WHERE Contacts.DistrictID = " & DistrictID & " AND Contacts.ContactType <> 'Company' "
            End If

            sql &= "ORDER BY FirstName"

            Return db.ExecuteDataTable(sql)

        End Function

        Public Sub GetContactForEdit(ByVal nContactID As Integer)

            'loads a parent form with data from passed row
            Dim form As Control = CallingPage.FindControl("Form1")  ' get ref to calling form
            Dim sql As String = ""

            'Fill the dropdown controls -- we are using the title for both val and display here
            sql = "SELECT ContactID As Val, Name as Lbl FROM Contacts WHERE DistrictID = " & HttpContext.Current.Session("DistrictID") & " AND ContactType = 'Company' ORDER BY Name "
            db.FillNewRADComboBox(sql, form.FindControl("lstParentContactID"), True, True, False)

 
            sql = "SELECT DISTINCT Users.UserID As Val, Users.UserName as Lbl FROM Users INNER JOIN SecurityPermissions ON Users.UserID = SecurityPermissions.UserID "
            sql &= "WHERE ISPM = 1 AND SecurityPermissions.DistrictID = " & HttpContext.Current.Session("DistrictID") & " ORDER BY UserName ASC"
            db.FillNewRADComboBox(sql, form.FindControl("lstUserID"), True, True, False)
           
            'load form
            If nContactID > 0 Then
                db.FillForm(form, "SELECT * FROM Contacts WHERE ContactID = " & nContactID)
            End If


        End Sub

       

        Public Sub SaveContact(ByVal nContactID As Integer)

            If nContactID = 0 Then  'this is new contact so add new 
                Dim Sql As String = "INSERT INTO Contacts "
                Sql &= "(DistrictID,ContactType) "
                Sql &= "VALUES ("
                Sql &= CallingPage.Session("DistrictID") & ",'Contact')"
                Sql &= ";SELECT NewKey = Scope_Identity()"  'return the new primary key
                nContactID = db.ExecuteScalar(Sql)
            End If

            'Saves record
            db.SaveForm(CallingPage.Form, "SELECT * FROM Contacts WHERE ContactID = " & nContactID)

        End Sub

        Public Function DeleteContact(ByVal nContactID As Integer) As String

            Dim msg As String = ""
            Dim sql As String = ""
            Dim cnt As Integer = 0
            sql = "SELECT COUNT(ProjectID) as TOT FROM Projects WHERE GC_Arch_ID = " & nContactID
            cnt = db.ExecuteScalar(sql)
            If cnt > 0 Then                 'display a popup warning and close edit page
                msg = "This Contact is assigned as GC/Arch on " & cnt & " Projects. Please reassign to Delete, or simply make the Contact inactive. <br />"
            End If

            sql = "SELECT COUNT(ProjectID) as TOT FROM Projects WHERE ArchID = " & nContactID
            cnt = db.ExecuteScalar(sql)
            If cnt > 0 Then                 'display a popup warning and close edit page
                msg &= "This Contact is assigned as Architect on " & cnt & " Projects. Please reassign to Delete, or simply make the Contact inactive.  <br />"
            End If

            sql = "SELECT COUNT(ProjectID) as TOT FROM Projects WHERE PM = " & nContactID
            cnt = db.ExecuteScalar(sql)
            If cnt > 0 Then                 'display a popup warning and close edit page
                msg &= "This Contact is assigned as Project Manager on " & cnt & " Projects. Please reassign to Delete, or simply make the Contact inactive.  <br />"
            End If


            sql = "SELECT COUNT(ContractID) as TOT FROM Contracts WHERE ContractorID = " & nContactID
            cnt = db.ExecuteScalar(sql)
            If cnt > 0 Then                 'display a popup warning and close edit page
                msg &= "There are " & cnt & " Contracts assigned to this Contact. Please reassign to Delete, or simply make the Contact inactive.  <br />"
            End If

            sql = "SELECT COUNT(InfoBulletinID) as TOT FROM InfoBulletins WHERE ToID = " & nContactID
            cnt = db.ExecuteScalar(sql)
            If cnt > 0 Then                 'display a popup warning and close edit page
                msg &= "There are " & cnt & " InfoBulletins assigned to this Contact. Please reassign to Delete, or simply make the Contact inactive.  <br />"
            End If
            sql = "SELECT COUNT(InfoBulletinID) as TOT FROM InfoBulletins WHERE FromID = " & nContactID
            cnt = db.ExecuteScalar(sql)
            If cnt > 0 Then                 'display a popup warning and close edit page
                msg &= "There are " & cnt & " InfoBulletins assigned to this Contact. Please reassign to Delete, or simply make the Contact inactive.  <br />"
            End If

            sql = "SELECT COUNT(SubmittalID) as TOT FROM Submittals WHERE SubmittedByID = " & nContactID
            cnt = db.ExecuteScalar(sql)
            If cnt > 0 Then                 'display a popup warning and close edit page
                msg &= "There are " & cnt & " Submittals assigned to this Contact. Please reassign to Delete, or simply make the Contact inactive.  <br />"
            End If
            sql = "SELECT COUNT(SubmittalID) as TOT FROM Submittals WHERE SubmittedToID = " & nContactID
            cnt = db.ExecuteScalar(sql)
            If cnt > 0 Then                 'display a popup warning and close edit page
                msg &= "There are " & cnt & " Submittals assigned to this Contact. Please reassign to Delete, or simply make the Contact inactive.  <br />"
            End If

            sql = "SELECT COUNT(TransmittalID) as TOT FROM Transmittals WHERE ToID = " & nContactID
            cnt = db.ExecuteScalar(sql)
            If cnt > 0 Then                 'display a popup warning and close edit page
                msg &= "There are " & cnt & " Transmittals assigned to this Contact. Please reassign to Delete, or simply make the Contact inactive.  <br />"
            End If
            sql = "SELECT COUNT(TransmittalID) as TOT FROM Transmittals WHERE FromID = " & nContactID
            cnt = db.ExecuteScalar(sql)
            If cnt > 0 Then                 'display a popup warning and close edit page
                msg &= "There are " & cnt & " Transmittals assigned to this Contact. Please reassign to Delete, or simply make the Contact inactive.  <br />"
            End If

            sql = "SELECT COUNT(RFIID) as TOT FROM RFIs WHERE TransmittedByID = " & nContactID
            cnt = db.ExecuteScalar(sql)
            If cnt > 0 Then                 'display a popup warning and close edit page
                msg &= "There are " & cnt & " RFIs assigned to this Contact. Please reassign to Delete, or simply make the Contact inactive.  <br />"
            End If
            sql = "SELECT COUNT(RFIID) as TOT FROM RFIs WHERE SubmittedToID = " & nContactID
            cnt = db.ExecuteScalar(sql)
            If cnt > 0 Then                 'display a popup warning and close edit page
                msg &= "There are " & cnt & " RFIs assigned to this Contact. Please reassign to Delete, or simply make the Contact inactive.  <br />"
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

