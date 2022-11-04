function [] = executeMultiRun(spmFolder,subjectID,nTasks)
%UNTITLED3 Summary of this function goes here
%   Detailed explanation goes here

clear matlabbatch

% execute batch
matlabbatch{1}.spm.stats.fmri_spec.dir = {fullfile(spmFolder,'model_task-inhib_run-all_MNI152NLin2009cAsym')};
matlabbatch{1}.spm.stats.fmri_spec.timing.units = 'secs';
matlabbatch{1}.spm.stats.fmri_spec.timing.RT = 1;
matlabbatch{1}.spm.stats.fmri_spec.timing.fmri_t = 16;
matlabbatch{1}.spm.stats.fmri_spec.timing.fmri_t0 = 8;
%
for tt=1:nTasks
    
    auxDir = dir(fullfile(spmFolder,sprintf('3d_task-inhib_run-%i_MNI152NLin2009cAsym',tt),'*.nii'));
    matlabbatch{1}.spm.stats.fmri_spec.sess(tt).scans = fullfile({auxDir.folder},{auxDir.name})';
    matlabbatch{1}.spm.stats.fmri_spec.sess(tt).cond = struct('name', {}, 'onset', {}, 'duration', {}, 'tmod', {}, 'pmod', {}, 'orth', {});
    matlabbatch{1}.spm.stats.fmri_spec.sess(tt).multi = {fullfile(spmFolder,sprintf('protocol_task-inhib_run-%i.mat',tt))};
    matlabbatch{1}.spm.stats.fmri_spec.sess(tt).regress = struct('name', {}, 'val', {});
    matlabbatch{1}.spm.stats.fmri_spec.sess(tt).multi_reg = {fullfile(spmFolder,sprintf('%s_ses-01_task-inhib_run-%i_desc-PNMmodel.mat',subjectID,tt))};
    matlabbatch{1}.spm.stats.fmri_spec.sess(tt).hpf = 60;
    
end
%
matlabbatch{1}.spm.stats.fmri_spec.fact = struct('name', {}, 'levels', {});
matlabbatch{1}.spm.stats.fmri_spec.bases.hrf.derivs = [0 0];
matlabbatch{1}.spm.stats.fmri_spec.volt = 1;
matlabbatch{1}.spm.stats.fmri_spec.global = 'None';
matlabbatch{1}.spm.stats.fmri_spec.mthresh = 0.8;
matlabbatch{1}.spm.stats.fmri_spec.mask = {''};
matlabbatch{1}.spm.stats.fmri_spec.cvi = 'FAST';
%
matlabbatch{2}.spm.stats.fmri_est.spmmat(1) = cfg_dep('fMRI model specification: SPM.mat File', substruct('.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','spmmat'));
matlabbatch{2}.spm.stats.fmri_est.write_residuals = 0;
matlabbatch{2}.spm.stats.fmri_est.method.Classical = 1;
%
matlabbatch{3}.spm.stats.con.spmmat(1) = cfg_dep('Model estimation: SPM.mat File', substruct('.','val', '{}',{2}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','spmmat'));
matlabbatch{3}.spm.stats.con.consess{1}.tcon.name = 'Coherent > Static';
matlabbatch{3}.spm.stats.con.consess{1}.tcon.weights = [0 0 0 1 0 0 0 0 0 0 0 0 -1];
matlabbatch{3}.spm.stats.con.consess{1}.tcon.sessrep = 'replsc';
matlabbatch{3}.spm.stats.con.consess{2}.tcon.name = 'Incoherent > Static';
matlabbatch{3}.spm.stats.con.consess{2}.tcon.weights = [0 0 0 0 0 0 0 0 1 0 0 0 -1];
matlabbatch{3}.spm.stats.con.consess{2}.tcon.sessrep = 'replsc';
matlabbatch{3}.spm.stats.con.consess{3}.tcon.name = 'NonAdapt > Static';
matlabbatch{3}.spm.stats.con.consess{3}.tcon.weights = [0 0 0 0 0 0 0 0 0 0 1 0 -1];
matlabbatch{3}.spm.stats.con.consess{3}.tcon.sessrep = 'replsc';
matlabbatch{3}.spm.stats.con.consess{4}.tcon.name = 'Coherent+Incoherent+NonAdapt > Static';
matlabbatch{3}.spm.stats.con.consess{4}.tcon.weights = [0 0 0 1 0 0 0 0 1 0 1 0 -3];
matlabbatch{3}.spm.stats.con.consess{4}.tcon.sessrep = 'replsc';
matlabbatch{3}.spm.stats.con.consess{5}.fcon.name = 'Effects of interest';
matlabbatch{3}.spm.stats.con.consess{5}.fcon.weights = eye(13);
matlabbatch{3}.spm.stats.con.consess{5}.fcon.sessrep = 'replsc';
matlabbatch{3}.spm.stats.con.consess{6}.tcon.name = 'Coh_aCoh > Coherent';
matlabbatch{3}.spm.stats.con.consess{6}.tcon.weights = [1 0 0 -1 0 0 0 0 0 0 0 0 0];
matlabbatch{3}.spm.stats.con.consess{6}.tcon.sessrep = 'replsc';
matlabbatch{3}.spm.stats.con.consess{7}.tcon.name = 'InCoh_aCoh > Coherent';
matlabbatch{3}.spm.stats.con.consess{7}.tcon.weights = [0 0 0 -1 0 1 0 0 0 0 0 0 0];
matlabbatch{3}.spm.stats.con.consess{7}.tcon.sessrep = 'replsc';
matlabbatch{3}.spm.stats.con.consess{8}.tcon.name = 'Coh_aInCoh > Incoherent';
matlabbatch{3}.spm.stats.con.consess{8}.tcon.weights = [0 1 0 0 0 0 0 0 -1 0 0 0 0];
matlabbatch{3}.spm.stats.con.consess{8}.tcon.sessrep = 'replsc';
matlabbatch{3}.spm.stats.con.consess{9}.tcon.name = 'InCoh_aInCoh > Incoherent';
matlabbatch{3}.spm.stats.con.consess{9}.tcon.weights = [0 0 0 0 0 0 1 0 -1 0 0 0 0];
matlabbatch{3}.spm.stats.con.consess{9}.tcon.sessrep = 'replsc';
matlabbatch{3}.spm.stats.con.consess{10}.tcon.name = 'Coh_aNA > NonAdapt';
matlabbatch{3}.spm.stats.con.consess{10}.tcon.weights = [0 0 1 0 0 0 0 0 0 0 -1 0 0];
matlabbatch{3}.spm.stats.con.consess{10}.tcon.sessrep = 'replsc';
matlabbatch{3}.spm.stats.con.consess{11}.tcon.name = 'InCoh_aNA > NonAdapt';
matlabbatch{3}.spm.stats.con.consess{11}.tcon.weights = [0 0 0 0 0 0 0 1 0 0 -1 0 0];
matlabbatch{3}.spm.stats.con.consess{11}.tcon.sessrep = 'replsc';
matlabbatch{3}.spm.stats.con.delete = 1;

% RUN
spm_jobman('run', matlabbatch);

end

