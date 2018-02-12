<%@ Page Language="VB" MasterPageFile="~/content.master" Title="" %>

<%@ Register Assembly="Telerik.Web.UI" Namespace="Telerik.Web.UI" TagPrefix="telerik" %>
<%@ Import Namespace="Prompt" %>
<script runat="server">
    
    Private bReadOnly As Boolean = True
    Private CurrentView As String = ""
    Private sKeyField As String = ""
    Private nProjectID As Integer = 0
    Private nCollegeID As Integer = 0
    Private nContractID As Integer = 0
    Private nLedgerAccountID As Integer = 0
    Private RecID As Integer = 0
    Private iterates As Boolean
    Private initDate As String
    Private revDate As String
    Private iteration As Integer
    Private maxIteration As Integer
    Private Draft As Integer
    Private nContactID As Integer
    Private userName As String
    Private currentUser As Integer
    Private saveType As String = ""
    Private xUserID As Integer = 0
    
   
    Protected Sub Page_Init(ByVal sender As Object, ByVal e As System.EventArgs)
        nProjectID = Request.QueryString("ProjectID")
        'set security
        Using dbsec As New EISSecurity
            dbsec.ProjectID = nProjectID
            If dbsec.FindUserPermission("Schedules", "write") Then
                bReadOnly = False
            Else
                bReadOnly = True
            End If
        End Using
    End Sub
    
    Private Sub Page_Load(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MyBase.Load

        ProcLib.CheckSession(Page)
        ProcLib.LoadPopupJscript(Page)
        'set up help button
        Session("PageID") = "PEP"
        CurrentView = Request.QueryString("view")
        nProjectID = Request.QueryString("ProjectID")
        nCollegeID = Request.QueryString("CollegeID")
        nContractID = Request.QueryString("ContractID")
        nLedgerAccountID = Request.QueryString("LedgerAccountID")
        
        Dim sContactName As String
        Using db As New RFI
            nContactID = db.getContactID(Session("UserID"), Session("DistrictID"))
            Dim ContactData As Object = db.getContactData(nContactID, Session("DistrictID"))
            Session("ParentContactID") = ContactData(0)
            Session("ContactType") = ContactData(1)
            sContactName = ContactData(2)
        End Using
        
        
        
        Using dbsa As New promptForms
            Dim xLoginID As String = Trim(Session("LoginID"))
            xUserID = dbsa.getUserID(xLoginID)
        End Using
        If nContactID = 0 And HttpContext.Current.Session("UserRole") = "TechSupport" Then
            nContactID = xUserID
        End If
        
        getUserData()
        userName = Session("UserName")
        currentUser = nContactID
        
        '
        lblIterationNoDate.Visible = False
        
        Dim masterTabs As RadTabStrip = Master.FindControl("tabMain")
        Session("CurrentTab") = "Schedules"
        For Each radTab In masterTabs.GetAllTabs
            If radTab.Value = "Schedules" Then
                radTab.Selected = True
                radTab.SelectParents()
                Exit For
            End If
        Next

        
        
        getMaxIteration()
        Session("maxIteration") = maxIteration
        If Not IsPostBack Then
            getDates()
            nIterations.SelectedValue = "        Draft"
            setOnLoad_nIterationsDropdown()
            
        Else
            If maxIteration = 0 Then
                nIterations.SelectedValue = "        Draft"
            End If
            setOnLoad_nIterationsDropdown()
            getInitDate()
        End If

        'lblMessage.Visible = False
        
        
        'David D 9-22-17 added subroutine call below to build iteration dropdown menu
        buildnIterationDropDownMenu()
        
        'Below subroutine checkIfDraft() handles removing of buttons in place of red text. If you comment-out this subroutine then the users can toggle through iterations, and when they "Save Changes" it will only record to the "Draft" you cannot overwrite iterations.
        checkIfDraft()
        getlastSavedDate()
        
        'lblMessage.Style.Add("margin-left","200px")
        'lblMessage.Text = "init date= " & initDate'" iteration= " & iteration & " readOnly=" & bReadOnly '"currentUser=" & currentUser & "  LastUpdateBy=" & Session("LastUpdateBy")  '" iteration= " & iteration & " Session= " & Session("iteration") & " Selected Iteration = " & nIterations.SelectedValue & " Draft = " & Draft & " maxIter= " & maxIteration
    End Sub
    
    Sub getDates()
        Dim sql As String = "Select revdate,iteration From pep Where ProjectID=" & nProjectID & " order by iteration desc"
        'David D 9-22-17 changed sort order to pull the laested revision
        Using db As New PromptDataHelper
            Dim tbl As DataTable = db.ExecuteDataTable(sql)
            If tbl.Rows.Count > 0 Then
                'David D 9-22-17 changed sort order to pull the laested revision
                tbl.DefaultView.Sort = "iteration desc"
                
                If tbl.Rows(0).Item("revdate") = "" Then
                    revDate = "No Revision"
                Else
                    revDate = tbl.Rows(0).Item("revdate")
                End If
                iteration = tbl.Rows(0).Item("iteration")
                Session("iteration") = iteration
                'nIterations.SelectedValue = tbl.Rows(0).Item("iteration")
            End If
        End Using
        getInitDate()
    End Sub
    
    Private Sub getUserData()
        Using dbs As New RFI
            Dim ContactData As Object = dbs.getContactData(nContactID, Session("DistrictID"))
            Session("LastUpdateBy") = ContactData(2)
        End Using

        'Below condition applies to TechSupport since they are not required to be a contact.  This will instead pull the document owner data from the user table
        If Session("LastUpdateBy") = "" Then
            Using dbsx As New promptForms
                Dim UserData As Object = dbsx.getUserNameByUserID(nContactID)
                Session("LastUpdateBy") = UserData(1)
            End Using
        End If
    End Sub
    
    
    Private Sub getlastSavedDate()
        Dim sql As String = "Select LastUpDateOn,revDate From pep Where ProjectID=" & nProjectID & " and iteration=" & iteration
        Using db As New PromptDataHelper
            Dim tbl As DataTable = db.ExecuteDataTable(sql)
            If tbl.Rows.Count > 0 Then
                If IsDBNull(tbl.Rows(0).Item("LastUpDateOn")) = True Then
                    If revDate <> "No Revision" Then
                        lblLastUpDateOn.Text = tbl.Rows(0).Item("revDate")
                        lblLastUpDateOn.Style.Add("color", "#013766")
                        lblLastUpDateOn.Style.Add("margin-right", "125px")
                    Else
                        lblLastUpDateOn.Text = "Not Saved"
                        lblLastUpDateOn.Style.Add("margin-right", "125px")
                        lblLastUpDateOn.Style.Add("color", "red")
                    End If
                Else
                    
                    lblLastUpDateOn.Text = tbl.Rows(0).Item("LastUpdateOn")
                    lblLastUpDateOn.Style.Add("color", "#013766")
                    lblLastUpDateOn.Style.Add("margin-right", "70px")
                End If
            End If
        End Using
        If lblLastUpDateOn.Text = "" Then
            lblLastUpDateOn.Text = "Not Saved"
            lblLastUpDateOn.Style.Add("margin-right", "125px")
            lblLastUpDateOn.Style.Add("color", "red")
        End If
    End Sub
    'Style="float: right; margin-right: 75px; margin-top: -20px; clear: left;"
    
    
    Private Sub setOnLoad_nIterationsDropdown()
        Dim iterationFix As String = nIterations.SelectedValue
        Dim hyphenSplit As String() = iterationFix.Split(" -")
            
        If iterationFix.Contains("Draft") Then
            iteration = 0
            Session("iteration") = 0
            Draft = 0
        Else
            iteration = hyphenSplit(0)
            Session("iteration") = hyphenSplit(0)
        End If
    End Sub
    
    Private Sub buildnIterationDropDownMenu()
        'David D 9-22-17 added code below for iteration dropdown
        If Not IsPostBack Then
            Try
                
                Using db As New PromptDataHelper
                    Dim sql As String = "Select  case when iteration = 0 then '        Draft' else convert(varchar(10),iteration) +' - '+ CONVERT(varchar(10),revdate,120) end as iterationNdate from pep Where ProjectID=" & nProjectID & "order by iteration desc"
                    Dim tbl As DataTable = db.ExecuteDataTable(sql)
                    If tbl.Rows.Count > 0 Then
                        With nIterations
                            .DataValueField = "iterationNdate"
                            .DataTextField = "iterationNdate"
                            .DataSource = tbl
                            .DataBind()
                        End With
                        lblIterationNoDate.Visible = False
                    Else
                        nIterations.Visible = True
                        lblIterationNoDate.Visible = True 'hides behind nIterations dropdown.  Will only show on new projects if dropdown fails to load.
                        lblMessage.Text = lblMessage.Text
                        With nIterations
                            .DataValueField = "iterationNdate"
                            .DataTextField = "iterationNdate"
                            .DataSource = tbl
                            .OnClientLoad = "OnClientLoad"
                            .DataBind()
                        End With
                    End If
                End Using
            Catch ex As Exception
                lblMessage.Text = ex.ToString()
            End Try
        End If
        
        If nIterations.SelectedValue.Contains("Draft") = False Then
            If Not IsPostBack Then
                setImplementationDraft()
            End If
        End If
        
    End Sub
    
    'David D 9-28-17 added setImplementationDraft() to handle inital implementation for old pep code.  This will rebuild the dropdown to include the existing iteration and the draft.
    Private Sub setImplementationDraft()
        Using dbs As New PromptDataHelper
            Dim sql As String = "Select  case when iteration = 0 then '        Draft'  else convert(varchar(10),iteration) +' - '+ CONVERT(varchar(10),revdate,120) end as iterationNdate from pep Where ProjectID=" & nProjectID & "order by iteration desc"
            Dim tbl As DataTable = dbs.ExecuteDataTable(sql)
            With nIterations
                .DataValueField = "iterationNdate"
                .DataTextField = "iterationNdate"
                .DataSource = tbl
                .OnClientLoad = "OnClientLoad"
                .DataBind()
            End With
        End Using
    End Sub
    
    
    Private Sub getInitDate()
        Dim sql As String = "Select top 1 initdate from pep Where ProjectID=" & nProjectID & " and initdate != '' order by iteration desc"
        Using db As New PromptDataHelper
            Dim tbl As DataTable = db.ExecuteDataTable(sql)
            If tbl.Rows.Count > 0 Then
                initDate = tbl.Rows(0).Item("initdate")
            End If
        End Using
    End Sub
    
    Private Sub nIterationsDropdown_Change() Handles nIterations.TextChanged
        Dim iterationFix As String = nIterations.SelectedValue
        Dim hyphenSplit As String() = iterationFix.Split(" -")
        If iterationFix.Contains("Draft") Then
            iteration = 0
            Session("iteration") = 0
            Draft = 0
        Else
            iteration = hyphenSplit(0)
            Session("iteration") = hyphenSplit(0)
        End If
        
        Dim sql As String = "Select revdate, iteration From pep Where ProjectID=" & nProjectID & " and iteration =" & iteration
        Using db As New PromptDataHelper
            Dim tbl As DataTable = db.ExecuteDataTable(sql)
            If tbl.Rows.Count > 0 Then
                If tbl.Rows(0).Item("revdate") = "" Then
                    revDate = "No Revision"
                Else
                    revDate = tbl.Rows(0).Item("revdate")
                End If
                iteration = tbl.Rows(0).Item("iteration")
                Session("iteration") = iteration
            End If
        End Using
    End Sub

    Private Sub checkIfDraft()
        Dim sql As String = "Select min(iteration) as draft From pep Where ProjectID=" & nProjectID
        Using db As New PromptDataHelper
            Dim tbl As DataTable = db.ExecuteDataTable(sql)
            If Draft = IsDBNull(tbl.Rows.Count) Then
                Draft = 0
            ElseIf tbl.Rows.Count > 0 Then
                Draft = tbl.Rows(0).Item("draft")
            Else
                Draft = 0
            End If
        End Using
        
        If iteration <> 0 Then
            ibSave.Visible = False
            ibzSave.Visible = False
            lblMessage.Visible = True
            lblMessage.Style.Add("float", "left")
            'lblMessage.Style.Add("clear", "right")
            lblMessage.Style.Add("margin-top", "1px")
            lblMessage.Style.Add("margin-left", "7px")
            lblMessage.Style.Add("color", "red")
            lblMessage.Style.Add("font-weight", "bold")
            lblMessage.Style.Add("width", "400px")
            lblMessage.Style.Add("line-height", "120%")
            lblMessage.Text = "You are currently viewing iteration (" & iteration & ").  Please select <br>Draft to save changes or record a new iteration"
            
        Else
            ibSave.Visible = True
            ibzSave.Visible = True
            lblMessage.Visible = False
        End If
        
        If bReadOnly = True Then
            ibSave.Visible = False
            ibzSave.Visible = False
            lblMessage.Visible = True
            lblMessage.Style.Add("float", "left")
            lblMessage.Style.Add("margin-top", "1px")
            lblMessage.Style.Add("margin-left", "7px")
            lblMessage.Style.Add("color", "red")
            lblMessage.Style.Add("font-weight", "bold")
            lblMessage.Style.Add("width", "400px")
            lblMessage.Style.Add("line-height", "120%")
            lblMessage.Text = "You are currently viewing iteration (" & iteration & ").  <br>Your user permissions are Read Only."
            lblIterationText.Style.Add("margin-left", "10px")
        End If
    End Sub
    
    Private Sub getMaxIteration()
        Dim sql As String = "Select max(iteration) as maxIteration From pep Where ProjectID=" & nProjectID
        Using db As New PromptDataHelper
            Dim tbl As DataTable = db.ExecuteDataTable(sql)
            Try
                If tbl.Rows.Count > 0 Then
                    maxIteration = tbl.Rows(0).Item("maxIteration")
                End If
            Catch ex As Exception
                maxIteration = 0
            End Try
        End Using
    End Sub
    
    
</script>
<asp:Content ID="Content1" ContentPlaceHolderID="mainBody" runat="Server">
    <telerik:RadWindowManager ID="contentPopup" runat="server" />
    <link id="css" rel="stylesheet" type="text/css" href="scr/pep_maas.css">
    <script type="text/javascript" src="js/pep.js"></script>
    <script type="text/javascript" src="js/tcal.js"></script>
    <style>
        .lblDates
        {
            position: relative;
            display: inline-block;
            line-height: 30px;
            height: 20px;
            vertical-align: middle;
            font-family: Arial;
            font-size: 12px;
            font-weight: bold;
            color: #013766;
            margin-left: 22px;
        }
        .dateWrapper
        {
            position: absolute;
            height: 30px;
            width: 500px;
            right: -300px;
            top: 125px;
            border-style: solid;
            border-width: 0px;
        }
        .dates
        {
            margin-left: 10px;
            border-style: solid;
            border-width: 0px;
            top: 5px;
            line-height: 20px;
            vertical-align: middle;
        }
    </style>
    <input type="hidden" id="iter" value="<%=iteration%>" />
    <input type="hidden" id="maxIter" value="<%=maxIteration%>" />
    <input type="hidden" id="readOnly" value="<%=bReadOnly%>" />
    <input type="hidden" id="revdte" value="<%=revDate%>" />
    <input type="hidden" id="initiationDate" value="<%=initDate%>" />
    <input type="hidden" id="projID" value="<%=nProjectID %>" />
    <div id="contentwrapper">
        <%-- style="scroll-Y:scroll"--%>
    </div>
    <telerik:RadComboBox ID="nIterations" runat="server" Width="105px" Height="100%"
        Style="z-index: 5050;  left: 610px; position: absolute;
        margin-top: 7px;" Skin="Vista" AutoPostBack="true" Visible="true" Enabled="true">
    </telerik:RadComboBox>
    <div id="navrow">
        <a class="printbtn" href="/report_viewer.aspx?ReportID=264&ProjectID=<%=nProjectID%>&RFIID=<%=iteration%>"
            onclick="printSelection(document.getElementById('printdiv'));return false" target="_blank">
            Print</a> <a id="ibSave" runat="server" onclick="processSave('false');" style="background-position: left center;
                padding: 5px 0px 3px 3px; margin-left: 50px; background-image: url(../images/prompt_savetodisk_light.gif);
                background-repeat: no-repeat; text-align: center; width: 111px;">Save Changes</a>
        <a id="ibzSave" runat="server" onclick="processSave('true');" style="background-position: left center;
            padding: 5px 0px 3px 3px; margin-left: 50px; background-image: url(../images/Iteration.gif);
            background-repeat: no-repeat; text-align: center; width: 170px;">Record New Iteration</a>
            
        <asp:Label name="lblMessage" ID="lblMessage" runat="server">
        </asp:Label>
        <a id="lblIterationText" runat="server" style="text-decoration:none;">Iteration No. / Date:</a>
        <asp:Label runat="server" ID="lblIterationNoDate" Style="color: Red; float: right;font-weight: bold;"> New Draft </asp:Label>
    </div>
    <div class="dateWrapper" style="margin-right: 250px;">
        <label class="lblDates">Initiation Date:</label><div id="initDate" class="lblDates dates" style="width: 140px">
                <%=initDate %></div>
        <label class="lblDates" style="display: none;">
            Revision Date:</label><div id="revDate" class="lblDates dates" style="display: none;
                width: 100px">
            </div>
        <label class="lblDates" style="float: right; margin-right: 205px; margin-top: -20px;
            clear: right;">
            Last Saved:</label>
        <asp:Label class="lblDates" runat="server" ID="lblLastUpDateOn" Style="float: right;
            margin-right: 75px; margin-top: -20px; clear: left;"></asp:Label>
        <div id="iterat" class="lblDates dates" style="display: none; width: 25px">
        </div>
    </div>
    <div style="background-position: left center; background-image: url('/blank.gif');
        background-repeat: no-repeat; border-style: solid; border-width: 0px">
    </div>
    <script type="text/javascript" language="javascript">   
 projectId=<%=nProjectID%>
 //David D added global variable maxIter on pep.aspx required to set new iteration value in js file
 var maxIter = <%=maxIteration%>;
 var $readOnly = document.getElementById('readOnly').value;

//    alert("bebe");
    LoadPage();
    //checkCarets();
    
    function OnClientLoad(sender, args) {
        //window.location.reload();//- will reload the page (equal to pressing F5)  
        window.location.href = window.location.href; // - will refresh the page by reloading the URL   
    }
                
    //David D 9-25-17 added below JS Code to set input fields to read only if not in Draft (iteration 0)
            var $iters = Number(<%=iteration%>);
            
            if ($iters === Number(0)) {
            //edit ability in Draft
            }else{
                var lengthIDs = Number(savedfields.length);
                for (var i = 7; i < lengthIDs; i++) {
                    var $it = savedfields[i];
                   //alert($iter);
                   document.getElementById($it).disabled = true;
                }
                }   


    </script>
    <script type="text/javascript">


        function checkCarets() {
            var h = parseInt(("dtitle0").parentNode.style.height);
            if (h > 28) {
                ("dtitle0").className = "gridhdrMinus";
            }
            ("dtitle0").className = "gridhdrPlus";
        }    
    </script>
    <telerik:RadScriptBlock ID="RadScriptlock_Scott" runat="server">
        <!--<script type="text/javascript" src="js/jquery-1.10.2.js"></script>-->
        <script type="text/javascript" language="javascript">
            getValues();

            function processSave(iterate) {
            
                //console.log(iterate);
                if (iterate === 'false') {
                    var msg = 'This action will save your updates to the Draft and update \nthe last saved date, but will not record a new iteration.\n\nDo you wish to continue?';
                } else {
                var iter = <%=maxIteration%>;
                today = makeDate();
                var rev = today;
                        iter = (Number(iter) + 1);
                        
                    var msg = 'This action will record a new iteration "' + iter + ' - ' + rev + '," \nsave your updates to the Draft and update the last saved date.\n\nDo you wish to continue?';
                }

                if (confirm(msg) === true) {
                    if (iterate === 'true') {
                        var iter = <%=maxIteration%>;
                        iter = (Number(iter) + 1);
                        today = makeDate();
                        document.getElementById('iterat').innerHTML = iter;
                        document.getElementById('revDate').innerHTML = today;
                        if ((iter - 1) === 0) {
                            document.getElementById('initDate').innerHTML = today;
                        }
                    }
                    save_Click(iterate)
                    var projid = document.getElementById('projID').value;
                    window.location = location;
                } else {
                /*David D 10-6-17 added else return false for persistence if user clicks cancel on pop-up msg*/
                return false
                
                }
            }
            function post(path) {
                console.log(path);
                var form = document.createElement("form");
                form.setAttribute("method", "post");
                form.setAttribute("action", path);
                document.body.appendChild(form);
                form.submit();
            }
            function makeDate() {
                var today = new Date();
                var dd = today.getDate();
                var mm = today.getMonth() + 1;
                var yyyy = today.getFullYear();
                today = mm + '/' + dd + '/' + yyyy;
                return today
            }
            function getValues() {
                var initDate = document.getElementById('initiationDate').value;
                if (initDate === '') {
                    var today = makeDate();
                    document.getElementById('initDate').innerHTML = 'Not Initiated';
                    document.getElementById('iterat').innerHTML = '0';
                    document.getElementById('revDate').innerHTML = 'No Revision';
                } else {
                    document.getElementById('iterat').innerHTML = Number(document.getElementById('iter').value);
                    document.getElementById('revDate').innerHTML = document.getElementById('revdte').value;
                }
                
            }
            

            
            if ($readOnly === 'False') {
            //edit ability in Draft
            }else{
                var lengthIDs = Number(savedfields.length);
                for (var i = 7; i < lengthIDs; i++) {
                    var $it = savedfields[i];
                   //alert($iter);
                   document.getElementById($it).disabled = true;
                }
                }   
        </script>
    </telerik:RadScriptBlock>
</asp:Content>
