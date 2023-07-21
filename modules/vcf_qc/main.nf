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