<%@ Page Language="VB" MasterPageFile="~/content.master" Title="" %>
<%@ Register Assembly="Telerik.Web.UI" Namespace="Telerik.Web.UI" TagPrefix="telerik" %>
<%@ Import Namespace="Prompt" %>

<script runat="server">
    
    Private bReadOnly As Boolean = True
    Private nProjectID As Integer = 0
    
    Private Sub Page_Load(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MyBase.Load

        ProcLib.CheckSession(Page)
        ProcLib.LoadPopupJscript(Page)

        ''set up help button
        Session("PageID") = "BondSiteInfo"
        nProjectID = Request.QueryString("ProjectID")
        
        'If Request.Browser.Browser = "IE" Then
        RadGrid1.Height = Unit.Pixel(600)
        'Else
        '.Height = Unit.Percentage(88)
        'End If
        
        Dim masterTabs As RadTabStrip = Master.FindControl("tabMain")
        Session("CurrentTab") = "BondWebsite"
        For Each radTab In masterTabs.GetAllTabs
            If radTab.Value = "BondWebsite" Then
                radTab.Selected = True
                radTab.SelectParents()
                Exit For
            End If
        Next
        
        With contentPopup
            .VisibleOnPageLoad = False
            .Skin = "Windows7"
                         
            Dim ww As New RadWindow

            ww = New RadWindow
            With ww
                .ID = "EditWindow"
                .NavigateUrl = "#"
                .Title = ""
                .Width = 650
                .Height = 575
                .Modal = True
                .VisibleStatusbar = False
                .ReloadOnShow = True
                .Behaviors = WindowBehaviors.Close
            End With
            .Windows.Add(ww)
            
            ww = New RadWindow
            With ww
                .ID = "AttachmentsWindow"
                .NavigateUrl = "#"
                .Title = ""
                .Width = 500
                .Height = 350
                .Modal = True
                .VisibleStatusbar = False
                .ReloadOnShow = True
                .Behaviors = WindowBehaviors.Close + WindowBehaviors.Move
            End With
            .Windows.Add(ww)
            
        End With
        
        'configure edit button
        Using db As New EISSecurity
            db.CollegeID = Session("CollegeID")
            db.ProjectID = nProjectID
            If db.FindUserPermission("BondWebsite", "write") Then
                lnkEdit.Attributes("onclick") = "return EditProjectInfo(" & nProjectID & ");"
                lnkNewsReleases.Visible = True
                lnkNewsReleases.Attributes("onclick") = "return ManageAttachments('" & nProjectID & "');"
            Else
                lnkEdit.Visible = False
                lnkNewsReleases.Visible = False
            End If

        End Using
        
        If Session("DistrictID") <> 56 Then   'HACK: Only show for COD for now
            lnkNewsReleases.Visible = False
            
        End If
        
   
    End Sub

    Protected Sub RadGrid1_NeedDataSource(ByVal source As Object, ByVal e As Telerik.Web.UI.GridNeedDataSourceEventArgs) Handles RadGrid1.NeedDataSource
        'loads the grid whenever it needs data (sorting, rebinding, etc...)
        Using db As New BondSite
            db.CallingPage = Page
            RadGrid1.DataSource = db.GetBondProjectInfo(nProjectID)
        End Using
         
    End Sub
    
    Private Sub RadGrid1_ItemDataBound(ByVal sender As Object, ByVal e As Telerik.Web.UI.GridItemEventArgs) Handles RadGrid1.ItemDataBound
        
        If TypeOf e.Item Is GridDataItem Then
            Dim dataitem As GridDataItem = e.Item
 
            If dataitem("DisplayLabel").Text = "Publish To Web" Then
                If dataitem("DisplayValue").Text = "Yes" Then
                    dataitem("DisplayValue").CssClass = "green"
                Else
                    dataitem("DisplayValue").CssClass = "red"
                End If
            End If
            
    
        End If

    End Sub

</script>

<asp:Content ID="Content1" ContentPlaceHolderID="mainBody" runat="Server">
    <telerik:RadWindowManager ID="contentPopup" runat="server">
    </telerik:RadWindowManager>
<div id="contentwrapper">
<div id="navrow">
    <asp:HyperLink ID="lnkEdit" CssClass="edit" runat="server" NavigateUrl="#">Edit</asp:HyperLink>
    &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
     <asp:HyperLink ID="lnkNewsReleases" runat="server" NavigateUrl="#">News Releases</asp:HyperLink>
    
</div>
<div id="contentcolumn">
<div class="innertube">
<telerik:RadGrid ID="RadGrid1" runat="server" AutoGenerateColumns="False" GridLines="None" Width="100%" EnableAJAX="True" EnableEmbeddedSkins="false" Skin="Prompt">
    <ClientSettings>
        <Selecting AllowRowSelect="False" />
        <Scrolling AllowScroll="False" UseStaticHeaders="True" />
    </ClientSettings>
    <MasterTableView Width="100%" GridLines="None" DataKeyNames="DisplayValue,DisplayLabel" 
        NoMasterRecordsText="No Bondsite Project Info found." ShowHeader="False">
        <Columns>
            <telerik:GridBoundColumn UniqueName="DisplayLabel" HeaderText="" DataField="DisplayLabel">
                <ItemStyle HorizontalAlign="Left" Width="175" />
                <HeaderStyle HorizontalAlign="Left" Width="175" Height="1px" />
            </telerik:GridBoundColumn>
            <telerik:GridBoundColumn UniqueName="DisplayValue" HeaderText="" DataField="DisplayValue">
                <ItemStyle HorizontalAlign="Left" />
                <HeaderStyle HorizontalAlign="Left" Height="1px" />
            </telerik:GridBoundColumn>
        </Columns>
    </MasterTableView>
</telerik:RadGrid>

</div></div></div>
<telerik:RadScriptBlock ID="RadScriptBlock1" runat="server">

<script type="text/javascript" language="javascript">

    function EditProjectInfo(id) {

        var oWnd = window.radopen("bondsite_projectinfo_edit.aspx?ProjectID=" + id, "EditWindow");
        return false;
    }



    function GetRadWindow() {
        var oWindow = null;
        if (window.RadWindow) oWindow = window.RadWindow;
        else if (window.frameElement.radWindow) oWindow = window.frameElement.radWindow;
        return oWindow;
    }

    function ManageAttachments(projectid)     //for attachments info display
    {

        var oWnd = window.radopen("apprisepm_attachments_manage.aspx?ParentType=NewsRelease&ParentID=" + projectid + "&ProjectID=" + projectid, "AttachmentsWindow");
        return false;
    }

</script>
</telerik:RadScriptBlock>
</asp:Content>
