<%@ Page Language="vb" %>
<%@ Import Namespace="Prompt" %>
<%@ Register Assembly="Telerik.Web.UI" Namespace="Telerik.Web.UI" TagPrefix="telerik" %>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">

<script runat="server">
    Public nClientID As Integer = 0
    Private Sub Page_Load(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MyBase.Load


        ProcLib.CheckSession(Page)

        'set up help button

        ProcLib.LoadPopupJscript(Page)

        Session("PageID") = "ClientEdit"
        butHelp.Attributes.Add("onclick", "openPopup('help_view.aspx','pophelp',550,450,'yes');")
        butHelp.NavigateUrl = "#"

        nClientID = Request.QueryString("ClientID")

        If IsPostBack Then   'only do the following post back
            nClientID = lblClientID.Text
        Else  'only do the following on first load
            
            Using db As New Client
                db.CallingPage = Page
                If nClientID = 0 Then    'add the new record
                    butDelete.Visible = False
                Else
                    db.GetClient(nClientID)
                End If
                lblClientID.Text = nClientID
            End Using
        End If
        
        txtClientName.Focus()
    End Sub

    Private Sub butSave_Click(ByVal sender As System.Object, ByVal e As System.Web.UI.ImageClickEventArgs) Handles butSave.Click

        Using db As New Client
            db.CallingPage = Page
            db.SaveClientEditForm(nClientID)
        End Using
 
        ProcLib.CloseAndRefreshRAD(Page)

    End Sub

    Private Sub butDelete_Click(ByVal sender As System.Object, ByVal e As System.Web.UI.ImageClickEventArgs) Handles butDelete.Click
        
        Dim msg As String = ""
        Using db As New Client
            msg = db.DeleteClient(nClientID)
        End Using
        If msg <> "" Then
            Response.Redirect("delete_error.aspx?msg=" & msg)
        Else
            ProcLib.CloseAndRefreshRADNoPrompt(Page)
        End If
    End Sub



</script>

<html xmlns="http://www.w3.org/1999/xhtml">
<head>
    <title>Edit Client</title>
     <link href="Styles.css" type="text/css" rel="stylesheet" />
     
    <script type="text/javascript" language="javascript">

        function GetRadWindow() {
            var oWindow = null;
            if (window.RadWindow) oWindow = window.RadWindow;
            else if (window.frameElement.radWindow) oWindow = window.frameElement.radWindow;
            return oWindow;
        }

 
    </script>

</head>
<body>
    <form id="Form1" method="post" runat="server">
    <telerik:RadScriptManager ID="RadScriptManager1" runat="server" />
    <asp:TextBox ID="txtClientName" Style="z-index: 104; left: 104px; position: absolute;
        top: 72px" runat="server" Width="192px" EnableViewState="False" CssClass="EditDataDisplay"></asp:TextBox>
    <asp:ImageButton ID="butDelete" Style="z-index: 110; left: 205px; position: absolute;
        top: 113px" TabIndex="6" runat="server" 
        ImageUrl="images/button_delete.gif">
    </asp:ImageButton>
    <asp:Label ID="lblClientID" Style="z-index: 107; left: 42px; position: absolute;
        top: 49px" runat="server" Height="12px" CssClass="FieldLabel">999</asp:Label>
    <asp:Label ID="Label3" Style="z-index: 106; left: 17px; position: absolute; top: 48px"
        runat="server" EnableViewState="False" Height="12px" CssClass="FieldLabel">ID:</asp:Label>
    &nbsp;&nbsp;
    <asp:Label ID="Label7" Style="z-index: 100; left: 16px; position: absolute; top: 72px"
        runat="server" EnableViewState="False" Height="24px" CssClass="FieldLabel">Client Name:</asp:Label>
    <table id="Table1" style="z-index: 102; left: 16px; position: absolute; top: 8px;
        height: 2px" cellspacing="1" cellpadding="1" width="92%" border="0">
        <tr height="1">
            <td style="height: 6px" valign="top">
                <asp:Label ID="Label8" runat="server" Width="88px" EnableViewState="False" Height="24px"
                    CssClass="PageHeading">Edit Client</asp:Label>
            </td>
            <td style="height: 6px" valign="top" align="right">
                <asp:HyperLink ID="butHelp" runat="server" ImageUrl="images/button_help.gif">HyperLink</asp:HyperLink>
            </td>
        </tr>
    </table>
    <hr style="z-index: 103; left: 16px; position: absolute; top: 40px" width="95%" size="1" />
    <asp:ImageButton ID="butSave" Style="z-index: 109; left: 18px; position: absolute;
        top: 112px" TabIndex="5" runat="server" ImageUrl="images/button_save.gif"></asp:ImageButton>
 
    </form>
</body>
</html>
