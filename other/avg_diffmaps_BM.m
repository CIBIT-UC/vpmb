function avg_diffmaps_BM()

p = '/DATAPOOL/BIOMOTION/'; gp = [ p, 'GROUP_RESULTS/' ];
sub = dir([ p, 'P*_*' ]); nS = length(sub);

% possible runs
RUNS = { 'Localizer'; 'BioMotion_01'; 'BioMotion_02'; 'BioMotion_03'; 'BioMotion_04' };
nR = length(RUNS);

% correction methods
CORR = { 'topup'; 'gfm' }; nC = length(CORR);

% load MNI1mm and MNI4mm
mni_str = load_untouch_nii([ p, 'MNI1mm.nii.gz' ]); mni_str.hdr.dime.datatype = 16;

for c = 1:nC
    
    % allocate memory
    inDiff = nan([ size(mni_str.img), nR, nS ]); outDiff = nan([ size(mni_str.img), nR, nS ]);
    PADiff = nan([ size(mni_str.img), nR, nS ]); APDiff = nan([ size(mni_str.img), nR, nS ]);
    
    for s = 1:nS
        
        sd = [ p, sub(s).name, '/' ]; % subject dir
        ad = [ sd, 'MRI/Analysis/' ]; % analysis dir
        
        for r = 1:nR
            
            rd = [ ad, RUNS{r}, '/', CORR{c}, '/' ];
            
            % difference between distorted AP and PA images
            auxF = [ rd, 'diffAPPA_distorted2std.nii.gz' ];
            if exist(auxF)
                aux_nii = load_untouch_nii(auxF); inDiff(:, :, :, r, s) = aux_nii.img;
            end
            
            % difference between corected AP and PA images
            auxF = [ rd, 'diffAPPA_corrected2std.nii.gz' ];
            if exist(auxF)
                aux_nii = load_untouch_nii(auxF); outDiff(:, :, :, r, s) = aux_nii.img;
            end
            
            % difference between AP and PA images, within methods
            if c == 2 % difference maps are stored @ gfm folder
                
                % difference between corrected PA images
                auxF = [ rd, 'diffPA_methods2std.nii.gz' ];
                if exist(auxF)
                    aux_nii = load_untouch_nii(auxF); PADiff(:, :, :, r, s) = aux_nii.img;
                end
                
                % difference between corrected AP images
                auxF = [ rd, 'diffAP_methods2std.nii.gz' ];
                if exist(auxF)
                    aux_nii = load_untouch_nii(auxF); APDiff(:, :, :, r, s) = aux_nii.img;
                end
                
            end
        end
    end
    
    % average across subjects
    avg_inDiff = squeeze(nanmean(inDiff, 5)); avg_outDiff = squeeze(nanmean(outDiff, 5));
    
    if c == 2, avg_PADiff = squeeze(nanmean(PADiff, 5)); avg_APDiff = squeeze(nanmean(APDiff, 5)); end
    
    for r = 1:nR
        
        gd = [ gp, RUNS{r}, '/', CORR{c}, '/' ];        
        
        avg_inDiff_nii = [ gd, 'avg_diffAPPA_distorted2std.nii.gz' ];
        mni_str.img = squeeze(avg_inDiff(:, :, :, r)); save_untouch_nii(mni_str, avg_inDiff_nii);
        
        avg_outDiff_nii = [ gd, 'avg_diffAPPA_corrected2std.nii.gz' ];
        mni_str.img = squeeze(avg_outDiff(:, :, :, r)); save_untouch_nii(mni_str, avg_outDiff_nii);
        
        if c == 2
            avg_PADiff_nii = [ gd, 'avg_diffPA_methods2std.nii.gz' ];
            mni_str.img = squeeze(avg_PADiff(:, :, :, r)); save_untouch_nii(mni_str, avg_PADiff_nii);
            
            avg_APDiff_nii = [ gd, 'avg_diffAP_methods2std.nii.gz' ];
            mni_str.img = squeeze(avg_APDiff(:, :, :, r)); save_untouch_nii(mni_str, avg_APDiff_nii);
        end
        
    end
    
    % average across subjects and runs
    gavg_inDiff = squeeze(nanmean(avg_inDiff, 4)); gavg_outDiff = squeeze(nanmean(avg_outDiff, 4));
    if c == 2, gavg_PADiff = squeeze(nanmean(avg_PADiff, 4)); gavg_APDiff = squeeze(nanmean(avg_APDiff, 4)); end
    
    fd = [ gp, 'fmaps/' ];
    
    gavg_inDiff_nii = [ fd, CORR{c}, '_gavg_diffAPPA_distorted2std.nii.gz' ];
    mni_str.img = gavg_inDiff; save_untouch_nii(mni_str, gavg_inDiff_nii);
    
    gavg_outDiff_nii = [ fd, CORR{c}, '_gavg_diffAPPA_corrected2std.nii.gz' ];
    mni_str.img = gavg_outDiff; save_untouch_nii(mni_str, gavg_outDiff_nii);
    
    if c == 2
        gavg_PADiff_nii = [ fd, 'gavg_diffPA_methods2std.nii.gz' ];
        mni_str.img = gavg_PADiff; save_untouch_nii(mni_str, gavg_PADiff_nii);
        
        gavg_APDiff_nii = [ fd, 'gavg_diffAP_methods2std.nii.gz' ];
        mni_str.img = gavg_APDiff; save_untouch_nii(mni_str, gavg_APDiff_nii);
    end
end