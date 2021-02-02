#!/bin/bash

# Pipeline for single subject/run evaluation of DC with Voxel shift maps (VSM)

# Requirements for this script
#  installed versions of: FSL, Convert3D, ANTs
#  environment: FSLDIR

# --------------------------------------------------------------------------------
#  Settings
# --------------------------------------------------------------------------------

VPDIR="/DATAPOOL/VPMB/VPMB-STCIBIT"                          # data folder
subID="VPMBAUS03"                                            # subject ID
taskName="TASK-LOC-1000"                                     # task name
taskDir="${VPDIR}/${subID}/ANALYSIS/${taskName}"             # task directory
fmapDir="${VPDIR}/${subID}/ANALYSIS/${taskName}/FMAP-SPE"    # fmap directory
t1Dir="${VPDIR}/${subID}/ANALYSIS/T1W"                       # T1w directory
vsmDir="${VPDIR}/${subID}/ANALYSIS/${taskName}/FMAP-SPE/vsm" # working directory
ro_time=0.0415863                                            # in seconds
mniImage=$FSLDIR/data/standard/MNI152_T1_1mm                 # MNI template

# --------------------------------------------------------------------------------
#  Create/Clean folder
# --------------------------------------------------------------------------------

if [ ! -e $vsmDir ] ; then # not exists
    mkdir -p $vsmDir
    echo "--> FMAP-SPE/vsm folder created."
elif [ "$(ls -A ${vsmDir})" ] ; then # not empty
    rm -r ${vsmDir}/*
    echo "--> FMAP-SPE/vsm folder cleared."
else
    echo "--> FMAP-SPE/vsm folder ready."
fi

# --------------------------------------------------------------------------------
#  Copy files
# --------------------------------------------------------------------------------

cp $fmapDir/work/TopupField.nii.gz $vsmDir/fieldmap.nii.gz # output field of topup
cp $fmapDir/work/spe-ap_dc_jac.nii.gz $vsmDir/speReference.nii.gz # distortion corrected SPE AP image

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
#  Brain extract speReference
# --------------------------------------------------------------------------------

bet2 $vsmDir/speReference.nii.gz $vsmDir/speReferenceMask -f 0.4 -n -m   # calculate spe-ap brain mask
mv $vsmDir/speReferenceMask_mask.nii.gz $vsmDir/speReference_brain_mask.nii.gz  # rename spe brain mask
fslmaths $vsmDir/speReference.nii.gz -mas $vsmDir/speReference_brain_mask.nii.gz $vsmDir/speReference_brain.nii.gz  # apply spe brain mask

# check visually
fslview_deprecated $vsmDir/speReference.nii.gz $vsmDir/speReference_brain.nii.gz &

# --------------------------------------------------------------------------------
#  Bias field correction speReference
# --------------------------------------------------------------------------------

fast -B -v $vsmDir/speReference_brain.nii.gz    # output: speReference_brain_restore

# --------------------------------------------------------------------------------
#  Estimate spe2struct using epi_reg
# --------------------------------------------------------------------------------
# Output matrix: spe2struct.mat

epi_reg \
    --epi=$vsmDir/speReference_brain_restore \
    --t1=${t1Dir}/FAST/${subID}_T1W_restore \
    --t1brain=${t1Dir}/FAST/${subID}_T1W_brain_restore \
    --wmseg=${t1Dir}/FAST/${subID}_T1W_brain_wmseg \
    --out=$vsmDir/spe2struct

# check visually
fslview_deprecated ${t1Dir}/FAST/${subID}_T1W_brain_restore.nii.gz $vsmDir/spe2struct.nii.gz &

# Convert .mat to ANTs format
c3d_affine_tool \
    -ref ${t1Dir}/FAST/${subID}_T1W_restore \
    -src $vsmDir/speReference_brain_restore \
    $vsmDir/spe2struct.mat -fsl2ras -oitk $vsmDir/spe2struct_ANTS.txt

# --------------------------------------------------------------------------------
#  SPE to MNI using ANTs
# --------------------------------------------------------------------------------

antsApplyTransforms -d 3 \
    -i $vsmDir/speReference.nii.gz \
    -r $mniImage.nii.gz \
    -n HammingWindowedSinc \
    -t ${t1Dir}/MNI/struct2mni_warp.nii.gz \
    -t ${t1Dir}/MNI/struct2mni_affine.mat \
    -t $vsmDir/spe2struct_ANTS.txt \
    -o $vsmDir/speReference_MNI.nii.gz -v

# check
fslview_deprecated $mniImage $vsmDir/speReference_MNI.nii.gz &

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
    -t $vsmDir/spe2struct_ANTS.txt \
    -o $vsmDir/fieldmap_vsm_MNI.nii.gz -v

# Apply brain mask
fslmaths $vsmDir/fieldmap_vsm_MNI -mas ${mniImage}_brain_mask $vsmDir/fieldmap_vsm_brain_MNI

# Check visually
fsleyes ${mniImage} $vsmDir/fieldmap_vsm_brain_MNI -dr -10 10 -cm brain_colours_diverging_bwr_iso &

# --------------------------------------------------------------------------------
#  Interesting values
# --------------------------------------------------------------------------------


