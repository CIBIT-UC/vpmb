function compare_AP_PA_BM_v3(par, repeat)

warning off;
p = '/DATAPOOL/BIOMOTION/';
sub = dir([ p, 'P*_*' ]); n_sub = length(sub);
RUNS = { 'Localizer'; 'BioMotion_01'; 'BioMotion_02'; 'BioMotion_03'; 'BioMotion_04' };
nR = length(RUNS);

geoCorr = { 'topup'; 'gfm' }; % methods for geometric distortion corrections

if ~exist([ p, 'GROUP_RESULTS/APPA.mat' ]) || repeat
    
    % within methods
    err  = nan(n_sub, nR, length(geoCorr)); errc  = nan(n_sub, nR, length(geoCorr)); % MSE
    nmse = nan(n_sub, nR, length(geoCorr)); nmsec = nan(n_sub, nR, length(geoCorr)); % normalized MSE
    xc   = nan(n_sub, nR, length(geoCorr)); xcc   = nan(n_sub, nR, length(geoCorr)); % cross-correlation
    
    % across methods
    errPA  = nan(n_sub, nR); errAP  = nan(n_sub, nR); % MSE
    nmsePA = nan(n_sub, nR); nmseAP = nan(n_sub, nR); % normalized MSE
    xcPA   = nan(n_sub, nR); xcAP   = nan(n_sub, nR); % cross-correlation
        
    if ~par
        for s = 1:n_sub
            
            [ err(s, :, :), errc(s, :, :), nmse(s, :, :), nmsec(s, :, :), xc(s, :, :), xcc(s, :, :), ...
                errPA(s, :), errAP(s, :), nmsePA(s, :), nmseAP(s, :), xcPA(s, :), xcAP(s, :) ] = ...
                compare_AP_PA_BM_aux(p, sub, s, RUNS, geoCorr);
            
        end
    else
        try
            parpool('local', 20);
        catch
            poolobj = gcp('nocreate'); delete(poolobj); parpool('local', 20);
        end
        
        parfor s = 1:n_sub
            
            [ err(s, :, :), errc(s, :, :), nmse(s, :, :), nmsec(s, :, :), xc(s, :, :), xcc(s, :, :), ...
                errPA(s, :), errAP(s, :), nmsePA(s, :), nmseAP(s, :), xcPA(s, :), xcAP(s, :) ] = ...
                compare_AP_PA_BM_aux(p, sub, s, RUNS, geoCorr);
            
        end
        
        poolobj = gcp('nocreate'); delete(poolobj);
    end
    
    % store results
    APPA.WithinMethods.err = err; APPA.WithinMethods.errc = errc; APPA.WithinMethods.nmse = nmse; APPA.WithinMethods.nmsec = nmsec; APPA.WithinMethods.xc = xc; APPA.WithinMethods.xcc = xcc;
    APPA.AcrossMethods.errPA = errPA; APPA.AcrossMethods.errAP = errAP; APPA.AcrossMethods.nmsePA = nmsePA; APPA.AcrossMethods.nmseAP = nmseAP; APPA.AcrossMethods.xcPA = xcPA; APPA.AcrossMethods.xcAP = xcAP;
    
    save([ p, 'GROUP_RESULTS/APPA_v2.mat' ], 'APPA')
    
else
    
    % load results
    load([ p, 'GROUP_RESULTS/APPA_v2.mat' ]);
    
end

% STATS

% TOPUP
% check if err(distorted) > err(corrected)
errT = APPA.WithinMethods.err(:, :, 1); errcT = APPA.WithinMethods.errc(:, :, 1);
[ ~, p_errT ] = ttest(errT(:) - errcT(:));

% check if nmse(distorted) > nmse(corrected)
nmseT = APPA.WithinMethods.nmse(:, :, 1); nmsecT = APPA.WithinMethods.nmsec(:, :, 1);
[ ~, p_nmseT ] = ttest(nmseT(:) - nmsecT(:));

% check if xc(distorted) < xc(corrected)
xcT = APPA.WithinMethods.xc(:, :, 1); xccT = APPA.WithinMethods.xcc(:, :, 1);
[ ~, p_xcT ] = ttest(xccT(:) - xcT(:));

% GFM
% check if err(distorted) > err(corrected)
errG = APPA.WithinMethods.err(:, :, 2); errcG = APPA.WithinMethods.errc(:, :, 2);
[ ~, p_errG ] = ttest(errG(:) - errcG(:));

% check if nmse(distorted) > nmse(corrected)
nmseG = APPA.WithinMethods.nmse(:, :, 2); nmsecG = APPA.WithinMethods.nmsec(:, :, 2);
[ ~, p_nmseG ] = ttest(nmseG(:) - nmsecG(:));

% check if xc(distorted) < xc(corrected)
xcG = APPA.WithinMethods.xc(:, :, 2); xccG = APPA.WithinMethods.xcc(:, :, 2);
[ ~, p_xcG ] = ttest(xccG(:) - xcG(:));

% TOPUP vs GFM (corrected)
% check if errAP ~= errPA
[ ~, p_err ] = ttest(APPA.AcrossMethods.errPA(:), APPA.AcrossMethods.errAP(:), 'tail', 'both');

% check if nmseAP ~= nmsePA
[ ~, p_nmse ] = ttest(APPA.AcrossMethods.nmsePA(:), APPA.AcrossMethods.nmseAP(:), 'tail', 'both');

% check if xcAP ~= xcPA
[ ~, p_xc ] = ttest(APPA.AcrossMethods.xcPA(:), APPA.AcrossMethods.xcAP(:), 'tail', 'both');