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
Rotate = LocateValue(ParamFileRows, "Rotation");
Flip = LocateValue(ParamFileRows, "Flip");
SectionArrangement = LocateValue(ParamFileRows, "Slice Arrangement");
FileOrdering = LocateValue(ParamFileRows, "File Order");
Scale_Seg = LocateValue(ParamFileRows, "Scale Segmentation");
RefCh = parseInt(LocateValue(ParamFileRows, "Reference channel"));
path_masks = LocateValue(ParamFileRows, "Directory_Masks");
path_masks=path_masks+"/";
replace_lost=LocateValue(ParamFileRows, "Replace lost");
path_lost=LocateValue(ParamFileRows, "Directory_Lost");
path_lost=path_lost+"/";


	
data_list = getFileList(path_data); 			// list of all files
image_list=newArray();
setOption("ExpandableArrays", true);
j=0;
for (i = 0; i < data_list.length; i++) {
	if(startsWith(data_list[i], "_")==false){	// exclude files and folders that start with "_"
		image_list[j]=data_list[i];
		j=j+1;
	}
}
	
Array.sort(image_list);			// list of all images 

//====================================================================================================================================
// Order files according to order on the slide (the slide scanner may scan and name images in a way that does not reflect order on the slide)

path_temp=path_data+"_Temp/";

// use existing coordinates if available 
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
		
		//slide information
		slidenumber = substring(image_list[j], 7, 9);
		slidenumber = replace(slidenumber, "_", "");
		slidenumber = parseInt(slidenumber);
		slide[j]=slidenumber;
		//print(slidenumber);
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
		//run("Close");
	}
	//setBatchMode(false);
	close("*");
//-------------------------------------
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
		imagesonslide[s-1]= imagesonslide[s-1]+1; }
		
	print("\\Clear");
	Array.print(imagesonslide);		//contains number of images for each slide
	selectWindow("Log");
	saveAs(".txt", path_temp+"_Images_per_Slide.txt");
//----------------------------------------
	//SAVE COORDINATES AND SEPARATE BOT vs TOP ROW
	// slide coordinate range in Nikon slide scanner: 
	//x: ~29000 - 82000
	//y: ~20000 - 40500
	
	for(tt=0; tt<image_list.length; tt++){
		allcoordinatesX[tt]=parseInt(allcoordinatesX[tt]);
		allcoordinatesY[tt]=parseInt(allcoordinatesY[tt]); }

	print("\\Clear");
	Array.print(allcoordinatesX);
	selectWindow("Log");
	saveAs(".txt", path_temp+"_Coordinates_X.txt");

	print("\\Clear");
	Array.print(allcoordinatesY);
	selectWindow("Log");
	saveAs(".txt", path_temp+"_Coordinates_Y.txt");

	SlideRow = newArray(image_list.length);
	reference_bot = 25000;								
	reference_top = 35000;
	tolerance = 5000;
	bot_max=reference_bot+tolerance;	// 30000
	
	errorcount=0;

	for(rr=0; rr<image_list.length; rr++){
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
	saveAs(".txt", path_temp+"_Coordinates_Rows.txt");
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

//====================================================================================================================================

path_temp=path_data+"_Temp/";
if (File.isDirectory(path_temp)==false){
	File.makeDirectory(path_temp);
}

// scale-down images for segmentation
if (Scale_Seg=="yes") {
	path_scaled=path_temp+"_0_Segmentation_Scaled_Images/";
	//check if has been run before
	if (File.isDirectory(path_scaled)==true){	//check if pre-scaled images have been created before
		print("Images have been down-scaled before and will be re-used. Delete files to re-run scaling");
	}
	else{		//down-scale images
		File.makeDirectory(path_scaled);  
		print("\\Update6:Scaling image " + 1 + " of " + image_list.length + " ...");
		//setBatchMode(true);	//Batchmode messes up saving: if active, image is saved before scaling!
		for (p=0; p<image_list.length; p++){
			print("\\Update6:Scaling image " + p+1 + " of " + image_list.length + " ..."); 
			Scalestart = getTime();
			//open image
			run("Bio-Formats Windowless Importer", "open=[" + path_data + image_list[p] + "] color_mode=Default rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT");
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
			saveAs(".tiff", path_scaled+image_list[p]);
			close("*");
			if (p == 0) {
				Scaleend = getTime();
				Scaletime = (Scaleend-Scalestart)/1000;
				print("  Processing time for one image = " +parseInt(Scaletime)+ " seconds. Total time for rescaling images will be ~"+(parseInt((Scaletime*image_list.length)/60)), "minutes.");
			}
		}
		
		print("Scaling complete!");
	}

	//check if segmentation masks have been placed before
	if ((File.exists(path_temp + "_ROI_X.txt")==true) && (File.exists(path_temp + "_ROI_Y.txt")==true)){	//check if ROI coordinates have been saved before
		print("Segmentation masks have been placed before and coordinates will be re-used. Delete files to re-run mask placement");
		
		//load existing ROI coordinates
		Cx_str=File.openAsString(path_temp+"_ROI_X.txt");
		Cx_str_sp=split(Cx_str, ",,");
		Cx=newArray(Cx_str_sp.length);
		for(i=0; i<Cx_str_sp.length; i++){
			Cx[i]=parseFloat(Cx_str_sp[i]);
		}
		Cy_str=File.openAsString(path_temp+"_ROI_Y.txt");
		Cy_str_sp=split(Cy_str, ",,");
		Cy=newArray(Cy_str_sp.length);
		for(i=0; i<Cy_str_sp.length; i++){
			Cy[i]=parseFloat(Cy_str_sp[i]);
		}

	}
		
	else{		//place segmentation mask on pre-scaled images
		run("ROI Manager...");
		mask_scaled = path_masks + "/Split_mask_scaled.roi"; 
		Cx=newArray(image_list.length);
		Cy=newArray(image_list.length);
		for (m=0; m<image_list.length; m++){
    		//run("Bio-Formats Windowless Importer", "open=[" + path_scaled + image_list[m] + "] color_mode=Default rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT");
			open(replace(path_scaled + image_list[m],"nd2","tif"));
			
			//transform image according to user input
			if (Flip=="vertical flip (up-down)"){
	    		run("Flip Vertically");    
	    	}
    		else if (Flip=="horizontal flip (left-right)"){
    			run("Flip Horizontally");  
    		}
    		else if (Flip=="vertical and horizontal flip"){
    			run("Flip Vertically");
    			run("Flip Horizontally");  
    		}
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
	}
}

//----------------------------------------------------------------------------------------------------------------------------					
// SPLIT IMAGES
print("Transforming and splitting images...");
path_split=path_temp+"_I_Split/";

//check if has been run before
if(File.isDirectory(path_split)==false){
	File.makeDirectory(path_split);
	mask = path_masks + "/Split_mask.roi";
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
						currfiles[nn]=image_list[oo];			//filenames of images on current slide
						currX[nn] = allcoordinatesX[oo];	//x-coordinates of images on current slide
						currrow[nn] = SlideRow[oo];			//row information of images on current slide
						nn=nn+1;
						slide[oo] = NaN; 
						}	
					}
					//Array.print(currfiles);
					//Array.print(currX);
					//Array.print(currrow);
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
				//Array.print(currXtop);							//contains X-coordinates of images in top row of current slide
				//Array.print(currXbot);							//contains X-coordinates of images in bottom row of current slide
				//Array.print(currfilestop);	
				//Array.print(currfilesbot);	
	
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
				//Array.print(slideorder);
				selectWindow("Log");
				saveAs(".txt", path_temp+"_Slide_"+ currslide +"_ordered.txt");
				print("All imges sorted according to slide position!");
				print("Segmenting images...");
				close("*");
				
				//OPEN AND TRANSFORM IMAGE, SAVE SEGMENTED TILES  
				for (ss=0; ss<slideorder.length; ss++){
					ImageStart = getTime();		
					//run("Bio-Formats Macro Extensions");
					run("Bio-Formats Windowless Importer", "open=[" + path_data + slideorder[ss] + "] color_mode=Default rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT");
	   				Stack.setChannel(RefCh);
	   				currImg = getTitle();
					title = replace(slideorder[ss], ".nd2", ""); 
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
					
					if (Scale_Seg=="no") {  // Mask placement on original images 
						setBatchMode("show");
						run("ROI Manager...");
						setTool(0);                                                                          
						waitForUser("Position mask to split image or Shift+click OK to skip");	//position mask   
						if (isKeyDown("Shift") == true) {				//check if shift key has been used to skip
	        				//skip  			
	        				}
						else {
		  				resetMinAndMax();   							//reset brightness           
						roiManager("Update");
						roiManager("Split");
						}
					}
					else if (Scale_Seg=="yes") {  // Mask placement on pre-scaled images 
						//get index of current image to match coordinates
						for (e=0; e<image_list.length; e++) {
							if(image_list[e]==slideorder[ss]){
								curr_ID=e;
								//print("curr_ID of file" + slideorder[ss] + " =" + curr_ID);
							}
						}
						//print(curr_ID);
						Cx_scaled=Cx[curr_ID]*10;
						Cy_scaled=Cy[curr_ID]*10;
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
					}
						
					//split image into 9
					//setBatchMode(true); 					
					for (tt=1; tt<=9; tt++){ 							
						selectWindow(currImg);		
						roiManager("Select", tt);	
						Roi.getBounds(rx, ry, rw, rh);
						//if((rx>Iw)||(rx+rw<0)||(ry>Ih)||(ry+rh<0)){		//does not work, as roi position is reset to middle if outside of image 					
							
						if((-floor(-(rx+(rw/2)))!=floor(Iw/2)) && (-floor(-(ry+(rh/2)))!=floor(Ih/2)) && (rx>0) && (ry>0)){			//triggered unless roi is exactly in middle (indication of position reset and unlikely to happen by dragging manually) 					
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
								
								savesplit= path_split + titlenew;							
								saveAs("Tiff", savesplit);																											
								//selectImage(currImg);  
								//close();	
						}
						else{
							print("skipped roi "+tt+" because is outside image "+currImg);
							//close();
						}
					}
					close("*");
					//setBatchMode(false);
					if (ss == 0) {
						ImageEnd = getTime();
						ImageTime = (ImageEnd-ImageStart)/1000;
						print("  Processing time for one image = " +parseInt(ImageTime)+ " seconds. Total time for all images ~"+(parseInt((ImageTime*slideorder.length)/60)), "minutes.");
					}									
				}
				close("*");
				setKeyDown("none");				// reset shift 
			
		}		// end if(imagesonslide[mm]>0){	
	}		//  end for (mm=0; mm<imagesonslide.length; mm++){				//end split images
}
else {
	print("Images already segmented. Delete folder '_Temp/_I_Split/' to re-run segmentation");
}

print("Segmentation completed!");


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
		segment[i]=spl[1];
		slide[i]=spl[3];
		section[i]=replace(spl[5],".tif","");
		if (lengthOf(section[i])>2){
			section[i]=substring(section[i], 1);
			}
		slidesection[i]=slide[i]+section[i];
	}
	
	//Array.show(slidesection);
	print("Replacing lost sections...");
	
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
	//Array.show(frep);

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
