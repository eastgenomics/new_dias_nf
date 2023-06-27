# dias_nextflow

At the moment, configuration of Dias into nextflow is mainly based on CEN assay; therefore, some reference files need to be replaced in the command line if to run TWE assay.
In the future, this will be improved so that the correct ref will be called based on the assay.

Current nextflow dias has the following app 
 - multi_fastQC
 - sentieon
 - picard
 - verifybamiD
 - samtools_flagstat
 - somalier_extract
 - somalier_relate
 - somalier_relate2multiqc
 - multiQC
 
 
## To build nextflow dias on DNAnexus
 - git clone <repo>
 - dx build --nextflow (inside the cloned folder)
 
## To run the build nextflow applet on DNAnexus 

`dx run applet-xxxx -idocker_creds=file-xxxx -i nextflow_pipeline_params="--file_path="dx://project-xxxx:/" --fastq="dx://project-xxxx:/*fastq.gz""`
 
docker_creds file has to be created privately \
--file_path is the DNAnexus where the fastq files are located \
--fastq is the same directory but with file exentsion 
