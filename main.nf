nextflow.enable.dsl=2

// -------------------------------------
// INCLUDE MODULES
// -------------------------------------

include { fastQC } from './modules/fastqc'
include { runSentieon } from './modules/sentieon'
include { untar } from './modules/untar'
include { picard } from './modules/picard'
include { verifybamID } from './modules/verifybamID'
include { samtools_flagstat } from './modules/samtools/samtools_flagstat'
include { somalier_extract } from './modules/somalier/somalier_extract'
include { get_ped } from './modules/somalier/get_ped'
include { somalier_relate } from './modules/somalier/somalier_relate'
include { somalier_relate2multiqc } from './modules/somalier/somalier_relate2multiqc'
include { MOSDEPTH } from './modules/mosdepth'
include { get_ref_genome } from './modules/get_ref_genome'
include { vcf_qc } from './modules/vcf_qc'
include { MULTIQC } from './modules/multiqc'
include { Calc_Custom_Coverage } from './modules/calc_custom_coverage'
include { happy } from './modules/happy'
include { reppy } from './modules/reppy'


// -------------------------------------
// 
// -------------------------------------



// -------------------------------------
// RUN WORKFLOW
// -------------------------------------

workflow 
{   fastq_ch = Channel.fromPath(params.fastq)
    
    read_pairs_ch = Channel
                .fromFilePairs(params.fastq_files,size: 4)
    fastQC(fastq_ch)
    runSentieon(read_pairs_ch, params.bwaIndex, params.fastaFile, params.fastaIndex,params.gatkResource)
    runSentieon.out.Haplotyper_vcf_gz.collect().map{it -> (it.findAll{it.baseName.contains(params.genome_in_a_bottle)})}.view()
    untar(params.fasta_index)
    picard(untar.out.genome,runSentieon.out.sorted_bam,params.bedfile,params.run_CollectMultipleMetrics,params.run_CollectHsMetrics,params.run_CollectTargetedPcrMetrics,params.run_CollectRnaSeqMetrics) 
    
    verifybamID(params.vcf_file,runSentieon.out.bam_file_pair)  
    samtools_flagstat(runSentieon.out.sorted_bam)
    
    somalier_extract(runSentieon.out.Haplotyper_vcf_gz,params.site_vcf,params.ref_file,params.ref_index_file)
    get_ped(somalier_extract.out.somalier_extract_output.collect())     
    somalier_relate(somalier_extract.out.somalier_extract_output.collect(),get_ped.out.ped_file)       
    somalier_relate2multiqc(somalier_relate.out.som_samples_tsv,params.female_threshold,params.male_threshold)

    MOSDEPTH(runSentieon.out.bam_file_pair,params.bed)
    get_ref_genome(runSentieon.out.bam_file_pair)
    vcf_qc(runSentieon.out.Haplotyper_vcf_gz,params.bed)
    MULTIQC(picard.out.tsv.mix(fastQC.out.fastqc_results,runSentieon.out.sentieon_multiqc,verifybamID.out.verifybamID_qc,samtools_flagstat.out.samtools_flagstat,somalier_relate2multiqc.out.som_samples_tsv_multiqc).collect(),params.multiqc_config)

    happy(params.fastaFile,params.fastaIndex,params.high_conf_bed,params.panel_bed,params.truth_vcf,runSentieon.out.Haplotyper_vcf_gz.collect().map{it -> (it.findAll{it.baseName.contains(params.genome_in_a_bottle)})},params.sdf_tar)
    reppy(happy.out.happy_roc)

    if (params.calc_custom_coverage==true) {
      Calc_Custom_Coverage(params.num_samples,params.depth,picard.out.hsmetrics.collect())
}
}

// -------------------------------------
// 
// -------------------------------------
