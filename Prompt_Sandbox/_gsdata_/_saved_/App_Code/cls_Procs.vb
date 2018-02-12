Imports System
Imports System.IO
Imports System.Xml
Imports System.Text
Imports System.Security.Cryptography
Imports Telerik.Web.UI

Namespace Prompt

    '********************************************
    '*  Utilities Class
    '*  
    '*  Purpose: Provide shared utilites to the application for use throughout 
    '*
    '*  Last Mod By:    Ford James
    '*  Last Mod On:    07/23/10
    '*
    '********************************************

    Public Class ProcLib

        Public Shared Sub SetCustomJCAFFundingSourceName(ByRef sourcetbl As DataTable, ByVal sourcerowname As String)
            'sets the passed column values for funding source to district custom values when present

            Using db As New PromptDataHelper
                Dim tblSourceNames As DataTable = db.ExecuteDataTable("SELECT * FROM Districts WHERE DistrictID = " & HttpContext.Current.Session("DistrictID"))
                For Each row As DataRow In sourcetbl.Rows
                    For Each rowsource As DataRow In tblSourceNames.Rows
                        If Not IsDBNull(rowsource("JCAFDonationColumnName")) Then  'there is a custom label
                            If row(sourcerowname) = "Donation" Then
                                row(sourcerowname) = rowsource("JCAFDonationColumnName")
                            End If
                        End If
                        If Not IsDBNull(rowsource("JCAFGrantColumnName")) Then
                            If row(sourcerowname) = "Grant" Then
                                row(sourcerowname) = rowsource("JCAFGrantColumnName")
                            End If
                        End If
                        If Not IsDBNull(rowsource("JCAFHazmatColumnName")) Then
                            If row(sourcerowname) = "Hazmat" Then
                                row(sourcerowname) = rowsource("JCAFHazmatColumnName")
                            End If
                        End If
                        If Not IsDBNull(rowsource("JCAFMaintColumnName")) Then
                            If row(sourcerowname) = "Maint" Then
                                row(sourcerowname) = rowsource("JCAFMaintColumnName")
                            End If
                        End If
                    Next
                Next
            End Using


        End Sub


        Public Shared Function EncryptString(ByVal stext As String) As String

            'Create an encoding object to ensure the encoding standard for the source text
            Dim Ue As New UnicodeEncoding()
            'Retrieve a byte array based on the source text
            Dim ByteSourceText() As Byte = Ue.GetBytes(stext)
            'Instantiate an MD5 Provider object
            Dim Md5 As New MD5CryptoServiceProvider()
            'Compute the hash value from the source
            Dim ByteHash() As Byte = Md5.ComputeHash(ByteSourceText)
            'And convert it to String format for return
            Return Convert.ToBase64String(ByteHash)
        End Function

        Public Shared Function GenerateRandomPassword() As String
            'generates a 5 char random string
            Dim fs
            Dim strTemp
            fs = CreateObject("Scripting.FileSystemObject")
            'Get just the filename part of the temp name path 
            strTemp = fs.GetTempName
            'Hack off the 'rad' 
            strTemp = Right(strTemp, Len(strTemp) - 3)
            'Hack off the '.tmp' 
            strTemp = Left(strTemp, Len(strTemp) - 4)
            fs = Nothing

            Return strTemp & "aT8"   'make it 8 chars

        End Function

        Public Shared Function CleanText(ByVal txt As String) As String
            'remove any single quotes and ; in either the login or password screens 
            'to help protect against SQL Injection security issues.
            'the following will remove these potentially harmfull 
            'characters and just pass invalid parms to the program.

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

        Public Shared Function BuildSelectedString(ByVal lst As ListBox) As String
            'this function builds a string from a listbox's selected items delimited with ;
            'Used to hold multiseleceted items in a single database field.

            'note: references changed to reference new class

            Dim strVal As String
            strVal = ""
            Dim li
            For Each li In lst.Items()
                If li.Selected = True Then
                    strVal = strVal & ";" & li.Value & ";"
                End If
            Next
            BuildSelectedString = strVal
        End Function

        Public Shared Function BuildDistrictCollegeSelectedString(ByVal lst As ListBox, ByVal Table As String) As String
            'this function builds a string from a listbox's selected items delimited with ; - District/CollegeCombination
            'Used to hold multiseleceted items in a single database field.

            'note: references changed to reference new class

            Dim strVal As String = ""
            Dim strRtn As String = ""
            Dim li
            For Each li In lst.Items()
                If Table = "District" Then
                    strVal = Left(li.Value, InStr(li.Value, "&") - 1)  'parse out the district portion
                    'Check if already in list and if so ignore
                    If InStr(strRtn, strVal) Then
                        strVal = ""
                    End If
                Else
                    strVal = Mid(li.Value, InStr(li.Value, "&") + 1)   'parse out the College portion
                End If
                If li.Selected = True Then
                    strRtn = strRtn & strVal
                End If
            Next
            Return strRtn
        End Function

        Public Shared Function CheckNullDBField(ByVal val) As String
            If IsDBNull(val) Then
                CheckNullDBField = " "
            Else
                If TypeOf (val) Is String Then
                    Dim newval As String = val
                    newval = newval.Replace("''", "'")   'fix double apostrophe on strings
                End If
                CheckNullDBField = val
            End If
        End Function

        Public Shared Function CheckNullNumField(ByVal val) As Double
            If IsDBNull(val) Then
                Return 0
            Else
                If Trim(val) = "" Then
                    Return 0
                End If
                Return val
            End If
        End Function


        Public Shared Function CheckDateField(ByVal val)     'no type specified to allow pasing back dbnull
            If IsDate(val) Then
                Return FormatDateTime(val, DateFormat.ShortDate)
            Else
                Return DBNull.Value  'set to null
            End If
        End Function


        Public Shared Sub RefreshNav(ByVal p As Page)
            'This is used to refresh the Nav page after adding new contracts or projects (which show in the nav bar),
            'or updating some information that shows on a nav node (like contractor or description).
            'Due to the way web pages load in .net, this script has to live in the last page called, so must be called
            'after a redirect to either the calling page (in the case of an edit, the list the the item was chsen from)
            'or an an ADD (in the case of contrats, from the Add New Contract method.
            Dim jscript As New StringBuilder
            With jscript
                .Append("<script language='javascript'>")
                .Append("window.parent.frames['leftFrame'].location.reload(true)")
                .Append("</script>")
            End With

            p.ClientScript.RegisterStartupScript(GetType(String), "RefreshNav", jscript.ToString)
            p.Session("RefreshNav") = False
        End Sub
       
     


        Public Shared Sub CloseAndRefresh(ByVal p As Page)
            'Used for Popup Pages - Pass the jscript back to the page to close it and refresh the data on the calling page
            Dim jscript As New StringBuilder
            With jscript
                .Append("<script language='javascript'>")
                .Append("window.opener.document.forms[0].submit();")
                .Append("self.close();")
                .Append("</script>")
            End With

            p.ClientScript.RegisterStartupScript(GetType(String), "CloseEditWindow", jscript.ToString)
            'p.ClientScript.RegisterStartupScript(GetType(Page), "PopupClose", jscript.ToString)

        End Sub

        Public Shared Sub CloseAndRefreshNoPrompt(ByVal p As Page)
            'Used for Popup Pages - Pass the jscript back to the page to close it and refresh the data on the calling page
            Dim jscript As New StringBuilder
            With jscript
                .Append("<script language='javascript'>")
                .Append("window.opener.document.forms[0].submit();")
                .Append("self.close();")
                .Append("</script>")
            End With

            p.ClientScript.RegisterStartupScript(GetType(String), "PopupClose", jscript.ToString)

        End Sub

        Public Shared Sub CloseAndRefreshSpecific(ByVal p As Page, ByVal location As String)
            Dim jscript As New StringBuilder
            With jscript
                .Append("<script language='javascript'>")
                .Append(location)
                .Append("self.close();")
                .Append("</script>")
            End With

            p.ClientScript.RegisterStartupScript(GetType(String), "PopupClose", jscript.ToString)

        End Sub

        Public Shared Sub CloseAndRefreshWithNavRefresh(ByVal p As Page)
            Dim jscript As New StringBuilder
            With jscript
                .Append("<script language='javascript'>")
                .Append("window.opener.location.reload();")
                .Append("self.close();")
                .Append("</script>")
            End With

            p.ClientScript.RegisterStartupScript(GetType(String), "PopupClose", jscript.ToString)

        End Sub

        Public Shared Sub CloseOnly(ByVal p As Page)
            'Used for Popup Pages - Pass the jscript back to the page to close it 
            Dim jscript As New StringBuilder
            With jscript
                .Append("<script language='javascript'>")
                .Append("self.close();")
                .Append("</script>")
            End With

            p.ClientScript.RegisterStartupScript(GetType(String), "PopupClose", jscript.ToString)

        End Sub

        Public Shared Sub CloseOnlyRAD(ByVal p As Page)
            'Used for Popup Pages - Pass the jscript back to the page to close it 
            Dim jscript As New StringBuilder
            With jscript
                .Append("<script language='javascript'>")
                .Append("GetRadWindow().Close();")
                .Append("</script>")
            End With

            p.ClientScript.RegisterStartupScript(GetType(String), "RadPopupClose", jscript.ToString)

        End Sub

        Public Shared Sub CloseAndRefreshRAD(ByVal p As Page)
            'Used for Popup Pages - Pass the jscript back to the page to close it and refresh the data on the calling page
            Dim jscript As New StringBuilder
            With jscript
                .Append("<script language='javascript'>")
                .Append("GetRadWindow().BrowserWindow.location.reload();")
                .Append("GetRadWindow().Close();")
                .Append("</script>")
            End With

            p.ClientScript.RegisterStartupScript(GetType(String), "RadPopupClose", jscript.ToString)

        End Sub
        Public Shared Sub CloseAndRefreshRAD(ByVal p As Page, ByVal newlocation As String)
            'Used for Popup Pages - Pass the jscript back to the page to close it and redirect calling page to new passed page
            Dim jscript As New StringBuilder
            With jscript
                .Append("<script language='javascript'>")
                .Append("GetRadWindow().BrowserWindow.location.href = '" & newlocation & "';")
                .Append("GetRadWindow().Close();")
                .Append("</script>")
            End With

            p.ClientScript.RegisterStartupScript(GetType(String), "RadPopupClose", jscript.ToString)

        End Sub
        Public Shared Sub CloseAndRefreshRADNoPrompt(ByVal p As Page)
            'Used for Popup Pages - Pass the jscript back to the page to close it and refresh the data on the calling page
            Dim jscript As New StringBuilder
            With jscript
                .Append("<script language='javascript'>")
                .Append("GetRadWindow().BrowserWindow.location.href = GetRadWindow().BrowserWindow.location.href;")
                .Append("GetRadWindow().Close();")
                .Append("</script>")
            End With

            p.ClientScript.RegisterStartupScript(GetType(String), "RadPopupClose", jscript.ToString)

        End Sub
        Public Shared Sub CheckSession(ByVal page As Page)
            'checks if a user has a current session and if not sends to index page
            'Check to see if session is dead
            If page.Session("UserName") = "" Then
                page.Response.Redirect("index.aspx?logout=1")

            Else        'write to SessionLog table
                Using dbTarget As New PromptDataHelper
                    Dim sql As String = ""
                    sql = "Insert into SessionLog (UserName,TimeStamp,Comment) Values ('" + page.Session("UserName") + "','" + Now() + "','')"
                    dbTarget.ExecuteNonQuery(sql)
                End Using
            End If

        End Sub
        Public Shared Function CheckExpiredSessionForPopup(ByVal page As Page) As Boolean
            'checks if a user has a current session and if not returns true so calling page can close itself
            'Dim cookie As HttpCookie = page.Request.Cookies("PROMPTUser")
            'If cookie Is Nothing Or page.Session("UserName") = "" Then
            '    Return True
            'End If
            If page.Session("UserName") = "" Then
                Return True
            End If
        End Function
        Public Shared Sub LoadPopupJscript(ByVal p As Page)
            'Used for opening and centering Popup Pages 
            Dim jscript As New StringBuilder
            With jscript
                .Append("<script language='javascript'>")
                .Append("function openPopup(mypage,myname,w,h,scroll){")
                .Append("var winl = (screen.width-w)/2;")
                .Append("var wint = (screen.height-h)/2;")
                .Append("var settings  ='height='+h+',';")
                .Append("settings +='width='+w+',';")
                .Append("settings +='top='+wint+',';")
                .Append("settings +='left='+winl+',';")
                .Append("settings +='scrollbars=yes,';")
                .Append("settings +='resizable=yes';")
                .Append("win=window.open(mypage,myname,settings);")
                .Append("if(parseInt(navigator.appVersion) >= 4){win.window.focus();}")
                .Append("}")
                .Append("</script>")
            End With

            p.ClientScript.RegisterStartupScript(GetType(String), "OpenPopup", jscript.ToString)

        End Sub

        Public Shared Sub CreateMessageAlert(ByVal senderpage As System.Web.UI.Page, ByVal alertMsg As String, ByVal alertKey As String)
            'eaxmple of usage:
            'Dim alertmessage As String
            'alertmessage = "Folder is not empty. Please delete file(s) before deleting folder."
            'CreateMessageAlert(Me, alertmessage, "alertKey")

            Dim strScript As String
            strScript = "<script language=JavaScript>alert('" + alertMsg + "')</script>"
            If Not (senderpage.ClientScript.IsStartupScriptRegistered(alertKey)) Then
                senderpage.ClientScript.RegisterStartupScript(GetType(String), alertKey, strScript)
            End If
        End Sub

  
        Public Shared Function FormatFileSize(ByVal nsize As Integer) As String
            FormatFileSize = FormatNumber(nsize, 0, ) & " bytes"
            If nsize > 1000 Then
                FormatFileSize = FormatNumber(nsize / 1000, 1) & "Kb"
            End If
            If nsize > 1000000 Then
                FormatFileSize = FormatNumber(nsize / 1000000, 1) & "Mb"
            End If
        End Function


        Public Shared Function GetLocale() As String
            'Determines where the app is running and which DB to and other settings to use.
            Dim sname As String
            sname = HttpContext.Current.Request.ServerVariables("SERVER_NAME") ' capture the request object address
            sname = UCase(sname) ' convert all to upper case

            Select Case sname
                Case "LOCALHOST"    'FOR DEBUGG AND DEVELOPMENT on local machine
                    Return "Local"

                Case "PROMPTBETA.MAASCO.COM"    'FOR Beta site on prod server 
                    Return "Beta"

                Case "PROMPTBETA2.MAASCO.COM", "PROMPTBETA2.EISPRO.COM"    'FOR VMBeta 
                    Return "VMBeta"

                Case "PROMPTED.MAASCO.COM", "PROMPTED.EISPRO.COM"    'FOR VMBeta 
                    Return "VMProduction"


                Case "APPS.EISPRO.NET"    'production
                    Return "Production"


                Case Else        'host name not found
                    Return "Error"

            End Select


        End Function

        Public Shared Function GetServerFooterID() As String
            'Determines where the app is running and which DB to and other settings to use.
            Dim sname As String
            sname = HttpContext.Current.Request.ServerVariables("SERVER_NAME") ' capture the request object address
            sname = UCase(sname) ' convert all to upper case

            Select Case sname
                Case "LOCALHOST"    'FOR DEBUGG AND DEVELOPMENT on local machine
                    Return "Local"

                Case "PROMPTBETA.MAASCO.COM"    'FOR Beta site on prod server 
                    Return "Beta"


                Case "APPS.EISPRO.NET"    'production
                    Return "Production"

                Case "PROMPTBETA2.MAASCO.COM", "PROMPTBETA2.EISPRO.COM"    'VMBeta
                    Return "VMBeta"

                Case "PROMPTED.MAASCO.COM", "PROMPTED.EISPRO.COM"    'VMProduction

                    Return "VMP"

                Case Else        'host name not found
                    Return "Error"

            End Select

        End Function

        Public Shared Function GetDataConnectionString() As String
            'This functions returns the current data connection string depending on where the app is running. This is necessary to 
            'avoid having to maintain different versions of web.config for each site.

            Dim sLocal As String = GetLocale()

            Select Case sLocal
                Case "Production"    'this is production
                    GetDataConnectionString = System.Configuration.ConfigurationManager.AppSettings("ProductionConnectionString")

                Case "Beta"    'this is beat dev site on production server
                    GetDataConnectionString = System.Configuration.ConfigurationManager.AppSettings("BetaConnectionString")

                Case "VMBeta"    'this is VMBeta site 
                    GetDataConnectionString = System.Configuration.ConfigurationManager.AppSettings("VMBetaConnectionString")

                Case "VMProduction"    'this is VMBeta site 
                    GetDataConnectionString = System.Configuration.ConfigurationManager.AppSettings("VMProductionConnectionString")


                Case Else     'localhost
                    GetDataConnectionString = System.Configuration.ConfigurationManager.AppSettings(UCase(System.Environment.MachineName.ToString) + "LocalDevConnectionString")

            End Select

         
        End Function
        Public Shared Function GetCurrentAttachmentPath() As String
            'This functions returns the current physical attachment path depending on where the app is running. This is necessary to 
            'avoid having to maintain different versions of web.config for each site.

            Dim sLocal As String = GetLocale()
            Select Case sLocal
                Case "Production"    'this is production
                    GetCurrentAttachmentPath = System.Configuration.ConfigurationManager.AppSettings("ProductionAttachmentPath")
                Case "Beta"    'this is beat dev site on production server
                    GetCurrentAttachmentPath = System.Configuration.ConfigurationManager.AppSettings("BetaAttachmentPath")
                Case "VMBeta"    'this is beat dev site on production server
                    GetCurrentAttachmentPath = System.Configuration.ConfigurationManager.AppSettings("VMBetaAttachmentPath")

                Case "VMProduction"    'this is beat dev site on production server
                    GetCurrentAttachmentPath = System.Configuration.ConfigurationManager.AppSettings("VMProductionAttachmentPath")

                Case Else    'localhost
                    GetCurrentAttachmentPath = System.Configuration.ConfigurationManager.AppSettings(UCase(System.Environment.MachineName.ToString) + "LocalDevAttachmentPath")


            End Select


        End Function
        Public Shared Function GetCurrentRelativeAttachmentPath() As String
            'This functions returns the current relative attachment path depending on where the app is running. This is necessary to 
            'avoid having to maintain different versions of web.config for each site.

            Dim sLocal As String = GetLocale()
            Select Case sLocal
                Case "Production"    'this is production
                    GetCurrentRelativeAttachmentPath = System.Configuration.ConfigurationManager.AppSettings("ProductionRelativeAttachmentPath")
                Case "Beta"    'this is beat dev site on production server
                    GetCurrentRelativeAttachmentPath = System.Configuration.ConfigurationManager.AppSettings("BetaRelativeAttachmentPath")
                Case "VMBeta"    'this is beat dev site on production server
                    GetCurrentRelativeAttachmentPath = System.Configuration.ConfigurationManager.AppSettings("VMBetaRelativeAttachmentPath")

                Case "VMProduction"    'this is beat dev site on production server
                    GetCurrentRelativeAttachmentPath = System.Configuration.ConfigurationManager.AppSettings("VMProductionRelativeAttachmentPath")


                Case Else    'localhost
                    GetCurrentRelativeAttachmentPath = System.Configuration.ConfigurationManager.AppSettings(UCase(System.Environment.MachineName.ToString) + "LocalDevRelativeAttachmentPath")

            End Select
        

        End Function
        Public Shared Function GetCurrentFRSTransferPath() As String
            'This functions returns the current relative attachment path depending on where the app is running. This is necessary to 
            'avoid having to maintain different versions of web.config for each site.

            Dim sLocal As String = GetLocale()

            If sLocal = "Production" Then   'this is production
                Return System.Configuration.ConfigurationManager.AppSettings("ProductionFRSTransferDirectory")
            ElseIf sLocal = "Beta" Then   'this is beat dev site on production server
                Return System.Configuration.ConfigurationManager.AppSettings("BetaFRSTransferDirectory")
            ElseIf sLocal = "FHDAPara" Then   'this is beat dev site on production server
                Return System.Configuration.ConfigurationManager.AppSettings("FHDAParaFRSTransferDirectory")
            Else    'localhost
                Return System.Configuration.ConfigurationManager.AppSettings(UCase(System.Environment.MachineName.ToString) + "FRSTransferDirectory")
            End If

        End Function
        Public Shared Function GetCurrentReportPath() As String
            'This functions returns the report path depending on where the app is running. This is necessary to 
            'avoid having to maintain different versions of web.config for each site.

            Dim sLocal As String = GetLocale()
            Select Case sLocal
                Case "Production"    'this is production
                    GetCurrentReportPath = System.Configuration.ConfigurationManager.AppSettings("ProductionReportPath")
                Case "Beta"    'this is beat dev site on production server
                    GetCurrentReportPath = System.Configuration.ConfigurationManager.AppSettings("BetaReportPath")
                Case "FHDAPara"    'this is beat dev site on production server
                    GetCurrentReportPath = System.Configuration.ConfigurationManager.AppSettings("FHDAParaReportPath")
                Case Else   'localhost
                    GetCurrentReportPath = System.Configuration.ConfigurationManager.AppSettings(UCase(System.Environment.MachineName.ToString) + "LocalDevReportPath")

            End Select
           

        End Function

        Public Shared Sub VerifyBudgetReportingTable(ByVal nProjectID As Integer)
            'this proc makes sure that there are correct number of reporting months in the 
            'Budget REporting Table based on the start/complete dates for the project.
            'We need to account for change of start/end date and add/remove appropriate
            'entries without deleting any existing data. 

            'Called from Project Edit screen and BudgetReportingEdit screen

            ' If Start Date changes and is earlier than existing start date, then empty records are added to begining.
            ' If complete date is moved later, more records wil be added. 
            'If complete date moved earlier, extra records are deleted.

            Dim dStart As String = ""
            Dim dComplete As String = ""
            Dim dCurrReportingDate As String = ""

            Dim iMonth As Integer = 0
            Dim iYear As Integer = 0

            Using rsTarget As New PromptDataHelper
                Using rs As New PromptDataHelper

                    rs.FillReader("SELECT StartDate, EstCompleteDate FROM Projects WHERE ProjectID =" & nProjectID)
                    While rs.Reader.Read
                        dStart = CheckNullDBField(rs.Reader("StartDate"))
                        dComplete = CheckNullDBField(rs.Reader("EstCompleteDate"))
                    End While
                    rs.Reader.Close()

                    If IsDate(dStart) And IsDate(dComplete) Then   'we have valid date range so validate
                        'normalize the start and end date to the first of the prospective months
                        dStart = Month(dStart) & "/01/" & Year(dStart)
                        dComplete = Month(dComplete) & "/01/" & Year(dComplete)

                        dCurrReportingDate = dStart

                        Dim nExtraMonths As Integer = 0
                        Dim dMinDate As String = ""

                        'Check for earliest start date currently in the Budget Reporting Table 
                        'If Start Date is earlier than earliest record in table then add needed records
                        rs.FillReader("SELECT MIN(ReportingDate) AS ReportingDate FROM BudgetReporting WHERE ProjectID = " & nProjectID)

                        While rs.Reader.Read
                            dMinDate = CheckNullDBField(rs.Reader("ReportingDate"))  ' get the first date
                        End While
                        rs.Reader.Close()

                        If IsDate(dMinDate) Then
                            If CDate(dMinDate) > CDate(dStart) Then
                                'add any extra month or new records if needed
                                nExtraMonths = DateDiff(DateInterval.Month, CDate(dStart), CDate(dMinDate))
                                If nExtraMonths > 0 Then  'add records for each needed month
                                    Dim i As Integer
                                    For i = 1 To nExtraMonths
                                        Dim ssql As String
                                        ssql = "INSERT INTO BudgetReporting (ReportingDate,ProjectID) VALUES ('" & dCurrReportingDate & "'," & nProjectID & ")"
                                        rsTarget.ExecuteNonQuery(ssql)

                                        'Add a month to current reporting date
                                        dCurrReportingDate = DateAdd(DateInterval.Month, 1, CDate(dCurrReportingDate))
                                    Next
                                End If
                            End If
                        End If
                        'Now go through all the existing records and remove any outside of date range
                        rs.FillReader("SELECT * FROM BudgetReporting WHERE ProjectID = " & nProjectID & " ORDER BY ReportingDate ASC")
                        If rs.Reader.HasRows Then  'go through a remove any outside of date range
                            While rs.Reader.Read
                                Dim ssql As String
                                dCurrReportingDate = rs.Reader("ReportingDate")
                                If CDate(dCurrReportingDate) > CDate(dComplete) Or CDate(dCurrReportingDate) < CDate(dStart) Then   ' delete outside of range
                                    ssql = "DELETE FROM BudgetReporting WHERE PrimaryKey = " & rs.Reader("PrimaryKey")
                                    rsTarget.ExecuteNonQuery(ssql)
                                End If
                                dCurrReportingDate = DateAdd(DateInterval.Month, 1, CDate(dCurrReportingDate))
                            End While
                        End If
                        rs.Reader.Close()

                        'add any extra month or new records if needed
                        nExtraMonths = DateDiff(DateInterval.Month, CDate(dCurrReportingDate), CDate(dComplete))
                        If nExtraMonths > 0 Then  'add records for each needed month
                            Dim i As Integer
                            For i = 0 To nExtraMonths
                                Dim ssql As String
                                ssql = "INSERT INTO BudgetReporting (ReportingDate,ProjectID) VALUES ('" & dCurrReportingDate & "'," & nProjectID & ")"
                                rsTarget.ExecuteNonQuery(ssql)

                                'Add a month to current reporting date
                                dCurrReportingDate = DateAdd(DateInterval.Month, 1, CDate(dCurrReportingDate))
                            Next

                        End If
                    End If
                End Using
            End Using

        End Sub
        Public Shared Function Round(ByVal nValue As Double, ByVal nDigits As Integer) As Double
            'rounds a number to the specified digits
            Round = Int(nValue * (10 ^ nDigits) + 0.5) / (10 ^ nDigits)
        End Function

        Public Shared Function GetNonPooledDataConnectionString() As String
            'This functions returns the current data connection string depending on where the app is running. This is necessary to 
            'avoid having to maintain different versions of web.config for each site.

            If GetLocale() = "Production" Then   'this is production
                GetNonPooledDataConnectionString = System.Configuration.ConfigurationManager.AppSettings("ProductionNonPooledConnectionString")
            ElseIf GetLocale() = "Beta" Then   'this is beat dev site on production server
                GetNonPooledDataConnectionString = System.Configuration.ConfigurationManager.AppSettings("BetaNonPooledConnectionString")
            ElseIf GetLocale() = "FHDAPara" Then   'this is beat dev site on production server
                GetNonPooledDataConnectionString = System.Configuration.ConfigurationManager.AppSettings("FHDAParaNonPooledConnectionString")
            Else     'localhost
                GetNonPooledDataConnectionString = System.Configuration.ConfigurationManager.AppSettings(UCase(System.Environment.MachineName.ToString) + "LocalNonPooledDevConnectionString")
            End If
            GetNonPooledDataConnectionString = "Persist Security Info=False;Data Source=216.129.104.66,4549;Initial Catalog=Prompt_Beta;User ID=maasa;Password=maubi2007;Pooling=false;Connect Timeout=45;"

        End Function

    End Class
End Namespace