# Scripts for mriqc 0.16.1

## Open screen
screen -L -Logfile /DATAPOOL/home/alexandresayal/GitRepos/vpmb/Module2-fMRIPrep/logs/vpmb-none_mriqc_participant.txt -S vpmb-mriqc

## Start
docker run -it --rm -v /SCRATCH/users/alexandresayal/BIDS-VPMB-NONE/:/data:ro -v /SCRATCH/users/alexandresayal/BIDS-VPMB-NONE/derivatives/mriqc/:/out poldracklab/mriqc:0.16.1 /data /out participant

## Detach
Ctrl-A e depois D