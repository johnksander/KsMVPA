#!/usr/bin/env bash

module load MATLAB/R2017b
nohup matlab -nodisplay -nodesktop -nosplash -r "network_spiking_results_durations2;exit" >> woodstock_job_out.txt 2>&1 &
#echo "job finished" >> woodstock_job_out.txt 
