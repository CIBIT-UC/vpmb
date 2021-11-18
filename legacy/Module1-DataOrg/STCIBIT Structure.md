# STCIBIT structure

```
MAIN folder
│   PROTOCOL.pdf
│   SEQUENCES.pdf   
│   VERSION.txt
└───<subID>
│   │
│   └───RAW
│   │  │
│   │  └───T1W
│   │  │    <subID>_T1W.nii.gz
│   │  │    <subID>_T1W.json
│   │  │
│   │  └───TASK-<runName>
│   │      │   <subID>_TASK-<runName>.nii.gz
│   │      │   <subID>_TASK-<runName>.json
│   │      │   
│   │      │   <subID>_FMAP-EPI-AP.nii.gz
│   │      │   <subID>_FMAP-EPI-PA.nii.gz
│   │      │
│   │      └───LINKED
│   │           <subID>_EYETRACKER.edf
│   │           <subID>_PHYSIO_Info.log
│   │           <subID>_PHYSIO_RESP.log
│   │           <subID>_PHYSIO_PULS.log
│   │           <subID>_KEYPRESS.mat
│   │
│   └───processed data will be placed here inside each folder
│
└───<subID>
        ...
```

# Example

```
VPMB-STCIBIT/
├── PROTOCOL.pdf
├── SEQUENCES.pdf
├── VERSION.txt
├── VPMBAUS01
│   └── RAW
│       ├── T1W
│       │   ├── LINKED
│       │   ├── VPMBAUS01_T1W.json
│       │   └── VPMBAUS01_T1W.nii.gz
│       ├── TASK-AA-0500
│       │   ├── LINKED
│       │   │   ├── VPMBAUS01_EYETRACKER.edf
│       │   │   ├── VPMBAUS01_KEYPRESS.mat
│       │   │   ├── VPMBAUS01_PHYSIO_Info.log
│       │   │   ├── VPMBAUS01_PHYSIO_PULS.log
│       │   │   ├── VPMBAUS01_PHYSIO_RESP.log
│       │   │   └── VPMBAUS01_PROTOCOL.prt
│       │   ├── VPMBAUS01_FMAP-EPI-AP.json
│       │   ├── VPMBAUS01_FMAP-EPI-AP.nii.gz
│       │   ├── VPMBAUS01_FMAP-EPI-PA.json
│       │   ├── VPMBAUS01_FMAP-EPI-PA.nii.gz
│       │   ├── VPMBAUS01_FMAP-GRE-E1.json
│       │   ├── VPMBAUS01_FMAP-GRE-E1.nii.gz
│       │   ├── VPMBAUS01_FMAP-GRE-E2.json
│       │   ├── VPMBAUS01_FMAP-GRE-E2.nii.gz
│       │   ├── VPMBAUS01_FMAP-GRE-PH.json
│       │   ├── VPMBAUS01_FMAP-GRE-PH.nii.gz
│       │   ├── VPMBAUS01_FMAP-SPE-AP.json
│       │   ├── VPMBAUS01_FMAP-SPE-AP.nii.gz
│       │   ├── VPMBAUS01_FMAP-SPE-PA.json
│       │   ├── VPMBAUS01_FMAP-SPE-PA.nii.gz
│       │   ├── VPMBAUS01_TASK-AA-0500.json
│       │   └── VPMBAUS01_TASK-AA-0500.nii.gz
│       ├── TASK-AA-0750
│       │   ├── LINKED
│       │   │   ├── VPMBAUS01_EYETRACKER.edf
│       │   │   ├── VPMBAUS01_KEYPRESS.mat
│       │   │   ├── VPMBAUS01_PHYSIO_Info.log
│       │   │   ├── VPMBAUS01_PHYSIO_PULS.log
│       │   │   ├── VPMBAUS01_PHYSIO_RESP.log
│       │   │   └── VPMBAUS01_PROTOCOL.prt
│       │   ├── VPMBAUS01_FMAP-EPI-AP.json
│       │   ├── VPMBAUS01_FMAP-EPI-AP.nii.gz
│       │   ├── VPMBAUS01_FMAP-EPI-PA.json
│       │   ├── VPMBAUS01_FMAP-EPI-PA.nii.gz
│       │   ├── VPMBAUS01_FMAP-GRE-E1.json
│       │   ├── VPMBAUS01_FMAP-GRE-E1.nii.gz
│       │   ├── VPMBAUS01_FMAP-GRE-E2.json
│       │   ├── VPMBAUS01_FMAP-GRE-E2.nii.gz
│       │   ├── VPMBAUS01_FMAP-GRE-PH.json
│       │   ├── VPMBAUS01_FMAP-GRE-PH.nii.gz
│       │   ├── VPMBAUS01_FMAP-SPE-AP.json
│       │   ├── VPMBAUS01_FMAP-SPE-AP.nii.gz
│       │   ├── VPMBAUS01_FMAP-SPE-PA.json
│       │   ├── VPMBAUS01_FMAP-SPE-PA.nii.gz
│       │   ├── VPMBAUS01_TASK-AA-0750.json
│       │   └── VPMBAUS01_TASK-AA-0750.nii.gz
...
```
