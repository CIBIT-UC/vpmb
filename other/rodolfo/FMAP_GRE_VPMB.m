function FMAP_GRE_VPMB(par, repeat)

p = '/DATAPOOL/VPMB/VPMB-STCIBIT/'; sub = dir([ p, 'VPMBAUS*' ]); nS = length(sub);

if ~par
    
    fprintf('DC correction with GRE ------>\n\n')
    
    for s = 1:nS
        run_FMAP_GRE_VPMB(sub, s, nS, repeat);
    end
else
    try
        parpool('local', 8);
    catch
        poolobj = gcp('nocreate'); delete(poolobj); parpool('local', 8);
    end
    
    fprintf('DC correction with GRE ------>\n\n')
    
    parfor s = 1:nS
        run_FMAP_GRE_VPMB(sub, s, nS, repeat);
    end
    
    poolobj = gcp('nocreate'); delete(poolobj);
end

function run_FMAP_GRE_VPMB(sub, s, nS, repeat)

% raw folder
pR = [ sub(s).folder, filesep, sub(s).name, '/RAW/' ];

% analysis folder
pA = [ sub(s).folder, filesep, sub(s).name, '/ANALYSIS/' ];
if ~exist(pA, 'dir'), mkdir(pA); end

% create subfolder in ANALYSIS as in RAW
f = dir([ pR, 'T*' ]); nF = length(f);
for i = 1:nF, if ~exist([ pA, f(i).name ], 'dir'), mkdir([ pA, f(i).name ]); end; end

% get runs
runs = dir([ pR, 'TASK-*' ]); nR = length(runs);

% prepare GRE data (the same for all runs)
R = 1;

% set some variables
pR_RUN = [ runs(R).folder, filesep, runs(R).name, filesep ]; % run folder @ RAW
aux_mag = [ pR_RUN, sub(s).name, '_FMAP-GRE-E2.nii.gz' ]; % magnitude image (2nd echo)
aux_ph = [ pR_RUN, sub(s).name, '_FMAP-GRE-PH.nii.gz' ]; % phase difference image

% GRE folder
pGRE = [ pA, 'FMAP-GRE/' ]; if ~exist(pGRE, 'dir'), mkdir(pGRE); end

% brain extraction on mag with FSL
mag = [ pGRE, sub(s).name, '_FMAP-GRE-E2.nii.gz' ]; copyfile(aux_mag, mag);
mag_brain = [ mag(1:end-7), '_brain.nii.gz' ];
mag_brain_mask = [ mag(1:end-7), '_brain_mask.nii.gz' ];

if ~exist(mag_brain) || repeat(1)
    
    cmd = sprintf('bet %s %s -R -m', mag, mag_brain); system(cmd); clear cmd; % run bet
    cmd = sprintf('fslmaths %s -kernel sphere 4 -ero %s', mag_brain_mask, mag_brain_mask); system(cmd); clear cmd; % erode brain mask [4mm] (noisy PH edges)
    cmd = sprintf('fslmaths %s -mas %s %s', mag_brain, mag_brain_mask, mag_brain); system(cmd); clear cmd; % apply eroded mask to mag
    
end

% convert ph to rad/s
ph = [ pGRE, sub(s).name, '_FMAP-GRE-PH.nii.gz' ]; copyfile(aux_ph, ph);
ph_rads = [ pGRE, sub(s).name, '_FMAP-GRE-PH_rads.nii.gz' ];
dw = 2.46; % difference between TEs (specific for 3T) [ms]

if ~exist(ph_rads) || repeat(2)
    cmd = sprintf('fsl_prepare_fieldmap SIEMENS %s %s %s %f', ph, mag_brain, ph_rads, dw); system(cmd); clear cmd;
end

for r = 1:nR
    
    % run folder @ RAW
    pR_RUN = [ pR, runs(r).name, filesep ]; % run folder @ RAW
    nii = [ pR_RUN, sub(s).name, '_', runs(r).name, '.nii.gz' ];
    nii_str = load_untouch_nii(nii);
    
    % run folder @ ANALYSIS
    pA_RUN = [ pA, runs(r).name, filesep ];
    
    % GRE folder @ run folder
    pGRE_RUN = [ pA_RUN, 'FMAP-GRE/' ]; if ~exist(pGRE_RUN, 'dir'), mkdir(pGRE_RUN); end
    
    % final nii
    nii_dc = [ pGRE_RUN, 'prestats+dc.feat/filtered_func_data.nii.gz' ];
    
    if ~exist(nii_dc) || repeat(3)
        
        % if to repeat, first remove existing feat directory
        if (exist(nii_dc) && repeat(3)) || (~exist(nii_dc) && exist([ pGRE_RUN, 'prestats+dc.feat' ], 'dir')), ...
                rmdir([ pGRE_RUN, 'prestats+dc.feat' ], 's'); 
        end
        
        % load json from func data and get some parameters
        func_bs = [ pR_RUN, sub(s).name, '_', runs(r).name ]; % func basename
        json = loadjson([ func_bs, '.json' ]);
        
        st = json.SliceTiming;                 % slice timing [ms]
        te = json.EchoTime * 1000;             % TE [ms]
        es = json.EffectiveEchoSpacing * 1000; % echo spacing or dwell time [ms]
        tr = json.RepetitionTime;              % TR [s]
        nvol = nii_str.hdr.dime.dim(5);        % number of volumes
        nvox = numel(nii_str.img);             % number of voxels (zero and non-zero)
        
        % convert slice timing to slice order (for FSL)
        bg = find(st == 0); % find the "beginning" of SMS
        sms = length(find(bg));
        
        if sms > 1
            st_aux = st(bg(1):bg(2) - 1);
            [ ~, srt1 ] = sort(st_aux); [ ~, srt_aux ] = sort(srt1);
            stO = []; for i = 1:length(bg), stO = [ stO, srt_aux ]; end
        else
            [ ~, srt1 ] = sort(st); [ ~, stO ] = sort(srt1);
        end
        
        % save slice order in txt file for use in FEAT
        st_file = [ pA_RUN, 'st_order.txt' ]; dlmwrite(st_file, stO, '\n');
        
        % open .fsf template file
        fid = fopen([ sub(s).folder, '/prestats+dc_GRE-template.fsf' ], 'r');
        f = fread(fid, '*char')'; fclose(fid);
        
        % replace info on .fsf template file for current dataset
        f = regexprep(f, 'VPMBAUS01', sub(s).name);                                                 % participant
        f = regexprep(f, 'TASK-AA-0500', runs(r).name);                                             % run
        f = regexprep(f, 'fmri\(tr\) 0.500000', [ 'fmri(tr) ', num2str(tr) ]);                      % TR
        f = regexprep(f, 'fmri\(npts\) 780', [ 'fmri(npts) ', num2str(nvol) ]);                     % volumes
        f = regexprep(f, 'fmri\(dwell\) 0.5771', [ 'fmri(dwell) ', num2str(es) ]);                  % echo spacing
        f = regexprep(f, 'fmri\(te\) 30.20', [ 'fmri(te) ', num2str(te) ]);                         % TE
        f = regexprep(f, 'fmri\(totalVoxels\) 189221760', [ 'fmri(totalVoxels) ', num2str(nvox) ]); % voxels
        
        % write new .fsf file for current dataset
        fid = fopen([ pGRE_RUN, 'prestats+dc.fsf' ], 'w');
        fprintf(fid, '%s', f); fclose(fid);
        
        % run .fsf
        fprintf('Subject: %i/%i | Run: %i/%i\n', s, nS, r, nR)
        cmd = sprintf('feat %s', [ pGRE_RUN, 'prestats+dc.fsf' ]); system(cmd); clear cmd;
        
    end    
end
