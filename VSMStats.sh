#!/bin/bash

# screen -L -Logfile vsmMain-logfile.txt -S vsm

# --------------------------------------------------------------------------------
#  Setup
# --------------------------------------------------------------------------------

subList="VPMBAUS01 VPMBAUS02 VPMBAUS03 VPMBAUS05 VPMBAUS06 VPMBAUS07 VPMBAUS08 VPMBAUS10 VPMBAUS11 VPMBAUS12 VPMBAUS15 VPMBAUS16 VPMBAUS21 VPMBAUS22 VPMBAUS23"
taskList="TASK-LOC-1000 TASK-AA-0500 TASK-AA-0750 TASK-AA-1000 TASK-AA-2500 TASK-UA-0500 TASK-UA-0750 TASK-UA-1000 TASK-UA-2500"
nTasks=9 # length of taskList
#roTimeList=(0.0415863 0.0432825 0.0415863 0.0415863 0.025030 0.0432825 0.0415863 0.0415863 0.025030)
#nThreadsS=36
VPDIR="/DATAPOOL/VPMB/VPMB-STCIBIT" # data folder
fmapType="SPE" # options: SPE, EPI, GRE
mniImage=$FSLDIR/data/standard/MNI152_T1_1mm                         # MNI template
groupVSMDir=${VPDIR}/GroupAnalyses/VSM

# --------------------------------------------------------------------------------
#  Do
# --------------------------------------------------------------------------------

# Initialize all subject vsm list
vsmFullList=""

# Iterate on the subjects
for subID in $subList
do

    echo "------> SUBJECT ${subID} <------"

    # Create/clear MultiRun folder
    WD=${VPDIR}/${subID}/ANALYSIS/MultiRun

    if [ ! -e $WD ] ; then # not exists
        mkdir -p $WD
        echo "--> MultiRun folder created."
    elif [ "$(ls -A ${WD})" ] ; then # not empty
        echo "--> MultiRun folder not empty!"
    else
        echo "--> MultiRun folder ready."
    fi

    # Initialize list of subject vsm's
    vsmList=""

    # Iterate on the runs to create list of vsm's
    for taskName in $taskList
    do

        vsmDir="${VPDIR}/${subID}/ANALYSIS/${taskName}/FMAP-${fmapType}/vsm"

        vsmList+="${vsmDir}/fieldmap_vsm_brain_MNI.nii.gz "

    done # end run iteration

    # concatenate vsm's for this subject (in time for convenience)
    fslmerge -t $WD/VSM_${fmapType}_merge $vsmList

    # Calculate mean, std, median, max, min of runs per voxel
    fslmaths $WD/VSM_${fmapType}_merge -Tmean $WD/VSM_${fmapType}_mean
    fslmaths $WD/VSM_${fmapType}_merge -Tmedian $WD/VSM_${fmapType}_median
    fslmaths $WD/VSM_${fmapType}_merge -Tstd $WD/VSM_${fmapType}_std
    fslmaths $WD/VSM_${fmapType}_merge -Tmax $WD/VSM_${fmapType}_max
    fslmaths $WD/VSM_${fmapType}_merge -Tmin $WD/VSM_${fmapType}_min

    # Abs
    fslmaths $WD/VSM_${fmapType}_merge -abs $WD/VSM_${fmapType}_merge_abs
    fslmaths $WD/VSM_${fmapType}_merge_abs -Tmean $WD/VSM_${fmapType}_mean_abs

    # Retrive positive and negative parts, mean
    fslmaths $WD/VSM_${fmapType}_merge -thr 0 $WD/VSM_${fmapType}_merge_pos
    fslmaths $WD/VSM_${fmapType}_merge -uthr 0 $WD/VSM_${fmapType}_merge_neg

    fslmaths $WD/VSM_${fmapType}_merge_pos -Tmean $WD/VSM_${fmapType}_mean_pos
    fslmaths $WD/VSM_${fmapType}_merge_neg -Tmean $WD/VSM_${fmapType}_mean_neg

    # Update full list
    vsmFullList+=$vsmList

done # end subject iteration

# --------------------------------------------------------------------------------
#  Group stats
# --------------------------------------------------------------------------------

# Create/clean folder
if [ ! -e $groupVSMDir ] ; then # not exists
    mkdir -p $groupVSMDir
    echo "--> GroupAnalyses/VSM folder created."
else
    echo "--> GroupAnalyses/VSM folder ready."
fi

# Merge all VSMs
fslmerge -t $groupVSMDir/VSM_${fmapType}_group_merge $vsmFullList

# Calculate mean and std
fslmaths $groupVSMDir/VSM_${fmapType}_group_merge -Tmean $groupVSMDir/VSM_${fmapType}_group_mean
fslmaths $groupVSMDir/VSM_${fmapType}_group_merge -Tstd $groupVSMDir/VSM_${fmapType}_group_std

# Useful to check min and max values
# fslstats $groupVSMDir/VSM_${fmapType}_group_mean -R
# fslstats $groupVSMDir/VSM_${fmapType}_group_std -R

# Display group mean
fsleyes --showColourBar --colourBarLocation right --colourBarLabelSide top-left --colourBarSize 50.0 --worldLoc 0.0 0.0 0.0 $mniImage $groupVSMDir/VSM_${fmapType}_group_mean -dr -8 8 -cm render3 --alpha 85  &

# Display group std
fsleyes --showColourBar --colourBarLocation right --colourBarLabelSide top-left --colourBarSize 50.0 --worldLoc 0.0 0.0 0.0 $mniImage $groupVSMDir/VSM_${fmapType}_group_std -dr -0 3 -cm blue-lightblue --alpha 85  &

# --------------------------------------------------------------------------------
#  List select TR
# --------------------------------------------------------------------------------
# Initialize all subject vsm list
trString="TR0500"

vsmListSelect=""
if [ $trString = "TR0500" ]; then
    taskList="TASK-AA-0500 TASK-UA-0500"
elif [ $trString = "TR0750" ]; then
    taskList="TASK-AA-0750 TASK-UA-0750"
elif [ $trString = "TR1000" ]; then
    taskList="TASK-LOC-1000 TASK-AA-1000 TASK-UA-1000"
elif [ $trString = "TR2500" ]; then
    taskList="TASK-AA-2500 TASK-UA-2500"
fi

# Iterate on the subjects
for subID in $subList
do

    # Iterate on the runs
    for taskName in $taskList
    do

        vsmDir="${VPDIR}/${subID}/ANALYSIS/${taskName}/FMAP-${fmapType}/vsm"

        vsmListSelect+="${vsmDir}/fieldmap_vsm_brain_MNI.nii.gz "

    done # end run iteration

done # end subject iteration

# Merge all VSMs
fslmerge -t $groupVSMDir/VSM_${fmapType}_${trString}_group_merge $vsmListSelect

# Calculate mean and std
fslmaths $groupVSMDir/VSM_${fmapType}_${trString}_group_merge -Tmean $groupVSMDir/VSM_${fmapType}_${trString}_group_mean
fslmaths $groupVSMDir/VSM_${fmapType}_${trString}_group_merge -Tstd $groupVSMDir/VSM_${fmapType}_${trString}_group_std

# Display group mean
fsleyes --showColourBar --colourBarLocation right --colourBarLabelSide top-left --colourBarSize 50.0 --worldLoc 0.0 0.0 0.0 $mniImage $groupVSMDir/VSM_${fmapType}_${trString}_group_mean -dr -8 8 -cm render3 --alpha 85  &

# Display group std
fsleyes --showColourBar --colourBarLocation right --colourBarLabelSide top-left --colourBarSize 50.0 --worldLoc 0.0 0.0 0.0 $mniImage $groupVSMDir/VSM_${fmapType}_${trString}_group_std -dr -0 3 -cm blue-lightblue --alpha 85  &