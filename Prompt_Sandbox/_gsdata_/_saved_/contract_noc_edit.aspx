<%@ Page Language="vb" %>
<%@ Register Assembly="Telerik.Web.UI" Namespace="Telerik.Web.UI" TagPrefix="telerik" %>
<%@ Import Namespace="Prompt" %>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">

<script runat="server">
   
    '
    'TODO: Remove extra Javascript at bottom of page (for shared calendar) when next update from telerik which should fix problem
  
    
    Public nContractID As Integer
    Public nProjectID As Integer
    Private Sub Page_Load(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MyBase.Load

        If Session("UserName") = "" Then   'make sure session has not expired
            ProcLib.CloseAndRefresh(Page)
        End If

        ProcLib.LoadPopupJscript(Page)

        'set up help button
        Session("PageID") = "ContractNOCEdit"
        butHelp.Attributes.Add("onclick", "openPopup('help_view.aspx','pophelp',550,450,'yes');")
        butHelp.NavigateUrl = "#"

        nContractID = Request.QueryString("ContractID")
        ViewState.Add("ContractID", nContractID)

        If IsPostBack Then          'only do the following post back
            nContractID = ViewState("ContractID")
        Else                        'only do the following on first load
            
            Using db As New promptContract
                db.CallingPage = Page
                db.GetNOCData(nContractID)   'loads existing  record
          
            End Using
        End If
        
    End Sub
   
 
    Private Sub butSave_Click(ByVal sender As System.Object, ByVal e As System.Web.UI.ImageClickEventArgs) Handles butSave.Click
        
        If IsDate(txtDateRecorded.SelectedDate) Then
            Dim d As Date
            d = txtDateRecorded.SelectedDate
            txtReleaseDate.SelectedDate = DateAdd(DateInterval.Day, 35, d)
        End If

        Using db As New promptContract
            db.CallingPage = Page
            db.SaveNOCData(nContractID)
        End Using

        Session("RtnFromEdit") = True
        ProcLib.CloseAndRefresh(Page)
        
     

    End Sub

  
</script>

<html>
<head>
    <title>Contract NOC Edit</title>
    <meta content="Microsoft Visual Studio .NET 7.1" name="GENERATOR">
    <meta content="Visual Basic .NET 7.1" name="CODE_LANGUAGE">
    <meta content="JavaScript" name="vs_defaultClientScript">
    <meta content="http://schemas.microsoft.com/intellisense/ie5" name="vs_targetSchema">
    <link href="Styles.css" type="text/css" rel="stylesheet">
</head>
   
<body>
    <form id="Form1" method="post" runat="server">
     <telerik:RadScriptManager ID="RadScriptManager1" runat="server" />
    <telerik:RadDatePicker ID="txtBoardApproved" Style="z-index: 100; left: 113px; position: absolute;
        top: 111px" TabIndex="2" runat="server" SharedCalendarID="sharedCalendar" Width="120px" >
        <DateInput  runat="server" Font-Size="13px" ForeColor="Blue">
        </DateInput>
    </telerik:RadDatePicker>
    <telerik:RadDatePicker ID="txtMailedForRecording" runat="server" Style="z-index: 101;
        left: 113px; position: absolute; top: 143px" TabIndex="3" Width="120px" SharedCalendarID="sharedCalendar" >
        <DateInput  runat="server"  Font-Size="13px" ForeColor="Blue">
        </DateInput>
    </telerik:RadDatePicker>
    <div style="display: none">
        <telerik:RadCalendar ID="sharedCalendar" 
            runat="server" EnableMultiSelect="false">
        </telerik:RadCalendar>
    </div>
    <telerik:RadDatePicker ID="txtDateRecorded" runat="server" Style="z-index: 102; left: 112px;
        position: absolute; top: 173px" TabIndex="4" Width="120px" SharedCalendarID="sharedCalendar" >
        <DateInput  runat="server" Font-Size="13px" ForeColor="Blue">
        </DateInput>
    </telerik:RadDatePicker>
    <telerik:RadDatePicker ID="txtReleaseDate" runat="server" Style="z-index: 103; left: 113px;
        position: absolute; top: 239px" TabIndex="6" Width="120px" SharedCalendarID="sharedCalendar" >
        <DateInput  runat="server"  Font-Size="13px" ForeColor="Blue">
        </DateInput>
    </telerik:RadDatePicker>
    <table id="Table1" style="z-index: 117; left: 8px; position: absolute; top: 8px;
        height: 2px" cellspacing="1" cellpadding="1" width="96%" border="0">
        <tr height="1">
            <td style="height: 6px" valign="top">
                <asp:Label ID="Label8" runat="server" Height="24px" CssClass="PageHeading" EnableViewState="False"
                    Width="128px">Edit Contract NOC</asp:Label>
            </td>
            <td style="height: 6px" valign="top" align="right">
                <asp:HyperLink ID="butHelp" runat="server" ImageUrl="images/button_help.gif">HyperLink</asp:HyperLink>
            </td>
        </tr>
    </table>
    <hr style="z-index: 116; left: 8px; position: absolute; top: 40px" width="96%" size="1">
    <asp:Label ID="Label3" Style="z-index: 104; left: 12px; position: absolute; top: 79px"
        runat="server" CssClass="smalltext" Height="16px">Surety:</asp:Label>
    <asp:Label ID="Label4" Style="z-index: 105; left: 12px; position: absolute; top: 54px"
        runat="server" CssClass="smalltext" Height="16px">NOC Date:</asp:Label>
    <asp:Label ID="Label6" Style="z-index: 106; left: 12px; position: absolute; top: 141px"
        runat="server" CssClass="smalltext" Height="16px">Mailed for Rec:</asp:Label>
    <asp:Label ID="Label9" Style="z-index: 107; left: 12px; position: absolute; top: 175px"
        runat="server" CssClass="smalltext">Date Recorded:</asp:Label>
    <asp:Label ID="Label10" Style="z-index: 108; left: 12px; position: absolute; top: 206px"
        runat="server" CssClass="smalltext" Height="16px">Doc Number:</asp:Label>
    <asp:Label ID="Label11" Style="z-index: 109; left: 12px; position: absolute; top: 240px"
        runat="server" CssClass="smalltext" Height="16px">Release Date:</asp:Label>
    <asp:Label ID="Label14" Style="z-index: 110; left: 12px; position: absolute; top: 110px"
        runat="server" CssClass="smalltext" Height="16px">Board Approved:</asp:Label>
    <asp:TextBox ID="txtDocNumber" Style="z-index: 111; left: 113px; position: absolute;
        top: 206px" runat="server" Width="75px" TabIndex="5" CssClass="EditDataDisplay"></asp:TextBox>
    <asp:DropDownList ID="lstSurety" Style="z-index: 112; left: 112px; position: absolute;
        top: 81px" runat="server" Width="208px" CssClass="EditDataDisplay" TabIndex="1">
    </asp:DropDownList>
    &nbsp;
    <telerik:RadDatePicker ID="txtNOCDate" Style="z-index: 113; left: 113px; position: absolute;
        top: 51px" runat="server" Width="120px" SharedCalendarID="sharedCalendar">
        <DateInput  runat="server"  Font-Size="13px" ForeColor="Blue">
        </DateInput>
    </telerik:RadDatePicker>
    &nbsp;
    <asp:ImageButton ID="butSave" Style="z-index: 114; left: 14px; position: absolute;
        top: 293px" runat="server" ImageUrl="images/button_save.gif" TabIndex="7"></asp:ImageButton>
    &nbsp;&nbsp;
    <asp:Label ID="Label1" runat="server" CssClass="smalltext" Style="z-index: 118; left: 249px;
        position: absolute; top: 241px" Text="(Leave Blank to automatically calculate as 35 days from DateRecorded when record is saved.)"
        Width="267px"></asp:Label>
        
        
    <script type="text/javascript" language="javascript">
        //temp code for q3 2009 release bug in shared calendars
        if (typeof (Telerik) != "undefined" && typeof (Telerik.Web.UI.Calendar) != "undefined") {
            Telerik.Web.UI.Calendar.Popup.prototype.Hide = function(updateData) {
                var div = this.DomElement;
                var styleObj = RadHelperUtils.GetStyleObj(div);

                if (div)
                    $telerik.$(div).stop(true, true);

                var thisObj = this;
                removeDiv = function() {
                    if (div) {
                        if (navigator.userAgent.match(/Safari/)) {
                            styleObj.visibility = "hidden";
                            styleObj.position = "absolute";
                            styleObj.left = "-1000px";
                        }
                        else {
                            styleObj.display = "none";
                        }

                        styleObj = null;

                        if (div.childNodes.length != 0) {
                            if (navigator.userAgent.match(/Safari/)) {
                                div.childNodes[0].style.visibility = "hidden";
                                div.childNodes[0].style.position = "absolute";
                                div.childNodes[0].style.left = "-1000px";
                            }
                            else {
                                div.childNodes[0].style.display = "none";
                            }
                        }

                        var innerElement = div.childNodes[0];
                        if (innerElement != null) {
                            div.removeChild(innerElement);

                            if (thisObj.Parent != null) {
                                thisObj.Parent.appendChild(innerElement);
                            }
                            else if (thisObj.Sibling != null) {
                                var parentElement = thisObj.Sibling.parentNode;
                                if (parentElement != null)
                                    parentElement.insertBefore(innerElement, thisObj.Sibling);
                            }

                            if (navigator.userAgent.match(/Safari/)) {
                                RadHelperUtils.GetStyleObj(innerElement).visibility = "hidden";
                                RadHelperUtils.GetStyleObj(innerElement).position = "absolute";
                                RadHelperUtils.GetStyleObj(innerElement).left = "-1000px";
                            }
                            else {
                                RadHelperUtils.GetStyleObj(innerElement).display = "none";
                            }
                        }
                        //IFRAME code
                        RadHelperUtils.ProcessIframe(div, false);
                    }
                }

                if (div && typeof (this.HideAnimationDuration) == "number" && this.HideAnimationDuration > 0)
                    $telerik.$(div).fadeOut(this.HideAnimationDuration, removeDiv);
                else
                    removeDiv();

                if (this.OnClickFunc != null) {
                    RadHelperUtils.DetachEventListener(document, "click", this.OnClickFunc);
                    this.OnClickFunc = null;
                }
                if (this.OnKeyPressFunc != null) {
                    RadHelperUtils.DetachEventListener(document, "keydown", this.OnKeyPressFunc);
                    this.OnKeyPressFunc = null;
                }

                if (updateData && this.ExitFunc) {
                    this.ExitFunc();
                }
            }
        }
 
    </script>
        
        
        
    </form>
</body>
</html>
