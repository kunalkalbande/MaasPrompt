<%@ Page Language="VB" MasterPageFile="~/content.master" Title="" %>
<%@ Register Assembly="Telerik.Web.UI" Namespace="Telerik.Web.UI" TagPrefix="telerik" %>
<%@ Import Namespace="Prompt" %>

<script runat="server">
    
    Private bReadOnly As Boolean = True
    Private nProjectID As Integer = 0
    Private nContactID As Integer
    Private nProjID As Integer
    Private nContractID As Integer = 0
    Private isPMtheCM As Boolean
    Private CMContactID As Integer
    Private PMContactID As Integer
    
    Protected Sub Page_PreRender(ByVal sender As Object, ByVal e As System.EventArgs)
        Using db As New promptUserPrefs
            db.SaveGridSettings(RadGrid1, "ChangeOrdersGridSettings", "ProjectID", nProjectID)
        End Using
    End Sub
    
    Protected Sub Page_Init(ByVal sender As Object, ByVal e As System.EventArgs)
        nProjectID = Request.QueryString("ProjectID")
              
        'set security
        Using dbsec As New EISSecurity
            'dbsec.ProjectID = nProjectID
            'If dbsec.FindUserPermission("MeetingMinutes", "write") Then
            'bReadOnly = False
            'Else
            'bReadOnly = True
            'End If
        End Using
        If Not IsPostBack Then
            Using db As New promptUserPrefs
                db.LoadGridSettings(RadGrid1, "ChangeOrderGridSettings", "ProjectID", nProjectID)
                db.LoadGridColumnVisibility(RadGrid1, "ChangeOrderGridColumns", "ProjectID", nProjectID)
            End Using
            'Session("CoType")=""
        End If
    End Sub
    
    Private Sub Page_Load(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MyBase.Load

        ProcLib.CheckSession(Page)
        ProcLib.LoadPopupJscript(Page)
                     
        'set up help button
        Session("PageID") = "ProjectChangeOrders"
        
        If Not IsPostBack Then
            If Session("COType") = "" Then
                Session("COType") = "PCO"
            End If
        Else
            TypeSelect_change()
        End If
           
        Using db As New RFI
            Dim thObj As Object = db.getCM(Request.QueryString("ProjectID"), Request.QueryString("ContractID"))
            Session("CMID") = thObj(0)
            Session("ContractorID") = thObj(1)
            If Session("CMID") = 0 Then isPMtheCM = True Else isPMtheCM = False ' gives pm cm privilages if no cm specified
            
            Dim emailIDs As Object = db.getPMAndCMid(Request.QueryString("ProjectID"))
            CMContactID = emailIDs(0)
            PMContactID = emailIDs(1)
            
            'testPlace.Value = isPMtheCM & " - " & Session("CMID")
        End Using
        
        Dim masterTabs As RadTabStrip = Master.FindControl("tabMain")
        Dim masterViewTitle As Label = Master.FindControl("lblViewTitle")
        
        Session("CurrentTab") = "ChangeOrderLog"
        For Each radTab In masterTabs.GetAllTabs
            If radTab.Value = "ChangeOrderLog" Then
                radTab.Selected = True
                radTab.SelectParents()
                Exit For
            End If
        Next
        
        If Session("RtnFromEdit") <> True Then
            Session("ContractID") = Nothing
        Else
            cboTypeSelect.SelectedValue = Session("COType") & "s"
            TypeSelect_change()
            'RadGrid1.MasterTableView.DetailTables(0).GetColumn("CONumber").HeaderText = Session("COType") & " #"
            If Session("COType") = "PCO" Then
                'RadGrid1.MasterTableView.DetailTables(0).GetColumn("RequiredBy").Visible = True
                'RadGrid1.MasterTableView.DetailTables(0).GetColumn("DaysInProcess").Visible = False
                'colorLegend.Visible = True
            ElseIf Session("COType") = "COR" Then
                'RadGrid1.MasterTableView.DetailTables(0).GetColumn("RequiredBy").Visible = False
                'RadGrid1.MasterTableView.DetailTables(0).GetColumn("DaysInProcess").Visible = True
                'colorLegend.Visible = False
            End If
            'RadGrid1.Rebind()
            Session("RtnFromEdit") = Nothing
            nContractID = Session("ContractID")
        End If
        Using db As New RFI
            nContactID = db.getContactID(Session("UserID"), Session("DistrictID"))
            contactID.Value = nContactID
        End Using
        
        Try
            Using db As New RFI
                'Dim contactData As Object = db.getContactData(nContactID, Session("DistrictID"))
                'parentID = contactData(0)
                'Session("ParentContactID") = parentID
                'contactType = contactData(1)
                'Session("ContactType") = contactData(1)
                'companyName = contactData(2)
                'Dim Obj As Object = db.getTeamContactData(Session("DistrictID"), nContactID, nProjectID)
                Dim Obj As Object = db.getContactData(nContactID, Session("DistrictID"))
                Session("ContactType") = Obj(1)
                If Session("ContactType") = "Project Manager" Then Session("ContactType") = "ProjectManger"
            End Using
        Catch ex As Exception
        End Try
        
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
        
        If Not IsPostBack Then
            BuildMenu()
        End If
        
        With contentPopup
            .VisibleOnPageLoad = False
            .Skin = "Windows7"
                         
            Dim ww As New RadWindow

            ww = New RadWindow
            With ww
                .ID = "EditWindow"
                .Title = " "
                .Width = 800
                .Height = 550
                .Modal = True
                .VisibleStatusbar = False
                .ReloadOnShow = True
                .Behaviors = WindowBehaviors.Close + WindowBehaviors.Move
                .OnClientClose = "onThisClientClose"
            End With
            .Windows.Add(ww)
            
        End With
       
        
        If Not IsPostBack Then
            buildProjectDropdown()
        End If
        If IsPostBack Then
            'RadGrid1.MasterTableView.DetailTables(0).GetColumn("CONumber").HeaderText = Session("CoType") & " Number"
            'RadGrid1.Rebind()
        End If
        'nProjectID = nProjectList.SelectedValue
        If Not IsPostBack Then
            RadGrid1.MasterTableView.DetailTables(0).GetColumn("RequiredBy").Visible = True
            RadGrid1.MasterTableView.DetailTables(0).GetColumn("DaysInProcess").Visible = False
            RadGrid1.MasterTableView.DetailTables(0).GetColumn("CONumber").HeaderText = "PCO #"
        End If
    End Sub
    
    Private Sub buildProjectDropdown()
       
    End Sub
    
    Private Sub BuildMenu()
        
        If Not IsPostBack Then          'Configure Tool Bar

            With RadMenu1
                .EnableEmbeddedSkins = False
                .Skin = "Prompt"
                .Width = Unit.Percentage(100)
                .EnableOverlay = False
                .OnClientItemClicking = "OnClientItemClicking"

                .CollapseAnimation.Duration = "200"
                .CollapseAnimation.Type = AnimationType.InOutBounce
                .ExpandAnimation.Duration = "200"
                .ExpandAnimation.Type = AnimationType.InOutBounce
            End With
        End If

        'If Not IsPostBack Then
            
        build_RadMenu1("PCO Log Report", 3243)

        'build buttons
        Dim but As RadMenuItem
                                   
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
                          
        but = New RadMenuItem
        but.IsSeparator = True
        RadMenu1.Items.Add(but)
        
        'End If
        
 
        RadGrid1.Rebind()
        'RadMenu1.Attributes("onclick") = "return EditMeeting(" & nProjectID & ",0,'New');"
        
    End Sub
  
    Private Sub build_RadMenu1(zText As String, ReportID As Integer)
        'RadMenu1.Dispose() 'David D 6/14/17 this was causing the Preferences to be disabled on click and 
        RadMenu1.Items.Clear()
        If IsPostBack Then
            If cboTypeSelect.SelectedValue = "PCOs" Then
                zText = "PCO Log Report"
                ReportID = 3243
            ElseIf cboTypeSelect.SelectedValue = "CORs" Then
                zText = "COR Log Report"
                ReportID = 4245
            End If
        End If
        
        testPlace.Value = zText
        
        Dim but As RadMenuItem
        
        but = New RadMenuItem
        With but
            .Text = zText
            .NavigateUrl = "report_viewer.aspx?ReportID=" & ReportID & "&ProjectID=" & nProjectID
            .ImageUrl = "images/printer.png"
            .PostBack = False
            .Visible = True
            .Target = "#"
            .Value = "COPrint"
        End With
        'If ReportID = 42432 Then
        RadMenu1.Items.Add(but)
        but = New RadMenuItem
        but.IsSeparator = True
        RadMenu1.Items.Add(but)
        'End If
        
        but = New RadMenuItem
        With but
            .Text = "Add New PCO"
            .ImageUrl = "images/add.png"
            .Attributes("onclick") = "return EditChangeOrder(" & nProjectID & ",0,'New','PCO');"
            .ToolTip = "Add a New Meeting."
            .PostBack = False
                
            'If bReadOnly Then
            '.Visible = False
            'Else
            .Visible = True
            'End If
        End With
        If Session("ContactType") <> "District" Then
            RadMenu1.Items.Add(but)
            but = New RadMenuItem
            but.IsSeparator = True
            'RadMenu1.Items.Add(but)
        End If
        
            
        but = New RadMenuItem
        With but
            .Text = "Add New COR"
            .ImageUrl = "images/add.png"
            .Attributes("onclick") = "return EditChangeOrder(" & nProjectID & ",0,'New','COR');"
            .ToolTip = "Add a New Change Order Request."
            .PostBack = False
            .Visible = True
        End With
        If Session("ContactType") <> "District" Then
            RadMenu1.Items.Add(but)
            but = New RadMenuItem
            but.IsSeparator = True
            RadMenu1.Items.Add(but)
        End If
                      
        but = New RadMenuItem
        With but
            .Text = "Add New CO"
            .ImageUrl = "images/add.png"
            .Attributes("onclick") = "return EditChangeOrder(" & nProjectID & ",0,'New','CO');"
            .ToolTip = "Add a New Change Order."
            .PostBack = False
            .Visible = False
        End With
        If Session("ContactType") <> "District" Then
            RadMenu1.Items.Add(but)
            but = New RadMenuItem
            but.IsSeparator = True
            'RadMenu1.Items.Add(but)
        End If
       
        'End If
                                                   
    End Sub
    
    Private Sub TypeSelect_change() Handles cboTypeSelect.SelectedIndexChanged
        Dim HeadName As String = "PCOs"
        Dim addName As String = "Add New Change Order"
        Dim reportID As Integer = 3243
        Dim reportType As String = "PCO Log Report"
       
        Select Case cboTypeSelect.SelectedValue
            Case "PCOs"
                HeadName = "PCO #"
                Session("COType") = "PCO"
                addName = "Add New Potential Change Order"
                reportID = 3243
                reportType = "PCO Log Report"
                RadGrid1.MasterTableView.DetailTables(0).GetColumn("RequiredBy").Visible = True
                RadGrid1.MasterTableView.DetailTables(0).GetColumn("DaysInProcess").Visible = False
                colorLegend.Visible = True
                legendpad.Visible = False
            Case "CORs"
                HeadName = "COR #"
                Session("COType") = "COR"
                addName = "Add New Change Order Request"
                reportID = 4245
                reportType = "COR Log Report"
                RadGrid1.MasterTableView.DetailTables(0).GetColumn("RequiredBy").Visible = False
                RadGrid1.MasterTableView.DetailTables(0).GetColumn("DaysInProcess").Visible = True
                colorLegend.Visible = False
                legendpad.Visible=true
        End Select
        
        'build_RadMenu1(reportType, reportID) 'David D 6/14/17 removed and added BuildMenu() below to keep full list on toggle
        BuildMenu()
        
        RadGrid1.MasterTableView.DetailTables(0).GetColumn("CONumber").HeaderText = HeadName
        RadGrid1.Rebind()
        
    End Sub
    
    Protected Sub RadGrid1_NeedDataSource(ByVal source As Object, ByVal e As Telerik.Web.UI.GridNeedDataSourceEventArgs) Handles RadGrid1.NeedDataSource
        Using db As New RFI
            RadGrid1.DataSource = db.getAllProjectContracts(nProjectID, False, Session("ContactType"), "PMChangeOrders")
        End Using
        
    End Sub

    Protected Sub RadGrid1_DetailTableDataBind(ByVal source As Object, ByVal e As GridDetailTableDataBindEventArgs) Handles RadGrid1.DetailTableDataBind
        Dim parentItem As GridDataItem = CType(e.DetailTableView.ParentItem, GridDataItem)
        
        Dim rfiSelect As String = Session("rfiSelect") 'cboShowStatus.SelectedValue
        
        Using db As New ChangeOrders
            e.DetailTableView.DataSource = db.getProjectChangeOrders(Session("DistrictID"), nProjectID, Session("ContactType"), nContactID, Session("COType"))
        End Using
       
    End Sub
    
    Protected Sub RadGrid1_ItemCreated(ByVal sender As Object, ByVal e As Telerik.Web.UI.GridItemEventArgs) Handles RadGrid1.ItemCreated
        'This event allows us to customize the cell contents - fired before databound
        
        If nContractID <> 0 Then
            For Each dataitem As GridDataItem In RadGrid1.MasterTableView.Items
                If dataitem("ContractID").Text = nContractID Then
                    dataitem.Expanded = True
                End If
            Next
        End If       
        
        If (TypeOf e.Item Is GridDataItem) Then
            Dim item As GridDataItem = CType(e.Item, GridDataItem)
            Dim nCOID As Integer = item.OwnerTableView.DataKeyValues(item.ItemIndex)("COID")
            'Dim sMinutes As String = ProcLib.CheckNullDBField(item.OwnerTableView.DataKeyValues(item.ItemIndex)("MinutesFileName"))
            'Dim sMeetingDate As String = ProcLib.CheckNullDBField(item.OwnerTableView.DataKeyValues(item.ItemIndex)("MeetingDate"))
            
            'update the link button to open report window
            Dim linkButton As HyperLink
           
            Try
                linkButton = CType(item("CONumber").Controls(0), HyperLink)
                linkButton.Attributes("onclick") = "return EditChangeOrder(" & nProjectID & "," & nCOID & ",'Existing');"
                linkButton.CssClass = ""
            Catch ex As Exception
            End Try
        End If
    End Sub
    
    Private Sub RadGrid1_ItemDataBound(ByVal sender As Object, ByVal e As Telerik.Web.UI.GridItemEventArgs) Handles RadGrid1.ItemDataBound
        If (TypeOf e.Item Is GridDataItem) Then
            Dim dataItem As GridDataItem = CType(e.Item, GridDataItem)
            Dim dRequiredBy As String = ProcLib.CheckNullDBField(dataItem.OwnerTableView.DataKeyValues(dataItem.ItemIndex)("RequiredBy"))
            Dim sStatus As String = ProcLib.CheckNullDBField(dataItem.OwnerTableView.DataKeyValues(dataItem.ItemIndex)("Status"))
            Dim wfPosition As String = ProcLib.CheckNullDBField(dataItem.OwnerTableView.DataKeyValues(dataItem.ItemIndex)("WorkFlowPosition"))
            Dim sNewWorkflow As String = ProcLib.CheckNullDBField(dataItem.OwnerTableView.DataKeyValues(dataItem.ItemIndex)("NewWorkflow"))
            Dim dDate As Date
            
            dataItem.CssClass = "rfi_unassigned"
            
            If sStatus = "Active" Or sStatus = "Approved-COPending" Then
                dataItem.Item("RequiredBy").CssClass = "rfi_pending"
                
                If Session("COType") = "PCO" Then
                    If dRequiredBy <> "" Then
                        dDate = DateTime.Parse(dRequiredBy)
                    End If
                    'dDate = Date.ParseExact(dRequiredBy, "dd/MM/yyy", System.Globalization.DateTimeFormatInfo.InvariantInfo)
                    If dRequiredBy <> "" Then
                        dDate = DateTime.Parse(dRequiredBy)
                    End If
                               
                    If IsDate(dDate) Then
                        If dDate = DateAdd(DateInterval.Day, 1, Date.Today) Or dDate = DateAdd(DateInterval.Day, 2, Date.Today) Then
                            dataItem.Item("RequiredBy").CssClass = "rfi_warning"
                        ElseIf CDate(dDate) < CDate(Now()) Then
                            dataItem.Item("RequiredBy").CssClass = "rfi_overdue"
                        End If
                    End If
                End If
                
            ElseIf sStatus = "Closed" Then
                dataItem.Item("RequiredBy").CssClass = "rfi_answered"
                dataItem.Font.Bold = False
            End If
            
            If wfPosition = "None" Then
                dataItem.Item("RequiredBy").CssClass = "rfi_preparing"
                dataItem.Font.Bold = False
            End If
            
            Select Case Trim(wfPosition)
                Case "PM:Review Pending", "PM:BOD Approval Pending", "PM:Approval Pending", "PM:Completion Pending"
                    If Session("ContactType") = "ProjectManager" And Trim(sNewWorkflow) = "True" Then
                        dataItem.CssClass = "NewWorkflow"
                    End If
                Case "CM:Distribution Pending", "CM:Acceptance Pending", "CM:Review Pending", "CM:Completion Pending"
                    'David D 6/9/17 updated below condition for isPMtheCM
                    If isPMtheCM = True And Session("ContactType") = "ProjectManager" And Trim(sNewWorkflow) = "True" Then
                        If Session("ContactType") <> "District" Then
                            dataItem.CssClass = "NewWorkflow"
                        End If
                    End If
            End Select
            
        End If
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
                    db.RemoveUserSavedSettings("ChangeOrdersGridSettings", "ProjectID", nProjectID)
                    db.RemoveUserSavedSettings("ChangeOrdersGridColumns", "ProjectID", nProjectID)
                End Using
                Response.Redirect(Page.Request.RawUrl)

        End Select
    End Sub
    
  
</script>

<asp:Content ID="Content1" ContentPlaceHolderID="mainBody" runat="Server">
    <telerik:RadWindowManager ID="contentPopup" runat="server" />

    <asp:HiddenField ID="ProjID" runat="server" />

    <asp:HiddenField ID="openCOID" runat="server" /> 

    <asp:HiddenField ID="contactID" runat="server" />
     
    <asp:HiddenField ID="pageType" value="CO" runat="server" />

    <asp:HiddenField ID="testPlace" value="" runat="server" />
   
    <asp:Label ID="lblModule" runat="server" Text="" style="z-index:600;left:800px;top:10px;position:absolute"></asp:Label> 

    <telerik:RadComboBox ID="cboTypeSelect" runat="server" Width="170px" Height="50px" Style="z-index: 200;left:30px;
        position:relative;top:9px;" Skin="Vista"  TabIndex="7" AutoPostBack="true" Visible="true">
         <Items>
            <telerik:RadComboBoxItem runat="server" Text="Potential Change Orders" Value="PCOs" />
            <telerik:RadComboBoxItem runat="server" Text="Change Order Requests" Value="CORs" />           
        </Items>
    </telerik:RadComboBox>
     <!--<telerik:RadComboBoxItem runat="server" Text="Change Orders" Value="COs" />-->

    <asp:Panel id="legendpad" runat="server" style="position:relative;top:15px;height:20px">
    </asp:Panel>

     <asp:Panel id="colorLegend" runat="server" >    
        <div style="height:20px;border-style:solid;border-width:0px;width:1050px;position:relative;top:15px;z-index:100">
            <div style="position:relative;width:100px;display:inline-block;height:16px;
                line-height:16px;vertical-align:top;text-align:right;font-size:10px;font-weight:bold">Status Indicator:&nbsp;&nbsp;</div>
            <div class="rfi_preparing" style="width:150px;height:16px;position:relative;display:inline-block;text-align:center;font-size:10px">Preparing</div>
            <div style="position:absolute;display:inline-block;width:5px"></div>
            <div class="rfi_unassigned" style="width: 150px; height: 16px; position: relative;
            display: inline-block; text-align: center; font-size: 10px">
            RFI Unassigned to DP</div>
        <div style="position: absolute; display: inline-block; width: 5px">
        </div>
            <!--<div class="rfi_unassigned" style="width:150px;height:16px;position:relative;display:inline-block;text-align:center;font-size:10px">Unassigned to DP</div>-->
            <div style="position:absolute;display:inline-block;width:5px"></div>
            <div class="rfi_pending" style="width:150px;height:16px;position:relative;display:inline-block;text-align:center;font-size:10px">Active</div>
            <div style="position:absolute;display:inline-block;width:5px"></div>

            <div class="rfi_warning" style="width:150px;height:16px;position:relative;display:inline-block;text-align:center;font-size:10px">Near Overdue (< 3 Days)</div>
            <div style="position:absolute;display:inline-block;width:5px"></div>

            <div class="rfi_overdue" style="width:150px;height:16px;position:relative;display:inline-block;text-align:center;font-size:10px">Overdue</div>
            <div style="position:absolute;display:inline-block;width:5px"></div>
            <div class="rfi_answered" style="width:150px;height:16px;display:inline-block;text-align:center;font-size:10px">Complete/Closed</div>
        </div>
    </asp:Panel>

       <telerik:radmenu id="RadMenu1" runat="server" onitemclick="RadMenu1_ItemClick" style="z-index: 10;top:-38px;width:470px;position:relative;right:0px;height:25px" />
       <!--<div style="position:absolute;top:135px;right:0px;width:1px;height:20px;border-style:solid;border-width:1px"></div>-->

    <telerik:RadGrid ID="RadGrid1" runat="server" AllowSorting="true" AutoGenerateColumns="False" Style="margin-top:-10px; float:left; clear:both"
        GridLines="None" Width="99%" EnableEmbeddedSkins="false" enableajax="True">
        <ClientSettings>
            <Selecting AllowRowSelect="False" />
            <Scrolling AllowScroll="True" UseStaticHeaders="True" ScrollHeight="50%" />
        </ClientSettings>

        <MasterTableView Width="99%" GridLines="None" DataKeyNames="ContractID,BidPackNumber"
            NoMasterRecordsText="No Change Orders found.">
            <Columns>

                <telerik:GridBoundColumn UniqueName="ContractID" HeaderText="Contract ID" DataField="ContractID">
                    <ItemStyle HorizontalAlign="Left" Width="70px" VerticalAlign="Top" />
                    <HeaderStyle HorizontalAlign="Left" Width="70px" />
                </telerik:GridBoundColumn>

                <telerik:GridBoundColumn UniqueName="BidPackNumber" HeaderText="Bid Pack Number" DataField="BidPackNumber">
                    <ItemStyle HorizontalAlign="Left" Width="120px" VerticalAlign="Top" />
                    <HeaderStyle HorizontalAlign="Left" Width="120px"  />
                </telerik:GridBoundColumn>

                 <telerik:GridBoundColumn UniqueName="Description" HeaderText="Description" DataField="Description">
                    <ItemStyle HorizontalAlign="Left" Width="250px" VerticalAlign="Top" />
                    <HeaderStyle HorizontalAlign="Left" Width="250px"   />
                </telerik:GridBoundColumn>

                <telerik:GridBoundColumn UniqueName="Contractor" HeaderText="Contractor" DataField="Contractor">
                    <ItemStyle HorizontalAlign="Left" Width="200px" VerticalAlign="Top" />
                    <HeaderStyle HorizontalAlign="Left" Width="200px" />
                </telerik:GridBoundColumn>
 
                 <telerik:GridBoundColumn UniqueName="Contact" HeaderText="Contact" DataField="Contact">
                    <ItemStyle HorizontalAlign="Left" Width="150px" VerticalAlign="Top" />
                    <HeaderStyle HorizontalAlign="Left" Width="150px" />
                </telerik:GridBoundColumn>

                 <telerik:GridBoundColumn UniqueName="Phone1" HeaderText="Phone Number" DataField="Phone1">
                    <ItemStyle HorizontalAlign="Left" Width="80px" VerticalAlign="Top" />
                    <HeaderStyle HorizontalAlign="Left" Width="80px"  />
                </telerik:GridBoundColumn>  
        </Columns>

        <DetailTables>
             <telerik:GridTableView runat="server" Name="RFIs" DataKeyNames="CONumber,RFIReference,FullName,CreateDate,RequiredBy,Subject,COID,Status,WorkFlowPosition,NewWorkflow" TableLayout="Auto" >
                <ParentTableRelation>
                  <telerik:GridRelationFields DetailKeyField="ContractID" MasterKeyField="ContractID" />
                </ParentTableRelation>
            <ItemStyle CssClass="rfi_unassigned" />

            <Columns>

            <telerik:GridHyperLinkColumn UniqueName="CONumber" HeaderText="PCO #" DataTextField="sCONumber"  SortExpression="CONumber" >
                <ItemStyle HorizontalAlign="Left" Width="50px"/>
                <HeaderStyle HorizontalAlign="Left" Width="50px" />
            </telerik:GridHyperLinkColumn>

            <telerik:GridBoundColumn UniqueName="Revision" HeaderText="Revision" DataField="zRevision" Visible="True">
                <ItemStyle HorizontalAlign="Left" Width="90px"/>
                <HeaderStyle HorizontalAlign="Left" Width="90px" />
            </telerik:GridBoundColumn>

            <telerik:GridBoundColumn UniqueName="WorkFlowPosition" HeaderText="Work Flow Position" DataField="WorkFlowPosition">
                <ItemStyle HorizontalAlign="Left" Width="175px"/>
                <HeaderStyle HorizontalAlign="Left" Width="175px" />
            </telerik:GridBoundColumn>

            <telerik:GridBoundColumn UniqueName="RFIReference" HeaderText="RFI Reference" DataField="RefNumber" Visible="false">
                <ItemStyle HorizontalAlign="Left" Width="110px"/>
                <HeaderStyle HorizontalAlign="Left" Width="110px" />
            </telerik:GridBoundColumn>            

            <telerik:GridBoundColumn UniqueName="Status" HeaderText="Status" DataField="Status" Visible="false">
                <ItemStyle HorizontalAlign="Left" Width="90px"/>
                <HeaderStyle HorizontalAlign="Left" Width="90px" />
            </telerik:GridBoundColumn>

            <telerik:GridBoundColumn UniqueName="FullName" HeaderText="Initiated By" DataField="FullName">
                <ItemStyle HorizontalAlign="Left" Width="110px"/>
                <HeaderStyle HorizontalAlign="Left" Width="110px" />
            </telerik:GridBoundColumn>

            <telerik:GridBoundColumn UniqueName="Company" HeaderText="Company" DataField="CompanyName" Visible="True">
                <ItemStyle HorizontalAlign="Left" Width="150px" VerticalAlign="Top" Wrap="true" />
                <HeaderStyle HorizontalAlign="Left" Width="150px" />
            </telerik:GridBoundColumn>
 
            <telerik:GridBoundColumn UniqueName="AltReference" HeaderText="Alt Ref #" DataField="AltRefNumber" Visible="True">
                <ItemStyle HorizontalAlign="Left" Width="130px" VerticalAlign="Top" Wrap="true" />
                <HeaderStyle HorizontalAlign="Left" Width="130px" />
            </telerik:GridBoundColumn>
 
             <telerik:GridBoundColumn UniqueName="CreateDate" HeaderText="Create Date" DataField="CreateDate"  DataFormatString="{0:MM/dd/yy}">
                <ItemStyle HorizontalAlign="Left" Width="90px"/>
                <HeaderStyle HorizontalAlign="Left" Width="90px" />
            </telerik:GridBoundColumn>  
            
            <telerik:GridBoundColumn UniqueName="DaysInProcess" HeaderText="Days In Process" DataField="nDaysInProcess">
                <ItemStyle HorizontalAlign="Left" Width="90px"/>
                <HeaderStyle HorizontalAlign="Left" Width="90px" />
            </telerik:GridBoundColumn>          

            <telerik:GridBoundColumn UniqueName="RequiredBy" HeaderText="Required By" DataField="RequiredBy"  DataFormatString="{0:MM/dd/yy}" Visible="False">
                <ItemStyle HorizontalAlign="Left" Width="90px"/>
                <HeaderStyle HorizontalAlign="Left" Width="90px" />
            </telerik:GridBoundColumn>      



            <telerik:GridBoundColumn UniqueName="Subject" HeaderText="Subject" DataField="sSubject">
                <ItemStyle HorizontalAlign="Left" Width="200px"/>
                <HeaderStyle HorizontalAlign="Left" Width="200px" />
            </telerik:GridBoundColumn>

            <telerik:GridBoundColumn UniqueName="CloseDate" HeaderText="Date Closed" DataField="CloseDate"  DataFormatString="{0:MM/dd/yy}">
                <ItemStyle HorizontalAlign="Left" Width="90px"/>
                <HeaderStyle HorizontalAlign="Left" Width="90px" />
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


    window.onbeforeunload = function () {
        onThisClientClose()
    }

    function onThisClientClose() {
        //var oWnd = window.radopen("closeSession.aspx", "closeSessionWindow");
        var openCOID = document.getElementById('<%= openCOID.ClientID %>').value
        var contactID = document.getElementById('<%= contactID.ClientID %>').value
        var pageType = document.getElementById('<%= pageType.ClientID %>').value

        $.post("closeSession.aspx?COID=" + openCOID + "&contactID=" + contactID + "&pageType=" + pageType, function () {
            //alert("Who is the man");
            document.getElementById('<%= openCOID.ClientID %>').value = ""
        });
    }

    // End ******************* Menu Handlers ***********************

    function EditChangeOrder(projectid, coID, displaytype,coType) {
        //var projID = document.getElementById('<% = ProjID.ClientID %>').value
        document.getElementById('<%= openCOID.ClientID %>').value = coID

        var oWnd = window.radopen("changeorders_edit.aspx?ProjectID=" + projectid + "&ChangeOrderID=" + coID + "&DisplayType=" + displaytype + "&coType=" + coType, "EditWindow");
        return false;
    }

</script>
</telerik:RadScriptBlock>

</asp:Content>
