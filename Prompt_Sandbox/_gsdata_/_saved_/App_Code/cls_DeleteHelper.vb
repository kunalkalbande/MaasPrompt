Imports System
Imports System.Web
Imports System.Web.UI.WebControls
Imports System.IO
Imports System.Data
Imports System.Data.SqlClient

Namespace Prompt

    '********************************************
    '*  College Class
    '*  
    '*  Purpose: Processes data for the College Object
    '*
    '*  Last Mod By:    Ford James
    '*  Last Mod On:    04/02/07
    '*
    '********************************************

    Public Class DeleteHelper
        Implements IDisposable

        'Properties
        Public CallingPage As Page
        Public Reader As SqlDataReader
        Public DataTable As DataTable

        Private db As PromptDataHelper

        Public Sub New()
            db = New PromptDataHelper
        End Sub

#Region "Subs and Functions"

        Private Function GetDependantTotals(ByVal sql As String) As Integer
            'returns a total count based on passed sql
            Return db.ExecuteScalar(sql)
        End Function

        Public Function CheckDependantsForDelete(ByVal RecordType As String, ByVal Key As Integer) As String

            'checks for dependant records prior to deletion 

            Dim message As String = "Are you sure you want to delete this record?"
            Dim recs As Integer = 0

            Select Case RecordType

                Case "Client"
                    recs = GetDependantTotals("SELECT COUNT(ClientID) as TOT FROM Users WHERE ClientID = " & Key)
                    If recs > 0 Then
                        message = "There are " & recs & " User(s) associated with this Client. "
                        message &= "<br>Please Delete them before deleting.<br><br>"
                    End If

                    recs = GetDependantTotals("SELECT COUNT(ClientID) as TOT FROM Districts WHERE ClientID = " & Key)
                    If recs > 0 Then
                        message &= "There are " & recs & " District(s) associated with this Client."
                        message &= "<br>Please Delete them before deleting.<br><br>"
                    End If


                Case "District"

                    recs = GetDependantTotals("SELECT COUNT(CollegeID) as TOT FROM Colleges WHERE DistrictID = " & Key)
                    If recs > 0 Then
                        message = "There are " & recs & " College(s) associated with this district."
                        message &= "<br>Please Delete them before deleting.<br><br>"
                    End If

                    
                Case "College"
                    recs = GetDependantTotals("SELECT COUNT(ProjectID) as TOT FROM Projects WHERE CollegeID = " & Key)
                    If recs > 0 Then
                        message = "There are " & recs & " Project(s) associated with this College."
                        message &= "<br>Please Delete them before deleting.<br><br>"
                    End If
                    recs = GetDependantTotals("SELECT COUNT(LedgerAccountID) as TOT FROM LedgerAccounts WHERE CollegeID = " & Key)
                    If recs > 0 Then
                        message = "There are " & recs & " Ledger Account(s) associated with this College."
                        message &= "<br>Please Delete them before deleting.<br><br>"
                    End If

                Case "Project"
                    recs = GetDependantTotals("SELECT COUNT(ContractID) as TOT FROM Contracts WHERE ProjectID = " & Key)
                    If recs > 0 Then
                        message = "There are " & recs & " Contracts(s) associated with this Project."
                        message &= "<br>Please Delete them before deleting.<br><br>"
                    End If

                Case "Contract"
                    recs = GetDependantTotals("SELECT COUNT(ContractID) as TOT FROM ContractDetail WHERE ContractID = " & Key)
                    If recs > 0 Then
                        message = "There are " & recs & " Contract Ammendment(s) associated with this Contract."
                        message &= "<br>Please Delete them before deleting.<br><br>"
                    End If

                    recs = GetDependantTotals("SELECT COUNT(ContractID) as TOT FROM Transactions WHERE ContractID = " & Key)
                    If recs > 0 Then
                        message = "There are " & recs & " Transaction(s) associated with this Contract."
                        message &= "<br>Please Delete them before deleting.<br><br>"
                    End If


                    'Case "BudgetChangeBatch"

                    '    'Check that the batch being deleted is the latest batch, otherwise disallow
                    '    recs = GetDependantTotals("SELECT MAX(BudgetChangeBatchID) FROM BudgetChangeBatches WHERE DistrictID = " & CallingPage.Session("DistrictID"))
                    '    If recs <> Key Then ' user cannot delete

                    '        message = "You can only delete the latest Batch entered. <br> Please delete all later Batches before attempting to Delete this batch."

                    '    Else
                    '        message = "SHOWDELETEDeleting this batch will delete all change log entries related to this batch - are you sure you want to continue?. "

                    '    End If




                    '        Case "Contractor"

                    '            rs.SQLText = "SELECT COUNT(ContractID) as TOT FROM Contracts WHERE ContractorID = " & RecID
                    '            rs.GetDataTable()
                    '            cnt = rs.DT.Rows(0).Item("TOT")
                    '            If cnt > 0 Then                 'display a popup warning and close edit page
                    '                message = "There are " & cnt & " Contracts associtated with this Contractor. Please Delete all associated records before deleting this contractor. <br><br> " & vbCrLf
                    '                butDelete.Visible = False
                    '                butCancel.Text = " Ok  "
                    '            End If

                    '            rs.SQLText = "SELECT COUNT(TransactionID) as TOT FROM Transactions WHERE ContractorID = " & RecID
                    '            rs.GetDataTable()
                    '            cnt = rs.DT.Rows(0).Item("TOT")
                    '            If cnt > 0 Then                 'display a popup warning and close edit page
                    '                message = message & "There are " & cnt & " Transactions associtated with this Contractor. Please Delete all associated records before deleting this contractor. "
                    '                butDelete.Visible = False
                    '                butCancel.Text = " Ok  "
                    '            End If

                    '        Case "ProjectManager"

                    '            rs.SQLText = "SELECT COUNT(ProjectID) as TOT FROM Projects WHERE PMID = " & RecID
                    '            rs.GetDataTable()
                    '            cnt = rs.DT.Rows(0).Item("TOT")
                    '            If cnt > 0 Then                 'display a popup warning and close edit page
                    '                message = "There are " & cnt & " Projects associtated with this Project Manager. Please un-associate all associated records before deleting this Project Manager. <br><br> " & vbCrLf
                    '                butDelete.Visible = False
                    '                butCancel.Text = " Ok  "
                    '            End If

                    '            rs.SQLText = "SELECT COUNT(TransactionID) as TOT FROM Transactions WHERE ContractorID = " & RecID
                    '            rs.GetDataTable()
                    '            cnt = rs.DT.Rows(0).Item("TOT")
                    '            If cnt > 0 Then                 'display a popup warning and close edit page
                    '                message = message & "There are " & cnt & " Transactions associtated with this Contractor. Please Delete all associated records before deleting this contractor. "
                    '                butDelete.Visible = False
                    '                butCancel.Text = " Ok  "
                    '            End If



                    '        Case "ApprisePhoto"

                    '            Session("RtnFromEdit") = True
                    '            message = "Are you sure you want to delete this photo? "
                    '            butDelete.Text = "Delete Photo"

                    '        Case Else
                    '            'do no checks

            End Select

            '    rs.Close()
            '    rs = Nothing

            Return message

        End Function

        Public Sub DeleteRecord(ByVal RecordType As String, ByVal Key As Integer)
            Dim sql As String = ""
            Select Case RecordType

                Case "Client"

                    HttpContext.Current.Session("RefreshNav") = True
                    sql = "DELETE FROM Clients WHERE ClientID = " & Key
                    db.ExecuteNonQuery(sql)

                    CallingPage.Session("RefreshNav") = True
                    ProcLib.CloseAndRefresh(CallingPage)


                Case "District"

                    Using att As New promptAttachment
                        With att                'Remove the Attachment Directory
                            .DistrictID = Key
                            .DeleteAttachmentDir()
                        End With
                    End Using

                    'delete the  record
                    sql = "DELETE FROM Districts WHERE DistrictID = " & Key
                    db.ExecuteNonQuery(sql)

                    'delete the  record
                    sql = "DELETE FROM Lookups WHERE DistrictID = " & Key
                    db.ExecuteNonQuery(sql)

                    'delete the  record
                    sql = "DELETE FROM Contractors WHERE DistrictID = " & Key
                    db.ExecuteNonQuery(sql)

                    'delete the  record
                    sql = "DELETE FROM ProjectManagers WHERE DistrictID = " & Key
                    db.ExecuteNonQuery(sql)


                    'delete the  record
                    sql = "DELETE FROM ObjectCodes WHERE DistrictID = " & Key
                    db.ExecuteNonQuery(sql)

                    'delete the  record
                    sql = "DELETE FROM Notes WHERE DistrictID = " & Key
                    db.ExecuteNonQuery(sql)


                    CallingPage.Session("RefreshNav") = True
                    ProcLib.CloseAndRefresh(CallingPage)

                Case "College"

                    Using att As New promptAttachment
                        With att                'Remove the Attachment Directory
                            .DistrictID = CallingPage.Session("DistrictID")
                            .CollegeID = Key
                            .DeleteAttachmentDir()
                        End With
                    End Using

                    sql = "DELETE FROM Attachments WHERE CollegeID = " & Key
                    db.ExecuteNonQuery(sql)

                    'delete the record
                    sql = "DELETE FROM Colleges WHERE CollegeID = " & Key
                    db.ExecuteNonQuery(sql)

                    CallingPage.Session("RefreshNav") = True
                    ProcLib.CloseAndRefresh(CallingPage)


                Case "Project"

                    Using att As New promptAttachment
                        With att                'Remove the Attachment Directory
                            .DistrictID = CallingPage.Session("DistrictID")
                            .CollegeID = CallingPage.Session("CollegeID")
                            .ProjectID = Key
                            .DeleteAttachmentDir()
                        End With
                    End Using

                    sql = "DELETE FROM Attachments WHERE ProjectID = " & Key
                    db.ExecuteNonQuery(sql)

                    'delete the record
                    sql = "DELETE FROM Projects WHERE ProjectID = " & Key
                    db.ExecuteNonQuery(sql)


                    ''delete the record
                    'sql = "DELETE FROM PromptProjectData WHERE ProjectID = " & Key
                    'db.ExecuteNonQuery(sql)

                    'delete the record
                    sql = "DELETE FROM BudgetItems WHERE ProjectID = " & Key
                    db.ExecuteNonQuery(sql)

                    ''delete the record
                    'sql = "DELETE FROM AppriseProjectData WHERE ProjectID = " & Key
                    'db.ExecuteNonQuery(sql)

                    'delete the record
                    sql = "DELETE FROM ApprisePhotos WHERE ProjectID = " & Key
                    db.ExecuteNonQuery(sql)

                    'delete the record
                    sql = "DELETE FROM ProjectBudgetChanges WHERE ProjectID = " & Key
                    db.ExecuteNonQuery(sql)

                    'delete the record
                    sql = "DELETE FROM BudgetChangeLog WHERE ProjectID = " & Key
                    db.ExecuteNonQuery(sql)

                    'delete the record
                    sql = "DELETE FROM BudgetObjectCodeEstimates WHERE ProjectID = " & Key
                    db.ExecuteNonQuery(sql)

                    'delete the record
                    sql = "DELETE FROM BudgetObjectCodes WHERE ProjectID = " & Key
                    db.ExecuteNonQuery(sql)

                    'delete the record
                    sql = "DELETE FROM BudgetReporting WHERE ProjectID = " & Key
                    db.ExecuteNonQuery(sql)


                    'delete the record
                    sql = "DELETE FROM Flags WHERE ProjectID = " & Key
                    db.ExecuteNonQuery(sql)

                    'delete the record
                    sql = "DELETE FROM Notes WHERE ProjectID = " & Key
                    db.ExecuteNonQuery(sql)

                    CallingPage.Session("RefreshNav") = True
                    'need to call default main page for college as no longer a project
                    ProcLib.CloseAndRefreshSpecific(CallingPage, "window.opener.document.location.href='frame_default.aspx?view=Project&ProjectID=" & Key & "&CollegeID=" & CallingPage.Session("CollegeID") & "';")



                Case "Contract"
                    Using att As New promptAttachment
                        With att                'Remove the Attachment Directory
                            .DistrictID = CallingPage.Session("DistrictID")
                            .CollegeID = CallingPage.Session("CollegeID")
                            .ProjectID = CallingPage.Session("DelProjectID")
                            .ContractID = Key
                            .DeleteAttachmentDir()
                        End With
                    End Using

                    sql = "DELETE FROM Attachments WHERE ContractID = " & Key
                    db.ExecuteNonQuery(sql)

                    'delete the record
                    sql = "DELETE FROM Contracts WHERE ContractID = " & Key
                    db.ExecuteNonQuery(sql)


                    'delete the record
                    sql = "DELETE FROM Notes WHERE ContractID = " & Key
                    db.ExecuteNonQuery(sql)


                    CallingPage.Session("nodeid") = "ContractGroup" & CallingPage.Session("DelProjectID")
                    CallingPage.Session("RefreshNav") = True
                    ProcLib.CloseAndRefreshSpecific(CallingPage, "window.opener.document.location.href='frame_default.aspx?view=Contract&ProjectID=" & CallingPage.Session("DelProjectID") & "&CollegeID=" & CallingPage.Session("CollegeID") & "';")

                    'Case "BudgetChangeBatch"

                    '    'delete the budget batch
                    '    sql = "DELETE FROM BudgetChangeBatches WHERE BudgetChangeBatchID = " & Key
                    '    Using command As SqlCommand = db.CreateSqlStringCommand(sql)
                    '        db.ExecuteNonQuery("DeleteRecord", command)
                    '    End Using

                    '    'delete the log entries
                    '    sql = "DELETE FROM BudgetChangeLog WHERE BudgetChangeBatchID = " & Key
                    '    Using command As SqlCommand = db.CreateSqlStringCommand(sql)
                    '        db.ExecuteNonQuery("RemoveLogEntries", command)
                    '    End Using

                    '    'Update the current budget batch id in the colleges table to the previous ID if present
                    '    sql = "SELECT BudgetChangeBatchID FROM BudgetChangeBatches WHERE DistrictID = " & CallingPage.Session("DistrictID") & " ORDER BY BudgetChangeBatchID DESC"
                    '    Dim newID As Integer = 0
                    '    Using command As SqlCommand = db.CreateSqlStringCommand(sql)
                    '        newID = db.ExecuteScalar("GetPreviousBatch", command)
                    '    End Using
                    '    If newID > 0 Then   'set to previous batch
                    '        sql = "UPDATE Colleges SET CurrentBudgetBatchID = " & newID & " WHERE DistrictID = " & CallingPage.Session("DistrictID")
                    '    Else            'set to zero
                    '        sql = "UPDATE Colleges SET CurrentBudgetBatchID = 0 WHERE DistrictID = " & CallingPage.Session("DistrictID")
                    '    End If
                    '    Using command As SqlCommand = db.CreateSqlStringCommand(sql)
                    '        db.ExecuteNonQuery("UpdateCollegeBatch", command)
                    '    End Using


                    '        Case "ApprisePhoto"

                    '            'Deletes a photo from apprise project
                    '            Dim strPhotoPath As String
                    '            Dim CollegeID As Integer = Request.QueryString("CollegeID")
                    '            Dim ProjectID As Integer = Request.QueryString("ProjectID")
                    '            strPhotoPath = Proclib.GetCurrentAttachmentPath()
                    '            strPhotoPath = strPhotoPath & "DistrictID_" & Session("DistrictID") & "\CollegeID_" & CollegeID & "\ProjectID_" & ProjectID & "\_appphotos\"

                    '            If Request.QueryString("main") = "y" Then
                    '                strPhotoPath = strPhotoPath & "main.jpg"
                    '            End If

                    '            'Delete photo if present
                    '            Dim file As New FileInfo(strPhotoPath)
                    '            If file.Exists Then  'create the folder
                    '                file.Delete()
                    '            End If

                    '            Session("RtnFromEdit") = True

                    '            CloseAndRefresh("window.opener.document.forms[0].submit();")

                    '        Case "Attachment"

                    '            Dim strFile As String
                    '            rs.SQLText = "SELECT FilePath,FileName FROM Attachments WHERE AttachmentID = " & RecID
                    '            rs.OpenDataReader()
                    '            While rs.Reader.Read
                    '                strFile = Proclib.GetCurrentAttachmentPath() & rs.Reader("FilePath") & rs.Reader("FileName")
                    '            End While
                    '            rs.Close()

                    '            'delete the record
                    '            rs.SQLText = "DELETE FROM Attachments WHERE AttachmentID = " & RecID
                    '            rs.ExecuteSQL()
                    '            rs.Close()

                    '            If file.Exists(strFile) Then
                    '                file.Delete(strFile)
                    '            End If

                    '            CloseAndRefresh("window.opener.document.forms[0].submit();")

                    '        Case "Contractor"


                    '            'delete the record
                    '            rs.SQLText = "DELETE FROM Contractors WHERE ContractorID = " & RecID
                    '            rs.ExecuteSQL()
                    '            rs.Close()

                    '            CloseAndRefresh("window.opener.document.forms[0].submit();")

                    '        Case "ProjectManager"


                    '            'delete the record
                    '            rs.SQLText = "DELETE FROM ProjectManagers WHERE PMID = " & RecID
                    '            rs.ExecuteSQL()
                    '            rs.Close()

                    '            CloseAndRefresh("window.opener.document.forms[0].submit();")

                    '        Case "ContractDetail"

                    '            'delete the record
                    '            rs.SQLText = "DELETE FROM ContractDetail WHERE ContractDetailID = " & RecID
                    '            rs.ExecuteSQL()


                    '            'delete the record
                    '            rs.SQLText = "DELETE FROM ContractDetail WHERE GlobalContractDetailID = " & RecID
                    '            rs.ExecuteSQL()

                    '            rs.Close()

                    '            CloseAndRefresh("window.opener.document.forms[0].submit();")


    


                    '        Case "Help"

                    '            'delete the help record
                    '            rs.SQLText = "DELETE FROM Help WHERE HelpID = " & RecID
                    '            rs.ExecuteSQL()
                    '            rs.Close()

                    '            CloseAndRefresh("window.opener.document.forms[0].submit();")

                    '        Case "User"

                    '            'delete the User record
                    '            rs.SQLText = "DELETE FROM Users WHERE UserID = " & RecID
                    '            rs.ExecuteSQL()
                    '            rs.Close()

                    '            CloseAndRefresh("window.opener.document.forms[0].submit();")


                    '        Case "Lookup"

                    '            'delete the User record
                    '            rs.SQLText = "DELETE FROM Lookups WHERE PrimaryKey = " & RecID
                    '            rs.ExecuteSQL()
                    '            rs.Close()

                    '            CloseAndRefresh("window.opener.document.forms[0].submit();")

                    '        Case "Report"

                    '            'delete the User record
                    '            rs.SQLText = "DELETE FROM Reports WHERE ReportID = " & RecID
                    '            rs.ExecuteSQL()
                    '            rs.Close()

                    '            CloseAndRefresh("window.opener.document.forms[0].submit();")

            End Select
        End Sub


#End Region


#Region "IDisposable"

        Public Overridable Sub Dispose() Implements IDisposable.Dispose
            If Not db Is Nothing Then
                db.Dispose()
            End If
            If Not Reader Is Nothing Then
                Reader.Dispose()
            End If
            If Not DataTable Is Nothing Then
                DataTable.Dispose()
            End If
        End Sub

#End Region

    End Class

End Namespace

