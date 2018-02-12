<%@ Page Language="vb" %>

<%@ Register Assembly="Telerik.Web.UI" Namespace="Telerik.Web.UI" TagPrefix="telerik" %>
<%@ Import Namespace="Prompt" %>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">

<script runat="server">

    Private Sub Page_Load(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MyBase.Load

        Session("PageID") = "CMDMNotesEdit"

        ProcLib.LoadPopupJscript(Page)

        If Not IsPostBack() Then
            Using db As New PromptDataHelper
                db.CallingPage = Page
                txtCMDMNotes.Text = ProcLib.CheckNullDBField(db.ExecuteScalar("SELECT CMDMNotes FROM Districts WHERE DistrictID = " & Session("DistrictID")))
 
            End Using
        End If


    End Sub
     
    Private Sub butSave_Click(ByVal sender As System.Object, ByVal e As System.Web.UI.ImageClickEventArgs) Handles butSave.Click
  
        Using db As New PromptDataHelper
            db.ExecuteNonQuery("UPDATE Districts SET CMDMNotes = '" & txtCMDMNotes.Text & "' WHERE DistrictID = " & Session("DistrictID"))
        End Using

        ProcLib.CloseAndRefreshRADNoPrompt(Page)
        Session("RtnFromEdit") = True
        
        
    End Sub

 
</script>

<html>
<head>
    <title>CMDM District Notes Edit</title>
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
    
    <table id="Table2"  cellspacing="1" cellpadding="1" width="96%" border="0">
        <tr>
            <td valign="top">
                <asp:Textbox ID="txtCMDMNotes" Width="98%" Height="300px" runat="server" TextMode="MultiLine">
                </asp:Textbox>
            </td>
        </tr>
        <tr>
            <td valign="middle" height="6">
                <asp:ImageButton ID="butSave" TabIndex="40" runat="server" ImageUrl="images/button_save.gif" >
                </asp:ImageButton>
                
             </td>
        </tr>
    </table>
 
    </form>
</body>
</html>
