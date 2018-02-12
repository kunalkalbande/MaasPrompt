Imports System
Imports System.Web
Imports System.Web.UI.WebControls
Imports System.IO
Imports System.Data
Imports System.Data.SqlClient
Imports Telerik.Web.UI

Namespace Prompt



    '********************************************
    '*  Contract Class
    '*  
    '*  Purpose: Processes data for the Contract Object
    '*
    '*  Last Mod By:    Ford James
    '*  Last Mod On:    07/15/07
    '*
    '********************************************

    Public Class promptContract
        Implements IDisposable

        'Properties
        Public CallingPage As Page

        'other contract info
        Public ContractTotal As Double = 0                      ' this is the original contract total
        Public ContractNonReimbursableTotal As Double = 0       ' this is the original non Reimb amount 
        Public ReimbursableAmount As Double = 0                 ' this is the original reimb amount 
        Public AmendTotal As Double = 0                         'this is total change orders (non Reimb)
        Public AmendReimbursableTotal As Double = 0                         'this is total change orders (Reimb)
        Public AllowanceAmount As Double = 0
        Public AlternateAmount As Double = 0
        Public TransTotal As Double = 0
        Public ReimbursableTransTotal As Double = 0
        Public NonReimbursableTransTotal As Double = 0

        Public TotalPaidTransactions As Double = 0
        Public TotalNonPaidTransactions As Double = 0

        Public ContractBalance As Double = 0

        Public TotalPendingChangeOrders As Double = 0
        Public TotalContractReimbursables As Double = 0

        Public TotalAdjustments As Double = 0

        Public TotalRetentionWithheld As Double = 0
        Public TotalRetentionPaid As Double = 0
        Public RemainingRetentionDue As Double = 0

        'Public ContractMinimumAmount As Double = 0   'based on encumbered transactions
        'Public ContractMaximumAmount As Double = 0  'based on budgeted object codes in the JCAF

        Public JCAFLineIsOverSpentForThisOC As Boolean = False    'to handle legacy overspent lines and signal in edit form

        Public WorkflowScenerioList As String = ""   'holds workflow scenerio ID list for this contract

        Public RetentionPercent As Integer = 0
        Public LastFiscalYearEnd As Date
        Public CurrentFiscalYear As String = Year(Now())
        Public ContractorID As Integer = 0
        Public PONumber As String = ""
        Public ParentProjectBondSeriesNumber As String = ""

        Public ObjectCode As String = ""
        Public AccountNumber As String = ""
        Public ContractType As String = ""

        Public CollegeID As Integer = 0
        Public ProjectID As Integer = 0
        Public ContractID As Integer = 0

        Private db As PromptDataHelper

        Public Sub New()
            db = New PromptDataHelper
        End Sub

#Region "Subs and Functions"

        Public Sub LoadContractInfo(ByVal nContractID As Integer)

            'loads current contract and related info (calced and static) into the class for use by other objects (i.e by transactions) 
            ContractID = nContractID

            ParentProjectBondSeriesNumber = ProcLib.CheckNullDBField(db.ExecuteScalar("SELECT BondSeriesNumber FROM Projects INNER JOIN Contracts ON Contracts.ProjectID = Projects.ProjectID WHERE ContractID =  " & ContractID))
            CurrentFiscalYear = ProcLib.CheckNullDBField(db.ExecuteScalar("SELECT FiscalYear FROM Districts WHERE DistrictID =  " & HttpContext.Current.Session("DistrictID")))
            If Val(CurrentFiscalYear) = 0 Then CurrentFiscalYear = Year(Now())

            db.FillReader("SELECT * FROM Contracts WHERE ContractID = " & ContractID)
            While db.Reader.Read
                RetentionPercent = ProcLib.CheckNullDBField(db.Reader("RetentionPercent"))
                PONumber = ProcLib.CheckNullDBField(db.Reader("BlanketPONumber"))
                AccountNumber = ProcLib.CheckNullDBField(db.Reader("AccountNumber"))
                ObjectCode = ProcLib.CheckNullDBField(db.Reader("ObjectCode"))
                ContractorID = ProcLib.CheckNullDBField(db.Reader("ContractorID"))
                ProjectID = ProcLib.CheckNullNumField(db.Reader("ProjectID"))
                CollegeID = ProcLib.CheckNullNumField(db.Reader("CollegeID"))

                WorkflowScenerioList = ProcLib.CheckNullDBField(db.Reader("WorkflowScenerioIDList"))

                ContractType = ProcLib.CheckNullDBField(db.Reader("ContractType"))

            End While
            db.Reader.Close()

            'Get the current Amounts for this contract
            Dim sql As String = ""

            'Orig Contract Non Reimb Amount
            sql = "SELECT IsNull(Sum(Amount),0) AS Amt FROM ContractLineItems WHERE ContractID = " & ContractID & " AND LineType='Contract' AND Reimbursable=0"
            ContractNonReimbursableTotal = db.ExecuteScalar(sql)

            'Orig Contract Reimb Amount
            sql = "SELECT IsNull(Sum(Amount),0) AS Amt FROM ContractLineItems WHERE ContractID = " & ContractID & " AND LineType='Contract' AND Reimbursable=1"
            ReimbursableAmount = db.ExecuteScalar(sql)

            'Current Allowance Amount
            sql = "SELECT IsNull(Sum(Amount),0) AS Amt FROM ContractLineItems WHERE ContractID = " & ContractID & " AND LineType = 'Allowance'"
            AllowanceAmount = db.ExecuteScalar(sql)

            'Current Alternate Amount
            sql = "SELECT IsNull(Sum(Amount),0) AS Amt FROM ContractLineItems WHERE ContractID = " & ContractID & " AND LineType = 'Alternate'"
            AlternateAmount = db.ExecuteScalar(sql)

            'Current Retention Amount
            sql = "SELECT IsNull(Sum(RetentionAmount),0) AS Amt FROM Transactions WHERE ContractID = " & ContractID
            TotalRetentionWithheld = db.ExecuteScalar(sql)

            'Current Retention Paid
            sql = "SELECT IsNull(Sum(PayableAmount),0) As Amt FROM Transactions WHERE ContractID = " & ContractID & " AND TransType = 'RetInvoice' "
            TotalRetentionPaid = db.ExecuteScalar(sql)

            RemainingRetentionDue = TotalRetentionWithheld - TotalRetentionPaid


            'Current Paid Transaction Total
            sql = "SELECT IsNull(Sum(Amount),0) As Amt FROM TransactionDetail INNER JOIN Transactions ON TransactionDetail.TransactionID = Transactions.TransactionID "
            sql &= "WHERE TransactionDetail.ContractID = " & ContractID & " AND Transactions.Status = 'Paid' "
            TotalPaidTransactions = db.ExecuteScalar(sql)

            'Current NonPaid Transaction Total
            sql = "SELECT IsNull(Sum(Amount),0) As Amt FROM TransactionDetail INNER JOIN Transactions ON TransactionDetail.TransactionID = Transactions.TransactionID "
            sql &= "WHERE TransactionDetail.ContractID = " & ContractID & " AND Transactions.Status <> 'Paid' "
            TotalNonPaidTransactions = db.ExecuteScalar(sql)



            'Current Transaction Total
            sql = "SELECT IsNull(Sum(Amount),0) As Amt FROM TransactionDetail WHERE ContractID = " & ContractID
            TransTotal = db.ExecuteScalar(sql)

            'Current Reimbursable Transaction Total
            sql = "SELECT IsNull(Sum(Amount),0) As Amt FROM TransactionDetail WHERE ContractID = " & ContractID & " AND Reimbursable=1"
            ReimbursableTransTotal = db.ExecuteScalar(sql)

            'Current NonReimbursable Transaction Total
            sql = "SELECT IsNull(Sum(Amount),0) As Amt FROM TransactionDetail WHERE ContractID = " & ContractID & " AND Reimbursable=0"
            NonReimbursableTransTotal = db.ExecuteScalar(sql)

            'Current Change Orders Total
            sql = "SELECT IsNull(Sum(Amount),0) As Amt FROM ContractDetail WHERE ContractID = " & ContractID & " AND ISDATE(DistrictApprovalDate) = 1"
            AmendTotal = db.ExecuteScalar(sql)

            'Current Change Order Reimb Total
            sql = "SELECT IsNull(Sum(Amount),0) As Amt FROM ContractLineItems WHERE ContractID = " & ContractID & " AND LineType='ChangeOrder'  AND Reimbursable=1"
            AmendReimbursableTotal = db.ExecuteScalar(sql)

            'Total Pending Change Orders
            sql = "SELECT IsNull(Sum(Amount),0) As Amt FROM ContractDetail WHERE ContractID = " & ContractID & " AND ISDATE(DistrictApprovalDate) = 0"
            TotalPendingChangeOrders = db.ExecuteScalar(sql)

            'Total TotalContractReimbursables
            sql = "SELECT IsNull(Sum(Amount),0) As Amt FROM ContractLineItems WHERE ContractID = " & ContractID & " AND Reimbursable=1"
            TotalContractReimbursables = db.ExecuteScalar(sql)


            'Total TotalContractAdjustments
            sql = "SELECT IsNull(Sum(Amount),0) As Amt FROM ContractLineItems WHERE ContractID = " & ContractID & " AND LineType='Adjustment' "
            TotalAdjustments = db.ExecuteScalar(sql)

            ContractTotal = ContractNonReimbursableTotal + ReimbursableAmount
            ContractBalance = ContractTotal + AmendTotal - TransTotal + TotalAdjustments

            LastFiscalYearEnd = "#01/01/1900#"
            Dim result As String = ProcLib.CheckNullDBField(db.ExecuteScalar("SELECT LastFiscalYearEnd FROM Colleges WHERE CollegeID = " & CollegeID))
            If IsDate(result) Then
                LastFiscalYearEnd = result
            End If


            ' GetCurrentObjectCodeMaximumAmount()
            'GetMinimumContractAmount()

        End Sub

        Public Sub GetNOCData(ByVal ContractID As Integer)

            'loads current contract NOC info 
            Dim sql As String = "SELECT LookupValue As Val, LookupTitle as Lbl FROM dbo.Lookups WHERE ParentTable = 'Contracts' AND ParentField = 'Surety' "
            sql &= " AND DistrictID = " & HttpContext.Current.Session("DistrictID") & "  ORDER By LookupTitle"
            db.FillDropDown(sql, CallingPage.FindControl("lstSurety"), True, False, False)

            sql = "SELECT * FROM Contracts WHERE ContractID = " & ContractID
            'pass the form and table to fill routine
            db.FillForm(CallingPage.FindControl("Form1"), sql)

        End Sub

        Public Sub GetAssignedWorkflowScenerios(ByVal lst As ListBox)

            Dim sql As String = "SELECT ScenerioName, WorkflowScenerioID FROM WorkflowScenerios WHERE AppliesTo = 'Transaction' AND DistrictID = " & CallingPage.Session("DistrictID")
            sql &= " ORDER BY ScenerioName "
            db.FillReader(sql)
            While db.Reader.Read()
                Dim strScenerioName As String = db.Reader("ScenerioName")
                Dim strScenerioID As String = ";" & CStr(db.Reader("WorkflowScenerioID")) & ";" 'need delim char due to number value

                'add the district
                Dim li As New ListItem(strScenerioName, strScenerioID)
                If InStr(WorkflowScenerioList, strScenerioID) > 0 Then
                    li.Selected = True
                End If
                lst.Items.Add(li)
            End While
            db.Reader.Close()
        End Sub

        Public Function HasPendingChangeOrders(ByVal ncontractID As Integer) As Boolean

            Dim sql As String = "SELECT * FROM ContractDetail WHERE ContractID = " & ncontractID
            Dim tbl As DataTable = db.ExecuteDataTable(sql)
            Dim result As Boolean = False
            For Each row As DataRow In tbl.Rows
                If Not IsDate(ProcLib.CheckNullDBField(row("DistrictApprovalDate"))) And row("Amount") <> 0 Then
                    result = True
                    Exit For
                End If

            Next
            Return result

        End Function


        'Public Overridable Sub GetCurrentObjectCodeMaximumAmount()

        '    'get the current maximum for the contract - this is current allocation remaining on the project (JCAF) for the object code assigned to this contract
        '    Dim sql As String = ""
        '    Dim nMaxJCAF As Double = 0
        '    Dim nContractsAlloc As Double = 0
        '    Dim nAmmends As Double = 0

        '    'Get total allocated to this OC in the JCAF
        '    sql = "SELECT ISNULL(SUM(Amount),0) AS Tot FROM BudgetObjectCodes WHERE ProjectID = " & ProjectID & " AND ObjectCode = '" & ObjectCode & "'"
        '    nMaxJCAF = db.ExecuteScalar(sql)

        '    'get total already allocated to other contracts in this project with same OC and subtract
        '    sql = "SELECT ISNULL(SUM(Amount),0) AS Tot FROM Contracts WHERE ProjectID = " & ProjectID & " AND ObjectCode = '" & ObjectCode & "' AND ContractID <> " & ContractID
        '    nContractsAlloc = db.ExecuteScalar(sql)


        '    'get total already allocated to amendments for this contract and subtract
        '    sql = "SELECT ISNULL(Sum(ContractDetail.Amount), 0) AS TOT FROM ContractDetail INNER JOIN Contracts ON ContractDetail.ContractID = Contracts.ContractID "
        '    sql &= "WHERE ContractDetail.ProjectID = " & ProjectID & " AND ObjectCode = '" & ObjectCode & "'"
        '    nAmmends = db.ExecuteScalar(sql)

        '    ContractMaximumAmount = nMaxJCAF - nContractsAlloc - nAmmends


        'End Sub

        'Public Overridable Sub GetCurrentObjectCodeMaximumAmount(ByVal sObjectCode As String, ByVal nProjectID As Integer, ByVal nContractID As Integer)
        '    'To allow getting just this amount when validaiting object code change in edit screen
        '    ObjectCode = sObjectCode
        '    ProjectID = nProjectID
        '    ContractID = nContractID
        '    GetCurrentObjectCodeMaximumAmount()

        'End Sub

        'Public Sub GetMinimumContractAmount()

        '    'get the current minimum for the contract - this is total of all current transactions posted against this contract + ammendments
        '    db.FillReader("SELECT * From qry_Get_ContractTotals WHERE ContractID = " & ContractID)
        '    While db.Reader.Read
        '        Dim nNonReimbTransTotal As Double = ProcLib.CheckNullNumField(db.Reader("NonReimbTransTotal"))
        '        Dim nReimbTransTotal As Double = ProcLib.CheckNullNumField(db.Reader("ReimbTransTotal"))
        '        Dim nTotalAmmendments As Double = ProcLib.CheckNullNumField(db.Reader("TotalAmmendments"))
        '        ContractMinimumAmount = nNonReimbTransTotal + nReimbTransTotal - nTotalAmmendments
        '    End While
        '    db.Reader.Close()

        'End Sub

        Public Sub GetNewContract(ByVal nProjectID As Integer)

            ProjectID = nProjectID  'set global project ID for class

            'get a blank contract record and populate with initial info
            Dim dt As DataTable
            Dim row As DataRow
            dt = db.ExecuteDataTable("SELECT * FROM Contracts WHERE ContractID = 0")
            row = dt.NewRow()

            row("PayStatus") = "Ok To Pay"
            row("Status") = "3-Pending"
            row("ContractorID") = 0
            row("ObjectCode") = "0"
            row("Amount") = 0
            row("ReimbAmount") = 0

            LoadEditForm(row)

        End Sub

        Public Function GetContractLineItems(ByVal nContractID As Integer) As DataTable

            LoadContractInfo(nContractID)

            

            Dim sql As String = "SELECT ContractLineItems.*,  ObjectCodes.ObjectCode + '-' + ObjectCodes.ObjectCodeDescription AS ObjectCodeDescription, BudgetFieldsTable.JCAFSection, "
            sql &= "BudgetFieldsTable.JCAFFundingSource, "
            sql &= "(SELECT     SUM(Amount) AS EXpr1 FROM TransactionDetail WHERE ContractLineItemID = ContractLineItems.LineID) AS Expended, "
            sql &= "ContractDetail.CreateDate, ContractDetail.CONumber, ContractDetail.DistrictApprovalDate, Contracts.Status AS ContractStatus "
            sql &= "FROM ContractLineItems INNER JOIN "
            sql &= "         Contracts ON ContractLineItems.ContractID = Contracts.ContractID LEFT OUTER JOIN"
            sql &= "         ContractDetail ON ContractLineItems.ContractChangeOrderID = ContractDetail.ContractDetailID LEFT OUTER JOIN"
            sql &= "         BudgetFieldsTable ON ContractLineItems.JCAFCellName = BudgetFieldsTable.ColumnName LEFT OUTER JOIN"
            sql &= "          ObjectCodes ON ContractLineItems.ObjectCode = ObjectCodes.ObjectCode AND ContractLineItems.DistrictID = ObjectCodes.DistrictID "
            sql &= "WHERE ContractLineItems.ContractID = " & nContractID & " "
            sql &= "ORDER BY ContractLineItems.LineType DESC, POLineNumber, Description ASC "

            Dim tbl As DataTable = db.ExecuteDataTable(sql)

            ''Add new columns
            Dim col As New DataColumn
            col = New DataColumn
            col.DataType = Type.GetType("System.String")
            col.ColumnName = "FundingSource"
            tbl.Columns.Add(col)

            col = New DataColumn
            col.DataType = Type.GetType("System.Double")
            col.ColumnName = "PendingAmount"
            tbl.Columns.Add(col)

            col = New DataColumn
            col.DataType = Type.GetType("System.String")
            col.ColumnName = "No"
            tbl.Columns.Add(col)


            For Each row As DataRow In tbl.Rows
                row("FundingSource") = row("JCAFFundingSource")

                If row("LineType") = "ChangeOrder" Then
                    row("LineType") = "CO"
                    row("No") = ProcLib.CheckNullDBField(row("CONumber"))

                    If Not IsDate(ProcLib.CheckNullDBField(row("DistrictApprovalDate"))) Then
                        row("PendingAmount") = row("Amount")
                        row("Amount") = 0

                    End If

                ElseIf row("LineType") = "Adjustment" Then
                    row("LineType") = "AD"
                    row("No") = ProcLib.CheckNullDBField(row("POLineNumber"))

                ElseIf row("LineType") = "DeductiveChangeOrder" Then
                    row("LineType") = "DCO"
                    row("No") = ProcLib.CheckNullDBField(row("POLineNumber"))


                ElseIf row("LineType") = "Allowance" Then
                    row("LineType") = "AL"
                    row("No") = ProcLib.CheckNullDBField(row("POLineNumber"))

                ElseIf row("LineType") = "Alternate" Then
                    row("LineType") = "ALT"
                    row("No") = ProcLib.CheckNullDBField(row("POLineNumber"))


                Else
                    row("LineType") = "CL"
                    row("No") = ProcLib.CheckNullDBField(row("POLineNumber"))
                End If


            Next

            'Update the FundingSource Column to custom name if used in this district
            Dim tblDistrict As DataTable = db.ExecuteDataTable("SELECT * FROM Districts WHERE DistrictID = " & HttpContext.Current.Session("DistrictID"))
            Dim rowDist As DataRow = tblDistrict.Rows(0)
            For Each row As DataRow In tbl.Rows
                Dim sSource As String = ProcLib.CheckNullDBField(row("JCAFFundingSource"))
                Select Case sSource
                    Case "Donation"
                        If ProcLib.CheckNullDBField(rowDist("JCAFDonationColumnName")) <> "" Then
                            row("FundingSource") = rowDist("JCAFDonationColumnName")
                        End If
                    Case "Grant"
                        If ProcLib.CheckNullDBField(rowDist("JCAFGrantColumnName")) <> "" Then
                            row("FundingSource") = rowDist("JCAFGrantColumnName")
                        End If

                    Case "Maint"
                        If ProcLib.CheckNullDBField(rowDist("JCAFMaintColumnName")) <> "" Then
                            row("FundingSource") = rowDist("JCAFMaintColumnName")
                        End If

                    Case "Hazmat"
                        If ProcLib.CheckNullDBField(rowDist("JCAFHazmatColumnName")) <> "" Then
                            row("FundingSource") = rowDist("JCAFHazmatColumnName")
                        End If

                End Select

                'If bLegacy Then    'update the items permenatly with ObjectCode info if legacy
                '    db.ExecuteNonQuery("UPDATE ContractLineItems SET LineObjectCodeDescription ='" & row("ObjectCodeDescription") & "' WHERE LineID = " & row("LineID"))
                'End If

            Next


            Return tbl


        End Function

        'Public Function GetJCAFLinesContainingBudgetAmounts(ByVal nProjectID As Integer) As DataTable

        '    'Builds a table that can be used in DropDown list for picking Object Codes with avaiable amounts to assign to Contract Line Items

        '    'Get all the budget lines/object codes/funding source that currently have allocated funds in the JCAF --
        '    'there might be many duplicate lines for a given bucket hence the sum/groupby
        '    Dim sql As String = "SELECT   BudgetFieldsTable.JCAFSection, BudgetFieldsTable.JCAFLine, "
        '    sql &= "BudgetFieldsTable.JCAFFundingSource, BudgetObjectCodes.JCAFColumnName "
        '    sql &= "FROM BudgetObjectCodes INNER JOIN BudgetFieldsTable ON BudgetObjectCodes.JCAFColumnName = BudgetFieldsTable.JCAFCellName "
        '    sql &= "WHERE BudgetObjectCodes.ProjectID = " & nProjectID & " "
        '    sql &= "GROUP BY  BudgetFieldsTable.JCAFLine, BudgetFieldsTable.JCAFSection, BudgetFieldsTable.JCAFLineDisplayOrder, "
        '    sql &= "BudgetFieldsTable.JCAFFundingSource, BudgetObjectCodes.JCAFColumnName "
        '    sql &= "ORDER BY BudgetFieldsTable.JCAFLineDisplayOrder"

        '    Dim tbl As DataTable = db.ExecuteDataTable(sql)

        '    'Add new columns
        '    Dim col As New DataColumn
        '    col.DataType = Type.GetType("System.String")
        '    col.ColumnName = "JCAFLineDescription"
        '    tbl.Columns.Add(col)


        '    'Update the FundingSource Column to custom name if used in this district
        '    Dim tblDistrict As DataTable = db.ExecuteDataTable("SELECT * FROM Districts WHERE DistrictID = " & HttpContext.Current.Session("DistrictID"))
        '    Dim rowDist As DataRow = tblDistrict.Rows(0)
        '    For Each row As DataRow In tbl.Rows
        '        Dim sSource As String = row("JCAFFundingSource")
        '        Select Case sSource
        '            Case "Donation"
        '                If ProcLib.CheckNullDBField(rowDist("JCAFDonationColumnName")) <> "" Then
        '                    row("JCAFFundingSource") = rowDist("JCAFDonationColumnName")
        '                End If
        '            Case "Grant"
        '                If ProcLib.CheckNullDBField(rowDist("JCAFGrantColumnName")) <> "" Then
        '                    row("JCAFFundingSource") = rowDist("JCAFGrantColumnName")
        '                End If

        '            Case "Maint"
        '                If ProcLib.CheckNullDBField(rowDist("JCAFMaintColumnName")) <> "" Then
        '                    row("JCAFFundingSource") = rowDist("JCAFMaintColumnName")
        '                End If

        '            Case "Hazmat"
        '                If ProcLib.CheckNullDBField(rowDist("JCAFHazmatColumnName")) <> "" Then
        '                    row("JCAFFundingSource") = rowDist("JCAFHazmatColumnName")
        '                End If

        '        End Select

        '        row("JCAFLineDescription") = row("JCAFSection") & " - " & row("JCAFLine") & " (" & row("JCAFFundingSource") & ")"

        '    Next

        '    'add global first row
        '    Dim newrow As DataRow = tbl.NewRow
        '    newrow("JCAFSection") = "Any"
        '    newrow("JCAFLine") = "Any"
        '    newrow("JCAFFundingSource") = "Any"
        '    newrow("JCAFColumnName") = "Any"
        '    newrow("JCAFLineDescription") = "Any"

        '    tbl.Rows.InsertAt(newrow, 0)

        '    Return tbl

        'End Function


        Public Function GetMaxOCJCAFCellAmountForContractLineItem(ByVal LineAmt As Double, ByVal ObjectCode As String, ByVal JCAFCell As String, ByVal ProjectID As Integer) As Double
            'returns the maximum available amount for the given oc/cell for this project

            Dim nMaxAvail As Double = 0

            Dim sql As String = "SELECT SUM(Amount) AS TotAmount FROM dbo.BudgetObjectCodes "
            sql &= "WHERE ProjectID = " & ProjectID & " AND ObjectCode ='" & ObjectCode & "' AND JCAFColumnName ='" & JCAFCell & "' "
            Dim TotalAllocated As Double = ProcLib.CheckNullNumField(db.ExecuteScalar(sql))

            'Now subtract already encumbered
            sql = "SELECT SUM(Amount) AS TotAmount FROM ContractLineItems "
            sql &= "WHERE ProjectID = " & ProjectID & " AND ObjectCode ='" & ObjectCode & "' AND JCAFCellName ='" & JCAFCell & "' "
            Dim TotalEncumbered As Double = ProcLib.CheckNullNumField(db.ExecuteScalar(sql))

            nMaxAvail = LineAmt + (TotalAllocated - TotalEncumbered)

            If nMaxAvail < LineAmt Then   'to accomodate overspent JCAF lines (Legacy)
                nMaxAvail = LineAmt
                JCAFLineIsOverSpentForThisOC = True
            End If

            Return nMaxAvail

        End Function
        Public Function GetTotalExpendedForContractLineItem(ByVal lineID As Integer) As Double
            'returns the total amount expended already against this line item 
            Dim sql As String = "SELECT SUM(Amount) AS TotAmount FROM TransactionDetail WHERE ContractLineItemID = " & lineID
            Dim result As Double = ProcLib.CheckNullNumField(db.ExecuteScalar(sql))

            Return result




        End Function


        Public Sub FillLineItemObjectCodeJCAFList(ByRef lst As RadComboBox, ByVal nProjectID As Integer, ByVal nLineID As Integer, Optional ByVal ShowAllLines As Boolean = False)

            'Fills a passed treeview control used in DropDown list for picking Object Codes with avaiable amounts to assign to Contract Line Items

            Dim tree As RadTreeView = DirectCast(lst.Items(0).FindControl("RadTreeView1"), RadTreeView)

            Dim sCurrenJCAFColOC As String = ""

            'Add None Line
            Dim node As New RadTreeNode
            node.Text = "--none--"
            node.Value = "--none--"

            'Add some attributes for validaion
            node.Attributes.Add("AvailableBalance", 0)
            node.Attributes.Add("OCDescription", "--none--")
            node.Attributes.Add("JCAFLine", "--none--")
            node.Attributes.Add("JCAFCellName", "--none--")
            node.Attributes.Add("ObjectCode", "--none--")


            tree.Nodes.Add(node)


            'Fill Object Code Line combo box with current value
            Dim sCurObjectCode As String = ""
            Dim sCurJCAFCell As String = ""
            Dim nCurAmount As Double = 0

            Dim tbl As DataTable = db.ExecuteDataTable("SELECT * FROM ContractLineItems WHERE LineID = " & nLineID)
            If tbl.Rows.Count > 0 Then

                sCurrenJCAFColOC = Trim(ProcLib.CheckNullDBField(tbl.Rows(0)("JCAFCellNameObjectCode")))

                If sCurrenJCAFColOC <> "" Then
                    lst.Items(0).Text = ProcLib.CheckNullDBField(tbl.Rows(0)("LineObjectCodeDescription"))
                    lst.Items(0).Value = ProcLib.CheckNullDBField(tbl.Rows(0)("JCAFCellNameObjectCode"))
                    lst.Items(0).Selected = True

                    sCurObjectCode = ProcLib.CheckNullDBField(tbl.Rows(0)("ObjectCode"))
                    sCurJCAFCell = ProcLib.CheckNullDBField(tbl.Rows(0)("JCAFCellName"))
                    nCurAmount = ProcLib.CheckNullNumField(tbl.Rows(0)("Amount"))


                End If

            Else
                lst.Items(0).Text = "--none--"
                lst.Items(0).Value = "--none--"
                lst.Items(0).Selected = True

            End If

            '*************************'Build the rest of the line-specific tree
            Dim sql As String = "SELECT * FROM qry_ContractLineItemsJCAFObjectCodeAllocations WHERE ProjectID = " & nProjectID
            sql &= "ORDER BY JCAFLineDisplayOrder,JCAFFundingSource,ObjectCode "
            Dim tblSource As DataTable = db.ExecuteDataTable(sql)


            ProcLib.SetCustomJCAFFundingSourceName(tblSource, "JCAFFundingSource") 'Update the FundingSource Column to custom name if used in this district


            'Dim col As DataColumn = New DataColumn
            'col.DataType = Type.GetType("System.Decimal")
            'col.ColumnName = "TotalProjectEncumbered"
            'tblSource.Columns.Add(col)

            'col = New DataColumn
            'col.DataType = Type.GetType("System.Decimal")
            'col.ColumnName = "TotalProjectJCAFNonEncumbered"
            'tblSource.Columns.Add(col)

            'col = New DataColumn
            'col.DataType = Type.GetType("System.Decimal")
            'col.ColumnName = "TotalJCAFLineItemOCNonEncumbered"     'this holds the available balance for this OC/JCAF Line combination
            'tblSource.Columns.Add(col)


            ''update the totals columns
            'For Each row As DataRow In tblSource.Rows
            '    row("TotalProjectEncumbered") = ProcLib.CheckNullNumField(row("ProjectTotalContractsObjectCodeEncumbered"))
            '    row("TotalProjectJCAFNonEncumbered") = row("ProjectJCAFObjectCodeTotal") - row("TotalProjectEncumbered")
            'Next

            Dim sNewJCAFLine As String = ""
            Dim sLastSection As String = ""
            Dim nodeparent As New RadTreeNode
            For Each row As DataRow In tblSource.Rows
                Dim sSection As String = row("JCAFSection")
                Dim sJCAFLine As String = row("JCAFLine")
                Dim sJCAFFundingSource As String = row("JCAFFundingSource")

                Dim sCurrentSection As String = sSection & sJCAFLine & sJCAFFundingSource

                If sCurrentSection <> sLastSection Then    'create root level parent

                    sLastSection = sSection & sJCAFLine & sJCAFFundingSource

                    Dim sParentDescription As String = ""
                    If sSection.Contains("5. Contingency") Then    'Remove redundancy/dirty description in master table (legacy)
                        sNewJCAFLine = sSection
                        sParentDescription = sSection & " - " & sJCAFFundingSource
                    ElseIf sSection.Contains("Furniture/Group II") Then
                        sNewJCAFLine = sJCAFLine
                        sParentDescription = sJCAFLine & " - " & sJCAFFundingSource
                    Else
                        sNewJCAFLine = sSection & " - " & sJCAFLine
                        sParentDescription = sSection & " (" & sJCAFLine & ") - " & sJCAFFundingSource
                    End If

                    nodeparent = New RadTreeNode
                    nodeparent.Text = sParentDescription
                    nodeparent.Value = "noselect"
                    nodeparent.ForeColor = System.Drawing.Color.Blue

                    tree.Nodes.Add(nodeparent)

                End If

                Dim sOC As String = row("ObjectCode")

                'Calc available balance for this JCAFLine/OC combo -- if the total available for the project for this object code
                'is more than was allocated on this specifc line, then the whole amount for the line can be allocated
                Dim nAvailableBal As Double = 0
                nAvailableBal = ProcLib.CheckNullNumField(row("ProjectJCAFObjectCodeTotal")) - ProcLib.CheckNullNumField(row("ProjectTotalContractsObjectCodeEncumbered")) - ProcLib.CheckNullNumField(row("ProjectTotalPassthroughObjectCodeEncumbered"))

                Dim sJCAFColOC As String = row("JCAFColumnName") & "::" & row("ObjectCode")

                If nAvailableBal > 0 Or sCurrenJCAFColOC = sJCAFColOC Or ShowAllLines = True Then    'always include the currently selected item
                    node = New RadTreeNode

                    'Need to add back in availble for currently selected line item
                    If sCurrenJCAFColOC = sJCAFColOC Then
                        nAvailableBal += nCurAmount
                        If nAvailableBal < nCurAmount Then    'this line is overspent realtive to allocted amount in JCAT (Legacy), so only show this items amount
                            nAvailableBal = nCurAmount
                        End If
                    End If


                    node.Text = row("Description") & " (" & FormatCurrency(nAvailableBal) & " Available)"
                    node.Value = sJCAFColOC

                    'Add some attributes for validaion
                    node.Attributes.Add("AvailableBalance", nAvailableBal)
                    node.Attributes.Add("OCDescription", row("Description"))
                    node.Attributes.Add("JCAFLine", sNewJCAFLine)
                    node.Attributes.Add("JCAFCellName", row("JCAFColumnName"))
                    node.Attributes.Add("ObjectCode", row("ObjectCode"))


                    nodeparent.Nodes.Add(node)
                End If
            Next

            'remove any nodes with no amounts except the current one -- have to do this in convoluted way due to enumeration error
            'on tree object -- so have to create new tree, copy desired nodes into it, remove all from orig tree, then copy back....
            Dim treeref As New RadTreeView
            'Add None Line
            node = New RadTreeNode
            node.Text = "--none--"
            node.Value = "--none--"

            'Add some attributes for validaion
            node.Attributes.Add("AvailableBalance", 0)
            node.Attributes.Add("OCDescription", "--none--")
            node.Attributes.Add("JCAFLine", "--none--")
            node.Attributes.Add("JCAFCellName", "--none--")
            node.Attributes.Add("ObjectCode", "--none--")

            treeref.Nodes.Add(node)

            For Each nodex As RadTreeNode In tree.Nodes
                If nodex.Nodes.Count > 0 Or sCurrenJCAFColOC = nodex.Attributes("JCAFCellName") & "::" & nodex.Attributes("ObjectCode") Then     'alwasy include current item
                    Dim newnode As RadTreeNode = nodex.Clone()
                    treeref.Nodes.Add(newnode)
                End If
            Next
            tree.Nodes.Clear()
            tree.LoadXmlString(treeref.GetXml())



            tree.BackColor = System.Drawing.Color.LightYellow
            tree.ExpandAllNodes()




        End Sub


        'Public Function GetObjectCodeLinesFromJCAF(ByVal CellName As String, ByVal nProjectID As Integer) As DataTable

        '    'Builds a table that can be used in DropDown list for picking Object Codes with avaiable amounts to assign to Contract Line Items

        '    'Get all the budget lines/object codes/funding source that currently have allocated funds in the JCAF --
        '    'there might be many duplicate object code lines for a given bucket (due to legacy functinality) hence the sum/groupby
        '    'NOTE: This is similar to GetJCAFLinesContainingBudgetAmounts proc except that it brings in actual amounts for each OC and calcs current balances

        '    Dim sql As String = "SELECT BudgetFieldsTable.JCAFSection, BudgetFieldsTable.JCAFLine, BudgetFieldsTable.JCAFFundingSource, BudgetObjectCodes.JCAFColumnName, "
        '    sql &= "SUM(BudgetObjectCodes.Amount) AS Amount, BudgetObjectCodes.ObjectCode, BudgetObjectCodes.Description,BudgetObjectCodes.ProjectID,"
        '    sql &= " (SELECT SUM(Amount) AS Expr1 FROM BudgetObjectCodes AS BO1 WHERE (BudgetObjectCodes.ProjectID = ProjectID) AND (BudgetObjectCodes.ObjectCode = ObjectCode)) AS JCAFObjectCodeGrandTotal "
        '    sql &= "FROM BudgetObjectCodes INNER JOIN BudgetFieldsTable ON BudgetObjectCodes.JCAFColumnName = BudgetFieldsTable.JCAFCellName "
        '    sql &= "WHERE BudgetObjectCodes.ProjectID = " & nProjectID & " "
        '    sql &= "GROUP BY  BudgetFieldsTable.JCAFLine, BudgetFieldsTable.JCAFSection, BudgetFieldsTable.JCAFLineDisplayOrder, "
        '    sql &= "BudgetFieldsTable.JCAFFundingSource, BudgetObjectCodes.JCAFColumnName, BudgetObjectCodes.ObjectCode, BudgetObjectCodes.Description,BudgetObjectCodes.ProjectID "
        '    sql &= "ORDER BY BudgetObjectCodes.ObjectCode"
        '    Dim tblSource As DataTable = db.ExecuteDataTable(sql)

        '    'Add new columns
        '    Dim col As New DataColumn
        '    col.DataType = Type.GetType("System.Decimal")
        '    col.ColumnName = "TotalContractEncumbered"      'holds the total encumered by all contracts and change orders under this project in all existing contracts for this object code
        '    tblSource.Columns.Add(col)

        '    col = New DataColumn
        '    col.DataType = Type.GetType("System.Decimal")
        '    col.ColumnName = "TotalChangeOrderEncumbered"   'holds the total encumered by all contract change orders under this project in all existing contracts for this object code
        '    tblSource.Columns.Add(col)

        '    col = New DataColumn
        '    col.DataType = Type.GetType("System.Decimal")
        '    col.ColumnName = "TotalAvailable"
        '    tblSource.Columns.Add(col)

        '    'Need to get current total Encumbered (i.e. in existing contracts + C/O's) for each object code. 
        '    sql = "SELECT Contracts.ProjectID, Contracts.ObjectCode, ContractDetail.DistrictApprovalDate, ContractDetail.Amount "
        '    sql &= "FROM ContractDetail INNER JOIN Contracts ON ContractDetail.ContractID = Contracts.ContractID "
        '    sql &= "WHERE Contracts.ProjectID = " & nProjectID & " ORDER BY Contracts.ObjectCode "
        '    Dim tblExistingChangeOrders As DataTable = db.ExecuteDataTable(sql)

        '    sql = "SELECT * FROM Contracts "
        '    sql &= "WHERE ProjectID = " & nProjectID & " ORDER BY Contracts.ObjectCode "
        '    Dim tblExistingContracts As DataTable = db.ExecuteDataTable(sql)

        '    'sql = "SELECT * FROM Transactions WHERE ProjectID = " & nProjectID & " AND TransType= 'Invoice' "
        '    'Dim tblExistingTransactions As DataTable = db.ExecuteDataTable(sql)




        '    For Each row As DataRow In tblSource.Rows

        '        'update encumbered totals
        '        Dim sObjectCode As String = row("ObjectCode")
        '        Dim nTotalContractEncumbered As Double = 0
        '        Dim nTotalChangeOrderEncumbered As Double = 0
        '        'Dim nTotalTransactions As Double = 0

        '        'Get total Contracts Encumbered
        '        For Each rowC As DataRow In tblExistingContracts.Rows
        '            If rowC("ObjectCode") = sObjectCode Then
        '                nTotalContractEncumbered += rowC("Amount") + rowC("ReimbAmount")
        '            End If
        '        Next

        '        'Get total Change Orders Encumbered
        '        For Each rowC As DataRow In tblExistingChangeOrders.Rows
        '            If rowC("ObjectCode") = sObjectCode Then
        '                Dim dDistApprDate As String = ProcLib.CheckNullDBField(rowC("DistrictApprovalDate"))
        '                If IsDate(dDistApprDate) Then
        '                    nTotalChangeOrderEncumbered += rowC("Amount")
        '                End If
        '            End If
        '        Next

        '        ''Get total Contracts Encumbered
        '        'For Each rowT As DataRow In tblExistingTransactions.Rows
        '        '    If rowT("ObjectCode") = sObjectCode Then
        '        '        nTotalTransactions += rowT("TotalAmount")
        '        '    End If
        '        'Next


        '        row("TotalContractEncumbered") = nTotalContractEncumbered
        '        row("TotalChangeOrderEncumbered") = nTotalChangeOrderEncumbered
        '        'row("TotalTransactions") = nTotalTransactions
        '        'row("TotalAvailable") = nTotalTransactions

        '    Next

        '    'now that we have a table with each oc line under this project in the JCAF and Total Encumberances for each Object Code, we can
        '    'determine available amount depending on if user is specifying a certain line, so simply (legacy) applying to aggregate OC total in JCAF

        '    Dim tblTarget As DataTable = tblSource.Clone()
        '    Dim newrow1 As DataRow = tblTarget.NewRow
        '    newrow1("ObjectCode") = "- none -"
        '    newrow1("Description") = "- none -"
        '    newrow1("TotalAvailable") = 0
        '    tblTarget.Rows.Add(newrow1)

        '    If CellName = "Any" Then       ' this is not specific to a JCAF line so need to agregate each OC and calc available bal
        '        Dim nOCTotal As Double = 0
        '        Dim sLastOC As String = ""
        '        Dim bFirstRow As Boolean = True
        '        For Each row As DataRow In tblSource.Rows
        '            If row("ObjectCode") <> sLastOC Or bFirstRow Then   'add this aggregate row to target
        '                sLastOC = row("ObjectCode")

        '                Dim newrow As DataRow = tblTarget.NewRow
        '                newrow("ObjectCode") = row("ObjectCode")
        '                newrow("Description") = row("Description")
        '                newrow("TotalAvailable") = row("JCAFObjectCodeGrandTotal") - row("TotalContractEncumbered") - row("TotalChangeOrderEncumbered")

        '                tblTarget.Rows.Add(newrow)
        '                bFirstRow = False
        '            End If
        '        Next

        '    Else   'this is specific line so include only OCs for that line

        '        For Each row As DataRow In tblSource.Rows
        '            If row("JCAFColumnName") = CellName Then   'add row to target
        '                Dim newrow As DataRow = tblTarget.NewRow
        '                newrow("ObjectCode") = row("ObjectCode")
        '                newrow("Description") = row("Description")
        '                newrow("TotalAvailable") = row("JCAFObjectCodeGrandTotal") - row("TotalContractEncumbered") - row("TotalChangeOrderEncumbered")

        '                tblTarget.Rows.Add(newrow)

        '            End If
        '        Next


        '    End If

        '    Return tblTarget

        'End Function

        Public Sub GetLineItemForEdit(ByVal LineID As Integer, ByVal ContractID As Integer)
            LoadContractInfo(ContractID)

            Dim sql As String = "SELECT Distinct ReferenceNo As Val, ReferenceNo as Lbl FROM ContractLineItems WHERE ContractID = " & ContractID & " AND ReferenceNo IS NOT Null ORDER BY ReferenceNo "
            db.FillNewRADComboBox(sql, CallingPage.FindControl("Form1").FindControl("lstReferenceNo"), False, False, False)


            If LineID > 0 Then
                db.FillForm(CallingPage.FindControl("Form1"), "SELECT * FROM ContractLineItems WHERE LineID = " & LineID)

            End If

        End Sub

        Public Sub SaveLineItem(ByVal nContractID As Integer, ByVal LineID As Integer)

            Dim sql As String = ""
            If LineID = 0 Then   'new record
                LoadContractInfo(nContractID)
                sql = "INSERT INTO ContractLineItems (DistrictID,CollegeID,ProjectID,ContractID,LineType) "
                sql &= "VALUES (" & HttpContext.Current.Session("DistrictID") & "," & CollegeID & "," & ProjectID & "," & nContractID & ",'Contract')"
                sql &= ";SELECT NewKey = Scope_Identity()"

                LineID = db.ExecuteScalar(sql)

            End If

            'Update record
            db.SaveForm(CallingPage.FindControl("Form1"), "SELECT * FROM ContractLineItems WHERE LineID = " & LineID)

            'Update the rest of the info Directly
            Dim fform As Control = CallingPage.FindControl("Form1")
            Dim sJCAFCellName As String = DirectCast(fform.FindControl("txtJCAFCellName"), HiddenField).Value
            Dim sObjectCode As String = DirectCast(fform.FindControl("txtObjectCode"), HiddenField).Value
            Dim sJCAFLine As String = DirectCast(fform.FindControl("txxtJCAFLine"), HiddenField).Value
            Dim sLineObjectCodeDescription As String = DirectCast(fform.FindControl("txtLineObjectCodeDescription"), HiddenField).Value

            Dim sLineAccountNumber As String = DirectCast(fform.FindControl("txtAccountNumber"), TextBox).Text

            Dim bReimbursable As Boolean = DirectCast(fform.FindControl("chkReimbursable"), CheckBox).Checked
            Dim nReimbursable As Integer = 0
            If bReimbursable Then
                nReimbursable = 1
            End If

            sql = "UPDATE ContractLineItems SET JCAFCellName ='" & sJCAFCellName & "' ,"
            sql &= "ObjectCode ='" & sObjectCode & "' ,"
            sql &= "JCAFLine ='" & sJCAFLine & "' ,"
            sql &= "JCAFCellNameObjectCode ='" & sJCAFCellName & "::" & sObjectCode & "' ,"
            sql &= "LineObjectCodeDescription ='" & sLineObjectCodeDescription & "', "
            sql &= "AccountNumber ='" & sLineAccountNumber & "' "
            sql &= " WHERE LineID = " & LineID

            db.ExecuteNonQuery(sql)

            'update related transaction detail records with reimb status and jcaf cell
            sql = "UPDATE TransactionDetail SET Reimbursable = " & nReimbursable & ",BudgetLineName = '" & sJCAFCellName & "' WHERE ContractLineItemID = " & LineID
            db.ExecuteNonQuery(sql)

            'Update the parent contract totals and Object Code for Legacy
            sql = "SELECT * FROM ContractLineItems WHERE ContractID = " & nContractID & " AND LineType = 'Contract'"
            Dim rs As DataTable = db.ExecuteDataTable(sql)
            Dim nNonReimbAmt As Double = 0
            Dim nReimbAmt As Double = 0
            Dim sLastObjectCode As String = ""
            For Each Row As DataRow In rs.Rows
                If Row("Reimbursable") = 1 Then
                    nReimbAmt += Row("Amount")
                Else
                    nNonReimbAmt += Row("Amount")
                End If
                sLastObjectCode = ProcLib.CheckNullDBField(Row("ObjectCode"))   'NOTE: This will only save the last Object Code in items list - for legacy only
            Next

            sql = "UPDATE Contracts SET Amount = " & nNonReimbAmt & ",ReimbAmount = " & nReimbAmt & ",ObjectCode = '" & sLastObjectCode & "' WHERE ContractID = " & nContractID
            db.ExecuteNonQuery(sql)

            'HACK -- Update any existing related Transaction Account Numbers with change acct number
            sql = "SELECT Transactions.TransactionID,Transactions.AccountNumber FROM TransactionDetail INNER JOIN Transactions ON TransactionDetail.TransactionID = Transactions.TransactionID "
            sql &= "WHERE TransactionDetail.ContractLineItemID = " & LineID
            Dim tblDet As DataTable = db.ExecuteDataTable(sql)
            For Each row As DataRow In tblDet.Rows
                Dim sAcct As String = Trim(ProcLib.CheckNullDBField(row("AccountNumber"))) 'HACK -- this will replace entire acct number with this one... problem with multiple accts later on.
                sql = "UPDATE Transactions SET AccountNumber = '" & sLineAccountNumber & "' WHERE TransactionID = " & row("TransactionID")
                db.ExecuteNonQuery(sql)
            Next
 

        End Sub

        Public Function DeleteLineItem(ByVal LineID As Integer) As String

            'check to see if any transaction detail lines assocciated
            Dim sErr As String = ""
            Dim result As Integer = db.ExecuteScalar("SELECT COUNT(TransactionSplitID) FROM TransactionDetail WHERE ContractLineItemID = " & LineID)
            If result > 0 Then
                sErr = "Sorry, there are Transactions associated with this line item so it cannot be deleted. Please remove associated Transactions before deleting this line item."
            End If


            If sErr = "" Then
                db.ExecuteNonQuery("DELETE FROM ContractLineItems WHERE LineID = " & LineID)
            End If

            Return sErr

        End Function

        Public Sub GetExistingContract(ByVal nContractID As Integer)

            ContractID = nContractID
            LoadContractInfo(nContractID)

            'get a existing contract record and populate with  info
            Dim row As DataRow
            row = db.GetDataRow("SELECT * FROM Contracts WHERE ContractID = " & nContractID)



            LoadEditForm(row)

        End Sub


        Private Sub LoadEditForm(ByVal row As DataRow)

            'loads a parent form with data from passed row
            Dim form As Control = CallingPage.FindControl("Form1")  ' get ref to calling form

            Dim nDistrictID As Integer = CallingPage.Session("DistrictID")
            Dim sql As String = ""



            'Fill the dropdown controls on parent form
            sql = "SELECT ContractorID As Val, Name as Lbl FROM Contractors WHERE DistrictID = " & nDistrictID & " OR ContractorID = 0 ORDER BY NAME"
            db.FillDropDown(sql, CallingPage.FindControl("pvGeneral").FindControl("lstContractorID"), True, False, False)


            sql = "SELECT LookupValue As Val, LookupTitle as Lbl FROM dbo.Lookups WHERE ParentTable = 'Contracts' AND ParentField = 'PayStatus' ORDER By LookupTitle"
            db.FillDropDown(sql, CallingPage.FindControl("pvGeneral").FindControl("lstPayStatus"), False, False, False)


            sql = "SELECT LookupValue As Val, LookupTitle as Lbl FROM dbo.Lookups WHERE ParentTable = 'Contracts' AND ParentField = 'Status' ORDER By LookupTitle"
            db.FillDropDown(sql, CallingPage.FindControl("pvGeneral").FindControl("lstStatus"), False, False, False)

            sql = "SELECT LookupValue As Val, LookupTitle as Lbl FROM dbo.Lookups WHERE ParentTable = 'Contracts' AND ParentField = 'RetentionPercent' ORDER By LookupTitle"
            db.FillDropDown(sql, CallingPage.FindControl("pvGeneral").FindControl("lstRetentionPercent"), False, False, False)

            sql = "SELECT LookupValue As Val, LookupTitle as Lbl FROM dbo.Lookups WHERE DistrictID = " & nDistrictID & " AND ParentTable = 'Contracts' AND ParentField = 'ContractType' "
            db.FillDropDown(sql, CallingPage.FindControl("pvGeneral").FindControl("lstContractType"), False, False, False)

            'HACK! - Only fill this for FHDA at present
            If HttpContext.Current.Session("DistrictID") = 55 Then
                sql = "SELECT PONumber As Val, PONumber as Lbl FROM FRS_PONumbers ORDER BY PONumber "
                db.FillRADComboBox(sql, CallingPage.FindControl("pvGeneral").FindControl("cboBlanketPONumber"), True, False, False)
            End If

            ''Filter the Object Codes to include only allocated codes in JCAF
            'sql = "SELECT ObjectCode AS Val, ObjectCodeDescription AS Lbl FROM ObjectCodes "
            'sql &= "WHERE (DistrictID = " & nDistrictID & " AND ObjectCode IN "
            'sql &= "(SELECT DISTINCT ObjectCode FROM BudgetObjectCodes WHERE ProjectID = " & ProjectID & " )) "
            'sql &= "ORDER BY Val "
            'db.FillDropDown(sql, CallingPage.FindControl("pvGeneral").FindControl("lstObjectCode"), True, False, True)

            'sql = "SELECT DivName as Val, DivName as Lbl FROM FE_Budgets WHERE DistrictID = " & nDistrictID
            'sql &= " Union Select 'Historical', '---Historical---' Order By DivName"
            'db.FillDropDown(sql, CallingPage.FindControl("pvGeneral").FindControl("lstFE_Division"), True, False, False)

            'load form
            db.FillForm(CallingPage.FindControl("pvGeneral"), row)
            'db.FillForm(CallingPage.FindControl("pvLineItems"), row)
            db.FillForm(CallingPage.FindControl("pvWorkflow"), row)

        End Sub

        Public Sub SaveContract(ByVal nContractID As Integer, ByVal nProjectID As Integer)

            ContractID = nContractID   'set globally for contract object

            If nContractID = 0 Then  'this is new contract so add new 
                Dim Sql As String = "Insert Into Contracts "
                Sql &= "(DistrictID,CollegeID,ProjectID) "
                Sql &= "VALUES ("
                Sql &= CallingPage.Session("DistrictID") & "," & CallingPage.Session("CollegeID") & "," & nProjectID & ")"
                Sql &= ";SELECT NewKey = Scope_Identity()"  'return the new primary key

                ContractID = db.ExecuteScalar(Sql)

            End If

            'Saves the basic contract fields
            db.FillDataTableForUpdate("SELECT * FROM Contracts WHERE ContractID = " & ContractID)
            Dim pvGeneral As Control = CallingPage.FindControl("pvGeneral")
            db.SaveMultipleFormControlsToDB(pvGeneral)

            db.SaveDataTableToDB()

            'Update workflow scenerio selection if needed
            If HttpContext.Current.Session("EnableWorkflow") = "1" Then
                Dim sScenerios As String = ""
                Dim lst As ListBox = CallingPage.Form.FindControl("lstWorkflowScenerios")
                For Each item As ListItem In lst.Items
                    If item.Selected = True Then
                        sScenerios &= item.Value
                    End If
                Next

                Dim sql As String = "UPDATE Contracts SET WorkflowScenerioIDList = '" & sScenerios & "' WHERE ContractID = " & ContractID
                db.ExecuteNonQuery(sql)
            End If


        End Sub

        Public Function DeleteContract(ByVal ContractID As Integer) As String

            Dim msg As String = ""
            Dim sql As String = ""
            Dim cnt As Integer = 0
            sql = "SELECT COUNT(TransactionID) as TOT FROM Transactions WHERE ContractID = " & ContractID
            cnt = db.ExecuteScalar(sql)

            sql = "SELECT COUNT(ContractDetailID) as TOT FROM ContractDetail WHERE ContractID = " & ContractID
            cnt += db.ExecuteScalar(sql)

            If cnt > 0 Then                 'display a popup warning and close edit page
                msg = "There are Ammendments or Transactions associtated with this Contract. Please Delete all associated records before deleting this contract. "
            End If

            If msg = "" Then

                Using att As New promptAttachment             'Get the parent Node for the deleted Contract and Parms for removal of Attachment Dir
                    db.FillDataTable("SELECT DistrictID,CollegeID,ProjectID FROM Contracts WHERE ContractID = " & ContractID)
                    With att                'Remove the Attachment Directory
                        .DistrictID = db.DataTable.Rows(0).Item("DistrictID")
                        .CollegeID = db.DataTable.Rows(0).Item("CollegeID")
                        .ProjectID = db.DataTable.Rows(0).Item("ProjectID")
                        .ContractID = ContractID
                        .DeleteAttachmentDir()
                    End With
                End Using

                db.ExecuteNonQuery("DELETE FROM Contracts WHERE ContractID = " & ContractID)
                db.ExecuteNonQuery("DELETE FROM ContractLineItems WHERE ContractID = " & ContractID)

            End If

            Return msg

        End Function



        Public Sub SaveNOCData(ByVal nContractID As Integer)

            'Saves the basic contractNOC fields
            db.SaveForm(CallingPage.Form, "SELECT * FROM Contracts WHERE ContractID = " & nContractID)

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
