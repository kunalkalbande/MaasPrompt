<%@ Page Language="vb" %>

<%@ Import Namespace="Prompt" %>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">

<script runat="server">

    Private RecordType As String = ""
    Private message As String = ""
    Private RecID As Integer

    Private Sub Page_Load(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MyBase.Load

        Session("PageID") = "DeleteRecord"

        RecordType = Request.QueryString("RecordType")
        RecID = Request.QueryString("ID")

        If Not IsPostBack Then
            Using db As New DeleteHelper
                db.CallingPage = Page
                message = db.CheckDependantsForDelete(RecordType, RecID)
                If message = "" Then   'go ahead and delete
                    db.DeleteRecord(RecordType, RecID)
                    Proclib.CloseAndRefresh(Page)
                Else
                    If message = "Are you sure you want to delete this record?" Then   'user may continue at own risk
                        butDelete.Visible = True
                    Else
                        butDelete.Visible = False     'user has no choice based on message
                    End If
                    lblMessage.Text = message
                End If
            End Using
        End If
    End Sub
  

    Protected Sub butCancel_Click(ByVal sender As Object, ByVal e As System.Web.UI.ImageClickEventArgs)
        Proclib.CloseAndRefresh(Page)
    End Sub

    Protected Sub butDelete_Click(ByVal sender As Object, ByVal e As System.Web.UI.ImageClickEventArgs)
        Using db As New DeleteHelper
            db.CallingPage = Page
            db.DeleteRecord(RecordType, RecID)
            Proclib.CloseAndRefresh(Page)
        End Using
    End Sub
    
       
</script>

<html>
<head>
    <title>Delete Record</title>
    <meta name="GENERATOR" content="Microsoft Visual Studio .NET 7.1">
    <meta name="CODE_LANGUAGE" content="Visual Basic .NET 7.1">
    <meta name="vs_defaultClientScript" content="JavaScript">
    <meta name="vs_targetSchema" content="http://schemas.microsoft.com/intellisense/ie5">
    <link rel="stylesheet" type="text/css" href="http://localhost/Prompt/Styles.css">
</head>
<body>
    <form id="Form1" method="post" runat="server">
        <table width="98%">
            <tr>
                <td>
                 <br />
                    <br />
                    <asp:Label ID="lblMessage" runat="server" CssClass="ViewDataDisplay" Font-Bold="True"
                        ForeColor="Red">message
                    </asp:Label>
                    <br />
                    <br />
                </td>
            </tr>
            <tr>
                <td><br />
                    <asp:ImageButton ID="butDelete" runat="server" ImageUrl="images/button_delete.gif"
                        TabIndex="41" OnClick="butDelete_Click" />
                    &nbsp; &nbsp;&nbsp;&nbsp; &nbsp;&nbsp;&nbsp; &nbsp;&nbsp;&nbsp;
                    <asp:ImageButton ID="butCancel" runat="server" ImageUrl="images/button_close.gif"
                        TabIndex="41" OnClick="butCancel_Click" />
                </td>
            </tr>
        </table>
    </form>
</body>
</html>
