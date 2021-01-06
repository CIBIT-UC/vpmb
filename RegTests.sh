#!/bin/bash

# Tests for the register between SPE and funcional data

# Requirements for this script
#  installed versions of: FSL
#  environment: FSLDIR

# --------------------------------------------------------------------------------
#  Define Folders
# --------------------------------------------------------------------------------
VPDIR="/DATAPOOL/VPMB/VPMB-STCIBIT"
#subID="VPMBAUS21"

D=`ls -d ${VPDIR}/*/`
printf "subID M1 M2\n" > $VPDIR/cost_values.txt

for subDir in $D; do

    WD=$subDir
    arrIN=(${WD//'/'/ }) # split strings
    subID=${arrIN[-1]} # retrieve subject ID 
    echo "-- Participant ${subID} ---------------------"

    # create or clean folder
    if [ ! -e $WD/regTests ] ; then # not exists
        mkdir $WD/regTests
        echo "--> regTests folder created."
    elif [ "$(ls -A $WD/regTests)" ] ; then # not empty
        rm -r $WD/regTests/*
        echo "--> regTests folder cleared."
    else
        echo "--> regTests folder ready."
    fi

    # copy functional
    cp $WD/RAW/TASK-LOC-1000/${subID}_TASK-LOC-1000.nii.gz $WD/regTests/func.nii.gz

    # copy SPE
    cp $WD/RAW/TASK-LOC-1000/${subID}_FMAP-SPE-AP.nii.gz $WD/regTests/spe.nii.gz

    # create functional reference
    fslroi $WD/regTests/func.nii.gz $WD/regTests/func01.nii.gz 0 1

    # BET functional reference
    bet2 $WD/regTests/func01.nii.gz $WD/regTests/funcMask -f 0.3 -n -m # calculate mask
    mv $WD/regTests/funcMask_mask.nii.gz $WD/regTests/func_brain_mask.nii.gz # rename mask
    fslmaths $WD/regTests/func01.nii.gz -mas $WD/regTests/func_brain_mask.nii.gz $WD/regTests/func01_brain.nii.gz # apply mask

    # BET SPE
    bet2 $WD/regTests/spe.nii.gz $WD/regTests/speMask -f 0.3 -n -m # calculate mask
    mv $WD/regTests/speMask_mask.nii.gz $WD/regTests/spe_brain_mask.nii.gz # rename mask
    fslmaths $WD/regTests/spe.nii.gz -mas $WD/regTests/spe_brain_mask.nii.gz $WD/regTests/spe_brain.nii.gz # apply mask

    # Change working directory
    WD=${subDir}/regTests

    # --------------------------------------------------------------------------------
    #  Use SPE-AP as reference
    # --------------------------------------------------------------------------------

    # Align func01 to SPE-AP
    flirt -ref $WD/spe_brain.nii.gz \
        -in $WD/func01_brain.nii.gz \
        -out $WD/func2spe.nii.gz \
        -omat $WD/func2spe.mat \
        -interp spline \
        -dof 6

    # Calculate cost function value
    cost1=`flirt -in $WD/func01_brain.nii.gz -ref $WD/spe_brain.nii.gz -schedule $FSLDIR/etc/flirtsch/measurecost1.sch -init $WD/func2spe.mat | head -1 | cut -f1 -d' '`

    # --------------------------------------------------------------------------------
    #  Use func01 as reference and then invert
    # --------------------------------------------------------------------------------

    # Align SPE-AP to func01
    flirt -ref $WD/func01_brain.nii.gz \
        -in $WD/spe_brain.nii.gz \
        -out $WD/spe2func.nii.gz \
        -omat $WD/spe2func.mat \
        -interp sinc \
        -dof 6

    # Invert transformation matrix
    convert_xfm -inverse $WD/spe2func.mat \
                -omat $WD/func2spe.mat

    # Apply inverse transformation matrix to func01
    flirt -ref $WD/spe_brain.nii.gz \
        -in $WD/func01_brain.nii.gz \
        -out $WD/func2spe.nii.gz \
        -interp sinc \
        -init $WD/func2spe.mat \
        -applyxfm 
        
    # Calculate cost function value (source https://fsl.fmrib.ox.ac.uk/fsl/fslwiki/FLIRT/FAQ)
    cost2=`flirt -in $WD/func01_brain.nii.gz -ref $WD/spe_brain.nii.gz -schedule $FSLDIR/etc/flirtsch/measurecost1.sch -init $WD/func2spe.mat | head -1 | cut -f1 -d' '`

    # --------------------------------------------------------------------------------
    #  Write to file
    # --------------------------------------------------------------------------------

    printf "%s %s %s\n" ${subID} ${cost1} ${cost2}  >> $VPDIR/cost_values.txt



    echo "---------------------------------------------"
done

# --------------------------------------------------------------------------------
#  Copy files and Brain Extraction
# --------------------------------------------------------------------------------

# working directory
#WD=${VPDIR}/${subID}

# create or clean folder
if [ ! -e $WD/regTests ] ; then # not exists
    mkdir $WD/regTests
    echo "--> regTests folder created."
elif [ "$(ls -A $WD/regTests)" ] ; then # not empty
    rm -r $WD/regTests/*
    echo "--> regTests folder cleared."
else
    echo "--> regTests folder ready."
fi

# copy functional
cp $WD/RAW/TASK-LOC-1000/${subID}_TASK-LOC-1000.nii.gz $WD/regTests/func.nii.gz

# copy SPE
cp $WD/RAW/TASK-LOC-1000/${subID}_FMAP-SPE-AP.nii.gz $WD/regTests/spe.nii.gz

# create functional reference
fslroi $WD/regTests/func.nii.gz $WD/regTests/func01.nii.gz 0 1

# BET functional reference
bet2 $WD/regTests/func01.nii.gz $WD/regTests/funcMask -f 0.3 -n -m # calculate mask
mv $WD/regTests/funcMask_mask.nii.gz $WD/regTests/func_brain_mask.nii.gz # rename mask
fslmaths $WD/regTests/func01.nii.gz -mas $WD/regTests/func_brain_mask.nii.gz $WD/regTests/func01_brain.nii.gz # apply mask

# BET SPE
bet2 $WD/regTests/spe.nii.gz $WD/regTests/speMask -f 0.3 -n -m # calculate mask
mv $WD/regTests/speMask_mask.nii.gz $WD/regTests/spe_brain_mask.nii.gz # rename mask
fslmaths $WD/regTests/spe.nii.gz -mas $WD/regTests/spe_brain_mask.nii.gz $WD/regTests/spe_brain.nii.gz # apply mask

# Change working directory
WD=${VPDIR}/${subID}/regTests

# --------------------------------------------------------------------------------
#  Use SPE-AP as reference
# --------------------------------------------------------------------------------

# Bias field correction
# fast -B $WD/func01_brain.nii.gz
# fast -B $WD/spe_brain.nii.gz 

# Align func01 to SPE-AP
flirt -ref $WD/spe_brain.nii.gz \
      -in $WD/func01_brain.nii.gz \
      -out $WD/func2spe.nii.gz \
      -omat $WD/func2spe.mat \
      -interp spline \
      -dof 6

# Calculate cost function value (source https://fsl.fmrib.ox.ac.uk/fsl/fslwiki/FLIRT/FAQ)
echo "Cost function=`flirt -in $WD/func01_brain.nii.gz -ref $WD/spe_brain.nii.gz -schedule $FSLDIR/etc/flirtsch/measurecost1.sch -init $WD/func2spe.mat | head -1 | cut -f1 -d' '`"

# Check alignment visually
# fslview_deprecated $WD/spe_brain.nii.gz $WD/func2spe.nii.gz &


# --------------------------------------------------------------------------------
#  Use func01 as reference and then invert
# --------------------------------------------------------------------------------

# Align SPE-AP to func01
flirt -ref $WD/func01_brain.nii.gz \
      -in $WD/spe_brain.nii.gz \
      -out $WD/spe2func.nii.gz \
      -omat $WD/spe2func.mat \
      -interp sinc \
      -dof 6

# Invert transformation matrix
convert_xfm -inverse $WD/spe2func.mat \
            -omat $WD/func2spe.mat

# Apply inverse transformation matrix to func01
flirt -ref $WD/spe_brain.nii.gz \
      -in $WD/func01_brain.nii.gz \
      -out $WD/func2spe.nii.gz \
      -interp sinc \
      -init $WD/func2spe.mat \
      -applyxfm 
      
# Calculate cost function value (source https://fsl.fmrib.ox.ac.uk/fsl/fslwiki/FLIRT/FAQ)
echo "Cost function=`flirt -in $WD/func01_brain.nii.gz -ref $WD/spe_brain.nii.gz -schedule $FSLDIR/etc/flirtsch/measurecost1.sch -init $WD/func2spe.mat | head -1 | cut -f1 -d' '`"

# Check alignment visually
# fslview_deprecated $WD/spe_brain.nii.gz $WD/func2spe.nii.gz &