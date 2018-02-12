<%@ Page Language="vb" %>

<%@ Register Assembly="Telerik.Web.UI" Namespace="Telerik.Web.UI" TagPrefix="telerik" %>
<%@ Import Namespace="Prompt" %>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">

<script runat="server">
   
    Private nKey As Integer = 0
         
    Private Sub Page_Load(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MyBase.Load
        
        If ProcLib.CheckExpiredSessionForPopup(Page) Then    'session died so close the page - this is to prevent orphaned popups
            ProcLib.CloseOnlyRAD(Page)
        End If
        
        'set help info - note: no need for help button as one on page top will suffice here
        Session("PageID") = "ObjectCodeEdit"
        
        lblMessage.Text = ""

        nKey = Request.QueryString("PrimaryKey")
  
        If IsPostBack Then   'only do the following on post back or pass back
            nKey = lblID.Text
        Else  'only do the following on first load
                
            Using db As New PromptDataHelper
                db.CallingPage = Page
                
                'load combo boxes
                
                Dim sql As String = "SELECT DISTINCT IsNull(BudgetGroup,'') AS BudgetGroup FROM ObjectCodes WHERE DistrictID = " & Session("DistrictID") & " ORDER BY BudgetGroup"
                Dim rs As DataTable = db.ExecuteDataTable(sql)
                For Each row As DataRow In rs.Rows()
                    rcbBudgetGroup.Items.Add(New Telerik.Web.UI.RadComboBoxItem(row("BudgetGroup"), row("BudgetGroup")))
                Next
                
                sql = "SELECT DISTINCT IsNull(ObjectCodeGroup,'') AS ObjectCodeGroup FROM ObjectCodes WHERE DistrictID = " & Session("DistrictID") & " ORDER BY ObjectCodeGroup"
                rs = db.ExecuteDataTable(sql)
                For Each row As DataRow In rs.Rows()
                    rcbObjectCodeGroup.Items.Add(New Telerik.Web.UI.RadComboBoxItem(row("ObjectCodeGroup"), row("ObjectCodeGroup")))
                Next

                If nKey > 0 Then    'load Existing record 
                                      
                    'get object code record for edit
                    sql = "SELECT * FROM ObjectCodes WHERE PrimaryKey = " & nKey
                    db.FillForm(Form1, sql)

                    Dim sCode As String = txtObjectCode.Text
                    'Checks to see if this code had been used in PROMPT records and sets flag accordingly
                    Dim cnt As Integer = 0
                    'Check Contracts
                    sql = "SELECT Count(ContractID) FROM Contracts WHERE ObjectCode = '" & sCode & "' AND DistrictID = " & Session("DistrictID")
                    cnt += db.ExecuteScalar(sql)
                    'Check Transactions
                    sql = "SELECT Count(TransactionID) FROM Transactions WHERE ObjectCode = '" & sCode & "' AND DistrictID = " & Session("DistrictID")
                    cnt += db.ExecuteScalar(sql)
                    'Check JCAF
                    sql = "SELECT Count(PrimaryKey) FROM BudgetObjectCodes WHERE ObjectCode = '" & sCode & "' AND DistrictID = " & Session("DistrictID")
                    cnt += db.ExecuteScalar(sql)
                    'Check Budget Estimates
                    sql = "Select Count(*) From BudgetObjectCodeEstimates Where ObjectCode = '" & sCode & "' and DistrictID = " & Session("DistrictID")
                    cnt += db.ExecuteScalar(sql)

                    If cnt > 0  Then
                        butDelete.Visible = False
                        txtObjectCode.Enabled = False
                        lblMessage.Text = "Note: This Object Code is being used in the JCAF or Contract records or in Budget Estimates and thus Object Code cannot be changed or deleted."
                        txtObjectCodeDescription.Focus()
                    Else
                        txtObjectCode.Focus()
                    End If
                   
                Else
                    'new record so hide delete button
                    butDelete.Visible = False
                    txtObjectCode.Focus()
                End If
                lblID.Text = nKey
               
            End Using
            'Store the old object code value in the view state for retrival in validation
            ViewState.Add("OldObjectCode", txtObjectCode.Text)   'save the original value to view state for later
        End If
    End Sub

    Private Sub butSave_Click(ByVal sender As System.Object, ByVal e As System.Web.UI.ImageClickEventArgs) Handles butSave.Click
        
        If Trim(txtObjectCode.Text) = "" Then
            lblMessage.Text = "Object Code cannot be blank."
            Exit Sub
        Else
            
            
            Using db As New PromptDataHelper
  
                Dim sql As String = ""

                If nKey = 0 Then      'new record
                    
                    'Check to see there are no duplicates
                    sql = "SELECT Count(ObjectCode) FROM ObjectCodes WHERE ObjectCode = '" & Trim(txtObjectCode.Text) & "' AND DistrictID = " & Session("DistrictID")
                    Dim isdup As Integer = db.ExecuteScalar(sql)

                    If isdup > 0 Then
                        lblMessage.Text = "Sorry, this Object Code already exists."
                        Exit Sub
                    
                    Else

                        sql = "INSERT INTO ObjectCodes "
                        sql &= "(DistrictID,LastUpdateBy,LastUpdateOn)"
                        sql &= "VALUES (" & Session("DistrictID") & ",'" & Session("UserName") & "','" & Now() & "')"
                        sql &= "SELECT CAST(SCOPE_IDENTITY() AS int) AS ID"

                        nKey = db.ExecuteScalar(sql)

                    End If
                End If

                'pass the form and sql to fill routine
                sql = "SELECT * FROM ObjectCodes WHERE PrimaryKey = " & nKey
                db.SaveForm(Form, sql)

                
                'Now update description in several files
                sql = "SELECT * FROM ObjectCodes WHERE PrimaryKey = " & nKey
                Dim tbl As DataTable = db.ExecuteDataTable(sql)
                Dim row As DataRow = tbl.Rows(0)
                Dim sDescr As String = Trim(ProcLib.CheckNullDBField(row("ObjectCodeDescription")))
                Dim sObjectCode As String = Trim(ProcLib.CheckNullDBField(row("ObjectCode")))
                Dim nDistrict As Integer = row("DistrictID")
                                
                sql = "UPDATE BudgetObjectCodes SET Description = '" & sObjectCode & " - " & sDescr & "' WHERE ObjectCode = '" & sObjectCode & "' AND DistrictID = " & nDistrict
                db.ExecuteNonQuery(sql)
                
                sql = "UPDATE ContractLineItems SET LineObjectCodeDescription = '" & sObjectCode & " - " & sDescr & "' WHERE ObjectCode = '" & sObjectCode & "' AND DistrictID = " & nDistrict
                db.ExecuteNonQuery(sql)

                sql = "UPDATE BudgetObjectCodeEstimates SET Description = '" & sDescr & "' WHERE ObjectCode = '" & sObjectCode & "' AND DistrictID = " & nDistrict
                db.ExecuteNonQuery(sql)

    

 
            End Using
        End If
        ProcLib.CloseAndRefreshRAD(Page)
    
    End Sub

    Private Sub butDelete_Click(ByVal sender As System.Object, ByVal e As System.Web.UI.ImageClickEventArgs) Handles butDelete.Click
        Using db As New PromptDataHelper
            
            Dim sql As String = "DELETE FROM ObjectCodes WHERE PrimaryKey = " & nKey
            db.ExecuteNonQuery(sql)

        End Using
        ProcLib.CloseAndRefreshRAD(Page)

    End Sub
 
        
 
</script>

<html>
<head>
    <title>Edit Object Code</title>
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
    <form id="Form1" method="post" runat="server">
    <telerik:RadScriptManager ID="RadScriptManager1" runat="server" />
    
    <asp:Label ID="lblID" Style="z-index: 100; left: 342px; position: absolute; top: 186px; height: 15px;"
        runat="server">999</asp:Label>
    <asp:Label ID="Label16" Style="z-index: 101; left: 309px; position: absolute; top: 185px; width: 14px;"
        runat="server">ID:</asp:Label>
    
    <asp:TextBox ID="txtObjectCode" Style="z-index: 102; left: 94px; position: absolute;
        top: 10px" runat="server" CssClass="EditDataDisplay" Width="96px" 
        ></asp:TextBox>
    &nbsp; &nbsp;
    <asp:TextBox ID="txtObjectCodeDescription" Style="z-index: 103; left: 93px; position: absolute;
        top: 45px" TabIndex="5" runat="server" CssClass="EditDataDisplay" 
        Width="304px"></asp:TextBox>
   
    <asp:Label ID="Label21" runat="server" Style="z-index: 105; left: 12px; position: absolute;
        top: 92px; height: 1px;">Budget Group:</asp:Label>
   
    <asp:Label ID="Label1" runat="server" Style="z-index: 105; left: 10px; position: absolute;
        top: 135px; height: 1px;">Object Code Group:</asp:Label>
    <%--<asp:Label ID="Label2" runat="server" Style="z-index: 106; left: 14px; position: absolute;
        top: 133px; height: 1px;">JCAF Assignment:</asp:Label>--%>
   
    <asp:Label ID="Label20" runat="server" Style="z-index: 107; left: 11px; position: absolute;
        top: 11px">Object Code:</asp:Label>
    
    <asp:ImageButton ID="butSave" Style="z-index: 108; left: 17px; position: absolute;
        top: 183px" TabIndex="150" runat="server" 
        ImageUrl="images/button_save.gif">
    </asp:ImageButton>
    <asp:ImageButton ID="butDelete" Style="z-index: 109; left: 196px; position: absolute;
        top: 181px" TabIndex="151" runat="server" 
        ImageUrl="images/button_delete.gif">
    </asp:ImageButton>
    &nbsp;&nbsp;
    <asp:Label ID="lblMessage" Style="z-index: 110; left: 13px; position: absolute;
        top: 213px; width: 426px;" runat="server" ForeColor="Red" Height="32px" 
        TabIndex="500">Note:</asp:Label>
    &nbsp;&nbsp;
    <telerik:RadWindowManager ID="RadPopups" runat="server">
    </telerik:RadWindowManager>
  
      <telerik:RadComboBox ID="rcbBudgetGroup" runat="server" Style="z-index: 1512; left: 136px;
        position: absolute; top: 95px" AllowCustomText="True" ShowMoreResultsBox="False"
        ItemRequestTimeout="500" MarkFirstMatch="True" TabIndex="10">
    </telerik:RadComboBox>
   <%-- <asp:ListBox Style="z-index: 113; left: 15px; position: absolute; top: 158px" ID="lstJCAFLines"
        runat="server" TabIndex="15" ToolTip="Assigns the Object Code to JCAF Budget Line - CTRL + Click to multi select."
        Width="402px" SelectionMode="Multiple"></asp:ListBox>
    <p>--%>
    <asp:Label ID="Label4" runat="server" Style="z-index: 104; left: 16px; position: absolute;
        top: 46px; height: 7px;">Description:</asp:Label>
    
    <telerik:RadComboBox ID="rcbObjectCodeGroup" runat="server" Style="z-index: 512;
        left: 134px; position: absolute; top: 134px" AllowCustomText="True"
        ShowMoreResultsBox="False" ItemRequestTimeout="500" MarkFirstMatch="True" 
        TabIndex="10">
    </telerik:RadComboBox>
    </form>
</body>
</html>
