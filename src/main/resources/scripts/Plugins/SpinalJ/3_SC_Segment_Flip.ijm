//--------------------------------------------------------------------------------
//SECOND STEP
//Create reference channle preview and rotate entire segments

//single channel montage displays each section sorted into segments 1-9 (rows)
//user can select segments from which all images need to be rotated (embedded upside-down)

//--------------------------------------------------------------------------------

//load images 
path_split = getDirectory("Choose folder containing single section tiffs ('_I_Split')"); 		//path to folder '/_I_Split' 
fileList = getFileList(path_split);
fileList=Array.sort(fileList);
//print(fileList.length);

Dialog.create("Select preview options");
Dialog.addNumber("Preview channel #", 3);
Dialog.addNumber("Canvas width [px]", 3000);
Dialog.addNumber("Canvas height [px]", 3000);
Dialog.addNumber("Binning (x,y factor)", 4);

Dialog.show();
regch=Dialog.getNumber();
width=Dialog.getNumber(); //3000;
height=Dialog.getNumber(); //3000;
bin=Dialog.getNumber();	//4
//print(width);
//print(height);


//save single channel preview images to /_II_Preview_Split
path_splitprev=File.getParent(path_split)+"/_II_Preview_Split";					//path to folder '/_II_Preview_Split'
//print(path_splitprev);
if (File.exists(path_splitprev)==1){									//delete preview folder and its content if already exists
	list = getFileList(path_splitprev);		
	Array.print(list);			
	for (i=0; i<list.length; i++) {
     	File.delete(path_splitprev+"/"+list[i]);
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
	selectWindow("C" + regch + "-" + imageTitle);							
	setOption("ScaleConversions", true);
	run("8-bit");
	run("8-bit");
	run("Enhance Contrast", "saturated=0.35");
	run("Canvas Size...", "width="+ width + " height=" + height + " position=Center zero");
	run("Bin...", "x=" + bin + " y=" + bin +" bin=Average");
	saveAs("tiff", path_splitprev+"/"+imageTitle);
	while (nImages>=1){
		close();
	}	
}

//save ref images to stack and montage
run("Image Sequence...", "open=["+path_splitprev+"/"+fileList[0]+"] sort");
run("Bleach Correction", "correction=[Histogram Matching]"); //histogram matching
saveAs("Tiff", path_splitprev+"/"+"_Preview_Stack");
Stack.getDimensions(width, height, channels, slices, frames); 
col=-floor(-(slices/9));	//ceil decimal values
row=9;
run("Make Montage...", "columns="+col+" rows="+row+" scale=0.25 font=32 label");
saveAs("Tiff", path_splitprev+"/"+"_Preview_Montage");
close();
setBatchMode(false);	
close();							   
print("Preview complete!"); 

//////////////////////////////
//path_split = getDirectory("Choose folder containing single section tiffs ('_I_Split')"); 		//path to folder '/_I_Split' 
//fileList = getFileList(path_split);
//fileList=Array.sort(fileList);
//path_splitprev=File.getParent(path_split)+"/_II_Preview_Split";		
//col=floor(-(fileList.length/9));
///////////////////////////////

//allow user to determine which segments need to be rotated
open(path_splitprev+"/"+"_Preview_Montage.tif");
setTool("zoom");
waitForUser("Determine which segments (all images in a row) are oriented upside-down (zoom not available in next step)!"); 
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
Array.print(seg);

close();


//TRANSFORM SINGLE SEGMENT RAW IMAGES in folder /_I_Split
//setBatchMode(true); //batch mode on
//print("Rotating images ..."); 
//for (i=0; i<fileList.length; i++) {		//all files
//	for (s=0; s<9; s++){				//all segments
//		sm=s+1;
//		if ((startsWith(fileList[i], "Segment_0" + sm)==1)&&(seg[s]==1)){
//			open(path_split+fileList[i]);								
//			run("Rotate... ", "angle=" +angle+ " grid=1 interpolation=Bilinear stack");		//rotate stack
//			run("Save");
//			close();
//
//			open(path_splitprev+"/"+fileList[i]);
//			run("Rotate... ", "angle=" +angle+ " grid=1 interpolation=Bilinear");			//rotate ref ch image
//			run("Save");
//			close();
//		}
//	}
//}
////////////////////////////////////////////////////
//rotating images that don't follow standard file name format


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

					open(path_splitprev+"/"+fileList[i]);
					run("Rotate... ", "angle=" +angle+ " grid=1 interpolation=Bilinear");			//rotate ref ch image
					run("Save");
					close();
				}
		}
	}

	print("Rotating images completed!"); 
	print("Updating preview images");
	File.delete(path_splitprev+"/"+"_Preview_Stack.tif");
	File.delete(path_splitprev+"/"+"_Preview_Montage.tif");
	run("Image Sequence...", "open=["+path_splitprev+"/"+fileList[0]+"] sort");
	saveAs("Tiff", path_splitprev+"/"+"_Preview_Stack");
	run("Make Montage...", "columns="+col+" rows="+row+" scale=0.25 font=32 label");
	saveAs("Tiff", path_splitprev+"/"+"_Preview_Montage");
	close();

	setBatchMode(false);
	close();

}
else{
	print("No rotation required!"); 
}

print("Job complete! Opening preview...");
open(path_splitprev+"/"+"_Preview_Montage.tif");
