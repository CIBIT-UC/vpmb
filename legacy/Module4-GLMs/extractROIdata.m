function roiData = extractROIdata(ROI, contrast)

    Y = spm_read_vols(spm_vol(ROI),1);
    indx = find(Y>0);
    [x,y,z] = ind2sub(size(Y),indx);
    
    XYZ = [x y z]';

    roiData = nanmean(spm_get_data(contrast,XYZ),2);

end