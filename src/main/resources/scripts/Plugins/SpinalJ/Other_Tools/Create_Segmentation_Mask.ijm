//Script to create masks for segmentation of SpineRack block section images 
//V1.0
//7/9/2021
//Felix Fiederling
//----------------------------------------------------------------------------------

file = File.openDialog("Choose single channel tif image of 3x3 section array from which to create segmentation mask"); 
path=File.getParent(file);

setBatchMode(true);
open(file);
image=getTitle();
print("Detecting sections...");
run("Enhance Contrast", "saturated=0.35");
run("8-bit");
setAutoThreshold("Mean dark"); //threshold sections
run("Convert to Mask");
run("Fill Holes");

getPixelSize(unit, pixelWidth, pixelHeight); 
//print(unit);print(pixelWidth);print(pixelHeight);

if ((unit!="microns") || (pixelWidth!=pixelHeight)){
	exit("ERROR: Please use 'Set Scale' to set unit of length to 'micron'!");
}

size_low=1000000/(Math.sqr(pixelWidth));  
size_high=5000000/(Math.sqr(pixelWidth)); 
circ_low=0.05;
circ_high=1;



roiManager("reset");
run("Analyze Particles...", "size="+size_low+"-"+size_high+" pixel circularity="+circ_low+"-"+circ_high+" show=Nothing include add"); //analyze particles
//run("Analyze Particles...", "size=1000000-5000000 pixel circularity=0.05-1.00 show=Nothing include add");
run("Clear Results");
roiManager("Measure");
if (roiManager("count")!=9){  //check if exactly nine particles are detected
	exit("ERROR: Could not detect nine sections, please run again on a different image!");
}

print("Nine sections detected. Extracting coordinates...");
n_rows = 3;	n_cols =3;
col = newArray("A", "B", "C");	row = newArray("A", "B", "C");
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
roiManager("deselect");
run("Clear Results");
roiManager("Measure");
roiManager("Show All without labels");
roiManager("Show All with labels");  //to update labels

print("Creating segmentation mask...");
XP=newArray(9); YP=newArray(9);
for (i = 0; i < 9; i++) {
	XP[i]=getResult("X", i);        //X coordinates of sections 1-9
	YP[i]=getResult("Y", i);		//Y coordinates of sections 1-9
}
xdist1=(abs(XP[0]-XP[1])+abs(XP[1]-XP[2]))/2;
xdist2=(abs(XP[3]-XP[4])+abs(XP[4]-XP[5]))/2;
xdist3=(abs(XP[6]-XP[7])+abs(XP[7]-XP[8]))/2;
xdist=(xdist1+xdist2+xdist3)/3;   //average x distance between sections  
//print(xdist);

ydist1=(abs(YP[0]-YP[3])+abs(YP[3]-YP[6]))/2;
ydist2=(abs(YP[1]-YP[4])+abs(YP[4]-YP[7]))/2;
ydist3=(abs(YP[2]-YP[5])+abs(YP[5]-YP[8]))/2;
ydist=(ydist1+ydist2+ydist3)/3;   //average y distance between sections
//print(ydist);

//dimensions of individual segmentation boxes
xgap=0.025*xdist;
ygap=0.025*ydist;
w=2*((xdist/2)-(xgap/2));
h=2*((ydist/2)-(ygap/2));

roiManager("reset");

for (i = 0; i < 3; i++) {
	for (j = 0; j<3; j++){
		x=w*i+xgap*i;
		y=h*j+ygap*j;
		makeRectangle(x, y, w, h);
		roiManager("add");
	}
}
roiManager("deselect");
roiManager("XOR");
roiManager("add");
roiManager("select", 9);
roiManager("rename", "Split_mask");
roiManager("save selected", path+"/Split_mask.roi");
roiManager("reset");

print("Segmentation mask saved!");




//-----------------------------------------------------------------------------------------
//create scaled mask
print("Creating down-scaled segmentation mask...");
selectWindow(image);
run("Select None");
//scale down (0.1x)
run("Scale...", "x=0.1 y=0.1 interpolation=Bilinear average create");
image_s=getTitle();
selectWindow(image_s);
close("\\Others");
setAutoThreshold("Default dark");
run("Convert to Mask");

getPixelSize(unit, pixelWidth, pixelHeight); 
//print(unit);print(pixelWidth);print(pixelHeight);
size_low=1000000/(Math.sqr(pixelWidth));  
size_high=5000000/(Math.sqr(pixelWidth)); 
circ_low=0.05;
circ_high=1;

roiManager("reset");
run("Analyze Particles...", "size="+size_low+"-"+size_high+" pixel circularity="+circ_low+"-"+circ_high+" show=Nothing include add"); //analyze particles
//run("Analyze Particles...", "size=1000000-5000000 pixel circularity=0.05-1.00 show=Nothing include add");
run("Clear Results");
roiManager("Measure");
if (roiManager("count")!=9){  //check if exactly nine particles are detected
	exit("ERROR: Could not detect nine sections, please run again on a different image!");
}

n_rows = 3;	n_cols =3;
col = newArray("A", "B", "C");	row = newArray("A", "B", "C");
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
roiManager("deselect");
run("Clear Results");
roiManager("Measure");
roiManager("Show All without labels");
roiManager("Show All with labels");  //to update labels


XP=newArray(9); YP=newArray(9);		
for (i = 0; i < 9; i++) {
	XP[i]=getResult("X", i);        //X coordinates of sections 1-9
	YP[i]=getResult("Y", i);		//Y coordinates of sections 1-9
}
xdist1=(abs(XP[0]-XP[1])+abs(XP[1]-XP[2]))/2;		
xdist2=(abs(XP[3]-XP[4])+abs(XP[4]-XP[5]))/2;
xdist3=(abs(XP[6]-XP[7])+abs(XP[7]-XP[8]))/2;
xdist=(xdist1+xdist2+xdist3)/3;   //average x distance between sections in microns
xdist=xdist*0.1;
//print(xdist);

ydist1=(abs(YP[0]-YP[3])+abs(YP[3]-YP[6]))/2;
ydist2=(abs(YP[1]-YP[4])+abs(YP[4]-YP[7]))/2;
ydist3=(abs(YP[2]-YP[5])+abs(YP[5]-YP[8]))/2;
ydist=(ydist1+ydist2+ydist3)/3;   //average y distance between sections in microns
ydist=ydist*0.1;
//print(ydist);

//dimensions of individual segmentation boxes
xgap=0.025*xdist;
ygap=0.025*ydist;
w=2*((xdist/2)-(xgap/2));
h=2*((ydist/2)-(ygap/2));

roiManager("reset");

for (i = 0; i < 3; i++) {
	for (j = 0; j<3; j++){
		x=w*i+xgap*i;
		y=h*j+ygap*j;
		makeRectangle(x, y, w, h);
		roiManager("add");
	}
}
roiManager("deselect");
roiManager("XOR");
roiManager("add");
roiManager("select", 9);
roiManager("rename", "Split_mask_scaled");
roiManager("save selected", path+"/Split_mask_scaled.roi");
roiManager("reset");

print("Scaled segmentation mask saved!");
print("Mask creation complete and saved to "+ path);

setBatchMode(false);
close("*");

