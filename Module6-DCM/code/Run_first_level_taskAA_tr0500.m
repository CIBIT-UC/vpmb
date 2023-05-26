clear,clc

%% Settings

% MRI scanner settings
TR = 0.5;   % Repetition time (secs)
TE = 0.0302;  % Echo time (secs)

% Experiment settings
subjectList = {'01';'02';'03';'05';'06';'07';'08';'10';'11';'12';'15';'16';'21';'22';'23'};
nsubjects   = 15;
nregions    = 3; 
nconditions = 3;

taskName = 'task-AA_tr-0500';

% Index of each condition in the DCM
MOTION=1; COHERENT=2; INCOHERENT=3;

% Index of each region in the DCM
V3a=1; hMT=2; SPL=3;

%% Specify DCMs (one per subject)

% A-matrix (on / off)
a = ones(nregions,nregions);
a(V3a,SPL) = 0;
a(SPL,V3a) = 0;

% B-matrix
b(:,:,MOTION)     = zeros(nregions); % Task
b(:,:,COHERENT) = eye(nregions);   % Coherent
b(:,:,INCOHERENT)    = eye(nregions);   % Incoherent

% C-matrix
c = zeros(nregions,nconditions);
c(:,MOTION) = 1;

% D-matrix (disabled)
d = zeros(nregions,nregions,0);

%% Specify

start_dir = pwd;
for ss = 1:nsubjects
    
    name = sprintf('sub-%s',subjectList{ss});
    
    % Load SPM
    glm_dir = fullfile('..','GLM',name);
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
    
    % Specify. Corresponds to the series of questions in the GUI.
    s = struct();
    s.name       = 'full';
    s.u          = include;                 % Conditions
    s.delays     = repmat(TR,1,nregions);   % Slice timing for each region
    s.TE         = TE;
    s.nonlinear  = false;
    s.two_state  = false;
    s.stochastic = false;
    s.centre     = true;
    s.induced    = 0;
    s.a          = a;
    s.b          = b;
    s.c          = c;
    s.d          = d;
    DCM = spm_dcm_specify(SPM,xY,s);
    
    % Return to script directory
    cd(start_dir);
end

%% Collate into a GCM file and estimate

% Turn on/off parallel processing
use_parfor = true;
maxNumCompThreads(36);
    
% Find all DCM files
dcms = '';
for ss = 1:nsubjects
    dcms(ss,:) = spm_select('FPListRec',['../GLM/sub-' subjectList{ss} '/' taskName],'DCM_full.mat');
end

% Prepare output directory
out_dir = fullfile('../analyses',taskName);
if ~exist(out_dir,'file')
    mkdir(out_dir);
end

% Check if it exists
if exist(fullfile(out_dir,'GCM_full.mat'),'file')
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
    save(fullfile('../analyses',taskName,'GCM_full.mat'),'GCM');
end
%% Specify 28 alternative models structures
%  These will be templates for the group analysis

% Define B-matrix for each family (factor: task)
% -------------------------------------------------------------------------
% Both
b_task_fam = {};
b_task_fam{1}(:,:,1) = ones(3); % Coherent
b_task_fam{1}(:,:,2) = ones(3); % Incoherent

% Words
b_task_fam{2}(:,:,1) = zeros(3); % Coherent
b_task_fam{2}(:,:,2) = ones(3);  % Incoherent

% Objects
b_task_fam{3}(:,:,1) = ones(3);  % Coherent
b_task_fam{3}(:,:,2) = zeros(3); % Incoherent

task_fam_names = {'Both','Incoherent','Coherent'};

% Define B-matrix for each family (factor: visual-visioparietal)
% -------------------------------------------------------------------------
% All
b_dv_fam{1} = eye(3);

% Visual
b_dv_fam{2} = [1 0 0
               0 1 0
               0 0 0];
% Visio-parietal   
b_dv_fam{3} = [0 0 0
               0 1 0
               0 0 1];
           
% hMT only   
b_dv_fam{3} = [0 0 0
               0 1 0
               0 0 0];

b_dv_fam_names = {'All','Visual','Visio-parietal','hMT'};
           
% % Define B-matrix for each family (factor: left-right)
% % -------------------------------------------------------------------------
% % Both
% b_lr_fam{1} = eye(4);
% 
% % Left
% b_lr_fam{2} = [1 0 0 0;
%                0 1 0 0;
%                0 0 0 0;
%                0 0 0 0];
% 
% % Right  
% b_lr_fam{3} = [0 0 0 0;
%                0 0 0 0;
%                0 0 1 0;
%                0 0 0 1];  
% 
% b_lr_fam_names = {'Both','Left','Right'};
           
% Make a DCM for each mixture of these factors
% -------------------------------------------------------------------------

% Load and unpack an example DCM
GCM_full = load(fullfile('../analyses',taskName,'GCM_full.mat'));
GCM_full = spm_dcm_load(GCM_full.GCM);
DCM_template = GCM_full{1,1};
a = DCM_template.a;
c = DCM_template.c;
d = DCM_template.d;
options = DCM_template.options;

% Output cell array for new models
GCM_templates = {};

m = 1;
for t = 1:length(b_task_fam)
    for dv = 1:length(b_dv_fam)

            % Prepare B-matrix
            b = zeros(3,3,3);
            b(:,:,2:3) = b_dv_fam{dv} & b_task_fam{t};

            % Prepare model name
            name = sprintf('Task: %s, Dorsoventral: %s',...
                task_fam_names{t}, b_dv_fam_names{dv});

            % Build minimal DCM
            DCM = struct();
            DCM.a       = a;
            DCM.b       = b;
            DCM.c       = c;
            DCM.d       = d;
            DCM.options = options;
            DCM.name    = name;                    
            GCM_templates{1,m} = DCM;

            % Record the assignment of this model to each family
            task_family(m) = t;
            b_dv_family(m) = dv;
            m = m + 1;

    end
end

% Add a null model with no modulation
% -------------------------------------------------------------------------
b = zeros(3);
c = [1 0 0;
     1 0 0;
     1 0 0];
name = 'Task: None';

DCM.b(:,:,2) = b;
DCM.b(:,:,3) = b;
DCM.c        = c;
DCM.name     = name;

GCM_templates{1,m} = DCM;

% Record the assignment of this model to each family
b_dv_family(m) = length(b_dv_fam)+1;
task_family(m) = length(b_task_fam)+1;

m = m + 1;    

% Save
GCM = GCM_templates;
save(fullfile('../analyses',taskName,'GCM_templates.mat'),'GCM',...
    'task_family','b_dv_family');

%% Run diagnostics
load(fullfile('../analyses',taskName,'GCM_full.mat'));
spm_dcm_fmri_check(GCM);