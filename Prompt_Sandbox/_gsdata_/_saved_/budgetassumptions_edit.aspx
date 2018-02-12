<%@ Page Language="vb"  %>
<%@ Import Namespace="Prompt" %>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">
<script runat="server">
    Dim nProjectID As Integer
    Private Sub Page_Load(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MyBase.Load

        Proclib.CheckSession(Page)

        Proclib.LoadPopupJscript(Page)
        'set up help button
        Session("PageID") = "EditBudgetAssumptions"
        butHelp.Attributes.Add("onclick", "openPopup('help_view.aspx','pophelp',550,450,'yes');")
        butHelp.NavigateUrl = "#"

        nProjectID = Request.QueryString("ProjectID")

        If Not IsPostBack Then
            Using rs As New promptBudget
                rs.CallingPage = Page
                rs.GetBudgetAssumptionsData(nProjectID)
            End Using
        End If

    End Sub

    Private Sub butSave_Click(ByVal sender As System.Object, ByVal e As System.Web.UI.ImageClickEventArgs) Handles butSave.Click
        'Update PromptProjectData
        Using rs As New promptBudget
            rs.CallingPage = Page
            rs.SaveBudgetAssumptionsData(nProjectID)
        End Using
        
        Session("RtnFromEdit") = True
        Proclib.CloseAndRefresh(Page)
    End Sub



</script>
<HTML>
	<HEAD>
		<title>budgetassumptions_edit</title>
		<meta name="GENERATOR" content="Microsoft Visual Studio .NET 7.1">
		<meta name="CODE_LANGUAGE" content="Visual Basic .NET 7.1">
		<meta name="vs_defaultClientScript" content="JavaScript">
		<meta name="vs_targetSchema" content="http://schemas.microsoft.com/intellisense/ie5">
		<LINK rel="stylesheet" type="text/css" href="http://localhost/Prompt/Styles.css">
	</HEAD>
	<body>
		<form id="Form1" method="post" runat="server">
			<asp:Label id="Label1" style="Z-INDEX: 101; LEFT: 8px; POSITION: absolute; TOP: 24px" runat="server">Edit Budget Assumptions:</asp:Label>
			<asp:HyperLink id="butHelp" style="Z-INDEX: 106; LEFT: 528px; POSITION: absolute; TOP: 8px" runat="server"
				ImageUrl="images/button_help.gif">HyperLink</asp:HyperLink>
			<asp:imagebutton id="butSave" style="Z-INDEX: 104; LEFT: 16px; POSITION: absolute; TOP: 288px" tabIndex="5"
				runat="server" ImageUrl="images/button_save.gif"></asp:imagebutton>
			<asp:TextBox id="txtBudgetAssumptions" style="Z-INDEX: 102; LEFT: 8px; POSITION: absolute; TOP: 40px"
				runat="server" Width="568px" Height="224px" TextMode="MultiLine"></asp:TextBox>
		</form>
	</body>
</HTML>
