#!/bin/bash

# Pipeline for estimating T1 to MNI transformation for all subjects

# Requirements for this script
#  installed versions of: FSL
#  environment: FSLDIR

# screen -L -Logfile t1tomniMain-logfile.txt -S t1tomni

# --------------------------------------------------------------------------------
#  Setup
# --------------------------------------------------------------------------------

subList="VPMBAUS01 VPMBAUS02 VPMBAUS03 VPMBAUS05 VPMBAUS06 VPMBAUS07 VPMBAUS08 VPMBAUS10 VPMBAUS11 VPMBAUS12 VPMBAUS15 VPMBAUS16 VPMBAUS21 VPMBAUS22 VPMBAUS23"
nThreadsS=15
VPDIR="/DATAPOOL/VPMB/VPMB-STCIBIT" # data folder

# --------------------------------------------------------------------------------
#  Define function
# --------------------------------------------------------------------------------

t1tomniRoutine () {

    # --------------------------------------------------------------------------------
    #  Settings
    # --------------------------------------------------------------------------------

    VPDIR=${1}                                      # data folder
    subID=${2}                                      # subject ID
    betDir="${VPDIR}/${subID}/ANALYSIS/T1W/BET"     # structural directory
    fastDir="${VPDIR}/${subID}/ANALYSIS/T1W/FAST"   # FAST directory
    WD="${VPDIR}/${subID}/ANALYSIS/T1W/MNI"         # working directory
    mniImage=$FSLDIR/data/standard/MNI152_T1_2mm    # MNI template

    # --------------------------------------------------------------------------------
    #  Create/Clean folder
    # --------------------------------------------------------------------------------

    if [ ! -e $WD ] ; then # not exists
        mkdir -p $WD
        echo "--> MNI folder created."
    elif [ "$(ls -A ${WD})" ] ; then # not empty
        rm -r ${WD}/*
        echo "--> MNI folder cleared."
    else
        echo "--> MNI folder ready."
    fi

    # --------------------------------------------------------------------------------
    #  Bias field correction
    # --------------------------------------------------------------------------------

    # create/clear folder
    if [ ! -e $fastDir ] ; then # not exists
        mkdir -p $fastDir
        echo "--> FAST folder created."
    elif [ "$(ls -A ${fastDir})" ] ; then # not empty
        rm -r ${fastDir}/*
        echo "--> FAST folder cleared."
    else
        echo "--> FAST folder ready."
    fi

    # BET (cannot use the existing _brain because its restored)
    cp $betDir/${subID}_T1W.nii.gz $fastDir/${subID}_T1W.nii.gz # copy file

    fslmaths $fastDir/${subID}_T1W -mas $betDir/${subID}_T1W_brain_mask $fastDir/${subID}_T1W_brain    # apply  brain mask

    # execute
    fast -b -B -v -o ${fastDir}/${subID}_T1W_brain ${fastDir}/${subID}_T1W_brain.nii.gz

    # apply also to non-bet image
    fslmaths ${fastDir}/${subID}_T1W.nii.gz \
            -div ${fastDir}/${subID}_T1W_brain_bias.nii.gz \
            ${fastDir}/${subID}_T1W_restore.nii.gz

    # --------------------------------------------------------------------------------
    #  Registration to MNI
    # --------------------------------------------------------------------------------

    # Initial linear registration
    flirt -ref ${mniImage}_brain \
            -in ${fastDir}/${subID}_T1W_brain_restore \
            -out ${WD}/${subID}_T1W_MNI_brain_affine \
            -omat $WD/struct2mni_affine.mat \
            -dof 12 -v

    # Non-linear registration
    fnirt --in=${fastDir}/${subID}_T1W_restore \
            --config=T1_2_MNI152_2mm \
            --aff=$WD/struct2mni_affine.mat \
            --warpres=6,6,6 \
            --cout=$WD/struct2mni -v

    # Apply
    applywarp --ref=${mniImage} \
        --in=${fastDir}/${subID}_T1W_restore \
        --warp=$WD/struct2mni \
        --out=${WD}/${subID}_T1W_MNI \
        --interp=sinc

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