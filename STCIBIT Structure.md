# STCIBIT structure

```
MAIN folder
│   PROTOCOL.pdf
│   SEQUENCES.pdf   
│
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