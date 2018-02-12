<%@ Page Language="vb" %>

<%@ Import Namespace="Prompt" %>
<%@ Register Assembly="Telerik.Web.UI" Namespace="Telerik.Web.UI" TagPrefix="telerik" %>

<script runat="server">

    Public nLedgerAccountID As Integer = 0
    Public nCollegeID As String
    Private message As String = ""
    Private WinType As String = ""
    
    Private bAdding As Boolean = False
    
    Private Sub Page_Load(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MyBase.Load

        ProcLib.CheckSession(Page)
        
        ProcLib.LoadPopupJscript(Page)
        
        lblMessage.Text = ""

        'set up help button
        Session("PageID") = "LedgerAccountEdit"
        
        butHelp.Attributes.Add("onclick", "openPopup('help_view.aspx','pophelp',550,450,'yes');")
        butHelp.NavigateUrl = "#"

        nLedgerAccountID = Request.QueryString("LedgerAccountID")
        
        WinType = Request.QueryString("WinType")
        nCollegeID = Request.QueryString("CollegeID")
        
        If nLedgerAccountID = 0 Then
            bAdding = True
            butDelete.Visible = False
            butFlag.Visible = False
        End If
                
        
        butFlag.Visible = False      'TODO: Decide about enabling flag for account level
        
        If IsPostBack Then   'only do the following post back
            nLedgerAccountID = lblLedgerAccountID.Text
        Else  'only do the following on first load
            Using db As New promptLedgerAccount
                db.CallingPage = Page
                If nLedgerAccountID = 0 Then    'new project
                    'get data and Fill the drop downs
                    db.GetNewLedgerAccount()
                Else
                    'get data and Fill the drop downs
                    db.GetExistingLedgerAccount(nLedgerAccountID)
                End If
                
                lblLedgerAccountID.Text = nLedgerAccountID
            End Using
        End If
        
        txtLedgerName.Focus()
        
        
    End Sub

   
    
    Private Sub butSave_Click(ByVal sender As System.Object, ByVal e As System.Web.UI.ImageClickEventArgs) Handles butSave.Click
        
        'save the account
        Using db As New promptLedgerAccount
            db.CallingPage = Page
            db.SaveLedgerAccount(nCollegeID, nLedgerAccountID)
            nLedgerAccountID = db.LedgerAccountID
        End Using
        Session("RtnFromEdit") = True
        Session("nodeid") = "Ledger" & nLedgerAccountID
        'Session("collegenodeid") = "College" & nCollegeID
        Session("RefreshNav") = True   'set a flag so that the nav page will refresh when the info page is refreshed

        If bAdding Then  'we are closing after initial edit after add new so need to redirect opener page
            
            ProcLib.CloseAndRefreshRAD(Page)
           
        Else
            ProcLib.CloseAndRefreshRAD(Page)
        End If
 
            
  
    End Sub

    Private Sub butDelete_Click(ByVal sender As System.Object, ByVal e As System.Web.UI.ImageClickEventArgs) Handles butDelete.Click
        
        Dim msg As String = ""
        Using db As New promptLedgerAccount
            msg = db.DeleteLedgerAccount(nLedgerAccountID)
        End Using
        If msg <> "" Then
            lblMessage.Text = msg
        Else
            Session("nodeid") = "College" & Session("CollegeID")
            Session("RtnFromEdit") = True
            Session("RefreshNav") = True   'set a flag so that the nav page will refresh when the info page is refreshed
            ProcLib.CloseAndRefreshRAD(Page)
        End If

    End Sub
 
  
</script>

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">
<html>
<head>
    <title>Ledger Account Edit</title>
    <link href="Styles.css" type="text/css" rel="stylesheet" />

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
    <table id="Table1" style="z-index: 116; left: 8px; position: absolute; top: 8px"
        height="2" cellspacing="1" cellpadding="1" width="98%" border="0">
        <tr height="1">
            <td valign="top" height="6">
                <asp:Label ID="Label8" runat="server" EnableViewState="False" Width="188px" CssClass="PageHeading"
                    Height="24px">Edit Ledger Account</asp:Label>
            </td>
            <td valign="top" align="right" height="6">
                <asp:HyperLink ID="butFlag" runat="server" ImageUrl="images/button_flag.gif"></asp:HyperLink>&nbsp;&nbsp;&nbsp;
                <asp:HyperLink ID="butHelp" runat="server" ImageUrl="images/button_help.gif">HyperLink</asp:HyperLink>
            </td>
        </tr>
    </table>
    &nbsp; &nbsp;
    <asp:Label ID="Label2" Style="z-index: 100; left: 24px; position: absolute; top: 82px"
        runat="server" CssClass="smalltext" Height="16px">Name:</asp:Label>
    <hr style="z-index: 117; left: 8px; position: absolute; top: 40px" width="98%" size="1">
    <asp:Label ID="Label1" Style="z-index: 101; left: 24px; position: absolute; top: 56px"
        runat="server" CssClass="smalltext" Height="16px">ID:</asp:Label>
    <asp:Label ID="lblMessage" runat="server" CssClass="smalltext" ForeColor="Red" Height="16px"
        Style="z-index: 118; left: 27px; position: absolute; top: 263px" Width="454px">ID:</asp:Label>
    &nbsp;&nbsp;&nbsp; &nbsp; &nbsp; &nbsp; &nbsp;&nbsp;
    <asp:Label ID="Label9" Style="z-index: 104; left: 21px; position: absolute; top: 117px"
        runat="server" CssClass="smalltext">Account Number:</asp:Label>
    &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp;
    <asp:HiddenField ID="txtCurrentBudgetBatchID" runat="server" />
    &nbsp; &nbsp;&nbsp;
    <asp:Label ID="Label15" Style="z-index: 105; left: 225px; position: absolute; top: 117px"
        runat="server" CssClass="smalltext" Height="16px">Bond Series:</asp:Label>
    &nbsp;
    <asp:Label ID="Label3" Style="z-index: 105; left: 225px; position: absolute; top: 52px"
        runat="server" CssClass="smalltext" Height="16px">Ledger Type:</asp:Label>
    &nbsp;
    <asp:Label ID="Label16" Style="z-index: 106; left: 23px; position: absolute; top: 146px"
        runat="server" CssClass="smalltext" Height="16px">Description:</asp:Label>
    &nbsp;&nbsp;
    <asp:TextBox ID="txtLedgerName" Style="z-index: 107; left: 71px; position: absolute;
        top: 83px" runat="server" Width="376px" CssClass="EditDataDisplay"></asp:TextBox>
    &nbsp;&nbsp;
    <asp:TextBox ID="txtAccountNumber" Style="z-index: 108; left: 118px; position: absolute;
        top: 118px" TabIndex="9" runat="server" Width="75px" CssClass="EditDataDisplay"></asp:TextBox>
    &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp;&nbsp;
    <asp:TextBox ID="txtDescription" Style="z-index: 109; left: 20px; position: absolute;
        top: 166px" TabIndex="40" runat="server" Width="430px" CssClass="EditDataDisplay"
        Height="55px" TextMode="MultiLine"></asp:TextBox>
    &nbsp;
    <asp:Label ID="lblLedgerAccountID" Style="z-index: 110; left: 56px; position: absolute;
        top: 56px" runat="server" CssClass="ViewDataDisplay" Height="16px">###</asp:Label>
    &nbsp; &nbsp; &nbsp; &nbsp; &nbsp;
    <asp:DropDownList ID="lstBondSeriesNumber" Style="z-index: 112; left: 297px; position: absolute;
        top: 118px" TabIndex="30" runat="server" CssClass="EditDataDisplay">
    </asp:DropDownList>
    &nbsp; &nbsp;
    <asp:DropDownList ID="lstAccountType" Style="z-index: 112; left: 297px; position: absolute;
        top: 52px" TabIndex="30" runat="server" CssClass="EditDataDisplay">
    </asp:DropDownList>
        &nbsp;
    <asp:ImageButton ID="butSave" Style="z-index: 114; left: 25px; position: absolute;
        top: 233px" TabIndex="45" runat="server" ImageUrl="images/button_save.gif"></asp:ImageButton>
    <asp:ImageButton ID="butDelete" Style="z-index: 115; left: 285px; position: absolute;
        top: 230px" TabIndex="50" runat="server" ImageUrl="images/button_delete.gif">
    </asp:ImageButton>
    &nbsp;
    </form>
</body>
</html>
