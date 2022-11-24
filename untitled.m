clear,clc

%% data input

subjectList = {'VPMBAUS01';'VPMBAUS02';'VPMBAUS03';'VPMBAUS05';'VPMBAUS06';'VPMBAUS07';'VPMBAUS08';'VPMBAUS10';'VPMBAUS11';'VPMBAUS12';'VPMBAUS15';'VPMBAUS16';'VPMBAUS21';'VPMBAUS22';'VPMBAUS23'};
subjectNumberList = {'01';'02';'03';'05';'06';'07';'08';'10';'11';'12';'15';'16';'21';'22';'23'};

runList = {'AA','UA'};
trList = {'0500','0750','1000','2500'};
trValues = [0.5, 0.75, 1, 2.5];

nSubjects = length(subjectList);
[combSub,combTR,combRun] = meshgrid(1:nSubjects,1:4,1:2);
nCombs = length(subjectList)*4*2;

%% Iterate

for cc = 1:nCombsg