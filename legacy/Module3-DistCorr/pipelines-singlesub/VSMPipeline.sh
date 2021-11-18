#!/bin/bash

# Pipeline for single subject/run evaluation of DC with Voxel shift maps (VSM)

# Requirements for this script
#  installed versions of: FSL, Convert3D, ANTs
#  environment: FSLDIR

# --------------------------------------------------------------------------------
#  Settings
# --------------------------------------------------------------------------------

VPDIR="/DATAPOOL/VPMB/VPMB-STCIBIT"                                  # data folder
subID="VPMBAUS01"                                                    # subject ID
taskName="TASK-LOC-1000"                                             # task name
fmapType="NLREG"                                                       # options: SPE, EPI. for GRE use VSMPipelineGRE.sh
taskDir="${VPDIR}/${subID}/ANALYSIS/${taskName}"                     # task directory
fmapDir="${VPDIR}/${subID}/ANALYSIS/${taskName}/FMAP-${fmapType}"    # fmap directory
t1Dir="${VPDIR}/${subID}/ANALYSIS/T1W"                               # T1w directory
vsmDir="${VPDIR}/${subID}/ANALYSIS/${taskName}/FMAP-${fmapType}/vsm" # working directory
ro_time=0.0415863                                                    # in seconds
mniImage=$FSLDIR/data/standard/MNI152_T1_1mm                         # MNI template

# --------------------------------------------------------------------------------
#  Create/Clean folder
# --------------------------------------------------------------------------------

if [ ! -e $vsmDir ] ; then # not exists
    mkdir -p $vsmDir
    echo "--> vsm folder created."
elif [ "$(ls -A ${vsmDir})" ] ; then # not empty
    rm -r ${vsmDir}/*
    echo "--> vsm folder cleared."
else
    echo "--> vsm folder ready."
fi

# --------------------------------------------------------------------------------
#  Copy files depending on fieldmap type
# --------------------------------------------------------------------------------

if [ ${fmapType} = "SPE" ]; then
    
    cp $fmapDir/work/TopupField.nii.gz $vsmDir/fieldmap.nii.gz # output field of topup
    cp $fmapDir/work/spe-ap_dc_jac.nii.gz $vsmDir/fmapReference.nii.gz # distortion corrected AP image

elif [ ${fmapType} = "EPI" ]; then

    cp $fmapDir/work/TopupField.nii.gz $vsmDir/fieldmap.nii.gz # output field of topup
    cp $fmapDir/work/epi-ap_dc_jac.nii.gz $vsmDir/fmapReference.nii.gz # distortion corrected AP image

elif [ ${fmapType} = "NLREG" ]; then

    cp $fmapDir/work/func012invt1_down_moderate_0Warp.nii.gz $vsmDir/fieldmap.nii.gz

fi

fsleyes $vsmDir/fieldmap -dr -10 10 -cm brain_colours_diverging_bwr_iso &

# --------------------------------------------------------------------------------
#  Calculate VSM
# --------------------------------------------------------------------------------
# Formula: VSM = topup field (Hz) * readout time (s) = topup field (Hz) / readout time (Hz)
# Output VSM is in number of voxels

fslmaths ${vsmDir}/fieldmap \
    -mul $ro_time \
    $vsmDir/fieldmap_vsm

# check visually
fsleyes $vsmDir/fieldmap_vsm -dr -10 10 -cm brain_colours_diverging_bwr_iso &

# --------------------------------------------------------------------------------
#  Brain extract fmapReference
# --------------------------------------------------------------------------------

bet2 $vsmDir/fmapReference.nii.gz $vsmDir/fmapReferenceMask -f 0.4 -n -m   # calculate fmap-ap brain mask
mv $vsmDir/fmapReferenceMask_mask.nii.gz $vsmDir/fmapReference_brain_mask.nii.gz  # rename fmap brain mask
fslmaths $vsmDir/fmapReference.nii.gz -mas $vsmDir/fmapReference_brain_mask.nii.gz $vsmDir/fmapReference_brain.nii.gz  # apply fmap brain mask

# check visually
fslview_deprecated $vsmDir/fmapReference.nii.gz $vsmDir/fmapReference_brain.nii.gz &

# --------------------------------------------------------------------------------
#  Bias field correction fmapReference
# --------------------------------------------------------------------------------

fast -B -v $vsmDir/fmapReference_brain.nii.gz    # output: fmapReference_brain_restore

# --------------------------------------------------------------------------------
#  Estimate fmap2struct using epi_reg
# --------------------------------------------------------------------------------
# Output matrix: fmap2struct.mat

epi_reg \
    --epi=$vsmDir/fmapReference_brain_restore \
    --t1=${t1Dir}/FAST/${subID}_T1W_restore \
    --t1brain=${t1Dir}/FAST/${subID}_T1W_brain_restore \
    --wmseg=${t1Dir}/FAST/${subID}_T1W_brain_wmseg \
    --out=$vsmDir/fmap2struct

# check visually
fslview_deprecated ${t1Dir}/FAST/${subID}_T1W_brain_restore.nii.gz $vsmDir/fmap2struct.nii.gz &

# Convert .mat to ANTs format
c3d_affine_tool \
    -ref ${t1Dir}/FAST/${subID}_T1W_restore \
    -src $vsmDir/fmapReference_brain_restore \
    $vsmDir/fmap2struct.mat -fsl2ras -oitk $vsmDir/fmap2struct_ANTS.txt

# --------------------------------------------------------------------------------
#  fmap to MNI using ANTs
# --------------------------------------------------------------------------------

antsApplyTransforms -d 3 \
    -i $vsmDir/fmapReference.nii.gz \
    -r $mniImage.nii.gz \
    -n HammingWindowedSinc \
    -t ${t1Dir}/MNI/struct2mni_warp.nii.gz \
    -t ${t1Dir}/MNI/struct2mni_affine.mat \
    -t $vsmDir/fmap2struct_ANTS.txt \
    -o $vsmDir/fmapReference_MNI.nii.gz -v

# check
fslview_deprecated $mniImage $vsmDir/fmapReference_MNI.nii.gz &

# --------------------------------------------------------------------------------
#  VSM to MNI using ANTs
# --------------------------------------------------------------------------------
# Nearest Neighbor interpolation (do not allow voxel value change)

antsApplyTransforms -d 3 \
    -i $vsmDir/fieldmap_vsm.nii.gz \
    -r $mniImage.nii.gz \
    -n NearestNeighbor \
    -t ${t1Dir}/MNI/struct2mni_warp.nii.gz \
    -t ${t1Dir}/MNI/struct2mni_affine.mat \
    -t $vsmDir/fmap2struct_ANTS.txt \
    -o $vsmDir/fieldmap_vsm_MNI.nii.gz -v

# Apply brain mask
fslmaths $vsmDir/fieldmap_vsm_MNI -mas ${mniImage}_brain_mask $vsmDir/fieldmap_vsm_brain_MNI

# Check visually
fsleyes ${mniImage} $vsmDir/fieldmap_vsm_brain_MNI -dr -10 10 -cm brain_colours_diverging_bwr_iso &
