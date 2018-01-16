#!/bin/bash

# ==========================================================================================================================================
# Editable settings
# ==========================================================================================================================================

PANDORA_CONDOR_DIR=.

PANDORA_BIN=$MY_TEST_AREA/LArReco/bin/PandoraInterface
SETUP_SCRIPT=$MY_TEST_AREA/setup.sh
RECO_OPTION=Full
SETTINGS_FILE=$MY_TEST_AREA/LArReco/settings/PandoraSettings_Master_MicroBooNE.xml
EVENTS=/r05/uboone/mcc8-4_samples/BNB_mu_cosmic/*
GEOMETRY_FILE=$MY_TEST_AREA/LArReco/geometry/PandoraGeometry_MicroBooNE.xml

FILES_PER_JOB=1
NUM_JOBS=100
MAX_SIMULTANEOUS_JOBS=100

# ==========================================================================================================================================
# ==========================================================================================================================================

# Clean up inputs
PANDORA_BIN=`readlink -f $PANDORA_BIN`                                                                                                         
SETUP_SCRIPT=`readlink -f $SETUP_SCRIPT`                                                                                                       
SETTINGS_FILE=`readlink -f $SETTINGS_FILE`                                                                                                     
GEOMETRY_FILE=`readlink -f $GEOMETRY_FILE`                                                                                                     
PANDORA_CONDOR_DIR=`readlink -f $PANDORA_CONDOR_DIR`                                                                                           

# ==========================================================================================================================================

# Derived paths
GENERIC_CONDOR_JOB=$PANDORA_CONDOR_DIR/generic/condor.job
WORKING_DIR=$PANDORA_CONDOR_DIR/work
EXECUTABLE=$PANDORA_CONDOR_DIR/generic/pandoraJob
JOBS_LIST=$WORKING_DIR/jobsList
JOB_NAME=`basename $EXECUTABLE`

# ==========================================================================================================================================

# Clean up the working directory and move to it
if [ ! -d $WORKING_DIR ]; then
    echo "Working directory doesn't exist! : ${WORKING_DIR}"
    return
fi

rm -rf $WORKING_DIR/*
cd $WORKING_DIR

# ==========================================================================================================================================

# Make the job files
FILE_INDEX=0
JOB_INDEX=0
FILE_LIST=""
for FILE in $EVENTS; do

    # Append this file to the current list
    if [ $FILE_INDEX -eq 0 ]; then
        FILE_LIST=$FILE
    else
        FILE_LIST=$FILE_LIST:$FILE
    fi

    FILE_INDEX=$(( $FILE_INDEX + 1 ))

    # Make new job file
    if [ $FILE_INDEX -eq $FILES_PER_JOB ]; then

        JOB_DIR=${WORKING_DIR}/job${JOB_INDEX}
        mkdir $JOB_DIR
        JOB_FILE=${JOB_DIR}/condor.job
        echo $JOB_FILE >> $JOBS_LIST

        cp $GENERIC_CONDOR_JOB $JOB_FILE
    
        sed -i "s|EXECUTABLE|${EXECUTABLE}|g" $JOB_FILE
        sed -i "s|INITIAL_DIR|${JOB_DIR}|g" $JOB_FILE
        sed -i "s|LOG_DIR|${JOB_DIR}|g" $JOB_FILE
        sed -i "s|JOB_INDEX|${JOB_INDEX}|g" $JOB_FILE

        sed -i "s|SETUP_SCRIPT|${SETUP_SCRIPT}|g" $JOB_FILE
        sed -i "s|PANDORA_BIN|${PANDORA_BIN}|g" $JOB_FILE
        sed -i "s|RECO_OPTION|${RECO_OPTION}|g" $JOB_FILE
        sed -i "s|SETTINGS_FILE|${SETTINGS_FILE}|g" $JOB_FILE
        sed -i "s|GEOMETRY_FILE|${GEOMETRY_FILE}|g" $JOB_FILE
        sed -i "s|FILE_LIST|${FILE_LIST}|g" $JOB_FILE

        JOB_INDEX=$(( $JOB_INDEX + 1 ))
        FILE_INDEX=0

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

    NUM_QUEUED_JOBS=`condor_q -nobatch | grep $JOB_NAME | wc -l`

    if [ $NUM_QUEUED_JOBS -lt $MAX_SIMULTANEOUS_JOBS ]; then

        # Pop the next job from the head of the jobs list
        NEXT_JOB=`head -n 1 $JOBS_LIST`
        tail -n +2 $JOBS_LIST > tmp
        cat tmp > $JOBS_LIST
        rm -rf tmp

        condor_submit $NEXT_JOB > /dev/null 
    fi
    NUM_JOBS_LEFT=`cat $JOBS_LIST | wc -l`
    
    echo -en "\e[2A"
    echo "Jobs queued    : ${NUM_QUEUED_JOBS}"
    echo "Jobs to submit : ${NUM_JOBS_LEFT}"

    sleep 0.5
done

# ==========================================================================================================================================

# Monitor remaining jobs
echo -en "\e[2A"
echo "All jobs submitted!"
echo "                               "; echo
while [ $NUM_QUEUED_JOBS -gt 0 ]; do
    echo -en "\e[1A"
    condor_q | tail -n 1
    NUM_QUEUED_JOBS=`condor_q -nobatch | grep $JOB_NAME | wc -l`
    sleep 0.5
done

cd -
