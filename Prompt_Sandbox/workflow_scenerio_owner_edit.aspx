<%@ Page Language="vb" %>

<%@ Register Assembly="Telerik.Web.UI" Namespace="Telerik.Web.UI" TagPrefix="telerik" %>
<%@ Import Namespace="Prompt" %>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">

<script runat="server">
   
    Private nKey As Integer = 0
    Private nWorkflowScenerioID As Integer = 0
         
    Private Sub Page_Load(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MyBase.Load
        
        If Proclib.CheckExpiredSessionForPopup(Page) Then    'session died so close the page - this is to prevent orphaned popups
            ProcLib.CloseOnlyRAD(Page)
        End If
        
        'set help info - note: no need for help button as one on page top will suffice here
        Session("PageID") = "WorkflowScenerioOwnerEdit"
        
        lblMessage.Text = ""

        nKey = Request.QueryString("WorkflowScenerioOwnerID")
        nWorkflowScenerioID = Request.QueryString("WorkflowScenerioID")
  
        If IsPostBack Then   'only do the following on post back or pass back
            nKey = lblID.Text
        Else  'only do the following on first load
                
            Using db As New promptWorkflowScenerio
                db.CallingPage = Page
                If nKey = 0 Then    'load new record 
                    'new record so hide delete button
                    butDelete.Visible = False
                End If
                db.GetWorkflowOwnerForEdit(nKey)   'loads existing record
                lstWorkflowRoleID.Focus()
                lblID.Text = nKey
                'If this parent scenrio limits rejection list, then hide list
                If db.LimitRejectionListToApproved(nWorkflowScenerioID) Then
                    lstRejectTargetList.Visible = False
                    lblRejectTargetListLabel.Text = "(Reject list limited to Approved)"
                End If
            End Using
        End If
        
        'Clear out any items in the Default approval box that are not selected or selected in the Approval Target listbox
        'Note: This combo box is rebuilt here (after initally bulding in the workflowscenerio class to allow any selected default to be appropriately added.
        
        RebuildApprovalDefaultList()
            
           
    End Sub
    
    Private Sub RebuildApprovalDefaultList()
        'Get the currently selected item
        Dim itemSelected As New ListItem
        itemSelected.Value = lstApprovalDefault.SelectedValue
        itemSelected.Text = lstApprovalDefault.SelectedItem.Text
        itemSelected.Selected = True
            
        lstApprovalDefault.Items.Clear()   'clear out the list
        Dim noneitem As New ListItem
        noneitem.Text = "-- none --"
        noneitem.Value = 0
        lstApprovalDefault.Items.Add(noneitem)
            
        'add the selected item back in
        lstApprovalDefault.Items.Add(itemSelected)
                         
        'now add any other selected items from the approval list            
        For Each item As ListItem In lstApproveTargetList.Items
            If item.Selected And item.Value <> itemSelected.Value Then    'already added 
                Dim newitem As New ListItem
                newitem.Value = item.Value
                newitem.Text = item.Text
                lstApprovalDefault.Items.Add(newitem)
            End If
        Next
    End Sub

    Private Sub butSave_Click(ByVal sender As System.Object, ByVal e As System.Web.UI.ImageClickEventArgs) Handles butSave.Click
        Using db As New promptWorkflowScenerio
            db.CallingPage = Page
            db.SaveWorkflowScenerioOwner(nWorkflowScenerioID, nKey)
        End Using
 
        ProcLib.CloseAndRefreshRADNoPrompt(Page)
    
    End Sub

    Private Sub butDelete_Click(ByVal sender As System.Object, ByVal e As System.Web.UI.ImageClickEventArgs) Handles butDelete.Click
        Using db As New promptWorkflowScenerio
            db.CallingPage = Page
            db.DeleteWorkflowScenerioOwner(nKey)  'need to pass the code and ID to take care of JCAF assignments table entries
        End Using
        ProcLib.CloseAndRefreshRADNoPrompt(Page)

    End Sub
 
 

    Protected Sub lstApproveTargetList_SelectedIndexChanged(ByVal sender As Object, ByVal e As System.EventArgs)
        RebuildApprovalDefaultList
    End Sub
</script>

<html>
<head>
    <title>Prompt - Edit Workflow Scenerio Owner</title>
     <link href="Styles.css" type="text/css" rel="stylesheet"/>

 
        <script type="text/javascript" language="javascript">

        function GetRadWindow()   //note: sometimes this needs to be in HEAD tag to work properly
        {
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
    <asp:Label ID="lblID" Style="z-index: 100; left: 42px; position: absolute; top: 15px"
        runat="server">999</asp:Label>
    <asp:Label ID="Label16" Style="z-index: 101; left: 10px; position: absolute; top: 14px"
        runat="server">ID:</asp:Label>
    &nbsp; &nbsp;
    <asp:Label ID="Label21" runat="server" Style="z-index: 102; left: 19px; position: absolute;
        top: 322px">Default target for Mulit-Approval:</asp:Label>
    <asp:Label ID="Label20" runat="server" Style="z-index: 102; left: 15px; position: absolute;
        top: 38px">Owner:</asp:Label>
    <asp:ImageButton ID="butSave" Style="z-index: 103; left: 22px; position: absolute;
        top: 408px" TabIndex="150" runat="server" ImageUrl="images/button_save.gif">
    </asp:ImageButton>
    <asp:ImageButton ID="butDelete" Style="z-index: 104; left: 237px; position: absolute;
        top: 408px" TabIndex="151" runat="server" ImageUrl="images/button_delete.gif">
    </asp:ImageButton>
    <asp:Label ID="lblMessage" Style="z-index: 105; left: 78px; position: absolute; top: 15px"
        runat="server" Width="382px" ForeColor="Red" Height="11px" TabIndex="500">Note:</asp:Label>
    &nbsp;
    <asp:ListBox ID="lstApproveTargetList" runat="server" SelectionMode="Multiple" Style="z-index: 110;
        left: 13px; position: absolute; top: 150px; height: 162px; width: 266px;" TabIndex="15"
        
        ToolTip="Determins Which Target Role this Role can forward Rejected Workflow Items to - CTRL + Click to multi select." 
        onselectedindexchanged="lstApproveTargetList_SelectedIndexChanged" 
        AutoPostBack="True">
    </asp:ListBox>
    <asp:Label ID="Label3" runat="server" Style="z-index: 106; left: 14px; position: absolute;
        top: 130px; height: 16px;">Approve Target List:</asp:Label>
    <asp:ListBox ID="lstRejectTargetList" runat="server" SelectionMode="Multiple" Style="z-index: 110;
        left: 295px; position: absolute; top: 90px; height: 279px; width: 299px;" TabIndex="15"
        ToolTip="Determins Which Target Role this Role can forward Rejected Workflow Items to - CTRL + Click to multi select.">
    </asp:ListBox>
    <telerik:RadWindowManager ID="RadPopups" runat="server" Style="z-index: 112; left: 13px;
        position: absolute; top: 527px">
    </telerik:RadWindowManager>
    <asp:DropDownList ID="lstApprovalDefault" runat="server" CssClass="EditDataDisplay"
        
        Style="z-index: 113; left: 18px; position: absolute; top: 344px; width: 233px;">
    </asp:DropDownList>
    <asp:DropDownList ID="lstWorkflowRoleID" runat="server" CssClass="EditDataDisplay"
        Style="z-index: 113; left: 65px; position: absolute; top: 40px">
    </asp:DropDownList>
    <asp:CheckBox ID="chkIsFinalApprover" runat="server" Style="z-index: 116; left: 12px;
        position: absolute; top: 103px" Text="Is Final Approver" 
        
         ToolTip="This role is the final approver in the chain -- for PADS it will cause status to change and is last step in workflow" />
    <asp:CheckBox ID="chkIsOriginator" runat="server" Style="z-index: 116; left: 128px;
        position: absolute; top: 71px" Text="Is Originator" 
        ToolTip="This role is the first owner in this Scenerio" />
    <asp:CheckBox ID="chkIsSignator" runat="server" Style="z-index: 116; left: 14px;
        position: absolute; top: 71px" Text="Is Signator" 
        ToolTip="This role is a signator for this Scenerio" />
    <asp:Label ID="lblRejectTargetListLabel" runat="server" Style="z-index: 107; left: 296px; position: absolute;
        top: 72px">Reject Target List:</asp:Label>
    <telerik:RadAjaxManager ID="RadAjaxManager1" runat="server">
        <AjaxSettings>
            <telerik:AjaxSetting AjaxControlID="lstApproveTargetList">
                <UpdatedControls>
                    <telerik:AjaxUpdatedControl ControlID="lstApprovalDefault" />
                </UpdatedControls>
            </telerik:AjaxSetting>
           
        </AjaxSettings>
    </telerik:RadAjaxManager>
    </form>
</body>
</html>
