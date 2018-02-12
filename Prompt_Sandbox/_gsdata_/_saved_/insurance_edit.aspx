<%@ Page Language="vb" %>

<%@ Import Namespace="System.IO" %>

<%@ Register Assembly="Telerik.Web.UI" Namespace="Telerik.Web.UI" TagPrefix="telerik" %>
<%@ Import Namespace="Prompt" %>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">

<script runat="server">

    Private nInsuranceID As Integer = 0
    Private nContactID As Integer = 0

    Private Sub Page_Load(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MyBase.Load

        ProcLib.CheckSession(Page)
        ProcLib.LoadPopupJscript(Page)

        Session("PageID") = "InsuranceEdit"
        
        lblMessage.Text = ""

        nInsuranceID = Request.QueryString("ID")
        nContactID = Request.QueryString("ContactID")
       
        'set up help button
        butHelp.Attributes.Add("onclick", "openPopup('help_view.aspx','pophelp',550,450,'yes');")
        butHelp.NavigateUrl = "#"
        
  
        If Not IsPostBack Then
            
           
            'get the data
            Using db As New PromptDataHelper
                
                Dim sql As String = "SELECT DISTINCT PolicyType AS VAL, PolicyType AS Lbl FROM InsurancePolicies WHERE DistrictID = " & Session("DistrictID")
                sql &= " ORDER BY PolicyType "
                db.FillNewRADComboBox(sql, lstPolicyType, True, False, False)
                
                If nInsuranceID = 0 Then
                    butDelete.Visible = False
                Else
  
                    db.FillForm(Form1, "SELECT * FROM InsurancePolicies WHERE InsuranceID = " & nInsuranceID)
                End If
              
            End Using
        End If
        
         
        lblxInsuranceID.Text = nInsuranceID
        txtExpirationDate.Focus()

    End Sub
    

    Private Sub butSave_Click(ByVal sender As System.Object, ByVal e As System.Web.UI.ImageClickEventArgs) Handles butSave.Click
    
  
        Using db As New PromptDataHelper
            Dim sql As String = ""
            If nInsuranceID = 0 Then   'new record
                sql = "INSERT INTO InsurancePolicies (DistrictID, ContactID) "
                sql &= "VALUES (" & HttpContext.Current.Session("DistrictID") & "," & nContactID & ")"
                sql &= ";SELECT NewKey = Scope_Identity()"

                nInsuranceID = db.ExecuteScalar(sql)

            End If

            'Update record
            db.SaveForm(Form1, "SELECT * FROM InsurancePolicies WHERE InsuranceID = " & nInsuranceID)
            
   
        End Using

        Session("RtnFromEdit") = True
        ProcLib.CloseAndRefreshRADNoPrompt(Page)
    End Sub

    Private Sub butDelete_Click(ByVal sender As System.Object, ByVal e As System.Web.UI.ImageClickEventArgs) Handles butDelete.Click
       
        Using db As New PromptDataHelper
            Dim strPhysicalPath As String = ProcLib.GetCurrentAttachmentPath() & "DistrictID_" & HttpContext.Current.Session("DistrictID")
            strPhysicalPath &= "/CompanyInsurancePolicies/ContactID_" & nContactID & "/InsuranceID_" & nInsuranceID & "/"
            Dim folder As New DirectoryInfo(strPhysicalPath)
            If folder.Exists Then  'there could be files so get all and list
 
                For Each fi As FileInfo In folder.GetFiles()
                    fi.Delete()
                Next
                
                folder.Delete()

            End If
            
  
            db.ExecuteNonQuery("DELETE FROM InsurancePolicies WHERE InsuranceID = " & nInsuranceID)
        End Using

        Session("RtnFromEdit") = True
        ProcLib.CloseAndRefreshRADNoPrompt(Page)
    End Sub


  
</script>

<html>
<head>
    <title>Insurance Edit</title>
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
    <asp:HyperLink ID="butHelp" Style="z-index: 112; left: 393px; position: absolute;
        top: 14px; height: 20px;" runat="server" ImageUrl="images/button_help.gif">HyperLink</asp:HyperLink>
    <asp:ImageButton ID="butSave" Style="z-index: 113; left: 17px; position: absolute;
        top: 176px" TabIndex="100" runat="server" 
        ImageUrl="images/button_save.gif">
    </asp:ImageButton>
    <asp:ImageButton ID="butDelete" Style="z-index: 107; left: 240px; position: absolute;
        top: 175px" TabIndex="400" runat="server" 
        ImageUrl="images/button_delete.gif">
    </asp:ImageButton>
    <asp:Label ID="lblMessage" Style="z-index: 105; left: 16px; position: absolute; top: 152px"
        runat="server" Height="24px" Font-Bold="True" ForeColor="Red">Error Message</asp:Label>
    <asp:Label ID="Label7" Style="z-index: 105; left: 15px; position: absolute; top: 22px"
        runat="server" Height="24px">Exp Date:</asp:Label>
    <asp:Label ID="Label16" Style="z-index: 105; left: 14px; position: absolute; top: 90px;"
        runat="server" Height="24px">Notes:</asp:Label>
    <asp:Label ID="lblxInsuranceID" Style="z-index: 105; left: 383px; position: absolute;
        top: 177px" runat="server" Class="ViewDataDisplay" Height="24px"></asp:Label>
    <asp:Label ID="Label12" Style="z-index: 105; left: 364px; position: absolute; top: 177px; width: 13px;"
        runat="server" Height="24px">ID:</asp:Label>
    <telerik:RadDatePicker ID="txtExpirationDate" Style="z-index: 6103; left: 84px; position: absolute;
        top: 21px" runat="server" Width="120px" Skin="Web20" TabIndex="1">
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
        
           <telerik:RadComboBox ID="lstPolicyType" Style="z-index: 138; left: 85px; position: absolute;
        top: 56px;" TabIndex="2" runat="server" AllowCustomText="True">
    </telerik:RadComboBox>
        
    <asp:Label ID="Label18" Style="z-index: 105; left: 14px; position: absolute; top: 62px; right: 1172px; width: 121px;"
        runat="server" Height="24px">Type:</asp:Label>
        
    
    <asp:Label ID="Label20" Style="z-index: 105; left: 658px; position: absolute; top: -551px; right: 600px; width: 49px;"
        runat="server" Height="24px">Status:</asp:Label>
        
    
    <asp:TextBox ID="txtNotes" Style="z-index: 103; left: 86px; position: absolute;
        top: 90px; width: 358px; bottom: 734px; right: 857px; height: 57px;" runat="server"
        TabIndex="80" CssClass="EditDataDisplay" TextMode="MultiLine"></asp:TextBox>
        
    
    <asp:CheckBox ID="chkInsuranceRequired" runat="server" Style="z-index: 103; left: 332px; position: absolute;
        top: 55px;" Text="Required :" TextAlign="Left"  />
        
    
    </form>
</body>
</html>
