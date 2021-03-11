//FF 7/28/2020
//Horizontal alignment of spinal cord sections.
//
//Cross section images (DAPI or Neurotrace) are processed for gray matter segmentation, split vertically and the left half 
//is flipped and overlayed on right half. The difference image is calculated for various rotation angles of the original image.
//The difference image that produces the smallest mean intensity indicates horizontal alignment.
//
//A number of si random images are analyzed from each tissue piece and the averaged rotation angle is applied to all raw images 
//of the corresponding tissue piece.
// 
//Alignment analysis is performed on "IV_Preview_Clean/_Preview_Stack_Clean.tif"
//Masking of sections is performed on channel specified as "MaskCh"
//Alignment is performed on images in "III_Clean/" and aligned images are saved to "III_Clean/1_Reformatted_Sections/"

 //------------------------------------------------------------------------------------------------------------------------------

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
save_temp = "no";	//LocateValue(ParamFileRows, "Save temp output");
MaskCh = parseInt(LocateValue(ParamFileRows, "Masking channel"));
thresh = LocateValue(ParamFileRows, "Threshold option for masking");
si = parseInt(LocateValue(ParamFileRows, "Horizontal Alignment Sampling interval"));
angle_min = parseInt(LocateValue(ParamFileRows, "Minimal test angle"));
angle_max = parseInt(LocateValue(ParamFileRows, "Maximal test angle"));
angle_incr = parseInt(LocateValue(ParamFileRows, "Test angle increment"));


path_temp = path_data + "_Temp/";
path_clean = path_temp + "_III_Clean/";
path_cleanprev = path_temp + "_IV_Preview_Clean/";	

path_horalign = path_temp + "_V_Horizontal_Alignment_Data/";
path_out = path_data + "_Output/";
path_reformat = path_out + "1_Reformatted_Sections/";

File.makeDirectory(path_horalign);
File.makeDirectory(path_out);
File.makeDirectory(path_reformat);

//-------------------------------------------------------------------------------------------------------------------------------
start = getTime();
setBatchMode(true);

sections_all=getFileList(path_cleanprev);
setOption("ExpandableArrays", true);
run("Colors...", "foreground=white background=black selection=yellow");

sections_01=newArray(sections_all.length);				//filelist of all sections of segment 1
sections_02=newArray(sections_all.length);
sections_03=newArray(sections_all.length); 
sections_04=newArray(sections_all.length); 
sections_05=newArray(sections_all.length);
sections_06=newArray(sections_all.length); 
sections_07=newArray(sections_all.length);
sections_08=newArray(sections_all.length);
sections_09=newArray(sections_all.length);

sections_analysis01=newArray();							//filelist of sections of segment 1 chosen for orientation analysis
sections_analysis02=newArray();
sections_analysis03=newArray();
sections_analysis04=newArray();
sections_analysis05=newArray();
sections_analysis06=newArray();
sections_analysis07=newArray();
sections_analysis08=newArray();
sections_analysis09=newArray();


//create filelist for each tissue segment; not sorted!
for (t=1; t<10; t++){
	for (s=0; s<sections_all.length; s++) {
		if (matches(sections_all[s], ".*Segment_0"+t+".*")) {	
			if (t==1){
				sections_01[s]=sections_all[s];}
			else if (t==2){
				sections_02[s]=sections_all[s];}
			else if (t==3){
				sections_03[s]=sections_all[s];}
			else if (t==4){
				sections_04[s]=sections_all[s];}
			else if (t==5){
				sections_05[s]=sections_all[s];}
			else if (t==6){
				sections_06[s]=sections_all[s];}
			else if (t==7){
				sections_07[s]=sections_all[s];}
			else if (t==8){
				sections_08[s]=sections_all[s];}
			else if (t==9){
				sections_09[s]=sections_all[s];}
		}
	}
}
//delete empty entries
sections_01=Array.deleteValue(sections_01, 0); 
sections_02=Array.deleteValue(sections_02, 0); 
sections_03=Array.deleteValue(sections_03, 0); 
sections_04=Array.deleteValue(sections_04, 0); 
sections_05=Array.deleteValue(sections_05, 0); 
sections_06=Array.deleteValue(sections_06, 0); 
sections_07=Array.deleteValue(sections_07, 0); 
sections_08=Array.deleteValue(sections_08, 0); 
sections_09=Array.deleteValue(sections_09, 0); 

//determine rotation angle for each tissue segment
//number of sections in each segment
nsections=newArray(9);
nsections[0]=sections_01.length;
nsections[1]=sections_02.length;
nsections[2]=sections_03.length;
nsections[3]=sections_04.length;
nsections[4]=sections_05.length;
nsections[5]=sections_06.length;
nsections[6]=sections_07.length;
nsections[7]=sections_08.length;
nsections[8]=sections_09.length;
								
//randomly choose sections for analysis
for (a=0; a<si; a++){
	sections_analysis01[a]=sections_01[floor(random*nsections[0])];
	sections_analysis02[a]=sections_02[floor(random*nsections[1])];
	sections_analysis03[a]=sections_03[floor(random*nsections[2])];
	sections_analysis04[a]=sections_04[floor(random*nsections[3])];
	sections_analysis05[a]=sections_05[floor(random*nsections[4])];
	sections_analysis06[a]=sections_06[floor(random*nsections[5])];
	sections_analysis07[a]=sections_07[floor(random*nsections[6])];
	sections_analysis08[a]=sections_08[floor(random*nsections[7])];
	sections_analysis09[a]=sections_09[floor(random*nsections[8])];
}


//setBatchMode(true);
//pre-process analysis images
for (a=0; a<si; a++){						//1
	path_horalign_1=path_horalign+"1/";
	File.makeDirectory(path_horalign_1);
	open(path_cleanprev+sections_analysis01[a]);
	run("Scale...", "x=- y=- z=1.0 width=300 height=300 interpolation=Bilinear average process create");
	currimg=getTitle();
	run("Duplicate...", " ");																		//create mask
	//run("Enhance Contrast...", "saturated=1");
	//setAutoThreshold("MinError dark");
	setAutoThreshold(thresh);
	run("Convert to Mask");
	run("Dilate");
	run("Fill Holes");
	roiManager("reset");
	run("Analyze Particles...", "size=10000-Infinity pixel show=Nothing include add");				//find section
	selectWindow(currimg);
	roiManager("Select", 0);
	run("Crop");
	run("Clear Outside");
	run("Canvas Size...", "width=300 height=300 position=Center zero");
	if (File.exists(path_horalign_1+currimg)==true){
		filename=replace(currimg, ".tif", a+".tif");}
	else {
		filename=currimg;}
	saveAs("tiff", path_horalign_1+filename);															//save image
	close("*");		
}
run("Image Sequence...", "open=["+path_horalign_1+currimg+"] sort");									//save images to stack
run("Bleach Correction", "correction=[Histogram Matching]");
run("Attenuation Correction", "opening=3 reference=1");
saveAs("tiff", path_horalign+"Segment_01.tif");
close("*");

for (a=0; a<si; a++){						//2
	open(path_cleanprev+sections_analysis02[a]);
	path_horalign_2=path_horalign+"2/";
	File.makeDirectory(path_horalign_2);
	run("Scale...", "x=- y=- z=1.0 width=300 height=300 interpolation=Bilinear average process create");
	currimg=getTitle();
	run("Duplicate...", " ");																		//create mask
	//run("Enhance Contrast...", "saturated=1");
	//setAutoThreshold("MinError dark");
	setAutoThreshold(thresh);
	//setOption("BlackBackground", false);
	run("Convert to Mask");
	run("Dilate");
	run("Fill Holes");
	roiManager("reset");
	run("Analyze Particles...", "size=10000-Infinity pixel show=Nothing include add");				//find section
	selectWindow(currimg);
	roiManager("Select", 0);
	run("Crop");
	run("Clear Outside");																	//crop section
	run("Canvas Size...", "width=300 height=300 position=Center zero");
	if (File.exists(path_horalign_2+currimg)==true){
		filename=replace(currimg, ".tif", a+".tif");}
	else {
		filename=currimg;}
	saveAs("tiff", path_horalign_2+filename);															//save image
	close("*");	
}
run("Image Sequence...", "open=["+path_horalign_2+currimg+"] sort");									//save images to stack
run("Bleach Correction", "correction=[Histogram Matching]");
run("Attenuation Correction", "opening=3 reference=1");
saveAs("tiff", path_horalign+"Segment_02.tif");
close("*");

for (a=0; a<si; a++){						//3
	open(path_cleanprev+sections_analysis03[a]);
	path_horalign_3=path_horalign+"3/";
	File.makeDirectory(path_horalign_3);
	run("Scale...", "x=- y=- z=1.0 width=300 height=300 interpolation=Bilinear average process create");
	currimg=getTitle();
	run("Duplicate...", " ");																		//create mask
	//run("Enhance Contrast...", "saturated=1");
	//setAutoThreshold("MinError dark");
	setAutoThreshold(thresh);
	//setOption("BlackBackground", false);
	run("Convert to Mask");
	run("Dilate");
	run("Fill Holes");
	roiManager("reset");
	run("Analyze Particles...", "size=10000-Infinity pixel show=Nothing include add");				//find section
	selectWindow(currimg);
	roiManager("Select", 0);
	run("Crop");
	run("Clear Outside");																	//crop section
	run("Canvas Size...", "width=300 height=300 position=Center zero");
	if (File.exists(path_horalign_3+currimg)==true){
		filename=replace(currimg, ".tif", a+".tif");}
	else {
		filename=currimg;}
	saveAs("tiff", path_horalign_3+filename);															//save image
	close("*");	
}

run("Image Sequence...", "open=["+path_horalign_3+currimg+"] sort");									//save images to stack
run("Bleach Correction", "correction=[Histogram Matching]");
run("Attenuation Correction", "opening=3 reference=1");
saveAs("tiff", path_horalign+"Segment_03.tif");
close("*");

for (a=0; a<si; a++){						//4
	open(path_cleanprev+sections_analysis04[a]);
	path_horalign_4=path_horalign+"4/";
	File.makeDirectory(path_horalign_4);
	run("Scale...", "x=- y=- z=1.0 width=300 height=300 interpolation=Bilinear average process create");
	currimg=getTitle();
	run("Duplicate...", " ");																		//create mask
	//run("Enhance Contrast...", "saturated=1");
	//setAutoThreshold("MinError dark");
	setAutoThreshold(thresh);
	//setOption("BlackBackground", false);
	run("Convert to Mask");
	run("Dilate");
	run("Fill Holes");
	roiManager("reset");
	run("Analyze Particles...", "size=10000-Infinity pixel show=Nothing include add");				//find section
	selectWindow(currimg);
	roiManager("Select", 0);
	run("Crop");
	run("Clear Outside");																	//crop section
	run("Canvas Size...", "width=300 height=300 position=Center zero");
	if (File.exists(path_horalign_4+currimg)==true){
		filename=replace(currimg, ".tif", a+".tif");}
	else {
		filename=currimg;}
	saveAs("tiff", path_horalign_4+filename);															//save image
	close("*");	
}
run("Image Sequence...", "open=["+path_horalign_4+currimg+"] sort");									//save images to stack
run("Bleach Correction", "correction=[Histogram Matching]");
run("Attenuation Correction", "opening=3 reference=1");
saveAs("tiff", path_horalign+"Segment_04.tif");
close("*");

for (a=0; a<si; a++){						//5
	open(path_cleanprev+sections_analysis05[a]);
	path_horalign_5=path_horalign+"5/";
	File.makeDirectory(path_horalign_5);
	run("Scale...", "x=- y=- z=1.0 width=300 height=300 interpolation=Bilinear average process create");
	currimg=getTitle();
	run("Duplicate...", " ");																		//create mask
	//run("Enhance Contrast...", "saturated=1");
	//setAutoThreshold("MinError dark");
	setAutoThreshold(thresh);
	//setOption("BlackBackground", false);
	run("Convert to Mask");
	run("Dilate");
	run("Fill Holes");
	roiManager("reset");
	run("Analyze Particles...", "size=10000-Infinity pixel show=Nothing include add");				//find section
	selectWindow(currimg);
	roiManager("Select", 0);
	run("Crop");
	run("Clear Outside");																	//crop section
	run("Canvas Size...", "width=300 height=300 position=Center zero");
	if (File.exists(path_horalign_5+currimg)==true){
		filename=replace(currimg, ".tif", a+".tif");}
	else {
		filename=currimg;}
	saveAs("tiff", path_horalign_5+filename);															//save image
	close("*");	
}
run("Image Sequence...", "open=["+path_horalign_5+currimg+"] sort");									//save images to stack
run("Bleach Correction", "correction=[Histogram Matching]");
run("Attenuation Correction", "opening=3 reference=1");
saveAs("tiff", path_horalign+"Segment_05.tif");
close("*");

for (a=0; a<si; a++){						//6
	open(path_cleanprev+sections_analysis06[a]);
	path_horalign_6=path_horalign+"6/";
	File.makeDirectory(path_horalign_6);
	run("Scale...", "x=- y=- z=1.0 width=300 height=300 interpolation=Bilinear average process create");
	currimg=getTitle();
	run("Duplicate...", " ");																		//create mask
	//run("Enhance Contrast...", "saturated=1");
	//setAutoThreshold("MinError dark");
	setAutoThreshold(thresh);
	//setOption("BlackBackground", false);
	run("Convert to Mask");
	run("Dilate");
	run("Fill Holes");
	roiManager("reset");
	run("Analyze Particles...", "size=10000-Infinity pixel show=Nothing include add");				//find section
	selectWindow(currimg);
	roiManager("Select", 0);
	run("Crop");
	run("Clear Outside");																	//crop section
	run("Canvas Size...", "width=300 height=300 position=Center zero");
	if (File.exists(path_horalign_6+currimg)==true){
		filename=replace(currimg, ".tif", a+".tif");}
	else {
		filename=currimg;}
	saveAs("tiff", path_horalign_6+filename);															//save image
	close("*");	
}
run("Image Sequence...", "open=["+path_horalign_6+currimg+"] sort");									//save images to stack
run("Bleach Correction", "correction=[Histogram Matching]");
run("Attenuation Correction", "opening=3 reference=1");
saveAs("tiff", path_horalign+"Segment_06.tif");
close("*");

for (a=0; a<si; a++){						//7
	open(path_cleanprev+sections_analysis07[a]);
	path_horalign_7=path_horalign+"7/";
	File.makeDirectory(path_horalign_7);
	run("Scale...", "x=- y=- z=1.0 width=300 height=300 interpolation=Bilinear average process create");
	currimg=getTitle();
	run("Duplicate...", " ");																		//create mask
	//run("Enhance Contrast...", "saturated=1");
	//setAutoThreshold("MinError dark");
	setAutoThreshold(thresh);
	//setOption("BlackBackground", false);
	run("Convert to Mask");
	run("Dilate");
	run("Fill Holes");
	roiManager("reset");
	run("Analyze Particles...", "size=10000-Infinity pixel show=Nothing include add");				//find section
	selectWindow(currimg);
	roiManager("Select", 0);
	run("Crop");
	run("Clear Outside");																		//crop section
	run("Canvas Size...", "width=300 height=300 position=Center zero");
	if (File.exists(path_horalign_7+currimg)==true){
		filename=replace(currimg, ".tif", a+".tif");}
	else {
		filename=currimg;}
	saveAs("tiff", path_horalign_7+filename);															//save image
	close("*");	
}
run("Image Sequence...", "open=["+path_horalign_7+currimg+"] sort");									//save images to stack
run("Bleach Correction", "correction=[Histogram Matching]");
run("Attenuation Correction", "opening=3 reference=1");
saveAs("tiff", path_horalign+"Segment_07.tif");
close("*");

for (a=0; a<si; a++){						//8
	open(path_cleanprev+sections_analysis08[a]);
	path_horalign_8=path_horalign+"8/";
	File.makeDirectory(path_horalign_8);
	run("Scale...", "x=- y=- z=1.0 width=300 height=300 interpolation=Bilinear average process create");
	currimg=getTitle();
	run("Duplicate...", " ");																		//create mask
	//run("Enhance Contrast...", "saturated=1");
	//setAutoThreshold("MinError dark");
	setAutoThreshold(thresh);
	//setOption("BlackBackground", false);
	run("Convert to Mask");
	run("Dilate");
	run("Fill Holes");
	roiManager("reset");
	run("Analyze Particles...", "size=10000-Infinity pixel show=Nothing include add");				//find section
	selectWindow(currimg);
	roiManager("Select", 0);
	run("Crop");
	run("Clear Outside");																	//crop section
	run("Canvas Size...", "width=300 height=300 position=Center zero");
	if (File.exists(path_horalign_8+currimg)==true){
		filename=replace(currimg, ".tif", a+".tif");}
	else {
		filename=currimg;}
	saveAs("tiff", path_horalign_8+filename);															//save image
	close("*");	
}
run("Image Sequence...", "open=["+path_horalign_8+currimg+"] sort");									//save images to stack
run("Bleach Correction", "correction=[Histogram Matching]");
run("Attenuation Correction", "opening=3 reference=1");
saveAs("tiff", path_horalign+"Segment_08.tif");
close("*");

for (a=0; a<si; a++){						//9
	open(path_cleanprev+sections_analysis09[a]);
	path_horalign_9=path_horalign+"9/";
	File.makeDirectory(path_horalign_9);
	run("Scale...", "x=- y=- z=1.0 width=300 height=300 interpolation=Bilinear average process create");
	currimg=getTitle();
	run("Duplicate...", " ");																		//create mask
	//run("Enhance Contrast...", "saturated=1");
	//setAutoThreshold("MinError dark");
	setAutoThreshold(thresh);
	//setOption("BlackBackground", false);
	run("Convert to Mask");
	run("Dilate");
	run("Fill Holes");
	roiManager("reset");
	run("Analyze Particles...", "size=10000-Infinity pixel show=Nothing include add");				//find section
	selectWindow(currimg);
	roiManager("Select", 0);
	run("Crop");
	run("Clear Outside");																		//crop section
	run("Canvas Size...", "width=300 height=300 position=Center zero");
	if (File.exists(path_horalign_9+currimg)==true){			
		filename=replace(currimg, ".tif", a+".tif");}
	else {
		filename=currimg;}
	saveAs("tiff", path_horalign_9+filename);															//save image
	close("*");	
}
run("Image Sequence...", "open=["+path_horalign_9+currimg+"] sort");									//save images to stack
run("Bleach Correction", "correction=[Histogram Matching]");
run("Attenuation Correction", "opening=3 reference=1");
saveAs("tiff", path_horalign+"Segment_09.tif");
close("*");

setBatchMode(false);


//--------------------------------------------------------------identify horizontal orientation
files=getFileList(path_horalign);
stacks=newArray();
ff=0;
for (f=0; f<files.length; f++){
	if (endsWith(files[f], ".tif")){
		stacks[ff]=files[f];
		ff=ff+1;
	}
}
stacks=Array.sort(stacks);

//Array.show(files);
//Array.show(stacks);


nangle=((abs(angle_min)+abs(angle_max))/angle_incr)+1;
angle=newArray(nangle);
difference_mean=newArray(nangle);
difference_max=newArray(nangle);
mean_angle=newArray(9);
median_angle=newArray(9);
adjust_angle=newArray(9);



for (ii=0; ii<stacks.length; ii++){				//for all stacks
	open(path_horalign+stacks[ii]);
	title_stack=getTitle();													//title of raw stack

	//Alternative: COMBINE ALL IMAGES IN STACK AND DETERMINE ANGLE ON THIS
	//run("Z Project...", "projection=Median");
	//-----------------------------------------------------------------------------------------------------------------
	ns=nSlices;
	best_angle=newArray(ns);

	roiManager("reset");
	makeRectangle(0, 0, 150, 300);
	roiManager("Add");						//left half
	makeRectangle(150, 0, 150, 300);
	roiManager("Add");						//right half
	run("Select None");

	setAutoThreshold("Default dark");											//threshold gray matter
	run("Convert to Mask", "method=Default background=Dark calculate");
	//run("Dilate", "stack");
	run("Gaussian Blur...", "sigma=5 stack");		
	resetMinAndMax();
	run("Apply LUT", "stack");
	saveAs("tiff", path_horalign+"Segment_"+ii+1+"_thresh.tif");
	title_stack_thresh=getTitle();											//title of thresholded stack
		
	//for each slice
	for(ss=0; ss<ns; ss++){ 
		selectWindow(title_stack_thresh);
		setSlice(ss+1);	
		indx=1;
		
		//for all angles
		for(aa=angle_min; aa<angle_max+1; aa+=angle_incr){	
			angle[indx-1]=aa;
			selectWindow(title_stack_thresh);
			run("Duplicate...", " ");	
			//rotate by angle
			run("Rotate... ", "angle="+aa+" grid=1 interpolation=Bilinear");
			title_slice=getTitle();											//title of single slice image
			
			roiManager("Select", 0);	//left half
			run("Duplicate...", " ");	
			title_left=getTitle();											//title of single image left half
			run("Flip Horizontally");
			run("Select None");	
			//print(title_left);
			selectWindow(title_slice);
			roiManager("Select", 1);	//right half
			run("Duplicate...", " ");
			title_right=getTitle();											//title of single image right half
			run("Select None");
			imageCalculator("Difference create", title_left,title_right);	//calculate difference
			run("Set Measurements...", "mean min redirect=None decimal=3");
			run("Clear Results");
			run("Measure");
			
			difference_mean[indx-1]=getResult("Mean", 0);
			difference_max[indx-1]=getResult("Max", 0);

			close(title_slice);
			close(title_left);
			close(title_right);

			indx=indx+1;
		}
	 
		//determine best angle
		alpha=Array.rankPositions(difference_mean);				
		best_angle[ss]=angle[alpha[0]];

		if(save_temp=="yes"){
			run("Clear Results");	
			for (w=0; w<nangle; w++) {
				setResult("Angle", w, angle[w]);
				setResult("overlay difference mean", w, difference_mean[w]);
				setResult("overlay difference max", w, difference_max[w]);
					
			}		
			saveAs("Results",  path_horalign+"Results_"+ii+1+"_Section_"+ss+1+".csv");
		}

		//close all but stack window
		selectWindow(title_stack_thresh);
		close("\\Others");
	}


	if(save_temp=="yes"){
		//save best angle
		run("Clear Results");
		for (bb=0; bb<si; bb++) {
			if(ii+1==1){			//segment 1
				setResult("Slice", bb, sections_analysis01[bb]);}
			else if(ii+1==2){		//segment 2
				setResult("Slice", bb, sections_analysis02[bb]);}
			else if(ii+1==3){		//segment 3
				setResult("Slice", bb, sections_analysis03[bb]);}
			else if(ii+1==4){		//segment 4
				setResult("Slice", bb, sections_analysis04[bb]);}
			else if(ii+1==5){		//segment 5
				setResult("Slice", bb, sections_analysis05[bb]);}
			else if(ii+1==6){		//segment 6
				setResult("Slice", bb, sections_analysis06[bb]);}
			else if(ii+1==7){		//segment 7
				setResult("Slice", bb, sections_analysis07[bb]);}
			else if(ii+1==8){		//segment 8
				setResult("Slice", bb, sections_analysis08[bb]);}
			else if(ii+1==9){		//segment 9
				setResult("Slice", bb, sections_analysis09[bb]);}
			setResult("Correction Angle", bb, best_angle[bb]);
		}
		saveAs("Results", path_horalign+"Correction_angles_0"+ii+1+".csv");
	close("Results");
	}
	
	best_angle=Array.deleteValue(best_angle, NaN);
	//average angle for each segment
	Array.getStatistics(best_angle, min, max, mean, std);
	mean_angle[ii]=mean;

	//median
	best_angle_rank=Array.rankPositions(best_angle);
	middle=floor(best_angle_rank.length/2);
	median_id=best_angle_rank[middle];
	median=best_angle[median_id];
	median_angle[ii]=median;

	//adjustment angle (use median if angles span a large range, otherwise mean)
	if (abs(max-min)>20){
		adjust_angle[ii]=median_angle[ii];
	}
	else {
		adjust_angle[ii]=mean_angle[ii];
	}
}
run("Clear Results");
Array.show(adjust_angle);
saveAs("Results", path_horalign+"_Horizontal_Alignment_Angles.csv");			//save angles used for alignment to csv

print("Determining Alignment Angles Complete!");
setBatchMode(true);


if(save_temp=="yes"){
	for (ii=0; ii<stacks.length; ii++){				//for all stacks
		run("Clear Results");
		open(path_horalign+"Correction_angles_0"+ii+1+".csv");				//save adjustment angle
		title=Table.title;
		Table.rename(title, "Results");
		setResult("Slice", si, "mean");
		setResult("Slice", si+1, "median");
		setResult("Slice", si+2, "used");
		setResult("Correction Angle", si, mean_angle[ii]);
		setResult("Correction Angle", si+1, median_angle[ii]);
		setResult("Correction Angle", si+2, adjust_angle[ii]);
		saveAs("Results", path_horalign+"Correction_angles_0"+ii+1+".csv");
	
		open(path_horalign+stacks[ii]);										//rotate stack
		run("Rotate... ", "angle="+adjust_angle[ii]+" grid=1 interpolation=Bilinear stack");
		saveAs("tiff", path_horalign+"Segment_"+ii+1+"_rotated.tif");
	}
}

close("*");
close("Results");
close("Log");
close("ROI Manager");



//---------------------------------------------------------------------------------------------------------------------------

//Reformat Sections
print("Reformatting Sections...");
open(path_clean+sections_01[0]);								//determine number of channels, image width and height
getDimensions(width, height, channels, slices, frames);
getPixelSize(unit, pixelWidth, pixelHeight);					//determine scaling factor
close();
sf=pixelWidth/2;
width_scaled=floor(width*sf);									//determine scaled image dimensions
height_scaled=floor(height*sf);
//print("dimensions: width="+width+" height="+height+" scaling factor="+sf+" width scaled="+width_scaled+" height scaled="+height_scaled);
									
for (ch=0; ch<channels; ch++) {									//make subfolder for each channel
	path_reformat_ch=path_reformat+ch+1+"/";
	File.makeDirectory(path_reformat_ch);
}

//process each image
for (seg=0; seg<9; seg++) {										//for each segment
	for(sec=0; sec<nsections[seg]; sec++){						//nsections[seg]: number of slices in current segment
		close("*");
		if (seg==0){										
			if (File.exists(path_clean+sections_01[sec])==true){
				open(path_clean+sections_01[sec]);	}}
		else if (seg==1){
			if (File.exists(path_clean+sections_02[sec])==true){
				open(path_clean+sections_02[sec]);	}}
		else if (seg==2){
			if (File.exists(path_clean+sections_03[sec])==true){
				open(path_clean+sections_03[sec]);	}}
		else if (seg==3){
			if (File.exists(path_clean+sections_04[sec])==true){
				open(path_clean+sections_04[sec]);	}}
		else if (seg==4){
			if (File.exists(path_clean+sections_05[sec])==true){
				open(path_clean+sections_05[sec]);	}}
		else if (seg==5){
			if (File.exists(path_clean+sections_06[sec])==true){
				open(path_clean+sections_06[sec]);	}}
		else if (seg==6){
			if (File.exists(path_clean+sections_07[sec])==true){
				open(path_clean+sections_07[sec]);	}}
		else if (seg==7){
			if (File.exists(path_clean+sections_08[sec])==true){
				open(path_clean+sections_08[sec]);	}}		
		else if (seg==8){
			if (File.exists(path_clean+sections_09[sec])==true){
				open(path_clean+sections_09[sec]);	}}

		if (nImages>0){			
			title_multich=getTitle();							
			print("Processing "+title_multich);
			//scale down to match atlas resolution (2px/um)
			run("Scale...", "x="+sf+" y="+sf+" z=1.0 width="+width_scaled+" height="+height_scaled+" depth="+channels+" interpolation=Bilinear average create");		
			//center section
			Stack.setChannel(MaskCh);
			run("Duplicate...", " ");																		//create mask
			//title_mask=getTitle();								//title with ending "-2.tif"
			//print(title_mask);
			run("Enhance Contrast...", "saturated=5");
			setAutoThreshold("MinError dark");
			run("Convert to Mask");
			run("Dilate");
			//run("Dilate");
			run("Fill Holes");
			roiManager("reset");
			run("Analyze Particles...", "size=100000-Infinity pixel show=Nothing include add");				//find section
			//selectWindow(title_mask);
			close();
			//selectWindow(title_multich_scaled);
			roiManager("Select", 0);
			run("Crop");
			run("Clear Outside", "stack");																	//crop section
			run("Canvas Size...", "width="+width_scaled+" height="+height_scaled+" position=Center zero");	//restore canvas size
			//run("Select None");
			
			//close("\\Others");
			run("Rotate... ", "angle="+adjust_angle[seg]+" grid=1 interpolation=Bilinear stack");	//rotate by segment specific angle
			

			//split channels
			run("Split Channels");
			for (ch=0; ch<channels; ch++) {															//run through all channels
				title_singlech=getTitle();
				run("Grays");
				if(startsWith(title_singlech, "C1")==true){
					savepath=path_reformat+1+"/";
					savetitle=replace(title_singlech,"C1-","");}
				else if(startsWith(title_singlech, "C2")==true){
					savepath=path_reformat+2+"/";
					savetitle=replace(title_singlech,"C2-","");}
				else if(startsWith(title_singlech, "C3")==true){
					savepath=path_reformat+3+"/";
					savetitle=replace(title_singlech,"C3-","");}
				else if(startsWith(title_singlech, "C4")==true){
					savepath=path_reformat+4+"/";
					savetitle=replace(title_singlech,"C4-","");}
				else if(startsWith(title_singlech, "C5")==true){
					savepath=path_reformat+5+"/";
					savetitle=replace(title_singlech,"C5-","");}

				saveAs("tiff", savepath+savetitle);															//save to single ch folder					
				close(savetitle);																			//close saved image
				
			}
		}	
	}
}

close("*");



print("Creating Post Alignment Preview (ref ch)...");
//save ref ch stack and montage
run("Image Sequence...", "open=["+path_reformat+RefCh+"/] sort");
run("Enhance Contrast...", "saturated=1");
run("Attenuation Correction", "opening=3 reference=1");
saveAs("tiff", path_reformat+"_Aligned_preview_stack.tif");	
Stack.getDimensions(width, height, channels, slices, frames); 
col=-floor(-(slices/9));	//ceil decimal values
row=9;
run("Make Montage...", "columns="+col+" rows="+row+" scale=0.25 font=20 label");
saveAs("tiff", path_horalign+"_Aligned_preview_montage.tif");
print("Preview Complete!");


setBatchMode(false);
close("*");

open(path_horalign+"_Aligned_preview_montage.tif");    //display preview

print("Reformatting Sections Complete!");
print("Processing Time: " + (getTime()-start)/60000 + " Minutes");   


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
