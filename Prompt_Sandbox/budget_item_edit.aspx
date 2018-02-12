<%@ Page Language="vb" %>

<%@ Register Assembly="Telerik.Web.UI" Namespace="Telerik.Web.UI" TagPrefix="telerik" %>
<%@ Import Namespace="Prompt" %>

<script runat="server">  
    
    Private JCAFColumnName As String = ""
    Private ObjectCode As String = ""
    Private ProjectID As Integer = 0
    Private CollegeID As Integer = 0
    
    Private TotalAllocated As Double = 0
    Private TotalEncumbered As Double = 0
    
    Private TotalAggregateUnEncumbered As Double = 0
    
    Private TotalSpent As Double = 0
    Private MinimumAmount As Double = 0
    
    Private PrimaryKey As Integer = 0
      
    Private bReadOnly As Boolean = True
       
    Private Sub Page_Load(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MyBase.Load

        JCAFColumnName = Request.QueryString("FieldName")
        ProjectID = Request.QueryString("ProjectID")
        CollegeID = Request.QueryString("CollegeID")
        PrimaryKey = Request.QueryString("PrimaryKey")
       
          
        lblMessage.Text = ""

        ProcLib.LoadPopupJscript(Page)
        Session("PageID") = "BudgetItemEdit"
        '<a href="main.aspx">main.aspx</a>
        If PrimaryKey = 0 Then  'new
            Page.Header.Title = "Add Budget Item"
        End If
 
        If Not IsPostBack Then     'populate the fields
  
            LoadForm()
            
            txtJCAFColumnName.Value = JCAFColumnName     'store to hidden field so it will be updated in the save/fill form routine

        End If
        
        With RadGrid1
            .EnableEmbeddedSkins = True
            .Skin = "Vista"
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
            .MasterTableView.NoMasterRecordsText = "No Encumberances Found."


            .Height = Unit.Pixel(150)
            
            '.ExportSettings.FileName = "PromptJCAFExport"
            '.ExportSettings.OpenInNewWindow = True
            '.ExportSettings.Pdf.PageTitle = "JCAF Budget Items"

        End With
        
        If lstLedgerAccountID.Items.Count = 1 Then   'there are no ledger accounts, just the default no selection pick so hide
            lstLedgerAccountID.Visible = False
            lblUseLedgerAccount.Visible = False
        End If

        'Lock down view only Clients
        Using db As New EISSecurity
            db.CollegeID = Session("CollegeID")
            db.ProjectID = ProjectID
            If db.FindUserPermission("JCAFBudget", "Write") = False Then
                txtAmount.Enabled = False
                txtNotes.Enabled = False
                lstLedgerAccountID.Enabled = False
                lstObjectCode.Enabled = False
                  
            End If

        End Using
        
        BuildMenu()
           
    End Sub
    
    Private Sub LoadForm()
        'loads the data
        
        Dim sql As String = ""
        Using db As New PromptDataHelper
            'Find out if limiting object codes to only assigned
            sql = "SELECT IncludeAllObjectCodesInJCAF FROM Districts WHERE DistrictID = " & Session("DistrictID")
            If db.ExecuteScalar(sql) = 0 Then
                sql = "SELECT ObjectCodes.ObjectCode as Val, ObjectCodes.ObjectCodeDescription AS Lbl "
                sql &= "FROM ObjectCodes INNER JOIN ObjectCodesJCAFLines ON ObjectCodes.ObjectCode = ObjectCodesJCAFLines.ObjectCode AND "
                sql &= "ObjectCodes.DistrictID = ObjectCodesJCAFLines.DistrictID "
                sql &= "WHERE ObjectCodes.DistrictID = " & Session("DistrictID") & " AND "
                sql &= "ObjectCodesJCAFLines.JCAFItemName = '" & JCAFColumnName & "' "
                sql &= "ORDER BY ObjectCodes.ObjectCode + ' - ' + ObjectCodes.ObjectCodeDescription"

            Else
                sql = "SELECT ObjectCodes.ObjectCode AS Val, ObjectCodes.ObjectCode + ' - ' + ObjectCodes.ObjectCodeDescription AS Lbl "
                sql &= "FROM ObjectCodes WHERE ObjectCodes.DistrictID = " & Session("DistrictID") & " "
                sql &= "ORDER BY ObjectCodes.ObjectCode + ' - ' + ObjectCodes.ObjectCodeDescription"
            End If

            db.FillDropDown(sql, lstObjectCode, False, False, False)

            'Fill Interest Account Dropdown
            sql = "SELECT LedgerAccountID AS Val, LedgerName AS Lbl FROM LedgerAccounts WHERE CollegeID =" & HttpContext.Current.Session("CollegeID") & " ORDER BY LedgerName"
            db.FillDropDown(sql, lstLedgerAccountID, False, False, False)

            'Load form data
            If PrimaryKey > 0 Then
                sql = "SELECT * FROM BudgetObjectCodes WHERE PrimaryKey = " & PrimaryKey
                db.FillForm(Form1, sql)
            End If
        End Using
 

    End Sub
    
   
             
    Private Sub BuildMenu()
        
        Dim bReadOnly As Boolean
        
        If Not IsPostBack Then          'Configure Tool Bar
            
            'get security setting
            Using db As New EISSecurity
                db.CollegeID = Session("CollegeID")
                db.ProjectID = ProjectID
                If db.FindUserPermission("JCAFBudget", "Write") = False Then
                    bReadOnly = True
                End If
            End Using
            
            With RadMenu1
                .EnableEmbeddedSkins = True
                .Skin = "Vista"
                .Width = Unit.Percentage(100)
                .EnableOverlay = False
                '.OnClientItemClicking = "OnClientItemClicking"
 
                .CollapseAnimation.Duration = "200"
                .CollapseAnimation.Type = AnimationType.InOutBounce
                .ExpandAnimation.Duration = "200"
                .ExpandAnimation.Type = AnimationType.InOutBounce
            End With
            
                 
            'build buttons
            Dim but As RadMenuItem
                
            If bReadOnly = False Then
                but = New RadMenuItem
                With but
                    .Text = "Save"
                    .Value = "Save"
                    .ImageUrl = "images/prompt_savetodisk.gif"
                End With
                RadMenu1.Items.Add(but)
            End If
                        
            but = New Telerik.Web.UI.RadMenuItem
            With but
                .Text = "Cancel"
                .Value = "Exit"
                .ImageUrl = "images/exit.png"
                .PostBack = True
            End With
            RadMenu1.Items.Add(but)
            
            If bReadOnly = False Then
                but = New RadMenuItem
                With but
                    .Text = "Delete"
                    .Value = "Delete"
                    .ImageUrl = "images/attachment_remove_small.gif"
                End With
                RadMenu1.Items.Add(but)
            End If
            

            but = New RadMenuItem
            but.IsSeparator = True
            but.Width = Unit.Pixel(25)
            RadMenu1.Items.Add(but)
            

            but = New RadMenuItem
            but.IsSeparator = True
            but.Width = Unit.Pixel(300)
            RadMenu1.Items.Add(but)
    
            
   
            but = New Telerik.Web.UI.RadMenuItem
            With but
                .Text = "Help"
                .Value = "Help"
                .ImageUrl = "images/help.png"
                .Attributes("onclick") = "openPopup('help_view.aspx','pophelp',550,450,'yes');"
                .PostBack = False

            End With
            RadMenu1.Items.Add(but)

 
    
        End If

    End Sub
    
    Private Sub SetEditability()
        'enables/disables controls based on amounts
        Dim nUnspent As Double = TotalEncumbered - TotalSpent
        Dim butDel As RadMenuItem = RadMenu1.FindItemByValue("Delete")

        If PrimaryKey > 0 Then   'existing record
            
            Dim nAmt As Double = txtAmount.Value
            
            'If nUnspent = 0 And TotalEncumbered > 0 Then
            '    MinimumAmount = nAmt
            '    butDel.Visible = False
            '    lstObjectCode.Enabled = False
            '    lstLedgerAccountID.Enabled = False
            '    txtAmount.Enabled = False
                
            'ElseIf nUnspent < TotalEncumbered  Then
            '    MinimumAmount = nAmt
            '    butDel.Visible = False
            '    lstObjectCode.Enabled = False
            '    lstLedgerAccountID.Enabled = False
            '    txtAmount.Enabled = False
                
            If TotalEncumbered = 0 Then    'free to change and delete
                MinimumAmount = 0
                butDel.Visible = True
                lstLedgerAccountID.Enabled = True
                lstObjectCode.Enabled = True
                txtAmount.Enabled = True
                lblMinAmt.Visible = True
                
                'ElseIf TotalEncumbered < nAmt Then     'then can reduce to encubered amount
                '    MinimumAmount =  TotalEncumbered
                '    butDel.Visible = False
                '    lstLedgerAccountID.Enabled = False
                '    lstObjectCode.Enabled = False
                '    txtAmount.Enabled = True
                
                'ElseIf TotalEncumbered >= nAmt Then     'fully encumbered so cannot change
                '    MinimumAmount =  nAmt
                '    butDel.Visible = False
                '    lstLedgerAccountID.Enabled = False
                '    lstObjectCode.Enabled = False
                '    txtAmount.Enabled = False
                
            ElseIf TotalAggregateUnEncumbered >= nAmt Then     'fully unencumbered so can freeely change or delete
                MinimumAmount = 0
                butDel.Visible = True
                lstLedgerAccountID.Enabled = False
                lstObjectCode.Enabled = False
                txtAmount.Enabled = True
                lblMinAmt.Visible = True
                
            ElseIf TotalAggregateUnEncumbered < nAmt Then     'Partially encumbered so cannot change 
                MinimumAmount = TotalEncumbered - TotalAggregateUnEncumbered
                butDel.Visible = False
                lstLedgerAccountID.Enabled = False
                lstObjectCode.Enabled = False
                txtAmount.Enabled = False
                lblMinAmt.Visible = False
                
                'ElseIf  nAmt < Then     'Partially encumbered so cannot change 
                '    MinimumAmount = TotalEncumbered - TotalAggregateUnEncumbered
                '    butDel.Visible = False
                '    lstLedgerAccountID.Enabled = False
                '    lstObjectCode.Enabled = False
                '    txtAmount.Enabled = False
                '    lblMinAmt.Visible = False
                
                
            Else
                MinimumAmount = 0
                butDel.Visible = True
                lstLedgerAccountID.Enabled = True
                lstObjectCode.Enabled = True
                txtAmount.Enabled = True
            End If
            lblMinAmt.Text = "Minimum Amount: <b>" & FormatCurrency(MinimumAmount) & "</b>"
           
            txtAmount.ClientEvents.OnValueChanged = "ValidateAmount"
            'lblMinAmt.Visible = True
            
        Else   'this is a new item
            
            MinimumAmount = 0
            lblMinAmt.Text = "Minimum Amount: <b>" & FormatCurrency(MinimumAmount) & "</b>"
            butDel.Visible = False
            lstLedgerAccountID.Enabled = True
            lstObjectCode.Enabled = True
            txtAmount.Enabled = True
            
            txtAmount.ClientEvents.OnValueChanged = ""
            lblMinAmt.Visible = False
                      
        End If
        
        hfMinimumAmount.Value = MinimumAmount
        
    End Sub
    
    
    Protected Sub RadMenu1_ItemClick(ByVal sender As Object, ByVal e As Telerik.Web.UI.RadMenuEventArgs) Handles RadMenu1.ItemClick
       
        Dim btn As RadMenuItem = e.Item
        
        Select Case btn.Value
            
            Case "Exit"
                
                Response.Redirect("budget_items.aspx?CollegeID=" & CollegeID & "&ProjectID=" & ProjectID & "&FieldName=" & JCAFColumnName)

                
            Case "Save"
                
                Dim sEntryDate As String
                If Not IsDate(txtItemDate.SelectedDate) = True Then
                    sEntryDate = Now.ToShortDateString
                Else
                    sEntryDate = CDate(txtItemDate.SelectedDate).ToShortDateString
                End If

                If txtAmount.Value <> 0 Then
                    Dim sql As String = ""
                    Dim bLogChanges As Boolean = False
                    Dim bNewEntry As Boolean = False
                    Dim sLogDescription As String = ""
                    
                    Using db As New PromptDataHelper

                        If PrimaryKey = 0 Then
                            bNewEntry = True
                        End If
                        
                        'Check to see if JCAF Budget Change tracking is on and if so get old values
                        sql = "SELECT IsNull(TrackJCAFBudgetChanges,0) FROM Colleges WHERE CollegeID = " & CollegeID
                        Dim nresult As Integer = db.ExecuteScalar(sql)
                        If nresult > 0 Then bLogChanges = True

                        If bLogChanges And Not bNewEntry Then  'get existing and log changes
                            sql = "SELECT * FROM BudgetObjectCodes WHERE PrimaryKey = " & PrimaryKey
                            Dim tbl As DataTable = db.ExecuteDataTable(sql)
                            Dim row As DataRow = tbl.Rows(0)
                            sLogDescription = "Allocation to ObjectCode " & row("Description") & " for " & FormatCurrency(row("Amount")) & " was changed."
                            LogChange(CollegeID, ProjectID, JCAFColumnName, sLogDescription)

                            'Update the change log
                            Dim sOldNote As String = ""
                            Dim sOldAmount As Double = 0
                            Dim sOldDate As String = 0
                            
                            sOldNote = ProcLib.CheckNullDBField(row("Notes"))
                            sOldNote = sOldNote.Replace("'", "''")
                            sOldAmount = row("Amount")
                            sOldDate = ProcLib.CheckNullDBField(row("ItemDate"))
                            
                            sLogDescription = "Allocation to ObjectCode " & row("Description") & " for " & FormatCurrency(row("Amount")) & " was changed."
                            sLogDescription &= vbCrLf & "New Amount:  " & FormatCurrency(txtAmount.Value) & vbCrLf & " Notes: " & txtNotes.Text
                           
                           sLogDescription = sLogDescription.Replace("'","''")
  
                            LogChange(CollegeID, ProjectID, JCAFColumnName, sLogDescription)
      
                        End If
                        
                        If bNewEntry Then  'new
                            sql = "INSERT INTO BudgetObjectCodes (DistrictID,CollegeID,ProjectID,JCAFColumnName) "
                            sql &= " VALUES(" & Session("DistrictID") & "," & CollegeID & "," & ProjectID & ",'" & JCAFColumnName & "') "
                            sql &= "SELECT CAST(SCOPE_IDENTITY() AS int) AS ID"
                            PrimaryKey = db.ExecuteScalar(sql)
                            
                        End If
 
                    
                        sql = "SELECT * FROM BudgetObjectCodes WHERE PrimaryKey = " & PrimaryKey
                        db.SaveForm(Form1, sql)
                        'now update the ObjectCode Description
                        sql = "UPDATE BudgetObjectCodes SET Description = '" & lstObjectCode.SelectedItem.Text & "', ItemDate = '" & sEntryDate & "' WHERE PrimaryKey = " & PrimaryKey
                        db.ExecuteNonQuery(sql)
                        
                        If bLogChanges And bNewEntry Then  'log added allocations
                            
                            sLogDescription = "New Allocation: " & FormatCurrency(txtAmount.Value) & " allocated to ObjectCode " & lstObjectCode.SelectedItem.Text
                            LogChange(CollegeID, ProjectID, JCAFColumnName, sLogDescription)

                        End If
                    
                        'LEGACY - Update the parent BudgetItem
                        'Check to see that there is a BudgetItem already
                        Dim nBudgetItemID As Integer = ProcLib.CheckNullNumField(db.ExecuteScalar("SELECT BudgetItemID FROM BudgetItems WHERE BudgetField = '" & JCAFColumnName & "' AND ProjectID = " & ProjectID))
                        If nBudgetItemID = 0 Then
                            sql = "INSERT INTO BudgetItems (DistrictID,CollegeID,ProjectID,BudgetField) "
                            sql &= " VALUES(" & Session("DistrictID") & "," & CollegeID & "," & ProjectID & ",'" & JCAFColumnName & "') "
                            sql &= "SELECT CAST(SCOPE_IDENTITY() AS int) AS ID"
                            nBudgetItemID = db.ExecuteScalar(sql)
                            
                        End If
                        
                        sql = "SELECT SUM(Amount) AS Amount FROM BudgetObjectCodes WHERE  JCAFColumnName = '" & JCAFColumnName & "' AND ProjectID = " & ProjectID
                        Dim nBudgetItemAmount As Double = ProcLib.CheckNullNumField(db.ExecuteScalar(sql))
                        
                        sql = "UPDATE BudgetItems SET Amount = " & nBudgetItemAmount & ", LastUpdateOn = '" & Now() & "', LastUpdateBy = '" & Session("UserName") & "' "
                        sql &= "WHERE BudgetField = '" & JCAFColumnName & "' AND ProjectID = " & ProjectID
                        db.ExecuteNonQuery(sql)
                        
                        
                        If lstLedgerAccountID.SelectedValue > 0 Then    'add/Update Ledger Account entry 

                            Dim nLedgerEntryID As Integer = ProcLib.CheckNullNumField(db.ExecuteScalar("SELECT LedgerEntryID FROM LedgerAccountEntries WHERE BudgetObjectCodeID = " & PrimaryKey))
                            
                            'Get the project name 
                            Dim sProjName As String = db.ExecuteScalar("SELECT ProjectName FROM Projects WHERE ProjectID = " & ProjectID)
                            Dim sJCAFDescr As String = db.ExecuteScalar("SELECT Description FROM BudgetFieldsTable WHERE ColumnName = '" & JCAFColumnName & "'")

                            Dim sDescr As String = "Allocation to " & sProjName & ", JCAF Line - " & sJCAFDescr & ", ObjectCode - " & ObjectCode & ")"
                            If Trim(txtNotes.Text) <> "" Then
                                sDescr = txtNotes.Text
                            End If
                            
                            If nLedgerEntryID = 0 Then   'does not exist
                                sql = "INSERT INTO LedgerAccountEntries (DistrictID,CollegeID,ProjectID,Description,BudgetJCAFColumn,"
                                sql &= "EntryType,EntryDate,Amount,LedgerAccountID,BudgetObjectCodeID,LastUpdateBy,LastUpdateOn) "
                                sql &= " VALUES(" & Session("DistrictID") & ","
                                sql &= CollegeID & ","
                                sql &= ProjectID & ","
                                sql &= "'" & sDescr & "',"
                                sql &= "'" & JCAFColumnName & "',"
                                sql &= "'Debit',"
                                sql &= "'" & sEntryDate & "',"

                                sql &= (txtAmount.Value * -1) & ","
                                sql &= lstLedgerAccountID.SelectedValue & ","
                                sql &= PrimaryKey & ","
                                sql &= "'" & Session("UserName") & "','" & Now() & "')"

                                
                            Else
                                sql = "UPDATE LedgerAccountEntries SET "
                                sql &= "Description =  '" & sDescr & "', "
                                sql &= "EntryDate = '" & sEntryDate & "', "
                                sql &= "Amount = " & (txtAmount.Value * -1) & ", "
                                sql &= "LastUpdateOn = '" & Now() & "', "
                                sql &= "LastUpdateBy = '" & Session("UserName") & "' "
                                
                                sql &= "WHERE LedgerEntryID = " & nLedgerEntryID

                            End If

                           
                            db.ExecuteNonQuery(sql)   'get the new primary key for this allocation for ledger account entry
                        End If
                                                                                                                  
                    End Using
                End If
                               
                Response.Redirect("budget_items.aspx?CollegeID=" & CollegeID & "&ProjectID=" & ProjectID & "&FieldName=" & JCAFColumnName)
                    
            Case "Delete"
                
                Dim sql As String = ""
                Dim bLogChanges As Boolean = False
                Dim sLogDescription As String = ""
                Using db As New PromptDataHelper
                    
                    'Check to see if JCAF Budget Change tracking is on and if so get old values
                    sql = "SELECT IsNull(TrackJCAFBudgetChanges,0) FROM Colleges WHERE CollegeID = " & CollegeID
                    Dim nresult As Integer = db.ExecuteScalar(sql)
                    If nresult > 0 Then bLogChanges = True
                    
                    If bLogChanges Then  'get existing and log changes
                        sql = "SELECT * FROM BudgetObjectCodes WHERE PrimaryKey = " & PrimaryKey
                        Dim tbl As DataTable = db.ExecuteDataTable(sql)
                        Dim row As DataRow = tbl.Rows(0)
                        sLogDescription = "Allocation to ObjectCode " & row("Description") & " for " & FormatCurrency(row("Amount")) & " was Deleted."
                        LogChange(CollegeID, ProjectID, JCAFColumnName, sLogDescription)

                    End If
             
                    sql = "DELETE FROM BudgetObjectCodes WHERE PrimaryKey = " & PrimaryKey
                    db.ExecuteNonQuery(sql)
                    
                    sql = "DELETE FROM LedgerAccountEntries WHERE BudgetObjectCodeID = " & PrimaryKey
                    db.ExecuteNonQuery(sql)
                    
                    'LEGACY - Update the parent BudgetItem
                    sql = "SELECT SUM(Amount) AS Amount FROM BudgetObjectCodes WHERE  JCAFColumnName = '" & JCAFColumnName & "' AND ProjectID = " & ProjectID
                    Dim nBudgetItemAmount As Double = ProcLib.CheckNullNumField(db.ExecuteScalar(sql))
                    
                    If nBudgetItemAmount = 0 Then
                        sql = "DELETE FROM BudgetItems WHERE BudgetField = '" & JCAFColumnName & "' AND ProjectID = " & ProjectID
                        db.ExecuteNonQuery(sql)
                    Else
                        sql = "UPDATE BudgetItems SET Amount = " & nBudgetItemAmount & ", LastUpdateOn = '" & Now() & "', LastUpdateBy = '" & Session("UserName") & "' "
                        sql &= "WHERE BudgetField = '" & JCAFColumnName & "' AND ProjectID = " & ProjectID
                        db.ExecuteNonQuery(sql)
                    End If
 
                End Using
                
               
                Response.Redirect("budget_items.aspx?CollegeID=" & CollegeID & "&ProjectID=" & ProjectID & "&FieldName=" & JCAFColumnName)

        End Select
        
    End Sub
    
    Private Sub LogChange(ByVal CollegeID As Integer, ByVal ProjectID As Integer, ByVal JCAFColumnName As String, ByVal Description As String)
        Using db1 As New PromptDataHelper
            Dim sql As String = "INSERT INTO JCAFChangeLog (DistrictID,CollegeID,ProjectID,JCAFCOlumnName,ChangeDescription,LastUpdateOn,LastUpdateBy) "
            sql &= "VALUES(" & Session("DistrictID") & "," & CollegeID & "," & ProjectID & ","
            sql &= "'" & JCAFColumnName & "','" & Description & "','" & Now() & "','" & Session("UserName") & "')"
            db1.ExecuteNonQuery(sql)
        End Using

    End Sub
    
    Protected Sub lstObjectCode_SelectedIndexChanged(ByVal sender As Object, ByVal e As System.EventArgs) Handles lstObjectCode.SelectedIndexChanged               
        RadGrid1.Rebind()
    End Sub
    
    Protected Sub RadGrid1_NeedDataSource(ByVal source As Object, ByVal e As Telerik.Web.UI.GridNeedDataSourceEventArgs) Handles RadGrid1.NeedDataSource
        
        ObjectCode = lstObjectCode.SelectedValue
        
        Using db As New PromptDataHelper
            
            Dim sql As String = "SELECT Contacts.Name AS Company, Contracts.Description,Contracts.ContractID, Contracts.Status, ContractLineItems.JCAFCellName, ContractLineItems.ObjectCode, "
            sql &= " SUM(ContractLineItems.Amount) AS Encumbered "
            sql &= "FROM ContractLineItems INNER JOIN Contracts ON ContractLineItems.ContractID = Contracts.ContractID INNER JOIN "
            sql &= "Contacts ON Contracts.ContractorID = Contacts.ContactID "
            sql &= "WHERE ContractLineItems.ProjectID=" & ProjectID & " AND ContractLineItems.ObjectCode='" & ObjectCode & "' AND ContractLineItems.JCAFCellName='" & JCAFColumnName & "' "
            sql &= "GROUP BY Contacts.Name, Contracts.Description, Contracts.ContractID,Contracts.Status, ContractLineItems.JCAFCellName, ContractLineItems.ObjectCode "
            sql &= "ORDER BY Company,Description "
           
            Dim tbl As DataTable = db.ExecuteDataTable(sql)
            
            'Now get the expended for OC per contract
            sql = "SELECT SUM(TransactionDetail.Amount) AS Expended, ContractLineItems.JCAFCellName, ContractLineItems.ObjectCode, ContractLineItems.ContractID, ContractLineItems.ProjectID "
            sql &= "FROM TransactionDetail INNER JOIN ContractLineItems ON TransactionDetail.ContractLineItemID = ContractLineItems.LineID "
            sql &= "WHERE ContractLineItems.ProjectID=" & ProjectID & " AND ContractLineItems.ObjectCode='" & ObjectCode & "' AND ContractLineItems.JCAFCellName='" & JCAFColumnName & "' "
            sql &= "GROUP BY ContractLineItems.JCAFCellName, ContractLineItems.ObjectCode, ContractLineItems.ContractID, ContractLineItems.ProjectID "
            Dim tblExp As DataTable = db.ExecuteDataTable(sql)
            
            'Add Expended column
            Dim col As New DataColumn
            col.DataType = Type.GetType("System.Double")
            col.ColumnName = "Spent"
            tbl.Columns.Add(col)
            
            'Get any Passthrough amount
            sql = "SELECT IsNull(SUM(Amount),0) AS Amount FROM PassThroughEntries "
            sql &= "WHERE ProjectID =" & ProjectID & " AND ObjectCode='" & ObjectCode & "' AND JCAFCellName='" & JCAFColumnName & "' "
            Dim nOverhead As Double = ProcLib.CheckNullNumField(db.ExecuteScalar(sql))
            
            
            sql = "SELECT SUM(Amount) AS TotalAllocated "   'note - this value will be the same for each record
            sql &= "FROM BudgetObjectCodes  "
            sql &= "WHERE ProjectID =" & ProjectID & " AND ObjectCode='" & ObjectCode & "' AND JCAFColumnName='" & JCAFColumnName & "' "
            Dim nAlloc As Double = ProcLib.CheckNullNumField(db.ExecuteScalar(sql))
            
                       
            'Add Allocated column
            col = New DataColumn
            col.DataType = Type.GetType("System.Double")
            col.ColumnName = "TotalAllocated"
            tbl.Columns.Add(col)
            
            'Clean Up some data
            For Each row As DataRow In tbl.Rows()
                row("Status") = Mid(row("Status"), 3)    'remove the sort number in contract status
                row("Spent") = 0
                row("TotalAllocated") = nAlloc
                
                For Each rowexp As DataRow In tblExp.Rows
                    If rowexp("ContractID") = row("ContractID") Then
                        row("Spent") = rowexp("Expended")
                        Exit For
                    End If
                Next
            Next
            
            If nOverhead > 0 Then   'add an overhead line
                Dim newrow As DataRow = tbl.NewRow
                'newrow("ProjectID") = ProjectID
                newrow("Status") = "Paid"
                newrow("TotalAllocated") = nOverhead
                newrow("Encumbered") = nOverhead
                newrow("Spent") = nOverhead
                newrow("Company") = "(Passthrough Expense)"
                newrow("Description") = "Allocated from Passthrough Account(s)"
                
                tbl.Rows.Add(newrow)
                
            End If
            
            
            RadGrid1.DataSource = tbl
        End Using
        
    End Sub
    
    Private Sub RadGrid1_ItemDataBound(ByVal sender As Object, ByVal e As Telerik.Web.UI.GridItemEventArgs) Handles RadGrid1.ItemDataBound
        If (TypeOf e.Item Is GridDataItem) Then
            Dim dataItem As GridDataItem = CType(e.Item, GridDataItem)

            TotalEncumbered += ProcLib.CheckNullNumField(dataItem.OwnerTableView.DataKeyValues(dataItem.ItemIndex)("Encumbered"))
            TotalSpent += dataItem.OwnerTableView.DataKeyValues(dataItem.ItemIndex)("Spent")
            
            TotalAllocated = dataItem.OwnerTableView.DataKeyValues(dataItem.ItemIndex)("TotalAllocated")   'this will be same for each row
          
        End If
        
        If (TypeOf e.Item Is GridFooterItem) Then
                     
            Dim nRemSpent As Double = TotalEncumbered - TotalSpent
            TotalAggregateUnEncumbered = TotalAllocated - TotalEncumbered
            
            Dim footerItem As GridFooterItem = CType(e.Item, GridFooterItem)
            Dim sText As String = ""
            sText = "Obj Code Aggregate Totals: <br /> Obj Code Aggregate Remaining:"
            footerItem("Description").Text = sText
            footerItem("Description").HorizontalAlign = HorizontalAlign.Right
            
            sText = FormatCurrency(TotalSpent) & "<br />" & FormatCurrency(nRemSpent)
            footerItem("Spent").Text = sText
            footerItem("Spent").HorizontalAlign = HorizontalAlign.Right
            
            sText = FormatCurrency(TotalEncumbered) & "<br />" & FormatCurrency(TotalAggregateUnEncumbered)
            footerItem("Encumbered").Text = sText
            footerItem("Encumbered").HorizontalAlign = HorizontalAlign.Right
            
            'footerItem.Font.Bold = True
            
            SetEditability()

        End If
  
        
    End Sub
      
    
</script>

<html>
<head runat="server">
    <title>Edit Budget Item</title>
    <link href="Styles.css" type="text/css" rel="stylesheet" />
    <link href="skins/Prompt/Grid.Prompt.css" rel="stylesheet" type="text/css" />
    <link href="skins/Prompt/Menu.Prompt.css" rel="stylesheet" type="text/css" />
    <style type="text/css">
        .style1
        {
            width: 75px;
        }
    </style>
    
    
    
        <telerik:RadCodeBlock ID="RadCodeBlock1" runat="server">

        <script type="text/javascript" language="javascript">

            function ValidateAmount(sender, eventArgs) {

               
                var objMinVal = document.getElementById('hfMinimumAmount');
                var nMinVal = objMinVal.value;

                
                
                var sCtrlID = sender.get_id();                      // get the current textbox control id
                var sNewVal = eventArgs.get_newValue();             // get the new value
                var sOldVal = eventArgs.get_oldValue();             // get the old value

                if (sOldVal == "") {                                // MAKE ZERO IF BLANK
                    sOldVal = 0;
                }
                if (sNewVal == "") {
                    sNewVal = 0;
                }

               //var nNewBal =  parseFloat(sOldVal) - parseFloat(sNewVal);
               //alert(sOldVal);
              // alert(sNewVal);
              // alert(nNewBal);
              // alert(nMinVal);

               if (sNewVal < nMinVal && sNewVal > 0) {
                    alert('Sorry, the new amount entered would be less than the minimum value allowed for this line.');
                    sender.set_value(sOldVal);
                    eventArgs.set_cancel(true);
                    
                    window.setTimeout(function() { sender.focus(); }, 50);
                    return false;
                }

            }

   
        </script>

    </telerik:RadCodeBlock>
 
</head>
<body>
    <form id="Form1" method="post" runat="server">
    <telerik:RadScriptManager ID="RadScriptManager1" runat="server" />
    <telerik:RadMenu ID="RadMenu1" runat="server" OnItemClick="RadMenu1_ItemClick" />
    <br />
    <br />
    <table width="100%">
        <tr>
            <td class="style1">
                <asp:Label ID="Label6" runat="server" Text="Date:" />
            </td>
            <td colspan="2" valign="center">
                <telerik:RadDatePicker ID="txtItemDate" runat="server" TabIndex="55" Width="120px"
                    SharedCalendarID="sharedCalendar" Skin="Vista">
                    <DateInput ID="DateInput4" runat="server" Skin="Vista" BackColor="#FFFFC0" Font-Size="13px"
                        ForeColor="Blue">
                    </DateInput>
                </telerik:RadDatePicker>
                &nbsp;&nbsp;&nbsp;
 
                <asp:Label ID="lblUseLedgerAccount" runat="server" Text="Use $$ From:" />
                <asp:DropDownList ID="lstLedgerAccountID" runat="server" Width="135px" ToolTip="Allocate amount from a Ledger Account.">
                    <asp:ListItem Selected="True" Value="0">--</asp:ListItem>
                </asp:DropDownList>
            </td>
        </tr>
        <tr>
            <td class="style1">
            <asp:Label ID="Label4" runat="server" Text="Object Code:" />
                
            </td>
            <td colspan="3">
             <asp:DropDownList ID="lstObjectCode" AutoPostback="true" runat="server" Width="170px" OnSelectedIndexChanged="lstObjectCode_SelectedIndexChanged" />
        &nbsp;&nbsp;&nbsp;
            <asp:Label ID="Label8" runat="server" Text="Amount:" /> &nbsp;&nbsp;
                <telerik:RadNumericTextBox ID="txtAmount" runat="server" MinValue="-1000000000" 
                    Width="125px" >
                    <ClientEvents OnValueChanged="ValidateAmount" />
                </telerik:RadNumericTextBox>
                &nbsp;&nbsp;&nbsp;&nbsp;
                <asp:Label ID="lblMinAmt" runat="server" Text="Minimum Amount: <b> $99999.99 </b>" />
            </td>
        </tr>
        <tr>
            <td colspan="4">
                <asp:Label ID="lblMessage" runat="server" Font-Bold="True" ForeColor="Red" Text="message" />
            </td>
        </tr>
        
               <tr>
            <td class="style1" valign="top">
                <asp:Label ID="Label7" runat="server" Text="Notes:" />
            </td>
            <td colspan="3">
                <asp:TextBox ID="txtNotes" runat="server" TabIndex="1" Width="570px" Height="50px"
                    TextMode="MultiLine" />
            </td>
        </tr>
        
        <tr>
            <td class="style1" valign="top" colspan="4">
                <telerik:RadGrid ID="RadGrid1" runat="server" AllowMultiRowSelection="False" AutoGenerateColumns="False"
                    Skin="" GridLines="None" AllowSorting="true" Width="670px" 
                    BorderColor="#006699" BorderStyle="Solid" BorderWidth="1px">
                    <HeaderStyle Font-Size="Smaller" />
                    <ClientSettings>
                        <Scrolling AllowScroll="True" UseStaticHeaders="True" ScrollHeight="50%" />
                    </ClientSettings>
                    <MasterTableView DataKeyNames="Encumbered,Spent,TotalAllocated" 
                        ShowFooter="true" Caption="Encumberances From This Object Code/JCAF Bucket">


                        <Columns>
                            <telerik:GridBoundColumn DataField="Company" UniqueName="Company" HeaderText="Company"  SortExpression="Company">
                                <ItemStyle HorizontalAlign="Left" Width="150px" />
                                <HeaderStyle HorizontalAlign="Left" Width="150px" />
                            </telerik:GridBoundColumn>
                            <telerik:GridBoundColumn DataField="Description" HeaderText="Description" UniqueName="Description">
                                <ItemStyle HorizontalAlign="Left" Width="170px" />
                                <HeaderStyle HorizontalAlign="Left" Width="170px" />
                            </telerik:GridBoundColumn>
                            <telerik:GridBoundColumn DataField="Status" HeaderText="Status" UniqueName="Status">
                                <ItemStyle HorizontalAlign="Left" Width="50px" />
                                <HeaderStyle HorizontalAlign="Left" Width="50px" />
                            </telerik:GridBoundColumn>
                            <telerik:GridBoundColumn DataField="Spent" HeaderText="Expended" UniqueName="Spent"
                                DataFormatString="{0:c}">
                                <ItemStyle HorizontalAlign="Right" Width="120px" />
                                <HeaderStyle HorizontalAlign="Right" Width="120px" />
                            </telerik:GridBoundColumn>
                            <telerik:GridBoundColumn DataField="Encumbered" HeaderText="Encumbered" UniqueName="Encumbered"
                                DataFormatString="{0:c}">
                                <ItemStyle HorizontalAlign="Right" Width="120px" />
                                <HeaderStyle HorizontalAlign="Right" Width="120px" />
                            </telerik:GridBoundColumn>
                        </Columns>
                        <FooterStyle Height="40px" Font-Size="Smaller"></FooterStyle>
                    </MasterTableView>
                </telerik:RadGrid>
            </td>
        </tr>
 
    </table>
    <telerik:RadCalendar ID="sharedCalendar" Skin="Vista" runat="server" EnableMultiSelect="false">
    </telerik:RadCalendar>
    
    <asp:HiddenField runat="server" ID="hfMinimumAmount" Value="0" />
    <asp:HiddenField runat="server" ID="txtJCAFColumnName" Value="" />
    
    
    <telerik:RadAjaxManager ID="RadAjaxManager1" runat="server">
        <AjaxSettings>
            <telerik:AjaxSetting AjaxControlID="lstObjectCode">
                <UpdatedControls>
                    <telerik:AjaxUpdatedControl ControlID="RadGrid1" LoadingPanelID="RadAjaxLoadingPanel1" />
                </UpdatedControls>
            </telerik:AjaxSetting>
        </AjaxSettings>
    </telerik:RadAjaxManager>
    <telerik:RadAjaxLoadingPanel ID="RadAjaxLoadingPanel1" runat="server" Height="75px"
        Width="75px" Transparency="25">
        <img alt="Loading..." src='<%= RadAjaxLoadingPanel.GetWebResourceUrl(Page, "Telerik.Web.UI.Skins.Default.Ajax.loading.gif") %>'
            style="border: 0;" />
    </telerik:RadAjaxLoadingPanel>
    </form>
</body>
</html>
