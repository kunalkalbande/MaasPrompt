Imports System
Imports System.Web
Imports System.Web.UI.WebControls
Imports System.IO
Imports System.Data
Imports System.Data.SqlClient
Imports Telerik.Web.UI

Namespace Prompt

    '********************************************
    '*  Contract ChangeOrder Class
    '*  
    '*  Purpose: Processes data for the Contract ChangeOrder Object
    '*
    '*  Last Mod By:    Ford James
    '*  Last Mod On:    1/15/10
    '*
    '********************************************

    Public Class ContractChangeOrder
        Implements IDisposable

        'Properties
        Public CallingPage As Page

        'other contract info

        Public ParentContract As promptContract
        Private ContractDetailID As Integer = 0

        Public ContractLineItemID As Integer = 0
        Public ContractLineItemJCAFCellName As String = ""
        Public ContractLineItemObjectCode As String = ""
        Public ContractLineItemJCAFLine As String = ""
        Public ContractLineItemAccountNumber As String = ""
        Public ContractLineItemReimbursable As Integer = 0

        Private db As PromptDataHelper

        Public Sub New()
            db = New PromptDataHelper
            ParentContract = New promptContract
        End Sub

#Region "Subs and Functions"

        'Public Function GetChangeOrders(ByVal ContractID As Integer) As DataTable

        '    '******************* DEPRICATED WITH CONTRACT LINE ITEMS IMPLEMENATION ************************************

        '    'Dim sql As String = "SELECT ContractDetail.*, "
        '    'sql &= "(SELECT SUM(TransactionDetail.Amount) AS Expended FROM ContractLineItems "
        '    'sql &= "INNER JOIN TransactionDetail ON ContractLineItems.LineID = TransactionDetail.ContractLineItemID "
        '    'sql &= "WHERE ContractDetail.ContractDetailID = ContractLineItems.ContractChangeOrderID) AS Expended "
        '    'sql &= " FROM ContractDetail WHERE ContractID = " & ContractID & " ORDER BY CreateDate ASC"
        '    'Dim tbl As DataTable = db.ExecuteDataTable(sql)

        '    ''Add extra column
        '    'Dim col As New DataColumn
        '    'col.DataType = Type.GetType("System.Double")
        '    'col.ColumnName = "PendingAmount"
        '    'tbl.Columns.Add(col)

        '    'For Each row As DataRow In tbl.Rows                 'filter out amount for those records with no District Approval Date
        '    '    If Not IsDBNull(row("DistrictApprovalDate")) Then
        '    '        If IsDate(row("DistrictApprovalDate")) Then
        '    '            Dim dDistrictApprovalDate As Date = row("DistrictApprovalDate")
        '    '            If dDistrictApprovalDate < #1/2/2001# Then  'not approved
        '    '                row("PendingAmount") = row("Amount")
        '    '                row("Amount") = 0
        '    '            Else   'approved
        '    '                row("PendingAmount") = 0
        '    '            End If
        '    '        Else
        '    '            row("PendingAmount") = row("Amount")
        '    '            row("Amount") = 0
        '    '        End If

        '    '    Else
        '    '        row("PendingAmount") = row("Amount")
        '    '        row("Amount") = 0
        '    '    End If
        '    'Next

        '    'Return tbl

        'End Function

        Public Sub GetNewAmendment(ByVal nContractID As Integer)

            'ParentContract = New promptContract
            ParentContract.LoadContractInfo(nContractID)

            'get a blank contract record and populate with initial info
            Dim dt As DataTable
            Dim row As DataRow
            dt = db.ExecuteDataTable("SELECT * FROM ContractDetail WHERE ContractDetailID = 0")
            row = dt.NewRow()

            row("DetailType") = "Change Order"

            LoadEditForm(row)


        End Sub

        Public Sub GetExistingAmendment(ByVal nContractDetailID As Integer)

            'get a existing contract record and populate with  info
            Dim row As DataRow
            row = db.GetDataRow("SELECT * FROM ContractDetail WHERE ContractDetailID = " & nContractDetailID)

            'ParentContract = New promptContract
            ParentContract.LoadContractInfo(row("ContractID"))
            LoadContractLineItemInfo(nContractDetailID)

            LoadEditForm(row)

        End Sub

        Private Sub LoadContractLineItemInfo(ByVal nContractDetailID As Integer)

            Dim sql As String = "SELECT * FROM ContractLineItems WHERE ContractChangeOrderID = " & nContractDetailID
            Dim tbl As DataTable = db.ExecuteDataTable(sql)
            For Each row As DataRow In tbl.Rows         'there will be only one
                'get the associated contract line item for this co
                ContractLineItemID = row("LineID")
                ContractLineItemJCAFCellName = Trim(ProcLib.CheckNullDBField(row("JCAFCellName")))
                ContractLineItemObjectCode = Trim(ProcLib.CheckNullDBField(row("ObjectCode")))
                ContractLineItemJCAFLine = Trim(ProcLib.CheckNullDBField(row("JCAFLine")))
                ContractLineItemAccountNumber = Trim(ProcLib.CheckNullDBField(row("AccountNumber")))
                ContractLineItemReimbursable = Trim(ProcLib.CheckNullNumField(row("Reimbursable")))
            Next

        End Sub

        Private Sub LoadEditForm(ByVal row As DataRow)

            'loads a parent form with data from passed row
            Dim form As Control = CallingPage.FindControl("Form1")  ' get ref to calling form
            Dim sql As String = ""

            'Fill the dropdown controls on parent form
            sql = "SELECT LookupValue As Val, LookupTitle as Lbl FROM dbo.Lookups WHERE ParentTable = 'ContractDetail' AND ParentField = 'DetailType' ORDER By LookupTitle"
            db.FillDropDown(sql, form.FindControl("lstDetailType"), True, False, False)


            sql = "SELECT LookupValue As Val, LookupTitle as Lbl FROM dbo.Lookups WHERE ParentTable = 'ContractDetail' AND "
            sql &= "ParentField = 'Category' AND DistrictID=" & CallingPage.Session("DistrictID") & " ORDER By LookupTitle"
            db.FillDropDown(sql, form.FindControl("lstCategory"), False, False, False)

            sql = "SELECT Distinct ReferenceNo As Val, ReferenceNo as Lbl FROM ContractLineItems WHERE ContractID = " & ParentContract.ContractID & " AND ReferenceNo IS NOT Null ORDER BY ReferenceNo "
            db.FillNewRADComboBox(sql, form.FindControl("lstReferenceNo"), False, False, False)

            'load form
            db.FillForm(form, row)

        End Sub

        'Public Sub SaveAmendment(ByVal nContractDetailID As Integer, ByVal nContractID As Integer)

        '    ContractDetailID = nContractDetailID   'set globally for contract object

        '    'ParentContract = New promptContract
        '    ParentContract.LoadContractInfo(nContractID)

        '    Dim sql As String = ""
        '    Dim nLineID As Integer = 0

        '    If nContractDetailID = 0 Then  'this is new contract so add new 
        '        sql = "Insert Into ContractDetail "
        '        sql &= "(DistrictID,ProjectID,ContractID) "
        '        sql &= "VALUES ("
        '        sql &= CallingPage.Session("DistrictID") & "," & ParentContract.ProjectID & "," & nContractID & ")"
        '        sql &= ";SELECT NewKey = Scope_Identity()"  'return the new primary key
        '        nContractDetailID = db.ExecuteScalar(sql)

        '        'create a contract line item for this CO 
        '        sql = "Insert Into ContractLineItems "
        '        sql &= "(DistrictID,ProjectID,ContractID,LineType) "
        '        sql &= "VALUES ("
        '        sql &= CallingPage.Session("DistrictID") & "," & ParentContract.ProjectID & "," & nContractID & ",'ChangeOrder')"
        '        sql &= ";SELECT NewKey = Scope_Identity()"  'return the new primary key
        '        nLineID = db.ExecuteScalar(sql)

        '    Else

        '        nLineID = db.ExecuteScalar("SELECT LineID FROM ContractLineItems WHERE ContractChangeOrderID = " & nContractDetailID)

        '    End If

        '    'Saves the basic amendment fields
        '    db.SaveForm(CallingPage.Form, "SELECT * FROM ContractDetail WHERE ContractDetailID = " & nContractDetailID)

        '    SaveContractLineItem(nContractDetailID, nContractID, nLineID)


        'End Sub

        'Private Sub SaveContractLineItem(ByVal ChangeOrderID As Integer, ByVal nContractID As Integer, ByVal nLineID As Integer)

        '    Dim sql As String = ""

        '    'Update the rest of the info Directly
        '    Dim fform As Control = CallingPage.FindControl("Form1")

        '    Dim nAmount As Double = ProcLib.CheckNullNumField(DirectCast(fform.FindControl("txtAmount"), RadNumericTextBox).Value)

        '    Dim sJCAFCellName As String = DirectCast(fform.FindControl("txtJCAFCellName"), HiddenField).Value
        '    Dim sObjectCode As String = DirectCast(fform.FindControl("txtObjectCode"), HiddenField).Value
        '    Dim sJCAFLine As String = DirectCast(fform.FindControl("txxtJCAFLine"), HiddenField).Value
        '    Dim sLineObjectCodeDescription As String = DirectCast(fform.FindControl("txtLineObjectCodeDescription"), HiddenField).Value

        '    Dim sAccountNumber As String = DirectCast(fform.FindControl("txtAccountNumber"), TextBox).Text
        '    Dim sDescription As String = DirectCast(fform.FindControl("txtDescription"), TextBox).Text
        '    Dim sReferenceNo As String = DirectCast(fform.FindControl("lstReferenceNo"), RadComboBox).Text


        '    Dim bReimbursable As Boolean = DirectCast(fform.FindControl("chkReimbursable"), CheckBox).Checked
        '    Dim nReimbursable As Integer = 0
        '    If bReimbursable Then
        '        nReimbursable = 1
        '    End If

        '    'update related transaction detail records with reimb status
        '    sql = "UPDATE TransactionDetail SET Reimbursable = " & nReimbursable & " WHERE ContractLineItemID = " & nLineID
        '    db.ExecuteNonQuery(sql)


        '    db.FillDataTableForUpdate("SELECT * FROM ContractLineItems WHERE LineID = " & nLineID)
        '    For Each row As DataRow In db.DataTable.Rows   'there will be only one

        '        row("ObjectCode") = sObjectCode
        '        row("JCAFLine") = sJCAFLine
        '        row("JCAFCellName") = sJCAFCellName
        '        row("JCAFCellNameObjectCode") = sJCAFCellName & "::" & sObjectCode
        '        row("LineObjectCodeDescription") = sLineObjectCodeDescription

        '        row("CollegeID") = ParentContract.CollegeID
        '        row("ContractChangeOrderID") = ChangeOrderID
        '        row("Amount") = nAmount
        '        row("LineType") = "ChangeOrder"
        '        row("ReferenceNo") = sReferenceNo

        '        row("AccountNumber") = sAccountNumber

        '        row("Description") = sDescription
        '        row("Reimbursable") = nReimbursable

        '        row("LastUpdateOn") = Now()
        '        row("LastUpdateBy") = HttpContext.Current.Session("UserName")
        '    Next

        '    db.SaveDataTableToDB()



        'End Sub


        Public Function DeleteChangeOrder(ByVal nContractDetailID As Integer, ByVal nContractLineID As Integer) As String


            'check to see if any transaction detail lines assocciated
            Dim sErr As String = ""
            Dim result As Integer = db.ExecuteScalar("SELECT COUNT(TransactionSplitID) FROM TransactionDetail WHERE ContractLineItemID = " & nContractLineID)
            If result > 0 Then
                sErr = "Sorry, there are Transactions associated with this Change Order so it cannot be deleted. Please remove associated Transactions before deleting this item."
            End If


            If sErr = "" Then
                db.ExecuteNonQuery("DELETE FROM ContractDetail WHERE ContractDetailID = " & nContractDetailID)
                db.ExecuteNonQuery("DELETE FROM ContractLineItems WHERE ContractChangeOrderID = " & nContractDetailID)
            End If

            'sErr = "Sorry, temporarily cannot delete change orders."
            Return sErr

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
