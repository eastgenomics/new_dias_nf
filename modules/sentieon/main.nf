process runSentieon
{
    
    publishDir params.outdir1, mode:'copy'
    tag "${reads[0]}, ${reads[1]}, ${reads[2]}, ${reads[3]}"
    
    input:
        tuple val(sample_id), path(reads)
        path bwaIndex
        path fastaFile
        path fastaIndex
        path gatkResource
        
    output:
        path "*_markdup.bam.recalibration_table"
        path "*_markdup_recalibrated_Haplotyper.g.vcf.gz"
        path "*_markdup_recalibrated_Haplotyper.vcf.gz", emit:Haplotyper_vcf_gz

        path "*.Duplication_metrics.txt"
        path "*.GCBias_metrics.txt"
        path "*.GCBiasSummary_metrics.txt"
        path "*.MeanQualityByCycle_metrics.txt"
        path "*.QualDistribution_metrics.txt"
        path "*.InsertSize_metrics.txt"
        path "*.AlignmentStat_metrics.txt"
        path "*.metrics.pdf"
        
        path "*.{AlignmentStat_metrics.txt,Duplication_metrics.txt,GCBiasSummary_metrics.txt,InsertSize_metrics.txt}", emit:sentieon_multiqc

        path "*_markdup_recalibrated_Haplotyper.vcf.gz.tbi"
        path "*_markdup_recalibrated_Haplotyper.g.vcf.gz.tbi"
        path "*_markdup.bam", emit: sorted_bam
        path "*_markdup.bam.bai"
        tuple val(sample_id), path("*_markdup{.bam,.bam.bai}"), emit:bam_file_pair
    script:

        """          
        echo "running ${reads[0]} ${reads[1]} ${reads[2]} ${reads[3]} "
        bash nextflow-bin/code_sentieon.sh $bwaIndex $fastaFile $fastaIndex $gatkResource ${reads[0]} ${reads[1]} ${reads[2]} ${reads[3]} 
        """
}