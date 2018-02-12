<%@ Page Language="VB" MasterPageFile="~/prompt.master" Title="" %>
<%@ Register Assembly="Telerik.Web.UI" Namespace="Telerik.Web.UI" TagPrefix="telerik" %>
<%@ Import Namespace="Prompt" %>

<script runat="server">
    
    Private bReadOnly As Boolean = True
    Private nProjectID As Integer = 0
    Private nContactID As Integer
    Private nProjID As Integer
    Private contactType As String
    Private parentID As Integer
    Private companyName As String
    Private nContractID As Integer = 0
    Private isPMtheCM As Integer = 0 'David D 6/9/17 added isPMtheCM variable
    
    Protected Sub Page_PreRender(ByVal sender As Object, ByVal e As System.EventArgs)
        Using db As New promptUserPrefs
            db.SaveGridSettings(RadGrid1, "ChangeOrdersGridSettings", "ProjectID", nProjectID)
        End Using
    End Sub
    
    Private Sub Page_Load(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MyBase.Load
       
        ProcLib.CheckSession(Page)
        ProcLib.LoadPopupJscript(Page)
                    
        If Not IsPostBack Then
            nProjectList.SelectedValue = Session("ProjectDropdown")
        Else
            'ypeSelect_change()
        End If
        
        'set up help button
        Session("PageID") = "ChangeOrders"
                          
        'Dim masterTabs As RadTabStrip = Master.FindControl("tabMain")
        Dim masterViewTitle As Label = Master.FindControl("lblViewTitle")
        
        Session("CurrentTab") = "ChangeOrders"
        
        Using db As New RFI
            'David D 6/9/17 added below "Try" for the isPMtheCM variable, if block of code is not nested in Try then a server error occurs
            Try
                nProjectID = Session("ProjectID")
                nContractID = Session("ContractID")
                Dim thObj As Object = db.getCM(nProjectID, nContractID)
            
                Session("CMID") = thObj(0)
                Session("ContractorID") = thObj(1)
                If Session("CMID") = 0 Then isPMtheCM = True Else isPMtheCM = False ' gives pm cm privilages if no cm specified
                'If no PM is assigned in the "Project Overview" Session("CMID") = 0 and isPMtheCM = True
            Catch ex As Exception
            End Try
            'End Try for isPMtheCM variable            
            
            nContactID = db.getContactID(Session("UserID"), Session("DistrictID"))
            contactID.Value = nContactID
        End Using
               
        If Session("RtnFromEdit") <> True Then
            Try
                nProjectID = nProjectList.SelectedValue
                ProjID.Value = nProjectID
            Catch
                Using db As New RFI
                    Dim tbl As DataTable = db.getUserProjects(nContactID)
                    Try
                        nProjectID = tbl.Rows(0).Item("ProjectID")
                        ProjID.Value = nProjectID
                    Catch ex As Exception
                        nProjectID = 0
                    End Try
                    'lblTemp.Text = nProjectID & " - DB Value"
                End Using
            End Try
            Session("ProjectID") = nProjectID
            Session("ContractID") = Nothing
        ElseIf Session("RtnFromEdit") = True Then
            
            nProjectList.SelectedValue = Session("ProjectID")
            nProjectID = Session("ProjectID")
            cboTypeSelect.SelectedValue = Session("COType") & "s"
            TypeSelect_change()
            'RadGrid1.MasterTableView.DetailTables(0).GetColumn("CONumber").HeaderText = Session("COType") & " #"
            If Session("COType") = "PCO" Then
                'RadGrid1.MasterTableView.DetailTables(0).GetColumn("RequiredBy").Visible = True
                'RadGrid1.MasterTableView.DetailTables(0).GetColumn("DaysInProcess").Visible = False
                ''colorLegend.Visible = True
            ElseIf Session("COType") = "COR" Then
                'RadGrid1.MasterTableView.DetailTables(0).GetColumn("RequiredBy").Visible = False
                ' RadGrid1.MasterTableView.DetailTables(0).GetColumn("DaysInProcess").Visible = True
                'colorLegend.Visible = False
            End If
            'RadGrid1.Rebind()
            Session("RtnFromEdit") = Nothing
            nContractID = Session("ContractID")
            checkReOpen.Value = True
            testPlace.Value = Session("COType")
           
        End If
        
        Try
            Using db As New RFI
                'Dim contactData As Object = db.getContactData(nContactID, Session("DistrictID"))
                'parentID = contactData(0)
                'Session("ParentContactID") = parentID
                'contactType = contactData(1)
                'Session("ContactType") = contactType
                'companyName = contactData(2)                       
                'Dim Obj As Object = db.getTeamContactData(Session("DistrictID"), nContactID, nProjectID)
                Dim Obj As Object = db.getContactData(nContactID, Session("DistrictID"))
                parentID = Obj(0)
                Session("ParentContactID") = parentID
                contactType = Obj(1)
                Session("ContactType") = contactType
               
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
            If Session("COType") = "" Then
                Session("COType") = "PCO"
            End If
        Else
            
        End If
        
        nProjectID = nProjectList.SelectedValue
        If Not IsPostBack Then
            RadGrid1.MasterTableView.DetailTables(0).GetColumn("RequiredBy").Visible = True
            RadGrid1.MasterTableView.DetailTables(0).GetColumn("DaysInProcess").Visible = False
            RadGrid1.MasterTableView.DetailTables(0).GetColumn("CONumber").HeaderText = "PCO #"
            colorLegend.Visible = True
        End If
    End Sub
    
    Private Sub buildProjectDropdown()
        'If Not IsPostBack Then
        Dim tbl As DataTable
        Using db As New RFI
            tbl = db.getUserProjects(nContactID)
            With nProjectList
                .DataValueField = "ProjectID"
                .DataTextField = "ProjectName"
                .DataSource = tbl
                .DataBind()
            End With
        End Using
        'End If
    End Sub
 
    Private Sub nProjectList_change() Handles nProjectList.SelectedIndexChanged
        nProjectID = nProjectList.SelectedValue
        ProjID.Value = nProjectID
        Session("ProjectDropdown") = nProjectList.SelectedValue
        RadMenu1.Dispose()
        RadMenu1.Items.Clear()
        BuildMenu()
    End Sub
    
    Private Sub BuildMenu()
        
        'Configure Tool Bar
            
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
        
        'build buttons
            Dim but As RadMenuItem
                
            but = New RadMenuItem
            With but
                .Text = "Add New PCO"
                .ImageUrl = "images/add.png"
                .Attributes("onclick") = "return EditChangeOrder(" & nProjectID & ",0,'New','PCO');"
                .ToolTip = "Add a New Potential Change Order."
            .PostBack = False
                'If bReadOnly Then
                '.Visible = False
                'Else
            .Visible = True
                'End If
            End With
        If Session("ContactType") <> "Design Professional" Then
            RadMenu1.Items.Add(but)
            but = New RadMenuItem
            but.IsSeparator = True
            RadMenu1.Items.Add(but)
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
            If contactType = "Construction Manager" Or contactType = "ProjectManager" Then
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
                .Visible = True
            End With
            If contactType = "Construction Manager" Or contactType = "ProjectManager" Then
            'RadMenu1.Items.Add(but)
            'but = New RadMenuItem
            'but.IsSeparator = True
            'RadMenu1.Items.Add(but)
            End If
                                                                            
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
            RadGrid1.Rebind()
            'RadMenu1.Attributes("onclick") = "return EditMeeting(" & nProjectID & ",0,'New');"
        
    End Sub
  
    Private Sub TypeSelect_change() Handles cboTypeSelect.SelectedIndexChanged
        Dim HeadName As String = "PCOs"
        Dim addName As String = "Add New Change Order"
        Select Case cboTypeSelect.SelectedValue
            Case "PCOs"
                HeadName = "PCO #"
                Session("COType") = "PCO"
                addName = "Add New Potential Change Order"
                RadGrid1.MasterTableView.DetailTables(0).GetColumn("RequiredBy").Visible = True
                RadGrid1.MasterTableView.DetailTables(0).GetColumn("DaysInProcess").Visible = False
                colorLegend.Visible = True
            Case "CORs"
                HeadName = "COR #"
                Session("COType") = "COR"
                addName = "Add New Change Order Request"
                RadGrid1.MasterTableView.DetailTables(0).GetColumn("RequiredBy").Visible = False
                RadGrid1.MasterTableView.DetailTables(0).GetColumn("DaysInProcess").Visible = True
                colorLegend.Visible = False
        End Select
              
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
            Dim dRequiredBy As String = ProcLib.CheckNullDBField(dataItem.OwnerTableView.DataKeyValues(dataItem.ItemIndex)("PCORequiredBy"))
            Dim sStatus As String = ProcLib.CheckNullDBField(dataItem.OwnerTableView.DataKeyValues(dataItem.ItemIndex)("Status"))
            Dim wfPosition As String = ProcLib.CheckNullDBField(dataItem.OwnerTableView.DataKeyValues(dataItem.ItemIndex)("WorkFlowPosition"))
            Dim sNewWorkflow As String = ProcLib.CheckNullDBField(dataItem.OwnerTableView.DataKeyValues(dataItem.ItemIndex)("NewWorkflow"))
            Dim dDate As Date
            
            dataItem.CssClass = "rfi_unassigned"
            
            If sStatus = "Unassigned" Or sStatus = "Active" Then
                dataItem.Item("RequiredBy").CssClass = "rfi_pending"
                'dataItem.CssClass = "rfi_pending"
                If sStatus = "Unassigned" Then
                    'dataItem.CssClass = "rfi_unassigned"
                    dataItem.Item("RequiredBy").CssClass = "rfi_unassigned"
                End If
                If nProjectList.SelectedValue = "PCOs" Then
                    If dRequiredBy <> "" Then
                        dDate = DateTime.Parse(dRequiredBy)
                    End If
                    'dDate = Date.ParseExact(dRequiredBy, "dd/MM/yyy", System.Globalization.DateTimeFormatInfo.InvariantInfo)
                    If dRequiredBy <> "" Then
                        'dDate = DateTime.Parse(dRequiredBy)
                    End If
                End If
                               
                If IsDate(dDate) Then
                    If dDate = DateAdd(DateInterval.Day, 1, Date.Today) Or dDate = DateAdd(DateInterval.Day, 2, Date.Today) Then
                        'dataItem.CssClass = "rfi_warning"
                        dataItem.Item("RequiredBy").CssClass = "rfi_warning"
                    ElseIf CDate(dDate) < CDate(Now()) Then
                        'dataItem.CssClass = "rfi_overdue"
                        dataItem.Item("RequiredBy").CssClass = "rfi_overdue"
                    End If
                End If
            ElseIf sStatus = "Closed" Then
                'dataItem.CssClass = "rfi_answered"
                dataItem.Item("RequiredBy").CssClass = "rfi_answered"
                dataItem.Font.Bold = False
            End If
            
            If wfPosition = "None" Then
                'dataItem.CssClass = "rfi_preparing"
                dataItem.Item("RequiredBy").CssClass = "rfi_preparing"
                dataItem.Font.Bold = False
                
            End If
            
            Select Case Trim(wfPosition)
                'David D 6/9/17 added condition for isPMtheCM below in first case
                Case "CM:Review Pending", "CM:Completion Pending", "CM:Response Pending", "CM:Distribution Pending"
                    If ((Session("ContactType") = "Construction Manager" And isPMtheCM = False) And Trim(sNewWorkflow) = "True") Then
                        dataItem.CssClass = "NewWorkflow"
                        
                    End If
                Case "GC:Receipt Pending"
                    If Session("ContactType") = "General Contractor" And Trim(sNewWorkflow) = "True" Then
                        dataItem.CssClass = "NewWorkflow"
                    End If
                Case "DP:Review Pending"
                    If Session("ContactType") = "Design Professional" And Trim(sNewWorkflow) = "True" Then
                        dataItem.CssClass = "NewWorkflow"
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

    <asp:HiddenField ID="checkReOpen" runat="server" />

    <asp:HiddenField ID="testPlace" runat="server" />

   <asp:Label ID="lblModule" runat="server" Text="Change Orders" style="z-index:600;left:10px;top:8px;position:relative;font-size:18px;font-weight:bold;letter-spacing:3px"></asp:Label>

    <telerik:RadComboBox ID="nProjectList" runat="server" Width="300px" Height="100px" Style="z-index: 200;left:30px;
        position:relative;top:8px;" Skin="Vista"  TabIndex="7" AutoPostBack="true" Visible="true">
    </telerik:RadComboBox>

    <telerik:RadComboBox ID="cboTypeSelect" runat="server" Width="170px" Height="50px" Style="z-index: 200;left:40px;
        position:relative;top:8px;" Skin="Vista"  TabIndex="7" AutoPostBack="true" Visible="true">
         <Items>
            <telerik:RadComboBoxItem runat="server" Text="Potential Change Orders" Value="PCOs" />
            <telerik:RadComboBoxItem runat="server" Text="Change Order Requests" Value="CORs" />          
        </Items>
    </telerik:RadComboBox>

    <asp:Panel id="colorLegend" runat="server" style="width:1050px">    
        <div style="height:16px;border-style:solid;border-width:0px;width:99%;position:relative;top:10px;z-index:100">
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
            <div class="rfi_answered" style="width:150px;height:16px;position:relative;display:inline-block;text-align:center;font-size:10px">Complete/Closed</div>
        </div>
    </asp:Panel>

    <telerik:radmenu id="RadMenu1" runat="server" onitemclick="RadMenu1_ItemClick" style="position:relative;z-index: 10;top:-18px;width:330px;height:28px" />
    
    <telerik:RadGrid ID="RadGrid1" runat="server" AllowSorting="true" AutoGenerateColumns="False"
        GridLines="None" Width="99%" EnableEmbeddedSkins="false" enableajax="True" Style="Top:16px;position:relative">
        <ClientSettings>
            <Selecting AllowRowSelect="False" />
            <Scrolling AllowScroll="True" UseStaticHeaders="True" ScrollHeight="50%" />
        </ClientSettings>

        <MasterTableView Width="99%" GridLines="None" DataKeyNames="ContractID,BidPackNumber" 
            NoMasterRecordsText="No Change Orders found." >
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
             <telerik:GridTableView runat="server" Name="RFIs" DataKeyNames="sCONumber,RFIReference,FullName,CreateDate,PCORequiredBy,Subject,COID,Status,WorkFlowPosition,NewWorkflow" TableLayout="Auto" >
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
                <ItemStyle HorizontalAlign="Left" Width="130px"/>
                <HeaderStyle HorizontalAlign="Left" Width="130px" />
            </telerik:GridBoundColumn>      

             <telerik:GridBoundColumn UniqueName="RequiredBy" HeaderText="Required By" DataField="PCORequiredBy"  DataFormatString="{0:MM/dd/yy}" Visible="true">
                <ItemStyle HorizontalAlign="Left" Width="100px"/>
                <HeaderStyle HorizontalAlign="Left" Width="100px" />
            </telerik:GridBoundColumn>    
            
            <telerik:GridBoundColumn UniqueName="DaysInProcess" HeaderText="Days In Process" DataField="nDaysInProcess" Visible="true">
                <ItemStyle HorizontalAlign="Left" Width="100px"/>
                <HeaderStyle HorizontalAlign="Left" Width="100px" />
            </telerik:GridBoundColumn>  

            <telerik:GridBoundColumn UniqueName="Subject" HeaderText="Subject" DataField="sSubject">
                <ItemStyle HorizontalAlign="Left" Width="300px"/>
                <HeaderStyle HorizontalAlign="Left" Width="300px" />
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
    $(document).ready(function () {
        var checkOpen = document.getElementById('<%= checkReOpen.ClientID %>').value
        if (checkOpen === 'True') {
            //alert('This works')
            //tryThis()
            //EditChangeOrder(286, 20, 'Existing', 'COR')

            //window.open('changeorders_edit.aspx', '_new','height=500px,width=800px');

        } else {
            //alert('Not so much')

        }

    });

    function tryThis() {
        alert('This other thing works.')
    }

    function onThisClientClose() {
        document.getElementById('<%= checkReOpen.ClientID %>').value = 'True' 
        //alert('You are here')
        //EditChangeOrder(234, 23, 'Edit', 'COR')
        var openCOID = document.getElementById('<%= openCOID.ClientID %>').value
        var contactID = document.getElementById('<%= contactID.ClientID %>').value
        var pageType = document.getElementById('<%= pageType.ClientID %>').value

        $.post("closeSession.aspx?COID=" + openCOID + "&contactID=" + contactID + "&pageType=" + pageType, function () {
            //alert("Who is the man");
            document.getElementById('<%= openCOID.ClientID %>').value = ""
        });

    }
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

    function EditChangeOrder(projectid, coID, displaytype, coType) {
       
        document.getElementById('<%= openCOID.ClientID %>').value = coID

        var oWnd = window.radopen("changeorders_edit.aspx?ProjectID=" + projectid + "&ChangeOrderID=" + coID + "&DisplayType=" + displaytype + "&coType=" + coType, "EditWindow");
        return false;
        //var projID = document.getElementById('<% = ProjID.ClientID %>').value
    }

</script>
</telerik:RadScriptBlock>

</asp:Content>
