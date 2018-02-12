<%@ Page Language="VB" %>
<%@ Import Namespace="Prompt" %>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">

<script runat="server">
    
    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs)
        
           
        Dim sText As String = ""
        Using rs As New HoverData
            sText = rs.GetJCAFBudgetData(Request.QueryString("parms"))
            lblData.Text = sText.Replace(vbCrLf, "<br>")      'put the line breaks in as html tags if present
        End Using
        
        If InStr(Request.QueryString("parms"), "Note") > 0 Then
            PageTitle.Text = "Current Notes"
        ElseIf InStr(Request.QueryString("parms"), "Flag") > 0 Then
            PageTitle.Text = "Flag"
        Else
            PageTitle.Text = "Change History"
        End If
        
    End Sub
</script>

<html xmlns="http://www.w3.org/1999/xhtml" >
<head runat="server">

    <title id="PageTitle" runat=server></title>
    <link href="Styles.css" type="text/css" rel="stylesheet">
</head>
<body  topmargin=0 leftmargin=0 >
    <form id="form1" runat="server">
    <div>
        <asp:Label ID="lblData" runat="server" Text="Label" Width="232px" CssClass="ViewDataDisplaySmall"></asp:Label>&nbsp;</div>
    </form>
</body>
</html>
