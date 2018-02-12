<%@ Page Language="VB" %>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">

<script runat="server">

    Protected Sub Button1_Click(ByVal sender As Object, ByVal e As System.EventArgs)
        Response.Redirect("http://216.129.104.66/q34jf8sfa?/PromptReports/FHDA_Audit_and_Finance_static")
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
        This report contains data relevant to the most recent CBOC period only. To
        avoid showing an transactions posted past the close date, a parallel database has
        been created upon which this report draws from. Hence, it is not live. Please look
        at the date/time listed in the top right hand corner of this report to see when
        the last update took place.
        <br />
        <br />
        Currently this report shows data for the 3rd quarter of FY2009-2010 (thru March 31, 2010).
        <br />
        <br />
        To view the latest data in Prompt (including past the close date) please select
        the report called "Audit and Finance Report (LIVE)".<br />
        <br />
        <br />
        <asp:Button ID="Button1" runat="server" OnClick="Button1_Click" Text="Continue to Report" /></div>
    </form>
</body>
</html>
