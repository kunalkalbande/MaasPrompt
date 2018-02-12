<%@ Control Language="vb" %>
<%@ Register Assembly="Telerik.Web.UI" Namespace="Telerik.Web.UI" TagPrefix="telerik" %>
<%@ Import Namespace="Prompt" %>

<script runat="server">
    
    Private view As String = ""
    
     
    Protected Sub Page_Init(ByVal sender As Object, ByVal e As System.EventArgs)
        
        view = Session("alertsview")
    
        Select Case view
            Case "AllAlerts"
                grid_Alerts.MasterTableView.Columns.FindByUniqueName("AlertType").Visible = True
                grid_Alerts.MasterTableView.Columns.FindByUniqueName("AlertInfo").HeaderText = "Info"
            
            Case "FlaggedItems"
                grid_Alerts.MasterTableView.Columns.FindByUniqueName("AlertType").Visible = False
                grid_Alerts.MasterTableView.Columns.FindByUniqueName("AlertInfo").HeaderText = "Created By"
            
            Case "ExpiredContracts", "ExpiredInsurance"
                
                grid_Alerts.MasterTableView.Columns.FindByUniqueName("AlertType").Visible = False
                grid_Alerts.MasterTableView.Columns.FindByUniqueName("AlertInfo").HeaderText = "Expires"
                
        End Select
            
    
    End Sub
    
    Private Sub Page_Load(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MyBase.Load

        'User Control to Show Open Alerts

        Session("PageID") = "DashboardAlertsWidget"
        ProcLib.LoadPopupJscript(Page)
         
        With grid_Alerts
            .EnableEmbeddedSkins = False
            .Skin = "Prompt"
            .GroupingEnabled = True
            .AllowSorting = True
            '.EnableViewState = False
                        
            .ClientSettings.AllowColumnsReorder = True
            .ClientSettings.ColumnsReorderMethod = GridClientSettings.GridColumnsReorderMethod.Reorder
            .ClientSettings.Scrolling.AllowScroll = True
            .ClientSettings.Scrolling.ScrollHeight = Unit.Percentage(50)
            .ClientSettings.Scrolling.UseStaticHeaders = True
            .ClientSettings.Resizing.AllowColumnResize = True
            

            .MasterTableView.EnableHeaderContextMenu = False
            .MasterTableView.TableLayout = GridTableLayout.Fixed
            .MasterTableView.AllowMultiColumnSorting = False

            .Height = Unit.Pixel(330)
            
            .ExportSettings.FileName = "PromptAlertsExport"
            .ExportSettings.OpenInNewWindow = True
            .ExportSettings.Pdf.PageTitle = "Prompt Open Alerts"
               
        End With
        
        'Configure the Popup Window(s)
        With AlertPopups
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
    
       
    Protected Sub grid_Alerts_NeedDataSource(ByVal source As Object, ByVal e As Telerik.Web.UI.GridNeedDataSourceEventArgs) Handles grid_Alerts.NeedDataSource
        
        grid_Alerts.DataSource = GetAlerts(view)

    End Sub
        
    Protected Sub grid_Alerts_ItemCommand(ByVal source As Object, ByVal e As Telerik.Web.UI.GridCommandEventArgs)
        ' If multiple buttons are used in a Telerik RadGrid control, use the
        ' CommandName property to determine which button was clicked.
        If e.CommandName = "FindRecord" Then       'autolocate the nav menu and main page to the contract show area for transaction
            Dim Args = Split(e.CommandArgument, ",")
            'Dim TransID As Integer = Args(0)
            Dim ContractID As Integer = Args(0)
            Dim ProjectID As Integer = Args(1)
            Dim CollegeID As Integer = Args(2)
            Dim AlertType As String = Args(3)
            'Dim nRFIID As Integer = Args(1)
            
            'testPlace.Value = "You are here"
            
            Session("RefreshNav") = True
            Session("RtnFromEdit") = False
            Session("CollegeID") = CollegeID
            Session("DirectCallCount") = 1
 
            Select Case AlertType

                Case "Flagged Project"
                    Session("nodeid") = "Project" & ProjectID
                    Session("DirectCallURL") = "project_overview.aspx?view=project&ProjectID=" & ProjectID & "&CollegeID=" & CollegeID & "&t=y"
  

                Case "Flagged Contract"
                    Session("nodeid") = "Contract" & ContractID
                    Session("DirectCallURL") = "contract_overview.aspx?view=contract&ContractID=" & ContractID & "&ProjectID=" & ProjectID & "&CollegeID=" & CollegeID & "&t=y"
                    
                Case "Expired Contract"
                    Session("nodeid") = "Contract" & ContractID
                    Session("DirectCallURL") = "contract_overview.aspx?view=contract&ContractID=" & ContractID & "&ProjectID=" & ProjectID & "&CollegeID=" & CollegeID & "&t=y"
  
                Case "Expired Insurance"
                    Session("nodeid") = "Contract" & ContractID
                    Session("DirectCallURL") = "contract_overview.aspx?view=contract&ContractID=" & ContractID & "&ProjectID=" & ProjectID & "&CollegeID=" & CollegeID & "&t=y"
  
                Case "Flagged ChangeOrder"
                    Session("nodeid") = "Contract" & ContractID
                    Session("DirectCallURL") = "contract_changeorders.aspx?view=contract&ContractID=" & ContractID & "&ProjectID=" & ProjectID & "&CollegeID=" & CollegeID & "&t=y"

                Case "Flagged Transaction"
                    Session("nodeid") = "Contract" & ContractID
                    Session("DirectCallURL") = "transactions.aspx?view=contract&ContractID=" & ContractID & "&ProjectID=" & ProjectID & "&CollegeID=" & CollegeID & "&t=y"

                Case "Flagged BudgetItem"
                    Session("nodeid") = "Project" & ProjectID
                    Session("DirectCallURL") = "budget.aspx?view=project&ProjectID=" & ProjectID & "&CollegeID=" & CollegeID & "&t=y"
 
                    
                Case "Contract Conversion Flag"
                    Session("nodeid") = "Contract" & ContractID
                    Session("DirectCallURL") = "contract_overview.aspx?view=contract&ContractID=" & ContractID & "&ProjectID=" & ProjectID & "&CollegeID=" & CollegeID & "&t=y"
                    
                Case "Flagged RFI"
                    Session("nodeid") = "Project" & ProjectID
                    Session("DirectCallURL") = "RFIs.aspx?view=project&ProjectID=" & ProjectID & "&CollegeID=" & CollegeID & "&t=y"
            End Select
            
            Response.Redirect("main.aspx")
 
        End If

    End Sub
  
    Protected Sub grid_Alerts_ItemCreated(ByVal sender As Object, ByVal e As Telerik.Web.UI.GridItemEventArgs) Handles grid_Alerts.ItemCreated
        'This event allows us to customize the cell contents - fired before databound
          
        If (TypeOf e.Item Is GridDataItem) Then
            
            Dim item As GridDataItem = CType(e.Item, GridDataItem)
            
            'Dim nAlertID As Integer = item.OwnerTableView.DataKeyValues(item.ItemIndex)("AlertID")
            Dim sAlertToolTip As String = item.OwnerTableView.DataKeyValues(item.ItemIndex)("AlertDescription")
            
            Dim sAlertType As String = item.OwnerTableView.DataKeyValues(item.ItemIndex)("AlertType")
            Dim sBudgetField As String = item.OwnerTableView.DataKeyValues(item.ItemIndex)("BudgetField")
            
            Dim nTransactionID As Integer = item.OwnerTableView.DataKeyValues(item.ItemIndex)("TransactionID")
            Dim nContractID As Integer = item.OwnerTableView.DataKeyValues(item.ItemIndex)("ContractID")
            Dim nContractDetailID As Integer = item.OwnerTableView.DataKeyValues(item.ItemIndex)("ContractDetailID")
            Dim nProjectID As Integer = item.OwnerTableView.DataKeyValues(item.ItemIndex)("ProjectID")
            Dim nCollegeID As Integer = item.OwnerTableView.DataKeyValues(item.ItemIndex)("CollegeID")
            'Dim nRFIID As Integer = item.OwnerTableView.DataKeyValues(item.ItemIndex)("RFIID")
            
            ''update the link button to open Alert window
            Dim linkButton As HyperLink = CType(item("Description").Controls(0), HyperLink)

            Dim nKey As Integer = 0
            Dim sType As String = ""
            Dim sBudgetItem As String = ""
            Dim sFindTip As String = ""
            Dim bSetEditFlagLink As Boolean = False

            Select Case sAlertType
                
                Case "Expired Contract", "Expired Insurance"
                    sType = "Contract"
                    nKey = nContractID
                    sFindTip = "Click to go directly to Contract Overview."
                   
                Case "Flagged Project"
                    sType = "Project"
                    nKey = nProjectID
                    sFindTip = "Click to go directly to Project Overview."
                    bSetEditFlagLink = True


                Case "Flagged Contract"
                    sType = "Contract"
                    nKey = nContractID
                    sFindTip = "Click to go directly to Contract Overview."
                    bSetEditFlagLink = True


                Case "Flagged ChangeOrder"
                    sType = "ContractDetail"
                    nKey = nContractDetailID
                    sFindTip = "Click to go directly to Contract Change Order list view."
                    bSetEditFlagLink = True


                Case "Flagged Transaction"
                    sType = "Transaction"
                    nKey = nTransactionID
                    sFindTip = "Click to go directly to Transaction list view."
                    bSetEditFlagLink = True


                Case "Flagged BudgetItem"
                    sType = "BudgetItem"
                    nKey = nProjectID
                    sFindTip = "Click to go directly to Project JCAF Budget."
                    bSetEditFlagLink = True

                Case "Flagged RFI"
                    sType = "Project"
                    nKey = nProjectID
                    sFindTip = "Click to go directly to Project Overview."
                    bSetEditFlagLink = False

            End Select
            
            If bSetEditFlagLink = True Then
                linkButton.Attributes("onclick") = "return EditFlag('" & nKey & "','" & sType & "','" & sBudgetField & "');"
                linkButton.ToolTip = sAlertToolTip
                linkButton.NavigateUrl = "#"
            End If
                
            ''update the link button to find record
            Dim linkButton3 As ImageButton = CType(item("FindRecord").Controls(0), ImageButton)
            linkButton3.CommandArgument = nContractID & "," & nProjectID & "," & nCollegeID & "," & sAlertType
            linkButton3.ToolTip = sFindTip
            linkButton3.ImageUrl = "images/dashboard_transaction_goto.png"

            Dim localLink As HyperLink = CType(item("AlertType").Controls(0), HyperLink)
            localLink.Attributes("onclick") = "return localNavigation('" & sType & "','" & nKey & "','" & sAlertType & "','" & nCollegeID & "','" & nProjectID & "','" & nContractID & "','" & nTransactionID & "');"
            'localLink.Attributes("onclick") = "return localNavigation('" & sType & "','" & nKey & "','" & sAlertType & "','" & nCollegeID & "','" & nProjectID & "','" & nContractID & "','" & nTransactionID & "','" & nRFIID & "');"
            
                  
        End If
  
    End Sub
    
    Private Sub grid_Alerts_ItemDataBound(ByVal sender As Object, ByVal e As Telerik.Web.UI.GridItemEventArgs) Handles grid_Alerts.ItemDataBound
        
        If (TypeOf e.Item Is GridDataItem) Then
            Dim dataItem As GridDataItem = CType(e.Item, GridDataItem)
            Dim sAlertType As String = dataItem.OwnerTableView.DataKeyValues(dataItem.ItemIndex)("AlertType")
            Dim linkButton As HyperLink = CType(dataItem("Description").Controls(0), HyperLink)
            
            If sAlertType = "Expired Contract" Or sAlertType = "Expired Insurance" Then
                
                'Set the color depending on if alreay expired or not
                Dim sDate As String = Trim(dataItem("AlertInfo").Text)
                If IsDate(sDate) Then
                    Dim dDate As Date = sDate
                    If sDate > Now() Then
                        dataItem("AlertInfo").ForeColor = Color.Purple
                    Else
                        dataItem("AlertInfo").ForeColor = Color.Red
                    End If
                End If

                Dim sDescr As String = linkButton.Text
                dataItem("Description").Controls.Clear()
                dataItem("Description").Text = sDescr
                
            Else
                ''update the link button to open Alert window
                
                Dim sAlert As String = linkButton.Text
                If Len(sAlert) > 50 Then
                    linkButton.Text = Left(sAlert, 50) & "..."
                Else
                    If sAlert = "" Then
                        linkButton.Text = "(none)..."
                    End If

                End If
            End If
  

        End If

    End Sub
    
    Private Function GetAlerts(ByVal AlertView As String) As DataTable

        Using db As New PromptDataHelper
 
            'gets contracts expired or expiring contracts within the next 30 day 
            Dim sql As String = ""
            Dim DistrictID As Integer = HttpContext.Current.Session("DistrictID")

            If AlertView = "" Then
                AlertView = "FlaggedItems"
            End If

            Dim tblAlerts As DataTable = New DataTable
            Dim col As New DataColumn

            col = New DataColumn
            col.DataType = Type.GetType("System.Int32")
            col.ColumnName = "CollegeID"
            tblAlerts.Columns.Add(col)

            col = New DataColumn
            col.DataType = Type.GetType("System.Int32")
            col.ColumnName = "ProjectID"
            tblAlerts.Columns.Add(col)

            col = New DataColumn
            col.DataType = Type.GetType("System.Int32")
            col.ColumnName = "ContractID"
            tblAlerts.Columns.Add(col)

            col = New DataColumn
            col.DataType = Type.GetType("System.String")
            col.ColumnName = "AlertType"
            tblAlerts.Columns.Add(col)

            col = New DataColumn
            col.DataType = Type.GetType("System.String")
            col.ColumnName = "Description"
            tblAlerts.Columns.Add(col)

            col = New DataColumn
            col.DataType = Type.GetType("System.String")
            col.ColumnName = "College"
            tblAlerts.Columns.Add(col)

            col = New DataColumn
            col.DataType = Type.GetType("System.String")
            col.ColumnName = "ProjectName"
            tblAlerts.Columns.Add(col)

            col = New DataColumn
            col.DataType = Type.GetType("System.String")
            col.ColumnName = "AlertInfo"
            tblAlerts.Columns.Add(col)

            'these cols for flags
            col = New DataColumn
            col.DataType = Type.GetType("System.String")
            col.ColumnName = "BudgetField"
            tblAlerts.Columns.Add(col)


            col = New DataColumn
            col.DataType = Type.GetType("System.Int32")
            col.ColumnName = "ContractDetailID"
            tblAlerts.Columns.Add(col)

            col = New DataColumn
            col.DataType = Type.GetType("System.Int32")
            col.ColumnName = "TransactionID"
            tblAlerts.Columns.Add(col)

            col = New DataColumn
            col.DataType = Type.GetType("System.Int32")
            col.ColumnName = "RFIID"
            tblAlerts.Columns.Add(col)

            If AlertView = "AllAlerts" Or AlertView = "ExpiredContracts" Then

                'gets contracts expired or expiring contracts within the next 30 day 
                Dim sDate As String = DateAdd(DateInterval.Day, 31, Now()).ToShortDateString
                sql = "SELECT Contracts.*,Projects.ProjectName,Colleges.College, Contractors.Name AS Contractor  FROM Contracts INNER JOIN Contractors ON Contracts.ContractorID = Contractors.ContractorID "
                sql &= "INNER JOIN Projects ON Contracts.ProjectID = Projects.ProjectID INNER JOIN Colleges ON Projects.CollegeID = Colleges.CollegeID "
                sql &= " WHERE Contracts.Status = '1-Open' AND ExpireDate < '" & sDate & "' AND Contracts.DistrictID = " & DistrictID
                sql &= " ORDER BY ExpireDate "
                Dim tbl As DataTable = db.ExecuteDataTable(sql)
                For Each row As DataRow In tbl.Rows
                    Dim sExpire As String = ProcLib.CheckNullDBField(row("ExpireDate"))
                    Dim newrow As DataRow = tblAlerts.NewRow()

                    newrow("CollegeID") = row("CollegeID")
                    newrow("ProjectID") = row("ProjectID")
                    newrow("BudgetField") = ""
                    newrow("ContractDetailID") = 0
                    newrow("TransactionID") = 0


                    newrow("ContractID") = row("ContractID")
                    newrow("ProjectName") = row("ProjectName")
                    newrow("College") = row("College")

                    newrow("Description") = row("Contractor") & " - " & row("Description")
                    newrow("AlertInfo") = sExpire
                    newrow("AlertType") = "Expired Contract"

                   
                    tblAlerts.Rows.Add(newrow)
                Next

            End If

            If AlertView = "AllAlerts" Or AlertView = "FlaggedItems" Then


                Using dbFlags As New promptFlag
                    Dim tbl As DataTable = dbFlags.GetAllOpenFlags()

                    For Each row As DataRow In tbl.Rows
                        'Dim sExpire As String = ProcLib.CheckNullDBField(row("ExpireDate"))
                        Dim newrow As DataRow = tblAlerts.NewRow()

                        newrow("CollegeID") = row("CollegeID")
                        newrow("ProjectID") = row("ProjectID")
                        newrow("ContractID") = row("ContractID")
                        newrow("BudgetField") = row("BudgetField")
                        newrow("ContractDetailID") = row("ContractDetailID")
                        newrow("TransactionID") = row("TransactionID")

                        newrow("ProjectName") = row("ProjectName")
                        newrow("College") = row("College")

                        newrow("Description") = row("FlagDescription")
                        newrow("AlertInfo") = row("CreatedBy")
                        newrow("AlertType") = "Flagged " & row("FlagType")
                        
                        
                        tblAlerts.Rows.Add(newrow)
                    Next
                End Using

            End If

            If AlertView = "AllAlerts" Or AlertView = "ExpiredInsurance" Then

                'gets contract insurance expired or expiring within the next 60 days
                Dim sDate As String = DateAdd(DateInterval.Day, 61, Now()).ToShortDateString
                                
                sql = "SELECT Contracts.*, Projects.ProjectName, Colleges.College, Contacts.Name AS Contractor, InsurancePolicies.ExpirationDate "
                sql &= "FROM Contracts INNER JOIN "
                sql &= "Contacts ON Contracts.ContractorID = Contacts.ContactID INNER JOIN "
                sql &= "Projects ON Contracts.ProjectID = Projects.ProjectID INNER JOIN "
                sql &= "Colleges ON Projects.CollegeID = Colleges.CollegeID INNER JOIN "
                sql &= "InsurancePolicies ON Contacts.ContactID = InsurancePolicies.ContactID "
                sql &= "WHERE Contracts.Status = '1-Open' AND Contracts.DistrictID = " & DistrictID & " AND InsurancePolicies.ExpirationDate < '" & sDate & "' "
                sql &= "ORDER BY InsurancePolicies.ExpirationDate"

                Dim tbl As DataTable = db.ExecuteDataTable(sql)
                For Each row As DataRow In tbl.Rows
                    Dim sExpire As String = ProcLib.CheckNullDBField(row("ExpirationDate"))
                    Dim newrow As DataRow = tblAlerts.NewRow()

                    newrow("CollegeID") = row("CollegeID")
                    newrow("ProjectID") = row("ProjectID")
                    newrow("BudgetField") = ""
                    newrow("ContractDetailID") = 0
                    newrow("TransactionID") = 0


                    newrow("ContractID") = row("ContractID")
                    newrow("ProjectName") = row("ProjectName")
                    newrow("College") = row("College")

                    newrow("Description") = row("Contractor") & " - " & row("Description")
                    newrow("AlertInfo") = sExpire
                    newrow("AlertType") = "Expired Insurance"

                    
                    tblAlerts.Rows.Add(newrow)
                Next

            End If

            Return tblAlerts
           
                       
        End Using

    End Function
   
 
</script>

<telerik:RadWindowManager ID="AlertPopups" runat="server">
</telerik:RadWindowManager>

<asp:HiddenField ID="testPlace" runat="server" />

<telerik:RadGrid Style="z-index: 100;" ID="grid_Alerts" OnItemCommand="grid_Alerts_ItemCommand"
    runat="server" AllowSorting="True" AutoGenerateColumns="False" GridLines="None"
    Width="99%" enableajax="True" Height="" AllowMultiRowSelection="True" autopostback="true">
    <ClientSettings>
        <Scrolling AllowScroll="True" UseStaticHeaders="True" ScrollHeight="50%" />
    </ClientSettings>
    <MasterTableView Width="98%" GridLines="None" NoMasterRecordsText="No Alerts Found."
        ShowHeadersWhenNoRecords="False" DataKeyNames="AlertType,ContractID,ProjectID,CollegeID,TransactionID,RFIID">
        <Columns>
            
            <telerik:GridButtonColumn ButtonType="ImageButton" Visible="True" CommandName="FindRecord"
                HeaderText="" HeaderTooltip="" UniqueName="FindRecord" Reorderable="False"
                ShowSortIcon="False">
                <ItemStyle Width="20px" HorizontalAlign="Center" VerticalAlign="Top" />
                <HeaderStyle Width="20px" HorizontalAlign="Center" />
            </telerik:GridButtonColumn>
            
            <telerik:GridHyperLinkColumn DataTextField="Description" HeaderText="Description" SortExpression="Description"
                UniqueName="Description">
                <ItemStyle HorizontalAlign="Left" VerticalAlign="Top" Width="40%" />
                <HeaderStyle HorizontalAlign="Left" Width="40%" />
            </telerik:GridHyperLinkColumn>

            <telerik:GridHyperLinkColumn DataTextField="AlertType" UniqueName="AlertType" HeaderText="Type">
                <ItemStyle HorizontalAlign="Left" VerticalAlign="Top" Width="75px" Wrap="false" />
                <HeaderStyle HorizontalAlign="Left" Width="75px" />
            </telerik:GridHyperLinkColumn>
            
            <telerik:GridBoundColumn DataField="AlertInfo" UniqueName="AlertInfo" HeaderText="Info" SortExpression="AlertInfo" >
                <ItemStyle HorizontalAlign="Left" VerticalAlign="Top" Width="100px" Wrap="false" />
                <HeaderStyle HorizontalAlign="Left" Width="100px" />
            </telerik:GridBoundColumn>
            
            <telerik:GridBoundColumn DataField="ProjectName" UniqueName="ProjectName" HeaderText="Project">
                <ItemStyle HorizontalAlign="Left" VerticalAlign="Top" Width="75px" Wrap="false" />
                <HeaderStyle HorizontalAlign="Left" Width="75px" />
            </telerik:GridBoundColumn>
            
            <telerik:GridBoundColumn DataField="College" UniqueName="College" HeaderText="College">
                <ItemStyle Width="75px" HorizontalAlign="Left" VerticalAlign="Top" Wrap="false" />
                <HeaderStyle Width="75px" HorizontalAlign="Left" />
            </telerik:GridBoundColumn>
             
        </Columns>
        <GroupHeaderItemStyle VerticalAlign="Bottom" />
    </MasterTableView>
    <ExportSettings FileName="PromptAlertsExport" OpenInNewWindow="True">
    </ExportSettings>
</telerik:RadGrid>
<telerik:RadToolTipManager ID="RadToolTipManager1" runat="server" Sticky="True" Title=""
    Position="BottomCenter" Skin="Sitefinity" HideDelay="000" ManualClose="False"
    ShowEvent="OnMouseOver" ShowDelay="000" AutoCloseDelay="9000"
    AutoTooltipify="False" Width="350" RelativeTo="Mouse" RenderInPageRoot="False">
</telerik:RadToolTipManager>
<telerik:RadCodeBlock ID="RadCodeBlock1" runat="server">

    <script type="text/javascript" language="javascript">

        function EditFlag(id, parenttype, budgetitem)     //for Flag display -- NOTE THAT DUE TO USER CONTROL NEED REF TO LOCAL WIN MANAGER
        {
            var oManager = $find("<%=AlertPopups.ClientID%>");
            var oWnd = oManager.open('flag_edit.aspx?ParentRecID=' + id + '&ParentRecType=' + parenttype + '&BudgetItem=' + budgetitem + '&WinType=RAD', 'EditFlagWindow');
            return false;

        }

        function localNavigation(idType,id,alertType,college,project,contract,transaction) {
            //alert(idType + ';' + id + ';' + alertType + ';' + college + ';' + project + ';' + contract + ';' + transaction);
            var theTree = parent.getTreeObject();

            switch (alertType) {
                case 'Flagged Project':
                    window.open("project_overview.aspx?view=project&ProjectID=" + project + "&CollegeID=" + college, "ctl00_mainBody_contentPane");
                    var theProject = theTree.findNodeByAttribute("ProjectID", project);
                    ExpandParentNodes(theProject);
                    break;
                case 'Flagged BudgetItem':
                    window.open("budget.aspx?view=project&ProjectID=" + project + "&CollegeID=" + college, "ctl00_mainBody_contentPane");
                    var theProject = theTree.findNodeByAttribute("ProjectID", project);
                    ExpandParentNodes(theProject);
                    break;
                case 'Flagged Contract':
                case 'Expired Contract':
                case 'Expired Insurance':
                    window.open("contract_overview.aspx?view=contract&ContractID=" + contract + "&ProjectID=" + project + "&CollegeID=" + college, "ctl00_mainBody_contentPane");
                    var theContract = theTree.findNodeByAttribute("ContractID", contract);
                    ExpandParentNodes(theContract);
                    break;
                case 'Flagged ChangeOrder':
                    window.open("contract_changeorders.aspx?view=contract&ContractID=" + contract + "&ProjectID=" + project + "&CollegeID=" + college, "ctl00_mainBody_contentPane");
                    var theContract = theTree.findNodeByAttribute("ContractID", contract);
                    ExpandParentNodes(theContract);
                    break;
                case 'Flagged Transaction':
                    window.open("transactions.aspx?view=contract&ContractID=" + contract + "&ProjectID=" + project + "&CollegeID=" + college, "ctl00_mainBody_contentPane");
                    var theContract = theTree.findNodeByAttribute("ContractID", contract);
                    ExpandParentNodes(theContract);
                    break;
                case 'Contract Conversion Flag':
                    window.open("contract_overview.aspx?view=contract&ContractID=" + contract + "&ProjectID=" + project + "&CollegeID=" + college, "ctl00_mainBody_contentPane");
                    var theContract = theTree.findNodeByAttribute("ContractID", contract);
                    ExpandParentNodes(theContract);
                    break;
                case 'Flagged RFI':
                    window.open("RFIs.aspx?view=project&ProjectID=" + project + "&CollegeID=" + college, "ctl00_mainBody_contentPane");
                    var theProject = theTree.findNodeByAttribute("ProjectID", project);
                    ExpandParentNodes(theProject);
                    break;
                default:
                    alert ('Unexpected Alert Type: ' + alertType);
                    break;
            }

        }

        // expand the appropriate nodes to focus on the one in question
        function ExpandParentNodes(node) {
            var theParent = node.get_parent();
            while (theParent.get_level() != 0) {
                theParent.expand();
                theParent = theParent.get_parent();
            }
            theParent.expand();
            node.select();
            //node.scrollIntoView(); // doesn't work!
        }

     
    </script>

</telerik:RadCodeBlock>
