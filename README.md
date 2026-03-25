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


