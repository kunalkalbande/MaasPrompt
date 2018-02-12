<%@ Page Language="VB" %>
<%@ Import Namespace="Prompt" %>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">

<script runat="server">
    
    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs)
        
        'If Request.QueryString("ID") = "FRSDISBURSEMENTIMPORT2007" Then
        Using db As New PromptDataHelper
            db.ExecuteStoredProcedure("rpt_FHDA_Budget_Cost_Report")
            'db.ExecuteStoredProcedure("test2")
            
        End Using
        Response.Write("Done")
        'End If

    End Sub
</script>

<html xmlns="http://www.w3.org/1999/xhtml" >
<head runat="server">
    <title>Untitled Page</title>
</head>
<body>
    <form id="form1" runat="server">
    <div>
    
    </div>
    </form>
</body>
</html>
