bidsFolder='/DATAPOOL/VPMB/VPMB-BIDS-NLREG';
workFolder='/DATAPOOL/VPMB/VPMB-BIDS-NLREG-work';

%% subject ID and folders
subjectID='01';

%% open new derivatives folder
WD=fullfile(bidsFolder,'derivatives','vsm',['sub-' subjectID]);

if ~exist(WD,'dir')
    mkdir(WD)
end

%% define run
taskName='loc';
TR='1000';

%% fetch warp
warpFilePath=fullfile(workFolder,'fmriprep_wf',...
    ['single_subject_' subjectID '_wf'],...
    ['func_preproc_task_' taskName '_acq_' TR '_run_01_wf'],'sdc_estimate_wf/syn_sdc_wf/syn/ants_susceptibility0Warp.nii.gz');

warp = niftiread(warpFilePath);

warp = squeeze(warp(:,:,:,1,2)); %extract the warp in the y direction

%% fetch header of the bold image
boldFilePath = fullfile(bidsFolder,'derivatives','fmriprep',['sub-' subjectID],'func',['sub-' subjectID '_task-' taskName '_acq-' TR '_run-1_desc-preproc_bold.nii.gz']);

boldHeader = niftiinfo(boldFilePath);

%% apply header to warp and save
boldHeader.ImageSize = boldHeader.ImageSize(1:3);
boldHeader.PixelDimensions = boldHeader.PixelDimensions(1:3);

warpFileName = ['sub-' subjectID '_task-' taskName '_acq-' TR '_nlreg-warp'];
niftiwrite(warp,fullfile(WD,warpFileName),boldHeader,'Compressed',true)

%% fetch transformation matrix to MNI and apply to warp
% https://neurostars.org/t/how-to-transform-mask-from-mni-to-native-space-using-fmriprep-outputs/2880/8
% https://neurostars.org/t/moving-images-from-mni-to-bold-epi-native-space/3833

cmd = sprintf('antsApplyTransforms -d 3 -e 3 -i %s -o %s -r %s -t %s -t %s -v 1',...
    fullfile(WD,[warpFileName '.nii.gz']),...
    fullfile(WD,[warpFileName '_MNI.nii.gz']), ...
    fullfile(bidsFolder,'derivatives','fmriprep',['sub-' subjectID],'func',['sub-' subjectID '_task-' taskName '_acq-' TR '_run-1_space-MNI152NLin2009cAsym_boldref.nii.gz']), ...
    fullfile(bidsFolder,'derivatives','fmriprep',['sub-' subjectID],'anat',['sub-' subjectID '_run-1_from-T1w_to-MNI152NLin2009cAsym_mode-image_xfm.h5']),...
    fullfile(bidsFolder,'derivatives','fmriprep',['sub-' subjectID],'func',['sub-' subjectID '_task-' taskName '_acq-' TR '_run-1_from-scanner_to-T1w_mode-image_xfm.txt']) );

system(cmd)

%% Apply brain mask

cmd = sprintf('fslmaths %s -mas %s %s',...
    fullfile(WD,[warpFileName '_MNI.nii.gz']), ...
    fullfile(bidsFolder,'derivatives','fmriprep',['sub-' subjectID],'func',['sub-' subjectID '_task-' taskName '_acq-' TR '_run-1_space-MNI152NLin2009cAsym_desc-brain_mask.nii.gz']), ...
    fullfile(WD,[warpFileName '_MNI_brain.nii.gz']));

system(cmd)

% %% Adjust header
% warpMNIFilePath = fullfile(WD,[warpFileName '_MNI.nii.gz']);
% 
% warpMNI = niftiread(warpMNIFilePath);
% 
% boldMNIFilePath = fullfile(bidsFolder,'derivatives','fmriprep',['sub-' subjectID],'func',['sub-' subjectID '_task-' taskName '_acq-' TR '_run-1_space-MNI152NLin2009cAsym_desc-preproc_bold.nii.gz']);
% 
% boldMNIHeader = niftiinfo(boldMNIFilePath);
% 
% %boldMNIHeader.ImageSize = boldMNIHeader.ImageSize(1:3);
% %boldMNIHeader.PixelDimensions = boldMNIHeader.PixelDimensions(1:3);
% 
% niftiwrite(warpMNI,warpMNIFilePath,boldMNIHeader);


%% average per TR

