<%@ Page Language="VB" %>

<%@ Register Assembly="Telerik.Web.UI" Namespace="Telerik.Web.UI" TagPrefix="telerik" %>
<%@ Import Namespace="Prompt" %>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">

<script runat="server">
    
    Private TransactionList As String = ""
    Private Source As String = ""
    Private CalledFromDashboard As Boolean = False
    Private CurrentView As String = ""
    
    'This page is used to approve multiple transactions in a single shot
    'TODO: THIS PROCESS NEEDS WORK -- 
         
    
    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs)
        
        If Request.QueryString("CalledFrom") = "Dashboard" Then   'flag to allow refresh of grid in calling page
            CalledFromDashboard = True
        End If
        
        TransactionList = Request.QueryString("TransactionList")
        If Right(TransactionList, 1) = "," Then
            TransactionList = Mid(TransactionList, 1, Len(TransactionList) - 1)   'get rid of trailing comma
        End If
        Source = Request.QueryString("Source")
        CurrentView = Request.QueryString("CurrentView")

        lblAlert.Text = ""
       
        If Not IsPostBack Then

            'load the data
            Using db As New promptWorkflow
                db.CallingPage = Page
                'db.TransactionID = TransactionID
                db.LoadRoutingTargetListBoxes()


                'enable certain fields for some roles
                Select Case Session("WorkflowRoleType")

                    Case "District AP"
                        'add some default picks for approval
                        Dim item As New ListItem
                        item.Text = "Ready To Transfer"
                        item.Value = -100
                        item.Selected = True
                        'lstApproveTarget.Items.Add(item)


                End Select

                ''Check that scenerio contains at least one owner that as authority for transaction $$ amount
                'If db.MaxDollarApprovalLevel < db.TransactionTotalAmount Then
                '    msg = "Sorry, There are no Workflow Owners that have approval level for this Trasnaction Amount."

                'End If


            End Using

        End If
   
                 
    End Sub
    
    Protected Sub RadGrid1_NeedDataSource(ByVal source As Object, ByVal e As Telerik.Web.UI.GridNeedDataSourceEventArgs) Handles RadGrid1.NeedDataSource
        'loads the grid whenever it needs data (sorting, rebinding, etc...)
        
        Using db As New promptWorkflow
            db.CallingPage = Page
            RadGrid1.DataSource = db.GetSelectedWorkflowTransactionsForApproval(TransactionList)
        End Using
           
    End Sub
    Protected Sub butSave_Click(ByVal sender As Object, ByVal e As System.Web.UI.ImageClickEventArgs)
        Using db As New promptWorkflow
            'Approve all transactions and route
            For Each item As GridDataItem In RadGrid1.MasterTableView.Items
                With db
                    .CallingPage = Page
                    .IsMultiApproval = True
                    .Action = "Approved"
                    .TransactionID = item.GetDataKeyValue("TransactionID").ToString
                    .Target = item.GetDataKeyValue("TargetRole").ToString
                    .TargetRoleID = item.GetDataKeyValue("TargetRoleID").ToString

                End With
                db.RouteTransaction()
            Next
         
        End Using

        If CalledFromDashboard = False Then  'only update parent form when called from within PROMPT
            lblAlert.Text = "<script>UpdateParentPage()</" + "script>"   'calls a function in parent form that updates control via ajax
            Session("RtnFromEdit") = True
            ProcLib.CloseOnlyRAD(Page)
        Else
            Session("RtnFromEdit") = True
            ProcLib.CloseAndRefreshRAD(Page)
        End If

    End Sub

    Protected Sub butClose_Click1(ByVal sender As Object, ByVal e As System.Web.UI.ImageClickEventArgs)
        ProcLib.CloseOnlyRAD(Page)
    End Sub

  
</script>

<html>
<head>
    <title>Approve Multiple Transactions</title>
    <link href="Styles.css" type="text/css" rel="stylesheet" />

    <script type="text/javascript" language="javascript">

        function GetRadWindow() {
            var oWindow = null;
            if (window.RadWindow) oWindow = window.RadWindow;
            else if (window.frameElement.radWindow) oWindow = window.frameElement.radWindow;
            return oWindow;
        }


        function confirmCallBackFn(arg) {
            alert(arg);
        }

        function promptCallBackFn(arg) {
            alert(arg);
        }

        function UpdateParentPage()
        //This call is used when record saved to update specific control on calling page -
        //in this case it is the HandleAjaxPostbackFromWorkflowPopup method on the calling page
        {
            GetRadWindow().BrowserWindow.HandleAjaxPostbackFromWorkflowPopup();
        }

    </script>

</head>
<body>
    <form id="Form1" method="post" runat="server">
    <telerik:RadScriptManager ID="RadScriptManager1" runat="server" />
    <asp:HyperLink ID="butHelp" runat="server" Style="z-index: 113; left: 360px; position: absolute;
        top: 6px; height: 14px;" ImageUrl="images/button_help.gif">HyperLink</asp:HyperLink>
    <asp:ImageButton ID="butSave" runat="server" ImageUrl="images/button_route.gif" Style="z-index: 106;
        left: 15px; position: absolute; top: 326px" TabIndex="6" OnClick="butSave_Click" />
    <telerik:RadWindowManager ID="RadPopups" runat="server" Skin="Office2007">
    </telerik:RadWindowManager>
    <%--for handling alerts and ajax callback--%>
    <telerik:RadGrid Style="z-index: 100; left: 5px; position: absolute; top: 36px; height: 263px;"
        ID="RadGrid1" runat="server" AllowSorting="True" AutoGenerateColumns="False"
        GridLines="None" Width="98%" enableajax="True" Skin="Vista">
        <ClientSettings>
            <Scrolling AllowScroll="True" UseStaticHeaders="True" ScrollHeight="15%" />
            <Selecting AllowRowSelect="true" />
            <Resizing AllowColumnResize="True" />
        </ClientSettings>
        <MasterTableView Width="98%" GridLines="None" NoMasterRecordsText="No Transactions Found."
            ShowHeadersWhenNoRecords="False" DataKeyNames="TransactionID,TargetRoleID,TargetRole">
            <Columns>
                <telerik:GridBoundColumn HeaderText="Contractor" UniqueName="Contractor" DataField="Contractor">
                    <ItemStyle HorizontalAlign="Left" Width="65px" Wrap="true" VerticalAlign="Top" />
                    <HeaderStyle HorizontalAlign="Left" Width="65px" Wrap="true" VerticalAlign="Top" />
                </telerik:GridBoundColumn>
                <telerik:GridBoundColumn DataField="InvoiceNumber" HeaderText="Inv#" UniqueName="InvoiceNumber">
                    <ItemStyle HorizontalAlign="Center" Width="65px" Wrap="false" VerticalAlign="Top" />
                    <HeaderStyle HorizontalAlign="Center" Width="65px" Wrap="false" />
                </telerik:GridBoundColumn>
                <telerik:GridBoundColumn DataField="TotalAmount" HeaderText="Total" UniqueName="TotalAmount"
                    DataFormatString="{0:c}">
                    <ItemStyle Width="70px" HorizontalAlign="Right" VerticalAlign="Top" />
                    <HeaderStyle Width="70px" HorizontalAlign="Right" />
                </telerik:GridBoundColumn>
                <telerik:GridBoundColumn DataField="TargetRole" HeaderText="RouteTo" UniqueName="TargetRole">
                    <ItemStyle HorizontalAlign="Center" Width="50%" Wrap="false" VerticalAlign="Top" />
                    <HeaderStyle HorizontalAlign="Center" Width="50%" Wrap="false" />
                </telerik:GridBoundColumn>
            </Columns>
            <ExpandCollapseColumn Resizable="False">
                <HeaderStyle Width="20px" />
            </ExpandCollapseColumn>
            <RowIndicatorColumn Visible="False">
                <HeaderStyle Width="20px" />
            </RowIndicatorColumn>
        </MasterTableView>
    </telerik:RadGrid>
    &nbsp;
    <asp:Label ID="lblApprove" runat="server" Height="24px" Style="z-index: 112; left: 8px;
        position: absolute; top: 12px">Approve these transactions and route as specified:</asp:Label>
    <asp:Label ID="lblAlert" runat="server" Height="24px" Style="z-index: 112; left: 20px;
        position: absolute; top: 363px"></asp:Label>
    <asp:ImageButton ID="butClose" runat="server" ImageUrl="images/button_cancel.gif"
        Style="z-index: 105; left: 203px; position: absolute; top: 329px" TabIndex="6"
        OnClick="butClose_Click1" />
    </form>
</body>
</html>
