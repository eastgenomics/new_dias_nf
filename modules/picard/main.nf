process picard {
    
    debug true

    tag "$sorted_bam"
    publishDir params.outdir2, mode:'copy'
    
    input:
    
    path genome
    path sorted_bam
    path bedfile
    val run_CollectMultipleMetrics
    val run_CollectHsMetrics
    val run_CollectTargetedPcrMetrics
    val run_CollectRnaSeqMetris

    output:
    path "${sorted_bam.getBaseName()}/*.tsv", emit: tsv
    path "${sorted_bam.getBaseName()}/*hsmetrics.tsv", emit: hsmetrics
    //path "${sorted_bam.getBaseName()}/*{.pdf,metrics}", emit: other

    """
    #!/bin/bash 
    
    echo 'the sample running is $sorted_bam'
    bash nextflow-bin/code_picard.sh $genome $sorted_bam $bedfile $run_CollectMultipleMetrics $run_CollectHsMetrics $run_CollectTargetedPcrMetrics $run_CollectRnaSeqMetris 
    """
}
