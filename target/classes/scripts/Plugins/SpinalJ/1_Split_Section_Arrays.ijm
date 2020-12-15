//--------------------------------------------------------------------------------
//FIRST STEP
//SPLIT 3x3 IMAGES
//returns multichannel tif images in folder "Split and Sorted" that contain a single spinal cord section

//updated 8/27/2020 
//fixed metadata extraction without loading image
//rois that lie outside the image boundaries are ignored for segmentation
//-----------------------------------------------------------------------------------------
//====================================================================================================================================

//SELECT IMAGE DATA

path_all = getDirectory("Choose folder that contains raw image files"); 
//print(path_all);
Dialog.create("Choose input format");
Dialog.addChoice("Type:", newArray(".nd2", ".tif", ".czi", ".lsm", ".ics", ".lif", ".oib"));		//only tested for nd2 so far
Dialog.show();
ext=Dialog.getChoice();

fileListall = getFileList(path_all); 
//make sure only image files are selected (if re-running this analysis, there might be additional folders in that directory)
setOption("ExpandableArrays", true);
fileList=newArray;
ff=0;
for (f=0; f<fileListall.length; f++){
	if (endsWith(fileListall[f], ext)){
		fileList[ff]=fileListall[f];
		ff=ff+1;
	}
}

Array.sort(fileList);		
Array.show("Files to process.", fileList);	//check slide order
//the Nikon slide scanner names files in a way that alphanumerical sorting does not match slide numbers, i.e. first element is Slide10 instead of Slide1

q1=getBoolean("List of files matches slide order (ascending)?");	//yes: 1, no: 0, cancel: exit macro
//print(q1);
if (q1==1){ //YES
	//save Filelist
	selectWindow("Files to process.");	
	saveAs("Results", path_all+"_FileList.csv");
	print("File list saved!");  
}
else if(q1==0){	//NO
	q2=getBoolean("Apply file name correction for Nikon system?");	//yes: 1, no: 0, cancel: exit macro
	if(q2==0){	//NO
	print("Please correct file names manually and start again!");}
	else if(q2==1){		//YES
		//RENAME Image FILES to match slide order (Nikon)
		//they need to be named Slide1-XX_Region... with XX having as many digits as number of slides (i.e. XX for up to 99 slides)
		for (t=0; t<fileList.length; t++){ 
			file = fileList[t];
			for (s=1; s<10; s++){
				prefix = "Slide1-" + s + "_";	//convert "Slide1-t_" to "Slide1-0t_"
				test=startsWith(file,prefix);
				if (test==1){
					newname = replace(file, "Slide1-", "Slide1-0");	
					File.rename(path_all+file, path_all+newname); } 
			}
		}
		print("Files re-named!"); 
		
		//get fileList with renamed files
		fileListall = getFileList(path_all); 
		//make sure only image files are processed
		ff=0;
		fileList=newArray();
		for (f=0; f<fileListall.length; f++){
			if (endsWith(fileListall[f], ext)){
				fileList[ff]=fileListall[f];
				ff=ff+1;
			}
		}
		fileList = Array.sort(fileList);	
		//selectWindow("_FileList.csv");
		run("Clear Results"); 
		Array.show("Files to process.",fileList);			
		saveAs("Results", path_all+"_FileList.csv");
		print("Files re-named and sorted file list saved!");  
	}
}


//====================================================================================================================================
// Order files according to order on the slide (the slide scanner may scan and name images in a way that does not reflect order on the slide)

// READ IMAGE COORDINATES FROM METADATA
//check if this step has already been completed

rerun="N/A";		//default definition

if(File.exists(path_all+"_Coordinates_Rows.txt")==1){	//YES, Coordinates already extracted
	Dialog.create("Action required");					//let user decide whether to re-run or go with existing information
	Dialog.addMessage("Image coordinates have been extracted before. Do you want to re-analyze Metadata?");
	options=newArray("yes", "no"); 
	Dialog.addRadioButtonGroup("Re-analyze metadata?", options, 2, 1, "no");
	Dialog.show();
	rerun = Dialog.getRadioButton();
}

//OPTION 1
//-------------------------------------------------------------------------------------------------------------
if((File.exists(path_all+"_Coordinates_Rows.txt")==0)||(rerun=="yes")){	//NO metadata or re-run selected
	print("Extracting stage coordinates of images...");
	
	allcoordinatesX=newArray(fileList.length);				
	allcoordinatesY=newArray(fileList.length);
	slide = newArray(fileList.length);

	setBatchMode(true);
	for (j=0; j<fileList.length; j++){ 
		
		//slide information
		slidenumber = substring(fileList[j], 7, 9);
		slidenumber = replace(slidenumber, "_", "");
		slidenumber = parseInt(slidenumber);
		slide[j]=slidenumber;
		//print(slidenumber);
		if (j==0){
			print("Reading Metadata of file " + j+1 + " of " + fileList.length + " ...");
		}
		else {
			print("\\Update:" + "Reading Metadata of file " + j+1 + " of " + fileList.length + " ...");
		}

		//load metadata
		//name="C:/Users/Felix Fiederling/Desktop/test split/Slide1-7_Region0009_Channel640 nm,555 nm,475 nm_Seq0064.nd2";
		run("Bio-Formats Macro Extensions");
		//run("Bio-Formats Importer", "open=[" + path_all + fileList[j] + "] color_mode=Default display_metadata rois_import=[ROI manager] view=[Metadata only] stack_order=Default");
		Ext.setId(path_all + fileList[j]);
		//Ext.setId(name);
		Ext.getMetadataValue("dXPos", XNum);
		Ext.getMetadataValue("dYPos", YNum);
	
		allcoordinatesX[j]=XNum;
		allcoordinatesY[j]=YNum;
		//run("Close");
	}
	setBatchMode(false);
	close("*");
//-------------------------------------
	//FIND HOW MANY IMAGES THERE ARE ON EACH SLIDE
	print("\\Clear");
	Array.print(slide);
	selectWindow("Log");
	saveAs(".txt", path_all+"_Slides.txt");
	
	maxslide = Array.findMaxima(slide, 0);
	maxslide = slide[maxslide[0]];				//select first index if multiple maxima are found
	//print(maxslide);
	imagesonslide = newArray(maxslide);
	imagesonslide = Array.fill(imagesonslide, 0);
	//Array.print(imagesonslide);

	for (uu=0; uu<slide.length; uu++){
		s=slide[uu];
		imagesonslide[s-1]= imagesonslide[s-1]+1; }
		
	print("\\Clear");
	Array.print(imagesonslide);		//contains number of images for each slide
	selectWindow("Log");
	saveAs(".txt", path_all+"_Images_per_Slide.txt");
//----------------------------------------
	//SAVE COORDINATES AND SEPARATE BOT vs TOP ROW
	// slide coordinate range in Nikon slide scanner: 
	//x: ~29000 - 82000
	//y: ~20000 - 40500
	
	for(tt=0; tt<fileList.length; tt++){
		allcoordinatesX[tt]=parseInt(allcoordinatesX[tt]);
		allcoordinatesY[tt]=parseInt(allcoordinatesY[tt]); }

	print("\\Clear");
	Array.print(allcoordinatesX);
	selectWindow("Log");
	saveAs(".txt", path_all+"_Coordinates_X.txt");

	print("\\Clear");
	Array.print(allcoordinatesY);
	selectWindow("Log");
	saveAs(".txt", path_all+"_Coordinates_Y.txt");

	SlideRow = newArray(fileList.length);
	reference_bot = 25000;								
	reference_top = 35000;
	tolerance = 5000;
	bot_max=reference_bot+tolerance;	// 30000
	
	errorcount=0;

	for(rr=0; rr<fileList.length; rr++){
		//print(allcoordinatesYsort[r]);
		if(allcoordinatesY[rr]<=bot_max){	// <=30000
			SlideRow[rr]="bottom"; }
		else if(allcoordinatesY[rr]>bot_max) {	// >30000
			SlideRow[rr]="top"; }
		else{
			SlideRow[rr]="top";				//assign "top" if can't be assigned
			errorcount=errorcount+1;
			}
	}
	print("\\Clear");
	Array.print(SlideRow);
	selectWindow("Log");
	saveAs(".txt", path_all+"_Coordinates_Rows.txt");
	print("\\Clear");
	print("Extracting stage coordinates of images...");
	Array.print(allcoordinatesX);
	Array.print(allcoordinatesY);
	Array.print(SlideRow);
	Array.print(imagesonslide);
	print("Stage coordinates saved!");

	if(errorcount>0){
		print("Warning: " + errorcount + " images could not be assigned to either top or bottom row of slide!");	
	}
}	//end extract coordinates from Metadata	 
//---------------------------------------------------------------------------------------------------------------------------

//OPTION 2
else if ((File.exists(path_all+"_Coordinates_Rows.txt")==1)&&(rerun=="no")){	//metadata available, no re-run selected
	print("loading coordinates from text files...");
	pathfile=path_all+"_Images_per_Slide.txt";
	filestring=File.openAsString(pathfile);
	splitstring=split(filestring, ",,");
	imagesonslide=newArray(splitstring.length);
	for(i=0; i<splitstring.length; i++){
		imagesonslide[i]=parseFloat(splitstring[i]);
	}
	//Array.print(imagesonslide);

	//load slide
	pathfile=path_all+"_Slides.txt";
	filestring=File.openAsString(pathfile);
	splitstring=split(filestring, ",,");
	slide=newArray(splitstring.length);
	for(i=0; i<splitstring.length; i++){
		slide[i]=parseFloat(splitstring[i]);
	}
	//Array.print(slide);

	//load allcoordinatesX
	pathfile=path_all+"_Coordinates_X.txt";
	filestring=File.openAsString(pathfile);
	splitstring=split(filestring, ",,");
	allcoordinatesX=newArray(splitstring.length);
	for(i=0; i<splitstring.length; i++){
		allcoordinatesX[i]=parseFloat(splitstring[i]);
	}
	//Array.print(allcoordinatesX);

	//load SlideRow
	//path_all = getDirectory("Choose a Directory"); 
	pathfile=path_all+"_Coordinates_Rows.txt";
	filestring=File.openAsString(pathfile);
	SlideRow=split(filestring, ",,");
	for(i=0; i<SlideRow.length; i++){
		SlideRow[i]=replace(SlideRow[i]," ","");		//remove spaces
		SlideRow[i]=replace(SlideRow[i],"\n","");		//remove line breaks
	}

}		//end load coordinates from text files
//---------------------------------------------------------------------------------------------------------------


//====================================================================================================================================
// IMAGE TRANSFORMATION AND CROPPING

// Choose transformation option (flipping all images)				
Dialog.create("Pre-processing all images");
options=newArray("no flip", "vertical flip (up-down)", "horizontal flip (left-right)", "vertical and horizontal flip"); 
Dialog.addRadioButtonGroup("Transformation", options, 4, 1, "no flip");
Dialog.show();
choice = Dialog.getRadioButton();

// Browse mask for segmentation
myDirectory = getDirectory("startup");
call("ij.io.OpenDialog.setDefaultDirectory", myDirectory);
mask = File.openDialog("Choose segmentation mask ROI file"); //only offer standard 3x3 mask? Offer 2x2, 3x3, 4x4, 5x5 options?
//---------------------------------------------------------------------------------------------------------------------

// SPLIT IMAGES
print("Transforming and splitting images...");
File.makeDirectory(path_all+"_I_Split");

//get images into correct order
for (mm=0; mm<imagesonslide.length; mm++){		//loop through all slides
		if(imagesonslide[mm]>0){				//if there are more than 0 images on slide mm
			currslide = mm+1;					//current slide number
			//print(currslide);
			currnumber = imagesonslide[mm];		//number of images on current slide
			//print(currnumber);

			currfiles = newArray(currnumber);
			currX = newArray(currnumber);
			currrow = newArray(currnumber);
			for (nn=0; nn<currnumber; nn++){
				for (oo=0; oo<slide.length; oo++){
					if(slide[oo]==currslide){
					currfiles[nn]=fileList[oo];			//filenames of images on current slide
					currX[nn] = allcoordinatesX[oo];	//x-coordinates of images on current slide
					currrow[nn] = SlideRow[oo];			//row information of images on current slide
					nn=nn+1;
					slide[oo] = NaN; 
					}	
				}
				Array.print(currfiles);
				Array.print(currX);
				Array.print(currrow);
				//print(currrow.length);
				//print(currX[0]);
				//print(currX[1]);
			}			

			currXtop = newArray(currrow.length);		//get X coordinates for images on current slide and split into a top and bottom list
			currXtop = Array.fill(currXtop, 0);
			currfilestop = newArray(currrow.length);
			currfilestop = Array.fill(currfilestop, 0);
			currXbot = newArray(currrow.length);
			currXbot = Array.fill(currXbot, 0);
			currfilesbot = newArray(currrow.length);
			currfilesbot = Array.fill(currfilesbot, 0);
		
			for (pp=0; pp<currrow.length; pp++){
				if (currrow[pp]=="top"){
					print("top detected");
					currXtop[pp]=currX[pp];
					currfilestop[pp]=currfiles[pp];
				}
				else if (currrow[pp]=="bottom"){
					print("bottom detected");
					currXbot[pp]=currX[pp];
					currfilesbot[pp]=currfiles[pp];
					print(currXbot[pp]);
				}
			}
			currXtop = Array.deleteValue(currXtop, 0);
			currXbot = Array.deleteValue(currXbot, 0);
			currfilestop = Array.deleteValue(currfilestop, 0);
			currfilesbot = Array.deleteValue(currfilesbot, 0);
			Array.print(currXtop);							//contains X-coordinates of images in top row of current slide
			Array.print(currXbot);							//contains X-coordinates of images in bottom row of current slide
			Array.print(currfilestop);	
			Array.print(currfilesbot);	

			//sort images based on coordinates
			ranktop = Array.rankPositions(currXtop);
			rankbot = Array.rankPositions(currXbot);
			for (u=0; u<rankbot.length;u++){				//continuous ranks
				rankbot[u] = rankbot[u]+ranktop.length;
			}

			slideorder = newArray(currnumber);
			ri = 0;
			while (ri<currnumber){
				if(ri<currXtop.length){
					for (rr=0; rr<currXtop.length; rr++){
						if (ranktop[rr]==ri){
							slideorder[ri]= currfilestop[rr];
							ri=ri+1;
						}
					}
				}
				else if (ri>=currXtop.length){
					for (rr=0; rr<currXbot.length; rr++){
						if (rankbot[rr]==ri){
							slideorder[ri]= currfilesbot[rr];
							ri=ri+1;
						}
					}
				}
			}			//end while loop
	
			print("\\Clear");
			Array.print(slideorder);
			selectWindow("Log");
			saveAs(".txt", path_all+"_Slide_"+ currslide +"_ordered.txt");
			print("All imges sorted according to slide position!");
			print("Segmenting images...");

			//OPEN AND TRANSFORM IMAGE, SAVE SEGMENTED TILES  
			close("*");
			for (ss=0; ss<slideorder.length; ss++){		
				//run("Bio-Formats Macro Extensions");
				run("Bio-Formats Windowless Importer", "open=[" + path_all + slideorder[ss] + "] color_mode=Default rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT");
   				currImg = getTitle();
				title = replace(slideorder[ss], ".nd2", ""); 
		    	//transform image according to user input
		    	if (choice=="vertical flip (up-down)"){
	    			run("Flip Vertically", "stack");    }
    			if (choice=="horizontal flip (left-right)"){
    				run("Flip Horizontally", "stack");  }
    			if (choice=="vertical and horizontal flip"){
    				run("Flip Vertically", "stack");
    				run("Flip Horizontally", "stack");  }

				//segment image
				selectWindow(currImg);
				run("Brightness/Contrast...");					//brighten up image
				run("Enhance Contrast", "saturated=0.35");	
				//get dimensions
				Iw=getWidth();
				Ih=getHeight();
				//print(Iw);print(Ih);

				// load segmentation mask
				roiManager("reset");													
				roiManager("Open", mask);   
				roiManager("Select", 0);                           
				setTool(0);                                                                          
				waitForUser("Position mask to split image or Shift+click OK to skip");	//position mask   
				
				if (isKeyDown("Shift") == true) {				//check if shift key has been used to skip
        			//skip  			
        			}
				else {
	  				resetMinAndMax();   							//reset brightness           
					roiManager("Update");
					roiManager("Split");
					setBatchMode(true); 	
									
					for (tt=1; tt<=9; tt++){ 							//split image into 9
						selectWindow(currImg);		
						roiManager("Select", tt);	
						Roi.getBounds(rx, ry, rw, rh);
						//if((rx>Iw)||(rx+rw<0)||(ry>Ih)||(ry+rh<0)){		//if roi is outside of image, does not work as position is reset to middle if outside					
						
						if((-floor(-(rx+(rw/2)))!=floor(Iw/2))&&(-floor(-(ry+(rh/2)))!=floor(Ih/2))){							//roi is exactly in middle (unlikely to happen by dragging manually								
							//print("inside");
							run("Duplicate...", "duplicate");	
				
							if (currslide<10){					
								if (ss<10){							//bringing Image and Segment number to two digits
									sa="0"+ss+1;}
								else {
									sa=ss+1;}
								if (tt<10){
									ta="0"+tt;}
								else {
									ta=tt;}
								titlenew = "Segment_" + ta + "_Slide_" + "0" + currslide + "_Image_" + sa;	
							}
							else {
								if (ss<10){							//bringing Image and Segment number to two digits
									sa="0"+ss+1;}
								else {
									sa=ss+1;}
								if (tt<10){
									ta="0"+tt;}
								else {
									ta=tt;}
								titlenew = "Segment_" + ta + "_Slide_" + currslide + "_Image_" + sa;
							}
							
							savesplit= path_all + "_I_Split/" + titlenew;							
							saveAs("Tiff", savesplit);																											
							//selectImage(currImg);  
							//close();	
						}
						else{
							print("skipped roi "+tt+" because is outside image "+currImg);
							//close();
						}
					}
					close();												
				}
				setBatchMode(false); 
				close("*");
				setKeyDown("none");				// reset shift 
			}
		}		// end if(imagesonslide[mm]>0){	
}		//  end for (mm=0; mm<imagesonslide.length; mm++){				//end split images


print("All images transformed and split!");
print("Job completed");

//====================================================================================================================================
