<%@ Page Language="VB" MasterPageFile="~/prompt.master" %>
<%@ Register Assembly="Telerik.Web.UI" Namespace="Telerik.Web.UI" TagPrefix="telerik" %>
<%@ Import Namespace="Prompt" %>

<script runat="server">
    

    Private sNavFilter As String = ""
        
        Private sSysAdminImageClass As String = "spIcon sprite-tree_node_systemadmin"
        Private sAdminItemImageClass As String = "spIcon sprite-tree_node_adminitem"
        Private sProjectGroupImageClass As String = "spIcon sprite-prompt_project_global_active"

        Private bShowProjectNumber As Boolean = False
        Private sProjectFilter As String = ""

        Private sCollegeList As String = ""
        Private bTechSupportUser As Boolean = False

    Private Sub Page_Load(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MyBase.Load

        If Request.QueryString("dashboard") = 12 Then
            Session("DashboardPageName") = "dashboard.aspx"
        ElseIf Request.QueryString("dashboard") = 16 Then
            Session("DashboardPageName") = "Default_LandingPage.aspx"   
        End If
        
        Session("PageID") = "Main"
        
        If HttpContext.Current.Session("UserRole") = "TechSupport" Then
            bTechSupportUser = True
        End If

        Using dbsec As New EISSecurity
            sCollegeList = dbsec.GetUserCollegeList()
        End Using
        
        
        
        

        'Handle change of District if needed
        If Request.QueryString("DistrictID") <> "" Then
            Session("DistrictID") = Request.QueryString("DistrictID")
            Session("DistrictName") = Request.QueryString("District")
            Session("ClientID") = Request.QueryString("ClientID")
            Using db As New NavMenu
                db.SetLastViewedDistrict()
            End Using
            
            Dim mm As MasterPage = Page.Master
            Dim menu As RadMenu = mm.FindControl("RadMenu1")
            Dim menuDistrict As RadMenuItem = menu.FindItemByValue("District")
            menuDistrict.Text = Session("DistrictName")
            
            Dim menuAppLogo As RadMenuItem = menu.FindItemByValue("AppLogo")
            Dim sLocale As String = ProcLib.GetLocale()
            With menuAppLogo
                If ProcLib.GetLocale() = "Production" Then
                    .Value = "AppLogo"
                    If Session("UsePromptName") = 1 Then
                        .ImageUrl = "images/prompt.ed_logo.png"
                        .CssClass = "logoheader"
                        Page.Header.Title = "Welcome to PROMPT.ed"
                    Else
                        .ImageUrl = "images/prompt.ed_logo.png"
                        .CssClass = "logoheader"
                        Page.Header.Title = "Welcome to PROMPT.ed"
                    End If
            
                    .Width = Unit.Pixel(250)
               
                ElseIf ProcLib.GetLocale() = "Beta" Then
                    .Value = "AppLogo"
                
                    If Session("UsePromptName") = 1 Then
                        .ImageUrl = "images/prompt.ed_logo.png"
                        .CssClass = "logoheader"
                        Page.Header.Title = "Prompt Beta"
                    Else
                        .ImageUrl = "images/prompt.ed_logo.png"
                        .CssClass = "logoheader"
                        Page.Header.Title = "Prompt Beta"
                    End If
                    .Width = Unit.Pixel(250)
					
					 
                ElseIf ProcLib.GetLocale() = "COD" Then
                    .Value = "AppLogo"
                
                    If Session("UsePromptName") = 1 Then
                        .ImageUrl = "images/prompt.ed_logo.png"
                        .CssClass = "logoheader"
                        Page.Header.Title = "Prompt COD"
                    Else
                        .ImageUrl = "images/prompt.ed_logo.png"
                        .CssClass = "logoheader"
                        Page.Header.Title = "Prompt COD"
                    End If
                    .Width = Unit.Pixel(250)
                
                Else
                    .Value = "AppLogo"
                    If Session("UsePromptName") = 1 Then
                        .ImageUrl = "images/prompt.ed_logo.png"
                        .CssClass = "logoheader"
                        Page.Header.Title = "Prompt Local"
                    Else
                        .ImageUrl = "images/prompt.ed_logo.png"
                        .CssClass = "logoheader"
                        Page.Header.Title = "Prompt Local"
                    End If
                    .Width = Unit.Pixel(250)
                
                End If
            End With
        End If
            
        radcboFilterTree.Visible = True

                
        If Not IsPostBack Then

            If Session("DirectCallCount") > 0 Then
                'NOTE: For some reason this page is called twice on direct calls, so we need to count and only apply 
                'settings on last call
                
                radcboFilterTree.SelectedIndex = 1    'Always All Projects in drop down when Direct Call for simplicy
                'radcboFilterTree.Text = "All Projects"   'All Projects
                
                If Session("DirectCallCount") = 1 Then
                    Session("DirectCallCount") = 2
                Else
                    BuildNavMenu()
                    contentPane.ContentUrl = Session("DirectCallURL")
                    Session("RefreshNav") = False
                    Session("nodeid") = ""
                    Session("DirectCallCount") = 0
                    Session("DirectCallURL") = ""
                End If
                
                          
            Else
                If Session("RefreshNav") = True Then     'this is call back after edit so set filter to all projects
                    radcboFilterTree.SelectedIndex = 1
                End If
                sNavFilter = radcboFilterTree.SelectedValue
                BuildNavMenu()
                Dim sPage As String = Session("DashboardPageName")
                If Session("RefreshNav") = False And sPage <> " " Then     'we are not coming back from edit so set to dashboard if appropriate
                    contentPane.ContentUrl = sPage
                End If
           
                Session("RefreshNav") = False
                Session("nodeid") = ""
            End If
        End If

    End Sub
    
    Private Sub BuildNavMenu()
        
        'Using db As New NavMenu
        '    db.BuildProjectsMenu(tree1, sNavFilter)
        'End Using
        
        BuildProjectsMenu(tree1, sNavFilter)
        
        'Set the targets to the content pane for all the nav items
        For Each node As RadTreeNode In tree1.GetAllNodes
            If node.Target = "mainFrame" Then
                node.Target = contentPane.ClientID
            End If
            
            'Update the Nav tree in the parent framework if needed.
            If node.Value = Session("nodeid") Then
                If Session("RefreshNav") Then    'need to update the node in the nav tree 
                    node.Selected = True
                    'Expand all nodes to this one
                    Dim nodeParent As RadTreeNode
                    nodeParent = node.ParentNode
                    While nodeParent IsNot Nothing
                        nodeParent.Expanded = True
                        nodeParent = nodeParent.ParentNode
                    End While
                    contentPane.ContentUrl = node.NavigateUrl
                End If
            End If
        Next
 
    End Sub

    Protected Sub radcboFilterTree_SelectedIndexChanged(ByVal o As Object, ByVal e As Telerik.Web.UI.RadComboBoxSelectedIndexChangedEventArgs) Handles radcboFilterTree.SelectedIndexChanged

        sNavFilter = o.SelectedValue
        BuildNavMenu()
        
    End Sub
    
         Public Function GetNavCollegesProjectsContracts(ByVal DistrictID As Integer) As DataTable
            'Get all the projects and contracts and provide table
            'check if this district requires project number prefix on Projects
            Dim sql = "SELECT ShowProjectNumberInMenu FROM Districts WHERE DistrictID = " & DistrictID
            
            Using db As New PromptDataHelper
                bShowProjectNumber = db.ExecuteScalar(sql)

                If bShowProjectNumber = True Then  'we need to sort differently
                    sql = "SELECT *  FROM qry_ProjectsContractsWithProjectNumber WHERE DistrictID = " & DistrictID & " ORDER BY College, Status, ProjectName, ContractStatus, ContractorName, ContractDescription "
                Else
                    sql = "SELECT *  FROM qry_ProjectsContracts WHERE DistrictID = " & DistrictID & " ORDER BY College, Status, ProjectName, ContractStatus, ContractorName, ContractDescription"
                End If

                Return db.ExecuteDataTable(sql)
            End Using
 

        End Function 
    
          Sub BuildProjectsMenu(ByVal tree1 As RadTreeView, ByVal sfilter As String)

            tree1.Nodes.Clear()

            Dim nDistrictID As Integer = HttpContext.Current.Session("DistrictID")

            Dim strCollegeNodeID As String = ""
            Dim strViewFile As String = ""
            Dim strCollege As String = ""
            Dim nCollegeID As Integer = 0
            Dim nLastProjectID As Integer = 0
            Dim sLastProjectStatus As String = ""
            Dim sLastContractStatus As String = ""
            Dim strContractGroupNodeID As String = ""

            Dim strContractNodeID As String = ""
            Dim strContractDescr As String = ""
            Dim nProjectID As Integer = 0
            Dim strProjectDescription As String
            Dim strDescription As String = ""
            Dim strProjectName As String = ""
            Dim strProjectNodeID As String = ""
            Dim nLastCollegeID As Integer = 0

            Dim nCollege As RadTreeNode = New RadTreeNode
            Dim nProject As RadTreeNode = New RadTreeNode
            Dim nContract As RadTreeNode = New RadTreeNode
            Dim nProjectStatusGroup As RadTreeNode = New RadTreeNode
            Dim nContractStatusGroup As RadTreeNode = New RadTreeNode
            Dim nNewCollege As Boolean = False    'flag for when college changes but project status does not

            sProjectFilter = sfilter


            Using dbsec As New EISSecurity
 
                'get the colleges this user can see
                Dim strVar As String = ""
                Dim rs As DataTable = GetNavCollegesProjectsContracts(nDistrictID)
                For Each row As DataRow In rs.Rows

                    strVar = ";" & CStr(row("CollegeID")) & ";"
                    If InStr(sCollegeList, strVar) > 0 Or bTechSupportUser Then 'add the node

                        If IsDBNull(row("ProjectID")) Then
                            nProjectID = 0
                        Else
                            nProjectID = row("ProjectID")
                        End If
                        If IsDBNull(row("ProjectName")) Then
                            strProjectName = "(No Name)"
                        Else
                            strProjectName = row("ProjectName")
                        End If


                        strProjectDescription = ProcLib.CheckNullDBField(row("ProjectDescription"))
                        strCollege = ProcLib.CheckNullDBField(row("College"))
                        nCollegeID = row("CollegeID")

                        If nLastCollegeID <> nCollegeID Then              'add the College node

                            nNewCollege = True
                            nCollege = New RadTreeNode
                            nLastCollegeID = nCollegeID
                            With nCollege
                                .Value = "CollegeParent" & row("CollegeID")
                                .Text = strCollege
                                .NavigateUrl = "college_overview.aspx?view=college&CollegeID=" & row("CollegeID")
                                .Target = "mainFrame"
                                .CssClass = "spIcon sprite-prompt_college"
                                .Attributes.Add("CollegeID", nCollegeID)
                                .Attributes.Add("NodeType", "College")
                            End With
                            tree1.Nodes.Add(nCollege)

                            dbsec.CollegeID = row("CollegeID")
                            If dbsec.FindUserPermission("LedgerList", "read") Then
                                'Add any Ledger Accounts for this college here
                                Using rsLedger As New promptLedgerAccount
                                    Dim tbl As DataTable = rsLedger.GetLedgerAccounts(row("CollegeID"))
                                    If tbl.Rows.Count > 0 Then
                                        For Each rowledg As DataRow In tbl.Rows
                                            Dim nLedger As New RadTreeNode
                                            With nLedger
                                                .Value = "Ledger" & rowledg("LedgerAccountID")
                                                .Text = rowledg("LedgerName")
                                                .NavigateUrl = "ledger_entries.aspx?view=ledgeraccount&LedgerAccountID=" & rowledg("LedgerAccountID") & "&CollegeID=" & rowledg("CollegeID")
                                                .Target = "mainFrame"
                                                .CssClass = "spIcon sprite-ledger_account"
                                                .Attributes.Add("CollegeID", nCollegeID)
                                                .Attributes.Add("LedgerAccountID", rowledg("LedgerAccountID"))
                                                .Attributes.Add("NodeType", "Ledger")
                                            End With
                                            nCollege.Nodes.Add(nLedger)
                                        Next
                                    End If
                                End Using
                            End If

                        End If

                        Dim bNewProject As Boolean = False

                        If nLastProjectID <> nProjectID Then   'add a new project line
                            nLastProjectID = nProjectID
                            bNewProject = True
                            Dim sCurrentProjectStatus As String = ""

                            'change icon depending on status
                            Dim strProjectImageClass As String = "spIcon sprite-prompt_project_active"
                            If Not IsDBNull(row("Status")) Then
                                sCurrentProjectStatus = row("Status")
                                If sCurrentProjectStatus = "2-Proposed" Then
                                    strProjectImageClass = "spIcon sprite-prompt_project_proposed"
                                ElseIf sCurrentProjectStatus = "4-Cancelled" Then
                                    strProjectImageClass = "spIcon sprite-prompt_project_cancelled"
                                ElseIf sCurrentProjectStatus = "3-Suspended" Then
                                    strProjectImageClass = "spIcon sprite-prompt_project_suspended"
                                ElseIf sCurrentProjectStatus = "5-Complete" Then
                                    strProjectImageClass = "spIcon sprite-prompt_project_complete"
                                ElseIf sCurrentProjectStatus = "6-Consolidated" Then
                                strProjectImageClass = "spIcon sprite-prompt_project_consolodated"
                            ElseIf sCurrentProjectStatus = "7-Deferred" Then
                                strProjectImageClass = "spIcon sprite-prompt_project_consolodated"
                                End If
                            End If

                            If sfilter <> "ActiveProjectsOnly" Then   'Group by Project Status
                                If sLastProjectStatus <> row("Status") Or nNewCollege Then       'If the status changes then time for new status group
                                    nNewCollege = False   'this flag test for a new college  -- there may only be single project status at a college so need this to trigger
                                    sLastProjectStatus = row("Status")
                                    nProjectStatusGroup = New RadTreeNode
                                    Dim sStatusGroupName As String = ""
                                    Dim cProjectColor As Color = Color.Green
                                    If Not IsDBNull(row("Status")) Then
                                        sStatusGroupName = "Active Projects"
                                        If row("Status") = "2-Proposed" Then
                                            cProjectColor = Color.Blue
                                            sStatusGroupName = "Proposed Projects"
                                        ElseIf row("Status") = "4-Cancelled" Then
                                            cProjectColor = Color.Red
                                            sStatusGroupName = "Cancelled Projects"
                                        ElseIf row("Status") = "3-Suspended" Then
                                            cProjectColor = Color.Orange
                                            sStatusGroupName = "Suspended Projects"
                                        ElseIf row("Status") = "5-Complete" Then
                                            cProjectColor = Color.Gray
                                            sStatusGroupName = "Completed Projects"
                                        ElseIf row("Status") = "6-Consolidated" Then
                                            cProjectColor = Color.Goldenrod
                                        sStatusGroupName = "Consolidated Projects"
                                    ElseIf row("Status") = "7-Deferred" Then
                                        cProjectColor = Color.DarkViolet
                                        sStatusGroupName = "Deferred Projects"
                                        End If
                                    End If
                                    With nProjectStatusGroup
                                        .Value = "College" & row("CollegeID") & sStatusGroupName.Replace(" ", "")
                                        .Text = sStatusGroupName
                                        .ForeColor = cProjectColor
                                        .Font.Bold = "true"
                                        .Attributes.Add("CollegeID", row("CollegeID"))
                                        .Attributes.Add("NodeType", "ProjectStatusGroup")
                                    End With

                                    nCollege.Nodes.Add(nProjectStatusGroup)
                                End If
                            End If

                            nProject = New RadTreeNode

                            With nProject
                                .Value = "Project" & nProjectID
                                .Text = strProjectName

                                .NavigateUrl = "project_overview.aspx?view=project&ProjectID=" & nProjectID & "&CollegeID=" & nCollegeID
                                .Target = "mainFrame"
                                .CssClass = strProjectImageClass
                                .Attributes.Add("ProjectGroupID", ProcLib.CheckNullNumField(row("ProjectGroupID")))
                                .Attributes.Add("ProjectID", nProjectID)
                                .Attributes.Add("CollegeID", nCollegeID)
                                .Attributes.Add("NodeType", "Project")
                            End With

                            If HttpContext.Current.Session("UserRole") = "TechSupport" Then
                                'Add the Logs Node under the project
                                Dim nLogNode As New RadTreeNode
                                With nLogNode
                                    .Value = "ProjectLogs" & nProjectID
                                    .Text = "Project Logs"

                                    .NavigateUrl = "rfis.aspx?view=projectlogs&ProjectID=" & nProjectID & "&CollegeID=" & nCollegeID
                                    .Target = "mainFrame"
                                    .ImageUrl = "images/prompt_task.gif"
                                    .Attributes.Add("ProjectID", nProjectID)
                                    .Attributes.Add("CollegeID", nCollegeID)
                                    .Attributes.Add("NodeType", "ProjectLog")
                                End With
                                nProject.Nodes.Add(nLogNode)
                            End If


                            If sfilter = "ActiveProjectsOnly" Then
                                If sCurrentProjectStatus = "1-Active" Then    'only add active projects
                                    nCollege.Nodes.Add(nProject)
                                End If

                            Else
                                nProjectStatusGroup.Nodes.Add(nProject)
                            End If


                        End If


                        'Add the contract
                        If Not IsDBNull(row("ContractID")) Then       'there is a contract so add it

                            nContract = New RadTreeNode

                            'change icon depending on status
                            Dim sCurrentContractStatus As String = ProcLib.CheckNullDBField(row("ContractStatus"))
                            Dim sContractImageClass As String = "spIcon sprite-prompt_contract_open"
                            If sCurrentContractStatus = "3-Pending" Then
                                sContractImageClass = "spIcon sprite-prompt_contract_pending"
                            ElseIf sCurrentContractStatus = "2-Closed" Then
                                sContractImageClass = "spIcon sprite-prompt_contract_closed"
                            End If


                            If sLastContractStatus <> sCurrentContractStatus Or bNewProject Then       'If the status changes then time for new status group

                                sLastContractStatus = sCurrentContractStatus
                                nContractStatusGroup = New RadTreeNode
                                Dim sStatusGroupName As String = ""
                                Dim cContractColor As Color = Color.Green


                                sStatusGroupName = "Open Contracts"
                                If sCurrentContractStatus = "3-Pending" Then
                                    cContractColor = Color.Goldenrod
                                    sStatusGroupName = "Pending Contracts"
                                ElseIf sCurrentContractStatus = "2-Closed" Then
                                    cContractColor = Color.Red
                                    sStatusGroupName = "Closed Contracts"
                                End If

                                With nContractStatusGroup
                                    .Value = "CS" & sStatusGroupName
                                    .Text = sStatusGroupName
                                    .ForeColor = cContractColor
                                    .Font.Bold = "true"
                                    .Attributes.Add("ParentCollegeID", nCollegeID)
                                    .Attributes.Add("NodeType", "ContractStatusGroup")
                                    .Attributes.Add("ProjectID", nProjectID)
                                    .Attributes.Add("CollegeID", nCollegeID)
                                End With

                                nProject.Nodes.Add(nContractStatusGroup)

                            End If

                            Dim strContractorName As String = ""
                            Dim strContractDescription As String = ""
                            Dim strToolTip As String = ""

                            strContractDescription = ProcLib.CheckNullDBField(row("ContractDescription"))
                            strContractorName = ProcLib.CheckNullDBField(row("ContractorName"))
                            strToolTip = strContractorName & "-(" & strContractDescription & ")"

                            If IsDBNull(strContractorName) Or strContractorName Is Nothing Then
                                strContractorName = ""
                            Else
                                If Len(strContractorName) > 10 Then
                                    strContractorName = Left(strContractorName, 10)
                                End If
                            End If

                            If Len(strContractDescription) > 20 Then
                                strContractDescription = Left(strContractDescription, 10)
                            End If

                            With nContract
                                .Value = "Contract" & row("ContractID")
                                .Text = strContractorName & "-(" & strContractDescription & ")"
                                .ToolTip = strToolTip
                                .NavigateUrl = "contract_overview.aspx?view=contract&ContractID=" & row("ContractID") & "&ProjectID=" & row("ProjectID") & "&CollegeID=" & nCollegeID
                                .Target = "mainFrame"
                                .CssClass = sContractImageClass

                                .Attributes.Add("ParentCollegeID", nCollegeID)
                                .Attributes.Add("ContractID", row("ContractID"))
                                .Attributes.Add("NodeType", "Contract")
                                .Attributes.Add("ProjectID", nProjectID)
                                .Attributes.Add("CollegeID", nCollegeID)

                            End With

                            nContractStatusGroup.Nodes.Add(nContract)

                        End If
                    End If
                Next

                AssignSubProjectsToProjectGroups(tree1)


                '******************* Filter for security - remove nodes user does not have rights to ***************************************

                Dim treeRef As New RadTreeView              'get a copy of the tree so we can traverse and remove nodes
                treeRef.LoadXmlString(tree1.GetXml())

                For Each nodeMaster As RadTreeNode In treeRef.GetAllNodes
                    Dim sNodeVal As String = nodeMaster.Value
                    If nodeMaster.Attributes("NodeType") = "College" Then    'this is college node
                        nCollegeID = nodeMaster.Attributes("CollegeID")
                        dbsec.CollegeID = nCollegeID

                        'Check if projects under this college inhereit rights from the college level or specifically assigned

                        If dbsec.SpecifyProjectRights(nCollegeID) = False Then    'they inherit, so check if college has project overivew read rights for user
                            If Not dbsec.FindUserPermission("ProjectOverview", "read") Then  'User does not have read permission for any projects so remove them
                                For Each nodechild As RadTreeNode In nodeMaster.Nodes
                                    If InStr(nodechild.Value, "Project") Then    'this is a project or project group so remove
                                        tree1.FindNodeByValue(nodechild.Value).Remove()
                                    End If
                                Next

                            Else            'okay to view projects, so check if okay to view contracts
                                If Not dbsec.FindUserPermission("ContractOverview", "read") Then      'no contracts allowed so remove them
                                    For Each node As RadTreeNode In tree1.GetAllNodes
                                        If node.Attributes("ParentCollegeID") = nCollegeID Then
                                            If InStr(node.Value, "Contract") > 0 Then
                                                tree1.FindNodeByValue(node.Value).Remove()
                                            End If
                                        End If
                                    Next
                                End If
                            End If


                        Else            'This college has specific right for each project, so only show the ones that have some rights assigned

                            Dim tblGoodProjects As DataTable = dbsec.GetAssignedProjectIDList(nCollegeID)    'get the list of assigned projects
                            For Each node As RadTreeNode In tree1.GetAllNodes
                                Dim bfound As Boolean = False
                                If node.Attributes("NodeType") = "Project" And node.Attributes("CollegeID") = nCollegeID Then     'this is a project node
                                    For Each row As DataRow In tblGoodProjects.Rows
                                        If node.Attributes("ProjectID") = row("ProjectID") And row("ObjectID") = "ProjectOverview" Then
                                            bfound = True
                                            Exit For
                                        End If
                                    Next
                                    If Not bfound Then
                                        node.Remove()
                                    End If
                                End If
                            Next

                            'Now remove any contracts if user has no read writes to contract overview
                            For Each node As RadTreeNode In tree1.GetAllNodes
                                Dim bfound As Boolean = False
                                If node.Attributes("NodeType") = "Contract" And node.Attributes("CollegeID") = nCollegeID Then     'this is a project node
                                    For Each row As DataRow In tblGoodProjects.Rows
                                        If node.Attributes("ProjectID") = row("ProjectID") And row("ObjectID") = "ContractOverview" Then
                                            bfound = True
                                            Exit For
                                        End If
                                    Next
                                    If Not bfound Then
                                        node.Remove()
                                    End If
                                End If

                            Next

                            'Now remove any empty project groups or project status groups from tree
                            For Each node As RadTreeNode In tree1.GetAllNodes
                                If node.Attributes("NodeType") = "ProjectGroup" And node.Attributes("CollegeID") = nCollegeID Then
                                    If node.Nodes.Count = 0 Then
                                        node.Remove()
                                    End If
                                End If
                            Next
                            For Each node As RadTreeNode In tree1.GetAllNodes
                                If node.Attributes("NodeType") = "ProjectStatusGroup" And node.Attributes("CollegeID") = nCollegeID Then
                                    If node.Nodes.Count = 0 Then
                                        node.Remove()
                                    End If
                                End If
                            Next
                            For Each node As RadTreeNode In tree1.GetAllNodes
                                If node.Attributes("NodeType") = "ContractStatusGroup" And node.Attributes("CollegeID") = nCollegeID Then
                                    If node.Nodes.Count = 0 Then
                                        node.Remove()
                                    End If
                                End If
                            Next


                        End If
                    End If
                Next



            End Using    'EISSecurity
        End Sub

        Private Sub AssignSubProjectsToProjectGroups(ByVal tree1 As RadTreeView)
            Using db As New PromptDataHelper
            'Get any Project Groups if present
            Dim sql As String = "SELECT * FROM ProjectGroups WHERE DistrictID = " & HttpContext.Current.Session("DistrictID") & " ORDER BY CollegeID "
            
            
            Dim tblGroups As DataTable = db.ExecuteDataTable(sql)
            
            
            If tblGroups.Rows.Count > 0 Then   'we need to insert the group records into the results
                For Each row As DataRow In tblGroups.Rows
                    If InStr(sCollegeList, ";" & row("CollegeID") & ";") > 0 Or bTechSupportUser Then    'this college is in this persons access list
                        Dim sName As String = row("Name")
                        If bShowProjectNumber = True Then
                            sName = row("ProjectNumber") & "-" & row("Name")
                        End If
                        Dim nodeGroup As New RadTreeNode
                        With nodeGroup
                            .Text = sName
                            .Value = "ProjectGroup" & row("ProjectGroupID")
                            .NavigateUrl = "project_group.aspx?view=projectgroup&CollegeID=" & row("CollegeID") & "&ProjectGroupID=" & row("ProjectGroupID")
                            .Target = "mainFrame"

                            .CssClass = sProjectGroupImageClass
                            .Attributes.Add("NodeType", "ProjectGroup")
                            .Attributes.Add("CollegeID", row("CollegeID"))
                        End With

                        'Now we need to find each project that belongs to group and make a child of the node
                        For Each node As RadTreeNode In tree1.GetAllNodes()
                            If node.Attributes("ProjectGroupID") = row("ProjectGroupID") Then
                                Dim newnode As RadTreeNode = node.Clone()
                                nodeGroup.Nodes.Add(newnode)
                                node.Remove()
                            End If
                        Next

                        If nodeGroup.Nodes.Count > 0 Then
                            Dim nodeParent As RadTreeNode
                            If sProjectFilter = "ActiveProjectsOnly" Then
                                If InStr(row("Status"), "Active") > 0 Then
                                    nodeParent = tree1.FindNodeByValue("CollegeParent" & row("CollegeID"))
                                    nodeParent.Nodes.Add(nodeGroup)
                                End If

                            Else
                                'Determine which group to add to
                                If InStr(row("Status"), "Active") Then
                                    nodeParent = tree1.FindNodeByValue("College" & row("CollegeID") & "ActiveProjects")
                                ElseIf InStr(row("Status"), "Cancelled") Then
                                    nodeParent = tree1.FindNodeByValue("College" & row("CollegeID") & "CancelledProjects")
                                ElseIf InStr(row("Status"), "Proposed") Then
                                    nodeParent = tree1.FindNodeByValue("College" & row("CollegeID") & "ProposedProjects")

                                ElseIf InStr(row("Status"), "Suspended") Then
                                    nodeParent = tree1.FindNodeByValue("College" & row("CollegeID") & "SuspendedProjects")
                                ElseIf InStr(row("Status"), "Complete") Then
                                    nodeParent = tree1.FindNodeByValue("College" & row("CollegeID") & "CompletedProjects")
                                ElseIf InStr(row("Status"), "Deferred") Then
                                    nodeParent = tree1.FindNodeByValue("College" & row("CollegeID") & "DeferredProjects")

                                Else
                                    nodeParent = tree1.FindNodeByValue("College" & row("CollegeID") & "ActiveProjects")
                                End If
                                
                                'Big hammer - if need will just put in the first available node  (9-2011-ford)
                                If IsNothing(nodeParent) Then
                                    nodeParent = tree1.FindNodeByValue("College" & row("CollegeID") & "ActiveProjects")
                                End If
                                If IsNothing(nodeParent) Then
                                    nodeParent = tree1.FindNodeByValue("College" & row("CollegeID") & "ProposedProjects")
                                End If
                                If IsNothing(nodeParent) Then
                                    nodeParent = tree1.FindNodeByValue("College" & row("CollegeID") & "CompletedProjects")
                                End If
                                If IsNothing(nodeParent) Then
                                    nodeParent = tree1.FindNodeByValue("College" & row("CollegeID") & "CancelledProjects")
                                End If
                                If IsNothing(nodeParent) Then
                                    nodeParent = tree1.FindNodeByValue("College" & row("CollegeID") & "DeferredProjects")
                                End If
                                
                                
                                
                                nodeParent.Nodes.Add(nodeGroup)
                            End If

                        End If

                    End If
                Next

                'Now go through and find the approiate parents and sort the project inside of them
                Dim nLastCollegeID As Integer = 0
                For Each row As DataRow In tblGroups.Rows
                    If InStr(sCollegeList, ";" & row("CollegeID") & ";") > 0 Or bTechSupportUser Then      'this college is in this persons access list
                        If nLastCollegeID <> row("CollegeID") Then
                            nLastCollegeID = row("CollegeID")
                            Dim nodeParent As RadTreeNode
                            If sProjectFilter = "ActiveProjectsOnly" Then
                                nodeParent = tree1.FindNodeByValue("CollegeParent" & row("CollegeID"))
                            Else
                                nodeParent = tree1.FindNodeByValue("College" & row("CollegeID") & "ActiveProjects")   'add to active projects group under the college
                                
                                'Big hammer - if need will just put in the first available node  (9-2011-ford)
                                If IsNothing(nodeParent) Then
                                    nodeParent = tree1.FindNodeByValue("College" & row("CollegeID") & "ProposedProjects")
                                End If
                                If IsNothing(nodeParent) Then
                                    nodeParent = tree1.FindNodeByValue("College" & row("CollegeID") & "CompletedProjects")
                                End If
                                If IsNothing(nodeParent) Then
                                    nodeParent = tree1.FindNodeByValue("College" & row("CollegeID") & "CancelledProjects")
                                End If
                                If IsNothing(nodeParent) Then
                                    nodeParent = tree1.FindNodeByValue("College" & row("CollegeID") & "DeferredProjects")
                                End If
                                
                            End If

                            Dim ItemCollection As New RadTreeNodeCollection(nodeParent)       'Create a new collection to store che child items.
                            'Create a new arraylist to store the text values of the nodes
                            Dim TextCollection As New ArrayList()
                            'Populate ItemCollection and TextCollection.
                            For Each node As RadTreeNode In nodeParent.Nodes
                                ItemCollection.Add(node)
                                TextCollection.Add(node.Text)
                            Next

                            Dim nodeNewParent As New RadTreeNode
                            For Each Node As RadTreeNode In nodeParent.Nodes
                                If Node.CssClass = "spIcon sprite-ledger_account" Then
                                    Dim newNode As RadTreeNode = Node.Clone
                                    nodeNewParent.Nodes.Add(newNode)
                                End If
                            Next

                            'You can use the ItemCollection to filter, sort, reverse order or apply any rule to 
                            'the child items. In this case we sort the items by text in ascending order. 
                            TextCollection.Sort()
                            Dim s As String
                            For Each s In TextCollection
                                For Each Node As RadTreeNode In ItemCollection
                                    If Node.Text = s Then
                                        If Node.CssClass <> "spIcon sprite-ledger_account" Then
                                            nodeNewParent.Nodes.Add(Node)
                                        End If
                                    End If
                                Next
                            Next

                            nodeParent.Nodes.Clear()
                            For Each node As RadTreeNode In nodeNewParent.Nodes
                                Dim newNode As RadTreeNode = node.Clone
                                nodeParent.Nodes.Add(newNode)
                            Next

                        End If
                    End If
                Next
            End If
        End Using
        
        End Sub   
         
</script>

<asp:Content ID="Content1" ContentPlaceHolderID="mainBody" runat="Server">
    <telerik:RadSplitter ID="RadSplitter1" runat="server" Skin="Sitefinity" Width="100%" Height="95%" SplitBarsSize="8" >
        <telerik:RadPane ID="navPane" runat="server" Width="280"  EnableViewState="true" >
        <div class="leftnavcss">
           <div style="position:relative;width:100%;height:20px;text-align:center;top:10px;font-size:14px;font-weight:bold;display:none">Financial Manager Dashboard</div>
 
            <br />
            &nbsp;&nbsp;&nbsp;&nbsp;
            <telerik:RadComboBox ID="radcboFilterTree" runat="server" Skin="Default" Text="Filter" Width="200"
                AutoPostBack="True">
                <Items>
                    <telerik:RadComboBoxItem runat="server" Text="Active Projects Only" Value="ActiveProjectsOnly" />
                    <telerik:RadComboBoxItem runat="server" Text="All Projects" Value="AllProjects" />
                </Items>
            </telerik:RadComboBox>
             <br />
            <br />
            <telerik:RadTreeView ID="tree1" runat="server" EnableViewState="False" ShowLineImages="True"
                OnClientNodeClicked="ClientNodeClicked" ExpandDelay="0" EnableEmbeddedSkins="false" Skin="Leftnav">
            </telerik:RadTreeView>
        </div>
        </telerik:RadPane>
        <%--<telerik:RadSplitBar ID="RadSplitBar1" runat="server" CollapseMode="None" />--%> 
        <telerik:RadPane ID="contentPane" runat="server" Scrolling="Both"  EnableViewState="true" ContentUrl="about:blank">content pane</telerik:RadPane>
    </telerik:RadSplitter>


    <script type="text/javascript" language="javascript">

        function refreshParentPage() {     //called from child pages when reloaded after edit and when nav needs updating
            document.location.href = 'main.aspx';
        }

        function ClientNodeClicked(sender, eventArgs) {
            var node = eventArgs.get_node();
            node.toggle();
        }

        function getTreeObject() {
            window.treeView = $find("<%=tree1.ClientID%>");
            return window.treeView;
        }

    </script>
</asp:Content>
