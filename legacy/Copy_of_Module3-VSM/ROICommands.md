# Summary of ROIs

https://docs.google.com/spreadsheets/d/1x--DiMogQ_PT04_BLPrlGd24gc5EgTFg_G8y9U1hFCI/edit#gid=0

# Sources

source of glasser mni: [https://neurovault.org/collections/1549/](https://neurovault.org/collections/1549/) (using "HCPMMP1_on_MNI152_ICBM2009a_nlin_hd.nii.gz")

labels from [https://static-content.springer.com/esm/art%3A10.1038%2Fnature18933/MediaObjects/41586_2016_BFnature18933_MOESM330_ESM.pdf](https://static-content.springer.com/esm/art%3A10.1038%2Fnature18933/MediaObjects/41586_2016_BFnature18933_MOESM330_ESM.pdf)

CIT168: [https://osf.io/r2hvk/](https://osf.io/r2hvk/)

How to extract value from ROI [https://andysbrainbook.readthedocs.io/en/latest/fMRI_Short_Course/fMRI_09_ROIAnalysis.html](https://andysbrainbook.readthedocs.io/en/latest/fMRI_Short_Course/fMRI_09_ROIAnalysis.html)

Brainnetome: [https://atlas.brainnetome.org/download.html](https://atlas.brainnetome.org/download.html)

# Commands

To extract mask roi with ID=2 from Glasser

```bash
fslmaths Glasser_HCPMMP1_on_MNI152_ICBM2009a_nlin_hd.nii.gz \
	-thr 2 -uthr 2 -bin temp_mst.nii.gz
```

To extract mask roi with ID=201 from Brainnetome assuming 50%

```bash
fslroi BNA_PM_4D.nii.gz temp_mt_l 200 1

fslmaths temp_mt_l -thr 50 -bin temp_mt_l_mask
```

to extract mask roi with ID = 2 (zero based) from CIT168 assuming 50%

```bash
fslroi CIT168_CIT168toMNI152-2009c_prob.nii.gz temp_nac 2 1

fslmaths temp_nac.nii.gz -thr 0.5 -bin temp_nac_mask
```

Combine rois

```bash
fslmaths glasser_3a_mask.nii.gz -add glasser_s1_mask.nii.gz -bin glasser_3a3b_mask
```

Check center of mass of mask

```bash
fslstats NAc_R_brainnetome.nii.gz -c
```