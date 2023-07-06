process untar {
    
    debug true
    
    publishDir params.outdir2, mode:'copy'
    
    input:
    
    path fasta_index

    output:
    
    path "genome*", emit: genome
    """
    #!/bin/bash 

    bash nextflow-bin/untar.sh $fasta_index 
    """
}