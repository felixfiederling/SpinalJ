//FF 8/7/2020										
//replace lost sections
//
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

//updated to run after I_Split
//running after III_Clean will miss to replace sections that have been replaced in the cleaning process (and thus have another Slide/Section/Image ID)
//

//-------------------------------------------------------------------------------------------------------------------------------

//lost sections
path_lost=File.openDialog("List of lost sections (csv)");
open(path_lost);

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

//Array.show(lostslide);
//Array.show(lostsection);
//Array.show(lostslidesection);


//existing sections
path_clean = getDirectory("Choose folder I_Split"); 
fileListall = getFileList(path_clean); 

setOption("ExpandableArrays", true);
fileList=newArray;
ff=0;
for (f=0; f<fileListall.length; f++){
	if (endsWith(fileListall[f], ".tif")){
		fileList[ff]=fileListall[f];
		ff=ff+1;
	}
}

fileListsort=Array.sort(fileList);
//Array.show(fileListsort);

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
	//if (startsWith(section[i], "0")==true){
	if (lengthOf(section[i])>2){
		section[i]=substring(section[i], 1);
	}
	slidesection[i]=slide[i]+section[i];
}


//Array.show(segment);
//Array.show(slide);
//Array.show(section);
Array.show(slidesection);

print("Replacing missing sections...");


//find replacement for lost section

//find and count lostslidesection[i] in slidesection

rep=newArray(lostslidesection.length);
frep=newArray;
k=0;
for (i = 0; i < lostslidesection.length; i++) {
	for (j = 0; j < slidesection.length; j++) {
		if(lostslidesection[i]==slidesection[j]){
			rep[i]=slidesection[j];
			//print(i+"_"+slidesection[j]);
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
//Array.show(rep);
Array.show(frep);


//duplicate replacements for lost sections

for(r=0; r<frep.length; r++){
	replacement=frep[r];
	path_rep=path_clean+replacement;
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
	//print("saved as "+path_copy);
	File.copy(path_rep, path_copy);
	
}


print("Job complete!");

