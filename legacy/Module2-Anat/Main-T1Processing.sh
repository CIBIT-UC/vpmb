#!/bin/bash

# Pipeline for T1 data processing for all subjects

# Steps
# - Copy T1 files to SCRATCH and make folders
# - Brain Extraction with ANTs
# - Bias field and segmentation with FAST
# - Registration to MNI with antsRegistrationSyN.sh

# Outputs
# - ${subID}_T1W_brain
# - ${subID}_T1W_brain_mask
# - ${subID}_T1W_brain_bias.nii.gz
# - ${subID}_T1W_brain_restore.nii.gz
# - ${subID}_T1W_restore.nii.gz
# - ${subID}_T1W_MNI.nii.gz
# - struct2mni.nii.gz

# Requirements for this script
#  installed versions of: FSL, ANTS
#  environment: FSLDIR

# screen -L -Logfile t1tomniMain-logfile.txt -S t1tomni

# --------------------------------------------------------------------------------
#  Setup
# --------------------------------------------------------------------------------

subList="VPMBAUS01 VPMBAUS02 VPMBAUS03 VPMBAUS05 VPMBAUS06 VPMBAUS07 VPMBAUS08 VPMBAUS10 VPMBAUS11 VPMBAUS12 VPMBAUS15 VPMBAUS16 VPMBAUS21 VPMBAUS22 VPMBAUS23"
nThreadsS=4 # subjects in parallel. take into account the nThreads variable inside the t1tomniRoutine
DATADIR="/DATAPOOL/VPMB/VPMB-STCIBIT-V2" # data folder
VPDIR="/SCRATCH/users/alexandresayal/VPMB" # processing folder

# --------------------------------------------------------------------------------
#  Define function
# --------------------------------------------------------------------------------

t1tomniRoutine () {

    # --------------------------------------------------------------------------------
    #  Settings
    # --------------------------------------------------------------------------------

    DATADIR=${1}                                  # data folder
    VPDIR=${2}                                    # processing folder
    subID=${3}                                    # subject ID
    t1Dir="${VPDIR}/${subID}/ANALYSIS/T1W"        # T1 directory
    betDir="${VPDIR}/${subID}/ANALYSIS/T1W/BET"   # structural directory
    fastDir="${VPDIR}/${subID}/ANALYSIS/T1W/FAST" # FAST directory
    downDir="${VPDIR}/${subID}/ANALYSIS/T1W/DOWN" # downsampled directory
    mniDir="${VPDIR}/${subID}/ANALYSIS/T1W/MNI"   # working directory
    mniImage=$FSLDIR/data/standard/MNI152_T1_1mm  # MNI template
    nThreads=10                                   # Number of threads for ANTs (overides $ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS)

    # --------------------------------------------------------------------------------
    #  Create/Clean fast and mni folders
    # --------------------------------------------------------------------------------

    # mniDir
    if [ ! -e $mniDir ] ; then # not exists
        mkdir -p $mniDir
        echo "--> MNI folder created."
    elif [ "$(ls -A ${mniDir})" ] ; then # not empty
        rm -r ${mniDir}/*
        echo "--> MNI folder cleared."
    else
        echo "--> MNI folder ready."
    fi

    # fastDir
    if [ ! -e $fastDir ] ; then # not exists
        mkdir -p $fastDir
        echo "--> FAST folder created."
    elif [ "$(ls -A ${fastDir})" ] ; then # not empty
        rm -r ${fastDir}/*
        echo "--> FAST folder cleared."
    else
        echo "--> FAST folder ready."
    fi

    # downDir
    if [ ! -e $downDir ] ; then # not exists
        mkdir -p $downDir
        echo "--> DOWN folder created."
    elif [ "$(ls -A ${downDir})" ] ; then # not empty
        rm -r ${downDir}/*
        echo "--> DOWN folder cleared."
    else
        echo "--> DOWN folder ready."
    fi

    # betDir
    if [ ! -e $betDir ] ; then # not exists
        mkdir -p $betDir
        echo "--> BET folder created."
    elif [ "$(ls -A ${betDir})" ] ; then # not empty
        rm -r ${betDir}/*
        echo "--> BET folder cleared."
    else
        echo "--> BET folder ready."
    fi

    # --------------------------------------------------------------------------------
    #  Copy file from DATAPOOL
    # --------------------------------------------------------------------------------

    cp $DATADIR/${subID}/RAW/T1W/${subID}_T1W.nii.gz $t1Dir/${subID}_T1W.nii.gz 

    # --------------------------------------------------------------------------------
    #  Brain Extraction with ANTs
    # --------------------------------------------------------------------------------

    antsBrainExtraction.sh -d 3 \
                           -a ${t1Dir}/${subID}_T1W.nii.gz \
                           -e /DATAPOOL/home/alexandresayal/OASIS-Templates/T_template0.nii.gz \
                           -m /DATAPOOL/home/alexandresayal/OASIS-Templates/T_template0_BrainCerebellumProbabilityMask.nii.gz \
                           -f /DATAPOOL/home/alexandresayal/OASIS-Templates/T_template0_BrainCerebellumRegistrationMask.nii.gz \
                           -o ${betDir}/antsBet_

    # Rename
    mv ${betDir}/antsBet_BrainExtractionBrain.nii.gz ${t1Dir}/${subID}_T1W_brain_restore.nii.gz
    mv ${betDir}/antsBet_BrainExtractionMask.nii.gz ${betDir}/${subID}_T1W_brain_mask.nii.gz

    # Apply brain mask to non bet image
    fslmaths $t1Dir/${subID}_T1W -mas $betDir/${subID}_T1W_brain_mask $t1Dir/${subID}_T1W_brain

    # --------------------------------------------------------------------------------
    #  Bias field correction
    # --------------------------------------------------------------------------------

    # Execute FAST
    # will export bias-corrected image (-B) and binary images for the three tissue types (segmentation, -g)
    fast -b -B -v -g -o ${fastDir}/${subID}_T1W_brain ${t1Dir}/${subID}_T1W_brain.nii.gz

    # Rename segmentation outputs
    mv ${fastDir}/${subID}_T1W_brain_seg_0.nii.gz ${fastDir}/${subID}_T1W_brain_seg-csf.nii.gz
    mv ${fastDir}/${subID}_T1W_brain_seg_1.nii.gz ${fastDir}/${subID}_T1W_brain_seg-gm.nii.gz
    mv ${fastDir}/${subID}_T1W_brain_seg_2.nii.gz ${fastDir}/${subID}_T1W_brain_seg-wm.nii.gz

    # Apply bias field also to non-bet image
    fslmaths ${t1Dir}/${subID}_T1W.nii.gz \
            -div ${fastDir}/${subID}_T1W_brain_bias.nii.gz \
            ${t1Dir}/${subID}_T1W_restore.nii.gz

    # --------------------------------------------------------------------------------
    #  Generate Outskin mask
    # --------------------------------------------------------------------------------

    bet ${t1Dir}/${subID}_T1W_restore.nii.gz $betDir/${subID}_T1W_todelete -A -v

    # rename
    mv $betDir/${subID}_T1W_todelete_outskin_mask.nii.gz $betDir/${subID}_T1W_outskin_mask.nii.gz

    # delete extra files
    rm $betDir/${subID}_T1W_todelete*

    # --------------------------------------------------------------------------------
    #  Generate downsampled images
    # --------------------------------------------------------------------------------

    (

    flirt -in ${t1Dir}/${subID}_T1W_restore.nii.gz \
          -ref ${t1Dir}/${subID}_T1W_restore.nii.gz \
          -applyisoxfm 2.5 \
          -out ${downDir}/${subID}_T1W_down_restore.nii.gz \
          -interp nearestneighbour -v
    
    flirt -in ${t1Dir}/${subID}_T1W_brain_restore.nii.gz \
          -ref ${t1Dir}/${subID}_T1W_brain_restore.nii.gz \
          -applyisoxfm 2.5 \
          -out ${downDir}/${subID}_T1W_down_brain_restore.nii.gz \
          -interp nearestneighbour -v
    
    flirt -in ${betDir}/${subID}_T1W_brain_mask.nii.gz \
          -ref ${betDir}/${subID}_T1W_brain_mask.nii.gz \
          -applyisoxfm 2.5 \
          -out ${downDir}/${subID}_T1W_down_brain_mask.nii.gz \
          -interp nearestneighbour -v

    flirt -in ${fastDir}/${subID}_T1W_brain_seg-wm.nii.gz \
          -ref ${fastDir}/${subID}_T1W_brain_seg-wm.nii.gz \
          -applyisoxfm 2.5 \
          -out ${downDir}/${subID}_T1W_down_brain_seg-wm.nii.gz \
          -interp nearestneighbour -v

    flirt -in $betDir/${subID}_T1W_outskin_mask.nii.gz \
          -ref $betDir/${subID}_T1W_outskin_mask.nii.gz \
          -applyisoxfm 2.5 \
          -out ${downDir}/${subID}_T1W_down_outskin_mask.nii.gz \
          -interp nearestneighbour -v    

    ) &

    # --------------------------------------------------------------------------------
    #  Registration to MNI using ANTs
    # --------------------------------------------------------------------------------

    # Execute
    antsRegistrationSyN.sh \
        -d 3 \
        -f ${mniImage}.nii.gz \
        -m ${t1Dir}/${subID}_T1W.nii.gz \
        -o ${mniDir}/antsOut_ \
        -n $nThreads

    # Rename final images
    mv ${mniDir}/antsOut_Warped.nii.gz ${mniDir}/${subID}_T1W_MNI.nii.gz
    mv ${mniDir}/antsOut_1Warp.nii.gz ${mniDir}/struct2mni.nii.gz

}

# --------------------------------------------------------------------------------
#  Iteration
# --------------------------------------------------------------------------------

# Limit ANTs threading
origN=$ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS
export ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS=10

# start the clock
startTime=`date "+%s"`

# Iterate on the subjects
for subID in $subList
do

    (

    echo "------> SUBJECT ${subID} <------"

    t1tomniRoutine ${DATADIR} ${VPDIR} ${subID}

    ) & # parallel power

    # allow to execute up to $nThreads jobs in parallel
    if [[ $(jobs -r -p | wc -l) -ge $nThreadsS ]]; then
        # now there are $nThreads jobs already running, so wait here for any job
        # to be finished so there is a place to start next one.
        wait -n
    fi

done
wait
echo "ALL DONE!"

# --------------------------------------------------------------------------------
#  Elapsed time
# --------------------------------------------------------------------------------

endTime="`date "+%s"`"
elapsedTime=$(($endTime - $startTime))
((sec=elapsedTime%60, elapsedTime/=60, min=elapsedTime%60, hrs=elapsedTime/60))
echo "---> ELAPSED TIME $(printf "%d:%02d:%02d" $hrs $min $sec)"

# Restore ANTs limit
export ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS=${origN}