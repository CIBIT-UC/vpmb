%%

% Requires:
% - textborder (https://www.mathworks.com/matlabcentral/fileexchange/27383-textborder-higher-contrast-text-using-a-1-pixel-thick-border)
% - notBoxPlot

addpath('/DATAPOOL/home/alexandresayal/Documents/MATLAB/notBoxPlot')

clear,clc

%% Settings
sdcMethods = {'NONE', 'EPI', 'SPE', 'GRE', 'NLREG'};
nMethods = length(sdcMethods);

%% Load data from step 02
dataset = struct();

for ii = 1:length(sdcMethods)
    filename = dir(['Output_Step04_' sdcMethods{ii} '*.mat']);
    dataset.(sdcMethods{ii}) = load(filename.name,'outputMatrix');
end

load(filename.name,'roiList','nROIs','taskList','nTasks','subjectList','nSubjects')

clear filename ii

%% Fix ROI names because they will be used for struct field names
roiList = erase(roiList,'+');

%% Compare T1w peak voxel coordinate of each ROI per participant and across sdc method for each TR
% CoG dimensions - 3,nROIs,nSubjects,nTasks
% output dimensions - nROIs x 5 x nSubjects

TRList = {'TR0500','TR0750','TR1000','TR2500'};
nTRs = length(TRList);
TRIndexes = {[1 5], [2 6], [3 7], [4 8]}; % ignoring 9 - localizer

%% average distance between sdcMethods -> how much the methods differ

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

%% UGLY PLOTSSSSS

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

        saveas(gcf,sprintf('Step05_outputFigs/%s--%s.png',roiList{roitoplot},TRList{trtoplot}))
        close
end

%% DIFFERENT PLOTSSSSS - per roi, WITHOUT SEM

CV = combvec(1:nTRs,1:nROIs)';

for jj = 1:size(CV,1)
    
    roitoplot = CV(jj,2);
    trtoplot = CV(jj,1);

    % Start plotting in specific figure (one per ROI)
    fig = figure(roitoplot);
    
    DATAtoPLOT = DIST.(roiList{roitoplot}).(TRList{trtoplot});

    % stat test - probably the stat only is not enough - should threshold in mm
    % now I test for different and greater than 2 mm - that should suffice
    TestZero = ttest(DATAtoPLOT.data, 2, 'dim',3,'tail','right');

    % set minimum distance of 2mm - voxel size
    TestZero(isnan(TestZero)) = 0;
    %TestZero = TestZero & DATAtoPLOT.mean >= 1.999;
    
    set(gcf,'Units','inches', 'Position',[2 2 13 11])

    % find maximum - using fixed value here
    %maxV = ceil(max(max(DATAtoPLOT.mean)));
    maxV = 11;
    
    subplot(2,2,trtoplot)
        % plot matrix
        im1 = imagesc(DATAtoPLOT.mean, [0 maxV]);

        % iterate on the connections
        for cc = 1:size(C,1)
            % depending on if the test is significant or not, write the data label
            % in bold + star or not
            if TestZero(C(cc,1),C(cc,2)) == 1
                textborder(C(cc,2),C(cc,1),sprintf('%0.2f*',DATAtoPLOT.mean(C(cc,1),C(cc,2))),...
                    'white',[0.5 0.5 0.5],'horizontalalignment','center','fontweight','bold','FontSize', 12)
            else
                textborder(C(cc,2),C(cc,1),sprintf('%0.2f',DATAtoPLOT.mean(C(cc,1),C(cc,2))),...
                    'white',[0.5 0.5 0.5],'horizontalalignment','center','FontSize', 12)
            end
        end

        % Colormap and Colorbar
        colormap(flipud(hot(maxV*2))); 
        h = colorbar('eastoutside');
        
        % Title, axis
        title([roiList{roitoplot} ' | ' TRList{trtoplot}], 'FontSize', 14, 'interpreter', 'none');
        set(gca, 'XTick', (1:nROIs));
        set(gca, 'YTick', (1:nROIs));
        set(gca, 'Ticklength', [0 0])
        set(gca, 'FontSize', 12)
        grid off
        box on

        % Labels
        xlabel(h, 'Distance (mm)', 'FontSize', 14);
        set(gca, 'XTickLabel', sdcMethods, 'XTickLabelRotation', 0);
        set(gca, 'YTickLabel', sdcMethods);

        if mod(jj,nTRs) == 0
            saveas(gcf,sprintf('Step05_outputFigs/MEAN--%s.png',roiList{roitoplot}))
            %pause
            close
        end
end

%% Compare T-values
% TValue dimensions - nROIs,nSubjects,nTasks

%% T-VALUE DATA REORGANIZATION PER ROI

TVALUE = struct();

% Iterate on the ROIs
for rr = 1:nROIs
    
    %Iterate on the TRs
    for tt = 1:nTRs
        
        % Initaliaze matrix
        TVALUE.(roiList{rr}).(TRList{tt}) = zeros(nSubjects,nMethods);
        
        % Iterate on the sdcMethods
        for mm = 1:nMethods

            % average for the runs with the same TR and save
            %TVALUE.(roiList{rr}).(TRList{tt})(:,mm) = mean(dataset.(sdcMethods{mm}).outputMatrix.MNI152NLin2009ASym.PeakVoxTValue(rr, :, TRIndexes{tt}) , 3);
             TVALUE.(roiList{rr}).(TRList{tt})(:,mm) = mean(dataset.(sdcMethods{mm}).outputMatrix.T1w.PeakVoxTValue(rr, :, TRIndexes{tt}) , 3);         
        end
               
    end
      
end

%% PLOT T-VALUES

CV = combvec(1:nTRs,1:nROIs)';

for jj = 1:size(CV,1)
    
    trtoplot = CV(jj,1);
    roitoplot = CV(jj,2);

    % Start plotting in specific figure (one per ROI)
    fig = figure(roitoplot);
    set(gcf,'Units','inches', 'Position',[2 2 13 11])

    DATAtoPLOT = TVALUE.(roiList{roitoplot}).(TRList{trtoplot});
    
    maxV = 10;

    subplot(2,2,trtoplot)
        notBoxPlot(DATAtoPLOT)
        
        xlabel('sdcMethod')
        xticklabels(sdcMethods)
        ylabel('t value')
        title([roiList{roitoplot} ' | ' TRList{trtoplot}], 'FontSize', 14, 'interpreter', 'none');
        ylim([0 maxV])
        
    if mod(jj,nTRs) == 0
        %saveas(gcf,sprintf('Step05_outputFigs/MEAN--%s.png',roiList{roitoplot}))
        pause
        %close
    end
        
end