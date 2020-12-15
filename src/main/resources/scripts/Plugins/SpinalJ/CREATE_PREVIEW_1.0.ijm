//----------------------------------------------------------------------------------------------------
//Create preview of cleaned images


path_clean=getDirectory("Browse Folder III_Clean"); 
///
 
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


//save single channel preview images to /_IV_Preview_Clean
path_cleanprev=File.getParent(path_clean)+"/_IV_Preview_Clean";					//path to folder '/_IV_Preview_Clean'
//print(path_cleanprev);
if (File.exists(path_cleanprev)==1){									//delete preview folder and its content if already exists
	print("Deleting old files...");
	list = getFileList(path_cleanprev);		
	Array.print(list);			
	for (i=0; i<list.length; i++) {
     	File.delete(path_cleanprev+"/"+list[i]);
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
	open(path_clean+"/"+fileList[i]);
	imageTitle=getTitle();
	run("Split Channels");
	selectWindow("C" + regch + "-" + imageTitle);							
	setOption("ScaleConversions", true);
	run("8-bit");
	run("8-bit");
	run("Enhance Contrast", "saturated=0.35");
	run("Canvas Size...", "width="+ width + " height=" + height + " position=Center zero");
	run("Bin...", "x=" + bin + " y=" + bin +" bin=Average");
	saveAs("tiff", path_cleanprev+"/"+imageTitle);
	while (nImages>=1){
		close();
	}	
}

//save ref images to stack and montage
run("Image Sequence...", "open=["+path_cleanprev+"/"+fileList[0]+"] sort");
run("Bleach Correction", "correction=[Histogram Matching]"); //histogram matching
saveAs("Tiff", path_cleanprev+"/"+"_Preview_Stack_Clean");
Stack.getDimensions(width, height, channels, slices, frames); 
col=-floor(-(slices/9));	//ceil decimal values
row=9;
run("Make Montage...", "columns="+col+" rows="+row+" scale=0.25 font=20 label");
saveAs("Tiff", path_cleanprev+"/"+"_Preview_Montage_Clean");
close();
setBatchMode(false);	
close();							   
print("Preview complete!"); 

