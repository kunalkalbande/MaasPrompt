"use strict";


function tryThis() {
    var ans = document.getElementById('txtAnswer').value;
    //alert(ans);


    ans = 'This is a replacement of one value to another';
    //document.getElementById('txtAnswer').value = ans;

    getData();

}
function getData() {

    $.getJSON('RFI/jqTest', '{}', function (data) {
        document.getElementById('txtAnswer').value = data;
        alert('here  ' + data)
    });

    document.getElementById('txtAnswer').value = 'change up';
}
