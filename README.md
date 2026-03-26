# *S. aureus* in atopic dermatitis

Code related to the paper "The gut-skin axis of Staphylococcus aureus colonization in pediatric atopic dermatitis" (T. Karagounis et al.)

This document is divided into sections dedicated to separate analyses done for the paper:

- [AD cohort 16S analysis](#ad-cohort-16s-analysis)
- [CHES cohort 16S analysis](#ches-cohort-16s-analysis)
- [Joint variant calling pipeline](#joint-variant-calling-pipeline)

## AD cohort 16S analysis

16S amplicon sequence analysis was performed using Qiime2 version 2023.5.1. All Qiime2 commands are listed in the document [16S_AD_cohort/QIIME_ADCohortProcessing.md](16S_AD_cohort/QIIME_ADCohortProcessing.md). The resulting Qiime2 artifacts are stored in `16S_AD_cohort/QIIME_Processed/` and serve as input for further analysis.

Further 16S analysis of the AD cohort data is detailed in following RMarkdown files:

    16S_AD_cohort/ADCohort_16SAnalysis.Rmd
    16S_AD_cohort/ADCohort_DifferentialAbundance.Rmd

This includes code for generating the panels of Figure 3 of the manuscript. These RMarkdown files are meant to be run form RStudio (tested on version 2024.12.0+467 with R version 4.4.2).

## CHES cohort 16S analysis

16S amplicon sequencing was performed in two sequencing runs. Sequence data were analyzed using Qiime2 version 2023.5.1, as detailed in the following documents:

- [`16S_CHES_cohort/NYUCHES_R1_processing.md`](16S_CHES_cohort/NYUCHES_R1_processing.md) 
- [`16S_CHES_cohort/NYUCHES_R2_processing.md`](16S_CHES_cohort/NYUCHES_R2_processing.md) 

The process of merging these runs is described in [`16S_CHES_cohort/MergingCHESRuns.md`](16S_CHES_cohort/MergingCHESRuns.md).

The resulting Qiime2 artifacts are used as input to the further analysis steps detailed in `16S_CHES_cohort/NYUCHES_16SAnalysis.Rmd`. That RMarkdown is meant to but run in RStudio (tested on on version 2024.12.0+467 with R version 4.4.2).

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

Supply that TSV file's path in this part of the README:

    cluster_refseq_tsv_file="misc/2024-09-12-refseq-cluster-refs-selected-by-ANI.tsv"



The following command will then generate the joint VCF files:

    CACHE=/path/to/your/conda/cache/dir
    snakemake --cores 32 --software-deployment-method conda --conda-prefix $CACHE --conda-frontend mamba process_vcf_refseq_all


