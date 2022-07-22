clear,clc

%% Settings
sdcMethods = {'NLREG', 'NONE', 'EPI', 'SPE', 'GRE'};
nMethods = length(sdcMethods);

%% Load data from step 02
dataset = struct();

for ii = 1:length(sdcMethods)
    filename = dir(['Output_Step02_' sdcMethods{ii} '*.mat']);
    dataset.(sdcMethods{ii}) = load(filename.name,'outputMatrix');
end

load(filename.name,'roiList','nROIs','taskList','nTasks','subjectList','nSubjects')

clear filename ii

%% Compare T1w center coordinates of each ROI per participant and across sdc method for each TR
% CoG dimensions - 3,nROIs,nSubjects,nTasks
% output dimensions - nROIs x 5 x nSubjects

TRList = {'TR0500','TR0750','TR1000','TR2500'};
TRIndexes = {[1 5], [2 6], [3 7 9], [4 8]};

for rr = 1:4
    
    DIST.(TRList{rr}) = zeros(nROIs,nMethods,nSubjects);
    
    auxiliaryStruct = struct();
    
    for mm = 1:nMethods
        
        auxiliaryStruct.(sdcMethods{mm}) = squeeze(dataset.(sdcMethods{mm}).outputMatrix.T1w.CoG(:,:, :, TRIndexes{rr}));
        
        auxiliaryStruct.(sdcMethods{mm}) = mean(aux,4);
        
    end
    
    pdist([auxiliaryStruct.GRE(:,1,1),auxiliaryStruct.SPE(:,1,1)]','EUCLIDEAN')
    
end

pdistll


roiIdx = 1;
taskIdx = [1 5];

% These are the center coordinates in 3D for all subjects and the selected
% tasks
aux = squeeze(dataset.(sdcMethods{1}).outputMatrix.T1w.CoG(:,roiIdx, :, taskIdx));

mean(aux,3)

std(aux,[],3)
