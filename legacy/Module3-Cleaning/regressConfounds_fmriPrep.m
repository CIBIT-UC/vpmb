function regressConfounds_fmriPrep(taskName,spaces,fmriPrepFolder,outputFolder,subjectID)
%REGRESSCONFOUNDS regress physiological regressors out of fMRI data
%

fprintf('[regressConfounds_fmriPrep] Started for run %s.\n',taskName)

warning off;

for sp = 1:length(spaces)
    
    % input nii image
    funcImage = fullfile(fmriPrepFolder,subjectID,'func',[subjectID '_' taskName '_space-' spaces{sp} '_desc-preproc_bold.nii.gz']);
    
    % output nii image
    funcImageClean = fullfile(outputFolder,[subjectID '_' taskName '_space-' spaces{sp} '_desc-pnm_bold.nii.gz']);
    
    % brain mask file
    brainMaskFile = fullfile(fmriPrepFolder,subjectID,'func',[subjectID '_' taskName '_space-' spaces{sp} '_desc-brain_mask.nii.gz']);
    betImage = fullfile(outputFolder,[subjectID '_' taskName '_space-' spaces{sp} '_desc-betfunc.nii.gz']);
    
    cmd = sprintf('fslmaths %s -mas %s %s', funcImage, brainMaskFile, betImage); system(cmd);
    %clear cmd;
    
    % compute mean func
    meanfuncImage = fullfile(outputFolder,[subjectID '_' taskName '_space-' spaces{sp} '_desc-meanfunc.nii.gz']);
    cmd = sprintf('fslmaths %s -Tmean %s', betImage, meanfuncImage); system(cmd);
    %clear cmd;
    
    % load fMRI
    fmri_struct = load_untouch_nii(betImage);
    fMRI = fmri_struct.img; dim = size(fMRI);
    fmri_struct_copy = fmri_struct;
    %clear fmri_struct;
    
    % name of pnm file
    matrixFile = fullfile(outputFolder,[subjectID '_' taskName '_desc-PNMmodel.mat']);
    
    % vectorize fMRI
    vec_fMRI = reshape(fMRI, [ dim(1)*dim(2)*dim(3), dim(4) ])';
    A = find(all(vec_fMRI, 1));
    vec_fMRI = vec_fMRI(:, A);
    res_fMRI = zeros(dim(4), dim(1)*dim(2)*dim(3));
    
    % load PNM
    aux = load(matrixFile); CONFMATRIX = aux.CONFMATRIX;
    %clear aux; % CONFMATRIX variable
    
    % Remove NaNs from CONFMATRIX
    CONFMATRIX(isnan(CONFMATRIX)) = 0;
    
    % compute the residuals of the PNM model
    [ ~, ~, res ] = arrayfun(@(x) regress(vec_fMRI(:, x), CONFMATRIX), 1:length(A), 'uniformoutput', 0);
    for i = 1:length(A)
        res_fMRI(:, A(i)) = res{i};
    end
    %clear res;
    
    % store PNM-corrected data
    res_4D_fMRI = reshape(res_fMRI', [ dim(1) dim(2) dim(3) dim(4) ]);
    
    %clear res_fMRI;
    
    fmri_struct_copy.img = single(res_4D_fMRI);
    demeanImage = fullfile(outputFolder,[subjectID '_' taskName '_space-' spaces{sp} '_desc-demean.nii.gz']);
    save_untouch_nii(fmri_struct_copy, demeanImage);
    
    %clear res_4D_fMRI;
    
    % add mean_func to PNM-corrected fMRI data
    cmd = sprintf('fslmaths %s -add %s %s', demeanImage, meanfuncImage, funcImageClean); system(cmd);
    %clear cmd;
    
    % delete demeaned and mean images
    delete(betImage);
    delete(demeanImage);
    delete(meanfuncImage);
    
end

fprintf('[regressConfounds_fmriPrep] Finished for run %s.\n',taskName)
