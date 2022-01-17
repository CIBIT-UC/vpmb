function [] = executeSPMjob(taskName,spaces,ssKernel,hpfValue,spmFolder,outputFolder,bidsFolder,subjectID)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

fprintf('[executeSPMjob] Started for run %s.\n',taskName)

%% Convert .tsv to SPM multiple conditions file
try % necessary workaround because incorrect run naming (label instead of index)
    tsvFile = fullfile(bidsFolder,subjectID,'func',[subjectID '_' taskName '_events.tsv']);
    tsvTable = importTSVProtocol(tsvFile);
    
catch
    tsvFile = fullfile(bidsFolder,subjectID,'func',[subjectID '_' taskName(1:end-1) '01_events.tsv']);
    tsvTable = importTSVProtocol(tsvFile);
    
end

names = cellstr(unique(tsvTable.Condition));
onsets = cell(size(names));
durations = cell(size(names));

for cc = 1:length(names)
    
    onsets{cc} = tsvTable.Onset(tsvTable.Condition==names{cc})';
    durations{cc} = tsvTable.Duration(tsvTable.Condition==names{cc})';
    
end

save(fullfile(spmFolder,['protocol_' taskName '.mat']),...
    'names','onsets','durations')


%% Fetch run info

%TR
[~,tr]=system(sprintf("echo $(fslinfo %s | grep -m 1 pixdim4 | awk '{print $2}')",fullfile(outputFolder,[subjectID '_' taskName '_space-' spaces{1} '_desc-pnm_bold.nii.gz'])));
tr = str2double(tr);

taskProperName = strsplit(taskName,'_');
taskProperName = taskProperName{1};

%


spm('defaults', 'FMRI');

%% Iterate
for sp = 1:length(spaces)
    
    % Start important folders
    mkdir(fullfile(spmFolder,['3d_' taskName '_' spaces{sp}]))
    mkdir(fullfile(spmFolder,['model_' taskName '_' spaces{sp}]))
    
    clear matlabbatch
    
    matlabbatch{1}.cfg_basicio.file_dir.file_ops.cfg_gunzip_files.files = {fullfile(outputFolder,[subjectID '_' taskName '_space-' spaces{sp} '_desc-pnm_bold.nii.gz'])};
    matlabbatch{1}.cfg_basicio.file_dir.file_ops.cfg_gunzip_files.outdir = {''};
    matlabbatch{1}.cfg_basicio.file_dir.file_ops.cfg_gunzip_files.keep = true;
    
    matlabbatch{2}.spm.util.split.vol(1) = cfg_dep('Gunzip Files: Gunzipped Files', substruct('.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('()',{':'}));
    matlabbatch{2}.spm.util.split.outdir = {fullfile(spmFolder,['3d_' taskName '_' spaces{sp}])};
    
    matlabbatch{3}.spm.spatial.smooth.data(1) = cfg_dep('4D to 3D File Conversion: Series of 3D Volumes', substruct('.','val', '{}',{2}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','splitfiles'));
    matlabbatch{3}.spm.spatial.smooth.fwhm = [ssKernel ssKernel ssKernel];
    matlabbatch{3}.spm.spatial.smooth.dtype = 0;
    matlabbatch{3}.spm.spatial.smooth.im = 0;
    matlabbatch{3}.spm.spatial.smooth.prefix = 'ss';
    
    matlabbatch{4}.spm.stats.fmri_spec.dir = {fullfile(spmFolder,['model_' taskName '_' spaces{sp}])};
    matlabbatch{4}.spm.stats.fmri_spec.timing.units = 'secs';
    matlabbatch{4}.spm.stats.fmri_spec.timing.RT = tr;
    matlabbatch{4}.spm.stats.fmri_spec.timing.fmri_t = 16;
    matlabbatch{4}.spm.stats.fmri_spec.timing.fmri_t0 = 8;
    matlabbatch{4}.spm.stats.fmri_spec.sess.scans(1) = cfg_dep('Smooth: Smoothed Images', substruct('.','val', '{}',{3}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','files'));
    matlabbatch{4}.spm.stats.fmri_spec.sess.cond = struct('name', {}, 'onset', {}, 'duration', {}, 'tmod', {}, 'pmod', {}, 'orth', {});
    matlabbatch{4}.spm.stats.fmri_spec.sess.multi = {fullfile(spmFolder,['protocol_' taskName '.mat'])};
    matlabbatch{4}.spm.stats.fmri_spec.sess.regress = struct('name', {}, 'val', {});
    matlabbatch{4}.spm.stats.fmri_spec.sess.multi_reg = {''};
    matlabbatch{4}.spm.stats.fmri_spec.sess.hpf = hpfValue;
    matlabbatch{4}.spm.stats.fmri_spec.fact = struct('name', {}, 'levels', {});
    matlabbatch{4}.spm.stats.fmri_spec.bases.hrf.derivs = [0 0];
    matlabbatch{4}.spm.stats.fmri_spec.volt = 1;
    matlabbatch{4}.spm.stats.fmri_spec.global = 'None';
    matlabbatch{4}.spm.stats.fmri_spec.mthresh = 0.8;
    matlabbatch{4}.spm.stats.fmri_spec.mask = {''};
    matlabbatch{4}.spm.stats.fmri_spec.cvi = 'FAST';
    
    matlabbatch{5}.spm.stats.fmri_est.spmmat(1) = cfg_dep('fMRI model specification: SPM.mat File', substruct('.','val', '{}',{4}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','spmmat'));
    matlabbatch{5}.spm.stats.fmri_est.write_residuals = 0;
    matlabbatch{5}.spm.stats.fmri_est.method.Classical = 1;
    
    % This is of course task-specific
    switch taskProperName
        case 'task-AA'
            matlabbatch{6}.spm.stats.con.spmmat(1) = cfg_dep('Model estimation: SPM.mat File', substruct('.','val', '{}',{5}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','spmmat'));
            matlabbatch{6}.spm.stats.con.consess{1}.tcon.name = 'AmbiguousVStatic';
            matlabbatch{6}.spm.stats.con.consess{1}.tcon.weights = [1 0 0 -1];
            matlabbatch{6}.spm.stats.con.consess{1}.tcon.sessrep = 'none';
            matlabbatch{6}.spm.stats.con.consess{2}.tcon.name = 'MAEVStatic';
            matlabbatch{6}.spm.stats.con.consess{2}.tcon.weights = [0 0 1 -1];
            matlabbatch{6}.spm.stats.con.consess{2}.tcon.sessrep = 'none';
            matlabbatch{6}.spm.stats.con.delete = 0;
        case 'task-UA'
            matlabbatch{6}.spm.stats.con.spmmat(1) = cfg_dep('Model estimation: SPM.mat File', substruct('.','val', '{}',{5}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','spmmat'));
            matlabbatch{6}.spm.stats.con.consess{1}.tcon.name = 'UnambiguousVStatic';
            matlabbatch{6}.spm.stats.con.consess{1}.tcon.weights = [0 0 -1 1];
            matlabbatch{6}.spm.stats.con.consess{1}.tcon.sessrep = 'none';
            matlabbatch{6}.spm.stats.con.consess{2}.tcon.name = 'MAEVStatic';
            matlabbatch{6}.spm.stats.con.consess{2}.tcon.weights = [0 1 -1 0];
            matlabbatch{6}.spm.stats.con.consess{2}.tcon.sessrep = 'none';
            matlabbatch{6}.spm.stats.con.delete = 0;
        case 'task-loc'
            matlabbatch{6}.spm.stats.con.spmmat(1) = cfg_dep('Model estimation: SPM.mat File', substruct('.','val', '{}',{5}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','spmmat'));
            matlabbatch{6}.spm.stats.con.consess{1}.tcon.name = 'MovingVStatic';
            matlabbatch{6}.spm.stats.con.consess{1}.tcon.weights = [0 0 1 -1];
            matlabbatch{6}.spm.stats.con.consess{1}.tcon.sessrep = 'none';
            matlabbatch{6}.spm.stats.con.consess{2}.tcon.name = 'StaticVFixation';
            matlabbatch{6}.spm.stats.con.consess{2}.tcon.weights = [0 -1 0 1];
            matlabbatch{6}.spm.stats.con.consess{2}.tcon.sessrep = 'none';
            matlabbatch{6}.spm.stats.con.delete = 0;
        otherwise
            disp('something is wrong')
    end
    
    matlabbatch{7}.spm.stats.results.spmmat(1) = cfg_dep('Contrast Manager: SPM.mat File', substruct('.','val', '{}',{6}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','spmmat'));
    matlabbatch{7}.spm.stats.results.conspec.titlestr = '';
    matlabbatch{7}.spm.stats.results.conspec.contrasts = Inf;
    matlabbatch{7}.spm.stats.results.conspec.threshdesc = 'none';
    matlabbatch{7}.spm.stats.results.conspec.thresh = 0.001;
    matlabbatch{7}.spm.stats.results.conspec.extent = 50;
    matlabbatch{7}.spm.stats.results.conspec.conjunction = 1;
    matlabbatch{7}.spm.stats.results.conspec.mask.none = 1;
    matlabbatch{7}.spm.stats.results.units = 1;
    matlabbatch{7}.spm.stats.results.export = cell(1,0);
    
    matlabbatch{8}.spm.util.cat.vols(1) = cfg_dep('Smooth: Smoothed Images', substruct('.','val', '{}',{3}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','files'));
    matlabbatch{8}.spm.util.cat.name = fullfile(outputFolder,[subjectID '_' taskName '_space-' spaces{sp} '_desc-pnmSS_bold.nii']);
    matlabbatch{8}.spm.util.cat.dtype = 4;
    matlabbatch{8}.spm.util.cat.RT = tr;
    
    matlabbatch{9}.cfg_basicio.file_dir.file_ops.cfg_gzip_files.files(1) = cfg_dep('3D to 4D File Conversion: Concatenated 4D Volume', substruct('.','val', '{}',{8}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','mergedfile'));
    matlabbatch{9}.cfg_basicio.file_dir.file_ops.cfg_gzip_files.outdir = {''};
    matlabbatch{9}.cfg_basicio.file_dir.file_ops.cfg_gzip_files.keep = false;
    
    % RUN
    spm_jobman('run', matlabbatch);
    
    % Delete temporary files
    rmdir(fullfile(spmFolder,['3d_' taskName '_' spaces{sp}]),'s')
    delete(fullfile(outputFolder,[subjectID '_' taskName '_space-' spaces{sp} '_desc-pnm_bold.nii']))
    delete(fullfile(outputFolder,[subjectID '_' taskName '_space-' spaces{sp} '_desc-pnmSS_bold.nii']))
    
end

fprintf('[executeSPMjob] Finished for run %s.\n',taskName)

end
