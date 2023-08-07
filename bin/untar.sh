#!/bin/bash

# The following line causes bash to exit at any point if there is any error
# and to output each line as it is executed -- useful for debugging
set -e -x -o pipefail

fasta_index_path="$1"

tar zxvf $fasta_index_path



