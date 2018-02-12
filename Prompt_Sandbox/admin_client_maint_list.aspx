<%@ Page Language="VB" %>
<%@ Import Namespace="Prompt" %>
<%@ Register Assembly="Telerik.Web.UI" Namespace="Telerik.Web.UI" TagPrefix="telerik" %>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">

<script runat="server">
        
 

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs)
                          
        Session("PageID") = "AdminClientMaintList"
  
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

            .Height = Unit.Pixel(600)

            .ExportSettings.FileName = "PromptRFIExport"
            .ExportSettings.OpenInNewWindow = True
            .ExportSettings.Pdf.PageTitle = "Client/Districts/Colleges"
        End With
        
        'Configure the Popup Window(s)
        With MasterPopups
            .VisibleOnPageLoad = False
            .Skin = "Office2007"
                  
            Dim ww As New RadWindow
            With ww
                .ID = "EditClient"
                .NavigateUrl = ""
                .Title = ""
                .Width = 500
                .Height = 250
                .Modal = True
                .VisibleStatusbar = True
                .ReloadOnShow = True
                .Behaviors = WindowBehaviors.Close + WindowBehaviors.Move
            End With
            .Windows.Add(ww)
            
        
            ww = New RadWindow
            With ww
                .ID = "EditDistrict"
                .NavigateUrl = ""
                .Title = ""
                .Width = 600
                .Height = 550
                .Modal = True
                .VisibleStatusbar = True
                .ReloadOnShow = True
                .Behaviors = WindowBehaviors.Close + WindowBehaviors.Move
            End With
            .Windows.Add(ww)
            
            ww = New RadWindow
            With ww
                .ID = "EditCollege"
                .NavigateUrl = ""
                .Title = ""
                .Width = 600
                .Height = 650
                .Modal = True
                .VisibleStatusbar = True
                .ReloadOnShow = True
                .Behaviors = WindowBehaviors.Close + WindowBehaviors.Move
            End With
            .Windows.Add(ww)
            
        End With
        
        'Configure Add New Button
        butAddNew.Attributes("onclick") = "return EditClient('0');"
        butAddNew.NavigateUrl = "#"
        butAddNew.ToolTip = "Add new Client"
        
        
    End Sub
    Protected Sub RadGrid1_NeedDataSource(ByVal source As Object, ByVal e As Telerik.Web.UI.GridNeedDataSourceEventArgs) Handles RadGrid1.NeedDataSource
        'loads the grid whenever it needs data (sorting, rebinding, etc...)
        Using db As New Client
            RadGrid1.DataSource = db.GetClientList()
        End Using
    End Sub
    
    Private Sub RadGrid1_DetailTableDataBind(ByVal source As Object, ByVal e As Telerik.Web.UI.GridDetailTableDataBindEventArgs) Handles RadGrid1.DetailTableDataBind
        Dim nKey As Integer = 0
        Dim dataItem As GridDataItem = CType(e.DetailTableView.ParentItem, GridDataItem)
        
        If (e.DetailTableView.DataMember = "Districts") Then
            nKey = dataItem.GetDataKeyValue("ClientID")
            Using db As New District
                e.DetailTableView.DataSource = db.GetDistrictList(nKey)
            End Using
        End If

        If (e.DetailTableView.DataMember = "Colleges") Then
            nKey = dataItem.GetDataKeyValue("DistrictID")
            Using db As New College
                e.DetailTableView.DataSource = db.GetCollegeList(nKey)
            End Using
        End If
        
  
    End Sub

    
    Protected Sub RadGrid1_ItemCreated(ByVal sender As Object, ByVal e As Telerik.Web.UI.GridItemEventArgs) Handles RadGrid1.ItemCreated
        'This event allows us to customize the cell contents - fired before databound
        If e.Item.OwnerTableView.DataMember = "Clients" Then
            If (TypeOf e.Item Is GridDataItem) Then
               
                Dim item As GridDataItem = CType(e.Item, GridDataItem)
                Dim nClientID As Integer = item.OwnerTableView.DataKeyValues(item.ItemIndex)("ClientID")
                          
                'update the link button to open edit window
                Dim linkButton As HyperLink = CType(item("EditClient").Controls(0), HyperLink)
                linkButton.Attributes("onclick") = "return EditClient('" & nClientID & "');"
                linkButton.ToolTip = "Edit this Client."
                linkButton.NavigateUrl = "#"
                linkButton.ImageUrl = "images/edit.png"
            
                'update the link button to open edit window
                Dim linkButton1 As HyperLink = CType(item("AddDistrict").Controls(0), HyperLink)
                linkButton1.Attributes("onclick") = "return AddDistrict('" & nClientID & "');"
                linkButton1.ToolTip = "Add a District for this Client."
                linkButton.NavigateUrl = "#"
                linkButton1.ImageUrl = "images/add_scenerio_step.gif"
          
            End If
             
        End If
        If e.Item.OwnerTableView.DataMember = "Districts" Then 'child view  
            If (TypeOf e.Item Is GridDataItem) Then
               
                Dim item As GridDataItem = CType(e.Item, GridDataItem)
                Dim nDistrictID As Integer = item.OwnerTableView.DataKeyValues(item.ItemIndex)("DistrictID")
                Dim nClientID As Integer = item.OwnerTableView.DataKeyValues(item.ItemIndex)("ClientID")
                          
                'update the link button to open edit window
                Dim linkButton As HyperLink = CType(item("DistrictEdit").Controls(0), HyperLink)
                linkButton.Attributes("onclick") = "return EditDistrict('" & nDistrictID & "','" & nClientID & "');"
                linkButton.ToolTip = "Edit this District."
                linkButton.NavigateUrl = "#"
                linkButton.ImageUrl = "images/edit.png"
                
                Dim linkButton1 As HyperLink = CType(item("AddCollege").Controls(0), HyperLink)
                linkButton1.Attributes("onclick") = "return AddCollege('" & nDistrictID & "','" & nClientID & "');"
                linkButton1.ToolTip = "Add a College for this District."
                linkButton.NavigateUrl = "#"
                linkButton1.ImageUrl = "images/add_scenerio_step.gif"
            
          
            End If
        End If
        
        If e.Item.OwnerTableView.DataMember = "Colleges" Then 'child view  
            If (TypeOf e.Item Is GridDataItem) Then
               
                Dim item As GridDataItem = CType(e.Item, GridDataItem)
                Dim nDistrictID As Integer = item.OwnerTableView.DataKeyValues(item.ItemIndex)("DistrictID")
                Dim nCollegeID As Integer = item.OwnerTableView.DataKeyValues(item.ItemIndex)("CollegeID")
                          
                'update the link button to open edit window
                Dim linkButton As HyperLink = CType(item("CollegeEdit").Controls(0), HyperLink)
                linkButton.Attributes("onclick") = "return EditCollege('" & nCollegeID & "','" & nDistrictID & "');"
                linkButton.ToolTip = "Edit this College."
                linkButton.NavigateUrl = "#"
                linkButton.ImageUrl = "images/edit.png"
                
                          
          
            End If
        End If
    End Sub
    
    'Protected Overrides Sub RaisePostBackEvent(ByVal source As IPostBackEventHandler, ByVal eventArgument As String)
    '    'Listens for pop window calling to refresh grid after some edit.
    '    MyBase.RaisePostBackEvent(source, eventArgument)
    '    If TypeOf source Is RadGrid Then
    '        Select Case eventArgument
    '            Case "Rebind"
    '                RadGrid1.Rebind()
    '        End Select
    '    End If
    'End Sub


</script>

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title>Admin Client Maintenance </title>
    <link href="Styles.css" rel="stylesheet" type="text/css" />
        <link href="skins/Prompt/Grid.Prompt.css" rel="stylesheet" type="text/css" />
</head>
<body>
    <form id="Form1" method="post" runat="server">
    <telerik:RadScriptManager ID="RadScriptManager1" runat="server" />
    <asp:Table ID="Table1" runat="server" Style="z-index: 102; left: 8px; position: absolute;
        top: 17px" Width="97%">
        <asp:TableRow ID="TableRow1" runat="server">
            <asp:TableCell ID="TableCell1" runat="server" Width="50%" HorizontalAlign="Left">
                <asp:Label ID="Label1" runat="server" Text="Maintain Clients" Font-Underline="true"></asp:Label>
            </asp:TableCell>
            <asp:TableCell ID="lblTitle" runat="server" HorizontalAlign="Right">
                <asp:HyperLink ID="butAddNew" runat="server" ImageUrl="images\button_add_new.gif"></asp:HyperLink>
            </asp:TableCell>
        </asp:TableRow>
    </asp:Table>
    <telerik:RadGrid Style="z-index: 100; left: 5px; position: absolute; top: 47px" ID="RadGrid1"
        runat="server" AllowSorting="True" AutoGenerateColumns="False" Width="99%" EnableAJAX="True"
        Skin="Sitefinity" Height="90%" DataMember="Client" OnDetailTableDataBind="RadGrid1_DetailTableDataBind"
        OnNeedDataSource="RadGrid1_NeedDataSource">
        <ClientSettings>
            <Selecting AllowRowSelect="True" />
            <Scrolling AllowScroll="True" UseStaticHeaders="True" ScrollHeight="80%" />
        </ClientSettings>
        <MasterTableView Width="100%" GridLines="None" DataKeyNames="ClientID" NoMasterRecordsText="No Clients Found."
            DataMember="Clients">
            <DetailTables>
                <telerik:GridTableView DataKeyNames="DistrictID,ClientID" Width="100%" runat="server"
                    Name="Districts" DataMember="Districts" NoDetailRecordsText="No Districts Found."
                    ShowHeadersWhenNoRecords="true">
                    <DetailTables>
                        <telerik:GridTableView DataKeyNames="DistrictID,ClientID,CollegeID" Width="100%"
                            runat="server" Name="Colleges" DataMember="Colleges" NoDetailRecordsText="No Colleges Found."
                            ShowHeadersWhenNoRecords="true">
                            <Columns>
                                <telerik:GridHyperLinkColumn UniqueName="CollegeEdit">
                                    <ItemStyle Width="35px" HorizontalAlign="Center" VerticalAlign="Top" />
                                    <HeaderStyle Width="35px" HorizontalAlign="Center" />
                                </telerik:GridHyperLinkColumn>
                                <telerik:GridBoundColumn DataField="College" UniqueName="College" HeaderText="College">
                                    <ItemStyle HorizontalAlign="Left" VerticalAlign="Top" />
                                    <HeaderStyle HorizontalAlign="Left" />
                                </telerik:GridBoundColumn>
                            </Columns>
                        </telerik:GridTableView>
                    </DetailTables>
                    <Columns>
                        <telerik:GridHyperLinkColumn UniqueName="DistrictEdit">
                            <ItemStyle Width="35px" HorizontalAlign="Center" VerticalAlign="Top" />
                            <HeaderStyle Width="35px" HorizontalAlign="Center" />
                        </telerik:GridHyperLinkColumn>
                        <telerik:GridBoundColumn DataField="Name" UniqueName="Name" HeaderText="District">
                            <ItemStyle HorizontalAlign="Left" VerticalAlign="Top" />
                            <HeaderStyle HorizontalAlign="Left" />
                        </telerik:GridBoundColumn>
                        <telerik:GridHyperLinkColumn HeaderText="Add College" UniqueName="AddCollege">
                            <ItemStyle Width="95px" HorizontalAlign="Center" VerticalAlign="Top" />
                            <HeaderStyle Width="95px" HorizontalAlign="Center" />
                        </telerik:GridHyperLinkColumn>
                    </Columns>
                </telerik:GridTableView>
            </DetailTables>
            <Columns>
                <telerik:GridHyperLinkColumn UniqueName="EditClient">
                    <ItemStyle Width="35px" HorizontalAlign="Center" VerticalAlign="Top" />
                    <HeaderStyle Width="35px" HorizontalAlign="Center" />
                </telerik:GridHyperLinkColumn>
                <telerik:GridBoundColumn DataField="ClientName" UniqueName="ClientName" HeaderText="Client">
                    <ItemStyle HorizontalAlign="Left" VerticalAlign="Top" />
                    <HeaderStyle HorizontalAlign="Left" Width="80%" />
                </telerik:GridBoundColumn>
 
                <telerik:GridHyperLinkColumn HeaderText="Add District" UniqueName="AddDistrict">
                    <ItemStyle Width="35px" HorizontalAlign="Center" VerticalAlign="Top" />
                    <HeaderStyle Width="35px" HorizontalAlign="Center" />
                </telerik:GridHyperLinkColumn>
            </Columns>
        </MasterTableView>
    </telerik:RadGrid>
    
                  <telerik:radajaxmanager id="RadAjaxManager1" runat="server">
                 <ClientEvents OnRequestStart="ajaxRequestStart" OnResponseEnd="ajaxRequestEnd" />
                    <AjaxSettings>
                        <telerik:AjaxSetting AjaxControlID="RadGrid1">
                            <UpdatedControls>
                                <telerik:AjaxUpdatedControl ControlID="RadGrid1" LoadingPanelID="RadAjaxLoadingPanel1" />
                            </UpdatedControls>
                        </telerik:AjaxSetting>

                    </AjaxSettings>
                </telerik:radajaxmanager>
                <telerik:radajaxloadingpanel id="RadAjaxLoadingPanel1" runat="server" height="75px"
                    width="75px" transparency="25">
                    <img alt="Loading..." src="images/loading.gif" style="border: 0;" />
                </telerik:radajaxloadingpanel>
    
    <telerik:RadWindowManager ID="MasterPopups" runat="server">
    </telerik:RadWindowManager>
    </form>
    
       <telerik:radscriptblock id="RadScriptBlock1" runat="server">

        <script type="text/javascript" language="javascript">

            // Begin ******************* Menu Handlers ***********************

            var sCancelAjax;    // flag to disable ajax for grid export functions

            function ajaxRequestStart(sender, args) {
                //Called when ajax request starts so we can disable for grid export controls.
                if (sCancelAjax == 'Y') {
                    args.set_enableAjax(false);
                }
            }

            function ajaxRequestEnd(sender, args) {
                //Called when ajax request Ends.
                args.set_enableAjax(true);
            }

            function OnClientItemClicking(sender, args) {
                // set this var so that we can cancel ajax for grid export function
                var button = args.get_item();
                sCancelAjax = button.get_attributes().getAttribute("CancelAjax");
            }


            // End ******************* Menu Handlers ***********************

            function EditClient(id)     //for editing object code
            {
                var oWnd = window.radopen("client_edit.aspx?ClientID= " + id, "EditClient");
                return false;
            }

            function AddDistrict(id) {
                var oWnd = window.radopen("district_edit.aspx?DistrictID=0&ClientID= " + id, "EditDistrict");
                return false;
            }

            function EditDistrict(id, clientID) {
                var oWnd = window.radopen("district_edit.aspx?DistrictID=" + id + "&ClientID=" + clientID, "EditDistrict");
                return false;
            }

            function AddCollege(districtID, clientID) {
                var oWnd = window.radopen("college_edit.aspx?CollegeID=0&DistrictID= " + districtID + "&ClientID= " + clientID, "EditCollege");
                return false;
            }

            function EditCollege(collegeID, districtID) {
                var oWnd = window.radopen("college_edit.aspx?CollegeID=" + collegeID + "&DistrictID= " + districtID, "EditCollege");
                return false;
            }
            function GetRadWindow() {
                var oWindow = null;
                if (window.RadWindow) oWindow = window.RadWindow;
                else if (window.frameElement.radWindow) oWindow = window.frameElement.radWindow;
                return oWindow;
            }

        </script>

    </telerik:radscriptblock>

   

</body>
</html>
