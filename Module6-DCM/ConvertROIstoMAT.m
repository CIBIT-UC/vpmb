clear,clc

%% Settings
roiList = {'leftV3a','rightV3a';'lefthMT+','righthMT+';'leftSPL','rightSPL'};
finalROINames = {'V3a','hMT','SPL'};
nROIs = 3; %yes, three, not six, will be bilateral.

roiFolder = '/DATAPOOL/VPMB/BIDS-VPMB-SPE/derivatives/ROI_spherical';
%/sub-01/sub-01_MNI152NLin2009cAsym-reslice_lefthMT+_sphere8mm.nii
spmMatFolder = '/DATAPOOL/VPMB/BIDS-VPMB-SPE/derivatives/spm12/';
%sub-01/model_task-AA_acq-0500_run-1_MNI152NLin2009cAsym/SPM.mat

%% data input

subjectList = {'01';'02';'03';'05';'06';'07';'08';'10';'11';'12';'15';'16';'21';'22';'23'};

runList = {'AA','UA'};
trList = {'0500','0750','1000','2500'};
trValues = [0.5, 0.75, 1, 2.5];

nSubjects = length(subjectList);
[combSub,combTR,combRun] = meshgrid(1:nSubjects,1:4,1:2);
nCombs = length(subjectList)*4*2;

%% Iterate
spm('defaults', 'FMRI');
spm_jobman('initcfg');


for rr = 1:nROIs
       
    for cc = 1:nCombs
        
        roi1 = fullfile(roiFolder,['sub-' subjectList{combSub(cc)}],['sub-' subjectList{combSub(cc)} '_MNI152NLin2009cAsym-reslice_' roiList{rr,1} '_sphere8mm.nii']);
        roi2 = fullfile(roiFolder,['sub-' subjectList{combSub(cc)}],['sub-' subjectList{combSub(cc)} '_MNI152NLin2009cAsym-reslice_' roiList{rr,2} '_sphere8mm.nii']);
        
        spmMat = fullfile(spmMatFolder,['sub-' subjectList{combSub(cc)}],...
            ['model_task-' runList{combRun(cc)} '_acq-' trList{combTR(cc)} '_run-1_MNI152NLin2009cAsym'],'SPM.mat');
        
        if ~exist(fullfile('/DATAPOOL/home/alexandresayal/GitRepos/vpmb/Module6-DCM','GLMrois',['sub-' subjectList{combSub(cc)}],['task-' runList{combRun(cc)} '_tr-' trList{combTR(cc)}]),'dir')
            mkdir(fullfile('/DATAPOOL/home/alexandresayal/GitRepos/vpmb/Module6-DCM','GLMrois',['sub-' subjectList{combSub(cc)}],['task-' runList{combRun(cc)} '_tr-' trList{combTR(cc)}]));
        end
        
        roi3 = fullfile('/DATAPOOL/home/alexandresayal/GitRepos/vpmb/Module6-DCM','GLMrois',['sub-' subjectList{combSub(cc)}],['task-' runList{combRun(cc)} '_tr-' trList{combTR(cc)}],...
            finalROINames{rr});
        
        %%
        clear matlabbatch

        matlabbatch{1}.spm.util.voi.spmmat = cellstr(spmMat);
        matlabbatch{1}.spm.util.voi.adjust = 3;
        matlabbatch{1}.spm.util.voi.session = 1;
        matlabbatch{1}.spm.util.voi.name = roi3;
        matlabbatch{1}.spm.util.voi.roi{1}.mask.image = cellstr([roi1 ',1']);
        matlabbatch{1}.spm.util.voi.roi{1}.mask.threshold = 0.5;
        matlabbatch{1}.spm.util.voi.roi{2}.mask.image = cellstr([roi2 ',1']);
        matlabbatch{1}.spm.util.voi.roi{2}.mask.threshold = 0.5;
        matlabbatch{1}.spm.util.voi.expression = 'i1 | i2';

        %% RUN
        spm_jobman('run', matlabbatch);


    end

end