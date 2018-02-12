<%@ Page Language="VB" %>
<%@ Import Namespace="Prompt" %>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">

<script runat="server">
    'called by scripts located in D:\ScheduledScripts on production server for daily tasks
    
    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs)
        'Using notify As New promptWorkflowTransfer
        '    notify.ImportFRSPONumbersLineItemsFile()
        'End Using
        'Exit Sub
        
             
        If Request.QueryString("key") <> "_XDrr09732255XvC" Then     'random key to pass with page for added security
            Response.Write("keyFalied")
            Exit Sub
        End If
                
        'Select Case Request.UserHostAddress                         'get the calling page host address and if not valid exit
            
            'Case "localHost"     'only allow Prompt Production, Beta or local to run
                                  
                Select Case Request.QueryString("task")
                        
                    Case "ImportFRSTables"
                        Using db As New promptWorkflowTransfer
                            db.CallingPage = Page
                            db.ImportFRSCheckMessageCodes()         'get the FRS check message codes and import 
                            db.ImportFRSVendorFile()                'get the FRS Vendor File and import 
                            db.ImportFRSAccountNumbersFile()          'get the FRS Account Numbers file and import
                            db.ImportFRSPONumbersFile()               'get the FRS PONumbers file and import
                            db.ImportFRSPONumbersLineItemsFile()
  
                        End Using
                
                    Case "ImportFRSDisbursements"
                        Using db As New promptWorkflowTransfer
                            db.CallingPage = Page
                            db.ImportFRSPaymentDisbursements()     'process nightly FRS disbursements 
                        End Using
                        
                        
                    Case "NotifyUsersOfFRSDisbursementsImportErrors"
                        'Notify all the appropriate workflow owners if errors
                        Using notify As New promptEmailNotify
                            notify.NotifyWorkflowOwnersOfFRSTransferErrors()
                        End Using
                        
                    Case "NotifyUsersOfNewInboxItems"
                        'Notify all the appropriate workflow owners if errors
                        Using notify As New promptEmailNotify
                            notify.NotifyUsersOfNewInboxItems(True)    'if true flag then copy sent to tech as well
                        End Using
                        
                    Case "NotifyFHDAOfContractExpiration"
                        Using notify As New promptEmailNotify
                            notify.FHDAContractAndInsuranceExpirationNotify()
                        End Using
                       
                    Case Else
                        Response.Write("taskFailed")
                
                End Select
            
            
            'Case Else       'not from this IP so exit
                'Response.Write("IPFalied")
                Exit Sub
        'End Select
    End Sub
</script>

<html xmlns="http://www.w3.org/1999/xhtml" >
<head runat="server">
    <title>Untitled Page</title>
</head>
<body>
    <form id="form1" runat="server">
    <div>
    
    </div>
    </form>
</body>
</html>
