#!/usr/bin/env bash

module load MATLAB/R2015a
nohup matlab -nodisplay -nodesktop -nosplash -r run_job_ROI2searchlight &> woodstock_job_out.txt
