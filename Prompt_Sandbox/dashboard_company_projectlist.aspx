<%@ Page Language="VB" %>
<%@ Register Assembly="Telerik.Web.UI" Namespace="Telerik.Web.UI" TagPrefix="telerik" %>
<%@ Import Namespace="Prompt" %>

<script runat="server">
    
    Private Sub Page_Load(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MyBase.Load

        Session("PageID") = "dashboard_company_projectlist"

        'Set Grid Properties
        With RadGrid1
            .EnableEmbeddedSkins = False
            .Skin = "Prompt"
            .GroupingEnabled = False
            .AllowSorting = True
                        
            .ClientSettings.AllowColumnsReorder = True
            .ClientSettings.ColumnsReorderMethod = GridClientSettings.GridColumnsReorderMethod.Reorder
            .ClientSettings.Scrolling.AllowScroll = True
            .ClientSettings.Scrolling.ScrollHeight = Unit.Percentage(50)
            .ClientSettings.Scrolling.UseStaticHeaders = True
            .ClientSettings.Resizing.AllowColumnResize = True

            .MasterTableView.EnableHeaderContextMenu = False
            .MasterTableView.TableLayout = GridTableLayout.Fixed
            .MasterTableView.AllowMultiColumnSorting = False

            .Height = Unit.Pixel(450)

            .ExportSettings.FileName = "PromptProjectListExport"
            .ExportSettings.OpenInNewWindow = True
            .ExportSettings.Pdf.PageTitle = "PromptProjectListExport"
        End With
    
        If Not IsPostBack Then
           
   
        End If

    End Sub
    
    Protected Sub RadGrid1_NeedDataSource(ByVal source As Object, ByVal e As Telerik.Web.UI.GridNeedDataSourceEventArgs) Handles RadGrid1.NeedDataSource
        
        Dim tbl As DataTable
        Dim tblResult As DataTable
        
        Using db As New PromptDataHelper
            Dim sql As String = "SELECT * FROM Projects WHERE DistrictID = " & Session("DistrictID") & " ORDER BY ProjectName "
            tbl = db.ExecuteDataTable(sql)
            tblResult = tbl.Copy
        End Using
        
        Using dbsec As New EISSecurity
            
            For Each row As DataRow In tbl.Rows
                Dim bFound As Boolean = False
                Dim tblGoodProjects As DataTable = dbsec.GetAssignedProjectIDList(row("CollegeID"))    'get the list of assigned projects
                For Each rowproject As DataRow In tblGoodProjects.Rows
                    If row("ProjectID") = rowproject("ProjectID") Then     'found so ok
                        bFound = True
                        Exit For
                    End If
                Next
                If Not bFound Then   'remove the project from the result table
                    For Each rowresult As DataRow In tblResult.Rows
                        If row("ProjectID") = rowresult("ProjectID") Then     'remove
                            tblResult.Rows.Remove(rowresult)
                            Exit For
                        End If
                    Next
                    
                End If

            Next

        End Using
            
            
        RadGrid1.DataSource = tblResult

    End Sub
    
    Protected Sub RadGrid1_ItemCreated(ByVal sender As Object, ByVal e As Telerik.Web.UI.GridItemEventArgs) Handles RadGrid1.ItemCreated
        
        'This event allows us to customize the cell contents - fired before databound
        
        If (TypeOf e.Item Is GridDataItem) Then
            Dim item As GridDataItem = CType(e.Item, GridDataItem)
            Dim nProjectID As Integer = item.OwnerTableView.DataKeyValues(item.ItemIndex)("ProjectID")
            Dim nCollegeID As Integer = item.OwnerTableView.DataKeyValues(item.ItemIndex)("CollegeID")
            
            Dim linkButton As HyperLink = CType(item("ProjectName").Controls(0), HyperLink)
            linkButton.ToolTip = "Open this Project."
            linkButton.NavigateUrl = "project_overview.aspx?view=project&ProjectID=" & nProjectID & "&CollegeID=" & nCollegeID
                       

        End If
        
        
    End Sub
    
    Private Sub RadGrid1_ItemDataBound(ByVal sender As Object, ByVal e As Telerik.Web.UI.GridItemEventArgs) Handles RadGrid1.ItemDataBound
        If (TypeOf e.Item Is GridDataItem) Then
            Dim dataItem As GridDataItem = CType(e.Item, GridDataItem)
            Dim sStatus As String = ProcLib.CheckNullDBField(dataItem.OwnerTableView.DataKeyValues(dataItem.ItemIndex)("Status"))

            sStatus = Mid(sStatus, 3)
            dataItem("Status").Text = sStatus
                        
            
        End If
        
    End Sub
    
  
</script>

<html>
<head>
    <title>Project List</title>
     <link href="Styles.css" type="text/css" rel="stylesheet" />
    <link href="skins/Prompt/TabStrip.Prompt.css" rel="stylesheet" type="text/css" />
    <link href="skins/Prompt/Grid.Prompt.css" rel="stylesheet" type="text/css" />
    <link href="skins/Prompt/Dock.Prompt.css" rel="stylesheet" type="text/css" />
    <link href="skins/Prompt/Menu.Prompt.css" rel="stylesheet" type="text/css" />
    <link href="skins/Prompt/TreeView.Prompt.css" rel="stylesheet" type="text/css" />

    <script type="text/javascript" language="javascript">


        function GetRadWindow() {
            var oWindow = null;
            if (window.radWindow) oWindow = window.radWindow; //Will work in Moz in all cases, including clasic dialog
            else if (window.frameElement.radWindow) oWindow = window.frameElement.radWindow; //IE (and Moz az well)

            return oWindow;
        }

 	   
    </script>

</head>
<body>
    <form id="Form1" method="post" runat="server">
    <telerik:RadScriptManager ID="RadScriptManager1" runat="server" />
   
    <telerik:RadGrid ID="RadGrid1" runat="server" AllowSorting="true" AutoGenerateColumns="False"
        GridLines="None" Width="99%" EnableEmbeddedSkins="false" enableajax="True" Skin="Prompt">
        <ClientSettings>
            <Selecting AllowRowSelect="False" />
            <Scrolling AllowScroll="True" UseStaticHeaders="True" ScrollHeight="50%" />
        </ClientSettings>
        <MasterTableView Width="99%" GridLines="None" DataKeyNames="ProjectID,CollegeID,Status"
            NoMasterRecordsText="No Projects found.">
            <Columns>
                <telerik:GridHyperLinkColumn UniqueName="ProjectName" HeaderText="Project" DataTextField="ProjectName"
                    SortExpression="ProjectName">
                    <ItemStyle HorizontalAlign="Left" Width="155px" VerticalAlign="Top" />
                    <HeaderStyle HorizontalAlign="Left" Width="155px" />
                </telerik:GridHyperLinkColumn>
                <telerik:GridBoundColumn UniqueName="ProjectNumber" HeaderText="ProjectNumber" DataField="ProjectNumber">
                    <ItemStyle HorizontalAlign="Left" Width="55px" VerticalAlign="Top" />
                    <HeaderStyle HorizontalAlign="Left" Width="55px" />
                </telerik:GridBoundColumn>
                               <telerik:GridBoundColumn UniqueName="Description" HeaderText="Description" DataField="Description">
                    <ItemStyle HorizontalAlign="Left" Width="245px" VerticalAlign="Top" />
                    <HeaderStyle HorizontalAlign="Left" Width="245px" />
                </telerik:GridBoundColumn>
                <telerik:GridBoundColumn UniqueName="Status" HeaderText="Status" DataField="Status">
                    <ItemStyle HorizontalAlign="Left" Width="45px" VerticalAlign="Top" />
                    <HeaderStyle HorizontalAlign="Left" Width="45px" />
                </telerik:GridBoundColumn>

            </Columns>
        </MasterTableView>
 
    </telerik:RadGrid>
    
        <telerik:RadAjaxManager ID="RadAjaxManager1" runat="server">
        <AjaxSettings>
            <telerik:AjaxSetting AjaxControlID="RadGrid1">
                <UpdatedControls>
                    <telerik:AjaxUpdatedControl ControlID="RadGrid1" LoadingPanelID="RadAjaxLoadingPanel1" />
                </UpdatedControls>
            </telerik:AjaxSetting>
            <telerik:AjaxSetting AjaxControlID="RadMenu1">
                <UpdatedControls>
                    <telerik:AjaxUpdatedControl ControlID="RadGrid1" LoadingPanelID="RadAjaxLoadingPanel1" />
                    <telerik:AjaxUpdatedControl ControlID="RadMenu1" LoadingPanelID="RadAjaxLoadingPanel1" />
                </UpdatedControls>
            </telerik:AjaxSetting>
        </AjaxSettings>
    </telerik:RadAjaxManager>
    <telerik:RadAjaxLoadingPanel ID="RadAjaxLoadingPanel1" runat="server" Height="75px"
        Width="75px" Transparency="25">
        <img alt="Loading..." src="images/loading.gif" style="border: 0;" />
    </telerik:RadAjaxLoadingPanel>

    
    </form>
</body>
</html>