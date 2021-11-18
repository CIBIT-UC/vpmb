#!/bin/bash

# screen -L -Logfile copyNLREG-logfile.txt -S nlreg

# --------------------------------------------------------------------------------
#  Setup
# --------------------------------------------------------------------------------

subList="VPMBAUS01 VPMBAUS02 VPMBAUS03 VPMBAUS05 VPMBAUS06 VPMBAUS07 VPMBAUS08 VPMBAUS10 VPMBAUS11 VPMBAUS12 VPMBAUS15 VPMBAUS16 VPMBAUS21 VPMBAUS22 VPMBAUS23"
taskList="TASK-LOC-1000 TASK-AA-0500 TASK-AA-0750 TASK-AA-1000 TASK-AA-2500 TASK-UA-0500 TASK-UA-0750 TASK-UA-1000 TASK-UA-2500"
nThreadsS=10
VPDIR="/DATAPOOL/VPMB/VPMB-STCIBIT" # data folder

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
    

    # Iterate on the runs
    for taskName in $taskList
    do

        echo "-----> $taskName <-----" 

        originDir=${VPDIR}/${subID}/ANALYSIS/${taskName}/FMAP-SPE/work
        destinDir=${VPDIR}/${subID}/ANALYSIS/${taskName}/FMAP-NLREG/work

        # create folder
        if [ ! -e $destinDir ] ; then # not exists
            mkdir -p $destinDir
            echo "--> ${destinDir} folder created."
        elif [ "$(ls -A ${destinDir})" ] ; then # not empty
            rm -r ${destinDir}/*
            echo "--> ${destinDir} folder cleared."
        else
            echo "--> ${destinDir} folder ready."
        fi

        cp $originDir/func_stc.nii.gz $destinDir &
        cp $originDir/func_stc_mc.nii.gz $destinDir &
        cp $originDir/func01_brain_restore.nii.gz $destinDir &
        cp $originDir/func_brain_mask.nii.gz $destinDir &

        mkdir $destinDir/postVols &

        cp -r $originDir/func_stc_mc.mat $destinDir &

        mkdir $destinDir/preVols
        cp -r $originDir/preVols/func* $destinDir/preVols

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