<%@ Page Language="VB" %>
<%@ Import Namespace="Prompt" %>
<%@ Register Assembly="Telerik.Web.UI" Namespace="Telerik.Web.UI" TagPrefix="telerik" %>

<script runat="server">
    
    Private Sub Page_Load(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MyBase.Load

        ProcLib.CheckSession(Page)
        ProcLib.LoadPopupJscript(Page)

        ''set up help button
        Session("PageID") = "AppriseBondMeetings"
        
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

            .MasterTableView.EnableHeaderContextMenu = True
            .MasterTableView.TableLayout = GridTableLayout.Fixed
            .MasterTableView.AllowMultiColumnSorting = False

            'If Request.Browser.Browser = "IE" Then
            .Height = Unit.Pixel(600)
            'Else
            '.Height = Unit.Percentage(88)
            'End If
            
            .ExportSettings.FileName = "PromptBondMeetingsExport"
            .ExportSettings.OpenInNewWindow = True
            .ExportSettings.Pdf.PageTitle = "Bond Website Meeting List"
        End With
        
        With contentPopups
            .VisibleOnPageLoad = False
            .Skin = "Office2007"
                         
            Dim ww As New RadWindow

            ww = New RadWindow
            With ww
                .ID = "EditWindow"
                .NavigateUrl = "#"
                .Title = ""
                .Width = 550
                .Height = 275
                .Modal = True
                .VisibleStatusbar = False
                .ReloadOnShow = True
                .Behaviors = WindowBehaviors.Close + WindowBehaviors.Move
            End With
            .Windows.Add(ww)
            
   
        End With
        
        linkAddNew.Attributes("onclick") = "return AddNewMeeting();"
 
          
    End Sub
    
    Protected Sub RadGrid1_NeedDataSource(ByVal source As Object, ByVal e As Telerik.Web.UI.GridNeedDataSourceEventArgs) Handles RadGrid1.NeedDataSource
        'loads the grid whenever it needs data (sorting, rebinding, etc...)
        Using db As New BondSite
            RadGrid1.DataSource = db.GetAllBondMeetings
        End Using
        
    End Sub
    
    Protected Sub RadGrid1_ItemCreated(ByVal sender As Object, ByVal e As Telerik.Web.UI.GridItemEventArgs) Handles RadGrid1.ItemCreated
        
        'This event allows us to customize the cell contents - fired before databound
        
        If (TypeOf e.Item Is GridDataItem) Then
            Dim item As GridDataItem = CType(e.Item, GridDataItem)
            Dim nMeetingID As Integer = item.OwnerTableView.DataKeyValues(item.ItemIndex)("MeetingID")
            Dim sAgenda As String = ProcLib.CheckNullDBField(item.OwnerTableView.DataKeyValues(item.ItemIndex)("AgendaFileName"))
            Dim sMinutes As String = ProcLib.CheckNullDBField(item.OwnerTableView.DataKeyValues(item.ItemIndex)("MinutesFileName"))

            'update the link button to open report window
            Dim linkButton As HyperLink = CType(item("EditMeeting").Controls(0), HyperLink)
            linkButton.Attributes("onclick") = "return EditMeeting(" & nMeetingID & ");"
            linkButton.ToolTip = "Edit selected Meeting."
            linkButton.NavigateUrl = "#"
            linkButton.ImageUrl = "images/edit.png"
            
            If Trim(sAgenda) = "" Then       'build upload link
                Dim linkButton1 As HyperLink = CType(item("Agenda").Controls(0), HyperLink)
                linkButton1.Attributes("onclick") = "return UploadAgenda(" & nMeetingID & ");"
                linkButton1.ToolTip = "Upload Agenda for this selected Meeting."
                linkButton1.NavigateUrl = "#"
                linkButton1.ImageUrl = "images/upload_file_small.gif"
                
            Else    'provide link to document
                'Note: These do not use rad windows as they are external opens
                Dim sPath As String = ProcLib.GetCurrentRelativeAttachmentPath() & "DistrictID_" & Session("DistrictID") & "/_apprisedocs/_bondsite/_meetingID_" & nMeetingID & "/"
                Dim linkButton1 As HyperLink = CType(item("Agenda").Controls(0), HyperLink)
                linkButton1.ToolTip = "Show currently posted Agenda for this selected Meeting."
                linkButton1.NavigateUrl = sPath & sAgenda
                linkButton1.Target = "_new"
            End If
            
            If Trim(sMinutes) = "" Then       'build upload link
                Dim linkButton2 As HyperLink = CType(item("Minutes").Controls(0), HyperLink)
                linkButton2.Attributes("onclick") = "return UploadMinutes(" & nMeetingID & ");"
                linkButton2.ToolTip = "Upload Minutes for this Meeting."
                linkButton2.NavigateUrl = "#"
                linkButton2.ImageUrl = "images/upload_file_small.gif"
                
            Else    'provide link to document
                'Note: These do not use rad windows as they are external opens
                Dim sPath As String = ProcLib.GetCurrentRelativeAttachmentPath() & "DistrictID_" & Session("DistrictID") & "/_apprisedocs/_bondsite/_meetingID_" & nMeetingID & "/"
                Dim linkButton2 As HyperLink = CType(item("Minutes").Controls(0), HyperLink)
                linkButton2.ToolTip = "Show currently posted Minutes for this selected Meeting."
                linkButton2.NavigateUrl = sPath & sMinutes
                linkButton2.Target = "_new"
            End If

            ''update the link button to open report window
 


        End If
    End Sub

 
</script>

<html xmlns="http://www.w3.org/1999/xhtml">
<head id="Head1" runat="server">
    <title> </title>
    <link href="Styles.css" rel="stylesheet" type="text/css" />
</head>
<body>
    <form id="Form1" method="post" runat="server">
    <telerik:RadScriptManager ID="RadScriptManager1" runat="server" />
    <br />
<div align="right" id="header" style="float: right; z-index: 150; position: static;">
   <asp:HyperLink ID="linkAddNew" runat="server" NavigateURL="#"  ImageUrl="images/button_add_new.gif">add new</asp:HyperLink>
</div>

<br />
<br />
<telerik:RadGrid ID="RadGrid1" runat="server" AllowSorting="False" AutoGenerateColumns="False"
    GridLines="None" Width="100%" EnableAJAX="True" Height="95%" SkinsPath="" Skin="Simple">
    <ClientSettings>
        <Selecting AllowRowSelect="False" />
        <Scrolling AllowScroll="True" UseStaticHeaders="True" ScrollHeight="50%" />
    </ClientSettings>
    <MasterTableView Width="100%" GridLines="None" DataKeyNames="MeetingID,AgendaFileName,MinutesFileName" NoMasterRecordsText="No meetings found.">
        <Columns>
  
            <telerik:GridHyperLinkColumn UniqueName="EditMeeting" HeaderText="" >
                <ItemStyle HorizontalAlign="Left" Width="15px" />
                <HeaderStyle HorizontalAlign="Left" Width="15px" />
            </telerik:GridHyperLinkColumn>
           
           <telerik:GridBoundColumn UniqueName="MeetingDate" HeaderText="Date" DataField="MeetingDate"  DataFormatString="{0:MM/dd/yy}">
                <ItemStyle HorizontalAlign="Left"  Width="55px"/>
                <HeaderStyle HorizontalAlign="Left" Width="55px" />
            </telerik:GridBoundColumn>
            <telerik:GridBoundColumn UniqueName="Description" HeaderText="Description" DataField="Description">
                <ItemStyle HorizontalAlign="Left" />
                <HeaderStyle HorizontalAlign="Left" Width="20%" />
            </telerik:GridBoundColumn>
            <telerik:GridHyperLinkColumn UniqueName="Agenda" HeaderText="Agenda" DataTextField="AgendaFileName" SortExpression="AgendaFileName">
                <ItemStyle HorizontalAlign="Left" Width="250px" />
                <HeaderStyle HorizontalAlign="Left" Width="250px" />
            </telerik:GridHyperLinkColumn>
            <telerik:GridHyperLinkColumn UniqueName="Minutes" HeaderText="Minutes" DataTextField="MinutesFileName" SortExpression="MinutesFileName">
                <ItemStyle HorizontalAlign="Left" Width="250px" />
                <HeaderStyle HorizontalAlign="Left" Width="250px" />
            </telerik:GridHyperLinkColumn>
        </Columns>
    </MasterTableView>
</telerik:RadGrid>


<telerik:RadWindowManager ID="contentPopups" runat="server">
</telerik:RadWindowManager>

<script type="text/javascript" language="javascript">

    function EditMeeting(id)    
    {

        var oWnd = window.radopen("bondsite_meeting_edit.aspx?MeetingID=" + id, "EditWindow");
        return false;
    }

 
    function AddNewMeeting()     
    {

        var oWnd = window.radopen("bondsite_meeting_edit.aspx?MeetingID=0", "EditWindow");
        return false;
    }

    function UploadAgenda(id) {

        var oWnd = window.radopen("bondsite_meetings_upload.aspx?UploadType=Agenda&MeetingID=" + id , "EditWindow");
        return false;
    }

    function UploadMinutes(id) {

        var oWnd = window.radopen("bondsite_meetings_upload.aspx?UploadType=Meeting&MeetingID=" + id, "EditWindow");
        return false;
    }

    function refreshGrid() {
        RadGridNamespace.AsyncRequest('<%= RadGrid1.UniqueID %>', 'Rebind', '<%= RadGrid1.ClientID %>');
    }

    function GetRadWindow() {
        var oWindow = null;
        if (window.RadWindow) oWindow = window.RadWindow;
        else if (window.frameElement.radWindow) oWindow = window.frameElement.radWindow;
        return oWindow;
    }

</script>
    </form>
</body>
</html>
