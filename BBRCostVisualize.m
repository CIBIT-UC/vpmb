%% Import data

DTable = importBBRfile('BBR_CostValues_func2struct.txt');

M = [DTable.costBefore DTable.costAfterGRE DTable.costAfterSPE DTable.costAfterEPI];

%% Not Box plot
clrMap = lines;
figure
H = notBoxPlot(M);

for ii = 1:4
    set(H(ii).data,'Marker','.','MarkerSize',6)
    set(H(ii).sdPtch,'FaceColor',clrMap(ii,:),'EdgeColor','none')
    set(H(ii).semPtch,'FaceColor',clrMap(ii,:)*0.1,'EdgeColor','none')
    set(H(ii).mu,'Color',[0.8 0.2 0])
end

xticklabels({'before','after GRE','after SPE','after EPI'})
title('BBR cost function values - func2struct')
ylim([0.2 0.8])
set(gca,'FontSize',16)

%% Statistical

[~,~,stats] = anova1(M);

[c,~,~,gnames] = multcompare(stats);
