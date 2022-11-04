function PhysioRegressors = computePhysIO(physio_path, subjectID, run_name, nslice, nvol, tr)
%COMPUTEPHYSIO Batch for the PhysIO toolbox pipeline

%tapas_physio_init();

physio = tapas_physio_new();

physio.log_files.vendor = 'BIDS';
physio.log_files.cardiac = {fullfile(physio_path,[subjectID '_' run_name '_recording-cardiac_physio.tsv.gz'])};
physio.log_files.respiration = {fullfile(physio_path,[subjectID '_' run_name '_recording-respiratory_physio.tsv.gz'])};
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

[~, PhysioRegressors, ~] = tapas_physio_main_create_regressors(physio);
%delete([ pwd, '/matlab.mat' ]);

end
