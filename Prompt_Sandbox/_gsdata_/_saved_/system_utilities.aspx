<%@ Page Language="vb" %>
<%@ Import Namespace="Prompt" %>
<%@ Import Namespace="System" %>
<%@ Import Namespace="System.IO" %>
<%@ Import Namespace="System.Data.OleDb" %>


<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">

<script runat="server">
    
    Private nProcID As Integer = 0
    Private nProcCode As String = ""
    Private bEnablePreReleaseProceedure As Boolean = True    'Set this true if you want to run relase update code (CAREFUL!)
   
    Private Sub Page_Load(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MyBase.Load

        Session("PageID") = "SystemUtilities"

        Proclib.CheckSession(Page)
        
        lblResults.Text = ""
        
        nProcID = Request.QueryString("proc")
        Using rs As New PromptDataHelper
            rs.FillReader("SELECT * FROM SystemUtilities WHERE PrimaryKey = " & nProcID)
            While rs.Reader.Read
                lblDescription.Text = rs.Reader("Description")
                nProcCode = Trim(rs.Reader("ProcCode"))
            End While
        End Using
        
        FilterPrompts()

    End Sub
    
    Private Sub FilterPrompts()
        
        lblParm1.Visible = False
        txtParm1.Visible = False
        lblParm2.Visible = False
        txtParm2.Visible = False
        chkAuditOnly.Visible = False
        txtEmailMessage.Visible = False
        
        Select Case nProcCode
            
            Case "A01"                          '"Reconcile Attachments"
                chkAuditOnly.Visible = True
                
          
            Case "P01"                          '"Move Project"
                lblParm1.Visible = True
                lblParm1.Text = "ProjectID"
                txtParm1.Visible = True
                lblParm2.Visible = True
                lblParm2.Text = "Target College ID:"
                txtParm2.Style.Item("Left") = 435
                txtParm2.Visible = True
                
            Case "C01"                          '"Purge College"
                
                lblParm1.Text = "CollegeID"
                lblParm1.Visible = True
                txtParm1.Visible = True
                
  
            Case "D01"                               '"Purge District"
                lblParm1.Text = "DistrictID"
                lblParm1.Visible = True
                txtParm1.Visible = True
                
            Case "I01"                                  '"Import FRS Reference Tables"
                'do nothing
             
            Case "I02"                                  '"Run FRS Disbursement Import"
                'do nothing
                
            Case "W01"                                  '"Process Workflow Inbox Email Notification"
 
                
            Case "W02"     'Reset Workflow Transaction History and Status for Transaction
                lblParm1.Text = "TransID:"
                lblParm1.Visible = True
                txtParm1.Visible = True
                
            Case "W03"     'Reset Workflow Transaction History and Status for DISTRICT
                lblParm1.Text = "DistrictID:"
                lblParm1.Visible = True
                txtParm1.Visible = True
                
 
            Case "E100"     'Send message to all prompt users
                txtEmailMessage.Visible = True
                chkAuditOnly.Visible = True
                chkAuditOnly.Text = "Test Only (send to tech support only)"
                
                
        End Select
    End Sub
    

  
  
    Protected Sub butRunProc_Click(ByVal sender As Object, ByVal e As System.EventArgs)
        
        Select Case nProcCode
            
            Case "A01"   '"Reconcile Attachments"
                Using rs As New promptSysUtils
                    If chkAuditOnly.Checked Then
                        rs.AuditOnly = True
                    End If
                    rs.RemoveOrphanDirectoriesFromAttachments()
                    rs.CheckAttachmentsForOrphans(Proclib.GetCurrentAttachmentPath())
                    rs.RemoveDeadAttachmentRecords()
                    
                    lblResults.Text = rs.Result
 
                End Using
               
                 
            Case "P01" '"Move Project"
                If Val(txtParm1.Text) > 0 And Val(txtParm2.Text) > 0 Then
                    Using rs As New promptSysUtils
                        rs.MoveProject(txtParm1.Text, txtParm2.Text)
                        lblResults.Text = rs.Result
                    End Using
                    
                End If
                
            Case "C01"   '"Purge College"
                
                If Val(txtParm1.Text) > 0 Then
                    Using rs As New promptSysUtils
                        rs.PurgeCollege(txtParm1.Text)
                    End Using
                    
                    lblResults.Text = "Done."
                End If


                
            Case "D01"   '"Purge District"
                
                If Val(txtParm1.Text) > 0 Then
                    Using rs As New promptSysUtils
                        rs.PurgeDistrict(txtParm1.Text)
                    End Using
                    
                    lblResults.Text = "Done."
                End If
                
            Case "I01"   '"Import FRS Reference Tables"
                
                Using db As New promptWorkflowTransfer
                    db.CallingPage = Page
                    db.ImportFRSCheckMessageCodes()             'get the FRS check message codes and import 
                    db.ImportFRSVendorFile()                    'get the FRS Vendor File and import 
                    db.ImportFRSAccountNumbersFile()            'get the FRS Account Numbers file and import
                    db.ImportFRSPONumbersFile()                 'get the FRS PONumbers file and import
                    db.ImportFRSPONumbersLineItemsFile()        'get the FRS POLineNumbers file and import
                End Using
                lblResults.Text = "Done."
            
            Case "I02"    '"Run FRS Disbursement Import"
                Using db As New promptWorkflowTransfer
                    db.CallingPage = Page
                    db.ImportFRSPaymentDisbursements()     'process nightly FRS disbursements 
                End Using
                lblResults.Text = "Done."
                
            Case "W01"    '"Process Workflow Inbox Email Notification"
                'Notify all the appropriate workflow owners if errors
                Using notify As New promptEmailNotify
                    notify.NotifyUsersOfNewInboxItems(True)    'if true flag then copy sent to tech as well
                End Using
                
            Case "W02"     'Reset Workflow Transaction History and Status
                If txtParm1.Text <> "" Then
                    Using rs As New promptWorkflow
                        rs.ResetWorkflowHistoryAndStatus(txtParm1.Text)
                    End Using
                End If
                lblResults.Text = "Done."
                
            Case "W03"     'Reset Workflow Transaction History and Status for DISTRICT
                If txtParm1.Text <> "" Then
                    Using rs As New promptWorkflow
                        rs.ResetDistrictWorkflowHistoryAndStatus(txtParm1.Text)
                    End Using
                End If
                lblResults.Text = "Done."
                
                
            Case "E100"     'Broadcast Email to all users
                If txtEmailMessage.Text <> "" Then
                    Using db As New promptEmailNotify
                        db.NotifyAllActiveUsers(txtEmailMessage.Text, chkAuditOnly.Checked)
                    End Using
                End If
                lblResults.Text = "Email Sent Successfully."
                
                
            Case "PRERELEASE"    'Pre Release Upgrade Routing -- MULTI USE FOR RUNNING CODE DURING SYSTEM UPGRADES - CHANGES DEPENDING ON RELEASE
               
                If bEnablePreReleaseProceedure Then
                    
                    RunPreReleaseCode()
                    'ImportSJEData()
                    'CreateSJEContractLineItems()
                    'BuildSJEJCAFEntries()
                    'FinalSJEFixOrphanedTransactions()
                    'ConsolodateSJEChangeOrders()
                    
                    lblResults.Text = "Done."
                Else
                    lblResults.Text = "NOT ENABLED!!!"
                End If
                 
            Case Else
                lblResults.Text = "No Proc Found."
                
        End Select

    End Sub
    
    Private Sub RunPreReleaseCode()
        
        Dim sql As String = ""
        Dim tbl As DataTable
        
        
        'Using db As New promptWorkflowTransfer
        '    db.ExportBannerTransactions()
        'End Using
       
        Using db As New PromptDataHelper


            'Update all Contract Line Items with no date to parent contract date if exists, or oldest transaction if exists 
            sql = "SELECT * FROM ContractLineItems WHERE ItemDate IS NULL ORDER BY ContractID "
            db.FillDataTableForUpdate(sql)

            For Each row As DataRow In db.DataTable.Rows
                Dim dItemDate As String = "01/01/2000"
                Dim nContractID As Integer = row("ContractID")

                Dim dContractDate = db.ExecuteScalar("SELECT ContractDate FROM Contracts WHERE ContractID = " & nContractID)
                If Not IsDBNull(dContractDate) Then
                    If IsDate(dContractDate) Then
                        dItemDate = dContractDate
                    End If

                Else            'look for oldest transaction date

                    sql = "SELECT Min(InvoiceDate) FROM Transactions WHERE ContractID = " & nContractID
                    dContractDate = db.ExecuteScalar(sql)
                    If Not IsDBNull(dContractDate) Then
                        If IsDate(dContractDate) Then
                            dItemDate = dContractDate
                        End If
                    End If
                End If

                row("ItemDate") = dItemDate

            Next

            db.SaveDataTableToDB()
            
            
            'Update all Contract Detail Items with no date to parent contract date if exists, or oldest transaction if exists 
            sql = "SELECT * FROM ContractDetail WHERE CreateDate IS NULL ORDER BY ContractID "
            db.FillDataTableForUpdate(sql)

            For Each row As DataRow In db.DataTable.Rows
                Dim dItemDate As String = "01/01/2000"
                Dim nContractID As Integer = row("ContractID")

                Dim dContractDate = db.ExecuteScalar("SELECT ContractDate FROM Contracts WHERE ContractID = " & nContractID)
                If Not IsDBNull(dContractDate) Then
                    If IsDate(dContractDate) Then
                        dItemDate = dContractDate
                    End If

                Else            'look for oldest transaction date

                    sql = "SELECT Min(InvoiceDate) FROM Transactions WHERE ContractID = " & nContractID
                    dContractDate = db.ExecuteScalar(sql)
                    If Not IsDBNull(dContractDate) Then
                        If IsDate(dContractDate) Then
                            dItemDate = dContractDate
                        End If
                    End If
                End If

                row("CreateDate") = dItemDate

            Next

            db.SaveDataTableToDB()
             
 
            ''Update all series ledger accounts with proper bond series number
            'sql = "UPDATE LedgerAccountEntries SET BondSeries = 'A' WHERE LedgerAccountID = 2 OR LedgerAccountID = 4 OR LedgerAccountID = 6 OR LedgerAccountID = 8  OR LedgerAccountID = 51"
            'db.ExecuteNonQuery(sql)

            'sql = "UPDATE LedgerAccountEntries SET BondSeries = 'B' WHERE LedgerAccountID = 3 OR LedgerAccountID = 5 OR LedgerAccountID = 7"
            'db.ExecuteNonQuery(sql)
  
            
            ''Consolodate Dup Invoice Transactions for SJE
            'sql = "SELECT COUNT(TransactionID) AS Invoices, ContractID, InvoiceNumber FROM Transactions "
            'sql &= "WHERE DistrictID = 67 AND TransType = 'Invoice' "
            'sql &= "GROUP BY ContractID, InvoiceNumber "
            'sql &= "ORDER BY Invoices "

            'tbl = db.ExecuteDataTable(sql)
            'For Each row As DataRow In tbl.Rows
            '    If row("Invoices") > 1 Then
            '        Dim sInvNo As String = row("InvoiceNumber")
            '        Dim nContractID As Integer = row("ContractID")

            '        'get that subset to work with 
            '        sql = "SELECT * FROM Transactions WHERE ContractID = " & nContractID & " AND InvoiceNumber = '" & sInvNo & "' "
            '        Dim tblInvoices As DataTable = db.ExecuteDataTable(sql)

            '        'Agregate all the totals and descriptions 

            '        'Get ID of the first row to use as Master
            '        Dim nMasterTransID As Integer = tblInvoices.Rows(0)("TransactionID")
            '        Dim nTotalAmount As Double = 0
            '        Dim sOldComments As String = ""
            '        Dim sNewComments As String = ""
            '        For Each rowTran As DataRow In tblInvoices.Rows
            '            nTotalAmount += rowTran("TotalAmount")
            '            sNewComments &= rowTran("Description") & " (" & rowTran("TotalAmount") & ")" & vbCrLf

            '            Dim sComm As String = rowTran("Comments") & vbCrLf
            '            If Not sOldComments.Contains(sComm) Then
            '                sOldComments &= rowTran("Comments") & vbCrLf
            '            End If

            '            'Dump the trans detail records while we are here
            '            If rowTran("TransactionID") <> nMasterTransID Then
            '                sql = "DELETE FROM TransactionDetail WHERE TransactionID = " & rowTran("TransactionID")
            '                db.ExecuteNonQuery(sql)
            '            End If
            '        Next

            '        sNewComments = sOldComments & vbCrLf & sNewComments
            '        sNewComments = sNewComments.Replace("'", "''")

            '        'Now Update the Master Record with new Information
            '        sql = "UPDATE Transactions SET TotalAmount = " & nTotalAmount & ","
            '        sql &= "PayableAmount = " & nTotalAmount & ","
            '        sql &= "RetentionAmount = 0,"
            '        sql &= "Description = 'Consolodated Transaction From Import (See Transaction Notes)',"
            '        sql &= "Comments = '" & sNewComments & "' "
            '        sql &= "WHERE TransactionID = " & nMasterTransID

            '        db.ExecuteNonQuery(sql)

            '        sql = "UPDATE TransactionDetail SET Amount = " & nTotalAmount & ",PayableAmount = " & nTotalAmount & " WHERE TransactionID = " & nMasterTransID
            '        db.ExecuteNonQuery(sql)

            '        'Now remove the old records
            '        sql = "DELETE FROM Transactions WHERE ContractID = " & nContractID & " AND InvoiceNumber = '" & sInvNo & "' AND TransactionID <> " & nMasterTransID
            '        db.ExecuteNonQuery(sql)


            '        'NOW DEAL WITH THE CONTRACT LINE ITEMS IF THERE ARE MULTIPLE RELATED TO THIS CONTRACT
                    
                    
                    
                    
            'End If

            'Next
            
                
            
            'sql = "SELECT * FROM ObjectCodes "
            'tbl = db.ExecuteDataTable(sql)
            'For Each row As DataRow In tbl.Rows
            '    Dim sDescr As String = Trim(ProcLib.CheckNullDBField(row("ObjectCodeDescription")))
            '    Dim sObjectCode As String = Trim(ProcLib.CheckNullDBField(row("ObjectCode")))
            '    Dim nDistrict As Integer = row("DistrictID")

            '    sql = "UPDATE BudgetObjectCodes SET Description = '" & sObjectCode & " - " & sDescr & "' WHERE ObjectCode = '" & sObjectCode & "' AND DistrictID = " & nDistrict
            '    db.ExecuteNonQuery(sql)

            '    sql = "UPDATE ContractLineItems SET LineObjectCodeDescription = '" & sObjectCode & " - " & sDescr & "' WHERE ObjectCode = '" & sObjectCode & "' AND DistrictID = " & nDistrict
            '    db.ExecuteNonQuery(sql)

            '    sql = "UPDATE BudgetObjectCodeEstimates SET Description = '" & sDescr & "' WHERE ObjectCode = '" & sObjectCode & "' AND DistrictID = " & nDistrict
            '    db.ExecuteNonQuery(sql)



            'Next

        End Using



    End Sub
    
    'Private Sub ConsolodateSJEChangeOrders()

    '    Dim sql As String = ""
    '    Dim tbl As DataTable

    '    Using db As New PromptDataHelper

    '        sql = "DELETE FROM Transactions WHERE DistrictID=67 AND TransType='ADJ' "
    '        db.ExecuteNonQuery(sql)

    '        sql = "DELETE FROM ContractLineItems WHERE DistrictID=67 AND LastUpdateBy='SJEImportConsolodation' "
    '        db.ExecuteNonQuery(sql)

    '        sql = "DELETE FROM ContractDetail WHERE DistrictID=67 AND LastUpdateBy='SJEImportConsolodation' "
    '        db.ExecuteNonQuery(sql)

    '        sql = "DELETE FROM TransactionDetail WHERE DistrictID=67 AND LastUpdateBy='SJEImportConsolodation' "
    '        db.ExecuteNonQuery(sql)

    '        'sql = "UPDATE ContractLineItems SET DistrictID=67 WHERE DistrictID = -99"
    '        'db.ExecuteNonQuery(sql)

    '        'sql = "UPDATE ContractLineItems SET ContractID = ContractID - 6700 WHERE DistrictID = 67 AND LineType = 'Adjustment' "
    '        'db.ExecuteNonQuery(sql)




    '        sql = "SELECT  CollegeID,ContractID, SUM(Amount) AS Amount,"
    '        sql &= "(SELECT     SUM(Amount) AS Expr1 FROM TransactionDetail "
    '        sql &= "WHERE  ContractLineItems.ContractID = ContractID) AS Expenses "
    '        sql &= "FROM ContractLineItems WHERE DistrictID = 67 "
    '        sql &= "GROUP BY CollegeID,ContractID "
    '        tbl = db.ExecuteDataTable(sql)
    '        For Each row As DataRow In tbl.Rows
    '            'get only those with a balance <> 0
    '            If ProcLib.CheckNullNumField(row("Amount")) <> ProcLib.CheckNullNumField(row("Expenses")) Then

    '                Dim nCollegeID As Integer = 0

    '                sql = "SELECT * FROM Transactions WHERE DistrictID = 999"
    '                db.FillDataTableForUpdate(sql)

    '                'create transactions from each of the AD records

    '                Dim dEarliestDate As String = ""

    '                sql = "SELECT * FROM ContractLineItems WHERE ContractID = " & row("ContractID") & " AND LineType = 'Adjustment' ORDER BY ItemDate"
    '                Dim tblCLs As DataTable = db.ExecuteDataTable(sql)
    '                For Each rowcl As DataRow In tblCLs.Rows

    '                    If dEarliestDate = "" Then
    '                        dEarliestDate = rowcl("ItemDate")
    '                        nCollegeID = rowcl("CollegeID")
    '                    End If

    '                    Dim sOCJCAFAcct As String = rowcl("ObjectCode") & rowcl("JCAFCellName") & rowcl("AccountNumber")  'to store in comments for later

    '                    Dim newrow As DataRow = db.DataTable.NewRow

    '                    newrow("DistrictID") = 67
    '                    newrow("ContractID") = rowcl("ContractID")

    '                    newrow("ProjectID") = rowcl("ProjectID")
    '                    newrow("TransType") = "ADJ"

    '                    newrow("DateReceived") = rowcl("ItemDate")
    '                    newrow("CreationDate") = rowcl("ItemDate")
    '                    newrow("InvoiceDate") = rowcl("ItemDate")
    '                    newrow("DatePaid") = rowcl("ItemDate")

    '                    newrow("Description") = rowcl("Description")
    '                    newrow("Comments") = sOCJCAFAcct

    '                    newrow("TotalAmount") = rowcl("Amount")
    '                    newrow("PayableAmount") = rowcl("Amount")
    '                    newrow("RetentionAmount") = 0
    '                    newrow("Reimbursable") = 0
    '                    newrow("TaxAdjustmentAmount") = 0

    '                    newrow("Accrual") = 0

    '                    newrow("AccountNumber") = rowcl("AccountNumber")
    '                    newrow("Status") = "Paid"

    '                    newrow("ContractorID") = 0


    '                    newrow("LastUpdateBy") = "SJEImport"
    '                    newrow("LastUpdateOn") = Now()

    '                    db.DataTable.Rows.Add(newrow)

    '                Next

    '                db.SaveDataTableToDB()

    '                'Consolodate all the CL Adjustments into a single Change Order
    '                'create transactions from each of the AD records
    '                sql = "SELECT * FROM ContractLineItems WHERE DistrictID = 67 "
    '                db.FillDataTableForUpdate(sql)

    '                sql = "SELECT ProjectID,ContractID, SUM(Amount) AS Amount, ObjectCode, JCAFCellName, AccountNumber "
    '                sql &= "FROM ContractLineItems WHERE DistrictID = 67 AND LineType = 'Adjustment' AND ContractID = " & row("ContractID") & " "
    '                sql &= "GROUP BY ProjectID,ContractID, ObjectCode, JCAFCellName, AccountNumber "
    '                sql &= "ORDER BY ProjectID,ContractID, ObjectCode, JCAFCellName, AccountNumber"
    '                tbl = db.ExecuteDataTable(sql)


    '                For Each rowcl As DataRow In tbl.Rows

    '                    Dim newrow As DataRow = db.DataTable.NewRow

    '                    newrow("DistrictID") = 67
    '                    newrow("ContractID") = rowcl("ContractID")
    '                    newrow("ContractChangeOrderID") = 0
    '                    newrow("ProjectID") = rowcl("ProjectID")
    '                    newrow("CollegeID") = nCollegeID
    '                    newrow("LineType") = "ChangeOrder"

    '                    newrow("ItemDate") = dEarliestDate

    '                    newrow("AccountNumber") = rowcl("AccountNumber")
    '                    newrow("JCAFCellName") = rowcl("JCAFCellName")
    '                    newrow("ObjectCode") = rowcl("ObjectCode")

    '                    newrow("Description") = "JE Entries from Import"

    '                    newrow("Amount") = rowcl("Amount")
    '                    newrow("Reimbursable") = 0

    '                    newrow("LastUpdateBy") = "SJEImportConsolodation"
    '                    newrow("LastUpdateOn") = Now()

    '                    'Get the JCAF Info 
    '                    Dim sOCJCAFAcct As String = rowcl("ObjectCode") & rowcl("JCAFCellName") & rowcl("AccountNumber")
    '                    For Each roworg As DataRow In tblCLs.Rows
    '                        Dim sOCJCAFAcctORG As String = roworg("ObjectCode") & roworg("JCAFCellName") & roworg("AccountNumber")
    '                        If sOCJCAFAcctORG = sOCJCAFAcct Then
    '                            newrow("JCAFCellNameObjectCode") = roworg("JCAFCellNameObjectCode")
    '                            newrow("JCAFLine") = roworg("JCAFLine")
    '                            newrow("LineObjectCodeDescription") = roworg("LineObjectCodeDescription")
    '                            Exit For
    '                        End If
    '                    Next

    '                    db.DataTable.Rows.Add(newrow)

    '                Next

    '                db.SaveDataTableToDB()

    '            End If
    '        Next


    '        'Create Contract DEtail REcords
    '        sql = "SELECT * FROM ContractDetail WHERE DistrictID = 67 "
    '        db.FillDataTableForUpdate(sql)

    '        sql = "SELECT * FROM ContractLineItems WHERE DistrictID = 67 AND LineType = 'ChangeOrder' "
    '        tbl = db.ExecuteDataTable(sql)

    '        For Each rowcl As DataRow In tbl.Rows

    '            Dim newrow As DataRow = db.DataTable.NewRow

    '            newrow("DistrictID") = 67
    '            newrow("ProjectID") = rowcl("ProjectID")
    '            newrow("ContractID") = rowcl("ContractID")

    '            newrow("CreateDate") = rowcl("ItemDate")
    '            newrow("DistrictApprovalDate") = rowcl("ItemDate")
    '            newrow("DetailType") = "ChangeOrder"
    '            newrow("Description") = "JE Entries from Import"

    '            newrow("Amount") = rowcl("Amount")

    '            newrow("GlobalContractDetailID") = rowcl("LineID")    'temporary storage for updating contractdetailID in line items after add

    '            newrow("LastUpdateBy") = "SJEImportConsolodation"
    '            newrow("LastUpdateOn") = Now()

    '            db.DataTable.Rows.Add(newrow)

    '        Next

    '        db.SaveDataTableToDB()


    '        'Now link the CO to the line item
    '        sql = "SELECT * FROM ContractDetail WHERE DistrictID = 67 "
    '        Dim tblCO As DataTable = db.ExecuteDataTable(sql)

    '        sql = "SELECT * FROM ContractLineItems WHERE DistrictID = 67 AND LineType = 'ChangeOrder' "
    '        db.FillDataTableForUpdate(sql)

    '        For Each rowcl As DataRow In db.DataTable.Rows
    '            For Each rowxx As DataRow In tblCO.Rows
    '                If rowcl("LineID") = rowxx("GlobalContractDetailID") Then
    '                    rowcl("ContractChangeOrderID") = rowxx("ContractDetailID")

    '                    Exit For
    '                End If
    '            Next
    '        Next

    '        db.SaveDataTableToDB()


    '        'Now link the CO to the line item

    '        sql = "SELECT * FROM ContractLineItems WHERE DistrictID = 67 AND LineType = 'ChangeOrder'  "
    '        Dim tblCLI As DataTable = db.ExecuteDataTable(sql)

    '        sql = "SELECT * FROM TransactionDetail WHERE DistrictID = 67 "
    '        db.FillDataTableForUpdate(sql)

    '        For Each rowcli As DataRow In tblCLI.Rows
    '            Dim nLineID As Integer = rowcli("LineID")
    '            Dim sOCJCAFAcctORG As String = rowcli("ObjectCode") & rowcli("JCAFCellName") & rowcli("AccountNumber")

    '            'get any transactions associated
    '            sql = "SELECT * FROM Transactions WHERE ContractID = " & rowcli("ContractID") & " AND Comments = '" & sOCJCAFAcctORG & "' AND TransType = 'ADJ'"
    '            Dim tblTrans As DataTable = db.ExecuteDataTable(sql)
    '            For Each rowtrans As DataRow In tblTrans.Rows

    '                Dim newrow As DataRow = db.DataTable.NewRow

    '                newrow("DistrictID") = 67
    '                newrow("ProjectID") = rowcli("ProjectID")
    '                newrow("ContractID") = rowcli("ContractID")
    '                newrow("ContractLineItemID") = nLineID
    '                newrow("TransactionID") = rowtrans("TransactionID")

    '                newrow("BudgetLineName") = rowcli("JCAFCellName")

    '                newrow("Amount") = rowtrans("TotalAmount")
    '                newrow("PayableAmount") = rowtrans("PayableAmount")


    '                newrow("LastUpdateBy") = "SJEImportConsolodation"
    '                newrow("LastUpdateOn") = Now()

    '                db.DataTable.Rows.Add(newrow)

    '            Next
    '        Next

    '        db.SaveDataTableToDB()


    '        sql = "UPDATE ContractDetail SET DetailType = 'Change Order' WHERE DetailType = 'ChangeOrder' AND DistrictID = 67"
    '        db.ExecuteNonQuery(sql)


    '        'move out the existing adjustments
    '        sql = "DELETE FROM ContractLineItems WHERE DistrictID = 67 AND LineType = 'Adjustment' "
    '        db.ExecuteNonQuery(sql)



    '        'Fix Object Code Descriptions
    '        sql = "SELECT * FROM ObjectCodes WHERE DistrictID =  67"
    '        tbl = db.ExecuteDataTable(sql)
    '        For Each row As DataRow In tbl.Rows
    '            Dim sDescr As String = Trim(ProcLib.CheckNullDBField(row("ObjectCodeDescription")))
    '            Dim sObjectCode As String = Trim(ProcLib.CheckNullDBField(row("ObjectCode")))
    '            Dim nDistrict As Integer = row("DistrictID")

    '            sql = "UPDATE BudgetObjectCodes SET Description = '" & sObjectCode & " - " & sDescr & "' WHERE ObjectCode = '" & sObjectCode & "' AND DistrictID = 67"
    '            db.ExecuteNonQuery(sql)

    '            sql = "UPDATE ContractLineItems SET LineObjectCodeDescription = '" & sObjectCode & " - " & sDescr & "' WHERE ObjectCode = '" & sObjectCode & "' AND DistrictID = 67"
    '            db.ExecuteNonQuery(sql)


    '        Next



    '    End Using


    'End Sub

    'Private Sub ImportSJEData()

    '    Using db As New PromptDataHelper

    '        'Imports San Jose Evergreen Transaction Data
    '        Dim sql As String = ""
    '        Dim tblImport As DataTable
    '        Dim tblContracts As DataTable

    '        'Load the working Table
    '        Dim sFileName As String = "sjeupload.txt"

    '        'REmove any existing data where appropriate
    '        sql = "DELETE FROM SJEImportTemp"
    '        db.ExecuteNonQuery(sql)

    '        'Open the existing table
    '        sql = "SELECT * FROM SJEImportTemp"
    '        db.FillDataTableForUpdate(sql)
    '        tblImport = db.DataTable
    '        Dim sFilePath As String = ProcLib.GetCurrentAttachmentPath
    '        Dim dDir As New DirectoryInfo(sFilePath)

    '        'Open the imported file
    '        Dim iline As Integer = 1
    '        Dim isavecount As Integer = 0
    '        For Each f As FileSystemInfo In dDir.GetFileSystemInfos
    '            If f.Name = sFileName Then   'file is there

    '                Dim objReader As New StreamReader(f.FullName)


    '                Dim sLine As String = objReader.ReadLine   'read the first line into the string

    '                While Not sLine Is Nothing   'loop through the file till the end

    '                    'skip first two lines
    '                    If iline > 2 Then
    '                        Dim vals() As String = sLine.Split(vbTab)
    '                        Dim newrow = tblImport.NewRow

    '                        Dim iTarget As Integer = 1
    '                        For isource As Integer = 1 To 29
    '                            If isource = 20 Or isource = 28 Then   'skip col 20 in source
    '                                isource += 1
    '                            End If
    '                            newrow(iTarget) = Trim(vals(isource))
    '                            iTarget += 1
    '                        Next

    '                        If newrow("ProjectNumber") <> "" Then
    '                            tblImport.Rows.Add(newrow)
    '                        End If


    '                    End If

    '                    iline += 1
    '                    isavecount += 1

    '                    sLine = objReader.ReadLine

    '                    'If iline > 10 Then Exit While

    '                End While
    '                db.SaveDataTableToDB()


    '            End If
    '        Next

    '        'Exit Sub

    '        'Clean Up  import file
    '        sql = "SELECT * FROM SJEImportTemp "
    '        db.FillDataTableForUpdate(sql)
    '        tblImport = db.DataTable

    '        Dim sLastContact As String = ""
    '        For Each row As DataRow In tblImport.Rows

    '            Dim sVendor As String = Trim(ProcLib.CheckNullDBField(row("Vendor")))
    '            Dim sVendorNumber As String = Trim(ProcLib.CheckNullDBField(row("VendorNumber")))
    '            Dim sAmt As String = Trim(ProcLib.CheckNullDBField(row("Amount")))
    '            Dim sPOComment As String = Trim(ProcLib.CheckNullDBField(row("POComment")))
    '            Dim sItemDescription As String = Trim(ProcLib.CheckNullDBField(row("ItemDescription")))

    '            Dim sJCAFRow As String = Trim(ProcLib.CheckNullDBField(row("JCAFRow")))
    '            Dim sJCAFFundingSource As String = Trim(ProcLib.CheckNullDBField(row("JCAFFundingSource")))

    '            If sVendor = "" Then
    '                sVendor = "-none-"
    '            End If

    '            If sVendorNumber = "" Then
    '                sVendorNumber = "999999"
    '            End If

    '            sVendor = sVendor.Replace(Chr(34), "")
    '            sAmt = sAmt.Replace(Chr(34), "")
    '            sPOComment = sPOComment.Replace(Chr(34), "")
    '            sItemDescription = sItemDescription.Replace(Chr(34), "")

    '            row("Vendor") = sVendor
    '            row("VendorNumber") = sVendorNumber
    '            row("Amount") = sAmt

    '            Dim nNewAmount As Double = sAmt
    '            row("NewAmount") = nNewAmount

    '            row("POComment") = sPOComment
    '            row("ItemDescription") = sItemDescription



    '            Dim sCell As String = ""
    '            'Set the JCAFCellName Based on JCAF Funding Source and JCAF Row
    '            Select Case sJCAFRow & sJCAFFundingSource

    '                Case "10State"

    '                    sCell = "FurnGroup2SF"

    '                Case "3EBond"

    '                    sCell = "WorkDrawBond_E"

    '                Case "OtherBond"
    '                    sCell = "OtherBond"

    '                Case "4FState"
    '                    sCell = "ConstrSF_F"

    '                Case "4DBond"
    '                    sCell = "ConstrBond_D"

    '                Case "7BState"
    '                    sCell = "TestsSF_B"

    '                Case "3CBond"
    '                    sCell = "WorkDrawBond_C"

    '                Case "7AState"
    '                    sCell = "TestsSF_A"

    '                Case "3AState"
    '                    sCell = "WorkDrawSF_A"

    '                Case "7ABond"
    '                    sCell = "TestsBond_A"

    '                Case "3ABond"
    '                    sCell = "WorkDrawBond_A"

    '                Case "4FBond"
    '                    sCell = "ConstrBond_F"

    '                Case "7BBond"
    '                    sCell = "TestsBond_B"

    '                Case "4DState"
    '                    sCell = "ConstrSF_D"

    '                Case "OtherState"
    '                    sCell = "OtherSF"

    '                Case "3CState"
    '                    sCell = "WorkDrawSF_C"

    '                Case "10Bond"
    '                    sCell = "FurnGroupBond"

    '                Case Else

    '                    sCell = "NOT FOUND"


    '            End Select

    '            row("JCAFCellName") = sCell




    '        Next

    '        db.SaveDataTableToDB()


    '        'Remove company contacts for this district except historical
    '        sql = "DELETE FROM Contacts WHERE DistrictID = 67 AND ContactType = 'Company' AND Name <> 'Historical Data'"
    '        db.ExecuteNonQuery(sql)

    '        sql = "SELECT DISTINCT Vendor,VendorNumber FROM SJEImportTemp ORDER BY Vendor "
    '        Dim tblvendorsSource As DataTable = db.ExecuteDataTable(sql)

    '        sql = "SELECT * FROM Contacts WHERE DistrictID = 0"
    '        db.FillDataTableForUpdate(sql)

    '        For Each row In tblvendorsSource.Rows
    '            Dim newrow As DataRow = db.DataTable.NewRow

    '            newrow("DistrictID") = 67
    '            newrow("ContactType") = "Company"
    '            newrow("Name") = row("Vendor")
    '            newrow("DistrictContractorID") = row("VendorNumber")
    '            newrow("LastUpdateBy") = "SJEImport"
    '            newrow("LastUpdateOn") = Now()

    '            If newrow("Name") <> "" Then
    '                db.DataTable.Rows.Add(newrow)
    '            End If


    '        Next
    '        db.SaveDataTableToDB()


    '        'Update Import File with Project Info and Vendor Info
    '        sql = "SELECT DISTINCT Projects.ProjectID, Projects.DistrictID, Projects.CollegeID, Projects.ProjectNumber "
    '        sql &= "FROM         Projects RIGHT OUTER JOIN  SJEImportTemp ON Projects.ProjectNumber = SJEImportTemp.ProjectNumber "
    '        sql &= "    WHERE Projects.DistrictID = 67"
    '        Dim tblProjectMaster As DataTable = db.ExecuteDataTable(sql)
    '        'Update Project info
    '        For Each rowProject As DataRow In tblProjectMaster.Rows
    '            sql = "UPDATE SJEImportTemp SET DistrictID = 67,CollegeID = " & rowProject("CollegeID") & ",ProjectID = " & rowProject("ProjectID") & " "
    '            sql &= "WHERE ProjectNumber = '" & rowProject("ProjectNumber") & "' "
    '            db.ExecuteNonQuery(sql)
    '        Next


    '        'Update CompanyInfo
    '        sql = "SELECT * FROM Contacts WHERE DistrictID = 67 AND ContactType = 'Company'"
    '        Dim tblCompanyMaster As DataTable = db.ExecuteDataTable(sql)
    '        sql = "SELECT * FROM SJEImportTemp "
    '        db.FillDataTableForUpdate(sql)
    '        For Each row As DataRow In db.DataTable.Rows
    '            For Each rowC As DataRow In tblCompanyMaster.Rows
    '                If ProcLib.CheckNullDBField(rowC("Name")) = ProcLib.CheckNullDBField(row("Vendor")) Then
    '                    row("CompanyContactID") = rowC("ContactID")
    '                    Exit For
    '                End If
    '            Next

    '        Next
    '        db.SaveDataTableToDB()

    '        'Add Missing Object Codes to Object Codes Table
    '        sql = "SELECT DISTINCT(ObjectCode) FROM SJEImportTemp "
    '        tblImport = db.ExecuteDataTable(sql)


    '        sql = "SELECT ObjectCode FROM ObjectCodes WHERE DistrictID = 67 "
    '        Dim tblOCRef As DataTable = db.ExecuteDataTable(sql)

    '        sql = "SELECT * FROM ObjectCodes WHERE DistrictID = 67"
    '        db.FillDataTableForUpdate(sql)
    '        For Each Row As DataRow In tblImport.Rows
    '            Dim bFound As Boolean = False
    '            For Each rowref As DataRow In tblOCRef.Rows
    '                If ProcLib.CheckNullDBField(rowref("ObjectCode")) = ProcLib.CheckNullDBField(Row("ObjectCode")) Then
    '                    bFound = True
    '                    Exit For
    '                End If
    '            Next

    '            If Not bFound Then
    '                Dim newrow As DataRow = db.DataTable.NewRow
    '                newrow("DistrictID") = 67
    '                newrow("ObjectCode") = Row("ObjectCode")
    '                newrow("ObjectCodeDescription") = "--No Description --"
    '                newrow("LastUpdateBy") = "SJEImport"

    '                db.DataTable.Rows.Add(newrow)
    '            End If

    '        Next
    '        db.SaveDataTableToDB()





    '        'Generate Contracts From the Data for all the Not Null project IDs

    '        sql = "DELETE FROM Contracts WHERE LastUpdateBy = 'SJEImport'"
    '        db.ExecuteNonQuery(sql)

    '        sql = "SELECT DISTINCT CompanyContactID, ProjectID, CollegeID,ContractDescription "
    '        sql &= "FROM SJEImportTemp WHERE ProjectID Is Not NULL ORDER BY CollegeID, ProjectID,CompanyContactID,ContractDescription "
    '        tblImport = db.ExecuteDataTable(sql)

    '        sql = "SELECT * FROM Contracts "
    '        db.FillDataTableForUpdate(sql)
    '        For Each row As DataRow In tblImport.Rows
    '            Dim newrow As DataRow = db.DataTable.NewRow

    '            newrow("DistrictID") = 67
    '            newrow("ProjectID") = row("ProjectID")
    '            newrow("CollegeID") = row("CollegeID")
    '            newrow("ContractorID") = row("CompanyContactID")
    '            'newrow("AccountNumber") = row("GLAccountNo")

    '            newrow("ContractType") = "Contract"
    '            newrow("PayStatus") = "Ok To Pay"
    '            newrow("Amount") = 0
    '            newrow("ReimbAmount") = 0
    '            newrow("Description") = Trim(ProcLib.CheckNullDBField(row("ContractDescription")))

    '            newrow("Status") = "2-Closed"
    '            newrow("RetentionPercent") = 10

    '            newrow("LastUpdateBy") = "SJEImport"
    '            newrow("LastUpdateOn") = Now

    '            db.DataTable.Rows.Add(newrow)

    '        Next
    '        db.SaveDataTableToDB()



    '        'Now update the import data with new contract ID
    '        sql = "SELECT * FROM Contracts WHERE DistrictID = 67 "
    '        tblContracts = db.ExecuteDataTable(sql)

    '        For Each Row As DataRow In tblContracts.Rows
    '            sql = "UPDATE SJEImportTemp SET ContractID = " & Row("ContractID") & " "
    '            sql &= "WHERE CompanyContactID = " & Row("ContractorID") & " AND ContractDescription = '" & Row("Description") & "' AND "
    '            sql &= "ProjectID = " & Row("ProjectID")
    '            db.ExecuteNonQuery(sql)
    '        Next

    '    End Using

    'End Sub


    'Private Sub CreateSJEContractLineItems()

    '    Using db As New PromptDataHelper
    '        Dim sql As String = ""
    '        Dim tblContracts As DataTable
    '        Dim tblImport As DataTable

    '        'Now Original Contract Line Items for each entry
    '        Sql = "DELETE FROM ContractLineItems WHERE LastUpdateBy = 'SJEImport'"
    '        db.ExecuteNonQuery(Sql)

    '        Sql = "SELECT * FROM Contracts WHERE DistrictID = 67 "
    '        Dim tblContractRef As DataTable = db.ExecuteDataTable(Sql)

    '        db.FillDataTableForUpdate("SELECT * FROM ContractLineItems ")

    '        Sql = "SELECT ContractID, SUM(NewAmount) AS ContractTotal, ObjectCode, GLAccountNo, JCAFCellName "
    '        Sql &= "FROM SJEImportTemp WHERE ContractID IS NOT NULL AND EntryType <> 'JE' "
    '        Sql &= "GROUP BY ContractID, ObjectCode,GLAccountNo, JCAFCellName ORDER BY ContractID, ObjectCode,GLAccountNo,JCAFCellName"
    '        tblContracts = db.ExecuteDataTable(Sql)
    '        For Each Row As DataRow In tblContracts.Rows

    '            Dim nContractID As Integer = Row("ContractID")
    '            Dim newrow As DataRow = db.DataTable.NewRow

    '            newrow("ContractID") = nContractID
    '            newrow("ContractChangeOrderID") = 0
    '            newrow("LineType") = "Contract"
    '            newrow("Description") = "Contract Amount(" & Row("GLAccountNo") & ")"
    '            newrow("Amount") = Row("ContractTotal")

    '            newrow("Reimbursable") = 0
    '            newrow("POLineNumber") = 1
    '            newrow("ObjectCode") = Row("ObjectCode")
    '            newrow("JCAFCellName") = Row("JCAFCellName")

    '            newrow("AccountNumber") = Row("GLAccountNo")

    '            newrow("LastUpdateBy") = "SJEImport"
    '            newrow("LastUpdateOn") = Now()

    '            'Update the other contract info
    '            For Each rowref As DataRow In tblContractRef.Rows
    '                If rowref("ContractID") = nContractID Then

    '                    newrow("CollegeID") = rowref("CollegeID")
    '                    newrow("ProjectID") = rowref("ProjectID")
    '                    newrow("DistrictID") = rowref("DistrictID")
    '                    'newrow("AccountNumber") = rowref("AccountNumber")

    '                    Exit For
    '                End If
    '            Next

    '            db.DataTable.Rows.Add(newrow)


    '        Next
    '        db.SaveDataTableToDB()

    '        'Add journal Entries for each Contract to Line Items
    '        sql = "SELECT * FROM Contracts WHERE DistrictID = 67 "
    '        tblContractRef = db.ExecuteDataTable(sql)

    '        db.FillDataTableForUpdate("SELECT * FROM ContractLineItems ")

    '        sql = "SELECT * FROM SJEImportTemp WHERE ContractID IS NOT NULL AND EntryType = 'JE' "
    '        sql &= "ORDER BY ContractID,VoucherDate "
    '        tblContracts = db.ExecuteDataTable(sql)
    '        For Each Row As DataRow In tblContracts.Rows

    '            Dim nContractID As Integer = Row("ContractID")
    '            Dim newrow As DataRow = db.DataTable.NewRow

    '            newrow("ContractID") = nContractID
    '            newrow("ContractChangeOrderID") = 0
    '            newrow("LineType") = "Adjustment"
    '            newrow("Description") = ProcLib.CheckNullDBField(Row("ItemDescription"))
    '            newrow("Amount") = Row("NewAmount")

    '            newrow("ItemDate") = Row("VoucherDate")

    '            newrow("Reimbursable") = 0
    '            newrow("POLineNumber") = 0
    '            newrow("ObjectCode") = Row("ObjectCode")
    '            newrow("JCAFCellName") = Row("JCAFCellName")

    '            newrow("AccountNumber") = Row("GLAccountNo")

    '            newrow("LastUpdateBy") = "SJEImport"
    '            newrow("LastUpdateOn") = Now()

    '            'Update the other contract info
    '            For Each rowref As DataRow In tblContractRef.Rows
    '                If rowref("ContractID") = nContractID Then

    '                    newrow("CollegeID") = rowref("CollegeID")
    '                    newrow("ProjectID") = rowref("ProjectID")
    '                    newrow("DistrictID") = rowref("DistrictID")

    '                    Exit For
    '                End If
    '            Next

    '            db.DataTable.Rows.Add(newrow)


    '        Next
    '        db.SaveDataTableToDB()




    '        'Final Cleanup of JCAF Line Description in ContractLineItems

    '        Sql = "SELECT ContractLineItems.LineID, BudgetFieldsTable.JCAFSection, "
    '        Sql &= "BudgetFieldsTable.JCAFLine, ObjectCodes.ObjectCodeDescription, ObjectCodes.ObjectCode "
    '        Sql &= "FROM  ObjectCodes INNER JOIN ContractLineItems ON ObjectCodes.DistrictID = ContractLineItems.DistrictID AND ObjectCodes.ObjectCode = ContractLineItems.ObjectCode "
    '        Sql &= " INNER JOIN BudgetFieldsTable ON ContractLineItems.JCAFCellName = BudgetFieldsTable.ColumnName "

    '        tblImport = db.ExecuteDataTable(Sql)

    '        db.FillDataTableForUpdate("SELECT * FROM ContractLineItems WHERE DistrictID = 67 ")
    '        For Each row As DataRow In db.DataTable.Rows
    '            For Each rowoc As DataRow In tblImport.Rows
    '                If rowoc("LineID") = row("LineID") Then

    '                    Dim sSection As String = rowoc("JCAFSection")
    '                    If sSection.Contains("5. Contingency") Then    'Remove redundancy/dirty description in master table (legacy)
    '                        row("JCAFLine") = sSection

    '                    ElseIf sSection.Contains("Furniture/Group II") Then
    '                        row("JCAFLine") = sSection

    '                    ElseIf sSection = "Other" Then
    '                        row("JCAFLine") = sSection


    '                    Else
    '                        row("JCAFLine") = sSection & " - " & rowoc("JCAFLine")
    '                    End If

    '                    Exit For
    '                End If

    '            Next
    '        Next
    '        db.SaveDataTableToDB()


    '        'FIX ObjectCodeLine field in ContractLine Items
    '        Sql = "SELECT * FROM ContractLineItems WHERE DistrictID = 67"
    '        db.FillDataTableForUpdate(Sql)
    '        For Each Row As DataRow In db.DataTable.Rows
    '            If Not IsDBNull(Row("ObjectCode")) And Not IsDBNull(Row("JCAFCellName")) Then
    '                Row("JCAFCellNameObjectCode") = Row("JCAFCellName") & "::" & Row("ObjectCode")
    '            End If
    '        Next
    '        db.SaveDataTableToDB()

    '        'FIX Contract Total Amount from ContractLine Items
    '        Sql = "SELECT SUM(Amount) as ContractTotal, ContractID FROM ContractLineItems WHERE DistrictID = 67 "
    '        Sql &= " GROUP BY ContractID "
    '        tblContractRef = db.ExecuteDataTable(Sql)

    '        Sql = "SELECT * FROM Contracts WHERE DistrictID = 67 "
    '        db.FillDataTableForUpdate(Sql)
    '        For Each Row As DataRow In db.DataTable.Rows
    '            Dim nContractID As Integer = Row("ContractID")

    '            For Each rowref As DataRow In tblContractRef.Rows
    '                If rowref("ContractID") = nContractID Then
    '                    Row("Amount") = rowref("ContractTotal")
    '                End If
    '            Next

    '        Next
    '        db.SaveDataTableToDB()

    '    End Using
    'End Sub

    'Private Sub BuildSJEJCAFEntries()

    '    Using db As New PromptDataHelper
    '        Dim sql As String = ""
    '        Dim tblContractRef As DataTable

    '        'Create JCAF Entries for all the CLItems
    '        Sql = "DELETE FROM BudgetObjectCodes WHERE LastUpdateBy = 'SJEImport'"
    '        db.ExecuteNonQuery(Sql)

    '        Sql = "SELECT SUM(Amount) AS LineTotal,JCAFCellName, ObjectCode, ProjectID, CollegeID "
    '        sql &= "FROM ContractLineItems WHERE DistrictID = 67 AND JCAFCellName <> 'OtherOther_Donation' "
    '        Sql &= "GROUP BY JCAFCellName,ObjectCode, ProjectID,CollegeID"
    '        tblContractRef = db.ExecuteDataTable(Sql)

    '        Sql = "SELECT * FROM BudgetObjectCodes WHERE DistrictID = 67"
    '        db.FillDataTableForUpdate(Sql)
    '        For Each Row As DataRow In tblContractRef.Rows

    '            Dim newrow As DataRow = db.DataTable.NewRow

    '            newrow("DistrictID") = 67
    '            newrow("CollegeID") = Row("CollegeID")
    '            newrow("ProjectID") = Row("ProjectID")
    '            newrow("LedgerAccountID") = 0

    '            newrow("ObjectCode") = Trim(Row("ObjectCode"))
    '            newrow("JCAFColumnName") = Trim(Row("JCAFCellName"))

    '            newrow("Amount") = Row("LineTotal")
    '            newrow("Notes") = "From SJE Import"

    '            newrow("LastUpdateOn") = Now()
    '            newrow("LastUpdateBy") = "SJEImport"

    '            db.DataTable.Rows.Add(newrow)

    '        Next
    '        db.SaveDataTableToDB()


    '        'Create JCAF Entries for all the CLItems
    '        Sql = "DELETE FROM BudgetItems WHERE LastUpdateBy = 'SJEImport'"
    '        db.ExecuteNonQuery(Sql)

    '        Sql = "SELECT SUM(Amount) AS LineTotal,JCAFCellName,  ProjectID, CollegeID "
    '        sql &= "FROM ContractLineItems WHERE DistrictID = 67 AND JCAFCellName <> 'OtherOther_Donation' "
    '        Sql &= "GROUP BY JCAFCellName, ProjectID,CollegeID"
    '        Dim tblContractLineRef As DataTable = db.ExecuteDataTable(Sql)


    '        Sql = "SELECT * FROM BudgetItems WHERE DistrictID = 67"
    '        db.FillDataTableForUpdate(Sql)
    '        For Each Row As DataRow In tblContractLineRef.Rows

    '            Dim bfound As Boolean = False

    '            For Each rowJcaf As DataRow In db.DataTable.Rows
    '                If rowJcaf("ProjectID") = Row("ProjectID") And rowJcaf("CollegeID") = Row("CollegeID") And rowJcaf("BudgetField") = Row("JCAFCellName") Then   'line already exists

    '                    rowJcaf("Amount") = rowJcaf("Amount") + Row("LineTotal")

    '                    bfound = True
    '                    Exit For

    '                End If


    '            Next

    '            If Not bfound Then

    '                Dim newrow As DataRow = db.DataTable.NewRow

    '                newrow("DistrictID") = 67
    '                newrow("CollegeID") = Row("CollegeID")
    '                newrow("ProjectID") = Row("ProjectID")

    '                newrow("BudgetField") = Row("JCAFCellName")

    '                newrow("Amount") = Row("LineTotal")
    '                newrow("Note") = "From SJE Import"

    '                newrow("LastUpdateOn") = Now()
    '                newrow("LastUpdateBy") = "SJEImport"

    '                db.DataTable.Rows.Add(newrow)

    '            End If




    '        Next
    '        db.SaveDataTableToDB()

    '        ''FIX ObjectCode Descriptions in BudgetObjectCodeTable
    '        Sql = "SELECT * FROM ObjectCodes WHERE DistrictID = 67"
    '        Dim tblObjectCodes As DataTable = db.ExecuteDataTable(Sql)

    '        Sql = "SELECT * FROM BudgetObjectCodes WHERE DistrictID = 67"
    '        db.FillDataTableForUpdate(Sql)

    '        For Each Row As DataRow In db.DataTable.Rows

    '            For Each rowref As DataRow In tblObjectCodes.Rows
    '                If Trim(ProcLib.CheckNullDBField(rowref("ObjectCode"))) = Trim(ProcLib.CheckNullDBField(Row("ObjectCode"))) Then
    '                    Row("Description") = rowref("ObjectCode") & "-" & rowref("ObjectCodeDescription")
    '                    Row("ObjectCode") = Trim(Row("ObjectCode"))   'fix extraneous space
    '                    Exit For
    '                End If
    '            Next



    '        Next
    '        db.SaveDataTableToDB()


    '        Sql = "SELECT * FROM ContractLineItems WHERE DistrictID = 67"
    '        db.FillDataTableForUpdate(Sql)

    '        For Each Row As DataRow In db.DataTable.Rows
    '            For Each rowref As DataRow In tblObjectCodes.Rows
    '                If Trim(ProcLib.CheckNullDBField(rowref("ObjectCode"))) = Trim(ProcLib.CheckNullDBField(Row("ObjectCode"))) Then
    '                    Row("LineObjectCodeDescription") = rowref("ObjectCode") & " - " & rowref("ObjectCodeDescription")
    '                    Exit For
    '                End If
    '            Next
    '        Next
    '        db.SaveDataTableToDB()


    '        'Now Create Transactions for each entry
    '        Sql = "DELETE FROM Transactions WHERE LastUpdateBy = 'SJEImport'"
    '        db.ExecuteNonQuery(Sql)

    '        Sql = "SELECT * FROM SJEImportTemp WHERE ContractID IS NOT Null AND EntryType = 'AP' "
    '        Dim tblTransImport As DataTable = db.ExecuteDataTable(Sql)

    '        Sql = "SELECT * FROM Contracts WHERE DistrictID = 67 "
    '        Dim tblContractLines As DataTable = db.ExecuteDataTable(Sql)

    '        db.FillDataTableForUpdate("SELECT * FROM Transactions WHERE DistrictID = 67 ")

    '        For Each Row As DataRow In tblTransImport.Rows




    '            Dim newrow As DataRow = db.DataTable.NewRow

    '            newrow("ContractID") = Row("ContractID")
    '            newrow("TotalAmount") = Row("NewAmount")
    '            newrow("PayableAmount") = Row("NewAmount")
    '            newrow("RetentionAmount") = 0
    '            newrow("FiscalYear") = ProcLib.CheckNullDBField(Row("FY"))
    '            newrow("FundCode") = ProcLib.CheckNullDBField(Row("Fund"))

    '            newrow("Comments") = Trim(ProcLib.CheckNullDBField(Row("POComment")))



    '            newrow("Description") = Trim(ProcLib.CheckNullDBField(Row("ItemDescription")))
    '            newrow("Reimbursable") = 0
    '            newrow("WorkFlowScenerioID") = 0

    '            If Row("VoucherStatus") = "Outstanding" Then
    '                newrow("Status") = "Open"
    '            ElseIf Row("VoucherStatus") = "Payment Pending" Then
    '                newrow("Status") = "Payment Pending"
    '            Else
    '                newrow("Status") = "Paid"
    '            End If

    '            If IsDate(ProcLib.CheckNullDBField(Row("InvoiceDate"))) Then
    '                newrow("InvoiceDate") = Row("InvoiceDate")
    '            End If

    '            newrow("CheckNumber") = ProcLib.CheckNullDBField(Row("CheckNumber"))
    '            newrow("InvoiceNumber") = ProcLib.CheckNullDBField(Row("InvoiceNumber"))

    '            'NEED TO RESOLVE WITH RAFAEL ABOUT NEW FIELDS FOR VOUCHER CHECK 

    '            newrow("CheckNumber") = ProcLib.CheckNullDBField(Row("VoucherNumber"))
    '            newrow("InternalInvNumber") = ProcLib.CheckNullDBField(Row("CheckNumber"))

    '            If IsDate(ProcLib.CheckNullDBField(Row("VoucherDate"))) Then
    '                newrow("DatePaid") = Row("VoucherDate")
    '            End If

    '            If IsDate(ProcLib.CheckNullDBField(Row("CheckDate"))) Then
    '                newrow("CheckDate") = Row("CheckDate")
    '            End If

    '            If Trim(ProcLib.CheckNullDBField(Row("Accrual"))) = "Y" Then
    '                newrow("Accrual") = 1
    '            Else
    '                newrow("Accrual") = 0
    '            End If

    '            If ProcLib.CheckNullDBField(Row("EntryType")) = "AP" Then
    '                newrow("TransType") = "Invoice"
    '            Else
    '                newrow("TransType") = "Adjustment"
    '                'If IsDate(ProcLib.CheckNullDBField(Row("VoucherDate"))) Then
    '                '    newrow("InvoiceDate") = Row("VoucherDate")
    '                'End If
    '            End If





    '            newrow("LastUpdateBy") = "SJEImport"
    '            newrow("LastUpdateOn") = Now()

    '            'Update the other contract info
    '            For Each rowref As DataRow In tblContractLines.Rows
    '                If rowref("ContractID") = Row("ContractID") Then

    '                    'newrow("CollegeID") = rowref("CollegeID")
    '                    newrow("ProjectID") = rowref("ProjectID")
    '                    newrow("DistrictID") = rowref("DistrictID")
    '                    newrow("ContractorID") = rowref("ContractorID")

    '                    Exit For
    '                End If
    '            Next

    '            db.DataTable.Rows.Add(newrow)

    '        Next

    '        db.SaveDataTableToDB()


    '        'Now Consolodate and Create Transactions for each Payroll entry

    '        Sql = "SELECT SUM(NewAmount) AS Amount, JCAFRow, JCAFFundingSource, ContractID, VoucherDate, VoucherNumber, JCAFCellName, FY, Fund, VoucherStatus "
    '        Sql &= "FROM SJEImportTemp WHERE EntryType = 'PR' AND ContractID IS NOT NULL "
    '        Sql &= "GROUP BY JCAFRow, JCAFFundingSource, ContractID, VoucherDate, VoucherNumber, JCAFCellName, FY, Fund, VoucherStatus "
    '        tblTransImport = db.ExecuteDataTable(Sql)

    '        Sql = "SELECT * FROM Contracts WHERE DistrictID = 67 "
    '        tblContractLines = db.ExecuteDataTable(Sql)

    '        db.FillDataTableForUpdate("SELECT * FROM Transactions WHERE DistrictID = 67 ")

    '        For Each Row As DataRow In tblTransImport.Rows

    '            Dim newrow As DataRow = db.DataTable.NewRow

    '            newrow("ContractID") = Row("ContractID")
    '            newrow("TotalAmount") = Row("Amount")
    '            newrow("PayableAmount") = Row("Amount")
    '            newrow("RetentionAmount") = 0
    '            newrow("FiscalYear") = ProcLib.CheckNullDBField(Row("FY"))
    '            newrow("FundCode") = ProcLib.CheckNullDBField(Row("Fund"))

    '            newrow("Comments") = "Consolodated Payroll Transactions Grouped By VoucherNumber, VoucherDate From Import."



    '            newrow("Description") = "Consolodated Payroll Transaction for " & Row("FY") & ", Voucher " & Row("VoucherNumber")
    '            newrow("Reimbursable") = 0
    '            newrow("WorkFlowScenerioID") = 0

    '            If Row("VoucherStatus") = "Outstanding" Then
    '                newrow("Status") = "Open"
    '            ElseIf Row("VoucherStatus") = "Payment Pending" Then
    '                newrow("Status") = "Payment Pending"
    '            Else
    '                newrow("Status") = "Paid"
    '            End If

    '            If IsDate(ProcLib.CheckNullDBField(Row("VoucherDate"))) Then
    '                newrow("InvoiceDate") = Row("VoucherDate")
    '            End If

    '            newrow("InvoiceNumber") = ProcLib.CheckNullDBField(Row("VoucherNumber"))
    '            newrow("InternalInvNumber") = ProcLib.CheckNullDBField(Row("VoucherNumber"))


    '            'NEED TO RESOLVE WITH RAFAEL ABOUT NEW FIELDS FOR VOUCHER CHECK 
    '            newrow("CheckNumber") = ProcLib.CheckNullDBField(Row("VoucherNumber"))
    '            If IsDate(ProcLib.CheckNullDBField(Row("VoucherDate"))) Then
    '                newrow("DatePaid") = Row("VoucherDate")
    '            End If

    '            newrow("Accrual") = 0
    '            newrow("TransType") = "Invoice"

    '            newrow("LastUpdateBy") = "SJEImport"
    '            newrow("LastUpdateOn") = Now()

    '            'Update the other contract info
    '            For Each rowref As DataRow In tblContractLines.Rows
    '                If rowref("ContractID") = Row("ContractID") Then

    '                    newrow("ProjectID") = rowref("ProjectID")
    '                    newrow("DistrictID") = rowref("DistrictID")
    '                    newrow("ContractorID") = rowref("ContractorID")

    '                    Exit For
    '                End If
    '            Next

    '            db.DataTable.Rows.Add(newrow)

    '        Next

    '        db.SaveDataTableToDB()


    '        'Create Transaction Detail Entries for all the Transactions
    '        Sql = "DELETE FROM TransactionDetail WHERE LastUpdateBy = 'SJEImport'"
    '        db.ExecuteNonQuery(Sql)

    '        Sql = "SELECT * FROM ContractLineItems WHERE DistrictID = 67 AND LineType='Contract' "
    '        Dim tblCLI As DataTable = db.ExecuteDataTable(Sql)


    '        Sql = "SELECT DISTINCT ContractID, GLAccountNo, VoucherNumber, ObjectCode, JCAFCellName "
    '        Sql &= "FROM SJEImportTemp WHERE ContractID Is Not Null AND EntryType <> 'JE'"
    '        Dim tblAccLookup As DataTable = db.ExecuteDataTable(Sql)

    '        Sql = "SELECT * FROM TransactionDetail WHERE DistrictID = 67"
    '        db.FillDataTableForUpdate(Sql)

    '        For Each Row As DataRow In tblCLI.Rows

    '            Dim nLineID As Integer = Row("LineID")
    '            Dim nContractID As Integer = Row("ContractID")
    '            Dim nGLAcctNo As String = Trim(ProcLib.CheckNullDBField(Row("AccountNumber")))
    '            Dim sObjectCode As String = Trim(ProcLib.CheckNullDBField(Row("ObjectCode")))
    '            Dim sJCAFCellName As String = Trim(ProcLib.CheckNullDBField(Row("JCAFCellName")))
    '            Dim nVoucherNumber As String = ""

    '            For Each rowA As DataRow In tblAccLookup.Rows    'get the account number as it ties the invoice to the cli
    '                If rowA("ContractID") = nContractID And Trim(ProcLib.CheckNullDBField(rowA("GLAccountNo"))) = nGLAcctNo And Trim(ProcLib.CheckNullDBField(rowA("JCAFCellName"))) = sJCAFCellName And Trim(ProcLib.CheckNullDBField(rowA("ObjectCode"))) = sObjectCode Then

    '                    nVoucherNumber = rowA("VoucherNumber")

    '                    Sql = "SELECT * FROM Transactions WHERE ContractID = " & nContractID & " AND InternalInvNumber ='" & nVoucherNumber & "' "
    '                    Dim tblTrans As DataTable = db.ExecuteDataTable(Sql)

    '                    For Each rowT As DataRow In tblTrans.Rows

    '                        'Create a detail recortd
    '                        Dim newrow As DataRow = db.DataTable.NewRow
    '                        newrow("DistrictID") = 67
    '                        newrow("ContractID") = nContractID
    '                        newrow("TransactionID") = rowT("TransactionID")
    '                        newrow("ProjectID") = rowT("ProjectID")
    '                        newrow("Reimbursable") = 0
    '                        newrow("Amount") = rowT("TotalAmount")
    '                        newrow("PayableAmount") = rowT("PayableAmount")
    '                        newrow("ContractLineItemID") = nLineID
    '                        newrow("BudgetLineName") = sJCAFCellName

    '                        newrow("LastUpdateBy") = "SJEImport"
    '                        newrow("LastUpdateOn") = Now()

    '                        db.DataTable.Rows.Add(newrow)

    '                    Next

    '                    Exit For
    '                End If

    '            Next
    '        Next
    '        db.SaveDataTableToDB()


    '    End Using

    'End Sub

    'Private Sub FinalSJEFixOrphanedTransactions()

    '    Dim sql As String = ""

    '    Using db As New PromptDataHelper

    '        sql = "SELECT * FROM TransactionDetail WHERE DistrictID = 67"
    '        db.FillDataTableForUpdate(sql)

    '        sql = "SELECT Transactions.TransactionID,Transactions.ProjectID, Transactions.TotalAmount, Transactions.PayableAmount, TransactionDetail.Amount AS DetAmount, "
    '        sql &= " TransactionDetail.PayableAmount AS DetPayable, TransactionDetail.ContractLineItemID AS LineID, Transactions.DistrictID,Transactions.ContractID "
    '        sql &= "FROM Transactions LEFT OUTER JOIN TransactionDetail ON Transactions.TransactionID = TransactionDetail.TransactionID "
    '        sql &= "WHERE TransactionDetail.Amount IS NULL AND Transactions.DistrictID = 67 "

    '        Dim tbl As DataTable = db.ExecuteDataTable(sql)
    '        For Each row As DataRow In tbl.Rows

    '            'For now, get the first contract line item and create detail from that -- this will fix most of the issues, but manaual cleanup will need to follow
    '            sql = "SELECT * FROM ContractLineItems WHERE ContractID = " & row("ContractID")
    '            Dim tblLines As DataTable = db.ExecuteDataTable(sql)
    '            For Each rowline As DataRow In tblLines.Rows

    '                Dim newrow As DataRow = db.DataTable.NewRow
    '                newrow("DistrictID") = 67
    '                newrow("ContractID") = row("ContractID")
    '                newrow("TransactionID") = row("TransactionID")
    '                newrow("ProjectID") = row("ProjectID")
    '                newrow("Reimbursable") = 0
    '                newrow("Amount") = row("TotalAmount")
    '                newrow("PayableAmount") = row("PayableAmount")
    '                newrow("ContractLineItemID") = rowline("LineID")
    '                newrow("BudgetLineName") = rowline("JCAFCellName")

    '                newrow("LastUpdateBy") = "SJEImport"
    '                newrow("LastUpdateOn") = Now()

    '                db.DataTable.Rows.Add(newrow)

    '                Exit For
    '            Next
    '        Next
    '        db.SaveDataTableToDB()




    '    End Using









    'End Sub
    
    
    
    
    
    
    
    
    
    
</script>

<html>
<head>
    <title>system_utilities</title>
    <link href="Styles.css" type="text/css" rel="stylesheet" />
</head>
<body>
    <form id="Form1" method="post" runat="server">
   
    <asp:Label ID="Label3" runat="server" Font-Underline="True" Style="z-index: 1; left: 11px;
        top: 12px; position: absolute; height: 13px;" Text="System Utilities"></asp:Label>
    <asp:TextBox ID="txtParm1" runat="server" Style="z-index: 1; left: 203px; top: 37px;
        position: absolute; width: 63px"></asp:TextBox>
    <asp:TextBox ID="txtParm2" runat="server" Style="z-index: 1; left: 362px; top: 35px;
        position: absolute; width: 63px"></asp:TextBox>
    <asp:Label ID="lblDescription" runat="server" Font-Underline="False" Style="z-index: 1;
        left: 16px; top: 66px; position: absolute; height: 12px" 
        Text="Description:" CssClass="ViewDataDisplay"></asp:Label>
    <asp:Label ID="lblResults" runat="server" Font-Underline="False" Style="z-index: 1;
        left: 71px; top: 101px; position: absolute; height: 12px" 
        Text="xxxxxx" CssClass="ViewDataDisplay"></asp:Label>
    <asp:Label ID="lbl3" runat="server" Font-Underline="False" Style="z-index: 1;
        left: 16px; top: 100px; position: absolute; height: 15px" Text="Results:"></asp:Label>
    <asp:Label ID="lblParm1" runat="server" Font-Underline="False" Style="z-index: 1;
        left: 137px; top: 41px; position: absolute; height: 12px" Text="Parm1:"></asp:Label>
    <asp:Button ID="butRunProc" runat="server" Style="z-index: 1; left: 15px; top: 33px;
        position: absolute" Text="Run Proc" OnClick="butRunProc_Click" />
    <asp:Label ID="lblParm2" runat="server" Font-Underline="False" Style="z-index: 1;
        left: 304px; top: 39px; position: absolute; height: 19px;" Text="Parm2:"></asp:Label>
    <asp:CheckBox ID="chkAuditOnly" runat="server" Checked="True" Style="z-index: 1;
        left: 474px; top: 37px; position: absolute" Text="Audit Only (Does not write to Database)" />

        <asp:TextBox ID="txtEmailMessage" runat="server" 
        Style="z-index: 1; left: 17px; top: 133px; position: absolute; height: 379px; width: 488px;" 
        TextMode="MultiLine"></asp:TextBox>

    </form>
</body>
</html>
