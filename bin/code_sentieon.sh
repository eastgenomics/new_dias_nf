#!/usr/bin/env bash

bwaIndex="$1"
fastaFile="$2"
fastaIndex="$3"
gatkResource="$4"
L1R1="$5"
L1R2="$6"
L2R1="$7"
L2R2="$8"
pathToBin="nextflow-bin"
nameOfSample=${L1R1%%_S*}

mkdir genome
tar --no-same-owner -zxvf ${bwaIndex} -C genome

# rename files in genome folder from "genome" to "hs37d5"
mv genome/genome.fa.amb genome/hs37d5.fa.amb
mv genome/genome.fa.ann genome/hs37d5.fa.ann
mv genome/genome.fa.bwt genome/hs37d5.fa.bwt
mv genome/genome.fa.pac genome/hs37d5.fa.pac
mv genome/genome.fa.sa genome/hs37d5.fa.sa

gunzip ${fastaFile}
mv hs37d5.fa genome
mv ${fastaIndex} genome

# prepare GATK resource files
mkdir resources
gunzip -k ${gatkResource}
tar --no-same-owner -zxvf ${gatkResource} -C resources --strip 1

# TODO: remove line below after testing
declare -a namearray=("genome/hs37d5.fa" "genome/hs37d5.fa.amb" "genome/hs37d5.fa.ann" "genome/hs37d5.fa.bwt" "genome/hs37d5.fa.pac" "genome/hs37d5.fa.sa" "resources/1000G_phase1.indels.b37.vcf.gz")

for name in "${namearray[@]}"
    do
        if test -f $name; then
           echo "$name exists."
        else
           echo "$name DOES NOT exist."
        fi
    done

# give permission to run Sentieon
chmod -R 777 ${pathToBin}

# get sentieon license
#export SENTIEON_LICENSE=${pathToBin}/license/East_Midlands_and_East_of_England_NHS_Genomic_Laboratory_Hub_eval.lic
source ${pathToBin}/license/license_setup.sh
set -eu
#export SENTIEON_INSTALL_DIR=nextflow-bin/sentieon-genomics-*
export SENTIEON_INSTALL_DIR=${pathToBin}/sentieon-genomics-*
SENTIEON_BIN_DIR=$SENTIEON_INSTALL_DIR/bin
SENTIEON_APP=$SENTIEON_BIN_DIR/sentieon
# index reference genome and make index file
#${pathToBin}/samtools-*/samtools faidx genome/hs37d5.fa

if test -f "genome/hs37d5.fa.fai"; then
   echo "genome/hs37d5.fa.fai exists."
else
   echo "genome/hs37d5.fa.fai DOES NOT exist."
fi


#Run alignment for 1st input file set
{ ($SENTIEON_APP bwa mem -R "@RG\tID:GROUP_NAME_1\tSM:${nameOfSample}\tPL:ILLUMINA" \
-t 36 -K 10000000 genome/hs37d5.fa ${L1R1} ${L1R2} || echo -n 'error' ) 2>&3 \
| $SENTIEON_APP util sort -o SORTED_BAM_1.bam -t 36 --sam2bam -i - ;} \
3>&1 | grep -v --line-buffered "^\[M::mem_pestat\]\|^\[M::process\]\|^\[M::mem_process_seqs\]"
#Run alignment for 2nd input file set
{ ($SENTIEON_APP bwa mem -R "@RG\tID:GROUP_NAME_2\tSM:${nameOfSample}\tPL:ILLUMINA" \
-t 36 -K 10000000 genome/hs37d5.fa ${L2R1} ${L2R2} || echo -n 'error' ) 2>&3 \
| $SENTIEON_APP util sort -o SORTED_BAM_2.bam -t 36 --sam2bam -i - ;} \
3>&1 | grep -v --line-buffered "^\[M::mem_pestat\]\|^\[M::process\]\|^\[M::mem_process_seqs\]"

#Run dedup on both BAM files
$SENTIEON_APP driver -t 36 -i SORTED_BAM_1.bam -i SORTED_BAM_2.bam \
--algo LocusCollector --fun score_info score.txt.gz
$SENTIEON_APP driver -t 36 -i SORTED_BAM_1.bam -i SORTED_BAM_2.bam \
--algo Dedup --rmdup --score_info score.txt.gz --metrics dedup_metrics.txt markdup.bam

# plot metrics
$SENTIEON_APP driver -t 36 -i SORTED_BAM_1.bam -i SORTED_BAM_2.bam -r genome/hs37d5.fa --algo LocusCollector --fun score_info score.txt.gz --algo GCBias --summary gc_summary.txt gc_metric.txt --algo MeanQualityByCycle mq_metric.txt --algo QualDistribution qd_metric.txt --algo InsertSizeMetricAlgo is_metric.txt --algo AlignmentStat aln_metric.txt
$SENTIEON_APP plot metrics -o metrics.pdf gc=gc_metric.txt mq=mq_metric.txt qd=qd_metric.txt isize=is_metric.txt

# Base quality score recalibration (BQSR)
$SENTIEON_APP driver -t 36 -r genome/hs37d5.fa \
-i markdup.bam --algo QualCal -k resources/1000G_phase1.indels.b37.vcf.gz -k resources/Mills_and_1000G_gold_standard.indels.b37.vcf.gz -k resources/dbsnp_138.b37.vcf.gz recal_data_Sentieon.table

$SENTIEON_APP driver -t 36 -r genome/hs37d5.fa -i markdup.bam \
 -q recal_data_Sentieon.table --algo QualCal -k resources/1000G_phase1.indels.b37.vcf.gz -k resources/Mills_and_1000G_gold_standard.indels.b37.vcf.gz -k resources/dbsnp_138.b37.vcf.gz \
recal_data_Sentieon.table.POST
$SENTIEON_APP driver -t 36 --algo QualCal --plot \
--before recal_data_Sentieon.table --after recal_data_Sentieon.table.POST RECAL_RESULT.csv
$SENTIEON_APP plot QualCal -o BQSR_PDF RECAL_RESULT.csv

$SENTIEON_APP driver -t 36 -r genome/hs37d5.fa -i markdup.bam \
-q recal_data_Sentieon.table --algo Haplotyper -d resources/dbsnp_138.b37.vcf.gz --emit_mode GVCF haplotyper.g.vcf.gz

$SENTIEON_APP driver -t 36 -r genome/hs37d5.fa --algo GVCFtyper -d resources/dbsnp_138.b37.vcf.gz -v haplotyper.g.vcf.gz haplotyper.vcf.gz

# rename files to match output
# metrics


mv dedup_metrics.txt ${nameOfSample}.Duplication_metrics.txt
mv gc_metric.txt ${nameOfSample}.GCBias_metrics.txt
mv gc_summary.txt ${nameOfSample}.GCBiasSummary_metrics.txt
mv mq_metric.txt ${nameOfSample}.MeanQualityByCycle_metrics.txt
mv qd_metric.txt ${nameOfSample}.QualDistribution_metrics.txt
mv is_metric.txt ${nameOfSample}.InsertSize_metrics.txt
mv aln_metric.txt ${nameOfSample}.AlignmentStat_metrics.txt
mv metrics.pdf ${nameOfSample}.metrics.pdf

# other files
mv recal_data_Sentieon.table ${nameOfSample}_markdup.bam.recalibration_table
mv haplotyper.g.vcf.gz ${nameOfSample}_markdup_recalibrated_Haplotyper.g.vcf.gz
mv haplotyper.vcf.gz ${nameOfSample}_markdup_recalibrated_Haplotyper.vcf.gz
mv markdup.bam ${nameOfSample}_markdup.bam
mv markdup.bam.bai ${nameOfSample}_markdup.bam.bai
mv haplotyper.g.vcf.gz.tbi ${nameOfSample}_markdup_recalibrated_Haplotyper.g.vcf.gz.tbi
mv haplotyper.vcf.gz.tbi ${nameOfSample}_markdup_recalibrated_Haplotyper.vcf.gz.tbi

