#!/bin/bash
#SBATCH -J analysis # A single job name for the array
#SBATCH --time=3-00:00 # Running time 
#SBATCH --mem=128G # Memory request
#SBATCH --cpus-per-task=30
#SBATCH -N 1
#SBATCH --partition=ncf_holy
#SBATCH -o log_job_%A.out
#SBATCH -e log_job_%A.err


cd /users/ksander/RCP/KsMVPA_h/mvpa_recipe/
module load matlab/R2017a-fasrc02

matlab -nodisplay -nodesktop -nosplash -r "ROI2searchlight_driver"
