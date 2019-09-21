#!/bin/bash
for i in {1..480..1}
do 
date >> usage_stats.txt
sinfo --nodes=compute-5-0 -o "%m %e %c %O" >> usage_stats.txt
sleep 60
done

#probably better is:
# sinfo --nodes=compute-5-0 -o "%m %e %C %O"
