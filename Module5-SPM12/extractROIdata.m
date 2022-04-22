function [CoG,TValue,PeakVoxTValue,PeakVoxCoord] = extractROIdata(ROI, Contrast)
%EXTRACTROIDATA Extract center of gravity (CoG) and T-value of a specific
%ROI for a given Contrast
%   

Y = spm_read_vols(spm_vol(ROI),1); % read values from ROI

indx = find(Y>0); % find which voxels belong to ROI

[x,y,z] = ind2sub(size(Y),indx); % convert to x,y,z coordinates

XYZ = [x y z]'; % concatenate to export

CoG = mean(XYZ,2); % estimate center of gravity

tvalues = spm_get_data(Contrast, XYZ); % get t-values for the given contrast inside the ROI

[PeakVoxTValue, m2] = max(tvalues); % calculate max and index of max

[p1,p2,p3] = ind2sub(size(Y),m2); % convert index of max to x,y,z coordinates

PeakVoxCoord = [p1 p2 p3]'; % concatenate to export

TValue = nanmean(tvalues,2); % calculate mean t-value of ROI

end
