<%@ Page Language="vb" %>

<%@ Register Assembly="Telerik.Web.UI" Namespace="Telerik.Web.UI" TagPrefix="telerik" %>
<%@ Import Namespace="Prompt" %>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">

<script runat="server">

    Public nCompanyID As Integer
    Private Sub Page_Load(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MyBase.Load

        ProcLib.CheckSession(Page)

        ProcLib.LoadPopupJscript(Page)

        'set up help button
        Session("PageID") = "CompanyEdit"
        
        butHelp.Attributes.Add("onclick", "openPopup('help_view.aspx','pophelp',550,450,'yes');")
        butHelp.NavigateUrl = "#"

        Session("passbacktype") = Request.QueryString("type")   'for use in project edit for Company and arch calls

        nCompanyID = Request.QueryString("ContactID")
        
        lblMessage.Text = ""
        
        Using rs As New Company

            If IsPostBack Then   'only do the following post back
                'nCompanyID = lblContactID.Text
            Else  'only do the following on first load

                If nCompanyID = 0 Then    'add the new record
                    With rs
                        .CallingPage = Page
                        .GetNewCompany()
                    End With
                    butDelete.Visible = False
                
                Else
                    With rs
                        .CallingPage = Page
                        .GetExistingCompany(nCompanyID)
                    End With

                End If
                
                lblID.Text = nCompanyID
            End If
            

        End Using

        'check for passback value and if there, add entry to dropdown and select
        If Session("passback") <> "" Then
            Dim item As New RadComboBoxItem
            item.Text = Session("passback")
            item.Value = Session("passback")
            lstCompanyType.Items.Add(item)
            lstCompanyType.SelectedValue = Session("passback")
            Session("passback") = ""
        End If

        Page.SetFocus("txtName")
        
        'set up attachments button
        lnkManageAttachments.Attributes("onclick") = "return ManageAttachments('" & nCompanyID & "','Insurance');"
        lnkManageAttachments.NavigateUrl = "#"
        
        SetUpRadWindows()

        LoadLinkedAttachments()
    End Sub


    Private Sub lnkAddNew_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles lnkAddNew.Click
        Dim jscript As New StringBuilder
        'Opens a new popup for adding a new value on the fly while editing a record.
        jscript.Append("<script language='javascript'>")
        jscript.Append("window.open('lookup_edit.aspx?new=y&passback=y&ParentField=ContractorType&ParentTable=Contractors','LookupEdit','height=500, width=500,status= no, resizable= yes, scrollbars=no, toolbar=no,location=no,menubar=no ');")
        jscript.Append("</" & "script>")
        ClientScript.RegisterStartupScript(GetType(String), "NewType", jscript.ToString)
    End Sub

    Private Sub butSave_Click(ByVal sender As System.Object, ByVal e As System.Web.UI.ImageClickEventArgs) Handles butSave.Click
        
        If txtName.Text = "" Then
            lblMessage.Text = "Please enter a Name."
            Exit Sub
        End If
        
        
        Dim bRefreshPassbackCallingPage As Boolean = False   'to force refresh of calling page when passback
        If Request.QueryString("passback") = "y" Then bRefreshPassbackCallingPage = True
        
        Using rs As New Company
            With rs
                .CallingPage = Page
                .SaveCompany(nCompanyID)
            End With
        End Using
  
        If bRefreshPassbackCallingPage Then       'this page was called from an edit page so save keyval to session for passback
            Session("passback") = txtName.Text
            Session("passbackID") = nCompanyID
        End If
        
        If Request.QueryString("WinType") = "RAD" Then
            ProcLib.CloseAndRefreshRAD(Page)
        Else
 
            ProcLib.CloseAndRefresh(Page)  'for legacy popup close - rad window will ignore
        End If

    End Sub

    Private Sub butDelete_Click(ByVal sender As System.Object, ByVal e As System.Web.UI.ImageClickEventArgs) Handles butDelete.Click

        Dim msg As String = ""
        Using db As New Company
            msg = db.DeleteCompany(nCompanyID)
        End Using
        If msg <> "" Then
            lblMessage.Text = "This Company is associated with existing records. Make Inactive instead of Deleting."
        Else
            Session("RtnFromEdit") = True
            ProcLib.CloseAndRefreshRAD(Page)
        End If
        
    End Sub

    Private Sub LoadLinkedAttachments()
        'get the linked attachements
        lstAttachments.Items.Clear()
        Using db As New PromptDataHelper
            Dim rs As DataTable
            rs = db.ExecuteDataTable("Select AI.AttachmentID, A.FileName From AttachmentsInsurance AI join Attachments A on AI.AttachmentID = A.AttachmentID Where AI.CompanyID = " & nCompanyID & " Order By A.Filename")
            If rs.Rows.Count > 0 Then
                For Each row As DataRow In rs.Rows
                    Dim li As New ListItem
                    li.Text = row("FileName")
                    li.Value = row("AttachmentID")
                    li.Attributes("ondblclick") = "return OpenAttachment('" & li.Value & "');"
                    lstAttachments.Items.Add(li)
                Next
            Else
                lstAttachments.Items.Add("No Attachments Found")
            End If
            
        End Using
    End Sub
    
    Private Sub SetUpRadWindows()
        With RadPopups
            .Skin = "Office2007"
            .VisibleOnPageLoad = False
            Dim ww As New Telerik.Web.UI.RadWindow
            With ww
                .ID = "ManageAttachments"
                .NavigateUrl = ""
                .Title = ""
                .Width = 500
                .Height = 450
                .Top = 200
                .Left = 20
                .Modal = False
                .VisibleStatusbar = False
                .ReloadOnShow = True
                .Behaviors = WindowBehaviors.Close + WindowBehaviors.Move
            End With
            .Windows.Add(ww)
        
            ww = New Telerik.Web.UI.RadWindow
            With ww
                .ID = "OpenAttachmentWindow"
                .NavigateUrl = ""
                .Title = ""
                .Width = 500
                .Height = 450
                .Top = 200
                .Left = 20
                .Modal = False
                .VisibleStatusbar = False
                .ReloadOnShow = True
                .Behaviors = WindowBehaviors.Close + WindowBehaviors.Move
            End With
            .Windows.Add(ww)
        End With
    End Sub
    
</script>

<html>
<head>
    <title>Edit Company</title>
    <link href="Styles.css" type="text/css" rel="stylesheet" />

    <script type="text/javascript" language="javascript">

        function GetRadWindow() {
            var oWindow = null;
            if (window.RadWindow) oWindow = window.RadWindow;
            else if (window.frameElement.radWindow) oWindow = window.frameElement.radWindow;
            return oWindow;
        }
        
        function ManageAttachments(id, rectype)     //for managing attachments
        {
            var oWnd = window.radopen("attachments_manage_insurance.aspx?ParentRecID=" + id + "&ParentType=" + rectype, "ManageAttachments");
            return false;
        }

        function OpenAttachment(id)     //for opening attachments 
        {
            var oWnd = window.radopen("attachment_get_linked.aspx?ID=" + id, "OpenAttachmentWindow");
            return false;
        }

        //For handling ajax post back from Attachment Manage RAD Popup
        function HandleAjaxPostbackFromAttachmentsPopup() {
            var oButton = document.getElementById("<%=AttachmentsPopup_AjaxHiddenButton.ClientID%>");
            oButton.click();

        }
    </script>

</head>
<body>
    <form id="Form1" method="post" runat="server">
    
        <telerik:RadScriptManager ID="RadScriptManager1" runat="server" />
    
    <asp:Label ID="Label1" Style="z-index: 100; left: 11px; position: absolute; top: 11px"
        runat="server" EnableViewState="False">ID:</asp:Label>
    <asp:ImageButton ID="butDelete" Style="z-index: 136; left: 296px; position: absolute;
        top: 560px" TabIndex="41" runat="server" ImageUrl="images/button_delete.gif">
    </asp:ImageButton>
    <asp:ImageButton ID="butSave" Style="z-index: 120; left: 46px; position: absolute;
        top: 561px" TabIndex="40" runat="server" ImageUrl="images/button_save.gif"></asp:ImageButton>
    <asp:Label ID="Label16" Style="z-index: 133; left: 24px; position: absolute; top: 444px"
        runat="server" EnableViewState="False" Height="8px">Keywords:</asp:Label>
    <asp:TextBox ID="txtKeyWords" Style="z-index: 132; left: 85px; position: absolute;
        top: 443px" TabIndex="18" runat="server" Height="40px" Width="416px" MaxLength="500"
        TextMode="MultiLine" CssClass="EditDataDisplay"></asp:TextBox>
    <asp:Label ID="Label15" Style="z-index: 117; left: 41px; position: absolute; top: 409px"
        runat="server" EnableViewState="False">Email:</asp:Label>
    <asp:TextBox ID="txtEmail" CssClass="EditDataDisplay" Style="z-index: 131; left: 85px;
        position: absolute; top: 408px; width: 159px;" TabIndex="17" runat="server"></asp:TextBox>
    <asp:TextBox ID="txtComments" Style="z-index: 130; left: 85px; position: absolute;
        top: 494px" TabIndex="19" runat="server" Height="49px" Width="416px" MaxLength="500"
        TextMode="MultiLine" CssClass="EditDataDisplay"></asp:TextBox>
    <asp:TextBox ID="txtFax" Style="z-index: 129; left: 88px; position: absolute; top: 377px"
        TabIndex="16" runat="server" Width="120px" CssClass="EditDataDisplay"></asp:TextBox>
    <asp:TextBox ID="txtPhone2" Style="z-index: 128; left: 86px; position: absolute;
        top: 341px" TabIndex="15" CssClass="EditDataDisplay" runat="server" Width="120px"></asp:TextBox>
    <asp:TextBox ID="txtPhone1" Style="z-index: 127; left: 86px; position: absolute;
        top: 307px" TabIndex="14" runat="server" Width="120px" CssClass="EditDataDisplay"></asp:TextBox>
    <asp:TextBox ID="txtContact" Style="z-index: 126; left: 85px; position: absolute;
        top: 275px" TabIndex="13" runat="server" Width="144px" CssClass="EditDataDisplay"></asp:TextBox>
    <asp:TextBox ID="txtZip" Style="z-index: 125; left: 84px; position: absolute; top: 241px"
        TabIndex="12" runat="server" Width="96px" CssClass="EditDataDisplay"></asp:TextBox>
    <asp:TextBox ID="txtState" Style="z-index: 124; left: 85px; position: absolute; top: 206px"
        TabIndex="11" runat="server" Width="64px" CssClass="EditDataDisplay"></asp:TextBox>
    <asp:TextBox ID="txtCity" Style="z-index: 123; left: 86px; position: absolute; top: 171px"
        TabIndex="9" runat="server" Width="144px" CssClass="EditDataDisplay"></asp:TextBox>
    <asp:TextBox ID="txtDistrictContractorID" runat="server" CssClass="EditDataDisplay"
        Style="z-index: 123; left: 357px; position: absolute; top: 173px" TabIndex="9"
        Width="144px" MaxLength="11"></asp:TextBox>
    <asp:TextBox ID="txtAddress2" Style="z-index: 121; left: 87px; position: absolute;
        top: 139px" TabIndex="8" runat="server" Width="248px" CssClass="EditDataDisplay"></asp:TextBox>
    <asp:TextBox ID="txtAddress1" Style="z-index: 119; left: 86px; position: absolute;
        top: 104px" TabIndex="7" runat="server" Width="248px" CssClass="EditDataDisplay"></asp:TextBox>
    <asp:Label ID="Label14" Style="z-index: 118; left: 11px; position: absolute; top: 493px"
        runat="server" EnableViewState="False">Comments:</asp:Label>
    <asp:Label ID="Label12" Style="z-index: 115; left: 49px; position: absolute; top: 378px"
        runat="server" EnableViewState="False">Fax:</asp:Label>
    <asp:Label ID="Label11" Style="z-index: 114; left: 30px; position: absolute; top: 345px"
        runat="server" EnableViewState="False">Phone2:</asp:Label>
    <asp:Label ID="Label10" Style="z-index: 113; left: 31px; position: absolute; top: 309px"
        runat="server" EnableViewState="False">Phone1:</asp:Label>
    <asp:Label ID="Label9" Style="z-index: 112; left: 30px; position: absolute; top: 275px"
        runat="server" EnableViewState="False">Contact:</asp:Label>
    <asp:Label ID="Label8" Style="z-index: 111; left: 24px; position: absolute; top: 242px"
        runat="server" EnableViewState="False">ZipCode:</asp:Label>
    <asp:Label ID="Label7" Style="z-index: 110; left: 43px; position: absolute; top: 210px;
        height: 20px;" runat="server" EnableViewState="False">State:</asp:Label>
    <asp:Label ID="Label6" Style="z-index: 109; left: 49px; position: absolute; top: 175px"
        runat="server" EnableViewState="False">City:</asp:Label>
    <asp:Label ID="Label5" Style="z-index: 108; left: 21px; position: absolute; top: 140px"
        runat="server" EnableViewState="False">Address2:</asp:Label>
    <asp:Label ID="Label4" Style="z-index: 107; left: 22px; position: absolute; top: 104px"
        runat="server" EnableViewState="False">Address1:</asp:Label>
    <asp:Label ID="Label18" runat="server" EnableViewState="False" Style="z-index: 107;
        left: 267px; position: absolute; top: 178px; right: 1204px; width: 72px;">District ID #:</asp:Label>
    <asp:Label ID="Label3" Style="z-index: 106; left: 42px; position: absolute; top: 71px"
        runat="server" EnableViewState="False">Type:</asp:Label>
    <asp:Label ID="Label19" Style="z-index: 105; left: 36px; position: absolute; top: 39px;
        height: 17px;" runat="server" EnableViewState="False">Name:</asp:Label>
    <asp:Label ID="lblID" Style="z-index: 104; left: 41px; position: absolute; top: 12px"
        runat="server">9999</asp:Label>
    <telerik:RadComboBox ID="lstCompanyType" Style="z-index: 1103; left: 87px; position: absolute;
        top: 70px" TabIndex="5" runat="server" Width="216px" MaxHeight="200px" >
    </telerik:RadComboBox>
    <asp:TextBox ID="txtName" Style="z-index: 102; left: 86px; position: absolute; top: 38px"
        runat="server" Width="248px" CssClass="EditDataDisplay"></asp:TextBox>
    <asp:LinkButton ID="lnkAddNew" Style="z-index: 134; left: 314px; position: absolute;
        top: 71px" TabIndex="6" runat="server">Add New...</asp:LinkButton>
    <asp:Label ID="lblMessage" Style="z-index: 105; left: 92px; position: absolute; top: 13px"
        runat="server" EnableViewState="False" Font-Bold="True" ForeColor="Red"></asp:Label>
    <asp:CheckBox ID="chkInactive" Style="z-index: 102; left: 396px; position: absolute;
        top: 38px" runat="server" runat="server" Text="InActive" />
    <asp:HyperLink ID="butHelp" runat="server" Style="z-index: 120; left: 423px; position: absolute;
        top: 11px; height: 15px; bottom: 878px;" ImageUrl="images/button_help.gif">HyperLink</asp:HyperLink>

    <div style="left: 250px; position: absolute; top: 204px; background-color:;width:251px; height:230px; border:1px solid #000">
        Insurance:<br />
        <asp:CheckBox ID="cbxInsuranceRequired" text="    Insurance Required?" runat="server" 
            Style="z-index: 107; left: 6px; position: absolute; top: 24px; height: 15px; width: 189px;"/>        
        <telerik:RadDatePicker ID="txtInsurExpireDate" Style="z-index: 155; left: 95px; position: absolute;
            top: 49px; width: 153px; height: 23px;" runat="server" TabIndex="12">
            <DateInput ID="DateInput1" runat="server" Skin="Vista" Font-Size="13px" ForeColor="Blue">
            </DateInput>
        </telerik:RadDatePicker>
        <asp:Label ID="Label333" runat="server" CssClass="smalltext" Height="16px" Style="z-index: 108;
          left: 9px; position: absolute; top: 76px">Policy Description:
        </asp:Label>             
        <asp:Label ID="Label334" Style="z-index: 107; left: 8px; position: absolute; top: 53px; height: 16px; right: 159px;"
          runat="server" CssClass="smalltext">Expiration Date:
        </asp:Label>
        <asp:TextBox ID="txtInsurPolicyDescription" runat="server" 
            Style="z-index: 107; left: 6px; position: absolute; top: 97px; height: 40px; width: 197px;"></asp:TextBox>
        <asp:Label ID="Label2" runat="server" Style="z-index: 119; left: 5px; position: absolute;
            top: 141px; height: 10px;">Attachments:</asp:Label>
        <asp:ListBox ID="lstAttachments" runat="server" Style="z-index: 156;
            left: 9px; position: absolute; top: 162px; width: 200px; height: 53px;" CssClass="smalltext"
            TabIndex="71"></asp:ListBox>
        <asp:HyperLink ID="lnkManageAttachments" runat="server" ImageUrl="images/button_folder_view.gif"
            Style="z-index: 155; left: 217px; position: absolute; top: 167px" TabIndex="73"
            ToolTip="Manage Attachments">Manage Attachments</asp:HyperLink>    
        </div>
        <telerik:RadWindowManager ID="RadPopups" runat="server">    </telerik:RadWindowManager>
        <asp:Button ID="AttachmentsPopup_AjaxHiddenButton" runat="server"></asp:Button>
    </form>
</body>
</html>
