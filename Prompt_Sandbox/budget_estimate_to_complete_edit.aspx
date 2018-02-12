<%@ Page Language="vb" %>

<%@ Register Assembly="Telerik.Web.UI" Namespace="Telerik.Web.UI" TagPrefix="telerik" %>
<%@ Import Namespace="Prompt" %>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">

<script runat="server">
   
    Private nKey As Integer = 0
    Private nProjectID As Integer = 0
    Private bIsSnapshot As Boolean = False
    Private BOCEtable As String = ""    'which of the two tables to use: BudgetObjectCodeEstimates, or BudgetObjectCodeEstimates_Snapshots
  
    Private Sub Page_Load(ByVal sender As System.Object, ByVal e As System.EventArgs)
  
        If ProcLib.CheckExpiredSessionForPopup(Page) Then    'session died so close the page - this is to prevent orphaned popups
            ProcLib.CloseOnlyRAD(Page)
        End If
        'set help info - note: no need for help button as one on page top will suffice here
        Session("PageID") = "BudgetObjectCodeEstimateEdit"
        
        lblMessage.Text = ""
        
        nKey = Request.QueryString("PrimaryKey")
        nProjectID = Request.QueryString("ProjectID")
        bIsSnapshot = IIf(Request.QueryString("Snapshot") = "Y", True, False)
        BOCEtable = IIf(bIsSnapshot, "BudgetObjectCodeEstimates_Snapshots", "BudgetObjectCodeEstimates")
  
        If IsPostBack Then   'only do the following on post back or pass back
            nKey = lblID.Text
        Else  'only do the following on first load
            
            'Fill the drop down box
           
            Using db As New PromptDataHelper
                'Fill the object code list box
                rcbObjectCode.Items.Clear()
                Dim rs As DataTable = db.ExecuteDataTable("SELECT DISTINCT ObjectCode, ObjectCodeDescription AS Description FROM ObjectCodes WHERE DistrictID = " & Session("DistrictID") & " ORDER BY ObjectCode")
                For Each row As DataRow In rs.Rows()
                    Dim item As New RadComboBoxItem
                    item.Value = row("ObjectCode")
                    item.Text = row("ObjectCode") & " :: " & row("Description")
                    rcbObjectCode.Items.Add(item)
                Next
            End Using
            Using db As New PromptDataHelper
                If nKey > 0 Then
                    Dim row As DataRow = db.GetDataRow("SELECT * FROM " & BOCEtable & " WHERE PrimaryKey = " & nKey)
                    Dim form As Control = Page.FindControl("Form1")  ' get ref to calling form
                    db.FillForm(form, row)
                Else
                    butDelete.Visible = False                   'new record so hide delete button
                End If
                lblID.Text = nKey
            End Using
        End If
    End Sub
 
    Private Sub butSave_Click(ByVal sender As System.Object, ByVal e As System.Web.UI.ImageClickEventArgs) Handles butSave.Click
        Using db As New PromptDataHelper
            
            Dim sql As String = ""
            sql = "SELECT COUNT(PrimaryKey) AS Tot FROM " & BOCEtable & "  "
            sql &= "WHERE ProjectID = " & nProjectID & " AND ObjectCode = '" & rcbObjectCode.SelectedValue & "' AND PrimaryKey <> " & nKey

            'check to see if dup is being added
            Dim nResult As Integer = db.ExecuteScalar(sql)
            If nResult > 0 Then
                lblMessage.Text = "Sorry, that Obect Code has already been entered. Please add to existing entry or select different OC."

            Else
                If nKey = 0 Then      'new record
                    sql = "INSERT INTO " & BOCEtable & " "
                    sql &= "(DistrictID,CollegeID,ProjectID, LastUpdateBy, LastUpdateOn)"
                    sql &= "VALUES (" & Page.Session("DistrictID") & "," & Session("CollegeID") & "," & nProjectID & ",'" & db.CurrentUserName & "','" & Now() & "')"
                    sql &= "SELECT CAST(SCOPE_IDENTITY() AS int) AS ID"
                    nKey = db.ExecuteScalar(sql)
                End If

                sql = "SELECT * FROM " & BOCEtable & " WHERE PrimaryKey = " & nKey
                Dim form As Control = Page.FindControl("Form1")
                db.SaveForm(form, sql)

                'Update the ObjectCode description - because the description is not part of the value field in the cbo box, won't write in saveform
                Dim lst As Telerik.Web.UI.RadComboBox = form.FindControl("rcbObjectCode")   'get refernce to the cbo
                Dim sDescription As String = lst.SelectedItem.Text                          'get the item
                sDescription = Trim(Mid(sDescription, InStr(sDescription, "::") + 2))   'strip out the object code part
                sql = "UPDATE " & BOCEtable & " SET Description = '" & sDescription & "' WHERE PrimaryKey = " & nKey
                db.ExecuteNonQuery(sql)
                
                       
                Session("RtnFromEdit") = True
                ProcLib.CloseAndRefreshRAD(Page)
            End If
            
  
        End Using
 
    End Sub
 
    Private Sub butDelete_Click(ByVal sender As System.Object, ByVal e As System.Web.UI.ImageClickEventArgs) Handles butDelete.Click
        Using db As New PromptDataHelper
            db.ExecuteNonQuery("DELETE FROM " & BOCEtable & " WHERE PrimaryKey = " & nKey)
        End Using
        Session("RtnFromEdit") = True
        ProcLib.CloseAndRefreshRAD(Page)
    End Sub
  
  
</script>

<html>
<head>
    <title>Edit Budget Estimate</title>
    <link href="Styles.css" type="text/css" rel="stylesheet" />

    <script type="text/javascript">

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
    <form id="Form1" method="post" runat="server" onsubmit="SubmitRecalcTotals()">
    <telerik:RadScriptManager ID="RadScriptManager1" runat="server" />
    <asp:Label ID="lblID" Style="z-index: 100; left: 337px; position: absolute; top: 197px; height: 1px;"
        runat="server">999</asp:Label>
    <asp:Label ID="Label20" runat="server" Style="z-index: 107; left: 15px; position: absolute;
        top: 13px">Object Code:</asp:Label>
    <asp:ImageButton ID="butSave" Style="z-index: 108; left: 11px; position: absolute;
        top: 190px" TabIndex="150" runat="server" 
        ImageUrl="images/button_save.gif">
    </asp:ImageButton>
    <asp:ImageButton ID="butDelete" Style="z-index: 109; left: 192px; position: absolute;
        top: 191px" TabIndex="151" runat="server" 
        ImageUrl="images/button_delete.gif">
    </asp:ImageButton>
    &nbsp; &nbsp;&nbsp;&nbsp;
    <asp:Label ID="Label1" runat="server" Style="z-index: 108; left: 8px; position: absolute;
        top: 47px">Pending Expenses:</asp:Label>
    <asp:Label ID="Label21" runat="server" Style="z-index: 108; left: 6px; position: absolute;
        top: 84px">Approximate Expenses:</asp:Label>
    <asp:Label ID="Label2" runat="server" Style="z-index: 108; left: 9px; position: absolute;
        top: 111px">Notes:</asp:Label>
    <telerik:RadNumericTextBox ID="txtPendingExpenses" runat="server" Style="z-index: 108;
        left: 136px; position: absolute; top: 47px">
    </telerik:RadNumericTextBox>
    <telerik:RadNumericTextBox ID="txtEstimateToComplete" runat="server" Style="z-index: 108;
        left: 136px; position: absolute; top: 84px">
    </telerik:RadNumericTextBox>
    <telerik:RadComboBox ID="rcbObjectCode" runat="server" Style="z-index: 7112; left: 140px;
        position: absolute; top: 11px" DropDownWidth="275" 
        Width="250" MaxHeight="200px" Skin="Windows7">
    </telerik:RadComboBox>

        <asp:Label ID="Label22" Style="z-index: 101; left: 313px; position: absolute; top: 196px;
            width: 8px; height: 14px;"  runat="server">ID:</asp:Label>

        <asp:Label ID="lblMessage" Style="z-index: 101; left: 12px; position: absolute; top: 217px;
            width: 367px; height: 31px;"  runat="server" ForeColor="Red"></asp:Label>

    <telerik:RadWindowManager ID="RadPopups" runat="server" />

      <asp:TextBox ID="txtNotes" runat="server"  Style="z-index: 101; left: 14px; position: absolute; top: 133px;
            width: 371px; height: 48px;" TextMode="MultiLine" ></asp:TextBox>

    </form>
    </body>
</html>
