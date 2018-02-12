Imports Microsoft.VisualBasic
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
    '*  Purpose: Processes data for the Change Order Objects
    '*
    '*  Last Mod By:    Scott McKown
    '*  Last Mod On:    06/06/2015
    '*
    '********************************************

    Public Class ChangeOrders
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

#Region "Project ChangeOrders"

        Public Function countAllContractCOs(ByVal ContractID As Integer, coType As String) As DataTable
            Dim sql = "Select * From PMChangeOrders Where ContractID = " & ContractID & " AND COType = '" & coType & "'"
            Dim tbl As DataTable = db.ExecuteDataTable(sql)
            Return tbl
        End Function

        Public Function getNewCOIDNumber(CoNumber As String) As Integer
            Dim sql As String = "Select COID from PMChangeOrders where CoNumber = '" & CoNumber & "'"
            Dim coid As Integer = db.ExecuteScalar(sql)
            Return coid
        End Function

        Public Function saveChangeOrder(Obj As Object) As String
            Dim sql As String = ""
            If Obj(12) = "Insert" Then
                sql = "Insert Into PMChangeOrders(DistrictID,ProjectID,ContractID,CONumber,InitiatedBy,RFIReference,CreateDate,RequiredBy,Subject,Reference,Breakdown"
                sql &= ",Request,SaveStatus,WorkFlowPosition,OriginalContractSum,ContractDaysChange,COType,Issue,CreatedBy,RequestedCOIncrease,Status)"
                sql &= " values(" & Obj(0) & "," & Obj(1) & "," & Obj(2) & ",'" & Obj(3) & "'," & Obj(4) & "," & Obj(5) & ",'" & Obj(6) & "','" & Obj(7)
                sql &= "','" & Obj(8) & "','" & Obj(9) & "','" & Obj(10) & "','" & Obj(11) & "','" & Obj(14) & "','" & Obj(16) & "'," & Obj(18) & "," & Obj(21) & ",'" & Obj(22) & "','" & Obj(23) & "'," & Obj(24) & "," & Obj(20) & ",'Preparing')"
            ElseIf Obj(12) = "Update" Then
                sql = "Update PMChangeOrders Set RequiredBy='" & Obj(7) & "', RFIReference = " & Obj(5) & ", Subject = '" & Obj(8) & "', Reference = '" & Obj(9)
                sql &= "', Breakdown = '" & Obj(10) & "', Request = '" & Obj(11) & "', SaveStatus = '" & Obj(14) & "', Status = '" & Obj(17) & "'"
                sql &= ", OriginalContractSum = '" & Obj(18) & "', PreviousCOSum = '" & Obj(19) & "', RequestedCOIncrease = '" & Obj(20) & "', ContractDaysChange = '" & Obj(21) & "'"
                sql &= ", COType = '" & Obj(22) & "', Issue = '" & Obj(23) & "', InitiatedBy=" & Obj(4) & ", AltRefNumber='" & Obj(25) & "'"

                If Obj(16) <> "NoChange" Then
                    sql &= ", WorkFlowPosition = '" & Obj(16) & "', NewWorkflow='True'"
                End If

                sql &= ", DPSelect = '" & Obj(15) & "' Where COID = " & Obj(13)
            End If

            db.ExecuteNonQuery(sql)
            Return sql
        End Function

        Public Function getOriginalContractAmount(nContractID As Integer) As Double
            Dim sql As String = "Select Amount from Contracts Where ContractID = " & nContractID
            Dim origAmount As Double = db.ExecuteScalar(sql)
            Return origAmount
        End Function

        Public Sub updatePreviousChangeOrderAmount(COID As Integer, Amount As Double)
            Dim sql = "Update PMChangeOrders Set PreviousCOSum = " & Amount & " Where COID = " & COID
            db.ExecuteNonQuery(sql)
        End Sub

        Public Function getTotalChangeOrders(nContractID As Integer) As Double
            Dim sql As String = "Select Sum(Amount) From ContractLineItems Where ContractID = " & nContractID & " AND LineType ='ChangeOrder'"
            Dim totalCOs As Double
            Try
                totalCOs = db.ExecuteScalar(sql)
            Catch ex As Exception
                totalCOs = 0
            End Try
            Return totalCOs
        End Function

        Public Function getOriginalCompletionDate(contractID As Integer) As String
            Dim sql As String = "Select ExpireDate from Contracts Where ContractID = " & contractID
            Dim expireDate = db.ExecuteScalar(sql)
            Return expireDate
        End Function

        Public Function getRefNumber(COID As Integer) As String
            Dim sql As String = "Select RefNumber From RFIs Where RFIID = " & COID
            Dim refNum As String = db.ExecuteScalar(sql)
            Return refNum
        End Function

        Public Function buildPCOReadout(COID As Integer, contactID As Integer) As String
            Dim strOut As String
            'Dim sql As String = "Select CONumber,PMChangeOrders.Subject,Issue,PMChangeOrders.RequiredBy,PMChangeOrders.CreateDate,Contacts.Name, RFIs.RefNumber From PMChangeOrders "
            Dim sql As String = "Select CONumber,PMChangeOrders.Subject,Issue,PMChangeOrders.RequiredBy,PMChangeOrders.CreateDate,Contacts.Name,RFIReference From PMChangeOrders "
            sql &= " JOIN Contacts ON Contacts.ContactID=PMChangeOrders.InitiatedBy "
            'sql &= " JOIN RFIs ON RFIs.RFIID=PMChangeOrders.RFIReference "
            sql &= " Where COID = " & COID
            Dim tbl As DataTable = db.ExecuteDataTable(sql)

            strOut = "<label style='display:inline-block;width:100%;text-align:center;font-weight:bold;height:20px'> " & tbl.Rows(0).Item("CONumber") & "</label><br/>"
            strOut &= "<b>Create Date:</b> " & tbl.Rows(0).Item("CreateDate") & "<br/>" & "<b>Initiated By:</b> " & tbl.Rows(0).Item("Name") & "<br/>"
            strOut &= "<b>Required By:</b> " & tbl.Rows(0).Item("RequiredBy") & "<br/>"

            Dim rfiStr As String = buildItemsList(COID, 0, "PCO", contactID)
            strOut &= "<b>RFI Reference:</b> <br/>"
            If rfiStr.Length > 0 Then
                strOut &= rfiStr
            Else
                strOut &= "No RFI Reference<br/>"
            End If
            'If tbl.Rows(0).Item("RFIReference") > 0 Then
            'strOut &= "<b>RFI Reference:</b> " & getRFIRefNumber(tbl.Rows(0).Item("RFIReference")) & "<br/>"
            'Else
            'strOut &= "<b>RFI Reference: </b>No RFI Reference<br/>"
            'End If
            strOut &= "<b>Subject:</b> " & Replace(tbl.Rows(0).Item("Subject"), "~", "'") & "<br/><br/>"
            strOut &= "<b>Issue:</b> " & Replace(tbl.Rows(0).Item("Issue"), "~", "'")

            Return strOut
        End Function

        Public Function getRFIRefNumber(RFIID As Integer) As String
            Dim sql As String = "Select RefNumber From RFIs Where RFIID = " & RFIID
            Return db.ExecuteScalar(sql)
        End Function

        Public Function checkSelectedItem(ParentCOID As Integer, ItemCOID As Integer, Rev As Integer, refType As String) As DataTable
            Dim sql As String = "Select COReferenceID, ItemCOID,ParentCOID,IsActive, CreateBy from PMCOItemReference Where ParentCOID=" & ParentCOID & " AND ItemCOID=" & ItemCOID
            sql &= " AND Revision = " & Rev & " AND RefType = '" & refType & "'"
            Dim tbl As DataTable = db.ExecuteDataTable(sql)

            Return tbl
        End Function

        Public Function buildItemsList(COID As Integer, Rev As Integer, itemType As String, contactID As Integer) As String
            Dim sql As String = "Select COReferenceID, PMCOItemReference.CreateBy, "
            If itemType = "PCO" Or itemType = "COR" Then
                sql &= " PMChangeOrders.CONumber From PMCOItemReference"
                sql &= " JOIN PMChangeOrders ON PMChangeOrders.COID=PMCOItemReference.ItemCOID"
            ElseIf itemType = "RFI" Then
                sql &= " RFIs.RefNumber From PMCOItemReference"
                sql &= " JOIN RFIs ON RFIs.RFIID=PMCOItemReference.ItemCOID"
            End If

            sql &= " Where ParentCOID = " & COID & " AND IsActive=1 AND Revision=" & Rev & " AND RefType = '" & itemType & "'"

            Dim tbl As DataTable = db.ExecuteDataTable(sql)
            Dim strOut As String = ""
            Dim butString1 = "<asp:LinkButton ID="
            Dim butstring2 = " runat='server'>"
            Dim butstring3 = "</asp:LinkButton>"

            For Each row As DataRow In tbl.Rows
                'If row.Item("CreateBy") = contactID Then
                If itemType = "PCO" Or itemType = "COR" Then
                    strOut &= row.Item("CONumber") & "<br/>"
                ElseIf itemType = "RFI" Then
                    strOut &= row.Item("RefNumber") & "<br/>"
                End If
                'End If
                'strOut &= butString1 & row.Item("CONumber") & butstring2 & row.Item("CONumber") & butstring3 & "<br/>"
                'strOut &= "<asp:ImageButton OnCommand='processButton' CommandArgument='" & row.Item("COReferenceID") & "' runat='server'"
                'strOut &= " ImageURL='images/trash.gif' visible='true' /><br/>"
            Next

            Return strOut
        End Function

        Public Function getContractRFIs(ContractID As Integer) As DataTable
            Dim sql = "Select RFIID, RefNumber From RFIs Where ContractID = " & ContractID
            Return db.ExecuteDataTable(sql)
        End Function

        Public Sub escalateCO(obj As Object)
            Dim sql As String = "Insert Into PMChangeOrders(DistrictID,ContractID,ProjectID,CONumber,InitiatedBy,CreateDate,RequiredBy,COType,CreatedBy,WorkFlowPosition,"
            sql &= "SaveStatus,Status,EscalateItemID,RequestedCOIncrease,Subject,Issue) Values(" & obj(0) & "," & obj(1) & "," & obj(2) & ",'" & obj(3) & "'," & obj(4)
            sql &= ",'" & obj(5) & "','" & obj(9) & "','" & obj(6) & "'," & obj(4) & ",'None','Preparing','Preparing'," & obj(7) & "," & obj(8) & ",'" & obj(10) & "','" & obj(10) & "')"

            db.ExecuteNonQuery(sql)

        End Sub

        Public Sub saveSelectedItem(Obj As Object)
            Dim sql As String = ""
            If Obj(1) = "Insert" Then
                sql = "Insert Into PMCOItemReference (ItemCOID,ParentCOID,CreateDate,CreateBy,IsActive,Revision,RefType)"
                sql &= " Values(" & Obj(0) & "," & Obj(2) & ",'" & Today & "'," & Obj(3) & "," & 1 & "," & Obj(6) & ",'" & Obj(7) & "')"
            ElseIf Obj(1) = "Update" Then
                sql = "Update PMCOItemReference Set IsActive=" & Obj(5) & " Where COReferenceID=" & Obj(4)
            End If
            db.ExecuteNonQuery(sql)

        End Sub

        Public Function getCOSelect(districtID As Integer, contractID As Integer, COtype As String, Rev As Integer) As DataTable
            Dim sql As String = "Select COID, CONumber from PMChangeOrders Where ContractID = " & contractID
            sql &= " AND districtID = " & districtID & " AND COType = '" & COtype & "' AND SaveStatus='Released' Order By COID"
            Dim tbl As DataTable = db.ExecuteDataTable(sql)

            Return tbl
        End Function

        Public Function getProjectChangeOrders(DistrictID As Integer, ProjectID As Integer, contactType As String, nContactID As Integer, sType As String) As DataTable
            'Dim sql As String = "Select *, Contacts.Name as FullName, RFIs.RefNumber from PMChangeOrders JOIN Contacts ON Contacts.ContactID=PMChangeOrders.InitiatedBy "

            Dim sql As String = "Select *, Contacts.Name as FullName from PMChangeOrders JOIN Contacts ON Contacts.ContactID=PMChangeOrders.InitiatedBy "
            'sql &= " JOIN RFIs ON RFIs.RFIID=PMChangeOrders.RFIReference "
            sql &= " Where PMChangeOrders.DistrictID = " & DistrictID & " And PMChangeOrders.ProjectID = " & ProjectID
            sql &= " AND COType='" & sType & "'"

            If contactType = "Design Professional" Then
                sql &= " AND PMChangeOrders.DPSelect = " & nContactID & " AND PMChangeOrders.Status != 'Preparing' "
                'sql &= " AND Decision !='Not Approved'"
            End If

            If contactType = "General Contractor" Or contactType = "Contractor" Then
                If Trim(sType) = "COR" Then
                    sql &= " AND (1 = Case When WorkFlowPosition = 'None' AND InitiatedBy = " & nContactID & " Then 1 Else 0 end"
                    sql &= " OR 1 = Case When WorkFlowPosition =  'GC:Receipt Pending' Then 1 Else 0 end"
                    sql &= " OR 1 = Case When WorkFlowPosition =  'PM:Completion Pending' Then 1 Else 0 end"
                    sql &= " OR 1 = Case When WorkFlowPosition =  'COR Complete' Then 1 Else 0 end)"
                ElseIf Trim(sType) = "CO" Then
                    sql &= " AND (1 = Case When WorkFlowPosition = 'None' AND InitiatedBy = " & nContactID & " Then 1 Else 0 end"
                    sql &= " OR 1 = Case When WorkFlowPosition =  'GC:Receipt Pending' Then 1 Else 0 end"
                    sql &= " OR 1 = Case When WorkFlowPosition =  'CM:Completion Pending' Then 1 Else 0 end"
                    sql &= " OR 1 = Case When WorkFlowPosition =  'CO Complete' Then 1 Else 0 end)"
                Else
                    sql &= " AND (1 = Case When WorkFlowPosition = 'None' AND InitiatedBy = " & nContactID & " Then 1 Else 0 end"
                    sql &= " OR 1 = Case When WorkFlowPosition <>  'None' Then 1 Else 0 end)"
                End If
                'sql &= " AND InitiatedBy = " & nContactID
            End If

            If contactType = "Construction Manager" Or contactType = "ProjectManager" Or contactType = "District" Then
                sql &= " AND (1 = Case When PMChangeOrders.WorkFlowPosition = 'None' AND PMChangeOrders.CreatedBy = " & nContactID & " Then 1 Else 0 end"
                sql &= " OR 1 = Case When PMChangeOrders.WorkFlowPosition <> 'None' Then 1 Else 0 end)"
            End If

            sql &= " Order by COID desc"

            Dim tbl As DataTable = db.ExecuteDataTable(sql)

            Dim reqTbl As DataTable
            Dim revTbl As DataTable
            Dim reqBy As String
            Dim col As New DataColumn
           
            col.DataType = Type.GetType("System.String")
            col.ColumnName = "PCORequiredBy"
            tbl.Columns.Add(col)

            Dim col2 As New DataColumn
            col2.DataType = Type.GetType("System.String")
            col2.ColumnName = "zRevision"
            tbl.Columns.Add(col2)

            Dim col3 As New DataColumn
            col3.DataType = Type.GetType("System.String")
            col3.ColumnName = "nDaysInProcess"
            tbl.Columns.Add(col3)

            Dim col4 As New DataColumn
            col4.DataType = Type.GetType("System.String")
            col4.ColumnName = "sSubject"
            tbl.Columns.Add(col4)

            Dim col5 As New DataColumn
            col5.DataType = Type.GetType("System.String")
            col5.ColumnName = "sCONumber"
            tbl.Columns.Add(col5)

            Dim col6 As New DataColumn
            col6.DataType = Type.GetType("System.String")
            col6.ColumnName = "CompanyName"
            tbl.Columns.Add(col6)

            For Each row As DataRow In tbl.Rows
                Dim itemNum As String
                If sType = "PCO" Then
                    'Add the Required By Date
                    sql = "Select RequiredBy From PMChangeOrderRevisions Where COID=" & row("COID") & " AND SaveStatus!='Preparing' Order By Revision"
                    reqTbl = db.ExecuteDataTable(sql)
                    If reqTbl.Rows.Count > 0 Then
                        reqBy = reqTbl.Rows(reqTbl.Rows.Count - 1).Item("RequiredBy")
                    Else
                        reqBy = row("RequiredBy")
                    End If
                    row("PCORequiredBy") = reqBy
                End If
                If sType = "COR" Then
                    'Add the days in process
                    If Trim(row("WorkFlowPosition")) = "COR Complete" Then
                        row("nDaysInProcess") = row("DaysInProcess")
                    Else
                        row("nDaysInProcess") = DateDiff("d", row("CreateDate"), Today) + 1
                    End If
                End If
                'Creates the trimmed down reference number
                itemNum = row.Item("CONumber")
                itemNum = "1" 'itemNum.Split("-").Last()
                row("sCONumber") = itemNum
                'Add the Revision number
                sql = "Select Revision From PMChangeOrderRevisions Where COID=" & row("COID") & " AND SaveStatus!='Preparing' Order By Revision"
                revTbl = db.ExecuteDataTable(sql)
                If revTbl.Rows.Count > 0 Then
                    row("zRevision") = revTbl.Rows(revTbl.Rows.Count - 1).Item("Revision").ToString
                Else
                    row("zRevision") = 0.ToString()
                End If
                'Get company
                sql = "Select Name From Contacts Where ContactID=" & row.Item("ParentContactID")
                row.Item("CompanyName") = db.ExecuteScalar(sql)
                'Format the subject to replace tilda with asterisk
                row("sSubject") = Replace(row("Subject"), "~", "'")
            Next
            Return tbl
        End Function

        Public Function getCompanyName(contractID As Integer) As String
            Dim sql As String = "Select x.ContractID, y.Name From Contracts x JOIN Contacts  y ON y.ContactID=x.ContractorID "
            sql &= " Where ContractID = " & contractID

            Dim tbl As DataTable = db.ExecuteDataTable(sql)
            Dim CoName As String = tbl.Rows(0).Item("ContractID") & " - " & tbl.Rows(0).Item("Name")

            Return CoName
        End Function



        Public Function getInitiatedBy(COID As Integer) As Integer
            Dim sql As String = "Select InitiatedBy From PMChangeOrders Where COID = " & COID
            Return db.ExecuteScalar(sql)
        End Function

        Public Function getContractTeamMembers(ContractID As Integer, ProjectID As Integer) As DataTable
            Dim sql As String = "Select Contacts.Name as Name, Contacts.ContactID AS ContactID From Contracts "
            sql &= " JOIN Contacts ON Contacts.ParentContactID=Contracts.ContractorID "
            'sql &= " JOIN TeamMembers ON TeamMembers.ContactID=Contacts.ContactID "
            'sql &= " Where TeamMembers.ProjectID=" & ProjectID & " AND Contracts.ContractID=" & ContractID
            sql &= " Where Contracts.ContractID = " & ContractID
            Dim tbl As DataTable = db.ExecuteDataTable(sql)
            Return tbl
        End Function

        Public Function getSchedules(schType As String) As DataTable
            Dim sql As String = "Select PMSchedules.*, Contacts.Name From PMSchedules JOIN Contacts ON Contacts.ContactID = PMSchedules.CreatedBy"
            sql &= " Where SchType = '" & schType & "' AND IsActive=1"

            Dim tbl As DataTable = db.ExecuteDataTable(sql)

            Return tbl
        End Function

        Public Function getProjectSchedules(projectID As Integer) As DataTable
            Dim sql As String = "Select * From PMSchedules x JOIN Contacts y ON y.ContactID = x.CreatedBy"
            sql &= " Where ProjectID = " & projectID & " AND SchType='Project' AND IsActive=1 "

            Dim tbl As DataTable = db.ExecuteDataTable(sql)

            Return tbl
        End Function

        Public Function getProjectContracts(projectID As Integer, ContactType As String, ContactID As Integer) As DataTable
            Dim sql = "Select Distinct(con.ContractID), cts.Name, Description From Contracts con JOIN Contacts cts ON cts.ContactID=con.ContractorID "
            sql &= " JOIN Contacts ctst ON ctst.ParentContactID=con.ContractorID"
            sql &= " Where con.ProjectID = " & projectID

            If ContactType.Trim() = "General Contractor" Then
                'sql &= " AND con.ContractorID = ctst.ParentContactID "
                sql &= " AND ctst.ContactID =  " & ContactID
            End If
            Dim tbl As DataTable = db.ExecuteDataTable(sql)
          

            Return tbl
        End Function

        Public Function getContractItems(contractID As Integer, nCOID As Integer) As Object
            Dim obj(6) As Object
            Dim tbl As DataTable
            Dim dbl As Double

            Dim sql As String = "Select IsNull(Sum(Amount),0) from ContractLineItems Where ContractID = " & contractID & " AND lineType ='Contract'"
            dbl = db.ExecuteScalar(sql)
            obj(0) = dbl

            sql = "Select IsNull(Sum(Amount),0) from ContractLineItems Where ContractID = " & contractID & " AND lineType ='Allowance'"
            dbl = db.ExecuteScalar(sql)
            obj(1) = dbl

            'don't need this one
            sql = "Select IsNull(Sum(TotalAmount),0) from Transactions Where ContractID = " & contractID
            dbl = db.ExecuteScalar(sql)
            obj(2) = dbl

            sql = "Select IsNull(Sum(tdet.Amount),0) from TransactionDetail tdet JOIN ContractLineItems cli ON cli.lineID=tdet.ContractLineItemID "
            sql &= " Where tdet.contractID = " & contractID & " AND cli.LineType = 'Allowance'"
            dbl = db.ExecuteScalar(sql)
            obj(3) = dbl

            sql = "Select isnull(sum(Amount),0) From ContractLineItems Where ContractID = " & contractID & " AND LineType='ChangeOrder'"
            dbl = db.ExecuteScalar(sql)
            obj(4) = dbl

            sql = "Select IsNull(Sum(RequestedCOIncrease),0) From PMChangeOrders Where COType='COR' AND Decision='Approved' AND Escalate=1 "
            sql &= " AND ContractID=" & contractID & " AND COID != " & nCOID
            dbl = db.ExecuteScalar(sql)
            obj(5) = dbl

            Return obj
        End Function

        Public Sub saveChangeOrderResponse(Obj As Object)
            Dim sql As String = ""
            If Obj(6) = "Insert" Then
                sql = "Insert Into PMChangeOrderResponses (COID,Response,ResponseType,ResponseDate,ResponseBy,SaveStatus,Revision,SeqNum)"
                sql &= " values(" & Obj(0) & ",'" & Obj(1) & "','" & Obj(2) & "','" & Obj(3) & "'," & Obj(4) & ",'" & Obj(5) & "'," & Obj(11) & "," & Obj(12) & ")"

            ElseIf Obj(6) = "Update" Then
                sql = "Update PMChangeOrderResponses Set Response = '" & Obj(1) & "', ResponseDate = '" & Obj(3) & "', SaveStatus = '" & Obj(5) & "'"
                sql &= ", ResponseType = '" & Obj(2) & "' Where PMCOResponseID = " & Obj(7)
            End If

            db.ExecuteNonQuery(sql)

            If Obj(11) > 0 Then
                sql = "Select CORevisionID From PMChangeOrderRevisions Where COID=" & Obj(0) & " AND Revision=" & Obj(11)
                Dim revNum As Integer = db.ExecuteScalar(sql)
                sql = "Update PMChangeOrderRevisions Set RequiredBy='" & Obj(19) & "' Where CORevisionID=" & revNum
            Else
                sql = "Update PMChangeOrders Set RequiredBy='" & Obj(19) & "' Where COID=" & Obj(0)
            End If

            db.ExecuteNonQuery(sql)

            'sql = "Update PMChangeOrders Set Status = '" & Obj(9) & "', DPSelect = '" & Obj(10) & "' Where COID = " & Obj(0)
            sql = "Update PMChangeOrders Set DPSelect = '" & Obj(10) & "', Escalate=" & Obj(13)
            '& ", Decision='" & Obj(14) & "' Where COID = " & Obj(0)
            If Obj(14) <> "NoChange" Then
                sql &= ", Decision='" & Obj(14) & "'"
            End If
            sql &= " Where COID = " & Obj(0)
            db.ExecuteNonQuery(sql)

            If Obj(9) = "Closed" Then
                sql = "Update PMChangeOrders Set CloseDate='" & Today & "' Where COID = " & Obj(0)
                db.ExecuteNonQuery(sql)
            End If

            If Obj(5) = "Released" Then
                If Obj(8) <> "NoChange" Then
                    sql = "Update PMChangeOrders Set WorkFlowPosition = '" & Obj(8) & "', NewWorkflow='True'"
                    If Obj(9) <> "NoChange" Then
                        sql &= ", Status = '" & Obj(9) & "'"
                    End If
                    sql &= " Where COID = " & Obj(0)
                    db.ExecuteNonQuery(sql)
                End If
            End If

            If Not IsNothing(Obj(15)) Then
                sql = "Update PMChangeOrders Set FinanceVerified = '" & Obj(15) & "' Where COID = " & Obj(0)
                db.ExecuteNonQuery(sql)
            End If
            If Not IsNothing(Obj(16)) Then
                sql = "Update PMChangeOrders Set BoardApproved='" & Obj(16) & "' Where COID = " & Obj(0)
                db.ExecuteNonQuery(sql)
            End If
            sql = "Update PMChangeOrders Set DaysInProcess=" & Obj(17) & " Where COID=" & Obj(0)
            db.ExecuteNonQuery(sql)

            sql = "Update PMChangeOrders Set AltRefNumber = '" & Obj(18) & "' Where COID=" & Obj(0)
            db.ExecuteNonQuery(sql)
        End Sub

        Public Sub updateRevisionDecision(decision As String, coid As Integer, rev As Integer)
            Dim sql As String = "Update PMChangeOrderRevisions Set Decision='" & decision & "' Where COID=" & coid & " AND Revision=" & rev
            db.ExecuteNonQuery(sql)
        End Sub

        Public Function getResponseSeqNum(nID As Integer) As Integer
            Dim sql As String = "Select SeqNum From PMChangeOrderResponses Where PMCOResponseID = " & nID
            Return db.ExecuteScalar(sql)
        End Function


        Public Sub coUpdateWFP(COID As Integer, wfp As String, status As String, newWFP As Boolean)
            Dim nWFP As String
            If newWFP = True Then nWFP = "True" Else nWFP = "False"
            Dim sql As String = "Update PMChangeOrders Set WorkFlowPosition='" & wfp & "', Status='" & status & "', NewWorkflow='" & nWFP & "'"
            sql &= " Where COID = " & COID


            db.ExecuteNonQuery(sql)

        End Sub

        Public Function getExistingResponse(COID As Integer, responseType As String, contactID As Integer, rev As Integer) As DataTable
            Dim sql As String = "Select * from PMChangeOrderResponses Where COID = " & COID & " AND Revision=" & rev
            If responseType <> "PMResponseToBoard" Then
                sql &= "  AND ResponseBy = " & contactID
            End If
            sql &= " AND responseType = '" & responseType & "'"

            Dim tbl As DataTable = db.ExecuteDataTable(sql)

            Return tbl
        End Function

        Public Function getPreparingResponse(COID As Integer, Rev As Integer, contactID As Integer, contactType As String) As DataTable
            Dim sql As String = "Select * From PMChangeOrderResponses Where COID = " & COID & " AND Revision = " & Rev & " AND SaveStatus = 'Preparing'"
            'If contactType <> "ProjectManager" Then
            sql &= " AND ResponseBy = " & contactID
            'End If
            sql &= " Order By SeqNum "
            Dim tbl As DataTable = db.ExecuteDataTable(sql)
            Return tbl
        End Function

        Public Sub checkCancelResponse(COID As Integer)
            Dim sql As String = "Select SaveStatus, PMCOResponseID From PMChangeOrderResponses Where COID=" & COID & " AND SaveStatus='Preparing'"
            Dim tbl As DataTable = db.ExecuteDataTable(sql)

            If tbl.Rows.Count > 0 Then
                sql = "update PMChangeOrderResponses Set SaveStatus='Canceled', SeqNum=0 Where PMCOResponseID=" & tbl.Rows(0).Item("PMCOResponseID")
                db.ExecuteNonQuery(sql)
                sql = "Select PMCOResponseID From PMChangeOrderResponses Where COID=" & COID & " AND ResponseType='PMResponseToDP'"
                tbl = db.ExecuteDataTable(sql)
                If tbl.Rows.Count = 0 Then
                    sql = "Update PMChangeOrders Set DPSelect=0 Where COID=" & COID
                    db.ExecuteNonQuery(sql)
                End If
            End If
        End Sub

        Public Sub cancelCORRevision(COID As Integer, Rev As Integer, nContactID As Integer, owner As String)
            Dim sql As String = "Select CORevisionID, CreatedBy From PMChangeOrderRevisions Where COID=" & COID & " AND Status='Preparing'"

            If owner = "non" Then
                sql &= " AND CreatedBy!=" & nContactID
            End If

            'sql &= " AND CreatedBy=" & nContactID
            Dim tbl As DataTable = db.ExecuteDataTable(sql)
            If tbl.Rows.Count > 0 Then
                sql = "Update PMChangeOrderRevisions Set Status='Canceled' Where CORevisionID = " & tbl.Rows(0).Item("CORevisionID")
                db.ExecuteNonQuery(sql)

                sql = "Select * From PMCOItemReference Where ParentCOID=" & COID & " AND RefType='PCO' AND Revision=" & Rev
                sql &= " AND IsActive=1 AND CreateBy=" & tbl.Rows(0).Item("CreatedBy")
                Dim pcoTbl As DataTable = db.ExecuteDataTable(sql)
                If pcoTbl.Rows.Count > 0 Then
                    For Each row As DataRow In pcoTbl.Rows
                        sql = "Update PMCOItemReference Set IsActive=0 Where COReferenceID=" & row.Item("COReferenceID")
                        db.ExecuteNonQuery(sql)
                    Next
                End If
            End If

        End Sub

        Public Function checkForResponsePrepare(COID As Integer, contactID As Integer) As String
            Dim str As String
            Dim sql = "Select pm.ResponseBy, con.Name From PMChangeOrderResponses pm JOIN Contacts con ON con.ContactID=pm.ResponseBy Where COID =" & COID & " AND SaveStatus='Preparing' AND ResponseBy <> " & contactID
            Dim tbl As DataTable = db.ExecuteDataTable(sql)

            If tbl.Rows.Count > 0 Then
                str = tbl.Rows(0).Item("Name")
            Else
                str = "none"
            End If

            Return str
        End Function

        Public Function countResponses(COID As Integer, Rev As Integer) As DataTable
            Dim sql As String = "Select * from PMChangeOrderResponses Where COID = " & COID & " AND Revision = " & Rev & " AND SaveStatus <> 'Canceled'"
            Dim tbl As DataTable = db.ExecuteDataTable(sql)
            Return tbl
        End Function

        Public Function getCOResponses(COID As Integer, Rev As Integer, rel As String, contactID As Integer) As DataTable
            Dim sql As String = "Select *, cn.ContactType, cn.Name from PMChangeOrderResponses pm JOIN Contacts cn ON cn.ContactID=pm.ResponseBy "
            sql &= " Where COID = " & COID & " AND Revision = " & Rev
            '& " AND ResponseBy=" & contactID
            If rel = "Released" Then
                sql &= " AND SaveStatus='Released'"
            Else
                sql &= " AND SaveStatus <> 'Canceled'"
            End If

            sql &= " Order By SeqNum "
            Dim tbl As DataTable = db.ExecuteDataTable(sql)

            Return tbl
        End Function

        Public Function getSingleResponse(ResponseID As Integer) As String
            Dim sql As String = "Select Response From PMChangeOrderResponses Where PMCOResponseID = " & ResponseID
            Dim response As String = db.ExecuteScalar(sql)
            Return response
        End Function

        Public Function getCOIDdata(nCOID As Integer) As DataTable
            'Dim sql As String = "Select *, cn.Name, RFIs.RefNumber From PMChangeOrders As pm JOIN Contacts as cn ON cn.ContactID=pm.InitiatedBy "
            Dim sql As String = "Select *, cn.Name From PMChangeOrders As pm JOIN Contacts as cn ON cn.ContactID=pm.InitiatedBy "

            'sql &= " JOIN Contacts dp ON dp.ContactID = pm.DPSelect"
            'sql &= " JOIN RFIs ON RFIs.RFIID=pm.RFIReference Where COID = " & nCOID
            sql &= " Where COID = " & nCOID
            Dim tbl As DataTable = db.ExecuteDataTable(sql)

            Return tbl
        End Function

        Public Function getResponseContactType(res As Integer) As DataTable
            Dim sql As String = "Select *, cn.ContactType From PMChangeOrderResponses co JOIN Contacts cn on cn.ContactID=co.Responseby Where PMCOResponseID = " & res
            Dim tbl As DataTable = db.ExecuteDataTable(sql)

            Return tbl
        End Function

        Public Function getRequiredByDate(coid As Integer, rev As Integer) As String
            Dim sql As String
            Dim zDate As String

            If rev = 0 Then
                sql = "Select RequiredBy From PMChangeOrders Where COID=" & coid
            Else
                sql = "Select RequiredBy From PMChangeOrderRevisions Where COID=" & coid & " AND Revision=" & rev
            End If
            zDate = db.ExecuteScalar(sql)

            Return zDate
        End Function

        Public Function getChangeOrderRevisions(COID As Integer) As DataTable
            Dim sql As String = "Select * from PMChangeOrderRevisions Where COID = " & COID
            sql &= " AND SaveStatus='Released' AND Status!='Canceled'"
            Dim tbl As DataTable = db.ExecuteDataTable(sql)
            Return tbl
        End Function

        Public Function getCORevisions(COID As Integer) As DataTable
            Dim sql As String = "Select * from PMChangeOrderRevisions Where COID = " & COID & " AND Status!='Canceled' Order By Revision"
            Dim tbl As DataTable = db.ExecuteDataTable(sql)
            Return tbl
        End Function

        Public Function getRevisionNumber(COID As Integer) As Integer
            Dim sql As String = "Select COID from PMChangeOrderRevisions Where COID = " & COID & " AND Status!='Canceled' AND Status!='Preparing'"
            Dim tbl As DataTable = db.ExecuteDataTable(sql)
            Dim count As Integer = tbl.Rows.Count
            Return count
        End Function

        Public Function getLatestItems(COID As Integer, Rev As Integer) As DataTable
            Dim sql As String = "Select * From PMCOItemReference Where ParentCOID = " & COID & " AND Revision = " & Rev
            Return db.ExecuteDataTable(sql)
        End Function

        Public Sub setNewWorkflowStatus(coid As Integer)
            Dim sql As String = "Update PMChangeOrders Set NewWorkflow='False' Where COID=" & coid
            db.ExecuteNonQuery(sql)
        End Sub

        Public Function checkForRevision(coid As Integer, contactID As Integer, ContactType As String, selectType As String) As DataTable
            Dim sql As String = "Select * From PMChangeOrderRevisions Where COID = " & coid
            sql &= " AND saveStatus = 'Preparing' AND Status!='Canceled'"
            If selectType = "owner" Then
                sql &= " AND CreatedBy=" & contactID
            ElseIf selectType = "non-owner" Then
                sql &= " AND CreatedBy!=" & contactID
            End If

            If ContactType = "ProjectManager" Then
                'sql &= " AND CreatedBy=" & contactID
            End If
            Dim tbl As DataTable = db.ExecuteDataTable(sql)
            Return tbl
        End Function

        Public Function checkForResponse(coid As Integer, contactID As Integer, ContactType As String) As DataTable
            Dim sql As String = "Select * From PMChangeOrderResponses Where COID=" & coid & " AND SaveStatus='Preparing' AND ResponseBy!='" & contactID & "'"
            If ContactType = "ProjectManager" Then
                'sql &= " AND ResponseBy=" & contactID
            End If
            Dim tbl As DataTable = db.ExecuteDataTable(sql)
            Return tbl
        End Function

        Public Function getRevisionData(COID As Integer, Rev As Integer) As DataTable
            Dim sql As String = "Select * from PMChangeOrderRevisions Where COID = " & COID & " AND Revision = " & Rev & " AND Status!='Canceled'"
            Dim tbl As DataTable = db.ExecuteDataTable(sql)
            Return tbl
        End Function

        Public Sub saveChangeOrderRevision(obj As Object)
            Dim sql As String
            If obj(6) = "Insert" Then
                sql = "Insert Into PMChangeOrderRevisions (COID,Revision,Issue,SaveStatus,Status,CreateDate,RequiredBy,Escalate,Decision,CreatedBy, RequestedCOIncrease) "
                sql &= " values(" & obj(1) & "," & obj(2) & ",'" & obj(3) & "','" & obj(4) & "','" & obj(5) & "','" & Today & "','" & obj(0) & "'," & obj(9) & ",'" & obj(10) & "'," & obj(11) & ",'" & obj(12) & "')"
            ElseIf obj(6) = "Update" Then
                sql = "Update PMChangeOrderRevisions Set Issue = '" & obj(3) & "', SaveStatus = '" & obj(4) & "', Status = '" & obj(5)
                sql &= "', CreateDate = '" & Today & "', RequiredBy = '" & obj(0) & "', Escalate = " & obj(9) & ", Decision = '" & obj(10) & "'"
                sql &= ", RequestedCOIncrease='" & obj(12) & "' Where CORevisionID = " & obj(8)
            End If

            db.ExecuteNonQuery(sql)

            If obj(7) <> "NoChange" Then
                sql = "Update PMChangeOrders Set WorkFlowPosition = '" & obj(7) & "', NewWorkflow='True' Where COID = " & obj(1) '
                db.ExecuteNonQuery(sql)
            End If

        End Sub

        Public Function countChangeOrderAttachments(COID As Integer, type As String, contactType As String, nRev As Integer, Seq As Integer) As Integer
            Dim strPhysicalPath As String = ProcLib.GetCurrentAttachmentPath() & "DistrictID_" & HttpContext.Current.Session("DistrictID")
            strPhysicalPath &= "/_apprisedocs/_ChangeOrders/COID_"

            Dim sPath As String = ""
            If type = "Response" Then
                sPath = strPhysicalPath & COID & "/Rev_" & nRev & "_" & type & "_" & Seq
            Else
                sPath = strPhysicalPath & COID & "/Rev_" & nRev & "_" & type
            End If


            Dim folder As New DirectoryInfo(sPath)
            Dim ifilecount As Integer
            Try
                For Each fi As FileInfo In folder.GetFiles()
                    ifilecount += 1
                Next
            Catch ex As Exception
                ifilecount = 0
            End Try

            'Return sPath
            Return ifilecount
        End Function

        Public Function getResponderName(ByVal contactID As Integer) As String
            Dim sql As String = "Select Name from Contacts where ContactID = " & contactID
            Dim name As String = db.ExecuteScalar(sql)
            Return name
        End Function

        Public Function checkDecision(coid As Integer, rev As Integer) As String
            Dim sql As String = ""
            Dim decision As String = ""
            If rev > 0 Then
                sql = "Select Decision From PMChangeOrders Where COID=" & coid
            Else
                sql = "Select Decision From PMChangeOrderRevisions Where COID=" & coid & " AND Revision=" & rev
            End If
            decision = db.ExecuteScalar(sql)
            Return decision
        End Function

        Public Function checkForCOItem(coID As Integer, coType As String) As DataTable
            Dim sql As String = "Select COReferenceID From PMCOItemReference Where itemCOID=" & coID & " AND CoType='" & coType & "'"
            Dim tbl As DataTable = db.ExecuteDataTable(sql)
            Return tbl
        End Function

        Public Function checkRevisionRelease(COID As Integer) As Object
            Dim sql As String = "Select * From PMChangeOrderRevisions Where COID=" & COID
            Dim tbl As DataTable = db.ExecuteDataTable(sql)
            Dim count As Integer = tbl.Rows.Count

            Dim obj(2) As Object
            If count > 0 Then
                obj(0) = tbl.Rows(count - 1).Item("SaveStatus")
                obj(1) = tbl.Rows(count - 1).Item("Revision")
            Else
                obj(0) = ""
                obj(1) = 0
            End If

            Return obj
        End Function

        Public Function checkForRevisionPreparing(nCOID As Integer) As DataTable
            Dim sql As String = "Select SubmittedByID, RequestStatus, Contacts.Name, Contacts.ContactType From RFIQuestions "
            sql &= " JOIN Contacts on Contacts.ContactID=RFIQuestions.SubmittedById "
            sql &= " Where RFIID = " & nCOID & " AND RequestStatus = 'Preparing'"
            Dim tbl As DataTable = db.ExecuteDataTable(sql)
            Return tbl
        End Function

        Public Function checkForActiveCOSession(COID As Integer, contactID As Integer) As DataTable
            Dim sql As String = "Select * From PMCOEditSessions Where EditStatus='Active' AND COID = " & COID
            Dim tbl As DataTable = db.ExecuteDataTable(sql)

            Return tbl
        End Function

        Public Sub sessionEnd(COID As Integer, sessID As String, contactID As Integer)
            Dim sql As String = "Update PMCOEditSessions set EditStatus='Closed', EndTime = '" & Now() & "'"
            'sql &= " Where RFIID = " & RFIID & " AND EditSessionID = '" & sessID & "' AND EditStatus = 'Active' AND ContactID = " & contactID
            sql &= " Where COID = " & COID & " AND EditStatus = 'Active' AND ContactID = " & contactID

            db.ExecuteNonQuery(sql)
        End Sub

        Public Sub sessionStart(contactID As Integer, COID As Integer, WFP As String, sessID As String)
            Dim sql As String = "Insert Into PMCOEditSessions (ContactID,EditSessionID,StartTime,EditStatus,COID,WorkFlowPosition)"
            sql &= " values (" & contactID & ",'" & sessID & "','" & Now() & "','Active'," & COID & ",'" & WFP & "')"
            db.ExecuteNonQuery(sql)
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
