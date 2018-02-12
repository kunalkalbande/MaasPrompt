Imports System
Imports System.Web
Imports System.Web.UI.WebControls
Imports System.IO
Imports System.Data
Imports System.Data.SqlClient
Imports System.Net.Mail
Imports System.Net
Imports System.Text

Namespace Prompt

    '********************************************
    '*  Workflow Transfer Class
    '*  
    '*  Purpose: Processes data for the Workflow Trasnfer objects
    '*
    '*  Last Mod By:    Ford James
    '*  Last Mod On:    10/15/08
    '*
    '********************************************

    Public Class promptWorkflowTransfer
        Implements IDisposable

        'Properties
        Public CallingPage As Page
        Private db As PromptDataHelper

        Public Reader As SqlDataReader
        Public DataTable As DataTable

        Private ImportFileName As String = ""       'to hold disbursements file name
        Private NotifyMessage As String = ""        'to hold message to be sent to notify list after processing


        Protected _ftpRoot As String = "ftp://tidbit.fhda.edu" & "/%2f"   'SEE NOTE BELOW
        Protected _FHDA_FTPExportDir As String = "/home/maas/BannerExportToPrompt/"                 'remote location for Banner output to PROMPT (misc files and disbursements)
        Protected _FHDA_FTPImportDir As String = "/home/maas/BannerImportFromPrompt/"               'remote location for export from Prompt (AP transfer)
        Protected _userName As String = "maas"
        Protected _password As String = "7afkang1"
        Protected _ftpWebReq As FtpWebRequest
        Protected _ftpWebResp As FtpWebResponse

        'NOTE:
        'If you’re trying to access the file “ftp://somehost/somedirectory/some.filename” and you’re getting a 550 error, you need to 
        'change the Uri to “ftp://somehost/%2f/somedirectory/some.filename”
        'FtpWebRequest interprets every directory in the chain as a “CWD” command (CD in DOS terminology).  Each of these is relative 
        'to the previous location.  The first location is wherever the FTP server dumped you on logon.  A behaviour that is irritating in 
        'interactive mode is made just plain unusable as an API.  What’s worse, Microsoft have actually implemented the spec 
        'correctly (section 3.2.2 if you really care).  This basically means that FTP urls don’t work the way you expect and don’t behave 
        'in a similar way to HTTP urls.

        'So, to fix this, we need to first change to the root directory.  That, of course, means executing a “CWD /” command.  
        'Of course, since / is a special character in the URL syntax, you end up having to write “%2F” to trick the FtpWebRequest '
        'into doing the right thing.  Ultimately, the moral of this story is that FtpWebRequest and ftp URIs are the wrong 
        'model for interacting with FTP.  I can’t see that being changed anytime soon, however.


        Public Sub New()
            db = New PromptDataHelper
        End Sub

#Region "Subs and Functions"

        Private Function GetDisbursementFileListFromTidbit() As String

            'Gets all Disbursement files in FHDA Tidbit Site

            WriteLog("StartGetFTPFilelist", "", "GetDisbursementFileListFromTidbit")

            Dim list As String = ""
            Dim status As String = ""


            'Configure the request
            _ftpWebReq = WebRequest.Create(_ftpRoot + _FHDA_FTPExportDir + "FRSDISBURSEMENTS*.*")
            _ftpWebReq.Method = WebRequestMethods.Ftp.ListDirectory
            _ftpWebReq.Credentials = New NetworkCredential(_userName, _password)


            Try
                'Execute the request
                _ftpWebResp = _ftpWebReq.GetResponse()
                list = New StreamReader(_ftpWebResp.GetResponseStream()).ReadToEnd
                _ftpWebResp.Close()
                status = "Ok"
            Catch ex As Exception
                'Do error trap here
                WriteLog(ex.Message, "ERROR", "GetDisbursementFileListFromTidbit")
                status = "Failed"
            End Try

            ' strip out line feed and comma delim list
            list = list.Replace(Chr(13), ",")
            list = list.Replace(Chr(10), "")

            WriteLog("EndGetFTPFilelist", status, "GetDisbursementFileListFromTidbit")

            Return list

        End Function

        Private Function GetFHDATidbitFile(ByVal filename As String) As String

            'Gets passed file from FHDA FTP transfer site

            WriteLog("StartFTPXfer" & filename, "", "GetFHDATidbitFile")

            Dim sw As StreamWriter
            Dim status As String = ""

            'Configure the request
            _ftpWebReq = WebRequest.Create(_ftpRoot + _FHDA_FTPExportDir + filename)
            _ftpWebReq.Method = WebRequestMethods.Ftp.DownloadFile
            _ftpWebReq.Credentials = New NetworkCredential(_userName, _password)
            _ftpWebReq.UseBinary = True

            Try
                'Execute the request
                _ftpWebResp = _ftpWebReq.GetResponse()              'downloads the file

                'write the file to disk
                sw = New StreamWriter(ProcLib.GetCurrentFRSTransferPath() & filename)
                sw.Write(New StreamReader(_ftpWebResp.GetResponseStream()).ReadToEnd)
                sw.Close()

                status = _ftpWebResp.StatusDescription
                _ftpWebResp.Close()

                status = "Ok"

            Catch ex As Exception
                'Do error trap here
                If InStr(ex.Message, "(550) File unavailable ") > 0 Then  'file was not found
                    WriteLog(filename & " was not found on Tidbit Server", "ERROR", "GetFHDATidbitFile")
                Else
                    WriteLog("(" & filename & ") - " & ex.Message, "ERROR", "GetFHDATidbitFile")
                End If

                status = "Failed"
            End Try

            WriteLog("EndFTPXfer" & filename, status, "GetFHDATidbitFile")

            Return status

        End Function


        Private Function DeleteFHDATidbitFile(ByVal filename As String) As String

            'Deletes passed file from FHDA FTP transfer site

            WriteLog("StartFTPDelete-" & filename, "", "DeleteFHDATidbitFile")

            Dim status As String = ""

            'Configure the request
            _ftpWebReq = WebRequest.Create(_ftpRoot + _FHDA_FTPExportDir + filename)
            _ftpWebReq.Method = WebRequestMethods.Ftp.DeleteFile
            _ftpWebReq.Credentials = New NetworkCredential(_userName, _password)
            '_ftpWebReq.UseBinary = True
            _ftpWebReq.KeepAlive = False

            Try
                'Execute the request
                _ftpWebResp = _ftpWebReq.GetResponse()              'deletes the file

                status = _ftpWebResp.StatusDescription
                _ftpWebResp.Close()

            Catch ex As Exception
                status = "Failed"
                'Do error trap here
                WriteLog("(" & filename & ") - " & ex.Message, "ERROR", "DeleteFHDATidbitFile")

            End Try

            If status.Contains("250 Delete operation successful") Then
                status = "Ok"
            End If

            WriteLog("EndFTPDelete-" & filename, status, "DeleteFHDATidbitFile")

            Return status

        End Function

        Public Sub ImportFRSCheckMessageCodes()
            'Retrieves and Imports the check message code output from FRS FTP Tidbit account

            Dim sFileName As String = "CHECK_MSG.DAT"

            WriteLog("Begin", "", "ImportFRSCheckMessageCodes")

            Dim result As String = GetFHDATidbitFile(sFileName)           'Get the File from tidbit

            If result <> "Ok" Then    'FTP failed so exit
                WriteLog("FTPError", "", "ImportFRSCheckMessageCodes")
                Exit Sub
            End If

            'All is good, so update the database.
            WriteLog("Begin Check Msg Update", "", "ImportFRSCheckMessageCodes")
            'Open the existing table
            Dim sql As String = "SELECT * FROM FRS_CheckMessageCodes"
            Dim tbMessages As DataTable = db.ExecuteDataTable(sql)
            Dim sCode As String = ""
            Dim sDescription As String = ""
            Dim sFRSCodeList As String = ""   'stores the list of codes that exist in db but not in FRS list anymore

            'Open the imported file
            Dim sFileDumpPath As String = ProcLib.GetCurrentFRSTransferPath()
            Dim dDir As New DirectoryInfo(sFileDumpPath)
            For Each f As FileSystemInfo In dDir.GetFileSystemInfos
                If f.Name = sFileName Then   'file is there
                    Dim objReader As New StreamReader(f.FullName)
                    Dim sLine As String = objReader.ReadLine   'read the first line into the string
                    While Not sLine Is Nothing   'loop through the file till the end
                        sCode = Mid(sLine, 1, 3)
                        sFRSCodeList &= "'" & sCode & "',"
                        sDescription = Mid(sLine, 4, 65)
                        sDescription = ProcLib.CleanText(sDescription)   'take out any erroneous characters
                        Dim bFound As Boolean = False
                        For Each row As DataRow In tbMessages.Rows()
                            If row("Code") = sCode Then    'code found
                                bFound = True
                                If row("Description") <> sDescription Then   'update the description
                                    sql = "UPDATE FRS_CheckMessageCodes SET Description = '" & sDescription & "', LastUpdateOn = '" & Now() & "' WHERE PrimaryKey = " & row("PrimaryKey")
                                    Try
                                        db.ExecuteNonQuery(sql)
                                    Catch ex As Exception
                                        WriteLog(ex.Message, "ERROR", "ImportFRSCheckMessageCodes")
                                    End Try

                                End If
                                Exit For
                            End If
                        Next
                        If Not bFound Then     'needs to be added
                            sql = "INSERT INTO FRS_CheckMessageCodes (Code,Description,LastUpdateOn) VALUES('" & sCode & "','" & sDescription & "','" & Now() & "')"
                            db.ExecuteNonQuery(sql)
                        End If
                        sLine = objReader.ReadLine
                    End While
                    objReader.Close()
                    objReader.Dispose()
                    tbMessages.Dispose()

                    sFRSCodeList = Left(sFRSCodeList, Len(sFRSCodeList) - 1)  'trim off last comma
                    'Now check for any codes in db that are no longer in FRS list
                    sql = "DELETE FROM FRS_CheckMessageCodes WHERE Code NOT IN (" & sFRSCodeList & ")"
                    Try
                        db.ExecuteNonQuery(sql)
                    Catch ex As Exception
                        WriteLog(ex.Message, "ERROR", "ImportFRSCheckMessageCodes")
                    End Try

                    'rename file so it does not get processed again
                    Dim BatchID As String = Format(Now(), "MMddyyyy-hhmmss")
                    Dim sNewName As String = f.FullName & "__" & BatchID
                    Dim fNew As FileInfo = New FileInfo(f.FullName)
                    Try
                        fNew.MoveTo(sNewName)
                    Catch ex As Exception
                        WriteLog(ex.Message, "ERROR", "ImportFRSCheckMessageCodes")
                    End Try


                    Exit For
                End If




            Next
            WriteLog("End Check Msg Update", "", "ImportFRSCheckMessageCodes")

            result = DeleteFHDATidbitFile(sFileName)           'Remove from FTP site

            WriteLog("End", "", "ImportFRSCheckMessageCodes")

        End Sub

        Public Sub ImportFRSVendorFile()
            'Retrieves and Imports the Vendor output from FRS FTP Tidbit account

            Dim sFileName As String = "VENDORS.DAT"

            WriteLog("Begin", "", "ImportFRSVendorFile")

            Dim result As String = GetFHDATidbitFile(sFileName)           'Get the File from tidbit

            If result <> "Ok" Then    'FTP failed so exit
                Exit Sub
            End If

            WriteLog("Begin Vendor Update", "", "ImportFRSVendorFile")
            'All is good, so update the database.

            'Open the existing table
            Dim sql As String = "SELECT * FROM FRS_Vendors"
            Dim tbVendors As DataTable = db.ExecuteDataTable(sql)
            Dim sVendorID As String = ""
            Dim sVendorName As String = ""

            'Open the imported file
            Dim sFileDumpPath As String = ProcLib.GetCurrentFRSTransferPath()
            Dim dDir As New DirectoryInfo(sFileDumpPath)
            For Each f As FileSystemInfo In dDir.GetFileSystemInfos
                If f.Name = sFileName Then   'file is there
                    Dim objReader As New StreamReader(f.FullName)
                    Dim sLine As String = objReader.ReadLine   'read the first line into the string
                    While Not sLine Is Nothing   'loop through the file till the end
                        sVendorID = Mid(sLine, 1, 11)
                        sVendorName = Mid(sLine, 12, 30)
                        sVendorName = ProcLib.CleanText(sVendorName)   'take out any erroneous characters
                        Dim bFound As Boolean = False
                        For Each row As DataRow In tbVendors.Rows()
                            If row("VendorID") = sVendorID Then    'code found
                                bFound = True
                                If row("VendorName") <> sVendorName Then   'update the description
                                    sql = "UPDATE FRS_VENDORS SET VendorName = '" & sVendorName & "', LastUpdateOn = '" & Now() & "' WHERE PrimaryKey = " & row("PrimaryKey")
                                    Try
                                        db.ExecuteNonQuery(sql)
                                    Catch ex As Exception
                                        WriteLog(ex.Message, "ERROR", "ImportFRSVendorFile")
                                    End Try

                                End If
                                Exit For
                            End If
                        Next
                        If Not bFound Then     'needs to be added
                            sql = "INSERT INTO FRS_Vendors (VendorID,VendorName,LastUpdateOn) VALUES('" & sVendorID & "','" & sVendorName & "','" & Now() & "')"
                            Try
                                db.ExecuteNonQuery(sql)
                            Catch ex As Exception
                                WriteLog(ex.Message, "ERROR", "ImportFRSVendorFile")
                            End Try

                        End If
                        sLine = objReader.ReadLine
                    End While
                    objReader.Close()
                    objReader.Dispose()

                    tbVendors.Dispose()

                    'rename file so it does not get processed again
                    Dim BatchID As String = Format(Now(), "MMddyyyy-hhmmss")
                    Dim sNewName As String = f.FullName & "__" & BatchID
                    Dim fNew As FileInfo = New FileInfo(f.FullName)
                    Try
                        fNew.MoveTo(sNewName)

                    Catch ex As Exception
                        WriteLog(ex.Message, "ERROR", "ImportFRSVendorFile")
                    End Try


                    Exit For
                End If
            Next

            WriteLog("End Vendor Update", "", "ImportFRSVendorFile")

            result = DeleteFHDATidbitFile(sFileName)           'Remove from FTP site


            ValidateFRSVendorsAgainstContractors()


            WriteLog("End", "", "ImportFRSVendorFile")

        End Sub

        Public Sub ImportFRSPONumbersFile()
            'Retrieves and Imports the PO Numbers output from FRS FTP Tidbit account

            Dim sFileName As String = "PURCHASE_ORDERS.DAT"

            WriteLog("Begin", "", "ImportFRSPONumbersFile")

            Dim result As String = GetFHDATidbitFile(sFileName)           'Get the File from tidbit

            If result <> "Ok" Then    'FTP failed so exit
                Exit Sub
            End If

            WriteLog("Begin PO Number Update", "", "ImportFRSPONumbersFile")
            'All is good, so update the database.

            'Open the existing table
            Dim sql As String = "SELECT * FROM FRS_PONumbers"
            Dim tbPONumbers As DataTable = db.ExecuteDataTable(sql)
            Dim sPONumber As String = ""
            Dim sVendorID As String = ""

            'Open the imported file
            Dim sFileDumpPath As String = ProcLib.GetCurrentFRSTransferPath()
            Dim dDir As New DirectoryInfo(sFileDumpPath)
            For Each f As FileSystemInfo In dDir.GetFileSystemInfos
                If f.Name = sFileName Then   'file is there
                    Dim objReader As New StreamReader(f.FullName)
                    Dim sLine As String = objReader.ReadLine   'read the first line into the string
                    While Not sLine Is Nothing   'loop through the file till the end
                        sPONumber = Mid(sLine, 1, 7)
                        sVendorID = Mid(sLine, 8, 11)

                        Dim bFound As Boolean = False
                        For Each row As DataRow In tbPONumbers.Rows()
                            If row("PONumber") = sPONumber Then    'code found
                                bFound = True
                                If row("VendorID") <> sVendorID Then   'update the Vendor ID
                                    sql = "UPDATE FRS_PONumbers SET VendorID = '" & sVendorID & "', LastUpdateOn = '" & Now() & "' WHERE PrimaryKey = " & row("PrimaryKey")
                                    Try
                                        db.ExecuteNonQuery(sql)
                                    Catch ex As Exception
                                        WriteLog(ex.Message, "ERROR", "ImportFRSPONumbersFile")
                                    End Try

                                End If
                                Exit For
                            End If
                        Next
                        If Not bFound Then     'needs to be added
                            sql = "INSERT INTO FRS_PONumbers (VendorID,PONumber,LastUpdateOn) VALUES('" & sVendorID & "','" & sPONumber & "','" & Now() & "')"
                            Try
                                db.ExecuteNonQuery(sql)
                            Catch ex As Exception
                                WriteLog(ex.Message, "ERROR", "ImportFRSPONumbersFile")
                            End Try

                        End If
                        sLine = objReader.ReadLine
                    End While
                    objReader.Close()
                    objReader.Dispose()

                    tbPONumbers.Dispose()

                    'rename file so it does not get processed again
                    Dim BatchID As String = Format(Now(), "MMddyyyy-hhmmss")
                    Dim sNewName As String = f.FullName & "__" & BatchID
                    Dim fNew As FileInfo = New FileInfo(f.FullName)
                    Try
                        fNew.MoveTo(sNewName)

                    Catch ex As Exception
                        WriteLog(ex.Message, "ERROR", "ImportFRSPONumbersFile")
                    End Try


                    Exit For
                End If
            Next

            WriteLog("End PO Number Update", "", "ImportFRSPONumbersFile")

            result = DeleteFHDATidbitFile(sFileName)           'Remove from FTP site


            ValidateFRSPONumbers()

            WriteLog("End", "", "ImportFRSPONumbersFile")

        End Sub

        Public Sub ImportFRSPONumbersLineItemsFile()
            'Retrieves and Imports the PO Line Items output from FRS FTP Tidbit account

            Dim sFileName As String = "PO_LINE_ITEM.DAT"

            WriteLog("Begin", "", sFileName)

            Dim result As String = GetFHDATidbitFile(sFileName)           'Get the File from tidbit

            If result <> "Ok" Then    'FTP failed so exit
                Exit Sub
            End If

            WriteLog("Begin PO Number Line Item Update", "", sFileName)
            'All is good, so update the database.

            'Open the existing table
            Dim sql As String = "SELECT * FROM FRS_PONumbers_Lines"
            Dim tbPONumbers As DataTable = db.ExecuteDataTable(sql)

            Dim sPONumber As String = ""
            Dim sLineNumber As String = ""
            Dim sLineAccountNumber As String = ""
            Dim sLineQuantity As String = ""
            Dim sLineAmount As String = ""
            Dim sLineDescription As String = ""

            'Open the imported file
            Dim sFileDumpPath As String = ProcLib.GetCurrentFRSTransferPath()
            Dim dDir As New DirectoryInfo(sFileDumpPath)
            For Each f As FileSystemInfo In dDir.GetFileSystemInfos
                If f.Name = sFileName Then   'file is there
                    Dim objReader As New StreamReader(f.FullName)
                    Dim sLine As String = objReader.ReadLine   'read the first line into the string
                    While Not sLine Is Nothing   'loop through the file till the end
                        sPONumber = Mid(sLine, 1, 7)
                        sLineNumber = Mid(sLine, 8, 3)
                        sLineAccountNumber = Mid(sLine, 11, 10)
                        sLineQuantity = Mid(sLine, 21, 7)
                        sLineAmount = Mid(sLine, 29, 10)

                        Dim valamt = Val(sLineAmount)
                        valamt = valamt / 100
                        sLineAmount = valamt.ToString

                        sLineDescription = ProcLib.CleanText(Mid(sLine, 39, 40))

                        'If sPONumber = "G979705" Then
                        '    Dim s As String = ""  'stop
                        'End If

                        Dim bFound As Boolean = False
                        For Each row As DataRow In tbPONumbers.Rows()
                            If row("PONumber") = sPONumber And row("LineNumber") = sLineNumber Then
                                If row("LineAccountNumber") = sLineAccountNumber And row("LineQuantity") = sLineQuantity And row("LineAmount") = sLineAmount And row("LineDescription") = sLineDescription Then    'code found
                                    bFound = True
                                    'do nothing
                                Else                'something has changed
                                    bFound = True
                                    sql = "UPDATE FRS_PONumbers_Lines SET "
                                    sql &= "LineAccountNumber = '" & sLineAccountNumber & "',"
                                    sql &= "LineQuantity = '" & sLineQuantity & "',"
                                    sql &= "LineAmount = '" & sLineAmount & "',"
                                    sql &= "LineDescription = '" & sLineDescription & "',"
                                    sql &= "LastUpdateOn = '" & Now() & "' WHERE PrimaryKey = " & row("PrimaryKey")
                                    Try
                                        db.ExecuteNonQuery(sql)
                                    Catch ex As Exception
                                        WriteLog(ex.Message, "ERROR", sFileName)
                                    End Try
                                    Exit For
                                End If
                            End If
                        Next
                        If Not bFound Then     'needs to be added
                            sql = "INSERT INTO FRS_PONumbers_Lines (PONumber,LineNumber,LineAccountNumber,LineQuantity,LineAmount,LineDescription,LastUpdateOn) "
                            sql &= "VALUES('"
                            sql &= sPONumber & "','"
                            sql &= sLineNumber & "','"
                            sql &= sLineAccountNumber & "','"
                            sql &= sLineQuantity & "','"
                            sql &= sLineAmount & "','"
                            sql &= sLineDescription & "','"
                            sql &= Now() & "')"
                            Try
                                db.ExecuteNonQuery(sql)
                            Catch ex As Exception
                                WriteLog(ex.Message, "ERROR", sFileName)
                            End Try

                        End If
                        sLine = objReader.ReadLine
                    End While
                    objReader.Close()
                    objReader.Dispose()

                    tbPONumbers.Dispose()

                    'rename file so it does not get processed again
                    Dim BatchID As String = Format(Now(), "MMddyyyy-hhmmss")
                    Dim sNewName As String = f.FullName & "__" & BatchID
                    Dim fNew As FileInfo = New FileInfo(f.FullName)
                    Try
                        fNew.MoveTo(sNewName)

                    Catch ex As Exception
                        WriteLog(ex.Message, "ERROR", sFileName)
                    End Try


                    Exit For
                End If
            Next

            WriteLog("End PO Line Update", "", sFileName)

            result = DeleteFHDATidbitFile(sFileName)           'Remove from FTP site

            WriteLog("End", "", sFileName)

        End Sub

        Public Sub ImportFRSAccountNumbersFile()
            'Retrieves and Imports the Account Numbers output from FRS FTP Tidbit account

            Dim sFileName As String = "ACCOUNTS.DAT"

            WriteLog("Begin", "", "ImportFRSAccountNumbersFile")

            Dim result As String = GetFHDATidbitFile(sFileName)           'Get the File from tidbit

            If result <> "Ok" Then    'FTP failed so exit
                Exit Sub
            End If

            WriteLog("Begin Account Number Update", "", "ImportFRSAccountNumbersFile")
            'All is good, so update the database.

            'Open the existing table
            Dim sql As String = "SELECT * FROM FRS_AccountNumbers"
            Dim tbAccountNumbers As DataTable = db.ExecuteDataTable(sql)
            Dim sAccountNumber As String = ""

            'Open the imported file
            Dim sFileDumpPath As String = ProcLib.GetCurrentFRSTransferPath()
            Dim dDir As New DirectoryInfo(sFileDumpPath)
            For Each f As FileSystemInfo In dDir.GetFileSystemInfos
                If f.Name = sFileName Then   'file is there
                    Dim objReader As New StreamReader(f.FullName)
                    Dim sLine As String = objReader.ReadLine   'read the first line into the string
                    While Not sLine Is Nothing   'loop through the file till the end
                        sAccountNumber = Mid(sLine, 1, 10)

                        Dim bFound As Boolean = False
                        For Each row As DataRow In tbAccountNumbers.Rows()
                            If row("AccountNumber") = sAccountNumber Then    'code found
                                bFound = True
                                Exit For
                            End If
                        Next
                        If Not bFound Then     'needs to be added
                            sql = "INSERT INTO FRS_AccountNumbers (AccountNumber,LastUpdateOn) VALUES('" & sAccountNumber & "','" & Now() & "')"
                            Try
                                db.ExecuteNonQuery(sql)
                            Catch ex As Exception
                                WriteLog(ex.Message, "ERROR", "ImportFRSAccountNumbersFile")
                            End Try

                        End If
                        sLine = objReader.ReadLine
                    End While
                    objReader.Close()
                    objReader.Dispose()

                    tbAccountNumbers.Dispose()

                    'rename file so it does not get processed again
                    Dim BatchID As String = Format(Now(), "MMddyyyy-hhmmss")
                    Dim sNewName As String = f.FullName & "__" & BatchID
                    Dim fNew As FileInfo = New FileInfo(f.FullName)
                    Try
                        fNew.MoveTo(sNewName)

                    Catch ex As Exception
                        WriteLog(ex.Message, "ERROR", "ImportFRSAccountNumbersFile")
                    End Try


                    Exit For
                End If
            Next

            WriteLog("End Vendor Update", "", "ImportFRSAccountNumbersFile")

            result = DeleteFHDATidbitFile(sFileName)           'Remove from FTP site


            ValidateFRSAccountNumbers()


            WriteLog("End", "", "ImportFRSAccountNumbersFile")

        End Sub

        Public Sub ValidateFRSVendorsAgainstContractors()
            WriteLog("BeginValidateVendors", "", "ValidateFRSVendorsAgainstContractors")
            'This proc checks the contracts table against the FRS Vendors table to make sure no errors.
            Dim sql As String = "SELECT * FROM Contractors WHERE DistrictID = 55 AND DistrictContractorID IS NOT NULL AND DistrictContractorID <> ''"
            Dim tblContractors As DataTable = db.ExecuteDataTable(sql)

            sql = "SELECT * FROM FRS_Vendors"
            Dim tblVendors As DataTable = db.ExecuteDataTable(sql)

            For Each contractor As DataRow In tblContractors.Rows()
                Dim bFound As Boolean = False
                Dim nContrID As Integer = contractor("ContractorID")   'to hold primary key for updating
                Dim sContDistVendID As String = contractor("DistrictContractorID")

                For Each Vendor As DataRow In tblVendors.Rows()
                    Dim sVendID As String = Vendor("VendorID")

                    'strip out the V and leading zeros to see if they are the same
                    Dim nVendID As Double = sVendID.Replace("V", "")
                    Dim nContDistVendID As Double = Val(sContDistVendID.Replace("V", ""))
                    If nVendID = nContDistVendID Then   'essentially the same

                        If sVendID <> sContDistVendID Then ' number is the same but different leading zeros or something so make same
                            sql = "UPDATE Contractors SET DistrictContractorID = '" & sVendID & "' WHERE ContractorID = " & nContrID
                            Try
                                db.ExecuteNonQuery(sql)
                                WriteLog("UpdatedContractor - " & sql, "Info", "ValidateFRSVendorsAgainstContractors")
                            Catch ex As Exception
                                WriteLog(ex.Message, "ERROR", "ValidateFRSVendorsAgainstContractors")
                            End Try

                        End If

                        bFound = True
                    End If
                Next

                If Not bFound Then 'there is something in the DistrictContractorID field but it is not in the FRS Vendor Table so blank out
                    bFound = False
                    sql = "UPDATE Contractors SET DistrictContractorID = '' WHERE ContractorID = " & nContrID
                    Try
                        db.ExecuteNonQuery(sql)
                        WriteLog("UpdatedContractor - " & sql, "Info", "ValidateFRSVendorsAgainstContractors")
                    Catch ex As Exception
                        WriteLog(ex.Message, "ERROR", "ValidateFRSVendorsAgainstContractors")
                    End Try


                End If

            Next

            tblVendors.Dispose()
            tblContractors.Dispose()

            WriteLog("EndValidateVendors", "", "ValidateFRSVendorsAgainstContractors")

        End Sub

        Public Sub ValidateFRSAccountNumbers()
            'WriteLog("BeginValidateAccountNumbers", "", "ValidateFRSAccountNumbers")
            ''This proc checks the transactions table against the FRS AccountNumbers table to make sure no errors.
            'Dim sql As String = "SELECT * FROM Transactions WHERE DistrictID = 55 AND AccountNumber IS NOT NULL AND AccountNumber <> ''"
            'Dim tblTransactions As DataTable = db.ExecuteDataTable(sql)

            'sql = "SELECT * FROM FRS_AccountNumbers"
            'Dim tblAccountNumbers As DataTable = db.ExecuteDataTable(sql)

            'For Each rTrans As DataRow In tblTransactions.Rows()
            '    Dim bFound As Boolean = False
            '    Dim nTransID As Integer = rTrans("TransactionID")   'to hold primary key for updating
            '    Dim sAccountNumber As String = rTrans("AccountNumber")

            '    For Each rAcct As DataRow In tblAccountNumbers.Rows()
            '        Dim sAcctNum As String = rAcct("AccountNumber")

            '        If sAcctNum = sAccountNumber Then
            '            bFound = True
            '        End If
            '    Next

            '    If Not bFound Then
            '        WriteLog("TransID:" & nTransID & " - AccountNumber not found in FRS Reference Table", "ERROR", "ValidateFRSAccountNumbers")
            '    End If

            'Next

            'tblTransactions.Dispose()
            'tblAccountNumbers.Dispose()

            'WriteLog("EndValidateAccountNumber", "", "ValidateFRSAccountNumbers")

        End Sub

        Public Sub ValidateFRSPONumbers()
            'WriteLog("BeginValidatePONumbers", "", "ValidateFRSPONumbers")
            ''This proc checks the contracts table against the FRS PONumber table to make sure no errors.
            'Dim sql As String = "SELECT * FROM Contracts WHERE DistrictID = 55 AND BlanketPONumber IS NOT NULL AND BlanketPONumber <> ''"
            'Dim tblContracts As DataTable = db.ExecuteDataTable(sql)

            'sql = "SELECT * FROM FRS_PONumbers"
            'Dim tblPONumbers As DataTable = db.ExecuteDataTable(sql)

            'For Each rContract As DataRow In tblContracts.Rows()
            '    Dim bFound As Boolean = False
            '    Dim nID As Integer = rContract("ContractID")   'to hold primary key for updating
            '    Dim sPONumber As String = rContract("BlanketPONumber")

            '    For Each rPO As DataRow In tblPONumbers.Rows()
            '        Dim sPO As String = rPO("PONumber")

            '        If sPONumber = sPO Then
            '            bFound = True
            '            Exit For
            '        End If
            '    Next

            '    If Not bFound Then
            '        WriteLog("ContractID:" & nID & " - PONumber not found in FRS Reference Table", "ERROR", "ValidateFRSPONumbers")
            '    End If

            'Next

            'tblPONumbers.Dispose()
            'tblContracts.Dispose()

            'WriteLog("EndValidatePONumbers", "", "ValidateFRSPONumbers")

        End Sub

        Private Sub PutFHDATidbitFile(ByVal UploadFullFilename As String, ByVal filename As String)

            'Puts passed file to FHDA FTP transfer site

            WriteLog("StartFTPXfer" & filename, "", "PutFHDATidbitFile")

            Dim status As String = ""
            Dim sTargetAddress As String = _ftpRoot + _FHDA_FTPImportDir + filename

            'Configure the request
            _ftpWebReq = WebRequest.Create(sTargetAddress)
            _ftpWebReq.Method = WebRequestMethods.Ftp.UploadFile
            _ftpWebReq.Credentials = New NetworkCredential(_userName, _password)
            _ftpWebReq.UseBinary = True

            Try
                'Read the file in preparation for upload
                Dim sw As StreamWriter
                sw = New StreamWriter(_ftpWebReq.GetRequestStream())
                sw.Write(New StreamReader(UploadFullFilename).ReadToEnd)
                sw.Close()

                'Execute the request
                _ftpWebResp = _ftpWebReq.GetResponse() 'uploads the file
                status = _ftpWebResp.StatusDescription
                _ftpWebResp.Close()
            Catch ex As Exception
                'Do error trap here
                WriteLog("(" & filename & ") - " & ex.Message, "ERROR", "PutFHDATidbitFile")
                status = "Failed"
            End Try

            WriteLog("EndFTPXfer" & filename, status, "PutFHDATidbitFile")

        End Sub


        Public Sub ExportBannerTransactions()

            'Create Banner (Foothill DeAnza) fixed length export file for transaction batch

            'Make sure local transfer directory exists
            Dim PhysicalPath As String = ProcLib.GetCurrentAttachmentPath() & "DistrictID_" & HttpContext.Current.Session("DistrictID") & "\"
            PhysicalPath &= "_DistrictDataTransfer\InvoiceExport\"

            If Not Directory.Exists(PhysicalPath) Then
                Directory.CreateDirectory(PhysicalPath)
            End If

            'For now, default Account number will be pulled from parent contract rather than from contract line items

            Dim tbl As DataTable
            Dim sql As String = "SELECT dbo.Contacts.DistrictContractorID, dbo.Contracts.AccountNumber, dbo.Contracts.BlanketPONumber AS PurchaseOrderNumber, "
            sql &= "dbo.Transactions.InvoiceNumber, dbo.Transactions.InvoiceDate, dbo.Transactions.DueDate, dbo.Transactions.PayableAmount, dbo.Transactions.Code1099, "
            sql &= "dbo.Transactions.TransactionID, dbo.Transactions.CurrentWorkflowOwner, dbo.Transactions.ExportedOn, dbo.Transactions.FRSCheckMessageCode, "
            sql &= "dbo.Projects.RetentionAccountNumber, dbo.Projects.TaxLiabilityAccountNumber, dbo.Transactions.RetentionAmount, dbo.Transactions.TransType, "
            sql &= "dbo.Transactions.FRSCutSingleCheck, dbo.Transactions.FRSRetentionCheckMessageCode, dbo.Projects.DistrictRetentionVendorID, "
            sql &= "dbo.Transactions.TaxAdjustmentAmount, dbo.Transactions.POLineNumber, dbo.Contracts.ContractType "
            sql &= "FROM dbo.Transactions INNER JOIN "
            sql &= "     dbo.Contracts ON dbo.Transactions.ContractID = dbo.Contracts.ContractID INNER JOIN "
            sql &= "     dbo.Contacts ON dbo.Contracts.ContractorID = dbo.Contacts.ContactID INNER JOIN "
            sql &= "     dbo.Projects ON dbo.Transactions.ProjectID = dbo.Projects.ProjectID "
            sql &= "WHERE  CurrentWorkflowOwner = 'Ready To Transfer' "
            sql &= "ORDER BY dbo.Transactions.InvoiceDate"

            tbl = db.ExecuteDataTable(sql)

            Dim BatchID As String = Format(Now(), "yyyy-MM-dd-hhmm")
            Dim sExportFileName As String = "PROMPT_Banner_ExportBatch_" & BatchID & ".exp"   'need short name to save in DB
            Dim sFile As String = PhysicalPath & sExportFileName    'need full path for writing export file

            Dim sOutput As New StringBuilder

            Dim nLineNumber As Integer = 0

            db.FillDataTableForUpdate("SELECT * FROM DataTransfer_Banner_ExportInvoices")
            For Each row As DataRow In tbl.Rows

                'Load variables
                Dim sCreditMemo As String = ""          '-- FABINVH_CR_MEMO_IND(VARCHAR2 1), FABCHKA_CR_MEMO_IND(VARCHAR2 1)
                Dim nAmount As Double = 0

                Dim sAmount As String = ""              '-- FARINVA_APPR_AMT(NUMBER 17,2), FABCHKS_CHECK_AMT(NUMBER 17,2)

                Dim sVendorID As String = ""            '-- FABINVH_VEND_PIDM(Number 8);SPRIDEN_ID(VARCHAR2 9)
                Dim sAccountNumber As String = ""       '-- FARINVA_FUND_CODE(VARCHAR2 6), FARINVA_ORGN_CODE(VARCHAR2 6), FARINVA_ACCT_CODE(VARCHAR2 6), FARINVA_PROG_CODE(VARCHAR26)
                Dim sPONumber As String = ""            '-- FARINVA_POHD_CODE(VARCHAR2 8), FABINVH_POHD_CODE(VARCHAR2 8) 
                Dim sInvoiceNumber As String = ""       ' -- FABINVH_CODE(VARCHAR2 8) 
                Dim sInvoiceDate As String = ""         '-- FABINVH_INVOICE_DATE(DATE 9)
                Dim sDueDate As String = ""             '-- FABINVH_PMT_DUE_DATE(DATE 9)
                Dim sCode1099 As String = ""            '-- FABINVH_1099_IND(VARCHAR2 1), FABINVH_1099_ID(VARCHAR2 9)
                Dim sPromptTransID As String = ""
                'Dim sFRSCheckMsg As String = ""
                'Dim sRetAcctNum As String = ""
                'Dim sRetAmount As String = ""
                Dim sTaxAcctNum As String = ""          '-- FARINVA_ACCT_CODE(VARCHAR2 6)
                Dim sTaxAmount As String = ""           '-- FARINVA_TAX_AMT(NUMBER 17,2), FABCHKA_TAX_AMT(NUMBER 17,2)

                'Dim sCutSeparateCheck As String = ""
                'Dim s2ndFRSCheckMsg As String = ""
                'Dim sRetentionBankVendorID As String = ""
                'Dim sPOLineNumber As String = ""

                'Dim sFRSDemandCheck As String = ""



                nAmount = row("PayableAmount")
                sCreditMemo = ""
                If row("TransType") = "Credit" Then  'CM must be positive amount with C flag
                    sCreditMemo = "C"
                    If Not IsDBNull(row("PayableAmount")) Then
                        nAmount = row("PayableAmount") * -1     'must be positive number for FRS
                    End If
                End If

                'If row("ContractType") = "ICA" Or row("ContractType") = "Check Request" Then  'Flag as Demand Check --no FRS validation of PO number
                '    sFRSDemandCheck = "D"
                'End If

                nLineNumber += 1
                sVendorID = FixLength(row("DistrictContractorID").ToString, 11)                 '-- FABINVH_VEND_PIDM(Number 8)
                sAccountNumber = FixLength(row("AccountNumber").ToString, 24, "Number")         '-- FARINVA_FUND_CODE(VARCHAR2 6), FARINVA_ORGN_CODE(VARCHAR2 6), FARINVA_ACCT_CODE(VARCHAR2 6), FARINVA_PROG_CODE(VARCHAR26)
                sPONumber = FixLength(row("PurchaseOrderNumber").ToString, 8)                   '-- FARINVA_POHD_CODE(VARCHAR2 8)
                sInvoiceNumber = FixLength(Trim(row("InvoiceNumber").ToString), 8)              ' -- FABINVH_CODE(VARCHAR2 8) 
                sInvoiceDate = FixLength(Format(row("InvoiceDate"), "MMddyyyy"), 9)             '-- FABINVH_INVOICE_DATE(DATE 9)
                sDueDate = FixLength(Format(row("DueDate"), "MMddyyyy"), 9)                     '-- FABINVH_PMT_DUE_DATE(DATE 9)
                sAmount = FixLength(nAmount, 17, "Currency")                                    '-- FARINVA_APPR_AMT(NUMBER 17,2), FABCHKS_CHECK_AMT(NUMBER 17,2)
                sCode1099 = FixLength(row("Code1099").ToString, 1)                              '-- FABINVH_1099_IND(VARCHAR2 1), FABINVH_1099_ID(VARCHAR2 9)
                sPromptTransID = FixLength(row("TransactionID").ToString, 10, "Number")
                'sFRSCheckMsg = FixLength(row("FRSCheckMessageCode").ToString, 3)
                sCreditMemo = FixLength(sCreditMemo, 1)
                'sRetAcctNum = FixLength(row("RetentionAccountNumber").ToString, 10, "Number")
                'sRetAmount = FixLength(row("RetentionAmount").ToString, 11, "Currency")
                sTaxAcctNum = FixLength(row("TaxLiabilityAccountNumber").ToString, 6, "Number")    '-- FARINVA_ACCT_CODE(VARCHAR2 6)
                sTaxAmount = FixLength(IIf(IsDBNull(row("TaxAdjustmentAmount")), "", row("TaxAdjustmentAmount").ToString), 17, "Currency") '-- FARINVA_TAX_AMT(NUMBER 17,2), FABCHKA_TAX_AMT(NUMBER 17,2)

                'sCutSeparateCheck = FixLength(row("FRSCutSingleCheck").ToString, 1)
                's2ndFRSCheckMsg = FixLength(row("FRSRetentionCheckMessageCode").ToString, 3)
                ' sRetentionBankVendorID = FixLength(row("DistrictRetentionVendorID").ToString, 11)
                ' sPOLineNumber = FixLength(row("POLineNumber").ToString, 3, "Number")

                With sOutput
                    .Append(sVendorID)
                    .Append(sAccountNumber)
                    .Append(sPONumber)
                    .Append(sInvoiceNumber)
                    .Append(sInvoiceDate)
                    .Append(sDueDate)
                    .Append(sAmount)
                    .Append(sCode1099)
                    .Append(sCreditMemo)
                    .Append(sTaxAcctNum)
                    .Append(sTaxAmount)
                    .Append(sPromptTransID)

                    '.Append(sCutSeparateCheck)
                    '.Append(s2ndFRSCheckMsg)
                    '.Append(sRetentionBankVendorID)
                    ' .Append(sPOLineNumber)
                    '.Append(sFRSCheckMsg)
                    '.Append(sFRSDemandCheck)
                    '.Append(sRetAcctNum)
                    '.Append(sRetAmount)
                End With

                sOutput.Append(Environment.NewLine)

                'Write to PromptExport Table

                Dim newrow As DataRow = db.DataTable.NewRow
                newrow("DateExported") = Now()
                newrow("LineNumber") = nLineNumber
                newrow("DistrictVendorID") = sVendorID
                newrow("AccountNumber") = sAccountNumber
                newrow("PONumber") = Trim(sPONumber)
                newrow("InvoiceNumber") = Trim(sInvoiceNumber)
                newrow("InvoiceDate") = sInvoiceDate
                newrow("DueDate") = sDueDate
                newrow("Amount") = sAmount
                newrow("CreditMemo") = sCreditMemo
                newrow("Code1099") = sCode1099
                newrow("PromptTransactionID") = row("TransactionID")
                newrow("PromptStringTransactionID") = sPromptTransID
                newrow("TaxLiabilityAccountNumber") = sTaxAcctNum
                newrow("TaxAdjustmentAmount") = sTaxAmount

                newrow("ExportFileName") = sExportFileName

                db.DataTable.Rows.Add(newrow)
            Next
            db.SaveDataTableToDB()


            'write to flat file
            Dim fs As New FileStream(sFile, FileMode.Create, FileAccess.Write)
            Dim sw As New StreamWriter(fs)
            sw.Write(sOutput.ToString())
            sw.Close()

            tbl.Dispose()


            ''Updates the transactions with new status
            'Using wrk As New promptWorkflow

            '    wrk.Target = "District For Payment"
            '    wrk.Action = "DistrctForPayment"
            '    'Get the current batch and write a workflow log entry
            '    sql = "SELECT TransactionID FROM Transactions WHERE CurrentWorkflowOwner = 'Ready To Transfer' AND DistrictID = " & HttpContext.Current.Session("DistrictID")
            '    Dim rs As DataTable = db.ExecuteDataTable(sql)
            '    For Each row As DataRow In rs.Rows()
            '        wrk.TransactionID = row("TransactionID")
            '        wrk.RouteTransaction()
            '    Next
            '    rs.Dispose()
            'End Using

            'Post the export file to the FHDA Tidbit site
            PutFHDATidbitFile(sFile, sExportFileName)

            'Notify tech suppor that file has been transferred
            'Using email As New promptEmailNotify
            '    email.SendEmail("techsupport", "FHDA Prompt Invoice Export Posted to Tidbit", "FHDA AP has posted an Invoice Export file to Tidbit")
            'End Using


        End Sub


        'Public Sub ExportFRSTransactions()

        '    'Create FRS (Foothill DeAnza) fixed length export file for transaction batch

        '    Dim tbl As DataTable
        '    Dim sql As String = "SELECT * FROM qry_GetFRSPaymentTransactionsForExport WHERE CurrentWorkflowOwner = 'Ready To Transfer'"
        '    tbl = db.ExecuteDataTable(sql)

        '    Dim BatchID As String = Format(Now(), "MM-dd-yyyy-hh-mm")
        '    Dim sExportFileName As String = "PROMPT_FRS_ExportBatch_" & BatchID & ".exp"   'need short name to save in DB
        '    Dim sFile As String = Proclib.GetCurrentFRSTransferPath() & sExportFileName    'need full path for writing export file

        '    Dim sOutput As New StringBuilder

        '    Dim nLineNumber As Integer = 0

        '    For Each row As DataRow In tbl.Rows

        '        'Load variables
        '        Dim sCreditMemo As String = ""
        '        Dim nAmount As Double = 0

        '        Dim sAmount As String = ""

        '        Dim sVendorID As String = ""
        '        Dim sAccountNumber As String = ""
        '        Dim sPONumber As String = ""
        '        Dim sInvoiceNumber As String = ""
        '        Dim sInvoiceDate As String = ""
        '        Dim sDueDate As String = ""
        '        Dim sCode1099 As String = ""
        '        Dim sFRSPromptTransID As String = ""
        '        Dim sFRSCheckMsg As String = ""
        '        Dim sRetAcctNum As String = ""
        '        Dim sRetAmount As String = ""
        '        Dim sTaxAcctNum As String = ""
        '        Dim sTaxAmount As String = ""

        '        Dim sCutSeparateCheck As String = ""
        '        Dim s2ndFRSCheckMsg As String = ""
        '        Dim sRetentionBankVendorID As String = ""
        '        Dim sPOLineNumber As String = ""

        '        Dim sFRSDemandCheck As String = ""



        '        nAmount = row("PayableAmount")
        '        sCreditMemo = ""
        '        If row("TransType") = "Credit" Then  'CM must be positive amount with C flag
        '            sCreditMemo = "C"
        '            If Not IsDBNull(row("PayableAmount")) Then
        '                nAmount = row("PayableAmount") * -1     'must be positive number for FRS
        '            End If
        '        End If

        '        If row("ContractType") = "ICA" Or row("ContractType") = "Check Request" Then  'Flag as Demand Check --no FRS validation of PO number
        '            sFRSDemandCheck = "D"
        '        End If

        '        nLineNumber += 1
        '        sVendorID = FixLength(row("DistrictContractorID").ToString, 11)
        '        sAccountNumber = FixLength(row("AccountNumber").ToString, 10, "Number")
        '        sPONumber = FixLength(row("PurchaseOrderNumber").ToString, 7)
        '        sInvoiceNumber = FixLength(Trim(row("InvoiceNumber").ToString), 10)
        '        sInvoiceDate = FixLength(Format(row("InvoiceDate"), "MMddyyyy"), 8)
        '        sDueDate = FixLength(Format(row("DueDate"), "MMddyyyy"), 8)
        '        sAmount = FixLength(nAmount, 11, "Currency")
        '        sCode1099 = FixLength(row("Code1099").ToString, 1)
        '        sFRSPromptTransID = FixLength(row("TransactionID").ToString, 10, "Number")
        '        sFRSCheckMsg = FixLength(row("FRSCheckMessageCode").ToString, 3)
        '        sCreditMemo = FixLength(sCreditMemo, 1)
        '        sRetAcctNum = FixLength(row("RetentionAccountNumber").ToString, 10, "Number")
        '        sRetAmount = FixLength(row("RetentionAmount").ToString, 11, "Currency")
        '        sTaxAcctNum = FixLength(row("TaxLiabilityAccountNumber").ToString, 10, "Number")
        '        sTaxAmount = FixLength(IIf(IsDBNull(row("TaxAdjustmentAmount")), "", row("TaxAdjustmentAmount").ToString), 11, "Currency")

        '        sCutSeparateCheck = FixLength(row("FRSCutSingleCheck").ToString, 1)
        '        s2ndFRSCheckMsg = FixLength(row("FRSRetentionCheckMessageCode").ToString, 3)
        '        sRetentionBankVendorID = FixLength(row("DistrictRetentionVendorID").ToString, 11)
        '        sPOLineNumber = FixLength(row("POLineNumber").ToString, 3, "Number")

        '        With sOutput
        '            .Append(sVendorID)
        '            .Append(Space(7))   'place holder for FRS system
        '            .Append(sAccountNumber)
        '            .Append(sPONumber)
        '            .Append(sInvoiceNumber)
        '            .Append(sInvoiceDate)
        '            .Append(sDueDate)
        '            .Append(sAmount)
        '            .Append(sCode1099)
        '            .Append(sFRSPromptTransID)
        '            .Append(sFRSCheckMsg)

        '            .Append(sCreditMemo)

        '            .Append(sRetAcctNum)
        '            .Append(sRetAmount)
        '            .Append(sTaxAcctNum)
        '            .Append(sTaxAmount)

        '            .Append(sCutSeparateCheck)
        '            .Append(s2ndFRSCheckMsg)
        '            .Append(sRetentionBankVendorID)
        '            .Append(sPOLineNumber)

        '            .Append(sFRSDemandCheck)

        '        End With

        '        sOutput.Append(Environment.NewLine)

        '        'Write to PromptVoucherlog Table
        '        Dim sqllog As New StringBuilder
        '        With sqllog
        '            .Append("INSERT INTO FRS_ExportVoucherRecords (")
        '            .Append("DateExportedToFRS,")
        '            .Append("LineNumber,")
        '            .Append("DistrictVendorID,")
        '            .Append("AccountNumber,")
        '            .Append("PONumber,")
        '            .Append("InvoiceNumber,")
        '            .Append("InvoiceDate,")
        '            .Append("DueDate,")
        '            .Append("Amount,")
        '            .Append("CreditMemo,")
        '            .Append("Code1099,")
        '            .Append("PromptTransactionID,")
        '            .Append("FRSPromptTransactionID,")
        '            .Append("FRSCheckMessageCode,")
        '            .Append("RetentionAccountNumber,")
        '            .Append("RetentionAmount,")
        '            .Append("TaxLiabilityAccountNumber,")
        '            .Append("TaxAdjustmentAmount,")

        '            .Append("CutSeparateCheck,")
        '            .Append("OtherCheckMessage,")
        '            .Append("RetentionBankVendorID,")
        '            .Append("POLineNumber,")

        '            .Append("FRSDemandCheck,")

        '            .Append("ExportFileName ")

        '            .Append(")")
        '            .Append("VALUES(")

        '            .Append("'" & Now() & "',")
        '            .Append(nLineNumber & ",")
        '            .Append("'" + sVendorID + "',")
        '            .Append("'" + sAccountNumber + "',")
        '            .Append("'" + sPONumber + "',")
        '            .Append("'" + sInvoiceNumber + "',")
        '            .Append("'" + sInvoiceDate + "',")
        '            .Append("'" + sDueDate + "',")
        '            .Append("'" + sAmount + "',")
        '            .Append("'" + sCreditMemo + "',")
        '            .Append("'" + sCode1099 + "',")

        '            .Append(row("TransactionID") & ",")
        '            .Append("'" + sFRSPromptTransID + "',")

        '            .Append("'" + sFRSCheckMsg + "',")

        '            .Append("'" + sRetAcctNum + "',")
        '            .Append("'" + sRetAmount + "',")
        '            .Append("'" + sTaxAcctNum + "',")
        '            .Append("'" + sTaxAmount + "',")

        '            .Append("'" + sCutSeparateCheck + "',")
        '            .Append("'" + s2ndFRSCheckMsg + "',")
        '            .Append("'" + sRetentionBankVendorID + "',")
        '            .Append("'" + sPOLineNumber + "',")

        '            .Append("'" + sFRSDemandCheck + "',")

        '            .Append("'" + sExportFileName + "'")

        '            .Append(")")

        '        End With

        '        db.ExecuteNonQuery(sqllog.ToString())
        '    Next

        '    Dim fs As New FileStream(sFile, FileMode.Create, FileAccess.Write)
        '    Dim sw As New StreamWriter(fs)
        '    sw.Write(sOutput.ToString())
        '    sw.Close()

        '    tbl.Dispose()


        '    'Updates the transactions with new status
        '    Using wrk As New promptWorkflow

        '        wrk.Target = "FRS for Processing"
        '        wrk.Action = "TransferToFRS"
        '        'Get the current batch and write a workflow log entry
        '        sql = "SELECT TransactionID FROM Transactions WHERE CurrentWorkflowOwner = 'Ready To Transfer' AND DistrictID = " & HttpContext.Current.Session("DistrictID")
        '        Dim rs As DataTable = db.ExecuteDataTable(sql)
        '        For Each row As DataRow In rs.Rows()
        '            wrk.TransactionID = row("TransactionID")
        '            wrk.RouteTransaction()
        '        Next
        '        rs.Dispose()
        '    End Using

        '    'Post the export file to the FHDA Tidbit site
        '    PutFHDATidbitFile(sFile, sExportFileName)

        '    'Notify tech suppor that file has been transferred
        '    Using email As New promptEmailNotify
        '        email.SendEmail("techsupport", "FHDA Disbursment Posted to Tidbit", "FHDA AP has posted a disbursements file to Tidbit")
        '    End Using


        'End Sub


        Private Sub WriteLog(ByVal msg As String, ByVal Status As String, ByVal Source As String, Optional ByVal TransID As Integer = 0)
            If TransID > 0 Then
                msg &= GetTransactionInfo(TransID)    'add the transaction info
            End If

            'remove erroneous char
            msg = msg.Replace("'", "")

            Dim sDistrictID As String = HttpContext.Current.Session("DistrictID")   'for cases when called from scheduled task
            If sDistrictID = "" Then sDistrictID = 99

            'writes an entry to the Transfer Log
            Dim sql As String = "INSERT INTO DataTransfer_Log (DistrictID,LogDate,LogNotes,ImportFileName,TransactionID,Status,Source) "
            sql &= "VALUES(" & sDistrictID & ",'" & Now & "','" & msg & "','" & ImportFileName & "'," & TransID & ",'" & Status & "','" & Source & "')"
            db.ExecuteNonQuery(sql)

        End Sub

        Private Function GetTransactionInfo(ByVal TransactionID) As String

            If Not IsNumeric(TransactionID) Then
                TransactionID = 0
            End If

            'Get the transaction info to include
            Dim sql As String = "SELECT Colleges.College, Projects.ProjectName, dbo.Contractors.Name AS Contractor, "
            sql &= "Contracts.Description AS Contract, Transactions.InvoiceNumber, Transactions.InvoiceDate, Transactions.TotalAmount, dbo.Transactions.TransactionID "
            sql &= "FROM dbo.Colleges INNER JOIN "
            sql &= "dbo.Transactions INNER JOIN "
            sql &= "dbo.Contracts ON dbo.Transactions.ContractID = dbo.Contracts.ContractID INNER JOIN "
            sql &= "dbo.Contractors ON dbo.Contracts.ContractorID = dbo.Contractors.ContractorID INNER JOIN "
            sql &= "dbo.Projects ON dbo.Contracts.ProjectID = dbo.Projects.ProjectID ON dbo.Colleges.CollegeID = dbo.Projects.CollegeID "
            sql &= "WHERE TransactionID = " & TransactionID
            Dim rs As SqlDataReader = db.ExecuteReader(sql)

            Dim sPromptInfo As String = "PROMPT Transaction Info:" & "<br/>"
            If rs.HasRows = False Then
                sPromptInfo &= "No PROMPT Transaction found with ID " & TransactionID & "." & "<br/>"
            Else
                While rs.Read
                    'build message
                    sPromptInfo &= "College:" & rs("College") & "<br/>"
                    sPromptInfo &= "Project:" & rs("ProjectName") & "<br/>"
                    sPromptInfo &= "Contractor:" & rs("Contractor") & "<br/>"
                    sPromptInfo &= "Contract:" & rs("Contract") & "<br/>"
                    sPromptInfo &= "Invoice#:" & rs("InvoiceNumber") & "<br/>"
                    sPromptInfo &= "Invoice Date:" & rs("InvoiceDate") & "<br/>"
                    sPromptInfo &= "Total Amount:" & FormatCurrency(rs("TotalAmount")) & "<br/>"
                End While
            End If
            rs.Close()

            Return sPromptInfo

        End Function


        Public Function GetTransactionImportLog(ByVal sdate As String) As DataTable

            Dim sql As String = "Select *, CONVERT(varchar, LogDate, 101) AS RunDate FROM FRS_ImportLog "
            sql &= "WHERE CONVERT(varchar, LogDate, 101) = '" & sdate & "' "

            Return db.ExecuteDataTable(sql)

        End Function
        Public Function GetFRSTransactionImportDates() As DataTable

            'note: will not quite get list right when spanning years - needs tweaking but good enough for now
            Dim sql As String = " SELECT CONVERT(varchar(10), LogDate, 101) AS Rundate "
            sql &= "FROM FRS_ImportLog GROUP BY CONVERT(varchar(10), LogDate, 101) ORDER BY Rundate DESC"

            Return db.ExecuteDataTable(sql)

        End Function


        Private Sub ParseFRSDisbursementRecord(ByVal rec As String, ByVal sLogFileName As String, ByVal LineNumber As Integer)
            'Takes the rec info provided and updates PROMPT with values

            Dim bError As Boolean = False
            Dim sErrorStatus As String = ""
            NotifyMessage = ""

            Dim sFRSProcessedDate As String = Mid(sLogFileName, 17, 8)
            sFRSProcessedDate = Left(sFRSProcessedDate, 2) & "/" & Mid(sFRSProcessedDate, 3, 2) & "/" & Right(sFRSProcessedDate, 4)

            Dim sTransactionID As String = Mid(rec, 114, 10)  'This is the FRS PROMPT transaction ID
            Dim nPromptTransactionID As Integer = 0      ' this is the int version of the FRS PROMPT Transaction ID
            If IsNumeric(sTransactionID) Then
                nPromptTransactionID = sTransactionID
            End If

            Dim sAccount As String = Mid(rec, 4, 10)
            Dim sPONumber As String = Mid(rec, 14, 7)

            Dim sDate As String = Mid(rec, 21, 4)
            sDate = Left(sDate, 2) & "/" & Mid(sDate, 3) & "/" & Year(Now())

            Dim sPayee As String = Mid(rec, 25, 20)
            'Fix any erroneous chars
            sPayee = sPayee.Replace("'", "")
            sPayee = sPayee.Replace(";", "")


            Dim sAmount As String = Mid(rec, 45, 11)

            'Get credit memo if present
            Dim sCreditMemo As String = Mid(rec, 56, 1)

            Dim sCheckNum As String = Mid(rec, 57, 6)
            'Dim sInvoiceNumber As String = Mid(rec, 74, 10)
            Dim sVendorID As String = Mid(rec, 74, 11)
            Dim nTransID As Integer = CInt(sTransactionID)

            Dim nAmount As Double = CDbl(sAmount) / 100
            sAmount = FormatCurrency(nAmount)


            Dim sFRSInfo As String = "FRS Voucher Info:" & "<br/>"
            sFRSInfo &= "Date: " & sDate & "<br/>"
            sFRSInfo &= "Payee: " & sPayee & "<br/>"
            sFRSInfo &= "FRS Check#: " & sCheckNum & "<br/>"
            sFRSInfo &= "VendorID: " & sVendorID & "<br/>"
            sFRSInfo &= "Amount: " & sAmount & "<br/>"

            If Trim(sTransactionID) = "" Then   'bad transaction number in voucher file
                NotifyMessage = "PROMPT/FRS Error: Record in FRS Voucher file missing PROMPT Transaction ID. " & "<br/>" & "Data:" & rec & "<br/>" & sFRSInfo
                sErrorStatus = "SysError"
                WriteLog(NotifyMessage, sErrorStatus, "FRSDisbursements")
            Else

                'Get the transaction records for update
                db.FillDataTableForUpdate("SELECT * FROM Transactions WHERE TransactionID = " & nTransID)

                If db.DataTable.Rows.Count = 0 Then     'transaction ID not found
                    NotifyMessage = "PROMPT/FRS Error: FRS Disbursement Transaction Not Found. <br/> FRS Payment Voucher was generated, but no matching "
                    NotifyMessage &= "PROMPT Transaction with TransactionID = " & sTransactionID & " was found." & "<br/>"
                    NotifyMessage &= sFRSInfo

                    sErrorStatus = "SysError"

                Else            'we have a transaction so validate

                    Dim targetRec As DataRow = db.DataTable.Rows(0)
                    If targetRec("Status") <> "Payment Pending" Then
                        NotifyMessage = "PROMPT/FRS Error: Transaction (" & nTransID & ") Status in Prompt not equal "
                        NotifyMessage &= "Payment Pending for FRS Batch Processed Transaction.<br/> An FRS Payment Voucher was generated, but "
                        NotifyMessage &= "PROMPT shows the Status for this Transaction as " & targetRec("Status") & "." & "<br/>"
                        NotifyMessage &= sFRSInfo & vbCrLf

                        sErrorStatus = "Error"

                    End If

                    'Need to adjust compare amount in case of Credit Memo as all amounts from FRS come back as unsigned
                    If sCreditMemo = "C" Then
                        nAmount = nAmount * -1
                    End If

                    If targetRec("PayableAmount") <> nAmount Then
                        NotifyMessage = "WARNING: Transaction (" & nTransID & ") Payable Amount in Prompt (" & targetRec("PayableAmount") & ") not equal "
                        NotifyMessage &= "to amount paid with FRS Voucher."
                        NotifyMessage &= sFRSInfo & "<br/>"

                        sErrorStatus = "Warning"

                    End If

                    If NotifyMessage = "" Then  'update the record
                        Dim sDescription As String = ""

                        With targetRec
                            .Item("Status") = "Paid"
                            .Item("CurrentWorkflowOwner") = "Complete"
                            .Item("PreviousWorkflowRoleID") = .Item("CurrentWorkflowRoleID")
                            .Item("CheckNumber") = sCheckNum
                            .Item("DatePaid") = sDate
                            .Item("LastWorkflowAction") = "PaidByFRS"
                            .Item("LastWorkflowActionOn") = Now()
                            .Item("LastUpdateBy") = "FRSDisbursementsImport"
                            .Item("LastUpdateOn") = Now()
                        End With
                        NotifyMessage = "Transaction ID " & nTransID & " Updated Succesfully."
                        sErrorStatus = "Ok"
                        WriteLog(NotifyMessage, sErrorStatus, "FRSDisbursements", nTransID)
                        NotifyMessage = ""

                        Try
                            db.SaveDataTableToDB()
                        Catch ex As Exception
                            WriteLog(ex.Message, "ERROR", "UpdateTransWithDisbursement")
                        End Try


                        'Write entry in workflow log
                        Using dbWk As New promptWorkflow
                            dbWk.AddWorkflowEntry(nTransID, "Paid by FRS", sFRSInfo)
                        End Using

                    End If
                End If


                If NotifyMessage <> "" Then   'there is an error so notify and flag appropriately
                    WriteLog(NotifyMessage, sErrorStatus, "FRSDisbursements", nTransID)

                    'Flag the transaction
                    Using flag As New promptFlag
                        flag.FlagTransactionFromWorkflowRejection(nTransID, NotifyMessage)
                    End Using

                    'Add a workflow history record
                    Using wrk As New promptWorkflow
                        wrk.AddWorkflowEntry(nTransID, "FRS Disbursement Error", NotifyMessage)
                    End Using

                End If
            End If

            'Write the parsed record to log table
            Dim sql As New StringBuilder
            With sql
                .Append("INSERT INTO FRS_DisbursementRecords (")
                .Append("DateFRSProcessed,")
                .Append("DatePromptProcessed,")
                .Append("LineNumber,")
                .Append("FRSPromptTransactionID,")
                .Append("PromptTransactionID,")
                .Append("AccountNumber,")
                .Append("PONumber,")
                .Append("DisbursementDate,")
                .Append("Payee,")
                .Append("Amount,")
                .Append("CreditMemo,")
                .Append("CheckNumber,")
                ' .Append("InvoiceNumber,")
                .Append("DistrictVendorID,")
                .Append("ProcessingResult,")
                .Append("ProcessingStatus,")
                .Append("LogFileName) ")

                .Append("VALUES(")

                .Append("'" + sFRSProcessedDate + "',")
                .Append("'" + Now() + "',")
                .Append("'" & LineNumber & "',")
                .Append("'" + sTransactionID + "',")
                .Append(nPromptTransactionID & ",")
                .Append("'" + sAccount + "',")
                .Append("'" + sPONumber + "',")
                .Append("'" + sDate + "',")
                .Append("'" + sPayee + "',")
                .Append("'" + sAmount + "',")
                .Append("'" + sCreditMemo + "',")
                .Append("'" + sCheckNum + "',")
                ' .Append("'" + sInvoiceNumber + "',")
                .Append("'" + sVendorID + "',")
                Dim sProcessingStatus As String = "Okay"
                If NotifyMessage <> "" Then
                    NotifyMessage = NotifyMessage.Replace(vbCrLf, "<br>") 'format for html display
                    sProcessingStatus = "Error"
                Else
                    NotifyMessage = "Okay"
                End If
                .Append("'" + NotifyMessage + "',")
                .Append("'" + sProcessingStatus + "',")
                .Append("'" + sLogFileName + "'")

                .Append(")")

            End With

            Try
                db.ExecuteNonQuery(sql.ToString())
            Catch ex As Exception
                WriteLog(ex.Message, "ERROR", "WriteDisbursementRecords")
            End Try



        End Sub

        Private Sub ParseFRSDisbursementLogRecord(ByVal rec As String, ByVal sLogFileName As String, ByVal LineNumber As Integer)

            'The log file will have only errors from FRS

            If Len(rec) < 4 Then 'dead record so skip
                Exit Sub
            End If

            'Takes the rec info provided and updates PROMPT with values
            Dim sTransactionID As String = Mid(rec, 1, 12)
            Dim nPromptTransactionID As Integer = 0      ' this is the int version of the FRS PROMPT Transaction ID
            If IsNumeric(sTransactionID) Then
                nPromptTransactionID = sTransactionID
            End If


            Dim sErrorMsg As String = Trim(Mid(rec, 13))

            Dim sFRSProcessedDate As String = Mid(sLogFileName, 17, 8)
            sFRSProcessedDate = Left(sFRSProcessedDate, 2) & "/" & Mid(sFRSProcessedDate, 3, 2) & "/" & Right(sFRSProcessedDate, 4)


            If Trim(sTransactionID) = "" Then   'bad transaction number in voucher file

                NotifyMessage = "ERROR: Record in FRS Voucher Log file missing PROMPT Transaction ID. " & "<br/>" & "Data:" & rec
                WriteLog(NotifyMessage, "Error", "FRSLog")


            Else

                NotifyMessage = "Rejected By FRS: Transaction (" & sTransactionID & ") -- " & sErrorMsg & "<br/>"
                WriteLog(NotifyMessage, "Error", "FRSLog", sTransactionID)

                'Flag the transaction
                Using flag As New promptFlag
                    flag.FlagTransactionFromWorkflowRejection(sTransactionID, NotifyMessage)
                End Using

                'Route back to Ellen and Write entry in workflow log
                Using dbWk As New promptWorkflow
                    dbWk.RejectTransactionFromFRS(sTransactionID, NotifyMessage)
                End Using

            End If

            'Write the parsed record to log table
            Dim sql As New StringBuilder
            With sql
                .Append("INSERT INTO FRS_DisbursementErrorLogs (")
                .Append("DateFRSProcessed,")
                .Append("DatePromptProcessed,")
                .Append("LineNumber,")
                .Append("FRSPromptTransactionID,")
                .Append("PromptTransactionID,")
                .Append("FRSErrorMessage,")
                .Append("LogFileName) ")

                .Append("VALUES(")

                .Append("'" + sFRSProcessedDate + "',")
                .Append("'" + Now() + "',")
                .Append("'" & LineNumber & "',")
                .Append("'" + sTransactionID + "',")
                .Append(nPromptTransactionID & ",")
                .Append("'" + sErrorMsg + "',")
                .Append("'" + sLogFileName + "'")

                .Append(")")

            End With

            Try
                db.ExecuteNonQuery(sql.ToString())
            Catch ex As Exception
                WriteLog(ex.Message, "ERROR", "WriteDisbursementErrorLog")
            End Try


        End Sub

        Public Sub ImportFRSPaymentDisbursements()
            'Retrieves and Imports the Disbursements files from FRS FTP Tidbit account and processes

            WriteLog("Begin", "", "ImportFRSPaymentDisbursements")

            Dim list As String = GetDisbursementFileListFromTidbit()

            Dim aList() As String = list.Split(",")

            'Download all the files
            For Each sfile As String In aList
                sfile = Trim(sfile)
                If sfile <> "" Then
                    Dim result As String = GetFHDATidbitFile(sfile)           'Get the Files from tidbit

                    If result <> "Ok" Then    'FTP failed so exit
                        WriteLog("FTPError - " & sfile, "", "ImportFRSPaymentDisbursements")
                    Else
                        'xfer was okay so remove from tidbit
                        result = DeleteFHDATidbitFile(sfile)           'Remove from FTP site
                    End If
                End If
            Next


            'All is good, so update the database.
            WriteLog("Begin PROMPT Disbursement Update", "", "ImportFRSPaymentDisbursements")


            'processes all unprocessed files in the FRS dump directory for disbursements and errors

            HttpContext.Current.Session("UserName") = "FRS Import Program"
            HttpContext.Current.Session("DistrictID") = 55
            HttpContext.Current.Session("WorkflowRole") = "FRS Import Program"
            HttpContext.Current.Session("WorkflowRoleID") = 0


            'Process Disbursment File(s)
            'Look in drop directory for candidate FRS Disbursment file (.DAT extension)
            Dim sFileDumpPath As String = ProcLib.GetCurrentFRSTransferPath()

            Dim dDir As New DirectoryInfo(sFileDumpPath)
            For Each f As FileSystemInfo In dDir.GetFileSystemInfos
                If Left(UCase(f.Name), 15) = "FRSDISBURSEMENT" And Right(UCase(f.Name), 3) = "DAT" Then
                    ImportFileName = f.Name
                    'Open the file for reading
                    WriteLog("Begin" & f.Name, "", "FRSDisbursements")
                    Dim objReader As New StreamReader(f.FullName)
                    Dim sLine As String = objReader.ReadLine   'read the first line into the string
                    Dim i As Integer = 1
                    While Not sLine Is Nothing   'loop through the file till the end
                        'Parse the line
                        ParseFRSDisbursementRecord(sLine, ImportFileName, i)
                        sLine = objReader.ReadLine
                        i += 1
                    End While
                    WriteLog("End" & f.Name, "", "FRSDisbursements")
                    objReader.Close()
                    objReader.Dispose()


                    'rename file so it does not get processed again
                    Dim sNewName As String = f.FullName & "__Done"
                    Dim fNew As FileInfo = New FileInfo(f.FullName)
                    Try
                        fNew.MoveTo(sNewName)
                    Catch ex As Exception
                        WriteLog(ex.Message, "ERROR", "FRSDisbursements")
                    End Try

                End If
            Next

            'Process Disbursment Error Log File(s)

            'Look in drop directory for candidate FRS Disbursment file (.LOG extension)
            For Each f As FileSystemInfo In dDir.GetFileSystemInfos
                If Left(UCase(f.Name), 15) = "FRSDISBURSEMENT" And Right(UCase(f.Name), 3) = "LOG" Then
                    ImportFileName = f.Name
                    'Open the file for reading
                    WriteLog("Begin" & f.Name, "", "FRSLog")
                    Dim objReader As New StreamReader(f.FullName)
                    Dim sLine As String = objReader.ReadLine   'read the first line into the string
                    Dim i As Integer = 1
                    While Not sLine Is Nothing   'loop through the file till the end
                        'Parse the line
                        ParseFRSDisbursementLogRecord(sLine, ImportFileName, i)
                        sLine = objReader.ReadLine
                        i += 1
                    End While
                    WriteLog("End", "", "FRSLog")
                    objReader.Close()
                    objReader.Dispose()

                    'rename file so it does not get processed again
                    Dim sNewName As String = f.FullName & "__Done"
                    Dim fNew As FileInfo = New FileInfo(f.FullName)
                    Try
                        fNew.MoveTo(sNewName)
                    Catch ex As Exception
                        WriteLog(ex.Message, "ERROR", "FRSLog")
                    End Try

                End If
            Next



            WriteLog("End PROMPT Disbursement Update", "", "ImportFRSPaymentDisbursements")

            ''Remove all files from FTP site
            'For Each sfile As String In aList
            '    sfile = Trim(sfile)
            '    If sfile <> "" Then
            '        Dim result As String = DeleteFHDATidbitFile(sfile)           'remove the file 
            '        If result <> "Ok" Then    'FTP failed so exit
            '            WriteLog("FTPError", "", "DeleteFTPDisbursementsFiles")
            '        End If
            '    End If
            'Next

            WriteLog("End", "", "ImportFRSPaymentDisbursements")


        End Sub


        Private Function FixLength(ByVal SourceString As String, ByVal MaxLen As Integer, Optional ByVal DataType As String = "") As String
            'Function checks to see if the string 'is the same length, less than, or greather than the maximum
            'length. Based on that, it either trims the string down, or pads it with spaces.
            'If the padding is for a numeric field it will be padded with zeros.

            Dim rtnString As String = ""
            If SourceString Is Nothing Then
                SourceString = ""
            End If

            If DataType = "Currency" Then
                If SourceString = "" Then SourceString = "0.00"
                SourceString = FormatCurrency(SourceString, 2, TriState.False, TriState.False, TriState.False)   'convert to currency
                SourceString = SourceString.Replace(".", "")  'get rid of the decimal
                SourceString = SourceString.Replace("$", "")  'get rid of the $
            End If

            If MaxLen > 0 Then
                Select Case Len(SourceString)
                    Case MaxLen
                        rtnString = SourceString
                    Case Is < MaxLen
                        If DataType = "Currency" Or DataType = "Number" Then   'pad with leading zeros
                            Dim ipad As Integer = MaxLen - Len(SourceString)
                            For i As Integer = 1 To ipad
                                SourceString = "0" & SourceString
                            Next
                            rtnString = SourceString
                        Else
                            rtnString = SourceString.PadLeft(MaxLen)
                        End If

                    Case Is > MaxLen
                        rtnString = Mid(SourceString, 1, MaxLen)
                End Select
            Else
                rtnString = SourceString
            End If
            Return rtnString
        End Function



#End Region

#Region "IDisposable"

        Public Overridable Sub Dispose() Implements IDisposable.Dispose
            If Not db Is Nothing Then
                db.Dispose()
            End If
        End Sub

#End Region

        Protected Overrides Sub Finalize()
            MyBase.Finalize()
        End Sub
    End Class

End Namespace

