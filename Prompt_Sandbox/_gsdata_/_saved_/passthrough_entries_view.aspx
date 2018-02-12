<%@ Page Language="VB" MasterPageFile="~/content.master" Title="" %>
<%@ Register Assembly="Telerik.Web.UI" Namespace="Telerik.Web.UI" TagPrefix="telerik" %>
<%@ Import Namespace="Prompt" %>

<script runat="server">
    
    Private nProjectID As Integer = 0
    Private TotalAmount As Double = 0
    Private TotalCredits As Double = 0
    Private TotalDebits As Double = 0
    
    Private bIsPassthroughProject As Boolean = False
    Private bEnabled As Boolean = False
    
    Private Sub Page_Load(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MyBase.Load

        ProcLib.CheckSession(Page)
        ProcLib.LoadPopupJscript(Page)
        Session("PageID") = "PassthroughEntriesView"
        nProjectID = Request.QueryString("ProjectID")
        
        'If Request.Browser.Browser = "IE" Then
        RadGrid1.Height = Unit.Pixel(600)
        'Else
        '.Height = Unit.Percentage(88)
        'End If
        
        Dim masterTabs As RadTabStrip = Master.FindControl("tabMain")
        Session("CurrentTab") = "Passthrough"
        For Each radTab In masterTabs.GetAllTabs
            If radTab.Value = "Passthrough" Then
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
                .ID = "EditEntry"
                .NavigateUrl = ""
                .Title = ""
                .Width = 550
                .Height = 250
                .Top = 200
                .Left = 20
                .Modal = False
                .VisibleStatusbar = False
                .ReloadOnShow = True
                .Behaviors = WindowBehaviors.Close + WindowBehaviors.Move + WindowBehaviors.Resize
            End With
            .Windows.Add(ww)
            
                       ww = New RadWindow
            With ww
                .ID = "AddEntry"
                .NavigateUrl = ""
                .Title = ""
                .Width = 550
                .Height = 500
                .Top = 200
                .Left = 20
                .Modal = False
                .VisibleStatusbar = False
                .ReloadOnShow = True
                .Behaviors = WindowBehaviors.Close + WindowBehaviors.Move + WindowBehaviors.Resize
            End With
            .Windows.Add(ww)
            
        End With
        
        'update the link button 
        lnkAllocate.Attributes("onclick") = "return AddAllocationEntry('" & nProjectID & "');"
        lnkAllocate.NavigateUrl = "#"
  
        Using DB As New promptPassthrough
            bIsPassthroughProject = DB.IsPassthroughProject(nProjectID)
        End Using
        
        'Lock down view only Clients
        Using db As New EISSecurity
            db.CollegeID = Session("CollegeID")
            db.ProjectID = nProjectID
            If db.FindUserPermission("ProjectPassthroughInfo", "Write") = True Then
                bEnabled = True
            End If

        End Using
        
        
         
    End Sub
    
    Protected Sub RadGrid1_NeedDataSource(ByVal source As Object, ByVal e As Telerik.Web.UI.GridNeedDataSourceEventArgs) Handles RadGrid1.NeedDataSource
        'loads the grid whenever it needs data (sorting, rebinding, etc...)
        If Not e.IsFromDetailTable Then
            Using db As New promptPassthrough
                db.CallingPage = Page
                RadGrid1.DataSource = db.GetPassthroughEntries(nProjectID)
            
                If bIsPassthroughProject Then
                    bIsPassthroughProject = True
                    lnkAllocate.Visible = True
                Else
                    lnkAllocate.Visible = False
                End If
            End Using
        End If
    End Sub
    
      
    Protected Sub RadGrid1_ItemCreated(ByVal sender As Object, ByVal e As Telerik.Web.UI.GridItemEventArgs) Handles RadGrid1.ItemCreated
        'This event allows us to customize the cell contents - fired before databound

        If (TypeOf e.Item Is GridDataItem) Then
            Dim item As GridDataItem = CType(e.Item, GridDataItem)
            Dim nPassthroughEntryID As Integer = item.OwnerTableView.DataKeyValues(item.ItemIndex)("PassthroughEntryID")
            Dim nProjectID As Integer = item.OwnerTableView.DataKeyValues(item.ItemIndex)("ProjectID")

            'update the link button to open attachments/notes window
            Dim lnk As HyperLink = CType(item("EditEntry").Controls(0), HyperLink)
            lnk.Attributes("onclick") = "return EditAllocationEntry('" & nProjectID & "','" & nPassthroughEntryID & "');"
            lnk.ToolTip = "Edit this allocation entry."
            lnk.ImageUrl = "images/edit.png"
            lnk.NavigateUrl = "#"
            If bEnabled = False Then
                lnk.Visible = False
            End If
  
        End If
    End Sub
    
    Private Sub RadGrid1_ItemDataBound(ByVal sender As Object, ByVal e As Telerik.Web.UI.GridItemEventArgs) Handles RadGrid1.ItemDataBound
        If (TypeOf e.Item Is GridDataItem) Then
            Dim dataItem As GridDataItem = CType(e.Item, GridDataItem)
            Dim nAmount As Double = dataItem.OwnerTableView.DataKeyValues(dataItem.ItemIndex)("Amount")
            TotalAmount += nAmount

        End If
        If (TypeOf e.Item Is GridFooterItem) Then
            Dim footerItem As GridFooterItem = CType(e.Item, GridFooterItem)
            footerItem("Amount").Text = FormatCurrency(TotalAmount)
            footerItem("Action").Text = "Total: " & " &nbsp;&nbsp;&nbsp; &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;"


        End If
    End Sub

    Protected Sub butPrint_Click(ByVal sender As Object, ByVal e As System.Web.UI.ImageClickEventArgs)
        
        RadGrid1.MasterTableView.ExportToExcel()     'TODO: Export to Excel needs 2 clicks for some reason
        
    End Sub


</script>

<asp:Content ID="Content1" ContentPlaceHolderID="mainBody" runat="Server">
    <telerik:RadWindowManager ID="contentPopup" runat="server">
    </telerik:RadWindowManager>
<%--<div id="contentwrapper">--%>
<div id="navrow">
<asp:ImageButton ID="butPrint" ImageURL = "images/export_to_excel.png" runat="server" onclick="butPrint_Click" Style="margin:9px;"></asp:ImageButton>
<asp:HyperLink ID="lnkAllocate" ImageUrl="~/images/passthrough_allocation_add.png" runat="server">Allocate</asp:HyperLink>
</div>
<%--<div id="contentcolumn">
<div class="innertube">--%>
            <telerik:RadGrid ID="RadGrid1" runat="server" AllowSorting="true" AutoGenerateColumns="False"
                GridLines="None" Width="100%" EnableAJAX="False" HierarchyDefaultExpanded="true" EnableEmbeddedSkins="false" Skin="Prompt">
                <ClientSettings>
                    <Scrolling AllowScroll="False" UseStaticHeaders="True" />
                </ClientSettings>
                <MasterTableView Width="100%" GridLines="None" NoMasterRecordsText="No Passthrough Entries Found."
                    ShowHeadersWhenNoRecords="True" DataKeyNames="Amount,PassthroughEntryID,ProjectID,PassthroughProjectID"
                    ShowFooter="true">
                    <Columns>

                        <telerik:GridHyperLinkColumn HeaderText="Edit" UniqueName="EditEntry">
                            <ItemStyle Width="35px" HorizontalAlign="Left" />
                            <HeaderStyle Width="35px" HorizontalAlign="Left" />
                        </telerik:GridHyperLinkColumn>
                        <telerik:GridBoundColumn DataField="EntryDate" HeaderText="Date" UniqueName="EntryDate"
                            DataFormatString="{0:MM/dd/yyyy}">
                            <ItemStyle Width="75px" HorizontalAlign="Left" VerticalAlign="Top" />
                            <HeaderStyle Width="75px" Height="20px" HorizontalAlign="Left" />
                        </telerik:GridBoundColumn>
                        <telerik:GridBoundColumn DataField="Description" UniqueName="Description" HeaderText="Description">
                            <ItemStyle HorizontalAlign="Left" VerticalAlign="Top" Width="30%" />
                            <HeaderStyle HorizontalAlign="Left" Width="30%" Height="15px" />
                            <FooterStyle HorizontalAlign="Right" Width="30%" Height="15px" />
                        </telerik:GridBoundColumn>
                        <telerik:GridBoundColumn DataField="Action" UniqueName="Action" HeaderText="Action">
                            <ItemStyle HorizontalAlign="Left" VerticalAlign="Top" Width="50%" />
                            <HeaderStyle HorizontalAlign="Left" Width="50%" Height="15px" />
                            <FooterStyle HorizontalAlign="Center" Width="50%" Height="15px" />
                        </telerik:GridBoundColumn>
                        <telerik:GridBoundColumn DataField="Amount" HeaderText="Amount" UniqueName="Amount"
                            DataFormatString="{0:c}" Visible="True">
                            <ItemStyle Width="130px" HorizontalAlign="Right" VerticalAlign="Top" />
                            <HeaderStyle Width="130px" HorizontalAlign="Right" />
                            <FooterStyle HorizontalAlign="Right" Width="130px" Height="15px" />
                        </telerik:GridBoundColumn>
                    </Columns>
 
                </MasterTableView>
                <ExportSettings FileName="PromptPassthroughEntriesExport" OpenInNewWindow="True">
                </ExportSettings>
            </telerik:RadGrid>


<telerik:RadAjaxManager ID="RadAjaxManager1" runat="server">
 <AjaxSettings>
   <telerik:AjaxSetting AjaxControlID="RadGrid1">
     <UpdatedControls>
       <telerik:AjaxUpdatedControl ControlID="RadGrid1" LoadingPanelID="RadAjaxLoadingPanel1"/>
     </UpdatedControls>
   </telerik:AjaxSetting>
 </AjaxSettings>
</telerik:RadAjaxManager>
<telerik:RadAjaxLoadingPanel ID="RadAjaxLoadingPanel1" runat="server" Height="75px" Width="75px" Transparency="25">
 <img alt="Loading..." src="loading.gif" style="border:0;" />
</telerik:RadAjaxLoadingPanel>




<%--</div></div>--%><%--</div>--%>
<telerik:RadScriptBlock ID="RadScriptBlock1" runat="server">

<script type="text/javascript" language="javascript">




    function AddAllocationEntry(projid)     //for adding allocation entries
    {

        var oWnd = window.radopen("passthrough_entry_add.aspx?PassthroughEntryID=0&ProjectID=" + projid, "AddEntry");
        return false;
    }

    function EditAllocationEntry(projid, id)     //for editing entries
    {

        var oWnd = window.radopen("passthrough_entry_edit.aspx?PassthroughEntryID=" + id + "&ProjectID=" + projid, "EditEntry");
        return false;
    }  
        
  
   
</script>
</telerik:RadScriptBlock>
</asp:Content>
