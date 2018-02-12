<%@ Page Language="vb" ValidateRequest="false" %>

<%@ Register Assembly="Telerik.Web.UI" Namespace="Telerik.Web.UI" TagPrefix="telerik" %>
<%@ Import Namespace="Prompt" %>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">

<script runat="server">
    
    Private ObjectType As String = ""
    Private districtid As Integer = 0
    'Private scopelevel As String = ""
    
     
    Private Sub Page_Load(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MyBase.Load

        ProcLib.CheckSession(Page)
        ProcLib.LoadPopupJscript(Page)
        
        ''set up help button
        Session("PageID") = "AdministrationSettings"
        
        ObjectType = Request.QueryString("type")
        districtid = Request.QueryString("districtid")
        'scopelevel = Request.QueryString("level")
        
        'Set group by 
        Dim expression As GridGroupByExpression = New GridGroupByExpression
        Dim gridGroupByField As GridGroupByField = New GridGroupByField
        RadGrid1.MasterTableView.GroupByExpressions.Clear()
        'Add select fields (before the "Group By" clause)
        gridGroupByField = New GridGroupByField
        gridGroupByField.FieldName = "Category"
        gridGroupByField.HeaderText = " "
        gridGroupByField.HeaderValueSeparator = " "
        expression.SelectFields.Add(gridGroupByField)

        'Add a field for group-by (after the "Group By" clause)
        gridGroupByField = New GridGroupByField
        gridGroupByField.FieldName = "Category"
        expression.GroupByFields.Add(gridGroupByField)

        RadGrid1.MasterTableView.GroupByExpressions.Add(expression)
        
        RadGrid1.Height = Unit.Pixel(475)
           
    End Sub
    
    Protected Sub RadGrid1_NeedDataSource(ByVal source As Object, ByVal e As Telerik.Web.UI.GridNeedDataSourceEventArgs) Handles RadGrid1.NeedDataSource
        'loads the grid whenever it needs data (sorting, rebinding, etc...)
        Using db As New EISSecurity

            RadGrid1.DataSource = db.GetAdminSystemSettings(ObjectType, districtid)

        End Using
        
    End Sub
    
    Protected Sub RadGrid1_ItemCreated(ByVal sender As Object, ByVal e As Telerik.Web.UI.GridItemEventArgs) Handles RadGrid1.ItemCreated
        
        ''This event allows us to customize the cell contents - fired before databound

        'If (TypeOf e.Item Is GridDataItem) Then
        '    Dim item As GridDataItem = CType(e.Item, GridDataItem)
        '    Dim sSetting As String = item.OwnerTableView.DataKeyValues(item.ItemIndex)("Setting")

        '    'update the link button to open report window
        '    Dim lst As DropDownList = CType(item("Setting").Controls(0), DropDownList)
        '    If sSetting = "On" Then
        '        lst.Items(0).Selected = True
        '    Else
        '        lst.Items(1).Selected = True
        '    End If

        'End If
    End Sub
    
    
    
    Private Sub RadGrid1_ItemDataBound(ByVal sender As Object, ByVal e As Telerik.Web.UI.GridItemEventArgs) Handles RadGrid1.ItemDataBound
        If TypeOf e.Item Is GridDataItem Then
            Dim item As GridDataItem = e.Item
            Dim nVisibility As Integer = ProcLib.CheckNullNumField(item.OwnerTableView.DataKeyValues(item.ItemIndex)("Visibility"))
            Dim sObjectID As String = item.OwnerTableView.DataKeyValues(item.ItemIndex)("ObjectID")
            Dim sCategory As String = item.OwnerTableView.DataKeyValues(item.ItemIndex)("Category")
            Dim sDisplayOrder As String = ProcLib.CheckNullNumField(item.OwnerTableView.DataKeyValues(item.ItemIndex)("DisplayOrder"))
            Dim nKey As Integer = item.OwnerTableView.DataKeyValues(item.ItemIndex)("SecurityPermissionID")
            Dim lst As DropDownList = item.FindControl("lstSetting")
            Dim txtOrder As TextBox = item.FindControl("txtDisplayOrder")
    
            txtOrder.Text = sDisplayOrder
            
            Dim lstitem As New ListItem
            With lstitem
                .Text = "On"
                .Value = 1
                If nVisibility = 1 Then
                    .Selected = True
                    lst.BackColor = Color.LightGreen
                End If
            End With
            lst.Items.Add(lstitem)
            
            
            lstitem = New ListItem
            With lstitem
                .Text = "Off"
                .Value = 0
                If nVisibility = 0 Then
                    .Selected = True
                    lst.BackColor = Color.IndianRed
                End If
            End With
            lst.Items.Add(lstitem)
          
        End If

    End Sub
    
    Protected Sub butSave_Click(ByVal sender As Object, ByVal e As System.Web.UI.ImageClickEventArgs)

        'Update changes
        Dim sql As String = ""
        Using db As New EISSecurity
            For Each item As GridDataItem In RadGrid1.MasterTableView.Items
                Dim lst As DropDownList = item.FindControl("lstSetting")
                Dim txtOrder As TextBox = item.FindControl("txtDisplayOrder")
                Dim nKey As Integer = item.OwnerTableView.DataKeyValues(item.ItemIndex)("SecurityPermissionID")

                db.SaveAdminSystemSetting(nKey, txtOrder.Text, lst.SelectedValue)
            Next
        
        End Using
        
        RadGrid1.Rebind()
        
        
    End Sub

 </script>

<html>
<head>
    <title>System Settings</title>
    <link href="Styles.css" type="text/css" rel="stylesheet" />
</head>
<body>
    <form id="Form1" method="post" runat="server">
    <telerik:RadScriptManager ID="RadScriptManager1" runat="server" />
    <table id="Table1" width="100%" runat="server">
        <tr>
            <td>
                <br />
                &nbsp;&nbsp;<asp:ImageButton ID="butSave" runat="server" ImageUrl="images/button_save.gif"
                    TabIndex="40" OnClick="butSave_Click"></asp:ImageButton>
            </td>
           
        </tr>
    </table>
    <telerik:RadGrid ID="RadGrid1" runat="server" AllowSorting="true" AutoGenerateColumns="False"
        GridLines="None" Width="99%" Height="450px" EnableAJAX="True" Skin="Office2007">
        <ClientSettings>
            <Selecting AllowRowSelect="False" />
            <Scrolling AllowScroll="True" UseStaticHeaders="True" ScrollHeight="50%" SaveScrollPosition="true" />
        </ClientSettings>
        <MasterTableView Width="100%" GridLines="None" DataKeyNames="SecurityPermissionID,Visibility,DisplayOrder,Category,ObjectID"
            NoMasterRecordsText="No Records Found.">
            <Columns>
                <telerik:GridBoundColumn UniqueName="Description" HeaderText="Description" DataField="Description">
                    <ItemStyle HorizontalAlign="Left" VerticalAlign="Top" />
                    <HeaderStyle HorizontalAlign="Left" />
                </telerik:GridBoundColumn>
                <telerik:GridTemplateColumn UniqueName="DisplayOrder" HeaderText="Order">
                    <ItemStyle HorizontalAlign="Center" Width="60px" VerticalAlign="Top" />
                    <HeaderStyle HorizontalAlign="Center" Width="60px" VerticalAlign="Top" />
                    <ItemTemplate>
                        <asp:TextBox ID="txtDisplayOrder" runat="server">
                        </asp:TextBox>
                    </ItemTemplate>
                </telerik:GridTemplateColumn>
                <telerik:GridTemplateColumn UniqueName="Setting" HeaderText="Setting">
                    <ItemStyle HorizontalAlign="Center" Width="130px" VerticalAlign="Top" />
                    <HeaderStyle HorizontalAlign="Center" Width="130px" VerticalAlign="Top" />
                    <ItemTemplate>
                        <asp:DropDownList ID="lstSetting" runat="server">
                        </asp:DropDownList>
                    </ItemTemplate>
                </telerik:GridTemplateColumn>
            </Columns>
        </MasterTableView>
    </telerik:RadGrid>
    <telerik:RadWindowManager ID="MasterPopups" runat="server">
    </telerik:RadWindowManager>
    </form>
</body>
</html>
