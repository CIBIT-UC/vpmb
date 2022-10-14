%% -- Step03_CreateSphericalROIs.m ------------------------------------------------- %%
% ----------------------------------------------------------------------- %
%  description
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
% - Preprocessed data by fmriPrep v20
% - FSL 6 functions in path
% - SPM12 in path
%
% Author: Alexandre Sayal
% CIBIT, University of Coimbra
% October 2022
% ----------------------------------------------------------------------- %
% ----------------------------------------------------------------------- %

clear,clc

%% Load Packages on sim01
% SPM12
addpath('/SCRATCH/software/toolboxes/spm12')

addpath('/SCRATCH/software/toolboxes/spm12/toolbox/marsbar')

%% Settings
% Base directory
baseFolder = '/DATAPOOL/VPMB';

sdcMethods = {'NONE', 'EPI', 'SPE', 'GRE', 'NLREG'};
nMethods = length(sdcMethods);

nROIs = 10;
sphereRadius = 8; % in mm

params = struct();
params.radius = sphereRadius;
space = 'MNI152NLin2009cAsym';

%% Load dataset
datasetLocROIs = importROIcsv('Localizer_ROISelection_20221014.csv');

%% Iterate on the methods

for mm = 1:nMethods
    
    sdcMethod = sdcMethods{mm};
    
    bidsFolder      = fullfile(baseFolder,['BIDS-VPMB-' sdcMethod]);
    derivFolder     = fullfile(bidsFolder,'derivatives');
    outputROIFolder = fullfile(derivFolder,'ROI_spherical','group');
    
    if ~exist(outputROIFolder,'dir')
        mkdir(outputROIFolder);
        disp('output folder created.')
    end
    
    % fetch anatomical image
    V = spm_vol(fullfile(derivFolder,'spm12','sub-01',['sub-01_run-1_space-' space '_desc-preproc_T1w.nii']));
    
    for rr = 1:nROIs
        
        params.centre = [datasetLocROIs.([sdcMethod '_X'])(rr)  datasetLocROIs.([sdcMethod '_Y'])(rr)  datasetLocROIs.([sdcMethod '_Z'])(rr)];
        
        outROI = maroi_sphere(params);
        
        save_as_image(outROI, fullfile(outputROIFolder,sprintf('%s_sphere%dmm.nii',erase(datasetLocROIs.ROIname(rr),' '),sphereRadius)), V)
        
    end
    
end

%%
save('Output_Step03_datasetLocROIs.mat','datasetLocROIs')
