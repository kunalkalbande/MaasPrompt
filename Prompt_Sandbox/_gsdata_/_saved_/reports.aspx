<%@ Page Language="VB" MasterPageFile="~/prompt.master" Title="Welcome to Prompt" %>

<%@ Register Assembly="Telerik.Web.UI" Namespace="Telerik.Web.UI" TagPrefix="telerik" %>
<%@ Import Namespace="Prompt" %>

<script runat="server">
   
    Private CurrentProjectFilter As String = ""
    Private CurrentProjectGroupBy As String = ""
   
    Private Sub Page_Load(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MyBase.Load

        ProcLib.CheckSession(Page)

        ''set up help button
        Session("PageID") = "Reports"
        
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

    <script src="js/jquery-1.3.2.min.js" type="text/javascript"></script>
    
    <script type="text/javascript">
        jQuery(function() {
        $('a:contains(Audit & Finance Report),a:contains(CBOC Project Summary),a:contains(CBOC Whole Measure C),a:contains(FHDA CBOC Category-based report),a:contains(FHDA CBOC Individual Projects Update Report),a:contains(FHDA CBOC Quarterly Report)')
            .bind('click', function(event) { alert("This report will generate data based on current (live) data in Prompt, therefore it will not reflect the data on past reports submitted at CBOC meetings.  \n\nYou can download historical versions of this report from Prompt by clicking on “District” and then on the “Attachments” tab.  Once there,  click on folder called “CBOC Meeting Reports” to select and download the report(s) you need."); });
        // Audit and Finance STATIC report removed from access per Rafael 10/28/2010
        //$("a[title='Audit & Finance Report (LIVE)']")
        //    .bind('click', function(event) { alert('Note:\n\nThis report contains up to the minute data including transactions posted thru the moment you run the report. It also contains budget transfers made to date.\n\nTo view data relevant to the CBOC time period only (before close date) please select the report called "Audit and Finance Report (STATIC)".'); });
        //$("a[title='Audit & Finance Report (STATIC)']")
        //    .bind('click', function(event) { alert('Note:\n\nThis report contains data relevant to the most recent CBOC meeting (June 15, 2010) only. \n\nCurrently this report shows data for the 3rd quarter of FY2009-2010 (thru March 31, 2010).'); });

        //8/25/10 - roy - added code to run "alternate" (new) reports side-by-side with old (existing) reports for test purposes
        $('a[href^="report_run.aspx"]') 
            .bind('click', function(event) {
                if (event.altKey) {
                    alert('Warning: this will run the ALT-ernate report (usually a report under test).');
                    window.open(event.currentTarget.href.toString() + '&NEW=y');
                    //alert(event.currentTarget.href.toString());
                    event.preventDefault();
                }
            }
        )
    });
    
    
    
    </script>
    
</asp:Content>
