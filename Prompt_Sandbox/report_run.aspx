<%@ Page Language="vb" %>
<%@ Import Namespace="Prompt" %>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">

<script runat="server">
    
    Private Sub Page_Load(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MyBase.Load
        If Session("UserName") = "" Then   'make sure session has not expired
            ProcLib.CloseAndRefresh(Page)
        End If

        Session("PageID") = "ReportRun"

        'if the report is called from the reports.aspx page, then the querystrings ReportID and NEW are pertinent
        'if the report is called directly from another page in Prompt, then the quertstrings ReportName and DirectCall are pertinent as well as any additional query parameters that are passed
        '           if called directly from another page, the format should be like: 
        '                   .NavigateUrl = "report_run.aspx?DirectCall=y&ReportName=ContractDebug&Dist=" & Session("DistrictID") & "&ContractID=" & nContractID

        Dim nDistrictID As Integer = Session("DistrictID")
        Dim nReportID As Integer = Request.QueryString("ReportID")
        Dim sReportFileName As String = Request.QueryString("ReportName")
        Dim bAltReport As Boolean = IIf(Request.QueryString("NEW") = "y", True, False)
        Dim bDirectCall As Boolean = IIf(Request.QueryString("DirectCall") = "y", True, False)
        
        Dim sLocale As String = ProcLib.GetLocale()

        Using rs As New PromptDataHelper
            'log the request for this report
            rs.ExecuteNonQuery("Insert into ReportUsageLog (ReportFileName, RunWhen, UserName, District) Values ('" & sReportFileName & "',GetDate(),'" & Session("UserName") & "'," & Session("DistrictID") & ")")
            
            If bDirectCall Then 'then this report is called directly from a specific context (i.e. a contract or transaction, etc.)
                Dim newQueryString As String = ""
                For Each key As String In Request.QueryString.AllKeys
                    If key <> "ReportName" And key <> "DirectCall" Then 'strip out the querystring parameters I don't want
                        newQueryString += "&" & key & "=" & Request.QueryString(key)
                    End If
                Next
                
                Select Case sLocale
                    Case "VMBeta", "VMProduction"
                        Response.Redirect("http://216.129.104.72/ReportServer?/PromptReports2008/" & sReportFileName & newQueryString & "&DataSource=" & sLocale)

                    Case "Beta", "Production"
                        Response.Redirect("http://216.129.104.66/q34jf8sfa?/PromptReports/" & sReportFileName & newQueryString & "&DataSource=" & sLocale)
                       
                    Case Else    'local
                        Response.Redirect("http://localhost/PromptReports2008/" & sReportFileName & newQueryString & "&DataSource=" & sLocale)
 
                        
                    
                End Select
                
                
                
            Else 'then this report is called from the reports.aspx page
                sReportFileName = rs.ExecuteScalar("SELECT ReportFileName FROM Reports WHERE IsSSRS = 1 and ReportID=" & nReportID)
            
                Dim url As String = ""
                
                Select Case sLocale
                    'Case "VMBeta", "VMProduction"
                    '    url = "http://216.129.104.72/ReportServer?/" & IIf(bAltReport, "AltReports2008/", "PromptReports2008/")
                    
                    Case "Beta", "Production"
                        url = "http://216.129.104.66/q34jf8sfa?/" & IIf(bAltReport, "BetaReports/", "PromptReports/")
                       
                    Case Else    'local
                        url = "http://localhost/ReportServer?/" & IIf(bAltReport, "AltReports2008/", "PromptReports2008/")
 
                        
                    
                End Select
                
                
                
                Select Case sReportFileName
                    Case "FHDA_Audit_and_Finance_static"
                        'Temporary HACK
                        'THIS MUST BE UPDATED EACH QUARTER (file to be copied to Production and filename to be updated)
                        Response.Redirect("FHDA.Measure.C.Quarterly.Summary.Report.FY0910Q3.FINAL.pdf")
                    Case "FHDA_BudgetCost_ROLLUP_BondyOnlyForCOD"
                        'this passes a hidden parameter to the Budget Cost Rollup Report so that it behaves differently 
                        '       the report name is actually a bogus name that allows us to 
                        sReportFileName = "FHDA_BudgetCost_ROLLUP"
                        If nDistrictID = 56 Then
                            Response.Redirect(url & sReportFileName & "&Dist=" & Session("DistrictID") & "&DataSource=" & sLocale & "&ForCOD_ShowOnlyBondAmountsInColumnsBandC=Yes")
                        End If
                    Case "TransactionDump", _
                        "BudgetDump", _
                        "FHDA_Project_Series"
                        Response.Redirect(url & sReportFileName & "&Dist=" & Session("DistrictID") & "&DataSource=" & sLocale _
                                          & "&rs:Command=Render&rs:Format=Excel&rs:ClearSession=True")
                    Case Else
                        Response.Redirect(url & sReportFileName & "&Dist=" & Session("DistrictID") & "&DataSource=" & sLocale)
                End Select
            End If
        End Using
    End Sub
</script>

<html>
<head>
    <title>report_run</title>
</head>
<body>
    <form id="Form1" method="post" runat="server">
    </form>
</body>
</html>
