<%@ Page Language="VB" %>

<%@ Import Namespace="Prompt" %>
<%@ Register Assembly="Telerik.Web.UI" Namespace="Telerik.Web.UI" TagPrefix="telerik" %>

<script runat="server">
        
    Dim CurrentView As String = ""

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs)
                          
        Session("PageID") = "UserActivity"
        
        'Set Grid Properties
        With RadGrid1
            .EnableEmbeddedSkins = False
            .Skin = "Prompt"
            .GroupingEnabled = True
            .AllowSorting = False
                        
            .ClientSettings.AllowColumnsReorder = False
            .ClientSettings.ColumnsReorderMethod = GridClientSettings.GridColumnsReorderMethod.Reorder
            .ClientSettings.Scrolling.AllowScroll = True
            .ClientSettings.Scrolling.ScrollHeight = Unit.Percentage(50)
            .ClientSettings.Scrolling.UseStaticHeaders = True
            .ClientSettings.Resizing.AllowColumnResize = True

            .MasterTableView.EnableHeaderContextMenu = False
            .MasterTableView.TableLayout = GridTableLayout.Fixed
            .MasterTableView.AllowMultiColumnSorting = False

            .Height = Unit.Pixel(600)

            .ExportSettings.FileName = "PromptUserActivityExport"
            .ExportSettings.OpenInNewWindow = True
            
        End With
        
        ''Set group by 
        'Dim expression As GridGroupByExpression = New GridGroupByExpression
        'Dim gridGroupByField As GridGroupByField = New GridGroupByField
        'RadGrid1.MasterTableView.GroupByExpressions.Clear()
        ''Add select fields (before the "Group By" clause)
        'gridGroupByField = New GridGroupByField
        'gridGroupByField.FieldName = "UserName"
        'gridGroupByField.HeaderText = " "
        'gridGroupByField.HeaderValueSeparator = " "
        'expression.SelectFields.Add(gridGroupByField)

        ''Add a field for group-by (after the "Group By" clause)
        'gridGroupByField = New GridGroupByField
        'gridGroupByField.FieldName = "UserName"
        'expression.GroupByFields.Add(gridGroupByField)

        'RadGrid1.MasterTableView.GroupByExpressions.Add(expression)
        
        If Not IsPostBack Then
            Using db As New promptSysUtils
                db.LoadSessionActivityCombo(lstFilter)
            End Using

        End If
        
        If CurrentView = "" Then CurrentView = "SummaryLast2Hours"
        
        SetCurrentView()
        
         
        ''Configure the Popup Window(s)
        'With MasterPopups
        '    .VisibleOnPageLoad = False
        '    .Skin = "Office2007"

        '    Dim ww As New RadWindow
        '    With ww
        '        .ID = "EditRecord"
        '        .NavigateUrl = ""
        '        .Title = ""
        '        .Width = 600
        '        .Height = 350
        '        .Modal = True
        '        .VisibleStatusbar = True
        '        .ReloadOnShow = True
        '    End With
        '    .Windows.Add(ww)
        '    .Windows("EditRecord").Behavior = RadWindowBehaviorFlags.Close + RadWindowBehaviorFlags.Move + RadWindowBehaviorFlags.Resize
        'End With

        ''Configure Add New Button
        'butAddNew.Attributes("onclick") = "return EditRecord(this,'" & 0 & "');"
        
        
        
    End Sub
    
    Private Sub SetCurrentView()
       
        Select Case CurrentView

            Case "SummaryLast2Hours"   'default to idle minutes
                RadGrid1.MasterTableView.Columns.FindByUniqueName("LastActivity").HeaderText = "Last Activity (Minutes)"
                RadGrid1.MasterTableView.Columns.FindByUniqueName("UserName").Visible = True
                RadGrid1.MasterTableView.Columns.FindByUniqueName("LastOn").Visible = False
                RadGrid1.MasterTableView.Columns.FindByUniqueName("Duration").Visible = False
                RadGrid1.MasterTableView.Columns.FindByUniqueName("ActivityStart").Visible = False
                RadGrid1.MasterTableView.Columns.FindByUniqueName("ActivityEnd").Visible = False
                RadGrid1.MasterTableView.Columns.FindByUniqueName("ActivityDate").Visible = False
                RadGrid1.MasterTableView.Columns.FindByUniqueName("PageViews").Visible = False

            Case Else
                
                If CurrentView.Contains("UserDetail") Then
                    RadGrid1.MasterTableView.Columns.FindByUniqueName("UserName").Visible = False
                    RadGrid1.MasterTableView.Columns.FindByUniqueName("LastActivity").Visible = False
                    RadGrid1.MasterTableView.Columns.FindByUniqueName("Duration").Visible = True
                    RadGrid1.MasterTableView.Columns.FindByUniqueName("ActivityStart").Visible = True
                    RadGrid1.MasterTableView.Columns.FindByUniqueName("ActivityEnd").Visible = True
                    RadGrid1.MasterTableView.Columns.FindByUniqueName("ActivityDate").Visible = True
                    RadGrid1.MasterTableView.Columns.FindByUniqueName("PageViews").Visible = True
                    
                Else
                    RadGrid1.MasterTableView.Columns.FindByUniqueName("UserName").Visible = True
                    RadGrid1.MasterTableView.Columns.FindByUniqueName("LastActivity").HeaderText = "Last Activity"
                    RadGrid1.MasterTableView.Columns.FindByUniqueName("LastActivity").Visible = True
                    RadGrid1.MasterTableView.Columns.FindByUniqueName("LastOn").Visible = False
                    RadGrid1.MasterTableView.Columns.FindByUniqueName("Duration").Visible = False
                    RadGrid1.MasterTableView.Columns.FindByUniqueName("ActivityStart").Visible = False
                    RadGrid1.MasterTableView.Columns.FindByUniqueName("ActivityEnd").Visible = False
                    RadGrid1.MasterTableView.Columns.FindByUniqueName("ActivityDate").Visible = False
                    RadGrid1.MasterTableView.Columns.FindByUniqueName("PageViews").Visible = False
                    
                End If
                
                
                
   
        End Select

    End Sub
    
    Protected Sub RadGrid1_NeedDataSource(ByVal source As Object, ByVal e As Telerik.Web.UI.GridNeedDataSourceEventArgs) Handles RadGrid1.NeedDataSource
        'loads the grid whenever it needs data (sorting, rebinding, etc...)
        Using db As New promptSysUtils
            db.CallingPage = Page
            RadGrid1.DataSource = db.GetUserSessionActivity(CurrentView)

        End Using
    End Sub
    
    Protected Sub RadGrid1_ItemCreated(ByVal sender As Object, ByVal e As Telerik.Web.UI.GridItemEventArgs) Handles RadGrid1.ItemCreated
        ''This event allows us to customize the cell contents - fired before databound

        'If (TypeOf e.Item Is GridDataItem) Then

        '    Dim item As GridDataItem = CType(e.Item, GridDataItem)
        '    Dim nKey As Integer = item.OwnerTableView.DataKeyValues(item.ItemIndex)("WorkflowRoleID")

        '    'update the link button to open attachments/notes window
        '    Dim linkButton As HyperLink = CType(item("Edit").Controls(0), HyperLink)
        '    linkButton.Attributes("onclick") = "return EditRecord(this,'" & nKey & "');"
        '    linkButton.ToolTip = "Edit this Role."
        '    linkButton.ImageUrl = "images/edit.gif"

        'End If
             
             
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
    
    'Protected Overrides Sub RaisePostBackEvent(ByVal source As IPostBackEventHandler, ByVal eventArgument As String)
    '    ''Listens for pop window calling to refresh grid after some edit.
    '    'MyBase.RaisePostBackEvent(source, eventArgument)
    '    'If TypeOf source Is RadGrid Then
    '    '    Select Case eventArgument
    '    '        Case "Rebind"
    '    '            RadGrid1.Rebind()
    '    '    End Select
    '    'End If
    'End Sub
    
    Protected Sub lstFilter_SelectedIndexChanged(ByVal o As Object, ByVal e As Telerik.Web.UI.RadComboBoxSelectedIndexChangedEventArgs)
        CurrentView = lstFilter.SelectedValue
        SetCurrentView()
        RadGrid1.Rebind()

    End Sub
  
    Protected Sub butExportToPDF_Click(ByVal sender As Object, ByVal e As System.Web.UI.ImageClickEventArgs) Handles butExportToPDF.Click

        'For Each item As GridItem In RadGrid1.MasterTableView.Items
        '    If TypeOf item Is GridDataItem Then
        '        Dim dataItem As GridDataItem = CType(item, GridDataItem)
        '        Dim lnk As HyperLink = CType(dataItem("RefNumber").Controls(0), HyperLink)
        '        lnk.NavigateUrl = ""
        '    End If
        'Next
        RadGrid1.ExportSettings.Pdf.PageTitle = "PROMPT User Activity for " & lstFilter.Text
        RadGrid1.MasterTableView.ExportToPdf()
        
        
        
    End Sub
</script>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" lang="en" xml:lang="en">

<head runat="server">
    <title>User Activity </title>
    <link href="Styles.css" rel="stylesheet" type="text/css" />
    <link href="skins/Prompt/Grid.Prompt.css" rel="stylesheet" type="text/css" />
</head>
<body>
    <form id="Form1" method="post" runat="server">
    <telerik:RadScriptManager ID="RadScriptManager1" runat="server" />
    <br />
    <telerik:RadComboBox ID="lstFilter" runat="server" AutoPostBack="True" DropDownWidth="300px"
        MaxHeight="350px" OnSelectedIndexChanged="lstFilter_SelectedIndexChanged">
    </telerik:RadComboBox>
    &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
    <asp:ImageButton ID="butExportToPDF" runat="server" 
        ImageUrl="images/prompt_pdf.gif" onclick="butExportToPDF_Click" />
    <br />
    <br />
    <telerik:RadGrid ID="RadGrid1" runat="server" AllowSorting="True" AutoGenerateColumns="False"
        GridLines="None" Width="96%" EnableAJAX="True" Skin="Office2007" Height="80%">
        <ClientSettings>
            <Selecting AllowRowSelect="True" />
            <Scrolling AllowScroll="True" UseStaticHeaders="True" ScrollHeight="80%" />
        </ClientSettings>
        <MasterTableView Width="100%" GridLines="None" DataKeyNames="" NoMasterRecordsText="No Activity Found.">
            <Columns>
                <telerik:GridBoundColumn DataField="UserName" UniqueName="UserName" HeaderText="User">
                    <ItemStyle HorizontalAlign="Left" VerticalAlign="Top" />
                    <HeaderStyle HorizontalAlign="Left" />
                </telerik:GridBoundColumn>
                <telerik:GridBoundColumn DataField="ActivityDate" UniqueName="ActivityDate" HeaderText="ActivityDate">
                    <ItemStyle HorizontalAlign="Left" Width="225px" />
                    <HeaderStyle HorizontalAlign="Left"  Width="225px"/>
                </telerik:GridBoundColumn>
                <telerik:GridBoundColumn DataField="ActivityStart" UniqueName="ActivityStart" HeaderText="ActivityStart">
                    <ItemStyle HorizontalAlign="Left" />
                    <HeaderStyle HorizontalAlign="Left" />
                </telerik:GridBoundColumn>
                <telerik:GridBoundColumn DataField="ActivityEnd" UniqueName="ActivityEnd" HeaderText="ActivityEnd">
                    <ItemStyle HorizontalAlign="Left" />
                    <HeaderStyle HorizontalAlign="Left" />
                </telerik:GridBoundColumn>
                
                <telerik:GridBoundColumn DataField="PageViews" UniqueName="PageViews" HeaderText="PageViews">
                    <ItemStyle HorizontalAlign="Left" />
                    <HeaderStyle HorizontalAlign="Left" />
                </telerik:GridBoundColumn>
                
                <telerik:GridBoundColumn DataField="Duration" UniqueName="Duration" HeaderText="Duration">
                    <ItemStyle HorizontalAlign="Left" />
                    <HeaderStyle HorizontalAlign="Left" />
                </telerik:GridBoundColumn>
                <telerik:GridBoundColumn DataField="LastActivity" UniqueName="LastActivity" HeaderText="LastActivity">
                    <ItemStyle HorizontalAlign="Left" />
                    <HeaderStyle HorizontalAlign="Left" />
                </telerik:GridBoundColumn>
                <telerik:GridBoundColumn DataField="LastOn" UniqueName="LastOn" HeaderText="LastOn">
                    <ItemStyle HorizontalAlign="Left" />
                    <HeaderStyle HorizontalAlign="Left" />
                </telerik:GridBoundColumn>
            </Columns>
        </MasterTableView>
    </telerik:RadGrid>
    <%--                       <telerik:radajaxmanager id="RadAjaxManager1" runat="server">
                 <ClientEvents OnRequestStart="ajaxRequestStart" OnResponseEnd="ajaxRequestEnd" />
                    <AjaxSettings>
                   <telerik:AjaxSetting AjaxControlID="RadGrid1">
                            <UpdatedControls>
                                <telerik:AjaxUpdatedControl ControlID="RadGrid1" LoadingPanelID="RadAjaxLoadingPanel1" />
                            </UpdatedControls>
                        </telerik:AjaxSetting>
                    <telerik:AjaxSetting AjaxControlID="lstFilter">
                            <UpdatedControls>
                                <telerik:AjaxUpdatedControl ControlID="RadGrid1" LoadingPanelID="RadAjaxLoadingPanel1" />
                            </UpdatedControls>
                        </telerik:AjaxSetting>
                    </AjaxSettings>
                </telerik:radajaxmanager>
                <telerik:radajaxloadingpanel id="RadAjaxLoadingPanel1" runat="server" height="75px"
                    width="75px" transparency="25">
                    <img alt="Loading..." src="images/loading.gif" style="border: 0;" />
                </telerik:radajaxloadingpanel>--%>
    <telerik:RadWindowManager ID="MasterPopups" runat="server">
    </telerik:RadWindowManager>
    </form>
    <telerik:RadScriptBlock ID="RadScriptBlock1" runat="server">

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

  
        </script>

    </telerik:RadScriptBlock>
</body>
</html>
