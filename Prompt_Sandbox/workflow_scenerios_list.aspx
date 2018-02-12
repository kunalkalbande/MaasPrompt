<%@ Page Language="VB" %>

<%@ Import Namespace="Prompt" %>
<%@ Register Assembly="Telerik.Web.UI" Namespace="Telerik.Web.UI" TagPrefix="telerik" %>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">

<script runat="server">
        
 

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs)
                          
        Session("PageID") = "WorkflowSceneriosList"
  
        
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
                .ID = "EditScenerio"
                .NavigateUrl = ""
                .Title = ""
                .Width = 600
                .Height = 250
                .Modal = True
                .VisibleStatusbar = False
                .ReloadOnShow = True
                .Behaviors = WindowBehaviors.Close + WindowBehaviors.Move
            End With
            .Windows.Add(ww)
            
        
            ww = New RadWindow
            With ww
                .ID = "EditOwner"
                .NavigateUrl = ""
                .Title = ""
                .Width = 620
                .Height = 550
                .Modal = True
                .VisibleStatusbar = False
                .ReloadOnShow = True
                .Behaviors = WindowBehaviors.Close + WindowBehaviors.Move
            End With
            .Windows.Add(ww)
            
        End With
        
        'Configure Add New Button
        butAddNew.Attributes("onclick") = "return EditScenerio(this,'" & 0 & "');"
        
        
        
    End Sub
    Protected Sub RadGrid1_NeedDataSource(ByVal source As Object, ByVal e As Telerik.Web.UI.GridNeedDataSourceEventArgs) Handles RadGrid1.NeedDataSource
        
        Using db As New PromptDataHelper
            'gets workflow roles list
            Dim sql As String = ""
            sql = "SELECT * FROM WorkFLowScenerios WHERE DistrictID = " & HttpContext.Current.Session("DistrictID") & " ORDER BY ScenerioName "
            RadGrid1.MasterTableView.DataSource = db.ExecuteDataTable(sql)
        End Using
    End Sub
    
    Private Sub RadGrid1_DetailTableDataBind(ByVal source As Object, ByVal e As Telerik.Web.UI.GridDetailTableDataBindEventArgs) Handles RadGrid1.DetailTableDataBind
        Dim nKey As Integer = 0
        Dim dataItem As GridDataItem = CType(e.DetailTableView.ParentItem, GridDataItem)
        nKey = dataItem.GetDataKeyValue("WorkflowScenerioID")
        Using db As New PromptDataHelper
            'gets workflow owners list
            Dim sql As String = ""
            sql = "SELECT WorkflowScenerioOwners.*, WorkflowRoles.WorkflowRole + ' (' + Users.UserName + ')' as OwnerName "
            sql &= "FROM WorkflowScenerioOwners INNER JOIN WorkflowRoles ON WorkflowScenerioOwners.WorkflowRoleID = WorkflowRoles.WorkflowRoleID "
            sql &= "INNER JOIN Users ON WorkflowRoles.UserID = Users.UserID "
            sql &= "WHERE WorkflowScenerioID = " & nKey & " ORDER BY IsOriginator Desc, OwnerName "
            Dim tbl As DataTable = db.ExecuteDataTable(sql)

            'Add column to table with list of approval targets
            Dim colApprovalTargets As New DataColumn("ApprovalTargets", System.Type.GetType("System.String"))
            tbl.Columns.Add(colApprovalTargets)
            For Each row As DataRow In tbl.Rows
                sql = "SELECT TargetRoleName FROM WorkflowScenerioOwnerTargets WHERE WorkflowScenerioOwnerID = " & row("WorkflowScenerioOwnerID") & " "
                sql &= "AND TargetAction = 'Approved' ORDER BY Priority "
                Dim sTargetList As String = ""
                db.FillReader(sql)
                While db.Reader.Read
                    sTargetList &= db.Reader("TargetRoleName") & "<br>"
                End While
                db.Close()
                row("ApprovalTargets") = sTargetList
            Next

            'Add column to table with list of reject targets
            Dim colRejectTargets As New DataColumn("RejectTargets", System.Type.GetType("System.String"))
            tbl.Columns.Add(colRejectTargets)
            For Each row As DataRow In tbl.Rows
                sql = "SELECT TargetRoleName FROM WorkflowScenerioOwnerTargets WHERE WorkflowScenerioOwnerID = " & row("WorkflowScenerioOwnerID") & " "
                sql &= "AND TargetAction = 'Rejected' ORDER BY TargetRoleName "
                Dim sTargetList As String = ""
                db.FillReader(sql)
                While db.Reader.Read
                    sTargetList &= db.Reader("TargetRoleName") & "<br>"
                End While
                db.Close()
                row("RejectTargets") = sTargetList
            Next
            
            e.DetailTableView.DataSource = tbl
        End Using
    End Sub

    
    Protected Sub RadGrid1_ItemCreated(ByVal sender As Object, ByVal e As Telerik.Web.UI.GridItemEventArgs) Handles RadGrid1.ItemCreated
        'This event allows us to customize the cell contents - fired before databound
        If e.Item.OwnerTableView.DataMember = "WorkflowScenerio" Then
            If (TypeOf e.Item Is GridDataItem) Then
               
                Dim item As GridDataItem = CType(e.Item, GridDataItem)
                Dim nKey As Integer = item.OwnerTableView.DataKeyValues(item.ItemIndex)("WorkflowScenerioID")
                          
                'update the link button to open edit window
                Dim linkButton As HyperLink = CType(item("ScenerioName").Controls(0), HyperLink)
                linkButton.Attributes("onclick") = "return EditScenerio(this,'" & nKey & "');"
                linkButton.NavigateUrl = "#"
                linkButton.ToolTip = "Edit this Scenerio."
                            
                'update the link button to open edit window
                Dim linkButton1 As HyperLink = CType(item("AddOwner").Controls(0), HyperLink)
                linkButton1.Attributes("onclick") = "return AddOwner('" & nKey & "');"
                linkButton1.ToolTip = "Add a Owner to this Scenerio."
                linkButton1.ImageUrl = "images/add_scenerio_step.gif"
          
            End If
             
        End If
        If e.Item.OwnerTableView.DataMember = "WorkflowScenerioOwners" Then 'child view  
            
            If (TypeOf e.Item Is GridDataItem) Then
               
                Dim item As GridDataItem = CType(e.Item, GridDataItem)
                Dim nKey As Integer = item.OwnerTableView.DataKeyValues(item.ItemIndex)("WorkflowScenerioOwnerID")
                Dim nScenerioID As Integer = item.OwnerTableView.DataKeyValues(item.ItemIndex)("WorkflowScenerioID")
                          
                'update the link button to open edit window
                Dim linkButton As HyperLink = CType(item("OwnerName").Controls(0), HyperLink)
                linkButton.Attributes("onclick") = "return EditOwner('" & nKey & "','" & nScenerioID & "');"
                linkButton.ToolTip = "Edit this Owner."
                linkButton.NavigateUrl = "#"
            
          
            End If
            
 
        End If
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
    <title>Workflow Scenerios List </title>
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
                <asp:Label ID="Label1" runat="server" Text="Workflow Scenerios List" Font-Underline="true"></asp:Label>
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
        Width="96%" EnableAJAX="True" Skin="Vista" Height="80%" DataMember="WorkflowScenerio"
        OnDetailTableDataBind="RadGrid1_DetailTableDataBind" OnNeedDataSource="RadGrid1_NeedDataSource">
        <ClientSettings>
            <Selecting AllowRowSelect="True" />
            <Scrolling AllowScroll="True" UseStaticHeaders="True" ScrollHeight="80%" />
        </ClientSettings>
        <MasterTableView Width="100%" GridLines="None" DataKeyNames="WorkflowScenerioID"
            NoMasterRecordsText="No Workflow Scenerio Found." DataMember="WorkflowScenerio">
            <DetailTables>
                <telerik:GridTableView DataKeyNames="WorkflowScenerioID,WorkflowScenerioOwnerID"
                    Width="100%" runat="server" Name="WorkflowScenerioOwners" DataMember="WorkflowScenerioOwners"
                    NoDetailRecordsText="No Owner Records Found." ShowHeadersWhenNoRecords="false">
                    <Columns>
                       <%-- <telerik:GridBoundColumn DataField="WorkflowScenerioOwnerID" UniqueName="WorkflowScenerioOwnerID"
                            HeaderText="WorkflowScenerioOwnerID" Visible="False">
                            <ItemStyle HorizontalAlign="Left" />
                            <HeaderStyle HorizontalAlign="Left" Width="90px" />
                        </telerik:GridBoundColumn>--%>
  
                        <telerik:GridHyperLinkColumn DataTextField="OwnerName" UniqueName="OwnerName" HeaderText="Owner" SortExpression="OwnerName">
                            <ItemStyle HorizontalAlign="Left" VerticalAlign="Top" />
                            <HeaderStyle HorizontalAlign="Left" />
                        </telerik:GridHyperLinkColumn>
                        <telerik:GridBoundColumn DataField="ApprovalTargets" UniqueName="ApprovalTargets"
                            HeaderText="ApprovalTarget(s)">
                            <ItemStyle HorizontalAlign="Left" VerticalAlign="Top" />
                            <HeaderStyle HorizontalAlign="Left" />
                        </telerik:GridBoundColumn>
                        <telerik:GridBoundColumn DataField="RejectTargets" UniqueName="RejectTargets" HeaderText="RejectTarget(s)">
                            <ItemStyle HorizontalAlign="Left" VerticalAlign="Top" />
                            <HeaderStyle HorizontalAlign="Left" />
                        </telerik:GridBoundColumn>
                        <telerik:GridBoundColumn DataField="IsSignator" UniqueName="IsSignator" HeaderText="Signator">
                            <ItemStyle HorizontalAlign="Left" VerticalAlign="Top" />
                            <HeaderStyle HorizontalAlign="Left" />
                        </telerik:GridBoundColumn>
                        <telerik:GridBoundColumn DataField="IsOriginator" UniqueName="IsOriginator" HeaderText="IsOriginator">
                            <ItemStyle HorizontalAlign="Left" VerticalAlign="Top" />
                            <HeaderStyle HorizontalAlign="Left" />
                        </telerik:GridBoundColumn>
                    </Columns>
                    <RowIndicatorColumn Visible="False">
                        <HeaderStyle Width="20px" />
                    </RowIndicatorColumn>
                    <ExpandCollapseColumn Resizable="False" Visible="False">
                        <HeaderStyle Width="20px" />
                    </ExpandCollapseColumn>
                </telerik:GridTableView>
            </DetailTables>
            <Columns>
 <%--               <telerik:GridBoundColumn DataField="WorkflowScenerioID" UniqueName="WorkflowScenerioID"
                    HeaderText="WorkflowScenerioID" Visible="False">
                    <ItemStyle HorizontalAlign="Left" />
                    <HeaderStyle HorizontalAlign="Left" Width="90px" />
                </telerik:GridBoundColumn>--%>
   <%--             <telerik:GridHyperLinkColumn UniqueName="Edit">
                    <ItemStyle Width="35px" HorizontalAlign="Center" VerticalAlign="Top" />
                    <HeaderStyle Width="35px" HorizontalAlign="Center" />
                </telerik:GridHyperLinkColumn>--%>
                <telerik:GridHyperLinkColumn DataTextField="ScenerioName" UniqueName="ScenerioName" HeaderText="Name" SortExpression="ScenerioName">
                    <ItemStyle HorizontalAlign="Left" VerticalAlign="Top" />
                    <HeaderStyle HorizontalAlign="Left" Width="90px" />
                </telerik:GridHyperLinkColumn>
                <telerik:GridBoundColumn DataField="Description" UniqueName="Description" HeaderText="Description">
                    <ItemStyle HorizontalAlign="Left" />
                    <HeaderStyle HorizontalAlign="Left" Width="35%" />
                </telerik:GridBoundColumn>
                <telerik:GridBoundColumn DataField="AppliesTo" UniqueName="AppliesTo" HeaderText="Type">
                    <ItemStyle HorizontalAlign="Left" />
                    <HeaderStyle HorizontalAlign="Left" Width="35%" />
                </telerik:GridBoundColumn>
                <telerik:GridHyperLinkColumn HeaderText="Owner" UniqueName="AddOwner">
                    <ItemStyle Width="55px" HorizontalAlign="Center" VerticalAlign="Top" />
                    <HeaderStyle Width="55px" HorizontalAlign="Center" />
                </telerik:GridHyperLinkColumn>
            </Columns>
            <RowIndicatorColumn Visible="False">
                <HeaderStyle Width="20px" />
            </RowIndicatorColumn>
            <ExpandCollapseColumn Resizable="False">
                <HeaderStyle Width="20px" />
            </ExpandCollapseColumn>
        </MasterTableView>
    </telerik:RadGrid>
    <telerik:RadWindowManager ID="MasterPopups" runat="server">
    </telerik:RadWindowManager>
    </form>

    <script type="text/javascript" language="javascript">
        // this is the actual script for loading the RAD window popup objects from attribute assigned to page elements
        function EditScenerio(oButton, id)     //for editing object code
        {
            var oWnd = window.radopen("workflow_scenerio_edit.aspx?WorkflowScenerioID= " + id, "EditScenerio");
            return false;
        }

        function AddOwner(id)     //for adding/Editing workflow Owner
        {
            var oWnd = window.radopen("workflow_scenerio_owner_edit.aspx?WorkflowScenerioOwnerID=0&WorkflowScenerioID= " + id, "EditOwner");
            return false;
        }

        function EditOwner(id, scenerioID)     //for adding/Editing workflow Owner
        {
            var oWnd = window.radopen("workflow_scenerio_owner_edit.aspx?WorkflowScenerioID=" + scenerioID + "&WorkflowScenerioOwnerID= " + id, "EditOwner");
            return false;
        }


        // to allow popup to call refresh in this form after edit
        function refreshGrid() {
            RadGridNamespace.AsyncRequest('<%= RadGrid1.UniqueID %>', 'Rebind', '<%= RadGrid1.ClientID %>');
        }
      
    </script>

</body>
</html>
