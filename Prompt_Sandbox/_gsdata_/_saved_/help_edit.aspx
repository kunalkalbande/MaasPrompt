<%@ Page Language="vb" %>

<%@ Import Namespace="Prompt" %>
<%@ Register Assembly="Telerik.Web.UI" Namespace="Telerik.Web.UI" TagPrefix="telerik" %>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">

<script runat="server"> 
    
    Dim nHelpID As Integer = 0
    Private Sub Page_Load(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MyBase.Load

        ProcLib.CheckSession(Page)

        ProcLib.LoadPopupJscript(Page)

        'set up help button
        Session("PageID") = "HelpEdit"
        butHelp.Attributes.Add("onclick", "openPopup('help_view.aspx','pophelp',550,450,'yes');")
        butHelp.NavigateUrl = "#"

        'Set the editor control properites
        txtHelpText.ToolsFile = "EISToolsFile.xml"

        nHelpID = Request.QueryString("HelpID")

        If IsPostBack Then   'only do the following post back
            nHelpID = lblHelpID.Text
        Else  'only do the following on first load

            Using rs As New Prompt_Help
                rs.CallingPage = Page
                Dim sql As String = ""
                If Request.QueryString("new") = "y" Then    'add the new record
                    rs.GetNewHelpEntry()
                    nHelpID = 0
                Else
                    rs.GetExistingHelpEntry(nHelpID)
                    
                End If

            End Using

        End If
        txtPageID.Focus()

    End Sub


    Private Sub butSave_Click(ByVal sender As System.Object, ByVal e As System.Web.UI.ImageClickEventArgs) Handles butSave.Click

        Using rs As New Prompt_Help
            rs.CallingPage = Page
            rs.SaveHelpEntry(nHelpID)
        End Using
        
        Session("RtnFromEdit") = True
        ProcLib.CloseAndRefresh(Page)

    End Sub

    Private Sub butDelete_Click(ByVal sender As System.Object, ByVal e As System.Web.UI.ImageClickEventArgs) Handles butDelete.Click
        Session("RtnFromEdit") = True
        Response.Redirect("delete_record.aspx?RecordType=Help&ID=" & nHelpID)

    End Sub
    

    
</script>

<html>
<head>
    <title>help_edit</title>
    <meta content="False" name="vs_snapToGrid" />
    <meta content="Microsoft Visual Studio .NET 7.1" name="GENERATOR" />
    <meta content="Visual Basic .NET 7.1" name="CODE_LANGUAGE" />
    <meta content="JavaScript" name="vs_defaultClientScript">
    <meta content="http://schemas.microsoft.com/intellisense/ie5" name="vs_targetSchema" />
    <link href="http://localhost/Prompt/Styles.css" type="text/css" rel="stylesheet" />

    <script type="text/javascript" language="javascript">
<!--

        var popUpWin = 0;
        function popUpWindow(URLStr, left, top, width, height) {
            if (popUpWin) {
                if (!popUpWin.closed) popUpWin.close();
            }
            popUpWin = open(URLStr, 'popUpWin', 'toolbar=no,location=no,directories=no,status=no,menubar=no,scrollbar=no,resizable=no,copyhistory=yes,width=' + width + ',height=' + height + ',left=' + left + ', top=' + top + ',screenX=' + left + ',screenY=' + top + '');
        }   
   
   
//-->
    </script>

</head>
<body>
   <form id="Form1" method="post" runat="server">
     <telerik:RadScriptManager ID="RadScriptManager1" runat="server" />
    <table id="Table1" style="z-index: 101; left: 16px; width: 1256px; position: absolute;
        top: 8px; height: 43px" height="43" cellspacing="1" cellpadding="1" width="100%"
        border="0">
        <tr height="1">
            <td valign="top" height="6">
                <asp:Label ID="Label8" runat="server" EnableViewState="False" Width="88px" CssClass="PageHeading"
                    Height="24px">Edit Help</asp:Label>
            </td>
            <td valign="top" align="right" height="6">
                <asp:HyperLink ID="butHelp" runat="server" ImageUrl="images/button_help.gif">HyperLink</asp:HyperLink>
            </td>
        </tr>
        <tr height="1">
            <td class="smalltext" valign="top" colspan="2" height="1">
                <hr width="100%" size="1">
                ID:
                <asp:Label ID="lblHelpID" runat="server">Label</asp:Label>
            </td>
        </tr>
    </table>
    <table id="Table2" style="z-index: 101; left: 16px; position: absolute; top: 64px;
        height: 43px" height="43" cellspacing="1" cellpadding="1" width="96%" border="0">
        <tr height="1">
            <td valign="top" width="1%" height="6">
                <asp:Label ID="Label7" runat="server" EnableViewState="False" CssClass="FieldLabel"
                    Height="24px">PageID:</asp:Label>
                &nbsp;
                <asp:TextBox ID="txtPageID" runat="server" EnableViewState="False" Width="147px"
                    CssClass="EditDataDisplay" Height="24px"></asp:TextBox>
                &nbsp;&nbsp;&nbsp;
                <asp:Label ID="Label1" runat="server" EnableViewState="False" CssClass="FieldLabel"
                    Height="24px">Page Title:</asp:Label>
                &nbsp;
                <asp:TextBox ID="txtPageTitle" TabIndex="1" runat="server" Width="218px" CssClass="EditDataDisplay"
                    Height="24px"></asp:TextBox>&nbsp;
            </td>
        </tr>
        <tr height="1">
            <td valign="top" height="421" style="height: 421px">
                <asp:Label ID="Label2" runat="server" EnableViewState="False" CssClass="FieldLabel"
                    Height="24px" Font-Bold="True">Help Text:</asp:Label><br>
                <telerik:RadEditor ID="txtHelpText" Width="620px" Height="391px" enabledocking="False"
                    enableenhancededit="False" runat="server" saveinfile="False" showhtmlmode="False"
                    showpreviewmode="False" showsubmitcancelbuttons="False" usefixedtoolbar="True">
                </telerik:RadEditor>
            </td>
        </tr>
        <tr height="1">
            <td valign="middle" height="6">
                <asp:ImageButton ID="butSave" TabIndex="40" runat="server" ImageUrl="images/button_save.gif">
                </asp:ImageButton>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
                <asp:ImageButton ID="butDelete" TabIndex="41" runat="server" ImageUrl="images/button_delete.gif">
                </asp:ImageButton>
            </td>
        </tr>
    </table>
    </form>
</body>
</html>
