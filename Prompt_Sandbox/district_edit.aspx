<%@ Page Language="vb" %>

<%@ Import Namespace="Prompt" %>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">

<script runat="server">
    Public nDistrictID As Integer = 0
    Public nClientID As Integer = 0
    Private Sub Page_Load(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MyBase.Load


        ProcLib.CheckSession(Page)
        ProcLib.LoadPopupJscript(Page)

        'set up help button
        Session("PageID") = "DistrictEdit"
        butHelp.Attributes.Add("onclick", "openPopup('help_view.aspx','pophelp',550,450,'yes');")
        butHelp.NavigateUrl = "#"


        nDistrictID = Request.QueryString("DistrictID")
        nClientID = Request.QueryString("ClientID")
        
        Using rs As New District

            If IsPostBack Then   'only do the following post back
                nDistrictID = lblDistrictID.Text
            Else  'only do the following on first load

                If nDistrictID = 0 Then    'add the new record
                    butDelete.Visible = False
                End If
                With rs
                    .CallingPage = Page
                    .GetDistrictForEdit(nDistrictID)  'NOTE: Fills the dropdowns but returns new record when id = 0
                End With
            End If
            lblDistrictID.Text = nDistrictID
        End Using
        txtName.Focus()
    End Sub

    Private Sub butSave_Click(ByVal sender As System.Object, ByVal e As System.Web.UI.ImageClickEventArgs) Handles butSave.Click
        
        
        Using rs As New District
            With rs
                .CallingPage = Page
                .SaveDistrict(nDistrictID, nClientID)
            End With
        End Using

        ProcLib.CloseAndRefreshRADNoPrompt(Page)
    End Sub
  
    Private Sub butDelete_Click(ByVal sender As System.Object, ByVal e As System.Web.UI.ImageClickEventArgs) Handles butDelete.Click
        
        Dim msg As String = ""
        Using db As New District
            msg = db.DeleteDistrict(nDistrictID)
        End Using
        If msg <> "" Then
            Response.Redirect("delete_error.aspx?msg=" & msg)
        Else
            ProcLib.CloseAndRefreshRADNoPrompt(Page)
        End If
        
    End Sub



</script>

<html>
<head>
    <title>District Edit</title>
    <link rel="stylesheet" type="text/css" href="Styles.css" />
        
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
    <asp:TextBox ID="txtName" Style="z-index: 100; left: 104px; position: absolute; top: 71px;
        width: 166px;" runat="server" EnableViewState="False" CssClass="EditDataDisplay"></asp:TextBox>
    &nbsp;
    <asp:CheckBox ID="chkShowProjectNumberInMenu" Style="z-index: 101; left: 13px; position: absolute;
        top: 303px" TabIndex="4" runat="server" Text="Show Project # In Nav Menu"></asp:CheckBox>
    <asp:Label ID="lblDistrictID" Style="z-index: 104; left: 50px; position: absolute;
        top: 47px" runat="server" Height="8px" CssClass="FieldLabel">99999</asp:Label>
    <asp:Label ID="Label1" Style="z-index: 105; left: 20px; position: absolute; top: 46px"
        runat="server" EnableViewState="False" Height="8px" CssClass="FieldLabel">ID:</asp:Label>
    <asp:Label ID="Label7" Style="z-index: 106; left: 16px; position: absolute; top: 71px"
        runat="server" EnableViewState="False" CssClass="FieldLabel" Height="24px">District Name:</asp:Label>
    <table id="Table1" style="z-index: 113; left: 16px; position: absolute; top: 8px;
        height: 2px" cellspacing="1" cellpadding="1" border="0" width="96%">
        <tr height="1">
            <td style="height: 6px" valign="top">
                <asp:Label ID="Label8" runat="server" EnableViewState="False" Width="88px" CssClass="PageHeading"
                    Height="24px">Edit District</asp:Label>
            </td>
            <td style="height: 6px" valign="top" align="right">
                <asp:HyperLink ID="butHelp" runat="server" ImageUrl="images/button_help.gif">HyperLink</asp:HyperLink>
            </td>
        </tr>
    </table>
    <hr style="z-index: 114; left: 16px; position: absolute; top: 40px" width="95%" size="1">
    <asp:DropDownList ID="lstFiscalYear" runat="server" CssClass="EditDataDisplay" Style="z-index: 108;
        left: 354px; position: absolute; top: 71px" TabIndex="13">
    </asp:DropDownList>
    <asp:CheckBox ID="chkIncludeAllObjectCodesInJCAF" Style="z-index: 109; left: 15px;
        position: absolute; top: 325px" TabIndex="4" runat="server" 
        Text="Include All Object Codes in JCAF Budgets">
    </asp:CheckBox>
    <asp:CheckBox ID="chkAllowChangingTransactionObjectCode" Style="z-index: 110; left: 13px;
        position: absolute; top: 351px" TabIndex="4" runat="server" 
        Text="Allow Users to change Object Codes on Transactions">
    </asp:CheckBox>
    <p>
        <asp:CheckBox ID="chkInActive" Style="z-index: 115; left: 322px; position: absolute;
            top: 305px" TabIndex="4" runat="server" Text="InActive"></asp:CheckBox>
        <asp:CheckBox ID="chkUsePromptName" Style="z-index: 115; left: 12px; position: absolute;
            top: 405px" TabIndex="4" runat="server" Text="Use PROMPT Name" 
            ToolTip="Will use PROMPT Logo for screens reports rather than EISPro"></asp:CheckBox>
        <asp:CheckBox ID="chkEnableWorkflowDataTransfer" Style="z-index: 115; left: 178px; position: absolute;
            top: 428px; width: 243px;" TabIndex="4" runat="server" 
            Text="Enable Workflow Data Transfer"></asp:CheckBox>
    </p>
    <p>
        &nbsp;</p>
    <p>
        <asp:Label ID="Label23" runat="server" Style="z-index: 107; left: 281px; position: absolute;
            top: 75px">Fiscal Year:</asp:Label>
    </p>
    <p>
        <asp:ImageButton ID="butDelete" Style="z-index: 102; left: 298px; position: absolute;
            top: 464px" TabIndex="6" runat="server" 
            OnClientClick="return confirm('You are about to delte this district.\nAre you sure you want to continue with the district delete?')"
            ImageUrl="images/button_delete.gif">
        </asp:ImageButton>
    </p>
    <asp:CheckBox ID="chkDisableTransactionAllocationObjectCodeFiltering" runat="server"
        Style="z-index: 111; left: 11px; position: absolute; top: 379px" TabIndex="4"
        
        Text="Disable Filtering of Transaction Allocation Lines by JCAF Object Code">
    </asp:CheckBox>
    <asp:Label ID="Label2" 
        Style="z-index: 106; left: 17px; position: absolute; top: 100px;
        right: 1350px; width: 162px; font-weight: 700; text-decoration: underline;" 
        runat="server" EnableViewState="False" CssClass="FieldLabel"
        Height="24px">JCAF 
        Column Names:</asp:Label>
    <asp:TextBox ID="txtJCAFMaintColumnName" Style="z-index: 100; left: 22px; position: absolute;
        top: 178px; width: 130px;" runat="server" EnableViewState="False" 
        CssClass="EditDataDisplay"></asp:TextBox>
    <asp:TextBox ID="txtFourthBondSeriesName" Style="z-index: 100; left: 207px; position: absolute;
        top: 275px; width: 130px;" runat="server" EnableViewState="False" 
        CssClass="EditDataDisplay"></asp:TextBox>
    <asp:TextBox ID="txtThirdBondSeriesName" Style="z-index: 100; left: 207px; position: absolute;
        top: 223px; width: 130px;" runat="server" EnableViewState="False" 
        CssClass="EditDataDisplay"></asp:TextBox>
    <asp:TextBox ID="txtSecondBondSeriesName" Style="z-index: 100; left: 207px; position: absolute;
        top: 182px; width: 130px;" runat="server" EnableViewState="False" 
        CssClass="EditDataDisplay"></asp:TextBox>
    <asp:TextBox ID="txtFirstBondSeriesName" Style="z-index: 100; left: 207px; position: absolute;
        top: 141px; width: 130px;" runat="server" EnableViewState="False" 
        CssClass="EditDataDisplay" ></asp:TextBox>
    <asp:TextBox ID="txtJCAFDonationColumnName" Style="z-index: 100; left: 21px; position: absolute;
        top: 138px; width: 130px;" runat="server" EnableViewState="False" CssClass="EditDataDisplay"></asp:TextBox>
    <asp:TextBox ID="txtJCAFGrantColumnName" Style="z-index: 100; left: 21px; position: absolute;
        top: 274px; width: 130px;" runat="server" EnableViewState="False" 
        CssClass="EditDataDisplay"></asp:TextBox>
    <asp:TextBox ID="txtJCAFHazmatColumnName" Style="z-index: 100; left: 20px; position: absolute;
        top: 224px; width: 130px;" runat="server" EnableViewState="False" 
        CssClass="EditDataDisplay"></asp:TextBox>
    <asp:Label ID="Label27" Style="z-index: 106; left: 20px; position: absolute; top: 164px;
        right: 1472px;" runat="server" EnableViewState="False" CssClass="FieldLabel"
        Height="24px">Maint:</asp:Label>
    <asp:Label ID="Label26" Style="z-index: 106; left: 21px; position: absolute; top: 253px;
        right: 1473px;" runat="server" EnableViewState="False" CssClass="FieldLabel"
        Height="24px">Grant:</asp:Label>
    <asp:Label ID="Label31" Style="z-index: 106; left: 208px; position: absolute; top: 254px;
        right: 1123px; width: 187px;" runat="server" EnableViewState="False" CssClass="FieldLabel"
        Height="24px">Fourth Series Name:</asp:Label>
    <asp:Label ID="Label33" Style="z-index: 106; left: 208px; position: absolute; top: 164px;
        right: 1111px; width: 199px;" runat="server" EnableViewState="False" CssClass="FieldLabel"
        Height="24px">Second Series Name:</asp:Label>
    <asp:Label ID="Label32" Style="z-index: 106; left: 208px; position: absolute; top: 120px;
        right: 1139px; width: 171px;" runat="server" EnableViewState="False" CssClass="FieldLabel"
        Height="24px">First Series Name:</asp:Label>
    <asp:Label ID="Label30" Style="z-index: 106; left: 208px; position: absolute; top: 205px;
        right: 1105px; width: 205px;" runat="server" EnableViewState="False" CssClass="FieldLabel"
        Height="24px">Third Series Name:</asp:Label>
    <asp:Label ID="Label25" Style="z-index: 106; left: 21px; position: absolute; top: 205px;
        right: 1461px;" runat="server" EnableViewState="False" CssClass="FieldLabel"
        Height="24px">Hazmat:</asp:Label>
    <asp:Label ID="Label24" Style="z-index: 106; left: 19px; position: absolute; top: 120px;
        right: 1461px;" runat="server" EnableViewState="False" CssClass="FieldLabel"
        Height="24px">Donation:</asp:Label>
    <asp:ImageButton ID="butSave" Style="z-index: 103; left: 19px; position: absolute;
        top: 465px;" TabIndex="5" runat="server" ImageUrl="images/button_save.gif"></asp:ImageButton>
    <p>
        <asp:CheckBox ID="chkEnableWorkflow" Style="z-index: 115; left: 178px; position: absolute;
            top: 404px" TabIndex="4" runat="server" Text="Enable Workflow"></asp:CheckBox>
    </p>
    <asp:Label ID="Label3" 
        Style="z-index: 106; left: 213px; position: absolute; top: 104px;
        right: 1151px; width: 162px; font-weight: 700; text-decoration: underline;" 
        runat="server" EnableViewState="False" CssClass="FieldLabel"
        Height="24px">JCAF 
        Bond Series Names:</asp:Label>    
    <p>
        &nbsp;</p>
    </form>
</body>
</html>
