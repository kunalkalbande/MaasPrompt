<%@ Page Language="vb" %>
<%@ Register Assembly="Microsoft.ReportViewer.WebForms, Version=10.0.0.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a"
    Namespace="Microsoft.Reporting.WebForms" TagPrefix="rsweb" %>

<%@ Import Namespace="Prompt" %>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">

<script runat="server">

 Dim deb As String = ""
    'Notes:
    'There are several considerations when setting up SQL2008 SSRS R2 to work with reports, specifically setting the correct security
    'is a pain to do so that the reports run in all the environments (local/beta/production).

    'Basically, there are two security users to be concerned with:
    'FOR REPORT TO CONNECT TO DATABASE TO GET DATA: maasa or prompt_db_user -- this is located inside the SQL Server and assigned rights specifically to the Prompt and Prompt Beta databases - should have at least RW access. This is set in the credentials tab for the datasources in each report. REQUIRED IF YOU WANT TO USE SUBSCRIPTION (EMAIL REPORT)
    'FOR PROMPT ASP APP TO BE ABLE TO PULL AND RUN THE REPORT IN THE REPORT VIEWER: SSRSReportAdmin -- this is a local windows user on each machine that hosts an SSRS install -- your local development machine and the VMSQL server. This is used by Prompt to access the report, and can also be used when accessing the web base report manager -- this user should have content rights in each SSRS install. No fancy windows rights needed, just needs to be member of the users.

    'Additionally, when installing SSRS2008 R2 on a new machine, just set the NETWORKSERVICE account on each local machine as the access account for all the SQL SERVER services.
    'Known Bugs:
    'Report Manager is weird in Chrome. Does not render report page. Use FF and IE to test in Report Server Browser
    'Deploying report to server does not always update changes made to Parameter Defaults and some others. You sometimes need to check the Paramters and connection info through report server to see what is going on. It caches old values. 
    'To Check Report Properties, click on report breadcrumb at top of page on report name and properties shows. Not intuitive.
    'If you are using shared datasources, and they are stored in a folder (i.e. /Datasources), then this directory and likely the datasources themselves will need to be created on the report server through the Report Manager before any reports using said shared datasources will deploy.


    'How to Configure Report Server:
    'SSRS2008 R2 Express Advanced can be used on local machine for development. This will install Reporting Services Locally. Note: There are some limitations using Report Writer 3 and deploying to this, but there are workarounds I believe. The other limitation is that shared datasources cannot reference an external sql server.
    'The SQLServer2008 R2 instance should be the Defalut Instance for your machine, not a named instance
    'Set up a user in your SQL Server (not windows) called prompt_db_user. pwd is maUbi2008. Give rights to Prompt DBs and Report Server DB's. This is the connection user used in the variable datasource in each report.
    'Create a local machine (windows) user on called SSRSReportAdmin, password Maubi2010. No special permissions needed, just needs to be a user.
    'Log in to your local SSRS Report Manager. You can access the built-in Report manager in SSRS via http://localhost/Reports. Use an Administrator account when prompted (NOT the SSRSReportAdmin user as we have not yet given rights for it; that comes below...)
    'From the main menu of Home page of the Report Manager, click on Folder Settings (not site settings in upper left corner).
    'Click New Role Assignment
    'In Group or User Name text box, type SSRSReportAdmin, and give Content rights and click OK. you should now be able to use this credential when accessing Report Manager in future. This is also the credential that Prompt uses to pull report and change parms. User and pwd are hardcoded in ReportCredentials Class in Prompt, so need to change there if you change on machines. 
    'NOTE: if you have trouble in the future with accessing items in the Report Manager, then log in using an administrator account instead of the SSRSReportAdmin account (i.e. the SSRSReportAdmin a/c is still a limited-rights account).

    'How to Configure Windows Authentication for the Reports Themselves

    'From Enterprise Manager, log in to the server.
    'Add the SSRSReportAdmin user to the Security/Logins for the Server. Make sure to use <MACHINENAME>\SSRSReportAdmin when designating the user if you get error. Give Public server role. Under User Mapping, select the Prompt database (and PromptBeta if necessary) and in the Database role membership for: Prompt area in the bottom, make sure db_datareader and public are checked.
    'Go to the Database (in this case Prompt and/or PromptBeta) and open Security/Users. You will see your newly added user. Make sure it has db_datareader selected as Database Role Membership
    'Finally, open the Reporting Services Configuration Manager.
    'Set up the <MACHINENAME>\SSRSReportAdmin with password Maubi2010 as the Execution Account.
    'Now each report can use a Variable Data Source that uses integrated security, ponts to (local) server, and accepts Parameter for inital catalog (database ie. Prompt or PromptBeta, etc...). The Parm can be passed in the Report Viewer from Prompt. 
    'NOTE: Since you need a defalut value for the Catalog Parm, use Prompt. This will be on every machine. Make sure your local development DB is named Prompt.
    'Adding the RSCustomAssembly to the local (development) Report Server
    'copy the RS_CustomAssembly.dll file from the Prompt project files to C:/Program Files/Microsoft Visual Studio 9.0/Common7/IDE/PrivateAssemblies
    'note: you have to separately make the this file available to the report server on the production server as well (which require separate/different instructions).


    'Office CLip Reports --
    'Changed RDL to use embeded datasource
    'user is sa with pwd Maubi2005
    
    Protected Sub Page_Init(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Init
                
        If Session("UserName") = "" Then   'make sure session has not expired
            ProcLib.CloseAndRefresh(Page)
        End If
        
        lblErrorMessage.Visible = False
        
        ReportViewer1.ProcessingMode = ProcessingMode.Remote
        Dim serverReport As ServerReport
        serverReport = ReportViewer1.ServerReport

        'if the report is called from the reports.aspx page, then the querystrings ReportID and NEW are pertinent
        'if the report is called directly from another page in Prompt, then the quertstring DirectCall is pertinent as well as any additional query parameters that are passed
        '           if called directly from another page, the format should be like this: 
        '                   .NavigateUrl = "report_viewer.aspx?DirectCall=y&ReportID=172&G_Projects=100&bShowAllObjectCodes=true"

        Dim nDistrictID As Integer = Session("DistrictID")
        Dim nReportID As Integer = Request.QueryString("ReportID")
        Dim nRFIID As Integer = Request.QueryString("RFIID")
        Dim nProjectID As Integer = Request.QueryString("ProjectID")
        Dim sReportDirectory As String = ""
        Dim sFullReportPath As String = ""
        Dim sReportFileName As String
        Dim sReportTitle As String = ""
        Dim bAltReport As Boolean = IIf(Request.QueryString("NEW") = "y", True, False)
        sReportDirectory = IIf(bAltReport, "AltReports", "PromptReports")
        Dim bDirectCall As Boolean = IIf(Request.QueryString("DirectCall") = "y", True, False)
        
        Using db As New PromptDataHelper
                         
            'get report name for title
            Dim tbl As DataTable = db.ExecuteDataTable("SELECT * FROM Reports WHERE ReportID=" & nReportID)
            sReportFileName = tbl.Rows(0)("ReportFileName")
            sReportTitle = tbl.Rows(0)("ReportTitle")
            
            If Session("UsePromptName") = 1 Then
                Page.Title = "Prompt " & sReportTitle
            Else
                Page.Title = "EISPro " & sReportTitle
            End If
            
            'log the request for this report
            'db.ExecuteNonQuery("Insert into ReportUsageLog (ReportFileName, RunWhen, UserName, District) Values ('" & sReportFileName & "','" & Now() & "','" & Session("UserName") & "'," & Session("DistrictID") & ")")
        End Using
        
        'Set the location of report server based on locale
        
        Dim sLocale As String = ProcLib.GetLocale()
        Dim sReportServerURL As String = ""
        Dim sDataSource As String = ""
        
		 If sLocale = "Local" Then
            'sReportServerURL = "http://localhost/ReportServer"
            sReportServerURL = "http://204.13.83.246/ReportServer"
            sDataSource = "NOCCCD_DEV"
        ElseIf sLocale.Contains("Beta") Then
            sReportServerURL = "http://204.13.83.246/ReportServer"
            sDataSource = "NOCCCD-DEV"
        Else   'production
            sReportServerURL = "http://204.13.83.246/ReportServer"
            sDataSource = "COD"
        End If
        
        'If sLocale = "COD" Then
         '   sReportServerURL = "http://localhost/ReportServer"
          '  sDataSource = "Prompt"
        'ElseIf sLocale.Contains("Beta") Then
          '  sReportServerURL = "http://204.13.83.246/ReportServer"
           ' sDataSource = "PromptBeta"
        'Else   'production
         '   sReportServerURL = "http://204.13.83.246/ReportServer"
          '  sDataSource = "Prompt"
        'End If
        
        'create help hyperlink
        'Notes:
        '
        '   to create documentation for a new report (or create documentation for a report that does not currently have documentation,
        '   Simply open the report; then click on the Help link in the top left corner of the screen; this opens the Help window; Within the Help window, 
        '       click on the Edit Help Text link
        '
        '   also note that this help implementation does not use the RadWindowPopups structure that is used in the rest of Prompt.
        '       this is because as is currently implemented, the Report Viewer window does not show the usual Prompt header with the usual link at the top (i.e. Report, Help, etc.)
        
        getHelp.OnClientClick = "return getReportHelpPopup(" & nReportID & ")"
        
        Dim url As String = ""
        Dim bAddExtraParm As Boolean = False
        Dim parmExtra As New Microsoft.Reporting.WebForms.ReportParameter()   'for occasional extra parm
            
        Select Case sReportFileName
            Case "FHDA_Audit_and_Finance_static"
                'Temporary HACK
                'THIS MUST BE UPDATED EACH QUARTER (file to be copied to Production and filename to be updated)
                Response.Redirect("FHDA.Measure.C.Quarterly.Summary.Report.FY0910Q3.FINAL.pdf")
                
                'Case "FHDA_BudgetCost_ROLLUP_BondyOnlyForCOD"
                '    'this passes a hidden parameter to the Budget Cost Rollup Report so that it behaves differently 
                '    '       the report name is actually a bogus name that allows us to 
                '    sReportFileName = "FHDA_BudgetCost_ROLLUP"
                '    If nDistrictID = 56 Then
                '        parmExtra.Name = "ForCOD_ShowOnlyBondAmountsInColumnsBandC"
                '        parmExtra.Values.Add("Yes")
                '        bAddExtraParm = True

                '        'sFullReportPath = "/" & sReportDirectory & "/" & sReportFileName & "&Dist=" & Session("DistrictID") & "&DataSource=" & sLocale & "&ForCOD_ShowOnlyBondAmountsInColumnsBandC=Yes"
                '        sFullReportPath = "/" & sReportDirectory & "/" & sReportFileName
                '    End If
                
                
                'NOTE -- For now we need to make user export instead of directly doing it due to no anaymous user in SSRSR2 -- authentication pain.
                'Case "TransactionDump", "BudgetDump", "FHDA_Project_Series"      'Need Redirects here to render direclty in Excel
                '    'sFullReportPath = "/" & sReportDirectory & "/" & sReportFileName & "&Dist=" & Session("DistrictID") & "&DataSource=" & sLocale & "&rs:Command=Render&rs:Format=Excel&rs:ClearSession=True"

                '    Dim sExportURL As String = sReportServerURL & "?/PromptReports/" & sReportFileName & "&Dist=" & Session("DistrictID") & "&DataSource=Prompt&rs:Command=Render&rs:Format=Excel&rs:ClearSession=True"

                '    Response.Redirect(sExportURL)

            Case Else
                sFullReportPath = "/" & sReportDirectory & "/" & sReportFileName
            
        End Select

           
        Try
            Dim parmRFIID As New Microsoft.Reporting.WebForms.ReportParameter()

            If nRFIID > 0 Then               
                parmRFIID.Name = "RFIID"
                parmRFIID.Values.Add(nRFIID)
            End If
            
            Dim parmProjectID As New Microsoft.Reporting.WebForms.ReportParameter()
            If nProjectID > 0 Then
                parmProjectID.Name = "ProjectID"
                parmProjectID.Values.Add(nProjectID)
            End If
            
            Dim parmDistrictID As New Microsoft.Reporting.WebForms.ReportParameter()
            parmDistrictID.Name = "Dist"
            parmDistrictID.Values.Add(nDistrictID)

            Dim parmDatasource As New Microsoft.Reporting.WebForms.ReportParameter()
            parmDatasource.Name = "DataSource"
            parmDatasource.Values.Add(sDataSource)
                    
            With serverReport
                .ReportServerCredentials = New ReportServerCredentials()    'set using the credential class -- user and pwd are hard coded
                .ReportServerUrl = New Uri(sReportServerURL)
                .ReportPath = sFullReportPath
                .SetParameters(New Microsoft.Reporting.WebForms.ReportParameter() {parmDistrictID})
                .SetParameters(New Microsoft.Reporting.WebForms.ReportParameter() {parmDatasource})
            
                If nRFIID > 0 Then
                    .SetParameters(New Microsoft.Reporting.WebForms.ReportParameter() {parmRFIID})
                End If
                If nProjectID > 0 Then
                    .SetParameters(New Microsoft.Reporting.WebForms.ReportParameter() {parmProjectID})
                End If
                    
                If bDirectCall Then 'then this report is called directly from a specific context (i.e. a contract or transaction, etc.), so include any additional parameters
                    For Each key As String In Request.QueryString.AllKeys
                        If key <> "DirectCall" And key <> "ReportID" Then 'strip out the querystring parameters I don't want
                            Dim xtraParam As New Microsoft.Reporting.WebForms.ReportParameter()
                            xtraParam.Name = key
                            xtraParam.Values.Add(Request.QueryString(key))
                            .SetParameters(New Microsoft.Reporting.WebForms.ReportParameter() {xtraParam})
                        End If
                    Next
                        
                    Dim bytes As Byte()
                    bytes = ReportViewer1.ServerReport.Render("PDF", Nothing, Nothing, Nothing, Nothing, Nothing, Nothing)
                    Response.ContentType = "Application/pdf"
                    Response.BinaryWrite(bytes)
                    Response.End()
                End If
            End With
        
        Catch ex As Exception

        deb &= ex.Message & "<br>"
            lblErrorMessage.Visible = True
            ReportViewer1.Visible = False
            Dim sMsg As String = "<br /><br />&nbsp;&nbsp;&nbsp;"   'prefix with padding and line breaks

            sMsg &= sFullReportPath & "<br /><br />&nbsp;&nbsp;&nbsp;"

            If ex.Message.Contains("rsItemNotFound") Then
                sMsg &= "The Report was not found."
            Else
                sMsg &= ex.Message
            End If

            lblErrorMessage.Text = sMsg

        End Try
       

        
        
        'OLD CODE THAT WORKED LOCALLY FOR REFERENCE
        'ReportViewer1.ProcessingMode = ProcessingMode.Remote
        'Dim serverReport As ServerReport
        'serverReport = ReportViewer1.ServerReport


        'serverReport.ReportPath = "/PromptReports/ContractorListByDistrict"
        ''Page.Title = "Prompt Company List"

        ''Create the report parameter
        'Dim districtid As New Microsoft.Reporting.WebForms.ReportParameter()
        'districtid.Name = "Dist"
        'districtid.Values.Add(Session("DistrictID"))

        'Dim datasource As New Microsoft.Reporting.WebForms.ReportParameter()
        'datasource.Name = "DataSource"
        'Select Case ProcLib.GetLocale

        '    Case "Production"
        '        datasource.Values.Add("Production")
        '    Case "Beta"
        '        datasource.Values.Add("Beta")
        '    Case "VMBeta"
        '        datasource.Values.Add("VMBeta")
        '        serverReport.ReportServerUrl = New Uri("http://216.129.104.72/ReportServer")

        '    Case Else
        '        datasource.Values.Add("Local")
        '        serverReport.ReportServerUrl = New Uri("http://localhost/ReportServer")

        'End Select

        'serverReport.SetParameters(New Microsoft.Reporting.WebForms.ReportParameter() {districtid})
        'serverReport.SetParameters(New Microsoft.Reporting.WebForms.ReportParameter() {datasource})
        
  
    End Sub
    
    'Protected Sub ProcessSubReport(ByVal sender As Object, ByVal e As SubreportProcessingEventArgs)


    '    Dim pProj As String
    '    For Each p As ReportParameterInfo In e.Parameters
    '        If p.Name = "ID" Then
    '            pProj = p.Values(0)
    '        End If
    '    Next

    '    Dim sql As String = ""
    '    sql += "Select ProjectNumber + Coalesce(ProjectSubNumber,'') as ProjectNumber, N.CreatedOn, N.Description  "
    '    sql += "From Notes N join Projects P on N.ProjectID = P.ProjectID  "
    '    sql += "Where P.ProjectID  = " & pProj & " "
    '    sql += "    and TransactionID = 0 AND ContractID = 0 AND N.CollegeID = 0 AND ContractorID = 0 AND LedgerAccountID = 0 AND DetailID = 0   "
    '    sql += "Order By ProjectNumber Asc, N.CreatedOn Desc         "

    '    Using db As New PromptDataHelper
    '        Dim tbl As DataTable = db.ExecuteDataTable(sql)
    '        e.DataSources.Add(New ReportDataSource("GetNotes", tbl))

    '    End Using

    'End Sub
    
    'Protected Sub ReportViewer1_Drillthrough(ByVal sender As Object, ByVal e As DrillthroughEventArgs)
    '    Dim drillThruReport As LocalReport = e.Report

    '    'get the parameters for use in the SQL for filtering
    '    Dim pDist, pProj, pOC As String

    '    For Each rparam As ReportParameterInfo In drillThruReport.GetParameters
    '        Select Case rparam.Name
    '            Case "Dist"
    '                pDist = rparam.Values(0)
    '            Case "ProjID"
    '                pProj = rparam.Values(0)
    '            Case "ObCode"
    '                pOC = rparam.Values(0)
    '            Case Else
    '                'ignore other parameters
    '        End Select
    '    Next
        
        
        
    'Using db1 As New PromptDataHelper
    '    Dim sql As String = ""
    '    Dim tbl As DataTable

    '    sql += "Declare @ProjID int; Set @ProjID = " & pProj & " "
    '    sql += "Declare @ObCode varchar(25); Set @ObCode = '" & pOC & "' "
    '    sql += " "
    '    sql += "Select CT.Name as Contractor, C.Description as Contract, CLI.Amount as EncumberedAmount,  "
    '    sql += "	Case When CLI.LineType in ('Contract','Adjustment') Then C.Status  "
    '    sql += "		Else  "
    '    sql += "		(Select Case When IsDate(CD.DistrictApprovalDate) = 1 Then 'Approved'  "
    '    sql += "			Else 'Pending' End From ContractDetail CD Where CD.ContractDetailID = CLI.ContractChangeOrderID) End  "
    '    sql += "		as Status, "
    '    sql += "	CLI.Reimbursable as Reimb, CLI.LineType as Type "
    '    sql += "From ContractLineItems CLI "
    '    sql += "	join Contracts C on CLI.ContractID = C.ContractID "
    '    sql += "	join Contractors CT on CT.ContractorID = C.ContractorID "
    '    sql += "Where CLI.ProjectID = @ProjID and CLI.ObjectCode = @ObCode "
    '    sql += "	and C.Status in ('1-Open', '2-Closed') "
    '    sql += "Order By Status, Contractor, Contract, Type Desc             "
    '    tbl = db1.ExecuteDataTable(sql)

    '    Dim dsGetContracts As New ReportDataSource()
    '    dsGetContracts.Name = "GetContracts"
    '    dsGetContracts.Value = tbl
    '    drillThruReport.DataSources.Add(dsGetContracts)
            
    'sql = ""
    'sql += "Declare @Dist int; Set @Dist = " & pDist & " "
    'sql += "Declare @ProjID int; Set @ProjID = " & pProj & " "
    'sql += "Declare @ObCode varchar(25); Set @ObCode = '" & pOC & "' "
    'sql += " "
    'sql += "Select "
    'sql += "(Select ObjectCodeDescription From ObjectCodes Where DistrictID = @Dist and ObjectCode = @ObCode) as ObCodeDesc, "
    'sql += "(Select ProjectNumber + Coalesce(ProjectSubNumber,'') + '-' + ProjectName From Projects Where ProjectID = @ProjID) as ProjectDescription             "
    'tbl = db1.ExecuteDataTable(sql)

    'Dim dsGetProjectObjectCodeDescription As New ReportDataSource()
    'dsGetProjectObjectCodeDescription.Name = "GetProjectObjectCodeDescription"
    'dsGetProjectObjectCodeDescription.Value = tbl
    'drillThruReport.DataSources.Add(dsGetProjectObjectCodeDescription)


    ''Set the processing mode for the ReportViewer to Local
    'ReportViewer1.ProcessingMode = ProcessingMode.Local

    'sql = ""
    'sql += "Declare @Dist int; Set @Dist = " & pDist & " "
    'sql += "Declare @ProjID int; Set @ProjID = " & pProj & " "
    'sql += "Declare @ObCode varchar(25); Set @ObCode = '" & pOC & "' "
    'sql += " "
    'sql += "Select JCAFColumnName, Amount, Coalesce(LA.Description,'') as Ledger "
    'sql += "From BudgetObjectCodes BOC join Projects P on P.ProjectID = BOC.ProjectID "
    'sql += "	LEFT OUTER join LedgerAccounts LA on BOC.LedgerAccountID = LA.LedgerAccountID "
    'sql += "Where BOC.ProjectID = @ProjID and ObjectCode = @ObCode             "
    'tbl = db1.ExecuteDataTable(sql)

    'Dim localReport As LocalReport
    'localReport = ReportViewer1.LocalReport

    'Dim dsGetJCAFLines As New ReportDataSource()
    'dsGetJCAFLines.Name = "GetJCAFLines"
    'dsGetJCAFLines.Value = tbl
    'drillThruReport.DataSources.Add(dsGetJCAFLines)

    'sql = ""
    'sql += "Declare @Dist int; Set @Dist = " & pDist & " "
    'sql += "Declare @ProjID int; Set @ProjID = " & pProj & " "
    'sql += "Declare @ObCode varchar(25); Set @ObCode = '" & pOC & "' "
    'sql += " "
    'sql += "Select CON.Name as Contractor, Ct.Description as Contract, T.Description as TransDesc, "
    'sql += "	TDE.Amount, T.TransType, T.Status as TransStatus, "
    'sql += "	Case When (Select count(*) From TransactionDetail TD Where TD.TransactionID = TDE.TransactionID) > 1 Then 'Y' Else '' End as SplitTrans "
    'sql += "From qry_TransactionDetail_Ext TDE "
    'sql += "	join Transactions T on TDE.TransactionID = T.TransactionID  "
    'sql += "	join Projects P on T.ProjectID = P.ProjectID "
    'sql += "	join Contracts Ct on T.ContractID = Ct.ContractID "
    'sql += "	join Contractors CON on Ct.ContractorID = CON.ContractorID "
    'sql += "Where TDE.ProjectID = @ProjID and TDE.ObjectCode = @ObCode and TDE.Status = 'Paid'             "
    'tbl = db1.ExecuteDataTable(sql)
            
        
    'Dim dsGetTransactions As New ReportDataSource()
    'dsGetTransactions.Name = "GetTransactions"
    'dsGetTransactions.Value = tbl
    'drillThruReport.DataSources.Add(dsGetTransactions)

    'sql = ""
    'sql += "Declare @Dist int; Set @Dist = " & pDist & " "
    'sql += "Declare @ProjID int; Set @ProjID = " & pProj & " "
    'sql += "Declare @ObCode varchar(25); Set @ObCode = '" & pOC & "' "
    'sql += " "
    'sql += "Select Description, Amount From PassThroughEntries Where ProjectID = @ProjID and ObjectCode = @ObCode             "
    'tbl = db1.ExecuteDataTable(sql)

    'Dim dsGetPassthruOverhead As New ReportDataSource()
    'dsGetPassthruOverhead.Name = "GetPassthruOverhead"
    'dsGetPassthruOverhead.Value = tbl
    'drillThruReport.DataSources.Add(dsGetPassthruOverhead)

    'Dim dsfoo As New ReportDataSource()
    'dsfoo.Name = "foo"
    'dsfoo.Value = tbl
    'drillThruReport.DataSources.Add(dsfoo)
            
    ''set up parameters for Drillthrough report
    'Dim rp1 As New ReportParameter("DataSource", "Production", True)
    'Dim rp2 As New ReportParameter("Dist", "55", True)
    'Dim rp3 As New ReportParameter("ProjID", "450", True)
    'Dim rp4 As New ReportParameter("ObCode", "5200", True)

    'localReport.ReportPath = "Reports/ContractorListByDistrict.rdlc"

    'Dim params(3) As ReportParameter
    'params(0) = rp1
    'params(1) = rp2
    'params(2) = rp3
    'params(3) = rp4

    'Using db As New PromptDataHelper

    'drillThruReport.SetParameters(params)



    '    Dim tbl As DataTable = db.ExecuteDataTable("Select Name as Contractor, cType as Type, Keywords, Comments From Contractors Where DistrictID = 56 Order By Contractor")
    '    'Create a report data source for the sales order data
    '    Dim dsSalesOrder As New ReportDataSource()
    '    dsSalesOrder.Name = "GetContractors"
    '    dsSalesOrder.Value = tbl

    '    localReport.DataSources.Add(dsSalesOrder)


    '    ''Create a report parameter for the sales order number 
    '    'Dim rpSalesOrderNumber As New ReportParameter()
    '    'rpSalesOrderNumber.Name = "Dist"
    '    'rpSalesOrderNumber.Values.Add(56)

    '    ''Set the report parameters for the report
    '    'Dim parameters() As ReportParameter = {rpSalesOrderNumber}
    '    'localReport.SetParameters(parameters)




    'End Using
            
            

    'Dim dataset As New DataSet("Sales Order Detail")

    'End Using
    'End Sub
    
 
    
    'Protected Sub GetData()
    '    'Set the processing mode for the ReportViewer to Local
    '    ReportViewer1.ProcessingMode = ProcessingMode.Local

    '    Dim localReport As LocalReport
    '    localReport = ReportViewer1.LocalReport

    '    localReport.ReportPath = "Reports/ExperimentalBCR.rdlc"

    '    AddHandler localReport.SubreportProcessing, AddressOf ProcessSubReport

    '    'clear existing datasources (i.e. for refresh)
    '    localReport.DataSources.Clear()


    '    Select Case localReport.ReportPath

    '        Case "Reports/Contracts_List.rdlc"
    '            Using db As New PromptDataHelper

    '                Dim sql As String
    '                sql = "Declare @Dist int; Set @Dist = 55; "
    '                sql += "Select ProjectNumber + Coalesce(ProjectSubNumber,'') as ProjNum, ProjectName, "
    '                sql += "	CT.Name as Contractor, ContractDate, C.Description as Contract, "
    '                sql += "	(Select IsNull(Sum(Amount),0) From ContractLineItems CLI Where CLI.ContractID = C.ContractID and CLI.LineType = 'Contract' and Reimbursable = 0) as ContractAmount, "
    '                sql += "	Substring(C.Status,3,99) as ContractStatus, BlanketPONumber as POnum "
    '                sql += "From Contracts C "
    '                sql += "	join Projects P on C.ProjectID = P.ProjectID "
    '                sql += "	join Contractors CT on C.ContractorID = CT.ContractorID "
    '                sql += "Where C.DistrictID = @Dist "
    '                sql += "Order By ProjNum, ProjectName, Contractor, Contract, ContractStatus "
    '                Dim tbl As DataTable = db.ExecuteDataTable(sql)

    '                'Create a report data source
    '                Dim dsGetContracts As New ReportDataSource()
    '                dsGetContracts.Name = "GetContracts"
    '                dsGetContracts.Value = tbl
    '                localReport.DataSources.Add(dsGetContracts)

    '                'Create second data source
    '                Dim dsFoo As New ReportDataSource()
    '                dsFoo.Name = "foo"
    '                dsFoo.Value = tbl                   'fake it out by using the same data as above datasource (i.e. we don;t actuallly need the foo data
    '                localReport.DataSources.Add(dsFoo)
    '            End Using

    '        Case "Reports/ExperimentalBCR.rdlc"

    '            'Create a report parameters 
    '            Dim rpDataSource As New ReportParameter("DataSource", "Production")
    '            Dim rpDist As New ReportParameter("Dist", "55", True)
    '            Dim rpCollege As New ReportParameter("College", "_District", True)
    '            Dim rpG_Projects As New ReportParameter("G_Projects", "101", True)

    '            Dim parameters() As ReportParameter = {rpDataSource, rpCollege, rpDist, rpG_Projects, _
    '                New ReportParameter("bShowProjectsGrouped", True, True)}
    '            localReport.SetParameters(parameters)

    '            Using db As New PromptDataHelper

    '                Dim sql As String

    '                sql = "Declare @Dist int; Set @dist = 55; Declare @ProjNums varchar(100); Set @ProjNums = '" & txtProjectNumber.Text & "' "

    '                sql += ";With q as (  "
    '                sql += "	Select Projects.DistrictID, Projects.ProjectID, ProjectGroupID,  "
    '                sql += "		Case When Coalesce(Projects.ProjectGroupID,0) = 0 Then 1000000+Projects.ProjectID Else Projects.ProjectGroupID End as CreatedGroupID,  "
    '                sql += "		ProjectNumber+Coalesce(ProjectSubNumber,'') as ProjNum, ProjectName,  "
    '                sql += "		Case When Coalesce(Projects.ProjectGroupID,0) <> 0   "
    '                sql += "			Then (Select Name From ProjectGroups PG Where PG.ProjectGroupID = Projects.ProjectGroupID)  "
    '                sql += "			Else ProjectName End as CreatedGroupName,  "
    '                sql += "		Case When Coalesce(Projects.ProjectGroupID,0) <> 0  "
    '                sql += "			Then (Select ProjectNumber From ProjectGroups PG Where PG.ProjectGroupID = Projects.ProjectGroupID)  "
    '                sql += "			Else ProjectNumber+Coalesce(ProjectSubNumber,'') End as CreatedGroupNumber,  "
    '                sql += "  "
    '                sql += "		C.College, C.CollegeID, Projects.Status, Projects.Description, Location, ObjectCodes.ObjectCode, ObjectCodeDescription, ObjectCodeGroup, BOCE.Notes as ObjectCodeNotes,   "
    '                sql += "  "
    '                sql += "	(Select IsNull(Sum(Amount),0) From BudgetObjectCodes Where ProjectID = Projects.ProjectID and ObjectCode = ObjectCodes.ObjectCode and PatIndex ('%bond%', JCAFColumnName) > 0) as BondTotal,  "
    '                sql += "	(Select IsNull(Sum(Amount),0) From BudgetObjectCodes Where ProjectID = Projects.ProjectID and ObjectCode = ObjectCodes.ObjectCode and PatIndex ('%SF%', JCAFColumnName) > 0) as SFTotal,  "
    '                sql += "	(Select IsNull(Sum(Amount),0) From BudgetObjectCodes Where ProjectID = Projects.ProjectID and ObjectCode = ObjectCodes.ObjectCode and PatIndex ('%Maint%', JCAFColumnName) > 0) as MaintTotal,  "
    '                sql += "	(Select IsNull(Sum(Amount),0) From BudgetObjectCodes Where ProjectID = Projects.ProjectID and ObjectCode = ObjectCodes.ObjectCode and PatIndex ('%Donation%', JCAFColumnName) > 0) as DonationTotal,  "
    '                sql += "	(Select IsNull(Sum(Amount),0) From BudgetObjectCodes Where ProjectID = Projects.ProjectID and ObjectCode = ObjectCodes.ObjectCode and PatIndex ('%Hazmat%', JCAFColumnName) > 0) as HazMatTotal,  "
    '                sql += "	(Select IsNull(Sum(Amount),0) From BudgetObjectCodes Where ProjectID = Projects.ProjectID and ObjectCode = ObjectCodes.ObjectCode and PatIndex ('%Grant%', JCAFColumnName) > 0) as GrantTotal,  "
    '                sql += "  "
    '                sql += "	/* ErrorTotal is to catch unexpected errors in JCAFColumnName */  "
    '                sql += "	(Select IsNull(Sum(Amount),0) From BudgetObjectCodes Where ProjectID = Projects.ProjectID and ObjectCode = ObjectCodes.ObjectCode and   "
    '                sql += "		not (PatIndex ('%bond%', JCAFColumnName) > 0 or PatIndex ('%SF%', JCAFColumnName) > 0 or PatIndex ('%Maint%', JCAFColumnName) > 0  "
    '                sql += "			or PatIndex ('%Donation%', JCAFColumnName) > 0 or PatIndex ('%Hazmat%', JCAFColumnName) > 0 or PatIndex ('%Grant%', JCAFColumnName) > 0)) as ErrorTotal,  "
    '                sql += "  "
    '                sql += "	(Select IsNull(Sum(Amount),0) From BudgetObjectCodes Where ProjectID = Projects.ProjectID and ObjectCode = ObjectCodes.ObjectCode) as BudgetTotals,  "
    '                sql += "  "
    '                sql += "	IsNull((Select IsNull(Sum(Amount),0) From qry_TransactionDetail_Ext QTE Where QTE.ProjectID = Projects.ProjectID and QTE.ObjectCode = ObjectCodes.ObjectCode and QTE.Status = 'Paid'),0)   "
    '                sql += "	+ IsNull((Select IsNull(Sum(Amount),0) From PassThroughEntries Where ProjectID = Projects.ProjectID and ObjectCode = ObjectCodes.ObjectCode),0) as CostsToDate,  "
    '                sql += "  "
    '                sql += "	IsNull(  "
    '                sql += "		  IsNull((Select  IsNull(Sum(CLI.Amount),0) From ContractLineItems CLI join Contracts C on CLI.ContractID = C.ContractID   "
    '                sql += "			Where CLI.ProjectID = Projects.ProjectID and CLI.ObjectCode = ObjectCodes.ObjectCode and C.Status in ('1-Open', '2-Closed') and CLI.LineType in ('Contract','Adjustment')),0)  "
    '                sql += "		+ IsNull ((Select IsNull(Sum(CD.Amount),0) From ContractDetail CD join Contracts C on CD.ContractID = C.ContractID join ContractLineItems CLI on CLI.ContractChangeOrderID = CD.ContractDetailID  "
    '                sql += "			Where CD.ProjectID = Projects.ProjectID and CLI.ObjectCode = ObjectCodes.ObjectCode and C.Status in ('1-Open', '2-Closed') and CD.DistrictApprovalDate IS NOT NULL), 0)  "
    '                sql += "		- IsNull ((Select IsNull(Sum(Amount),0) From qry_TransactionDetail_Ext QTE Where QTE.ProjectID = Projects.ProjectID and QTE.ObjectCode = ObjectCodes.ObjectCode and QTE.Status = 'Paid'),0)  "
    '                sql += "		,0) as Encumbered,   "
    '                sql += "  "
    '                sql += "	IsNull(  "
    '                sql += "		  IsNull((Select IsNull(Sum(PendingExpenses),0) From BudgetObjectCodeEstimates Where ProjectID = Projects.ProjectID and ObjectCode = ObjectCodes.ObjectCode),0)  "
    '                sql += "		+ IsNull((Select IsNull(Sum(CLI.Amount),0) From ContractLineItems CLI join Contracts C on CLI.ContractID = C.ContractID   "
    '                sql += "			Where CLI.ProjectID = Projects.ProjectID and CLI.ObjectCode = ObjectCodes.ObjectCode and C.Status = '3-Pending' and CLI.LineType in ('Contract','Adjustment')),0)  "
    '                sql += "		+ IsNull((Select IsNull(Sum(CD.Amount),0) From ContractDetail CD join Contracts C on CD.ContractID = C.ContractID join ContractLineItems CLI on CLI.ContractChangeOrderID = CD.ContractDetailID  "
    '                sql += "			Where CD.ProjectID = Projects.ProjectID and CLI.ObjectCode = ObjectCodes.ObjectCode and CD.DistrictApprovalDate is Null),0)   "
    '                sql += "		,0) as PendingApprox,  "
    '                sql += "  "
    '                sql += "	IsNull((Select IsNull(Sum(EstimateToComplete),0) From BudgetObjectCodeEstimates Where ProjectID = Projects.ProjectID and ObjectCode = ObjectCodes.ObjectCode),0) as EstToComplete  "
    '                sql += "   "
    '                sql += "From Projects  "
    '                sql += "	join Districts on Projects.DistrictID = Districts.DistrictID  "
    '                sql += "	RIGHT OUTER join ObjectCodes on Districts.DistrictID = ObjectCodes.DistrictID  "
    '                sql += "	join Colleges C on Projects.CollegeID = C.CollegeID  "
    '                sql += "	LEFT OUTER join BudgetObjectCodeEstimates BOCE on BOCE.ProjectID = Projects.ProjectID and BOCE.ObjectCode = ObjectCodes.ObjectCode  "
    '                sql += "Where Projects.DistrictID = @Dist  "
    '                sql += " /*	Order By ProjectGroupID Desc */  "
    '                sql += ")   "
    '                sql += "Select DistrictID, College, CollegeID, ProjNum, ProjectName, ObjectCode, ObjectCodeDescription, ObjectCodeGroup,   "
    '                sql += "	BondTotal, SFTotal, MaintTotal, DonationTotal,  "
    '                sql += "	HazMatTotal, GrantTotal, ErrorTotal, BudgetTotals,  "
    '                sql += "	CostsToDate, Encumbered, PendingApprox, EstToComplete,  "
    '                sql += "	Description, Status, Location, 'P' as ProjType, ProjectID as ID,  "
    '                sql += "	ObjectCodeNotes  "
    '                sql += "From q  "
    '                sql += "Where ProjNum in (@ProjNums)  "
    '                sql += "Order By ProjNum, ObjectCode  "

    '                Dim tbl As DataTable = db.ExecuteDataTable(sql)

    '                'Create a report data source for the sales order data
    '                Dim dsGetProjectsByDistrict As New ReportDataSource()
    '                dsGetProjectsByDistrict.Name = "GetProjectsByDistrict"
    '                dsGetProjectsByDistrict.Value = tbl
    '                localReport.DataSources.Add(dsGetProjectsByDistrict)

    '                Dim dsGetJCAFColumnHeadings As New ReportDataSource()
    '                dsGetJCAFColumnHeadings.Name = "GetJCAFColumnHeadings"
    '                dsGetJCAFColumnHeadings.Value = tbl
    '                localReport.DataSources.Add(dsGetJCAFColumnHeadings)

    '                Dim dsGetReportData As New ReportDataSource()
    '                dsGetReportData.Name = "GetReportData"
    '                dsGetReportData.Value = tbl
    '                localReport.DataSources.Add(dsGetReportData)

    '                Dim dsFoo As New ReportDataSource()
    '                dsFoo.Name = "foo"
    '                dsFoo.Value = tbl
    '                localReport.DataSources.Add(dsFoo)

    '            End Using
    '        Case Else


    '    End Select
    '    localReport.Refresh()


    'End Sub

    'Protected Sub butRefresh_Click(ByVal sender As Object, ByVal e As System.EventArgs)
    '    GetData()
    'End Sub
</script>

<html>
<head runat="server">
    <title >Report Viewer</title>
    <link href="Styles.css" type="text/css" rel="stylesheet" />
    <link rel="icon" type="image/png" href="images/home.png" />
    
    <script type="text/javascript">
        function getReportHelpPopup(reportID) {
            //alert(reportID);
            window.open("help_view.aspx?PageID=HelpReportID_" + reportID, "rep_help", "target=new height=500, width=500,status= no, resizable= yes, scrollbars=no, toolbar=no,location=no,menubar=no");
        }
    </script>
</head>
<body>

<div>
<%=deb%>
</div>
    <form id="Form1" method="post" runat="server">
    <asp:ScriptManager ID="ScriptManager1" runat="server"> </asp:ScriptManager>
<%--    <br />
    Project Number: 
    <asp:TextBox ID="txtProjectNumber" runat="server"></asp:TextBox>
    <asp:Button ID="butRefresh" runat="server" Text="Refresh Report" 
        onclick="butRefresh_Click" />   --%>
  <%--  <rsweb:ReportViewer ID="ReportViewer1" runat="server"  OnDrillthrough="ReportViewer1_Drillthrough" 
        Font-Names="Verdana" Font-Size="8pt" Height="700px" Width="100%">
    </rsweb:ReportViewer>--%>
    <asp:LinkButton ID="getHelp" Text="Help" runat="server" ToolTip="Get Help/Documentation for this report" />
    <asp:Label ID="lblErrorMessage" runat="server" ForeColor="Red" Font-Bold="True" Text="" />
       <rsweb:ReportViewer ID="ReportViewer1" runat="server" Font-Names="Verdana" Font-Size="8pt" Height="850px" SizeToReportContent="False" Width="100%" />
   
 <%--   <asp:ObjectDataSource ID="ObjectDataSource1" runat="server">
    </asp:ObjectDataSource>--%>
     
    </form>
</body>
</html>
