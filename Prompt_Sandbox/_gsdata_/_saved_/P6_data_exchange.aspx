<%@ Page Language="vb" %>

<%@ Register Assembly="Telerik.Web.UI" Namespace="Telerik.Web.UI" TagPrefix="telerik" %>
<%@ Import Namespace="System.IO" %>
<%@ Import Namespace="System.IO.FileSystemInfo" %>
<%@ Import Namespace="Prompt" %>
<%@ Import Namespace="Microsoft.SqlServer.Dts.Runtime" %>
<%@ Import Namespace="System.Data" %>
<%@ Import Namespace="System.Data.SqlCLient" %>
<%@ Import Namespace="System.Data.OleDb" %>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">

<script runat="server">
    ' TODO: do Excel file MIME? validation on uploaded file so that it does not break the whole process
    Private Sub Page_Load(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MyBase.Load
        
        ProcLib.CheckSession(Page)
        ProcLib.LoadPopupJscript(Page)
        Session("PageID") = "UploadP6Data"
        
        RadGrid1.Visible = False

        'set up help button
        butHelp.Attributes.Add("onclick", "openPopup('help_view.aspx','pophelp',550,450,'yes');")
        butHelp.NavigateUrl = "#"
    End Sub

    
    Protected Sub butExchangeData_Click(ByVal sender As Object, ByVal e As System.EventArgs)
        For Each File As Telerik.Web.UI.UploadedFile In RadUpload1.UploadedFiles
            File.SaveAs(ProcLib.GetCurrentAttachmentPath() + "\Foothill.xls", True)
        Next
        
        Using db As New PromptDataHelper
            'db.ExecuteNonQuery("exec sp_addlinkedserver 'abc',@srvproduct='',@provider='Microsoft.Jet.OLEDB.4.0',@datasrc='C:\Documents and Settings\roy\Desktop\P6_latest\Foothill.xls',@provstr='Excel 8.0;'")
        
            db.ExecuteStoredProcedure("spQryP6Resources")
        End Using

        
        
        
    End Sub

    Protected Sub OLDbutExchangeData_Click(ByVal sender As Object, ByVal e As System.EventArgs)
        For Each File As Telerik.Web.UI.UploadedFile In RadUpload1.UploadedFiles
            File.SaveAs(ProcLib.GetCurrentAttachmentPath() + "\P6_import.xls", True)
        Next
        
        '--------------------------------------------------
        'delete all rows in preparation for import
        Using db As New PromptDataHelper
            Dim sql As String
            sql = "Delete From P6PromptTransferActualExpenses"
            db.ExecuteNonQuery(sql)
        End Using
        
        ' read the Excel table into a dataset
        Dim sConnectionString As String = "Provider=Microsoft.Jet.OLEDB.4.0;Data Source=" + ProcLib.GetCurrentAttachmentPath() _
            + "\P6_import.xls" + ";" & "Extended Properties=Excel 8.0;"
        Dim objConn As New OleDbConnection(sConnectionString)                  ' Create the connection object by using the preceding connection string.
        objConn.Open()                                                          ' Open connection with the database.
        Dim objCmdSelect As New OleDbCommand("SELECT * FROM [TASKRSRC$]", objConn)     ' Create new OleDbCommand to return data from worksheet.
        Dim objAdapter1 As New OleDbDataAdapter()
        objAdapter1.SelectCommand = objCmdSelect                                ' Pass the Select command to the adapter.
        Dim objDataset1 As New DataSet()                                        ' Create new DataSet to hold information from the worksheet.
        objAdapter1.Fill(objDataset1, "XLData")                                 ' Fill the DataSet with the information from the worksheet.
        
        ' write the data from the dataset into the Prompt database table
        Using reader As DataTableReader = objDataset1.CreateDataReader
            reader.Read()           'dummy read to ignore second "header row"
            Dim st As String
            Do While reader.Read()
                st = "Insert into P6PromptTransferActualExpenses ("
                st += "task_id,TASK__status_code,rsrc_id,role_id,acct_id,proj_id,task__wbs_name,user_field_131,task__task_name, "
                st += "rsrc__rsrc_name,total_cost,act_cost,delete_record_flag) VALUES ("
                st += "'" + reader("task_id").ToString + "',"
                st += "'" + reader("TASK__status_code").ToString + "',"
                st += "'" + reader("rsrc_id").ToString + "',"
                st += "'" + reader("role_id").ToString + "',"
                st += "'" + reader("acct_id").ToString + "',"
                st += "'" + reader("proj_id").ToString + "',"
                st += "'" + reader("task__wbs_name").ToString + "',"
                st += "'" + reader("user_field_131").ToString + "',"
                st += "'" + reader("task__task_name").ToString + "',"
                st += "'" + reader("rsrc__rsrc_name").ToString + "',"
                st += "'" + Mid(reader("total_cost").ToString, 1) + "',"
                st += "'" + Mid(reader("act_cost").ToString, 1) + "',"
                st += "'" + reader("delete_record_flag").ToString + "')"
                Using db As New PromptDataHelper
                    db.ExecuteNonQuery(st)
                End Using
            Loop
        End Using
        objConn.Close()        ' Clean up objects.

        'run the stored procedure to update table with updated actuals data
        Using db As New PromptDataHelper
            db.ExecuteStoredProcedure("spP6UpdateExpenses")
        End Using


        
        '--------------------------------------------------
        'Using db As New PromptDataHelper
        '    Dim sql As String
        '    sql = "Delete From P6PromptTransferActualExpenses"        'delete all rows in preparation for import
        '    db.ExecuteNonQuery(sql)
        '    sql = "Insert into P6PromptTransferActualExpenses Select * FROM OPENROWSET('Microsoft.Jet.OLEDB.4.0', 'Excel 8.0;Database=" + Proclib.GetCurrentAttachmentPath() + "\P6_import.xls ', DATA$)"
        '    db.ExecuteNonQuery(sql)
        '    db.ExecuteStoredProcedure("spP6UpdateExpenses")  'run more complex query/stored procedure to update table with updated actuals data
        'End Using
        '--------------------------------------------------

        ''Create a new connection object for Book1.xls
        'Dim conn As New adodb.Connection
        'conn.Open("Provider=Microsoft.Jet.OLEDB.4.0;Data Source=" + Proclib.GetCurrentAttachmentPath() + "\P6_import.xls;Extended Properties=Excel 8.0;")
        'conn.Execute("Insert into DATA (act_cost, total_cost) values (2,3)")
        'conn.Execute("Insert into MyTable (FirstName, LastName) values ('Joe', 'Thomas')")
        'conn.Close()
        '--------------------------------------------------

        'If Proclib.GetLocale() = "Production" Or Proclib.GetLocale() = "Beta" Then   'Beta or Production will use same data exchange location
        '    Response.Redirect("D:\Gilbane P6 File Dump\Prompt_Actuals.xls")
        'Else    'localhost -- THIS IS CORRECT FOR ROY'S LAPTOP -- NOT TESTED ANYWHERE ELSE!!!!
        '    Response.Redirect("C:\PromptAttachments\Attachments\Prompt_Actuals.xls")
        '    'Response.Redirect("http://localhost/LocalPromptProduction/PromptAttachments/Attachments/Prompt_Actuals.xls")
        'End If
        '--------------------------------------------------

        RadGrid1.Visible = True
        RadGrid1.Rebind()
        
        RadGrid1.ExportSettings.ExportOnlyData = True
        RadGrid1.ExportSettings.IgnorePaging = True
        RadGrid1.ExportSettings.OpenInNewWindow = True

        RadGrid1.MasterTableView.ExportToExcel()
        
        Session("RtnFromEdit") = True
        ProcLib.CloseAndRefresh(Page)

    End Sub
    
    Protected Sub RadGrid1_NeedDataSource(ByVal source As Object, ByVal e As Telerik.Web.UI.GridNeedDataSourceEventArgs) Handles RadGrid1.NeedDataSource
        'loads the grid whenever it needs data (sorting, rebinding, etc...)
        Dim dt As DataTable
        Using db As New PromptDataHelper
            If Not e.IsFromDetailTable Then                                     'roy: not sure why this is here ...
                dt = db.ExecuteDataTable("Select task_id,TASK__status_code,rsrc_id,role_id,acct_id,proj_id,task__wbs_name,user_field_131,task__task_name,rsrc__rsrc_name,total_cost,act_cost,delete_record_flag From P6PromptTransferActualExpenses")
                RadGrid1.DataSource = dt
            End If
        End Using
    End Sub

    'Private Sub ReturnExcelFile()
    '    Dim fileName As String = "C:\PromptAttachments\Attachments\Prompt_Actuals.xls"
    '    Dim contents As Byte() = CByte()("hello this is a test")
        
    '    HttpContext.Current.Response.ContentType = "application/octet-stream"
    '    HttpContext.Current.Response.AddHeader("Content-Disposition", "attachment; filename=" + fileName)
    '    HttpContext.Current.Response.Clear()
    '    HttpContext.Current.Response.OutputStream.Write(contents, 0, contents.Length)
    '    HttpContext.Current.Response.End()
    'End Sub
    
    'Private Sub RunRemotePackage()

    '    Dim jobConnection As SqlConnection
    '    Dim jobCommand As SqlCommand
    '    Dim jobReturnValue As SqlParameter
    '    Dim jobParameter As SqlParameter
    '    Dim jobResult As Integer
                
    '    If Proclib.GetLocale() = "Production" Or Proclib.GetLocale() = "Beta" Then   'Beta or Production will use same data exchange location
    '        jobConnection = New SqlConnection(Proclib.GetDataConnectionString())
    '    Else    'localhost -- THIS IS CORRECT FOR ROY'S LAPTOP -- NOT TESTED ANYWHERE ELSE!!!!
    '        jobConnection = New SqlConnection("Data Source=ROY_MAASCO\SQL_ROY;Initial Catalog=msdb;Integrated Security=SSPI")
    '    End If
    '    jobCommand = New SqlCommand("sp_start_job", jobConnection)
    '    jobCommand.CommandType = CommandType.StoredProcedure

    '    jobReturnValue = New SqlParameter("@RETURN_VALUE", SqlDbType.Int)
    '    jobReturnValue.Direction = ParameterDirection.ReturnValue
    '    jobCommand.Parameters.Add(jobReturnValue)

    '    jobParameter = New SqlParameter("@job_name", SqlDbType.VarChar)
    '    jobParameter.Direction = ParameterDirection.Input
    '    jobCommand.Parameters.Add(jobParameter)
    '    jobParameter.Value = "jobP6PrompActualExpensesExchange"

    '    jobConnection.Open()
    '    jobCommand.ExecuteNonQuery()
    '    jobResult = DirectCast(jobCommand.Parameters("@RETURN_VALUE").Value, Integer)
    '    jobConnection.Close()

    '    Select Case jobResult
    '        Case 0
    '            System.Diagnostics.Debug.WriteLine("Package succeeded.")
    '        Case Else
    '            System.Diagnostics.Debug.WriteLine("Package failed.")
    '    End Select
    'End Sub
    
    'Private Sub RunLocalPackage()
    '    'execute the SSIS package which reads the Excel file, extracts the data from Prompt, and creates an output Excel file
    '    'see the following in Help for more information: ms-help://MS.SQLCC.v9/MS.SQLSVR.v9.en/extran9/html/1f92cf61-1f55-4769-895b-af1e56c8df70.htm
    '    ' and: ms-help://MS.SQLCC.v9/MS.SQLSVR.v9.en/dtsref9/html/2f9fc1a8-a001-4c54-8c64-63b443725422.htm
    '    ' and running the package on a remote server: ms-help://MS.SQLCC.v9/MS.SQLSVR.v9.en/dtsref9/html/9f6ef376-3408-46bf-b5fa-fc7b18c689c9.htm
    '    Dim pkgLocation As String
    '    Dim pkg As New Package
    '    Dim app As New Application
    '    Dim pkgResults As DTSExecResult
        
    '    Dim eventListener As New EventListener()

    '    pkgLocation = _
    '      "C:\Documents and Settings\roy\My Documents\Visual Studio 2005\Projects\P6Exchange\Integration Services Project1\New Package.dtsx"
    '    pkg = app.LoadPackage(pkgLocation, eventListener)
    '    pkgResults = pkg.Execute(Nothing, Nothing, eventListener, Nothing, Nothing)
    '    System.Diagnostics.Debug.WriteLine(pkgResults.ToString())
    '    'Console.WriteLine(pkgResults.ToString())
    '    'Console.ReadKey()
    'End Sub
    
    'Class EventListener
    '    Inherits DefaultEvents

    '    Public Overrides Function OnError(ByVal source As Microsoft.SqlServer.Dts.Runtime.DtsObject, _
    '      ByVal errorCode As Integer, ByVal subComponent As String, ByVal description As String, _
    '      ByVal helpFile As String, ByVal helpContext As Integer, _
    '      ByVal idofInterfaceWithError As String) As Boolean

    '        ' Add application–specific diagnostics here.
    '        System.Diagnostics.Debug.WriteLine("Error in " & source.ToString & "/" & subComponent & " : " & description)

    '        'Console.WriteLine("Error in {0}/{1} : {2}", source, subComponent, description)
    '        Return False

    '    End Function

    'End Class

    Protected Sub Button1_Click(ByVal sender As Object, ByVal e As System.EventArgs)
        Response.Redirect("index.aspx?logout=1")
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
                Exchange P6 - Prompt Data
            </td>
            <td class="pageheading" style="height: 11px" align="right">
                <asp:HyperLink ID="butHelp" runat="server" ImageUrl="images/button_help.gif">HyperLink</asp:HyperLink>
            </td>
        </tr>
        <tr>
            <td colspan="2" style="height: 26px">
                <asp:Label ID="Label1" runat="server">Select File:</asp:Label>
            </td>
        </tr>
        <tr>
            <td colspan="2" style="height: 21px">
                &nbsp; &nbsp;
                <telerik:radupload id="RadUpload1" runat="server" style="z-index: 100; left: 8px; top: 54px"
                    controlobjectsvisibility="None" width="500px" enablefileinputskinning="False"
                    height="20px" />
            </td>
        </tr>
        <tr>
            <td colspan="2" style="height: 40px">
                &nbsp;&nbsp;
                <asp:Button ID="butExchangeData" runat="server" OnClick="butExchangeData_Click" Style="z-index: 100;
                    left: 14px; top: 80px;" Text="Exchange P6 Data with Prompt" Width="305px" />
                <asp:Button ID="Button1" runat="server" Style="z-index: 100; left: 447px; top: 78px"
                    Text="Logout" OnClick="Button1_Click" />
            </td>
        </tr>
        <tr>
            <td colspan="2" align="left">
                &nbsp; &nbsp; &nbsp; &nbsp;&nbsp; &nbsp; &nbsp; &nbsp; &nbsp;&nbsp;<br />
                &nbsp;
                <telerik:radgrid id="RadGrid1" runat="server" style="z-index: 46; left: 0px; top: 0px"
                    gridlines="None">
                            <MasterTableView>
                                <RowIndicatorColumn Visible="False">
                                    <HeaderStyle Width="20px" />
                                </RowIndicatorColumn>
                                <ExpandCollapseColumn Resizable="False" Visible="False">
                                    <HeaderStyle Width="20px" />
                                </ExpandCollapseColumn>
                            </MasterTableView>
                        </telerik:radgrid>
            </td>
        </tr>
    </table>
    <telerik:radprogressarea id="RadProgressArea1" runat="server" style="z-index: 100; left: 186px;
        position: absolute; top: 299px;" left="3px" />
    <telerik:radprogressmanager id="RadProgressManager1" runat="server" />
    &nbsp;
    </form>
</body>
</html>
