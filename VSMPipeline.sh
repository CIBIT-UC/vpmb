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
#  Calculate VDM
# --------------------------------------------------------------------------------

fslmaths ${WD}/fieldmap \
    -div $ro_time \
    $WD/fieldmap_vsm

# check visually
fsleyes $WD/fieldmap_vsm -dr -30000 30000 -cm brain_colours_diverging_bwr_iso &

# --------------------------------------------------------------------------------
#  Registration to MNI
# --------------------------------------------------------------------------------

# BET speReference
bet2 $WD/speReference.nii.gz $WD/speReferenceMask -f 0.4 -n -m   # calculate spe-ap brain mask
mv $WD/speReferenceMask_mask.nii.gz $WD/speReference_brain_mask.nii.gz  # rename spe brain mask
fslmaths $WD/speReference.nii.gz -mas $WD/speReference_brain_mask.nii.gz $WD/speReference_brain.nii.gz  # apply spe brain mask

# check visually
fsleyes $WD/speReference.nii.gz $WD/speReference_brain.nii.gz &

# Affine guess
flirt -ref $FSLDIR/data/standard/MNI152_T1_2mm_brain.nii.gz \
      -in $WD/speReference_brain.nii.gz \
      -out $WD/spe2mni_affineguess \
      -omat $WD/spe2mni_affineguess.mat \
      -dof 12 -v

# check
# fslview_deprecated $FSLDIR/data/standard/MNI152_T1_2mm_brain.nii.gz $WD/spe2mni_affineguess &

# Non linear registration
fnirt --ref=$FSLDIR/data/standard/MNI152_T1_2mm \
    --refmask=$FSLDIR/data/standard/MNI152_T1_2mm_brain_mask \
    --in=$WD/speReference.nii.gz \
    --aff=$WD/spe2mni_affineguess \
    --cout=$WD/spe2mni_coeff \
    --fout=$WD/spe2mni_warp \
    --iout=$WD/speReference2mni \
    --warpres=10,10,10 -v

# Check visually
fslview_deprecated $FSLDIR/data/standard/MNI152_T1_2mm.nii.gz $WD/speReference2mni &

# Alternative !

# Estimate register from spe to struct
flirt -ref ${t1Dir}/BET/${subDir}_T1W_brain \
    -in $WD/speReference_brain \
    -omat spe2struct.mat \
    -cost normmi \
    -interp sinc \
    -dof 6 -v

# Combine spe2struct with struct2mni
applywarp --ref=${FSLDIR}/data/standard/MNI152_T1_2mm \
    --in=$WD/speReference \
    --warp=${t1Dir}/MNI/struct2mni \
    --premat=$WD/spe2struct.mat \
    --out=$WD/speReference_MNI \
    --interp=sinc