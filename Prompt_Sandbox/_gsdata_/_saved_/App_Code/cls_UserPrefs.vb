Imports System
Imports System.Web
Imports System.Web.UI.WebControls
Imports System.IO
Imports System.Data
Imports System.Data.SqlClient
Imports System.Net.Mail
Imports Telerik.Web.UI
Imports System.Collections.Generic
Imports System.Web.Script.Serialization


Namespace Prompt

    '********************************************
    '*  UserPrefs Class
    '*  
    '*  Purpose: Processes data for the UserPrefs objects
    '*
    '*  Last Mod By:    Ford James
    '*  Last Mod On:    3/25/10
    '*
    '********************************************

    Public Class promptUserPrefs
        Implements IDisposable

        'Properties
        Public CallingPage As Page
        Private db As PromptDataHelper

        Public Sub New()
            db = New PromptDataHelper

        End Sub



#Region "User Prefs"

        Public Sub RemoveAllUserSavedSettings()

            Dim sql As String =  "DELETE FROM UsersPrefs WHERE UserID=" & HttpContext.Current.Session("UserID")
            db.ExecuteNonQuery(sql)

        End Sub

        Public Function GetUserSetting(ByVal SettingName As String, ByVal KeyField As String, ByVal ID As Integer) As String
            'gets specified user setting
            Dim sql As String = ""
            sql = "SELECT Setting FROM UsersPrefs WHERE " & KeyField & "=" & ID & " AND SettingName='" & SettingName & "' AND UserID=" & HttpContext.Current.Session("UserID")
            Return db.ExecuteScalar(sql)

        End Function



        Public Sub SetUserViewedLatestAnnouncement(ByVal dTime As String)

            Dim sql As String = "DELETE FROM UsersPrefs WHERE SettingName='LastAnnouncementViewed' AND UserID=" & HttpContext.Current.Session("UserID")
            db.ExecuteNonQuery(sql)

            sql = "INSERT INTO UsersPrefs (UserID,SettingName,SettingValue,LastUpdateBy,LastUpdateOn) "
            sql &= "VALUES(" & HttpContext.Current.Session("UserID") & ",'LastAnnouncementViewed','" & dTime & "','" & HttpContext.Current.Session("UserName") & "', "
            sql &= "'" & Now() & "')"
            db.ExecuteNonQuery(sql)


        End Sub


        Public Sub SaveDockState(ByVal dockstate As String, ByVal SettingName As String, ByVal KeyField As String, ByVal ID As Integer)

            Dim sql As String = ""

            sql = "DELETE FROM UsersPrefs WHERE " & KeyField & "=" & ID & " AND SettingName='" & SettingName & "' AND UserID=" & HttpContext.Current.Session("UserID")
            db.ExecuteNonQuery(sql) 'delete existing setting

            sql = "INSERT INTO UsersPrefs (UserID," & KeyField & ",SettingName,SettingValue,LastUpdateBy,LastUpdateOn) "
            sql &= "VALUES(" & HttpContext.Current.Session("UserID") & "," & ID & ",'" & SettingName & "','" & dockstate & "','" & HttpContext.Current.Session("UserName") & "', "
            sql &= "'" & Now() & "')"
            db.ExecuteNonQuery(sql)

        End Sub

        Public Function GetDockState(ByVal SettingName As String, ByVal KeyField As String, ByVal ID As Integer) As String

            Dim sql As String = ""

            sql = "SELECT SettingValue FROM UsersPrefs WHERE " & KeyField & "=" & ID & " AND SettingName='" & SettingName & "' AND UserID=" & HttpContext.Current.Session("UserID")
            Return db.ExecuteScalar(sql)

        End Function

        Public Sub SaveGridColumnVisibility(ByVal SettingName As String, ByVal ColumnName As String, ByVal SettingValue As String, ByVal KeyField As String, ByVal ID As Integer)

            Dim sql As String = ""

            sql = "DELETE FROM UsersPrefs WHERE " & KeyField & "=" & ID & " AND SettingName='" & SettingName & "' AND SettingParm1 = '" & ColumnName & "' AND UserID=" & HttpContext.Current.Session("UserID")
            db.ExecuteNonQuery(sql) 'delete existing setting

            sql = "INSERT INTO UsersPrefs (UserID," & KeyField & ",SettingName,SettingValue,SettingParm1,LastUpdateBy,LastUpdateOn) "
            sql &= "VALUES(" & HttpContext.Current.Session("UserID") & "," & ID & ",'" & SettingName & "','" & SettingValue & "','" & ColumnName & "','" & HttpContext.Current.Session("UserName") & "', "
            sql &= "'" & Now() & "')"
            db.ExecuteNonQuery(sql)


        End Sub

        Public Sub LoadGridColumnVisibility(ByRef gridInstance As RadGrid, ByVal SettingName As String, ByVal KeyField As String, ByVal ID As Integer)

            Dim sql As String = ""

            sql = "SELECT * FROM UsersPrefs WHERE " & KeyField & "=" & ID & " AND SettingName='" & SettingName & "' AND UserID=" & HttpContext.Current.Session("UserID")
            Dim tbl As DataTable = db.ExecuteDataTable(sql)
            For Each row As DataRow In tbl.Rows
                Try
                    Dim setting As String = row("SettingValue")
                    Dim col As String = ProcLib.CheckNullDBField(row("SettingParm1"))
                    If Trim(col) <> "" Then
                        If setting = "On" Then
                            gridInstance.Columns.FindByUniqueName(col).Visible = True
                        End If
                        If setting = "Off" Then
                            gridInstance.Columns.FindByUniqueName(col).Visible = False
                        End If
                    End If
                Catch ex As Exception
                    'do nothing
                End Try

            Next

        End Sub


        Public Sub SaveGridSettings(ByRef gridInstance As RadGrid, ByVal SettingName As String, ByVal KeyField As String, ByVal ID As Integer)

            Dim sql As String = ""

            'this method should be called on Render
            Dim gridSettings() As Object = New Object((4) - 1) {}
            'Save groupBy
            Dim groupByExpressions As GridGroupByExpressionCollection = gridInstance.MasterTableView.GroupByExpressions
            Dim groupExpressions() As Object = New Object((groupByExpressions.Count) - 1) {}
            Dim count As Integer = 0
            For Each expression As GridGroupByExpression In groupByExpressions
                groupExpressions(count) = CType(expression, IStateManager).SaveViewState
                count = (count + 1)
            Next
            gridSettings(0) = groupExpressions
            'Save sort expressions
            gridSettings(1) = CType(gridInstance.MasterTableView.SortExpressions, IStateManager).SaveViewState
            'Save columns order
            Dim columnsLength As Integer = (gridInstance.MasterTableView.Columns.Count + gridInstance.MasterTableView.AutoGeneratedColumns.Length)
            Dim columnOrder() As Pair = New Pair(columnsLength - 1) {}
            Dim allColumns As ArrayList = New ArrayList(columnsLength)
            allColumns.AddRange(gridInstance.MasterTableView.Columns)
            allColumns.AddRange(gridInstance.MasterTableView.AutoGeneratedColumns)
            Dim i As Integer = 0
            For Each column As GridColumn In allColumns
                Dim p As Pair = New Pair
                p.First = column.OrderIndex
                p.Second = column.HeaderStyle.Width
                columnOrder(i) = p
                i = (i + 1)
            Next
            gridSettings(2) = columnOrder
            'Save filter expression
            gridSettings(3) = CType(gridInstance.MasterTableView.FilterExpression, Object)
            'save the visible/displayed columns settings and current filter value/current filter function
            Dim visibleColumns As ArrayList = New ArrayList(columnsLength)
            Dim displayedColumns As ArrayList = New ArrayList(columnsLength)
            i = 0

            Dim formatter As LosFormatter = New LosFormatter
            Dim writer As StringWriter = New StringWriter
            formatter.Serialize(writer, gridSettings)


            sql = "DELETE FROM UsersPrefs WHERE " & KeyField & "=" & ID & " AND SettingName='" & SettingName & "' AND UserID=" & HttpContext.Current.Session("UserID")
            db.ExecuteNonQuery(sql) 'delete existing setting

            sql = "INSERT INTO UsersPrefs (UserID," & KeyField & ",SettingName,SettingValue,LastUpdateBy,LastUpdateOn) "
            sql &= "VALUES(" & HttpContext.Current.Session("UserID") & "," & ID & ",'" & SettingName & "','" & writer.ToString & "','" & HttpContext.Current.Session("UserName") & "', "
            sql &= "'" & Now() & "')"
            db.ExecuteNonQuery(sql)

        End Sub

        Public Sub SaveGridGroupCollapseState(ByVal Setting As String, ByVal SettingName As String, ByVal KeyField As String, ByVal ID As Integer)

            Dim sql As String = ""

            sql = "DELETE FROM UsersPrefs WHERE " & KeyField & "=" & ID & " AND SettingName='" & SettingName & "' AND UserID=" & HttpContext.Current.Session("UserID")
            db.ExecuteNonQuery(sql) 'delete existing setting

            sql = "INSERT INTO UsersPrefs (UserID," & KeyField & ",SettingName,SettingValue,LastUpdateBy,LastUpdateOn) "
            sql &= "VALUES(" & HttpContext.Current.Session("UserID") & "," & ID & ",'" & SettingName & "','" & Setting & "','" & HttpContext.Current.Session("UserName") & "', "
            sql &= "'" & Now() & "')"
            db.ExecuteNonQuery(sql)

        End Sub

        Public Function LoadGridGroupCollapseState(ByVal SettingName As String, ByVal KeyField As String, ByVal ID As Integer) As String

            Dim sql As String = ""
            Dim result As String = ""
            sql = "SELECT SettingValue FROM UsersPrefs WHERE " & KeyField & "=" & ID & " AND SettingName='" & SettingName & "' AND UserID=" & HttpContext.Current.Session("UserID")


            result = Trim(ProcLib.CheckNullDBField(db.ExecuteScalar(sql)))

            Return result

        End Function



        Public Sub RemoveUserSavedSettings(ByVal SettingName As String, ByVal KeyField As String, ByVal ID As Integer)

            Dim sql As String = ""


            sql = "DELETE FROM UsersPrefs WHERE " & KeyField & "=" & ID & " AND SettingName='" & SettingName & "' AND UserID=" & HttpContext.Current.Session("UserID")
            db.ExecuteNonQuery(sql) 'delete existing setting

        End Sub

        Public Sub LoadGridSettings(ByRef gridInstance As RadGrid, ByVal SettingName As String, ByVal KeyField As String, ByVal ID As Integer)

            Dim sql As String = ""
            Dim settings As String = ""

            sql = "SELECT SettingValue FROM UsersPrefs WHERE " & KeyField & "=" & ID & " AND SettingName='" & SettingName & "' AND UserID=" & HttpContext.Current.Session("UserID")
            settings = ProcLib.CheckNullDBField(db.ExecuteScalar(sql))

            If settings <> "" Then
                Try
                    'this method should be called on PageInit
                    Dim formatter As LosFormatter = New LosFormatter
                    Dim reader As StringReader = New StringReader(settings)
                    Dim gridSettings() As Object = CType(formatter.Deserialize(reader), Object())
                    'Load groupBy
                    Dim groupByExpressions As GridGroupByExpressionCollection = gridInstance.MasterTableView.GroupByExpressions
                    groupByExpressions.Clear()
                    Dim groupExpressionsState() As Object = CType(gridSettings(0), Object())
                    Dim count As Integer = 0
                    For Each obj As Object In groupExpressionsState
                        Dim expression As GridGroupByExpression = New GridGroupByExpression
                        CType(expression, IStateManager).LoadViewState(obj)
                        groupByExpressions.Add(expression)
                        count = (count + 1)
                    Next
                    'Load sort expressions
                    gridInstance.MasterTableView.SortExpressions.Clear()
                    CType(gridInstance.MasterTableView.SortExpressions, IStateManager).LoadViewState(gridSettings(1))
                    'Load columns order
                    Dim columnsLength As Integer = (gridInstance.MasterTableView.Columns.Count + gridInstance.MasterTableView.AutoGeneratedColumns.Length)
                    Dim columnOrder() As Pair = CType(gridSettings(2), Pair())
                    Dim allColumns As ArrayList = New ArrayList(columnsLength)
                    If (columnsLength = columnOrder.Length) Then
                        allColumns.AddRange(gridInstance.MasterTableView.Columns)
                        allColumns.AddRange(gridInstance.MasterTableView.AutoGeneratedColumns)
                        Dim counter As Integer = 0
                        For Each column As GridColumn In allColumns
                            column.OrderIndex = CType(columnOrder(counter).First, Integer)
                            column.HeaderStyle.Width = CType(columnOrder(counter).Second, Unit)
                            counter = (counter + 1)
                        Next
                    End If
                    'Load filter expression
                    'gridInstance.MasterTableView.FilterExpression = CType(gridSettings(3), String)
                    'Dim StatusLabel As Label = CType(gridInstance.NamingContainer.FindControl("StatusLabel"), Label)
                    'StatusLabel.Text = gridSettings.Length.ToString()
                    ''Load visible/displayed columns and their current filter values/current filter functions
                    'If (gridSettings.Length > 4) Then
                    '    Dim visibleCols As ArrayList = DirectCast(gridSettings(4), ArrayList)
                    '    Dim displayedColumns As ArrayList = DirectCast(gridSettings(5), ArrayList)
                    '    Dim columnFilter As Pair() = DirectCast(gridSettings(6), Pair())
                    '    Dim i As Integer = 0

                    '    For Each column As GridColumn In allColumns
                    '        column.CurrentFilterFunction = DirectCast(columnFilter(i).First, GridKnownFunction)
                    '        column.CurrentFilterValue = DirectCast(columnFilter(i).Second, String)
                    '        column.Visible = DirectCast(visibleCols(i), Boolean)
                    '        column.Display = DirectCast(displayedColumns(i), Boolean)
                    '        System.Math.Max(System.Threading.Interlocked.Increment(i), i - 1)
                    '    Next
                    'End If
                    gridInstance.Rebind()

                Catch ex As Exception
                    'do nothing - default config will prevail

                End Try
              
            End If


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

