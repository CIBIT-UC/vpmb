clear, clc

%% SETTINGS

% Base directory
baseDir = '/DATAPOOL/VPMB';

% Distortion correction method (affects folders)
% Options: NLREG
sdcMethod = 'NLREG';

%% Folders
bidsFolder      = fullfile(baseDir,['VPMB-BIDS-' sdcMethod]);
derivFolder     = fullfile(bidsFolder,'derivatives');
fmriPrepFolder  = fullfile(bidsFolder,'derivatives','fmriprep');
cleanFolder     = fullfile(bidsFolder,'derivatives','cleaning');
roiFolder       = fullfile(baseDir,'ROIsforSDC');
outputROIFolder = fullfile(derivFolder,'rois');

codeFolder     = pwd;

%% Subject, Task, ROI Lists and output matrices

subjectList = {'sub-01','sub-02','sub-03','sub-05','sub-06','sub-07','sub-08','sub-10','sub-11','sub-12','sub-15','sub-16','sub-21','sub-22','sub-23'};
nSubjects = length(subjectList);

taskList = {'task-loc_acq-1000_run-1'};
nTasks = length(taskList);

roiList = {'aIns_LR_brainnetome' 'Ca_LR_CIT168' 'hMT_LR_brainnetome' 'hMT_LR_glasser' 'MPFC_LR_brainnetome' 'MPFC_LR_glasser' 'NAc_LR_brainnetome' 'NAc_LR_CIT168' 'SubCC_LR_glasser' 'V1_LR_glasser'};
nROIs = length(roiList);

outputMatrix_T1w = zeros(nROIs,nSubjects,nTasks);
outputMatrix_MNI152NLin2009ASym = zeros(nROIs,nSubjects,nTasks);

spm('defaults', 'FMRI');
clear matlabbatch

%% Do

% Iterate on the ROIs
for rr = 1:nROIs
    
    roiFile = fullfile(roiFolder,[roiList{rr} '.nii.gz']);
    
    % Iterate on the subjects
    for ss = 1:nSubjects
        
        % make folder
        subjectOutputROIFolder = fullfile(outputROIFolder,subjectList{ss});
        if ~exist(subjectOutputROIFolder,'dir')
           mkdir(subjectOutputROIFolder); disp('Output subject-ROI folder created.')
        end
        
        % unzip and resample ROIs to MNI152
        clear matlabbatch
        
        matlabbatch{1}.cfg_basicio.file_dir.file_ops.cfg_gunzip_files.files = {roiFile};
        matlabbatch{1}.cfg_basicio.file_dir.file_ops.cfg_gunzip_files.outdir = {roiFolder};
        matlabbatch{1}.cfg_basicio.file_dir.file_ops.cfg_gunzip_files.keep = true;
        
        matlabbatch{2}.spm.spatial.coreg.write.ref = {fullfile(cleanFolder,subjectList{ss},'spm','model_task-loc_acq-1000_run-1_MNI152NLin2009cAsym','con_0001.nii,1')};
        matlabbatch{2}.spm.spatial.coreg.write.source(1) = cfg_dep('Gunzip Files: Gunzipped Files', substruct('.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('()',{':'}));
        matlabbatch{2}.spm.spatial.coreg.write.roptions.interp = 4;
        matlabbatch{2}.spm.spatial.coreg.write.roptions.wrap = [0 0 0];
        matlabbatch{2}.spm.spatial.coreg.write.roptions.mask = 0;
        matlabbatch{2}.spm.spatial.coreg.write.roptions.prefix = [subjectList{ss} '_MNI152NLin2009cAsym-reslice_'];
        
        spm_jobman('run', matlabbatch);
        
        newROIName = [subjectList{ss} '_MNI152NLin2009cAsym-reslice_' roiList{rr} '.nii'];
        movefile(fullfile(roiFolder,newROIName),subjectOutputROIFolder)
        
        % Iterate on the tasks
        for tt = 1:nTasks
            
            outputMatrix_MNI152NLin2009ASym(rr,ss,tt) = ...
                extractROIdata(fullfile(subjectOutputROIFolder,newROIName), ...
                fullfile(cleanFolder,subjectList{ss},'spm',['model_' taskList{tt} '_MNI152NLin2009cAsym'],'con_0001.nii,1') );
            
        end
        
        % Transform ROIs to T1w space
        
        transformMatrixFile = fullfile(fmriPrepFolder,subjectList{ss},'anat',[subjectList{ss} '_run-1_from-MNI152NLin2009cAsym_to-T1w_mode-image_xfm.h5']);
        t1wFile = fullfile(fmriPrepFolder,subjectList{ss},'anat',[subjectList{ss} '_run-1_desc-preproc_T1w.nii.gz']);
        
        cmd = sprintf('antsApplyTransforms --dimensionality 3 --input %s --output %s --transform %s --interpolation Linear --reference-image %s',...
            roiFile,...
            fullfile(subjectOutputROIFolder,[subjectList{ss} '_T1w_' roiList{rr} '.nii.gz']),...
            transformMatrixFile,t1wFile);
        
        system(cmd)
        
        % unzip and resample ROIs to T1w
        clear matlabbatch
        
        matlabbatch{1}.cfg_basicio.file_dir.file_ops.cfg_gunzip_files.files = {fullfile(subjectOutputROIFolder,[subjectList{ss} '_T1w_' roiList{rr} '.nii.gz'])};
        matlabbatch{1}.cfg_basicio.file_dir.file_ops.cfg_gunzip_files.outdir = {subjectOutputROIFolder};
        matlabbatch{1}.cfg_basicio.file_dir.file_ops.cfg_gunzip_files.keep = true;
        
        matlabbatch{2}.spm.spatial.coreg.write.ref = {fullfile(cleanFolder,subjectList{ss},'spm','model_task-loc_acq-1000_run-1_T1w','con_0001.nii,1')};
        matlabbatch{2}.spm.spatial.coreg.write.source(1) = cfg_dep('Gunzip Files: Gunzipped Files', substruct('.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('()',{':'}));
        matlabbatch{2}.spm.spatial.coreg.write.roptions.interp = 4;
        matlabbatch{2}.spm.spatial.coreg.write.roptions.wrap = [0 0 0];
        matlabbatch{2}.spm.spatial.coreg.write.roptions.mask = 0;
        matlabbatch{2}.spm.spatial.coreg.write.roptions.prefix = 'T1w-reslice_';
        
        spm_jobman('run', matlabbatch);
        
        newROIName = [subjectList{ss} '_T1w-reslice_' roiList{rr} '.nii'];
        movefile(fullfile(subjectOutputROIFolder,['T1w-reslice_' subjectList{ss} '_T1w_' roiList{rr} '.nii']),...
                 fullfile(subjectOutputROIFolder,newROIName))
        
        for tt = 1:nTasks
            
            outputMatrix_T1w(rr,ss,tt) = ...
                extractROIdata(fullfile(subjectOutputROIFolder,newROIName), ...
                fullfile(cleanFolder,subjectList{ss},'spm',['model_' taskList{tt} '_T1w'],'con_0001.nii,1') );
            
        end
        
    end
    
    
end

%% Export output
save(['Output_' datestr(now,'yyyymmdd-HHMM') '.mat'])
