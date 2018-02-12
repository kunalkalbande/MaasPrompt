<%@ Page Language="vb" %>

<%@ Register Assembly="Telerik.Web.UI" Namespace="Telerik.Web.UI" TagPrefix="telerik" %>
<%@ Import Namespace="Prompt" %>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">

<script runat="server">

    Private Sub Page_Load(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MyBase.Load

        Session("PageID") = "BondSiteNewsEdit"

        ProcLib.LoadPopupJscript(Page)

        'set up help button
        butHelp.Attributes.Add("onclick", "openPopup('help_view.aspx','pophelp',550,450,'yes');")
        butHelp.NavigateUrl = "#"

        If Not IsPostBack() Then
            Using db As New BondSite
                db.CallingPage = Page
                txtAppriseCurrentNews.Content = db.GetBondNews(Session("DistrictID"))
 
            End Using
        End If


    End Sub
     
    Private Sub butSave_Click(ByVal sender As System.Object, ByVal e As System.Web.UI.ImageClickEventArgs) Handles butSave.Click
  
        Using db As New BondSite
            db.CallingPage = Page
            db.SaveBondNews(Session("DistrictID"))
        End Using

        ProcLib.CloseAndRefreshRADNoPrompt(Page)
        Session("RtnFromEdit") = True
        
        
    End Sub

 
</script>

<html>
<head>
    <title>Apprise Current News Edit</title>
    <meta content="Microsoft Visual Studio .NET 7.1" name="GENERATOR">
    <meta content="Visual Basic .NET 7.1" name="CODE_LANGUAGE">
    <meta content="JavaScript" name="vs_defaultClientScript">
    <meta content="http://schemas.microsoft.com/intellisense/ie5" name="vs_targetSchema">
    <link href="Styles.css" type="text/css" rel="stylesheet">

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
     <telerik:RadScriptManager ID="RadScriptManager1" runat="server" />
    <table id="Table1" style="z-index: 101; left: 16px; position: absolute; top: 8px;
        height: 43px" cellspacing="1" cellpadding="1" width="96%" border="0">
        <tr>
            <td valign="top" height="6">
                <asp:Label ID="Label8" runat="server" EnableViewState="False" Width="88px" CssClass="PageHeading"
                    Height="24px">Edit Current News</asp:Label>
            </td>
            <td valign="top" align="right" height="6">
                <asp:HyperLink ID="butHelp" runat="server" ImageUrl="images/button_help.gif">HyperLink</asp:HyperLink>
            </td>
        </tr>
        <tr>
            <td class="smalltext" valign="top" colspan="2" height="1">
                <hr width="100%" size="1">
            </td>
        </tr>
    </table>
    <table id="Table2" style="z-index: 101; left: 16px; position: absolute; top: 64px;
        height: 43px" cellspacing="1" cellpadding="1" width="96%" border="0">
        <tr>
            <td colspan="2" valign="top">
                <telerik:RadEditor ID="txtAppriseCurrentNews" Width="98%" Height="300px" EnableDocking="False"
                    EnableEnhancedEdit="False" runat="server" SaveInFile="False" ShowHtmlMode="False"
                    ShowPreviewMode="False" ShowSubmitCancelButtons="False" UseFixedToolbar="True"
                    ToolsFile="EISToolsFile.xml">
                </telerik:RadEditor>
            </td>
        </tr>
        <tr>
            <td colspan="2" valign="middle" height="6">
                <asp:ImageButton ID="butSave" TabIndex="40" runat="server" ImageUrl="images/button_save.gif" >
                </asp:ImageButton>
                
             </td>
        </tr>
    </table>
 
    </form>
</body>
</html>
