Imports System
Imports System.Web
Imports System.Web.UI.WebControls
Imports System.IO
Imports System.Data.SqlClient

Namespace Prompt

    '********************************************
    '*  Alert Class
    '*  
    '*  Purpose: Processes data for the Alert Object
    '*
    '*  Last Mod By:    Ford James
    '*  Last Mod On:    4/2/10

    '*
    '********************************************

    Public Class promptAlert
        Implements IDisposable

        'Properties
        Public CallingPage As Page
        Public ParentRecID As Integer = 0
        Public ParentRecType As String = ""
        Public BudgetItemField As String = ""

        Private db As PromptDataHelper
        Private tblAlerts As DataTable

        Public Sub New()
            db = New PromptDataHelper
        End Sub

#Region "Subs and Functions"

        'Public Function GetAlerts(ByVal AlertView As String) As DataTable

        '    'gets contracts expired or expiring contracts within the next 30 day 
        '    Dim sql As String = ""
        '    Dim DistrictID As Integer = HttpContext.Current.Session("DistrictID")

        '    If AlertView = "" Then
        '        AlertView = "FlaggedItems"
        '    End If

        '    Dim tblAlerts As DataTable = New DataTable
        '    Dim col As New DataColumn

        '    col = New DataColumn
        '    col.DataType = Type.GetType("System.Int32")
        '    col.ColumnName = "CollegeID"
        '    tblAlerts.Columns.Add(col)

        '    col = New DataColumn
        '    col.DataType = Type.GetType("System.Int32")
        '    col.ColumnName = "ProjectID"
        '    tblAlerts.Columns.Add(col)

        '    col = New DataColumn
        '    col.DataType = Type.GetType("System.Int32")
        '    col.ColumnName = "ContractID"
        '    tblAlerts.Columns.Add(col)

        '    col = New DataColumn
        '    col.DataType = Type.GetType("System.String")
        '    col.ColumnName = "AlertType"
        '    tblAlerts.Columns.Add(col)

        '    col = New DataColumn
        '    col.DataType = Type.GetType("System.String")
        '    col.ColumnName = "Description"
        '    tblAlerts.Columns.Add(col)

        '    col = New DataColumn
        '    col.DataType = Type.GetType("System.String")
        '    col.ColumnName = "College"
        '    tblAlerts.Columns.Add(col)

        '    col = New DataColumn
        '    col.DataType = Type.GetType("System.String")
        '    col.ColumnName = "ProjectName"
        '    tblAlerts.Columns.Add(col)

        '    col = New DataColumn
        '    col.DataType = Type.GetType("System.String")
        '    col.ColumnName = "AlertInfo"
        '    tblAlerts.Columns.Add(col)

        '    'these cols for flags
        '    col = New DataColumn
        '    col.DataType = Type.GetType("System.String")
        '    col.ColumnName = "BudgetField"
        '    tblAlerts.Columns.Add(col)


        '    col = New DataColumn
        '    col.DataType = Type.GetType("System.Int32")
        '    col.ColumnName = "ContractDetailID"
        '    tblAlerts.Columns.Add(col)

        '    col = New DataColumn
        '    col.DataType = Type.GetType("System.Int32")
        '    col.ColumnName = "TransactionID"
        '    tblAlerts.Columns.Add(col)


        '    If AlertView = "AllAlerts" Or AlertView = "ExpiredContracts" Then

        '        'gets contracts expired or expiring contracts within the next 30 day 
        '        Dim sDate As String = DateAdd(DateInterval.Day, 31, Now()).ToShortDateString
        '        sql = "SELECT Contracts.*,Projects.ProjectName,Colleges.College, Contractors.Name AS Contractor  FROM Contracts INNER JOIN Contractors ON Contracts.ContractorID = Contractors.ContractorID "
        '        sql &= "INNER JOIN Projects ON Contracts.ProjectID = Projects.ProjectID INNER JOIN Colleges ON Projects.CollegeID = Colleges.CollegeID "
        '        sql &= " WHERE Contracts.Status = '1-Open' AND ExpireDate < '" & sDate & "' AND Contracts.DistrictID = " & DistrictID
        '        sql &= " ORDER BY ExpireDate "
        '        Dim tbl As DataTable = db.ExecuteDataTable(sql)
        '        For Each row As DataRow In tbl.Rows
        '            Dim sExpire As String = ProcLib.CheckNullDBField(row("ExpireDate"))
        '            Dim newrow As DataRow = tblAlerts.NewRow()

        '            newrow("CollegeID") = row("CollegeID")
        '            newrow("ProjectID") = row("ProjectID")
        '            newrow("BudgetField") = ""
        '            newrow("ContractDetailID") = 0
        '            newrow("TransactionID") = 0


        '            newrow("ContractID") = row("ContractID")
        '            newrow("ProjectName") = row("ProjectName")
        '            newrow("College") = row("College")

        '            newrow("Description") = row("Contractor") & " - " & row("Description")
        '            newrow("AlertInfo") = sExpire
        '            newrow("AlertType") = "Expired Contract"

        '            tblAlerts.Rows.Add(newrow)
        '        Next

        '    End If

        '    If AlertView = "AllAlerts" Or AlertView = "FlaggedItems" Then


        '        Using dbFlags As New promptFlag
        '            Dim tbl As DataTable = dbFlags.GetAllOpenFlags()

        '            For Each row As DataRow In tbl.Rows
        '                'Dim sExpire As String = ProcLib.CheckNullDBField(row("ExpireDate"))
        '                Dim newrow As DataRow = tblAlerts.NewRow()

        '                newrow("CollegeID") = row("CollegeID")
        '                newrow("ProjectID") = row("ProjectID")
        '                newrow("ContractID") = row("ContractID")
        '                newrow("BudgetField") = row("BudgetField")
        '                newrow("ContractDetailID") = row("ContractDetailID")
        '                newrow("TransactionID") = row("TransactionID")

        '                newrow("ProjectName") = row("ProjectName")
        '                newrow("College") = row("College")

        '                newrow("Description") = row("FlagDescription")
        '                newrow("AlertInfo") = row("CreatedBy")
        '                newrow("AlertType") = "Flagged " & row("FlagType")

        '                tblAlerts.Rows.Add(newrow)
        '            Next
        '        End Using

        '    End If

        '    If AlertView = "AllAlerts" Or AlertView = "ExpiredInsurance" Then


        '        'gets contract insurance expired or expiring within the next 60 days
        '        Dim sDate As String = DateAdd(DateInterval.Day, 61, Now()).ToShortDateString
        '        sql = "SELECT Contracts.*,Projects.ProjectName,Colleges.College, Contractors.Name AS Contractor  FROM Contracts INNER JOIN Contractors ON Contracts.ContractorID = Contractors.ContractorID "
        '        sql &= "INNER JOIN Projects ON Contracts.ProjectID = Projects.ProjectID INNER JOIN Colleges ON Projects.CollegeID = Colleges.CollegeID "
        '        sql &= " WHERE Contracts.Status = '1-Open' AND InsuranceExpireDate < '" & sDate & "' AND Contracts.DistrictID = " & DistrictID
        '        sql &= " ORDER BY InsuranceExpireDate "
        '        Dim tbl As DataTable = db.ExecuteDataTable(sql)
        '        For Each row As DataRow In tbl.Rows
        '            Dim sExpire As String = ProcLib.CheckNullDBField(row("ExpireDate"))
        '            Dim newrow As DataRow = tblAlerts.NewRow()

        '            newrow("CollegeID") = row("CollegeID")
        '            newrow("ProjectID") = row("ProjectID")
        '            newrow("BudgetField") = ""
        '            newrow("ContractDetailID") = 0
        '            newrow("TransactionID") = 0


        '            newrow("ContractID") = row("ContractID")
        '            newrow("ProjectName") = row("ProjectName")
        '            newrow("College") = row("College")

        '            newrow("Description") = row("Contractor") & " - " & row("Description")
        '            newrow("AlertInfo") = sExpire
        '            newrow("AlertType") = "Expired Insurance"

        '            tblAlerts.Rows.Add(newrow)
        '        Next

        '    End If

        '    Return tblAlerts

        'End Function

        'Public Sub LoadAlertViews(ByVal lst As DropDownList)

        '    Dim item As New ListItem


        '    item.Text = "All Alerts"
        '    item.Value = "AllAlerts"
        '    lst.Items.Add(item)

        '    item = New ListItem
        '    item.Text = "Flagged Items"
        '    item.Value = "FlaggedItems"
        '    item.Selected = True
        '    lst.Items.Add(item)

        '    item = New ListItem
        '    item.Text = "Expired Contracts"
        '    item.Value = "ExpiredContracts"
        '    lst.Items.Add(item)

        '    item = New ListItem
        '    item.Text = "Expired Insurance"
        '    item.Value = "ExpiredInsurance"
        '    lst.Items.Add(item)


        'End Sub



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
