%% -- Step02_Run2ndLevel.m ------------------------------------------------- %%
% ----------------------------------------------------------------------- %
% Script for executing the group GLM for the localizer run for all
% correction methods.
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
% - Preprocessed data by fmriPrep v21
% - SPM12 in path
% - Tapas PhysIO in path
%
% Author: Alexandre Sayal
% CIBIT, University of Coimbra
% October 2022
% ----------------------------------------------------------------------- %
% ----------------------------------------------------------------------- %


methodList = {'NLREG','NONE','SPE','EPI','GRE'};
thisTask = 'task-loc_acq-1000_run-1';
space = 'MNI152NLin2009cAsym';
contrastN = '0002';
contrastName = 'StaticPlaid>Fixation';

spm('defaults', 'FMRI');
spm_jobman('initcfg');

for mm = 1:length(methodList) 
    
    thisMethod = methodList{mm};
    derivativesFolder = ['/DATAPOOL/VPMB/BIDS-VPMB-' thisMethod '/derivatives'];
    
    clear matlabbatch
    
    %% Folder
    spmPath = [derivativesFolder '/spm12/group/' thisTask '_' space '_con-' contrastName];
    
    if ~exist(spmPath,'dir')
        mkdir(spmPath); disp('Output folder created.')
    end
    
    %% Batch
    
    matlabbatch{1}.spm.stats.factorial_design.dir = {spmPath};
    matlabbatch{1}.spm.stats.factorial_design.des.t1.scans = {
        [ derivativesFolder '/spm12/sub-01/model_' thisTask '_' space '/con_' contrastN '.nii,1']
        [ derivativesFolder '/spm12/sub-02/model_' thisTask '_' space '/con_' contrastN '.nii,1']
        [ derivativesFolder '/spm12/sub-03/model_' thisTask '_' space '/con_' contrastN '.nii,1']
        [ derivativesFolder '/spm12/sub-05/model_' thisTask '_' space '/con_' contrastN '.nii,1']
        [ derivativesFolder '/spm12/sub-06/model_' thisTask '_' space '/con_' contrastN '.nii,1']
        [ derivativesFolder '/spm12/sub-07/model_' thisTask '_' space '/con_' contrastN '.nii,1']
        [ derivativesFolder '/spm12/sub-08/model_' thisTask '_' space '/con_' contrastN '.nii,1']
        [ derivativesFolder '/spm12/sub-10/model_' thisTask '_' space '/con_' contrastN '.nii,1']
        [ derivativesFolder '/spm12/sub-11/model_' thisTask '_' space '/con_' contrastN '.nii,1']
        [ derivativesFolder '/spm12/sub-12/model_' thisTask '_' space '/con_' contrastN '.nii,1']
        [ derivativesFolder '/spm12/sub-15/model_' thisTask '_' space '/con_' contrastN '.nii,1']
        [ derivativesFolder '/spm12/sub-16/model_' thisTask '_' space '/con_' contrastN '.nii,1']
        [ derivativesFolder '/spm12/sub-21/model_' thisTask '_' space '/con_' contrastN '.nii,1']
        [ derivativesFolder '/spm12/sub-22/model_' thisTask '_' space '/con_' contrastN '.nii,1']
        [ derivativesFolder '/spm12/sub-23/model_' thisTask '_' space '/con_' contrastN '.nii,1']
        };
    matlabbatch{1}.spm.stats.factorial_design.cov = struct('c', {}, 'cname', {}, 'iCFI', {}, 'iCC', {});
    matlabbatch{1}.spm.stats.factorial_design.multi_cov = struct('files', {}, 'iCFI', {}, 'iCC', {});
    matlabbatch{1}.spm.stats.factorial_design.masking.tm.tm_none = 1;
    matlabbatch{1}.spm.stats.factorial_design.masking.im = 1;
    matlabbatch{1}.spm.stats.factorial_design.masking.em = {''};
    matlabbatch{1}.spm.stats.factorial_design.globalc.g_omit = 1;
    matlabbatch{1}.spm.stats.factorial_design.globalm.gmsca.gmsca_no = 1;
    matlabbatch{1}.spm.stats.factorial_design.globalm.glonorm = 1;
    
    matlabbatch{2}.spm.stats.fmri_est.spmmat(1) = cfg_dep('Factorial design specification: SPM.mat File', substruct('.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','spmmat'));
    matlabbatch{2}.spm.stats.fmri_est.write_residuals = 0;
    matlabbatch{2}.spm.stats.fmri_est.method.Classical = 1;
    
    matlabbatch{3}.spm.stats.con.spmmat(1) = cfg_dep('Model estimation: SPM.mat File', substruct('.','val', '{}',{2}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','spmmat'));
    matlabbatch{3}.spm.stats.con.consess{1}.tcon.name = contrastName;
    matlabbatch{3}.spm.stats.con.consess{1}.tcon.weights = 1;
    matlabbatch{3}.spm.stats.con.consess{1}.tcon.sessrep = 'none';
    matlabbatch{3}.spm.stats.con.delete = 0;
    
    matlabbatch{4}.spm.stats.results.spmmat(1) = cfg_dep('Contrast Manager: SPM.mat File', substruct('.','val', '{}',{3}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','spmmat'));
    matlabbatch{4}.spm.stats.results.conspec.titlestr = '';
    matlabbatch{4}.spm.stats.results.conspec.contrasts = 1;
    matlabbatch{4}.spm.stats.results.conspec.threshdesc = 'FWE';
    matlabbatch{4}.spm.stats.results.conspec.thresh = 0.05;
    matlabbatch{4}.spm.stats.results.conspec.extent = 25;
    matlabbatch{4}.spm.stats.results.conspec.conjunction = 1;
    matlabbatch{4}.spm.stats.results.conspec.mask.none = 1;
    matlabbatch{4}.spm.stats.results.units = 1;
    matlabbatch{4}.spm.stats.results.export = cell(1, 0);
    
    %% RUN
    spm_jobman('run', matlabbatch);
    
end