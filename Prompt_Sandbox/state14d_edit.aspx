<%@ Page Language="vb" %>

<%@ Register Assembly="Telerik.Web.UI" Namespace="Telerik.Web.UI" TagPrefix="telerik" %>
<%@ Import Namespace="Prompt" %>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">

<script runat="server">

    Dim nProjectID As Integer
    Private Sub Page_Load(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MyBase.Load

        ProcLib.CheckSession(Page)

        ProcLib.LoadPopupJscript(Page)

        'set up help button
        Session("PageID") = "State14dEdit"
        butHelp.Attributes.Add("onclick", "openPopup('help_view.aspx','pophelp',550,450,'yes');")
        butHelp.NavigateUrl = "#"

        nProjectID = Request.QueryString("ProjectID")

        If IsPostBack Then   'only do the following post back
            nProjectID = lblProjectID.Text
        Else  'only do the following on first load
             
            
            Using rs As New promptProject
                rs.CallingPage = Page
                rs.GetAdditionalProjectData(nProjectID)
            End Using
                
            lblProjectID.Text = nProjectID
        End If
        txtCCCCO_SubmittalDate.Focus()
    End Sub

    
    Private Sub butSave_Click(ByVal sender As System.Object, ByVal e As System.Web.UI.ImageClickEventArgs) Handles butSave.Click

        Using rs As New promptProject
            rs.CallingPage = Page
            rs.SaveSubmittalData(nProjectID)
        End Using
        
        Session("RtnFromEdit") = True
        ProcLib.CloseAndRefresh(Page)
    End Sub

  

</script>

<html>
<head>
    <title>state14d_edit</title>
    <link rel="stylesheet" type="text/css" href="Styles.css" />
</head>
<body>
    <form id="Form1" method="post" runat="server">
    <telerik:RadScriptManager ID="RadScriptManager1" runat="server" />
    <asp:Label ID="Label1" Style="z-index: 100; left: 16px; position: absolute; top: 80px"
        runat="server">Initial Submittal:</asp:Label>
    <asp:Label ID="Label4" Style="z-index: 127; left: 168px; position: absolute; top: 112px"
        runat="server">Budget #:</asp:Label>
    <asp:TextBox ID="txtCCCCO_Equip_BudgetNumber" Style="z-index: 126; left: 160px; position: absolute;
        top: 240px" runat="server" Width="104px" CssClass="EditDataDisplay"></asp:TextBox>
    <asp:TextBox ID="txtCCCCO_Const_BudgetNumber" Style="z-index: 125; left: 160px; position: absolute;
        top: 200px" runat="server" Width="104px" CssClass="EditDataDisplay"></asp:TextBox>
    <asp:TextBox ID="txtCCCCO_WD_BudgetNumber" Style="z-index: 124; left: 160px; position: absolute;
        top: 168px" runat="server" Width="104px" CssClass="EditDataDisplay"></asp:TextBox>
    <table id="Table1" style="z-index: 122; left: 8px; position: absolute; top: 8px;
        height: 2px" cellspacing="1" cellpadding="1" width="96%" border="0">
        <tr height="1">
            <td style="height: 6px" valign="top">
                <asp:Label ID="Label3" runat="server" CssClass="PageHeading" Width="100px" EnableViewState="False"
                    Height="24px">Edit State 14d Info</asp:Label>
            </td>
            <td style="height: 6px" valign="top" align="right">
                <asp:HyperLink ID="butHelp" runat="server" ImageUrl="images/button_help.gif">HyperLink</asp:HyperLink>
            </td>
        </tr>
    </table>
    <hr style="z-index: 119; left: 8px; position: absolute; top: 40px" width="96%" size="1" />
    <telerik:RadDatePicker ID="txtCCCCO_WD_ReleaseDate" Style="z-index: 120; left: 280px;
        position: absolute; top: 168px" TabIndex="5" runat="server" Width="120px" SharedCalendarID="sharedCalendar"
        Skin="Vista">
        <DateInput runat="server" Skin="Vista" Font-Size="13px" ForeColor="Blue">
        </DateInput>
    </telerik:RadDatePicker>
    <telerik:RadDatePicker ID="txtCCCCO_Equip_ReleaseDate" Style="z-index: 118; left: 280px;
        position: absolute; top: 240px" TabIndex="13" runat="server" Width="120px" SharedCalendarID="sharedCalendar"
        Skin="Vista">
        <DateInput runat="server" Skin="Vista" Font-Size="13px" ForeColor="Blue">
        </DateInput>
    </telerik:RadDatePicker>
    <telerik:RadDatePicker ID="txtCCCCO_Const_ReleaseDate" Style="z-index: 117; left: 280px;
        position: absolute; top: 200px" TabIndex="9" runat="server" Width="120px" SharedCalendarID="sharedCalendar"
        Skin="Vista">
        <DateInput runat="server" Skin="Vista" Font-Size="13px" ForeColor="Blue">
        </DateInput>
    </telerik:RadDatePicker>
    <asp:Label ID="lblProjectID" Style="z-index: 114; left: 48px; position: absolute;
        top: 56px" runat="server">9999</asp:Label>
    <asp:Label ID="Label2" Style="z-index: 113; left: 16px; position: absolute; top: 56px"
        runat="server">ID: </asp:Label>
    <asp:CheckBox ID="chkCCCCO_Equip_14D" Style="z-index: 112; left: 53px; position: absolute;
        top: 232px" runat="server" Text="Equipment:" TextAlign="Left" TabIndex="12">
    </asp:CheckBox>
    <asp:CheckBox ID="chkCCCCO_Const_14D" Style="z-index: 111; left: 39px; position: absolute;
        top: 200px" runat="server" Text="Construction: " TextAlign="Left" TabIndex="8">
    </asp:CheckBox>
    <telerik:RadNumericTextBox ID="txtCCCCO_Equip_AmountReleased" Style="z-index: 110;
        left: 420px; position: absolute; top: 240px" runat="server" Width="104px" TabIndex="14"
        SelectionOnFocus="SelectAll" MinValue="0" AutoPostBack="False" NumberFormat-DecimalDigits="2">
        <NumberFormat AllowRounding="True" DecimalDigits="2" PositivePattern="$ n"></NumberFormat>
    </telerik:RadNumericTextBox>
    <asp:Label ID="Label8" Style="z-index: 109; left: 400px; position: absolute; top: 112px"
        runat="server">Release Amount:</asp:Label>
    <telerik:RadNumericTextBox ID="txtCCCCO_Const_AmountReleased" Style="z-index: 108;
        left: 420px; position: absolute; top: 200px" runat="server" Width="104px" TabIndex="11"
        SelectionOnFocus="SelectAll" MinValue="0" AutoPostBack="False" NumberFormat-DecimalDigits="2">
        <NumberFormat AllowRounding="True" DecimalDigits="2" PositivePattern="$ n"></NumberFormat>
    </telerik:RadNumericTextBox>
    <asp:Label ID="Label7" Style="z-index: 107; left: 120px; position: absolute; top: 112px"
        runat="server">14D:</asp:Label>
    <asp:CheckBox ID="chkCCCCO_Prelim_14D" Style="z-index: 106; left: 48px; position: absolute;
        top: 136px" runat="server" Text="Preliminary:        " TextAlign="Left" TabIndex="1">
    </asp:CheckBox>
    <telerik:RadNumericTextBox ID="txtCCCCO_Prelim_AmountReleased" Style="z-index: 105;
        left: 420px; position: absolute; top: 136px" runat="server" Width="104px" TabIndex="3"
        SelectionOnFocus="SelectAll" MinValue="0" AutoPostBack="False" NumberFormat-DecimalDigits="2">
        <NumberFormat AllowRounding="True" DecimalDigits="2" PositivePattern="$ n"></NumberFormat>
    </telerik:RadNumericTextBox>
    <asp:Label ID="Label6" Style="z-index: 104; left: 280px; position: absolute; top: 112px"
        runat="server">Release Date:</asp:Label>
    <telerik:RadNumericTextBox ID="txtCCCCO_WD_AmountReleased" Style="z-index: 102; left: 420px;
        position: absolute; top: 168px" runat="server" Width="104px" TabIndex="6" SelectionOnFocus="SelectAll"
        MinValue="0" AutoPostBack="False" NumberFormat-DecimalDigits="2">
        <NumberFormat AllowRounding="True" DecimalDigits="2" PositivePattern="$ n"></NumberFormat>
    </telerik:RadNumericTextBox>
    <asp:CheckBox ID="chkCCCCO_WD_14D" Style="z-index: 101; left: 11px; position: absolute;
        top: 168px" runat="server" Text="Working Drawings:   " TextAlign="Left" TabIndex="4">
    </asp:CheckBox>
    <telerik:RadDatePicker ID="txtCCCCO_SubmittalDate" Style="z-index: 115; left: 120px;
        position: absolute; top: 80px" runat="server" Width="120px" SharedCalendarID="sharedCalendar"
        Skin="Vista">
        <DateInput runat="server" Skin="Vista" Font-Size="13px" ForeColor="Blue">
        </DateInput>
    </telerik:RadDatePicker>
    <telerik:RadDatePicker ID="txtCCCCO_Prelim_ReleaseDate" Style="z-index: 116; left: 280px;
        position: absolute; top: 136px" TabIndex="2" runat="server" Width="120px" SharedCalendarID="sharedCalendar"
        Skin="Vista">
        <DateInput runat="server" Skin="Vista" Font-Size="13px" ForeColor="Blue">
        </DateInput>
    </telerik:RadDatePicker>
    <asp:ImageButton ID="butSave" Style="z-index: 121; left: 24px; position: absolute;
        top: 288px" runat="server" ImageUrl="images/button_save.gif" TabIndex="20"></asp:ImageButton>
    <asp:TextBox ID="txtCCCCO_Prelim_BudgetNumber" Style="z-index: 123; left: 160px;
        position: absolute; top: 136px" runat="server" Width="104px" CssClass="EditDataDisplay"></asp:TextBox>
    <div style="display: none">
        <telerik:RadCalendar ID="sharedCalendar" Skin="Vista" runat="server" EnableMultiSelect="false">
        </telerik:RadCalendar>
    </div>
    </form>
</body>
</html>
