#!/bin/bash env
fa_file="$1"
conf_bed="$2"
bed_file="$3"
prefix="$4"
truth_vcf="$5"
query_vcf="$6"
sdf_tar="$7"

/opt/hap.py/bin/hap.py \
    --reference $fa_file \
    -f $conf_bed \
    -T $bed_file \
    --gender female --decompose --leftshift --adjust-conf-regions \
    --engine vcfeval --ci-alpha 0.05 \
    --engine-vcfeval-template $sdf_tar \
    -o $prefix $truth_vcf $query_vcf


