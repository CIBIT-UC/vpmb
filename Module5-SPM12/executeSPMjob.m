function [] = executeSPMjob(taskName,spaces,ssKernel,hpfValue,spmFolder,fmriPrepFolder,bidsFolder,subjectID)
%EXECUTESPMJOB Perform batch in SPM12
%   Spatial smoothing, GLM
%
% Inputs:
%   taskName
%   spaces - a list of spaces to be analysed
%   ssKernel - spatial smoothing kernel (in mm)
%   hpfValue - cut-off value for high-pass filtering (in seconds)
%   spmFolder
%   fmriPrepFolder
%   bidsFolder
%   subjectID
%
% Author: Alexandre Sayal
% CIBIT, University of Coimbra
% February 2022
% ----------------------------------------------------------------------- %
% ----------------------------------------------------------------------- %

fprintf('[executeSPMjob] Started for run %s.\n',taskName)

%% Convert .tsv to SPM multiple conditions file
tsvFile = fullfile(bidsFolder,subjectID,'func',[subjectID '_' taskName '_events.tsv']);
tsvTable = importTSVProtocol(tsvFile);

names = cellstr(unique(tsvTable.trial_type));

% Remove baseline condition from matrix - in this case, it is condition
% called 'Static'
%names(strcmp(names,'Static')) = [];

onsets = cell(size(names));
durations = cell(size(names));

for cc = 1:length(names)
    
    onsets{cc} = tsvTable.onset(tsvTable.trial_type==names{cc})';
    durations{cc} = tsvTable.duration(tsvTable.trial_type==names{cc})';
    
end

save(fullfile(spmFolder,['protocol_' taskName '.mat']),...
    'names','onsets','durations')

%% Run name
taskProperName = strsplit(taskName,'_');
taskProperName = taskProperName{1};

spm('defaults', 'FMRI');

%% Iterate
for sp = 1:length(spaces)
    
    % Get funcImage and TR
    funcImage = fullfile(fmriPrepFolder,subjectID,'func',...
        [subjectID '_' taskName '_space-' spaces{sp} '_desc-preproc_bold.nii.gz']);
    
    [~,tr]=system(sprintf("echo $(fslinfo %s | grep -m 1 pixdim4 | awk '{print $2}')",funcImage));
    tr = str2double(tr);
    
    % Start important folders
    mkdir(fullfile(spmFolder,['3d_' taskName '_' spaces{sp}]))
    mkdir(fullfile(spmFolder,['model_' taskName '_' spaces{sp}]))
    
    clear matlabbatch
    
    matlabbatch{1}.cfg_basicio.file_dir.file_ops.cfg_gunzip_files.files = {funcImage};
    matlabbatch{1}.cfg_basicio.file_dir.file_ops.cfg_gunzip_files.outdir = {spmFolder};
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
    matlabbatch{4}.spm.stats.fmri_spec.sess.multi_reg = {fullfile(spmFolder,[subjectID '_' taskName '_desc-PNMmodel.mat'])};
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
        case 'task-loc'
            matlabbatch{6}.spm.stats.con.spmmat(1) = cfg_dep('Model estimation: SPM.mat File', substruct('.','val', '{}',{5}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','spmmat'));
            matlabbatch{6}.spm.stats.con.consess{1}.tcon.name = 'MovingPlaid > StaticPlaid';
            matlabbatch{6}.spm.stats.con.consess{1}.tcon.weights = [0 0 1 -1];
            matlabbatch{6}.spm.stats.con.consess{1}.tcon.sessrep = 'none';
            matlabbatch{6}.spm.stats.con.consess{2}.tcon.name = 'StaticPlaid > Fixation';
            matlabbatch{6}.spm.stats.con.consess{2}.tcon.weights = [0 -1 0 1];
            matlabbatch{6}.spm.stats.con.consess{2}.tcon.sessrep = 'none';
            matlabbatch{6}.spm.stats.con.consess{3}.fcon.name = 'Effects of interest';
            matlabbatch{6}.spm.stats.con.consess{3}.fcon.weights = eye(4);
            matlabbatch{6}.spm.stats.con.consess{3}.fcon.sessrep = 'none';
            matlabbatch{6}.spm.stats.con.delete = 0;
        case 'task-UA'
            matlabbatch{6}.spm.stats.con.spmmat(1) = cfg_dep('Model estimation: SPM.mat File', substruct('.','val', '{}',{5}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','spmmat'));
            matlabbatch{6}.spm.stats.con.consess{1}.tcon.name = 'Unambiguous > Static';
            matlabbatch{6}.spm.stats.con.consess{1}.tcon.weights = [0 0 -1 1];
            matlabbatch{6}.spm.stats.con.consess{1}.tcon.sessrep = 'none';
            matlabbatch{6}.spm.stats.con.consess{2}.tcon.name = 'MAE > Static';
            matlabbatch{6}.spm.stats.con.consess{2}.tcon.weights = [0 1 -1 0];
            matlabbatch{6}.spm.stats.con.consess{2}.tcon.sessrep = 'none';
            matlabbatch{6}.spm.stats.con.consess{3}.fcon.name = 'Effects of interest';
            matlabbatch{6}.spm.stats.con.consess{3}.fcon.weights = eye(4);
            matlabbatch{6}.spm.stats.con.consess{3}.fcon.sessrep = 'none';
            matlabbatch{6}.spm.stats.con.delete = 0;
        case 'task-AA'
            matlabbatch{6}.spm.stats.con.spmmat(1) = cfg_dep('Model estimation: SPM.mat File', substruct('.','val', '{}',{5}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','spmmat'));
            matlabbatch{6}.spm.stats.con.consess{1}.tcon.name = 'Moving > Static';
            matlabbatch{6}.spm.stats.con.consess{1}.tcon.weights = [1 0 0 -1];
            matlabbatch{6}.spm.stats.con.consess{1}.tcon.sessrep = 'none';
            matlabbatch{6}.spm.stats.con.consess{2}.tcon.name = 'MAE > Static';
            matlabbatch{6}.spm.stats.con.consess{2}.tcon.weights = [0 0 1 -1];
            matlabbatch{6}.spm.stats.con.consess{2}.tcon.sessrep = 'none';
            matlabbatch{6}.spm.stats.con.consess{3}.fcon.name = 'Effects of interest';
            matlabbatch{6}.spm.stats.con.consess{3}.fcon.weights = eye(4);
            matlabbatch{6}.spm.stats.con.consess{3}.fcon.sessrep = 'none';
            matlabbatch{6}.spm.stats.con.delete = 0;
        otherwise
            error('something is wrong');
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
    matlabbatch{8}.spm.util.cat.name = fullfile(spmFolder,[subjectID '_' taskName '_space-' spaces{sp} '_desc-SS_bold.nii']);
    matlabbatch{8}.spm.util.cat.dtype = 4;
    matlabbatch{8}.spm.util.cat.RT = tr;
    
    matlabbatch{9}.cfg_basicio.file_dir.file_ops.cfg_gzip_files.files(1) = cfg_dep('3D to 4D File Conversion: Concatenated 4D Volume', substruct('.','val', '{}',{8}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','mergedfile'));
    matlabbatch{9}.cfg_basicio.file_dir.file_ops.cfg_gzip_files.outdir = {''};
    matlabbatch{9}.cfg_basicio.file_dir.file_ops.cfg_gzip_files.keep = false;
    
    if strcmp(spaces{sp},'T1w') % the images in T1w space do not have the field 'space-x' in the name
        matlabbatch{10}.cfg_basicio.file_dir.file_ops.cfg_gunzip_files.files = {fullfile(fmriPrepFolder,subjectID,'anat',[subjectID '_run-1_desc-preproc_T1w.nii.gz'])};
        matlabbatch{10}.cfg_basicio.file_dir.file_ops.cfg_gunzip_files.outdir = {spmFolder};
        matlabbatch{10}.cfg_basicio.file_dir.file_ops.cfg_gunzip_files.keep = true;
    else
        matlabbatch{10}.cfg_basicio.file_dir.file_ops.cfg_gunzip_files.files = {fullfile(fmriPrepFolder,subjectID,'anat',[subjectID '_run-1_space-' spaces{sp} '_desc-preproc_T1w.nii.gz'])};
        matlabbatch{10}.cfg_basicio.file_dir.file_ops.cfg_gunzip_files.outdir = {spmFolder};
        matlabbatch{10}.cfg_basicio.file_dir.file_ops.cfg_gunzip_files.keep = true;
    end
    
    % RUN
    spm_jobman('run', matlabbatch);
    
    % Delete temporary files
    delete(fullfile(spmFolder,[subjectID '_' taskName '_space-' spaces{sp} '_desc-preproc_bold.nii'])) % unzipped fmriprep output file
    delete(fullfile(spmFolder,['3d_' taskName '_' spaces{sp}],'sub-*.nii')) % 3d volumes unsmoothed
    
end

fprintf('[executeSPMjob] Finished for run %s.\n',taskName)

end
