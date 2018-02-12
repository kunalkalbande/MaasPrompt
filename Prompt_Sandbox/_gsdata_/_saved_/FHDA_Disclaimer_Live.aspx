<%@ Page Language="VB" %>
<%@ Import Namespace="Prompt" %>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">

<script runat="server">

    Protected Sub Button1_Click(ByVal sender As Object, ByVal e As System.EventArgs)
        Response.Redirect("http://216.129.104.66/q34jf8sfa?/PromptReports/FHDA_Audit_and_Finance&Dist=" & Session("DistrictID") & "&DataSource=" & ProcLib.GetLocale())
    End Sub
</script>

<html xmlns="http://www.w3.org/1999/xhtml" >
<head runat="server">
    <title>Untitled Page</title>
</head>
<body>
    <form id="form1" runat="server">
    <div>
        Note: 
        <br />
        <br />
        This report contains up to the minute data including transactions posted thru the
        moment you run the report.
        It also contains budget transfers made to date.
        <br />
        <br />
        To view data relevant to the CBOC time period only (before close date) please select
        the report called "Audit and Finance Report (STATIC)".<br />
        <br />
        <br />
        <asp:Button ID="Button1" runat="server" OnClick="Button1_Click" Text="Continue to Report" /></div>
    </form>
</body>
</html>
