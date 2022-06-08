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






