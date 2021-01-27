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