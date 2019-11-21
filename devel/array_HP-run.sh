#!/bin/bash
#SBATCH -J HP-run # A single job name for the array
#SBATCH --time=3-00:00 # Running time 
#SBATCH --mem=128G # Memory request
#SBATCH --cpus-per-task=30
#SBATCH -N 1
#SBATCH --partition=ncf_holy
#SBATCH -o log_%x_%A_%a.out
#SBATCH -e log_%x_%A_%a.err


cd /users/ksander/RCP/KsMVPA_h/mvpa_recipe/
module load matlab/R2018b-fasrc01

matlab -nodisplay -nodesktop -nosplash -r "array_driver"
