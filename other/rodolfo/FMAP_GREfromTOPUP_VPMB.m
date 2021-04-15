function FMAP_GREfromTOPUP_VPMB(par, repeat)

p = '/DATAPOOL/VPMB/VPMB-STCIBIT/'; sub = dir([ p, 'VPMBAUS*' ]); nS = length(sub);

if ~par
    for s = 1:nS
        run_FMAP_GREfromTOPUP_VPMB(sub, s, nS, repeat);
    end
else
    try
        parpool('local', 8);
    catch
        poolobj = gcp('nocreate'); delete(poolobj); parpool('local', 8);
    end
    
    parfor s = 1:nS
        run_FMAP_GREfromTOPUP_VPMB(sub, s, nS, repeat);
    end
    
    poolobj = gcp('nocreate'); delete(poolobj);
end

function run_FMAP_GREfromTOPUP_VPMB(sub, s, nS, repeat)

% raw folder
pR = [ sub(s).folder, filesep, sub(s).name, '/RAW/' ];

% analysis folder
pA = [ sub(s).folder, filesep, sub(s).name, '/ANALYSIS/' ];
if ~exist(pA, 'dir'), mkdir(pA); end

% get runs
runs = dir([ pR, 'TASK-*' ]); nR = length(runs);

% TOPUP-related folders
tp = { 'EPI'; 'SPE' }; nT = length(tp);

for r = 1:nR
    
    % run folder @ RAW
    pR_RUN = [ pR, runs(r).name, filesep ]; % run folder @ RAW
    nii = [ pR_RUN, sub(s).name, '_', runs(r).name, '.nii.gz' ];
    nii_str = load_untouch_nii(nii);
    
    % run folder @ ANALYSIS
    pA_RUN = [ pA, runs(r).name, filesep ];
    
    for t = 1:nT
        
        % topup-related folder
        tpf = [ pA_RUN, 'FMAP-', tp{t}, '/work/' ];
        
        % set some variables
        ph = 'GREfromTOPUP-Phase.nii.gz'; % phase difference image
        mag = 'GREfromTOPUP-Magnitude.nii.gz'; % magnitude image
        mag_brain = 'GREfromTOPUP-Magnitude_brain.nii.gz'; % magnitude brain image
        mag_brain_mask = 'GREfromTOPUP-Magnitude_brain_mask.nii.gz'; % magnitude brain mask
        
        % GRE folder @ run folder
        pGRE_RUN = [ pA_RUN, 'FMAP-GRE-', tp{t}, '/' ]; if ~exist(pGRE_RUN, 'dir'), mkdir(pGRE_RUN), end
        
        % work folder @ GRE folder
        work = [ pGRE_RUN, 'work/' ]; if ~exist(work, 'dir'), mkdir(work); end 
        
        % % erode brain mask [6mm] (noisy PH edges)
        cmd = sprintf('fslmaths %s -kernel sphere 6 -ero %s', [ tpf, mag_brain_mask ], [ work, mag_brain_mask ]); system(cmd); clear cmd; 
        
        % apply eroded mask to mag
        cmd = sprintf('fslmaths %s -mas %s %s', [ tpf, mag ], [ tpf, mag_brain_mask ], [ work, mag_brain ]); system(cmd); clear cmd; 
        
        % apply eroded mask to ph
        cmd = sprintf('fslmaths %s -mas %s %s', [ tpf, ph ], [ tpf, mag_brain_mask ], [ work, ph ]); system(cmd); clear cmd; 
        
        % copy mag file
        copyfile([ tpf, mag ], [ work, mag ]);
        
        % final nii
        nii_dc = [ work, 'prestats+dc.feat/filtered_func_data.nii.gz' ];
        
        if ~exist(nii_dc) || repeat(1)
            
            % if to repeat, first remove existing feat directory
            if (exist(nii_dc) && repeat(1)) || (~exist(nii_dc) && exist([ work, 'prestats+dc.feat' ], 'dir')), ...
                    rmdir([ work, 'prestats+dc.feat' ], 's');
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
            fid = fopen([ sub(s).folder, '/prestats+dc_GREfromTOPUP-template.fsf' ], 'r');
            f = fread(fid, '*char')'; fclose(fid);
            
            % replace info on .fsf template file for current dataset
            f = regexprep(f, 'VPMBAUS01', sub(s).name);                                                 % participant
            f = regexprep(f, 'TASK-AA-0500', runs(r).name);                                             % run
            f = regexprep(f, 'FMAP-GRE-EPI', [ 'FMAP-GRE-', tp{t} ]);                                   % TOPUP 
            f = regexprep(f, 'fmri\(tr\) 0.500000', [ 'fmri(tr) ', num2str(tr) ]);                      % TR
            f = regexprep(f, 'fmri\(npts\) 780', [ 'fmri(npts) ', num2str(nvol) ]);                     % volumes
            f = regexprep(f, 'fmri\(dwell\) 0.5771', [ 'fmri(dwell) ', num2str(es) ]);                  % echo spacing
            f = regexprep(f, 'fmri\(te\) 30.20', [ 'fmri(te) ', num2str(te) ]);                         % TE
            f = regexprep(f, 'fmri\(totalVoxels\) 189221760', [ 'fmri(totalVoxels) ', num2str(nvox) ]); % voxels
            
            % write new .fsf file for current dataset
            fid = fopen([ work, 'prestats+dc.fsf' ], 'w');
            fprintf(fid, '%s', f); fclose(fid);
            
            % run .fsf
            fprintf('DC correction with GRE: Subject: %i/%i | Run: %i/%i | TOPUP: %s\n', s, nS, r, nR, tp{t})
            cmd = sprintf('feat %s', [ work, 'prestats+dc.fsf' ]); system(cmd); clear cmd;
            
            % move filtered func data to GRE folder
            cmd = sprintf('mv %s %s', [ work, 'prestats+dc.feat/filtered_func_data.nii.gz' ], [ pGRE_RUN, 'filtered_func_data.nii.gz' ]);
            system(cmd); clear cmd;
            
        end
    end
end
