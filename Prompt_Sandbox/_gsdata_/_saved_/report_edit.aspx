<%@ Page Language="vb" %>
<%@ Register Assembly="Telerik.Web.UI" Namespace="Telerik.Web.UI" TagPrefix="telerik" %>
<%@ Import Namespace="Prompt" %>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">

<script runat="server">
    Public nReportID As Integer
    Private Sub Page_Load(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MyBase.Load

        ProcLib.CheckSession(Page)

        ProcLib.LoadPopupJscript(Page)

        'set up help button
        Session("PageID") = "ReportEdit"
        butHelp.Attributes.Add("onclick", "openPopup('help_view.aspx','pophelp',550,450,'yes');")
        butHelp.NavigateUrl = "#"


        nReportID = Request.QueryString("ReportID")

        If IsPostBack Then   'only do the following post back
            nReportID = lblReportID.Text
        Else  'only do the following on first load

            Using rs As New promptReport
                If Request.QueryString("new") = "y" Then    'add the new record
                    With rs
                        .CallingPage = Page
                        .GetNewReport()
                    End With
                    butDelete.Visible = False
                
                Else
                    With rs
                        .CallingPage = Page
                        .GetExistingReport(nReportID)
                    End With

                End If
            End Using
  
            
            Dim strDistrictList As String = ""
            Dim strUserList As String = ""
            Using rsLists As New PromptDataHelper
                Dim tbl As DataTable = rsLists.ExecuteDataTable("SELECT DistrictViewList,UserViewList FROM Reports WHERE ReportID = " & nReportID)
                If tbl.Rows.Count > 0 Then
                    strDistrictList = ProcLib.CheckNullDBField(tbl.Rows(0)("DistrictViewList"))
                    strUserList = ProcLib.CheckNullDBField(tbl.Rows(0)("UserViewList"))
                End If
   
                'populate the district access
                Dim sql As String = "SELECT Districts.DistrictID, CLients.ClientName + ' - ' + Districts.Name AS District "
                sql = sql & "FROM Districts INNER JOIN Clients ON Districts.ClientID = Clients.ClientID ORDER BY ClientName, Name "
                rsLists.FillReader(sql)
                Dim strDistrict As String
                Dim strDistrictID As String
                Dim li As New ListItem("***  ALL  ***", ";0;")
                If InStr(strDistrictList, ";0;") > 0 Then
                    li.Selected = True
                End If
                lstAssignedDistricts.Items.Add(li)
                While rsLists.Reader.Read()
                    strDistrict = rsLists.Reader("District")
                    strDistrictID = ";" & CStr(rsLists.Reader("DistrictID")) & ";"  'need delim char due to number value
                    'add the district
                    li = New ListItem(strDistrict, rsLists.Reader("DistrictID"))
                    'Check to see if need to select
                    If InStr(strDistrictList, strDistrictID) > 0 Then
                        li.Selected = True
                    End If
                    lstAssignedDistricts.Items.Add(li)
                End While
                rsLists.Reader.Close()
            
                sql = "SELECT Users.UserID, Users.UserName + '  (' + CLients.ClientName + ')' AS UserName FROM Users INNER JOIN Clients ON Users.ClientID = Clients.ClientID ORDER BY ClientName, UserName "
                rsLists.FillReader(sql)
                Dim strUser As String
                Dim strUserID As String
                li = New ListItem("***  ALL  ***", ";0;")
                If InStr(strUserList, ";0;") > 0 Then
                    li.Selected = True
                End If
                lstAssignedUsers.Items.Add(li)
                While rsLists.Reader.Read()
                    strUser = rsLists.Reader("UserName")
                    strUserID = ";" & CStr(rsLists.Reader("UserID")) & ";"  'need delim char due to number value
                    'add the district
                    li = New ListItem(strUser, strUserID)
                    'Check to see if need to select
                    If InStr(strUserList, strUserID) > 0 Then
                        li.Selected = True
                    End If
                    lstAssignedUsers.Items.Add(li)
                End While
                rsLists.Reader.Close()
                
            End Using
        End If

        txtReportTitle.Focus()
    End Sub

    Private Sub butSave_Click(ByVal sender As System.Object, ByVal e As System.Web.UI.ImageClickEventArgs) Handles butSave.Click
        
        
        Using rs As New promptReport
            With rs
                .CallingPage = Page
                .SaveReport(nReportID)
            End With
        End Using
        
        Session("RtnFromEdit") = True
        ProcLib.CloseAndRefreshNoPrompt(Page)

    End Sub

    Private Sub butDelete_Click(ByVal sender As System.Object, ByVal e As System.Web.UI.ImageClickEventArgs) Handles butDelete.Click

        Response.Redirect("delete_record.aspx?RecordType=Report&ID=" & nReportID)
    End Sub

</script>

<html>
<head>
    <title>Report Edit</title>
      <link rel="stylesheet" type="text/css" href="styles.css" />
</head>
<body>
    <form id="Form1" method="post" runat="server">
        <telerik:RadScriptManager ID="RadScriptManager1" runat="server" />
        
    <asp:Label ID="Label1" Style="z-index: 100; left: 24px; position: absolute; top: 11px; width: 12px; right: 1569px;"
        runat="server">ID:</asp:Label>
    <asp:CheckBox ID="chkFilterContractor" Style="z-index: 102; left: 14px; position: absolute;
        top: 258px" TabIndex="11" runat="server" Text="Prompt for Contractor?"></asp:CheckBox>
    <asp:ImageButton ID="butDelete" Style="z-index: 103; left: 311px; position: absolute;
        top: 567px" TabIndex="41" runat="server" 
        ImageUrl="images/button_delete.gif">
    </asp:ImageButton>
    <asp:ImageButton ID="butSave" Style="z-index: 104; left: 29px; position: absolute;
        top: 567px" TabIndex="40" runat="server" ImageUrl="images/button_save.gif"></asp:ImageButton>

               

    <asp:Label ID="Label18" runat="server" Style="z-index: 106; left: 20px; position: absolute;
        top: 324px">Assigned User List:</asp:Label>
    <asp:Label ID="Label19" runat="server" Style="z-index: 107; left: 318px; position: absolute;
        top: 329px">Assigned District List:</asp:Label>
    <asp:Label ID="Label9" Style="z-index: 113; left: 267px; position: absolute; top: 178px"
        runat="server">Category for grouping on the list page.</asp:Label>
    <asp:TextBox ID="txtNKeyFieldName" Style="z-index: 114; left: 444px; position: absolute;
        top: 293px" runat="server" Width="112px" TabIndex="9" 
        CssClass="EditDataDisplay"></asp:TextBox>
    <asp:TextBox ID="txtDescription" Style="z-index: 117; left: 81px; position: absolute;
        top: 110px; height: 45px; width: 409px;" runat="server" TextMode="MultiLine" TabIndex="2"
        CssClass="EditDataDisplay"></asp:TextBox>
    <asp:TextBox ID="txtReportFileName" Style="z-index: 118; left: 67px; position: absolute;
        top: 72px" runat="server" Width="312px" TabIndex="1" 
            CssClass="EditDataDisplay"></asp:TextBox>
    <asp:Label ID="lblReportID" Style="z-index: 119; left: 58px; position: absolute;
        top: 11px; height: 4px;" runat="server">9999</asp:Label>
    <asp:CheckBox ID="chkPassDateRange" Style="z-index: 121; left: 360px; position: absolute;
        top: 219px" runat="server" Text="Prompt for DateRange?" TabIndex="11"></asp:CheckBox>
    <asp:CheckBox ID="chkPassNKey" Style="z-index: 122; left: 15px; position: absolute;
        top: 292px" runat="server" Text="Pass specific key or project to report?" 
        TabIndex="8"></asp:CheckBox>
    <asp:CheckBox ID="chkUsesParms" Style="z-index: 123; left: 154px; position: absolute;
        top: 218px" runat="server" Text="Prompt for Parameters?" TabIndex="7"></asp:CheckBox>
    <asp:Label ID="Label7" Style="z-index: 124; left: 310px; position: absolute; top: 297px"
        runat="server">NKey Field Name:</asp:Label>
    <asp:Label ID="Label5" Style="z-index: 126; left: 14px; position: absolute; top: 169px"
        runat="server">Type:</asp:Label>
    <asp:Label ID="Label4" Style="z-index: 127; left: 8px; position: absolute; top: 111px"
        runat="server">Description:</asp:Label>
    <asp:Label ID="Label3" Style="z-index: 128; left: 6px; position: absolute; top: 74px"
        runat="server">FileName:</asp:Label>
    <asp:Label ID="Label2" Style="z-index: 129; left: 21px; position: absolute; top: 38px"
        runat="server">Title:</asp:Label>
    <asp:TextBox ID="txtReportTitle" Style="z-index: 130; left: 66px; position: absolute;
        top: 36px" runat="server" Width="248px" CssClass="EditDataDisplay"></asp:TextBox>
    <asp:TextBox ID="txtReportNumber" runat="server" CssClass="EditDataDisplay" MaxLength="5"
        Style="z-index: 139; left: 432px; position: absolute; top: 35px" Width="54px"></asp:TextBox>
    <asp:CheckBox ID="chkPublish" Style="z-index: 132; left: 16px; position: absolute;
        top: 216px" runat="server" Text="Show in List?" TabIndex="6"></asp:CheckBox>
    <telerik:RadComboBox ID="lstReportType" Style="z-index: 2233; left: 69px; position: absolute;
        top: 174px" runat="server" TabIndex="3" CssClass="EditDataDisplay" 
            AllowCustomText="True" Sort="Ascending">
    </telerik:RadComboBox>
    <asp:ListBox ID="lstAssignedUsers" runat="server" SelectionMode="Multiple" Style="z-index: 134;
        left: 30px; position: absolute; top: 360px; height: 179px;" Width="250px"></asp:ListBox>
    <asp:ListBox ID="lstAssignedDistricts" runat="server" SelectionMode="Multiple" Style="z-index: 135;
        left: 308px; position: absolute; top: 358px; height: 176px;" Width="281px"></asp:ListBox>
    <asp:Label ID="Label20" runat="server" Style="z-index: 136; left: 351px; position: absolute;
        top: 39px">Number:</asp:Label>
    <asp:CheckBox ID="chkIsSSRS" Style="z-index: 102; left: 249px; position: absolute;
        top: 252px" TabIndex="11" runat="server" Text="SSRS Report?"></asp:CheckBox>
        
         <asp:HyperLink ID="butHelp" runat="server" ImageUrl="images/button_help.gif" Style="z-index: 106; left: 474px; position: absolute;
        top: 14px"></asp:HyperLink>
        
    </form>
</body>
</html>
