#!/bin/bash

# screen -L -Logfile BBRCostExtraction-logfile.txt -S bbr

# --------------------------------------------------------------------------------
#  Setup
# --------------------------------------------------------------------------------

subList="VPMBAUS01 VPMBAUS02 VPMBAUS03 VPMBAUS05 VPMBAUS06 VPMBAUS07 VPMBAUS08 VPMBAUS10 VPMBAUS11 VPMBAUS12 VPMBAUS15 VPMBAUS16 VPMBAUS21 VPMBAUS22 VPMBAUS23"
taskList="TASK-LOC-1000 TASK-AA-0500 TASK-AA-0750 TASK-AA-1000 TASK-AA-2500 TASK-UA-0500 TASK-UA-0750 TASK-UA-1000 TASK-UA-2500"
VPDIR="/DATAPOOL/VPMB/VPMB-STCIBIT" # data folder

outputFileName1="${VPDIR}/GroupAnalyses/CostValues_BBR_func2struct.txt"
outputFileName2="${VPDIR}/GroupAnalyses/CostValues_NormMI_func2struct.txt"
outputFileName3="${VPDIR}/GroupAnalyses/CostValues_CorrRatio_func2struct.txt"

nThreadsS=15

# Init output files (replacing existing)
printf "subID taskName costBefore costAfterSPE costAfterEPI costAfterGRE costAfterGREEPI costAfterGRESPE\n" > $outputFileName1
printf "subID taskName costBefore costAfterSPE costAfterEPI costAfterGRE costAfterGREEPI costAfterGRESPE\n" > $outputFileName2
printf "subID taskName costBefore costAfterSPE costAfterEPI costAfterGRE costAfterGREEPI costAfterGRESPE\n" > $outputFileName3

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

        # if [ ! -e $WD ] ; then mkdir -p $WD ; fi # make dir
        # cp ${VPDIR}/${subID}/ANALYSIS/${taskName}/FMAP-SPE/work/func01.nii.gz $WD/func01.nii.gz # copy original func01 from another place (for now)

        # # register (this will be handled by another script in the near future)
        # epi_reg --epi=$WD/func01.nii.gz \
        #     --t1=${t1Dir}/FAST/${subID}_T1W_restore \
        #     --t1brain=${t1Dir}/FAST/${subID}_T1W_brain_restore \
        #     --wmseg=${t1Dir}/FAST/${subID}_T1W_brain_wmseg \
        #     --out=$WD/func2struct -v

        costBefore1=`flirt -in $WD/func01.nii.gz \
            -ref ${t1Dir}/FAST/${subID}_T1W_brain_restore \
            -schedule $FSLDIR/etc/flirtsch/measurecost1.sch \
            -init $WD/func2struct.mat \
            -wmseg ${t1Dir}/FAST/${subID}_T1W_brain_wmseg.nii.gz \
            -cost bbr|head -1|cut -f1 -d ' '`
        costBefore2=`flirt -in $WD/func01.nii.gz \
            -ref ${t1Dir}/FAST/${subID}_T1W_brain_restore \
            -schedule $FSLDIR/etc/flirtsch/measurecost1.sch \
            -init $WD/func2struct.mat \
            -cost normmi|head -1|cut -f1 -d ' '`
        costBefore3=`flirt -in $WD/func01.nii.gz \
            -ref ${t1Dir}/FAST/${subID}_T1W_brain_restore \
            -schedule $FSLDIR/etc/flirtsch/measurecost1.sch \
            -init $WD/func2struct.mat \
            -cost corratio|head -1|cut -f1 -d ' '`
        # ------------------------------

        # -- SPE -----------------------
        WD="${VPDIR}/${subID}/ANALYSIS/${taskName}/FMAP-SPE/work"

        costAfterSPE1=`flirt -in $WD/func01_processed.nii.gz \
            -ref ${t1Dir}/FAST/${subID}_T1W_brain_restore \
            -schedule $FSLDIR/etc/flirtsch/measurecost1.sch \
            -init $WD/func2struct.mat \
            -wmseg ${t1Dir}/FAST/${subID}_T1W_brain_wmseg.nii.gz \
            -cost bbr|head -1|cut -f1 -d ' '`
        costAfterSPE2=`flirt -in $WD/func01_processed.nii.gz \
            -ref ${t1Dir}/FAST/${subID}_T1W_brain_restore \
            -schedule $FSLDIR/etc/flirtsch/measurecost1.sch \
            -init $WD/func2struct.mat \
            -cost normmi|head -1|cut -f1 -d ' '`
        costAfterSPE3=`flirt -in $WD/func01_processed.nii.gz \
            -ref ${t1Dir}/FAST/${subID}_T1W_brain_restore \
            -schedule $FSLDIR/etc/flirtsch/measurecost1.sch \
            -init $WD/func2struct.mat \
            -cost corratio|head -1|cut -f1 -d ' '`
        # ------------------------------
        
        # -- EPI -----------------------
        WD="${VPDIR}/${subID}/ANALYSIS/${taskName}/FMAP-EPI/work"

        costAfterEPI1=`flirt -in $WD/func01_processed.nii.gz \
            -ref ${t1Dir}/FAST/${subID}_T1W_brain_restore \
            -schedule $FSLDIR/etc/flirtsch/measurecost1.sch \
            -init $WD/func2struct.mat \
            -wmseg ${t1Dir}/FAST/${subID}_T1W_brain_wmseg.nii.gz \
            -cost bbr|head -1|cut -f1 -d ' '`
        costAfterEPI2=`flirt -in $WD/func01_processed.nii.gz \
            -ref ${t1Dir}/FAST/${subID}_T1W_brain_restore \
            -schedule $FSLDIR/etc/flirtsch/measurecost1.sch \
            -init $WD/func2struct.mat \
            -cost normmi|head -1|cut -f1 -d ' '`
        costAfterEPI3=`flirt -in $WD/func01_processed.nii.gz \
            -ref ${t1Dir}/FAST/${subID}_T1W_brain_restore \
            -schedule $FSLDIR/etc/flirtsch/measurecost1.sch \
            -init $WD/func2struct.mat \
            -cost corratio|head -1|cut -f1 -d ' '`
        # ------------------------------

        # -- GRE -----------------------
        WD="${VPDIR}/${subID}/ANALYSIS/${taskName}/FMAP-GRE/prestats+dc.feat/reg/"
        
        costAfterGRE1=`flirt -in $WD/example_func.nii.gz \
            -ref ${t1Dir}/FAST/${subID}_T1W_brain_restore \
            -schedule $FSLDIR/etc/flirtsch/measurecost1.sch \
            -init $WD/example_func2highres.mat \
            -wmseg ${t1Dir}/FAST/${subID}_T1W_brain_wmseg.nii.gz \
            -cost bbr|head -1|cut -f1 -d ' '`
        costAfterGRE2=`flirt -in $WD/example_func.nii.gz \
            -ref ${t1Dir}/FAST/${subID}_T1W_brain_restore \
            -schedule $FSLDIR/etc/flirtsch/measurecost1.sch \
            -init $WD/example_func2highres.mat \
            -cost normmi|head -1|cut -f1 -d ' '`
        costAfterGRE3=`flirt -in $WD/example_func.nii.gz \
            -ref ${t1Dir}/FAST/${subID}_T1W_brain_restore \
            -schedule $FSLDIR/etc/flirtsch/measurecost1.sch \
            -init $WD/example_func2highres.mat \
            -cost corratio|head -1|cut -f1 -d ' '`
        # ------------------------------

        # -- GRE-EPI -----------------------
        WD="${VPDIR}/${subID}/ANALYSIS/${taskName}/FMAP-GRE-EPI/prestats+dc.feat/reg/"
        
        costAfterGREEPI1=`flirt -in $WD/example_func.nii.gz \
            -ref ${t1Dir}/FAST/${subID}_T1W_brain_restore \
            -schedule $FSLDIR/etc/flirtsch/measurecost1.sch \
            -init $WD/example_func2highres.mat \
            -wmseg ${t1Dir}/FAST/${subID}_T1W_brain_wmseg.nii.gz \
            -cost bbr|head -1|cut -f1 -d ' '`
        costAfterGREEPI2=`flirt -in $WD/example_func.nii.gz \
            -ref ${t1Dir}/FAST/${subID}_T1W_brain_restore \
            -schedule $FSLDIR/etc/flirtsch/measurecost1.sch \
            -init $WD/example_func2highres.mat \
            -cost normmi|head -1|cut -f1 -d ' '`
        costAfterGREEPI3=`flirt -in $WD/example_func.nii.gz \
            -ref ${t1Dir}/FAST/${subID}_T1W_brain_restore \
            -schedule $FSLDIR/etc/flirtsch/measurecost1.sch \
            -init $WD/example_func2highres.mat \
            -cost corratio|head -1|cut -f1 -d ' '`
        # ------------------------------

        # -- GRE-SPE -----------------------
        WD="${VPDIR}/${subID}/ANALYSIS/${taskName}/FMAP-GRE-SPE/prestats+dc.feat/reg/"
        
        costAfterGRESPE1=`flirt -in $WD/example_func.nii.gz \
            -ref ${t1Dir}/FAST/${subID}_T1W_brain_restore \
            -schedule $FSLDIR/etc/flirtsch/measurecost1.sch \
            -init $WD/example_func2highres.mat \
            -wmseg ${t1Dir}/FAST/${subID}_T1W_brain_wmseg.nii.gz \
            -cost bbr|head -1|cut -f1 -d ' '`
        costAfterGRESPE2=`flirt -in $WD/example_func.nii.gz \
            -ref ${t1Dir}/FAST/${subID}_T1W_brain_restore \
            -schedule $FSLDIR/etc/flirtsch/measurecost1.sch \
            -init $WD/example_func2highres.mat \
            -cost normmi|head -1|cut -f1 -d ' '`
        costAfterGRESPE3=`flirt -in $WD/example_func.nii.gz \
            -ref ${t1Dir}/FAST/${subID}_T1W_brain_restore \
            -schedule $FSLDIR/etc/flirtsch/measurecost1.sch \
            -init $WD/example_func2highres.mat \
            -cost corratio|head -1|cut -f1 -d ' '`
        # ------------------------------

        # Write to file
        printf "%s %s %s %s %s %s %s %s\n" ${subID} ${taskName} ${costBefore1} ${costAfterSPE1} ${costAfterEPI1} ${costAfterGRE1} ${costAfterGREEPI1} ${costAfterGRESPE1}  >> $outputFileName1
        printf "%s %s %s %s %s %s %s %s\n" ${subID} ${taskName} ${costBefore2} ${costAfterSPE2} ${costAfterEPI2} ${costAfterGRE2} ${costAfterGREEPI2} ${costAfterGRESPE2}  >> $outputFileName2
        printf "%s %s %s %s %s %s %s %s\n" ${subID} ${taskName} ${costBefore3} ${costAfterSPE3} ${costAfterEPI3} ${costAfterGRE3} ${costAfterGREEPI3} ${costAfterGRESPE3}  >> $outputFileName3

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
