% ----------------------------------------------------------------------- %
% ----------------------------------------------------------------------- %
% MODULE 1 - Data organization
% Script Name: M1_RAWtoSTCIBIT.m
%
% Convert the dataset to the STCIBIT format:
% - Fetch the DICOM data files and convert them to nifti
% - Fetch keypress, eyetracker, and physio data and copy them
% - Reorganize!
%
% Author: Alexandre Sayal, PhD student
% Coimbra Institute for Biomedical Imaging and Translational Research
% Email address: alexandresayal@gmail.com
% December 2020; Last revision: 30-Apr-2021
% ----------------------------------------------------------------------- %

%% Start clean
clear,clc,close all

%% Requirements

% 1) jsonlab (https://github.com/fangq/jsonlab)
addpath('/home/alexandresayal/Documents/MATLAB/jsonlab')

% 2) dcm2niix (https://github.com/rordenlab/dcm2niix)
% Make sure dcm2niix version 1.0.20201102 or greater is installed 
system('dcm2niix -v');

%% Settings
subID = 'VPMBAUS23';

basePath = '/media/alexandresayal/DATA4TB';

%% Subject folders to export data
niiFolder = fullfile(basePath,'VPMB-NII',subID);
stcibitFolder = fullfile(basePath,'VPMB-STCIBIT',subID);

%% Subject sub-folders of RAW folder
dicomFolder = fullfile(basePath,'VPMB-RAW',subID,'DICOM');
physioFolder = fullfile(basePath,'VPMB-RAW',subID,'PHYSIO');
keypressFolder = fullfile(basePath,'VPMB-RAW',subID,'KEYPRESS');
eyetrackerFolder = fullfile(basePath,'VPMB-RAW',subID,'EYETRACKER');
protocolFolder = fullfile(basePath,'VPMB-RAW',subID,'PROTOCOL');

%% Check subID
if ~exist(dicomFolder,'dir')
   error('[%s] subID=%s DICOM folder does not exist.\n',datestr(now),subID) 
end

%% Import naming match
% This is a custom file with the match between the sequence name and the desired name
% in the STCIBIT format.

T = importMatchFile(fullfile(basePath,'VPMB-RAW','aux-files','MatchMatrix.csv'));

%% Conversion to nifti

% % create nii folder if it does not exist
% if ~exist(niiFolder,'dir')
%     mkdir(niiFolder)
%     fprintf('[%s] %s folder created.\n',datestr(now),niiFolder)
% end
% 
% % check if folder is empty
% if length(dir(niiFolder)) > 2
%    error('[%s] Please remove all files in %s.\n',datestr(now),niiFolder)
% end
% 
% fprintf('[%s] Start conversion to nifti with dcm2niix...\n',datestr(now))
% 
% % create dcm2niix command
% bCmd = sprintf('dcm2niix -f "%%d" -p y -z y -o "%s" "%s"',niiFolder,dicomFolder);
% 
% fprintf('[%s] dcm2niix command:\n\n > %s \n\n',datestr(now),bCmd)
% 
% % execute dcm2niix
% system(bCmd);
% 
% fprintf('[%s] Nifti conversion complete.\n',datestr(now))

%% Read NIFTI folder and copy files

fprintf('[%s] Copying nii files to stcibit...\n',datestr(now))

Ndir = dir(niiFolder); % Fetch files

Ndir(cell2mat(extractfield(Ndir,'isdir'))) = []; % Remove '.' and '..'

for ii = 1:length(Ndir) % iterate
    
    % retrieve name and extension
    aux = strsplit(Ndir(ii).name,'.');
    
    if strcmp(aux{end},'gz') % needed workaround due to inconsistent number of dots in the extension of some files (.json vs .nii.gz)
        name = strjoin(aux(1:end-2),'.');
        ext = 'nii.gz';        
    else
        name = strjoin(aux(1:end-1),'.');
        ext = aux{end};
    end
    
    % find run name in match file
    idx = find(strcmp(T(:,1),name));
    
    % Copy and rename
    if isempty(idx) % will not be copied (make sure it is discarded on purpose!)
        
        warning('[%s] %s does not exist in match file. Make sure it is discarded on purpose!\n',datestr(now),name)
        
    else
        
        % create new name
        newName = [subID '_' T{idx,2} '.' ext];
        
        % copy to intendedFor folders
        folders = strsplit(T{idx,3},'.');
        
        for jj = 1:length(folders)
            
            % create folder if does not exist
            if ~exist(fullfile(stcibitFolder,'RAW',folders{jj}),'dir')
                mkdir(fullfile(stcibitFolder,'RAW',folders{jj},'LINKED')); % creating the longest path creates all the previous levels
            end
            
            copyfile(fullfile(niiFolder,Ndir(ii).name),...
                fullfile(stcibitFolder,'RAW',folders{jj},newName));
            
        end
        
    end % end if
    
end % end nii file iteration

fprintf('[%s] Nifti files copy completed.\n',datestr(now))

%% Retrieve run order based on .json info

% Search stcibit folder for functional runs
D = dir(fullfile(stcibitFolder,'RAW','TASK-*'));

% Initialize cell array
RunOrder = cell(length(D),2);

% Iterate on the functional runs
for ii = 1:length(D)
    
    funcFile = fullfile(stcibitFolder,'RAW',D(ii).name,[subID '_' D(ii).name '.json']);
    
    auxJ = loadjson(funcFile);
    
    RunOrder{ii,1} = D(ii).name;
    RunOrder{ii,2} = auxJ.AcquisitionTime; % functional runs were acquired all on the same session/day. quite dangerous nevertheless :P
    
end

% Sort based on acquisition time (column 2)
RunOrder = sortrows(RunOrder,2);

% Save run order as txt
tt = table(RunOrder(:,1),RunOrder(:,2),'VariableNames',{'RunName','Time'});
write(tt,fullfile(stcibitFolder,'RAW','runOrder.txt'))

fprintf('[%s] Run order retrieved.\n',datestr(now))

%% Copy Physio files

fprintf('[%s] Copying physio files...\n',datestr(now))

D = dir(fullfile(physioFolder,'*.log'));
D = sort(extractfield(D,'name'))';
nFileTypes = 3; % _Info, _RESP, _PULS
idx = 1;

if length(D) ~= size(RunOrder,1)*nFileTypes
    error('number of physio files is unexpected!')
end

for ii = 1:size(RunOrder,1)
   
   for jj = 1:nFileTypes
       
        aux = strsplit(D{idx},'_');
        
        copyfile(fullfile(physioFolder,D{idx}),...
            fullfile(stcibitFolder,'RAW',RunOrder{ii,1},'LINKED',[subID '_' RunOrder{ii,1} '_PHYSIO_' aux{end}]));
        
        idx = idx + 1;
        
   end
    
end

%% Copy Eyetracker data

D = dir(fullfile(eyetrackerFolder,'*.edf'));

if ~isempty(D) % no eyetracker data available
    
    if length(D) ~= size(RunOrder,1)
        warning('number of eyetracker files is unexpected!')
    end
    
    D = sort(extractfield(D,'name'))';
    
    fprintf('[%s] Copying %i eyetracker files...\n',datestr(now),length(D))
    
    for ii = 1:size(RunOrder,1)
        
        copyfile(fullfile(eyetrackerFolder,D{ii}),...
            fullfile(stcibitFolder,'RAW',RunOrder{ii,1},'LINKED',[subID '_' RunOrder{ii,1} '_EYETRACKER.edf']));
        
    end
else
    warning('No eyetracker files available. Moving on.')
end

%% Copy keypress data

D = dir(fullfile(keypressFolder,'*.mat'));
D = extractfield(D,'name')';

% clean unwanted files (OUT and Aborted runs)
idxtoRemove = [];
times = cell(length(D),1);

for ii = 1:length(D)
    
   aux = strsplit(D{ii},'_');
   
   if strcmp(aux{2},'OUT') || strcmp(aux{end},'Aborted.mat')
       idxtoRemove = [idxtoRemove ii];
   end
    
   times(ii) = aux(4);
   
end

times(idxtoRemove) = [];
D(idxtoRemove) = [];

% order list
[~,ord] = sort(times);
D = D(ord);

if length(D) ~= size(RunOrder,1)
    warning('number of keypress files is unexpected!')
end

fprintf('[%s] Copying %i keypress files...\n',datestr(now),length(D))

% copy
for ii = 1:size(RunOrder,1)
    
     copyfile(fullfile(keypressFolder,D{ii}),...
            fullfile(stcibitFolder,'RAW',RunOrder{ii,1},'LINKED',[subID '_' RunOrder{ii,1} '_KEYPRESS.mat']));
    
end

%% Copy protocol data

fprintf('[%s] Copying %i protocol files...\n',datestr(now),size(RunOrder,1))

for ii = 1:size(RunOrder,1)
    
     copyfile(fullfile(protocolFolder,[RunOrder{ii,1} '.prt']),...
            fullfile(stcibitFolder,'RAW',RunOrder{ii,1},'LINKED',[subID '_' RunOrder{ii,1} '_PROTOCOL.prt']));
    
end

%% Done
fprintf('[%s] Done!\n',datestr(now))
