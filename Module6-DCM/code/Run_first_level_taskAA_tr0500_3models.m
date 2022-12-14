clear,clc

%% Settings

% MRI scanner settings
TR = 1;   % Repetition time (secs)
taskName = 'task-AA_tr-1000';
TE = 0.0302;  % Echo time (secs)

% Experiment settings
subjectList = {'01';'02';'03';'05';'06';'07';'08';'10';'11';'12';'15';'16';'21';'22';'23'};
nsubjects   = 15;
nregions    = 3; 
nconditions = 3;

% Index of each condition in the DCM
MOTION=1; COHERENT=2; INCOHERENT=3;

% Index of each region in the DCM
V3a=1; hMT=2; SPL=3;

%% Specify DCMs

% A-matrix (on / off)
a = ones(nregions,nregions);
a(V3a,SPL) = 0;
a(SPL,V3a) = 0;

% C-matrix
c = zeros(nregions,nconditions);
c(:,MOTION) = 1;

% D-matrix (disabled)
d = zeros(nregions,nregions,0);

%%
% B-matrix
b1(:,:,MOTION)     = zeros(nregions); % Task
b1(:,:,COHERENT) = [1 0 0; 0 0 0 ; 0 0 0];   % Pictures
b1(:,:,INCOHERENT)    = [1 0 0; 0 0 0 ; 0 0 0];   % Words

%% Specify DCMs REDUCED (one per subject)

% B-matrix
b2(:,:,MOTION)     = zeros(nregions); % Task
b2(:,:,COHERENT) = [0 0 0; 0 1 0 ; 0 0 0];   % Pictures
b2(:,:,INCOHERENT)    = [0 0 0; 0 1 0 ; 0 0 0];   % Words

%% Specify DCMs REDUCED (one per subject)

% B-matrix
b3(:,:,MOTION)     = zeros(nregions); % Task
b3(:,:,COHERENT) = [0 0 0; 0 0 0 ; 0 0 1];   % Pictures
b3(:,:,INCOHERENT)    = [0 0 0; 0 0 0 ; 0 0 1];   % Words

%% Specify

start_dir = pwd;
for ss = 1:nsubjects
    
    name = sprintf('sub-%s',subjectList{ss});
    
    % Load SPM
    glm_dir = fullfile('..','GLM_3models',name);
    SPM     = load(fullfile(glm_dir,taskName,'SPM.mat'));
    SPM     = SPM.SPM;
    
    % Load ROIs
    f = {fullfile(glm_dir,taskName,'VOI_V3a_1.mat');
         fullfile(glm_dir,taskName,'VOI_hMT_1.mat');
         fullfile(glm_dir,taskName,'VOI_SPL_1.mat')};    
    for r = 1:length(f)
        XY = load(f{r});
        xY(r) = XY.xY;
    end
    
    % Move to output directory
    cd(fullfile(glm_dir,taskName));
    
    % Select whether to include each condition from the design matrix
    % (Motion, Coherent, Incoherent)
    include = [1 1 1]';    
    
    % v3a
    
    % Specify. Corresponds to the series of questions in the GUI.
    s = struct();
    s.name       = 'v3a';
    s.u          = include;                 % Conditions
    s.delays     = repmat(TR,1,nregions);   % Slice timing for each region
    s.TE         = TE;
    s.nonlinear  = false;
    s.two_state  = true;
    s.stochastic = false;
    s.centre     = true;
    s.induced    = 0;
    s.a          = a;
    s.b          = b1;
    s.c          = c;
    s.d          = d;
    DCM = spm_dcm_specify(SPM,xY,s);
    
    % hmt
    
    % Specify. Corresponds to the series of questions in the GUI.
    s.name       = 'hmt';
    s.b          = b2;
    DCM = spm_dcm_specify(SPM,xY,s);
    
    % spl
    
    % Specify. Corresponds to the series of questions in the GUI.
    s.name       = 'spl';
    s.b          = b3;
    DCM = spm_dcm_specify(SPM,xY,s);
    
    % Return to script directory
    cd(start_dir);
end

%% Collate into a GCM file and estimate - FULL

% Turn on/off parallel processing
use_parfor = true;
%maxNumCompThreads(36);
    
% Find all DCM files
dcms = '';
for ss = 1:nsubjects
    dcms(ss,:) = spm_select('FPListRec',['../GLM_3models/sub-' subjectList{ss} '/' taskName],'DCM_v3a.mat');
end

% Prepare output directory
out_dir = fullfile('../analyses_3models',taskName);
if ~exist(out_dir,'file')
    mkdir(out_dir);
end

% Check if it exists
if exist(fullfile(out_dir,'GCM_v3a.mat'),'file')
    opts.Default = 'No';
    opts.Interpreter = 'none';
    f = questdlg('Overwrite existing GCM?','Overwrite?','Yes','No',opts);
    tf = strcmp(f,'Yes');
else
    tf = true;
end

% Collate & estimate
if tf
    % Character array -> cell array
    GCM = cellstr(dcms);
    
    % Filenames -> DCM structures
    GCM = spm_dcm_load(GCM);

    % Estimate DCMs (this won't effect original DCM files)
    GCM = spm_dcm_fit(GCM,use_parfor);
    
    % Save estimated GCM
    save(fullfile('../analyses_3models',taskName,'GCM_v3a.mat'),'GCM');
end

%% Collate into a GCM file and estimate - REDUCED

% Turn on/off parallel processing
use_parfor = true;
%maxNumCompThreads(36);
    
% Find all DCM files
dcms = '';
for ss = 1:nsubjects
    dcms(ss,:) = spm_select('FPListRec',['../GLM_3models/sub-' subjectList{ss} '/' taskName],'DCM_hmt.mat');
end

% Prepare output directory
out_dir = fullfile('../analyses_3models',taskName);
if ~exist(out_dir,'file')
    mkdir(out_dir);
end

% Check if it exists
if exist(fullfile(out_dir,'GCM_hmt.mat'),'file')
    opts.Default = 'No';
    opts.Interpreter = 'none';
    f = questdlg('Overwrite existing GCM?','Overwrite?','Yes','No',opts);
    tf = strcmp(f,'Yes');
else
    tf = true;
end

% Collate & estimate
if tf
    % Character array -> cell array
    GCM = cellstr(dcms);
    
    % Filenames -> DCM structures
    GCM = spm_dcm_load(GCM);

    % Estimate DCMs (this won't effect original DCM files)
    GCM = spm_dcm_fit(GCM,use_parfor);
    
    % Save estimated GCM
    save(fullfile('../analyses_3models',taskName,'GCM_hmt.mat'),'GCM');
end

%% Collate into a GCM file and estimate - REDUCED

% Turn on/off parallel processing
use_parfor = true;
%maxNumCompThreads(36);
    
% Find all DCM files
dcms = '';
for ss = 1:nsubjects
    dcms(ss,:) = spm_select('FPListRec',['../GLM_3models/sub-' subjectList{ss} '/' taskName],'DCM_spl.mat');
end

% Prepare output directory
out_dir = fullfile('../analyses_3models',taskName);
if ~exist(out_dir,'file')
    mkdir(out_dir);
end

% Check if it exists
if exist(fullfile(out_dir,'GCM_spl.mat'),'file')
    opts.Default = 'No';
    opts.Interpreter = 'none';
    f = questdlg('Overwrite existing GCM?','Overwrite?','Yes','No',opts);
    tf = strcmp(f,'Yes');
else
    tf = true;
end

% Collate & estimate
if tf
    % Character array -> cell array
    GCM = cellstr(dcms);
    
    % Filenames -> DCM structures
    GCM = spm_dcm_load(GCM);

    % Estimate DCMs (this won't effect original DCM files)
    GCM = spm_dcm_fit(GCM,use_parfor);
    
    % Save estimated GCM
    save(fullfile('../analyses_3models',taskName,'GCM_spl.mat'),'GCM');
end

%% Run diagnostics
load(fullfile('../analyses_3models',taskName,'GCM_v3a.mat'));
spm_dcm_fmri_check(GCM);

%% Run diagnostics
load(fullfile('../analyses_3models',taskName,'GCM_hmt.mat'));
spm_dcm_fmri_check(GCM);

%% Run diagnostics
load(fullfile('../analyses_3models',taskName,'GCM_spl.mat'));
spm_dcm_fmri_check(GCM);

%% Split GCM files

load(['/home/alexandresayal/GitRepos/vpmb/Module6-DCM/analyses_3models/' taskName '/GCM_v3a.mat']);

for ss=1:nsubjects
   
    DCM = GCM{ss,1};
    
    save(['/home/alexandresayal/GitRepos/vpmb/Module6-DCM/analyses_3models/' taskName '/sub-' subjectList{ss} '_DCM_v3a.mat'], 'DCM')
    
    
end


load(['/home/alexandresayal/GitRepos/vpmb/Module6-DCM/analyses_3models/' taskName '/GCM_hmt.mat']);

for ss=1:nsubjects
   
    DCM = GCM{ss,1};
    
    save(['/home/alexandresayal/GitRepos/vpmb/Module6-DCM/analyses_3models/' taskName '/sub-' subjectList{ss} '_DCM_hmt.mat'], 'DCM')
    
    
end

load(['/home/alexandresayal/GitRepos/vpmb/Module6-DCM/analyses_3models/' taskName '/GCM_spl.mat']);

for ss=1:nsubjects
   
    DCM = GCM{ss,1};
    
    save(['/home/alexandresayal/GitRepos/vpmb/Module6-DCM/analyses_3models/' taskName '/sub-' subjectList{ss} '_DCM_spl.mat'], 'DCM')
    
    
end


%% COMPARE

spm('defaults', 'FMRI');
spm_jobman('initcfg');

clear matlabbatch

matlabbatch{1}.spm.dcm.bms.inference.dir = {['/home/alexandresayal/GitRepos/vpmb/Module6-DCM/analyses_3models/' taskName]};
for ss=1:nsubjects
matlabbatch{1}.spm.dcm.bms.inference.sess_dcm{1}(ss).dcmmat = {
                                                              ['/home/alexandresayal/GitRepos/vpmb/Module6-DCM/analyses_3models/' taskName '/sub-' subjectList{ss} '_DCM_v3a.mat']
                                                              ['/home/alexandresayal/GitRepos/vpmb/Module6-DCM/analyses_3models/' taskName '/sub-' subjectList{ss} '_DCM_hmt.mat']
                                                              ['/home/alexandresayal/GitRepos/vpmb/Module6-DCM/analyses_3models/' taskName '/sub-' subjectList{ss} '_DCM_spl.mat']
                                                              };
end
matlabbatch{1}.spm.dcm.bms.inference.model_sp = {''};
matlabbatch{1}.spm.dcm.bms.inference.load_f = {''};
matlabbatch{1}.spm.dcm.bms.inference.method = 'RFX';
matlabbatch{1}.spm.dcm.bms.inference.family_level.family_file = {''};
matlabbatch{1}.spm.dcm.bms.inference.bma.bma_no = 0;
matlabbatch{1}.spm.dcm.bms.inference.verify_id = 1;

spm_jobman('run', matlabbatch);




