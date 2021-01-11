#!/bin/bash

# Tests for the register between SPE and funcional data

# Requirements for this script
#  installed versions of: FSL
#  environment: FSLDIR

# --------------------------------------------------------------------------------
#  Define Function
# --------------------------------------------------------------------------------

mainfunction () {
    VPDIR=$1
    outputFileName=$2
    TASKNAME=$3
    subDir=$4

    WD=$subDir
    arrIN=(${WD//'/'/ }) # split strings
    subID=${arrIN[-1]} # retrieve subject ID 
    echo "--- Participant ${subID} ---------------------"

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
    cp $WD/RAW/${TASKNAME}/${subID}_${TASKNAME}.nii.gz $WD/regTests/func.nii.gz

    # copy SPE
    cp $WD/RAW/${TASKNAME}/${subID}_FMAP-SPE-AP.nii.gz $WD/regTests/spe.nii.gz

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

    # Bias field correction
    fast -B $WD/func01_brain.nii.gz &
    fast -B $WD/spe_brain.nii.gz

    # Align func01 to SPE-AP
    flirt -ref $WD/spe_brain_restore.nii.gz \
        -in $WD/func01_brain_restore.nii.gz \
        -out $WD/func2spe.nii.gz \
        -omat $WD/func2spe.mat \
        -cost normmi \
        -interp sinc \
        -dof 6

    # Calculate cost function value
    cost1a=`flirt -in $WD/func01_brain_restore.nii.gz -ref $WD/spe_brain_restore.nii.gz -schedule $FSLDIR/etc/flirtsch/measurecost1.sch -init $WD/func2spe.mat -cost corratio | head -1 | cut -f1 -d' '`
    cost1b=`flirt -in $WD/func01_brain_restore.nii.gz -ref $WD/spe_brain_restore.nii.gz -schedule $FSLDIR/etc/flirtsch/measurecost1.sch -init $WD/func2spe.mat -cost mutualinfo | head -1 | cut -f1 -d' '`

    # --------------------------------------------------------------------------------
    #  Use func01 as reference and then invert
    # --------------------------------------------------------------------------------

    # Align SPE-AP to func01
    flirt -ref $WD/func01_brain_restore.nii.gz \
        -in $WD/spe_brain_restore.nii.gz \
        -out $WD/spe2func.nii.gz \
        -omat $WD/spe2func.mat \
        -cost normmi \
        -interp sinc \
        -dof 6

    # Invert transformation matrix
    convert_xfm -inverse $WD/spe2func.mat \
                -omat $WD/func2speM2.mat

    # Apply inverse transformation matrix to func01
    flirt -ref $WD/spe_brain_restore.nii.gz \
        -in $WD/func01_brain_restore.nii.gz \
        -out $WD/func2speM2.nii.gz \
        -interp sinc \
        -init $WD/func2speM2.mat \
        -applyxfm 
        
    # Calculate cost function value (source https://fsl.fmrib.ox.ac.uk/fsl/fslwiki/FLIRT/FAQ)
    cost2a=`flirt -in $WD/func01_brain_restore.nii.gz -ref $WD/spe_brain_restore.nii.gz -schedule $FSLDIR/etc/flirtsch/measurecost1.sch -init $WD/func2speM2.mat -cost corratio | head -1 | cut -f1 -d' '`
    cost2b=`flirt -in $WD/func01_brain_restore.nii.gz -ref $WD/spe_brain_restore.nii.gz -schedule $FSLDIR/etc/flirtsch/measurecost1.sch -init $WD/func2speM2.mat -cost mutualinfo | head -1 | cut -f1 -d' '`

    # --------------------------------------------------------------------------------
    #  Write to file
    # --------------------------------------------------------------------------------

    printf "%s %s %s %s %s\n" ${subID} ${cost1a} ${cost2a} ${cost1b} ${cost2b}  >> $VPDIR/cost_values_restore.txt



    echo "----------------------------------------------"
} # end function

cleanfunction () {
    VPDIR=$1
    outputFileName=$2
    TASKNAME=$3
    subDir=$4

    WD=$subDir
    arrIN=(${WD//'/'/ }) # split strings
    subID=${arrIN[-1]} # retrieve subject ID 
    echo "--- Participant ${subID} ---------------------"

    # create or clean folder
    if [ -e $WD/regTests ] ; then # not exists
        rm -r $WD/regTests
        echo "--> regTests folder cleared."
    else
        echo "--> regTests folder does not exist."
    fi
}

# --------------------------------------------------------------------------------
#  Define Folders
# --------------------------------------------------------------------------------
VPDIR="/DATAPOOL/VPMB/VPMB-STCIBIT"
TASKNAME="TASK-LOC-1000"
outputFileName="cost_values_restore.txt"

D=`ls -d ${VPDIR}/*/`
printf "subID M1a M2a M1b M2b\n" > $VPDIR/$outputFileName # create file, replacing existing, add header

# Iterate on the subjects
for subDir in $D
do

    #mainfunction $VPDIR $outputFileName $TASKNAME $subDir &
    #cleanfunction $VPDIR $outputFileName $TASKNAME $subDir &

done
wait
echo "--> All subs done."


# --------------------------------------------------------------------------------------------------------------------------------------------------------
# --------------------------------------------------------------------------------------------------------------------------------------------------------
# MANUAL TESTS
# --------------------------------------------------------------------------------------------------------------------------------------------------------
# --------------------------------------------------------------------------------------------------------------------------------------------------------

VPDIR="/DATAPOOL/VPMB/VPMB-STCIBIT"
TASKNAME="TASK-LOC-1000"
subID="VPMBAUS01"

# --------------------------------------------------------------------------------
#  Copy files and Brain Extraction
# --------------------------------------------------------------------------------

# working directory
WD=${VPDIR}/${subID}

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
cp $WD/RAW/${TASKNAME}/${subID}_${TASKNAME}.nii.gz $WD/regTests/func.nii.gz

# copy SPE
cp $WD/RAW/${TASKNAME}/${subID}_FMAP-SPE-AP.nii.gz $WD/regTests/spe.nii.gz

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
fast -B $WD/func01_brain.nii.gz &
fast -B $WD/spe_brain.nii.gz

# Align func01 to SPE-AP
flirt -ref $WD/spe_brain_restore.nii.gz \
      -in $WD/func01_brain_restore.nii.gz \
      -out $WD/func2spe.nii.gz \
      -omat $WD/func2spe.mat \
      -cost normmi \
      -interp sinc \
      -dof 6

# Calculate cost function value (source https://fsl.fmrib.ox.ac.uk/fsl/fslwiki/FLIRT/FAQ)
echo "Cost function=`flirt -in $WD/func01_brain.nii.gz -ref $WD/spe_brain.nii.gz -schedule $FSLDIR/etc/flirtsch/measurecost1.sch -init $WD/func2spe.mat -cost normcorr | head -1 | cut -f1 -d' '`"

# Check alignment visually
fslview_deprecated $WD/spe_brain_restore.nii.gz $WD/func2spe.nii.gz &

# --------------------------------------------------------------------------------
#  Test fake SBRef
# --------------------------------------------------------------------------------

flirt -ref $WD/spe_brain.nii.gz \
      -in $WD/tfMRI_RunA_AP_SMS6_TR1000_SBRef.nii.gz \
      -out $WD/sbref2spe.nii.gz \
      -omat $WD/sbref2spe.mat \
      -cost normmi \
      -interp sinc \
      -dof 6

fslview_deprecated $WD/spe_brain.nii.gz $WD/sbref2spe.nii.gz &



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