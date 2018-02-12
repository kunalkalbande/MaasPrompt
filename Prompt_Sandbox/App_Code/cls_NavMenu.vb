Imports System
Imports System.Web
Imports System.Web.UI.WebControls
Imports System.IO
Imports System.Data
Imports System.Data.SqlClient
Imports Telerik.Web.UI
Imports System.Drawing

Namespace Prompt

    '********************************************
    '*  nav Class
    '*  
    '*  Purpose: Processes data for the nav object
    '*
    '*  Last Mod By:    Ford James
    '*  Last Mod On:    02/13/09
    '*
    '********************************************

    Public Class NavMenu
        Implements IDisposable

        'Properties
        Public CallingPage As Page
        Public Reader As SqlDataReader

        Private sSysAdminImageClass As String = "spIcon sprite-tree_node_systemadmin"
        Private sAdminItemImageClass As String = "spIcon sprite-tree_node_adminitem"
        Private sProjectGroupImageClass As String = "spIcon sprite-prompt_project_global_active"

        Private bShowProjectNumber As Boolean = False
        Private sProjectFilter As String = ""

        Private sCollegeList As String = ""
        Private bTechSupportUser As Boolean = False
        'Private bIsPromptDistrictAdmin As Boolean = False

        Private db As PromptDataHelper

        Public Sub New()
            db = New PromptDataHelper

            If HttpContext.Current.Session("UserRole") = "TechSupport" Then
                bTechSupportUser = True
            End If

            Using dbsec As New EISSecurity
                sCollegeList = dbsec.GetUserCollegeList()
            End Using

        End Sub


#Region "Subs and Functions"
        'Handles all the nav page database calls


        Public Function GetOtherUserList() As DataTable
            'Get all the users for tech support to login as other user
            Dim sql As String = "SELECT UserName, UserID FROM Users WHERE AccountDisabled = 0 ORDER BY UserName ASC"
            Return db.ExecuteDataTable(sql)

        End Function

        Public Function GetNavGlobalLookups(ByVal ParentTable As String) As DataTable
            'Get all the global lookups (system) and provide reader
            Dim sql As String = "SELECT Distinct ParentField FROM Lookups  WHERE ParentTable = '" & ParentTable & "' AND DistrictID = 0 ORDER BY ParentField ASC"
            Return db.ExecuteDataTable(sql)

        End Function


        Public Sub LoadClientDistricts(ByVal mNode As RadMenuItem)

            Dim tbl As DataTable
            Dim sql As String = ""
            Dim bSingleDistrictUser As Boolean = False

            Dim sDistrictList As String = HttpContext.Current.Session("DistrictList")
            If InStr(sDistrictList, ";;") = 0 Then 'there is only one district - districts are separated by ;; - so go directly to this district 
                bSingleDistrictUser = True
                HttpContext.Current.Session("DistrictID") = Replace(sDistrictList, ";", "")
            End If

            sql = "SELECT Clients.ClientID,Clients.ClientName, Districts.Name AS District,Districts.UsePromptName, Districts.DistrictID "
            sql &= "FROM Clients INNER JOIN Districts ON Clients.ClientID = Districts.ClientID WHERE Districts.InActive = 0 "
            sql &= "ORDER BY Clients.ClientName, District "
            tbl = db.ExecuteDataTable(sql)

            Dim sLastClient As String = ""
            Dim item As New Telerik.Web.UI.RadMenuItem
            For Each row As DataRow In tbl.Rows

                If Not bSingleDistrictUser Then                         'check to see if user has access or if tech support
                    Dim sCurDistrict As String = ";" & row("DistrictID") & ";"
                    If InStr(sDistrictList, sCurDistrict) > 0 Or HttpContext.Current.Session("UserRole") = "TechSupport" Then
                        If sLastClient <> row("ClientName") Then        'add separator
                            sLastClient = row("ClientName")
                            item = New Telerik.Web.UI.RadMenuItem
                            item.IsSeparator = "True"
                            mNode.Items.Add(item)

                            item = New Telerik.Web.UI.RadMenuItem
                            item.Text = row("ClientName")
                            item.PostBack = False
                            item.BackColor = System.Drawing.Color.FromName("#c4c4c4")
                            item.ForeColor = System.Drawing.Color.FromName("#292929")
							item.Font.Bold = True
                            item.ImageUrl = "images/cube_green.png"
                            item.Attributes.Add("ClientID", row("ClientID"))
                            mNode.Items.Add(item)

                            item = New Telerik.Web.UI.RadMenuItem
                            item.IsSeparator = "True"
                            item.PostBack = False
                            mNode.Items.Add(item)
                        End If
                        item = New Telerik.Web.UI.RadMenuItem
                        item.Value = row("DistrictID")
                        item.Text = row("District")
                        item.Attributes.Add("ClientID", row("ClientID"))

                        item.NavigateUrl = "main.aspx?DistrictID=" & row("DistrictID") & "&District=" & row("District") & "&ClientID=" & row("ClientID")

                        If HttpContext.Current.Session("DistrictID") = row("DistrictID") Then
                            mNode.Text = item.Text
                            HttpContext.Current.Session("DistrictName") = row("District")
                            HttpContext.Current.Session("UsePromptName") = row("UsePromptName")

                            sql = "SELECT EnableWorkflow FROM Districts WHERE DistrictID = " & row("DistrictID")
                            Dim result = db.ExecuteScalar(sql)
                            If Not IsDBNull(result) Then
                                HttpContext.Current.Session("EnableWorkflow") = result
                            End If

                        End If
                        mNode.Items.Add(item)
                    End If
                Else            'single district user so only set parms for one district
                    If HttpContext.Current.Session("DistrictID") = row("DistrictID") Then
                        mNode.Text = item.Text
                        HttpContext.Current.Session("DistrictName") = row("District")
                        HttpContext.Current.Session("UsePromptName") = row("UsePromptName")

                        sql = "SELECT EnableWorkflow FROM Districts WHERE DistrictID = " & row("DistrictID")
                        Dim result = db.ExecuteScalar(sql)
                        If Not IsDBNull(result) Then
                            HttpContext.Current.Session("EnableWorkflow") = result
                        End If
                    End If
                End If

            Next

        End Sub

        Public Sub SetLastViewedDistrict()
            'sets the last district viewed for user
            db.ExecuteNonQuery("UPDATE Users SET LastDistrictViewed = " & HttpContext.Current.Session("DistrictID") & " WHERE UserID = " & HttpContext.Current.Session("UserID"))
            HttpContext.Current.Session("UsePromptName") = db.ExecuteScalar("SELECT UsePromptName FROM Districts WHERE DistrictID = " & HttpContext.Current.Session("DistrictID"))
        End Sub

        Public Sub BuildAdminMenu(ByVal tree1 As RadTreeView)

            'Builds the admin menus

            Dim nDistrictID As Integer = HttpContext.Current.Session("DistrictID")

            '******************************************       User Changeable Settings
            Dim node As RadTreeNode
            Dim nodetop As New RadTreeNode
            nodetop.Text = "My Settings"
            ' nodetop.Expanded = True
            tree1.Nodes.Add(nodetop)

            Dim nPwd As New RadTreeNode
            With nPwd
                .Value = "PasswordChange"
                .Text = "Change Password"
                .NavigateUrl = "password_change.aspx"
                .Target = "contentPane"

            End With
            nodetop.Nodes.Add(nPwd)

            'If HttpContext.Current.Session("DashboardPageName") = "dashboard.aspx" Then
            nPwd = New RadTreeNode
            With nPwd
                .Value = "DashboardSettings"
                .Text = "Reset Saved Grid Settings"
                .NavigateUrl = "dashboard_settings.aspx"
                .Target = "contentPane"

            End With
            nodetop.Nodes.Add(nPwd)

            'End If

            Using dbsec As New EISSecurity


                If dbsec.FindUserPermission("DistrictBondWebsiteInfo", "read") Then
                    Dim nodeBondsite As RadTreeNode = New RadTreeNode
                    With nodeBondsite
                        .Text = "Maintain District Bond Website Info"
                        .Value = "DistrictBondWebsiteInfo"
                    End With

                    Dim nodechild As RadTreeNode = New RadTreeNode
                    With nodechild
                        .Text = "Current News"
                        .Value = "CurrentNews"
                        .Target = "contentPane"
                        .NavigateUrl = "bondsite_currentnews.aspx"
                    End With
                    nodeBondsite.Nodes.Add(nodechild)

                    nodechild = New RadTreeNode
                    With nodechild
                        .Text = "CBOC Meeting Minutes"
                        .Value = "BondsiteMeetingMinutes"
                        .Target = "contentPane"
                        .NavigateUrl = "bondsite_meetings.aspx"
                    End With
                    nodeBondsite.Nodes.Add(nodechild)

                    nodechild = New RadTreeNode
                    With nodechild
                        .Text = "Links"
                        .Value = "BondsiteLinks"
                        .Target = "contentPane"
                        .NavigateUrl = "bondsite_links.aspx"
                    End With
                    nodeBondsite.Nodes.Add(nodechild)

                    tree1.Nodes.Add(nodeBondsite)

                End If


                If dbsec.FindUserPermission("TableMaintenance", "read") Then


                    ''************************************* FHDA FE Settings 
                    If HttpContext.Current.Session("DistrictID") = 55 Then

                        Dim FEnode As New RadTreeNode
                        FEnode.Text = "FHDA FE Settings"
                        '   FEnode.Expanded = True
                        tree1.Nodes.Add(FEnode)

                        Dim n1b As New RadTreeNode
                        With n1b
                            .Value = "FE_BudgetsList"
                            .Target = "contentPane"
                            .NavigateUrl = "list_show.aspx?ListType=FE_Budgets&DistrictID=" & nDistrictID
                            .Text = "Furn. & Equip. Budgets"
                        End With
                        FEnode.Nodes.Add(n1b)

                        Dim n1c As New RadTreeNode
                        With n1c
                            .Value = "FE_LogList"
                            .Target = "contentPane"
                            .NavigateUrl = "list_show.aspx?ListType=FE_LogList&DistrictID=" & nDistrictID
                            .Text = "View F&E Change Log"
                        End With
                        FEnode.Nodes.Add(n1c)
                    End If

                    Dim n33 As New RadTreeNode
                    With n33
                        .Value = "CMDMNotes"
                        .Target = "contentPane"
                        .NavigateUrl = "admin_CMDMNotes.aspx"
                        .Text = "CM/DM Report Notes"
                    End With
                    tree1.Nodes.Add(n33)

                    ''************************************* Lookup Tables 
                    Dim nLookups As New RadTreeNode
                    With nLookups
                        .Value = "Lookups"
                        .Target = "contentPane"
                        .Text = "Table Maintenance"
                    End With
                    tree1.Nodes.Add(nLookups)

                    Dim nObjectCodes As New RadTreeNode
                    With nObjectCodes
                        .Value = "ObjectCodes"
                        .NavigateUrl = "objectcodes_list.aspx"
                        .Target = "contentPane"
                        .Text = "Object Codes"

                    End With
                    nLookups.Nodes.Add(nObjectCodes)

                    'Add the lookups links
                    Dim sLabel As String = ""
                    Dim i As Integer = 0
                    Dim strParentTable As String = ""
                    For i = 1 To 4
                        If i = 1 Then
                            strParentTable = "Projects"
                            sLabel = strParentTable
                        ElseIf i = 2 Then
                            strParentTable = "Contractors"
                            sLabel = strParentTable
                        ElseIf i = 3 Then
                            strParentTable = "Contracts"
                            sLabel = "Contracts"
                        ElseIf i = 4 Then
                            strParentTable = "ContractDetail"
                            sLabel = "Amendments/COs"
                        End If

                        Dim nLookupTable As New RadTreeNode
                        With nLookupTable
                            .Value = "Lookup" & i
                            .Target = "contentPane"
                            .Text = sLabel
                        End With
                        nLookups.Nodes.Add(nLookupTable)

                        'NOTE: For user editable lookups, you need to "seed" the lookup table with a dummy entry for 
                        'district = 0 so that the lookup category will show up under the appropriate table.
                        'ie. to creat a new lookup called "flavors" under "Projects" you need to manually enter a record
                        'in the database lookup table with district = 0, parent table=Projects; Parent Field = flavors

                        Dim rsLook As DataTable = db.ExecuteDataTable("SELECT Distinct ParentField  FROM Lookups  WHERE ParentTable = '" & strParentTable & "' AND UserEditable = 1 ORDER BY ParentField ASC")
                        Dim ii As Integer
                        ii = i * 100 'create unique key
                        Dim rs2 As DataTable = GetNavUserEditableLookups(strParentTable)
                        For Each row As DataRow In rs2.Rows
                            If row("ParentField") <> "ObjectCode" Then   'HACK; to exclude during Object COde transition - can be removed later.
                                ii = ii + 1
                                Dim nL1 As New RadTreeNode
                                With nL1
                                    .Value = "Lookup" & ii
                                    .NavigateUrl = "list_show.aspx?ListType=Lookups&ParentField=" & row("ParentField") & "&ParentTable=" & strParentTable
                                    .Target = "contentPane"
                                    .Text = row("ParentField")
                                End With
                                nLookupTable.Nodes.Add(nL1)
                            End If
                        Next
                    Next

                    If HttpContext.Current.Session("UserRole") = "TechSupport" Then

                        'add Global Lookup Administration
                        Dim nGLookups = New RadTreeNode
                        With nGLookups
                            .Value = "Lookups"
                            .Target = "contentPane"
                            .Text = "Global Lookup Admin"
                        End With
                        nLookups.Nodes.Add(nGLookups)

                        'Add the lookups links
                        sLabel = ""
                        i = 0
                        strParentTable = ""
                        For i = 1 To 6
                            If i = 1 Then
                                strParentTable = "Projects"
                                sLabel = strParentTable
                            ElseIf i = 2 Then
                                strParentTable = "Contractors"
                                sLabel = strParentTable
                            ElseIf i = 3 Then
                                strParentTable = "Transactions"
                                sLabel = strParentTable
                            ElseIf i = 4 Then
                                strParentTable = "Contracts"
                                sLabel = "Contracts"
                            ElseIf i = 5 Then
                                strParentTable = "ContractDetail"
                                sLabel = "Amendments/COs"
                            ElseIf i = 6 Then
                                strParentTable = "Reports"
                                sLabel = "Reports"
                            End If

                            Dim nLookupTable As New RadTreeNode
                            With nLookupTable
                                .Value = "Lookup" & i
                                .Target = "contentPane"
                                .Text = sLabel


                            End With
                            nGLookups.Nodes.Add(nLookupTable)

                            'Get Global Lookup Values
                            Dim ii As Integer
                            ii = i * 100 'create unique key
                            Dim rsww As DataTable = GetNavGlobalLookups(strParentTable)
                            For Each row As DataRow In rsww.Rows
                                ii = ii + 1
                                Dim nL1 As New RadTreeNode
                                With nL1
                                    .Value = "Lookup" & ii
                                    .NavigateUrl = "list_show.aspx?ListType=GlobalLookupAdmin&ParentField=" & row("ParentField") & "&ParentTable=" & strParentTable
                                    .Target = "contentPane"
                                    .Text = row("ParentField")


                                End With
                                nLookupTable.Nodes.Add(nL1)
                            Next
                        Next

                    End If

                End If

                If HttpContext.Current.Session("UserRole") = "TechSupport" Then


                    Dim n1 As New RadTreeNode
                    '****************************************  System Settings 


                    '-------------------- District Defaults

                    node = New RadTreeNode
                    node.Text = "District Settings (Current District)"
                    tree1.Nodes.Add(node)

                    n1 = New RadTreeNode
                    n1.Text = "Tab Visibility"
                    n1.NavigateUrl = "administration_settings.aspx?type=Tab&districtid=" & nDistrictID
                    n1.Target = "contentPane"
                    node.Nodes.Add(n1)

                    n1 = New RadTreeNode
                    n1.Text = "Widget Visbility"
                    n1.NavigateUrl = "administration_settings.aspx?type=Widget&districtid=0" & nDistrictID
                    n1.Target = "contentPane"
                    node.Nodes.Add(n1)

                    n1 = New RadTreeNode
                    n1.Text = "Menu Visibility"
                    n1.NavigateUrl = "administration_settings.aspx?type=MenuItem&districtid=0" & nDistrictID
                    n1.Target = "contentPane"
                    node.Nodes.Add(n1)




                    nodetop = New RadTreeNode
                    nodetop.Text = "System Settings"
                    tree1.Nodes.Add(nodetop)

                    '-------------------- System Defaults

                    n1 = New RadTreeNode
                    n1.Text = "Tab Visibility"
                    n1.NavigateUrl = "administration_settings.aspx?type=Tab&districtid=0"
                    n1.Target = "contentPane"
                    nodetop.Nodes.Add(n1)

                    n1 = New RadTreeNode
                    n1.Text = "Widget Visbility"
                    n1.NavigateUrl = "administration_settings.aspx?type=Widget&districtid=0"
                    n1.Target = "contentPane"
                    nodetop.Nodes.Add(n1)

                    n1 = New RadTreeNode
                    n1.Text = "Menu Visibility"
                    n1.NavigateUrl = "administration_settings.aspx?type=MenuItem&districtid=0"
                    n1.Target = "contentPane"
                    nodetop.Nodes.Add(n1)




                    '******************* Maintain Clients/Districts/Colleges
                    n1 = New RadTreeNode
                    With n1
                        .Value = "ClientMaint"
                        .Target = "contentPane"
                        .NavigateUrl = "admin_client_maint_list.aspx"
                        .Text = "Maintain Clients/Districts/Colleges"
                    End With
                    tree1.Nodes.Add(n1)

                    Dim n2 As New RadTreeNode
                    With n2
                        .Value = "UserMaint"
                        .Target = "contentPane"
                        .NavigateUrl = "admin_users.aspx"
                        .Text = "Maintain Users"

                    End With
                    tree1.Nodes.Add(n2)

                    Dim n2xx As New RadTreeNode
                    With n2xx
                        .Value = "UserRoleMaint"
                        .Target = "contentPane"
                        .NavigateUrl = "admin_user_roles.aspx"
                        .Text = "Maintain User Roles"

                    End With
                    tree1.Nodes.Add(n2xx)

                    Dim n3 As New RadTreeNode
                    With n3
                        .Value = "HelpFileMaint"
                        .Target = "contentPane"
                        .NavigateUrl = "list_show.aspx?ListType=Help"
                        .Text = "Maintain Help Files"

                    End With
                    tree1.Nodes.Add(n3)

                    Dim n4 As New RadTreeNode
                    With n4
                        .Value = "ReportMaint"
                        .Target = "contentPane"
                        .NavigateUrl = "list_show.aspx?ListType=ReportAdmin"
                        .Text = "Maintain Reports"


                    End With
                    tree1.Nodes.Add(n4)

                    Dim n4xx As New RadTreeNode
                    With n4xx
                        .Value = "AnnounEdit"
                        .Target = "contentPane"
                        .NavigateUrl = "admin_announcements_edit.aspx"
                        .Text = "Update Prompt Announcement"


                    End With
                    tree1.Nodes.Add(n4xx)

                    Dim n5 As New RadTreeNode
                    With n5
                        .Value = "Routines"
                        .Target = "contentPane"
                        .Text = "System Utilities"
                    End With
                    tree1.Nodes.Add(n5)

                    Dim tbl As DataTable = GetProcedureList()
                    For Each row As DataRow In tbl.Rows
                        Dim n5aa As New RadTreeNode
                        With n5aa
                            .Value = "SysUtil"
                            .Target = "contentPane"
                            .NavigateUrl = "system_utilities.aspx?proc=" & row("PrimaryKey")
                            .Text = row("Title")


                        End With
                        n5.Nodes.Add(n5aa)
                    Next

                    node = New RadTreeNode
                    With node
                        .Value = "CopyCollege"
                        .Target = "contentPane"
                        .NavigateUrl = "college_copy.aspx?DistrictID=" & nDistrictID
                        .Text = "Copy College"
                    End With
                    n5.Nodes.Add(node)


                    '************************************* Workflow Settings 
                    nodetop = New RadTreeNode
                    nodetop.Text = "Workflow Settings"
                    tree1.Nodes.Add(nodetop)

                    Dim nWorkflowRoles As New RadTreeNode
                    With nWorkflowRoles
                        .Value = "WorkflowRoles"
                        .NavigateUrl = "workflow_roles_list.aspx"
                        .Target = "contentPane"
                        .Text = "Maintain Workflow Roles"
                    End With
                    nodetop.Nodes.Add(nWorkflowRoles)

                    Dim nWorkflowScenerios As New RadTreeNode
                    With nWorkflowScenerios
                        .Value = "WorkflowScenerios"
                        .NavigateUrl = "workflow_scenerios_list.aspx"
                        .Target = "contentPane"
                        .Text = "Maintain Workflow Scenerios"
                    End With
                    nodetop.Nodes.Add(nWorkflowScenerios)

                    node = New RadTreeNode
                    With node
                        .Value = "ViewTransactionImportLog"
                        .NavigateUrl = "workflow_transaction_import_log_view.aspx"
                        .Target = "contentPane"
                        .Text = "View Transaction Import Batch Log"
                    End With
                    nodetop.Nodes.Add(node)



                    ''Add login As entries
                    'Dim n5a As New RadTreeNode
                    'With n5a
                    '    .Value = "LogInAs"
                    '    .Text = "Log In As Another User"

                    'End With
                    'tree1.Nodes.Add(n5a)

                    'tbl = GetOtherUserList()
                    'For Each row As DataRow In tbl.Rows
                    '    Dim n5aa As New RadTreeNode
                    '    With n5aa
                    '        .Value = "OtherUser"
                    '        .Target = "contentPane"
                    '        .NavigateUrl = "index.aspx?loginasanotheruser=100&otherid=" & row("UserID")
                    '        .Text = row("UserName")


                    '    End With
                    '    n5a.Nodes.Add(n5aa)
                    'Next


                    Dim n5x As New RadTreeNode
                    With n5x
                        .Value = "UserActivity"
                        .Target = "contentPane"
                        .NavigateUrl = "user_activity.aspx"
                        .Text = "User Activity Report"


                    End With
                    tree1.Nodes.Add(n5x)

                    Dim n5xx As New RadTreeNode
                    With n5xx
                        .Value = "TestReport"
                        .Target = "_new"
                        .NavigateUrl = "report_viewer.aspx"
                        .Text = "Test Report Viewer"


                    End With
                    tree1.Nodes.Add(n5xx)

                    Dim n6 As New RadTreeNode
                    With n6
                        .Value = "FileRepair"
                        .Target = "contentPane"
                        .NavigateUrl = "File_Name_Repair.aspx"
                        .Text = "File Name Repair"


                    End With
                    tree1.Nodes.Add(n6)

                End If

            End Using     'EISsecurity


        End Sub

        'Public Function GetNavCollegesProjectsContracts(ByVal DistrictID As Integer) As DataTable
        '    'Get all the projects and contracts and provide table
        '    'check if this district requires project number prefix on Projects
        '    Dim sql = "SELECT ShowProjectNumberInMenu FROM Districts WHERE DistrictID = " & DistrictID

        '    bShowProjectNumber = db.ExecuteScalar(sql)

        '    If bShowProjectNumber = True Then  'we need to sort differently
        '        sql = "SELECT *  FROM qry_ProjectsContractsWithProjectNumber WHERE DistrictID = " & DistrictID & " ORDER BY College, Status, ProjectName, ContractStatus, ContractorName, ContractDescription "
        '    Else
        '        sql = "SELECT *  FROM qry_ProjectsContracts WHERE DistrictID = " & DistrictID & " ORDER BY College, Status, ProjectName, ContractStatus, ContractorName, ContractDescription"
        '    End If

        '    Return db.ExecuteDataTable(sql)

        'End Function

        Public Function GetNavUserEditableLookups(ByVal ParentTable As String) As DataTable
            'Get all the global lookups (system) and provide reader
            Dim sql As String = "SELECT Distinct ParentField  FROM Lookups  WHERE ParentTable = '" & ParentTable & "' AND UserEditable = 1 ORDER BY ParentField ASC"
            Return db.ExecuteDataTable(sql)
        End Function

        Public Function GetProcedureList() As DataTable

            Return db.ExecuteDataTable("SELECT * FROM SystemUtilities ")

        End Function


        'Sub BuildProjectsMenu(ByVal tree1 As RadTreeView, ByVal sfilter As String)

        '    tree1.Nodes.Clear()

        '    Dim nDistrictID As Integer = HttpContext.Current.Session("DistrictID")

        '    Dim strCollegeNodeID As String = ""
        '    Dim strViewFile As String = ""
        '    Dim strCollege As String = ""
        '    Dim nCollegeID As Integer = 0
        '    Dim nLastProjectID As Integer = 0
        '    Dim sLastProjectStatus As String = ""
        '    Dim sLastContractStatus As String = ""
        '    Dim strContractGroupNodeID As String = ""

        '    Dim strContractNodeID As String = ""
        '    Dim strContractDescr As String = ""
        '    Dim nProjectID As Integer = 0
        '    Dim strProjectDescription As String
        '    Dim strDescription As String = ""
        '    Dim strProjectName As String = ""
        '    Dim strProjectNodeID As String = ""
        '    Dim nLastCollegeID As Integer = 0

        '    Dim nCollege As RadTreeNode = New RadTreeNode
        '    Dim nProject As RadTreeNode = New RadTreeNode
        '    Dim nContract As RadTreeNode = New RadTreeNode
        '    Dim nProjectStatusGroup As RadTreeNode = New RadTreeNode
        '    Dim nContractStatusGroup As RadTreeNode = New RadTreeNode
        '    Dim nNewCollege As Boolean = False    'flag for when college changes but project status does not

        '    sProjectFilter = sfilter


        '    Using dbsec As New EISSecurity

        '        'get the colleges this user can see
        '        Dim strVar As String = ""
        '        Dim rs As DataTable = GetNavCollegesProjectsContracts(nDistrictID)
        '        For Each row As DataRow In rs.Rows

        '            strVar = ";" & CStr(row("CollegeID")) & ";"
        '            If InStr(sCollegeList, strVar) > 0 Or bTechSupportUser Then 'add the node

        '                If IsDBNull(row("ProjectID")) Then
        '                    nProjectID = 0
        '                Else
        '                    nProjectID = row("ProjectID")
        '                End If
        '                If IsDBNull(row("ProjectName")) Then
        '                    strProjectName = "(No Name)"
        '                Else
        '                    strProjectName = row("ProjectName")
        '                End If


        '                strProjectDescription = ProcLib.CheckNullDBField(row("ProjectDescription"))
        '                strCollege = ProcLib.CheckNullDBField(row("College"))
        '                nCollegeID = row("CollegeID")

        '                If nLastCollegeID <> nCollegeID Then              'add the College node

        '                    nNewCollege = True
        '                    nCollege = New RadTreeNode
        '                    nLastCollegeID = nCollegeID
        '                    With nCollege
        '                        .Value = "CollegeParent" & row("CollegeID")
        '                        .Text = strCollege
        '                        .NavigateUrl = "college_overview.aspx?view=college&CollegeID=" & row("CollegeID")
        '                        .Target = "mainFrame"
        '                        .CssClass = "spIcon sprite-prompt_college"
        '                        .Attributes.Add("CollegeID", nCollegeID)
        '                        .Attributes.Add("NodeType", "College")
        '                    End With
        '                    tree1.Nodes.Add(nCollege)

        '                    dbsec.CollegeID = row("CollegeID")
        '                    If dbsec.FindUserPermission("LedgerList", "read") Then
        '                        'Add any Ledger Accounts for this college here
        '                        Using rsLedger As New promptLedgerAccount
        '                            Dim tbl As DataTable = rsLedger.GetLedgerAccounts(row("CollegeID"))
        '                            If tbl.Rows.Count > 0 Then
        '                                For Each rowledg As DataRow In tbl.Rows
        '                                    Dim nLedger As New RadTreeNode
        '                                    With nLedger
        '                                        .Value = "Ledger" & rowledg("LedgerAccountID")
        '                                        .Text = rowledg("LedgerName")
        '                                        .NavigateUrl = "ledger_entries.aspx?view=ledgeraccount&LedgerAccountID=" & rowledg("LedgerAccountID") & "&CollegeID=" & rowledg("CollegeID")
        '                                        .Target = "mainFrame"
        '                                        .CssClass = "spIcon sprite-ledger_account"
        '                                        .Attributes.Add("CollegeID", nCollegeID)
        '                                        .Attributes.Add("LedgerAccountID", rowledg("LedgerAccountID"))
        '                                        .Attributes.Add("NodeType", "Ledger")
        '                                    End With
        '                                    nCollege.Nodes.Add(nLedger)
        '                                Next
        '                            End If
        '                        End Using
        '                    End If

        '                End If

        '                Dim bNewProject As Boolean = False

        '                If nLastProjectID <> nProjectID Then   'add a new project line
        '                    nLastProjectID = nProjectID
        '                    bNewProject = True
        '                    Dim sCurrentProjectStatus As String = ""

        '                    'change icon depending on status
        '                    Dim strProjectImageClass As String = "spIcon sprite-prompt_project_active"
        '                    If Not IsDBNull(row("Status")) Then
        '                        sCurrentProjectStatus = row("Status")
        '                        If sCurrentProjectStatus = "2-Proposed" Then
        '                            strProjectImageClass = "spIcon sprite-prompt_project_proposed"
        '                        ElseIf sCurrentProjectStatus = "4-Cancelled" Then
        '                            strProjectImageClass = "spIcon sprite-prompt_project_cancelled"
        '                        ElseIf sCurrentProjectStatus = "3-Suspended" Then
        '                            strProjectImageClass = "spIcon sprite-prompt_project_suspended"
        '                        ElseIf sCurrentProjectStatus = "5-Complete" Then
        '                            strProjectImageClass = "spIcon sprite-prompt_project_complete"
        '                        ElseIf sCurrentProjectStatus = "6-Consolidated" Then
        '                            strProjectImageClass = "spIcon sprite-prompt_project_consolodated"
        '                        End If
        '                    End If

        '                    If sfilter <> "ActiveProjectsOnly" Then   'Group by Project Status
        '                        If sLastProjectStatus <> row("Status") Or nNewCollege Then       'If the status changes then time for new status group
        '                            nNewCollege = False   'this flag test for a new college  -- there may only be single project status at a college so need this to trigger
        '                            sLastProjectStatus = row("Status")
        '                            nProjectStatusGroup = New RadTreeNode
        '                            Dim sStatusGroupName As String = ""
        '                            Dim cProjectColor As Color = Color.Green
        '                            If Not IsDBNull(row("Status")) Then
        '                                sStatusGroupName = "Active Projects"
        '                                If row("Status") = "2-Proposed" Then
        '                                    cProjectColor = Color.Blue
        '                                    sStatusGroupName = "Proposed Projects"
        '                                ElseIf row("Status") = "4-Cancelled" Then
        '                                    cProjectColor = Color.Red
        '                                    sStatusGroupName = "Cancelled Projects"
        '                                ElseIf row("Status") = "3-Suspended" Then
        '                                    cProjectColor = Color.Orange
        '                                    sStatusGroupName = "Suspended Projects"
        '                                ElseIf row("Status") = "5-Complete" Then
        '                                    cProjectColor = Color.Gray
        '                                    sStatusGroupName = "Completed Projects"
        '                                ElseIf row("Status") = "6-Consolidated" Then
        '                                    cProjectColor = Color.Goldenrod
        '                                    sStatusGroupName = "Consolidated Projects"
        '                                End If
        '                            End If
        '                            With nProjectStatusGroup
        '                                .Value = "College" & row("CollegeID") & sStatusGroupName.Replace(" ", "")
        '                                .Text = sStatusGroupName
        '                                .ForeColor = cProjectColor
        '                                .Font.Bold = "true"
        '                                .Attributes.Add("CollegeID", row("CollegeID"))
        '                                .Attributes.Add("NodeType", "ProjectStatusGroup")
        '                            End With

        '                            nCollege.Nodes.Add(nProjectStatusGroup)
        '                        End If
        '                    End If

        '                    nProject = New RadTreeNode

        '                    With nProject
        '                        .Value = "Project" & nProjectID
        '                        .Text = strProjectName

        '                        .NavigateUrl = "project_overview.aspx?view=project&ProjectID=" & nProjectID & "&CollegeID=" & nCollegeID
        '                        .Target = "mainFrame"
        '                        .CssClass = strProjectImageClass
        '                        .Attributes.Add("ProjectGroupID", ProcLib.CheckNullNumField(row("ProjectGroupID")))
        '                        .Attributes.Add("ProjectID", nProjectID)
        '                        .Attributes.Add("CollegeID", nCollegeID)
        '                        .Attributes.Add("NodeType", "Project")
        '                    End With

        '                    If HttpContext.Current.Session("UserRole") = "TechSupport" Then
        '                        'Add the Logs Node under the project
        '                        Dim nLogNode As New RadTreeNode
        '                        With nLogNode
        '                            .Value = "ProjectLogs" & nProjectID
        '                            .Text = "Project Logs"

        '                            .NavigateUrl = "rfis.aspx?view=projectlogs&ProjectID=" & nProjectID & "&CollegeID=" & nCollegeID
        '                            .Target = "mainFrame"
        '                            .ImageUrl = "images/prompt_task.gif"
        '                            .Attributes.Add("ProjectID", nProjectID)
        '                            .Attributes.Add("CollegeID", nCollegeID)
        '                            .Attributes.Add("NodeType", "ProjectLog")
        '                        End With
        '                        nProject.Nodes.Add(nLogNode)
        '                    End If


        '                    If sfilter = "ActiveProjectsOnly" Then
        '                        If sCurrentProjectStatus = "1-Active" Then    'only add active projects
        '                            nCollege.Nodes.Add(nProject)
        '                        End If

        '                    Else
        '                        nProjectStatusGroup.Nodes.Add(nProject)
        '                    End If


        '                End If


        '                'Add the contract
        '                If Not IsDBNull(row("ContractID")) Then       'there is a contract so add it

        '                    nContract = New RadTreeNode

        '                    'change icon depending on status
        '                    Dim sCurrentContractStatus As String = ProcLib.CheckNullDBField(row("ContractStatus"))
        '                    Dim sContractImageClass As String = "spIcon sprite-prompt_contract_open"
        '                    If sCurrentContractStatus = "3-Pending" Then
        '                        sContractImageClass = "spIcon sprite-prompt_contract_pending"
        '                    ElseIf sCurrentContractStatus = "2-Closed" Then
        '                        sContractImageClass = "spIcon sprite-prompt_contract_closed"
        '                    End If


        '                    If sLastContractStatus <> sCurrentContractStatus Or bNewProject Then       'If the status changes then time for new status group

        '                        sLastContractStatus = sCurrentContractStatus
        '                        nContractStatusGroup = New RadTreeNode
        '                        Dim sStatusGroupName As String = ""
        '                        Dim cContractColor As Color = Color.Green


        '                        sStatusGroupName = "Open Contracts"
        '                        If sCurrentContractStatus = "3-Pending" Then
        '                            cContractColor = Color.Goldenrod
        '                            sStatusGroupName = "Pending Contracts"
        '                        ElseIf sCurrentContractStatus = "2-Closed" Then
        '                            cContractColor = Color.Red
        '                            sStatusGroupName = "Closed Contracts"
        '                        End If

        '                        With nContractStatusGroup
        '                            .Value = "CS" & sStatusGroupName
        '                            .Text = sStatusGroupName
        '                            .ForeColor = cContractColor
        '                            .Font.Bold = "true"
        '                            .Attributes.Add("ParentCollegeID", nCollegeID)
        '                            .Attributes.Add("NodeType", "ContractStatusGroup")
        '                            .Attributes.Add("ProjectID", nProjectID)
        '                            .Attributes.Add("CollegeID", nCollegeID)
        '                        End With

        '                        nProject.Nodes.Add(nContractStatusGroup)

        '                    End If

        '                    Dim strContractorName As String = ""
        '                    Dim strContractDescription As String = ""
        '                    Dim strToolTip As String = ""

        '                    strContractDescription = ProcLib.CheckNullDBField(row("ContractDescription"))
        '                    strContractorName = ProcLib.CheckNullDBField(row("ContractorName"))
        '                    strToolTip = strContractorName & "-(" & strContractDescription & ")"

        '                    If IsDBNull(strContractorName) Or strContractorName Is Nothing Then
        '                        strContractorName = ""
        '                    Else
        '                        If Len(strContractorName) > 10 Then
        '                            strContractorName = Left(strContractorName, 10)
        '                        End If
        '                    End If

        '                    If Len(strContractDescription) > 20 Then
        '                        strContractDescription = Left(strContractDescription, 10)
        '                    End If

        '                    With nContract
        '                        .Value = "Contract" & row("ContractID")
        '                        .Text = strContractorName & "-(" & strContractDescription & ")"
        '                        .ToolTip = strToolTip
        '                        .NavigateUrl = "contract_overview.aspx?view=contract&ContractID=" & row("ContractID") & "&ProjectID=" & row("ProjectID") & "&CollegeID=" & nCollegeID
        '                        .Target = "mainFrame"
        '                        .CssClass = sContractImageClass

        '                        .Attributes.Add("ParentCollegeID", nCollegeID)
        '                        .Attributes.Add("ContractID", row("ContractID"))
        '                        .Attributes.Add("NodeType", "Contract")
        '                        .Attributes.Add("ProjectID", nProjectID)
        '                        .Attributes.Add("CollegeID", nCollegeID)

        '                    End With

        '                    nContractStatusGroup.Nodes.Add(nContract)

        '                End If
        '            End If
        '        Next

        '        AssignSubProjectsToProjectGroups(tree1)


        '        '******************* Filter for security - remove nodes user does not have rights to ***************************************

        '        Dim treeRef As New RadTreeView              'get a copy of the tree so we can traverse and remove nodes
        '        treeRef.LoadXmlString(tree1.GetXml())

        '        For Each nodeMaster As RadTreeNode In treeRef.GetAllNodes
        '            Dim sNodeVal As String = nodeMaster.Value
        '            If nodeMaster.Attributes("NodeType") = "College" Then    'this is college node
        '                nCollegeID = nodeMaster.Attributes("CollegeID")
        '                dbsec.CollegeID = nCollegeID

        '                'Check if projects under this college inhereit rights from the college level or specifically assigned

        '                If dbsec.SpecifyProjectRights(nCollegeID) = False Then    'they inherit, so check if college has project overivew read rights for user
        '                    If Not dbsec.FindUserPermission("ProjectOverview", "read") Then  'User does not have read permission for any projects so remove them
        '                        For Each nodechild As RadTreeNode In nodeMaster.Nodes
        '                            If InStr(nodechild.Value, "Project") Then    'this is a project or project group so remove
        '                                tree1.FindNodeByValue(nodechild.Value).Remove()
        '                            End If
        '                        Next

        '                    Else            'okay to view projects, so check if okay to view contracts
        '                        If Not dbsec.FindUserPermission("ContractOverview", "read") Then      'no contracts allowed so remove them
        '                            For Each node As RadTreeNode In tree1.GetAllNodes
        '                                If node.Attributes("ParentCollegeID") = nCollegeID Then
        '                                    If InStr(node.Value, "Contract") > 0 Then
        '                                        tree1.FindNodeByValue(node.Value).Remove()
        '                                    End If
        '                                End If
        '                            Next
        '                        End If
        '                    End If


        '                Else            'This college has specific right for each project, so only show the ones that have some rights assigned

        '                    Dim tblGoodProjects As DataTable = dbsec.GetAssignedProjectIDList(nCollegeID)    'get the list of assigned projects
        '                    For Each node As RadTreeNode In tree1.GetAllNodes
        '                        Dim bfound As Boolean = False
        '                        If node.Attributes("NodeType") = "Project" And node.Attributes("CollegeID") = nCollegeID Then     'this is a project node
        '                            For Each row As DataRow In tblGoodProjects.Rows
        '                                If node.Attributes("ProjectID") = row("ProjectID") And row("ObjectID") = "ProjectOverview" Then
        '                                    bfound = True
        '                                    Exit For
        '                                End If
        '                            Next
        '                            If Not bfound Then
        '                                node.Remove()
        '                            End If
        '                        End If
        '                    Next

        '                    'Now remove any contracts if user has no read writes to contract overview
        '                    For Each node As RadTreeNode In tree1.GetAllNodes
        '                        Dim bfound As Boolean = False
        '                        If node.Attributes("NodeType") = "Contract" And node.Attributes("CollegeID") = nCollegeID Then     'this is a project node
        '                            For Each row As DataRow In tblGoodProjects.Rows
        '                                If node.Attributes("ProjectID") = row("ProjectID") And row("ObjectID") = "ContractOverview" Then
        '                                    bfound = True
        '                                    Exit For
        '                                End If
        '                            Next
        '                            If Not bfound Then
        '                                node.Remove()
        '                            End If
        '                        End If

        '                    Next

        '                    'Now remove any empty project groups or project status groups from tree
        '                    For Each node As RadTreeNode In tree1.GetAllNodes
        '                        If node.Attributes("NodeType") = "ProjectGroup" And node.Attributes("CollegeID") = nCollegeID Then
        '                            If node.Nodes.Count = 0 Then
        '                                node.Remove()
        '                            End If
        '                        End If
        '                    Next
        '                    For Each node As RadTreeNode In tree1.GetAllNodes
        '                        If node.Attributes("NodeType") = "ProjectStatusGroup" And node.Attributes("CollegeID") = nCollegeID Then
        '                            If node.Nodes.Count = 0 Then
        '                                node.Remove()
        '                            End If
        '                        End If
        '                    Next
        '                    For Each node As RadTreeNode In tree1.GetAllNodes
        '                        If node.Attributes("NodeType") = "ContractStatusGroup" And node.Attributes("CollegeID") = nCollegeID Then
        '                            If node.Nodes.Count = 0 Then
        '                                node.Remove()
        '                            End If
        '                        End If
        '                    Next


        '                End If
        '            End If
        '        Next



        '    End Using    'EISSecurity
        'End Sub

        'Private Sub AssignSubProjectsToProjectGroups(ByVal tree1 As RadTreeView)

        '    'Get any Project Groups if present
        '    Dim sql As String = "SELECT * FROM ProjectGroups WHERE DistrictID = " & HttpContext.Current.Session("DistrictID") & " ORDER BY CollegeID "
        '    Dim tblGroups As DataTable = db.ExecuteDataTable(sql)
        '    If tblGroups.Rows.Count > 0 Then   'we need to insert the group records into the results
        '        For Each row As DataRow In tblGroups.Rows
        '            If InStr(sCollegeList, ";" & row("CollegeID") & ";") > 0 Or bTechSupportUser Then    'this college is in this persons access list
        '                Dim sName As String = row("Name")
        '                If bShowProjectNumber = True Then
        '                    sName = row("ProjectNumber") & "-" & row("Name")
        '                End If
        '                Dim nodeGroup As New RadTreeNode
        '                With nodeGroup
        '                    .Text = sName
        '                    .Value = "ProjectGroup" & row("ProjectGroupID")
        '                    .NavigateUrl = "project_group.aspx?view=projectgroup&CollegeID=" & row("CollegeID") & "&ProjectGroupID=" & row("ProjectGroupID")
        '                    .Target = "mainFrame"

        '                    .CssClass = sProjectGroupImageClass
        '                    .Attributes.Add("NodeType", "ProjectGroup")
        '                    .Attributes.Add("CollegeID", row("CollegeID"))
        '                End With

        '                'Now we need to find each project that belongs to group and make a child of the node
        '                For Each node As RadTreeNode In tree1.GetAllNodes()
        '                    If node.Attributes("ProjectGroupID") = row("ProjectGroupID") Then
        '                        Dim newnode As RadTreeNode = node.Clone()
        '                        nodeGroup.Nodes.Add(newnode)
        '                        node.Remove()
        '                    End If
        '                Next

        '                If nodeGroup.Nodes.Count > 0 Then
        '                    Dim nodeParent As RadTreeNode
        '                    If sProjectFilter = "ActiveProjectsOnly" Then
        '                        If InStr(row("Status"), "Active") > 0 Then
        '                            nodeParent = tree1.FindNodeByValue("CollegeParent" & row("CollegeID"))
        '                            nodeParent.Nodes.Add(nodeGroup)
        '                        End If

        '                    Else
        '                        'Determine which group to add to
        '                        If InStr(row("Status"), "Active") Then
        '                            nodeParent = tree1.FindNodeByValue("College" & row("CollegeID") & "ActiveProjects")
        '                        ElseIf InStr(row("Status"), "Cancelled") Then
        '                            nodeParent = tree1.FindNodeByValue("College" & row("CollegeID") & "CancelledProjects")
        '                        ElseIf InStr(row("Status"), "Proposed") Then
        '                            nodeParent = tree1.FindNodeByValue("College" & row("CollegeID") & "ProposedProjects")

        '                        ElseIf InStr(row("Status"), "Suspended") Then
        '                            nodeParent = tree1.FindNodeByValue("College" & row("CollegeID") & "SuspendedProjects")
        '                        ElseIf InStr(row("Status"), "Complete") Then
        '                            nodeParent = tree1.FindNodeByValue("College" & row("CollegeID") & "CompletedProjects")

        '                        Else
        '                            nodeParent = tree1.FindNodeByValue("College" & row("CollegeID") & "ActiveProjects")
        '                        End If
        '                        nodeParent.Nodes.Add(nodeGroup)
        '                    End If

        '                End If

        '            End If
        '        Next

        '        'Now go through and find the approiate parents and sort the project inside of them
        '        Dim nLastCollegeID As Integer = 0
        '        For Each row As DataRow In tblGroups.Rows
        '            If InStr(sCollegeList, ";" & row("CollegeID") & ";") > 0 Or bTechSupportUser Then      'this college is in this persons access list
        '                If nLastCollegeID <> row("CollegeID") Then
        '                    nLastCollegeID = row("CollegeID")
        '                    Dim nodeParent As RadTreeNode
        '                    If sProjectFilter = "ActiveProjectsOnly" Then
        '                        nodeParent = tree1.FindNodeByValue("CollegeParent" & row("CollegeID"))
        '                    Else
        '                        nodeParent = tree1.FindNodeByValue("College" & row("CollegeID") & "ActiveProjects")   'add to active projects group under the college
        '                    End If

        '                    Dim ItemCollection As New RadTreeNodeCollection(nodeParent)       'Create a new collection to store che child items.
        '                    'Create a new arraylist to store the text values of the nodes
        '                    Dim TextCollection As New ArrayList()
        '                    'Populate ItemCollection and TextCollection.
        '                    For Each node As RadTreeNode In nodeParent.Nodes
        '                        ItemCollection.Add(node)
        '                        TextCollection.Add(node.Text)
        '                    Next

        '                    Dim nodeNewParent As New RadTreeNode
        '                    For Each Node As RadTreeNode In nodeParent.Nodes
        '                        If Node.CssClass = "spIcon sprite-ledger_account" Then
        '                            Dim newNode As RadTreeNode = Node.Clone
        '                            nodeNewParent.Nodes.Add(newNode)
        '                        End If
        '                    Next

        '                    'You can use the ItemCollection to filter, sort, reverse order or apply any rule to 
        '                    'the child items. In this case we sort the items by text in ascending order. 
        '                    TextCollection.Sort()
        '                    Dim s As String
        '                    For Each s In TextCollection
        '                        For Each Node As RadTreeNode In ItemCollection
        '                            If Node.Text = s Then
        '                                If Node.CssClass <> "spIcon sprite-ledger_account" Then
        '                                    nodeNewParent.Nodes.Add(Node)
        '                                End If
        '                            End If
        '                        Next
        '                    Next

        '                    nodeParent.Nodes.Clear()
        '                    For Each node As RadTreeNode In nodeNewParent.Nodes
        '                        Dim newNode As RadTreeNode = node.Clone
        '                        nodeParent.Nodes.Add(newNode)
        '                    Next

        '                End If
        '            End If
        '        Next
        '    End If

        'End Sub

#End Region
#Region "IDisposable"

        Public Overridable Sub Dispose() Implements IDisposable.Dispose
            If Not db Is Nothing Then
                db.Dispose()
            End If
            If Not Reader Is Nothing Then
                Reader.Close()
                Reader.Dispose()
            End If
        End Sub

#End Region

    End Class

End Namespace

