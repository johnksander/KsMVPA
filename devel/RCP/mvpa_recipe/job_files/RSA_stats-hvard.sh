#!/bin/bash
#SBATCH -J RSAstats # A single job name for the array
#SBATCH --time=12:00:00	 # Running time 
#SBATCH --mem=200G # Memory request
#SBATCH --partition=ncf_bigmem
#SBATCH -o log_RSA_stats.out
#SBATCH -e log_RSA_stats.err


cd /users/ksander/RCP/KsMVPA_h/mvpa_recipe/
module load matlab/R2017a-fasrc02

matlab -singleCompThread -nodisplay -nodesktop -nosplash -r "RSA_searchlight_stats_mainscript"
