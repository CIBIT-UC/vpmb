clear,clc

%% Settings
sdcMethods = {'NONE', 'EPI', 'SPE', 'GRE'};
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

% iterate on the TRIndexes
for rr = 1:length(TRIndexes)
    
    %DIST.(TRList{rr}) = zeros(nROIs,nMethods,nSubjects);
    
    auxiliaryStruct = struct();
    
    for mm = 1:nMethods
        
        aux = dataset.(sdcMethods{mm}).outputMatrix.T1w.PeakVoxCoord_mm(:,:, :, TRIndexes{rr});
        
        auxiliaryStruct.(sdcMethods{mm}) = mean(aux,4); % average all runs with the same TR. This will be 3 x nROIs x nSubjects
        
    end
    
    %pdist([auxiliaryStruct.GRE(:,1,1),auxiliaryStruct.SPE(:,1,1)]','EUCLIDEAN')
    
end

%% test plot
roiNumber = 9;
testData = squeeze(auxiliaryStruct.EPI(:,roiNumber,:));
testDataB = squeeze(auxiliaryStruct.GRE(:,roiNumber,:));
testDataC = squeeze(auxiliaryStruct.NONE(:,roiNumber,:));
testDataD = squeeze(auxiliaryStruct.SPE(:,roiNumber,:));

figure

plot3(testData(1,:),testData(2,:),testData(3,:),'o','LineWidth',2)
hold on
plot3(testDataB(1,:),testDataB(2,:),testDataB(3,:),'.','LineWidth',2)
hold on
plot3(testDataC(1,:),testDataC(2,:),testDataC(3,:),'x','LineWidth',2)
hold on
plot3(testDataD(1,:),testDataD(2,:),testDataD(3,:),'s','LineWidth',2)
hold off

title(roiList{roiNumber},'interpreter','none')


%% 

% average distance between EPI, SPE, GRE -> how much the methods differ


%%
pdistll


roiIdx = 1;
taskIdx = [1 5];

% These are the center coordinates in 3D for all subjects and the selected
% tasks
aux = squeeze(dataset.(sdcMethods{1}).outputMatrix.T1w.CoG(:,roiIdx, :, taskIdx));

mean(aux,3)

std(aux,[],3)
