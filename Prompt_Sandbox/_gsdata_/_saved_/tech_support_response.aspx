<%@ Page Language="vb" %>

<%@ Import Namespace="Prompt" %>
<%@ Register Assembly="Telerik.Web.UI" Namespace="Telerik.Web.UI" TagPrefix="telerik" %>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">

<script runat="Server">


    Protected Sub butClose_Click(ByVal sender As Object, ByVal e As System.Web.UI.ImageClickEventArgs)
        If Session("HelpCalledFrom") = "Dashboard" Then
            'Add Jscript to close the window and update the grid.
            Dim jscript As New StringBuilder
            With jscript
                .Append("<script language='javascript'>")
                .Append("CloseHelp();")
                .Append("</" & "script>")
            End With
            ClientScript.RegisterStartupScript(GetType(String), "CloseHelp", jscript.ToString)
        Else
            ProcLib.CloseOnly(Page)
        End If
       
        
        
    End Sub
</script>

<html>
<head>
    <title>Prompt - Tech Support Response</title>
    <meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">
    <style type="text/css">
        <!
        -- .style1
        {
            font-family: Verdana, Arial, Helvetica, sans-serif;
        }
        .style3
        {
            font-family: Verdana, Arial, Helvetica, sans-serif;
            font-size: 12px;
        }
        body
        {
            background-color: #FFFFCC;
        }
        -- ></style>
</head>
<body>
<form id="Form1" method="post" runat="server">
     <telerik:RadScriptManager ID="RadScriptManager1" runat="server" />
    <table width="383" border="0" align="left">
        <tr>
            <td width="377">
                <div align="center" class="style1">
                    Prompt Technical Support
                </div>
            </td>
        </tr>
        <tr>
            <td height="21">
                <span class="style3"></span>
            </td>
        </tr>
        <tr>
            <td height="61">
                <span class="style3">Thank you for your inquiry. We will contact you with a response
                    as soon as possible. </span>
            </td>
        </tr>
    </table>
    <asp:ImageButton ID="butClose" runat="server" ImageUrl="images/button_close.gif"
        Style="z-index: 105; left: 148px; position: absolute; top: 145px; height: 23px;"
        TabIndex="6" OnClick="butClose_Click" />
    <telerik:radwindowmanager id="MasterPopups" runat="server">
        </telerik:radwindowmanager>

    <script type="text/javascript">

        function GetRadWindow1() {
            var oWindow = null;
            if (window.radWindow) oWindow = window.radWindow; //Will work in Moz in all cases, including clasic dialog
            else if (window.frameElement.radWindow) oWindow = window.frameElement.radWindow; //IE (and Moz az well)

            return oWindow;
        }

        function CloseHelp() {
            GetRadWindow1().Close();
        }
    </script>

    </form>
</body>
</html>
