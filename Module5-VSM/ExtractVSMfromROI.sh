vsmFolder='/DATAPOOL/VPMB/VPMB-BIDS-NLREG/derivatives/vsm/group'
roiFolder='/DATAPOOL/VPMB/ROIsforSDC'

acqList=("all" "0500" "0750" "1000" "2500")
acqName=${acqList[1]}

roiList=("aIns_LR_brainnetome" "Ca_LR_CIT168" "hMT_LR_brainnetome" "hMT_LR_glasser" "MPFC_LR_brainnetome" "MPFC_LR_glasser" "NAc_LR_brainnetome" "NAc_LR_CIT168" "SubCC_LR_glasser" "V1_LR_glasser")
roiName=${roiList[1]}

# resample roi mask to VSM resolution
# https://fsl.fmrib.ox.ac.uk/fsl/fslwiki/FLIRT/FAQ#How_do_I_transform_a_mask_with_FLIRT_from_one_space_to_another.3F

flirt -in $roiFolder/$roiName \
    -ref $vsmFolder/sub-all_task-all_acq-${acqName}_space-MNI_warp_brain_mean.nii.gz \
    -applyxfm -usesqform \
    -out $roiFolder/${roiName}_space-VSM

fslmaths $roiFolder/${roiName}_space-VSM -thr 0.5 -bin $roiFolder/${roiName}_space-VSM

# Check result
fsleyes $roiFolder/${roiName} $roiFolder/${roiName}_space-VSM &

# Extract values
fslmeants -i $vsmFolder/sub-all_task-all_acq-${acqName}_space-MNI_warp_brain_merge \
          -m $roiFolder/${roiName}_space-VSM