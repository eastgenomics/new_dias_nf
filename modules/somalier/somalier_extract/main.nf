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
