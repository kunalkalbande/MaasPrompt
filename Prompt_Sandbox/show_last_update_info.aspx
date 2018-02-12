<%@ Page Language="VB" %>

<%@ Import Namespace="Prompt" %>

<script runat="server">
    
    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load
        Dim nID As Integer = Request.QueryString("ID")
        Dim sType As String = Request.QueryString("RecType")
        
        Using db As New PromptDataHelper
            Dim rs As New DataTable
            rs = db.ExecuteDataTable("SELECT LastUpdateOn,LastUpdateBy FROM Transactions WHERE TransactionID = " & nID)
            lblLastUpdateOn.Text = rs.Rows(0)(0)
            lblLastUpdateBy.Text = rs.Rows(0)(1)
        End Using
       
       
        
    End Sub
 
   </script>

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title>Last Update Info</title>
    <link href="Styles.css" rel="stylesheet" type="text/css" />
</head>
<body>
    <form id="form1" runat="server">
        <asp:Label ID="Label1" runat="server" CssClass="smalltext" Style="z-index: 100; left: 9px;
            position: absolute; top: 10px" Text="Last Updated On:"></asp:Label>
        <asp:Label ID="lblLastUpdateOn" runat="server" CssClass="ViewDataDisplay" Style="z-index: 101;
            left: 110px; position: absolute; top: 11px" Text="07/07/2007"></asp:Label>
        <asp:Label ID="lblLastUpdateBy" runat="server" CssClass="ViewDataDisplay" Style="z-index: 104;
            left: 114px; position: absolute; top: 33px" Text="Joe Shmo"></asp:Label>
        <asp:Label ID="Label2" runat="server" CssClass="smalltext" Style="z-index: 103; left: 10px;
            position: absolute; top: 34px" Text="Last Updated By:"></asp:Label>
  
    </form>
</body>
</html>
