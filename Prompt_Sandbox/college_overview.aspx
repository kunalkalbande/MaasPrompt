<%@ Page Language="VB" MasterPageFile="~/content.master" Title="" %>

<%@ Register Assembly="Telerik.Web.UI" Namespace="Telerik.Web.UI" TagPrefix="telerik" %>
<%@ Register Assembly="Telerik.Web.UI" Namespace="Telerik.Charting" TagPrefix="telerik" %>
<%@ Import Namespace="Prompt" %>

<script runat="server">
    
    Private nCollegeID As Integer = 0
    Private ContractAmount As Double = 0
    Private AmmendAmount As Double = 0
    Private TransAmount As Double = 0
    Private InterestIncome As Double = 0
    Private ContractBalance As Double = 0
    
    Private Adjustments As Double = 0
    
    Private bNotesReadOnly As Boolean = True
    Private bProjectReadOnly As Boolean = True
    
      
    Protected Sub Page_Init(ByVal sender As Object, ByVal e As System.EventArgs)
        nCollegeID = Request.QueryString("CollegeID")    'needed here for docks
    End Sub
    
    Private Sub Page_Load(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MyBase.Load

        Session("PageID") = "CollegeOverview"
        
        nCollegeID = Request.QueryString("CollegeID")
        Session("CollegeID") = nCollegeID
        
        lblCollegeName.Text = DirectCast(Master.FindControl("lblViewTitle"), Label).Text
        
        
        'Since this is the primary calling page from the Nav menu, we need to check if current view is something other than
        'Overview and if so redirect
        'Since this is the primary calling page from the Nav menu, we need to check if current view is something other than
        'Overview and if so redirect
        Dim masterTabs As RadTabStrip = Master.FindControl("tabMain")
        Dim sNewLocation As String = ""
        If Request.QueryString("t") <> "y" Then
            If Session("CurrentTab") <> "Overview" Then   'redirect to appropriate tab if available
                For Each radTab In masterTabs.GetAllTabs
                    If radTab.Value = Session("CurrentTab") Then
                        radTab.Selected = True
                        radTab.SelectParents()
                        Response.Redirect(radTab.NavigateUrl)
                        Exit For
                    End If
                Next
            End If
        End If
        Session("CurrentTab") = "Overview"
        'if we have not redirected then we are at the right place
        For Each radTab In masterTabs.GetAllTabs
            If radTab.Value = "Overview" Then
                radTab.Selected = True
                radTab.SelectParents()
                Exit For
            End If
        Next
        
        
        'Configure the Popup Window(s)
        With contentPopups
            .VisibleOnPageLoad = False
            .Skin = "Windows7"
            Dim ww As New Telerik.Web.UI.RadWindow
            ww = New Telerik.Web.UI.RadWindow
            With ww
                .ID = "EditWindow"
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
        
        'get the district record
        Dim FirstSeriesName As String, SecondSeriesName As String, ThirdSeriesName As String, FourthSeriesName As String
        Using db As New PromptDataHelper
            Dim sql As String = "Select FirstBondSeriesName, SecondBondSeriesName, ThirdBondSeriesName, FourthBondSeriesName from Districts Where DistrictID = " & Session("DistrictID")
            db.FillReader(sql)   
            While db.Reader.Read
                FirstSeriesName = db.Reader("FirstBondSeriesName")
                SecondSeriesName = db.Reader("SecondBondSeriesName")
                ThirdSeriesName = db.Reader("ThirdBondSeriesName")
                FourthSeriesName = db.Reader("FourthBondSeriesName")
            End While
        End Using

        lblFirstSeries.Text = FirstSeriesName & ":"
        lblSecondSeries.Text = SecondSeriesName & ":"
        lblThirdSeries.Text = ThirdSeriesName & ":"
        lblFourthSeries.Text = FourthSeriesName & ":"

        'get the college record
        Using db As New College
            db.CallingPage = Page
            db.GetCollege(contentPanel1, nCollegeID)  'note: pass the user control to fill, not Form1 from parent page
            TransAmount = db.GetCollegeTotals("Transactions", nCollegeID)
            AmmendAmount = db.GetCollegeTotals("Amendments", nCollegeID)
            ContractAmount = db.GetCollegeTotals("Contracts", nCollegeID)
            InterestIncome = db.GetCollegeTotals("InterestIncome", nCollegeID)
            Adjustments = db.GetCollegeTotals("Adjustments", nCollegeID)
            
        End Using
        ContractBalance = ContractAmount + AmmendAmount - TransAmount + Adjustments
        
        lblInterestIncome.Text = FormatCurrency(InterestIncome, -1, -2, -1, -2)
 
        lblContractAmount.Text = FormatCurrency(ContractAmount, -1, -2, -1, -2)
        lblAmmendAmount.Text = FormatCurrency(AmmendAmount, -1, -2, -1, -2)
        lblTransAmount.Text = FormatCurrency(TransAmount, -1, -2, -1, -2)
        lblContractBalance.Text = FormatCurrency(ContractBalance, -1, -2, -1, -2)
        lblAdjustments.Text = FormatCurrency(Adjustments, -1, -2, -1, -2)

        ''Configure the College Summary Chart
        chartTotalExpenses.ChartTitle.TextBlock.Appearance.TextProperties.Color = Color.DodgerBlue
        chartTotalExpenses.Width = Unit.Pixel(450)

        Dim csContracts As ChartSeries = chartTotalExpenses.Series(0)
        Dim ciContracts As ChartSeriesItem = csContracts.Items(0)
        With ciContracts
            .YValue = FormatCurrency(ContractAmount, 0)
            .Label.TextBlock.Text = FormatCurrency(ContractAmount, 0)
        End With

        Dim csAmendments As ChartSeries = chartTotalExpenses.Series(1)
        Dim ciAmendments As ChartSeriesItem = csAmendments.Items(0)
        With ciAmendments
            .YValue = FormatCurrency(AmmendAmount, 0)
            .Label.TextBlock.Text = FormatCurrency(AmmendAmount, 0)
        End With

        Dim csTrans As ChartSeries = chartTotalExpenses.Series(2)
        Dim ciTrans As ChartSeriesItem = csTrans.Items(0)
        With ciTrans
            .YValue = FormatCurrency(TransAmount, 0)
            .Label.TextBlock.Text = FormatCurrency(TransAmount, 0)
        End With

        Dim csBal As ChartSeries = chartTotalExpenses.Series(3)
        Dim ciBal As ChartSeriesItem = csBal.Items(0)
        With ciBal
            .YValue = FormatCurrency(ContractBalance, 0)
            .Label.TextBlock.Text = FormatCurrency(ContractBalance, 0)
        End With

        SetSecurity()
        BuildMenu()
 
    End Sub
    
    Private Sub BuildMenu()
        
        If Not IsPostBack Then          'Configure main menu

            With RadMenu1
                .EnableEmbeddedSkins = False
                .Skin = "Prompt"
                .Width = Unit.Percentage(100)
                .EnableOverlay = False
            End With
            
            'build buttons
            Dim but As RadMenuItem
                
            If Not bProjectReadOnly Then
                
                but = New RadMenuItem
                With but
                    .Text = "Add New Project"
                    .ImageUrl = "images/add.png"
                    .Attributes.Add("onclick", "openPopup('project_edit.aspx?new=y&CollegeID=" & nCollegeID & "','projedit',650,650,'yes');")
                    .ToolTip = "Add a New Project."
                    .PostBack = False
                End With
                RadMenu1.Items.Add(but)
            
            
                but = New RadMenuItem
                With but
                    .Text = "Add New Ledger Account"
                    .ImageUrl = "images/addledger.png"
                    .Attributes("onclick") = "return AddNewLedgerAccount(" & nCollegeID & ",this);"
                    .ToolTip = "Add a New Project."
                    .PostBack = False
                End With
                RadMenu1.Items.Add(but)
            
                but = New RadMenuItem
                With but
                    .Text = "Add New Project Group"
                    .ImageUrl = "images/addgroup.png"
                    .Attributes("onclick") = "return AddNewProjectGroup(" & nCollegeID & ",this);"
                    .ToolTip = "Add a New Project."
                    .PostBack = False
                End With
                RadMenu1.Items.Add(but)
 
                but = New RadMenuItem
                With but
                    .Text = "Printer friendly page"
                    .ImageUrl = "images/printer.png"
                    .Attributes("onclick") = "return printSelection(document.getElementById('printdiv'));return false"
                    .ToolTip = "Show Printer Friendly Page."
                    .PostBack = False
                End With
                RadMenu1.Items.Add(but)
            
            End If
            
        End If
        

    End Sub
    
    Private Sub SetSecurity()
        'Sets the security constraints for current page
        Using db As New EISSecurity
            db.CollegeID = nCollegeID

            If db.FindUserPermission("ProjectOverview", "write") Then
                bProjectReadOnly = False

            End If
            
            If db.FindUserPermission("CollegeNotesWidget", "write") Then
                With lnkNewNote
                    .Visible = True
                    .Attributes("onclick") = "return EditNote(0," & nCollegeID & ");"
                End With
                bNotesReadOnly = False
            Else
                bNotesReadOnly = True
                lnkNewNote.Visible = False
            End If
            
            If db.FindUserPermission("CollegeNotesWidget", "read") Then
                dockNotes.Visible = True
            Else
                dockNotes.Visible = False
            End If
            
            
            'trump any widget settings if district is turned off
            Dim tbl As DataTable = db.GetDistrictObjectVisibilitySettings("CollegeWidget")
            For Each row In tbl.Rows
                Select Case row("ObjectID")
                    Case "CollegeNotesWidget"
                        If ProcLib.CheckNullNumField(row("Visibility")) = 0 Then
                            dockNotes.Visible = False
                        End If
                        
                End Select
                
            Next

        End Using
    End Sub
    
    Protected Sub radgridNotesWidget_NeedDataSource(ByVal source As Object, ByVal e As Telerik.Web.UI.GridNeedDataSourceEventArgs) Handles radgridNotesWidget.NeedDataSource
        'loads the grid whenever it needs data (sorting, rebinding, etc...)
        Using db As New promptNote
            radgridNotesWidget.DataSource = db.GetNotes("CollegeID", nCollegeID)
        End Using

    End Sub

    Protected Sub radgridNotesWidget_ItemCreated(ByVal sender As Object, ByVal e As Telerik.Web.UI.GridItemEventArgs) Handles radgridNotesWidget.ItemCreated

        'This event allows us to customize the cell contents - fired before databound

        If (TypeOf e.Item Is GridDataItem) Then
            Dim item As GridDataItem = CType(e.Item, GridDataItem)
            Dim nNoteID As Integer = item.OwnerTableView.DataKeyValues(item.ItemIndex)("NoteID")

            'update the link button to open report window
            Dim linkButton As HyperLink = CType(item("CreatedOn").Controls(0), HyperLink)
            If Not bNotesReadOnly Then
                linkButton.Attributes("onclick") = "return EditNote(" & nNoteID & "," & nCollegeID & ");"
                linkButton.NavigateUrl = "#"
            End If
            linkButton.ToolTip = "Edit selected Note."
            
        End If
    End Sub

    '********************************** Docking *********************************
    Protected Sub RadDock1_DockPositionChanged(ByVal sender As Object, ByVal e As DockPositionChangedEventArgs)

        Dim dockState As String
        Dim serializer As New Script.Serialization.JavaScriptSerializer()
        Dim stateList As Generic.List(Of DockState) = RadDockLayout1.GetRegisteredDocksState()
        Dim serializedList As New StringBuilder()
        Dim i As Integer = 0
        While i < stateList.Count
            serializedList.Append(serializer.Serialize(stateList(i)))
            serializedList.Append("|")
            i += 1
        End While
        dockState = serializedList.ToString()

        'Save the dockState string into DB   
        Using db As New promptUserPrefs
            db.SaveDockState(dockState, "CollegeOverviewDockSettings", "CollegeID", nCollegeID)
        End Using
    End Sub
    
    Protected Sub RadDockLayout1_SaveDockLayout(ByVal sender As Object, ByVal e As Telerik.Web.UI.DockLayoutEventArgs)

        Dim dockState As String
        Dim serializer As New Script.Serialization.JavaScriptSerializer()
        Dim stateList As Generic.List(Of DockState) = RadDockLayout1.GetRegisteredDocksState()
        Dim serializedList As New StringBuilder()
        Dim i As Integer = 0
        While i < stateList.Count
            serializedList.Append(serializer.Serialize(stateList(i)))
            serializedList.Append("|")
            i += 1
        End While
        dockState = serializedList.ToString()
        'Save the dockState string into DB 
        Using db As New promptUserPrefs
            db.SaveDockState(dockState, "CollegeOverviewDockSettings", "CollegeID", nCollegeID)
        End Using
    End Sub
    
    Protected Sub RadDockLayout1_LoadDockLayout(ByVal sender As Object, ByVal e As Telerik.Web.UI.DockLayoutEventArgs)

        Dim serializer As New Script.Serialization.JavaScriptSerializer()
        'Get saved state string from the database - set it to dockState variable for example  
        Dim dockstate As String = ""
        Using db As New promptUserPrefs
            dockstate = db.GetDockState("CollegeOverviewDockSettings", "CollegeID", nCollegeID)
        End Using
        If dockstate <> "" Then
            Dim currentDockStates As String() = dockstate.Split("|")
            For Each stringState As String In currentDockStates
                If stringState <> String.Empty Then
                    Dim state As DockState = serializer.Deserialize(Of DockState)(stringState)

                    Dim dock As RadDock = RadDockLayout1.FindControl(state.UniqueName)
                    Try
                        dock.ApplyState(state)
                    Catch ex As Exception
                        'error here so default config will prevail
                    End Try
                    
                    e.Positions(state.UniqueName) = state.DockZoneID
                    e.Indices(state.UniqueName) = state.Index

                End If
            Next
        End If
        
        'Reset the non changeable dock properties
        dockCollegeOverview.Height = Unit.Pixel(250)
        CreateSaveStateTrigger(dockCollegeOverview)
        
        graphInsert.Height = Unit.Pixel(300)
        graphInsert2.Height = Unit.Pixel(350)

        dockTotalContractsChart.Height = Unit.Pixel(350)
        'dockTotalContractsChart.Width = Unit.Pixel(420)
        CreateSaveStateTrigger(dockTotalContractsChart)
        
        dockBudgetOverview.Height = Unit.Pixel(200)
        CreateSaveStateTrigger(dockBudgetOverview)
        
        radgridNotesWidget.Height = Unit.Pixel(300)
        dockNotes.Height = Unit.Pixel(360)
        CreateSaveStateTrigger(dockNotes)
        
  
    End Sub
    
    Private Sub CreateSaveStateTrigger(ByVal dock As RadDock)
        'Ensure that the RadDock control will initiate postback
        ' when its position changes on the client or any of the commands is clicked.
        'Using the trigger we will "ajaxify" that postback.
        dock.AutoPostBack = True
        dock.CommandsAutoPostBack = True

        Dim saveStateTrigger As New AsyncPostBackTrigger()
        saveStateTrigger.ControlID = dock.ID
        saveStateTrigger.EventName = "DockPositionChanged"
        UpdatePanel1.Triggers.Add(saveStateTrigger)

        saveStateTrigger = New AsyncPostBackTrigger()
        saveStateTrigger.ControlID = dock.ID
        saveStateTrigger.EventName = "Command"
        UpdatePanel1.Triggers.Add(saveStateTrigger)
    End Sub


</script>

<asp:Content ID="Content1" ContentPlaceHolderID="mainBody" runat="Server">
    <telerik:RadWindowManager ID="contentPopups" runat="server">
    </telerik:RadWindowManager>
    <div id="contentwrapper">


               <telerik:radmenu id="RadMenu1" runat="server"  style="z-index:10;" />
  
        <div id="contentcolumn">
            <div id="printdiv" class="innertube"><span class="hdprint">
            <asp:Label ID="lblCollegeName" runat="server"></asp:Label>
            </span><telerik:RadDockLayout ID="RadDockLayout1" runat="server" EnableEmbeddedSkins="false" Skin="Prompt" OnSaveDockLayout="RadDockLayout1_SaveDockLayout"
                    OnLoadDockLayout="RadDockLayout1_LoadDockLayout">
                    <telerik:RadDockZone ID="raddockLeft" runat="server" Orientation="Vertical" FitDocks="false"
                        CssClass="raddockzone">
                        <telerik:RadDock ID="dockCollegeOverview" Title="Project Overview" runat="server"
                            Width="" Height="400px" DockHandle="TitleBar" DockMode="Docked" DefaultCommands="ExpandCollapse"
                            EnableRoundedCorners="True" OnDockPositionChanged="RadDock1_DockPositionChanged"
                            EnableAnimation="true" AutoPostBack="true">
                            <TitlebarTemplate>
                                <asp:Label ID="Label1" runat="server" CssClass="widgetcontractoverviewtitle">Funding Overview</asp:Label>
                            </TitlebarTemplate>
                            <ContentTemplate>
                                <asp:Panel ID="contentPanel1" runat="server">
                                    <table cellpadding="3" cellspacing="0" width="100%" class="project_ov">
                                        <tr>
                                            <td>
                                                Bond Program Name:
                                            </td>
                                            <td>
                                                <asp:Label ID="lblBondProgramName" runat="server"></asp:Label>
                                            </td>
                                        </tr>
                                        <tr class="alt">
                                            <td>
                                                Bond Amount:
                                            </td>
                                            <td>
                                                <asp:Label ID="lblBondAmount" runat="server"></asp:Label>
                                            </td>
                                        </tr>
                                        <tr>
                                            <td>
                                                State Funding Anticipated:
                                            </td>
                                            <td>
                                                <asp:Label ID="lblStateFundAnticipated" runat="server"></asp:Label>
                                            </td>
                                        </tr>
                                        <tr class="alt">
                                            <td>
                                                <asp:Label ID="lblFirstSeries" runat="server"></asp:Label>
                                            </td>
                                            <td>
                                                <asp:Label ID="lblSeries1Amt" runat="server"></asp:Label>
                                            </td>
                                        </tr>
                                        <tr>
                                            <td>
                                                <asp:Label ID="lblSecondSeries" runat="server"></asp:Label>
                                            </td>
                                            <td>
                                                <asp:Label ID="lblSeries2Amt" runat="server"></asp:Label>
                                            </td>
                                        </tr>
                                        <tr class="alt">
                                            <td>
                                                <asp:Label ID="lblThirdSeries" runat="server"></asp:Label>
                                            </td>
                                            <td>
                                                <asp:Label ID="lblSeries3Amt" runat="server"></asp:Label>
                                            </td>
                                        </tr>
                                        <tr>
                                            <td>
                                                <asp:Label ID="lblFourthSeries" runat="server"></asp:Label>
                                            </td>
                                            <td>
                                                <asp:Label ID="lblSeries4Amt" runat="server"></asp:Label>
                                            </td>
                                        </tr>
                                        <tr class="alt">
                                            <td>
                                                Current Series:
                                            </td>
                                            <td>
                                                <span class="blue">
                                                    <asp:Label ID="lblCurrentSeriesNumber" runat="server"></asp:Label></span>
                                            </td>
                                        </tr>
                                        <tr>
                                            <td>
                                                Current Budget Batch:
                                            </td>
                                            <td>
                                                <asp:Label ID="lblCurrentBudgetApprovalBatch" runat="server"></asp:Label>
                                            </td>
                                        </tr>
                                    </table>
                                    <div class="id_display">
                                        ID:<asp:Label ID="lblCollegeID" runat="server"></asp:Label></div>
                                </asp:Panel>
                            </ContentTemplate>
                        </telerik:RadDock>

                         <telerik:RadDock ID="graphInsert" runat="server" Width="" Height="" Title="AnhsGraph" DockHandle="TitleBar"
                            DockMode="Docked" DefaultCommands="ExpandCollapse" OnDockPositionChanged="RadDock1_DockPositionChanged"
                            EnableAnimation="true" AutoPostBack="true" EnableRoundedCorners="True">
                            <TitlebarTemplate>
                                <asp:Label ID="lblGraph1" runat="server" CssClass="widgetnotestitle">Anh's Graph</asp:Label>
                            </TitlebarTemplate>
                            <ContentTemplate>
                               


                            </ContentTemplate>
                        </telerik:RadDock>

                        <telerik:RadDock ID="dockTotalContractsChart" Title="Total Contracts" runat="server" visible="false"
                            Width="" Height="400px" DockHandle="TitleBar" DockMode="Docked" DefaultCommands="ExpandCollapse"
                            EnableRoundedCorners="True" OnDockPositionChanged="RadDock1_DockPositionChanged"
                            EnableAnimation="true" AutoPostBack="true">
                            <TitlebarTemplate>
                                <asp:Label ID="Label2" runat="server" CssClass="widgetcontractchart">Total Contracts</asp:Label>
                            </TitlebarTemplate>
                            <ContentTemplate>
                                <telerik:RadChart ID="chartTotalExpenses" runat="server" Skin="Desert" Width="400px">
                                    <Series>
                                        <telerik:ChartSeries Name="Contracts">
                                            <Appearance>
                                                <FillStyle FillType="ComplexGradient">
                                                    <FillSettings>
                                                        <ComplexGradient>
                                                            <telerik:GradientElement Color="59, 161, 205" />
                                                            <telerik:GradientElement Color="30, 149, 200" Position="0.5" />
                                                            <telerik:GradientElement Color="5, 141, 199" Position="1" />
                                                        </ComplexGradient>
                                                    </FillSettings>
                                                </FillStyle>
                                                <LabelAppearance Position-AlignedPosition="Center">
                                                </LabelAppearance>
                                                <TextAppearance TextProperties-Color="#292929" TextProperties-Font="Arial, 8.25pt, style=Bold">
                                                </TextAppearance>
                                                <Border Color="#ffffff" />
                                            </Appearance>
                                            <Items>
                                                <telerik:ChartSeriesItem Name="Item 1" YValue="200">
                                                </telerik:ChartSeriesItem>
                                            </Items>
                                        </telerik:ChartSeries>
                                        <telerik:ChartSeries Name="Amendments">
                                            <Appearance>
                                                <FillStyle FillType="ComplexGradient">
                                                    <FillSettings>
                                                        <ComplexGradient>
                                                            <telerik:GradientElement Color="153, 115, 169" />
                                                            <telerik:GradientElement Color="139, 88, 160" Position="0.5" />
                                                            <telerik:GradientElement Color="130, 71, 154" Position="1" />
                                                        </ComplexGradient>
                                                    </FillSettings>
                                                </FillStyle>
                                                <TextAppearance TextProperties-Color="#292929" TextProperties-Font="Arial, 8.25pt, style=Bold">
                                                </TextAppearance>
                                                <Border Color="#ffffff" />
                                            </Appearance>
                                            <Items>
                                                <telerik:ChartSeriesItem Name="Item 1" YValue="500">
                                                </telerik:ChartSeriesItem>
                                            </Items>
                                        </telerik:ChartSeries>
                                        <telerik:ChartSeries Name="Transactions">
                                            <Appearance>
                                                <FillStyle FillType="ComplexGradient">
                                                    <FillSettings>
                                                        <ComplexGradient>
                                                            <telerik:GradientElement Color="237, 119, 72" />
                                                            <telerik:GradientElement Color="236, 103, 51" Position="0.5" />
                                                            <telerik:GradientElement Color="237, 86, 27" Position="1" />
                                                        </ComplexGradient>
                                                    </FillSettings>
                                                </FillStyle>
                                                <TextAppearance TextProperties-Color="#292929" TextProperties-Font="Arial, 8.25pt, style=Bold">
                                                </TextAppearance>
                                                <Border Color="#ffffff" />
                                            </Appearance>
                                            <Items>
                                                <telerik:ChartSeriesItem Name="Item 1" YValue="300">
                                                </telerik:ChartSeriesItem>
                                            </Items>
                                        </telerik:ChartSeries>
                                        <telerik:ChartSeries Name="ContractBalance">
                                            <Appearance>
                                                <FillStyle FillType="ComplexGradient">
                                                    <FillSettings>
                                                        <ComplexGradient>
                                                            <telerik:GradientElement Color="74, 182, 41" />
                                                            <telerik:GradientElement Color="57, 173, 22" Position="0.5" />
                                                            <telerik:GradientElement Color="37, 158, 1" Position="1" />
                                                        </ComplexGradient>
                                                    </FillSettings>
                                                </FillStyle>
                                                <TextAppearance TextProperties-Color="#292929" TextProperties-Font="Arial, 8.25pt, style=Bold">
                                                </TextAppearance>
                                                <Border Color="#ffffff" />
                                            </Appearance>
                                            <Items>
                                                <telerik:ChartSeriesItem Name="Item 1" YValue="100">
                                                </telerik:ChartSeriesItem>
                                            </Items>
                                        </telerik:ChartSeries>
                                    </Series>
                                    <PlotArea>
                                        <XAxis Visible="False" VisibleValues="Positive">
                                            <Appearance Color="#ffffff" MajorTick-Color="226, 225, 207" MajorTick-Visible="False">
                                                <MajorGridLines Color="#000000" PenStyle="Solid" />
                                                <LabelAppearance Visible="False">
                                                </LabelAppearance>
                                                <TextAppearance TextProperties-Color="#ffffff">
                                                </TextAppearance>
                                            </Appearance>
                                            <AxisLabel>
                                                <TextBlock>
                                                    <Appearance TextProperties-Color="96, 93, 75">
                                                    </Appearance>
                                                </TextBlock>
                                            </AxisLabel>
                                        </XAxis>
                                        <YAxis>
                                            <Appearance Color="212, 211, 199" MajorTick-Color="226, 225, 207" MinorTick-Color="226, 225, 207"
                                                MinorTick-Width="0">
                                                <MajorGridLines Color="226, 225, 207" PenStyle="Solid" />
                                                <MinorGridLines Color="226, 225, 207" PenStyle="Solid" Width="0" />
                                                <TextAppearance TextProperties-Color="#ffffff">
                                                </TextAppearance>
                                            </Appearance>
                                            <AxisLabel>
                                                <TextBlock>
                                                    <Appearance TextProperties-Color="#ffffff">
                                                    </Appearance>
                                                </TextBlock>
                                            </AxisLabel>
                                        </YAxis>
                                        <Appearance Dimensions-Margins="5%, 5%, 5%, 5%">
                                            <FillStyle FillType="Solid" MainColor="#ffffff">
                                            </FillStyle>
                                            <Border Color="208, 207, 195" />
                                        </Appearance>
                                    </PlotArea>
                                    <Appearance>
                                        <Border Color="#ffffff" />
                                        <FillStyle FillType="Solid" MainColor="#ffffff">
                                        </FillStyle>
                                    </Appearance>
                                    <ChartTitle>
                                        <Appearance Dimensions-Margins="0px, 0px, 0px, 0px">
                                        </Appearance>
                                        <TextBlock Text=" ">
                                            <Appearance TextProperties-Color="#ffffff" TextProperties-Font="Segoe UI, 1px">
                                            </Appearance>
                                        </TextBlock>
                                    </ChartTitle>
                                    <Legend>
                                        <Appearance>
                                            <ItemTextAppearance TextProperties-Color="0, 0, 0" TextProperties-Font="Arial, 8.25pt, style=Bold"
                                                Dimensions-Margins="0px, 0px, 0px, 0px">
                                            </ItemTextAppearance>
                                            <FillStyle MainColor="238, 240, 245">
                                            </FillStyle>
                                            <Border Color="208, 207, 195" />
                                        </Appearance>
                                    </Legend>
                                </telerik:RadChart>
                            </ContentTemplate>
                        </telerik:RadDock>
                    </telerik:RadDockZone>
                    <telerik:RadDockZone ID="raddockRight" runat="server" Orientation="Vertical" FitDocks="False"
                        CssClass="raddockzone">
                        <telerik:RadDock ID="dockBudgetOverview" runat="server" Width="" Height="325px" DockHandle="TitleBar"
                            DockMode="Docked" DefaultCommands="ExpandCollapse" EnableRoundedCorners="True"
                            OnDockPositionChanged="RadDock1_DockPositionChanged" EnableAnimation="true" AutoPostBack="true"
                            Resizable="false" Title="Budget Overview">
                            <TitlebarTemplate>
                                <asp:Label ID="Label3" runat="server" CssClass="widgetbudgetoverviewtitle">Budget Overview</asp:Label>
                            </TitlebarTemplate>
                            <ContentTemplate>
                                <table cellpadding="3" cellspacing="0" width="100%" class="project_ov">
                                    <tr>
                                        <td>
                                            Total Interest Income:
                                        </td>
                                        <td>
                                            <asp:Label ID="lblInterestIncome" runat="server"></asp:Label>
                                        </td>
                                    </tr>
                                    <tr class="alt">
                                        <td>
                                            Total Contracts:
                                        </td>
                                        <td>
                                            <asp:Label ID="lblContractAmount" runat="server"></asp:Label>
                                        </td>
                                    </tr>
                                    <tr>
                                        <td>
                                            Total Amend/CO's:
                                        </td>
                                        <td>
                                            <asp:Label ID="lblAmmendAmount" runat="server"></asp:Label>
                                        </td>
                                    </tr>
                                    <tr class="alt">
                                        <td>
                                            Total Transactions:
                                        </td>
                                        <td>
                                            <asp:Label ID="lblTransAmount" runat="server"></asp:Label>
                                        </td>
                                    </tr>
                                    
                                     <tr >
                                        <td>
                                            Total Contract Adjustments:
                                        </td>
                                        <td>
                                            <asp:Label ID="lblAdjustments" runat="server"></asp:Label>
                                        </td>
                                    </tr>
                                    
                                    
                                    <tr class="alt">
                                        <td>
                                            Contract Balance:
                                        </td>
                                        <td>
                                            <asp:Label ID="lblContractBalance" runat="server"></asp:Label>
                                        </td>
                                    </tr>
                                </table>
                            </ContentTemplate>
                        </telerik:RadDock>
                        <telerik:RadDock ID="dockNotes" runat="server" Width="" Height="" Title="Notes" DockHandle="TitleBar"
                            DockMode="Docked" DefaultCommands="ExpandCollapse" OnDockPositionChanged="RadDock1_DockPositionChanged"
                            EnableAnimation="true" AutoPostBack="true" EnableRoundedCorners="True">
                            <TitlebarTemplate>
                                <asp:Label ID="Label4" runat="server" CssClass="widgetnotestitle">Notes</asp:Label>
                                <asp:HyperLink ID="lnkNewNote" NavigateUrl="#" CssClass="widgetaddbtn" runat="server">Add</asp:HyperLink>
                            </TitlebarTemplate>
                            <ContentTemplate>
                                <telerik:RadGrid ID="radgridNotesWidget" runat="server" AllowSorting="true" AutoGenerateColumns="False"
                                    GridLines="None" Width="100%" EnableAJAX="True" Height="300px" EnableEmbeddedSkins="false" Skin="Prompt">
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
                                </telerik:RadGrid>
                            </ContentTemplate>
                        </telerik:RadDock>


                            <telerik:RadDock ID="graphInsert2" runat="server" Width="" Height="" Title="AnhsGraph" DockHandle="TitleBar"
                            DockMode="Docked" DefaultCommands="ExpandCollapse" OnDockPositionChanged="RadDock1_DockPositionChanged"
                            EnableAnimation="true" AutoPostBack="true" EnableRoundedCorners="True">
                            <TitlebarTemplate>
                                <asp:Label ID="lblGraph2" runat="server" CssClass="widgetnotestitle">Anh's Graph II</asp:Label>
                            </TitlebarTemplate>
                            <ContentTemplate>
                               


                            </ContentTemplate>
                        </telerik:RadDock>





                    </telerik:RadDockZone>
                </telerik:RadDockLayout>
                <asp:HiddenField ID="lblContractorID" runat="server" Value="0" />
                <div style="width: 0px; height: 0px; overflow: hidden; position: absolute; left: -10000px;">
                    Hidden UpdatePanel, which is used to help with saving state when minimizing, moving
                    and closing docks. This way the docks state is saved faster (no need to update the
                    docking zones).
                    <asp:UpdatePanel runat="server" ID="UpdatePanel1">
                    </asp:UpdatePanel>
                </div>
                <telerik:RadAjaxManager ID="RadAjaxManager1" runat="server">
                    <AjaxSettings>
                        <telerik:AjaxSetting AjaxControlID="radgridNotesWidget">
                            <UpdatedControls>
                                <telerik:AjaxUpdatedControl ControlID="radgridNotesWidget" LoadingPanelID="RadAjaxLoadingPanel1" />
                            </UpdatedControls>
                        </telerik:AjaxSetting>
                     </AjaxSettings>
                </telerik:RadAjaxManager>
                <telerik:RadAjaxLoadingPanel ID="RadAjaxLoadingPanel1" runat="server" Height="75px"
                    Width="75px" Transparency="25">
                    <img alt="Loading..." src='<%= RadAjaxLoadingPanel.GetWebResourceUrl(Page, "Telerik.Web.UI.Skins.Default.Ajax.loading.gif") %>'
                        style="border: 0;" />
                </telerik:RadAjaxLoadingPanel>
                <telerik:RadCodeBlock ID="RadCodeBlock1" runat="server">

                    <script type="text/javascript" language="javascript">

                        function AddNewProjectGroup(collegeid, element) {

                            var oWnd = window.radopen("project_group_edit.aspx?ProjectGroupID=0&CollegeID=" + collegeid, "EditWindow");
                            var pos = GetElementPosition(element);
                            var X = pos.x;
                            var Y = pos.y;

                            oWnd.MoveTo(X + 30, Y + element.offsetHeight);

                            return false;
                        }

                        function AddNewLedgerAccount(collegeid, element) {

                            var oWnd = window.radopen("ledger_account_edit.aspx?LedgerAccountID=0&CollegeID=" + collegeid, "EditWindow");
                            var pos = GetElementPosition(element);
                            var X = pos.x;
                            var Y = pos.y;

                            oWnd.MoveTo(X + 30, Y + element.offsetHeight);

                            return false;
                        }

                        function EditNote(id, parentkey) {

                            var oWnd = window.radopen("note_edit.aspx?NoteID=" + id + "&CurrentView=college&KeyValue=" + parentkey + "&WinType=RAD", "EditWindow");
                            return false;
                        }



                        function GetElementPosition(el) {
                            var parent = null;
                            var pos = { x: 0, y: 0 };
                            var box;

                            if (el.getBoundingClientRect) {
                                // IE   
                                box = el.getBoundingClientRect();
                                var scrollTop = document.documentElement.scrollTop || document.body.scrollTop;
                                var scrollLeft = document.documentElement.scrollLeft || document.body.scrollLeft;

                                pos.x = box.left + scrollLeft - 2;
                                pos.y = box.top + scrollTop - 2;

                                return pos;
                            }
                            else if (document.getBoxObjectFor) {
                                // gecko   
                                box = document.getBoxObjectFor(el);
                                pos.x = box.x - 2;
                                pos.y = box.y - 2;
                            }
                            else {
                                // safari/opera   
                                pos.x = el.offsetLeft;
                                pos.y = el.offsetTop;
                                parent = el.offsetParent;
                                if (parent != el) {
                                    while (parent) {
                                        pos.x += parent.offsetLeft;
                                        pos.y += parent.offsetTop;
                                        parent = parent.offsetParent;
                                    }
                                }
                            }


                            if (window.opera) {
                                parent = el.offsetParent;

                                while (parent && parent.tagName != 'BODY' && parent.tagName != 'HTML') {
                                    pos.x -= parent.scrollLeft;
                                    pos.y -= parent.scrollTop;
                                    parent = parent.offsetParent;
                                }
                            }
                            else {
                                parent = el.parentNode;
                                while (parent && parent.tagName != 'BODY' && parent.tagName != 'HTML') {
                                    pos.x -= parent.scrollLeft;
                                    pos.y -= parent.scrollTop;

                                    parent = parent.parentNode;
                                }
                            }
                            return pos;
                        }


                        function GetRadWindow() {
                            var oWindow = null;
                            if (window.RadWindow) oWindow = window.RadWindow;
                            else if (window.frameElement.radWindow) oWindow = window.frameElement.radWindow;
                            return oWindow;
                        }

                    </script>

                </telerik:RadCodeBlock>
            </div>
        </div>
    </div>
</asp:Content>
