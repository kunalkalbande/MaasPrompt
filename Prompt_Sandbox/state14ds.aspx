<%@ Page Language="VB" MasterPageFile="~/content.master" Title="" %>
<%@ Register Assembly="Telerik.Web.UI" Namespace="Telerik.Web.UI" TagPrefix="telerik" %>
<%@ Import Namespace="Prompt" %>

<script runat="server">
    
    Private ProjectID As Integer = 0
    
   
    Private Sub Page_Load(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MyBase.Load

        ProcLib.CheckSession(Page)
        ProcLib.LoadPopupJscript(Page)

        ''set up help button
        Session("PageID") = "State14Ds"
        ProjectID = Request.QueryString("ProjectID")
  
        
        Dim masterTabs As RadTabStrip = Master.FindControl("tabMain")
        Session("CurrentTab") = "State14D"
        For Each radTab In masterTabs.GetAllTabs
            If radTab.Value = "State14D" Then
                radTab.Selected = True
                radTab.SelectParents()
                Exit For
            End If
        Next
        
        tblShow.Rows.Clear()
        tblShow.Width = Unit.Percentage(98)
		tblShow.CssClass = "notes_tb"
        'Sets the security constraints for current page
        Using db As New EISSecurity
            db.CollegeID = Session("CollegeID")
            db.ProjectID = ProjectID
            If db.FindUserPermission("State14D", "Write") Then

                Dim r1 As New TableRow
                Dim r1c1 As New TableCell

                Dim ctrlEditSubmittal As New HyperLink
                With ctrlEditSubmittal
                    .Attributes.Add("onclick", "openPopup('state14d_edit.aspx?ProjectID=" & ProjectID & "','editSubm',550,350,'yes');")
                    .ID = "butEdit"
                    .ImageUrl = "images/button_edit.gif"
                    .NavigateUrl = "#"
                End With


                'Add the control to the table cell
                With r1c1
                    .Controls.Add(ctrlEditSubmittal)
                    .ColumnSpan = 5
                    .HorizontalAlign = HorizontalAlign.Left
                End With
                r1.Cells.Add(r1c1)

                tblShow.Rows.Add(r1)
            End If

        End Using
        
        'build header row
        Dim r2 As New TableRow
        Dim r2c1 As New TableHeaderCell
        Dim r2c2 As New TableHeaderCell
        Dim r2c22 As New TableHeaderCell
        Dim r2c3 As New TableHeaderCell
        Dim r2c4 As New TableHeaderCell


        r2c1.Text = "Chancellors Office"
        r2c1.HorizontalAlign = HorizontalAlign.Left

        r2c2.Text = "14D"
        r2c2.HorizontalAlign = HorizontalAlign.Left

        r2c22.Text = "Budget Number"
        r2c22.HorizontalAlign = HorizontalAlign.Left

        r2c3.Text = "Release Date"
        r2c3.HorizontalAlign = HorizontalAlign.Left

        r2c4.Text = "Amount Released"
        r2c4.HorizontalAlign = HorizontalAlign.Right

        With r2
            .Cells.Add(r2c1)
            .Cells.Add(r2c2)
            .Cells.Add(r2c22)
            .Cells.Add(r2c3)
            .Cells.Add(r2c4)
        End With

        tblShow.Rows.Add(r2)

        'get the submittal data
        Using rs As New PromptDataHelper
            rs.FillReader("SELECT * FROM Projects WHERE ProjectID = " & ProjectID)
            While rs.Reader.Read()

                Dim r3 As New TableRow

                Dim r3c1 As New TableCell
                Dim r3c2 As New TableCell

                With r3c1
                    .Text = "Initial Submittal: <span class='blue'>" & ProcLib.CheckNullDBField(rs.Reader("CCCCO_SubmittalDate")) & "</span>"
                    .CssClass = "smalltext"
                    .ColumnSpan = 5
                    .HorizontalAlign = HorizontalAlign.Left
                End With

                r3.Cells.Add(r3c1)
                tblShow.Rows.Add(r3)

                'add prelim row
                Dim r4 As New TableRow
				r4.CssClass = "alt"

                Dim r4c1 As New TableCell
                Dim r4c2 As New TableCell
                Dim r4c22 As New TableCell
                Dim r4c3 As New TableCell
                Dim r4c4 As New TableCell

                r4c1.Text = "Prelim:"
                r4c1.CssClass = "smalltext"
                r4c1.HorizontalAlign = HorizontalAlign.Left

                r4c2.Text = ProcLib.CheckNullDBField(rs.Reader("CCCCO_Prelim_14D"))
                If r4c2.Text = "1" Then
                    r4c2.Text = "Y"
                Else
                    r4c2.Text = " "
                End If
                r4c2.CssClass = "ViewDataDisplay"

                r4c22.Text = ProcLib.CheckNullDBField(rs.Reader("CCCCO_Prelim_BudgetNumber"))
                r4c22.CssClass = "ViewDataDisplay"

                r4c3.Text = ProcLib.CheckNullDBField(rs.Reader("CCCCO_Prelim_ReleaseDate"))
                r4c3.CssClass = "ViewDataDisplay"

                r4c4.Text = FormatCurrency(ProcLib.CheckNullNumField(rs.Reader("CCCCO_Prelim_AmountReleased")))
                r4c4.CssClass = "ViewDataDisplay"
                r4c4.HorizontalAlign = HorizontalAlign.Right

                With r4
                    .Cells.Add(r4c1)
                    .Cells.Add(r4c2)
                    .Cells.Add(r4c22)
                    .Cells.Add(r4c3)
                    .Cells.Add(r4c4)
                End With
                tblShow.Rows.Add(r4)

                '---------------  Work Drawings
                Dim r5 As New TableRow

                Dim r5c1 As New TableCell
                Dim r5c2 As New TableCell
                Dim r5c22 As New TableCell
                Dim r5c3 As New TableCell
                Dim r5c4 As New TableCell

                r5c1.Text = "Working Drawings:"
                r5c1.CssClass = "smalltext"
                r5c1.HorizontalAlign = HorizontalAlign.Left

                r5c2.Text = ProcLib.CheckNullDBField(rs.Reader("CCCCO_WD_14D"))
                If r5c2.Text = "1" Then
                    r5c2.Text = "Y"
                Else
                    r5c2.Text = " "
                End If
                r5c2.CssClass = "ViewDataDisplay"

                r5c22.Text = ProcLib.CheckNullDBField(rs.Reader("CCCCO_WD_BudgetNumber"))
                r5c22.CssClass = "ViewDataDisplay"


                r5c3.Text = ProcLib.CheckNullDBField(rs.Reader("CCCCO_WD_ReleaseDate"))
                r5c3.CssClass = "ViewDataDisplay"

                r5c4.Text = FormatCurrency(ProcLib.CheckNullNumField(rs.Reader("CCCCO_WD_AmountReleased")))
                r5c4.CssClass = "ViewDataDisplay"
                r5c4.HorizontalAlign = HorizontalAlign.Right

                With r5
                    .Cells.Add(r5c1)
                    .Cells.Add(r5c2)
                    .Cells.Add(r5c22)
                    .Cells.Add(r5c3)
                    .Cells.Add(r5c4)
                End With
                tblShow.Rows.Add(r5)

                '----------------- Construction

                Dim r6 As New TableRow
				r6.CssClass = "alt"

                Dim r6c1 As New TableCell
                Dim r6c2 As New TableCell
                Dim r6c22 As New TableCell
                Dim r6c3 As New TableCell
                Dim r6c4 As New TableCell

                r6c1.Text = "Construction:"
                r6c1.HorizontalAlign = HorizontalAlign.Left

                r6c2.Text = ProcLib.CheckNullDBField(rs.Reader("CCCCO_Const_14D"))
                If r6c2.Text = "1" Then
                    r6c2.Text = "Y"
                Else
                    r6c2.Text = " "
                End If

                r6c22.Text = ProcLib.CheckNullDBField(rs.Reader("CCCCO_Const_BudgetNumber"))

                r6c3.Text = ProcLib.CheckNullDBField(rs.Reader("CCCCO_Const_ReleaseDate"))

                r6c4.Text = FormatCurrency(ProcLib.CheckNullNumField(rs.Reader("CCCCO_Const_AmountReleased")))
                r6c4.HorizontalAlign = HorizontalAlign.Right

                With r6
                    .Cells.Add(r6c1)
                    .Cells.Add(r6c2)
                    .Cells.Add(r6c22)
                    .Cells.Add(r6c3)
                    .Cells.Add(r6c4)
                End With
                tblShow.Rows.Add(r6)


                '----------------- Equipment

                Dim r7 As New TableRow

                Dim r7c1 As New TableCell
                Dim r7c2 As New TableCell
                Dim r7c22 As New TableCell
                Dim r7c3 As New TableCell
                Dim r7c4 As New TableCell

                r7c1.Text = "Equipment:"
                r7c1.HorizontalAlign = HorizontalAlign.Left

                r7c2.Text = ProcLib.CheckNullDBField(rs.Reader("CCCCO_Equip_14D"))
                If r7c2.Text = "1" Then
                    r7c2.Text = "Y"
                Else
                    r7c2.Text = " "
                End If

                r7c22.Text = ProcLib.CheckNullDBField(rs.Reader("CCCCO_Equip_BudgetNumber"))

                r7c3.Text = ProcLib.CheckNullDBField(rs.Reader("CCCCO_Equip_ReleaseDate"))

                r7c4.Text = FormatCurrency(ProcLib.CheckNullNumField(rs.Reader("CCCCO_Equip_AmountReleased")))
                r7c4.HorizontalAlign = HorizontalAlign.Right

                With r7
                    .Cells.Add(r7c1)
                    .Cells.Add(r7c2)
                    .Cells.Add(r7c22)
                    .Cells.Add(r7c3)
                    .Cells.Add(r7c4)
                End With
                tblShow.Rows.Add(r7)

            End While

            rs.Reader.Close()
        End Using

    End Sub

</script>

<asp:Content ID="Content1" ContentPlaceHolderID="mainBody" runat="Server">
<div id="contentwrapper"><div class="innertube">
<asp:table id="tblShow" runat="server"></asp:table></div></div>
</asp:Content>
