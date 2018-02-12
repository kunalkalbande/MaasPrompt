<%@ Page Language="VB" MasterPageFile="~/prompt.master" Title="Reports Dashboard" %>
<%@ Register Assembly="Telerik.Web.UI" Namespace="Telerik.Web.UI" TagPrefix="telerik" %>
<%@ Import Namespace="Prompt" %>

<script runat="server">
   
   
     Private CurrentProjectFilter As String = ""
    Private CurrentProjectGroupBy As String = ""
   
    Private Sub Page_Load(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MyBase.Load

        ProcLib.CheckSession(Page)
        ProcLib.LoadPopupJscript(Page)

        ''set up help button
        Session("PageID") = "ReportsOnlyDashboard"
        
        'If Request.Browser.Browser = "IE" Then
        RadGrid1.Height = Unit.Pixel(600)
        'Else
        '.Height = Unit.Percentage(88)
        'End If
        
        'Reconfigure some master page elements
        Dim masterMenu As RadMenu = Master.FindControl("RadMenu1")
        masterMenu.FindItemByValue("Reports").Visible = False
        'masterMenu.FindItemByValue("Contacts").Visible = False
        masterMenu.FindItemByValue("Administration").Visible = False
        masterMenu.FindItemByValue("Home").NavigateUrl = "dashboard_reports_only.aspx"

        
        'Set group by Level
        Dim expression As GridGroupByExpression = New GridGroupByExpression
        Dim gridGroupByField As GridGroupByField = New GridGroupByField
        RadGrid1.MasterTableView.GroupByExpressions.Clear()
        
        'Add select fields (before the "Group By" clause)
        gridGroupByField = New GridGroupByField
        gridGroupByField.FieldName = "ReportType"
        gridGroupByField.HeaderText = " "
        gridGroupByField.HeaderValueSeparator = " "
        expression.SelectFields.Add(gridGroupByField)

        'Add a field for group-by (after the "Group By" clause)
        gridGroupByField = New GridGroupByField
        gridGroupByField.FieldName = "ReportType"
        expression.GroupByFields.Add(gridGroupByField)

    
        RadGrid1.MasterTableView.GroupByExpressions.Add(expression)
     
    End Sub
    
    Protected Sub RadGrid1_NeedDataSource(ByVal source As Object, ByVal e As Telerik.Web.UI.GridNeedDataSourceEventArgs) Handles RadGrid1.NeedDataSource
        'loads the grid whenever it needs data (sorting, rebinding, etc...)
        Using db As New promptReport
            RadGrid1.DataSource = db.GetReportsList()
        End Using
        

    End Sub
    
    Protected Sub RadGrid1_ItemCreated(ByVal sender As Object, ByVal e As Telerik.Web.UI.GridItemEventArgs) Handles RadGrid1.ItemCreated
        'This event allows us to customize the cell contents - fired before databound
        
        If (TypeOf e.Item Is GridDataItem) Then
            Dim item As GridDataItem = CType(e.Item, GridDataItem)
            Dim nReportID As Integer = item.OwnerTableView.DataKeyValues(item.ItemIndex)("ReportID")

            'update the link button to open report window
            Dim linkButton As HyperLink = CType(item("ReportTitle").Controls(0), HyperLink)
            linkButton.ToolTip = "Go to selected project."
            linkButton.NavigateUrl = "report_run.aspx?ReportID=" & nReportID
            linkButton.Target = "_new"

        End If
        
    End Sub
    
    Protected Sub RadGrid1_ItemDataBound(ByVal sender As Object, ByVal e As Telerik.Web.UI.GridItemEventArgs) Handles RadGrid1.ItemDataBound
        'This event allows us to customize the cell contents - fired after databound
        
        'If (TypeOf e.Item Is GridDataItem) Then
        '    Dim item As GridDataItem = e.Item
        '    If item("PublishToWeb").Text = "1" Then
        '        item("PublishToWeb").Text = "Y"
        '    Else
        '        item("PublishToWeb").Text = " "
        '    End If

        '    If item("IsPromptProject").Text = "1" Then
        '        item("IsPromptProject").Text = "Y"
        '    Else
        '        item("IsPromptProject").Text = "N"
        '    End If


        'End If
        
        
    End Sub

     
    Private Sub CollapseAll()
        Dim item As GridItem
        For Each item In RadGrid1.MasterTableView.Controls(0).Controls
            If TypeOf item Is GridGroupHeaderItem Then
                item.Expanded = False
            End If
        Next item
    End Sub 'CollapseAll

</script>

<asp:Content ID="Content1" ContentPlaceHolderID="mainBody" runat="Server">

    <script type="text/javascript" language="javascript">

        function GetRadWindow() {
            var oWindow = null;
            if (window.RadWindow) oWindow = window.RadWindow;
            else if (window.frameElement.radWindow) oWindow = window.frameElement.radWindow;
            return oWindow;
        }

    </script>

<asp:Image ID="Image1" runat="server" ImageUrl="images/reports.png" Style="margin:5px 10px;position:relative;top:10px;left:0;" /><asp:Label ID="lblPageTitle" runat="server" CssClass="college_lbl">Reports</asp:Label><br /><br />

    <telerik:RadGrid ID="RadGrid1" runat="server" AllowSorting="True" AutoGenerateColumns="False"
        GridLines="None" Width="100%" EnableAJAX="True" Height="90%" Skin="Sitefinity">
        <ClientSettings>
            <Selecting AllowRowSelect="True" />
            <Scrolling AllowScroll="True" UseStaticHeaders="True" ScrollHeight="50%" SaveScrollPosition="true" />
        </ClientSettings>
        <MasterTableView Width="100%" GridLines="None" DataKeyNames="ReportID" NoMasterRecordsText="No Reports available.">
            <Columns>
                <telerik:GridHyperLinkColumn UniqueName="ReportTitle" HeaderText="Title" DataTextField="ReportTitle">
                    <ItemStyle HorizontalAlign="Left" Width="30%" VerticalAlign="Top" />
                    <HeaderStyle HorizontalAlign="Left" Width="30%" />
                </telerik:GridHyperLinkColumn>
                <telerik:GridBoundColumn UniqueName="Description" HeaderText="Description" DataField="Description">
                    <ItemStyle HorizontalAlign="Left" Width="65%" VerticalAlign="Top" />
                    <HeaderStyle HorizontalAlign="Left" Width="65%" />
                </telerik:GridBoundColumn>
                <telerik:GridBoundColumn UniqueName="ReportNumber" HeaderText="Number" DataField="ReportNumber">
                    <ItemStyle HorizontalAlign="Left" Width="55" VerticalAlign="Top" />
                    <HeaderStyle HorizontalAlign="Left" Width="55" />
                </telerik:GridBoundColumn>
            </Columns>
        </MasterTableView>
    </telerik:RadGrid>
</asp:Content>
