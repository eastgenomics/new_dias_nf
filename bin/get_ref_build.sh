#!/bin/bash
bam="$1"
prefix="$(basename -- $bam .bam)"
ref=$(nextflow-bin/samtools view -H $bam | grep @SQ | tail -1 | cut -d$'\t' -f2 | cut -d':' -f2)
echo $ref >> ${prefix}_reference_build.txt

