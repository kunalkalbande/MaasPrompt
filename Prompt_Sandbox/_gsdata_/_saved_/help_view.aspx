<%@ Page Language="vb" %>

<%@ Import Namespace="Prompt" %>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">

<script runat="server">
     
    Private Sub Page_Load(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MyBase.Load

        Dim strPageID As String
        

        Proclib.LoadPopupJscript(Page)
        
        Session("HelpCalledFrom") = ""

        lblTitle.Text = ""
        lblText.Text = ""
 
        
        strPageID = Session("PageID")
        If Request.QueryString("PageID") <> "" Then   'incase help is called from specific context page
            strPageID = Request.QueryString("PageID")
        End If

        lblPageID.Text = "(" & strPageID & ")"

        Dim HelpID As Integer
        Using rs As New PromptDataHelper
            rs.FillReader("SELECT * FROM Help WHERE PageID = '" & strPageID + "'")
            While rs.Reader.Read
                lblTitle.Text = rs.Reader("PageTitle")
                lblText.Text = rs.Reader("HelpText")
                HelpID = rs.Reader("HelpID")
            End While
            rs.Reader.Close()
        End Using
        
        If HelpID = 0       'no existing entry in the help table, so create one
            Using db As New PromptDataHelper
                Dim sql As String 
                sql = "Insert into Help (PageTitle, PageID, HelpText, LastUpdateOn, LastUpdateBy) Values ('" & strPageID & "', '" & strPageID 
                sql &= "', 'Sorry, No help available for this page.', getdate(), 'auto-created') SELECT CAST(SCOPE_IDENTITY() AS int) AS ID" 
                helpID = db.executescalar(sql)
            End Using
        End If
        

        If lblTitle.Text = "" Then lblTitle.Text = ""
        If lblText.Text = "" Then lblText.Text = "Sorry, No help available for this page."

        If Session("UserRole") = "TechSupport"
            lnkEditHelp.Visible = True
            lnkEditHelp.navigateURL = "help_edit.aspx?HelpID=" & HelpID
            lnkEditHelp.Target = "new"
        Else
            lnkEditHelp.Visible = False
        End If
        

    End Sub

    Private Sub lnkTechSupport_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles lnkTechSupport.Click
        Dim jscript As String
        Dim sQS As String
        sQS = "U=" & Session("UserName") & "&pageid=" & Session("PageID") & "&DI=" & Session("DistrictID") & "&LoginID=" & Session("LoginID")
        'popup edit page
        jscript = "<script language='javascript'>"
        jscript = jscript & "openPopup('tech_support_email_form.aspx?" & sQS & "','techsup',550,400,'yes');"
        jscript = jscript & "self.close(); "
        jscript = jscript & "</" & "script>"
        Page.ClientScript.RegisterStartupScript(GetType(String), "techsupp", jscript)

    End Sub

    Private Sub butClose_Click(ByVal sender As System.Object, ByVal e As System.Web.UI.ImageClickEventArgs) Handles butClose.Click
        If Request.QueryString("WinType") = "RAD" Then
            ProcLib.CloseOnlyRAD(Page)
        Else
            ProcLib.CloseOnly(Page)
        End If
        
    End Sub
 
</script>

<html>
<head>
    <title>help_view</title>
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
    <table id="Table1" style="z-index: 104; left: 8px; position: absolute; top: 8px;
        height: 128px" cellspacing="1" cellpadding="1" width="95%" border="0">
        <tr>
            <td>
                <p>
                    <asp:Label ID="lblTitle" runat="server" Font-Bold="True" Font-Underline="True" CssClass="ViewDataDisplay"
                        ForeColor="#404040">Title</asp:Label></p>
                <p>
                    <asp:Label ID="lblText" runat="server" CssClass="ViewDataDisplay">Title</asp:Label><br>
                </p>
            </td>
        </tr>
        <tr>
            <td class="smalltext">
                <hr size="1">
                <br />
                <br />
                If you neeed further help or to report a problem, please&nbsp;&nbsp;
                <asp:LinkButton ID="lnkTechSupport" runat="server">Click Here </asp:LinkButton>&nbsp;to 
                send a technical support message or email <a href="mailto:promptsupport@eispro.com">
                    promptsupport@eispro.com</a>. <br /><br /> 
                    <br /><br />
                    Prompt Support Tel: 408-384-8347
                    <br /><br />
                    To download Revision History <a href="PromptRevisionHistory.pdf">
                    Click Here</a>
               <p class="style3">
                    <asp:Label ID="lblPageID" runat="server" CssClass="ViewDataDisplay">PageID</asp:Label>
                   <asp:HyperLink ID="lnkEditHelp" runat="server">Edit Help Text</asp:HyperLink>
               </p>
            </td>
        </tr>
        <tr>
            <td>
                <asp:ImageButton ID="butClose" runat="server" ImageUrl="images/button_close.gif">                 </asp:ImageButton>
            </td>
        </tr>
    </table>
    </form>
</body>
</html>
