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
  