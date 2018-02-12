<%@ Page Language="VB" %>

<%@ Register Assembly="Telerik.Web.UI" Namespace="Telerik.Web.UI" TagPrefix="telerik" %>
<%@ Import Namespace="Prompt" %>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">

<script runat="server">
    Private nProjectID As Integer = 0
    Private bReadOnly As Boolean = True
    Private bAllowUserToCreateSnapshots As Boolean = False
    Private dSnapshotDate As Nullable(Of Date) = Nothing
 
    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs)
        ProcLib.LoadPopupJscript(Page)
        Session("PageID") = "BudgetObjectCodeEstimatesList"
        
        nProjectID = Request.QueryString("ProjectID")
        
        Using db As New EISSecurity
            db.DistrictID = Session("DistrictID")
            db.CollegeID = Session("CollegeID")
            db.ProjectID = nProjectID
            db.UserID = Session("UserID")
            
            'Check for specific rights
            If db.FindUserPermission("JCAFEstExpenses", "write") Or db.FindUserPermission("JCAFBudget", "write") Then
                bReadOnly = False
            Else
                bReadOnly = True
            End If
            
            'Check for specific rights
            If db.FindUserPermission("JCAFExpenseSnapshots", "write") Then
                bAllowUserToCreateSnapshots = True
            End If
            
        End Using

        'Set Grid Properties
        With RadGrid1
            .EnableEmbeddedSkins = False
            .Skin = "Prompt"
            .GroupingEnabled = False
            .AllowSorting = True
                
            .ClientSettings.AllowColumnsReorder = False
            .ClientSettings.ColumnsReorderMethod = GridClientSettings.GridColumnsReorderMethod.Reorder
            .ClientSettings.Scrolling.AllowScroll = True
            .ClientSettings.Scrolling.ScrollHeight = Unit.Percentage(50)
            .ClientSettings.Scrolling.UseStaticHeaders = True
            .ClientSettings.Resizing.AllowColumnResize = True

            .MasterTableView.EnableHeaderContextMenu = True
            .MasterTableView.TableLayout = GridTableLayout.Fixed
            .MasterTableView.AllowMultiColumnSorting = False

            .Height = Unit.Pixel(300)
            
            .ExportSettings.FileName = "PromptBudgetEstimatesExport"
            .ExportSettings.OpenInNewWindow = True
            .ExportSettings.Pdf.PageTitle = "PROMPT Budget Estimates"
        End With
        
        'Configure the Popup Window(s)
        With MasterPopups
            .VisibleOnPageLoad = False
            .Skin = "Vista"
                  
            Dim ww As New RadWindow
            With ww
                .ID = "EditRecord"
                '.NavigateUrl = ""
                .Title = ""
                .Width = 450
                .Height = 300
                .Modal = True
                .VisibleStatusbar = False
                .ReloadOnShow = False
                .Behaviors = WindowBehaviors.Close + WindowBehaviors.Resize
            End With
            .Windows.Add(ww)
           
        End With
        
        If Not IsPostBack Then
            'Load the Notes Box
            Using db As New PromptDataHelper
                Dim rs As DataTable = db.ExecuteDataTable("SELECT * FROM Projects WHERE ProjectID = " & nProjectID)
                Dim row As DataRow = rs.Rows(0)
                txtBudgetEstimateNotes.Text = ProcLib.CheckNullDBField(row("BudgetEstimateNotes"))
                Dim sstat As String = Trim(ProcLib.CheckNullDBField(row("CMDM_Status")))
                If sstat <> "" Then
                    cboCMDMStatus.SelectedValue = sstat
                Else
                    cboCMDMStatus.SelectedIndex = 0
                End If
                
                sstat = Trim(ProcLib.CheckNullDBField(row("CMDM_EstimateAtCompletionStatus")))
                If sstat <> "" Then
                    cboCMDMEstAtCompletionStatus.SelectedValue = sstat
                Else
                    cboCMDMEstAtCompletionStatus.SelectedIndex = 0
                End If
                
                sstat = Trim(ProcLib.CheckNullDBField(row("CMDM_ProjectBudgetStatus")))
                If sstat <> "" Then
                    cboCMDMProjectBudgetStatus.SelectedValue = sstat
                Else
                    cboCMDMProjectBudgetStatus.SelectedIndex = 0
                End If
            End Using
        End If

        If bReadOnly = True Then
            cboCMDMEstAtCompletionStatus.Enabled = False
            cboCMDMProjectBudgetStatus.Enabled = False
            cboCMDMStatus.Enabled = False
            txtBudgetEstimateNotes.Enabled = False
            
        End If
        
        BuildMenu()
    End Sub

    Protected Sub RadGrid1_NeedDataSource(ByVal source As Object, ByVal e As Telerik.Web.UI.GridNeedDataSourceEventArgs) Handles RadGrid1.NeedDataSource

        'loads the grid whenever it needs data (sorting, rebinding, etc...)
        Select Case cboWhichData.SelectedItem.Text
            Case "Current Data"
                Using db As New PromptDataHelper
                    Dim sql As String = "SELECT * From BudgetObjectCodeEstimates Where ProjectID = " & nProjectID & " ORDER BY ObjectCode"
                    RadGrid1.DataSource = db.ExecuteDataTable(sql)
                End Using
            Case "Snapshot Data"
                Using db As New PromptDataHelper
                    dSnapshotDate = db.ExecuteScalar("Select Top 1 SnapshotTime From  BudgetObjectCodeEstimates_Snapshots Where ProjectID = " & nProjectID)
                    Dim sql As String = "SELECT * From BudgetObjectCodeEstimates_Snapshots Where ProjectID = " & nProjectID & " ORDER BY ObjectCode"
                    RadGrid1.DataSource = db.ExecuteDataTable(sql)
                End Using
            Case Else
                Throw New Exception("unexpected error")
        End Select
       
    End Sub
 
    Protected Sub RadGrid1_ItemCreated(ByVal sender As Object, ByVal e As Telerik.Web.UI.GridItemEventArgs) Handles RadGrid1.ItemCreated
        'This event allows us to customize the cell contents - fired before databound

        If (TypeOf e.Item Is GridDataItem) Then
               
            Dim item As GridDataItem = CType(e.Item, GridDataItem)
            Dim nKey As Integer = item.OwnerTableView.DataKeyValues(item.ItemIndex)("PrimaryKey")
                 
            If bReadOnly = False Then
                'update the link button to open attachments/notes window
                Dim linkButton As HyperLink = CType(item("ObjectCode").Controls(0), HyperLink)
                If cboWhichData.SelectedItem.Text = "Current Data" Then
                    linkButton.Attributes("onclick") = "return EditRecord(this,'" & nKey & "','" & nProjectID & "','BudgetObjectCodeEstimates');"
                Else
                    linkButton.Attributes("onclick") = "return EditRecord(this,'" & nKey & "','" & nProjectID & "','BudgetObjectCodeEstimates_Snapshots');"
                End If
                linkButton.ToolTip = "Edit this Budget Object Code Estimate"
            End If
        End If
        
    End Sub

       
    Private Sub BuildMenu()
        
        If Not IsPostBack Then          'Configure Tool Bar            
            With RadMenu1
                .EnableEmbeddedSkins = True
                .Skin = "Vista"
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
                
            If Not bReadOnly Then
                but = New RadMenuItem
                With but
                    .Text = "Add New Line"
                    .ImageUrl = "images/add.png"
                    .ToolTip = "Add a New Line."
                    If cboWhichData.SelectedItem.Text = "Current Data" Then
                        .Attributes("onclick") = "return EditRecord(this,'" & 0 & "','" & nProjectID & "','BudgetObjectCodeEstimates');"
                    Else
                        .Attributes("onclick") = "return EditRecord(this,'" & 0 & "','" & nProjectID & "','BudgetObjectCodeEstimates_Snapshots');"
                    End If
                    .PostBack = False
                End With
                RadMenu1.Items.Add(but)
            
                but = New RadMenuItem
                but.IsSeparator = True
                but.Width = Unit.Pixel(15)
                RadMenu1.Items.Add(but)
                
                but = New RadMenuItem
                With but
                    .Text = "Save"
                    .Value = "Save"
                    .ImageUrl = "images/prompt_savetodisk.gif"
                End With
                RadMenu1.Items.Add(but)
                
                'hide the Snapshot button(s) for all by TechSupport users
                ' If HttpContext.Current.Session("UserRole") = "TechSupport" Then
                If bAllowUserToCreateSnapshots = True Or HttpContext.Current.Session("UserRole") = "TechSupport" Then
                    but = New Telerik.Web.UI.RadMenuItem
                    With but
                        .Text = "Snapshots"
                        .Value = "Snapshots"
                        .ImageUrl = "images/camera2_small.png"
                        .PostBack = False
                    End With
                    Dim butSubA As New Telerik.Web.UI.RadMenuItem
                    With butSubA
                        .Text = "Snapshot THIS Project"
                        .ToolTip = "Copies current data to snapshot FOR THIS PROJECT ONLY (overwrites any existing snapshot)"
                        .Value = "SnapshotThisProject"
                        'note: jQuery code (below) creates a confirmation pop up
                    End With
                    but.Items.Add(butSubA)
                    Dim butSubB As New Telerik.Web.UI.RadMenuItem
                    With butSubB
                        .Text = "Snapshot ALL District Projects"
                        .ToolTip = "Copies current data to snapshot FOR ALL PROJECTS IN THIS DISTRICT (overwrites any existing snapshots)"
                        .Value = "SnapshotAllProjects"
                        'note: jQuery code (below) creates a confirmation pop up
                    End With
                    but.Items.Add(butSubB)
                    RadMenu1.Items.Add(but)
                End If
            End If
           
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
            butDropDown.Items.Add(butSub)
            
            RadMenu1.Items.Add(butDropDown)
            
   
            'butDropDown = New RadMenuItem
            'With butDropDown
            '    .Text = "Print"
            '    .Value = "Print"
            '    .ImageUrl = "images/printer.png"
            '    .PostBack = False
            'End With

            'butSub = New RadMenuItem
            'With butSub
            '    .Text = "Budget Allocation Detail Report"
            '    .Value = "BudgetAllocationReport"
            '    .ImageUrl = "images/printer.png"
            '    .NavigateUrl = "report_run.aspx?DirectCall=1&rpt=Allocation_Detail_By_Project&Item=" & JCAFColumnName & "&ProjectID=" & ProjectID
            '    .Target = "_new"
            '    .PostBack = True
            'End With
            'butDropDown.Items.Add(butSub)

            'RadMenu1.Items.Add(butDropDown)
            
                        
            but = New Telerik.Web.UI.RadMenuItem
            With but
                .Text = "Exit"
                .Value = "Exit"

                .ImageUrl = "images/exit.png"
            End With
            RadMenu1.Items.Add(but)
            
            but = New RadMenuItem
            but.IsSeparator = True
            but.Width = Unit.Pixel(100)
            RadMenu1.Items.Add(but)
            
            but = New Telerik.Web.UI.RadMenuItem
            With but
                .Text = "Help"
                .Value = "Help"
                .ImageUrl = "images/help.png"
                .Attributes("onclick") = "openPopup('help_view.aspx','pophelp',550,450,'yes');"
                .PostBack = False

            End With
            RadMenu1.Items.Add(but)
        End If
        
        'update "add new" button to add to correct table
        If bReadOnly = False Then
            Dim m As New Telerik.Web.UI.RadMenuItem
            m = RadMenu1.Items.FindItemByText("Add New Line")
            If cboWhichData.SelectedItem.Text = "Current Data" Then
                m.Attributes("onclick") = "return EditRecord(this,'" & 0 & "','" & nProjectID & "','BudgetObjectCodeEstimates');"
            Else
                m.Attributes("onclick") = "return EditRecord(this,'" & 0 & "','" & nProjectID & "','BudgetObjectCodeEstimates_Snapshots');"
            End If
        End If
    End Sub
    
    Protected Sub RadMenu1_ItemClick(ByVal sender As Object, ByVal e As Telerik.Web.UI.RadMenuEventArgs) Handles RadMenu1.ItemClick
       
        Dim btn As RadMenuItem = e.Item
        
        Select Case btn.Value
            
            Case "Exit"
                
                Session("RtnFromEdit") = True
                ProcLib.CloseOnly(Page)
                
            Case "Save"
                
                Using db As New PromptDataHelper
                    Dim sstat As String = cboCMDMStatus.SelectedValue
                    If sstat = "-auto calc-" Then
                        sstat = ""
                    Else
                        sstat = cboCMDMStatus.SelectedValue
                    End If
                    
                    Dim sstatEst As String = cboCMDMEstAtCompletionStatus.SelectedValue
                    If sstatEst = "-auto calc-" Then
                        sstatEst = ""
                    Else
                        sstatEst = cboCMDMEstAtCompletionStatus.SelectedValue
                    End If
                    
                    Dim sstatBudget As String = cboCMDMProjectBudgetStatus.SelectedValue
                    If sstatBudget = "-auto calc-" Then
                        sstatBudget = ""
                    Else
                        sstatBudget = cboCMDMProjectBudgetStatus.SelectedValue
                    End If
                    
                    Dim snotes As String = txtBudgetEstimateNotes.Text
                    snotes = snotes.Replace("'", "''")
                    
                    Dim sql As String = "UPDATE Projects SET "
                    sql &= "BudgetEstimateNotes = '" & snotes & "',"
                    sql &= " CMDM_Status = '" & sstat & "', "
                    sql &= " CMDM_EstimateAtCompletionStatus = '" & sstatEst & "', "
                    sql &= " CMDM_ProjectBudgetStatus = '" & sstatBudget & "' "
                    sql &= "WHERE ProjectID = " & nProjectID
                    db.ExecuteNonQuery(sql)
                End Using
                
                Session("RtnFromEdit") = True
                ProcLib.CloseOnly(Page)

            Case "ExportExcel"
 
                RadGrid1.MasterTableView.ExportToExcel()
                
            Case "SnapshotThisProject"
                Using db As New PromptDataHelper
                    db.ExecuteScalar("Delete From BudgetObjectCodeEstimates_Snapshots Where ProjectID = " & nProjectID)
                    Dim count As Integer
                    Dim sql As String
                    sql = "Insert into BudgetObjectCodeEstimates_Snapshots  "
                    sql += "(DistrictID, CollegeID, ProjectID, ObjectCode, Description, EstimateToComplete, PendingExpenses, LastUpdateOn, LastUpdateBy, FHDA_ObjectCode, Notes, SnapshotTime) "
                    sql += "Select DistrictID, CollegeID, ProjectID, ObjectCode, Description, EstimateToComplete, PendingExpenses, GetDate(), '" & Session("UserName") & "', FHDA_ObjectCode, Notes, GetDate() "
                    sql += "From BudgetObjectCodeEstimates where ProjectID = " & nProjectID
                    count = db.ExecuteNonQueryWithReturn(sql)
                    lblNowShowing.Text = "Successfully updated THIS Project snapshot with " & count & " row(s)"
                End Using
                
            Case "SnapshotAllProjects"
                Using db As New PromptDataHelper
                    db.ExecuteScalar("Delete From BudgetObjectCodeEstimates_Snapshots Where DistrictID = " & Session("DistrictID"))
                    Dim count As Integer
                    Dim sql As String
                    sql = "INSERT INTO BudgetObjectCodeEstimates_Snapshots (DistrictID,CollegeID,ProjectID,ObjectCode,Description, "
                    sql += "	EstimateToComplete,PendingExpenses,LastUpdateOn,LastUpdateBy,FHDA_ObjectCode,Notes,SnapshotTime) "
                    sql += "SELECT DistrictID,CollegeID,ProjectID,ObjectCode,Description,EstimateToComplete,PendingExpenses, "
                    sql += "	LastUpdateOn,LastUpdateBy,FHDA_ObjectCode,Notes,getdate()  "
                    sql += "FROM BudgetObjectCodeEstimates "
                    sql += "Where DistrictID = " & Session("DistrictID")
                    count = db.ExecuteNonQueryWithReturn(sql)
                    lblNowShowing.Text = "Successfully updated ALL Project snapshots with " & count & " row(s)"
                End Using
        End Select
        
    End Sub
    
    Private Sub cboWhichData_SelectedIndexChanged(ByVal sender As Object, ByVal e As System.EventArgs) Handles cboWhichData.SelectedIndexChanged
        If (cboWhichData.SelectedItem.Text = "Snapshot Data") And Not (dSnapshotDate Is Nothing) Then
            lblNowShowing.Text = " from: " & dSnapshotDate
        Else
            lblNowShowing.Text = ""
        End If
        RadGrid1.Rebind()
    End Sub
</script>

<html >
<head runat="server">
    <title>Budget Object Code Estimates List</title>
    <link href="Styles.css" rel="stylesheet" type="text/css" />
        <link href="skins/Prompt/Grid.Prompt.css" rel="stylesheet" type="text/css" />
            <link href="skins/Prompt/Menu.Prompt.css" rel="stylesheet" type="text/css" />
    <script src="js/jquery-1.4.2.min.js" type="text/javascript"></script>

   <telerik:RadCodeBlock ID="RadCodeBlock1" runat="server">

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

            function GetRadWindow() {
                var oWindow = null;
                if (window.RadWindow) oWindow = window.RadWindow;
                else if (window.frameElement.radWindow) oWindow = window.frameElement.radWindow;
                return oWindow;
            }

            function EditRecord(oButton, id, Pid, whichTable)     //for editing object code
            {
                //var message = id + " / " + Pid ; alert(message);
                if (whichTable == 'BudgetObjectCodeEstimates') {
                    var oWnd = window.radopen("budget_estimate_to_complete_edit.aspx?PrimaryKey= " + id + "&ProjectID=" + Pid, "EditRecord");
                } else {
                    var oWnd = window.radopen("budget_estimate_to_complete_edit.aspx?PrimaryKey= " + id + "&ProjectID=" + Pid + "&Snapshot=Y", "EditRecord");
                }
                return false;
            }

            jQuery(function() {
                //this is the code that creates a confirm pop up for the Copy-to-Snapshot buttons
                $('a:contains(Snapshot THIS Project), a:contains(Snapshot ALL District)').click(function() {
                    x = confirm('Are you sure you want to overwrite the snapshot with current data?');
                    if (x) {
                        //alert('y');
                    } else {
                        //alert('n');
                        return false;   //returning false prevents the postback and thus prevents the snapshot from taking place
                    }
                });
            })
        </script>

    </telerik:RadCodeBlock>  



</head>
   
<body>
 <form id="Form1" method="post" runat="server">
     <telerik:RadScriptManager ID="RadScriptManager1" runat="server" />
     <telerik:RadMenu ID="RadMenu1" runat="server" OnItemClick="RadMenu1_ItemClick" />
    <br />
     <asp:Label ID="lblText" runat="server" Text="Now Showing:"></asp:Label>
     <telerik:RadComboBox ID="cboWhichData" runat="server" Width="175px" AutoPostBack="True" OnSelectedIndexChanged="cboWhichData_SelectedIndexChanged">
         <Items>
             <telerik:RadComboBoxItem runat="server" Text="Current Data"  Value="Current Data" />
             <telerik:RadComboBoxItem runat="server" Text="Snapshot Data" Value="Snapshot Data" />
         </Items>
     </telerik:RadComboBox>
     <asp:Label ID="lblNowShowing" runat="server" Text=""></asp:Label>
                <br />
            <telerik:RadGrid ID="RadGrid1"
                runat="server" AllowSorting="True" AutoGenerateColumns="False" GridLines="None"
                Width="96%" EnableAJAX="True" Skin="Office2007" Height="450">
                <ClientSettings>
                    <Selecting AllowRowSelect="True" />
                    <Scrolling AllowScroll="True" UseStaticHeaders="True" ScrollHeight="50%" />
                </ClientSettings>
                <MasterTableView Height="80%" Width="100%" GridLines="None" DataKeyNames="PrimaryKey"
                    NoMasterRecordsText="No Object Codes Found.">
                    <Columns>
                        <telerik:GridHyperLinkColumn DataTextField="ObjectCode" UniqueName="ObjectCode" HeaderText="Object Code" SortExpression="ObjectCode">
                            <ItemStyle VerticalAlign="Top" HorizontalAlign="Left" />
                            <HeaderStyle VerticalAlign="Top" HorizontalAlign="Left" Width="90px" Height="15px" />
                        </telerik:GridHyperLinkColumn>
                        <telerik:GridBoundColumn DataField="Description" UniqueName="Description" HeaderText="Description">
                            <ItemStyle  VerticalAlign="Top" HorizontalAlign="Left" />
                            <HeaderStyle  VerticalAlign="Top" HorizontalAlign="Left" Height="15px" Width="35%" />
                        </telerik:GridBoundColumn>
                        <telerik:GridBoundColumn DataField="PendingExpenses" UniqueName="PendingExpenses" HeaderText="Pending Expenses"  DataFormatString="{0:c}">
                            <ItemStyle  VerticalAlign="Top" HorizontalAlign="Left" />
                            <HeaderStyle  VerticalAlign="Top" HorizontalAlign="Left" Height="15px" />
                        </telerik:GridBoundColumn>
                        <telerik:GridBoundColumn DataField="EstimateToComplete" UniqueName="EstimateToComplete"
                            HeaderText="Approximate Expenses"  DataFormatString="{0:c}">
                            <ItemStyle  VerticalAlign="Top" HorizontalAlign="Left" />
                            <HeaderStyle  VerticalAlign="Top" HorizontalAlign="Left" Height="15px" />
                        </telerik:GridBoundColumn>
                        <telerik:GridBoundColumn DataField="Notes" UniqueName="Notes"
                            HeaderText="Notes"  DataFormatString="{0:c}">
                            <ItemStyle  VerticalAlign="Top" HorizontalAlign="Left" />
                            <HeaderStyle  VerticalAlign="Top" HorizontalAlign="Left" Height="15px" />
                        </telerik:GridBoundColumn>
                    </Columns>
                </MasterTableView>
            </telerik:RadGrid>
            
            <br />
            &nbsp;&nbsp;
            <asp:Label ID="Label1" runat="server" Text="CM/DM Report Project Notes:"></asp:Label>
            <br />
            &nbsp;&nbsp;
     <asp:TextBox ID="txtBudgetEstimateNotes" runat="server" TextMode="MultiLine" Height="35" Width="90%"></asp:TextBox>
             <br /> <br />
            &nbsp;&nbsp;
            <asp:Label ID="Label2" runat="server" Text="CM/DM Report Status:"></asp:Label>
            &nbsp;&nbsp;
     <telerik:RadComboBox ID="cboCMDMStatus" runat="server" Width="175px">
         <Items>
             <telerik:RadComboBoxItem runat="server" Text="- Auto Calc -"  Value="-auto calc-" />
             <telerik:RadComboBoxItem runat="server" Text="caution" Value="caution" />
             <telerik:RadComboBoxItem runat="server" Text="N/A" Value="N/A" />
             <telerik:RadComboBoxItem runat="server" Text="ok" Value="ok" />
             <telerik:RadComboBoxItem runat="server" Text="problem" Value="problem" />
         </Items>
     </telerik:RadComboBox>
            &nbsp;&nbsp;
            <asp:Label ID="Label3" runat="server" Text="CM/DM Proj Budget Status:"></asp:Label>
            &nbsp;&nbsp;
     <telerik:RadComboBox ID="cboCMDMProjectBudgetStatus" runat="server" Width="175px">
         <Items>
             <telerik:RadComboBoxItem runat="server" Text="- Auto Calc -" Value="-auto calc-" />
             <telerik:RadComboBoxItem runat="server" Text="caution" Value="caution" />
             <telerik:RadComboBoxItem runat="server" Text="N/A" Value="N/A" />
             <telerik:RadComboBoxItem runat="server" Text="ok" Value="ok" />
             <telerik:RadComboBoxItem runat="server" Text="problem" Value="problem" />
         </Items>
     </telerik:RadComboBox>
          <br /> <br />
            &nbsp;&nbsp;
            <asp:Label ID="Label4" runat="server" Text="CM/DM Est At Complete Status:"></asp:Label>
            &nbsp;&nbsp;
     <telerik:RadComboBox ID="cboCMDMEstAtCompletionStatus" runat="server" Width="175px">
         <Items>
             <telerik:RadComboBoxItem runat="server" Text="- Auto Calc -" Value="-auto calc-" />
             <telerik:RadComboBoxItem runat="server" Text="caution" Value="caution" />
             <telerik:RadComboBoxItem runat="server" Text="N/A" Value="N/A" />
             <telerik:RadComboBoxItem runat="server" Text="ok" Value="ok" />
             <telerik:RadComboBoxItem runat="server" Text="problem" Value="problem" />
         </Items>
     </telerik:RadComboBox>  
            
    <telerik:RadWindowManager ID="MasterPopups" runat="server">  </telerik:RadWindowManager>
            
<%--    <telerik:RadAjaxManager ID="RadAjaxManager1" runat="server">
            <ClientEvents OnRequestStart="ajaxRequestStart" OnResponseEnd="ajaxRequestEnd" />
            <AjaxSettings>
                <telerik:AjaxSetting AjaxControlID="RadGrid1">
                    <UpdatedControls>
                        <telerik:AjaxUpdatedControl ControlID="RadGrid1" LoadingPanelID="RadAjaxLoadingPanel1" />
                    </UpdatedControls>
                </telerik:AjaxSetting>
                <telerik:AjaxSetting AjaxControlID="cboWhichData">
                    <UpdatedControls>
                        <telerik:AjaxUpdatedControl ControlID="RadGrid1" LoadingPanelID="RadAjaxLoadingPanel1" />
                    </UpdatedControls>
                </telerik:AjaxSetting>
            </AjaxSettings>
    </telerik:RadAjaxManager>
--%>    
    <telerik:RadAjaxLoadingPanel ID="RadAjaxLoadingPanel1" runat="server" Height="75px"
        Width="75px" Transparency="25">
        <img alt="Loading..." src='<%= RadAjaxLoadingPanel.GetWebResourceUrl(Page, "Telerik.Web.UI.Skins.Default.Ajax.loading.gif") %>' style="border: 0;" />
    </telerik:RadAjaxLoadingPanel>
   
    </form>
</body>
</html>
