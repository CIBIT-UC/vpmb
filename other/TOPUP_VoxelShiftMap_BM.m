function TOPUP_VoxelShiftMap_BM(par, repeat)

p = '/DATAPOOL/BIOMOTION/';
sub = dir([ p, 'P*_*' ]); nS = length(sub);

if ~par
    
    for s = 1:nS
        [ max_shift(s, :), min_shift(s, :), avgAbs_shift(s, :), avgPos_shift(s, :), avgNeg_shift(s, :), ...
            max_b0(s, :), min_b0(s, :), avgAbs_b0(s, :), avgPos_b0(s, :), avgNeg_b0(s, :) ] = ...
            run_TOPUP_VoxelShiftMap_BM(sub, s, repeat);
    end
    
else
    try
        parpool('local', 10);
    catch
        poolobj = gcp('nocreate'); delete(poolobj); parpool('local', 10);
    end
    
    max_shift_aux = cell(1, nS); min_shift_aux = cell(1, nS); avgAbs_shift = cell(1, nS);
    avgPos_shift_aux = cell(1, nS); avgNeg_shift_aux = cell(1, nS);
    
    max_b0_aux = cell(1, nS); min_b0_aux = cell(1, nS); avgAbs_b0_aux = cell(1, nS);
    avgPos_b0_aux = cell(1, nS); avgNeg_b0_aux = cell(1, nS);
    
    parfor s = 1:nS
        [ max_shift_aux{s}, min_shift_aux{s}, avgAbs_shift_aux{s}, avgPos_shift_aux{s}, avgNeg_shift_aux{s}, ...
            max_b0_aux{s}, min_b0_aux{s}, avgAbs_b0_aux{s}, avgPos_b0_aux{s}, avgNeg_b0_aux{s} ] = ...
            run_TOPUP_VoxelShiftMap_BM(sub, s, repeat);
    end
    
    poolobj = gcp('nocreate'); delete(poolobj);
    
    for s = 1:nS
        max_shift(s, :) = max_shift_aux{s}; min_shift(s, :) = min_shift_aux{s}; avgAbs_shift(s, :) = avgAbs_shift_aux{s};
        avgPos_shift(s, :) = avgPos_shift_aux{s}; avgNeg_shift(s, :) = avgNeg_shift_aux{s};
        
        max_b0(s, :) = max_b0_aux{s}; min_b0(s, :) = min_b0_aux{s}; avgAbs_b0(s, :) = avgAbs_b0_aux{s};
        avgPos_b0(s, :) = avgPos_b0_aux{s}; avgNeg_b0(s, :) = avgNeg_b0_aux{s};
    end
end

% store results
fmap.shift.max = max_shift; fmap.shift.min = min_shift; fmap.shift.avgAbs = avgAbs_shift; fmap.shift.avgPos = avgPos_shift; fmap.shift.avgNeg = avgNeg_shift;
fmap.b0.max = max_b0; fmap.b0.min = min_b0; fmap.b0.avgAbs = avgAbs_b0; fmap.b0.avgPos = avgPos_b0; fmap.b0.avgNeg = avgNeg_b0;

save([ p, 'GROUP_RESULTS/fmap_topup.mat' ], 'fmap');

function [ max_shift, min_shift, avgAbs_shift, avgPos_shift, avgNeg_shift, ...
    max_b0, min_b0, avgAbs_b0, avgPos_b0, avgNeg_b0 ] = run_TOPUP_VoxelShiftMap_BM(sub, s, repeat)

% set some variable
sd = [ sub(s).folder, filesep, sub(s).name, '/' ]; % subject dir
nd = [ sd, 'MRI/NIFTI/' ]; % nifti dir
ad = [ sd, 'MRI/Analysis/' ]; % analysis dir

% possible runs
RUNS = { 'Localizer'; 'BioMotion_01'; 'BioMotion_02'; 'BioMotion_03'; 'BioMotion_04' };
nR = length(RUNS);

% initialize variables
max_shift = nan(1, nR); min_shift = nan(1, nR); avgAbs_shift = nan(1, nR); avgPos_shift = nan(1, nR); avgNeg_shift = nan(1, nR);
max_b0 = nan(1, nR); min_b0 = nan(1, nR); avgAbs_b0 = nan(1, nR); avgPos_b0 = nan(1, nR); avgNeg_b0 = nan(1, nR);

for r = 1:nR
    
    rd = [ ad, RUNS{r}, '/topup/' ];
    
    % some variables
    tp_in = [ rd, 'topup_input.nii.gz' ];   % PA and AP distorted images
    tp_info = [ nd, 'topup_info.txt' ];     % txt files with PE direction
    config = [ sub(s).folder, '/topup_parameters.cnf' ]; % configuration file (same for diffusion)
    fmap = [ rd, 'topup_fieldmap.nii.gz' ]; % field map [Hz]
    vsm = [ rd, 'topup_vsm.nii.gz' ]; % voxel shift map
    
    if exist(tp_in)
        
        if ~exist(fmap) || repeat(1)
            
            cmd = sprintf('topup --imain=%s --datain=%s --config=%s --fout=%s', tp_in, tp_info, config, fmap);
            system(cmd); clear cmd;
            
        end
        
        if ~exist(vsm) || repeat(2)
            
            % get matrix size
            hdr = load_untouch_header_only(tp_in); ny = hdr.dime.dim(3); % also number of echoes
            echo_spacing = 0.57 / 1000; % time between echoes (=time between PE lines) [s]
            GRAPPA = 2; % in-plane acceleration factor
            PE_readout = 1 / (echo_spacing * ny); % readout in the PE direction [Hz/pixel]
            factor = PE_readout * GRAPPA;
            
            % fsl command
            cmd = sprintf('fslmaths %s -div %f %s', fmap, factor, vsm); system(cmd); clear cmd;
            
        end
        
        % vsm and fmap in MNI 4mm space
        fmap2std = [ rd, 'topup_fieldmap2standard_4mm.nii.gz' ];
        vsm2std = [ rd, 'topup_vsm2standard_4mm.nii.gz' ];
        
        if ~exist(vsm2std) || repeat(3)
            
            mni1mm = '/SCRATCH/software/fsl/data/standard/MNI152_T1_1mm.nii.gz';
            mni1mm_brain = '/SCRATCH/software/fsl/data/standard/MNI152_T1_1mm_brain.nii.gz';
            warp = [ rd, 'example_func2standard_warp.nii.gz' ];
            
            % transform fmap -> std 1mm, apply mask and downsample to 2 and 4 mm
            fmap2std_1mm = [ rd, 'topup_fieldmap2standard_1mm.nii.gz' ];
            fmap2std_2mm = [ rd, 'topup_fieldmap2standard_2mm.nii.gz' ];
            cmd = sprintf('applywarp -r %s -i %s -o %s -w %s --interp=nn', mni1mm, fmap, fmap2std_1mm, warp); system(cmd); clear cmd;
            cmd = sprintf('fslmaths %s -mas %s %s', fmap2std_1mm, mni1mm_brain, fmap2std_1mm); system(cmd); clear cmd;
            cmd = sprintf('flirt -in %s -ref %s -applyisoxfm 2 -out %s -interp nearestneighbour', fmap2std_1mm, fmap2std_1mm, fmap2std_2mm); system(cmd); clear cmd;
            cmd = sprintf('flirt -in %s -ref %s -applyisoxfm 4 -out %s -interp nearestneighbour', fmap2std_1mm, fmap2std_1mm, fmap2std); system(cmd); clear cmd;
            
            % transform vsm -> std 1mm, apply mask and downsample to 2 and 4 mm
            vsm2std_1mm = [ rd, 'topup_vsm2standard_1mm.nii.gz' ];
            vsm2std_2mm = [ rd, 'topup_vsm2standard_2mm.nii.gz' ];
            cmd = sprintf('applywarp -r %s -i %s -o %s -w %s --interp=nn', mni1mm, vsm, vsm2std_1mm, warp); system(cmd); clear cmd;
            cmd = sprintf('fslmaths %s -mas %s %s', vsm2std_1mm, mni1mm_brain, vsm2std_1mm); system(cmd); clear cmd;
            cmd = sprintf('flirt -in %s -ref %s -applyisoxfm 2 -out %s -interp nearestneighbour', vsm2std_1mm, vsm2std_1mm, vsm2std_2mm); system(cmd); clear cmd;
            cmd = sprintf('flirt -in %s -ref %s -applyisoxfm 4 -out %s -interp nearestneighbour', vsm2std_1mm, vsm2std_1mm, vsm2std); system(cmd); clear cmd;
            
        end
        
        % get mask from gfm (problems with masks from topup...)
        mk_gfm = [ rd, 'mask_gfm.nii.gz' ];
        
        if ~exist(mk_gfm) || repeat(4)
            
            mk_aux = [ ad, RUNS{r}, '/gfm/prestats_gfm.feat/mask.nii.gz' ];
            copyfile(mk_aux, mk_gfm);
            
            % remove last slice to match TOPUP images
            cmd = sprintf('fslroi %s %s 0 -1 0 -1 1 50', mk_gfm, mk_gfm); system(cmd); clear cmd;
            
        end
        
        vsm  = load_untouch_nii(vsm);  vsm  = vsm.img; % voxel shift map
        fmap = load_untouch_nii(fmap); fmap = fmap.img; % fieldmap
        mask = load_untouch_nii(mk_gfm); mask = mask.img; % brain mask
        
        vsm = vsm .* mask; fmap = fmap .* mask; % apply mask
        
        % extract vsm values
        vsmPos = vsm(vsm >= 0); vsmNeg = vsm(vsm <= 0);
        max_shift(r) = max(nonzeros(vsm)); min_shift(r) = min(nonzeros(vsm));
        avgAbs_shift(r) = mean(nonzeros(abs(vsm))); avgPos_shift(r) = mean(nonzeros(vsmPos)); avgNeg_shift(r) = mean(nonzeros(vsmNeg));
        
        % extract fmap values
        fmapPos = fmap(fmap >= 0); fmapNeg = fmap(fmap <= 0);
        max_b0(r) = max(nonzeros(fmap)); min_b0(r) = min(nonzeros(fmap));
        avgAbs_b0(r) = mean(nonzeros(abs(fmap))); avgPos_b0(r) = mean(nonzeros(fmapPos)); avgNeg_b0(r) = mean(nonzeros(fmapNeg));
    end
end