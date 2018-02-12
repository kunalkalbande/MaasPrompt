<%@ Page Language="vb" ValidateRequest="false" %>

<%@ Register Assembly="Telerik.Web.UI" Namespace="Telerik.Web.UI" TagPrefix="telerik" %>
<%@ Import Namespace="Prompt" %>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">

<script runat="server">
    
    Public nParentRecID As Integer = 0
    Public sParentRecType As String = ""
    Public sBudgetItemField As String = ""
    Public nRFIID As Integer = 0
    
    Private bReadOnly As Boolean = True
    
    Private sCallingWindowType As String = ""
    
    Private Sub Page_Load(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MyBase.Load
        
        ProcLib.CheckSession(Page)
        ProcLib.LoadPopupJscript(Page)

        'set up help button
        Session("PageID") = "FlagEdit"
 
        nParentRecID = Request.QueryString("ParentRecID")
        sParentRecType = Request.QueryString("ParentRecType")
        sBudgetItemField = Request.QueryString("BudgetItem")
        nRFIID = Request.QueryString("RFIID")
        
        sCallingWindowType = Request.QueryString("WinType")   'for special close routine with RAD windows
        
        If Not IsPostBack Then
            
            BuildMenu()
           
            Using db As New promptFlag
                With db
                    .CallingPage = Page
                    .ParentRecID = nParentRecID
                    .ParentRecType = sParentRecType
                    .BudgetItemField = sBudgetItemField
                    '.RFIID = nRFIID
                    .GetFlagForEdit()
                    
                End With
            End Using
            
        End If
        
        Dim xx As Integer = txtFlagID.Value   'hidden field to hold flag ID
        
        With RadPopups
            .Skin = "Office2007"
            .VisibleOnPageLoad = False
            Dim ww As New RadWindow
            With ww
                .ID = "ShowHelpWindow"
                .NavigateUrl = ""
                .Title = ""
                .Width = 400
                .Height = 300
                .Top = 30
                .Left = 10
                .Modal = False
                .VisibleStatusbar = True
                .ReloadOnShow = True
                .Behaviors = WindowBehaviors.Close + WindowBehaviors.Move
            End With
            .Windows.Add(ww)
           
        End With

        txtFlagDescription.Focus()

    End Sub
   
    Public Sub BuildMenu()
        
        If Not IsPostBack Then

            With RadMenu1
                .Items.Clear()
                .Skin = "Windows7"
                .EnableEmbeddedSkins = True
                .Width = Unit.Percentage(99)
                .EnableOverlay = False
                .CollapseAnimation.Duration = "200"
                .CollapseAnimation.Type = AnimationType.InOutBounce
                .ExpandAnimation.Duration = "200"
                .ExpandAnimation.Type = AnimationType.InOutBounce
            End With
            
            Dim mm As RadMenuItem
        
            mm = New RadMenuItem
            With mm
                .Text = "Close"
                .Value = "Close"
                .ImageUrl = "images/exit.png"
            End With
            RadMenu1.Items.Add(mm)
        
            Using dbsec As New EISSecurity
                dbsec.DistrictID = HttpContext.Current.Session("DistrictID")
                dbsec.CollegeID = HttpContext.Current.Session("CollegeID")
                dbsec.UserID = HttpContext.Current.Session("UserID")

                Dim sPermission As String = ""
                Select Case sParentRecType
                    Case "Project"
                        sPermission = "ProjectOverview"

                    Case "Contract"
                        sPermission = "ContractOverview"

                    Case "ContractDetail"
                        sPermission = "ContractOverview"

                    Case "Transaction"
                        sPermission = "Transactions"

                    Case "BudgetItem"
                        sPermission = "JCAFBudget"
                    Case "RFI"
                        sPermission = "ProjectOverview"
                    
                End Select
            
                If dbsec.FindUserPermission(sPermission, "write") Then
                
                    bReadOnly = False
                
                    mm = New RadMenuItem
                    With mm
                        .Text = "Save"
                        .Value = "Save"
                        .ImageUrl = "images/prompt_savetodisk.gif"
                    End With
                    RadMenu1.Items.Add(mm)
        
                    mm = New RadMenuItem
                    With mm
                        .Text = "Resolve"
                        .Value = "Resolve"
                        .ImageUrl = "images/check2.png"
                    End With
                    RadMenu1.Items.Add(mm)
                
                Else
                    txtFlagDescription.Enabled = False
                End If
            
            End Using       
        
            'mm = New RadMenuItem
            'With mm
            '    .Text = "Help"
            '    .Value = "Help"
            '    .ImageUrl = "images/help.png"
            '    .Attributes("onclick") = "return ShowHelp();"
            '    .NavigateUrl = "#"
            '    .PostBack = False
            'End With
            'RadMenu1.Items.Add(mm)
                      
        End If    
           
    End Sub
     
    Private Sub CloseMe()
        Session("RtnFromEdit") = True
        If Request.QueryString("WinType") = "RAD" Then
            If bReadOnly Then
                ProcLib.CloseOnlyRAD(Page)
            Else
                ProcLib.CloseAndRefreshRAD(Page)
            End If
            
        Else
            If bReadOnly Then
                ProcLib.CloseOnly(Page)
            Else
                ProcLib.CloseAndRefresh(Page)
            End If
        End If
    End Sub

    Protected Sub RadMenu1_ItemClick(ByVal sender As Object, ByVal e As Telerik.Web.UI.RadMenuEventArgs)
        Select Case e.Item.Text
            Case "Close"
                CloseMe()
                
            Case "Save"
                
                If txtFlagDescription.Text = "" Then
                    lblMessage.Text = "You must include a description." 'and select assigned users."
                Else
                    Using db As New promptFlag
                        With db
                            .CallingPage = Page
                            .ParentRecID = nParentRecID
                            .ParentRecType = sParentRecType
                            .BudgetItemField = sBudgetItemField
                            .RFIID = nRFIID
                            db.SaveFlag(txtFlagID.Value)
                        End With
                    End Using
                    CloseMe()
                End If

            Case "Resolve"
                
                Using db As New promptFlag
                    With db
                        .CallingPage = Page
                        .ParentRecID = nParentRecID
                        .ParentRecType = sParentRecType
                        .BudgetItemField = sBudgetItemField
                        db.ResolveFlag(txtFlagID.Value, txtFlagDescription.Text)
                    End With
                End Using
                
                CloseMe()
                'Session("RtnFromEdit") = True               
                'ProcLib.CloseAndRefreshRADNoPrompt("ASP.rfi_edit_aspx")
                
        End Select

    End Sub
</script>

<html>
<head>
    <title>Edit Flag</title>
    <link href="Styles.css" type="text/css" rel="stylesheet" />

    <script type="text/javascript" language="javascript">
        function GetRadWindow() {
            var oWindow = null;
            if (window.RadWindow) oWindow = window.RadWindow;
            else if (window.frameElement.radWindow) oWindow = window.frameElement.radWindow;
            return oWindow;
        }

        function ShowHelp()     //for help display
        {

            var oWnd = window.radopen("help_view.aspx?WinType=RAD", "ShowHelpWindow");
            return false;
        } 

    </script>

</head>
<body>
    <form id="Form1" method="post" runat="server">
    <telerik:RadScriptManager ID="RadScriptManager1" runat="server" />
    &nbsp;
    <asp:Label ID="Label2" runat="server" CssClass="smalltext" EnableViewState="False"
        Style="z-index: 101; left: 8px; position: absolute; top: 35px">Description:</asp:Label>
    <asp:TextBox ID="txtFlagDescription" Style="z-index: 102; left: 6px; position: absolute;
        top: 54px" TabIndex="1" runat="server" Height="99px" CssClass="EditDataDisplay"
        TextMode="MultiLine" Width="427px"></asp:TextBox>
    &nbsp;
    <asp:Label ID="Label3" runat="server" CssClass="smalltext" EnableViewState="False"
        Style="z-index: 104; left: 10px; position: absolute; top: 163px">Created By:</asp:Label>
    <asp:Label ID="lblMessage" runat="server" CssClass="smalltext" EnableViewState="False"
        ForeColor="Red" Style="z-index: 114; left: 138px; position: absolute; top: 36px"
        Width="294px"></asp:Label>
    <asp:Label ID="Label6" runat="server" CssClass="smalltext" EnableViewState="False"
        Style="z-index: 106; left: 11px; position: absolute; top: 187px">Last Update By:</asp:Label>
    <asp:Label ID="lblCreatedBy" runat="server" CssClass="EditDataDisplay" Style="z-index: 107;
        left: 77px; position: absolute; top: 162px"></asp:Label>
    <asp:Label ID="lblLastUpdateBy" runat="server" CssClass="EditDataDisplay" Style="z-index: 108;
        left: 97px; position: absolute; top: 187px"></asp:Label>
    <asp:Label ID="lblCreatedOn" runat="server" CssClass="EditDataDisplay" Style="z-index: 109;
        left: 291px; position: absolute; top: 163px"></asp:Label>
    <asp:Label ID="lblLastUpdateOn" runat="server" CssClass="EditDataDisplay" Style="z-index: 110;
        left: 292px; position: absolute; top: 188px"></asp:Label>
    <asp:Label ID="Label4" runat="server" CssClass="smalltext" EnableViewState="False"
        Style="z-index: 111; left: 266px; position: absolute; top: 164px">On:</asp:Label>
    <asp:Label ID="Label7" runat="server" CssClass="smalltext" EnableViewState="False"
        Style="z-index: 112; left: 266px; position: absolute; top: 188px">On:</asp:Label>
    <!-- Menu Items -->
    <telerik:RadMenu ID="RadMenu1" runat="server" Style="z-index: 113; left: 5px; position: absolute;
        top: 2px" BorderColor="Silver" BorderStyle="Solid" BorderWidth="1px" OnItemClick="RadMenu1_ItemClick">
        <Items>
            <telerik:RadMenuItem runat="server" Text="Help">
            </telerik:RadMenuItem>
            <telerik:RadMenuItem runat="server" Text="Close">
            </telerik:RadMenuItem>
        </Items>
    </telerik:RadMenu>
    <telerik:RadWindowManager ID="RadPopups" runat="server">
    </telerik:RadWindowManager>
    <asp:HiddenField ID="txtFlagID" runat="server" Value="0" />
    </form>
</body>
</html>
