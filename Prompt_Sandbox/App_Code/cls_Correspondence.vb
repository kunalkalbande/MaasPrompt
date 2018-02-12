Imports System
Imports System.Web
Imports System.Web.UI.WebControls
Imports System.IO
Imports System.Data
Imports System.Data.SqlClient
Imports Telerik.Web.UI

Namespace Prompt

    Public Class Correspondence
        Implements IDisposable

        Private db As PromptDataHelper
        Public Reader As SqlDataReader
        Public DataTable As DataTable

        Public Sub New()
            db = New PromptDataHelper
        End Sub

        Public Function getRecordsCount(projectID As Integer, contractID As Integer, level As String) As DataTable
            Dim sql As String = ""
            Select Case level
                Case "Project"
                    sql = "Select * From PMCorrespondence Where CorrLevel='Project' AND ProjectID = " & projectID
                Case "Contract"
                    sql = "Select * From PMCorrespondence Where CorrLevel='Contract' AND ContractID = " & contractID
            End Select

            Return db.ExecuteDataTable(sql)
        End Function

        Public Function getProjectNumber(ProjectID As Integer) As String
            Dim sql As String = "Select ProjectNumber From Projects Where ProjectID=" & ProjectID
            Dim projNum As String = db.ExecuteScalar(sql)

            Return projNum
        End Function

        Public Sub updateFileName(fileName As String, CorrID As Integer)
            Dim sql As String = "Update PMCorrespondence Set FileName = '" & fileName & "' Where CorrID = " & CorrID
            db.ExecuteNonQuery(sql)
        End Sub

        Public Function getProjectName(projectID As Integer) As String
            Dim sql As String = "Select ProjectName From Projects Where ProjectID = " & projectID
            Return db.ExecuteScalar(sql)
        End Function

        Public Function getCorrespondenceData(corrID As Integer) As DataTable
            Dim sql As String = "Select * From PMCorrespondence Where CorrID = " & corrID
            Dim tbl As DataTable = db.ExecuteDataTable(sql)

            Return tbl
        End Function

        Public Function getCorrespondenceLevel(corrLevel As String, project As Integer, contactID As Integer) As DataTable
            Dim sql As String = "Select PMCorrespondence.*, Contacts.Name from PMCorrespondence JOIN Contacts ON Contacts.ContactID = PMCorrespondence.CreateBy"
            sql &= " Where ProjectID = " & project & " AND CorrLevel = '" & corrLevel & "' AND IsActive = 1"
            sql &= " Order By CorrID "
            Dim tbl As DataTable = db.ExecuteDataTable(sql)

            Return tbl
        End Function

        Public Function getCorrespondenceLevelSelect(corrLevel As String, project As Integer, contactID As Integer) As DataTable
            Dim sql As String = "Select PMCorrespondence.*, Contacts.Name from PMCorrespondence JOIN Contacts ON Contacts.ContactID = PMCorrespondence.CreateBy"
            sql &= " Where CorrLevel='" & corrLevel & "' AND ProjectID = " & project & " AND PMCorrespondence.CreateBy = " & contactID
            sql &= " OR Exists(Select CorrID From PMCorrRecipients pcr Where pcr.ContactID=" & contactID & " AND CorrID = PMCorrespondence.CorrID AND IsActive=1 AND PMCorrespondence.CorrLevel= '" & corrLevel & "' AND ProjectID = " & project & ")"
            'sql &= " AND ProjectID = " & project & " AND IsActive = 1"

            sql &= " Order By CorrID "
            Dim tbl As DataTable = db.ExecuteDataTable(sql)

            Return tbl
        End Function

        Public Function getCorrespondenceByRoll(corrLevel As String, project As Integer, contactID As Integer, contactType As String) As DataTable
            Dim sql As String = "Select PMCorrespondence.*, Contacts.Name from PMCorrespondence JOIN Contacts ON Contacts.ContactID = PMCorrespondence.CreateBy"
            sql &= " JOIN Projects ON Projects.ProjectID=" & project
            sql &= " JOIN Contacts cn ON cn.ContactID=" & contactID

            If corrLevel = "Contract" Then
                sql &= "JOIN Contracts ON Contracts.ContractID=PMCorrespondence.ContractID "
            End If

            sql &= " Where CorrLevel='" & corrLevel & "' AND PMCorrespondence.ProjectID = " & project & " AND PMCorrespondence.CreateBy = " & contactID
 
            Select Case Trim(contactType)
                Case "ProjectManager", "District"
                    sql &= " OR (cn.ContactType = 'ProjectManager' OR cn.ContactType='District') AND corrLevel= '" & corrLevel & "' AND PMCorrespondence.ProjectID =" & project
                Case "Construction Manager"
                    sql &= " OR (Projects.CMID=cn.ParentContactID AND corrLevel='" & corrLevel & "' AND PMCorrespondence.ProjectID =" & project & ")"
                Case "General Contractor"
                    If corrLevel = "Contract" Then
                        sql &= " OR (Contracts.ContractorID=cn.ParentContactID) AND corrLevel='Contract' AND PMCorrespondence.ProjectID=" & project
                    End If
                Case "Design Professional"
                    'If corrLevel = "Contract" Then
                    sql &= " OR (Projects.ArchID=cn.ParentContactID) AND corrLevel='Contract' AND PMCorrespondence.ProjectID=" & project
                    'End If
            End Select

            sql &= " Order By CorrID "
            Dim tbl As DataTable = db.ExecuteDataTable(sql)

            Return tbl
        End Function

        Public Function checkRecipient(corrID As Integer, contactID As Integer) As DataTable
            Dim sql As String = "Select * From PMCorrRecipients Where corrID = " & corrID & " AND ContactID = " & contactID
            Dim tbl As DataTable = db.ExecuteDataTable(sql)

            Return tbl
        End Function

        Public Sub processRecipient(obj As Object)
            Dim sql As String

            If obj(4) = "Insert" Then
                sql = "Insert Into PMCorrRecipients(CorrID,ContactID,IsActive,CreatedBy,LastUpdate)"
                sql &= " Values(" & obj(0) & "," & obj(1) & "," & 1 & "," & obj(3) & ",'" & Now & "')"
            ElseIf obj(4) = "Update" Then
                sql = "Update PMCorrRecipients Set isActive = " & obj(5) & " Where CorrID = " & obj(0) & " AND ContactID = " & obj(1)
            End If

            db.ExecuteDataTable(sql)

        End Sub

        Public Function createRecipientList(corrID As Integer) As String
            Dim sql As String = "Select PCR.ContactID, Contacts.Name contName, com.Name comName from PMCorrRecipients As PCR "
            sql &= " JOIN Contacts ON Contacts.ContactID = PCR.ContactID "
            sql &= " JOIN Contacts com ON com.ContactID = Contacts.ParentContactID"
            sql &= " Where CorrID = " & corrID & " AND IsActive = 1 "
            sql &= " Order By Contacts.LastName"

            Dim tbl As DataTable = db.ExecuteDataTable(sql)
            Dim outPut As String = ""

            If tbl.Rows.Count > 0 Then
                For Each row As DataRow In tbl.Rows
                    outPut &= row.Item("contName") & " - " & row.Item("comName") & "<br/>"
                Next
            Else
                outPut = "No Recipients Selected"
            End If
          
            Return outPut
        End Function


        Public Sub removeCorrespondence(corrID As Integer)
            Dim sql As String = "Update PMCorrespondence Set IsActive=0 Where CorrID = " & corrID
            db.ExecuteNonQuery(sql)
        End Sub

        Public Function getAuthor(corrID As Integer) As Integer
            Dim sql As String = "Select CreateBy From PMCorrespondence Where CorrID = " & corrID
            Return db.ExecuteScalar(sql)
        End Function

        Public Function saveCorrespondenceData(obj As Object) As String
            Dim sql As String = ""
            If obj(0) = "New" Then
                sql = "Insert Into PMCorrespondence(DistrictID,ProjectID,ContractID,CorrNumber,CorrLevel,CreateDate,CreateBy,FileName,CorrName,CorrType,IsActive)"
                sql &= " Values(" & obj(8) & "," & obj(3) & "," & obj(4) & ",'" & obj(1) & "','" & obj(2) & "','" & obj(9) & "'," & obj(10)
                sql &= ",'" & obj(7) & "','" & obj(6) & "','" & obj(5) & "'," & 1 & ")"

            ElseIf obj(0) = "Update" Then
                sql = "Update PMCorrespondence Set CorrType = '" & obj(5) & "', CorrName = '" & obj(6) & "'"
                sql &= " Where CorrID = " & obj(11)
            End If

            db.ExecuteNonQuery(sql)

            Return sql

        End Function

        Public Function getCorrID(corrNumber As String) As Integer
            Dim sql As String = "Select CorrID From PMCorrespondence Where CorrNumber = '" & corrNumber & "'"
            Dim corrID As Integer = db.ExecuteScalar(sql)

            Return corrID
        End Function

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

