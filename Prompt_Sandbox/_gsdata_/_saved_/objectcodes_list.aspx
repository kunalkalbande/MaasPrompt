<%@ Page Language="VB" %>

<%@ Import Namespace="Prompt" %>
<%@ Register Assembly="Telerik.Web.UI" Namespace="Telerik.Web.UI" TagPrefix="telerik" %>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">

<script runat="server">
 
    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs)
                          
        Session("PageID") = "ObjectCodeList"
        
        'Configure the Popup Window(s)
        With MasterPopups
            .VisibleOnPageLoad = False
            .Skin = "Office2007"
                  
            Dim ww As New RadWindow
            With ww
                .ID = "EditRecord"
                .NavigateUrl = ""
                .Title = ""
                .Width = 500
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
        
        Using dbsec As New EISSecurity
            
            If Not dbsec.FindUserPermission("TableMaintenance", "write") Then
                butAddNew.Visible = False
                RadGrid1.MasterTableView.Columns.FindByUniqueName("Edit").Visible = False
            End If
            
        End Using
        
        
    End Sub
    Protected Sub RadGrid1_NeedDataSource(ByVal source As Object, ByVal e As Telerik.Web.UI.GridNeedDataSourceEventArgs) Handles RadGrid1.NeedDataSource
        
        Using db As New PromptDataHelper
            Dim sql As String = "SELECT * FROM ObjectCodes WHERE DistrictID = " & Session("DistrictID") & " ORDER BY ObjectCode"
            RadGrid1.DataSource = db.ExecuteDataTable(sql)
        End Using
   
    End Sub
    
    Protected Sub RadGrid1_ItemCreated(ByVal sender As Object, ByVal e As Telerik.Web.UI.GridItemEventArgs) Handles RadGrid1.ItemCreated
        'This event allows us to customize the cell contents - fired before databound
          
        If (TypeOf e.Item Is GridDataItem) Then
               
            Dim item As GridDataItem = CType(e.Item, GridDataItem)
            Dim nKey As Integer = item.OwnerTableView.DataKeyValues(item.ItemIndex)("PrimaryKey")
                          
            'update the link button to open attachments/notes window
            Dim linkButton As HyperLink = CType(item("Edit").Controls(0), HyperLink)
            linkButton.Attributes("onclick") = "return EditRecord(this,'" & nKey & "');"
            linkButton.ToolTip = "Edit this Object Code."
            linkButton.ImageUrl = "images/edit.png"
            linkButton.NavigateUrl = "#"
          
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
  
</script>

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title>Object Codes List </title>
    <link href="Styles.css" rel="stylesheet" type="text/css" />
</head>
<body>
    <form id="Form1" method="post" runat="server">
    <telerik:RadScriptManager ID="RadScriptManager1" runat="server" />
    <asp:Table ID="Table1" runat="server" Style="z-index: 102; left: 8px; position: absolute;
        top: 17px" Width="97%">
        <asp:TableRow ID="TableRow1" runat="server">
            <asp:TableCell ID="TableCell1" runat="server" Width="50%" HorizontalAlign="Left">
                <asp:Label ID="Label1" runat="server" Text="Object Code List" Font-Underline="true"></asp:Label>
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
            <Scrolling AllowScroll="True" UseStaticHeaders="True" ScrollHeight="50%" />
        </ClientSettings>
        <MasterTableView Width="100%" GridLines="None" DataKeyNames="PrimaryKey" NoMasterRecordsText="No Object Codes Found.">
            <Columns>
                <telerik:GridBoundColumn DataField="ObjectCode" UniqueName="ObjectCode" HeaderText="Object Code">
                    <ItemStyle HorizontalAlign="Left" Height="15px" />
                    <HeaderStyle HorizontalAlign="Left" Width="90px" Height="15px" />
                </telerik:GridBoundColumn>
                <telerik:GridBoundColumn DataField="ObjectCodeDescription" UniqueName="ObjectCodeDescription"
                    HeaderText="Description">
                    <ItemStyle HorizontalAlign="Left" Height="15px" />
                    <HeaderStyle HorizontalAlign="Left" Height="15px" Width="35%" />
                </telerik:GridBoundColumn>
                <telerik:GridBoundColumn DataField="BudgetGroup" UniqueName="BudgetGroup" HeaderText="BudgetGroup">
                    <ItemStyle HorizontalAlign="Left" Height="15px" />
                    <HeaderStyle HorizontalAlign="Left" Height="15px" />
                </telerik:GridBoundColumn>
                <telerik:GridBoundColumn DataField="ObjectCodeGroup" UniqueName="ObjectCodeGroup"
                    HeaderText="ObjectCodeGroup">
                    <ItemStyle HorizontalAlign="Left" Height="15px" />
                    <HeaderStyle HorizontalAlign="Left" Height="15px" />
                </telerik:GridBoundColumn>
                <telerik:GridHyperLinkColumn HeaderText="" UniqueName="Edit">
                    <ItemStyle Width="35px" HorizontalAlign="Center" />
                    <HeaderStyle Width="35px" HorizontalAlign="Center" />
                </telerik:GridHyperLinkColumn>
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
            var oWnd = window.radopen("objectcode_edit.aspx?PrimaryKey= " + id, "EditRecord");
            return false;
        }


        // to allow popup to call refresh in this form after edit
        function refreshGrid() {
            RadGridNamespace.AsyncRequest('<%= RadGrid1.UniqueID %>', 'Rebind', '<%= RadGrid1.ClientID %>');
        }
      
    </script>

</body>
</html>
