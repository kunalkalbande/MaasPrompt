<%@ Page Language="vb" %>

<%@ Register Assembly="Telerik.Web.UI" Namespace="Telerik.Web.UI" TagPrefix="telerik" %>
<%@ Import Namespace="Prompt" %>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">

<script runat="server">

    Private nLinkID As Integer = 0

    Private Sub Page_Load(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MyBase.Load

        ProcLib.CheckSession(Page)
        ProcLib.LoadPopupJscript(Page)

        Session("PageID") = "ApprisePMBondLinkEdit"

        nLinkID = Request.QueryString("LinkID")
   
        'set up help button
        butHelp.Attributes.Add("onclick", "openPopup('help_view.aspx','pophelp',550,450,'yes');")
        butHelp.NavigateUrl = "#"

        If Not IsPostBack Then
            Using db As New BondSite
                db.CallingPage = Page
                If nLinkID = 0 Then
                    butDelete.Visible = False
                Else
                    db.GetBondsiteLinkForEdit(nLinkID)
                End If
            End Using
        End If

        txtLinkURL.Focus()

    End Sub
    

    Private Sub butSave_Click(ByVal sender As System.Object, ByVal e As System.Web.UI.ImageClickEventArgs) Handles butSave.Click
    
        Using db As New BondSite
            db.CallingPage = Page
            db.SaveBondsiteLink(nLinkID)
        End Using

        Session("RtnFromEdit") = True
        ProcLib.CloseAndRefreshRADNoPrompt(Page)
    End Sub

    Private Sub butDelete_Click(ByVal sender As System.Object, ByVal e As System.Web.UI.ImageClickEventArgs) Handles butDelete.Click
     
        Using db As New BondSite
            db.CallingPage = Page
            db.DeleteBondsiteLink(nLinkID)
        End Using

        Session("RtnFromEdit") = True
        ProcLib.CloseAndRefreshRADNoPrompt(Page)
    End Sub

	   
    </script>

<html>
<head>
    <title>Apprise Bondsite Link Edit</title>
    <meta content="Microsoft Visual Studio .NET 7.1" name="GENERATOR" />
    <meta content="Visual Basic .NET 7.1" name="CODE_LANGUAGE" />
    <meta content="JavaScript" name="vs_defaultClientScript" />
    <meta content="http://schemas.microsoft.com/intellisense/ie5" name="vs_targetSchema" />
    <link href="Styles.css" type="text/css" rel="stylesheet" />
            <script type="text/javascript" language="javascript">


        function GetRadWindow() {
            var oWindow = null;
            if (window.radWindow) oWindow = window.radWindow; //Will work in Moz in all cases, including clasic dialog
            else if (window.frameElement.radWindow) oWindow = window.frameElement.radWindow; //IE (and Moz az well)

            return oWindow;
        }

 	   
    </script>

</head>
<body>
   <form id="Form1" method="post" runat="server">
     <telerik:RadScriptManager ID="RadScriptManager1" runat="server" />
    <asp:ImageButton ID="butSave" Style="z-index: 113; left: 41px; position: absolute;
        top: 177px" TabIndex="5" runat="server" ImageUrl="images/button_save.gif"></asp:ImageButton>
    <asp:ImageButton ID="butDelete" Style="z-index: 107; left: 282px; position: absolute;
        top: 178px" TabIndex="6" runat="server" 
        ImageUrl="images/button_delete.gif">
    </asp:ImageButton>
    <asp:HyperLink ID="butHelp" Style="z-index: 112; left: 470px; position: absolute;
        top: 24px" runat="server" ImageUrl="images/button_help.gif">HyperLink</asp:HyperLink>
    <asp:Label ID="Label4" Style="z-index: 105; left: 30px; position: absolute; top: 123px; right: 1187px;"
        runat="server" Height="24px">Link:</asp:Label>
    <asp:Label ID="Label2" Style="z-index: 105; left: 30px; position: absolute; top: 48px; height: 24px;"
        runat="server">Title:</asp:Label>
     <asp:TextBox ID="txtDescription" Style="z-index: 103; left: 101px; position: absolute;
        top: 84px" runat="server" Height="24px" Width="352px" TabIndex="2" 
        CssClass="EditDataDisplay" ></asp:TextBox>
     <asp:TextBox ID="txtTitle" Style="z-index: 103; left: 101px; position: absolute;
        top: 47px" runat="server" Height="24px" Width="352px" TabIndex="2" 
        CssClass="EditDataDisplay"></asp:TextBox>
     <asp:TextBox ID="txtLinkURL" Style="z-index: 103; left: 101px; position: absolute;
        top: 123px" runat="server" Height="24px" Width="352px" TabIndex="2" 
        CssClass="EditDataDisplay"></asp:TextBox>
    <asp:Label ID="Label3" Style="z-index: 105; left: 30px; position: absolute; top: 85px"
        runat="server" Height="24px">Description:</asp:Label>
    </form>
</body>
</html>
