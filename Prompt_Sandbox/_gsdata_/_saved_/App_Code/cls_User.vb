Imports System
Imports System.Web
Imports System.Web.UI.WebControls
Imports System.IO
Imports System.Data
Imports System.Data.SqlClient
Imports System.Net.Mail
Imports Telerik.Web.UI
Imports System.Collections.Generic
Imports System.Web.Script.Serialization


Namespace Prompt

    '********************************************
    '*  User Class
    '*  
    '*  Purpose: Processes data for the User objects
    '*
    '*  Last Mod By:    Ford James
    '*  Last Mod On:    10/25/09
    '*
    '********************************************

    Public Class promptUser
        Implements IDisposable

        'Properties
        Public CallingPage As Page
        Private db As PromptDataHelper


        Public TechUser As Boolean = False

        Public Sub New()
            db = New PromptDataHelper

        End Sub

#Region "User Roles"

        Public Function GetAllUserRoles() As DataTable

            Dim sql As String = "SELECT Dashboards.DashboardName, UserRoles.UserRoleID, UserRoles.RoleName, UserRoles.Description, "
            sql &= "Dashboards.PageName, Dashboards.DashboardType FROM UserRoles INNER JOIN "
            sql &= "Dashboards ON UserRoles.DashboardID = Dashboards.DashboardID ORDER BY RoleName "
            Return db.ExecuteDataTable(sql)

        End Function

        Public Sub GetRoleForEdit(ByVal RoleID As Integer)

            Dim form As Control = CallingPage.FindControl("Form1")  ' get ref to calling form
            Dim sql As String = ""

            'sql = "SELECT DashboardName as Lbl, DashboardID as Val FROM Dashboards ORDER BY DashboardName"
            'db.FillDropDown(sql, CallingPage.Form.FindControl("lstDashboardID"))

            'get record for edit
            If RoleID > 0 Then
                Dim row As DataRow = db.GetDataRow("SELECT * FROM UserRoles WHERE UserRoleID = " & RoleID)
                db.FillForm(form, row)

            End If


        End Sub

        Public Function SaveRole(ByVal roleID As Integer) As String

            'Takes data from the form and writes it to the database
            Dim message As String = ""
            Dim sql As String = ""
            Dim txtRoleName As TextBox = CallingPage.Form.FindControl("txtRoleName")
            If roleID = 0 Then      'new record 

                'check to see that the loginID does not already exist
                sql = "SELECT COUNT(RoleID) FROM Users WHERE RoleName = '" & txtRoleName.Text & "'"
                Dim result As Integer = db.ExecuteScalar(sql)
                If result <> 0 Then   'already there so bail
                    message = "Sorry, that Role is already being used. Please use another."
                    Return message
                End If

                sql = "INSERT INTO UserRoles "
                sql &= "(RoleName)"
                sql &= "VALUES ('NewRole') "
                sql &= "SELECT CAST(SCOPE_IDENTITY() AS int) AS ID"

                roleID = db.ExecuteScalar(sql)

            End If

            sql = "SELECT * FROM UserRoles WHERE UserRoleID = " & roleID
            'pass the form and sql to fill routine
            Dim form As Control = CallingPage.FindControl("Form1")
            db.SaveForm(form, sql)

            'Save the grid permissions
            Dim gridPermissions As RadGrid = CallingPage.Form.FindControl("Radgrid1")
            Using dbsec As New EISSecurity
                dbsec.SaveRolePermissions(gridPermissions, roleID)
            End Using


            Return message

        End Function

        Public Sub DeleteUserRole(ByVal id As Integer)

            Dim sql As String = "DELETE FROM Users WHERE UserID = " & id
            db.ExecuteNonQuery(sql)

        End Sub

        Public Function GetAllUsers(ByVal DistrictFilter As String, ByVal UserFilter As Integer) As DataTable

            Dim sql As String = ""
            Select Case DistrictFilter

                Case "Tech"
                    sql = "SELECT *, UserRoles.RoleName,  Dashboards.DashboardName AS Dashboard FROM Users INNER JOIN UserRoles ON Users.UserRoleID = UserRoles.UserRoleID "
                    sql &= " LEFT OUTER JOIN Dashboards ON Users.DashboardID = Dashboards.DashboardID WHERE Users.UserRoleID = 5 ORDER BY UserName"

                Case "Active"

                    If UserFilter = 0 Then
                        sql = "SELECT *,  UserRoles.RoleName,  Dashboards.DashboardName AS Dashboard FROM Users INNER JOIN UserRoles ON Users.UserRoleID = UserRoles.UserRoleID "
                        sql &= " LEFT OUTER JOIN Dashboards ON Users.DashboardID = Dashboards.DashboardID WHERE AccountDisabled = 0 ORDER BY UserName"
                    Else
                        sql = "SELECT *, UserRoles.RoleName,  Dashboards.DashboardName AS Dashboard FROM Users INNER JOIN UserRoles ON Users.UserRoleID = UserRoles.UserRoleID "
                        sql &= " LEFT OUTER JOIN Dashboards ON Users.DashboardID = Dashboards.DashboardID  WHERE  AccountDisabled = 0 AND UserID IN (SELECT UserID FROM SecurityPermissions WHERE DistrictID = " & UserFilter & ") AND Users.UserRoleID <> 5 ORDER BY UserName"
                    End If

                Case "All"

                    If UserFilter = 0 Then
                        sql = "SELECT *,  UserRoles.RoleName,  Dashboards.DashboardName AS Dashboard FROM Users INNER JOIN UserRoles ON Users.UserRoleID = UserRoles.UserRoleID "
                        sql &= " LEFT OUTER JOIN Dashboards ON Users.DashboardID = Dashboards.DashboardID ORDER BY UserName"
                    Else
                        sql = "SELECT *,  UserRoles.RoleName,  Dashboards.DashboardName AS Dashboard FROM Users INNER JOIN UserRoles ON Users.UserRoleID = UserRoles.UserRoleID  "
                        sql &= " LEFT OUTER JOIN Dashboards ON Users.DashboardID = Dashboards.DashboardID WHERE UserID IN (SELECT UserID FROM SecurityPermissions WHERE DistrictID = " & UserFilter & ") AND Users.UserRoleID <> 5 ORDER BY UserName"
                    End If

                Case "Disabled"
                    If UserFilter = 0 Then
                        sql = "SELECT *,  UserRoles.RoleName,  Dashboards.DashboardName AS Dashboard FROM Users INNER JOIN UserRoles ON Users.UserRoleID = UserRoles.UserRoleID "
                        sql &= " LEFT OUTER JOIN Dashboards ON Users.DashboardID = Dashboards.DashboardID WHERE AccountDisabled = 1 ORDER BY UserName"
                    Else
                        sql = "SELECT *,  UserRoles.RoleName,  Dashboards.DashboardName AS Dashboard FROM Users INNER JOIN UserRoles ON Users.UserRoleID = UserRoles.UserRoleID  "
                        sql &= " LEFT OUTER JOIN Dashboards ON Users.DashboardID = Dashboards.DashboardID WHERE  AccountDisabled = 1 AND UserID IN (SELECT UserID FROM SecurityPermissions WHERE DistrictID = " & UserFilter & ") AND Users.UserRoleID <> 5 ORDER BY UserName"
                    End If

            End Select

            Dim tbl As DataTable = db.ExecuteDataTable(sql)

            Return tbl

        End Function
#End Region

#Region "Users"

        Public Sub LoadAdminUserFilterList(ByVal lst As DropDownList)

            Dim sql As String = "SELECT DistrictID as Val, Name as Lbl FROM Districts ORDER BY Name"

            db.FillDropDown(sql, lst, False, False, False)

        End Sub

        Public Sub GetUserForEdit(ByVal UserID As Integer)

            Dim form As Control = CallingPage.FindControl("Form1")  ' get ref to calling form
            Dim sDistrictList As String = ""
            Dim sCollegeList As String = ""
            Dim sql As String = ""

            sql = "SELECT DashboardName as Lbl, DashboardID as Val FROM Dashboards ORDER BY DashboardName"
            db.FillDropDown(sql, form.FindControl("lstDashboardID"), True, True, False)

            sql = "SELECT RoleName as Lbl, UserRoleID as Val FROM UserRoles ORDER BY RoleName"
            db.FillDropDown(sql, form.FindControl("lstUserRoleID"))

            'get record for edit
            If UserID > 0 Then
                db.FillForm(form, "SELECT * FROM Users WHERE UserID = " & UserID)
            End If


        End Sub


        Public Function SaveUser(ByVal UserID As Integer) As String

            'Takes data from the form and writes it to the database
            Dim message As String = ""
            Dim sql As String = ""
            Dim txtLoginID As TextBox = CallingPage.Form.FindControl("txtLoginID")
            Dim txtPassword As TextBox = CallingPage.Form.FindControl("NewPassword")

            If UserID = 0 Then      'new record 

                'check to see that the loginID does not already exist
                sql = "SELECT COUNT(UserID) FROM Users WHERE LoginID = '" & txtLoginID.Text & "'"
                Dim result As Integer = db.ExecuteScalar(sql)
                If result <> 0 Then   'already there so bail
                    message = "Sorry, that Login ID is already being used. Please use another."
                    Return message
                End If

                sql = "INSERT INTO Users "
                sql &= "(ClientID,PasswordExpiresOn,Password)"
                sql &= "VALUES (" & CallingPage.Session("ClientID") & ",'" & Now() & "','maUbi2020') "
                sql &= "SELECT CAST(SCOPE_IDENTITY() AS int) AS ID"

                UserID = db.ExecuteScalar(sql)

                'set initial password
                ChangePasswordToDesignated(txtLoginID.Text, "maUbi2020")   'set inital password

            End If

            sql = "SELECT * FROM Users WHERE UserID = " & UserID
            'pass the form and sql to fill routine
            Dim form As Control = CallingPage.FindControl("Form1")
            db.SaveForm(form, sql)


            Return message

        End Function

        Public Sub DeleteUser(ByVal id As Integer)

            Dim sql As String = "DELETE FROM Users WHERE UserID = " & id
            db.ExecuteNonQuery(sql)

        End Sub


        Public Function ResetPasswordFromLoginPage(ByVal LoginID As String) As String

            'Sends the login ID a temporary password that they must change once they login in.
            'Called from login page

            'Make sure login ID is valid
            Dim sql As String = "SELECT COUNT(loginID) FROM Users WHERE loginID = '" & ProcLib.CleanText(LoginID) & "'"
            Dim result As Integer = db.ExecuteScalar(sql)
            If result <> 1 Then
                Return "Login ID not found."
            End If

            Dim pwd As String = ProcLib.GenerateRandomPassword()    'create random password 

            Dim sEncpwd As String = ProcLib.EncryptString(pwd & LoginID) 'Encrypt and salt with login ID

            'Write new password to database and reset the PasswordExpireDate for the user
            sql = "UPDATE Users SET EncryptedPassword = '" & sEncpwd & "',"
            sql &= "Password = '" & pwd & "',"     'NOTE: Testing only to log temp password
            sql &= "PasswordExpiresOn = '" & Now() & "',"
            sql &= "LastUpdateBy = 'LoginPage',"
            sql &= "LastUpdateOn = '" & Now() & "' "
            sql &= "WHERE LoginID = '" & LoginID & "'"
            db.ExecuteNonQuery(sql)

            'TEst for correct match
            sql = "SELECT EncryptedPassword FROM Users "
            sql &= "WHERE LoginID = '" & LoginID & "'"
            Dim sTestSaved As String = db.ExecuteScalar(sql)
            Dim sTestEnc As String = ProcLib.EncryptString(pwd & LoginID)

            If sTestSaved = sTestEnc Then
                'send the password to the user
                Dim objmail As New MailMessage
                With objmail
                    .From = New MailAddress("support@eispro.com")
                    .To.Add(New MailAddress(LoginID))
                    .Subject = "PROMPT Login Password"
                    .Body = "Your password has been reset. Your new temporary password is : " & pwd & vbCrLf & " (Password is case-sensitive)"
                    .IsBodyHtml = False
                End With
                Dim smtpClient As New SmtpClient
                With smtpClient
                    .Host = "mail.eispro.com"
                    .Credentials = New System.Net.NetworkCredential("support@eispro.com", "maubi2007")
                    .Send(objmail)
                End With
                Return ""
            Else
                Return "Password does not match saved in db. Check Fail."
            End If

        End Function

        Public Function ResetPassword(ByVal LoginID As String) As String

            'Sends the login ID a temporary password that they must change once they login in.
            'Called from User edit pages


            Dim pwd As String = ProcLib.GenerateRandomPassword()    'create random password 

            Dim sEncpwd As String = ProcLib.EncryptString(pwd & LoginID) 'Encrypt and salt with login ID

            'Write new password to database and reset the PasswordExpireDate for the user
            Dim sql As String = "UPDATE Users SET EncryptedPassword = '" & sEncpwd & "',"
            sql &= "Password = '" & pwd & "',"     'NOTE: Testing only to log temp password
            sql &= "PasswordExpiresOn = '" & Now() & "',"
            sql &= "LastUpdateBy = '" & CallingPage.Session("UserName") & "',"
            sql &= "LastUpdateOn = '" & Now() & "' "
            sql &= "WHERE LoginID = '" & LoginID & "'"
            db.ExecuteNonQuery(sql)

            'TEst for correct match
            sql = "SELECT EncryptedPassword FROM Users "
            sql &= "WHERE LoginID = '" & LoginID & "'"
            Dim sTestSaved As String = db.ExecuteScalar(sql)
            Dim sTestEnc As String = ProcLib.EncryptString(pwd & LoginID)

            If sTestSaved = sTestEnc Then
                'send the password to the user
                Dim objmail As New MailMessage
                With objmail
                    .From = New MailAddress("support@eispro.com")
                    .To.Add(New MailAddress(LoginID))
                    .Subject = "PROMPT Login Password"
                    .Body = "Your password has been reset. Your new temporary password is : " & pwd & vbCrLf & " (Password is case-sensitive)"
                    .IsBodyHtml = False
                End With
                Dim smtpClient As New SmtpClient
                With smtpClient
                    .Host = "mail.eispro.com"
                    .Credentials = New System.Net.NetworkCredential("support@eispro.com", "maubi2007")
                    .Send(objmail)
                End With
                Return "Password Changed Successfully. Temp Password sent to user."
            Else
                Return "Password does not match saved in db. Check Fail."
            End If

        End Function


        Public Function ChangePassword() As String

            'Changes the user password after login 
            Dim msg As String = ""
            Dim sOldEncrPassword As String = ""
            Dim nUserID As Integer = 0

            Dim sLoginID As String = HttpContext.Current.Session("LoginID")

            Dim sql As String = "SELECT UserID,EncryptedPassword FROM Users WHERE LoginID = '" & CallingPage.Session("LoginID") & "'"
            db.FillReader(sql)
            While db.Reader.Read
                sOldEncrPassword = db.Reader("EncryptedPassword")
                nUserID = db.Reader("UserID")
            End While
            db.Close()


            Dim sCurrPwd As String = ""
            If HttpContext.Current.Session("CurrentPwd") <> "" Then   'catch login ID from login password expire page
                sCurrPwd = HttpContext.Current.Session("CurrentPwd")
            Else
                sCurrPwd = DirectCast(CallingPage.Form.FindControl("txtCurrentPassword"), TextBox).Text
            End If

            Dim sNewPwd As String = DirectCast(CallingPage.Form.FindControl("txtNewPassword"), TextBox).Text
            Dim sConfirmPwd As String = DirectCast(CallingPage.Form.FindControl("txtConfirmPassword"), TextBox).Text

            'Check for valid entries
            If sCurrPwd = "" Then
                msg = "Please enter current password."
                Return msg
            End If
            If sNewPwd = "" Then
                msg = "Please enter new password."
                Return msg
            End If
            If sNewPwd = sCurrPwd Then
                msg = "You cannot reuse the current password. Please enter new password."
                Return msg
            End If
            If sNewPwd <> sConfirmPwd Then
                msg = "New password and Confirm password do not match."
                Return msg
            End If
            If sNewPwd = "Testpwd2" Then
                msg = "Cannot use example password. Please reenter."
                Return msg
            End If

            'Test that the current password is correct
            Dim sCurrEncryptedPwd As String = ProcLib.EncryptString(sCurrPwd & sLoginID) 'Encrypt and salt with login ID
            If sCurrEncryptedPwd <> sOldEncrPassword Then
                msg = "You entered and incorrect current password. Please retry."
                Return msg
            End If

            'Check that new password is at least 8 chars, contains at least 1 number and 1 ucase letter.
            Dim sRegExExpression As String = ""
            sRegExExpression &= "^"   ' anchor at the start
            sRegExExpression &= "(?=.*\d)" ' must contain at least one numeric character
            sRegExExpression &= "(?=.*[a-z])" ' must contain one lowercase character
            sRegExExpression &= "(?=.*[A-Z])" ' must contain one uppercase character
            sRegExExpression &= ".{8,15}"     'From 8 to 15 characters in length
            sRegExExpression &= "$"           'anchor at the end"

            If Not System.Text.RegularExpressions.Regex.IsMatch(sNewPwd, sRegExExpression) Then
                msg = "New password must be at least 8 characters and contain at least one number and one upper case letter. Please reenter."
                Return msg
            End If

            'got through basic validation. 
            Dim sNewEncPwd As String = ProcLib.EncryptString(sNewPwd & sLoginID) 'Encrypt and salt with login ID

            'Check that user has not previously used this password
            sql = "SELECT * FROM UsersPreviousPasswords WHERE UserID = " & nUserID & " ORDER BY LastUpdateOn DESC "
            db.FillReader(sql)
            Dim icnt As Integer = 0
            While db.Reader.Read
                If icnt < 4 Then
                    If sNewEncPwd = db.Reader("EncryptedPassword") Then
                        msg = "You cannot use a previously used password. Please try another."
                        Exit While
                    End If
                Else
                    Exit While
                End If
                icnt += 1

            End While
            db.Close()

            If msg <> "" Then
                Return msg
            Else
                'save the old password to the used paswword table
                sql = "INSERT INTO UsersPreviousPasswords (EncryptedPassword,UserID,LastUpdateOn) VALUES"
                sql &= "('" & sOldEncrPassword & "',"
                sql &= nUserID & ","
                sql &= "'" & Now() & "')"
                db.ExecuteNonQuery(sql)

                'TODO: Create Maintenace Routine to purge old passwords older than 1 year

            End If


            'Write new password to database and reset the PasswordExpireDate for the user
            sql = "UPDATE Users SET EncryptedPassword = '" & sNewEncPwd & "',"
            sql &= "Password = '" & sNewPwd & "',"     'NOTE: Testing only to log temp password
            sql &= "PasswordExpiresOn = '" & DateAdd(DateInterval.Day, 60, Now()) & "',"       'pwds expire every 60 days
            sql &= "LastUpdateBy = '" & CallingPage.Session("UserName") & "',"
            sql &= "LastUpdateOn = '" & Now() & "' "
            sql &= "WHERE LoginID = '" & sLoginID & "'"
            db.ExecuteNonQuery(sql)

            msg = "Your Password has been changed."



            Return msg

        End Function

        Public Sub ChangePasswordToDesignated(ByVal sloginID As String, ByVal sNewPwd As String)

            'Changes the user from the user edit page - does not check for strength and does not email user  
            Dim msg As String = ""
            Dim sOldEncrPassword As String = ""
            Dim nUserID As Integer = 0


            Dim sql As String = "SELECT UserID FROM Users WHERE LoginID = '" & sloginID & "'"
            nUserID = db.ExecuteScalar(sql)

            Dim sNewEncPwd As String = ProcLib.EncryptString(sNewPwd & sloginID) 'Encrypt and salt with login ID

            'Write new password to database and reset the PasswordExpireDate for the user
            sql = "UPDATE Users SET EncryptedPassword = '" & sNewEncPwd & "',"
            sql &= "Password = '" & sNewPwd & "',"     'NOTE: Testing only to log temp password
            sql &= "PasswordExpiresOn = '" & DateAdd(DateInterval.Day, 60, Now()) & "',"       'pwds expire every 60 days
            sql &= "LastUpdateBy = '" & CallingPage.Session("UserName") & "',"
            sql &= "LastUpdateOn = '" & Now() & "' "
            sql &= "WHERE LoginID = '" & sloginID & "'"
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

