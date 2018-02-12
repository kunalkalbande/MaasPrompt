<%@ Page Language="vb" %>

<%@ Register Assembly="Telerik.Web.UI" Namespace="Telerik.Web.UI" TagPrefix="telerik" %>
<%@ Import Namespace="Prompt" %>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" lang="en" xml:lang="en">

<script runat="server">
    
  
    Public nContractID As Integer = 0
    Public nProjectID As Integer = 0
    
    Private bReadOnly As Boolean = True
    Private nPendingCoAmount As Double = 0
    'Private nTotalContractAmount As Double = 0
    'Private nTotalReimbAmount As Double = 0
    
    Private Sub Page_Load(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MyBase.Load

        
        If ProcLib.CheckExpiredSessionForPopup(Page) Then    'session died so close the page - this is to prevent orphaned popups
            ProcLib.CloseAndRefresh(Page)
        End If
        
        lblMsg.Text = ""
        
        nContractID = Request.QueryString("ContractID")
        nProjectID = Request.QueryString("ProjectID")
        
        ProcLib.LoadPopupJscript(Page)
        
        'set up help button
        Session("PageID") = "ContractEdit"
        butHelp.Attributes("onclick") = "return ShowHelp();"
        butHelp.NavigateUrl = "#"
          
            
        'set up add new contractor link
        lnkAddNew.Attributes("onclick") = "return AddContractor();"
        
 
        butFlag.Attributes.Add("onclick", "openPopup('flag_edit.aspx?ParentRecID=" & nContractID & "&ParentRecType=Contract','pophelp',500,250,'yes');")
        butFlag.NavigateUrl = "#"
        
         
        If IsPostBack Then   'only do the following post back
            nContractID = lblContractID.Text
        Else  'only do the following on first load
            
            Using db As New promptContract
                db.CallingPage = Page
                If nContractID = 0 Then    'get blank contract record
                    db.GetNewContract(nProjectID)   'loads default values to record from parent project
                    butDelete.Visible = False
                    lnkManageAttachments.Visible = False
                Else
                    db.GetExistingContract(nContractID)   'loads default values to record from parent project
                                                         
                    LoadLinkedAttachments()
 
                    'set up attachments button
                    lnkManageAttachments.Attributes("onclick") = "return ManageAttachments('" & nContractID & "','Contract');"
                    lnkManageAttachments.NavigateUrl = "#"
                    
                End If
                 
                If db.TransTotal > 0 Or db.AmendTotal > 0 Then
                    txtxHasDependants.Value = "yes"
                Else
                    txtxHasDependants.Value = "no"
                End If
               
                If HttpContext.Current.Session("EnableWorkflow") <> "1" Then
                    RadTabStrip1.FindTabByText("Workflow").Visible = False
                    'lblAssignedWorkflowScenerios.Visible = False 'turn off workflow info
                    'lstWorkflowScenerios.Visible = False
            
                Else   'Load up workflow scenerio info
                    db.GetAssignedWorkflowScenerios(lstWorkflowScenerios)
            
                End If
                
            End Using

            lblContractID.Text = nContractID
            RadTabStrip1.SelectedIndex = 0   'default to general
        End If
        
        
        With RadPopups
            .Skin = "Windows7"
            .VisibleOnPageLoad = False
            Dim ww As New Telerik.Web.UI.RadWindow
            With ww
                .ID = "ShowHelpWindow"
                '.NavigateUrl = ""
                .Title = ""
                .Width = 450
                .Height = 450
                .Top = 100
                .Left = 20
                .Modal = False
                .VisibleStatusbar = False
                .ReloadOnShow = True
                .Behaviors = WindowBehaviors.Close + WindowBehaviors.Resize
            End With
            .Windows.Add(ww)
            
            
                                  
            ww = New Telerik.Web.UI.RadWindow
            With ww
                .ID = "OpenAttachmentWindow"
                '.NavigateUrl = ""
                .Title = "Open Attachment"
                .Width = 500
                .Height = 300
                .Top = 100
                .Left = 20
                .Modal = False
                .VisibleStatusbar = False
                .ReloadOnShow = True
                .Behaviors = WindowBehaviors.Close + WindowBehaviors.Resize
            End With
            .Windows.Add(ww)
            
            
            ww = New Telerik.Web.UI.RadWindow
            With ww
                .ID = "ManageAttachmentsWindow"
                '.NavigateUrl = ""
                .Title = "Manage Attachments"
                .Width = 500
                .Height = 450
                .Top = 100
                .Left = 20
                .Modal = False
                .VisibleStatusbar = False
                .ReloadOnShow = True
                .Behaviors = WindowBehaviors.Close + WindowBehaviors.Resize
            End With
            .Windows.Add(ww)
           
           
            ww = New Telerik.Web.UI.RadWindow
            With ww
                .ID = "AddContractorWindow"
                '.NavigateUrl = ""
                .Title = "Add Contractor"
                .Width = 455
                .Height = 440
                .Top = 100
                .Left = 20
                .Modal = False
                .VisibleStatusbar = False
                .ReloadOnShow = True
                .Behaviors = WindowBehaviors.Close + WindowBehaviors.Resize
            End With
            .Windows.Add(ww)
            
           
            
        End With
        
        Using db As New EISSecurity
            db.ProjectID = nProjectID
            If db.FindUserPermission("ContractOverview", "Write") Then
                bReadOnly = False
            End If
        End Using
        
        'check for passback value and if there, add entry to dropdown and select
        If Session("passback") <> "" Then
            Dim i As New ListItem
            i.Text = Session("passback")
            i.Value = Session("passbackID")
            'lstContractorID.Items.Add(i)
            lstContractorID.SelectedValue = i.Value
            lstContractorID.Text = i.Text.ToString
            Session("passback") = ""
            Session("passbackID") = ""
                       
        End If
                   
        ''Save old object code value for validation
        'ViewState.Add("OldObjectCode", lstObjectCode.SelectedValue)
        
        If Session("DistrictID") <> 55 Then
            cboBlanketPONumber.Height = Unit.Pixel(0)      'HACK: only show for FHDA now
        End If
  

    End Sub

    Private Sub LoadLinkedAttachments()
               
        'get the linked attachements
        lstAttachments.Items.Clear()
        Using db1 As New promptAttachment
            Dim rs As DataTable = db1.GetLinkedAttachments(nContractID, "Contract")
            If rs.Rows.Count > 0 Then
                For Each Row As DataRow In rs.Rows
                    Dim li As New ListItem
                    li.Text = Row("FileName")
                    li.Value = Row("AttachmentID")
                    li.Attributes("ondblclick") = "return OpenAttachment('" & li.Value & "');"
                    lstAttachments.Items.Add(li)
                Next
            Else '
                lstAttachments.Items.Add("No Attachments Found")
            End If
        End Using
       
    End Sub
    
    Private Sub lnkAddNew_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles lnkAddNew.Click
        Dim jscript As New StringBuilder
        'Opens a new popup for adding a new value on the fly while editing a record.
        jscript.Append("<script language='javascript'>")
        jscript.Append("openPopup('contractor_edit.aspx?new=y&passback=y','ContractorEdit',700,700,'yes');")
        jscript.Append("</" & "script" & ">")
        ClientScript.RegisterStartupScript(GetType(String), "NewContractor", jscript.ToString)
    End Sub


    Private Sub butSave_Click(ByVal sender As System.Object, ByVal e As System.Web.UI.ImageClickEventArgs) Handles butSave.Click
 
        If lstContractorID.SelectedValue = "none" Then 
            lblMsg.Text = "You must select a contractor (Company) to save the contract."
            Exit Sub
        End if
        If Not bReadOnly Then  'save contract
            Using db As New promptContract
                db.CallingPage = Page
                db.SaveContract(nContractID, nProjectID)
                If nContractID = 0 Then  'new so get new id
                    nContractID = db.ContractID
                End If
            End Using
        End If

        Session("nodeid") = "Contract" & nContractID
        Session("RefreshNav") = True
        ProcLib.CloseAndRefreshNoPrompt(Page)

    End Sub

    Private Sub butDelete_Click(ByVal sender As System.Object, ByVal e As System.Web.UI.ImageClickEventArgs) Handles butDelete.Click
 
        
        Dim msg As String = ""
        Using db As New promptContract
            msg = db.DeleteContract(nContractID)
        End Using
 
        Session("RtnFromEdit") = True
        Session("nodeid") = "Project" & nProjectID    'locate to parent Project
        Session("RefreshNav") = True
        Session("delcontract") = True
        ProcLib.CloseAndRefresh(Page)
     
        
    End Sub
    
      
    'Protected Sub lstObjectCode_SelectedIndexChanged(ByVal sender As Object, ByVal e As System.EventArgs)
    '    'Get current max contract amount for this contract object code
    '    Using db As New promptContract
    '        db.GetCurrentObjectCodeMaximumAmount(sender.SelectedValue, nProjectID, nContractID)
    '        lblMaxAmount.Value = FormatCurrency(db.ContractMaximumAmount)
    '    End Using

    'End Sub
    

    
    Protected Sub AttachmentsPopup_AjaxHiddenButton_Click(ByVal sender As Object, ByVal e As System.EventArgs) Handles AttachmentsPopup_AjaxHiddenButton.Click
        'This is method used to handle the workflow popup close to update the linked attachments list 
        LoadLinkedAttachments()
    End Sub
    
    Protected Sub lstStatus_SelectedIndexChanged(ByVal sender As Object, ByVal e As System.EventArgs)
        Dim msg As String = ""
        If lstStatus.SelectedValue = "2-Closed" Then
            Using db As New promptContract
                If db.HasPendingChangeOrders(nContractID) Then
                    msg = "Sorry, you cannot close this contract as there are Pending Change Orders."
                End If
            End Using
        End If
        
        
        If msg <> "" Then    'error so return to old value and set focus and warn
            lblMsg.Text = msg
            lstStatus.SelectedValue = "1-Open"
            lstStatus.Focus()
        End If

        

    End Sub

</script>

<head>
    <title>Prompt Edit Contract</title>
    <link href="Styles.css" type="text/css" rel="stylesheet" />
    <link href="skins/Prompt/TabStrip.Prompt.css" rel="stylesheet" type="text/css" />
    <link href="skins/Prompt/Grid.Prompt.css" rel="stylesheet" type="text/css" />
    <telerik:RadCodeBlock ID="RadCodeBlock1" runat="server">

        <script type="text/javascript" language="javascript">

            function confirmDelete() {

                var objHasDependants = document.getElementById("txtxHasDependants");
                var sHasDependants = objHasDependants.value;
                if (sHasDependants == 'yes') {
                    alert('This Contract has Transactions or Change Orders Associated with it. Please delete these before deleting the Contract.');
                    return false;
                }

                var agree = confirm("Are you sure you wish to Delete the Contract?");
                if (agree) {
                    return true;
                }

                return false;
            }


            function ShowHelp()     //for help display
            {

                var oWnd = window.radopen("help_view.aspx?WinType=RAD", "ShowHelpWindow");
                return false;
            }



            function AddContractor()     //for adding contractor on the fly
            {

                var oWnd = window.radopen("company_edit.aspx?new=y&passback=y&WinType=RAD", "AddContractorWindow");
                return false;
            }

            function GetRadWindow() {
                var oWindow = null;
                if (window.RadWindow) oWindow = window.RadWindow;
                else if (window.frameElement.radWindow) oWindow = window.frameElement.radWindow;
                return oWindow;
            }

            function ManageAttachments(id, rectype)     //for managing attachments 
            {

                var oWnd = window.radopen("attachments_manage_linked.aspx?ParentRecID=" + id + "&ParentType=" + rectype, "ManageAttachmentsWindow");
                return false;
            }


            function OpenAttachment(id)     //for opening attachments 
            {

                var oWnd = window.radopen("attachment_get_linked.aspx?ID=" + id, "OpenAttachmentWindow");
                return false;
            }


            //For handling ajax post back from Attachment Manage RAD Popup
            function HandleAjaxPostbackFromAttachmentsPopup() {
                var oButton = document.getElementById("<%=AttachmentsPopup_AjaxHiddenButton.ClientID%>");
                oButton.click();
            }

    
        </script>

    </telerik:RadCodeBlock>
</head>
<body>
    <form id="Form1" method="post" runat="server">
    <telerik:RadScriptManager ID="RadScriptManager1" runat="server" />
    <telerik:RadTabStrip ID="RadTabStrip1" runat="server" Width="100%" Skin="Vista" MultiPageID="RadMultiPage1">
        <Tabs>
            <telerik:RadTab runat="server" Text="General" PerTabScrolling="True" PageViewID="pvGeneral" />
            <telerik:RadTab runat="server" Text="Workflow" PageViewID="pvWorkflow" />
        </Tabs>
    </telerik:RadTabStrip>
    <telerik:RadMultiPage ID="RadMultiPage1" runat="server" SelectedIndex="0" Width="99%"
        Height="85%">
        <telerik:RadPageView ID="pvGeneral" runat="server">
            <table width="100%" cellpadding="3px">
                <tr>
                    <td>
                        <asp:Label ID="Label3" runat="server" CssClass="smalltext" Text="Company:" />
                    </td>
                    <td colspan="2">
                        <asp:DropDownList ID="lstContractorID" runat="server" Width="250px" CssClass="EditDataDisplay">
                        </asp:DropDownList>
                        &nbsp; &nbsp; &nbsp;
                        <asp:LinkButton ID="lnkAddNew" runat="server" TabIndex="300">add new...</asp:LinkButton>
                    </td>
                    <td align="right">
                        <asp:HyperLink ID="butFlag" runat="server" TabIndex="400" ImageUrl="images/flag.gif">Flag</asp:HyperLink>
                        &nbsp;&nbsp;&nbsp;
                        <asp:HyperLink ID="butHelp" runat="server" ImageUrl="images/help.png" TabIndex="400">Help</asp:HyperLink>
                    </td>
                </tr>
                <tr>
                    <td nowrap="nowrap">
                        <asp:Label ID="Label4" runat="server" CssClass="smalltext" Text="Contract Date:" />
                    </td>
                    <td>
                        <telerik:RadDatePicker ID="txtContractDate" TabIndex="5" runat="server" Width="120px"
                            SharedCalendarID="sharedCalendar">
                            <DateInput Font-Size="13px" ForeColor="Blue">
                            </DateInput>
                        </telerik:RadDatePicker>
                    </td>
                    <td nowrap="nowrap">
                        <asp:Label ID="Label8" runat="server" CssClass="smalltext" Text="Expire Date:" />
                    </td>
                    <td>
                        <telerik:RadDatePicker ID="txtExpireDate" runat="server" TabIndex="10" Width="120px"
                            SharedCalendarID="sharedCalendar">
                            <DateInput Skin="WebBlue" Font-Size="13px" ForeColor="Blue">
                            </DateInput>
                        </telerik:RadDatePicker>
                    </td>
                </tr>
                
                <tr>
                    <td width="150px">
                        <asp:Label ID="Label26" runat="server" CssClass="smalltext" Text="Contract Type:" />
                    </td>
                    <td>
                        <asp:DropDownList ID="lstContractType" runat="server" TabIndex="11" CssClass="EditDataDisplay"
                            AutoPostBack="False">
                            <asp:ListItem>Contract</asp:ListItem>
                        </asp:DropDownList>
                    </td>
                    <td align="right" width="150px">
                        <asp:Label ID="Label28" runat="server" CssClass="smalltext" Text="Status:" />
                    </td>
                    <td align="left">
                        <asp:DropDownList ID="lstStatus" runat="server" TabIndex="40" CssClass="EditDataDisplay"
                            OnSelectedIndexChanged="lstStatus_SelectedIndexChanged" AutoPostBack="True">
                        </asp:DropDownList>
                    </td>
                </tr>
                <tr>
                    <td width="150px">
                        <asp:Label ID="Label27" runat="server" CssClass="smalltext" Text="Description:" />
                    </td>
                    <td colspan="3">
                        <asp:TextBox ID="txtDescription" runat="server" Width="75%" TabIndex="30" CssClass="EditDataDisplay"></asp:TextBox>
                    </td>
                </tr>
                <tr>
                    <td valign="top" width="150px">
                        <asp:Label ID="Label29" runat="server" CssClass="smalltext" Text="Attachments:" />
                    </td>
                    <td >
                        <asp:ListBox ID="lstAttachments" runat="server" CssClass="smalltext" Height="49px"
                            TabIndex="71" Width="250px" />
                        
                    </td>
                <td colspan="2" align="left" valign="top">
                       &nbsp;
                        <asp:HyperLink ID="lnkManageAttachments" runat="server" ImageUrl="images/button_folder_view.gif"
                            TabIndex="71" ToolTip="Manage Attachments" />
                    </td>
                
                </tr>
                <tr>
                    <td width="150px">
                        <asp:Label ID="Label30" runat="server" CssClass="smalltext" Text="Retention%:" />
                    </td>
                    <td>
                        <asp:DropDownList ID="lstRetentionPercent" runat="server" TabIndex="50" CssClass="EditDataDisplay">
                        </asp:DropDownList>
                    </td>
                    <td width="150px">
                        <asp:Label ID="Label31" runat="server" CssClass="smalltext" Text="BidPak#:" />
                    </td>
                    <td align="left">
                        <asp:TextBox ID="txtBidPackNumber" runat="server" Width="125px" TabIndex="60" CssClass="EditDataDisplay"></asp:TextBox>
                    </td>
                </tr>
                <tr>
                    <td>
                        <asp:Label ID="Label36" runat="server" CssClass="smalltext" Text="Signed Copy Rec'd:" />
                    </td>
                    <td>
                        <telerik:RadDatePicker ID="txtSignedCopyReceived" TabIndex="70" runat="server" SharedCalendarID="sharedCalendar"
                            Width="120px">
                            <DateInput ID="DateInput1" runat="server" Skin="WebBlue" Font-Size="13px" ForeColor="Blue">
                            </DateInput>
                        </telerik:RadDatePicker>
                    </td>
                    <td nowrap="nowrap">
                        <asp:Label ID="Label37" runat="server" CssClass="smalltext" Text="Purch. Req#:" />
                    </td>
                    <td align="left">
                        <asp:TextBox ID="txtPRNumber" runat="server" Width="125px" TabIndex="60" CssClass="EditDataDisplay"></asp:TextBox>
                    </td>
                </tr>
                <tr>
                    <td>
                        <asp:Label ID="Label38" runat="server" CssClass="smalltext" Text="Default Account#:" />
                    </td>
                    <td>
                        <asp:TextBox ID="txtAccountNumber" runat="server" CssClass="EditDataDisplay" TabIndex="90"
                            Width="210px" ToolTip="This Account Number will be used as default for Contract Line Items and Change Orders when specifc Account Numbers are not assigned to those items."></asp:TextBox>
                    </td>
                    <td nowrap="nowrap">
                        <asp:Label ID="Label39" runat="server" CssClass="smalltext" Text="Blanket P.O.#:" />
                    </td>
                    <td>
                        <telerik:RadComboBox ID="cboBlanketPONumber" TabIndex="71" runat="server" AllowCustomText="True"
                            Height="100px" Width="95px">
                        </telerik:RadComboBox>
                    </td>
                </tr>
                <tr>
                    <td>
                        <asp:Label ID="Label40" runat="server" CssClass="smalltext" Text="Pay Status:" />
                    </td>
                    <td>
                        <asp:DropDownList ID="lstPayStatus" runat="server" TabIndex="92" CssClass="EditDataDisplay">
                        </asp:DropDownList>
                    </td>
                    <td valign="top">
                        <asp:Label ID="Label42" runat="server" CssClass="smalltext" Text="Ret Escrow Agent:" />
                    </td>
                    <td>
                        <asp:TextBox ID="txtRetentionEscrowAgent" runat="server" CssClass="EditDataDisplay"
                            TabIndex="94" Width="181px"></asp:TextBox>
                    </td>
                </tr>
                <tr>
                    <td width="150px">
                        <asp:Label ID="Label2" runat="server" CssClass="smalltext" Text="Board Approved:" />
                    </td>
                    <td>
                        <telerik:RadDatePicker ID="txtBoardApproved" runat="server" Width="120px" SharedCalendarID="sharedCalendar">
                            <DateInput ID="DateInput2" runat="server" Font-Size="13px" ForeColor="Blue">
                            </DateInput>
                        </telerik:RadDatePicker>
                    </td>
                    <td width="150px">
                    </td>
                    <td>
                    </td>
                    
                </tr>
                <tr>
                    <td valign="top" width="150px">
                        <asp:Label ID="Label44" runat="server" CssClass="smalltext" Text="Comments:" />
                    </td>
                    <td colspan="3">
                        <asp:TextBox ID="txtComments" runat="server" Height="66px" Width="384px" TextMode="MultiLine"
                            TabIndex="95" CssClass="EditDataDisplay"></asp:TextBox>
                    </td>
                </tr>
            </table>
        </telerik:RadPageView>
        <telerik:RadPageView ID="pvWorkflow" runat="server">
            <table width="100%">
                <tr>
                    <td>
                        <br />
                        <asp:Label ID="lblAssignedWorkflowScenerios" runat="server" CssClass="smalltext"
                            Text="Assigned Workflow Scenerios:"></asp:Label>
                    </td>
                </tr>
                <tr>
                    <td>
                        <br />
                        <asp:ListBox ID="lstWorkflowScenerios" runat="server" CssClass="ViewDataDisplay"
                            Height="250px" TabIndex="71" SelectionMode="Multiple" Width="500px"></asp:ListBox>
                    </td>
                </tr>
            </table>
        </telerik:RadPageView>
    </telerik:RadMultiPage>
    <asp:ImageButton ID="butSave" Style="z-index: 104; left: 40px; position: absolute;
        top: 489px" TabIndex="5" runat="server" ImageUrl="images/button_save.gif"></asp:ImageButton>
    <asp:ImageButton ID="butDelete" Style="z-index: 105; left: 243px; position: absolute;
        top: 489px" TabIndex="6" runat="server" 
        ImageUrl="images/button_delete.gif" OnClientClick="return confirmDelete();">
    </asp:ImageButton>
    <asp:Label ID="lblMsg" runat="server" CssClass="smalltext" Font-Bold="True" ForeColor="Red"
        Height="16px" Style="z-index: 102; left: 22px; position: absolute; top: 520px"
        TabIndex="300">Error Message</asp:Label>
    <asp:Label ID="Label1" Style="z-index: 101; left: 524px; position: absolute; top: 486px;"
        runat="server" CssClass="left">ID:</asp:Label>
    <asp:Label ID="lblContractID" Style="z-index: 129; left: 556px; position: absolute;
        top: 486px" runat="server" CssClass="ViewDataDisplay" Height="16px" TabIndex="300">###</asp:Label>
    <asp:HiddenField ID="txtAmount" runat="server" />
    <asp:HiddenField ID="txtReimbAmount" runat="server" />
    <asp:HiddenField ID="lblMinAmount" runat="server" />
    <asp:HiddenField ID="lblMaxAmount" runat="server" />
    <asp:HiddenField ID="txtxHasDependants" runat="server" />
    <telerik:RadAjaxManager ID="RadAjaxManager1" runat="server">
        <AjaxSettings>
            <telerik:AjaxSetting AjaxControlID="lstObjectCode">
                <UpdatedControls>
                    <telerik:AjaxUpdatedControl ControlID="lblMsg" />
                    <telerik:AjaxUpdatedControl ControlID="lblMinAmount" />
                    <telerik:AjaxUpdatedControl ControlID="lblMaxAmount" />
                </UpdatedControls>
            </telerik:AjaxSetting>
            <telerik:AjaxSetting AjaxControlID="RadGrid1">
                <UpdatedControls>
                    <telerik:AjaxUpdatedControl ControlID="RadGrid1" />
                </UpdatedControls>
            </telerik:AjaxSetting>
            <telerik:AjaxSetting AjaxControlID="AttachmentsPopup_AjaxHiddenButton">
                <UpdatedControls>
                    <telerik:AjaxUpdatedControl ControlID="lstAttachments" />
                </UpdatedControls>
            </telerik:AjaxSetting>
            <telerik:AjaxSetting AjaxControlID="lstStatus">
                <UpdatedControls>
                    <telerik:AjaxUpdatedControl ControlID="lstStatus" />
                    <telerik:AjaxUpdatedControl ControlID="lblmsg" />
                </UpdatedControls>
            </telerik:AjaxSetting>
        </AjaxSettings>
    </telerik:RadAjaxManager>
    <telerik:RadAjaxLoadingPanel ID="RadAjaxLoadingPanel1" runat="server" Height="75px"
        Width="75px" Transparency="25">
        <img alt="Loading..." src='<%= RadAjaxLoadingPanel.GetWebResourceUrl(Page, "Telerik.Web.UI.Skins.Default.Ajax.loading.gif") %>'
            style="border: 0;" />
    </telerik:RadAjaxLoadingPanel>
    <telerik:RadWindowManager ID="RadPopups" runat="server" />
    <%-- 
            Put Hidden button on form to handle ajax post back from rad window
            
            --%>
    <div style="display: none">
        <asp:Button ID="AttachmentsPopup_AjaxHiddenButton" runat="server"></asp:Button>
    </div>
    <telerik:RadCalendar ID="sharedCalendar" runat="server" EnableMultiSelect="false">
    </telerik:RadCalendar>
    </form>
</body>
</html>
