clc, clear

%% Folders
bidsFolder='/DATAPOOL/VPMB/VPMB-BIDS-NLREG';
workFolder='/DATAPOOL/VPMB/VPMB-BIDS-NLREG-work/fmriprep_wf';

%% Subject List
aux = dir(fullfile(bidsFolder,'sub-*'));
subjectList = extractfield(aux,'name');
clear aux

%% Task List
aux = dir(fullfile(bidsFolder,'sub-01','func','*_task-*.json'));
taskList = extractfield(aux,'name');

taskList = cellfun(@(x) x(8:end-17), taskList, 'un', 0); % remove trailing and leading info

%%

subjectID = subjectList{1};

taskName = taskList{1};

subtaskWFolder = fullfile(workFolder,...
        ['single_subject_' subjectID(5:end) '_wf'],...
        ['func_preproc_' strrep(taskName,'-','_') '_run_01_wf']);
 
funcImage = fullfile(subtaskWFolder,...
    'sdc_estimate_wf/syn_sdc_wf/skullstrip_bold_wf/apply_mask/ref_bold_corrected_trans_masked.nii.gz');

refImage = fullfile(subtaskWFolder,...
    't1w_brain/sub-01_run-01_T1w_corrected_xform_masked.nii.gz');

affineMatrix = fullfile(subtaskWFolder,...
    '/bold_reg_wf/fsl_bbr_wf/flt_bbr/ref_bold_corrected_trans_masked_flirt.mat');


cmd = sprintf("flirt -in %s -ref %s -schedule $FSLDIR/etc/flirtsch/measurecost1.sch -init %s -cost corratio | head -1 | cut -f1 -d' '",...
    funcImage,...
    refImage,...
    affineMatrix);

[~,result] = system(cmd)

cmd = sprintf("flirt -in %s -ref %s -schedule $FSLDIR/etc/flirtsch/measurecost1.sch -init %s -cost normmi | head -1 | cut -f1 -d' '",...
    funcImage,...
    refImage,...
    affineMatrix);

[~,result] = system(cmd)







