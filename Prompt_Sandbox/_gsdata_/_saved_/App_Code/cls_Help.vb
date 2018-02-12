Imports System
Imports System.Web
Imports System.Web.UI.WebControls
Imports System.IO
Imports System.Data
Imports System.Data.SqlClient

Namespace Prompt

    '********************************************
    '*  Budget Class
    '*  
    '*  Purpose: Processes data for the help Object
    '*
    '*  Last Mod By:    Ford James
    '*  Last Mod On:    02/15/09
    '*
    '********************************************

    Public Class Prompt_Help
        Implements IDisposable

        'Properties
        Public CallingPage As Page
        Private db As PromptDataHelper

        Public Sub New()
            db = New PromptDataHelper
        End Sub

#Region "Subs and Functions"

        Public Sub GetHelpInfo()

            Dim sql As String = "SELECT * FROM Help WHERE PageID = '" & CallingPage.Session("PageID") & "' "
            db.FillReader(sql)
            While db.Reader.Read
                CallingPage.Title = db.Reader("PageTitle")
                DirectCast(CallingPage.FindControl("txtHelp"), Label).Text = db.Reader("HelpText")
            End While
            db.Reader.Close()

        End Sub

        Public Sub GetNewHelpEntry()

            'get a blank record and populate with initial info
            Dim dt As DataTable
            Dim row As DataRow
            dt = db.ExecuteDataTable("SELECT * FROM Help WHERE HelpID = 0")
            row = dt.NewRow()

            LoadEditForm(row)


        End Sub

        Public Sub GetExistingHelpEntry(ByVal nID As Integer)

            'get a existing contractor record and populate with  info
            Dim row As DataRow
            row = db.GetDataRow("SELECT * FROM Help WHERE HelpID = " & nID)

            LoadEditForm(row)

        End Sub


        Private Sub LoadEditForm(ByVal row As DataRow)

            'loads a parent form with data from passed row
            Dim form As Control = CallingPage.FindControl("Form1")  ' get ref to calling form
            Dim sql As String = ""

            ''Fill the dropdown controls -- we are using the title for both val and display here
            'sql = "SELECT LookupTitle As Val, LookupTitle as Lbl FROM Lookups WHERE DistrictID = " & httpcontext.current.Session("DistrictID") & " "
            'sql &= "AND ParentTable = 'Contractors' AND ParentField = 'ContractorType' ORDER BY LookupTitle"
            'db.FillDropDown(sql, form.FindControl("lstcType"), True, False, False)

            'load form
            db.FillForm(form, row)

        End Sub

        Public Sub SaveHelpEntry(ByVal nID As Integer)

            If nID = 0 Then  'this is new so add new 
                Dim Sql As String = "INSERT INTO Help "
                Sql &= "(PageTitle) "
                Sql &= "VALUES ('NewHelpPage')"
                Sql &= ";SELECT NewKey = Scope_Identity()"  'return the new primary key
                nID = db.ExecuteScalar(Sql)
            End If

            'Saves record
            db.SaveForm(CallingPage.Form, "SELECT * FROM Help WHERE HelpID = " & nID)

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
