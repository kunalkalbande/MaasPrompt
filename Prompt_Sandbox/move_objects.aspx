<%@ Page Language="VB" %>
<%@ Register Assembly="Telerik.Web.UI" Namespace="Telerik.Web.UI" TagPrefix="telerik" %>
<%@ Import Namespace="Prompt" %>
<%@ Import Namespace="System.IO" %>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">

<script runat="server">
    Dim db As New PromptDataHelper
    Dim strSQL As String
    Dim DistrictID As Integer
    Dim dtListTrans As DataTable

    Private Sub Page_Load(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MyBase.Load
        
        If Not IsPostBack Then
            DistrictID = Session("DistrictID")
            strSQL = "Select Name From Districts Where DistrictID = " & DistrictID
            lblDistrictName.Text = db.ExecuteScalar(strSQL)
        
            'Source College
            strSQL = "SELECT CollegeID As Val, College as Lbl From Colleges Where DistrictID = " & DistrictID
            db.FillDropDown(strSQL, ddlCollegeSrc, True, False, False)
        
            'Destination College
            strSQL = "SELECT CollegeID As Val, College as Lbl From Colleges Where DistrictID = " & DistrictID
            db.FillDropDown(strSQL, ddlCollegeDst, True, False, False)
            
            ddlCollegeSrc.AutoPostBack = True
            ddlProjectSrc.AutoPostBack = True
            ddlContractSrc.AutoPostBack = True
            ddlCollegeDst.AutoPostBack = True
            ddlProjectDst.AutoPostBack = True
            
            RadGrid1.ClientSettings.Selecting.AllowRowSelect = True
            RadGrid1.MasterTableView.NoDetailRecordsText = "No transactions under this contract"
            
            RadioButtonList1.SelectedValue = "Contract"       ' default: contract
            butMove.Text = "Move Contract"

        End If

    End Sub

    Protected Sub ddlCollegeSrc_SelectedIndexChanged(ByVal sender As Object, ByVal e As System.EventArgs)
        strSQL = "Select ProjectNumber + Coalesce(ProjectSubNumber,'') + '-' + ProjectName as Lbl, ProjectID as Val From Projects " _
        & " Where DistrictID = " & Session("DistrictID") & " and CollegeID = " & ddlCollegeSrc.SelectedItem.Value _
        & " Order By ProjectNumber + Coalesce(ProjectSubNumber,'') "
        ddlProjectSrc.Items.Clear()
        db.FillDropDown(strSQL, ddlProjectSrc, False, False, False)
    End Sub
    
    Protected Sub ddlProjectSrc_SelectedIndexChanged(ByVal sender As Object, ByVal e As System.EventArgs)
        strSQL = "Select CT.Name + '-' + CO.Description as Lbl, CO.ContractID as Val From Contracts CO " _
        & " join Contractors CT on CO.ContractorID = CT.ContractorID join Projects P on CO.ProjectID = P.ProjectID " _
        & " Where CO.DistrictID = " & Session("DistrictID") & " and CO.ProjectID = " & ddlProjectSrc.SelectedItem.Value _
        & " Order By CT.Name + '-' + CO.Description"
        ddlContractSrc.Items.Clear()
        db.FillDropDown(strSQL, ddlContractSrc, False, False, False)
    End Sub
    
    Protected Sub ddlContractSrc_SelectedIndexChanged(ByVal sender As Object, ByVal e As System.EventArgs)
        'show transactions in the grid
        strSQL = "Select TransactionID, InvoiceDate, TotalAmount From Transactions T join Projects P on T.ProjectID = P.ProjectID " _
        & "	join Contracts CO on T.ContractID = CO.ContractID " _
        & " Where CO.ContractID = " & ddlContractSrc.SelectedItem.Value & " Order By T.InvoiceDate"
        dtListTrans = db.ExecuteDataTable(strSQL)
        RadGrid1.Rebind()
    End Sub
    
    Protected Sub ddlCollegeDst_SelectedIndexChanged(ByVal sender As Object, ByVal e As System.EventArgs)
        strSQL = "Select ProjectNumber + Coalesce(ProjectSubNumber,'') + '-' + ProjectName as Lbl, ProjectID as Val From Projects " _
        & " Where DistrictID = " & Session("DistrictID") & " and CollegeID = " & ddlCollegeDst.SelectedItem.Value _
        & " Order By ProjectNumber + Coalesce(ProjectSubNumber,'') "
        ddlProjectDst.Items.Clear()
        db.FillDropDown(strSQL, ddlProjectDst, False, False, False)
    End Sub
    
    Protected Sub ddlProjectDst_SelectedIndexChanged(ByVal sender As Object, ByVal e As System.EventArgs)
        strSQL = "Select CT.Name + '-' + CO.Description as Lbl, CO.ContractID as Val From Contracts CO " _
        & " join Contractors CT on CO.ContractorID = CT.ContractorID join Projects P on CO.ProjectID = P.ProjectID " _
        & " Where CO.DistrictID = " & Session("DistrictID") & " and CO.ProjectID = " & ddlProjectDst.SelectedItem.Value _
        & " Order By CT.Name + '-' + CO.Description"
        ddlContractDst.Items.Clear()
        db.FillDropDown(strSQL, ddlContractDst, False, False, False)
    End Sub

    Protected Sub ddlContractDst_SelectedIndexChanged(ByVal sender As Object, ByVal e As System.EventArgs)

    End Sub
    
    Protected Sub RadioButtonList1_SelectedIndexChanged(ByVal sender As Object, ByVal e As System.EventArgs)
        Select Case RadioButtonList1.SelectedValue
            Case "Transaction"
                RadGrid1.Visible = True
                butMove.Text = "Move Transaction(s)"
                ddlContractDst.Visible = True
            Case "Contract"
                RadGrid1.Visible = False
                butMove.Text = "Move Contract"
                ddlContractDst.Visible = False
        End Select
    End Sub

    
    Dim OrigCollegeID As Integer
    Dim OrigProjectID As Integer
    Dim OrigContractID As Integer
    Dim NewCollegeID As Integer
    Dim NewProjectID As Integer
    Dim NewContractID As Integer
    Dim OrigTransactionID As Integer
    Dim retCode As Integer
   
    Protected Sub butMove_Click(ByVal sender As Object, ByVal e As System.EventArgs)
        
        If RadioButtonList1.SelectedValue = "Transaction" Then
            lblMessage.Text = "Sorry - Moving transactions not supported at this time"
            Exit Sub
        End If
        
        'ensure that all needed fields have been properly selected
        Try
            OrigCollegeID = ddlCollegeSrc.SelectedValue
            OrigProjectID = ddlProjectSrc.SelectedValue
            OrigContractID = ddlContractSrc.SelectedValue
            NewCollegeID = ddlCollegeDst.SelectedValue
            NewProjectID = ddlProjectDst.SelectedValue
        Catch ex As Exception
            lblMessage.Text = "Error: Please select from the DropdownLists"
            Exit Sub
        End Try
        lblMessage.Text = ""
        
        Select Case RadioButtonList1.SelectedValue
            Case "Transaction"
                RadGrid1.Visible = True
                MoveTransactions()
            Case "Contract"
                RadGrid1.Visible = False
                MoveContract()
            Case Else
                lblMessage.Text = "Unexpected Error: neither Contract or Transaction radio button chosen"
        End Select
    End Sub
    
    Sub MoveContract()
        
        'perform a series of checks first
        If Not (AnalyzeSourceToTargetMove(OrigContractID, NewProjectID)) Then
            lblMessage.Text &= "<br/>Target project does not have enough $ in JCAF cell / object code combination"
            Exit Sub
        End If
        
        If cbxAnalyzeOnly.Checked = True Then
            Exit Sub
        End If
        
        'check if this contract has any transactions that are STILL currently in the workflow; if so, do not proceed!
        strSQL = "Select count(T.TransactionID) From Transactions T join qry_GetWorkflowTransactions as GWT on T.TransactionID = GWT.TransactionID " _
            & " Where GWT.LastWorkflowAction <> 'Paid by FRS' and T.ContractID = " & OrigContractID
        If db.ExecuteScalar(strSQL) > 0 Then
            lblMessage.Text &= "Error: this contract has transactions that are STILL in the midst of workflow (i.e. have not yet completed workflow). Thus this contract cannot be moved. <br>"
            Exit Sub
        End If

        'update Contracts table (update ProjectID, CollegeID)
        strSQL = "Update Contracts Set ProjectID = " & NewProjectID & ", CollegeID = " & NewCollegeID & ", LastUpdateOn = getdate(), LastUpdateBy = 'MoveContract' Where ContractID = " & OrigContractID
        retCode = db.ExecuteNonQueryWithReturn(strSQL)
        If retCode <> 1 Then
            lblMessage.Text &= "Error updating Contracts table <br>"
            Exit Sub
        End If
        
        'update ContractLineItems table (update CollegeID, ProjectID)
        strSQL = "Update ContractLineItems Set ProjectID = " & NewProjectID & ", CollegeID = " & NewCollegeID & ", LastUpdateOn = getdate(), LastUpdateBy = 'MoveContract' Where ContractID = " & OrigContractID
        retCode = db.ExecuteNonQueryWithReturn(strSQL)
        lblMessage.Text &= retCode & " ContractLineItems table rows updated <br>"

        'update ContractDetail table (update ProjectID)
        strSQL = "Update ContractDetail Set ProjectID = " & NewProjectID & ", LastUpdateOn = getdate(), LastUpdateBy = 'MoveContract' Where ContractID = " & OrigContractID
        retCode = db.ExecuteNonQueryWithReturn(strSQL)
        lblMessage.Text &= retCode & " ContractDetail table rows updated <br>"
        
        'update Transaction table (update ProjectID)
        strSQL = "Update Transactions Set ProjectID = " & NewProjectID & ", LastUpdateOn = getdate(), LastUpdateBy = 'MoveContract' Where ContractID = " & OrigContractID
        retCode = db.ExecuteNonQueryWithReturn(strSQL)
        lblMessage.Text &= retCode & " Transactions table rows updated <br>"

        'update TransactionDetail table (update ProjectID)
        strSQL = "Update TransactionDetail Set ProjectID = " & NewProjectID & ", LastUpdateOn = getdate(), LastUpdateBy = 'MoveContract' Where ContractID = " & OrigContractID
        retCode = db.ExecuteNonQueryWithReturn(strSQL)
        lblMessage.Text &= retCode & " TransactionDetail table rows updated <br>"

        'Update Attachments records - must update EACH record with new CollegeID/ProjectID, AND with new FilePath
        Dim sFullPath As String, iAtt As Integer
        Dim sOldString As String = "CollegeID_" & OrigCollegeID & "/ProjectID_" & OrigProjectID
        Dim sNewString As String = "CollegeID_" & NewCollegeID & "/ProjectID_" & NewProjectID
        Using rs As New PromptDataHelper
            Dim sql As String = "Select AttachmentID, FilePath From Attachments Where ContractID = " & OrigContractID
            db.FillReader(sql)
            While db.Reader.Read
                sFullPath = db.Reader("FilePath")
                iAtt = db.Reader("AttachmentID")
                sFullPath = sFullPath.Replace(sOldString, sNewString)
                sql = "Update Attachments Set CollegeID = " & NewCollegeID & ", ProjectID = " & NewProjectID & ", FilePath = '" & sFullPath & "'" & " Where AttachmentID = " & iAtt
                rs.ExecuteNonQuery(sql)
            End While
            db.Reader.Close()
        End Using
        
        'Move the actual folder/contents to the new location
        sOldString = ProcLib.GetCurrentAttachmentPath() & "DistrictID_" & Session("DistrictID") & "/CollegeID_" & OrigCollegeID & "/ProjectID_" & OrigProjectID & "/ContractID_" & OrigContractID
        sNewString = ProcLib.GetCurrentAttachmentPath() & "DistrictID_" & Session("DistrictID") & "/CollegeID_" & NewCollegeID & "/ProjectID_" & NewProjectID & "/ContractID_" & OrigContractID
       
        System.Diagnostics.Debug.WriteLine("sOldString: " & sOldString)
        System.Diagnostics.Debug.WriteLine("sNewString: " & sNewString)
        
        If Not Directory.Exists(sNewString) Then
            Directory.CreateDirectory(sNewString)
        End If

        Try
            CopyDirectory(sOldString, sNewString)
            lblMessage.Text &= "Directory Contents Copied; <br>"
        Catch ex As Exception
            lblMessage.Text &= "Cannot COPY directory: <br>     " & sOldString & "<br>to: <br>     " & sNewString
            Exit Sub
        End Try
        Try
            Directory.Delete(sOldString, True)
            lblMessage.Text &= "Source Directory Deleted; <br>"
        Catch ex As Exception
            lblMessage.Text &= "Cannot delete Source Directory: <br>     " & sOldString & "<br>     " & ex.Message
            Exit Sub
        End Try
        
        'update AttachmentsLinks table (attachments can be linked to Transactions, Contracts, or ChangeOrders)
        'NOTE: no need to update this table since each of these IDs does not change
        
        'update Notes table (notes can be attached to College, Project, or Contract)
        'NOTE: no need to update the Notes table for contracts since the ContractID field in the note stays the same (and the other ID fields are 0)
        
        'update Flags table (flags can be attached to Project, Contract, ChangeOrder, or Transaction)
        'NOTE: no need to update ... since TransactionID does not change, ContractDetailID does not change, ContractID does not change
        
        'update WorkflowLog table (update fields: CollegeID, ProjectID)
        strSQL = "Update WorkflowLog Set CollegeID = " & NewCollegeID & ", ProjectID = " & NewProjectID & " Where ContractID = " & OrigContractID
        retCode = db.ExecuteNonQueryWithReturn(strSQL)
        lblMessage.Text &= retCode & " WorkflowLog table rows updated <br>"

        'commit OR rollback DB changes depending on success/failure 
        
        'refresh left-nav pane
    End Sub
    
    Sub MoveTransactions()
        
        'to move transactions modify the following tables:
        '   keep TransactionID the same, just change the CollegeID, ProjectID, and ContractID.
        '   can only move a transaction to an existing contract
        '       Transaction table - 
        '       TransactionDetail table - 
        '       Attachments table - 
        '       AttachmentsLinks table - 
        '       ContractDetail table -
        '       Contracts table - does not change 
        '       Flags table - 
        '       FRS_ImportLog table - 
        '       Notes table - 
        '       WorkflowLog table - 
        'attachments must also be moved from one folder to another
        Try
            NewContractID = ddlContractDst.SelectedValue
            OrigTransactionID = RadGrid1.SelectedValue
        Catch ex As Exception
            lblMessage.Text = "Error: Please select a Destination Contract"
            Exit Sub
        End Try

    End Sub
    
    Sub CopyDirectory(ByVal SourcePath As String, ByVal DestPath As String, Optional ByVal Overwrite As Boolean = False)
        Dim SourceDir As DirectoryInfo = New DirectoryInfo(SourcePath)
        Dim DestDir As DirectoryInfo = New DirectoryInfo(DestPath)

        ' the source directory must exist, otherwise throw an exception
        If SourceDir.Exists Then
            ' if destination SubDir's parent SubDir does not exist throw an exception
            If Not DestDir.Parent.Exists Then
                Throw New DirectoryNotFoundException _
                    ("Destination directory does not exist: " + DestDir.Parent.FullName)
            End If

            If Not DestDir.Exists Then
                DestDir.Create()
            End If

            ' copy all the files of the current directory
            Dim ChildFile As FileInfo
            For Each ChildFile In SourceDir.GetFiles()
                If Overwrite Then
                    ChildFile.CopyTo(Path.Combine(DestDir.FullName, ChildFile.Name), True)
                Else
                    ' if Overwrite = false, copy the file only if it does not exist
                    ' this is done to avoid an IOException if a file already exists
                    ' this way the other files can be copied anyway...
                    If Not File.Exists(Path.Combine(DestDir.FullName, ChildFile.Name)) Then
                        ChildFile.CopyTo(Path.Combine(DestDir.FullName, ChildFile.Name), False)
                    End If
                End If
            Next

            ' copy all the sub-directories by recursively calling this same routine
            Dim SubDir As DirectoryInfo
            For Each SubDir In SourceDir.GetDirectories()
                CopyDirectory(SubDir.FullName, Path.Combine(DestDir.FullName, _
                    SubDir.Name), Overwrite)
            Next
        Else
            Throw New DirectoryNotFoundException("Source directory does not exist: " + SourceDir.FullName)
        End If
    End Sub

    
    Protected Sub RadGrid1_NeedDataSource(ByVal source As Object, ByVal e As Telerik.Web.UI.GridNeedDataSourceEventArgs)
        If Not e.IsFromDetailTable Then
            RadGrid1.DataSource = dtListTrans
        End If
    End Sub
    
    
    'analyze the move from source to target to see if there are any problems with budget, etc. 
    '   return True if move should proceed; False otherwise
    Protected Function AnalyzeSourceToTargetMove(ByVal sContractID As Integer, ByVal tProjectID As Integer) As Boolean
        Dim db As New PromptDataHelper
        Dim bAllowMove As Boolean = True
               
        'get all ContractLineItems and associated amounts
        Dim sql As String
        sql = " Select ProjectID, ContractID, IsNull(Sum(Amount),0) as Amount, JCAFCellName, ObjectCode, Description "
        sql += "From ContractLineItems CLI Group By ProjectID, ContractID, JCAFCellName, ObjectCode, Description "
        sql += "Having ContractID = " & sContractID
        Dim dtCLI As DataTable  'contract line items
        dtCLI = db.ExecuteDataTable(sql)
        For Each row As DataRow In dtCLI.Rows
            'get encumbered amounts from target project JCAF for comparison
            sql = " declare @tPID integer, @ObCode varchar(50), @Jcaf varchar(100); Set @tPID = " & tProjectID & "; Set @ObCode = '" & row.Item("ObjectCode") & "'; Set @Jcaf = '" & row.Item("JCAFCellName") & "'; "
            sql += "Select IsNull(Sum(Amount),0) as JcafAmount, "
            sql += "    (Select IsNull(Sum(Amount),0) From ContractLineItems Where ProjectID = @tPID and ObjectCode = @ObCode and JcafCellName = @Jcaf) "
            sql += "        + (Select IsNull(Sum(Amount),0) From PassThroughEntries Where ProjectID = @tPID and ObjectCode = @ObCode and JcafCellName = @Jcaf) as AlreadyEncumbered "
            sql += "From BudgetObjectCodes "
            sql += "Where ProjectID = @tPID and ObjectCode = @ObCode and JCAFColumnName = @Jcaf "
            Dim dtDest As DataTable 'target project JCAF
            dtDest = db.ExecuteDataTable(sql)
            
            lblMessage.Text &= "<br/>-->Contract Line Item [" & row.Item("Description") & "] with OC = [" & row.Item("ObjectCode")
            lblMessage.Text &= "] and JCAF cell [" & row.Item("JCAFCellName") & "] --> Amount = " & row.Item("Amount") & "<br/>"
            lblMessage.Text &= "    Destination project JCAF has Amount " & dtDest.Rows(0).Item("JcafAmount") & " with "
            lblMessage.Text &= dtDest.Rows(0).Item("AlreadyEncumbered") & " already encumbered<br/>"

            If (dtDest.Rows(0).Item("JcafAmount") - dtDest.Rows(0).Item("AlreadyEncumbered") - row.Item("Amount")) < 0 Then
                Throw New Exception("not enough money in the jcaf:")    'TODO - show which cell details and all amounts in question
                bAllowMove = False
            End If
            
        Next
       
        
        
        Return bAllowMove
    End Function
        
        
</script>

<html xmlns="http://www.w3.org/1999/xhtml" >
<head runat="server">
    <title>Move Transactions, Contracts, or Projects</title>
</head>
<body>
<form id="Form1" method="post" runat="server">
     <telerik:RadScriptManager ID="RadScriptManager1" runat="server" />
    <div>
        <strong><span style="text-decoration: underline">
        <asp:Label ID="lblDistrictName" runat="server" Text="Label"></asp:Label><br />
        </span>
        
        </strong>
        <br />
        <span style="text-decoration: underline">Source</span>:<asp:CheckBox ID="cbxAnalyzeOnly" runat="server" />Analyze Only<br />
        
        College:
        <asp:DropDownList ID="ddlCollegeSrc" runat="server" OnSelectedIndexChanged="ddlCollegeSrc_SelectedIndexChanged" >
        </asp:DropDownList>&nbsp;<br />
        Project:
        <asp:DropDownList ID="ddlProjectSrc" runat="server" OnSelectedIndexChanged="ddlProjectSrc_SelectedIndexChanged">
        </asp:DropDownList><br />
        Contract:<asp:DropDownList ID="ddlContractSrc" runat="server" OnSelectedIndexChanged="ddlContractSrc_SelectedIndexChanged">
        </asp:DropDownList><br />
        <br />        <br />        <br />        <br />        <br />        <br />        <br />        <br />
        <br />        <br />        <br />        <br />        <br />        <br />        <br />        <br />        <br />
        &nbsp;&nbsp;<br />
        <span style="text-decoration: underline">Destination</span>:<br />
        College:<asp:DropDownList ID="ddlCollegeDst" runat="server" OnSelectedIndexChanged="ddlCollegeDst_SelectedIndexChanged" >
        </asp:DropDownList><br />
        Project:<asp:DropDownList ID="ddlProjectDst" runat="server" OnSelectedIndexChanged="ddlProjectDst_SelectedIndexChanged" >
        </asp:DropDownList><br />
        Contract:<asp:DropDownList ID="ddlContractDst" runat="server" OnSelectedIndexChanged="ddlContractDst_SelectedIndexChanged" >
        </asp:DropDownList><br />
        <br />
        <asp:Button ID="butMove" runat="server" Text="Move" OnClick="butMove_Click"  />
        <br />
        <asp:Label ID="lblMessage" runat="server" Text=""></asp:Label></div>
        <asp:RadioButtonList ID="RadioButtonList1" runat="server" AutoPostBack="True" Style="z-index: 199;
            left: 451px; position: absolute; top: 7px" OnSelectedIndexChanged="RadioButtonList1_SelectedIndexChanged">
            <asp:ListItem Value="Contract">Move Contract</asp:ListItem>
            <asp:ListItem Value="Transaction">Move Transaction(s)</asp:ListItem>
        </asp:RadioButtonList>
        <telerik:RadGrid ID="RadGrid1" runat="server" AllowSorting="True" DataMember="dataSearch"
            EnableAJAX="True" GridLines="None" Height="350px" Skin="Office2007" Style="z-index: 104;
            left: 10px; position: absolute; top: 137px" Width="800px" OnNeedDataSource="RadGrid1_NeedDataSource">
            <ClientSettings>
                <Scrolling AllowScroll="True" ScrollHeight="80%" UseStaticHeaders="True" />
            </ClientSettings>
            <MasterTableView DataMember="dataSearch" GridLines="None" NoMasterRecordsText="No matching records were found to display."
                Width="98%">
                <RowIndicatorColumn>
                    <HeaderStyle Width="20px" />
                </RowIndicatorColumn>
                <ExpandCollapseColumn>
                    <HeaderStyle Width="20px" />
                </ExpandCollapseColumn>
            </MasterTableView>
        </telerik:RadGrid>
    </form>
</body>
</html>
