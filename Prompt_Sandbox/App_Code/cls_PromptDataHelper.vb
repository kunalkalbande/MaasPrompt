Imports System
Imports System.Configuration
Imports System.Data
Imports System.Data.SqlClient
Imports System.Web
Imports System.Web.UI.WebControls
Imports System.Xml

'Imports Telerik.WebControls

Namespace Prompt

    ''' <summary>
    ''' Represents a data access layer to the Prompt database.
    ''' </summary>
    Public Class PromptDataHelper
        Implements IDisposable

        Public Reader As SqlDataReader
        Public DataTable As DataTable
        Public CallingPage As Page  'to allow passing of session and request variables to procedures
        Public CurrentUserName As String = ""
        Public CurrentUserID As Integer = 0
        Public ClientID As Integer = 0


        'data access variables
        Private _da As SqlDataAdapter
        Private _ds As DataSet
        Private _sqlcmd As SqlCommandBuilder

        Private _connection As SqlConnection
        Private _disposeConnection As Boolean


#Region "Constructor"

        Public Sub New()
            Try    'gets connection from the pool
                _connection = New SqlConnection(ProcLib.GetDataConnectionString())
                _connection.Open()
                _disposeConnection = True

                Try
                    ClientID = System.Web.HttpContext.Current.Session("ClientID")
                    CurrentUserID = System.Web.HttpContext.Current.Session("UserID")
                    CurrentUserName = System.Web.HttpContext.Current.Session("UserName")
                Catch ex As Exception
                    MsgBox(ex.Message)
                End Try

            Catch ex As Exception   'if no pooled connections, then get non pooled connection
                Dim t As String
                t = ex.Message
                If _connection.State <> ConnectionState.Closed Then   'try getting a non-pooled connection string
                    _connection = New SqlConnection(ProcLib.GetNonPooledDataConnectionString())
                    _connection.Open()
                    _disposeConnection = True

                    Try
                        ClientID = System.Web.HttpContext.Current.Session("ClientID")
                        CurrentUserID = System.Web.HttpContext.Current.Session("UserID")
                        CurrentUserName = System.Web.HttpContext.Current.Session("UserName")
                    Catch

                    End Try
                End If


            End Try

        End Sub


#End Region

#Region "UDF Routines"

        Public Function GetFilteredUDFDataAsRows(ByVal ParentTable As String, ByVal ParentTableRecordKeyField As String, ByVal ParentTableFilterIDField As String, ByVal ParentTableFilterIDValue As Integer) As DataTable
            'Returns a simple two column datatable with UDF data rows containing two fields: DisplayLabel and DisplayValue
            'Usage:
            '   ParentTable:                Owner of UDF fields 
            '   ParentTableRecordKeyField:  The key field that ties each UDF data record to it's Parent Record
            '   ParentTableFilterIDField:   The field in the parent table you wish to filter results on
            '   ParentTableFilterIDValue:   The value of the FilterID -- SHOULD BE UNIQUE KEY
            '   
            '   ex: Return row for each item in AppriseProjectUDFData with an ProjectID = 76"

            Dim sql As String = "SELECT UDF_Data.UDFLabel AS DisplayLabel, UDF_Data.UDFValue AS DisplayValue "
            sql &= "FROM UDF_Data INNER JOIN UDF_Templates ON UDF_Data.UDFTemplateKey = UDF_Templates.UDFTemplateKey "
            sql &= "INNER JOIN " & ParentTable & " ON UDF_Data.ParentTableRecordKey = " & ParentTable & "." & ParentTableRecordKeyField & " "
            sql &= "WHERE UDF_Templates.RelatedTable = '" & ParentTable & "' AND " & ParentTable & "." & ParentTableFilterIDField & " = " & ParentTableFilterIDValue & " "
            sql &= "ORDER BY UDF_Templates.DisplayOrder "

            Return ExecuteDataTable(sql)


        End Function

        Public Function GetFilteredParentAndUDFDataAsSingleRow(ByVal ParentTable As String, ByVal ParentTableRecordKeyField As String, ByVal ParentTableFilterIDField As String, ByVal ParentTableFilterIDValue As Integer) As DataTable
            'Returns a datatable containing a single record created by combining the ParentTable Record with UDF Data entries combined into a single row. 
            'Usage:
            '   ParentTable:                Owner of UDF fields 
            '   ParentTableRecordKeyField:  The key field that ties each UDF data record to it's Parent Record
            '   ParentTableFilterIDField:   The field in the parent table you wish to filter results on
            '   ParentTableFilterIDValue:   The value of the FilterID -- SHOULD BE UNIQUE KEY
            '   NOTE: All UDF columns will have udf_ prefix
            '   
            '   ex: Return all AppriseProjectData and AppriseProjectUDFData in a single row for passed ProjectID"

            Dim sql As String = "SELECT * FROM " & ParentTable & " WHERE " & ParentTableFilterIDField & " = " & ParentTableFilterIDValue
            Dim tblParent As DataTable = ExecuteDataTable(sql)

            sql = "SELECT UDF_Data.UDFDataField, UDF_Data.UDFValue "
            sql &= "FROM UDF_Data INNER JOIN UDF_Templates ON UDF_Data.UDFTemplateKey = UDF_Templates.UDFTemplateKey "
            sql &= "INNER JOIN " & ParentTable & " ON UDF_Data.ParentTableRecordKey = " & ParentTable & "." & ParentTableRecordKeyField & " "
            sql &= "WHERE UDF_Templates.RelatedTable = '" & ParentTable & "' AND " & ParentTable & "." & ParentTableFilterIDField & " = " & ParentTableFilterIDValue
            Dim tblUDF As DataTable = ExecuteDataTable(sql)

            'Now add the columns to the parent table for each UDF record
            For Each row As DataRow In tblUDF.Rows
                Dim col As New DataColumn
                col.DataType = Type.GetType("System.String")
                col.ColumnName = "udf_" & row("UDFDataField")
                tblParent.Columns.Add(col)
            Next

            'Now update each of the new fields in the row with actual data
            Dim parentrow As DataRow = tblParent.Rows(0)
            For Each row As DataRow In tblUDF.Rows
                parentrow("udf_" & row("UDFDataField")) = row("UDFValue")
            Next

            Return tblParent      'return the whole table with a single row here so we have access to field attributes as well as row data

        End Function

        Public Sub WriteUDFDataFromForm(ByVal form As Control, ByVal ParentTable As String, ByVal ParentTableRecordKey As Integer)
            'Write any UDF data on a form to UDF Table for passed key. 
            'Usage:
            '   frm:                        passed edit form
            '   ParentTable:                Owner of UDF fields 
            '   ParentTableRecordKey:       The key field value that ties each UDF data record to it's Parent Record
            '   NOTE: All UDF columns will have udf_ prefix. Also, this routine will search the form recusively to make sure that
            '   controls that themselves contain controls are found - this is particularly important when using dyanmically created controls like UDFS
            '   
            '   ex: write all AppriseProjectUDFData from edit form for passed ProjectID"

            BuildDataAdaptor("SELECT * FROM UDF_Data WHERE ParentTable = '" & ParentTable & "' AND ParentTableRecordKey = " & ParentTableRecordKey)
            Dim dt As DataTable = _ds.Tables("tbl")

            WriteUDFDataToSaveTableRecursively(form, dt)

            UpdateDBFromDataAdaptor()

        End Sub

        Public Sub BuildUDFEditTable(ByVal formtable As Table, ByVal DistrictID As Integer, ByVal RelatedTable As String)

            'Adds the UDF fields and labels to the passed table 
            Dim sql As String = "SELECT * FROM UDF_Templates WHERE DistrictID = " & DistrictID & " AND RelatedTable = '" & RelatedTable & "' ORDER BY DisplayOrder"
            Dim tblTemplate As DataTable = ExecuteDataTable(sql)
            Dim i As Integer = 0
            For Each row As DataRow In tblTemplate.Rows

                i += 1

                Dim tr As TableRow = New TableRow()

                'Create the label
                Dim tclbl As TableCell = New TableCell()
                tclbl.CssClass = "smalltext"
                tclbl.VerticalAlign = VerticalAlign.Top
                tclbl.ID = "lblcell_" & i


                Dim label As Label = New Label()
                label.Text = row("DisplayLabel") & ":"
                label.ID = "label_" & row("DataField")


                ' Add the control to the TableCell
                tclbl.Controls.Add(label)
                ' Add the TableCell to the TableRow
                tr.Cells.Add(tclbl)

                'Create the edit box
                Dim tctxt As New TableCell()
                tctxt.CssClass = "EditDataDisplay"
                tclbl.ID = "txtudfcell_" & i

                Dim txtBox As TextBox = New TextBox()
                txtBox.ID = "txtudf_" & row("DataField")

                txtBox.Width = Unit.Pixel(row("EditControlWidth"))
                If row("IsMultiLine") = 1 Then
                    txtBox.TextMode = TextBoxMode.MultiLine
                    txtBox.Height = 80
                End If


                ' Add the control to the TableCell
                tctxt.Controls.Add(txtBox)
                ' Add the TableCell to the TableRow
                tr.Cells.Add(tctxt)

                formtable.Rows.Add(tr)

            Next

        End Sub

        Public Sub ValidateUDFDataWithTemplate(ByVal RelatedTable As String, ByVal ParentKey As Integer)

            'Check that this project has all the correct UDF entries in the UDF Data table. If not then create them.
            Dim sql As String = "SELECT * FROM UDF_Templates WHERE RelatedTable = 'Projects' AND "
            sql &= "DistrictID = " & HttpContext.Current.Session("DistrictID")

            Dim tblUDFTemplate As DataTable = ExecuteDataTable(sql)
            Dim tblUDFData As DataTable = ExecuteDataTable("SELECT * FROM UDF_DATA WHERE ParentTable = '" & RelatedTable & "' AND ParentTableRecordKey = " & ParentKey)
            For Each tmpRow As DataRow In tblUDFTemplate.Rows
                Dim nUDFTemplateKey As Integer = tmpRow("UDFTemplateKey")
                Dim bFound As Boolean = False
                For Each dataRow As DataRow In tblUDFData.Rows
                    If dataRow("UDFTemplateKey") = nUDFTemplateKey Then
                        bFound = True
                        Exit For
                    End If
                Next
                If Not bFound Then       'add a blank record to the database for this UDF field

                    Dim sUDFDataField As String = tmpRow("DataField")
                    Dim sUDFDisplayLabel As String = tmpRow("DisplayLabel")
                    Dim nDistrictID As Integer = tmpRow("DistrictID")
                    Dim sUDFValue As String = ""
                    Dim sParentTable As String = tmpRow("RelatedTable")
                    Dim sParentTableRecordKey As Integer = ParentKey

                    sql = "INSERT INTO UDF_Data ("
                    sql &= "UDFLabel" & ","
                    sql &= "UDFDataField" & ","
                    sql &= "UDFValue" & ","
                    sql &= "DistrictID" & ","
                    sql &= "UDFTemplateKey" & ","
                    sql &= "ParentTableRecordKey" & ","
                    sql &= "ParentTable" & ","

                    sql &= "LastUpdateOn" & ","
                    sql &= "LastUpdateBy" & ") "


                    sql &= "VALUES("
                    sql &= "'" & sUDFDisplayLabel & "',"
                    sql &= "'" & sUDFDataField & "',"
                    sql &= "'" & sUDFValue & "',"

                    sql &= "" & nDistrictID & ","
                    sql &= "" & tmpRow("UDFTemplateKey") & ","

                    sql &= "" & sParentTableRecordKey & ","
                    sql &= "'" & tmpRow("RelatedTable") & "',"

                    sql &= "'" & Now() & "',"
                    sql &= "'" & HttpContext.Current.Session("UserName") & "'"

                    sql &= ")"

                    ExecuteNonQuery(sql)
                End If
            Next


        End Sub

        Private Sub WriteUDFDataToSaveTableRecursively(ByVal ParentControl As Control, ByVal dt As DataTable)
            'Look in the passed control for match and write to table for save 

            'requires that the field names on the form match the field names in dataset (Minus the prefix)
            Dim colname As String = ""
            Dim colValue As String = ""
            Dim ctrlname As String = ""

            'this flag is needed because forms only return fields that have values, so
            'if boxes are unchecked they will not get passed, but still need to update the DB
            Dim bFound As Boolean = False

            For Each row As DataRow In dt.Rows

                colname = row("UDFDataField")

                bFound = False

                For Each ctrl As Control In ParentControl.Controls                    'iterate each of the returned forms controls

                    If Not IsNothing(ctrl.ID) Then
                        bFound = True
                    End If

                    ctrlname = Mid(ctrl.ID, 8) 'strip off prefix for field name including udf_ tag

                    If colname = ctrlname Then   'then we have a column name that matches a control name
                        bFound = True

                        If TypeOf ctrl Is TextBox Then
                            colValue = Trim(CType(ctrl, TextBox).Text)
                            row("UDFValue") = colValue
                        End If

                        If TypeOf ctrl Is Telerik.Web.UI.RadDatePicker Then
                            colValue = CType(ctrl, Telerik.Web.UI.RadDatePicker).DbSelectedDate
                            row("UDFValue") = ProcLib.CheckDateField(colValue)    'save dbnull if not date
                        End If

                        If TypeOf ctrl Is Telerik.Web.UI.RadNumericTextBox Then
                            colValue = CType(ctrl, Telerik.Web.UI.RadNumericTextBox).Text
                            If colValue = "" Then colValue = 0
                            row("UDFValue") = colValue

                        End If

                        If TypeOf ctrl Is DropDownList Then
                            colValue = CType(ctrl, DropDownList).SelectedValue
                            row("UDFValue") = colValue
                        End If

                        If TypeOf ctrl Is Telerik.Web.UI.RadComboBox Then    'for new control
                            colValue = CType(ctrl, Telerik.Web.UI.RadComboBox).SelectedValue
                            Dim colText As String = CType(ctrl, Telerik.Web.UI.RadComboBox).Text
                            If colValue <> "" Then
                                row("UDFValue") = colValue
                            Else
                                If colText <> "" Then
                                    row("UDFValue") = colText
                                End If
                            End If

                        End If

                        If TypeOf ctrl Is Telerik.Web.UI.RadEditor Then                 'For new editor
                            colValue = CType(ctrl, Telerik.Web.UI.RadEditor).Content.ToString
                            row("UDFValue") = colValue
                        End If

                        If TypeOf ctrl Is CheckBox Then
                            colValue = CType(ctrl, CheckBox).Checked
                            If colValue = True Then
                                colValue = 1
                            Else
                                colValue = 0
                            End If
                            row("UDFValue") = colValue
                        End If
                    End If

                    If ctrl.Controls.Count > 0 Then   'Recursive
                        WriteUDFDataToSaveTableRecursively(ctrl, dt)
                    End If

                Next

                'write the timestamp
                row("LastUpdateBy") = CurrentUserName
                row("LastUpdateOn") = Now()
            Next

        End Sub

#End Region

#Region "FormRoutines"

        Public Sub FillDropDown(ByVal sql As String, ByRef lst As DropDownList, Optional ByVal AddNoneEntry As Boolean = False, Optional ByVal IsNumeric As Boolean = True, Optional ByVal ConcatDescription As Boolean = False)
            'fills a passed DropDown Control based on SQLText 
            'will add a default entry if specified
            'will make default entry (value) number or string if specified
            'Will concat the value + "-" + Description if ConcatDescription is true

            If AddNoneEntry Then   'check for empty lst and add default record
                Dim item As New ListItem
                If IsNumeric Then
                    item.Value = 0
                Else
                    item.Value = "none"
                End If
                item.Text = "-- none --"
                lst.Items.Add(item)
            End If

            Dim Reader As SqlDataReader
            Using command As SqlCommand = CreateSqlStringCommand(sql)
                Reader = ExecuteReader("FillDropDown", command)
                If Reader.HasRows Then
                    While Reader.Read()
                        Dim item As New ListItem
                        item.Value = ProcLib.CheckNullDBField(Reader("Val"))
                        If ConcatDescription Then
                            item.Text = item.Value & "-" & Reader("Lbl")
                        Else
                            item.Text = ProcLib.CheckNullDBField(Reader("Lbl"))
                        End If
                        lst.Items.Add(item)
                    End While
                End If

                Reader.Close()
            End Using
            Reader = Nothing


        End Sub

        Public Sub FillRADComboBox(ByVal sql As String, ByRef lst As Telerik.Web.UI.RadComboBox, Optional ByVal AddNoneEntry As Boolean = False, Optional ByVal IsNumeric As Boolean = True, Optional ByVal ConcatDescription As Boolean = False)
            'fills a passed RAD Combo Control based on SQLText 
            'will add a default entry if specified
            'will make default entry (value) number or string if specified
            'Will concat the value + "-" + Description if ConcatDescription is true

            If AddNoneEntry Then   'check for empty lst and add default record
                Dim item As New Telerik.Web.UI.RadComboBoxItem
                If IsNumeric Then
                    item.Value = 0
                Else
                    item.Value = "none"
                End If
                item.Text = "-- none --"
                lst.Items.Add(item)
            End If

            Dim Reader As SqlDataReader = ExecuteReader(sql)
            While Reader.Read()
                Dim item As New Telerik.Web.UI.RadComboBoxItem
                item.Value = ProcLib.CheckNullDBField(Reader("Val"))
                If ConcatDescription Then
                    item.Text = item.Value & "-" & Reader("Lbl")
                Else
                    item.Text = Reader("Lbl")
                End If
                lst.Items.Add(item)
            End While
            Reader.Close()
            Reader = Nothing


        End Sub

        Public Sub FillNewRADComboBox(ByVal sql As String, ByRef lst As Telerik.Web.UI.RadComboBox, Optional ByVal AddNoneEntry As Boolean = False, Optional ByVal IsNumeric As Boolean = True, Optional ByVal ConcatDescription As Boolean = False, Optional ByVal SetValSameAsLbl As Boolean = False)
            'fills a passed RAD Combo Control based on SQLText 
            'will add a default entry if specified
            'will make default entry (value) number or string if specified
            'Will concat the value + "-" + Description if ConcatDescription is true
            'Will put set value = text if SetValSameAsLbl = true

            If AddNoneEntry Then   'check for empty lst and add default record
                Dim item As New Telerik.Web.UI.RadComboBoxItem
                If IsNumeric Then
                    item.Value = 0
                Else
                    item.Value = "none"
                End If
                item.Text = "-- none --"
                lst.Items.Add(item)
            End If

            Dim Reader As SqlDataReader = ExecuteReader(sql)
            While Reader.Read()
                Dim item As New Telerik.Web.UI.RadComboBoxItem
                item.Value = ProcLib.CheckNullDBField(Reader("Val"))

                If ConcatDescription Then
                    item.Text = item.Value & "-" & Reader("Lbl")
                ElseIf SetValSameAsLbl Then
                    item.Text = item.Value
                Else
                    item.Text = Reader("Lbl")
                End If
                lst.Items.Add(item)
            End While
            Reader.Close()
            Reader = Nothing


        End Sub

        Public Sub FillRADListBox(ByVal sql As String, ByRef lst As Telerik.Web.UI.RadListBox, Optional ByVal AddNoneEntry As Boolean = False, Optional ByVal IsNumeric As Boolean = True, Optional ByVal ConcatDescription As Boolean = False)
            'fills a passed RAD Listbox Control based on SQLText 
            'will add a default entry if specified
            'will make default entry (value) number or string if specified
            'Will concat the value + "-" + Description if ConcatDescription is true

            If AddNoneEntry Then   'check for empty lst and add default record
                Dim item As New Telerik.Web.UI.RadListBoxItem
                If IsNumeric Then
                    item.Value = 0
                Else
                    item.Value = "none"
                End If
                item.Text = "-- none --"
                lst.Items.Add(item)
            End If

            Dim Reader As SqlDataReader = ExecuteReader(sql)
            While Reader.Read()
                Dim item As New Telerik.Web.UI.RadListBoxItem
                item.Value = ProcLib.CheckNullDBField(Reader("Val"))
                If ConcatDescription Then
                    item.Text = item.Value & "-" & Reader("Lbl")
                Else
                    item.Text = Reader("Lbl")
                End If
                lst.Items.Add(item)
            End While
            Reader.Close()
            Reader = Nothing


        End Sub

        Public Overridable Sub FillForm(ByVal frm As Control, ByRef sql As String)
            'fills a form from passed sql

            Dim dt As DataTable = ExecuteDataTable(sql)
            LoadControlCollectionFromDataRow(frm, dt.Rows(0))
            If dt.Rows.Count < 0 Then
                dt.Rows.Add(1)
            End If


        End Sub

        Public Overridable Sub FillForm(ByVal frm As Control, ByRef dt As DataTable)
            'fills a form from passed data table
            LoadControlCollectionFromDataRow(frm, dt.Rows(0))

        End Sub

        Public Overridable Sub FillForm(ByVal frm As Control, ByRef row As DataRow)
            'fills a form from passed data row
            LoadControlCollectionFromDataRow(frm, row)

        End Sub

 

        Private Sub LoadControlCollectionFromDataRow(ByVal passedctrl As Control, ByVal row As DataRow)

            'This loads all the controls in a passed collection (like a form) with data from a passed datarow by 
            'matching fieldname with control ID (minus 3 char prefix like txt or lbl)
            For Each ctrl As Control In passedctrl.Controls
                LoadSingleControlFromDataRow(ctrl, row)
            Next

        End Sub

        Private Sub LoadSingleControlFromDataRow(ByVal ctrl As Control, ByVal row As DataRow)

            'This loads a specific passed control with data from a passed datarow by 
            'matching fieldname with control ID (minus 3 char prefix like txt or lbl)

            Dim ctrlname As String = ""
            Dim colname As String = ""
            Dim colType As String = ""
            Dim colValue As String = ""

            For Each col As DataColumn In row.Table.Columns      'go through each column and match up the names
                colname = col.ColumnName
                colType = col.DataType().FullName 'will return the type of the column based on the type in the database.

                ctrlname = Mid(ctrl.ID, 4) 'strip off prefix for field name
                If ctrlname = colname Then  'then we have a column name that matches a control name
                    colValue = Trim(ProcLib.CheckNullDBField(row(ctrlname)))
                    If TypeOf ctrl Is TextBox Then
                        If colType = "System.Decimal" Then  'round to 2 decimal places
                            If colValue = "" Then
                                CType(ctrl, TextBox).Text = ""
                            Else
                                CType(ctrl, TextBox).Text = FormatNumber(ProcLib.CheckNullDBField(colValue), 2, TriState.True, TriState.True, TriState.True)
                            End If
                        Else
                            CType(ctrl, TextBox).Text = ProcLib.CheckNullDBField(colValue)
                        End If
                    End If
                    If TypeOf ctrl Is HiddenField Then
                        If colType = "System.Decimal" Then  'round to 2 decimal places
                            If colValue = "" Then
                                CType(ctrl, HiddenField).Value = ""
                            Else
                                CType(ctrl, HiddenField).Value = FormatNumber(ProcLib.CheckNullDBField(colValue), 2, TriState.True, TriState.True, TriState.True)
                            End If
                        Else
                            CType(ctrl, HiddenField).Value = ProcLib.CheckNullDBField(colValue)
                        End If
                    End If
                    If TypeOf ctrl Is HyperLink Then
                        If colType = "System.Decimal" Then  'round to 2 decimal places
                            If colValue = "" Then
                                CType(ctrl, HyperLink).Text = ""
                            Else
                                CType(ctrl, HyperLink).Text = FormatNumber(ProcLib.CheckNullDBField(colValue), 2, TriState.False, TriState.False, TriState.False)
                            End If
                        Else
                            CType(ctrl, HyperLink).Text = ProcLib.CheckNullDBField(colValue)
                        End If
                    End If



                    If TypeOf ctrl Is Telerik.Web.UI.RadInputControl Then

                        If TypeOf ctrl Is Telerik.Web.UI.RadNumericTextBox Then

                            CType(ctrl, Telerik.Web.UI.RadNumericTextBox).DbValue = ProcLib.CheckNullNumField(colValue)

                        Else  'normally would use numeric textbox for number but just in case

                            If colType = "System.Decimal" Then  'round to 2 decimal places
                                CType(ctrl, Telerik.Web.UI.RadInputControl).Text = CheckCurrencyFormat(colname, ProcLib.CheckNullDBField(colValue))
                            ElseIf colType = "System.DateTime" And TypeOf ctrl Is Telerik.Web.UI.RadDateInput Then  'Date control
                                If colValue <> "" Then
                                    CType(ctrl, Telerik.Web.UI.RadDateInput).SelectedDate = CDate(colValue)
                                Else
                                    CType(ctrl, Telerik.Web.UI.RadDateInput).SelectedDate = Now()
                                End If

                            Else
                                CType(ctrl, Telerik.Web.UI.RadInputControl).Text = ProcLib.CheckNullDBField(colValue)
                            End If
                        End If
                    End If


                    If TypeOf ctrl Is Telerik.Web.UI.RadNumericTextBox Then

                        CType(ctrl, Telerik.Web.UI.RadNumericTextBox).DbValue = ProcLib.CheckNullNumField(colValue)

                    End If


                    'If TypeOf ctrl Is Telerik.WebControls.RadDatePicker Then   'For Old Version
                    '    CType(ctrl, Telerik.WebControls.RadDatePicker).DbSelectedDate = ProcLib.CheckDateField(colValue)
                    'End If


                    If TypeOf ctrl Is Telerik.Web.UI.RadDatePicker Then  'For new ajax version
                        CType(ctrl, Telerik.Web.UI.RadDatePicker).DbSelectedDate = ProcLib.CheckDateField(colValue)
                    End If

                    If TypeOf ctrl Is Telerik.Web.UI.RadColorPicker Then
                        CType(ctrl, Telerik.Web.UI.RadColorPicker).SelectedColor = System.Drawing.ColorTranslator.FromHtml(colValue)
                    End If

                    If TypeOf ctrl Is Telerik.Web.UI.RadEditor Then      'For new ajax version
                        CType(ctrl, Telerik.Web.UI.RadEditor).Content = colValue
                    End If


                    If TypeOf ctrl Is Label Then
                        If colType = "System.Decimal" Then  'round to 2 decimal places
                            CType(ctrl, Label).Text = CheckCurrencyFormat(colname, ProcLib.CheckNullDBField(colValue))
                        Else
                            CType(ctrl, Label).Text = ProcLib.CheckNullDBField(colValue)
                        End If
                    End If
                    If TypeOf ctrl Is DropDownList Then
                        Dim cc As DropDownList = ctrl

                        On Error Resume Next   'BUG -- need to fix this if value not in list it dies
                        cc.SelectedValue = ProcLib.CheckNullDBField(colValue)
                        On Error GoTo 0
                    End If

                    If TypeOf ctrl Is Telerik.Web.UI.RadListBox Then    'new RAD listbox
                        Dim cc As Telerik.Web.UI.RadListBox = ctrl
                        For Each item As Telerik.Web.UI.RadListBoxItem In cc.Items
                            If item.Value = ProcLib.CheckNullDBField(colValue) Then
                                item.Checked = True
                            End If
                        Next

                    End If

                    If TypeOf ctrl Is Telerik.Web.UI.RadComboBox Then  'For new ajax version
                        Dim cc As Telerik.Web.UI.RadComboBox = ctrl
                        Dim bfound As Boolean = False
                        Dim val = ProcLib.CheckNullDBField(colValue)
                        For Each item As Telerik.Web.UI.RadComboBoxItem In cc.Items
                            If item.Value = val Then
                                item.Selected = True
                                bfound = True
                                Exit For
                            End If
                        Next
                        If Not bfound Then   ' item was not found in list
                            cc.Text = val
                            cc.SelectedValue = val

                        End If

                    End If


                    If TypeOf ctrl Is CheckBox Then
                        If Not IsDBNull(row(ctrlname)) Then
                            If row(ctrlname) = 1 Then
                                CType(ctrl, CheckBox).Checked = True
                            End If
                        End If
                    End If
                End If
            Next

        End Sub
        Public Overridable Sub FillUDFEditTable(ByVal frmtbl As Control, ByRef dt As DataTable)
            'fills a form from passed data table that contains a UDF Table - lloks for udf in control name to recurse
            'Specifically looks for UDF Control to filter out unneeded recursive calls

            Dim ctrlname As String = ""
            For Each ctrlmaster As Control In frmtbl.Controls    'table level
                If ctrlmaster.Controls.Count > 0 Then
                    For Each ctrlsub As Control In ctrlmaster.Controls     'row/col level
                        If ctrlsub.Controls.Count > 0 Then
                            For Each ctrl As Control In ctrlsub.Controls     'actual controls
                                ctrlname = ctrl.ID
                                If ctrlname.Contains("udf_") Then
                                    LoadSingleControlFromDataRow(ctrl, dt.Rows(0))
                                End If
                            Next
                        End If
                    Next
                End If
            Next

        End Sub

  
        Private Function CheckCurrencyFormat(ByVal fldname As String, ByVal value As String) As String
            'NOTE: This is legacy code - needs to be accomodated differently - perhaps we can use id prefixes on the 
            'controls themselves to denote if they are holding currency or not.

            'Passes back formatted number based on if it is a currency field - as all numbers in DB are system.type decimal,
            'we need to write our own checker to determin format

            If value <> "" Then
                Select Case fldname
                    Case "BondAmount", "Series1Amt", "Series2Amt", "Series3Amt", "Series4Amt", "StateFundAnticipated"
                        CheckCurrencyFormat = FormatCurrency(value, 2)

                    Case Else
                        CheckCurrencyFormat = FormatNumber(value, 2, TriState.False, TriState.False, TriState.False)
                End Select
            Else
                CheckCurrencyFormat = ""
            End If

        End Function

        Public Sub SaveForm(ByVal frm As Control, ByRef sql As String)

            FillDataTableForUpdate(sql)
            WriteFormControlValuesToTableRow(frm, DataTable)
            UpdateDBFromDataAdaptor()

        End Sub

        Public Sub SaveMultipleFormControlsToDB(ByVal passedctrl As Control)
            'Does several passes to write to table row. Useful when need to save controls from multiple parts of a form with single read/write
            'NOTE: Need to open the data adaptor first and then close

            WriteFormControlValuesToTableRow(passedctrl, DataTable)


        End Sub

        Private Sub WriteFormControlValuesToTableRow(ByVal passedctrl As Control, ByVal dt As DataTable)


            'Saves the parent form to database based on passed sql
            'requires that the field names on the form match the field names in dataset (Minus the prefix)

            Dim row As DataRow = DataTable.Rows(0)

            Dim colname As String
            Dim colType As String
            Dim colValue
            Dim ctrlname As String

            'this flag is needed because forms only return fields that have values, so
            'if boxes are unchecked they will not get passed, but still need to update the DB
            Dim bFound As Boolean = False

            For Each col As DataColumn In DataTable.Columns      'iterate each of the columns and look for field match
                colname = col.ColumnName
                colType = col.DataType().FullName

                bFound = False
                'will return the type of the column based on the type in the database.
                For Each ctrl As Control In passedctrl.Controls                    'iterate each of the returned forms controls
                    ctrlname = Mid(ctrl.ID, 4) 'strip off prefix for field name

                    If colname = ctrlname Then   'then we have a column name that matches a control name
                        bFound = True

                        If TypeOf ctrl Is TextBox Then
                            colValue = Trim(CType(ctrl, TextBox).Text)

                            If colType = "System.Decimal" Then  'round to 2 decimal places
                                If colValue <> "" Then
                                    colValue = FormatNumber(colValue, 2, TriState.False, TriState.False, TriState.False)
                                Else
                                    colValue = 0
                                End If
                                row(ctrlname) = colValue
                            ElseIf colType = "System.DateTime" Then    'round to 2 decimal places
                                If colValue = "" Then
                                    row(ctrlname) = DBNull.Value
                                Else
                                    row(ctrlname) = colValue
                                End If

                            ElseIf colType = "System.Int16" Then    'make sure it is a number
                                If colValue = "" Then
                                    row(ctrlname) = 0
                                Else
                                    row(ctrlname) = colValue
                                End If

                            ElseIf colType = "System.Int32" Then    'make sure it is a number
                                If colValue = "" Then
                                    row(ctrlname) = 0
                                Else
                                    row(ctrlname) = colValue
                                End If

                            Else
                                row(ctrlname) = colValue
                            End If
                        End If

                        If TypeOf ctrl Is Label Then

                            colValue = CType(ctrl, Label).Text
                            row(ctrlname) = colValue
                        End If

                        If TypeOf ctrl Is Telerik.Web.UI.RadDatePicker Then
                            colValue = CType(ctrl, Telerik.Web.UI.RadDatePicker).DbSelectedDate
                            row(ctrlname) = ProcLib.CheckDateField(colValue)    'save dbnull if not date

                        End If

                        If TypeOf ctrl Is Telerik.Web.UI.RadInputControl Then

                            colValue = CType(ctrl, Telerik.Web.UI.RadInputControl).Text
                            If colValue = "" Then colValue = 0
                            row(ctrlname) = colValue

                        End If

                        If TypeOf ctrl Is Telerik.Web.UI.RadNumericTextBox Then

                            colValue = CType(ctrl, Telerik.Web.UI.RadNumericTextBox).Text
                            If colValue = "" Then colValue = 0
                            row(ctrlname) = colValue

                        End If

                        If TypeOf ctrl Is Telerik.Web.UI.RadColorPicker Then

                            colValue = System.Drawing.ColorTranslator.ToHtml(CType(ctrl, Telerik.Web.UI.RadColorPicker).SelectedColor)
                            row(ctrlname) = colValue

                        End If


                        If TypeOf ctrl Is DropDownList Then
                            colValue = CType(ctrl, DropDownList).SelectedValue
                            row(ctrlname) = colValue
                        End If


                        If TypeOf ctrl Is Telerik.Web.UI.RadComboBox Then    'for new control
                            colValue = CType(ctrl, Telerik.Web.UI.RadComboBox).SelectedValue
                            Dim colText As String = CType(ctrl, Telerik.Web.UI.RadComboBox).Text
                            If colValue <> "" Then
                                row(ctrlname) = colValue
                            Else
                                If colText <> "" Then
                                    row(ctrlname) = colText
                                End If
                            End If

                        End If


                        If TypeOf ctrl Is Telerik.Web.UI.RadEditor Then
                            colValue = CType(ctrl, Telerik.Web.UI.RadEditor).Text.ToString
                            row(ctrlname) = colValue
                        End If

                        If TypeOf ctrl Is Telerik.Web.UI.RadEditor Then                 'For new editor
                            colValue = CType(ctrl, Telerik.Web.UI.RadEditor).Content.ToString
                            row(ctrlname) = colValue
                        End If


                        If TypeOf ctrl Is CheckBox Then
                            colValue = CType(ctrl, CheckBox).Checked
                            If colValue = True Then
                                colValue = 1
                            Else
                                colValue = 0
                            End If
                            row(ctrlname) = colValue
                        End If
                    End If
                Next

            Next
            'write the timestamp
            row("LastUpdateBy") = CurrentUserName
            row("LastUpdateOn") = Now()


        End Sub


        Public Sub FillReportParmDropDown(ByVal sql As String, ByRef lst As DropDownList, ByVal NKeyFieldName As String)
            'fills a passed DropDown Control based on SQLText specifically for report paramters
            'will add a default entry if specified
            'will make default entry number or string if specified
            'Will concat the value + "-" + Description if ConcatDescription is true
            Dim bAdd As Boolean = True
            FillReader(sql)
            While Reader.Read()

                'Filter approved colleges from list if report is college level
                If NKeyFieldName = "CollegeID" Or NKeyFieldName = "ProjectID" Then

                    If HttpContext.Current.Session("UserRole") <> "TechSupport" Then
                        If InStr(HttpContext.Current.Session("CollegeList"), ";" & Reader("CollegeID") & ";") Then
                            bAdd = True
                        Else
                            bAdd = False
                        End If
                    End If
                End If

                If bAdd Then
                    Dim item As New ListItem
                    item.Value = Reader("Val")
                    item.Text = Reader("Lbl")
                    lst.Items.Add(item)
                End If

            End While
            Reader.Close()

        End Sub

   

#End Region

#Region "General Routines"

        Public Sub FillReader(ByVal sql As String)
            'fills the public reader from sql statement
            If Not Reader Is Nothing Then
                Reader.Close()
            End If
            Using command As SqlCommand = CreateSqlStringCommand(sql)
                Reader = ExecuteReader("FillReader", command)
            End Using

        End Sub

        Public Sub FillDataTable(ByVal sql As String)
            'fills the public table from sql statement
            If Not DataTable Is Nothing Then
                DataTable.Dispose()
            End If
            Using command As SqlCommand = CreateSqlStringCommand(sql)
                DataTable = ExecuteDataTable("FillDataTable", command)
            End Using

        End Sub
        Public Sub FillDataTableForUpdate(ByVal sql As String)
            'fills the public table from sql statement and adds update functionality
            If Not DataTable Is Nothing Then
                DataTable.Dispose()
            End If
            BuildDataAdaptor(sql)
            Dim dt As DataTable = _ds.Tables("tbl")
            DataTable = dt

        End Sub


        Private Sub BuildDataAdaptor(ByVal sql As String)
            'builds a data adaptor and assigns to _da. fills dataset.  
            _da = New SqlDataAdapter(sql + " /* test */ ", ProcLib.GetDataConnectionString())
            _sqlcmd = New SqlCommandBuilder(_da)
            _ds = New DataSet
            _da.Fill(_ds, "tbl")

        End Sub


        Private Sub UpdateDBFromDataAdaptor()
            'writes changes in dataset to database
            _da.Update(_ds, "tbl")

        End Sub

        Public Sub SaveDataTableToDB()
            'write the previously filled public data table (from FillDataTableForUpdate) to database
            UpdateDBFromDataAdaptor()

        End Sub

        Public Sub Close()
            ' This method cleans up the resources 
            If Not Reader Is Nothing Then
                Reader.Close()
                Reader = Nothing
            End If
            If Not DataTable Is Nothing Then
                DataTable.Dispose()
                DataTable = Nothing
            End If
            If Not _ds Is Nothing Then
                _ds.Dispose()
                _ds = Nothing
            End If
            If Not _sqlcmd Is Nothing Then
                _sqlcmd.Dispose()
                _sqlcmd = Nothing
            End If
            If Not _da Is Nothing Then
                _da.Dispose()
                _da = Nothing
            End If
        End Sub

#End Region


#Region "IDisposable"

        Public Overridable Sub Dispose() Implements IDisposable.Dispose
            If _disposeConnection AndAlso Not _connection Is Nothing Then
                _connection.Dispose()
            End If

            Close()

        End Sub

#End Region

#Region "Creating commands"

        Public Function CreateSqlStringCommand(ByVal text As String) As SqlCommand
            Dim command As SqlCommand = _connection.CreateCommand()
            command.CommandType = CommandType.Text
            '4/21/2011-roy - the following line is experimental
            'this sets the SQL Server global variable Context_Info with the current username
            'a (newly created) trigger (currently just for BudgetObjectCodes table) makes use of this variable
            'to determine which user is making a change to the table.
            'there is no other way for the application (Prompt) to tell SQL Server which user is performing the change
            'unless this would have been baked into Prompt and its db tables right from the start.
            'this does not work (i.e. username is not transferred) for all table data changes; for example 
            'when a dataset update of a table occurs (i.e. through the SaveForm routine), the code below is not run...
            '
            'As further documentation, here is the current code for the trigger:
            'Create Trigger trg_Log_BudgetObjectCodes
            '	On BudgetObjectCodes
            'After(Insert, Update, Delete)
            'As
            '
            'Declare @user as varchar(1000)
            'Set @user = cast(CONTEXT_INFO() as char(128))  
            '
            'If Not Exists (Select * From inserted)
            'Begin	--this is for DELETED rows
            '	Insert into log_BudgetObjectCodes Select 'D' as AuditType, GETDATE() as AuditTime, @user as AuditUser, * From deleted
            'End
            'Else If Not Exists (Select * From deleted)
            'Begin	--this is for INSERTED rows
            '	Insert into log_BudgetObjectCodes Select 'I' as AuditType, GETDATE() as AuditTime, @user as AuditUser, * From inserted
            'End
            'Else	--this is for UPDATED rows
            'Begin
            '	Insert into log_BudgetObjectCodes Select 'D' as AuditType, GETDATE() as AuditTime, @user as AuditUser, * From deleted
            '	Insert into log_BudgetObjectCodes Select 'I' as AuditType, GETDATE() as AuditTime, @user as AuditUser, * From inserted
            'End
            '
            'Further documentation ... the log table for BudgetObjectCodes (4 columns added for audit purposes to the current BOC table schema)
            'CREATE TABLE [dbo].[log_BudgetObjectCodes](
            '    [AuditID] [int] IDENTITY(1,1) NOT NULL,
            '    [AuditType] [char](1),
            '    [AuditTime] [datetime],
            '    [AuditUser] [varchar](1000),
            '    [PrimaryKey] [int] NULL,
            '    [DistrictID] [int] NULL,
            '    [CollegeID] [int] NULL,
            '    [ProjectID] [int] NULL,
            '    [ObjectCode] [varchar](30) NULL,
            '    [Description] [varchar](150) NULL,
            '    [JCAFColumnName] [varchar](30) NULL,
            '    [Amount] [money] NULL,
            '    [LastUpdateOn] [smalldatetime] NULL,
            '    [LastUpdateBy] [varchar](50) NULL,
            '    [LedgerAccountID] [int] NULL,
            '   [ItemDate] [datetime] NULL,
            '   [Notes] [varchar](max) NULL,
            'CONSTRAINT [PK_AuditID] PRIMARY KEY CLUSTERED 
            '(
            '[AuditID](Asc)
            ')WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
            ') ON [PRIMARY]
            'GO()
            command.CommandText = "; Declare @CI varbinary(128); Select @CI = cast( '" + CurrentUserName + "' + space(128) AS binary(128) ); Set CONTEXT_INFO @CI; "
                command.CommandText += text + " -- " + CurrentUserName
                Return command
        End Function


#End Region

#Region "Adding parameters"

        Public Overridable Sub AddInParameter( _
                ByVal command As SqlCommand, _
                ByVal name As String, _
                ByVal type As SqlDbType, _
                ByVal value As Object)
            Dim parameter As SqlParameter = command.CreateParameter()
            parameter.Direction = ParameterDirection.Input
            parameter.ParameterName = name
            parameter.SqlDbType = type
            parameter.Value = IIf(Not value Is Nothing, value, DBNull.Value)
            command.Parameters.Add(parameter)
        End Sub

        'Public Overridable Sub AddInParameter(Of T As Structure)( _
        '        ByVal command As SqlCommand, _
        '        ByVal name As String, _
        '        ByVal type As SqlDbType, _
        '        ByVal value As Nullable(Of T))
        '    If value.HasValue Then
        '        AddInParameter( _
        '            command, _
        '            name, _
        '            type, _
        '            value.Value)
        '    Else
        '        AddInParameter( _
        '            command, _
        '            name, _
        '            type, _
        '            Nothing)
        '    End If
        'End Sub

#End Region

#Region "Executing commands"

        Public Overridable Function ExecuteNonQuery(ByVal nonQueryName As String, ByVal command As SqlCommand) As Integer
            Dim rowsAffected As Integer = command.ExecuteNonQuery()
            Return rowsAffected
        End Function

        Public Overridable Sub ExecuteNonQuery(ByVal SQL As String)
            'Performs the passed sql statement and passes nothing back
            'usefull for shortcut sql commands
            Using command As SqlCommand = CreateSqlStringCommand(SQL)
                ExecuteNonQuery("DirectSQL", command)
            End Using

        End Sub

        Public Overridable Function ExecuteNonQueryWithReturn(ByVal SQL As String)
            Dim ret As Integer
            Using command As SqlCommand = CreateSqlStringCommand(SQL)
                ret = ExecuteNonQuery("DirectSQL", command)
            End Using
            Return ret
        End Function


        Public Overridable Sub ExecuteStoredProcedure(ByVal SPName As String)
            'Executes the pass SP name and passes nothing back
            'usefull for shortcut sql commands
            Using command As SqlCommand = _connection.CreateCommand()
                command.CommandType = CommandType.StoredProcedure
                command.CommandText = SPName
                command.ExecuteNonQuery()
            End Using

        End Sub


        Public Overridable Function ExecuteReader(ByVal SQL As String) As SqlDataReader

            Using command As SqlCommand = CreateSqlStringCommand(SQL)
                Return ExecuteReader("DirectSQL", command)
            End Using

        End Function

        Public Overridable Function ExecuteReader(ByVal queryName As String, ByVal command As SqlCommand) As SqlDataReader
            Return ExecuteReader(queryName, command, CommandBehavior.Default)
        End Function

        Public Overridable Function ExecuteReader(ByVal queryName As String, ByVal command As SqlCommand, ByVal commandBehavior As CommandBehavior) As SqlDataReader
            Dim reader As SqlDataReader = command.ExecuteReader(commandBehavior)
            Return reader
        End Function

        Public Overridable Function ExecuteXmlReader(ByVal queryName As String, ByVal command As SqlCommand) As XmlReader
            Dim reader As XmlReader = command.ExecuteXmlReader()
            Return reader
        End Function

        Public Overridable Function ExecuteDataSet(ByVal queryName As String, ByVal command As SqlCommand) As DataSet
            Dim result As New DataSet()
            Using reader As SqlDataReader = ExecuteReader(queryName, command)
                result.Load(reader, LoadOption.PreserveChanges, DirectCast(Nothing, DataTable()))
            End Using
            Return result
        End Function

        Public Overridable Function ExecuteDataTable(ByVal queryName As String, ByVal command As SqlCommand) As DataTable
            Dim result As New DataTable()
            Using reader As SqlDataReader = ExecuteReader(queryName, command)
                result.Load(reader)
            End Using
            Return result
        End Function

        Public Overridable Function GetDataRow(ByVal sql As String) As DataRow
            'get single row of data from table
            Dim dt As DataTable
            dt = ExecuteDataTable(sql)
            Return dt.Rows(0)
        End Function

        Public Overridable Function ExecuteDataTable(ByVal SQL As String) As DataTable
            Dim result As New DataTable()
            Using command As SqlCommand = CreateSqlStringCommand(SQL)
                Using reader As SqlDataReader = ExecuteReader("GetDataTable", command)
                    result.Load(reader)
                End Using
            End Using
            Return result
        End Function

        Public Overridable Function ExecuteScalar(ByVal queryName As String, ByVal command As SqlCommand) As Object
            'Executes the query, and returns the first column of the first row 
            'in the result set returned by the query. Additional columns 
            'or rows are ignored. 
            Dim result As Object = command.ExecuteScalar()
            Return result
        End Function


        Public Overridable Function ExecuteScalar(ByVal sql As String) As Object
            'Executes the query, and returns the first column of the first row 
            'in the result set returned by the query. Additional columns 
            'or rows are ignored. 
            Using command As SqlCommand = CreateSqlStringCommand(sql)
                Return ExecuteScalar("DirectSQL", command)
            End Using
        End Function

        Public Overridable Function ExecuteScalar(ByVal queryName As String, ByVal command As SqlCommand, ByVal defaultValue As Object) As Object
            Dim value As Object = ExecuteScalar(queryName, command)
            Return IIf(Not value Is Nothing, value, defaultValue)
        End Function

#End Region

    End Class

End Namespace
