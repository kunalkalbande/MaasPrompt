<%@ Page Language="VB" MasterPageFile="~/content.master" Title="" %>

<%@ Register Assembly="Telerik.Web.UI" Namespace="Telerik.Web.UI" TagPrefix="telerik" %>
<%@ Import Namespace="Prompt" %>

<script runat="server">
    
    Private bReadOnly As Boolean = True
    Private CurrentView As String = ""
    Private sKeyField As String = ""
    Private nProjectID As Integer = 0
    Private nCollegeID As Integer = 0
    Private nContractID As Integer = 0
    Private nLedgerAccountID As Integer = 0
    Private RecID As Integer = 0
    
    
    Private Sub Page_Load(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MyBase.Load

        ProcLib.CheckSession(Page)
        ProcLib.LoadPopupJscript(Page)

        ''set up help button
        Session("PageID") = "Notes"
        CurrentView = Request.QueryString("view")
        nProjectID = Request.QueryString("ProjectID")
        nCollegeID = Request.QueryString("CollegeID")
        nContractID = Request.QueryString("ContractID")
        nLedgerAccountID = Request.QueryString("LedgerAccountID")
       
        
        Dim masterTabs As RadTabStrip = Master.FindControl("tabMain")
        Session("CurrentTab") = "Notes"
        For Each radTab In masterTabs.GetAllTabs
            If radTab.Value = "Notes" Then
                radTab.Selected = True
                radTab.SelectParents()
                Exit For
            End If
        Next
        
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

            'If Request.Browser.Browser = "IE" Or Request.Browser.Browser = "AppleMAC-Safari" Then
            .Height = Unit.Pixel(500)
            'Else
            '.Height = Unit.Percentage(80)
            'End If
            
            .ExportSettings.FileName = "PromptProjectNotesExport"
            .ExportSettings.OpenInNewWindow = True
            .ExportSettings.Pdf.PageTitle = "Project Notes List"
  
        End With
        
        'Configure the Popup Window(s)
        With contentPopups
            .VisibleOnPageLoad = False
            .Skin = "Windows7"
            Dim ww As New Telerik.Web.UI.RadWindow
            ww = New Telerik.Web.UI.RadWindow
            With ww
                .ID = "EditNoteWindow"
                .NavigateUrl = ""
                .Title = ""
                .Width = 500
                .Height = 475
                .Modal = True
                .VisibleStatusbar = False
                .ReloadOnShow = True
            End With
            .Windows.Add(ww)
            
              
        End With
  
        Dim bAllowEdit As Boolean = False

        Using db As New EISSecurity
            db.CollegeID = Session("CollegeID")
            db.ProjectID = nProjectID
        
            Select Case CurrentView
                Case "college"
                    RecID = nCollegeID
                    sKeyField = "CollegeID"
                    bAllowEdit = db.FindUserPermission("CollegeNotesTab", "Write")
                    
                Case "project"
                    RecID = nProjectID
                    sKeyField = "ProjectID"
                    bAllowEdit = db.FindUserPermission("ProjectNotesTab", "Write")
                
                Case "ledgeraccount"
                    RecID = nLedgerAccountID
                    sKeyField = "LedgerAccountID"
                    bAllowEdit = db.FindUserPermission("LedgerNotes", "Write")
  

                Case "contract"
                    RecID = nContractID
                    sKeyField = "ContractID"
                    bAllowEdit = db.FindUserPermission("ContractNotesTab", "Write")
  

            End Select
            
        End Using
        
        If bAllowEdit Then
            With lnkAddNew
                .Visible = True
                .Attributes("onclick") = "return EditNote(0,'" & CurrentView & "'," & RecID & ");"
            End With
        Else
            lnkAddNew.Visible = False
        End If
  
    End Sub
  
    
    Protected Sub RadGrid1_NeedDataSource(ByVal source As Object, ByVal e As Telerik.Web.UI.GridNeedDataSourceEventArgs) Handles RadGrid1.NeedDataSource
        'loads the grid whenever it needs data (sorting, rebinding, etc...)
        Using db As New promptNote
            RadGrid1.DataSource = db.GetNotes(sKeyField, RecID)
        End Using

    End Sub

    Protected Sub RadGrid1_ItemCreated(ByVal sender As Object, ByVal e As Telerik.Web.UI.GridItemEventArgs) Handles RadGrid1.ItemCreated

        'This event allows us to customize the cell contents - fired before databound

        If (TypeOf e.Item Is GridDataItem) Then
            Dim item As GridDataItem = CType(e.Item, GridDataItem)
            Dim nNoteID As Integer = item.OwnerTableView.DataKeyValues(item.ItemIndex)("NoteID")

            'update the link button to open report window
            Dim linkButton As HyperLink = CType(item("CreatedOn").Controls(0), HyperLink)
            linkButton.Attributes("onclick") = "return EditNote(" & nNoteID & ",'" & CurrentView & "'," & RecID & ");"
            linkButton.ToolTip = "Edit selected Note."
            linkButton.NavigateUrl = "#"
            
        End If
    End Sub

</script>

<asp:Content ID="Content1" ContentPlaceHolderID="mainBody" runat="Server">
    <telerik:radwindowmanager id="contentPopups" runat="server">
    </telerik:radwindowmanager>
    <div id="contentwrapper">
        <div id="navrow">
            <asp:HyperLink ID="lnkAddNew" CssClass="addnew" runat="server">Add Note</asp:HyperLink>
        </div>
        <div id="contentcolumn">
            <div class="innertube">
                <span class="hdprint">
                    <asp:Label ID="lblProjectName" runat="server"></asp:Label></span>
                <telerik:radgrid id="RadGrid1" runat="server" allowsorting="true" autogeneratecolumns="False"
                    gridlines="None" width="100%" enableajax="True" height="360px" skin="Windows7">
                                    <ClientSettings>
                                        <Selecting AllowRowSelect="False" />
                                        <Scrolling AllowScroll="True" UseStaticHeaders="True" ScrollHeight="50%" />
                                    </ClientSettings>
                                    <MasterTableView Width="100%" GridLines="None" DataKeyNames="NoteID" NoMasterRecordsText="No Notes found.">
                                        <Columns>
                                            <telerik:GridHyperLinkColumn UniqueName="CreatedOn" HeaderText="On" NavigateUrl="#"
                                                SortExpression="CreatedOn" DataTextField="CreatedOn" DataTextFormatString="{0:MM/dd/yy}">
                                                <ItemStyle HorizontalAlign="Left" VerticalAlign="Top" Width="20%" />
                                                <HeaderStyle HorizontalAlign="Left" Width="20%" />
                                            </telerik:GridHyperLinkColumn>
                                            <telerik:GridBoundColumn UniqueName="Description" HeaderText="Description" DataField="Description">
                                                <ItemStyle HorizontalAlign="Left" VerticalAlign="Top" />
                                                <HeaderStyle HorizontalAlign="Left" />
                                            </telerik:GridBoundColumn>
                                            <telerik:GridBoundColumn UniqueName="CreatedBy" HeaderText="By" DataField="CreatedBy">
                                                <ItemStyle HorizontalAlign="Left" Width="20%" VerticalAlign="Top" />
                                                <HeaderStyle Width="20%" HorizontalAlign="Left" />
                                            </telerik:GridBoundColumn>
                                        </Columns>
                                    </MasterTableView>
                                </telerik:radgrid>
            </div>
        </div>
        <telerik:radajaxmanager id="RadAjaxManager1" runat="server">
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
                    <img alt="Loading..." src='<%= RadAjaxLoadingPanel.GetWebResourceUrl(Page, "Telerik.Web.UI.Skins.Default.Ajax.loading.gif") %>'
                        style="border: 0;" />
                </telerik:radajaxloadingpanel>
        <telerik:radcodeblock id="RadCodeBlock1" runat="server">

                    <script type="text/javascript" language="javascript">


                        function EditNote(id, view, parentkey) {

                            var oWnd = window.radopen("note_edit.aspx?NoteID=" + id + "&CurrentView=" + view + "&KeyValue=" + parentkey + "&WinType=RAD", "EditNoteWindow");
                            return false;
                        }

                        function GetRadWindow() {
                            var oWindow = null;
                            if (window.RadWindow) oWindow = window.RadWindow;
                            else if (window.frameElement.radWindow) oWindow = window.frameElement.radWindow;
                            return oWindow;
                        }

                    </script>

                </telerik:radcodeblock>
</asp:Content>
