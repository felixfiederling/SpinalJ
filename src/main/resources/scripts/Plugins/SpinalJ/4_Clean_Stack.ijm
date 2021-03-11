//--------------------------------------------------------------------------------
//8_26_2020	USER INPUT VIA KEYS, NO ANGLE CORRECTION OF INDIVDUAL IMAGES POSSIBLE

//--------------------------------------------------------------------------------

#@ File(label="Image Data:", description="Subfolder containing spinal cord block section raw data", style="directory") input

start=getTime();

if (File.exists(input + "/_Temp/_PreProcessing_Parameters.csv")) {
	ParamFile = File.openAsString(input + "/_Temp/_PreProcessing_Parameters.csv");
	ParamFileRows = split(ParamFile, "\n"); 		
} else {
	exit("Pre-processing Parameter file doesn't exist, please run Set Pre-processing Settings step for this folder first.");
}
       		
path_data = LocateValue(ParamFileRows, "Directory_Data");
path_data=path_data+"/";    		     		
RefCh = parseInt(LocateValue(ParamFileRows, "Reference channel"));

path_temp=path_data + "_Temp/";
path_split= path_temp + "_I_Split/";
path_splitprev= path_temp + "_II_Preview_Split/";

//set display options
sw=screenWidth;
sh=screenHeight;
if((sw/3)<=sh){
	w=floor((sw-20)/3);
	h=w;
	xleft=5;
	yleft=50;
	xmiddle=xleft+w+5;
	ymiddle=50;
	xright=xmiddle+w+5;
	yright=50;
	xdialog=xmiddle;
	ydialog=ymiddle+h+5;
}
else{
	print("Screen resolution not supported");
}

//open preview stack (ref channel)
open(path_splitprev + "_Preview_Stack.tif");
stack = getTitle();
//selectWindow(stack);
setLocation(xmiddle,ymiddle,w,h);

slices=nSlices;
selection=newArray(slices);
//angle=newArray(slices);

//list of files (not containing Montage and Stack; filenames of images in "_I_Split" and in "_II_Preview_Split" should be the same)
fileList=getFileList(path_split);
fileList=Array.sort(fileList);
//Array.print(list);

path_clean=path_temp+"_III_Clean/";	
File.makeDirectory(path_clean);	

print("Initializing Cleaning...");

//check if cleaning has been started previously
if (File.exists(path_temp + "_Cleaning_log.csv")==true){
	open(path_temp + "_Cleaning_log.csv");
	for (r=0; r<slices; r++){
		selectWindow("_Cleaning_log.csv");
		pr=Table.get("Value", r);
		if(pr==0){
			lastprocessed=r-1;			//first section counted as 0
			waitForUser("Warning", "Cleaning already (partially) performed! Will resume from last processed section ("+lastprocessed+"). To re-run, delete Cleaning_log.csv!");
			start=lastprocessed;	
			break;
		}
		else {
		pr=Table.getString("Value", r);	//write existing selections into selection array
		selection[r]=pr;
		start=slices-1;	
		}
	}
	run("Close");
					
}
else {
	start=0;
}

selectWindow(stack);
setSlice(start+1);
	
//GO THROUGH ALL PREVIEW IMAGES
for (i=start; i<slices; i++) {		// loop through stack slices
	if(i>0){
		open(path_splitprev+fileList[i-1]);			//show previous slice
		prev=getTitle();
		setLocation(xleft,yleft,w,h);
		rename("Previous slice");			
	}
	else{
		newImage("Previous slice", "8-bit black", w, h, 1);		
		setLocation(xleft,yleft,w,h);
	}
	if(i<slices-1){										//show next slice
		open(path_splitprev+fileList[i+1]);
		prev=getTitle();
		setLocation(xright,yright,w,h);
		rename("Next slice");		
	}
	else {
		newImage("Next slice", "8-bit black", w, h, 1);		
		setLocation(xright,yright,w,h);
	}

	//key press
	//"space": keep, "control": replace, "alt": delete
	if (i==0){
		//waitForUser("Press 'space' to keep, 'control' to replace or 'alt' to delete current section. Start after clicking OK");  
		print("Press 'space' to keep, 'control' to replace or 'alt' to delete current section.");
		showMessage("Clean image dataset", "Create a continuous stack of intact sections by cleaning out sections that are damaged, out of focus, or otherwise compromised. \nFor further information consult the user guide. \n \nPress 'SPACE' to keep, 'CTRL' to replace or 'ALT' to delete current section. \n(Key bindings are saved to log window).");
	
	}

	//wait for user input (key press)
	userinput=0;
	while (userinput==0){
	wait(5);	
		if (isKeyDown("space")){
			selection[i]="keep";
			userinput=1;}
		
		else if (isKeyDown("control")){
			selection[i]="replace";
			userinput=1;}
		
		else if (isKeyDown("alt")){
			selection[i]="delete";
			userinput=1;}
	}

	//save selection for each step
	run("Clear Results"); 
	Array.show(selection);		
	saveAs("Results", path_temp + "_Cleaning_log.csv");
	run("Close");
	
	selectWindow(stack);
	if (i<slices-1){
		setSlice(i+2);				//next section (i=0 --> first section = 1, next section = 2)
	}
	//run("Next Slice [>]");
	close("Previous slice");
	close("Next slice");
	
}

		
close();

//apply user input to single segment images in folder "_I_Split"
print("Cleaning images...");	
				
s=1;
setBatchMode(true); //batch mode on

for (j=0; j<fileList.length; j++) {
	//print(imgpath+"/"+fileList[j]);
	open(path_split+fileList[j]);	
	
	if (s<1000) {												//alphanumeric numbering of up to 9999 slices
		saveslice=path_clean + "0" + s;			
		if (s<100) {
			saveslice=path_clean + "00" + s;
			if (s<10) {
				saveslice=path_clean + "000" + s;
			}
		}
	
		saveslice=replace(saveslice, File.separator, "/");
	}
 	else {
 		saveslice=path_clean+"/"+ s;
		saveslice=replace(saveslice, File.separator, "/"); 		
 	}
	if (selection[j]=="keep") {
		saveAs("tiff",saveslice + "_" + fileList[j]);
		lastgood=fileList[j];
		close();
		s=s+1; }
				
	if (selection[j]=="replace") {
		close();
		open(path_split+lastgood);
		saveAs("tiff",saveslice+ "_" + lastgood);
		close();
		s=s+1; }
}

setBatchMode(false);
//close();

print("Cleaning completed!");

//----------------------------------------------------------------------------------------------------
//Create preview of cleaned images

// uncomment below to start here
//path_stack = File.openDialog("Choose Preview Stack ('/_II_Preview_Split/_Preview_Stack.tif')"); 
//path_splitprev=File.getParent(path_stack);		//path to /_II_Preview_Split
//path_split=File.getParent(path_splitprev)+"/_I_Split";  //path to /_I_Split
//path_clean=File.getParent(path_splitprev)+"/_III_Clean";	//path to /_III_Clean
///
 
width=3000;
height=3000;
bin=4;

//save single channel preview images to /_IV_Preview_Clean
path_cleanprev = path_temp + "_IV_Preview_Clean/";					//path to folder '/_IV_Preview_Clean'
//print(path_cleanprev);
if (File.exists(path_cleanprev)==1){									//delete preview folder and its content if already exists
	print("Deleting old files...");
	list = getFileList(path_cleanprev);		
	Array.print(list);			
	for (i=0; i<list.length; i++) {
     	File.delete(path_cleanprev+list[i]);
	}												
	File.delete(path_cleanprev);  
}
while (File.exists(path_cleanprev)==1){									//wait until files are deleted
	//wait for file delete
}
File.makeDirectory(path_cleanprev);

//split channels and save binned ref channel 
print("Creating single channel preview..."); 
fileList=getFileList(path_clean);
setBatchMode(true); //batch mode on
for (i=0; i<fileList.length; i++) {
	open(path_clean+fileList[i]);
	imageTitle=getTitle();
	run("Split Channels");
	selectWindow("C" + RefCh + "-" + imageTitle);							
	setOption("ScaleConversions", true);
	run("8-bit");
	run("8-bit");
	run("Enhance Contrast", "saturated=0.35");
	run("Canvas Size...", "width="+ width + " height=" + height + " position=Center zero");
	run("Bin...", "x=" + bin + " y=" + bin +" bin=Average");
	saveAs("tiff", path_cleanprev+imageTitle);
	while (nImages>=1){
		close();
	}	
}

//save ref images to stack and montage
run("Image Sequence...", "open=["+path_cleanprev+fileList[0]+"] sort");
run("Bleach Correction", "correction=[Histogram Matching]"); //histogram matching
saveAs("Tiff", path_cleanprev+"_Preview_Stack_Clean");
Stack.getDimensions(width, height, channels, slices, frames); 
col=-floor(-(slices/9));	//ceil decimal values
row=9;
run("Make Montage...", "columns="+col+" rows="+row+" scale=0.25 font=20 label");
saveAs("Tiff", path_cleanprev+"_Preview_Montage_Clean");
//close();
setBatchMode(false);	
//close();							   
print("Preview complete!"); 

//---------------------------------------------------------------------------------------------------------------------------------
function LocateValue(inputArray, VarName) {
		
	//Give array name, and variable name in column 0, returns value in column 1
	Found = 0;
	for(i=0; i<inputArray.length; i++){ 
		if(matches(inputArray[i],".*"+VarName+".*") == 1 ){
			Row = split(inputArray[i], ",");
			Value = Row[1];
			Found = 1; 	
		}
		
	}
	if (Found == 0) {
		Value = 0;
	}
	return Value;
}