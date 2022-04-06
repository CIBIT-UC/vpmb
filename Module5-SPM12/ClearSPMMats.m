clear,clc

%% Folders
bidsFolder     = '/DATAPOOL/VPMB/BIDS-VPMB-NONE';
%bidsFolder     = '/DATAPOOL/VPMB/BIDS-VPMB-NLREG';
%bidsFolder     = '/DATAPOOL/VPMB/BIDS-VPMB-EPI';
%bidsFolder     = '/DATAPOOL/VPMB/BIDS-VPMB-SPE';
%bidsFolder     = '/DATAPOOL/VPMB/BIDS-VPMB-GRE';
derivFolder    = fullfile(bidsFolder,'derivatives');

%% Extract Subject List from BIDS
aux = dir(fullfile(bidsFolder,'sub-*'));
subjectList = extractfield(aux,'name');
clear aux

%% Extract Task List from BIDS
aux = dir(fullfile(bidsFolder,'sub-01','func','*_task-*_bold.json'));
taskList = extractfield(aux,'name');

taskList = cellfun(@(x) x(8:end-10), taskList, 'un', 0); % remove trailing and leading info (VERY custom)
nTasks = length(taskList);

%% Iterate on subs and runs
for ss = 1:length(subjectList)
    
    subjectID = subjectList{ss};
    
    fprintf('%s processing started!\n',subjectID)
    
    %% Create spmFolder
    spmFolder = fullfile(derivFolder,'spm12',subjectID);
    
    for tt = 1:nTasks
        
        delete(fullfile(spmFolder,['model_' taskList{tt} '_T1w'],'SPM.mat'))
        %rmdir(fullfile(spmFolder,['model_' taskList{tt} '_T1w']), 's')
        %rmdir(fullfile(spmFolder,['3d_' taskList{tt} '_T1w']), 's')
        
        delete(fullfile(spmFolder,['model_' taskList{tt} '_MNI152NLin2009cAsym'],'SPM.mat'))
            
    end

    
end
