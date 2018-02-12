<%@ Page Language="vb" %>

<%@ Import Namespace="System.Data" %>
<%@ Import Namespace="System.Data.SqlCLient" %>
<%@ Import Namespace="Prompt" %>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">

<script runat="server">

    Private nCollegeID As Integer
    
    Private Sub Page_Load(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MyBase.Load

        nCollegeID = Request.QueryString("ID") 'should be 112, 82 or 82 for FHDA
        
        Session("DistrictID") = 55
 
        Dim strImage As String = ""
        
        'Add the header row
        
        Dim row As New TableRow
        Dim cc As New TableCell
        cc.Text = "Project Name"
        cc.Wrap = False
        cc.BackColor = Drawing.Color.LightGray
        cc.Font.Bold = True
        cc.HorizontalAlign = HorizontalAlign.Left
        cc.CssClass = "smalltext"
        
        row.Cells.Add(cc)
        
        cc = New TableCell
        cc.Text = "Project Number"
        cc.Wrap = False
        cc.BackColor = Drawing.Color.LightGray
        cc.Font.Bold = True
        cc.HorizontalAlign = HorizontalAlign.Center
        cc.CssClass = "smalltext"
        row.Cells.Add(cc)
 
        cc = New TableCell
        cc.Wrap = False
        cc.Text = "Bond Budget"
        cc.BackColor = Drawing.Color.LightGray
        cc.Font.Bold = True
        cc.HorizontalAlign = HorizontalAlign.Right
        cc.CssClass = "smalltext"
        row.Cells.Add(cc)
        
        tblList.Rows.Add(row)
 
        Using db As New PromptDataHelper
  
            
            Dim sql As String = "SELECT dbo.Colleges.College, LTRIM((CASE WHEN UsePromptName = 0 THEN dbo.Projects.ProjectTitle ELSE dbo.Projects.ProjectName END)) AS Title, "
            sql &= "dbo.Projects.UsePromptName, dbo.Projects.ProjectName, dbo.Projects.ProjectTitle, dbo.Projects.AppriseDescription, dbo.Projects.UsePromptDescr, "
            sql &= "dbo.Projects.FundingSource, dbo.Projects.FundingDescription, dbo.Projects.CurrentProjectCost, dbo.Projects.PercentComplete, dbo.Projects.PublishToWeb, "
            sql &= "dbo.Projects.Description AS ProjectsDescription, dbo.Projects.LastUpdateOn AS AppriseLastUpdate, dbo.Projects.LastUpdateOn AS ProjectsLastUpdate, "
            sql &= "dbo.Projects.ProjectID, dbo.Projects.Status, dbo.Projects.CollegeID, dbo.Projects.DistrictID, dbo.Projects.UsePromptCompletionDate, "
            sql &= "dbo.Projects.HideCompletionDate, dbo.Projects.EstCompleteDate AS PromptEstCompleteDate, dbo.Projects.ProjectNumber, dbo.Projects.OrigBudget AS ProjectBudget,"
            sql &= "dbo.Projects.StartDate, dbo.Projects.HidePercentComplete, dbo.Projects.UsePromptBudget,dbo.Projects.UseManualBudgetAmount , dbo.Projects.ProjectGroupID ,"
            
            sql &= "(SELECT ISNULL(SUM(Amount), 0) AS TotAmount FROM dbo.BudgetItems WHERE BudgetField LIKE '%Bond%' AND ProjectID = Projects.ProjectID) AS ProjectBondTotal "
            sql &= "FROM dbo.Projects INNER JOIN dbo.Colleges ON dbo.Projects.CollegeID = dbo.Colleges.CollegeID "
            sql &= "WHERE dbo.Projects.PublishToWeb = 1 AND Colleges.CollegeID = " & nCollegeID & " "
            sql &= "ORDER BY dbo.Projects.Status,Title"
                        
            Dim rs As DataTable = db.ExecuteDataTable(sql)
            Dim col As DataColumn = New DataColumn("PromptBondTotal", System.Type.GetType("System.Double"))
            rs.Columns.Add(col)
            
            'Now go through to see if the project is part of a project group and if so, then consolodate the bond amount from all the group projects
            For Each rrow As DataRow In rs.Rows
                If ProcLib.CheckNullNumField(rrow("ProjectGroupID")) > 0 Then
                    sql = "SELECT ISNULL(SUM(dbo.BudgetItems.Amount), 0) AS TotAmount "
                    sql &= "FROM dbo.BudgetItems INNER JOIN dbo.Projects ON dbo.BudgetItems.ProjectID = dbo.Projects.ProjectID "
                    sql &= "WHERE dbo.Projects.ProjectGroupID = 18 AND dbo.BudgetItems.BudgetField LIKE '%Bond%' "
                    
                    rrow("PromptBondTotal") = db.ExecuteScalar(sql)
                    
                Else
                    rrow("PromptBondTotal") = rrow("ProjectBondTotal")
                End If
                
            Next
  
            
            Dim sLastStatus As String = ""
            For Each rproject As DataRow In rs.Rows
                If sLastStatus <> rproject("Status") Then
                    sLastStatus = rproject("Status")
                    If rproject("Status") = "1-Active" Then
                        strImage = "<img src=images/triangle_greenS.gif />"
                    ElseIf rproject("Status") = "2-Proposed" Then
                        strImage = "<img src=images/triangle_blueS.gif />"
                    ElseIf rproject("Status") = "3-Suspended" Then
                        strImage = "<img src=images/triangle_yellowS.gif />"
                    ElseIf rproject("Status") = "4-Cancelled" Then
                        strImage = "<img src=images/triangle_redS.gif />"
                    Else
                        strImage = "<img src=images/triangle_brownS.gif />"
                    End If
                
                    'create category row
                    row = New TableRow
                    row.BackColor = Drawing.Color.Beige
            
                    cc = New TableCell
                    cc.Text = " ---  " & Mid(sLastStatus, 3) & " Projects  --- "
                    cc.ColumnSpan = 3
                    cc.Wrap = False
                    cc.CssClass = "smalltext"
                    cc.HorizontalAlign = HorizontalAlign.Left
                    row.Cells.Add(cc)
            
               
                    tblList.Rows.Add(row)
                
                End If
         
               
                row = New TableRow
            
                cc = New TableCell
                cc.Text = strImage & "<a href='xfhda_project_view.aspx?ProjectID=" & rproject("ProjectID") & "'>" & rproject("Title") & "</a>"
                cc.Wrap = False
                cc.CssClass = "ProjectDataValue"
                cc.HorizontalAlign = HorizontalAlign.Left
                row.Cells.Add(cc)
            
                cc = New TableCell
                cc.Text = rproject("ProjectNumber")
                cc.CssClass = "ProjectDataValue"
                cc.HorizontalAlign = HorizontalAlign.Center
                row.Cells.Add(cc)
            
                cc = New TableCell
                If rproject("UsePromptBudget") = 1 Then
                    cc.Text = FormatCurrency(rproject("PromptBondTotal"), 0)
                Else
                    cc.Text = FormatCurrency(rproject("ProjectBudget"), 0)
                End If
            
                If Not IsDBNull(rproject("UseManualBudgetAmount")) Then
                    If rproject("UseManualBudgetAmount") = 1 Then
                        cc.Text = FormatCurrency(rproject("CurrentProjectCost"), 0)
                    End If
                End If
            
                cc.CssClass = "ProjectDataValue"
                cc.HorizontalAlign = HorizontalAlign.Right
                row.Cells.Add(cc)
            
                tblList.Rows.Add(row)
            Next

        End Using
 
    End Sub


</script>

<html>
<head>
    <title>FHDA Apprise Navigation</title>
<style type='text/css'>
body, #tblList{font-family:Arial, Helvetica, sans-serif;font-size:11px;}
a{color: #000;}
</style>
</head>
<body>
<img src="http://measurec.fhda.edu.previewdns.com/wp-content/uploads/2012/02/prompt_legend.jpg" alt="" />
    <form id="Form1" method="post" runat="server">
        <asp:Table ID="tblList" runat="server" Width="400px" BorderColor="#FFFFFF" BorderStyle="Solid" BorderWidth="1px" GridLines="Horizontal">
           
        </asp:Table>
    </form>
</body>
</html>
