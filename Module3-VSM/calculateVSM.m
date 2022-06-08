function [] = calculateVSM(bidsFolder,vsmFolder,subjectID,taskName,fmapName)
%UNTITLED3 Summary of this function goes here
%   Detailed explanation goes here

%% fetch warp
warpFilePath = fullfile(bidsFolder,'derivatives','fmriprep',subjectID,...
    'fmap',[fmapName '.nii.gz']);

warpMNIFileName = [subjectID '_' taskName '_space-MNI152NLin2009cAsym_fieldmap'];

%% move fieldmap to T1w space


%% fetch transformation matrix to MNI and apply to warp
% https://neurostars.org/t/how-to-transform-mask-from-mni-to-native-space-using-fmriprep-outputs/2880/8
% https://neurostars.org/t/moving-images-from-mni-to-bold-epi-native-space/3833

cmd = sprintf('antsApplyTransforms -d 3 -e 3 -i %s -o %s -r %s -t %s -t %s -v 1',...
    warpFilePath,...
    fullfile(vsmFolder,[warpMNIFileName '.nii.gz']), ...
    fullfile(bidsFolder,'derivatives','fmriprep',subjectID,'func',[subjectID '_' taskName '_run-1_space-MNI152NLin2009cAsym_boldref.nii.gz']), ...
    fullfile(bidsFolder,'derivatives','fmriprep',subjectID,'anat',[subjectID '_run-1_from-T1w_to-MNI152NLin2009cAsym_mode-image_xfm.h5']),...
    fullfile(bidsFolder,'derivatives','fmriprep',subjectID,'func',[subjectID '_' taskName '_run-1_from-scanner_to-T1w_mode-image_xfm.txt']) );

system(cmd);

%% Apply brain mask

cmd = sprintf('fslmaths %s -mas %s %s',...
    fullfile(vsmFolder,[warpMNIFileName '.nii.gz']), ...
    fullfile(bidsFolder,'derivatives','fmriprep',subjectID,'func',[subjectID '_' taskName '_run-1_space-MNI152NLin2009cAsym_desc-brain_mask.nii.gz']), ...
    fullfile(vsmFolder,[warpMNIFileName '_brain.nii.gz']));

system(cmd);

end
