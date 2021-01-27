function VoxelDisplacement_BM(repeat)

p = '/DATAPOOL/BIOMOTION/'; gp = [ p, 'GROUP_RESULTS/' ];
sub = dir([ p, 'P*_*' ]); nS = length(sub);

% possible runs
RUNS = { 'Localizer'; 'BioMotion_01'; 'BioMotion_02'; 'BioMotion_03'; 'BioMotion_04' };
nR = length(RUNS);

% correction methods
CORR = { 'topup'; 'gfm' }; nC = length(CORR);

% load MNI1mm and MNI4mm
mni1_str = load_untouch_nii([ p, 'MNI1mm.nii.gz' ]); mni1_str.hdr.dime.datatype = 16;
mni4_str = load_untouch_nii([ p, 'MNI4mm.nii.gz' ]); mni4_str.hdr.dime.datatype = 16;

% load info of match between ICs and RSNs
load([ gp, 'Overlap.mat' ]);

% allocate memory
max_rsn_shift = nan(nC, nR, 10); min_rsn_shift = nan(nC, nR, 10); avgAbs_rsn_shift = nan(nC, nR, 10); avgPos_rsn_shift = nan(nC, nR, 10); avgNeg_rsn_shift = nan(nC, nR, 10);
stdAbs_rsn_shift = nan(nC, nR, 10); stdPos_rsn_shift = nan(nC, nR, 10); stdNeg_rsn_shift = nan(nC, nR, 10);

max_act_shift = nan(nC, 2); min_act_shift = nan(nC, 2); avgAbs_act_shift = nan(nC, 2); avgPos_act_shift = nan(nC, 2); avgNeg_act_shift = nan(nC, 2);
stdAbs_act_shift = nan(nC, 2); stdPos_act_shift = nan(nC, 2); stdNeg_act_shift = nan(nC, 2);

for c = 1:nC
    
    count_act = 0;
    
    for r = 1:nR
        
        % group folder
        gd = [ gp, RUNS{r}, '/', CORR{c}, '/' ];
        
        % set some variables
        avg_vsm2std_1mmF = [ gd, 'avg_vsm2std_1mm.nii.gz' ]; % avg vsm 1mm across subjects
        std_vsm2std_1mmF = [ gd, 'std_vsm2std_1mm.nii.gz' ]; % std vsm 1mm across subjects
        avg_vsm2std_4mmF = [ gd, 'avg_vsm2std_4mm.nii.gz' ]; % avg vsm 4mm across subjects
        std_vsm2std_4mmF = [ gd, 'std_vsm2std_4mm.nii.gz' ]; % std vsm 4mm across subjects
        
        if ~exist(std_vsm2std_4mmF) || repeat(1)
            
            % compute avg vsm across subjects for each run
            [ avg_vsm2std_1mm, avg_vsm2std_4mm ] = compute_avg_vsm(avg_vsm2std_1mmF, std_vsm2std_1mmF, ...
                avg_vsm2std_4mmF, std_vsm2std_4mmF, sub, nS, RUNS{r}, CORR{c}, mni1_str, mni4_str);
            
        else
            
            % load avg vsm maps
            avg_vsm2std_1mm = load_untouch_nii(avg_vsm2std_1mmF); avg_vsm2std_1mm = avg_vsm2std_1mm.img;
            avg_vsm2std_4mm = load_untouch_nii(avg_vsm2std_4mmF); avg_vsm2std_4mm = avg_vsm2std_4mm.img;
            
        end
        
        % avg and std vsm within each group RSN (4mm)
        idx = Overlap.Run(r).Correction(c).idx; % get correspondence between ICs and RSNs
        
        % load fMRI ICs
        id = [ gd, 'GroupICA_MNI4mm.gica/' ]; % ICA folder
        ICf = load_untouch_nii([ id, 'melodic_IC.nii.gz' ]); ICf = ICf.img;
        ICf = squeeze(ICf(:, :, :, idx)); nI = size(ICf, 4);
        
        % set threshold for ICs (according to Smith paper)
        thrIC = 3;
        
        for i = 1:nI
            
            % get "IC" mask
            icf = squeeze(ICf(:, :, :, i)); icf(icf < thrIC) = 0; icf(icf > thrIC) = 1;
            
            % compute min, max and avg vsm within each RSN
            vsm = avg_vsm2std_4mm .* icf; % apply IC mask
            
            % extract vsm values
            vsmPos = vsm(vsm >= 0); vsmNeg = vsm(vsm <= 0);
            max_rsn_shift(c, r, i) = max(nonzeros(vsm)); min_rsn_shift(c, r, i) = min(nonzeros(vsm));
            avgAbs_rsn_shift(c, r, i) = mean(nonzeros(abs(vsm))); avgPos_rsn_shift(c, r, i) = mean(nonzeros(vsmPos)); avgNeg_rsn_shift(c, r, i) = mean(nonzeros(vsmNeg));
            stdAbs_rsn_shift(c, r, i) = std(nonzeros(abs(vsm))); stdPos_rsn_shift(c, r, i) = std(nonzeros(vsmPos)); stdNeg_rsn_shift(c, r, i) = std(nonzeros(vsmNeg));
            
        end
        
        % avg and std vsm within group activation maps (1mm)
        
        % thresholds for z-score for localizer and biomotion group activation maps
        thrZ = [ 3, 3.5 ];
        
        if r == 1 || r == 5 % only one map for the biomotion runs
            
            if r == 5 % compute avg vsm across biomotion runs                
                avg_vsm2std_1mm_bm = compute_avg_vsm_bm(gp, RUNS, CORR{c}, r, mni1_str, repeat(2));
            end
            
            count_act = count_act + 1;
            
            if contains(lower(RUNS{r}), 'localizer')
                pm = [ gd, 'localizer.gfeat/cope1.feat' ];
                vsm = avg_vsm2std_1mm;
            else
                pm = [ gp, 'biomotion_', CORR{c}, '_ME.gfeat/cope1.feat' ];
                vsm = avg_vsm2std_1mm_bm;
            end
            
            % load glm map
            actf = [ pm, '/thresh_zstat1_masked.nii.gz' ]; act = load_untouch_nii(actf); act = act.img;
            
            % get "act" mask
            act(act < thrIC) = 0; act(act > thrZ(count_act)) = 1;
            
            % compute min, max and avg vsm within group act maps
            vsm = vsm .* act; % apply act mask
            
            % extract vsm values
            vsmPos = vsm(vsm >= 0); vsmNeg = vsm(vsm <= 0);
            max_act_shift(c, count_act) = max(nonzeros(vsm)); min_act_shift(c, count_act) = min(nonzeros(vsm));
            avgAbs_act_shift(c, count_act) = mean(nonzeros(abs(vsm))); avgPos_act_shift(c, count_act) = mean(nonzeros(vsmPos)); avgNeg_act_shift(c, count_act) = mean(nonzeros(vsmNeg));
            stdAbs_act_shift(c, count_act) = std(nonzeros(abs(vsm))); stdPos_act_shift(c, count_act) = std(nonzeros(vsmPos)); stdNeg_act_shift(c, count_act) = std(nonzeros(vsmNeg));
            
        end
    end
end

% store results
shift.rsn.max = max_rsn_shift; shift.rsn.min = min_rsn_shift; shift.rsn.avgAbs = avgAbs_rsn_shift; shift.rsn.avgPos = avgPos_rsn_shift; shift.rsn.avgNeg = avgNeg_rsn_shift;
shift.rsn.stdAbs = stdAbs_rsn_shift; shift.rsn.stdPos = stdPos_rsn_shift; shift.rsn.stdNeg = stdNeg_rsn_shift;

shift.act.max = max_act_shift; shift.act.min = min_act_shift; shift.act.avgAbs = avgAbs_act_shift; shift.act.avgPos = avgPos_act_shift; shift.act.avgNeg = avgNeg_act_shift;
shift.act.stdAbs = stdAbs_act_shift; shift.act.stdPos = stdPos_act_shift; shift.act.stdNeg = stdNeg_act_shift;

save([ gp, 'shift_rsn_act.mat' ], 'shift');

function [ avg_vsm2std_1mm, avg_vsm2std_4mm ] = compute_avg_vsm(avg_vsm2std_1mmF, std_vsm2std_1mmF, ...
    avg_vsm2std_4mmF, std_vsm2std_4mmF, sub, nS, RUNS, CORR, mni1_str, mni4_str)

[ x1, y1, z1 ] = size(mni1_str.img); [ x4, y4, z4 ] = size(mni4_str.img);

% allocate memory
vsm2std_1mm_nS = zeros(x1, y1, z1, nS); vsm2std_4mm_nS = zeros(x4, y4, z4, nS);

d = []; % idx of subjects to delete

for s = 1:nS
    
    % set some variables
    sd = [ sub(s).folder, filesep, sub(s).name, '/' ]; % subject dir
    rd = [ sd, 'MRI/Analysis/', RUNS, '/', CORR, '/' ]; % run dir
    
    vsm2std_1mmF = [ rd, CORR, '_vsm2standard_1mm.nii.gz' ];
    vsm2std_4mmF = [ rd, CORR, '_vsm2standard_4mm.nii.gz' ];
    
    if exist(vsm2std_1mmF)
        
        % load vsm2std 1mm
        vsm2std_1mm = load_untouch_nii(vsm2std_1mmF); vsm2std_1mm = vsm2std_1mm.img;
        vsm2std_1mm_nS(:, :, :, s) = vsm2std_1mm;
        
        % load vsm2std 4mm
        vsm2std_4mm = load_untouch_nii(vsm2std_4mmF); vsm2std_4mm = vsm2std_4mm.img;
        vsm2std_4mm_nS(:, :, :, s) = vsm2std_4mm;
        
    else
        d = [ d, s ];
    end
end

% delete subjects
vsm2std_1mm_nS(:, :, :, d) = []; vsm2std_4mm_nS(:, :, :, d) = [];

% compute average and std of vsm2std_1mm across subjects
avg_vsm2std_1mm = squeeze(mean(vsm2std_1mm_nS, 4));
std_vsm2std_1mm = squeeze(std(vsm2std_1mm_nS, 0, 4));

% save nii files
mni1_str.img = avg_vsm2std_1mm; save_untouch_nii(mni1_str, avg_vsm2std_1mmF);
mni1_str.img = std_vsm2std_1mm; save_untouch_nii(mni1_str, std_vsm2std_1mmF);

% compute average and std of vsm2std_4mm across subjects
avg_vsm2std_4mm = squeeze(mean(vsm2std_4mm_nS, 4));
std_vsm2std_4mm = squeeze(std(vsm2std_4mm_nS, 0, 4));

% save nii files
mni4_str.img = avg_vsm2std_4mm; save_untouch_nii(mni4_str, avg_vsm2std_4mmF);
mni4_str.img = std_vsm2std_4mm; save_untouch_nii(mni4_str, std_vsm2std_4mmF);

function avg_vsm2std_1mm_bm = compute_avg_vsm_bm(gp, RUNS, CORR, r, mni1_str, repeat)

avg_vsm2std_1mm_bmF = [ gp, 'fmaps/', CORR, '_avg_vsm2std_1mm_bm.nii.gz' ];
std_vsm2std_1mm_bmF = [ gp, 'fmaps/', CORR, '_std_vsm2std_1mm_bm.nii.gz' ];

if ~exist(std_vsm2std_1mm_bmF) || repeat
    
    [ x1, y1, z1 ] = size(mni1_str.img);
    vsm2std_1mm_bm = zeros(x1, y1, z1, length(2:r));
    
    for rr = 2:r
        % group folder
        gd = [ gp, RUNS{r}, '/', CORR, '/' ];
        
        % load avg vsm
        vsm2std_1mm_aux = load_untouch_nii([ gd, 'avg_vsm2std_1mm.nii.gz' ]); vsm2std_1mm_aux = vsm2std_1mm_aux.img;
        vsm2std_1mm_bm(:, :, :, rr) = vsm2std_1mm_aux;
    end
    
    % compute avg and std across BM runs
    avg_vsm2std_1mm_bm = squeeze(mean(vsm2std_1mm_bm, 4));
    std_vsm2std_1mm_bm = squeeze(std(vsm2std_1mm_bm, 0, 4));
    
    % save nii files
    mni1_str.img = avg_vsm2std_1mm_bm; save_untouch_nii(mni1_str, avg_vsm2std_1mm_bmF);
    mni1_str.img = std_vsm2std_1mm_bm; save_untouch_nii(mni1_str, std_vsm2std_1mm_bmF);
    
else
    % load vsm
    avg_vsm2std_1mm_bm = load_untouch_nii(avg_vsm2std_1mm_bmF); avg_vsm2std_1mm_bm = avg_vsm2std_1mm_bm.img;
end