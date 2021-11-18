#!/bin/bash

# screen -L -Logfile speMain-logfile.txt -S spe

# --------------------------------------------------------------------------------
#  Setup
# --------------------------------------------------------------------------------

subList="VPMBAUS01 VPMBAUS02 VPMBAUS03 VPMBAUS05 VPMBAUS06 VPMBAUS07 VPMBAUS08 VPMBAUS10 VPMBAUS11 VPMBAUS12 VPMBAUS15 VPMBAUS16 VPMBAUS21 VPMBAUS22 VPMBAUS23"
taskList="TASK-LOC-1000 TASK-AA-0500 TASK-AA-0750 TASK-AA-1000 TASK-AA-2500 TASK-UA-0500 TASK-UA-0750 TASK-UA-1000 TASK-UA-2500"
roTimeList=(0.0415863 0.0432825 0.0415863 0.0415863 0.025030 0.0432825 0.0415863 0.0415863 0.025030)
nThreadsS=6
VPDIR="/DATAPOOL/VPMB/VPMB-STCIBIT" # data folder

# --------------------------------------------------------------------------------
#  Define function
# --------------------------------------------------------------------------------
speRoutine () {

    # --------------------------------------------------------------------------------
    #  Settings
    # --------------------------------------------------------------------------------

    VPDIR=${1}                         # data folder
    subID=${2}                                           # subject ID
    taskName=${3}                                    # task name
    taskDir="${VPDIR}/${subID}/ANALYSIS/${taskName}"            # task directory
    fmapDir="${VPDIR}/${subID}/ANALYSIS/${taskName}/FMAP-SPE"   # fmap directory
    WD="${VPDIR}/${subID}/ANALYSIS/${taskName}/FMAP-SPE/work"   # working directory
    t1Dir="${VPDIR}/${subID}/ANALYSIS/T1W"                      # T1w directory
    ro_time=${4} # in seconds
    nThreads=6 # number of threads

    echo ${VPDIR} ${subID} ${taskName} ${roTime}

    # --------------------------------------------------------------------------------
    #  Create/Clean folder
    # --------------------------------------------------------------------------------

    if [ ! -e $WD ] ; then # not exists
        mkdir -p $WD
        echo "--> FMAP-SPE/work folder created."
    elif [ "$(ls -A ${WD})" ] ; then # not empty
        rm -r ${WD}/*
        echo "--> FMAP-SPE/work folder cleared."
    else
        echo "--> FMAP-SPE/work folder ready."
    fi

    # --------------------------------------------------------------------------------
    #  Copy files and Brain Extraction and Bias field correction
    # --------------------------------------------------------------------------------

    # Copy functional data and SPEs
    cp $VPDIR/$subID/RAW/${taskName}/${subID}_${taskName}.nii.gz $WD/func.nii.gz
    cp $VPDIR/$subID/RAW/${taskName}/${subID}_FMAP-SPE-AP.nii.gz $WD/spe-ap.nii.gz
    cp $VPDIR/$subID/RAW/${taskName}/${subID}_FMAP-SPE-PA.nii.gz $WD/spe-pa.nii.gz

    # Create func01 (first volume of functional data)
    fslroi $WD/func.nii.gz $WD/func01.nii.gz 0 1

    # BET func01 and SPE
    bet2 $WD/func01.nii.gz $WD/funcMask -f 0.3 -n -m     # calculate func01 brain mask
    bet2 $WD/spe-ap.nii.gz $WD/spe-apMask -f 0.3 -n -m   # calculate spe-ap brain mask

    mv $WD/funcMask_mask.nii.gz $WD/func_brain_mask.nii.gz      # rename func01 brain mask
    mv $WD/spe-apMask_mask.nii.gz $WD/spe-ap_brain_mask.nii.gz  # rename spe brain mask

    fslmaths $WD/func01.nii.gz -mas $WD/func_brain_mask.nii.gz $WD/func01_brain.nii.gz    # apply func01 brain mask
    fslmaths $WD/spe-ap.nii.gz -mas $WD/spe-ap_brain_mask.nii.gz $WD/spe-ap_brain.nii.gz  # apply spe brain mask

    # Bias field correction
    fast -B $WD/func01_brain.nii.gz &  # output: func01_brain_restore
    fast -B $WD/spe-ap_brain.nii.gz    # output: spe_brain_restore

    # --------------------------------------------------------------------------------
    #  Calculate func2spe and spe2func transformation matrices
    # --------------------------------------------------------------------------------

    # Align func01 to SPE-AP and export transformation matrix func2spe.mat
    flirt -ref $WD/spe-ap_brain_restore.nii.gz \
        -in $WD/func01_brain_restore.nii.gz \
        -out $WD/func2spe.nii.gz \
        -omat $WD/func2spe.mat \
        -cost normmi \
        -interp sinc \
        -dof 6 -v

    # Invert transformation matrix
    convert_xfm -inverse $WD/func2spe.mat \
                -omat $WD/spe2func.mat

    # --------------------------------------------------------------------------------
    #  Slice timing correction (ST)
    # --------------------------------------------------------------------------------
    customSTFile=${VPDIR}/${subID}/ANALYSIS/${taskName}/st_order.txt

    slicetimer -i $WD/func.nii.gz -o $WD/func_stc.nii.gz --tcustom=$customSTFile -v

    # --------------------------------------------------------------------------------
    #  Motion Correction (MC)
    # --------------------------------------------------------------------------------

    # Align all volumes to the first (func01)
    mcflirt -in $WD/func_stc.nii.gz \
            -refvol 0 \
            -o $WD/func_stc_mc \
            -mats -plots -report

    # --------------------------------------------------------------------------------
    #  TOPUP - Distortion Correction (DC)
    # --------------------------------------------------------------------------------

    # Create topup config file
    echo "0 -1 0 $ro_time" > $WD/acqparams.txt
    echo "0 1 0 $ro_time" >> $WD/acqparams.txt

    # Merge SPEs (AP image first)
    fslmerge -t ${WD}/speMerge ${WD}/spe-ap.nii.gz ${WD}/spe-pa.nii.gz

    # Create mask (Single volume containing all 1's)
    fslmaths ${WD}/speMerge -mul 0 -add 1 -Tmin ${WD}/speMask

    # Extrapolate the existing values beyond the mask (adding 1 just to avoid smoothing inside the mask)
    ${FSLDIR}/bin/fslmaths ${WD}/speMerge \
        -abs -add 1 \
        -mas ${WD}/speMask \
        -dilM -dilM -dilM -dilM -dilM \
        ${WD}/speMerge

    # Topup
    topup --imain=${WD}/speMerge \
        --datain=$WD/acqparams.txt \
        --config=b02b0.cnf \
        --out=${WD}/Coefficents \
        --iout=${WD}/Magnitudes \
        --fout=${WD}/TopupField \
        --dfout=${WD}/WarpField \
        --rbmout=${WD}/MotionMatrix \
        --jacout=${WD}/Jacobian -v

    # Jacobian to func space
    flirt -ref $WD/func01.nii.gz \
        -in $WD/Jacobian_01.nii.gz \
        -out $WD/Jacobian2func.nii.gz \
        -interp sinc \
        -init $WD/spe2func.mat \
        -applyxfm -v

    # Calculate Equivalent Field Map (magnitude+phase)
    fslmaths ${WD}/TopupField -mul 6.283 ${WD}/GREfromTOPUP-Phase
    fslmaths ${WD}/Magnitudes -Tmean ${WD}/GREfromTOPUP-Magnitude
    bet ${WD}/GREfromTOPUP-Magnitude ${WD}/GREfromTOPUP-Magnitude_brain -f 0.4 -m #Brain extract the magnitude image

    # --------------------------------------------------------------------------------
    #  Apply correction to SPE images (QA)
    # --------------------------------------------------------------------------------

    # AP
    ${FSLDIR}/bin/applywarp \
        --rel \
        --interp=sinc \
        -i ${WD}/spe-ap \
        -r ${WD}/speMask \
        --premat=${WD}/MotionMatrix_01.mat \
        -w ${WD}/WarpField_01 \
        -o ${WD}/spe-ap_dc

    ${FSLDIR}/bin/fslmaths \
        ${WD}/spe-ap_dc \
        -mul ${WD}/Jacobian_01 \
        ${WD}/spe-ap_dc_jac

    # PA
    ${FSLDIR}/bin/applywarp \
        --rel \
        --interp=sinc \
        -i ${WD}/spe-pa \
        -r ${WD}/speMask \
        --premat=${WD}/MotionMatrix_02.mat \
        -w ${WD}/WarpField_02 \
        -o ${WD}/spe-pa_dc

    ${FSLDIR}/bin/fslmaths \
        ${WD}/spe-pa_dc \
        -mul ${WD}/Jacobian_02 \
        ${WD}/spe-pa_dc_jac
        
    # --------------------------------------------------------------------------------
    #  One Step Resampling (apply MC+DC)
    # --------------------------------------------------------------------------------

    # Create aux folders
    if [ ! -e $WD/preVols ] ; then # not exists
        mkdir $WD/preVols
        mkdir $WD/postVols
        echo "--> preVols folder created."
    fi

    # Save number of volumes
    nVols=`fslnvols $WD/func.nii.gz`

    # Iterate on the volumes
    for ((vv=0; vv < $nVols; vv++))
    do

        (
        
        # concatenate func2spe and MC matrices (linear)
        convert_xfm -omat $(printf "${WD}/func_stc_mc.mat/CONCAT_%04d" ${vv}) \
                    -concat $WD/func2spe.mat $(printf "${WD}/func_stc_mc.mat/MAT_%04d" ${vv})

        # isolate raw functional volume $vv
        fslroi $WD/func_stc.nii.gz $(printf "${WD}/preVols/func_%04d.nii.gz" ${vv}) $vv 1 

        # concatenate transformations for volume $vv (linear+nonlinear)
        convertwarp --ref=$WD/func01.nii.gz \
                --out=$(printf "${WD}/preVols/MatrixAll_%04d.nii.gz" ${vv}) \
                --premat=$(printf "${WD}/func_stc_mc.mat/CONCAT_%04d" ${vv}) \
                --warp1=$WD/WarpField_01 \
                --postmat=$WD/spe2func.mat \
                --rel --verbose
        
        # apply warps (mc + dc)
        applywarp -i $(printf "${WD}/preVols/func_%04d.nii.gz" ${vv}) \
                -o $(printf "${WD}/postVols/func_%04d.nii.gz" ${vv}) \
                -r $WD/func01.nii.gz \
                -w $(printf "${WD}/preVols/MatrixAll_%04d.nii.gz" ${vv}) \
                --interp=sinc

        echo $(printf "Volume %04d of %04d...\n" ${vv} $nVols)

        ) & # parallel power

        # allow to execute up to $nThreads jobs in parallel
        if [[ $(jobs -r -p | wc -l) -ge $nThreads ]]; then
            # now there are $nThreads jobs already running, so wait here for any job
            # to be finished so there is a place to start next one.
            wait -n
        fi

    done
    wait

    # Create string of all volumes to merge (separately from the paralell cycle above)
    VolumeMergeSTRING=""
    for ((vv=0; vv < $nVols; vv++))
    do
        VolumeMergeSTRING+=$(printf "${WD}/postVols/func_%04d.nii.gz " ${vv})
    done

    # Merge all volumes again
    TR=`fslval ${WD}/func.nii.gz pixdim4 | cut -d " " -f 1`
    fslmerge -tr $WD/func_stc_mc_dc.nii.gz $VolumeMergeSTRING $TR

    # --------------------------------------------------------------------------------
    #  BET, Bias field correction, Jacobian modulation
    # --------------------------------------------------------------------------------

    # BET 1st volume
    bet2 ${WD}/postVols/func_0000.nii.gz\
        ${WD}/postVols/func_0000 -f 0.3 -m -n

    # Apply BET to 1st volume
    fslmaths ${WD}/postVols/func_0000.nii.gz \
            -mas ${WD}/postVols/func_0000_mask.nii.gz \
            ${WD}/postVols/func_0000_brain.nii.gz

    # Estimate bias field
    fast -b ${WD}/postVols/func_0000_brain.nii.gz

    # Apply BET, bias field, and Jacobian modulation to func
    fslmaths $WD/func_stc_mc_dc.nii.gz \
            -mul $WD/Jacobian2func.nii.gz \
            -mas ${WD}/postVols/func_0000_mask.nii.gz \
            -div ${WD}/postVols/func_0000_brain_bias.nii.gz \
            ${WD}/func_stc_mc_dc_jac_brain_restore.nii.gz

    # --------------------------------------------------------------------------------
    #  Register corrected func to T1w
    # --------------------------------------------------------------------------------

    # Create func01_processed (first volume of corrected functional data)
    fslroi ${WD}/func_stc_mc_dc_jac_brain_restore.nii.gz $WD/func01_processed.nii.gz 0 1

    # Estimate registration
    epi_reg --epi=$WD/func01_processed.nii.gz \
            --t1=${t1Dir}/FAST/${subID}_T1W_restore \
            --t1brain=${t1Dir}/FAST/${subID}_T1W_brain_restore \
            --wmseg=${t1Dir}/FAST/${subID}_T1W_brain_wmseg \
            --out=$WD/func2struct -v

    # --------------------------------------------------------------------------------
    #  Export
    # --------------------------------------------------------------------------------

    cp ${WD}/func_stc_mc_dc_jac_brain_restore.nii.gz $fmapDir/filtered_func_data.nii.gz

}

topupRoutine () {

    # --------------------------------------------------------------------------------
    #  Settings
    # --------------------------------------------------------------------------------

    VPDIR=${1}                         # data folder
    subID=${2}                                           # subject ID
    taskName=${3}                                    # task name
    taskDir="${VPDIR}/${subID}/ANALYSIS/${taskName}"            # task directory
    fmapDir="${VPDIR}/${subID}/ANALYSIS/${taskName}/FMAP-SPE"   # fmap directory
    WD="${VPDIR}/${subID}/ANALYSIS/${taskName}/FMAP-SPE/work"   # working directory
    ro_time=${4} # in seconds

    echo ${VPDIR} ${subID} ${taskName} ${roTime}

    # --------------------------------------------------------------------------------
    #  TOPUP - Distortion Correction (DC)
    # --------------------------------------------------------------------------------

    # Create topup config file
    echo "0 -1 0 $ro_time" > $WD/acqparams.txt
    echo "0 1 0 $ro_time" >> $WD/acqparams.txt

    # Merge SPEs (AP image first)
    fslmerge -t ${WD}/speMerge ${WD}/spe-ap.nii.gz ${WD}/spe-pa.nii.gz

    # Topup
    topup --imain=${WD}/speMerge \
        --datain=$WD/acqparams.txt \
        --config=b02b0.cnf \
        --out=${WD}/Coefficents \
        --iout=${WD}/Magnitudes \
        --fout=${WD}/TopupField \
        --dfout=${WD}/WarpField \
        --rbmout=${WD}/MotionMatrix \
        --jacout=${WD}/Jacobian -v

    # Jacobian to func space
    flirt -ref $WD/func01.nii.gz \
        -in $WD/Jacobian_01.nii.gz \
        -out $WD/Jacobian2func.nii.gz \
        -interp sinc \
        -init $WD/spe2func.mat \
        -applyxfm -v

    # Calculate Equivalent Field Map (magnitude+phase)
    fslmaths ${WD}/TopupField -mul 6.283 ${WD}/GREfromTOPUP-PHASE
    fslmaths ${WD}/Magnitudes -Tmean ${WD}/GREfromTOPUP-MAGNITUDE
    bet ${WD}/GREfromTOPUP-MAGNITUDE ${WD}/GREfromTOPUP-MAGNITUDE_brain -f 0.4 -m #Brain extract the magnitude image

}

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
    roCounter=0

    # Iterate on the runs
    for taskName in $taskList
    do

        echo "-----> $taskName <-----" 

        roTime=${roTimeList[$roCounter]}
       
        # main function
        speRoutine ${VPDIR} ${subID} ${taskName} ${roTime}
        #topupRoutine ${VPDIR} ${subID} ${taskName} ${roTime}

        # increase counter
        roCounter=$[$roCounter+1]

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

# --------------------------------------------------------------------------------
#  Elapsed time
# --------------------------------------------------------------------------------

endTime="`date "+%s"`"
elapsedTime=$(($endTime - $startTime))
((sec=elapsedTime%60, elapsedTime/=60, min=elapsedTime%60, hrs=elapsedTime/60))
echo "---> ELAPSED TIME $(printf "%d:%02d:%02d" $hrs $min $sec)"