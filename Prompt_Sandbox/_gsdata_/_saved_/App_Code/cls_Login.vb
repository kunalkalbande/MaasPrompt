Imports System
Imports System.Web
Imports System.Web.UI.WebControls
Imports System.IO
Imports System.Data
Imports System.Data.SqlClient


Namespace Prompt

    '********************************************
    '*  Login Class
    '*  
    '*  Purpose: Processes Login Related requests
    '*
    '*  Last Mod By:    Ford James
    '*  Last Mod On:    12/15/11
    '*
    '********************************************

    Public Class promptLogin
        Implements IDisposable

        'Properties
        Public CallingPage As Page
        Private db As PromptDataHelper
        Private bLogInAsAnotherUser As Boolean = False    'flag for tech support function to log in as another user and bypass controls

        Public Sub New()
            db = New PromptDataHelper
        End Sub

#Region "Subs and Functions"


        Public Sub LogInAsAnotherUser(ByVal UserID As Integer)


            Dim Login As String = ""
            Dim Password As String = ""
            Dim sSQL As String = "SELECT LoginID,Password FROM Users WHERE UserID = " & UserID
            db.FillReader(sSQL)
            While db.Reader.Read()
                Login = db.Reader("LoginID")
                Password = ProcLib.CheckNullDBField(db.Reader("Password"))
            End While

            db.Close()

            bLogInAsAnotherUser = True

            ValidateUser(Login, Password)

        End Sub

        Public Overridable Function ValidateUser(ByVal loginID As String, ByVal password As String) As String

            Dim bLogonGood As Boolean = False
            Dim bStartPageIsDashboard As Boolean = False

            HttpContext.Current.Session("UserName") = ""     'reset session user name

            loginID = CleanText(loginID)
            password = CleanText(password)

            Dim EncryptedPassword As String = Proclib.EncryptString(password & loginID)

            Dim sSQL As String = "SELECT Users.*, Clients.ClientName, Dashboards.PageName AS DashboardPageName, "
            sSQL &= "Dashboards.DashboardType, UserRoles.RoleName AS UserRole "
            sSQL &= "FROM Users LEFT OUTER JOIN UserRoles ON Users.UserRoleID = UserRoles.UserRoleID LEFT OUTER JOIN "
            sSQL &= "Dashboards ON Users.DashboardID = Dashboards.DashboardID LEFT OUTER JOIN "
            sSQL &= "Clients ON Users.ClientID = Clients.ClientID "
            sSQL &= "WHERE LoginID = '" + loginID + "'"

            Dim rs As DataTable = db.ExecuteDataTable(sSQL)
            If rs.Rows.Count > 0 Then
                For Each row As DataRow In rs.Rows
                    'check for disabled
                    If Not IsDBNull(row("AccountDisabled")) Then
                        If row("AccountDisabled") = 1 Then
                            Return "AccountDisabled"
                        End If
                    End If


                    If Not IsDBNull(row("LoginTrysExceededOn")) Then
                        Dim dExceededOn As Date = row("LoginTrysExceededOn")
                        If DateDiff(DateInterval.Minute, dExceededOn, Now()) < 15 Then 'maxed login trys so need to wait until account is unlocked
                            Return "AccountLocked"
                        End If
                    End If

                    If HttpContext.Current.Session("DEBUGLiveTest") = "Y" And HttpContext.Current.Session("backdoorlogin") <> "y" Then
                        If Not IsDBNull(row("LiveTester")) Then
                            If row("LiveTester") <> 1 Then
                                Return "LiveTestingErr"
                            End If
                        Else
                            Return "LiveTestingErr"
                        End If

                    End If

                    If row("EncryptedPassword") = EncryptedPassword Or bLogInAsAnotherUser = True Then
                        'Check if password needs to be reset
                        If Not bLogInAsAnotherUser Then    'bypass expire check when tech support loginasanotheruser
                            If row("PasswordExpiresOn") < Now() Then 'pwd needs changing so redirect

                                Return "ChangePassword"    'flag to change password

                            End If
                        End If

                        'set up all session variables 
                        HttpContext.Current.Session("UserName") = row("UserName")
                        HttpContext.Current.Session("LoginID") = row("LoginID")
                        HttpContext.Current.Session("UserID") = row("UserID")

                        HttpContext.Current.Session("CurrentView") = "Login"
                        HttpContext.Current.Session("DashboardPageName") = ProcLib.CheckNullDBField(row("DashboardPageName"))
                        HttpContext.Current.Session("UserRole") = row("UserRole")
                        HttpContext.Current.Session("UserRoleID") = row("UserRoleID")
                        HttpContext.Current.Session("PreferredStartPage") = IIf(IsDBNull(row("PreferredStartPage")), "", row("PreferredStartPage"))

                        HttpContext.Current.Session("IsWorkflowUser") = IIf(IsDBNull(row("ISWorkflowUser")), 0, row("IsWorkflowUser"))


                        HttpContext.Current.Session("ClientID") = row("ClientID")
                        HttpContext.Current.Session("ClientName") = row("ClientName")

                        SetDistrictAndCollegeAccessList(row("UserID"))

                        bLogonGood = True

                        HttpContext.Current.Session("StartPageName") = "main.aspx"   'default for most people

                        If ProcLib.CheckNullDBField(row("DashboardType")) = "StandAlone" Then
                            bStartPageIsDashboard = True
                            HttpContext.Current.Session("StartPageName") = row("DashboardPageName")
                        End If


                    Else
                        'User is not found due to bad pwd ot login
                        Return IncrementLoginTrys(loginID)

                    End If
                Next
            Else
                Return "BadLoginID"
            End If

            If bStartPageIsDashboard Then
                'force the district for Dashboard users - will only get the first district in the list
                Dim sDistrict As String = ""
                Dim sVar As String = HttpContext.Current.Session("DistrictList")
                Dim sDistList() As String = sVar.Split(";")
                For Each s As String In sDistList
                    sDistrict = s.ToString
                    If sDistrict <> "" Then   'we have a district
                        HttpContext.Current.Session("DistrictID") = sDistrict
                        Exit For
                    End If
                Next
                'Get the district Name
                HttpContext.Current.Session("DistrictName") = db.ExecuteScalar("SELECT Name FROM Districts WHERE DistrictID = " & sDistrict)
                HttpContext.Current.Session("UsePromptName") = db.ExecuteScalar("SELECT UsePromptName FROM Districts WHERE DistrictID = " & sDistrict)
            End If

            If bLogonGood Then

                'Update the users record with last login time
                sSQL = "UPDATE Users SET LastLoginOn = '" & Now() & "',LoginTrys = 0 WHERE UserID = " & HttpContext.Current.Session("UserID")
                db.ExecuteNonQuery(sSQL)

                'Get users workflow role if appropriate
                HttpContext.Current.Session("WorkflowRole") = ""
                HttpContext.Current.Session("WorkflowRoleID") = 0

                Dim sql As String = "SELECT * FROM WorkflowRoles "
                sql &= "WHERE UserID = " & HttpContext.Current.Session("UserID")

                Dim rs1 As DataTable = db.ExecuteDataTable(sql)
                For Each row As DataRow In rs1.Rows
                    HttpContext.Current.Session("WorkflowRole") = row("WorkflowRole")
                    HttpContext.Current.Session("WorkflowRoleID") = row("WorkflowRoleID")
                    HttpContext.Current.Session("WorkflowRoleType") = row("RoleType")
                Next


            End If

            Return "Ok"

        End Function


        Public Sub SetUserStartPage()
            'This routine loads the last district the user visited if available, otherwise first in available access list,
            'and loads the user starup page

            'Get available districts for this user
            Dim userid As Integer = HttpContext.Current.Session("UserID")
            Dim slist As String = ""
            Dim sql As String = ""
            Dim tbl As DataTable

            Dim nFirstAvalDistrictID As Integer = 0

            If HttpContext.Current.Session("UserRole") = "TechSupport" Then  'allow all districts and colleges - fill session vars just for redundancy.
                sql = "SELECT DistrictID FROM Districts WHERE InActive <> 1 ORDER BY DistrictID "
                tbl = db.ExecuteDataTable(sql)
                For Each row As DataRow In tbl.Rows
                    If nFirstAvalDistrictID = 0 Then  'get the first district available
                        nFirstAvalDistrictID = row("DistrictID")
                    End If
                    slist &= ";" & row("DistrictID") & ";"
                Next
                HttpContext.Current.Session("DistrictList") = slist

                sql = "SELECT CollegeID FROM Colleges ORDER BY CollegeID "
                tbl = db.ExecuteDataTable(sql)
                For Each row As DataRow In tbl.Rows
                    slist &= ";" & row("CollegeID") & ";"
                Next
                HttpContext.Current.Session("CollegeList") = slist

            Else            'Only allow access where allowed

                sql = "SELECT DISTINCT DistrictID FROM SecurityPermissions WHERE UserID = " & userid
                tbl = db.ExecuteDataTable(sql)
                For Each row As DataRow In tbl.Rows
                    If nFirstAvalDistrictID = 0 Then  'get the first district available
                        nFirstAvalDistrictID = row("DistrictID")
                    End If
                    slist &= ";" & row("DistrictID") & ";"
                Next
                HttpContext.Current.Session("DistrictList") = slist

                slist = ""
                sql = "SELECT DISTINCT CollegeID FROM SecurityPermissions WHERE UserID = " & userid
                tbl = db.ExecuteDataTable(sql)
                For Each row As DataRow In tbl.Rows
                    slist &= ";" & row("CollegeID") & ";"
                Next
                HttpContext.Current.Session("CollegeList") = slist

            End If

            'get the last district and last app viewed by user
            Dim nLastDistrict As Integer = 0
            tbl = db.ExecuteDataTable("SELECT LastDistrictViewed FROM Users WHERE UserID = " & userid)
            If tbl.Rows.Count > 0 Then
                Dim row1 As DataRow = tbl.Rows(0)
                nLastDistrict = ProcLib.CheckNullNumField(row1("LastDistrictViewed"))
            End If

            If nLastDistrict = 0 Then           'set to first in available list
                HttpContext.Current.Session("DistrictID") = nFirstAvalDistrictID
                db.ExecuteNonQuery("UPDATE Users SET LastDistrictViewed = " & nFirstAvalDistrictID & " WHERE UserID = " & HttpContext.Current.Session("UserID"))
            Else
                HttpContext.Current.Session("DistrictID") = nLastDistrict
                HttpContext.Current.Session("UsePromptName") = db.ExecuteScalar("SELECT UsePromptName FROM Districts WHERE DistrictID = " & nLastDistrict)
            End If


        End Sub



        Private Sub SetDistrictAndCollegeAccessList(ByVal userid As Integer)

            Dim slist As String = ""
            Dim sql As String = "SELECT DISTINCT DistrictID FROM SecurityPermissions WHERE UserID = " & HttpContext.Current.Session("UserID")
            Dim tbl As DataTable = db.ExecuteDataTable(sql)
            For Each row As DataRow In tbl.Rows
                slist &= ";" & row("DistrictID") & ";"
            Next

            HttpContext.Current.Session("DistrictList") = slist

            slist = ""
            sql = "SELECT DISTINCT CollegeID FROM SecurityPermissions WHERE UserID = " & HttpContext.Current.Session("UserID")
            tbl = db.ExecuteDataTable(sql)
            For Each row As DataRow In tbl.Rows
                slist &= ";" & row("CollegeID") & ";"
            Next

            HttpContext.Current.Session("CollegeList") = slist

        End Sub

        Public Function IncrementLoginTrys(ByVal LoginID As String) As Integer
            'Logs each login attempt and after 5 disables the account for 15 minutes
            Dim nTrysLeft As Integer = 6
            Using db1 As New PromptDataHelper
                Dim sql As String = "SELECT LoginTrys FROM Users WHERE LoginID = '" & LoginID & "'"
                Dim nTrys As Integer = db1.ExecuteScalar(sql)
                nTrysLeft = nTrysLeft - nTrys
                nTrys = nTrys + 1
                If nTrysLeft = 0 Then
                    sql = "UPDATE Users SET LoginTrys = " & nTrys & ", LoginTrysExceededOn = '" & Now() & "' WHERE LoginID = '" & LoginID & "'"
                Else
                    sql = "UPDATE Users SET LoginTrys = " & nTrys & " WHERE LoginID = '" & LoginID & "'"
                End If
                db1.ExecuteNonQuery(sql)
            End Using

            Return nTrysLeft

        End Function

        Public Function AccountIsLocked(ByVal LoginID As String) As Boolean
            'Checks if account is temporarily locked out
            Dim sql As String = "SELECT LoginTrysExceededOn FROM Users WHERE LoginID = '" & LoginID & "'"
            Dim nDate As Date = db.ExecuteScalar(sql)
            If DateDiff(DateInterval.Minute, nDate, Now()) < 15 Then
                Return True
            Else
                Return False
            End If

        End Function


        Public Sub ResetSessionVariables()
            'reset all session credentials
            HttpContext.Current.Session("LoginID") = ""
            HttpContext.Current.Session("UserID") = 0
            HttpContext.Current.Session("DistrictList") = ""

            HttpContext.Current.Session("DistrictID") = 0
            HttpContext.Current.Session("UsePromptName") = 0
            HttpContext.Current.Session("CollegeID") = 0

            HttpContext.Current.Session("CollegeList") = ""
            HttpContext.Current.Session("CurrentView") = ""
            HttpContext.Current.Session("ClientID") = 0
            HttpContext.Current.Session("EnableWorkflow") = ""
            HttpContext.Current.Session("IsWorkflowUser") = 0
            HttpContext.Current.Session("StartPageName") = ""
            HttpContext.Current.Session("WorkflowRole") = ""
            HttpContext.Current.Session("RoleType") = ""
            HttpContext.Current.Session("WorkflowRoleID") = 0
            HttpContext.Current.Session("UserRole") = ""
            HttpContext.Current.Session("UserRoleID") = 0
            HttpContext.Current.Session("PreferredStartPage") = ""

        End Sub

        Private Function CleanText(ByVal txt As String) As String
            'remove any single quotes and ; in either the login or password screens 
            'to help protect against SQL Injection security issues.
            'the following will remove these potentially harmfull 
            'characters and just replace with empty strings.

            txt = txt.Replace(" oR ", "")
            txt = txt.Replace(" or ", "")
            txt = txt.Replace(" OR ", "")
            txt = txt.Replace(" Or ", "")
            txt = txt.Replace("'", "")
            txt = txt.Replace(";", "")
            txt = txt.Replace("--", "")
            txt = txt.Replace("DECLARE", "")
            txt = txt.Replace("sysobjects", "")
            txt = txt.Replace("syscolumns", "")
            txt = txt.Replace("CURSOR", "")
            txt = txt.Replace("@@", "")
            txt = txt.Replace("</", "")
            txt = txt.Replace("BEGIN", "")
            txt = txt.Replace("FETCH NEXT", "")

            Return txt

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
