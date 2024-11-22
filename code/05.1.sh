#!/bin/bash
# Set directories and files
reads_dir="../../data/"
genome_folder="../../data/genome"
output_dir="."
checkpoint_file="completed_samples.log"

# Create the checkpoint file if it doesn't exist
touch ${checkpoint_file}

# Get the list of sample files and corresponding sample names
files=(${reads_dir}*R1_001.fastp-trim.20220827.fq.gz)
file="${files[$SLURM_ARRAY_TASK_ID]}"
sample_name=$(basename "$file" "_R1_001.fastp-trim.20220827.fq.gz")

# Check if the sample has already been processed
if grep -q "^${sample_name}$" ${checkpoint_file}; then
    echo "Sample ${sample_name} already processed. Skipping..."
    exit 0
fi

# Define log files for stdout and stderr
stdout_log="${output_dir}${sample_name}_stdout.log"
stderr_log="${output_dir}${sample_name}_stderr.log"

# Run Bismark align
bismark \
    -genome ${genome_folder} \
    -p 8 \
    -score_min L,0,-0.8 \
    --non_directional \
    -1 ${reads_dir}${sample_name}_R1_001.fastp-trim.20220827.fq.gz \
    -2 ${reads_dir}${sample_name}_R2_001.fastp-trim.20220827.fq.gz \
    -o ${output_dir} \
    --basename ${sample_name} \
    2> "${sample_name}-${SLURM_ARRAY_TASK_ID}-bismark_stderr.log"

# Check if the command was successful
if [ $? -eq 0 ]; then
    # Append the sample name to the checkpoint file
    echo ${sample_name} >> ${checkpoint_file}
    echo "Sample ${sample_name} processed successfully."
else
    echo "Sample ${sample_name} failed. Check ${stderr_log} for details."
fi
