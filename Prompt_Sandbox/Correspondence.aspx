<%@ Page Language="VB" MasterPageFile="~/content.master" Title="" %>
<%@ Register Assembly="Telerik.Web.UI" Namespace="Telerik.Web.UI" TagPrefix="telerik" %>
<%@ Import Namespace="Prompt" %>

<script runat="server">
    
    Private bReadOnly As Boolean = True
    Private nProjectID As Integer = 0
    Private nContactID As Integer
    Private nProjID As Integer
    Private nContractID As Integer = 0
    
    Protected Sub Page_PreRender(ByVal sender As Object, ByVal e As System.EventArgs)
        Using db As New promptUserPrefs
            db.SaveGridSettings(RadGrid1, "ChangeOrdersGridSettings", "ProjectID", nProjectID)
        End Using
    End Sub
    
    Protected Sub Page_Init(ByVal sender As Object, ByVal e As System.EventArgs)
        nProjectID = Request.QueryString("ProjectID")          
        'set security
        Using dbsec As New EISSecurity
            'dbsec.ProjectID = nProjectID
            'If dbsec.FindUserPermission("MeetingMinutes", "write") Then
            'bReadOnly = False
            'Else
            'bReadOnly = True
            'End If
        End Using
        If Not IsPostBack Then
            Using db As New promptUserPrefs
                db.LoadGridSettings(RadGrid1, "CorrespondenceGridSettings", "ProjectID", nProjectID)
                db.LoadGridColumnVisibility(RadGrid1, "CorrespondencGridColumns", "ProjectID", nProjectID)
            End Using
        End If
    End Sub
    
    Private Sub Page_Load(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MyBase.Load

        ProcLib.CheckSession(Page)
        ProcLib.LoadPopupJscript(Page)
                     
        'set up help button
        Session("PageID") = "ProjectChangeOrders"
        
        If Not IsPostBack Then
            If Session("COType") = "" Then
                Session("COType") = "PCO"
            End If            
        End If
           
        Dim masterTabs As RadTabStrip = Master.FindControl("tabMain")
        Dim masterViewTitle As Label = Master.FindControl("lblViewTitle")
        
        Session("CurrentTab") = "Correspondence"
        For Each radTab In masterTabs.GetAllTabs
            If radTab.Value = "Correspondence" Then
                radTab.Selected = True
                radTab.SelectParents()
                Exit For
            End If
        Next
        
        If Session("RtnFromEdit") <> True Then
            Session("ContractID") = Nothing
        Else
            'cboTypeSelect.SelectedValue = Session("COType") & "s"
            Session("RtnFromEdit") = Nothing
            nContractID = Session("ContractID")            
        End If
        
        Using db As New RFI
            nContactID = db.getContactID(Session("UserID"), Session("DistrictID"))
        End Using
        
        Try
            Using db As New RFI
                Dim contactData As Object = db.getContactData(nContactID, Session("DistrictID"))
                Session("ContactType") = contactData(1)
            End Using
        Catch ex As Exception
        End Try

        'Set Grid Properties
        With RadGrid1
            .EnableEmbeddedSkins = False
            .Skin = "Prompt"
            .GroupingEnabled = False
            .AllowSorting = True
                        
            .ClientSettings.AllowColumnsReorder = True
            .ClientSettings.ColumnsReorderMethod = GridClientSettings.GridColumnsReorderMethod.Reorder
            .ClientSettings.Scrolling.AllowScroll = True
            .ClientSettings.Scrolling.ScrollHeight = Unit.Percentage(50)
            .ClientSettings.Scrolling.UseStaticHeaders = True
            .ClientSettings.Resizing.AllowColumnResize = True

            .MasterTableView.EnableHeaderContextMenu = False
            .MasterTableView.TableLayout = GridTableLayout.Fixed
            .MasterTableView.AllowMultiColumnSorting = False

            .Height = Unit.Pixel(600)
        End With
        
        With RadGrid2
            .EnableEmbeddedSkins = False
            .Skin = "Prompt"
            .GroupingEnabled = False
            .AllowSorting = True
                        
            .ClientSettings.AllowColumnsReorder = True
            .ClientSettings.ColumnsReorderMethod = GridClientSettings.GridColumnsReorderMethod.Reorder
            .ClientSettings.Scrolling.AllowScroll = True
            .ClientSettings.Scrolling.ScrollHeight = Unit.Percentage(50)
            .ClientSettings.Scrolling.UseStaticHeaders = True
            .ClientSettings.Resizing.AllowColumnResize = True

            .MasterTableView.EnableHeaderContextMenu = False
            .MasterTableView.TableLayout = GridTableLayout.Fixed
            .MasterTableView.AllowMultiColumnSorting = False

            .Height = Unit.Pixel(200)
        End With
        
        BuildMenu()
       
        
        With contentPopup
            .VisibleOnPageLoad = False
            .Skin = "Windows7"
                         
            Dim ww As New RadWindow

            ww = New RadWindow
            With ww
                .ID = "EditWindow"
                .Title = " "
                .Width = 550
                .Height = 580
                .Modal = True
                .VisibleStatusbar = False
                .ReloadOnShow = True
                .Behaviors = WindowBehaviors.Close + WindowBehaviors.Move
            End With
            .Windows.Add(ww)
            
        End With
       
        
        If Not IsPostBack Then
            buildProjectDropdown()
        End If
    End Sub
    
    Private Sub buildProjectDropdown()
       
    End Sub
    
    Private Sub BuildMenu()
        
        If Not IsPostBack Then          'Configure Tool Bar
            
            With RadMenu1
                .EnableEmbeddedSkins = False
                .Skin = "Prompt"
                .Width = Unit.Percentage(100)
                .EnableOverlay = False
                .OnClientItemClicking = "OnClientItemClicking"

                .CollapseAnimation.Duration = "200"
                .CollapseAnimation.Type = AnimationType.InOutBounce
                .ExpandAnimation.Duration = "200"
                .ExpandAnimation.Type = AnimationType.InOutBounce
            End With
        End If
        
        If Not IsPostBack Then
            
            'build buttons
            Dim but As RadMenuItem
                
            but = New RadMenuItem
            With but
                .Text = "Add New Correspondence"
                .ImageUrl = "images/add.png"
                .Attributes("onclick") = "return EditCorrespondence(" & nProjectID & ",0,'New','');"
                .ToolTip = "Add a New Meeting."
                .PostBack = False
                
                'If bReadOnly Then
                '.Visible = False
                'Else
                .Visible = True
                'End If
            End With
            RadMenu1.Items.Add(but)
            but = New RadMenuItem
            but.IsSeparator = True
            RadMenu1.Items.Add(but)
                      
            'Add grid configurator       
            Dim butConfig As New RadMenuItem
            With butConfig
                .Text = "Preferences"
                .ImageUrl = "images/gear.png"
                .PostBack = False
            End With
            RadMenu1.Items.Add(butConfig)
            
            'Add sub items
            Dim butConfigSub As New RadMenuItem
            With butConfigSub
                .Text = "Visible Columns"
                .ImageUrl = "images/column_preferences.png"
                .PostBack = False
            End With
            
            'Load the avaialble columns as checkbox items
            For Each col As GridColumn In RadGrid1.Columns
                If col.HeaderText <> "" Then
                    Dim butCol As New RadMenuItem
                    With butCol
                        .Text = col.HeaderText
                        .Value = "ColumnVisibility"
                        If col.Visible = True Then
                            .ImageUrl = "images/check2.png"
                            .Attributes("Visibility") = "On"
                        Else
                            .ImageUrl = ""
                            .Attributes("Visibility") = "Off"
                        End If
                        
                        .Attributes("ID") = col.UniqueName
                    End With
                    butConfigSub.Items.Add(butCol)
                End If
 
            Next
            butConfig.Items.Add(butConfigSub)
            
            'Add sub items
            butConfigSub = New RadMenuItem
            With butConfigSub
                .Text = "Restore Default Settings"
                .Value = "RestoreDefaultSettings"
                .ImageUrl = "images/gear_refresh.png"
            End With
            butConfig.Items.Add(butConfigSub)

            Dim butDropDown As New RadMenuItem
            With butDropDown
                .Text = "Export"
                .ImageUrl = "images/data_down.png"
                .PostBack = False
            End With
            
            'Add sub items
            Dim butSub As New RadMenuItem
            With butSub
                .Text = "Export To Excel"
                .Value = "ExportExcel"
                .Attributes("CancelAjax") = "Y"   'NOTE: This is needed to cancel ajax call and do regular postback as grid export to pdf/execl does not work with ajax
                .ImageUrl = "images/excel.gif"
                .PostBack = True
            End With
            'butDropDown.Items.Add(butSub)
            
            butSub = New RadMenuItem
            With butSub
                .Text = "Export To PDF"
                .Value = "ExportPDF"
                .Attributes("CancelAjax") = "Y"   'NOTE: This is needed to cancel ajax call and do regular postback as grid export to pdf/execl does not work with ajax
                .ImageUrl = "images/prompt_pdf.gif"
                .PostBack = True
            End With
            'butDropDown.Items.Add(butSub)
            'RadMenu1.Items.Add(butDropDown)
 
            butDropDown = New RadMenuItem
            With butDropDown
                .Text = "Print"
                .ImageUrl = "images/printer.png"
                .PostBack = False
            End With
                          
            but = New RadMenuItem
            but.IsSeparator = True
            RadMenu1.Items.Add(but)
                                     
        End If
        
        RadGrid1.Rebind()
        'RadMenu1.Attributes("onclick") = "return EditMeeting(" & nProjectID & ",0,'New');"
        
    End Sub
    
    Protected Sub RadGrid1_NeedDataSource(ByVal source As Object, ByVal e As Telerik.Web.UI.GridNeedDataSourceEventArgs) Handles RadGrid1.NeedDataSource
        Using db As New RFI
            RadGrid1.DataSource = db.getAllProjectContracts(nProjectID, False, Session("ContactType"), "PMCorrespondence")
        End Using        
    End Sub
    
    Protected Sub RadGrid2_NeedDataSource(ByVal source As Object, ByVal e As Telerik.Web.UI.GridNeedDataSourceEventArgs) Handles RadGrid2.NeedDataSource
        'loads the grid whenever it needs data (sorting, rebinding, etc...)            
        Using db As New Correspondence
            'RadGrid2.DataSource = db.getCorrespondenceLevelSelect("Project", nProjectID, nContactID)
            RadGrid2.DataSource = db.getCorrespondenceByRoll("Project", nProjectID, nContactID, Session("ContactType"))
        End Using                 
    End Sub
    
    Protected Sub RadGrid2_ItemCreated(ByVal sender As Object, ByVal e As Telerik.Web.UI.GridItemEventArgs) Handles RadGrid2.ItemCreated
        'This event allows us to customize the cell contents - fired before databound
       
        If (TypeOf e.Item Is GridDataItem) Then
            Dim item As GridDataItem = CType(e.Item, GridDataItem)
            Dim nCorrID As Integer = item.OwnerTableView.DataKeyValues(item.ItemIndex)("CorrID")
            Dim sFileName As String = item.OwnerTableView.DataKeyValues(item.ItemIndex)("FileName")
            Dim nAuthor As Integer = item.OwnerTableView.DataKeyValues(item.ItemIndex)("CreateBy")
            
            Dim linkButton As HyperLink
            If nAuthor = nContactID Then
                Try
                    linkButton = CType(item("CorrNumber").Controls(0), HyperLink)
                    linkButton.Attributes("onclick") = "return EditCorrespondence(" & nProjectID & "," & nCorrID & ",'Existing','')"
                    linkButton.CssClass = ""
                Catch ex As Exception
                End Try
            Else
                
            End If
            
       
            If Not sFileName = "None Selected" Then
                Dim sPath As String = ProcLib.GetCurrentRelativeAttachmentPath() & "DistrictID_" & Session("DistrictID") & "/_apprisedocs/"
                sPath &= "_Correspondence/_ProjectID_" & nProjectID & "/" & nAuthor & "/"

                Dim linkButton2 As HyperLink = CType(item("FileName").Controls(0), HyperLink)
                'linkButton2.ToolTip = "Show currently posted Minutes for this selected Meeting."
                linkButton2.NavigateUrl = sPath & sFileName
                linkButton2.Target = "_new"              
            Else            'remove the hyperlink and just display none
                item("FileName").Controls.Clear()
                item("FileName").Text = sFileName
            End If
        End If
        
    End Sub
    

    Protected Sub RadGrid1_DetailTableDataBind(ByVal source As Object, ByVal e As GridDetailTableDataBindEventArgs) Handles RadGrid1.DetailTableDataBind
        Dim parentItem As GridDataItem = CType(e.DetailTableView.ParentItem, GridDataItem)
        
        Using db As New Correspondence
            'e.DetailTableView.DataSource = db.getCorrespondenceLevelSelect("Contract", nProjectID, nContactID)
            e.DetailTableView.DataSource = db.getCorrespondenceByRoll("Contract", nProjectID, nContactID, Session("ContactType"))
        End Using
        
    End Sub
    
    Protected Sub RadGrid1_ItemCreated(ByVal sender As Object, ByVal e As Telerik.Web.UI.GridItemEventArgs) Handles RadGrid1.ItemCreated
        'This event allows us to customize the cell contents - fired before databound
        
        If nContractID <> 0 Then
            For Each dataitem As GridDataItem In RadGrid1.MasterTableView.Items
                If dataitem("ContractID").Text = Session("ContractID") Then
                    dataitem.Expanded = True
                End If
            Next
        End If       
        
        If (TypeOf e.Item Is GridDataItem) Then
            Dim item As GridDataItem = CType(e.Item, GridDataItem)
            Dim nCorrID As Integer = item.OwnerTableView.DataKeyValues(item.ItemIndex)("CorrID")
            Dim sFileName As String = item.OwnerTableView.DataKeyValues(item.ItemIndex)("FileName")
            Dim nContractID As Integer = item.OwnerTableView.DataKeyValues(item.ItemIndex)("ContractID")
            Dim nAuthor As Integer = item.OwnerTableView.DataKeyValues(item.ItemIndex)("CreateBy")
            
            Dim linkButton As HyperLink
            If nAuthor = nContactID Then
                Try
                    linkButton = CType(item("CorrNumber").Controls(0), HyperLink)
                    linkButton.Attributes("onclick") = "return EditCorrespondence(" & nProjectID & "," & nCorrID & ",'Existing','')"
                    linkButton.CssClass = ""
                Catch ex As Exception
                End Try
            Else
                
            End If
           
            Try
                Dim linkButton2 As HyperLink
                Dim sPath As String = ProcLib.GetCurrentRelativeAttachmentPath() & "DistrictID_" & Session("DistrictID") & "/_apprisedocs/"
                sPath &= "_Correspondence/_ProjectID_" & nProjectID & "/ContractID_" & nContractID & "/" & nAuthor & "/"
                linkButton2 = CType(item("FileName").Controls(0), HyperLink)
                linkButton2.NavigateUrl = sPath & sFileName
                linkButton2.Target = "_new"                
            Catch ex As Exception               
            End Try
        End If                
    End Sub
    
    Private Sub RadGrid1_ItemDataBound(ByVal sender As Object, ByVal e As Telerik.Web.UI.GridItemEventArgs) Handles RadGrid1.ItemDataBound
       
            
    End Sub
    
    Protected Sub RadMenu1_ItemClick(ByVal sender As Object, ByVal e As Telerik.Web.UI.RadMenuEventArgs)
       
        Dim btn As RadMenuItem = e.Item
        
        Select Case btn.Value
            
            Case "ExportExcel"
                'RadGrid1.Columns.FindByUniqueName("Attachments").Visible = False
                RadGrid1.MasterTableView.ExportToExcel()
                
            Case "ExportPDF"
                'RadGrid1.Columns.FindByUniqueName("Attachments").Visible = False
                For Each item As GridItem In RadGrid1.MasterTableView.Items
                    If TypeOf item Is GridDataItem Then
                        Dim dataItem As GridDataItem = CType(item, GridDataItem)
                        Dim lnk As HyperLink = CType(dataItem("MeetingDate").Controls(0), HyperLink)
                        lnk.NavigateUrl = ""
                    End If
                Next
                RadGrid1.MasterTableView.ExportToPdf()
            
                    
            Case "ColumnVisibility"
                If btn.Attributes("Visibility") = "Off" Then
                    btn.ImageUrl = "images/check2.png"
                    btn.Attributes("Visibility") = "On"
                    RadGrid1.Columns.FindByUniqueName(btn.Attributes("ID")).Visible = True
                Else
                    btn.ImageUrl = ""
                    btn.Attributes("Visibility") = "Off"
                    RadGrid1.Columns.FindByUniqueName(btn.Attributes("ID")).Visible = False
                End If
                Using db As New promptUserPrefs
                    db.SaveGridColumnVisibility("MeetingMinutesGridColumns", btn.Attributes("ID"), btn.Attributes("Visibility"), "ProjectID", nProjectID)
                End Using
                RadGrid1.Rebind()
                
            Case "RestoreDefaultSettings"
                
                Using db As New promptUserPrefs
                    db.RemoveUserSavedSettings("ChangeOrdersGridSettings", "ProjectID", nProjectID)
                    db.RemoveUserSavedSettings("ChangeOrdersGridColumns", "ProjectID", nProjectID)
                End Using
                Response.Redirect(Page.Request.RawUrl)

        End Select
    End Sub
     
</script>

<asp:Content ID="Content1" ContentPlaceHolderID="mainBody" runat="Server">
    <telerik:RadWindowManager ID="contentPopup" runat="server" />

    <asp:HiddenField ID="ProjID" runat="server" />

    <telerik:radmenu id="RadMenu1" runat="server" onitemclick="RadMenu1_ItemClick" style="z-index: 100;top:5px;width:470px;position:relative;right:0px" />

    <div style="z-index:10;left:0px;top:0px;position:relative;width:99%;height:36px;font-size:18px;font-weight:bold;font-family:arial;
       letter-spacing:3px;border-style:solid;border-width:0px;background-color:#FFFFFF">
        <asp:Label ID="lblModule" runat="server" Text="Project Level Correspondence" style="z-index:600;left:20px;top:15px;position:relative;font-size:14px;font-weight:bold;font-family:arial;letter-spacing:3px"></asp:Label>       
     </div>
  
    <telerik:RadGrid ID="RadGrid2" runat="server" AllowSorting="True" AutoGenerateColumns="False" 
        GridLines="None" Width="99%" Height="25%" EnableAJAX="True"  style="position:relative;top:3px">
        <ClientSettings>
            <Selecting AllowRowSelect="false" />
            <Scrolling AllowScroll="false" UseStaticHeaders="True" />
        </ClientSettings>
        <MasterTableView Width="100%" GridLines="None" DataKeyNames="CorrID,FileName,CreateBy" 
                    NoMasterRecordsText="No Correspondence Found.">
            <Columns>

                <telerik:GridBoundColumn UniqueName="CorrID" HeaderText="Correspondence ID" DataField="CorrID" Visible="false">
                    <ItemStyle HorizontalAlign="Left" Width="150px"/>
                    <HeaderStyle HorizontalAlign="Left" Width="150px" />
                </telerik:GridBoundColumn>
    
                <telerik:GridHyperLinkColumn UniqueName="CorrNumber" HeaderText="Number" DataTextField="CorrNumber">
                    <ItemStyle HorizontalAlign="Left" Width="150px"/>
                    <HeaderStyle HorizontalAlign="Left" Width="150px" />
                </telerik:GridHyperLinkColumn>

               <telerik:GridBoundColumn UniqueName="CorrType" HeaderText="Type" DataField="CorrType">
                    <ItemStyle HorizontalAlign="Left" Width="150px"/>
                    <HeaderStyle HorizontalAlign="Left" Width="150px" />
                </telerik:GridBoundColumn>

               <telerik:GridBoundColumn UniqueName="Name" HeaderText="Uploaded By" DataField="Name">
                    <ItemStyle HorizontalAlign="Left" Width="100px"/>
                    <HeaderStyle HorizontalAlign="Left" Width="100px" />
                </telerik:GridBoundColumn>

                <telerik:GridBoundColumn UniqueName="CorrName" HeaderText="Description" DataField="CorrName">
                    <ItemStyle HorizontalAlign="Left" Width="200px"/>
                    <HeaderStyle HorizontalAlign="Left" Width="200px" />
                </telerik:GridBoundColumn>

                <telerik:GridHyperLinkColumn UniqueName="FileName" HeaderText="File Name" DataTextField="FileName">
                    <ItemStyle HorizontalAlign="Left" Width="25%" />
                    <HeaderStyle HorizontalAlign="Left" Width="25%" />
                </telerik:GridHyperLinkColumn>

            </Columns>
        </MasterTableView>
    </telerik:RadGrid>   


   <div style="z-index:600;left:0px;top:8px;position:relative;width:99%;height:20px;font-size:18px;font-weight:bold;font-family:arial;
       letter-spacing:3px;border-style:solid;border-width:0px;background-color:#FFFFFF">
     <asp:Label ID="lblModule2" runat="server" Text="Contract Level Correspondence" style="z-index:600;left:20px;top:2px;position:absolute;font-size:14px;font-weight:bold;font-family:arial;letter-spacing:3px"></asp:Label>

   </div>
 

    <telerik:RadGrid ID="RadGrid1" runat="server" AllowSorting="true" AutoGenerateColumns="False"
        GridLines="None" Width="99%" Height="50%" EnableEmbeddedSkins="false" enableajax="True" Style="Top:8px;position:relative">
        <ClientSettings>
            <Selecting AllowRowSelect="False" />
            <Scrolling AllowScroll="True" UseStaticHeaders="True" ScrollHeight="50%" />
        </ClientSettings>

        <MasterTableView Width="99%" GridLines="None" DataKeyNames="ContractID,BidPackNumber"
            NoMasterRecordsText="No Correspondence found.">
            <Columns>

                <telerik:GridBoundColumn UniqueName="ContractID" HeaderText="Contract ID" DataField="ContractID">
                    <ItemStyle HorizontalAlign="Left" Width="70px" VerticalAlign="Top" />
                    <HeaderStyle HorizontalAlign="Left" Width="70px" />
                </telerik:GridBoundColumn>

                <telerik:GridBoundColumn UniqueName="BidPackNumber" HeaderText="Bid Pack Number" DataField="BidPackNumber">
                    <ItemStyle HorizontalAlign="Left" Width="120px" VerticalAlign="Top" />
                    <HeaderStyle HorizontalAlign="Left" Width="120px"  />
                </telerik:GridBoundColumn>

                 <telerik:GridBoundColumn UniqueName="Description" HeaderText="Description" DataField="Description">
                    <ItemStyle HorizontalAlign="Left" Width="250px" VerticalAlign="Top" />
                    <HeaderStyle HorizontalAlign="Left" Width="250px"   />
                </telerik:GridBoundColumn>

                <telerik:GridBoundColumn UniqueName="Contractor" HeaderText="Contractor" DataField="Contractor">
                    <ItemStyle HorizontalAlign="Left" Width="200px" VerticalAlign="Top" />
                    <HeaderStyle HorizontalAlign="Left" Width="200px" />
                </telerik:GridBoundColumn>
 
                 <telerik:GridBoundColumn UniqueName="Contact" HeaderText="Contact" DataField="Contact">
                    <ItemStyle HorizontalAlign="Left" Width="150px" VerticalAlign="Top" />
                    <HeaderStyle HorizontalAlign="Left" Width="150px" />
                </telerik:GridBoundColumn>

                 <telerik:GridBoundColumn UniqueName="Phone1" HeaderText="Phone Number" DataField="Phone1">
                    <ItemStyle HorizontalAlign="Left" Width="80px" VerticalAlign="Top" />
                    <HeaderStyle HorizontalAlign="Left" Width="80px"  />
                </telerik:GridBoundColumn>  
        </Columns>

        <DetailTables>
             <telerik:GridTableView runat="server" Name="Corr" DataKeyNames="CorrID,FileName,ContractID,CreateBy" TableLayout="Auto" >
                <ParentTableRelation>
                  <telerik:GridRelationFields DetailKeyField="ContractID" MasterKeyField="ContractID" />
                </ParentTableRelation>
            <ItemStyle CssClass="rfi_unassigned" />

            <Columns>

             <telerik:GridBoundColumn UniqueName="CorrID" HeaderText="Correspondence ID" DataField="CorrID" Visible="false">
                    <ItemStyle HorizontalAlign="Left" Width="150px"/>
                    <HeaderStyle HorizontalAlign="Left" Width="150px" />
                </telerik:GridBoundColumn>
    
                <telerik:GridHyperLinkColumn UniqueName="CorrNumber" HeaderText="Number" DataTextField="CorrNumber">
                    <ItemStyle HorizontalAlign="Left" Width="150px"/>
                    <HeaderStyle HorizontalAlign="Left" Width="150px" />
                </telerik:GridHyperLinkColumn>

               <telerik:GridBoundColumn UniqueName="CorrType" HeaderText="Type" DataField="CorrType">
                    <ItemStyle HorizontalAlign="Left" Width="150px"/>
                    <HeaderStyle HorizontalAlign="Left" Width="150px" />
                </telerik:GridBoundColumn>

               <telerik:GridBoundColumn UniqueName="Name" HeaderText="Uploaded By" DataField="Name">
                    <ItemStyle HorizontalAlign="Left" Width="100px"/>
                    <HeaderStyle HorizontalAlign="Left" Width="100px" />
                </telerik:GridBoundColumn>

                <telerik:GridBoundColumn UniqueName="CorrName" HeaderText="Description" DataField="CorrName">
                    <ItemStyle HorizontalAlign="Left" Width="200px"/>
                    <HeaderStyle HorizontalAlign="Left" Width="200px" />
                </telerik:GridBoundColumn>

                <telerik:GridHyperLinkColumn UniqueName="FileName" HeaderText="File Name" DataTextField="FileName">
                    <ItemStyle HorizontalAlign="Left" Width="25%" />
                    <HeaderStyle HorizontalAlign="Left" Width="25%" />
                </telerik:GridHyperLinkColumn>

            </Columns>

             </telerik:GridTableView>

        </DetailTables>

    </MasterTableView>
</telerik:RadGrid>



    <telerik:radajaxmanager id="RadAjaxManager1" runat="server">
        <ClientEvents OnRequestStart="ajaxRequestStart" OnResponseEnd="ajaxRequestEnd" />
        <AjaxSettings>


            <telerik:AjaxSetting AjaxControlID="RadGrid1">
                <UpdatedControls>
                    <telerik:AjaxUpdatedControl ControlID="RadGrid1" LoadingPanelID="RadAjaxLoadingPanel1" />
                </UpdatedControls>
            </telerik:AjaxSetting>

            <telerik:AjaxSetting AjaxControlID="RadGrid2">
                <UpdatedControls>
                    <telerik:AjaxUpdatedControl ControlID="RadGrid2" LoadingPanelID="RadAjaxLoadingPanel2" />
                </UpdatedControls>
            </telerik:AjaxSetting>


            <telerik:AjaxSetting AjaxControlID="RadMenu1">
                <UpdatedControls>
                    <telerik:AjaxUpdatedControl ControlID="RadGrid1" LoadingPanelID="RadAjaxLoadingPanel1" />
                    <telerik:AjaxUpdatedControl ControlID="RadMenu1" LoadingPanelID="RadAjaxLoadingPanel1" />
                </UpdatedControls>   
                
                <UpdatedControls>
                    <telerik:AjaxUpdatedControl ControlID="RadGrid2" LoadingPanelID="RadAjaxLoadingPanel2" />
                    <telerik:AjaxUpdatedControl ControlID="RadMenu2" LoadingPanelID="RadAjaxLoadingPanel2" />
                </UpdatedControls>      
                   
            </telerik:AjaxSetting>

        </AjaxSettings>
    </telerik:radajaxmanager>


    <telerik:radajaxloadingpanel id="RadAjaxLoadingPanel1" runat="server" height="75px"
        width="75px" transparency="25">
        <img alt="Loading..." src="images/loading.gif" style="border: 0;" />
    </telerik:radajaxloadingpanel>


    <telerik:radajaxloadingpanel id="RadAjaxLoadingPanel2" runat="server" height="75px"
        width="75px" transparency="25">
        <img alt="Loading..." src="images/loading.gif" style="border: 0;" />
    </telerik:radajaxloadingpanel>


    
  <telerik:radtooltipmanager id="RadToolTipManager1" runat="server" sticky="True" title=""
        position="BottomCenter" skin="Office2007" hidedelay="500" manualclose="False"
        showevent="OnMouseOver" showdelay="100" animation="Fade" autoclosedelay="6000"
        AutoTooltipify="False" width="350" relativeto="Mouse" renderinpageroot="False">
    </telerik:radtooltipmanager>

<telerik:RadScriptBlock ID="RadScriptBlock1" runat="server">

<script type="text/javascript" language="javascript">
    // Begin ******************* Menu Handlers ***********************

    var sCancelAjax;    // flag to disable ajax for grid export functions

    function ajaxRequestStart(sender, args) {
        //Called when ajax request starts so we can disable for grid export controls.
        if (sCancelAjax == 'Y') {
            args.set_enableAjax(false);
        }
    }

    function ajaxRequestEnd(sender, args) {
        //Called when ajax request Ends.
        args.set_enableAjax(true);
    }

    function OnClientItemClicking(sender, args) {
        // set this var so that we can cancel ajax for grid export function
        var button = args.get_item();
        sCancelAjax = button.get_attributes().getAttribute("CancelAjax");
    }


    // End ******************* Menu Handlers ***********************

    function EditCorrespondence(projectid, coID, displaytype,coType) {
        //var projID = document.getElementById('<% = ProjID.ClientID %>').value

        var oWnd = window.radopen("correspondence_edit.aspx?ProjectID=" + projectid + "&CorrID=" + coID + "&DisplayType=" + displaytype + "&coType=" + coType, "EditWindow");
        return false;
    }

</script>
</telerik:RadScriptBlock>

</asp:Content>
