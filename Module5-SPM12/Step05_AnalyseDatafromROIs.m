clear,clc

%% Settings
sdcMethods = {'NONE', 'EPI', 'SPE', 'GRE', 'NLREG'};
nMethods = length(sdcMethods);

%% Load data from step 02
dataset = struct();

for ii = 1:length(sdcMethods)
    filename = dir(['Output_Step02_' sdcMethods{ii} '*.mat']);
    dataset.(sdcMethods{ii}) = load(filename.name,'outputMatrix');
end

load(filename.name,'roiList','nROIs','taskList','nTasks','subjectList','nSubjects')

clear filename ii

%% Compare T1w center peak voxel coordinate of each ROI per participant and across sdc method for each TR
% CoG dimensions - 3,nROIs,nSubjects,nTasks
% output dimensions - nROIs x 5 x nSubjects
% this is nonsense with the CoG - the coordinates will be the same since the reference
% ROIs are the same. This would only work for the glm cluster defined for
% each participant (maybe..)
% However, with the peak voxel coordinate...

TRList = {'TR0500','TR0750','TR1000','TR2500'};
TRIndexes = {[1 5], [2 6], [3 7 9], [4 8]};

% iterate on the TRIndexes
for rr = 1:length(TRIndexes)
        
    auxiliaryStruct = struct();
    
    for mm = 1:nMethods
        
        aux = dataset.(sdcMethods{mm}).outputMatrix.T1w.PeakVoxCoord_mm(:,:, :, TRIndexes{rr});
        
        auxiliaryStruct.(sdcMethods{mm}) = mean(aux,4); % average all runs with the same TR. This will be 3 x nROIs x nSubjects
        
    end
        
end

%% 3D figure - test
% roiNumber = 9;
% testData = squeeze(auxiliaryStruct.EPI(:,roiNumber,:));
% testDataB = squeeze(auxiliaryStruct.GRE(:,roiNumber,:));
% testDataC = squeeze(auxiliaryStruct.NONE(:,roiNumber,:));
% testDataD = squeeze(auxiliaryStruct.SPE(:,roiNumber,:));
% testDataE = squeeze(auxiliaryStruct.NLREG(:,roiNumber,:));
% 
% figure
% 
% plot3(testData(1,:),testData(2,:),testData(3,:),'o','LineWidth',4,'MarkerSize',4)
% hold on
% plot3(testDataB(1,:),testDataB(2,:),testDataB(3,:),'.','LineWidth',4,'MarkerSize',4)
% hold on
% plot3(testDataC(1,:),testDataC(2,:),testDataC(3,:),'x','LineWidth',4,'MarkerSize',4)
% hold on
% plot3(testDataD(1,:),testDataD(2,:),testDataD(3,:),'s','LineWidth',4,'MarkerSize',4)
% hold on
% plot3(testDataE(1,:),testDataE(2,:),testDataE(3,:),'*','LineWidth',4,'MarkerSize',4)
% hold off
% 
% title(roiList{roiNumber},'interpreter','none')


%% average distance between EPI, SPE, GRE -> how much the methods differ

C = combnk(1:nMethods,2);

DIST = struct();

% Iterate on the combinations of methods
for cc = 1:size(C,1)
    
    % Iterate on the ROIs
    for rr = 1:nROIs
        
        
        % Iterate on the TRs
        for tt = 1:length(TRIndexes)
            
            if cc == 1
                DIST.(roiList{rr}).(TRList{tt}).mean = zeros(nMethods,nMethods);
                DIST.(roiList{rr}).(TRList{tt}).sem = zeros(nMethods,nMethods);
                DIST.(roiList{rr}).(TRList{tt}).data = zeros(nMethods,nMethods,nSubjects);
            end
            
            A = squeeze(mean(dataset.(sdcMethods{C(cc,1)}).outputMatrix.T1w.PeakVoxCoord_mm(:,rr,:,TRIndexes{tt}),4));
            B = squeeze(mean(dataset.(sdcMethods{C(cc,2)}).outputMatrix.T1w.PeakVoxCoord_mm(:,rr,:,TRIndexes{tt}),4));
            
            D = sqrt(sum((A - B) .^ 2)); % distance between A and B for each participant
            DIST.(roiList{rr}).(TRList{tt}).data(C(cc,1),C(cc,2),:) = D; % save the data for stat testing
            
            DIST.(roiList{rr}).(TRList{tt}).mean(C(cc,1),C(cc,2)) = mean(D); % save the mean across participants
            DIST.(roiList{rr}).(TRList{tt}).sem(C(cc,1),C(cc,2)) = std(D) / sqrt(nSubjects); % save the sem across participants
            
        end % end TR iteration
        
        
    end % end ROI iteration
    
    
end % end combination of methods iteration

%% Stat test
%ttest(DIST.hMT_L_brainnetome.TR0500.data,zeros(nMethods,nMethods,nSubjects),'dim',3)

%% PLOTSSSSS

roitoplot = 3;
trtoplot = 1;

CV = combvec(1:nROIs,1:length(TRIndexes))';

for jj = 1:size(CV,1)
    
    roitoplot = CV(jj,1);
    trtoplot = CV(jj,2);

    DATAtoPLOT = DIST.(roiList{roitoplot}).(TRList{trtoplot});

    % stat test - probably the stat only is not enough - should threshold in mm
    TestZero = ttest(DATAtoPLOT.data,0,'dim',3,'tail','right');

    % set minimum distance of 2mm - voxel size
    TestZero(isnan(TestZero)) = 0;
    TestZero = TestZero & DATAtoPLOT.mean >= 1.999;

    % Start plotting
    fig = figure;

    set(gcf,'Units','inches', 'Position',[4 4 17.5 6.5])

    % find maximum
    maxV = ceil(max(max(DATAtoPLOT.mean)));

    subplot(1,2,1)
        im1 = imagesc(DATAtoPLOT.mean, [0 maxV]);

        for cc = 1:size(C,1)
            if TestZero(C(cc,1),C(cc,2)) == 1
                textborder(C(cc,2),C(cc,1),sprintf('%0.2f*',DATAtoPLOT.mean(C(cc,1),C(cc,2))),...
                    'white',[0.5 0.5 0.5],'horizontalalignment','center','fontweight','bold','FontSize', 12)
            else
                textborder(C(cc,2),C(cc,1),sprintf('%0.2f',DATAtoPLOT.mean(C(cc,1),C(cc,2))),...
                    'white',[0.5 0.5 0.5],'horizontalalignment','center','FontSize', 12)
            end
        end

        colormap(flipud(hot(20)));

        h = colorbar('eastoutside');
        xlabel(h, 'Distance (mm)', 'FontSize', 14);

        % Title, axis
        title([roiList{roitoplot} ' | ' TRList{trtoplot}], 'FontSize', 14, 'interpreter', 'none');
        set(gca, 'XTick', (1:nROIs));
        set(gca, 'YTick', (1:nROIs));
        set(gca, 'Ticklength', [0 0])
        set(gca, 'FontSize', 12)
        grid off
        box on

        % Labels
        set(gca, 'XTickLabel', sdcMethods, 'XTickLabelRotation', 0);
        set(gca, 'YTickLabel', sdcMethods);

    subplot(1,2,2)
        im2 = imagesc(DATAtoPLOT.sem, [0 maxV]);

        for cc = 1:size(C,1)
            textborder(C(cc,2),C(cc,1),sprintf('%0.2f',DATAtoPLOT.sem(C(cc,1),C(cc,2))),...
                'white',[0.5 0.5 0.5],'horizontalalignment','center','fontweight','bold','FontSize', 12)
        end

        colormap(flipud(hot(maxV*4)));

        h = colorbar('eastoutside');
        xlabel(h, 'Distance (mm)', 'FontSize', 14);

        % Title, axis
        title('SEM', 'FontSize', 14);
        set(gca, 'XTick', (1:nROIs));
        set(gca, 'YTick', (1:nROIs));
        set(gca, 'Ticklength', [0 0])
        set(gca, 'FontSize', 12)
        grid off
        box on

        % Labels
        set(gca, 'XTickLabel', sdcMethods, 'XTickLabelRotation', 0);
        set(gca, 'YTickLabel', sdcMethods);

        saveas(gcf,sprintf('Step03_outputFigs/%s--%s.png',roiList{roitoplot},TRList{trtoplot}))
        close
end


