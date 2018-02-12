
var ActionArray={};
var clndArray={
"pcc":{"line":"0","start":"0","stop":"0","cls":"7"},
"pcd":{"line":"1","start":"0","stop":"0","cls":"7"},
"rrd":{"line":"2","start":"0","stop":"0","cls":"7"},
"pv":{"line":"3","start":"0","stop":"0","cls":"1"},
"sd":{"line":"4","start":"0","stop":"0","cls":"2"},
"dd":{"line":"5","start":"0","stop":"0","cls":"2"},
"cd":{"line":"6","start":"0","stop":"0","cls":"2"},
"dsa":{"line":"7","start":"0","stop":"0","cls":"3"},
"pc":{"line":"8","start":"0","stop":"0","cls":"4"},
"gmp":{"line":"9","start":"0","stop":"0","cls":"4"},
"c":{"line":"10","start":"0","stop":"0","cls":"5"},
"ffe":{"line":"11","start":"0","stop":"0","cls":"6"},
"o":{"line":"12","start":"0","stop":"0","cls":"6"},
"co":{"line":"13","start":"0","stop":"0","cls":"6"}
};
var savedfields = ["campus","revdate","initdate","iteration","prjname","prjnumber","pribudget","pccs","pcds","rrds","pvs","sds","dds","cds","dsas","pcs","cs","ffes","os","cos","pccp","pcdp","rrdp","gmps","pvp","sdp","ddp","cdp","dsap","pcp","cp","ffep","op","cop","gmpp","aor","aorco","cm","cmco","ior","xtra1","xtra2","xtra3","xtra4","xtra5","aorsc","aorcosc","cmsc","cmscco","iorsc","xtras1","xtras2","xtras3","xtras4","xtras5","aord","aorcod","cmd","cmdco","iord","xtrad1","xtrad2","xtrad3","xtrad4","xtrad5","xtrat0","xtrat1","xtrat2","xtrat3","xtrat4","xtrat5","xtrat6","xtrat7", "xtrat8", "xtrat9","notes", "po1", "po2", "po3", "po4", "po5", "po6", "po7", "po8", "po9", "po10"];//,"aort","aorcot","cmt","cmtco","iort"


var toolbarZindex=5000;
var extra=0;
//var editLabel=0;
var colzero;
var savedData={};
function LoadPage() {

// panel=JSON.parse(LoadData('./scr/pep.htm'));

 drawPage();
 
}
function $(v) { return(document.getElementById(v)); }
function $S(v) { return($(v).style); }
function sleep(milliseconds) {
                var start = new Date().getTime();
                for (var i = 0; i < 1e7; i++) {
                    if ((new Date().getTime() - start) > milliseconds){
                        break;
                    }
                }
            }

function $(v) { return(document.getElementById(v)); }
function $S(v) { return($(v).style); }



function redrawPage() {
 wx=document.compatMode=='CSS1Compat' && !window.opera?document.documentElement.clientWidth:document.body.clientWidth;
 wy=document.compatMode=='CSS1Compat' && !window.opera?document.documentElement.clientHeight:document.body.clientHeight;


}
/*********************************************************************************************************
 **********               LoadData() - AJAX GET data loader                                     **********
 *********************************************************************************************************/
function LoadData(Filehref)
{
var textfile='';
  try {textfile=new ActiveXObject('Msxml2.XMLHTTP');}
  catch (e)
  {
    try {textfile=new ActiveXObject('Microsoft.XMLHTTP');}
    catch (e)
    {
      try {textfile=new XMLHttpRequest();}
      catch (e)
      {return "<p>error</p>";}
    }
  }
textfile.open('GET', Filehref, false);
textfile.send(null);
return textfile.responseText;
}
/*********************************************************************************************************
 **********               POSTData() - AJAX POST data loader                                     **********
 *********************************************************************************************************/
function POSTData(Filehref,param)
{
var textfile='';
  try {textfile=new ActiveXObject('Msxml2.XMLHTTP');}
  catch (e)
  {
    try {textfile=new ActiveXObject('Microsoft.XMLHTTP');}
    catch (e)
    {
      try {textfile=new XMLHttpRequest();}
      catch (e)
      {
        return "<p>error</p>";
      }
    }
  }
textfile.open('POST', Filehref, false);
textfile.setRequestHeader("Content-Type", "application/x-www-form-urlencoded");
//textfile.setRequestHeader("Content-length", param.length);
//textfile.setRequestHeader("Connection", "close");

textfile.send(param);
return textfile.responseText;
}

/*********************************************************************************************************
 **********     getFront(where,what) getEnd(where,what) - substring parsing functions           **********
 *********************************************************************************************************/
function getFront(mainStr, searchStr)
{
  foundOffset = mainStr.indexOf(searchStr);
  if (foundOffset == -1) {
  foundOffset=mainStr.indexOf('"');
    if (foundOffset == 0) {
    mainStr=mainStr.substring(1,mainStr.length);}
  foundOffset=mainStr.indexOf("'");
    if (foundOffset == 0) {
    mainStr=mainStr.substring(1,mainStr.length);}
    return mainStr;
}
  work=mainStr.substring(0,foundOffset);
  foundOffset=work.indexOf('"');
    if (foundOffset == 0) {
    work=work.substring(1,work.length);}
  foundOffset=work.indexOf("'");
    if (foundOffset == 0) {
    work=work.substring(1,work.length);}
return work;
}
function getEnd(mainStr,searchStr)
{
  foundOffset = mainStr.indexOf(searchStr);
   if (foundOffset == -1) {
     return "";
   }
  return mainStr.substring(foundOffset+searchStr.length, mainStr.length);
}

/*********************************************************************************************************
 **********     actionList                                                                      **********
 *********************************************************************************************************/
function actionList() {
//	alert (alist);
	var ascript="function defineActionList() { ";
var alist=[{"function":"swapToBud"},{"function":"swapToCal"}];
	for (var i=0; i<alist.length;i++) {
	//	console.log(alist[i].function+"="+alist[i].function+"; ");
	ascript	+="ActionArray."+alist[i].function+"="+alist[i].function+"; " ;
	}
ascript	+= " }";
//alert (ascript);

var ns = document.createElement("script");
    ns.type = "text/javascript";
    ns.text = ascript;
    document.getElementsByTagName('head')[0].appendChild(ns);
    defineActionList();
}

/*********************************************************************************************************
 **********      newDiv                                                                         **********
 *********************************************************************************************************/

 function newDiv (parentid,id,x,y,w,h,disp,brd,cls,pos,target) {
 	           var divBlock=document.createElement('DIV');
 if (id==0)    divBlock.id=parentid+currentObject;
 else          divBlock.id=id;
 		   	   divBlock.style.position=pos;
 		   	   divBlock.style.overflow="hidden";
		       divBlock.style.zIndex=++toolbarZindex;
if (x>=0)	   divBlock.style.left=x;
else           divBlock.style.right=-x;
 			   divBlock.style.top=y;
if (w!=0)  	   divBlock.style.width=w;

if (h!=0)  			   divBlock.style.height=h;
if (disp!=0)   divBlock.style.display=disp;
if (brd!=0)    divBlock.style.border=brd;

if (cls!=0)    divBlock.className=cls;
if (id=="dtitle0"||id=="dtitle1"||id=="dtitle2"||id=="data0_calt")  divBlock.className="gridhdrMinus";

if(!target)    document.getElementsByTagName("body")[0].appendChild(divBlock);
else           $(target).appendChild(divBlock);
}



/*********************************************************************************************************
 **********                                                                                     **********
 *********************************************************************************************************/
function drawPage() {
//    alert (projectId);
	actionList();
//	  console.log(ActionArray);
//    alert ("**");
//    redrawPage();
       
    panel=JSON.parse(LoadData('scr/pep.htm'));
    
//    console.log(panel);
//    wx=960;
    wx=document.compatMode=='CSS1Compat' && !window.opera?document.documentElement.clientWidth:document.body.clientWidth;
    wy=document.compatMode=='CSS1Compat' && !window.opera?document.documentElement.clientHeight:document.body.clientHeight;
//    newDiv(0,"header",0,120,wx,160,0,"solid 1px",0,"absolute","contentwrapper");
    newDiv(0,"ptitle",0,120,wx,24,0,"#fcc solid 1px","pep_ttl","absolute","contentwrapper");
    $("ptitle").innerHTML=panel.header.title;
//    $S("ptitle").textAlign="center";
    
//    newDiv(0,"savebtn",wx-70,2,60,16,0,0,"picbtn","absolute","ptitle");
//    $("savebtn").innerHTML="Save..."
//    $S("savebtn").background="#9c9";
//	  $S("savebtn").color="#339";
//	  $S("savebtn").padding="3px";
//	  $("savebtn").onclick=function() {
//		  savePep();
//		  }


    newDiv(0,"stitle",0,146,wx,24,0,"#fcc solid 1px","gridhdr","absolute","contentwrapper");
    $("stitle").innerHTML=panel.header.section.title;
    if (panel.header.section.button) var bl=panel.header.section.button.length;
    else bl="";
//    console.log(bl);

//			}
    if (bl>0) {
		for (i=0; i<bl; i++) {
			newDiv(0,"hbutton"+i,wx-40*i-50,1,panel.header.section.button[i].w,24,0,0,"picbtn","absolute","stitle");
			$S("hbutton"+i).background="url(img/"+panel.header.section.button[i].img+") top left no-repeat";
			$S("hbutton"+i).number=i;
//            $("hbutton"+i).onclick=function() {
//                ActionArray[panel.header.section.button[this.style.number].action]();
//		 	  }
            $S("hbutton"+i).display="none";
		}
	}
    // Now populate columns...
    for (i=0; i<panel.header.section.columns.length; i++) {
//        console.log (panel.header.section.columns[1].lines.length);

		var cw=parseInt(wx/panel.header.section.columns.length)-2;
		newDiv(0,"hcol"+i,i*cw+2,180,cw,110,0,0,0,"absolute","contentwrapper");

        for (j=0;j<panel.header.section.columns[i].lines.length; j++) {
			newDiv(0,"hline"+i+"_"+j,20,4,cw-40,24,0,0,0,"relative","hcol"+i);
			newDiv (0,"hline"+i+"_"+j+"lbl",0,0,(cw-40)/2,24,0,0,"hlbl","absolute","hline"+i+"_"+j);
            $("hline"+i+"_"+j+"lbl").innerHTML=panel.header.section.columns[i].lines[j].label+":&nbsp;";
			newDiv (0,"hline"+i+"_"+j+"fld",(cw-40)/2+1,0,(cw-40)/2,24,0,0,0,"absolute","hline"+i+"_"+j);
			if (panel.header.section.columns[i].lines[j].type=="calendar") {
			    $("hline"+i+"_"+j+"fld").innerHTML='<input class="tcal" type=text id="'+panel.header.section.columns[i].lines[j].datafield+'" value="" style="border:none;border-bottom:#bbb solid 1px;width:'+((cw-40)/2-4)+'px;height:20px;cursor:pointer;" onChange="checkDate('+ panel.header.section.columns[i].lines[j].datafield + ')"  />';
                $S("hline"+i+"_"+j+"fld").onclick=function() {markDate(this); };
		    }
			if (panel.header.section.columns[i].lines[j].type=="text") {
			 $("hline"+i+"_"+j+"fld").innerHTML='<input type=text id="'+panel.header.section.columns[i].lines[j].datafield+'" value="" style="border:none;border-bottom:#bbb solid 1px;width:'+((cw-40)/2-4)+'px;height:20px;cursor:pointer;" />';
			}
        }
    }
//    newDiv(0,"data",0,300,wx,900,0,"solid 1px",0,"absolute","contentwrapper");
    newDiv(0,"data",0,160,wx,1310,0,"solid 1px",0,"absolute","contentwrapper");
//    $S("data0").overflowY="scroll";
    //for each section...
	for (i=0; i<panel.body.section.length; i++) {
        var sech=0;
		newDiv(0,"data"+i,0,0,wx,"auto",0,0,0,"relative","data");
        newDiv(0,"dtitle"+i,0,0,wx,24,0,0,"gridhdr","relative","data"+i);
        sech=24;
        $("dtitle"+i).innerHTML=panel.body.section[i].title;
        $("dtitle"+i).onclick=function() { 
            hideShow(this);
            }
        $S("dtitle"+i).cursor="pointer";
//        console.log(panel.body.section[i].columns);
        fillColTitle(panel.body.section[i], "dtitle"+i);
        var colsize=[];
//        console.log("number of columns=",panel.body.section[i].columns.length);
  	    if (panel.body.section[i].columns.length>0 && panel.body.section[i].columns[0].w) {
 	        var cw=parseInt((wx-panel.body.section[i].columns[0].w)/(panel.body.section[i].columns.length-1));
            var shift=panel.body.section[i].columns[0].w;
//            console.log("shift="+shift);
	    }
 	    else {
            cw=wx/(panel.body.section[i].columns.length);
 	        shift=cw;
        }
        if (i==0) {
            colzero=shift;
        }
        //for each column in this section...
        for (var ii=0; ii<panel.body.section[i].columns.length;ii++) {
		    colsize[ii]=cw;
	    }

        colsize[0]=parseInt(shift);
//        console.log(colsize);
        shift=0;

        //for each column in this section...
        for (var ii=0; ii<panel.body.section[i].columns.length;ii++) {
		    
            var ch=44;
            
            //create column container
		    newDiv(0,"data"+i+"_col"+ii,shift,28,colsize[ii]-2,"auto",0,0,0,"absolute","data"+i);
		    $S("data"+i+"_col"+ii).borderRight="#ccc solid 1px";

		    shift=shift+colsize[ii];

            //this may be redundant to the For condition above!!
            //if columns exist
            if ("columns" in panel.body.section[i] && panel.body.section[i].columns.length>0) {

//                console.log("section="+i, " columns="+panel.body.section[i].columns.length);

                var swt=("labels" in panel.body.section[i].columns[0]);
            }
            //this logic may be wrong!!
            //section without titles(labels)
            else {
                swt=false;
            }

            //section with titles(labels)?
            if (swt) {
                            
                //For in line 251 controls i
                //for each element/cell in column 0 of the current section
                //OTHER COLUMNS CAN COME IN HERE!!
				for (var k=0; k<panel.body.section[i].columns[0].labels.length; k++){
                    ch=ch+24;

                    //i=section
                    //ii=column
                    //k=element/cell

                    //create the label div
                    newDiv (0,"data"+i+"_col"+ii+"l"+k,0,0,"100%",20,0,0,"cell","relative","data"+i+"_col"+ii);

					  
                    //if first column
                    if (ii==0) {
                        //********************************************************************************************************************************************
                        //********************************************************************************************************************************************
                        //building this for each section, handling making all labels editable in data1 regardless of whether its label is Other or not****************
                        //********************************************************************************************************************************************
                        //********************************************************************************************************************************************
                        //-=if second section (data1) 
                        if (i==1) {
                            //this is the editable labels

//							id="'+panel.body.section[i].columns[ii].values[k].datafield+'" value=""
//							panel.body.section[1].columns[0].values[0].datafield

                            var label=panel.body.section[i].columns[0].labels[k].label;
                            
                        
//							var dataField=panel.body.section[i].columns[0].labels[k].datafield;
                            var id=("data"+i+"_col"+ii+"l"+k);
//console.log(id);
                            //if label is not equal to "Other"
//							if (label !="Other") {
								//create textbox
							$(id).innerHTML='<input type="text" id="xtrat'+extra+'" value="" placeholder="'+label+'" style="border:none;border-bottom:#bbb solid 1px;width:'+$S("pvs").width+'px;height:20px;cursor:pointer;padding-top:1px;" />';
						//	$S(dataField).width="96%";
                            $S("xtrat"+extra).width="96%";

//								editLabel++;
//							}
							//if label IS "Other" (extra)
//							else {
								//this structure is for the labels that were already editable (textboxes)
								//create textbox
//								$(id).innerHTML='<input type="text" id="xtrat'+extra+'" value="" placeholder="Other" style="border:none;border-bottom:#bbb solid 1px;width:'+$S("pvs").width+'px;height:20px;cursor:pointer;padding-top:1px;" />';
//								$S("xtrat"+extra).width="96%";
	//                            $S("data"+i+"_col"+ii+"l"+k).background="#fafafa";

								//Other is 0 through 4
								//xtra is 1 through 5
								extra++;

//							}

                        }

                        //if section is data0
                        else if (i==0) {
                            //The only superscripts exist in data0

                            var label=panel.body.section[i].columns[0].labels[k];

                            //Change asterisks into superscripts for notes
                            if (label.indexOf('**') > -1) {
                                $("data"+i+"_col"+ii+"l"+k).innerHTML=label.replace("**","<sup>2</sup>");
                            }
                            else if (label.indexOf('*') > -1) {
                                $("data"+i+"_col"+ii+"l"+k).innerHTML=label.replace("*","<sup>1</sup>");
                            }
                            //no asterisks exist in label
                            //still need to assign label to cell
                            else {
                                $("data"+i+"_col"+ii+"l"+k).innerHTML=label;
                            } 
                        }
                        //all other sections
                        //if section is not data0 or data1
                        //still need to assign label to cell
                        else {
                            $("data"+i+"_col"+ii+"l"+k).innerHTML=panel.body.section[i].columns[0].labels[k];
                        }

                
                    }
                    //this is for 'body' columns
                    else {
//                        console.log("values=",panel.body.section[i].columns[ii].values[k]);
                        $S("data"+i+"_col"+ii+"l"+k).textAlign="center";
                        //if this is a calendar column
                        if (panel.body.section[i].columns[ii].values[k].type=="calendar") {
						    //add calendar input to this div
                            $("data"+i+"_col"+ii+"l"+k).innerHTML='<input class="tcal" type=text id="'+panel.body.section[i].columns[ii].values[k].datafield+'" value="" style="border:none;border-bottom:#bbb solid 1px;width:'+((cw-40)/2-4)+'px;height:20px;cursor:pointer;" onChange="checkDate(this.value,this.id)" />';
	                    }
                        //if this is a text column
                        if (panel.body.section[i].columns[ii].values[k].type=="text") {
//                            console.log ("Log",panel.body.section [i].columns[ii].values[k]);
                            //add text input to this div
						    $("data"+i+"_col"+ii+"l"+k).innerHTML='<input type=text id="'+panel.body.section[i].columns[ii].values[k].datafield+'" value="" style="border:none;border-bottom:#bbb solid 1px;width:'+((cw-40)/2-4)+'px;height:20px;cursor:pointer;background:#fefefe;" />';
					    }
                        $S("data"+i+"_col"+ii+"l"+k).background="#fcfcfc";
                    }					
	            }
			}
        }
        //this is only for notes
        //if no columns in this section
        if	(panel.body.section[i].columns.length==0)	{

//            console.log ("section "+i+"   "+ii);
            //create column container
			newDiv(0,"data"+i+"_col"+ii,shift,28,wx-2,60,0,0,0,"absolute","data"+i);
            //add text input to this div
			$("data"+i+"_col"+ii).innerHTML="<textarea style='height:60px;width:100%;background:#fefefe;' id='notes'></textarea>";
        }
//        alert ("data"+i+"_col"+ii+'\n'+swt+'\n'+ch+'\n'+"len="+panel.body.section[i].columns[0].labels.length);


		$S("data"+i).height=ch;

    }//next section
    
    //calblock does not exist in scr/pep.htm
    //build calblock
	newDiv(0,"data0_calblock",0,0,wx,"auto",0,0,0,"relative","data");
	$S("data0_calblock").height=parseInt($S("data0").height)+(1*30);

    $S("data0_calblock").overflowX="scroll";
	newDiv(0,"data0_calt",0,0,1732,25,0,0,"gridhdr","absolute","data0_calblock");
    $("data0_calt").innerHTML="SCHEDULE (CHART)";
    $("data0_calt").onclick=function() { 
        hideShow(this);
        }
    $S("data0_calt").cursor="pointer";
	newDiv(0,"data0_calhdr",colzero,0,1512,30,0,0,"calttl","absolute","data0_calt");
	for (var mm=0;mm<7;mm++) {
		newDiv(0,"data0_calyear"+mm,0,30,216,30,0,0,"calttl","relative","data0_calhdr");
        $S("data0_calyear"+mm).top=0;
        $S("data0_calyear"+mm).background="url(img/months3.png) bottom left no-repeat";
        $("data0_calyear"+mm).innerHTML=(2016+parseInt(mm));
	}
	newDiv(0,"data0_calttls",0,30,colzero,350,0,0,0,"absolute","data0_calblock");
    //*************************************************************
	var noSup=$("data0_col0").innerHTML.replace("<sup>1</sup>","");
	noSup=noSup.replace("<sup>2</sup>","");
	
//	$("data0_calttls").innerHTML=$("data0_col0").innerHTML;
	$("data0_calttls").innerHTML=noSup;
	//*************************************************************

	newDiv(0,"data0_calendar",colzero,30,1512,350,0,0,"calbox","absolute","data0_calblock");
//    $S("data0_calendar").overflowX="scroll";
    $S("data0_calendar").background="url(img/calbg.png)";
//    $("data0_calendar").innerHTML="bebebe";
//    $S("data0_calendar").display="none";
    $S("stitle").display="none";
    $S("hcol0").display="none";
    $S("hcol1").display="none";

//	newDiv(0,"savebtn",wx-70,2,60,16,0,0,"picbtn","absolute","ptitle");dtitle0
//	$("savebtn").innerHTML="Save..."
//	$S("savebtn").background="#9c9";
//	$S("savebtn").color="#339";
//	$S("savebtn").padding="3px";
//	$("savebtn").onclick=function() {
//		savePep();
//		}
    $S("data2").height=90;
//    $("notes").value='* PV = Programing Validation\n** PC = Pre-Construction';
//    $S("data1").display="none";
//    $S("data2").display="none";
    var noteplace=parseInt($S("data0").height);
    $S("data0").height=parseInt($S("data0").height)+60;
    newDiv(0,"calnotes",5,noteplace,"100%",60,"block",0,0,"absolute","data0");
//    $S("calnotes").top=null;
//    $S("calnotes").bottom=2;
    $S("calnotes").color="#013766";
    $S("calnotes").fontStyle="italic";
    $("calnotes").innerHTML="Notes:<br><sup>1</sup>Includes solicitation preparation, bidding documents, bidding period/review, BOT contract approval & execution<br><sup>2</sup>Includes Back-punch, NOC, and DSA Financial close-out";
//    $S("xtrab").padding=2;
//    $("xtrab").innerHTML="More...";
//    $S("xtrab").cursor="pointer";
//    $("xtrab").onclick=function(){ 
//        addXtraItem();
//        }
//    alert (colzero)


//    noteplace=parseInt($S("data1").height);
//    $S("data1").height=parseInt($S("data1").height)+60;
//    newDiv(0,"calnotes2",5,noteplace,"100%",60,"block",0,0,"absolute","data1");
//    $S("calnotes2").color="#013766";
//    $S("calnotes2").fontStyle="italic";
//    $("calnotes2").innerHTML="Notes:<br><sup>3</sup>PV = Programming Validation<br><sup>4</sup>PC = Pre-Construction";

    // New Calendar Legend
    //*********************
    var legplace=parseInt($S("data0_calblock").height);
    $S("data0_calblock").height=parseInt($S("data0_calblock").height)+60;
    newDiv(0,"calLegend",5,legplace,"100%",60,"block",0,"calLegend","absolute","data0_calblock");

    $("calLegend").innerHTML="<b>Legend:</b><label style='background-color: #ff3399;'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</label>Pre-Progamming<label style='background-color: #e16b09; margin-left: 20px;'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</label>Programming<label style='background-color: #00afef;'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</label>Design<label style='background-color: #953634;'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</label>Agency Processing (DSA)<label style='background-color: #ffc000;'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</label>Pre-Construction<label style='background-color: #333399;'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</label>Construction<label style='background-color: #92d050;'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</label>Close-Out";



	f_tcalInit ();
	swapToCal();
	loadCalendar();

setPersistance();

}//end of drawPage()

/*********************************************************************************************************
 **********                                                                                     **********
 *********************************************************************************************************/
 // if iterate is true, the iteration will be advanced and the revdate will be updated.
function save_Click(iterate) {
    var iter = document.getElementById('iteration').innerHTML;
    savePep(iterate);
}
//**************************
//**************************
function hideShow(obj) {
//alert (obj.parentNode.id);
var h=parseInt(obj.parentNode.style.height);
if (h>30) {
//   alert ("_");

    if (obj.id=="data0_calt") {
        if (h>48) {
            obj.style.parh=obj.parentNode.style.height;
            
            obj.parentNode.style.height=48;
            obj.className="gridhdrPlus";
            setStorage(obj, 'A'); //added by Scott
        }
        else {
            obj.parentNode.style.height=obj.style.parh;
            obj.className="gridhdrMinus";
            setStorage(obj, 'B'); //added by Scott
        }
       
    }
    else {
            obj.style.parh=obj.parentNode.style.height;
            //change this to ~25?
            obj.parentNode.style.height=30;
            obj.className="gridhdrPlus";
            setStorage(obj, 'A'); //added by Scott
    }
}
else {
//alert ("+");
    obj.parentNode.style.height=obj.style.parh;
    obj.className="gridhdrMinus";
   
    setStorage(obj,'B'); //added by Scott
    if(!obj.style.parh ){       
        setPersistance(); //added by Scott
    }
    
}
//obj.style.parh=obj.parentNode.style.height;
//alert (h);

    setPersistance(); //added by Scott
}

function setStorage(obj,type){// added by Scott
    var height

    switch(obj.id){
        case 'dtitle0':
            if(type === 'A'){
                height = '30px';
            }else if(type === 'B'){
                height = '440px'
            }
            sessionStorage.setItem('dtitle0_value', height);
            break;
        case 'dtitle1':
            if(type === 'A'){
                height = '30px';
            }else if(type === 'B'){
                height = '284px'
            }
            sessionStorage.setItem('dtitle1_value', height);
            break;
        case 'dtitle2':
            if(type === 'A'){
                height = '30px';
            }else if(type === 'B'){
                height = '90px'
            }
            sessionStorage.setItem('dtitle2_value', height);
            break;
        case 'data0_calt':
            if(type === 'A'){
                height = '48px';
            }else if(type === 'B'){
                height = '470px'
            }
            sessionStorage.setItem('data0_calt_value', height);
            break;
    }

    //console.log(obj.id + ' - ' + obj.parentNode.style.height + ' - ' + type);

}

function setPersistance(){// added by Scott
    
   if(!sessionStorage.getItem('dtitle0_value')){}else{
        document.getElementById('dtitle0').parentNode.style.height=sessionStorage.getItem('dtitle0_value');
        if(sessionStorage.getItem('dtitle0_value') === '30px'){
            document.getElementById('dtitle0').className = 'gridhdrPlus';
        }else{
            document.getElementById('dtitle0').className = 'gridhdrMinus';
        }    
   } 
   if(!sessionStorage.getItem('dtitle1_value')){}else{
        document.getElementById('dtitle1').parentNode.style.height=sessionStorage.getItem('dtitle1_value');
        if(sessionStorage.getItem('dtitle1_value') === '30px'){
            document.getElementById('dtitle1').className = 'gridhdrPlus';
        }else{
            document.getElementById('dtitle1').className = 'gridhdrMinus';
        }
   } 
   if(!sessionStorage.getItem('dtitle2_value')){}else{
        document.getElementById('dtitle2').parentNode.style.height=sessionStorage.getItem('dtitle2_value');
        if(sessionStorage.getItem('dtitle2_value') === '30px'){
            document.getElementById('dtitle2').className = 'gridhdrPlus';
        }else{
            document.getElementById('dtitle2').className = 'gridhdrMinus';
        }
   } 
   if(!sessionStorage.getItem('data0_calt_value')){}else{
        document.getElementById('data0_calt').parentNode.style.height=sessionStorage.getItem('data0_calt_value');
        if(sessionStorage.getItem('data0_calt_value') === '48px'){
            document.getElementById('data0_calt').className = 'gridhdrPlus';
        }else{
            document.getElementById('data0_calt').className = 'gridhdrMinus';
        }
   } 
}
/*********************************************************************************************************
 **********                                                                                     **********
 *********************************************************************************************************/
 function addXtraItem() {

 alert ("Xtra");
 var newtop=parseInt($S("data1").height)-38;
  newDiv(0,"xline"+extra,0,newtop,"100%",26,"block",0,0,"absolute","data1");
 var new0=parseInt($S("data1_col0").width);
 newDiv(0,"xtcell"+extra,0,0,new0,22,"block","#999 solid 1px",0,"absolute","xline"+extra);
$S("xtcell"+extra).className="cell";
  $S("xtcell"+extra).border=null;
  $S("xtcell"+extra).borderRight="#999 solid 1px";
  $S("xtcell"+extra).borderBottom="#999 solid 1px";
  $("xtcell"+extra).innerHTML='<input type=text id="xb'+extra+'" value="" style="border:none;border-bottom:#bbb solid 1px;width:'+(new0-2)+'px;height:19px;cursor:pointer;background:#efefef;" />'  
  var new1=parseInt($S("data1_col1").width); 
 newDiv(0,"xbcell"+extra,new0+2,0,new1,22,"block","#999 solid 1px",0,"absolute","xline"+extra);
$S("xbcell"+extra).className="cell";
 $S("xbcell"+extra).border=null;
  $S("xbcell"+extra).borderRight="#999 solid 1px";
  $S("xbcell"+extra).borderBottom="#999 solid 1px";
  var new2=parseInt($S("data1_col2").width); 
  $S("xbcell"+extra).textAlign="center";
 // $("xbcell"+extra).innerHTML='<input type=text id=xb"'+extra+'" value="" style="border:none;border-bottom:#bbb solid 1px;width:"'+(new1-2)+'px";height:19px;cursor:pointer;iop:1px;" />'  
 $("xbcell"+extra).innerHTML='<input class="tcal" type=text id="xb'+extra+'" value="" style="border:none;border-bottom:#bbb solid 1px;width:'+parseInt($S("cm").width)+'px;height:20px;cursor:pointer;padding-top:1px;" />';

 newDiv(0,"xscell"+extra,(new0+new1+4),0,new2,22,"block","#999 solid 1px",0,"absolute","xline"+extra);
$S("xscell"+extra).className="cell";
  $S("xscell"+extra).border=null;
  $S("xscell"+extra).borderRight="#999 solid 1px";
  $S("xscell"+extra).borderBottom="#999 solid 1px";  
  $S("xscell"+extra).textAlign="center";
  $("xscell"+extra).innerHTML='<input type=text id=xs"'+extra+'" value="" style="border:none;border-bottom:#bbb solid 1px;width:'+parseInt($S("aorsc").width)+'px;height:19px;cursor:pointer;background:#efefef;" />';  
  var new3=parseInt($S("data1_col3").width); 
 newDiv(0,"xdcell"+extra,(new0+new1+new2+6),0,new2,22,"block","#999 solid 1px",0,"absolute","xline"+extra);
$S("xdcell"+extra).className="cell";
  $S("xdcell"+extra).border=null;
  $S("xdcell"+extra).borderRight="#999 solid 1px";
  $S("xdcell"+extra).borderBottom="#999 solid 1px";  
  $S("xdcell"+extra).textAlign="center";
  $("xdcell"+extra).innerHTML='<input type=text id=xd"'+extra+'" value="" style="border:none;border-bottom:#bbb solid 1px;width:'+parseInt($S("aord").width)+'px;height:19px;cursor:pointer;background:#efefef;" />'  
  var new3=parseInt($S("data1_col3").width); 
  
   f_tcalInit ();
  
 /* var neww1=parseInt($S("data0_col1").width); 
 var neww1=parseInt($S("data0_col1").width); 

  $S("xscell"+extra).textAlign="center";
  $S("xpcell"+extra).textAlign="center";

 $("xscell"+extra).innerHTML='<input class="tcal" type=text id="xtras'+extra+'" value="" style="border:none;border-bottom:#bbb solid 1px;width:'+$S("pvs").width+'px;height:20px;cursor:pointer;padding-top:1px;" />';
 $("xpcell"+extra).innerHTML='<input class="tcal" type=text id="xtrap'+extra+'" value="" style="border:none;border-bottom:#bbb solid 1px;width:'+$S("pvp").width+'px;height:20px;cursor:pointer;" />';
 
 $("xtcell"+extra).innerHTML='<input type=text id=xttl"'+extra+'" value="" style="border:none;border-bottom:#bbb solid 1px;width:"'+(neww0-2)+'px";height:19px;cursor:pointer;iop:1px;" />'  
*/
  $S("data1").height=parseInt($S("data1").height)+26;
  extra+=1;

 }
/*********************************************************************************************************
 **********                                                                                     **********
 *********************************************************************************************************/
 function showGraph() {

	 $("data0_calendar").innerHTML="";
//	 console.log(clndArray);
	 for (var key in clndArray) {
//		 console.log(clndArray[key].start, clndArray[key].stop);
		 if ((clndArray[key].start !=0 || clndArray[key].stop!=0) && clndArray[key].start<clndArray[key].stop) {
//			 console.log("filled=")
     newDiv(0,"line_"+key,clndArray[key].start,25*clndArray[key].line,clndArray[key].stop-clndArray[key].start,24,0,0,"fill"+clndArray[key].cls,"absolute","data0_calendar");
	     }
	 }
 }

/*********************************************************************************************************
 **********                                                                                     **********
 *********************************************************************************************************/
function savePep(iterate) {
    
//	alert ("savePep");
	var dataarray=[];
	var l=savedfields.length; /*68*/
	var j=0;
    //Scott Added
    var zDate = makeDate();
    if(iterate==='true'){
    //David D added global variable maxIter on pep.aspx required to set new iteration value
        var iter = Number(maxIter)+1;
        $(savedfields[3]).value = iter;
    }  
    //-------------
	for (var i=0; i<l; i++) {
			
			if (savedfields[i]!="notes") {
				if(savedfields[i]==="iteration"){//added by scott to deal with new stuff
                    //if iterate = true, the iteration and revdate gets updated.
                    if(iterate==='true'){                   
                         if((iter-1)===0){
                            //console.log(zDate); 
                            dataarray[2]='"'+savedfields[2]+'":"'+zDate+'"';
                            $(savedfields[2]).value=zDate;
                         }
                         dataarray[1]='"'+savedfields[1]+'":"'+zDate+'"'
                         dataarray[j]='"'+savedfields[i]+'":"'+iter+'"';
                         //console.log($(savedfields[i]).value);
                    } else{
                        dataarray[j]='"'+savedfields[i]+'":"'+$(savedfields[i]).value+'"';
                    }                   
                }else{
                    dataarray[j]='"'+savedfields[i]+'":"'+$(savedfields[i]).value+'"';
                }				
				j++;
			}else {
				//notes
				
				var vl=$("notes").value;
                vl = cleanHTML(vl);
				while (vl.indexOf("\n")>-1) { 
				    vl=vl.replace("\n","###");
				}
                while(vl.indexOf(",")>-1){
                    vl=vl.replace(",","~");
                }
                while(vl.indexOf(":")>-1){
                    vl=vl.replace(":","`");
                }
                //console.log(vl);
				//alert ($("notes").value);
				dataarray[j] ='"notes":"'+ vl+'"';

				j++;
			}			
	}
	var line=dataarray.join(",");
	//console.log(line);
	var ret=POSTData('pepSave.aspx',"data="+encodeURIComponent(line)+"&projectid="+projectId+"&iterate="+iterate+"&iteration="+$(savedfields[3]).value); 
   
 }

 // removes MS Office generated guff
function cleanHTML(input) {
  // 1. remove line breaks / Mso classes
  var stringStripper = /(\n|\r| class=(")?Mso[a-zA-Z]+(")?)/g; 
  var output = input.replace(stringStripper, ' ');
  // 2. strip Word generated HTML comments
  var commentSripper = new RegExp('<!--(.*?)-->','g');
  var output = output.replace(commentSripper, '');
  var tagStripper = new RegExp('<(/)*(meta|link|span|\\?xml:|st1:|o:|font)(.*?)>','gi');
  // 3. remove tags leave content if any
  output = output.replace(tagStripper, '');
  // 4. Remove everything in between and including tags '<style(.)style(.)>'
  var badTags = ['style', 'script','applet','embed','noframes','noscript'];

  for (var i=0; i< badTags.length; i++) {
    tagStripper = new RegExp('<'+badTags[i]+'.*?'+badTags[i]+'(.*?)>', 'gi');
    output = output.replace(tagStripper, '');
  }
  // 5. remove attributes ' style="..."'
  var badAttributes = ['style', 'start'];
  for (var i=0; i< badAttributes.length; i++) {
    var attributeStripper = new RegExp(' ' + badAttributes[i] + '="(.*?)"','gi');
    output = output.replace(attributeStripper, '');
  }
  return output;
}
 /*********************************************************************************************************
 **********                                                                                     **********
 *********************************************************************************************************/
 function showCalendar() {

 }
/*********************************************************************************************************
 **********                                                                                     **********
 *********************************************************************************************************/
function markDate(obj) {
   var ind=obj.id.substr(0,obj.id.length-1);
   if (ind in clndArray) {
	   var sign=obj.id.substr(obj.id.length-1);
	   var dt=obj.value;
	   var tmp= (getEnd(dt,"/"));
	   var mo=parseInt(getFront(obj.value,"/"));
	   var ye=parseInt(getEnd(tmp,"/"))-2016;//changed this from 2017 to 2016
 //  alert (ye+"   "+mo);
	   var pt=216*ye+18*(mo-1);
	   if (sign=="s") clndArray[ind].start=pt;
	   if (sign=="p") clndArray[ind].stop=pt+18;
//	console.log(ind, clndArray[ind]);
	showGraph();
	}
}

/*********************************************************************************************************
 **********                                                                                     **********
 *********************************************************************************************************/
function fillColTitle(sect,id) {
	 if (sect.columns.length>0) {
//		 alert (sect.columns.length);

	if (sect.columns[0].w) {
 	var cw=parseInt((wx-sect.columns[0].w)/(sect.columns.length-1));
 	var shift=sect.columns[0].w;
	}
 	else {cw=wx/(sect.columns.length);
 	shift=cw;
    }
//    console.log("cw="+cw);
//	alert (id+"\n"+sect.columns.length);
 	for (var i=1; i<sect.columns.length; i++) {
//		alert (shift+"\n"+sect.columns[i].title);
            newDiv(0,id+"sub"+i,shift,0,cw,24,0,0,"cellhdr","absolute",id);
            shift=parseInt(shift)+cw;
            $(id+"sub"+i).innerHTML=sect.columns[i].title;
 	}
    }
}
/*********************************************************************************************************
 **********                                                                                     **********
 *********************************************************************************************************/
function loadCalendar() {
	var calend=JSON.parse(LoadData('pepLoad.aspx?projectid=' +projectId+ "&r="+Math.random()));
	//console.log(calend);
	for (key in calend) {
	//console.log ("Key="+key, calend[key])
		$(key).value=calend[key].replace("###","\n");
		while ($(key).value.indexOf ("###") >-1) {
		$(key).value=$(key).value.replace("###","\n");
		}
        while ($(key).value.indexOf ("~") >-1) {
		$(key).value=$(key).value.replace("~",",");
		}
        while ($(key).value.indexOf ("`") >-1) {
		$(key).value=$(key).value.replace("`",":");
		}
		markDate($(key));
	}
//	alert ("bebebe aort:"+$(aort).value);
//	$("notes").value="bebebe aort:"+$(aort).value;
//	$("notes").value+="" ;
}


/*********************************************************************************************************
 **********                                                                                     **********
 *********************************************************************************************************/
function swapToBud() {
// alert (obj.style.number);
 $S("hbutton1").background="url(img/"+panel.header.section.button[1].img+") -"+panel.header.section.button[1].w+"px 0px no-repeat";
 $S("hbutton0").background="url(img/"+panel.header.section.button[0].img+") 0px 0px no-repeat";
 $S("data0").display="none";
 $S("data1").display="none";
 $S("data2").display="none";
 $S("data3").display="block";
 $S("data4").display="block";

};

function swapToCal() {
// alert (obj.style.number);
 $S("hbutton0").background="url(img/"+panel.header.section.button[0].img+") -"+panel.header.section.button[0].w+"px 0px no-repeat";
 $S("hbutton1").background="url(img/"+panel.header.section.button[1].img+") 0px 0px no-repeat";
 $S("data0").display="block";
 //$S("data1").display="block";
 //$S("data2").display="block";
 $S("data3").display="none";
 $S("data4").display="none";



};

function checkDate(date,id){ //added by Scott
    var zid
    var type = id.substr(id.length - 1, 1);
    var oDte
    var zDte = Date.parse(date);
    //console.log(date);
    if(date != ''){
        var isDte = isDate(date);
        //console.log(isDte);
        if(isDte === false){
            alert('[' + date + ']' + ' is not a valid date.\nPlease enter valid date (DD/MM/YYYY) or use calendar/date picker to the right.');
            document.getElementById(id).value = ''; 
            document.getElementById(id).focus(); 
            document.getElementById(id).select(); 

        }else{
            if(Date.parse(date) < 1451635200000){
                alert('Selected date must fall on or after January 1, 2016');
                document.getElementById(id).value = '';
            }
            if(type === 's'){
                zid = id.substr(0, id.length-1) + 'p'
                oDte = Date.parse(document.getElementById(zid).value);
                if(zDte > oDte){

                    alert('START date cannot be after the selected FINISH date.')
                    document.getElementById(id).value = ''; 
                }
                
            }else if(type === 'p'){
                zid = id.substr(0, id.length-1) + 's'
                oDte = Date.parse(document.getElementById(zid).value);
                if(oDte > zDte){

                    alert('FINISH date cannot be earlier than selected START date.') 
                    document.getElementById(id).value = '';
                }
            }
        }   
    }else{        
       if(type === 's'){           
            zid = id.substr(0, id.length-1) + 'p'
            document.getElementById(zid).value = '';
            //console.log(zid);
        }else if( type ==='p'){
            zid = id.substr(0, id.length-1) + 's'
            document.getElementById(zid).value = '';
           
        } 
        document.getElementById('line_' + id.substr(0, id.length-1)).style.display = 'none';
    }
}

function checkDateYear(zDte, zint){ //added by Scott
    //xDte = new Date(zDte);
    xDte = makeDateString(zDte);
    //console.log(xDte);
    if(zDte < 1451635200000){
         alert('You are attempting to select a date prior to 2016.\nSelected dates must be on or after January 1, 2016.');
    }else{

        checkDate(xDte, zint);
    }
}

function makeDateString(zDte){ //added by Scott
    var dte = new Date(zDte);
    var ndte = dte.getMonth()+ 1 + '/' + dte.getDate() + '/' + dte.getFullYear();
    return ndte
}

function isDate(txtDate){ //Added by Scott
    var currVal = txtDate;
    if(currVal == '')
        return false;
    
    var rxDatePattern = /^(\d{1,2})(\/|-)(\d{1,2})(\/|-)(\d{4})$/; //Declare Regex
    var dtArray = currVal.match(rxDatePattern); // is format OK?
    
    if (dtArray == null) 
        return false;
    
    //Checks for mm/dd/yyyy format.
    dtMonth = dtArray[1];
    dtDay= dtArray[3];
    dtYear = dtArray[5];        
    
    if (dtMonth < 1 || dtMonth > 12) 
        return false;
    else if (dtDay < 1 || dtDay> 31) 
        return false;
    else if ((dtMonth==4 || dtMonth==6 || dtMonth==9 || dtMonth==11) && dtDay ==31) 
        return false;
    else if (dtMonth == 2) 
    {
        var isleap = (dtYear % 4 == 0 && (dtYear % 100 != 0 || dtYear % 400 == 0));
        if (dtDay> 29 || (dtDay ==29 && !isleap)) 
                return false;
    }
    return true;
}
 