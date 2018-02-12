Imports System
Imports System.Web
Imports System.Web.UI.WebControls
Imports System.IO
Imports System.Data
Imports System.Data.SqlClient
Imports System.Net.Mail
Imports System.Text

Namespace Prompt

    '********************************************
    '*  Workflow Class
    '*  
    '*  Purpose: Processes data for the Workflow objects
    '*
    '*  Last Mod By:    Ford James
    '*  Last Mod On:    12/14/11
    '*
    '********************************************

    Public Class promptWorkflow
        Implements IDisposable

        'Properties
        Public CallingPage As Page
        Private db As PromptDataHelper

        Public Reader As SqlDataReader
        Public DataTable As DataTable

        Public RecordType As String = ""
        Public PADID As Integer = 0
        Public TransactionID As Integer = 0
        Public TransactionTotalAmount As Double = 0
        Public TransactionRetentionAmount As Double = 0

        Public IsMultiApproval As Boolean = False    'denotes that this is part of multiple approval action

        Public IsFinalApprover As Boolean = False    'denotes that this role is final approver for workflow chain as defined in scenario owners

        Public Action As String = ""    'action taken on workflow item
        Public Target As String = ""    'person recieving item in next stage of workflow
        Public TargetRoleID As Integer = 0

        Public LastOwnerRoleID As Integer = 0   'for storing the last Owners ID 
        Public LastOwnerRole As String = ""   'for storing last Owners Role
        Public LastOwnerEmailAddress As String = ""  ' for storing last Owners email
        Public LastWorkflowAction As String = ""  ' for storing last workflow action

        Public TransactionInfo As String = ""   'for storing condensed transaction info for inclusion in emails and logs
        Public WorkflowScenerioID As Integer = 0   'for storing current workflow scenerio ID info   

        Public FRSCheckMessageCode As String = ""  ' to hold the check message code for FRS
        Public FRSRetentionCheckMessageCode As String = ""  ' to hold the check message code for FRS Retention Bank Check
        Public FRSCutSingleCheck As String = ""    'to indicate if single check should be cut - = S if yes 

        Public TransactionWorkflowRoleType As String = ""    'holds the current workflow role type for a given transaction
        Public MaxDollarApprovalLevel As Double = 0    'to store the highest dollar approval level in the mix
        Public IsCurrentlyInWorkflow As Boolean = False    'flag that tells the trans edit screen to disable the scenerio list box once in workflow
        Public WorkflowScenerioApprovalAmount As Double = 0   'store max approval amount for owners in scenerio


        Public Sub New()
            db = New PromptDataHelper
        End Sub

#Region "Subs and Functions"


        'Public Function GetWorkflowHistory(ByVal TransactionID As Integer) As DataTable
        '    'gets workflow history for given transaction for display in history popup window
        '    Dim sql As String = ""
        '    sql = "SELECT *, CONVERT(CHAR(10),CreatedOn,101) as CreatedOnDate FROM WorkflowLog WHERE TransactionID = " & TransactionID & " ORDER BY CreatedOn DESC "
        '    Return db.ExecuteDataTable(sql)
        'End Function

        Public Sub ResetWorkflowHistoryAndStatus(ByVal TransactionID As Integer)
            'purges workflow history for given transaction and resets workflow routing/status to generic FDO

            If TransactionID > 0 Then

                'delete all the current workflow entries for this transaction
                Dim sql As String = "DELETE FROM WorkflowLog WHERE TransactionID = " & TransactionID
                db.ExecuteNonQuery(sql)

                'Update the transaction
                sql = "UPDATE Transactions SET "
                sql &= "LastWorkflowAction = 'At FDO',"
                sql &= "LastWorkflowActionOn = NULL,"
                sql &= "PreviousWorkflowRoleID = 0,"
                sql &= "CurrentWorkflowRoleID = 0,"
                sql &= "CurrentWorkflowOwner = '-- none --',"
                sql &= "CurrentWorkflowOwnerNotifiedOn = NULL,"
                sql &= "WorkflowScenerioID = 0,"
                'sql &= "Status = 'Open',"
                sql &= "FRSCheckMessageCode = '',"
                sql &= "FRSCutSingleCheck = '',"
                sql &= "FRSRetentionCheckMessageCode = '',"
                sql &= "ExportedOn = NULL "

                sql &= "WHERE TransactionID = " & TransactionID

                db.ExecuteNonQuery(sql)

            End If
        End Sub

        Public Sub ResetDistrictWorkflowHistoryAndStatus(ByVal DistrictID As Integer)
            'purges workflow history for entire district resets workflow routing/status to generic FDO

            If DistrictID > 0 Then

                'delete all the current workflow entries for this transaction
                Dim sql As String = "DELETE FROM WorkflowLog WHERE DistrictID = " & DistrictID
                db.ExecuteNonQuery(sql)

                sql = "SELECT TransactionID FROM Transactions WHERE DistrictID = " & DistrictID
                db.FillReader(sql)
                Using rs As New PromptDataHelper
                    While db.Reader.Read
                        'Update the transaction
                        sql = "UPDATE Transactions SET "
                        sql &= "LastWorkflowAction = 'At FDO',"
                        sql &= "LastWorkflowActionOn = NULL,"
                        sql &= "PreviousWorkflowRoleID = 0,"
                        sql &= "CurrentWorkflowRoleID = 0,"
                        sql &= "CurrentWorkflowOwner = '-- none --',"
                        sql &= "CurrentWorkflowOwnerNotifiedOn = NULL,"
                        sql &= "WorkflowScenerioID = 0,"
                        sql &= "FRSCheckMessageCode = '',"
                        sql &= "FRSCutSingleCheck = '',"
                        sql &= "FRSRetentionCheckMessageCode = '',"
                        sql &= "ExportedOn = NULL "

                        sql &= "WHERE TransactionID = " & db.Reader("TransactionID")

                        rs.ExecuteNonQuery(sql)
                    End While
                    db.Reader.Close()
                End Using
            End If
        End Sub



        Public Function IsWorkflowDistrict(ByVal DistrictID As Integer) As String

            Dim sql As String = ""
            sql = "SELECT EnableWorkflow FROM Districts WHERE DistrictID = " & DistrictID
            Dim result = db.ExecuteScalar(sql)
            If Not IsDBNull(result) Then
                Return result
            Else
                Return ""
            End If
        End Function

        Public Function IsRetentionScenario(ByVal ScenarioID As Integer) As Boolean

            Dim sql As String = ""
            sql = "SELECT IsRetentionScenario FROM WorkflowScenerios WHERE WorkflowScenerioID = " & ScenarioID
            Dim result = db.ExecuteScalar(sql)
            If Not IsDBNull(result) Then
                If result = 1 Then
                    Return True
                Else
                    Return False
                End If
            Else
                Return False
            End If
        End Function

        Public Function GetInboxWorkflowTransactions(ByVal WorkflowOwnerID As Integer) As DataTable
            'gets workflow transactions for given and district
            Dim tbl As DataTable
            Dim tblPAD As DataTable
            If WorkflowOwnerID = 0 Then
                WorkflowOwnerID = -99     'dummy to make sure query returns empty datatable to trigger no records message on grid
            End If

            'HACK: In order to return a table with the correct fields regardless of if there are records (to avoid a harry union), we
            'need to fill a table with an inital set of data, then filter for valid data if any. Not elegeant but faster than rewriting 
            'funtion at this point.
            'So... get all the records for the district, then filter out 

            Dim sql As String = ""
            sql = "SELECT * FROM qry_GetWorkflowTransactions WHERE DistrictID = " & HttpContext.Current.Session("DistrictID")
            'sql &= " AND CurrentWorkflowRoleID = " & WorkflowOwnerID & " AND Status = 'FDO Approved'"
            tbl = db.ExecuteDataTable(sql)

            'Add RecordType and PADID fieldto table
            Dim colPADID As DataColumn = New DataColumn("PADID", System.Type.GetType("System.Int32"))
            Dim colRecType As DataColumn = New DataColumn("RecordType", System.Type.GetType("System.String"))
            tbl.Columns.Add(colPADID)
            tbl.Columns.Add(colRecType)

            'Filter out bad data and update the new colmns in the transaction records
            For Each row As DataRow In tbl.Rows
                If row("CurrentWorkflowRoleID") <> WorkflowOwnerID Or row("Status") <> "FDO Approved" Then
                    row.Delete()
                Else
                    row("PADID") = 0
                    row("RecordType") = "Transaction"
                End If
            Next


            'Gets PADs ready for Approval If Any
            sql = "SELECT * FROM qry_GetWorkflowPADS WHERE DistrictID = " & HttpContext.Current.Session("DistrictID")
            sql &= " AND CurrentWorkflowRoleID = " & WorkflowOwnerID & " AND Status = 'Pending Approval'"
            tblPAD = db.ExecuteDataTable(sql)

            For Each row As DataRow In tblPAD.Rows
                Dim newrow As DataRow = tbl.NewRow
                newrow("ProjectID") = row("ProjectID")
                newrow("CollegeID") = row("CollegeID")
                newrow("ContractID") = 0
                newrow("TransactionID") = 0
                newrow("Attachments") = 1       'this is assumed as the record could not be in workflow otherwise
                newrow("College") = row("College")
                newrow("PADID") = row("PADID")
                newrow("RecordType") = "PAD"
                newrow("TransType") = "PAD"
                newrow("ModTransType") = "PAD"
                newrow("ContractType") = "PAD"

                newrow("ProjectNumber") = row("ProjectNumber")
                newrow("ProjectName") = row("ProjectName")
                newrow("Status") = row("Status")


                tbl.Rows.Add(newrow)
            Next


            Return tbl

        End Function



        Public Sub LoadRoutingTargetListBoxes()

            Dim sql As String = ""

            If RecordType = "Transaction" Then
                LoadTransactionInfo(TransactionID)
            Else
                LoadPADInfo(PADID)

            End If


            Dim lstApprove As DropDownList = DirectCast(CallingPage.FindControl("lstApproveTarget"), DropDownList)
            Dim lstReject As DropDownList = DirectCast(CallingPage.FindControl("lstRejectTarget"), DropDownList)

            'determine if the current user is a signator for this scenerio
            'Returns if passed role is a signator for the passed scenerio
            sql = "SELECT IsNull(WorkflowScenerioOwners.IsSignator,0) as IsSignator, IsNull(WorkflowScenerioOwners.IsFinalApprover,0) as IsFinalApprover, IsNull(WorkflowRoles.ApprovalDollarLimit,0) As ApprovalDollarLimit, WorkflowScenerioOwners.WorkflowRoleID "
            sql &= "FROM WorkflowScenerioOwners INNER JOIN WorkflowRoles ON WorkflowScenerioOwners.WorkflowRoleID = WorkflowRoles.WorkflowRoleID "
            sql &= "WHERE WorkflowScenerioOwners.WorkflowRoleID = " & CallingPage.Session("WorkflowRoleID") & " AND WorkflowScenerioID = " & WorkflowScenerioID

            Dim nCurrentRoleDollarLimit As Double = 0
            Dim bIsSignator As Boolean = False
            db.FillReader(sql)
            While db.Reader.Read
                nCurrentRoleDollarLimit = db.Reader("ApprovalDollarLimit")
                bIsSignator = db.Reader("IsSignator")
                IsFinalApprover = db.Reader("IsFinalApprover")
            End While
            db.Reader.Close()

            Dim rs As SqlDataReader
            'get the target list
            sql = "SELECT * FROM qry_GetWorkflowTargets "
            sql &= "WHERE WorkflowRoleID = " & CallingPage.Session("WorkflowRoleID") & " AND WorkflowScenerioID = " & WorkflowScenerioID & " "
            sql &= " ORDER BY TargetAction, Priority, TargetRole"
            rs = db.ExecuteReader(sql)

            If Not rs.HasRows And RecordType = "PAD" Then   'determine with if this is a PM/PE originator and if so load list from PADOriginator Default
                rs.Close()
                sql = "SELECT * FROM qry_GetWorkflowTargets "
                sql &= "WHERE WorkflowRoleID = 81 AND WorkflowScenerioID = " & WorkflowScenerioID & " "    'HACK -- hard coded PADOriginator Role record number for testing
                sql &= " ORDER BY TargetAction, Priority, TargetRole"
                rs = db.ExecuteReader(sql)

            End If

            While rs.Read

                Dim sTargetName As String = rs("UserName") & " (" & rs("TargetRole") & ")"

                If rs("TargetAction") = "Approved" Then
                    Dim item As New ListItem
                    item.Text = sTargetName
                    item.Value = rs("TargetRoleID")

                    If bIsSignator Then   'need to make sure only add approval targets have authority for trans amount if current user has less
                        If nCurrentRoleDollarLimit < TransactionTotalAmount Then
                            If rs("ApprovalDollarLimit") > TransactionTotalAmount Then 'add the target
                                lstApprove.Items.Add(item)
                            End If
                        Else
                            lstApprove.Items.Add(item)
                        End If
                    Else
                        lstApprove.Items.Add(item)
                    End If
                End If
                If rs("TargetAction") = "Rejected" Then
                    Dim item As New ListItem
                    item.Text = sTargetName
                    item.Value = rs("TargetRoleID")
                    If item.Value = GetSendersWorkflowRoleID() Then
                        item.Selected = True
                    End If
                    lstReject.Items.Add(item)
                End If
            End While
            rs.Close()

            'Rebuild the reject list if Limit to Approved is flagged to only those who previously Approved
            Dim result As Integer = db.ExecuteScalar("SELECT LimitRejectionList FROM WorkflowScenerios WHERE WorkflowScenerioID = " & WorkflowScenerioID)
            If result = 1 And RecordType <> "PAD" Then
                lstReject.Items.Clear()

                sql = "SELECT WorkflowRoleID FROM WorkflowLog WHERE TransactionID = " & TransactionID & " AND WorkflowAction LIKE 'Approved by%' "
                sql &= "AND WorkflowRoleID <> " & CallingPage.Session("WorkflowRoleID") & "  ORDER BY CreatedOn"
                db.FillReader(sql)
                Dim sRejectTargets As String = ""
                While db.Reader.Read
                    sRejectTargets &= db.Reader("WorkflowRoleID") & ","
                End While
                db.Reader.Close()

                If sRejectTargets <> "" Then
                    sRejectTargets = Left(sRejectTargets, sRejectTargets.Length - 1)  'strip out last ,

                    sql = "SELECT Users.UserName, WorkflowRoles.WorkflowRole, WorkflowRoles.WorkflowRoleID "
                    sql &= "FROM WorkflowRoles INNER JOIN Users ON WorkflowRoles.UserID = Users.UserID "
                    sql &= "WHERE WorkflowRoleID IN(" & sRejectTargets & ")"
                    db.FillReader(sql)

                    While db.Reader.Read
                        Dim sTargetName As String = db.Reader("UserName") & " (" & db.Reader("WorkflowRole") & ")"
                        Dim item As New ListItem
                        item.Text = sTargetName
                        item.Value = db.Reader("WorkflowRoleID")
                        If item.Value = GetSendersWorkflowRoleID() Then
                            item.Selected = True
                        End If
                        lstReject.Items.Add(item)
                    End While
                    db.Reader.Close()
                End If

            End If

            'Make Sure Originator is alwasys a Reject Target for PADS
            If RecordType = "PAD" Then

                sql = "SELECT ISNULL(OriginatorWorkflowRoleID,0) FROM ProjectApprovalDocuments WHERE PADID = " & PADID
                result = db.ExecuteScalar(sql)     'GET OriginatorWorkflowRoleID 
                If result > 0 And result <> CallingPage.Session("WorkflowRoleID") Then

                    'Get the role and user name and replace the generic with it
                    sql = "SELECT WorkflowRoles.WorkflowRoleID, WorkflowRoles.DistrictID, WorkflowRoles.WorkflowRole, WorkflowRoles.UserID, Users.UserName "
                    sql &= "FROM WorkflowRoles INNER JOIN Users ON WorkflowRoles.UserID = Users.UserID "
                    sql &= "WHERE WorkflowRoleID = " & result
                    Dim tbl2 As DataTable = db.ExecuteDataTable(sql)
                    Dim row As DataRow = tbl2.Rows(0)

                    Dim bFound As Boolean = False
                    For Each item As ListItem In lstReject.Items
                        If item.Value = 81 Then         'HACK: HArd coded primary key for testing
                            item.Value = result
                            item.Text = row("UserName") & " (" & row("WorkflowRole") & ")"
                            bFound = True
                        End If
                    Next
                    If Not bFound Then
                        Dim ii As New ListItem
                        ii.Value = result
                        ii.Text = row("UserName") & " (" & row("WorkflowRole") & ")"
                        lstReject.Items.Add(ii)
                    End If

                Else                'this is originator so clear reject list

                    lstReject.Items.Clear()
                End If

            End If
        End Sub
        Public Function GetSelectedWorkflowTransactionsForApproval(ByVal TransList As String) As DataTable
            'gets all workflow transactions and targets for Multi-Approval Action
            Dim sql As String = ""
            sql = "SELECT * FROM qry_GetWorkflowTransactions WHERE TransactionID IN (" & TransList & ") "
            Dim tbl As DataTable = db.ExecuteDataTable(sql)

            'now add approval columns to datatable
            Dim colTargetRole As DataColumn = New DataColumn("TargetRole", System.Type.GetType("System.String"))
            Dim colTargetRoleID As DataColumn = New DataColumn("TargetRoleID", System.Type.GetType("System.Int32"))
            tbl.Columns.Add(colTargetRole)
            tbl.Columns.Add(colTargetRoleID)

            'Now get all the next approval target for each transaction based on the current workflow owner and append to each record

            For Each row As DataRow In tbl.Rows
                If CallingPage.Session("WorkflowRoleType") = "District AP" Then  'Only target for approval is ready to transfer
                    'row("TargetRole") = "Ready To Transfer"
                    row("TargetRole") = "District for Payment"
                    row("TargetRoleID") = -100

                Else
                    sql = "SELECT * FROM qry_GetWorkflowTargets "
                    sql &= "WHERE WorkflowRoleID = " & CallingPage.Session("WorkflowRoleID") & " AND WorkflowScenerioID = " & row("WorkflowScenerioID") & " "
                    sql &= " ORDER BY Priority"

                    Dim rs As SqlDataReader = db.ExecuteReader(sql)
                    While rs.Read
                        If MaxDollarApprovalLevel < rs("ApprovalDollarLimit") Then
                            MaxDollarApprovalLevel = rs("ApprovalDollarLimit")
                        End If
                        If rs("TargetAction") = "Approved" Then
                            row("TargetRole") = rs("TargetRole")
                            row("TargetRoleID") = rs("TargetRoleID")
                            Exit While   'only get first item
                        End If

                    End While
                    rs.Close()
                End If
            Next

            Return tbl

        End Function


        Public Sub LoadCheckMessageListBoxes()

            Dim lstCheck As DropDownList = DirectCast(CallingPage.FindControl("lstFRSCheckMessageCode"), DropDownList)
            Dim lstRetention As DropDownList = DirectCast(CallingPage.FindControl("lstFRSRetentionCheckMessageCode"), DropDownList)

            lstCheck.Items.Clear()
            lstRetention.Items.Clear()

            Dim item As New ListItem
            item.Text = "-none-"
            item.Value = ""
            lstRetention.Items.Add(item)

            item = New ListItem
            item.Text = "-none-"
            item.Value = ""
            lstCheck.Items.Add(item)

            Dim sql As String = "SELECT * FROM FRS_CheckMessageCodes "
            Dim rs As SqlDataReader = db.ExecuteReader(sql)
            While rs.Read
                item = New ListItem
                item.Text = rs("Code") & " - " & rs("Description")
                item.Value = rs("Code")
                lstCheck.Items.Add(item)

                item = New ListItem
                item.Text = rs("Code") & " - " & rs("Description")
                item.Value = rs("Code")
                lstRetention.Items.Add(item)


            End While
            rs.Close()



        End Sub

        Public Function GetPendingWorkflowTransactions(ByVal WorkflowOwnerID As Integer) As DataTable

            'gets workflow transactions current user type has approved or rejected
            'Get distinct list of trans IDs
            Dim sql As String = ""
            sql = "SELECT DISTINCT WorkflowAction, WorkflowRoleID, DistrictID, TransactionID FROM WorkflowLog "
            sql &= "WHERE (WorkflowLog.WorkflowAction  Like 'Approved by%' OR WorkflowLog.WorkflowAction  Like 'Rejected by%') AND WorkflowRoleID = " & WorkflowOwnerID & " AND "
            sql &= "DistrictID = " & HttpContext.Current.Session("DistrictID")
            Dim tbl As DataTable = db.ExecuteDataTable(sql)
            Dim skeylist As New StringBuilder
            For Each row As DataRow In tbl.Rows
                skeylist.Append(row("TransactionID") & ",")
            Next
            tbl.Dispose()
            'remove the last coma
            Dim sTrans As String = skeylist.ToString
            If sTrans.Length > 0 Then
                sTrans = Left(sTrans, sTrans.Length - 1)
            Else
                sTrans = "0"
            End If

            'Use resulting list to get one of each trans ID
            sql = "SELECT qry_GetWorkflowTransactions.* FROM qry_GetWorkflowTransactions WHERE  Status <> 'Paid' AND TransactionID In (" & sTrans & ")"
            Dim tblReturn As DataTable = db.ExecuteDataTable(sql)
            Return tblReturn


        End Function

        Public Function GetFDOApprovedTransactions() As DataTable

            'gets workflow transactions for given status and district
            Dim sql As String = ""
            sql = "SELECT * FROM qry_GetWorkflowTransactions WHERE DistrictID = " & HttpContext.Current.Session("DistrictID")
            sql &= " AND Status = 'FDO Approved' AND CurrentWorkflowOwner <> 'Ready To Transfer' AND CurrentWorkflowOwner <> 'District for Payment' ORDER BY College, ProjectName"

            Dim tbl As DataTable = db.ExecuteDataTable(sql)
            'Add RecordType and PADID fieldto table
            Dim colPADID As DataColumn = New DataColumn("PADID", System.Type.GetType("System.Int32"))
            Dim colRecType As DataColumn = New DataColumn("RecordType", System.Type.GetType("System.String"))
            tbl.Columns.Add(colPADID)
            tbl.Columns.Add(colRecType)

            For Each row As DataRow In tbl.Rows
                row("PADID") = 0
                row("RecordType") = "Transaction"

            Next

            Return tbl


        End Function


        Public Function GetPaidWorkflowTransactions(ByVal WorkflowOwnerID As Integer) As DataTable
            'gets workflow transactions current user type has rejected

            'Get distinct list of trans IDs
            Dim sql As String = ""
            sql = "SELECT DISTINCT WorkflowAction, WorkflowRoleID, DistrictID, TransactionID FROM WorkflowLog "
            sql &= "WHERE (WorkflowLog.WorkflowAction  Like 'Approved by%' OR WorkflowLog.WorkflowAction  Like 'Rejected by%') AND  WorkflowRoleID=" & WorkflowOwnerID & " AND "
            sql &= "DistrictID = " & HttpContext.Current.Session("DistrictID")

            Dim tbl As DataTable = db.ExecuteDataTable(sql)
            Dim skeylist As New StringBuilder
            For Each row As DataRow In tbl.Rows
                skeylist.Append(row("TransactionID") & ",")
            Next
            tbl.Dispose()
            'remove the last coma
            Dim sTrans As String = skeylist.ToString
            If sTrans.Length > 0 Then
                sTrans = Left(sTrans, sTrans.Length - 1)
            Else
                sTrans = "0"
            End If

            'Use resulting list to get one of each trans ID
            sql = "SELECT qry_GetWorkflowTransactions.* FROM qry_GetWorkflowTransactions WHERE Status = 'Paid' AND TransactionID In (" & sTrans & ")"
            Dim tblReturn As DataTable = db.ExecuteDataTable(sql)
            Return tblReturn


        End Function

        Public Function GetMyApprovedRejectedWorkflowItems(ByVal Status As String, ByVal WorkflowOwnerID As Integer) As DataTable
            'gets workflow transactions current user type has rejected

            'Get distinct list of items
            Dim sql As String = ""
            sql = "SELECT DISTINCT WorkflowAction, WorkflowRoleID, DistrictID, ISNULL(TransactionID,0) AS TransactionID,ISNULL(PADID,0) AS PADID FROM WorkflowLog "
            If Status = "Approved" Then
                sql &= "WHERE (WorkflowLog.WorkflowAction  Like '" & Status & " by%' OR WorkflowLog.WorkflowAction  Like 'Final Approval%' ) AND  WorkflowRoleID=" & WorkflowOwnerID & " AND "
            Else
                sql &= "WHERE (WorkflowLog.WorkflowAction  Like '" & Status & " by%') AND  WorkflowRoleID=" & WorkflowOwnerID & " AND "
            End If
            sql &= "DistrictID = " & HttpContext.Current.Session("DistrictID")

            Dim tblKeys As DataTable = db.ExecuteDataTable(sql)

            'gets workflow transactions for given and district
            Dim tblPAD As DataTable
            If WorkflowOwnerID = 0 Then
                WorkflowOwnerID = -99     'dummy to make sure query returns empty datatable to trigger no records message on grid
            End If

            'HACK: In order to return a table with the correct fields regardless of if there are records (to avoid a harry union), we
            'need to fill a table with an inital set of data, then filter for valid data if any. Not elegeant but faster than rewriting 
            'funtion at this point.
            'So... get all the records for the district, then filter out 
            Dim tbl As DataTable
            sql = "SELECT * FROM qry_GetWorkflowTransactions WHERE DistrictID = " & HttpContext.Current.Session("DistrictID")
            tbl = db.ExecuteDataTable(sql)

            'Add RecordType and PADID fieldto table
            Dim colPADID As DataColumn = New DataColumn("PADID", System.Type.GetType("System.Int32"))
            Dim colRecType As DataColumn = New DataColumn("RecordType", System.Type.GetType("System.String"))
            tbl.Columns.Add(colPADID)
            tbl.Columns.Add(colRecType)

            'Filter out bad data and update the new colmns in the transaction records
            For Each row As DataRow In tbl.Rows
                Dim bFound As Boolean = False
                For Each rowtrans As DataRow In tblKeys.Rows
                    If row("TransactionID") = rowtrans("TransactionID") Then
                        bFound = True
                        row("PADID") = 0
                        row("RecordType") = "Transaction"
                        Exit For
                    End If
                Next
                If Not bFound Then
                    row.Delete()
                End If

            Next


            'Gets all PADs 
            sql = "SELECT * FROM qry_GetWorkflowPADS WHERE DistrictID = " & HttpContext.Current.Session("DistrictID")
            tblPAD = db.ExecuteDataTable(sql)

            For Each row As DataRow In tblPAD.Rows
                Dim bFound As Boolean = False
                For Each rowpad As DataRow In tblKeys.Rows
                    If row("PADID") = rowpad("PADID") Then
                        bFound = True
                        Dim newrow As DataRow = tbl.NewRow
                        newrow("ProjectID") = row("ProjectID")
                        newrow("CollegeID") = row("CollegeID")
                        newrow("ContractID") = 0
                        newrow("TransactionID") = 0
                        newrow("Attachments") = 1       'this is assumed as the record could not be in workflow otherwise
                        newrow("College") = row("College")
                        newrow("PADID") = row("PADID")
                        newrow("RecordType") = "PAD"
                        newrow("TransType") = "PAD"
                        newrow("ModTransType") = "PAD"
                        newrow("ContractType") = "PAD"

                        newrow("ProjectNumber") = row("ProjectNumber")
                        newrow("ProjectName") = row("ProjectName")
                        newrow("Status") = row("Status")


                        tbl.Rows.Add(newrow)
                        Exit For
                    End If
                Next

            Next


            Return tbl


        End Function



        Public Function GetAllOpenWorkflowItems() As DataTable
            'gets all workflow items

            Dim tbl As DataTable
            Dim sql As String = "SELECT * FROM qry_GetWorkflowTransactions WHERE DistrictID = " & HttpContext.Current.Session("DistrictID")
            sql &= " AND Status <> 'Paid'"
            tbl = db.ExecuteDataTable(sql)

            'Add RecordType and PADID fieldto table
            Dim colPADID As DataColumn = New DataColumn("PADID", System.Type.GetType("System.Int32"))
            Dim colRecType As DataColumn = New DataColumn("RecordType", System.Type.GetType("System.String"))
            tbl.Columns.Add(colPADID)
            tbl.Columns.Add(colRecType)

            For Each row As DataRow In tbl.Rows
                row("PADID") = 0
                row("RecordType") = "Transaction"

            Next


            'Gets all PADs 
            sql = "SELECT * FROM qry_GetWorkflowPADS WHERE DistrictID = " & HttpContext.Current.Session("DistrictID")
            sql &= " AND Status <> 'Approved'"
            Dim tblPAD As DataTable = db.ExecuteDataTable(sql)

            For Each row As DataRow In tblPAD.Rows

                Dim newrow As DataRow = tbl.NewRow
                newrow("ProjectID") = row("ProjectID")
                newrow("CollegeID") = row("CollegeID")
                newrow("ContractID") = 0
                newrow("TransactionID") = 0
                newrow("Attachments") = 1       'this is assumed as the record could not be in workflow otherwise
                newrow("College") = row("College")
                newrow("PADID") = row("PADID")
                newrow("RecordType") = "PAD"
                newrow("TransType") = "PAD"
                newrow("ModTransType") = "PAD"
                newrow("ContractType") = "PAD"

                newrow("ProjectNumber") = row("ProjectNumber")
                newrow("ProjectName") = row("ProjectName")
                newrow("Status") = row("Status")


                tbl.Rows.Add(newrow)
            Next


            Return tbl
        End Function


        Public Sub AddWorkflowEntry(ByVal TransactionID As Integer, ByVal Action As String, Optional ByVal Notes As String = "")

            'Get all the needed info for transaction
            Dim sql As String = "SELECT Transactions.ContractID, Transactions.Status, Transactions.TransactionID, Transactions.ProjectID, "
            sql &= "Transactions.DistrictID, Contracts.CollegeID FROM Transactions INNER JOIN "
            sql &= "Contracts ON Transactions.ContractID = Contracts.ContractID WHERE TransactionID = " & TransactionID
            Dim tbl As DataTable = db.ExecuteDataTable(sql)
            Dim row As DataRow = tbl.Rows(0)

            'Insert workflow record
            sql = "INSERT INTO WorkflowLog (DistrictID,CollegeID,ProjectID,ContractID,TransactionID,WorkflowOwner,WorkflowRoleID,WorkflowAction,Notes,CreatedOn,CreatedBy) "
            sql &= " VALUES(" & row("DistrictID") & ","
            sql &= row("CollegeID") & ","
            sql &= row("ProjectID") & ","
            sql &= row("ContractID") & ","
            sql &= row("TransactionID") & ","
            sql &= "'" & HttpContext.Current.Session("WorkflowRole") & "',"
            sql &= HttpContext.Current.Session("WorkflowRoleID") & ","
            sql &= "'" & Action & "',"
            sql &= "'" & Notes & "',"
            sql &= "'" & Now() & "',"
            sql &= "'" & HttpContext.Current.Session("UserName") & "')"

            tbl.Dispose()
            db.ExecuteNonQuery(sql)

        End Sub

        Public Sub AddPADWorkflowEntry(ByVal PADID As Integer, ByVal Action As String, Optional ByVal Notes As String = "")

            'Get all the needed info for transaction
            Dim sql As String = "SELECT  * FROM ProjectApprovalDocuments WHERE PADID = " & PADID
            Dim tbl As DataTable = db.ExecuteDataTable(sql)
            Dim row As DataRow = tbl.Rows(0)

            'Insert workflow record
            sql = "INSERT INTO WorkflowLog (DistrictID,CollegeID,ProjectID,ContractID,PADID,WorkflowOwner,WorkflowRoleID,WorkflowAction,Notes,CreatedOn,CreatedBy) "
            sql &= " VALUES(" & row("DistrictID") & ","
            sql &= row("CollegeID") & ","
            sql &= row("ProjectID") & ","
            sql &= "0,"
            sql &= row("PADID") & ","
            sql &= "'" & HttpContext.Current.Session("WorkflowRole") & "',"
            sql &= HttpContext.Current.Session("WorkflowRoleID") & ","
            sql &= "'" & Action & "',"
            sql &= "'" & Notes & "',"
            sql &= "'" & Now() & "',"
            sql &= "'" & HttpContext.Current.Session("UserName") & "')"

            tbl.Dispose()
            db.ExecuteNonQuery(sql)

        End Sub


        'Public Function GetDaysSinceLastAction(ByVal TransactionID) As String

        '    Dim Sql As String = "SELECT LastWorkFlowActionOn FROM Transactions WHERE TransactionID = " & TransactionID
        '    Dim result = db.ExecuteScalar(Sql)
        '    If IsDBNull(result) Then
        '        result = Now()
        '    End If
        '    Return DateDiff(DateInterval.Day, result, Now())

        'End Function


        Public Function GetSendersWorkflowRoleID() As Integer

            'need our own reader and connection 
            Using db As New PromptDataHelper
                Dim Sql As String = ""
                If RecordType = "Transaction" Then
                    Sql = "SELECT PreviousWorkflowRoleID FROM Transactions WHERE TransactionID = " & TransactionID
                Else
                    Sql = "SELECT PreviousWorkflowRoleID FROM ProjectApprovalDocuments WHERE PADID = " & PADID
                End If

                Dim result = db.ExecuteScalar(Sql)
                If IsDBNull(result) Then
                    result = 0
                End If
                Return result
            End Using

        End Function

        Public Function GetLastTransactionWorkflowEntryID(ByVal TransactionID) As Integer

            'need our own reader and connection 
            Using db As New PromptDataHelper
                Dim Sql As String = "SELECT * FROM WorkflowLog WHERE TransactionID = " & TransactionID & " "
                Sql &= "AND WorkflowRoleID = " & HttpContext.Current.Session("WorkflowRoleID") & " "
                Sql &= "AND WorkflowAction <> 'Note Added' ORDER BY PrimaryKey Desc "
                'get the first record (sorted desc)
                Dim nID As Integer = 0
                db.FillReader(Sql)
                While db.Reader.Read
                    nID = db.Reader("PrimaryKey")
                    Exit While
                End While
                db.Reader.Close()
                Return nID
            End Using

        End Function

        Public Function GetLastPADWorkflowEntryID(ByVal PADID) As Integer

            'need our own reader and connection 
            Using db As New PromptDataHelper
                Dim Sql As String = "SELECT * FROM WorkflowLog WHERE PADID = " & PADID & " "
                Sql &= "AND WorkflowRoleID = " & HttpContext.Current.Session("WorkflowRoleID") & " "
                Sql &= "AND WorkflowAction <> 'Note Added' ORDER BY PrimaryKey Desc "
                'get the first record (sorted desc)
                Dim nID As Integer = 0
                db.FillReader(Sql)
                While db.Reader.Read
                    nID = db.Reader("PrimaryKey")
                    Exit While
                End While
                db.Reader.Close()
                Return nID
            End Using

        End Function


        Private Sub LoadTransactionInfo(ByVal TransactionID)

            If Not IsNumeric(TransactionID) Then
                TransactionID = 0
            End If

            'Get the transaction info to include
            Dim sql As String = "SELECT Colleges.College, Projects.ProjectName, dbo.Contractors.Name AS Contractor, "
            sql &= "Contracts.Description AS Contract, Transactions.InvoiceNumber, Transactions.LastWorkflowAction, Transactions.InvoiceDate, Transactions.WorkflowScenerioID, "
            sql &= "Transactions.TotalAmount,Transactions.RetentionAmount, dbo.Transactions.TransactionID "
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

                    WorkflowScenerioID = rs("WorkflowScenerioID")

                    TransactionTotalAmount = rs("TotalAmount")
                    TransactionRetentionAmount = rs("RetentionAmount")
                    LastWorkflowAction = ProcLib.CheckNullDBField(rs("LastWorkflowAction"))


                End While
            End If
            rs.Close()

            TransactionInfo = sPromptInfo

            'populate the properties in this class with sender info
            sql = "SELECT Users.LoginID,WorkflowRoles.WorkflowRole,WorkflowRoles.WorkflowRoleID FROM WorkflowLog INNER JOIN WorkflowRoles ON WorkflowLog.WorkflowRoleID = WorkflowRoles.WorkflowRoleID INNER JOIN "
            sql &= "Users ON WorkflowRoles.UserID = Users.UserID WHERE WorkflowLog.TransactionID = " & TransactionID & " ORDER BY WorkflowLog.PrimaryKey Desc "
            'get the first record (sorted desc)
            Dim sEmail As String = ""
            db.FillReader(sql)
            While db.Reader.Read
                LastOwnerEmailAddress = db.Reader("LoginID")
                LastOwnerRole = db.Reader("WorkflowRole")
                LastOwnerRoleID = db.Reader("WorkflowRoleID")
                Exit While
            End While
            db.Reader.Close()

            sql = "SELECT MAX(WorkflowRoles.ApprovalDollarLimit) AS MaxAmount "
            sql &= "FROM WorkflowRoles INNER JOIN WorkflowScenerioOwners ON WorkflowRoles.WorkflowRoleID = WorkflowScenerioOwners.WorkflowRoleID "
            sql &= "WHERE WorkflowScenerioID = " & WorkflowScenerioID
            Dim result = db.ExecuteScalar(sql)
            If IsDBNull(result) Then
                MaxDollarApprovalLevel = 0
            Else
                MaxDollarApprovalLevel = result
            End If


        End Sub

        Private Sub LoadPADInfo(ByVal PADID)

            If Not IsNumeric(PADID) Then
                PADID = 0
            End If

            'Get the PAD info to include
            Dim sql As String = "SELECT * FROM ProjectApprovalDocuments WHERE PADID = " & PADID
            Dim rs As SqlDataReader = db.ExecuteReader(sql)

            While rs.Read
                WorkflowScenerioID = rs("WorkflowScenerioID")
                LastWorkflowAction = ProcLib.CheckNullDBField(rs("LastWorkflowAction"))
            End While
            rs.Close()

            'populate the properties in this class with sender info
            sql = "SELECT Users.LoginID,WorkflowRoles.WorkflowRole,WorkflowRoles.WorkflowRoleID FROM WorkflowLog INNER JOIN WorkflowRoles ON WorkflowLog.WorkflowRoleID = WorkflowRoles.WorkflowRoleID INNER JOIN "
            sql &= "Users ON WorkflowRoles.UserID = Users.UserID WHERE WorkflowLog.PADID = " & PADID & " ORDER BY WorkflowLog.PrimaryKey Desc "
            'get the first record (sorted desc)
            'Dim sEmail As String = ""
            db.FillReader(sql)
            While db.Reader.Read
                LastOwnerEmailAddress = db.Reader("LoginID")
                LastOwnerRole = db.Reader("WorkflowRole")
                LastOwnerRoleID = db.Reader("WorkflowRoleID")
                Exit While
            End While
            db.Reader.Close()


        End Sub

        Public Sub RouteTransaction()
            Dim sql As String = ""

            LoadTransactionInfo(TransactionID)  'populate the various properties in this class with transaction info

            Dim sNotes As String = ""
            If Action <> "DistrictForPayment" And Action <> "ReRouted By Sender" And Not IsMultiApproval Then
                'get notes info from routing page
                sNotes = DirectCast(CallingPage.FindControl("txtNotes"), TextBox).Text
                sNotes = sNotes.Replace("'", "")
            End If

            'Get the sender info
            Dim nSenderID As Integer = HttpContext.Current.Session("UserID")

            Dim sActionDescription As String = ""
            Select Case Action

                Case "Approved"
                    sActionDescription = "Approved by " & HttpContext.Current.Session("WorkflowRole")


                Case "Rejected"
                    sActionDescription = "Rejected by " & HttpContext.Current.Session("WorkflowRole")


                Case "DistrictForPayment"
                    sActionDescription = "District for Payment"

                Case Else
                    sActionDescription = Action

            End Select


            If Action = "Rejected" Then      'We need to notify and flag where appropriate 

                Dim msgtext As String = ""
                msgtext = "The following transaction has been rejected:" & "<br/>"
                msgtext &= "Rejected by: " & HttpContext.Current.Session("WorkflowRole") & "<br/>"
                msgtext &= "Currently At: " & Target & "<br/>"
                msgtext &= "Reason: " & sNotes & "<br/>"
                msgtext &= TransactionInfo & "<br/>"


                'flag the transaction
                Using flag As New promptFlag
                    Dim flagmsg As String = sActionDescription & " On " & Now() & "<br/>"
                    flagmsg &= "Reason: " & sNotes & "<br/>"
                    flag.CallingPage = CallingPage
                    flag.FlagTransactionFromWorkflowRejection(TransactionID, flagmsg)
                End Using


            End If

            If Action = "ReRouted By Sender" Then      'We need to remove last approval and reroute - no need to log entry
                'Get the last workflow action for this transaction and delete the entry
                Dim nID As Integer = GetLastTransactionWorkflowEntryID(TransactionID)
                db.ExecuteScalar("DELETE FROM WorkflowLog WHERE PrimaryKey = " & nID)

                'Remove workflow flag in Attachments for linked docs if the total workflow entry count is < 2 
                '-- this signifies it went back to Originator before moving through workflow
                Dim sCount As Integer = db.ExecuteScalar("SELECT COUNT(PrimaryKey) FROM WorkflowLog WHERE TransactionID = " & TransactionID)
                If sCount < 2 Then
                    db.FillReader("SELECT AttachmentID FROM AttachmentsLinks WHERE TransactionID = " & TransactionID)
                    Dim sKeylist As String = ""
                    While db.Reader.Read()
                        sKeylist &= db.Reader("AttachmentID") & ","
                    End While
                    db.Reader.Close()
                    If sKeylist <> "" Then
                        sKeylist = sKeylist.Substring(0, sKeylist.Length - 1)    'strip of last comma
                        db.ExecuteNonQuery("UPDATE Attachments SET InWorkflow = 0 WHERE AttachmentID IN (" & sKeylist & ")")
                    End If

                End If

            Else

                AddWorkflowEntry(TransactionID, sActionDescription, sNotes)

                'Update the flag for any attachments that this is now in workflow 
                db.FillReader("SELECT AttachmentID FROM AttachmentsLinks WHERE TransactionID = " & TransactionID)
                Dim sKeylist As String = ""
                While db.Reader.Read()
                    sKeylist &= db.Reader("AttachmentID") & ","
                End While
                db.Reader.Close()
                If sKeylist <> "" Then
                    sKeylist = sKeylist.Substring(0, sKeylist.Length - 1)    'strip of last comma
                    db.ExecuteNonQuery("UPDATE Attachments SET InWorkflow = 1 WHERE AttachmentID IN (" & sKeylist & ")")
                End If

            End If

            If Target = "District for Payment" Then             'set transaction status to payment pending if at District
                sql = "UPDATE Transactions SET CurrentWorkflowOwner = '" & Target & "',"
                sql &= "Status = 'Payment Pending',"
                sql &= "PreviousWorkflowRoleID = " & HttpContext.Current.Session("WorkflowRoleID") & ","

                sql &= "LastWorkflowActionOn = '" & Now() & "', "
                sql &= "LastWorkflowAction = '" & Target & "', "
                ' sql &= "CurrentWorkflowOwnerNotifiedOn = NULL, "
                sql &= "ExportedOn='" & Now() & "' "
                sql &= "WHERE TransactionID = " & TransactionID
            Else
                sql = "UPDATE Transactions SET CurrentWorkflowOwner = '" & Target & "',"
                sql &= "CurrentWorkflowRoleID = " & TargetRoleID & ","
                sql &= "PreviousWorkflowRoleID = " & HttpContext.Current.Session("WorkflowRoleID") & ", "
                sql &= "CurrentWorkflowOwnerNotifiedOn = NULL, "

                If LastWorkflowAction = "District for Payment" Then    'this is being recalled by AP so change status
                    sql &= "Status = 'FDO Approved',"
                End If

                If HttpContext.Current.Session("WorkflowRoleType") = "Bond Accountant" Then   'only update this if Bond Accountant
                    sql &= "FRSCheckMessageCode = '" & FRSCheckMessageCode & "', "
                    sql &= "FRSRetentionCheckMessageCode = '" & FRSRetentionCheckMessageCode & "', "
                End If


                sql &= "FRSCutSingleCheck = '" & FRSCutSingleCheck & "', "
                sql &= "LastWorkflowAction = '" & Action & "', "
                sql &= "LastWorkflowActionOn = '" & Now() & "' "

                sql &= "WHERE TransactionID = " & TransactionID
            End If
            db.ExecuteNonQuery(sql)




        End Sub

        Public Sub RoutePAD()
            Dim sql As String = ""

            LoadPADInfo(PADID)  'populate the various properties in this class with PAD info

            Dim sNotes As String = ""
            If Action <> "DistrictForPayment" And Action <> "ReRouted By Sender" And Not IsMultiApproval Then
                'get notes info from routing page
                sNotes = DirectCast(CallingPage.FindControl("txtNotes"), TextBox).Text
                sNotes = sNotes.Replace("'", "")
            End If

            'Get the sender info
            Dim nSenderID As Integer = HttpContext.Current.Session("UserID")

            Dim sActionDescription As String = ""
            Select Case Action

                Case "Approved"
                    sActionDescription = "Approved by " & HttpContext.Current.Session("WorkflowRole")


                Case "Rejected"
                    sActionDescription = "Rejected by " & HttpContext.Current.Session("WorkflowRole")

                Case "FinalApproval"
                    sActionDescription = "Final Approval by " & HttpContext.Current.Session("WorkflowRole")
                    Target = "Final Approval"
                    TargetRoleID = 0
                    Action = "FinalApproval"
                Case Else
                    sActionDescription = Action

            End Select


            If Action = "Rejected" Then      'We need to notify and flag where appropriate 

                'Dim msgtext As String = ""
                'msgtext = "The following PAD has been rejected:" & "<br/>"
                'msgtext &= "Rejected by: " & HttpContext.Current.Session("WorkflowRole") & "<br/>"
                'msgtext &= "Currently At: " & Target & "<br/>"
                'msgtext &= "Reason: " & sNotes & "<br/>"
                'msgtext &= TransactionInfo & "<br/>"


                ''flag the transaction
                'Using flag As New promptFlag
                '    Dim flagmsg As String = sActionDescription & " On " & Now() & "<br/>"
                '    flagmsg &= "Reason: " & sNotes & "<br/>"
                '    flag.CallingPage = CallingPage
                '    flag.FlagTransactionFromWorkflowRejection(TransactionID, flagmsg)
                'End Using


            End If

            If Action = "ReRouted By Sender" Then      'We need to remove last approval and reroute - no need to log entry
                'Get the last workflow action for this transaction and delete the entry
                Dim nID As Integer = GetLastPADWorkflowEntryID(PADID)
                db.ExecuteScalar("DELETE FROM WorkflowLog WHERE PrimaryKey = " & nID)



            Else

                AddPADWorkflowEntry(PADID, sActionDescription, sNotes)



            End If

            sql = "UPDATE ProjectApprovalDocuments SET CurrentWorkflowOwner = '" & Target & "',"
            sql &= "CurrentWorkflowRoleID = " & TargetRoleID & ","
            sql &= "PreviousWorkflowRoleID = " & HttpContext.Current.Session("WorkflowRoleID") & ", "
            sql &= "CurrentWorkflowOwnerNotifiedOn = NULL, "

            If Action = "FinalApproval" Then
                sql &= "Status = 'Approved', "
            End If

            sql &= "LastWorkflowAction = '" & Action & "', "
            sql &= "LastWorkflowActionOn = '" & Now() & "' "

            sql &= "WHERE PADID = " & PADID

            db.ExecuteNonQuery(sql)

            'Check if OriginatorWorkflowRoleID is zero and if so this is originator so fill in here
            sql = "SELECT ISNULL(OriginatorWorkflowRoleID,0) FROM ProjectApprovalDocuments WHERE PADID = " & PADID
            Dim result As Integer = db.ExecuteScalar(sql)
            If result = 0 Then
                sql = "UPDATE ProjectApprovalDocuments SET OriginatorWorkflowRoleID = " & HttpContext.Current.Session("WorkflowRoleID") & " WHERE PADID = " & PADID
                db.ExecuteNonQuery(sql)
            End If


        End Sub


        Public Sub RejectTransactionFromFRS(ByVal TransactionID As Integer, ByVal Reason As String)

            LoadTransactionInfo(TransactionID)

            'Used by the import program to reject the transaction when error found during Log processing
            Dim sActionDescription As String = "Rejected By FRS"
            'Add the workflow entry
            AddWorkflowEntry(TransactionID, sActionDescription, Reason)

            'update the transaction and return to sender
            Dim sql As String = "UPDATE Transactions SET CurrentWorkflowOwner = '" & LastOwnerRole & "',"
            sql &= "Status = 'FDO Approved',"
            sql &= "CurrentWorkflowRoleID = " & LastOwnerRoleID & ","
            sql &= "PreviousWorkflowRoleID = -99,"       'signifies FRS 
            sql &= "ExportedOn = Null, "
            sql &= "LastWorkflowAction = 'RejectedByFRS', "
            ' sql &= "CurrentWorkflowOwnerNotifiedOn = NULL, "
            sql &= "LastWorkflowActionOn = '" & Now() & "' "
            sql &= "WHERE TransactionID = " & TransactionID

            db.ExecuteNonQuery(sql)


        End Sub


        Public Function GetCurrentWorkflowOwner(ByVal rectype As String, ByVal recid As Integer) As String
            Dim sResult As String = ""
            If rectype = "Transaction" Then
                'Get all current workflow status and roletype for a given transaction
                Dim sql As String = "SELECT WorkflowRoles.RoleType AS Role FROM WorkflowRoles INNER JOIN "
                sql &= "Transactions ON WorkflowRoles.WorkflowRoleID = Transactions.CurrentWorkflowRoleID WHERE TransactionID = " & recid
                sResult = db.ExecuteScalar(sql)
                If sResult = "" Then
                    TransactionWorkflowRoleType = "FDO Accountant"   'catchall for those unrouted
                Else
                    TransactionWorkflowRoleType = sResult
                End If

                'Check to see if already in workflow
                sql = "SELECT Count(PrimaryKey) FROM WorkflowLog WHERE TransactionID = " & recid
                If db.ExecuteScalar(sql) > 0 Then
                    IsCurrentlyInWorkflow = True
                End If

                sql = "SELECT ISNULL(CurrentWorkflowOwner,'') AS CurrentWorkflowOwner, TotalAmount FROM Transactions WHERE TransactionID = " & recid
                db.FillReader(sql)
                While db.Reader.Read
                    sResult = db.Reader("CurrentWorkflowOwner")
                    TransactionTotalAmount = db.Reader("TotalAmount")
                End While
                db.Reader.Close()


            End If
            If rectype = "PAD" Then
                'Get all current workflow status and roletype for a given transaction
                Dim sql As String = "SELECT WorkflowRoles.RoleType AS Role FROM WorkflowRoles INNER JOIN "
                sql &= "ProjectApprovalDocuments ON WorkflowRoles.WorkflowRoleID = ProjectApprovalDocuments.CurrentWorkflowRoleID WHERE PADID = " & recid
                sResult = db.ExecuteScalar(sql)
                If sResult = "" Then
                    TransactionWorkflowRoleType = "FDO Accountant"   'catchall for those unrouted
                Else
                    TransactionWorkflowRoleType = sResult
                End If

                'Check to see if already in workflow
                sql = "SELECT Count(PrimaryKey) FROM WorkflowLog WHERE PADID = " & recid
                If db.ExecuteScalar(sql) > 0 Then
                    IsCurrentlyInWorkflow = True
                End If

                sql = "SELECT ISNULL(CurrentWorkflowOwner,'') AS CurrentWorkflowOwner FROM ProjectApprovalDocuments WHERE PADID = " & recid
                db.FillReader(sql)
                While db.Reader.Read
                    sResult = db.Reader("CurrentWorkflowOwner")
                    TransactionTotalAmount = 0
                End While
                db.Reader.Close()

                Return sResult
            End If

            Return sResult

        End Function

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

