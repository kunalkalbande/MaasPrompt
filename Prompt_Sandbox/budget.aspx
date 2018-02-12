<%@ Page Language="VB" MasterPageFile="~/content.master" Title="" %>

<%@ Register Assembly="Telerik.Web.UI" Namespace="Telerik.Web.UI" TagPrefix="telerik" %>
<%@ Import Namespace="Prompt" %>
<%@ Import Namespace="System.Data.SqlClient" %>
<%@ Import Namespace="System.Configuration" %>

<script runat="server">
    
    Private bReadOnly As Boolean = True
    Private nProjectID As Integer = 0
    Private nCollegeID As Integer = 0
       
    Private rsBudget As New DataTable
    
    Private Sub Page_Load(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MyBase.Load

        ProcLib.CheckSession(Page)
        ProcLib.LoadPopupJscript(Page)

        ''set up help button
        Session("PageID") = "BudgetView"
        nProjectID = Request.QueryString("ProjectID")
        
         
        Dim masterTabs As RadTabStrip = Master.FindControl("tabMain")
        Session("CurrentTab") = "Budget"
        For Each radTab In masterTabs.GetAllTabs
            If radTab.Value = "Budget" Then
                radTab.Selected = True
                radTab.SelectParents()
                Exit For
            End If
        Next
        
        With contentPopup
            .Skin = "Windows7"
            .VisibleOnPageLoad = False
            Dim ww As New RadWindow
            With ww
                .ID = "HoverWindow"
                .NavigateUrl = ""
                .Title = ""
                .Width = 250
                .Height = 250
                .VisibleStatusbar = False
                .ReloadOnShow = True
            End With
            .Windows.Add(ww)
            
            ww = New RadWindow
            With ww
                .ID = "SettingsWindow"
                .NavigateUrl = ""
                .Title = ""
                .Width = 250
                .Height = 300
                .VisibleStatusbar = False
                .ReloadOnShow = True
            End With
            .Windows.Add(ww)
            
            ww = New RadWindow
            With ww
                .ID = "BudgetItemsEditWindow"
                .NavigateUrl = ""
                .Title = "JCAF Budget Items"
                .Width = 725
                .Height = 350
                .VisibleStatusbar = False
                .ReloadOnShow = True
                .Behaviors = WindowBehaviors.Close + WindowBehaviors.Move
            End With
            .Windows.Add(ww)
         
        End With
        
        
        lnkPageConfig.Attributes("onclick") = "return EditSettings();"
                
        'Populate the Budget table object with exisiting budget items - since we are storing the items only if
        'they have values (to keep data size down), we need to build a flat file from the template file (adding values from exsisting items where they
        'exist) to populate the form with. We build a temp table object rsBudget and populate it.

        'Get the custom JCAF column name if any
        Dim rowHeader As TableRow = tblBudget.Rows(0)
        Using db1 As New PromptDataHelper
            db1.FillReader("SELECT * FROM Districts WHERE DistrictID = " & Session("DistrictID"))
            While db1.Reader.Read
                If Not IsDBNull(db1.Reader("JCAFDonationColumnName")) Then
                    If db1.Reader("JCAFDonationColumnName") <> "" Then
                        For Each cell As TableCell In rowHeader.Cells
                            If InStr(cell.ID, "Donation") > 0 Then
                                cell.Text = db1.Reader("JCAFDonationColumnName")
                            End If
                        Next
                        
                    End If
                End If
                If Not IsDBNull(db1.Reader("JCAFGrantColumnName")) Then
                    If db1.Reader("JCAFGrantColumnName") <> "" Then
                        For Each cell As TableCell In rowHeader.Cells
                            If InStr(cell.ID, "Grant") > 0 Then
                                cell.Text = db1.Reader("JCAFGrantColumnName")
                            End If
                        Next
                       
                    End If
                End If
                If Not IsDBNull(db1.Reader("JCAFHazmatColumnName")) Then
                    If db1.Reader("JCAFHazmatColumnName") <> "" Then
                        For Each cell As TableCell In rowHeader.Cells
                            If InStr(cell.ID, "Hazmat") > 0 Then
                                cell.Text = db1.Reader("JCAFHazmatColumnName")
                            End If
                        Next
                       
                    End If
                End If
                If Not IsDBNull(db1.Reader("JCAFMaintColumnName")) Then
                    If db1.Reader("JCAFMaintColumnName") <> "" Then
                        For Each cell As TableCell In rowHeader.Cells
                            If InStr(cell.ID, "Maint") > 0 Then
                                cell.Text = db1.Reader("JCAFMaintColumnName")
                            End If
                        Next
                        
                    End If
                End If
            End While
        End Using
        
        Using rs As New PromptDataHelper

            rs.FillReader("SELECT * FROM BudgetFieldsTable ")

            'add the columns to the table
            While rs.Reader.Read()
                Dim cc1 As New DataColumn(rs.Reader("ColumnName"), GetType(Double))   'add the budget column 
                cc1.DefaultValue = 0
                rsBudget.Columns.Add(cc1)

                Dim cc2 As New DataColumn("NOTES" & rs.Reader("ColumnName"), GetType(String))  'add the Notes column for this BudgetItem
                rsBudget.Columns.Add(cc2)
            
                Dim cc3 As New DataColumn("CHANGES" & rs.Reader("ColumnName"), GetType(String))  'add the Changes column for this BudgetItem
                rsBudget.Columns.Add(cc3)
            
            End While
            rs.Reader.Close()
 
            Dim rr As DataRow
            rr = rsBudget.NewRow()
            
            'get a table with those fields that have changes to flag history icon
            Dim dtChanges As DataTable = rs.ExecuteDataTable("SELECT DISTINCT(JCAFColumnName) FROM JCAFCHangeLog WHERE ProjectID = " & nProjectID)

            'Now populate the row with amount data
            rs.FillReader("SELECT CollegeID,BudgetField, Amount, Note FROM BudgetItems WHERE ProjectID = " & nProjectID)
            While rs.Reader.Read()
                'Store the collegeID while we are here for JCAF Generator
                nCollegeID = rs.Reader("CollegeID")

                If rs.Reader("Amount") > 0 Then
                    rr.Item(rs.Reader("BudgetField")) = rs.Reader("Amount")  'add the amount for this field
                Else
                    rr.Item(rs.Reader("BudgetField")) = 0
                End If
                If Not IsDBNull(rs.Reader("Note")) Then
                    rr.Item("NOTES" & rs.Reader("BudgetField")) = rs.Reader("Note")  'add the note for this field
                Else
                    rr.Item("NOTES" & rs.Reader("BudgetField")) = ""
                End If
            
                'Check for changelog entries
                For Each r As DataRow In dtChanges.Rows
                    If r("JCAFColumnName") = rs.Reader("BudgetField") Then
                        rr.Item("CHANGES" & rs.Reader("BudgetField")) = "T"  'flag that the item has changes
                    End If
                Next
            
            End While
            rs.Reader.Close()
            dtChanges.Dispose()
        

            'set up the JCAF Generator Link
            lnkJCAFGenerator.Attributes.Add("onclick", "openPopup('JCAFGenerator.aspx?ProjectID=" & nProjectID & "&CollegeID=" & nCollegeID & "','jcafgen',600,750,'yes');")
            lnkJCAFGenerator.NavigateUrl = "#"

            'set up the Budget REporting Edit Link
            lnkBudgetReporting.Attributes.Add("onclick", "openPopup('Budget_Reporting_edit.aspx?ProjectID=" & nProjectID & "','budrep',600,550,'yes');")
            lnkBudgetReporting.NavigateUrl = "#"
        
            'set up the Budget Estimates Edit Link
            lnkEstimates.Attributes.Add("onclick", "openPopup('budget_estimate_to_complete_list.aspx?ProjectID=" & nProjectID & "','estrep',675,530,'yes');")
            lnkEstimates.NavigateUrl = "#"
        
            'set up the Budget Assumptions Link
            lnkBudgetAssumptionsEdit.Attributes.Add("onclick", "openPopup('BudgetAssumptions_edit.aspx?ProjectID=" & nProjectID & "','budass',580,400,'yes');")
            lnkBudgetAssumptionsEdit.NavigateUrl = "#"
        
  

            'Aggregate the "Other" subitems into a summary item for ease 
            Dim nTotalSiteAquOther As Double = rr.Item("SiteAquOther_Grant") + rr.Item("SiteAquOther_Donation") + rr.Item("SiteAquOther_Maint") + rr.Item("SiteAquOther_Hazmat")
            Dim nTotalPlanOther_A As Double = rr.Item("PlanOther_A_Grant") + rr.Item("PlanOther_A_Donation") + rr.Item("PlanOther_A_Maint") + rr.Item("PlanOther_A_Hazmat")
            Dim nTotalPlanOther_B As Double = rr.Item("PlanOther_B_Grant") + rr.Item("PlanOther_B_Donation") + rr.Item("PlanOther_B_Maint") + rr.Item("PlanOther_B_Hazmat")
            Dim nTotalPlanOther_C As Double = rr.Item("PlanOther_C_Grant") + rr.Item("PlanOther_C_Donation") + rr.Item("PlanOther_C_Maint") + rr.Item("PlanOther_C_Hazmat")
            Dim nTotalPlanOther_D As Double = rr.Item("PlanOther_D_Grant") + rr.Item("PlanOther_D_Donation") + rr.Item("PlanOther_D_Maint") + rr.Item("PlanOther_D_Hazmat")
            Dim nTotalWorkDrawOther_A As Double = rr.Item("WorkDrawOther_A_Grant") + rr.Item("WorkDrawOther_A_Donation") + rr.Item("WorkDrawOther_A_Maint") + rr.Item("WorkDrawOther_A_Hazmat")
            Dim nTotalWorkDrawOther_B As Double = rr.Item("WorkDrawOther_B_Grant") + rr.Item("WorkDrawOther_B_Donation") + rr.Item("WorkDrawOther_B_Maint") + rr.Item("WorkDrawOther_B_Hazmat")
            Dim nTotalWorkDrawOther_C As Double = rr.Item("WorkDrawOther_C_Grant") + rr.Item("WorkDrawOther_C_Donation") + rr.Item("WorkDrawOther_C_Maint") + rr.Item("WorkDrawOther_C_Hazmat")
            Dim nTotalWorkDrawOther_D As Double = rr.Item("WorkDrawOther_D_Grant") + rr.Item("WorkDrawOther_D_Donation") + rr.Item("WorkDrawOther_D_Maint") + rr.Item("WorkDrawOther_D_Hazmat")
            Dim nTotalWorkDrawOther_E As Double = rr.Item("WorkDrawOther_E_Grant") + rr.Item("WorkDrawOther_E_Donation") + rr.Item("WorkDrawOther_E_Maint") + rr.Item("WorkDrawOther_E_Hazmat")
            Dim nTotalConstrOther_A As Double = rr.Item("ConstrOther_A_Grant") + rr.Item("ConstrOther_A_Donation") + rr.Item("ConstrOther_A_Maint") + rr.Item("ConstrOther_A_Hazmat")
            Dim nTotalConstrOther_B As Double = rr.Item("ConstrOther_B_Grant") + rr.Item("ConstrOther_B_Donation") + rr.Item("ConstrOther_B_Maint") + rr.Item("ConstrOther_B_Hazmat")
            Dim nTotalConstrOther_C As Double = rr.Item("ConstrOther_C_Grant") + rr.Item("ConstrOther_C_Donation") + rr.Item("ConstrOther_C_Maint") + rr.Item("ConstrOther_C_Hazmat")
            Dim nTotalConstrOther_D As Double = rr.Item("ConstrOther_D_Grant") + rr.Item("ConstrOther_D_Donation") + rr.Item("ConstrOther_D_Maint") + rr.Item("ConstrOther_D_Hazmat")
            Dim nTotalConstrOther_E As Double = rr.Item("ConstrOther_E_Grant") + rr.Item("ConstrOther_E_Donation") + rr.Item("ConstrOther_E_Maint") + rr.Item("ConstrOther_E_Hazmat")
            Dim nTotalConstrOther_F As Double = rr.Item("ConstrOther_F_Grant") + rr.Item("ConstrOther_F_Donation") + rr.Item("ConstrOther_F_Maint") + rr.Item("ConstrOther_F_Hazmat")
            Dim nTotalConstrOther_G As Double = rr.Item("ConstrOther_G_Grant") + rr.Item("ConstrOther_G_Donation") + rr.Item("ConstrOther_G_Maint") + rr.Item("ConstrOther_G_Hazmat")
            Dim nTotalContingencyOther As Double = rr.Item("ContingencyOther_Grant") + rr.Item("ContingencyOther_Donation") + rr.Item("ContingencyOther_Maint") + rr.Item("ContingencyOther_Hazmat")
            Dim nTotalAEOversightOther As Double = rr.Item("AEOversightOther_Grant") + rr.Item("AEOversightOther_Donation") + rr.Item("AEOversightOther_Maint") + rr.Item("AEOversightOther_Hazmat")
            Dim nTotalTestsOther_A As Double = rr.Item("TestsOther_A_Grant") + rr.Item("TestsOther_A_Donation") + rr.Item("TestsOther_A_Maint") + rr.Item("TestsOther_A_Hazmat")
            Dim nTotalTestsOther_B As Double = rr.Item("TestsOther_B_Grant") + rr.Item("TestsOther_B_Donation") + rr.Item("TestsOther_B_Maint") + rr.Item("TestsOther_B_Hazmat")
            Dim nTotalConstMgmtOther As Double = rr.Item("ConstMgmtOther_Grant") + rr.Item("ConstMgmtOther_Donation") + rr.Item("ConstMgmtOther_Maint") + rr.Item("ConstMgmtOther_Hazmat")
            Dim nTotalFurnGroupOther As Double = rr.Item("FurnGroupOther_Grant") + rr.Item("FurnGroupOther_Donation") + rr.Item("FurnGroupOther_Maint") + rr.Item("FurnGroupOther_Hazmat")
            Dim nTotalOtherOther As Double = rr.Item("OtherOther_Grant") + rr.Item("OtherOther_Donation") + rr.Item("OtherOther_Maint") + rr.Item("OtherOther_Hazmat")

            Dim nTotalGlobalOther As Double = rr.Item("GlobalOther_Grant") + rr.Item("GlobalOther_Donation") + rr.Item("GlobalOther_Maint") + rr.Item("GlobalOther_Hazmat")

            'Now get all subtotals 
            Dim TotalSiteAqu As Double = rr.Item("SiteAquSF") + rr.Item("SiteAquDFSS") + rr.Item("SiteAquDFNSS") + nTotalSiteAquOther + rr.Item("SiteAquBond")
            Dim TotalPlan_A As Double = rr.Item("PlanSF_A") + rr.Item("PlanDFSS_A") + rr.Item("PlanDFNSS_A") + nTotalPlanOther_A + rr.Item("PlanBond_A")
            Dim TotalPlan_B As Double = rr.Item("PlanSF_B") + rr.Item("PlanDFSS_B") + rr.Item("PlanDFNSS_B") + nTotalPlanOther_B + rr.Item("PlanBond_B")
            Dim TotalPlan_C As Double = rr.Item("PlanSF_C") + rr.Item("PlanDFSS_C") + rr.Item("PlanDFNSS_C") + nTotalPlanOther_C + rr.Item("PlanBond_C")
            Dim TotalPlan_D As Double = rr.Item("PlanSF_D") + rr.Item("PlanDFSS_D") + rr.Item("PlanDFNSS_D") + nTotalPlanOther_D + rr.Item("PlanBond_D")
            Dim TotalWorkDraw_A As Double = rr.Item("WorkDrawSF_A") + rr.Item("WorkDrawDFSS_A") + rr.Item("WorkDrawDFNSS_A") + nTotalWorkDrawOther_A + rr.Item("WorkDrawBond_A")
            Dim TotalWorkDraw_B As Double = rr.Item("WorkDrawSF_B") + rr.Item("WorkDrawDFSS_B") + rr.Item("WorkDrawDFNSS_B") + nTotalWorkDrawOther_B + rr.Item("WorkDrawBond_B")
            Dim TotalWorkDraw_C As Double = rr.Item("WorkDrawSF_C") + rr.Item("WorkDrawDFSS_C") + rr.Item("WorkDrawDFNSS_C") + nTotalWorkDrawOther_C + rr.Item("WorkDrawBond_C")
            Dim TotalWorkDraw_D As Double = rr.Item("WorkDrawSF_D") + rr.Item("WorkDrawDFSS_D") + rr.Item("WorkDrawDFNSS_D") + nTotalWorkDrawOther_D + rr.Item("WorkDrawBond_D")
            Dim TotalWorkDraw_E As Double = rr.Item("WorkDrawSF_E") + rr.Item("WorkDrawDFSS_E") + rr.Item("WorkDrawDFNSS_E") + nTotalWorkDrawOther_E + rr.Item("WorkDrawBond_E")
            Dim TotalConstr_A As Double = rr.Item("ConstrSF_A") + rr.Item("ConstrDFSS_A") + rr.Item("ConstrDFNSS_A") + nTotalConstrOther_A + rr.Item("ConstrBond_A")
            Dim TotalConstr_B As Double = rr.Item("ConstrSF_B") + rr.Item("ConstrDFSS_B") + rr.Item("ConstrDFNSS_B") + nTotalConstrOther_B + rr.Item("ConstrBond_B")
            Dim TotalConstr_C As Double = rr.Item("ConstrSF_C") + rr.Item("ConstrDFSS_C") + rr.Item("ConstrDFNSS_C") + nTotalConstrOther_C + rr.Item("ConstrBond_C")
            Dim TotalConstr_D As Double = rr.Item("ConstrSF_D") + rr.Item("ConstrDFSS_D") + rr.Item("ConstrDFNSS_D") + nTotalConstrOther_D + rr.Item("ConstrBond_D")
            Dim TotalConstr_E As Double = rr.Item("ConstrSF_E") + rr.Item("ConstrDFSS_E") + rr.Item("ConstrDFNSS_E") + nTotalConstrOther_E + rr.Item("ConstrBond_E")
            Dim TotalConstr_F As Double = rr.Item("ConstrSF_F") + rr.Item("ConstrDFSS_F") + rr.Item("ConstrDFNSS_F") + nTotalConstrOther_F + rr.Item("ConstrBond_F")
            Dim TotalConstr_G As Double = rr.Item("ConstrSF_G") + rr.Item("ConstrDFSS_G") + rr.Item("ConstrDFNSS_G") + nTotalConstrOther_G + rr.Item("ConstrBond_G")
            Dim TotalContingency As Double = rr.Item("ContingencySF") + rr.Item("ContingencyDFSS") + rr.Item("ContingencyDFNSS") + nTotalContingencyOther + rr.Item("ContingencyBond")
            Dim TotalAEOversight As Double = rr.Item("AEOversightSF") + rr.Item("AEOversightDFSS") + rr.Item("AEOversightDFNSS") + nTotalAEOversightOther + rr.Item("AEOversightBond")
            Dim TotalTests_A As Double = rr.Item("TestsSF_A") + rr.Item("TestsDFSS_A") + rr.Item("TestsDFNSS_A") + nTotalTestsOther_A + rr.Item("TestsBond_A")
            Dim TotalTests_B As Double = rr.Item("TestsSF_B") + rr.Item("TestsDFSS_B") + rr.Item("TestsDFNSS_B") + nTotalTestsOther_B + rr.Item("TestsBond_B")
            Dim TotalConstMgmt As Double = rr.Item("ConstMgmtSF") + rr.Item("ConstMgmtDFSS") + rr.Item("ConstMgmtDFNSS") + nTotalConstMgmtOther + rr.Item("ConstMgmtBond")
            Dim TotalFurnGroup As Double = rr.Item("FurnGroup2SF") + rr.Item("FurnGroup2DFSS") + rr.Item("FurnGroup2DFNSS") + nTotalFurnGroupOther + rr.Item("FurnGroupBond")
            Dim TotalOther As Double = rr.Item("OtherSF") + rr.Item("OtherDFSS") + rr.Item("OtherDFNSS") + rr.Item("OtherBond") + nTotalOtherOther

            Dim TotalGlobal As Double = rr.Item("GlobalSF") + rr.Item("GlobalDFSS") + rr.Item("GlobalDFNSS") + rr.Item("GlobalBond") + nTotalGlobalOther

        
            'Calculate the Total Constructin Costs line

            Dim TotalConstructionCostsSF As Double = rr.Item("ConstrSF_A") + _
                                                     rr.Item("ConstrSF_B") + _
                                                     rr.Item("ConstrSF_C") + _
                                                     rr.Item("ConstrSF_D") + _
                                                     rr.Item("ConstrSF_E") + _
                                                     rr.Item("ConstrSF_F") + _
                                                     rr.Item("ConstrSF_G") + _
                                                     rr.Item("ContingencySF") + _
                                                     rr.Item("AEOversightSF") + _
                                                     rr.Item("TestsSF_A") + _
                                                     rr.Item("TestsSF_B") + _
                                                     rr.Item("ConstMgmtSF")

         
            Dim TotalConstructionCostsBond As Double = rr.Item("ConstrBond_A") + _
                                       rr.Item("ConstrBond_B") + _
                                       rr.Item("ConstrBond_C") + _
                                       rr.Item("ConstrBond_D") + _
                                       rr.Item("ConstrBond_E") + _
                                       rr.Item("ConstrBond_F") + _
                                       rr.Item("ConstrBond_G") + _
                                       rr.Item("ContingencyBond") + _
                                       rr.Item("AEOversightBond") + _
                                       rr.Item("TestsBond_A") + _
                                       rr.Item("TestsBond_B") + _
                                       rr.Item("ConstMgmtBond")

            Dim TotalConstructionCostsOther_Grant As Double = rr.Item("ConstrOther_A_Grant") + _
                                rr.Item("ConstrOther_B_Grant") + _
                                rr.Item("ConstrOther_C_Grant") + _
                                rr.Item("ConstrOther_D_Grant") + _
                                rr.Item("ConstrOther_E_Grant") + _
                                rr.Item("ConstrOther_F_Grant") + _
                                rr.Item("ConstrOther_G_Grant") + _
                                rr.Item("ContingencyOther_Grant") + _
                                rr.Item("AEOversightOther_Grant") + _
                                rr.Item("TestsOther_A_Grant") + _
                                rr.Item("TestsOther_B_Grant") + _
                                rr.Item("ConstMgmtOther_Grant")
        
 
            Dim TotalConstructionCostsOther_Hazmat As Double = rr.Item("ConstrOther_A_Hazmat") + _
                         rr.Item("ConstrOther_B_Hazmat") + _
                         rr.Item("ConstrOther_C_Hazmat") + _
                         rr.Item("ConstrOther_D_Hazmat") + _
                         rr.Item("ConstrOther_E_Hazmat") + _
                         rr.Item("ConstrOther_F_Hazmat") + _
                         rr.Item("ConstrOther_G_Hazmat") + _
                         rr.Item("ContingencyOther_Hazmat") + _
                         rr.Item("AEOversightOther_Hazmat") + _
                         rr.Item("TestsOther_A_Hazmat") + _
                         rr.Item("TestsOther_B_Hazmat") + _
                         rr.Item("ConstMgmtOther_Hazmat")
        
            Dim TotalConstructionCostsOther_Maint As Double = rr.Item("ConstrOther_A_Maint") + _
                         rr.Item("ConstrOther_B_Maint") + _
                         rr.Item("ConstrOther_C_Maint") + _
                         rr.Item("ConstrOther_D_Maint") + _
                         rr.Item("ConstrOther_E_Maint") + _
                         rr.Item("ConstrOther_F_Maint") + _
                         rr.Item("ConstrOther_G_Maint") + _
                         rr.Item("ContingencyOther_Maint") + _
                         rr.Item("AEOversightOther_Maint") + _
                         rr.Item("TestsOther_A_Maint") + _
                         rr.Item("TestsOther_B_Maint") + _
                         rr.Item("ConstMgmtOther_Maint")
        
            Dim TotalConstructionCostsOther_Donation As Double = rr.Item("ConstrOther_A_Donation") + _
                         rr.Item("ConstrOther_B_Donation") + _
                         rr.Item("ConstrOther_C_Donation") + _
                         rr.Item("ConstrOther_D_Donation") + _
                         rr.Item("ConstrOther_E_Donation") + _
                         rr.Item("ConstrOther_F_Donation") + _
                         rr.Item("ConstrOther_G_Donation") + _
                         rr.Item("ContingencyOther_Donation") + _
                         rr.Item("AEOversightOther_Donation") + _
                         rr.Item("TestsOther_A_Donation") + _
                         rr.Item("TestsOther_B_Donation") + _
                         rr.Item("ConstMgmtOther_Donation")
        
 
                
            Dim TotalConstructionCosts As Double = TotalConstructionCostsSF + TotalConstructionCostsBond + TotalConstructionCostsOther_Grant + TotalConstructionCostsOther_Hazmat + TotalConstructionCostsOther_Maint + TotalConstructionCostsOther_Donation
      
                
            'caculate all Funding  totals
            Dim nSFTotal As Double = 0
            Dim nDFSSTotal As Double = 0
            Dim nDFNSSTotal As Double = 0
            Dim nBondTotal As Double = 0
        
            Dim nOtherGrantTotal As Double = 0
            Dim nOtherHazmatTotal As Double = 0
            Dim nOtherMaintTotal As Double = 0
            Dim nOtherDonationTotal As Double = 0
        
            Dim c As DataColumn
            For Each c In rr.Table.Columns()
                Dim fld As String
                fld = c.ColumnName
                If InStr(fld, "NOTES") = 0 And InStr(fld, "CHANGES") = 0 Then  'filter out notes and  Changes fields
                    If InStr(fld, "SF") > 0 Then
                        nSFTotal = nSFTotal + ProcLib.CheckNullNumField(rr.Item(fld))
                    End If
                    If InStr(fld, "Bond") > 0 Then
                        nBondTotal = nBondTotal + ProcLib.CheckNullNumField(rr.Item(fld))
                    End If
                    If InStr(fld, "_Grant") > 0 Then
                        nOtherGrantTotal = nOtherGrantTotal + ProcLib.CheckNullNumField(rr.Item(fld))
                    End If
                    If InStr(fld, "_Hazmat") > 0 Then
                        nOtherHazmatTotal = nOtherHazmatTotal + ProcLib.CheckNullNumField(rr.Item(fld))
                    End If
                    If InStr(fld, "_Maint") > 0 Then
                        nOtherMaintTotal = nOtherMaintTotal + ProcLib.CheckNullNumField(rr.Item(fld))
                    End If
                    If InStr(fld, "_Donation") > 0 Then
                        nOtherDonationTotal = nOtherDonationTotal + ProcLib.CheckNullNumField(rr.Item(fld))
                    End If

                End If
            Next

            Dim GrandTotal As Double = TotalSiteAqu + TotalPlan_A + TotalPlan_B + TotalPlan_C + TotalPlan_D + TotalWorkDraw_A + TotalWorkDraw_B + TotalWorkDraw_C + TotalWorkDraw_D
            GrandTotal = GrandTotal + TotalWorkDraw_E + TotalConstr_A + TotalConstr_B + TotalConstr_C + TotalConstr_D + TotalConstr_E + TotalConstr_F + TotalConstr_G + TotalContingency + TotalAEOversight
            GrandTotal = GrandTotal + TotalTests_A + TotalTests_B + TotalConstMgmt + TotalFurnGroup + TotalOther + TotalGlobal

            rsBudget.Rows.Add(rr)   'add the new row to the table

                 
            For Each row As TableRow In tblBudget.Rows  'loop through all the lable controls on the page to fill each item
                For Each cell As TableCell In row.Cells
                    For Each bitem As Control In cell.Controls
                        If TypeOf (bitem) Is Label Then
                            Dim sfld As String = bitem.ID
                            If Left(sfld, 3) = "lbl" Then
                                DirectCast(bitem, Label).Text = AddEditLink(sfld)
                            End If
                        End If
                       
                    Next
                Next
            Next

            'Write Line Totals
            totTotalSiteAqu.Text = FormatCurrency(TotalSiteAqu)
            totTotalPlan_A.Text = FormatCurrency(TotalPlan_A)
            totTotalPlan_B.Text = FormatCurrency(TotalPlan_B)
            totTotalPlan_C.Text = FormatCurrency(TotalPlan_C)
            totTotalPlan_D.Text = FormatCurrency(TotalPlan_D)
            totTotalWorkDraw_A.Text = FormatCurrency(TotalWorkDraw_A)
            totTotalWorkDraw_B.Text = FormatCurrency(TotalWorkDraw_B)
            totTotalWorkDraw_C.Text = FormatCurrency(TotalWorkDraw_C)
            totTotalWorkDraw_D.Text = FormatCurrency(TotalWorkDraw_D)
            totTotalWorkDraw_E.Text = FormatCurrency(TotalWorkDraw_E)
            totTotalConstr_A.Text = FormatCurrency(TotalConstr_A)
            totTotalConstr_B.Text = FormatCurrency(TotalConstr_B)
            totTotalConstr_C.Text = FormatCurrency(TotalConstr_C)
            totTotalConstr_D.Text = FormatCurrency(TotalConstr_D)
            totTotalConstr_E.Text = FormatCurrency(TotalConstr_E)
            totTotalConstr_F.Text = FormatCurrency(TotalConstr_F)
            totTotalConstr_G.Text = FormatCurrency(TotalConstr_G)
            totTotalContingency.Text = FormatCurrency(TotalContingency)
            totTotalAEOversight.Text = FormatCurrency(TotalAEOversight)
            totTotalTests_A.Text = FormatCurrency(TotalTests_A)
            totTotalTests_B.Text = FormatCurrency(TotalTests_B)
            totTotalConstmgmt.Text = FormatCurrency(TotalConstMgmt)
            totTotalFurngroup.Text = FormatCurrency(TotalFurnGroup)
            totTotalOther.Text = FormatCurrency(TotalOther)
            totTotalGlobal.Text = FormatCurrency(TotalGlobal)

            totTotalPlan.Text = FormatCurrency(TotalPlan_A + TotalPlan_B + TotalPlan_C + TotalPlan_D, -1, -2, -2, -2)
            totTotalPlanSF.Text = FormatCurrency(rr.Item("PlanSF_A") + rr.Item("PlanSF_B") + rr.Item("PlanSF_C") + rr.Item("PlanSF_D"), -1, -2, -2, -2)
            totTotalPlanBond.Text = FormatCurrency(rr.Item("PlanBond_A") + rr.Item("PlanBond_B") + rr.Item("PlanBond_C") + rr.Item("PlanBond_D"), -1, -2, -2, -2)
            totTotalPlanOther_Grant.Text = FormatCurrency(rr("PlanOther_A_Grant") + rr("PlanOther_B_Grant") + rr("PlanOther_C_Grant") + rr("PlanOther_D_Grant"), -1, -2, -2, -2)
            totTotalPlanOther_Hazmat.Text = FormatCurrency(rr("PlanOther_A_Hazmat") + rr("PlanOther_B_Hazmat") + rr("PlanOther_C_Hazmat") + rr("PlanOther_D_Hazmat"), -1, -2, -2, -2)
            totTotalPlanOther_Maint.Text = FormatCurrency(rr("PlanOther_A_Maint") + rr("PlanOther_B_Maint") + rr("PlanOther_C_Maint") + rr("PlanOther_D_Maint"), -1, -2, -2, -2)
            totTotalPlanOther_Donation.Text = FormatCurrency(rr("PlanOther_A_Donation") + rr("PlanOther_B_Donation") + rr("PlanOther_C_Donation") + rr("PlanOther_D_Donation"), -1, -2, -2, -2)
        
            totTotalWorkDraw.Text = FormatCurrency(TotalWorkDraw_A + TotalWorkDraw_B + TotalWorkDraw_C + TotalWorkDraw_D + TotalWorkDraw_E, -1, -2, -2, -2)
            totTotalWorkDrawSF.Text = FormatCurrency(rr.Item("WorkDrawSF_A") + rr.Item("WorkDrawSF_B") + rr.Item("WorkDrawSF_C") + rr.Item("WorkDrawSF_D") + rr.Item("WorkDrawSF_e"), -1, -2, -2, -2)
            totTotalWorkDrawBOND.Text = FormatCurrency(rr.Item("WorkDrawBOND_A") + rr.Item("WorkDrawBOND_B") + rr.Item("WorkDrawBOND_C") + rr.Item("WorkDrawBOND_D") + rr.Item("WorkDrawBOND_e"), -1, -2, -2, -2)
            totTotalWorkDrawOther_Grant.Text = FormatCurrency(rr("WorkDrawOther_A_Grant") + rr("WorkDrawOther_B_Grant") + rr("WorkDrawOther_C_Grant") + rr("WorkDrawOther_D_Grant") + rr("WorkDrawOther_E_Grant"), -1, -2, -2, -2)
            totTotalWorkDrawOther_Hazmat.Text = FormatCurrency(rr("WorkDrawOther_A_Hazmat") + rr("WorkDrawOther_B_Hazmat") + rr("WorkDrawOther_C_Hazmat") + rr("WorkDrawOther_D_Hazmat") + rr("WorkDrawOther_E_Hazmat"), -1, -2, -2, -2)
            totTotalWorkDrawOther_Maint.Text = FormatCurrency(rr("WorkDrawOther_A_Maint") + rr("WorkDrawOther_B_Maint") + rr("WorkDrawOther_C_Maint") + rr("WorkDrawOther_D_Maint") + rr("WorkDrawOther_E_Maint"), -1, -2, -2, -2)
            totTotalWorkDrawOther_Donation.Text = FormatCurrency(rr("WorkDrawOther_A_Donation") + rr("WorkDrawOther_B_Donation") + rr("WorkDrawOther_C_Donation") + rr("WorkDrawOther_D_Donation") + rr("WorkDrawOther_E_Donation"), -1, -2, -2, -2)

            totTotalConstr.Text = FormatCurrency(TotalConstr_A + TotalConstr_B + TotalConstr_C + TotalConstr_D + TotalConstr_E + TotalConstr_F + TotalConstr_G, -1, -2, -2, -2)
            totTotalConstrSF.Text = FormatCurrency(rr.Item("ConstrSF_A") + rr.Item("ConstrSF_B") + rr.Item("ConstrSF_C") + rr.Item("ConstrSF_D") + rr.Item("ConstrSF_E") + rr.Item("ConstrSF_F") + rr.Item("ConstrSF_G"), -1, -2, -2, -2)
            totTotalConstrBOND.Text = FormatCurrency(rr.Item("ConstrBOND_A") + rr.Item("ConstrBOND_B") + rr.Item("ConstrBOND_C") + rr.Item("ConstrBOND_D") + rr.Item("ConstrBOND_e") + rr.Item("ConstrBOND_F") + rr.Item("ConstrBOND_G"), -1, -2, -2, -2)
            totTotalConstrOther_Grant.Text = FormatCurrency(rr("ConstrOther_A_Grant") + rr("ConstrOther_B_Grant") + rr("ConstrOther_C_Grant") + rr("ConstrOther_D_Grant") + rr("ConstrOther_E_Grant") + rr("ConstrOther_F_Grant") + rr("ConstrOther_G_Grant"), -1, -2, -2, -2)
            totTotalConstrOther_Hazmat.Text = FormatCurrency(rr("ConstrOther_A_Hazmat") + rr("ConstrOther_B_Hazmat") + rr("ConstrOther_C_Hazmat") + rr("ConstrOther_D_Hazmat") + rr("ConstrOther_E_Hazmat") + rr("ConstrOther_F_Hazmat") + rr("ConstrOther_G_Hazmat"), -1, -2, -2, -2)
            totTotalConstrOther_Maint.Text = FormatCurrency(rr("ConstrOther_A_Maint") + rr("ConstrOther_B_Maint") + rr("ConstrOther_C_Maint") + rr("ConstrOther_D_Maint") + rr("ConstrOther_E_Maint") + rr("ConstrOther_F_Maint") + rr("ConstrOther_G_Maint"), -1, -2, -2, -2)
            totTotalConstrOther_Donation.Text = FormatCurrency(rr("ConstrOther_A_Donation") + rr("ConstrOther_B_Donation") + rr("ConstrOther_C_Donation") + rr("ConstrOther_D_Donation") + rr("ConstrOther_E_Donation") + rr("ConstrOther_F_Donation") + rr("ConstrOther_G_Donation"), -1, -2, -2, -2)

            'write total contruction costs line
            totTotalConstructionCosts.Text = FormatCurrency(TotalConstructionCosts, -1, -2, -2, -2)
            totTotalConstructionCostsSF.Text = FormatCurrency(TotalConstructionCostsSF, -1, -2, -2, -2)
            totTotalConstructionCostsBond.Text = FormatCurrency(TotalConstructionCostsBond, -1, -2, -2, -2)
            totTotalConstructionCostsOther_Grant.Text = FormatCurrency(TotalConstructionCostsOther_Grant, -1, -2, -2, -2)
            totTotalConstructionCostsOther_Hazmat.Text = FormatCurrency(TotalConstructionCostsOther_Hazmat, -1, -2, -2, -2)
            totTotalConstructionCostsOther_Maint.Text = FormatCurrency(TotalConstructionCostsOther_Maint, -1, -2, -2, -2)
            totTotalConstructionCostsOther_Donation.Text = FormatCurrency(TotalConstructionCostsOther_Donation, -1, -2, -2, -2)
    
        
            totTotalTests.Text = FormatCurrency(TotalTests_A + TotalTests_B, -1, -2, -2, -2)
            totTotalTestsSF.Text = FormatCurrency(rr.Item("TestsSF_A") + rr.Item("TestsSF_B"), -1, -2, -2, -2)
            totTotalTestsBOND.Text = FormatCurrency(rr.Item("TestsBOND_A") + rr.Item("TestsBond_B"), -1, -2, -2, -2)
            totTotalTestsOther_Grant.Text = FormatCurrency(rr.Item("TestsOther_A_Grant") + rr.Item("TestsOther_B_Grant"), -1, -2, -2, -2)
            totTotalTestsOther_Hazmat.Text = FormatCurrency(rr.Item("TestsOther_A_Hazmat") + rr.Item("TestsOther_B_Hazmat"), -1, -2, -2, -2)
            totTotalTestsOther_Maint.Text = FormatCurrency(rr.Item("TestsOther_A_Maint") + rr.Item("TestsOther_B_Maint"), -1, -2, -2, -2)
            totTotalTestsOther_Donation.Text = FormatCurrency(rr.Item("TestsOther_A_Donation") + rr.Item("TestsOther_B_Donation"), -1, -2, -2, -2)


            'Write the GRAND TOTAL Line
            totGrandTotal.Text = FormatCurrency(GrandTotal, -1, -2, -2, -2)
            totSFTotal.Text = FormatCurrency(nSFTotal, -1, -2, -2, -2)
            totBondTotal.Text = FormatCurrency(nBondTotal, -1, -2, -2, -2)
            totOtherGrantTotal.Text = FormatCurrency(nOtherGrantTotal, -1, -2, -2, -2)
            totOtherHazmatTotal.Text = FormatCurrency(nOtherHazmatTotal, -1, -2, -2, -2)
            totOtherMaintTotal.Text = FormatCurrency(nOtherMaintTotal, -1, -2, -2, -2)
            totOtherDonationTotal.Text = FormatCurrency(nOtherDonationTotal, -1, -2, -2, -2)



            'write budget assumptions
            Dim strBA As String = ""
            rs.FillReader("SELECT BudgetAssumptions FROM Projects WHERE ProjectID = " & nProjectID)
            While rs.Reader.Read()
                strBA = ProcLib.CheckNullDBField(rs.Reader("BudgetAssumptions"))
            End While
            rs.Reader.Close()

            LabelNotes.Text = FormatMemo(strBA)
            rsBudget.Dispose()
        End Using

        SetSecurity()
        
        HideUnusedColumns()
 
    End Sub
    
    Private Sub SetSecurity()
        'Sets the security constraints for current page
        Using db As New EISSecurity
            db.DistrictID = Session("DistrictID")
            db.CollegeID = Session("CollegeID")
            db.ProjectID = nProjectID
            db.UserID = Session("UserID")
            
            'Set all off as default
            lnkJCAFGenerator.Visible = False
            lnkBudgetAssumptionsEdit.Visible = False
            lnkBudgetReporting.Visible = False
            lnkEstimates.Visible = False
            lnkPageConfig.Visible = False

 

            'finally, if user has write privaleges the grant all
            If db.FindUserPermission("JCAFBudget", "Write") Then
                lnkJCAFGenerator.Visible = True
                lnkBudgetAssumptionsEdit.Visible = True
                lnkBudgetReporting.Visible = True
                lnkEstimates.Visible = True
                lnkPageConfig.Visible = True
                
            Else
                'Check for specific rights
                If db.FindUserPermission("JCAFEstExpenses", "read") Then
                    lnkJCAFGenerator.Visible = False
                    lnkBudgetAssumptionsEdit.Visible = False
                    lnkBudgetReporting.Visible = False
                    lnkEstimates.Visible = True
                End If
            End If
            

        End Using
        
      
        
    End Sub
    
    Private Sub HideUnusedColumns()
        'Hides columns user has set to hide
        
        Dim bHideStateColumn As Boolean = False
        Dim bHideBondColumn As Boolean = False
        Dim bHideDonationColumn As Boolean = False
        Dim bHideHazmatColumn As Boolean = False
        Dim bHideMaintColumn As Boolean = False
        Dim bHideGrantColumn As Boolean = False
        Dim nTotalVisibleColumns As Integer = 6
        
        Using db As New promptBudget
            Dim tbl As DataTable = db.GetBudgetColumnSettings(nProjectID)
            If ProcLib.CheckNullNumField(tbl.Rows(0)("BudgetHideStateColumn")) = 1 Then
                bHideStateColumn = True
            End If
            If ProcLib.CheckNullNumField(tbl.Rows(0)("BudgetHideBondColumn")) = 1 Then
                bHideBondColumn = True
            End If
            If ProcLib.CheckNullNumField(tbl.Rows(0)("BudgetHideDonationColumn")) = 1 Then
                bHideDonationColumn = True
            End If
            If ProcLib.CheckNullNumField(tbl.Rows(0)("BudgetHideHazmatColumn")) = 1 Then
                bHideHazmatColumn = True
            End If
            If ProcLib.CheckNullNumField(tbl.Rows(0)("BudgetHideMaintColumn")) = 1 Then
                bHideMaintColumn = True
            End If
            If ProcLib.CheckNullNumField(tbl.Rows(0)("BudgetHideGrantColumn")) = 1 Then
                bHideGrantColumn = True
            End If
            
        End Using
        
        If bHideBondColumn = True Then
            nTotalVisibleColumns -= 1
            For Each row As TableRow In tblBudget.Rows
                For Each cell As TableCell In row.Cells
                    If InStr(cell.ID, "Bond") > 0 Then
                        cell.Visible = False
                    End If
                Next
            Next
        End If
        If bHideStateColumn = True Then
            nTotalVisibleColumns -= 1
            For Each row As TableRow In tblBudget.Rows
                For Each cell As TableCell In row.Cells
                    If InStr(cell.ID, "State") > 0 Then
                        cell.Visible = False
                    End If
                Next
            Next
        End If
        If bHideDonationColumn = True Then
            nTotalVisibleColumns -= 1
            For Each row As TableRow In tblBudget.Rows
                For Each cell As TableCell In row.Cells
                    If InStr(cell.ID, "Donation") > 0 Then
                        cell.Visible = False
                    End If
                Next
            Next
        End If
        If bHideHazmatColumn = True Then
            nTotalVisibleColumns -= 1
            For Each row As TableRow In tblBudget.Rows
                For Each cell As TableCell In row.Cells
                    If InStr(cell.ID, "Hazmat") > 0 Then
                        cell.Visible = False
                    End If
                Next
            Next
        End If
        If bHideGrantColumn = True Then
            nTotalVisibleColumns -= 1
            For Each row As TableRow In tblBudget.Rows
                For Each cell As TableCell In row.Cells
                    If InStr(cell.ID, "Grant") > 0 Then
                        cell.Visible = False
                    End If
                Next
            Next
        End If
        If bHideMaintColumn = True Then
            nTotalVisibleColumns -= 1
            For Each row As TableRow In tblBudget.Rows
                For Each cell As TableCell In row.Cells
                    If InStr(cell.ID, "Maint") > 0 Then
                        cell.Visible = False
                    End If
                Next
            Next
        End If

        'split columns equally
        Dim nPercentage As Integer = 100 / (nTotalVisibleColumns + 3)
            
        For Each row As TableRow In tblBudget.Rows
            For Each cell As TableCell In row.Cells
                If cell.Visible = True Then
                    cell.Width = Unit.Percentage(nPercentage)
                End If
            Next
        Next
                      
        If nTotalVisibleColumns = 1 Then                'hide the total cost column as it is redundant
            tblBudget.Width = Unit.Percentage(75)
            For Each row As TableRow In tblBudget.Rows
                For Each cell As TableCell In row.Cells
                    If InStr(cell.ID, "TotalCost") > 0 Then
                        cell.Visible = False
                    End If
                Next
            Next
        End If
 
       
    End Sub

    Function AddEditLink(ByVal strFieldName As String) As String

        AddEditLink = " "
        strFieldName = Mid(strFieldName, 4)


        Dim rr As DataRow
        rr = rsBudget.Rows(0)

        Dim nAmt As Double = 0
        Dim sNotes As String = ""
        Dim sChanges As String = ""

        'Dim sTargetForm As String = "budget_items.aspx"
        'Dim npopH As Integer = 475
        'Dim npopW As Integer = 650

        nAmt = rr.Item(strFieldName)
        sNotes = Trim(ProcLib.CheckNullDBField(rr.Item("NOTES" & strFieldName)))
        sChanges = Trim(ProcLib.CheckNullDBField(rr.Item("CHANGES" & strFieldName)))


        'Check for Changes and show change icon if present
        Dim strChangesLink As String = ""
        Dim strChangesParms As String = "Changes:" & nProjectID & ":" & strFieldName    'concatonate the popup type, projectID and field name to use for hover window parm
        If sChanges <> "" Then   'there is a note so add the image and hover window code
            strChangesLink = "<span id=""qqq2"" onclick=""HandleClick()"" onmouseover=""OpenWindowWithParam('HoverWindow', '" & strChangesParms & "', this)"" onmouseout=""CloseWindow('HoverWindow')"">"
            strChangesLink = strChangesLink & "<img src='images/prompt_change_history.gif' width='12' height='12'></span>" & "&nbsp;"
        Else
            strChangesLink = ""
        End If
        
        'Check for Notes and show notes icon if present
        Dim strNoteLink As String = ""
        Dim strNoteParms As String = "Notes:" & nProjectID & ":" & strFieldName    'concatonate the popup type, projectID and field name to use for hover window parm
        If sNotes <> "" Then   'there is a note so add the image and hover window code
            strNoteLink = "<span id=""qqq1"" onclick=""HandleClick()"" onmouseover=""OpenWindowWithParam('HoverWindow', '" & strNoteParms & "', this)"" onmouseout=""CloseWindow('HoverWindow')"">"
            strNoteLink = strNoteLink & "<img src='images/prompt_note.gif' width='15' height='14'></span>"
        Else
            strNoteLink = ""
        End If
        
        'Check for flag and show flag icon if present
        Dim strFlagLink As String = ""
        Dim strFlagParms As String = "Flag:" & nProjectID & ":" & strFieldName    'concatonate the popup type, projectID and field name to use for hover window parm
        Using db As New promptFlag
            db.ParentRecID = nProjectID     'projectID
            db.ParentRecType = "BudgetItem"
            db.BudgetItemField = strFieldName
            If db.FlagExists Then       'there is a Flag so add the image and hover window code
                strFlagLink = "<span id=""qqq1"" onclick=""HandleClick()"" onmouseover=""OpenWindowWithParam('HoverWindow', '" & strFlagParms & "', this)"" onmouseout=""CloseWindow('HoverWindow')"">"
                strFlagLink = strFlagLink & "<img src='images/alert.gif' width='15' height='14'></span>" & "&nbsp;"
            Else
                strFlagLink = ""
            End If
                
        End Using
          
        Dim strLink As String = ""
        strLink = strFlagLink & strChangesLink & strNoteLink & "<a href=""javascript:;"" onClick=""EditBudgetItems('" & strFieldName & "',this);"">"

        If strFieldName = "SAAcres" Then
            strLink = strLink & rr.Item(strFieldName) & "</a>"
        Else
            strLink = strLink & FormatCurrency(nAmt, -1, -2, -2, -2) & "</a>"
        End If

        'Just show the amount with no link for Global Items
        If InStr(strFieldName, "Global") > 0 Then
            strLink = FormatCurrency(nAmt, -1, -2, -2, -2)
        End If

        AddEditLink = strLink

    End Function

    Function FormatMemo(ByVal txt As String) As String
        Dim temp As String = ""
        Dim pos As Integer = 0
        Dim strOriginal As String = ""
        Dim strOldChar As String = ""
        Dim strNewChar As String = ""

        strOriginal = txt
        strOldChar = Chr(13) & Chr(10)
        strNewChar = "<br>"
        pos = InStr(1, strOriginal, strOldChar)
        While pos > 0
            temp = temp & Mid(strOriginal, 1, pos - 1) & strNewChar
            strOriginal = Right(strOriginal, Len(strOriginal) - pos - Len(strOldChar) + 1)
            pos = InStr(1, strOriginal, strOldChar)
        End While

        Return temp & strOriginal

    End Function



</script>

<asp:Content ID="Content1" ContentPlaceHolderID="mainBody" runat="Server">
    <telerik:RadWindowManager ID="contentPopup" runat="server">
    </telerik:RadWindowManager>
    <div id="contentwrapper">
        <div id="navrow">
            <asp:HyperLink ID="lnkJCAFGenerator" CssClass="jcaf" runat="server">Budget Generator</asp:HyperLink>
            <asp:HyperLink ID="lnkEstimates" runat="server" CssClass="budget">Budget Estimates</asp:HyperLink>
            <asp:HyperLink ID="lnkBudgetReporting" runat="server" CssClass="report">Budget Reporting</asp:HyperLink>
            <a class="printbtn" href="" onclick="printSelection(document.getElementById('printdiv'));return false">
                Printer-friendly page</a>
            <asp:HyperLink runat="server" ID="lnkPageConfig" CssClass="gear">Preferences</asp:HyperLink>
        </div>
        <div id="contentcolumn">
            <div class="innertube">
                <div id="printdiv">
                    <span class="hdprint">
                        <asp:Label ID="lblProjectName" runat="server"></asp:Label></span>
                    <asp:Table ID="tblBudget" runat="server" CellSpacing="0" CellPadding="4" class="jcaftable">
                        <asp:TableRow ID="HeaderRow" runat="server">
                            <asp:TableHeaderCell Style="background: #ccc; border-bottom: 1px #888 solid; -moz-border-radius-topleft: 5px;
                                -webkit-border-top-left-radius: 5px;" ColumnSpan="2" Height="30" Text="Budget Item"></asp:TableHeaderCell>
                            <asp:TableHeaderCell ID="TotalCost00" Width="182px" Style="background: #ccc; border-bottom: 1px #888 solid;"
                                HorizontalAlign="center" Height="30" Text="Total Cost">
    
                            </asp:TableHeaderCell>
                            <asp:TableHeaderCell ID="StateFunded" Style="background: #ccc; border-bottom: 1px #888 solid;"
                                HorizontalAlign="center" Width="13%" Height="30" Text="State Funded">
  
                            </asp:TableHeaderCell>
                            <asp:TableHeaderCell ID="BondFunded" Style="background: #ccc; border-bottom: 1px #888 solid;"
                                HorizontalAlign="center" Width="8%" Height="30" Text=" Bond Funded">
   
                            </asp:TableHeaderCell>
                            <asp:TableHeaderCell ID="GrantFunded" Style="background: #ccc; border-bottom: 1px #888 solid;"
                                HorizontalAlign="center" Width="8%" Height="30" Text="Grant Funded">
                            </asp:TableHeaderCell>
                            <asp:TableHeaderCell ID="HazmatFunded" Style="background: #ccc; border-bottom: 1px #888 solid;"
                                HorizontalAlign="center" Width="8%" Height="30" Text="Hazmat Funded">
                            </asp:TableHeaderCell>
                            <asp:TableHeaderCell ID="MaintFunded" Style="background: #ccc; border-bottom: 1px #888 solid;"
                                HorizontalAlign="center" Width="8%" Height="30" Text="Maint Funded">
                            </asp:TableHeaderCell>
                            <asp:TableHeaderCell ID="DonationFunded" Style="background: #ccc; border-bottom: 1px #888 solid;
                                -moz-border-radius-topright: 5px; -webkit-border-top-right-radius: 5px;" HorizontalAlign="center"
                                Width="8%" Height="30" Text="Donation Funded">
                            </asp:TableHeaderCell>
                        </asp:TableRow>
                        <asp:TableRow ID="TableRow1" runat="server">
                            <asp:TableCell ID="rowLabel0" Width="21%" class="bgblue" Height="30" Text="1. Site Aquisition" />
                            <asp:TableCell HorizontalAlign="center" Width="9%" Height="30">
                                <strong>Acres:</strong> <span>
                                    <asp:Label ID="lblSAAcres" Text="test" runat="server"></asp:Label></span>
                            </asp:TableCell>
                            <asp:TableCell ID="TotalCost1" Wrap="true" Width="182px" HorizontalAlign="right"
                                class="bgblue" Height="30">
                                <asp:Label ID="totTotalSiteAqu" Text="test" runat="server"></asp:Label>
                            </asp:TableCell>
                            <asp:TableCell ID="State01" Wrap="true" HorizontalAlign="right" Height="30">
                                <asp:Label ID="lblSiteAquSF" Text="test" runat="server"></asp:Label>
                            </asp:TableCell>
                            <asp:TableCell ID="Bond01" Wrap="true" HorizontalAlign="right" Height="30">
                                &nbsp;<asp:Label ID="lblSiteAquBond" Text="test" runat="server"></asp:Label>
                            </asp:TableCell>
                            <asp:TableCell ID="Grant01" Wrap="true" HorizontalAlign="right" Height="30">
                                &nbsp;<asp:Label ID="lblSiteAquOther_Grant" Text="test" runat="server"></asp:Label>
                            </asp:TableCell>
                            <asp:TableCell ID="Hazmat01" Wrap="true" HorizontalAlign="right" Height="30">
                                &nbsp;<asp:Label ID="lblSiteAquOther_Hazmat" Text="test" runat="server"></asp:Label>
                            </asp:TableCell>
                            <asp:TableCell ID="Maint01" Wrap="true" HorizontalAlign="right" Height="30">
                                &nbsp;<asp:Label ID="lblSiteAquOther_Maint" Text="test" runat="server"></asp:Label>
                            </asp:TableCell>
                            <asp:TableCell ID="Donation01" Wrap="true" HorizontalAlign="right" Height="30">
                                &nbsp;<asp:Label ID="lblSiteAquOther_Donation" Text="test" runat="server"></asp:Label>
                            </asp:TableCell>
                        </asp:TableRow>
                        <asp:TableRow ID="TableRow2" runat="server">
                            <asp:TableCell ID="rowLabel1" Wrap="true" class="bgblue" ColumnSpan="2" Height="30"
                                Text="2. Plans" Font-Bold="true" />
                            <asp:TableCell ID="TotalCost2" Wrap="true" Width="182px" HorizontalAlign="right"
                                class="bgblue" Height="30">
                                <asp:Label ID="totTotalPlan" Text="test" runat="server"></asp:Label>
                            </asp:TableCell>
                            <asp:TableCell ID="State02" Wrap="true" HorizontalAlign="right" BackColor="#feefb2"
                                Height="30">
                                <asp:Label ID="totTotalPlanSF" Text="test" runat="server"></asp:Label>
                            </asp:TableCell>
                            <asp:TableCell ID="Bond02" Wrap="true" HorizontalAlign="right" BackColor="#feefb2"
                                Height="30">
                                <asp:Label ID="totTotalPlanBond" Text="test" runat="server"></asp:Label>
                            </asp:TableCell>
                            <asp:TableCell ID="Grant02" Wrap="true" HorizontalAlign="right" BackColor="#feefb2"
                                Height="30">
                                <asp:Label ID="totTotalPlanOther_Grant" Text="test" runat="server"></asp:Label>
                            </asp:TableCell>
                            <asp:TableCell ID="Hazmat02" Wrap="true" HorizontalAlign="right" BackColor="#feefb2"
                                Height="30">
                                <asp:Label ID="totTotalPlanOther_Hazmat" Text="test" runat="server"></asp:Label>
                            </asp:TableCell>
                            <asp:TableCell ID="Maint02" Wrap="true" HorizontalAlign="right" BackColor="#feefb2"
                                Height="30">
                                <asp:Label ID="totTotalPlanOther_Maint" Text="test" runat="server"></asp:Label>
                            </asp:TableCell>
                            <asp:TableCell ID="Donation02" Wrap="true" HorizontalAlign="right" BackColor="#feefb2"
                                Height="30">
                                <asp:Label ID="totTotalPlanOther_Donation" Text="test" runat="server"></asp:Label>
                            </asp:TableCell>
                        </asp:TableRow>
                        <asp:TableRow ID="TableRow3" runat="server">
                            <asp:TableCell ID="rowLabel2" Wrap="true" valign="middle" ColumnSpan="2" Height="30"
                                Text="A. Architectual Fees" />
                            <asp:TableCell ID="TotalCost3" Wrap="true" Width="182px" HorizontalAlign="right"
                                BackColor="#feefb2" Height="30">
                                &nbsp;<asp:Label ID="totTotalPlan_A" Text="test" runat="server">test</asp:Label>
                            </asp:TableCell>
                            <asp:TableCell ID="State03" Wrap="true" HorizontalAlign="right" Height="30">
                                &nbsp;<asp:Label ID="lblPlanSF_A" Text="test" runat="server"></asp:Label>
                            </asp:TableCell>
                            <asp:TableCell ID="Bond03" Wrap="true" HorizontalAlign="right" Height="30">
                                &nbsp;<asp:Label ID="lblPlanBond_A" Text="test" runat="server"></asp:Label>
                            </asp:TableCell>
                            <asp:TableCell ID="Grant03" Wrap="true" HorizontalAlign="right" Height="30">
                                &nbsp;<asp:Label ID="lblPlanOther_A_Grant" Text="test" runat="server"></asp:Label>
                            </asp:TableCell>
                            <asp:TableCell ID="Hazmat03" Wrap="true" HorizontalAlign="right" Height="30">
                                &nbsp;<asp:Label ID="lblPlanOther_A_Hazmat" Text="test" runat="server"></asp:Label>
                            </asp:TableCell>
                            <asp:TableCell ID="Maint03" Wrap="true" HorizontalAlign="right" Height="30">
                                &nbsp;<asp:Label ID="lblPlanOther_A_Maint" Text="test" runat="server"></asp:Label>
                            </asp:TableCell>
                            <asp:TableCell ID="Donation03" Wrap="true" HorizontalAlign="right" Height="30">
                                &nbsp;<asp:Label ID="lblPlanOther_A_Donation" Text="test" runat="server"></asp:Label>
                            </asp:TableCell>
                        </asp:TableRow>
                        <asp:TableRow ID="TableRow4" runat="server">
                            <asp:TableCell ID="rowLabel3" Wrap="true" ColumnSpan="2" Height="30" Text="B. Project Management" />
                            <asp:TableCell ID="TotalCost4" Wrap="true" Width="182px" HorizontalAlign="right"
                                BackColor="#feefb2" Height="30">
                                <asp:Label ID="totTotalPlan_B" Text="test" runat="server">test</asp:Label>
                            </asp:TableCell>
                            <asp:TableCell ID="State04" Wrap="true" HorizontalAlign="right" Height="30">
                                &nbsp;<asp:Label ID="lblPlanSF_B" Text="test" runat="server"></asp:Label>
                            </asp:TableCell>
                            <asp:TableCell ID="Bond04" Wrap="true" HorizontalAlign="right" Height="30">
                                &nbsp;<asp:Label ID="lblPlanBond_B" Text="test" runat="server"></asp:Label>
                            </asp:TableCell>
                            <asp:TableCell ID="Grant04" Wrap="true" HorizontalAlign="right" Height="30">
                                &nbsp;<asp:Label ID="lblPlanOther_B_Grant" Text="test" runat="server"></asp:Label>
                            </asp:TableCell>
                            <asp:TableCell ID="Hazmat04" Wrap="true" HorizontalAlign="right" Height="30">
                                &nbsp;<asp:Label ID="lblPlanOther_B_Hazmat" Text="test" runat="server"></asp:Label>
                            </asp:TableCell>
                            <asp:TableCell ID="Maint04" Wrap="true" HorizontalAlign="right" Height="30">
                                &nbsp;<asp:Label ID="lblPlanOther_B_Maint" Text="test" runat="server"></asp:Label>
                            </asp:TableCell>
                            <asp:TableCell ID="Donation04" Wrap="true" HorizontalAlign="right" Height="30">
                                &nbsp;<asp:Label ID="lblPlanOther_B_Donation" Text="test" runat="server"></asp:Label>
                            </asp:TableCell>
                        </asp:TableRow>
                        <asp:TableRow ID="TableRow5" runat="server">
                            <asp:TableCell ID="rowLabel4" Wrap="true" ColumnSpan="2" Height="30" Text="C. Preliminary Tests" />
                            <asp:TableCell ID="TotalCost5" Wrap="true" Width="182px" HorizontalAlign="right"
                                BackColor="#feefb2" Height="30">
                                &nbsp;<asp:Label ID="totTotalPlan_C" Text="test" runat="server">test</asp:Label>
                            </asp:TableCell>
                            <asp:TableCell ID="State05" Wrap="true" HorizontalAlign="right" Height="30">
                                &nbsp;<asp:Label ID="lblPlanSF_C" Text="test" runat="server"></asp:Label>
                            </asp:TableCell>
                            <asp:TableCell ID="Bond05" Wrap="true" HorizontalAlign="right" Height="30">
                                &nbsp;<asp:Label ID="lblPlanBond_C" Text="test" runat="server"></asp:Label>
                            </asp:TableCell>
                            <asp:TableCell ID="Grant05" Wrap="true" HorizontalAlign="right" Height="30">
                                &nbsp;<asp:Label ID="lblPlanOther_C_Grant" Text="test" runat="server"></asp:Label>
                            </asp:TableCell>
                            <asp:TableCell ID="Hazmat05" Wrap="true" HorizontalAlign="right" Height="30">
                                &nbsp;<asp:Label ID="lblPlanOther_C_Hazmat" Text="test" runat="server"></asp:Label>
                            </asp:TableCell>
                            <asp:TableCell ID="Maint05" Wrap="true" HorizontalAlign="right" Height="30">
                                &nbsp;<asp:Label ID="lblPlanOther_C_Maint" Text="test" runat="server"></asp:Label>
                            </asp:TableCell>
                            <asp:TableCell ID="Donation05" Wrap="true" HorizontalAlign="right" Height="30">
                                &nbsp;<asp:Label ID="lblPlanOther_C_Donation" Text="test" runat="server"></asp:Label>
                            </asp:TableCell>
                        </asp:TableRow>
                        <asp:TableRow ID="TableRow6" runat="server">
                            <asp:TableCell ID="rowLabel5" Wrap="true" ColumnSpan="2" Height="30" Text="D. Other Costs" />
                            <asp:TableCell ID="TotalCost6" Wrap="true" Width="182px" HorizontalAlign="right"
                                BackColor="#feefb2" Height="30">
                                &nbsp;<asp:Label ID="totTotalPlan_D" Text="test" runat="server">test</asp:Label>
                            </asp:TableCell>
                            <asp:TableCell ID="State06" Wrap="true" HorizontalAlign="right" Height="30">
                                &nbsp;<asp:Label ID="lblPlanSF_D" Text="test" runat="server"></asp:Label>
                            </asp:TableCell>
                            <asp:TableCell ID="Bond06" Wrap="true" HorizontalAlign="right" Height="30">
                                &nbsp;<asp:Label ID="lblPlanBond_D" Text="test" runat="server"></asp:Label>
                            </asp:TableCell>
                            <asp:TableCell ID="Grant06" Wrap="true" HorizontalAlign="right" Height="30">
                                &nbsp;<asp:Label ID="lblPlanOther_D_Grant" Text="test" runat="server"></asp:Label>
                            </asp:TableCell>
                            <asp:TableCell ID="Hazmat06" Wrap="true" HorizontalAlign="right" Height="30">
                                &nbsp;<asp:Label ID="lblPlanOther_D_Hazmat" Text="test" runat="server"></asp:Label>
                            </asp:TableCell>
                            <asp:TableCell ID="Maint06" Wrap="true" HorizontalAlign="right" Height="30">
                                &nbsp;<asp:Label ID="lblPlanOther_D_Maint" Text="test" runat="server"></asp:Label>
                            </asp:TableCell>
                            <asp:TableCell ID="Donation06" Wrap="true" HorizontalAlign="right" Height="30">
                                &nbsp;<asp:Label ID="lblPlanOther_D_Donation" Text="test" runat="server"></asp:Label>
                            </asp:TableCell>
                        </asp:TableRow>
                        <asp:TableRow ID="TableRow7" runat="server">
                            <asp:TableCell ID="rowLabel6" Wrap="true" ColumnSpan="2" Height="30" class="bgblue"
                                Text="3. Working Drawings" Font-Bold="true" />
                            <asp:TableCell ID="TotalCost7" Wrap="true" Width="182px" HorizontalAlign="right"
                                class="bgblue" Height="30">
                                <asp:Label ID="totTotalWorkDraw" Text="test" runat="server"></asp:Label>
                            </asp:TableCell>
                            <asp:TableCell ID="State07" Wrap="true" HorizontalAlign="right" BackColor="#feefb2"
                                Height="30">
                                <asp:Label ID="totTotalWorkDrawSF" Text="test" runat="server"></asp:Label>
                            </asp:TableCell>
                            <asp:TableCell ID="Bond07" Wrap="true" HorizontalAlign="right" BackColor="#feefb2"
                                Height="30">
                                <asp:Label ID="totTotalWorkDrawBOND" Text="test" runat="server"></asp:Label>
                            </asp:TableCell>
                            <asp:TableCell ID="Grant07" Wrap="true" HorizontalAlign="right" BackColor="#feefb2"
                                Height="30">
                                <asp:Label ID="totTotalWorkDrawOther_Grant" Text="test" runat="server"></asp:Label>
                            </asp:TableCell>
                            <asp:TableCell ID="Hazmat07" Wrap="true" HorizontalAlign="right" BackColor="#feefb2"
                                Height="30">
                                <asp:Label ID="totTotalWorkDrawOther_Hazmat" Text="test" runat="server"></asp:Label>
                            </asp:TableCell>
                            <asp:TableCell ID="Maint07" Wrap="true" HorizontalAlign="right" BackColor="#feefb2"
                                Height="30">
                                <asp:Label ID="totTotalWorkDrawOther_Maint" Text="test" runat="server"></asp:Label>
                            </asp:TableCell>
                            <asp:TableCell ID="Donation07" Wrap="true" HorizontalAlign="right" BackColor="#feefb2"
                                Height="30">
                                <asp:Label ID="totTotalWorkDrawOther_Donation" Text="test" runat="server"></asp:Label>
                            </asp:TableCell>
                        </asp:TableRow>
                        <asp:TableRow ID="TableRow8" runat="server">
                            <asp:TableCell ID="rowLabel7" Wrap="true" ColumnSpan="2" Height="30" Text="A. Architectural Fees" />
                            <asp:TableCell ID="TotalCost8" Wrap="true" Width="182px" HorizontalAlign="right"
                                BackColor="#feefb2" Height="30">
                                &nbsp;<asp:Label ID="totTotalWorkDraw_A" Text="test" runat="server">test</asp:Label>
                            </asp:TableCell>
                            <asp:TableCell ID="State08" Wrap="true" HorizontalAlign="right" Height="30">
                                &nbsp;<asp:Label ID="lblWorkDrawSF_A" Text="test" runat="server"></asp:Label>
                            </asp:TableCell>
                            <asp:TableCell ID="Bond08" Wrap="true" HorizontalAlign="right" Height="30">
                                &nbsp;<asp:Label ID="lblWorkDrawBond_A" Text="test" runat="server"></asp:Label>
                            </asp:TableCell>
                            <asp:TableCell ID="Grant08" Wrap="true" HorizontalAlign="right" Height="30">
                                &nbsp;<asp:Label ID="lblWorkDrawOther_A_Grant" Text="test" runat="server"></asp:Label>
                            </asp:TableCell>
                            <asp:TableCell ID="Hazmat08" Wrap="true" HorizontalAlign="right" Height="30">
                                &nbsp;<asp:Label ID="lblWorkDrawOther_A_Hazmat" Text="test" runat="server"></asp:Label>
                            </asp:TableCell>
                            <asp:TableCell ID="Maint08" Wrap="true" HorizontalAlign="right" Height="30">
                                &nbsp;<asp:Label ID="lblWorkDrawOther_A_Maint" Text="test" runat="server"></asp:Label>
                            </asp:TableCell>
                            <asp:TableCell ID="Donation08" Wrap="true" HorizontalAlign="right" Height="30">
                                &nbsp;<asp:Label ID="lblWorkDrawOther_A_Donation" Text="test" runat="server"></asp:Label>
                            </asp:TableCell>
                        </asp:TableRow>
                        <asp:TableRow ID="TableRow9" runat="server">
                            <asp:TableCell ID="rowLabel8" Wrap="true" ColumnSpan="2" Height="30" Text="B. Project Management" />
                            <asp:TableCell ID="TotalCost9" Wrap="true" Width="182px" HorizontalAlign="right"
                                BackColor="#feefb2" Height="30">
                                <asp:Label ID="totTotalWorkDraw_B" Text="test" runat="server">test</asp:Label>
                            </asp:TableCell>
                            <asp:TableCell ID="State09" Wrap="true" HorizontalAlign="right" Height="30">
                                &nbsp;<asp:Label ID="lblWorkDrawSF_B" Text="test" runat="server"></asp:Label>
                            </asp:TableCell>
                            <asp:TableCell ID="Bond09" Wrap="true" HorizontalAlign="right" Height="30">
                                &nbsp;<asp:Label ID="lblWorkDrawBond_B" Text="test" runat="server"></asp:Label>
                            </asp:TableCell>
                            <asp:TableCell ID="Grant09" Wrap="true" HorizontalAlign="right" Height="30">
                                &nbsp;<asp:Label ID="lblWorkDrawOther_B_Grant" Text="test" runat="server"></asp:Label>
                            </asp:TableCell>
                            <asp:TableCell ID="Hazmat09" Wrap="true" HorizontalAlign="right" Height="30">
                                &nbsp;<asp:Label ID="lblWorkDrawOther_B_Hazmat" Text="test" runat="server"></asp:Label>
                            </asp:TableCell>
                            <asp:TableCell ID="Maint09" Wrap="true" HorizontalAlign="right" Height="30">
                                &nbsp;<asp:Label ID="lblWorkDrawOther_B_Maint" Text="test" runat="server"></asp:Label>
                            </asp:TableCell>
                            <asp:TableCell ID="Donation09" Wrap="true" HorizontalAlign="right" Height="30">
                                &nbsp;<asp:Label ID="lblWorkDrawOther_B_Donation" Text="test" runat="server"></asp:Label>
                            </asp:TableCell>
                        </asp:TableRow>
                        <asp:TableRow ID="TableRow10" runat="server">
                            <asp:TableCell ID="rowLabel9" Wrap="true" ColumnSpan="2" Height="30" Text="C. Office of SA, Plan Check Fee" />
                            <asp:TableCell ID="TotalCost10" Wrap="true" Width="182px" HorizontalAlign="right"
                                BackColor="#feefb2" Height="30">
                                &nbsp;<asp:Label ID="totTotalWorkDraw_C" Text="test" runat="server">test</asp:Label>
                            </asp:TableCell>
                            <asp:TableCell ID="State10" Wrap="true" HorizontalAlign="right" Height="30">
                                <asp:Label ID="lblWorkDrawSF_C" Text="test" runat="server"></asp:Label>
                            </asp:TableCell>
                            <asp:TableCell ID="Bond10" Wrap="true" HorizontalAlign="right" Height="30">
                                &nbsp;<asp:Label ID="lblWorkDrawBond_C" Text="test" runat="server"></asp:Label>
                            </asp:TableCell>
                            <asp:TableCell ID="Grant10" Wrap="true" HorizontalAlign="right" Height="30">
                                &nbsp;<asp:Label ID="lblWorkDrawOther_C_Grant" Text="test" runat="server"></asp:Label>
                            </asp:TableCell>
                            <asp:TableCell ID="Hazmat10" Wrap="true" HorizontalAlign="right" Height="30">
                                &nbsp;<asp:Label ID="lblWorkDrawOther_C_Hazmat" Text="test" runat="server"></asp:Label>
                            </asp:TableCell>
                            <asp:TableCell ID="Maint10" Wrap="true" HorizontalAlign="right" Height="30">
                                &nbsp;<asp:Label ID="lblWorkDrawOther_C_Maint" Text="test" runat="server"></asp:Label>
                            </asp:TableCell>
                            <asp:TableCell ID="Donation10" Wrap="true" HorizontalAlign="right" Height="30">
                                &nbsp;<asp:Label ID="lblWorkDrawOther_C_Donation" Text="test" runat="server"></asp:Label>
                            </asp:TableCell>
                        </asp:TableRow>
                        <asp:TableRow ID="TableRow11" runat="server">
                            <asp:TableCell ID="rowLabel10" Wrap="true" ColumnSpan="2" Height="30" Text="D. CC Plan Check Fee" />
                            <asp:TableCell ID="TotalCost11" Wrap="true" Width="182px" HorizontalAlign="right"
                                BackColor="#feefb2" Height="30">
                                &nbsp;<asp:Label ID="totTotalWorkDraw_D" Text="test" runat="server">test</asp:Label>
                            </asp:TableCell>
                            <asp:TableCell ID="State11" Wrap="true" HorizontalAlign="right" Height="30">
                                &nbsp;<asp:Label ID="lblWorkDrawSF_D" Text="test" runat="server"></asp:Label>
                            </asp:TableCell>
                            <asp:TableCell ID="Bond11" Wrap="true" HorizontalAlign="right" Height="30">
                                &nbsp;<asp:Label ID="lblWorkDrawBond_D" Text="test" runat="server"></asp:Label>
                            </asp:TableCell>
                            <asp:TableCell ID="Grant11" Wrap="true" HorizontalAlign="right" Height="30">
                                &nbsp;<asp:Label ID="lblWorkDrawOther_D_Grant" Text="test" runat="server"></asp:Label>
                            </asp:TableCell>
                            <asp:TableCell ID="Hazmat11" Wrap="true" HorizontalAlign="right" Height="30">
                                &nbsp;<asp:Label ID="lblWorkDrawOther_D_Hazmat" Text="test" runat="server"></asp:Label>
                            </asp:TableCell>
                            <asp:TableCell ID="Maint11" Wrap="true" HorizontalAlign="right" Height="30">
                                &nbsp;<asp:Label ID="lblWorkDrawOther_D_Maint" Text="test" runat="server"></asp:Label>
                            </asp:TableCell>
                            <asp:TableCell ID="Donation11" Wrap="true" HorizontalAlign="right" Height="30">
                                &nbsp;<asp:Label ID="lblWorkDrawOther_D_Donation" Text="test" runat="server"></asp:Label>
                            </asp:TableCell>
                        </asp:TableRow>
                        <asp:TableRow ID="TableRow12" runat="server">
                            <asp:TableCell ID="rowLabel11" Wrap="true" ColumnSpan="2" Height="30" Text="E. Other Costs" />
                            <asp:TableCell ID="TotalCost12" Wrap="true" Width="182px" HorizontalAlign="right"
                                BackColor="#feefb2" Height="30">
                                &nbsp;<asp:Label ID="totTotalWorkDraw_E" Text="test" runat="server">test</asp:Label>
                            </asp:TableCell>
                            <asp:TableCell ID="State12" Wrap="true" HorizontalAlign="right" Height="30">
                                &nbsp;<asp:Label ID="lblWorkDrawSF_E" Text="test" runat="server"></asp:Label>
                            </asp:TableCell>
                            <asp:TableCell ID="Bond12" Wrap="true" HorizontalAlign="right" Height="30">
                                &nbsp;<asp:Label ID="lblWorkDrawBond_E" Text="test" runat="server"></asp:Label>
                            </asp:TableCell>
                            <asp:TableCell ID="Grant12" Wrap="true" HorizontalAlign="right" Height="30">
                                &nbsp;<asp:Label ID="lblWorkDrawOther_E_Grant" Text="test" runat="server"></asp:Label>
                            </asp:TableCell>
                            <asp:TableCell ID="Hazmat12" Wrap="true" HorizontalAlign="right" Height="30">
                                &nbsp;<asp:Label ID="lblWorkDrawOther_E_Hazmat" Text="test" runat="server"></asp:Label>
                            </asp:TableCell>
                            <asp:TableCell ID="Maint12" Wrap="true" HorizontalAlign="right" Height="30">
                                &nbsp;<asp:Label ID="lblWorkDrawOther_E_Maint" Text="test" runat="server"></asp:Label>
                            </asp:TableCell>
                            <asp:TableCell ID="Donation12" Wrap="true" HorizontalAlign="right" Height="30">
                                &nbsp;<asp:Label ID="lblWorkDrawOther_E_Donation" Text="test" runat="server"></asp:Label>
                            </asp:TableCell>
                        </asp:TableRow>
                        <asp:TableRow ID="TableRow13" runat="server">
                            <asp:TableCell ID="rowLabel12" Wrap="true" ColumnSpan="2" Height="30" class="bgblue"
                                Text="4. Construction" Font-Bold="true" />
                            <asp:TableCell ID="TotalCost13" Wrap="true" Width="182px" HorizontalAlign="right"
                                class="bgblue" Height="30">
                                <asp:Label ID="totTotalConstr" Text="test" runat="server"></asp:Label>
                            </asp:TableCell>
                            <asp:TableCell ID="State13" Wrap="true" HorizontalAlign="right" BackColor="#feefb2"
                                Height="30">
                                <asp:Label ID="totTotalConstrSF" Text="test" runat="server"></asp:Label>
                            </asp:TableCell>
                            <asp:TableCell ID="Bond13" Wrap="true" HorizontalAlign="right" BackColor="#feefb2"
                                Height="30">
                                <asp:Label ID="totTotalConstrBOND" Text="test" runat="server"></asp:Label>
                            </asp:TableCell>
                            <asp:TableCell ID="Grant13" Wrap="true" HorizontalAlign="right" BackColor="#feefb2"
                                Height="30">
                                <asp:Label ID="totTotalConstrOther_Grant" Text="test" runat="server"></asp:Label>
                            </asp:TableCell>
                            <asp:TableCell ID="Hazmat13" Wrap="true" HorizontalAlign="right" BackColor="#feefb2"
                                Height="30">
                                <asp:Label ID="totTotalConstrOther_Hazmat" Text="test" runat="server"></asp:Label>
                            </asp:TableCell>
                            <asp:TableCell ID="Maint13" Wrap="true" HorizontalAlign="right" BackColor="#feefb2"
                                Height="30">
                                <asp:Label ID="totTotalConstrOther_Maint" Text="test" runat="server"></asp:Label>
                            </asp:TableCell>
                            <asp:TableCell ID="Donation13" Wrap="true" HorizontalAlign="right" BackColor="#feefb2"
                                Height="30">
                                <asp:Label ID="totTotalConstrOther_Donation" Text="test" runat="server"></asp:Label>
                            </asp:TableCell>
                        </asp:TableRow>
                        <asp:TableRow ID="TableRow14" runat="server">
                            <asp:TableCell ID="rowLabel13" Wrap="true" ColumnSpan="2" Height="30" Text="A. Utility Service" />
                            <asp:TableCell ID="TotalCost14" Wrap="true" Width="182px" HorizontalAlign="right"
                                BackColor="#feefb2" Height="30">
                                &nbsp;<asp:Label ID="totTotalConstr_A" Text="test" runat="server">test</asp:Label>
                            </asp:TableCell>
                            <asp:TableCell ID="State14" Wrap="true" HorizontalAlign="right" Height="30">
                                &nbsp;<asp:Label ID="lblConstrSF_A" Text="test" runat="server"></asp:Label>
                            </asp:TableCell>
                            <asp:TableCell ID="Bond14" Wrap="true" HorizontalAlign="right" Height="30">
                                &nbsp;<asp:Label ID="lblConstrBond_A" Text="test" runat="server"></asp:Label>
                            </asp:TableCell>
                            <asp:TableCell ID="Grant14" Wrap="true" HorizontalAlign="right" Height="30">
                                &nbsp;<asp:Label ID="lblConstrOther_A_Grant" Text="test" runat="server"></asp:Label>
                            </asp:TableCell>
                            <asp:TableCell ID="Hazmat14" Wrap="true" HorizontalAlign="right" Height="30">
                                &nbsp;<asp:Label ID="lblConstrOther_A_Hazmat" Text="test" runat="server"></asp:Label>
                            </asp:TableCell>
                            <asp:TableCell ID="Maint14" Wrap="true" HorizontalAlign="right" Height="30">
                                &nbsp;<asp:Label ID="lblConstrOther_A_Maint" Text="test" runat="server"></asp:Label>
                            </asp:TableCell>
                            <asp:TableCell ID="Donation14" Wrap="true" HorizontalAlign="right" Height="30">
                                &nbsp;<asp:Label ID="lblConstrOther_A_Donation" Text="test" runat="server"></asp:Label>
                            </asp:TableCell>
                        </asp:TableRow>
                        <asp:TableRow ID="TableRow15" runat="server">
                            <asp:TableCell ID="rowLabel14" Wrap="true" ColumnSpan="2" Height="30" Text="B. Site Development, Service" />
                            <asp:TableCell ID="TotalCost15" Wrap="true" Width="182px" HorizontalAlign="right"
                                BackColor="#feefb2" Height="30">
                                <asp:Label ID="totTotalConstr_B" Text="test" runat="server">test</asp:Label>
                            </asp:TableCell>
                            <asp:TableCell ID="State15" Wrap="true" HorizontalAlign="right" Height="30">
                                &nbsp;<asp:Label ID="lblConstrSF_B" Text="test" runat="server"></asp:Label>
                            </asp:TableCell>
                            <asp:TableCell ID="Bond15" Wrap="true" HorizontalAlign="right" Height="30">
                                &nbsp;<asp:Label ID="lblConstrBond_B" Text="test" runat="server"></asp:Label>
                            </asp:TableCell>
                            <asp:TableCell ID="Grant15" Wrap="true" HorizontalAlign="right" Height="30">
                                &nbsp;<asp:Label ID="lblConstrOther_B_Grant" Text="test" runat="server"></asp:Label>
                            </asp:TableCell>
                            <asp:TableCell ID="Hazmat15" Wrap="true" HorizontalAlign="right" Height="30">
                                &nbsp;<asp:Label ID="lblConstrOther_B_Hazmat" Text="test" runat="server"></asp:Label>
                            </asp:TableCell>
                            <asp:TableCell ID="Maint15" Wrap="true" HorizontalAlign="right" Height="30">
                                &nbsp;<asp:Label ID="lblConstrOther_B_Maint" Text="test" runat="server"></asp:Label>
                            </asp:TableCell>
                            <asp:TableCell ID="Donation15" Wrap="true" HorizontalAlign="right" Height="30">
                                &nbsp;<asp:Label ID="lblConstrOther_B_Donation" Text="test" runat="server"></asp:Label>
                            </asp:TableCell>
                        </asp:TableRow>
                        <asp:TableRow ID="TableRow16" runat="server">
                            <asp:TableCell ID="rowLabel15" Wrap="true" ColumnSpan="2" Height="30" Text="C. Site Development, General" />
                            <asp:TableCell ID="TotalCost16" Wrap="true" Width="182px" HorizontalAlign="right"
                                BackColor="#feefb2" Height="30">
                                &nbsp;<asp:Label ID="totTotalConstr_C" Text="test" runat="server">test</asp:Label>
                            </asp:TableCell>
                            <asp:TableCell ID="State16" Wrap="true" HorizontalAlign="right" Height="30">
                                &nbsp;<asp:Label ID="lblConstrSF_C" Text="test" runat="server"></asp:Label>
                            </asp:TableCell>
                            <asp:TableCell ID="Bond16" Wrap="true" HorizontalAlign="right" Height="30">
                                &nbsp;<asp:Label ID="lblConstrBond_C" Text="test" runat="server"></asp:Label>
                            </asp:TableCell>
                            <asp:TableCell ID="Grant16" Wrap="true" HorizontalAlign="right" Height="30">
                                &nbsp;<asp:Label ID="lblConstrOther_C_Grant" Text="test" runat="server"></asp:Label>
                            </asp:TableCell>
                            <asp:TableCell ID="Hazmat16" Wrap="true" HorizontalAlign="right" Height="30">
                                &nbsp;<asp:Label ID="lblConstrOther_C_Hazmat" Text="test" runat="server"></asp:Label>
                            </asp:TableCell>
                            <asp:TableCell ID="Maint16" Wrap="true" HorizontalAlign="right" Height="30">
                                &nbsp;<asp:Label ID="lblConstrOther_C_Maint" Text="test" runat="server"></asp:Label>
                            </asp:TableCell>
                            <asp:TableCell ID="Donation16" Wrap="true" HorizontalAlign="right" Height="30">
                                &nbsp;<asp:Label ID="lblConstrOther_C_Donation" Text="test" runat="server"></asp:Label>
                            </asp:TableCell>
                        </asp:TableRow>
                        <asp:TableRow ID="TableRow17" runat="server">
                            <asp:TableCell ID="rowLabel16" Wrap="true" ColumnSpan="2" Height="30" Text="D. Other Site Development" />
                            <asp:TableCell ID="TotalCost17" Wrap="true" Width="182px" HorizontalAlign="right"
                                BackColor="#feefb2" Height="30">
                                &nbsp;<asp:Label ID="totTotalConstr_D" Text="test" runat="server">test</asp:Label>
                            </asp:TableCell>
                            <asp:TableCell ID="State17" Wrap="true" HorizontalAlign="right" Height="30">
                                &nbsp;<asp:Label ID="lblConstrSF_D" Text="test" runat="server"></asp:Label>
                            </asp:TableCell>
                            <asp:TableCell ID="Bond17" Wrap="true" HorizontalAlign="right" Height="30">
                                &nbsp;<asp:Label ID="lblConstrBond_D" Text="test" runat="server"></asp:Label>
                            </asp:TableCell>
                            <asp:TableCell ID="Grant17" Wrap="true" HorizontalAlign="right" Height="30">
                                &nbsp;<asp:Label ID="lblConstrOther_D_Grant" Text="test" runat="server"></asp:Label>
                            </asp:TableCell>
                            <asp:TableCell ID="Hazmat17" Wrap="true" HorizontalAlign="right" Height="30">
                                &nbsp;<asp:Label ID="lblConstrOther_D_Hazmat" Text="test" runat="server"></asp:Label>
                            </asp:TableCell>
                            <asp:TableCell ID="Maint17" Wrap="true" HorizontalAlign="right" Height="30">
                                &nbsp;<asp:Label ID="lblConstrOther_D_Maint" Text="test" runat="server"></asp:Label>
                            </asp:TableCell>
                            <asp:TableCell ID="Donation17" Wrap="true" HorizontalAlign="right" Height="30">
                                &nbsp;<asp:Label ID="lblConstrOther_D_Donation" Text="test" runat="server"></asp:Label>
                            </asp:TableCell>
                        </asp:TableRow>
                        <asp:TableRow ID="TableRow18" runat="server">
                            <asp:TableCell ID="rowLabel17" Wrap="true" ColumnSpan="2" Height="30" Text="E. Reconstruction" />
                            <asp:TableCell ID="TotalCost18" Wrap="true" Width="182px" HorizontalAlign="right"
                                BackColor="#feefb2" Height="30">
                                <asp:Label ID="totTotalConstr_E" Text="test" runat="server">test</asp:Label>
                            </asp:TableCell>
                            <asp:TableCell ID="State18" Wrap="true" HorizontalAlign="right" Height="30">
                                &nbsp;<asp:Label ID="lblConstrSF_E" Text="test" runat="server"></asp:Label>
                            </asp:TableCell>
                            <asp:TableCell ID="Bond18" Wrap="true" HorizontalAlign="right" Height="30">
                                &nbsp;<asp:Label ID="lblConstrBond_E" Text="test" runat="server"></asp:Label>
                            </asp:TableCell>
                            <asp:TableCell ID="Grant18" Wrap="true" HorizontalAlign="right" Height="30">
                                &nbsp;<asp:Label ID="lblConstrOther_E_Grant" Text="test" runat="server"></asp:Label>
                            </asp:TableCell>
                            <asp:TableCell ID="Hazmat18" Wrap="true" HorizontalAlign="right" Height="30">
                                &nbsp;<asp:Label ID="lblConstrOther_E_Hazmat" Text="test" runat="server"></asp:Label>
                            </asp:TableCell>
                            <asp:TableCell ID="Maint18" Wrap="true" HorizontalAlign="right" Height="30">
                                &nbsp;<asp:Label ID="lblConstrOther_E_Maint" Text="test" runat="server"></asp:Label>
                            </asp:TableCell>
                            <asp:TableCell ID="Donation18" Wrap="true" HorizontalAlign="right" Height="30">
                                &nbsp;<asp:Label ID="lblConstrOther_E_Donation" Text="test" runat="server"></asp:Label>
                            </asp:TableCell>
                        </asp:TableRow>
                        <asp:TableRow ID="TableRow19" runat="server">
                            <asp:TableCell ID="rowLabel18" Wrap="true" ColumnSpan="2" Height="30" Text="F. New Construction" />
                            <asp:TableCell ID="TotalCost19" Wrap="true" Width="182px" HorizontalAlign="right"
                                BackColor="#feefb2" Height="30">
                                &nbsp;<asp:Label ID="totTotalConstr_F" Text="test" runat="server">test</asp:Label>
                            </asp:TableCell>
                            <asp:TableCell ID="State19" Wrap="true" HorizontalAlign="right" Height="30">
                                &nbsp;<asp:Label ID="lblConstrSF_F" Text="test" runat="server"></asp:Label>
                            </asp:TableCell>
                            <asp:TableCell ID="Bond19" Wrap="true" HorizontalAlign="right" Height="30">
                                &nbsp;<asp:Label ID="lblConstrBond_F" Text="test" runat="server"></asp:Label>
                            </asp:TableCell>
                            <asp:TableCell ID="Grant19" Wrap="true" HorizontalAlign="right" Height="30">
                                &nbsp;<asp:Label ID="lblConstrOther_F_Grant" Text="test" runat="server"></asp:Label>
                            </asp:TableCell>
                            <asp:TableCell ID="Hazmat19" Wrap="true" HorizontalAlign="right" Height="30">
                                &nbsp;<asp:Label ID="lblConstrOther_F_Hazmat" Text="test" runat="server"></asp:Label>
                            </asp:TableCell>
                            <asp:TableCell ID="Maint19" Wrap="true" HorizontalAlign="right" Height="30">
                                &nbsp;<asp:Label ID="lblConstrOther_F_Maint" Text="test" runat="server"></asp:Label>
                            </asp:TableCell>
                            <asp:TableCell ID="Donation19" Wrap="true" HorizontalAlign="right" Height="30">
                                &nbsp;<asp:Label ID="lblConstrOther_F_Donation" Text="test" runat="server"></asp:Label>
                            </asp:TableCell>
                        </asp:TableRow>
                        <asp:TableRow ID="TableRow20" runat="server">
                            <asp:TableCell ID="rowLabel19" Wrap="true" ColumnSpan="2" Height="30" Text="G. Other" />
                            <asp:TableCell ID="TotalCost20" Wrap="true" Width="182px" HorizontalAlign="right"
                                BackColor="#feefb2" Height="30">
                                &nbsp;<asp:Label ID="totTotalConstr_G" Text="test" runat="server">test</asp:Label>
                            </asp:TableCell>
                            <asp:TableCell ID="State20" Wrap="true" HorizontalAlign="right" Height="30">
                                &nbsp;<asp:Label ID="lblConstrSF_G" Text="test" runat="server"></asp:Label>
                            </asp:TableCell>
                            <asp:TableCell ID="Bond20" Wrap="true" HorizontalAlign="right" Height="30">
                                &nbsp;<asp:Label ID="lblConstrBond_G" Text="test" runat="server"></asp:Label>
                            </asp:TableCell>
                            <asp:TableCell ID="Grant20" Wrap="true" HorizontalAlign="right" Height="30">
                                &nbsp;<asp:Label ID="lblConstrOther_G_Grant" Text="test" runat="server"></asp:Label>
                            </asp:TableCell>
                            <asp:TableCell ID="Hazmat20" Wrap="true" HorizontalAlign="right" Height="30">
                                &nbsp;<asp:Label ID="lblConstrOther_G_Hazmat" Text="test" runat="server"></asp:Label>
                            </asp:TableCell>
                            <asp:TableCell ID="Maint20" Wrap="true" HorizontalAlign="right" Height="30">
                                &nbsp;<asp:Label ID="lblConstrOther_G_Maint" Text="test" runat="server"></asp:Label>
                            </asp:TableCell>
                            <asp:TableCell ID="Donation20" Wrap="true" HorizontalAlign="right" Height="30">
                                &nbsp;<asp:Label ID="lblConstrOther_G_Donation" Text="test" runat="server"></asp:Label>
                            </asp:TableCell>
                        </asp:TableRow>
                        <asp:TableRow ID="TableRow21" runat="server">
                            <asp:TableCell ID="rowLabel20" Wrap="true" class="bgblue" ColumnSpan="2" Height="30"
                                Text="5. Contingency" Font-Bold="true" />
                            <asp:TableCell ID="TotalCost21" Wrap="true" Width="182px" HorizontalAlign="right"
                                class="bgblue" Height="30">
                                &nbsp;<asp:Label ID="totTotalContingency" Text="test" runat="server">test</asp:Label>
                            </asp:TableCell>
                            <asp:TableCell ID="State21" Wrap="true" HorizontalAlign="right" Height="30">
                                &nbsp;<asp:Label ID="lblContingencySF" Text="test" runat="server"></asp:Label>
                            </asp:TableCell>
                            <asp:TableCell ID="Bond21" Wrap="true" HorizontalAlign="right" Height="30">
                                &nbsp;<asp:Label ID="lblContingencyBond" Text="test" runat="server"></asp:Label>
                            </asp:TableCell>
                            <asp:TableCell ID="Grant21" Wrap="true" HorizontalAlign="right" Height="30">
                                &nbsp;<asp:Label ID="lblContingencyOther_Grant" Text="test" runat="server"></asp:Label>
                            </asp:TableCell>
                            <asp:TableCell ID="Hazmat21" Wrap="true" HorizontalAlign="right" Height="30">
                                &nbsp;<asp:Label ID="lblContingencyOther_Hazmat" Text="test" runat="server"></asp:Label>
                            </asp:TableCell>
                            <asp:TableCell ID="Maint21" Wrap="true" HorizontalAlign="right" Height="30">
                                &nbsp;<asp:Label ID="lblContingencyOther_Maint" Text="test" runat="server"></asp:Label>
                            </asp:TableCell>
                            <asp:TableCell ID="Donation21" Wrap="true" HorizontalAlign="right" Height="30">
                                &nbsp;<asp:Label ID="lblContingencyOther_Donation" Text="test" runat="server"></asp:Label>
                            </asp:TableCell>
                        </asp:TableRow>
                        <asp:TableRow ID="TableRow22" runat="server">
                            <asp:TableCell ID="rowLabel21" Wrap="true" class="bgblue" ColumnSpan="2" Height="30"
                                Text="6. A and E Oversight" Font-Bold="true" />
                            <asp:TableCell ID="TotalCost22" Wrap="true" Width="182px" HorizontalAlign="right"
                                class="bgblue" Height="30">
                                &nbsp;<asp:Label ID="totTotalAEOversight" Text="test" runat="server">test</asp:Label>
                            </asp:TableCell>
                            <asp:TableCell ID="State22" Wrap="true" HorizontalAlign="right" Height="30">
                                &nbsp;<asp:Label ID="lblAEOversightSF" Text="test" runat="server"></asp:Label>
                            </asp:TableCell>
                            <asp:TableCell ID="Bond22" Wrap="true" HorizontalAlign="right" Height="30">
                                &nbsp;<asp:Label ID="lblAEOversightBond" Text="test" runat="server"></asp:Label>
                            </asp:TableCell>
                            <asp:TableCell ID="Grant22" Wrap="true" HorizontalAlign="right" Height="30">
                                &nbsp;<asp:Label ID="lblAEOversightOther_Grant" Text="test" runat="server"></asp:Label>
                            </asp:TableCell>
                            <asp:TableCell ID="Hazmat22" Wrap="true" HorizontalAlign="right" Height="30">
                                &nbsp;<asp:Label ID="lblAEOversightOther_Hazmat" Text="test" runat="server"></asp:Label>
                            </asp:TableCell>
                            <asp:TableCell ID="Maint22" Wrap="true" HorizontalAlign="right" Height="30">
                                &nbsp;<asp:Label ID="lblAEOversightOther_Maint" Text="test" runat="server"></asp:Label>
                            </asp:TableCell>
                            <asp:TableCell ID="Donation22" Wrap="true" HorizontalAlign="right" Height="30">
                                &nbsp;<asp:Label ID="lblAEOversightOther_Donation" Text="test" runat="server"></asp:Label>
                            </asp:TableCell>
                        </asp:TableRow>
                        <asp:TableRow ID="TableRow23" runat="server">
                            <asp:TableCell ID="rowLabel22" Wrap="true" ColumnSpan="2" Height="30" class="bgblue"
                                Text="7. Test and Inspections" Font-Bold="true" />
                            <asp:TableCell ID="TotalCost23" Wrap="true" Width="182px" HorizontalAlign="right"
                                Height="30">
                                <asp:Label ID="totTotalTests" Text="test" runat="server"></asp:Label>
                            </asp:TableCell>
                            <asp:TableCell ID="State23" Wrap="true" HorizontalAlign="right" BackColor="#feefb2"
                                Height="30">
                                <asp:Label ID="totTotalTestsSF" Text="test" runat="server"></asp:Label>
                            </asp:TableCell>
                            <asp:TableCell ID="Bond23" Wrap="true" HorizontalAlign="right" BackColor="#feefb2"
                                Height="30">
                                <asp:Label ID="totTotalTestsBOND" Text="test" runat="server"></asp:Label>
                            </asp:TableCell>
                            <asp:TableCell ID="Grant23" Wrap="true" HorizontalAlign="right" BackColor="#feefb2"
                                Height="30">
                                <asp:Label ID="totTotalTestsOther_Grant" Text="test" runat="server"></asp:Label>
                            </asp:TableCell>
                            <asp:TableCell ID="Hazmat23" Wrap="true" HorizontalAlign="right" BackColor="#feefb2"
                                Height="30">
                                <asp:Label ID="totTotalTestsOther_Hazmat" Text="test" runat="server"></asp:Label>
                            </asp:TableCell>
                            <asp:TableCell ID="Maint23" Wrap="true" HorizontalAlign="right" BackColor="#feefb2"
                                Height="30">
                                <asp:Label ID="totTotalTestsOther_Maint" Text="test" runat="server"></asp:Label>
                            </asp:TableCell>
                            <asp:TableCell ID="Donation23" Wrap="true" HorizontalAlign="right" BackColor="#feefb2"
                                Height="30">
                                <asp:Label ID="totTotalTestsOther_Donation" Text="test" runat="server"></asp:Label>
                            </asp:TableCell>
                        </asp:TableRow>
                        <asp:TableRow ID="TableRow24" runat="server">
                            <asp:TableCell ID="rowLabel23" Wrap="true" ColumnSpan="2" Height="30" Text="A. Test" />
                            <asp:TableCell ID="TotalCost24" Wrap="true" Width="182px" HorizontalAlign="right"
                                BackColor="#feefb2" Height="30">
                                <asp:Label ID="totTotalTests_A" Text="test" runat="server">test</asp:Label>
                            </asp:TableCell>
                            <asp:TableCell ID="State24" Wrap="true" HorizontalAlign="right" Height="30">
                                &nbsp;<asp:Label ID="lblTestsSF_A" Text="test" runat="server"></asp:Label>
                            </asp:TableCell>
                            <asp:TableCell ID="Bond24" Wrap="true" HorizontalAlign="right" Height="30">
                                &nbsp;<asp:Label ID="lblTestsBond_A" Text="test" runat="server"></asp:Label>
                            </asp:TableCell>
                            <asp:TableCell ID="Grant24" Wrap="true" HorizontalAlign="right" Height="30">
                                &nbsp;<asp:Label ID="lblTestsOther_A_Grant" Text="test" runat="server"></asp:Label>
                            </asp:TableCell>
                            <asp:TableCell ID="Hazmat24" Wrap="true" HorizontalAlign="right" Height="30">
                                &nbsp;<asp:Label ID="lblTestsOther_A_Hazmat" Text="test" runat="server"></asp:Label>
                            </asp:TableCell>
                            <asp:TableCell ID="Maint24" Wrap="true" HorizontalAlign="right" Height="30">
                                &nbsp;<asp:Label ID="lblTestsOther_A_Maint" Text="test" runat="server"></asp:Label>
                            </asp:TableCell>
                            <asp:TableCell ID="Donation24" Wrap="true" HorizontalAlign="right" Height="30">
                                &nbsp;<asp:Label ID="lblTestsOther_A_Donation" Text="test" runat="server"></asp:Label>
                            </asp:TableCell>
                        </asp:TableRow>
                        <asp:TableRow ID="TableRow25" runat="server">
                            <asp:TableCell ID="rowLabel24" Wrap="true" ColumnSpan="2" Height="30" Text="B. Inspections" />
                            <asp:TableCell ID="TotalCost25" Wrap="true" Width="182px" HorizontalAlign="right"
                                BackColor="#feefb2" Height="30">
                                &nbsp;<asp:Label ID="totTotalTests_B" Text="test" runat="server">test</asp:Label>
                            </asp:TableCell>
                            <asp:TableCell ID="State25" Wrap="true" HorizontalAlign="right" Height="30">
                                &nbsp;<asp:Label ID="lblTestsSF_B" Text="test" runat="server"></asp:Label>
                            </asp:TableCell>
                            <asp:TableCell ID="Bond25" Wrap="true" HorizontalAlign="right" Height="30">
                                &nbsp;<asp:Label ID="lblTestsBond_B" Text="test" runat="server"></asp:Label>
                            </asp:TableCell>
                            <asp:TableCell ID="Grant25" Wrap="true" HorizontalAlign="right" Height="30">
                                &nbsp;<asp:Label ID="lblTestsOther_B_Grant" Text="test" runat="server"></asp:Label>
                            </asp:TableCell>
                            <asp:TableCell ID="Hazmat25" Wrap="true" HorizontalAlign="right" Height="30">
                                &nbsp;<asp:Label ID="lblTestsOther_B_Hazmat" Text="test" runat="server"></asp:Label>
                            </asp:TableCell>
                            <asp:TableCell ID="Maint25" Wrap="true" HorizontalAlign="right" Height="30">
                                &nbsp;<asp:Label ID="lblTestsOther_B_Maint" Text="test" runat="server"></asp:Label>
                            </asp:TableCell>
                            <asp:TableCell ID="Donation25" Wrap="true" HorizontalAlign="right" Height="30">
                                &nbsp;<asp:Label ID="lblTestsOther_B_Donation" Text="test" runat="server"></asp:Label>
                            </asp:TableCell>
                        </asp:TableRow>
                        <asp:TableRow ID="TableRow26" runat="server">
                            <asp:TableCell ID="rowLabel25" Wrap="true" class="bgblue" ColumnSpan="2" Height="30"
                                Text="8. Construction Management" Font-Bold="true" />
                            <asp:TableCell ID="TotalCost26" Wrap="true" Width="182px" HorizontalAlign="right"
                                class="bgblue" Height="30">
                                &nbsp;<asp:Label ID="totTotalConstmgmt" Text="test" runat="server">test</asp:Label>
                            </asp:TableCell>
                            <asp:TableCell ID="State26" Wrap="true" HorizontalAlign="right" Height="30">
                                &nbsp;<asp:Label ID="lblConstMgmtSF" Text="test" runat="server"></asp:Label>
                            </asp:TableCell>
                            <asp:TableCell ID="Bond26" Wrap="true" HorizontalAlign="right" Height="30">
                                &nbsp;<asp:Label ID="lblConstMgmtBond" Text="test" runat="server"></asp:Label>
                            </asp:TableCell>
                            <asp:TableCell ID="Grant26" Wrap="true" HorizontalAlign="right" Height="30">
                                &nbsp;<asp:Label ID="lblConstMgmtOther_Grant" Text="test" runat="server"></asp:Label>
                            </asp:TableCell>
                            <asp:TableCell ID="Hazmat26" Wrap="true" HorizontalAlign="right" Height="30">
                                &nbsp;<asp:Label ID="lblConstMgmtOther_Hazmat" Text="test" runat="server"></asp:Label>
                            </asp:TableCell>
                            <asp:TableCell ID="Maint26" Wrap="true" HorizontalAlign="right" Height="30">
                                &nbsp;<asp:Label ID="lblConstMgmtOther_Maint" Text="test" runat="server"></asp:Label>
                            </asp:TableCell>
                            <asp:TableCell ID="Donation26" Wrap="true" HorizontalAlign="right" Height="30">
                                &nbsp;<asp:Label ID="lblConstMgmtOther_Donation" Text="test" runat="server"></asp:Label>
                            </asp:TableCell>
                        </asp:TableRow>
                        <asp:TableRow ID="TableRow27" runat="server">
                            <asp:TableCell ID="rowLabel26" Wrap="true" class="bgblue" ColumnSpan="2" Height="30"
                                Text="9. Total Construction Costs(Items 4 - 8)" Font-Bold="true" />
                            <asp:TableCell ID="TotalCost27" Wrap="true" Width="182px" HorizontalAlign="right"
                                class="bgblue" Height="30">
                                &nbsp;<asp:Label ID="totTotalConstructionCosts" Text="test" runat="server">test</asp:Label>
                            </asp:TableCell>
                            <asp:TableCell ID="State27" Wrap="true" HorizontalAlign="right" class="bgblue" Height="30">
                                &nbsp;<asp:Label ID="totTotalConstructionCostsSF" Text="test" runat="server"></asp:Label>
                            </asp:TableCell>
                            <asp:TableCell ID="Bond27" Wrap="true" HorizontalAlign="right" class="bgblue" Height="30">
                                &nbsp;<asp:Label ID="totTotalConstructionCostsBond" Text="test" runat="server"></asp:Label>
                            </asp:TableCell>
                            <asp:TableCell ID="Grant27" Wrap="true" HorizontalAlign="right" class="bgblue" Height="30">
                                &nbsp;<asp:Label ID="totTotalConstructionCostsOther_Grant" Text="test" runat="server"></asp:Label>
                            </asp:TableCell>
                            <asp:TableCell ID="Hazmat27" Wrap="true" HorizontalAlign="right" class="bgblue" Height="30">
                                &nbsp;<asp:Label ID="totTotalConstructionCostsOther_Hazmat" Text="test" runat="server"></asp:Label>
                            </asp:TableCell>
                            <asp:TableCell ID="Maint27" Wrap="true" HorizontalAlign="right" class="bgblue" Height="30">
                                &nbsp;<asp:Label ID="totTotalConstructionCostsOther_Maint" Text="test" runat="server"></asp:Label>
                            </asp:TableCell>
                            <asp:TableCell ID="Donation27" Wrap="true" HorizontalAlign="right" class="bgblue"
                                Height="30">
                                &nbsp;<asp:Label ID="totTotalConstructionCostsOther_Donation" Text="test" runat="server"></asp:Label>
                            </asp:TableCell>
                        </asp:TableRow>
                        <asp:TableRow ID="TableRow28" runat="server">
                            <asp:TableCell ID="rowLabel27" Wrap="true" class="bgblue" ColumnSpan="2" Height="30"
                                Text="10. Funiture and Group II Equipment" HorizontalAlign="left" Font-Bold="true" />
                            <asp:TableCell ID="TotalCost28" Wrap="true" Width="182px" HorizontalAlign="right"
                                class="bgblue" Height="30">
                                &nbsp;<asp:Label ID="totTotalFurngroup" Text="test" runat="server">test</asp:Label>
                            </asp:TableCell>
                            <asp:TableCell ID="State28" Wrap="true" HorizontalAlign="right" Height="30">
                                &nbsp;<asp:Label ID="lblFurnGroup2SF" Text="test" runat="server"></asp:Label>
                            </asp:TableCell>
                            <asp:TableCell ID="Bond28" Wrap="true" HorizontalAlign="right" Height="30">
                                &nbsp;<asp:Label ID="lblFurnGroupBond" Text="test" runat="server"></asp:Label>
                            </asp:TableCell>
                            <asp:TableCell ID="Grant28" Wrap="true" HorizontalAlign="right" Height="30">
                                &nbsp;<asp:Label ID="lblFurnGroupOther_Grant" Text="test" runat="server"></asp:Label>
                            </asp:TableCell>
                            <asp:TableCell ID="Hazmat28" Wrap="true" HorizontalAlign="right" Height="30">
                                &nbsp;<asp:Label ID="lblFurnGroupOther_Hazmat" Text="test" runat="server"></asp:Label>
                            </asp:TableCell>
                            <asp:TableCell ID="Maint28" Wrap="true" HorizontalAlign="right" Height="30">
                                &nbsp;<asp:Label ID="lblFurnGroupOther_Maint" Text="test" runat="server"></asp:Label>
                            </asp:TableCell>
                            <asp:TableCell ID="Donation28" Wrap="true" HorizontalAlign="right" Height="30">
                                &nbsp;<asp:Label ID="lblFurnGroupOther_Donation" Text="test" runat="server"></asp:Label>
                            </asp:TableCell>
                        </asp:TableRow>
                        <asp:TableRow ID="TableRow29" runat="server">
                            <asp:TableCell ID="rowLabel28" Wrap="true" class="bgblue" ColumnSpan="2" Height="30"
                                Text="Other" HorizontalAlign="left" Font-Bold="true" />
                            <asp:TableCell ID="TotalCost29" Wrap="true" Width="182px" HorizontalAlign="right"
                                class="bgblue" Height="30">
                                <asp:Label ID="totTotalOther" Text="test" runat="server">test</asp:Label>
                            </asp:TableCell>
                            <asp:TableCell ID="State29" Wrap="true" HorizontalAlign="right" Height="30">
                                &nbsp;<asp:Label ID="lblOtherSF" Text="test" runat="server"></asp:Label>
                            </asp:TableCell>
                            <asp:TableCell ID="Bond29" Wrap="true" HorizontalAlign="right" Height="30">
                                &nbsp;<asp:Label ID="lblOtherBond" Text="test" runat="server"></asp:Label>
                            </asp:TableCell>
                            <asp:TableCell ID="Grant29" Wrap="true" HorizontalAlign="right" Height="30">
                                &nbsp;<asp:Label ID="lblOtherOther_Grant" Text="test" runat="server"></asp:Label>
                            </asp:TableCell>
                            <asp:TableCell ID="Hazmat29" Wrap="true" HorizontalAlign="right" Height="30">
                                &nbsp;<asp:Label ID="lblOtherOther_Hazmat" Text="test" runat="server"></asp:Label>
                            </asp:TableCell>
                            <asp:TableCell ID="Maint29" Wrap="true" HorizontalAlign="right" Height="30">
                                &nbsp;<asp:Label ID="lblOtherOther_Maint" Text="test" runat="server"></asp:Label>
                            </asp:TableCell>
                            <asp:TableCell ID="Donation29" Wrap="true" HorizontalAlign="right" Height="30">
                                &nbsp;<asp:Label ID="lblOtherOther_Donation" Text="test" runat="server"></asp:Label>
                            </asp:TableCell>
                        </asp:TableRow>
                        <asp:TableRow ID="TableRow30" runat="server">
                            <asp:TableCell ID="rowLabel29" Wrap="true" class="bgblue" ColumnSpan="2" Height="30"
                                Text="Global Project Share" HorizontalAlign="left" Font-Bold="true" />
                            <asp:TableCell ID="TotalCost30" Wrap="true" Width="182px" HorizontalAlign="right"
                                class="bgblue" Height="30">
                                <asp:Label ID="totTotalGlobal" Text="test" runat="server">test</asp:Label>
                            </asp:TableCell>
                            <asp:TableCell ID="State30" Wrap="true" HorizontalAlign="right" BackColor="#feefb2"
                                Height="30">
                                &nbsp;<asp:Label ID="lblGlobalSF" Text="test" runat="server"></asp:Label>
                            </asp:TableCell>
                            <asp:TableCell ID="Bond30" Wrap="true" HorizontalAlign="right" BackColor="#feefb2"
                                Height="30">
                                &nbsp;<asp:Label ID="lblGlobalBond" Text="test" runat="server"></asp:Label>
                            </asp:TableCell>
                            <asp:TableCell ID="Grant30" Wrap="true" HorizontalAlign="right" BackColor="#feefb2"
                                Height="30">
                                &nbsp;<asp:Label ID="lblGlobalOther_Grant" Text="test" runat="server"></asp:Label>
                            </asp:TableCell>
                            <asp:TableCell ID="Hazmat30" Wrap="true" HorizontalAlign="right" BackColor="#feefb2"
                                Height="30">
                                &nbsp;<asp:Label ID="lblGlobalOther_Hazmat" Text="test" runat="server"></asp:Label>
                            </asp:TableCell>
                            <asp:TableCell ID="Maint30" Wrap="true" HorizontalAlign="right" BackColor="#feefb2"
                                Height="30">
                                &nbsp;<asp:Label ID="lblGlobalOther_Maint" Text="test" runat="server"></asp:Label>
                            </asp:TableCell>
                            <asp:TableCell ID="Donation30" Wrap="true" HorizontalAlign="right" BackColor="#feefb2"
                                Height="30">
                                &nbsp;<asp:Label ID="lblGlobalOther_Donation" Text="test" runat="server"></asp:Label>
                            </asp:TableCell>
                        </asp:TableRow>
                        <asp:TableRow ID="TableRow31" runat="server">
                            <asp:TableCell ID="rowLabel30" Wrap="true" class="bgblue" ColumnSpan="2" Height="51"
                                Text="Grand Totals:" HorizontalAlign="right" Font-Bold="true" />
                            <asp:TableCell ID="TotalCost31" Wrap="true" Width="182px" HorizontalAlign="right"
                                class="bgblue" Height="51">
                                <asp:Label ID="totGrandTotal" Text="test" runat="server"></asp:Label>
                            </asp:TableCell>
                            <asp:TableCell ID="State31" Wrap="true" HorizontalAlign="right" class="bgblue" Height="51">
                                <asp:Label ID="totSFTotal" Text="test" runat="server"></asp:Label>
                            </asp:TableCell>
                            <asp:TableCell ID="Bond31" Wrap="true" HorizontalAlign="right" class="bgblue" Height="51">
                                <asp:Label ID="totBondTotal" Text="test" runat="server"></asp:Label>
                            </asp:TableCell>
                            <asp:TableCell ID="Grant31" Wrap="true" HorizontalAlign="right" class="bgblue" Height="51">
                                <asp:Label ID="totOtherGrantTotal" Text="test" runat="server"></asp:Label>
                            </asp:TableCell>
                            <asp:TableCell ID="Hazmat31" Wrap="true" HorizontalAlign="right" class="bgblue" Height="51">
                                <asp:Label ID="totOtherHazmatTotal" Text="test" runat="server"></asp:Label>
                            </asp:TableCell>
                            <asp:TableCell ID="Maint31" Wrap="true" HorizontalAlign="right" class="bgblue" Height="51">
                                <asp:Label ID="totOtherMaintTotal" Text="test" runat="server"></asp:Label>
                            </asp:TableCell>
                            <asp:TableCell ID="Donation31" Wrap="true" HorizontalAlign="right" class="bgblue"
                                Height="51">
                                <asp:Label ID="totOtherDonationTotal" Text="test" runat="server"></asp:Label>
                            </asp:TableCell>
                        </asp:TableRow>
                        <%--</table>--%>
                    </asp:Table>
                    <strong>Notes and Assumptions: </strong>(<asp:HyperLink ID="lnkBudgetAssumptionsEdit"
                        runat="server">edit</asp:HyperLink>)
                    <asp:Label ID="LabelNotes" runat="server" Text="Notes"></asp:Label></div>
            </div>
        </div>
    </div>
    <telerik:RadScriptBlock ID="RadScriptBlock1" runat="server">

        <script type="text/javascript" language="javascript">

            var projectid = '<%=nProjectID%>';
            var collegeid = '<%=nCollegeID%>';



            // This code is for the hover window 

            function OpenWindow(WindowName) {
                window.radopen(null, WindowName);
            }
            function GetElementPosition(el) {
                var parent = null;
                var pos = { x: 0, y: 0 };
                var box;

                if (el.getBoundingClientRect) {
                    // IE   
                    box = el.getBoundingClientRect();
                    var scrollTop = document.documentElement.scrollTop || document.body.scrollTop;
                    var scrollLeft = document.documentElement.scrollLeft || document.body.scrollLeft;

                    pos.x = box.left + scrollLeft - 2;
                    pos.y = box.top + scrollTop - 2;

                    return pos;
                }
                else if (document.getBoxObjectFor) {
                    // gecko   
                    box = document.getBoxObjectFor(el);
                    pos.x = box.x - 2;
                    pos.y = box.y - 2;
                }
                else {
                    // safari/opera   
                    pos.x = el.offsetLeft;
                    pos.y = el.offsetTop;
                    parent = el.offsetParent;
                    if (parent != el) {
                        while (parent) {
                            pos.x += parent.offsetLeft;
                            pos.y += parent.offsetTop;
                            parent = parent.offsetParent;
                        }
                    }
                }


                if (window.opera) {
                    parent = el.offsetParent;

                    while (parent && parent.tagName != 'BODY' && parent.tagName != 'HTML') {
                        pos.x -= parent.scrollLeft;
                        pos.y -= parent.scrollTop;
                        parent = parent.offsetParent;
                    }
                }
                else {
                    parent = el.parentNode;
                    while (parent && parent.tagName != 'BODY' && parent.tagName != 'HTML') {
                        pos.x -= parent.scrollLeft;
                        pos.y -= parent.scrollTop;

                        parent = parent.parentNode;
                    }
                }
                return pos;
            }

            var skip_close = false;
            var param_value = '';

            function OpenWindowWithParam(WindowName, ParamValue, element) {
                if (param_value == ParamValue) return;
                //alert(param_value + '==' +  ParamValue)
                var oWindow = window.radopen(null, WindowName);
                oWindow.SetUrl("budget_view_popup.aspx?parms=" + escape(ParamValue));

                var pos = GetElementPosition(element);
                var X = pos.x;
                var Y = pos.y;

                oWindow.MoveTo(X - 250, Y + element.offsetHeight);

                param_value = ParamValue;
                skip_close = false;
            }



            function HandleClick(WindowName, ParamValue) {
                skip_close = true;
            }

            function CloseWindow(WindowName) {
                if (skip_close) return
                var oManager = GetRadWindowManager();
                var oWindow = oManager.GetWindowByName(WindowName);
                param_value = '';
                if (oWindow != null) {
                    oWindow.Close();
                }
            }


            function EditSettings() {

                var oWnd = window.radopen("admin_budget_pagesettings_edit.aspx?ProjectID=" + projectid, "SettingsWindow");
                return false;
            }


            function EditBudgetItems(fldname,element) {

                var oWindow = window.radopen(null, "BudgetItemsEditWindow");
                oWindow.SetUrl("budget_items.aspx?CollegeID=" + collegeid + "&ProjectID=" + projectid + "&FieldName=" + fldname);

                var pos = GetElementPosition(element);
                var X = pos.x;
                var Y = pos.y;

                //oWindow.MoveTo(X - 250, Y + element.offsetHeight);
                //alert(element.offsetHeight);
                //alert(X);
                //alert(Y);
                oWindow.MoveTo(100, Y - 125);
   
                return false;
            }
 
        </script>

    </telerik:RadScriptBlock>


</asp:Content>
