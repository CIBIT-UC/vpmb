#!/bin/bash

# Pipeline for single subject/run correction of functional data using Spin-Echo (SPE) fieldmaps

# Requirements for this script
#  installed versions of: FSL
#  environment: FSLDIR

# --------------------------------------------------------------------------------
#  Settings
# --------------------------------------------------------------------------------

VPDIR="/DATAPOOL/VPMB/VPMB-STCIBIT"                         # data folder
subID="VPMBAUS01"                                           # subject ID
taskName="TASK-LOC-1000"                                    # task name
taskDir="${VPDIR}/${subID}/ANALYSIS/${taskName}"            # task directory
fmapDir="${VPDIR}/${subID}/ANALYSIS/${taskName}/FMAP-SPE"   # fmap directory
WD="${VPDIR}/${subID}/ANALYSIS/${taskName}/FMAP-SPE/work"   # working directory
ro_time=0.0415863 # in seconds

# --------------------------------------------------------------------------------
#  Create/Clean folder
# --------------------------------------------------------------------------------

if [ ! -e $WD ] ; then # not exists
    mkdir -p $WD
    echo "--> FMAP-SPE/work folder created."
elif [ "$(ls -A ${WD})" ] ; then # not empty
    rm -r ${WD}/*
    echo "--> FMAP-SPE/work folder cleared."
else
    echo "--> FMAP-SPE/work folder ready."
fi

# --------------------------------------------------------------------------------
#  Copy files and Brain Extraction and Bias field correction
# --------------------------------------------------------------------------------

# Copy functional data and SPEs
cp $VPDIR/$subID/RAW/${taskName}/${subID}_${taskName}.nii.gz $WD/func.nii.gz
cp $VPDIR/$subID/RAW/${taskName}/${subID}_FMAP-SPE-AP.nii.gz $WD/spe-ap.nii.gz
cp $VPDIR/$subID/RAW/${taskName}/${subID}_FMAP-SPE-PA.nii.gz $WD/spe-pa.nii.gz

# Create func01 (first volume of functional data)
fslroi $WD/func.nii.gz $WD/func01.nii.gz 0 1

# BET func01 and SPE
bet2 $WD/func01.nii.gz $WD/funcMask -f 0.3 -n -m     # calculate func01 brain mask
bet2 $WD/spe-ap.nii.gz $WD/spe-apMask -f 0.3 -n -m   # calculate spe-ap brain mask

mv $WD/funcMask_mask.nii.gz $WD/func_brain_mask.nii.gz      # rename func01 brain mask
mv $WD/spe-apMask_mask.nii.gz $WD/spe-ap_brain_mask.nii.gz  # rename spe brain mask

fslmaths $WD/func01.nii.gz -mas $WD/func_brain_mask.nii.gz $WD/func01_brain.nii.gz    # apply func01 brain mask
fslmaths $WD/spe-ap.nii.gz -mas $WD/spe-ap_brain_mask.nii.gz $WD/spe-ap_brain.nii.gz  # apply spe brain mask

# Bias field correction
fast -B $WD/func01_brain.nii.gz &  # output: func01_brain_restore
fast -B $WD/spe-ap_brain.nii.gz    # output: spe_brain_restore

# --------------------------------------------------------------------------------
#  Calculate func2spe and spe2func transformation matrices
# --------------------------------------------------------------------------------

# Align func01 to SPE-AP and export transformation matrix func2spe.mat
flirt -ref $WD/spe-ap_brain_restore.nii.gz \
      -in $WD/func01_brain_restore.nii.gz \
      -out $WD/func2spe.nii.gz \
      -omat $WD/func2spe.mat \
      -cost normmi \
      -interp sinc \
      -dof 6 -v

# Invert transformation matrix
convert_xfm -inverse $WD/func2spe.mat \
            -omat $WD/spe2func.mat

# --------------------------------------------------------------------------------
#  Slice timing correction (ST)
# --------------------------------------------------------------------------------
customSTFile=${VPDIR}/${subID}/ANALYSIS/${taskName}/st_order.txt

slicetimer -i $WD/func.nii.gz -o $WD/func_stc.nii.gz --tcustom=$customSTFile -v

# --------------------------------------------------------------------------------
#  Motion Correction (MC)
# --------------------------------------------------------------------------------

# Align all volumes to the first (func01)
mcflirt -in $WD/func_stc.nii.gz \
        -refvol 0 \
        -o $WD/func_stc_mc \
        -mats -plots -report

# --------------------------------------------------------------------------------
#  Concatenate func2spe and MC matrices for all volumes
# --------------------------------------------------------------------------------

nVols=`fslnvols $WD/func.nii.gz`

for ((vv=0; vv < $nVols; vv++))
do
    convert_xfm -omat $(printf "${WD}/func_stc_mc.mat/CONCAT_%04d" ${vv}) \
                -concat $WD/func2spe.mat $(printf "${WD}/func_stc_mc.mat/MAT_%04d" ${vv}) & # the first transform is mc, so it appears in 2nd place
done
wait

# --------------------------------------------------------------------------------
#  TOPUP - Distortion Correction (DC)
# --------------------------------------------------------------------------------

# Create topup config file
echo "0 -1 0 $ro_time" > $WD/acqparams.txt
echo "0 1 0 $ro_time" >> $WD/acqparams.txt

# Merge SPEs
fslmerge -t ${WD}/speMerge ${WD}/spe-ap.nii.gz ${WD}/spe-pa.nii.gz

# Topup
topup --imain=${WD}/speMerge \
      --datain=$WD/acqparams.txt \
      --config=b02b0.cnf \
      --out=${WD}/Coefficents \
      --dfout=${WD}/WarpField \
      --rbmout=${WD}/MotionMatrix \
      --jacout=${WD}/Jacobian -v

# --------------------------------------------------------------------------------
#  One Step Resampling (apply MC+DC)
# --------------------------------------------------------------------------------

# Create aux folders
if [ ! -e $WD/preVols ] ; then # not exists
    mkdir $WD/preVols
    mkdir $WD/postVols
    echo "--> preVols folder created."
fi

# Iterate on the volumes
for ((vv=0; vv < $nVols; vv++))
do
    (

    # isolate raw functional volume $vv
    fslroi $WD/func_stc.nii.gz $(printf "${WD}/preVols/func_%04d.nii.gz" ${vv}) $vv 1 

    # concatenate transformations for volume $vv
    convertwarp --ref=$WD/func01.nii.gz \
            --out=$(printf "${WD}/preVols/MatrixAll_%04d.nii.gz" ${vv}) \
            --premat=$(printf "${WD}/func_stc_mc.mat/CONCAT_%04d" ${vv}) \
            --warp1=$WD/WarpField_01 \
            --postmat=$WD/spe2func.mat \
            --rel --verbose
    
    # Apply warps (mc + dc)
    applywarp -i $(printf "${WD}/preVols/func_%04d.nii.gz" ${vv}) \
              -o $(printf "${WD}/postVols/func_%04d.nii.gz" ${vv}) \
              -r $WD/func01.nii.gz \
              -w $(printf "${WD}/preVols/MatrixAll_%04d.nii.gz" ${vv}) \
              --interp=sinc

    echo $(printf "Volume %04d of %04d...\n" ${vv} $nVols)

    ) & # infinite parallel power eheheh might result in catastrophic crash in weak systems but not really but who knows

done
wait

# Create string to merge (separately from the paralell cycle above)
VolumeMergeSTRING=""
for ((vv=0; vv < $nVols; vv++))
do
    VolumeMergeSTRING+=$(printf "${WD}/postVols/func_%04d.nii.gz " ${vv})
done

# Merge all volumes again
TR=`fslval ${WD}/func.nii.gz pixdim4 | cut -d " " -f 1`
fslmerge -tr $fmapDir/filtered_func_data.nii.gz $VolumeMergeSTRING $TR

# --------------------------------------------------------------------------------
#  Estimate register to T1w
# --------------------------------------------------------------------------------

# Create aux folders
if [ ! -e $fmapDir/func2struct ] ; then # not exists
    mkdir $fmapDir/func2struct
    echo "--> func2struct folder created."
fi

# Create func01_stc_mc_dc (first volume of corrected functional data)
fslroi $fmapDir/filtered_func_data.nii.gz $WD/func2struct/func01_stc_mc_dc.nii.gz 0 1

epi_reg --epi=${WD}/func01_stc_mc_dc.nii.gz \
        --t1=$VPDIR/$subID/ANALYSIS/T1W/BET/${subID}_T1W.nii.gz \
        --t1brain=$VPDIR/$subID/ANALYSIS/T1W/BET/${subID}_T1W_brain.nii.gz \
        --out=$WD/func2struct/func2struct -v

# --------------------------------------------------------------------------------
#  Clean up
# --------------------------------------------------------------------------------

# To do... :)