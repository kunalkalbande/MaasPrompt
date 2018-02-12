<%@ Page Language="VB" MasterPageFile="~/content.master" Title="" %>
<%@ Register Assembly="Telerik.Web.UI" Namespace="Telerik.Web.UI" TagPrefix="telerik" %>
<%@ Import Namespace="Prompt" %>

<script runat="server">
    
    Private bReadOnly As Boolean = True
    Private nProjectID As Integer = 0
    Private bHideAnswered As Boolean = False
    Private nContractID As Integer = 0
    Private isPMtheCM As Boolean
    
   
    Protected Sub Page_PreRender(ByVal sender As Object, ByVal e As System.EventArgs)
        Using db As New promptUserPrefs
            db.SaveGridSettings(RadGrid1, "RFIGridSettings", "ProjectID", nProjectID)
        End Using
    End Sub

    Protected Sub Page_Init(ByVal sender As Object, ByVal e As System.EventArgs)
        nProjectID = Request.QueryString("ProjectID")
        'set security
        Using dbsec As New EISSecurity
            dbsec.ProjectID = nProjectID
            If dbsec.FindUserPermission("RFILog", "write") Then
                bReadOnly = False
            Else
                bReadOnly = True
            End If
        End Using
        
        'bReadOnly = False ' Temp allow to create RFI
        
        If Not IsPostBack Then
            Using db As New promptUserPrefs
                'db.LoadGridSettings(RadGrid1, "RFIGridSettings", "ProjectID", nProjectID)
                'db.LoadGridColumnVisibility(RadGrid1, "RFIGridColumns", "ProjectID", nProjectID)
            End Using
        End If

    End Sub
    
    Private Sub Page_Load(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MyBase.Load

        ProcLib.CheckSession(Page)
        ProcLib.LoadPopupJscript(Page)
        
        If Not IsPostBack Then
            Session("HideClosed") = "Closed"
        End If

        ''set up help button
        Session("PageID") = "RFIs"
        nProjectID = Request.QueryString("ProjectID")
        
        Using db As New RFI
            Dim thObj As Object = db.getCM(nProjectID, 0)
            If thObj(0) = 0 Then isPMtheCM = True Else isPMtheCM = False ' gives pm cm privilages if no cm specified 
            Try
                Session("ContactID") = db.getContactID(Session("UserID"), Session("DistrictID"))
                contactID.Value = Session("ContactID")
                Dim contactData As Object = db.getContactData(Session("ContactID"), Session("DistrictID"))
                'parentID = contactData(0)
                'Session("ParentContactID") = parentID
                'contactType = contactData(1)
                Session("ContactType") = Trim(contactData(1))
                'companyName = contactData(2)
                'Dim Obj As Object = db.getTeamContactData(Session("DistrictID"), Session("ContactID"), nProjectID)
                'Session("ContactType") = Obj(1)
                'If Session("ContactType") = "Project Manager" Then Session("ContactType") = "ProjectManger"
                
                testPlace.value = Session("ContactID") & " - " & Session("DistrictID")
            Catch ex As Exception
            End Try
        End Using
             
        
        
        Dim masterTabs As RadTabStrip = Master.FindControl("tabMain")
        Dim masterViewTitle As Label = Master.FindControl("lblViewTitle")
        
        If Session("RtnFromEdit") <> True Then
            Session("ContractID") = Nothing
        ElseIf Session("RtnFromEdit") = True Then
            nContractID = Session("ContractID")
            Session("RtnFromEdit") = Nothing                        
        End If
        
        Session("CurrentTab") = "RFIs"
        For Each radTab In masterTabs.GetAllTabs
            If radTab.Value = "RFIs" Then
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

            .Height = Unit.Pixel(600)

            .ExportSettings.FileName = "PromptRFIExport"
            .ExportSettings.OpenInNewWindow = True
            .ExportSettings.Pdf.PageTitle = masterViewTitle.Text & " RFIs"
        End With
        
        With RadGrid1.MasterTableView.DetailTables
            
        End With
        
        BuildMenu()

        With contentPopup
            .VisibleOnPageLoad = False
            .Skin = "Windows7"
                         
            Dim ww As New RadWindow

            ww = New RadWindow
            With ww
                .ID = "NewWindow"
                '.NavigateUrl = "#"
                
                .Title = ""
                .Width = 580
                .Height = 600
                .Modal = True
                .VisibleStatusbar = False
                .ReloadOnShow = True
                .Behaviors = WindowBehaviors.Close + WindowBehaviors.Move
            End With
            .Windows.Add(ww)
            
            ww = New RadWindow
            With ww
                .ID = "EditWindow"
                '.NavigateUrl = "#"

                .Title = ""
                .Width = 900
                .Height = 600
                .Modal = True
                '.MaxHeight = 300
                .VisibleStatusbar = False
                .ReloadOnShow = True
                .Behaviors = WindowBehaviors.Close + WindowBehaviors.Move
                '.Behaviors = WindowBehaviors.Move
                .OnClientClose = "onThisClientClose"
            End With
            .Windows.Add(ww)
            
            ww = New RadWindow
            With ww
                .ID = "AttachmentsWindow"
                .NavigateUrl = "#"
                .Title = ""
                .Width = 500
                .Height = 350
                .Modal = True
                .VisibleStatusbar = False
                .ReloadOnShow = True
                .Behaviors = WindowBehaviors.Close + WindowBehaviors.Move
            End With
            .Windows.Add(ww)
        End With

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
            
            'build buttons
            Dim but As RadMenuItem
                
            but = New RadMenuItem
            With but
                .Text = "Add New RFI"
                .ImageUrl = "images/add.png"
                .Attributes("onclick") = "return EditRFI('0'," & nProjectID & ",'0','New');"
                .ToolTip = "Add a New RFI."
                .PostBack = False
                If bReadOnly Then
                    .Visible = False
                Else
                    .Visible = True
                End If
            End With
            RadMenu1.Items.Add(but)

            Dim butDropDown As New RadMenuItem
            With butDropDown
                .Text = "Export"
                .ImageUrl = "images/data_down.png"
                .PostBack = False
                .Visible = False
            End With
            
            'Add sub items
            Dim butSub As New RadMenuItem
            With butSub
                .Text = "Export To Excel"
                .Value = "ExportExcel"
                .Attributes("CancelAjax") = "Y"   'NOTE: This is needed to cancel ajax call and do regular postback as grid export to pdf/execl does not work with ajax
                .ImageUrl = "images/excel.gif"
                .PostBack = True
                .Visible = False
            End With
            butDropDown.Items.Add(butSub)
            
            butSub = New RadMenuItem
            With butSub
                .Text = "Export To PDF"
                .Value = "ExportPDF"
                .Attributes("CancelAjax") = "Y"   'NOTE: This is needed to cancel ajax call and do regular postback as grid export to pdf/execl does not work with ajax
                .ImageUrl = "images/prompt_pdf.gif"
                .PostBack = True
                .Visible = False
            End With
            butDropDown.Items.Add(butSub)
            RadMenu1.Items.Add(butDropDown)
 
            but = New RadMenuItem
            With but
                .Text = "Print To Download"
                .Value = "LogPrint"
                .ImageUrl = "images/printer.png"
                .PostBack = True
                .ToolTip = "Print the RFI log file to download"
                .Visible = False
                '.Attributes("onclick") = "return PrintRFILog();"
            End With
            RadMenu1.Items.Add(but)
            
            but = New RadMenuItem
            With but
                .Text = "Print Setup"
                .ImageUrl = "images/printer.png"
                .Attributes("onclick") = "return OpenPrintSetup(" & nProjectID & ");"
                .ToolTip = "Print the RFI log file to download."
                .PostBack = False
                .Visible = True
            End With
            'RadMenu1.Items.Add(but)
            'but = New RadMenuItem
            'but.IsSeparator = True
            
            butSub = New RadMenuItem
            With butSub
                .Text = "RFI Log Report"
                .ImageUrl = "images/printer.png"
                .Target = "_new"
                .NavigateUrl = Request.Url.GetLeftPart(UriPartial.Authority) & "/report_viewer.aspx?ReportID=4243&ProjectID=" & nProjectID
                .PostBack = False
            End With
            RadMenu1.Items.Add(butSub)
            
            but = New RadMenuItem
            but.IsSeparator = True
            
            but = New RadMenuItem
            With but
                .Text = "Hide Closed"
                .Value = "HideAnswered"
                .ImageUrl = "images/funnel.png"
                .Attributes("Filter") = "On"
                .Visible = True
            End With
            RadMenu1.Items.Add(but)
 
               
            but = New RadMenuItem
            but.IsSeparator = True
            RadMenu1.Items.Add(but)
            
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

    End Sub
    
    Public Sub PrintRFILog()
      
        Using db As New OpenXML
            Dim dwnData As String = db.LogPrint(nProjectID)
            
            Dim targetFile As New System.IO.FileInfo(dwnData)
            
            Response.Clear()
            Response.AddHeader("content-Disposition", "attachment; filename=" & targetFile.Name)
            Response.AddHeader("Content-Length", targetFile.Length.ToString())
            Response.ContentType = "application/octet-stream"
            Response.WriteFile(targetFile.FullName)
            Response.End()
            
        End Using
     
    End Sub
    
    Public Sub downloadFile(ByVal newFile As String)
            
        Dim targetFile As New System.IO.FileInfo(newFile)
            
        Response.Clear()
        'Response.AddHeader("content-Disposition", "attachment; filename=" & targetFile.Name)
        'Response.AddHeader("Content-Length", targetFile.Length.ToString())
        'Response.ContentType = "application/octet-stream"
        'Response.WriteFile(targetFile.FullName)
        Response.End()
            
    End Sub
    
    Protected Sub RadGrid1_NeedDataSource(ByVal source As Object, ByVal e As Telerik.Web.UI.GridNeedDataSourceEventArgs) Handles RadGrid1.NeedDataSource
        
        Using db As New RFI
            'RadGrid1.DataSource = db.GetAllProjectRFIs(nProjectID, bHideAnswered)
            RadGrid1.DataSource = db.getAllProjectRFIs(nProjectID, Session("ContactID"), Session("ContactType"), Session("HideClosed"))
        End Using
        
    End Sub
    
    'No longer needed as there is no child table in the grid.
    Protected Sub RadGrid1_DetailTableDataBind(ByVal source As Object, ByVal e As GridDetailTableDataBindEventArgs) Handles RadGrid1.DetailTableDataBind
        'Dim parentItem As GridDataItem = CType(e.DetailTableView.ParentItem, GridDataItem)
        
        'Using db As New RFI
        'e.DetailTableView.DataSource = db.getAllContractRFIs(parentItem("contractid").Text, Session("ContactType"), Session("ContactID"), Session("HideClosed"))
        'End Using
        
    End Sub
      
    Protected Sub RadGrid1_ItemCreated(ByVal sender As Object, ByVal e As Telerik.Web.UI.GridItemEventArgs) Handles RadGrid1.ItemCreated
       
        If nContractID <> 0 Then
            For Each dataitem As GridDataItem In RadGrid1.MasterTableView.Items
                'If dataitem("ContractID").Text = nContractID Then
                'dataitem.Expanded = True
                'End If
            Next
        End If
        
        If (TypeOf e.Item Is GridDataItem) Then
           
            Dim item As GridDataItem = CType(e.Item, GridDataItem)
            Dim nRFIID As Integer = item.GetDataKeyValue("RFIID")
            
            Dim sRFIRef As String = item.OwnerTableView.DataKeyValues(item.ItemIndex)("RefNumber")
            Dim nContractID As Integer = item.OwnerTableView.DataKeyValues(item.ItemIndex)("ContractID")
            Dim LinkButton As HyperLink
            
            'If bReadOnly Then
            If 1 = 2 Then
                'item("RefNumber").Controls.Clear()
                'item("RefNumber").Text = nRFIID.ToString
            Else
                Try
                    LinkButton = CType(item("RefNumber").Controls(0), HyperLink)
                    LinkButton.Text = nRFIID.ToString
                    LinkButton.Attributes("onclick") = "return EditRFI(" & nRFIID & "," & nProjectID & "," & nContractID & ",'Edit');"
                    LinkButton.NavigateUrl = "#"
                    LinkButton.ToolTip = "Edit this RFI."
                Catch
                End Try
            End If
            
            'Added by Scott 2/13/2014
            'Check for flag and show flag icon if present
            Dim strFlagLink As String = ""
            Dim isFlag = ""
            Dim strFlagParms As String = "Flag:" & nProjectID & ":" & ""    'concatonate the popup type, projectID and field name to use for hover window parm
            Using db As New promptFlag
                db.ParentRecID = nRFIID     'projectID
                db.ParentRecType = "RFI"
                db.BudgetItemField = ""
                If db.FlagExists Then
                    isFlag = "true"
                Else
                    strFlagLink = ""
                End If
                
            End Using
            
            'Added by Scott 2/13/2014
            If isFlag = "true" Then
                Dim zImg As String
                If Request.QueryString("t") = "y" Then
                    zImg = "images/alert.gif"
                Else
                    zImg = "images/flag.gif"
                End If
                zImg = "images/flag.gif"
                Try
                    LinkButton = CType(item("Flag").Controls(0), HyperLink)
                    LinkButton.Attributes("onclick") = "openPopup('PM_flag_edit.aspx?ParentRecID=" & nRFIID & "&ParentRecType=RFI&BudgetItem=" & "" & "&RFIID=" & nRFIID & "','pophelp',550,450,'yes');"
                    LinkButton.NavigateUrl = "#"
                    LinkButton.ImageUrl = zImg
                    'LinkButton.ImageUrl = "images/alert.gif"
                    '.ToolTip = "Edit this RFI."
                Catch
                End Try
            End If
                                    
            Dim sQuestionAttachments As String = Nothing
            Try
                sQuestionAttachments = ProcLib.CheckNullDBField(item.OwnerTableView.DataKeyValues(item.ItemIndex)("QuestionAttachments"))
            Catch
            End Try
            
            'update the link button to open attachments/notes window
            Try
                LinkButton = CType(item("QuestionAttachments").Controls(0), HyperLink)
                LinkButton.ToolTip = "Upload Question Attachments."
                LinkButton.NavigateUrl = "#"
                LinkButton.ImageUrl = "images/add.png"
            
                LinkButton.Attributes("onclick") = "return ManageQuestionAttachments('" & nRFIID & "','" & nProjectID & "');"
                
                If sQuestionAttachments = "Y" Then    'add link for each file
                    LinkButton.ImageUrl = "images/paper_clip_small.gif"
                End If
            Catch
            End Try
            
        End If

    End Sub
 
    Private Sub RadGrid1_ItemDataBound(ByVal sender As Object, ByVal e As Telerik.Web.UI.GridItemEventArgs) Handles RadGrid1.ItemDataBound
        If (TypeOf e.Item Is GridDataItem) Then
            Dim dataItem As GridDataItem = CType(e.Item, GridDataItem)
            Dim dRequiredBy As String = ProcLib.CheckNullDBField(dataItem.OwnerTableView.DataKeyValues(dataItem.ItemIndex)("sRequiredBy"))
            Dim dReturnedOn As String = ProcLib.CheckNullDBField(dataItem.OwnerTableView.DataKeyValues(dataItem.ItemIndex)("ReturnedOn"))
            Dim sStatus As String = ProcLib.CheckNullDBField(dataItem.OwnerTableView.DataKeyValues(dataItem.ItemIndex)("Status"))
            Dim wfPosition As String = ProcLib.CheckNullDBField(dataItem.OwnerTableView.DataKeyValues(dataItem.ItemIndex)("WFPosition"))
            Dim sNewWorkflow As String = ProcLib.CheckNullDBField(dataItem.OwnerTableView.DataKeyValues(dataItem.ItemIndex)("NewWorkflow"))
            Dim sPMNewWorkFlow As String = ProcLib.CheckNullDBField(dataItem.OwnerTableView.DataKeyValues(dataItem.ItemIndex)("PMNewWorkFlow"))
            Dim dDate As Date
            
            dataItem.CssClass = "rfi_unassigned" 'Style for all lines
            
            If sStatus = "Unassigned" Or sStatus = "Active" Then          
                dataItem.Item("sRequiredBy").CssClass = "rfi_pending"
                
                If sStatus = "Unassigned" Then
                    dataItem.Item("sRequiredBy").CssClass = "rfi_pending"
                End If
                'dDate = Date.ParseExact(dRequiredBy, "dd/MM/yyy", System.Globalization.DateTimeFormatInfo.InvariantInfo)
                If dRequiredBy <> "" Then
                    dDate = DateTime.Parse(dRequiredBy)
                End If
                    
                If Trim(wfPosition) = "None" Or Trim(sStatus) = "Unassigned" Then
                    dataItem.Item("sRequiredBy").CssClass = "rfi_unassigned"
                    dataItem.Font.Bold = False
                End If
                
                If IsDate(dDate) Then
                    If dDate = DateAdd(DateInterval.Day, 1, Date.Today) Or dDate = DateAdd(DateInterval.Day, 2, Date.Today) Then
                        dataItem.Item("sRequiredBy").CssClass = "rfi_warning"
                    ElseIf CDate(dDate) < CDate(Now()) Then
                        dataItem.Item("sRequiredBy").CssClass = "rfi_overdue"
                    End If
                End If
            ElseIf sStatus = "Answered" Or sStatus = "Closed" Then
                dataItem.Font.Bold = False
                dataItem.Item("sRequiredBy").CssClass = "rfi_answered"
            End If
            
            Select Case Trim(wfPosition)
                Case "CM:Distribution Pending", "CM:Acceptance Pending", "CM:Review Pending", "CM:Completion Pending"
                    If isPMtheCM = True And Session("ContactType") = "ProjectManager" And Trim(sNewWorkflow) = "True" Then
                        If Session("ContactType") <> "District" Then
                            dataItem.CssClass = "NewWorkflow"
                            dataItem.Font.Bold = True
                        End If
                    End If
                Case Else
            End Select
            
            If Trim(sPMNewWorkFlow) = "True" Then
                If Session("ContactType") <> "District" Then
                    dataItem.CssClass = "NewWorkflow"
                    dataItem.Font.Bold = True
                End If
            End If
           
            Try
                Using db As New RFI
                    dataItem("Answer").ToolTip = db.getAllRFIAnswers(dataItem("RFIID").Text, "Prompt", 0)
                End Using
              
                Using db As New RFI
                    dataItem("Question").ToolTip = db.buildRFIQAndAJavaScript(dataItem("RFIID").Text, Session("ContactType"))
                End Using
                   
                If Len(dataItem("Question").Text) > 55 Then
                    dataItem("Question").Text = Left((dataItem("Question").Text).Replace("~", "'"), 55) & "..."
                Else
                    dataItem("Question").Text = Left((dataItem("Question").Text).Replace("~", "'"), 55) & "..."
                End If
                
                If Len(dataItem("Answer").Text) > 55 Then
                    'dataItem("Answer").Text = Left(dataItem("Answer").Text, 55) & "..."
                End If
            
                If Len(dataItem("Question").Text) > 55 Then
                    'dataItem("Question").Text = Left(dataItem("Question").Text, 55) & "..."
                End If
            Catch
            End Try
        End If
    End Sub
    
    'David D 6/13/17 added below sub routine to prevent RadGrid from collapsing on "Hide Close" toggle
    'Do not need this anymore due to no contract child tables
    Protected Sub RefreshDetailTable(rg As RadGrid, iDetailIndex As Integer)
        ' Refresh detail table by setting Expanded to false for all, then setting it to true again
        Dim eiExpanded As New List(Of GridEditableItem)()
        For Each item As GridItem In rg.MasterTableView.Items
            If TypeOf item Is GridEditableItem Then
                Dim ei As GridEditableItem = TryCast(item, GridEditableItem)
                If ei.Expanded Then
                    eiExpanded.Add(ei)
                    ei.Expanded = False
                End If
            End If
        Next
        RadGrid1.MasterTableView.DetailTables(iDetailIndex).Rebind()
        For Each ei As GridEditableItem In eiExpanded
            ei.Expanded = True
        Next
    End Sub
    
    Protected Sub RadMenu1_ItemClick(ByVal sender As Object, ByVal e As Telerik.Web.UI.RadMenuEventArgs)
       
        Dim btn As RadMenuItem = e.Item
        
        Select Case btn.Value
            Case "LogPrint"
                PrintRFILog()
                
            Case "ExportExcel"
                RadGrid1.Columns.FindByUniqueName("QuestionAttachments").Visible = False
                'RadGrid1.Columns.FindByUniqueName("AnswerAttachments").Visible = False
                RadGrid1.MasterTableView.ExportToExcel()
                
            Case "ExportPDF"
                RadGrid1.Columns.FindByUniqueName("QuestionAttachments").Visible = False
                'RadGrid1.Columns.FindByUniqueName("AnswerAttachments").Visible = False
                For Each item As GridItem In RadGrid1.MasterTableView.Items
                    If TypeOf item Is GridDataItem Then
                        Dim dataItem As GridDataItem = CType(item, GridDataItem)
                        Dim lnk As HyperLink = CType(dataItem("RefNumber").Controls(0), HyperLink)
                        lnk.NavigateUrl = ""
                    End If
                Next
                RadGrid1.MasterTableView.ExportToPdf()
            
            Case "HideAnswered"
                If btn.Attributes("Filter") = "Off" Then
                    btn.Attributes("Filter") = "On"
                    bHideAnswered = True
                    Session("HideClosed") = "Closed"
                    btn.ImageUrl = "images/funnel_down.png"
                Else
                    btn.Attributes("Filter") = "Off"
                    bHideAnswered = False
                    Session("HideClosed") = ""
                    btn.ImageUrl = "images/funnel.png"
                End If
                RadGrid1.Rebind() 'David D 6/13/17 not needed. Using below sub routine to keep detail table expanded during hide/close
                'RefreshDetailTable(RadGrid1, 0) 'Do not need this anymore because there is no child table. SM
                
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
                    db.SaveGridColumnVisibility("RFIGridColumns", btn.Attributes("ID"), btn.Attributes("Visibility"), "ProjectID", nProjectID)
                End Using
                RadGrid1.Rebind()
                
                
            Case "RestoreDefaultSettings"
                
                Using db As New promptUserPrefs
                    db.RemoveUserSavedSettings("RFIGridSettings", "ProjectID", nProjectID)
                    db.RemoveUserSavedSettings("RFIGridColumns", "ProjectID", nProjectID)
                End Using
                Response.Redirect(Page.Request.RawUrl)

        End Select
    End Sub

</script>

<asp:Content ID="Content1" ContentPlaceHolderID="mainBody" runat="Server">
    <telerik:RadWindowManager ID="contentPopup" runat="server" />

    <asp:HiddenField ID="openRFIID" runat="server"></asp:HiddenField>  

    <asp:HiddenField ID="contactID" runat="server"></asp:HiddenField> 
     
    <asp:HiddenField ID="pageType" value="RFI" runat="server"></asp:HiddenField>  

    <asp:HiddenField ID="testPlace" runat="server"></asp:HiddenField>  

    <telerik:RadMenu ID="RadMenu1" runat="server" OnItemClick="RadMenu1_ItemClick" Style="z-index: 10;" />

        <div style="height:18px;border-style:solid;border-width:0px;width:1050px;position:absolute;top:120px;z-index:500;background-color:#ededed;padding:3px 0 0 0">
            <div style="position:relative;width:100px;display:inline-block;height:18px;
                line-height:16px;vertical-align:top;text-align:right;font-size:10px;font-weight:bold">Status Indicator:&nbsp;&nbsp;</div>
           <div class="rfi_preparing" style="width:150px;height:16px;position:relative;display:inline-block;text-align:center;font-size:10px">RFI Preparing</div>
            <div style="position:absolute;display:inline-block;width:5px"></div>
            <div class="rfi_unassigned" style="width:150px;height:16px;position:relative;display:inline-block;text-align:center;font-size:10px">RFI Unassigned to DP</div>
            <div style="position:absolute;display:inline-block;width:5px"></div>
            <div class="rfi_pending" style="width:150px;height:16px;position:relative;display:inline-block;text-align:center;font-size:10px">RFI Active</div>
            <div style="position:absolute;display:inline-block;width:5px"></div>

            <div class="rfi_warning" style="width:150px;height:16px;position:relative;display:inline-block;text-align:center;font-size:10px">RFI Near Overdue (< 3 Days)</div>
            <div style="position:absolute;display:inline-block;width:5px"></div>

            <div class="rfi_overdue" style="width:150px;height:16px;position:relative;display:inline-block;text-align:center;font-size:10px">RFI Overdue</div>
            <div style="position:absolute;display:inline-block;width:5px"></div>
            <div class="rfi_answered" style="width:150px;height:16px;position:relative;display:inline-block;text-align:center;font-size:10px">RFI Complete/Closed</div>
        </div>

    <telerik:RadGrid ID="RadGrid1" runat="server" AllowSorting="true" AutoGenerateColumns="False" Style="margin-top:25px; float:left; clear:both"
        GridLines="None" Width="99%" EnableEmbeddedSkins="false" enableajax="True">
        <ClientSettings>
            <Selecting AllowRowSelect="False" />
            <Scrolling AllowScroll="True" UseStaticHeaders="True" ScrollHeight="50%" />
        </ClientSettings>

        <MasterTableView Width="99%" GridLines="None" DataKeyNames="ContractID,RefNumber,RFIID,Answer,Question,sRequiredBy,ReturnedOn,Status,QuestionAttachments,NewWorkflow,PMNewWorkFlow,WFPosition"
            NoMasterRecordsText="No Contracts with RFI(s) found.">
            <Columns>

               <telerik:GridHyperLinkColumn UniqueName="RefNumber" HeaderText="RFI #" DataTextField="itemNum"
                        SortExpression="RefNumber">
                        <ItemStyle HorizontalAlign="Left" Width="45px" VerticalAlign="top" CssClass="InnerItemStyle"   />
                        <HeaderStyle HorizontalAlign="Left" Width="45px" />
                    </telerik:GridHyperLinkColumn>

                    <telerik:GridBoundColumn UniqueName="Revision" HeaderText="Rev" DataField="Revision">
                        <ItemStyle HorizontalAlign="Left" Width="30px" VerticalAlign="Top" />
                        <HeaderStyle HorizontalAlign="Left" Width="30px" />
                    </telerik:GridBoundColumn> 

                   <telerik:GridHyperLinkColumn HeaderText="Flag" UniqueName="Flag" Visible="True">
                        <ItemStyle Width="50px" HorizontalAlign="Center" VerticalAlign="Middle" />
                        <HeaderStyle Width="50px" HorizontalAlign="Center" />
                    </telerik:GridHyperLinkColumn>

                    <telerik:GridHyperLinkColumn HeaderText="Attach" UniqueName="QuestionAttachments" Visible="false">
                        <ItemStyle Width="45px" HorizontalAlign="Center" VerticalAlign="Middle" />
                        <HeaderStyle Width="45px" HorizontalAlign="Center" />
                    </telerik:GridHyperLinkColumn>

                     <telerik:GridBoundColumn UniqueName="QueAttach" HeaderText="Attach" DataField="QuestionAttachments" Visible="false">
                        <ItemStyle HorizontalAlign="Left" Width="40px" VerticalAlign="Top" />
                        <HeaderStyle HorizontalAlign="Left" Width="40" />
                    </telerik:GridBoundColumn> 

                   <telerik:GridBoundColumn UniqueName="Position" HeaderText="Workflow Position" DataField="WFPosition">
                        <ItemStyle HorizontalAlign="Left" Width="150px" VerticalAlign="Top" />
                        <HeaderStyle HorizontalAlign="Left" Width="150px" />
                    </telerik:GridBoundColumn> 

                    <telerik:GridBoundColumn UniqueName="Status" HeaderText="Status" DataField="Status" Visible="false">
                        <ItemStyle HorizontalAlign="Left" Width="150px" VerticalAlign="Top" />
                        <HeaderStyle HorizontalAlign="Left" Width="150px" />
                    </telerik:GridBoundColumn> 

                    <telerik:GridBoundColumn UniqueName="CreatedBy" HeaderText="Created By" DataField="Name" Visible="True">
                        <ItemStyle HorizontalAlign="Left" Width="100px" VerticalAlign="Top" Wrap="true" />
                        <HeaderStyle HorizontalAlign="Left" Width="100px" />
                    </telerik:GridBoundColumn>

                    <telerik:GridBoundColumn UniqueName="Company" HeaderText="Company" DataField="CompanyName" Visible="True">
                        <ItemStyle HorizontalAlign="Left" Width="150px" VerticalAlign="Top" Wrap="true" />
                        <HeaderStyle HorizontalAlign="Left" Width="150px" />
                    </telerik:GridBoundColumn>

                     <telerik:GridBoundColumn UniqueName="AltReference" HeaderText="Alt Ref #" DataField="AltRefNumber" Visible="true">
                        <ItemStyle HorizontalAlign="Left" Width="130px" VerticalAlign="Top" Wrap="true" />
                        <HeaderStyle HorizontalAlign="Left" Width="130px" />
                    </telerik:GridBoundColumn>

                    <telerik:GridBoundColumn DataField="ReceivedOn" HeaderText="RFI Created" UniqueName="ReceivedOn"
                        DataFormatString="{0:MM/dd/yy}">
                        <ItemStyle Width="90px" HorizontalAlign="Center" VerticalAlign="Top" />
                        <HeaderStyle Width="90px" HorizontalAlign="Center" />
                    </telerik:GridBoundColumn>

                     <telerik:GridBoundColumn DataField="sRequiredBy" HeaderText="Date Required" UniqueName="sRequiredBy" visible="True"
                        DataFormatString="{0:MM/dd/yy}">
                        <ItemStyle Width="90px" HorizontalAlign="Center" VerticalAlign="Top" />
                        <HeaderStyle Width="90px" Height="20px" HorizontalAlign="Center" />
                    </telerik:GridBoundColumn>

                    <telerik:GridBoundColumn UniqueName="Question" HeaderText="Question/Response" DataField="Question">
                        <ItemStyle HorizontalAlign="Left" Width="175px" VerticalAlign="Top" Wrap="true" />
                        <HeaderStyle HorizontalAlign="Left" Width="175px" />
                    </telerik:GridBoundColumn>

                    <telerik:GridBoundColumn UniqueName="Answer" HeaderText="Answer" DataField="Answer" Visible="false">
                        <ItemStyle HorizontalAlign="Left" Width="100px" VerticalAlign="Top" Wrap="true" />
                        <HeaderStyle HorizontalAlign="Left" Width="100px" />
                    </telerik:GridBoundColumn>

                    <telerik:GridBoundColumn UniqueName="SubmittedTo" HeaderText="Submitted To" DataField="SubmittedTo" visible="false">
                        <ItemStyle HorizontalAlign="Left" Width="100px" VerticalAlign="Top" />
                        <HeaderStyle HorizontalAlign="Left" Width="100px" />
                    </telerik:GridBoundColumn>

                    <telerik:GridBoundColumn DataField="ClosedOn" HeaderText="Date Closed" UniqueName="ClosedOn"
                        DataFormatString="{0:MM/dd/yy}">
                        <ItemStyle Width="90px" HorizontalAlign="Center" VerticalAlign="Top" />
                        <HeaderStyle Width="90px" Height="20px" HorizontalAlign="Center" />
                    </telerik:GridBoundColumn>

                    <telerik:GridBoundColumn UniqueName="RFIID" HeaderText="RFIID" DataField="RFIID" Visible="false">
                        <ItemStyle HorizontalAlign="Left" Width="150px" VerticalAlign="Top" />
                        <HeaderStyle HorizontalAlign="Left" Width="150px" />
                    </telerik:GridBoundColumn>

                     <telerik:GridBoundColumn UniqueName="NewWorkflow" HeaderText="NewWorkflow" DataField="NewWorkflow" Visible="false">
                        <ItemStyle HorizontalAlign="Left" Width="150px" VerticalAlign="Top" />
                        <HeaderStyle HorizontalAlign="Left" Width="150px" />
                    </telerik:GridBoundColumn>
                
            </Columns>

           

        </MasterTableView>
        
        <ExportSettings OpenInNewWindow="True">
            <Pdf PageWidth="297mm" PageHeight="210mm" />
        </ExportSettings>

    </telerik:RadGrid>

    <!--  ------------------------------  -->

<%--    <telerik:RadAjaxManager ID="RadAjaxManager1" runat="server">
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
    </telerik:RadAjaxManager>
    <telerik:RadAjaxLoadingPanel ID="RadAjaxLoadingPanel1" runat="server" Height="75px"
        Width="75px" Transparency="25">
        <img alt="Loading..." src="images/loading.gif" style="border: 0;" />
    </telerik:RadAjaxLoadingPanel>--%>
    <telerik:RadToolTipManager ID="RadToolTipManager1" runat="server" Sticky="True" Title=""
        Position="BottomCenter" Skin="Office2007" HideDelay="500" ManualClose="False"
        ShowEvent="OnMouseOver" ShowDelay="100" Animation="Fade" AutoCloseDelay="6000"
        AutoTooltipify="False" Width="350" RelativeTo="Mouse" RenderInPageRoot="False">
    </telerik:RadToolTipManager>

    <telerik:RadScriptBlock ID="RadScriptBlock1" runat="server">

        <script type="text/javascript" language="javascript">
            window.onbeforeunload = function () {
                onThisClientClose()
            }

            function onThisClientClose() {
                //var oWnd = window.radopen("closeSession.aspx", "closeSessionWindow");
                var openRFIID = document.getElementById('<%= openRFIID.ClientID %>').value
                var contactID = document.getElementById('<%= contactID.ClientID %>').value
                var pageType = document.getElementById('<%= pageType.ClientID %>').value

                $.post("closeSession.aspx?RFIID=" + openRFIID + "&contactID=" + contactID + "&pageType=" + pageType, function () {
                    //alert("Who is the man");
                    document.getElementById('<%= openRFIID.ClientID %>').value = ""
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

            function ManageQuestionAttachments(id, projectid)     //for attachments info display
            {

                var oWnd = window.radopen("apprisepm_attachments_manage.aspx?ParentType=RFIQuestion&ParentID=" + id + "&ProjectID=" + projectid, "AttachmentsWindow");
                return false;
            }

            function ManageAnswerAttachments(id, projectid)     //for attachments info display
            {

                var oWnd = window.radopen("apprisepm_attachments_manage.aspx?ParentType=RFIAnswer&ParentID=" + id + "&ProjectID=" + projectid, "AttachmentsWindow");
                return false;
            }

            function EditRFI(id, projectid, contractid, type) {
                document.getElementById('<%= openRFIID.ClientID %>').value = id
                //var windowtype = type + "Window"
				var windowtype = "EditWindow"
                var oWnd = window.radopen("RFI_edit.aspx?RFIID=" + id + "&ProjectID=" + projectid + "&ContractID=" + contractid + "&EditType=" + type  , windowtype);
                return false;
            }

            function EditFlag(id, projectid) {

                var oWnd = window.radopen("PM_flag_edit.aspx?ProjectID=" + projectid + "ParentRecType=Project");
                return false;

            }
            function OpenPrintSetup(projectid) {
                var oWnd = window.radopen("PrintSetup.aspx?ProjectID=" + projectid);
                return false;
            }
//            function GetRadWindow() {
//                var oWindow = null;
//                if (window.RadWindow) oWindow = window.RadWindow;
//                else if (window.frameElement.radWindow) oWindow = window.frameElement.radWindow;
//                return oWindow;
//            }

        </script>

    </telerik:RadScriptBlock>
</asp:Content>
