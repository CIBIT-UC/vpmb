function avg_fmaps_BM(map, repeat)

if strcmpi(map, 'fmap')
    gmap = 'fmap'; smap = 'fieldmap';
elseif strcmpi(map, 'vsm')
    gmap = 'vsm'; smap = 'vsm';
end

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

for c = 1:nC
    
    avg_fmap2std_1mm = zeros([ size(mni1_str.img), nR ]); avg_fmap2std_4mm = zeros([ size(mni4_str.img), nR ]);
    
    % set some variables
    gavg_fmap2std_1mmF = [ gp, 'fmaps/', CORR{c}, '_gavg_', gmap, '2std_1mm.nii.gz' ]; % group avg vsm 1mm across subjects and runs
    gstd_fmap2std_1mmF = [ gp, 'fmaps/', CORR{c}, '_gstd_', gmap, '2std_1mm.nii.gz' ]; % group std vsm 1mm across subjects and runs
    gavg_fmap2std_4mmF = [ gp, 'fmaps/', CORR{c}, '_gavg_', gmap, '2std_4mm.nii.gz' ]; % group avg vsm 4mm across subjects and runs
    gstd_fmap2std_4mmF = [ gp, 'fmaps/', CORR{c}, '_gstd_', gmap, '2std_4mm.nii.gz' ]; % group std vsm 4mm across subjects and runs
    
    for r = 1:nR
        
        % group folder
        gd = [ gp, RUNS{r}, '/', CORR{c}, '/' ];
        
        % set some variables
        avg_fmap2std_1mmF = [ gd, 'avg_', gmap, '2std_1mm.nii.gz' ]; % avg vsm 1mm across subjects
        std_fmap2std_1mmF = [ gd, 'std_', gmap, '2std_1mm.nii.gz' ]; % std vsm 1mm across subjects
        avg_fmap2std_4mmF = [ gd, 'avg_', gmap, '2std_4mm.nii.gz' ]; % avg vsm 4mm across subjects
        std_fmap2std_4mmF = [ gd, 'std_', gmap, '2std_4mm.nii.gz' ]; % std vsm 4mm across subjects
        
        if ~exist(std_fmap2std_4mmF) || repeat
            
            % compute avg vsm across subjects for each run
            [ avg_fmap2std_1mm(:, :, :, r), avg_fmap2std_4mm(:, :, :, r) ] = compute_avg_fmap(avg_fmap2std_1mmF, std_fmap2std_1mmF, ...
                avg_fmap2std_4mmF, std_fmap2std_4mmF, sub, nS, RUNS{r}, CORR{c}, mni1_str, mni4_str, smap);
            
        else
            
            % load avg vsm maps
            aux_1mm = load_untouch_nii(avg_fmap2std_1mmF); avg_fmap2std_1mm(:, :, :, r) = aux_1mm.img;
            aux_4mm = load_untouch_nii(avg_fmap2std_4mmF); avg_fmap2std_4mm(:, :, :, r) = aux_4mm.img;
            
        end
    end
    
    % compute average and std of vsm2std_1mm across subjects
    gavg_fmap2std_1mm = squeeze(mean(avg_fmap2std_1mm, 4));
    gstd_fmap2std_1mm = squeeze(std(avg_fmap2std_1mm, 0, 4));
    
    % save nii files
    mni1_str.img = gavg_fmap2std_1mm; save_untouch_nii(mni1_str, gavg_fmap2std_1mmF);
    mni1_str.img = gstd_fmap2std_1mm; save_untouch_nii(mni1_str, gstd_fmap2std_1mmF);
    
    % compute average and std of vsm2std_4mm across subjects
    gavg_fmap2std_4mm = squeeze(mean(avg_fmap2std_4mm, 4));
    gstd_fmap2std_4mm = squeeze(std(avg_fmap2std_4mm, 0, 4));
    
    % save nii files
    mni4_str.img = gavg_fmap2std_4mm; save_untouch_nii(mni4_str, gavg_fmap2std_4mmF);
    mni4_str.img = gstd_fmap2std_4mm; save_untouch_nii(mni4_str, gstd_fmap2std_4mmF);
end

function [ avg_fmap2std_1mm, avg_fmap2std_4mm ] = compute_avg_fmap(avg_fmap2std_1mmF, std_fmap2std_1mmF, ...
    avg_fmap2std_4mmF, std_fmap2std_4mmF, sub, nS, RUNS, CORR, mni1_str, mni4_str, smap)

[ x1, y1, z1 ] = size(mni1_str.img); [ x4, y4, z4 ] = size(mni4_str.img);

% allocate memory
fmap2std_1mm_nS = zeros(x1, y1, z1, nS); fmap2std_4mm_nS = zeros(x4, y4, z4, nS);

d = []; % idx of subjects to delete

for s = 1:nS
    
    % set some variables
    sd = [ sub(s).folder, filesep, sub(s).name, '/' ]; % subject dir
    rd = [ sd, 'MRI/Analysis/', RUNS, '/', CORR, '/' ]; % run dir
    
    fmap2std_1mmF = [ rd, CORR, '_', smap, '2standard_1mm.nii.gz' ];
    fmap2std_4mmF = [ rd, CORR, '_', smap, '2standard_4mm.nii.gz' ];
    
    if exist(fmap2std_1mmF)
        
        % load vsm2std 1mm
        fmap2std_1mm = load_untouch_nii(fmap2std_1mmF); fmap2std_1mm = fmap2std_1mm.img;
        fmap2std_1mm_nS(:, :, :, s) = fmap2std_1mm;
        
        % load vsm2std 4mm
        fmap2std_4mm = load_untouch_nii(fmap2std_4mmF); fmap2std_4mm = fmap2std_4mm.img;
        fmap2std_4mm_nS(:, :, :, s) = fmap2std_4mm;
        
    else
        d = [ d, s ];
    end
end

% delete subjects
fmap2std_1mm_nS(:, :, :, d) = []; fmap2std_4mm_nS(:, :, :, d) = [];

% compute average and std of vsm2std_1mm across subjects
avg_fmap2std_1mm = squeeze(mean(fmap2std_1mm_nS, 4));
std_fmap2std_1mm = squeeze(std(fmap2std_1mm_nS, 0, 4));

% save nii files
mni1_str.img = avg_fmap2std_1mm; save_untouch_nii(mni1_str, avg_fmap2std_1mmF);
mni1_str.img = std_fmap2std_1mm; save_untouch_nii(mni1_str, std_fmap2std_1mmF);

% compute average and std of vsm2std_4mm across subjects
avg_fmap2std_4mm = squeeze(mean(fmap2std_4mm_nS, 4));
std_fmap2std_4mm = squeeze(std(fmap2std_4mm_nS, 0, 4));

% save nii files
mni4_str.img = avg_fmap2std_4mm; save_untouch_nii(mni4_str, avg_fmap2std_4mmF);
mni4_str.img = std_fmap2std_4mm; save_untouch_nii(mni4_str, std_fmap2std_4mmF);