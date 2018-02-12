<%@ Page Language="vb" %>

<%@ Import Namespace="Prompt" %>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">

<script runat="server">
    
    Public nLookupID As Integer = 0
    Private ParentField As String = ""
    Private ParentTable As String = ""
    
    Private bIsGlobal As Boolean = False
    
    Private Sub Page_Load(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MyBase.Load

        ProcLib.CheckSession(Page)

        ProcLib.LoadPopupJscript(Page)
        
        If Request.QueryString("Admin") = "y" Then
            bIsGlobal = True
        End If

        'set up help button
        butHelp.Attributes.Add("onclick", "openPopup('help_view.aspx','pophelp',550,450,'yes');")
        butHelp.NavigateUrl = "#"

        nLookupID = Request.QueryString("LookupID")
        ParentField = Request.QueryString("ParentField")
        ParentTable = Request.QueryString("ParentTable")
        
        If bIsGlobal Then
            Session("PageID") = "GlobalLookupAdmin"
            chkUserEditable.Visible = True
            lblMaxLen.Visible = True
            txtMaxLength.Visible = True
        Else
            Session("PageID") = "LookupEdit"
            chkUserEditable.Visible = False
            lblMaxLen.Visible = False
            txtMaxLength.Visible = False
        End If

        If IsPostBack Then   'only do the following post back
            nLookupID = lblPrimaryKey.Text
        Else  'only do the following on first load
            
            Using rs As New Lookup
          
                If Request.QueryString("new") = "y" Then    'add the new record
                    With rs
                        .CallingPage = Page
                        .GetNewLookup()
                    End With
                    butDelete.Visible = False
 
                
                Else
                    With rs
                        .CallingPage = Page
                        .GetExistingLookup(nLookupID)
                    End With

                End If
            End Using

        End If
        
        'set the max length
        If Not bIsGlobal Then
            'txtLookupValue.MaxLength = txtMaxLength.Text   BUGGGG
        End If
                   
        If txtLookupValue.Text = txtLookupTitle.Text Then   'blank out the title for simplicity
            txtLookupTitle.Text = ""
        End If
    
    
        txtLookupValue.Focus()

    End Sub


    Private Sub butSave_Click(ByVal sender As System.Object, ByVal e As System.Web.UI.ImageClickEventArgs) Handles butSave.Click
        
        If txtLookupTitle.Text = "" Then   'make it the same as value
            txtLookupTitle.Text = txtLookupValue.Text
        End If
        
        Using rs As New Lookup
            rs.CallingPage = Page
            rs.SaveLookup(nLookupID, ParentTable, ParentField, bIsGlobal)
        End Using
        
  
        If Request.QueryString("passback") = "y" Then       'this page was called from an edit page so save val to session for passback
            Session("passback") = txtLookupTitle.Text
        End If
        Session("RtnFromEdit") = True
        ProcLib.CloseAndRefresh(Page)
    End Sub

    Private Sub butDelete_Click(ByVal sender As System.Object, ByVal e As System.Web.UI.ImageClickEventArgs) Handles butDelete.Click
        Session("RtnFromEdit") = True
        Response.Redirect("delete_record.aspx?RecordType=Lookup&ID=" & nLookupID)
    End Sub



</script>

<html>
<head>
    <title>Lookup Edit</title>
    <meta content="False" name="vs_snapToGrid">
    <meta content="Microsoft Visual Studio .NET 7.1" name="GENERATOR">
    <meta content="Visual Basic .NET 7.1" name="CODE_LANGUAGE">
    <meta content="JavaScript" name="vs_defaultClientScript">
    <meta content="http://schemas.microsoft.com/intellisense/ie5" name="vs_targetSchema">
    <link href="Styles.css" type="text/css" rel="stylesheet">
</head>
<body>
    <form id="Form1" method="post" runat="server">
    <asp:TextBox ID="txtLookupTitle" Style="z-index: 100; left: 225px; position: absolute;
        top: 99px" runat="server" EnableViewState="False" Width="240px" TabIndex="2"></asp:TextBox>
    <asp:TextBox ID="txtLookupValue" runat="server" EnableViewState="False" Style="z-index: 101;
        left: 16px; position: absolute; top: 100px" Width="177px" TabIndex="1"></asp:TextBox>
    <asp:ImageButton ID="butDelete" Style="z-index: 102; left: 255px; position: absolute;
        top: 209px" TabIndex="41" runat="server" ImageUrl="images/button_delete.gif">
    </asp:ImageButton>
    <asp:ImageButton ID="butSave" Style="z-index: 103; left: 20px; position: absolute;
        top: 208px" TabIndex="40" runat="server" ImageUrl="images/button_save.gif"></asp:ImageButton>
    <asp:Label ID="lblPrimaryKey" Style="z-index: 104; left: 42px; position: absolute;
        top: 49px" runat="server" CssClass="FieldLabel" Height="12px">99999</asp:Label>
    <asp:Label ID="Label3" Style="z-index: 105; left: 17px; position: absolute; top: 48px"
        runat="server" EnableViewState="False" CssClass="FieldLabel" Height="12px">ID:</asp:Label>
    <asp:Label ID="Label7" Style="z-index: 106; left: 225px; position: absolute; top: 79px"
        runat="server" EnableViewState="False" CssClass="FieldLabel" Height="24px">Lookup Title:</asp:Label>
    <asp:Label ID="lblMaxLen" runat="server" CssClass="FieldLabel" EnableViewState="False"
        Height="24px" Style="z-index: 114; left: 19px; position: absolute; top: 167px">Max Len:</asp:Label>
    <asp:Label ID="Label2" runat="server" CssClass="FieldLabel" EnableViewState="False"
        Height="29px" Style="z-index: 108; left: 227px; position: absolute; top: 129px"
        Width="238px">(Note: Leave Title blank unless you want display title in list different from stored value)</asp:Label>
    <asp:Label ID="Label1" runat="server" CssClass="FieldLabel" EnableViewState="False"
        Height="24px" Style="z-index: 109; left: 18px; position: absolute; top: 78px">Lookup Value:</asp:Label>
    &nbsp;
    <table id="Table1" style="z-index: 112; left: 16px; position: absolute; top: 8px;
        height: 2px" cellspacing="1" cellpadding="1" width="96%" border="0">
        <tr height="1">
            <td style="height: 6px" valign="top">
                <asp:Label ID="Label8" runat="server" EnableViewState="False" Width="88px" CssClass="PageHeading"
                    Height="24px">Edit Lookup</asp:Label>
            </td>
            <td style="height: 6px" valign="top" align="right">
                <asp:HyperLink ID="butHelp" runat="server" ImageUrl="images/button_help.gif">HyperLink</asp:HyperLink>
            </td>
        </tr>
    </table>
    <hr style="z-index: 113; left: 16px; position: absolute; top: 40px" width="98%" size="1">
    <asp:CheckBox ID="chkUserEditable" runat="server" Style="z-index: 110; left: 19px;
        position: absolute; top: 135px" Text="User Editable" TextAlign="Left" TabIndex="3" />
    <asp:TextBox ID="txtMaxLength" runat="server" Style="z-index: 111; left: 85px; position: absolute;
        top: 166px" Width="34px" TabIndex="4"></asp:TextBox>
    </form>
</body>
</html>
