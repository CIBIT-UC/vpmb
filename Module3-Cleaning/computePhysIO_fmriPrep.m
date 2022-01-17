function PhysioRegressors = computePhysIO_fmriPrep(physio_path, subjectID, run_name, nslice, nvol, tr)
%COMPUTEPHYSIO Batch for the PhysIO toolbox pipeline

%tapas_physio_init();

physio = tapas_physio_new();

physio.log_files.vendor = 'BIDS';
physio.log_files.cardiac = {fullfile(physio_path,[subjectID '_' run_name(1:end-1) '01_recording-cardiac_physio.tsv.gz'])};
physio.log_files.respiration = {fullfile(physio_path,[subjectID '_' run_name(1:end-1) '01_recording-respiratory_physio.tsv.gz'])};
physio.log_files.scan_timing = {''};
physio.log_files.sampling_interval = [];
physio.log_files.relative_start_acquisition = 0;
physio.log_files.align_scan = 'first';
physio.scan_timing.sqpar.Nslices = nslice;
physio.scan_timing.sqpar.NslicesPerBeat = [];
physio.scan_timing.sqpar.TR = tr;
physio.scan_timing.sqpar.Ndummies = 0;
physio.scan_timing.sqpar.Nscans = nvol;
physio.scan_timing.sqpar.onset_slice = 1;
physio.scan_timing.sqpar.time_slice_to_slice = [];
physio.scan_timing.sqpar.Nprep = [];
physio.scan_timing.sync.method = 'scan_timing_log';
physio.scan_timing.sync.nominal = struct([]);
physio.preproc.cardiac.modality = 'PPU';
physio.preproc.cardiac.filter.no = struct([]);
physio.preproc.cardiac.initial_cpulse_select.auto_matched.min = 0.4;
physio.preproc.cardiac.initial_cpulse_select.auto_matched.file = 'initial_cpulse_kRpeakfile.mat';
physio.preproc.cardiac.initial_cpulse_select.auto_matched.max_heart_rate_bpm = 90;
physio.preproc.cardiac.posthoc_cpulse_select.off = struct([]);
%physio.model.output_multiple_regressors = 'multiple_regressors.txt';
%physio.model.output_physio = 'physio.mat';
physio.model.orthogonalise = 'none';
physio.model.censor_unreliable_recording_intervals = false;
physio.model.retroicor.yes.order.c = 3;
physio.model.retroicor.yes.order.r = 4;
physio.model.retroicor.yes.order.cr = 1;
physio.model.rvt.no = struct([]);
physio.model.hrv.no = struct([]);
physio.model.noise_rois.no = struct([]);
physio.model.movement.no = struct([]);
physio.model.other.no = struct([]);
physio.verbose.level = 0;
physio.verbose.fig_output_file = '';
physio.verbose.use_tabs = false;

% physio.log_files.vendor = 'Siemens_Tics';
% physio.log_files.scan_timing = {fullfile(physio_path, [subjectID '_' run_name '_PHYSIO_Info.log' ])};
% physio.log_files.relative_start_acquisition = 0;
% physio.log_files.align_scan = 'first';
% physio.scan_timing.sqpar.Nslices = nslice;
% physio.scan_timing.sqpar.TR = tr;
% physio.scan_timing.sqpar.Ndummies = 0;
% physio.scan_timing.sqpar.Nscans = nvol;
% physio.scan_timing.sqpar.onset_slice = 1;
% physio.scan_timing.sync.method = 'scan_timing_log';
% physio.preproc.cardiac.modality = 'PPU';
% physio.model.orthogonalise = 'none';
% physio.model.censor_unreliable_recording_intervals = false;
% % physio.model.output_multiple_regressors = 'multiple_regressors.txt';
% % physio.model.output_physio = 'physio.mat';
% 
% physio.model.noise_rois.include = false;
% physio.model.noise_rois.thresholds = 0.9;
% physio.model.noise_rois.n_voxel_crop = 0;
% physio.model.noise_rois.n_components = 1;
% physio.model.movement.include = false;
% physio.model.movement.order = 6;
% physio.model.movement.censoring_threshold = 0.5;
% physio.model.movement.censoring_method = 'FD';
% physio.model.other.include = false;
% physio.verbose.level = 0;
% physio.verbose.process_log = cell(0, 1);
% physio.verbose.fig_handles = zeros(0, 1);
% physio.verbose.use_tabs = false;

% % check PULS log file
% if exist(fullfile(physio_path, [subjectID '_' run_name '_PHYSIO_PULS.log' ]),'file')
%     physio.log_files.cardiac = {fullfile(physio_path, [subjectID '_' run_name '_PHYSIO_PULS.log' ])};
%     physio.preproc.cardiac.initial_cpulse_select.method = 'auto_matched';
%     physio.preproc.cardiac.initial_cpulse_select.file = 'initial_cpulse_kRpeakfile.mat';
%     physio.preproc.cardiac.initial_cpulse_select.min = 0.4;
%     physio.preproc.cardiac.posthoc_cpulse_select.method = 'off';
%     physio.preproc.cardiac.posthoc_cpulse_select.percentile = 80;
%     physio.preproc.cardiac.posthoc_cpulse_select.upper_thresh = 60;
%     physio.preproc.cardiac.posthoc_cpulse_select.lower_thresh = 60;
%     
%     physio.model.retroicor.include = true;
%     physio.model.retroicor.order.c = 3;
%     
%     physio.model.hrv.include = true;
%     physio.model.hrv.delays = 0;
%     
%     physio.ons_secs.c_scaling = 1;
% end
% 
% % check RESP log file
% if exist(fullfile(physio_path, [subjectID '_' run_name '_PHYSIO_RESP.log']),'file')
%     physio.log_files.respiration = {fullfile(physio_path, [subjectID '_' run_name '_PHYSIO_RESP.log'])};
%     physio.model.retroicor.order.r = 4;
%     physio.model.retroicor.order.cr = 0;
%     
%     physio.model.rvt.include = true;
%     physio.model.rvt.delays = 0;
%     
%     physio.ons_secs.r_scaling = 1;
% end

[~, PhysioRegressors, ~] = tapas_physio_main_create_regressors(physio);
%delete([ pwd, '/matlab.mat' ]);

end
