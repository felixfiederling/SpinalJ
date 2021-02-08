// Setup SpinalJ Pre-processing Settings

// First open input directory and check for parameter file

// if parameter file exists - populate all the variables - if not then just proceed - doesn't seem to work but parameters persist so it should be easy to use

  
#@ File(label="Image Data:", description="Subfolder containing spinal cord block section raw data", style="directory") input
#@ String(label="Reference Channel:", choices={"1", "2", "3", "4", "5"}, style="radioButtonHorizontal", value = "3", description="Select a reference channel (e.g. DAPI or Neurotrace).") RefCh

//#@ String(label="Do the sections require rotation?", choices={"No rotation", "Rotate 90 degrees right", "Rotate 90 degrees left"}, style="radioButtonHorizontal", description="Rotate sections as necessary so the dorsal surface of the spinal cord is at the top of the image.") Rotation
#@ String(label="Transform all Block Section Images:", choices={"no flip", "vertical flip (up-down)", "horizontal flip (left-right)", "vertical and horizontal flip"}, style="radioButtonHorizontal", description="Flip sections as necessary so that the segment order in the image is right and down (1-3, 4-6, 7-9).") Flip

#@ String(label="Determine r-c File Order:", choices={"Alphanumeric", "Nikon ND2 stage coodinates"}, value = "Nikon ND2 stage coodinates", style="listBox", description="Determine rostro-caudal order of files by filename (alphanumeric) or by extracting stage coordinates from metadata") FileOrder
#@ String(label="Order of Sections on Slide:", choices={"Right and Down", "Left and Down", "Right", "Left", "Right and Up", "Left and Up" }, style="listBox", description="Right and Down = Top: 1, 2, 3, 4 Bottom: 5, 6, 7, 8 || Left and Down = Top: 4, 3, 2, 1 Bottom: 8, 7, 6, 5, 4 || ... Only required when extracting coordinates from metadata") SliceArrangement
//only right and down implemented right now 

#@ String(label="Perform Segmentation on Down-Scaled Images?", choices={"No", "Yes"}, style="radioButtonHorizontal", description="Down-scaling of images reduces user interaction time.") ScaleSegmentation
#@ File(label="Segmentation Masks:", description="Subfolder containing spinal cord block section segmentation masks (.roi)", style="directory") Masks

#@ String(label="Replace Lost Sections?", choices={"no", "yes"}, style="radioButtonHorizontal", description="Providing a list of sections that were lost during sectioning allows to compensate for tissue loss.") Lost
#@ File(label="Lost Sections:", description="Subfolder containing '_Lost_Sections.csv' with column 1: Slide; column 2: Section", style="directory") path_lost

#@ String(label="Save Horizontal Alignment Temp Data", choices={"no", "yes"}, style="radioButtonHorizontal", description="Save intermediate processing files for troubleshooting.") Alignment_Temp
#@ Integer(label="Sampling Interval:", value = 10, style="spinner", description="Total number of setions / N sections will be randomly chosen to determine horizontal alignment") Sampling_Int
#@ Integer(label="Minimal Test Angle:", value = -50, style="spinner") MinAngle
#@ Integer(label="Maximal Test Angle:", value = 50, style="spinner") MaxAngle
#@ Integer(label="Test Angle Increment:", value = 10, style="spinner") Angle_Inc
#@ String(label="Masking Channel:", choices={"1", "2", "3", "4", "5"}, style="radioButtonHorizontal", value = "3", description="Channel for automatic section detection.") MaskCh
#@ String(label="Threshold Option for Masking:", choices={"Percentile dark", "MinError dark"}, style="radioButtonHorizontal", description="Thresholding method for automatic section detection.") MaskThresh


path_temp=input + "/_Temp/";
File.makeDirectory(path_temp);

title1 = "Segmentation_Parameters"; 
title2 = "["+title1+"]"; 
f=title2; 
run("New... ", "name="+title2+" type=Table"); 
print(f,"\\Headings:Parameter\tValue");

print(f,"Directory_Data:\t"+input); //0
//print(f,"Rotation:\t"+Rotation); //2
print(f,"Flip:\t"+Flip); //3
print(f,"Slice Arrangement:\t"+SliceArrangement); //4
print(f,"File Order:\t"+FileOrder); //5
print(f,"Scale Segmentation:\t"+ScaleSegmentation); //6
print(f,"Reference channel:\t"+RefCh); //7
print(f,"Directory_Masks:\t"+Masks); //8
print(f,"Replace lost:\t"+Lost); //9
print(f,"Directory_Lost:\t"+path_lost); //10
print(f,"Save temp output:\t"+Alignment_Temp); //11
print(f,"Sampling interval:\t"+Sampling_Int); //12
print(f,"Minimal test angle:\t"+MinAngle); //13
print(f,"Maximal test angle:\t"+MaxAngle); //14
print(f,"Test angle increment:\t"+Angle_Inc); //15
print(f,"Masking channel:\t"+MaskCh); //16
print(f,"Threshold option for masking:\t"+MaskThresh); //17

	
selectWindow(title1);	
saveAs("txt", path_temp + "Segmentation_Parameters.csv");
closewindow(title1);


function closewindow(windowname) {
	if (isOpen(windowname)) { 
      		 selectWindow(windowname); 
       		run("Close"); 
  		} 
}