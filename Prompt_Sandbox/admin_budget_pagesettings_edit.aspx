<%@ Page Language="vb" ValidateRequest="false" %>
<%@ Register Assembly="Telerik.Web.UI" Namespace="Telerik.Web.UI" TagPrefix="telerik" %>
<%@ Import Namespace="Prompt" %>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">

<script runat="server">
    Private nProjectID As Integer = 0
     
    Private Sub Page_Load(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MyBase.Load

        ProcLib.CheckSession(Page)
 
        'set up help button
        Session("PageID") = "AdminBudgetPageSettings"
        nProjectID = Request.QueryString("ProjectID")
              
        If Not IsPostBack Then
            Using db As New promptBudget
                db.CallingPage = Page
                db.GetBudgetColumnSettingsForEdit(nProjectID)
            End Using
        End If

    End Sub
   
    Private Sub butSave_Click(ByVal sender As System.Object, ByVal e As System.Web.UI.ImageClickEventArgs) Handles butSave.Click
        
        Using db As New promptBudget
            db.CallingPage = Page
            db.SaveBudgetColumnSettings(nProjectID)
            
        End Using

        Session("RtnFromEdit") = True
        ProcLib.CloseAndRefreshRADNoPrompt(Page)
         
    End Sub
    

</script>

<html>
<head>
    <title>Budget Column Settings</title>
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
    
    
    <asp:ImageButton ID="butSave" Style="z-index: 104; left: 91px; position: absolute;
        top: 191px" TabIndex="5" runat="server" ImageUrl="images/button_save.gif"></asp:ImageButton>
        
     <asp:CheckBox ID="chkBudgetHideDonationColumn" runat="server" 
        Style="z-index: 101; left: 10px; position: absolute; top: 152px; bottom: 732px;" 
        Text="Hide Donation Column" />
    
    
     <asp:CheckBox ID="chkBudgetHideMaintColumn" runat="server" 
        Style="z-index: 101; left: 10px; position: absolute; top: 125px; bottom: 759px;" 
        Text="Hide Maintenance Column" />
    
    
     <asp:CheckBox ID="chkBudgetHideGrantColumn" runat="server" 
        Style="z-index: 101; left: 10px; position: absolute; top: 98px; bottom: 786px;" 
        Text="Hide Grant Column" />
    
    
     <asp:CheckBox ID="chkBudgetHideHazmatColumn" runat="server" 
        Style="z-index: 101; left: 10px; position: absolute; top: 73px; bottom: 811px;" 
        Text="Hide Hazmat Column" />
    
    
     <asp:CheckBox ID="chkBudgetHideBondColumn" runat="server" 
        Style="z-index: 101; left: 10px; position: absolute; top: 48px; bottom: 836px;" 
        Text="Hide Bond Column" />
    
    
     <asp:CheckBox ID="chkBudgetHideStateColumn" runat="server" 
        Style="z-index: 101; left: 10px; position: absolute; top: 21px; bottom: 863px;" 
        Text="Hide State Column" />
    
    
    </form>
</body>
</html>
