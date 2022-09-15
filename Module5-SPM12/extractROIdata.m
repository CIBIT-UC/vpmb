function [CoG_vox,TValue,PeakVoxTValue,PeakVoxCoord_vox,CoG_mm,PeakVoxCoord_mm] = extractROIdata(ROI, Contrast)
%EXTRACTROIDATA Extract center of gravity (CoG) and T-value of a specific
%ROI for a given Contrast
%   Some reference: https://www.jiscmail.ac.uk/cgi-bin/webadmin?A2=spm;d269f69c.1604

[Y,XYZ_mm] = spm_read_vols(spm_vol(ROI),1); % read values from ROI and coordinates in mm

indx = find(Y>0.1); % find which voxels belong to ROI. do not use zero as the threshold as there could be some noise in the background.

[x,y,z] = ind2sub(size(Y),indx); % convert to x,y,z coordinates

XYZ_vox = [x y z]'; % concatenate to export
XYZ_mm = XYZ_mm(:,indx); % in mm

CoG_vox = mean(XYZ_vox,2); % estimate center of gravity
CoG_mm = mean(XYZ_mm,2); % estimate center of gravity (in mm)

tvalues = spm_get_data(Contrast, XYZ_vox); % get t-values for the given contrast inside the ROI

[PeakVoxTValue, m2] = max(tvalues); % calculate max and index of max

PeakVoxCoord_vox = XYZ_vox(:,m2); % to export
PeakVoxCoord_mm = XYZ_mm(:,m2); % to export

TValue = nanmean(tvalues,2); % calculate mean t-value of ROI

end
