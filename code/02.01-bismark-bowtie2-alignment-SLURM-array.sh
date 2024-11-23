#!/bin/bash

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
bismark_threads=4

###################################################################################

## CREATE LIST OF PAIRED READS ##

cd "${trimmed_fastqs_dir}"

if [[ ! -f "${output_dir_top}"/fastq_pairs.txt ]]; then
  echo "Missing ${output_dir_top}/fastq_pairs.txt" >&2
  exit 1
fi


# Create a new file for unprocessed pairs
unprocessed_pairs_file="${output_dir_top}/unprocessed_fastq_pairs.txt"
if [[ ! -f "${unprocessed_pairs_file}" ]]; then
  echo "Missing ${unprocessed_pairs_file}" >&2
  exit 1
fi


## SET ARRAY TASKS ##
cd "${output_dir_top}"

# Get the FastQ file pair for this task
pair=$(sed -n "${SLURM_ARRAY_TASK_ID}p" "${unprocessed_pairs_file}")

echo "Contents of pair:"
echo "${pair}"
echo ""

R1_file=$(echo $pair | awk '{print $1}')
R2_file=$(echo $pair | awk '{print $2}')

# Get just the sample name (excludes the _R[12]_001*)
sample_name=$(echo "$R1_file" | awk -F"_" '{print $1}')


# Check if R1_file and R2_file are not empty
if [ -z "$R1_file" ] || [ -z "$R2_file" ]; then
  echo "Error: R1_file or R2_file is empty. Exiting."
  exit 1
fi

# Check if sample_name is not empty
if [ -z "$sample_name" ]; then
  echo "Error: sample_name is empty. Exiting."
  exit 1
fi

echo "Contents of sample_name: ${sample_name}"
echo ""


## RUN BISMARK ALIGNMENTS ##
bismark \
--genome ${bisulfite_genome_dir} \
--score_min "${bowtie2_min_score}" \
--parallel "${bismark_threads}" \
--non_directional \
--gzip \
-p "${bismark_threads}" \
-1 ${trimmed_fastqs_dir}/${R1_file} \
-2 ${trimmed_fastqs_dir}/${R2_file} \
--output_dir "${output_dir_top}" \
2> "${output_dir_top}"/${sample_name}-${SLURM_ARRAY_TASK_ID}-bismark_summary.txt