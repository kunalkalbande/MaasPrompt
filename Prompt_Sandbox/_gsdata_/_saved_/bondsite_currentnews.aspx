<%@ Page Language="VB" %>
<%@ Import Namespace="Prompt" %>
<%@ Register Assembly="Telerik.Web.UI" Namespace="Telerik.Web.UI" TagPrefix="telerik" %>

<script runat="server">
    
    Private Sub Page_Load(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MyBase.Load

        Session("PageID") = "BondsiteCurrentNews"
       
        With contentPopups
            .VisibleOnPageLoad = False
            .Skin = "Office2007"
                         
            Dim ww As New RadWindow

            ww = New RadWindow
            With ww
                .ID = "EditNewsWindow"
                .NavigateUrl = "#"
                .Title = ""
                .Width = 650
                .Height = 475
                .Modal = True
                .VisibleStatusbar = False
                .ReloadOnShow = True
                .Behaviors = WindowBehaviors.Close + WindowBehaviors.Move
            End With
            .Windows.Add(ww)
  
        End With

        'configure edit button

        lnkEdit.Attributes("onclick") = "return EditNews();"
        
        Using db As New BondSite
            lblNews.Text = db.GetBondNews(Session("DistrictID"))
            If lblNews.Text = " " Then
                lblNews.Text = "( No News Found ) "
            End If
        End Using


    End Sub

 
</script>

<html xmlns="http://www.w3.org/1999/xhtml">
<head id="Head1" runat="server">
    <title> </title>
    <link href="Styles.css" rel="stylesheet" type="text/css" />
</head>
<body>
    <form id="Form1" method="post" runat="server">
    <telerik:RadScriptManager ID="RadScriptManager1" runat="server" />
    <br />
 <div align="right" id="header" style="float: right; z-index: 150; position: static;">
  <asp:HyperLink ID="lnkEdit" ImageUrl="images/button_edit.gif" runat="server" NavigateUrl="#">edit link</asp:HyperLink>
</div>
<asp:Label ID="lblNews" runat="server"><<< News goes here >>></asp:Label>
<telerik:RadWindowManager ID="contentPopups" runat="server">
</telerik:RadWindowManager>
<script type="text/javascript" language="javascript">

    function EditNews()   
    {

        var oWnd = window.radopen("bondsite_currentnews_edit.aspx", "EditNewsWindow");
        return false;
    }

 
    function GetRadWindow() {
        var oWindow = null;
        if (window.RadWindow) oWindow = window.RadWindow;
        else if (window.frameElement.radWindow) oWindow = window.frameElement.radWindow;
        return oWindow;
    }

</script>
    </form>
</body>
</html>
