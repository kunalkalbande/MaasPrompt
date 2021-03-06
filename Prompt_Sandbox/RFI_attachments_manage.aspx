<%@ Page Language="vb" %>
<%@ Register Assembly="Telerik.Web.UI" Namespace="Telerik.Web.UI" TagPrefix="telerik" %>
<%@ Import Namespace="Prompt" %>
<%@ Import Namespace="System.IO" %>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">

<script runat="server">

    Private ParentRecordType As String = ""
    Private sPhysicalPath As String = ""
    Private sRelativePath As String = ""
    Private ParentRecID As Integer = 0
    Private nProjectID As Integer = 0
    Private nContactID As Integer = 0   'for insurance
    Private bEnableDelete As Boolean = False
    Private Rev As Integer = 0
    Private isUpload As Boolean
    Private AttachDir As Integer

    Private Sub Page_Load(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MyBase.Load

        
        If ProcLib.CheckExpiredSessionForPopup(Page) Then    'session died so close the page - this is to prevent orphaned popups
            ProcLib.CloseAndRefresh(Page)
        End If
        If Session("RtnFromEdit") = True Then
             'ProcLib.CloseAndRefresh(Page)
        End If
        ProcLib.LoadPopupJscript(Page)
        Session("PageID") = "AttachmentsManage"

        ParentRecordType = Request.QueryString("ParentType")
        ParentRecID = Request.QueryString("ParentID")
        Try
            nProjectID = Request.QueryString("ProjectID")
        Catch ex As Exception
        End Try
        nContactID = Request.QueryString("ContactID")
        Rev = Request.QueryString("Revision")
        Try
            isUpload = Request.QueryString("Upload")
        Catch ex As Exception
        End Try
        
        Try
            AttachDir = Request.QueryString("AttachDir")
        Catch ex As Exception
        End Try
                   
        'If ParentRecordType = "Insurance" Then
        'nProjectID = -99
        'End If
        
        BuildMenu()
        
        Dim sUser As String
        Select Case Session("ContactType")
            Case "Construction Manager"
                sUser = "CM"
                sUser = Request.QueryString("User")
            Case "ProjectManager"
                sUser = "PM"
            Case "Design Professional"
                sUser = "DP"
            Case "General Contractor"
                sUser = "GC"
            Case Else
                sUser = "NA"
        End Select
        
         sUser = Request.QueryString("User")
        
        sPhysicalPath = ProcLib.GetCurrentAttachmentPath() & "DistrictID_" & HttpContext.Current.Session("DistrictID") & "/_apprisedocs/"
        sRelativePath = ProcLib.GetCurrentRelativeAttachmentPath() & "DistrictID_" & HttpContext.Current.Session("DistrictID") & "/_apprisedocs/"
        
        Select Case Trim(ParentRecordType)
            Case "RFIQuestion"
                sPhysicalPath &= "_RFIs/RFIID_" & ParentRecID & "/Rev_" & Request.QueryString("Revision") & "/"
                sRelativePath &= "_RFIs/RFIID_" & ParentRecID & "/Rev_" & Request.QueryString("Revision") & "/"

            Case "RFIAnswer"
                sPhysicalPath &= "_RFIs/RFIID_" & ParentRecID & "/Rev_" & Request.QueryString("Revision") & "_Response_" & Request.QueryString("Seq") & "/"
                sRelativePath &= "_RFIs/RFIID_" & ParentRecID & "/Rev_" & Request.QueryString("Revision") & "_Response_" & Request.QueryString("Seq") & "/"
            
            Case "SubmittalRemark"
                sPhysicalPath &= "_Submittals/SubmittalID_" & ParentRecID & "/Rev_" & Request.QueryString("Revision") & "_Remark_" & Request.QueryString("Seq") & "/"
                sRelativePath &= "_Submittals/SubmittalID_" & ParentRecID & "/Rev_" & Request.QueryString("Revision") & "_Remark_" & Request.QueryString("Seq") & "/"
                If Request.QueryString("Seq") = 2 Or Request.QueryString("Seq") = 4 Then
                    sPhysicalPath &= AttachDir & "/"
                    sRelativePath &= AttachDir & "/"
                End If
                
            Case "SubmittalRequest"
                sPhysicalPath &= "_Submittals/SubmittalID_" & ParentRecID & "/Rev_" & Request.QueryString("Revision") & "/"
                sRelativePath &= "_Submittals/SubmittalID_" & ParentRecID & "/Rev_" & Request.QueryString("Revision") & "/"
                
            Case "SubmittalRespond"
                sPhysicalPath &= "_Submittals/SubmittalID_" & ParentRecID & "/Rev_" & Request.QueryString("Revision") & "_Response_" & Request.QueryString("Seq") & "/"
                sRelativePath &= "_Submittals/SubmittalID_" & ParentRecID & "/Rev_" & Request.QueryString("Revision") & "_Response_" & Request.QueryString("Seq") & "/"
                
            Case "CoReference"
                sPhysicalPath &= "_ChangeOrders/COID_" & ParentRecID & "/Rev_" & Request.QueryString("Revision") & "_Reference/"
                sRelativePath &= "_ChangeOrders/COID_" & ParentRecID & "/Rev_" & Request.QueryString("Revision") & "_Reference/"
            Case "CoCost"
                sPhysicalPath &= "_ChangeOrders/COID_" & ParentRecID & "/Rev_" & Request.QueryString("Revision") & "_CostBreakdown/"
                sRelativePath &= "_ChangeOrders/COID_" & ParentRecID & "/Rev_" & Request.QueryString("Revision") & "_CostBreakdown/"
            Case "CoRequest"
                sPhysicalPath &= "_ChangeOrders/COID_" & ParentRecID & "/Rev_" & Request.QueryString("Revision") & "_Request/"
                sRelativePath &= "_ChangeOrders/COID_" & ParentRecID & "/Rev_" & Request.QueryString("Revision") & "_Request/"
            Case "CoResponse"
                sPhysicalPath &= "_ChangeOrders/COID_" & ParentRecID & "/Rev_" & Request.QueryString("Revision") & "_Response_" & Request.QueryString("Seq") & "/"
                sRelativePath &= "_ChangeOrders/COID_" & ParentRecID & "/Rev_" & Request.QueryString("Revision") & "_Response_" & Request.QueryString("Seq") & "/"              
            Case "CoIssue"
                sPhysicalPath &= "_ChangeOrders/COID_" & ParentRecID & "/Rev_" & Request.QueryString("Revision") & "_Issue/"
                sRelativePath &= "_ChangeOrders/COID_" & ParentRecID & "/Rev_" & Request.QueryString("Revision") & "_Issue/"
        End Select
                
        Dim ww As RadWindow = New RadWindow
        With ww
            .ID = "ShowDialogPopup"
            .NavigateUrl = ""
            .Title = ""
            .Width = 350
            .Height = 150
            .Modal = True
            .VisibleStatusbar = True
            .ReloadOnShow = True
        End With
        RadWin1.Windows.Add(ww)
        
        Using db As New EISSecurity
            db.ProjectID = nProjectID
            bEnableDelete = True
            Select Case ParentRecordType
                Case "RFIQuestion", "RFIAnswer", "CoReference", "CoCost", "CoRequest", "CoResponse", "CoIssue", "SubmittalRemark"
                    If isUpload = True Then
                        bEnableDelete = True
                    Else
                        bEnableDelete = False
                    End If
                    If Not db.FindUserPermission("RFILog", "Write") Then
                        'RadMenu1.FindItemByValue("Upload").Visible = False   
                    End If
                    'Case "SubmittalRequest"
                    'If Not db.FindUserPermission("SubmittalLog", "Write") Then
                    'RadMenu1.FindItemByValue("Upload").Visible = False
                    'bEnableDelete = False
                    'End If
                Case Else
                    
            End Select
        End Using
    
        'If ProjectID=0 then read only
        If nProjectID = 0 Then
            'RadMenu1.FindItemByValue("Upload").Visible = False
            'bEnableDelete = False
        End If
  
    End Sub
    
  
    Public Sub BuildMenu()
        RadMenu1.Width = Unit.Percentage(100)

        Dim nTopMenuItemWidths As Unit = Unit.Pixel(100)

        With RadMenu1
            .Items.Clear()
            .Skin = "Vista"
        End With
        Dim mm As RadMenuItem

        '**********************************************
        mm = New RadMenuItem
        With mm
            .Text = "Upload"
            .Value = "Upload"
            .NavigateUrl = "RFI_attachment_upload.aspx?ParentID=" & ParentRecID & "&ParentType=" & Trim(ParentRecordType) & "&ContactID=" & nContactID & "&Revision=" & Request.QueryString("Revision") & "&Seq=" & Request.QueryString("Seq") _
                                                                  & "&UserType=" & Session("ContactType") & "&Type=" & Request.QueryString("Type") & "&Closed=" & Request.QueryString("Closed") & "&Upload=" & Request.QueryString("Upload") _
                                                                  & "&ProjectID=" & Request.QueryString("ProjectID") & "&User=" & Request.QueryString("User") & "&AttachDir=" & AttachDir
            .ImageUrl = "images/arrow_up_green.png"
            .Width = nTopMenuItemWidths
        End With
        
        If isUpload = True Then
            RadMenu1.Items.Add(mm)
        End If
        
        If ParentRecordType = "RFIQuestion" Or ParentRecordType = "SubmittalRequest" Then
            If Session("UserType") = "Origin" Or Session("ContactType") = "Construction Manager" Then
                If Request.QueryString("Closed") <> "True" Then
                    'RadMenu1.Items.Add(mm)
                End If
            End If
        ElseIf ParentRecordType = "RFIAnswer" Or ParentRecordType = "SubmittalResponse" Then
            If Session("UserType") = "Responder" Or Session("ContactType") = "Construction Manager" Then
                If Request.QueryString("Closed") <> "True" Then
                    ' RadMenu1.Items.Add(mm)
                End If
            End If
        End If
        
        If ParentRecordType = "SubmittalRequest" Then
            If Session("SubRequestUpload") = True Then
                'RadMenu1.Items.Add(mm)
            End If
        End If
        If ParentRecordType = "SubmittalResponse" Then
            If Session("SubResponseUpload") = True Then
                ' RadMenu1.Items.Add(mm)
            End If
        End If
        
        mm = New RadMenuItem
        With mm
            .Text = "Exit"
            .ImageUrl = "images/exit.png"
            .Width = nTopMenuItemWidths
        End With
        'RadMenu1.Items.Add(mm)

        mm = New RadMenuItem
        With mm
            .Text = "Help"
            .ImageUrl = "images/help.png"
            .Attributes("onclick") = "openPopup('help_view.aspx','pophelp',550,450,'yes');"
            .PostBack = False
            .Width = nTopMenuItemWidths
        End With
        RadMenu1.Items.Add(mm)


    End Sub

    Protected Sub RadMenu1_ItemClick(ByVal sender As Object, ByVal e As Telerik.Web.UI.RadMenuEventArgs) Handles RadMenu1.ItemClick
        Dim Item As Telerik.Web.UI.RadMenuItem = e.Item
        If Item.Text = "Exit" Then
            'ProcLib.CloseAndRefreshRADNoPrompt(Page)
            'ProcLib.Closeonly(Page)
            
            Session("RtnFromEdit") = True
            
        End If

    End Sub

 
    Protected Sub RadGrid1_NeedDataSource(ByVal source As Object, ByVal e As Telerik.Web.UI.GridNeedDataSourceEventArgs) Handles RadGrid1.NeedDataSource

            Dim tbl As New datatable

            Dim col As New DataColumn
            col.DataType = Type.GetType("System.String")
            col.ColumnName = "FileName"
            tbl.Columns.Add(col)

            col = New DataColumn
            col.DataType = Type.GetType("System.String")
            col.ColumnName = "FileSize"
            tbl.Columns.Add(col)

            col = New DataColumn
            col.DataType = Type.GetType("System.String")
            col.ColumnName = "FileIcon"
            tbl.Columns.Add(col)

            col = New DataColumn
            col.DataType = Type.GetType("System.String")
            col.ColumnName = "LinkURL"
            tbl.Columns.Add(col)

            Dim folder As New DirectoryInfo(sPhysicalPath)
            If folder.Exists Then  'Look for files

                For Each fi As FileInfo In folder.GetFiles()
                    Dim newrow As datarow = tbl.newrow
                    newrow("FileName") = fi.name

                    Dim FileSize As String = FormatNumber(fi.Length, 0, ) & " bytes"
                    If fi.Length > 1000 Then
                        FileSize = FormatNumber(fi.Length / 1000, 1) & "Kb"
                    End If
                    If fi.Length > 1000000 Then
                        FileSize = FormatNumber(fi.Length / 1000000, 1) & "Mb"
                    End If

                    newrow("FileSize") = FileSize

                    'Select image depending on file type
                    If InStr(fi.name, ".xls") > 0 Then
                        newrow("FileIcon") = "images/prompt_xls.gif"
                    ElseIf InStr(fi.name, ".pdf") > 0 Then
                        newrow("FileIcon") = "images/prompt_pdf.gif"
                    ElseIf InStr(fi.name, ".doc") > 0 Then
                        newrow("FileIcon") = "images/prompt_doc.gif"
                    ElseIf InStr(fi.name, ".docx") > 0 Then
                        newrow("FileIcon") = "images/prompt_doc.gif"
                    ElseIf InStr(fi.name, ".zip") > 0 Then
                        newrow("FileIcon") = "images/prompt_zip.gif"
                    Else
                        newrow("FileIcon") = "prompt_page.gif"
                    End If

                    newrow("LinkURL") = sRelativePath & fi.name

                    tbl.rows.add(newrow)
                Next

            End If


            RadGrid1.DataSource = tbl
  
    End Sub
  
    Protected Sub RadGrid1_ItemCommand(ByVal source As Object, ByVal e As Telerik.Web.UI.GridCommandEventArgs) Handles RadGrid1.ItemCommand
        ' If multiple buttons are used in a Telerik RadGrid control, use the
        ' CommandName property to determine which button was clicked.
          
        If e.CommandName = "DeleteFile" Then       'reRoute this transaction to current user
            Dim sFileName As String = e.CommandArgument
             
            'Remove file
            Dim objFileInfo As FileInfo
            objFileInfo = New FileInfo(sPhysicalPath & sFileName)
            objFileInfo.Delete()

            RadGrid1.Rebind()
            
 
        End If
        
 
    End Sub
    'Private Sub RadGrid1_ItemDataBound(ByVal sender As Object, ByVal e As Telerik.Web.UI.GridItemEventArgs) Handles RadGrid1.ItemDataBound
    
    'End Sub
    
    Protected Sub RadGrid1_ItemCreated(ByVal sender As Object, ByVal e As Telerik.Web.UI.GridItemEventArgs) Handles RadGrid1.ItemCreated
        'This event allows us to customize the cell contents - fired before databound
          
        If (TypeOf e.Item Is GridDataItem) Then

            'This looks at the row as it is created and finds the hyperlink 
            'and wiresd it to a Java Script function that calls a RAD window.
                               
            Dim item As GridDataItem = CType(e.Item, GridDataItem)
            Dim sFileName As String = item.OwnerTableView.DataKeyValues(item.ItemIndex)("FileName")
              
            'update the link button to delete file
            Dim linkButton As ImageButton = CType(item("DeleteFile").Controls(0), ImageButton)
            linkButton.ToolTip = "Delete this File."
            linkButton.ImageUrl = "images/trash.gif"
            linkButton.CommandArgument = sFileName
            linkButton.Visible = bEnableDelete
          
        End If
    End Sub        
</script>

<html>
<head runat="server">
    <title >Manage Attachments</title>
    <link rel="stylesheet" type="text/css" href="Styles.css" />

    <script type="text/javascript" language="javascript">


        function GetRadWindow() {
            var oWindow = null;
            if (window.radWindow) oWindow = window.radWindow; //Will work in Moz in all cases, including clasic dialog
            //else if (window.frameElement.radWindow) oWindow = window.frameElement.radWindow; //IE (and Moz az well)

            return oWindow;
        }

        function ConfirmDelete(oButton, id, rectype)   //for dialog window display - pass the record id and the record type
        {

            var oWnd = window.radopen("attachment_dialog_confirm_delete.aspx?recid=" + id + "&ParentType=" + rectype, "ShowDialogPopup");
            oWnd.MoveTo(50, 30);
            return false;
        }  	   
    </script>

</head>
<body>
    <form id="Form1" method="post" runat="server">
    <telerik:RadScriptManager ID="RadScriptManager1" runat="server" />
    <telerik:RadMenu ID="RadMenu1" runat="server" DefaultGroupSettings-Flow="Horizontal">
    </telerik:RadMenu>
    <br />
    <br />
    <telerik:RadGrid Style="z-index: 100; left: 9px; position: absolute; top: 42px" ID="RadGrid1"
        runat="server" AllowMultiRowSelection="False" AllowSorting="True" AutoGenerateColumns="False"
        GridLines="None" Width="95%" EnableAJAX="True" Skin="Office2007" Height="85%">
        <ClientSettings>
            <Scrolling AllowScroll="True" UseStaticHeaders="True" ScrollHeight="80%" />
        </ClientSettings>
        <MasterTableView Width="98%" GridLines="None" DataKeyNames="FileName" NoMasterRecordsText="No Attachments were found.">
            <Columns>

                <telerik:GridHyperLinkColumn DataTextField="FileName" DataNavigateUrlFields="LinkURL"
                    Target="_new" HeaderText="File" UniqueName="FileName">
                    <ItemStyle HorizontalAlign="Left" />
                    <HeaderStyle HorizontalAlign="Left" Width="75%" Height="15px" />
                </telerik:GridHyperLinkColumn>

                <telerik:GridBoundColumn DataField="FileSize" UniqueName="FileSize" HeaderText="Size">
                    <ItemStyle HorizontalAlign="Left" />
                    <HeaderStyle HorizontalAlign="Left" Wrap="False" />
                </telerik:GridBoundColumn>
  
                <telerik:GridButtonColumn ButtonType="ImageButton" Visible="True" CommandName="DeleteFile"
                    HeaderText="" UniqueName="DeleteFile" Reorderable="False" ShowSortIcon="False">
                    <ItemStyle Width="35px" HorizontalAlign="Right" VerticalAlign="Top" />
                    <HeaderStyle Width="35px" HorizontalAlign="Right" />
                </telerik:GridButtonColumn>

            </Columns>
            <ExpandCollapseColumn Resizable="False" Visible="False">
                <HeaderStyle Width="20px" />
            </ExpandCollapseColumn>
            <RowIndicatorColumn Visible="False">
                <HeaderStyle Width="20px" />
            </RowIndicatorColumn>
        </MasterTableView>
    </telerik:RadGrid>





    <telerik:RadWindowManager ID="RadWin1" runat="server">
    </telerik:RadWindowManager>
    <%--Hidden lable to handle jscript code--%>
    <asp:Label ID="lblAlert" runat="server" Height="24px" Style="z-index: 111; left: 370px;
        position: absolute; top: 83px"></asp:Label>
    </form>
</body>
</html>
