Imports System
Imports System.Web
Imports System.Web.UI.WebControls
Imports System.IO
Imports System.Data
Imports System.Data.SqlClient
Imports Telerik.Web.UI

Namespace Prompt

    '********************************************
    '*  Bondsite Class
    '*  
    '*  Purpose: Processes data for the Bondsite Objects
    '*
    '*  Last Mod By:    Ford James
    '*  Last Mod On:    02/12/10
    '*
    '********************************************

    Public Class BondSite
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

#Region "Bond Website Info"


        Public Function GetBondProjectInfo(ByVal ProjectID) As DataTable

            'Since the Bond Project Info uses UDF data we need to pull from UDF table and AppriseProjectData

            'Check that this project has all the correct UDF entries in the UDF Data table. If not then create them.
            db.ValidateUDFDataWithTemplate("Projects", ProjectID)

            'Get all the UDF data in for this table in display order

            Dim tbl As DataTable = db.GetFilteredUDFDataAsRows("Projects", "ProjectID", "ProjectID", ProjectID)

            'Now get the Display Title and insert as first record in the table
            Dim sql As String = "SELECT bondDisplayTitle FROM Projects WHERE ProjectID = " & ProjectID
            Dim sTitle As String = ProcLib.CheckNullDBField(db.ExecuteScalar(sql))

            Dim newtbl As DataTable = tbl.Clone
            Dim newRec As DataRow = newtbl.NewRow
            newRec("DisplayLabel") = "Display Title"
            newRec("DisplayValue") = sTitle
            newtbl.Rows.Add(newRec)

            'Now get the PublishToWeb Status and insert as second record in the table
            Dim sPublish As String = "No"
            sql = "SELECT PublishToWeb FROM Projects WHERE ProjectID = " & ProjectID
            Dim nPublish = db.ExecuteScalar(sql)
            If nPublish = 1 Then
                sPublish = "Yes"
            End If

            newRec = newtbl.NewRow
            newRec("DisplayLabel") = "Publish To Web"
            newRec("DisplayValue") = sPublish
            newtbl.Rows.Add(newRec)

            For Each row As DataRow In tbl.Rows
                Dim newrow As DataRow = newtbl.NewRow
                newrow("DisplayLabel") = row("DisplayLabel")
                newrow("DisplayValue") = row("DisplayValue")
                newtbl.Rows.Add(newrow)
            Next

            Return newtbl

        End Function

        Public Sub BuildBondProjectUDFEditForm(ByVal formtable As Table, ByVal DistrictID As Integer)

            'Adds the UDF fields and labels to the BondProjectEditForm 
            db.BuildUDFEditTable(formtable, DistrictID, "Projects")

        End Sub
        Public Sub GetBondProjectInfoForEdit(ByVal ProjectID)

            'Since the Bond Project Info uses UDF data we need to pull from UDF table and AppriseProjectData
            Dim tblUDFData As DataTable = db.GetFilteredParentAndUDFDataAsSingleRow("Projects", "ProjectID", "ProjectID", ProjectID)
            'First Fill the top level standard fields (non UDF)
            db.FillForm(CallingPage.FindControl("Form1"), tblUDFData)

            'Now fill the UDF data - this is tricky as we have to travers control collections
            db.FillUDFEditTable(CallingPage.FindControl("tblUDFs"), tblUDFData)

        End Sub

        Public Sub SaveAppriseBondInfo(ByVal ProjectID As Integer)

            'save the parent data
            Dim sql As String = "SELECT * FROM Projects WHERE ProjectID = " & ProjectID
            db.SaveForm(CallingPage.FindControl("Form1"), sql)

            'save the dynamically created UDF data controls on the form 
            db.WriteUDFDataFromForm(CallingPage.FindControl("form1"), "Projects", ProjectID)

        End Sub



#End Region

#Region "Bond News"



        Public Function GetBondNews(ByVal DistrictID) As String

            Return Proclib.CheckNullDBField(db.ExecuteScalar("SELECT AppriseCurrentNews FROM Districts WHERE DistrictID = " & DistrictID))

        End Function
        Public Function SaveBondNews(ByVal DistrictID) As String

            db.SaveForm(CallingPage.FindControl("Form1"), "SELECT * FROM Districts WHERE DistrictID = " & DistrictID)

        End Function


#End Region

#Region "Bondsite Links"
        Public Function GetAllBondLinks() As DataTable

            Return db.ExecuteDataTable("SELECT * FROM apprise_bondsite_links WHERE DistrictID = " & httpcontext.current.Session("DistrictID") & " ORDER BY Title ")

        End Function
        Public Sub GetBondsiteLinkForEdit(ByVal LinkID As Integer)

            db.FillForm(CallingPage.FindControl("Form1"), "SELECT * FROM Apprise_Bondsite_Links WHERE PrimaryKey = " & LinkID)

        End Sub
        Public Sub SaveBondsiteLink(ByVal LinkID As Integer)

            Dim sql As String = ""
            If LinkID = 0 Then   'new record
                sql = "INSERT INTO Apprise_Bondsite_Links (DistrictID) "
                sql &= "VALUES (" & HttpContext.Current.Session("DistrictID") & ")"
                sql &= ";SELECT NewKey = Scope_Identity()"

                LinkID = db.ExecuteScalar(sql)

            End If

            db.SaveForm(CallingPage.Form, "SELECT * FROM Apprise_Bondsite_Links WHERE PrimaryKey = " & LinkID)

        End Sub
        Public Sub DeleteBondsiteLink(ByVal LinkID As Integer)

            db.ExecuteNonQuery("DELETE FROM Apprise_Bondsite_Links WHERE PrimaryKey = " & LinkID)

        End Sub

#End Region

#Region "Bondsite Agenda, Meetings and Minutes"


        Public Function GetAllBondMeetings() As DataTable

            Return db.ExecuteDataTable("SELECT * FROM apprise_bondsite_meetings WHERE DistrictID = " & httpcontext.current.Session("DistrictID") & " ORDER BY MeetingDate ")

        End Function
        Public Sub GetBondsiteMeetingForEdit(ByVal MeetingID As Integer)

            db.FillForm(CallingPage.FindControl("Form1"), "SELECT * FROM Apprise_Bondsite_Meetings WHERE MeetingID = " & MeetingID)

        End Sub

        Public Sub SaveBondsiteMeeting(ByVal MeetingID As Integer)

            Dim sql As String = ""
            If MeetingID = 0 Then   'new record
                sql = "INSERT INTO Apprise_Bondsite_Meetings (DistrictID) "
                sql &= "VALUES (" & HttpContext.Current.Session("DistrictID") & ")"
                sql &= ";SELECT NewKey = Scope_Identity()"

                MeetingID = db.ExecuteScalar(sql)

            End If

            'Update Project Master
            db.SaveForm(CallingPage.Form, "SELECT * FROM Apprise_Bondsite_Meetings WHERE MeetingID = " & MeetingID)

        End Sub

        Public Sub DeleteBondsiteMeeting(ByVal MeetingID As Integer)

            Dim strPhysicalPath As String = ProcLib.GetCurrentAttachmentPath() & "DistrictID_" & httpcontext.current.Session("DistrictID") & "/_apprisedocs/_bondsite/_meetingID_" & MeetingID
            Dim folder As New DirectoryInfo(strPhysicalPath)
            If folder.Exists Then
                IO.Directory.Delete(strPhysicalPath, True)     'delete the folder
            End If

            db.ExecuteNonQuery("DELETE FROM Apprise_Bondsite_Meetings WHERE MeetingID = " & MeetingID)



        End Sub


        Public Sub SaveBondsiteAgendaMinutesPath(ByVal MeetingID As Integer, ByVal FileName As String, ByVal UploadType As String)
            Dim sTargetField As String = ""
            Dim sql As String = ""
            If UploadType = "Agenda" Then
                sTargetField = "AgendaFileName"
            Else
                sTargetField = "MinutesFileName"
            End If
            sql = "UPDATE Apprise_Bondsite_Meetings SET " & sTargetField & " = '" & FileName & "', LastUpdateOn = '" & Now() & "',"
            sql &= "LastUpdateBy='" & Httpcontext.Current.Session("UserName") & "' WHERE MeetingID = " & MeetingID
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
