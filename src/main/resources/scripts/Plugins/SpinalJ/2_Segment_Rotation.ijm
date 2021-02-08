//--------------------------------------------------------------------------------
//Create reference channle preview and rotate entire segments

//single channel montage displays each section sorted into segments 1-9 (rows)
//user can select segments from which all images need to be rotated (embedded upside-down)
//--------------------------------------------------------------------------------
inputdir=getDirectory("Choose folder that contains raw image files.");			//$$$$$$$$$$$$$$$ how to avoid this?
start=getTime();

if (File.exists(inputdir + "/_Temp/Segmentation_Parameters.csv")) {
	ParamFile = File.openAsString(inputdir + "/_Temp/Segmentation_Parameters.csv");
	ParamFileRows = split(ParamFile, "\n"); 		
} else {
	exit("Pre-processing Parameter file doesn't exist, please run Set Pre-processing Settings step for this folder first.");
}
       		
path_data = LocateValue(ParamFileRows, "Directory_Data");
path_data=path_data+"/";    		     		
RefCh = parseInt(LocateValue(ParamFileRows, "Reference channel"));

path_temp=path_data + "_Temp/";
path_split= path_temp + "_I_Split/";

//load images 
fileList = getFileList(path_split);
fileList=Array.sort(fileList);
//print(fileList.length);

width=3000;
height=3000;
bin=4;

//save single channel preview images to /_II_Preview_Split
path_splitprev=path_temp + "_II_Preview_Split/";					

if (File.exists(path_splitprev)==true){									//delete preview folder and its content if already exists
	list = getFileList(path_splitprev);		
	//Array.print(list);			
	for (i=0; i<list.length; i++) {
     	File.delete(path_splitprev+list[i]);
	}												
	File.delete(path_splitprev);  
}
while (File.exists(path_splitprev)==1){									//wait until files are deleted
	//wait for file delete
}

File.makeDirectory(path_splitprev);

//split channels and save binned ref channel 
print("Creating single channel preview..."); 
setBatchMode(true); //batch mode on
for (i=0; i<fileList.length; i++) {
	open(path_split+fileList[i]);
	imageTitle=getTitle();
	run("Split Channels");
	selectWindow("C" + RefCh + "-" + imageTitle);							
	setOption("ScaleConversions", true);
	run("8-bit");
	run("8-bit");
	run("Enhance Contrast", "saturated=0.35");
	run("Canvas Size...", "width="+ width + " height=" + height + " position=Center zero");
	run("Bin...", "x=" + bin + " y=" + bin +" bin=Average");
	saveAs("tiff", path_splitprev+imageTitle);
	while (nImages>=1){
		close();
	}	
}

//save ref images to stack and montage
run("Image Sequence...", "open=["+path_splitprev+fileList[0]+"] sort");
run("Bleach Correction", "correction=[Histogram Matching]"); //histogram matching
saveAs("Tiff", path_splitprev+"_Preview_Stack");
Stack.getDimensions(width, height, channels, slices, frames); 
col=-floor(-(slices/9));	//ceil decimal values
row=9;
run("Make Montage...", "columns="+col+" rows="+row+" scale=0.25 font=32 label");
saveAs("Tiff", path_splitprev+"_Preview_Montage");
close();
setBatchMode(false);	
close();							   
print("Preview complete!"); 


//allow user to determine which segments need to be rotated
open(path_splitprev+"_Preview_Montage.tif");
setTool("zoom");
waitForUser("Determine which segment(s) (all images in a row) need to be rotated, so that dorsal is up (angles <90 degree are ok). \nLeft or right click to zoom in and out!"); 
Dialog.create("Rotating entire segments");
Dialog.addCheckbox("Segment 1", false);
Dialog.addCheckbox("Segment 2", false);
Dialog.addCheckbox("Segment 3", false);
Dialog.addCheckbox("Segment 4", false);
Dialog.addCheckbox("Segment 5", false);
Dialog.addCheckbox("Segment 6", false);
Dialog.addCheckbox("Segment 7", false);
Dialog.addCheckbox("Segment 8", false);
Dialog.addCheckbox("Segment 9", false);

Dialog.addNumber("Rotation angle", 180);
Dialog.show();
seg1 = Dialog.getCheckbox();
seg2 = Dialog.getCheckbox();
seg3 = Dialog.getCheckbox();
seg4 = Dialog.getCheckbox();
seg5 = Dialog.getCheckbox();
seg6 = Dialog.getCheckbox();
seg7 = Dialog.getCheckbox();
seg8 = Dialog.getCheckbox();
seg9 = Dialog.getCheckbox();

seg=newArray(seg1, seg2, seg3, seg4, seg5, seg6, seg7, seg8, seg9);
angle=Dialog.getNumber();
//Array.print(seg);

close();


//check if any segment is selected for rotation
Array.getStatistics(seg, min, max, mean, stdDev);

if(max==1){		//at least one segment needs rotation
	print("at least one segment selected for rotation");
	setBatchMode(true); //batch mode on
	print("Rotating images ..."); 

	for (i=0; i<fileList.length; i++) {		//all files
		for (s=0; s<9; s++){				//all segments
			sm=s+1;
				if ((seg[s]==1)&&(startsWith(fileList[i], "Segment_0" + sm)==1)){
					open(path_split+fileList[i]);
					print("rotating " + fileList[i]);								
					run("Rotate... ", "angle=" +angle+ " grid=1 interpolation=Bilinear stack");		//rotate stack
					run("Save");
					close();

					open(path_splitprev+fileList[i]);
					run("Rotate... ", "angle=" +angle+ " grid=1 interpolation=Bilinear");			//rotate ref ch image
					run("Save");
					close();
				}
		}
	}

	print("Rotating images completed!"); 
	print("Updating preview images");
	File.delete(path_splitprev+"_Preview_Stack.tif");
	File.delete(path_splitprev+"_Preview_Montage.tif");
	run("Image Sequence...", "open=["+path_splitprev+fileList[0]+"] sort");
	saveAs("Tiff", path_splitprev+"_Preview_Stack");
	run("Make Montage...", "columns="+col+" rows="+row+" scale=0.25 font=32 label");
	saveAs("Tiff", path_splitprev+"_Preview_Montage");
	close();

	setBatchMode(false);
	close();

}
else{
	print("No rotation required!"); 
}

print("Job complete! Opening preview...");
open(path_splitprev+"_Preview_Montage.tif");

//---------------------------------------------------------------------------------------------------------------------------

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

