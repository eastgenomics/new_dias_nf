# dias_nextflow

At the moment, configuration of Dias into nextflow is mainly based on CEN assay; therefore, some reference files need to be replaced in the command line if to run TWE assay.
In the future, this will be improved so that the relevant ref files will be used based on the assay.

Current dias_nextflow has the following processes 
 - multi_fastQC
 - sentieon
 - picard
 - verifybamID
 - samtools_flagstat
 - somalier_extract
 - somalier_relate
 - somalier_relate2multiqc
 - multiQC
 - mosdepth
 - vcf_qc
 - vcfeval_hap.py
 
### Tools and version used in the pipeline
 - fastqc_v0.12.1 
 - sentieon-genomics-202112.07
 - picard - downloaded from [eggd_picardqc](https://github.com/eastgenomics/eggd_picardqc/tree/master/resources) (Release v1.0.0)
 - verifybamID - downloaded from [eggd_verifybamid](https://github.com/eastgenomics/eggd_verifybamid/tree/master/resources/usr/bin) (Release v2.2.0)
 - samtools-v1.16.1
 - bedtools-2.29.1
 
 
### nextflow.config
Contains all parameters used in different processes
### main.nf
Calls the modules and runs workflows
### nextflow_schema.json
Defines the parameter type
### modules
Contains modules for all processes 
### bin folder
Contains all the source codes/tools

### To build dias_nextflow on DNAnexus
```
 git clone <repo>
 dx select <DNAnexus project>
 dx build --nextflow (inside the cloned folder)
 ```
 
### To run the built dias_nextflow applet on DNAnexus 
```
dx run applet-xxxx \
-ifastaFile="project-F3zxk7Q4F30Xp8fG69K1Vppj:file-F403K904F30y2vpVFqxB9kz7" \
-ifastaIndex="project-F3zxk7Q4F30Xp8fG69K1Vppj:file-F3zyVj84F30jxYxG68vJyg68" \
-inextflow_pipeline_params="--file_path=<file/path/> --genome_in_a_bottle=<GIAB prefix>"
```
 
`--file_path` is the dir where the all fastq files are located on DNAnexus 
`--genome_in_a_bottle` is a string - prefix of GIAB test sample (if this variable is constant for every Dias run, I can put it in the config file, so don't need to provide in the command line) 


## How the pipeline works
The pipeline takes multiple samples (i.e fastq.gz files) as initial input, and all fastq files inside `--file_path` are run in parallel. The ouputs from one process  are fed into relevant subsequent processes. Therefore, one set off will run all samples in a series of processes. 
![Image of workflow](workflow1.png)

