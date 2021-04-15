function invert_struct_VPMB(par, repeat)

p = '/DATAPOOL/VPMB/VPMB-STCIBIT/'; sub = dir([ p, 'VPMBAUS*' ]); nS = length(sub);

if ~par
    for s = 1:nS
        run_invert_struct_VPMB(sub, s, repeat);
    end
else
    try
        parpool('local', 8);
    catch
        poolobj = gcp('nocreate'); delete(poolobj); parpool('local', 8);
    end
    
    parfor s = 1:nS
        run_invert_struct_VPMB(sub, s, repeat);
    end
    
    poolobj = gcp('nocreate'); delete(poolobj);
end

function run_invert_struct_VPMB(sub, s, repeat)

% analysis folder
pA = [ sub(s).folder, filesep, sub(s).name, '/ANALYSIS/' ];

% t1w folder
pT1 = [ pA, 'T1W/' ];

% downsampled t1w folder
pdownT1 = [ pT1, 'DOWN/' ]; if ~exist(pdownT1, 'dir'); mkdir(pdownT1); end

% images to downsample to 2.5 mm isotropic
t1        = [ pT1, 'FAST/', sub(s).name, '_T1W_restore.nii.gz' ];
t1brain   = [ pT1, 'FAST/', sub(s).name, '_T1W_brain_restore.nii.gz' ];
t1mask    = [ pT1, 'BET/', sub(s).name, '_T1W_brain_mask.nii.gz' ];
t1wm      = [ pT1, 'FAST/', sub(s).name, '_T1W_brain_wmseg.nii.gz' ];
t1outskin = [ pT1, 'BET/', sub(s).name, '_T1W_outskin_mask.nii.gz' ];

if ~exist(t1outskin) || repeat(1)
    
    % run bet to get outskin mask
    cmd = sprintf('bet %s %s -A', t1, t1mask(1:end-18)); system(cmd); clear cmd;
    
end

% downsampled images
t1_down        = [ pdownT1, sub(s).name, '_T1W_down_restore.nii.gz' ];
t1brain_down   = [ pdownT1, sub(s).name, '_T1W_down_restore_brain.nii.gz' ];
t1mask_down    = [ pdownT1, sub(s).name, '_T1W_down_restore_brain_mask.nii.gz' ];
t1wm_down      = [ pdownT1, sub(s).name, '_T1W_down_restore_brain_wmseg.nii.gz' ];
t1outskin_down = [ pdownT1, sub(s).name, '_T1W_down_restore_outskin_mask.nii.gz' ];

if ~exist(t1_down) || ~exist(t1brain_down) || ~exist(t1mask_down) || ~exist(t1wm_down) || ~exist(t1outskin_down) || repeat(2)
    
    % downsample images
    cmd = sprintf('flirt -in %s -ref %s -applyisoxfm 2.5 -out %s -interp nearestneighbour', t1, t1, t1_down); system(cmd); clear cmd;
    cmd = sprintf('flirt -in %s -ref %s -applyisoxfm 2.5 -out %s -interp nearestneighbour', t1brain, t1brain, t1brain_down); system(cmd); clear cmd;
    cmd = sprintf('flirt -in %s -ref %s -applyisoxfm 2.5 -out %s -interp nearestneighbour', t1mask, t1mask, t1mask_down); system(cmd); clear cmd;
    cmd = sprintf('flirt -in %s -ref %s -applyisoxfm 2.5 -out %s -interp nearestneighbour', t1wm, t1wm, t1wm_down); system(cmd); clear cmd;
    cmd = sprintf('flirt -in %s -ref %s -applyisoxfm 2.5 -out %s -interp nearestneighbour', t1outskin, t1outskin, t1outskin_down); system(cmd); clear cmd;
    
end

% get range of t1w brain
[ ~, outstr1 ] = system(sprintf('fslstats %s -k %s -R', t1_down, t1outskin_down));
outstr1 = split(outstr1); t1wmin_down1 = str2double(outstr1{1}); t1wmax_down1 = str2double(outstr1{2});

[ ~, outstr2 ] = system(sprintf('fslstats %s -k %s -R', t1brain_down, t1mask_down));
outstr2 = split(outstr2); t1wmin_down2 = str2double(outstr2{1}); t1wmax_down2 = str2double(outstr2{2});

% get runs
runs = dir([ pA, 'TASK-*' ]); nR = length(runs);

for r = 1:nR
    
    % run folder
    pR = [ pA, runs(r).name, filesep ];
    
    % non-linear reg folder
    pNLreg = [ pR, 'FMAP-NLREG/' ]; if ~exist(pNLreg, 'dir'), mkdir(pNLreg); end    
    
    % get range of func01 (from FMAP-NONE)
    pw = [ pNLreg, 'work/' ]; if ~exist(pw, 'dir'), mkdir(pw); end   
    func01 = [ pw, 'func01_brain_restore.nii.gz' ]; func01_mask = [ pw, 'func_brain_mask.nii.gz' ];
    
    [ ~, outstr ] = system(sprintf('fslstats %s -k %s -R', func01, func01_mask));
    outstr = split(outstr); func01min = str2double(outstr{1}); func01max = str2double(outstr{2});
    
    % inversion transformation using non-BET structural image
    mul1 = - (func01max - func01min) / (t1wmax_down1 - t1wmin_down1);
    add1 = abs(t1wmax_down1 * mul1) + func01min;
    
    % apply inversion transformation (one downsampled, inverted t1w per run)
    invt1_down1 = [ pw, 'invT1W_down-nobet.nii.gz' ];
    invt1brain_down1 = [ pw, 'invT1W_down-nobet_brain.nii.gz' ];
    
    cmd = sprintf('fslmaths %s -mul %f -add %f %s', t1_down, mul1, add1, invt1_down1); system(cmd); clear cmd;
    cmd = sprintf('fslmaths %s -mas %s %s', invt1_down1, t1outskin_down, invt1_down1); system(cmd); clear cmd;
    cmd = sprintf('fslmaths %s -mas %s %s', invt1_down1, t1mask_down, invt1brain_down1); system(cmd); clear cmd;
    
    % inversion transformation using BET structural image
    mul2 = - (func01max - func01min) / (t1wmax_down2 - t1wmin_down2);
    add2 = abs(t1wmax_down2 * mul2) + func01min;
    
    % apply inversion transformation (one downsampled, inverted t1w per run)
    invt1brain_down2 = [ pw, 'invT1W_down-brain.nii.gz' ];
    
    cmd = sprintf('fslmaths %s -mul %f -add %f %s', t1brain_down, mul2, add2, invt1brain_down2); system(cmd); clear cmd;
    cmd = sprintf('fslmaths %s -mas %s %s', invt1brain_down2, t1mask_down, invt1brain_down2); system(cmd); clear cmd;

end