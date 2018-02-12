Imports System
Imports System.Web
Imports System.Web.UI.WebControls
Imports System.IO
Imports System.Data
Imports System.Data.SqlClient
Imports Telerik.Web.UI

Namespace Prompt

    '********************************************
    '*  Submittal Class
    '*  
    '*  Purpose: Processes data for the Submittal Objects
    '*
    '*  Last Mod By:    Ford James
    '*  Last Mod On:    02/12/10
    '*
    '********************************************

    Public Class Submittal
        Implements IDisposable

        'Properties
        Public CallingPage As Page
        Public CallingUserControl As UserControl   'used for refernce to dynamic UC as cannot get through calling page
        Public Reader As SqlDataReader
        Public DataTable As DataTable
        Public sql As String
        Public tbl As DataTable

        Private db As PromptDataHelper

        Public Sub New()
            db = New PromptDataHelper

        End Sub

#Region "Project Submittals"

        Public Function buildSubmittalHistory(submittalID As Integer) As String
            Dim tblRem As DataTable
            Dim outPut As String
            Dim zbold As String = "<b>"
            Dim attach As String

            sql = "Select sub.CreateDate, sub.DateRequired, sub.SubmittedByID, sub.RevNo, sub.Remarks, sub.ReleasedDate, con.Name  From submittals sub"
            sql &= " JOIN Contacts con On con.ContactID=sub.SubmittedByID"
            sql &= " Where sub.submittalID = " & submittalID & " OR sub.ParentSubmittalID = " & submittalID

            tbl = db.ExecuteDataTable(sql)
            outPut = "Date Created: <b>" & tbl.Rows(0).Item("CreateDate") & "</b>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; Created By: <b>" & tbl.Rows(0).Item("Name") & "</b><br />"
            outPut &= "Original Date Required: <b>" & tbl.Rows(0).Item("DateRequired") & "</b><br /><br />"
            outPut &= tbl.Rows(0).Item("Remarks") & "<br /><br />"
            attach = getAttachments(submittalID, tbl.Rows(0).Item("RevNo"), 1)
            outPut &= attach
            outPut &= "---------------------------<br />"

            For Each row As DataRow In tbl.Rows
                If row.Item("RevNo") > 0 Then
                    outPut &= "Revision #: <b>" & row.Item("RevNo") & "</b>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Released On: <b>" & row.Item("ReleasedDate") & "</b><br />"
                    outPut &= "Revision Date Required: <b>" & row.Item("dateRequired") & "</b><br />"
                    outPut &= "Release Remarks By: <b>" & row.Item("Name") & "</b><br /><br />"
                    outPut &= row.Item("Remarks") & "<br /><br />"
                    'outPut &= "Revision #: <b>" & row.Item("RevNo") & "</b>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Released On: <b>" & row.Item("ReleasedDate") & "</b><br />"
                    attach = getAttachments(submittalID, row.Item("RevNo"), 1)
                    outPut &= attach
                    outPut &= "----------------------------<br />"
                End If

                sql = "Select rem.Remark, rem.ResponderID, rem.RemarkType, rem.ReturnedOn, rem.SequenceNum, rem.RemarkStatus, con.Name From SubmittalRemarks rem"
                sql &= " JOIN Contacts con ON con.ContactID=rem.ResponderID "
                sql &= "Where SubmittalID=" & submittalID & " AND Revision=" & row.Item("RevNo") & " AND RemarkStatus='Released' Order By SequenceNum"

                tblRem = db.ExecuteDataTable(sql)

                For Each rowRem As DataRow In tblRem.Rows
                    outPut &= "Response Type: <b>" & rowRem.Item("RemarkType") & "</b>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; Released On: <b>" & rowRem.Item("ReturnedOn") & "</b><br/>"
                    outPut &= "Response By: <b>" & rowRem.Item("Name") & "</b><br /><br />" & rowRem.Item("Remark") & "<br /><br />"
                    attach = getAttachments(submittalID, row.Item("RevNo"), rowRem.Item("SequenceNum"))
                    outPut &= attach
                    If rowRem.Item("SequenceNum") < 7 Then
                        outPut &= "---------------------------<br />"
                    End If
                Next
                outPut &= "<b>_____________________________________________________________</b><br />"
            Next

            Return outPut
        End Function

        Public Function getAttachments(submittalID As Integer, revision As Integer, seqNum As Integer) As String
            Dim curUl As String = (HttpContext.Current.Request.Url.Host).ToString()
            Dim port As String = (HttpContext.Current.Request.Url.Port).ToString()
            Dim protocol As String = ConfigurationManager.AppSettings("Protocol")

            If port = "" Then
                curUl = curUl & "/"
            Else
                curUl = curUl & ":" & port & "/"
            End If

            Dim strPhysicalPath As String = ProcLib.GetCurrentAttachmentPath() & "DistrictID_" & HttpContext.Current.Session("DistrictID") & "/"
            strPhysicalPath &= "_apprisedocs/_Submittals/SubmittalID_" & submittalID & "/Rev_" & revision & "_Remark_" & seqNum & "/"

            Dim strFilePath As String = ProcLib.GetCurrentRelativeAttachmentPath() & "DistrictID_" & HttpContext.Current.Session("DistrictID") & "/"
            strFilePath &= "_apprisedocs/_Submittals/SubmittalID_" & submittalID & "/Rev_" & revision & "_Remark_" & seqNum & "/"
            Dim strFiles As String = ""

            Try ' getting meeting minutes
                Dim dinfo As New IO.DirectoryInfo(strPhysicalPath)
                Dim finfo As IO.FileInfo() = dinfo.GetFiles()
                Dim dra As IO.FileInfo
                Dim path As String = "<a href='" & protocol & curUl & strFilePath & "/"
                Dim Icon As String = ""
                If finfo.Length > 0 Then
                    For Each dra In finfo
                        'Icon = "<img src='images/" & getFileImage(dra.ToString()) & "'/>"
                        Icon = ""
                        strFiles &= path & dra.ToString() & "'>" & Icon & "&nbsp;&nbsp;" & dra.ToString() & "</a><br/>"
                    Next
                Else
                    strFiles = "No Attachments!<br/>"
                End If
               
            Catch ex As Exception
                strFiles = "No Attachments!<br/>"
            End Try

            Return strFiles
        End Function

        Public Function GetAllProjectSubmittals(ByVal ProjectID As Integer) As DataTable

            'this sql does several self joins in contacts to get different contact names and parent company for each contact
            Dim sql As String = "SELECT Submittals.*, Contacts_1.Name AS SubmittedTo, Contacts.Name AS SubmittedToCompany, Contacts_2.Name AS SubmittedBy, "
            sql &= "Contacts_3.Name AS SubmittedByCompany FROM Submittals LEFT OUTER JOIN "
            sql &= "Contacts AS Contacts_2 ON Submittals.SubmittedByID = Contacts_2.ContactID LEFT OUTER JOIN "
            sql &= "Contacts AS Contacts_1 ON Submittals.SubmittedToID = Contacts_1.ContactID LEFT OUTER JOIN "
            sql &= "Contacts ON Contacts_1.ParentContactID = Contacts.ContactID LEFT OUTER JOIN "
            sql &= "Contacts AS Contacts_3 ON Contacts_2.ParentContactID = Contacts_3.ContactID "
            sql &= "WHERE ProjectID = " & ProjectID & " ORDER BY DateSent DESC"

            Dim tbl As DataTable = db.ExecuteDataTable(sql)

  

            'Now look for attachments for each Submittal and if present then up the count
            Dim strPhysicalPath As String = ProcLib.GetCurrentAttachmentPath() & "DistrictID_" & httpcontext.current.Session("DistrictID")
            strPhysicalPath &= "/_apprisedocs/_Submittals/"

            Dim strRelativePath As String = ProcLib.GetCurrentRelativeAttachmentPath() & "DistrictID_" & httpcontext.current.Session("DistrictID")
            strRelativePath &= "/_apprisedocs/_Submittals/"

            'Add an attachments column to the result table
            Dim col As New DataColumn
            col.DataType = Type.GetType("System.String")
            col.ColumnName = "Attachments"
            tbl.Columns.Add(col)

            For Each row As datarow In tbl.rows
                Dim sPath As String = strPhysicalPath & "SubmittalID_" & row("SubmittalID") & "/"
                Dim sRelPath As String = strRelativePath & "SubmittalID_" & row("SubmittalID") & "/"
                Dim folder As New DirectoryInfo(sPath)
                If Not folder.Exists Then  'There are not any files
                    row("Attachments") = ""
                Else                'there could be files so get all and list

                    For Each fi As FileInfo In folder.GetFiles()
                        Dim sfilename As String = fi.name
                        If len(sfilename) > 20 Then
                            sfilename = Left(sfilename, 15) & "..." & Right(sfilename, 4)
                        End If

                        Dim sfilelink As String = "<a target='_new' href='" & sRelPath & fi.name & "'>"
                        row("Attachments") = sfilelink & sfilename & "</a>"
                    Next

                End If
            Next

            Return tbl

        End Function

        Public Function getContractSubmittalsCount(contractID As Integer) As DataTable
            sql = "Select SubmittalID From Submittals Where ContractID = " & contractID

            Return db.ExecuteDataTable(sql)
        End Function

        Public Function getAllProjectContracts(ProjectID As Integer, ContactType As String, contactID As Integer) As DataTable
            Dim sql As String = "Select contracts.ContractID, BidPackNumber, ContractorID, Contacts.Name AS Contractor, Contacts.Contact AS Contact "
            sql &= ", Contacts.Phone1, Contacts.Email, Contracts.Description, Contracts.Status,Districts.Name As DistrictName "
            sql &= " From Contracts "
            sql &= "Join Contacts On Contacts.ContactID=Contracts.ContractorID "
            sql &= "Join Districts On Contracts.DistrictID=Districts.DistrictID "
            sql &= "where Contracts.ProjectID = " & ProjectID
            sql &= " AND Exists(Select SubmittalID from Submittals Where Submittals.ContractID= Contracts.ContractID AND SubmittedToID=" & contactID & " AND Released=1)"

            If ContactType = "Design Professional" Then
                'sql &= " AND Exists(Select SubmittalID from Submittals Where Submittals.ContractID= Contracts.ContractID AND SubmittedToID=" & contactID & " AND Released=1)"
            End If

            If ContactType = "General Contractor" Then
                sql &= " AND Contracts.ContractorID = " & HttpContext.Current.Session("ParentContactID")
                'sql &= " AND Exists(Select SubmittalID, WorkFlowPosition from Submittals Where Submittals.ContractID= Contracts.ContractID AND SubmittedByID=" & contactID & ")"
            End If

            If ContactType = "Construction Manager" Then
                'sql &= " AND Exists(Select SubmittalID, WorkFlowPosition from Submittals Where Submittals.ContractID= Contracts.ContractID)"
            End If
 
 

            sql &= " Order By ContractID asc "
            Dim tbl As DataTable = db.ExecuteDataTable(sql)

            Return tbl
        End Function

        Public Sub setNewWorkflowStatus(submittalID As Integer, revision As Integer)
            If revision = 0 Then
                sql = "Update Submittals Set NewWorkflow = 'False' Where SubmittalID = " & submittalID
            ElseIf revision > 0 Then
                sql = "Update Submittals Set NewWorkflow = 'False' Where ParentSubmittalID = " & submittalID & " AND RevNo = " & revision
            End If
            db.ExecuteNonQuery(sql)
        End Sub

        Public Function getAllContractSubmittals(ByVal ContractID As Integer, contactID As Integer, contactType As String, typeSelect As String) As DataTable
            sql = "Select sub.SubmittalID, sub.SubmittalNo, sub.ContractID, sub.Description, sub.CreateDate, con.Name, sub.Released, "
            'This is used to get the revision data if it exists taking values from the most recent revision -----------
            sql &= "(case when (Select Max(rev.revno) from Submittals rev Where rev.ParentSubmittalID=sub.submittalID) is not Null"
            sql &= " Then (Select Max(rev.WorkFlowPosition) from Submittals rev Where rev.ParentSubmittalID=sub.submittalID"
            sql &= " AND rev.RevNo = (Select Max(rev.revno) from Submittals rev Where rev.ParentSubmittalID=sub.submittalID)) else sub.WorkFlowPosition end) as WorkFlowPosition, "

            sql &= "(case when (Select Max(rev.revno) from Submittals rev Where rev.ParentSubmittalID=sub.submittalID) is not Null"
            sql &= " Then (Select Max(rev.Status) from Submittals rev Where rev.ParentSubmittalID=sub.submittalID) else sub.Status end) as Status, "

            sql &= "(case when (Select Max(rev.revno) from Submittals rev Where rev.ParentSubmittalID=sub.submittalID) is not Null"
            sql &= " Then (Select Max(rev.DateRequired) from Submittals rev Where rev.ParentSubmittalID=sub.submittalID) else sub.DateRequired end) as DateRequired, "

            sql &= "(case when (Select Max(rev.revno) from Submittals rev Where rev.ParentSubmittalID=sub.submittalID) is not Null"
            sql &= " Then (Select Max(rev.RevNo) from Submittals rev Where rev.ParentSubmittalID=sub.submittalID) else sub.RevNo end) as RevNo, "

            sql &= "(case when (Select Max(rev.revno) from Submittals rev Where rev.ParentSubmittalID=sub.submittalID) is not Null"
            sql &= " Then (Select Max(rev.NewWorkflow) from Submittals rev Where rev.ParentSubmittalID=sub.submittalID) else sub.NewWorkflow end) as NewWorkflow "

            '-----------------------------------------------------------------

            sql &= " From Submittals sub "

            sql &= " JOIN Contacts con ON con.ContactID=sub.SubmittedById"
            sql &= " JOIN Contracts ON Contracts.ContractID=sub.ContractID "
            sql &= " JOIN Contacts cn ON cn.ContactID=" & contactID

            sql &= " Where sub.ContractID = " & ContractID

            If contactType = "General Contractor" Then
                sql &= " AND cn.ParentContactID=Contracts.ContractorID"
            End If

            If contactType = "General Contractor" Or contactType = "Construction Manager" Or contactType = "District" Then
                'sql &= " AND (1 = Case When WorkFlowPosition='None' AND sub.SubmittedById=" & contactID & " Then 1 "
                'sql &= "Else Case When WorkFlowPosition <> 'None' Then 1 Else 0 end end)"
                sql &= " AND (1 = Case When WorkFlowPosition='None' AND sub.SubmittedById=" & contactID & " Then 1 Else 0 end "
                sql &= "OR 1 = Case When WorkFlowPosition <> 'None' Then 1 Else 0 end)"
                'sql &= " AND RFIs.TransmittedByID = " & ContID
            End If

            If contactType = "ProjectManager" Then
                sql &= " AND (1 = Case When WorkFlowPosition='None' AND sub.SubmittedById=" & contactID & " Then 1 Else 0 end "
                sql &= "OR 1 = Case When WorkFlowPosition <> 'None' Then 1 Else 0 end)"
                'sql &= " AND (1 = Case When WorkFlowPosition='None' AND sub.SubmittedById=" & contactID & " Then 1 "
                'sql &= "Else Case When WorkFlowPosition <> 'None' Then 1 Else 0 end end)"
                'sql &= " AND WorkFlowPosition <> 'None' "
            End If

            If contactType = "Design Professional" And contactID > 0 Then
                sql &= " AND SubmittedToID = " & contactID
                sql &= " AND Released=1"
            End If

            Select Case typeSelect
                Case "Closed"
                    sql &= " AND ( sub.Status <> 'Closed' )"
                    'sql &= " AND WorkFlowPosition <> 'Complete'"
                Case Else
            End Select

            tbl = db.ExecuteDataTable(sql)

            Return tbl
        End Function

        Public Function insertNewSubmittal(obj As Object) As Integer
            Dim zObj As Object = obj

            sql = "Insert Into Submittals (ProjectID,DistrictID,SubmittalNo,ContractID) values(" & obj(11) & "," & obj(12) & ",'" & obj(1) & "'," & obj(0) & ")"
            sql &= " ;SELECT NewKey = Scope_Identity()"
            Dim recNum As Integer = db.ExecuteScalar(sql)

            updateSubmittal(zObj, recNum)

            Return recNum
        End Function

        Public Sub updateNextPosition(obj As Object)
            sql = "Update Submittals Set WorkFlowPosition = '" & obj(1) & "', LastUpdateOn = '" & Today & "', LastUpdateBy = " & obj(2)
            If obj(1) = "Complete" Then
                sql &= " , Status='Closed' "
            End If

            If obj(0) = "Revision" Then
                If obj(5) = "RevRelease" Then
                    sql &= " , Status='Active', Released=1 , ReleasedDate = '" & Today & "'"
                End If
                sql &= " Where SubmittalID = " & obj(3) 'obj(3) is the revision record number
            Else
                sql &= " Where SubmittalNo = '" & obj(0) & "'"
            End If

            db.ExecuteScalar(sql)

            If obj(0) = "Revision" Then 'This updates the parent work flow position or the previous revision.
                sql = "Update Submittals Set WorkFlowPosition = 'ForwardToRevision',LastUpdateOn = '" & Today & "', LastUpdateBy = " & obj(2)
                If obj(6) < 2 Then
                    sql &= " Where SubmittalID = " & obj(4) ' this is the current record submittalid. Need to swith to current revision base recordID also
                ElseIf obj(6) > 1 Then
                    sql &= " Where ParentSubmittalID = " & obj(4) & " AND RevNo = " & obj(6) - 1
                End If
                db.ExecuteScalar(sql)
            End If

            If obj(1) = "Complete" Then 'Close the root submittalID
                sql = "Update Submittals Set Status = 'Closed' Where SubmittalID=" & obj(4)
                db.ExecuteScalar(sql)
            End If

        End Sub

        Public Sub updateNewWorkflowStatus(submittalID As Integer, revision As Integer)
            If revision = 0 Then
                sql = "Update Submittals Set NewWorkflow='True' Where SubmittalID = " & submittalID
            ElseIf revision > 0 Then
                sql = "Update Submittals Set NewWorkflow='True' Where ParentSubmittalID = " & submittalID & " AND RevNo = " & revision
            End If

            db.ExecuteScalar(sql)

        End Sub

        Public Function checkRemarkStatus(submittalID As Integer, seq As Integer, revision As Integer) As String
            sql = "Select RemarkStatus from SubmittalRemarks Where submittalID=" & submittalID & " AND SequenceNum=" & seq & " AND Revision=" & revision
            Return db.ExecuteScalar(sql)
        End Function

        Public Function checkForRemarks(submittalID As Integer, sequence As Integer, contactID As Integer, revision As Integer) As DataTable
            sql = "Select RemarksID, ResponderID, RemarkStatus, Remark From SubmittalRemarks Where SubmittalID=" & submittalID & " AND SequenceNum=" & sequence & " AND Revision=" & revision
            sql &= " AND (1=Case when ResponderID=" & contactID & " AND submittalID=" & submittalID & " Then 1 else 0 end "
            sql &= " OR 1= case When SubmittalID=" & submittalID & " AND RemarkStatus='Released' then 1 else 0 end) "

            tbl = db.ExecuteDataTable(sql)
            Return tbl
        End Function

        Public Function checkDistrictApproval(submittalID As Integer, revision As Integer) As Object
            Dim obj(1) As Object
            sql = "Select RemarksID From SubmittalRemarks Where SubmittalID = " & submittalID & " AND SequenceNum=4 AND RemarkStatus='Released' AND Revision=" & revision
            obj(0) = db.ExecuteScalar(sql)
            sql = "Select RemarksID From SubmittalRemarks Where SubmittalID = " & submittalID & " AND SequenceNum=3 AND RemarkStatus='Released' AND Revision=" & revision
            obj(1) = db.ExecuteScalar(sql)

            Return obj
        End Function

        Public Sub cancelPendingRemarks(submittalID As Integer, seq As Integer, revision As Integer)
            sql = "Update SubmittalRemarks Set RemarkStatus='Canceled' Where SubmittalID = " & submittalID & " AND SequenceNum = " & seq & " AND RemarkStatus='Preparing'"
            sql &= " AND Revision = " & revision
            db.ExecuteScalar(sql)

        End Sub

        Public Function getSubmittalRemarks(submittalID As Integer, sequence As Integer, contactID As Integer, revision As Integer) As DataTable
            sql = "Select * From submittalRemarks Where SubmittalID = " & submittalID & " AND SequenceNum = " & sequence & " AND Revision = " & revision
            sql &= " AND (1=Case when ResponderID=" & contactID & " AND submittalID=" & submittalID & " AND RemarkStatus='Preparing' Then 1 else 0 end "
            sql &= " OR 1= case When SubmittalID=" & submittalID & " AND RemarkStatus='Released' then 1 else 0 end) "

            tbl = db.ExecuteDataTable(sql)

            Return tbl
        End Function

        Public Function getRemarksForSubmittal(submittalID As Integer, rev As Integer, contactID As Integer, wfp As String) As DataTable
            sql = "Select RemarksID, Remark, SequenceNum, ResponderID, RemarkType From SubmittalRemarks Where SubmittalID = " & submittalID & " AND Revision = " & rev
            sql &= " AND (1=Case when ResponderID=" & contactID & " AND submittalID=" & submittalID & " AND RemarkStatus='Preparing' Then 1 else 0 end "
            sql &= " OR 1= case When SubmittalID=" & submittalID & " AND RemarkStatus='Released' then 1 else 0 end) "
            sql &= " Order By SequenceNum "

            tbl = db.ExecuteDataTable(sql)

            Dim newrow As DataRow
            Dim addrow As Integer = 0
            If rev > 0 Then
                'newrow = tbl.NewRow
                'newrow("RemarksID") = -1
                'newrow("Remark") = ""
                'newrow("SequenceNum") = 0
                'tbl.Rows.InsertAt(newrow, 0)
                addrow = 1
            End If

            If tbl.Rows.Count > 0 Then
                'Add None Record
                newrow = tbl.NewRow
                newrow("RemarksID") = 0
                newrow("Remark") = ""
                newrow("SequenceNum") = 1

                tbl.Rows.InsertAt(newrow, 0)   'put it first
            End If

            Return tbl
        End Function

        Public Sub insertRemarks(obj As Object)
            sql = "Insert Into SubmittalRemarks (SubmittalID,Remark,LastUpdateDate,LastUpdatedBy,SequenceNum,ResponderID,Revision,RemarkStatus,RemarkType,ReturnedOn)"
            sql &= " values(" & obj(7) & ",'" & "" & "','" & Today & "'," & obj(0)
            sql &= "," & obj(9) & "," & obj(0) & "," & obj(10) & ",'" & obj(8) & "','" & obj(6) & "','" & Today & "')"

            db.ExecuteNonQuery(sql)

            sql = "Select RemarksID From SubmittalRemarks Where SubmittalID = " & obj(7) & " AND Revision = " & obj(10) & " AND SequenceNum = " & obj(9)
            Dim remNo As Integer = db.ExecuteScalar(sql)
            updateNewRemark(obj(5), remNo)

        End Sub

        Public Sub updateNewRemark(remark As String, remID As Integer)
            sql = "Update SubmittalRemarks Set Remark = @remarks Where RemarksID = @remID"

            Dim connStr As String = ProcLib.GetDataConnectionString()
            'connStr = System.Configuration.ConfigurationManager.AppSettings("MaascoVMDev1ConnectionString")

            Dim sqlConn As New SqlConnection(connStr)
            Using sqlConn
                Using comm As New SqlCommand()
                    With comm
                        .Connection = sqlConn
                        .CommandType = CommandType.Text
                        .CommandText = sql
                        comm.Parameters.Add("@remarks", SqlDbType.NChar).Value = remark
                        .Parameters.Add("@remID", SqlDbType.Int).Value = remID
                    End With
                    sqlConn.Open()
                    comm.ExecuteNonQuery()
                    sqlConn.Close()
                End Using
            End Using

        End Sub

        Public Sub createDistrictPlaceholder(submittalID As Integer, contactID As Integer, rev As Integer)
            Dim remark As String = "District approval is not required" & vbCrLf & vbCrLf & "Auto Generated By The System:"

            sql = "insert into SubmittalRemarks(SubmittalID,LastUpdateDate,LastUpdatedBy,SequenceNum,ResponderID, ReturnedOn,Revision,RemarkStatus,RemarkType,Remark)"
            sql &= " Values(" & submittalID & ",'" & Today & "'," & contactID & ",4,0,'" & Today & "'," & rev & ",'Released','DistrictAutoRemark','" & remark & "')"

            db.ExecuteNonQuery(sql)
        End Sub

        Public Sub updateRemarks(obj As Object)
            sql = "Update SubmittalRemarks Set Remark = '" & obj(5) & "', LastUpdateDate = '" & Today & "', RemarkStatus = '" & obj(8) & "', RemarkType = '" & obj(6)
            sql &= "', ReturnedOn = '" & Today
            sql &= "' Where RemarksID = " & obj(11)

            'db.ExecuteNonQuery(sql)
            updateRemarks_V3(obj)

        End Sub

        Public Sub updateRemarks_V3(obj As Object)
            sql = "Update SubmittalRemarks Set Remark = @remark, LastUpdateDate = @today, RemarkStatus = @remstatus, RemarkType = @remtype, ReturnedOn = @today"
            sql &= " Where RemarksID = @remID "

            'Dim connStr As String = System.Configuration.ConfigurationManager.AppSettings("MaascoVMDev1ConnectionString")
            Dim connStr As String = ProcLib.GetDataConnectionString()

            Dim sqlConn As New SqlConnection(connStr)
            Using sqlConn
                Using comm As New SqlCommand()
                    With comm
                        .Connection = sqlConn
                        .CommandType = CommandType.Text
                        .CommandText = sql
                        comm.Parameters.Add("@remark", SqlDbType.NChar).Value = obj(5)
                        .Parameters.Add("@today", SqlDbType.NChar).Value = Today
                        .Parameters.Add("@remstatus", SqlDbType.NChar).Value = obj(8)
                        .Parameters.Add("@remtype", SqlDbType.NChar).Value = obj(6)
                        .Parameters.Add("@remID", SqlDbType.Int).Value = obj(11)
                    End With
                    sqlConn.Open()
                    comm.ExecuteNonQuery()
                    sqlConn.Close()
                End Using
            End Using
        End Sub

        Public Sub updateRemarks_V2(obj As Object)
            'Only call this on revision 0.

            sql = "Update Submittals Set Remarks = @remarks , Description = @desc Where SubmittalNO = @subNo"

            'Dim connStr As String = System.Configuration.ConfigurationManager.AppSettings("MaascoVMDev1ConnectionString")
            Dim connStr As String = ProcLib.GetDataConnectionString()

            Dim sqlConn As New SqlConnection(connStr)
            Using sqlConn
                Using comm As New SqlCommand()
                    With comm
                        .Connection = sqlConn
                        .CommandType = CommandType.Text
                        .CommandText = sql
                        comm.Parameters.Add("@remarks", SqlDbType.NChar).Value = obj(10)
                        .Parameters.Add("@desc", SqlDbType.NChar).Value = obj(6)
                        .Parameters.Add("@subNo", SqlDbType.NChar).Value = obj(1)
                    End With
                    sqlConn.Open()
                    comm.ExecuteNonQuery()
                    sqlConn.Close()
                End Using
            End Using
        End Sub

        Public Sub updateRevisionDateRequired(zDate As DateTime, revSubmittalNum As Integer)
            sql = "Update Submittals Set DateRequired = '" & zDate & "' Where SubmittalID = " & revSubmittalNum
            db.ExecuteNonQuery(sql)
        End Sub

        Public Sub updateAssignedTo(obj As Object)
            sql = "Update Submittals Set  LastUpdateBy = " & obj(0) & ", LastUpdateOn = '" & Today & "', DistrictApproval='" & obj(12) & "' "
            If obj(3) <> "No Change" Then
                sql &= " , WorkFlowPosition = '" & obj(3) & "'"
            End If

            If obj(1) > 1 Then
                sql &= ", SubmittedToId = " & obj(1)
            End If

            If obj(1) = 1 Then
                sql &= " , DateRequired = '" & obj(13) & "' "
            End If

            If obj(4) = 1 Then
                sql &= " , Released = " & obj(4)
            End If
            sql &= " Where SubmittalNo = '" & obj(2) & "'"

            db.ExecuteScalar(sql)

        End Sub

        Public Function checkAndSetDateType(dateType As String, submittalID As Integer, revision As Integer) As Date
            sql = "Select " & dateType & " From Submittals "
            If revision = 0 Then
                sql &= " Where SubmittalID = " & submittalID
            ElseIf revision > 0 Then
                sql &= " Where ParentSubmittalID = " & submittalID & " AND RevNo = " & revision
            End If
            Dim zDate As Date = db.ExecuteScalar(sql)

            Return zDate
        End Function

        Public Function stampDate(dateType As String, submittalID As Integer, revision As Integer) As String
            sql = "Update Submittals Set " & dateType & " = '" & Today & "'"
            If revision > 0 Then
                sql &= " Where ParentSubmittalID = " & submittalID & " AND RevNo = " & revision
            ElseIf revision = 0 Then
                sql &= " Where SubmittalID = " & submittalID
            End If
            db.ExecuteNonQuery(sql)
            Return sql

        End Function

        Public Function updateSubmittal(obj As Object, recNum As Integer) As String
            sql = "Update Submittals Set SubmittedByID = " & obj(3) & ",  SubmittedToID = " & obj(5)
            'sql &= ", Description = '" & obj(6) & "', SpecificationPackage = '" & obj(7) & "', SpecSection = '" & obj(8) & "', RevNo = '" & obj(9) & "',"
            sql &= ", SpecificationPackage = '" & obj(7) & "', SpecSection = '" & obj(8) & "', RevNo = '" & obj(9) & "',"
            'sql &= " Remarks = '" & obj(10) & "', DateRequired = '" & obj(2) & "'"
            sql &= " DateRequired = '" & obj(2) & "'"
            sql &= " , LastUpdateOn = '" & obj(4) & "', LastUpdateBy = " & obj(3)

            sql &= ", CreateDate = '" & obj(4) & "', WorkFlowPosition = '" & obj(21) & "'"
            sql &= ", Status = '" & obj(13) & "', SampleProvided = '" & obj(23) & "', SampleDescription = '" & obj(24) & "'"

            If obj(20) = "Edit" Then
                sql &= ", NoOfCopiesReceived = '" & obj(14) & "', NoOfCopiesSent = '" & obj(15) & "' "

                sql &= ", ShipDate = '" & obj(16) & "', DateSent = '" & obj(17) & "', DateReturned = '" & obj(18) & "' "
                sql &= ", DateReceived = '" & obj(19) & "'"

            End If


            sql &= " Where SubmittalNO = '" & obj(1) & "'"

            db.ExecuteScalar(sql)

            updateRemarks_V2(obj)

            Return sql

        End Function

        Public Function getSubmittalData(submittalID As Integer) As DataTable
            sql = "Select * From Submittals sub "
            'sql &= "JOIN Contacts con On Contacts.ContactID = Submittals.SubmittedById "
            sql &= "Where SubmittalID = " & submittalID
            tbl = db.ExecuteDataTable(sql)

            Return tbl
        End Function

        Public Function getContactName(contactID As Integer) As Object
            Dim obj(1) As Object
            sql = "Select Name, ContactType From contacts Where ContactID=" & contactID
            Dim tbl As DataTable = db.ExecuteDataTable(sql)
            obj(0) = tbl.Rows(0).Item("Name")
            obj(1) = tbl.Rows(0).Item("ContactType")

            Return obj
        End Function

        Public Function checkForRevision(submittalID As Integer) As Integer
            sql = "Select SubmittalID From Submittals Where ParentSubmittalID = " & submittalID & " Order By RevNo"
            Dim tbl As DataTable = db.ExecuteDataTable(sql)
            Dim count As Integer = tbl.Rows.Count

            Return count
        End Function

        Public Function checkForPreparingRevision(submittalID As Integer) As Integer
            sql = "Select SubmittalID From Submittals Where ParentSubmittalID=" & submittalID & " AND Status='Preparing'"
            tbl = db.ExecuteDataTable(sql)
            Dim count As Integer = tbl.Rows.Count
            Return count
        End Function

        Public Function getRevisionRecordNumber(parentSubNum As Integer, revNum As Integer) As Integer
            sql = "Select SubmittalID From Submittals Where ParentSubmittalID=" & parentSubNum & " AND RevNo=" & revNum
            Dim recNum As Integer = db.ExecuteScalar(sql)

            Return recNum
        End Function

        Public Function getSubmittalRevisionData(submittalID As Integer, revision As Integer) As DataTable
            sql = "Select sub.SubmittalNo, sub.ContractID, sub.SpecificationPackage, sub.Description, sub.SpecSection, sub.DistrictApproval, sub.SampleProvided, sub.SampleDescription, "
            sql &= " rev.Released, rev.ReleasedDate, sub.SubmittedToId, sub.SubmittedById, rev.Remarks, rev.Status, rev.WorkFlowPosition, rev.RevNo, "
            sql &= "rev.DateRequired,rev.NoOfCopiesReceived,rev.NoOfCopiesSent,rev.ShipDate,rev.DateSent,rev.DateReturned,rev.DateReceived "
            sql &= " From Submittals sub JOIN Submittals rev on rev.ParentSubmittalID=sub.SubmittalID "
            sql &= " Where sub.SubmittalID=" & submittalID & " AND rev.RevNo=" & revision

            tbl = db.ExecuteDataTable(sql)

            Return tbl
        End Function

        Public Function getSubmittalRevisions(submittalID As Integer) As DataTable
            sql = "Select RevNo From Submittals Where ParentSubmittalID = " & submittalID & " order by RevNo "

            tbl = db.ExecuteDataTable(sql)
            'Add None Record
            Dim newrow As DataRow = tbl.NewRow
            newrow("RevNo") = 0

            tbl.Rows.InsertAt(newrow, 0)   'put it first

            Return tbl
        End Function

        Public Function insertRevision(obj As Object) As String
            sql = "Insert Into Submittals(ParentSubmittalID,ContractID,RevNo,SubmittedToID,SubmittedByID,Status,WorkFlowPosition,LastUpdateOn,LastUpdateBy,DateRequired)"
            sql &= " values(" & obj(0) & ",0," & obj(1) & ",0," & obj(2) & ",'" & obj(3) & "','" & obj(4) & "','" & Now & "'," & obj(2) & ",'" & obj(5) & "')"

            db.ExecuteNonQuery(sql)
            sql = "Select SubmittalID From Submittals Where ParentSubmittalID = " & obj(0) & " AND RevNo = " & obj(1)
            Dim subID As Integer = db.ExecuteScalar(sql)
            updateRevisionRemark(obj(6), subID)

            Return ""
        End Function

        Public Function updateRevision(obj As Object) As String
            sql = "Update Submittals Set ShipDate = '" & obj(4) & "', DateReceived = '" & obj(5) & "', DateRequired = '" & obj(6) & "'"
            'sql &= ", DateReturned = '" & obj(7) & "', DateSent = '" & obj(8) & "', Remarks = '" & obj(3) & "'"
            sql &= ", DateReturned = '" & obj(7) & "', DateSent = '" & obj(8) & "'"

            If obj(9) <> "No Change" Then
                sql &= ", WorkFlowPosition = '" & obj(9) & "', Status='Active', Released=1, ReleasedDate='" & Today & "'"
            End If

            sql &= " Where ParentSubmittalID = " & obj(0) & " AND RevNo = " & obj(1)

            db.ExecuteNonQuery(sql)

            sql = "Select SubmittalID From Submittals Where ParentSubmittalID = " & obj(0) & " AND RevNo = " & obj(1)
            Dim subID As Integer = db.ExecuteScalar(sql)
            updateRevisionRemark(obj(3), subID)

            Return ""
        End Function

        Public Sub updateRevisionRemark(remark As String, subID As Integer)
            sql = "Update Submittals Set Remarks = @remarks Where SubmittalID = @subID"

            'Dim connStr As String = System.Configuration.ConfigurationManager.AppSettings("MaascoVMDev1ConnectionString")
            Dim connStr As String = ProcLib.GetDataConnectionString()

            Dim sqlConn As New SqlConnection(connStr)
            Using sqlConn
                Using comm As New SqlCommand()
                    With comm
                        .Connection = sqlConn
                        .CommandType = CommandType.Text
                        .CommandText = sql
                        comm.Parameters.Add("@remarks", SqlDbType.NChar).Value = remark
                        .Parameters.Add("@subID", SqlDbType.Int).Value = subID
                    End With
                    sqlConn.Open()
                    comm.ExecuteNonQuery()
                    sqlConn.Close()
                End Using
            End Using


        End Sub


        Public Sub GetSubmittalForEdit(ByVal SubmittalID As Integer, ByVal ProjectID As Integer)

            'db.FillNewRADComboBox("SELECT ContractorID as Val, Name as Lbl FROM Contractors WHERE DistrictID = " & HttpContext.Current.Session("DistrictID") & " ORDER BY Name", CallingPage.FindControl("cboSubmittedToContractorID"), True, True)
            'db.FillRADListBox("SELECT LookupValue as Val, LookupTitle as Lbl FROM Lookups WHERE ParentTable='Submittals' AND ParentField = 'Status' AND DistrictID = 0", CallingPage.FindControl("cboStatusList"))


            If SubmittalID > 0 Then

                'db.FillForm(CallingPage.FindControl("Form1"), "SELECT * FROM Submittals WHERE SubmittalID = " & SubmittalID)

            End If


        End Sub



        Public Sub SaveSubmittal(ByVal ProjectID As Integer, ByVal SubmittalID As Integer)


            Dim sql As String = ""
            If SubmittalID = 0 Then   'new record
                sql = "INSERT INTO Submittals (DistrictID, ProjectID) "
                sql &= "VALUES (" & HttpContext.Current.Session("DistrictID") & "," & ProjectID & ")"
                sql &= ";SELECT NewKey = Scope_Identity()"

                SubmittalID = db.ExecuteScalar(sql)

            End If

            'Update record
            db.SaveForm(CallingPage.Form, "SELECT * FROM Submittals WHERE SubmittalID = " & SubmittalID)

            'HACK: Update the status field -- need to update dbhelper to handle hidden fields
            Dim txtStatus As HiddenField = CallingPage.Form.FindControl("txtStatus")
            sql = "UPDATE Submittals SET Status = '" & txtStatus.Value & "' WHERE SubmittalID = " & SubmittalID
            db.ExecuteNonQuery(sql)


        End Sub

        Public Sub DeleteSubmittal(ByVal ProjectID As Integer, ByVal SubmittalID As Integer)


            Dim strPhysicalPath As String = ProcLib.GetCurrentAttachmentPath() & "DistrictID_" & HttpContext.Current.Session("DistrictID")
            strPhysicalPath &= "/_apprisedocs/_Submittals/SubmittalID_" & SubmittalID & "/"
            Dim fileinfo As New FileInfo(strPhysicalPath)
            If fileinfo.Exists Then
                IO.File.Delete(strPhysicalPath)     'delete the file
            End If

            db.ExecuteNonQuery("DELETE FROM Submittals WHERE SubmittalID = " & SubmittalID)

        End Sub


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
