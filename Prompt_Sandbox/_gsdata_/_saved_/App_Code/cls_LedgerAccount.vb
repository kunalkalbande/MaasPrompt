Imports System
Imports System.Web
Imports System.Web.UI.WebControls
Imports System.IO
Imports System.Data
Imports System.Data.SqlClient

Namespace Prompt

    '********************************************
    '*  Ledger Account Class
    '*  
    '*  Purpose: Processes data for the Ledger Account Object
    '*
    '*  Last Mod By:    Ford James
    '*  Last Mod On:    05/28/08
    '*
    '********************************************

    Public Class promptLedgerAccount
        Implements IDisposable

        'Properties
        Public CallingPage As Page
        Public LedgerAccountID As Integer = 0

        Private db As PromptDataHelper

        Public Sub New()
            db = New PromptDataHelper
        End Sub

#Region "Subs and Functions"

        Public Function GetLedgerAccounts(ByVal CollegeID As Integer) As DataTable
            'Get all the Ledger Accounts for this College
            Dim sql As String = "SELECT * FROM LedgerAccounts WHERE CollegeID = " & CollegeID & " ORDER BY LedgerName ASC"
            Return db.ExecuteDataTable(sql)

        End Function

        Public Function GetLedgerAccountName(ByVal AccountID As Integer) As String
            'Get all the Ledger Accounts for this College
            Dim sql As String = "SELECT LedgerName FROM LedgerAccounts WHERE LedgerAccountID = " & AccountID
            Return db.ExecuteScalar(sql)

        End Function

        Public Function GetLedgerAccountEntries(ByVal LedgerAccountID As Integer) As DataTable
            'Get all the Ledger Entries for this LedgerAccount
            Dim tbl As DataTable = db.ExecuteDataTable("SELECT * FROM qry_GetLedgerAccountEntries WHERE LedgerAccountID = " & LedgerAccountID & " ORDER BY EntryDate ")

            ''Add extra column
            'Dim col As New DataColumn
            'col.DataType = Type.GetType("System.Double")
            'col.ColumnName = "Credit"
            'tbl.Columns.Add(col)

            ''Add extra column
            'col = New DataColumn
            'col.DataType = Type.GetType("System.Double")
            'col.ColumnName = "Debit"
            'tbl.Columns.Add(col)

            'For Each row As DataRow In tbl.Rows
            '    If row("Amount") < 0 Then  'it is a debit
            '        row("Credit") = row("Amount") * -1    'don't show as neg
            '        row("Debit") = 0
            '    Else
            '        row("Debit") = row("Amount")
            '        row("Credit") = 0
            '    End If
            'Next

            Return tbl


        End Function

        Public Function GetProjectLedgerEntries(ByVal ProjectID As Integer) As DataTable
            'Get all the Ledger Entries for this Project
            Dim sql As String = "SELECT * FROM qry_GetLedgerAccountEntries WHERE ProjectID = " & ProjectID & " ORDER BY EntryDate "
            Return db.ExecuteDataTable(sql)

        End Function

        Public Sub GetNewLedgerAccount()

            'populates the parent form with new LedgerAccount record
            'get a blank record and populate with initial info
            Dim sql As String = "select * from LedgerAccounts where LedgerAccountid = 0"
            Dim dt As DataTable
            Dim row As DataRow
            dt = db.ExecuteDataTable(sql)
            row = dt.NewRow()
            LoadEditForm(row)

        End Sub

        Public Sub GetExistingLedgerAccount(ByVal nLedgerAccountID As Integer)

            'populates the parent form with LedgerAccount record
            LedgerAccountID = nLedgerAccountID   'set class property with passed id

            'get LedgerAccount record and populate with info
            Dim row As DataRow
            row = db.GetDataRow("SELECT * FROM LedgerAccounts WHERE LedgerAccountID = " & LedgerAccountID)

            'pass the row to routine to populate form
            LoadEditForm(row)


        End Sub

        Private Sub LoadEditForm(ByVal row As DataRow)

            'loads a parent form with data from passed row

            Dim form As Control = CallingPage.FindControl("Form1")  ' get ref to calling form

            Dim nDistrictID As Integer = CallingPage.Session("DistrictID")
            Dim sql As String = ""

            'Fill the dropdown controls on parent form

            'sql = "SELECT LookupValue As Val, LookupTitle as Lbl FROM dbo.Lookups WHERE ParentTable = 'LedgerAccounts' AND ParentField = 'Status' ORDER By LookupTitle"
            'db.FillDropDown(sql, form.FindControl("lstStatus"))

            sql = "SELECT LookupValue As Val, LookupTitle as Lbl FROM dbo.Lookups WHERE ParentTable = 'Projects' AND ParentField = 'BondSeriesNumber' "  'get from project list
            sql = sql & "AND DistrictID = " & CallingPage.Session("DistrictID") & " ORDER By LookupTitle"
            db.FillDropDown(sql, form.FindControl("lstBondSeriesNumber"), False, False, False)

            sql = "SELECT 'Interest' As Val, 'Interest' as Lbl Union Select 'Credit' as Val, 'Credit' as Lbl"
            db.FillDropDown(sql, form.FindControl("lstAccountType"), False, False, False)

            db.FillForm(form, row)


        End Sub

        Public Sub SaveLedgerAccount(ByVal CollegeID As Integer, ByVal nLedgerAccountID As Integer)

            LedgerAccountID = nLedgerAccountID   'set class property with passed id

            'NOTE: Defaults to Interest type Ledger Account for now

            Dim sql As String = ""
            'Check if this is a new LedgerAccount
            If LedgerAccountID = 0 Then
                'Add Master LedgerAccount Record
                sql = "INSERT INTO LedgerAccounts "
                sql = sql & "(ClientID,DistrictID,CollegeID,AccountType) "
                sql = sql & "VALUES  (" & CallingPage.Session("ClientID") & "," & CallingPage.Session("DistrictID") & "," & CollegeID & ",'Interest') "
                sql = sql & ";SELECT NewKey = Scope_Identity()"  'return the new primary key

                LedgerAccountID = db.ExecuteScalar(sql)


                ''Create the Attachments Dir
                'Dim att As New promptAttachment
                'With att
                '    .DistrictID = CallingPage.Session("DistrictID")
                '    .CollegeID = CollegeID
                '    .LedgerAccountID = LedgerAccountID
                '    .CreateAttachmentDir()
                'End With

            End If

            'Update the LedgerAccountID label on the form as it will be included in save form
            DirectCast(CallingPage.Form.FindControl("lblLedgerAccountID"), Label).Text = LedgerAccountID

            'Update LedgerAccount Master
            db.SaveForm(CallingPage.Form, "SELECT * FROM LedgerAccounts WHERE LedgerAccountID = " & LedgerAccountID)

        End Sub



        Public Function DeleteLedgerAccount(ByVal nLedgerAccountID As Integer) As String

            Dim sql As String = "SELECT COUNT(LedgerEntryID) FROM LedgerAccountEntries WHERE LedgerAccountID = " & nLedgerAccountID
            Dim cnt As Integer = db.ExecuteScalar(sql)
            If cnt > 0 Then
                Return "Please delete all entries for this account to remove ledger account."
            Else
                sql = "DELETE FROM LedgerAccounts WHERE LedgerAccountID = " & nLedgerAccountID
                db.ExecuteNonQuery(sql)
                Return ""
            End If
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
