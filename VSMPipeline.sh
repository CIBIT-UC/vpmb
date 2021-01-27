#!/bin/bash

# Pipeline for single subject/run evaluation of DC with Voxel shift maps (VSM)

# Requirements for this script
#  installed versions of: FSL
#  environment: FSLDIR

# --------------------------------------------------------------------------------
#  Settings
# --------------------------------------------------------------------------------

VPDIR="/DATAPOOL/VPMB/VPMB-STCIBIT"                         # data folder
subID="VPMBAUS03"                                           # subject ID
taskName="TASK-LOC-1000"                                    # task name
taskDir="${VPDIR}/${subID}/ANALYSIS/${taskName}"            # task directory
fmapDir="${VPDIR}/${subID}/ANALYSIS/${taskName}/FMAP-SPE"   # fmap directory
t1Dir="${VPDIR}/${subID}/ANALYSIS/T1W"                      # T1w directory
WD="${VPDIR}/${subID}/ANALYSIS/${taskName}/FMAP-SPE/vsm"    # working directory
ro_time=0.0415863 # in seconds
#nThreads=36 # number of threads
mniImage=$FSLDIR/data/standard/MNI152_T1_2mm

# --------------------------------------------------------------------------------
#  Create/Clean folder
# --------------------------------------------------------------------------------

if [ ! -e $WD ] ; then # not exists
    mkdir -p $WD
    echo "--> FMAP-SPE/vsm folder created."
elif [ "$(ls -A ${WD})" ] ; then # not empty
    rm -r ${WD}/*
    echo "--> FMAP-SPE/vsm folder cleared."
else
    echo "--> FMAP-SPE/vsm folder ready."
fi

# --------------------------------------------------------------------------------
#  Copy files
# --------------------------------------------------------------------------------

cp $fmapDir/work/GREfromTOPUP-Phase.nii.gz $WD/fieldmap.nii.gz
cp $fmapDir/work/spe-ap_dc_jac.nii.gz $WD/speReference.nii.gz

# --------------------------------------------------------------------------------
#  Calculate VSM
# --------------------------------------------------------------------------------

fslmaths ${WD}/fieldmap \
    -div $ro_time \
    $WD/fieldmap_vsm

# check visually
fsleyes $WD/fieldmap_vsm -dr -30000 30000 -cm brain_colours_diverging_bwr_iso &

# --------------------------------------------------------------------------------
#  Estimate spe2mni
# --------------------------------------------------------------------------------

# BET speReference
bet2 $WD/speReference.nii.gz $WD/speReferenceMask -f 0.4 -n -m   # calculate spe-ap brain mask
mv $WD/speReferenceMask_mask.nii.gz $WD/speReference_brain_mask.nii.gz  # rename spe brain mask
fslmaths $WD/speReference.nii.gz -mas $WD/speReference_brain_mask.nii.gz $WD/speReference_brain.nii.gz  # apply spe brain mask

# check visually
fslview_deprecated $WD/speReference.nii.gz $WD/speReference_brain.nii.gz &

# Bias field
fast -B $WD/speReference_brain.nii.gz    # output: speReference_brain_restore

# Estimate register from spe to struct
flirt -ref ${t1Dir}/FAST/${subID}_T1W_brain_restore \
    -in $WD/speReference_brain_restore \
    -omat $WD/spe2struct \
    -out $WD/spe2struct \
    -cost normmi \
    -interp sinc \
    -dof 6 -v

# check visually
fslview_deprecated ${t1Dir}/FAST/${subID}_T1W_brain_restore.nii.gz $WD/spe2struct.nii.gz &

# Concatenate spe2struct and struct2mni_affine
convert_xfm -omat $WD/spe2mni_affine \
            -concat ${t1Dir}/MNI/struct2mni_affine.mat $WD/spe2struct

# Apply spe2mni_affine
flirt -ref $mniImage \
    -in $WD/speReference \
    -init $WD/spe2mni_affine \
    -applyxfm \
    -out $WD/speReference_MNI_affine \
    -interp sinc -v

# check
fslview_deprecated $mniImage $WD/speReference_MNI_affine &

# --------------------------------------------------------------------------------
#  VSM to MNI
# --------------------------------------------------------------------------------

#fslmaths $WD/fieldmap_vsm -mas $WD/speReference_brain_mask.nii.gz $WD/fieldmap_vsm_brain  # apply spe brain mask

# Apply spe2mni_affine
flirt -ref $mniImage \
    -in $WD/fieldmap_vsm \
    -init $WD/spe2mni_affine \
    -applyxfm \
    -out $WD/fieldmap_vsm_MNI \
    -interp sinc -v

fslmaths $WD/fieldmap_vsm_MNI -mas ${mniImage}_brain_mask $WD/fieldmap_vsm_brain_MNI

fsleyes ${mniImage} $WD/fieldmap_vsm_brain_MNI -dr -30000 30000 -cm brain_colours_diverging_bwr_iso &

# # concatenate transformations spe2struct (linear) with struct2mni (nonlinear)
# convertwarp --ref=$mniImage \
#         --out=$WD/spe2mni \
#         --premat=$WD/spe2struct \
#         --warp1=${t1Dir}/MNI/struct2mni \
#         --rel --verbose

# # Apply spe2mni
# applywarp --ref=$mniImage \
#     --in=$WD/speReference \
#     --warp=$WD/spe2mni \
#     --out=$WD/speReference_MNI \
#     --interp=sinc

# # Check visually
# fslview_deprecated $mniImage ${t1Dir}/MNI/${subID}_T1W_MNI $WD/speReference_MNI &
