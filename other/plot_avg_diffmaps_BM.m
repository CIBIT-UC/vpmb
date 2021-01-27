function plot_avg_diffmaps_BM()

p = '/DATAPOOL/BIOMOTION/'; gp = [ p, 'GROUP_RESULTS/fmaps/' ];

% correction methods
CORR = { 'topup'; 'gfm' }; nC = length(CORR);

% load MNI1mm
mni = load_untouch_nii([ p, 'MNI1mm_brain.nii.gz' ]); mni = mni.img;

mni1mm_mask = '/SCRATCH/software/fsl/data/standard/MNI152_T1_1mm_brain_mask.nii.gz';
mask = load_untouch_nii(mni1mm_mask); mni_mask = nan(size(mask.img)); mni_mask(logical(mask.img)) = 1;

% slices to display
sx = 91; sz = [ 46 67 ];

nrow = 3; ncol = 3 * nC;
figure('Color', 'Black'); [ha, pos] = tight_subplot(nrow, ncol, [0 0], [0 0], [.01 .01]);

for c = 1:nC
        
    % load distorted map
    map1 = load_untouch_nii([ gp, CORR{c}, '_gavg_diffAPPA_distorted2std.nii.gz' ]); map1 = map1.img .* mni_mask;
    fLim = [ min(map1(:)) max(map1(:)) ];
    
    % load corrected map
    map2 = load_untouch_nii([ gp, CORR{c}, '_gavg_diffAPPA_corrected2std.nii.gz' ]); map2 = map2.img .* mni_mask;
    
    % get slices to plot
    map1_x = rot90(squeeze(map1(sx, :, :))); map1_z1 = rot90(squeeze(map1(:, :, sz(1)))); map1_z2 = rot90(squeeze(map1(:, :, sz(2))));
    map2_x = rot90(squeeze(map2(sx, :, :))); map2_z1 = rot90(squeeze(map2(:, :, sz(1)))); map2_z2 = rot90(squeeze(map2(:, :, sz(2))));
    
    % map1 -> saggital (x) slice
    idX = ((c-1)*6)+1; axes(ha(idX)); imagesc(map1_x, fLim); axis image off;
    colormap('jet'); freezeColors;
    
    % map1 -> 1st axial (x) slice
    idZ1 = ((c-1)*+6)+2; axes(ha(idZ1)); imagesc(map1_z1, fLim); axis image off;
    colormap('jet'); freezeColors;
    
    % map1 -> 2nd axial (x) slice
    idZ2 = ((c-1)*6)+3; axes(ha(idZ2)); imagesc(map1_z2, fLim); axis image off; 
    colormap('jet'); freezeColors;
    
    % map2 -> saggital (x) slice
    idX = ((c-1)*6)+1+3; axes(ha(idX)); imagesc(map2_x, fLim); axis image off;
    colormap('jet'); freezeColors;
    
    % map2 -> 1st axial (x) slice
    idZ1 = ((c-1)*6)+2+3; axes(ha(idZ1)); imagesc(map2_z1, fLim); axis image off;
    colormap('jet'); freezeColors;
    
    % map2 -> 2nd axial (x) slice
    idZ2 = ((c-1)*6)+3+3; axes(ha(idZ2)); imagesc(map2_z2, fLim); axis image off; 
    colormap('jet'); freezeColors;
end

% AP and PA images
IMG = { 'PA'; 'AP' }; nC = length(IMG);

for c = 1:nC
        
    % load map
    map = load_untouch_nii([ gp, 'gavg_diff', IMG{c}, '_methods2std.nii.gz'  ]); map = map.img .* mni_mask;
    
    % get slices to plot
    map_x = rot90(squeeze(map(sx, :, :))); map_z1 = rot90(squeeze(map(:, :, sz(1)))); map_z2 = rot90(squeeze(map(:, :, sz(2))));
    
    % saggital (x) slice
    idX = ((c-1)*3)+1+12; axes(ha(idX)); imagesc(map_x, fLim); axis image off;
    colormap('jet'); freezeColors;
    
    % 1st axial (x) slice
    idZ1 = ((c-1)*3)+2+12; axes(ha(idZ1)); imagesc(map_z1, fLim); axis image off;
    colormap('jet'); freezeColors;
    
    % 2nd axial (x) slice
    idZ2 = ((c-1)*3)+3+12; axes(ha(idZ2)); imagesc(map_z2, fLim); axis image off; 
    colormap('jet'); freezeColors;
end

fign = [ gp, 'diffmaps_v2.fig' ];
set(gcf, 'Position', [ 2 383 1914 375 ]); saveas(gcf, fign, 'fig');



