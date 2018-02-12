<%@ Page Language="VB" MasterPageFile="~/content.master" Title="" %>
<%@ Register Assembly="Telerik.Web.UI" Namespace="Telerik.Web.UI" TagPrefix="telerik" %>
<%@ Import Namespace="Prompt" %>

<script runat="server">
    
    Private nContractID As Integer = 0
    Private nProjectID As Integer = 0
    Private ContractAmount As Double = 0
    Private Reimbursables As Double = 0
    Private AmmendAmount As Double = 0
    Private TransAmount As Double = 0
    Private ReimbAmt As Double = 0
    Private Balance As Double = 0
    Private TotalRetentionAmount As Double = 0
    Private TotalRetentionPaid As Double = 0
    Private TotalRetentionDue As Double = 0
    
    Private TotalAdjustments As Double = 0
    
    Private bContractReadOnly As Boolean = True

    Private CurrentBalanceDue As Double = 0
    
    Protected Sub Page_Init(ByVal sender As Object, ByVal e As System.EventArgs)
        nContractID = Request.QueryString("ContractID")    'needed here for docks
        nProjectID = Request.QueryString("ProjectID")
    End Sub
    
    Private Sub Page_Load(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MyBase.Load

        Session("PageID") = "ContractOverview"
        
        nContractID = Request.QueryString("ContractID")
        nProjectID = Request.QueryString("ProjectID")
        
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
        
        lblContractName.Text = DirectCast(Master.FindControl("lblViewTitle"), Label).Text
        
        If Session("delcontract") <> True Then    'to prevent reload on postback after deleting the record

            'get the Contract record 
            Using rs As New PromptDataHelper
                With rs
                    .CallingPage = Page
                    .FillForm(contentPanel1, "SELECT * FROM qry_ContractView WHERE ContractID =" & nContractID)
                End With
            End Using
       
	   
        
            'Look for flags
            lnkFlag.Visible = False
            Using db As New promptFlag
                db.ParentRecType = "Contract"
                db.ParentRecID = nContractID
                If db.FlagExists() Then
                    lnkFlag.Visible = True
                    lnkFlag.Attributes.Add("onclick", "openPopup('flag_edit.aspx?ParentRecID=" & nContractID & "&ParentRecType=Contract','showFlag',500,400,'yes');")
                End If
            End Using
        
        
            '**** HACK *****
            ' get the object code descrption to display
            'Dim sObjectCodeDesc As String = ""
            'Using db As New PromptDataHelper
                'Dim sql As String = "select objectcode +  ' - ' + Objectcodedescription as ObjCode from qry_objectcodes "
                'sql = sql & " where objectcode = '" & lblObjectCode.Text & "' and districtid = " & Session("DistrictID")
                'sObjectCodeDesc = db.ExecuteScalar(sql)
            
                'lblObjectCode.Text = sObjectCodeDesc
            'End Using
        
            'Check contract expire date
            If IsDate(lblExpireDate.Text) Then
                Dim dd As Date = lblExpireDate.Text
                If DateDiff(DateInterval.Day, dd, Now()) > 0 Then
                    lblExpireDate.CssClass = "AlertDataDisplay"
                End If
            End If

            lblRetentionPercent.Text = lblRetentionPercent.Text & "%"


            'Set color of status 
            If lblStatus.Text = "2-Closed" Then
                lblStatus.Text = "Closed"
                lblStatus.CssClass = "red"
            ElseIf lblStatus.Text = "3-Pending" Then
                lblStatus.Text = "Pending"
                lblStatus.CssClass = "orange"
            Else
                lblStatus.Text = "Open"
                lblStatus.CssClass = "green"
            End If

            'Calculate Summary Box 
            Dim nPendingCos as double = 0
            
            Using db As New promptContract
                db.LoadContractInfo(nContractID)
                          
                'TransAmount = db.NonReimbursableTransTotal
                ReimbAmt = db.ReimbursableTransTotal
                AmmendAmount = db.AmendTotal
                ContractAmount = db.ContractNonReimbursableTotal
                Reimbursables = db.ReimbursableAmount
                TotalRetentionAmount = db.TotalRetentionWithheld
                TotalRetentionPaid = db.TotalRetentionPaid
                TotalAdjustments = db.TotalAdjustments
            
            
                nPendingCos = db.TotalPendingChangeOrders
                lblAmendmentReimbursables.Text = FormatCurrency(db.AmendReimbursableTotal, -1, -2, -1, -2)
                
                lblNonPaidTransactions.Text = FormatCurrency(db.TotalNonPaidTransactions, -1, -2, -1, -2)
                lblPaidTransactions.Text = FormatCurrency(db.TotalPaidTransactions, -1, -2, -1, -2)

                TransAmount = db.TotalPaidTransactions + db.TotalNonPaidTransactions
                
            End Using
            
            
            
            
            TotalRetentionDue = TotalRetentionAmount - TotalRetentionPaid
            Balance = ContractAmount + AmmendAmount - TransAmount + Reimbursables + TotalAdjustments
            
           CurrentBalanceDue = Balance + (TotalRetentionAmount - TotalRetentionPaid)

            lblOriginalContractAmount.Text = FormatCurrency(ContractAmount, -1, -2, -1, -2)
            lblTotalApprovedAmendments.Text = FormatCurrency(AmmendAmount, -1, -2, -1, -2)
            lblTotalPendingAmendments.Text = FormatCurrency(nPendingCos, -1, -2, -1, -2)
            
            lblRevisedNonReimbContractTotal.Text = FormatCurrency(ContractAmount + AmmendAmount + nPendingCos, -1, -2, -1, -2)
            
            lblTotalAmendments.Text = FormatCurrency(AmmendAmount + nPendingCos, -1, -2, -1, -2)
            
            lblTotalAdjustments.Text = FormatCurrency(TotalAdjustments, -1, -2, -1, -2)
             
             
            
            lblRevisedContractTotal.Text = FormatCurrency(ContractAmount + AmmendAmount + Reimbursables + nPendingCos, -1, -2, -1, -2)
            lblOrigReimbursables.Text = FormatCurrency(Reimbursables, -1, -2, -1, -2)
            lblTotalTransactions.Text = FormatCurrency(TransAmount, -1, -2, -1, -2)
            lblTotalReimbursables.Text = FormatCurrency(ReimbAmt, -1, -2, -1, -2)
            lblBalanceRemaining.Text = FormatCurrency(Balance, -1, -2, -1, -2)
            lblRetentionDue.Text = FormatCurrency(TotalRetentionDue, -1, -2, -1, -2)
            lblCurrentBalanceDue.Text = FormatCurrency(CurrentBalanceDue, -1, -2, -1, -2)
            
            
            '*********************************************** set up report quick links

            Dim nContractorID As Integer = lblContractorID.Value   'NOTE: this is hidden field on the form only to retrive value
           

            SetSecurity()
        
        Else
            Session("delcontract") = False    'we just deleted a contract so needed to load page, then redirect to parent project
        End If
        
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
        
        BuildMenu
        
   
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
        
            but = New RadMenuItem
            With but
                .Text = "Printer friendly page"
                .ImageUrl = "images/printer.png"
                .Attributes("onclick") = "return printSelection(document.getElementById('printdiv'));return false"
                .ToolTip = "Show Printer Friendly Page."
                .PostBack = False
            End With
            RadMenu1.Items.Add(but)
            
            Dim butDropDown As New RadMenuItem
            Dim butSub As New RadMenuItem
            Dim butSub2 As New RadMenuItem
            Dim butSub3 As New RadMenuItem
            
            butDropDown = New RadMenuItem
            With butDropDown
                .Text = "Print"
                .ImageUrl = "images/printer.png"
                .PostBack = False
            End With

            Dim projNum As String
            Using db As New PromptDataHelper
                projNum = db.ExecuteScalar("Select ProjectNumber + Coalesce(ProjectSubNumber,'') From Projects Where ProjectID = " & nProjectID)
            End Using 'db
            With butSub
                .Text = "Budget Cost Report"
                .ImageUrl = "images/printer.png"
                .Target = "_new"
                .NavigateUrl = "report_viewer.aspx?DirectCall=y&ReportID=172&G_Projects=" & projNum
                .PostBack = False
            End With
            butDropDown.Items.Add(butSub)

            With butSub2
                .Text = "Contract Summary"
                .ImageUrl = "images/printer.png"
                .Target = "_new"
                .NavigateUrl = "report_viewer.aspx?DirectCall=y&ReportID=3&Proj=" & nProjectID & "&Contracts=" & nContractID
                .PostBack = False
            End With
            butDropDown.Items.Add(butSub2)

            With butSub3
                .Text = "Contract Detail"
                .ImageUrl = "images/printer.png"
                .Target = "_new"
                .NavigateUrl = "report_viewer.aspx?DirectCall=y&ReportID=182&ContractID=" & nContractID 
                .PostBack = False
            End With
            butDropDown.Items.Add(butSub3)

            RadMenu1.Items.Add(butDropDown)
            
        End If
 

    End Sub

    Private Sub SetSecurity()
        'Sets the security constraints for current page
        Using db As New EISSecurity
            db.ProjectID = Request.QueryString("ProjectID")
            
            If db.FindUserPermission("ContractOverview", "Write") Then
                bContractReadOnly = False
                Dim dcmd As New DockCommand
                With dcmd
                    .Name = "ContractEdit"
                    .Text = "Edit this Contract"       'this is the tooltip
                    .OnClientCommand = "EditContract"
                    .CssClass = "widgeteditbtn"
                    .AutoPostBack = "false"
                    
                End With
                dockContractOverview.Commands.Add(dcmd)
            End If
            
            If db.FindUserPermission("ContractNotesWidget", "write") Then
                With lnkNewNote
                    .Visible = True
                    .Attributes("onclick") = "return EditNote(0," & nContractID & ");"
                End With
            Else
                lnkNewNote.Visible = False
            End If
            
            If db.FindUserPermission("ContractNotesWidget", "read") Then
                dockNotes.Visible = True
            Else
                dockNotes.Visible = False
            End If
            
            'trump any widget settings if district is turned off
            Dim tbl As DataTable = db.GetDistrictObjectVisibilitySettings("ContractWidget")
            For Each row In tbl.Rows
                Select Case row("ObjectID")
                    Case "ContractNotesWidget"
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
            radgridNotesWidget.DataSource = db.GetNotes("ContractID", nContractID)
        End Using

    End Sub

    Protected Sub radgridNotesWidget_ItemCreated(ByVal sender As Object, ByVal e As Telerik.Web.UI.GridItemEventArgs) Handles radgridNotesWidget.ItemCreated

        'This event allows us to customize the cell contents - fired before databound

        If (TypeOf e.Item Is GridDataItem) Then
            Dim item As GridDataItem = CType(e.Item, GridDataItem)
            Dim nNoteID As Integer = item.OwnerTableView.DataKeyValues(item.ItemIndex)("NoteID")

            'update the link button to open report window
            Dim linkButton As HyperLink = CType(item("CreatedOn").Controls(0), HyperLink)
            linkButton.Attributes("onclick") = "return EditNote(" & nNoteID & "," & nContractID & ");"
            linkButton.ToolTip = "Edit selected Note."
            linkButton.NavigateUrl = "#"
            
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
            db.SaveDockState(dockState, "ContractOverviewDockSettings", "ContractID", nContractID)
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
            db.SaveDockState(dockState, "ContractOverviewDockSettings", "ContractID", nContractID)
        End Using
    End Sub
    
    Protected Sub RadDockLayout1_LoadDockLayout(ByVal sender As Object, ByVal e As Telerik.Web.UI.DockLayoutEventArgs)

        Dim serializer As New Script.Serialization.JavaScriptSerializer()
        'Get saved state string from the database - set it to dockState variable for example  
        Dim dockstate As String = ""
        Using db As New promptUserPrefs
            dockstate = db.GetDockState("ContractOverviewDockSettings", "ContractID", nContractID)
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
        dockContractOverview.Height = Unit.Pixel(325)
        CreateSaveStateTrigger(dockContractOverview)
        
        dockBudgetOverview.Height = Unit.Pixel(360)
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
    <telerik:radwindowmanager id="contentPopups" runat="server">
    </telerik:radwindowmanager>
    <div id="contentwrapper">
        <telerik:radmenu id="RadMenu1" runat="server" style="z-index: 10;" />
         <div id="contentcolumn">
            <div id="printdiv" class="innertube"><span class="hdprint">Contract: <asp:Label ID="lblContractName" runat="server"></asp:Label></span>
                <telerik:raddocklayout id="RadDockLayout1" runat="server" enableembeddedskins="false"
                    skin="Prompt" onsavedocklayout="RadDockLayout1_SaveDockLayout" onloaddocklayout="RadDockLayout1_LoadDockLayout">
                    <telerik:RadDockZone ID="raddockLeft" runat="server" Orientation="Vertical" FitDocks="false"
                        CssClass="raddockzone">
                        <telerik:RadDock ID="dockContractOverview" Title="Project Overview" runat="server"
                            Width="" Height="400px" DockHandle="TitleBar" DockMode="Docked" DefaultCommands="ExpandCollapse"
                            EnableRoundedCorners="True" OnDockPositionChanged="RadDock1_DockPositionChanged"
                            EnableAnimation="true" AutoPostBack="true">
                            <Commands>
                                <telerik:DockExpandCollapseCommand />
                            </Commands>
                            <TitlebarTemplate>
                                <asp:Label ID="Label1" runat="server" CssClass="widgetcontractoverviewtitle">Contract Overview</asp:Label>
                            </TitlebarTemplate>
                            <ContentTemplate>
                                <asp:Panel ID="contentPanel1" runat="server">
                                    <table cellpadding="3" cellspacing="0" width="100%" class="project_ov">
   
                                        <tr class="alt">
                                            <td>
                                                Company:
                                            </td>
                                            <td >
                                                <asp:HyperLink ID="lblContractorName" runat="server"></asp:HyperLink>&nbsp;&nbsp;&nbsp;&nbsp;
                                                <asp:HyperLink ID="lnkFlag" runat="server" Visible="True" NavigateUrl="#" ImageUrl="images/alert.gif"></asp:HyperLink>
                                            </td>
                                        </tr>
                                        <tr >
                                            <td>
                                                Contract Date:
                                            </td>
                                            <td >
                                                <asp:Label ID="lblContractDate" runat="server"></asp:Label>&nbsp;
                                            </td>
                                        </tr>
                                       <tr class="alt">
                                            <td>
                                                Description:
                                            </td>
                                            <td >
                                                <asp:Label ID="lblDescription" runat="server"></asp:Label>&nbsp;
                                            </td>
                                        </tr>
                                        
                                        <tr>
                                            <td>
                                                Expires:
                                            </td>
                                            <td >
                                                <asp:Label ID="lblExpireDate" runat="server"></asp:Label>&nbsp;
                                            </td>
                                        </tr>
                                        <tr class="alt">
                                            <td>
                                                Status:
                                            </td>
                                            <td >
                                                <asp:Label ID="lblStatus" runat="server"></asp:Label>&nbsp;
                                            </td>
                                        </tr>
                                        <tr>
                                            <td>
                                                P.O. Number:
                                            </td>
                                            <td>
                                                <asp:Label ID="lblBlanketPONumber" runat="server"></asp:Label>&nbsp;
                                            </td>
                                        </tr>
                                     
                                        <tr>
                                            <td>
                                                Bid Pack #:
                                            </td>
                                           <td>
                                                <asp:Label ID="lblBidPackNumber" runat="server"></asp:Label>&nbsp;
                                            </td>
                                        </tr>
                                        <tr class="alt">
                                            <td>
                                                Signed Copy Rec'd:
                                            </td>
                                           <td >
                                                <asp:Label ID="lblSignedCopyReceived" runat="server"></asp:Label>&nbsp;
                                            </td>
                                        </tr>
                                        <tr>
                                            <td>
                                                Retention %:
                                            </td>
                                            <td >
                                                <asp:HyperLink ID="lblRetentionPercent" runat="server"></asp:HyperLink>&nbsp;
                                            </td>
                                        </tr>
                                        <tr class="alt">
                                            <td>
                                                Pay Status:
                                            </td>
                                            <td >
                                                <asp:Label ID="lblPayStatus" runat="server"></asp:Label>&nbsp;
                                            </td>
                                        </tr>
                                        <tr>
                                            <td>
                                                Type:
                                            </td>
                                            <td >
                                                <asp:Label ID="lblContractType" runat="server"></asp:Label>&nbsp;
                                            </td>
                                        </tr>
                                        <tr class="alt">
                                            <td>
                                                Ret. Escrow Agnt:
                                            </td>
                                            <td>
                                                <asp:Label ID="lblRetentionEscrowAgent" runat="server"></asp:Label>&nbsp;
                                            </td>
                                        </tr>
                                    </table>
                                   <div class="id_display">ID:<asp:Label ID="lblContractID" runat="server"></asp:Label></div>
                                </asp:Panel>
                            </ContentTemplate>
                        </telerik:RadDock>
                    </telerik:RadDockZone>
                    <telerik:RadDockZone ID="raddockRight" runat="server" Orientation="Vertical" FitDocks="False"
                        CssClass="raddockzone">
                        <telerik:RadDock ID="dockBudgetOverview" runat="server" Width="" Height="375px" DockHandle="TitleBar"
                            DockMode="Docked" DefaultCommands="ExpandCollapse" EnableRoundedCorners="True"
                            OnDockPositionChanged="RadDock1_DockPositionChanged" EnableAnimation="true" AutoPostBack="true"
                            Resizable="false" Title="Budget Overview" EnableEmbeddedSkins="false" Skin="Prompt">
                            <TitlebarTemplate>
                                <asp:Label ID="Label3" runat="server" CssClass="widgetbudgetoverviewtitle">Budget Overview</asp:Label>
                            </TitlebarTemplate>
                            <ContentTemplate>
                                <table cellpadding="3" cellspacing="0" width="100%" class="project_ov">
  
                                        <tr>
                                            <td>
                                                Original Contract:
                                            </td>
                                              <td align="right">
                                                <asp:Label ID="lblOriginalContractAmount" runat="server"></asp:Label>
                                            </td>
                                        </tr>
                                       <tr class="alt">
                                            <td>
                                                Contract Reimbursables:
                                            </td>
                                              <td align="right">
                                                <asp:Label ID="lblOrigReimbursables" runat="server"></asp:Label>
                                            </td>
                                        </tr>
                                        
                                       
                                        
                                        
                                        <tr >
                                            <td>
                                                Approved Amendments/CO's:
                                            </td>
                                              <td align="right">
                                                <asp:HyperLink ID="lblTotalApprovedAmendments" runat="server"></asp:HyperLink>
                                            </td>
                                        </tr>
                                          <tr >
                                            <td>
                                                Pending Amendments/CO's:
                                            </td>
                                              <td align="right">
                                                <asp:HyperLink ID="lblTotalPendingAmendments" runat="server"></asp:HyperLink>
                                            </td>
                                        </tr>
                                        
                                        
                                                                                 <tr >
                                            <td>
                                                Amendment Reimbursables:
                                            </td>
                                              <td align="right">
                                                <asp:HyperLink ID="lblAmendmentReimbursables" runat="server"></asp:HyperLink>
                                            </td>
                                        </tr>
                                        
                                        
                                        
                                        
                                                                               <tr >
                                            <td>
                                                Total Amendments/CO's:
                                            </td>
                                             <td align="right">
                                                <asp:HyperLink ID="lblTotalAmendments" runat="server"></asp:HyperLink>
                                            </td>
                                        </tr>
                                        
                                         <tr class="alt">
                                            <td>
                                                Total Non-Reimbursable Revised Contract Amt:
                                            </td>
                                              <td align="right">
                                                <asp:Label ID="lblRevisedNonReimbContractTotal" runat="server"></asp:Label>
                                            </td>
                                        </tr>
                                        
                                        <tr class="alt">
                                            <td>
                                                Grand Total Revised Contract Amt:
                                            </td>
                                              <td align="right">
                                                <asp:Label ID="lblRevisedContractTotal" runat="server"></asp:Label>
                                            </td>
                                        </tr>
                                        
                                        <tr >
                                            <td>
                                                Total Adjustments:
                                            </td>
                                              <td align="right">
                                                <asp:Label ID="lblTotalAdjustments" runat="server"></asp:Label>
                                            </td>
                                        </tr>
                                        
                                         <tr class="alt">
                                            <td>
                                                Total Paid Transactions (incl. Reimbursables):
                                            </td>
                                             <td align="right">
                                                <asp:HyperLink ID="lblPaidTransactions" runat="server"></asp:HyperLink>
                                            </td>
                                        </tr>
                                        
                                         <tr>
                                            <td>
                                                Total Non-Paid Transactions:
                                            </td>
                                              <td align="right">
                                                <asp:HyperLink ID="lblNonPaidTransactions" runat="server"></asp:HyperLink>
                                            </td>
                                        </tr>
  
                                         <tr class="alt">
                                            <td>
                                                Total Transactions (incl. Reimbursables):
                                            </td>
                                              <td align="right">
                                                <asp:HyperLink ID="lblTotalTransactions" runat="server"></asp:HyperLink>
                                            </td>
                                        </tr>
                                        <tr >
                                            <td>
                                                Total Reimbursable Transactions:
                                            </td>
                                             <td align="right">
                                                <asp:HyperLink ID="lblTotalReimbursables" runat="server"></asp:HyperLink>
                                            </td>
                                        </tr>
                                         <tr class="alt">
                                            <td>
                                                Contract Balance Remaining:
                                            </td>
                                             <td align="right">
                                                <asp:HyperLink ID="lblBalanceRemaining" runat="server"></asp:HyperLink>
                                            </td>
                                        </tr>
                                        <tr>
                                            <td>
                                                Retention Due:
                                            </td>
                                              <td align="right">
                                                <asp:Label ID="lblRetentionDue" runat="server"></asp:Label>
                                            </td>
                                        </tr>
                                         <tr class="alt">
                                            <td>
                                                Bal Due (Incl. Unpaid Reten):
                                            </td>
                                              <td align="right">
                                                <asp:Label ID="lblCurrentBalanceDue" runat="server"></asp:Label>
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
                    </telerik:RadDockZone>
                </telerik:raddocklayout>
                <asp:HiddenField ID="lblContractorID" runat="server" Value="0" />
                <div style="width: 0px; height: 0px; overflow: hidden; position: absolute; left: -10000px;">
                    Hidden UpdatePanel, which is used to help with saving state when minimizing, moving
                    and closing docks. This way the docks state is saved faster (no need to update the
                    docking zones).
                    <asp:UpdatePanel runat="server" ID="UpdatePanel1">
                    </asp:UpdatePanel>
                </div>
                <telerik:radajaxmanager id="RadAjaxManager1" runat="server">
                    <AjaxSettings>
                        <telerik:AjaxSetting AjaxControlID="radgridNotesWidget">
                            <UpdatedControls>
                                <telerik:AjaxUpdatedControl ControlID="radgridNotesWidget" LoadingPanelID="RadAjaxLoadingPanel1" />
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

                        var projid = '<%=nProjectID%>';    // set projid for global
                        var contractid = '<%=nContractID%>';    // set projid for global

                        function EditContract() {
                            openPopup('contract_edit.aspx?ProjectID=' + projid + '&ContractID=' + contractid, 'editContract', 650, 550, 'yes');

                        }

                        function EditNote(id, parentkey) {

                            var oWnd = window.radopen("note_edit.aspx?NoteID=" + id + "&CurrentView=contract&KeyValue=" + parentkey + "&WinType=RAD", "EditNoteWindow");
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
            </div>
        </div>
    </div>
</asp:Content>
