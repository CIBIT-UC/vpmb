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

# copy functional and SPEs
cp $VPDIR/$subID/RAW/${taskName}/${subID}_${taskName}.nii.gz $WD/func.nii.gz &
cp $VPDIR/$subID/RAW/${taskName}/${subID}_FMAP-SPE-AP.nii.gz $WD/spe-ap.nii.gz &
cp $VPDIR/$subID/RAW/${taskName}/${subID}_FMAP-SPE-PA.nii.gz $WD/spe-pa.nii.gz

# create func01 (first volume of functional data)
fslroi $WD/func.nii.gz $WD/func01.nii.gz 0 1

# BET func01 and SPE
bet2 $WD/func01.nii.gz $WD/funcMask -f 0.3 -n -m &   # calculate func01 mask
bet2 $WD/spe-ap.nii.gz $WD/spe-apMask -f 0.3 -n -m   # calculate spe-ap mask

mv $WD/funcMask_mask.nii.gz $WD/func_brain_mask.nii.gz &    # rename func01 mask
mv $WD/spe-apMask_mask.nii.gz $WD/spe-ap_brain_mask.nii.gz  # rename spe mask

fslmaths $WD/func01.nii.gz -mas $WD/func_brain_mask.nii.gz $WD/func01_brain.nii.gz &  # apply func01 mask
fslmaths $WD/spe-ap.nii.gz -mas $WD/spe-ap_brain_mask.nii.gz $WD/spe-ap_brain.nii.gz  # apply spe mask

# Bias field correction
fast -B $WD/func01_brain.nii.gz &  # output: func01_brain_restore
fast -B $WD/spe-ap_brain.nii.gz    # output: spe_brain_restore

# Clean up
# not yet...

# --------------------------------------------------------------------------------
#  Using SPE-AP as reference (scout)
# --------------------------------------------------------------------------------

# Align func01 to SPE-AP and export transformation matrix func2spe.mat
flirt -ref $WD/spe-ap_brain_restore.nii.gz \
      -in $WD/func01_brain_restore.nii.gz \
      -out $WD/func2spe.nii.gz \
      -omat $WD/func2spe.mat \
      -cost normmi \
      -interp sinc \
      -dof 6

# --------------------------------------------------------------------------------
#  Motion Correction
# --------------------------------------------------------------------------------

# Align all volumes to the first (func01)
mcflirt -in $WD/func.nii.gz \
        -refvol 0 \
        -o $WD/func_mc \
        -sinc_final \
        -mats -plots

# Concatenate func2spe and mc matrices for all volumes
nVols=$((`fslnvols $WD/func.nii.gz`-1))

for vv in $(eval echo "{0..$nVols}")
do
    convert_xfm -omat $(printf "${WD}/func_mc.mat/CONCAT_%04d" ${vv}) \
                -concat $WD/func2spe.mat $(printf "${WD}/func_mc.mat/MAT_%04d" ${vv}) & # the first transform is mc, so it appears in 2nd place
done
wait

# Align all volumes to SPE (using sinc interp)
applyxfm4D $WD/func.nii.gz $WD/spe-ap.nii.gz $WD/func_mc2spe $WD/func_mc.mat -userprefix CONCAT_

# Check visually
fslview_deprecated $WD/spe-ap_brain_restore.nii.gz $WD/func_mc2spe.nii.gz &

# Rename
# Maybe rename func_mc2spe...?

# Clean up
# not yet...

# --------------------------------------------------------------------------------
#  TOPUP
# --------------------------------------------------------------------------------

# Create config file - this will depend on the TR - TO DO
ro_time=0.0415863
echo "0 -1 0 $ro_time" > $WD/acqparams.txt
echo "0 1 0 $ro_time" >> $WD/acqparams.txt

# Merge SPEs
fslmerge -t ${WD}/speMerge ${WD}/spe-ap.nii.gz ${WD}/spe-pa.nii.gz

# Topup
topup --imain=${WD}/speMerge \
      --datain=$WD/acqparams.txt \
      --config=b02b0.cnf \
      --out=${WD}/Coefficents \
      --iout=${WD}/Magnitudes \
      --fout=${WD}/TopupField \
      --dfout=${WD}/WarpField \
      --rbmout=${WD}/MotionMatrix \
      --jacout=${WD}/Jacobian -v

# Apply topup
applytopup --imain=$WD/func_mc2spe.nii.gz \
           --datain=$WD/acqparams.txt \
           --inindex=1 \
           --topup=${WD}/Coefficents \
           --out=$WD/func_mc_dc2spe.nii.gz \
           --method=jac

# Check visually
fslview_deprecated $WD/func_mc2spe.nii.gz $WD/func_mc_dc2spe.nii.gz &

# Calculate Equivalent Field Map
fslmaths ${WD}/TopupField -mul 6.283 ${WD}/GREfromTOPUP-PHASE
fslmaths ${WD}/Magnitudes -Tmean ${WD}/GREfromTOPUP-MAGNITUDE
bet ${WD}/GREfromTOPUP-MAGNITUDE ${WD}/GREfromTOPUP-MAGNITUDE_brain -f 0.35 -m #Brain extract the magnitude image

# Check visually
fslview_deprecated ${WD}/GREfromTOPUP-MAGNITUDE_brain ${WD}/GREfromTOPUP-PHASE &

# --------------------------------------------------------------------------------
#  func to corrected func
# --------------------------------------------------------------------------------