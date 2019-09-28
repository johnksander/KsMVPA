#!/bin/bash
#SBATCH -J stats # A single job name for the array
#SBATCH --time=1-00:00	 # Running time 
#SBATCH --mem=400G # Memory request
#SBATCH --partition=ncf_bigmem
#SBATCH -o log_stats_%A_%a.out
#SBATCH -e log_stats_%A_%a.err


cd /users/ksander/RCP/KsMVPA_h/mvpa_recipe/
module load matlab/R2017a-fasrc02

matlab -singleCompThread -nodisplay -nodesktop -nosplash -r "RSA_searchlight_stats_mainscript"
