<%@ Page Language="VB" MasterPageFile="~/content.master" Title="" %>
<%@ Register Assembly="Telerik.Web.UI" Namespace="Telerik.Web.UI" TagPrefix="telerik" %>
<%@ Import Namespace="Prompt" %>

<script runat="server">
    
    Private nContractID As Integer = 0
    Private Sub Page_Load(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MyBase.Load

        Session("PageID") = "ContractNOC"
        nContractID = Request.QueryString("ContractID")
        
        'Since this is the primary calling page from the Nav menu, we need to check if current view is something other than
        'Overview and if so redirect
        Dim masterTabs As RadTabStrip = Master.FindControl("tabMain")
        Dim sNewLocation As String = ""
        If Request.QueryString("t") <> "y" Then
            If Session("CurrentTab") <> "NOC" Then   'redirect to appropriate tab if available
                For Each radTab In masterTabs.GetAllTabs
                    If radTab.Value = Session("CurrentTab") Then
                        radTab.Selected = True
                        radTab.SelectParents()
                        Response.Redirect(radTab.NavigateUrl)
                        Exit For
                    End If
                Next
            End If
        End If
        Session("CurrentTab") = "NOC"
        'if we have not redirected then we are at the right place
        For Each radTab In masterTabs.GetAllTabs
            If radTab.Value = "NOC" Then
                radTab.Selected = True
                radTab.SelectParents()
                Exit For
            End If
        Next
        
        Using dbsec As New EISSecurity
            dbsec.DistrictID = HttpContext.Current.Session("DistrictID")
            dbsec.CollegeID = HttpContext.Current.Session("CollegeID")
            dbsec.UserID = HttpContext.Current.Session("UserID")
            
            If dbsec.FindUserPermission("ContractOverview", "write") Then
                With lnkEdit
                    .Visible = True
                    .Attributes.Add("onclick", "openPopup('contract_noc_edit.aspx?ContractID=" & nContractID & "','editContractNOC',600,600,'yes');")
                End With
            Else
                lnkEdit.Visible = False
            End If

        End Using

  
        'get the Contract record 
        Using rs As New PromptDataHelper
            rs.CallingPage = Page
            rs.FillForm(contentPanel1, "SELECT * FROM Contracts WHERE ContractID =" & nContractID)
        End Using
        

    End Sub


</script>

<asp:Content ID="Content1" ContentPlaceHolderID="mainBody" runat="Server">
    <telerik:RadWindowManager ID="contentPopups" runat="server">
    </telerik:RadWindowManager>
    <asp:Panel ID="contentPanel1" runat="server">
<div id="contentwrapper">
<div id="contentcolumn">
<div class="innertube">
<table class="notes_tb" width="97%" cellpadding="3" cellspacing="0">
<tr><th colspan="2"><asp:HyperLink CssClass="editbtn" ID="lnkEdit" runat="server" NavigateUrl="#">Edit</asp:HyperLink>NOC Details</th></tr>
<tr><td><asp:Label ID="Label1" runat="server" Text="NOC Date:"></asp:Label></td><td><asp:Label ID="lblNOCDate" runat="server" Text=""></asp:Label>&nbsp;</td></tr>
<tr><td><asp:Label ID="Label4" runat="server" Text="Surety:"></asp:Label></td><td><asp:Label ID="lblSurety" runat="server" Text=""></asp:Label>&nbsp;</td></tr>
<tr><td><asp:Label ID="Label8" runat="server" Text="Board Approved:"></asp:Label></td><td><asp:Label ID="lblBoardApproved" runat="server" Text=""></asp:Label>&nbsp;</td></tr>
<tr><td><asp:Label ID="Label9" runat="server" Text="Mailed NOC for Recording:"></asp:Label></td><td><asp:Label ID="lblMailedForRecording" runat="server" Text=""></asp:Label>&nbsp;</td></tr>
<tr><td><asp:Label ID="Label5" runat="server" Text="Date Recorded:"></asp:Label></td><td><asp:Label ID="lblDateRecorded" runat="server" Text=""></asp:Label>&nbsp;</td></tr>
<tr><td><asp:Label ID="Label6" runat="server" Text="Doc #:"></asp:Label></td><td><asp:Label ID="lblDocNumber" runat="server" Text=""></asp:Label>&nbsp;</td></tr>
<tr><td><asp:Label ID="Label7" runat="server" Text="Release Date:"></asp:Label></td><td><asp:Label ID="lblReleaseDate" runat="server" Text=""></asp:Label>&nbsp;</td></tr></table>
</div></div></div>
        </asp:Panel>
        <br class="clear" />
        <div class="id_display">ID:<asp:Label ID="lblContractID" runat="server"></asp:Label></div>
        <asp:Label ID="lblDebug" runat="server" Style="z-index: 100; left: 16px; position: absolute;
            top: 386px" Visible="False"></asp:Label>
 
</asp:Content>
