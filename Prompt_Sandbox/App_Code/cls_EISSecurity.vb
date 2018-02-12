Imports System
Imports System.Web
Imports System.Web.UI.WebControls
Imports System.IO
Imports System.Data
Imports System.Net.Mail
Imports Telerik.Web.UI



Namespace Prompt

    '********************************************
    '*  Security Class
    '*  
    '*  Purpose: Processes data for the Security objects
    '*
    '*  Last Mod By:    Ford James
    '*  Last Mod On:    10/25/09
    '*
    '********************************************

    Public Class EISSecurity

        Implements IDisposable

        'Properties
        Public CallingPage As Page
        Public DistrictID As Integer = 0
        Public CollegeID As Integer = 0
        Public ProjectID As Integer = 0
        Public UserID As Integer = 0

        Private db As PromptDataHelper
        Private rights As DataTable


        Public Sub New()
            db = New PromptDataHelper

            DistrictID = HttpContext.Current.Session("DistrictID")
            CollegeID = HttpContext.Current.Session("CollegeID")
            UserID = HttpContext.Current.Session("UserID")


        End Sub

#Region "Validation Functions"

 
        Public Function FindUserPermission(ByVal ObjectID As String, ByVal right As String) As Boolean

            'Looks in loaded class datable for specific rights

            Dim Ok As Boolean = False
            Dim sql As String = ""
            Dim ObjectType As String = ""

            Dim bHasProjectLevelPermissions As Boolean = False

            right = UCase(right)

            If HttpContext.Current.Session("UserRole") = "TechSupport" Then         'always ok for tech support and go right back
                Return True
            End If

            sql = "SELECT SecurityPermissions.*, SecurityPermissionsRights.ScopeLevel  FROM SecurityPermissions INNER JOIN "
            sql &= "SecurityPermissionsRights ON SecurityPermissions.ObjectID = SecurityPermissionsRights.ObjectID "
            sql &= "WHERE UserID = " & UserID & " AND  DistrictID = " & DistrictID

            If IsNothing(db.DataTable) Then             'First time in it should load the table
                db.DataTable = db.ExecuteDataTable(sql)
            ElseIf db.DataTable.Rows.Count = 0 Then
                db.DataTable = db.ExecuteDataTable(sql)
            End If

            'Check if there are project level permissons for passed project
            If ProjectID > 0 Then
                For Each row As DataRow In db.DataTable.Rows
                    If row("ProjectID") = ProjectID Then
                        bHasProjectLevelPermissions = True
                        Exit For
                    End If
                Next
            End If

            If db.DataTable.Rows.Count > 0 Then
                For Each rowRight As DataRow In db.DataTable.Rows
                    If rowRight("ObjectID") = ObjectID Then
                        ObjectType = rowRight("ObjectType")

                        'If CollegeID = 0 And ProjectID = 0 Then    'this is a district level object
                        If rowRight("ScopeLevel") = "District" Then
                            If right = "READ" Then
                                If rowRight("Permissions") = "ReadOnly" Or rowRight("Permissions") = "Write" Then
                                    Ok = True
                                    Exit For
                                End If
                            End If
                            If right = "WRITE" Then
                                If rowRight("Permissions") = "Write" Then
                                    Ok = True
                                    Exit For
                                End If
                            End If
                            'End If

                        End If

                        If CollegeID > 0 And ProjectID = 0 Then    'this is a college level object
                            If rowRight("CollegeID") = CollegeID Then
                                If right = "READ" Then
                                    If rowRight("Permissions") = "ReadOnly" Or rowRight("Permissions") = "Write" Then
                                        Ok = True
                                        Exit For
                                    End If
                                End If
                                If right = "WRITE" Then
                                    If rowRight("Permissions") = "Write" Then
                                        Ok = True
                                        Exit For
                                    End If
                                End If
                            End If

                        End If

                        If ProjectID > 0 And bHasProjectLevelPermissions Then    'this is a project level object so use project level permissions
                            If rowRight("ProjectID") = ProjectID Then
                                If right = "READ" Then
                                    If rowRight("Permissions") = "ReadOnly" Or rowRight("Permissions") = "Write" Then
                                        Ok = True
                                        Exit For
                                    End If
                                End If
                                If right = "WRITE" Then
                                    If rowRight("Permissions") = "Write" Then
                                        Ok = True
                                        Exit For
                                    End If
                                End If
                            End If
                        End If
                    End If
                Next

                If ProjectID > 0 And bHasProjectLevelPermissions = False Then        'this was project level permission that was not found.
                    For Each rowRight As DataRow In db.DataTable.Rows
                        If rowRight("ObjectID") = ObjectID And rowRight("CollegeID") = CollegeID Then
                            If right = "READ" Then
                                If rowRight("Permissions") = "ReadOnly" Or rowRight("Permissions") = "Write" Then
                                    Ok = True
                                    Exit For
                                End If
                            End If
                            If right = "WRITE" Then
                                If rowRight("Permissions") = "Write" Then
                                    Ok = True
                                    Exit For
                                End If
                            End If
                        End If
                    Next
                End If

            End If

            Return Ok

        End Function

        Public Function SpecifyProjectRights(ByVal nCollegeID As Integer) As Boolean
            Dim sql As String = "SELECT * FROM SecurityPermissions WHERE UserID = " & UserID & " AND CollegeID = " & nCollegeID & " "
            sql &= "AND ObjectID ='SpecifyProjectAccess' "
            Dim tbl As DataTable = db.ExecuteDataTable(sql)
            If tbl.Rows.Count > 0 Then
                If tbl.Rows(0)("Permissions") = "Yes" Then
                    Return True
                End If
            End If
           
            Return False

        End Function

        Public Function GetAssignedProjectIDList(ByVal nCollegeID As Integer) As DataTable

            Dim sql As String = "SELECT ObjectID,ProjectID FROM SecurityPermissions WHERE CollegeID = " & nCollegeID & " AND UserID = " & UserID & " "
            sql &= "AND (ObjectID ='ProjectOverview' OR ObjectID ='ContractOverview') AND (Permissions = 'ReadOnly' OR Permissions = 'Write')"
            Return db.ExecuteDataTable(sql)


        End Function
        


        Public Function GetCollegeName(ByVal collegeid) As String
            Return db.ExecuteScalar("SELECT College FROM Colleges WHERE CollegeID = " & collegeid)

        End Function

        Public Function GetDistrictCollegeProjectName(ByVal collegeid As Integer, ByVal projectid As Integer) As String
            Dim sql As String = ""
            If projectid = 0 Then
                sql = "SELECT Districts.Name + ' : ' + Colleges.College AS Name FROM Colleges INNER JOIN Districts ON Colleges.DistrictID = Districts.DistrictID WHERE CollegeID = " & collegeid
            Else
                sql = "SELECT Districts.Name + ' : ' + Colleges.College + ' : ' + Projects.ProjectName AS Name FROM Colleges INNER JOIN Districts ON Colleges.DistrictID = Districts.DistrictID "
                sql &= "INNER JOIN Projects ON Projects.CollegeID = Colleges.CollegeID WHERE colleges.collegeid = " & collegeid & " AND projects.ProjectID = " & projectid
            End If

            Return db.ExecuteScalar(sql)

        End Function

        Public Function GetLedgerName(ByVal ledgerid) As String
            Return db.ExecuteScalar("SELECT LedgerName FROM LedgerAccounts WHERE LedgerAccountID = " & ledgerid)

        End Function

        Public Function GetProjectGroupName(ByVal ProjectGroupID) As String
            Return db.ExecuteScalar("SELECT Name FROM ProjectGroups WHERE ProjectGroupID = " & ProjectGroupID)

        End Function
        Public Function GetProjectName(ByVal ProjectID) As String
            Dim var As String = ""
            Dim sql As String = "SELECT CollegeID,ProjectName FROM Projects WHERE ProjectID = " & ProjectID

            db.FillReader(sql)
            If db.reader.hasrows Then
                While db.reader.read
                    var = ProcLib.CheckNullDBField(db.Reader("ProjectName"))
                    HttpContext.Current.Session("CollegeID") = db.reader("CollegeID")
                End While
            End If
            db.reader.close()

            Return var

        End Function

        Public Function GetContractName(ByVal ContractID) As String
            Dim sql As String = "SELECT Contacts.Name AS Name, Contracts.Description AS Description FROM Contracts INNER JOIN "
            sql &= "Contacts ON Contracts.ContractorID = Contacts.ContactID  WHERE Contracts.ContractID = " & ContractID
            Dim tbl As DataTable = db.ExecuteDataTable(sql)
            Dim sContractor As String = ProcLib.CheckNullDBField(tbl.Rows(0)("Name"))
            Dim sDescription As String = ProcLib.CheckNullDBField(tbl.Rows(0)("Description"))

            Return sContractor & "- (" & sDescription & ")"

        End Function

        Public Function GetDistrictObjectVisibilitySettings(ByVal Category As String) As DataTable
            'Gets the show/hide tab settings for the District 
            'NOTE: System default has district ID = 0

            Dim tblSystem As DataTable
            Dim tblDistrict As DataTable

            Dim sql As String = ""

            sql = "SELECT * FROM SecurityPermissions INNER JOIN "
            sql &= "SecurityPermissionsRights ON SecurityPermissions.ObjectID = SecurityPermissionsRights.ObjectID "
            sql &= "WHERE Category = '" & Category & "' AND DistrictID = 0 AND UserID=0 AND RoleID=0 AND CollegeID=0 ORDER BY DisplayOrder"
            tblSystem = db.ExecuteDataTable(sql)

            sql = "SELECT * FROM SecurityPermissions INNER JOIN "
            sql &= "SecurityPermissionsRights ON SecurityPermissions.ObjectID = SecurityPermissionsRights.ObjectID "
            sql &= "WHERE Category = '" & Category & "' AND DistrictID = " & DistrictID & " AND UserID=0 AND RoleID=0 AND CollegeID=0 ORDER BY DisplayOrder"
            tblDistrict = db.ExecuteDataTable(sql)

            'Now check if there are district items and if so, turn any off if system equivalent is turned off
            If tblDistrict.Rows.Count > 0 Then
                For Each rowSys As DataRow In tblSystem.Rows
                    For Each rowDist As DataRow In tblDistrict.Rows
                        If rowSys("ObjectID") = rowDist("ObjectID") Then
                            If ProcLib.CheckNullNumField(rowSys("Visibility")) = 0 And ProcLib.CheckNullNumField(rowDist("Visibility")) = 1 Then   'system trumps so turn off district
                                rowDist("Visibility") = 0
                            End If
                        End If
                    Next
                Next
                Return tblDistrict
            Else
                Return tblSystem

            End If

        End Function

        Public Function GetAdminSystemSettings(ByVal ObjectType As String, ByVal districtid As Integer) As DataTable
            'Gets the settings for a specified entity for a district or creates system default if not there
            'NOTE: System default has district ID = 0
            Dim tbl As DataTable
            Dim sql As String = ""

            sql = "SELECT *, SecurityPermissionsRights.Description,SecurityPermissionsRights.ScopeLevel,SecurityPermissionsRights.Category FROM SecurityPermissions INNER JOIN "
            sql &= "SecurityPermissionsRights ON SecurityPermissions.ObjectID = SecurityPermissionsRights.ObjectID "
            sql &= "WHERE SecurityPermissions.ObjectType = '" & ObjectType & "'  AND DistrictID = " & districtid & " AND CollegeID=0 AND RoleID=0 AND UserID=0 ORDER BY DisplayOrder"
            tbl = db.ExecuteDataTable(sql)


            If tbl.Rows.Count = 0 And districtid > 0 Then           'If this is a district setting and has not been initialized so copy system defaults

                sql = "SELECT * FROM SecurityPermissions WHERE ObjectType = '" & ObjectType & "'  AND UserID=0 AND RoleID=0 AND CollegeID=0 AND DistrictID = 0 ORDER BY DisplayOrder"
                Dim tblMaster = db.ExecuteDataTable(sql)
                db.FillDataTableForUpdate("SELECT * FROM SecurityPermissions WHERE SecurityPermissionID = 0 ")         'open updatable table
                For Each rowSource As DataRow In tblMaster.Rows
                    Dim newdistrictrow As DataRow = db.DataTable.NewRow
                    For Each col As DataColumn In tblMaster.Columns
                        If col.ColumnName <> "SecurityPermissionID" Then
                            newdistrictrow(col.ColumnName) = rowSource(col.ColumnName)
                        End If
                    Next
                    newdistrictrow("DistrictID") = districtid
                    newdistrictrow("LastUpdateBy") = HttpContext.Current.Session("UserName")
                    newdistrictrow("LastUpdateOn") = Now()
                    db.DataTable.Rows.Add(newdistrictrow)

                Next
                db.SaveDataTableToDB()


            Else   'this district or system default has records so check for new entries and add if needed

                'Get the master list and see if setting is there -- if not add it
                sql = "SELECT * FROM SecurityPermissionsRights WHERE ObjectType = '" & ObjectType & "' "
                Dim tblsource As DataTable = db.ExecuteDataTable(sql)

                For Each rowMaster As DataRow In tblsource.Rows
                    Dim bExists As Boolean = False
                    For Each rowSetting As DataRow In tbl.Rows
                        If rowSetting("ObjectID") = rowMaster("ObjectID") Then
                            bExists = True
                        End If
                    Next

                    If Not bExists Then         'there are no settings for this combination of parameters, so create from master list 

                        db.FillDataTableForUpdate("SELECT * FROM SecurityPermissions WHERE SecurityPermissionID = 0 ")         'open updatable table
                        Dim newrow As DataRow = db.DataTable.NewRow

                        newrow("ObjectType") = rowMaster("ObjectType")
                        newrow("ObjectID") = rowMaster("ObjectID")

                        newrow("DistrictID") = districtid
                        newrow("ProjectID") = 0
                        newrow("CollegeID") = 0
                        newrow("UserID") = 0
                        newrow("RoleID") = 0
                        newrow("Permissions") = ""

                        newrow("LastUpdateBy") = HttpContext.Current.Session("UserName")
                        newrow("LastUpdateOn") = Now()
                        db.DataTable.Rows.Add(newrow)
                        db.SaveDataTableToDB()
                    End If
                Next

            End If

            'now get whole mess again
            sql = "SELECT *, SecurityPermissionsRights.Description,SecurityPermissionsRights.ScopeLevel,SecurityPermissionsRights.Category FROM SecurityPermissions INNER JOIN "
            sql &= "SecurityPermissionsRights ON SecurityPermissions.ObjectID = SecurityPermissionsRights.ObjectID "
            sql &= "WHERE SecurityPermissions.ObjectType = '" & ObjectType & "'  AND UserID=0 AND RoleID=0 AND CollegeID=0 AND DistrictID = " & districtid & " ORDER BY DisplayOrder"
            tbl = db.ExecuteDataTable(sql)


            Return tbl

        End Function

        Public Sub SaveAdminSystemSetting(ByVal nKey As Integer, ByVal DisplayOrder As Integer, ByVal Visibility As Integer)


            Dim sql As String = "UPDATE SecurityPermissions SET Visibility = '" & Visibility & "',DisplayOrder =" & DisplayOrder & " "
            sql &= "WHERE SecurityPermissionID = " & nKey

            db.ExecuteNonQuery(sql)

        End Sub


        'Public Shared Function GetSecurityLevel(ByVal ObjectType As String, ByVal right As String) As Boolean

        '    'TEMP TEMP TEMP TEMP TEMP FOR Ver 4.x

        '    'looks for an entry in security permissions at the district level

        '    Dim Ok As Boolean = True
        '    'Dim sql As String = ""

        '    'If HttpContext.Current.Session("UserRole") = "TechSupport" Then
        '    '    Return True
        '    'End If

        '    'sql = "SELECT * FROM SecurityPermissions WHERE ObjectType = '" & ObjectType & "' AND "
        '    'sql &= "UserID = " & HttpContext.Current.Session("UserID")


        '    'If rights Is Nothing Then    'need to fill rights table first call
        '    '    Dim sql As String = "SELECT * FROM SecurityPermissions WHERE UserID = " & HttpContext.Current.Session("UserID") & " AND "
        '    '    sql &= "CollegeID = " & CollegeID & " AND (ProjectID = " & ProjectID & " OR ProjectID = -100)"
        '    '    rights = db.ExecuteDataTable(sql)
        '    'End If

        '    ''Look up passed object
        '    'For Each row As DataRow In rights.Rows
        '    '    If row("ObjectType") = ObjectType And row("Permissions") = Right() Then
        '    '        Ok = True
        '    '    End If
        '    'Next

        '    Return Ok

        'End Function


        Public Function IsPromptDistrictAdmin() As Boolean

            'Return False

            'If HttpContext.Current.Session("DistrictID") = "" Then HttpContext.Current.Session("DistrictID") = "0"

            'Looks to see if this person has Contract Edit rights in prompt and if so enables edit of colleges and lists in nav bar
            Dim Ok As Boolean = False
            Dim sql As String = "SELECT Count(SecurityPermissionID) FROM SecurityPermissions WHERE UserID = " & HttpContext.Current.Session("UserID") & " AND "
            sql &= "DistrictID = " & HttpContext.Current.Session("DistrictID") & " AND ObjectType = 'ContractInfo' AND ReadWrite = 1"

            Dim result As Integer = db.ExecuteScalar(sql)
            If result > 0 Then
                Ok = True
            End If
            Return Ok

        End Function

#End Region

#Region "Users"

        Public Function GetUserCollegeList() As String
            Dim sql As String = "SELECT DISTINCT CollegeID FROM SecurityPermissions WHERE UserID = " & HttpContext.Current.Session("UserID")
            Dim tbl As DataTable = db.ExecuteDataTable(sql)
            Dim sList As String = ""
            For Each row As DataRow In tbl.Rows
                sList &= ";" & row("CollegeID") & ";"
            Next
            Return sList
        End Function

        Public Function GetUserCollegeAccessList(ByVal userid As Integer, ByVal ShowAll As Boolean) As DataTable

            Dim sql As String = ""

            'build a list of all projects with college and district ids - NOTE:including projects for future rights expansion
            sql = "SELECT Districts.Name AS District, Colleges.College, Projects.ProjectName AS Project, Colleges.DistrictID, "
            sql &= "Colleges.CollegeID, Projects.ProjectID, "
            sql &= "(SELECT Count(SecurityPermissionID) FROM SecurityPermissions WHERE SecurityPermissions.CollegeID = Colleges.CollegeID AND UserID = " & userid & ") AS Permissions, "
            sql &= "(SELECT Count(SecurityPermissionID) FROM SecurityPermissions WHERE SecurityPermissions.CollegeID = Colleges.CollegeID AND UserID = " & userid & " "
            sql &= " AND ObjectID ='SpecifyProjectAccess') AS ProjectPermissions "
            sql &= "FROM Colleges INNER JOIN Districts ON Colleges.DistrictID = Districts.DistrictID INNER JOIN "
            sql &= " Projects ON Colleges.CollegeID = Projects.CollegeID "
            sql &= "ORDER BY District, Colleges.College, Projects.ProjectName "

            Dim tblSource As DataTable = db.ExecuteDataTable(sql)
            Dim tbl As DataTable = tblSource.Clone
            Dim sLastCollege As String = ""
            For Each row As DataRow In tblSource.Rows
                If sLastCollege <> row("College") Then   'filtering at change of college level for now
                    sLastCollege = row("College")
                    Dim newlastrow As DataRow = tbl.NewRow
                    newlastrow.ItemArray = row.ItemArray
                    If ShowAll = False Then
                        If row("Permissions") > 0 Then
                            tbl.Rows.Add(newlastrow)
                        End If
                    Else
                        tbl.Rows.Add(newlastrow)
                    End If


                End If
            Next

            Return tbl

        End Function

        Public Function GetUserProjectAccessList(ByVal collegeid As Integer, ByVal userid As Integer) As DataTable
            'build a list of all projects with for college  for given user
            Dim sql As String = ""
            sql = "SELECT Projects.ProjectName,Projects.ProjectNumber,Projects.Status, Projects.DistrictID,Projects.CollegeID, Projects.ProjectID, "
            sql &= "(SELECT Count(SecurityPermissionID) FROM SecurityPermissions WHERE SecurityPermissions.ProjectID = Projects.ProjectID AND UserID = " & userid & ") AS Permissions "
            sql &= "FROM Projects WHERE Projects.CollegeID = " & collegeid & " ORDER BY ProjectName "

            Return db.ExecuteDataTable(sql)

        End Function

        Public Function GetUserPermissionsForEdit(ByVal userid As Integer, ByVal ndistrictid As Integer, ByVal collegeid As Integer, ByVal projectid As Integer) As DataTable

            'get the full available rights list
            Dim sql As String = "SELECT * FROM SecurityPermissionsRights ORDER By Description"
            Dim tblRightsMasterList As DataTable = db.ExecuteDataTable(sql)

            'get the district level permission settings for this particular user
            sql = "SELECT * FROM SecurityPermissions WHERE UserID = " & userid
            Dim tblUserExistingPermissions As DataTable = db.ExecuteDataTable(sql)

            'build a new table for results
            Dim tblNewPermissions As DataTable = tblUserExistingPermissions.Clone
            tblNewPermissions.Columns("SecurityPermissionID").ReadOnly = False    'to fix error on PK

            Dim col As New DataColumn
            col.DataType = Type.GetType("System.String")
            col.ColumnName = "Description"
            tblNewPermissions.Columns.Add(col)

            col = New DataColumn
            col.DataType = Type.GetType("System.String")
            col.ColumnName = "Category"
            tblNewPermissions.Columns.Add(col)

            col = New DataColumn
            col.DataType = Type.GetType("System.String")
            col.ColumnName = "ScopeLevel"
            tblNewPermissions.Columns.Add(col)


            'Now go through each avaialble right and assign value for this role if permission exists
            Dim sObjectType As String = ""
            Dim sObjectID As String = ""
            Dim sCategory As String = ""
            Dim sScopeLevel As String = ""
            For Each rowMaster As DataRow In tblRightsMasterList.Rows
                Dim newrow As DataRow = tblNewPermissions.NewRow
                newrow("Description") = rowMaster("Description")
                sObjectType = rowMaster("ObjectType")
                sCategory = rowMaster("Category")
                sObjectID = rowMaster("ObjectID")
                sScopeLevel = rowMaster("ScopeLevel")
                Dim bFound As Boolean = False

                If projectid = 0 Then           'these are district/college level rights
                    If sScopeLevel = "District" Then
                        For Each rowPermission As DataRow In tblUserExistingPermissions.Rows
                            If rowPermission("ObjectID") = sObjectID And rowPermission("DistrictID") = ndistrictid Then           'permission for this object has been previously assigned so exit
                                bFound = True
                                newrow.ItemArray = rowPermission.ItemArray
                                newrow("Category") = sCategory
                                newrow("ScopeLevel") = sScopeLevel
                                tblNewPermissions.Rows.Add(newrow)
                            End If
                        Next
                        If Not bFound Then    'add object to list for this role
                            newrow("ObjectType") = sObjectType
                            newrow("ObjectID") = sObjectID
                            newrow("RoleID") = 0
                            newrow("UserID") = userid
                            newrow("CollegeID") = collegeid
                            newrow("ProjectID") = 0
                            newrow("DistrictID") = ndistrictid
                            newrow("Category") = sCategory
                            newrow("ScopeLevel") = sScopeLevel
                            newrow("Permissions") = ""

                            tblNewPermissions.Rows.Add(newrow)

                        End If

                    Else

                        For Each rowPermission As DataRow In tblUserExistingPermissions.Rows
                            If rowPermission("ObjectID") = sObjectID And rowPermission("DistrictID") = ndistrictid And rowPermission("CollegeID") = collegeid And rowPermission("ProjectID") = 0 Then           'permission for this object has been previously assigned so exit
                                bFound = True
                                newrow.ItemArray = rowPermission.ItemArray
                                newrow("Category") = sCategory
                                newrow("ScopeLevel") = sScopeLevel
                                tblNewPermissions.Rows.Add(newrow)
                            End If
                        Next
                        If Not bFound Then    'add object to list for this role
                            newrow("ObjectType") = sObjectType
                            newrow("ObjectID") = sObjectID
                            newrow("RoleID") = 0
                            newrow("UserID") = userid
                            newrow("CollegeID") = collegeid
                            newrow("ProjectID") = 0
                            newrow("DistrictID") = ndistrictid
                            newrow("Permissions") = ""

                            newrow("Category") = sCategory
                            newrow("ScopeLevel") = sScopeLevel

                            tblNewPermissions.Rows.Add(newrow)

                        End If
                    End If

                Else            'this is for prject level permissions

                    If sScopeLevel = "Project" Then
                        For Each rowPermission As DataRow In tblUserExistingPermissions.Rows
                            If rowPermission("ObjectID") = sObjectID And rowPermission("ProjectID") = projectid Then           'permission for this object has been previously assigned so exit
                                bFound = True
                                newrow.ItemArray = rowPermission.ItemArray
                                newrow("Category") = sCategory
                                newrow("ScopeLevel") = sScopeLevel
                                tblNewPermissions.Rows.Add(newrow)
                            End If
                        Next
                        If Not bFound Then    'add object to list for this role
                            newrow("ObjectType") = sObjectType
                            newrow("ObjectID") = sObjectID
                            newrow("RoleID") = 0
                            newrow("UserID") = userid
                            newrow("CollegeID") = collegeid
                            newrow("ProjectID") = projectid
                            newrow("DistrictID") = ndistrictid
                            newrow("Category") = sCategory
                            newrow("ScopeLevel") = sScopeLevel
                            newrow("Permissions") = ""

                            tblNewPermissions.Rows.Add(newrow)

                        End If
                    End If
                End If

            Next

            Return tblNewPermissions

        End Function

  
        Public Sub SaveUserPermissions(ByVal grid As RadGrid, ByVal ndistrictid As Integer, ByVal collegeid As Integer, ByVal userID As Integer, Optional ByVal nprojectid As Integer = 0)

            Dim sql As String = ""
            'Delete existing College Level permissions
            ProjectID = nprojectid

            If ProjectID = 0 Then
                sql = "DELETE FROM SecurityPermissions WHERE UserID = " & userID & " AND "
                sql &= "DistrictID = " & ndistrictid & " AND CollegeID = " & collegeid & " AND ProjectID=0"
                db.ExecuteNonQuery(sql)

                'Delete existing DistrictLevel permissions
                sql = "DELETE FROM SecurityPermissions WHERE UserID = " & userID & " AND "
                sql &= "DistrictID = " & ndistrictid & " AND CollegeID = 0"
                db.ExecuteNonQuery(sql)

            Else   'project level permissions
                sql = "DELETE FROM SecurityPermissions WHERE UserID = " & userID & " AND ProjectID = " & ProjectID
                db.ExecuteNonQuery(sql)
            End If


            'Now add new permissions if any
            db.FillDataTableForUpdate("SELECT * FROM SecurityPermissions WHERE SecurityPermissionID=0 ")
            Dim tblTarget As DataTable = db.DataTable

            Dim bRemoveSpecifyProject As Boolean = False   'we need to check if we are turning on project level or not for a college - if turning off need to remove existing

            For Each item As GridItem In grid.MasterTableView.Items
                If TypeOf item Is GridDataItem Then

                    Dim lstRights As DropDownList = item.FindControl("lstRights")
                    Dim sObjectType As String = item.OwnerTableView.DataKeyValues(item.ItemIndex)("ObjectType")
                    Dim sObjectID As String = item.OwnerTableView.DataKeyValues(item.ItemIndex)("ObjectID")
                    Dim sScopeLevel As String = item.OwnerTableView.DataKeyValues(item.ItemIndex)("ScopeLevel")

                    Dim newrow As DataRow = tblTarget.NewRow
                    newrow("UserID") = userID
                    newrow("RoleID") = 0
                    newrow("DistrictID") = ndistrictid
                    If sScopeLevel = "District" Then
                        newrow("CollegeID") = 0
                    Else
                        newrow("CollegeID") = collegeid
                    End If
                    newrow("ProjectID") = ProjectID
                    newrow("ObjectType") = sObjectType
                    newrow("ObjectID") = sObjectID

                    newrow("Permissions") = lstRights.SelectedValue

                    newrow("LastUpdateOn") = Now()
                    newrow("LastUpdateBy") = HttpContext.Current.Session("UserName")

                    If newrow("Permissions") <> "none" And newrow("Permissions") <> "No" Then     'only add those assigned
                        db.DataTable.Rows.Add(newrow)
                    End If

                    If ProjectID = 0 Then   'we are setting college level settings
                        If sObjectID = "SpecifyProjectAccess" Then
                            If lstRights.SelectedValue = "No" Then   'remove any existing settings
                                bRemoveSpecifyProject = True
                            End If
                        End If
                    End If

                End If
            Next
            db.SaveDataTableToDB()

            If bRemoveSpecifyProject = True Then   'we are setting college level settings
                sql = "DELETE FROM SecurityPermissions WHERE UserID = " & userID & " AND "
                sql &= "DistrictID = " & ndistrictid & " AND CollegeID = " & collegeid & " AND ProjectID > 0"
                db.ExecuteNonQuery(sql)
            End If

        End Sub

        Public Sub ResetUserToRolePermissions(ByVal userID As Integer, ByVal ndistrictid As Integer, ByVal collegeid As Integer)

            Dim sql As String = ""
            'Delete existing College Level permissions
            sql = "DELETE FROM SecurityPermissions WHERE UserID = " & userID & " AND "
            sql &= "DistrictID = " & ndistrictid & " AND CollegeID = " & collegeid
            db.ExecuteNonQuery(sql)

            'Delete existing DistrictLevel permissions
            sql = "DELETE FROM SecurityPermissions WHERE UserID = " & userID & " AND "
            sql &= "DistrictID = " & ndistrictid & " AND CollegeID = 0"
            db.ExecuteNonQuery(sql)


            Dim nRoleID As Integer = db.ExecuteScalar("SELECT UserRoleID FROM Users WHERE UserID = " & userID)

            'Now get role permissions
            sql = "SELECT *, SecurityPermissionsRights.ScopeLevel  FROM SecurityPermissions INNER JOIN "
            sql &= "SecurityPermissionsRights ON SecurityPermissions.ObjectID = SecurityPermissionsRights.ObjectID WHERE RoleID = " & nRoleID
            Dim tblRolePermissions As DataTable = db.ExecuteDataTable(sql)

            If tblRolePermissions.Rows.Count > 0 Then

                'Now add new permissions 
                db.FillDataTableForUpdate("SELECT * FROM SecurityPermissions WHERE SecurityPermissionID=0 ")
                Dim tblTarget As DataTable = db.DataTable

                For Each rowSource As DataRow In tblRolePermissions.Rows
                    Dim newrow As DataRow = tblTarget.NewRow
                    newrow("UserID") = userID
                    newrow("RoleID") = 0
                    newrow("DistrictID") = ndistrictid
                    If rowSource("ScopeLevel") = "District" Then
                        newrow("CollegeID") = 0
                    Else
                        newrow("CollegeID") = collegeid
                    End If
                    newrow("ProjectID") = 0
                    newrow("ObjectType") = rowSource("ObjectType")
                    newrow("ObjectID") = rowSource("ObjectID")

                    newrow("Permissions") = rowSource("Permissions")

                    newrow("LastUpdateOn") = Now()
                    newrow("LastUpdateBy") = HttpContext.Current.Session("UserName")

                    tblTarget.Rows.Add(newrow)
                Next
                db.SaveDataTableToDB()

            End If

        End Sub

        Public Sub ResetUserProjectToParentCollegePermissions(ByVal userID As Integer, ByVal ndistrictid As Integer, ByVal collegeid As Integer, ByVal nprojectid As Integer)

            Dim sql As String = ""
            'Delete existing Project Level permissions
            sql = "DELETE FROM SecurityPermissions WHERE UserID = " & userID & " AND "
            sql &= "ProjectID = " & nprojectid
            db.ExecuteNonQuery(sql)

            'Now get college permissions
            sql = "SELECT *, SecurityPermissionsRights.ScopeLevel  FROM SecurityPermissions INNER JOIN "
            sql &= "SecurityPermissionsRights ON SecurityPermissions.ObjectID = SecurityPermissionsRights.ObjectID WHERE CollegeID = " & collegeid & " "
            sql &= "AND UserID = " & userID
            Dim tblRolePermissions As DataTable = db.ExecuteDataTable(sql)

            If tblRolePermissions.Rows.Count > 0 Then

                'Now add new permissions 
                db.FillDataTableForUpdate("SELECT * FROM SecurityPermissions WHERE SecurityPermissionID=0 ")
                Dim tblTarget As DataTable = db.DataTable

                For Each rowSource As DataRow In tblRolePermissions.Rows
                    Dim newrow As DataRow = tblTarget.NewRow
                    newrow("UserID") = userID
                    newrow("RoleID") = 0
                    newrow("DistrictID") = ndistrictid
                    newrow("CollegeID") = collegeid

                    newrow("ProjectID") = nprojectid
                    newrow("ObjectType") = rowSource("ObjectType")
                    newrow("ObjectID") = rowSource("ObjectID")

                    newrow("Permissions") = rowSource("Permissions")

                    newrow("LastUpdateOn") = Now()
                    newrow("LastUpdateBy") = HttpContext.Current.Session("UserName")

                    tblTarget.Rows.Add(newrow)
                Next
                db.SaveDataTableToDB()

            End If

        End Sub

        Public Sub ResetAllUserRolePermissions(ByVal roleID As Integer)

            'Resets all users with this role ID to role permissions

            Dim sql As String = ""

            sql = "SELECT SecurityPermissions.SecurityPermissionID, SecurityPermissions.UserID, SecurityPermissions.RoleID, SecurityPermissions.DistrictID, "
            sql &= "SecurityPermissions.CollegeID, SecurityPermissions.ProjectID, SecurityPermissions.ObjectID, SecurityPermissions.ObjectType,  "
            sql &= "SecurityPermissions.LastUpdateOn, SecurityPermissions.LastUpdateBy, SecurityPermissions.Permissions, "
            sql &= "SecurityPermissions.DisplayOrder, SecurityPermissions.Visibility, SecurityPermissionsRights.ScopeLevel "
            sql &= "FROM SecurityPermissions INNER JOIN SecurityPermissionsRights ON SecurityPermissions.ObjectID = SecurityPermissionsRights.ObjectID "
            sql &= "WHERE RoleID = " & roleID
            Dim tblRolePermissions As DataTable = db.ExecuteDataTable(sql)

            Dim tblUsers As DataTable = db.ExecuteDataTable("SELECT * FROM Users WHERE UserRoleID = " & roleID)

            For Each userrow As DataRow In tblUsers.Rows
                Dim userID As Integer = userrow("UserID")
                'Get current district/college accesses
                Dim tblCurrentUserDistrictPermissions As DataTable = db.ExecuteDataTable("SELECT DISTINCT DistrictID, CollegeID FROM SecurityPermissions WHERE UserID = " & userID & " ORDER BY DistrictID")

                'Remove existing records
                sql = "DELETE FROM SecurityPermissions WHERE UserID = " & userID
                db.ExecuteNonQuery(sql)

                If tblRolePermissions.Rows.Count > 0 Then       'there are permissions so add to allowed district/colleges
                    db.FillDataTableForUpdate("SELECT * FROM SecurityPermissions WHERE SecurityPermissionID=0 ")
                    Dim tblTarget As DataTable = db.DataTable

                    Dim nLastDistrict As Integer = 0
                    For Each rowCollegeDistrict As DataRow In tblCurrentUserDistrictPermissions.Rows    'add premissions back for each district college combo
                        Dim ndistrictid As Integer = rowCollegeDistrict("DistrictID")
                        Dim collegeid As Integer = rowCollegeDistrict("CollegeID")

                        If nLastDistrict <> DistrictID Then     'add any district scope level permissions only once as they do not make sense on the college level
                            nLastDistrict = DistrictID
                            For Each rowSource As DataRow In tblRolePermissions.Rows
                                If rowSource("ScopeLevel") = "District" Then
                                    Dim newrow As DataRow = tblTarget.NewRow
                                    newrow("UserID") = userID
                                    newrow("RoleID") = 0
                                    newrow("DistrictID") = ndistrictid
                                    newrow("CollegeID") = 0
                                    newrow("ProjectID") = 0
                                    newrow("ObjectType") = rowSource("ObjectType")
                                    newrow("ObjectID") = rowSource("ObjectID")

                                    newrow("Permissions") = rowSource("Permissions")

                                    newrow("LastUpdateOn") = Now()
                                    newrow("LastUpdateBy") = HttpContext.Current.Session("UserName")

                                    tblTarget.Rows.Add(newrow)
                                End If
                            Next


                        End If

                        'Now add all college level
                        For Each rowSource As DataRow In tblRolePermissions.Rows
                            If rowSource("ScopeLevel") = "College" Or rowSource("ScopeLevel") = "Project" Then
                                Dim newrow As DataRow = tblTarget.NewRow
                                newrow("UserID") = userID
                                newrow("RoleID") = 0
                                newrow("DistrictID") = ndistrictid
                                newrow("CollegeID") = collegeid
                                newrow("ProjectID") = 0
                                newrow("ObjectType") = rowSource("ObjectType")
                                newrow("ObjectID") = rowSource("ObjectID")

                                newrow("Permissions") = rowSource("Permissions")

                                newrow("LastUpdateOn") = Now()
                                newrow("LastUpdateBy") = HttpContext.Current.Session("UserName")

                                tblTarget.Rows.Add(newrow)
                            End If
                        Next
                        db.SaveDataTableToDB()
                    Next
                End If
            Next

        End Sub

        'Public Sub SaveUserDistrictCollegeProjectAccessPermissions(ByVal gridPermissions As RadGrid, ByVal UserID As Integer)

        '    Dim tblSec As DataTable = db.ExecuteDataTable("SELECT * FROM SecurityPermissions WHERE UserID = " & UserID)

        '    db.FillDataTableForUpdate("SELECT * FROM SecurityPermissions ")
        '    Dim tblTarget As DataTable = db.DataTable

        '    'loop through the grid to see if something access for college/project has been added or revoked - we do not want to remove existing permissions
        '    'Update Permissions 

        '    For Each item As GridItem In gridPermissions.MasterTableView.Items
        '        If TypeOf item Is GridDataItem Then

        '            Dim chkPermissions As CheckBox = item.FindControl("Permissions")
        '            Dim nDistrictID As Integer = chkPermissions.Attributes("DistrictID")
        '            Dim nCollegeID As Integer = chkPermissions.Attributes("CollegeID")
        '            Dim nProjectID As Integer = chkPermissions.Attributes("ProjectID")
        '            Dim nSecurityPermissionID As Integer = chkPermissions.Attributes("SecurityPermissionID")
        '            Dim sObjectType As String = chkPermissions.Attributes("ObjectType")
        '            Dim bPermissionFound As Boolean = False

        '            If chkPermissions.Checked Then    'see if right exist and if so ignore

        '                'Look if there are existing permissions 
        '                For Each row As DataRow In tblSec.Rows
        '                    If sObjectType = row("ObjectType") And nSecurityPermissionID = row("SecurityPermissionID") Then
        '                        bPermissionFound = True
        '                        Exit For
        '                    End If
        '                Next
        '                If Not bPermissionFound Then    'if not create default read Permissions

        '                    Dim newrow As DataRow = tblTarget.NewRow
        '                    newrow("UserID") = UserID
        '                    newrow("DistrictID") = nDistrictID
        '                    newrow("CollegeID") = nCollegeID
        '                    newrow("ProjectID") = -100
        '                    newrow("ObjectType") = "AllCollegeProjects"
        '                    newrow("Permissions") = "Read"
        '                    newrow("LastUpdateOn") = Now()
        '                    newrow("LastUpdateBy") = "SysUpgrade"
        '                    tblTarget.Rows.Add(newrow)

        '                    newrow = tblTarget.NewRow
        '                    newrow("UserID") = UserID
        '                    newrow("DistrictID") = nDistrictID
        '                    newrow("CollegeID") = nCollegeID
        '                    newrow("ProjectID") = -100
        '                    newrow("ObjectType") = "PromptProjects"
        '                    newrow("Permissions") = "Read"
        '                    newrow("LastUpdateOn") = Now()
        '                    newrow("LastUpdateBy") = "SysUpgrade"
        '                    tblTarget.Rows.Add(newrow)

        '                    newrow = tblTarget.NewRow
        '                    newrow("UserID") = UserID
        '                    newrow("DistrictID") = nDistrictID
        '                    newrow("CollegeID") = nCollegeID
        '                    newrow("ProjectID") = -100
        '                    newrow("ObjectType") = "PromptContracts"
        '                    newrow("Permissions") = "Read"
        '                    newrow("LastUpdateOn") = Now()
        '                    newrow("LastUpdateBy") = "SysUpgrade"
        '                    tblTarget.Rows.Add(newrow)

        '                    db.SaveDataTableToDB()

        '                    bPermissionFound = False
        '                End If

        '            Else                        'Remove any rights for this item if previously there
        '                If sObjectType = "AllCollegeProjects" Then
        '                    Dim sql As String = "DELETE FROM SecurityPermissions WHERE CollegeID = " & nCollegeID & " AND UserID = " & UserID
        '                    db.ExecuteNonQuery(sql)
        '                End If

        '            End If
        '        End If
        '    Next




        'End Sub



#End Region

#Region "Roles"

        Public Function GetRolePermissionsForEdit(ByVal roleid As Integer) As DataTable
            'NOTE: Initially, roles are not assigned to Districts/colleges or projects -- users are individually, so 
            'role permissions have zero for these vaules

            'get the full available rights list
            Dim sql As String = "SELECT * FROM SecurityPermissionsRights ORDER By Description"
            Dim tblRightsMasterList As DataTable = db.ExecuteDataTable(sql)

            'get the permission settings for this particular role
            sql = "SELECT * FROM SecurityPermissions WHERE RoleID = " & roleid
            Dim tblRolePermissions As DataTable = db.ExecuteDataTable(sql)
            Dim tblNewPermissions As DataTable = tblRolePermissions.Clone

            Dim col As New DataColumn
            col.DataType = Type.GetType("System.String")
            col.ColumnName = "Description"
            tblNewPermissions.Columns.Add(col)

            col = New DataColumn
            col.DataType = Type.GetType("System.String")
            col.ColumnName = "Category"
            tblNewPermissions.Columns.Add(col)


            'Now go through each avaialble right and assign value for this role if permission exists
            Dim sObjectType As String = ""
            Dim sObjectID As String = ""
            Dim sCategory As String = ""
            For Each rowMaster As DataRow In tblRightsMasterList.Rows
                If rowMaster("ObjectID") <> "SpecifyProjectAccess" Then
                    Dim newrow As DataRow = tblNewPermissions.NewRow
                    newrow("Description") = rowMaster("Description")
                    sObjectType = rowMaster("ObjectType")
                    sObjectID = rowMaster("ObjectID")
                    sCategory = rowMaster("Category")
                    Dim bFound As Boolean = False
                    For Each rowPermission As DataRow In tblRolePermissions.Rows
                        If ProcLib.CheckNullDBField(rowPermission("ObjectID")) = sObjectID Then           'permission for this object has been previously assigned so exit
                            bFound = True
                            newrow.ItemArray = rowPermission.ItemArray
                            newrow("Category") = sCategory       'add here as this is not in the permissions table 
                            tblNewPermissions.Rows.Add(newrow)
                        End If
                    Next

                    If Not bFound Then    'add object to list for this role

                        If sObjectID <> "DefaultProjectAccess" Then
                            newrow("ObjectType") = sObjectType
                            newrow("ObjectID") = sObjectID
                            newrow("RoleID") = roleid
                            newrow("UserID") = 0
                            newrow("CollegeID") = 0
                            newrow("ProjectID") = 0
                            newrow("DistrictID") = 0
                            newrow("Category") = sCategory
                            newrow("Permissions") = ""
                            tblNewPermissions.Rows.Add(newrow)
                        End If
                    End If
                End If

            Next

            Return tblNewPermissions

        End Function

        Public Sub SaveRolePermissions(ByVal grid As RadGrid, ByVal roleID As Integer)

            Dim sql As String = ""

            'Delete existing permissions
            sql = "DELETE FROM SecurityPermissions WHERE RoleID = " & roleID
            db.ExecuteNonQuery(sql)

            'Now add new permissions if any
            db.FillDataTableForUpdate("SELECT * FROM SecurityPermissions WHERE SecurityPermissionID = 0 ")
            Dim tblTarget As DataTable = db.DataTable

            For Each item As GridItem In grid.MasterTableView.Items
                If TypeOf item Is GridDataItem Then

                    Dim sObjectID As String = item.OwnerTableView.DataKeyValues(item.ItemIndex)("ObjectID")
                    Dim sObjectType As String = item.OwnerTableView.DataKeyValues(item.ItemIndex)("ObjectType")
                    Dim lstRights As DropDownList = item.FindControl("lstRights")


                    Dim newrow As DataRow = tblTarget.NewRow
                    newrow("RoleID") = roleID
                    newrow("ObjectType") = sObjectType
                    newrow("ObjectID") = sObjectID
                    newrow("DistrictID") = 0
                    newrow("CollegeID") = 0
                    newrow("ProjectID") = 0
                    newrow("UserID") = 0

                    newrow("Permissions") = lstRights.SelectedValue

                    newrow("LastUpdateOn") = Now()
                    newrow("LastUpdateBy") = HttpContext.Current.Session("UserName")


                    tblTarget.Rows.Add(newrow)
                End If
            Next
            db.SaveDataTableToDB()

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


