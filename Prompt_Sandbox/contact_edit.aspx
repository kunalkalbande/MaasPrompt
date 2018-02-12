<%@ Page Language="vb" %>
<%@ Import Namespace="Prompt" %>
<%@ Register Assembly="Telerik.Web.UI" Namespace="Telerik.Web.UI" TagPrefix="telerik" %>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">

<script runat="server">

    Public nContactID As Integer = 0
    Public nUserID As Integer = 0
    Public nUserStatus As Integer
    
    
    Private Sub Page_Load(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MyBase.Load

        ProcLib.CheckSession(Page)

        ProcLib.LoadPopupJscript(Page)
        
        lblMessage.Text = ""

        'set up help button
        Session("PageID") = "ContactEdit"
        butHelp.Attributes.Add("onclick", "openPopup('help_view.aspx','pophelp',900,600,'yes');")
        butHelp.NavigateUrl = "#"

        nContactID = Request.QueryString("ContactID")
             
        If Not IsPostBack Then   'only do the following post back
            Session("nUserID") = 0
            Using rs As New Contact
                If nContactID = 0 Then    'add the new record
                    butDelete.Visible = False
                    'chkCreateUserAccount.Visible = False
                    'chkDisableUserAccount.Visible = False
                Else
                    nUserID = rs.getUserAccount(nContactID)
                    Session("nUserID") = nUserID
                End If
                
                With rs
                    .CallingPage = Page
                    .GetContactForEdit(nContactID)
                End With
            End Using
        End If
        'txtComments.Text = "This is here" & nUserID
        If nContactID = 0 Then
            chkCreateUserAccount.Visible = False
            chkDisableUserAccount.Visible = False
        Else
            If nUserID <> 0 Then
                chkCreateUserAccount.Visible = False
                chkDisableUserAccount.Visible = True
                Using db As New Contact
                    nUserStatus = db.checkAccountStatus(nUserID)
                    '1 = disabled
                    '0 = enabled
                End Using
            
                If nUserStatus = 1 Then
                    chkDisableUserAccount.Text = "Enable User Account"
                ElseIf nUserStatus = 0 Then
                    chkDisableUserAccount.Text = "Disable User Account"
                End If
               ' txtComments.Text = nUserID
            Else
                chkCreateUserAccount.Visible = True
                chkDisableUserAccount.Visible = False
            End If
            
            Try
                If Session("RFIContactID") = nContactID Then
                    chkDisableUserAccount.Visible = False
                End If
            Catch ex As Exception
            End Try

        End If
        
        lblContactID.Text = nContactID
        
        txtFirstName.Focus()
        
        If lstContactType.SelectedValue = "ProjectManager" Then
            lstUserID.Visible = True
            lblAssocUser.Visible = True
        Else
            lstUserID.Visible = False
            lblAssocUser.Visible = False
        End If

    End Sub


    Private Sub butSave_Click(ByVal sender As System.Object, ByVal e As System.Web.UI.ImageClickEventArgs) Handles butSave.Click
        
        If txtFirstName.Text = "" Then
            lblMessage.Text = "Please enter a First Name."
            Exit Sub
        End If
        
        If chkCreateUserAccount.Checked = True Then
            Dim userName As String = txtFirstName.Text & " " & txtLastName.Text
            If txtEmail.Text = "" Then
                lblMessage.Text = "Please enter a email address."
                Exit Sub
            End If
            Dim sEmail As String = txtEmail.Text
            
            Using db As New Contact
                Dim tempcom = db.createRFIUserAccount(nContactID, userName, sEmail)
                'txtComments.Text = tempcom
            End Using
            ProcLib.CloseAndRefreshRAD(Page)
            Exit Sub
        End If
        
        txtName.Value = txtFirstName.Text & " " & txtLastName.Text   'to update the full name field
        
        Using db As New PromptDataHelper
            
            If nContactID = 0 Then  'this is new contact so add new 
                Dim Sql As String = "INSERT INTO Contacts "
                Sql &= "(DistrictID,ContactType) "
                Sql &= "VALUES ("
                Sql &= Session("DistrictID") & ",'Contact')"
                Sql &= ";SELECT NewKey = Scope_Identity()"  'return the new primary key
                nContactID = db.ExecuteScalar(Sql)
            End If

            'Saves record
            db.SaveForm(Form1, "SELECT * FROM Contacts WHERE ContactID = " & nContactID)
            
            Try
                'HACK: Force save of name field
                db.ExecuteNonQuery("UPDATE Contacts SET Name = '" & txtFirstName.Text & " " & txtLastName.Text & "', UserID = " _
                                   & Session("nUserID") & " WHERE ContactID = " & nContactID)
            Catch
            End Try
                  
        End Using
        
        If chkDisableUserAccount.Checked = True Then
            Using db As New Contact
                Dim newStatus As Integer = db.switchCurrentAccountStatus(Session("nUserID"))
            End Using           
        End If

        ProcLib.CloseAndRefreshRAD(Page)
    End Sub

    Private Sub butDelete_Click(ByVal sender As System.Object, ByVal e As System.Web.UI.ImageClickEventArgs) Handles butDelete.Click
        Dim msg As String = ""
        Using db As New Contact
            msg = db.DeleteContact(nContactID)
        End Using
 
        If msg = "" Then
            Session("RtnFromEdit") = True
            ProcLib.CloseAndRefreshRAD(Page)
        Else
            lblMessage.Text = "This Contact is associated with existing records. Make Inactive instead of Deleting."
        End If
        
       

    End Sub

</script>

<html>
<head>
    <title>Contact Edit</title>
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
    <asp:Label ID="Label1" Style="z-index: 100; left: 11px; position: absolute; top: 10px;
        height: 14px; width: 17px;" runat="server" EnableViewState="False">ID:</asp:Label>
    <asp:ImageButton ID="butDelete" Style="z-index: 136; left: 368px; position: absolute;
        top: 563px; height: 23px;" TabIndex="99" runat="server" 
        OnClientClick="return confirm('You are about to delete this contact.\n\nAre you sure you want to delete this contact?')"
        ImageUrl="images/button_delete.gif">
    </asp:ImageButton>
    <asp:ImageButton ID="butSave" Style="z-index: 120; left: 38px; position: absolute;
        top: 562px; right: 871px;" TabIndex="40" runat="server" 
        ImageUrl="images/button_save.gif"></asp:ImageButton>
        
        <asp:HyperLink ID="butHelp" runat="server" Style="z-index: 120; left: 423px; position: absolute;
        top: 11px; height: 15px; bottom: 878px;" ImageUrl="images/button_help.gif">HyperLink</asp:HyperLink>
        
   
    <asp:Label ID="Label15" Style="z-index: 117; left: 40px; position: absolute; top: 467px;
        height: 19px;" runat="server" EnableViewState="False">Email:</asp:Label>
    <asp:TextBox ID="txtEmail" Style="z-index: 131; left: 93px; position: absolute; top: 466px"
        TabIndex="21" runat="server" Width="192px" CssClass="EditDataDisplay"></asp:TextBox>

    <asp:Label ID="emailAlert" Style="z-index: 117; left: 300px; position: absolute; top: 467px;
        height: 19px;width:200px" runat="server" EnableViewState="False">
        If creating a prompt login account, this email will be used for the user ID
        
        </asp:Label>

    <asp:TextBox ID="txtComments" Style="z-index: 130; left: 94px; position: absolute;
        top: 501px; height: 48px; width: 365px;" TabIndex="23" runat="server" MaxLength="500"
        TextMode="MultiLine" CssClass="EditDataDisplay"></asp:TextBox>
    <asp:TextBox ID="txtFax" Style="z-index: 129; left: 95px; position: absolute; top: 432px"
        TabIndex="20" runat="server" Width="120px" CssClass="EditDataDisplay"></asp:TextBox>
    <asp:TextBox ID="txtExt" Style="z-index: 127; left: 279px; position: absolute; top: 325px;
        width: 39px;" TabIndex="15" runat="server" CssClass="EditDataDisplay"></asp:TextBox>

   <asp:TextBox ID="txtCell" Style="z-index: 127; left: 92px; position: absolute;
        top: 361px; right: 1395px;" TabIndex="14" runat="server" Width="120px" CssClass="EditDataDisplay"></asp:TextBox>

    <asp:TextBox ID="txtPhone1" Style="z-index: 127; left: 92px; position: absolute;
        top: 325px; right: 1395px;" TabIndex="14" runat="server" Width="120px" CssClass="EditDataDisplay"></asp:TextBox>
    <asp:TextBox ID="txtZip" Style="z-index: 125; left: 91px; position: absolute; top: 256px"
        TabIndex="12" runat="server" Width="96px" CssClass="EditDataDisplay"></asp:TextBox>
    <asp:TextBox ID="txtState" Style="z-index: 124; left: 94px; position: absolute; top: 218px"
        TabIndex="11" runat="server" Width="64px" CssClass="EditDataDisplay"></asp:TextBox>
    <asp:TextBox ID="txtCity" Style="z-index: 123; left: 93px; position: absolute; top: 187px"
        TabIndex="10" runat="server" Width="144px" CssClass="EditDataDisplay"></asp:TextBox>
    <asp:TextBox ID="txtAddress2" Style="z-index: 121; left: 92px; position: absolute;
        top: 154px" TabIndex="8" runat="server" Width="248px" 
        CssClass="EditDataDisplay"></asp:TextBox>
    <asp:TextBox ID="txtAddress1" Style="z-index: 119; left: 95px; position: absolute;
        top: 121px" TabIndex="7" runat="server" Width="248px" 
        CssClass="EditDataDisplay"></asp:TextBox>
    <asp:Label ID="Label14" Style="z-index: 118; left: 12px; position: absolute; top: 503px"
        runat="server" EnableViewState="False">Comments:</asp:Label>
    <asp:Label ID="Label12" Style="z-index: 115; left: 46px; position: absolute; top: 438px;
        width: 16px;" runat="server" EnableViewState="False">Fax:</asp:Label>
    <asp:Label ID="Label11" Style="z-index: 114; left: 32px; position: absolute; top: 403px;
        height: 19px;" runat="server" EnableViewState="False">Phone2:</asp:Label>
    <asp:Label ID="Label20" Style="z-index: 113; left: 27px; position: absolute; top: 332px;
        right: 1537px;" runat="server" EnableViewState="False">Phone1:</asp:Label>
    <asp:Label ID="Label19" Style="z-index: 113; left: 43px; position: absolute; top: 367px"
        runat="server" EnableViewState="False">Cell:</asp:Label>
    <asp:Label ID="Label10" Style="z-index: 113; left: 240px; position: absolute; top: 328px"
        runat="server" EnableViewState="False">Ext:</asp:Label>
    <asp:Label ID="Label8" Style="z-index: 111; left: 24px; position: absolute; top: 260px; height: 10px;"
        runat="server" EnableViewState="False">ZipCode:</asp:Label>
    <asp:Label ID="Label18" Style="z-index: 110; left: 38px; position: absolute; top: 224px;
        height: 21px;" runat="server" EnableViewState="False">State:</asp:Label>
    <asp:Label ID="Label22" Style="z-index: 109; left: 38px; position: absolute; top: 187px"
        runat="server" EnableViewState="False">City:</asp:Label>
    <asp:Label ID="Label26" Style="z-index: 109; left: 281px; position: absolute; top: 181px"
        runat="server" EnableViewState="False">Assoc. Company:</asp:Label>
    <asp:Label ID="lblAssocUser" Style="z-index: 109; left: 282px; position: absolute; top: 234px"
        runat="server" EnableViewState="False">Assoc. User:</asp:Label>
    <asp:Label ID="Label23" Style="z-index: 109; left: 10px; position: absolute; top: 293px"
        runat="server" EnableViewState="False">Contact Type:</asp:Label>
    <asp:Label ID="lblMessage" Style="z-index: 109; left: 96px; position: absolute; top: 10px"
        runat="server" EnableViewState="False" Font-Bold="True" ForeColor="Red"></asp:Label>
    <asp:Label ID="Label5" Style="z-index: 108; left: 19px; position: absolute; top: 157px"
        runat="server" EnableViewState="False">Address2:</asp:Label>
    <asp:Label ID="Label4" Style="z-index: 107; left: 21px; position: absolute; top: 125px"
        runat="server" EnableViewState="False">Address1:</asp:Label>
    <asp:Label ID="Label24" Style="z-index: 105; left: 25px; position: absolute; top: 67px;
        bottom: 822px;" runat="server" EnableViewState="False">Last Name:</asp:Label>
    <asp:Label ID="Label21" Style="z-index: 105; left: 25px; position: absolute; top: 35px;
        bottom: 854px;" runat="server" EnableViewState="False">First Name:</asp:Label>
    <asp:Label ID="Label2" Style="z-index: 105; left: 29px; position: absolute; top: 93px"
        runat="server" EnableViewState="False">Title:</asp:Label>
    <asp:Label ID="lblContactID" Style="z-index: 104; left: 46px; position: absolute; top: 11px"
        runat="server">9999</asp:Label>
    <asp:TextBox ID="txtTitle" Style="z-index: 102; left: 94px; position: absolute; top: 89px;
        width: 182px;" runat="server" CssClass="EditDataDisplay" TabIndex="4"></asp:TextBox>
    <asp:TextBox ID="txtLastName" Style="z-index: 102; left: 94px; position: absolute; top: 60px"
        runat="server" Width="248px" CssClass="EditDataDisplay" TabIndex="2"></asp:TextBox>
    <asp:TextBox ID="txtFirstName" Style="z-index: 102; left: 94px; position: absolute; top: 31px"
        runat="server" Width="248px" CssClass="EditDataDisplay" TabIndex="1"></asp:TextBox>

        <asp:TextBox ID="txtPhone2" Style="z-index: 128; left: 95px; position: absolute;
            top: 398px" TabIndex="19" runat="server" Width="120px" 
            CssClass="EditDataDisplay"></asp:TextBox>

<telerik:RadComboBox ID="lstParentContactID" 
        Style="z-index: 5134; left: 286px; position: absolute;top: 201px; " 
        runat="server" TabIndex="11" CssClass="EditDataDisplay" 
        DropDownWidth="250px" MaxHeight="250px" Width="250px">
</telerik:RadComboBox>

<telerik:RadComboBox ID="lstContactType" 
        Style="z-index: 134; left: 94px; position: absolute;top: 292px; width: 170px;" 
        runat="server" TabIndex="11" CssClass="EditDataDisplay">
       <Items>
       <telerik:RadComboBoxItem Text="Associate Program Manager" Value="Associate Program Manager" />
       <telerik:RadComboBoxItem Text="Contact" Value="Contact" />
       <telerik:RadComboBoxItem Text="Construction Manager" Value="Construction Manager" />
       <telerik:RadComboBoxItem Text="Design Professional" Value="Design Professional" />
       <telerik:RadComboBoxItem Text="District" Value="District" />
       <telerik:RadComboBoxItem Text="General Contractor" Value="General Contractor" />
       <telerik:RadComboBoxItem Text="Inspector Of Record" Value="Inspector Of Record" />
       <telerik:RadComboBoxItem Text="Program Manager" Value="Program Manager" />
       <telerik:RadComboBoxItem Text="Project Accountant" Value="Project Accountant" />
       <telerik:RadComboBoxItem Text="Project Manager" Value="ProjectManager" />                                        
       </Items>      
</telerik:RadComboBox>

    <asp:HiddenField ID="txtName" runat="server" Value="" />

       <asp:CheckBox ID="chkInactive" Style="z-index: 102; left: 359px; position: absolute; top: 67px"
        runat="server" runat="server" Text="InActive" />

        <asp:CheckBox ID="chkCreateUserAccount" Style="z-index: 102; left: 359px; position: absolute; top: 97px"
        runat="server" runat="server" Text="Create Prompt User Account" />

        <asp:CheckBox ID="chkDisableUserAccount" Style="z-index: 102; left: 359px; position: absolute; top: 97px"
        runat="server" runat="server" Text="Disable User Account" />

<telerik:RadComboBox ID="lstUserID" 
        Style="z-index: 2134; left: 288px; position: absolute;top: 257px; " 
        runat="server" TabIndex="11" CssClass="EditDataDisplay" 
        DropDownWidth="250px" MaxHeight="250px" Width="200px">
</telerik:RadComboBox>


    </form>
</body>
</html>
