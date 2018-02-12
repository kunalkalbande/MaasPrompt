<%@ Page Language="VB" %>

<%@ Import Namespace="Prompt" %>
<%@ Register Assembly="Telerik.Web.UI" Namespace="Telerik.Web.UI" TagPrefix="telerik" %>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">

<script runat="server">
        
 

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs)
                          
        Session("PageID") = "WorkflowRolesList"
   
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

            .MasterTableView.EnableHeaderContextMenu = True
            .MasterTableView.TableLayout = GridTableLayout.Fixed
            .MasterTableView.AllowMultiColumnSorting = False

            RadGrid1.Height = Unit.Pixel(500)
 
            .ExportSettings.FileName = "PromptTransactionsExport"
            .ExportSettings.OpenInNewWindow = True
            '.ExportSettings.Pdf.PageTitle = masterViewTitle.Text & " Transactions"

        End With
   
        
        'Configure the Popup Window(s)
        With MasterPopups
            .VisibleOnPageLoad = False
            .Skin = "Office2007"
                  
            Dim ww As New RadWindow
            With ww
                .ID = "EditRecord"
                .NavigateUrl = ""
                .Title = ""
                .Width = 600
                .Height = 350
                .Modal = True
                .VisibleStatusbar = False
                .ReloadOnShow = True
                .Behaviors = WindowBehaviors.Close + WindowBehaviors.Move
            End With
            .Windows.Add(ww)
            
        End With
        
        'Configure Add New Button
        butAddNew.Attributes("onclick") = "return EditRecord(this,'" & 0 & "');"
        
        
        
    End Sub
    Protected Sub RadGrid1_NeedDataSource(ByVal source As Object, ByVal e As Telerik.Web.UI.GridNeedDataSourceEventArgs) Handles RadGrid1.NeedDataSource
        'loads the grid whenever it needs data (sorting, rebinding, etc...)
        Using db As New PromptDataHelper
            'gets workflow roles list
            Dim sql As String = "SELECT WorkflowRoles.WorkflowRoleID, WorkflowRoles.WorkflowRole,WorkflowRoles.ApprovalDollarLimit, WorkflowRoles.RoleType,WorkflowRoles.Description, "
            sql &= "Users.UserName, WorkflowRoles.DistrictID FROM WorkflowRoles LEFT OUTER JOIN "
            sql &= "Users ON WorkflowRoles.UserID = Users.UserID "
            sql &= "WHERE WorkflowRoles.DistrictID = " & Session("DistrictID") & " ORDER BY WorkflowRole"
            
            RadGrid1.DataSource = db.ExecuteDataTable(sql)
            
            
        End Using
    End Sub
    
    Protected Sub RadGrid1_ItemCreated(ByVal sender As Object, ByVal e As Telerik.Web.UI.GridItemEventArgs) Handles RadGrid1.ItemCreated
        'This event allows us to customize the cell contents - fired before databound
          
        If (TypeOf e.Item Is GridDataItem) Then
               
            Dim item As GridDataItem = CType(e.Item, GridDataItem)
            Dim nKey As Integer = item.OwnerTableView.DataKeyValues(item.ItemIndex)("WorkflowRoleID")
                          
            'update the link button to open attachments/notes window
            Dim linkButton As HyperLink = CType(item("WorkflowRole").Controls(0), HyperLink)
            linkButton.Attributes("onclick") = "return EditRecord(this,'" & nKey & "');"
            linkButton.ToolTip = "Edit this Role."
            linkButton.NavigateUrl = "#"
          
        End If
             
             
        'If e.Item.OwnerTableView.DataMember = "TablesList" Then
        '    'This looks at the row as it is created and finds the LinkButton control 
        '    'named ViewTransactionInfo and updates the link button so its wired to a 
        '    'Java Script function that calls a RAD window.
        '    If (TypeOf e.Item Is GridDataItem) Then
        '        Dim item As GridDataItem = CType(e.Item, GridDataItem)
        '        Dim strReportName As String = item.OwnerTableView.DataKeyValues(item.ItemIndex)("ReportFileName")
                
        '        'update the link button to open attachments/notes window
        '        Dim linkButton As HyperLink = CType(item("ReportTitle").Controls(0), HyperLink)
        '        linkButton.Attributes("onclick") = "return ShowReport(this,'" & 0 & "', '" & strReportName & "');"
        '        linkButton.ToolTip = "Click on the report title to generate the report"
        '    End If
        'End If
    End Sub
    
    Protected Overrides Sub RaisePostBackEvent(ByVal source As IPostBackEventHandler, ByVal eventArgument As String)
        'Listens for pop window calling to refresh grid after some edit.
        MyBase.RaisePostBackEvent(source, eventArgument)
        If TypeOf source Is RadGrid Then
            Select Case eventArgument
                Case "Rebind"
                    RadGrid1.Rebind()
            End Select
        End If
    End Sub

    Protected Sub butExport_Click(ByVal sender As Object, ByVal e As System.Web.UI.ImageClickEventArgs)
        Me.RadGrid1.MasterTableView.ExportToExcel()
    End Sub  
</script>

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title>Object Codes List </title>
    <link href="Styles.css" rel="stylesheet" type="text/css" />
    <link href="skins/Prompt/Grid.Prompt.css" rel="stylesheet" type="text/css" />
</head>
<body>
    <form id="Form1" method="post" runat="server">
    <telerik:RadScriptManager ID="RadScriptManager1" runat="server" />
    <asp:Table ID="Table1" runat="server" Style="z-index: 102; left: 8px; position: absolute;
        top: 17px" Width="97%">
        <asp:TableRow ID="TableRow1" runat="server">
            <asp:TableCell ID="TableCell1" runat="server" Width="50%" HorizontalAlign="Left">
                <asp:Label ID="Label1" runat="server" Text="Workflow Roles List" Font-Underline="true"></asp:Label>
            </asp:TableCell>
            <asp:TableCell HorizontalAlign="Center">
                <asp:ImageButton ID="butExport" runat="server" ImageUrl="~/images/export_to_excel.png"
                    OnClick="butExport_Click" ToolTip="Export table to Excel." />
            </asp:TableCell>
            <asp:TableCell ID="lblTitle" runat="server" HorizontalAlign="Right">
                <asp:HyperLink ID="butAddNew" runat="server" ImageUrl="images\button_add_new.gif"></asp:HyperLink>
            </asp:TableCell>
        </asp:TableRow>
    </asp:Table>
    <telerik:RadGrid Style="z-index: 100; left: 5px; position: absolute; top: 47px" ID="RadGrid1"
        runat="server" AllowSorting="True" AutoGenerateColumns="False" GridLines="None"
        Width="96%" EnableAJAX="True" Skin="Office2007" Height="80%">
        <ClientSettings>
            <Selecting AllowRowSelect="True" />
            <Scrolling AllowScroll="True" UseStaticHeaders="True" ScrollHeight="80%" />
        </ClientSettings>
        <MasterTableView Width="100%" GridLines="None" DataKeyNames="WorkflowRoleID" NoMasterRecordsText="No Workflow Roles Found.">
            <Columns>
                <telerik:GridHyperLinkColumn DataTextField="WorkflowRole" UniqueName="WorkflowRole"
                    HeaderText="Role" SortExpression="WorkflowRole">
                    <ItemStyle HorizontalAlign="Left" VerticalAlign="top" />
                    <HeaderStyle HorizontalAlign="Left" Width="90px" />
                </telerik:GridHyperLinkColumn>
                <telerik:GridBoundColumn DataField="Description" UniqueName="Description" HeaderText="Description">
                    <ItemStyle HorizontalAlign="Left" />
                    <HeaderStyle HorizontalAlign="Left" Width="35%" />
                </telerik:GridBoundColumn>
                <telerik:GridBoundColumn DataField="UserName" UniqueName="UserName" HeaderText="User">
                    <ItemStyle HorizontalAlign="Left" VerticalAlign="top" />
                    <HeaderStyle HorizontalAlign="Left" Width="90px" />
                </telerik:GridBoundColumn>
                <telerik:GridBoundColumn DataField="RoleType" UniqueName="RoleType" HeaderText="Routing Type">
                    <ItemStyle HorizontalAlign="Left" VerticalAlign="top" />
                    <HeaderStyle HorizontalAlign="Left" Width="90px" />
                </telerik:GridBoundColumn>
                <telerik:GridBoundColumn DataField="ApprovalDollarLimit" UniqueName="ApprovalDollarLimit"
                    HeaderText="Limit" DataFormatString="{0:c}">
                    <ItemStyle HorizontalAlign="Left" VerticalAlign="top" />
                    <HeaderStyle HorizontalAlign="Left" Width="90px" />
                </telerik:GridBoundColumn>
            </Columns>
        </MasterTableView>
    </telerik:RadGrid>
    <telerik:RadWindowManager ID="MasterPopups" runat="server">
    </telerik:RadWindowManager>
    </form>

    <script type="text/javascript" language="javascript">
        // this is the actual script for loading the RAD window popup objects from attribute assigned to page elements
        function EditRecord(oButton, id)     //for editing object code
        {
            //radalert(id);
            var oWnd = window.radopen("workflow_role_edit.aspx?WorkflowRoleID= " + id, "EditRecord");
            return false;
        }


        // to allow popup to call refresh in this form after edit
        function refreshGrid() {
            RadGridNamespace.AsyncRequest('<%= RadGrid1.UniqueID %>', 'Rebind', '<%= RadGrid1.ClientID %>');
        }
      
    </script>

</body>
</html>
