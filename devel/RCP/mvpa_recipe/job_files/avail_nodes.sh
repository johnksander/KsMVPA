#!/bin/bash

echo "---------ncf holy---------"
sinfo -p ncf_holy -N -o "%15N %15C %15m %15e %15a"
echo ""
echo "---------ncf cannon---------"
sinfo -p ncf -N -o "%15N %15C %15m %15e %15a"
echo ""
echo "---------ncf bigmem---------"
sinfo -p ncf_bigmem -N -o "%15N %15C %15m %15e %15a"

#do this to look at queue ranked by priority
#showq-slurm -p ncf -o
