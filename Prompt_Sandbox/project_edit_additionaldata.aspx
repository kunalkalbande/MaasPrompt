<%@ Page Language="vb" %>

<%@ Import Namespace="Prompt" %>
<%@ Register Assembly="Telerik.Web.UI" Namespace="Telerik.Web.UI" TagPrefix="telerik" %>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">

<script runat="server">
    Dim nProjectID As Integer
    Private Sub Page_Load(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MyBase.Load

        ProcLib.CheckSession(Page)

        ProcLib.LoadPopupJscript(Page)

        'set up help button
        Session("PageID") = "ProjectEditAdditional"
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

        txtPD_Const_OGSF.Focus()
    End Sub


    Private Sub butSave_Click(ByVal sender As System.Object, ByVal e As System.Web.UI.ImageClickEventArgs) Handles butSave.Click
        Using rs As New promptProject
            rs.CallingPage = Page
            rs.SaveAdditionalData(nProjectID)
        End Using
        
        Session("RtnFromEdit") = True
        ProcLib.CloseAndRefresh(Page)

    End Sub


</script>

<html>
<head>
    <title>project_edit_additionaldata</title>
    <meta content="Microsoft Visual Studio .NET 7.1" name="GENERATOR">
    <meta content="Visual Basic .NET 7.1" name="CODE_LANGUAGE">
    <meta content="JavaScript" name="vs_defaultClientScript">
    <meta content="http://schemas.microsoft.com/intellisense/ie5" name="vs_targetSchema">
    <link href="Styles.css" type="text/css" rel="stylesheet">
</head>
<body>
   <form id="Form1" method="post" runat="server">
     <telerik:RadScriptManager ID="RadScriptManager1" runat="server" />
    <table id="Editlist" style="z-index: 103; left: 8px; position: absolute; top: 48px"
        cellspacing="0" cellpadding="0" width="96%" border="0">
        <tr>
            <td width="15%" class="smalltext" style="height: 22px">
                &nbsp;
                <asp:Label ID="Label3" runat="server">ID:</asp:Label>
                <asp:Label ID="lblProjectID" runat="server">999</asp:Label>
            </td>
            <td class="smalltext" align="center" width="19%" style="height: 22px">
                <u>Outside GSF </u>
            </td>
            <td class="smalltext" align="center" width="14%" style="height: 22px">
                <div class="smalltext" align="center">
                    <u>Assignable SQFt </u>
                </div>
            </td>
            <td class="smalltext" align="center" width="18%" style="height: 22px">
                <u>Ratio ASF/GSF </u>
            </td>
            <td class="smalltext" align="center" width="18%" style="height: 22px">
                <u>Unit Cost per ASF </u>
            </td>
            <td class="smalltext" align="center" width="16%" style="height: 22px">
                <u>Unit Cost per GSF </u>
            </td>
        </tr>
        <tr>
            <td class="smalltext" height="23" style="height: 23px" align="right">
                &nbsp;&nbsp;Construction:
            </td>
            <td style="height: 23px">
                <div class="ViewDataDisplay" align="center">
                    &nbsp;
                    <telerik:RadNumericTextBox ID="txtPD_Const_OGSF" runat="server" Width="71px" SelectionOnFocus="SelectAll"
                        MinValue="0" AutoPostBack="False" NumberFormat-DecimalDigits="2">
                        <NumberFormat AllowRounding="True" DecimalDigits="2"></NumberFormat>
                    </telerik:RadNumericTextBox>
                </div>
            </td>
            <td style="height: 23px">
                <div class="ViewDataDisplay" align="center">
                    &nbsp;
                    <telerik:RadNumericTextBox ID="txtPD_Const_ASFT" runat="server" Width="70px" TabIndex="3"
                        SelectionOnFocus="SelectAll" MinValue="0" AutoPostBack="False" NumberFormat-DecimalDigits="2">
                        <NumberFormat AllowRounding="True" DecimalDigits="2"></NumberFormat>
                    </telerik:RadNumericTextBox>
                </div>
            </td>
            <td style="height: 23px">
                <div class="ViewDataDisplay" align="center">
                    &nbsp;
                    <telerik:RadNumericTextBox ID="txtPD_Const_RatioASFGSF" runat="server" Width="70px"
                        TabIndex="5" SelectionOnFocus="SelectAll" MinValue="0" AutoPostBack="False" NumberFormat-DecimalDigits="2">
                        <NumberFormat AllowRounding="True" DecimalDigits="2"></NumberFormat>
                    </telerik:RadNumericTextBox>
                </div>
            </td>
            <td style="height: 23px">
                <div class="ViewDataDisplay" align="center">
                    &nbsp;
                    <telerik:RadNumericTextBox ID="txtPD_Const_UCPASF" runat="server" Width="70px" TabIndex="7"
                        SelectionOnFocus="SelectAll" MinValue="0" AutoPostBack="False" NumberFormat-DecimalDigits="2">
                        <NumberFormat AllowRounding="True" DecimalDigits="2"></NumberFormat>
                    </telerik:RadNumericTextBox>
                </div>
            </td>
            <td style="height: 23px">
                <div class="ViewDataDisplay" align="center">
                    &nbsp;
                    <telerik:RadNumericTextBox ID="txtPD_Const_UCPGSF" runat="server" Width="70px" TabIndex="9"
                        SelectionOnFocus="SelectAll" MinValue="0" AutoPostBack="False" NumberFormat-DecimalDigits="2">
                        <NumberFormat AllowRounding="True" DecimalDigits="2"></NumberFormat>
                    </telerik:RadNumericTextBox>
                </div>
            </td>
        </tr>
        <tr>
            <td class="smalltext" height="32" align="right">
                &nbsp;&nbsp;Reconstruction:
            </td>
            <td>
                <div class="ViewDataDisplay" align="center">
                    &nbsp;
                    <telerik:RadNumericTextBox ID="txtPD_REConst_OGSF" runat="server" Width="70px" TabIndex="1"
                        SelectionOnFocus="SelectAll" MinValue="0" AutoPostBack="False" NumberFormat-DecimalDigits="2">
                        <NumberFormat AllowRounding="True" DecimalDigits="2"></NumberFormat>
                    </telerik:RadNumericTextBox>
                </div>
            </td>
            <td>
                <div class="ViewDataDisplay" align="center">
                    &nbsp;
                    <telerik:RadNumericTextBox ID="txtPD_REConst_ASFT" runat="server" Width="70px" TabIndex="4"
                        SelectionOnFocus="SelectAll" MinValue="0" AutoPostBack="False" NumberFormat-DecimalDigits="2">
                        <NumberFormat AllowRounding="True" DecimalDigits="2"></NumberFormat>
                    </telerik:RadNumericTextBox>
                </div>
            </td>
            <td>
                <div class="ViewDataDisplay" align="center">
                    &nbsp;
                    <telerik:RadNumericTextBox ID="txtPD_REConst_RatioASFGSF" runat="server" Width="70px"
                        TabIndex="6" SelectionOnFocus="SelectAll" MinValue="0" AutoPostBack="False" NumberFormat-DecimalDigits="2">
                        <NumberFormat AllowRounding="True" DecimalDigits="2"></NumberFormat>
                    </telerik:RadNumericTextBox>
                </div>
            </td>
            <td>
                <div class="ViewDataDisplay" align="center">
                    &nbsp;
                    <telerik:RadNumericTextBox ID="txtPD_REConst_UCPASF" runat="server" Width="70px"
                        TabIndex="8" SelectionOnFocus="SelectAll" MinValue="0" AutoPostBack="False" NumberFormat-DecimalDigits="2">
                        <NumberFormat AllowRounding="True" DecimalDigits="2"></NumberFormat>
                    </telerik:RadNumericTextBox>
                </div>
            </td>
            <td>
                <div class="ViewDataDisplay" align="center">
                    &nbsp;
                    <telerik:RadNumericTextBox ID="txtPD_REConst_UCPGSF" runat="server" Width="70px"
                        TabIndex="11" SelectionOnFocus="SelectAll" MinValue="0" AutoPostBack="False"
                        NumberFormat-DecimalDigits="2">
                        <NumberFormat AllowRounding="True" DecimalDigits="2"></NumberFormat>
                    </telerik:RadNumericTextBox>
                </div>
            </td>
        </tr>
    </table>
    <table id="Table2" style="z-index: 119; left: 8px; position: absolute; top: 8px;
        height: 2px" cellspacing="1" cellpadding="1" width="96%" border="0">
        <tr height="1">
            <td style="height: 6px" valign="top">
                <asp:Label ID="Label8" runat="server" CssClass="PageHeading" Width="176px" EnableViewState="False"
                    Height="24px">Edit Additional Project Data</asp:Label>
            </td>
            <td style="height: 6px" valign="top" align="right">
                <asp:HyperLink ID="butHelp" runat="server" ImageUrl="images/button_help.gif">HyperLink</asp:HyperLink>
            </td>
        </tr>
    </table>
    <hr style="z-index: 118; left: 8px; position: absolute; top: 40px" width="96%" size="1" />
    <table id="Table1" style="z-index: 102; left: 8px; position: absolute; top: 152px"
        cellspacing="0" cellpadding="0" width="96%" border="0">
        <tr>
            <td class="smalltext" colspan="4" height="26">
                <strong>Anticipated Time Schedule:</strong>
            </td>
        </tr>
        <tr>
            <td class="smalltext" height="32" style="width: 158px" align="right">
                Start Prelim Plans :
            </td>
            <td class="smalltext" align="center">
                <telerik:RadDatePicker ID="txtATS_StartPrelimPlans" TabIndex="21" runat="server"
                    Width="120px" SharedCalendarID="sharedCalendar" Skin="Vista">
                    <DateInput Skin="Vista" Font-Size="13px" ForeColor="Blue">
                    </DateInput>
                </telerik:RadDatePicker>
            </td>
            <td class="smalltext" align="right">
                Advertise Bid For Construction :
            </td>
            <td class="smalltext" align="center">
                <telerik:RadDatePicker ID="txtATS_AdvertiseBidConst" TabIndex="25" runat="server"
                    Width="120px" SharedCalendarID="sharedCalendar" Skin="Vista">
                    <DateInput Skin="Vista" Font-Size="13px" ForeColor="Blue">
                    </DateInput>
                </telerik:RadDatePicker>
            </td>
        </tr>
        <tr>
            <td height="37" class="smalltext" style="width: 158px" align="right">
                Start Wking Drawings :
            </td>
            <td height="37" class="smalltext" align="center">
                <telerik:RadDatePicker ID="txtATS_StartWrkDrawings" TabIndex="22" runat="server"
                    Width="120px" SharedCalendarID="sharedCalendar" Skin="Vista">
                    <DateInput Skin="Vista" Font-Size="13px" ForeColor="Blue">
                    </DateInput>
                </telerik:RadDatePicker>
            </td>
            <td class="smalltext" align="right">
                Award Construction Contract :
            </td>
            <td class="smalltext" align="center">
                <telerik:RadDatePicker ID="txtATS_AwardConstContract" TabIndex="26" runat="server"
                    Width="120px" SharedCalendarID="sharedCalendar" Skin="Vista">
                    <DateInput runat="server" Skin="Vista" Font-Size="13px" ForeColor="Blue">
                    </DateInput>
                </telerik:RadDatePicker>
            </td>
        </tr>
        <tr>
            <td height="35" class="smalltext" style="width: 158px" align="right">
                Complete Wking Drawings :
            </td>
            <td height="35" class="smalltext" align="center">
                <telerik:RadDatePicker ID="txtATS_CompleteWrkDrawings" TabIndex="23" runat="server"
                    Width="120px" SharedCalendarID="sharedCalendar" Skin="Vista">
                    <DateInput  runat="server" Skin="Vista" Font-Size="13px" ForeColor="Blue">
                    </DateInput>
                </telerik:RadDatePicker>
            </td>
            <td class="smalltext" align="right">
                Advertise Bid for Equipment :
            </td>
            <td class="smalltext" align="center">
                <telerik:raddatepicker id="txtATS_AdvertiseBidEquip" tabindex="27" runat="server" width="120px"
                    sharedcalendarid="sharedCalendar" skin="Vista">
        <DateInput Skin="Vista"  runat="server" Font-Size="13px" ForeColor="Blue"></DateInput>
                </telerik:RadDatePicker>
            </td>
        </tr>
        <tr>
            <td height="38" class="smalltext" style="width: 158px" align="right">
                DSA Final Approval :
            </td>
            <td height="38" class="smalltext" align="center">
                <telerik:raddatepicker id="txtATS_DSAFinalApproval" tabindex="24" runat="server" width="120px"
                    sharedcalendarid="sharedCalendar" skin="Vista">
        <DateInput Skin="Vista"  runat="server" Font-Size="13px" ForeColor="Blue"></DateInput>
                </telerik:RadDatePicker>
            </td>
            <td class="smalltext" align="right">
                Complete Project :
            </td>
            <td class="smalltext" align="center">
                <telerik:raddatepicker id="txtATS_CompleteProject" tabindex="28" runat="server" width="120px"
                    sharedcalendarid="sharedCalendar" skin="Vista">
        <DateInput Skin="Vista"  runat="server" Font-Size="13px" ForeColor="Blue"></DateInput>
                </telerik:RadDatePicker>
            </td>
        </tr>
    </table>
    <div style="display: none">
        <telerik:RadCalendar ID="sharedCalendar" Skin="Vista" runat="server" EnableMultiSelect="false">
        </telerik:RadCalendar>
    </div>
    <asp:ImageButton ID="butSave" Style="z-index: 104; left: 24px; position: absolute;
        top: 336px" runat="server" ImageUrl="images/button_save.gif" TabIndex="50"></asp:ImageButton>
    </form>
</body>
</html>
