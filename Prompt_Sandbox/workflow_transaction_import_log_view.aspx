<%@ Page Language="VB" %>

<%@ Import Namespace="Prompt" %>
<%@ Register Assembly="Telerik.Web.UI" Namespace="Telerik.Web.UI" TagPrefix="telerik" %>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">

<script runat="server">
     
    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs)
 
        If Not IsPostBack Then
            Using db As New promptWorkflowTransfer
                Dim tbl As DataTable = db.GetFRSTransactionImportDates()
                For Each row As DataRow In tbl.Rows
                    Dim item As New RadComboBoxItem
                    item.Text = row("RunDate")
                    item.Value = row("RunDate")
                    lstProcessDate.Items.Add(item)
                Next
            End Using
        End If
        
        
    End Sub
    
    Protected Sub RadGrid1_NeedDataSource(ByVal source As Object, ByVal e As Telerik.Web.UI.GridNeedDataSourceEventArgs) Handles RadGrid1.NeedDataSource
        'loads the grid whenever it needs data (sorting, rebinding, etc...)
        Using db As New promptWorkflowTransfer
            db.CallingPage = Page
            RadGrid1.DataSource = db.GetTransactionImportLog(lstProcessDate.SelectedValue)
        End Using
       
    End Sub

    Protected Sub lstProcessedDate_SelectedIndexChanged(ByVal o As Object, ByVal e As Telerik.Web.UI.RadComboBoxSelectedIndexChangedEventArgs)
        RadGrid1.Rebind()

    End Sub
    
    
</script>

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title>View Transaction Import Log</title>
    <link href="Styles.css" rel="stylesheet" type="text/css" />
</head>
<body>
<form id="Form1" method="post" runat="server">
     <telerik:RadScriptManager ID="RadScriptManager1" runat="server" />
    <telerik:RadComboBox ID="lstProcessDate" runat="server" Style="z-index: 501; left: 9px;
        position: absolute; top: 25px" OnSelectedIndexChanged="lstProcessedDate_SelectedIndexChanged"
        AutoPostBack="True" NoWrap="True" ToolTip="Select View you wish to see." Width="150px"
        Height="350px">
    </telerik:RadComboBox>
    <telerik:RadGrid Style="z-index: 103; left: 7px; position: absolute; top: 50px" ID="RadGrid1"
        runat="server" AllowSorting="True" AutoGenerateColumns="False" GridLines="None"
        Width="99%" EnableAJAX="True" Skin="Office2007" Height="80%" DataMember="viewlog">
        <ClientSettings Resizing-AllowColumnResize="true">
            <Scrolling AllowScroll="True" UseStaticHeaders="True" ScrollHeight="80%" />
        </ClientSettings>
        <MasterTableView Width="98%" GridLines="None" DataMember="viewlog" NoMasterRecordsText="No records were found to display.">
            <ExpandCollapseColumn Visible="true" Resizable="true">
                <HeaderStyle Width="19px" />
            </ExpandCollapseColumn>
            <RowIndicatorColumn Visible="False">
                <HeaderStyle Width="20px" />
            </RowIndicatorColumn>
            <Columns>
                <telerik:GridBoundColumn DataField="LogDate" UniqueName="LogDate" HeaderText="Time">
                    <ItemStyle Width="45px" HorizontalAlign="Left" VerticalAlign="Top" />
                    <HeaderStyle Width="45px" HorizontalAlign="Left" />
                </telerik:GridBoundColumn>
                <telerik:GridBoundColumn DataField="LogNotes" UniqueName="LogNotes" HeaderText="Notes">
                    <ItemStyle HorizontalAlign="Left" Wrap="true" VerticalAlign="Top" Width="125px" />
                    <HeaderStyle HorizontalAlign="Left" Wrap="true" Width="125px" Height="15px" />
                </telerik:GridBoundColumn>
                <telerik:GridBoundColumn DataField="TransactionID" UniqueName="TransactionID" HeaderText="TransID">
                    <ItemStyle HorizontalAlign="Left" Width="10" VerticalAlign="Top" />
                    <HeaderStyle HorizontalAlign="Left" Width="10px" Height="15px" />
                </telerik:GridBoundColumn>
                <telerik:GridBoundColumn HeaderText="Source" UniqueName="Source" DataField="Source">
                    <ItemStyle HorizontalAlign="Left" Width="95px" Wrap="true" VerticalAlign="Top" />
                    <HeaderStyle HorizontalAlign="Left" Width="95px" Wrap="true" VerticalAlign="Top" />
                </telerik:GridBoundColumn>
                <telerik:GridBoundColumn DataField="NotifySentOn" HeaderText="NotifySentOn" UniqueName="NotifySentOn">
                    <ItemStyle HorizontalAlign="Center" Width="25px" Wrap="false" VerticalAlign="Top" />
                    <HeaderStyle HorizontalAlign="Center" Width="25px" Wrap="false" />
                </telerik:GridBoundColumn>
            </Columns>
        </MasterTableView>
    </telerik:RadGrid>
    </form>
</body>
</html>
