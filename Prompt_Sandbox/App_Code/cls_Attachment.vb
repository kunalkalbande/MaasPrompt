Imports System
Imports System.Web
Imports System.Web.UI.WebControls
Imports System.IO

Namespace Prompt

    '********************************************
    '*  Attachment Class
    '*  
    '*  Purpose: Processes data for the Attachment Object
    '*
    '*  Last Mod By:    Ford James
    '*  Last Mod On:    12/20/08
    '*
    '********************************************

    Public Class promptAttachment
        Implements IDisposable

        'Properties
        Public CallingPage As Page

        Public DistrictID As Integer = 0
        Public CollegeID As Integer = 0
        Public ProjectID As Integer = 0
        Public ContractID As Integer = 0
        Public ChangeOrderID As Integer = 0
        Public PhysicalPath As String = ""   'physical path for file minus file name
        Public FileName As String = ""
        Public SourceMovePath As String = ""
        Public TargetMovePath As String = ""

        Public UploadedFileName As String = ""    'File name from telerik upload file control
        Public FullPhysicalFilePathAndFileName As String = ""   'full physical file name and path on disc
        Public Comments As String = ""
        Public Description As String = ""

        Public DisableOverwrite As Boolean = False      'flag to disable overwrite in some cases

        Public Parent As Page    'legacy

        Public ParentType As String = ""
        Public ParentRecID As Integer = 0

        Public LastUpdateOn As String = ""
        Public LastUpdateBy As String = ""

        Private db As PromptDataHelper

        Public Sub New()
            db = New PromptDataHelper
        End Sub

#Region "Subs and Functions"

        Public Sub GetAttachmentData(ByVal sStoredFilePath As String, ByVal strFileName As String)
            'Fill the form
            Dim sql As String = "SELECT * FROM Attachments WHERE CHARINDEX('" & UCase(sStoredFilePath & strFileName) & "',UPPER(FilePath + FileName)) > 0"
            db.FillForm(CallingPage.FindControl("Form1"), sql)

        End Sub
        Public Sub SaveAttachmentData(ByVal AttachmentID As Integer)

            db.SaveForm(CallingPage.FindControl("Form1"), "SELECT * FROM Attachments WHERE AttachmentID = " & AttachmentID)

        End Sub

        Public Function GetTargetMoveDirectoriesFromProjectID(ByVal nProjectID As Integer) As DataTable
            Dim bShowProjectNumber As Integer
            Dim sql As String = "SELECT ShowProjectNumberInMenu FROM Districts WHERE DistrictID = " & HttpContext.Current.Session("DistrictID")

            bShowProjectNumber = db.ExecuteScalar(sql)

            If bShowProjectNumber = 1 Then  'we need to sort differently
                sql = "SELECT *  FROM qry_ProjectsContractsWithProjectNumber WHERE ProjectID = " & nProjectID & " ORDER BY College, Status, ProjectName, ContractStatus, ContractorName, ContractDescription "
            Else
                sql = "SELECT *  FROM qry_ProjectsContracts WHERE ProjectID = " & nProjectID & " ORDER BY College, Status, ProjectName, ContractStatus, ContractorName, ContractDescription"
            End If

            Return db.ExecuteDataTable(sql)

        End Function

        Public Function GetTargetMoveDirectories() As DataTable
            Dim bShowProjectNumber As Integer
            Dim sql As String = "SELECT ShowProjectNumberInMenu FROM Districts WHERE DistrictID = " & HttpContext.Current.Session("DistrictID")

            bShowProjectNumber = db.ExecuteScalar(sql)

            If bShowProjectNumber = 1 Then  'we need to sort differently
                sql = "SELECT *  FROM qry_ProjectsContractsWithProjectNumber WHERE DistrictID = " & HttpContext.Current.Session("DistrictID") & " ORDER BY College, Status, ProjectName, ContractStatus, ContractorName, ContractDescription "
            Else
                sql = "SELECT *  FROM qry_ProjectsContracts WHERE DistrictID = " & HttpContext.Current.Session("DistrictID") & " ORDER BY College, Status, ProjectName, ContractStatus, ContractorName, ContractDescription"
            End If

            Return db.ExecuteDataTable(sql)

        End Function

        Public Function GetTransactionsForAssociation(ByVal nContractID As Integer) As DataTable

            Return db.ExecuteDataTable("SELECT * FROM Transactions WHERE ContractID = " & nContractID)

        End Function

        Public Function GetInvoiceFilesForAssociation(ByVal nContractID As Integer) As DataTable

            Return db.ExecuteDataTable("SELECT AttachmentID,FileName FROM Attachments WHERE ContractID = " & nContractID & " AND FilePath Like '%/Invoices/%' ORDER BY FileName")

        End Function

        Public Function GetContractFilesForAssociation(ByVal nContractID As Integer) As DataTable

            Return db.ExecuteDataTable("SELECT AttachmentID,FileName FROM Attachments WHERE ContractID = " & nContractID & " AND FilePath Like '%C%' And FilePath Not Like '%Inv%' ORDER BY FileName")

        End Function


        Public Function GetChangeOrderFilesForAssociation(ByVal nContractID As Integer) As DataTable

            Return db.ExecuteDataTable("SELECT AttachmentID,FileName FROM Attachments WHERE ContractID = " & nContractID & " AND FilePath Like '%C%' And FilePath Not Like '%Inv%' ORDER BY FileName")

        End Function


        Public Sub SaveTransactionAssociation(ByVal transID As Integer, ByVal attachID As Integer)
            'Check that the assocation is not already there
            Dim sql As String = "SELECT COUNT(PrimaryKey) FROM AttachmentsLinks WHERE TransactionID = " & transID & " AND AttachmentID = " & attachID
            If db.ExecuteScalar(sql) = 0 Then 'Save the association of file/transaction
                sql = "INSERT INTO AttachmentsLinks(AttachmentID,TransactionID,LastUpdateBy,LastUpdateOn) "
                sql &= "VALUES (" & attachID & "," & transID & ",'" & db.CurrentUserName & "','" & Now() & "')"
                db.ExecuteNonQuery(sql)
            End If

        End Sub

        Public Sub GetLinkedAttachment(ByVal ID As Integer)
            db.FillReader("SELECT * FROM Attachments WHERE AttachmentID = " & ID)
            While db.Reader.Read()
                DistrictID = db.Reader("DistrictID")
                CollegeID = db.Reader("CollegeID")
                ProjectID = db.Reader("ProjectID")
                ContractID = db.Reader("ContractID")
                FileName = db.Reader("FileName")
                PhysicalPath = ProcLib.GetCurrentAttachmentPath() & db.Reader("FilePath")

                LastUpdateOn = db.Reader("LastUpdateOn")
                LastUpdateBy = db.Reader("LastUpdateBy")


            End While
        End Sub

        Public Sub UnlinkAttachment(ByVal ID As Integer, ByVal sParentType As String, ByVal ParentRecID As String)
            'Unlinks specific attachments from specific records
            If sParentType = "Transaction" Then
                db.ExecuteNonQuery("DELETE FROM AttachmentsLinks WHERE AttachmentID = " & ID & " AND TransactionID = " & ParentRecID)
            End If


        End Sub

        Public Sub DeleteLinkedAttachment(ByVal ID As Integer, ByVal sParentType As String)

            'get the full info for attachment 
            Dim fname As String = ""
            Dim row As DataRow
            row = db.GetDataRow("SELECT * FROM Attachments WHERE AttachmentID = " & ID)

            DistrictID = row("DistrictID")
            CollegeID = row("CollegeID")
            ProjectID = row("ProjectID")
            ContractID = row("ContractID")
            FileName = row("FileName")
            SetPath()

            If sParentType = "Transaction" Then
                PhysicalPath &= "Invoices/"
            ElseIf sParentType = "ContractDetail" Then
                PhysicalPath &= "Change Orders/"
            ElseIf sParentType = "Insurance" Then
                Dim ContactID As Integer = db.ExecuteScalar("Select CompanyID From AttachmentsInsurance Where AttachmentID = " & ID)
                PhysicalPath &= "ContactID_" & ContactID & "/"
            Else
                PhysicalPath &= "Contract/"
            End If

            FullPhysicalFilePathAndFileName = PhysicalPath & FileName

            row = Nothing

            'Delete the file from the disc
            If File.Exists(FullPhysicalFilePathAndFileName) Then
                File.Delete(FullPhysicalFilePathAndFileName)
            End If

            'delete from database
            If sParentType <> "Insurance" Then
                db.ExecuteNonQuery("DELETE FROM Attachments WHERE AttachmentID = " & ID)
                db.ExecuteNonQuery("DELETE FROM AttachmentsLinks WHERE AttachmentID = " & ID)
            Else
                db.ExecuteNonQuery("DELETE FROM Attachments WHERE AttachmentID = " & ID)
                db.ExecuteNonQuery("DELETE FROM AttachmentsInsurance WHERE AttachmentID = " & ID)
            End If

        End Sub

        Public Sub SetFullLinkedPhysicalFilePathAndFileName()
            'returns the Full path and file name for saved file
            Dim fname As String = ""
            Dim row As DataRow
            If ParentType = "Transaction" Then
                row = db.GetDataRow("SELECT Transactions.*,  Contracts.CollegeID FROM Transactions INNER JOIN Contracts ON  Transactions.ContractID = Contracts.ContractID WHERE TransactionID = " & ParentRecID)
                DistrictID = row("DistrictID")
                CollegeID = row("CollegeID")
                ProjectID = row("ProjectID")
                ContractID = row("ContractID")
                FileName = RemoveBadCharacters(UploadedFileName)
                CheckPath()
                SetPath()
                PhysicalPath &= "Invoices/"

                FullPhysicalFilePathAndFileName = PhysicalPath & FileName

                'check to see if this attachment is in workflow and if so flag
                'Checks passed attachmentID to see if in workflow
                Dim result As String = db.ExecuteScalar("SELECT InWorkflow FROM Attachments WHERE ContractID = " & ContractID & " AND FileName = '" & FileName & "'")
                If Not IsDBNull(result) Then
                    If result = 1 Then
                        DisableOverwrite = True
                    End If
                End If


            ElseIf ParentType = "ContractDetail" Then
                row = db.GetDataRow("SELECT Contracts.* FROM Contracts INNER JOIN ContractDetail ON  ContractDetail.ContractID = Contracts.ContractID WHERE ContractDetailID = " & ParentRecID)
                DistrictID = row("DistrictID")
                CollegeID = row("CollegeID")
                ProjectID = row("ProjectID")
                ContractID = row("ContractID")
                FileName = RemoveBadCharacters(UploadedFileName)
                CheckPath()
                SetPath()
                PhysicalPath &= "Change Orders/"
                FullPhysicalFilePathAndFileName = PhysicalPath & FileName

            ElseIf ParentType = "Insurance" Then
                DistrictID = db.ExecuteScalar("SELECT DistrictID From Contacts C Where C.ContactID = " & ParentRecID)
                CollegeID = 0
                ProjectID = 0
                ContractID = 0
                FileName = RemoveBadCharacters(UploadedFileName)
                'Note: Company Insurance Attachments are "special" and are not associated with a particular College or Project or Contract.
                '       They are associated with a particular Company.  They are stored under the appropriate district under the CompanyInsurancePolicies folder
                SetPath()
                PhysicalPath &= "ContactID_" & ParentRecID & "/"
                If Not Directory.Exists(PhysicalPath) Then
                    Directory.CreateDirectory(PhysicalPath)
                End If
                FullPhysicalFilePathAndFileName = PhysicalPath & FileName

            Else
                row = db.GetDataRow("SELECT Contracts.* FROM Contracts WHERE ContractID = " & ParentRecID)
                DistrictID = row("DistrictID")
                CollegeID = row("CollegeID")
                ProjectID = row("ProjectID")
                ContractID = row("ContractID")
                FileName = RemoveBadCharacters(UploadedFileName)
                CheckPath()
                SetPath()
                PhysicalPath &= "Contract/"
                FullPhysicalFilePathAndFileName = PhysicalPath & FileName

            End If
            row = Nothing
        End Sub


        Public Function GetLinkedAttachments(ByVal recid As Integer, ByVal rectype As String) As DataTable
            Dim sql As String = ""
            If rectype = "Transaction" Then
                sql = "SELECT Attachments.* FROM AttachmentsLinks INNER JOIN Attachments ON AttachmentsLinks.AttachmentID = Attachments.AttachmentID "
                sql &= "WHERE AttachmentsLinks.TransactionID = " & recid & " ORDER BY Attachments.FileName "

            ElseIf rectype = "ContractDetail" Then
                sql = "SELECT Attachments.* FROM AttachmentsLinks INNER JOIN Attachments ON AttachmentsLinks.AttachmentID = Attachments.AttachmentID "
                sql &= "WHERE AttachmentsLinks.ContractDetailID = " & recid & " ORDER BY Attachments.FileName "

            Else   'contract
                sql = "SELECT Attachments.* FROM AttachmentsLinks INNER JOIN Attachments ON AttachmentsLinks.AttachmentID = Attachments.AttachmentID "
                sql &= "WHERE AttachmentsLinks.ContractID = " & recid & " ORDER BY Attachments.FileName "

            End If

            Return db.ExecuteDataTable(sql)

        End Function

        Public Function RemoveBadCharacters(ByVal fname As String) As String
            Dim result As String = fname
            'Remove bad characters from file name
            result = result.Replace("[", "")
            result = result.Replace("]", "")
            result = result.Replace("'", "")
            result = result.Replace("#", "-")
            result = result.Replace("`", "")
            result = result.Replace("@", "")
            result = result.Replace("*", "")

            result = result.Replace("&", " and ")
            result = result.Replace("+", " plus ")
			
            Return result

        End Function

        Public Function IsInWorkflow(ByVal AttachmentID) As Boolean
            'Checks passed attachmentID to see if in workflow
            Dim result As String = db.ExecuteScalar("SELECT InWorkflow FROM Attachments WHERE AttachmentID = " & AttachmentID)
            If Not IsDBNull(result) Then
                If result = 1 Then
                    Return True
                End If
            End If

            Return False

        End Function

        Public Sub SaveLinkedFileToDatabase()

            Dim bFileExists As Boolean = False
            Dim bWriteFile As Boolean = True

            FileName = RemoveBadCharacters(FileName)

            Dim sStoredFilePath As String = FullPhysicalFilePathAndFileName.Replace(ProcLib.GetCurrentAttachmentPath(), "") 'strip off the physical prefix of full path
            sStoredFilePath = sStoredFilePath.Replace(FileName, "")

            'Check that the file does not already exist
            db.FillReader("SELECT * FROM Attachments WHERE CollegeID = " & CollegeID)
            Dim strFullFileName As String
            While db.Reader.Read()
                strFullFileName = db.Reader("FilePath") & db.Reader("FileName")
                If strFullFileName = (sStoredFilePath & FileName) Then
                    bFileExists = True
                End If
            End While
            db.Reader.Close()

            'If bFileExists Then
            '    If Request.Form("overwriteflag") = "warn" Then   'warn user if file exists and don't upload			
            '        message.Text = message.Text & "<br><br>File Aready Exists! <br> Please rename the file before uploading."
            '        bWriteFile = False
            '    End If
            'End If
            Dim sql As String = ""
            If bWriteFile = True Then
                If bFileExists = True Then  'update the current record
                    sql = "UPDATE Attachments SET "
                    sql &= "Description = '" & Description & "',"
                    sql &= "FilePath = '" & sStoredFilePath & "',"
                    sql &= "FileSize = '" & LinkedAttachmentFileSize() & "',"
                    sql &= "Comments = '" & Comments & "',"
                    sql &= "LastUpdateBy = '" & db.CurrentUserName & "',"
                    sql &= "LastUpdateOn = '" & Now() & "' "
                    sql &= "WHERE FileName = '" & FileName & "' AND FilePath = '" & sStoredFilePath & "'"
                    'write file info to database
                    db.ExecuteNonQuery(sql)

                Else  'write a new record  (for contract and contract detail 
                    sql = "INSERT INTO Attachments "
                    sql &= "(ClientID,DistrictID, FilePath, FileName, FileSize, Description, ProjectID, CollegeID, ContractID, Comments, LastUpdateBy, LastUpdateOn) "
                    sql &= "VALUES (" & CallingPage.Session("ClientID") & ",'" & DistrictID & "','" & sStoredFilePath & "','" & FileName & "','" & LinkedAttachmentFileSize() & "',"
                    sql &= "'" & Description & "','" & ProjectID & "','" & CollegeID & "','" & ContractID & "','" & Comments & "',"
                    sql &= "'" & db.CurrentUserName & "','" & Now() & "') "
                    sql &= ";SELECT NewKey = Scope_Identity()"  'return the new primary key

                    'write record to database and get new key
                    Dim newkey As Integer = db.ExecuteScalar(sql)

                    If ParentType = "Transaction" Then
                        sql = "INSERT INTO AttachmentsLinks (AttachmentID,TransactionID,LastUpdateBy,LastUpdateOn) "
                        sql &= "VALUES(" & newkey & "," & ParentRecID & ",'" & db.CurrentUserName & "','" & Now() & "')"
                    ElseIf ParentType = "ContractDetail" Then
                        sql = "INSERT INTO AttachmentsLinks (AttachmentID,ContractDetailID,LastUpdateBy,LastUpdateOn) "
                        sql &= "VALUES(" & newkey & "," & ParentRecID & ",'" & db.CurrentUserName & "','" & Now() & "')"
                    ElseIf ParentType = "Insurance" Then
                        sql = "INSERT INTO AttachmentsInsurance (AttachmentID,CompanyID,LastUpdateBy,LastUpdateOn) "
                        sql &= "VALUES(" & newkey & "," & ParentRecID & ",'" & db.CurrentUserName & "','" & Now() & "')"
                    Else
                        sql = "INSERT INTO AttachmentsLinks (AttachmentID,ContractID,LastUpdateBy,LastUpdateOn) "
                        sql &= "VALUES(" & newkey & "," & ParentRecID & ",'" & db.CurrentUserName & "','" & Now() & "')"
                    End If
                    'Write entry to link attachements table

                    db.ExecuteNonQuery(sql)
                End If


            End If
        End Sub
        Public Sub CreateAttachmentDir()
            'This routine creates directories for attachement storage
            SetPath()
            If Not Directory.Exists(PhysicalPath) Then
                Directory.CreateDirectory(PhysicalPath)
            End If
            Dim ndir As String = ""
            'create default directories for projects and contracts
            If ContractID > 0 Then    'create default contract folders
                ndir = PhysicalPath & "Contract"
                If Not Directory.Exists(ndir) Then
                    Directory.CreateDirectory(ndir)
                End If
                ndir = PhysicalPath & "Invoices"
                If Not Directory.Exists(ndir) Then
                    Directory.CreateDirectory(ndir)
                End If
                ndir = PhysicalPath & "Change Orders"
                If Not Directory.Exists(ndir) Then
                    Directory.CreateDirectory(ndir)
                End If
                ndir = PhysicalPath & "Misc"
                If Not Directory.Exists(ndir) Then
                    Directory.CreateDirectory(ndir)
                End If
                'hardcoded for FHDA only
                If DistrictID = 55 Then
                    ndir = PhysicalPath & "Liability Insurance"
                    If Not Directory.Exists(ndir) Then
                        Directory.CreateDirectory(ndir)
                    End If
                End If
            End If
            If ContractID = 0 And ProjectID > 0 Then    'create default project folders
                ndir = PhysicalPath & "14-D"
                If Not Directory.Exists(ndir) Then
                    Directory.CreateDirectory(ndir)
                End If
                ndir = PhysicalPath & "Board Items"
                If Not Directory.Exists(ndir) Then
                    Directory.CreateDirectory(ndir)
                End If
                ndir = PhysicalPath & "Correspondence"
                If Not Directory.Exists(ndir) Then
                    Directory.CreateDirectory(ndir)
                End If
                ndir = PhysicalPath & "Misc"
                If Not Directory.Exists(ndir) Then
                    Directory.CreateDirectory(ndir)
                End If
            End If


        End Sub
        Public Sub DeleteAttachmentDir()
            'This routine creates directories for attachement storage
            SetPath()
            If Directory.Exists(PhysicalPath) Then
                Directory.Delete(PhysicalPath, True)
            End If
        End Sub
        Public Sub CheckPath()
            'This checks that the path exist and if not creates it - is a little redundant but 
            'used to make code readable when not explicitly trying to create the path (as when adding a record)

            CreateAttachmentDir()
        End Sub
        Public Sub SetPath()
            'This routine sets the physical path for the attachment
            'start with the basic path - we do not allow attachent storage above the college level
            PhysicalPath = ProcLib.GetCurrentAttachmentPath() & "DistrictID_" & DistrictID & "/"

            If CollegeID <> 0 Then
                PhysicalPath = PhysicalPath & "CollegeID_" & CollegeID & "/"

            End If
            If ProjectID <> 0 Then
                PhysicalPath = PhysicalPath & "ProjectID_" & ProjectID & "/"
            End If

            If ContractID <> 0 Then
                PhysicalPath = PhysicalPath & "ContractID_" & ContractID & "/"
            End If

            If CollegeID = 0 And ProjectID = 0 And ContractID = 0 Then 'then this is Insurance-related
                PhysicalPath &= "CompanyInsurancePolicies/"
            End If



        End Sub
        Public Function FileSize() As String
            'Dim f As New FileInfo(PhysicalPath & FileName)
            Dim f As New FileInfo(PhysicalPath)
            FileSize = FormatNumber(f.Length, 0, ) & " bytes"
            If f.Length > 1000 Then
                FileSize = FormatNumber(f.Length / 1000, 1) & "Kb"
            End If
            If f.Length > 1000000 Then
                FileSize = FormatNumber(f.Length / 1000000, 1) & "Mb"
            End If
        End Function
        Public Function LinkedAttachmentFileSize() As String
            'this is redundant but fixes breaking change in linked attachment code when changing out obout control - need to fix later. (1/09)
            Dim f As New FileInfo(PhysicalPath & FileName)
            LinkedAttachmentFileSize = FormatNumber(f.Length, 0, ) & " bytes"
            If f.Length > 1000 Then
                LinkedAttachmentFileSize = FormatNumber(f.Length / 1000, 1) & "Kb"
            End If
            If f.Length > 1000000 Then
                LinkedAttachmentFileSize = FormatNumber(f.Length / 1000000, 1) & "Mb"
            End If
        End Function
        Public Function LastModified() As String
            'Dim f As New FileInfo(PhysicalPath & FileName)
            Dim f As New FileInfo(PhysicalPath)
            LastModified = f.LastWriteTime
        End Function
        Public Function RelativePath() As String
            RelativePath = Replace(PhysicalPath, ProcLib.GetCurrentAttachmentPath(), ProcLib.GetCurrentRelativeAttachmentPath())
        End Function
        Public Function FileIcon() As String
            'Select image depending on file type
            If InStr(FileName, ".xls") > 0 Then
                FileIcon = "prompt_xls.gif"
            ElseIf InStr(FileName, ".pdf") > 0 Then
                FileIcon = "prompt_pdf.gif"
            ElseIf InStr(FileName, ".doc") > 0 Then
                FileIcon = "prompt_doc.gif"
            ElseIf InStr(FileName, ".zip") > 0 Then
                FileIcon = "prompt_zip.gif"
            Else
                FileIcon = "prompt_page.gif"
            End If

        End Function
        Public Sub DeriveIDsFromPath(ByVal spath As String)
            'Sets the ID properties of the class based on passed path
            CollegeID = ParseIDs(spath, "College")
            ProjectID = ParseIDs(spath, "Project")
            ContractID = ParseIDs(spath, "Contract")

        End Sub
        Private Function ParseIDs(ByVal spath As String, ByVal sLevel As String) As Integer
            'passes back the ID from passed path and key

            If InStr(spath, sLevel) = 0 Then  'just return 0
                ParseIDs = 0

            Else

                sLevel = sLevel & "ID_"
                Dim sResult As String
                Dim nLoc As Integer

                nLoc = InStr(spath, sLevel)
                sResult = Mid(spath, nLoc)

                nLoc = InStr(sResult, "/") - 1
                sResult = Left(sResult, nLoc)

                nLoc = InStr(sResult, "_") + 1
                sResult = Mid(sResult, nLoc)

                ParseIDs = sResult
            End If


        End Function
        Public Sub MoveFile()

            DeriveIDsFromPath(TargetMovePath)
            DistrictID = Parent.Session("DistrictID")

            'remove erroneous // in path if present
            TargetMovePath = TargetMovePath.Replace("//", "/")
            SourceMovePath = SourceMovePath.Replace("//", "/")

            File.Move(SourceMovePath & FileName, TargetMovePath & FileName)

            'Strip out the physical path from file path before update
            Dim dbTargetMovePath As String = TargetMovePath.Replace(ProcLib.GetCurrentAttachmentPath(), "")
            Dim dbSourceMovePath As String = SourceMovePath.Replace(ProcLib.GetCurrentAttachmentPath(), "")

            'Update the database
            Using rs As New PromptDataHelper
                Dim sql As String = ""
                sql &= "UPDATE Attachments SET FilePath = '" & dbTargetMovePath & "', "
                sql &= "CollegeID = " & CollegeID & ","
                sql &= "ProjectID = " & ProjectID & ","
                sql &= "ContractID = " & ContractID & ", "
                sql &= "LastUpdateBy = '" & Parent.Session("UserName") & "',"
                sql &= "LastUpdateOn = '" & Now() & "'  "
                sql &= "WHERE FilePath = '" & dbSourceMovePath & "' AND FileName = '" & FileName & "' "

                rs.ExecuteNonQuery(sql)
            End Using
        End Sub

        Public Function checkFileNameCharacters(fileName As String) As String
            Dim charFind As Boolean = False
            Dim badArray As Array = {"&", "[", "]", "'", "#", "+"}

            For Each value As String In badArray
                If fileName.IndexOf(value) > -1 Then
                    charFind = True
                    Exit For
                End If
            Next
            Return charFind
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





