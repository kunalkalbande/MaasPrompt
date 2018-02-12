Imports System
Imports System.Web
Imports System.Web.UI.WebControls
Imports System.IO
Imports System.Data
Imports System.Data.SqlClient

Namespace Prompt

    '********************************************
    '*  Workflow Scenerio Class
    '*  
    '*  Purpose: Processes data for the Workflow Scenerio objects
    '*
    '*  Last Mod By:    Ford James
    '*  Last Mod On:    10/20/08
    '*
    '********************************************

    Public Class promptWorkflowScenerio
        Implements IDisposable

        'Properties
        Public CallingPage As Page
        Private db As PromptDataHelper

        Public Reader As SqlDataReader
        Public DataTable As DataTable

        Public Sub New()
            db = New PromptDataHelper
        End Sub

#Region "Subs and Functions"

        Public Function GetWorkflowRolesList(ByVal DistrictID As Integer) As DataTable
            'gets workflow roles list
            Dim sql As String = "SELECT WorkflowRoles.WorkflowRoleID, WorkflowRoles.WorkflowRole, WorkflowRoles.Description, "
            sql &= "Users.UserName, WorkflowRoles.DistrictID FROM WorkflowRoles LEFT OUTER JOIN "
            sql &= "Users ON WorkflowRoles.UserID = Users.UserID "
            sql &= "WHERE WorkflowRoles.DistrictID = " & HttpContext.Current.Session("DistrictID") & " ORDER BY WorkflowRole"

            Return db.ExecuteDataTable(sql)

        End Function

        'Public Function GetWorkflowSceneriosList(ByVal DistrictID As Integer) As DataTable
        '    'gets workflow roles list
        '    Dim sql As String = ""
        '    sql = "SELECT * FROM WorkFLowScenerios WHERE DistrictID = " & DistrictID & " ORDER BY ScenerioName "
        '    Return db.ExecuteDataTable(sql)
        'End Function
        'Public Function GetWorkflowScenerioOwners(ByVal WorkflowScenerioID As Integer) As DataTable
        '    'gets workflow owners list
        '    Dim sql As String = ""
        '    sql = "SELECT WorkflowRoles.WorkflowRole as OwnerName, WorkflowScenerioOwners.* "
        '    sql &= "FROM WorkflowScenerioOwners INNER JOIN WorkflowRoles ON WorkflowScenerioOwners.WorkflowRoleID = WorkflowRoles.WorkflowRoleID "
        '    sql &= "WHERE WorkflowScenerioID = " & WorkflowScenerioID & " ORDER BY IsOriginator Desc, OwnerName "
        '    Dim tbl As DataTable = db.ExecuteDataTable(sql)

        '    'Add column to table with list of approval targets
        '    Dim colApprovalTargets As New DataColumn("ApprovalTargets", System.Type.GetType("System.String"))
        '    tbl.Columns.Add(colApprovalTargets)
        '    For Each row As DataRow In tbl.Rows
        '        sql = "SELECT TargetRoleName FROM WorkflowScenerioOwnerTargets WHERE WorkflowScenerioOwnerID = " & row("WorkflowScenerioOwnerID") & " "
        '        sql &= "AND TargetAction = 'Approved' ORDER BY Priority "
        '        Dim sTargetList As String = ""
        '        db.FillReader(sql)
        '        While db.Reader.Read
        '            sTargetList &= db.Reader("TargetRoleName") & "<br>"
        '        End While
        '        db.Close()
        '        row("ApprovalTargets") = sTargetList
        '    Next

        '    'Add column to table with list of reject targets
        '    Dim colRejectTargets As New DataColumn("RejectTargets", System.Type.GetType("System.String"))
        '    tbl.Columns.Add(colRejectTargets)
        '    For Each row As DataRow In tbl.Rows
        '        sql = "SELECT TargetRoleName FROM WorkflowScenerioOwnerTargets WHERE WorkflowScenerioOwnerID = " & row("WorkflowScenerioOwnerID") & " "
        '        sql &= "AND TargetAction = 'Rejected' ORDER BY TargetRoleName "
        '        Dim sTargetList As String = ""
        '        db.FillReader(sql)
        '        While db.Reader.Read
        '            sTargetList &= db.Reader("TargetRoleName") & "<br>"
        '        End While
        '        db.Close()
        '        row("RejectTargets") = sTargetList
        '    Next

        '    Return tbl


        'End Function

        Public Function LimitRejectionListToApproved(ByVal WorkflowScenerioID As Integer) As Boolean

            'Returns true if this scenerio limits rejection list to those who have previously approved
            Dim result As Integer = db.ExecuteScalar("SELECT LimitRejectionList FROM WorkflowScenerios WHERE WorkflowScenerioID = " & WorkflowScenerioID)
            If result = 1 Then
                Return True
            Else
                Return False
            End If

        End Function

        'Public Sub GetWorkflowScenerioForEdit(ByVal WorkflowScenerioID As Integer)

        '    Dim form As Control = CallingPage.FindControl("Form1")  ' get ref to calling form
        '    Dim sql As String = ""

        '    'get record for edit
        '    If WorkflowScenerioID <> 0 Then
        '        Dim row As DataRow = db.GetDataRow("SELECT * FROM WorkflowScenerios WHERE WorkflowScenerioID = " & WorkflowScenerioID)
        '        db.FillForm(form, row)
        '    End If

        'End Sub

        Public Sub GetWorkflowOwnerForEdit(ByVal WorkflowScenerioOwnerID As Integer)
            'gets workflow scenerio owner for edit

            Dim form As Control = CallingPage.FindControl("Form1")  ' get ref to calling form

            Dim sql As String = "SELECT WorkflowRoleID as Val,  WorkflowRole + ' (' + Users.UserName + ')' AS Lbl FROM WorkflowRoles INNER JOIN Users ON WorkflowRoles.UserID = Users.UserID "
            sql &= "WHERE WorkflowRoles.DistrictID = " & HttpContext.Current.Session("DistrictID") & " "
            sql &= "ORDER BY WorkflowRoles.WorkflowRole"

            db.FillDropDown(sql, form.FindControl("lstWorkflowRoleID"), True, False, False)

            'get record for edit
            If WorkflowScenerioOwnerID <> 0 Then
                Dim row As DataRow = db.GetDataRow("SELECT * FROM WorkflowScenerioOwners WHERE WorkflowScenerioOwnerID = " & WorkflowScenerioOwnerID)
                db.FillForm(form, row)
            End If

            'Get the list of Roles to target when Approved and rejected
            sql = "SELECT WorkflowRoles.*, Users.UserName FROM WorkflowRoles INNER JOIN Users ON WorkflowRoles.UserID = Users.UserID "
            sql &= "WHERE WorkflowRoles.DistrictID = " & HttpContext.Current.Session("DistrictID") & " "
            sql &= "ORDER BY WorkflowRoles.WorkflowRole"

            Dim rs As SqlDataReader = db.ExecuteReader(sql)
            'build both list boxes with available roles for this district
            Dim lstApproveDefault As DropDownList = form.FindControl("lstApprovalDefault")
            Dim lstApprove As ListBox = form.FindControl("lstApproveTargetList")
            Dim lstReject As ListBox = form.FindControl("lstRejectTargetList")

            Dim noneitem As New ListItem
            noneitem.Text = "-- none --"
            noneitem.Value = 0

            lstApproveDefault.Items.Clear()
            lstApproveDefault.Items.Add(noneitem)

            lstReject.Items.Clear()
            While rs.Read()
                Dim iApprove As New ListItem
                Dim iApproveDefault As New ListItem
                Dim iReject As New ListItem
                iApprove.Text = rs("WorkflowRole") & " (" & rs("UserName") & ")"
                iApprove.Value = rs("WorkflowRoleID")
                iApproveDefault.Text = rs("WorkflowRole") & " (" & rs("UserName") & ")"
                iApproveDefault.Value = rs("WorkflowRoleID")
                iReject.Text = rs("WorkflowRole") & " (" & rs("UserName") & ")"
                iReject.Value = rs("WorkflowRoleID")

                lstApprove.Items.Add(iApprove)
                lstApproveDefault.Items.Add(iApproveDefault)   'Note: This combo box is built here and then rebuilt in the page to allow any selected default to be appropriately added.
                lstReject.Items.Add(iReject)
            End While
            rs.Close()

            'select those already selected
            sql = "SELECT * FROM WorkflowScenerioOwnerTargets WHERE WorkflowScenerioOwnerID = " & WorkflowScenerioOwnerID
            rs = db.ExecuteReader(sql)
            While rs.Read
                If rs("TargetAction") = "Approved" Then  'update approve list
                    For Each item1 As ListItem In lstApprove.Items
                        If item1.Value = rs("TargetRoleID") Then
                            item1.Selected = True
                        End If
                    Next

                    'See if default approval target and select in combo box - Note: in order to minimize impact in revising this functionality,
                    'the Approved Default target will have a value of 10 in the Priority field of the WorkflowScenerioTargets Table.
                    If rs("Priority") = 10 Then
                        For Each item1 As ListItem In lstApproveDefault.Items
                            If item1.Value = rs("TargetRoleID") Then
                                item1.Selected = True
                            End If
                        Next
                    End If
                End If
 

                If rs("TargetAction") = "Rejected" Then  'update reject list
                    For Each item2 As ListItem In lstReject.Items
                        If item2.Value = rs("TargetRoleID") Then
                            item2.Selected = True
                        End If
                    Next
                End If

            End While

            rs.Close()


        End Sub

  

        Public Sub SaveWorkflowScenerioOwner(ByVal ScenerioID As Integer, ByVal OwnerID As Integer)
            Dim sql As String = ""
            'Takes data from the form and writes it to the database
            If OwnerID = 0 Then      'new record
                sql = "INSERT INTO WorkflowScenerioOwners "
                sql &= "(DistrictID,WorkflowScenerioID)"
                sql &= "VALUES (" & CallingPage.Session("DistrictID") & "," & ScenerioID & ")"
                sql &= "SELECT CAST(SCOPE_IDENTITY() AS int) AS ID"

                OwnerID = db.ExecuteScalar(sql)
            End If

            sql = "SELECT * FROM WorkflowScenerioOwners WHERE WorkflowScenerioOwnerID = " & OwnerID
            'pass the form and sql to fill routine
            Dim form As Control = CallingPage.FindControl("Form1")
            db.SaveForm(form, sql)

 
            'Update Notify List
            'remove existing assigments
            db.ExecuteNonQuery("DELETE FROM WorkflowScenerioOwnerNotifyList WHERE WorkflowScenerioOwnerID = " & OwnerID)


            'Update Workflow Target List
            'remove existing assigments
            db.ExecuteNonQuery("DELETE FROM WorkflowScenerioOwnerTargets WHERE WorkflowScenerioOwnerID = " & OwnerID)

            Dim lstApproveDefault As DropDownList = form.FindControl("lstApprovalDefault")
            Dim lstApprove As ListBox = form.FindControl("lstApproveTargetList")
            Dim lstReject As ListBox = form.FindControl("lstRejectTargetList")
            For Each item As ListItem In lstApprove.Items
                Dim nApprovalDefault As Integer = 0
                If item.Selected = True And item.Value <> 0 Then
                    If item.Value = lstApproveDefault.SelectedValue Then
                        nApprovalDefault = 10     'this is the default target for multi-approval
                    End If
                    sql = "INSERT INTO WorkflowScenerioOwnerTargets "
                    sql &= "(DistrictID,WorkflowScenerioOwnerID,TargetRoleName,TargetRoleID,TargetAction,Priority)"
                    sql &= "VALUES ("
                    sql &= CallingPage.Session("DistrictID") & "," & OwnerID & ",'" & item.Text & "'," & item.Value & ",'Approved'," & nApprovalDefault & ")"
                    db.ExecuteNonQuery(sql)
                End If
            Next

            For Each item As ListItem In lstReject.Items
                If item.Selected = True Then
                    sql = "INSERT INTO WorkflowScenerioOwnerTargets "
                    sql &= "(DistrictID,WorkflowScenerioOwnerID,TargetRoleName,TargetRoleID,TargetAction)"
                    sql &= "VALUES ("
                    sql &= CallingPage.Session("DistrictID") & "," & OwnerID & ",'" & item.Text & "'," & item.Value & ",'Rejected')"
                    db.ExecuteNonQuery(sql)
                End If
            Next


        End Sub
        'Public Sub DeleteWorkflowScenerio(ByVal id As Integer)
        '    Dim sql As String = "DELETE FROM WorkflowScenerios WHERE WorkflowScenerioID = " & id
        '    db.ExecuteNonQuery(sql)

        '    sql = "DELETE FROM WorkflowScenerioSteps WHERE WorkflowScenerioID = " & id
        '    db.ExecuteNonQuery(sql)

        'End Sub

        Public Sub DeleteWorkflowScenerioOwner(ByVal id As Integer)
            Dim sql As String = "DELETE FROM WorkflowScenerioOwners WHERE WorkflowScenerioOwnerID = " & id
            db.ExecuteNonQuery(sql)

            sql = "DELETE FROM WorkflowScenerioOwnerTargets WHERE WorkflowScenerioOwnerID = " & id
            db.ExecuteNonQuery(sql)

        End Sub

        'Public Sub SaveWorkflowScenerio(ByVal Key As Integer)
        '    Dim sql As String = ""
        '    'Takes data from the form and writes it to the database
        '    If Key = 0 Then      'new record
        '        sql = "INSERT INTO WorkflowScenerios "
        '        sql &= "(DistrictID)"
        '        sql &= "VALUES (" & CallingPage.Session("DistrictID") & ")"
        '        sql &= "SELECT CAST(SCOPE_IDENTITY() AS int) AS ID"

        '        Key = db.ExecuteScalar(sql)
        '    End If

        '    sql = "SELECT * FROM WorkflowScenerios WHERE WorkflowScenerioID = " & Key
        '    'pass the form and sql to fill routine
        '    Dim form As Control = CallingPage.FindControl("Form1")
        '    db.SaveForm(form, sql)

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

