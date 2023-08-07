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