
taskList = {'task-AA_acq-0500_run-1','task-AA_acq-0750_run-1','task-AA_acq-1000_run-1','task-AA_acq-2500_run-1','task-UA_acq-0500_run-1','task-UA_acq-0750_run-1','task-UA_acq-1000_run-1','task-UA_acq-2500_run-1','task-loc_acq-1000_run-1'};

space = 'MNI152NLin2009cAsym';

spm('defaults', 'FMRI');

for tt = 1:length(taskList)
    
    try
        
    taskName = taskList{tt};
    
    clear matlabbatch
    
    %% Folder
    spmPath = ['/DATAPOOL/VPMB/VPMB-BIDS-NLREG/derivatives/glm/' taskName '_' space];
    
    if ~exist(spmPath,'dir')
        mkdir(spmPath); disp('Output folder created.')
    end
    
    %% Batch
    
    matlabbatch{1}.spm.stats.factorial_design.dir = {spmPath};
    matlabbatch{1}.spm.stats.factorial_design.des.t1.scans = {
        ['/DATAPOOL/VPMB/VPMB-BIDS-NLREG/derivatives/cleaning/sub-01/spm/model_' taskName '_' space '/con_0001.nii,1']
        ['/DATAPOOL/VPMB/VPMB-BIDS-NLREG/derivatives/cleaning/sub-02/spm/model_' taskName '_' space '/con_0001.nii,1']
        ['/DATAPOOL/VPMB/VPMB-BIDS-NLREG/derivatives/cleaning/sub-03/spm/model_' taskName '_' space '/con_0001.nii,1']
        ['/DATAPOOL/VPMB/VPMB-BIDS-NLREG/derivatives/cleaning/sub-05/spm/model_' taskName '_' space '/con_0001.nii,1']
        ['/DATAPOOL/VPMB/VPMB-BIDS-NLREG/derivatives/cleaning/sub-06/spm/model_' taskName '_' space '/con_0001.nii,1']
        ['/DATAPOOL/VPMB/VPMB-BIDS-NLREG/derivatives/cleaning/sub-07/spm/model_' taskName '_' space '/con_0001.nii,1']
        ['/DATAPOOL/VPMB/VPMB-BIDS-NLREG/derivatives/cleaning/sub-08/spm/model_' taskName '_' space '/con_0001.nii,1']
        ['/DATAPOOL/VPMB/VPMB-BIDS-NLREG/derivatives/cleaning/sub-10/spm/model_' taskName '_' space '/con_0001.nii,1']
        ['/DATAPOOL/VPMB/VPMB-BIDS-NLREG/derivatives/cleaning/sub-11/spm/model_' taskName '_' space '/con_0001.nii,1']
        ['/DATAPOOL/VPMB/VPMB-BIDS-NLREG/derivatives/cleaning/sub-12/spm/model_' taskName '_' space '/con_0001.nii,1']
        ['/DATAPOOL/VPMB/VPMB-BIDS-NLREG/derivatives/cleaning/sub-15/spm/model_' taskName '_' space '/con_0001.nii,1']
        ['/DATAPOOL/VPMB/VPMB-BIDS-NLREG/derivatives/cleaning/sub-16/spm/model_' taskName '_' space '/con_0001.nii,1']
        ['/DATAPOOL/VPMB/VPMB-BIDS-NLREG/derivatives/cleaning/sub-21/spm/model_' taskName '_' space '/con_0001.nii,1']
        ['/DATAPOOL/VPMB/VPMB-BIDS-NLREG/derivatives/cleaning/sub-22/spm/model_' taskName '_' space '/con_0001.nii,1']
        ['/DATAPOOL/VPMB/VPMB-BIDS-NLREG/derivatives/cleaning/sub-23/spm/model_' taskName '_' space '/con_0001.nii,1']
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
    matlabbatch{3}.spm.stats.con.consess{1}.tcon.name = 'Moving>Static';
    matlabbatch{3}.spm.stats.con.consess{1}.tcon.weights = 1;
    matlabbatch{3}.spm.stats.con.consess{1}.tcon.sessrep = 'none';
    matlabbatch{3}.spm.stats.con.delete = 0;
    
    matlabbatch{4}.spm.stats.results.spmmat(1) = cfg_dep('Contrast Manager: SPM.mat File', substruct('.','val', '{}',{3}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','spmmat'));
    matlabbatch{4}.spm.stats.results.conspec.titlestr = '';
    matlabbatch{4}.spm.stats.results.conspec.contrasts = 1;
    matlabbatch{4}.spm.stats.results.conspec.threshdesc = 'none';
    matlabbatch{4}.spm.stats.results.conspec.thresh = 0.05;
    matlabbatch{4}.spm.stats.results.conspec.extent = 0;
    matlabbatch{4}.spm.stats.results.conspec.conjunction = 1;
    matlabbatch{4}.spm.stats.results.conspec.mask.none = 1;
    matlabbatch{4}.spm.stats.results.units = 1;
    matlabbatch{4}.spm.stats.results.export = cell(1, 0);
    
    %% RUN
    spm_jobman('run', matlabbatch);
    
    catch
       fprintf('\n\n  ERROR ON TASK %s  \n\n',upper(taskName))
    end
end