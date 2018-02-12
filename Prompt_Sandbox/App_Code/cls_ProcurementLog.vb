Imports System
Imports System.Web
Imports System.Web.UI.WebControls
Imports System.IO
Imports System.Data
Imports System.Data.SqlClient
Imports Telerik.Web.UI

Namespace Prompt

    '********************************************
    '*  ProcurementLog Class
    '*  
    '*  Purpose: Processes data for the ProcurementLog Objects
    '*
    '*  Last Mod By:    Ford James
    '*  Last Mod On:    07/12/09
    '*
    '********************************************

    Public Class ProcurementLog
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

#Region "Project Procurement Log"

        Public Function GetAllProjectProcurements(ByVal ProjectID As Integer) As DataTable

            Dim sql As String = "SELECT * FROM qry_Apprise_GetAllProcurements "
            sql &= "WHERE ProjectID = " & ProjectID

            Dim tbl As datatable = db.ExecuteDataTable(sql)

            'Now look for attachments for each Submittal and if present then up the count
            Dim strPhysicalPath As String = ProcLib.GetCurrentAttachmentPath() & "DistrictID_" & httpcontext.current.Session("DistrictID")
            strPhysicalPath &= "/_apprisedocs/_ProcurementLogs/"

            Dim strRelativePath As String = ProcLib.GetCurrentRelativeAttachmentPath() & "DistrictID_" & httpcontext.current.Session("DistrictID")
            strRelativePath &= "/_apprisedocs/_ProcurementLogs/"

            'Add an attachments column to the result table
            Dim col As New DataColumn
            col.DataType = Type.GetType("System.String")
            col.ColumnName = "Attachments"
            tbl.Columns.Add(col)

            For Each row As DataRow In tbl.Rows
                Dim ifilecount As Integer = 0
                Dim sPath As String = strPhysicalPath & "ProcurementID_" & row("ProcurementID") & "/"
                Dim sRelPath As String = strRelativePath & "ProcurementID_" & row("ProcurementID") & "/"
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



        Public Sub GetProcurementForEdit(ByVal ProcurementID As Integer)

            db.FillNewRADComboBox("SELECT ContractorID as Val, Name as Lbl FROM Contractors WHERE DistrictID = " & HttpContext.Current.Session("DistrictID"), CallingPage.FindControl("cboSupplierID"), True)
            db.FillNewRADComboBox("SELECT ContractorID as Val, Name as Lbl FROM Contractors WHERE DistrictID = " & HttpContext.Current.Session("DistrictID"), CallingPage.FindControl("cboSubContractorID"), True)

            If ProcurementID > 0 Then
                db.FillForm(CallingPage.FindControl("Form1"), "SELECT * FROM ProcurementLog WHERE ProcurementID = " & ProcurementID)

            End If


        End Sub

        Public Sub SaveProcurement(ByVal ProjectID As Integer, ByVal ProcurementID As Integer)


            Dim sql As String = ""
            If ProcurementID = 0 Then   'new record
                sql = "INSERT INTO ProcurementLog (DistrictID, ProjectID) "
                sql &= "VALUES (" & HttpContext.Current.Session("DistrictID") & "," & ProjectID & ")"
                sql &= ";SELECT NewKey = Scope_Identity()"

                ProcurementID = db.ExecuteScalar(sql)

            End If

            'Update record
            db.SaveForm(CallingPage.Form, "SELECT * FROM ProcurementLog WHERE ProcurementID = " & ProcurementID)


        End Sub

        Public Sub DeleteProcurement(ByVal ProjectID As Integer, ByVal ProcurementID As Integer)


            Dim strPhysicalPath As String = ProcLib.GetCurrentAttachmentPath() & "DistrictID_" & HttpContext.Current.Session("DistrictID")
            strPhysicalPath &= "/_apprisedocs/_ProcurementLogs/ProcurementID_" & ProcurementID & "/"
            Dim fileinfo As New FileInfo(strPhysicalPath)
            If fileinfo.Exists Then
                IO.File.Delete(strPhysicalPath)     'delete the file
            End If

            db.ExecuteNonQuery("DELETE FROM ProcurementLog WHERE ProcurementID = " & ProcurementID)

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
