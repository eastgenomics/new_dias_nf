process somalier_relate2multiqc {

    debug true
    publishDir params.outdir7, mode:'copy'
    
    input:
    path som_samples_tsv
    val female_threshold
    val male_threshold
    
    output:

    path "*.samples.tsv", emit:som_samples_tsv_multiqc
    
  
    script:

    """
    python3 nextflow-bin/reformat.py -F ${female_threshold} -M ${male_threshold} -i ${som_samples_tsv}
    """
    
}
