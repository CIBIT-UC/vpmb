%% Import data

DTable_BBR = importBBRfile('CostValues_BBR_func2struct.txt');
DTable_NormMI = importBBRfile('CostValues_NormMI_func2struct.txt');
DTable_CorrRatio = importBBRfile('CostValues_CorrRatio_func2struct.txt');

M_BBR = [DTable_BBR.costBefore DTable_BBR.costAfterGRE DTable_BBR.costAfterSPE DTable_BBR.costAfterEPI DTable_BBR.costAfterGRESPE DTable_BBR.costAfterGREEPI];
M_NormMI = [DTable_NormMI.costBefore DTable_NormMI.costAfterGRE DTable_NormMI.costAfterSPE DTable_NormMI.costAfterEPI DTable_NormMI.costAfterGRESPE DTable_NormMI.costAfterGREEPI];
M_CorrRatio = [DTable_CorrRatio.costBefore DTable_CorrRatio.costAfterGRE DTable_CorrRatio.costAfterSPE DTable_CorrRatio.costAfterEPI DTable_CorrRatio.costAfterGRESPE DTable_CorrRatio.costAfterGREEPI];

%% Not Box plot BBR
clrMap = lines;
figure('position',[100 100 1000 500])
H = notBoxPlot(M_BBR);

for ii = 1:6
    set(H(ii).data,'Marker','.','MarkerSize',6)
    set(H(ii).sdPtch,'FaceColor',clrMap(ii,:),'EdgeColor','none')
    set(H(ii).semPtch,'FaceColor',clrMap(ii,:)*0.1,'EdgeColor','none')
    set(H(ii).mu,'Color',[0.8 0.2 0])
end

xticklabels({'before','after GRE','after SPE','after EPI','after GRE-SPE','after GRE-EPI'})
title('BBR cost function values - func2struct')
ylim([0.2 0.8])
set(gca,'FontSize',16)

%% Not Box plot NormMI
clrMap = lines;
figure('position',[100 100 1000 500])
H = notBoxPlot(M_NormMI);

for ii = 1:6
    set(H(ii).data,'Marker','.','MarkerSize',6)
    set(H(ii).sdPtch,'FaceColor',clrMap(ii,:),'EdgeColor','none')
    set(H(ii).semPtch,'FaceColor',clrMap(ii,:)*0.1,'EdgeColor','none')
    set(H(ii).mu,'Color',[0.8 0.2 0])
end

xticklabels({'before','after GRE','after SPE','after EPI','after GRE-SPE','after GRE-EPI'})
title('Normalized mutual information cost function values - func2struct')
ylim([-1.3 -1.1])
set(gca,'FontSize',16)

%% Not Box plot CorrRatio
clrMap = lines;
figure('position',[100 100 1000 500])
H = notBoxPlot(M_CorrRatio);

for ii = 1:6
    set(H(ii).data,'Marker','.','MarkerSize',6)
    set(H(ii).sdPtch,'FaceColor',clrMap(ii,:),'EdgeColor','none')
    set(H(ii).semPtch,'FaceColor',clrMap(ii,:)*0.1,'EdgeColor','none')
    set(H(ii).mu,'Color',[0.8 0.2 0])
end

xticklabels({'before','after GRE','after SPE','after EPI','after GRE-SPE','after GRE-EPI'})
title('Correlation ratio cost function values - func2struct')
ylim([0 0.5])
set(gca,'FontSize',16)

%% TR1000 BBR

idx1=strcmp(DTable_BBR.taskName,'TASK-LOC-1000');

figure('position',[100 100 1000 500])
H = notBoxPlot(M_BBR(idx1,:));

for ii = 1:6
    set(H(ii).data,'Marker','.','MarkerSize',6)
    set(H(ii).sdPtch,'FaceColor',clrMap(ii,:),'EdgeColor','none')
    set(H(ii).semPtch,'FaceColor',clrMap(ii,:)*0.1,'EdgeColor','none')
    set(H(ii).mu,'Color',[0.8 0.2 0])
end

xticklabels({'before','after GRE','after SPE','after EPI','after GRE-SPE','after GRE-EPI'})
title('BBR cost function values - func2struct')
ylim([0.2 0.8])
set(gca,'FontSize',16)

%% TR2500 BBR

idx1=strcmp(DTable_BBR.taskName,'TASK-AA-2500') | strcmp(DTable_BBR.taskName,'TASK-UA-2500');

figure('position',[100 100 1000 500])
H = notBoxPlot(M_BBR(idx1,:));

for ii = 1:6
    set(H(ii).data,'Marker','.','MarkerSize',6)
    set(H(ii).sdPtch,'FaceColor',clrMap(ii,:),'EdgeColor','none')
    set(H(ii).semPtch,'FaceColor',clrMap(ii,:)*0.1,'EdgeColor','none')
    set(H(ii).mu,'Color',[0.8 0.2 0])
end

xticklabels({'before','after GRE','after SPE','after EPI','after GRE-SPE','after GRE-EPI'})
title('BBR cost function values - func2struct')
ylim([0.2 0.8])
set(gca,'FontSize',16)

%% TR1000 CorrRatio

idx1=strcmp(DTable_BBR.taskName,'TASK-AA-1000') | strcmp(DTable_BBR.taskName,'TASK-UA-1000');

figure('position',[100 100 1000 500])
H = notBoxPlot(M_CorrRatio(idx1,:));

for ii = 1:6
    set(H(ii).data,'Marker','.','MarkerSize',6)
    set(H(ii).sdPtch,'FaceColor',clrMap(ii,:),'EdgeColor','none')
    set(H(ii).semPtch,'FaceColor',clrMap(ii,:)*0.1,'EdgeColor','none')
    set(H(ii).mu,'Color',[0.8 0.2 0])
end

xticklabels({'before','after GRE','after SPE','after EPI','after GRE-SPE','after GRE-EPI'})
title('BBR cost function values - func2struct')
ylim([0 0.5])
set(gca,'FontSize',16)

%% TR2500 CorrRatio

idx1=strcmp(DTable_BBR.taskName,'TASK-AA-2500') | strcmp(DTable_BBR.taskName,'TASK-UA-2500');

figure('position',[100 100 1000 500])
H = notBoxPlot(M_CorrRatio(idx1,:));

for ii = 1:6
    set(H(ii).data,'Marker','.','MarkerSize',6)
    set(H(ii).sdPtch,'FaceColor',clrMap(ii,:),'EdgeColor','none')
    set(H(ii).semPtch,'FaceColor',clrMap(ii,:)*0.1,'EdgeColor','none')
    set(H(ii).mu,'Color',[0.8 0.2 0])
end

xticklabels({'before','after GRE','after SPE','after EPI','after GRE-SPE','after GRE-EPI'})
title('BBR cost function values - func2struct')
ylim([0 0.5])
set(gca,'FontSize',16)


%% Statistical

[~,~,stats] = anova1(M);

[c,~,~,gnames] = multcompare(stats);
