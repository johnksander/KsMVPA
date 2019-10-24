#!/bin/bash

echo "---------ncf holy---------"
sinfo -p ncf_holy -N -o "%N %C"
echo "---------ncf bigmem---------"
sinfo -p ncf_bigmem -N -o "%N %C %m %e"
