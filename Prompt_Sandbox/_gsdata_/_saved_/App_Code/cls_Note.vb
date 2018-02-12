Imports System
Imports System.Web
Imports System.Web.UI.WebControls
Imports System.IO
Imports System.Data.SqlClient

Namespace Prompt

    '********************************************
    '*  Flag Class
    '*  
    '*  Purpose: Processes data for the Note Object
    '*
    '*  Last Mod By:    Ford James
    '*  Last Mod On:    4/2/08
    '* Note: Projects, Contracts and Transaction notes are stored in the notes db using just the 
    '*       Parent Id  
    '*
    '********************************************

    Public Class promptNote
        Implements IDisposable

        'Properties
        Public CallingPage As Page
        Public ParentRecID As Integer = 0
        Public ParentRecType As String = ""

        Private db As PromptDataHelper

        Public Sub New()
            db = New PromptDataHelper
        End Sub

#Region "Subs and Functions"

        Public Function GetNotes(ByVal KeyField As String, ByVal RecID As Integer) As DataTable

            Dim sFilter As String = " WHERE " & KeyField & " = " & RecID & " ORDER BY CreatedOn DESC"
            Dim sUserRole As String = HttpContext.Current.Session("UserRole")

            If sUserRole <> "TechSupport" Then
                If sUserRole = "Project Accountant" Then
                    sFilter = " WHERE (Visibility <> 'ProjectManager'  OR Visibility IS NULL) AND " & KeyField & " = " & RecID & " ORDER BY CreatedOn DESC"

                ElseIf sUserRole = "Project Manager" Then
                    sFilter = " WHERE (Visibility <> 'Accountant' OR Visibility IS NULL) AND " & KeyField & " = " & RecID & " ORDER BY CreatedOn DESC"

                Else
                    sFilter = " WHERE ((Visibility <> 'Accountant' AND  Visibility <> 'ProjectManager') OR Visibility IS NULL ) AND " & KeyField & " = " & RecID & " ORDER BY CreatedOn DESC"
                End If
            End If

            Dim sql As String = "SELECT * FROM Notes " & sFilter
            Return db.ExecuteDataTable(sql)

        End Function
    
        Public Sub GetNoteForEdit(ByVal nNoteID As Integer)
            Dim form As Control = CallingPage.FindControl("Form1")  ' get ref to calling form
            db.FillForm(form, "SELECT * FROM Notes WHERE NoteID =" & nNoteID)

        End Sub

        Public Sub SaveNote(ByVal noteid As Integer)
            Using rs As New PromptDataHelper
                Dim sql As String = ""
                If noteid = 0 Then

                    sql = "INSERT INTO Notes (CreatedBy, CreatedOn," & ParentRecType & ",DistrictID,LastUpdateBy,LastUpdateOn) "
                    sql &= "VALUES ('" & HttpContext.Current.Session("UserName") & "','" & Now() & "',"
                    sql &= ParentRecID & "," & HttpContext.Current.Session("DistrictID") & ",'" & HttpContext.Current.Session("UserName") & "','" & Now() & "')"
                    sql &= ";SELECT NewKey = Scope_Identity()"  'return the new primary key
                    noteid = rs.ExecuteScalar(sql)
                End If
                'Update Project Master
                db.SaveForm(CallingPage.Form, "SELECT * FROM Notes WHERE NoteID = " & noteid)




            End Using

        End Sub

        Public Sub DeleteNote(ByVal nNoteID As Integer)
            db.ExecuteNonQuery("DELETE FROM Notes WHERE NoteID = " & nNoteID)
        End Sub
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
