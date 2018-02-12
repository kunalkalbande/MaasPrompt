<%@ Page Language="vb" %>

<%@ Import Namespace="Prompt" %>

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">

<script runat="server">

    Private Sub Page_Load(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MyBase.Load

        ProcLib.CheckSession(Page)
        ProcLib.LoadPopupJscript(Page)

        'set up help button
        Session("PageID") = "CollegeCopy"

        If Not IsPostBack Then   'only do the following post back

            'Load the College List
            Using rs As New PromptDataHelper
                rs.FillDropDown("SELECT College as Lbl, CollegeID As Val FROM Colleges WHERE DistrictID = " & Session("DistrictID") & " ORDER BY College", lstColleges)
            End Using
 
        End If

    End Sub

    Private Sub butCopy_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles butCopy.Click
       
        
        Using rs As New College
            rs.CopyCollege(lstColleges.SelectedValue, lstColleges.SelectedItem.Text)
        End Using

        ProcLib.RefreshNav(Page)

    End Sub

 
   

</script>

<html>
<head>
    <title>Copy College</title>
    <meta name="vs_snapToGrid" content="False">
    <meta name="GENERATOR" content="Microsoft Visual Studio .NET 7.1">
    <meta name="CODE_LANGUAGE" content="Visual Basic .NET 7.1">
    <meta name="vs_defaultClientScript" content="JavaScript">
    <meta name="vs_targetSchema" content="http://schemas.microsoft.com/intellisense/ie5">
    <link rel="stylesheet" type="text/css" href="http://localhost/Prompt/Styles.css">
</head>
<body>
    <form id="Form1" method="post" runat="server">
    <asp:Label ID="Label7" Style="z-index: 100; left: 18px; position: absolute; top: 114px"
        runat="server" EnableViewState="False" CssClass="FieldLabel" Height="24px">Source College:</asp:Label>
    <asp:Label ID="Label1" Style="z-index: 106; left: 16px; position: absolute; top: 54px"
        runat="server" Height="34px" CssClass="FieldLabel" EnableViewState="False" Width="95%">This procedure will create a copy of the selected college in the current District, including all subordinate items associated with the source college (except Attachments).</asp:Label>
    <table id="Table1" style="z-index: 102; left: 16px; position: absolute; top: 8px;
        height: 2px" cellspacing="1" cellpadding="1" border="0" width="96%">
        <tr height="1">
            <td style="height: 6px" valign="top">
                <asp:Label ID="Label8" runat="server" EnableViewState="False" Width="88px" CssClass="PageHeading"
                    Height="24px">Copy College</asp:Label>
            </td>
            <td style="height: 6px" valign="top" align="right">
            </td>
        </tr>
    </table>
    <hr style="z-index: 103; left: 16px; position: absolute; top: 40px" width="95%" size="1">
    <asp:DropDownList ID="lstColleges" Style="z-index: 104; left: 117px; position: absolute;
        top: 113px" runat="server">
    </asp:DropDownList>
    <asp:Button ID="butCopy" Style="z-index: 105; left: 21px; position: absolute; top: 168px"
        runat="server" Width="65px" Text="Copy"></asp:Button>
    </form>
</body>
</html>
