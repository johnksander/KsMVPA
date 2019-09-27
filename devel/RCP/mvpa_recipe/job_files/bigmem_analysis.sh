#!/bin/bash
#SBATCH -J permtest # A single job name for the array
#SBATCH --time=1-00:00	 # Running time 
#SBATCH --cpus-per-task=28
#SBATCH -N 1
#SBATCH --mem=200G # Memory request 
#SBATCH --account=paul-lab
#SBATCH --partition=neuro-largemem
#SBATCH --qos=medium
#SBATCH -o log_analysis_%A_%a.out
#SBATCH -e log_analysis_%A_%a.err


cd /work/jksander/RCP/KsMVPA_h/mvpa_recipe/
module load share_modules/MATLAB/R2017a

matlab -nodisplay -nodesktop -nosplash -r "pt2_driver"
