#!/bin/bash
#SBATCH --dependency=afterok:26646351
#SBATCH -J VMGM-stats # A single job name for the array
#SBATCH --time=1-00:00	 # Running time 
#SBATCH --mem=400G # Memory request
#SBATCH --partition=ncf_bigmem
#SBATCH -o log_%x_%A.out
#SBATCH -e log_%x_%A.err


cd /users/ksander/RCP/KsMVPA_h/mvpa_recipe/
module load matlab/R2017a-fasrc02

matlab -singleCompThread -nodisplay -nodesktop -nosplash -r "VMGM_stats"
