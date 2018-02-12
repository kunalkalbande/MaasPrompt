<%@ Page Language="VB" MasterPageFile="~/content.master" Title="" %>
<%@ Register Assembly="Telerik.Web.UI" Namespace="Telerik.Web.UI" TagPrefix="telerik" %>
<%@ Import Namespace="Prompt" %>
<%@ Import Namespace="System.IO" %>
<%@ Import Namespace="System.Configuration" %>

<script runat="server">
    
    Private CollegeID As Integer = 0
    Private ProjectID As Integer = 0
    
    Private bReadOnly As Boolean = True
    
    Dim strImageBasePath As String = ""
    Dim strImagePath As String = ""
    
    Private Sub Page_Load(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MyBase.Load

        ProcLib.CheckSession(Page)
        ProcLib.LoadPopupJscript(Page)

        ''set up help button
        Session("PageID") = "Photos"
        ProjectID = Request.QueryString("ProjectID")
        
        'If Request.Browser.Browser = "IE" Then
        RadGrid1.Height = Unit.Pixel(600)
        'Else
        '.Height = Unit.Percentage(88)
        'End If
        
        Dim masterTabs As RadTabStrip = Master.FindControl("tabMain")
        Session("CurrentTab") = "Photos"
        For Each radTab In masterTabs.GetAllTabs
            If radTab.Value = "Photos" Then
                radTab.Selected = True
                radTab.SelectParents()
                Exit For
            End If
        Next
        
        strImageBasePath = "DistrictID_" & Session("DistrictID") & "/_apprisedocs/_photos/" & "ProjectID_" & ProjectID & "/"
        strImagePath = ProcLib.GetCurrentRelativeAttachmentPath() & strImageBasePath
        
        Dim strFullMainImageFilename = strImagePath & "main.jpg"
        
        Dim strRealPhotoPath As String = ProcLib.GetCurrentAttachmentPath() & strImageBasePath
        Dim strRealImageFilename = strRealPhotoPath & "main.jpg"
        
        Dim folder As New DirectoryInfo(strRealPhotoPath)
        If Not folder.Exists Then  'create the folder if it does not exist
            folder.Create()
        End If

          
        Dim filem As New FileInfo(strRealImageFilename)
        If Not filem.Exists Then  'show none
            imgMain.ImageUrl = "images/none.jpg"
            imgMain.Width = "300"
            imgMain.Height = "225"
            butMainPhoto.Attributes("onclick") = "return UploadMainPhoto(" & ProjectID & ",'y');"
            butMainPhoto.NavigateUrl = "#"
			
        Else
            imgMain.ImageUrl = strFullMainImageFilename & "?t=" & Now()
            butMainPhoto.Attributes("onclick") = "return UploadMainPhoto(" & ProjectID & ",'n');"
            butMainPhoto.NavigateUrl = "#"

        End If
        
        lnkAddNew.Attributes("onclick") = "return EditPhoto(" & ProjectID & ",0);"
        lnkAddNew.NavigateUrl = "#"
        
        With contentPopup
            .VisibleOnPageLoad = False
            .Skin = "Windows7"
                         
            Dim ww As New RadWindow

            ww = New RadWindow
            With ww
                .ID = "EditPhotoWindow"
                .NavigateUrl = "#"
                .Title = ""
                .Width = 500
                .Height = 375
                .Modal = False
                .VisibleStatusbar = False
                .ReloadOnShow = True
                .Behaviors = WindowBehaviors.Close + WindowBehaviors.Move
            End With
            .Windows.Add(ww)
            
   
        End With
        
        
        Using dbsec As New EISSecurity
            dbsec.DistrictID = HttpContext.Current.Session("DistrictID")
            dbsec.CollegeID = HttpContext.Current.Session("CollegeID")
            dbsec.UserID = HttpContext.Current.Session("UserID")
            
            If dbsec.FindUserPermission("ProjectPhotos", "write") Then
                bReadOnly = False
            Else
                bReadOnly = True
                lnkAddNew.Visible = False
                butMainPhoto.Visible = False
                
            End If
            
        End Using
        
        
    End Sub
    
    Protected Sub RadGrid1_NeedDataSource(ByVal source As Object, ByVal e As Telerik.Web.UI.GridNeedDataSourceEventArgs) Handles RadGrid1.NeedDataSource
        'loads the grid whenever it needs data (sorting, rebinding, etc...)
        Using db As New Photo
            RadGrid1.DataSource = db.GetAdditionalPhotos(ProjectID)
        End Using
        
    End Sub
    
    Protected Sub RadGrid1_ItemCreated(ByVal sender As Object, ByVal e As Telerik.Web.UI.GridItemEventArgs) Handles RadGrid1.ItemCreated
        
        'This event allows us to customize the cell contents - fired before databound
        
        If (TypeOf e.Item Is GridDataItem) Then
            Dim item As GridDataItem = CType(e.Item, GridDataItem)
            Dim nPhotoID As Integer = item.OwnerTableView.DataKeyValues(item.ItemIndex)("ApprisePhotoID")
            Dim nProjectID As Integer = item.OwnerTableView.DataKeyValues(item.ItemIndex)("ProjectID")
            Dim strRelativeImagePath As String = strImagePath & nPhotoID & ".jpg"

            'update the link button to open report window
            Dim oImage As WebControls.Image = CType(item("Photo").Controls(0), WebControls.Image)
            With oImage
                .ImageUrl = strRelativeImagePath & "?t=" & Now()
                .Width = "70"
                .Height = "45"
            End With
            
            'update the link button to open report window
            Dim linkButton As HyperLink = CType(item("EditLink").Controls(0), HyperLink)
            linkButton.Attributes("onclick") = "return EditPhoto(" & nProjectID & "," & nPhotoID & ");"
            linkButton.ToolTip = "Edit selected Photo."
            linkButton.NavigateUrl = "#"
            linkButton.ImageUrl = "images/edit.png"
            
            If bReadOnly Then
                linkButton.Visible = False
            End If
            
            Dim linkButton1 As HyperLink = CType(item("GetOriginal").Controls(0), HyperLink)
            If HttpContext.Current.Session("UserRole") = "TechSupport" Then  'show original download
                linkButton1.ToolTip = "Get Original Photo."
                linkButton1.NavigateUrl = Replace(strRelativeImagePath, ".jpg", "_ORIG.jpg")
                linkButton1.Target = "_new"
                linkButton1.Text = "Original..."
                
                lnkGetMainOrig.Target = "_new"
                lnkGetMainOrig.NavigateUrl = strImagePath & "main_ORIG.jpg"
                
            Else
                linkButton1.Visible = False
                lnkGetMainOrig.Visible = False
            End If
            
    
        End If
    End Sub
    
    Private Sub RadGrid1_ItemDataBound(ByVal sender As Object, ByVal e As Telerik.Web.UI.GridItemEventArgs) Handles RadGrid1.ItemDataBound
        
        If TypeOf e.Item Is GridDataItem Then
            
            Dim item As GridDataItem = e.Item
            Dim nPublish As Integer = item.OwnerTableView.DataKeyValues(item.ItemIndex)("PostToWeb")
            If nPublish = 0 Then
                item("PostToWeb").Text = "No"
            Else
                item("PostToWeb").Text = "Yes"
                item("PostToWeb").ForeColor = Color.Green
                item("PostToWeb").Font.Bold = True
            End If
        End If

    End Sub
  

</script>

<asp:Content ID="Content1" ContentPlaceHolderID="mainBody" runat="Server">
    <telerik:RadWindowManager ID="contentPopup" runat="server">
    </telerik:RadWindowManager>
<div id="contentwrapper">
<div style="background:#fff;">
<div class="innertube">
<h2 style="float:left;">Main Photo</h2><asp:HyperLink ID="butMainPhoto" runat="server" CssClass="uploadbtn">Upload Main Photo</asp:HyperLink>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<asp:HyperLink ID="lnkGetMainOrig" runat="server" >Get Original...</asp:HyperLink>
<br class="clear" /><asp:Image ID="imgMain" runat="server" Width="300px" Height="225px" CssClass="main_photo"></asp:Image>
</div>
</div></div>

<div id="contentcolumn" class="clear">
<div class="innertube"><br /><br />
<h2 style="float:left;">Additional Photos</h2><asp:HyperLink ID="lnkAddNew" runat="server" CssClass="addnewbtn">Add Additional Photos</asp:HyperLink>
<br class="clear" />
<telerik:RadGrid ID="RadGrid1" runat="server" AllowSorting="False" AutoGenerateColumns="False"
    GridLines="None" Width="100%"  AllowMultiRowSelection="false" EnableEmbeddedSkins="false" Skin="Prompt">
    <ClientSettings >
        <Selecting AllowRowSelect="false" EnableDragToSelectRows="false"/>
        <Scrolling AllowScroll="True" UseStaticHeaders="True" />
    </ClientSettings>
    <MasterTableView Width="100%" GridLines="None" DataKeyNames="ProjectID,DistrictID,CollegeID,ApprisePhotoID,PostToWeb"
        NoMasterRecordsText="No Additional Photos found.">
        <Columns>
                    <telerik:GridHyperLinkColumn UniqueName="EditLink" HeaderText="Edit">
                <ItemStyle HorizontalAlign="Left" VerticalAlign="Top" Width="30px" />
                <HeaderStyle HorizontalAlign="Left" Width="30px" />
            </telerik:GridHyperLinkColumn>
            <telerik:GridImageColumn UniqueName="Photo" HeaderText="Thumbnail">
                <ItemStyle HorizontalAlign="Left" VerticalAlign="Top" Width="75px" />
                <HeaderStyle HorizontalAlign="Left" Width="75px" />
            </telerik:GridImageColumn>
            <telerik:GridBoundColumn UniqueName="Title" HeaderText="Title" DataField="Title">
                <ItemStyle HorizontalAlign="Left" VerticalAlign="Top" Width="20%" />
                <HeaderStyle HorizontalAlign="Left" Width="20%" />
            </telerik:GridBoundColumn>
            <telerik:GridBoundColumn UniqueName="Description" HeaderText="Description" DataField="Description">
                <ItemStyle HorizontalAlign="Left" VerticalAlign="Top" />
                <HeaderStyle HorizontalAlign="Left" />
            </telerik:GridBoundColumn>
           <telerik:GridBoundColumn UniqueName="DisplayOrder" HeaderText="Order" DataField="DisplayOrder">
                <ItemStyle HorizontalAlign="Left" VerticalAlign="Top" />
                <HeaderStyle HorizontalAlign="Left" />
            </telerik:GridBoundColumn>
            <telerik:GridBoundColumn UniqueName="PostToWeb" HeaderText="Publish" DataField="PostToWeb">
                <ItemStyle HorizontalAlign="Left" VerticalAlign="Top" />
                <HeaderStyle HorizontalAlign="Left" />
            </telerik:GridBoundColumn>
            
            <telerik:GridHyperLinkColumn UniqueName="GetOriginal" HeaderText="">
                <ItemStyle HorizontalAlign="Left" VerticalAlign="Top" Width="30px" />
                <HeaderStyle HorizontalAlign="Left" Width="50px" />
            </telerik:GridHyperLinkColumn>
            
        </Columns>
    </MasterTableView>
</telerik:RadGrid>

</div></div>
<telerik:RadScriptBlock ID="RadScriptBlock1" runat="server">

<script type="text/javascript" language="javascript">

    function EditPhoto(projectid, photoid) {

        var oWnd = window.radopen("photo_edit.aspx?ProjectID=" + projectid + "&ID=" + photoid, "EditPhotoWindow");
        return false;
    }


    function UploadMainPhoto(projectid, isnew) {

        var oWnd = window.radopen("photo_main_upload.aspx?new=" + isnew + "&ProjectID=" + projectid, "EditPhotoWindow");
        return false;
    }

    function DeleteMainPhoto(projectid, collegeid) {

        var oWnd = window.radopen("delete_record.aspx?RecordType=ApprisePMPhoto&main=y&ProjectID=" + projectid, "EditPhotoWindow");
        return false;
    }


    function GetRadWindow() {
        var oWindow = null;
        if (window.RadWindow) oWindow = window.RadWindow;
        else if (window.frameElement.radWindow) oWindow = window.frameElement.radWindow;
        return oWindow;
    }


</script>
</telerik:RadScriptBlock>
</asp:Content>
