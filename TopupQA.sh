# --------------------------------------------------------------------------------
#  Settings
# --------------------------------------------------------------------------------

VPDIR="/DATAPOOL/VPMB/VPMB-STCIBIT"                         # data folder
subID="VPMBAUS03"                                           # subject ID
taskName="TASK-LOC-1000"                                    # task name
taskDir="${VPDIR}/${subID}/ANALYSIS/${taskName}"            # task directory
fmapDir="${VPDIR}/${subID}/ANALYSIS/${taskName}/FMAP-SPE"   # fmap directory
WD="${VPDIR}/${subID}/ANALYSIS/${taskName}/FMAP-SPE/qa"   # working directory

# --------------------------------------------------------------------------------
#  Create/Clean folder
# --------------------------------------------------------------------------------

if [ ! -e $WD ] ; then # not exists
    mkdir -p $WD
    echo "--> FMAP-SPE/qa folder created."
elif [ "$(ls -A ${WD})" ] ; then # not empty
    rm -r ${WD}/*
    echo "--> FMAP-SPE/qa folder cleared."
else
    echo "--> FMAP-SPE/qa folder ready."
fi

# --------------------------------------------------------------------------------
#  Copy files
# --------------------------------------------------------------------------------

cp $fmapDir/work/func01.nii.gz $WD/func01.nii.gz

# --------------------------------------------------------------------------------
#  Stuff
# --------------------------------------------------------------------------------

# Extract brain
bet2 $WD/func01.nii.gz $WD/func01_brain.nii.gz -o -m -f 0.5

#Takes a bet2 extracted image and it's original, and creates a mask of the outline. final image is input_outline

fslmaths $WD/func01_brain_overlay.nii.gz -sub $WD/func01.nii.gz $WD/func01_diff_out
thresh=`fslstats $WD/func01_diff_out.nii.gz -p 97`
fslmaths $WD/func01_diff_out.nii.gz -thr $thresh $WD/func01_thresh.nii.gz
fslmaths $WD/func01_thresh.nii.gz -bin $WD/func01_brain_outline.nii.gz

#creates an overlay of image 2 over image1

overlay 0 0 $WD/func01.nii.gz -a $WD/func01_brain_outline.nii.gz 0.001 5 $WD/overlay1
slicer $WD/overlay1 -c -s 3 -x 0.5 $WD/x0v.png -y 0.5 $WD/y0v.png -z 0.5 $WD/z0v.png
pngappend $WD/x0v.png + 4 $WD/y0v.png + 4 $WD/z0v.png $WD/overlay1.png
