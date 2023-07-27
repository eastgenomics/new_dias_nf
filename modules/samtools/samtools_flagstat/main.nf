process samtools_flagstat {
    
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
