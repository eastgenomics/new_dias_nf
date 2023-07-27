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

