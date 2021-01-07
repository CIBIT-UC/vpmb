#!/bin/bash

# Tests for the correction of functional data using Spin-Echo (SPE) fieldmaps

# Requirements for this script
#  installed versions of: FSL
#  environment: FSLDIR

# --------------------------------------------------------------------------------
#  Settings
# --------------------------------------------------------------------------------

VPDIR="/DATAPOOL/VPMB/VPMB-STCIBIT"   # data folder
subID="VPMBAUS01"                     # subject ID
taskName="TASK-LOC-1000"              # task name
WD="${VPDIR}/${subID}/speTests"       # working directory

# --------------------------------------------------------------------------------
#  Create or clean folder
# --------------------------------------------------------------------------------

if [ ! -e $WD ] ; then # not exists
    mkdir $WD
    echo "--> speTests folder created."
elif [ "$(ls -A ${WD})" ] ; then # not empty
    rm -r ${WD}/*
    echo "--> speTests folder cleared."
else
    echo "--> speTests folder ready."
fi

# --------------------------------------------------------------------------------
#  Copy files and Brain Extraction and Bias field correction
# --------------------------------------------------------------------------------

# copy functional and SPE
cp $VPDIR/$subID/RAW/${TASKNAME}/${subID}_${TASKNAME}.nii.gz $WD/func.nii.gz &
cp $VPDIR/$subID/RAW/${TASKNAME}/${subID}_FMAP-SPE-AP.nii.gz $WD/spe.nii.gz

# create func01 (first volume of functional data)
fslroi $WD/func.nii.gz $WD/func01.nii.gz 0 1

# BET func01 and SPE
bet2 $WD/func01.nii.gz $WD/funcMask -f 0.3 -n -m &  # calculate func01 mask
bet2 $WD/spe.nii.gz $WD/speMask -f 0.3 -n -m        # calculate spe mask

mv $WD/funcMask_mask.nii.gz $WD/func_brain_mask.nii.gz &  # rename func01 mask
mv $WD/speMask_mask.nii.gz $WD/spe_brain_mask.nii.gz      # rename spe mask

fslmaths $WD/func01.nii.gz -mas $WD/func_brain_mask.nii.gz $WD/func01_brain.nii.gz &  # apply func01 mask
fslmaths $WD/spe.nii.gz -mas $WD/spe_brain_mask.nii.gz $WD/spe_brain.nii.gz           # apply spe mask

# Bias field correction
fast -B $WD/func01_brain.nii.gz &  # output: func01_brain_restore
fast -B $WD/spe_brain.nii.gz       # output: spe_brain_restore

# --------------------------------------------------------------------------------
#  Using SPE-AP as reference (scout)
# --------------------------------------------------------------------------------

# Align func01 to SPE-AP
flirt -ref $WD/spe_brain_restore.nii.gz \
      -in $WD/func01_brain_restore.nii.gz \
      -out $WD/func2spe.nii.gz \
      -omat $WD/func2spe.mat \
      -cost normmi \
      -interp sinc \
      -dof 6


# --------------------------------------------------------------------------------
#  Motion Correction
# --------------------------------------------------------------------------------

mcflirt -in $WD/func.nii.gz \
        -refvol 0 \
        -o $WD/func_mc \
        -sinc_final \
        -mats -plots -report


# --------------------------------------------------------------------------------
#  TOPUP
# --------------------------------------------------------------------------------


# --------------------------------------------------------------------------------
#  func to corrected func
# --------------------------------------------------------------------------------