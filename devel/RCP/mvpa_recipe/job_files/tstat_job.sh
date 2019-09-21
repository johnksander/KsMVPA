#!/bin/bash
#SBATCH -J tstat # A single job name for the array
#SBATCH --time=12:00:00	 # Running time 
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=200G # Memory request 
#SBATCH --account=paul-lab
#SBATCH --partition=neuro-largemem
#SBATCH --qos=medium
#SBATCH -o log_t-stats_%A_%a.out
#SBATCH -e log_t-stats_%A_%a.err


cd /work/jksander/RCP/KsMVPA_h/mvpa_recipe/
module load share_modules/MATLAB/R2017a

matlab -singleCompThread -nodisplay -nodesktop -nosplash -r "run_tstat_job"
