<%@ Page Language="vb" %>

<%@ Register Assembly="Telerik.Web.UI" Namespace="Telerik.Web.UI" TagPrefix="telerik" %>
<%@ Import Namespace="Prompt" %>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">

<script runat="server">
   
    Private nKey As Integer = 0
         
    Private Sub Page_Load(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MyBase.Load
        
        If ProcLib.CheckExpiredSessionForPopup(Page) Then    'session died so close the page - this is to prevent orphaned popups
            CloseMe()
        End If
        
        'set help info - note: no need for help button as one on page top will suffice here
        Session("PageID") = "FE_DivisionEdit"
        
        lblMessage.Text = ""

        nKey = Request.QueryString("DivisionID")
  
        If IsPostBack Then   'only do the following on post back or pass back
            nKey = lblID.Text
        Else  'only do the following on first load
                
            Using db As New PromptFE_Budgets
                db.CallingPage = Page
                If nKey = 0 Then    'load new record 
                    'new record so hide delete button
                    butDelete.Visible = False
                End If
                db.GetDivisionForEdit(nKey)   'loads existing record
                txtDivName.Focus()
                lblID.Text = nKey
               
            End Using
  
        End If
    End Sub

    Private Sub butSave_Click(ByVal sender As System.Object, ByVal e As System.Web.UI.ImageClickEventArgs) Handles butSave.Click
        If txtDivName.Text <> "" Then
            Using db As New PromptFE_Budgets
                db.CallingPage = Page
                db.SaveDivision(nKey)
            End Using
        End If
        CloseMe()
    End Sub

    Private Sub butDelete_Click(ByVal sender As System.Object, ByVal e As System.Web.UI.ImageClickEventArgs) Handles butDelete.Click
        Using db As New PromptFE_Budgets
            db.CallingPage = Page
            db.DeleteDivision(nKey)  'need to pass the code and ID to take care of JCAF assignments table entries
        End Using
        CloseMe()
    End Sub
 
    Private Sub CloseMe()
        ProcLib.CloseAndRefresh(Page)
    End Sub
    
</script>

<html>
<head>
    <title>Prompt - FE Divisions</title>
    <meta content="Microsoft Visual Studio .NET 7.1" name="GENERATOR">
    <meta content="Visual Basic .NET 7.1" name="CODE_LANGUAGE">
    <meta content="JavaScript" name="vs_defaultClientScript">
    <meta content="http://schemas.microsoft.com/intellisense/ie5" name="vs_targetSchema">
    <link href="Styles.css" type="text/css" rel="stylesheet">

    <script type="text/javascript" language="javascript">

        function GetRadWindow()   //note: sometimes this needs to be in HEAD tag to work properly
        {
            var oWindow = null;
            if (window.radWindow) oWindow = window.radWindow; //Will work in Moz in all cases, including clasic dialog
            else if (window.frameElement.radWindow) oWindow = window.frameElement.radWindow; //IE (and Moz az well)

            return oWindow;
        }

    </script>

</head>
<body>
    <telerik:RadScriptManager ID="RadScriptManager1" runat="server" />
    <form id="Form1" method="post" runat="server">
    <asp:Label ID="lblID" Style="z-index: 100; left: 42px; position: absolute; top: 15px"
        runat="server">999</asp:Label>
    <asp:Label ID="Label16" Style="z-index: 101; left: 10px; position: absolute; top: 14px"
        runat="server">ID:</asp:Label>
    <asp:TextBox ID="txtDivName" Style="z-index: 102; left: 109px; position: absolute;
        top: 37px" runat="server" CssClass="EditDataDisplay" Width="299px"></asp:TextBox>
    <asp:TextBox ID="txtAdminName" Style="z-index: 103; left: 109px; position: absolute;
        top: 68px" TabIndex="5" runat="server" CssClass="EditDataDisplay" Width="304px"></asp:TextBox>
    <asp:Label ID="Label4" runat="server" Style="z-index: 104; left: 14px; position: absolute;
        top: 66px; margin-bottom: 35px;">Administrator:</asp:Label>
    <asp:Label ID="Label20" runat="server" Style="z-index: 105; left: 15px; position: absolute;
        top: 38px; right: 1477px;">Division:</asp:Label>
    <asp:ImageButton ID="butSave" Style="z-index: 106; left: 19px; position: absolute;
        top: 160px" TabIndex="150" runat="server" ImageUrl="images/button_save.gif">
    </asp:ImageButton>
    <asp:ImageButton ID="butDelete" Style="z-index: 107; left: 247px; position: absolute;
        top: 159px" TabIndex="151" runat="server" ImageUrl="images/button_delete.gif">
    </asp:ImageButton>
    <asp:Label ID="lblMessage" Style="z-index: 108; left: 114px; position: absolute;
        top: 15px" runat="server" Width="382px" ForeColor="Red" Height="11px" TabIndex="500">Note:</asp:Label>
    <telerik:RadWindowManager ID="RadPopups" runat="server" Style="z-index: 110; left: 308px;
        position: absolute; top: 436px">
    </telerik:RadWindowManager>
    <telerik:RadNumericTextBox ID="txtBudget" runat="server" CssClass="EditDataDisplay"
        Label="   " MinValue="0" Style="z-index: 122; left: 111px; position: absolute;
        top: 102px" Width="97px">
        <NumberFormat AllowRounding="True" />
    </telerik:RadNumericTextBox>
    <p>
        <asp:Label ID="Label1" Style="z-index: 101; left: 14px; position: absolute; top: 101px"
            runat="server">Budget:</asp:Label>
    </p>
    </form>
</body>
</html>
