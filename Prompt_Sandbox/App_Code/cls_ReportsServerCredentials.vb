Imports Microsoft.VisualBasic
Imports Microsoft.Reporting.WebForms
Imports System.Security.Principal

'Notes:
'    There are several considerations when setting up SQL2008 SSRS R2 to work with reports, specifically setting the correct security
'is a pain to do so that the reports run in all the environments (local/beta/production).

'Basically, there are two security users to be concerned with:
'prompt_db_user -- this is located inside the SQL Server install and should have at least RW access to Prompt Database. 
'This is hard coded in each report variable datasource for access to the data
'SSRSReportAdmin -- this is a local user on each machine that hosts an SSRS install -- your local development machine and 
'the VMSQL server. This is used by Prompt to access the report, and can also be used when accessing the web base 
'report manager -- this user should have content rights in each SSRS install. No fancy windows rights needed, just needs to be member of the users.
'Additionally, when installing SSRS2008 R2 on a new machine, just set the NETWORKSERVICE account on each local machine as the access account for all the SQL SERVER services.

'On your Local Machine:
'SSRS2008 R2 Express Advanced can be used. This will install Reporting Services Locally. 
'There are some limitations using Report Writer 3 and deploying to this, but there are workarounds I believe.
'The SQLServer2008 R2 instance should be the Defalut Instance for your machine, not a named instance
'Set up a user in your SQL Server (not windows) called prompt_db_user. pwd is maubi2008. 
'Give rights to Prompt DBs and Report Server DB's. This is the connection user used in the variable datasource in each report.
'Create a local machine (windows) user on called SSRSReportAdmin, password Maubi2010. No special permissions needed, just needs to be a user.
'Log in to your local SSRS Report Manager. You can access the built-in Report manager in SSRS via http://localhost/Reports. Use an Administrator account when prompted.
'From the main menu of Home page of the Report Manager, click on Folder Settings (not site settings in upper left corner).
'Click New Role Assignment
'In Group or User Name text box, type SSRSReportAdmin, and give Content rights and click OK. 
'you should now be able to use this credential when accessing Report Manager in future. 
'This is also the credential that Prompt uses to pull report and change parms. User and pwd are hardcoded in ReportCredentials 
'Class in Prompt, so need to change there if you change on machines.


Public NotInheritable Class ReportServerCredentials

    'Implements IReportServerCredentials

    'Public ReadOnly Property ImpersonationUser() As WindowsIdentity Implements IReportServerCredentials.ImpersonationUser
    'Get

    'Use the default windows user.  Credentials will be
    'provided by the NetworkCredentials property.
    'Return Nothing

    'End Get
    'End Property

    'Public ReadOnly Property NetworkCredentials() As Net.ICredentials Implements IReportServerCredentials.NetworkCredentials
    'Get

    'Read the user information from the web.config file.  
    'By reading the information on demand instead of storing 
    'it, the credentials will not be stored in session, 
    'reducing the vulnerable surface area to the web.config 
    'file, which can be secured with an ACL.

    'Dim userName As String = "MaasAdmin"
    'Dim password As String = "graPe!2014"
    'Return New Net.NetworkCredential(userName, password)



    ''User name
    'Dim userName As String = ConfigurationManager.AppSettings("Administrator")

    'If (String.IsNullOrEmpty(userName)) Then
    '    Throw New Exception("Missing user name from web.config file")
    'End If

    ''Password
    'Dim password As String = _
    '    ConfigurationManager.AppSettings("Password")

    'If (String.IsNullOrEmpty(password)) Then
    '    Throw New Exception("Missing password from web.config file")
    'End If

    ''Domain
    'Dim domain As String = _
    '    ConfigurationManager.AppSettings("ServerName")

    'If (String.IsNullOrEmpty(domain)) Then
    '    Throw New Exception("Missing domain from web.config file")
    'End If

    'Return New Net.NetworkCredential(userName, password, domain)

    'End Get
    'End Property

    Public Function GetFormsCredentials(ByRef authCookie As System.Net.Cookie,
                                        ByRef userName As String,
                                        ByRef password As String,
                                        ByRef authority As String) _
                                        As Boolean _
        'Implements IReportServerCredentials.GetFormsCredentials

        authCookie = Nothing
        userName = Nothing
        password = Nothing
        authority = Nothing

        'Not using form credentials
        Return False

    End Function
End Class
