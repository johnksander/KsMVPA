#!/bin/bash
#SBATCH -J DCS # A single job name for the array
#SBATCH --time=0-06:00 # Running time 
#SBATCH --mem=16G # Memory request
#SBATCH -N 1
#SBATCH --partition=ncf_holy
#SBATCH -o DCS-config.out
#SBATCH -e DCS-config.err


cd /users/ksander/RCP/KsMVPA_h/mvpa_recipe/
module load matlab/R2018b-fasrc01

matlab -nodisplay -nodesktop -nosplash -r "DCS_config"
