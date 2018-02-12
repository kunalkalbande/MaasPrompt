function printSelection(node){
var content=node.innerHTML
var pwin=window.open('','print_content');
pwin.document.open();
pwin.document.write('<html><head><link rel="stylesheet" type="text/css" href="print.css" /></head><body onload="window.print()"><div class="printpage">'+content+'</div></body></html>');
pwin.document.close();
setTimeout(function(){pwin.close();},15000);
}