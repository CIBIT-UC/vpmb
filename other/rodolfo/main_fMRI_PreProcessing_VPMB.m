% % run bet on anatomical images with ANTs
% par = 0; repeat = 0;
% BET_VPMB(par, repeat);
% 
% % run distortion correction with FMAP-GRE
% par = 1; repeat = [ 0 0 0 ];
% FMAP_GRE_VPMB(par, repeat);
% 
% % run distortion correction with FEAT using TOPUP-derived FMAPs
% par = 0; repeat = 0;
% FMAP_GREfromTOPUP_VPMB(par, repeat);
% 
% % invert MPRAGE to be "T2w"
% par = 1; repeat = [ 0 0 ];
% invert_struct_VPMB(par, repeat);
% 
% % run non-linear registration to inverted T1w
% par = 1; repeat = [ 0 0 0 ];
% nonlinear_reg_VPMB(par, repeat);

% run rigid+affine+non-linear registration to inverted T1w
par = 0; repeat = [ 0 1 0 ];
nonlinear_reg_VPMB_v3(par, repeat);