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
