<%@ Page Language="VB" %>
<%@ Import Namespace="Prompt" %>
<%@ Register Assembly="Telerik.Web.UI" Namespace="Telerik.Web.UI" TagPrefix="telerik" %>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">

<script runat="server">
    Dim dtSearchResults As DataTable
    
    Protected Sub RadGrid1_NeedDataSource(ByVal source As Object, ByVal e As Telerik.Web.UI.GridNeedDataSourceEventArgs) Handles RadGrid1.NeedDataSource
        'loads the grid whenever it needs data (sorting, rebinding, etc...)
        If Not e.IsFromDetailTable Then                                     'roy: not sure why this is here ...
            RadGrid1.DataSource = dtSearchResults
        End If
    End Sub
  
    Protected Sub butFindPO_Click(ByVal sender As Object, ByVal e As System.EventArgs)
        Using db As New promptSearch
            db.CallingPage = Page                                         'roy: not sure why this is here ...
            dtSearchResults = db.SearchPONums(ddlDistrict.Text, tbPONum.Text)
        End Using
        RadGrid1.Rebind()
    End Sub

    Protected Sub butFindInv_Click(ByVal sender As Object, ByVal e As System.EventArgs)
        Using db As New promptSearch
            db.CallingPage = Page                                            'roy: not sure why this is here ...
            dtSearchResults = db.SearchInvoiceNums(ddlDistrict.Text, tbInvNum.Text)
        End Using
        RadGrid1.Rebind()
    End Sub

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs)
        Dim sql As String = "Select DistrctID, Name from Districts"
        Using db As New PromptDataHelper
            db.FillDropDown("Select DistrictID as Val, Name as Lbl From Districts Order By DistrictID Desc", ddlDistrict)
        End Using
      
    End Sub
</script>

<html xmlns="http://www.w3.org/1999/xhtml" >
<head runat="server">
    <title>Prompt P.O. Search Page</title>
    <link href="Styles.css" rel="stylesheet" type="text/css" />
</head>

<body>
<form id="Form1" method="post" runat="server">
     <telerik:RadScriptManager ID="RadScriptManager1" runat="server" />
    <div>
        <br />
        &nbsp;
        <asp:Label ID="Label1" runat="server" Font-Size="Medium" Height="28px" Style="z-index: 100;
            left: 17px; position: absolute; top: 7px" Text="District" Width="99px"></asp:Label>
        &nbsp;
        <asp:DropDownList ID="ddlDistrict" runat="server" Style="z-index: 107; left: 131px;
            position: absolute; top: 9px">
        </asp:DropDownList>
        &nbsp; &nbsp;
        <br />
        <asp:TextBox ID="tbPONum" runat="server" style="z-index: 102; left: 8px; position: absolute; top: 43px"></asp:TextBox><asp:Button ID="butFindPO"
            runat="server" Text="Find PO #" style="z-index: 103; left: 218px; position: absolute; top: 43px" OnClick="butFindPO_Click" />
                
        <telerik:RadGrid  Style="z-index: 104; left: 9px; position: absolute;
            top: 75px" ID="RadGrid1"  runat="server" AllowSorting="True"
            GridLines="None" Width="99%" EnableAJAX="True" Skin="Office2007" Height="80%" DataMember="dataSearch">
            <ClientSettings>
                <Scrolling AllowScroll="True" UseStaticHeaders="True" ScrollHeight="80%"/>
            </ClientSettings>
            <MasterTableView Width="98%" GridLines="None" DataMember="dataSearch" NoMasterRecordsText="No matching records were found to display.">
                <ExpandCollapseColumn Visible="False">
                    <HeaderStyle Width="19px" />
                </ExpandCollapseColumn>
                <RowIndicatorColumn Visible="False">
                    <HeaderStyle Width="20px" />
                </RowIndicatorColumn>
            </MasterTableView>
        </telerik:RadGrid>
        <asp:TextBox ID="tbInvNum" runat="server" Style="z-index: 105; left: 448px; position: absolute;
            top: 45px">
        </asp:TextBox>
        <asp:Button ID="butFindInv" runat="server" Style="z-index: 106; left: 660px; position: absolute;
            top: 44px" Text="Find Invoice #" OnClick="butFindInv_Click" />
 </div>
    </form>
</body>
</html>
