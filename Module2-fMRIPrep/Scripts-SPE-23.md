# FIELMAP SPE

## Open screen
screen -L -Logfile /DATAPOOL/home/alexandresayal/GitRepos/vpmb/Module2-fMRIPrep/logs23/vpmb-spe_fmriprep_sub-03.txt -S vpmb-03

## Start
docker run -ti --rm \
    -v /DATAPOOL/VPMB/BIDS-VPMB-SPE:/data:ro \
    -v /DATAPOOL/VPMB/BIDS-VPMB-SPE/derivatives/fmriprep23:/out \
    -v /SCRATCH/users/alexandresayal/fmriprep23-work-vpmb:/work \
    -v /SCRATCH/software/freesurfer/license.txt:/license \
    nipreps/fmriprep:23.0.2 \
    /data /out/fmriprep \
    participant \
    -w /work \
    --fs-license-file /license \
    --nprocs 18 \
    --stop-on-first-crash \
    --output-spaces MNI152NLin2009cAsym:res-2 T1w \
    --participant-label 03