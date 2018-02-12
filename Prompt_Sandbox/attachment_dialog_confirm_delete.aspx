<%@ Page Language="VB" %>
<%@ Import Namespace="Prompt" %>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">

<script runat="server">
    Private recid As Integer = 0
    Private ParentRecType As String = ""
    Private ParentRecID As String = ""
    Private Action As String = ""
    
    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs)
        recid = Val(Request.QueryString("recid"))
        ParentRecType = Request.QueryString("ParentType")
        ParentRecID = Request.QueryString("ParentRecID")
        
        If Request.QueryString("Unlink") = 1 Then
            Action = "Unlink"
            lblMessage.Text = "Are you sure you want to unlink this Attachment?"
        Else
            Action = "Delete"
            lblMessage.Text = "Are you sure you want to Delete this File?"
        End If
        
        
    End Sub
    
 
    Protected Sub butYes_Click(ByVal sender As Object, ByVal e As System.EventArgs)
        Using db As New promptAttachment
            db.CallingPage = Page
            If Action = "Unlink" Then
                db.UnlinkAttachment(recid, ParentRecType, ParentRecID)
            Else
                db.DeleteLinkedAttachment(recid, ParentRecType)
            End If
            
        End Using
        Response.Redirect("attachments_manage_linked.aspx?ParentRecID=" & ParentRecID & "&ParentType=" & ParentRecType)
    End Sub

    Protected Sub butNo_Click(ByVal sender As Object, ByVal e As System.EventArgs)
        Response.Redirect("attachments_manage_linked.aspx?ParentRecID=" & ParentRecID & "&ParentType=" & ParentRecType)
    End Sub
</script>

<html xmlns="http://www.w3.org/1999/xhtml" >
<head runat="server">
    <title>Confirm Delete</title>
    <link href="Styles.css" rel="stylesheet" type="text/css" />
 </head>
<body>
    <form id="form1" runat="server">

    <div>
        <asp:Label ID="lblMessage" runat="server" Font-Bold="True" Font-Size="10px" Style="z-index: 100;
            left: 43px; position: absolute; top: 25px" TabIndex="10" Text="Are you sure you want to Delete this file?"></asp:Label>
        <asp:Button ID="butYes" runat="server" OnClick="butYes_Click" Style="z-index: 101;
            left: 38px; position: absolute; top: 60px" TabIndex="5" Text="Yes" Width="64px" />
        <asp:Button ID="butNo" runat="server" Style="z-index: 103; left: 152px; position: absolute;
            top: 60px" Text="No" Width="66px" OnClick="butNo_Click" />
    
    </div>

    </form>
    
 
    
</body>
</html>
