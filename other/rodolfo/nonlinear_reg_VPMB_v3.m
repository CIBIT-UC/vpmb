function nonlinear_reg_VPMB_v3(par, repeat)

p = '/DATAPOOL/VPMB/VPMB-STCIBIT/'; sub = dir([ p, 'VPMBAUS*' ]); nS = length(sub);

if ~par
    for s = 1:nS
        run_nonlinear_reg_VPMB(sub, s, repeat);
    end
else
    try
        parpool('local', 8);
    catch
        poolobj = gcp('nocreate'); delete(poolobj); parpool('local', 8);
    end
    
    parfor s = 1:nS
        run_nonlinear_reg_VPMB(sub, s, repeat);
    end
    
    poolobj = gcp('nocreate'); delete(poolobj);
end

function run_nonlinear_reg_VPMB(sub, s, repeat)

% analysis folder
pA = [ sub(s).folder, filesep, sub(s).name, '/ANALYSIS/' ];

% downsampled t1w folder
pT1 = [ pA, 'T1W/DOWN/' ];

% downsampled images
t1_down      = [ pT1, sub(s).name, '_T1W_down_restore.nii.gz' ];
t1brain_down = [ pT1, sub(s).name, '_T1W_down_restore_brain.nii.gz' ];
t1mask_down  = [ pT1, sub(s).name, '_T1W_down_restore_brain_mask.nii.gz' ];
t1wm_down    = [ pT1, sub(s).name, '_T1W_down_restore_brain_wmseg.nii.gz' ];

% get runs
runs = dir([ pA, 'TASK-*' ]); nR = length(runs);

% path to Convert3D functions
c3dp = '/SCRATCH/software/Convert3D/bin';

% deformations to be tested
% def(1).type = 'moderate'; def(1).weight = '0.1x1x0.1';
def(2).type = 'strict';   def(2).weight = '0x1x0';

for r = 1:nR
    
    fprintf('\nRunning NL REG: Subject %s | Run %s\n\n', sub(s).name, runs(r).name); 
    
    % run folder
    pR = [ pA, runs(r).name, filesep ];
    
    % non-linear reg and work folders
    pNLreg = [ pR, 'FMAP-NLREG/' ]; if ~exist(pNLreg, 'dir'), mkdir(pNLreg); end
    pw = [ pNLreg, 'work/' ];
    
    % get functional images
    func01 = [ pw, 'func01_brain_restore.nii.gz' ]; func01_mask = [ pw, 'func_brain_mask.nii.gz' ];
    
    % compute linear transformation func012t1_down
    func012t1_down = [ pw, 'func012t1_down.nii.gz' ];
    
    if ~exist(func012t1_down) || repeat(1)
        cmd = sprintf('epi_reg --epi=%s --t1=%s --t1brain=%s --wmseg=%s --out=%s', func01, t1_down, t1brain_down, t1wm_down, func012t1_down); system(cmd); clear cmd;
    end
    
    % compute composite transformation (linear + non-linear) with ANTs, controlling for the allowed deformation directions
    % parameters adjusted according to Hutenburg (MSc Thesis)
    invt1brain_down = [ pw, 'invT1W_down-brain.nii.gz' ];
    
    for d = 2%1:length(def)
        
        % func01 transformed to downsampled invT1
        func012invt1_down = [ pw, 'func012invt1_down_lnl_StrictParam_warped_', def(d).type, '.nii.gz' ];
        
        if ~exist(func012invt1_down) || repeat(2)
            
            % ANTs commands (original, moderate and strict wrt parameters - NOT deformations)
            cmd = ANTs_cmd_VPMB(invt1brain_down, func01, pw, def(d));
            
            system(cmd.linear);   % only linear 
            system(cmd.orig);     % original 
            system(cmd.moderate); % moderate
            system(cmd.strict);   % strict
        end
        
%         % composite transformation of MC + NLreg (specific for each volume)
%         preVol = [ pw, 'preVols/' ]; postVol = [ pw, 'postVols/' ];
%         mats = dir([ pw, 'func_stc_mc.mat/MAT_*' ]); nvol = length(mats); % MC transformations (1 per volume)
%         ltransf = [ pw, 'func012invt1_down_moderate_lnl_0GenericAffine.mat' ];
%         nlwarp = [ pw, 'func012invt1_down_moderate_lnl_1Warp.nii.gz' ];
%         
%         for v = 1:nvol
%             
%             pre_func  = [ preVol, sprintf('func_%04d', v-1), '.nii.gz' ]; % "raw" func data (stc+mc)
%             post_func = [ postVol, sprintf('func_%04d', v-1), '.nii.gz' ]; % corected func data (stc+mc+dc)
%             
%             % convert fsl mc mats to ants (itk transformations)
%             mat = [ mats(v).folder, filesep, mats(v).name ];
%             mat2ants = [ mats(v).folder, filesep, sprintf('MAT2ants_%04d', v-1), '.txt' ];
%             
%             cmd = sprintf('%s/c3d_affine_tool %s -oitk %s', c3dp, mat, mat2ants); system(cmd); clear cmd;
%             
%             % apply mask to preVols
%             cmd = sprintf('fslmaths %s -mas %s %s', pre_func, func01_mask, pre_func); system(cmd); clear cmd;
%             
%             % apply composite transformation mc+nl
%             cmd = sprintf('antsApplyTransforms -d 3 -i %s -o %s -r %s -t %s -t %s -t %s -n Linear', ...
%                 pre_func, post_func, invt1brain_down, mat2ants, ltransf, nlwarp);
%             system(cmd); clear cmd;
%             
%         end
%         
%         % concat pos_func volumes
%         func_dc = [ pw, 'func_stc_mc_dc.nii.gz' ];
%         
%         if ~exist(func_dc) || repeat(3)
%             
%             cmd = sprintf('fslmerge -t %s %s', func_dc, [ pw, 'postVols/func_*.nii.gz' ]);
%             system(cmd); clear cmd;
%             
%         end
    end
end

% premat  = [ mats(v).folder, filesep, mats(v).name ];
% mc_warp = [ preVol, sprintf('MatrixAll_%04d', v-1), '.nii.gz' ];
% 
% if ~exist(mc_warp) || repeat(3)
%     
%     compute composite transformation
%     cmd = sprintf('convertwarp --ref=%s --out=%s --premat=%s --warp1=%s --rel --verbose', invt1brain_down, mc_warp, premat, nlwarp);
%     system(cmd), clear cmd;
%     
% end
% 
% pre_func = [ preVol, sprintf('func_%04d', v-1), '.nii.gz' ]; % "raw" func data (stc+mc)
% pos_func = [ posVol, sprintf('func_%04d', v-1), '.nii.gz' ]; % corected func data (stc+mc+dc)
% 
% if ~exist(pos_func) || repeat(4)
%     
%     apply composite transformation
%     cmd = sprintf('applywarp -i %s -o %s -r %s -w %s --interp=sinc', pre_func, pos_func, invt1brain_down, mc_warp);
%     system(cmd); clear cmd;
%     
% end