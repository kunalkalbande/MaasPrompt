<%@ Page Language="vb" %>

<%@ Register Assembly="Telerik.Web.UI" Namespace="Telerik.Web.UI" TagPrefix="telerik" %>
<%@ Import Namespace="Prompt" %>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">

<script runat="server">

    Private nMeetingID As Integer = 0

    Private Sub Page_Load(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MyBase.Load

        ProcLib.CheckSession(Page)
        ProcLib.LoadPopupJscript(Page)

        Session("PageID") = "ApprisePMBondMeetingEdit"

        nMeetingID = Request.QueryString("MeetingID")
   
        'set up help button
        butHelp.Attributes.Add("onclick", "openPopup('help_view.aspx','pophelp',550,450,'yes');")
        butHelp.NavigateUrl = "#"

        If Not IsPostBack Then
            Using db As New BondSite
                db.CallingPage = Page
                If nMeetingID = 0 Then
                    butDelete.Visible = False
                Else
                    db.GetBondsiteMeetingForEdit(nMeetingID)
                End If
            End Using
        End If

        txtDescription.Focus()

    End Sub
    

    Private Sub butSave_Click(ByVal sender As System.Object, ByVal e As System.Web.UI.ImageClickEventArgs) Handles butSave.Click
    
        Using db As New BondSite
            db.CallingPage = Page
            db.SaveBondsiteMeeting(nMeetingID)
        End Using

        Session("RtnFromEdit") = True
        ProcLib.CloseAndRefreshRADNoPrompt(Page)
    End Sub

    Private Sub butDelete_Click(ByVal sender As System.Object, ByVal e As System.Web.UI.ImageClickEventArgs) Handles butDelete.Click
     
        Using db As New BondSite
            db.CallingPage = Page
            db.DeleteBondsiteMeeting(nMeetingID)
        End Using

        Session("RtnFromEdit") = True
        ProcLib.CloseAndRefreshRADNoPrompt(Page)
    End Sub




</script>

<html>
<head>
    <title>Apprise Bondsite Meeting Edit</title>
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
    <asp:ImageButton ID="butSave" Style="z-index: 113; left: 46px; position: absolute;
        top: 154px" TabIndex="5" runat="server" ImageUrl="images/button_save.gif"></asp:ImageButton>
    <asp:ImageButton ID="butDelete" Style="z-index: 107; left: 283px; position: absolute;
        top: 156px" TabIndex="6" runat="server" ImageUrl="images/button_delete.gif">
    </asp:ImageButton>
    <asp:HyperLink ID="butHelp" Style="z-index: 112; left: 470px; position: absolute;
        top: 24px" runat="server" ImageUrl="images/button_help.gif">HyperLink</asp:HyperLink>
    <asp:Label ID="Label3" Style="z-index: 105; left: 29px; position: absolute; top: 67px"
        runat="server" Height="24px">Description:</asp:Label>
    <asp:Label ID="Label2" Style="z-index: 105; left: 31px; position: absolute; top: 26px"
        runat="server" Height="24px">Date:</asp:Label>
    <telerik:RadDatePicker ID="txtMeetingDate" Style="z-index: 103; left: 109px; position: absolute;
        top: 25px" runat="server" Width="120px" Skin="Web20">
        <DateInput runat="server" Skin="WebBlue" Font-Size="13px" ForeColor="Blue">
        </DateInput>
        <Calendar runat="server" UseRowHeadersAsSelectors="False" UseColumnHeadersAsSelectors="False"
            ViewSelectorText="x" Skin="Web20">
             <SpecialDays> 
            <telerik:RadCalendarDay Repeatable="Today"> 
                <ItemStyle BackColor="LightBlue" /> 
            </telerik:RadCalendarDay> 
        </SpecialDays> 
        </Calendar>
        <DatePopupButton ImageUrl="" HoverImageUrl=""></DatePopupButton>
    </telerik:RadDatePicker>
    <asp:TextBox ID="txtDescription" Style="z-index: 103; left: 107px; position: absolute;
        top: 64px" runat="server" Height="24px" Width="352px" TabIndex="2" CssClass="EditDataDisplay"></asp:TextBox>
    </form>
</body>
</html>
