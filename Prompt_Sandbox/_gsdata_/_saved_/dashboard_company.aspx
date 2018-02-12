<%@ Page Language="VB" MasterPageFile="~/prompt.master" %>
<%@ Register Assembly="Telerik.Web.UI" Namespace="Telerik.Web.UI" TagPrefix="telerik" %>
<%@ Import Namespace="Prompt" %>

<script runat="server">
    

    Private sNavFilter As String = ""

    Private Sub Page_Load(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MyBase.Load

        Session("PageID") = "dashboard_company"

            
        Dim mm As MasterPage = Page.Master
        Dim menu As RadMenu = mm.FindControl("RadMenu1")
  
        Dim menuDistrict As RadMenuItem = menu.FindItemByValue("District")
        menuDistrict.Text = Session("DistrictName")
            
        Dim menuAppLogo As RadMenuItem = menu.FindItemByValue("AppLogo")
        Dim sLocale As String = ProcLib.GetLocale()
        With menuAppLogo
            If sLocale = "Production" Then
                If Session("UsePromptName") = 1 Then
                    .ImageUrl = "images/Prompt_local.gif"
                Else
                    .ImageUrl = "images/logo.png"
                End If
                .Width = Unit.Pixel(200)
                Page.Header.Title = "Welcome to Prompt"
                    
            ElseIf sLocale = "Beta" Or sLocale = "VMBeta" Then
                .Value = "AppLogo"
                    
                If Session("UsePromptName") = 1 Then
                    .ImageUrl = "images/logo_beta.png"
                Else
                    .ImageUrl = "images/logo.png"
                End If
                .Width = Unit.Pixel(200)
                Page.Header.Title = "Prompt Beta"
            Else
                .Value = "AppLogo"
                If Session("UsePromptName") = 1 Then
                    .ImageUrl = "images/Prompt_local.gif"
                Else
                    .ImageUrl = "images/logo.png"
                End If
                .Width = Unit.Pixel(195)
                .CssClass = "logoheader"
                Page.Header.Title = "Prompt Local"
            End If
        End With
            
        'Now hide the reports and admin menus
        Dim menuReports As RadMenuItem = menu.FindItemByValue("Reports")
        menuReports.Visible = False
            
        Dim menuAdmin As RadMenuItem = menu.FindItemByValue("Administration")
        menuAdmin.Visible = False

        Dim menuHome As RadMenuItem = menu.FindItemByValue("Home")
        menuHome.Text = "Projects"
        menuHome.NavigateUrl = "dashboard_company.aspx"
  
                
        If Not IsPostBack Then

            contentPane.ContentUrl = "dashboard_company_projectlist.aspx?view=project&ProjectID=738&CollegeID=113"

        End If

    End Sub
    
  
</script>

<asp:Content ID="Content1" ContentPlaceHolderID="mainBody" runat="Server">
    <telerik:RadSplitter ID="RadSplitter1" runat="server" Skin="Sitefinity" Width="100%" Height="95%" SplitBarsSize="8" >
         
        <telerik:RadPane ID="contentPane" runat="server" Scrolling="Both"  EnableViewState="true" ContentUrl="about:blank">content pane</telerik:RadPane>
    </telerik:RadSplitter>


    <script type="text/javascript" language="javascript">

        function refreshParentPage() {     //called from child pages when reloaded after edit and when nav needs updating
            document.location.href = 'dashboard_company.aspx';
        }

    </script>
</asp:Content>