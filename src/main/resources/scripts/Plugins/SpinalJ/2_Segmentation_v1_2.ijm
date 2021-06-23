// SpinalJ Image pre-processing
// Rename files, Ordering, Segmentation of block section images
// Input file names should be in format SlideXX_... or SlideZ_XX	with X=slide number

// Author: 	Felix Fiederling
// Mason/Dodd lab | Zuckerman Institute, Columbia University
// Date:	4/28/2021

//Update 4/9/21
//Change order of operations:
//-Metadata extraction --> rename files to match slide order
//-Auto segmentation of images with 9 sections; save down-scaled images of files that can't be auto processed
//-open donw-scaled images for manual segmentation

//Update 4/19/21
//ignore non-image files when loading data

//Update 6/22/21
//fixed slide ordering bug, that prevented renaming files if the same filename was already assigned to another file
//fixed auto segmentation bug, resulting from decimal readung error when loading pre-processing (circularity) parameters
//memory usage reduced by garbage collection
//still have a "macro error" crash when running the script for the first time

SpinalJVer ="SpinalJ 1.1";
ReleaseDate= "4/28/2021";


//-----------------------------------------------------------------------------------------------------------------------------
//Load settings

#@ File(label="Image Data:", description="Subfolder containing spinal cord block section raw data", style="directory") input

start=getTime();
setBatchMode(true);           

if (File.exists(input + "/_Temp/_PreProcessing_Parameters.csv")) {
	ParamFile = File.openAsString(input + "/_Temp/_PreProcessing_Parameters.csv");
	ParamFileRows = split(ParamFile, "\n"); 		
} else {
	exit("Pre-processing Parameter file doesn't exist, please run Set Pre-processing Settings step for this folder first.");
}
       		
// Get Variables for running Reformt Series
path_data = LocateValue(ParamFileRows, "Directory_Data");
path_data=path_data+"/";    		     		
//Rotate = LocateValue(ParamFileRows, "Rotation");
Flip = LocateValue(ParamFileRows, "Flip");
sectionorder = LocateValue(ParamFileRows, "Slice Arrangement");
FileOrdering = LocateValue(ParamFileRows, "File Order");
Scale_Seg = LocateValue(ParamFileRows, "Scale Segmentation");
RefCh = parseInt(LocateValue(ParamFileRows, "Reference channel"));
path_masks = LocateValue(ParamFileRows, "Directory_Masks");
path_masks=path_masks+"/";
size_low = LocateValue(ParamFileRows, "Min Object Size");
size_high = LocateValue(ParamFileRows, "Max Object Size");
circ_low = LocateValue(ParamFileRows, "Min Circularity");
circ_high = LocateValue(ParamFileRows, "Max Circularity");
replace_lost=LocateValue(ParamFileRows, "Replace lost");
path_lost=LocateValue(ParamFileRows, "Directory_Lost");
path_lost=path_lost+"/";



//=======================================================================================================================
//Get list of images
data_list = getFileList(path_data); 			// list of all files
image_list = ImageFilesOnlyArray(data_list);

//image_list=newArray();
setOption("ExpandableArrays", true);
//j=0;
//for (i = 0; i < data_list.length; i++) {
//	if(startsWith(data_list[i], "_")==false){	// exclude files and folders that start with "_"
//		image_list[j]=data_list[i];
//		j=j+1;
//	}
//}
//Array.sort(image_list);			// list of all images 
//Array.show(image_list);

//replace all commas and spaces in filenames
for (i = 0; i < image_list.length; i++) {
	newname1=replace(image_list[i],",","_");  
	newname2=replace(newname1," ","_");
	newname3=replace(newname2, ".nd2", "_pre.nd2");				// add extenison to all filenames to avoid trouble when repeating this step and errors because of duplicated filenames
	File.rename(path_data+image_list[i], path_data+newname2);
}

//====================================================================================================================================
// Order files according to order on the slide (the slide scanner may scan and name images in a way that does not reflect order on the slide)

//Extract stage coordinates from metadata
path_temp=path_data+"_Temp/";
// use existing metadata if available 
if(File.exists(path_temp+"_Coordinates_Rows.txt")==1){	//YES, Coordinates already extracted
	print("Stage coordinates have been extracted before and will be re-used. Delete coordinate files to re-run metadata analysis");
	pathfile=path_temp+"_Images_per_Slide.txt";
	filestring=File.openAsString(pathfile);
	splitstring=split(filestring, ",,");
	imagesonslide=newArray(splitstring.length);
	for(i=0; i<splitstring.length; i++){
		imagesonslide[i]=parseFloat(splitstring[i]);
	}
	//load slide
	pathfile=path_temp+"_Slides.txt";
	filestring=File.openAsString(pathfile);
	splitstring=split(filestring, ",,");
	slide=newArray(splitstring.length);
	for(i=0; i<splitstring.length; i++){
		slide[i]=parseFloat(splitstring[i]);
	}
	slide=Array.sort(slide);
	//load allcoordinatesX
	pathfile=path_temp+"_Coordinates_X.txt";
	filestring=File.openAsString(pathfile);
	splitstring=split(filestring, ",,");
	allcoordinatesX=newArray(splitstring.length);
	for(i=0; i<splitstring.length; i++){
		allcoordinatesX[i]=parseFloat(splitstring[i]);
	}
	//load SlideRow
	pathfile=path_temp+"_Coordinates_Rows.txt";
	filestring=File.openAsString(pathfile);
	SlideRow=split(filestring, ",,");
	for(i=0; i<SlideRow.length; i++){
		SlideRow[i]=replace(SlideRow[i]," ","");		//remove spaces
		SlideRow[i]=replace(SlideRow[i],"\n","");		//remove line breaks
	}
}

else {		//extract metadata
	print("Extracting stage coordinates of images...");
	allcoordinatesX=newArray(image_list.length);				
	allcoordinatesY=newArray(image_list.length);
	slide = newArray(image_list.length);

	for (j=0; j<image_list.length; j++){ 
		if(lengthOf(image_list[j])>19){ //original filename from slide scanner (e.g. Slide1-03_....nd2)
			slidenumber = substring(image_list[j], 7, 9);
		}
		else if(lengthOf(image_list[j])==19){	//filename modified previously by SpinalJ (e.g. Slide03_....nd2)
			slidenumber = substring(image_list[j], 5, 7);
		}
		slidenumber = replace(slidenumber, "_", "");
		slidenumber = parseInt(slidenumber);
		slide[j]=slidenumber;
		
		if (j==0){
			print("Reading Metadata of file " + j+1 + " of " + image_list.length + " ...");
		}
		else {
			print("\\Update:" + "Reading Metadata of file " + j+1 + " of " + image_list.length + " ...");
		}
		run("Bio-Formats Macro Extensions");
		Ext.setId(path_data + image_list[j]);
		Ext.getMetadataValue("dXPos", XNum);
		Ext.getMetadataValue("dYPos", YNum);
		allcoordinatesX[j]=XNum;
		allcoordinatesY[j]=YNum;
		Ext.close();
	}
	close("*");

	//FIND HOW MANY IMAGES THERE ARE ON EACH SLIDE
	print("\\Clear");
	Array.print(slide);
	selectWindow("Log");
	saveAs(".txt", path_temp+"_Slides.txt");
	maxslide = Array.findMaxima(slide, 0);
	maxslide = slide[maxslide[0]];				//select first index if multiple maxima are found
	imagesonslide = newArray(maxslide);
	imagesonslide = Array.fill(imagesonslide, 0);
	for (uu=0; uu<slide.length; uu++){
		s=slide[uu];
		imagesonslide[s-1]= imagesonslide[s-1]+1; 
	}
	print("\\Clear");
	Array.print(imagesonslide);		//contains number of images for each slide
	selectWindow("Log");
	saveAs(".txt", path_temp+"_Images_per_Slide.txt");

	//SAVE COORDINATES AND SEPARATE BOT vs TOP ROW
	// slide coordinate range in Nikon slide scanner: 
	//x: ~29000 - 82000
	//y: ~20000 - 40500
	for(tt=0; tt<image_list.length; tt++){
		allcoordinatesX[tt]=parseInt(allcoordinatesX[tt]);
		allcoordinatesY[tt]=parseInt(allcoordinatesY[tt]); 
	}
	print("\\Clear");
	Array.print(allcoordinatesX);
	selectWindow("Log");
	saveAs(".txt", path_temp+"_Coordinates_X.txt");
	print("\\Clear");
	Array.print(allcoordinatesY);
	selectWindow("Log");
	saveAs(".txt", path_temp+"_Coordinates_Y.txt");


	//sort images based on in which row on the slide they are
	SlideRow = newArray(image_list.length);
	Y_row_low = 25000;								
	Y_row_high = 35000;
	tolerance = 5000;
	Y_row_low_max=Y_row_low+tolerance;	// 30000
	
	//section order: up
	if ((sectionorder=="Left and Up") || (sectionorder=="Right and Up")) {
		//print ("sectionorder up");
		errorcount=0;
		for(rr=0; rr<image_list.length; rr++){
			if(allcoordinatesY[rr]<=Y_row_low_max){	// <=30000
				SlideRow[rr]="top"; }
			else if(allcoordinatesY[rr]>Y_row_low_max) {	// >30000
				SlideRow[rr]="bottom"; }
			else{
				SlideRow[rr]="bottom";				//assign "bottom" if can't be assigned
				errorcount=errorcount+1;
			}
		}
	}
	//section order: down
	else if ((sectionorder=="Left and Down") || (sectionorder=="Right and Down")) {
		//print ("sectionorder down");
		errorcount=0;
		for(rr=0; rr<image_list.length; rr++){
			if(allcoordinatesY[rr]<=Y_row_low_max){	// <=30000
				SlideRow[rr]="bottom"; }
			else if(allcoordinatesY[rr]>Y_row_low_max) {	// >30000
				SlideRow[rr]="top"; }
			else{
				SlideRow[rr]="bottom";				//assign "bottom" if can't be assigned
				errorcount=errorcount+1;
			}
		}
	}

	print("\\Clear");
	Array.print(SlideRow);
	selectWindow("Log");
	saveAs(".txt", path_temp+"_Coordinates_Rows.txt");
	print("\\Clear");
	print("Extracting stage coordinates of images...");
	Array.print(allcoordinatesX);
	Array.print(allcoordinatesY);
	Array.print(SlideRow);
	Array.print(imagesonslide);
	print("Metadata extraction complete! Image stage coordinates saved!");
	if(errorcount>0){
		print("Warning: " + errorcount + " images could not be assigned to either top or bottom row of slide!");	
	}
}	 
//---------------------------------------------------------------------------------------------------------------------------

//Rename files to match slide order using stage coordinates
print("Ordering files based on stage coordinates...");
//get images into correct order
for (mm=0; mm<imagesonslide.length; mm++){	//loop through all slides
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
					currfiles[nn]=image_list[oo];			//filenames of images on current slide
					currX[nn] = allcoordinatesX[oo];	//x-coordinates of images on current slide
					currrow[nn] = SlideRow[oo];			//row information of images on current slide
					nn=nn+1;
					slide[oo] = NaN; 
				}	
			}
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
				//print("top detected");
				currXtop[pp]=currX[pp];
				currfilestop[pp]=currfiles[pp];
			}
			else if (currrow[pp]=="bottom"){
				//print("bottom detected");
				currXbot[pp]=currX[pp];
				currfilesbot[pp]=currfiles[pp];
				//print(currXbot[pp]);
			}
		}
		currXtop = Array.deleteValue(currXtop, 0);
		currXbot = Array.deleteValue(currXbot, 0);
		currfilestop = Array.deleteValue(currfilestop, 0);
		currfilesbot = Array.deleteValue(currfilesbot, 0);
				
		//sort images based on X coordinates
		ranktop = Array.rankPositions(currXtop); 
		rankbot = Array.rankPositions(currXbot);
		for (u=0; u<rankbot.length;u++){				//continuous ranks
			rankbot[u] = rankbot[u]+ranktop.length;
		}
		slideorder = newArray(currnumber);
		ri = 0;
		
		//section order: left
		if ((sectionorder=="Left and Up") || (sectionorder=="Left and Down")) {
			//print ("sectionorder left");
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
			}	
		}		

		//section order: right
		else if ((sectionorder=="Right and Up") || (sectionorder=="Right and Down")) {
			//print ("sectionorder right");
			ranktop=Array.reverse(ranktop);
			rankbot=Array.reverse(rankbot);
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
			}	
		}		
		
		print("\\Clear");
		Array.print(slideorder);
		selectWindow("Log");
		saveAs(".txt", path_temp+"_Slide_"+ currslide +"_ordered.txt");
		print("Ordering complete!");
		print("Renaming image files to match sectioning order...");
		slnum=IJ.pad(currslide, 2);							//padded slide number (e.g. 03 or 15)


		// rename files based on stage coordinates and slide order
		for (i = 0; i < currnumber ; i++) { 
			imnum=IJ.pad(i+1, 2); 							//padded image number 
			oldname=path_data+slideorder[i];
			//oldname=replace(oldname,".nd2", "_re.nd2");
			newname=path_data+"Slide"+slnum+"_Image"+imnum+".nd2";
			File.rename(oldname, newname);  
		}
		close("*");
	}
}

print("Renaming complete!");


//==============================================================================================================================================================
//Segment images

print("Segmenting images to isolate tissue sections...");
data_list_ordered=getFileList(path_data);
image_list_ordered=newArray();
setOption("ExpandableArrays", true);
j=0;
for (i = 0; i < data_list_ordered.length; i++) {
	if(startsWith(data_list_ordered[i], "_")==false){	// exclude files and folders that start with "_"
		image_list_ordered[j]=data_list_ordered[i];
		j=j+1;
	}
}
image_list_ordered=Array.sort(image_list_ordered); 
path_split=path_temp+"_I_Split/";
if(File.isDirectory(path_split)==false){	//check if has been run before
	File.makeDirectory(path_split);
}
else{
	print("Images have been segmented before! Delete folder '/_Temp/_I_Split/' and '/_Temp/_0_Scaled/' to re-run segmentation.");
	skip_segmentation="yes";
}

path_scaled=path_temp+"_0_Scaled/";
if(File.isDirectory(path_scaled)==false){
	File.makeDirectory(path_scaled);
}
else{
	print("Images have been segmented before! Delete folder '/_Temp/_I_Split/' and '/_Temp/_0_Scaled/' to re-run segmentation.");
	skip_segmentation="yes";
}


//if (skip_segmentation!="yes") {		///////////////

count_auto=0;
count_manual=0;

for (im=0; im<image_list_ordered.length; im++){
	SegmentStart = getTime();		
	run("Bio-Formats Windowless Importer", "open=[" + path_data + image_list_ordered[im] + "] color_mode=Default rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT");
	currImg = getTitle();
	title = replace(image_list_ordered[im], ".nd2", ""); 
	print("Auto-segmenting image "+im+1+" of "+image_list_ordered.length+" ...");
	//print(size_low+","+size_high+","+ circ_low +","+ circ_high);
	//print(image_list_ordered[im]);
	//Flip image according to user input
	if (Flip=="vertical flip (up-down)"){
		run("Flip Vertically", "stack");    }
	if (Flip=="horizontal flip (left-right)"){
		run("Flip Horizontally", "stack");  }
	if (Flip=="vertical and horizontal flip"){
	    run("Flip Vertically", "stack");
	   	run("Flip Horizontally", "stack");  }

	//attempt auto segmentation

	Stack.setChannel(RefCh);
    run("Duplicate...", "title="+RefCh); //duplicate ref channel
	selectWindow(RefCh);
	run("Enhance Contrast", "saturated=0.35");
	run("8-bit");
	setAutoThreshold("Mean dark"); //threshold sections
	run("Convert to Mask");
	run("Fill Holes");
	roiManager("reset");
	//size_low=1000000;
	//size_high=5000000;
	//circ_low=0.05;
	//circ_high=1;
	run("Analyze Particles...", "size="+size_low+"-"+size_high+" pixel circularity="+circ_low+"-"+circ_high+" show=Nothing include add"); //analyze particles
	//run("Analyze Particles...", "size=1000000-5000000 pixel circularity=0.05-1.00 show=Nothing include add");
	run("Clear Results");
	roiManager("Measure");
	//selectWindow(RefCh); close();

	if (roiManager("count")==9){ //check if exactly 9 particles detected
		print("Auto-segmentation successful!");
		count_auto=count_auto+1;
		n_rows = 3;	n_cols =3;
		col = newArray("A", "B", "C");	row = newArray("A", "B", "C");
		run("Set Measurements...", "area centroid redirect=None decimal=0");
		for(r=0; r<n_rows; r++) {		//sort particles based on grid position
			xCoords = newArray();
				for(c=0; c<n_cols; c++) {;
					roiManager("select", ((n_cols) * r) + c);
					getSelectionBounds(x, y, width, height);  
					xCoords = Array.concat(xCoords, x);
				}	
				rankPositions = Array.rankPositions(Array.rankPositions(xCoords));
				for(c=0; c<n_cols; c++) {
					roiManager("select", n_cols * r + c);
					roiManager("rename", row[r] + "-" + col[rankPositions[c]]);
				}	
			}
		roiManager("deselect");
		roiManager("Sort");
		for (i=0; i<roiManager("count"); i++) {
			roiManager("select", i);
			roiManager("Rename", i+1); 
		}
		run("Clear Results");
		roiManager("deselect");
		//roiManager("Show None");
		//roiManager("Show All");
		roiManager("Measure");
		//crop and save single sections
		crop_width=3200;
		crop_height=2800;
		
		for (h = 0; h < 9; h++) {
			selectWindow(currImg);
			makeRectangle(getResult("X",h)-floor(crop_width/2),getResult("Y",h)-floor(crop_height/2),crop_width,crop_height);
			run("Duplicate...", "duplicate"); //duplicate crop
			saveAs(".tiff", path_split+"Segment"+IJ.pad(h+1,2)+"_"+title+".tif"); //save 
			close();
		}
		close("*");
	} 
	
	
	else {		//if autosegmentation fails: save as down-scaled image
		print("Auto-segmentation failed... saving down-sampled image for manual segmentation");
		count_manual=count_manual+1;
		//open image
		run("Bio-Formats Windowless Importer", "open=[" + path_data + image_list_ordered[im] + "] color_mode=Default rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT");
		// it's possible to open only the channel you need - but could create issues for other file formats?
		rename("raw");
		//duplicate ref channel
		run("Duplicate...", "title=RawCh duplicate channels="+RefCh);
		close("raw");
		run("Enhance Contrast", "saturated=0.35");
		//scale down (0.1x)
		run("Scale...", "x=0.1 y=0.1 interpolation=Bilinear average create");
		run("8-bit");
		//save
		scaled_tit=getTitle();
		//print(scaled_tit);
		selectWindow(scaled_tit);
		saveAs(".tiff", path_scaled+image_list_ordered[im]);
		close("*");
	}	

	if (im == 0) {
		Segmentend = getTime();
		Segmenttime = (Segmentend-SegmentStart)/1000;
		print("  Processing time for one image = " +parseInt(Segmenttime)+ " seconds. Total time for segmenting images will be ~"+(parseInt((Segmenttime*image_list_ordered.length)/60)), "minutes.");
	}
	close("*");
	collectGarbage(4, 4);
}
close("*");
print("Auto-segmentation completed for "+count_auto+" of "+image_list_ordered.length+" images! "+count_manual+" images require manual segmentation.");  


collectGarbage(4, 4);

//==================================================================================================================
//manual segmentation

//place segmentation mask on down-scaled images
image_list_manual=getFileList(path_scaled);
run("ROI Manager...");
mask = path_masks + "/Split_mask.roi";
mask_scaled = path_masks + "/Split_mask_scaled.roi"; 
Cx=newArray(image_list_manual.length);
Cy=newArray(image_list_manual.length);
for (m=0; m<image_list_manual.length; m++){
	open(path_scaled + image_list_manual[m]);
	//Flip image according to user input
	if (Flip=="vertical flip (up-down)"){
		run("Flip Vertically", "stack");    }
	if (Flip=="horizontal flip (left-right)"){
		run("Flip Horizontally", "stack");  }
	if (Flip=="vertical and horizontal flip"){
		run("Flip Vertically", "stack");
		run("Flip Horizontally", "stack");  }
	setBatchMode("show");
	roiManager("reset");													
	roiManager("Open", mask_scaled);  
	roiManager("Select", 0);                           
	setTool(0);                                                                         
	waitForUser("Position mask to split image, then click OK. \nShift+click OK to skip");	//position mask 
	if (isKeyDown("Shift") == true) {				//check if shift key has been used to skip
    	//skip  
    	Cx[m]=-1000000;	//if skipped, make roi outside of image so that they are ignored when splitting image!!
  		Cy[m]=-1000000;			
    }
	else { 							      
		roiManager("Update");
		//get center coordinates
  		Roi.getBounds(mx, my, mwidth, mheight);	//x,y: coordinates of top left corner
  		//print(mx); print(my); print(mwidth); print(mheight);
  		//center of ROI
  		Cx[m]=floor(mx+(mwidth/2));
  		Cy[m]=floor(my+(mheight/2));			
	}
	close("*");
	setKeyDown("none");				// reset shift 
}

//save coordinates 
print("\\Clear");
Array.print(Cx);
selectWindow("Log");
saveAs(".txt", path_temp+"_ROI_X.txt");
	
print("\\Clear");
Array.print(Cy);
selectWindow("Log");
saveAs(".txt", path_temp+"_ROI_Y.txt");

collectGarbage(4, 4);

// split images using manual segmentation info
print("Manual segmentation parameters saved. Segmenting images ...");
cnt=0;
for (ss=0; ss<image_list_manual.length; ss++){
	ImageStart = getTime();		
	run("Bio-Formats Windowless Importer", "open=[" + path_data + replace(image_list_manual[ss],".tif",".nd2") + "] color_mode=Default rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT");
	Stack.setChannel(RefCh);
	currImg = getTitle();
	title = replace(image_list_manual[ss], ".tif", ""); 
	//Flip image according to user input
	if (Flip=="vertical flip (up-down)"){
		run("Flip Vertically", "stack");    }
	if (Flip=="horizontal flip (left-right)"){
		run("Flip Horizontally", "stack");  }
	if (Flip=="vertical and horizontal flip"){
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
	
	Cx_scaled=Cx[ss]*10;
	Cy_scaled=Cy[ss]*10;
	//print(Cy_scaled); print(Cx_scaled);			
	//move mask to determined coordinates
	getSelectionBounds(x_current, y_current, w_current, h_current);
	dx=Cx_scaled-x_current-floor(w_current/2);
	dy=Cy_scaled-y_current-floor(h_current/2);
	//print(dx); print(dy);
	setSelectionLocation(x_current+dx, y_current+dy);
	roiManager('update');
	setTool(0);
	resetMinAndMax();   							//reset brightness           
	roiManager("Update");
	roiManager("Split");
							
	//split image into 9			
	for (tt=1; tt<10; tt++){ 							
		selectWindow(currImg);		
		roiManager("Select", tt);	
		Roi.getBounds(rx, ry, rw, rh);
				
		if((-floor(-(rx+(rw/2)))!=floor(Iw/2)) && (-floor(-(ry+(rh/2)))!=floor(Ih/2)) && (rx>0) && (ry>0)){			//triggered unless roi is exactly in middle (indication of position reset and unlikely to happen by dragging manually) 					
			if((rx>Iw)||(rx+rw<0)||(ry>Ih)||(ry+rh<0)){		//does not work, as roi position is reset to middle if outside of image 						
				print("skipped roi "+tt+" because is outside image "+currImg);
			}
			else{
				run("Duplicate...", "duplicate");
				titlenew="Segment"+IJ.pad(tt,2)+"_"+title+".tif";
				savesplit= path_split + titlenew;							
				saveAs("Tiff", savesplit);																											
				//selectImage(currImg);  
				close();	

				if (cnt == 0) {
					ImageEnd = getTime();
					ImageTime = (ImageEnd-ImageStart)/1000;
					print("  Processing time for one image = " +parseInt(ImageTime)+ " seconds. Total time to segment all images ~"+(parseInt((ImageTime*image_list_manual.length)/60)), "minutes.");
				}	
				cnt=1;
			}
		}
		else{
			print("skipped roi "+tt+" because is outside image "+currImg);
			//close();
		}
	}
	close("*");
	setKeyDown("none");				// reset shift 
	collectGarbage(4, 4);
}

print("Manual segmentation complete!");
print("Segmentation complete!");

  

//====================================================================================================================================								
//replace lost sections

//requires notes of sections that have been lost on sectioning in form of a csv table with column "Slide" and "Section".
//Slide: # of slide 
//Section: position on slide where lost section would have been collected (1-8)
//duplicate entry if consecutive sections have been lost

//example:
//	Slide		Section
//	3			2
//  3			6
//	12			8
//	12			8

//this script will search folder "I_Split" (single section images) for images of existing sections that match slide/position 
//indicated in missing sections list and duplicate those.

//example:
//Slide 5, Section 3 is missing
//Images found and duplicated:
//0044_Segment_01_Slide_05_Image_03
//0098_Segment_02_Slide_05_Image_03
//0133_Segment_03_Slide_05_Image_03
//0184_Segment_04_Slide_05_Image_03
//0399_Segment_07_Slide_05_Image_03
//0487_Segment_08_Slide_05_Image_03

//lost sections

if(replace_lost=="yes"){	//compensate for lost sections
	print("Replaceing lost sections...");
	if(File.exists(path_lost+"_Lost_Sections.csv")==false){
		list=File.openDialog("List of lost sections '_Lost_Sections.csv' not found. Please specify file location!");
		open(list);
	}
	else{
		open(path_lost+"_Lost_Sections.csv");
	}
	title=Table.title;
	Table.rename(title, "Results");
	nlost=nResults;
	lostslide=newArray(nlost);
	lostsection=newArray(nlost);
	lostslidesection=newArray(nlost);
	for (i = 0; i < nlost; i++) {
		if(getResult("Slide",i)>9){
			lostslide[i]=d2s(getResult("Slide",i), 0);
		}
		else {
			lostslide[i]="0"+d2s(getResult("Slide",i), 0);//getResult("Slide",i);
		}
		lostsection[i]="0"+d2s(getResult("Section",i), 0);//getResult("Section",i);
		lostslidesection[i]=lostslide[i]+lostsection[i];
	}
	selectWindow("Results"); 
	run("Close" );
	
	//existing sections
	fileListsplit = getFileList(path_split); 
	setOption("ExpandableArrays", true);
	fileList=newArray;
	ff=0;
	for (f=0; f<fileListsplit.length; f++){
		if (endsWith(fileListsplit[f], ".tif")){
			fileList[ff]=fileListsplit[f];
			ff=ff+1;
		}
	}
	fileListsort=Array.sort(fileList);
	
	//extract segment, slide, image info
	segment=newArray(fileListsort.length);
	slide=newArray(fileListsort.length);
	section=newArray(fileListsort.length);
	slidesection=newArray(fileListsort.length);
	
	for (i=0; i<fileListsort.length; i++) {
		spl=split(fileListsort[i], "_");
		segment[i]=replace(spl[0],"Segment","");
		slide[i]=replace(spl[1],"Slide","");
		section[i]=replace(spl[2],"Image",""); section[i]=replace(section[i],".tif","");
		if (lengthOf(section[i])>2){
			section[i]=substring(section[i], 1);
			}
		slidesection[i]=slide[i]+section[i];
	}
		
	//find replacement for lost section
	//find and count lostslidesection[i] in slidesection
	rep=newArray(lostslidesection.length);
	frep=newArray;
	k=0;
	for (i = 0; i < lostslidesection.length; i++) {
		for (j = 0; j < slidesection.length; j++) {
			if(lostslidesection[i]==slidesection[j]){
				rep[i]=slidesection[j];		
				frep[k]=fileListsort[j];
				k=k+1;
			}
		}
	}
	for (i =0; i<rep.length; i++) {
		if(rep[i]==0){
			print("Warning: no replacement sections found for "+lostslidesection[i]);
		}
	}
	//duplicate replacements for lost sections
	for(r=0; r<frep.length; r++){
		replacement=frep[r];
		path_rep=path_split+replacement;
		a=0;
		path_copy=replace(path_rep,".tif","_copy"+a+".tif");
		check=0;
		while(check==0){
			if(File.exists(path_copy)==true){
				//print("file exists "+path_copy);
				a=a+1;
				path_copy=replace(path_rep,".tif","_copy"+a+".tif");
			}
			else{
				check=1;
			}
		}
		File.copy(path_rep, path_copy);
	}
	print("Replacing lost sections completed!");	
}

collectGarbage(4, 4);
end=getTime();
duration=(end-start)/60000;
print("Script completed in " + duration + " minutes.");





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


function ImageFilesOnlyArray (arr) {
	//pass array from getFileList through this e.g. NEWARRAY = ImageFilesOnlyArray(NEWARRAY);
	setOption("ExpandableArrays", true);
	f=0;
	files = newArray;
	for (i = 0; i < arr.length; i++) {
		if(endsWith(arr[i], ".tif") || endsWith(arr[i], ".nd2") || endsWith(arr[i], ".LSM") || endsWith(arr[i], ".czi") || endsWith(arr[i], ".jpg") ) {   //if it's a tiff image add it to the new array
			files[f] = arr[i];
			f = f+1;
		}
	}
	arr = files;
	arr = Array.sort(arr);
	return arr;
}


function collectGarbage(slices, itr){
	setBatchMode(false);
	wait(1000);
	for(i=0; i<itr; i++){
		wait(50*slices);
		run("Collect Garbage");
		call("java.lang.System.gc");
		}
	setBatchMode(true);
}
