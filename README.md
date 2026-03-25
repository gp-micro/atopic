# *S. aureus* in atopic dermatitis

Code related to the paper "The gut-skin axis of Staphylococcus aureus colonization in pediatric atopic dermatitis" (T. Karagounis et al.)

This document is divided into sections dedicated to separate analyses done for the paper:

- [Joint variant calling pipeline](#joint-variant-calling-pipeline)

## Joint variant calling pipeline

**Software requirements**

The pipeline runs on Linux (tested on Red Hat Linux 8.8).

- [Snakemake](https://snakemake.readthedocs.io/en/stable/) (tested on version 8.16.0)

All further software will be loaded automatically via the conda environments specified in the Snakemake workflow, but are listed below for completeness:

- BWA (tested on version 0.7.18)
- samtools (version 1.20)
- bamaddrg (version 9baba65f88228e55639689a3cea38dd150e6284f-2)
- freebayes (version 1.3.2)
- bcftools (version 1.15.1)
- snpEff (version 5.2)
- Python (version 3.9.7)
- R (version 4.3.2)
- R package rtracklayer (version 1.62.0)

**Instructions**

Edit `Snakefile` to fill in the following paths

    scratch_dir="/your/scratch/dir/here"
    #Path to a tab-delimited file with 3 columns: sample identifier, forward read, reverse read
    #These are fastp-cleaned forward and reverse reads to be specific
    sample2fastp_tsv="path/to/sample2fastp_Update6.tsv"

The following should be a TSV file with three columns:

- Cluster name
- Global path to reference FASTA file for that cluster
- Name of reference

Supply that TSV file's path here:

    cluster_refseq_tsv_file="misc/2024-09-12-refseq-cluster-refs-selected-by-ANI.tsv"



The following command will then generate the joint VCF files:

    CACHE=/path/to/your/conda/cache/dir
    snakemake --cores 32 --software-deployment-method conda --conda-prefix $CACHE --conda-frontend mamba process_vcf_refseq_all


