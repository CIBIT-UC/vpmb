# FIELMAP NONE

## Open screen
screen -L -Logfile /DATAPOOL/home/alexandresayal/GitRepos/vpmb/Module2-fMRIPrep/logs/vpmb-none_fmriprep_sub-23.txt -S vpmb-none-23

## Start
docker run -ti --rm \
    -v /DATAPOOL/VPMB/BIDS-VPMB-NONE:/data:ro \
    -v /DATAPOOL/VPMB/BIDS-VPMB-NONE/derivatives:/out \
    -v /SCRATCH/users/alexandresayal/fmriprep-work_VPMB-NONE:/work \
    -v /SCRATCH/software/freesurfer/license.txt:/license \
    nipreps/fmriprep:21.0.1 \
    /data /out/fmriprep \
    participant \
    -w /work \
    --fs-license-file /license \
    --nprocs 16 \
    --low-mem \
    --stop-on-first-crash \
    --fs-no-reconall \
    --output-spaces MNI152NLin2009cAsym T1w \
    --participant-label 23

## Detach screen
Ctrl-A e depois D

# FIELMAP SPE

## Open screen
screen -L -Logfile /DATAPOOL/home/alexandresayal/GitRepos/vpmb/Module2-fMRIPrep/logs/vpmb-spe_fmriprep_sub-2223.txt -S vpmb-spe-2223

## Start
docker run -ti --rm \
    -v /DATAPOOL/VPMB/BIDS-VPMB-SPE:/data:ro \
    -v /DATAPOOL/VPMB/BIDS-VPMB-SPE/derivatives:/out \
    -v /SCRATCH/users/alexandresayal/fmriprep-work_VPMB-SPE:/work \
    -v /SCRATCH/software/freesurfer/license.txt:/license \
    nipreps/fmriprep:21.0.1 \
    /data /out/fmriprep \
    participant \
    -w /work \
    --fs-license-file /license \
    --nprocs 16 \
    --low-mem \
    --stop-on-first-crash \
    --fs-no-reconall \
    --output-spaces MNI152NLin2009cAsym T1w \
    --participant-label 22 23

## Detach screen
Ctrl-A e depois D

# FIELMAP EPI

## Open screen
screen -L -Logfile /DATAPOOL/home/alexandresayal/GitRepos/vpmb/Module2-fMRIPrep/logs/vpmb-epi_fmriprep_sub-2223.txt -S vpmb-epi-2223

## Start
docker run -ti --rm \
    -v /DATAPOOL/VPMB/BIDS-VPMB-EPI:/data:ro \
    -v /DATAPOOL/VPMB/BIDS-VPMB-EPI/derivatives:/out \
    -v /SCRATCH/users/alexandresayal/fmriprep-work_VPMB-EPI:/work \
    -v /SCRATCH/software/freesurfer/license.txt:/license \
    nipreps/fmriprep:21.0.1 \
    /data /out/fmriprep \
    participant \
    -w /work \
    --fs-license-file /license \
    --nprocs 16 \
    --low-mem \
    --stop-on-first-crash \
    --fs-no-reconall \
    --output-spaces MNI152NLin2009cAsym T1w \
    --participant-label 22 23

## Detach screen
Ctrl-A e depois D

# FIELMAP NLREG

## Open screen
screen -L -Logfile /DATAPOOL/home/alexandresayal/GitRepos/vpmb/Module2-fMRIPrep/logs/vpmb-nlreg_fmriprep_sub-2223.txt -S vpmb-nlreg-2223

## Start
docker run -ti --rm \
    -v /DATAPOOL/VPMB/BIDS-VPMB-NLREG:/data:ro \
    -v /DATAPOOL/VPMB/BIDS-VPMB-NLREG/derivatives:/out \
    -v /SCRATCH/users/alexandresayal/fmriprep-work_VPMB-NLREG:/work \
    -v /SCRATCH/software/freesurfer/license.txt:/license \
    nipreps/fmriprep:21.0.1 \
    /data /out/fmriprep \
    participant \
    -w /work \
    --fs-license-file /license \
    --use-syn-sdc \
    --nprocs 16 \
    --low-mem \
    --stop-on-first-crash \
    --fs-no-reconall \
    --output-spaces MNI152NLin2009cAsym T1w \
    --participant-label 22 23

# FIELMAP gre

## Open screen
screen -L -Logfile /DATAPOOL/home/alexandresayal/GitRepos/vpmb/Module2-fMRIPrep/logs/vpmb-gre_fmriprep_sub-2223.txt -S vpmb-gre-2223

## Start
docker run -ti --rm \
    -v /DATAPOOL/VPMB/BIDS-VPMB-GRE:/data:ro \
    -v /DATAPOOL/VPMB/BIDS-VPMB-GRE/derivatives:/out \
    -v /SCRATCH/users/alexandresayal/fmriprep-work_VPMB-GRE:/work \
    -v /SCRATCH/software/freesurfer/license.txt:/license \
    nipreps/fmriprep:21.0.1 \
    /data /out/fmriprep \
    participant \
    -w /work \
    --fs-license-file /license \
    --nprocs 16 \
    --low-mem \
    --stop-on-first-crash \
    --fs-no-reconall \
    --output-spaces MNI152NLin2009cAsym T1w \
    --participant-label 22 23

## Detach screen
Ctrl-A e depois D    