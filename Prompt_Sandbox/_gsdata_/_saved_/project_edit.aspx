<%@ Page Language="vb" %>

<%@ Register Assembly="Telerik.Web.UI" Namespace="Telerik.Web.UI" TagPrefix="telerik" %>
<%@ Import Namespace="Prompt" %>


<script runat="server">
  
    Public nProjectID As String = ""
    Public nCollegeID As String = ""
    Private message As String = ""
    Private bAdding As Boolean = False
    
    Private Sub Page_Load(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MyBase.Load

        ProcLib.CheckSession(Page)
        ProcLib.LoadPopupJscript(Page)

        'set up help button
        Session("PageID") = "ProjectEdit"
 
        nProjectID = Request.QueryString("ProjectID")
        nCollegeID = Session("CollegeID")
        
        lblMessage.Text = ""

        Using db As New EISSecurity
            db.CollegeID = Session("CollegeID")
            db.ProjectID = nProjectID
            If db.FindUserPermission("ProjectInfo", "Write") Then
                butFlag.Visible = True
            Else
                butFlag.Visible = False
            End If

        End Using
        
        If Request.QueryString("new") = "y" Then
            bAdding = True
        End If
 

        If IsPostBack Then   'only do the following post back
            nProjectID = lblProjectID.Text
        Else  'only do the following on first load
            ' Using db As New promptProject
            'db.CallingPage = Page
            If bAdding Then    'new project
                'get data and Fill the drop downs
                'db.GetNewProject()
                nProjectID = 0
                butDelete.Visible = False
                butFlag.Visible = False
            End If
                
            LoadEditForm()
            'lnkChangeBudget.Visible = False
                
            'If db.IsOriginalBudget = False Then  'this is not the original budget
            '    'Check to see if current budget = 0  -- if so allow direct change
            '    If db.BudgetAmount = 0 Then
            '        If db.LockCurrentBudgets = False Then  'allow changes
            '            txtOrigBudget.Enabled = True
            '        End If
            '    Else                     'disable the budget field
            '        txtOrigBudget.Enabled = False
            '        If db.LockCurrentBudgets = True Then  'project budget is locked so disallow changes
            '            lnkChangeBudget.Visible = False
            '        Else     'allow changes only through popup as this is not the original budget
            '            lnkChangeBudget.Visible = True
            '        End If
            '    End If
            'Else      'there are no budget change batches
            '    If db.LockCurrentBudgets = False Then  'allow changes
            '        txtOrigBudget.Enabled = True
            '    End If
            'End If
            'lblBudgetChangeBatch.Text = db.BudgetBatchDescription
                
            lblProjectID.Text = nProjectID
            'End Using
        End If
        
        'Format the budget lable
        'If Session("newprojectbudget") <> "" Then  'this load is called from the budget change screen
        '    txtOrigBudget.Value = Session("newprojectbudget")
        '    Session("newprojectbudget") = ""
        'End If

        ''disable this for now.
        'txtOrigBudget.Visible = False
        'lblbudgetbatch.Visible = False
        'lblBudgetChangeBatch.Visible = False
        'lblcurrentbudget.Visible = False
        
        'check for passback value and if there, add entry to dropdown and select
        If Session("passback") <> "" Then
            Dim i As New ListItem
            i.Text = Session("passback")
            i.Value = Session("passbackID")
            If Session("passbacktype") = "architect" Then
                lstArchID.Items.Add(i)
                lstArchID.SelectedValue = i.Value
            End If
            If Session("passbacktype") = "contractor" Then
                lstGC_Arch_ID.Items.Add(i)
                lstGC_Arch_ID.SelectedValue = i.Value
            End If
            
            If Session("passbacktype") = "CM" Then
                lstCMID.Items.Add(i)
                lstCMID.SelectedValue = i.Value
            End If
            Session("passbacktype") = ""
            Session("passback") = ""
            Session("passbackID") = ""
        End If
        
        SetupRadWindows()
        
        txtProjectName.Focus()
        
        
    End Sub
    
    Private Sub LoadEditForm()

        'loads a parent form with data from passed row
        Using db As New PromptDataHelper
 
       
            Dim form As Control = Form1  ' get ref to calling form

            Dim nDistrictID As Integer = Session("DistrictID")
            Dim sql As String = ""

            'Fill the dropdown controls on parent form
            sql = "SELECT ContactID As Val, Name as Lbl FROM dbo.Contacts WHERE ContactType='ProjectManager' AND (DistrictID = " & nDistrictID & " OR DistrictID = 0) ORDER BY Name ASC"
            db.FillDropDown(sql, form.FindControl("lstPM"), False, True, False)

            sql = "SELECT LookupValue As Val, LookupTitle as Lbl FROM dbo.Lookups WHERE ParentTable = 'Projects' AND ParentField = 'Status' ORDER By LookupTitle"
            db.FillDropDown(sql, form.FindControl("lstStatus"))
            
            sql = "SELECT LookupValue As Val, LookupTitle as Lbl FROM dbo.Lookups WHERE ParentTable = 'Projects' AND ParentField = 'Status' ORDER By LookupTitle"
            db.FillDropDown(sql, form.FindControl("lstPriorQuarter_Status"), True, False, False)

            sql = "SELECT ContactID As Val, Name as Lbl FROM Contacts WHERE ContactType='Company' AND (DistrictID = " & nDistrictID & " OR DistrictID = 0) ORDER BY NAME"
            db.FillDropDown(sql, form.FindControl("lstGC_Arch_ID"), True, True, False)

            sql = "SELECT ContactID As Val, Name as Lbl FROM Contacts WHERE ContactType='Company' AND (DistrictID = " & nDistrictID & " OR DistrictID = 0) ORDER BY NAME"
            db.FillDropDown(sql, form.FindControl("lstArchID"), True, True, False)

            sql = "SELECT ContactID As Val, Name as Lbl FROM Contacts WHERE ContactType='Company' AND (DistrictID = " & nDistrictID & " OR DistrictID = 0) ORDER BY NAME"
            db.FillDropDown(sql, form.FindControl("lstCMID"), True, True, False)

            sql = "SELECT LookupValue As Val, LookupTitle as Lbl FROM dbo.Lookups WHERE ParentTable = 'Projects' AND ParentField = 'BondSeriesNumber' "
            sql = sql & "AND DistrictID = " & nDistrictID & " ORDER By LookupTitle"
            db.FillDropDown(sql, form.FindControl("lstBondSeriesNumber"), False, False, False)


            sql = "SELECT LookupValue As Val, LookupTitle as Lbl FROM dbo.Lookups WHERE ParentTable = 'Projects' AND ParentField = 'ActivityCode' AND "
            sql = sql & "DistrictID = " & nDistrictID & " ORDER By LookupValue"
            db.FillDropDown(sql, form.FindControl("lstActivityCode"), True, False, True)

            sql = "SELECT LookupValue As Val, LookupTitle as Lbl FROM dbo.Lookups WHERE ParentTable = 'Projects' AND ParentField = 'Category' AND "
            sql = sql & "DistrictID = " & nDistrictID & " ORDER By LookupValue"
            db.FillDropDown(sql, form.FindControl("lstCategory"), True, False, False)

            sql = "SELECT LookupValue As Val, LookupTitle as Lbl FROM dbo.Lookups WHERE ParentTable = 'Projects' AND ParentField = 'Phase' AND "
            sql = sql & "DistrictID = " & nDistrictID & " ORDER By LookupValue"
            db.FillDropDown(sql, form.FindControl("lstPhase"), True, False, False)

            sql = "SELECT LookupValue As Val, LookupTitle as Lbl FROM dbo.Lookups WHERE ParentTable = 'Projects' AND ParentField = 'Phase' AND "
            sql = sql & "DistrictID = " & nDistrictID & " ORDER By LookupValue"
            db.FillDropDown(sql, form.FindControl("lstPriorQuarter_Phase"), True, False, False)
            
            sql = "Select State as Val, State as Lbl From (Select 'ok' as State Union Select 'caution' Union Select 'problem' Union Select 'N/A' Union Select '') as qry"
            db.FillDropDown(sql, form.FindControl("lstPE_Status_Cost"), False, False, False)

            sql = "Select State as Val, State as Lbl From (Select 'ok' as State Union Select 'caution' Union Select 'problem' Union Select 'N/A' Union Select '') as qry"
            db.FillDropDown(sql, form.FindControl("lstPE_Status_Schedule"), False, False, False)

            'sql = "Select State as Val, State as Lbl From (Select 'ok' as State Union Select 'caution' Union Select 'problem' Union Select 'N/A' Union Select '') as qry"
            'db.FillDropDown(sql, form.FindControl("lstCMDM_Status"), False, False, False)

            If nProjectID > 0 Then
             
                db.FillForm(form, "SELECT * FROM qry_GetPromptProject WHERE ProjectID = " & nProjectID)

            End If
            

        End Using
        
    End Sub
    
    Private Sub SetupRadWindows()
        
        With RadPopups
            .VisibleOnPageLoad = False
            .Skin = "Office2007"
            
            butFlag.Attributes("onclick") = "return ShowFlag('" & nProjectID & "');"
            butFlag.NavigateUrl = "#"
            
            Dim ww As New RadWindow
            With ww
                .ID = "ShowFlagWindow"
                .NavigateUrl = ""
                .Title = ""
                .Width = 500
                .Height = 250
                .Top = 200
                .Left = 20
                .Modal = False
                .VisibleStatusbar = True
                .ReloadOnShow = True
                .Behaviors = WindowBehaviors.Close + WindowBehaviors.Move
            End With
            .Windows.Add(ww)
            
            'set up help button
            butHelp.Attributes("onclick") = "return ShowHelp('" & Session("PageID") & "');"
            butHelp.NavigateUrl = "#"
                
            ww = New Telerik.Web.UI.RadWindow
            With ww
                .ID = "ShowHelpWindow"
                .NavigateUrl = ""
                .Title = ""
                .Width = 450
                .Height = 550
                .Top = 20
                .Left = 20
                .Modal = False
                .VisibleStatusbar = True
                .ReloadOnShow = True
                .Behaviors = WindowBehaviors.Close + WindowBehaviors.Move
            End With
            .Windows.Add(ww)

        End With
        
        
    End Sub

    Private Sub lnkAddNew_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles lnkAddNew.Click
        Dim jscript As New StringBuilder
        'Opens a new popup for adding a new value on the fly while editing a record.
        jscript.Append("<script language='javascript'>")
        jscript.Append("openPopup('company_edit.aspx?new=y&passback=y&type=contractor','ContractorEdit',700,580,'yes');")
        jscript.Append("</" & "script>")
        ClientScript.RegisterStartupScript(GetType(String), "NewGC", jscript.ToString)
    End Sub

    Private Sub lnkAddArch_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles lnkAddArch.Click
        Dim jscript As New StringBuilder
        'Opens a new popup for adding a new value on the fly while editing a record.
        jscript.Append("<script language='javascript'>")
        jscript.Append("openPopup('company_edit.aspx?new=y&passback=y&type=architect','ContractorEdit',700,580,'yes');")
        jscript.Append("</" & "script>")
        ClientScript.RegisterStartupScript(GetType(String), "NewArch", jscript.ToString)
    End Sub

    
    'Protected Sub lnkChangeBudget_Click(ByVal sender As Object, ByVal e As System.EventArgs)
    '    Dim jscript As New StringBuilder
    '    'Opens a new popup for changing the budget amount
    '    jscript.Append("<script language='javascript'>")
    '    jscript.Append("openPopup('project_budget_change_edit.aspx?BatchID=" & txtCurrentBudgetBatchID.Value & "&ProjectID=" & nProjectID & "','BudgetChange',500,500,'yes');")
    '    jscript.Append("</" & "script>")
    '    ClientScript.RegisterStartupScript(GetType(String), "BudgetChange", jscript.ToString)
    'End Sub
    
    
    Private Sub butSave_Click(ByVal sender As System.Object, ByVal e As System.Web.UI.ImageClickEventArgs) Handles butSave.Click
        
        'save the project
        nProjectID = Val(nProjectID)
        Using db As New promptProject
            db.CallingPage = Page
            db.SaveProject(nCollegeID, nProjectID)
            If nProjectID = 0 Then
                nProjectID = db.ProjectID 'this was a new record
            End If
           
        End Using
  
        Session("RtnFromEdit") = True
        Session("nodeid") = "Project" & nProjectID
        Session("RefreshNav") = True
        ProcLib.CloseAndRefreshNoPrompt(Page)
        
    End Sub

    Private Sub butDelete_Click(ByVal sender As System.Object, ByVal e As System.Web.UI.ImageClickEventArgs) Handles butDelete.Click
         
        Dim msg As String = ""
        Using db As New promptProject
            msg = db.DeleteProject(nProjectID)
        End Using
        If msg = "" Then
            Session("RtnFromEdit") = True
            Session("nodeid") = "College" & nCollegeID    'locate to parent college
            Session("RefreshNav") = True
            Session("delproject") = True
            ProcLib.CloseAndRefresh(Page)
            
        Else
            lblMessage.Text = msg
            
        End If
    End Sub
 
  
    Protected Sub lnkAddNewCM_Click(ByVal sender As Object, ByVal e As System.EventArgs)
        Dim jscript As New StringBuilder
        'Opens a new popup for adding a new value on the fly while editing a record.
        jscript.Append("<script language='javascript'>")
        jscript.Append("openPopup('company_edit.aspx?new=y&passback=y&type=CM','ContractorEdit',700,580,'yes');")
        jscript.Append("</" & "script>")
        ClientScript.RegisterStartupScript(GetType(String), "NewCM", jscript.ToString)
    End Sub
</script>

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">
<html>
<head>
    <title>Project Edit</title>
     <link href="Styles.css" type="text/css" rel="stylesheet" />
     
         <script type="text/javascript" language="javascript">

       function ShowFlag(id)     //for Flag display
             {

                 var oWnd = window.radopen("flag_edit.aspx?ParentRecID=" + id + "&ParentRecType=Project&WinType=RAD", "ShowFlagWindow");
                 return false;

             }

       function ShowHelp(pageid)     //for help display
             {

                 var oWnd = window.radopen("help_view.aspx?WinType=RAD&PageID=" + pageid, "ShowHelpWindow");
                 return false;
             } 
             
             
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
  
                <asp:HyperLink ID="butHelp" runat="server" 
         ImageUrl="images/button_help.gif" 
         Style="z-index: 102; left: 504px; position: absolute; top: 17px; height: 14px;">HyperLink</asp:HyperLink>

    
    
    
    
    <asp:CheckBox ID="chkIsPassthroughProject" Style="z-index: 100; left: 402px; position: absolute;
        top: 81px" TabIndex="55" runat="server" Text="Is Passthrough Project" 
         TextAlign="Left">
    </asp:CheckBox>
    <telerik:RadDatePicker ID="txtEstCompleteDate" Style="z-index: 101; left: 511px;
        position: absolute; top: 334px" runat="server" TabIndex="16" Width="120px">
        <DateInput runat="server" Skin="Vista" Font-Size="13px" ForeColor="Blue">
        </DateInput>
    </telerik:RadDatePicker>
    <asp:Label ID="Label17" Style="z-index: 102; left: 392px; position: absolute; top: 334px"
        runat="server" CssClass="smalltext" Height="16px">Est Complete Date:</asp:Label>
    <asp:Label ID="Label30" Style="z-index: 102; left: 429px; position: absolute; top: 270px"
        runat="server" CssClass="smalltext" Height="16px">Cost Status:</asp:Label>
    <asp:Label ID="Label31" Style="z-index: 102; left: 407px; position: absolute; top: 300px"
        runat="server" CssClass="smalltext" Height="16px">Schedule Status:</asp:Label>
    <asp:Label ID="Label7" Style="z-index: 103; left: 200px; position: absolute; top: 332px"
        runat="server" CssClass="smalltext" Height="16px">Start Date:</asp:Label>
    <asp:Label ID="Label2" Style="z-index: 104; left: 17px; position: absolute; top: 48px"
        runat="server" CssClass="smalltext" Height="16px">Project Name:</asp:Label>
    <asp:Label ID="Label1" Style="z-index: 105; left: 14px; position: absolute; top: 18px"
        runat="server" CssClass="smalltext" Height="16px">ID:</asp:Label>
    <asp:Label ID="Label3" Style="z-index: 106; left: 24px; position: absolute; top: 84px; height: 10px;"
        runat="server" CssClass="smalltext">PM:</asp:Label>
    <asp:Label ID="Label4" Style="z-index: 107; left: 23px; position: absolute; top: 115px; right: 1217px;"
        runat="server" CssClass="smalltext" Height="16px">Status:</asp:Label>
    <asp:Label ID="Label20" runat="server" CssClass="smalltext" Height="16px" Style="z-index: 108;
        left: 282px; position: absolute; top: 402px">Phase:</asp:Label>
    <asp:Label ID="Label32" Style="z-index: 109; left: 24px; position: absolute; top: 176px"
        runat="server" CssClass="smalltext" Height="16px">GC:</asp:Label>
    <asp:Label ID="Label5" Style="z-index: 109; left: 25px; position: absolute; top: 146px"
        runat="server" CssClass="smalltext" Height="16px">CM:</asp:Label>
    <asp:Label ID="Label21" runat="server" CssClass="smalltext" Height="16px" Style="z-index: 110;
        left: 25px; position: absolute; top: 236px; width: 61px;">Arch:</asp:Label>
    <asp:Label ID="Label33" runat="server" CssClass="smalltext" Height="16px" Style="z-index: 111;
        left: 24px; position: absolute; top: 208px; right: 1511px; width: 72px;">GC Proj#:</asp:Label>
    <asp:Label ID="Label6" runat="server" CssClass="smalltext" Height="16px" Style="z-index: 111;
        left: 455px; position: absolute; top: 146px; right: 1102px;">CMRef#:</asp:Label>
    <asp:Label ID="Label23" Style="z-index: 112; left: 23px; position: absolute; top: 266px"
        runat="server" CssClass="smalltext" Height="16px">Arch Proj#:</asp:Label>
    <asp:Label ID="Label9" Style="z-index: 113; left: 24px; position: absolute; top: 297px"
        runat="server" CssClass="smalltext">Project Number:</asp:Label>
    <asp:Label ID="Label10" Style="z-index: 114; left: 24px; position: absolute; top: 330px"
        runat="server" CssClass="smalltext" Height="16px">Org Code:</asp:Label>
    <asp:Label ID="Label26" runat="server" CssClass="smalltext" Height="16px" Style="z-index: 115;
        left: 241px; position: absolute; top: 298px">Sub Number:</asp:Label>
    <asp:Label ID="Label11" Style="z-index: 116; left: 24px; position: absolute; top: 361px"
        runat="server" CssClass="smalltext" Height="16px">Category:</asp:Label>
    <%--<asp:Label ID="lblcurrentbudget" Style="z-index: 117; left: 24px; position: absolute;
        top: 399px" runat="server" CssClass="smalltext" Height="16px">Current Budget:</asp:Label>--%>
  
                <asp:HyperLink ID="butFlag" runat="server" 
         ImageUrl="images/button_flag.gif" 
         Style="z-index: 102; left: 439px; position: absolute; top: 17px"></asp:HyperLink>
    &nbsp;
    <%--<asp:Label ID="lblbudgetbatch" runat="server" CssClass="smalltext" Height="16px"
        Style="z-index: 118; left: 353px; position: absolute; top: 403px">Budget Batch:</asp:Label>--%>
    <%--<telerik:RadNumericTextBox ID="txtOrigBudget" Style="z-index: 119; left: 136px; position: absolute;
        top: 400px" Width="117px" TabIndex="20" runat="server" Enabled="False" ToolTip='This is the current budget for this project. Changes to this budget must be logged through the "change..." button on the right.'
        SelectionOnFocus="SelectAll" MinValue="0" AutoPostBack="False" NumberFormat-DecimalDigits="2">
        <NumberFormat AllowRounding="True" DecimalDigits="2" PositivePattern="$ n"></NumberFormat>
    </telerik:RadNumericTextBox>--%>
 <%--   <asp:Label ID="lblBudgetChangeBatch" runat="server" CssClass="EditDataDisplay" Height="16px"
        Style="z-index: 120; left: 434px; position: absolute; top: 403px" Width="195px">March 20, 2007</asp:Label>--%>
    <asp:HiddenField ID="txtCurrentBudgetBatchID" runat="server" />
    <asp:Label ID="Label13" Style="z-index: 121; left: 461px; position: absolute; top: 401px"
        runat="server" CssClass="smalltext" Height="16px">Location:</asp:Label>
    &nbsp;
    <asp:Label ID="Label14" Style="z-index: 122; left: 27px; position: absolute; top: 437px"
        runat="server" CssClass="smalltext" Height="16px">State/Bond Split:</asp:Label>
    <asp:Label ID="Label15" Style="z-index: 123; left: 27px; position: absolute; top: 472px"
        runat="server" CssClass="smalltext" Height="16px">Bond Series:</asp:Label>
    &nbsp;
    <asp:Label ID="Label16" Style="z-index: 124; left: 27px; position: absolute; top: 511px"
        runat="server" CssClass="smalltext" Height="16px">Description:</asp:Label>
    <asp:Label ID="Label34" runat="server" CssClass="smalltext" Height="16px" Style="z-index: 125;
        left: 23px; position: absolute; top: 573px">CBOC Narrative:</asp:Label>
    <asp:Label ID="lblMessage" runat="server" CssClass="smalltext" Height="16px" Style="z-index: 125;
        left: 19px; position: absolute; top: 641px; width: 643px;" Font-Bold="True" 
         ForeColor="Red">Message</asp:Label>
    <asp:Label ID="Label18" runat="server" CssClass="smalltext" Height="16px" Style="z-index: 126;
        left: 282px; position: absolute; top: 114px">Activity Code:</asp:Label>
    <asp:TextBox ID="txtProjectName" Style="z-index: 127; left: 137px; position: absolute;
        top: 47px" runat="server" Width="376px" CssClass="EditDataDisplay"></asp:TextBox>
    <asp:TextBox ID="txtGC_Arch_ProjectNum" Style="z-index: 128; left: 136px; position: absolute;
        top: 208px" TabIndex="6" runat="server" Width="75px" 
         CssClass="EditDataDisplay"></asp:TextBox>
    <asp:TextBox ID="txtCMRefNumber" Style="z-index: 128; left: 508px; position: absolute;
        top: 145px; width: 97px;" TabIndex="6" runat="server" 
         CssClass="EditDataDisplay"></asp:TextBox>
    <asp:TextBox ID="txtArchProjectNumber" runat="server" CssClass="EditDataDisplay"
        Style="z-index: 129; left: 137px; position: absolute; top: 265px" TabIndex="8"
        Width="75px"></asp:TextBox>
    <asp:TextBox ID="txtProjectNumber" Style="z-index: 130; left: 137px; position: absolute;
        top: 295px" TabIndex="9" runat="server" Width="75px" CssClass="EditDataDisplay"></asp:TextBox>
    <asp:TextBox ID="txtProjectSubNumber" runat="server" CssClass="EditDataDisplay" Style="z-index: 131;
        left: 315px; position: absolute; top: 296px" TabIndex="10" Width="75px"></asp:TextBox>
    <asp:DropDownList ID="lstPE_Status_Cost" runat="server" CssClass="EditDataDisplay"
        Style="z-index: 131; left: 511px; position: absolute; top: 264px" TabIndex="10"
        Width="94px">
    </asp:DropDownList>
    <asp:DropDownList ID="lstPE_Status_Schedule" runat="server" CssClass="EditDataDisplay"
        Style="z-index: 131; left: 511px; position: absolute; top: 296px" TabIndex="10"
        Width="95px">
    </asp:DropDownList>
    <asp:TextBox ID="txtTaxLiabilityAccountNumber" runat="server" CssClass="EditDataDisplay"
        Style="z-index: 131; left: 518px; position: absolute; top: 435px; width: 93px;"
        TabIndex="10"></asp:TextBox>
    <asp:TextBox ID="txtDistrictRetentionVendorID" runat="server" CssClass="EditDataDisplay"
        Style="z-index: 131; left: 335px; position: absolute; top: 467px; width: 91px;"
        TabIndex="10"></asp:TextBox>
    <asp:TextBox ID="txtRetentionEscrowAcctNumber" runat="server" CssClass="EditDataDisplay"
        Style="z-index: 131; left: 518px; position: absolute; top: 465px; width: 91px;
        right: 998px;" TabIndex="10"></asp:TextBox>
    <asp:TextBox ID="txtRetentionAccountNumber" runat="server" CssClass="EditDataDisplay"
        Style="z-index: 131; left: 331px; position: absolute; top: 435px; width: 90px;
        right: 1186px;" TabIndex="10"></asp:TextBox>
    <asp:TextBox ID="txtOrgCode" Style="z-index: 132; left: 136px; position: absolute;
        top: 329px" TabIndex="14" runat="server" Width="50px" CssClass="EditDataDisplay"></asp:TextBox>
    <telerik:RadNumericTextBox ID="txtEscalation" Style="z-index: 133; left: 138px; position: absolute;
        top: 398px" TabIndex="22" runat="server" Width="91px" SelectionOnFocus="SelectAll"
        MinValue="0" AutoPostBack="False" NumberFormat-DecimalDigits="2">
        <NumberFormat AllowRounding="True" DecimalDigits="2" PositivePattern="$ n"></NumberFormat>
    </telerik:RadNumericTextBox>
    <asp:TextBox ID="txtLocation" runat="server" CssClass="EditDataDisplay" Style="z-index: 134;
        left: 514px; position: absolute; top: 398px; width: 91px;" TabIndex="32"></asp:TextBox>
    <asp:Label ID="Label22" runat="server" CssClass="smalltext" Height="16px" Style="z-index: 135;
        left: 47px; position: absolute; top: 405px">Escalation:</asp:Label>
    &nbsp;&nbsp;
    <asp:TextBox ID="txtStateBondSplit" Style="z-index: 136; left: 138px; position: absolute;
        top: 436px" TabIndex="24" runat="server" Width="50px" CssClass="EditDataDisplay"
        ToolTip="This is the state/bond split of the project."></asp:TextBox>
    <asp:TextBox ID="txtDescription" Style="z-index: 137; left: 140px; position: absolute;
        top: 505px; height: 52px;" TabIndex="40" runat="server" Width="464px" 
         CssClass="EditDataDisplay" TextMode="MultiLine"></asp:TextBox>
    <asp:TextBox ID="txtCBOCNarrative" runat="server" CssClass="EditDataDisplay" Height="67px"
        Style="z-index: 138; left: 140px; position: absolute; top: 568px" TabIndex="40"
        TextMode="MultiLine" Width="347px"></asp:TextBox>
    <asp:Label ID="lblProjectID" Style="z-index: 139; left: 42px; position: absolute;
        top: 19px" runat="server" CssClass="ViewDataDisplay" Height="16px">###</asp:Label>
    <asp:DropDownList ID="lstPM" Style="z-index: 140; left: 136px; position: absolute;
        top: 80px;  width: 212px;" TabIndex="1" runat="server" 
         CssClass="EditDataDisplay">
    </asp:DropDownList>
    <asp:DropDownList ID="lstStatus" Style="z-index: 141; left: 137px; position: absolute;
        top: 112px" TabIndex="3" runat="server" CssClass="EditDataDisplay">
    </asp:DropDownList>
    <asp:DropDownList ID="lstActivityCode" Style="z-index: 142; left: 376px; position: absolute;
        top: 108px;  width: 225px;" TabIndex="4" runat="server" 
         CssClass="EditDataDisplay">
    </asp:DropDownList>
    <asp:DropDownList ID="lstCMID" Style="z-index: 143; left: 136px; position: absolute;
        top: 142px" TabIndex="5" runat="server" Width="192px" 
         CssClass="EditDataDisplay">
    </asp:DropDownList>
    <asp:DropDownList ID="lstGC_Arch_ID" Style="z-index: 143; left: 136px; position: absolute;
        top: 176px" TabIndex="5" runat="server" Width="192px" CssClass="EditDataDisplay">
    </asp:DropDownList>
    <asp:DropDownList ID="lstArchID" Style="z-index: 144; left: 137px; position: absolute;
        top: 236px" TabIndex="7" runat="server" Width="192px" CssClass="EditDataDisplay">
    </asp:DropDownList>
    <asp:DropDownList ID="lstCategory" Style="z-index: 145; left: 136px; position: absolute;
        top: 361px" TabIndex="18" runat="server" CssClass="EditDataDisplay">
    </asp:DropDownList>
    <asp:DropDownList ID="lstPhase" Style="z-index: 146; left: 326px; position: absolute;
        top: 398px" TabIndex="23" runat="server" CssClass="EditDataDisplay">
    </asp:DropDownList>
    <asp:DropDownList ID="lstBondSeriesNumber" Style="z-index: 147; left: 139px; position: absolute;
        top: 470px; height: 20px; width: 62px;" TabIndex="30" runat="server" 
         CssClass="EditDataDisplay">
    </asp:DropDownList>
    <asp:LinkButton ID="lnkAddNewCM" Style="z-index: 148; left: 353px; position: absolute;
        top: 145px" TabIndex="99" runat="server" Width="72px" Height="16px" 
         onclick="lnkAddNewCM_Click">add new...</asp:LinkButton>
    <asp:LinkButton ID="lnkAddNew" Style="z-index: 148; left: 353px; position: absolute;
        top: 180px" TabIndex="99" runat="server" Width="72px" Height="16px">add new...</asp:LinkButton>
        
    <asp:LinkButton ID="lnkAddArch" runat="server" Height="16px" Style="z-index: 149;
        left: 351px; position: absolute; top: 242px" TabIndex="99" Width="72px">add new...</asp:LinkButton>
    <%--<asp:LinkButton ID="lnkChangeBudget" runat="server" Height="16px" Style="z-index: 150;
        left: 260px; position: absolute; top: 402px" TabIndex="5" Width="72px" OnClick="lnkChangeBudget_Click">Change...</asp:LinkButton>--%>
    <asp:CheckBox ID="chkExcludeFromReports" Style="z-index: 151; left: 184px; position: absolute;
        top: 15px; right: 1253px; width: 170px;" TabIndex="56" runat="server" TextAlign="Left"
        Text="Exclude From Reports:"></asp:CheckBox>
    <asp:CheckBox ID="chkShowNarrativeOnReports" Style="z-index: 158; left: 507px; position: absolute;
        top: 578px" TabIndex="41" runat="server" Text="Show on Reports:"></asp:CheckBox>
    <asp:ImageButton ID="butSave" Style="z-index: 153; left: 140px; position: absolute;
        top: 670px" TabIndex="45" runat="server" ImageUrl="images/button_save.gif"></asp:ImageButton>
    <asp:ImageButton ID="butDelete" Style="z-index: 154; left: 445px; position: absolute;
        top: 671px" TabIndex="50" runat="server" 
         ImageUrl="images/button_delete.gif">
    </asp:ImageButton>
    <telerik:RadDatePicker ID="txtStartDate" Style="z-index: 155; left: 261px; position: absolute;
        top: 330px" runat="server" TabIndex="12" Width="120px">
        <DateInput runat="server" Skin="Vista" Font-Size="13px" ForeColor="Blue">
        </DateInput>
    </telerik:RadDatePicker>
    <asp:Label ID="Label28" runat="server" CssClass="smalltext" Height="16px" Style="z-index: 115;
        left: 222px; position: absolute; top: 473px; right: 1272px; width: 113px;">Dist Ret VendorID:</asp:Label>
    <asp:Label ID="Label27" runat="server" CssClass="smalltext" Height="16px" Style="z-index: 115;
        left: 213px; position: absolute; top: 438px">Retention Account #:</asp:Label>
    <asp:Label ID="Label29" runat="server" CssClass="smalltext" Height="16px" Style="z-index: 115;
        left: 432px; position: absolute; top: 437px">Tax Account #:</asp:Label>
    <asp:Label ID="Label24" runat="server" CssClass="smalltext" Height="16px" Style="z-index: 115;
        left: 437px; position: absolute; top: 468px">Ret Escr Acct:</asp:Label>
       <telerik:RadWindowManager ID="RadPopups" runat="server">
    </telerik:RadWindowManager>
        
<div style="left: 411px; position: absolute; top: 181px; background-color:;width:210px; height:77px; border:1px solid #000">
Prior Quarter:
<asp:Label ID="Label333" runat="server" CssClass="smalltext" Height="16px" Style="z-index: 108;
  left: 31px; position: absolute; top: 48px">Phase:
</asp:Label>
<asp:DropDownList ID="lstPriorQuarter_Phase" Style="z-index: 146; left: 97px; position: absolute;
  top: 45px" TabIndex="23" runat="server" CssClass="EditDataDisplay">
</asp:DropDownList>

<asp:DropDownList ID="lstPriorQuarter_Status" Style="z-index: 141; left: 97px; position: absolute;
  top:20px" TabIndex="3" runat="server" CssClass="EditDataDisplay">
</asp:DropDownList>

<asp:Label ID="Label334" Style="z-index: 107; left: 30px; position: absolute; top: 24px; height: 16px;"
  runat="server" CssClass="smalltext">Status:
</asp:Label>
</div>
        
    </form>
</body>
</html>
