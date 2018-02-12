Imports System
Imports System.Web
Imports System.Web.UI.WebControls
Imports System.IO
Imports System.Data
Imports System.Data.SqlClient

Namespace Prompt

    '********************************************
    '*  Client Class
    '*  
    '*  Purpose: Processes data for the client object
    '*
    '*  Last Mod By:    Ford James
    '*  Last Mod On:    04/02/07
    '*
    '********************************************

    Public Class Client
        Implements IDisposable

        'Properties
        Public CallingPage As Page
        Private db As PromptDataHelper

        Public Sub New()
            db = New PromptDataHelper
        End Sub

#Region "Subs and Functions"


        Public Sub GetClient(ByVal id As Integer)
            Dim sql As String = "SELECT * FROM Clients WHERE ClientID = " & id
            db.FillForm(CallingPage.FindControl("Form1"), sql)

        End Sub

        Public Function GetClientList() As DataTable
            Return db.ExecuteDataTable("SELECT * FROM Clients ORDER BY ClientName")
        End Function


        Public Sub SaveClientEditForm(ByVal clientID As Integer)
            Dim sql As String = ""
            If clientID = 0 Then                    'add
                sql = "INSERT INTO Clients (ClientName)"
                sql &= "VALUES ('NewClient' )"
                sql &= "SELECT CAST(SCOPE_IDENTITY() AS int) AS ID"
                clientID = db.ExecuteScalar(sql)
            End If

            sql = "SELECT * FROM Clients WHERE ClientID = " & clientID
            db.SaveForm(CallingPage.FindControl("Form1"), sql)

        End Sub

        Public Function DeleteClient(ByVal ClientID As Integer) As String
            Dim msg As String = ""
            Dim sql As String = "SELECT COUNT(DistrictID) as TOT FROM Districts WHERE ClientID = " & ClientID
            Dim cnt As Integer = db.ExecuteScalar(sql)
            If cnt > 0 Then
                msg = "There are " & cnt & " Districts associated with this Client. Please Delete all associated records before deleting this Client. "
            Else
                db.ExecuteNonQuery("DELETE FROM Clients WHERE ClientID = " & ClientID)
            End If

            Return msg

        End Function

#End Region

#Region "IDisposable"

        Public Overridable Sub Dispose() Implements IDisposable.Dispose
            If Not db Is Nothing Then
                db.Dispose()
            End If
        End Sub

#End Region

    End Class

End Namespace

