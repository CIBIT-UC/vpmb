function plot_avg_fmaps_BM()

p = '/DATAPOOL/BIOMOTION/'; gp = [ p, 'GROUP_RESULTS/fmaps/' ];

% correction methods
CORR = { 'topup'; 'gfm' }; nC = length(CORR);

% load MNI1mm
mni = load_untouch_nii([ p, 'MNI1mm_brain.nii.gz' ]); mni = mni.img;

mni1mm_mask = '/SCRATCH/software/fsl/data/standard/MNI152_T1_1mm_brain_mask.nii.gz';
mask = load_untouch_nii(mni1mm_mask); mni_mask = nan(size(mask.img)); mni_mask(logical(mask.img)) = 1;

% slices to display
sx = 91; sz = [ 46 67 ];

nrow = 1; ncol = 3 * nC;
figure('Color', 'Black'); [ha, pos] = tight_subplot(nrow, ncol, [0 0], [0 0], [.01 .01]);

for c = 1:nC
        
    % load map
    map = load_untouch_nii([ gp, CORR{c}, '_gavg_vsm2std_1mm.nii.gz' ]); map = map.img .* mni_mask;
    H(:, c) = map(~isnan(map)); % histogram
    lim = max([ abs(min(map(:))) max(map(:)) ]); fLim = [ -lim lim ];
    
    % get slices to plot
    mni_x = rot90(squeeze(mni(sx, :, :))); mni_z1 = rot90(squeeze(mni(:, :, sz(1)))); mni_z2 = rot90(squeeze(mni(:, :, sz(2))));
    map_x = rot90(squeeze(map(sx, :, :))); map_z1 = rot90(squeeze(map(:, :, sz(1)))); map_z2 = rot90(squeeze(map(:, :, sz(2))));
    
    % saggital (x) slice
    idX = ((c-1)*3)+1; axes(ha(idX));
    hB = imagesc(mni_x); colormap('gray'); axis image off;
    freezeColors;
    
    hold on; climF = fLim; hF = imagesc(map_x, climF);
    colormap('jet'); freezeColors;
    
    % 1st axial (x) slice
    idZ1 = ((c-1)*3)+2; axes(ha(idZ1));
    hB = imagesc(mni_z1); colormap('gray'); axis image off;
    freezeColors;
    
    hold on; climF = fLim; hF = imagesc(map_z1, climF);
    colormap('jet'); freezeColors;
    
    % 2nd axial (x) slice
    idZ2 = ((c-1)*3)+3; axes(ha(idZ2));
    hB = imagesc(mni_z2); colormap('gray'); axis image off;
    freezeColors;
    
    hold on; climF = fLim; hF = imagesc(map_z2, climF);
    colormap('jet'); freezeColors;
    
%     % histogram
%     idH = [ ((c-1)*3)+7:((c-1)*3)+9 ]; axes(ha(idH));
%     histogram(H, 100); xlim([ -lim lim ]);
end

fign = [ gp, 'vsm_topup_gfm.fig' ];
set(gcf, 'Position', [ 2 383 1914 375 ]); saveas(gcf, fign, 'fig');

% plot histograms
H = H .* 2.5; % multiply by voxel size

save([ gp, 'topup_gfm_hist.mat' ], 'H');

for c = 1:nC
    figure; histogram(H(:, c), 100); xlim([ min(H(:, c)) max(H(:, c)) ]);
    set(gca, 'box', 'off'); xlabel('Voxel displacement [mm]');
end


