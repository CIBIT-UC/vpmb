function [ err, errc, nmse, nmsec, xc, xcc, errPA, errAP, nmsePA, nmseAP, xcPA, xcAP ] = ...
    compare_AP_PA_BM_aux(p, sub, s, RUNS, geoCorr)

nR = length(RUNS);

% within methods
err  = nan(nR, length(geoCorr)); errc  = nan(nR, length(geoCorr)); % MSE
nmse = nan(nR, length(geoCorr)); nmsec = nan(nR, length(geoCorr)); % normalized MSE
xc   = nan(nR, length(geoCorr)); xcc   = nan(nR, length(geoCorr)); % cross-correlation

% across methods
errPA  = nan(1, nR); errAP  = nan(1, nR); % MSE
nmsePA = nan(1, nR); nmseAP = nan(1, nR); % normalized MSE
xcPA   = nan(1, nR); xcAP   = nan(1, nR); % cross-correlation

sd = [ p, sub(s).name, '/' ]; % subject dir
ad = [ sd, 'MRI/Analysis/' ]; % analysis dir

for r = 1:nR
    
    rd_top = [ ad, RUNS{r}, '/', geoCorr{1}, '/' ];
    rd_gfm = [ ad, RUNS{r}, '/', geoCorr{2}, '/' ];
    
    % fmri file
    fmri_top = [ rd_top, RUNS{r}, '_mcf_st_', geoCorr{1}, '_bet_pnm.nii.gz' ];
    fmri_gfm = [ rd_gfm, RUNS{r}, '_mcf_st_', geoCorr{2}, '_bet_pnm.nii.gz' ];
    
    if exist(fmri_top) && exist(fmri_gfm)
        
        % get images
        
        % TOPUP
        [ inPAnii_top, inPA_top, inAPnii_top, inAP_top, outPAnii_top, ...
            outPA_top, outAPnii_top, outAP_top ] = getImages_top(rd_top);
        
        % GFM
        [ inPAnii_gfm, inPA_gfm, inAPnii_gfm, inAP_gfm, outPAnii_gfm, ...
            outPA_gfm, outAPnii_gfm, outAP_gfm ] = getImages_gfm(rd_gfm);
        
        % compute map differences, map errors and x-correlations - within methods
        
        % TOPUP
        [ err(r, 1), errc(r, 1), nmse(r, 1), nmsec(r, 1), xc(r, 1), xcc(r, 1) ] = compute_metrics...
            (rd_top, inPAnii_top, inPA_top, inAPnii_top, inAP_top, outPAnii_top, outPA_top, outAPnii_top, outAP_top);
        
        % GFM
        [ err(r, 2), errc(r, 2), nmse(r, 2), nmsec(r, 2), xc(r, 2), xcc(r, 2) ] = compute_metrics...
            (rd_gfm, inPAnii_gfm, inPA_gfm, inAPnii_gfm, inAP_gfm, outPAnii_gfm, outPA_gfm, outAPnii_gfm, outAP_gfm);
        
        % compute map differences, map errors and x-correlations - across methods (after correction)
        
        [ errPA(r), errAP(r), nmsePA(r), nmseAP(r), xcPA(r), xcAP(r) ] = compare_methods...
            (rd_gfm, outPAnii_top, outPA_top, outAPnii_top, outAP_top, outPAnii_gfm, outPA_gfm, outAPnii_gfm, outAP_gfm);
        
    end
end

function [ inPAnii, inPA, inAPnii, inAP, outPAnii, outPA, outAPnii, outAP ] = getImages_top(rd)

% distorted images (PA, AP)
in = [ rd, 'topup_input.nii.gz' ];
inPAnii = [ rd, 'PA_distorted.nii.gz' ]; inAPnii = [ rd, 'AP_distorted.nii.gz' ];
cmd = sprintf('fslroi %s %s 0 1', in, inPAnii); system(cmd); clear cmd;
cmd = sprintf('fslroi %s %s 1 1', in, inAPnii); system(cmd); clear cmd;

in_img = load_untouch_nii(in); in_img = in_img.img;
inPA = double(squeeze(in_img(:, :, :, 1))); inAP = double(squeeze(in_img(:, :, :, 2)));

% corrected images
out = [ rd, 'topup_images.nii.gz' ];
outPAnii = [ rd, 'PA_corrected.nii.gz' ]; outAPnii = [ rd, 'AP_corrected.nii.gz' ];
cmd = sprintf('fslroi %s %s 0 1', out, outPAnii); system(cmd); clear cmd;
cmd = sprintf('fslroi %s %s 1 1', out, outAPnii); system(cmd); clear cmd;

out_img = load_untouch_nii(out); out_img = out_img.img;
outPA = double(squeeze(out_img(:, :, :, 1))); outAP = double(squeeze(out_img(:, :, :, 2)));
clear out_img;

function [ inPAnii, inPA, inAPnii, inAP, outPAnii, outPA, outAPnii, outAP ] = getImages_gfm(rd)

% distorted images
PAaux = [ rd, 'prestats_gfm_pa.feat/example_func_distorted.nii.gz' ];
inPAnii = [ rd, 'prestats_gfm_pa.feat/example_func_distorted_50slices.nii.gz' ];
if ~exist(inPAnii) % remove first slice - TOPUP required even number of slices (50)
    cmd = sprintf('fslroi %s %s 0 -1 0 -1 1 50', PAaux, inPAnii); system(cmd); clear cmd;
end
inPA = load_untouch_nii(inPAnii); inPA = double(inPA.img);

APaux = [ rd, 'prestats_gfm.feat/example_func_distorted.nii.gz' ];
inAPnii = [ rd, 'prestats_gfm.feat/example_func_distorted_50slices.nii.gz' ];
if ~exist(inAPnii) % remove first slice - TOPUP required even number of slices (50)
    cmd = sprintf('fslroi %s %s 0 -1 0 -1 1 50', APaux, inAPnii); system(cmd); clear cmd;
end
inAP = load_untouch_nii(inAPnii); inAP = double(inAP.img);

% corrected images
PAaux = [ rd, 'prestats_gfm_pa.feat/example_func.nii.gz' ];
outPAnii = [ rd, 'prestats_gfm_pa.feat/example_func_50slices.nii.gz' ];
if ~exist(outPAnii) % remove first slice - TOPUP required even number of slices (50)
    cmd = sprintf('fslroi %s %s 0 -1 0 -1 1 50', PAaux, outPAnii); system(cmd); clear cmd;
end
outPA = load_untouch_nii(outPAnii); outPA = double(outPA.img);

APaux = [ rd, 'prestats_gfm.feat/example_func.nii.gz' ];
outAPnii = [ rd, 'prestats_gfm.feat/example_func_50slices.nii.gz' ];
if ~exist(outAPnii) % remove first slice - TOPUP required even number of slices (50)
    cmd = sprintf('fslroi %s %s 0 -1 0 -1 1 50', APaux, outAPnii); system(cmd); clear cmd;
end
outAP = load_untouch_nii(outAPnii); outAP = double(outAP.img);

function [ err, errc, nmse, nmsec, xc, xcc ] = compute_metrics...
    (rd, inPAnii, inPA, inAPnii, inAP, outPAnii, outPA, outAPnii, outAP)

% brain mask
mk = [ rd, 'mask.nii.gz' ]; mask = load_untouch_nii(mk); mask = double(mask.img);

% apply brain mask
inPAmk  = inPA .* mask;  inAPmk  = inAP .* mask;
outPAmk = outPA .* mask; outAPmk = outAP .* mask;

% difference maps
inDiff = [ rd, 'diffAPPA_distorted.nii.gz' ];
cmd = sprintf('fslmaths %s -sub %s %s', inAPnii, inPAnii, inDiff); system(cmd); clear cmd;

outDiff = [ rd, 'diffAPPA_corrected.nii.gz' ];
cmd = sprintf('fslmaths %s -sub %s %s', outAPnii, outPAnii, outDiff); system(cmd); clear cmd;

% register difference maps to MNI 1mm
mni = '/SCRATCH/software/fsl/data/standard/MNI152_T1_1mm.nii.gz';
mni_brain = '/SCRATCH/software/fsl/data/standard/MNI152_T1_1mm_brain.nii.gz';
warp = [ rd, 'example_func2standard_warp.nii.gz' ];

inDiff2std = [ rd, 'diffAPPA_distorted2std.nii.gz' ];
cmd = sprintf('applywarp -r %s -i %s -o %s -w %s --interp=nn', mni, inDiff, inDiff2std, warp); system(cmd); clear cmd;
cmd = sprintf('fslmaths %s -mas %s %s', inDiff2std, mni_brain, inDiff2std); system(cmd); clear cmd;

outDiff2std = [ rd, 'diffAPPA_corrected2std.nii.gz' ];
cmd = sprintf('applywarp -r %s -i %s -o %s -w %s --interp=nn', mni, outDiff, outDiff2std, warp); system(cmd); clear cmd;
cmd = sprintf('fslmaths %s -mas %s %s', outDiff2std, mni_brain, outDiff2std); system(cmd); clear cmd;

% difference maps error
err  = norm(inAPmk(:) - inPAmk(:));   nmse  = err ./ norm(inAPmk(:));   % distorted
errc = norm(outAPmk(:) - outPAmk(:)); nmsec = errc ./ norm(outAPmk(:)); % corrected

% cross-correlation between maps
cmd = sprintf('fslcc -m %s %s %s', mk, inPAnii, inAPnii); [ ~, xcaux ] = system(cmd); xc = str2double(xcaux(end-4:end-1));
cmd = sprintf('fslcc -m %s %s %s', mk, outPAnii, outAPnii); [ ~, xccaux ] = system(cmd); xcc = str2double(xccaux(end-4:end-1));

function [ errPA, errAP, nmsePA, nmseAP, xcPA, xcAP ] = compare_methods...
    (rdG, PAniiT, PAT, APniiT, APT, PAniiG, PAG, APniiG, APG)

% brain mask
mk = [ rdG, 'mask.nii.gz' ]; mask = load_untouch_nii(mk); mask = double(mask.img);

% apply brain mask
PAGmk = PAG .* mask; APGmk = APG .* mask;
PATmk = PAT .* mask; APTmk = APT .* mask;

% difference maps @ GFM folder
PADiff = [ rdG, 'diffPA_methods.nii.gz' ];
cmd = sprintf('fslmaths %s -sub %s %s', PAniiG, PAniiT, PADiff); system(cmd); clear cmd;

APDiff = [ rdG, 'diffAP_methods.nii.gz' ];
cmd = sprintf('fslmaths %s -sub %s %s', APniiG, APniiT, APDiff); system(cmd); clear cmd;

% register difference maps to MNI 1mm @ GFM folder
mni = '/SCRATCH/software/fsl/data/standard/MNI152_T1_1mm.nii.gz';
mni_brain = '/SCRATCH/software/fsl/data/standard/MNI152_T1_1mm_brain.nii.gz';
warp = [ rdG, 'example_func2standard_warp.nii.gz' ];

PADiff2std = [ rdG, 'diffPA_methods2std.nii.gz' ];
cmd = sprintf('applywarp -r %s -i %s -o %s -w %s --interp=nn', mni, PADiff, PADiff2std, warp); system(cmd); clear cmd;
cmd = sprintf('fslmaths %s -mas %s %s', PADiff2std, mni_brain, PADiff2std); system(cmd); clear cmd;

APDiff2std = [ rdG, 'diffAP_methods2std.nii.gz' ];
cmd = sprintf('applywarp -r %s -i %s -o %s -w %s --interp=nn', mni, APDiff, APDiff2std, warp); system(cmd); clear cmd;
cmd = sprintf('fslmaths %s -mas %s %s', APDiff2std, mni_brain, APDiff2std); system(cmd); clear cmd;

% difference maps error
errPA = norm(PAGmk(:) - PATmk(:)); nmsePA = errPA ./ norm(PAGmk(:)); % PA
errAP = norm(APGmk(:) - APTmk(:)); nmseAP = errAP ./ norm(APGmk(:)); % AP

% cross-correlation between maps
cmd = sprintf('fslcc -m %s %s %s', mk, PAniiG, PAniiT); [ ~, xcauxPA ] = system(cmd); xcPA = str2double(xcauxPA(end-4:end-1));
cmd = sprintf('fslcc -m %s %s %s', mk, APniiG, APniiT); [ ~, xcauxAP ] = system(cmd); xcAP = str2double(xcauxAP(end-4:end-1));