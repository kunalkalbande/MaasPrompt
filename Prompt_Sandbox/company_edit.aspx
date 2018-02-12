<%@ Page Language="vb" %>

<%@ Import Namespace="System.IO" %>
<%@ Register Assembly="Telerik.Web.UI" Namespace="Telerik.Web.UI" TagPrefix="telerik" %>
<%@ Import Namespace="Prompt" %>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">

<script runat="server">

    Public nCompanyID As Integer = 0
    Private bReadOnly As Boolean = False
    
    Private Sub Page_Load(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MyBase.Load

        ProcLib.CheckSession(Page)

        ProcLib.LoadPopupJscript(Page)

        'set up help button
        Session("PageID") = "CompanyEdit"
        
        butHelp.Attributes.Add("onclick", "openPopup('help_view.aspx','pophelp',550,450,'yes');")
        butHelp.NavigateUrl = "#"

        Session("passbacktype") = Request.QueryString("type")   'for use in project edit for Company and arch calls

        nCompanyID = Request.QueryString("ContactID")
        
        lblMessage.Text = ""
        
        Using rs As New Company

            If Not IsPostBack Then
              
                If nCompanyID = 0 Then    'add the new record
                    With rs
                        .CallingPage = Page
                        .GetNewCompany()
                    End With
                    butDelete.Visible = False
                    butAddInsurance.Visible = False
                
                Else
                    With rs
                        .CallingPage = Page
                        .GetExistingCompany(nCompanyID)
                    End With

                End If
                
                lblID.Text = nCompanyID
            End If
            

        End Using

        'check for passback value and if there, add entry to dropdown and select
        If Session("passback") <> "" Then
            Dim item As New RadComboBoxItem
            item.Text = Session("passback")
            item.Value = Session("passback")
            lstCompanyType.Items.Add(item)
            lstCompanyType.SelectedValue = Session("passback")
            Session("passback") = ""
        End If

        Page.SetFocus("txtName")
        
        ''set up attachments button
        butAddInsurance.Attributes("onclick") = "return EditInsurance(" & nCompanyID & ",0);"
        butAddInsurance.NavigateUrl = "#"
        
        SetUpRadWindows()

        'Set Grid Properties
        With RadGrid1
            .EnableEmbeddedSkins = False
            .Skin = "Prompt"
            .GroupingEnabled = False
            .AllowSorting = True
                        
            .ClientSettings.AllowColumnsReorder = False
            .ClientSettings.ColumnsReorderMethod = GridClientSettings.GridColumnsReorderMethod.Reorder
            .ClientSettings.Scrolling.AllowScroll = True
            .ClientSettings.Scrolling.ScrollHeight = Unit.Percentage(50)
            .ClientSettings.Scrolling.UseStaticHeaders = True
            .ClientSettings.Resizing.AllowColumnResize = True

            .MasterTableView.EnableHeaderContextMenu = False
            .MasterTableView.TableLayout = GridTableLayout.Fixed
            .MasterTableView.AllowMultiColumnSorting = False

            .Height = Unit.Pixel(300)
 
            
            .ExportSettings.FileName = "PromptInsuranceExport"
            .ExportSettings.OpenInNewWindow = True
        End With
    End Sub


  
    Private Sub butSave_Click(ByVal sender As System.Object, ByVal e As System.Web.UI.ImageClickEventArgs) Handles butSave.Click
        
        If txtName.Text = "" Then
            lblMessage.Text = "Please enter a Name."
            Exit Sub
        End If
        
        
        Dim bRefreshPassbackCallingPage As Boolean = False   'to force refresh of calling page when passback
        If Request.QueryString("passback") = "y" Then bRefreshPassbackCallingPage = True
        
        Using rs As New Company
            With rs
                .CallingPage = Page
                .SaveCompany(nCompanyID)
            End With
        End Using
  
        If bRefreshPassbackCallingPage Then       'this page was called from an edit page so save keyval to session for passback
            Session("passback") = txtName.Text
            Session("passbackID") = nCompanyID
        End If
        
        If Request.QueryString("WinType") = "RAD" Then
            ProcLib.CloseAndRefreshRAD(Page)
        Else
 
            ProcLib.CloseAndRefresh(Page)  'for legacy popup close - rad window will ignore
        End If

    End Sub

    Private Sub butDelete_Click(ByVal sender As System.Object, ByVal e As System.Web.UI.ImageClickEventArgs) Handles butDelete.Click

        Dim msg As String = ""
        Using db As New Company
            msg = db.DeleteCompany(nCompanyID)
        End Using
        If msg <> "" Then
            lblMessage.Text = "This Company is associated with existing records. Make Inactive instead of Deleting."
        Else
            Session("RtnFromEdit") = True
            ProcLib.CloseAndRefreshRAD(Page)
        End If
        
    End Sub

     
    Private Sub SetUpRadWindows()
        With RadPopups
            .Skin = "Office2007"
            '.VisibleOnPageLoad = False
            Dim ww As New Telerik.Web.UI.RadWindow
            With ww
                .ID = "AttachmentsWindow"
                .NavigateUrl = ""
                .Title = ""
                .Width = 475
                .Height = 485
                .Top = 70
                .Left = 20
                .Modal = False
                .VisibleStatusbar = False
                .ReloadOnShow = True
                .Behaviors = WindowBehaviors.Close + WindowBehaviors.Move
            End With
            .Windows.Add(ww)
        
            ww = New Telerik.Web.UI.RadWindow
            With ww
                .ID = "EditWindow"
                .NavigateUrl = ""
                .Title = ""
                .Width = 500
                .Height = 295
                .Top = 10
                .Left = 10
                .Modal = False
                .VisibleStatusbar = False
                .ReloadOnShow = True
                .Behaviors = WindowBehaviors.Close + WindowBehaviors.Move
            End With
            .Windows.Add(ww)
        End With
    End Sub
    
    
    Protected Sub RadGrid1_NeedDataSource(ByVal source As Object, ByVal e As Telerik.Web.UI.GridNeedDataSourceEventArgs) Handles RadGrid1.NeedDataSource
        ''loads the grid whenever it needs data (sorting, rebinding, etc...)
        Using db As New PromptDataHelper

            Dim tbl As DataTable
            tbl = db.ExecuteDataTable("SELECT * FROM InsurancePolicies WHERE ContactID = " & nCompanyID)


            'Now look for attachments for each Submittal and if present then up the count
            Dim strPhysicalPath As String = ProcLib.GetCurrentAttachmentPath() & "DistrictID_" & HttpContext.Current.Session("DistrictID")
            strPhysicalPath &= "/CompanyInsurancePolicies/"

            Dim strRelativePath As String = ProcLib.GetCurrentRelativeAttachmentPath() & "DistrictID_" & HttpContext.Current.Session("DistrictID")
            strRelativePath &= "/CompanyInsurancePolicies/"

            'Add an attachments column to the result table
            Dim col As New DataColumn
            col.DataType = Type.GetType("System.String")
            col.ColumnName = "Attachments"
            tbl.Columns.Add(col)

            For Each row As DataRow In tbl.Rows
                Dim sPath As String = strPhysicalPath & "ContactID_" & row("ContactID") & "/InsuranceID_" & row("InsuranceID") & "/"
                Dim sRelPath As String = strRelativePath & "ContactID_" & row("ContactID") & "/InsuranceID_" & row("InsuranceID") & "/"
                Dim folder As New DirectoryInfo(sPath)

                row("Attachments") = ""
                If folder.Exists Then  'there could be files so get all and list

                    For Each fi As FileInfo In folder.GetFiles()
                        Dim sfilename As String = fi.Name
                        If Len(sfilename) > 20 Then
                            sfilename = Left(sfilename, 15) & "..." & Right(sfilename, 4)
                        End If

                        Dim sfilelink As String = "<a target='_new' href='" & sRelPath & fi.Name & "'>"
                        row("Attachments") = sfilelink & sfilename & "</a>"
                    Next

                End If
            Next

            RadGrid1.DataSource = tbl
        End Using
        
    End Sub
    
    Protected Sub RadGrid1_ItemCreated(ByVal sender As Object, ByVal e As Telerik.Web.UI.GridItemEventArgs) Handles RadGrid1.ItemCreated
        
        'This event allows us to customize the cell contents - fired before databound

        If (TypeOf e.Item Is GridDataItem) Then
            Dim item As GridDataItem = CType(e.Item, GridDataItem)
            Dim nID As Integer = item.OwnerTableView.DataKeyValues(item.ItemIndex)("InsuranceID")
            Dim sType As String = item.OwnerTableView.DataKeyValues(item.ItemIndex)("PolicyType")
            Dim sAttachments As String = ProcLib.CheckNullDBField(item.OwnerTableView.DataKeyValues(item.ItemIndex)("Attachments"))


            'update the link button to open report window

            Dim linkButton As HyperLink

            If bReadOnly Then
                item("PolicyType").Controls.Clear()
                item("PolicyType").Text = sType
            Else
                linkButton = CType(item("PolicyType").Controls(0), HyperLink)
                linkButton.Attributes("onclick") = "return EditInsurance(" & nCompanyID & "," & nID & ");"
                linkButton.NavigateUrl = "#"
                linkButton.ToolTip = "Edit this Policy."
            End If


            'update the link button to open attachments/notes window
            linkButton = CType(item("ShowAttachments").Controls(0), HyperLink)
            linkButton.ToolTip = "Manage Attachments."
            linkButton.NavigateUrl = "#"
            linkButton.ImageUrl = "images/add.png"

            linkButton.Attributes("onclick") = "return ManageAttachments(" & nCompanyID & "," & nID & ");"

            If sAttachments <> "" Then    'add link for each file
                linkButton.ImageUrl = "images/paper_clip_small.gif"
            End If

           

        End If
        
        
    End Sub
    
</script>

<html>
<head>
    <title>Edit Company</title>
    <link href="Styles.css" type="text/css" rel="stylesheet" />
    <link href="skins/Prompt/Grid.Prompt.css" rel="stylesheet" type="text/css" />

    <script type="text/javascript" language="javascript">

        function GetRadWindow() {
            var oWindow = null;
            if (window.RadWindow) oWindow = window.RadWindow;
            else if (window.frameElement.radWindow) oWindow = window.frameElement.radWindow;
            return oWindow;
        }

        function ManageAttachments(contactid, id)     //for attachments info display
        {

            var oWnd = window.radopen('apprisepm_attachments_manage.aspx?ParentType=Insurance&ContactID=' + contactid + '&ParentID=' + id, 'AttachmentsWindow');
            return false;
        }

        function EditInsurance(contactid, id) {
            var oWnd = window.radopen("insurance_edit.aspx?ID=" + id + "&ContactID=" + contactid, "EditWindow");
            return false;
        }

  

    </script>

</head>
<body>
    <form id="Form1" method="post" runat="server">
    <telerik:RadScriptManager ID="RadScriptManager1" runat="server" />
    <asp:Label ID="Label1" Style="z-index: 100; left: 436px; position: absolute; top: 535px"
        runat="server" EnableViewState="False">ID:</asp:Label>
    <asp:ImageButton ID="butDelete" Style="z-index: 136; left: 279px; position: absolute;
        top: 530px" TabIndex="41" runat="server" ImageUrl="images/button_delete.gif">
    </asp:ImageButton>
    <asp:ImageButton ID="butSave" Style="z-index: 120; left: 30px; position: absolute;
        top: 529px" TabIndex="40" runat="server" ImageUrl="images/button_save.gif"></asp:ImageButton>
    <asp:Label ID="Label15" Style="z-index: 117; left: 227px; position: absolute; top: 246px"
        runat="server" EnableViewState="False">Email:</asp:Label>
    <asp:TextBox ID="txtEmail" CssClass="EditDataDisplay" Style="z-index: 131; left: 270px;
        position: absolute; top: 243px; width: 159px;" TabIndex="17" runat="server"></asp:TextBox>
    <asp:TextBox ID="txtComments" Style="z-index: 130; left: 86px; position: absolute;
        top: 278px" TabIndex="19" runat="server" Height="49px" Width="416px" MaxLength="500"
        TextMode="MultiLine" CssClass="smalltext" Font-Size="Small"></asp:TextBox>
    <asp:TextBox ID="txtFax" Style="z-index: 129; left: 87px; position: absolute; top: 243px"
        TabIndex="16" runat="server" Width="120px" CssClass="EditDataDisplay"></asp:TextBox>
    <asp:TextBox ID="txtPhone2" Style="z-index: 128; left: 296px; position: absolute;
        top: 211px" TabIndex="15" CssClass="EditDataDisplay" runat="server" Width="120px"></asp:TextBox>
    <asp:TextBox ID="txtContact" Style="z-index: 126; left: 85px; position: absolute;
        top: 177px" TabIndex="13" runat="server" Width="144px" CssClass="EditDataDisplay"></asp:TextBox>
    <asp:TextBox ID="txtZip" Style="z-index: 125; left: 396px; position: absolute; top: 140px"
        TabIndex="12" runat="server" Width="96px" CssClass="EditDataDisplay"></asp:TextBox>
    <asp:TextBox ID="txtState" Style="z-index: 124; left: 274px; position: absolute;
        top: 139px" TabIndex="11" runat="server" Width="64px" CssClass="EditDataDisplay"></asp:TextBox>
    <asp:TextBox ID="txtCity" Style="z-index: 123; left: 82px; position: absolute; top: 139px"
        TabIndex="9" runat="server" Width="144px" CssClass="EditDataDisplay"></asp:TextBox>
    <asp:TextBox ID="txtDistrictContractorID" runat="server" CssClass="EditDataDisplay"
        Style="z-index: 123; left: 347px; position: absolute; top: 173px" TabIndex="9"
        Width="144px" MaxLength="11"></asp:TextBox>
    <asp:TextBox ID="txtAddress2" Style="z-index: 121; left: 83px; position: absolute;
        top: 108px" TabIndex="8" runat="server" Width="248px" CssClass="EditDataDisplay"></asp:TextBox>
    <asp:TextBox ID="txtAddress1" Style="z-index: 119; left: 84px; position: absolute;
        top: 75px" TabIndex="7" runat="server" Width="248px" CssClass="EditDataDisplay"></asp:TextBox>
    <asp:Label ID="Label14" Style="z-index: 118; left: 14px; position: absolute; top: 280px"
        runat="server" EnableViewState="False">Comments:</asp:Label>
    <asp:Label ID="Label12" Style="z-index: 115; left: 54px; position: absolute; top: 246px;
        height: 15px;" runat="server" EnableViewState="False">Fax:</asp:Label>
    <asp:Label ID="Label11" Style="z-index: 114; left: 235px; position: absolute; top: 213px"
        runat="server" EnableViewState="False">Phone2:</asp:Label>
    <asp:Label ID="Label10" Style="z-index: 113; left: 36px; position: absolute; top: 215px;
        height: 2px;" runat="server" EnableViewState="False">Phone1:</asp:Label>
    <asp:Label ID="Label9" Style="z-index: 112; left: 32px; position: absolute; top: 178px"
        runat="server" EnableViewState="False">Contact:</asp:Label>
    <asp:Label ID="Label7" Style="z-index: 110; left: 241px; position: absolute; top: 141px;
        height: 20px;" runat="server" EnableViewState="False">State:</asp:Label>
    <asp:Label ID="Label6" Style="z-index: 109; left: 49px; position: absolute; top: 140px"
        runat="server" EnableViewState="False">City:</asp:Label>
    <asp:Label ID="Label5" Style="z-index: 108; left: 22px; position: absolute; top: 109px"
        runat="server" EnableViewState="False">Address2:</asp:Label>
    <asp:Label ID="Label4" Style="z-index: 107; left: 21px; position: absolute; top: 76px;
        height: 6px;" runat="server" EnableViewState="False">Address1:</asp:Label>
    <asp:Label ID="Label18" runat="server" EnableViewState="False" Style="z-index: 107;
        left: 268px; position: absolute; top: 178px; right: 1267px; width: 72px;">District ID #:</asp:Label>
    <asp:Label ID="Label3" Style="z-index: 106; left: 42px; position: absolute; top: 42px"
        runat="server" EnableViewState="False">Type:</asp:Label>
    <asp:Label ID="Label19" Style="z-index: 105; left: 36px; position: absolute; top: 14px;
        height: 17px;" runat="server" EnableViewState="False">Name:</asp:Label>
    <asp:Label ID="lblID" Style="z-index: 104; left: 473px; position: absolute; top: 536px"
        runat="server">9999</asp:Label>
    <telerik:RadComboBox ID="lstCompanyType" Style="z-index: 1103; left: 87px; position: absolute;
        top: 44px" TabIndex="5" runat="server" Width="216px" MaxHeight="200px">
<WebServiceSettings>
<ODataSettings InitialContainerName=""></ODataSettings>
</WebServiceSettings>
    </telerik:RadComboBox>
    <asp:TextBox ID="txtName" Style="z-index: 102; left: 86px; position: absolute; top: 12px"
        runat="server" Width="248px" CssClass="EditDataDisplay"></asp:TextBox>
    <asp:Label ID="lblMessage" Style="z-index: 105; left: 27px; position: absolute; top: 502px;
        height: 9px;" runat="server" EnableViewState="False" Font-Bold="True" ForeColor="Red"></asp:Label>
    <asp:CheckBox ID="chkInactive" Style="z-index: 102; left: 403px; position: absolute;
        top: 43px; height: 22px;" runat="server" runat="server" Text="InActive" />
    <asp:HyperLink ID="butHelp" runat="server" Style="z-index: 120; left: 458px; position: absolute;
        top: 7px; height: 15px; bottom: 859px;" ImageUrl="images/button_help.gif">HyperLink</asp:HyperLink>
    <asp:TextBox ID="txtPhone1" Style="z-index: 127; left: 86px; position: absolute;
        top: 212px" TabIndex="14" runat="server" Width="120px" CssClass="EditDataDisplay"></asp:TextBox>
    <telerik:RadWindowManager ID="RadPopups" runat="server">
    </telerik:RadWindowManager>
    <asp:Label ID="Label8" Style="z-index: 111; left: 363px; position: absolute; top: 142px;
        height: 6px;" runat="server" EnableViewState="False">Zip:</asp:Label>
    <asp:Label ID="Label2" Style="z-index: 111; left: 10px; position: absolute; top: 340px;
        height: 6px;" runat="server" EnableViewState="False">Insurance:</asp:Label>
    <asp:HyperLink ID="butAddInsurance" runat="server" Style="z-index: 350; left: 440px;
        position: absolute; top: 340px; height: 15px;" ImageUrl="images/button_add_new.gif">Add Ins</asp:HyperLink>
    <telerik:RadGrid ID="RadGrid1" runat="server" AllowSorting="True" AutoGenerateColumns="False"
        Style="z-index: 811; left: 10px; position: absolute; top: 360px; height: 130px;"
        GridLines="None" Width="500px" EnableAJAX="True" Skin="prompt">
        <ClientSettings>
            <Selecting AllowRowSelect="False" />
            <Scrolling AllowScroll="True" UseStaticHeaders="True" ScrollHeight="50%" />
        </ClientSettings>
        <MasterTableView Width="99%" GridLines="None" DataKeyNames="InsuranceID,PolicyType,Attachments"
            NoMasterRecordsText="No Insurance Items found.">
            <Columns>
                <telerik:GridHyperLinkColumn UniqueName="PolicyType" HeaderText="Type" DataTextField="PolicyType"
                    SortExpression="PolicyType">
                    <ItemStyle HorizontalAlign="Left" Width="75px" VerticalAlign="Top" />
                    <HeaderStyle HorizontalAlign="Left" Width="75px" />
                </telerik:GridHyperLinkColumn>
                <telerik:GridBoundColumn DataField="ExpirationDate" HeaderText="Exp" UniqueName="ExpirationDate"
                    DataFormatString="{0:MM/dd/yyyy}" SortExpression="ExpirationDate">
                    <ItemStyle Width="75px" HorizontalAlign="Left" VerticalAlign="Top" />
                    <HeaderStyle Width="75px" Height="20px" HorizontalAlign="Left" />
                </telerik:GridBoundColumn>
                <telerik:GridBoundColumn UniqueName="Notes" HeaderText="Notes" DataField="Notes">
                    <ItemStyle HorizontalAlign="Left" Width="125px" VerticalAlign="Top" />
                    <HeaderStyle HorizontalAlign="Left" Width="125px" />
                </telerik:GridBoundColumn>
                <telerik:GridHyperLinkColumn HeaderText="Att" UniqueName="ShowAttachments">
                    <ItemStyle Width="35px" HorizontalAlign="Center" VerticalAlign="Top" />
                    <HeaderStyle Width="35px" HorizontalAlign="Center" />
                </telerik:GridHyperLinkColumn>
            </Columns>
        </MasterTableView>
    </telerik:RadGrid>
    </form>
</body>
</html>
