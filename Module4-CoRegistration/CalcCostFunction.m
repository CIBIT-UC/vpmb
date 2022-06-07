clc, clear

%% Folders
sdcMethod = 'NLREG';
bidsFolder = ['/DATAPOOL/VPMB/BIDS-VPMB-' sdcMethod];
workFolder = ['/DATAPOOL/VPMB/fmriprep-work_VPMB-' sdcMethod '/fmriprep_wf'];

%% Subject List
aux = dir(fullfile(bidsFolder,'sub-*'));
subjectList = extractfield(aux,'name');
nSubjects = length(subjectList);
clear aux

%% Task List
aux = dir(fullfile(bidsFolder,'sub-01','func','*_task-*_bold.json'));
taskList = extractfield(aux,'name');
taskList = cellfun(@(x) x(8:end-16), taskList, 'un', 0)'; % remove trailing and leading info
nTasks = length(taskList);
clear aux

%% Output matrices
COST = struct();

COST.sdcMethod = sdcMethod;
COST.subjectList = subjectList;
COST.taskList = taskList;
COST.sbref = false(nSubjects,nTasks);
COST.corrratio.data = zeros(nSubjects,nTasks);
COST.normmi.data = zeros(nSubjects,nTasks);
COST.bbr.data = zeros(nSubjects,nTasks);

%% Iterate (this takes some time, option to load below)

% Iterate on the subjects
for ss = 1:nSubjects

    % subject name
    subjectID = subjectList{ss};
    
    % Iterate on the runs
    for tt = 1:nTasks
        
        % task name
        taskName = taskList{tt};
        
        % working folder
        subtaskWFolder = fullfile(workFolder,...
            ['single_subject_' subjectID(5:end) '_wf'],...
            ['func_preproc_' strrep(taskName,'-','_') '_run_1_wf']);
        
        %% func image after SDC        
        % we need this dir here because fmriprep will generate different
        % filenames according to the sdcMethod and the existence of an
        % SBRef image
        d = dir(fullfile(subtaskWFolder,...
            'final_boldref_wf/enhance_and_skullstrip_bold_wf/n4_correct/vol*.nii*'));
        
        if length(d) == 1
            funcImage = fullfile(d(1).folder,d(1).name);
            clear d
        else
           error('more than one image here OR no image') 
        end

        %% T1w image
        refImage = fullfile(subtaskWFolder,...
            ['t1w_brain/' subjectID '_run-1_T1w_corrected_xform_masked.nii.gz']);
        
        %% Estimated transformation matrix (BBR, 6 DoF)
        % we need this dir here because fmriprep will generate different
        % filenames according to the sdcMethod and the existence of an
        % SBRef image
        d = dir(fullfile(subtaskWFolder,...
            '/bold_reg_wf/fsl_bbr_wf/flt_bbr/vol*.mat'));
        
        if length(d) == 1
            affineMatrix = fullfile(d(1).folder,d(1).name);
            clear d
        else
           error('more than one image there OR no image') 
        end
                
        %% Estimate cost function 1 - correlation ratio
        cmd = sprintf("flirt -in %s -ref %s -schedule $FSLDIR/etc/flirtsch/measurecost1.sch -init %s -cost corratio | head -1 | cut -f1 -d' '",...
            funcImage,...
            refImage,...
            affineMatrix);
        
        [~,result1] = system(cmd);

        COST.corrratio.data(ss,tt) = str2num(result1);
        
        %% Estimate cost function 2 - normalized mutual information
        cmd = sprintf("flirt -in %s -ref %s -schedule $FSLDIR/etc/flirtsch/measurecost1.sch -init %s -cost normmi | head -1 | cut -f1 -d' '",...
            funcImage,...
            refImage,...
            affineMatrix);
        
        [~,result2] = system(cmd);
        
        COST.normmi.data(ss,tt) = str2num(result2);
        
        %% Estimate cost function 3 - bbr
        cmd = sprintf("flirt -in %s -ref %s -schedule $FSLDIR/etc/flirtsch/measurecost1.sch -init %s -cost bbr -wmseg %s | head -1 | cut -f1 -d' '",...
            funcImage,...
            refImage,...
            affineMatrix,...
            fullfile(subtaskWFolder,['bold_reg_wf/fsl_bbr_wf/wm_mask/' subjectID '_run-1_T1w_corrected_xform_masked_pveseg_dseg_mask.nii.gz']));
        
        [~,result3] = system(cmd);
        
        COST.bbr.data(ss,tt) = str2num(result3);
        
    end
        
    fprintf('Subject %s done.\n',subjectList{ss})
end
    
%% Save COST
save(['CostFunctionData_' sdcMethod '.mat'],'COST','workFolder','bidsFolder')

%% stats Correlation Ratio

% global mean
COST.corrratio.globalmean = mean(nanmean(COST.corrratio.data));

% reshape per TR
COST.corrratio.reshape0500 = reshape(COST.corrratio.data(:,[1 5]),nSubjects*2,1);
COST.corrratio.reshape0750 = reshape(COST.corrratio.data(:,[2 6]),nSubjects*2,1);
COST.corrratio.reshape1000 = reshape(COST.corrratio.data(:,[3 7 9]),nSubjects*3,1);
COST.corrratio.reshape2500 = reshape(COST.corrratio.data(:,[4 8]),nSubjects*2,1);

% mean per TR
COST.corrratio.mean0500 = nanmean(COST.corrratio.reshape0500);
COST.corrratio.mean0750 = nanmean(COST.corrratio.reshape0750);
COST.corrratio.mean1000 = nanmean(COST.corrratio.reshape1000);
COST.corrratio.mean2500 = nanmean(COST.corrratio.reshape2500);

% std per TR
COST.corrratio.std0500 = nanstd(COST.corrratio.reshape0500);
COST.corrratio.std0750 = nanstd(COST.corrratio.reshape0750);
COST.corrratio.std1000 = nanstd(COST.corrratio.reshape1000);
COST.corrratio.std2500 = nanstd(COST.corrratio.reshape2500);

%% stats Normalized MI

% global mean
COST.normmi.globalmean = mean(nanmean(COST.normmi.data));

% reshape per TR
COST.normmi.reshape0500 = reshape(COST.normmi.data(:,[1 5]),nSubjects*2,1);
COST.normmi.reshape0750 = reshape(COST.normmi.data(:,[2 6]),nSubjects*2,1);
COST.normmi.reshape1000 = reshape(COST.normmi.data(:,[3 7 9]),nSubjects*3,1);
COST.normmi.reshape2500 = reshape(COST.normmi.data(:,[4 8]),nSubjects*2,1);

% mean per TR
COST.normmi.mean0500 = nanmean(COST.normmi.reshape0500);
COST.normmi.mean0750 = nanmean(COST.normmi.reshape0750);
COST.normmi.mean1000 = nanmean(COST.normmi.reshape1000);
COST.normmi.mean2500 = nanmean(COST.normmi.reshape2500);

% std per TR
COST.normmi.std0500 = nanstd(COST.normmi.reshape0500);
COST.normmi.std0750 = nanstd(COST.normmi.reshape0750);
COST.normmi.std1000 = nanstd(COST.normmi.reshape1000);
COST.normmi.std2500 = nanstd(COST.normmi.reshape2500);

%% stats BBR

% global mean
COST.bbr.globalmean = mean(nanmean(COST.bbr.data));

% reshape per TR
COST.bbr.reshape0500 = reshape(COST.bbr.data(:,[1 5]),nSubjects*2,1);
COST.bbr.reshape0750 = reshape(COST.bbr.data(:,[2 6]),nSubjects*2,1);
COST.bbr.reshape1000 = reshape(COST.bbr.data(:,[3 7 9]),nSubjects*3,1);
COST.bbr.reshape2500 = reshape(COST.bbr.data(:,[4 8]),nSubjects*2,1);

% mean per TR
COST.bbr.mean0500 = nanmean(COST.bbr.reshape0500);
COST.bbr.mean0750 = nanmean(COST.bbr.reshape0750);
COST.bbr.mean1000 = nanmean(COST.bbr.reshape1000);
COST.bbr.mean2500 = nanmean(COST.bbr.reshape2500);

% std per TR
COST.bbr.std0500 = nanstd(COST.bbr.reshape0500);
COST.bbr.std0750 = nanstd(COST.bbr.reshape0750);
COST.bbr.std1000 = nanstd(COST.bbr.reshape1000);
COST.bbr.std2500 = nanstd(COST.bbr.reshape2500);

%% Save COST
save(['CostFunctionData_' sdcMethod '.mat'],'COST','workFolder','bidsFolder')

%% plots

figure

subplot(1,3,1)
hold on
notBoxPlot([COST.corrratio.reshape0500,COST.corrratio.reshape0750,COST.corrratio.reshape2500],[1 2 4],'sdPatchColor',[0.4 0.4 0.8],'semPatchColor',[0.4 0.3 0.7])
notBoxPlot(COST.corrratio.reshape1000,3,'sdPatchColor',[0.4 0.4 0.8],'semPatchColor',[0.4 0.3 0.7])
%ylim([0 0.3])
xticks(1:4)
xticklabels({'TR0500','TR0750','TR1000','TR2500'})
title('Correlation ratio - NLREG')

subplot(1,3,2)
hold on
notBoxPlot([COST.normmi.reshape0500,COST.normmi.reshape0750,COST.normmi.reshape2500],[1 2 4],'sdPatchColor',[0.4 0.4 0.8],'semPatchColor',[0.4 0.3 0.7])
notBoxPlot(COST.normmi.reshape1000,3,'sdPatchColor',[0.4 0.4 0.8],'semPatchColor',[0.4 0.3 0.7])
%ylim([-1.3 -1.2])
xticks(1:4)
xticklabels({'TR0500','TR0750','TR1000','TR2500'})
title('Normalized mutual information - NLREG')

subplot(1,3,3)
hold on
notBoxPlot([COST.bbr.reshape0500,COST.bbr.reshape0750,COST.bbr.reshape2500],[1 2 4],'sdPatchColor',[0.4 0.4 0.8],'semPatchColor',[0.4 0.3 0.7])
notBoxPlot(COST.bbr.reshape1000,3,'sdPatchColor',[0.4 0.4 0.8],'semPatchColor',[0.4 0.3 0.7])
%ylim([0.25 0.75])
xticks(1:4)
xticklabels({'TR0500','TR0750','TR1000','TR2500'})
title('BBR - NLREG')

%% plots with subjects color coded

figure

subplot(1,3,1)
hold on
notBoxPlot([COST.corrratio.reshape0500,COST.corrratio.reshape0750,COST.corrratio.reshape2500],[1 2 4],'subColors',true,'nSubjects',nSubjects,'sdPatchColor',[0.4 0.4 0.8],'semPatchColor',[0.4 0.3 0.7])
notBoxPlot(COST.corrratio.reshape1000,3,'subColors',true,'nSubjects',nSubjects,'sdPatchColor',[0.4 0.4 0.8],'semPatchColor',[0.4 0.3 0.7])
%ylim([0 0.3])
xticks(1:4)
xticklabels({'TR0500','TR0750','TR1000','TR2500'})
title('Correlation ratio - NLREG')

subplot(1,3,2)
hold on
notBoxPlot([COST.normmi.reshape0500,COST.normmi.reshape0750,COST.normmi.reshape2500],[1 2 4],'subColors',true,'nSubjects',nSubjects,'sdPatchColor',[0.4 0.4 0.8],'semPatchColor',[0.4 0.3 0.7])
notBoxPlot(COST.normmi.reshape1000,3,'subColors',true,'nSubjects',nSubjects,'sdPatchColor',[0.4 0.4 0.8],'semPatchColor',[0.4 0.3 0.7])
%ylim([-1.3 -1.2])
xticks(1:4)
xticklabels({'TR0500','TR0750','TR1000','TR2500'})
title('Normalized mutual information - NLREG')

subplot(1,3,3)
hold on
notBoxPlot([COST.bbr.reshape0500,COST.bbr.reshape0750,COST.bbr.reshape2500],[1 2 4],'subColors',true,'nSubjects',nSubjects,'sdPatchColor',[0.4 0.4 0.8],'semPatchColor',[0.4 0.3 0.7])
notBoxPlot(COST.bbr.reshape1000,3,'subColors',true,'nSubjects',nSubjects,'sdPatchColor',[0.4 0.4 0.8],'semPatchColor',[0.4 0.3 0.7])
%ylim([0.25 0.75])
xticks(1:4)
xticklabels({'TR0500','TR0750','TR1000','TR2500'})
title('BBR - NLREG')
