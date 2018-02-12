<%@ Page Language="vb" ValidateRequest="false" %>

<%@ Register Assembly="Telerik.Web.UI" Namespace="Telerik.Web.UI" TagPrefix="telerik" %>
<%@ Import Namespace="Prompt" %>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">

<script runat="server">
    
    Private Sub Page_Load(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MyBase.Load
        
        ProcLib.CheckSession(Page)
        ProcLib.LoadPopupJscript(Page)

        'set up help button

    End Sub
   
    Public Sub BuildMenu()
        
         
           
    End Sub
     
    Private Sub CloseMe()
 
    End Sub

    Protected Sub RadMenu1_ItemClick(ByVal sender As Object, ByVal e As Telerik.Web.UI.RadMenuEventArgs)
       
    End Sub
</script>

<html>
<head>
    <title>Print Setup</title>
    <link href="Styles.css" type="text/css" rel="stylesheet" />

    <script type="text/javascript" language="javascript">
        function GetRadWindow() {
            var oWindow = null;
            if (window.RadWindow) oWindow = window.RadWindow;
            else if (window.frameElement.radWindow) oWindow = window.frameElement.radWindow;
            return oWindow;
        }

        function ShowHelp()     //for help display
        {

            var oWnd = window.radopen("help_view.aspx?WinType=RAD", "ShowHelpWindow");
            return false;
        } 

    </script>

</head>
<body>
    <form id="Form1" method="post" runat="server">
    <telerik:RadScriptManager ID="RadScriptManager1" runat="server" />
    &nbsp;
    <asp:Label ID="Label2" runat="server" CssClass="smalltext" EnableViewState="False"
        Style="z-index: 101; left: 8px; position: absolute; top: 135px" visible="false">Description:</asp:Label>


    <asp:TextBox ID="TestingText" Style="z-index: 102; left: 6px; position: absolute;
        top: 154px" TabIndex="1" runat="server" Height="99px" CssClass="EditDataDisplay"
        TextMode="MultiLine" Width="250px"></asp:TextBox>
    <!-- Menu Items -->
 
    <telerik:RadWindowManager ID="RadPopups" runat="server">
    </telerik:RadWindowManager>
    <asp:HiddenField ID="txtFlagID" runat="server" Value="0" />
    </form>
</body>
</html>
