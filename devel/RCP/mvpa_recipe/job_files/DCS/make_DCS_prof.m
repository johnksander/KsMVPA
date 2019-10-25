clear
clc
format compact

 JID = str2num(getenv('SLURM_ARRAY_TASK_ID'))

prof_loc = sprintf('/users/ksander/parprofiles/prof_%i',JID)

whos
