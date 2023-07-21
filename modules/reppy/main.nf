process reppy{

    debug true
    publishDir params.outdir10, mode:'copy'

    input:
    path happy_roc

    output:
    path "*.html"

    script:

    """
    python /app/benchmarking-tools/reporting/basic/bin/rep.py -o "${happy_roc.toString().split("\\_")[0]}_summary.html" "${happy_roc.toString().split("\\_")[0]}_vcfeval-hap.py":$happy_roc
  
    """
}