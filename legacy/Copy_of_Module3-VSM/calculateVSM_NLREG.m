function [] = calculateVSM_NLREG(bidsFolder,workFolder,vsmFolder,subjectID,taskacqName)
%UNTITLED3 Summary of this function goes here
%   Detailed explanation goes here

%% fetch warp
warpFilePath=fullfile(workFolder,'fmriprep_wf',...
    ['single_subject_' subjectID(5:end) '_wf'],...
    ['func_preproc_' strrep(taskacqName,'-','_') '_run_01_wf'],'sdc_estimate_wf/syn_sdc_wf/syn/ants_susceptibility0Warp.nii.gz');

warp = niftiread(warpFilePath);

warp = squeeze(warp(:,:,:,1,2)); %extract the warp in the y direction

%% fetch header of the bold image
boldFilePath = fullfile(bidsFolder,'derivatives','fmriprep',subjectID,'func',[ subjectID '_' taskacqName '_run-1_desc-preproc_bold.nii.gz']);

boldHeader = niftiinfo(boldFilePath);

%% apply header to warp and save
boldHeader.ImageSize = boldHeader.ImageSize(1:3);
boldHeader.PixelDimensions = boldHeader.PixelDimensions(1:3);

warpFileName = [subjectID '_' taskacqName '_warp'];
warpMNIFileName = [subjectID '_' taskacqName '_space-MNI_warp'];
niftiwrite(warp,fullfile(vsmFolder,warpFileName),boldHeader,'Compressed',true)

%% fetch transformation matrix to MNI and apply to warp
% https://neurostars.org/t/how-to-transform-mask-from-mni-to-native-space-using-fmriprep-outputs/2880/8
% https://neurostars.org/t/moving-images-from-mni-to-bold-epi-native-space/3833

cmd = sprintf('antsApplyTransforms -d 3 -e 3 -i %s -o %s -r %s -t %s -t %s -v 1',...
    fullfile(vsmFolder,[warpFileName '.nii.gz']),...
    fullfile(vsmFolder,[warpMNIFileName '.nii.gz']), ...
    fullfile(bidsFolder,'derivatives','fmriprep',subjectID,'func',[subjectID '_' taskacqName '_run-1_space-MNI152NLin2009cAsym_boldref.nii.gz']), ...
    fullfile(bidsFolder,'derivatives','fmriprep',subjectID,'anat',[subjectID '_run-1_from-T1w_to-MNI152NLin2009cAsym_mode-image_xfm.h5']),...
    fullfile(bidsFolder,'derivatives','fmriprep',subjectID,'func',[subjectID '_' taskacqName '_run-1_from-scanner_to-T1w_mode-image_xfm.txt']) );

system(cmd);

%% Apply brain mask

cmd = sprintf('fslmaths %s -mas %s %s',...
    fullfile(vsmFolder,[warpMNIFileName '.nii.gz']), ...
    fullfile(bidsFolder,'derivatives','fmriprep',subjectID,'func',[subjectID '_' taskacqName '_run-1_space-MNI152NLin2009cAsym_desc-brain_mask.nii.gz']), ...
    fullfile(vsmFolder,[warpMNIFileName '_brain.nii.gz']));

system(cmd);

end
