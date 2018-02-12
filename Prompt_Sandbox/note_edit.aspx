<%@ Page Language="vb" ValidateRequest="false" %>

<%@ Register Assembly="Telerik.Web.UI" Namespace="Telerik.Web.UI" TagPrefix="telerik" %>
<%@ Import Namespace="Prompt" %>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">

<script runat="server">
    Private nNoteID As Integer = 0
    Private sParentRec As String = ""
    Private nParentRecID As Integer = 0
    
    Private Sub Page_Load(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MyBase.Load

        ProcLib.CheckSession(Page)
        ProcLib.LoadPopupJscript(Page)

        'set up help button
        Session("PageID") = "NoteEdit"
        butHelp.Attributes.Add("onclick", "openPopup('help_view.aspx','pophelp',550,450,'yes');")
        butHelp.NavigateUrl = "#"

        nNoteID = Request.QueryString("NoteID")
        nParentRecID = Request.QueryString("KeyValue")
        
        Dim item As New ListItem
        item.Text = "Everyone"
        item.Value = "Everyone"
        cboVisibility.Items.Add(item)
        
        If Session("UserRole") = "TechSupport" Or Session("UserRole") = "Project Accountant" Then
            item = New ListItem
            item.Text = "Accountants Only"
            item.Value = "Accountant"
            cboVisibility.Items.Add(item)
        End If
        If Session("UserRole") = "TechSupport" Or Session("UserRole") = "Project Manager" Then
            item = New ListItem
            item.Text = "Project Managers Only"
            item.Value = "ProjectManager"
            cboVisibility.Items.Add(item)
        End If

        Dim bAllowEdit As Boolean = False
        Using dbsec As New EISSecurity
            Select Case Request.QueryString("CurrentView")
                Case "college"
                    sParentRec = "CollegeID"
                    If dbsec.FindUserPermission("CollegeNotesTab", "Write") Or dbsec.FindUserPermission("CollegeNotesWidget", "Write") Then
                        bAllowEdit = True
                    End If

                Case "project"
                    sParentRec = "ProjectID"
                    If dbsec.FindUserPermission("ProjectNotesTab", "Write") Or dbsec.FindUserPermission("ProjectNotesWidget", "Write") Then
                        bAllowEdit = True
                    End If
                    
                Case "contract"
                    sParentRec = "ContractID"
                    If dbsec.FindUserPermission("ContractNotesTab", "Write") Or dbsec.FindUserPermission("ContractNotesWidget", "Write") Then
                        bAllowEdit = True
                    End If

                Case "ledgeraccount"
                    sParentRec = "LedgerAccountID"
                    bAllowEdit = dbsec.FindUserPermission("LedgerNotes", "Write")

            End Select

            If bAllowEdit Then
                butClose.Visible = False
                cboVisibility.Enabled = True
                
            Else
                txtCreatedOn.Enabled = False
                txtDescription.Enabled = False
                butSave.Visible = False
                butClose.Visible = True
                butDelete.Visible = False
                cboVisibility.Enabled = False
                
            End If
            
        End Using
        
        
        If Not IsPostBack Then

            If nNoteID = 0 Then
                butDelete.Visible = False
                txtCreatedOn.SelectedDate = Now()
            Else
                Using db As New promptNote
                    db.CallingPage = Page
                    db.GetNoteForEdit(nNoteID)
                End Using
            End If
 
        End If

        txtCreatedOn.Focus()

    End Sub
   

    Private Sub butDelete_Click(ByVal sender As System.Object, ByVal e As System.Web.UI.ImageClickEventArgs) Handles butDelete.Click
    
        Using db As New promptNote
            db.CallingPage = Page
            db.DeleteNote(nNoteID)
        End Using
        
        Session("RtnFromEdit") = True
        If Request.QueryString("WinType") = "RAD" Then
            ProcLib.CloseAndRefreshRAD(Page)
        Else
            ProcLib.CloseAndRefresh(Page)
        End If
        
    End Sub


    Private Sub butSave_Click(ByVal sender As System.Object, ByVal e As System.Web.UI.ImageClickEventArgs) Handles butSave.Click

        'fix the apostrophe problem
        txtDescription.Text = Replace(txtDescription.Text, "'", "''")
        
        If Not IsDate(txtCreatedOn.SelectedDate) Then
            txtCreatedOn.SelectedDate = Now()
        End If

        Using db As New promptNote
            db.CallingPage = Page
            db.ParentRecType = sParentRec
            db.ParentRecID = nParentRecID
            db.SaveNote(nNoteID)
            
        End Using

        Session("RtnFromEdit") = True
        
        If Request.QueryString("WinType") = "RAD" Then
            ProcLib.CloseAndRefreshRAD(Page)
        Else
            ProcLib.CloseAndRefresh(Page)
        End If
        
       
    End Sub
    
    Private Sub butClose_Click(ByVal sender As System.Object, ByVal e As System.Web.UI.ImageClickEventArgs) Handles butClose.Click

       
        If Request.QueryString("WinType") = "RAD" Then
            ProcLib.CloseOnlyRAD(Page)
        Else
            ProcLib.CloseOnly(Page)
        End If
        
       
    End Sub

 
</script>

<html>
<head>
    <title>Edit Note</title>
    <link href="Styles.css" type="text/css" rel="stylesheet" />

    <script type="text/javascript" language="javascript">

        function GetRadWindow() {
            var oWindow = null;
            if (window.RadWindow) oWindow = window.RadWindow;
            else if (window.frameElement.radWindow) oWindow = window.frameElement.radWindow;
            return oWindow;
        }

    </script>

</head>
<body>
    <form id="Form1" method="post" runat="server">
    <telerik:RadScriptManager ID="RadScriptManager1" runat="server" />
    <asp:Label ID="Label2" Style="z-index: 101; left: 10px; position: absolute; top: 12px"
        runat="server" Text="Date:"></asp:Label>
    <asp:Label ID="Label1" Style="z-index: 101; left: 423px; position: absolute; top: 12px"
        runat="server" Text="Date:"></asp:Label>
    <asp:DropDownList ID="cboVisibility" runat="server" Style="z-index: 101; left: 62px;
        position: absolute; top: 42px">
    </asp:DropDownList>
    <asp:HyperLink ID="butHelp" runat="server" ImageUrl="images/button_help.gif" Style="z-index: 101;
        left: 408px; position: absolute; top: 12px">HyperLink</asp:HyperLink>
    <asp:TextBox ID="txtDescription" Style="z-index: 102; left: 15px; position: absolute;
        top: 83px" TabIndex="1" runat="server" Height="272px" CssClass="EditDataDisplay"
        TextMode="MultiLine" Width="432px"></asp:TextBox>
    <telerik:RadDatePicker ID="txtCreatedOn" Style="z-index: 103; left: 62px; position: absolute;
        top: 11px" runat="server" Width="120px" Skin="Vista">
        <DateInput runat="server" Skin="Vista" Font-Size="13px" ForeColor="Blue">
        </DateInput>
    </telerik:RadDatePicker>
    <asp:ImageButton ID="butSave" Style="z-index: 104; left: 18px; position: absolute;
        top: 367px" TabIndex="5" runat="server" ImageUrl="images/button_save.gif"></asp:ImageButton>
    <asp:ImageButton ID="butClose" Style="z-index: 104; left: 142px; position: absolute;
        top: 369px" TabIndex="5" runat="server" ImageUrl="images/button_close.gif"></asp:ImageButton>
    <asp:ImageButton ID="butDelete" Style="z-index: 105; left: 349px; position: absolute;    
        top: 367px" TabIndex="6" runat="server" 
        OnClientClick="return confirm('You have selected to Delete this Note!\n\nAre you sure you want to delete this note?')"       
        ImageUrl="images/button_delete.gif">
    </asp:ImageButton>
    <asp:Label ID="Label3" Style="z-index: 101; left: 10px; position: absolute; top: 42px"
        runat="server" Text="Visibility:"></asp:Label>
    </form>
</body>
</html>
