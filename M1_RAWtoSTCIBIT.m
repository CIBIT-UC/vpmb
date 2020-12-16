clear,clc,close all

%% Requirements

% 1) jsonlab (https://github.com/fangq/jsonlab)
addpath('/home/alexandresayal/Documents/MATLAB/jsonlab')

% 2) dcm2niix (https://github.com/rordenlab/dcm2niix)
% Make sure dcm2niix version 1.0.20201102  is installed

%% Settings
subID = 'VPMBAUS23';

rawDicomFolder = '/home/alexandresayal/Desktop/BIDS-VPMB/sourcedata/15/01';
niiFolder = '/home/alexandresayal/Desktop/VPMB-NIFTI/VPMBAUS23';
stcibitFolder = '/home/alexandresayal/Desktop/VPMB-STCIBIT/VPMBAUS23';
physioFolder = '/media/alexandresayal/DATA_1TB/RAW_DATA_VP_MBEPI_DistortionCorr/VPMBAUS23_LOGS';
keypressFolder = '/media/alexandresayal/DATA_1TB/RAW_DATA_VP_MBEPI_DistortionCorr/VPMBAUS23_KEYS';
eyetrackerFolder = '/media/alexandresayal/DATA_1TB/RAW_DATA_VP_MBEPI_DistortionCorr/VPMBAUS23_EYETRACKER';

protocolFolder = '/media/alexandresayal/DATA_1TB/RAW_DATA_VP_MBEPI_Codev0.5/PRTs/renamedForSTCIBIT';

%% Conversion to Nifti

% create nii folder if it does not exist
if ~exist(niiFolder,'dir')
    mkdir(niiFolder)
end

% check if folder is empty
if length(dir(niiFolder)) > 2
   error('Please remove all files in niiFolder') 
end

disp('--| Converting files to nii...')

bCmd = sprintf('dcm2niix -f "%%d" -p y -z y -o "%s" "%s"',niiFolder,rawDicomFolder);

system(bCmd)

%% Import naming match
% custom file with the match between the sequence name and the desired name
% in the STCIBIT format.

T = importMatchFile('runNameMatch.csv');

%% Read NIFTI folder and copy files

disp('--| Copying nii files...')

Ndir = dir(niiFolder);

for ii = 3:length(Ndir) % mind this 3 - it may vary with OS
    
    % retrieve name and extension
    aux = strsplit(Ndir(ii).name,'.');
    
    if strcmp(aux{end},'gz') % needed workaround due to inconsistent number of dots in some files
        name = strjoin(aux(1:end-2),'.');
        ext = 'nii.gz';        
    else
        name = strjoin(aux(1:end-1),'.');
        ext = aux{end};
    end
    
    % find run name in match file
    idx = find(strcmp(T(:,1),name));
    
    % Copy and rename
    if isempty(idx) % will not be copied (discarded on purpose? =) )
        
        warning([name ' name does not exist in match file'])
        
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
        
    end
    
end

%% Retrieve run order

D = dir(fullfile(stcibitFolder,'RAW','TASK-*'));

RunOrder = cell(length(D),2);

for ii = 1:length(D)
    
    funcFile = fullfile(stcibitFolder,'RAW',D(ii).name,[subID '_' D(ii).name '.json']);
    
    auxJ = loadjson(funcFile);
    
    RunOrder{ii,1} = D(ii).name;
    RunOrder{ii,2} = auxJ.AcquisitionTime;
    
end

RunOrder = sortrows(RunOrder,2);

%% Copy Physio files

disp('--| Copying physio files...')

D = dir(fullfile(physioFolder,'*.log'));
D = sort(extractfield(D,'name'))';
nFileTypes = 3; % _Info, _RESP, _PULS
idx = 1;

if length(D) ~= size(RunOrder,1)*nFileTypes
    warning('number of physio files is unexpected!')
end

for ii = 1:size(RunOrder,1)
   
   for jj = 1:nFileTypes
       
        aux = strsplit(D{idx},'_');
        
        copyfile(fullfile(physioFolder,D{idx}),...
            fullfile(stcibitFolder,'RAW',RunOrder{ii,1},'LINKED',[subID '_PHYSIO_' aux{end}]));
        
        idx = idx + 1;
        
   end
    
end

%% Copy Eyetracker data

disp('--| Copying eyetracker files...')

D = dir(fullfile(eyetrackerFolder,'*.edf'));

if ~isempty(D) % no eyetracker data available
    
    if length(D) ~= size(RunOrder,1)
        warning('number of eyetracker files is unexpected!')
    end
    
    D = sort(extractfield(D,'name'))';
    
    for ii = 1:size(RunOrder,1)
        
        copyfile(fullfile(eyetrackerFolder,D{ii}),...
            fullfile(stcibitFolder,'RAW',RunOrder{ii,1},'LINKED',[subID '_EYETRACKER.edf']));
        
    end
else
    warning('No eyetracker files available. Moving on.')
end

%% Copy keypress data

disp('--| Copying keypress files...')

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

% copy
for ii = 1:size(RunOrder,1)
    
     copyfile(fullfile(keypressFolder,D{ii}),...
            fullfile(stcibitFolder,'RAW',RunOrder{ii,1},'LINKED',[subID '_KEYPRESS.mat']));
    
end

%% Copy protocol data

disp('--| Copying protocol files...')

for ii = 1:size(RunOrder,1)
    
     copyfile(fullfile(protocolFolder,[RunOrder{ii,1} '.prt']),...
            fullfile(stcibitFolder,'RAW',RunOrder{ii,1},'LINKED',[subID '_PROTOCOL.prt']));
    
end

%% Done

disp('--| Done!')




