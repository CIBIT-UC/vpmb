
% Requires neuroelf

tsvFolder = 'temp-tsv';

bidsFolder = '/media/alexandresayal/DATA4TB/VPMB-BIDS';

%% Subject List
aux = dir(fullfile(bidsFolder,'sub-*'));
subjectList = extractfield(aux,'name');
clear aux

nSubjects = length(subjectList);

%% Task List
taskList = {'task-loc_acq-1000_run-01','task-AA_acq-0500_run-01','task-AA_acq-0750_run-01','task-AA_acq-1000_run-01','task-AA_acq-2500_run-01','task-UA_acq-0500_run-01','task-UA_acq-0750_run-01','task-UA_acq-1000_run-01','task-UA_acq-2500_run-01'};

%% PRT List
% In this case the protocol is the same for all participants
prtFolder = '/media/alexandresayal/DATA4TB/VPMB-RAW/VPMBAUS01/PROTOCOL';
prtList = {'TASK-LOC-1000.prt','TASK-AA-0500.prt','TASK-AA-0750.prt','TASK-AA-1000.prt','TASK-AA-2500.prt','TASK-UA-0500.prt','TASK-UA-0750.prt','TASK-UA-1000.prt','TASK-UA-2500.prt'};
nRuns = length(prtList);

%% TR List
TRList = [1 0.5 0.75 1 2.5 0.5 0.75 1 2.5]; % in seconds

%% Convert

for rr = 1:nRuns
    
    [ cond_names , intervalsPRT ,~,~,~, blockDur, blockNum ] = readProtocol( fullfile(prtFolder, prtList{rr}) , TRList(rr) );
    
    Condition = {};
    Onset = [];
    Duration = [];
    for cc = 1:length(cond_names)
        Condition = [Condition ; repmat({cond_names(cc)},blockNum(cc),1)];
        Onset = [Onset ; intervalsPRT.(cond_names{cc})(:,1).*TRList(rr)-TRList(rr)];
        Duration = [Duration ; repmat(blockDur(cc).*TRList(rr),blockNum(cc),1)];
    end
    [Onset,idx] = sort(Onset);
    Condition = Condition(idx);
    Duration = Duration(idx);
    
    T = table(Condition,Onset,Duration);
    
    export_file = fullfile(tsvFolder,...
        sprintf('task-%s_events.txt',prtList{rr}(1:end-4)));
    
    writetable(T,export_file,'Delimiter','\t');
    movefile(export_file,[export_file(1:end-4) '.tsv']);
    
end

%% Copy to BIDS
% Iterate

for ss = 1:nSubjects
    
    subjectID = subjectList{ss};
    
    for rr = 1:nRuns
        
        subfuncFolder = fullfile(bidsFolder,subjectID,'func');
        
        tsvBIDSName = sprintf('%s_%s_events.tsv',subjectID,taskList{rr});
        
        % Check if exists to replace
        if exist(fullfile(subfuncFolder,tsvBIDSName),'file')
            
            copyfile(fullfile(tsvFolder,['task-' prtList{rr}(1:end-4) '_events.tsv']),...
                     fullfile(subfuncFolder,tsvBIDSName) )
            
        else
            warning('%s does not exist. Expected?',tsvBIDSName)
        end
        
    end
    
    fprintf('%s done! \n',subjectID)
       
end
