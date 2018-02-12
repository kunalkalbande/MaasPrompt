Imports System
Imports System.Web
Imports System.Web.UI.WebControls
Imports System.IO
Imports System.Data
Imports System.Data.SqlClient
Imports Telerik.Web.UI
Imports System.Net.Mail

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

        Public Function getUserID(email As String) As Integer
            Dim id As Integer = 0
            Dim sql As String = "Select UserID From Users Where LoginID='" & email & "'"
            Dim tbl As DataTable = db.ExecuteDataTable(sql)
            If tbl.Rows.Count = 0 Then
                id = 0
            Else
                id = tbl.Rows(0).Item("UserID")
            End If

            Return id
        End Function

        Public Sub saveUserID(userID As Integer, contactID As Integer)
            Dim sql As String = "Update Contacts Set UserID=" & userID & " Where ContactID=" & contactID
            db.ExecuteNonQuery(sql)

        End Sub

        Public Function getUserAccount(ByVal ContactID As Integer) As Integer
            'Dim sql As String = "Select UserID From Users where Contact = " & ContactID
            Dim sql As String = "Select UserID From Contacts where ContactID = " & ContactID
            Dim UserID As Integer = 0

            Try
                UserID = db.ExecuteScalar(sql)
            Catch
                UserID = 0
            End Try

            Return UserID
        End Function

        Public Function checkAccountStatus(ByVal UserID As Integer) As Integer
            Dim sql As String = "Select AccountDisabled From Users Where UserID = " & UserID

            Dim status As Integer = db.ExecuteScalar(sql)

            Return status
        End Function

        Public Function switchCurrentAccountStatus(UserID As Integer) As Integer
            Dim status As Integer = checkAccountStatus(UserID)
            Dim newStatus As Integer = Nothing
            If status = 0 Then
                newStatus = 1
            ElseIf status = 1 Then
                newStatus = 0
            End If

            Dim sql As String = "Update Users Set AccountDisabled = " & newStatus & " Where UserID = " & UserID
            db.ExecuteScalar(sql)

            Return UserID
        End Function
        Public Function checkForExistingUser(email As String) As Integer
            Dim sql As String = 0
            Dim chkUser As Integer = 0
            sql = "Select UserID from Users Where LoginID = '" & email & "'"
            Try
                chkUser = db.ExecuteScalar(sql)
            Catch
            End Try

            Return chkUser
        End Function

        Public Function createRFIUserAccount(ContactID As Integer, userName As String, sEmail As String) As String
            Dim chkUser As Integer = 0
            Dim sql As String = ""
            Dim UserId As Integer

            Try
                chkUser = checkForExistingUser(sEmail)
            Catch
                chkUser = 0
            End Try

            If chkUser <> 0 Then
                sql = "Update Contacts Set UserID = " & chkUser & " Where ContactID = " & ContactID
                db.ExecuteScalar(sql)
            Else
                Dim encryptPW As String = ProcLib.EncryptString("tester1234" & sEmail)

                sql = "Insert Into Users (ClientID,UserName,UserRoleID,SecurityLevel,DistrictList,CollegeList,IsPM,LoginID,Password,"
                sql &= "LastUpdateOn,LastUpdateBy,UserType, IsWorkFlowUser, DashboardID, AccountDisabled, EncryptedPassword, LoginTrys,PasswordExpiresOn,SuppressWorkflowNotification"
                sql &= ",LiveTester,LastDistrictViewed,Contact) Values (" & 1 & ",'" & userName & "',8,0,';0;',';0;',0,'" & sEmail & "','tester1234','" & Now() & "','"
                sql &= HttpContext.Current.Session("UserName") & "','PromptUser',0,15,0,'" & encryptPW & "',0,'" & DateAdd(DateInterval.Day, 60, Now()) & "',0,0,0," & ContactID & " )"

                db.ExecuteScalar(sql)

                UserId = db.ExecuteScalar("select IDENT_CURRENT('users')")
                'UserId = db.ExecuteScalar("select UserID From Users Where LoginID=" & sEmail)

                sql = "Insert Into SecurityPermissions (UserID,RoleID,DistrictID,CollegeID,ProjectID,ObjectID,Permissions,ObjectType,LastUpdateOn,LastUpdateBy)"
                sql &= " Values (" & UserID & ",0," & HttpContext.Current.Session("DistrictID") & ",0,0,'SpecifyProjectAccess','Yes','ProjectRights','" & Now() & "','"
                sql &= HttpContext.Current.Session("UserName") & "')"

                db.ExecuteScalar(sql)

                sql = "Update Contacts Set UserID = " & UserId & " Where ContactID = " & ContactID

                db.ExecuteScalar(sql)
            End If

            Return sql
        End Function

        Public Function emailCredentials() As String
            'send the password to the user
            Dim objmail As New MailMessage
            With objmail
                .From = New MailAddress("support@eispro.com")
                '.To.Add(New MailAddress(LoginID))
                .Subject = "PROMPT Login Password"
                '.Body = "Your password has been reset. Your new temporary password is : " & pwd & vbCrLf & " (Password is case-sensitive)"
                .IsBodyHtml = False
            End With
            Dim smtpClient As New SmtpClient
            With smtpClient
                .Host = "mail.eispro.com"
                .Credentials = New System.Net.NetworkCredential("support@eispro.com", "maubi2007")
                '.Send(objmail)
            End With
            Return ""

            Return Nothing
        End Function

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

