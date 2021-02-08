path_all = getDirectory("Choose folder that contains raw image files."); 
//Make sure that files are in alphanumeric order and that folder does not contain other files

fileList = getFileList(path_all); 
Array.sort(fileList);		

//Array.show("Files to process.", fileList);	//check slide order
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

