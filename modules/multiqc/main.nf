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
    #!/bin/bash
    set -euxo pipefail
    multiqc --config $multiqc_config .
    """
       
}
