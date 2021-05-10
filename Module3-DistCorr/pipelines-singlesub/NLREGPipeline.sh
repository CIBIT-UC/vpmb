#!/bin/bash

# Pipeline for single subject/run correction of functional data using non linear registration

# Requirements for this script
#  installed versions of: FSL
#  environment: FSLDIR

# --------------------------------------------------------------------------------
#  Settings
# --------------------------------------------------------------------------------

DATADIR="/DATAPOOL/VPMB/VPMB-STCIBIT-V2" # data folder
VPDIR="/SCRATCH/users/alexandresayal/VPMB" # processing folder
subID="VPMBAUS01"                                           # subject ID
taskName="TASK-LOC-1000"                                    # task name
taskDir="${VPDIR}/${subID}/ANALYSIS/${taskName}"            # task directory
fmapDir="${VPDIR}/${subID}/ANALYSIS/${taskName}/FMAP-NLREG"   # fmap directory
WD="${VPDIR}/${subID}/ANALYSIS/${taskName}/FMAP-NLREG/work"   # working directory
t1Dir="${VPDIR}/${subID}/ANALYSIS/T1W"                      # T1w directory
ro_time=0.0415863 # in seconds
nThreads=18 # number of threads

startTime=`date "+%s"`

# --------------------------------------------------------------------------------
#  Create/Clean folder
# --------------------------------------------------------------------------------

if [ ! -e $WD ] ; then # not exists
    mkdir -p $WD
    echo "--> FMAP-NLREG/work folder created."
elif [ "$(ls -A ${WD})" ] ; then # not empty
    rm -r ${WD}/*
    echo "--> FMAP-NLREG/work folder cleared."
else
    echo "--> FMAP-NLREG/work folder ready."
fi

# --------------------------------------------------------------------------------
#  Copy files
# --------------------------------------------------------------------------------

# Copy functional data
cp $DATADIR/$subID/RAW/${taskName}/${subID}_${taskName}.nii.gz $WD/func.nii.gz

# Create func01 (first volume of functional data)
fslroi $WD/func.nii.gz $WD/func01.nii.gz 0 1

# Align func01 to T1W_down
epi_reg --epi=$WD/func01.nii.gz \
        --t1=$t1Dir/DOWN/${subID}_T1W_down_restore.nii.gz \
        --t1brain=$t1Dir/DOWN/${subID}_T1W_down_brain_restore.nii.gz \
        --wmseg=$t1Dir/DOWN/${subID}_T1W_down_brain_seg-wm.nii.gz \
        --out=$WD/func012T1W_down -v

# Check
fslview_deprecated $t1Dir/DOWN/${subID}_T1W_down_restore.nii.gz $WD/func012T1W_down.nii.gz &

# Calculate inverse T1W_down2func01
convert_xfm -inverse $WD/func012T1W_down.mat \
            -omat $WD/T1W_down2func01.mat

# Create brain mask in func01 space
flirt -ref $WD/func01.nii.gz \
      -in $t1Dir/DOWN/${subID}_T1W_down_brain_mask.nii.gz \
      -out $WD/T1W_down_brain_mask2func01.nii.gz \
      -interp sinc \
      -init $WD/T1W_down2func01.mat \
      -applyxfm -v

# Threshold mask
fslmaths $WD/T1W_down_brain_mask2func01.nii.gz -thr 0.9 $WD/T1W_down_brain_mask2func01.nii.gz

# Apply mask
fslmaths $WD/func01.nii.gz \
        -mas $WD/T1W_down_brain_mask2func01.nii.gz \
        $WD/func01_brain.nii.gz

# Check
fslview_deprecated $WD/func01.nii.gz $WD/func01_brain.nii.gz $WD/T1W_down_brain_mask2func01.nii.gz &

# Create func01_brain2T1W_down
flirt -ref $t1Dir/DOWN/${subID}_T1W_down_brain_restore.nii.gz \
      -in $WD/func01_brain.nii.gz \
      -out $WD/func01_brain2T1W_down.nii.gz \
      -interp sinc \
      -init $WD/func012T1W_down.mat \
      -applyxfm -v

# Invert T1w_down to match func01 intensities

# Intensity range T1W
range_t1w=`fslstats $t1Dir/DOWN/${subID}_T1W_down_brain_restore.nii.gz -R`
range_t1w=(${range_t1w// / }) # split into array

# Intensity range func01
range_func01=`fslstats $WD/func01_brain.nii.gz -R`
range_func01=(${range_func01// / }) # split into array

# Auxialiry math
mul=`echo "-(${range_func01[1]} - ${range_func01[0]}) / (${range_t1w[1]} - ${range_t1w[0]})" | bc -l`

aux=`echo "${range_t1w[1]} * $mul" | bc -l`
aux=${aux#-}

add=`echo "$aux + ${range_func01[0]}" | bc -l`

# Invert and mask
fslmaths $t1Dir/DOWN/${subID}_T1W_down_brain_restore.nii.gz \
        -mul $mul \
        -add $add \
        $WD/T1W_down_inv

fslmaths $WD/T1W_down_inv.nii.gz \
    -mas $t1Dir/DOWN/${subID}_T1W_down_brain_mask \
    $WD/T1W_down_inv.nii.gz

# Check side by side
fslview_deprecated $WD/T1W_down_inv.nii.gz &
fslview_deprecated $WD/func01.nii.gz &

# Non linear registration

antsRegistration \
    --dimensionality 3 \
    --transform SyN[0.1,3,0] \
    --metric CC[$WD/T1W_down_inv.nii.gz,$WD/func01_brain2T1W_down.nii.gz,1,4] \
    --convergence [100x70x50x20,1e-6,10] \
    --shrink-factors 8x4x2x1 \
    --smoothing-sigmas 3x2x1x0.5vox \
    --restrict-deformation 0x1x0 \
    --output [$WD/ants_outputTransform_,$WD/ants_outputWarpedImage.nii.gz] \
    --use-estimate-learning-rate-once 1 \
    --use-histogram-matching 1 \
    --interpolation HammingWindowedSinc \
    --verbose 1

# Check
fslview_deprecated $WD/T1W_down_inv.nii.gz $WD/func012T1W_down.nii.gz $WD/ants_outputWarpedImage.nii.gz &


# Non linear registration + rigid

antsRegistration \
    --dimensionality 3 \
    --transform Rigid[0.1] \
    --metric MI[$WD/T1W_down_inv.nii.gz,$WD/func01_brain.nii.gz,1,32,Regular,0.25] \
    --convergence [1000x500x250x100,1e-6,10] \
    --shrink-factors 8x4x2x1 \
    --smoothing-sigmas 3x2x1x0vox \
    --transform SyN[0.1,3,0] \
    --metric CC[$WD/T1W_down_inv.nii.gz,$WD/func01_brain.nii.gz,1,3] \
    --convergence [70x50x20,1e-6,10] \
    --shrink-factors 4x2x1 \
    --smoothing-sigmas 2x1x0.5vox \
    --restrict-deformation 0x1x0 \
    --output [$WD/ants_outputTransform_,$WD/ants_outputWarpedImagewithRigid.nii.gz] \
    --use-estimate-learning-rate-once 1 \
    --use-histogram-matching 1 \
    --interpolation HammingWindowedSinc \
    --verbose 1

# Check
fslview_deprecated $WD/T1W_down_inv.nii.gz $WD/ants_outputWarpedImagewithRigid.nii.gz &