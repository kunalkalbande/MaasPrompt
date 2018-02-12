<%@ Page Language="vb" %>
<%@ Import Namespace="Prompt" %>
<%@ Register Assembly="Telerik.Web.UI" Namespace="Telerik.Web.UI" TagPrefix="telerik" %>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">

<script runat="server">
    Public nCalendarID As Integer = 0
    Public nCollegeID As Integer = 0
    Public nProjectID As Integer = 0
    
    Private Sub Page_Load(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MyBase.Load


        ProcLib.CheckSession(Page)

        'set up help button

        ProcLib.LoadPopupJscript(Page)
        
        lblMessage.Text = ""

        Session("PageID") = "CalendarEdit"
        butHelp.Attributes.Add("onclick", "openPopup('help_view.aspx','pophelp',550,450,'yes');")
        butHelp.NavigateUrl = "#"

        If Request.QueryString("ID") = 0 Then
            nCalendarID = 0
            Page.Title = "New Calendar"
        Else
            nCalendarID = Session("CurrentCalendarID")
            Page.Title = "Edit Calendar"
        End If
        
        nCollegeID = Request.QueryString("CollegeID")
        
        If IsPostBack Then   'only do the following post back
            nCalendarID = lblCalendarID.Text
        Else
            
            Using db As New PromptDataHelper
                If nCalendarID = 0 Then    'add the new record
                    butDelete.Visible = False
                    Page.Title = "Add Calendar"
                Else
                    db.FillForm(Form1, "SELECT * FROM Calendars WHERE CalendarID = " & nCalendarID)
                    
                    'now set the color
                    colorPicker.SelectedColor = ColorTranslator.FromHtml(txtItemColor.Value)
                    
                End If
                lblCalendarID.Text = nCalendarID
            End Using
        End If
        
        txtName.Focus()
    End Sub
    
  

    Private Sub butSave_Click(ByVal sender As System.Object, ByVal e As System.Web.UI.ImageClickEventArgs) Handles butSave.Click
        If Trim(txtName.Text) = "" Then
            lblMessage.Text = "Please enter a Calendar Name."
        Else
            
            Dim sname As String = txtName.Text
            sname = sname.Replace("'", "''")
            
            Using db As New PromptDataHelper
                Dim sql As String = ""
                If nCalendarID = 0 Then
                    sql = "INSERT INTO Calendars (Name,CollegeID,ItemColor) VALUES ('" & sname & "'," & nCollegeID & ",'Blue')"
                    sql &= ";SELECT NewKey = Scope_Identity()"  'return the new primary key
                    nCalendarID = db.ExecuteScalar(sql)
                End If

                'update manaully as colorpicker is a problem
                sql = "UPDATE Calendars SET Name = '" & sname & "',ItemColor='" & ColorTranslator.ToHtml(colorPicker.SelectedColor) & "' "
                sql &= "WHERE CalendarID = " & nCalendarID
                db.ExecuteNonQuery(sql)
               
            End Using
        End If
 
 
        ProcLib.CloseAndRefreshRAD(Page)

    End Sub

    Private Sub butDelete_Click(ByVal sender As System.Object, ByVal e As System.Web.UI.ImageClickEventArgs) Handles butDelete.Click
        
        Using db As New PromptDataHelper
            Dim sql As String = ""
           
            sql = "DELETE FROM Calendars WHERE CalendarID = " & nCalendarID
            db.ExecuteNonQuery(sql)
            
            sql = "DELETE FROM CalendarEntries WHERE CalendarID = " & nCalendarID
            db.ExecuteNonQuery(sql)
               
        End Using
        
        ProcLib.CloseAndRefreshRAD(Page)
        
    End Sub



</script>

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title>Edit Calendar</title>
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
    
    
    
    <asp:TextBox ID="txtName" Style="z-index: 104; left: 107px; position: absolute;
        top: 20px" runat="server" Width="192px" EnableViewState="False" 
        CssClass="EditDataDisplay"></asp:TextBox>
    <asp:ImageButton ID="butDelete" Style="z-index: 110; left: 169px; position: absolute;
        top: 111px" TabIndex="6" runat="server" 
        ImageUrl="images/button_delete.gif">
    </asp:ImageButton>
    <asp:Label ID="lblCalendarID" Style="z-index: 107; left: 322px; position: absolute;
        top: 116px" runat="server" Height="12px" CssClass="FieldLabel">999</asp:Label>
    <asp:Label ID="Label9" Style="z-index: 106; left: 290px; position: absolute; top: 115px; width: 15px; bottom: 774px; height: 4px;"
        runat="server" EnableViewState="False" CssClass="FieldLabel">ID:</asp:Label>
    <asp:Label ID="lblMessage" Style="z-index: 106; left: 9px; position: absolute; top: 82px; width: 332px; bottom: 807px; height: 4px;"
        runat="server" EnableViewState="False" CssClass="FieldLabel" 
        ForeColor="Red">message</asp:Label>
    &nbsp;&nbsp;
    <asp:Label ID="Label8" Style="z-index: 100; left: 9px; position: absolute; top: 21px"
        runat="server" EnableViewState="False" Height="24px" CssClass="FieldLabel">Calendar Name:</asp:Label>

    <asp:Label ID="Label7" Style="z-index: 100; left: 9px; position: absolute; top: 55px; width: 203px;"
        runat="server" EnableViewState="False" Height="24px" CssClass="FieldLabel">Color for multi-calendar display:</asp:Label>

    <asp:ImageButton ID="butSave" Style="z-index: 109; left: 12px; position: absolute;
        top: 111px" TabIndex="5" runat="server" ImageUrl="images/button_save.gif"></asp:ImageButton>
 <asp:HyperLink ID="butHelp" runat="server" Style="z-index: 104; left: 312px; position: absolute;
        top: 4px"  ImageUrl="images/button_help.gif">HyperLink</asp:HyperLink>
        
        <telerik:RadColorPicker ID="colorPicker" runat="server" 
        Style="z-index: 104; left: 206px; position: absolute; top: 52px; width: 109px; height: 35px;" 
        Preset="Standard" SelectedColor="Blue" ShowEmptyColor="False" 
        Skin="Windows7" ShowIcon="True">
<Localization RGBSlidersTabText=" RGB Sliders"></Localization>
    </telerik:RadColorPicker>
    
    <asp:HiddenField ID="txtItemColor" runat="server" Value=""/>
        
    </form>
    
</body>
</html>
