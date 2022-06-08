function createConfoundMatrix_fmriPrep(taskName,bidsFolder,fmriPrepFolder,outputFolder,subjectID)
%CREATECONFOUNDMATRIX Create a matrix with confounds to regress out from
%the signal
%

fprintf('[createConfoundMatrix_fmriPrep] Started for run %s.\n.',taskName)

% Select Confounds of interest
confoundNames = {'trans_x','trans_y','trans_z','rot_x','rot_y','rot_z'...
    'trans_x_derivative1','trans_y_derivative1','trans_z_derivative1',...
    'rot_x_derivative1','rot_y_derivative1','rot_z_derivative1','csf','white_matter'};

% Confounds file from fmriPrep
confoundFile = fullfile(fmriPrepFolder,subjectID,'func',...
    [subjectID '_' taskName '_desc-confounds_timeseries.tsv']);

% Load confounds from fmriPrep
TSVData = tdfread(confoundFile);
TSVHeader = fieldnames(TSVData);

% Select confounds
outlierIndexes = ~cellfun('isempty', regexp(TSVHeader, 'motion_outlier*'));
cosineIndexes = ~cellfun('isempty', regexp(TSVHeader, 'cosine*'));
allotherIndexes = ismember(TSVHeader,confoundNames);

TSVHeader = TSVHeader(outlierIndexes | cosineIndexes | allotherIndexes);

% Get number of volumes, slices, and TR
funcImage = fullfile(fmriPrepFolder,subjectID,'func',...
    [subjectID '_' taskName '_space-T1w_desc-preproc_bold.nii.gz']);

[~,nSlices]=system(sprintf("echo $(fslinfo %s | grep -m 1 dim3 | awk '{print $2}')",funcImage));
nSlices = str2double(nSlices);

[~,tr]=system(sprintf("echo $(fslinfo %s | grep -m 1 pixdim4 | awk '{print $2}')",funcImage));
tr = str2double(tr);

nVols = length(TSVData.trans_x);

% Sanity check for the number of motion outliers
outlierRatio = sum(outlierIndexes) / nVols;
if outlierRatio > 0.5
    ME = MException('VerifyOutliers:Ratio', ...
             '[createConfoundMatrix_fmriPrep] Ratio of motion outliers is greater than 50%.');
    throw(ME);
end

% PhysIO
PhysioRegressors = computePhysIO_fmriPrep(fullfile(bidsFolder,subjectID,'func'), subjectID, taskName, nSlices, nVols, tr);

% Init confound matrix
nColumns = 1 + length(TSVHeader) + size(PhysioRegressors,2);

CONFMATRIX = zeros(nVols,nColumns);
CONFMATRIX(:,1) = 1; % constant

for cc = 1:length(TSVHeader)
    
    if ischar(TSVData.(TSVHeader{cc})) % Stupid data format handling but it works (necessary because of tdfread behavior with NaNs)
        
        for nn = 1:nVols
            CONFMATRIX(nn,1+cc) = str2double(TSVData.(TSVHeader{cc})(nn,:));
        end
        
    else
        CONFMATRIX(:,1+cc) = TSVData.(TSVHeader{cc});
    end
end

CONFMATRIX(:,2+length(TSVHeader):end) = PhysioRegressors;

% Skip confounds which are always lower than 1e-4
if sum(all(abs(CONFMATRIX) < 1e-4))
    CONFMATRIX(:,all(abs(CONFMATRIX) < 1e-4)) = [];
    warning('[createConfoundMatrix_fmriPrep] Removed some confounds because of <1e-4')
end

%% Output

% export Physiological Noise Model (PNM)
outputFile = fullfile(outputFolder,[subjectID '_' taskName '_desc-PNMmodel.mat']);
save(outputFile, 'CONFMATRIX');


fprintf('[createConfoundMatrix_fmriPrep] Finished for run %s.\n',taskName)
