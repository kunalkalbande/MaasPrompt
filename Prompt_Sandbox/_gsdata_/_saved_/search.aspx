<%@ Page Language="vb" %>
<%@ Import Namespace="Prompt" %>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">
<script runat="server">
    Private Sub Page_Load(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MyBase.Load


        If Not IsPostBack Then   'build the search criteria form

            Dim txtSearch As New TextBox
            Dim butSearch As New ImageButton
            With butSearch
                .ID = "butSearch"
                .ImageUrl = "images/button_search.gif"
                .TabIndex = 1
            End With

            Dim butClose As New HyperLink
            With butClose
                .Attributes.Add("onclick", "self.close();")
                .ID = "butClose"
                .ImageUrl = "images/button_close.gif"
                .TabIndex = 1
            End With

            With tblSearch
                .Rows.Clear()
                .Width = Unit.Percentage(95)
            End With

            'add first row
            Dim r1 As New TableRow
            Dim r1c1 As New TableCell

            With r1c1
                .Text = "To Search all Notes fields for text, please enter Search Criteria:"
                .HorizontalAlign = HorizontalAlign.Left
                .CssClass = "smalltext"
                .ColumnSpan = 2
            End With
            r1.Cells.Add(r1c1)
            tblSearch.Rows.Add(r1)
            

            'add criteria textbox
            Dim r2 As New TableRow
            Dim r2c1 As New TableCell

            With txtSearch
                .ID = "txtSearch"
                .Width = Unit.Point(200)
                .TabIndex = 0
                .CssClass = "ViewDataDisplay"
            End With

            With r2c1
                .Controls.Add(txtSearch)
                .ColumnSpan = 2
            End With

            r2.Cells.Add(r2c1)
            tblSearch.Rows.Add(r2)

            'add option buttons
            Dim r31 As New TableRow
            Dim r31c1 As New TableCell

            Dim optKeywords As New CheckBox
            With optKeywords
                .Checked = False
                .ID = "chkKeywordsOnly"
                .TabIndex = 4
                .Text = "Search Contractor Keywords Only"
                .CssClass = "SmallText"
            End With
            With r31c1
                .ColumnSpan = 2
                .Controls.Add(optKeywords)
                .HorizontalAlign = HorizontalAlign.Left
            End With

            r31.Cells.Add(r31c1)
            tblSearch.Rows.Add(r31)

            'add Seacrh and Close Buttons
            Dim r3 As New TableRow
            Dim r3c1 As New TableCell
            Dim r3c2 As New TableCell

            With r3c1
                .Height = Unit.Pixel(35)
                .Controls.Add(butSearch)
                .HorizontalAlign = HorizontalAlign.Left
            End With

            With r3c2
                .Controls.Add(butClose)
                .HorizontalAlign = HorizontalAlign.Left
            End With

            r3.Cells.Add(r3c1)
            r3.Cells.Add(r3c2)
            tblSearch.Rows.Add(r3)

            '            SetFocus(Page, "txtSearch")


        Else            'do the Search

            PerformSearch()


        End If

    End Sub

    Private Sub PerformSearch()

        ''Get the result set for contract 
        'Dim sSearch As String = Request.Form("txtSearch")

        'With tblSearch
        '    .Rows.Clear()
        '    .Width = Unit.Percentage(98)
        'End With
        ''add first row
        'Dim r1 As New TableRow
        'Dim r1c1 As New TableCell

        'With r1c1
        '    .Text = "Results: <br><hr size=1>"
        '    .HorizontalAlign = HorizontalAlign.Left
        '    .CssClass = "smalltext"
        '    .Width = Unit.Percentage(98)
        'End With
        'r1.Cells.Add(r1c1)
        'tblSearch.Rows.Add(r1)
        
        'Dim rs As DataTable
        
        'Using db As New promptSearch
        '    db.CallingPage = Page
        '    If Request.Form("chkKeywordsOnly") <> "" Then
        '        rs = db.PerformSearch(sSearch, True)
        '    Else
        '        rs = db.PerformSearch(sSearch, False)
        '    End If
        'End Using

        'If rs.Rows.Count > 0 Then

        '    Dim i As Integer = 0
        '    FOr each
        '        i = i + 1
        '        'Show Result
        '        Dim r2 As New TableRow
        '        Dim r2c1 As New TableCell
        '        Dim ctrlResult1 As New Label
        '        With ctrlResult1
        '            .ID = "lnkResult1" & i
        '            .Text = rs.Reader("Source")
        '            .CssClass = "SmallText"
        '        End With

        '        Dim ctrlResult2 As New HyperLink
        '        With ctrlResult2
        '            .ID = "lnkResult2" & i
        '            .Text = "<br>" & rs.Reader("Description") & "<hr=size=1>"
        '            .CssClass = "ViewDataDisplay"
        '        End With

        '        With r2c1
        '            .Controls.Add(ctrlResult1)
        '            .Controls.Add(ctrlResult2)
        '        End With

        '        r2.Cells.Add(r2c1)
        '        tblSearch.Rows.Add(r2)
        '    End While
        'Else
        '        Dim r2 As New TableRow
        '        Dim r2c1 As New TableCell
        '        Dim ctrlResult1 As New Label
        '        With ctrlResult1
        '            .ID = "lnkResult1"
        '            .Text = "Sorry, no records found with that criteria."
        '            .CssClass = "ViewDataDisplay"
        '        End With
        '        r2c1.Controls.Add(ctrlResult1)
        '        r2.Cells.Add(r2c1)
        '        tblSearch.Rows.Add(r2)
        'End If

        'rs.Close()


        ''add Close Buttons
        'Dim r3 As New TableRow
        'Dim r3c1 As New TableCell

        'Dim ctrlResult3 As New Label
        'With ctrlResult3
        '    .ID = "lnkResult3"
        '    .Text = "<hr size=1>"
        'End With

        'Dim butClose As New HyperLink
        'With butClose
        '    .Attributes.Add("onclick", "self.close();")
        '    .ID = "butClose"
        '    .ImageUrl = "images/button_close.gif"
        '    .TabIndex = 1
        'End With

        'With r3c1
        '    .Controls.Add(ctrlResult3)
        '    .Controls.Add(butClose)
        '    .HorizontalAlign = HorizontalAlign.Left
        'End With

        'r3.Cells.Add(r3c1)
        'tblSearch.Rows.Add(r3)

    End Sub
</script>
<HTML>
	<HEAD>
		<title>search</title>
		<meta content="Microsoft Visual Studio .NET 7.1" name="GENERATOR">
		<meta content="Visual Basic .NET 7.1" name="CODE_LANGUAGE">
		<meta content="JavaScript" name="vs_defaultClientScript">
		<meta content="http://schemas.microsoft.com/intellisense/ie5" name="vs_targetSchema">
		<LINK href="Styles.css" type="text/css" rel="stylesheet">
	</HEAD>
	<body>
		<form id="Form1" method="post" runat="server">
			<asp:table id="tblSearch" style="Z-INDEX: 101; LEFT: 16px; POSITION: absolute; TOP: 8px" runat="server"></asp:table></form>
	</body>
</HTML>
