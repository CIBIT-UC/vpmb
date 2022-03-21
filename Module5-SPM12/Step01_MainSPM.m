%% -- Step01_MainSPM.m ------------------------------------------------- %%
% ----------------------------------------------------------------------- %
% Script for executing the first step regarding the SPM analysis of fMRI
% data after preprocessing with fmriPrep v21.
%
% Dataset:
% - Multiband (Visual Perception)
%
% Warnings:
% - a number of values/steps are custom for this dataset - full code review
% is strongly advised for different datasets
% - this was designed to run on sim01 - a lot of paths must change if run
% at any other computer
%
% Requirements:
% - Preprocessed data by fmriPrep v21
% - FSL 6 functions in path
% - SPM12 in path
% - Tapas PhysIO in path
%
% Author: Alexandre Sayal
% CIBIT, University of Coimbra
% March 2022
% ----------------------------------------------------------------------- %
% ----------------------------------------------------------------------- %

clear,clc
tic

%% SETTINGS

% Select spaces
spaces = {'MNI152NLin2009cAsym','T1w'};

% Select spatial smooting
ssKernel = 6; % Spatial smooting kernel width (in mm)

% Manually define cut-off for HPF (in seconds)
% In this dataset, the last run is different (localizer) and as such the HP
% filter has a different cut-off
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
bidsFolder     = '/DATAPOOL/VPMB/BIDS-VPMB-NONE';
derivFolder    = fullfile(bidsFolder,'derivatives');
fmriPrepFolder = fullfile(bidsFolder,'derivatives','fmriprep');
codeFolder     = pwd;

%% Extract Subject List from BIDS
aux = dir(fullfile(bidsFolder,'sub-*'));
subjectList = extractfield(aux,'name');
clear aux

%% Extract Task List from BIDS
aux = dir(fullfile(bidsFolder,'sub-01','func','*_task-*_bold.json'));
taskList = extractfield(aux,'name');

taskList = cellfun(@(x) x(8:end-10), taskList, 'un', 0); % remove trailing and leading info (VERY custom)
nTasks = length(taskList);

%% Error matrix - flag matrix for errors during execution
errorMatrix = zeros(length(subjectList),length(taskList));

%% MATLAB Thread management
LASTN = maxNumCompThreads(20);

%% Iteration on the subjects (in parallel)
parfor ss = 1:length(subjectList)
    
    subjectID = subjectList{ss};
    
    fprintf('%s processing started!\n',subjectID)
    
    %% Create spmFolder
    spmFolder = fullfile(derivFolder,'spm12',subjectID);
    
    if ~exist(spmFolder,'dir')
        mkdir(spmFolder); disp('spm folder created.')
    end
    
    %% Start the clock and iteration for cleaning
    startTime = tic;
    
    for tt = 1:nTasks
        
        try
            
            %% Build/Select confounds (Physio, WM, CSF, Motion)
            % build regressors for physiological noise correction (using PhysIO)
            % extract interest regressors from fmriPrep output
            createConfoundMatrix(taskList{tt},bidsFolder,fmriPrepFolder,spmFolder,subjectID)
            
            %% SPM post-processing
            % Spatial Smoothing
            % First-level stats
            executeSPMjob(taskList{tt},spaces,ssKernel,hpfValues(tt),spmFolder,fmriPrepFolder,bidsFolder,subjectID)
            
            % cd because SPM might change dir
            cd(codeFolder)
            
        catch ME
            
            if (strcmp(ME.identifier,'VerifyOutliers:Ratio'))
                errorMatrix(ss,tt) = 1;
            else
                errorMatrix(ss,tt) = 2;
                fprintf('\n\n------\nFatal unspecific error on subject %s run %s!\n------\n\n',subjectID,taskList{tt})
            end
            
        end
        
    end

    %% Stop the clock
    fprintf('%s processing done! Elapsed time = %0.2f min.\n',subjectID,toc(startTime)/60)
    
end

%% Export output
save(['Output_' datestr(now,'yyyymmdd-HHMM') '.mat'])

fprintf('\n\n == Step01_MainSPM completed. ==\n\n')
fprintf(' == Elapsed time: %0.2f min. ==\n\n',toc/60)
