<%@ Page Language="vb" ValidateRequest="false" %>

<%@ Register Assembly="Telerik.Web.UI" Namespace="Telerik.Web.UI" TagPrefix="telerik" %>
<%@ Import Namespace="Prompt" %>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">

<script runat="server">
    
    Private nRecID As Integer = 0
    Private sRecType As String = ""
 
    Private Sub Page_Load(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MyBase.Load

        ProcLib.CheckSession(Page)
        ProcLib.LoadPopupJscript(Page)

        'set up help button
        Session("PageID") = "WorkfowHistoryNoteAdd"
        
        nRecID = Request.QueryString("recid")
        sRecType = Request.QueryString("rectype")

        txtDescription.Focus()

    End Sub

    Private Sub butSave_Click(ByVal sender As System.Object, ByVal e As System.Web.UI.ImageClickEventArgs) Handles butSave.Click

        'fix the apostrophe problem
        txtDescription.Text = Replace(txtDescription.Text, "'", "''")

        If Trim(txtDescription.Text) <> "" Then
            Using db As New PromptDataHelper
                  
                If sRecType = "Transaction" Then

                    'Get all the needed info for record
                    Dim sql As String = "SELECT Transactions.ContractID, Transactions.Status, Transactions.TransactionID, Transactions.ProjectID, "
                    sql &= "Transactions.DistrictID, Contracts.CollegeID FROM Transactions INNER JOIN "
                    sql &= "Contracts ON Transactions.ContractID = Contracts.ContractID WHERE TransactionID = " & nRecID
                    Dim tbl As DataTable = db.ExecuteDataTable(sql)
                    Dim row As DataRow = tbl.Rows(0)

                    'Insert workflow record
                    sql = "INSERT INTO WorkflowLog (DistrictID,CollegeID,ProjectID,ContractID,TransactionID,WorkflowOwner,WorkflowRoleID,WorkflowAction,Notes,CreatedOn,CreatedBy) "
                    sql &= " VALUES(" & row("DistrictID") & ","
                    sql &= row("CollegeID") & ","
                    sql &= row("ProjectID") & ","
                    sql &= row("ContractID") & ","
                    sql &= row("TransactionID") & ","
                    sql &= "'" & HttpContext.Current.Session("WorkflowRole") & "',"
                    sql &= HttpContext.Current.Session("WorkflowRoleID") & ","
                    sql &= "'Note Added',"
                    sql &= "'" & txtDescription.Text & "',"
                    sql &= "'" & Now() & "',"
                    sql &= "'" & HttpContext.Current.Session("UserName") & "')"
                    
                    tbl.Dispose()
                    db.ExecuteNonQuery(sql)
                    
                Else      'PAD
                    
                    'get current info
                    Dim sql As String = "SELECT ProjectID,DistrictID FROM ProjectApprovalDocuments WHERE PADID = " & nRecID
                    Dim tbl As DataTable = db.ExecuteDataTable(sql)
                    Dim row As DataRow = tbl.Rows(0)

                    'Insert note into workflow record
                    sql = "INSERT INTO WorkflowLog (DistrictID,ProjectID,PADID,WorkflowOwner,WorkflowRoleID,WorkflowAction,Notes,CreatedOn,CreatedBy) "
                    sql &= " VALUES("
                    sql &= row("DistrictID") & ","
                    sql &= row("ProjectID") & ","
                    sql &= nRecID & ","
                    sql &= "'" & HttpContext.Current.Session("WorkflowRole") & "',"
                    sql &= HttpContext.Current.Session("WorkflowRoleID") & ","
                    sql &= "'Note Added',"
                    sql &= "'" & txtDescription.Text & "',"
                    sql &= "'" & Now() & "',"
                    sql &= "'" & HttpContext.Current.Session("UserName") & "')"
                    
                    tbl.Dispose()
                    db.ExecuteNonQuery(sql)
                End If
 
  
            End Using
        End If

        ProcLib.CloseAndRefreshRAD(Page)
 
       
    End Sub
    
  
</script>

<html>
<head>
    <title>Add Workflow Note</title>
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
    <asp:TextBox ID="txtDescription" Style="z-index: 102; left: 5px; position: absolute;
        top: 7px; height: 153px; width: 460px;" TabIndex="1" runat="server" CssClass="EditDataDisplay"
        TextMode="MultiLine"></asp:TextBox>
    <asp:ImageButton ID="butSave" Style="z-index: 104; left: 8px; position: absolute;
        top: 176px" TabIndex="5" runat="server" ImageUrl="images/button_save.gif"></asp:ImageButton>
    </form>
</body>
</html>
