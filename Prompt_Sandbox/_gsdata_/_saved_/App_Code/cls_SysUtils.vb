Imports System
Imports System.Web
Imports System.Web.UI.WebControls
Imports System.IO
Imports System.Data
Imports System.Data.SqlClient
Imports Telerik.Web.UI

Namespace Prompt

    '********************************************
    '*  System Utilities Class
    '*  
    '*  Purpose: Processes System Utilities
    '*
    '*  Last Mod By:    Ford James
    '*  Last Mod On:    12/22/11
    '*
    '********************************************

    Public Class promptSysUtils
        Implements IDisposable

        'Properties
        Public CallingPage As Page
        Public AuditOnly As Boolean = False    'flag to bypass performing actual actions such as deletes
        Public Result As String = ""           'to pass back results of operation

        Private db As PromptDataHelper

        Public Sub New()
            db = New PromptDataHelper
        End Sub


#Region "Subs and Functions"

        Public Sub RunSystemPreReleaseRoutines()
            'NOTE: This is a catch all for running prerelase code - changes depending release.

  



        End Sub

  

        Private Function GetAvailableJCAFOCAllocations(ByVal nProjectID As Integer) As DataTable

            'Get all the budget lines/object codes/funding source that currently have allocated funds in the JCAF --

            Dim sql As String = "SELECT * FROM qry_BudgetJCAFOCSummaryLines WHERE ProjectID = " & nProjectID
            sql &= " ORDER BY ObjectCode"


            Dim tblSource As DataTable = db.ExecuteDataTable(sql)

            Dim col As New DataColumn
            col.DataType = Type.GetType("System.Decimal")
            col.ColumnName = "TotalProjectEncumbered"
            tblSource.Columns.Add(col)

            col = New DataColumn
            col.DataType = Type.GetType("System.Decimal")
            col.ColumnName = "TotalProjectJCAFNonEncumbered"
            tblSource.Columns.Add(col)

            'update the totals columns
            For Each row As DataRow In tblSource.Rows
                row("TotalProjectEncumbered") = ProcLib.CheckNullNumField(row("ProjectTotalContractsObjectCodeEncumbered")) + ProcLib.CheckNullNumField(row("ProjectTotalChangeOrdersObjectCodeEncumbered"))
                row("TotalProjectJCAFNonEncumbered") = row("ProjectJCAFObjectCodeTotal") - row("TotalProjectEncumbered")
            Next

            '*************************'Build the rest of the line-specific tree
            sql = "SELECT * FROM qry_BudgetJCAFOCDetailLines WHERE ProjectID = " & nProjectID
            sql &= " ORDER BY  JCAFLineDisplayOrder, ObjectCode"
            tblSource = db.ExecuteDataTable(sql)


            ProcLib.SetCustomJCAFFundingSourceName(tblSource, "JCAFFundingSource") 'Update the FundingSource Column to custom name if used in this district


            col = New DataColumn
            col.DataType = Type.GetType("System.Decimal")
            col.ColumnName = "TotalProjectEncumbered"
            tblSource.Columns.Add(col)

            col = New DataColumn
            col.DataType = Type.GetType("System.Decimal")
            col.ColumnName = "TotalProjectJCAFNonEncumbered"
            tblSource.Columns.Add(col)

            col = New DataColumn
            col.DataType = Type.GetType("System.Decimal")
            col.ColumnName = "TotalJCAFLineItemOCNonEncumbered"     'this holds the available balance for this OC/JCAF Line combination
            tblSource.Columns.Add(col)


            'update the totals columns
            For Each row As DataRow In tblSource.Rows
                row("TotalProjectEncumbered") = ProcLib.CheckNullNumField(row("ProjectTotalContractsObjectCodeEncumbered")) + ProcLib.CheckNullNumField(row("ProjectTotalChangeOrdersObjectCodeEncumbered"))
                row("TotalProjectJCAFNonEncumbered") = row("ProjectJCAFObjectCodeTotal") - row("TotalProjectEncumbered")
            Next


            'Create output table
            Dim tblTarget As New DataTable

            col = New DataColumn
            col.DataType = Type.GetType("System.String")
            col.ColumnName = "ObjectCode"
            tblTarget.Columns.Add(col)

            col = New DataColumn
            col.DataType = Type.GetType("System.String")
            col.ColumnName = "JCAFCellName"
            tblTarget.Columns.Add(col)

            col = New DataColumn
            col.DataType = Type.GetType("System.String")
            col.ColumnName = "JCAFCellNameObjectCode"
            tblTarget.Columns.Add(col)

            col = New DataColumn
            col.DataType = Type.GetType("System.String")
            col.ColumnName = "JCAFLine"
            tblTarget.Columns.Add(col)

            col = New DataColumn
            col.DataType = Type.GetType("System.Decimal")
            col.ColumnName = "AvailableAmount"
            tblTarget.Columns.Add(col)




            'now get specific OC's for each line in JCAF 
            Dim tblSectionLookup As DataTable = tblSource.Copy()    'for aggreagting totals


            Dim sLastSection As String = ""
            For Each row As DataRow In tblSource.Rows
                Dim sSection As String = row("JCAFSection")
                Dim sJCAFLine As String = row("JCAFLine")
                Dim sJCAFFundingSource As String = row("JCAFFundingSource")
                If (sSection & sJCAFLine & sJCAFFundingSource) <> sLastSection Then    'create root level parent
                    sLastSection = sSection & sJCAFLine & sJCAFFundingSource

                    Dim sParentDescription As String = ""
                    Dim sNewJCAFLine As String = ""
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

                    'Dim nodeparent As New RadTreeNode
                    'nodeparent.Text = sParentDescription
                    'nodeparent.Value = "noselect"
                    'nodeparent.ForeColor = System.Drawing.Color.Blue

                    For Each rowsec As DataRow In tblSectionLookup.Rows
                        If rowsec("JCAFSection") = sSection And rowsec("JCAFLine") = sJCAFLine And rowsec("JCAFFundingSource") = sJCAFFundingSource Then   'add get OC totals

                            Dim nJCAFLineOCTotalAmount As Double = 0
                            Dim sOC As String = rowsec("ObjectCode")

                            nJCAFLineOCTotalAmount = ProcLib.CheckNullNumField(rowsec("Amount"))

                            'Calc available balance for this JCAFLine/OC combo -- if the total available for the project for this object code
                            'is more than was allocated on this specifc line, then the whole amount for the line can be allocated
                            Dim nAvailableBal As Double = 0
                            'If nJCAFLineOCTotalAmount <= rowsec("TotalProjectJCAFNonEncumbered") Then
                            nAvailableBal = nJCAFLineOCTotalAmount   'NOTE: We might need to filter this more to subtract already allocated amounts from Line Total
                            'Else
                            '    nAvailableBal = rowsec("TotalProjectJCAFNonEncumbered")
                            'End If

                            If nAvailableBal > 0 Then
                                Dim newrow As DataRow = tblTarget.NewRow
                                ' node.Text = rowsec("Description") & " (" & FormatCurrency(nJCAFLineOCTotalAmount) & " Allocated, " & FormatCurrency(nAvailableBal) & " Available)"
                                newrow("JCAFCellNameObjectCode") = rowsec("JCAFColumnName") & "::" & rowsec("ObjectCode")

                                'Add some attributes for validaion
                                newrow("AvailableAmount") = nAvailableBal
                                ' node.Attributes.Add("OCDescription", rowsec("Description"))
                                newrow("JCAFLine") = sNewJCAFLine
                                newrow("JCAFCellName") = rowsec("JCAFColumnName")
                                newrow("ObjectCode") = rowsec("ObjectCode")


                                tblTarget.Rows.Add(newrow)
                            End If
                        End If
                    Next

                End If
            Next

            Return tblTarget

        End Function


        Public Sub SetSchedulePlaceholderEntries()
            'This Proc creates schecdule placeholder entries for those projects with no existing schedule and who have start and end dates set.
            Dim sql As String = "SELECT Projects.ProjectID, Projects.DistrictID,Projects.CollegeID,Projects.ProjectName, "
            sql &= "Projects.StartDate, Projects.EstCompleteDate, ScheduleTasks.TaskID "
            sql &= "FROM ScheduleTasks RIGHT OUTER JOIN Projects ON ScheduleTasks.ProjectID = Projects.ProjectID "
            sql &= "ORDER BY Projects.ProjectID "

            db.FillDataTableForUpdate("SELECT * FROM ScheduleTasks WHERE TaskID = 0 ")
            Dim tbl As DataTable = db.ExecuteDataTable(sql)
            Dim nLastProjectID As Integer = 0
            For Each row As DataRow In tbl.Rows
                If nLastProjectID <> row("ProjectID") Then
                    nLastProjectID = row("ProjectID")
                    If IsDBNull(row("TaskID")) Then       'no tasks for this project
                        If IsDate(row("StartDate")) And IsDate(row("EstCompleteDate")) Then   'create schedule entry

                            Dim newrow As DataRow = db.DataTable.NewRow()

                            newrow("CollegeID") = row("CollegeID")
                            newrow("DistrictID") = row("DistrictID")
                            newrow("ProjectID") = row("ProjectID")
                            newrow("Name") = "Project Duration (Placeholder)"
                            newrow("Description") = "Auto Generated Schedule placeholder"
                            newrow("ActualStart") = row("StartDate")
                            newrow("ActualEnd") = row("EstCompleteDate")

                            newrow("PercentComplete") = 0
                            newrow("Parent_TaskID") = 0
                            newrow("Duration") = DateDiff(DateInterval.Day, row("StartDate"), row("EstCompleteDate"))
                            newrow("IsMilestone") = 0
                            newrow("DisplayOrder") = 0
                            newrow("Budget") = 0




                            newrow("LastUpdateOn") = Now()
                            newrow("LastUpdateBy") = "SystemUtils"

                            db.DataTable.Rows.Add(newrow)
                        End If

                    End If

                End If


            Next
            db.SaveDataTableToDB()

        End Sub

        Public Sub LoadSessionActivityCombo(ByVal lstFilter As RadComboBox)

            lstFilter.Items.Clear()
            'Build the dropdown list

            Dim item As RadComboBoxItem

            item = New RadComboBoxItem
            item.Text = "Summary"
            item.Value = "Summary"
            item.IsSeparator = True
            lstFilter.Items.Add(item)

            item = New RadComboBoxItem
            item.Text = "Last 2 Hours"
            item.Value = "SummaryLast2Hours"
            lstFilter.Items.Add(item)

            item = New RadComboBoxItem
            item.Text = "Last 24 Hours"
            item.Value = "SummaryLast24Hours"
            lstFilter.Items.Add(item)

            item = New RadComboBoxItem
            item.Text = "Last 7 Days"
            item.Value = "SummaryLast7Days"
            lstFilter.Items.Add(item)

            item = New RadComboBoxItem
            item.Text = "Last 30 Days"
            item.Value = "SummaryLast30Days"
            lstFilter.Items.Add(item)

            item = New RadComboBoxItem
            item.Text = "Last 90 Days"
            item.Value = "SummaryLast90Days"
            lstFilter.Items.Add(item)

            item = New RadComboBoxItem
            item.Text = "All"
            item.Value = "SummaryAll"
            lstFilter.Items.Add(item)

            item = New RadComboBoxItem
            item.Text = "User Detail"
            item.Value = "UserDetail"
            item.IsSeparator = True
            lstFilter.Items.Add(item)

            db.FillDataTable("SELECT DISTINCT UserName FROM SessionLog ORDER BY UserName")
            For Each row As DataRow In db.DataTable.Rows

                item = New RadComboBoxItem
                item.Text = row("UserName")
                item.Value = "UserDetail" & row("UserName")
                lstFilter.Items.Add(item)

            Next



        End Sub

        Public Function GetUserSessionActivity(ByVal range As String) As DataTable
            'Gets user activity from session log
            Dim sql As String = ""
            Dim tbl As DataTable

            Select Case range
                Case "SummaryLast2Hours"
                    'Gets user activity from session log
                    sql = "Select UserName, Min(DateDiff(mi,TimeStamp,GetDate())) AS LastActivity "
                    sql &= "FROM SessionLog WHERE (DateDiff(mi, TimeStamp, GetDate()) < 120) "
                    sql &= "GROUP BY UserName ORDER BY UserName,LastActivity "
                    tbl = db.ExecuteDataTable(sql)

                Case "SummaryLast24Hours"
                    sql = "SELECT UserName, MAX(TimeStamp) AS LastActivity "
                    sql &= "FROM SessionLog WHERE(DateDiff(d, TimeStamp, GETDATE()) < 2) GROUP BY UserName ORDER BY UserName,LastActivity"
                    tbl = db.ExecuteDataTable(sql)

                Case "SummaryLast7Days"
                    sql = "SELECT UserName, MAX(TimeStamp) AS LastActivity "
                    sql &= "FROM SessionLog WHERE(DateDiff(d, TimeStamp, GETDATE()) < 8) GROUP BY UserName ORDER BY UserName,LastActivity"
                    tbl = db.ExecuteDataTable(sql)
                Case "SummaryLast30Days"
                    sql = "SELECT UserName, MAX(TimeStamp) AS LastActivity "
                    sql &= "FROM SessionLog WHERE(DateDiff(d, TimeStamp, GETDATE()) < 31) GROUP BY UserName ORDER BY UserName,LastActivity"
                    tbl = db.ExecuteDataTable(sql)

                Case "SummaryLast90Days"
                    sql = "SELECT UserName, MAX(TimeStamp) AS LastActivity "
                    sql &= "FROM SessionLog WHERE(DateDiff(d, TimeStamp, GETDATE()) < 91) GROUP BY UserName ORDER BY UserName,LastActivity"
                    tbl = db.ExecuteDataTable(sql)


                Case "SummaryAll"
                    sql = "SELECT UserName, MAX(TimeStamp) AS LastActivity "
                    sql &= "FROM SessionLog  GROUP BY UserName ORDER BY UserName,LastActivity"
                    tbl = db.ExecuteDataTable(sql)

                Case Else

                    If range.Contains("UserDetail") Then

                        Dim sUser As String = range.Replace("UserDetail", "")

                        tbl = New DataTable

                        Dim col As New DataColumn
                        col.DataType = Type.GetType("System.String")
                        col.ColumnName = "LoginTime"
                        tbl.Columns.Add(col)

                        col = New DataColumn
                        col.DataType = Type.GetType("System.String")
                        col.ColumnName = "Duration"
                        tbl.Columns.Add(col)

                        col = New DataColumn
                        col.DataType = Type.GetType("System.String")
                        col.ColumnName = "ActivityDate"
                        tbl.Columns.Add(col)

                        col = New DataColumn
                        col.DataType = Type.GetType("System.String")
                        col.ColumnName = "ActivityStart"
                        tbl.Columns.Add(col)

                        col = New DataColumn
                        col.DataType = Type.GetType("System.String")
                        col.ColumnName = "ActivityEnd"
                        tbl.Columns.Add(col)

                        col = New DataColumn
                        col.DataType = Type.GetType("System.String")
                        col.ColumnName = "LastActivity"
                        tbl.Columns.Add(col)

                        col = New DataColumn
                        col.DataType = Type.GetType("System.String")
                        col.ColumnName = "PageViews"
                        tbl.Columns.Add(col)

                        col = New DataColumn
                        col.DataType = Type.GetType("System.String")
                        col.ColumnName = "UserName"
                        tbl.Columns.Add(col)

                        Dim tblTime As DataTable = db.ExecuteDataTable("SELECT * FROM SessionLog WHERE UserName = '" & sUser & "' ORDER BY Timestamp ")
                        Dim sLastDay As String = ""
                        Dim bVeryFirstRecord As Boolean = True
                        Dim bAddLastRecord As Boolean = False
                        Dim dFirstBlockTimeStamp As DateTime
                        Dim dLastBlockTimeStamp As DateTime
                        Dim nTimeDiffMinutes As Integer = 0
                        Dim nPageViews As Integer = 0
                        Dim newrow As DataRow
                        For Each rowsource As DataRow In tblTime.Rows
                            Dim dTimeStamp As DateTime = rowsource("TimeStamp")
                            nPageViews += 1

                            If bVeryFirstRecord Then  'this is very first record 
                                newrow = tbl.NewRow
                                dFirstBlockTimeStamp = dTimeStamp
                                newrow("UserName") = sUser
                                newrow("ActivityDate") = FormatDateTime(dTimeStamp, DateFormat.LongDate)
                                newrow("ActivityStart") = FormatDateTime(dTimeStamp, DateFormat.ShortTime)
                                bVeryFirstRecord = False
                            End If

                            'Now check the time diff between first block time and this one (if different)
                            nTimeDiffMinutes = DateDiff(DateInterval.Minute, dFirstBlockTimeStamp, dTimeStamp)

                            If nTimeDiffMinutes > 60 Then  'this is greater than 60 minutes, could be new day, calc difference, update last record and add to table
                                Dim nDuration As Integer = DateDiff(DateInterval.Minute, dFirstBlockTimeStamp, dLastBlockTimeStamp)
                                newrow("ActivityEnd") = FormatDateTime(dLastBlockTimeStamp, DateFormat.ShortTime)
                                newrow("Duration") = nDuration & " Minutes"
                                newrow("PageViews") = nPageViews
                                nPageViews = 0
                                tbl.Rows.Add(newrow)

                                'now create next first block record
                                newrow = tbl.NewRow
                                dFirstBlockTimeStamp = dTimeStamp
                                newrow("UserName") = sUser
                                newrow("ActivityDate") = FormatDateTime(dTimeStamp, DateFormat.LongDate)
                                newrow("ActivityStart") = FormatDateTime(dTimeStamp, DateFormat.ShortTime)

                                bAddLastRecord = True
                            End If

                            dLastBlockTimeStamp = dTimeStamp
                        Next

                        'add the last record if there is one
                        If bAddLastRecord Then
                            Dim nDuration As Integer = DateDiff(DateInterval.Minute, dFirstBlockTimeStamp, dLastBlockTimeStamp)
                            newrow("ActivityEnd") = FormatDateTime(dLastBlockTimeStamp, DateFormat.ShortTime)
                            newrow("Duration") = nDuration & " Minutes"
                            newrow("PageViews") = nPageViews
                            nPageViews = 0
                            tbl.Rows.Add(newrow)
                        End If

                    End If

            End Select

            Return tbl


        End Function


        Public Sub MoveProject(ByVal nProjectID As Integer, ByVal nTargetCollegeID As Integer)
            'This proc moves a projectID to a new College ID
            Dim berror As Boolean = False

            If nProjectID = 0 Or nTargetCollegeID = 0 Then
                berror = True
            Else
                'check that the target and source are valid Numbers
                db.FillReader("SELECT Count(ProjectID) AS Tot from Projects WHERE ProjectID = " & nProjectID)
                While db.Reader.Read
                    If db.Reader("tot") = 0 Then
                        berror = True
                    End If
                End While
                db.Reader.Close()
                db.FillReader("SELECT Count(CollegeID) AS Tot from Colleges WHERE CollegeID = " & nTargetCollegeID)

                While db.Reader.Read
                    If db.Reader("tot") = 0 Then
                        berror = True
                    End If
                End While
                db.Reader.Close()

            End If
            If berror Then
                Result &= "Sorry, Please enter a valild ProjectID and CollegeID."
            Else   'Make the move

                'get the new Old college and district ID
                Dim nOldDistrictID As Integer
                Dim nOldCollegeID As Integer
                db.FillReader("SELECT CollegeID,DistrictID from Projects WHERE ProjectID = " & nProjectID)
                While db.Reader.Read
                    nOldDistrictID = db.Reader("DistrictID")
                    nOldCollegeID = db.Reader("CollegeID")
                End While
                db.Reader.Close()

                'get the new district ID
                Dim nTargetDistrictID As Integer
                db.FillReader("SELECT DistrictID AS ID from Colleges WHERE CollegeID = " & nTargetCollegeID)
                While db.Reader.Read
                    nTargetDistrictID = db.Reader("ID")
                End While
                db.Reader.Close()

                'Update Apprise Photos
                db.ExecuteNonQuery("UPDATE ApprisePhotos SET DistrictID = " & nTargetDistrictID & ",CollegeID = " & nTargetCollegeID & " WHERE ProjectID = " & nProjectID)

                'Update Attachments records
                db.ExecuteNonQuery("UPDATE Attachments SET DistrictID = " & nTargetDistrictID & ",CollegeID = " & nTargetCollegeID & " WHERE ProjectID = " & nProjectID)

                'get the old path info and new path info to update the file path field
                Dim sOldPath As String = "DistrictID_" & nOldDistrictID & "/CollegeID_" & nOldCollegeID
                Dim sNewPath As String = "DistrictID_" & nTargetDistrictID & "/CollegeID_" & nTargetCollegeID
                Dim sFilePath As String
                Using rsTar As New PromptDataHelper
                    db.FillReader("SELECT AttachmentID,FilePath FROM Attachments WHERE ProjectID = " & nProjectID)
                    While db.Reader.Read
                        sFilePath = db.Reader("FilePath")
                        Dim nkey As Integer = db.Reader("AttachmentID")
                        sFilePath = sFilePath.Replace(sOldPath, sNewPath)
                        rsTar.ExecuteNonQuery("UPDATE Attachments SET FilePath = '" & sFilePath & "' WHERE AttachmentID = " & nkey)
                    End While
                    db.Reader.Close()
                End Using

                'Now move the actual project directory to the new location
                sOldPath = ProcLib.GetCurrentAttachmentPath() & sOldPath & "/ProjectID_" & nProjectID
                sNewPath = ProcLib.GetCurrentAttachmentPath() & sNewPath & "/ProjectID_" & nProjectID
                Directory.Move(sOldPath, sNewPath)

                'update budget items
                db.ExecuteNonQuery("UPDATE BudgetItems SET DistrictID = " & nTargetDistrictID & ",CollegeID = " & nTargetCollegeID & " WHERE ProjectID = " & nProjectID)


                'update contract Detail
                db.ExecuteNonQuery("UPDATE ContractDetail SET DistrictID = " & nTargetDistrictID & " WHERE ProjectID = " & nProjectID)


                'update contracts
                db.ExecuteNonQuery("UPDATE Contracts SET DistrictID = " & nTargetDistrictID & ",CollegeID = " & nTargetCollegeID & " WHERE ProjectID = " & nProjectID)


                'update Notes
                db.ExecuteNonQuery("UPDATE Notes SET DistrictID = " & nTargetDistrictID & " WHERE ProjectID = " & nProjectID)


                'update projects
                db.ExecuteNonQuery("UPDATE Projects SET DistrictID = " & nTargetDistrictID & ",CollegeID = " & nTargetCollegeID & " WHERE ProjectID = " & nProjectID)


                'update TransactionDetail
                db.ExecuteNonQuery("UPDATE TransactionDetail SET DistrictID = " & nTargetDistrictID & " WHERE ProjectID = " & nProjectID)


                'update Transactions
                db.ExecuteNonQuery("UPDATE Transactions SET DistrictID = " & nTargetDistrictID & " WHERE ProjectID = " & nProjectID)


                Result &= "Done moving Project " & nProjectID & " !"

            End If

        End Sub


        Public Sub RemoveDeadAttachmentRecords()

            'this proc removes any records in the attachments table for files that are not found on the disk.

            If AuditOnly = False Then  'take action
                Using rsRem As New PromptDataHelper

                    Dim sPath As String = ProcLib.GetCurrentAttachmentPath()
                    rsRem.FillReader("SELECT AttachmentID, FilePath, FileName From Attachments")
                    While rsRem.Reader.Read
                        Dim sFile As String
                        sFile = sPath & rsRem.Reader("FilePath") & rsRem.Reader("FileName")
                        sFile = sFile.Replace("/", "\")

                        If Not File.Exists(sFile) Then
                            db.ExecuteNonQuery("DELETE FROM Attachments WHERE AttachmentID = " & rsRem.Reader("AttachmentID"))
                        End If

                    End While

                    rsRem.Reader.Close()
                End Using
            End If


        End Sub

        Public Sub CheckAttachmentsForOrphans(ByVal PhysicalPath As String)
            'NOTE: this is a RECURSIVE subroutine
            'This proc will go through the given directory and check for files that are orphaned.
            'If they exist on disk but on in the database they are added as entries in the database.
            'Nothing is performed if the AuditOnly checkbox is checked.

            'Diagnostics.Debug.WriteLine("Directory: " & PhysicalPath) 'debugging...

            Dim sPath As String
            Dim sFolderName As String
            Dim s As String
            Dim bFound As Boolean = False

            ' Display Subfolders.
            For Each s In Directory.GetDirectories(PhysicalPath)
                sFolderName = Path.GetFileName(s)
                If InStr(sFolderName, "_appphotos") = 0 And InStr(sFolderName, "_vti_cnf") = 0 Then 'filter out these sub folders
                    'we have a user folder so check it out
                    sPath = PhysicalPath & sFolderName + "/"
                    CheckAttachmentsForOrphans(sPath)      ' NOTE:  THIS IS A RECURSIVE CALL
                End If
            Next

            'Check the files in the dir.
            Dim sFileName As String
            Dim sFilePath As String
            For Each s In Directory.GetFiles(PhysicalPath)
                sFileName = Path.GetFileName(s)
                If sFileName <> "_collegelogo_.jpg" Then 'filter out the logo for the college

                    'Strip off the attachemetns path preface 
                    sFilePath = Path.GetFullPath(s)
                    sFilePath = sFilePath.Replace("\", "/")   'fix slashes
                    sFilePath = sFilePath.Replace(ProcLib.GetCurrentAttachmentPath(), "")
                    sFilePath = sFilePath.Replace(sFileName, "")
                    Try

                        'NOTE: we have to replace single quotes with doubles for SQL server inserts to work
                        Dim attID As Integer
                        attID = db.ExecuteScalar("Select AttachmentID From Attachments Where FilePath = '" & sFilePath.Replace("'", "''") & "' AND FileName = '" & sFileName.Replace("'", "''") & "' ")

                        If attID = Nothing Then         'no file found in database
                            Result &= "Orphaned File: " & sFilePath & sFileName & "<br>"
                            If AuditOnly = False Then  'take action
                                'insert the record to correspond with this file in the attachments table
                                Dim ff As FileInfo = New FileInfo(Path.GetFullPath(s))
                                Dim nFileSize = ff.Length
                                'Fix any wrong leaning slash
                                sFilePath = sFilePath.Replace("\", "/")

                                'retrieve CLientID from District
                                Dim ssql As New System.Text.StringBuilder
                                Dim nClientID As Integer = 0
                                nClientID = db.ExecuteScalar("SELECT Distinct ClientID FROM Districts WHERE DistrictID = " & ExtractID(sFilePath, "District"))

                                sFilePath = sFilePath.Replace(ProcLib.GetCurrentAttachmentPath(), "")
                                sFilePath = sFilePath.Replace("'", "''")                         'we have to replace single quotes with doubles for SQL server inserts to work
                                sFileName = sFileName.Replace("'", "''")

                                ssql.Append("INSERT INTO Attachments ")
                                ssql.Append("(CLientID,DistrictID,CollegeID,ProjectID,ContractID,FilePath,FileName,FileSize,Description,LastUpdateBy,LastUpdateOn) ")
                                ssql.Append("VALUES ")
                                ssql.Append("(" & nClientID & "," & ExtractID(sFilePath, "District") & "," & ExtractID(sFilePath, "College") & "," & ExtractID(sFilePath, "Project") & ",")
                                ssql.Append(ExtractID(sFilePath, "Contract") & ",")
                                ssql.Append("'" & sFilePath & "','" & sFileName & "','" & nFileSize & "','Added By Reconcile Routine','Reconcile Routine','" & Now() & "')")
                                db.ExecuteNonQuery(ssql.ToString)

                            End If
                        End If

                    Catch ex As Exception
                        Result &= "<br><br><br>File Error: " & ex.Message & "<br>" '& ex.StackTrace
                    End Try

                End If
            Next

        End Sub

        Private Function ExtractID(ByVal spath As String, ByVal sLevel As String) As Integer
            ' Extracts the ID From Attachemnt Path and passes back 

            Try
                sLevel = sLevel & "ID_"

                If InStr(spath, sLevel) = 0 Then  'just return 0
                    ExtractID = 0
                Else
                    Dim sResult As String
                    Dim nLoc As Integer

                    nLoc = InStr(spath, sLevel)
                    sResult = Mid(spath, nLoc)

                    nLoc = InStr(sResult, "/") - 1
                    sResult = Left(sResult, nLoc)

                    nLoc = InStr(sResult, "_") + 1
                    sResult = Mid(sResult, nLoc)

                    ExtractID = sResult
                End If
            Catch ex As Exception
                Result &= "<br><br><br>Parse Error: " & spath & "<br><br>" & sLevel & "<br><br>" & ex.Message & "<br> "
            End Try



        End Function

        Public Sub RemoveOrphanDirectoriesFromAttachments()

            'This proc will go through the attachments directory and check that every Distrcit/College/Project/Contract found on the disk
            'are represented with a corresponding entry in the database. 

            'First remove any orphaned districts, colleges, projects or contracts
            Dim spath = Replace(ProcLib.GetCurrentAttachmentPath(), "/", "\") 'fix wrong leaning \
            Using rs As New PromptDataHelper
                Dim RootAttachmentsDir As DirectoryInfo = New DirectoryInfo(spath)

                'remove orphaned districts
                Dim dirs_Districts As DirectoryInfo() = RootAttachmentsDir.GetDirectories()
                Dim dir_District As DirectoryInfo
                For Each dir_District In dirs_Districts
                    'extract the DistrictID
                    Dim sDistrictID As String = dir_District.FullName
                    sDistrictID = sDistrictID.Replace(spath, "")
                    sDistrictID = sDistrictID.Replace("DistrictID_", "")

                    'Find in DataBase
                    rs.FillReader("SELECT DistrictID FROM Districts WHERE DistrictID = " & sDistrictID)
                    If rs.Reader.HasRows = False Then   'district does not exist in database
                        Result &= "Removed Orphaned District: DistrictID_" & sDistrictID & "<br>"
                        'remove the directory and all contents
                        If AuditOnly = False Then
                            dir_District.Delete(True)
                        End If


                    Else       'The district is valid now check for valid college

                        Using rsColleges As New PromptDataHelper
                            Dim dirs_Colleges As DirectoryInfo() = dir_District.GetDirectories()
                            Dim dir_College As DirectoryInfo
                            For Each dir_College In dirs_Colleges
                                'extract the CollegeID
                                Dim sCollegeID As String = dir_College.FullName
                                sCollegeID = sCollegeID.Replace(dir_District.FullName, "")
                                sCollegeID = sCollegeID.Replace("CollegeID_", "")
                                sCollegeID = sCollegeID.Replace("\", "")  'remove remainign"\"

                                'Find in DataBase
                                rsColleges.FillReader("SELECT CollegeID FROM Colleges WHERE CollegeID = " & sCollegeID)
                                If rsColleges.Reader.HasRows = False Then   'college does not exist in database
                                    Result &= "Orphaned College: " & dir_College.FullName & "<br>"
                                    'remove the directory and all contents
                                    If AuditOnly = False Then
                                        Try
                                            dir_College.Delete(True)
                                        Catch ex As Exception
                                            Result &= "!!!!!College!!!!!!!!!!!<br><br>" & dir_College.FullName & "<br><br>!!!!!!!!!!!!!!!!!"
                                        End Try
                                    End If

                                Else       'The college is valid now check for valid projects

                                    Using rsProjects As New PromptDataHelper
                                        Dim dirs_Projects As DirectoryInfo() = dir_College.GetDirectories()
                                        Dim dir_Project As DirectoryInfo
                                        For Each dir_Project In dirs_Projects
                                            If InStr(dir_Project.Name, "ProjectID_") > 0 Then
                                                'extract the ProjectID
                                                Dim sProjectID As String = dir_Project.FullName
                                                sProjectID = sProjectID.Replace(dir_College.FullName, "")
                                                sProjectID = sProjectID.Replace("ProjectID_", "")
                                                sProjectID = sProjectID.Replace("\", "")  'remove remainign"\"

                                                'Find in DataBase
                                                rsProjects.FillReader("SELECT ProjectID FROM Projects WHERE ProjectID = " & sProjectID)
                                                If rsProjects.Reader.HasRows = False Then   'college does not exist in database
                                                    Result &= "Orphaned Project: " & dir_Project.FullName & "<br>"
                                                    'remove the directory and all contents
                                                    If AuditOnly = False Then
                                                        Try
                                                            dir_Project.Delete(True)
                                                        Catch ex As Exception
                                                            Result &= "!!!!!!!Project!!!!!!!!!<br><br>" & dir_Project.FullName & "<br>"
                                                            Result &= ex.Message & "******************************************"
                                                        End Try

                                                    End If
                                                Else       'The Project is valid now check for valid Contract

                                                    Using rsContracts As New PromptDataHelper
                                                        Dim dirs_Contracts As DirectoryInfo() = dir_Project.GetDirectories()
                                                        Dim dir_Contract As DirectoryInfo
                                                        For Each dir_Contract In dirs_Contracts
                                                            If InStr(dir_Contract.Name, "ContractID_") > 0 Then
                                                                'extract the ContracttID
                                                                Dim sContractID As String = dir_Contract.FullName
                                                                sContractID = sContractID.Replace(dir_Project.FullName, "")
                                                                sContractID = sContractID.Replace("ContractID_", "")
                                                                sContractID = sContractID.Replace("\", "")  'remove remainign"\"

                                                                'Find in DataBase
                                                                Try
                                                                    rsContracts.FillReader("SELECT ContractID FROM Contracts WHERE ContractID = " & sContractID)
                                                                    If rsContracts.Reader.HasRows = False Then   'college does not exist in database
                                                                        Result &= "Orphaned Contract: " & dir_Contract.FullName & "<br>"
                                                                        'remove the directory and all contents
                                                                        If AuditOnly = False Then
                                                                            Try
                                                                                dir_Contract.Delete(True)
                                                                            Catch ex As Exception
                                                                                Result &= "!!!!!!!Contract!!!!!!!!!<br><br>" & dir_Project.FullName & "<br><br>!!!!!!!!!!!!!!!!!"
                                                                            End Try
                                                                        End If
                                                                    End If
                                                                Catch ex As Exception
                                                                    Result &= "<br><br><br>Contract Error: " & dir_Contract.FullName & "<br><br>"
                                                                Finally
                                                                    rsContracts.Reader.Close()
                                                                End Try
                                                            End If

                                                        Next
                                                        rsContracts.Close()
                                                    End Using 'rsContracts
                                                End If
                                            End If
                                        Next
                                        'rsProjects.Reader.Close()
                                        rsProjects.Close()
                                    End Using 'rsProjects
                                End If
                                rsColleges.Reader.Close()
                                rsColleges.Close()
                            Next
                        End Using 'rsColleges
                    End If
                    rs.Reader.Close()
                    rs.Close()
                Next
            End Using 'rs

        End Sub

        Public Sub PurgeCollege(ByVal nCollegeID As Integer)
            'This proc will purge all records accociated with a college.
            Dim sql As String = ""
            Dim nDistrictID As Integer = 0

            If Val(nCollegeID) > 0 Then

                'Start at projects level so loop through all projects accociated with college.
                Dim rsProjects As SqlDataReader = db.ExecuteReader("SELECT DistrictID, ProjectID FROM Projects WHERE CollegeID = " & nCollegeID)
                While rsProjects.Read

                    nDistrictID = rsProjects("DistrictID")   'store for attachments removal later

                    Dim nProjectID As Integer = rsProjects("ProjectId")
                    If nProjectID <> 0 Then

                        Using dbTarget As New PromptDataHelper

                            sql = "DELETE FROM ApprisePhotos WHERE ProjectID = " & nProjectID
                            dbTarget.ExecuteNonQuery(sql)

                            'sql = "DELETE FROM AppriseProjectData WHERE ProjectID = " & nProjectID
                            'dbTarget.ExecuteNonQuery(sql)

                            sql = "DELETE FROM Attachments WHERE ProjectID = " & nProjectID
                            dbTarget.ExecuteNonQuery(sql)

                            sql = "DELETE FROM BudgetChangeLog WHERE ProjectID = " & nProjectID
                            dbTarget.ExecuteNonQuery(sql)

                            sql = "DELETE FROM BudgetItems WHERE ProjectID = " & nProjectID
                            dbTarget.ExecuteNonQuery(sql)

                            sql = "DELETE FROM BudgetObjectCodeEstimates WHERE ProjectID = " & nProjectID
                            dbTarget.ExecuteNonQuery(sql)

                            sql = "DELETE FROM BudgetObjectCodes WHERE ProjectID = " & nProjectID
                            dbTarget.ExecuteNonQuery(sql)

                            sql = "DELETE FROM BudgetReporting WHERE ProjectID = " & nProjectID
                            dbTarget.ExecuteNonQuery(sql)

                            sql = "DELETE FROM ContractDetail WHERE ProjectID = " & nProjectID
                            dbTarget.ExecuteNonQuery(sql)

                            'Blow away all notes assoicated with all Contracts
                            Using db2 As New PromptDataHelper
                                sql = "SELECT ContractID FROM Contracts WHERE ProjectID = " & nProjectID
                                Dim rs2 As SqlDataReader = db2.ExecuteReader(sql)
                                While rs2.Read
                                    If rs2("ContractID") <> 0 Then
                                        sql = "DELETE FROM Notes WHERE ContractID = " & rs2("ContractId")
                                        dbTarget.ExecuteNonQuery(sql)
                                    End If

                                End While
                            End Using


                            sql = "DELETE FROM Contracts WHERE ProjectID = " & nProjectID
                            dbTarget.ExecuteNonQuery(sql)

                            sql = "DELETE FROM JCAFChangeLog WHERE ProjectID = " & nProjectID
                            dbTarget.ExecuteNonQuery(sql)

                            If nProjectID <> 0 Then
                                sql = "DELETE FROM Notes WHERE ProjectID = " & nProjectID
                                dbTarget.ExecuteNonQuery(sql)
                            End If

                            sql = "DELETE FROM TransactionDetail WHERE ProjectID = " & nProjectID
                            dbTarget.ExecuteNonQuery(sql)

                            sql = "DELETE FROM Transactions WHERE ProjectID = " & nProjectID
                            dbTarget.ExecuteNonQuery(sql)

                        End Using
                    End If
                End While
                rsProjects.Close()


                sql = "DELETE FROM Projects WHERE CollegeID = " & nCollegeID
                db.ExecuteNonQuery(sql)

                sql = "DELETE FROM Colleges WHERE CollegeID = " & nCollegeID
                db.ExecuteNonQuery(sql)

                If nCollegeID <> 0 Then
                    sql = "DELETE FROM Notes WHERE CollegeID = " & nCollegeID
                    db.ExecuteNonQuery(sql)
                End If


            End If

            ''Blow away attachments folder '' NEED TO DEAL WITH READ ONY FILES - FOR NOW MANUALLY DELETE
            'Dim PhysicalPath As String = Proclib.GetCurrentAttachmentPath() & "DistrictID_" & nDistrictID & "/"
            'PhysicalPath = PhysicalPath & "CollegeID_" & nCollegeID & "/"
            'If Directory.Exists(PhysicalPath) Then
            '    'Directory.Delete(PhysicalPath, True)
            'End If

        End Sub

        Public Sub PurgeDistrict(ByVal nDistrictID As Integer)
            'Purges all records associated with a district from the system
            Dim sql As String = ""

            If Val(nDistrictID) > 0 Then

                Using rs1 As New PromptDataHelper
                    'Start at projects level so loop through all projects accociated with District.
                    rs1.FillReader("SELECT CollegeID FROM Colleges WHERE DistrictID = " & nDistrictID)
                    While rs1.Reader.Read
                        Dim nCollegeID As Integer = rs1.Reader("CollegeId")
                        PurgeCollege(nCollegeID)
                    End While
                    rs1.Reader.Close()
                End Using

                Using db As New PromptDataHelper
                    sql = "DELETE FROM Colleges WHERE DistrictID = " & nDistrictID
                    db.ExecuteNonQuery(sql)

                    sql = "DELETE FROM Lookups WHERE DistrictID = " & nDistrictID
                    db.ExecuteNonQuery(sql)


                    sql = "DELETE FROM ProjectManagers WHERE DistrictID = " & nDistrictID
                    db.ExecuteNonQuery(sql)

                    sql = "DELETE FROM Contractors WHERE DistrictID = " & nDistrictID
                    db.ExecuteNonQuery(sql)

                    sql = "DELETE FROM BudgetChangeBatches WHERE DistrictID = " & nDistrictID
                    db.ExecuteNonQuery(sql)

                    sql = "DELETE FROM Districts WHERE DistrictID = " & nDistrictID
                    db.ExecuteNonQuery(sql)

                    sql = "DELETE FROM JCAFChangeLog WHERE DistrictID = " & nDistrictID
                    db.ExecuteNonQuery(sql)

                    sql = "DELETE FROM LedgerAccountEntries WHERE DistrictID = " & nDistrictID
                    db.ExecuteNonQuery(sql)

                    sql = "DELETE FROM LedgerAccountEntryAllocations WHERE DistrictID = " & nDistrictID
                    db.ExecuteNonQuery(sql)

                    sql = "DELETE FROM LedgerAccounts WHERE DistrictID = " & nDistrictID
                    db.ExecuteNonQuery(sql)

                    sql = "DELETE FROM ObjectCodes WHERE DistrictID = " & nDistrictID
                    db.ExecuteNonQuery(sql)

                    sql = "DELETE FROM ObjectCodesJCAFLines WHERE DistrictID = " & nDistrictID
                    db.ExecuteNonQuery(sql)

                    sql = "DELETE FROM ProjectManagers WHERE DistrictID = " & nDistrictID
                    db.ExecuteNonQuery(sql)


                    sql = "DELETE FROM WorkflowLog WHERE DistrictID = " & nDistrictID
                    db.ExecuteNonQuery(sql)
                    sql = "DELETE FROM WorkflowRoles WHERE DistrictID = " & nDistrictID
                    db.ExecuteNonQuery(sql)

                    sql = "DELETE FROM WorkflowSCenerioOwners WHERE DistrictID = " & nDistrictID
                    db.ExecuteNonQuery(sql)

                    sql = "DELETE FROM WorkflowSCenerioOwnerTargets WHERE DistrictID = " & nDistrictID
                    db.ExecuteNonQuery(sql)

                    sql = "DELETE FROM WorkflowSCenerios WHERE DistrictID = " & nDistrictID
                    db.ExecuteNonQuery(sql)

                    sql = "DELETE FROM PassThroughEntries WHERE DistrictID = " & nDistrictID
                    db.ExecuteNonQuery(sql)
                End Using




            End If

            'Dim PhysicalPath As String = Proclib.GetCurrentAttachmentPath() & "DistrictID_" & nDistrictID & "/"
            'If Directory.Exists(PhysicalPath) Then
            '    Directory.Delete(PhysicalPath, True)
            'End If

            Result = "Done."

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

