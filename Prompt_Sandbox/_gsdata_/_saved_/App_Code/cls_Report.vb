Imports System
Imports System.Web
Imports System.Web.UI.WebControls
Imports System.IO
Imports System.Data
Imports System.Data.SqlClient

Namespace Prompt

    '********************************************
    '*  Report Class
    '*  
    '*  Purpose: Processes data for the report object
    '*
    '*  Last Mod By:    Ford James
    '*  Last Mod On:    02/02/09
    '*
    '********************************************

    Public Class promptReport
        Implements IDisposable

        'Properties
        Public CallingPage As Page
        Private db As PromptDataHelper

        Public Sub New()
            db = New PromptDataHelper
        End Sub

#Region "Subs and Functions"

    

        Public Sub GetNewReport()

            'get a blank record and populate with initial info
            Dim dt As DataTable
            Dim row As DataRow
            dt = db.ExecuteDataTable("SELECT * FROM Reports WHERE ReportID = 0")
            row = dt.NewRow()

            LoadEditForm(row)


        End Sub

        Public Sub GetExistingReport(ByVal nReportID As Integer)

            'get a existing record and populate with  info
            Dim row As DataRow
            row = db.GetDataRow("SELECT * FROM Reports WHERE ReportID = " & nReportID)

            LoadEditForm(row)

        End Sub


        Private Sub LoadEditForm(ByVal row As DataRow)

            'loads a parent form with data from passed row
            Dim form As Control = CallingPage.FindControl("Form1")  ' get ref to calling form
            Dim sql As String = ""

            'Fill the dropdown controls
            sql = "SELECT DISTINCT ReportType AS Val FROM Reports  "     'NOTE: only select val - lbl will be set same
            db.FillNewRADComboBox(sql, form.FindControl("lstReportType"), True, False, False, True)


            'sql = "SELECT LookupValue As Val, LookupTitle as Lbl FROM Lookups WHERE "
            'sql &= "ParentTable = 'Reports' AND ParentField = 'SecurityLevel' ORDER BY LookupTitle"
            'db.FillDropDown(sql, form.FindControl("lstSecurityLevel"), False, False, False)

            'sql = "SELECT LookupValue As Val, LookupTitle as Lbl FROM Lookups WHERE "
            'sql &= "ParentTable = 'Reports' AND ParentField = 'ViewLevel' ORDER BY LookupTitle"
            'db.FillDropDown(sql, form.FindControl("lstViewLevel"), True, False, False)


            'load form

            db.FillForm(form, row)

        End Sub

        Public Sub SaveReport(ByVal nReportID As Integer)

            If nReportID = 0 Then  'this is new contractor so add new 
                Dim Sql As String = "INSERT INTO Reports "
                Sql &= "(LastUpdateBy) "
                Sql &= "VALUES ('AddNew')"
                Sql &= ";SELECT NewKey = Scope_Identity()"  'return the new primary key
                nReportID = db.ExecuteScalar(Sql)
            End If

            'Saves record
            db.SaveForm(CallingPage.Form, "SELECT * FROM Reports WHERE ReportID = " & nReportID)

            'Save the lists 
            Dim lstUsers As ListBox = CallingPage.Form.FindControl("lstAssignedUsers")
            Dim lstDistricts As ListBox = CallingPage.Form.FindControl("lstAssignedDistricts")
            Dim sUserlist As String = ProcLib.BuildSelectedString(lstUsers)
            Dim sDistrictList As String = ProcLib.BuildSelectedString(lstDistricts)
            db.ExecuteNonQuery("UPDATE Reports SET DistrictViewList = '" & sDistrictList & "',UserViewList = '" & sUserlist & "' WHERE ReportID = " & nReportID)

        End Sub

        Public Function GetReportsList() As DataTable
            Dim tbl As DataTable
            Dim bShowReport As Boolean = True
            Dim sql As String = "SELECT ReportID, ReportTitle, ReportNumber, ReportType, ViewLevel, DistrictViewList, "
            sql &= "UserViewList, Description FROM Reports WHERE Publish = 1  ORDER BY ReportType, ReportTitle"
            tbl = db.ExecuteDataTable(sql)

            For Each row As DataRow In tbl.Rows
                'Check for current user/District access
                Dim sUserViewList As String = ProcLib.CheckNullDBField(row("UserViewList"))
                Dim sDistrictViewList As String = ProcLib.CheckNullDBField(row("DistrictViewList"))

                bShowReport = True

                'Bypass for tech support
                If HttpContext.Current.Session("UserRole") <> "TechSupport" Then
                    If InStr(sUserViewList, ";0;") = 0 Then      'only some users can see report
                        bShowReport = False
                        If InStr(sUserViewList, ";" & HttpContext.Current.Session("UserID") & ";") > 0 Then   'user is good
                            bShowReport = True
                        End If
                    End If

                    If bShowReport = True Then    'user is good so check district
                        If InStr(sDistrictViewList, ";0;") = 0 Then      'only some districts can see report
                            bShowReport = False
                            If InStr(sDistrictViewList, ";" & HttpContext.Current.Session("DistrictID") & ";") > 0 Then   'district is good
                                bShowReport = True
                            End If
                        End If
                    End If
                End If

                If bShowReport = False Then
                    row.Delete()
                End If
            Next

            Return tbl

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

