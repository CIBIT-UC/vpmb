#!/bin/bash

#bidsFolder="/SCRATCH/users/alexandresayal/test-vpmb-nlreg-fmriprep"
#workFolder="/SCRATCH/users/alexandresayal/test-vpmb-nlreg-fmriprep-work"
bidsFolder="/DATAPOOL/VPMB/VPMB-BIDS-NLREG"
workFolder="/DATAPOOL/VPMB/VPMB-BIDS-NLREG-work"

# Validate
bids-validator $bidsFolder

# fmriprep run
fmriprep-docker $bidsFolder $bidsFolder/derivatives \
    participant --participant-label 02 \
    --work-dir $workFolder \
    --fs-license-file /SCRATCH/software/freesurfer/license.txt \
    --fs-no-reconall \
    --stop-on-first-crash \
    --output-spaces MNI152NLin2009cAsym T1w func \
    --use-syn-sdc \
    --nprocs 12

## PARALLEL PROCESSING

# Open screen
screen -L -Logfile $workFolder/log-terminal-vpmb-sub21.txt -S vpmb21

# Start
#fmriprep-docker ...

# Detach screen
# Ctrl-A e depois D
