<%@ Page Language="vb" %>

<%@ Import Namespace="System.IO" %>
<%@ Import Namespace="System.IO.FileSystemInfo" %>
<%@ Import Namespace="Prompt" %>
<%@ Register Assembly="Telerik.Web.UI" Namespace="Telerik.Web.UI" TagPrefix="telerik" %>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">

<script runat="server">

    Public nCollegeID As Integer = 0
    Public nDistrictID As Integer = 0
    Public nClientID As Integer = 0
    
    Private Sub Page_Load(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MyBase.Load

        ProcLib.CheckSession(Page)
        ProcLib.LoadPopupJscript(Page)

        'set up help button
        Session("PageID") = "CollegeEdit"
        butHelp.Attributes.Add("onclick", "openPopup('help_view.aspx','pophelp',550,450,'yes');")
        butHelp.NavigateUrl = "#"

        Dim strRealPhotoPath As String

        nCollegeID = Request.QueryString("CollegeID")
        nDistrictID = Request.QueryString("DistrictID")
        nClientID = Request.QueryString("ClientID")

        If IsPostBack Then   'only do the following post back
            nCollegeID = lblCollegeID.Text
        Else  'only do the following on first load
            Using db As New College
                db.CallingPage = Page
                If nCollegeID = 0 Then    'add the new record
                    butDelete.Visible = False
                End If
                db.GetCollegeForEdit(nCollegeID, nDistrictID)
                lblCollegeID.Text = nCollegeID
            End Using
        End If
                
        ''logo
        'strRealPhotoPath = ProcLib.GetCurrentAttachmentPath()
        'strRealPhotoPath = strRealPhotoPath & "DistrictID_" & nDistrictID & "\CollegeID_" & nCollegeID & "\"
        'strRealPhotoPath = strRealPhotoPath & "_collegelogo_.jpg"
        'Dim filem As New FileInfo(strRealPhotoPath)
        'If Not filem.Exists Then  'show none
        '    imgLogo.ImageUrl = "images/none.gif"
        'Else
        '    imgLogo.ImageUrl = ProcLib.GetCurrentRelativeAttachmentPath() & "DistrictID_" & nDistrictID & "/CollegeID_" & nCollegeID & "/_collegelogo_.jpg"
        'End If
        'imgLogo.Width = Unit.Pixel(60)
        'imgLogo.Height = Unit.Pixel(60)
        'With lnkUpload
        '    .Attributes.Add("onclick", "openPopup('apprise_photo_upload.aspx?logo=y&CollegeID=" & nCollegeID & "','photoedit',450,450,'yes');")
        '    .Text = "Upload"
        '    .ImageUrl = "images/button_upload_file.gif"
        '    .NavigateUrl = "#"  'dummy value so that link line shows
        'End With

        txtCollege.Focus()
        
    End Sub

  
    Private Sub butSave_Click(ByVal sender As System.Object, ByVal e As System.Web.UI.ImageClickEventArgs) Handles butSave.Click
        
        Using db As New College
            db.CallingPage = Page
            db.SaveCollege(nCollegeID, nDistrictID, nClientID)
        End Using
       
        ProcLib.CloseAndRefreshRADNoPrompt(Page)
 
    End Sub

    Private Sub butDelete_Click(ByVal sender As System.Object, ByVal e As System.Web.UI.ImageClickEventArgs) Handles butDelete.Click
      
        Dim msg As String = ""
        Using db As New College
            msg = db.DeleteCollege(nCollegeID)
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
    <title>College Edit</title>
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
    <asp:TextBox ID="txtCollege" Style="z-index: 100; left: 122px; position: absolute;
        top: 71px" runat="server" CssClass="EditDataDisplay" EnableViewState="False"
        Width="192px"></asp:TextBox>
    <asp:Label ID="Label5" Style="z-index: 101; left: 20px; position: absolute; top: 518px"
        runat="server" CssClass="FieldLabel" EnableViewState="False" Height="24px">Lock Transactions Dated Before:</asp:Label>
    <asp:Label ID="Label26" runat="server" CssClass="FieldLabel" EnableViewState="False"
        Height="24px" Style="z-index: 102; left: 20px; position: absolute; top: 458px">Current Budget Batch:</asp:Label>
    <asp:Label ID="lblCurrentBudgetBatch" runat="server" CssClass="ViewDataDisplay" EnableViewState="False"
        Style="z-index: 103; left: 142px; position: absolute; top: 458px">Test Batch 2007</asp:Label>
    &nbsp; &nbsp;&nbsp;
    <asp:ImageButton ID="butDelete" Style="z-index: 104; left: 201px; position: absolute;
        top: 682px" TabIndex="99" runat="server" ImageUrl="images/button_delete.gif">
    </asp:ImageButton>
    <asp:ImageButton ID="butSave" Style="z-index: 105; left: 20px; position: absolute;
        top: 683px" TabIndex="50" runat="server" ImageUrl="images/button_save.gif"></asp:ImageButton>
    <asp:Label ID="lblCollegeID" Style="z-index: 106; left: 49px; position: absolute;
        top: 48px" runat="server" CssClass="ViewDataDisplay" Height="8px">999</asp:Label>
    <asp:Label ID="Label4" Style="z-index: 107; left: 20px; position: absolute; top: 48px"
        runat="server" CssClass="FieldLabel" EnableViewState="False" Height="8px">ID:</asp:Label>
    <asp:TextBox ID="txtAppriseHomeLink" Style="z-index: 109; left: 139px; position: absolute;
        top: 631px" TabIndex="46" runat="server" CssClass="EditDataDisplay" EnableViewState="False"
        Width="223px"></asp:TextBox>
    <asp:Label ID="Label2" Style="z-index: 110; left: 19px; position: absolute; top: 630px"
        runat="server" CssClass="FieldLabel" EnableViewState="False" Height="24px">College Home Link:</asp:Label>
    <asp:TextBox ID="txtCollegeLogoImageURL" Style="z-index: 111; left: 140px; position: absolute;
        top: 588px" TabIndex="45" runat="server" CssClass="EditDataDisplay" EnableViewState="False"
        Width="400px"></asp:TextBox>
    <asp:Label ID="Label1" Style="z-index: 112; left: 20px; position: absolute; top: 589px"
        runat="server" CssClass="FieldLabel" EnableViewState="False" Height="24px">College Logo Image:</asp:Label>
    <asp:Label ID="lblCollegeName" Style="z-index: 113; left: 20px; position: absolute;
        top: 71px" runat="server" CssClass="FieldLabel" EnableViewState="False" Height="24px">College Name:</asp:Label>
    <table id="Table1" style="z-index: 157; left: 16px; position: absolute; top: 8px;
        height: 2px" cellspacing="1" cellpadding="1" width="96%" border="0">
        <tr height="1">
            <td style="height: 6px" valign="top">
                <asp:Label ID="Label8" runat="server" CssClass="PageHeading" EnableViewState="False"
                    Width="88px" Height="24px">Edit College</asp:Label>
            </td>
            <td style="height: 6px" valign="top" align="right">
                <asp:HyperLink ID="butHelp" runat="server" ImageUrl="images/button_help.gif">HyperLink</asp:HyperLink>
            </td>
        </tr>
    </table>
    <hr style="z-index: 158; left: 16px; position: absolute; top: 40px" width="96%" size="1">
    <telerik:RadDatePicker ID="txtLastFiscalYearEnd" Style="z-index: 116; left: 201px;
        position: absolute; top: 520px" runat="server" Width="120px">
        <DateInput runat="server" Skin="WebBlue" Font-Size="13px" ForeColor="Blue">
        </DateInput>
    </telerik:RadDatePicker>
    <asp:CheckBox Style="z-index: 117; left: 20px; position: absolute; top: 486px" ID="chkLockCurrentProjectBudgets"
        runat="server" Text="Lock Current Project Budgets:" TextAlign="Left" TabIndex="40" />
    <asp:CheckBox Style="z-index: 118; left: 20px; position: absolute; top: 550px" ID="chkTrackJCAFBudgetChanges"
        runat="server" Text="Track JCAF Budget Changes:" TextAlign="Left" TabIndex="40"
        ToolTip="Turns on the logging of changes made to JCAF budget items." />
    <asp:CheckBox Style="z-index: 119; left: 246px; position: absolute; top: 551px" ID="chkTurnOffValidation"
        runat="server" Text="Turn Off Validation:" TextAlign="Left" TabIndex="40" ToolTip="Turns off Validation on Transaction Edit Screen." />
    <telerik:RadNumericTextBox ID="txtSeries4Amt" runat="server" Style="z-index: 121;
        left: 379px; position: absolute; top: 266px" TabIndex="15" SelectionOnFocus="SelectAll"
        MinValue="0" AutoPostBack="False" NumberFormat-DecimalDigits="2">
        <NumberFormat AllowRounding="True" DecimalDigits="2" PositivePattern="$ n"></NumberFormat>
    </telerik:RadNumericTextBox>
    <telerik:RadNumericTextBox ID="txtSeries3Amt" runat="server" Style="z-index: 122;
        left: 126px; position: absolute; top: 264px" TabIndex="14" SelectionOnFocus="SelectAll"
        MinValue="0" AutoPostBack="False" NumberFormat-DecimalDigits="2">
        <NumberFormat AllowRounding="True" DecimalDigits="2" PositivePattern="$ n"></NumberFormat>
    </telerik:RadNumericTextBox>
    <telerik:RadNumericTextBox ID="txtSeries2Amt" runat="server" Style="z-index: 123;
        left: 378px; position: absolute; top: 238px" TabIndex="13" SelectionOnFocus="SelectAll"
        MinValue="0" AutoPostBack="False" NumberFormat-DecimalDigits="2">
        <NumberFormat AllowRounding="True" DecimalDigits="2" PositivePattern="$ n"></NumberFormat>
    </telerik:RadNumericTextBox>
    <telerik:RadNumericTextBox ID="txtSeries1Amt" runat="server" Style="z-index: 124;
        left: 126px; position: absolute; top: 238px" TabIndex="12" SelectionOnFocus="SelectAll"
        MinValue="0" AutoPostBack="False" NumberFormat-DecimalDigits="2">
        <NumberFormat AllowRounding="True" DecimalDigits="2" PositivePattern="$ n"></NumberFormat>
    </telerik:RadNumericTextBox>
    <telerik:RadNumericTextBox ID="txtStateFundAnticipated" runat="server" Style="z-index: 125;
        left: 178px; position: absolute; top: 208px" TabIndex="9" SelectionOnFocus="SelectAll"
        MinValue="0" AutoPostBack="False" NumberFormat-DecimalDigits="2">
        <NumberFormat AllowRounding="True" DecimalDigits="2" PositivePattern="$ n"></NumberFormat>
    </telerik:RadNumericTextBox>
    <asp:Label ID="Label9" runat="server" CssClass="smalltext" Height="16px" Style="z-index: 126;
        left: 281px; position: absolute; top: 265px">Series 4 Amount:</asp:Label>
    <asp:Label ID="Label7" runat="server" CssClass="smalltext" Height="16px" Style="z-index: 127;
        left: 20px; position: absolute; top: 266px">Series 3 Amount:</asp:Label>
    <asp:Label ID="Label6" runat="server" CssClass="smalltext" Height="16px" Style="z-index: 128;
        left: 281px; position: absolute; top: 239px">Series 2 Amount:</asp:Label>
    <asp:Label ID="Label10" runat="server" CssClass="smalltext" Height="16px" Style="z-index: 129;
        left: 20px; position: absolute; top: 209px">State Funding Anticipated:</asp:Label>
    <asp:Label ID="Label11" runat="server" CssClass="smalltext" Height="16px" Style="z-index: 130;
        left: 20px; position: absolute; top: 239px">Series 1 Amount:</asp:Label>
    <asp:Label ID="Label21" runat="server" CssClass="smalltext" Height="16px" Style="z-index: 131;
        left: 20px; position: absolute; top: 178px">Bond Amount:</asp:Label>
    <asp:Label ID="Label22" runat="server" CssClass="smalltext" Height="16px" Style="z-index: 132;
        left: 20px; position: absolute; top: 144px">Bond Program Name:</asp:Label>
    <asp:Label ID="Label15" runat="server" CssClass="smalltext" Height="16px" Style="z-index: 133;
        left: 310px; position: absolute; top: 179px">Current Series:</asp:Label>
    <asp:Label ID="Label12" runat="server" CssClass="smalltext" Font-Underline="True"
        Height="16px" Style="z-index: 134; left: 20px; position: absolute; top: 303px">Fund Codes</asp:Label>
    <asp:Label ID="Label25" runat="server" CssClass="smalltext" Font-Underline="True"
        Height="16px" Style="z-index: 135; left: 20px; position: absolute; top: 425px">Budget Information</asp:Label>
    <asp:Label ID="Label24" runat="server" CssClass="smalltext" Font-Underline="True"
        Height="16px" Style="z-index: 137; left: 20px; position: absolute; top: 114px">Bond Information</asp:Label>
    <asp:Label ID="Label13" runat="server" CssClass="smalltext" Height="16px" Style="z-index: 138;
        left: 20px; position: absolute; top: 326px">State:</asp:Label>
    <asp:Label ID="Label14" runat="server" CssClass="smalltext" Height="16px" Style="z-index: 139;
        left: 163px; position: absolute; top: 325px">District State Supp:</asp:Label>
    <asp:Label ID="Label23" runat="server" CssClass="smalltext" Height="25px" Style="z-index: 140;
        left: 294px; position: absolute; top: 314px" Width="86px">District Non State Supp:</asp:Label>
    <asp:Label ID="Label16" runat="server" CssClass="smalltext" Height="16px" Style="z-index: 141;
        left: 425px; position: absolute; top: 324px">Bond:</asp:Label>
    <asp:Label ID="Label17" runat="server" CssClass="smalltext" Height="16px" Style="z-index: 142;
        left: 20px; position: absolute; top: 372px">Grant:</asp:Label>
    <asp:Label ID="Label18" runat="server" CssClass="smalltext" Height="16px" Style="z-index: 143;
        left: 161px; position: absolute; top: 373px">Hazmat:</asp:Label>
    <asp:Label ID="Label19" runat="server" CssClass="smalltext" Height="16px" Style="z-index: 144;
        left: 291px; position: absolute; top: 371px">Sched Maint:</asp:Label>
    <asp:Label ID="Label20" runat="server" CssClass="smalltext" Height="16px" Style="z-index: 145;
        left: 423px; position: absolute; top: 371px">Donation:</asp:Label>
    <asp:TextBox ID="txtBondProgramName" runat="server" CssClass="EditDataDisplay" Style="z-index: 146;
        left: 134px; position: absolute; top: 143px" Width="336px" TabIndex="2"></asp:TextBox>
    <asp:TextBox ID="txtFundCodeSF" runat="server" CssClass="EditDataDisplay" Style="z-index: 147;
        left: 20px; position: absolute; top: 346px" TabIndex="22" Width="110px"></asp:TextBox>
    <asp:TextBox ID="txtFundCodeDFSS" runat="server" CssClass="EditDataDisplay" Style="z-index: 148;
        left: 161px; position: absolute; top: 345px" TabIndex="23" Width="110px"></asp:TextBox>
    <asp:TextBox ID="txtFundCodeDFNSS" runat="server" CssClass="EditDataDisplay" Style="z-index: 149;
        left: 295px; position: absolute; top: 344px" TabIndex="24" Width="110px"></asp:TextBox>
    <asp:TextBox ID="txtFundCodeBond" runat="server" CssClass="EditDataDisplay" Style="z-index: 150;
        left: 424px; position: absolute; top: 343px" TabIndex="25" Width="110px"></asp:TextBox>
    <asp:TextBox ID="txtFundCodeGrant" runat="server" CssClass="EditDataDisplay" Style="z-index: 151;
        left: 20px; position: absolute; top: 391px" TabIndex="26" Width="110px"></asp:TextBox>
    <asp:TextBox ID="txtFundCodeHazmat" runat="server" CssClass="EditDataDisplay" Style="z-index: 152;
        left: 160px; position: absolute; top: 390px" TabIndex="27" Width="110px"></asp:TextBox>
    <asp:TextBox ID="txtFundCodeMaint" runat="server" CssClass="EditDataDisplay" Style="z-index: 153;
        left: 294px; position: absolute; top: 390px" TabIndex="28" Width="110px"></asp:TextBox>
    <asp:TextBox ID="txtFundCodeDonation" runat="server" CssClass="EditDataDisplay" Style="z-index: 154;
        left: 424px; position: absolute; top: 390px" TabIndex="29" Width="110px"></asp:TextBox>
    <asp:DropDownList ID="lstCurrentSeriesNumber" runat="server" CssClass="EditDataDisplay"
        Style="z-index: 155; left: 400px; position: absolute; top: 180px" TabIndex="5">
    </asp:DropDownList>
    <telerik:RadNumericTextBox ID="txtBondAmount" runat="server" CssClass="CurrencyTextBox"
        Style="z-index: 156; left: 134px; position: absolute; top: 179px" TabIndex="3"
       SelectionOnFocus="SelectAll"
        MinValue="0" AutoPostBack="False" NumberFormat-DecimalDigits="2">
        <NumberFormat AllowRounding="True" DecimalDigits="2" PositivePattern="$ n"></NumberFormat>
    </telerik:RadNumericTextBox>
    &nbsp;
    </form>
</body>
</html>
