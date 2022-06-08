clear,clc

%% Folders
bidsFolder='/DATAPOOL/VPMB/VPMB-BIDS-NLREG';
workFolder='/DATAPOOL/VPMB/VPMB-BIDS-NLREG-work';

%% Subject List
aux = dir(fullfile(bidsFolder,'sub-*'));
subjectList = extractfield(aux,'name');
clear aux

%% Task List
aux = dir(fullfile(bidsFolder,'sub-01','func','*_task-*.json'));
taskList = extractfield(aux,'name');

taskList = cellfun(@(x) x(8:end-17), taskList, 'un', 0); % remove trailing and leading info

%% Iterate on the subjects

for ss = 1:length(subjectList)
    
    subjectID = subjectList{ss};
    
    fprintf('--> Creating vsm for %s...\n',subjectID);
    
    % define and create VSM directory
    vsmFolder = fullfile(bidsFolder,'derivatives','vsm',subjectID);

    if ~exist(vsmFolder,'dir')
        mkdir(vsmFolder)
    end
    
    % Iterate on the runs
    for rr = 1:length(taskList)
        
        taskName = taskList{rr};
        
        calculateVSM_NLREG(bidsFolder,workFolder,vsmFolder,subjectID,taskName);
        
    end

end

clear taskList

%% Calculate single subject mean/std vsm alltasks and per TR

for ss = 1:length(subjectList)
    
    subjectID = subjectList{ss};
    
    fprintf('--> Calculating vsm stats for %s...\n',subjectID);

    % define VSM directory
    vsmFolder = fullfile(bidsFolder,'derivatives','vsm',subjectID);
    
    %% fetch vsm list for all runs
    aux = dir(fullfile(vsmFolder,'*_space-MNI_warp_brain.nii.gz'));

    vsmList.All = extractfield(aux,'name'); clear aux;

    vsmList.All = cellfun(@(c)fullfile(vsmFolder,c),vsmList.All,'uni',false); % add full path
    
    %% fetch vsm list for each TR (probably not the best method, review)
    aux = dir(fullfile(vsmFolder,'*acq-0500_space-MNI_warp_brain.nii.gz'));
    
    vsmList.TR0500 = extractfield(aux,'name'); clear aux;
    vsmList.TR0500 = cellfun(@(c)fullfile(vsmFolder,c),vsmList.TR0500,'uni',false); % add full path
    
    aux = dir(fullfile(vsmFolder,'*acq-0750_space-MNI_warp_brain.nii.gz'));
    
    vsmList.TR0750 = extractfield(aux,'name'); clear aux;
    vsmList.TR0750 = cellfun(@(c)fullfile(vsmFolder,c),vsmList.TR0750,'uni',false); % add full path
    
    aux = dir(fullfile(vsmFolder,'*acq-1000_space-MNI_warp_brain.nii.gz'));
    
    vsmList.TR1000 = extractfield(aux,'name'); clear aux;
    vsmList.TR1000 = cellfun(@(c)fullfile(vsmFolder,c),vsmList.TR1000,'uni',false); % add full path    
    
    aux = dir(fullfile(vsmFolder,'*acq-2500_space-MNI_warp_brain.nii.gz'));
    
    vsmList.TR2500 = extractfield(aux,'name'); clear aux;
    vsmList.TR2500 = cellfun(@(c)fullfile(vsmFolder,c),vsmList.TR2500,'uni',false); % add full path    

    %% Merge all VSMs in the time dimension
    cmd = sprintf('fslmerge -t %s %s',...
        fullfile(vsmFolder,[subjectID '_task-all_acq-all_space-MNI_warp_brain_merge.nii.gz']),...
        strjoin(vsmList.All,' '));

    system(cmd);

    % Calculate mean and std
    cmd = sprintf('fslmaths %s -Tmean %s',...
        fullfile(vsmFolder,[subjectID '_task-all_acq-all_space-MNI_warp_brain_merge.nii.gz']),...
        fullfile(vsmFolder,[subjectID '_task-all_acq-all_space-MNI_warp_brain_mean.nii.gz']));

    system(cmd);

    cmd = sprintf('fslmaths %s -Tstd %s',...
        fullfile(vsmFolder,[subjectID '_task-all_acq-all_space-MNI_warp_brain_merge.nii.gz']),...
        fullfile(vsmFolder,[subjectID '_task-all_acq-all_space-MNI_warp_brain_std.nii.gz']));

    system(cmd);
    
    %% Merge VSMs per TR
    TRs = {'0500','0750','1000','2500'};
    
    for tt = 1:length(TRs)
        
        cmd = sprintf('fslmerge -t %s %s',...
            fullfile(vsmFolder,[subjectID '_task-all_acq-' TRs{tt} '_space-MNI_warp_brain_merge.nii.gz']),...
            strjoin(vsmList.(['TR' TRs{tt}]),' '));

        system(cmd);
        
        % Calculate mean and std
        cmd = sprintf('fslmaths %s -Tmean %s',...
            fullfile(vsmFolder,[subjectID '_task-all_acq-' TRs{tt} '_space-MNI_warp_brain_merge.nii.gz']),...
            fullfile(vsmFolder,[subjectID '_task-all_acq-' TRs{tt} '_space-MNI_warp_brain_mean.nii.gz']));

        system(cmd);

        cmd = sprintf('fslmaths %s -Tstd %s',...
            fullfile(vsmFolder,[subjectID '_task-all_acq-' TRs{tt} '_space-MNI_warp_brain_merge.nii.gz']),...
            fullfile(vsmFolder,[subjectID '_task-all_acq-' TRs{tt} '_space-MNI_warp_brain_std.nii.gz']));

        system(cmd);   
  
    end

end

clear vsmFolder

%% Calculate group average vsm

aux = dir(fullfile(bidsFolder,'derivatives','vsm','sub-*','sub-*_task-all_acq-all_space-MNI_warp_brain_mean.nii.gz'));

groupVsmList.All = cellfun(@(c1,c2)fullfile(c1,c2),extractfield(aux,'folder'),extractfield(aux,'name'),'uni',false); % add full path

% Create folder for group analyses
groupVsmFolder = fullfile(bidsFolder,'derivatives','vsm','group');
if ~exist(groupVsmFolder,'dir')
    mkdir(groupVsmFolder);
end

% Merge all mean vsms
cmd = sprintf('fslmerge -t %s %s',...
    fullfile(groupVsmFolder,'sub-all_task-all_acq-all_space-MNI_warp_brain_merge.nii.gz'),...
    strjoin(groupVsmList.All,' '));

system(cmd);

% Calculate mean and std
cmd = sprintf('fslmaths %s -Tmean %s',...
    fullfile(groupVsmFolder,'sub-all_task-all_acq-all_space-MNI_warp_brain_merge.nii.gz'),...
    fullfile(groupVsmFolder,'sub-all_task-all_acq-all_space-MNI_warp_brain_mean.nii.gz'));

system(cmd);

cmd = sprintf('fslmaths %s -Tstd %s',...
    fullfile(groupVsmFolder,'sub-all_task-all_acq-all_space-MNI_warp_brain_merge.nii.gz'),...
    fullfile(groupVsmFolder,'sub-all_task-all_acq-all_space-MNI_warp_brain_std.nii.gz'));

system(cmd);   


%% display command line for fsleyes (run in local terminal)
% fsleyes --scene lightbox --worldLoc 6.545809474495087 63.04108480661628 -14.47959859501421 \
%   --displaySpace world --zaxis 2 --sliceSpacing 5.0 --zrange -45.0 60.0 --ncols 7 --nrows 4 --hideCursor \
%   --bgColour 0.0 0.0 0.0 --fgColour 1.0 1.0 1.0 --cursorColour 0.0 1.0 0.0 --showColourBar --colourBarLocation bottom \
%   --colourBarLabelSide top-left --colourBarSize 100.0 --labelSize 20 --performance 3 --movieSync \
%   /run/user/1000/gvfs/sftp:host=192.168.0.68/DATAPOOL/VPMB/VPMB-BIDS-NLREG/derivatives/fmriprep/sub-01/anat/sub-01_run-1_space-MNI152NLin2009cAsym_desc-preproc_T1w.nii.gz \
%   --name "sub-01_run-1_space-MNI152NLin2009cAsym_desc-preproc_T1w" --overlayType volume --alpha 100.0 --brightness 49.30473204128602 --contrast 55.19275298788637 \
%   --cmap greyscale --negativeCmap greyscale --displayRange 0.0 2500.0 --clippingRange 0.0 2633.968806152344 --modulateRange -183.6558074951172 2606.071533203125 \
%   --gamma 0.0 --cmapResolution 256 --interpolation none --numSteps 100 --blendFactor 0.1 --smoothing 0 --resolution 100 --numInnerSteps 10 --clipMode intersection --volume 0 \
%   /run/user/1000/gvfs/sftp:host=192.168.0.68/DATAPOOL/VPMB/VPMB-BIDS-NLREG/derivatives/vsm/group/sub-all_task-all_acq-all_space-MNI_warp_brain_mean.nii.gz \
%   --name "sub-all_task-all_acq-all_space-MNI_warp_brain_mean" --overlayType volume --alpha 80.0 --brightness 54.595916231415806 --contrast 48.97141564370903 \
%   --cmap brain_colours_2winter_iso --negativeCmap greyscale --unlinkLowRanges --displayRange -6.0 6.0 --clippingRange -1.0 1.0 --modulateRange -4.427344466706585 6.421818173772496 \
%   --gamma 0.0 --invertClipping --cmapResolution 256 --interpolation none --numSteps 100 --blendFactor 0.1 --smoothing 0 \
%   --resolution 100 --numInnerSteps 10 --clipMode intersection --volume 0 &

%% Calculate group average per TR

TRs = {'0500','0750','1000','2500'};
    
for tt = 1:length(TRs)

    aux = dir(fullfile(bidsFolder,'derivatives','vsm','sub-*',['sub-*_task-all_acq-' TRs{tt} '_space-MNI_warp_brain_mean.nii.gz']));

    groupVsmList.(['TR' TRs{tt}]) = cellfun(@(c1,c2)fullfile(c1,c2),extractfield(aux,'folder'),extractfield(aux,'name'),'uni',false); % add full path

    % Merge all mean vsms
    cmd = sprintf('fslmerge -t %s %s',...
        fullfile(groupVsmFolder,['sub-all_task-all_acq-' TRs{tt} '_space-MNI_warp_brain_merge.nii.gz']),...
        strjoin(groupVsmList.(['TR' TRs{tt}]),' '));

    system(cmd);

    % Calculate mean and std
    cmd = sprintf('fslmaths %s -Tmean %s',...
        fullfile(groupVsmFolder,['sub-all_task-all_acq-' TRs{tt} '_space-MNI_warp_brain_merge.nii.gz']),...
        fullfile(groupVsmFolder,['sub-all_task-all_acq-' TRs{tt} '_space-MNI_warp_brain_mean.nii.gz']));

    system(cmd);

    cmd = sprintf('fslmaths %s -Tstd %s',...
        fullfile(groupVsmFolder,['sub-all_task-all_acq-' TRs{tt} '_space-MNI_warp_brain_merge.nii.gz']),...
        fullfile(groupVsmFolder,['sub-all_task-all_acq-' TRs{tt} '_space-MNI_warp_brain_std.nii.gz']));

    system(cmd);  

end
