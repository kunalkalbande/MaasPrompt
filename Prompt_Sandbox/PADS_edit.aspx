<%@ Page Language="vb" %>

<%@ Import Namespace="System.IO" %>

<%@ Register Assembly="Telerik.Web.UI" Namespace="Telerik.Web.UI" TagPrefix="telerik" %>
<%@ Import Namespace="Prompt" %>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">

<script runat="server">

    Private nPADID As Integer = 0
    Private nProjectID As Integer = 0
    Private strPhysicalPath As String = ""

    Private Sub Page_Load(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MyBase.Load

        ProcLib.CheckSession(Page)
        ProcLib.LoadPopupJscript(Page)

        Session("PageID") = "PADEdit"
        
        lblMessage.Text = ""

        nPADID = Request.QueryString("PADID")
        nProjectID = Request.QueryString("ProjectID")
     
        'set up help button
        butHelp.Attributes.Add("onclick", "openPopup('help_view.aspx','pophelp',550,450,'yes');")
        butHelp.NavigateUrl = "#"
        
  
        If Not IsPostBack Then
            
           
            'get the data
            Using db As New PromptDataHelper
                
                Dim sql As String = "SELECT WorkflowScenerioID as val, Description as lbl FROM WorkflowScenerios WHERE DistrictID = " & Session("DistrictID")
                sql &= " AND AppliesTo = 'Pad' Order By ScenerioName "
                db.FillDropDown(sql, lstWorkflowScenerioID, True, True, False)
                
                If nPADID = 0 Then
                    butDelete.Visible = False
                    butAddToWorkflow.Visible = False
                Else
  
                    db.FillForm(Form1, "SELECT * FROM ProjectApprovalDocuments WHERE PADID = " & nPADID)
                End If
                
                'Check to see if the current user is the PM for the project, and if so allow to submit to workflow
                Dim nPMUserID As Integer = db.ExecuteScalar("SELECT Contacts.UserID FROM Projects INNER JOIN Contacts ON Projects.PM = Contacts.ContactID WHERE ProjectID = " & nProjectID)
                If Session("UserID") <> nPMUserID Then
                    butAddToWorkflow.Visible = False
                End If
                
                'Check to see if the PAD is already in workflow and in another user inbox and if so disable scenario list
                If Val(txtCurrentWorkflowRoleID.Value) > 0 Then
                    butAddToWorkflow.Visible = False
                    lstWorkflowScenerioID.Enabled = False
                    butDelete.Visible = False
                End If
                
                If lblStatus.Text <> "Open" Then
                    butDelete.Visible = False
                    butAddToWorkflow.Visible = False
                End If
                
                                
            End Using
        End If
        
         
        If lstWorkflowScenerioID.SelectedValue = 0 Then    'hide submit for approval
            butAddToWorkflow.Visible = False
        End If
        
        
        lblxPADID.Text = nPADID
        txtPADDate.Focus()

    End Sub
    

    Private Sub butSave_Click(ByVal sender As System.Object, ByVal e As System.Web.UI.ImageClickEventArgs) Handles butSave.Click
    
        If txtDescription.Text = "" Then
            lblMessage.Text = "Please enter a Description."
            Exit Sub
        End If
        If txtPADDate.SelectedDate Is Nothing Then
            lblMessage.Text = "Please enter a Date."
            Exit Sub
        End If
        
 
        Using db As New PromptDataHelper
            Dim sql As String = ""
            If nPADID = 0 Then   'new record
                sql = "INSERT INTO ProjectApprovalDocuments (DistrictID, ProjectID) "
                sql &= "VALUES (" & HttpContext.Current.Session("DistrictID") & "," & nProjectID & ")"
                sql &= ";SELECT NewKey = Scope_Identity()"

                nPADID = db.ExecuteScalar(sql)

            End If

            'Update record
            db.SaveForm(Form1, "SELECT * FROM ProjectApprovalDocuments WHERE PADID = " & nPADID)
            
            'Update the collegeID
            sql = "SELECT CollegeID FROM Projects WHERE ProjectID = " & nProjectID
            Dim result As Integer = db.ExecuteScalar(sql)
            sql = "UPDATE ProjectApprovalDocuments SET CollegeID = " & result & " WHERE PADID = " & nPADID
            db.ExecuteNonQuery(sql)

        End Using

        Session("RtnFromEdit") = True
        ProcLib.CloseAndRefreshRADNoPrompt(Page)
    End Sub

    Private Sub butDelete_Click(ByVal sender As System.Object, ByVal e As System.Web.UI.ImageClickEventArgs) Handles butDelete.Click
       
        Using db As New PromptDataHelper
            Dim strPhysicalPath As String = ProcLib.GetCurrentAttachmentPath() & "DistrictID_" & HttpContext.Current.Session("DistrictID")
            strPhysicalPath &= "/_apprisedocs/_PADS/PADID_" & nPADID & "/"
            Dim folder As New DirectoryInfo(strPhysicalPath)
            If folder.Exists Then  'there could be files so get all and list
 
                For Each fi As FileInfo In folder.GetFiles()
                    fi.Delete()
                Next
                
                folder.Delete()

            End If
            
  
            db.ExecuteNonQuery("DELETE FROM ProjectApprovalDocuments WHERE PADID = " & nPADID)
        End Using

        Session("RtnFromEdit") = True
        ProcLib.CloseAndRefreshRADNoPrompt(Page)
    End Sub


    Protected Sub butAddToWorkflow_Click(ByVal sender As Object, ByVal e As System.EventArgs)
                
        If lstWorkflowScenerioID.SelectedValue = 0 Then
            lblMessage.Text = "Please select a Workflow Scenario to submit this PAD for approval."
            Exit Sub
        End If
        
        'Now look for attachments 
        Dim strPhysicalPath As String = ProcLib.GetCurrentAttachmentPath() & "DistrictID_" & HttpContext.Current.Session("DistrictID")
        strPhysicalPath &= "/_apprisedocs/_PADS/"
        Dim nCount As Integer = 0
        Dim sPath As String = strPhysicalPath & "PADID_" & nPADID & "/"
        Dim folder As New DirectoryInfo(sPath)
        If folder.Exists Then  'there could be files so get all and list
            For Each fi As FileInfo In folder.GetFiles()
                nCount += 1
                Exit For
            Next

        End If
        If nCount = 0 Then
            lblMessage.Text = "Please save the PAD, and then attach documents before attempting to submit for approval."
            Exit Sub
        End If
        
        'Put into Workflow by adding to current users Inbox
        Using db As New PromptDataHelper
            Dim sql As String = "UPDATE ProjectApprovalDocuments SET "
            sql &= "Status = 'Pending Approval',"
            sql &= "CurrentWorkflowRoleID = " & Session("WorkflowRoleID") & ", "
            sql &= "CurrentWorkflowOwner = '" & Session("WorkflowRole") & "' "
            sql &= "WHERE PADID = " & nPADID
            db.ExecuteNonQuery(sql)
            
        End Using
        
        lblStatus.Text = "Pending Approval"
        
        
        lblMessage.Text = "PAD has been placed in your PROMPT Inbox for you to route for approval."
        butAddToWorkflow.Visible = False
            
        'Session("RtnFromEdit") = True
        'ProcLib.CloseAndRefreshRADNoPrompt(Page)
        
        
    End Sub
</script>

<html>
<head>
    <title>PAD Edit</title>
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
    <asp:HyperLink ID="butHelp" Style="z-index: 112; left: 489px; position: absolute;
        top: 14px; height: 20px;" runat="server" ImageUrl="images/button_help.gif">HyperLink</asp:HyperLink>
    <asp:ImageButton ID="butSave" Style="z-index: 113; left: 16px; position: absolute;
        top: 253px" TabIndex="100" runat="server" 
        ImageUrl="images/button_save.gif">
    </asp:ImageButton>
    <asp:ImageButton ID="butDelete" Style="z-index: 107; left: 286px; position: absolute;
        top: 254px" TabIndex="400" runat="server" 
        ImageUrl="images/button_delete.gif">
    </asp:ImageButton>
    <asp:Label ID="lblMessage" Style="z-index: 105; left: 8px; position: absolute; top: 224px"
        runat="server" Height="24px" Font-Bold="True" ForeColor="Red">Error Message</asp:Label>
    <asp:Label ID="Label7" Style="z-index: 105; left: 12px; position: absolute; top: 38px"
        runat="server" Height="24px">Date:</asp:Label>
    <asp:Label ID="Label16" Style="z-index: 105; left: 13px; position: absolute; top: 65px;"
        runat="server" Height="24px">Description:</asp:Label>
    <asp:Label ID="lblxPADID" Style="z-index: 105; left: 45px; position: absolute;
        top: 7px" runat="server" Class="ViewDataDisplay" Height="24px"></asp:Label>
    <asp:Label ID="Label12" Style="z-index: 105; left: 12px; position: absolute; top: 7px"
        runat="server" Height="24px">ID:</asp:Label>
    <telerik:RadDatePicker ID="txtPADDate" Style="z-index: 6103; left: 98px; position: absolute;
        top: 34px" runat="server" Width="120px" Skin="Web20" TabIndex="1">
        <DateInput runat="server" Skin="WebBlue" Font-Size="13px" ForeColor="Blue" TabIndex="1">
        </DateInput>
        <Calendar runat="server" UseRowHeadersAsSelectors="False" UseColumnHeadersAsSelectors="False"
            ViewSelectorText="x" Skin="Web20">
             <SpecialDays> 
            <telerik:RadCalendarDay Repeatable="Today"> 
                <ItemStyle BackColor="LightBlue" /> 
            </telerik:RadCalendarDay> 
        </SpecialDays> 
        </Calendar>
        <DatePopupButton ImageUrl="" HoverImageUrl="" TabIndex="1"></DatePopupButton>
    </telerik:RadDatePicker>
    <asp:Label ID="Label19" Style="z-index: 105; left: 11px; position: absolute; top: 144px; right: 1529px; width: 90px;"
        runat="server" Height="24px">Current Phase:</asp:Label>
    <asp:TextBox ID="txtCurrentPhase" Style="z-index: 103; left: 96px; position: absolute;
        top: 142px; width: 142px;" runat="server" Height="24px" TabIndex="7" 
        CssClass="EditDataDisplay"></asp:TextBox>
        
           <asp:DropDownList ID="lstWorkflowScenerioID" Style="z-index: 138; left: 122px; position: absolute;
        top: 187px;" TabIndex="2" runat="server" CssClass="EditDataDisplay">
    </asp:DropDownList>
        
    <asp:Label ID="Label18" Style="z-index: 105; left: 9px; position: absolute; top: 187px; right: 1477px; width: 121px;"
        runat="server" Height="24px">Workflow Scenario:</asp:Label>
        
    
        <asp:Button ID="butAddToWorkflow" runat="server" Text="Add to Workflow Approval" 
        
        Style="z-index: 105; left: 342px; position: absolute; top: 183px; right: 1090px; width: 175px;" 
        onclick="butAddToWorkflow_Click" />
        
       <asp:HiddenField runat=server ID="txtCurrentWorkflowRoleID" /> 
    
        
    <asp:Label ID="lblStatus" Style="z-index: 105; left: 328px; position: absolute; top: 141px; right: 1161px; width: 118px;"
        runat="server" Height="24px" Font-Bold="True" ForeColor="Blue">Open</asp:Label>
        
    
    <asp:Label ID="Label20" Style="z-index: 105; left: 281px; position: absolute; top: 141px; right: 1277px; width: 49px;"
        runat="server" Height="24px">Status:</asp:Label>
        
    
    <asp:TextBox ID="txtDescription" Style="z-index: 103; left: 97px; position: absolute;
        top: 73px; width: 430px; bottom: 751px; right: 1080px; height: 57px;" runat="server"
        TabIndex="80" CssClass="EditDataDisplay" TextMode="MultiLine"></asp:TextBox>
        
    
    </form>
</body>
</html>
