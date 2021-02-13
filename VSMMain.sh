#!/bin/bash

# screen -L -Logfile vsmMain-logfile.txt -S vsm

# --------------------------------------------------------------------------------
#  Setup
# --------------------------------------------------------------------------------

subList="VPMBAUS01 VPMBAUS02 VPMBAUS03 VPMBAUS05 VPMBAUS06 VPMBAUS07 VPMBAUS08 VPMBAUS10 VPMBAUS11 VPMBAUS12 VPMBAUS15 VPMBAUS16 VPMBAUS21 VPMBAUS22 VPMBAUS23"
taskList="TASK-LOC-1000 TASK-AA-0500 TASK-AA-0750 TASK-AA-1000 TASK-AA-2500 TASK-UA-0500 TASK-UA-0750 TASK-UA-1000 TASK-UA-2500"
roTimeList=(0.0415863 0.0432825 0.0415863 0.0415863 0.025030 0.0432825 0.0415863 0.0415863 0.025030)
nThreadsS=6
VPDIR="/DATAPOOL/VPMB/VPMB-STCIBIT" # data folder
fmapType="GRE-SPE"  # options: GRE-SPE, GRE-EPI, GRE, SPE, EPI

# --------------------------------------------------------------------------------
#  Define function
# --------------------------------------------------------------------------------

vsmRoutine(){

    # --------------------------------------------------------------------------------
    #  Settings
    # --------------------------------------------------------------------------------

    VPDIR=${1}            # data folder
    subID=${2}            # subject ID
    taskName=${3}         # task name
    ro_time=${4}          # in seconds
    fmapType=${5}         # options: SPE, EPI, GRE

    taskDir="${VPDIR}/${subID}/ANALYSIS/${taskName}"                     # task directory
    fmapDir="${VPDIR}/${subID}/ANALYSIS/${taskName}/FMAP-${fmapType}"    # fmap directory
    t1Dir="${VPDIR}/${subID}/ANALYSIS/T1W"                               # T1w directory
    vsmDir="${VPDIR}/${subID}/ANALYSIS/${taskName}/FMAP-${fmapType}/vsm" # working directory

    mniImage=$FSLDIR/data/standard/MNI152_T1_1mm                         # MNI template

    # --------------------------------------------------------------------------------
    #  Create/Clean folder
    # --------------------------------------------------------------------------------

    if [ ! -e $vsmDir ] ; then # not exists
        mkdir -p $vsmDir
        echo "--> vsm folder created."
    elif [ "$(ls -A ${vsmDir})" ] ; then # not empty
        rm -r ${vsmDir}/*
        echo "--> vsm folder cleared."
    else
        echo "--> vsm folder ready."
    fi

    # --------------------------------------------------------------------------------
    #  Copy files depending on fieldmap type
    # --------------------------------------------------------------------------------

    if [ ${fmapType} = "SPE" ]; then
        
        cp $fmapDir/work/TopupField.nii.gz $vsmDir/fieldmap.nii.gz # output field of topup
        cp $fmapDir/work/spe-ap_dc_jac.nii.gz $vsmDir/fmapReference.nii.gz # distortion corrected AP image

    elif [ ${fmapType} = "EPI" ]; then

        cp $fmapDir/work/TopupField.nii.gz $vsmDir/fieldmap.nii.gz # output field of topup
        cp $fmapDir/work/epi-ap_dc_jac.nii.gz $vsmDir/fmapReference.nii.gz # distortion corrected AP image

    fi

    # --------------------------------------------------------------------------------
    #  Calculate VSM
    # --------------------------------------------------------------------------------
    # Formula: VSM = topup field (Hz) * readout time (s) = topup field (Hz) / readout time (Hz)
    # Output VSM is in number of voxels

    fslmaths ${vsmDir}/fieldmap \
        -mul $ro_time \
        $vsmDir/fieldmap_vsm

    # --------------------------------------------------------------------------------
    #  Brain extract fmapReference
    # --------------------------------------------------------------------------------

    bet2 $vsmDir/fmapReference.nii.gz $vsmDir/fmapReferenceMask -f 0.4 -n -m   # calculate fmap-ap brain mask
    mv $vsmDir/fmapReferenceMask_mask.nii.gz $vsmDir/fmapReference_brain_mask.nii.gz  # rename fmap brain mask
    fslmaths $vsmDir/fmapReference.nii.gz -mas $vsmDir/fmapReference_brain_mask.nii.gz $vsmDir/fmapReference_brain.nii.gz  # apply fmap brain mask

    # --------------------------------------------------------------------------------
    #  Bias field correction fmapReference
    # --------------------------------------------------------------------------------

    fast -B -v $vsmDir/fmapReference_brain.nii.gz    # output: fmapReference_brain_restore

    # --------------------------------------------------------------------------------
    #  Estimate fmap2struct using epi_reg
    # --------------------------------------------------------------------------------
    # Output matrix: fmap2struct.mat

    epi_reg \
        --epi=$vsmDir/fmapReference_brain_restore \
        --t1=${t1Dir}/FAST/${subID}_T1W_restore \
        --t1brain=${t1Dir}/FAST/${subID}_T1W_brain_restore \
        --wmseg=${t1Dir}/FAST/${subID}_T1W_brain_wmseg \
        --out=$vsmDir/fmap2struct

    # Convert .mat to ANTs format
    c3d_affine_tool \
        -ref ${t1Dir}/FAST/${subID}_T1W_restore \
        -src $vsmDir/fmapReference_brain_restore \
        $vsmDir/fmap2struct.mat -fsl2ras -oitk $vsmDir/fmap2struct_ANTS.txt

    # --------------------------------------------------------------------------------
    #  fmap to MNI using ANTs
    # --------------------------------------------------------------------------------

    antsApplyTransforms -d 3 \
        -i $vsmDir/fmapReference.nii.gz \
        -r $mniImage.nii.gz \
        -n HammingWindowedSinc \
        -t ${t1Dir}/MNI/struct2mni_warp.nii.gz \
        -t ${t1Dir}/MNI/struct2mni_affine.mat \
        -t $vsmDir/fmap2struct_ANTS.txt \
        -o $vsmDir/fmapReference_MNI.nii.gz -v

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
        -t $vsmDir/fmap2struct_ANTS.txt \
        -o $vsmDir/fieldmap_vsm_MNI.nii.gz -v

    # Apply brain mask
    fslmaths $vsmDir/fieldmap_vsm_MNI -mas ${mniImage}_brain_mask $vsmDir/fieldmap_vsm_brain_MNI

}

vsmRoutineGRE(){

    # --------------------------------------------------------------------------------
    #  Settings
    # --------------------------------------------------------------------------------

    VPDIR=${1}            # data folder
    subID=${2}            # subject ID
    taskName=${3}         # task name
    fmapType=${4}

    taskDir="${VPDIR}/${subID}/ANALYSIS/${taskName}"                     # task directory
    fmapDir="${VPDIR}/${subID}/ANALYSIS/${taskName}/FMAP-${fmapType}"    # fmap directory
    t1Dir="${VPDIR}/${subID}/ANALYSIS/T1W"                               # T1w directory
    vsmDir="${VPDIR}/${subID}/ANALYSIS/${taskName}/FMAP-${fmapType}/vsm" # working directory

    mniImage=$FSLDIR/data/standard/MNI152_T1_1mm                         # MNI template

    # --------------------------------------------------------------------------------
    #  Create/Clean folder
    # --------------------------------------------------------------------------------

    if [ ! -e $vsmDir ] ; then # not exists
        mkdir -p $vsmDir
        echo "--> vsm folder created."
    elif [ "$(ls -A ${vsmDir})" ] ; then # not empty
        rm -r ${vsmDir}/*
        echo "--> vsm folder cleared."
    else
        echo "--> vsm folder ready."
    fi

    # --------------------------------------------------------------------------------
    #  Copy files
    # --------------------------------------------------------------------------------

    # funcReference
    cp $fmapDir/prestats+dc.feat/example_func.nii.gz $vsmDir/fmapReference.nii.gz

    # fmap2struct
    cp $fmapDir/prestats+dc.feat/reg/example_func2highres.mat $vsmDir/fmap2struct.mat

    # VSM
    cp $fmapDir/prestats+dc.feat/reg/unwarp/FM_UD_fmap2epi_shift.nii.gz $vsmDir/fieldmap_vsm.nii.gz

    # --------------------------------------------------------------------------------
    #  Brain extract fmapReference
    # --------------------------------------------------------------------------------

    bet2 $vsmDir/fmapReference.nii.gz $vsmDir/fmapReferenceMask -f 0.4 -n -m   # calculate fmap-ap brain mask
    mv $vsmDir/fmapReferenceMask_mask.nii.gz $vsmDir/fmapReference_brain_mask.nii.gz  # rename fmap brain mask
    fslmaths $vsmDir/fmapReference.nii.gz -mas $vsmDir/fmapReference_brain_mask.nii.gz $vsmDir/fmapReference_brain.nii.gz  # apply fmap brain mask

    # --------------------------------------------------------------------------------
    #  Bias field correction fmapReference
    # --------------------------------------------------------------------------------

    fast -B -v $vsmDir/fmapReference_brain.nii.gz    # output: fmapReference_brain_restore

    # --------------------------------------------------------------------------------
    #  Convert .mat to ANTs format
    # --------------------------------------------------------------------------------

    c3d_affine_tool \
        -ref ${t1Dir}/FAST/${subID}_T1W_restore.nii.gz \
        -src $vsmDir/fmapReference_brain_restore.nii.gz \
        $vsmDir/fmap2struct.mat -fsl2ras -oitk $vsmDir/fmap2struct_ANTS.txt

    # --------------------------------------------------------------------------------
    #  fmap to MNI using ANTs
    # --------------------------------------------------------------------------------

    antsApplyTransforms -d 3 \
        -i $vsmDir/fmapReference.nii.gz \
        -r $mniImage.nii.gz \
        -n HammingWindowedSinc \
        -t ${t1Dir}/MNI/struct2mni_warp.nii.gz \
        -t ${t1Dir}/MNI/struct2mni_affine.mat \
        -t $vsmDir/fmap2struct_ANTS.txt \
        -o $vsmDir/fmapReference_MNI.nii.gz -v

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
        -t $vsmDir/fmap2struct_ANTS.txt \
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
        if [ $fmapType = "GRE" ] || [ $fmapType = "GRE-SPE" ] || [ $fmapType = "GRE-EPI" ] ; then

            vsmRoutineGRE ${VPDIR} ${subID} ${taskName} ${fmapType}

        else

            vsmRoutine ${VPDIR} ${subID} ${taskName} ${roTime} ${fmapType}

        fi

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