<%@ Control Language="vb" %>
<%@ Import Namespace="Prompt" %>

<script runat="server">

    Private Sub Page_Load(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MyBase.Load
       
        'Set Footer Info
        lblYear.Text = Year(Now)
        lblFootLeft.Text = "Logged in as: " & Session("UserName") & " (" & Session("WorkflowRole") & ")"
        lblFootRight.Text = FormatDateTime(Now(), DateFormat.LongDate)
        
        If ProcLib.GetLocale() = "Production" Then
            lblDev.Visible = False
        Else
            lblDev.Text = ProcLib.GetServerFooterID()
            lblDev.Visible = True
        End If
        
                  
        lblVersion.Text = "(v.6.1.0)"
   
    End Sub


</script>

<br />
<asp:Table ID="Table2" runat="server" Width="100%" BorderWidth="1px" BorderStyle="Solid"
    BorderColor="#E0E0E0" BackColor="#0060aa">
    <asp:TableRow Width="100%">
        <asp:TableCell Width="20%" HorizontalAlign="Left">
            <asp:Label ID="lblFootLeft" runat="server" Text="Label" ForeColor="White"></asp:Label>
        </asp:TableCell>
        <asp:TableCell Width="65%" HorizontalAlign="Center">
         
    <asp:Label ID="lblDev" runat="server" Font-Bold="True" Font-Size="Larger" ForeColor="#FF3300">
    -- DEV -- &nbsp;&nbsp;&nbsp;&nbsp;</asp:Label>
    
        
            <span class="style4">Copyright ©
                <asp:Label ID="lblYear" runat="server"></asp:Label>
                EIS Professionals &nbsp;&nbsp;
                <asp:Label ID="lblVersion" runat="server" Font-Bold="False" ForeColor="White" Font-Size="6pt">(Ver)</asp:Label> 
                
                </span>
            <br />
        </asp:TableCell>
        <asp:TableCell Width="15%" HorizontalAlign="Right" Wrap="false">
            <asp:Label ID="lblFootRight" runat="server" Text="Label" ForeColor="White"></asp:Label>
        </asp:TableCell>
    </asp:TableRow>
</asp:Table>
