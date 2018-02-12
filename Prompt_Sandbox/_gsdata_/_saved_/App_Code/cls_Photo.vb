Imports System
Imports System.Web
Imports System.Web.UI.WebControls
Imports System.IO
Imports System.Data
Imports System.Data.SqlClient
Imports Telerik.Web.UI

Namespace Prompt

    '********************************************
    '*  Photo Class
    '*  
    '*  Purpose: Processes data for the Photo Objects
    '*
    '*  Last Mod By:    Ford James
    '*  Last Mod On:    01/12/10
    '*
    '********************************************

    Public Class Photo
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


#Region "Photos"

        Public Function GetAdditionalPhotos(ByVal nProjectID As Integer) As DataTable

            'TEMP: If the order has not been set, then update it initially first time through - eventulally we can eliminate this check
            Dim sql As String = "SELECT COUNT(ApprisePhotoID) FROM ApprisePhotos WHERE ProjectID = " & nProjectID & " AND DisplayOrder IS NULL"
            Dim result As Integer = db.ExecuteScalar(sql)
            If result > 0 Then
                sql = "SELECT * FROM ApprisePhotos WHERE ProjectID = " & nProjectID
                db.FillDataTableForUpdate(sql)
                Dim i As Integer = 0
                For Each row As DataRow In db.DataTable.Rows
                    i += 5
                    row("DisplayOrder") = i
                    If HttpContext.Current.Session("DistrictID") = 56 Then   'TEMP:might as well update this for COD while we are at it.
                        row("PostToWeb") = 1
                    End If
                Next
                db.SaveDataTableToDB()
            End If

            sql = "SELECT * FROM ApprisePhotos WHERE ProjectID = " & nProjectID & " ORDER BY DisplayOrder"
            Return db.ExecuteDataTable(sql)

        End Function

    
        Public Sub GetPhotoForEdit(ByVal nPhotoID As Integer)

            Dim form As Control = CallingPage.FindControl("Form1")  ' get ref to calling form
            db.FillForm(form, "SELECT * FROM ApprisePhotos WHERE ApprisePhotoID =" & nPhotoID)

        End Sub
        Public Function SavePhoto(ByVal nProjectID As Integer, ByVal nPhotoID As Integer) As Integer

            Dim sql As String = ""
            If nPhotoID = 0 Then   'new record
                sql = "INSERT INTO ApprisePhotos (DistrictID,CollegeID,ProjectID) "
                sql &= "VALUES (" & HttpContext.Current.Session("DistrictID") & "," & HttpContext.Current.Session("CollegeID") & "," & nProjectID & ")"
                sql &= ";SELECT NewKey = Scope_Identity()"
                nPhotoID = db.ExecuteScalar(sql)

            End If

            'Update Project Master
            db.SaveForm(CallingPage.Form, "SELECT * FROM ApprisePhotos WHERE ApprisePhotoID = " & nPhotoID)

            Return nPhotoID

        End Function
        Public Sub DeletePhoto(ByVal ProjectID As Integer, ByVal nPhotoID As Integer)

            Dim strBasePhotoPath As String = ProcLib.GetCurrentAttachmentPath() & "DistrictID_" & HttpContext.Current.Session("DistrictID") & "\_apprisedocs\_photos\ProjectID_" & ProjectID & "\"
            Dim strPhotoPath As String = strBasePhotoPath & nPhotoID & ".jpg"
            Dim strThumbPhotoPath As String = strBasePhotoPath & nPhotoID & "_thumb.jpg"

            db.ExecuteNonQuery("DELETE FROM ApprisePhotos WHERE ApprisePhotoId = " & nPhotoID)

            'Delete photo if present
            Dim file As New FileInfo(strPhotoPath)
            If file.Exists Then
                file.Delete()
            End If

            Dim fileThumb As New FileInfo(strThumbPhotoPath)
            If fileThumb.Exists Then
                fileThumb.Delete()
            End If

        End Sub

        Public Sub DeleteMainPhoto(ByVal ProjectID As Integer)

            Dim strBasePhotoPath As String = ProcLib.GetCurrentAttachmentPath() & "DistrictID_" & HttpContext.Current.Session("DistrictID") & "\_apprisedocs\_photos\ProjectID_" & ProjectID & "\"
            Dim strPhotoPath As String = strBasePhotoPath & "main.jpg"
            Dim strThumbPhotoPath As String = strBasePhotoPath & "main_thumb.jpg"

            'Delete photo if present
            Dim file As New FileInfo(strPhotoPath)
            If file.Exists Then
                file.Delete()
            End If

            Dim fileThumb As New FileInfo(strThumbPhotoPath)
            If fileThumb.Exists Then
                fileThumb.Delete()
            End If

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
