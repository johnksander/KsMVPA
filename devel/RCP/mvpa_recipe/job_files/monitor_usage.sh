#!/bin/bash
for i in {1..480..1}
do 
date >> usage_stats.txt
sinfo --nodes=ncfmem01 -o "%m %e %c %O" >> usage_stats.txt
sleep 60
done

