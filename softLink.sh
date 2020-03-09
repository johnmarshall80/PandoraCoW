#!/bin/bash

# ==========================================================================================================================================
# Editable settings
# ==========================================================================================================================================

PANDORA_COW_DIR=/storage/epp2/phsnpc/cow/PandoraCoW/
TARGET_FILE_NAME='Validation'
TARGET_FILE_EXTENSION='.root'
OUTPUT_DIR_NAME=softlinks

# ==========================================================================================================================================

# Derived paths
WORKING_DIR=$PANDORA_COW_DIR/${1}
OUTPUT_DIR=${WORKING_DIR}/softlinks

# ==========================================================================================================================================

# Clean up the output directory
if [ -d $OUTPUT_DIR ]; then
    echo "Output directory already exists! : ${OUTPUT_DIR}"
    exit 1
fi

mkdir -p ${OUTPUT_DIR}

# ==========================================================================================================================================

for i in `ls -d ${WORKING_DIR}/job*/`; do
    JOB_INDEX=`echo ${i} | grep -oE 'job[0-9]+' | grep -oE '[0-9]+'`
    ln -s ${i}/${TARGET_FILE_NAME}${TARGET_FILE_EXTENSION} ${OUTPUT_DIR}/${TARGET_FILE_NAME}_${JOB_INDEX}${TARGET_FILE_EXTENSION}
done
