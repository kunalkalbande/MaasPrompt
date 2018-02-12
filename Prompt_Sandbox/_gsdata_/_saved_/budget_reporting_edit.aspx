<%@ Page Language="vb" %>

<%@ Import Namespace="Prompt" %>
<%@ Register Assembly="Telerik.Web.UI" Namespace="Telerik.Web.UI" TagPrefix="telerik" %>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">

<script runat="server">
    Private nProjectID As Integer
    Private Sub Page_Load(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MyBase.Load

        ProcLib.LoadPopupJscript(Page)

        'set up help button
        Session("PageID") = "Budget_Reporting_Edit"
        butHelp.Attributes.Add("onclick", "openPopup('help_view.aspx','pophelp',550,450,'yes');")
        butHelp.NavigateUrl = "#"

        nProjectID = Request.QueryString("ProjectID")

        If Not IsPostBack Then

            ProcLib.VerifyBudgetReportingTable(nProjectID)

            With tbl1
                .Rows.Clear()
                .Width = Unit.Percentage(95)
            End With


            'build header row
            Dim r2 As New TableRow
            Dim r2c1 As New TableCell
            Dim r2c2 As New TableCell
            Dim r2c3 As New TableCell
            Dim r2c4 As New TableCell   'padding

            r2c1.Width = Unit.Percentage(20)
            r2c1.Text = "Month/Year"
            r2c1.HorizontalAlign = HorizontalAlign.Center
            r2.Cells.Add(r2c1)

            r2c2.Width = Unit.Percentage(10)
            r2c2.Text = "Budget"
            r2c2.HorizontalAlign = HorizontalAlign.Right
            r2.Cells.Add(r2c2)

            'r2c3.Width = Unit.Percentage(10)
            'r2c3.Text = "Actual"
            'r2c3.HorizontalAlign = HorizontalAlign.Right
            'r2.Cells.Add(r2c3)

            r2c4.Width = Unit.Percentage(80)
            r2.Cells.Add(r2c4)

            r2.CssClass = "smalltext"
            r2.BackColor = Color.Silver

            tbl1.Rows.Add(r2)

            Using rs As New PromptDataHelper
                           
                rs.FillReader("SELECT * FROM BudgetReporting WHERE ProjectID = " & nProjectID & " ORDER BY ReportingDate ")
                
                While rs.Reader.Read()

                    'build detail row
                    Dim r4 As New TableRow
                    Dim r4c1 As New TableCell
                    Dim r4c2 As New TableCell
                    Dim r4c3 As New TableCell
                    Dim r4c4 As New TableCell   'padding

                    Dim sDate As DateTime = rs.Reader("ReportingDate")
                    With r4c1
                        .Text = sDate.ToString("MMM-yyyy")
                        .ForeColor = Color.DarkBlue
                        .CssClass = "CurrencyTextBox"
                        .HorizontalAlign = HorizontalAlign.Left
                    End With
                    With r4c2
                        .Text = rs.Reader("Budget")
                        .ForeColor = Color.DarkBlue
                        .HorizontalAlign = HorizontalAlign.Right
                    End With

                    'With r4c3
                    '    .Text = rs.Reader("Actual")
                    '    .ForeColor = Color.DarkBlue
                    '    .HorizontalAlign = HorizontalAlign.Right
                    'End With


                    Dim ctrlBudget As New RadNumericTextBox 'create text box and fill with current value
                    With ctrlBudget
                        .ID = "txtBudget" & rs.Reader("PrimaryKey")
                        .Width = Unit.Point(100)
                        .TabIndex = 99
                    
                        .Skin = "Vista"
                        .SelectionOnFocus = SelectionOnFocus.SelectAll
                        .NumberFormat.AllowRounding = True
                        .NumberFormat.DecimalDigits = "2"
                        .NumberFormat.PositivePattern = "$ n"
                                       
                        If rs.Reader("Budget") = 0 Then
                            .Text = ""
                        Else
                            .Text = FormatNumber(rs.Reader("Budget"), 2, TriState.False, TriState.False, TriState.True)
                        End If
                    

                    End With
                
  
                    With r4c2
                        .Controls.Add(ctrlBudget)
                        .HorizontalAlign = HorizontalAlign.Right
                    End With


                    'With r4c3
                    '    .Controls.Add(ctrlActual)
                    '    .HorizontalAlign = HorizontalAlign.Right
                    'End With

                    With r4.Cells
                        .Add(r4c1)
                        .Add(r4c2)
                        '.Add(r4c3)
                        .Add(r4c4)
                    End With

                    tbl1.Rows.Add(r4)

                End While
                rs.Reader.Close()
            End Using
            'build save button
            Dim r5 As New TableRow
            Dim r5c1 As New TableCell

            Dim ctrlSave As New System.Web.UI.WebControls.ImageButton
            With ctrlSave
                .ID = "butSave"
                .TabIndex = 99
                .ImageUrl = "images/button_save.gif"
            End With

            r5c1.ColumnSpan = 4
            r5c1.Controls.Add(ctrlSave)

            r5.Cells.Add(r5c1)
            tbl1.Rows.Add(r5)

        End If
        'txtM1Budget.focus()
    End Sub
    
    Private Sub butSave_Click(ByVal sender As System.Object, ByVal e As System.Web.UI.ImageClickEventArgs) Handles butSave.Click
        
        Using rs As New promptBudget
            rs.CallingPage = Page
            rs.SaveBudgetReportingEstimates(0, nProjectID)
            
        End Using
        Session("RtnFromEdit") = True
        ProcLib.CloseAndRefresh(Page)
    End Sub


</script>

<html>
<head>
    <title>budget_reporting_edit</title>
     <link href="Styles.css" type="text/css" rel="stylesheet" />
</head>
<body>
<form id="Form1" method="post" runat="server">
     <telerik:RadScriptManager ID="RadScriptManager1" runat="server" />
    <asp:ImageButton ID="butSave" Style="z-index: 102; left: 16px; position: absolute;
        top: 120px" TabIndex="40" runat="server" ImageUrl="images/button_save.gif" Visible="False">
    </asp:ImageButton>
    <table id="Table1" style="z-index: 103; left: 8px; position: absolute; top: 8px;
        height: 28px" height="28" cellspacing="1" cellpadding="1" width="96%" border="0">
        <tr height="1">
            <td valign="top" height="6">
                <asp:Label ID="Label17" runat="server" EnableViewState="False" CssClass="PageHeading"
                    Height="24px">Edit Budget Reporting</asp:Label>
            </td>
            <td valign="top" align="right" height="6">
                <asp:HyperLink ID="butHelp" runat="server" ImageUrl="images/button_help.gif">HyperLink</asp:HyperLink>
            </td>
        </tr>
    </table>
    <hr style="z-index: 101; left: 8px; position: absolute; top: 40px; height: 1px" width="96%"
        size="1">
    <asp:Table ID="tbl1" Style="z-index: 105; left: 16px; position: absolute; top: 56px"
        runat="server">
    </asp:Table>
    </form>
</body>
</html>
