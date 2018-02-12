<%@ Page Language="vb" %>
<%@ Import Namespace="Prompt" %>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">

<script runat="server">

  
    Private Sub Page_Load(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MyBase.Load

        Session("PageID") = "DeleteError"
        lblMessage.Text = Request.QueryString("msg")
 
    End Sub

  
    Private Sub butCancel_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles butCancel.Click
        ProcLib.CloseOnlyRAD(Page)
    End Sub


</script>

<html>
<head>
    <title>Delete Error</title>
    <link rel="stylesheet" type="text/css" href="http://localhost/Prompt/Styles.css">

        <script type="text/javascript" language="javascript">


       function GetRadWindow() {
           var oWindow = null;
           if (window.radWindow) oWindow = window.radWindow; //Will work in Moz in all cases, including clasic dialog
           else if (window.frameElement.radWindow) oWindow = window.frameElement.radWindow; //IE (and Moz az well)

           return oWindow;
       }

 	   
    </script>

</head>
<body>
    <form id="Form1" method="post" runat="server">
    <asp:Label ID="lblMessage" Style="z-index: 100; left: 16px; position: absolute; top: 16px; height: 83px; width: 389px;"
        runat="server" CssClass="ViewDataDisplay">message</asp:Label>
     <asp:ImageButton ID="butCancel" Style="z-index: 102; left: 17px; position: absolute;
        top: 112px" runat="server" ImageUrl="images/button_cancel.gif"></asp:ImageButton>
    </form>
</body>
</html>
