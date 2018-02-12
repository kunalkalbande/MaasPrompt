<%@ Page Language="vb" %>

<%@ Register Assembly="Telerik.Web.UI" Namespace="Telerik.Web.UI" TagPrefix="telerik" %>
<%@ Import Namespace="Prompt" %>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">

<script runat="server">

    Private nProcurementID As Integer = 0
    Private nProjectID As Integer = 0
    Private strPhysicalPath As String = ""

    Private Sub Page_Load(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MyBase.Load

        ProcLib.CheckSession(Page)
        ProcLib.LoadPopupJscript(Page)

        Session("PageID") = "ProcurementEdit"
        
        lblMessage.Text = ""

        nProcurementID = Request.QueryString("ProcurementID")
        nProjectID = Request.QueryString("ProjectID")
     
        'set up help button
        butHelp.Attributes.Add("onclick", "openPopup('help_view.aspx','pophelp',550,450,'yes');")
        butHelp.NavigateUrl = "#"
        
  
        If Not IsPostBack Then
            Using db As New ProcurementLog
                db.CallingPage = Page
                If nProcurementID = 0 Then
                    butDelete.Visible = False
                End If
                db.GetProcurementForEdit(nProcurementID)
                
            End Using
        End If
        
        lblxProcurementID.Text = nProcurementID

        cboSpecificationPackage.Focus()

    End Sub
    

    Private Sub butSave_Click(ByVal sender As System.Object, ByVal e As System.Web.UI.ImageClickEventArgs) Handles butSave.Click
    
        If txtRequiredDate.SelectedDate Is Nothing Then
            lblMessage.Text = "Please enter a Date Required Date."
            Exit Sub
        End If
        If txtDescription.Text = "" Then
            lblMessage.Text = "Please enter a Description."
            Exit Sub
        End If
 
        Using db As New ProcurementLog
            db.CallingPage = Page
            db.SaveProcurement(nProjectID, nProcurementID)

        End Using

        Session("RtnFromEdit") = True
        ProcLib.CloseAndRefreshRADNoPrompt(Page)
    End Sub

    Private Sub butDelete_Click(ByVal sender As System.Object, ByVal e As System.Web.UI.ImageClickEventArgs) Handles butDelete.Click
       
        Using db As New ProcurementLog
            db.CallingPage = Page
            db.DeleteProcurement(nProjectID, nProcurementID)
        End Using

        Session("RtnFromEdit") = True
        ProcLib.CloseAndRefreshRADNoPrompt(Page)
    End Sub

  
</script>

<html>
<head>
    <title>Procurement Edit</title>
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
    <asp:HyperLink ID="butHelp" Style="z-index: 112; left: 539px; position: absolute;
        top: 14px; height: 20px;" runat="server" ImageUrl="images/button_help.gif">HyperLink</asp:HyperLink>
    <asp:ImageButton ID="butSave" Style="z-index: 113; left: 12px; position: absolute;
        top: 388px" TabIndex="50" runat="server" ImageUrl="images/button_save.gif"></asp:ImageButton>
    <asp:ImageButton ID="butDelete" Style="z-index: 107; left: 337px; position: absolute;
        top: 388px" TabIndex="60" runat="server" ImageUrl="images/button_delete.gif">
    </asp:ImageButton>
    <asp:Label ID="lblMessage" Style="z-index: 105; left: 16px; position: absolute; top: 358px"
        runat="server" Height="24px" Font-Bold="True" ForeColor="Red">Error Message</asp:Label>
    <asp:Label ID="Label19" Style="z-index: 105; left: 304px; position: absolute; top: 204px;
        right: 870px; width: 110px;" runat="server" Height="24px">Contact Phone:</asp:Label>
    <asp:Label ID="Label16" Style="z-index: 105; left: 280px; position: absolute; top: 157px;
        right: 886px; width: 118px;" runat="server" Height="24px">Lead Time (weeks):</asp:Label>
    <asp:Label ID="Label8" Style="z-index: 105; left: 8px; position: absolute; top: 205px;
        right: 1166px; width: 110px;" runat="server" Height="24px">Contact Name:</asp:Label>
    <asp:Label ID="lblxProcurementID" Style="z-index: 105; left: 145px; position: absolute;
        top: 7px" runat="server" Class="ViewDataDisplay" Height="24px"></asp:Label>
    <asp:Label ID="Label12" Style="z-index: 105; left: 12px; position: absolute; top: 7px"
        runat="server" Height="24px">Procurement Number:</asp:Label>
    <asp:Label ID="Label13" Style="z-index: 105; left: 10px; position: absolute; top: 161px"
        runat="server" Height="24px">Date Required:</asp:Label>
    <asp:Label ID="Label14" Style="z-index: 105; left: 18px; position: absolute; top: 49px"
        runat="server" Height="24px">Spec Pkg:</asp:Label>
    <asp:Label ID="Label2" Style="z-index: 105; left: 311px; position: absolute; top: 55px"
        runat="server" Height="24px">Spec Ref:</asp:Label>
    <telerik:RadComboBox ID="cboSubContractorID" runat="server" Style="z-index: 505;
        left: 399px; position: absolute; top: 119px; right: 662px;" Skin="Vista" Text="SubContractor"
        DropDownWidth="220px" OffsetX="-50" TabIndex="16" ZIndex="9000">
    </telerik:RadComboBox>
    <telerik:RadComboBox ID="cboStatus" runat="server" Style="z-index: 505; left: 410px;
        position: absolute; top: 243px; right: 662px;" Skin="Vista" Text="Status" DropDownWidth="220px"
        TabIndex="38">
        <Items>
            <telerik:RadComboBoxItem runat="server" Text="On Schedule" Value="On Schedule" />
            <telerik:RadComboBoxItem runat="server" Text="Delayed" Value="Delayed" />
        </Items>
    </telerik:RadComboBox>
    <telerik:RadComboBox ID="cboSupplierID" runat="server" Style="z-index: 505; left: 106px;
        position: absolute; top: 122px; right: 662px;" Skin="Vista" Text="Supplier" DropDownWidth="220px"
        TabIndex="15" ZIndex="9000">
    </telerik:RadComboBox>
    <telerik:RadComboBox ID="cboSpecificationPackage" runat="server" Style="z-index: 605;
        left: 107px; position: absolute; top: 49px;" Skin="Vista" Text="Spec Pkg" DropDownWidth="220px"
        TabIndex="1">
        <Items>
            <telerik:RadComboBoxItem runat="server" Text="Div. 2 Site Construction" Value="Div. 2 Site Construction" />
            <telerik:RadComboBoxItem runat="server" Text="Div. 3 Concrete" Value="Div. 3 Concrete" />
            <telerik:RadComboBoxItem runat="server" Text="Div. 4 Masonry" Value="Div. 4 Masonry" />
            <telerik:RadComboBoxItem runat="server" Text="Div. 5 Steel" Value="Div. 5 Steel" />
            <telerik:RadComboBoxItem runat="server" Text="Div. 6 Rough Carpentry" Value="Div. 6 Rough Carpentry" />
            <telerik:RadComboBoxItem runat="server" Text="Div. 7 Thermal & Moisture" Value="Div. 7 Thermal & Moisture" />
            <telerik:RadComboBoxItem runat="server" Text="Div. 8 Doors and Windows" Value="Div. 8 Doors and Windows" />
            <telerik:RadComboBoxItem runat="server" Text="Div. 9 Finishes" Value="Div. 9 Finishes" />
            <telerik:RadComboBoxItem runat="server" Text="Div. 10 Specialties" Value="Div. 10 Specialties" />
            <telerik:RadComboBoxItem runat="server" Text="Div. 11 Equipment" Value="Div. 11 Equipment" />
            <telerik:RadComboBoxItem runat="server" Text="Div. 12 Furnishings" Value="Div. 12 Furnishings" />
            <telerik:RadComboBoxItem runat="server" Text="Div. 13 Special Construction" Value="Div. 13 Special Construction" />
            <telerik:RadComboBoxItem runat="server" Text="Div. 14 Conveying Systems" Value="Div. 14 Conveying Systems" />
            <telerik:RadComboBoxItem runat="server" Text="Div. 15 Mechanical" Value="Div. 15 Mechanical" />
            <telerik:RadComboBoxItem runat="server" Text="Div. 16 Electrical" Value="Div. 16 Electrical" />
        </Items>
    </telerik:RadComboBox>
    <asp:Label ID="Label3" Style="z-index: 105; left: 15px; position: absolute; top: 90px"
        runat="server" Height="24px">Description:</asp:Label>
    <asp:TextBox ID="txtSpecRef" Style="z-index: 103; left: 375px; position: absolute;
        top: 52px; width: 194px;" runat="server" Height="24px" TabIndex="5" CssClass="EditDataDisplay"></asp:TextBox>
    <p>
        &nbsp;</p>
    <asp:Label ID="Label15" Style="z-index: 105; left: 21px; position: absolute; top: 125px"
        runat="server" Height="24px">Supplier:</asp:Label>
    <asp:Label ID="Label7" Style="z-index: 105; left: 297px; position: absolute; top: 122px"
        runat="server" Height="24px">Sub Contractor:</asp:Label>
    <p>
        <asp:TextBox ID="txtDescription" Style="z-index: 103; left: 104px; position: absolute;
            top: 87px; width: 465px;" runat="server" Height="24px" TabIndex="10" CssClass="EditDataDisplay"></asp:TextBox>
        <asp:Label ID="Label17" Style="z-index: 105; left: 10px; position: absolute; top: 247px;
            width: 122px; right: 1152px;" runat="server" Height="24px">P.O. From Sub:</asp:Label>
        <asp:Label ID="Label18" Style="z-index: 105; left: 347px; position: absolute; top: 246px;
            width: 122px; right: 738px;" runat="server" Height="24px">Status:</asp:Label>
        <asp:Label ID="Label6" Style="z-index: 105; left: 9px; position: absolute; top: 285px;
            width: 122px; right: 1076px;" runat="server" Height="24px">Comments:</asp:Label>
    </p>
    <telerik:RadDatePicker ID="txtRequiredDate" Style="z-index: 103; left: 105px; position: absolute;
        top: 157px; right: 1059px;" runat="server" Width="120px" Skin="Web20" TabIndex="20">
        <DateInput runat="server" Skin="WebBlue" Font-Size="13px" ForeColor="Blue" TabIndex="20">
        </DateInput>
        <Calendar runat="server" UseRowHeadersAsSelectors="False" UseColumnHeadersAsSelectors="False"
            ViewSelectorText="x" Skin="Web20">
             <SpecialDays> 
            <telerik:RadCalendarDay Repeatable="Today"> 
                <ItemStyle BackColor="LightBlue" /> 
            </telerik:RadCalendarDay> 
        </SpecialDays> 
        </Calendar>
        <DatePopupButton ImageUrl="" HoverImageUrl="" TabIndex="20"></DatePopupButton>
    </telerik:RadDatePicker>
    <asp:TextBox ID="txtComments" Style="z-index: 103; left: 12px; position: absolute;
        top: 312px; width: 551px; height: 42px;" runat="server" TabIndex="40" CssClass="EditDataDisplay"
        TextMode="MultiLine"></asp:TextBox>
    <asp:TextBox ID="txtPOFromSub" Style="z-index: 103; left: 108px; position: absolute;
        top: 244px; width: 147px;" runat="server" Height="24px" TabIndex="35" CssClass="EditDataDisplay"></asp:TextBox>
    <telerik:RadNumericTextBox ID="txtLeadTimeWeeks" Style="z-index: 103; left: 409px;
        position: absolute; top: 153px; width: 46px; bottom: 728px;" runat="server" Height="24px"
        TabIndex="22" CssClass="EditDataDisplay" MinValue="0" MaxValue="500" Width="50px">
    </telerik:RadNumericTextBox>
    <asp:TextBox ID="txtContactPhone" Style="z-index: 103; left: 406px; position: absolute;
        top: 200px; width: 147px;" runat="server" Height="24px" TabIndex="29" CssClass="EditDataDisplay"></asp:TextBox>
    <asp:TextBox ID="txtContactName" Style="z-index: 103; left: 108px; position: absolute;
        top: 201px; width: 147px; right: 1029px;" runat="server" Height="24px" TabIndex="26"
        CssClass="EditDataDisplay"></asp:TextBox>
    </form>
</body>
</html>
