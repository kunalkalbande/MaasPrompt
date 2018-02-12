<%@ Page Language="vb" ValidateRequest="false" %>

<%@ Import Namespace="Prompt" %>
<%@ Register Assembly="Telerik.Web.UI" Namespace="Telerik.Web.UI" TagPrefix="telerik" %>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">

<script runat="server">
    
    Public nProjectGroupID As Integer = 0
    
    Private nCollegeID As Integer = 0
    Private bAdding As Boolean = False
    
    Private Sub Page_Load(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MyBase.Load

        ProcLib.CheckSession(Page)
        ProcLib.LoadPopupJscript(Page)
        
        'set up help button
        Session("PageID") = "ProjectGroupEdit"
        butHelp.Attributes.Add("onclick", "openPopup('help_view.aspx','pophelp',550,450,'yes');")
        butHelp.NavigateUrl = "#"

        lblmsg.Visible = False
        nProjectGroupID = Request.QueryString("ProjectGroupID")
        nCollegeID = Request.QueryString("CollegeID")
         
        If nProjectGroupID = 0 Then
            butDelete.Visible = False
            bAdding = True
        End If
        
        If IsPostBack Then   'only do the following post back
            nProjectGroupID = lblID.Text
        Else  'only do the following on first load
            Using db As New promptProject
                db.CallingPage = Page
                db.GetProjectGroupForEdit(nProjectGroupID)      'get data and Fill the drop downs
               
                lblID.Text = nProjectGroupID
                Dim vsChildProjectsStatus As String = db.GetAllCollegeProjects(lstProjects, nCollegeID, nProjectGroupID)
                ViewState.Add("vsProjectStatus", vsChildProjectsStatus)
            End Using
        End If
        
        txtName.Focus()

    End Sub
   

    Private Sub butDelete_Click(ByVal sender As System.Object, ByVal e As System.Web.UI.ImageClickEventArgs) Handles butDelete.Click
        Using db As New promptProject
            db.CallingPage = Page
            db.DeleteProjectGroup(nProjectGroupID)
        End Using
        Session("RtnFromEdit") = True
        Session("nodeid") = "College" & nCollegeID    'locate to parent college
        Session("RefreshNav") = True
        Session("delproject") = True
        ProcLib.CloseAndRefreshRAD(Page)

    End Sub


    Private Sub butSave_Click(ByVal sender As System.Object, ByVal e As System.Web.UI.ImageClickEventArgs) Handles butSave.Click
        If txtName.Text = "" Then
            lblmsg.Visible = True
            lblmsg.Text = "Project Name is required."
            Exit Sub
        End If
        If lstProjects.CheckedItems.Count = 0 Then
            lblmsg.Visible = True
            lblmsg.Text = "You must have at least one project assigned to a group. "
            Exit Sub
        End If
                
        'Check that there are no checked projects that are active when group status is not set to active
        Dim sMessage As String = ""
        If lstStatus.SelectedItem.Text <> "Active" Then
            Dim sProjectStatusList As String = ViewState("vsProjectStatus")    'get the previously saved project statuss
            Dim aList As String() = sProjectStatusList.Split("::")   'break the string into a list of project/status pairs
            
            For Each item As RadListBoxItem In lstProjects.CheckedItems            'look for the corresponding project
                For Each sp In aList
                    Dim aProject As String() = sp.Split(",")   'now we have a 2 column array with id and status
                    If aProject(0) = item.Value Then                'we have selected a project and now should check the status
                        If aProject(1) = "1-Active" Then
                            sMessage = "Sorry, you cannot change a group status to other than Active when it contains Active Projects."
                            Exit For
                        End If
                    End If
                    If sMessage <> "" Then
                        Exit For
                    End If
                Next
            Next
        End If
 
        If sMessage <> "" Then
            lblmsg.Visible = True
            lblmsg.Text = sMessage
            Exit Sub
            
        End If
        
        Using db As New promptProject
            db.CallingPage = Page
            nProjectGroupID = db.SaveProjectGroup(nProjectGroupID, nCollegeID)
        End Using
        
         
        Session("RtnFromEdit") = True
        Session("nodeid") = "ProjectGroup" & nProjectGroupID
        Session("RefreshNav") = True
        ProcLib.CloseAndRefreshRAD(Page)


    End Sub


</script>

<html style="height:560px">
<head>
    <title>Edit Project Group</title>
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
<body style="height:560px">
    <form id="Form1" method="post" runat="server">
    <telerik:RadScriptManager ID="RadScriptManager1" runat="server" />
    <asp:HyperLink ID="butHelp" runat="server" ImageUrl="images/button_help.gif" Style="z-index: 100;
        left: 411px; position: absolute; top: 8px">HyperLink</asp:HyperLink>
    <asp:Label ID="Label9" Style="z-index: 100; left: 9px; position: absolute; top: 413px;
        bottom: 476px;" runat="server">Sub Projects:</asp:Label>
    <asp:Label ID="Label14" Style="z-index: 100; left: 8px; position: absolute; top: 100px;"
        runat="server">Start Date:</asp:Label>
    <asp:Label ID="Label16" Style="z-index: 100; left: 9px; position: absolute; top: 176px;
        height: 4px;" runat="server">Prev Budget:</asp:Label>
    <asp:Label ID="Label13" Style="z-index: 100; left: 221px; position: absolute; top: 175px;
        height: 20px;" runat="server"> Prev Expenses:</asp:Label>
    <asp:Label ID="Label11" Style="z-index: 100; left: 13px; position: absolute; top: 134px"
        runat="server">Status:</asp:Label>
    <asp:Label ID="Label10" Style="z-index: 100; left: 206px; position: absolute; top: 137px"
        runat="server">Phase:</asp:Label>
    <asp:Label ID="Label1" Style="z-index: 100; left: 12px; position: absolute; top: 28px"
        runat="server">Name:</asp:Label>
    <asp:Label ID="lblmsg" runat="server" ForeColor="Red" Style="z-index: 115; left: 15px;
        position: absolute; top: 565px" Width="422px">message</asp:Label>
    <asp:ImageButton ID="butSave" Style="z-index: 106; left: 12px; position: absolute;
        top: 535px" TabIndex="5" runat="server" ImageUrl="images/button_save.gif"></asp:ImageButton>
    <asp:ImageButton ID="butDelete" Style="z-index: 107; left: 295px; position: absolute;
        top: 534px" TabIndex="6" runat="server" 
        OnClientClick="return confirm('You are about to delete this Project Group!\n\nAre you sure you want to delete this Project Group?')"
        ImageUrl="images/button_delete.gif">
    </asp:ImageButton>
    <asp:Label ID="Label2" runat="server" CssClass="smalltext" Height="16px" Style="z-index: 108;
        left: 15px; position: absolute; top: 6px">ID:</asp:Label>
    <asp:Label ID="lblID" runat="server" CssClass="ViewDataDisplay" Height="16px" Style="z-index: 109;
        left: 38px; position: absolute; top: 5px">###</asp:Label>
    <asp:TextBox ID="txtPhase" runat="server" CssClass="EditDataDisplay" Style="z-index: 111;
        left: 261px; position: absolute; top: 136px; width: 105px;" TabIndex="41"></asp:TextBox>
    <asp:TextBox ID="txtProjectNumber" runat="server" CssClass="EditDataDisplay" Style="z-index: 111;
        left: 62px; position: absolute; top: 62px; width: 79px;" TabIndex="41"></asp:TextBox>
    <asp:TextBox ID="txtName" runat="server" CssClass="EditDataDisplay" Style="z-index: 111;
        left: 62px; position: absolute; top: 27px; width: 326px;" TabIndex="40"></asp:TextBox>
    <asp:Label ID="Label12" Style="z-index: 100; left: 7px; position: absolute; top: 65px;
        height: 21px;" runat="server">Number:</asp:Label>
    <asp:DropDownList ID="lstArchitect" runat="server" Style="z-index: 100; left: 88px;
        position: absolute; top: 208px; height: 24px; width: 102px;">
    </asp:DropDownList>
    <asp:DropDownList ID="lstProjectManager" runat="server" Style="z-index: 100; left: 263px;
        position: absolute; top: 209px; height: 24px; width: 102px;">
    </asp:DropDownList>
    <telerik:RadListBox ID="lstProjects" runat="server" Style="z-index: 105; left: 12px;
        position: absolute; top: 440px;" CheckBoxes="True" SelectionMode="Multiple" Height="75px"
        Width="420px">
    </telerik:RadListBox>
    <asp:DropDownList ID="lstStatus" Style="z-index: 141; left: 63px; position: absolute;
        top: 133px; width: 110px;" TabIndex="3" runat="server" CssClass="EditDataDisplay">
    </asp:DropDownList>
    <telerik:RadNumericTextBox ID="txtPreviousExpenses" Style="z-index: 119; left: 310px;
        position: absolute; top: 173px" Width="95px" TabIndex="20" runat="server" Enabled="True"
        SelectionOnFocus="SelectAll" MinValue="0" AutoPostBack="False" NumberFormat-DecimalDigits="2">
        <NumberFormat AllowRounding="True" DecimalDigits="2" PositivePattern="$ n"></NumberFormat>
    </telerik:RadNumericTextBox>
    <telerik:RadNumericTextBox ID="txtPreviousBudget" Style="z-index: 119; left: 90px;
        position: absolute; top: 173px" Width="95px" TabIndex="20" runat="server" Enabled="True"
        SelectionOnFocus="SelectAll" MinValue="0" AutoPostBack="False" NumberFormat-DecimalDigits="2">
        <NumberFormat AllowRounding="True" DecimalDigits="2" PositivePattern="$ n"></NumberFormat>
    </telerik:RadNumericTextBox>
    <asp:Label ID="Label17" runat="server" Text="Architect:" Style="z-index: 100; left: 13px;
        position: absolute; top: 210px; height: 17px;"></asp:Label>
    <asp:Label ID="Label3" runat="server" Text="PM:" Style="z-index: 100; left: 11px;
        position: absolute; top: 210px; left: 224px; height: 17px;"></asp:Label>
    <telerik:RadDatePicker ID="txtStartDate" Style="z-index: 155; left: 69px; position: absolute;
        top: 100px" runat="server" TabIndex="12" Width="120px">
        <DateInput ID="DateInput1" runat="server" Skin="Vista" Font-Size="13px" ForeColor="Blue">
        </DateInput>
    </telerik:RadDatePicker>
    <telerik:RadDatePicker ID="txtEndDate" Style="z-index: 155; left: 286px; position: absolute;
        top: 101px" runat="server" TabIndex="12" Width="120px">
        <DateInput ID="DateInput2" runat="server" Skin="Vista" Font-Size="13px" ForeColor="Blue">
        </DateInput>
    </telerik:RadDatePicker>
    <br />
    &nbsp;&nbsp;
    <asp:Label ID="Label4" runat="server" Text="CM/DM Report Project Notes:" Style="z-index: 155;
        left: 11px; position: absolute; top: 242px"></asp:Label>
    <br />
    &nbsp;&nbsp;
    <asp:TextBox ID="txtBudgetEstimateNotes" runat="server" TextMode="MultiLine" Height="35"
        Style="z-index: 155; left: 12px; position: absolute; top: 265px; width: 400px;"></asp:TextBox>
    <asp:Label ID="Label15" Style="z-index: 100; left: 216px; position: absolute; top: 105px"
        runat="server">End Date:</asp:Label>
    <br />
    <br />
    &nbsp;&nbsp;
    <asp:Label ID="Label5" runat="server" Text="CM/DM Report Status:" Style="z-index: 155;
        left: 14px; position: absolute; top: 313px"></asp:Label>
    &nbsp;&nbsp;
    <telerik:RadComboBox ID="cboCMDM_Status" runat="server" Width="175px" Style="z-index: 5155;
        left: 177px; position: absolute; top: 312px">
        <Items>
            <telerik:RadComboBoxItem runat="server" Text="- Auto Calc -" Value="-auto calc-" />
            <telerik:RadComboBoxItem runat="server" Text="caution" Value="caution" />
            <telerik:RadComboBoxItem runat="server" Text="N/A" Value="N/A" />
            <telerik:RadComboBoxItem runat="server" Text="ok" Value="ok" />
            <telerik:RadComboBoxItem runat="server" Text="problem" Value="problem" />
        </Items>
    </telerik:RadComboBox>
    &nbsp;&nbsp;
    <asp:Label ID="Label6" runat="server" Text="CM/DM Proj Budget Status:" Style="z-index: 155;
        left: 11px; position: absolute; top: 346px"></asp:Label>
    &nbsp;&nbsp;
    <telerik:RadComboBox ID="cboCMDM_ProjectBudgetStatus" runat="server" Width="175px"
        Style="z-index: 4155; left: 179px; position: absolute; top: 346px">
        <Items>
            <telerik:RadComboBoxItem runat="server" Text="- Auto Calc -" Value="-auto calc-" />
            <telerik:RadComboBoxItem runat="server" Text="caution" Value="caution" />
            <telerik:RadComboBoxItem runat="server" Text="N/A" Value="N/A" />
            <telerik:RadComboBoxItem runat="server" Text="ok" Value="ok" />
            <telerik:RadComboBoxItem runat="server" Text="problem" Value="problem" />
        </Items>
    </telerik:RadComboBox>
    <br />
    <br />
    &nbsp;&nbsp;
    <asp:Label ID="Label7" runat="server" Text="CM/DM Est At Complete Status:" Style="z-index: 3155;
        left: 7px; position: absolute; top: 380px"></asp:Label>
    &nbsp;&nbsp;
    <telerik:RadComboBox ID="cboCMDM_EstimateAtCompletionStatus" runat="server" Width="175px"
        Style="z-index: 3155; left: 185px; position: absolute; top: 378px">
        <Items>
            <telerik:RadComboBoxItem runat="server" Text="- Auto Calc -" Value="-auto calc-" />
            <telerik:RadComboBoxItem runat="server" Text="caution" Value="caution" />
            <telerik:RadComboBoxItem runat="server" Text="N/A" Value="N/A" />
            <telerik:RadComboBoxItem runat="server" Text="ok" Value="ok" />
            <telerik:RadComboBoxItem runat="server" Text="problem" Value="problem" />
        </Items>
    </telerik:RadComboBox>
    </form>
</body>
</html>
