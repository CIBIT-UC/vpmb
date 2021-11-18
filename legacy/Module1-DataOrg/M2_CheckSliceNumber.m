% ----------------------------------------------------------------------- %
% ----------------------------------------------------------------------- %
% MODULE 1 - Data managment
% Script Name: M2_CheckSliceNumber.m
%
% Intended for removing some extra slices from the data (inconsistent
% protocols).
%
% Author: Alexandre Sayal, PhD student
% Coimbra Institute for Biomedical Imaging and Translational Research
% Email address: alexandresayal@gmail.com
% December 2020; Last revision: 05-Apr-2021
% ----------------------------------------------------------------------- %

%% Start clean
clear,clc,close all

%% Settings
stcibitFolder = fullfile('/media','alexandresayal','DATA4TB','VPMB-STCIBIT');

%% Retrive subject list
D = dir(fullfile(stcibitFolder,'VPMBAUS*'));
subjectList = extractfield(D,'name')';

%% Open figure
figure('Name','Images to evalute','Position',[150 150 2000 1000])

%% Iterate
for ss = 1:length(subjectList)
    
    fprintf('[%s] Subject %s...\n',datestr(now),subjectList{ss})
    
    % FMAP image
    F1 = niftiread(fullfile(stcibitFolder,subjectList{ss},...
        'RAW','TASK-AA-0750',...
        [subjectList{ss} '_FMAP-SPE-AP.nii.gz']));
    
    S = size(F1);
    
    if S(3) == 42 % This means two slices must be excluded
        
        % Functional image
        F2 = niftiread(fullfile(stcibitFolder,subjectList{ss},...
            'RAW','TASK-AA-0750',...
            [subjectList{ss} '_TASK-AA-0750.nii.gz']));
        
        Sh = round(S./2);
        
        % Display images to make informed decision        
        subplot(1,2,1)
        imshow(squeeze(F1(Sh(1),:,end:-1:1))','InitialMagnification','fit')
        title('FMAP')
        
        subplot(1,2,2)
        imshow(squeeze(F2(Sh(1),:,end:-1:1,1))','InitialMagnification','fit')
        title('FUNC')
        
        % Ask answer from user
        I = 0;
        while ~ any(I == [1,2,3])
            I = input('Trim options:\n 1) 2 slices above \n 2) 1 below 1 above \n 3) 2 slices below \n Answer: ');
        end
        
        % List files to trim and replace
        nf1 = fullfile(stcibitFolder,subjectList{ss},'RAW','TASK-AA-0750',[subjectList{ss} '_FMAP-SPE-AP.nii.gz']);
        nf2 = fullfile(stcibitFolder,subjectList{ss},'RAW','TASK-AA-0750',[subjectList{ss} '_FMAP-SPE-PA.nii.gz']);
        nf3 = fullfile(stcibitFolder,subjectList{ss},'RAW','TASK-UA-0750',[subjectList{ss} '_FMAP-SPE-AP.nii.gz']);
        nf4 = fullfile(stcibitFolder,subjectList{ss},'RAW','TASK-UA-0750',[subjectList{ss} '_FMAP-SPE-PA.nii.gz']);
        
        % Execute
        system(sprintf('fslroi %s %s 0 -1 0 -1 %i 40',...
            nf1,nf1,I-1));
        system(sprintf('fslroi %s %s 0 -1 0 -1 %i 40',...
            nf2,nf2,I-1));
        system(sprintf('fslroi %s %s 0 -1 0 -1 %i 40',...
            nf3,nf3,I-1));
        system(sprintf('fslroi %s %s 0 -1 0 -1 %i 40',...
            nf4,nf4,I-1));
        
        fprintf('[%s] Trimmed.\n',datestr(now))

    else
        fprintf('[%s] All okay here.\n',datestr(now))
        
    end % end if
     
end % end subject iteration

%% Done
close all

fprintf('[%s] Done!\n',datestr(now))
