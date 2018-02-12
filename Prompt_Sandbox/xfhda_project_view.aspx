<%@ Page Language="vb" %>

<%@ Import Namespace="System.IO" %>
<%@ Import Namespace="System.Data" %>
<%@ Import Namespace="System.Configuration" %>
<%@ Import Namespace="System.Web.UI.WebControls" %>
<%@ Import Namespace="Prompt" %>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">


<script runat="Server">


    Private Sub Page_Load(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MyBase.Load

        Dim nProjectID As Integer = Request.QueryString("ProjectID")
        Dim strPhase As String = Request.QueryString("Phase")
        Dim nPhotoID As Integer

        Dim nCollegeID As Integer = 0
        Dim nDistrictID As Integer = 0
        Dim strProjectTitle As String = ""
        Dim strDescription As String = ""
        Dim strFundingSource As String = ""
        Dim strFundingDescription As String = ""
        Dim strCurrentProjectCost As String = ""
        Dim strPercentComplete As String = ""
        Dim strEstCompleteDate As String = ""
        Dim strPercentImage As String = ""
        Dim strLastUpdateOn As String = ""

        Session("DistrictID") = 55
        
        Using db As New PromptDataHelper
            Dim tbl As DataTable = db.GetFilteredParentAndUDFDataAsSingleRow("Projects", "ProjectID", "ProjectID", Request.QueryString("ProjectID"))
            For Each rproject In tbl.Rows   'should be only one

                nProjectID = rproject("ProjectID")
                nCollegeID = rproject("CollegeID")
                nDistrictID = rproject("DistrictID")

                strProjectTitle = ProcLib.CheckNullDBField(rproject("bondDisplayTitle"))
                strDescription = ProcLib.CheckNullDBField(rproject("udf_bondProjectDescription"))
                strFundingSource = ProcLib.CheckNullDBField(rproject("udf_bondFundingSource"))
                strCurrentProjectCost = ProcLib.CheckNullDBField(rproject("udf_bondProjectBudget"))
               
                strPercentComplete = ProcLib.CheckNullDBField(rproject("udf_bondPercentComplete"))
                 
                strEstCompleteDate = ProcLib.CheckNullDBField(rproject("udf_bondEstComplete"))
                strLastUpdateOn = FormatDateTime(rproject("LastUpdateOn"), DateFormat.ShortDate)
       
            Next
               
            Dim sql As String = "SELECT dbo.Colleges.College, LTRIM((CASE WHEN UsePromptName = 0 THEN dbo.Projects.ProjectTitle ELSE dbo.Projects.ProjectName END)) AS Title, "
            sql &= "dbo.Projects.UsePromptName, dbo.Projects.ProjectName, dbo.Projects.ProjectTitle, dbo.Projects.AppriseDescription, dbo.Projects.UsePromptDescr, "
            sql &= "dbo.Projects.FundingSource, dbo.Projects.FundingDescription, dbo.Projects.CurrentProjectCost, dbo.Projects.PercentComplete, dbo.Projects.PublishToWeb, "
            sql &= "dbo.Projects.Description AS ProjectsDescription, dbo.Projects.LastUpdateOn AS AppriseLastUpdate, dbo.Projects.LastUpdateOn AS ProjectsLastUpdate, "
            sql &= "dbo.Projects.ProjectID, dbo.Projects.Status, dbo.Projects.CollegeID, dbo.Projects.DistrictID, dbo.Projects.UsePromptCompletionDate, "
            sql &= "dbo.Projects.HideCompletionDate, dbo.Projects.EstCompleteDate AS PromptEstCompleteDate, dbo.Projects.ProjectNumber, dbo.Projects.OrigBudget AS ProjectBudget,"
            sql &= "dbo.Projects.StartDate, dbo.Projects.HidePercentComplete, dbo.Projects.UsePromptBudget,dbo.Projects.UseManualBudgetAmount , dbo.Projects.ProjectGroupID ,"
            
            sql &= "(SELECT ISNULL(SUM(Amount), 0) AS TotAmount FROM dbo.BudgetItems WHERE BudgetField LIKE '%Bond%' AND ProjectID = Projects.ProjectID) AS ProjectBondTotal "
            sql &= "FROM dbo.Projects INNER JOIN dbo.Colleges ON dbo.Projects.CollegeID = dbo.Colleges.CollegeID "
            sql &= "WHERE dbo.Projects.PublishToWeb = 1 AND Projects.ProjectID = " & nProjectID & " "
            sql &= "ORDER BY dbo.Projects.Status, Title"
                        
            Dim rs1 As DataTable = db.ExecuteDataTable(sql)
            Dim col As DataColumn = New DataColumn("PromptBondTotal", System.Type.GetType("System.Double"))
            rs1.Columns.Add(col)
            
            'Now go through to see if the project is part of a project group and if so, then consolodate the bond amount from all the group projects
            For Each rrow As DataRow In rs1.Rows
                If ProcLib.CheckNullNumField(rrow("ProjectGroupID")) > 0 Then
                    sql = "SELECT ISNULL(SUM(dbo.BudgetItems.Amount), 0) AS TotAmount "
                    sql &= "FROM dbo.BudgetItems INNER JOIN dbo.Projects ON dbo.BudgetItems.ProjectID = dbo.Projects.ProjectID "
                    sql &= "WHERE dbo.Projects.ProjectGroupID = 18 AND dbo.BudgetItems.BudgetField LIKE '%Bond%' "
                    rrow("PromptBondTotal") = db.ExecuteScalar(sql)
                Else
                    rrow("PromptBondTotal") = rrow("ProjectBondTotal")
                End If
                strCurrentProjectCost = FormatCurrency(rrow("PromptBondTotal")) 
            Next
        End Using
        
        projTitle.Text = strProjectTitle
        projDescription.InnerHtml = strDescription
        projBudget.InnerText = strCurrentProjectCost
        projFundingSource.InnerText = strFundingSource
        projLastUpdated.InnerText = strLastUpdateOn
        
        
        Dim sProjName As String = ""
        Dim sAppriseDescription As String = ""
        Dim inner As String = ""
        
        
        Using pdh As New PromptDataHelper
            'sProjName = pdh.ExecuteScalar("Select ProjectName from Projects Where ProjectID = " & nProjectID)
            Dim projRow As DataRow
            projRow = pdh.GetDataRow("Select ProjectName, AppriseDescription, ProjectTitle From Projects Where ProjectID = " & nProjectID)
            sAppriseDescription = projRow("AppriseDescription")
        End Using
        theTitle.InnerHtml = sProjName
        
        
        'Get all photos
        Using rs As New PromptDataHelper
            rs.FillReader("SELECT * FROM ApprisePhotos WHERE ProjectID = " & nProjectID & " ORDER BY DisplayOrder")
            Dim strTitle As String
            Try
                Dim i As Integer = 0
                While rs.Reader.Read()
                    i = i + 1
                    nPhotoID = rs.Reader("ApprisePhotoID")
                    nCollegeID = rs.Reader("CollegeID")
                    nDistrictID = rs.Reader("DistrictID")
                    strTitle = ProcLib.CheckNullDBField(rs.Reader("Title"))
                    strDescription = ProcLib.CheckNullDBField(rs.Reader("Description"))
                    
                    
                    inner += "<div class=""slide""><img src=""" + ProcLib.GetCurrentRelativeAttachmentPath() + "DistrictID_55/_apprisedocs/_photos/ProjectID_" + CStr(nProjectID) + "/" + CStr(nPhotoID) + ".jpg"""
                    'inner += "<div class=""slide""><img src=""PromptAttachments/DistrictID_55/_apprisedocs/_photos/ProjectID_" + CStr(nProjectID) + "/" + CStr(nPhotoID) + ".jpg"""
                    inner += " width=""500"" height=""375"" alt=""" + strTitle + """>"
                    inner += "<div class=""caption"" style=""bottom:0""> <p>" + strTitle + "</p></div>"
                    inner += "</div>" + vbCrLf
                End While
            Catch ex As Exception
                'lblDescription.Text = "Database Error: " & ex.Message
            End Try
            rs.Reader.Close()
            rs.Close()
        End Using

        insertPhotos.InnerHtml = vbCrLf + inner

    End Sub

</script>

<html>
<head>
	<meta charset="utf-8">
	<title runat="server" id="theTitle">Placeholder</title>
	<script src="https://ajax.googleapis.com/ajax/libs/jquery/1.5.1/jquery.min.js"></script>
	<script src="js/slides.jquery.js"></script>
	<script>
	    $(function() {
	        $('#slides').slides({
	            preload: true,
	            preloadImage: 'images/loading.gif',
	            play: 4000,
	            pause: 2500,
	            hoverPause: true,
	            animationStart: function(current) {
	                $('.caption').animate({
	                    bottom: -35
	                }, 100);
	                if (window.console && console.log) {
	                    // example return of current slide number
	                    console.log('animationStart on slide: ', current);
	                };
	            },
	            animationComplete: function(current) {
	                $('.caption').animate({
	                    bottom: 0
	                }, 200);
	                if (window.console && console.log) {
	                    // example return of current slide number
	                    console.log('animationComplete on slide: ', current);
	                };
	            },
	            slidesLoaded: function() {
	                $('.caption').animate({
	                    bottom: 0
	                }, 200);
	            }
	        });
	    });
	</script>
<style type='text/css'>
body{font-family:Arial, Helvetica, sans-serif;}
.MainProjectTitle{font-weight:bold;color:#326127;}
a{color: #000;}

/* 
	Resets default browser settings
	reset.css

html,body,div,span,applet,object,iframe,h1,h2,h3,h4,h5,h6,p,blockquote,pre,a,abbr,acronym,address,big,cite,code,del,dfn,em,font,img,ins,kbd,q,s,samp,small,strike,strong,sub,sup,tt,var,dl,dt,dd,ol,ul,li,fieldset,form,label,legend,table,caption,tbody,tfoot,thead,tr,th,td { margin:0; padding:0; border:0; outline:0; font-weight:inherit; font-style:inherit; font-size:100%; font-family:inherit; vertical-align:baseline; }
:focus { outline:0; }
a:active { outline:none; }
body { line-height:1; color:black; background:white; }
ol,ul { list-style:none; }
table { border-collapse:separate; border-spacing:0; }
caption,th,td { text-align:left; font-weight:normal; }
blockquote:before,blockquote:after,q:before,q:after { content:""; }
blockquote,q { quotes:"" ""; }
*/
/*
	Page style

body { 
	font:normal 62.5%/1.5 Helvetica, Arial, sans-serif;
	letter-spacing:0;
	color:#434343;
	background:#efefef url(../img/background.png) repeat top center;
	padding:20px 0;
	position:relative;
	text-shadow:0 1px 0 rgba(255,255,255,.8);
	-webkit-font-smoothing: subpixel-antialiased;
}
*/
#container {
	width:580px;
	padding:10px;
	margin:0 auto;
	position:relative;
	z-index:0;
}

#example {
	width:600px;
	height:350px;
	position:relative;
}

#ribbon {
	position:absolute;
	top:-3px;
	left:-15px;
	z-index:500;
}

#frame {
	position:absolute;
	z-index:0;
	width:739px;
	height:341px;
	top:-3px;
	left:-80px;
}

/*
	Slideshow
*/

#slides {
	position:absolute;
	top:15px;
	left:4px;
	z-index:100;
}

/*
	Slides container
	Important:
	Set the width of your slides container
	Set to display none, prevents content flash
*/

.slides_container {
	width:570px;
	overflow:hidden;
	position:relative;
	display:none;
}

/*
	Each slide
	Important:
	Set the width of your slides
	If height not specified height will be set by the slide content
	Set to display block
*/

.slides_container div.slide {
	width:600px;
	height:370px;
	display:block;
}


/*
	Next/prev buttons
*/

#slides .next,#slides .prev {
	position:absolute;
	top:107px;
	left:-24px;
	width:24px;
	height:43px;
	display:block;
	z-index:101;
}

#slides .next {
	left:500px;
}

/*
	Pagination
*/

.pagination {
	margin:26px auto 0;
	width:100px;
}

.pagination li {
	float:left;
	margin:0 1px;
	list-style:none;
}

.pagination li a {
	display:block;
	width:12px;
	height:0;
	padding-top:12px;
	background-image:url(../img/pagination.png);
	background-position:0 0;
	float:left;
	overflow:hidden;
}

.pagination li.current a {
	background-position:0 -12px;
}

/*
	Caption
*/

.caption {
	z-index:500;
	position:absolute;
	bottom:-5px;
	left:0;
	height:30px;
	padding:5px 20px 0 20px;
	background:#000;
	background:rgba(0,0,0,.5);
	width:460px;
	color:#fff;
	border-top:1px solid #000;
	text-shadow:none;
}

.caption p{margin:0;padding:0;}

#footer {
	text-align:center;
	width:580px;
	margin-top:9px;
	padding:4.5px 0 18px;
	border-top:1px solid #dfdfdf;
}

#footer p {
	margin:4.5px 0;
}

</style>
</head>
<body>
    <form id="formx" runat="server">
    
        <table cellspacing="5">
        <tr colspan="2"><asp:Label runat="server" ID="projTitle" class="MainProjectTitle" Height="20" Width="100%">Placeholder for Project Title</asp:Label></tr>
        <tr colspan="2"><div runat="server" id="projDescription" class="MainProjectDescription">Placeholder for Project Description</div></tr>
        <tr>
            <td><div class="ProjectDataLabel">Project Budget:</div></td>
            <td><div runat="server" id="projBudget" class="ProjectDataValue">100,000</div></td>
        </tr>
        <tr>
            <td><div class="ProjectDataLabel">Project Funding Source:</div></td>
            <td><div runat="server" id="projFundingSource"  class="ProjectDataValue">yyy</div></td>
        </tr>
        <tr>
            <td><div class="ProjectDataLabel">Last Update On:</div></td>
            <td><div runat="server" id="projLastUpdated"  class="ProjectDataValue">xxx</div></td>
        </tr>
        </table>
	    <div id="container">
		    <div id="example">
			    <div id="slides">
				    <div id="insertPhotos" runat="server" class="slides_container">

				    </div>
    				<a href="#" class="prev"><img src="images/arrow-prev.png" width="24" height="43" alt="Arrow Prev"></a>
				    <a href="#" class="next"><img src="images/arrow-next.png" width="24" height="43" alt="Arrow Next"></a>
			    </div>
		    </div>
	    </div>
	</form>
</body>
</html>
