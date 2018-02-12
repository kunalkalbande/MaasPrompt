<%@ Page Language="VB" MasterPageFile="~/content.master" Title="" %>

<%@ Register Assembly="Telerik.Web.UI" Namespace="Telerik.Web.UI" TagPrefix="telerik" %>
<%@ Import Namespace="Prompt" %>
<%@ Import Namespace="System.Collections.Generic" %>

<script runat="server">
    
    Private bReadOnly As Boolean = True
    Private CurrentLevel As String = ""
    Private CurrentCalendarID As Integer = 0
    Private sKeyField As String = ""
    Private nProjectID As Integer = 0
    Private nCollegeID As Integer = 0
    Private RecID As Integer = 0
    
    
    Private Sub Page_Load(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MyBase.Load

        ProcLib.CheckSession(Page)
        ProcLib.LoadPopupJscript(Page)

        ''set up help button
        Session("PageID") = "Calendar"
        
        CurrentLevel = "college"
        
        nProjectID = Request.QueryString("ProjectID")
        nCollegeID = Request.QueryString("CollegeID")
              
        Dim masterTabs As RadTabStrip = Master.FindControl("tabMain")
        Session("CurrentTab") = "Calendar"
        For Each radTab In masterTabs.GetAllTabs
            If radTab.Value = "Calendar" Then
                radTab.Selected = True
                radTab.SelectParents()
                Exit For
            End If
        Next
        
        With RadScheduler1
            .Skin = "Windows7"
            .Height = Unit.Pixel(600)
            .SelectedView = SchedulerViewType.MonthView
            .AdvancedForm.Enabled = True
            .StartEditingInAdvancedForm = True
            .StartInsertingInAdvancedForm = True
            .ShowViewTabs = False
            .EnableRecurrenceSupport = False
        End With
        
        If Not IsPostBack Then
            
            Session.Remove(AppointmentsKey)
            RadScheduler1.DataKeyField = "ID"
            RadScheduler1.DataStartField = "Start"
            RadScheduler1.DataEndField = "End"
            RadScheduler1.DataSubjectField = "Subject"
            RadScheduler1.DataRecurrenceField = "RecurrenceRule"
            RadScheduler1.DataRecurrenceParentKeyField = "RecurrenceParentID"
 
        End If

        'Configure the Popup Window(s)
        With contentPopups
            .VisibleOnPageLoad = False
            .Skin = "Windows7"
            Dim ww As New Telerik.Web.UI.RadWindow
            ww = New Telerik.Web.UI.RadWindow
            With ww
                .ID = "EditWindow"
                .NavigateUrl = ""
                .Title = ""
                .Width = 375
                .Height = 200
                .Modal = True
                .VisibleStatusbar = False
                .ReloadOnShow = True
                .Behaviors = WindowBehaviors.Close + WindowBehaviors.Move
            End With
            .Windows.Add(ww)
            
              
        End With
  
        Dim bAllowEdit As Boolean = False

        Using db As New EISSecurity
            db.CollegeID = Session("CollegeID")
            db.ProjectID = nProjectID
        
            Select Case CurrentLevel
                Case "college"
                    RecID = nCollegeID
                    sKeyField = "CollegeID"
                    bAllowEdit = db.FindUserPermission("CollegeCalendar", "Write")
                    
                Case "project"
                    RecID = nProjectID
                    sKeyField = "ProjectID"
                    bAllowEdit = db.FindUserPermission("ProjectCalendar", "Write")
                
   

            End Select
            
        End Using
        
        'If bAllowEdit Then
        '    With lnkAddNew
        '        .Visible = True
        '        .Attributes("onclick") = "return EditEntry(0,'" & CurrentLevel & "'," & RecID & ");"
        '    End With
        'Else
        '    lnkAddNew.Visible = False
        'End If
        
        BuildMenu()
        
        SetCalendar()
  
    End Sub
    
    Private Sub SetCalendar()
        
        Dim calItems As RadMenuItem = RadMenu1.FindItemByText("Calendars")
        Dim cboCal As RadComboBox = DirectCast(calItems.FindControl("cboCalendars"), RadComboBox)
        CurrentCalendarID = cboCal.SelectedValue
        
        Dim calx As RadMenuItem = RadMenu1.FindItemByText("Edit This Calendar")
        If CurrentCalendarID = -99 Then
            calx.Visible = False
            RadScheduler1.AllowEdit = False
            RadScheduler1.AllowDelete = False
            RadScheduler1.AllowInsert = False
            
        Else
            calx.Visible = True
            RadScheduler1.AllowEdit = True
            RadScheduler1.AllowDelete = True
            RadScheduler1.AllowInsert = True
        End If
        
        RadScheduler1.DataSource = Appointments

        
    End Sub
    
    
    Private Sub BuildMenu()
        
        If Not IsPostBack Then          'Configure Tool Bar

            With RadMenu1
                .EnableEmbeddedSkins = True
                .Skin = "Windows7"
                .Width = Unit.Percentage(100)
                .EnableOverlay = False
                '.OnClientItemClicking = "OnClientItemClicking"

                .CollapseAnimation.Duration = "200"
                .CollapseAnimation.Type = AnimationType.InOutBounce
                .ExpandAnimation.Duration = "200"
                .ExpandAnimation.Type = AnimationType.InOutBounce
            End With

            'build buttons
            Dim but As RadMenuItem

                     
            but = New RadMenuItem
            With but
                .Text = "Settings"
                '.ImageUrl = "images/add.png"
                '.Attributes("onclick") = "return EditRFI('0'," & nProjectID & ");"
                .ToolTip = ""
                .PostBack = False
                'If bReadOnly Then
                '    .Visible = False
                'Else
                '    .Visible = True
                'End If
            End With
            RadMenu1.Items.Add(but)

            Dim butsub As New RadMenuItem
            With butsub
                .Text = "Add New Calendar"
                .Value = "Add New Calendar"
                .ImageUrl = "images/add.png"
                .Attributes("onclick") = "return EditCalendar(0," & nCollegeID & ");"
                .ToolTip = "Add new Calendar."
                .PostBack = False
            End With
            but.Items.Add(butsub)
            
            butsub = New RadMenuItem
            With butsub
                .Text = "Edit This Calendar"
                .Value = "Edit This Calendar"
                .ImageUrl = "images/edit.png"
                .Attributes("onclick") = "return EditCalendar(16," & nCollegeID & ");"
                .ToolTip = "Edit This Calendar."
                .PostBack = False
            End With
            but.Items.Add(butsub)

            Dim calItems As RadMenuItem = RadMenu1.FindItemByText("Calendars")
            Dim cboCal As RadComboBox = DirectCast(calItems.FindControl("cboCalendars"), RadComboBox)
            cboCal.AutoPostBack = True
            
            'Add items to the calendar cbo
            Using db As New PromptDataHelper
                Dim tbl As DataTable = db.ExecuteDataTable("SELECT * FROM Calendars WHERE CollegeID = " & nCollegeID & " ORDER BY Name ")
                If tbl.Rows.Count = 0 Then   'add the default calendar
                    db.ExecuteNonQuery("INSERT INTO Calendars (Name,CollegeID,ItemColor) VALUES ('Default Calendar'," & nCollegeID & ",'Blue')")
                    'reget
                    tbl = db.ExecuteDataTable("SELECT * FROM Calendars WHERE CollegeID = " & nCollegeID & " ORDER BY Name ")
                End If
                For Each row As DataRow In tbl.Rows
                    Dim item As New RadComboBoxItem
                    item.Text = row("Name")
                    item.Value = row("CalendarID")
                    cboCal.Items.Add(item)
                    
                Next
                
                Dim itemx As New RadComboBoxItem
                itemx.Text = "Show All Calendars"
                itemx.Value = -99
                cboCal.Items.Add(itemx)
                
                
                If CurrentCalendarID = 0 Then
                    cboCal.SelectedIndex = 0     'default to first one
                    Session("CurrentCalendarID") = cboCal.SelectedValue
                Else
                    cboCal.FindItemByValue(CurrentCalendarID).Selected = True
                End If
                
                
            End Using
     

        End If

    End Sub
    
    
    '<<<<<<<<<<<<<<<<<<<<<<<<<<<< Calendar Properties and Functions
    Private Const AppointmentsKey As String = "Prompt.CalendarEntries"
    
    Private ReadOnly Property Appointments() As List(Of AppointmentInfo)
        Get
            Dim sessApts As List(Of AppointmentInfo) = TryCast(Session(AppointmentsKey), List(Of AppointmentInfo))
            If sessApts Is Nothing Or Session("CurrentCalendarID") <> CurrentCalendarID Then   'only rebuild if calendar changes or first time through
                sessApts = New List(Of AppointmentInfo)()
                'Load the entries
                Using db As New PromptDataHelper
                   
                    Dim sql As String = "SELECT CalendarEntries.*,Calendars.ItemColor FROM CalendarEntries "
                    sql &= "INNER JOIN Calendars ON Calendars.CalendarID = CalendarEntries.CalendarID "
                    
                    If CurrentCalendarID = -99 Then   'combine all calendars for this college
                        sql &= "WHERE CalendarEntries.CollegeID = " & nCollegeID
                    Else
                        sql &= "WHERE CalendarEntries.CalendarID = " & CurrentCalendarID
                    End If
                    
                    
                    Dim tbl As DataTable = db.ExecuteDataTable(sql)
                    For Each row As DataRow In tbl.Rows
                        Dim ai As New AppointmentInfo(row("Subject"), row("StartTime"), row("EndTime"))
                        'ai.RecurrenceRule = ProcLib.CheckNullDBField(row("RecurrenceRule"))
                        'ai.RecurrenceParentID = ProcLib.CheckNullNumField(row("RecurrenceParentID"))
                        ai.ItemColor = row("ItemColor")
                        sessApts.Add(ai)
                    Next
                End Using
                Session("CurrentCalendarID") = CurrentCalendarID
                Session(AppointmentsKey) = sessApts
            End If
            Return sessApts
        End Get
    End Property
    
       
    Protected Sub RadScheduler1_AppointmentDataBound(ByVal sender As Object, ByVal e As SchedulerEventArgs) Handles RadScheduler1.AppointmentDataBound
        
        Dim item As AppointmentInfo = e.Appointment.DataItem
        If CurrentCalendarID = -99 Then   'combine all calendars for this college
            e.Appointment.BackColor = ColorTranslator.FromHtml(item.ItemColor)
            e.Appointment.ForeColor = System.Drawing.Color.LightYellow
            e.Appointment.BorderColor = System.Drawing.Color.DarkGray
            e.Appointment.BorderStyle = BorderStyle.Solid
            e.Appointment.BorderWidth = Unit.Pixel(1)
        End If
        

    End Sub
    
  
    Protected Sub RadScheduler1_FormCreated(ByVal sender As Object, ByVal e As SchedulerFormCreatedEventArgs)
        Dim startDate As RadDatePicker = TryCast(e.Container.FindControl("StartDate"), RadDatePicker)
        If startDate IsNot Nothing Then
            ' advanced form is shown
            startDate.ClientEvents.OnDateSelected = "changeEndDate"
        End If
    End Sub
    
    Protected Sub RadScheduler1_AppointmentInsert(ByVal sender As Object, ByVal e As SchedulerCancelEventArgs) Handles RadScheduler1.AppointmentInsert
        Appointments.Add(New AppointmentInfo(e.Appointment))
        SaveAppointmentsToDatabase()
          
    End Sub
    Protected Sub RadScheduler1_AppointmentUpdate(ByVal sender As Object, ByVal e As AppointmentUpdateEventArgs) Handles RadScheduler1.AppointmentUpdate
        Dim ai As AppointmentInfo = FindById(e.ModifiedAppointment.ID.ToString())
        ai.CopyInfo(e.ModifiedAppointment)
        SaveAppointmentsToDatabase()
    End Sub
    Protected Sub RadScheduler1_AppointmentDelete(ByVal sender As Object, ByVal e As SchedulerCancelEventArgs) Handles RadScheduler1.AppointmentDelete
        Appointments.Remove(FindById(e.Appointment.ID.ToString()))
        SaveAppointmentsToDatabase()
    End Sub
    
    Private Function FindById(ByVal ID As String) As AppointmentInfo
        For Each ai As AppointmentInfo In Appointments
            If ai.ID = ID Then
                Return ai
            End If
        Next
        Return Nothing
    End Function
    
    Private Sub SaveAppointmentsToDatabase()
        
        Using db As New PromptDataHelper
            Dim sql As String = "DELETE FROM CalendarEntries WHERE CalendarID = " & CurrentCalendarID
            db.ExecuteNonQuery(sql)
            
            sql = "SELECT * FROM CalendarEntries "
            db.FillDataTableForUpdate(sql)
            For Each ai As AppointmentInfo In Appointments
                
                Dim newrow As DataRow = db.DataTable.NewRow
                newrow("DistrictID") = HttpContext.Current.Session("DistrictID")
                newrow("CollegeID") = nCollegeID
                newrow("CalendarID") = CurrentCalendarID
                
                newrow("StartTime") = ai.Start
                newrow("EndTime") = ai.End
                newrow("Subject") = ai.Subject
                
                'newrow("RecurrenceRule") = ai.RecurrenceRule
                'newrow("RecurrenceParentID") = ai.RecurrenceParentID


                newrow("LastUpdateBy") = HttpContext.Current.Session("UserName")
                newrow("LastUpdateOn") = Now()

                db.DataTable.Rows.Add(newrow)

               
                
                
            Next
            db.SaveDataTableToDB()

        End Using
        
     
        
    End Sub
    
    '-------------------------- Calendar Entries Class ---------------------------------
    
    Class AppointmentInfo
        Private sid As String
        Private ssubject As String
        Private dstart As DateTime
        Private dend As DateTime
        Private recurParentID As String
        Private sitemColor As String
        Private recurData As String
        Private room As Integer
        Public Property ID() As String
            Get
                Return sid
            End Get
            Set(ByVal value As String)
                sid = value
            End Set
        End Property
        Public Property Subject() As String
            Get
                Return ssubject
            End Get
            Set(ByVal value As String)
                ssubject = value
            End Set
        End Property
        Public Property Start() As DateTime
            Get
                Return dstart
            End Get
            Set(ByVal value As DateTime)
                dstart = value
            End Set
        End Property
        Public Property [End]() As DateTime
            Get
                Return dend
            End Get
            Set(ByVal value As DateTime)
                dend = value
            End Set
        End Property
        Public Property RecurrenceRule() As String
            Get
                Return recurData
            End Get
            Set(ByVal value As String)
                recurData = value
            End Set
        End Property
        Public Property RecurrenceParentID() As String
            Get
                Return recurParentID
            End Get
            Set(ByVal value As String)
                recurParentID = value
            End Set
        End Property
        
        Public Property ItemColor() As String
            Get
                Return sitemColor
            End Get
            Set(ByVal value As String)
                sitemColor = value
            End Set
        End Property
        
        
        Public Property RoomNo() As Integer
            Get
                Return room
            End Get
            Set(ByVal value As Integer)
                room = value
            End Set
        End Property
        Private Sub New()
            Me.ID = Guid.NewGuid().ToString()
        End Sub
        Public Sub New(ByVal subject As String, ByVal start As DateTime, ByVal [end] As DateTime)
            Me.New()
            Me.Subject = subject
            Me.Start = start
            Me.[End] = [end]
        End Sub
        Public Sub New(ByVal source As Appointment)
            Me.New()
            CopyInfo(source)
        End Sub
        Public Sub CopyInfo(ByVal source As Appointment)
            ssubject = source.Subject
            dstart = source.Start
            dend = source.[End]
            recurData = source.RecurrenceRule
            If source.RecurrenceParentID <> Nothing Then
                recurParentID = source.RecurrenceParentID.ToString()
            End If
            'Dim r As Resource = source.Resources.GetResourceByType("Room")
            'If r <> Nothing Then
            '    room = DirectCast(r.Key, Integer)
            'End If
        End Sub
    End Class
    'Class RoomInfo
    '    Private id As Integer
    '    Private name As String
    '    Public ReadOnly Property RoomNo() As Integer
    '        Get
    '            Return id
    '        End Get
    '    End Property
    '    Public ReadOnly Property RoomName() As String
    '        Get
    '            Return name
    '        End Get
    '    End Property
    '    Public Sub New(ByVal id As Integer, ByVal name As String)
    '        Me.id = id
    '        Me.name = name
    '    End Sub
    'End Class
    '-------------------------- End Calendar Entries Class ---------------------------------

</script>

<asp:Content ID="Content1" ContentPlaceHolderID="mainBody" runat="Server">
    <telerik:RadWindowManager ID="contentPopups" runat="server" />
    <telerik:RadMenu ID="RadMenu1" runat="server" Style="z-index: 10;">
        <Items>
            <telerik:RadMenuItem runat="server" Text="Calendars" Value="Calendars">
                <ItemTemplate>
                    <telerik:RadComboBox ID="cboCalendars" runat="server" Label="View:" AutoPostBack="True">
                    </telerik:RadComboBox>
                </ItemTemplate>
            </telerik:RadMenuItem>
        </Items>
    </telerik:RadMenu>
    <div id="contentwrapper">
        <div id="contentcolumn">
            <div id="printdiv" class="innertube">
                <span class="hdprint">Project:
                    <asp:Label ID="lblProjectName" runat="server"></asp:Label></span>
                <telerik:RadScheduler ID="RadScheduler1" runat="server" DataEndField="End" DataKeyField="ID"
                    DataSourceID="" DataStartField="Start" DataSubjectField="Subject">
                </telerik:RadScheduler>
            </div>
        </div>
    </div>
    <telerik:RadAjaxManager ID="RadAjaxManager1" runat="server">
        <AjaxSettings>
            <telerik:AjaxSetting AjaxControlID="RadScheduler1">
                <UpdatedControls>
                    <telerik:AjaxUpdatedControl ControlID="RadScheduler1" LoadingPanelID="RadAjaxLoadingPanel1" />
                </UpdatedControls>
            </telerik:AjaxSetting>
            
                       <telerik:AjaxSetting AjaxControlID="RadMenu1">
                <UpdatedControls>
                    <telerik:AjaxUpdatedControl ControlID="RadScheduler1" LoadingPanelID="RadAjaxLoadingPanel1" />
                    <telerik:AjaxUpdatedControl ControlID="RadMenu1" LoadingPanelID="RadAjaxLoadingPanel1" />
                </UpdatedControls>
            </telerik:AjaxSetting>
            
        </AjaxSettings>
    </telerik:RadAjaxManager>
    <telerik:RadAjaxLoadingPanel ID="RadAjaxLoadingPanel1" runat="server" Height="75px"
        Width="75px" Transparency="25">
        <img alt="Loading..." src='<%= RadAjaxLoadingPanel.GetWebResourceUrl(Page, "Telerik.Web.UI.Skins.Default.Ajax.loading.gif") %>'
            style="border: 0;" />
    </telerik:RadAjaxLoadingPanel>
    <telerik:RadCodeBlock ID="RadCodeBlock1" runat="server">

        <script type="text/javascript" language="javascript">


            function EditEntry(id, view, parentkey) {

                var oWnd = window.radopen("calendar_entry_edit.aspx?EntryID=" + id + "&CurrentView=" + view + "&KeyValue=" + parentkey + "&WinType=RAD", "EditWindow");
                return false;
            }

            function EditCalendar(id, collegeid) {

                var oWnd = window.radopen("calendar_edit.aspx?ID=" + id + "&CollegeID=" + collegeid, "EditWindow");
                return false;
            }

            function GetRadWindow() {
                var oWindow = null;
                if (window.RadWindow) oWindow = window.RadWindow;
                else if (window.frameElement.radWindow) oWindow = window.frameElement.radWindow;
                return oWindow;
            }


            function changeEndDate(sender, e) {
                var endDatePickerID = sender.get_id().replace("StartDate", "EndDate");
                var endDatePicker = $find(endDatePickerID);
                endDatePicker.set_selectedDate(sender.get_selectedDate());
            }
 
                        

        </script>

    </telerik:RadCodeBlock>


</asp:Content>
