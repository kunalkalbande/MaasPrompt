<%@ Page Language="vb" %>

<%@ Import Namespace="Prompt" %>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">

<script runat="server">

    Public nContractorID As Integer
    Private Sub Page_Load(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MyBase.Load

        ProcLib.CheckSession(Page)

        ProcLib.LoadPopupJscript(Page)

        'set up help button
        Session("PageID") = "ContractorEdit"
        butHelp.Attributes.Add("onclick", "openPopup('help_view.aspx','pophelp',550,450,'yes');")
        butHelp.NavigateUrl = "#"

        Session("passbacktype") = Request.QueryString("type")   'for use in project edit for contractor and arch calls

        nContractorID = Request.QueryString("ContractorID")
        
        lblMessage.Text = ""
        
        Using rs As New Contractor

            If IsPostBack Then   'only do the following post back
                nContractorID = lblContractorID.Text
            Else  'only do the following on first load

                If nContractorID = 0 Then    'add the new record
                    With rs
                        .CallingPage = Page
                        .GetNewContractor()
                    End With
                    butDelete.Visible = False
                
                Else
                    With rs
                        .CallingPage = Page
                        .GetExistingContractor(nContractorID)
                    End With

                End If
            End If
            

        End Using

        'check for passback value and if there, add entry to dropdown and select
        If Session("passback") <> "" Then
            lstcType.Items.Add(Session("passback"))
            lstcType.SelectedValue = Session("passback")
            Session("passback") = ""
        End If

        Page.SetFocus("txtName")
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
        
        Using rs As New Contractor
            With rs
                .CallingPage = Page
                .SaveContractor(nContractorID)
            End With
        End Using
  
        If bRefreshPassbackCallingPage Then       'this page was called from an edit page so save keyval to session for passback
            Session("passback") = txtName.Text
            Session("passbackID") = nContractorID
        End If
        
        If Request.QueryString("WinType") = "RAD" Then
            ProcLib.CloseAndRefreshRAD(Page)
        Else
 
            ProcLib.CloseAndRefresh(Page)  'for legacy popup close - rad window will ignore
        End If

    End Sub

    Private Sub butDelete_Click(ByVal sender As System.Object, ByVal e As System.Web.UI.ImageClickEventArgs) Handles butDelete.Click

        Dim msg As String = ""
        Using db As New Contractor
            msg = db.DeleteContractor(nContractorID)
        End Using
        If msg <> "" Then
            Response.Redirect("delete_error.aspx?msg=" & msg)
        Else
            Session("RtnFromEdit") = True
            ProcLib.CloseAndRefreshRAD(Page)
        End If
        
    End Sub


</script>

<html>
<head>
    <title>contractor_edit</title>
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
    <asp:Label ID="Label1" Style="z-index: 100; left: 8px; position: absolute; top: 48px"
        runat="server" EnableViewState="False">ID:</asp:Label>
    <asp:ImageButton ID="butDelete" Style="z-index: 136; left: 328px; position: absolute;
        top: 580px" TabIndex="41" runat="server" ImageUrl="images/button_delete.gif">
    </asp:ImageButton>
    <asp:ImageButton ID="butSave" Style="z-index: 120; left: 92px; position: absolute;
        top: 577px" TabIndex="40" runat="server" ImageUrl="images/button_save.gif"></asp:ImageButton>
    <table id="Table1" style="z-index: 135; left: 8px; position: absolute; top: 8px;
        height: 28px" height="28" cellspacing="1" cellpadding="1" width="96%" border="0">
        <tr height="1">
            <td valign="top" height="6">
                <asp:Label ID="Label17" runat="server" EnableViewState="False" CssClass="PageHeading"
                    Height="24px">Edit Contractor</asp:Label>
            </td>
            <td valign="top" align="right" height="6">
                <asp:HyperLink ID="butHelp" runat="server" ImageUrl="images/button_help.gif">HyperLink</asp:HyperLink>
            </td>
        </tr>
    </table>
    <hr style="z-index: 101; left: 8px; position: absolute; top: 40px; height: 1px" width="96%"
        size="1">
    <asp:Label ID="Label16" Style="z-index: 133; left: 16px; position: absolute; top: 464px"
        runat="server" EnableViewState="False" Height="8px">Keywords:</asp:Label>
    <asp:TextBox ID="txtKeyWords" Style="z-index: 132; left: 88px; position: absolute;
        top: 456px" TabIndex="18" runat="server" Height="40px" Width="416px" MaxLength="500"
        TextMode="MultiLine" CssClass="EditDataDisplay"></asp:TextBox>
    <asp:Label ID="Label15" Style="z-index: 117; left: 40px; position: absolute; top: 432px"
        runat="server" EnableViewState="False">Email:</asp:Label>
    <asp:TextBox ID="txtEmail" CssClass="EditDataDisplay" Style="z-index: 131; left: 88px;
        position: absolute; top: 424px" TabIndex="17" runat="server" Width="192px"></asp:TextBox>
    <asp:TextBox ID="txtComments" Style="z-index: 130; left: 88px; position: absolute;
        top: 504px" TabIndex="19" runat="server" Height="49px" Width="416px" MaxLength="500"
        TextMode="MultiLine" CssClass="EditDataDisplay"></asp:TextBox>
    <asp:TextBox ID="txtFax" Style="z-index: 129; left: 88px; position: absolute; top: 392px"
        TabIndex="16" runat="server" Width="120px" CssClass="EditDataDisplay"></asp:TextBox>
    <asp:TextBox ID="txtPhone2" Style="z-index: 128; left: 88px; position: absolute;
        top: 360px" TabIndex="15" CssClass="EditDataDisplay" runat="server" Width="120px"></asp:TextBox>
    <asp:TextBox ID="txtPhone1" Style="z-index: 127; left: 88px; position: absolute;
        top: 328px" TabIndex="14" runat="server" Width="120px" CssClass="EditDataDisplay"></asp:TextBox>
    <asp:TextBox ID="txtContact" Style="z-index: 126; left: 88px; position: absolute;
        top: 296px" TabIndex="13" runat="server" Width="144px" CssClass="EditDataDisplay"></asp:TextBox>
    <asp:TextBox ID="txtZip" Style="z-index: 125; left: 88px; position: absolute; top: 264px"
        TabIndex="12" runat="server" Width="96px" CssClass="EditDataDisplay"></asp:TextBox>
    <asp:TextBox ID="txtState" Style="z-index: 124; left: 88px; position: absolute; top: 232px"
        TabIndex="11" runat="server" Width="64px" CssClass="EditDataDisplay"></asp:TextBox>
    <asp:TextBox ID="txtCity" Style="z-index: 123; left: 88px; position: absolute; top: 200px"
        TabIndex="9" runat="server" Width="144px" CssClass="EditDataDisplay"></asp:TextBox>
    <asp:TextBox ID="txtDistrictContractorID" runat="server" CssClass="EditDataDisplay"
        Style="z-index: 123; left: 293px; position: absolute; top: 235px" TabIndex="9"
        Width="144px" MaxLength="11"></asp:TextBox>
    <asp:TextBox ID="txtAddress2" Style="z-index: 121; left: 88px; position: absolute;
        top: 168px" TabIndex="8" runat="server" Width="248px" CssClass="EditDataDisplay"></asp:TextBox>
    <asp:TextBox ID="txtAddress1" Style="z-index: 119; left: 88px; position: absolute;
        top: 136px" TabIndex="7" runat="server" Width="248px" CssClass="EditDataDisplay"></asp:TextBox>
    <asp:Label ID="Label14" Style="z-index: 118; left: 8px; position: absolute; top: 504px"
        runat="server" EnableViewState="False">Comments:</asp:Label>
    <asp:Label ID="Label13" Style="z-index: 116; left: 40px; position: absolute; top: 432px"
        runat="server" EnableViewState="False">Email:</asp:Label>
    <asp:Label ID="Label12" Style="z-index: 115; left: 50px; position: absolute; top: 400px"
        runat="server" EnableViewState="False">Fax:</asp:Label>
    <asp:Label ID="Label11" Style="z-index: 114; left: 28px; position: absolute; top: 368px"
        runat="server" EnableViewState="False">Phone2:</asp:Label>
    <asp:Label ID="Label10" Style="z-index: 113; left: 28px; position: absolute; top: 336px"
        runat="server" EnableViewState="False">Phone1:</asp:Label>
    <asp:Label ID="Label9" Style="z-index: 112; left: 28px; position: absolute; top: 296px"
        runat="server" EnableViewState="False">Contact:</asp:Label>
    <asp:Label ID="Label8" Style="z-index: 111; left: 24px; position: absolute; top: 272px"
        runat="server" EnableViewState="False">ZipCode:</asp:Label>
    <asp:Label ID="Label7" Style="z-index: 110; left: 40px; position: absolute; top: 240px"
        runat="server" EnableViewState="False">State:</asp:Label>
    <asp:Label ID="Label6" Style="z-index: 109; left: 48px; position: absolute; top: 208px"
        runat="server" EnableViewState="False">City:</asp:Label>
    <asp:Label ID="Label5" Style="z-index: 108; left: 18px; position: absolute; top: 176px"
        runat="server" EnableViewState="False">Address2:</asp:Label>
    <asp:Label ID="Label4" Style="z-index: 107; left: 18px; position: absolute; top: 144px"
        runat="server" EnableViewState="False">Address1:</asp:Label>
    <asp:Label ID="Label18" runat="server" EnableViewState="False" Style="z-index: 107;
        left: 180px; position: absolute; top: 236px">District ID Number:</asp:Label>
    <asp:Label ID="Label3" Style="z-index: 106; left: 42px; position: absolute; top: 104px"
        runat="server" EnableViewState="False">Type:</asp:Label>
    <asp:Label ID="Label19" Style="z-index: 105; left: 37px; position: absolute; top: 80px"
        runat="server" EnableViewState="False">Name:</asp:Label>
    <asp:Label ID="lblContractorID" Style="z-index: 104; left: 40px; position: absolute;
        top: 48px" runat="server">9999</asp:Label>
    <asp:DropDownList ID="lstcType" Style="z-index: 103; left: 88px; position: absolute;
        top: 104px" TabIndex="5" runat="server" Width="216px" CssClass="EditDataDisplay">
    </asp:DropDownList>
    <asp:TextBox ID="txtName" Style="z-index: 102; left: 88px; position: absolute; top: 72px"
        runat="server" Width="248px" CssClass="EditDataDisplay"></asp:TextBox>
    <asp:LinkButton ID="lnkAddNew" Style="z-index: 134; left: 312px; position: absolute;
        top: 112px" TabIndex="6" runat="server">Add New...</asp:LinkButton>
    <p>
    <asp:Label ID="lblMessage" Style="z-index: 105; left: 92px; position: absolute; top: 52px"
        runat="server" EnableViewState="False" Font-Bold="True" ForeColor="Red"></asp:Label>
    </p>
    </form>
</body>
</html>
