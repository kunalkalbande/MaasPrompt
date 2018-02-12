<%@ Control Language="vb" ClassName="PMOverviewControl" %>
<%@ Register Assembly="Telerik.Web.UI" Namespace="Telerik.Web.UI" TagPrefix="telerik" %>
<%@ Import Namespace="Prompt" %>

<script runat="server">
   
    Public view As String = ""
    
          
    Protected Sub Page_Init(ByVal sender As Object, ByVal e As System.EventArgs)
        
        view = Session("pmview")
                
        'Set the view
        Select Case view
            Case "AllProjects"
                grid_PMOverview.MasterTableView.Columns.FindByUniqueName("PMName").Visible = True
                
            Case Else
                grid_PMOverview.MasterTableView.Columns.FindByUniqueName("PMName").Visible = False
                
                'Set group by Spec Package
                'Dim expression As GridGroupByExpression = New GridGroupByExpression
                'Dim gridGroupByField As GridGroupByField = New GridGroupByField

                ''Add select fields (before the "Group By" clause)
                'gridGroupByField = New GridGroupByField
                'gridGroupByField.FieldName = "PMName"
                'gridGroupByField.HeaderText = ""
                'expression.SelectFields.Add(gridGroupByField)

                ''Add a field for group-by (after the "Group By" clause)
                'gridGroupByField = New GridGroupByField
                'gridGroupByField.FieldName = "PMName"
                'expression.GroupByFields.Add(gridGroupByField)

                'grid_PMOverview.MasterTableView.GroupByExpressions.Add(expression)
   
        End Select
    End Sub
    
     
    Private Sub Page_Load(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MyBase.Load

              
        Session("PageID") = "DashboardPMOverviewWidget"
        ProcLib.LoadPopupJscript(Page)

        With grid_PMOverview
            .EnableEmbeddedSkins = False
            .Skin = "Prompt"
            .GroupingEnabled = False
            .AllowSorting = True
            '.EnableViewState = False
                        
            .ClientSettings.AllowColumnsReorder = False
            .ClientSettings.ColumnsReorderMethod = GridClientSettings.GridColumnsReorderMethod.Reorder
            .ClientSettings.Scrolling.AllowScroll = True
            .ClientSettings.Scrolling.ScrollHeight = Unit.Percentage(50)
            .ClientSettings.Scrolling.UseStaticHeaders = True
            .ClientSettings.Resizing.AllowColumnResize = True
            

            .MasterTableView.EnableHeaderContextMenu = False
            .MasterTableView.TableLayout = GridTableLayout.Fixed
            .MasterTableView.AllowMultiColumnSorting = False

            .Height = Unit.Pixel(330)
            
            .ExportSettings.FileName = "PromptPMOverviewExport"
            .ExportSettings.OpenInNewWindow = True
            .ExportSettings.Pdf.PageTitle = "Prompt PM Overview"
            
   
        End With
        
     
        
        'Configure the Popup Window(s)
        With pmOverviewPopups
            .VisibleOnPageLoad = False
            .Skin = "Windows7"
            
            Dim ww As Telerik.Web.UI.RadWindow
            
            ww = New RadWindow
            With ww
                .ID = "EditFlagWindow"
                .NavigateUrl = ""
                .Title = ""
                .Width = 550
                .Height = 300
                '.Left = 20
                .Modal = True
                .VisibleStatusbar = False
                .ReloadOnShow = True
                .Behaviors = WindowBehaviors.Close + WindowBehaviors.Move
            End With
            .Windows.Add(ww)

        End With
        

  
    End Sub
    
       
    Protected Sub grid_PMOverview_NeedDataSource(ByVal source As Object, ByVal e As Telerik.Web.UI.GridNeedDataSourceEventArgs) Handles grid_PMOverview.NeedDataSource
 
        Using db As New promptProject
            db.CallingPage = Page
            grid_PMOverview.DataSource = db.GetAllPMProjects(view)
            
        End Using
    
    End Sub
        
    Protected Sub grid_PMOverview_ItemCommand(ByVal source As Object, ByVal e As Telerik.Web.UI.GridCommandEventArgs)
        ' If multiple buttons are used in a Telerik RadGrid control, use the
        ' CommandName property to determine which button was clicked.

        Select Case e.CommandName       'autolocate the nav menu and main page to appropriate spot
            
            Case "FindProject"
                Dim Args = Split(e.CommandArgument, ",")
                Dim ProjectID As Integer = Args(0)
                Dim CollegeID As Integer = Args(1)
        
                Session("RefreshNav") = True
                Session("RtnFromEdit") = False
                Session("CollegeID") = CollegeID
                Session("DirectCallCount") = 1
                Session("nodeid") = "Project" & ProjectID
                Session("DirectCallURL") = "project_overview.aspx?view=project&ProjectID=" & ProjectID & "&CollegeID=" & CollegeID & "&t=y"

                Response.Redirect("main.aspx")
                
            Case "FindRFIS"
                Dim Args = Split(e.CommandArgument, ",")
                Dim ProjectID As Integer = Args(0)
                Dim CollegeID As Integer = Args(1)
        
                Session("RefreshNav") = True
                Session("RtnFromEdit") = False
                Session("CollegeID") = CollegeID
                Session("DirectCallCount") = 1
                Session("nodeid") = "Project" & ProjectID
                Session("DirectCallURL") = "rfis.aspx?view=project&ProjectID=" & ProjectID & "&CollegeID=" & CollegeID & "&t=y"
                
                Response.Redirect("main.aspx")
                
            Case "FindSubmittals"
                Dim Args = Split(e.CommandArgument, ",")
                Dim ProjectID As Integer = Args(0)
                Dim CollegeID As Integer = Args(1)
        
                Session("RefreshNav") = True
                Session("RtnFromEdit") = False
                Session("CollegeID") = CollegeID
                Session("DirectCallCount") = 1
                Session("nodeid") = "Project" & ProjectID
                Session("DirectCallURL") = "submittals.aspx?view=project&ProjectID=" & ProjectID & "&CollegeID=" & CollegeID & "&t=y"
                
                Response.Redirect("main.aspx")
                
   

        End Select
       

    End Sub
  
    Protected Sub grid_PMOverview_ItemCreated(ByVal sender As Object, ByVal e As Telerik.Web.UI.GridItemEventArgs) Handles grid_PMOverview.ItemCreated
        'This event allows us to customize the cell contents - fired before databound
          
        If (TypeOf e.Item Is GridDataItem) Then
            
            Dim item As GridDataItem = CType(e.Item, GridDataItem)
     
            Dim nProjectID As Integer = item.OwnerTableView.DataKeyValues(item.ItemIndex)("ProjectID")
            Dim nCollegeID As Integer = item.OwnerTableView.DataKeyValues(item.ItemIndex)("CollegeID")
                                                                  
            ''update the link button to find record
            Dim lnk As ImageButton = CType(item("FindProject").Controls(0), ImageButton)
            lnk.CommandArgument = nProjectID & "," & nCollegeID
            lnk.ToolTip = "Click to go directly to Project Overview."
            lnk.ImageUrl = "images/dashboard_transaction_goto.png"

            Dim sStatus As String = ""
            Dim sToolTip As String = ""
            Dim sItemType As String = ""
            
            sItemType = "RFI"
            sStatus = item.OwnerTableView.DataKeyValues(item.ItemIndex)(sItemType & "Status")
            sToolTip = item.OwnerTableView.DataKeyValues(item.ItemIndex)(sItemType & "ToolTip")
                     
            lnk = CType(item(sItemType).Controls(0), ImageButton)
            lnk.CommandArgument = nProjectID & "," & nCollegeID
            lnk.ToolTip = sToolTip
            If sStatus = "none" Then
                lnk.ImageUrl = "images/status_gray1.png"
            ElseIf sStatus = "late" Then
                lnk.ImageUrl = "images/status_red1.png"
            ElseIf sStatus = "warning" Then
                lnk.ImageUrl = "images/status_yellow1.png"
            Else
                lnk.ImageUrl = "images/status_green1.png"
            End If
            
            sItemType = "Submittal"
            sStatus = item.OwnerTableView.DataKeyValues(item.ItemIndex)(sItemType & "Status")
            sToolTip = item.OwnerTableView.DataKeyValues(item.ItemIndex)(sItemType & "ToolTip")
                     
            lnk = CType(item(sItemType).Controls(0), ImageButton)
            lnk.CommandArgument = nProjectID & "," & nCollegeID
            lnk.ToolTip = sToolTip
            If sStatus = "none" Then
                lnk.ImageUrl = "images/status_gray1.png"
            ElseIf sStatus = "late" Then
                lnk.ImageUrl = "images/status_red1.png"
            ElseIf sStatus = "warning" Then
                lnk.ImageUrl = "images/status_yellow1.png"
            Else
                lnk.ImageUrl = "images/status_green1.png"
            End If
            
            sItemType = "Schedule"
            sStatus = item.OwnerTableView.DataKeyValues(item.ItemIndex)(sItemType & "Status")
            sToolTip = item.OwnerTableView.DataKeyValues(item.ItemIndex)(sItemType & "ToolTip")
                     
            lnk = CType(item(sItemType).Controls(0), ImageButton)
            lnk.CommandArgument = nProjectID & "," & nCollegeID
            lnk.ToolTip = sToolTip

            If sStatus = "none" Then
                lnk.ImageUrl = "images/status_gray1.png"
            ElseIf sStatus = "late" Then
                lnk.ImageUrl = "images/status_red1.png"
            ElseIf sStatus = "warning" Then
                lnk.ImageUrl = "images/status_yellow1.png"
            Else
                lnk.ImageUrl = "images/status_green1.png"
            End If
                  
        End If
  
    End Sub
    
    Private Sub grid_PMOverview_ItemDataBound(ByVal sender As Object, ByVal e As Telerik.Web.UI.GridItemEventArgs) Handles grid_PMOverview.ItemDataBound
        If (TypeOf e.Item Is GridDataItem) Then
            'Dim dataItem As GridDataItem = CType(e.Item, GridDataItem)

            'Dim sStatus As String = dataItem.OwnerTableView.DataKeyValues(dataItem.ItemIndex)("RFIStatus")
            'Dim sToolTip As String = dataItem.OwnerTableView.DataKeyValues(dataItem.ItemIndex)("RFIToolTip")
            'Dim nWarning As Integer = 0

            'Dim lnk As New HyperLink
            'lnk.ToolTip = sToolTip
            'If sStatus = "late" Then
            '    lnk.ImageUrl = "images/status_red.png"
            'ElseIf sStatus = "warning" Then
            '    lnk.ImageUrl = "images/status_yellow.png"
            'Else
            '    lnk.ImageUrl = "images/status_green.png"
            'End If
            'dataItem("RFIStatus").Controls.Add(lnk)
            
        End If

    End Sub
    
 
</script>

<telerik:RadWindowManager ID="pmOverviewPopups" runat="server">
</telerik:RadWindowManager>
<telerik:RadGrid Style="z-index: 10000;" ID="grid_PMOverview" OnItemCommand="grid_PMOverview_ItemCommand"
    runat="server" AllowSorting="True" AutoGenerateColumns="False" GridLines="None"
    Width="99%" enableajax="True" Height="" AllowMultiRowSelection="True" autopostback="true">
    <ClientSettings>
        <Scrolling AllowScroll="True" UseStaticHeaders="True" ScrollHeight="50%" />
    </ClientSettings>
    <MasterTableView Width="98%" GridLines="None" NoMasterRecordsText="No Projects Found."
        ShowHeadersWhenNoRecords="False" DataKeyNames="ProjectID,CollegeID,RFIStatus,RFIToolTip,SubmittalStatus,SubmittalToolTip,ScheduleStatus,ScheduleToolTip">
        <Columns>
            <telerik:GridButtonColumn ButtonType="ImageButton" Visible="True" CommandName="FindProject"
                HeaderText="" HeaderTooltip="" UniqueName="FindProject" Reorderable="False"
                ShowSortIcon="False">
                <ItemStyle Width="35px" HorizontalAlign="Center" VerticalAlign="Top" />
                <HeaderStyle Width="35px" HorizontalAlign="Center" />
            </telerik:GridButtonColumn>
                      <telerik:GridBoundColumn DataField="PMName" HeaderText="PMName" SortExpression="PMName" UniqueName="PMName">
                <ItemStyle HorizontalAlign="Left" VerticalAlign="Top" Width="150px" />
                <HeaderStyle HorizontalAlign="Left" Width="150px" />
            </telerik:GridBoundColumn>
            <telerik:GridBoundColumn DataField="ProjectName" HeaderText="Project" SortExpression="ProjectName" UniqueName="ProjectName">
                <ItemStyle HorizontalAlign="Left" VerticalAlign="Top" Width="70%" />
                <HeaderStyle HorizontalAlign="Left" Width="70%" />
            </telerik:GridBoundColumn>

  <%--          <telerik:GridBoundColumn DataField="Status" HeaderText="Status" SortExpression="Status" UniqueName="Status">
                <ItemStyle HorizontalAlign="Left" VerticalAlign="Top" Width="50px" />
                <HeaderStyle HorizontalAlign="Left" Width="50px" />
            </telerik:GridBoundColumn>
--%>
             <telerik:GridButtonColumn ButtonType="ImageButton" CommandName="FindRFIS"  HeaderText="RFIs" SortExpression="RFIStatus" UniqueName="RFI" >
                <ItemStyle HorizontalAlign="Center" VerticalAlign="Top" Width="10%" />
                <HeaderStyle HorizontalAlign="Center" Width="10%" />
            </telerik:GridButtonColumn>
            <telerik:GridButtonColumn  ButtonType="ImageButton" CommandName="FindSubmittals" HeaderText="Submittals" SortExpression="SubmittalStatus" UniqueName="Submittal"  >
                <ItemStyle HorizontalAlign="Center" VerticalAlign="Top" Width="10%" />
                <HeaderStyle HorizontalAlign="Center" Width="10%" />
            </telerik:GridButtonColumn>
            <telerik:GridButtonColumn  ButtonType="ImageButton" CommandName="FindSchedule" HeaderText="Schedule" SortExpression="ScheduleStatus" UniqueName="Schedule" >
                <ItemStyle HorizontalAlign="Center" VerticalAlign="Top" Width="10%" />
                <HeaderStyle HorizontalAlign="Center" Width="10%" />
            </telerik:GridButtonColumn>
 <%--           <telerik:GridButtonColumn  ButtonType="ImageButton" CommandName="FindBudget" HeaderText="Budget" SortExpression="BudgetStatus" UniqueName="Budget">
                <ItemStyle HorizontalAlign="Center" VerticalAlign="Top" Width="10%" />
                <HeaderStyle HorizontalAlign="Center" Width="10%" />
            </telerik:GridButtonColumn>           --%>
   
     
        </Columns>
        <GroupHeaderItemStyle VerticalAlign="Bottom" />
    </MasterTableView>
    <ExportSettings FileName="PromptMyProjectsExport" OpenInNewWindow="True">
    </ExportSettings>
</telerik:RadGrid>
<telerik:RadToolTipManager ID="RadToolTipManager1" runat="server" Sticky="True" Title=""
    Position="BottomCenter" Skin="Office2007" HideDelay="500" ManualClose="False"
    ShowEvent="OnMouseOver" ShowDelay="100" Animation="Fade" AutoCloseDelay="6000"
    AutoTooltipify="False" Width="350" RelativeTo="Mouse" RenderInPageRoot="False">
</telerik:RadToolTipManager>

<telerik:RadCodeBlock ID="RadCodeBlock1" runat="server">

    <script type="text/javascript" language="javascript">



     
    </script>

</telerik:RadCodeBlock>
