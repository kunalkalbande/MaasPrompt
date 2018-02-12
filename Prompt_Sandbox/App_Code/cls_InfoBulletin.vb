Imports System
Imports System.Web
Imports System.Web.UI.WebControls
Imports System.IO
Imports System.Data
Imports System.Data.SqlClient
Imports Telerik.Web.UI

Namespace Prompt

    '********************************************
    '*  InfoBulletin Class
    '*  
    '*  Purpose: Processes data for the Info Bulletin Objects
    '*
    '*  Last Mod By:    Ford James
    '*  Last Mod On:    03/12/10
    '*
    '********************************************

    Public Class InfoBulletin
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

#Region "Project InfoBulletins"

        Public Function GetAllProjectInfoBulletins(ByVal ProjectID As Integer) As DataTable


            'this sql does several self joins in contacts to get different contact names and parent company for each contact
            Dim sql As String = "SELECT InfoBulletins.*, Contacts_1.Name AS IBFromName, Contacts.Name AS FromCompany, Contacts_2.Name AS IBToName, "
            sql &= "Contacts_3.Name AS ToCompany FROM InfoBulletins LEFT OUTER JOIN "
            sql &= "Contacts AS Contacts_2 ON InfoBulletins.ToID = Contacts_2.ContactID LEFT OUTER JOIN "
            sql &= "Contacts AS Contacts_1 ON InfoBulletins.FromID = Contacts_1.ContactID LEFT OUTER JOIN "
            sql &= "Contacts ON Contacts_1.ParentContactID = Contacts.ContactID LEFT OUTER JOIN "
            sql &= "Contacts AS Contacts_3 ON Contacts_2.ParentContactID = Contacts_3.ContactID "
            sql &= "WHERE ProjectID = " & ProjectID

            Dim tbl As datatable = db.ExecuteDataTable(sql)

            'Now look for attachments for each InfoBulletin and if present then up the count
            Dim strPhysicalPath As String = ProcLib.GetCurrentAttachmentPath() & "DistrictID_" & httpcontext.current.Session("DistrictID")
            strPhysicalPath &= "/_apprisedocs/_InfoBulletins/"

            Dim strRelativePath As String = ProcLib.GetCurrentRelativeAttachmentPath() & "DistrictID_" & httpcontext.current.Session("DistrictID")
            strRelativePath &= "/_apprisedocs/_InfoBulletins/"

            'Add an attachments column to the result table
            Dim col As New DataColumn
            col.DataType = Type.GetType("System.String")
            col.ColumnName = "Attachments"
            tbl.Columns.Add(col)

            For Each row As DataRow In tbl.Rows
                Dim ifilecount As Integer = 0
                Dim sPath As String = strPhysicalPath & "InfoBulletinID_" & row("InfoBulletinID") & "/"
                Dim sRelPath As String = strRelativePath & "InfoBulletinID_" & row("InfoBulletinID") & "/"
                Dim folder As New DirectoryInfo(sPath)
                If Not folder.Exists Then  'There are not any files
                    row("Attachments") = "N"
                Else                'there could be files so get all and list
                    For Each fi As FileInfo In folder.GetFiles()
                        ifilecount += 1
                    Next
                    If ifilecount > 0 Then
                        row("Attachments") = "Y"
                    Else
                        row("Attachments") = "N"
                    End If
                End If
            Next

            Return tbl

        End Function



        Public Sub GetInfoBulletinForEdit(ByVal InfoBulletinID As Integer)

  
            If InfoBulletinID > 0 Then
                db.FillForm(CallingPage.FindControl("Form1"), "SELECT * FROM InfoBulletins WHERE InfoBulletinID = " & InfoBulletinID)

            End If


        End Sub

        Public Sub SaveInfoBulletin(ByVal ProjectID As Integer, ByVal InfoBulletinID As Integer)


            Dim sql As String = ""
            If InfoBulletinID = 0 Then   'new record
                sql = "INSERT INTO InfoBulletins (DistrictID, ProjectID) "
                sql &= "VALUES (" & HttpContext.Current.Session("DistrictID") & "," & ProjectID & ")"
                sql &= ";SELECT NewKey = Scope_Identity()"

                InfoBulletinID = db.ExecuteScalar(sql)

            End If

            'Update record
            db.SaveForm(CallingPage.Form, "SELECT * FROM InfoBulletins WHERE InfoBulletinID = " & InfoBulletinID)


        End Sub

        Public Sub DeleteInfoBulletin(ByVal ProjectID As Integer, ByVal InfoBulletinID As Integer)


            Dim strPhysicalPath As String = ProcLib.GetCurrentAttachmentPath() & "DistrictID_" & httpcontext.current.Session("DistrictID")
            strPhysicalPath &= "/_apprisedocs/_InfoBulletins/InfoBulletinID_" & InfoBulletinID & "/"
            Dim fileinfo As New FileInfo(strPhysicalPath)
            If fileinfo.Exists Then
                IO.File.Delete(strPhysicalPath)     'delete the file
            End If

            db.ExecuteNonQuery("DELETE FROM InfoBulletins WHERE InfoBulletinID = " & InfoBulletinID)

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
