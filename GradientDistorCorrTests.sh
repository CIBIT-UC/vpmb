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