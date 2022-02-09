% this script performs confound regression, spatial smoothing, high-pass
% filtering and GLMs for all tasks.
%
% Requires:
% - data in BIDS directory
% - FSL 6
% - SPM12

clear,clc

%% SETTINGS

% Base directory
baseDir = '/DATAPOOL/VPMB';

% Distortion correction method (affects folders)
% Options: NLREG
sdcMethod = 'NLREG';

% Select spaces
spaces = {'T1w','MNI152NLin2009cAsym'};

% Select spatial smooting
ssKernel = 6; % Spatial smooting kernel width (in mm)

% Manually define cut-off for HPF
hpfValues = [330*ones(1,8) 32];

%% Load Packages on sim01

% JSON lab
addpath('/SCRATCH/software/toolboxes/jsonlab/')

% SPM12
addpath('/SCRATCH/software/toolboxes/spm12')

% PhysIO
addpath('/SCRATCH/software/toolboxes/spm12/toolbox/PhysIO/')

% NifTI tools
addpath('/SCRATCH/software/toolboxes/nifti-tools')

% Neuroelf
addpath(genpath('/SCRATCH/software/toolboxes/neuroelf-matlab/'))

%% Folders
bidsFolder     = fullfile(baseDir,['VPMB-BIDS-' sdcMethod]);
workFolder     = fullfile(baseDir,['VPMB-BIDS-' sdcMethod '-work']);
derivFolder    = fullfile(bidsFolder,'derivatives');
fmriPrepFolder = fullfile(bidsFolder,'derivatives','fmriprep');
cleanFolder    = fullfile(bidsFolder,'derivatives','cleaning');
codeFolder     = pwd;

%% Extract Subject List from BIDS
aux = dir(fullfile(bidsFolder,'sub-*'));
subjectList = extractfield(aux,'name');
clear aux

%% Extract Task List from BIDS
aux = dir(fullfile(bidsFolder,'sub-01','func','*_task-*_bold.json'));
taskList = extractfield(aux,'name');

taskList = cellfun(@(x) [x(8:end-12) '1'], taskList, 'un', 0); % remove trailing and leading info and add a 1 (as index, without trailing zero)
nTasks = length(taskList);

%% Error matrix - flag matrix for errors during execution
errorMatrix = zeros(length(subjectList),length(taskList));

%% MATLAB Thread management
N = maxNumCompThreads;
maxNumCompThreads(ceil(N/2))

%% Iteration on the subjects (in parallel)
parfor ss = 1:length(subjectList)
    
    subjectID = subjectList{ss};
    
    fprintf('%s processing started!\n',subjectID)
    
    %% Create outputFolder and spmFolder
    outputFolder = fullfile(cleanFolder,subjectID);
    spmFolder = fullfile(outputFolder,'spm');
    
    if ~exist(spmFolder,'dir')
        mkdir(spmFolder); disp('output and spm folders created.')
    end
    
    %% Start the clock and iteration for cleaning
    startTime = tic;
    
    for tt = 1:nTasks
        
        try
            taskName = taskList{tt};
            hpfValue = hpfValues(tt);
            
            %% Build/Select confounds (Physio, WM, CSF, Motion)
            % build regressors for physiological noise correction (using PhysIO)
            % extract interest regressors from fmriPrep output
            createConfoundMatrix_fmriPrep(taskName,bidsFolder,fmriPrepFolder,outputFolder,subjectID)
            
            %% Run physiological noise correction (using regress from MATLAB)
            regressConfounds_fmriPrep(taskName,spaces,fmriPrepFolder,outputFolder,subjectID)
            
            %% SPM post-processing
            % Spatial Smoothing
            % First-level stats
            executeSPMjob(taskName,spaces,ssKernel,hpfValue,spmFolder,outputFolder,bidsFolder,subjectID)
            
            % cd because SPM might change dir
            cd(codeFolder)
            
        catch ME
            
            if (strcmp(ME.identifier,'VerifyOutliers:Ratio'))
                errorMatrix(ss,tt) = 1;
            else
                errorMatrix(ss,tt) = 2;
                fprintf('\n\n------\nFatal unspecific error on subject %s run %s!\n------\n\n',subjectID,taskName)
            end
            
        end
        
    end
    
    %% Stop the clock
    fprintf('%s processing done! Elapsed time = %0.2f min.\n',subjectID,toc(startTime)/60)
    
end

%% Export output
save(['Output_' datestr(now,'yyyymmdd-HHMM') '.mat'])
