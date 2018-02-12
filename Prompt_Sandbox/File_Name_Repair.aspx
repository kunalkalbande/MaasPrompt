<%@ Page Language="vb" %>
<%@ Register Assembly="Telerik.Web.UI" Namespace="Telerik.Web.UI" TagPrefix="telerik" %>
<%@ Import Namespace="Prompt" %>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">

<%@ Import Namespace="Prompt" %>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">

<script runat="server">

    Private currentDistrictID As Integer
    Private currentCollegeID As Integer
    Private currentProjectID As Integer
    Private zList As DataTable
    
    Private Sub Page_Load(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MyBase.Load    
        
        butScanner.Visible = False
        Dim sname As String = Request.ServerVariables("SERVER_NAME")
        lblserver.Text = sname
        
        Using db As New FileRename
 
            Dim str As String = ""
            
            Dim zList As DataTable = db.getDistinctRepairPaths(55)
            
            For Each row As DataRow In zList.Rows
                Try
                    str = str & row.Item("FilePath").ToString() & "<br/>"
                Catch ex As Exception
                    str = "Nothing Found"
                End Try
            Next
            
        End Using
        
        Try
            currentDistrictID = cboDistrictID.SelectedValue
        Catch ex As Exception
            Using db As New FileRename
                zList = db.getDistinctDistricts()
                currentDistrictID = zList.Rows(0).Item("DistrictID")
            End Using
        End Try
        
        Try
            currentCollegeID = cboCollegeID.SelectedValue
        Catch ex As Exception
            Using db As New FileRename
                zList = db.getDistinctColleges(currentDistrictID)
                currentCollegeID = zList.Rows(0).Item("CollegeID")
            End Using
        End Try
        Try
            currentProjectID = cboProjectID.SelectedValue
        Catch ex As Exception
            Using db As New FileRename
                zList = db.getCollegeProjects(currentDistrictID, currentCollegeID)
                currentProjectID = zList.Rows(0).Item("ProjectID")
            End Using
        End Try
        
        If Not IsPostBack Then
            Using db As New FileRename
                
                With cboDistrictID
                    .DataValueField = "DistrictID"
                    .DataTextField = "DistrictID"
                    .DataSource = db.getDistinctDistricts()
                    .DataBind()
                End With
                
                With cboCollegeID
                    .DataValueField = "CollegeID"
                    .DataTextField = "CollegeID"
                    .DataSource = db.getDistinctColleges(currentDistrictID)
                    .DataBind()
                End With
                
                With cboProjectID
                    .DataValueField = "ProjectID"
                    .DataTextField = "ProjectID"
                    .DataSource = db.getCollegeProjects(currentDistrictID, currentCollegeID)
                    .DataBind()
                End With
                
                With cboFiles
                    .DataValueField = "FileName"
                    .DataTextField = "FileName"
                    .DataSource = db.getDistinctCollegeDirectories(currentDistrictID, currentCollegeID)
                    .DataBind()
                End With
                
            End Using
            scanDirectories()
        End If
        
    End Sub
    
    Private Sub DistrictID_change() Handles cboDistrictID.SelectedIndexChanged
        
        Using db As New FileRename
            With cboFiles
                .DataValueField = "FileName"
                .DataTextField = "FileName"
                .DataSource = db.getDistinctCollegeDirectories(currentDistrictID, 99)
                .DataBind()
            End With
            
            With cboCollegeID
                .DataValueField = "CollegeID"
                .DataTextField = "CollegeID"
                .DataSource = db.getDistinctColleges(currentDistrictID)
                .DataBind()
            End With
            
            zList = db.getDistinctColleges(currentDistrictID)
            currentCollegeID = zList.Rows(0).Item("CollegeID")
            
            With cboProjectID
                .DataValueField = "ProjectID"
                .DataTextField = "ProjectID"
                .DataSource = db.getCollegeProjects(currentDistrictID, currentCollegeID)
                .DataBind()
            End With
 
            zList = db.getCollegeProjects(currentDistrictID, currentCollegeID)
            currentProjectID = zList.Rows(0).Item("ProjectID")
            
            With cboFiles
                .DataValueField = "FileName"
                .DataTextField = "FileName"
                '.DataSource = db.getDistinctCollegeDirectories(currentDistrictID, currentCollegeID)
                .DataSource = db.getProjectFiles(currentDistrictID, currentCollegeID, currentProjectID)
                .DataBind()
            End With
            
        End Using
        scanDirectories()
    End Sub
    
    Private Sub CollegeID_change() Handles cboCollegeID.SelectedIndexChanged
        
        Using db As New FileRename
            With cboFiles
                .DataValueField = "FileName"
                .DataTextField = "FileName"
                .DataSource = db.getDistinctCollegeDirectories(currentDistrictID, currentCollegeID)
                .DataBind()
            End With
            
            zList = db.getCollegeProjects(currentDistrictID, currentCollegeID)
            currentProjectID = zList.Rows(0).Item("ProjectID")
                       
            With cboProjectID
                .DataValueField = "ProjectID"
                .DataTextField = "ProjectID"
                .DataSource = db.getCollegeProjects(currentDistrictID, currentCollegeID)
                .DataBind()
            End With
            
            With cboFiles
                .DataValueField = "FileName"
                .DataTextField = "FileName"
                '.DataSource = db.getDistinctCollegeDirectories(currentDistrictID, currentCollegeID)
                .DataSource = db.getProjectFiles(currentDistrictID, currentCollegeID, currentProjectID)
                .DataBind()
            End With
            
        End Using
        scanDirectories()
    End Sub
    
    Private Sub ProjectID_change() Handles cboProjectID.SelectedIndexChanged
        Using db As New FileRename
            With cboFiles
                .DataValueField = "FileName"
                .DataTextField = "FileName"
                '.DataSource = db.getDistinctCollegeDirectories(currentDistrictID, currentCollegeID)
                .DataSource = db.getProjectFiles(currentDistrictID, currentCollegeID, currentProjectID)
                .DataBind()
            End With
                  
        End Using
        scanDirectories()
    End Sub
    
    Private Sub butScanner_click() Handles butScanner.Click
      
        scanDirectories()
        
    End Sub
    
    Public Sub scanDirectories()
        Dim list As ArrayList
        Using db As New FileRename
            Dim str As String = ""
            list = db.checkIfFileExists(currentDistrictID, currentCollegeID, currentProjectID)
            'For Each row As DataRow In list.rows
            'str &= list.Item(row)
            'Nextst
            For i = 0 To list.Count - 1
                str &= list(i) & "<br/>"
            Next
            lblDisplay.Text = str
        End Using
    End Sub
    
</script>

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title></title>
</head>
<body>
    <div id="MainDiv">
    <form id="Form1" method="post" runat="server">
     <telerik:RadScriptManager ID="RadScriptManager1" runat="server" />

    <asp:Label ID="pageCaption" Style="left: 10px; position: absolute; top: 10px; font-size:18px"
        runat="server" Height="100px" Width="800">
        Stop: This page is for prompt attachment administration file name repairing. Not using this page correctly can effect the ability of prompt
        users to locate documents critical to perform their jobs. If you don't know what your doing, exit this module now.
    </asp:Label>

    <asp:Label ID="lblserver" Style="left: 850px; position: absolute; top: 10px; font-size:18px"
        runat="server" Height="30px" Width="100">
    </asp:Label>

    <asp:Label ID="lblDistrictID" Style="left: 10px; position: absolute; top: 100px"
        runat="server" Height="30px">District ID:</asp:Label>

     <telerik:RadComboBox ID="cboDistrictID" runat="server" Style="z-index: 505; left: 100px;
        position: absolute; top: 98px;" Skin="Vista"  TabIndex="7" AutoPostBack="true" Visible="True">
    </telerik:RadComboBox>

    <asp:Label ID="lblCollegeID" Style="left: 280px; position: absolute; top: 100px"
        runat="server" Height="30px">College ID:</asp:Label>

     <telerik:RadComboBox ID="cboCollegeID" runat="server" Style="z-index: 505; left: 360px;
        position: absolute; top: 98px;" Skin="Vista"  TabIndex="7" AutoPostBack="true" Visible="True">
    </telerik:RadComboBox>

    <asp:Label ID="lblProjectID" Style="left:530px; position: absolute; top: 100px"
        runat="server" Height="30px">Project ID:</asp:Label>

     <telerik:RadComboBox ID="cboProjectID" runat="server" Style="z-index: 505; left:610px;
        position: absolute; top: 98px;" Skin="Vista"  TabIndex="7" AutoPostBack="true" Visible="True">
    </telerik:RadComboBox>

     <asp:ImageButton ID="butScanner" Style="z-index: 90; left: 800px; position: absolute;
        top: 98px" TabIndex="100" runat="server" ImageUrl="images/button_save.gif">
    </asp:ImageButton>

    <asp:Label ID="Label1" Style="left: 43px; position: absolute; top: 150px"
        runat="server" Height="30px">Files:</asp:Label>

     <telerik:RadComboBox ID="cboFiles" runat="server" Style="z-index: 10; left: 100px;
        position: absolute; top: 148px;" Skin="Vista"  TabIndex="7" AutoPostBack="true" Visible="True" Width="500">
    </telerik:RadComboBox>



    <asp:Label ID="lblDisplay" Style="left: 10px; position: absolute; top: 200px"
        runat="server" Height="30px">here</asp:Label>



    </form>
    </div>
</body>
</html>
