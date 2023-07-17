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
