#!/bin/bash

# Pipeline for single subject/run correction of functional data using GRE-EPI fieldmaps

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
fmapDir="${VPDIR}/${subID}/ANALYSIS/${taskName}/FMAP-EPI"   # fmap directory
WD="${VPDIR}/${subID}/ANALYSIS/${taskName}/FMAP-EPI/work"   # working directory
t1Dir="${VPDIR}/${subID}/ANALYSIS/T1W"                      # T1w directory
ro_time=0.0415863 # in seconds
nThreads=18 # number of threads

startTime=`date "+%s"`

# --------------------------------------------------------------------------------
#  Create/Clean folder
# --------------------------------------------------------------------------------

if [ ! -e $WD ] ; then # not exists
    mkdir -p $WD
    echo "--> FMAP-EPI/work folder created."
elif [ "$(ls -A ${WD})" ] ; then # not empty
    rm -r ${WD}/*
    echo "--> FMAP-EPI/work folder cleared."
else
    echo "--> FMAP-EPI/work folder ready."
fi

# --------------------------------------------------------------------------------
#  Copy files and Brain Extraction and Bias field correction
# --------------------------------------------------------------------------------

# Copy functional data and EPIs
cp $VPDIR/$subID/RAW/${taskName}/${subID}_${taskName}.nii.gz $WD/func.nii.gz
cp $VPDIR/$subID/RAW/${taskName}/${subID}_FMAP-EPI-AP.nii.gz $WD/epi-ap.nii.gz
cp $VPDIR/$subID/RAW/${taskName}/${subID}_FMAP-EPI-PA.nii.gz $WD/epi-pa.nii.gz

# Extract last volume of EPIs
fslroi $WD/epi-ap.nii.gz $WD/epi-ap.nii.gz 9 1
fslroi $WD/epi-pa.nii.gz $WD/epi-pa.nii.gz 9 1

# Create func01 (first volume of functional data)
fslroi $WD/func.nii.gz $WD/func01.nii.gz 0 1

# --------------------------------------------------------------------------------
#  Calculate func2epi and epi2func transformation matrices
# --------------------------------------------------------------------------------

# Align func01 to EPI-AP and export transformation matrix func2epi.mat
flirt -ref $WD/epi-ap.nii.gz \
      -in $WD/func01.nii.gz \
      -out $WD/func012epi.nii.gz \
      -omat $WD/func2epi.mat \
      -cost normmi \
      -interp sinc \
      -dof 6 -v

# Invert transformation matrix
convert_xfm -inverse $WD/func2epi.mat \
            -omat $WD/epi2func.mat

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
#  TOPUP - Distortion Correction (DC)
# --------------------------------------------------------------------------------

# Create topup config file
echo "0 -1 0 $ro_time" > $WD/acqparams.txt
echo "0 1 0 $ro_time" >> $WD/acqparams.txt

# Merge EPIs (AP image first)
fslmerge -t ${WD}/epiMerge ${WD}/epi-ap.nii.gz ${WD}/epi-pa.nii.gz

# Create mask (Single volume containing all 1's)
fslmaths ${WD}/epiMerge -mul 0 -add 1 -Tmin ${WD}/epiMask

# Topup
topup --imain=${WD}/epiMerge \
      --datain=$WD/acqparams.txt \
      --config=b02b0.cnf \
      --out=${WD}/Coefficents \
      --iout=${WD}/Magnitudes \
      --fout=${WD}/TopupField \
      --dfout=${WD}/WarpField \
      --rbmout=${WD}/MotionMatrix \
      --jacout=${WD}/Jacobian -v

# Jacobian to func space
flirt -ref $WD/func01.nii.gz \
      -in $WD/Jacobian_01.nii.gz \
      -out $WD/Jacobian2func.nii.gz \
      -interp sinc \
      -init $WD/epi2func.mat \
      -applyxfm -v

# Calculate Equivalent Field Map (magnitude+phase)
fslmaths ${WD}/TopupField -mul 6.283 ${WD}/GREfromTOPUP-Phase
fslmaths ${WD}/Magnitudes -Tmean ${WD}/GREfromTOPUP-Magnitude
bet ${WD}/GREfromTOPUP-Magnitude ${WD}/GREfromTOPUP-Magnitude_brain -f 0.4 -m #Brain extract the magnitude image

# --------------------------------------------------------------------------------
#  Apply correction to EPI images (QA)
# --------------------------------------------------------------------------------

# AP
${FSLDIR}/bin/applywarp \
    --rel \
    --interp=sinc \
    -i ${WD}/epi-ap \
    -r ${WD}/epiMask \
    --premat=${WD}/MotionMatrix_01.mat \
    -w ${WD}/WarpField_01 \
    -o ${WD}/epi-ap_dc

${FSLDIR}/bin/fslmaths \
    ${WD}/epi-ap_dc \
    -mul ${WD}/Jacobian_01 \
    ${WD}/epi-ap_dc_jac

# PA
${FSLDIR}/bin/applywarp \
    --rel \
    --interp=sinc \
    -i ${WD}/epi-pa \
    -r ${WD}/epiMask \
    --premat=${WD}/MotionMatrix_02.mat \
    -w ${WD}/WarpField_02 \
    -o ${WD}/epi-pa_dc

${FSLDIR}/bin/fslmaths \
    ${WD}/epi-pa_dc \
    -mul ${WD}/Jacobian_02 \
    ${WD}/epi-pa_dc_jac

# check visually
fsleyes $WD/Magnitudes ${WD}/epi-ap_dc_jac ${WD}/epi-pa_dc_jac &

# --------------------------------------------------------------------------------
#  One Step Resampling (apply MC+DC)
# --------------------------------------------------------------------------------

# Create aux folders
if [ ! -e $WD/preVols ] ; then # not exists
    mkdir $WD/preVols
    mkdir $WD/postVols
    echo "--> preVols folder created."
fi

# Save number of volumes
nVols=`fslnvols $WD/func.nii.gz`

# Iterate on the volumes
for ((vv=0; vv < $nVols; vv++))
do

    (
    
    # concatenate func2epi and MC matrices (linear)
    convert_xfm -omat $(printf "${WD}/func_stc_mc.mat/CONCAT_%04d" ${vv}) \
                -concat $WD/func2epi.mat $(printf "${WD}/func_stc_mc.mat/MAT_%04d" ${vv})

    # isolate raw functional volume $vv
    fslroi $WD/func_stc.nii.gz $(printf "${WD}/preVols/func_%04d.nii.gz" ${vv}) $vv 1 

    # concatenate transformations for volume $vv (linear+nonlinear)
    convertwarp --ref=$WD/func01.nii.gz \
            --out=$(printf "${WD}/preVols/MatrixAll_%04d.nii.gz" ${vv}) \
            --premat=$(printf "${WD}/func_stc_mc.mat/CONCAT_%04d" ${vv}) \
            --warp1=$WD/WarpField_01 \
            --postmat=$WD/epi2func.mat \
            --rel --verbose
    
    # apply warps (mc + dc)
    applywarp -i $(printf "${WD}/preVols/func_%04d.nii.gz" ${vv}) \
              -o $(printf "${WD}/postVols/func_%04d.nii.gz" ${vv}) \
              -r $WD/func01.nii.gz \
              -w $(printf "${WD}/preVols/MatrixAll_%04d.nii.gz" ${vv}) \
              --interp=sinc

    echo $(printf "Volume %04d of %04d...\n" ${vv} $nVols)

    ) & # parallel power

    # allow to execute up to $nThreads jobs in parallel
    if [[ $(jobs -r -p | wc -l) -ge $nThreads ]]; then
        # now there are $nThreads jobs already running, so wait here for any job
        # to be finished so there is a place to start next one.
        wait -n
    fi

done
wait

# Create string of all volumes to merge (separately from the paralell cycle above)
VolumeMergeSTRING=""
for ((vv=0; vv < $nVols; vv++))
do
    VolumeMergeSTRING+=$(printf "${WD}/postVols/func_%04d.nii.gz " ${vv})
done

# Merge all volumes again
TR=`fslval ${WD}/func.nii.gz pixdim4 | cut -d " " -f 1`
fslmerge -tr $WD/func_stc_mc_dc.nii.gz $VolumeMergeSTRING $TR

# --------------------------------------------------------------------------------
#  BET, Bias field correction, Jacobian modulation
# --------------------------------------------------------------------------------

# BET 1st volume
bet2 ${WD}/postVols/func_0000.nii.gz\
     ${WD}/postVols/func_0000 -f 0.3 -m -n

# Apply BET to 1st volume
fslmaths ${WD}/postVols/func_0000.nii.gz \
         -mas ${WD}/postVols/func_0000_mask.nii.gz \
         ${WD}/postVols/func_0000_brain.nii.gz

# Estimate bias field
fast -b ${WD}/postVols/func_0000_brain.nii.gz

# Apply BET, bias field, and Jacobian modulation to func
fslmaths $WD/func_stc_mc_dc.nii.gz \
        -mul $WD/Jacobian2func.nii.gz \
        -mas ${WD}/postVols/func_0000_mask.nii.gz \
        -div ${WD}/postVols/func_0000_brain_bias.nii.gz \
        ${WD}/func_stc_mc_dc_jac_brain_restore.nii.gz

# --------------------------------------------------------------------------------
#  Export
# --------------------------------------------------------------------------------

cp ${WD}/func_stc_mc_dc_jac_brain_restore.nii.gz $fmapDir/filtered_func_data.nii.gz

# --------------------------------------------------------------------------------
#  Register corrected func to T1w
# --------------------------------------------------------------------------------

# Create func01_processed (first volume of corrected functional data)
fslroi ${WD}/func_stc_mc_dc_jac_brain_restore.nii.gz $WD/func01_processed.nii.gz 0 1

# Estimate registration
epi_reg --epi=$WD/func01_processed.nii.gz \
        --t1=${t1Dir}/FAST/${subID}_T1W_restore \
        --t1brain=${t1Dir}/FAST/${subID}_T1W_brain_restore \
        --wmseg=${t1Dir}/FAST/${subID}_T1W_brain_wmseg \
        --out=$WD/func2struct -v

# Check visually
fsleyes ${t1Dir}/FAST/${subID}_T1W_restore.nii.gz ${WD}/func2struct.nii.gz ${WD}/func2struct_fast_wmedge.nii.gz &

# --------------------------------------------------------------------------------
#  Elapsed time
# --------------------------------------------------------------------------------

endTime="`date "+%s"`"
elapsedTime=$(($endTime - $startTime))
((sec=elapsedTime%60, elapsedTime/=60, min=elapsedTime%60, hrs=elapsedTime/60))
echo "---> ELAPSED TIME $(printf "%d:%02d:%02d" $hrs $min $sec)"
