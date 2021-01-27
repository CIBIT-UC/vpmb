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

# --------------------------------------------------------------------------------
#  Create/Clean folders
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

# execute
fast -b -v -o ${fastDir}/${subID}_T1W_brain ${betDir}/${subID}_T1W_brain.nii.gz
#mv ${fastDir}/${subID}_T1W_bias

# apply
fslmaths ${betDir}/${subID}_T1W_brain.nii.gz \
        -div ${fastDir}/${subID}_T1W_brain_bias.nii.gz \
        ${fastDir}/${subID}_T1W_brain_restore.nii.gz

# apply also to non-bet image
fslmaths ${betDir}/${subID}_T1W.nii.gz \
        -div ${fastDir}/${subID}_T1W_brain_bias.nii.gz \
        ${fastDir}/${subID}_T1W_restore.nii.gz

# check
fslview_deprecated ${fastDir}/${subID}_T1W_restore -b 0,500 \
    ${fastDir}/${subID}_T1W_brain_restore -b 0,500 &

# --------------------------------------------------------------------------------
#  Registration to MNI
# --------------------------------------------------------------------------------

# Initial linear registration
flirt -ref ${FSLDIR}/data/standard/MNI152_T1_2mm_brain \
        -in ${fastDir}/${subID}_T1W_brain_restore \
        -omat $WD/struct2mni_affine.mat \
        -dof 12 -v

# Non-linear registration
fnirt --in=${fastDir}/${subID}_T1W_restore \
        --config=T1_2_MNI152_2mm \
        --aff=$WD/struct2mni_affine.mat \
        --cout=$WD/struct2mni -v

# fnirt --in=${betDir}/${subID}_T1W \
#         --aff=$WD/struct2mni_affine.mat \
#         --cout=$WD/struct2mniop2 \
#         --ref=$FSLDIR/data/standard/MNI152_T1_2mm \
#         --refmask=$FSLDIR/data/standard/MNI152_T1_2mm_brain_mask -v \
#         --warpres=10,10,10 -v

# Apply
applywarp --ref=${FSLDIR}/data/standard/MNI152_T1_2mm \
    --in=${fastDir}/${subID}_T1W_restore \
    --warp=$WD/struct2mni \
    --out=${WD}/${subID}_T1W_MNI \
    --interp=sinc

# applywarp --ref=${FSLDIR}/data/standard/MNI152_T1_2mm \
#     --in=${betDir}/${subID}_T1W \
#     --warp=$WD/struct2mniop2 \
#     --out=${WD}/${subID}_T1W_MNIop2    

fslview_deprecated ${FSLDIR}/data/standard/MNI152_T1_2mm ${WD}/${subID}_T1W_MNI &