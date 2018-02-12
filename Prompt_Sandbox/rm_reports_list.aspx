<%@ Page Language="VB" %>

<%@ Import Namespace="Prompt" %>
<%@ Register Assembly="Telerik.Web.UI" Namespace="Telerik.Web.UI" TagPrefix="telerik" %>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">

<script runat="server">
        
    Protected Sub RadGrid1_NeedDataSource(ByVal source As Object, ByVal e As Telerik.Web.UI.GridNeedDataSourceEventArgs) Handles RadGrid1.NeedDataSource
        'loads the grid whenever it needs data (sorting, rebinding, etc...)
        If Not e.IsFromDetailTable Then
            Using db As New PromptDataHelper
                Dim sql As String = ""
                
                sql = "SELECT Distinct ReportType FROM Reports "
 
                RadGrid1.DataSource = db.ExecuteDataTable(sql)
            End Using
        End If
    End Sub
    
    Protected Sub RadGrid1_DetailTableDataBind(ByVal source As Object, ByVal e As Telerik.Web.UI.GridDetailTableDataBindEventArgs) Handles RadGrid1.DetailTableDataBind
        Dim parentItem As Telerik.Web.UI.GridDataItem = CType(e.DetailTableView.ParentItem, Telerik.Web.UI.GridDataItem)
        If Not parentItem.Edit Then
            If (e.DetailTableView.DataMember = "TablesList") Then
                Using db As New PromptDataHelper
                    e.DetailTableView.DataSource = db.ExecuteDataTable("Select * From Reports Where ReportType = '" & parentItem("ReportType").Text & "'")
                End Using
                
                'this needs to be set here for some reason
                ' e.DetailTableView.CommandItemStyle.CssClass = "Grid_Child_CommandItem"
                
                e.DetailTableView.NoDetailRecordsText = "No ... Found."
            End If
        End If
    End Sub

    Protected Sub RadGrid1_ItemCreated(ByVal sender As Object, ByVal e As Telerik.Web.UI.GridItemEventArgs) Handles RadGrid1.ItemCreated
        'This event allows us to customize the cell contents - fired before databound
          
              
             
        If e.Item.OwnerTableView.DataMember = "TablesList" Then
            'This looks at the row as it is created and finds the LinkButton control 
            'named ViewTransactionInfo and updates the link button so its wired to a 
            'Java Script function that calls a RAD window.
            If (TypeOf e.Item Is GridDataItem) Then
                Dim item As GridDataItem = CType(e.Item, GridDataItem)
                Dim strReportName As String = item.OwnerTableView.DataKeyValues(item.ItemIndex)("ReportFileName")
                
                'update the link button to open attachments/notes window
                Dim linkButton As HyperLink = CType(item("ReportTitle").Controls(0), HyperLink)
                linkButton.Attributes("onclick") = "return ShowReport(this,'" & 0 & "', '" & strReportName & "');"
                linkButton.ToolTip = "Click on the report title to generate the report"
            End If
        End If
    End Sub
  

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs)
        'Dim sql As String = "Select DistrctID, Name from Districts"
        'Using db As New PromptDataHelper
        '    db.FillDropDown("Select DistrictID as Val, Name as Lbl From Districts Order By DistrictID Desc", ddlDistrict)
        'End Using
                      
        'Configure the Popup Window(s)
        With MasterPopups
            .VisibleOnPageLoad = False
            .Skin = "WinnXPSilver"
                         
            Dim ww As New RadWindow
    
            With ww
                .ID = "MasterHelpWin"
                .NavigateUrl = ""
                .Title = ""
                .Width = 500
                .Height = 425
                .Modal = False
                .VisibleStatusbar = False
                .ReloadOnShow = True
                .Behaviors = WindowBehaviors.Close + WindowBehaviors.Move
            End With
            .Windows.Add(ww)
            
        End With
        
    End Sub
    
</script>

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title>Prompt Reports List </title>
    <link href="Styles.css" rel="stylesheet" type="text/css" />
</head>
<body>
<form id="Form1" method="post" runat="server">
     <telerik:RadScriptManager ID="RadScriptManager1" runat="server" />
        <div>
            <telerik:RadGrid Style="z-index: 104; left: 1px; position: absolute; top: 46px" ID="RadGrid1"
                runat="server" AllowSorting="True" AutoGenerateColumns="False" GridLines="None"
                Width="96%" EnableAJAX="True" Skin="Office2007" Height="291px">
                <ClientSettings>
                    <Selecting AllowRowSelect="True" />
                    <Scrolling AllowScroll="True" UseStaticHeaders="True" ScrollHeight="50%" />
                </ClientSettings>
                <MasterTableView Width="100%" GridLines="None" DataKeyNames="ReportType" NoMasterRecordsText="No reports available for this user.">
                    <Columns>
                        <telerik:GridBoundColumn DataField="ReportType" UniqueName="ReportType" HeaderText="Report Type">
                            <ItemStyle HorizontalAlign="Left" />
                            <HeaderStyle HorizontalAlign="Left" Height="15px" />
                        </telerik:GridBoundColumn>
                    </Columns>
                    <ExpandCollapseColumn>
                        <HeaderStyle Width="19px" />
                    </ExpandCollapseColumn>
                    <RowIndicatorColumn Visible="False">
                        <HeaderStyle Width="20px" />
                    </RowIndicatorColumn>
                    <DetailTables>
                        <telerik:GridTableView runat="server" DataMember="TablesList" DataKeyNames="ReportFileName,ReportID">
                            <Columns>
                                <telerik:GridBoundColumn DataField="ReportNumber" UniqueName="ReportNumber" HeaderText="Report #">
                                    <HeaderStyle HorizontalAlign="Left" Height="15px" Width="10%" />
                                </telerik:GridBoundColumn>
                                <telerik:GridHyperLinkColumn DataTextField="ReportTitle" UniqueName="ReportTitle" HeaderText="Title" >
                                    <HeaderStyle HorizontalAlign="Left" Width="30%" />
                                </telerik:GridHyperLinkColumn>
                                <telerik:GridBoundColumn DataField="Description" UniqueName="Description" HeaderText="Description">
                                    <HeaderStyle HorizontalAlign="Left" Height="15px" Width="50%" />
                                </telerik:GridBoundColumn>
                            </Columns>
                            <ExpandCollapseColumn Visible="False">
                                <HeaderStyle Width="19px" />
                            </ExpandCollapseColumn>
                            <RowIndicatorColumn Visible="False">
                                <HeaderStyle Width="20px" />
                            </RowIndicatorColumn>
                        </telerik:GridTableView>
                    </DetailTables>
                </MasterTableView>
            </telerik:RadGrid>
        </div>
        <telerik:RadWindowManager ID="MasterPopups" runat="server">
        </telerik:RadWindowManager>
    </form>

        <script type="text/javascript" language="javascript">
        // this is the actual script for loading the RAD window popup objects from attribute assigned to page elements
        function ShowReport(oButton, id, str)     //for help display
        {
            radalert(str);
            var oWnd = window.radopen("http://216.129.104.66/ReportServer?/Prompt Reports/Project Summary&ProjectID=569","ShowReportWin"); 
           return false;
        } 
    </script>

</body>
</html>
