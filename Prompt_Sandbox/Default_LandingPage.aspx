<%@ Page Language="VB" %>
<%@ Register Assembly="Telerik.Web.UI" Namespace="Telerik.Web.UI" TagPrefix="telerik" %>
<%@ Register Assembly="Telerik.Web.UI" Namespace="Telerik.Charting" TagPrefix="telerik" %>
<%@ Import Namespace="Prompt" %>

<script runat="server">
    Private nDistrictID As Integer = 0
    Private nCollegeID As Integer = 0
    Private ContractAmount As Double = 0
    Private AmmendAmount As Double = 0
    Private TransAmount As Double = 0
    Private InterestIncome As Double = 0
    Private ContractBalance As Double = 0    
    Private Adjustments As Double = 0
    
    Private collegeIDOne As Integer
    Private collegeIDTwo As Integer
    Private collegeIDThree As Integer
    Private collegeIDFour As Integer
    Private districtName As String
    Private collegeNameOne As String
    Private collegeNameTwo As String
    Private collegeNameThree As String
    Private collegeNameFour As String
    Private bondSiteName As String
    Private bondSiteURL As String
    Private collegeOneLogo As String
    Private collegeTwoLogo As String
    Private collegeThreeLogo As String
    Private collegeFourLogo As String
    Private collegeLogoSizeOne As String
    Private collegeLogoSizeTwo As String
    Private collegeLogoSizeThree As String
    Private collegeLogoSizeFour As String
    Private legendOne As String
    Private legendTwo As String
    Private legendThree As String
    Private titleName As String
    
    Private collegeOneBondAmount As Integer
    Private collegeTwoBondAmount As Integer
    Private collegeThreeBondAmount As Integer
    Private collegeFourBondAmount As Integer
        
    Protected Sub Page_Init(ByVal sender As Object, ByVal e As System.EventArgs)
        nDistrictID = Session("DistrictID")    'needed here for docks
        setCampusValues()
        getBondAmounts()
    End Sub
    
    Private Sub Page_Load(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MyBase.Load
        setObjectValues()     
        configRadChart()              
        buildProjectLists()
               
    End Sub
 
    Private Sub setCampusValues()
		collegeIDOne = 146
        collegeIDTwo = 63
        collegeIDThree = 145
        collegeIDFour = 147
        
        districtName = "ABC Community College District"
        collegeNameOne = "ABC Community College District"
        collegeNameTwo = "A College"
        collegeNameThree = "B College"
        collegeNameFour = "C College"
        
		legendOne = "A College"
		legendTwo = "B College"
		legendThree = "C College"

		titleName = "Measure J Bond"
		
        bondSiteName = "ABC College Bond Site"
        bondSiteURL = "http://nocccdbond.maasco.com"
        
        collegeOneLogo = "ABC.png"
        collegeTwoLogo = "A.png"
        collegeThreeLogo = "B.png"
        collegeFourLogo = "C.png"
          
        collegeLogoSizeOne = "40px"
        collegeLogoSizeTwo = "40px"
        collegeLogoSizeThree = "40px"
        collegeLogoSizeFour = "40px"
        
    End Sub
    
    Private Sub setObjectValues()
        collegeOneName.Text = collegeNameOne
        collegeTwoName.Text = collegeNameTwo
        collegeThreeName.Text = collegeNameThree
        collegeFourName.Text = collegeNameFour
        
    End Sub
    
    Private Sub buildProjectLists()
        Using db As New LandingPage
            Dim str As String
        
            str = db.buildProjectLists(collegeIDTwo)
            insertTwo.Text = str
            
            str = db.buildProjectLists(collegeIDThree)
            insertThree.Text = str
            
            str = db.buildProjectLists(collegeIDFour)
            insertFour.Text = str
            
        End Using
    End Sub
    
    Private Sub getBondAmounts()
        Using db As New LandingPage
            collegeOneBondAmount = FormatCurrency(db.getCollegeBondAmount(collegeIDOne))
            collegeTwoBondAmount = FormatCurrency(db.getCollegeBondAmount(collegeIDTwo))
            collegeThreeBondAmount = db.getCollegeBondAmount(collegeIDThree)
            collegeFourBondAmount = db.getCollegeBondAmount(collegeIDFour)  
        End Using
    End Sub
    
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
            db.SaveDockState(dockState, "DashboardDockSettings", "DistrictID", nDistrictID)
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
            db.SaveDockState(dockState, "DashboardDockSettings", "DistrictID", nDistrictID)
        End Using
    End Sub
    
    Protected Sub RadDockLayout1_LoadDockLayout(ByVal sender As Object, ByVal e As Telerik.Web.UI.DockLayoutEventArgs)    
        
        UpperLeftBox.Height = Unit.Pixel(355)
        CreateSaveStateTrigger(UpperLeftBox)
        
        LowerLeftBox.Height = Unit.Pixel(355)
        CreateSaveStateTrigger(LowerLeftBox)
        
        UpperRightBox.Height = Unit.Pixel(355)
        CreateSaveStateTrigger(UpperRightBox)
        
        LowerRightBox.Height = Unit.Pixel(355)
        CreateSaveStateTrigger(LowerRightBox)
        
        lblViewTitle.Text = districtName
        lblViewTitle.CssClass = "college_lbl"
        
        LeftDocZone.MinWidth = Unit.Pixel(550)
        RightDocZone.MinWidth = Unit.Pixel(550)
        
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
    
    Private Sub configRadChart()
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

        'get the college record
        Dim chart As Telerik.Web.UI.RadChart
        Dim zDiv As String
        Dim skipItem As Boolean = False
        Dim lbl As System.Web.UI.WebControls.Label
        
        For x = 1 To 4
            Select Case x
                Case 1
                    skipItem = True
                Case 2
                    skipItem = False
                    chart = chartTotalExpenses2
                    nCollegeID = collegeIDTwo
                    zDiv = "insertTwo"
                    'lbl = college_A
                Case 3
                    skipItem = False
                    chart = chartTotalExpenses3
                    nCollegeID = collegeIDThree
                    zDiv = "insertThree"
                Case 4
                    skipItem = False
                    chart = chartTotalExpenses4
                    nCollegeID = collegeIDFour
                    zDiv = "insertFour"
            End Select
            
            If skipItem = False Then
                         
                Using db As New College
                    db.CallingPage = Page
                    'db.GetCollege(contentPanel1, nCollegeID)  'note: pass the user control to fill, not Form1 from parent page
                    TransAmount = db.GetCollegeTotals("Transactions", nCollegeID)
                    AmmendAmount = db.GetCollegeTotals("Amendments", nCollegeID)
                    ContractAmount = db.GetCollegeTotals("Contracts", nCollegeID)
                    InterestIncome = db.GetCollegeTotals("InterestIncome", nCollegeID)
                    Adjustments = db.GetCollegeTotals("Adjustments", nCollegeID)
            
                End Using
                ContractBalance = ContractAmount + AmmendAmount - TransAmount + Adjustments
        
                'Configure the College Summary Chart               
                chart.ChartTitle.TextBlock.Appearance.TextProperties.Color = Color.DodgerBlue
                chart.Width = Unit.Pixel(250)
                chart.Legend.Appearance.Position.AlignedPosition = Styles.AlignedPositions.Left
                
                Dim csContracts As ChartSeries = chart.Series(0)
                Dim ciContracts As ChartSeriesItem = csContracts.Items(0)
                With ciContracts
                    .YValue = FormatCurrency(ContractAmount, 0)
                    .Label.TextBlock.Text = FormatCurrency(ContractAmount, 0)
                End With

                Dim csAmendments As ChartSeries = chart.Series(1)
                Dim ciAmendments As ChartSeriesItem = csAmendments.Items(0)
                With ciAmendments
                    .YValue = FormatCurrency(AmmendAmount, 0)
                    .Label.TextBlock.Text = FormatCurrency(AmmendAmount, 0)
                End With

                Dim csTrans As ChartSeries = chart.Series(2)
                Dim ciTrans As ChartSeriesItem = csTrans.Items(0)
                With ciTrans
                    .YValue = FormatCurrency(TransAmount, 0)
                    .Label.TextBlock.Text = FormatCurrency(TransAmount, 0)
                End With

                Dim csBal As ChartSeries = chart.Series(3)
                Dim ciBal As ChartSeriesItem = csBal.Items(0)
                With ciBal
                    .YValue = FormatCurrency(ContractBalance, 0)
                    .Label.TextBlock.Text = FormatCurrency(ContractBalance, 0)
                End With
                                                              
            End If
            Using db As New promptWorkflow
                Dim tbl As DataTable = db.GetInboxWorkflowTransactions(Session("WorkflowRoleID"))
                    
                If tbl.Rows.Count > 0 Then
                    districtInBox.Visible = True
                Else
                    districtInBox.Visible = False
                End If
                    
            End Using
            'buildProjectLists(nCollegeID, zDiv)
            
        Next
        
    End Sub
    
</script>

<html style="margin-top:0px">
<head id="Head1"> 
<title ></title>
    <link href="Styles.css" rel="stylesheet" type="text/css" />
    <link href="skins/Prompt/TabStrip.Prompt.css" rel="stylesheet" type="text/css" />
    <link href="skins/Prompt/Grid.Prompt.css" rel="stylesheet" type="text/css" />
    <link href="skins/Prompt/Dock.Prompt.css" rel="stylesheet" type="text/css" />
    <link href="skins/Prompt/Menu.Prompt.css" rel="stylesheet" type="text/css" />
   
  
    <script src="js/jquery-1.10.1.min.js" type="text/javascript"></script>
    <script src="js/jquery.canvasjs.min.js" type="text/javascript"></script>


    <script type="text/javascript">
        $(window).load(function () {
            CanvasJS.addColorSet('maasColors',
             [//colorSet Array
             '#F75200',
             '#02B517',
             '#0090DE'
        ]);

            var amountOne = <% = collegeOneBondAmount %>;
            var amountTwo = <% = collegeTwoBondAmount %>;
            var amountThree = <% = collegeThreeBondAmount %>;
            var amountFour = <% = collegeFourBondAmount %>;
            var amountTotal = amountTwo + amountThree + amountFour;
            var percentTwo = (amountTwo / amountTotal * 100).toFixed(2);
            var percentThree = (amountThree / amountTotal * 100).toFixed(2);
            var percentFour = (amountFour / amountTotal * 100).toFixed(2);
            var chartNameOne = '<% = collegeNameTwo %>';
            var chartNameTwo = '<% =collegeNameThree %>';
            var chartNameThree = '<% = collegeNameFour %>';
            var legendOne = '<% = legendOne %>';
            var legendTwo = '<% = legendTwo %>';
            var legendThree = '<% = legendThree %>';
            var titleName = '<% = titleName %>';

            amountOne = amountOne.toFixed(2).replace(/(\d)(?=(\d{3})+\.)/g, '$1,');
            //amountOne = amountOne.slice(0-3)
            amountTwo = amountTwo.toFixed(2).replace(/(\d)(?=(\d{3})+\.)/g, '$1,');
            amountThree = amountThree.toFixed(2).replace(/(\d)(?=(\d{3})+\.)/g, '$1,');
            amountFour = amountFour.toFixed(2).replace(/(\d)(?=(\d{3})+\.)/g, '$1,');

            //var collegeNameOne =<% = collegeNameOne %>

            var collegeOne = chartNameOne + '<br/>$' + amountTwo;
            var collegeTwo = chartNameTwo + '<br/>$' + amountThree;
            var collegeThree = chartNameThree + '<br/>$' + amountFour;
            var stitle = titleName + ' ' + amountOne

            $("#chartContainer").CanvasJSChart({
                colorSet: 'maasColors',

                title: {
                    text: stitle,
                    fontSize: 18,
                    wrap: true,
                    maxWidth: 200
                },
                axisY: {
                    title: "Products in %"
                },
                legend: {
                    verticalAlign: "center",
                    horizontalAlign: "right",
                    fontSize: 9.5,
                    fontFamily: "Arial"
                    
                    
                },
                data: [
		{
		    type: "pie",
		    showInLegend: true,
		    toolTipContent: "{label} <br/> {y} %",
		    indexLabel: "{y} %",
		    dataPoints: [
				{ label: collegeOne, y: percentTwo, legendText: legendOne },
				{ label: collegeTwo, y: percentThree, legendText: legendTwo },
				{ label: collegeThree, y: percentFour, legendText: legendThree },

			]
		}
		]
            });
        });

    </script>

</head>
<body>
    <form id="Form1" method="post" runat="server">
    <telerik:RadScriptManager ID="RadScriptManager1" runat="server" />
    <input type="hidden" id="bondAmountTwo" value="<% = collegeTwoBondAmount %>" />

    <telerik:RadStyleSheetManager ID="RadStyleSheetManager1" runat="server" />
        <div id="contentwrapper" style="position:absolute;top:0px">
            <div class="innertube" style="min-width:1000px">
                <asp:Panel ID="panelViewTitle" class="title" style="position:relative;top:0px" runat="server" Height="62">
                    <asp:Label ID="lblViewTitle" runat="server"></asp:Label>
                </asp:Panel>
                <telerik:RadDockLayout ID="RadDockLayout1" runat="server" EnableEmbeddedSkins="false"
                    Skin="Prompt" OnSaveDockLayout="RadDockLayout1_SaveDockLayout" OnLoadDockLayout="RadDockLayout1_LoadDockLayout">

                    <telerik:RadDockZone ID="LeftDocZone" runat="server" Orientation="Vertical" FitDocks="false" Width="49%">

                    <telerik:RadDock ID="UpperLeftBox" runat="server" Width="" Height="" Title="Title"
                        DockHandle="TitleBar" OnDockPositionChanged="RadDock1_DockPositionChanged" 
                        EnableAnimation="true" AutoPostBack="false" EnableRoundedCorners="True" Resizable="true">
                        <Commands>
                            <telerik:DockCloseCommand />
                            <telerik:DockExpandCollapseCommand />
                        </Commands>
                        <TitlebarTemplate>
                            <asp:Label ID="collegeOneName" runat="server" CssClass="radBoxTitle" Text="<% = collegeNameOne %>"></asp:Label>
                        </TitlebarTemplate>
                        <ContentTemplate>
                            <asp:Panel ID="PanelOne" runat="server" style="position:absolute;left:10px;top:35px;width:98%;height:325px;border-style:solid;border-width:0px">
                               <div style="position:absolute;left:18px;top:0px;width:50%;height:75px;border-style:solid;border-width:0px">
                                    <a href="college_overview.aspx?view=college&collegeID=<% = collegeIDOne %>" >
                                        <img src="images/<% = collegeOneLogo %>" alt="<% = collegeOneLogo %>" height="<% = collegeLogoSizeOne %>" style="position:relative;top:5px"/>
                                    </a>
                                </div>
                                <div id="" style="position:absolute;right:0;top:0px;width:50%;height:75px;border-style:solid;border-width:0px">                                
                                    <asp:Label ID="districtInBox" runat="server" Text="" style="position:absolute;top:20px;font-family:Arial;font-size:14px;font-weight:bold">
                                        You have items in workflow that need your attention!&nbsp;&nbsp;&nbsp;&nbsp;
                                        <a style="font-family:Ariel;text-decoration:none;color:Red;font-size:14px;font-weight:bold" href="main.aspx?dashboard=12" >Go To Workflow</a>
                                    </asp:Label>
                                </div>
                               
                                <div style="display:block;position:absolute;top:76px;width:49%;height:147px;left:20px;border-style:solid;border-width:0px">
                                    <div style="height:30px"><img src="images/bondsite.png" alt="bondsite" style="position:relative;top:1px;margin-right:5px"/><a style="font-family:Segoe UI, Arial, sans-serif;font-size:13px;font-weight:bold;text-decoration:none" href="<% = bondSiteURL %>" target="_blank"><% = bondSiteName%></a></div>
                                       
                                    <div style="height:30px"><img src="images/schedule.png" alt="schedules" style="position:relative;top:1px;margin-right:5px"/><a style="font-family:Segoe UI, Arial, sans-serif;font-size:13px;font-weight:bold;text-decoration:none" href="GlobalSchedules.aspx?view=college&CollegeID=<% = collegeIDOne %>">District Schedules</a></div>
              
                                    <div style="height:30px"><img src="images/meetingminutes.png" alt="meetings" style="position:relative;top:2px;margin-right:5px"/><a style="font-family:Segoe UI, Arial, sans-serif;font-size:13px;font-weight:bold;text-decoration:none" href="MeetingMinutes.aspx?view=college&CollegeID=<% = collegeIDOne %>">District Meeting Minutes</a></div>
 
                                    <div style="height:30px"><img src="images/reports.png" alt="reports" height="15px" style="position:relative;top:2px;margin-right:5px"/><a style="font-family:Segoe UI, Arial, sans-serif;font-size:13px;font-weight:bold;text-decoration:none" href="reports.aspx">Reports</a></div>                               
                                </div>

                                <div style="display:block;position:absolute;top:220px;width:200px;height:100px;left:70px;border-style:solid;border-width:0px;font_family:Arial;font-size:14px;font-weight:bold">
                                This is the space for the Budget Allocation disclosure statement.
                                </div>

                               <div id="chartContainer" style="display:inline-block;position:absolute;top:76px;width:50%;right:25px;height:235px;border-style:solid;border-width:0px">
                              
                               </div>
                                                          
                            </asp:Panel>                                                                           
                        </ContentTemplate>
                    </telerik:RadDock>

                    <telerik:RadDock ID="LowerLeftBox" runat="server" Width="" Height="" Title="Title"
                        DockHandle="TitleBar" OnDockPositionChanged="RadDock1_DockPositionChanged"
                        EnableAnimation="true" AutoPostBack="false" EnableRoundedCorners="True" Resizable="true">
                        <Commands>
                            <telerik:DockCloseCommand />
                            <telerik:DockExpandCollapseCommand />
                        </Commands>
                        <TitlebarTemplate>
                            <asp:Label ID="collegeTwoName" runat="server" CssClass="radBoxTitle" Text="<% = collegeNameTwo %>"></asp:Label>
                        </TitlebarTemplate>
                        <ContentTemplate>
                        <asp:Panel ID="PanelTwo" runat="server" style="position:relative;left:0px;top:0px;width:99%;height:317px;border-style:solid;border-width:0px">

                                <div style="position:absolute;left:18px;top:0px;width:50%;height:75px;border-style:solid;border-width:0px">
                                    <a href="college_overview.aspx?view=college&collegeID=<% = collegeIDTwo %>" >
                                        <img src="images/<% = collegeTwoLogo %>" alt="<% = collegeTwoLogo %>" height="<% = collegeLogoSizeTwo %>" style="position:relative;top:5px"/>
                                    </a>                                    
                                </div>
                                <div id="collegeOneInbox" style="position:absolute;right:0;top:0px;width:50%;height:75px;border-style:solid;border-width:0px">                                
                                    
                                </div>

                                  <div style="position:absolute;left:18px;top:80px;width:50%;height:157px;border-style:solid;border-width:0px">
                                    <div style="position:absolute;width:100%;height:30px;vertical-align:middle;line-height:30px;text-align:left;font-family:Segoe UI, Arial, sans-serif;font-size:14px;font-weight:bold">Active Projects</div>
                                    <div id="insertOnexxxx" style="top:30px;position:relative;width:100%;height:130px;border-style:solid;border-width:0px"> 
                                        <asp:Label ID="insertTwo" runat="server" Text=""></asp:Label>
                                    </div>                                 
                                </div>

                                <div style="position:absolute;right:-5px;top:78px;width:50%;height:240px;border-style:solid;border-width:0px">
                                    <telerik:RadChart ID="chartTotalExpenses2" runat="server" Skin="Desert" Height="240px" Width="250px">
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
                                                    <ItemTextAppearance TextProperties-Color="0, 0, 0" TextProperties-Font="Arial, 7.25pt, style=Bold"
                                                        Dimensions-Margins="0px, 0px, 0px, 0px">
                                                    </ItemTextAppearance>
                                                    <ItemAppearance Position-AlignedPosition="Top"></ItemAppearance>
                                                    <FillStyle MainColor="238, 240, 245">
                                                    </FillStyle>
                                                    <Border Color="208, 207, 195" />
                                                </Appearance>
                                            </Legend>
                                        </telerik:RadChart> 
                                
                                </div>
                              

                         </asp:Panel>              
                        </ContentTemplate>
                    </telerik:RadDock>

                    </telerik:RadDockZone>


                    <telerik:RadDockZone ID="RightDocZone" runat="server" Orientation="Vertical" FitDocks="True" Width="49%">

                    <telerik:RadDock ID="UpperRightBox" runat="server" Width="" Height="" Title="Title"
                        DockHandle="TitleBar" OnDockPositionChanged="RadDock1_DockPositionChanged"
                        EnableAnimation="true" AutoPostBack="false" EnableRoundedCorners="True" Resizable="true">
                        <Commands>
                            <telerik:DockCloseCommand />
                            <telerik:DockExpandCollapseCommand />
                        </Commands>
                        <TitlebarTemplate>
                            <asp:Label ID="collegeThreeName" runat="server" CssClass="radBoxTitle" Text="<% = collegeNameThree %>"></asp:Label>
                        </TitlebarTemplate>
                        <ContentTemplate>
                        <asp:Panel ID="Panel3" runat="server" style="position:relative;left:0px;top:0px;width:99%;height:317px;border-style:solid;border-width:0px">

                                <div style="position:absolute;left:18px;top:0px;width:50%;height:75px;border-style:solid;border-width:0px">
                                    <a href="college_overview.aspx?view=college&collegeID=<% = collegeIDThree %>" >
                                        <img src="images/<% = collegeThreeLogo %>" alt="<% = collegeThreeLogo %>" height="<% = collegeLogoSizeThree %>" style="position:relative;top:5px"/>
                                    </a>
                                </div>
                                <div style="position:absolute;right:0;top:0px;width:50%;height:157px;border-style:solid;border-width:0px"></div>

                                <div id="upperRightDetailFour" style="position:absolute;left:18px;top:80px;width:50%;height:157px;border-style:solid;border-width:0px">
                                    <div style="position:absolute;width:100%;height:30px;vertical-align:middle;line-height:30px;text-align:left;font-family:Segoe UI, Arial, sans-serif;font-size:14px;font-weight:bold">Active Projects</div>
                                    <div id="insertTwoxxx" style="top:30px;position:relative;width:100%;height:130px;border-style:solid;border-width:0px">
                                        <asp:Label ID="insertThree" runat="server" Text="Label"></asp:Label>
                                     
                                    </div>
                                </div>

                                <div style="position:absolute;right:-5px;top:76px;width:50%;height:240px;border-style:solid;border-width:0px">
                                    <telerik:RadChart ID="chartTotalExpenses3" runat="server" Skin="Desert" Height="240px" Width="250px">
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
                                                <ItemTextAppearance TextProperties-Color="0, 0, 0" TextProperties-Font="Arial, 7.25pt, style=Bold"
                                                    Dimensions-Margins="0px, 0px, 0px, 0px">
                                                </ItemTextAppearance>
                                                <ItemAppearance Position-AlignedPosition="Top"></ItemAppearance>
                                                <FillStyle MainColor="238, 240, 245">
                                                </FillStyle>
                                                <Border Color="208, 207, 195" />
                                            </Appearance>
                                        </Legend>
                                    </telerik:RadChart>                                                                
                                </div>

                                

                         </asp:Panel>              
                        </ContentTemplate>
                    </telerik:RadDock>

                    <telerik:RadDock ID="LowerRightBox" runat="server" Width="" Height="" Title="Title"
                        DockHandle="TitleBar" OnDockPositionChanged="RadDock1_DockPositionChanged"
                        EnableAnimation="true" AutoPostBack="false" EnableRoundedCorners="True" Resizable="true">
                        <Commands>
                            <telerik:DockCloseCommand />
                            <telerik:DockExpandCollapseCommand />
                        </Commands>
                        <TitlebarTemplate>
                            <asp:Label ID="collegeFourName" runat="server" CssClass="radBoxTitle" Text="<% = collegeNameFour %>"></asp:Label>
                        </TitlebarTemplate>
                        <ContentTemplate>
                        <asp:Panel ID="Panel4" runat="server" style="position:relative;left:0px;top:0px;width:99%;height:317px;border-style:solid;border-width:0px">

                                <div style="position:absolute;left:18px;top:0px;width:50%;height:75px;border-style:solid;border-width:0px">
                                    <a href="college_overview.aspx?view=college&collegeID=<% = collegeIDFour %>" >
                                        <img src="images/<% = collegeFourLogo %>" alt="<% = collegeFourLogo %>" height="<% = collegeLogoSizeFour %>" style="position:relative;top:5px"/>
                                    </a>
                                </div>
                                <div style="position:absolute;right:0;top:0px;width:50%;height:157px;border-style:solid;border-width:0px"></div>

                                  <div style="position:absolute;left:18px;top:80px;width:50%;height:150px;border-style:solid;border-width:0px">
                                    <div style="position:absolute;width:100%;height:30px;vertical-align:middle;line-height:30px;text-align:left;font-family:Segoe UI, Arial, sans-serif;font-size:14px;font-weight:bold">Active Projects</div>
                                    <div id="insertThreexx" style="top:30px;position:relative;width:100%;height:130px;border-style:solid;border-width:0px"> 

                                        <asp:Label ID="insertFour" runat="server" Text="Label">
                                                                                    
                                        </asp:Label>
                                    </div>
                                </div>

                                <div style="position:absolute;right:-5px;top:79px;width:50%;height:240px;border-style:solid;border-width:0px">
                                    <telerik:RadChart ID="chartTotalExpenses4" runat="server" Skin="Desert" Height="240px" Width="250px">
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
                                                    <ItemTextAppearance TextProperties-Color="0, 0, 0" TextProperties-Font="Arial, 7.25pt, style=Bold"
                                                        Dimensions-Margins="0px, 0px, 0px, 0px">
                                                    </ItemTextAppearance>
                                                    <ItemAppearance Position-AlignedPosition="Top"></ItemAppearance>
                                                    <FillStyle MainColor="238, 240, 245">
                                                    </FillStyle>
                                                    <Border Color="208, 207, 195" />
                                                </Appearance>
                                            </Legend>
                                        </telerik:RadChart>
                                
                                </div>
                              

                        </asp:Panel>              
                        </ContentTemplate>
                    </telerik:RadDock>

                    </telerik:RadDockZone>


                </telerik:RadDockLayout>
                <div style="width: 0px; height: 0px; overflow: hidden; position: absolute; left: -10000px;">
                Hidden UpdatePanel, which is used to help with saving state when minimizing, moving
                and closing docks. This way the docks state is saved faster (no need to update the
                docking zones).
                <asp:UpdatePanel runat="server" ID="UpdatePanel1">
                </asp:UpdatePanel>
                </div>
            </div>
        </div>
    </form>
</body>
</html>
