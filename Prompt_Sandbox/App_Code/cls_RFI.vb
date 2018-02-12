Imports System
Imports System.Web
Imports System.Web.UI.WebControls
Imports System.IO
Imports System.Data
Imports System.Data.SqlClient
Imports Telerik.Web.UI
Imports System.Timers
Imports System.Net.Mail


Namespace Prompt

    '********************************************
    '*  RFI Class
    '*  
    '*  Purpose: Processes data for the RFI Objects
    '*
    '*  Last Mod By:    Ford James
    '*  Last Mod On:    07/12/09
    '*
    '********************************************

    Public Class RFI
        Implements IDisposable

        'Properties
        Public CallingPage As Page
        Public CallingUserControl As UserControl   'used for refernce to dynamic UC as cannot get through calling page
        Public Reader As SqlDataReader
        Public DataTable As DataTable

        Private db As PromptDataHelper
        Private Shared aTimer As System.Timers.Timer

        Public Sub New()
            db = New PromptDataHelper

        End Sub

#Region "Project RFIs"

        Public Function jqTest() As String
            Return "This"
        End Function

        Public Function configResponseSave(rfiid As Integer, contactID As Integer, rev As Integer, override As Integer) As Object
            Dim sql As String
            Dim tbl As DataTable
            Dim rStatus As String
            Dim Seq As Integer
            Dim saveType As String
            Dim count As Integer = 0
            Dim isAnswer As Integer
            Dim zAnswer As String
            Dim ansID As Integer
            Dim overHold As Integer = 0

            Dim obj(5) As Object

            If override = 1 Then
                If rev = 0 Then
                    sql = "Select RFIID From RFIs Where RFIID=" & rfiid & " AND ResponseStatus='Hold' AND RespondedBy!=" & contactID
                ElseIf rev > 0 Then
                    sql = "Select QuestionID From RFIQuestions Where RFIID=" & rfiid & " AND ResponseStatus='Hold' AND RespondedBy!=" & contactID
                End If
                tbl = db.ExecuteDataTable(sql)
                If tbl.Rows.Count > 0 Then
                    overHold = 1
                End If
                If overHold = 0 Then
                    sql = "Select AnswerID From RFIAnswers Where RFIID=" & rfiid & " AND Revision=" & rev & " AND ResponseStatus='Hold' AND ResponderID!=" & contactID
                    tbl = db.ExecuteDataTable(sql)
                    If tbl.Rows.Count > 0 Then
                        overHold = 2
                    End If
                End If
            End If

            If rev = 0 Then
                sql = "Select ResponseStatus From RFIs Where RFIID=" & rfiid
            ElseIf rev > 0 Then
                sql = "Select ResponseStatus From RFIQuestions Where RFIID=" & rfiid & " AND Revision=" & rev
            End If
            rStatus = db.ExecuteScalar(sql) ' Checking to see if the response in the root table is canceled.

            If Trim(rStatus) = "Canceled" Then
                Seq = Seq + 1
            Else
                Seq = Seq + 2
            End If

            If rev = 0 Then
                sql = "Select Answer From RFIs Where RFIID=" & rfiid & " AND RespondedBy=" & contactID & " AND ResponseStatus='Hold'"
                tbl = db.ExecuteDataTable(sql)
            ElseIf rev > 0 Then
                sql = "Select Answer From RFIQuestions Where RFIID=" & rfiid & " AND RespondedBy=" & contactID & " AND ResponseStatus='Hold'"
                tbl = db.ExecuteDataTable(sql)
            End If
            count = tbl.Rows.Count
            isAnswer = count
            If count = 1 Then
                If rev > 0 Then
                    saveType = "b"
                    Seq = 1
                ElseIf rev = 0 Then
                    saveType = "a"
                    Seq = 1
                End If
                zAnswer = tbl.Rows(0).Item("Answer")
            ElseIf count = 0 Then 'chck for a record in the RFIAnswer table
                sql = "Select AnswerID, Answer, SequenceNum From RFIAnswers Where RFIID=" & rfiid & " AND ResponderID=" & contactID & " AND ResponseStatus='Hold'"
                tbl = db.ExecuteDataTable(sql)
                count = tbl.Rows.Count
                isAnswer = count
                Try
                    ansID = tbl.Rows(0).Item("AnswerID")
                Catch ex As Exception
                    ansID = 0
                End Try

                If count = 1 Then
                    saveType = "c" 'update the RFIAnswer table
                    Seq = tbl.Rows(0).Item("SequenceNum")
                    zAnswer = tbl.Rows(0).Item("Answer")
                ElseIf count = 0 Then
                    If rStatus = "" Then 'no response in the RFI or RFIQuestions table
                        If rev > 0 Then
                            saveType = "b"
                            Seq = 1
                        ElseIf rev = 0 Then
                            saveType = "a"
                            Seq = 1
                        End If
                    Else
                        saveType = "d"
                        Try
                            Seq = getSequence(rfiid, rev) + 1
                        Catch ex As Exception
                            If rStatus = "Canceled" Then
                                Seq = 1
                            Else
                                Seq = 2
                            End If
                        End Try
                        If overHold = 1 Then
                            Seq = 1
                        ElseIf overHold = 2 Then
                            Seq = getSequence(rfiid, rev)
                        End If
                    End If
                End If
            End If
            obj(0) = saveType
            obj(1) = Seq
            obj(2) = isAnswer
            obj(3) = zAnswer
            obj(4) = ansID

            Return obj
        End Function

        Public Function getSequence(rfiid As Integer, rev As Integer) As Integer
            Dim seq As Integer
            Dim sql = "Select Max(SequenceNum) from RFIAnswers Where RFIID=" & rfiid & " AND Revision=" & rev & " AND ResponseStatus!='Canceled'"
            seq = db.ExecuteScalar(sql)

            Return seq
        End Function

        Public Function BuildActionDropdown(ContactType As String, WFP As String) As DataTable
            Dim tbl As DataTable

            Dim newrow As DataRow = tbl.NewRow
            newrow("Action") = "AssignDP"
            newrow("ActionText") = "Assign To DP"
            tbl.Rows.InsertAt(newrow, 0)

            newrow("Action") = "AddResponseDP"
            newrow("ActionText") = "Add Response & Assign To DP"
            tbl.Rows.InsertAt(newrow, 1)
            Return tbl
        End Function

        Public Sub saveRequiredDate(reqDate As String, rfiid As Integer, rev As Integer)
            Dim sql As String
            If rev = 0 Then
                sql = "Update RFIs Set RequiredBy='" & reqDate & "' Where RFIID=" & rfiid
            Else
                sql = "Update RFIQuestions Set RequiredBy='" & reqDate & "' Where RFIID=" & rfiid & " AND Revision=" & rev
            End If

            db.ExecuteNonQuery(sql)
        End Sub

        Public Function getActiveRFIRevision(rfiID As Integer) As Integer
            Dim sql As String = ""
            Dim rev As Integer = -1
            Dim status As String = ""

            sql = "Select RequestStatus From RFIs Where RFIID = " & rfiID
            status = db.ExecuteScalar(sql)
            If status = "Active" Then
                rev = 0
            Else
                sql = "Select RequestStatus, Revision From RFIQuestions Where RFIID = " & rfiID & " AND RequestStatus='Active' "
                Dim tbl As DataTable = db.ExecuteDataTable(sql)
                If tbl.Rows.Count > 0 Then
                    rev = tbl.Rows(0).Item("Revision")
                Else
                    rev = 0
                End If

            End If

            Return rev
        End Function

        Public Function checkReportsAccess(userID As Integer, distID As Integer) As Boolean
            Dim sql As String = "Select ContactType From Contacts Where UserID = " & userID & " AND DistrictID = " & distID
            Dim isAccess As Boolean
            Dim conType = db.ExecuteScalar(sql)

            If conType = "Construction Manager" Or conType = "General Contractor" Or conType = "Design Professional" Then
                isAccess = False
            Else
                isAccess = True
            End If

            Return isAccess
        End Function

        Public Function getCM(ByVal projectID As Integer, contractID As Integer) As Object
            Dim contractorID As Integer
            Dim sql As String = "Select CMID, PM From Projects where ProjectID = " & projectID
            Dim tbl As DataTable = db.ExecuteDataTable(sql)
            If contractID > 0 Then
                sql = "Select ContractorID from Contracts Where ContractID = " & contractID
                contractorID = db.ExecuteScalar(sql)
            End If

            Dim thObj(3) As Object
            thObj(0) = tbl.Rows(0).Item("CMID")
            If contractID > 0 Then
                thObj(1) = contractorID
                thObj(2) = tbl.Rows(0).Item("PM")
            End If

            Return thObj
        End Function

        Public Function getPMAndCMid(projectID As Integer) As Object
            Dim sql = "Select PM from Projects Where ProjectID = " & projectID
            Dim PMID As Integer = db.ExecuteScalar(sql)
            sql = "Select TeamMembers.ContactID From TeamMembers JOIN Contacts ON Contacts.ContactID=TeamMembers.ContactID "
            sql &= "Where projectID = " & projectID & " AND Contacts.ContactType = 'Construction Manager'"
            Dim CMID As Integer = db.ExecuteScalar(sql)
            Dim thObj(2) As Object
            thObj(0) = CMID
            thObj(1) = PMID
            Return thObj
        End Function

        Public Function getContactID(UserID As Integer, DistrictID As Integer) As Integer
            Dim sql As String = "Select ContactID From Contacts Where UserID = " & UserID
            sql &= " AND DistrictID = " & DistrictID
            Dim ContactID As Integer = db.ExecuteScalar(sql)
            Return ContactID
        End Function

        Public Function getContactData(ContactID As Integer, DistrictID As Integer) As Object
            Dim sql = "Select Contacts.ParentContactID, Contacts.ContactType, cn.Name, Contacts.Phone1, Contacts.Cell, Contacts.Name as fullName, Contacts.Email from Contacts "
            sql &= " JOIN Contacts as cn On cn.ContactID = Contacts.ParentContactID "
            sql &= "Where Contacts.ContactID = " & ContactID
            Dim ContactData As DataTable
            Dim SendData(5) As Object
            Try
                ContactData = db.ExecuteDataTable(sql)
                SendData(0) = ContactData.Rows(0).Item("ParentContactID")
                SendData(1) = ContactData.Rows(0).Item("ContactType")
                SendData(2) = ContactData.Rows(0).Item("fullName")
                SendData(3) = ContactData.Rows(0).Item("Phone1")
                SendData(4) = ContactData.Rows(0).Item("Cell")
                SendData(5) = ContactData.Rows(0).Item("Email")
            Catch
                SendData(0) = 0
                SendData(1) = ""
                SendData(2) = ""
            End Try

            Return SendData
        End Function

        Public Function getTeamContactData(disID As Integer, ContactID As Integer, projectID As Integer) As Object
            Dim sql As String = "Select tm.TeamGroupName, con.ParentContactID, con.Name,  "
            sql &= " From TeamMembers tm JOIN Contacts con ON con.ContactID=tm.ContactID "
            sql &= " JOIN Contacts cn ON cn.ContactID=con.ParentContactID "
            sql &= " Where tm.ProjectID=" & projectID & " AND tm.DistrictID=" & disID & " AND tm.ContactID=" & ContactID
            Dim tbl As DataTable
            Dim dataObj(5) As Object
            Try
                tbl = db.ExecuteDataTable(sql)
                dataObj(0) = tbl.Rows(0).Item("ParentContactID")
                dataObj(1) = tbl.Rows(0).Item("TeamGroupName")
                dataObj(2) = tbl.Rows(0).Item("Name")
            Catch ex As Exception
                dataObj(0) = 0
                dataObj(1) = ""
                dataObj(2) = ""
            End Try
            Return dataObj
        End Function

        Public Sub cancelOpenRevisions(contactID As Integer, nRFIID As Integer)
            'Dim sql = "Select QuestionID From RFIQuestions Where RFIID = " & nRFIID & " AND SubmittedByID = " & contactID & " AND RequestStatus = 'Preparing' "
            Dim sql = "Select QuestionID From RFIQuestions Where RFIID = " & nRFIID & " AND RequestStatus = 'Preparing' "
            Dim tbl As DataTable = db.ExecuteDataTable(sql)
            If tbl.Rows.Count > 0 Then
                sql = "Update RFIQuestions Set Revision=0, RequestStatus='Canceled' Where QuestionID = " & tbl.Rows(0).Item("QuestionID")
                db.ExecuteNonQuery(sql)
            End If

        End Sub

        Public Function checkForRevisions(ByVal RFIID As Integer) As Integer
            Dim nextRevision As Integer
            If db.ExecuteScalar("SELECT MAX(Revision) from RFIQuestions Where RFIID = " & RFIID) Is DBNull.Value Then
                nextRevision = 0
            Else
                nextRevision = db.ExecuteScalar("SELECT MAX(Revision) from RFIQuestions Where RFIID = " & RFIID)
            End If
            Return nextRevision
        End Function

        Public Sub sessionStart(contactID As Integer, RFIID As Integer, WFP As String, sessID As String)
            Dim sql As String = "Insert Into RFIEditSessions (ContactID,EditSessionID,StartTime,EditStatus,RFIID,WorkFlowPosition)"
            sql &= " values (" & contactID & ",'" & sessID & "','" & Now() & "','Active'," & RFIID & ",'" & WFP & "')"
            db.ExecuteNonQuery(sql)
        End Sub

        Public Sub sessionEnd(RFIID As Integer, sessID As String, contactID As Integer)
            Dim sql As String = "Update RFIEditSessions set EditStatus='Closed', EndTime = '" & Now() & "'"
            'sql &= " Where RFIID = " & RFIID & " AND EditSessionID = '" & sessID & "' AND EditStatus = 'Active' AND ContactID = " & contactID
            sql &= " Where RFIID = " & RFIID & " AND EditStatus = 'Active' AND ContactID = " & contactID

            db.ExecuteNonQuery(sql)
        End Sub

        Public Function getRFIRequiredBy(ByVal RFIID As Integer) As String
            Dim sql As String = "Select RequiredBy From RFIs Where RFIID = " & RFIID
            Dim ReqBy As String = db.ExecuteScalar(sql)
            Return ReqBy
        End Function

        Public Function getRFIData(ByVal RFIID As Integer) As DataTable
            Dim rfiData As DataTable
            Dim sql As String = "Select Question, SubmittedToID,TransmittedByID, y.name as FromName, y.Email, y.Phone1, ReceivedOn, RequiredBy, RefNumber, "
            sql &= "Proposed, ReturnedOn, Answer, Status, RespondedBy, WorkFlowPosition, RequestStatus, ResponseStatus,ResponseType, RFIType, CMShowToGC, "
            sql &= "ContractID, ToDPReleaseDate, ToGCReleaseDate, RequestReleaseDate, ReturnedOn, ClosedOn, TransmittedByID, AltRefNumber From RFIs"
            sql &= " Join Contacts y on y.ContactID = RFIs.TransmittedByID "
            sql &= " Where RFIID = " & RFIID
            rfiData = db.ExecuteDataTable(sql)

            'sql = "Select Revision, WorkFlowPosition From RFIQuestions Where RFIID = " & RFIID & " order By Revision"
            'Dim Que As DataTable = db.ExecuteDataTable(sql)

            Dim col As New DataColumn
            col.DataType = Type.GetType("System.String")
            col.ColumnName = "WFPosition"
            rfiData.Columns.Add(col)

            'If Que.Rows.Count > 0 Then
            'rfiData.Rows(0).Item("WFPosition") = Que.Rows(Que.Rows.Count - 1).Item("WorkFlowPosition")
            'row("Revision") = Que.Rows.Count
            'Else
            Try
                rfiData.Rows(0).Item("WFPosition") = rfiData.Rows(0).Item("WorkFlowPosition")
            Catch ex As Exception
            End Try

            'End If

            Return rfiData
        End Function

        Public Function getCheckBoxData(ByVal RFIID As Integer) As DataTable
            Dim sql As String
            Dim zData As DataTable

            sql = "Select * From RFICheckBox Where RFIID = " & RFIID
            zData = db.ExecuteDataTable(sql)

            Return zData
        End Function

        Public Function checkForCheckBoxRecord(RFIID As Integer) As String
            Dim sql As String
            Dim isRecord As String

            sql = "Select RecordNumber From RFICheckBox Where RFIID = " & RFIID
            Dim tbl As DataTable = db.ExecuteDataTable(sql)
            If tbl.Rows.Count > 0 Then
                isRecord = "True"
            Else
                isRecord = "False"
            End If

            Return isRecord
        End Function

        Public Function checkForActiveRFISession(RFIID As Integer, contactID As Integer) As DataTable
            Dim sql As String = "Select * From RFIEditSessions Where EditStatus='Active' AND RFIID = " & RFIID
            Dim tbl As DataTable = db.ExecuteDataTable(sql)

            Return tbl
        End Function

        Public Sub closeEditSession(RFIID As Integer, contactID As Integer, sessionID As String)
            Dim sql As String = "Update RFIEditSessions Set EditStatus='Closed' Where RFIID = " & RFIID
            sql &= " AND ContactID = " & contactID & " AND EditStatus='Active'"
            db.ExecuteNonQuery(sql)

        End Sub

        Public Sub updateRFICMShowToGC(nRFIID As Integer, nContactID As Integer, show As Integer)
            Dim sql As String = "Update RFIs Set CMShowToGC = '" & show & "', CMShowToGCBy = " & nContactID & " , CMShowToGCDate = '" & Now() & "', NewWorkflow='True'"
            sql &= ", PMNewWorkFlow='True', WorkFlowPosition='GC:Acceptance Pending' "
            sql &= " Where RFIID = " & nRFIID
            db.ExecuteNonQuery(sql)
        End Sub

        Public Function getSubmittedTo(submittedTo As Integer) As String
            Dim sql As String = "Select name from contacts where contactID = " & submittedTo
            Dim rfiData As String = db.ExecuteScalar(sql)

            Return rfiData
        End Function
        Public Function CheckRFIAnswerData(RFIID As Integer, Rev As Integer) As String
            Dim sql As String = "Select ResponseStatus From RFIAnswers Where RFIID=" & RFIID & " AND Revision=" & Rev
            Dim stat As String = db.ExecuteScalar(sql)

            Return stat
        End Function
        Public Function getReturnedBy(ByVal ReturnedBy As Integer) As String
            Dim sql As String = "Select name from Contacts Where ContactID = " & ReturnedBy
            Dim rfiData As String = db.ExecuteScalar(sql)
            Return rfiData
        End Function

        Public Function checkForExistingRevision(contactID As Integer, RFIID As Integer) As DataTable
            Dim sql As String
            Dim isRev As DataTable
            sql = "Select RFIID, RequestStatus, Revision from RFIQuestions where RFIID = " & RFIID & " AND SubmittedByID = " & contactID & " AND RequestStatus = 'Preparing'"
            isRev = db.ExecuteDataTable(sql)
            Return isRev
        End Function

        Public Function checkForDPSolution(RFIID As Integer, Revision As Integer) As DataTable
            Dim isSolution As Boolean = False
            Dim sql As String
            Dim tbl As DataTable

            If Revision > 0 Then
                sql = "Select RFIID, responseStatus, Answer From RFIQuestions Where RFIID = " & RFIID & " AND Revision = " & Revision & " AND ResponseType = 'DP-Solution'"
            Else
                sql = "Select RFIID, responseStatus, Answer From RFIs Where RFIID = " & RFIID & " AND ResponseType = 'DP-Solution'"
            End If
            tbl = db.ExecuteDataTable(sql)

            If tbl.Rows.Count = 0 Then
                sql = "Select RFIID, responseStatus, Answer, SequenceNum From RFIAnswers Where RFIID = " & RFIID & " AND Revision = " & Revision & " AND ResponseType = 'DP-Solution'"
                tbl = db.ExecuteDataTable(sql)
            End If

            Return tbl
        End Function

        Public Function isDPSolution(RFIID As Integer, Revision As Integer) As Boolean
            Dim tbl As DataTable = checkForDPSolution(RFIID, Revision)
            Dim isSolution As Boolean

            If tbl.Rows.Count = 0 Then
                isSolution = False
            Else
                isSolution = True
            End If

            Return isSolution
        End Function

        Public Function getQuestionsForRFI(ByVal RFIID As Integer, contactType As String, wfp As String, contactID As Integer) As DataTable
            Dim tbl As DataTable
            Dim sql As String = "Select Revision,QuestionID,Question,RequestStatus,ResponseStatus, SubmittedByID from RFIQuestions Where RFIID = " & RFIID & " AND RequestStatus <> 'Canceled' "

            If contactType <> "General Contractor" Then
                If contactType = "Design Professional" Or contactType = "District" Then
                    sql &= " AND RequestStatus <> 'Preparing'"
                ElseIf contactType = "ProjectManager" Or contactType = "Construction Manager" Then
                    sql &= " AND ( 1 = Case When RequestStatus = 'Preparing' AND SubmittedByID = " & contactID & " Then 1 Else "
                    sql &= " Case When RequestStatus <> 'Preparing' Then 1 Else 0 end end)"
                End If
            ElseIf contactType = "General Contractor" Then
                sql &= " AND ( 1 = Case When RequestStatus = 'Preparing' AND SubmittedByID = " & contactID & " Then 1 Else "
                sql &= " Case When SubmittedById=" & contactID & " Then 1 Else "
                sql &= " Case When SubmittedToId <> " & contactID & " Then Case When  RequestStatus <> 'Preparing' Then Case When ToGCReleaseBy is null then 0 Else 1 end end end end end)"
                sql &= " "
            End If

            sql &= " Order by Revision"

            tbl = db.ExecuteDataTable(sql)
            Dim newrow As DataRow = tbl.NewRow
            newrow("QuestionID") = 0
            newrow("Question") = ""
            newrow("Revision") = 0
            tbl.Rows.InsertAt(newrow, 0)

            Return tbl
        End Function

        Public Function checkForActiveRevision(RFIID As Integer, Rev As Integer) As Object
            Dim sql As String
            If Rev > 0 Then
                sql = "Select RequestStatus, WorkFlowPosition From RFIQuestions Where RFIID=" & RFIID & " AND Revision=" & Rev
            ElseIf Rev = 0 Then
                sql = "Select RequestStatus, WorkFlowPosition From RFIs Where RFIID=" & RFIID
            End If
            Dim tbl As DataTable = db.ExecuteDataTable(sql)
            Dim obj(1) As Object
            obj(0) = tbl.Rows(0).Item("RequestStatus")
            obj(1) = tbl.Rows(0).Item("WorkFlowPosition")
            Return obj
        End Function

        Public Function getRFIQuestion(ByVal RFIID As Integer, ByVal rev As Integer) As DataTable
            Dim tbl As DataTable
            Dim sql As String = "Select * from RFIQuestions Where RFIID = " & RFIID & " AND Revision = " & rev
            tbl = db.ExecuteDataTable(sql)

            Return tbl
        End Function

        Public Function GetAnswersForRFI(ByVal RFIID As Integer, ByVal Rev As Integer, hideHolds As Boolean) As DataTable

            Dim tblAnswers As DataTable

            Dim sql As String = "Select AnswerID, SequenceNum,AnswerID,Answer,ResponseStatus,ResponseType, ResponderID From RFIAnswers Where RFIID = " & RFIID & " AND Revision = " & Rev & " AND RTRIM(ResponseStatus)!='Canceled'"

            sql &= " Order by SequenceNum"

            tblAnswers = db.ExecuteDataTable(sql)

            
            'Add None Record
            Dim newrow As DataRow = tblAnswers.NewRow
            newrow("AnswerID") = 0
            newrow("Answer") = ""
            newrow("SequenceNum") = 1
            Try
                If tblAnswers.Rows(0).Item("SequenceNum") = 2 Then
                    tblAnswers.Rows.InsertAt(newrow, 0)   'put it first
                End If
            Catch ex As Exception
            End Try

            Return tblAnswers

        End Function

        Public Function getOriginalAnswer(ByVal RFIID As Integer, ByVal Rev As Integer) As DataTable
            Dim Ans As DataTable
            Dim sql As String = ""
            If Rev = 0 Then
                sql = "Select x.name, Answer, ReturnedOn, ResponseStatus, RequestStatus, ResponseType from RFIs "
                sql &= " Join Contacts x ON x.ContactID=RFIs.RespondedBy "
                sql &= "Where RFIID = " & RFIID
            Else
                sql = "Select  Answer, x.ResponseStatus, x.RequestStatus, x.ResponseType From RFIQuestions x "
                sql = "Select x.Answer, x.ReturnedOn, z.name, z.ContactType, x.ResponseStatus, x.RequestStatus, x.ResponseType From RFIQuestions x "
                sql &= "Join RFIs y ON y.RFIID=x.RFIID "
                sql &= "Join Contacts z ON z.ContactID=x.RespondedBy "
                sql &= "Where x.RFIID = " & RFIID & " AND x.Revision = " & Rev
            End If

            Ans = db.ExecuteDataTable(sql)
            Return Ans
        End Function

        Public Function getRFIAnswer(ByVal RFIID As Integer, ByVal Seq As Integer, ByVal rev As Integer) As DataTable
            Dim sql As String = "Select Answer, ResponderID, x.name, x.ContactType, ReturnedOn, ResponseStatus, ResponseType, SequenceNum from RFIAnswers "
            sql &= " Join Contacts x on x.ContactID=RFIAnswers.ResponderID "
            sql &= " Where RFIID = " & RFIID & " And SequenceNum = " & Seq & " AND Revision = " & rev & " AND ResponseStatus!='Canceled'"
            Dim Ans As DataTable
            Ans = db.ExecuteDataTable(sql)
            Return Ans
        End Function

        Public Function getNextRFIAnswerID(ByVal RFIID As Integer, ByVal Rev As Integer) As Integer
            Dim nextAnsID As Integer
            If db.ExecuteScalar("SELECT MAX(SequenceNum) from RFIAnswers Where RFIID = " & RFIID & " AND Revision = " & Rev & " AND ResponseStatus!='Canceled'") Is DBNull.Value Then
                nextAnsID = 1
            Else
                nextAnsID = db.ExecuteScalar("SELECT MAX(SequenceNum) from RFIAnswers Where RFIID = " & RFIID & " AND Revision = " & Rev & " AND ResponseStatus!='Canceled'")
            End If
            Return nextAnsID + 1
        End Function

        Public Sub insertRFIRevision(reqObj As Object)
            'Dim subTo As Integer = getRFISubmittedTo(reqObj(0))
            Dim sql As String = "Insert Into RFIQuestions(RFIID,Revision,Question,Proposed,ResubmittedOn,RequiredBy,LastUpdatedDate,LastUpdatedBy,SubmittedToId,SubmittedById,WorkFlowPosition,RequestStatus,ResponseStatus)"
            sql &= " VALUES(" & reqObj(11) & "," & reqObj(10) & ",'" & reqObj(8) & "','" & reqObj(9) & "','" & Now & "','" & reqObj(6) & "','" & Now & "'," & reqObj(13) & "," & 0 & "," & reqObj(13) & ",'" & "" & "','" & reqObj(14) & "','')"

            db.ExecuteNonQuery(sql)

            sql = "Update RFIs Set AltRefNumber = '" & reqObj(18) & "' Where RFIID = " & reqObj(11)
            db.ExecuteNonQuery(sql)

        End Sub

        Public Function getRFISubmittedTo(RFIID As Integer) As Integer
            Dim sql = "Select SubmittedToID from RFIs where RFIID = " & RFIID
            Dim subTo As Integer = db.ExecuteScalar(sql)
            Return subTo
        End Function

        Public Sub releaseRFI(ByVal RFIID As Integer)
            Dim zdate As DateTime = Date.UtcNow
            Dim user As String = HttpContext.Current.Session("UserName")

            Dim sql As String = "Update RFIs Set WorkFlowPosition='CM:Close Pending', LastUpdateOn='" & Now & "', LastUpdateBy='" & user & "'"
            sql &= " Where RFIID = " & RFIID
            db.ExecuteScalar(sql)

        End Sub

        Public Sub updateWorkFlowPosition(RFIID As Integer, wfPosition As String)
            Dim sql As String
            sql = "Update RFIs Set WorkFlowPosition = '" & wfPosition & "', NewWorkflow='True', PMNewWorkFlow='True' Where RFIID = " & RFIID
            db.ExecuteNonQuery(sql)
        End Sub

        Public Sub updateRFIRequest(reqObj As Object)
            Dim sql As String

            If reqObj(10) = 0 Then
                sql = "Update RFIs Set Question = '" & reqObj(8) & "', Proposed = '" & reqObj(9) & "', ReceivedOn = '" & Now & "', "
                sql &= "RequiredBy = '" & reqObj(6) & "', LastUpdateOn = '" & Now & "'"
                If reqObj(14) = "Active" Then
                    sql &= " , RequestStatus='Active'"
                End If
                If reqObj(16) > 0 Then
                    sql &= " ,SubmittedToID=" & reqObj(16)
                End If
                sql &= " Where RFIID=" & reqObj(11)
            Else
                sql = "Update RFIQuestions Set Question = '" & reqObj(8) & "', Proposed = '" & reqObj(9) & "', ResubmittedOn = '" & Now & "', "
                sql &= "RequiredBy = '" & reqObj(6) & "', LastUpdatedDate = '" & Now & "'"
                If reqObj(14) = "Active" Then
                    sql &= " , RequestStatus='Active'"
                End If
                If reqObj(16) > 0 Then
                    sql &= " ,SubmittedToID=" & reqObj(16)
                End If
                sql &= " Where RFIID=" & reqObj(11) & " AND Revision=" & reqObj(10)
            End If

            db.ExecuteNonQuery(sql)

            If reqObj(14) <> "" Then
                If reqObj(10) = 0 Then
                    sql = "Update RFIs Set requestStatus='" & reqObj(14) & "' Where RFIID = " & reqObj(11)
                Else
                    sql = "Update RFIQuestions Set requestStatus='" & reqObj(14) & "' Where RFIID= " & reqObj(11) & " AND Revision = " & reqObj(10)
                End If
                db.ExecuteNonQuery(sql)
            End If

            If reqObj(16) > 0 Then
                sql = "Update RFIs Set Status='Active' Where RFIID = " & reqObj(11)
                db.ExecuteNonQuery(sql)
            End If

            If reqObj(17) = "UpdateReqBy" Then
                If reqObj(10) = 0 Then
                    sql = "Update RFIs Set RequiredBy='" & Now.AddDays(5) & "' Where RFIID=" & reqObj(11)
                Else
                    sql = "Update RFIQuestions Set RequiredBy='" & Now.AddDays(5) & "' Where RFIID=" & reqObj(11)
                End If
                db.ExecuteNonQuery(sql)
            End If

            If reqObj(12) <> "noChange" Then
                sql = "Update RFIs Set WorkFlowPosition = '" & reqObj(12) & "', NewWorkflow='True', PMNewWorkFlow='True' Where RFIID = " & reqObj(11)
                db.ExecuteNonQuery(sql)
            End If

            sql = "Update RFIs Set AltRefNumber='" & reqObj(18) & "' Where RFIID=" & reqObj(11)
            db.ExecuteNonQuery(sql)

        End Sub

        Public Function checkForRevisionPreparing(nRFIID As Integer) As DataTable
            Dim sql As String = "Select SubmittedByID, RequestStatus, Contacts.Name, Contacts.ContactType From RFIQuestions "
            sql &= " JOIN Contacts on Contacts.ContactID=RFIQuestions.SubmittedById "
            sql &= " Where RFIID = " & nRFIID & " AND RequestStatus = 'Preparing'"
            Dim tbl As DataTable = db.ExecuteDataTable(sql)
            Return tbl
        End Function

        Public Sub overrideRevision(Rev As Integer, RFIID As Integer)
            Dim sql As String
            If Rev = 0 Then
                sql = "Update RFIs Set RequestStatus='Revision Override' Where RFIID = " & RFIID
            Else
                sql = "Update RFIQuestions Set RequestStatus='Revision Override' Where RFIID = " & RFIID & " AND Revision = " & Rev
            End If
            db.ExecuteNonQuery(sql)
        End Sub

        Public Sub updateSentTo(RFIID As Integer, SentTo As Integer, rev As Integer, response As String, responseType As String)
            Dim zdate As Date = DateTime.Now()
            Dim user As String = HttpContext.Current.Session("UserName")
            Dim userid As Integer = HttpContext.Current.Session("UserID")
            Dim sql As String = ""
            Dim status As String = "Active"

            If rev = 0 Then
                sql = "Update RFIs Set SubmittedToID = " & SentTo & ", LastUpdateOn = '" & zdate & "', Answer = '" & response & "'"
                sql &= ", LastUpdateBy = " & userid & ", Status = '" & status & "'"
                sql &= " Where RFIID = " & RFIID
            ElseIf rev > 0 Then
                sql = "Update RFIQuestions Set SubmittedToID = " & SentTo & ", LastUpdatedDate = '" & zdate & "', Answer = '" & response & "'"
                sql &= ", LastUpdatedBy = " & userid
                sql &= " Where RFIID = " & RFIID & " AND Revision = " & rev
            End If

            db.ExecuteNonQuery(sql)

            If rev > 0 Then
                sql = "Update RFIs Set SubmittedToID = " & SentTo & ", Status = '" & status & "' Where RFIID = " & RFIID
                db.ExecuteNonQuery(sql)
            End If

        End Sub

        Public Sub updateRFIResponse(ByVal RFIID As Integer, ByVal Seq As Integer, ByVal Ans As String)
            Dim zdate As Date = DateTime.Now()
            Dim user As String = HttpContext.Current.Session("UserName")
            Dim sql As String = "Update RFIAnswers Set Answer = '" & Ans & "', LastUpdateDate = " & zdate
            sql &= ", LastUpdatedBy = '" & user & "' Where RFIID = " & RFIID & " AND SequenceNum = " & Seq

            db.ExecuteNonQuery(sql)
        End Sub

        Public Sub insertRFIResponse(ByVal resObj As Object)
            Dim user As String = HttpContext.Current.Session("UserName")
            Dim zDate As Date = DateTime.Now()
            Dim sql As String = "Insert Into RFIAnswers(Answer,RFIID,Revision,ResponderID,SequenceNum,ReturnedOn,LastUpdateDate,LastUpdatedBy)"
            sql &= " Values('" & resObj(0) & "'," & resObj(1) & "," & resObj(2) & "," & resObj(3) & "," & resObj(4) & ",'" & resObj(5) & "','" & zDate & "','" & user & "')"
            db.ExecuteNonQuery(sql)
            Dim stat As String = ""
            If resObj(2) = 0 Then
                stat = "Orig:#" & resObj(4)
            Else
                stat = "Rev-" & resObj(2) & ":#" & resObj(4)
            End If
            sql = "Update RFIs Set Status = '" & stat & " Response Provided' Where RFIID = " & resObj(1)
            db.ExecuteNonQuery(sql)

        End Sub

        Public Function updateReleaseData(rfiObj As Object, save As Boolean) As String
            Dim sql As String = ""

            If rfiObj(2) = 0 Then
                sql = "Update RFIs Set "
            Else
                sql = "Update RFIQuestions Set "
            End If

            Select Case rfiObj(7)
                Case "DP:Response Pending"
                    sql &= " ToDPReleaseDate = '" & rfiObj(4) & "', ToDPReleaseBy = " & rfiObj(5)
                Case "GC:Acceptance Pending"
                    sql &= " ToGCReleaseDate = '" & rfiObj(4) & "', ToGCReleaseBy = " & rfiObj(5)
                Case "CM:Completion Pending"
                    sql &= " RequestReleaseDate = '" & rfiObj(4) & "', RequestReleaseBy = " & rfiObj(5)
            End Select

            If rfiObj(2) = 0 Then
                sql &= " Where RFIID = " & rfiObj(1)
            Else
                sql &= " Where RFIID = " & rfiObj(1) & " AND Revision = " & rfiObj(2)
            End If

            If rfiObj(7) = "Complete" Then
                sql = "Update RFIs Set ClosedOn = '" & rfiObj(4) & "', ClosedBy = " & rfiObj(5) & ", Status = 'Closed' Where RFIID = " & rfiObj(1) & " "
            End If

            If save = True Then
                db.ExecuteNonQuery(sql)
            End If

            Return sql

        End Function

        Public Sub releaseToGC(RFIID As Integer, sequenceNum As Integer)
            Dim sql As String = "Update RFIAnswers Set ResponseStatus='Released' Where RFIID = " & RFIID & " AND SequenceNum = " & sequenceNum
            db.ExecuteNonQuery(sql)

        End Sub

        Public Sub updateRequiredByDate(reqBy As DateTime, RFIID As Integer, rev As Integer, sType As String)
            Dim sql As String = ""

            If sType = "a" Then
                sql = "Update RFIs Set RequiredBy='" & reqBy & "' Where RFIID=" & RFIID
            ElseIf sType = "b" Then
                sql = "Update RFIQuestions Set RequiredBy='" & reqBy & "' Where RFIID=" & RFIID & " AND Revision=" & rev
            End If

            db.ExecuteNonQuery(sql)

        End Sub

        Public Function checkForResponsePrepare(rfiid As Integer, contactID As Integer) As Object
            Dim tbl As DataTable = Nothing
            Dim name As String = ""
            Dim sql As String
            Dim obj(6) As Object

            sql = "Select QuestionID, SubmittedById From RFIQuestions Where RFIID=" & rfiid & " AND RequestStatus <> 'Released'AND (1 = Case When RequestStatus='Canceled' Then 0 Else 1 End) "
            sql &= "AND (1 = Case When RequestStatus='CMPending' Then 0 Else 1 End) AND (1 = Case When RequestStatus='Active' Then 0 Else 1 End)  AND (1 = Case When RequestStatus='Revision Override' Then 0 Else 1 End) AND SubmittedByID <> " & contactID
            tbl = db.ExecuteDataTable(sql)
            If tbl.Rows.Count > 0 Then  'There is a preparing revision in the RFIs table
                sql = "Select Name from Contacts Where ContactID=" & tbl.Rows(0).Item("SubmittedById")
                obj(0) = db.ExecuteScalar(sql)
                obj(1) = tbl.Rows(0).Item("SubmittedById")
                obj(2) = "RFIQuestions"
                obj(3) = tbl.Rows(0).Item("QuestionID")
                obj(4) = "QuestionID"
                obj(5) = "revision"
            Else
                sql = "Select AnswerID, ResponderID From RFIAnswers Where RFIID=" & rfiid & " AND ResponseStatus <> 'Released' AND (1 = Case When ResponseStatus='Canceled' Then 0 Else 1 End)  "
                sql &= "AND (1 = Case When ResponseStatus='CMPending' Then 0 Else 1 End)  AND ResponderID <> " & contactID
                tbl = db.ExecuteDataTable(sql)
                If tbl.Rows.Count > 0 Then 'There is a preparing response in the RFIAnswers table
                    sql = "Select Name from Contacts Where ContactID=" & tbl.Rows(0).Item("ResponderID")
                    obj(0) = db.ExecuteScalar(sql)
                    obj(1) = tbl.Rows(0).Item("ResponderID")
                    obj(2) = "RFIAnswers"
                    obj(3) = tbl.Rows(0).Item("AnswerID")
                    obj(4) = "AnswerID"
                    obj(5) = "response"
                Else
                    sql = "Select QuestionID, RespondedBy From RFIQuestions Where RFIID=" & rfiid & " AND ResponseStatus <> 'Released' AND (1 = Case When ResponseStatus='Canceled' Then 0 Else 1 End)  "
                    sql &= "AND (1 = Case When ResponseStatus='CMPending' Then 0 Else 1 End)  AND RespondedBy <> " & contactID
                    tbl = db.ExecuteDataTable(sql)
                    If tbl.Rows.Count > 0 Then  'There is a preparing response in the RFIQuestions table
                        sql = "Select Name from Contacts Where ContactID=" & tbl.Rows(0).Item("RespondedBy")
                        obj(0) = db.ExecuteScalar(sql)
                        obj(1) = tbl.Rows(0).Item("RespondedBy")
                        obj(2) = "RFIQuestions"
                        obj(3) = tbl.Rows(0).Item("QuestionID")
                        obj(4) = "QuestionID"
                        obj(5) = "response"
                    Else
                        sql = "Select RFIID, RespondedBy From RFIs Where RFIID=" & rfiid & " AND ResponseStatus <> 'Released' AND (1 = Case When ResponseStatus='Canceled' Then 0 Else 1 End) "
                        sql &= "AND (1 = Case When ResponseStatus='CMPending' Then 0 Else 1 End) AND RespondedBy <> " & contactID
                        tbl = db.ExecuteDataTable(sql)
                        If tbl.Rows.Count > 0 Then  'There is a preparing response in the RFIs table
                            sql = "Select Name from Contacts Where ContactID=" & tbl.Rows(0).Item("RespondedBy")
                            obj(0) = db.ExecuteScalar(sql)
                            obj(1) = tbl.Rows(0).Item("RespondedBy")
                            obj(2) = "RFIs"
                            obj(3) = tbl.Rows(0).Item("RFIID")
                            obj(4) = "RFIID"
                            obj(5) = "response"
                        Else
                            obj(0) = "none" 'There are no responses being prepared
                        End If
                    End If
                End If
            End If


            Return obj
        End Function

        Public Sub checkCancelResponse(rfiid As Integer, contactID As Integer)
            Dim obj(2) As Object
            obj = checkForResponsePrepare(rfiid, contactID)
            If obj(0) <> "none" Then
                Dim sql = "Update " & obj(2) & " Set ResponseStatus='Canceled' Where " & obj(4) & "=" & obj(3)
                db.ExecuteNonQuery(sql)
            End If
        End Sub

        Public Sub processRFIResponse(ByVal rfiObj As Object)
            Dim user As String = HttpContext.Current.Session("UserName")
            Dim zDate As Date = DateTime.Now()
            Dim sql As String = ""
            Dim sqlString As String = ""

            Select Case rfiObj(11)
                Case "a"
                    sql = "Update RFIs Set Answer = '" & rfiObj(0) & "', LastUpdateBy = '" & user & "', LastUpdateOn = '" & zDate & "', ReturnedOn = '" & rfiObj(4) & "', RespondedBy = " & rfiObj(5)
                    sql &= ", ResponseStatus = '" & rfiObj(8) & "', ResponseType = '" & rfiObj(14) & "', RequiredBy='" & rfiObj(15) & "'"

                    If rfiObj(7) <> "noChange" Then
                        sql &= ", WorkFlowPosition = '" & rfiObj(7) & "', Status = '" & rfiObj(10) & "'"
                    End If

                    sql &= " Where RFIID = " & rfiObj(1)
                Case "b"
                    sql = "Update RFIQuestions Set Answer = '" & rfiObj(0) & "', LastUpdatedBy = '" & rfiObj(5) & "', LastUpdatedDate = '" & zDate & "', ReturnedOn = '" & rfiObj(4) & "', RespondedBy = " & rfiObj(5)
                    sql &= ", ResponseStatus = '" & rfiObj(8) & "', ResponseType = '" & rfiObj(14) & "', RequiredBy='" & rfiObj(15) & "'"

                    If rfiObj(7) <> "noChange" Then
                        sql &= ", WorkFlowPosition = '" & rfiObj(7) & "'"
                    End If

                    sql &= "  Where RFIID = " & rfiObj(1) & " AND Revision = " & rfiObj(2)
                Case "c"
                    sql = "Update RFIAnswers Set Answer = '" & rfiObj(0) & "', LastUpdatedBy = '" & user & "', LastUpdateDate = '" & zDate & "', ReturnedOn = '" & rfiObj(4) & "', ResponderID = " & rfiObj(5)
                    sql &= ", ResponseStatus = '" & rfiObj(8) & "', ResponseType = '" & rfiObj(14) & "'"
                    sql &= " Where AnswerID=" & rfiObj(19)

                    'sql &= "  Where RFIID = " & rfiObj(1) & " AND Revision = " & rfiObj(2) & " AND SequenceNum = " & rfiObj(3)
                Case "d"
                    sql = "Insert Into RFIAnswers(RFIID,Answer,LastUpdateDate,LastUpdatedBy,SequenceNum,ResponderID,ReturnedOn,Revision, ResponseStatus,ResponseType)"
                    sql &= " Values(" & rfiObj(1) & ",'" & rfiObj(0) & "','" & zDate & "','" & user & "'," & rfiObj(13) & "," & rfiObj(5) & ",'" & rfiObj(4) & "'," & rfiObj(2) & ",'" & rfiObj(8) & "','" & rfiObj(14) & "')"
            End Select

            db.ExecuteNonQuery(sql)

            If rfiObj(16) = True Then
                sql = "Update RFIS Set  AltRefNumber = '" & rfiObj(17) & "' Where RFIID=" & rfiObj(1)
                db.ExecuteNonQuery(sql)
            End If

            If rfiObj(18) = True Then
                If rfiObj(2) > 0 Then
                    sql = "Select QuestionID From RFIQuestions Where RFIID=" & rfiObj(1) & " AND Revision=" & rfiObj(2)
                    Dim queID As Integer = db.ExecuteScalar(sql)
                    sql = "Update RFIQuestions Set Requiredby='" & rfiObj(15) & "' Where QuestionID=" & queID
                Else
                    sql = "Update RFIs Set RequiredBy='" & rfiObj(15) & "' Where RFIID=" & rfiObj(1)
                End If
                db.ExecuteNonQuery(sql)
            End If

            If rfiObj(7) <> "noChange" Then
                sql = "Update RFIs Set WorkFlowPosition = '" & rfiObj(7) & "', Status = '" & rfiObj(10) & "', NewWorkflow='True', PMNewWorkFlow='True' Where RFIID = " & rfiObj(1)
                db.ExecuteNonQuery(sql)
            End If
        End Sub

        Public Sub processRFIResponse_back(ByVal rfiObj As Object)
            Dim user As String = HttpContext.Current.Session("UserName")
            Dim zDate As Date = DateTime.Now()
            Dim sql As String = ""

            If rfiObj(12) = True Then
                sql = "Insert Into RFIAnswers(RFIID,Answer,LastUpdateDate,LastUpdatedBy,SequenceNum,ResponderID,ReturnedOn,Revision ResponseStatus)"
                sql &= " Values(" & rfiObj(1) & ",'" & rfiObj(0) & "','" & zDate & "','" & user & "'," & rfiObj(3) + 1 & "," & rfiObj(5) & ",'" & rfiObj(4) & "'," & rfiObj(2) & ",'" & rfiObj(8) & "')"
            Else
                If rfiObj(2) = 0 Then
                    sql = "Update RFIs Set Answer = '" & rfiObj(0) & "', LastUpdateBy = '" & user & "', LastUpdateOn = '" & zDate & "', ReturnedOn = '" & rfiObj(4) & "', RespondedBy = " & rfiObj(5)
                    sql &= ", ResponseStatus = '" & rfiObj(8) & "'"

                    If rfiObj(8) <> "noChange" Then
                        sql &= ", WorkFlowPosition = '" & rfiObj(7) & "', Status = '" & rfiObj(10) & "'"
                    End If

                    sql &= " Where RFIID = " & rfiObj(1)
                Else
                    If rfiObj(3) = 1 Then
                        sql = "Update RFIQuestions Set Answer = '" & rfiObj(0) & "', LastUpdatedBy = " & rfiObj(5) & ", LastUpdatedDate = '" & zDate & "', ReturnedOn = '" & rfiObj(4) & "', RespondedBy = " & rfiObj(5)
                        sql &= ", ResponseStatus = '" & rfiObj(8) & "'"

                        If rfiObj(7) <> "noChange" Then
                            sql &= ", WorkFlowPosition = '" & rfiObj(7) & "'"
                        End If

                        sql &= "  Where RFIID = " & rfiObj(1) & " AND Revision = " & rfiObj(2)
                    Else
                        sql = "Update RFIAnswers Set Answer = '" & rfiObj(0) & "', LastUpdatedBy = " & rfiObj(5) & ", LastUpdateDate = '" & zDate & "', ReturnedOn = '" & rfiObj(4) & "', ResponderID = " & rfiObj(5)
                        sql &= ", ResponseStatus = '" & rfiObj(8) & "'"

                        sql &= "  Where RFIID = " & rfiObj(1) & " AND Revision = " & rfiObj(2) & " AND SequenceNum = " & rfiObj(3)
                    End If
                End If
            End If

            db.ExecuteNonQuery(sql)

            If rfiObj(2) > 0 Then
                If rfiObj(7) <> "noChange" Then
                    sql = "Update RFIs Set WorkFlowPosition = '" & rfiObj(7) & "', Status = '" & rfiObj(10) & "', NewWorkflow='True', PMNewWorkFlow='True' Where RFIID = " & rfiObj(1)
                    db.ExecuteNonQuery(sql)
                End If
            End If
        End Sub

        Public Function getResponderName(ByVal contactID As Integer) As String
            Dim sql As String = "Select Name from Contacts where ContactID = " & contactID
            Dim name As String = db.ExecuteScalar(sql)
            Return name
        End Function

        Public Function getAllRFIAnswers(ByVal nRFIID As Integer, ByVal type As String, ByVal Rev As Integer) As String
            Dim sql As String
            If Rev = 0 Then
                sql = "Select x.Answer, x.RespondedBy, x.ReturnedOn, x.RequiredBy From RFIs x "
                sql &= " Where RFIID = " & nRFIID
            Else
                'sql = "Select Answer From RFIQuestions Where RFIID = " & nRFIID & " AND Revision = " & Rev
                sql = "Select x.Answer, x.RespondedBy, x.ReturnedOn, x.RequiredBy From RFIQuestions x "
                sql &= " Where RFIID = " & nRFIID & " AND Revision = " & Rev
            End If

            Dim primeAns As String = ""
            Dim isAns As Boolean = True
            Dim root As DataTable = db.ExecuteDataTable(sql)
            Try
                primeAns = root.Rows(0).Item("Answer")
            Catch ex As Exception
            End Try

            If primeAns = "" Then
                isAns = False
                primeAns = " No Response For This Request"
            End If
            Dim chk As String = ""

            sql = "Select x.Answer, x.ResponderID, x.SequenceNum, x.ReturnedOn From RFIAnswers x "
            sql &= " Where RFIID = " & nRFIID & " And Revision = " & Rev
            sql &= " Order By x.SequenceNum"
            Dim tbl As New DataTable
            Dim i As Integer = 1
            tbl = db.ExecuteDataTable(sql)

            If type = "Prompt" Then
                chk = i & ".) " & primeAns & vbCrLf & vbCrLf
            ElseIf type = "Log" Then
                If isAns = False Then
                    chk = i & ".) " & primeAns & " &#10;&#10; "
                Else
                    chk = i & ".) [ Responded On: " & root.Rows(0).Item("ReturnedOn") & " ]&#10;[ " & getResponderName(root.Rows(0).Item("RespondedBy")) & " ]&#10;" & primeAns & " &#10;&#10; "
                    'chk = (root.Rows(0).Item("RespondedBy")).ToString()
                End If
            End If

            If tbl.Rows.Count > 0 Then
                Dim Ans As String = ""
                For Each row As DataRow In tbl.Rows
                    isAns = True
                    Ans = row.Item("Answer")
                    If Ans = "" Then
                        isAns = False
                        Ans = " No Response For This Request"
                    Else
                        isAns = True
                    End If
                    i = i + 1
                    If type = "Prompt" Then
                        chk &= i & ".)" & Ans & vbCrLf & vbCrLf
                    ElseIf type = "Log" Then
                        If isAns = False Then
                            chk &= i & ".)" & Ans & " - " & isAns & " &#10;&#10; "
                        Else
                            chk &= i & ".) [ Responded On: " & row.Item("ReturnedOn") & " ]&#10;[ " & getResponderName(row.Item("ResponderID")) & " ]&#10;" & Ans & " &#10;&#10; "
                        End If

                    End If
                Next

            Else
                If isAns = False Then
                    chk = i & ".)" & primeAns
                Else
                    chk = i & ".) [ Responded On " & root.Rows(0).Item("ReturnedON") & " ]&#10; [ " & getResponderName(root.Rows(0).Item("RespondedBy")) & " ]&#10;" & primeAns
                End If

            End If

            Return chk
        End Function

        Public Function checkForRevisionAnswers(nRFIID As Integer, rev As Integer) As DataTable
            Dim sql As String
            sql = "Select Answer From RFIAnswers Where RFIID=" & nRFIID & " AND Revision=" & rev
            Dim tbl As DataTable = db.ExecuteDataTable(sql)

            Return tbl
        End Function

        Public Function getUserProjects(ByVal ContactID As Integer) As DataTable
            Dim tbl As DataTable
            Dim sql As String = "Select Projects.ProjectID, Projects.ProjectName From TeamMembers "
            sql &= " JOIN Projects ON Projects.ProjectID = TeamMembers.ProjectID "
            sql &= " Where TeamMembers.ContactID = " & ContactID
            sql &= " Order by ProjectName "

            tbl = db.ExecuteDataTable(sql)

            Return tbl
        End Function



        Public Function countRFIAttachments(ByVal RFIID As Integer, Type As String, responseNum As Integer) As Integer
            Dim numAttach As Integer = 0
            Dim sPath As String = ""
            Dim sRelPath As String
            Dim strPhysicalPath As String = ProcLib.GetCurrentAttachmentPath() & "DistrictID_" & HttpContext.Current.Session("DistrictID")
            strPhysicalPath &= "/_apprisedocs/_RFIs/"

            Dim strRelativePath As String = ProcLib.GetCurrentRelativeAttachmentPath() & "DistrictID_" & HttpContext.Current.Session("DistrictID")
            strRelativePath &= "/_apprisedocs/_RFIs/"

            If Type = "Request" Then
                sPath = strPhysicalPath & "RFIID_" & RFIID & "/Rev_0"
                sRelPath = strRelativePath & "RFIID_" & RFIID & "Rev_0/"
            ElseIf Type = "Response" Then
                sPath = strPhysicalPath & "RFIID_" & RFIID & "/Rev_0_Response_1"
                sRelPath = strRelativePath & "RFIID_" & RFIID & "Rev_0_Response_1/"
            End If

            Dim folder As New DirectoryInfo(sPath)
            If Not folder.Exists Then
            Else
                For Each fi As FileInfo In folder.GetFiles()
                    numAttach += 1
                Next
            End If
            Return numAttach

        End Function

        Public Function countRFIAttachmentsNew(RFIID As Integer, Rev As Integer, Seq As Integer, type As String) As Integer
            Dim strPhysicalPath As String = ProcLib.GetCurrentAttachmentPath() & "DistrictID_" & HttpContext.Current.Session("DistrictID")
            strPhysicalPath &= "/_apprisedocs/_RFIs/"

            Dim strRelativePath As String = ProcLib.GetCurrentRelativeAttachmentPath() & "DistrictID_" & HttpContext.Current.Session("DistrictID")
            strRelativePath &= "/_apprisedocs/_RFIs/"

            Dim sPath As String = ""
            Dim sRelPath As String = ""

            If type = "Request" Then
                sPath = strPhysicalPath & "RFIID_" & RFIID & "/Rev_" & Rev
                sRelPath = strRelativePath & "RFIID_" & RFIID & "Rev_0/"
            ElseIf type = "Response" Then
                sPath = strPhysicalPath & "RFIID_" & RFIID & "/Rev_" & Rev & "_Response_" & Seq
                sRelPath = strRelativePath & "RFIID_" & RFIID & "Rev_0_Response_1/"
            End If

            Dim folder As New DirectoryInfo(sPath)
            Dim zPath As String = ""
            Dim ifilecount As Integer = 0

            If Not folder.Exists Then
                If type = "Request" Then
                    sPath = strPhysicalPath & "RFIID_" & RFIID & "/Rev_" & Rev
                    sRelPath = strRelativePath & "RFIID_" & RFIID & "Rev_0/"
                ElseIf type = "Response" Then
                    sPath = strPhysicalPath & "RFIID_" & RFIID & "/Rev_" & Rev & "_Response_" & Seq
                    sRelPath = strRelativePath & "RFIID_" & RFIID & "Rev_0_Response_1/"
                End If

                Dim folderB As New DirectoryInfo(sPath)

                If Not folderB.Exists Then
                Else
                    For Each fi As FileInfo In folderB.GetFiles()
                        ifilecount += 1
                    Next
                End If
            Else
                For Each fi As FileInfo In folder.GetFiles()
                    ifilecount += 1
                Next
            End If

            Return ifilecount
        End Function

        Public Function getAllContractSubmittals(ByVal ContractID As Integer) As DataTable
            Dim sql = "Select * From Submittals JOIN Contacts ON Contacts.ContactID=Submittals.SubmittedByID Where ContractID = " & ContractID
            Dim tbl As DataTable = db.ExecuteDataTable(sql)


            Return tbl
        End Function

        Public Function countAllContractRFIs(ByVal ContractID As Integer) As DataTable
            Dim sql = "Select ContractID From RFIs Where ContractID = " & ContractID
            Dim tbl As DataTable = db.ExecuteDataTable(sql)
            Return tbl
        End Function

        Public Sub updateLineItemAugment(RFIID As Integer, augment As String)
            Dim sql As String = "Update RFIs Set PMNewWorkFlow='" & augment & "' Where RFIID=" & RFIID
            db.ExecuteNonQuery(sql)
        End Sub

        Public Function countAllRFIs(ByVal ProjectID As Integer) As DataTable
            Dim sql = "Select ProjectID From RFIs Where ProjectID = " & ProjectID
            Dim tbl As DataTable = db.ExecuteDataTable(sql)
            Return tbl
        End Function

        Public Sub setNewWorkflowStatus(RFIID As Integer)
            Dim sql As String = "Update RFIs Set NewWorkflow = 'False' Where RFIID = " & RFIID
            db.ExecuteNonQuery(sql)
        End Sub

        Public Sub setPMNewWorkFlowStatus(RFIID As Integer)
            Dim sql = "Update RFIs Set PMNewWorkFlow='False' Where RFIID = " & RFIID
            db.ExecuteNonQuery(sql)
        End Sub

        Public Sub writeToContacts(contactID As Integer, value As String)
            Dim sql As String = "Update Contacts Set Category = '" & value & " Where ContactID = " & contactID
            db.ExecuteNonQuery(sql)
        End Sub

        Public Function getRfis(projectID As Integer) As DataTable
            Dim sql As String = "Select * From RFIS Where ProjectID = " & projectID
            Dim tbl As DataTable = db.ExecuteDataTable(sql)

            Return tbl
        End Function

        Public Function getAllProjectRFIs(projectID As Integer, contID As Integer, contactType As String, rfiSelect As String) As DataTable
            Dim sql As String = "Select * From RFIs JOIN Contacts ON Contacts.ContactID=RFIs.TransmittedByID "
            sql &= " JOIN Contacts AS cn ON cn.ContactID=" & contID
            sql &= " JOIN Contracts ON Contracts.ContractID=RFIs.ContractID "
            sql &= "Where RFIs.ProjectID = " & projectID

            If contactType = "General Contractor" Then 'And ContID > 0 Then
                sql &= " AND cn.ParentContactID=Contracts.ContractorID "
                sql &= " AND (1 = Case When RFIType='CM' AND CMShowToGC=0 Then 0 Else 1 end)"
            End If

            If contactType = "General Contractor" Or contactType = "Construction Manager" Then
                sql &= " AND (1 = Case When WorkFlowPosition='None' AND RFIs.TransmittedById=" & contID & " Then 1 Else 0 end "
                sql &= "OR 1 = Case When WorkFlowPosition <> 'None' Then 1 Else 0 end)"
            End If

            If contactType = "ProjectManager" Or contactType = "District" Then
                sql &= " AND (1 = Case When WorkFlowPosition='None' AND RFIs.TransmittedById=" & contID & " Then 1 "
                sql &= "Else Case When WorkFlowPosition <> 'None' Then 1 Else 0 end end)"
                'sql &= " AND WorkFlowPosition <> 'None' "
            End If

            If contactType = "Design Professional" And contID > 0 Then
                sql &= " AND SubmittedToID = " & contID
                sql &= " AND WorkFlowPosition <> 'None'"
            End If

            Select Case rfiSelect
                Case "Closed"
                    sql &= " AND ( RFIs.Status <> 'Closed' )"
                Case Else
            End Select

            sql &= " Order By RFIID desc "

            Dim tbl As DataTable = db.ExecuteDataTable(sql)

            'Now look for attachments for each RFI and if present then up the count
            Dim strPhysicalPath As String = ProcLib.GetCurrentAttachmentPath() & "DistrictID_" & HttpContext.Current.Session("DistrictID")
            strPhysicalPath &= "/_apprisedocs/_RFIs/"

            Dim strRelativePath As String = ProcLib.GetCurrentRelativeAttachmentPath() & "DistrictID_" & HttpContext.Current.Session("DistrictID")
            strRelativePath &= "/_apprisedocs/_RFIs/"

            'Add an attachments column
            Dim col As New DataColumn
            col.DataType = Type.GetType("System.String")
            col.ColumnName = "QuestionAttachments"
            tbl.Columns.Add(col)

            Dim col2 As New DataColumn
            col2.DataType = Type.GetType("System.String")
            col2.ColumnName = "WFPosition"
            tbl.Columns.Add(col2)

            Dim col3 As New DataColumn
            col3.DataType = Type.GetType("System.String")
            col3.ColumnName = "Revision"
            tbl.Columns.Add(col3)

            Dim col4 As New DataColumn
            col4.DataType = Type.GetType("System.DateTime")
            col4.ColumnName = "sRequiredBy"
            tbl.Columns.Add(col4)

            Dim col5 As New DataColumn
            col5.DataType = Type.GetType("System.String")
            col5.ColumnName = "ItemNum" 'This is the RefNumber trimed down
            tbl.Columns.Add(col5)

            Dim col6 As New DataColumn
            col6.DataType = Type.GetType("System.String")
            col6.ColumnName = "CompanyName"
            tbl.Columns.Add(col6)

            Dim ifilecount As Integer = 0

            For Each row As DataRow In tbl.Rows
                Dim sPath As String = strPhysicalPath & "RFIID_" & row("RFIID") & "/Rev_0"
                Dim sRelPath As String = strRelativePath & "RFIID_" & row("RFIID") & "Rev_0/"
                Dim folder As New DirectoryInfo(sPath)
                Dim zPath As String = ""
                Dim itemNum As String

                'Creates the trimmed down RFI number
                itemNum = row.Item("RefNumber")
                itemNum = "1" 'itemNum.Split("-").Last()
                row("ItemNum") = itemNum

                sql = "Select Name From Contacts Where ContactID=" & row.Item("ParentContactID")
                row.Item("CompanyName") = db.ExecuteScalar(sql)

                sql = "Select RequiredBy, Revision, WorkFlowPosition From RFIQuestions Where RFIID = " & row("RFIID") & " AND RequestStatus<>'Canceled'"
                If contactType <> "General Contractor" Then
                    sql &= " AND RequestStatus <> 'Preparing'"
                End If

                sql &= " order By Revision"
                Dim Que As DataTable = db.ExecuteDataTable(sql)

                If Que.Rows.Count > 0 Then
                    'row("WFPosition") = Que.Rows(Que.Rows.Count - 1).Item("WorkFlowPosition")
                    row("WFPosition") = row.Item("WorkFlowPosition")
                    row("Revision") = Que.Rows.Count
                Else
                    row("WFPosition") = row.Item("WorkFlowPosition")
                    row("Revision") = 0
                End If

                sql = "Select RequiredBy From RFIQuestions Where RFIID = " & row("RFIID") & " AND RequestStatus='Active'"
                Dim reqBy As DataTable = db.ExecuteDataTable(sql)
                If reqBy.Rows.Count > 0 Then
                    row("sRequiredBy") = FormatDateTime(reqBy.Rows(0).Item("RequiredBy"), 2)
                Else
                    row("sRequiredBy") = FormatDateTime(row.Item("RequiredBy"), 2)
                End If

                If Not folder.Exists Then  'There is no folder for root RFI. Need to search revisions.
                    If Que.Rows.Count > 0 Then
                        For Each dir As DataRow In Que.Rows
                            zPath = strPhysicalPath & "RFIID_" & row("RFIID") & "Rev_" & dir("Revision")
                            Dim newPath As New DirectoryInfo(zPath) '
                            If Not newPath.Exists Then
                                row("QuestionAttachments") = "N"
                            Else 'The path exists but is there any files?
                                For Each fi As FileInfo In folder.GetFiles()
                                    ifilecount += 1
                                Next
                                If ifilecount > 0 Then
                                    row("QuestionAttachments") = "Y"
                                    Exit For
                                Else
                                    row("QuestionAttachments") = "N"
                                End If
                            End If
                        Next
                    Else
                        row("QuestionAttachments") = "N"
                    End If
                Else                'there could be files so get all and list

                    For Each fi As FileInfo In folder.GetFiles()
                        ifilecount += 1
                    Next
                    If ifilecount > 0 Then
                        row("QuestionAttachments") = "Y"
                    Else
                        row("QuestionAttachments") = "N"
                    End If
                End If
            Next

            Return tbl
        End Function

        Public Function getAllContractRFIs(ByVal ContractID As Integer, contactType As String, ContID As Integer, rfiSelect As String) As DataTable
            Dim nTbl As DataTable

            Dim sql = "Select * From RFIs "
            'sql &= " Join Contacts ON Contacts.ContactID=RFIs.SubmittedToID "

            sql &= "JOIN Contacts ON Contacts.ContactID=RFIs.TransmittedById " '& ContID
            sql &= " JOIN Contracts ON Contracts.ContractID=RFIs.ContractID "
            sql &= " JOIN Contacts AS cn ON cn.ContactID=" & ContID & " "

            sql &= " Where RFIs.ContractID = " & ContractID

            If contactType = "General Contractor" Then 'And ContID > 0 Then
                sql &= " AND cn.ParentContactID=Contracts.ContractorID "
                sql &= " AND (1 = Case When RFIType='CM' AND CMShowToGC=0 Then 0 Else 1 end)"
            End If

            If contactType = "General Contractor" Or contactType = "Construction Manager" Then
                sql &= " AND (1 = Case When WorkFlowPosition='None' AND RFIs.TransmittedById=" & ContID & " Then 1 Else 0 end "
                sql &= "OR 1 = Case When WorkFlowPosition <> 'None' Then 1 Else 0 end)"
            End If

            If contactType = "ProjectManager" Or contactType = "District" Then
                sql &= " AND (1 = Case When WorkFlowPosition='None' AND RFIs.TransmittedById=" & ContID & " Then 1 "
                sql &= "Else Case When WorkFlowPosition <> 'None' Then 1 Else 0 end end)"
                'sql &= " AND WorkFlowPosition <> 'None' "
            End If

            If contactType = "Design Professional" And ContID > 0 Then
                sql &= " AND SubmittedToID = " & ContID
                sql &= " AND WorkFlowPosition <> 'None'"
            End If

            Select Case rfiSelect
                Case "Closed"
                    sql &= " AND ( RFIs.Status <> 'Closed' )"
                Case Else
            End Select

            If contactType = "General Contractor" Then
                sql &= " OR (1 = Case When RFIs.RFIType='CM' AND RFIs.CMShowToGC = 1 AND  Contracts.ContractorID=cn.ParentContactID  "
                If rfiSelect = "Closed" Then
                    sql &= " AND RFIs.Status <> 'Closed' Then 1 "
                Else
                    sql &= " Then 1 "
                End If
                sql &= " else 0 end )"
            End If

            sql &= "Order By RFIID desc"

            Dim tbl As DataTable = db.ExecuteDataTable(sql)

            'Now look for attachments for each RFI and if present then up the count
            Dim strPhysicalPath As String = ProcLib.GetCurrentAttachmentPath() & "DistrictID_" & HttpContext.Current.Session("DistrictID")
            strPhysicalPath &= "/_apprisedocs/_RFIs/"

            Dim strRelativePath As String = ProcLib.GetCurrentRelativeAttachmentPath() & "DistrictID_" & HttpContext.Current.Session("DistrictID")
            strRelativePath &= "/_apprisedocs/_RFIs/"

            'Add an attachments column
            Dim col As New DataColumn
            col.DataType = Type.GetType("System.String")
            col.ColumnName = "QuestionAttachments"
            tbl.Columns.Add(col)

            Dim col2 As New DataColumn
            col2.DataType = Type.GetType("System.String")
            col2.ColumnName = "WFPosition"
            tbl.Columns.Add(col2)

            Dim col3 As New DataColumn
            col3.DataType = Type.GetType("System.String")
            col3.ColumnName = "Revision"
            tbl.Columns.Add(col3)

            Dim col4 As New DataColumn
            col4.DataType = Type.GetType("System.DateTime")
            col4.ColumnName = "sRequiredBy"
            tbl.Columns.Add(col4)

            Dim ifilecount As Integer = 0

            For Each row As DataRow In tbl.Rows
                Dim sPath As String = strPhysicalPath & "RFIID_" & row("RFIID") & "/Rev_0"
                Dim sRelPath As String = strRelativePath & "RFIID_" & row("RFIID") & "Rev_0/"
                Dim folder As New DirectoryInfo(sPath)
                Dim zPath As String = ""

                sql = "Select RequiredBy, Revision, WorkFlowPosition From RFIQuestions Where RFIID = " & row("RFIID") & " AND RequestStatus<>'Canceled'"
                If contactType <> "General Contractor" Then
                    sql &= " AND RequestStatus <> 'Preparing'"
                End If

                sql &= " order By Revision"
                Dim Que As DataTable = db.ExecuteDataTable(sql)

                If Que.Rows.Count > 0 Then
                    'row("WFPosition") = Que.Rows(Que.Rows.Count - 1).Item("WorkFlowPosition")
                    row("WFPosition") = row.Item("WorkFlowPosition")
                    row("Revision") = Que.Rows.Count
                Else
                    row("WFPosition") = row.Item("WorkFlowPosition")
                    row("Revision") = 0
                End If

                sql = "Select RequiredBy From RFIQuestions Where RFIID = " & row("RFIID") & " AND RequestStatus='Active'"
                Dim reqBy As DataTable = db.ExecuteDataTable(sql)
                If reqBy.Rows.Count > 0 Then
                    row("sRequiredBy") = FormatDateTime(reqBy.Rows(0).Item("RequiredBy"), 2)
                Else
                    row("sRequiredBy") = FormatDateTime(row.Item("RequiredBy"), 2)
                End If

                If Not folder.Exists Then  'There is no folder for root RFI. Need to search revisions.
                    If Que.Rows.Count > 0 Then
                        For Each dir As DataRow In Que.Rows
                            zPath = strPhysicalPath & "RFIID_" & row("RFIID") & "Rev_" & dir("Revision")
                            Dim newPath As New DirectoryInfo(zPath) '
                            If Not newPath.Exists Then
                                row("QuestionAttachments") = "N"
                            Else 'The path exists but is there any files?
                                For Each fi As FileInfo In folder.GetFiles()
                                    ifilecount += 1
                                Next
                                If ifilecount > 0 Then
                                    row("QuestionAttachments") = "Y"
                                    Exit For
                                Else
                                    row("QuestionAttachments") = "N"
                                End If
                            End If
                        Next
                    Else
                        row("QuestionAttachments") = "N"
                    End If
                Else                'there could be files so get all and list

                    For Each fi As FileInfo In folder.GetFiles()
                        ifilecount += 1
                    Next
                    If ifilecount > 0 Then
                        row("QuestionAttachments") = "Y"
                    Else
                        row("QuestionAttachments") = "N"
                    End If
                End If
            Next

            Return tbl

        End Function

        Public Function getAddRFIContracts(ProjectID As Integer, ContactType As String, ParentContactID As Integer, ContactID As Integer) As DataTable
            Dim sql As String = "Select ContractID, Description From Contracts"
            sql &= " Where ProjectID = " & ProjectID

            If ContactType.Trim() = "General Contractor" Then
                sql &= " AND ContractorID = " & ParentContactID
            End If

            Dim tbl As DataTable = db.ExecuteDataTable(sql)


            Dim col As New DataColumn
            col.DataType = Type.GetType("System.String")
            col.ColumnName = "ContractName"
            tbl.Columns.Add(col)

            Dim contractName As String

            For Each row As DataRow In tbl.Rows

                row("ContractName") = row.Item("ContractID") & " - " & row.Item("Description")

            Next


            Dim newrow As DataRow = tbl.NewRow
            newrow("ContractID") = 0
            newrow("ContractName") = "Select Contract"
            tbl.Rows.InsertAt(newrow, 0)   'put it first

            Return tbl
        End Function

        Public Function getContractID(nCOID As Integer) As Integer
            Dim sql As String = "Select RFIReference From PMChangeOrders Where COID = " & nCOID
            Return db.ExecuteScalar(sql)
        End Function

        Public Function getContractRFIs(ContractID As Integer) As DataTable
            Dim sql = "Select RFIID, RefNumber From RFIs Where ContractID = " & ContractID
            Return db.ExecuteDataTable(sql)
        End Function


        Public Function getAllProjectContracts(ProjectID As Integer, isDrop As Boolean, ContactType As String, tName As String) As DataTable
            'Dim objContracts(0) As Object
            Dim sql As String = "Select contracts.ContractID, BidPackNumber, ContractorID, Contacts.Name AS Contractor, Contacts.Contact AS Contact "
            sql &= ", Contacts.Phone1, Contacts.Email, Contracts.Description, Contracts.Status,Districts.Name As DistrictName "
            sql &= " From Contracts "
            sql &= "Join Contacts On Contacts.ContactID=Contracts.ContractorID "
            sql &= "Join Districts On Contracts.DistrictID=Districts.DistrictID "
            sql &= "where Contracts.ProjectID = " & ProjectID

            If ContactType = "General Contractor" Then
                sql &= " AND Contracts.ContractorID = " & HttpContext.Current.Session("ParentContactID")
            End If
            'sql &= " AND Exists(Select SubmittalID from Submittals Where Submittals.ContractID= Contracts.ContractID)"

            If isDrop = False Then
                'sql &= " AND Exists(Select SubmittalID from Submittals Where Submittals.ContractID= Contracts.ContractID)"
                Select Case Trim(tName)
                    Case "RFIs"
                        sql &= " AND Exists(Select RFIID from RFIs Where RFIs.ContractID= Contracts.ContractID)"
                    Case "Submittals"
                        sql &= " AND Exists(Select SubmittalID from Submittals Where Submittals.ContractID= Contracts.ContractID)"
                    Case "PMChangeOrders"
                        sql &= " AND Exists(Select ContractID from PMChangeOrders Where PMChangeOrders.ContractID= Contracts.ContractID)"
                    Case "PMCorrespondence"
                        sql &= " AND Exists(Select CorrID from PMCorrespondence Where PMCorrespondence.ContractID=Contracts.ContractID)"
                End Select
            End If

            sql &= " Order By ContractID asc "
            Dim tbl As DataTable = db.ExecuteDataTable(sql)

            If isDrop = True Then
                Dim newrow As DataRow = tbl.NewRow
                newrow("ContractID") = 0
                tbl.Rows.InsertAt(newrow, 0)   'put it first
            End If

            Return tbl
        End Function

        Public Function getRFIQAndAData(RFIID As Integer) As Object
            Dim rfiQue As DataTable
            Dim rfiAns As DataTable
            Dim OutPut As String = ""
            Dim sql As String = ""
            Dim revCount As Integer = checkForRevisions(RFIID)
            Dim resName As String = ""
            Dim zObj(4) As Object

            If revCount > 0 Then
                sql = "Select x.Question As OrigQue, y.Revision, y.Question as RevisionQue, x.Proposed, x.Answer, x.RequiredBy as OrigRequired, x.Status, x.ClosedBy, x.ClosedOn"
                sql &= ", y.Proposed as RevProposed, y.Answer as RevAnswer, x.ReceivedOn as OrigReceived, x.ReturnedOn as OrigReturn"
                sql &= ", y.ResubmittedOn as RevResubmit , y.ReturnedOn RevReturn, y.RequiredBy as RevRequired, x.RespondedBy as OrigResponder, y.RespondedBy as RevResponder "
                sql &= " From RFIs x "
                'sql &= " JOIN Contacts z ON z.ContactID=x.RespondedBy"
                sql &= " JOIN RFIQuestions y ON y.RFIID=x.RFIID Where x.RFIID = " & RFIID
            Else
                sql = "Select Question as OrigQue, Answer, Proposed, ReturnedOn as OrigReturn, ReceivedOn as OrigReceived, RequiredBy as OrigRequired, RespondedBy as OrigResponder, x.Status, x.ClosedBy, x.ClosedOn "
                'sql &= " JOIN Contacts y ON y.ContactID=x.RespondedBy "
                sql &= " From RFIs x where RFIID = " & RFIID
            End If
            rfiQue = db.ExecuteDataTable(sql)

            Try
                sql = "Select Name From Contacts Where ContactID = " & rfiQue.Rows(0).Item("OrigResponder")
                resName = db.ExecuteScalar(sql)
            Catch
                resName = ""
            End Try

            sql = "Select x.Answer, x.SequenceNum, x.Revision, x.ReturnedOn, y.Name From RFIAnswers x "
            sql &= " JOIN Contacts y on y.ContactID=x.ResponderID "
            sql &= " Where RFIID = " & RFIID & " AND Revision = 0"
            sql &= " Order By SequenceNum "

            rfiAns = db.ExecuteDataTable(sql)

            zObj(0) = rfiQue
            zObj(1) = rfiAns
            zObj(2) = resName
            zObj(3) = revCount

            Return zObj
        End Function

        'This is replaced with an html version
        Public Function buildRFIQAndAJavaScript(ByVal RFIID As Integer, ContactType As String) As String
            Dim rfiQue As DataTable
            Dim rfiAns As DataTable
            Dim OutPut As String = ""
            Dim sql As String = ""
            Dim revCount As Integer = checkForRevisions(RFIID)
            Dim resName As String = ""
            Dim reqName As String = ""
            Dim gcShow As Boolean = True

            If revCount > 0 Then
                sql = "Select x.Question As OrigQue, y.Revision, y.Question as RevisionQue, x.Proposed, x.Answer, x.RequiredBy as OrigRequired, x.TransmittedById as OrigRequester"
                sql &= ", x.Status, x.ClosedBy, x.ClosedOn, y.Proposed as RevProposed, y.Answer as RevAnswer, x.ReceivedOn as OrigReceived"
                sql &= ", x.ReturnedOn as OrigReturn, y.ResubmittedOn as RevResubmit , y.ReturnedOn RevReturn, y.RequiredBy as RevRequired, y.Revision "
                sql &= ", x.RespondedBy as OrigResponder, y.RespondedBy as RevResponder, x.RequestStatus, y.RequestStatus as RevRequestStatus"
                sql &= ", x.ResponseStatus, y.ResponseStatus as RevResponseStatus, x.ResponseType, y.ResponseType as RevResponseType, y.SubmittedById as RevRequester"
                'sql &= ""
                sql &= " From RFIs x "
                'sql &= " JOIN Contacts z ON z.ContactID=x.RespondedBy"
                sql &= " JOIN RFIQuestions y ON y.RFIID=x.RFIID Where x.RFIID = " & RFIID & " AND y.Revision <> 0 "
            Else
                sql = "Select Question as OrigQue, Answer, Proposed, ReturnedOn as OrigReturn, ReceivedOn as OrigReceived, TransmittedByID as OrigRequester "
                sql &= ", RequiredBy as OrigRequired, RespondedBy as OrigResponder, x.Status, x.ClosedBy, x.ClosedOn"
                sql &= ", RequestStatus, ResponseStatus, ResponseType"
                'sql &= " JOIN Contacts y ON y.ContactID=x.RespondedBy "
                sql &= " From RFIs x where RFIID = " & RFIID
            End If
            rfiQue = db.ExecuteDataTable(sql)

            If ContactType = "General Contractor" Then
                If rfiQue.Rows(0).Item("ResponseStatus") = "CMPending" Then
                    gcShow = False
                End If
            End If

            Try
                sql = "Select Name From Contacts Where ContactID = " & rfiQue.Rows(0).Item("OrigResponder")
                resName = db.ExecuteScalar(sql)
            Catch
                resName = ""
            End Try
            Try
                sql = "Select Name From Contacts Where ContactID = " & rfiQue.Rows(0).Item("OrigRequester")
                reqName = db.ExecuteScalar(sql)
            Catch ex As Exception
                reqName = ""
            End Try

            OutPut = "Original Question " & rfiQue.Rows(0).Item("OrigReceived") & " Required By  " & rfiQue.Rows(0).Item("OrigRequired") & " : " & vbCrLf
            OutPut &= "Originated By: " & reqName & vbCrLf & vbCrLf
            OutPut &= (rfiQue.Rows(0).Item("OrigQue")).Replace("~", "'") & vbCrLf & vbCrLf
            OutPut &= "Proposed: " & (rfiQue.Rows(0).Item("Proposed")).Replace("~", "'") & vbCrLf & "------------" & vbCrLf

            If rfiQue.Rows(0).Item("ResponseStatus") <> "Hold" And gcShow = True Then
                OutPut &= "Response #1 - " & rfiQue.Rows(0).Item("OrigReturn") & " " & resName & " : " & rfiQue.Rows(0).Item("ResponseType") & " :" & vbCrLf & (rfiQue.Rows(0).Item("Answer")).Replace("~", "'") & vbCrLf & vbCrLf
            Else
                OutPut &= "Response #1 - Response Pending" & vbCrLf & vbCrLf
            End If

            sql = "Select x.Answer, x.SequenceNum, x.Revision, x.ReturnedOn, y.Name, x.ResponseStatus, x.ResponseType From RFIAnswers x "
            sql &= " JOIN Contacts y on y.ContactID=x.ResponderID "
            sql &= " Where RFIID = " & RFIID & " AND Revision = 0"
            sql &= " Order By SequenceNum "

            rfiAns = db.ExecuteDataTable(sql)
            Try
                For Each row As DataRow In rfiAns.Rows
                    If ContactType = "General Contractor" Then
                        If Trim(row.Item("ResponseStatus")) = "CMPending" Then
                            gcShow = False
                        Else
                            gcShow = True
                        End If
                    End If
                    If Trim(row.Item("ResponseStatus")) <> "Hold" And gcShow = True Then
                        OutPut &= "Response #" & row.Item("SequenceNum") & " - " & row.Item("ReturnedOn") & " " & row.Item("Name") & " : " & row.Item("ResponseType") & " : " & vbCrLf & (row.Item("Answer")).Replace("~", "'") & vbCrLf & vbCrLf
                    Else
                        OutPut &= "Response #" & row.Item("SequenceNum") & " - Response Pending" & vbCrLf & vbCrLf
                    End If
                Next
                OutPut &= "-----------------------------------------------------" & vbCrLf
            Catch
                OutPut &= "-----------------------------------------------------" & vbCrLf
            End Try

            If revCount > 0 Then
                For Each row As DataRow In rfiQue.Rows
                    gcShow = True
                    If row.Item("RevisionQue") <> "" Then
                        'resName = ""
                        Try
                            sql = "Select Name From Contacts Where ContactID = " & row.Item("RevResponder")
                            resName = db.ExecuteScalar(sql)
                        Catch
                            resName = ""
                        End Try
                        Try
                            sql = "Select Name From Contacts Where ContactID = " & row.Item("RevRequester")
                            reqName = db.ExecuteScalar(sql)
                        Catch ex As Exception
                            reqName = ""
                        End Try
                        'If row.Item("RevAnswer") = "" Then resName = ""
                        If row.Item("RevRequestStatus") <> "Preparing" Then
                            If row.Item("RevResponseStatus") = "CMPending" Then

                            End If
                            OutPut &= "Revision #" & row.Item("Revision") & " - " & row.Item("RevResubmit") & " Required By " & row.Item("RevRequired") & " : " & vbCrLf
                            OutPut &= "Originated By: " & reqName & vbCrLf & vbCrLf
                            OutPut &= (row.Item("RevisionQue")).Replace("~", "'") & vbCrLf & vbCrLf
                            OutPut &= "Proposed: " & row.Item("RevProposed") & vbCrLf & "------------" & vbCrLf

                            If row.Item("RevResponseStatus") <> "Hold" Then
                                OutPut &= "Response #1 - " & row.Item("RevReturn") & " " & resName & " : " & row.Item("ResponseType") & " : " & vbCrLf
                                Try
                                    OutPut &= (row.Item("RevAnswer")).Replace("~", "'") & vbCrLf & vbCrLf
                                Catch ex As Exception
                                End Try
                            Else
                                OutPut &= "Response #1 - Response Pending" & vbCrLf & vbCrLf
                            End If

                            sql = "Select Answer, SequenceNum, Revision, ReturnedOn, y.Name, ResponseStatus, ResponseType From RFIAnswers "
                            sql &= " JOIN Contacts y On y.ContactID=RFIAnswers.ResponderID "
                            sql &= "Where RFIID = " & RFIID & " AND Revision = " & row.Item("Revision")
                            sql &= " Order By SequenceNum "
                            rfiAns = db.ExecuteDataTable(sql)
                            Try
                                For Each zrow As DataRow In rfiAns.Rows

                                    If ContactType = "General Contractor" Then
                                        If Trim(zrow.Item("ResponseStatus")) = "CMPending" Then
                                            gcShow = False
                                        Else
                                            gcShow = True
                                        End If
                                    End If

                                    If Trim(zrow.Item("ResponseStatus")) <> "Hold" And gcShow = True Then
                                        OutPut &= "Response #" & zrow.Item("SequenceNum") & " - " & zrow.Item("ReturnedOn") & " " & zrow.Item("Name") & " : " & zrow.Item("ResponseType") & " : " & vbCrLf & (zrow.Item("Answer")).Replace("~", "'") & vbCrLf & vbCrLf
                                    Else
                                        OutPut &= "Response #1 - Response Pending" & vbCrLf & vbCrLf
                                    End If
                                Next
                                OutPut &= "-----------------------------------------------------" & vbCrLf
                            Catch
                                OutPut &= "-----------------------------------------------------" & vbCrLf
                            End Try
                        Else
                            OutPut &= "Revision #" & row.Item("Revision") & " - Preparing" & vbCrLf & vbCrLf
                        End If
                    End If
                Next
            End If

            OutPut &= "Status: " & rfiQue.Rows(0).Item("Status") & vbCrLf

            If rfiQue.Rows(0).Item("Status") = "Closed" Then
                Try
                    sql = "Select Name From Contacts Where ContactID = " & rfiQue.Rows(0).Item("ClosedBy")
                    resName = db.ExecuteScalar(sql)
                Catch
                    resName = "Unknown"
                End Try

                OutPut &= "Closed By: " & resName & vbCrLf
                OutPut &= "Close On: " & rfiQue.Rows(0).Item("ClosedOn") & vbCrLf

            End If


            Return OutPut
        End Function

        Public Function getAttachments(nRFIID As Integer, Rev As Integer, Type As String, Res As Integer) As String
            Dim curUl As String = (HttpContext.Current.Request.Url.Host).ToString()
            Dim port As String = (HttpContext.Current.Request.Url.Port).ToString()
            Dim protocol As String = ConfigurationManager.AppSettings("Protocol")

            If port = "" Or port = 443 Then
                curUl = curUl & "/"
            Else
                curUl = curUl & ":" & port & "/"
            End If

            Dim strPhysicalPath As String = ProcLib.GetCurrentAttachmentPath() & "DistrictID_" & HttpContext.Current.Session("DistrictID") & "/"
            strPhysicalPath &= "_apprisedocs/_RFIs/RFIID_" & nRFIID & "/Rev_" & Rev

            Dim strFilePath As String = ProcLib.GetCurrentRelativeAttachmentPath() & "DistrictID_" & HttpContext.Current.Session("DistrictID") & "/"
            strFilePath &= "_apprisedocs/_RFIs/RFIID_" & nRFIID & "/Rev_" & Rev
            Dim strFiles As String = ""

            Select Case Type
                Case "Orig", "Revision"
                Case "Response"
                    strPhysicalPath &= "_Response_" & Res
                    strFilePath &= "_Response_" & Res
            End Select

            Try ' getting meeting minutes
                Dim dinfo As New IO.DirectoryInfo(strPhysicalPath)
                Dim finfo As IO.FileInfo() = dinfo.GetFiles()
                Dim dra As IO.FileInfo
                Dim path As String = "<a href='" & strFilePath & "/"
                Dim Icon As String = ""

                For Each dra In finfo
                    'Icon = "<img src='images/" & getFileImage(dra.ToString()) & "'/>"
                    Icon = ""
                    strFiles &= path & dra.ToString() & "'>" & Icon & "&nbsp;&nbsp;" & dra.ToString() & "</a><br/>"
                Next
            Catch ex As Exception
                strFiles = "No Attachments!<br/>"
            End Try

            Return strFiles
        End Function

        Public Function buildRFIQAndA(ByVal RFIID As Integer, ContactType As String) As String
            Dim rfiQue As DataTable
            Dim rfiAns As DataTable
            Dim OutPut As String = ""
            Dim sql As String = ""
            Dim revCount As Integer = checkForRevisions(RFIID)
            Dim resName As String = ""
            Dim reqName As String = ""
            Dim gcShow As Boolean

            If revCount > 0 Then
                sql = "Select x.Question As OrigQue, y.Revision, y.Question as RevisionQue, x.Proposed, x.Answer, x.RequiredBy as OrigRequired, x.TransmittedById as OrigRequester"
                sql &= ", x.Status, x.ClosedBy, x.ClosedOn, x.WorkFlowPosition, y.Proposed as RevProposed, y.Answer as RevAnswer, x.ReceivedOn as OrigReceived"
                sql &= ", x.ReturnedOn as OrigReturn, y.ResubmittedOn as RevResubmit , y.ReturnedOn RevReturn, y.RequiredBy as RevRequired, y.Revision "
                sql &= ", x.RespondedBy as OrigResponder, y.RespondedBy as RevResponder, x.RequestStatus, y.RequestStatus as RevRequestStatus, y.ToGCReleaseBy as rb1, x.ToGCReleaseBy as rb2 "
                sql &= ", x.ResponseStatus, y.ResponseStatus as RevResponseStatus, x.ResponseType, y.ResponseType as RevResponseType, y.SubmittedById as RevRequester"
                'sql &= ""
                sql &= " From RFIs x "
                'sql &= " JOIN Contacts z ON z.ContactID=x.RespondedBy"
                sql &= " JOIN RFIQuestions y ON y.RFIID=x.RFIID Where x.RFIID = " & RFIID & " AND y.Revision <> 0 "
                sql &= " Order By y.Revision"
            Else
                sql = "Select Question as OrigQue, Answer, Proposed, ReturnedOn as OrigReturn, ReceivedOn as OrigReceived, TransmittedByID as OrigRequester "
                sql &= ", RequiredBy as OrigRequired, RespondedBy as OrigResponder, x.Status, x.ClosedBy, x.ClosedOn,x.WorkFlowPosition "
                sql &= ", RequestStatus, ResponseStatus, ResponseType, x.ToGCReleaseBy as rb1, x.ToGCReleaseBy as rb2 "
                'sql &= " JOIN Contacts y ON y.ContactID=x.RespondedBy "
                sql &= " From RFIs x where RFIID = " & RFIID
            End If
            rfiQue = db.ExecuteDataTable(sql)

            If ContactType = "General Contractor" Then
                Try
                    If Not IsDBNull(rfiQue.Rows(0).Item("rb1")) Or Not IsDBNull(rfiQue.Rows(0).Item("rb2")) Then
                        gcShow = True
                    Else
                        If rfiQue.Rows(0).Item("ResponseStatus") = "CMPending" Or rfiQue.Rows(0).Item("WorkFlowPosition") = "DP:Response Pending" Then
                            If rfiQue.Rows(0).Item("WorkFlowPosition") = "GC:Acceptance Pending" Then
                                gcShow = True
                            Else
                                gcShow = False
                            End If
                        Else
                            If rfiQue.Rows(0).Item("WorkFlowPosition") = "GC:Acceptance Pending" Or rfiQue.Rows(0).Item("WorkFlowPosition") = "Complete" Then
                                gcShow = True
                            Else
                                gcShow = False
                            End If
                        End If
                    End If
                Catch ex As Exception
                End Try
                If rfiQue.Rows(0).Item("WorkFlowPosition") = "Complete" Then
                    gcShow = True
                End If
            End If

            Try
                sql = "Select Name From Contacts Where ContactID = " & rfiQue.Rows(0).Item("OrigResponder")
                resName = db.ExecuteScalar(sql)
            Catch
                resName = ""
            End Try
            Try
                sql = "Select Name From Contacts Where ContactID = " & rfiQue.Rows(0).Item("OrigRequester")
                reqName = db.ExecuteScalar(sql)
            Catch ex As Exception
                reqName = ""
            End Try

            Dim attach As String = ""

            OutPut = "Original Question " & rfiQue.Rows(0).Item("OrigReceived") & " Required By  " & rfiQue.Rows(0).Item("OrigRequired") & " : " & "<br/>"
            OutPut &= "Originated By: " & reqName & "<br/>" & "<br/>"
            OutPut &= (rfiQue.Rows(0).Item("OrigQue")).Replace("~", "'") & "<br/>" & "<br/>"
            Dim origAttach As String = getAttachments(RFIID, 0, "Orig", 0)
            OutPut &= "Proposed: " & (rfiQue.Rows(0).Item("Proposed")).Replace("~", "'") & "<br/><br/>" & origAttach & "------------" & "<br/>"

            If rfiQue.Rows(0).Item("ResponseStatus") <> "Hold" And gcShow = True Then
                attach = getAttachments(RFIID, 0, "Response", 1)
                OutPut &= "Response #1 - " & rfiQue.Rows(0).Item("OrigReturn") & " " & resName & " : " & rfiQue.Rows(0).Item("ResponseType") & " :" & "<br/>" & (rfiQue.Rows(0).Item("Answer")).Replace("~", "'") & "<br/>" & "<br/>"
                OutPut &= attach
            Else
                If rfiQue.Rows(0).Item("WorkFlowPosition") = "DP:Response Pending" Then
                    If ContactType = "Construction Manager" Or ContactType = "Design Professional" Or ContactType = "ProjectManager" Or ContactType = "District" Then
                        attach = getAttachments(RFIID, 0, "Response", 1)
                        OutPut &= "Response #1 - " & rfiQue.Rows(0).Item("OrigReturn") & " " & resName & " : " & rfiQue.Rows(0).Item("ResponseType") & " :" & "<br/>" & (rfiQue.Rows(0).Item("Answer")).Replace("~", "'") & "<br/>" & "<br/>"
                        OutPut &= attach
                    Else
                        OutPut &= "Response #1 - Response Pending" & "<br/>" & "<br/>"
                    End If
                Else
                    If ContactType = "Construction Manager" Or ContactType = "Design Professional" Or ContactType = "ProjectManager" Or ContactType = "District" Then
                        attach = getAttachments(RFIID, 0, "Response", 1)
                        OutPut &= "Response #1 - " & rfiQue.Rows(0).Item("OrigReturn") & " " & resName & " : " & rfiQue.Rows(0).Item("ResponseType") & " :" & "<br/>" & (rfiQue.Rows(0).Item("Answer")).Replace("~", "'") & "<br/>" & "<br/>"
                        OutPut &= attach
                    Else
                        OutPut &= "Response #1 - Response Pending" & "<br/>" & "<br/>"
                    End If
                    'OutPut &= "Response #1 - Response Pending" & "<br/>" & "<br/>"
                End If
            End If

            sql = "Select x.Answer, x.SequenceNum, x.Revision, x.ReturnedOn, y.Name, x.ResponseStatus, x.ResponseType From RFIAnswers x "
            sql &= " JOIN Contacts y on y.ContactID=x.ResponderID "
            sql &= " Where RFIID = " & RFIID & " AND Revision = 0"
            sql &= " Order By SequenceNum "

            rfiAns = db.ExecuteDataTable(sql)
            Try
                'gcShow = False
                For Each row As DataRow In rfiAns.Rows

                    If Trim(row.Item("ResponseStatus")) <> "Hold" And gcShow = True Then
                        attach = getAttachments(RFIID, 0, "Response", row.Item("SequenceNum"))
                        OutPut &= "Response #" & row.Item("SequenceNum") & " - " & row.Item("ReturnedOn") & " " & row.Item("Name") & " : " & row.Item("ResponseType") & " : " & "<br/>" & (row.Item("Answer")).Replace("~", "'") & "<br/>" & "<br/>"
                        OutPut &= attach
                    Else
                        If rfiQue.Rows(0).Item("WorkFlowPosition") = "DP:Response Pending" Then
                            If ContactType = "Construction Manager" Or ContactType = "Design Professional" Or ContactType = "ProjectManager" Or ContactType = "District" Then
                                attach = getAttachments(RFIID, 0, "Response", row.Item("SequenceNum"))
                                OutPut &= "Response #" & row.Item("SequenceNum") & " - " & row.Item("ReturnedOn") & " " & row.Item("Name") & " : " & row.Item("ResponseType") & " : " & "<br/>" & (row.Item("Answer")).Replace("~", "'") & "<br/>" & "<br/>"
                                OutPut &= attach
                            Else
                                OutPut &= "Response #" & row.Item("SequenceNum") & " - Response Pending" & "<br/>" & "<br/>"
                            End If
                        Else
                            If ContactType = "Construction Manager" Or ContactType = "Design Professional" Or ContactType = "ProjectManager" Or ContactType = "District" Then
                                attach = getAttachments(RFIID, 0, "Response", row.Item("SequenceNum"))
                                OutPut &= "Response #" & row.Item("SequenceNum") & " - " & row.Item("ReturnedOn") & " " & row.Item("Name") & " : " & row.Item("ResponseType") & " : " & "<br/>" & (row.Item("Answer")).Replace("~", "'") & "<br/>" & "<br/>"
                                OutPut &= attach
                            Else
                                If gcShow = True Then
                                    attach = getAttachments(RFIID, 0, "Response", row.Item("SequenceNum"))
                                    OutPut &= "Response #" & row.Item("SequenceNum") & " - " & row.Item("ReturnedOn") & " " & row.Item("Name") & " : " & row.Item("ResponseType") & " : " & "<br/>" & (row.Item("Answer")).Replace("~", "'") & "<br/>" & "<br/>"
                                    OutPut &= attach
                                Else
                                    OutPut &= "Response #" & row.Item("SequenceNum") & " - Response Pending" & "<br/>" & "<br/>"
                                End If

                            End If
                            'OutPut &= "Response #" & row.Item("SequenceNum") & " - Response Pending" & "<br/>" & "<br/>"
                        End If
                    End If
                Next
                OutPut &= "-----------------------------------------------------" & "<br/>"
            Catch
                OutPut &= "-----------------------------------------------------" & "<br/>"
            End Try

            If revCount > 0 Then
                For Each row As DataRow In rfiQue.Rows
                    If ContactType = "General Contractor" Then
                        Try
                            If Not IsDBNull(rfiQue.Rows(0).Item("rb1")) Or Not IsDBNull(rfiQue.Rows(0).Item("rb2")) Then
                                gcShow = True
                            Else
                                If rfiQue.Rows(0).Item("ResponseStatus") = "CMPending" Or rfiQue.Rows(0).Item("WorkFlowPosition") = "DP:Response Pending" Then
                                    If rfiQue.Rows(0).Item("WorkFlowPosition") = "GC:Acceptance Pending" Then
                                        gcShow = True
                                    Else
                                        gcShow = False
                                    End If
                                Else
                                    If rfiQue.Rows(0).Item("WorkFlowPosition") = "GC:Acceptance Pending" Or rfiQue.Rows(0).Item("WorkFlowPosition") = "Complete" Then
                                        gcShow = True
                                    Else
                                        gcShow = False
                                    End If
                                End If
                            End If
                        Catch ex As Exception
                        End Try
                        If rfiQue.Rows(0).Item("WorkFlowPosition") = "Complete" Then
                            gcShow = True
                        End If
                    End If

                    If row.Item("RevisionQue") <> "" Then
                        'resName = ""
                        Try
                            sql = "Select Name From Contacts Where ContactID = " & row.Item("RevResponder")
                            resName = db.ExecuteScalar(sql)
                        Catch
                            resName = ""
                        End Try
                        Try
                            sql = "Select Name From Contacts Where ContactID = " & row.Item("RevRequester")
                            reqName = db.ExecuteScalar(sql)
                        Catch ex As Exception
                            reqName = ""
                        End Try
                        'If row.Item("RevAnswer") = "" Then resName = ""
                        If row.Item("RevRequestStatus") <> "Preparing" Then
                            If row.Item("WorkFlowPosition") = "DP:Response Pending" And ContactType = "General Contractor" Then
                                OutPut &= "Revision #" & row.Item("Revision") & " - Preparing" & "<br/>" & "<br/>"
                            Else
                                If row.Item("RevResponseStatus") = "CMPending" And ContactType = "General Contractor" Then
                                    If gcShow = True Then
                                        OutPut &= "Revision #" & row.Item("Revision") & " - " & row.Item("RevResubmit") & " Required By " & row.Item("RevRequired") & " : " & "<br/>"
                                        OutPut &= "Originated By: " & reqName & "<br/>" & "<br/>"
                                        OutPut &= (row.Item("RevisionQue")).Replace("~", "'") & "<br/>" & "<br/>"
                                        attach = getAttachments(RFIID, row.Item("Revision"), "Revision", 0)
                                        OutPut &= "Proposed: " & Replace(row.Item("RevProposed"), "~", "'") & "<br/><br/>" & attach & "------------" & "<br/>"
                                    Else
                                        OutPut &= "Revision #" & row.Item("Revision") & " - Preparing" & "<br/>" & "<br/>"
                                    End If

                                Else
                                    OutPut &= "Revision #" & row.Item("Revision") & " - " & row.Item("RevResubmit") & " Required By " & row.Item("RevRequired") & " : " & "<br/>"
                                    OutPut &= "Originated By: " & reqName & "<br/>" & "<br/>"
                                    OutPut &= (row.Item("RevisionQue")).Replace("~", "'") & "<br/>" & "<br/>"
                                    attach = getAttachments(RFIID, row.Item("Revision"), "Revision", 0)
                                    OutPut &= "Proposed: " & Replace(row.Item("RevProposed"), "~", "'") & "<br/><br/>" & attach & "------------" & "<br/>"
                                End If

                                If row.Item("RevResponseStatus") <> "Hold" Then
                                    If row.Item("RevResponseStatus") = "CMPending" And ContactType = "General Contractor" Then
                                        If gcShow = True Then
                                            OutPut &= "Response #1 - " & row.Item("RevReturn") & " " & resName & " : " & row.Item("ResponseType") & " : " & "<br/>"
                                            Try
                                                OutPut &= (row.Item("RevAnswer")).Replace("~", "'") & "<br/>" & "<br/>"
                                            Catch ex As Exception
                                            End Try
                                        Else
                                            OutPut &= "Response #1 - Response Pending" & "<br/>" & "<br/>"
                                        End If
                                    Else
                                        OutPut &= "Response #1 - " & row.Item("RevReturn") & " " & resName & " : " & row.Item("ResponseType") & " : " & "<br/>"
                                        Try
                                            OutPut &= (row.Item("RevAnswer")).Replace("~", "'") & "<br/>" & "<br/>"
                                        Catch ex As Exception
                                        End Try
                                    End If
                                Else
                                    If gcShow = True Then
                                        OutPut &= "Response #1 - " & row.Item("RevReturn") & " " & resName & " : " & row.Item("ResponseType") & " : " & "<br/>"
                                        Try
                                            OutPut &= (row.Item("RevAnswer")).Replace("~", "'") & "<br/>" & "<br/>"
                                        Catch ex As Exception
                                        End Try
                                    Else
                                        OutPut &= "Response #1 - Response Pending" & "<br/>" & "<br/>"
                                    End If

                                End If

                                sql = "Select Answer, SequenceNum, Revision, ReturnedOn, y.Name, ResponseStatus, ResponseType From RFIAnswers "
                                sql &= " JOIN Contacts y On y.ContactID=RFIAnswers.ResponderID "
                                sql &= "Where RFIID = " & RFIID & " AND Revision = " & row.Item("Revision")
                                sql &= " Order By SequenceNum "
                                rfiAns = db.ExecuteDataTable(sql)
                                Try
                                    For Each zrow As DataRow In rfiAns.Rows
                                        If Trim(zrow.Item("ResponseStatus")) <> "Hold" Then
                                            If ContactType = "General Contractor" Then
                                                If gcShow = True Then
                                                    attach = getAttachments(RFIID, row.Item("Revision"), "Response", zrow.Item("SequenceNum"))
                                                    OutPut &= "Response #" & zrow.Item("SequenceNum") & " - " & zrow.Item("ReturnedOn") & " " & zrow.Item("Name") & " : " & zrow.Item("ResponseType") & " : " & "<br/>" & (zrow.Item("Answer")).Replace("~", "'") & "<br/>" & "<br/>"
                                                    OutPut &= attach
                                                Else
                                                    OutPut &= "Response #1 - Response Pending" & "<br/>" & "<br/>"
                                                End If
                                            Else
                                                attach = getAttachments(RFIID, row.Item("Revision"), "Response", zrow.Item("SequenceNum"))
                                                OutPut &= "Response #" & zrow.Item("SequenceNum") & " - " & zrow.Item("ReturnedOn") & " " & zrow.Item("Name") & " : " & zrow.Item("ResponseType") & " : " & "<br/>" & (zrow.Item("Answer")).Replace("~", "'") & "<br/>" & "<br/>"
                                                OutPut &= attach
                                            End If
                                        Else
                                            OutPut &= "Response #1 - Response Pending" & "<br/>" & "<br/>"
                                        End If
                                    Next
                                    OutPut &= "-----------------------------------------------------" & "<br/>"
                                Catch
                                    OutPut &= "-----------------------------------------------------" & "<br/>"
                                End Try
                            End If

                        Else
                            OutPut &= "Revision #" & row.Item("Revision") & " - Preparing" & "<br/>" & "<br/>"
                        End If
                    End If
                Next
            End If

            OutPut &= "Status: " & rfiQue.Rows(0).Item("Status") & "<br/>"

            If rfiQue.Rows(0).Item("Status") = "Closed" Then
                Try
                    sql = "Select Name From Contacts Where ContactID = " & rfiQue.Rows(0).Item("ClosedBy")
                    resName = db.ExecuteScalar(sql)
                Catch
                    resName = "Unknown"
                End Try

                OutPut &= "Closed By: " & resName & "<br/>"
                OutPut &= "Close On: " & rfiQue.Rows(0).Item("ClosedOn") & "<br/>"

            End If


            Return OutPut
        End Function


        Public Function GetAllProjectRFIs(ByVal ProjectID As Integer, ByVal bHideAnswered As Boolean) As DataTable
            'Do not use this one.
            Dim sql As String = "SELECT RFIs.*, Contacts_1.Name AS SubmittedTo, Contacts.Name AS SubmittedToCompany, Contacts_2.Name AS TransmittedBy, "
            sql &= "Contacts_3.Name AS TransmittedByCompany FROM RFIs LEFT OUTER JOIN "
            sql &= "Contacts AS Contacts_2 ON RFIs.TransmittedByID = Contacts_2.ContactID LEFT OUTER JOIN "
            sql &= "Contacts AS Contacts_1 ON RFIs.SubmittedToID = Contacts_1.ContactID LEFT OUTER JOIN "
            sql &= "Contacts ON Contacts_1.ParentContactID = Contacts.ContactID LEFT OUTER JOIN "
            sql &= "Contacts AS Contacts_3 ON Contacts_2.ParentContactID = Contacts_3.ContactID "

            If bHideAnswered Then
                sql &= "WHERE RFIs.ProjectID = " & ProjectID & " AND Status <> 'Answered' ORDER BY RefNumber "
            Else
                sql &= "WHERE RFIs.ProjectID = " & ProjectID & " ORDER BY RefNumber "
            End If

            Dim tbl As DataTable = db.ExecuteDataTable(sql)

            'Now look for attachments for each RFI and if present then up the count
            Dim strPhysicalPath As String = ProcLib.GetCurrentAttachmentPath() & "DistrictID_" & HttpContext.Current.Session("DistrictID")
            strPhysicalPath &= "/_apprisedocs/_RFIs/"

            Dim strRelativePath As String = ProcLib.GetCurrentRelativeAttachmentPath() & "DistrictID_" & HttpContext.Current.Session("DistrictID")
            strRelativePath &= "/_apprisedocs/_RFIs/"

            'Add an attachments colu
            Dim col As New DataColumn
            col.DataType = Type.GetType("System.String")
            col.ColumnName = "QuestionAttachments"
            tbl.Columns.Add(col)

            col = New DataColumn
            col.DataType = Type.GetType("System.String")
            col.ColumnName = "AnswerAttachments"
            tbl.Columns.Add(col)

            Dim ifilecount As Integer = 0

            For Each row As DataRow In tbl.Rows
                Dim sPath As String = strPhysicalPath & "RFIID_" & row("RFIID") & "/"
                Dim sRelPath As String = strRelativePath & "RFIID_" & row("RFIID") & "/"
                Dim folder As New DirectoryInfo(sPath)
                If Not folder.Exists Then  'There are not any files
                    row("QuestionAttachments") = "N"
                Else                'there could be files so get all and list
                    For Each fi As FileInfo In folder.GetFiles()
                        ifilecount += 1
                    Next
                    If ifilecount > 0 Then
                        row("QuestionAttachments") = "Y"
                    Else
                        row("QuestionAttachments") = "N"
                    End If
                End If

                ifilecount = 0

                sPath = strPhysicalPath & "RFIID_" & row("RFIID") & "/_answers/"
                sRelPath = strRelativePath & "RFIID_" & row("RFIID") & "/_answers/"
                folder = New DirectoryInfo(sPath)
                If Not folder.Exists Then  'There are not any files
                    row("AnswerAttachments") = "N"
                Else                'there could be files so get all and list
                    For Each fi As FileInfo In folder.GetFiles()
                        ifilecount += 1
                    Next
                    If ifilecount > 0 Then
                        row("AnswerAttachments") = "Y"
                    Else
                        row("AnswerAttachments") = "N"
                    End If
                End If

            Next

            Return tbl

        End Function

        Public Function GetSuggestedNextRefNumber() As String
            Dim intSuggest As Integer = db.ExecuteScalar("SELECT MAX(RFIID) FROM RFIs")

            'Return db.ExecuteScalar("SELECT MAX(RFIID) FROM RFIs")
            Return intSuggest + 1

        End Function

        Public Sub GetRFIForEdit(ByVal RFIID As Integer)

            Dim nDistrictID As Integer = HttpContext.Current.Session("DistrictID")

            'db.FillNewRADComboBox("SELECT ContractorID as Val, Name as Lbl FROM Contractors WHERE DistrictID = " & nDistrictID & " ORDER BY Name", CallingPage.FindControl("cboSubmittedToContractorID"), True)
            'db.FillNewRADComboBox("SELECT PMID as Val, Name as Lbl FROM ProjectManagers WHERE DistrictID = " & nDistrictID & " ORDER BY Name", CallingPage.FindControl("cboTransmittedByPMID"), True)
            'db.FillNewRADComboBox("SELECT LookupValue as Val, LookupTitle as Lbl FROM Lookups WHERE ParentTable='RFIs' AND ParentField='Status' AND DistrictID = 0 ", CallingPage.FindControl("cboStatus"), False)

            If RFIID > 0 Then
                db.FillForm(CallingPage.FindControl("Form1"), "SELECT * FROM RFIs WHERE RFIID = " & RFIID)

            End If

        End Sub

        Public Sub SaveRFI(ByVal ProjectID As Integer, ByVal RFIID As Integer, ByVal ContractID As Integer)

            Dim sql As String = ""
            If RFIID = 0 Then   'new record
                sql = "INSERT INTO RFIs (DistrictID, ProjectID, ContractID) "
                sql &= "VALUES (" & HttpContext.Current.Session("DistrictID") & "," & ProjectID & "," & ContractID & ")"
                sql &= ";SELECT NewKey = Scope_Identity()"

                RFIID = db.ExecuteScalar(sql)

            End If

            'Update record
            db.SaveForm(CallingPage.Form, "SELECT * FROM RFIs WHERE RFIID = " & RFIID)

        End Sub

        Public Function insertNewRFI(reqObj As Object) As Integer
            Dim RFIID As Integer
            Dim sql As String = ""
            Dim Status As String = ""
            If reqObj(16) > 0 Then
                Status = "Active"
            Else
                Status = "Unassigned"
            End If
            sql = "Insert Into RFIs(DistrictID,ProjectID,ContractID,RefNumber,LastUpdateOn,LastUpdateBy,ReceivedOn,RequiredBy,TransmittedByID,"
            sql &= "Question,Proposed,WorkFlowPosition,RequestStatus,ResponseStatus,Status,Answer,RFIType,SubmittedToID,CMShowToGc,AltRefNumber)"
            sql &= " Values(" & reqObj(4) & "," & reqObj(0) & "," & reqObj(1) & ",'" & reqObj(2) & "','" & DateTime.Now & "','" & reqObj(3) & "','" & Now & "','"
            sql &= reqObj(6) & "'," & reqObj(13) & ",'" & reqObj(8) & "','" & reqObj(9) & "','" & reqObj(12) & "','" & reqObj(14) & "','','" & Status & "','','" & reqObj(15) & "'," & reqObj(16) & ",0,'" & reqObj(18) & "')"
            sql &= ";SELECT NewKey = Scope_Identity()"

            RFIID = db.ExecuteScalar(sql)
            Return RFIID
        End Function

        Public Sub insertNewCheckBoxValues(obj As Object)
            Dim sql As String
            sql = "Insert Into RFICheckBox(RFIID,CIVIL,ARCH,STRUCT,PLUMBING,MECH,FP,ELECT,OTHER,NotShown,CoordProb,Interpretation,"
            sql &= "CostImpact,Conflict,TimeImpact,CreateDate,CreateBy,OtherDescription)"
            sql &= "Values(" & obj(0) & ",'" & obj(1) & "','" & obj(2) & "','" & obj(3) & "','" & obj(4) & "','" & obj(5) & "','" & obj(6) & "','"
            sql &= obj(7) & "','" & obj(8) & "','" & obj(9) & "','" & obj(10) & "','" & obj(11) & "','" & obj(12) & "','" & obj(13) & "','" & obj(14)
            sql &= "','" & DateTime.Now & "','" & obj(15) & "','" & obj(16) & "')"

            db.ExecuteNonQuery(sql)

        End Sub

        Public Sub updateCheckBoxValues(obj As Object)
            Dim sql As String
            sql = "Update RFICheckBox Set CIVIL = '" & obj(1) & "', ARCH = '" & obj(2) & "', STRUCT = '" & obj(3) & "', PLUMBING = '" & obj(4) & "', MECH = '" & obj(5)
            sql &= "', FP = '" & obj(6) & "', ELECT = '" & obj(7) & "', OTHER = '" & obj(8) & "', NotShown = '" & obj(9) & "', CoordProb = '" & obj(10) & "',"
            sql &= " Interpretation = '" & obj(11) & "', CostImpact = '" & obj(12) & "', Conflict = '" & obj(13) & "', TimeImpact = '" & obj(14) & "',"
            sql &= " OtherDescription = '" & obj(16) & "' Where RFIID = " & obj(0)

            db.ExecuteNonQuery(sql)

        End Sub

        Public Sub sendEmailNotification(mailto As String, subject As String, msgtext As String)
            Dim mail As New MailMessage
            With mail
                .From = New MailAddress("Maasco RFI Notification System <support@maasco.com>")
                .To.Add(mailto)
                .Subject = subject
                .Body = msgtext
                .IsBodyHtml = False
            End With

            Dim smtpClient As New SmtpClient
            With smtpClient
                .Host = "mail.eispro.com"
                .Credentials = New System.Net.NetworkCredential("support@eispro.com", "maubi2007")
                .Send(mail)
            End With

        End Sub

        Public Function getEmailInfo(contactID As Integer) As DataTable
            Dim emailInfo As New DataTable
            Dim sql As String = "Select Name, email from contacts where contactID = " & contactID
            emailInfo = db.ExecuteDataTable(sql)
            Return emailInfo
        End Function

        Public Sub setNewWorkFlowValues(saveType As String)
            Dim RFIID As Integer = db.ExecuteScalar("SELECT MAX(RFIID) FROM RFIs")
            Dim sql As String

            If saveType = "Release" Then
                sql = "Update RFIs set Status='Unassigned', WorkFlowPosition='CM:Review Pending', RequestStatus='Active' Where RFIID = " & RFIID
            Else
                sql = "Update RFIs set Status='None', WorkFlowPosition='None', RequestStatus='GC:Hold' Where RFIID = " & RFIID
            End If

            db.ExecuteScalar(sql)
        End Sub

        Public Sub DeleteRFI(ByVal ProjectID As Integer, ByVal RFIID As Integer)

            'Now look for attachments for each RFI and if present then up the count
            Dim strPhysicalPath As String = ProcLib.GetCurrentAttachmentPath() & "DistrictID_" & HttpContext.Current.Session("DistrictID")
            strPhysicalPath &= "/_apprisedocs/_RFIs/RFIID_" & RFIID & "/"

            Dim folder As New DirectoryInfo(strPhysicalPath)
            If folder.Exists Then
                For Each fi As FileInfo In folder.GetFiles()
                    fi.Delete()
                Next

            End If

            db.ExecuteNonQuery("DELETE FROM RFIs WHERE RFIID = " & RFIID)

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
