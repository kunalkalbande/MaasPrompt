<%@ Page Language="VB" %>

<%@ Import Namespace="Prompt" %>
<%@ Register Assembly="Telerik.Web.UI" Namespace="Telerik.Web.UI" TagPrefix="telerik" %>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">

<script runat="server">
    
    ' Broken: add sorting, moving columns, etc.
    ' TODO: add checks for filtering out SQL injection issues (see CleanSQL in cls_Login.vb)
    ' TODO: button to clear query and start afresh
    ' TODO: add limit to # of rows returned so that it does not get to be too much for Firefox, etc. to deal with 
    ' TODO: set appropriate tab-order and also default action on enter-key
    ' TODO: integrate better into Prompt via button/link only available to "power users"
    ' TODO: saved queries list (in a new table in Prompt)
    ' Done: Export to Excel
    ' done: add error recovery for when query bombs
        
    Dim dtQueryResults As DataTable
    
    Private Sub Page_Load(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MyBase.Load
        ProcLib.CheckSession(Page)
    End Sub
    
    Protected Sub RadGrid1_NeedDataSource(ByVal source As Object, ByVal e As Telerik.Web.UI.GridNeedDataSourceEventArgs) Handles RadGrid1.NeedDataSource
        'loads the grid whenever it needs data (sorting, rebinding, etc...)
        If Not e.IsFromDetailTable Then
            RadGrid1.DataSource = dtQueryResults
        End If
    End Sub
  
    Protected Sub butGetQueryResults_Click(ByVal sender As Object, ByVal e As System.EventArgs)
        'first check query string to protect against SQL injection attacks
        If LCase(tbQuery.Text).Contains("update") Or LCase(tbQuery.Text).Contains("delete") Or LCase(tbQuery.Text).Contains("drop") Or LCase(tbQuery.Text).Contains("insert") Then
            Exit Sub
        End If
        'fetch results into datatable
        Using db As New PromptDataHelper
            Try
                RadGrid1.DataSource = db.ExecuteDataTable(tbQuery.Text)
                
                RadGrid1.BackColor = Color.White
                lblBadQuery.Visible = False
            Catch ex As Exception
                ' clear the previous results from the grid
                RadGrid1.BackColor = Color.Magenta
                RadGrid1.Rebind()
                ' indicate error
                lblBadQuery.Visible = True
            End Try
        End Using
        'refresh grid
        RadGrid1.Rebind()
    End Sub

    Protected Sub butExport_Click(ByVal sender As Object, ByVal e As System.EventArgs)
        Me.RadGrid1.MasterTableView.ExportToExcel()
    End Sub

    Protected Sub butClear_Click(ByVal sender As Object, ByVal e As System.EventArgs)
        MsgBox("butClear_Click")
    End Sub
</script>

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title>Custom Prompt Query</title>
    <link href="Styles.css" rel="stylesheet" type="text/css" />
</head>
<body>
<form id="Form1" method="post" runat="server">
     <telerik:RadScriptManager ID="RadScriptManager1" runat="server" />
    <div>
        <br />
        &nbsp; &nbsp;&nbsp; &nbsp; &nbsp;&nbsp;&nbsp; &nbsp;&nbsp;<br />
        <telerik:RadGrid Style="z-index: 100; left: 9px; position: absolute; top: 109px"
            ID="RadGrid1" runat="server" GridLines="None" Width="99%" EnableAJAX="True" Skin="Office2007"
            Height="66%">
            <ClientSettings>
                <Scrolling ScrollHeight="80%" />
            </ClientSettings>
            <MasterTableView Width="98%" GridLines="None" NoMasterRecordsText="No matching records were found to display."
                AllowMultiColumnSorting="True">
                <ExpandCollapseColumn Visible="True" Resizable="True">
                    <HeaderStyle Width="20px" />
                </ExpandCollapseColumn>
                <RowIndicatorColumn Visible="True">
                    <HeaderStyle Width="20px" />
                </RowIndicatorColumn>
            </MasterTableView>
            <ExportSettings>
                <Pdf PageBottomMargin="" PageFooterMargin="" PageHeaderMargin="" PageHeight="11in"
                    PageLeftMargin="" PageRightMargin="" PageTopMargin="" PageWidth="8.5in" />
            </ExportSettings>
        </telerik:RadGrid>
        &nbsp;&nbsp;&nbsp;
        <asp:Label ID="Label1" runat="server" Style="z-index: 101; left: 7px; position: absolute;
            top: 23px" Text="Query:" Width="585px"></asp:Label>
        <asp:Label ID="Label2" runat="server" Style="z-index: 103; left: 0px; position: absolute;
            top: 0px" Text="Run Custom Query in Prompt" Font-Bold="True" Font-Size="10pt"
            Font-Underline="True"></asp:Label>
        <asp:Label ID="lblBadQuery" runat="server" Style="z-index: 106; left: 158px; position: absolute;
            top: 79px" Text="Query Could Not Execute.  Try again ..." Width="277px" ForeColor="Red"
            Visible="False"></asp:Label>
        <asp:Button ID="butGetQueryResults" runat="server" OnClick="butGetQueryResults_Click"
            Style="z-index: 104; left: 15px; position: absolute; top: 74px" Text="Execute Query" />
        <asp:Button ID="butExport" runat="server" Style="z-index: 105; left: 450px; position: absolute;
            top: 75px" Text="Export To Excel" OnClick="butExport_Click" />
        <asp:Button ID="butClear" runat="server" OnClick="butClear_Click" Style="z-index: 108;
            left: 610px; position: absolute; top: 75px" Text="Clear Query" />
        <asp:TextBox ID="tbQuery" runat="server" Style="z-index: 102; left: 78px; position: absolute;
            top: 21px" Width="702px" Rows="3" TextMode="MultiLine" Height="41px"></asp:TextBox>
    </div>
    </form>
</body>
</html>
