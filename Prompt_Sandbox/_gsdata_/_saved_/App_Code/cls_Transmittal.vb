Imports System
Imports System.Web
Imports System.Web.UI.WebControls
Imports System.IO
Imports System.Data
Imports System.Data.SqlClient
Imports Telerik.Web.UI

Namespace Prompt

    '********************************************
    '*  Transmittal Class
    '*  
    '*  Purpose: Processes data for the Transmittal Objects
    '*
    '*  Last Mod By:    Ford James
    '*  Last Mod On:    04/1/10
    '*
    '********************************************

    Public Class Transmittal
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

#Region "Transmittal"

        Public Function GetAllProjectTransmittals(ByVal ProjectID As Integer) As DataTable

            'this sql does several self joins in contacts to get different contact names and parent company for each contact
            Dim sql As String = "SELECT Transmittals.*, Contacts_1.Name AS FromName, Contacts.Name AS FromCompany, Contacts_2.Name AS ToName, "
            sql &= "Contacts_3.Name AS ToCompany FROM Transmittals LEFT OUTER JOIN "
            sql &= "Contacts AS Contacts_2 ON Transmittals.ToID = Contacts_2.ContactID LEFT OUTER JOIN "
            sql &= "Contacts AS Contacts_1 ON Transmittals.FromID = Contacts_1.ContactID LEFT OUTER JOIN "
            sql &= "Contacts ON Contacts_1.ParentContactID = Contacts.ContactID LEFT OUTER JOIN "
            sql &= "Contacts AS Contacts_3 ON Contacts_2.ParentContactID = Contacts_3.ContactID "
            sql &= "WHERE ProjectID = " & ProjectID

            Dim tbl As DataTable = db.ExecuteDataTable(sql)



            'Now look for attachments for each Submittal and if present then up the count
            Dim strPhysicalPath As String = ProcLib.GetCurrentAttachmentPath() & "DistrictID_" & HttpContext.Current.Session("DistrictID")
            strPhysicalPath &= "/_apprisedocs/_Transmittals/"

            Dim strRelativePath As String = ProcLib.GetCurrentRelativeAttachmentPath() & "DistrictID_" & HttpContext.Current.Session("DistrictID")
            strRelativePath &= "/_apprisedocs/_Transmittals/"

            'Add an attachments column to the result table
            Dim col As New DataColumn
            col.DataType = Type.GetType("System.String")
            col.ColumnName = "Attachments"
            tbl.Columns.Add(col)

            For Each row As DataRow In tbl.Rows
                Dim ifilecount As Integer = 0
                Dim sPath As String = strPhysicalPath & "TransmittalID_" & row("TransmittalID") & "/"
                Dim sRelPath As String = strRelativePath & "TransmittalID_" & row("TransmittalID") & "/"
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



        Public Sub GetTransmittalForEdit(ByVal TransmittalID As Integer)

            If TransmittalID > 0 Then
                db.FillForm(CallingPage.FindControl("Form1"), "SELECT * FROM Transmittals WHERE TransmittalID = " & TransmittalID)

            End If


        End Sub

        Public Sub SaveTransmittal(ByVal ProjectID As Integer, ByVal TransmittalID As Integer)


            Dim sql As String = ""
            If TransmittalID = 0 Then   'new record
                sql = "INSERT INTO Transmittals (DistrictID, ProjectID) "
                sql &= "VALUES (" & HttpContext.Current.Session("DistrictID") & "," & ProjectID & ")"
                sql &= ";SELECT NewKey = Scope_Identity()"

                TransmittalID = db.ExecuteScalar(sql)

            End If

            'Update record
            db.SaveForm(CallingPage.Form, "SELECT * FROM Transmittals WHERE TransmittalID = " & TransmittalID)


        End Sub

        Public Sub DeleteTransmittal(ByVal ProjectID As Integer, ByVal TransmittalID As Integer)


            Dim strPhysicalPath As String = ProcLib.GetCurrentAttachmentPath() & "DistrictID_" & HttpContext.Current.Session("DistrictID")
            strPhysicalPath &= "/_apprisedocs/_Transmittals/TransmittalID_" & TransmittalID & "/"
            Dim fileinfo As New FileInfo(strPhysicalPath)
            If fileinfo.Exists Then
                IO.File.Delete(strPhysicalPath)     'delete the file
            End If

            db.ExecuteNonQuery("DELETE FROM Transmittals WHERE TransmittalID = " & TransmittalID)

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
