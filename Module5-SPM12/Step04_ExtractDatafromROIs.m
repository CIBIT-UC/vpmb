%% -- Step04_ExtractDatafromROIs.m ------------------------------------------------- %%
% ----------------------------------------------------------------------- %
% Script for executing the second step regarding the SPM analysis of fMRI
% data after preprocessing with fmriPrep v21 - extracting the T value and 
% coordinates of the various contrasts of interests for the ROIs defined 
% before. This also reslices the ROIs to each image.
%
% Dataset:
% - Multiband (Visual Perception)
%
% Warnings:
% - a number of values/steps are custom for this dataset - full code review
% is strongly advised for different datasets
% - this was designed to run on sim01 - a lot of paths must change if run
% at any other computer
%
% Requirements:
% - Preprocessed data by fmriPrep v20
% - FSL 6 functions in path
% - SPM12 in path
%
% Author: Alexandre Sayal
% CIBIT, University of Coimbra
% October 2022
% ----------------------------------------------------------------------- %
% ----------------------------------------------------------------------- %

clear,clc
tic

%% Load Packages on sim01
% SPM12
addpath('/SCRATCH/software/toolboxes/spm12')

%% SETTINGS

% Base directory
baseFolder = '/DATAPOOL/VPMB';

% Distortion correction method (affects folders)
% Options: NLREG, NONE, EPI, SPE, GRE
sdcMethod = 'NLREG';

%% Folders
bidsFolder      = fullfile(baseFolder,['BIDS-VPMB-' sdcMethod]);
derivFolder     = fullfile(bidsFolder,'derivatives');
fmriPrepFolder  = fullfile(bidsFolder,'derivatives','fmriprep');
spm12Folder     = fullfile(bidsFolder,'derivatives','spm12');


roiFolder       = fullfile(derivFolder,'ROI_spherical','group');
outputROIFolder = fullfile(derivFolder,'ROI_spherical');

codeFolder     = pwd;

%% Load data from step 03
% data from localizer spherical group ROIs - datasetLocROIs
load('output/Output_Step03_datasetLocROIs.mat');

%% Subject, Task, ROI Lists and output matrices

% Extract Subject List from BIDS
aux = dir(fullfile(bidsFolder,'sub-*'));
subjectList = extractfield(aux,'name');
clear aux
nSubjects = length(subjectList);

% Extract Task List from BIDS
aux = dir(fullfile(bidsFolder,'sub-01','func','*_task-*_bold.json'));
taskList = extractfield(aux,'name');

taskList = cellfun(@(x) x(8:end-10), taskList, 'un', 0); % remove trailing and leading info (VERY custom)
nTasks = length(taskList);

% ROIs
roiList = erase(datasetLocROIs.ROIname,' ');

nROIs = length(roiList);

% Output matrices
outputMatrix = struct();

outputMatrix.T1w.TValue = zeros(nROIs,nSubjects,nTasks);
outputMatrix.T1w.CoG_vox = zeros(3,nROIs,nSubjects,nTasks);
outputMatrix.T1w.CoG_mm = zeros(3,nROIs,nSubjects,nTasks);
outputMatrix.T1w.PeakVoxTValue = zeros(nROIs,nSubjects,nTasks);
outputMatrix.T1w.PeakVoxCoord_vox = zeros(3,nROIs,nSubjects,nTasks);
outputMatrix.T1w.PeakVoxCoord_mm = zeros(3,nROIs,nSubjects,nTasks);
outputMatrix.MNI152NLin2009ASym.TValue = zeros(nROIs,nSubjects,nTasks);
outputMatrix.MNI152NLin2009ASym.CoG_vox = zeros(3,nROIs,nSubjects,nTasks);
outputMatrix.MNI152NLin2009ASym.CoG_mm = zeros(3,nROIs,nSubjects,nTasks);
outputMatrix.MNI152NLin2009ASym.PeakVoxTValue = zeros(nROIs,nSubjects,nTasks);
outputMatrix.MNI152NLin2009ASym.PeakVoxCoord_vox = zeros(3,nROIs,nSubjects,nTasks);
outputMatrix.MNI152NLin2009ASym.PeakVoxCoord_mm = zeros(3,nROIs,nSubjects,nTasks);

% init spm
spm('defaults', 'FMRI');
spm_jobman('initcfg');
clear matlabbatch

%% Do

% Iterate on the ROIs
for rr = 1:nROIs
    
    roiFile = fullfile(roiFolder,[roiList{rr} '_sphere8mm.nii']);
    
    % Iterate on the subjects
    for ss = 1:nSubjects
        
        % make folder
        subjectOutputROIFolder = fullfile(outputROIFolder,subjectList{ss});
        if ~exist(subjectOutputROIFolder,'dir')
           mkdir(subjectOutputROIFolder); disp('Output subject-ROI folder created.')
        end
        
        % unzip and resample ROIs to MNI152
        clear matlabbatch
        
        matlabbatch{1}.spm.spatial.coreg.write.ref = {fullfile(spm12Folder,subjectList{ss},'model_task-loc_acq-1000_run-1_MNI152NLin2009cAsym','con_0001.nii,1')};
        matlabbatch{1}.spm.spatial.coreg.write.source(1) = {roiFile};
        matlabbatch{1}.spm.spatial.coreg.write.roptions.interp = 4;
        matlabbatch{1}.spm.spatial.coreg.write.roptions.wrap = [0 0 0];
        matlabbatch{1}.spm.spatial.coreg.write.roptions.mask = 0;
        matlabbatch{1}.spm.spatial.coreg.write.roptions.prefix = [subjectList{ss} '_MNI152NLin2009cAsym-reslice_'];
        
        spm_jobman('run', matlabbatch);
        
        newROIName = [subjectList{ss} '_MNI152NLin2009cAsym-reslice_' roiList{rr} '_sphere8mm.nii'];
        movefile(fullfile(roiFolder,newROIName),subjectOutputROIFolder)
        
        %% Extract data in MNI
        % Iterate on the tasks
        for tt = 1:nTasks
            
            % Very custom adjustment - if the ROI is V1 and the task is the
            % localizer, use the second contrast (Static vs. Fixation)
            if tt == 9 && rr>=9
                conString = 'con_0002.nii,1';
            else
                conString = 'con_0001.nii,1';
            end
            
            [outputMatrix.MNI152NLin2009ASym.CoG_vox(:,rr,ss,tt),outputMatrix.MNI152NLin2009ASym.TValue(rr,ss,tt),outputMatrix.MNI152NLin2009ASym.PeakVoxTValue(rr,ss,tt),outputMatrix.MNI152NLin2009ASym.PeakVoxCoord_vox(:,rr,ss,tt),outputMatrix.MNI152NLin2009ASym.CoG_mm(:,rr,ss,tt),outputMatrix.MNI152NLin2009ASym.PeakVoxCoord_mm(:,rr,ss,tt)] = ...
                extractROIdata(...
                    fullfile(subjectOutputROIFolder,newROIName), ...
                    fullfile(spm12Folder,subjectList{ss},['model_' taskList{tt} '_MNI152NLin2009cAsym'],...
                    conString) );
            
        end
        
        %% Transform ROIs to T1w space
        
        transformMatrixFile = fullfile(fmriPrepFolder,subjectList{ss},'anat',[subjectList{ss} '_run-1_from-MNI152NLin2009cAsym_to-T1w_mode-image_xfm.h5']);
        t1wFile = fullfile(fmriPrepFolder,subjectList{ss},'anat',[subjectList{ss} '_run-1_desc-preproc_T1w.nii.gz']);
        
        cmd = sprintf('antsApplyTransforms --dimensionality 3 --input %s --output %s --transform %s --interpolation Linear --reference-image %s',...
            roiFile,...
            fullfile(subjectOutputROIFolder,[subjectList{ss} '_T1w_' roiList{rr} '.nii.gz']),...
            transformMatrixFile,t1wFile);
        
        system(cmd)
        
        %% unzip and resample ROIs to T1w
        clear matlabbatch
        
        matlabbatch{1}.cfg_basicio.file_dir.file_ops.cfg_gunzip_files.files = {fullfile(subjectOutputROIFolder,[subjectList{ss} '_T1w_' roiList{rr} '.nii.gz'])};
        matlabbatch{1}.cfg_basicio.file_dir.file_ops.cfg_gunzip_files.outdir = {subjectOutputROIFolder};
        matlabbatch{1}.cfg_basicio.file_dir.file_ops.cfg_gunzip_files.keep = true;
        
        matlabbatch{2}.spm.spatial.coreg.write.ref = {fullfile(spm12Folder,subjectList{ss},'3d_task-loc_acq-1000_run-1_T1w',['ss' subjectList{ss} '_task-loc_acq-1000_run-1_space-T1w_desc-preproc_bold_00001.nii,1'])};
        matlabbatch{2}.spm.spatial.coreg.write.source(1) = cfg_dep('Gunzip Files: Gunzipped Files', substruct('.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('()',{':'}));
        matlabbatch{2}.spm.spatial.coreg.write.roptions.interp = 4;
        matlabbatch{2}.spm.spatial.coreg.write.roptions.wrap = [0 0 0];
        matlabbatch{2}.spm.spatial.coreg.write.roptions.mask = 0;
        matlabbatch{2}.spm.spatial.coreg.write.roptions.prefix = 'T1w-reslice_';

        spm_jobman('run', matlabbatch);
        
        newROIName = [subjectList{ss} '_T1w-reslice_' roiList{rr} '_sphere8mm.nii'];
        movefile(fullfile(subjectOutputROIFolder,['T1w-reslice_' subjectList{ss} '_T1w_' roiList{rr} '.nii']),...
                 fullfile(subjectOutputROIFolder,newROIName))
        
        %% Extract data in T1w
        for tt = 1:nTasks
            
            % Very custom adjustment - if the ROI is V1 and the task is the
            % localizer, use the second contrast (Static vs. Fixation)
            if tt == 9 && rr>=9
                conString = 'con_0002.nii,1';
            else
                conString = 'con_0001.nii,1';
            end
            
            [outputMatrix.T1w.CoG_vox(:,rr,ss,tt),outputMatrix.T1w.TValue(rr,ss,tt),outputMatrix.T1w.PeakVoxTValue(rr,ss,tt),outputMatrix.T1w.PeakVoxCoord_vox(:,rr,ss,tt),outputMatrix.T1w.CoG_mm(:,rr,ss,tt),outputMatrix.T1w.PeakVoxCoord_mm(:,rr,ss,tt)] = ...
                extractROIdata(...
                    fullfile(subjectOutputROIFolder,newROIName), ...
                    fullfile(spm12Folder,subjectList{ss},['model_' taskList{tt} '_T1w'],...
                    conString) );
            
        end
        
    end
        
end

%% Export output
save(['Output_Step04_' sdcMethod '.mat'])
toc
