sdcMethods = {'EPI','GRE','NLREG','SPE','NONE'};

TRs = {'0500','0750','1000','2500'};

%% Load data

for ii = 1:length(sdcMethods)
   
    DATA.(sdcMethods{ii}) = load(['CostFunctionData_' sdcMethods{ii} '.mat'],'COST');
    
end

%% CORR RATIO

figure
suptitle('Co-registration comparison | Metric: Correlation ratio')

% TR 0500
subplot(2,2,1)

notBoxPlot([DATA.EPI.COST.corrratio.reshape0500,DATA.GRE.COST.corrratio.reshape0500,DATA.NLREG.COST.corrratio.reshape0500,DATA.SPE.COST.corrratio.reshape0500,DATA.NONE.COST.corrratio.reshape0500],1:5,'sdPatchColor',[0.4 0.4 0.8],'semPatchColor',[0.4 0.3 0.7])

title('TR = 0.5 s')
xticks(1:length(sdcMethods)), xticklabels(sdcMethods)
ylim([0 0.5]), ylabel('Correlation ratio')
set(gca,'FontSize',14)

% TR 0750
subplot(2,2,2)

notBoxPlot([DATA.EPI.COST.corrratio.reshape0750,DATA.GRE.COST.corrratio.reshape0750,DATA.NLREG.COST.corrratio.reshape0750,DATA.SPE.COST.corrratio.reshape0750,DATA.NONE.COST.corrratio.reshape0750],1:5,'sdPatchColor',[0.4 0.4 0.8],'semPatchColor',[0.4 0.3 0.7])

title('TR = 0.75 s')
xticks(1:length(sdcMethods)), xticklabels(sdcMethods)
ylim([0 0.5]), ylabel('Correlation ratio')
set(gca,'FontSize',14)

% TR 1000
subplot(2,2,3)

notBoxPlot([DATA.EPI.COST.corrratio.reshape1000,DATA.GRE.COST.corrratio.reshape1000,DATA.NLREG.COST.corrratio.reshape1000,DATA.SPE.COST.corrratio.reshape1000,DATA.NONE.COST.corrratio.reshape1000],1:5,'sdPatchColor',[0.4 0.4 0.8],'semPatchColor',[0.4 0.3 0.7])

title('TR = 1 s')
xticks(1:length(sdcMethods)), xticklabels(sdcMethods)
ylim([0 0.5]), ylabel('Correlation ratio')
set(gca,'FontSize',14)

% TR 2500
subplot(2,2,4)

notBoxPlot([DATA.EPI.COST.corrratio.reshape2500,DATA.GRE.COST.corrratio.reshape2500,DATA.NLREG.COST.corrratio.reshape2500,DATA.SPE.COST.corrratio.reshape2500,DATA.NONE.COST.corrratio.reshape2500],1:5,'sdPatchColor',[0.4 0.4 0.8],'semPatchColor',[0.4 0.3 0.7])

title('TR = 2.5 s')
xticks(1:length(sdcMethods)), xticklabels(sdcMethods)
ylim([0 0.5]), ylabel('Correlation ratio')
set(gca,'FontSize',14)

%% NORMALIZED MUTUAL INFORMATION

figure
suptitle('Co-registration comparison | Metric: Normalized mutual information')

% TR 0500
subplot(2,2,1)

notBoxPlot([DATA.EPI.COST.normmi.reshape0500,DATA.GRE.COST.normmi.reshape0500,DATA.NLREG.COST.normmi.reshape0500,DATA.SPE.COST.normmi.reshape0500,DATA.NONE.COST.normmi.reshape0500],1:5,'sdPatchColor',[0.4 0.4 0.8],'semPatchColor',[0.4 0.3 0.7])

title('TR = 0.5 s')
xticks(1:length(sdcMethods)), xticklabels(sdcMethods)
ylim([-1.25 -1.1]), ylabel('Normalized mutual information')
set(gca,'FontSize',14)

% TR 0750
subplot(2,2,2)

notBoxPlot([DATA.EPI.COST.normmi.reshape0750,DATA.GRE.COST.normmi.reshape0750,DATA.NLREG.COST.normmi.reshape0750,DATA.SPE.COST.normmi.reshape0750,DATA.NONE.COST.normmi.reshape0750],1:5,'sdPatchColor',[0.4 0.4 0.8],'semPatchColor',[0.4 0.3 0.7])

title('TR = 0.75 s')
xticks(1:length(sdcMethods)), xticklabels(sdcMethods)
ylim([-1.25 -1.1]), ylabel('Normalized mutual information')
set(gca,'FontSize',14)

% TR 1000
subplot(2,2,3)

notBoxPlot([DATA.EPI.COST.normmi.reshape1000,DATA.GRE.COST.normmi.reshape1000,DATA.NLREG.COST.normmi.reshape1000,DATA.SPE.COST.normmi.reshape1000,DATA.NONE.COST.normmi.reshape1000],1:5,'sdPatchColor',[0.4 0.4 0.8],'semPatchColor',[0.4 0.3 0.7])

title('TR = 1 s')
xticks(1:length(sdcMethods)), xticklabels(sdcMethods)
ylim([-1.25 -1.1]), ylabel('Normalized mutual information')
set(gca,'FontSize',14)

% TR 2500
subplot(2,2,4)

notBoxPlot([DATA.EPI.COST.normmi.reshape2500,DATA.GRE.COST.normmi.reshape2500,DATA.NLREG.COST.normmi.reshape2500,DATA.SPE.COST.normmi.reshape2500,DATA.NONE.COST.normmi.reshape2500],1:5,'sdPatchColor',[0.4 0.4 0.8],'semPatchColor',[0.4 0.3 0.7])

title('TR = 2.5 s')
xticks(1:length(sdcMethods)), xticklabels(sdcMethods)
ylim([-1.25 -1.1]), ylabel('Normalized mutual information')
set(gca,'FontSize',14)

%% BBR

figure
suptitle('Co-registration comparison | Metric: BBR cost function')

% TR 0500
subplot(2,2,1)

notBoxPlot([DATA.EPI.COST.bbr.reshape0500,DATA.GRE.COST.bbr.reshape0500,DATA.NLREG.COST.bbr.reshape0500,DATA.SPE.COST.bbr.reshape0500,DATA.NONE.COST.bbr.reshape0500],1:5,'sdPatchColor',[0.4 0.4 0.8],'semPatchColor',[0.4 0.3 0.7])

title('TR = 0.5 s')
xticks(1:length(sdcMethods)), xticklabels(sdcMethods)
ylim([0.25 0.85]), ylabel('BBR cost function')
set(gca,'FontSize',14)

% TR 0750
subplot(2,2,2)

notBoxPlot([DATA.EPI.COST.bbr.reshape0750,DATA.GRE.COST.bbr.reshape0750,DATA.NLREG.COST.bbr.reshape0750,DATA.SPE.COST.bbr.reshape0750,DATA.NONE.COST.bbr.reshape0750],1:5,'sdPatchColor',[0.4 0.4 0.8],'semPatchColor',[0.4 0.3 0.7])

title('TR = 0.75 s')
xticks(1:length(sdcMethods)), xticklabels(sdcMethods)
ylim([0.25 0.85]), ylabel('BBR cost function')
set(gca,'FontSize',14)

% TR 1000
subplot(2,2,3)

notBoxPlot([DATA.EPI.COST.bbr.reshape1000,DATA.GRE.COST.bbr.reshape1000,DATA.NLREG.COST.bbr.reshape1000,DATA.SPE.COST.bbr.reshape1000,DATA.NONE.COST.bbr.reshape1000],1:5,'sdPatchColor',[0.4 0.4 0.8],'semPatchColor',[0.4 0.3 0.7])

title('TR = 1 s')
xticks(1:length(sdcMethods)), xticklabels(sdcMethods)
ylim([0.25 0.85]), ylabel('BBR cost function')
set(gca,'FontSize',14)

% TR 2500
subplot(2,2,4)

notBoxPlot([DATA.EPI.COST.bbr.reshape2500,DATA.GRE.COST.bbr.reshape2500,DATA.NLREG.COST.bbr.reshape2500,DATA.SPE.COST.bbr.reshape2500,DATA.NONE.COST.bbr.reshape2500],1:5,'sdPatchColor',[0.4 0.4 0.8],'semPatchColor',[0.4 0.3 0.7])

title('TR = 2.5 s')
xticks(1:length(sdcMethods)), xticklabels(sdcMethods)
ylim([0.25 0.85]), ylabel('BBR cost function')
set(gca,'FontSize',14)


%% Data for notBoxPlot

DATAforPLOT = nan(45,20);

DATAforPLOT(1:30,1:5) = [DATA.EPI.COST.bbr.reshape0500,DATA.GRE.COST.bbr.reshape0500,DATA.NLREG.COST.bbr.reshape0500,DATA.SPE.COST.bbr.reshape0500,DATA.NONE.COST.bbr.reshape0500];
DATAforPLOT(1:30,6:10) = [DATA.EPI.COST.bbr.reshape0750,DATA.GRE.COST.bbr.reshape0750,DATA.NLREG.COST.bbr.reshape0750,DATA.SPE.COST.bbr.reshape0750,DATA.NONE.COST.bbr.reshape0750];
DATAforPLOT(1:45,11:15) = [DATA.EPI.COST.bbr.reshape1000,DATA.GRE.COST.bbr.reshape1000,DATA.NLREG.COST.bbr.reshape1000,DATA.SPE.COST.bbr.reshape1000,DATA.NONE.COST.bbr.reshape1000];
DATAforPLOT(1:30,16:20) = [DATA.EPI.COST.bbr.reshape2500,DATA.GRE.COST.bbr.reshape2500,DATA.NLREG.COST.bbr.reshape2500,DATA.SPE.COST.bbr.reshape2500,DATA.NONE.COST.bbr.reshape2500];



%%
figure('position',[10 10 550 950])
%suptitle('Co-registration comparison | Metric: BBR cost function')

% TR 0500
hold on

h1 = notBoxPlot(DATAforPLOT(:,1:5),...
    1:5,'sdPatchColor',[244 95 56]/255,'semPatchColor',[244 115 56]/255);

h2 = notBoxPlot(DATAforPLOT(:,6:10),...
    7:11,'sdPatchColor',[254 208 117]/255,'semPatchColor',[254 228 117]/255);

h3 = notBoxPlot(DATAforPLOT(:,11:15),...
   13:17,'sdPatchColor',[154 200 194]/255,'semPatchColor',[154 220 194]/255);

h4 = notBoxPlot(DATAforPLOT(:,16:20),...
    19:23,'sdPatchColor',[27 125 118]/255,'semPatchColor',[27 145 118]/255);

hold off

xlim([0,24])
xticks([1:5 7:11 13:17 19:23]), xticklabels(repmat(sdcMethods,1,4))
ylim([0.25 0.85]), ylabel('BBR cost function')
set(gca,'FontSize',14)
grid on, box on

patches = [h1.sdPtch h2.sdPtch h3.sdPtch h4.sdPtch];

legend(patches([1 5 11 20]),{'TR = 0.5 s','TR = 0.75 s','TR = 1 s', 'TR = 2.5 s'},'location','southeast')

camroll(-90)

%%
title('TR = 0.5 s')
xticks(1:length(sdcMethods)), xticklabels(sdcMethods)
ylim([0.25 0.85]), ylabel('BBR cost function')
set(gca,'FontSize',14)

%%
% TR 0750


notBoxPlot([],1:5,'sdPatchColor',[0.4 0.4 0.8],'semPatchColor',[0.4 0.3 0.7])

title('TR = 0.75 s')
xticks(1:length(sdcMethods)), xticklabels(sdcMethods)
ylim([0.25 0.85]), ylabel('BBR cost function')
set(gca,'FontSize',14)

% TR 1000


notBoxPlot([],1:5,'sdPatchColor',[0.4 0.4 0.8],'semPatchColor',[0.4 0.3 0.7])

title('TR = 1 s')
xticks(1:length(sdcMethods)), xticklabels(sdcMethods)
ylim([0.25 0.85]), ylabel('BBR cost function')
set(gca,'FontSize',14)

% TR 2500



title('TR = 2.5 s')
xticks(1:length(sdcMethods)), xticklabels(sdcMethods)
ylim([0.25 0.85]), ylabel('BBR cost function')
set(gca,'FontSize',14)


%% Two way ANOVA

% metric
metric = 'normmi';

% Prep data
sdcMethodLabel = reshape(repmat(sdcMethods,135,1),675,1);
TRLabel = repmat([repmat('0500',30,1) ; repmat('0750',30,1) ; repmat('1000',45,1) ; repmat('2500',30,1)],5,1);

DATAforANOVA = [DATA.EPI.COST.(metric).reshape0500;
                DATA.EPI.COST.(metric).reshape0750;
                DATA.EPI.COST.(metric).reshape1000;
                DATA.EPI.COST.(metric).reshape2500;

                DATA.GRE.COST.(metric).reshape0500;
                DATA.GRE.COST.(metric).reshape0750;
                DATA.GRE.COST.(metric).reshape1000;
                DATA.GRE.COST.(metric).reshape2500;

                DATA.NLREG.COST.(metric).reshape0500;
                DATA.NLREG.COST.(metric).reshape0750;
                DATA.NLREG.COST.(metric).reshape1000;
                DATA.NLREG.COST.(metric).reshape2500;

                DATA.SPE.COST.(metric).reshape0500;
                DATA.SPE.COST.(metric).reshape0750;
                DATA.SPE.COST.(metric).reshape1000;
                DATA.SPE.COST.(metric).reshape2500;

                DATA.NONE.COST.(metric).reshape0500;
                DATA.NONE.COST.(metric).reshape0750;
                DATA.NONE.COST.(metric).reshape1000;
                DATA.NONE.COST.(metric).reshape2500 ];

[p, ~, stats] = anovan(DATAforANOVA,{sdcMethodLabel TRLabel},'model',2,'varnames',{'sdcMethod','TR'});

[results,~,~,gnames] = multcompare(stats,"Dimension",[1 2]);


