#!/bin/bash

# Pipeline for single subject/run correction of functional data using Spin-Echo (SPE) fieldmaps

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
WD="${VPDIR}/${subID}/ANALYSIS/${taskName}/FMAP-SPE/work"   # working directory
ro_time=0.0415863 # in seconds
nThreads=36 # number of threads

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
#  Gradient Unwarp Correction (GDC)
# --------------------------------------------------------------------------------

# Define functions
opts_GetOpt1() {
    sopt="$1"
    shift 1
    for fn in "$@" ; do
    if [ `echo $fn | grep -- "^${sopt}=" | wc -w` -gt 0 ] ; then
        echo "$fn" | sed "s/^${sopt}=//"
        return 0
    fi
    done
}

gradientUnwarp(){

    # Inputs
    WD=`opts_GetOpt1 "--wd" $@`
    InputFile=`opts_GetOpt1 "--in" $@`
    InputCoefficients=`opts_GetOpt1 "--coeff" $@`
    OutputFile=`opts_GetOpt1 "--out" $@`

    # Basename
    BaseName=`remove_ext $InputFile`
    BaseName=`basename $BaseName`

    # Output
    OutputFile=`${FSLDIR}/bin/remove_ext ${OutputFile}`
    OutputTransform=${OutputFile}_warp.nii.gz
    OutputTransformFile=${OutputFile}_warp

    # Extract first volume and run gradient distortion correction on this (all others follow suit as scanner coordinate system is unchanged, even with subject motion)
    fslroi ${InputFile} $WD/${BaseName}_vol1.nii.gz 0 1

    # move (temporarily) into the working directory as gradient_unwarp.py outputs some files directly into pwd
    InputCoeffs=`${FSLDIR}/bin/fsl_abspath $InputCoefficients`
    ORIGDIR=`pwd`
    cd $WD
    echo "gradient_unwarp.py ${BaseName}_vol1.nii.gz trilinear.nii.gz siemens -g ${InputCoeffs} -n"
    # NB: gradient_unwarp.py *must* have the filename extensions written out explicitly or it will crash
    gradient_unwarp.py ${BaseName}_vol1.nii.gz trilinear.nii.gz siemens -g $InputCoeffs -n
    cd $ORIGDIR

    # Now create an appropriate warpfield output (relative convention) and apply it to all timepoints
    #convertwarp's jacobian output has 8 frames, each combination of one-sided differences, so average them
    ${FSLDIR}/bin/convertwarp \
        --abs \
        --ref=$WD/trilinear.nii.gz \
        --warp1=$WD/fullWarp_abs.nii.gz \
        --relout \
        --out=$OutputTransform \
        --jacobian=${OutputTransformFile}_jacobian

    ${FSLDIR}/bin/fslmaths ${OutputTransformFile}_jacobian -Tmean ${OutputTransformFile}_jacobian

    ${FSLDIR}/bin/applywarp \
        --rel \
        --interp=sinc \
        -i $InputFile \
        -r $WD/${BaseName}_vol1.nii.gz \
        -w $OutputTransform \
        -o $OutputFile

    #QA
    applywarp --rel --interp=trilinear -i $InputFile -r $WD/${BaseName}_vol1.nii.gz -w $OutputTransform -o $WD/qa_aw_tri
    fslmaths $WD/qa_aw_tri -sub $WD/trilinear $WD/diff_tri
    echo `fslstats $WD/diff_tri -a -P 100 -M`

    # Apply Jacobian and replace
    fslmaths $OutputFile -mul ${OutputTransformFile}_jacobian $OutputFile

    # Make a dilated mask in the distortion corrected space
    fslmaths $OutputFile -abs -bin -dilD -Tmin ${OutputFile}_mask
    
    applywarp \
        --rel \
        --interp=sinc \
        -i ${OutputFile}_mask \
        -r ${OutputFile}_mask \
        -w $OutputTransform \
        -o ${WD}/${BaseName}_mask_gdc

}

# Correct SPE-AP
gradientUnwarp \
    --wd=$WD \
    --in=${WD}/spe-ap.nii.gz \
    --coeff=/DATAPOOL/VPMB/GradientCoil/coeff.grad \
    --out=${WD}/spe-ap_gdc

# Correct SPE-PA
gradientUnwarp \
    --wd=$WD \
    --in=${WD}/spe-pa.nii.gz \
    --coeff=/DATAPOOL/VPMB/GradientCoil/coeff.grad \
    --out=${WD}/spe-pa_gdc    

# Make a conservative (eroded) intersection of the two masks
fslmaths ${WD}/spe-ap_mask_gdc -mas ${WD}/spe-pa_mask_gdc -ero -bin ${WD}/speMask

# Merge SPEs (AP image first)
fslmerge -t ${WD}/speMerge ${WD}/spe-ap_gdc ${WD}/spe-pa_gdc

# Extrapolate the existing values beyond the mask (adding 1 just to avoid smoothing inside the mask)
${FSLDIR}/bin/fslmaths \
    ${WD}/speMerge \
    -abs -add 1 -mas ${WD}/speMask -dilM -dilM -dilM -dilM -dilM \
    ${WD}/speMerge

# Check
# fslview_deprecated ${WD}/speMerge ${WD}/speMask &

# --------------------------------------------------------------------------------
#  TOPUP - Distortion Correction (DC)
# --------------------------------------------------------------------------------

# Create topup config file
echo "0 -1 0 $ro_time" > $WD/acqparams.txt
echo "0 1 0 $ro_time" >> $WD/acqparams.txt

# Merge SPEs (AP image first)
# fslmerge -t ${WD}/speMerge ${WD}/spe-ap.nii.gz ${WD}/spe-pa.nii.gz

# Create mask (Single volume containing all 1's)
# fslmaths ${WD}/speMerge -mul 0 -add 1 -Tmin ${WD}/speMask

# Extrapolate the existing values beyond the mask (adding 1 just to avoid smoothing inside the mask)
# ${FSLDIR}/bin/fslmaths ${WD}/speMerge \
#     -abs -add 1 \
#     -mas ${WD}/speMask \
#     -dilM -dilM -dilM -dilM -dilM \
#     ${WD}/speMerge

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

# Jacobian to func space
flirt -ref $WD/func01.nii.gz \
      -in $WD/Jacobian_01.nii.gz \
      -out $WD/Jacobian2func.nii.gz \
      -interp sinc \
      -init $WD/spe2func.mat \
      -applyxfm -v

# Calculate Equivalent Field Map (magnitude+phase)
fslmaths ${WD}/TopupField -mul 6.283 ${WD}/GREfromTOPUP-PHASE
fslmaths ${WD}/Magnitudes -Tmean ${WD}/GREfromTOPUP-MAGNITUDE
bet ${WD}/GREfromTOPUP-MAGNITUDE ${WD}/GREfromTOPUP-MAGNITUDE_brain -f 0.4 -m #Brain extract the magnitude image

# --------------------------------------------------------------------------------
#  Apply correction to SPE images (QA)
# --------------------------------------------------------------------------------

# AP
${FSLDIR}/bin/applywarp \
    --rel \
    --interp=sinc \
    -i ${WD}/spe-ap \
    -r ${WD}/speMask \
    --premat=${WD}/MotionMatrix_01.mat \
    -w ${WD}/WarpField_01 \
    -o ${WD}/spe-ap_dc

${FSLDIR}/bin/fslmaths \
    ${WD}/spe-ap_dc \
    -mul ${WD}/Jacobian_01 \
    ${WD}/spe-ap_dc_jac

# PA
${FSLDIR}/bin/applywarp \
    --rel \
    --interp=sinc \
    -i ${WD}/spe-pa \
    -r ${WD}/speMask \
    --premat=${WD}/MotionMatrix_02.mat \
    -w ${WD}/WarpField_02 \
    -o ${WD}/spe-pa_dc

${FSLDIR}/bin/fslmaths \
    ${WD}/spe-pa_dc \
    -mul ${WD}/Jacobian_02 \
    ${WD}/spe-pa_dc_jac

# check visually
fslview_deprecated ${WD}/spe-ap_dc_jac ${WD}/spe-pa_dc_jac &

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
    
    # concatenate func2spe and MC matrices (linear)
    convert_xfm -omat $(printf "${WD}/func_stc_mc.mat/CONCAT_%04d" ${vv}) \
                -concat $WD/func2spe.mat $(printf "${WD}/func_stc_mc.mat/MAT_%04d" ${vv})

    # isolate raw functional volume $vv
    fslroi $WD/func_stc.nii.gz $(printf "${WD}/preVols/func_%04d.nii.gz" ${vv}) $vv 1 

    # concatenate transformations for volume $vv (linear+nonlinear)
    convertwarp --ref=$WD/func01.nii.gz \
            --out=$(printf "${WD}/preVols/MatrixAll_%04d.nii.gz" ${vv}) \
            --premat=$(printf "${WD}/func_stc_mc.mat/CONCAT_%04d" ${vv}) \
            --warp1=$WD/WarpField_01 \
            --postmat=$WD/spe2func.mat \
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
         -div ${WD}/postVols/func_0000_brain_bias.nii.gz \
         -mul $WD/Jacobian2func.nii.gz \
         -mas ${WD}/postVols/func_0000_mask.nii.gz \
         ${WD}/func_stc_mc_dc_brain_restore_jac.nii.gz

# --------------------------------------------------------------------------------
#  Export
# --------------------------------------------------------------------------------

cp ${WD}/func_stc_mc_dc_brain_restore_jac.nii.gz $fmapDir/filtered_func_data.nii.gz

# --------------------------------------------------------------------------------
#  Clean up
# --------------------------------------------------------------------------------

# To do... :)
# rm -r $WD




fsleyes $WD/spe-ap.nii.gz $WD/spe-ap_gdc.ni.gz &

gradientUnwarp $WD ${WD}/spe-pa.nii.gz /DATAPOOL/VPMB/GradientCoil/coeff.grad ${WD}/spe-pa_gdc ${WD}/spe-pa_gdc_warp

fsleyes $WD/spe-pa.nii.gz $WD/spe-pa_gdc.nii.gz &

# Make a conservative (eroded) intersection of the two masks
fslmaths ${WD}/spe-ap_mask_gdc -mas ${WD}/spe-pa_mask_gdc -ero -bin ${WD}/speMask_gdc

# Merge both sets of images
fslmerge -t ${WD}/speMerge_gdc ${WD}/spe-ap_gdc ${WD}/spe-pa_gdc

# check
fsleyes ${WD}/speMerge ${WD}/speMerge_gdc &

# Extrapolate the existing values beyond the mask (adding 1 just to avoid smoothing inside the mask)
${FSLDIR}/bin/fslmaths ${WD}/speMerge_gdc \
    -abs -add 1 -mas ${WD}/speMask_gdc -dilM -dilM -dilM -dilM -dilM ${WD}/speMerge_gdc2

# check
fslview_deprecated ${WD}/speMerge ${WD}/speMerge_gdc ${WD}/speMerge_gdc2 &
