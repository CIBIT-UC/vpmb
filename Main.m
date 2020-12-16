%% Requirements

% https://github.com/fangq/jsonlab
addpath('/home/alexandresayal/Documents/MATLAB/jsonlab')

% Make sure dcm2niix version 1.0.20201102  is installed

%% Settings
subID = 'VPMBAUS02';
rawDicomFolder = '/home/alexandresayal/Desktop/BIDS-VPMB/sourcedata/02/01';
niiFolder = '/home/alexandresayal/Desktop/VPMB-NIFTI/VPMBAUS02';
stcibitFolder = '/home/alexandresayal/Desktop/VPMB-STCIBIT/VPMBAUS02';

if ~exist(niiFolder,'dir')
    mkdir(niiFolder)
end

%% Conversion to Nifti

disp('--| Converting files to nii...')

bCmd = sprintf('dcm2niix -f "%%d" -p y -z y -o "%s" "%s"',niiFolder,rawDicomFolder);

system(bCmd)

%% Import naming match

T = importMatchFile('runNameMatch.csv');

%% Read NIFTI folder and copy files

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
                mkdir(fullfile(stcibitFolder,'RAW',folders{jj},'LINKED'));
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

%% Rename Linked data

sourceFolder = '/home/alexandresayal/Desktop/VPMB-STCIBIT/VPMBAUS01/RAW/';

D = dir([sourceFolder 'TASK*']);

for ii = 1:length(D)
    
    linkedFolder = fullfile(sourceFolder,D(ii).name,'LINKED');
    
    try
        
        % Eyetracker files
        Daux = dir(fullfile(linkedFolder,'*.edf'));
        
        movefile(fullfile(linkedFolder,Daux(1).name),...
            fullfile(linkedFolder,[subID '_EYETRACKER.edf']));
        
        % Keypress files
        Daux = dir(fullfile(linkedFolder,'*.mat'));
        
        movefile(fullfile(linkedFolder,Daux(1).name),...
            fullfile(linkedFolder,[subID '_KEYPRESS.edf']));
        
        % Physio files
        Daux = dir(fullfile(linkedFolder,'*.log'));
        
        for jj = 1:length(Daux)
            
            aux = strsplit(Daux(jj).name,'_');
            
            movefile(fullfile(linkedFolder,Daux(jj).name),...
                fullfile(linkedFolder,[subID '_PHYSIO_' aux{end}]));
            
        end
        
    catch
        warning('Already renamed')
    end
    
end








