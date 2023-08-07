process Calc_Custom_Coverage {
  debug true 

  publishDir params.outdir4, mode:'copy'
  input:
  val count
  val depth
  path hsmetrics
  
  output:
  path "*"
  
  """
  python3 nextflow-bin/calc_custom_coverage.py $count $depth $hsmetrics
  """
}
