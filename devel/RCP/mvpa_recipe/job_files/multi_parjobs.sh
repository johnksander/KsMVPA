#!/bin/bash
for i in {1..10..1}
do 
jobname="#$ -N permJ$i"
echo $jobname >> MPjob_$i.txt
cat setup_Mjobs.txt >> MPjob_$i.txt
job_command='matlab -nodisplay -nodesktop -nosplash -r "job2RSA_searchlight_perm_mainscript('"$i"');quit"'
echo $job_command >> MPjob_$i.txt
qsub MPjob_$i.txt
sleep 11
done

