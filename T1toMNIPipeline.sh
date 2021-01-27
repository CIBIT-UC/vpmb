#!/bin/bash

# Pipeline for single subject/run estimation of struct2standard

# Requirements for this script
#  installed versions of: FSL
#  environment: FSLDIR

# --------------------------------------------------------------------------------
#  Settings
# --------------------------------------------------------------------------------

VPDIR="/DATAPOOL/VPMB/VPMB-STCIBIT"          # data folder
subID="VPMBAUS03"                            # subject ID
betDir="${VPDIR}/${subID}/ANALYSIS/T1W/BET"    # structural directory
fastDir="${VPDIR}/${subID}/ANALYSIS/T1W/FAST"    # FAST directory
WD="${VPDIR}/${subID}/ANALYSIS/T1W/MNI"      # working directory
mniImage=$FSLDIR/data/standard/MNI152_T1_2mm

# --------------------------------------------------------------------------------
#  Create/Clean folder
# --------------------------------------------------------------------------------

if [ ! -e $WD ] ; then # not exists
    mkdir -p $WD
    echo "--> MNI folder created."
elif [ "$(ls -A ${WD})" ] ; then # not empty
    rm -r ${WD}/*
    echo "--> MNI folder cleared."
else
    echo "--> MNI folder ready."
fi

# --------------------------------------------------------------------------------
#  Bias field correction
# --------------------------------------------------------------------------------

# create/clear folder
if [ ! -e $fastDir ] ; then # not exists
    mkdir -p $fastDir
    echo "--> FAST folder created."
elif [ "$(ls -A ${fastDir})" ] ; then # not empty
    rm -r ${fastDir}/*
    echo "--> FAST folder cleared."
else
    echo "--> FAST folder ready."
fi

# BET (cannot use the existing _brain because its restored)
cp $betDir/${subID}_T1W.nii.gz $fastDir/${subID}_T1W.nii.gz # copy file

fslmaths $fastDir/${subID}_T1W -mas $betDir/${subID}_T1W_brain_mask $fastDir/${subID}_T1W_brain    # apply  brain mask

#fslview_deprecated $fastDir/${subID}_T1W $fastDir/${subID}_T1W_brain &

# execute
fast -b -B -v -o ${fastDir}/${subID}_T1W_brain ${fastDir}/${subID}_T1W_brain.nii.gz

# apply also to non-bet image
fslmaths ${fastDir}/${subID}_T1W.nii.gz \
        -div ${fastDir}/${subID}_T1W_brain_bias.nii.gz \
        ${fastDir}/${subID}_T1W_restore.nii.gz

# check
# fslview_deprecated ${fastDir}/${subID}_T1W_restore.nii.gz -b 0,500 \
#     ${fastDir}/${subID}_T1W_brain_restore.nii.gz -b 0,500 &

# --------------------------------------------------------------------------------
#  Registration to MNI
# --------------------------------------------------------------------------------

# Initial linear registration
flirt -ref ${mniImage}_brain \
        -in ${fastDir}/${subID}_T1W_brain_restore \
        -omat $WD/struct2mni_affine.mat \
        -dof 12 -v

# Non-linear registration
fnirt --in=${fastDir}/${subID}_T1W_restore \
        --config=T1_2_MNI152_2mm \
        --aff=$WD/struct2mni_affine.mat \
        --cout=$WD/struct2mni -v

# Apply
applywarp --ref=${mniImage} \
    --in=${fastDir}/${subID}_T1W_restore \
    --warp=$WD/struct2mni \
    --out=${WD}/${subID}_T1W_MNI \
    --interp=sinc

# Check visually
# fslview_deprecated ${mniImage} ${WD}/${subID}_T1W_MNI &