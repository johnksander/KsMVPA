#!/bin/bash
#SBATCH -J DCS-HP-run # A single job name for the array
#SBATCH --time=3-00:00 # Running time 
#SBATCH --mem=5000 # Memory request
#SBATCH -c 1
#SBATCH --partition=ncf_holy
#SBATCH -o log_%x_%A.out
#SBATCH -e log_%x_%A.err

cd /users/ksander/RCP/KsMVPA_h/mvpa_recipe/
module load matlab/R2018b-fasrc01

srun -c 1 matlab -nodisplay -nodesktop -nosplash -r "DCSbatch"
