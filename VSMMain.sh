#!/bin/bash

# screen -L -Logfile vsmMain-logfile.txt -S vsm

# --------------------------------------------------------------------------------
#  Setup
# --------------------------------------------------------------------------------

subList="VPMBAUS01 VPMBAUS02 VPMBAUS03 VPMBAUS05 VPMBAUS06 VPMBAUS07 VPMBAUS08 VPMBAUS10 VPMBAUS11 VPMBAUS12 VPMBAUS15 VPMBAUS16 VPMBAUS21 VPMBAUS22 VPMBAUS23"
taskList="TASK-LOC-1000 TASK-AA-0500 TASK-AA-0750 TASK-AA-1000 TASK-AA-2500 TASK-UA-0500 TASK-UA-0750 TASK-UA-1000 TASK-UA-2500"
nTasks=9 # length of taskList
roTimeList=(0.0415863 0.0432825 0.0415863 0.0415863 0.025030 0.0432825 0.0415863 0.0415863 0.025030)
nThreadsS=36
VPDIR="/DATAPOOL/VPMB/VPMB-STCIBIT" # data folder

# --------------------------------------------------------------------------------
#  Define function
# --------------------------------------------------------------------------------

vsmRoutine(){

    # --------------------------------------------------------------------------------
    #  Settings
    # --------------------------------------------------------------------------------

    VPDIR=${1}                         # data folder
    subID=${2}                                           # subject ID
    taskName=${3}                                    # task name
    taskDir="${VPDIR}/${subID}/ANALYSIS/${taskName}"             # task directory
    fmapDir="${VPDIR}/${subID}/ANALYSIS/${taskName}/FMAP-SPE"    # fmap directory
    t1Dir="${VPDIR}/${subID}/ANALYSIS/T1W"                       # T1w directory
    vsmDir="${VPDIR}/${subID}/ANALYSIS/${taskName}/FMAP-SPE/vsm" # working directory
    ro_time=${4}                                            # in seconds
    mniImage=$FSLDIR/data/standard/MNI152_T1_1mm                 # MNI template

    # --------------------------------------------------------------------------------
    #  Create/Clean folder
    # --------------------------------------------------------------------------------

    if [ ! -e $vsmDir ] ; then # not exists
        mkdir -p $vsmDir
        echo "--> FMAP-SPE/vsm folder created."
    elif [ "$(ls -A ${vsmDir})" ] ; then # not empty
        rm -r ${vsmDir}/*
        echo "--> FMAP-SPE/vsm folder cleared."
    else
        echo "--> FMAP-SPE/vsm folder ready."
    fi

    # --------------------------------------------------------------------------------
    #  Copy files
    # --------------------------------------------------------------------------------

    cp $fmapDir/work/TopupField.nii.gz $vsmDir/fieldmap.nii.gz # output field of topup
    cp $fmapDir/work/spe-ap_dc_jac.nii.gz $vsmDir/speReference.nii.gz # distortion corrected SPE AP image

    # --------------------------------------------------------------------------------
    #  Calculate VSM
    # --------------------------------------------------------------------------------
    # Formula: VSM = topup field (Hz) * readout time (s) = topup field (Hz) / readout time (Hz)
    # Output VSM is in number of voxels

    fslmaths ${vsmDir}/fieldmap \
        -mul $ro_time \
        $vsmDir/fieldmap_vsm

    # --------------------------------------------------------------------------------
    #  Brain extract speReference
    # --------------------------------------------------------------------------------

    bet2 $vsmDir/speReference.nii.gz $vsmDir/speReferenceMask -f 0.4 -n -m   # calculate spe-ap brain mask
    mv $vsmDir/speReferenceMask_mask.nii.gz $vsmDir/speReference_brain_mask.nii.gz  # rename spe brain mask
    fslmaths $vsmDir/speReference.nii.gz -mas $vsmDir/speReference_brain_mask.nii.gz $vsmDir/speReference_brain.nii.gz  # apply spe brain mask

    # --------------------------------------------------------------------------------
    #  Bias field correction speReference
    # --------------------------------------------------------------------------------

    fast -B -v $vsmDir/speReference_brain.nii.gz    # output: speReference_brain_restore

    # --------------------------------------------------------------------------------
    #  Estimate spe2struct using epi_reg
    # --------------------------------------------------------------------------------
    # Output matrix: spe2struct.mat

    epi_reg \
        --epi=$vsmDir/speReference_brain_restore \
        --t1=${t1Dir}/FAST/${subID}_T1W_restore \
        --t1brain=${t1Dir}/FAST/${subID}_T1W_brain_restore \
        --wmseg=${t1Dir}/FAST/${subID}_T1W_brain_wmseg \
        --out=$vsmDir/spe2struct

    # Convert .mat to ANTs format
    c3d_affine_tool \
        -ref ${t1Dir}/FAST/${subID}_T1W_restore \
        -src $vsmDir/speReference_brain_restore \
        $vsmDir/spe2struct.mat -fsl2ras -oitk $vsmDir/spe2struct_ANTS.txt

    # --------------------------------------------------------------------------------
    #  SPE to MNI using ANTs
    # --------------------------------------------------------------------------------

    antsApplyTransforms -d 3 \
        -i $vsmDir/speReference.nii.gz \
        -r $mniImage.nii.gz \
        -n HammingWindowedSinc \
        -t ${t1Dir}/MNI/struct2mni_warp.nii.gz \
        -t ${t1Dir}/MNI/struct2mni_affine.mat \
        -t $vsmDir/spe2struct_ANTS.txt \
        -o $vsmDir/speReference_MNI.nii.gz -v

    # --------------------------------------------------------------------------------
    #  VSM to MNI using ANTs
    # --------------------------------------------------------------------------------
    # Nearest Neighbor interpolation (do not allow voxel value change)

    antsApplyTransforms -d 3 \
        -i $vsmDir/fieldmap_vsm.nii.gz \
        -r $mniImage.nii.gz \
        -n NearestNeighbor \
        -t ${t1Dir}/MNI/struct2mni_warp.nii.gz \
        -t ${t1Dir}/MNI/struct2mni_affine.mat \
        -t $vsmDir/spe2struct_ANTS.txt \
        -o $vsmDir/fieldmap_vsm_MNI.nii.gz -v

    # Apply brain mask
    fslmaths $vsmDir/fieldmap_vsm_MNI -mas ${mniImage}_brain_mask $vsmDir/fieldmap_vsm_brain_MNI

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
    roCounter=0

    # Iterate on the runs
    for taskName in $taskList
    do

        echo "-----> $taskName <-----" 

        roTime=${roTimeList[$roCounter]}
       
        # main function
        vsmRoutine ${VPDIR} ${subID} ${taskName} ${roTime}

        # increase counter
        roCounter=$[$roCounter+1]

    done

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

# --------------------------------------------------------------------------------
#  Average VSM
# --------------------------------------------------------------------------------

# Iterate on the subjects
for subID in $subList
do

    echo "------> SUBJECT ${subID} <------"

    firstFlag=1 # to flag first run of subject

    WD=${VPDIR}/${subID}/ANALYSIS/MultiRun

    if [ ! -e $WD ] ; then # not exists
        mkdir -p $WD
        echo "--> MultiRun folder created."
    elif [ "$(ls -A ${WD})" ] ; then # not empty
        rm -r ${wd}/*
        echo "--> MultiRun folder cleared."
    else
        echo "--> MultiRun folder ready."
    fi

    # Iterate on the runs
    for taskName in $taskList
    do

        echo "-----> $taskName <-----" 

        vsmDir="${VPDIR}/${subID}/ANALYSIS/${taskName}/FMAP-SPE/vsm"

        # if it is the first run
        if [$firstFlag -eq 1]
        then
            # copy the first vsm and rename
            cp $vsmDir/fieldmap_vsm_brain_MNI $WD/VSM_aux
            # change firstFlag to 0
            firstFlag=0
        else
            # concatenate existing vsm with the next (in time for convenience)
            fslmerge -t $WD/VSM_aux $WD/VSM_aux $vsmDir/fieldmap_vsm_brain_MNI
        fi

    done # end run iteration

    # Calculate mean, std, max of runs per voxel
    fslmaths $WD/VSM_aux -Tmean $WD/VSM_mean
    fslmaths $WD/VSM_aux -Tmedian $WD/VSM_median
    fslmaths $WD/VSM_aux -Tstd $WD/VSM_std
    fslmaths $WD/VSM_aux -Tmax $WD/VSM_max
    #rm $WD/VSM_aux

done
