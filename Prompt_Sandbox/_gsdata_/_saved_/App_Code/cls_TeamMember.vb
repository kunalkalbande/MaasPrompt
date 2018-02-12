Imports System
Imports System.Web
Imports System.Web.UI.WebControls
Imports System.IO
Imports System.Data
Imports System.Data.SqlClient
Imports Telerik.Web.UI

Namespace Prompt

    '********************************************
    '*  TeamMember Class
    '*  
    '*  Purpose: Processes data for the TeamMember Objects
    '*
    '*  Last Mod By:    Ford James
    '*  Last Mod On:    07/12/09
    '*
    '********************************************

    Public Class TeamMember
        Implements IDisposable

        'Properties
        Public CallingPage As Page
        Public CallingUserControl As UserControl   'used for refernce to dynamic UC as cannot get through calling page
        Public Reader As SqlDataReader
        Public DataTable As DataTable

        Private db As PromptDataHelper

        Public Sub New()
            db = New PromptDataHelper

        End Sub

#Region "Team Members"

        Public Function GetExistingMembersForDropDowns(ByVal ProjectID As Integer) As DataTable


            Dim tblSource As DataTable

            Dim sql As String = "SELECT dbo.TeamMembers.*, dbo.Contacts.*, "
            sql &= "dbo.Contacts.FirstName + ' ' + dbo.Contacts.LastName AS Contact,Contacts_1.Name AS Company "
            sql &= "FROM dbo.Contacts LEFT OUTER JOIN dbo.Contacts AS Contacts_1 ON dbo.Contacts.ParentContactID = Contacts_1.ContactID RIGHT OUTER JOIN "
            sql &= "dbo.TeamMembers ON dbo.Contacts.ContactID = dbo.TeamMembers.ContactID "
            sql &= "WHERE ProjectID = " & ProjectID & " "
            sql &= "ORDER BY TeamGroupDisplayOrder,TeamMemberDisplayOrder "



            tblSource = db.ExecuteDataTable(sql)

            'Add None Record
            Dim newrow As DataRow = tblSource.NewRow
            newrow("ContactID") = 0
            newrow("TeamMemberID") = 0
            newrow("TeamGroupName") = "--none--"
            newrow("Name") = "--none--"

            tblSource.Rows.InsertAt(newrow, 0)   'put it first


            Return tblSource

        End Function

        Public Function GetExistingMembers(ByVal ProjectID As Integer) As DataTable

            'Build a common table with info from contacts/projectmanagers/contractors

            Dim tblSource As DataTable

            Dim sql As String = "SELECT  TeamMembers.TeamMemberID, TeamMembers.DistrictID, TeamMembers.ProjectID, TeamMembers.UserID, "
            sql &= "TeamMembers.TeamGroupName, TeamMembers.TeamGroupDisplayOrder, TeamMembers.TeamMemberDisplayOrder, TeamMembers.LastUpdateOn, "
            sql &= "TeamMembers.LastUpdateBy, dbo.Contacts.*, "
            sql &= "dbo.Contacts.FirstName + ' ' + dbo.Contacts.LastName AS Contact,Contacts_1.Name AS Company "
            sql &= "FROM dbo.Contacts LEFT OUTER JOIN dbo.Contacts AS Contacts_1 ON dbo.Contacts.ParentContactID = Contacts_1.ContactID RIGHT OUTER JOIN "
            sql &= "dbo.TeamMembers ON dbo.Contacts.ContactID = dbo.TeamMembers.ContactID "
            sql &= "WHERE ProjectID = " & ProjectID & " "
            sql &= "ORDER BY TeamGroupDisplayOrder,TeamMemberDisplayOrder "

            tblSource = db.ExecuteDataTable(sql)



            Return tblSource

        End Function

        Public Sub GetExistingMembersToManage(ByVal tree As RadTreeView, ByVal ProjectID As Integer)

            Dim tbl As DataTable = GetExistingMembers(ProjectID)

            Dim parentnode As RadTreeNode = New RadTreeNode
            Dim childnode As RadTreeNode = New RadTreeNode
            Dim sLastGroup As String = "<<<none>>>"
            For Each row As DataRow In tbl.Rows
                If row("TeamGroupName") <> "" Then
                    If sLastGroup <> row("TeamGroupName") Then
                        sLastGroup = row("TeamGroupName")
                        parentnode = New RadTreeNode
                        With parentnode
                            .Text = sLastGroup
                            .Value = sLastGroup
                            .ImageUrl = "images/group_16x.png"
                            .Attributes.Add("Type", "TeamGroup")
                            .AllowDrag = True
                            .AllowDrop = True
                            .AllowEdit = True
                        End With
                        tree.Nodes.Add(parentnode)
                    End If
                End If

                childnode = New RadTreeNode
                With childnode
                    .Text = row("Name")
                    .ImageUrl = "images/user_16x.png"
                    .Attributes.Add("Type", "TeamMember")
                    .Attributes.Add("ContactID", row("ContactID"))
                    
                    
                    .AllowDrag = True
                    .AllowDrop = True
                    .AllowEdit = False
                End With
                If row("TeamGroupName") = "" Then
                    tree.Nodes.Add(childnode)
                Else
                    parentnode.Nodes.Add(childnode)
                End If


            Next



        End Sub


        Public Sub BuildSourceTree(ByVal tree As RadTreeView)

            tree.Nodes.Clear()
            Dim nodeParent As RadTreeNode
            Dim nodeMember As RadTreeNode
            'Dim nodeProject As RadTreeNode
            'Dim nodeTeamGroup As RadTreeNode

            Dim sql As String = ""

            '******* Project Managers

            nodeParent = New RadTreeNode
            With nodeParent
                .Text = "Project Managers"
                .Value = "ProjectManagers"
                .ImageUrl = "images/group_16x.png"
                .Attributes.Add("Type", "TeamGroup")
                .AllowDrag = False
                .AllowDrop = False
                .AllowEdit = False
            End With
            tree.Nodes.Add(nodeParent)

            Dim tbl As DataTable = db.ExecuteDataTable("SELECT * FROM Contacts WHERE DistrictID = " & HttpContext.Current.Session("DistrictID") & " AND ContactType = 'ProjectManager' AND InActive<>1 ORDER BY Name ")
            For Each row As DataRow In tbl.Rows
                nodeMember = New RadTreeNode
                With nodeMember
                    .Text = ProcLib.CheckNullDBField(row("Name"))
                    .ImageUrl = "images/user_16x.png"
                    .Attributes.Add("ContactID", row("ContactID"))
                    .Attributes.Add("Type", "TeamMember")
 
                    .AllowDrop = False
                    .AllowEdit = False
                    .AllowDrag = True
                End With
                nodeParent.Nodes.Add(nodeMember)
            Next

  

            '******* Companies

            nodeParent = New RadTreeNode
            With nodeParent
                .Text = "Companies"
                .Value = "Companies"
                .ImageUrl = "images/group_16x.png"
                .Attributes.Add("Type", "TeamGroup")
                .AllowDrop = False
                .AllowDrag = False
            End With
            tree.Nodes.Add(nodeParent)

            tbl = db.ExecuteDataTable("SELECT * FROM Contacts WHERE DistrictID = " & HttpContext.Current.Session("DistrictID") & " AND ContactType = 'Company' ORDER BY Name ")
            For Each row As DataRow In tbl.Rows
                nodeMember = New RadTreeNode
                With nodeMember
                    .Text = ProcLib.CheckNullDBField(row("Name"))
                    .ImageUrl = "images/user_16x.png"
                    .Attributes.Add("ContactID", row("ContactID"))
                    .Attributes.Add("Type", "TeamMember")
  
                    .AllowDrop = False
                    .AllowEdit = False
                    .AllowDrag = True
                End With
                nodeParent.Nodes.Add(nodeMember)

            Next


            '******* Contacts

            nodeParent = New RadTreeNode
            With nodeParent
                .Text = "Contacts"
                .Value = "Contacts"
                .ImageUrl = "images/group_16x.png"
                .Attributes.Add("Type", "ContactGroup")
                .AllowDrop = False
                .AllowDrag = False
            End With
            tree.Nodes.Add(nodeParent)

            sql = "SELECT Contacts.*, Companies.Name AS Company FROM Contacts LEFT OUTER JOIN Contacts AS Companies ON Contacts.ParentContactID = Companies.ContactID "
            sql &= "WHERE Contacts.DistrictID = " & HttpContext.Current.Session("DistrictID") & " AND Contacts.ContactType = 'Contact' ORDER BY FirstName "
            tbl = db.ExecuteDataTable(sql)
            For Each row As DataRow In tbl.Rows
                nodeMember = New RadTreeNode
                With nodeMember
                    Dim sName As String = ""
                    sName = ProcLib.CheckNullDBField(row("FirstName")) & " " & ProcLib.CheckNullDBField(row("LastName"))
                    'If row("ContactType") = "Company" Then
                    sName &= " (" & ProcLib.CheckNullDBField(row("Company")) & ")"
                    'End If
                    .Text = sName
                    .ImageUrl = "images/user_16x.png"
                    .Attributes.Add("ContactID", row("ContactID"))
                    .Attributes.Add("Type", "TeamMember")

                    .AllowDrop = False
                    .AllowEdit = False
                    .AllowDrag = True
                End With
                nodeParent.Nodes.Add(nodeMember)

            Next

            '******* Project Teams

            'nodeParent = New RadTreeNode
            'With nodeParent
            '    .Text = "Existing Teams"
            '    .ImageUrl = "images/group_16x.png"
            '    .Value = "ExistingTeamMembers"
            '    .Attributes.Add("Type", "TeamGroup")
            '    .AllowDrop = False
            '    .AllowDrag = False
            'End With
            'tree.Nodes.Add(nodeParent)

            'Dim nLastProjectID As Integer = 0
            'Dim nLastTeamGroup As String = ""
            'Dim nodeCurrentParent = New RadTreeNode
            'sql = "SELECT TeamMembers.*, Projects.ProjectName FROM TeamMembers "
            'sql &= "INNER JOIN Projects ON TeamMembers.ProjectID = Projects.ProjectID "
            'sql &= "WHERE TeamMembers.DistrictID = " & HttpContext.Current.Session("DistrictID") & " ORDER BY ProjectName, TeamGroupName, Name "
            'tbl = db.ExecuteDataTable(sql)
            'For Each row As DataRow In tbl.Rows
            '    If row("ProjectID") <> nLastProjectID Then
            '        nLastProjectID = row("ProjectID")
            '        nodeProject = New RadTreeNode
            '        With nodeProject
            '            .Text = row("ProjectName")
            '            .ImageUrl = "images/group_16x.png"
            '            .Value = "ProjectTeam" & nLastProjectID
            '            .Attributes.Add("Type", "ProjectTeam")
            '            .AllowDrop = False
            '            .AllowDrag = True
            '            .AllowEdit = False
            '        End With
            '        nodeParent.Nodes.Add(nodeProject)
            '        nodeCurrentParent = nodeProject

            '    End If

            '    If row("TeamGroupName") <> nLastTeamGroup And row("TeamGroupName") <> "" Then
            '        nLastTeamGroup = row("TeamGroupName")
            '        nodeTeamGroup = New RadTreeNode
            '        With nodeTeamGroup
            '            .Text = nLastTeamGroup
            '            .ImageUrl = "images/group_16x.png"
            '            .Value = nLastTeamGroup
            '            .Attributes.Add("Type", "TeamGroup")
            '            .AllowDrop = False
            '            .AllowDrag = True
            '            .AllowEdit = False
            '        End With
            '        nodeProject.Nodes.Add(nodeTeamGroup)
            '        nodeCurrentParent = nodeTeamGroup

            '    End If

            '    nodeMember = New RadTreeNode
            '    With nodeMember
            '        .Text = ProcLib.CheckNullDBField(row("Name"))
            '        .Value = "TeamMember" & row("TeamMemberID")
            '        .ImageUrl = "images/user_16x.png"
            '        .Attributes.Add("KeyField", "TeamMemberID")
            '        .Attributes.Add("SourceTable", "TeamMembers")
            '        .Attributes.Add("Type", "TeamMember")
            '        For Each col As DataColumn In tbl.Columns
            '            If col.ColumnName <> "LastUpdateOn" And col.ColumnName <> "LastUpdateBy" Then
            '                .Attributes.Add(col.ColumnName, ProcLib.CheckNullDBField(row(col.ColumnName)))
            '            End If

            '        Next
            '        .AllowDrop = False
            '        .AllowEdit = False
            '        .AllowDrag = True

            '    End With
            '    nodeCurrentParent.Nodes.Add(nodeMember)

            'Next

        End Sub

        Public Sub SaveTeamMembers(ByVal tree As RadTreeView, ByVal projectID As Integer)

            Dim sql As String = "DELETE FROM TeamMembers WHERE ProjectID = " & projectID
            db.ExecuteNonQuery(sql)

            db.FillDataTableForUpdate("SELECT * FROM TeamMembers WHERE ProjectID = " & projectID)
            Dim tblTarget As DataTable = db.DataTable

            Dim sLastGroup As String = ""
            Dim nGroupDisplayOrder As Integer = 0
            Dim nMemberDisplayOrder As Integer = 0
            For Each node As RadTreeNode In tree.Nodes
                If node.Attributes("Type") = "TeamGroup" And node.Text <> sLastGroup Then
                    sLastGroup = node.Text
                    nGroupDisplayOrder += 1
                    For Each nodeChild As RadTreeNode In node.Nodes   'there are members under this group
                        nMemberDisplayOrder += 1
                        Dim newrow As DataRow = tblTarget.NewRow

                        newrow("ContactID") = nodeChild.Attributes("ContactID")
                        newrow("DistrictID") = HttpContext.Current.Session("DistrictID")
                        newrow("ProjectID") = projectID
                        newrow("TeamGroupName") = sLastGroup
                        newrow("TeamGroupDisplayOrder") = nGroupDisplayOrder
                        newrow("TeamMemberDisplayOrder") = nMemberDisplayOrder
                        newrow("TeamGroupName") = sLastGroup
                        newrow("LastUpdateBy") = HttpContext.Current.Session("UserName")
                        newrow("LastUpdateOn") = Now

                        tblTarget.Rows.Add(newrow)
                    Next

                Else                'this is member not under a group 

                    nMemberDisplayOrder += 1
                    Dim newrow As DataRow = tblTarget.NewRow
                    newrow("ContactID") = node.Attributes("ContactID")
                    newrow("DistrictID") = HttpContext.Current.Session("DistrictID")
                    newrow("ProjectID") = projectID
                    newrow("TeamGroupName") = ""
                    newrow("TeamGroupDisplayOrder") = nGroupDisplayOrder
                    newrow("TeamMemberDisplayOrder") = nMemberDisplayOrder
                    newrow("LastUpdateBy") = HttpContext.Current.Session("UserName")
                    newrow("LastUpdateOn") = Now

                    tblTarget.Rows.Add(newrow)

                End If

            Next

            db.SaveDataTableToDB()

        End Sub


        Public Sub GetTeamMemberForEdit(ByVal id As Integer)

            'get a existing  record and populate with  info
            Dim row As DataRow
            row = db.GetDataRow("SELECT * FROM TeamMembers WHERE TeamMemberID = " & id)
            db.FillForm(CallingPage.FindControl("Form1"), row)

        End Sub

        'Public Sub SaveTeamMember(ByVal id As Integer, ByVal projectid As Integer)

        '    Dim form As Control = CallingPage.FindControl("Form1")  ' get ref to calling form
        '    Dim Sql As String = ""
        '    If id = 0 Then  'this is new so add new 
        '        Sql = "INSERT INTO TeamMembers "
        '        Sql &= "(DistrictID,ProjectID) "
        '        Sql &= "VALUES ("
        '        Sql &= CallingPage.Session("DistrictID") & "," & projectid & ")"
        '        Sql &= ";SELECT NewKey = Scope_Identity()"  'return the new primary key
        '        id = db.ExecuteScalar(Sql)
        '    End If

        '    'Saves record
        '    db.SaveForm(form, "SELECT * FROM TeamMembers WHERE TeamMemberID = " & id)

        'End Sub


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
