Imports System
Imports System.Web
Imports System.Web.UI.WebControls
Imports System.IO
Imports System.Data
Imports System.Data.SqlClient
Imports Telerik.Web.UI

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

        Public Sub New()
            db = New PromptDataHelper

        End Sub


#Region "Project RFIs"

        Public Function GetAllProjectRFIs(ByVal ProjectID As Integer, ByVal bHideAnswered As Boolean) As DataTable

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

            Return db.ExecuteScalar("SELECT MAX(RFIID) FROM RFIs")


        End Function

        Public Sub GetRFIForEdit(ByVal RFIID As Integer)

            Dim nDistrictID As Integer = HttpContext.Current.Session("DistrictID")

            'db.FillNewRADComboBox("SELECT ContractorID as Val, Name as Lbl FROM Contractors WHERE DistrictID = " & nDistrictID & " ORDER BY Name", CallingPage.FindControl("cboSubmittedToContractorID"), True)
            'db.FillNewRADComboBox("SELECT PMID as Val, Name as Lbl FROM ProjectManagers WHERE DistrictID = " & nDistrictID & " ORDER BY Name", CallingPage.FindControl("cboTransmittedByPMID"), True)
            db.FillNewRADComboBox("SELECT LookupValue as Val, LookupTitle as Lbl FROM Lookups WHERE ParentTable='RFIs' AND ParentField='Status' AND DistrictID = 0 ", CallingPage.FindControl("cboStatus"), False)

            If RFIID > 0 Then
                db.FillForm(CallingPage.FindControl("Form1"), "SELECT * FROM RFIs WHERE RFIID = " & RFIID)

            End If


        End Sub

        Public Sub SaveRFI(ByVal ProjectID As Integer, ByVal RFIID As Integer)


            Dim sql As String = ""
            If RFIID = 0 Then   'new record
                sql = "INSERT INTO RFIs (DistrictID, ProjectID) "
                sql &= "VALUES (" & HttpContext.Current.Session("DistrictID") & "," & ProjectID & ")"
                sql &= ";SELECT NewKey = Scope_Identity()"

                RFIID = db.ExecuteScalar(sql)

            End If

            'Update record
            db.SaveForm(CallingPage.Form, "SELECT * FROM RFIs WHERE RFIID = " & RFIID)


        End Sub

        Public Sub DeleteRFI(ByVal ProjectID As Integer, ByVal RFIID As Integer)

            'Now look for attachments for each RFI and if present then up the count
            Dim strPhysicalPath As String = ProcLib.GetCurrentAttachmentPath() & "DistrictID_" & httpcontext.current.Session("DistrictID")
            strPhysicalPath &= "/_apprisedocs/_RFIs/RFIID_" & RFIID & "/"

            Dim folder As New DirectoryInfo(strPhysicalPath)
            If folder.Exists Then
                For Each fi As FileInfo In folder.GetFiles()
                    fi.delete()
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
