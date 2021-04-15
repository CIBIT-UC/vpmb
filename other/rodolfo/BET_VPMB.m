function BET_VPMB(par, repeat)

p = '/DATAPOOL/VPMB/VPMB-STCIBIT/'; sub = dir([ p, 'VPMBAUS*' ]); nS = length(sub);

if ~par
    for s = 1:nS
        run_BET_VPMB(sub, s, repeat);
    end
else
    try
        parpool('local', 8);
    catch
        poolobj = gcp('nocreate'); delete(poolobj); parpool('local', 8);
    end
    
    parfor s = 1:nS
        run_BET_VPMB(sub, s, repeat);
    end
    
    poolobj = gcp('nocreate'); delete(poolobj);
end

function run_BET_VPMB(sub, s, repeat)

% raw folder
pR = [ sub(s).folder, filesep, sub(s).name, '/RAW/' ];

% analysis folder
pA = [ sub(s).folder, filesep, sub(s).name, '/ANALYSIS/' ];
if ~exist(pA, 'dir'), mkdir(pA); end

% create subfolder in ANALYSIS as in RAW
f = dir([ pR, 'T*' ]); nF = length(f);
for i = 1:nF, if ~exist([ pA, f(i).name ], 'dir'), mkdir([ pA, f(i).name ]); end; end

% bet folder
pB = [ pA, 'T1W/BET/' ]; if ~exist(pB, 'dir'), mkdir(pB); end

% get t1w and t1w brain
t1w = [ pB, sub(s).name, '_T1W.nii.gz' ];
t1w_brain = [ pB, sub(s).name, '_T1W_brain.nii.gz' ];

if ~exist(t1w) % copy t1w to bet folder
    
    aux_t1w = [ pR, 'T1W/', sub(s).name, '_T1W.nii.gz' ];
    copyfile(aux_t1w, t1w);
    
end

if ~exist(t1w_brain) || repeat % run brain extraction with ANTs
    
    % set some variables
    pANTs_OASIS = '/DATAPOOL/home/rabreu/FSL+ANTs+FIX/ANTs-OASIS_Template/';
    eOpt = [ pANTs_OASIS, 'T_template0.nii.gz' ];
    mOpt = [ pANTs_OASIS, 'T_template0_BrainCerebellumProbabilityMask.nii.gz' ];
    fOpt = [ pANTs_OASIS, 'T_template0_BrainCerebellumRegistrationMask.nii.gz' ];
    outbase = [ pB, sub(s).name, '_T1W_' ];
    
    % brain mask
    cmd = sprintf('antsBrainExtraction.sh -d 3 -a %s -e %s -m %s -f %s -o %s', ...
        t1w, eOpt, mOpt, fOpt, outbase);
    system(cmd); clear cmd;
    
    % reorganize output
    t1w_brain_mask = [ outbase, 'brain_mask.nii.gz' ];
    cmd = sprintf('mv %s %s', [ outbase, 'BrainExtractionMask.nii.gz' ], t1w_brain_mask);
    system(cmd); clear cmd;
    
    cmd = sprintf('mv %s %s', [ outbase, 'BrainExtractionBrain.nii.gz' ], t1w_brain);
    system(cmd); clear cmd;
    
end
