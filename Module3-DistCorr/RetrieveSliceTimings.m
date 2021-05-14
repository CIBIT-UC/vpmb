DATADIR='/DATAPOOL/VPMB/VPMB-STCIBIT-V2'; % data folder
VPDIR='/SCRATCH/users/alexandresayal/VPMB'; % processing folder
subID='VPMBAUS01';                                           % subject ID
taskName='TASK-LOC-1000';                                    % task name

taskDir=fullfile(VPDIR,subID,'ANALYSIS',taskName);            % task directory
fmapDir=fullfile(VPDIR,subID,'ANALYSIS',taskName,'FMAP-NONE');   % fmap directory
WD=fullfile(fmapDir,'work');   % working directory
t1Dir='${VPDIR}/${subID}/ANALYSIS/T1W';                      % T1w directory



% Load .json file

% Extract slice timing

% Find maximum and divide by two

% Subtract to timings

% Export .txt