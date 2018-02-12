<%@ Page Language="vb" %>

<%@ Register Assembly="Telerik.Web.UI" Namespace="Telerik.Web.UI" TagPrefix="telerik" %>
<%@ Import Namespace="Prompt" %>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">

<script runat="server">
    
    Public nPassthroughEntryID As Integer = 0
    Public nProjectID As Integer = 0
    
    Private Sub Page_Load(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MyBase.Load

        ProcLib.CheckSession(Page)
        ProcLib.LoadPopupJscript(Page)

        lblDateRequired.Visible = False
        
        'set up help button
        Session("PageID") = "PassthroughEntryEdit"
        butHelp.Attributes.Add("onclick", "openPopup('help_view.aspx','pophelp',550,450,'yes');")
        butHelp.NavigateUrl = "#"


        nPassthroughEntryID = Request.QueryString("PassthroughEntryID")
        nProjectID = Request.QueryString("ProjectID")
        
          
        If IsPostBack Then   'only do the following post back
            nPassthroughEntryID = lblID.Text
        Else  'only do the following on first load
            Using db As New promptPassthrough
                db.CallingPage = Page
                db.GetExistingPassthroughEntry(nPassthroughEntryID)
                
                If db.IsPassthroughProject(nProjectID) Then  'only allow delete
                    butSave.Visible = False
                    lblDateRequired.Text = "Since this is the parent allocation entry, you must delete and recreate if you want to change allocation."
                    lblDateRequired.Visible = True
                    txtEntryDate.Enabled = False
                    txtAmount.Enabled = False
                    txtDescription.Enabled = False
                    
                End If
                lblID.Text = nPassthroughEntryID
                
                oldAmount.Value = txtAmount.Value   'store old amount for later
               
            End Using
        End If

        txtEntryDate.Focus()

    End Sub
   

    Private Sub butDelete_Click(ByVal sender As System.Object, ByVal e As System.Web.UI.ImageClickEventArgs) Handles butDelete.Click
        Using db As New promptPassthrough
            db.CallingPage = Page
            db.DeleteEntry(nPassthroughEntryID, nProjectID)
           
        End Using
        Session("RtnFromEdit") = True
        ProcLib.CloseAndRefreshRAD(Page)
    End Sub


    Private Sub butSave_Click(ByVal sender As System.Object, ByVal e As System.Web.UI.ImageClickEventArgs) Handles butSave.Click
        If IsNothing(txtEntryDate.SelectedDate) Or txtAmount.Text = "" Then
            lblDateRequired.Visible = True
        Else
            Using db As New promptPassthrough
                db.CallingPage = Page
                db.SaveEntry(nPassthroughEntryID)
            End Using
            Session("RtnFromEdit") = True
            ProcLib.CloseAndRefreshRAD(Page)
        End If

    End Sub


  
</script>

<html>
<head>
    <title>Edit Passthrough Entry</title>
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
    <asp:Label ID="Label1" Style="z-index: 100; left: 10px; position: absolute; top: 12px"
        runat="server">Date:</asp:Label>
    <asp:Label ID="Label9" runat="server" Style="z-index: 102; left: 15px; position: absolute;
        top: 81px">Amount:</asp:Label>
    <asp:Label ID="Label4" runat="server" Style="z-index: 103; left: 7px; position: absolute;
        top: 50px">Description:</asp:Label>

    <asp:HyperLink ID="butHelp" runat="server" ImageUrl="images/button_help.gif" style="z-index: 113; left: 338px; position: absolute; top: 4px">HyperLink</asp:HyperLink>
    <telerik:RadDatePicker runat="server" Style="z-index: 20; left: 83px; position: absolute;
        top: 10px" ID="txtEntryDate" Width="120px">
        <DateInput Skin="Vista" Font-Size="13px" ForeColor="Blue">
        </DateInput>
    </telerik:RadDatePicker>
    <asp:ImageButton ID="butSave" Style="z-index: 106; left: 10px; position: absolute;
        top: 144px" TabIndex="5" runat="server" ImageUrl="images/button_save.gif"></asp:ImageButton>
    <asp:ImageButton ID="butDelete" Style="z-index: 107; left: 178px; position: absolute;
        top: 143px; bottom: 738px;" TabIndex="6" runat="server" 
         ImageUrl="images/button_delete.gif">
    </asp:ImageButton>
    <asp:Label ID="Label2" runat="server" CssClass="smalltext" Height="16px" Style="z-index: 108;
        left: 324px; position: absolute; top: 145px">ID:</asp:Label>
    <asp:Label ID="lblID" runat="server" CssClass="ViewDataDisplay" Height="16px" Style="z-index: 109;
        left: 357px; position: absolute; top: 147px">###</asp:Label>
    <asp:TextBox ID="txtDescription" runat="server" CssClass="EditDataDisplay" Style="z-index: 111;
        left: 80px; position: absolute; top: 46px" TabIndex="40" Width="356px"></asp:TextBox>
    &nbsp; &nbsp;
    <telerik:RadNumericTextBox Label="  " ID="txtAmount" runat="server" Style="z-index: 112;
        left: 79px; position: absolute; top: 81px; width: 80px;" SelectionOnFocus="SelectAll"
        MinValue="-100000000" TabIndex="15" AutoPostBack="False" ToolTip="Amount of Allocation."
        Width="100px">
    </telerik:RadNumericTextBox>
    <asp:Label ID="lblDateRequired" runat="server" ForeColor="Red" Style="z-index: 115;
        left: 11px; position: absolute; top: 110px; height: 8px;" Width="422px">Date and Amount are Required</asp:Label>
    <asp:HiddenField ID="oldAmount" runat="server" />
    </form>
</body>
</html>
