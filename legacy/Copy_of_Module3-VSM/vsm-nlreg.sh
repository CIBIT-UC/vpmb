#!/bin/bash

bidsFolder="/DATAPOOL/VPMB/VPMB-BIDS-NLREG"
workFolder="/DATAPOOL/VPMB/VPMB-BIDS-NLREG-work"

# subject ID and folders
subjectID='01'

# open new derivatives folder
WD=$bidsFolder/derivatives/vsm/$subjectID

if [ ! -e $WD ] ; then # not exists
    mkdir -p $WD
    echo "--> subject vsm folder created."
elif [ "$(ls -A ${WD})" ] ; then # not empty
    rm -r ${WD}/*
    echo "--> subject vsm folder cleared."
else
    echo "--> subject vsm folder ready."
fi

# define run
taskName='loc'
TR='1000'

# fetch warp
warpFile=${workFolder}/fmriprep_wf/single_subject_${subjectID}_wf/func_preproc_task_${taskName}_acq_${TR}_run_01_wf/sdc_estimate_wf/syn_sdc_wf/syn/ants_susceptibility0Warp.nii.gz

# fetch transformation matrix to MNI

# warp 2 MNI

# average per TR
