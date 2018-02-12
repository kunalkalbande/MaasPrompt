<%@ Page Language="vb" %>

<%@ Register Assembly="Telerik.Web.UI" Namespace="Telerik.Web.UI" TagPrefix="telerik" %>
<%@ Import Namespace="Prompt" %>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">

<script runat="server">
   
    Private nWorkflowScenerioID As Integer = 0
             
    Private Sub Page_Load(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MyBase.Load
        
        If ProcLib.CheckExpiredSessionForPopup(Page) Then    'session died so close the page - this is to prevent orphaned popups
            ProcLib.CloseOnlyRAD(Page)
        End If
        
        'set help info - note: no need for help button as one on page top will suffice here
        Session("PageID") = "WorkflowScenerioEdit"
        
        lblMessage.Text = ""

        nWorkflowScenerioID = Request.QueryString("WorkflowScenerioID")
  
        If IsPostBack Then   'only do the following on post back or pass back
            nWorkflowScenerioID = lblID.Text
        Else  'only do the following on first load
                
            Using db As New PromptDataHelper
                db.CallingPage = Page
                If nWorkflowScenerioID = 0 Then    'load new record 
                    'new record so hide delete button
                    butDelete.Visible = False
                Else
                    db.FillForm(Form, "SELECT * FROM WorkflowScenerios WHERE WorkflowScenerioID = " & nWorkflowScenerioID)
                End If

                txtScenerioName.Focus()
                lblID.Text = nWorkflowScenerioID
               
            End Using
 
        End If
    End Sub

    Private Sub butSave_Click(ByVal sender As System.Object, ByVal e As System.Web.UI.ImageClickEventArgs) Handles butSave.Click
        If trim(txtScenerioName.Text) <> "" Then
            Dim sql As String = ""
            Using db As New PromptDataHelper
                If nWorkflowScenerioID = 0 Then      'new record
                    sql = "INSERT INTO WorkflowScenerios "
                    sql &= "(DistrictID)"
                    sql &= "VALUES (" & Session("DistrictID") & ")"
                    sql &= "SELECT CAST(SCOPE_IDENTITY() AS int) AS ID"

                    nWorkflowScenerioID = db.ExecuteScalar(sql)
                End If

                'pass the form and sql to fill routine
                db.SaveForm(Form1, "SELECT * FROM WorkflowScenerios WHERE WorkflowScenerioID = " & nWorkflowScenerioID)
            End Using
        End If
        ProcLib.CloseAndRefreshRADNoPrompt(Page)
    
    End Sub

    Private Sub butDelete_Click(ByVal sender As System.Object, ByVal e As System.Web.UI.ImageClickEventArgs) Handles butDelete.Click
        Using db As New PromptDataHelper
            Dim sql As String = "DELETE FROM WorkflowScenerios WHERE WorkflowScenerioID = " & nWorkflowScenerioID
            db.ExecuteNonQuery(sql)

            sql = "DELETE FROM WorkflowScenerioOwners WHERE WorkflowScenerioID = " & nWorkflowScenerioID
            db.ExecuteNonQuery(sql)
        End Using
        ProcLib.CloseAndRefreshRADNoPrompt(Page)

    End Sub
 
      
 

  
</script>

<html>
<head>
    <title>Prompt - Edit Workflow Scenerio</title>
    <link href="Styles.css" type="text/css" rel="stylesheet" />

    <script type="text/javascript" language="javascript">
		
		function GetRadWindow()   //note: sometimes this needs to be in HEAD tag to work properly
		{
			var oWindow = null;
			if (window.radWindow) oWindow = window.radWindow; //Will work in Moz in all cases, including clasic dialog
			else if (window.frameElement.radWindow) oWindow = window.frameElement.radWindow;//IE (and Moz az well)
				
			return oWindow;
		}

    </script>

</head>
<body>
<form id="Form1" method="post" runat="server">
     <telerik:RadScriptManager ID="RadScriptManager1" runat="server" />
    <asp:Label ID="lblID" Style="z-index: 100; left: 42px; position: absolute; top: 15px"
        runat="server">999</asp:Label>
    <asp:Label ID="Label16" Style="z-index: 101; left: 10px; position: absolute; top: 14px"
        runat="server">ID:</asp:Label>
    <asp:TextBox ID="txtScenerioName" Style="z-index: 102; left: 90px; position: absolute;
        top: 37px" runat="server" CssClass="EditDataDisplay" Width="157px" MaxLength="50"></asp:TextBox>
    <asp:TextBox ID="txtDescription" Style="z-index: 103; left: 90px; position: absolute;
        top: 68px" TabIndex="5" runat="server" CssClass="EditDataDisplay" Width="304px"></asp:TextBox>
    <asp:Label ID="Label4" runat="server" Style="z-index: 104; left: 14px; position: absolute;
        top: 68px">Description:</asp:Label>
    <asp:Label ID="Label20" runat="server" Style="z-index: 105; left: 15px; position: absolute;
        top: 38px">Scenerio:</asp:Label>
    <asp:Label ID="Label1" runat="server" Style="z-index: 118; left: 14px; position: absolute;
        top: 100px">Type:</asp:Label>
    <asp:ImageButton ID="butSave" Style="z-index: 107; left: 12px; position: absolute;
        top: 161px" TabIndex="150" runat="server" ImageUrl="images/button_save.gif">
    </asp:ImageButton>
    &nbsp;
   
    <asp:ImageButton ID="butDelete" Style="z-index: 108; left: 258px; position: absolute;
        top: 161px" TabIndex="151" OnClick="butDelete_Click" OnClientClick="if(!confirm('Are you sure?')) return false;" runat="server" ImageUrl="images/button_delete.gif">
    </asp:ImageButton>
    <asp:Label ID="lblMessage" Style="z-index: 109; left: 114px; position: absolute;
        top: 15px" runat="server" Width="382px" ForeColor="Red" Height="11px" TabIndex="500">Note:</asp:Label>
    &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp;
    <telerik:radwindowmanager id="RadPopups" runat="server" style="z-index: 114; left: 20px;
        position: absolute; top: 171px">
        </telerik:radwindowmanager>
    &nbsp;&nbsp;&nbsp; &nbsp;
    <asp:DropDownList ID="lstAppliesTo" runat="server" Style="z-index: 117; left: 89px;
        position: absolute; top: 102px" CssClass="EditDataDisplay">
        <asp:ListItem>Transaction</asp:ListItem>
        <asp:ListItem>PAD</asp:ListItem>
    </asp:DropDownList>
    <asp:CheckBox ID="chkIsFFEScenario" Style="z-index: 117; left: 216px; position: absolute;
        top: 110px" runat="server" Text="FFE Scenario" />
    <asp:CheckBox ID="chkIsRetentionScenario" Style="z-index: 117; left: 216px; position: absolute;
        top: 91px" runat="server" Text="Retention Scenario" />
    <p>
        <asp:CheckBox ID="chkLimitRejectionList" Style="z-index: 117; left: 11px; position: absolute;
            top: 129px" runat="server" Text="Limit Rejection list to Approved" ToolTip="Limits rejection list to only those who have approved." />
    </p>
    </form>
</body>
</html>
