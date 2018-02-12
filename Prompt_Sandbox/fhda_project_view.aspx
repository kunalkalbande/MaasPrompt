<%@ Page Language="vb" %>

<%@ Import Namespace="System.IO" %>
<%@ Import Namespace="System.Data" %>
<%@ Import Namespace="System.Configuration" %>
<%@ Import Namespace="System.Web.UI.WebControls" %>
<%@ Import Namespace="Prompt" %>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">

<script runat="server">

    Private Sub Page_Load(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MyBase.Load
        Dim rs As New PromptDataHelper
        Dim strImagePath As String = ""
        Dim strRealPhotoPath As String = ""

        Dim nCollegeID As Integer = 0
        Dim nProjectID As Integer = 0
        Dim nDistrictID As Integer = 0
        Dim strProjectTitle As String = ""
        Dim strDescription As String = ""
        Dim strFundingSource As String = ""
        Dim strFundingDescription As String = ""
        Dim strCurrentProjectCost As String = ""
        Dim strPercentComplete As String = ""
        Dim strEstCompleteDate As String = ""
        Dim strPercentImage As String = ""
        
        Dim strLastUpdateOn As String = ""

        Dim bShowMainPhoto As Boolean = False
        Dim bHideCompleteDate As Boolean = False
        Dim bHidePercentComplete As Boolean = False
        
        Session("DistrictID") = 55


        Using db As New PromptDataHelper
            Dim tbl As DataTable = db.GetFilteredParentAndUDFDataAsSingleRow("Projects", "ProjectID", "ProjectID", Request.QueryString("ProjectID"))
            For Each rproject In tbl.Rows   'should be only one

                nProjectID = rproject("ProjectID")
                nCollegeID = rproject("CollegeID")
                nDistrictID = rproject("DistrictID")

                strProjectTitle = ProcLib.CheckNullDBField(rproject("bondDisplayTitle"))
                strDescription = ProcLib.CheckNullDBField(rproject("udf_bondProjectDescription"))
                strFundingSource = ProcLib.CheckNullDBField(rproject("udf_bondFundingSource"))
                strCurrentProjectCost = ProcLib.CheckNullDBField(rproject("udf_bondProjectBudget"))
               
                strPercentComplete = ProcLib.CheckNullDBField(rproject("udf_bondPercentComplete"))
                 
                strEstCompleteDate = ProcLib.CheckNullDBField(rproject("udf_bondEstComplete"))
                strLastUpdateOn = FormatDateTime(rproject("LastUpdateOn"), DateFormat.ShortDate)
       
            Next
            
  

               
            Dim sql As String = "SELECT dbo.Colleges.College, LTRIM((CASE WHEN UsePromptName = 0 THEN dbo.Projects.ProjectTitle ELSE dbo.Projects.ProjectName END)) AS Title, "
            sql &= "dbo.Projects.UsePromptName, dbo.Projects.ProjectName, dbo.Projects.ProjectTitle, dbo.Projects.AppriseDescription, dbo.Projects.UsePromptDescr, "
            sql &= "dbo.Projects.FundingSource, dbo.Projects.FundingDescription, dbo.Projects.CurrentProjectCost, dbo.Projects.PercentComplete, dbo.Projects.PublishToWeb, "
            sql &= "dbo.Projects.Description AS ProjectsDescription, dbo.Projects.LastUpdateOn AS AppriseLastUpdate, dbo.Projects.LastUpdateOn AS ProjectsLastUpdate, "
            sql &= "dbo.Projects.ProjectID, dbo.Projects.Status, dbo.Projects.CollegeID, dbo.Projects.DistrictID, dbo.Projects.UsePromptCompletionDate, "
            sql &= "dbo.Projects.HideCompletionDate, dbo.Projects.EstCompleteDate AS PromptEstCompleteDate, dbo.Projects.ProjectNumber, dbo.Projects.OrigBudget AS ProjectBudget,"
            sql &= "dbo.Projects.StartDate, dbo.Projects.HidePercentComplete, dbo.Projects.UsePromptBudget,dbo.Projects.UseManualBudgetAmount , dbo.Projects.ProjectGroupID ,"
            
            sql &= "(SELECT ISNULL(SUM(Amount), 0) AS TotAmount FROM dbo.BudgetItems WHERE BudgetField LIKE '%Bond%' AND ProjectID = Projects.ProjectID) AS ProjectBondTotal "
            sql &= "FROM dbo.Projects INNER JOIN dbo.Colleges ON dbo.Projects.CollegeID = dbo.Colleges.CollegeID "
            sql &= "WHERE dbo.Projects.PublishToWeb = 1 AND Projects.ProjectID = " & nProjectID & " "
            sql &= "ORDER BY dbo.Projects.Status, Title"
                        
            Dim rs1 As DataTable = db.ExecuteDataTable(sql)
            Dim col As DataColumn = New DataColumn("PromptBondTotal", System.Type.GetType("System.Double"))
            rs1.Columns.Add(col)
            
            'Now go through to see if the project is part of a project group and if so, then consolodate the bond amount from all the group projects
            For Each rrow As DataRow In rs1.Rows
                If ProcLib.CheckNullNumField(rrow("ProjectGroupID")) > 0 Then
                    sql = "SELECT ISNULL(SUM(dbo.BudgetItems.Amount), 0) AS TotAmount "
                    sql &= "FROM dbo.BudgetItems INNER JOIN dbo.Projects ON dbo.BudgetItems.ProjectID = dbo.Projects.ProjectID "
                    sql &= "WHERE dbo.Projects.ProjectGroupID = 18 AND dbo.BudgetItems.BudgetField LIKE '%Bond%' "
                    
                    rrow("PromptBondTotal") = db.ExecuteScalar(sql)
                    
                Else
                    rrow("PromptBondTotal") = rrow("ProjectBondTotal")
                End If
                
                strCurrentProjectCost = FormatCurrency(rrow("PromptBondTotal"))
                
            Next

            
            
        End Using
 

        'get main image path
        strImagePath = ProcLib.GetCurrentRelativeAttachmentPath() & "DistrictID_" & nDistrictID & "/_apprisedocs/_photos/ProjectID_" & nProjectID & "/"

        'get physical photo path
        strRealPhotoPath = ProcLib.GetCurrentAttachmentPath()
        strRealPhotoPath = strRealPhotoPath & "DistrictID_" & nDistrictID & "/_apprisedocs/_photos/ProjectID_" & nProjectID & "/"
        Dim filem As New FileInfo(strRealPhotoPath & "main.jpg")
        If filem.Exists Then
            bShowMainPhoto = True
        Else
            bShowMainPhoto = False
        End If

        'Build the table
        tblProject.CellSpacing = 5

        Dim r1 As New TableRow
        Dim r1c1 As New TableCell
        With r1c1
            .Text = strProjectTitle
            .CssClass = "MainProjectTitle"
            .ColumnSpan = 2
            .Height = Unit.Point(20)
            .Width = Unit.Percentage(100)
            .HorizontalAlign = HorizontalAlign.Left
        End With
        r1.Cells.Add(r1c1)
        r1.Width = Unit.Percentage(100)
        tblProject.Rows.Add(r1)

        'add description
        Dim r2 As New TableRow
        Dim r2c1 As New TableCell
        With r2c1
            .Text = strDescription
            .VerticalAlign = VerticalAlign.Top
            .HorizontalAlign = HorizontalAlign.Left
            .Width = Unit.Percentage(50)
            .CssClass = "MainProjectDescription"
        End With
        r2.Cells.Add(r2c1)

        Dim r2c2 As New TableCell    'holder cell for data table
        With r2c2
            .VerticalAlign = VerticalAlign.Top
            .HorizontalAlign = HorizontalAlign.Left
            .CssClass = "MainProjectDescription"
        End With

        '-----------------------------------------
        Dim tblDataTable As New Table  'create the data table to sit in the cell
        tblDataTable.Width = Unit.Percentage(96)

        If bShowMainPhoto Then  'add the photo row
            Dim sr1a As New TableRow
            Dim sr1ac1 As New TableCell
            With sr1ac1
                .VerticalAlign = VerticalAlign.Top
                .HorizontalAlign = HorizontalAlign.Center
                .ColumnSpan = 3
            End With

            'add main image
            Dim ctrlMainImage As New System.Web.UI.WebControls.Image   'dynamically create web control
            With ctrlMainImage
                .ImageUrl = strImagePath & "main.jpg"
            End With
            sr1ac1.Controls.Add(ctrlMainImage)

            sr1a.Cells.Add(sr1ac1)
            tblDataTable.Rows.Add(sr1a)
        End If


        Dim sr1 As New TableRow
        Dim sr1c1 As New TableCell
        Dim sr1c2 As New TableCell

        With sr1c1
            .Text = "Project Budget:"
            .Wrap = False
            .CssClass = "ProjectDataLabel"
            .HorizontalAlign = HorizontalAlign.Left
            .VerticalAlign = VerticalAlign.Top
            .Width = Unit.Percentage(20)
        End With

        With sr1c2
            .Text = strCurrentProjectCost
            .CssClass = "ProjectDataValue"
            .HorizontalAlign = HorizontalAlign.Right
            .ColumnSpan = 2
        End With
        sr1.Cells.Add(sr1c1)
        sr1.Cells.Add(sr1c2)
        tblDataTable.Rows.Add(sr1)


        '-----------------------------------------
        If strPercentComplete <> "" Then

            Dim sr2 As New TableRow
            Dim sr2c1 As New TableCell
            Dim sr2c2 As New TableCell

            With sr2c1
                .Text = "Percent Complete:"
                .Wrap = False
                .CssClass = "ProjectDataLabel"
                .HorizontalAlign = HorizontalAlign.Left
                .VerticalAlign = VerticalAlign.Top
            End With

            With sr2c2
                .Wrap = False
                .HorizontalAlign = HorizontalAlign.Right
                .VerticalAlign = VerticalAlign.Top
            End With
            
            Dim nPercent As Double = Val(strPercentComplete)

            If nPercent = 0 Then
                strPercentImage = ""
            End If
            If nPercent > 0 And nPercent < 13 Then
                strPercentImage = "images/12.gif"
            End If
            If nPercent > 12 And nPercent < 26 Then
                strPercentImage = "images/25.gif"
            End If
            If nPercent > 25 And nPercent < 38 Then
                strPercentImage = "images/37.gif"
            End If
            If nPercent > 37 And nPercent < 51 Then
                strPercentImage = "images/50.gif"
            End If
            If nPercent > 50 And nPercent < 63 Then
                strPercentImage = "images/62.gif"
            End If
            If nPercent > 62 And nPercent < 75 Then
                strPercentImage = "images/75.gif"
            End If
            If nPercent > 75 And nPercent < 88 Then
                strPercentImage = "images/87.gif"
            End If
            If nPercent > 87 Then
                strPercentImage = "images/100.gif"
            End If

            If strPercentImage <> "" Then
                Dim ctrlPercent As New System.Web.UI.WebControls.Image
                With ctrlPercent
                    .ImageUrl = strPercentImage
                End With
                sr2c2.Controls.Add(ctrlPercent)

            End If
            sr2.Cells.Add(sr2c1)
            sr2.Cells.Add(sr2c2)


            Dim sr3ac2 As New TableCell
            With sr3ac2
                .VerticalAlign = VerticalAlign.Top
                .HorizontalAlign = HorizontalAlign.Right
                .Width = Unit.Percentage(30)
            End With

            Dim ctrlPercentText As New Label
            With ctrlPercentText
                .Text = strPercentComplete & "%"
                .CssClass = "ProjectDataValue"
            End With
            sr3ac2.Controls.Add(ctrlPercentText)
            sr2.Cells.Add(sr3ac2)

            tblDataTable.Rows.Add(sr2)
        
        
        End If

        If strEstCompleteDate <> "" Then
            '----------------------------------------- Add Est Complete Date
            Dim sr22 As New TableRow
            Dim sr22c1 As New TableCell
            Dim sr22c2 As New TableCell

            With sr22c1
                .Text = "Est Complete:"
                .Wrap = False
                .CssClass = "ProjectDataLabel"
                .HorizontalAlign = HorizontalAlign.Left
                .VerticalAlign = VerticalAlign.Top
            End With
            With sr22c2
                .Text = strEstCompleteDate
                .CssClass = "ProjectDataValue"
                .HorizontalAlign = HorizontalAlign.Right
                .ColumnSpan = 2
            End With
            sr22.Cells.Add(sr22c1)
            sr22.Cells.Add(sr22c2)
            tblDataTable.Rows.Add(sr22)
        End If
 

        '-----------------------------------------
        Dim sr3 As New TableRow
        Dim sr3c1 As New TableCell
        Dim sr3c2 As New TableCell

        With sr3c1
            .Text = "Funding Source:"
            .Wrap = False
            .CssClass = "ProjectDataLabel"
            .HorizontalAlign = HorizontalAlign.Left
            .VerticalAlign = VerticalAlign.Top
        End With
        With sr3c2
            .Text = strFundingSource
            .CssClass = "ProjectDataValue"
            .HorizontalAlign = HorizontalAlign.Right
            .ColumnSpan = 2
        End With
        sr3.Cells.Add(sr3c1)
        sr3.Cells.Add(sr3c2)
        tblDataTable.Rows.Add(sr3)
        
        
        '-----------------------------------------
        Dim sr3a As New TableRow
        Dim sr3c1a As New TableCell
        Dim sr3c2a As New TableCell

        With sr3c1a
            .Text = "Last Update On:"
            .Wrap = False
            .CssClass = "ProjectDataLabel"
            .HorizontalAlign = HorizontalAlign.Left
            .VerticalAlign = VerticalAlign.Top
        End With
        With sr3c2a
            .Text = strLastUpdateOn
            .CssClass = "ProjectDataValue"
            .HorizontalAlign = HorizontalAlign.Right
            .ColumnSpan = 2
        End With
        sr3a.Cells.Add(sr3c1a)
        sr3a.Cells.Add(sr3c2a)
        tblDataTable.Rows.Add(sr3a)

        '----------------------------------------
        Dim sr4 As New TableRow
        Dim sr4c1 As New TableCell

        sr4c1.Text = strFundingDescription
        sr4c1.ColumnSpan = 3
        sr4c1.CssClass = "ProjectDataValue"
        sr4c1.HorizontalAlign = HorizontalAlign.Right

        sr4.Cells.Add(sr4c1)
        tblDataTable.Rows.Add(sr4)

        '----------------------------------------

        'add the sub table to the main table cell
        r2c2.Controls.Add(tblDataTable)


        r2.Cells.Add(r2c2)
        tblProject.Rows.Add(r2)


        'Check for additional photos and build if needed
        Using db As New PromptDataHelper
            Dim sql As String = "SELECT * FROM ApprisePhotos WHERE ProjectID = " & Request.QueryString("ProjectID") & " AND PostToWeb = 1  ORDER BY Phase,Title"
            Dim tbl As DataTable = db.ExecuteDataTable(sql)

            Dim strLastPhase As String = ""
            Dim strCurrPhase As String = ""
            Dim r3 As New TableRow
            Dim r3c1 As New TableCell
            With r3c1
                .HorizontalAlign = HorizontalAlign.Left
                .ColumnSpan = 2
                .CssClass = "MainProjectDescription"
            End With
            Dim ctrlphoto As New Label   'dynamically create web control
            With ctrlphoto
                .Text = "Photos  "
                .CssClass = "MaroonHeading"
            End With
            r3c1.Controls.Add(ctrlphoto)

            Dim ctrlInfo As New Label   'dynamically create web control
            With ctrlInfo
                .Text = "(Click on photos to view)<br>"
                .CssClass = "smalltext"
            End With
            r3c1.Controls.Add(ctrlInfo)

            Dim i As Integer = 0  'counter to ID the photo records - because we need to do fwd/back we want index number not actual id
            
            For Each prow As DataRow In tbl.Rows
            
                i = i + 1
                strCurrPhase = ProcLib.CheckNullDBField(prow("Phase"))
                If strLastPhase <> strCurrPhase Then
                    i = 1
                    'add description
                    Dim ctrlTitle As New Label
                    With ctrlTitle
                        .Text = "<br>" & strCurrPhase & "<br>"
                        .CssClass = "ProjectDataValue"
                    End With
                    r3c1.Controls.Add(ctrlTitle)
                    strLastPhase = strCurrPhase
                End If
                'add image
                Dim ctrlImage As New System.Web.UI.WebControls.Image   'dynamically create web control
                With ctrlImage
                    .Attributes.Add("onclick", "window.open('fhda_photo_view.aspx?PhotoID=" & prow("ApprisePhotoID") & "&Phase=" & strCurrPhase & "&ProjectID=" & prow("ProjectID") & "&ID=" & i & "',null,'height=450, width=450,status= no, resizable= yes, scrollbars=no, toolbar=no,location=no,menubar=no ');")
                    .ImageUrl = strImagePath & prow("ApprisePhotoID") & ".jpg"
                    .Height = Unit.Pixel(45)
                    .Width = Unit.Pixel(45)
                End With
                r3c1.Controls.Add(ctrlImage)

                Dim ctrlSpacer As New Label   'dynamically create web control
                With ctrlSpacer
                    .Text = "&nbsp;&nbsp;"
                End With
                r3c1.Controls.Add(ctrlImage)
                r3c1.Controls.Add(ctrlSpacer)

            Next
            
            r3.Cells.Add(r3c1)
            tblProject.Rows.Add(r3)  'add row

        End Using

    End Sub







</script>

<html>
<head>
    <title>project_view</title>
    <link href="stylesFHDAbond.css" type="text/css" rel="stylesheet" />
</head>
<body bgcolor="lightsteelblue" bgproperties="fixed">
    <form id="Form1" method="post" runat="server">
    <asp:Table ID="tblProject" Style="z-index: 104; left: 8px; position: absolute; top: 8px"
        runat="server" Height="8px" Width="96%">
    </asp:Table>
    </form>
</body>
</html>

