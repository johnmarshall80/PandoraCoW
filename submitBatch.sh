#!/bin/bash

# ==========================================================================================================================================
# Editable settings
# ==========================================================================================================================================

USERID=phsnpc
MY_TEST_AREA=/storage/epp2/phsnpc/github/
PANDORA_COW_DIR=/storage/epp2/phsnpc/cow/PandoraCoW/

PANDORA_BIN=$MY_TEST_AREA/LArReco/bin/PandoraInterface
SETUP_SCRIPT=$MY_TEST_AREA/setup.sh
RECO_OPTION=AllHitsNu
SETTINGS_FILE=$MY_TEST_AREA/LArReco/settings/PandoraSettings_Master_MicroBooNE.xml
GEOMETRY_FILE=/storage/dune/uB_mcc9-0_samples/Pandora_Geometry_MCC9.0.xml
EVENTS=/storage/dune/uB_mcc9-0_samples/prodgenie_bnb_nu_only_v12/*.pndr

FILES_PER_JOB=5
NUM_JOBS=250
MAX_SIMULTANEOUS_JOBS=20

# ==========================================================================================================================================
# ==========================================================================================================================================

# Clean up inputs
PANDORA_BIN=`readlink -f $PANDORA_BIN`                                                                                                         
SETUP_SCRIPT=`readlink -f $SETUP_SCRIPT`                                                                                                       
SETTINGS_FILE=`readlink -f $SETTINGS_FILE`                                                                                                     
GEOMETRY_FILE=`readlink -f $GEOMETRY_FILE`                                                                                                     
PANDORA_COW_DIR=`readlink -f $PANDORA_COW_DIR`                                                                                           

# ==========================================================================================================================================

# Derived paths
WORKING_DIR=$PANDORA_COW_DIR/work
GENERIC_JOB=$PANDORA_COW_DIR/generic/pandoraJob
JOBS_LIST=$WORKING_DIR/jobsList
JOB_NAME=`basename $GENERIC_JOB`

# ==========================================================================================================================================

# Clean up the working directory and move to it
if [ -d $WORKING_DIR ]; then
    echo "Working directory already exists! : ${WORKING_DIR}"
    exit 1
fi

mkdir -p $WORKING_DIR
cd $WORKING_DIR

# ==========================================================================================================================================

# Make the job files
JOB_INDEX=0
FILE_INDEX=0
FILE_PER_JOB_INDEX=0

FILE_LIST=""
NUM_FILES=`ls ${EVENTS} | wc -l`

for FILE in $EVENTS; do
    # Append this file to the current list
    if [ $FILE_PER_JOB_INDEX -eq 0 ]; then
        FILE_LIST=$FILE
    else
        FILE_LIST=$FILE_LIST:$FILE
    fi

    FILE_INDEX=$(( $FILE_INDEX + 1 ))
    FILE_PER_JOB_INDEX=$(( $FILE_PER_JOB_INDEX + 1 ))

    # Make new job file
    if [ $FILE_PER_JOB_INDEX -eq $FILES_PER_JOB ] || [ $FILE_INDEX -eq $NUM_FILES ]; then

        JOB_DIR=${WORKING_DIR}/job${JOB_INDEX}
        mkdir $JOB_DIR
        JOB_FILE=${JOB_DIR}/pandoraJob
        echo $JOB_FILE >> $JOBS_LIST

        cp $GENERIC_JOB $JOB_FILE
    
        sed -i "s|SETUP_SCRIPT|${SETUP_SCRIPT}|g" $JOB_FILE
        sed -i "s|PANDORA_BIN|${PANDORA_BIN}|g" $JOB_FILE
        sed -i "s|RECO_OPTION|${RECO_OPTION}|g" $JOB_FILE
        sed -i "s|SETTINGS_FILE|${SETTINGS_FILE}|g" $JOB_FILE
        sed -i "s|GEOMETRY_FILE|${GEOMETRY_FILE}|g" $JOB_FILE
        sed -i "s|FILE_LIST|${FILE_LIST}|g" $JOB_FILE

        JOB_INDEX=$(( $JOB_INDEX + 1 ))
        FILE_PER_JOB_INDEX=0

        if [ $JOB_INDEX -eq $NUM_JOBS ]; then
            break
        fi
    fi
done

# ==========================================================================================================================================

# Submit jobs
echo; echo
NUM_JOBS_LEFT=$NUM_JOBS
while [ $NUM_JOBS_LEFT -gt 0 ]; do

    NUM_QUEUED_JOBS=`squeue -u $USERID -n $JOB_NAME | wc -l`
    NUM_QUEUED_JOBS=$(( $NUM_QUEUED_JOBS - 1 ))

    if [ $NUM_QUEUED_JOBS -lt $MAX_SIMULTANEOUS_JOBS ]; then

        # Pop the next job from the head of the jobs list
        NEXT_JOB=`head -n 1 $JOBS_LIST`
        tail -n +2 $JOBS_LIST > tmp
        cat tmp > $JOBS_LIST
        rm -rf tmp

        JOB_INDEX=`echo ${NEXT_JOB} | grep -oE 'job[0-9]+' | grep -oE '[0-9]+'`
        cd ${WORKING_DIR}/job${JOB_INDEX}

        sbatch $NEXT_JOB > /dev/null
        cd ${WORKING_DIR}
    fi
    NUM_JOBS_LEFT=`cat $JOBS_LIST | wc -l`
    
    echo -en "\e[2A"
    echo "Jobs queued    : ${NUM_QUEUED_JOBS} "
    echo "Jobs to submit : ${NUM_JOBS_LEFT}   "

    sleep 0.5
done

# ==========================================================================================================================================

# Monitor remaining jobs
echo -en "\e[2A"
echo "All jobs submitted!"
while [ $NUM_QUEUED_JOBS -gt 0 ]; do
    # TODO Some print out about number of running jobs
    # echo -en "\e[1A"
    NUM_QUEUED_JOBS=`squeue -u $USERID -n $JOB_NAME | wc -l`
    NUM_QUEUED_JOBS=$(( $NUM_QUEUED_JOBS - 1 ))
    sleep 0.5
done

cd -
