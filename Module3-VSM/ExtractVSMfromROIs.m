clear, clc

%% Settings
vsmFolder = '/DATAPOOL/VPMB/VPMB-BIDS-NLREG/derivatives/vsm/group';
roiFolder = '/DATAPOOL/VPMB/ROIsforSDC';

acqList = {'all','0500','0750','1000','2500'};
nTRs = length(acqList);

roiList = {'aIns_LR_brainnetome' 'Ca_LR_CIT168' 'hMT_LR_brainnetome' 'hMT_LR_glasser' 'MPFC_LR_brainnetome' 'MPFC_LR_glasser' 'NAc_LR_brainnetome' 'NAc_LR_CIT168' 'SubCC_LR_glasser' 'V1_LR_glasser'};
nROIs = length(roiList);

nSubjects = 15;

outputMatrix = zeros(nROIs,nTRs,nSubjects);

%% Iterate

% on the rois

for rr = 1:nROIs
    
    if ~exist(fullfile(roiFolder,[roiList{rr} '_space-VSM']),'file')
        
        % Resample roi mask to VSM resolution
        cmd = sprintf('flirt -in %s -ref %s -applyxfm -usesqform -out %s',...
            fullfile(roiFolder,[roiList{rr} '.nii.gz']),...
            fullfile(vsmFolder,'sub-all_task-all_acq-all_space-MNI_warp_brain_mean.nii.gz'),...
            fullfile(roiFolder,[roiList{rr} '_space-VSM']) );

        system(cmd);

        cmd = sprintf('fslmaths %s -thr 0.5 -bin %s',...
            fullfile(roiFolder,[roiList{rr} '_space-VSM']),...
            fullfile(roiFolder,[roiList{rr} '_space-VSM']) );

        system(cmd);
        
    end
    
    % Iterate on the TRs
    for tt = 1:nTRs
        
        cmd = sprintf('fslmeants -i %s -m %s',...
            fullfile(vsmFolder,['sub-all_task-all_acq-' acqList{tt} '_space-MNI_warp_brain_merge']),...
            fullfile(roiFolder,[roiList{rr} '_space-VSM']) );  
        
        [~,result] = system(cmd);
        
        outputMatrix(rr,tt,:) = str2num(result);
        
    end
     
end

%% Export results
save('VSMfromROI-NLREG-OutputMatrix.m')

%% Stats

averageSubs = mean(outputMatrix,3);

% display table
array2table(averageSubs,'RowNames',roiList,'VariableNames',acqList)

%% notBoxPlot per ROI
figure

for rr = 1:nROIs
    
    subplot(2,5,rr)
    
    hold on
    notBoxPlot(squeeze(outputMatrix(rr,2:end,:))','sdPatchColor',[0.4 0.4 0.8],'semPatchColor',[0.4 0.3 0.7])
    line([0 5],[0 0],'linestyle',':')
    hold off
    
    title(roiList{rr}, 'Interpreter', 'none')
    
    ylim([-3 8])
    ylabel('voxel displacement')
    xlabel('TR (ms)')
    xticklabels(acqList(2:end))
    
end



