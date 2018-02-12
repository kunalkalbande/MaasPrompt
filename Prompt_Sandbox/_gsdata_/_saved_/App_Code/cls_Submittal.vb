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

        Private db As PromptDataHelper

        Public Sub New()
            db = New PromptDataHelper

        End Sub

#Region "Project Submittals"

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



        Public Sub GetSubmittalForEdit(ByVal SubmittalID As Integer, ByVal ProjectID As Integer)

            'db.FillNewRADComboBox("SELECT ContractorID as Val, Name as Lbl FROM Contractors WHERE DistrictID = " & HttpContext.Current.Session("DistrictID") & " ORDER BY Name", CallingPage.FindControl("cboSubmittedToContractorID"), True, True)
            db.FillRADListBox("SELECT LookupValue as Val, LookupTitle as Lbl FROM Lookups WHERE ParentTable='Submittals' AND ParentField = 'Status' AND DistrictID = 0", CallingPage.FindControl("cboStatusList"))


            If SubmittalID > 0 Then

                db.FillForm(CallingPage.FindControl("Form1"), "SELECT * FROM Submittals WHERE SubmittalID = " & SubmittalID)

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
            Dim txtStatus As HiddenField = Callingpage.form.Findcontrol("txtStatus")
            sql = "UPDATE Submittals SET Status = '" & txtStatus.Value & "' WHERE SubmittalID = " & SubmittalID
            db.executenonquery(sql)


        End Sub

        Public Sub DeleteSubmittal(ByVal ProjectID As Integer, ByVal SubmittalID As Integer)


            Dim strPhysicalPath As String = ProcLib.GetCurrentAttachmentPath() & "DistrictID_" & httpcontext.current.Session("DistrictID")
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
