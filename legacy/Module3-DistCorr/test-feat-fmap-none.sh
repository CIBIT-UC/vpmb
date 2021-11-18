#!/bin/bash

# test feat

# Requirements for this script
#  installed versions of: FSL
#  environment: FSLDIR

# --------------------------------------------------------------------------------
#  Settings
# --------------------------------------------------------------------------------

DATADIR="/DATAPOOL/VPMB/VPMB-STCIBIT-V2" # data folder
VPDIR="/SCRATCH/users/alexandresayal/VPMB" # processing folder
subID="VPMBAUS01"                                           # subject ID
taskName="TASK-LOC-1000"                                    # task name
taskDir="${VPDIR}/${subID}/ANALYSIS/${taskName}"            # task directory
fmapDir="${VPDIR}/${subID}/ANALYSIS/${taskName}/FMAP-NONE"   # fmap directory
WD="${VPDIR}/${subID}/ANALYSIS/${taskName}/FMAP-NONE/work"   # working directory
t1Dir="${VPDIR}/${subID}/ANALYSIS/T1W"                      # T1w directory
ro_time=0.0415863 # in seconds
nThreads=18 # number of threads

# --------------------------------------------------------------------------------
#  Create/Clean folder
# --------------------------------------------------------------------------------

if [ ! -e $WD ] ; then # not exists
    mkdir -p $WD
    echo "--> FMAP-NONE/work folder created."
elif [ "$(ls -A ${WD})" ] ; then # not empty
    rm -r ${WD}/*
    echo "--> FMAP-NONE/work folder cleared."
else
    echo "--> FMAP-NONE/work folder ready."
fi

# --------------------------------------------------------------------------------
#  Copy files
# --------------------------------------------------------------------------------

# Copy functional data
cp $DATADIR/$subID/RAW/${taskName}/${subID}_${taskName}.nii.gz $WD/func.nii.gz

# --------------------------------------------------------------------------------
#  Slice timing correction (ST)
# --------------------------------------------------------------------------------

# Generate ST timings file

echo "${DATADIR}/${subID}/RAW/${taskName}/${subID}_${taskName}.json" | jq -r -s '.SliceTiming'

stArray=`jq '.SliceTiming' ${DATADIR}/${subID}/RAW/${taskName}/${subID}_${taskName}.json`
stArray=(${stArray//, / }) # split into array




# TODO
customSTFile=${VPDIR}/${subID}/ANALYSIS/${taskName}/st_order.txt

# --------------------------------------------------------------------------------
#  Protocol
# --------------------------------------------------------------------------------

# Generate events file