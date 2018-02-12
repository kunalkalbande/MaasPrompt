
<%@ Page Language="VB" %>

<%@ Import Namespace="Prompt" %>

<script runat="server">
    
    Private nDistrictID As Integer = 0
        
    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs)
              
        nDistrictID = Request.QueryString("id")
        
        tblList.Width = Unit.Pixel(600)
        tblList.BackColor = Color.LightYellow
        

        If nDistrictID = 75 Then      'only Ohlone projects
            Using db As New PromptDataHelper
                Dim sql As String = ""
            
                If nDistrictID = 75 Then
                    sql = "SELECT Projects.CollegeID,Colleges.College,ProjectID,ProjectName, Phase, "
                    sql &= "(SELECT ISNULL(SUM(BudgetItems.Amount),0) AS Budget FROM BudgetItems INNER JOIN BudgetFieldsTable ON BudgetItems.BudgetField = BudgetFieldsTable.ColumnName "
                    sql &= "WHERE BudgetItems.ProjectID = Projects.ProjectID AND BudgetFieldsTable.Source = 'Bond') AS Budget "
                    sql &= "FROM Projects INNER JOIN Colleges ON Projects.CollegeID = Colleges.CollegeID "
                    sql &= "WHERE Projects.DistrictID = " & nDistrictID & "  "
                    sql &= "Order By College, Case "
                    sql &= "	When Phase = 'Board Approved' Then 1 "
                    sql &= "	When Phase = 'Design' Then 2 "
                    sql &= "	When Phase = 'Construction' Then 3 "
                    sql &= "	When Phase = 'Consolidated' Then 4 "
                    sql &= "	When Phase = 'Cancelled' Then 5 "
                    sql &= "	When Phase = 'Deferred' Then 6 "
                    sql &= "	When Phase = 'Completed' Then 7 "
                    sql &= "	Else 99 "
                    sql &= "End Asc, "
                    sql &= "ProjectName "
                    
                    Dim rowh As New TableRow
                    Dim colh As New TableCell
                                        
                    colh = New TableCell
                    colh.VerticalAlign = VerticalAlign.Top
                    colh.Text = "Project"
                    rowh.Cells.Add(colh)
                    
                    colh = New TableCell
                    colh.VerticalAlign = VerticalAlign.Top
                    colh.Text = "Phase"
                    rowh.Cells.Add(colh)
                                       
                    colh = New TableCell
                    colh.VerticalAlign = VerticalAlign.Top
                    colh.HorizontalAlign = HorizontalAlign.Right
                    colh.Text = "Budget"
                    rowh.Cells.Add(colh)
        
                    rowh.BackColor = Color.LightGray
                    rowh.Font.Bold = True
                    
                    tblList.Rows.Add(rowh)

                
                    
                End If
                
                Dim nLastCollege As Integer = 0
                Dim tbl As DataTable = db.ExecuteDataTable(sql)
                For Each datarow As DataRow In tbl.Rows
                    If datarow("CollegeID") <> nLastCollege Then
                        nLastCollege = datarow("CollegeID")
                        Dim rowcol As New TableRow
                        Dim colcol As New TableCell
                    
                        colcol = New TableCell
                        colcol.Text = datarow("College")
                        colcol.ColumnSpan = 4
                        rowcol.Cells.Add(colcol)
                        rowcol.BackColor = Color.LightGreen
                        
                        tblList.Rows.Add(rowcol)
                        
                    End If
                    
                    Dim row As New TableRow
                    Dim col As New TableCell
                    
                                       
                    col = New TableCell
                    col.Text = datarow("ProjectName")
                    row.Cells.Add(col)
                    

                    col = New TableCell
                    col.Text = datarow("Phase")
                    row.Cells.Add(col)

 
                                       
                    col = New TableCell
                    col.Text = FormatCurrency(datarow("Budget"))
                    col.HorizontalAlign = HorizontalAlign.Right
                    row.Cells.Add(col)
                    
                    tblList.Rows.Add(row)
                    
                Next
            
            
            End Using
        Else
            Dim row As New TableRow
            Dim col As New TableCell
                    
            col = New TableCell
            col.Text = "No Projects Found"
            row.Cells.Add(col)
        
            tblList.Rows.Add(row)
        End If
        
 
    End Sub



</script>

<html>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">
<head />
<body>
     
    <asp:Table ID="tblList" runat="server" Font-Names="Arial" Font-Size="11px">
    </asp:Table>

</body>
</html>
