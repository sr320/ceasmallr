#!/bin/bash

# This sccript is designed to be called by a SLURM script which
# runs this script across an array of HPC nodes.


###################################################################################
# These variables need to be set by user

## Assign Variables

# INPUT FILES
repo_dir="/gscratch/scrubbed/samwhite/gitrepos/ceasmallr"
trimmed_fastqs_dir="${repo_dir}/output/00.00-trimming-fastp"
bisulfite_genome_dir="${repo_dir}/data/Cvirginica_v300"


# OUTPUT FILES
output_dir_top="${repo_dir}/output/02.01-bismark-bowtie2-alignment-SLURM-array"

# PARAMETERS
bowtie2_min_score="L,0,-0.6"


# CPU threads
# Bismark already spawns multiple instances and additional threads are multiplicative."
bismark_threads=15

###################################################################################

# Print name of container

echo "Running in Apptainer container: ${APPTAINER_CONTAINER}"
echo ""

# Make output directory, if it doesn't exist
mkdir --parents "02.01-bismark-bowtie2-alignment-SLURM-array"${output_dir_top}""

## CREATE LIST OF PAIRED READS ##

cd "${trimmed_fastqs_dir}"

if [[ -f "${output_dir_top}"/fastq_pairs.txt ]]; then
  rm "${output_dir_top}"/fastq_pairs.txt
fi

# Find all _R1_ files and match them with their corresponding _R2_ files
for R1_file in *_R1_*.fq.gz; do
    R2_file="${R1_file/_R1_/_R2_}"
    if [[ -f "$R2_file" ]]; then
        echo "$R1_file $R2_file" >> "${output_dir_top}"/fastq_pairs.txt
    else
        echo "Warning: No matching R2 file for $R1_file"
    fi
done


## SET ARRAY TASKS ##
cd "${output_dir_top}"

# Get the FastQ file pair for this task
pair=$(sed -n "${SLURM_ARRAY_TASK_ID}p" fastq_pairs.txt)

R1=$(echo $pair | awk '{print $1}')

R2=$(echo $pair | awk '{print $2}')


# Check if R1 and R2 are not empty
if [ -z "$R1" ] || [ -z "$R2" ]; then
  echo "Error: R1 or R2 is empty. Exiting."
  exit 1
fi

# Get just the sample name (excludes the _R[12]_001*)
sample_name="${R1%%_*}"

# Check if sample_name is not empty
if [ -z "$sample_name" ]; then
  echo "Error: sample_name is empty. Exiting."
  exit 1
fi


## RUN BISMARK ALIGNMENTS ##
bismark \
--genome ${bisulfite_genome_dir} \
--score_min "${bowtie2_min_score}" \
--parallel "${bismark_threads}" \
--non_directional \
--gzip \
-p "${bismark_threads}" \
-1 ${trimmed_fastqs_dir}/${R1} \
-2 ${trimmed_fastqs_dir}/${R2} \
--output_dir "${output_dir_top}" \
2> "${output_dir_top}"/${sample_name}-${SLURM_ARRAY_TASK_ID}-bismark_summary.txt