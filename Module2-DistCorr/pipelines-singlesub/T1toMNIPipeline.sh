#!/bin/bash

# Pipeline for single subject/run estimation of struct2standard

# Requirements for this script
#  installed versions of: FSL, ANTs
#  environment: FSLDIR, ANTSPATH

# --------------------------------------------------------------------------------
#  Settings
# --------------------------------------------------------------------------------

VPDIR="/DATAPOOL/VPMB/VPMB-STCIBIT"           # data folder
subID="VPMBAUS01"                             # subject ID
betDir="${VPDIR}/${subID}/ANALYSIS/T1W/BET"   # structural directory
fastDir="${VPDIR}/${subID}/ANALYSIS/T1W/FAST" # FAST directory
mniDir="${VPDIR}/${subID}/ANALYSIS/T1W/MNI"       # working directory
mniImage=$FSLDIR/data/standard/MNI152_T1_1mm  # MNI template
nThreads=18                                   # Number of threads for ANTs (overides $ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS)

# --------------------------------------------------------------------------------
#  Create/Clean fast and mni folders
# --------------------------------------------------------------------------------

# mniDir
if [ ! -e $mniDir ] ; then # not exists
    mkdir -p $mniDir
    echo "--> MNI folder created."
elif [ "$(ls -A ${mniDir})" ] ; then # not empty
    rm -r ${mniDir}/*
    echo "--> MNI folder cleared."
else
    echo "--> MNI folder ready."
fi

# fastDir
if [ ! -e $fastDir ] ; then # not exists
    mkdir -p $fastDir
    echo "--> FAST folder created."
elif [ "$(ls -A ${fastDir})" ] ; then # not empty
    rm -r ${fastDir}/*
    echo "--> FAST folder cleared."
else
    echo "--> FAST folder ready."
fi

# --------------------------------------------------------------------------------
#  BET T1W
# --------------------------------------------------------------------------------
# (cannot use the output from ANTs because it is already restored)

# Copy file
cp $betDir/${subID}_T1W.nii.gz $fastDir/${subID}_T1W.nii.gz 

# Apply  brain mask
fslmaths $fastDir/${subID}_T1W -mas $betDir/${subID}_T1W_brain_mask $fastDir/${subID}_T1W_brain

# check
fslview_deprecated $fastDir/${subID}_T1W $fastDir/${subID}_T1W_brain &

# --------------------------------------------------------------------------------
#  Bias field correction
# --------------------------------------------------------------------------------

# Execute FAST
# will export bias-corrected image (-B) and binary images for the three tissue types (segmentation, -g)
fast -b -B -v -g -o ${fastDir}/${subID}_T1W_brain ${fastDir}/${subID}_T1W_brain.nii.gz

# Rename segmentation outputs
mv ${fastDir}/${subID}_T1W_brain_seg_0.nii.gz ${fastDir}/${subID}_T1W_brain_csfseg.nii.gz
mv ${fastDir}/${subID}_T1W_brain_seg_1.nii.gz ${fastDir}/${subID}_T1W_brain_gmseg.nii.gz
mv ${fastDir}/${subID}_T1W_brain_seg_2.nii.gz ${fastDir}/${subID}_T1W_brain_wmseg.nii.gz

# Apply bias field also to non-bet image
fslmaths ${fastDir}/${subID}_T1W.nii.gz \
        -div ${fastDir}/${subID}_T1W_brain_bias.nii.gz \
        ${fastDir}/${subID}_T1W_restore.nii.gz

# check
fslview_deprecated ${fastDir}/${subID}_T1W_restore.nii.gz -b 0,500 ${fastDir}/${subID}_T1W_brain_restore.nii.gz -b 0,500 &

# --------------------------------------------------------------------------------
#  Registration to MNI using ANTs
# --------------------------------------------------------------------------------

# Execute
antsRegistrationSyN.sh \
    -d 3 \
    -f ${mniImage}.nii.gz \
    -m ${fastDir}/${subID}_T1W.nii.gz \
    -o ${mniDir}/antsOut_ \
    -n $nThreads

# Rename final images
mv ${mniDir}/antsOut_Warped.nii.gz ${mniDir}/${subID}_T1W_MNI.nii.gz
mv ${mniDir}/antsOut_0GenericAffine.mat ${mniDir}/struct2mni_affine.mat
mv ${mniDir}/antsOut_1Warp.nii.gz ${mniDir}/struct2mni_warp.nii.gz

# check
fslview_deprecated $mniImage ${mniDir}/${subID}_T1W_MNI.nii.gz &