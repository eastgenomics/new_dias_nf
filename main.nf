nextflow.enable.dsl=2

process fastQC {
    
    debug true
    tag "$fastq"
    publishDir params.outdir5, mode:'copy'
    
    input:
    
    path fastq
    
    output:
    
    path "*_fastqc.{zip,html}", emit:fastqc_results
        
    """
    #!/bin/bash 
    chmod -R 777 nextflow-bin/fastqc_bin
    nextflow-bin/fastqc_bin/fastqc $fastq 
    #mv ${fastq.getBaseName(2)}_fastqc/fastqc_data.txt ${fastq.getBaseName(2)}_fastqc/${fastq.getBaseName(2)}_fastqc_data.txt
    
    """
}

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

process untar {
    
    debug true
    
    publishDir params.outdir2, mode:'copy'
    
    input:
    
    path fasta_index

    output:
    
    path "genome*", emit: genome
    """
    #!/bin/bash 

    bash nextflow-bin/untar.sh $fasta_index 
    """
}

process picard {
    
    debug true

    tag "$sorted_bam"
    publishDir params.outdir2, mode:'copy'
    
    input:
    
    path genome
    path sorted_bam
    path bedfile
    val run_CollectMultipleMetrics
    val run_CollectHsMetrics
    val run_CollectTargetedPcrMetrics
    val run_CollectRnaSeqMetris

    output:
    path "${sorted_bam.getBaseName()}/*.tsv", emit: tsv
    path "${sorted_bam.getBaseName()}/*hsmetrics.tsv", emit: hsmetrics
    //path "${sorted_bam.getBaseName()}/*{.pdf,metrics}", emit: other

    """
    #!/bin/bash 
    
    echo 'the sample running is $sorted_bam'
    bash nextflow-bin/code_picard.sh $genome $sorted_bam $bedfile $run_CollectMultipleMetrics $run_CollectHsMetrics $run_CollectTargetedPcrMetrics $run_CollectRnaSeqMetris 
    """
}

process verifybamID {
    
    debug true
    tag "${reads[0]} and ${reads[1]}"
    publishDir params.outdir3, mode:'copy'
    
    input:
    
    path vcf_file
    tuple val(sample_id), path(reads) 
    
    output:
    path "${reads[0].getBaseName()}/*", emit: verifybamID_qc
    
    """
    #!/bin/bash 
    echo "now running ${reads[0]} and ${reads[1]}"
    
    bash nextflow-bin/code_verifybamid.sh $vcf_file ${reads[0]} ${reads[1]} 
    """
}


process samtools {
    
    debug true
    tag "$bam"
    publishDir params.outdir6, mode:'copy'
    
    input:
    
    path bam
    
    output:
    
    path "${bam.baseName}.flagstat", emit:samtools_flagstat
    
    """
    #!/bin/bash 
    
    nextflow-bin/samtools flagstat $bam >  "${bam.baseName}.flagstat" 
    
    """
}

process MULTIQC {
    
    debug true
    tag "running multiqc"
    publishDir params.outdir4, mode:'copy'

    input:
    path tsv 
    path multiqc_config 

    output:
    path "*.html"
    path "multiqc_data"
    
    script:
    
    """
    
    multiqc --config $multiqc_config .
    """
       
}

process Calc_Custom_Coverage {
  debug true 

  publishDir params.outdir4, mode:'copy'
  input:
  val count
  val depth
  path hsmetrics
  
  output:
  path "*"
  
  """
  python3 nextflow-bin/calc_custom_coverage.py $count $depth $hsmetrics
  """
}

process somalier_extract {
    tag "$vcf_ch"
    debug true
    publishDir params.outdir7, mode:'copy'
    input:
    
    path vcf_ch
    path site_vcf
    path ref_file
    path ref_index_file
        
    output:
    
    path "*.somalier", emit:somalier_extract_output
   
    script:

    """
    #!/bin/bash
    
    tabix -p vcf ${vcf_ch}
    
    somalier extract --sites ${site_vcf} -f "${ref_file}" ${vcf_ch}
    
    """
}

process get_ped {
    tag "$somalier_extract_output"
    debug true
    publishDir params.outdir7, mode:'copy'
    
    input:
    
    path somalier_extract_output
       
    output:
    
    path "*.ped" , emit:ped_file

    script:

    """
    #!/bin/bash
    python3 nextflow-bin/make_ped.py -a $somalier_extract_output
    
    """
}

process somalier_relate {
    
    
    debug true
    publishDir params.outdir7, mode:'copy'
    
    input:
    path somalier_extract_output
    path ped_file
    
    output:
    path "*groups.tsv"
    path "*.html"
    path "*.samples.tsv", emit:som_samples_tsv
    path "*.pairs.tsv"
  
    script:

    """
    #!/bin/bash
    

    somalier relate --ped ${ped_file} ${somalier_extract_output}
    """
    
}

process somalier_relate2multiqc {

    debug true
    publishDir params.outdir7, mode:'copy'
    
    input:
    path som_samples_tsv
    val female_threshold
    val male_threshold
    
    output:

    path "*.samples.tsv", emit:som_samples_tsv_multiqc
    
  
    script:

    """
    python3 nextflow-bin/reformat.py -F ${female_threshold} -M ${male_threshold} -i ${som_samples_tsv}
    """
    
}

process get_ref_genome{

    debug true
    publishDir params.outdir8, mode:'copy'
    tag "${reads[0]}"
    input:
    
    tuple val(sample_id), path(reads) 
    output:
    
    path "*.txt"
    
    script:

    """
    #!/bin/bash
    echo ${reads[0]}
    echo ${reads[1]}
    bash nextflow-bin/get_ref_build.sh ${reads[0]}
    """
    

}
       
process MOSDEPTH {
        
    debug true
    publishDir params.outdir8, mode:'copy'
    tag "${reads[0]}"
    input:
    
    tuple val(sample_id), path(reads) 
    path bed
        
    output:
    
    path "*.txt"
    path "*bed*"
    
    
    script:

    """
    #!/bin/bash
    echo ${reads[0]}
    echo ${reads[1]}
   
    mosdepth --by ${bed} --flag 1796 --mapq 20 ${reads[0].baseName} ${reads[0]}
    """

}

process vcf_qc {
    
    debug true
    tag "$vcf"
    publishDir params.outdir9, mode:'copy'
    
    input:
    
    path vcf
    path bed

    output:
    
    path "*.QC"
    
    """
    #!/bin/bash 
    
    python3 nextflow-bin/vcf_QC.py $vcf $bed > ${vcf.getBaseName()}.QC
    
    """
}



workflow 
{   fastq_ch = Channel.fromPath(params.fastq)
    
    read_pairs_ch = Channel
                .fromFilePairs(params.fastq_files,size: 4)
    fastQC(fastq_ch)
    runSentieon(read_pairs_ch, params.bwaIndex, params.fastaFile, params.fastaIndex,params.gatkResource)
    untar(params.fasta_index)
picard(untar.out.genome,runSentieon.out.sorted_bam,params.bedfile,params.run_CollectMultipleMetrics,params.run_CollectHsMetrics,params.run_CollectTargetedPcrMetrics,params.run_CollectRnaSeqMetrics) 
    
    verifybamID(params.vcf_file,runSentieon.out.bam_file_pair)  
    samtools(runSentieon.out.sorted_bam)
    
    somalier_extract(runSentieon.out.Haplotyper_vcf_gz,params.site_vcf,params.ref_file,params.ref_index_file)
    get_ped(somalier_extract.out.somalier_extract_output.collect())     
    somalier_relate(somalier_extract.out.somalier_extract_output.collect(),get_ped.out.ped_file)       
    somalier_relate2multiqc(somalier_relate.out.som_samples_tsv,params.female_threshold,params.male_threshold)

    MOSDEPTH(runSentieon.out.bam_file_pair,params.bed)
    get_ref_genome(runSentieon.out.bam_file_pair)
    vcf_qc(runSentieon.out.Haplotyper_vcf_gz,params.bed)
    MULTIQC(picard.out.tsv.mix(fastQC.out.fastqc_results,runSentieon.out.sentieon_multiqc,verifybamID.out.verifybamID_qc,samtools.out.samtools_flagstat,somalier_relate2multiqc.out.som_samples_tsv_multiqc).collect(),params.multiqc_config)


    if (params.calc_custom_coverage==true) {
      Calc_Custom_Coverage(params.num_samples,params.depth,picard.out.hsmetrics.collect())
}
}
