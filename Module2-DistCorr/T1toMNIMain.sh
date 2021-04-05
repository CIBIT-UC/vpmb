#!/bin/bash

# Pipeline for estimating T1 to MNI transformation for all subjects

# Requirements for this script
#  installed versions of: FSL, ANTS
#  environment: FSLDIR

# screen -L -Logfile t1tomniMain-logfile.txt -S t1tomni

# --------------------------------------------------------------------------------
#  Setup
# --------------------------------------------------------------------------------

subList="VPMBAUS01 VPMBAUS02 VPMBAUS03 VPMBAUS05 VPMBAUS06 VPMBAUS07 VPMBAUS08 VPMBAUS10 VPMBAUS11 VPMBAUS12 VPMBAUS15 VPMBAUS16 VPMBAUS21 VPMBAUS22 VPMBAUS23"
nThreadsS=4 # subjects in parallel. take into account the nThreads variable inside the t1tomniRoutine
VPDIR="/DATAPOOL/VPMB/VPMB-STCIBIT" # data folder

# --------------------------------------------------------------------------------
#  Define function
# --------------------------------------------------------------------------------

t1tomniRoutine () {

    # --------------------------------------------------------------------------------
    #  Settings
    # --------------------------------------------------------------------------------

    VPDIR=${1}                                    # data folder
    subID=${2}                                    # subject ID
    betDir="${VPDIR}/${subID}/ANALYSIS/T1W/BET"   # structural directory
    fastDir="${VPDIR}/${subID}/ANALYSIS/T1W/FAST" # FAST directory
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

    # --------------------------------------------------------------------------------
    #  BET T1W
    # --------------------------------------------------------------------------------
    # (cannot use the output from ANTs because it is already restored)

    # Copy file
    cp $betDir/${subID}_T1W.nii.gz $fastDir/${subID}_T1W.nii.gz 

    # Apply  brain mask
    fslmaths $fastDir/${subID}_T1W -mas $betDir/${subID}_T1W_brain_mask $fastDir/${subID}_T1W_brain

    # --------------------------------------------------------------------------------
    #  Bias field correction
    # --------------------------------------------------------------------------------

    (
    # Execute FAST
    # will export bias-corrected image (-B) and binary images for the three tissue types (segmentation, -g)
    fast -b -B -v -g -o ${fastDir}/${subID}_T1W_brain ${fastDir}/${subID}_T1W_brain.nii.gz

    # Rename segmentation outputs
    mv ${fastDir}/${subID}_T1W_brain_seg_0.nii.gz ${fastDir}/${subID}_T1W_brain_csfseg.nii.gz
    mv ${fastDir}/${subID}_T1W_brain_seg_1.nii.gz ${fastDir}/${subID}_T1W_brain_gmseg.nii.gz
    mv ${fastDir}/${subID}_T1W_brain_seg_2.nii.gz ${fastDir}/${subID}_T1W_brain_wmseg.nii.gz

    # Apply bias field also to non-bet image
    fslmaths ${fastDir}/${subID}_T1W.nii.gz \
            -div ${fastDir}/${subID}_T1W_brain_bias.nii.gz \
            ${fastDir}/${subID}_T1W_restore.nii.gz
    ) &

    # --------------------------------------------------------------------------------
    #  Registration to MNI using ANTs
    # --------------------------------------------------------------------------------

    # Execute
    antsRegistrationSyN.sh \
        -d 3 \
        -f ${mniImage}.nii.gz \
        -m ${fastDir}/${subID}_T1W.nii.gz \
        -o ${mniDir}/antsOut_ \
        -n $nThreads

    # Rename final images
    mv ${mniDir}/antsOut_Warped.nii.gz ${mniDir}/${subID}_T1W_MNI.nii.gz
    mv ${mniDir}/antsOut_1Warp.nii.gz ${mniDir}/struct2mni.nii.gz

}

# --------------------------------------------------------------------------------
#  Iteration
# --------------------------------------------------------------------------------

# start the clock
startTime=`date "+%s"`

# Iterate on the subjects
for subID in $subList
do

    (

    echo "------> SUBJECT ${subID} <------"

    t1tomniRoutine ${VPDIR} ${subID}

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