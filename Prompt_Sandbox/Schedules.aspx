<%@ Page Language="VB" MasterPageFile="~/content.master" Title="" %>
<%@ Register Assembly="Telerik.Web.UI" Namespace="Telerik.Web.UI" TagPrefix="telerik" %>
<%@ Import Namespace="Prompt" %>

<script runat="server">
    
    Private bReadOnly As Boolean = True
    Private nProjectID As Integer = 0
    Private nContactID As Integer
    Private nProjID As Integer
    Private nSchType As String
      
    'Protected Sub Page_PreRender(ByVal sender As Object, ByVal e As System.EventArgs)
    'Using db As New promptUserPrefs
    'db.SaveGridSettings(RadGrid1, "MeetingMinutesGridSettings", "ProjectID", nProjectID)
    'End Using
    'End Sub
    
    Private Sub Page_Load(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MyBase.Load

        ProcLib.CheckSession(Page)
        ProcLib.LoadPopupJscript(Page)
                                    
        'set up help button
        Session("PageID") = "Schedules"
        ' Dim masterViewTitle As Label = Master.FindControl("lblViewTitle")
        Dim masterTabs As RadTabStrip = Master.FindControl("tabMain")
        Dim masterViewTitle As Label = Master.FindControl("lblViewTitle")
        
        Using dbsec As New EISSecurity
            dbsec.ProjectID = nProjectID
            If dbsec.FindUserPermission("Schedules", "write") Then
                bReadOnly = False
            Else
                bReadOnly = True
            End If
        End Using
        
        Session("CurrentTab") = "Schedules"
        For Each radTab In masterTabs.GetAllTabs
            If radTab.Value = "Schedules" Then
                radTab.Selected = True
                radTab.SelectParents()
                Exit For
            End If
        Next
 
        Using db As New RFI
            nContactID = db.getContactID(Session("UserID"), Session("DistrictID"))
            Dim ContactData As Object = db.getContactData(nContactID, Session("DistrictID"))
            Session("ParentContactID") = ContactData(0)
            Session("ContactType") = Trim(ContactData(1))
        End Using
         
        If Session("RtnFromEdit") <> True Then
            Try
                nProjectID = Request.QueryString("ProjectID")
                Session("ProjectID") = nProjectID
                nSchType = ScheduleSelect.SelectedValue
            Catch
                nSchType = "Project"
            End Try
        ElseIf Session("RtnFromEdit") = True Then
            Session("RtnFromEdit") = Nothing
            nProjectID = Session("ProjectID")
        End If
        
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

            '.ExportSettings.FileName = "PromptMeetingMinutesExport"
            '.ExportSettings.OpenInNewWindow = True
            '.ExportSettings.Pdf.PageTitle = masterViewTitle.Text & " Meeting Minutes"
        End With
        
        BuildMenu()
               
        With contentPopup
            .VisibleOnPageLoad = False
            .Skin = "Windows7"
                         
            Dim ww As New RadWindow

            ww = New RadWindow
            With ww
                .ID = "EditWindow"
                .Title = " "
                .Width = 520
                .Height = 320
                .Modal = True
                .VisibleStatusbar = False
                .ReloadOnShow = True
                .Behaviors = WindowBehaviors.Close + WindowBehaviors.Move
            End With
            .Windows.Add(ww)
            
            'ww = New RadWindow
            'With ww
            '    .ID = "AttachmentsWindow"
            '    .NavigateUrl = "#"
            '    .Title = " "
            '    .Width = 500
            '    .Height = 350
            '    .Modal = True
            '    .VisibleStatusbar = False
            '    .ReloadOnShow = True
            '    .Behaviors = WindowBehaviors.Close + WindowBehaviors.Move
            'End With
            '.Windows.Add(ww)
        End With
       
        
        If Not IsPostBack Then
            buildProjectDropdown()
        End If
        
       
        
    End Sub
    
    Private Sub buildProjectDropdown()
        If Not IsPostBack Then
            'Dim tbl As DataTable
            'Using db As New MeetingMinute
            'tbl = db.getProjectList(nContactID)
            'With nProjectList
            '.DataValueField = "ProjectID"
            '.DataTextField = "ProjectName"
            '.DataSource = tbl
            '.DataBind()
            'End With
            'End Using
        End If
    End Sub
    
    Private Sub BuildMenu()
        
        If Not IsPostBack Then          'Configure Tool Bar
            
            With RadMenu1
                .EnableEmbeddedSkins = False
                .Skin = "Prompt"
                .Width = Unit.Percentage(100)
                '.EnableOverlay = False
                .OnClientItemClicking = "OnClientItemClicking"

                .CollapseAnimation.Duration = "200"
                .CollapseAnimation.Type = AnimationType.InOutBounce
                .ExpandAnimation.Duration = "200"
                .ExpandAnimation.Type = AnimationType.InOutBounce
                
            End With
            
            
        End If
        
        If Not IsPostBack Then
            
            'build buttons
           

            Dim butDropDown As New RadMenuItem
            With butDropDown
                .Text = "Export"
                .ImageUrl = "images/data_down.png"
                .PostBack = False
            End With
            
            'Add sub items
            Dim butSub As New RadMenuItem
            With butSub
                .Text = "Export To Excel"
                .Value = "ExportExcel"
                .Attributes("CancelAjax") = "Y"   'NOTE: This is needed to cancel ajax call and do regular postback as grid export to pdf/execl does not work with ajax
                .ImageUrl = "images/excel.gif"
                .PostBack = True
            End With
            'butDropDown.Items.Add(butSub)
            
            butSub = New RadMenuItem
            With butSub
                .Text = "Export To PDF"
                .Value = "ExportPDF"
                .Attributes("CancelAjax") = "Y"   'NOTE: This is needed to cancel ajax call and do regular postback as grid export to pdf/execl does not work with ajax
                .ImageUrl = "images/prompt_pdf.gif"
                .PostBack = True
            End With
            'butDropDown.Items.Add(butSub)
            'RadMenu1.Items.Add(butDropDown)
 
            butDropDown = New RadMenuItem
            With butDropDown
                .Text = "Print"
                .ImageUrl = "images/printer.png"
                .PostBack = False
            End With
                
            Dim but As RadMenuItem
            
            but = New RadMenuItem
            but.IsSeparator = True
            'RadMenu1.Items.Add(but)            
               
            Dim butAdd As RadMenuItem
            
            butAdd = New RadMenuItem
            With butAdd
                .Text = "Add New Schedule"
                .ImageUrl = "images/add.png"
                .Attributes("onclick") = "return EditSchedules(" & nProjectID & ",0,'New','Project');"
                '.ToolTip = "Add a New Meeting."
                .PostBack = False
                
            End With
            'If Session("ContactType") = "ProjectManager" Then
            'RadMenu1.Items.Add(butAdd)
            'End If
            If bReadOnly = False Then
                RadMenu1.Items.Add(butAdd)
            End If
            'If Session("UserRoll") = "TechSupport" Then
           
            'End If
              
            'Add grid configurator       
            Dim butConfig As New RadMenuItem
            With butConfig
                .Text = "Preferences"
                .ImageUrl = "images/gear.png"
                .PostBack = False
            End With
            RadMenu1.Items.Add(butConfig)
            
            'Add sub items
            Dim butConfigSub As New RadMenuItem
            With butConfigSub
                .Text = "Visible Columns"
                .ImageUrl = "images/column_preferences.png"
                .PostBack = False
            End With
            
            'Load the avaialble columns as checkbox items
            For Each col As GridColumn In RadGrid1.Columns
                If col.HeaderText <> "" Then
                    Dim butCol As New RadMenuItem
                    With butCol
                        .Text = col.HeaderText
                        .Value = "ColumnVisibility"
                        If col.Visible = True Then
                            .ImageUrl = "images/check2.png"
                            .Attributes("Visibility") = "On"
                        Else
                            .ImageUrl = ""
                            .Attributes("Visibility") = "Off"
                        End If
                        
                        .Attributes("ID") = col.UniqueName
                    End With
                    butConfigSub.Items.Add(butCol)
                End If
 
            Next
            butConfig.Items.Add(butConfigSub)
            
            'Add sub items
            butConfigSub = New RadMenuItem
            With butConfigSub
                .Text = "Restore Default Settings"
                .Value = "RestoreDefaultSettings"
                .ImageUrl = "images/gear_refresh.png"
            End With
            butConfig.Items.Add(butConfigSub)
        End If
        
        'RadGrid1.Rebind()
        'RadMenu1.Attributes("onclick") = "return EditMeeting(" & nProjectID & ",0,'New');"
        
    End Sub
  
    Private Sub ScheduleSelect_change() Handles ScheduleSelect.SelectedIndexChanged
        nSchType = ScheduleSelect.SelectedValue
        RadGrid1.Rebind()
    End Sub
        
    Protected Sub RadGrid1_NeedDataSource(ByVal source As Object, ByVal e As Telerik.Web.UI.GridNeedDataSourceEventArgs) Handles RadGrid1.NeedDataSource
        'loads the grid whenever it needs data (sorting, rebinding, etc...)
            
        'Using db As New ChangeOrders
        'rid1.DataSource = db.getProjectSchedules(nProjectID)
        'End Using
        
        Using db As New Schedules
            RadGrid1.DataSource = db.buildProjectScheduleGrid()
        End Using
        
    End Sub
    
    Protected Sub RadGrid1_DetailTableDataBind(ByVal source As Object, ByVal e As GridDetailTableDataBindEventArgs) Handles RadGrid1.DetailTableDataBind
        Dim parentItem As GridDataItem = CType(e.DetailTableView.ParentItem, GridDataItem)
        
        Dim ProjName As String = parentItem("ProjName").Text
        
        Using db As New Schedules
            e.DetailTableView.DataSource = db.getProjectSchedules(nProjectID, ProjName, Session("DistrictID"))
        End Using
        
    End Sub
    
    Protected Sub RadGrid1_ItemCreated(ByVal sender As Object, ByVal e As Telerik.Web.UI.GridItemEventArgs) Handles RadGrid1.ItemCreated
        'This event allows us to customize the cell contents - fired before databound               
        If (TypeOf e.Item Is GridDataItem) Then
            Dim item As GridDataItem = CType(e.Item, GridDataItem)
            Dim nScheduleID As Integer = item.OwnerTableView.DataKeyValues(item.ItemIndex)("ScheduleID")
            Dim sSchNumber As String = item.OwnerTableView.DataKeyValues(item.ItemIndex)("SchNumber")
            Dim fileName As String = item.OwnerTableView.DataKeyValues(item.ItemIndex)("ScheduleFileName")
            Dim LinkButton As HyperLink
            
            'If Session("ContactType") = "ProjectManager" Then
            Try
                LinkButton = CType(item("SchNumber").Controls(0), HyperLink)
                LinkButton.Text = sSchNumber
                LinkButton.Attributes("onclick") = "return EditSchedules(" & nProjectID & "," & nScheduleID & ",'Edit');"
                LinkButton.NavigateUrl = "#"
                LinkButton.ToolTip = "Edit this Schedule."
            Catch
            End Try
            'Else
            'item("SchNumber").Controls.Clear()
            'item("SchNumber").Text = sSchNumber
            'End If
                                                        
            If Not fileName = "None Selected" Then
                Dim sPath As String = ProcLib.GetCurrentRelativeAttachmentPath() & "DistrictID_" & Session("DistrictID") & "/_apprisedocs/"
                sPath &= "_Schedules/Sch_" & nProjectID & "/"
                Try
                    Dim linkButton2 As HyperLink = CType(item("ScheduleFileName").Controls(0), HyperLink)
                    linkButton2.ToolTip = "Show currently posted schedule."
                    linkButton2.NavigateUrl = sPath & fileName
                    linkButton2.Target = "_new"
                Catch ex As Exception
                End Try             
            Else            'remove the hyperlink and just display none
                item("ScheduleFileName").Controls.Clear()
                item("ScheduleFileName").Text = fileName
            End If
            
            
            
        End If
    End Sub
    
    Private Sub RadGrid1_ItemDataBound(ByVal sender As Object, ByVal e As Telerik.Web.UI.GridItemEventArgs) Handles RadGrid1.ItemDataBound
        
        'If TypeOf e.Item Is GridDataItem Then
        '    Dim dataitem As GridDataItem = e.Item

        '    Dim sMinutes As String = ProcLib.CheckNullDBField(dataitem.OwnerTableView.DataKeyValues(dataitem.ItemIndex)("MinutesFileName"))
        '    If Not sMinutes = "(None Attached)" Then
        '        Dim linkButton2 As HyperLink = CType(dataitem("Minutes").Controls(0), HyperLink)
        '        linkButton2.Text = "Click to download"
        '    End If

        'End If

    End Sub
    
    Protected Sub RadMenu1_ItemClick(ByVal sender As Object, ByVal e As Telerik.Web.UI.RadMenuEventArgs)
       
        Dim btn As RadMenuItem = e.Item
        
        Select Case btn.Value
            
            Case "ExportExcel"
                'RadGrid1.Columns.FindByUniqueName("Attachments").Visible = False
                RadGrid1.MasterTableView.ExportToExcel()
                
            Case "ExportPDF"
                'RadGrid1.Columns.FindByUniqueName("Attachments").Visible = False
                For Each item As GridItem In RadGrid1.MasterTableView.Items
                    If TypeOf item Is GridDataItem Then
                        Dim dataItem As GridDataItem = CType(item, GridDataItem)
                        Dim lnk As HyperLink = CType(dataItem("MeetingDate").Controls(0), HyperLink)
                        lnk.NavigateUrl = ""
                    End If
                Next
                RadGrid1.MasterTableView.ExportToPdf()
            
                    
            Case "ColumnVisibility"
                If btn.Attributes("Visibility") = "Off" Then
                    btn.ImageUrl = "images/check2.png"
                    btn.Attributes("Visibility") = "On"
                    RadGrid1.Columns.FindByUniqueName(btn.Attributes("ID")).Visible = True
                Else
                    btn.ImageUrl = ""
                    btn.Attributes("Visibility") = "Off"
                    RadGrid1.Columns.FindByUniqueName(btn.Attributes("ID")).Visible = False
                End If
                Using db As New promptUserPrefs
                    db.SaveGridColumnVisibility("MeetingMinutesGridColumns", btn.Attributes("ID"), btn.Attributes("Visibility"), "ProjectID", nProjectID)
                End Using
                RadGrid1.Rebind()
                
            Case "RestoreDefaultSettings"
                
                Using db As New promptUserPrefs
                    db.RemoveUserSavedSettings("MeetingMinutesGridSettings", "ProjectID", nProjectID)
                    db.RemoveUserSavedSettings("MeetingMinutesGridColumns", "ProjectID", nProjectID)
                End Using
                Response.Redirect(Page.Request.RawUrl)

        End Select
    End Sub
    
  
</script>

<asp:Content ID="Content1" ContentPlaceHolderID="mainBody" runat="Server">
<style type="text/css">  
    div.RadMenu {  
        float: right;  
    }  
</style> 

    <telerik:RadWindowManager ID="contentPopup" runat="server" />

    <telerik:radmenu id="RadMenu1" runat="server" onitemclick="RadMenu1_ItemClick" style="z-index: 10;top:5px;position:relative;width:100%" />

    <asp:HiddenField ID="ProjID" runat="server" />

    <telerik:RadComboBox ID="ScheduleSelect" runat="server" Width="400px" Height="100px" Style="z-index: 200;left:30px;
        position:relative;top:9px;" Skin="Vista"  TabIndex="7" AutoPostBack="true" Visible="false">
        <Items>
            <telerik:RadComboBoxItem runat="server" Text="Master Program Schedule" Value="MPS" />
            <telerik:RadComboBoxItem runat="server" Text="90 Day Look Ahead Schedule" Value="9DLAS" />    
            <telerik:RadComboBoxItem runat="server" Text="4 Week Look Ahead Schedule" Value="4DLAS" />    
            <telerik:RadComboBoxItem runat="server" Text="Project Activity Coordination Schedule" Value="PACS" />    
        </Items>
    </telerik:RadComboBox>
   
    <telerik:RadGrid ID="RadGrid1" runat="server" AllowSorting="True" AutoGenerateColumns="False" Style="Top:14px;position:relative"
    GridLines="None" Width="99%" EnableAJAX="True"  >
        <ClientSettings>
            <Selecting AllowRowSelect="False" />
            <Scrolling AllowScroll="False" UseStaticHeaders="True" />
        </ClientSettings>
        <MasterTableView Width="99%" GridLines="None" DataKeyNames="ProjectGroup,ProjName" 
                    NoMasterRecordsText="No Schedules Found.">
            <Columns>

                <telerik:GridBoundColumn UniqueName="ProjName" HeaderText="Project ID" DataField="ProjName" Visible="false">
                    <ItemStyle HorizontalAlign="Left" Width="110px"/>
                    <HeaderStyle HorizontalAlign="Left" Width="110px" />
                </telerik:GridBoundColumn>

               <telerik:GridHyperLinkColumn UniqueName="ProjectGroup" HeaderText="Project Group" DataTextField="ProjectGroup"
                    SortExpression="ScheduleName">
                    <ItemStyle HorizontalAlign="Left" Width="500px" VerticalAlign="top" CssClass="InnerItemStyle"   />
                    <HeaderStyle HorizontalAlign="Left" Width="500px" />
                 </telerik:GridHyperLinkColumn>

            </Columns>

            <DetailTables>

                 <telerik:GridTableView runat="server" Name="Schedules" DataKeyNames="ScheduleFileName,SchType,ScheduleID" TableLayout="Auto" >
                    <ParentTableRelation>
                      <telerik:GridRelationFields DetailKeyField="ProjectGroup" MasterKeyField="ProjName" />
                    </ParentTableRelation>
                <ItemStyle CssClass="rfi_unassigned" />

                <Columns>
                    <telerik:GridBoundColumn UniqueName="ScheduleID" HeaderText="Schedule ID" DataField="ScheduleID" Visible="false">
                <ItemStyle HorizontalAlign="Left" Width="110px"/>
                <HeaderStyle HorizontalAlign="Left" Width="110px" />
            </telerik:GridBoundColumn>
    
                    <telerik:GridHyperLinkColumn UniqueName="SchNumber" HeaderText="Schedule Number" DataTextField="SchNumber"
                        SortExpression="SchNumber">
                        <ItemStyle HorizontalAlign="Left" Width="100px" VerticalAlign="top" CssClass="InnerItemStyle"   />
                        <HeaderStyle HorizontalAlign="Left" Width="100px" />
                     </telerik:GridHyperLinkColumn>

                    <telerik:GridBoundColumn UniqueName="ScheduleName" HeaderText="Schedule Name" DataField="ScheduleName">
                        <ItemStyle HorizontalAlign="Left" Width="200px"/>
                        <HeaderStyle HorizontalAlign="Left" Width="200px" />
                    </telerik:GridBoundColumn>

                    <telerik:GridBoundColumn UniqueName="CreatedBy" HeaderText="Created By" DataField="Name" Visible="false">
                        <ItemStyle HorizontalAlign="Left" Width="130px"/>
                        <HeaderStyle HorizontalAlign="Left" Width="130px" />
                    </telerik:GridBoundColumn>      

                    <telerik:GridDateTimeColumn UniqueName="CreateDate" HeaderText="Effective Date" DataField="CreateDate" DataFormatString="{0:MM/dd/yy}" Visible="false">
                        <ItemStyle HorizontalAlign="Left" Width="130px"/>
                        <HeaderStyle HorizontalAlign="Left" Width="130px" />
                    </telerik:GridDateTimeColumn>      

                    <telerik:GridHyperLinkColumn UniqueName="ScheduleFileName" HeaderText="Schedule" DataTextField="ScheduleFileName">
                        <ItemStyle HorizontalAlign="Left" Width="200px" />
                        <HeaderStyle HorizontalAlign="Left" Width="200px" />
                    </telerik:GridHyperLinkColumn>

                     <telerik:GridBoundColumn UniqueName="Spacer" HeaderText="" DataField="ContractID" Visible="true">
                        <ItemStyle HorizontalAlign="Left" Width="330px"/>
                        <HeaderStyle HorizontalAlign="Left" Width="330px" />
                    </telerik:GridBoundColumn>      

                </Columns>

              </telerik:GridTableView>
             </DetailTables>


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
            <telerik:AjaxSetting AjaxControlID="RadMenu1">
                <UpdatedControls>
                    <telerik:AjaxUpdatedControl ControlID="RadGrid1" LoadingPanelID="RadAjaxLoadingPanel1" />
                    <telerik:AjaxUpdatedControl ControlID="RadMenu1" LoadingPanelID="RadAjaxLoadingPanel1" />
                </UpdatedControls>
            </telerik:AjaxSetting>
        </AjaxSettings>
    </telerik:radajaxmanager>
    <telerik:radajaxloadingpanel id="RadAjaxLoadingPanel1" runat="server" height="75px"
        width="75px" transparency="25">
        <img alt="Loading..." src="images/loading.gif" style="border: 0;" />
    </telerik:radajaxloadingpanel>
    
  <telerik:radtooltipmanager id="RadToolTipManager1" runat="server" sticky="True" title=""
        position="BottomCenter" skin="Office2007" hidedelay="500" manualclose="False"
        showevent="OnMouseOver" showdelay="100" animation="Fade" autoclosedelay="6000"
        AutoTooltipify="False" width="350" relativeto="Mouse" renderinpageroot="False">
    </telerik:radtooltipmanager>
<telerik:RadScriptBlock ID="RadScriptBlock1" runat="server">

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

    function EditSchedules(projectid, id, displaytype, level) {

        var oWnd = window.radopen("schedule_edit.aspx?ProjectID=" + projectid + "&ScheduleID=" + id + "&DisplayType=" + displaytype + "&SchType=" + level, "EditWindow");
        return false;
    }

 

</script>
</telerik:RadScriptBlock>
</asp:Content>
