process happy{

    debug true
    publishDir params.outdir10, mode:'copy'

    input:
    path ref_fasta
    path reference_fasta_index
    path high_conf_bed
    path panel_bed
    path truth_vcf
    path query_vcf
    path sdf_tar

    output:
    path "*.csv"
    path "*.gz"
    path "*roc.all.csv.gz",emit:happy_roc

    script:

    """
    #!/bin/bash
    echo "GIAB VCF - $query_vcf"
    gzip -d --force $ref_fasta
    tar -xvf $sdf_tar
    bash nextflow-bin/code_happy.sh ${ref_fasta.getBaseName()} $high_conf_bed $panel_bed "${query_vcf.toString().split("\\_")[0]}_happy_output" $truth_vcf $query_vcf "${sdf_tar.toString().split("\\-")[0]}.sdf"
    """
}