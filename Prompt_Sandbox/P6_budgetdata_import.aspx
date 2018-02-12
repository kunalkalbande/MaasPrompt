<%@ Page Language="vb" %>

<%@ Register Assembly="Telerik.Web.UI" Namespace="Telerik.Web.UI" TagPrefix="telerik" %>
<%@ Import Namespace="System.IO" %>
<%@ Import Namespace="System.IO.FileSystemInfo" %>
<%@ Import Namespace="Prompt" %>
<%@ Import Namespace="Microsoft.SqlServer.Dts.Runtime" %>
<%@ Import Namespace="System.Data" %>
<%@ Import Namespace="System.Data.SqlCLient" %>
<%@ Import Namespace="System.Data.OleDb" %>
<%@ Import Namespace="System.Text.RegularExpressions" %>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">

<script runat="server">
    ' TODO: do Excel file MIME? validation on uploaded file so that it does not break the whole process
    Private Sub Page_Load(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MyBase.Load
        
        ProcLib.CheckSession(Page)
        ProcLib.LoadPopupJscript(Page)
        Session("PageID") = "P6BudgetImport"

        'set up help button
        butHelp.Attributes.Add("onclick", "openPopup('help_view.aspx','pophelp',550,450,'yes');")
        butHelp.NavigateUrl = "#"
        
        Label2.Visible = False
    End Sub

    Protected Sub Button1_Click(ByVal sender As Object, ByVal e As System.EventArgs)
        Dim sql As String
        Dim sFileName As String = "\P6_budget.xls"
        
        'get the file and store it in the root of the attachments folder
        For Each File As Telerik.Web.UI.UploadedFile In RadUpload1.UploadedFiles
            File.SaveAs(ProcLib.GetCurrentAttachmentPath() & sFileName, True)
        Next
        Label2.Visible = False

        ' read the Excel table into a dataset
        Dim sConnectionString As String = "Provider=Microsoft.Jet.OLEDB.4.0;Data Source=" + ProcLib.GetCurrentAttachmentPath() _
            + sFileName + ";" & "Extended Properties=Excel 8.0;"
        Dim objConn As New OleDbConnection(sConnectionString)                  ' Create the connection object by using the preceding connection string.
        objConn.Open()                                                          ' Open connection with the database.
        Dim objCmdSelect As New OleDbCommand("SELECT * FROM [Sheet1$]", objConn)     ' Create new OleDbCommand to return data from worksheet.
        Dim objAdapter1 As New OleDbDataAdapter()
        objAdapter1.SelectCommand = objCmdSelect                                ' Pass the Select command to the adapter.
        Dim objDataset1 As New DataSet()                                        ' Create new DataSet to hold information from the worksheet.
        objAdapter1.Fill(objDataset1, "BudgetData")                                 ' Fill the DataSet with the information from the worksheet.

        'go through each record in the dataset/excel file
        Using reader As DataTableReader = objDataset1.CreateDataReader
            Dim i As Integer = 0        'row counter
            Dim str As String
            Dim Pnum As String          'project number
            Dim Pid As Integer          'project ID
            Dim StartDate As Date, EndDate As Date
            Do While reader.Read()  'loop for each record/row in the excel file
                i += 1
                str = reader("Activity ID")
                If Regex.IsMatch(str, ".*#[0-9][0-9][0-9] ") Then 'this row contains #XYZ (project #xyz data)
                    Pnum = str.Substring(str.IndexOf("#") + 1, 3)
                    Using db As New PromptDataHelper    'get the ProjectID for this project
                        sql = "Select Distinct ProjectID From Projects Where DistrictID = 55 and ProjectNumber = '" + Pnum + "' and Coalesce(ProjectSubNumber,'') = ''"
                        Pid = db.ExecuteScalar(sql)
                    End Using
                    'delete the project's existing budget data in preparation for import
                    Using db As New PromptDataHelper
                        sql = "Delete From BudgetReporting Where ProjectID = " & Pid
                        db.ExecuteNonQuery(sql)
                    End Using
                    Dim column As Integer = 2       'start at column 2 (ignore column 1 [Budget Cost Total])
                    While reader(column) Is DBNull.Value        'bypass the initial 0 entries to find the start date for spending
                        column += 1
                    End While
                    StartDate = DateAdd(DateInterval.Month, (column - 2) * 3, CDate("1/1/2007"))
                    'now find the EndDate for project spending and update the project
                    Dim ee As Integer = reader.FieldCount - 1
                    While reader(ee) Is DBNull.Value
                        ee -= 1
                    End While
                    EndDate = DateAdd(DateInterval.Month, ((ee - 2) * 3) + 2, CDate("1/1/2007"))
                    'now update the project's StartDate and EndDate in the Projects table
                    Using db As New PromptDataHelper
                        sql = "Update Projects Set StartDate = '" & StartDate & "' Where DistrictID = 55 and ProjectID = " & Pid
                        db.ExecuteNonQuery(sql)
                        sql = "Update Projects Set EstCompleteDate = '" & EndDate & "' Where DistrictID = 55 and ProjectID = " & Pid
                        db.ExecuteNonQuery(sql)
                    End Using
                    'now add necessary rows in the BudgetReporting table
                    While column <= ee    'loop through each column in the record/row between Start and End dates
                        Using db As New PromptDataHelper
                            Dim dd As Date
                            For ii As Integer = 0 To 2  'insert a row in the table for each month in the quarter
                                dd = DateAdd(DateInterval.Month, ((column - 2) * 3) + ii, CDate("1/1/2007"))
                                sql = "Insert into BudgetReporting (ProjectID, ReportingDate, Budget, Actual, LastUpdateOn, LastUpdateBy) "
                                sql = sql & "Values (" & Pid & ", '" & dd & "', " & IIf(IsDBNull(reader(column)), 0, reader(column)) / 3 & ", 0, '" & Now() & "', 'P6Update')"
                                db.ExecuteNonQuery(sql)
                            Next ii
                        End Using
                        column += 1
                    End While 'loop through each column in record/row
                Else
                    'ignore this row
                End If
                
            Loop 'for each record in excel file
        End Using 'reader
        objConn.Close()        ' Clean up connection objects.
        Label2.Visible = True

    End Sub
</script>

<html>
<head>
    <title>P6 Data Exchange</title>
    <meta content="Microsoft Visual Studio .NET 7.1" name="GENERATOR">
    <meta content="Visual Basic .NET 7.1" name="CODE_LANGUAGE">
    <meta content="JavaScript" name="vs_defaultClientScript">
    <meta content="http://schemas.microsoft.com/intellisense/ie5" name="vs_targetSchema">
    <link href="Styles.css" type="text/css" rel="stylesheet">
</head>
<body>
<form id="Form1" method="post" runat="server">
     <telerik:RadScriptManager ID="RadScriptManager1" runat="server" />
    <table width="100%">
        <tr>
            <td class="pageheading" style="height: 11px" align="left">
                P6 - Budget Data Import
            </td>
            <td class="pageheading" style="height: 11px" align="right">
                <asp:HyperLink ID="butHelp" runat="server" ImageUrl="images/button_help.gif">HyperLink</asp:HyperLink>
            </td>
        </tr>
        <tr>
            <td colspan="2" style="height: 26px">
                <asp:Label ID="Label1" runat="server">Select Excel File with P6 budget data to Import:</asp:Label>
            </td>
        </tr>
        <tr>
            <td colspan="2" style="height: 21px">
                &nbsp; &nbsp;
                <telerik:RadUpload ID="RadUpload1" runat="server" Style="z-index: 100; left: 8px; top: 54px"
                    ControlObjectsVisibility="None" Width="500px" EnableFileInputSkinning="False"
                    Height="20px" />
                &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp &nbsp
                <asp:Button ID="Button1" runat="server" Text="Start Import" OnClick="Button1_Click" />
                &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp &nbsp
                <asp:Label ID="Label2" runat="server" Text="Done!"></asp:Label>
            </td>
        </tr>
    </table>
    </form>
</body>
</html>
