Imports System
Imports System.Web
Imports System.Web.UI.WebControls
Imports System.IO
Imports System.Data
Imports System.Data.SqlClient
Imports System.Net.Mail
Namespace Prompt

    '********************************************
    '*  Workflow Class
    '*  
    '*  Purpose: Processes email messages to notify users 
    '*
    '*  Last Mod By:    Ford James
    '*  Last Mod On:    05/15/08
    '*
    '********************************************

    Public Class promptEmailNotify
        Implements IDisposable

        'Properties
        Public CallingPage As Page
        Private db As PromptDataHelper

        Public Sub New()
            db = New PromptDataHelper
        End Sub

#Region "Subs and Functions"

        Private Sub WriteLog(ByVal msg As String, ByVal Status As String, ByVal Source As String)

            'remove erroneous char
            msg = msg.Replace("'", "")

            Dim sDistrictID As String = HttpContext.Current.Session("DistrictID")   'for cases when called from scheduled task
            If sDistrictID = "" Then sDistrictID = 99

            'writes an entry to the Transaction Import Log
            Dim sql As String = "INSERT INTO FRS_ImportLog (DistrictID,LogDate,LogNotes,Status,Source) "
            sql &= "VALUES(" & sDistrictID & ",'" & Now & "','" & msg & "','" & Status & "','" & Source & "')"
            db.ExecuteNonQuery(sql)

        End Sub

        '12/09/2011 - roy - modified to send HTML emails (so a link to Prompt can be sent)
        Public Sub SendEmail(ByVal emailaddress As String, ByVal subject As String, ByVal msgtext As String)

            'For tech support only - send techsupport as entire email address
            Dim bTechOnly As Boolean = False
            If emailaddress = "techsupport" Then
                bTechOnly = True
            End If

            msgtext = msgtext.Replace(vbCrLf, "<br/>")  'change vbCRLF to html line breaks

            Dim mail As New MailMessage
            With mail
                .From = New MailAddress("PROMPT Notify System <support@eispro.com>")
                If ProcLib.GetLocale() = "Production" Then   'add real email addresses in production

                    If bTechOnly Then
                        .To.Add("ford@maasco.com")
                        .To.Add("roy@maasco.com")
                    Else
                        .To.Add(New MailAddress(emailaddress))
                    End If

                Else 'Debugg - triggered from local or beta
                    .To.Add("ford@maasco.com")
                    .To.Add("roy@maasco.com")
                    msgtext &= vbCrLf & "(DEBUGG - Email notify List)" & vbCrLf & emailaddress    'show list of production targets in email body
                End If
                .Subject = subject
                .Body = msgtext

                .IsBodyHtml = True
            End With
            Dim smtpClient As New SmtpClient
            With smtpClient
                .Host = "mail.eispro.com"
                .Credentials = New System.Net.NetworkCredential("support@eispro.com", "maubi2007")
                .Send(mail)
            End With

        End Sub

        Public Sub NotifyAllActiveUsers(ByVal msgtext As String, ByVal bTestOnly As Boolean)
            'sends message to all active users
            Dim sDebuggEmailAddresses As String = ""
            Dim tbl As DataTable = db.ExecuteDataTable("SELECT LoginID FROM Users WHERE AccountDisabled = 0 ORDER BY UserName ")
            For Each row As DataRow In tbl.Rows
                Dim sEmailAddress As String = ProcLib.CheckNullDBField(row("LoginID"))
                'Check valid email address
                If System.Text.RegularExpressions.Regex.IsMatch(sEmailAddress, "^[a-zA-Z][\w\.-]*[a-zA-Z0-9]@[a-zA-Z0-9][\w\.-]*[a-zA-Z0-9]\.[a-zA-Z][a-zA-Z\.]*[a-zA-Z]$") = True Then
                    sDebuggEmailAddresses &= ProcLib.CheckNullDBField(row("LoginID")) & vbCrLf    'for debugg
                End If

            Next

            msgtext = msgtext.Replace("<br/>", vbCrLf)  'change html line break to vbcrlf

            Dim mail As New MailMessage
            With mail
                .From = New MailAddress("PROMPT Technical Support <support@eispro.com>")

                If bTestOnly Then
                    tbl = db.ExecuteDataTable("SELECT LoginID FROM Users WHERE UserRoleID = 5 ORDER BY UserName ")    'Tech Support
                    For Each row As DataRow In tbl.Rows
                        Dim sEmailAddress As String = ProcLib.CheckNullDBField(row("LoginID"))
                        'Check valid email address
                        If System.Text.RegularExpressions.Regex.IsMatch(sEmailAddress, "^[a-zA-Z][\w\.-]*[a-zA-Z0-9]@[a-zA-Z0-9][\w\.-]*[a-zA-Z0-9]\.[a-zA-Z][a-zA-Z\.]*[a-zA-Z]$") = True Then
                            .To.Add(sEmailAddress)
                        End If

                    Next
                    msgtext &= vbCrLf & "(Test Only - Active Users Email List)" & vbCrLf & sDebuggEmailAddresses    'show list of production targets in email body

                Else

                    If ProcLib.GetLocale() = "Production" Then   'add real email addresses in production
                        For Each row As DataRow In tbl.Rows
                            Dim sEmailAddress As String = ProcLib.CheckNullDBField(row("LoginID"))
                            'Check valid email address
                            If System.Text.RegularExpressions.Regex.IsMatch(sEmailAddress, "^[a-zA-Z][\w\.-]*[a-zA-Z0-9]@[a-zA-Z0-9][\w\.-]*[a-zA-Z0-9]\.[a-zA-Z][a-zA-Z\.]*[a-zA-Z]$") = True Then
                                .Bcc.Add(New MailAddress(sEmailAddress))
                            End If

                        Next

                    Else                        'Debugg - triggered from local or beta
                        tbl = db.ExecuteDataTable("SELECT LoginID FROM Users WHERE UserRoleID = 5 ORDER BY UserName ")    'Tech Support
                        For Each row As DataRow In tbl.Rows
                            Dim sEmailAddress As String = ProcLib.CheckNullDBField(row("LoginID"))
                            'Check valid email address
                            If System.Text.RegularExpressions.Regex.IsMatch(sEmailAddress, "^[a-zA-Z][\w\.-]*[a-zA-Z0-9]@[a-zA-Z0-9][\w\.-]*[a-zA-Z0-9]\.[a-zA-Z][a-zA-Z\.]*[a-zA-Z]$") = True Then
                                .To.Add(sEmailAddress)
                            End If

                        Next
                        msgtext &= vbCrLf & "(Test Only - Active Users Email List)" & vbCrLf & sDebuggEmailAddresses    'show list of production targets in email body
                    End If

                End If
                .Subject = "Prompt Announcement"
                .Body = msgtext

                .IsBodyHtml = False
            End With
            Dim smtpClient As New SmtpClient
            With smtpClient
                .Host = "mail.eispro.com"
                .Credentials = New System.Net.NetworkCredential("support@eispro.com", "maubi2007")
                .Send(mail)
            End With

        End Sub


        Public Sub NotifyUsersOfNewInboxItems(Optional ByVal CopyToTechSupport As Boolean = False)
            'This proc will check for new items in any users inbox and send consolodated email to notify them.
            'Get all transactions that are in workflow and have actions done on them except inital add to workflow stream.
            Dim sql As String = "SELECT Users.UserName, Users.LoginID, ISNULL(Users.SuppressWorkflowNotification,0) AS SuppressWorkflowNotification, Transactions.TransactionID, Transactions.CurrentWorkflowOwnerNotifiedOn "
            sql &= "FROM WorkflowRoles INNER JOIN Users ON WorkflowRoles.UserID = Users.UserID INNER JOIN "
            sql &= "Transactions ON WorkflowRoles.WorkflowRoleID = Transactions.CurrentWorkflowRoleID "
            sql &= "WHERE (Transactions.LastWorkflowAction IS NOT NULL) AND (Transactions.LastWorkflowAction <> 'Add to Workflow') AND (Transactions.CurrentWorkflowOwnerNotifiedOn IS NULL)"
            db.FillReader(sql)
            Dim sUserList As String = ""
            Dim sTransactionList As String = ""
            While db.Reader.Read
                If db.Reader("SuppressWorkflowNotification") <> 1 Then
                    If Not sUserList.Contains(db.Reader("LoginID")) Then
                        sUserList &= db.Reader("LoginID") & ";"
                    End If
                    sTransactionList &= db.Reader("TransactionID") & ","
                End If
            End While
            db.Reader.Close()

            If sUserList <> "" Then  'process the list
                sUserList = sUserList.Remove(sUserList.Length - 1, 1)     'remove the last ;
                Dim aUserList() As String = sUserList.Split(";")
                For Each target As String In aUserList
                    Dim msg As String = "There are new items for you to review in your PROMPT Inbox. " & vbCrLf _
                        & "https://prompted.eispro.com" & vbCrLf & "PROMPT Notify System" & vbCrLf
                    Dim subject As String = "New Items in your PROMPT Inbox"
                    SendEmail(target, subject, msg)

                    'send tech copy
                    If CopyToTechSupport = True Then
                        SendEmail("techsupport", subject & "(" & target & ")", msg)
                    End If

                Next

            End If

            'Now update transactions
            If sTransactionList <> "" Then
                sTransactionList = sTransactionList.Remove(sTransactionList.Length - 1, 1)      'remove the last ,
                sql = "UPDATE Transactions SET CurrentWorkflowOwnerNotifiedOn = '" & Now & "' WHERE TransactionID IN (" & sTransactionList & ")"
                db.ExecuteNonQuery(sql)
            End If

            WriteLog("Sent Notify Emails", "NotifiedUsers", "NotifyUsersOfNewInboxItems")   'just log that it went



        End Sub


        'Public Sub NotifyWorkflowUsers(ByVal Action As String, ByVal subject As String, ByVal msgtext As String, Optional ByVal SenderEmail As String = "")

        '    Dim sql As String = ""

        '    msgtext = msgtext.Replace("<br/>", vbCrLf)  'change html line break to vbcrlf

        '    'Send an email to all designated workflow users for this action by current owner
        '    sql = "SELECT Users.LoginID, WorkflowScenerioOwners.DistrictID, WorkflowScenerioOwners.WorkflowRoleID "
        '    sql &= "FROM WorkflowScenerioOwners INNER JOIN WorkflowScenerioOwnerNotifyList ON "
        '    sql &= "WorkflowScenerioOwners.WorkflowScenerioOwnerID = WorkflowScenerioOwnerNotifyList.WorkflowScenerioOwnerID INNER JOIN "
        '    sql &= "Users ON WorkflowScenerioOwnerNotifyList.PromptUserID = Users.UserID "
        '    sql &= "WHERE WorkflowScenerioOwnerNotifyList.Action = '" & Action & "' AND "
        '    sql &= "WorkflowScenerioOwners.DistrictID = " & HttpContext.Current.Session("DistrictID") & " AND "
        '    sql &= "WorkflowScenerioOwners.WorkflowRoleID = " & HttpContext.Current.Session("WorkflowRoleID")

        '    Dim rs As SqlDataReader = db.ExecuteReader(sql)
        '    Dim sEmailList As String = ""
        '    While rs.Read
        '        sEmailList &= rs("LoginID") & ";"  'for the email notify
        '    End While
        '    rs.Close()

        '    If SenderEmail <> "" Then
        '        If Not sEmailList.Contains(SenderEmail) Then   'add the senders email if not already there
        '            sEmailList &= SenderEmail
        '        End If
        '    End If

        '    Dim mail As New MailMessage
        '    With mail
        '        .From = New MailAddress("support@eispro.com")
        '        If Proclib.GetLocale() = "Production" Then   'add real email addresses in production
        '            Dim aList() As String = sEmailList.Split(";")
        '            For Each sEmailAddress As String In aList
        '                .To.Add(New MailAddress(sEmailAddress))
        '            Next
        '        Else 'Debugg
        '            .To.Add("ford@maasco.com")
        '            msgtext &= vbCrLf & "(DEBUGG - Email notify List)" & vbCrLf & sEmailList
        '        End If
        '        .Subject = subject
        '        .Body = msgtext

        '        .IsBodyHtml = False
        '    End With
        '    Dim smtpClient As New SmtpClient
        '    With smtpClient
        '        .Host = "mail.eispro.com"
        '        .Credentials = New System.Net.NetworkCredential("support@eispro.com", "maubi2007")
        '        .Send(mail)
        '    End With



        'End Sub
        Private Function GetNotifyEmailAddresses(ByVal NotifyType As String, ByVal TransactionID As Integer) As String
            'returns a string with all appropriate email addresses for mail message

            Dim sEmails As New StringBuilder
            With sEmails
                .Append("ford@maasco.com;")   'add tech support users
                .Append("roy@maasco.com;")
            End With

            Select Case NotifyType
                Case "FRSTransferError"

                    Dim Sql As String = "SELECT * FROM qry_GetWorkflowScenerioNotifyUsers WHERE TransactionID = " & TransactionID
                    Using rs As New PromptDataHelper
                        rs.FillReader(Sql)
                        While rs.Reader.Read
                            sEmails.Append(rs.Reader("LoginID") & ";")
                        End While
                        rs.Close()

                    End Using
            End Select

            Return sEmails.ToString


        End Function
        Public Sub NotifyWorkflowOwnersOfFRSTransferErrors()

            ''This routine will notify all Workflow Scenerio Owners of any errors in processing files imported from the District.
            ''Currently for FRS only

            WriteLog("BeginEmailNotify", "", "NotifyWorkflowOwnersOfFRSTransferErrors")

            'Open the Import Log file and get all entries with no Notify date
            Dim sql As String = "SELECT * FROM FRS_ImportLog WHERE NotifySentOn IS NULL "
            Dim rs As SqlDataReader = db.ExecuteReader(sql)

            Dim sEmailMessage As String = ""

            While rs.Read
                sEmailMessage = ""
                If UCase(rs("Status")) = "WARNING" Or UCase(rs("Status")) = "ERROR" Then      'notify appropriate users

                    Dim LogID As Integer = rs("PrimaryKey")

                    sEmailMessage = rs("LogNotes")
                    sEmailMessage = sEmailMessage.Replace("<br/>", vbCrLf)   'swap out html breaks for crlf

                    Dim sEmailList As String = GetNotifyEmailAddresses("FRSTransferError", rs("TransactionID"))

                    Dim mail As New MailMessage
                    With mail
                        .Subject = "PROMPT-FRS Transfer Error"
                        .From = New MailAddress("PROMPT Notify System <support@eispro.com>")

                        If Proclib.GetLocale() = "Production" Then
                            Dim aList() As String = sEmailList.Split(";")
                            For Each sEmailAddress As String In aList
                                .To.Add(New MailAddress(sEmailAddress))
                            Next

                        Else                     'only send to tech support 
                            .To.Add("ford@maasco.com")
                            .To.Add("roy@maasco.com")

                            sEmailMessage &= vbCrLf & "(DEBUGG - Email notify List)" & vbCrLf

                            Dim aList() As String = sEmailList.Split(";")   ' append whole notify list to message for debugging
                            For Each sEmailAddress As String In aList
                                sEmailMessage &= sEmailAddress & vbCrLf
                            Next

                        End If

                        .Body = sEmailMessage

                        .IsBodyHtml = False
                    End With
                    Dim smtpClient As New SmtpClient
                    With smtpClient
                        .Host = "mail.eispro.com"
                        .Credentials = New System.Net.NetworkCredential("support@eispro.com", "maubi2007")
                        Try
                            .Send(mail)
                        Catch ex As Exception
                            WriteLog(ex.Message, "MailError", "NotifyWorkflowOwnersOfFRSTransferErrors")
                        End Try


                    End With

                    Using db1 As New PromptDataHelper
                        sql = "UPDATE FRS_ImportLog SET NotifySentOn = '" & Now() & "' WHERE PrimaryKey = " & LogID
                        db1.ExecuteNonQuery(sql)
                    End Using

                End If

            End While
            rs.Close()

            WriteLog("EndEmailNotify", "", "NotifyWorkflowOwnersOfFRSTransferErrors")

        End Sub



        'Public Sub NotifyAllWorkflowUsersOfGeneralError(ByVal subject As String, ByVal msgtext As String)

        '    'This routine will notify all workflow users for the district that there was an error and email message to all of them.
        '    'this is used when the error is not Transaction Specifc.

        '    msgtext = msgtext.Replace("<br/>", vbCrLf)  'change html line break to vbcrlf

        '    'Notify all normal prompt users for the district with security level = 10 
        '    Dim Sql As String = "SELECT WorkflowRoles.WorkflowRoleID, Users.LoginID "
        '    Sql &= "FROM WorkflowRoles INNER JOIN WorkflowRolesUsers ON WorkflowRoles.WorkflowRoleID = WorkflowRolesUsers.WorkflowRoleID INNER JOIN "
        '    Sql &= "Users ON WorkflowRolesUsers.UserID = Users.UserID WHERE WorkflowRoles.DistrictID = " & HttpContext.Current.Session("DistrictID") & " "
        '    Sql &= "AND IsWorkflowUser=1 AND SecurityLevel = 10"

        '    Dim rs As SqlDataReader = db.ExecuteReader(Sql)
        '    Dim sEmailList As String = ""
        '    Dim sFlagNotifyList As String = ""
        '    While rs.Read
        '        sEmailList &= rs("LoginID") & ";"  'for the email notify
        '    End While
        '    rs.Close()

        '    Dim mail As New MailMessage
        '    With mail
        '        .From = New MailAddress("support@eispro.com")
        '        If Proclib.GetLocale() = "Production" Then   'add real email addresses in production
        '            Dim aList() As String = sEmailList.Split(";")
        '            For Each sEmailAddress As String In aList
        '                .To.Add(New MailAddress(sEmailAddress))
        '            Next
        '        Else 'Debugg
        '            .To.Add("ford@maasco.com")
        '            msgtext &= vbCrLf & "(DEBUGG - Email notify List)" & vbCrLf & sEmailList
        '        End If
        '        .Subject = subject
        '        .Body = msgtext

        '        .IsBodyHtml = False
        '    End With
        '    Dim smtpClient As New SmtpClient
        '    With smtpClient
        '        .Host = "mail.eispro.com"
        '        .Credentials = New System.Net.NetworkCredential("support@eispro.com", "maubi2007")
        '        .Send(mail)
        '    End With

        'End Sub

        'Public Sub NotifyTechSupportOfGeneralError(ByVal subject As String, ByVal msgtext As String)

        '    'This routine will notify tech support users there was an error and email message.
        '    'this is used when the error is not Transaction Specifc.

        '    msgtext = msgtext.Replace("<br/>", vbCrLf)  'change html line break to vbcrlf

        '    'Notify all tech support users 
        '    Dim Sql As String = "SELECT Users.LoginID FROM Users WHERE SecurityLevel = 99 "
        '    Dim rs As SqlDataReader = db.ExecuteReader(Sql)
        '    Dim sEmailList As String = ""
        '    Dim sFlagNotifyList As String = ""
        '    While rs.Read
        '        sEmailList &= rs("LoginID") & ";"  'for the email notify
        '    End While
        '    rs.Close()

        '    Dim mail As New MailMessage
        '    With mail
        '        .From = New MailAddress("support@eispro.com")
        '        If Proclib.GetLocale() = "Production" Then   'add real email addresses in production
        '            Dim aList() As String = sEmailList.Split(";")
        '            For Each sEmailAddress As String In aList
        '                .To.Add(New MailAddress(sEmailAddress))
        '            Next
        '        Else 'Debugg
        '            .To.Add("ford@maasco.com")
        '            .To.Add("roy@maasco.com")
        '            .To.Add("rafael@maasco.com")
        '            msgtext &= vbCrLf & "(DEBUGG - Email notify List)" & vbCrLf & sEmailList
        '        End If
        '        .Subject = subject
        '        .Body = msgtext

        '        .IsBodyHtml = False
        '    End With
        '    Dim smtpClient As New SmtpClient
        '    With smtpClient
        '        .Host = "mail.eispro.com"
        '        .Credentials = New System.Net.NetworkCredential("support@eispro.com", "maubi2007")
        '        .Send(mail)
        '    End With

        'End Sub

        'Public Sub NotifyAffectedUsersForTransactionError(ByVal subject As String, ByVal msgtext As String, ByVal TransactionID As String)

        '    'This routine will look at all users that approved a given transaction and email message to all of them.

        '    msgtext = msgtext.Replace("<br/>", vbCrLf)  'change html line break to vbcrlf

        '    'Get all the users that have approved this transaction in the workflow to date
        '    Dim Sql As String = "SELECT Users.LoginID, Users.UserName, WorkflowLog.WorkflowAction "
        '    Sql &= "FROM WorkflowLog INNER JOIN WorkflowRoles ON WorkflowLog.WorkflowRoleID = WorkflowRoles.WorkflowRoleID INNER JOIN "
        '    Sql &= "Users ON WorkflowRoles.UserID = Users.UserID "
        '    Sql &= "WHERE WorkflowLog.TransactionID = " & TransactionID & " AND WorkflowLog.WorkflowAction LIKE N'Approved%'"

        '    Dim rs As SqlDataReader = db.ExecuteReader(Sql)
        '    Dim sEmailList As String = ""
        '    Dim sEmailNames As String = ""  'for inclusion in DEbug
        '    Dim sFlagNotifyList As String = ""
        '    While rs.Read
        '        If Not sEmailList.Contains(rs("LoginID")) Then
        '            sEmailList &= rs("LoginID") & ";"  'for the email notify
        '            sEmailNames &= rs("LoginID") & vbCrLf  'for the email notify
        '        End If

        '    End While
        '    rs.Close()

        '    Dim mail As New MailMessage
        '    With mail
        '        .From = New MailAddress("support@eispro.com")
        '        If Proclib.GetLocale() = "Production" Then   'add real email addresses in production
        '            Dim aList() As String = sEmailList.Split(";")
        '            For Each sEmailAddress As String In aList
        '                .To.Add(New MailAddress(sEmailAddress))
        '            Next
        '        Else 'Debugg
        '            .To.Add("ford@maasco.com")
        '            msgtext &= vbCrLf & "(DEBUGG - Email notify List)" & vbCrLf & sEmailNames
        '        End If
        '        .Subject = subject
        '        .Body = msgtext

        '        .IsBodyHtml = False
        '    End With
        '    Dim smtpClient As New SmtpClient
        '    With smtpClient
        '        .Host = "mail.eispro.com"
        '        .Credentials = New System.Net.NetworkCredential("support@eispro.com", "maubi2007")
        '        .Send(mail)
        '    End With

        '    'Update the 




        'End Sub


        ' this routine notifies the Prompt Accounts 60-days prior to Contract Expiration or Contract Insurance Expiration
        Public Sub FHDAContractAndInsuranceExpirationNotify()
            Dim sql As String
            sql = "Select Name as Contractor, InsurExpireDate as InsuranceExpires, InsurPolicyDescription as PolicyDescription "
            sql += "From Contacts "
            sql += "Where ContactType = 'Company' and DistrictID = 55 and InsuranceRequired = 1   "
            sql += "	and ((IsDate(InsurExpireDate) <> 1) or (DateDiff(day,InsurExpireDate,GetDate()) > -60)) "
            'format the message text
            Dim msg As String
            msg = "The following Contractors' Insurance is expiring within the next 60 days:" & vbCrLf & vbCrLf
            msg += "=========================================================================" & vbCrLf
            db.FillReader(sql)
            While db.Reader.Read
                msg += db.Reader("Contractor").ToString.PadRight(30) & " - "
                msg += db.Reader("PolicyDescription").ToString.PadRight(30) & "; "
                If Not IsDBNull(db.Reader("InsuranceExpires")) Then
                    msg += CType(db.Reader("InsuranceExpires").ToString, DateTime).ToString("MM/dd/yyy") & "; "
                End If
                msg += vbCrLf
            End While
            db.Reader.Close()

            SendEmail("nancyle@maasco.com,juliebernhardt@maasco.com", "Prompt Notification - Expiring Insurance", msg)
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

