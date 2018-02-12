<%@ Page Language="vb" %>

<%@ Register Assembly="Telerik.Web.UI" Namespace="Telerik.Web.UI" TagPrefix="telerik" %>
<%@ Import Namespace="Prompt" %>

<script runat="server">

    'set up vars
    Private nProjectID As Integer
    Private nCollegeID As Integer
    Private nTotalBudget As Double = 0
    Private nSFAmt As Double = 0
    'Dim nDFSSAmt As Double = 0
    'Dim nDFNSSAmt As Double = 0
    Private nBFAmt As Double = 0

    Private nOFAmt_Grant As Double = 0
    Private nOFAmt_Hazmat As Double = 0
    Private nOFAmt_Donation As Double = 0
    Private nOFAmt_Maint As Double = 0

    Private bNewConst As Boolean
    
    Private n2a As Double
    Private n2b As Double
    Private n3a As Double
    Private n3c As Double
    Private n3d As Double
    Private n4e As Double
    Private n5 As Double
    Private n6 As Double
    Private n7a As Double
    Private n7b As Double
    Private n8 As Double
    Private n9 As Double

    Private Sub Page_Load(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MyBase.Load

        
        ProcLib.CheckSession(Page)
        ProcLib.LoadPopupJscript(Page)
        
        nProjectID = Request.QueryString("ProjectID")
        nCollegeID = Request.QueryString("CollegeID")

        'set up help button
        Session("PageID") = "JCAFGenerator"
        butHelp.Attributes.Add("onclick", "openPopup('help_view.aspx','pophelp',550,450,'yes');")
        butHelp.NavigateUrl = "#"

        'totproject.Focus()

        lblMessage.Text = ""

        If Not IsPostBack Then
            'check for current total allocations
            Using rs As New PromptDataHelper
                rs.FillReader("SELECT (CASE WHEN SUM(Amount) IS NULL THEN 0 ELSE Sum(Amount) END) as tot FROM TransactionDetail WHERE ProjectID = " & Request.QueryString("ProjectID"))
                While rs.Reader.Read
                    If rs.Reader("Tot") > 0 Then
                        lblMessage.Text = "Sorry, you cannot use this tool when there are existing transactions that have amounts allocated to this budget."
                        butGenerate.Enabled = False
                    End If
                End While
                rs.Reader.Close()
            End Using
            SetCalcDefaults()
        End If
 
    End Sub
    
    Private Sub SetCalcDefaults(Optional ByVal ZeroOut As Boolean = False)
        'set up values for spread
        
        If ZeroOut Then
            n2a = 0     'Plan Arch Fees
            n2b = 0      'Plan PM
            n3a = 0      'workDraw Arch Fee
            n3c = 0      'SA work draw plan check fee
            n3d = 0      'CC Plan Check Fee
            n4e = 0      'Construction - reconstruction     'this is total construction/reconstruction
            n5 = 0       'Contingency
            n6 = 0       'A and E Oversight
            n7a = 0      'tests
            n7b = 0      'Inspections
            n8 = 0      'Construction Mgmnt
            n9 = 0                  'Other Other       'this holds balance of any amount needed to round to 100%
        Else
            n2a = 0.0287 * 100       'Plan Arch Fees
            n2b = 0.0082 * 100    'Plan PM
            n3a = 0.0369 * 100     'workDraw Arch Fee
            n3c = 0.0045 * 100   'SA work draw plan check fee
            n3d = 0.0023 * 100      'CC Plan Check Fee
            n4e = 0.8209 * 100      'Construction - reconstruction     'this is total construction/reconstruction
            n5 = 0.0575 * 100     'Contingency
            n6 = 0.0164 * 100     'A and E Oversight
            n7a = 0.0082 * 100      'tests
            n7b = 0                 'inspections
            n8 = 0.0164 * 100     'Construction Mgmnt
            n9 = 0                  'Other Other       'this holds balance of any amount needed to round to 100%
        End If
 
        txtN2a.Text = n2a
        txtN2b.Text = n2b
        txtN3a.Text = n3a
        txtN3c.Text = n3c
        txtN3d.Text = n3d
        
        txtTotalConstrReconstr.Text = n4e
        
        txtN5.Text = n5
        txtN6.Text = n6
        txtN7a.Text = n7a
        txtN7b.Text = n7b
        txtN8.Text = n8
        
        txtN9.Text = n9
        
        txtTotalPercentage.Text = n2a + n2b + n3a + n3c + n3d + n4e + n5 + n6 + n7a + n7b + n8 + n9
                
        
    End Sub
    
    Protected Sub ChangePercentage(ByVal sender As Object, ByVal e As System.EventArgs)
          
        'add all the current values
        Dim nTotal As Double = 0
        
        'check that the total amount is not 100
        nTotal = nTotal + Val(txtN2a.Text)
        nTotal = nTotal + Val(txtN2b.Text)
        nTotal = nTotal + Val(txtN3a.Text)
        nTotal = nTotal + Val(txtN3c.Text)
        nTotal = nTotal + Val(txtN3d.Text)
        nTotal = nTotal + Val(txtN5.Text)
        nTotal = nTotal + Val(txtN6.Text)
        nTotal = nTotal + Val(txtN7a.Text)
        nTotal = nTotal + Val(txtN7b.Text)
        nTotal = nTotal + Val(txtN8.Text)
        nTotal = nTotal + Val(txtN9.Text)
        
        If nTotal > 100 Then
            lblMessage.Text = "Sorry, total of all percentages cannot exceed 100."
        Else
            'subtract the total from 1 and assign result to Construction/Reconstruction amount
            txtTotalConstrReconstr.Text = 100 - nTotal
            
        End If
 
        txtTotalPercentage.Text = (nTotal + txtTotalConstrReconstr.Text)
        

    End Sub
    
    Private Sub butGenerate_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles butGenerate.Click
        'Generate the budget
        
        'n2a = 0.0287 / 100      'Plan Arch Fees
        'n2b = 0.0082 / 100      'Plan PM
        'n3a = 0.0369 / 100      'workDraw Arch Fee
        'n3c = 0.0045 / 100      'SA work draw plan check fee
        'n3d = 0.0023 / 100      'CC Plan Check Fee
        'n4e = 0.8209 / 100      'Construction - reconstruction     'this is total construction/reconstruction
        'n5 = 0.0575 / 100       'Contingency
        'n6 = 0.0164 / 100       'A and E Oversight
        'n7a = 0.0082 / 100      'tests
        'n7b = 0     'Inspections
        'n8 = 0.0164 / 100       'Construction Mgmnt
        'n9 = 0                  'Other Other       'this holds balance of any amount needed to round to 100%
        
       
        If totproject.Text = "" Then
            lblMessage.Text = "You must enter a Total Project Budget for this Project."
            Exit Sub
        End If
        
        Dim nFix As Double = 10000    'convert the percentages for math
        n2a = Val(txtN2a.Text) / nFix
        n2b = Val(txtN2b.Text) / nFix
        n3a = Val(txtN3a.Text) / nFix
        n3c = Val(txtN3c.Text) / nFix
        n3d = Val(txtN3d.Text) / nFix
        n4e = Val(txtTotalConstrReconstr.Text) / nFix
        n5 = Val(txtN5.Text) / nFix
        n6 = Val(txtN6.Text) / nFix
        n7a = Val(txtN7a.Text) / nFix
        n7b = Val(txtN7b.Text) / nFix
        n8 = Val(txtN8.Text) / nFix
        n9 = Val(txtN9.Text) / nFix

        nTotalBudget = totproject.Text

        If SF.Text <> "" Then
            nSFAmt = SF.Text
        End If
        'If DFSS.Text <> "" Then
        '    nDFSSAmt = DFSS.Text
        'End If
        'If DFNSS.Text <> "" Then
        '    nDFNSSAmt = DFNSS.Text
        'End If
        If BF.Text <> "" Then
            nBFAmt = BF.Text
        End If
        If OFGrant.Text <> "" Then
            nOFAmt_Grant = OFGrant.Text
        End If
        If OFHazmat.Text <> "" Then
            nOFAmt_Hazmat = OFHazmat.Text
        End If
        If OFDonation.Text <> "" Then
            nOFAmt_Donation = OFDonation.Text
        End If
        If OFMaint.Text <> "" Then
            nOFAmt_Maint = OFMaint.Text
        End If

        If NewConst.Checked Then
            bNewConst = True
        Else
            bNewConst = False
        End If

        Using rsTarget As New PromptDataHelper
                    
            'Remove Existing Budget REcords if any
            rsTarget.ExecuteNonQuery("DELETE FROM BudgetItems WHERE ProjectID = " & nProjectID)
            rsTarget.ExecuteNonQuery("DELETE FROM BudgetObjectCodes WHERE ProjectID = " & nProjectID)
           
            Using rsSource As New PromptDataHelper
                rsSource.FillDataTable("SELECT * FROM BudgetFieldsTable")
                Dim row As DataRow
                Dim fld As String
                Dim sSQL As String

                For Each row In rsSource.DataTable.Rows()
                    fld = row.Item("ColumnName")

                    Dim Val As Double = 0

                    Select Case fld

                        Case "PlanSF_A"
                            Val = nTotalBudget * nSFAmt * n2a


                            'Case "PlanDFSS_A"
                            '    Val = nTotalBudget * nDFSSAmt * n2a


                            'Case "PlanDFNSS_A"
                            '    Val = nTotalBudget * nDFNSSAmt * n2a


                        Case "PlanBond_A"
                            Val = nTotalBudget * nBFAmt * n2a


                        Case "PlanOther_A_Grant"
                            Val = nTotalBudget * nOFAmt_Grant * n2a


                        Case "PlanOther_A_Hazmat"
                            Val = nTotalBudget * nOFAmt_Hazmat * n2a


                        Case "PlanOther_A_Donation"
                            Val = nTotalBudget * nOFAmt_Donation * n2a


                        Case "PlanOther_A_Maint"
                            Val = nTotalBudget * nOFAmt_Maint * n2a


                            '--------------------------------------------
                        Case "PlanSF_B"
                            Val = nTotalBudget * nSFAmt * n2b


                            'Case "PlanDFSS_B"
                            '    Val = nTotalBudget * nDFSSAmt * n2b


                            'Case "PlanDFNSS_B"
                            '    Val = nTotalBudget * nDFNSSAmt * n2b


                        Case "PlanBond_B"
                            Val = nTotalBudget * nBFAmt * n2b


                        Case "PlanOther_B_Grant"
                            Val = nTotalBudget * nOFAmt_Grant * n2b


                        Case "PlanOther_B_Hazmat"
                            Val = nTotalBudget * nOFAmt_Hazmat * n2b


                        Case "PlanOther_B_Donation"
                            Val = nTotalBudget * nOFAmt_Donation * n2b


                        Case "PlanOther_B_Maint"
                            Val = nTotalBudget * nOFAmt_Maint * n2b


                            '--------------------------------------------
                        Case "WorkDrawSF_A"
                            Val = nTotalBudget * nSFAmt * n3a


                            'Case "WorkDrawDFSS_A"
                            '    Val = nTotalBudget * nDFSSAmt * n3a


                            'Case "WorkDrawDFNSS_A"
                            '    Val = nTotalBudget * nDFNSSAmt * n3a


                        Case "WorkDrawBond_A"
                            Val = nTotalBudget * nBFAmt * n3a


                        Case "WorkDrawOther_A_Grant"
                            Val = nTotalBudget * nOFAmt_Grant * n3a


                        Case "WorkDrawOther_A_Hazmat"
                            Val = nTotalBudget * nOFAmt_Hazmat * n3a


                        Case "WorkDrawOther_A_Donation"
                            Val = nTotalBudget * nOFAmt_Donation * n3a


                        Case "WorkDrawOther_A_Maint"
                            Val = nTotalBudget * nOFAmt_Maint * n3a

                            '--------------------------------------------
                        Case "WorkDrawSF_C"
                            Val = nTotalBudget * nSFAmt * n3c


                            'Case "WorkDrawDFSS_C"
                            '    Val = nTotalBudget * nDFSSAmt * n3c


                            'Case "WorkDrawDFNSS_C"
                            '    Val = nTotalBudget * nDFNSSAmt * n3c


                        Case "WorkDrawBond_C"
                            Val = nTotalBudget * nBFAmt * n3c


                        Case "WorkDrawOther_C_Grant"
                            Val = nTotalBudget * nOFAmt_Grant * n3c


                        Case "WorkDrawOther_C_Hazmat"
                            Val = nTotalBudget * nOFAmt_Hazmat * n3c


                        Case "WorkDrawOther_C_Donation"
                            Val = nTotalBudget * nOFAmt_Donation * n3c


                        Case "WorkDrawOther_C_Maint"
                            Val = nTotalBudget * nOFAmt_Maint * n3c


                            '--------------------------------------------
                        Case "WorkDrawSF_D"
                            Val = nTotalBudget * nSFAmt * n3d


                            'Case "WorkDrawDFSS_D"
                            '    Val = nTotalBudget * nDFSSAmt * n3d


                            'Case "WorkDrawDFNSS_D"
                            '    Val = nTotalBudget * nDFNSSAmt * n3d


                        Case "WorkDrawBond_D"
                            Val = nTotalBudget * nBFAmt * n3d


                        Case "WorkDrawOther_D_Grant"
                            Val = nTotalBudget * nOFAmt_Grant * n3d


                        Case "WorkDrawOther_D_Hazmat"
                            Val = nTotalBudget * nOFAmt_Hazmat * n3d


                        Case "WorkDrawOther_D_Donation"
                            Val = nTotalBudget * nOFAmt_Donation * n3d


                        Case "WorkDrawOther_D_Maint"
                            Val = nTotalBudget * nOFAmt_Maint * n3d


                            '--------------------------------------------
                        Case "ContingencySF"
                            Val = nTotalBudget * nSFAmt * n5


                            'Case "ContingencyDFSS"
                            '    Val = nTotalBudget * nDFSSAmt * n5


                            'Case "ContingencyDFNSS"
                            '    Val = nTotalBudget * nDFNSSAmt * n5


                        Case "ContingencyBond"
                            Val = nTotalBudget * nBFAmt * n5


                        Case "ContingencyOther_Grant"
                            Val = nTotalBudget * nOFAmt_Grant * n5


                        Case "ContingencyOther_Hazmat"
                            Val = nTotalBudget * nOFAmt_Hazmat * n5


                        Case "ContingencyOther_Donation"
                            Val = nTotalBudget * nOFAmt_Donation * n5


                        Case "ContingencyOther_Maint"
                            Val = nTotalBudget * nOFAmt_Maint * n5


                            '--------------------------------------------
                        Case "AEOversightSF"
                            Val = nTotalBudget * nSFAmt * n6


                            'Case "AEOversightDFSS"
                            '    Val = nTotalBudget * nDFSSAmt * n6


                            'Case "AEOversightDFNSS"
                            '    Val = nTotalBudget * nDFNSSAmt * n6


                        Case "AEOversightBond"
                            Val = nTotalBudget * nBFAmt * n6


                        Case "AEOversightOther_Grant"
                            Val = nTotalBudget * nOFAmt_Grant * n6


                        Case "AEOversightOther_Hazmat"
                            Val = nTotalBudget * nOFAmt_Hazmat * n6


                        Case "AEOversightOther_Donation"
                            Val = nTotalBudget * nOFAmt_Donation * n6


                        Case "AEOversightOther_Maint"
                            Val = nTotalBudget * nOFAmt_Maint * n6



                            '--------------------------------------------
                        Case "TestsSF_A"
                            Val = nTotalBudget * nSFAmt * n7a


                            'Case "TestsDFSS_A"
                            '    Val = nTotalBudget * nDFSSAmt * n7a


                            'Case "TestsDFNSS_A"
                            '    Val = nTotalBudget * nDFNSSAmt * n7a


                        Case "TestsBond_A"
                            Val = nTotalBudget * nBFAmt * n7a


                        Case "TestsOther_A_Grant"
                            Val = nTotalBudget * nOFAmt_Grant * n7a


                        Case "TestsOther_A_Hazmat"
                            Val = nTotalBudget * nOFAmt_Hazmat * n7a


                        Case "TestsOther_A_Donation"
                            Val = nTotalBudget * nOFAmt_Donation * n7a


                        Case "TestsOther_A_Maint"
                            Val = nTotalBudget * nOFAmt_Maint * n7a


                            '--------------------------------------------
                    
                        Case "TestsSF_B"
                            Val = nTotalBudget * nSFAmt * n7b


                            'Case "TestsDFSS_A"
                            '    Val = nTotalBudget * nDFSSAmt * n7a


                            'Case "TestsDFNSS_A"
                            '    Val = nTotalBudget * nDFNSSAmt * n7a


                        Case "TestsBond_B"
                            Val = nTotalBudget * nBFAmt * n7b


                        Case "TestsOther_B_Grant"
                            Val = nTotalBudget * nOFAmt_Grant * n7b


                        Case "TestsOther_B_Hazmat"
                            Val = nTotalBudget * nOFAmt_Hazmat * n7b


                        Case "TestsOther_B_Donation"
                            Val = nTotalBudget * nOFAmt_Donation * n7b


                        Case "TestsOther_B_Maint"
                            Val = nTotalBudget * nOFAmt_Maint * n7b


                            '--------------------------------------------


                        Case "ConstMgmtSF"
                            Val = nTotalBudget * nSFAmt * n8


                            'Case "ConstMgmtDFSS"
                            '    Val = nTotalBudget * nDFSSAmt * n8


                            'Case "ConstMgmtDFNSS"
                            '    Val = nTotalBudget * nDFNSSAmt * n8


                        Case "ConstMgmtBond"
                            Val = nTotalBudget * nBFAmt * n8


                        Case "ConstMgmtOther_Grant"
                            Val = nTotalBudget * nOFAmt_Grant * n8


                        Case "ConstMgmtOther_Hazmat"
                            Val = nTotalBudget * nOFAmt_Hazmat * n8


                        Case "ConstMgmtOther_Donation"
                            Val = nTotalBudget * nOFAmt_Donation * n8


                        Case "ConstMgmtOther_Maint"
                            Val = nTotalBudget * nOFAmt_Maint * n8


                            '--------------------------------------------
                    
                        Case "OtherSF"
                            Val = nTotalBudget * nSFAmt * n9
                    
                        Case "OtherBond"
                            Val = nTotalBudget * nBFAmt * n9


                        Case "OtherOther_Grant"
                            Val = nTotalBudget * nOFAmt_Grant * n9


                        Case "OtherOther_Hazmat"
                            Val = nTotalBudget * nOFAmt_Hazmat * n9


                        Case "OtherOther_Donation"
                            Val = nTotalBudget * nOFAmt_Donation * n9


                        Case "OtherOther_Maint"
                            Val = nTotalBudget * nOFAmt_Maint * n9
                    
  
                    End Select

                    If bNewConst = True Then      'put in new contruction line instead

                        Select Case fld
                            Case "ConstrSF_F"
                                Val = nTotalBudget * nSFAmt * n4e


                                'Case "ConstrDFSS_F"
                                '    Val = nTotalBudget * nDFSSAmt * n4e


                                'Case "ConstrDFNSS_F"
                                '    Val = nTotalBudget * nDFNSSAmt * n4e


                            Case "ConstrBond_F"
                                Val = nTotalBudget * nBFAmt * n4e


                            Case "ConstrOther_F_Grant"
                                Val = nTotalBudget * nOFAmt_Grant * n4e


                            Case "ConstrOther_F_Hazmat"
                                Val = nTotalBudget * nOFAmt_Hazmat * n4e


                            Case "ConstrOther_F_Donation"
                                Val = nTotalBudget * nOFAmt_Donation * n4e


                            Case "ConstrOther_F_Maint"
                                Val = nTotalBudget * nOFAmt_Maint * n4e



                        End Select
                    Else

                        Select Case fld
                            Case "ConstrSF_E"
                                Val = nTotalBudget * nSFAmt * n4e


                                'Case "ConstrDFSS_E"
                                '    Val = nTotalBudget * nDFSSAmt * n4e


                                'Case "ConstrDFNSS_E"
                                '    Val = nTotalBudget * nDFNSSAmt * n4e


                            Case "ConstrBond_E"
                                Val = nTotalBudget * nBFAmt * n4e


                            Case "ConstrOther_E_Grant"
                                Val = nTotalBudget * nOFAmt_Grant * n4e


                            Case "ConstrOther_E_Hazmat"
                                Val = nTotalBudget * nOFAmt_Hazmat * n4e


                            Case "ConstrOther_E_Donation"
                                Val = nTotalBudget * nOFAmt_Donation * n4e


                            Case "ConstrOther_E_Maint"
                                Val = nTotalBudget * nOFAmt_Maint * n4e


                        End Select
                    End If

                    If Val <> 0 Then
                        sSQL = "INSERT INTO BudgetItems (DistrictID,CollegeID,ProjectID,BudgetField,Amount,LastUpdateBy,LastUpdateOn) "
                        sSQL = sSQL & "VALUES(" & Session("DistrictID") & "," & nCollegeID & "," & nProjectID & ",'" & fld & "'," & Val & ",'JCAF GEN','" & Now() & "')"
                        rsTarget.ExecuteNonQuery(sSQL)
                
                        'add an unallocated amount reocrd to the BudgetObjectCodes Table
                        sSQL = "INSERT INTO BudgetObjectCodes (DistrictID,CollegeID,ProjectID,JCAFColumnName,Amount,ObjectCode,Description,LastUpdateBy,LastUpdateOn) "
                        sSQL = sSQL & "VALUES(" & Session("DistrictID") & "," & nCollegeID & "," & nProjectID & ",'" & fld & "',"
                        sSQL = sSQL & Val & ",'_unallcoated_','UnAllocated Amount','JCAF GEN','" & Now() & "')"
                        rsTarget.ExecuteNonQuery(sSQL)

                    End If

                Next

            End Using
        End Using
       

        Session("RtnFromEdit") = True
        ProcLib.CloseAndRefresh(Page)

    End Sub
   

    Protected Sub butReset_Click(ByVal sender As Object, ByVal e As System.EventArgs)
        SetCalcDefaults()
    End Sub
    
  
    Protected Sub butClear_Click(ByVal sender As Object, ByVal e As System.EventArgs)
        SetCalcDefaults(True)
    End Sub
</script>

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">
<html>
<head>
    <title>JCAFGenerator</title>
    <meta content="Microsoft Visual Studio .NET 7.1" name="GENERATOR">
    <meta content="Visual Basic .NET 7.1" name="CODE_LANGUAGE">
    <meta content="http://schemas.microsoft.com/intellisense/ie5" name="vs_targetSchema">
    <link href="Styles.css" type="text/css" rel="stylesheet">
</head>
<body>
    <form id="Form1" method="post" runat="server">
     <telerik:RadScriptManager ID="RadScriptManager1" runat="server" />
    <table id="Table1" style="z-index: 120; left: 8px; position: absolute; top: 8px;
        height: 2px" cellspacing="1" cellpadding="1" width="96%" border="0">
        <tr>
            <td style="height: 6px" valign="top">
                <asp:Label ID="Label1" runat="server" Height="18px" Width="136px" CssClass="PageHeading"
                    EnableViewState="False">JCAF Generator</asp:Label>
            </td>
            <td style="height: 6px" valign="top" align="right">
                <asp:HyperLink ID="butHelp" runat="server" ImageUrl="images/button_help.gif">HyperLink</asp:HyperLink>
            </td>
        </tr>
    </table>
    <telerik:RadNumericTextBox Label="" ID="OFMaint" Style="z-index: 126; left: 303px;
        position: absolute; top: 242px" TabIndex="7" runat="server" Width="45px " SelectionOnFocus="SelectAll"
        MinValue="0" AutoPostBack="False" NumberFormat-DecimalDigits="2">
        <NumberFormat AllowRounding="False" DecimalDigits="4"></NumberFormat>
    </telerik:RadNumericTextBox>
    <telerik:RadNumericTextBox ID="OFDonation" Style="z-index: 125; left: 375px; position: absolute;
        top: 241px" TabIndex="7" runat="server" Width="45px " SelectionOnFocus="SelectAll"
        MinValue="0" AutoPostBack="False" NumberFormat-DecimalDigits="2">
        <NumberFormat AllowRounding="False" DecimalDigits="4"></NumberFormat>
    </telerik:RadNumericTextBox>
    <telerik:RadNumericTextBox ID="OFHazmat" Style="z-index: 124; left: 230px; position: absolute;
        top: 242px" TabIndex="7" runat="server" Width="45px " SelectionOnFocus="SelectAll"
        MinValue="0" AutoPostBack="False" NumberFormat-DecimalDigits="2">
        <NumberFormat AllowRounding="False" DecimalDigits="4"></NumberFormat>
    </telerik:RadNumericTextBox>
    <asp:Label ID="Label13" Style="z-index: 123; left: 304px; position: absolute; top: 220px"
        runat="server">Maint %: </asp:Label>
    <asp:Label ID="Label12" Style="z-index: 122; left: 371px; position: absolute; top: 220px"
        runat="server">Donation %: </asp:Label>
    <asp:Label ID="Label11" Style="z-index: 121; left: 230px; position: absolute; top: 220px"
        runat="server">Hazmat %:</asp:Label>
    <telerik:RadNumericTextBox ID="OFGrant" Style="z-index: 119; left: 158px; position: absolute;
        top: 242px" TabIndex="7" runat="server" Width="45px " SelectionOnFocus="SelectAll"
        MinValue="0" AutoPostBack="False" NumberFormat-DecimalDigits="2">
        <NumberFormat AllowRounding="False" DecimalDigits="4"></NumberFormat>
    </telerik:RadNumericTextBox>
    <hr style="z-index: 113; left: 8px; position: absolute; top: 40px" width="96%" size="1">
    <telerik:RadNumericTextBox ID="BF" Style="z-index: 118; left: 85px; position: absolute;
        top: 242px" TabIndex="6" runat="server" Width="45px " SelectionOnFocus="SelectAll"
        MinValue="0" AutoPostBack="False" NumberFormat-DecimalDigits="2">
        <NumberFormat AllowRounding="False" DecimalDigits="4"></NumberFormat>
    </telerik:RadNumericTextBox>
    <telerik:RadNumericTextBox ID="SF" Style="z-index: 115; left: 11px; position: absolute;
        top: 242px" TabIndex="3" runat="server" Width="45px " SelectionOnFocus="SelectAll"
        MinValue="0" AutoPostBack="False" NumberFormat-DecimalDigits="2">
        <NumberFormat AllowRounding="False" DecimalDigits="4"></NumberFormat>
    </telerik:RadNumericTextBox>
    <telerik:RadNumericTextBox ID="txtN2a" runat="server" Style="z-index: 115; left: 198px;
        position: absolute; top: 317px" TabIndex="3" Width="55px" OnTextChanged="ChangePercentage"
        AutoPostBack="True " SelectionOnFocus="SelectAll" MinValue="0" NumberFormat-DecimalDigits="2">
        <NumberFormat AllowRounding="False" DecimalDigits="4"></NumberFormat>
    </telerik:RadNumericTextBox>
    <telerik:RadNumericTextBox ID="txtN2b" runat="server" Style="z-index: 115; left: 198px;
        position: absolute; top: 343px" TabIndex="3" Width="55px" OnTextChanged="ChangePercentage"
        AutoPostBack="True " SelectionOnFocus="SelectAll" MinValue="0" NumberFormat-DecimalDigits="2">
        <NumberFormat AllowRounding="False" DecimalDigits="4"></NumberFormat>
    </telerik:RadNumericTextBox>
    <telerik:RadNumericTextBox ID="txtN3a" runat="server" Style="z-index: 115; left: 198px;
        position: absolute; top: 370px" TabIndex="3" Width="55px" OnTextChanged="ChangePercentage"
        AutoPostBack="True " SelectionOnFocus="SelectAll" MinValue="0" NumberFormat-DecimalDigits="2">
        <NumberFormat AllowRounding="False" DecimalDigits="4"></NumberFormat>
    </telerik:RadNumericTextBox>
    <telerik:RadNumericTextBox ID="txtN3c" runat="server" Style="z-index: 115; left: 198px;
        position: absolute; top: 398px" TabIndex="3" Width="55px" OnTextChanged="ChangePercentage"
        AutoPostBack="True " SelectionOnFocus="SelectAll" MinValue="0" NumberFormat-DecimalDigits="2">
        <NumberFormat AllowRounding="False" DecimalDigits="4"></NumberFormat>
    </telerik:RadNumericTextBox>
    <telerik:RadNumericTextBox ID="txtN3d" runat="server" Style="z-index: 115; left: 198px;
        position: absolute; top: 427px" TabIndex="3" Width="55px" OnTextChanged="ChangePercentage"
        AutoPostBack="True " SelectionOnFocus="SelectAll" MinValue="0" NumberFormat-DecimalDigits="2">
        <NumberFormat AllowRounding="False" DecimalDigits="4"></NumberFormat>
    </telerik:RadNumericTextBox>
    <telerik:RadNumericTextBox ID="txtN5" runat="server" Style="z-index: 115; left: 198px;
        position: absolute; top: 455px" TabIndex="3" Width="55px" OnTextChanged="ChangePercentage"
        AutoPostBack="True " SelectionOnFocus="SelectAll" MinValue="0" NumberFormat-DecimalDigits="2">
        <NumberFormat AllowRounding="False" DecimalDigits="4"></NumberFormat>
    </telerik:RadNumericTextBox>
    <telerik:RadNumericTextBox ID="txtN6" runat="server" Style="z-index: 115; left: 198px;
        position: absolute; top: 483px" TabIndex="3" Width="55px" OnTextChanged="ChangePercentage"
        AutoPostBack="True " SelectionOnFocus="SelectAll" MinValue="0" NumberFormat-DecimalDigits="2">
        <NumberFormat AllowRounding="False" DecimalDigits="4"></NumberFormat>
    </telerik:RadNumericTextBox>
    <telerik:RadNumericTextBox ID="txtN7a" runat="server" Style="z-index: 115; left: 198px;
        position: absolute; top: 511px" TabIndex="3" Width="55px" OnTextChanged="ChangePercentage"
        AutoPostBack="True " SelectionOnFocus="SelectAll" MinValue="0" NumberFormat-DecimalDigits="2">
        <NumberFormat AllowRounding="False" DecimalDigits="4"></NumberFormat>
    </telerik:RadNumericTextBox>
    <telerik:RadNumericTextBox ID="txtN7b" runat="server" Style="z-index: 115; left: 198px;
        position: absolute; top: 539px" TabIndex="3" Width="55px" OnTextChanged="ChangePercentage"
        AutoPostBack="True " SelectionOnFocus="SelectAll" MinValue="0" NumberFormat-DecimalDigits="2">
        <NumberFormat AllowRounding="False" DecimalDigits="4"></NumberFormat>
    </telerik:RadNumericTextBox>
    <telerik:RadNumericTextBox ID="txtN8" runat="server" Style="z-index: 115; left: 198px;
        position: absolute; top: 566px" TabIndex="3" Width="55px" OnTextChanged="ChangePercentage"
        AutoPostBack="True " SelectionOnFocus="SelectAll" MinValue="0" NumberFormat-DecimalDigits="2">
        <NumberFormat AllowRounding="False" DecimalDigits="4"></NumberFormat>
    </telerik:RadNumericTextBox>
    <telerik:RadNumericTextBox ID="txtN9" runat="server" Style="z-index: 115; left: 198px;
        position: absolute; top: 595px" TabIndex="3" Width="55px" OnTextChanged="ChangePercentage"
        AutoPostBack="True " SelectionOnFocus="SelectAll" MinValue="0" NumberFormat-DecimalDigits="2">
        <NumberFormat AllowRounding="False" DecimalDigits="4"></NumberFormat>
    </telerik:RadNumericTextBox>
    <telerik:RadNumericTextBox ID="txtTotalConstrReconstr" runat="server" Style="z-index: 115;
        left: 198px; position: absolute; top: 634px" Width="55px"  SelectionOnFocus="SelectAll" MinValue="0" NumberFormat-DecimalDigits="2">
        <NumberFormat AllowRounding="False" DecimalDigits="4"></NumberFormat>
    </telerik:RadNumericTextBox>
    <telerik:RadNumericTextBox ID="txtTotalPercentage" runat="server" Enabled="False"
        Style="z-index: 115; left: 198px; position: absolute; top: 662px" Width="55px"
         SelectionOnFocus="SelectAll"
        MinValue="0" NumberFormat-DecimalDigits="2">
        <NumberFormat AllowRounding="False" DecimalDigits="4"></NumberFormat>
    </telerik:RadNumericTextBox>
    <asp:Label ID="Label10" Style="z-index: 114; left: 158px; position: absolute; top: 221px"
        runat="server">Grant %: </asp:Label>
    <asp:Label ID="Label9" Style="z-index: 112; left: 89px; position: absolute; top: 221px"
        runat="server">Bond %: </asp:Label>
    <asp:Label ID="Label6" Style="z-index: 109; left: 10px; position: absolute; top: 221px"
        runat="server">State %: </asp:Label>
    <asp:Label ID="Label8" runat="server" Style="z-index: 109; left: 59px; position: absolute;
        top: 662px">Total Budget %: </asp:Label>
    &nbsp;
    <asp:Label ID="Label14" runat="server" Style="z-index: 109; left: 29px; position: absolute;
        top: 319px">Planning Arch Fees (2A) %: </asp:Label>
    <asp:Label ID="Label15" runat="server" Style="z-index: 109; left: 10px; position: absolute;
        top: 344px">Planning Project Mgmt (2B) %: </asp:Label>
    <asp:Label ID="Label16" runat="server" Style="z-index: 109; left: 22px; position: absolute;
        top: 372px">WorkDraw Arch Fees (3A) %: </asp:Label>
    <asp:Label ID="Label17" runat="server" Style="z-index: 109; left: 18px; position: absolute;
        top: 401px">WorkDraw SA PC Fee (3C) %: </asp:Label>
    <asp:Label ID="Label24" runat="server" Style="z-index: 109; left: 16px; position: absolute;
        top: 428px">WorkDraw CC PC Fee (3D) %: </asp:Label>
    <asp:Label ID="Label18" runat="server" Style="z-index: 109; left: 62px; position: absolute;
        top: 456px">Contingency (5) %: </asp:Label>
    <asp:Label ID="Label19" runat="server" Style="z-index: 109; left: 45px; position: absolute;
        top: 485px">A & E Oversight (6) %: </asp:Label>
    <asp:Label ID="Label20" runat="server" Style="z-index: 109; left: 100px; position: absolute;
        top: 512px">Tests (7A) %: </asp:Label>
    <asp:Label ID="Label21" runat="server" Style="z-index: 109; left: 66px; position: absolute;
        top: 539px">Inspections (7B) %: </asp:Label>
    <asp:Label ID="Label22" runat="server" Style="z-index: 109; left: 26px; position: absolute;
        top: 566px">Construction Mgmt (8) %: </asp:Label>
    <asp:Label ID="Label23" runat="server" Style="z-index: 109; left: 64px; position: absolute;
        top: 596px">Other %: </asp:Label>
    <asp:Label ID="Label25" runat="server" Style="z-index: 109; left: 13px; position: absolute;
        top: 634px">Total Const/Reconstr (4 E/F) %: </asp:Label>
    <asp:Label ID="Label26" runat="server" Style="z-index: 109; left: 119px; position: absolute;
        top: 618px">-------------------</asp:Label>
    <asp:Label ID="lblMessage" Style="z-index: 127; left: 115px; position: absolute;
        top: 695px" runat="server" Width="472px" Font-Bold="True" ForeColor="Red" Height="32px">Message</asp:Label>
    <asp:Button ID="butReset" Style="z-index: 103; left: 135px; position: absolute; top: 277px"
        TabIndex="8" runat="server" Text="Reset Defaults" OnClick="butReset_Click"></asp:Button>
    <asp:Button ID="butClear" Style="z-index: 103; left: 291px; position: absolute; top: 277px"
        TabIndex="8" runat="server" Text="Clear" Width="76px" OnClick="butClear_Click">
    </asp:Button>
    <telerik:RadNumericTextBox ID="totproject" Style="z-index: 101; left: 141px; position: absolute;
        top: 138px" runat="server"  SelectionOnFocus="SelectAll"
        MinValue="0" NumberFormat-DecimalDigits="2">
        <NumberFormat AllowRounding="False" DecimalDigits="4"></NumberFormat>
    </telerik:RadNumericTextBox>
    <asp:Label ID="Label5" Style="z-index: 108; left: 8px; position: absolute; top: 200px"
        runat="server" Font-Underline="True" Font-Bold="True">Funding Sources:</asp:Label>
    <asp:Label ID="Label7" runat="server" Font-Bold="True" Font-Underline="True" Style="z-index: 108;
        left: 9px; position: absolute; top: 284px">Calc Percentages:</asp:Label>
    <asp:RadioButton ID="ReConst" Style="z-index: 107; left: 150px; position: absolute;
        top: 167px" TabIndex="2" runat="server" GroupName="NewConst" Text="Re-Construction">
    </asp:RadioButton>
    <asp:Label ID="Label4" Style="z-index: 106; left: 13px; position: absolute; top: 139px"
        runat="server">Total Project Budget:</asp:Label>
    <asp:Label ID="Label3" Style="z-index: 105; left: 8px; position: absolute; top: 92px"
        runat="server" Font-Bold="True" ForeColor="Red"> WARNING: This program will OVERWRITE all exisitng budget numbers for this project. The process cannot be undone! </asp:Label>
    <asp:Label ID="Label2" Style="z-index: 104; left: 8px; position: absolute; top: 56px"
        runat="server">This screen generates standard allocations to budget fields based on the percentage amounts entered in the fields below.</asp:Label>
    <asp:Button ID="butGenerate" Style="z-index: 103; left: 19px; position: absolute;
        top: 693px" TabIndex="8" runat="server" Text="Generate"></asp:Button>
    <asp:RadioButton ID="NewConst" Style="z-index: 102; left: 8px; position: absolute;
        top: 167px" TabIndex="1" runat="server" GroupName="NewConst" Text="New Construction"
        Checked="True"></asp:RadioButton>
    <telerik:RadAjaxManager Style="z-index: 102; left: 20px; position: absolute; top: 754px"
        ID="RadAjaxManager1" runat="server">
        <AjaxSettings>
            <telerik:AjaxSetting AjaxControlID="txtN2a">
                <UpdatedControls>
                    <telerik:AjaxUpdatedControl ControlID="txtTotalConstrReconstr" />
                    <telerik:AjaxUpdatedControl ControlID="txtTotalPercentage" />
                    <telerik:AjaxUpdatedControl ControlID="lblMessage" />
                </UpdatedControls>
            </telerik:AjaxSetting>
            <telerik:AjaxSetting AjaxControlID="txtN2b">
                <UpdatedControls>
                    <telerik:AjaxUpdatedControl ControlID="txtTotalConstrReconstr" />
                    <telerik:AjaxUpdatedControl ControlID="txtTotalPercentage" />
                    <telerik:AjaxUpdatedControl ControlID="lblMessage" />
                </UpdatedControls>
            </telerik:AjaxSetting>
            <telerik:AjaxSetting AjaxControlID="txtN3a">
                <UpdatedControls>
                    <telerik:AjaxUpdatedControl ControlID="txtTotalConstrReconstr" />
                    <telerik:AjaxUpdatedControl ControlID="txtTotalPercentage" />
                    <telerik:AjaxUpdatedControl ControlID="lblMessage" />
                </UpdatedControls>
            </telerik:AjaxSetting>
            <telerik:AjaxSetting AjaxControlID="txtN3c">
                <UpdatedControls>
                    <telerik:AjaxUpdatedControl ControlID="txtTotalConstrReconstr" />
                    <telerik:AjaxUpdatedControl ControlID="txtTotalPercentage" />
                    <telerik:AjaxUpdatedControl ControlID="lblMessage" />
                </UpdatedControls>
            </telerik:AjaxSetting>
            <telerik:AjaxSetting AjaxControlID="txtN3d">
                <UpdatedControls>
                    <telerik:AjaxUpdatedControl ControlID="txtTotalConstrReconstr" />
                    <telerik:AjaxUpdatedControl ControlID="txtTotalPercentage" />
                    <telerik:AjaxUpdatedControl ControlID="lblMessage" />
                </UpdatedControls>
            </telerik:AjaxSetting>
            <telerik:AjaxSetting AjaxControlID="txtN5">
                <UpdatedControls>
                    <telerik:AjaxUpdatedControl ControlID="txtTotalConstrReconstr" />
                    <telerik:AjaxUpdatedControl ControlID="txtTotalPercentage" />
                    <telerik:AjaxUpdatedControl ControlID="lblMessage" />
                </UpdatedControls>
            </telerik:AjaxSetting>
            <telerik:AjaxSetting AjaxControlID="txtN6">
                <UpdatedControls>
                    <telerik:AjaxUpdatedControl ControlID="txtTotalConstrReconstr" />
                    <telerik:AjaxUpdatedControl ControlID="txtTotalPercentage" />
                    <telerik:AjaxUpdatedControl ControlID="lblMessage" />
                </UpdatedControls>
            </telerik:AjaxSetting>
            <telerik:AjaxSetting AjaxControlID="txtN7a">
                <UpdatedControls>
                    <telerik:AjaxUpdatedControl ControlID="txtTotalConstrReconstr" />
                    <telerik:AjaxUpdatedControl ControlID="txtTotalPercentage" />
                    <telerik:AjaxUpdatedControl ControlID="lblMessage" />
                </UpdatedControls>
            </telerik:AjaxSetting>
            <telerik:AjaxSetting AjaxControlID="txtN7b">
                <UpdatedControls>
                    <telerik:AjaxUpdatedControl ControlID="txtTotalConstrReconstr" />
                    <telerik:AjaxUpdatedControl ControlID="txtTotalPercentage" />
                    <telerik:AjaxUpdatedControl ControlID="lblMessage" />
                </UpdatedControls>
            </telerik:AjaxSetting>
            <telerik:AjaxSetting AjaxControlID="txtN8">
                <UpdatedControls>
                    <telerik:AjaxUpdatedControl ControlID="txtTotalConstrReconstr" />
                    <telerik:AjaxUpdatedControl ControlID="txtTotalPercentage" />
                    <telerik:AjaxUpdatedControl ControlID="lblMessage" />
                </UpdatedControls>
            </telerik:AjaxSetting>
            <telerik:AjaxSetting AjaxControlID="txtN9">
                <UpdatedControls>
                    <telerik:AjaxUpdatedControl ControlID="txtTotalConstrReconstr" />
                    <telerik:AjaxUpdatedControl ControlID="txtTotalPercentage" />
                    <telerik:AjaxUpdatedControl ControlID="lblMessage" />
                </UpdatedControls>
            </telerik:AjaxSetting>
            <telerik:AjaxSetting AjaxControlID="butReset">
                <UpdatedControls>
                    <telerik:AjaxUpdatedControl ControlID="txtN2a" />
                    <telerik:AjaxUpdatedControl ControlID="txtN2b" />
                    <telerik:AjaxUpdatedControl ControlID="txtN3a" />
                    <telerik:AjaxUpdatedControl ControlID="txtN3c" />
                    <telerik:AjaxUpdatedControl ControlID="txtN3d" />
                    <telerik:AjaxUpdatedControl ControlID="txtN5" />
                    <telerik:AjaxUpdatedControl ControlID="txtN6" />
                    <telerik:AjaxUpdatedControl ControlID="txtN7a" />
                    <telerik:AjaxUpdatedControl ControlID="txtN7b" />
                    <telerik:AjaxUpdatedControl ControlID="txtN8" />
                    <telerik:AjaxUpdatedControl ControlID="txtN9" />
                    <telerik:AjaxUpdatedControl ControlID="txtTotalConstrReconstr" />
                    <telerik:AjaxUpdatedControl ControlID="txtTotalPercentage" />
                    <telerik:AjaxUpdatedControl ControlID="lblMessage" />
                </UpdatedControls>
            </telerik:AjaxSetting>
            <telerik:AjaxSetting AjaxControlID="butClear">
                <UpdatedControls>
                    <telerik:AjaxUpdatedControl ControlID="txtN2a" />
                    <telerik:AjaxUpdatedControl ControlID="txtN2b" />
                    <telerik:AjaxUpdatedControl ControlID="txtN3a" />
                    <telerik:AjaxUpdatedControl ControlID="txtN3c" />
                    <telerik:AjaxUpdatedControl ControlID="txtN3d" />
                    <telerik:AjaxUpdatedControl ControlID="txtN5" />
                    <telerik:AjaxUpdatedControl ControlID="txtN6" />
                    <telerik:AjaxUpdatedControl ControlID="txtN7a" />
                    <telerik:AjaxUpdatedControl ControlID="txtN7b" />
                    <telerik:AjaxUpdatedControl ControlID="txtN8" />
                    <telerik:AjaxUpdatedControl ControlID="txtN9" />
                    <telerik:AjaxUpdatedControl ControlID="txtTotalConstrReconstr" />
                    <telerik:AjaxUpdatedControl ControlID="txtTotalPercentage" />
                    <telerik:AjaxUpdatedControl ControlID="lblMessage" />
                </UpdatedControls>
            </telerik:AjaxSetting>
        </AjaxSettings>
    </telerik:RadAjaxManager>
    </form>
</body>
</html>
