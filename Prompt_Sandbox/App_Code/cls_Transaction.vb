Imports System
Imports System.Web
Imports System.Web.UI.WebControls
Imports Telerik.Web.UI
Imports System.IO
Imports System.Data
Imports System.Data.SqlClient

Namespace Prompt

    '********************************************
    '*  Transaction Class
    '*  
    '*  Purpose: Processes data for the Transaction Object
    '*
    '*  Last Mod By:    Ford James
    '*  Last Mod On:    08/15/07
    '*
    '********************************************

    Public Class promptTransaction
        Implements IDisposable

        'Properties
        Public CallingPage As Page
        Public TransactionType As String = ""

        'parent contract info
        Public ParentContract As promptContract

        Public TurnOffValidation As Boolean = False
        Public DisableObjectCodeFilter As Boolean = False  'determins if allocation lines are filtered by object code assignments in JCAF
        Public AllowObjectCodeChange As Boolean = False 'used for legacy conversion to allow change/assignment of object code

        Public TotalGrossAmount As Double = 0
        Public TotalPayableAmount As Double = 0
        Public TotalRetentionAmount As Double = 0
        Public TaxAmount As Double = 0

        Public WorkflowScenerioID As Integer = 0
        Public WorkflowScenerioApprovalAmountOk As Boolean = False
        Public WorkflowScenerioApprovalAmount As Double = 0
        Public CurrentWorkflowOwner As String = ""


        Private db As PromptDataHelper

        Public Sub New()
            db = New PromptDataHelper
        End Sub

#Region "Transaction"

        Public Function GetTransactions(ByVal ContractID As Integer) As DataTable
            Dim sql As String = "SELECT Transactions.*,"
            sql &= "(SELECT COUNT(TransactionSplitID) AS Expr1 "
            sql &= "FROM TransactionDetail WHERE TransactionID = Transactions.TransactionID AND TransactionDetail.Reimbursable = 1) AS DetailReimbursables, "
            sql &= "(SELECT COUNT(PrimaryKey) AS Expr1 "
            sql &= "FROM AttachmentsLinks WHERE (TransactionID = Transactions.TransactionID)) AS Attachments "
            sql &= "FROM Transactions WHERE ContractID = " & ContractID & " ORDER BY Status ASC, InvoiceDate DESC"

            Return db.ExecuteDataTable(sql)

        End Function


        Public Sub SetParentContract(ByVal ContractID)

            'get the parent contract
            ParentContract = New promptContract
            ParentContract.LoadContractInfo(ContractID)

            Dim result As Integer = db.ExecuteScalar("SELECT DisableTransactionAllocationObjectCodeFiltering FROM Districts WHERE DistrictID = " & CallingPage.Session("DistrictID"))
            If result = 1 Then DisableObjectCodeFilter = True

            result = db.ExecuteScalar("SELECT AllowChangingTransactionObjectCode FROM Districts WHERE DistrictID = " & CallingPage.Session("DistrictID"))
            If result = 1 Then AllowObjectCodeChange = True

            TurnOffValidation = db.ExecuteScalar("SELECT ISNULL(TurnOffValidation,0) FROM Colleges WHERE CollegeID = " & ParentContract.CollegeID)

            'Set the session variable for College for this contract just to be sure as somtimes it goes away
            HttpContext.Current.Session("CollegeID") = ParentContract.CollegeID


        End Sub

        'Public Function GetAllocationRecords(ByVal ProjectID As Integer, ByVal ContractID As Integer) As DataTable

        '    SetParentContract(ContractID)

        '    Dim sql As String = ""
        '    If DisableObjectCodeFilter = True Then   'get all object codes
        '        'Get the budget items (with values > 0) and transaction totals for this project and loop through for allocation
        '        sql = "SELECT * FROM qry_TransactionEditAllocation WHERE ProjectID =" & ProjectID _
        '            & " ORDER BY Case When Substring(BudgetGroup,2,1) = '.' Then '0' + Substring(BudgetGroup,1,1) Else BudgetGroup End Asc, Source, Description "

        '    Else
        '        'Get the budget items (with values > 0 ) and allocated object codes and return those that match
        '        'the passed contract id's object code assignment. include the remaining balance allocated for each
        '        'jcaf line item/object code.

        '        sql = "SELECT * FROM qry_BudgetJCAF_ObjectCode_Allocation_by_contract WHERE ContractID = " & ContractID & " ORDER BY ColumnName"
        '    End If

        '    Dim dtAlloc As DataTable = db.ExecuteDataTable(sql)

        '    Return dtAlloc


        'End Function

        Public Function GetTransJCAFLineObjectCodeAllocTotal(ByVal JCAFLine As String, ByVal ObjectCode As String, ByVal ProjectID As Integer) As Double
            'gets the total currect transaction jcaf objectcode/jcaf allocation for current project - used to calc remaining
            'bal for object code/jcaf alloc in transactions
            Dim sql As String = "SELECT ISNULL(SUM(dbo.TransactionDetail.Amount), 0) AS TotalAllocExpenses "
            sql = sql & "FROM  dbo.TransactionDetail INNER JOIN dbo.Contracts ON dbo.TransactionDetail.ContractID = dbo.Contracts.ContractID "
            sql = sql & "WHERE dbo.Contracts.ObjectCode = '" & ObjectCode & "' AND dbo.TransactionDetail.ProjectID = " & ProjectID & " "
            sql = sql & "AND dbo.TransactionDetail.BudgetLineName = '" & JCAFLine & "'"

            Return db.ExecuteScalar(sql)

        End Function

        Public Function GetTransactionDetailRecords(ByVal Transid As Integer, ByVal nContractID As Integer) As DataTable

            Dim sql As String = "SELECT  ContractLineItems.ContractID, ContractLineItems.Reimbursable, ContractLineItems.AccountNumber, ContractLineItems.LineID AS ContractLineItemID, ContractLineItems.Description, "
            sql &= "BudgetFieldsTable.ColumnName, ContractLineItems.JCAFLine, BudgetFieldsTable.Source, ContractLineItems.Amount AS ContractLineAmount, "
            sql &= "ContractLineItems.ObjectCode,ContractLineItems.LineType, POLineNumber, "
            sql &= "(SELECT SUM(Amount) AS Exp1 FROM TransactionDetail WHERE ContractLineItemID = ContractLineItems.LineID) AS TotalLineExpended, "
            sql &= "ContractDetail.DistrictApprovalDate, Contracts.Status AS ContractStatus,ContractLineItems.LineType "
            sql &= "FROM ContractLineItems INNER JOIN "
            sql &= "BudgetFieldsTable ON ContractLineItems.JCAFCellName = BudgetFieldsTable.ColumnName INNER JOIN "
            sql &= "  Contracts ON ContractLineItems.ContractID = Contracts.ContractID LEFT OUTER JOIN "
            sql &= " ContractDetail ON ContractLineItems.ContractChangeOrderID = ContractDetail.ContractDetailID "
            sql &= "WHERE ContractLineItems.ContractID = " & nContractID & " AND ContractLineItems.LineType <> 'Adjustment' "
            sql &= "Order By POLineNumber"


            Dim tbl As DataTable = db.ExecuteDataTable(sql)


            'get the existing transaction detail items for this contract
            sql = "SELECT * FROM TransactionDetail WHERE TransactionID = " & Transid
            Dim tblTransDet As DataTable = db.ExecuteDataTable(sql)

            'Add new columns
            Dim col As New DataColumn
            col.DataType = Type.GetType("System.Decimal")
            col.ColumnName = "RemainingAvailableAmount"
            tbl.Columns.Add(col)

            col = New DataColumn
            col.DataType = Type.GetType("System.Decimal")
            col.ColumnName = "Amount"    'holds the transaction detail amount if any
            tbl.Columns.Add(col)

            col = New DataColumn
            col.DataType = Type.GetType("System.Int32")
            col.ColumnName = "TransactionSplitID"    'holds the id of the transaction detail item if any
            tbl.Columns.Add(col)

            col = New DataColumn
            col.DataType = Type.GetType("System.String")
            col.ColumnName = "Pending"    'holds status of the line -- for transaction edit validation
            tbl.Columns.Add(col)





            For Each row As DataRow In tbl.Rows         'calc remaini avail and set custom source names

                row("RemainingAvailableAmount") = ProcLib.CheckNullNumField(row("ContractLineAmount")) - ProcLib.CheckNullNumField(row("TotalLineExpended")) 'fix null amount for non expended lines
                row("Amount") = 0

                'Update the row with transdet amount if exists
                For Each rowdet As DataRow In tblTransDet.Rows
                    If ProcLib.CheckNullNumField(rowdet("ContractLineItemID")) = ProcLib.CheckNullNumField(row("ContractLineItemID")) Then
                        row("Amount") = rowdet("Amount")
                        row("TransactionSplitID") = rowdet("TransactionSplitID")

                    End If
                Next

                If row("Linetype") = "ChangeOrder" And Not IsDate(ProcLib.CheckNullDBField(row("DistrictApprovalDate"))) Then
                    row("Pending") = "Y"
                Else
                    row("Pending") = "N"
                End If


            Next

            ProcLib.SetCustomJCAFFundingSourceName(tbl, "Source")    'sets the custom JCAF names

            Return tbl

        End Function



        Public Sub GetTransactionTotals(ByVal Transid As Integer)
            Dim dt As DataTable = db.ExecuteDataTable("SELECT RetentionAmount,TaxAdjustmentAmount,TotalAmount,PayableAmount FROM Transactions WHERE TransactionID = " & Transid)
            TotalGrossAmount = dt.Rows(0).Item("TotalAmount")
            TotalPayableAmount = dt.Rows(0).Item("PayableAmount")
            TotalRetentionAmount = dt.Rows(0).Item("RetentionAmount")
            TaxAmount = IIf(IsDBNull(dt.Rows(0).Item("TaxAdjustmentAmount")), 0, dt.Rows(0).Item("TaxAdjustmentAmount"))

        End Sub


        Public Function IsPassthroughProject(ByVal ProjectID As Integer) As Boolean
            'Gets passthrough entries for project
            Dim sql As String = "Select IsPassthroughProject FROM Projects WHERE ProjectID = " & ProjectID
            Dim result = db.ExecuteScalar(sql)
            If Not IsDBNull(result) Then
                If result = 1 Then
                    Return True
                End If
            End If
        End Function

        Public Function IsFFEScenario(ByVal ScenarioID As Integer) As Boolean
            'Gets FFE Status for Scenario
            Dim sql As String = "Select IsFFEScenario FROM WorkflowScenerios WHERE WorkflowScenerioID = " & ScenarioID
            Dim result = db.ExecuteScalar(sql)
            If Not IsDBNull(result) Then
                If result = 1 Then
                    Return True
                End If
            End If
        End Function


        Public Sub GetNewTransaction(ByVal ContractId As Integer)

            'populates the parent form with new transaction record

            SetParentContract(ContractId)

            Dim sql As String = ""

            'get a blank transaction record and populate with initial info
            Dim dt As DataTable
            Dim row As DataRow
            sql = "select * from transactions where transactionid = 0"
            dt = db.ExecuteDataTable(sql)
            row = dt.NewRow()

            If TransactionType = "Retention" Then
                row("TransType") = "RetInvoice"
                row("PurchaseOrderNumber") = ParentContract.PONumber
                row("BondSeries") = ParentContract.ParentProjectBondSeriesNumber
                row("ContractorID") = ParentContract.ContractorID
                row("FiscalYear") = ParentContract.CurrentFiscalYear
                row("Status") = "Open"

            Else
                row("TransType") = "Invoice"
                row("PurchaseOrderNumber") = ParentContract.PONumber
                row("BondSeries") = ParentContract.ParentProjectBondSeriesNumber
                row("ObjectCode") = ParentContract.ObjectCode
                row("ContractorID") = ParentContract.ContractorID
                row("FiscalYear") = ParentContract.CurrentFiscalYear
                row("Status") = "Open"

            End If

            LoadEditForm(row)

        End Sub


        Public Sub SetDistrictValidationFlags()

            Dim result As Integer = db.ExecuteScalar("SELECT DisableTransactionAllocationObjectCodeFiltering FROM Districts WHERE DistrictID = " & CallingPage.Session("DistrictID"))
            If result = 1 Then DisableObjectCodeFilter = True

            result = db.ExecuteScalar("SELECT AllowChangingTransactionObjectCode FROM Districts WHERE DistrictID = " & CallingPage.Session("DistrictID"))
            If result = 1 Then AllowObjectCodeChange = True

            TurnOffValidation = db.ExecuteScalar("SELECT ISNULL(TurnOffValidation,0) FROM Colleges WHERE CollegeID = " & CallingPage.Session("CollegeID"))

        End Sub
        Public Function GetMaxApprovalLevel(ByVal WorkflowScenerioID As Integer) As Double
            'Get max approval level if workflow - make sure there is a scenerio owner with approval level high enough
            Dim sql As String = "SELECT MAX(WorkflowRoles.ApprovalDollarLimit) AS MaxAmount "
            sql &= "FROM WorkflowRoles INNER JOIN WorkflowScenerioOwners ON WorkflowRoles.WorkflowRoleID = WorkflowScenerioOwners.WorkflowRoleID "
            sql &= "WHERE WorkflowScenerioID = " & WorkflowScenerioID

            Dim result = db.ExecuteScalar(sql)
            If IsDBNull(result) Then
                WorkflowScenerioApprovalAmount = 0
                Return 0
            Else
                WorkflowScenerioApprovalAmount = result
                Return result
            End If

        End Function


        Public Sub GetExistingTransaction(ByVal TransID As Integer, ByVal ContractID As Integer)

            'populates the parent form with transaction record
            SetParentContract(ContractID)

            'get transaction record and populate with initial info
            Dim row As DataRow
            row = db.GetDataRow("select * from transactions where transactionid = " & TransID)

            If HttpContext.Current.Session("EnableWorkflow") = "1" Then
                WorkflowScenerioID = row("WorkflowScenerioID")
                TotalGrossAmount = row("TotalAmount")
                Dim nmax As Double = GetMaxApprovalLevel(WorkflowScenerioID)
                If nmax >= TotalGrossAmount Then
                    WorkflowScenerioApprovalAmountOk = True
                End If

            End If

            LoadEditForm(row)

        End Sub


        Public Sub GetFRSPOLineNumbers(ByRef cbo As Telerik.Web.UI.RadComboBox, ByVal PONumber As String)

            Dim sSelectedValue As String = cbo.SelectedValue

            'loads PO line numbers for FHDA
            Dim sql As String = "SELECT  FRS_PONumbers.PONumber, ISNULL(FRS_PONumbers_Lines.LineNumber, N'1') AS LineNumber, "
            sql &= "ISNULL(FRS_PONumbers_Lines.LineAmount, N'N/A')AS LineAmt, ISNULL(FRS_PONumbers_Lines.LineDescription, N'N/A') AS Description "
            sql &= "FROM FRS_PONumbers LEFT OUTER JOIN FRS_PONumbers_Lines ON FRS_PONumbers.PONumber = FRS_PONumbers_Lines.PONumber "
            sql &= "WHERE FRS_PONumbers.PONumber = '" & PONumber & "' "
            sql &= "ORDER BY FRS_PONumbers.PONumber, LineNumber "
            Dim tbl As DataTable = db.ExecuteDataTable(sql)

            'now add formatted columns to datatable
            Dim colLine As DataColumn = New DataColumn("Line", System.Type.GetType("System.String"))
            Dim colAmt As DataColumn = New DataColumn("Amount", System.Type.GetType("System.String"))
            tbl.Columns.Add(colLine)
            tbl.Columns.Add(colAmt)

            cbo.Items.Clear()
            Dim item As New Telerik.Web.UI.RadComboBoxItem
            item.Text = "-- none --"
            item.Value = "0"
            cbo.Items.Add(item)
            'If tbl.Rows.Count = 0 Then
            '    item = New Telerik.Web.UI.RadComboBoxItem
            '    item.Text = "1"
            '    item.Value = "1"
            '    cbo.Items.Add(item)
            'End If

            For Each linerow As DataRow In tbl.Rows
                If linerow("LineNumber") <> "N/A" Then
                    linerow("Line") = Val(linerow("LineNumber"))
                End If
                If linerow("LineAmt") <> "N/A" Then
                    linerow("Amount") = FormatCurrency(Val(linerow("LineAmt")), 2)
                End If

                item = New Telerik.Web.UI.RadComboBoxItem
                item.Text = linerow("Line") & " -- " & linerow("Description") & " (" & linerow("Amount") & ")"
                item.Value = linerow("Line")

                If linerow("Line") = sSelectedValue Then
                    item.Selected = True
                End If
                cbo.Items.Add(item)

            Next

            tbl = Nothing

        End Sub

        Public Function GetLinkedAttachments(ByVal TransactionID As Integer) As DataTable
            Dim sql As String = "SELECT Attachments.AttachmentID, Attachments.FileName FROM AttachmentsLinks "
            sql &= "INNER JOIN Attachments ON AttachmentsLinks.AttachmentID = Attachments.AttachmentID "
            sql &= "WHERE TransactionID = " & TransactionID & " ORDER BY Attachments.Filename "

            Return db.ExecuteDataTable(sql)

        End Function

        Private Sub LoadEditForm(ByVal row As DataRow)

            'loads a parent form with data from passed row

            Dim form As Control = CallingPage.FindControl("Form1")  ' get ref to calling form

            Dim nDistrictID As Integer = CallingPage.Session("DistrictID")
            Dim sql As String = ""

            If TransactionType = "Retention" Then

                'sql = "SELECT ContractorID As Val, Name as Lbl FROM Contractors WHERE DistrictID = " & nDistrictID & " OR ContractorID = 0 ORDER BY NAME"
                'db.FillDropDown(sql, form.FindControl("lstContractorID"))

                sql = "SELECT LookupValue As Val, LookupTitle as Lbl FROM dbo.Lookups WHERE ParentTable = 'Transactions' AND ParentField = 'Status'  ORDER By LookupTitle"
                db.FillDropDown(sql, form.FindControl("lstStatus"))

                sql = "SELECT LookupValue As Val, LookupTitle as Lbl FROM dbo.Lookups WHERE ParentTable = 'Transactions' AND ParentField = 'FiscalYear' ORDER By LookupTitle"
                db.FillDropDown(sql, form.FindControl("lstFiscalYear"), True, False, False)

            Else


                'Fill the dropdown controls on parent form
                'sql = "SELECT ContractorID As Val, Name as Lbl FROM Contractors WHERE DistrictID = " & nDistrictID & " OR ContractorID = 0 ORDER BY NAME"
                'db.FillDropDown(sql, form.FindControl("lstContractorID"))

                sql = "SELECT LookupValue As Val, LookupTitle as Lbl FROM dbo.Lookups WHERE ParentTable = 'Transactions' AND ParentField = 'Status'  ORDER By LookupTitle"
                db.FillDropDown(sql, form.FindControl("lstStatus"))

                sql = "SELECT LookupValue As Val, LookupTitle as Lbl FROM dbo.Lookups WHERE DistrictID = " & nDistrictID & " AND ParentTable = 'Projects' AND ParentField = 'BondSeriesNumber'  ORDER By LookupTitle"
                db.FillDropDown(sql, form.FindControl("lstBondSeries"))

                sql = "SELECT LookupValue As Val, LookupTitle as Lbl FROM dbo.Lookups WHERE ParentTable = 'Transactions' AND ParentField = 'Type'  ORDER By LookupTitle"
                db.FillDropDown(sql, form.FindControl("lstTransType"))

                sql = "SELECT LookupValue As Val, LookupTitle as Lbl FROM dbo.Lookups WHERE ParentTable = 'Transactions' AND ParentField = 'Code1099' ORDER By LookupTitle Desc"
                db.FillDropDown(sql, form.FindControl("lstCode1099"), False, False, True)

                sql = "SELECT LookupValue As Val, LookupTitle as Lbl FROM dbo.Lookups WHERE DistrictID = " & nDistrictID & " AND ParentTable = 'Transactions' AND ParentField = 'FiscalYear' ORDER By LookupTitle"
                db.FillDropDown(sql, form.FindControl("lstFiscalYear"), True, False, False)

                sql = "SELECT LookupValue As Val, LookupTitle as Lbl FROM dbo.Lookups WHERE ParentTable = 'Transactions' AND ParentField = 'Verified' ORDER By LookupTitle"
                db.FillDropDown(sql, form.FindControl("lstVerified"), True, False, False)

                'sql = "SELECT ObjectCode As Val, ObjectCode + '-' + ObjectCodeDescription as Lbl FROM dbo.ObjectCodes WHERE DistrictID = " & nDistrictID & " ORDER By Lbl"
                'db.FillDropDown(sql, form.FindControl("lstObjectCode"), True, False, False)

                'sql = "SELECT DeanID As Val, Name as Lbl FROM dbo.Deans WHERE DistrictID = " & nDistrictID & " ORDER By Lbl"
                'db.FillDropDown(sql, form.FindControl("lstDeanID"), True, True, False)

                If HttpContext.Current.Session("EnableWorkflow") = "1" Then    'fill the scenerio list box 
                    'Get the workflow scenerios available for this transaction -
                    'Note: These are preselected for in the parent contract edit screen
                    Dim sScenerioList As String = ParentContract.WorkflowScenerioList
                    sScenerioList = sScenerioList.Replace(";;", ",")     'remove between delimiter
                    sScenerioList = sScenerioList.Replace(";", "")     'remove front and back delimiter

                    If Trim(sScenerioList) <> "" Then   'only fill the list if assigned
                        sql = "SELECT WorkflowScenerioID as Val, ScenerioName as lbl FROM WorkflowScenerios "
                        sql &= "WHERE WorkflowScenerioID IN (" & sScenerioList & ") ORDER BY lbl "

                        db.FillDropDown(sql, form.FindControl("lstxWorkflowScenerioID"), True, True, False)
                    End If

                End If

                'load balance and total fields
                DirectCast(form.FindControl("lblContractBalance"), Label).Text = FormatCurrency(ParentContract.ContractBalance)
                DirectCast(form.FindControl("lblContractTotal"), Label).Text = FormatCurrency(ParentContract.ContractTotal + ParentContract.AmendTotal)


            End If

            db.FillForm(form, row)



        End Sub


        Public Function ValidateDistrictContractorID(ByVal ContractorID As Integer) As Boolean
            'checks that a value is in the DistrictCOntratorID field in the contrator table
            ValidateDistrictContractorID = False

            Dim Sql As String = "SELECT DistrictContractorID FROM Contractors WHERE ContractorID = " & ContractorID
            Dim result = db.ExecuteScalar(Sql)
            If Not IsDBNull(result) Then
                If Trim(result) <> "" Then
                    If HttpContext.Current.Session("DistrictID") = 55 Then 'Check to see if in FRS_Vendors table if district is 55
                        Sql = "SELECT COUNT(PrimaryKey) FROM FRS_Vendors WHERE VendorID = '" & result & "'"
                        Dim newresult As Integer = db.ExecuteScalar(Sql)
                        If newresult > 0 Then
                            ValidateDistrictContractorID = True
                        End If
                    Else
                        ValidateDistrictContractorID = True
                    End If

                End If
            End If

        End Function

        Public Function ValidateProjectRetentionAndTaxAccounts(ByVal ProjectID As Integer) As String
            'checks that there is a value is in the Retention and Tax Account fields in the project record
            Dim msg As String = ""
            Dim sql As String = "SELECT TaxLiabilityAccountNumber, RetentionAccountNumber FROM Projects WHERE ProjectId = " & ProjectID
            db.FillReader(sql)
            While db.Reader.Read()
                If Not IsDBNull(db.Reader("TaxLiabilityAccountnumber")) Then
                    If Len(db.Reader("TaxLiabilityAccountnumber")) > 3 Then  'there is something there
                        msg = "Tax;"
                    End If
                End If
                If Not IsDBNull(db.Reader("RetentionAccountNumber")) Then
                    If Len(db.Reader("RetentionAccountNumber")) > 3 Then  'there is something there
                        msg = "Retention;"
                    End If
                End If
            End While

            db.Reader.Close()

            Return msg

        End Function

        Public Function ValidateForDuplicateInvoiceNumber(ByVal newInvNumber As String, ByVal TransID As Integer, ByVal ContractID As Integer) As String
            'checks that there is not an existing record with same invoice number for this contract
            Dim msg As String = ""
            Dim sql As String = "SELECT TransactionID FROM Transactions WHERE InvoiceNumber = '" & newInvNumber & "' AND ContractID = " & ContractID
            sql &= " AND TransactionID <> " & TransID
            db.FillReader(sql)
            While db.Reader.Read()
                If TransID <> db.Reader("TransactionID") Then   'there is another record for this contract with same invoice number
                    msg = "Sorry, there is already a transaction for this contract with this Invoice Number. Please use another number."
                End If
            End While

            db.Reader.Close()

            Return msg

        End Function

        Public Function UpdateWorkflowScenerio(ByVal TransID As Integer, ByVal ScenerioID As Integer, ByVal TransAmt As Double) As String
            'checks that workflow scenerio has appropriate approval level and if so writes the newly selected workfow scenerio to the database
            Dim msg As String = ""
            If TransID > 0 Then
                Dim nMax As Double = GetMaxApprovalLevel(ScenerioID)
                If nMax >= TransAmt Or ScenerioID = 0 Then   'okay to update if setting to none or max okay 
                    WorkflowScenerioApprovalAmountOk = True

                    Dim sql As String = ""
                    Dim nWorkflowRoleID As Integer = 0
                    Dim sWorkflowRole As String = "--none--"

                    If ScenerioID > 0 Then       'Need to get the appropriate Originator workflow owner for this scenerio
                        sql = "SELECT WorkflowRoles.WorkflowRole, WorkflowRoles.WorkflowRoleID, WorkflowScenerioOwners.WorkflowScenerioID "
                        sql &= "FROM WorkflowScenerioOwners INNER JOIN WorkflowRoles ON WorkflowScenerioOwners.WorkflowRoleID = WorkflowRoles.WorkflowRoleID "
                        sql &= "WHERE WorkflowScenerioID = " & ScenerioID & " AND IsOriginator = 1"

                        db.FillReader(sql)
                        While db.Reader.Read
                            nWorkflowRoleID = db.Reader("WorkflowRoleID")
                            sWorkflowRole = db.Reader("WorkflowRole")
                        End While
                        db.Reader.Close()
                    End If

                    CurrentWorkflowOwner = sWorkflowRole

                    'Update the transaction to put in appropriate inbox
                    sql = "UPDATE Transactions SET "
                    sql &= "WorkflowScenerioID = " & ScenerioID & ","
                    sql &= "LastWorkflowAction = 'Add To Workflow',"
                    sql &= "LastWorkflowActionOn = '" & Now & "',"
                    sql &= "PreviousWorkflowRoleID = 0,"
                    sql &= "CurrentWorkflowRoleID = " & nWorkflowRoleID & ","
                    sql &= "CurrentWorkflowOwner = '" & sWorkflowRole & "',"
                    sql &= "CurrentWorkflowOwnerNotifiedOn = NULL,"
                    sql &= "FRSCheckMessageCode = '',"
                    sql &= "FRSCutSingleCheck = '',"
                    sql &= "FRSRetentionCheckMessageCode = '',"
                    sql &= "ExportedOn = NULL "

                    sql &= " WHERE TransactionID = " & TransID

                    db.ExecuteNonQuery(sql)
                Else
                    msg = "Fail"
                End If
            End If

            Return msg

        End Function


        Public Sub SaveTransaction(ByVal TransactionID As Integer)


            Dim nDistrictID As Integer = CallingPage.Session("DistrictID")
            Dim nCollegeID As Integer = CallingPage.Session("CollegeID")
            Dim nContractID As Integer = CallingPage.Request.QueryString("ContractID")

            'get the parent contract
            SetParentContract(nContractID)

            Dim nProjectID As Integer = ParentContract.ProjectID

            Dim sql As String = ""

            If TransactionID = 0 Then  'this is new transaction so add new 
                sql = "Insert Into Transactions "
                If TransactionType = "Retention" Then
                    sql &= "(DistrictID,ProjectID,ContractID,TransType,CurrentWorkflowOwner,CurrentWorkflowRoleID,ContractorID) "
                    sql &= "VALUES ("
                    sql &= nDistrictID & "," & nProjectID & "," & nContractID & ",'RetInvoice','" & HttpContext.Current.Session("WorkflowRole") & "',"
                    sql &= HttpContext.Current.Session("WorkflowRoleID") & "," & ParentContract.ContractorID & ")"
                Else
                    sql &= "(DistrictID,ProjectID,ContractID,CurrentWorkflowOwner,CurrentWorkflowRoleID,ContractorID) "
                    sql &= "VALUES ("
                    sql &= nDistrictID & "," & nProjectID & "," & nContractID & ",'" & HttpContext.Current.Session("WorkflowRole") & "',"
                    sql &= HttpContext.Current.Session("WorkflowRoleID") & "," & ParentContract.ContractorID & ")"
                End If
                sql &= ";SELECT NewKey = Scope_Identity()"  'return the new primary key

                TransactionID = db.ExecuteScalar(sql)

            End If

            'Saves the basic transaction fields (excluding those dynamically created
            db.SaveForm(CallingPage.Form, "SELECT * FROM Transactions WHERE TransactionID = " & TransactionID)

            If TransactionType <> "Retention" Then   'do additional for normal invoices

                'Update Dynamic Fields to Transaction

                Dim nTransTot As Double = CallingPage.Request.Form("txtTotalAmount")
                Dim nTransPay As Double = CallingPage.Request.Form("txtPayableAmount")
                Dim nTransRet As Double = CallingPage.Request.Form("txtRetentionAmount")
                Dim nTransTax As Double = CallingPage.Request.Form("txtTaxAdjustmentAmount")
                Dim sTransRetOverride As String = CallingPage.Request.Form("chkAllowRetentionOverride")  'will be blank if not checked

                'Dim nWorkflowScenerioID As Integer = CallingPage.Request.Form("lstxWorkflowScenerioID")  'will be blank if not checked

                'Quick fix to force credit trans type for neg invoices
                Dim lstTransType As DropDownList = DirectCast(CallingPage.FindControl("lstTransType"), DropDownList)
                Dim sTransType As String = lstTransType.SelectedValue
                If nTransTot < 0 And sTransType = "Invoice" Then
                    sTransType = "Credit"
                End If

                sql = "Update Transactions Set "
                sql = sql & "TotalAmount = " & nTransTot & ", "
                'sql = sql & "WorkflowScenerioID = " & nWorkflowScenerioID & ", "
                sql = sql & "PayableAmount = " & nTransPay & ", "
                sql = sql & "TaxAdjustmentAmount = " & nTransTax & ", "
                sql = sql & "RetentionAmount = " & nTransRet & ", "
                sql = sql & "TransType = '" & sTransType & "', "

                If sTransRetOverride = "True" Then
                    sql = sql & "AllowRetentionOverride = 1 "
                Else
                    sql = sql & "AllowRetentionOverride = 0 "
                End If

                sql = sql & "Where TransactionID = " & TransactionID
                db.ExecuteNonQuery(sql)

                'UPDATE TRANSACTIONDETAIL 
                Dim nRetPercent As Double = 0
                Dim nNewPayAmt As Double = 0

                Dim bCalcPayableAmt As Boolean = True

                If nTransTot = 0 Or nTransPay = 0 Then
                    bCalcPayableAmt = False
                Else
                    nRetPercent = (nTransPay / nTransTot)
                End If

                'delete existing detail records for this transaction
                db.ExecuteNonQuery("DELETE FROM TransactionDetail WHERE TransactionID = " & TransactionID)

                Dim sAccountNumber As String = ""   'LEGACY -- to update parent transaction with contract line item account number(s)

                Dim nRows As Integer = 0
                'Now update the transaction details
                Using dbDet As New PromptDataHelper
                    'load DataTable Prop of helper with an updateable table
                    dbDet.FillDataTableForUpdate("Select * From TransactionDetail Where TransactionID = 0")

                    Dim fldname As String = ""
                    Dim colValue As String = ""
                    For i As Integer = 0 To CallingPage.Request.Form.Count - 1             'iterate each of the returned forms controls
                        fldname = CallingPage.Request.Form.AllKeys(i)
                        colValue = CallingPage.Request.Form.GetValues(i)(0)
                        If colValue = "" Then
                            colValue = 0
                        End If
                        If Left(fldname, 4) = "txxt" Then  'get the detail items only that have values
                            If colValue <> 0 And (Not fldname.EndsWith("_text")) Then  'HACK to circumvent RadAjax issue with creating additional control that ends with _text

                                'get reference to the Amount control (NOTE: 07/2010  THIS is newer and cleaner methodolgy for accessing objects... will need to update rest of code later)
                                Dim objAmountBox As RadNumericTextBox = CallingPage.Form.FindControl(fldname)
                                Dim nContractLineItemID As Integer = objAmountBox.Attributes("ContractLineItemID")
                                Dim nReimb As Integer = objAmountBox.Attributes("Reimbursable")
                                Dim sJCAFCellName As String = objAmountBox.Attributes("JCAFCellName")

                                'Check for bad format
                                colValue = Val(colValue)

                                'get new row
                                Dim row As DataRow = dbDet.DataTable.NewRow()
                                fldname = Mid(fldname, 5)

                                nNewPayAmt = colValue
                                If bCalcPayableAmt Then
                                    If nRetPercent <> 0 Then
                                        nNewPayAmt = ProcLib.Round(nNewPayAmt * nRetPercent, 2)
                                    End If
                                End If

                                row("DistrictID") = nDistrictID
                                'row("CollegeID") = nCollegeID
                                row("ProjectID") = nProjectID
                                row("ContractID") = nContractID
                                row("TransactionID") = TransactionID
                                row("BudgetLineName") = sJCAFCellName


                                row("Reimbursable") = nReimb
                                row("ContractLineItemID") = nContractLineItemID

                                row("PayableAmount") = nNewPayAmt
                                row("Amount") = colValue
                                row("LastUpdateBy") = CallingPage.Session("UserName")
                                row("LastUpdateOn") = Now()



                                dbDet.DataTable.Rows.Add(row)
                                nRows = nRows + 1

                                'HACK -- get the associated account number from the contract line item and concatonate if mulitple and save to parent transactions
                                Dim sAcct As String = Trim(ProcLib.CheckNullDBField(db.ExecuteScalar("SELECT AccountNumber FROM ContractLineItems WHERE LineID = " & nContractLineItemID)))
                                If sAcct <> "" Then
                                    If InStr(sAccountNumber, sAcct) = 0 And sAccountNumber = "" Then
                                        sAccountNumber &= sAcct
                                    ElseIf sAccountNumber <> "" Then
                                        sAccountNumber &= ";" & sAcct
                                    End If
                                End If
                            End If
                        End If
                    Next
                    If nRows > 0 Then
                        dbDet.SaveDataTableToDB()
                    End If

                    db.ExecuteNonQuery("UPDATE Transactions SET AccountNumber = '" & sAccountNumber & "' WHERE TransactionID = " & TransactionID)

                End Using
            End If


        End Sub
        Public Sub DeleteTransaction(ByVal Transid As Integer)
            If Transid <> 0 Then  'need this to handle zeroed variable bug.
                db.ExecuteNonQuery("DELETE FROM Transactions WHERE TransactionID = " & Transid)
                db.ExecuteNonQuery("DELETE FROM WorkflowLog WHERE TransactionID = " & Transid)
                db.ExecuteNonQuery("DELETE FROM TransactionDetail WHERE TransactionID = " & Transid)
                db.ExecuteNonQuery("DELETE FROM Flags WHERE TransactionID = " & Transid)
                db.ExecuteNonQuery("DELETE FROM WorkflowLog WHERE TransactionID = " & Transid)
                db.ExecuteNonQuery("DELETE FROM AttachmentsLinks WHERE TransactionID = " & Transid)
                db.ExecuteNonQuery("DELETE FROM Notes WHERE TransactionID = " & Transid)
            End If

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
