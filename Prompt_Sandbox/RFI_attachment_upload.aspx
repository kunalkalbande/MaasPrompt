<%@ Page Language="vb" %>

<%@ Register Assembly="Telerik.Web.UI" Namespace="Telerik.Web.UI" TagPrefix="telerik" %>
<%@ Import Namespace="System.IO" %>
<%@ Import Namespace="System.IO.FileSystemInfo" %>
<%@ Import Namespace="Prompt" %>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">

<script runat="server">

      
    Private nParentID As Integer = 0
    Private sParentType As String = ""
    Private sPhysicalPath As String = ""
    Private nContactID As Integer = 0   'for insurance
    Private sUser As String = ""
    Private AttachDir As Integer
    
    Private Sub Page_Load(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MyBase.Load

        ProcLib.LoadPopupJscript(Page)
        
        If ProcLib.CheckExpiredSessionForPopup(Page) Then    'session died so close the page - this is to prevent orphaned popups
            ProcLib.CloseAndRefresh(Page)
        End If

        Session("PageID") = "UploadAppriseAttachment"
        nParentID = Request.QueryString("ParentID")
        sParentType = Request.QueryString("ParentType")
        nContactID = Request.QueryString("ContactID")
        AttachDir = Request.QueryString("AttachDir")
        'Dim sUser As String = Request.QueryString("User")
        
        lblMessage.Text = ""
        
        BuildMenu()
        
        Dim sUser As String
        Select Case Session("ContactType")
            Case "Construction Manager"
                sUser = "CM"
            Case "ProjectManager"
                sUser = "PM"
            Case "Design Professional"
                sUser = "DP"
            Case "General Contractor"
                sUser = "GC"
            Case Else
                sUser = "NA"
        End Select
        
        Select Case sParentType
            Case "RFIQuestion"
                sPhysicalPath = ProcLib.GetCurrentAttachmentPath() & "DistrictID_" & Session("DistrictID") & "/_apprisedocs/_RFIs/RFIID_" & nParentID & "/" & "Rev_" & Request.QueryString("Revision")

            Case "RFIAnswer"
                sPhysicalPath = ProcLib.GetCurrentAttachmentPath() & "DistrictID_" & Session("DistrictID") & "/_apprisedocs/_RFIs/RFIID_" & nParentID & "/" & "Rev_" & Request.QueryString("Revision") & "_Response_" & Request.QueryString("Seq")

            Case "SubmittalRemark"
                'sPhysicalPath &= "_Submittals/SubmittalID_" & ParentRecID & "/Rev_" & Request.QueryString("Revision") & "_Remark_" & Request.QueryString("Seq") & "/"
                sPhysicalPath = ProcLib.GetCurrentAttachmentPath() & "DistrictID_" & Session("DistrictID") & "/_apprisedocs/_Submittals/SubmittalID_" & nParentID & "/" & "Rev_" & Request.QueryString("Revision") & "_Remark_" & Request.QueryString("Seq") & "/"
                If Request.QueryString("Seq") = 2 Or Request.QueryString("Seq") = 4 Then
                    sPhysicalPath &= AttachDir & "/"
                End If
                
            Case "SubmittalRequest"
                sPhysicalPath = ProcLib.GetCurrentAttachmentPath() & "DistrictID_" & Session("DistrictID") & "/_apprisedocs/_Submittals/SubmittalID_" & nParentID & "/" & "Rev_" & Request.QueryString("Revision")

            Case "SubmittalResponse"
                sPhysicalPath = ProcLib.GetCurrentAttachmentPath() & "DistrictID_" & Session("DistrictID") & "/_apprisedocs/_Submittals/SubmittalID_" & nParentID & "/" & "Rev_" & Request.QueryString("Revision") & "_Response_" & Request.QueryString("Seq")           
            
            Case "CoReference"
                sPhysicalPath &= ProcLib.GetCurrentAttachmentPath() & "DistrictID_" & Session("DistrictID") & "/_apprisedocs/_ChangeOrders/COID_" & nParentID & "/Rev_" & Request.QueryString("Revision") & "/_Reference/"
            Case "CoCost"
                sPhysicalPath &= ProcLib.GetCurrentAttachmentPath() & "DistrictID_" & Session("DistrictID") & "/_apprisedocs/_ChangeOrders/COID_" & nParentID & "/Rev_" & Request.QueryString("Revision") & "/_CostBreakdown/"
            Case "CoRequest"
                sPhysicalPath &= ProcLib.GetCurrentAttachmentPath() & "DistrictID_" & Session("DistrictID") & "/_apprisedocs/_ChangeOrders/COID_" & nParentID & "/Rev_" & Request.QueryString("Revision") & "/_Request/"
            Case "CoResponse"
                sPhysicalPath &= ProcLib.GetCurrentAttachmentPath() & "DistrictID_" & Session("DistrictID") & "/_apprisedocs/_ChangeOrders/COID_" & nParentID & "/" & "/Rev_" & Request.QueryString("Revision") & "_Response_" & Request.QueryString("Seq")
 
            Case "CoIssue"
                sPhysicalPath &= ProcLib.GetCurrentAttachmentPath() & "DistrictID_" & Session("DistrictID") & "/_apprisedocs/_ChangeOrders/COID_" & nParentID & "/Rev_" & Request.QueryString("Revision") & "_Issue"
                
            Case "PAD"
                sPhysicalPath = ProcLib.GetCurrentAttachmentPath() & "DistrictID_" & Session("DistrictID") & "/_apprisedocs/_PADS/PADID_" & nParentID & "/"

            Case "InfoBulletin"
                sPhysicalPath = ProcLib.GetCurrentAttachmentPath() & "DistrictID_" & Session("DistrictID") & "/_apprisedocs/_InfoBulletins/InfoBulletinID_" & nParentID & "/"

            Case "Procurement"
                sPhysicalPath = ProcLib.GetCurrentAttachmentPath() & "DistrictID_" & Session("DistrictID") & "/_apprisedocs/_ProcurementLogs/ProcurementID_" & nParentID & "/"
 
            Case "Transmittal"
                sPhysicalPath = ProcLib.GetCurrentAttachmentPath() & "DistrictID_" & Session("DistrictID") & "/_apprisedocs/_Transmittals/TransmittalID_" & nParentID & "/"

            Case "Insurance"
                sPhysicalPath = ProcLib.GetCurrentAttachmentPath() & "DistrictID_" & Session("DistrictID") & "/CompanyInsurancePolicies/ContactID_" & nContactID & "/InsuranceID_" & nParentID & "/"

                
 
            Case "ProgressReport"
                sPhysicalPath = ProcLib.GetCurrentAttachmentPath() & "DistrictID_" & Session("DistrictID") & "/_apprisedocs/_ProgressReports/ProgressReportID_" & nParentID & "/"

            Case "NewsRelease"
                sPhysicalPath = ProcLib.GetCurrentAttachmentPath() & "DistrictID_" & Session("DistrictID") & "/_apprisedocs/_NewsReleases/ProjectID_" & nParentID & "/"
                lblSelectFile.Text = lblSelectFile.Text & " (pdf only)"
                RadUpload1.AllowedFileExtensions = New String() {".pdf"}
                
                
        End Select

    End Sub
    
    Public Sub BuildMenu()
        RadMenu1.Width = Unit.Percentage(100)

        Dim nTopLineHeight As Unit = Unit.Pixel(27)
        Dim nTopMenuItemWidths As Unit = Unit.Pixel(75)

        With RadMenu1
            .Items.Clear()
        End With
        Dim mm As Telerik.Web.UI.RadMenuItem

        '**********************************************
        mm = New Telerik.Web.UI.RadMenuItem
        With mm
            .Height = nTopLineHeight
            .Text = "Back"
            '.NavigateUrl = "RFI_attachments_manage.aspx?ParentID=" & nParentID & "&ParentType=" & sParentType
            .NavigateUrl = "RFI_attachments_manage.aspx?ParentID=" & nParentID & "&ProjectID=" & Request.QueryString("ProjectID") & "&Revision=" & Request.QueryString("Revision") _
                                                                  & "&ParentType=" & sParentType & "&ContactID=" & nContactID & "&UserType=" & Session("UserType") & "&Type=" _
                                                                  & Request.QueryString("Type") & "&Closed=" & Request.QueryString("Closed") & "&Upload=" & Request.QueryString("Upload") _
                                                                  & "&Seq=" & Request.QueryString("Seq") & "&User=" & sUser & "&AttachDir=" & AttachDir
            .ImageUrl = "images/arrow_left_green.png"
            .Width = nTopMenuItemWidths
        End With
        RadMenu1.Items.Add(mm)
        

        mm = New Telerik.Web.UI.RadMenuItem
        With mm
            .Text = "Exit"
            .Height = nTopLineHeight
            .Width = nTopMenuItemWidths
            .ImageUrl = "images/exit.png"
        End With
        RadMenu1.Items.Add(mm)

        mm = New Telerik.Web.UI.RadMenuItem
        With mm
            .Text = "Help"
            .ImageUrl = "images/help.png"
            .Attributes("onclick") = "openPopup('help_view.aspx','pophelp',550,450,'yes');"
            .PostBack = False
            .Height = nTopLineHeight
            .Width = nTopMenuItemWidths
        End With
        RadMenu1.Items.Add(mm)


    End Sub

    Private Sub butUpload_Click(ByVal sender As System.Object, ByVal e As System.Web.UI.ImageClickEventArgs) Handles butUpload.Click

        If RadUpload1.UploadedFiles.Count = 0 Then
            lblMessage.Text = "Please Select a file to upload."
            
        End If
        
        Dim folder As New DirectoryInfo(sPhysicalPath)
        If Not folder.Exists Then  'create the folder
            folder.Create()
        End If
        'save the file - we are only allowing one file for this upload funtion
        For Each File As Telerik.Web.UI.UploadedFile In RadUpload1.UploadedFiles
            Dim sSaveFile As String = Path.Combine(sPhysicalPath, File.GetName)
            sSaveFile = sSaveFile.Replace("#", "")
            sSaveFile = sSaveFile.Replace(";", "")
            sSaveFile = sSaveFile.Replace(",", "")
            File.SaveAs(sSaveFile, True)    'overwrite if there
        Next

        'Response.Redirect("RFI_attachments_manage.aspx?ParentID=" & nParentID & "&ParentType=" & sParentType & "&ContactID=" & nContactID & "&Revision=" & Request.QueryString("Revision") & "&Seq=" & Request.QueryString("Seq"))
        Response.Redirect("RFI_attachments_manage.aspx?ParentID=" & nParentID & "&ProjectID=" & Request.QueryString("ProjectID") & "&Revision=" & Request.QueryString("Revision") _
                                                                  & "&ParentType=" & sParentType & "&User=" & Request.QueryString("User") & "&UserType=" & Session("UserType") & "&Type=" _
                                                                  & Request.QueryString("Type") & "&Closed=" & Request.QueryString("Closed") & "&Upload=" & Request.QueryString("Upload") _
                                                                  & "&Seq=" & Request.QueryString("Seq") & "&AttachDir=" & AttachDir)
        
        
    End Sub
    
    Protected Sub RadMenu1_ItemClick(ByVal sender As Object, ByVal e As Telerik.Web.UI.RadMenuEventArgs) Handles RadMenu1.ItemClick
        Dim Item As Telerik.Web.UI.RadMenuItem = e.Item
        If Item.Text = "Exit" Then
            'ProcLib.CloseOnlyRAD(Page)
            ProcLib.CloseOnly(Page)
        End If

    End Sub
    
  


</script>

<html>
<head>
    <title>Attachment Upload</title>
     <link href="Styles.css" type="text/css" rel="stylesheet" />
    <script type="text/javascript" language="javascript">

        function GetRadWindow() {
            var oWindow = null;
            if (window.radWindow) oWindow = window.radWindow; //Will work in Moz in all cases, including clasic dialog
            else if (window.frameElement.radWindow) oWindow = window.frameElement.radWindow; //IE (and Moz az well)

            return oWindow;
        }   
    </script>

</head>
<body>
   <form id="Form1" method="post" runat="server">
     <telerik:RadScriptManager ID="RadScriptManager1" runat="server" />
                  
    <telerik:RadMenu ID="RadMenu1" runat="server" DefaultGroupSettings-Flow="Horizontal" Skin="Vista">
        <DefaultGroupSettings Flow="Horizontal"></DefaultGroupSettings>
    </telerik:RadMenu>

        <br /><br />
    <table width="100%">
 
        <tr>
            <td colspan="2" style="height: 26px">
                <asp:Label ID="lblSelectFile" runat="server">Select File:</asp:Label>
            </td>
        </tr>
        <tr>
            <td colspan="2" style="height: 21px">
                <telerik:RadUpload ID="RadUpload1" runat="server" Style="z-index: 100; left: 8px; top: 54px"
                     ControlObjectsVisibility="None" />
            </td>
        </tr>
        <tr>
            <td colspan="2">
                <asp:ImageButton ID="butUpload" runat="server" ImageUrl="images/button_save.gif">
                </asp:ImageButton> &nbsp;&nbsp; <asp:Label ID="lblMessage" runat="server"></asp:Label>
            </td>
        </tr>
        <tr>
            <td colspan="2" align="left">
                <br />
                &nbsp;
            </td>
        </tr>
    </table>
    <telerik:RadProgressArea ID="RadProgressArea1" runat="server" Style="z-index: 100; left: 3px;
        position: absolute; top: 146px;" Left="3px" />
    <telerik:RadProgressManager ID="RadProgressManager1" runat="server" />
    </form>
</body>
</html>
