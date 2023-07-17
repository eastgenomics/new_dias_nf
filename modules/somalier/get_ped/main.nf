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
