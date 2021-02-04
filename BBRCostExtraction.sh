#!/bin/bash

# screen -L -Logfile BBRCostExtraction-logfile.txt -S bbr

# --------------------------------------------------------------------------------
#  Setup
# --------------------------------------------------------------------------------

subList="VPMBAUS01 VPMBAUS02 VPMBAUS03 VPMBAUS05 VPMBAUS06 VPMBAUS07 VPMBAUS08 VPMBAUS10 VPMBAUS11 VPMBAUS12 VPMBAUS15 VPMBAUS16 VPMBAUS21 VPMBAUS22 VPMBAUS23"
taskList="TASK-LOC-1000 TASK-AA-0500 TASK-AA-0750 TASK-AA-1000 TASK-AA-2500 TASK-UA-0500 TASK-UA-0750 TASK-UA-1000 TASK-UA-2500"
VPDIR="/DATAPOOL/VPMB/VPMB-STCIBIT" # data folder
outputFileName="${VPDIR}/GroupAnalyses/BBR_CostValues_func2struct.txt"
nThreadsS=36
# Init output file (replacing existing)
printf "subID taskName costBefore costAfterSPE costAfterEPI costAfterGRE\n" > $outputFileName

# --------------------------------------------------------------------------------
#  Iteration
# --------------------------------------------------------------------------------

# Iterate on the subjects
for subID in $subList
do

    (

    t1Dir="${VPDIR}/${subID}/ANALYSIS/T1W" # T1w directory

    # Iteration on the runs
    for taskName in $taskList
    do

        # -- BEFORE --------------------
        WD="${VPDIR}/${subID}/ANALYSIS/${taskName}/FMAP-NONE/work"

        if [ ! -e $WD ] ; then mkdir -p $WD ; fi # make dir
        cp ${VPDIR}/${subID}/ANALYSIS/${taskName}/FMAP-SPE/work/func01.nii.gz $WD/func01.nii.gz # copy original func01 from another place (for now)

        # register (this will be handled by another script in the near future)
        epi_reg --epi=$WD/func01.nii.gz \
            --t1=${t1Dir}/FAST/${subID}_T1W_restore \
            --t1brain=${t1Dir}/FAST/${subID}_T1W_brain_restore \
            --wmseg=${t1Dir}/FAST/${subID}_T1W_brain_wmseg \
            --out=$WD/func2struct -v

        costBefore=`flirt -in $WD/func01.nii.gz \
            -ref ${t1Dir}/FAST/${subID}_T1W_brain_restore \
            -schedule $FSLDIR/etc/flirtsch/measurecost1.sch \
            -init $WD/func2struct.mat \
            -wmseg ${t1Dir}/FAST/${subID}_T1W_brain_wmseg.nii.gz \
            -cost bbr|head -1|cut -f1 -d ' '`
        # ------------------------------

        # -- SPE -----------------------
        WD="${VPDIR}/${subID}/ANALYSIS/${taskName}/FMAP-SPE/work"

        costAfterSPE=`flirt -in $WD/func01_processed.nii.gz \
            -ref ${t1Dir}/FAST/${subID}_T1W_brain_restore \
            -schedule $FSLDIR/etc/flirtsch/measurecost1.sch \
            -init $WD/func2struct.mat \
            -wmseg ${t1Dir}/FAST/${subID}_T1W_brain_wmseg.nii.gz \
            -cost bbr|head -1|cut -f1 -d ' '`
        # ------------------------------

        # -- EPI -----------------------
        WD="${VPDIR}/${subID}/ANALYSIS/${taskName}/FMAP-EPI/work"

        costAfterEPI=`flirt -in $WD/func01_processed.nii.gz \
            -ref ${t1Dir}/FAST/${subID}_T1W_brain_restore \
            -schedule $FSLDIR/etc/flirtsch/measurecost1.sch \
            -init $WD/func2struct.mat \
            -wmseg ${t1Dir}/FAST/${subID}_T1W_brain_wmseg.nii.gz \
            -cost bbr|head -1|cut -f1 -d ' '`
        # ------------------------------

        # -- GRE -----------------------
        WD="${VPDIR}/${subID}/ANALYSIS/${taskName}/FMAP-GRE/prestats+dc.feat/reg/"
        
        costAfterGRE=`flirt -in $WD/example_func.nii.gz \
            -ref ${t1Dir}/FAST/${subID}_T1W_brain_restore \
            -schedule $FSLDIR/etc/flirtsch/measurecost1.sch \
            -init $WD/example_func2highres.mat \
            -wmseg ${t1Dir}/FAST/${subID}_T1W_brain_wmseg.nii.gz \
            -cost bbr|head -1|cut -f1 -d ' '`
        # ------------------------------

        # Write to file
        printf "%s %s %s %s %s %s %s\n" ${subID} ${taskName} ${costBefore} ${costAfterSPE} ${costAfterEPI} ${costAfterGRE}  >> $outputFileName

    done # end task iteration

    ) & # parallel power

    # allow to execute up to $nThreads jobs in parallel
    if [[ $(jobs -r -p | wc -l) -ge $nThreadsS ]]; then
        # now there are $nThreads jobs already running, so wait here for any job
        # to be finished so there is a place to start next one.
        wait -n
    fi

done # end subject iteration
wait
echo "ALL DONE!"
