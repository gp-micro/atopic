scratch_dir="/your/scratch/dir/here"

isolates_list_file="lists/isolates_Update6.txt"
bwa_index_prefix="resources/FPR3757/GCF_000013465.1_ASM1346v1_genomic.fna"
#Path to a tab-delimited file with 3 columns: sample identifier, forward read, reverse read
#These are fastp-cleaned forward and reverse reads to be specific
sample2fastp_tsv="path/to/sample2fastp_Update6.tsv"
isolate_cluster_tsv_file="lists/clusters_Update6/isolate2cluster.tsv"
#We don't need to change this for Update6, because there were no new clusters
cluster_refseq_tsv_file="misc/2024-09-12-refseq-cluster-refs-selected-by-ANI.tsv"

isolate_set_name="Update6"

all_isolates = []

with open(isolates_list_file,'r') as fin:
    all_isolates = [l.rstrip('\n') for l in fin.readlines()]

isolates_in_cluster = {}
cluster_of_isolate = {}
with open(isolate_cluster_tsv_file,'r') as fin:
    for l in fin.readlines():
        isolate,cluster = l.rstrip('\n').split()
        cluster_of_isolate[isolate] = cluster
        if cluster in isolates_in_cluster:
            isolates_in_cluster[cluster].append(isolate)
        else:
            isolates_in_cluster[cluster] = [isolate]

clusters=list(isolates_in_cluster.keys())

#RefSeq assemblies selected for each cluster
cluster_refseq_fasta = {}
with open(cluster_refseq_tsv_file,'r') as fin:
    for l in fin.readlines():
        cluster,fasta,accession = l.rstrip('\n').split()
        cluster_refseq_fasta[cluster]=fasta

fastp_files={}
with open(sample2fastp_tsv,'r') as fin:
    for l in fin.readlines():
        isolate,R1,R2 = l.rstrip('\n').split()
        fastp_files[isolate] = {'R1':R1,'R2':R2}

rule list_clusters:
    run:
        for cluster in clusters:
            print(cluster)

rule list_isolates:
    run:
        for cluster in clusters:
            print(cluster)
            print(",".join(isolates_in_cluster[cluster]))

def bwa_input(wildcards):
    isolate = wildcards["isolate"]
    return {"R1":fastp_files[isolate]["R1"],"R2":fastp_files[isolate]["R2"]}
    
rule bwa:
    input:
        unpack(bwa_input)
    output:
        bam = scratch_dir + "/bam/{isolate}.bam",
        bai = scratch_dir + "/bam/{isolate}.bam.bai"
    conda:
        "scripts/conda_env_yml/bwa_samtools_bamaddrg.yml"
    threads: 4
    shell:
        """
        bwa mem -t {threads} {bwa_index_prefix} {input.R1} {input.R2} > {scratch_dir}/{wildcards.isolate}.sam
        samtools sort -@ {threads} -m 2G {scratch_dir}/{wildcards.isolate}.sam > {scratch_dir}/{wildcards.isolate}.temp.bam
        rm {scratch_dir}/{wildcards.isolate}.sam
        bamaddrg -b {scratch_dir}/{wildcards.isolate}.temp.bam -s {wildcards.isolate} > {scratch_dir}/bam/{wildcards.isolate}.bam
        rm {scratch_dir}/{wildcards.isolate}.temp.bam
        samtools index {scratch_dir}/bam/{wildcards.isolate}.bam 
        """

rule all_bwa:
    input:
        [scratch_dir + "/bam/" + isolate + ".bam" for isolate in all_isolates]

def freebayes_input(wildcards):
    cluster=wildcards["cluster"]
    isolates = isolates_in_cluster[cluster]
    return {'bam' : [scratch_dir + "/bam/" + isolate + ".bam" for isolate in isolates],'ref':bwa_index_prefix}

rule freebayes:
    input:
        unpack(freebayes_input)
    output:
        vcf="results/freebayes/joint_calling_vs_FPR3757/" + isolate_set_name + "/{cluster}.vcf"
    conda:
        "scripts/conda_env_yml/freebayes.yml"
    threads: 1
    shell:
        """
        freebayes -p 1 -f {input.ref} --min-alternate-count 10 --use-best-n-alleles 4 --min-alternate-fraction 0.2 --genotype-qualities {input.bam} > {output.vcf}
        """

rule freebayes_all:
    input:
        ["results/freebayes/joint_calling_vs_FPR3757/" + isolate_set_name + "/" + cluster + ".vcf" for cluster in clusters]

rule bcftools:
    input:
        vcf="results/freebayes/joint_calling_vs_FPR3757/" + isolate_set_name + "/{cluster}.vcf"
    output:
        vcf="results/bcftools/joint_vcf_filtered/" + isolate_set_name + "/{cluster}.filtered.vcf"
    conda:
        "scripts/conda_env_yml/bcftools.yml"
    threads: 1
    shell:
        """
        cat {input.vcf} | bcftools view -i 'MIN(GQ)>=100 && COUNT(GQ>=0)=N_SAMPLES' | bcftools view -e 'COUNT(GT="A")=N_SAMPLES || COUNT(GT="R")=N_SAMPLES' > {output.vcf}
        """ 

rule bcftools_all:
    input:
        ["results/bcftools/joint_vcf_filtered/" + isolate_set_name + "/" + cluster + ".filtered.vcf" for cluster in clusters]

#Note:
#This rule is kept for reference purposes
#I have not found a way to explicitly point to a conda environment by path (--prefix)

#Note that we need to specify the explicit path to the conda environment because
#the FPR3757 database has been added there
#rule snpeff:
#    input:
#        vcf="results/bcftools/joint_vcf_filtered/" + isolate_set_name + "/{cluster}.filtered.vcf"
#    output:
#        vcf="results/snpEff/annotated_vcf/" + isolate_set_name + "/{cluster}.ann.vcf"
#    conda:
#        "/gpfs/data/pirontilab/software/conda/snpEff"
#    threads: 1
#    shell:
#        """
#        snpEff ann -noLog -noStats -no-downstream -no-upstream -no-utr FPR3757 {input.vcf} > {output.vcf}
#        """

rule process_vcf:
    input:
        vcf="results/snpEff/annotated_vcf/" + isolate_set_name + "/{cluster}.ann.vcf"
    output:
        tsv="results/snp_tab/" + isolate_set_name + "/{cluster}.tsv"
    run:
        isolate_string = ",".join(isolates_in_cluster[wildcards.cluster])
        shell("python scripts/process_vcf.py {input.vcf} {isolate_string} > {output.tsv}")

rule add_intergenic_annotations:
    input:
        gff="misc/GCF_000013465.1_ASM1346v1_genomic.gff",
        tsv="results/snp_tab/" + isolate_set_name + "/{cluster}.tsv"
    output:
        tsv="results/snp_tab_with_intergenic_annotations/" + isolate_set_name + "/{cluster}.tsv"
    conda:
        "scripts/conda_env_yml/tidyverse_rtracklayer.yml"
    script:
        "scripts/add_intergenic_annotations.R"

rule add_intergenic_annotations_all:
    input:
        ["results/snp_tab_with_intergenic_annotations/" + isolate_set_name + "/" + cluster + ".tsv" for cluster in clusters]

def bwa_refseq_index_input(wildcards):
    return {"fasta":cluster_refseq_fasta[wildcards["cluster"]]}

rule bwa_refseq_index:
    input:
        unpack(bwa_refseq_index_input)
    output:
        bwt=scratch_dir + "/bwa_refseq_index/{cluster}.bwt"
    conda:
        "scripts/conda_env_yml/bwa_samtools_bamaddrg.yml"
    threads: 1
    shell:
        "bwa index -p {scratch_dir}/bwa_refseq_index/{wildcards.cluster} {input.fasta}"

def bwa_refseq_input(wildcards):
    isolate = wildcards["isolate"]
    cluster = cluster_of_isolate[isolate]
    return {"R1":fastp_files[isolate]["R1"],"R2":fastp_files[isolate]["R2"],"bwt":scratch_dir + "/bwa_refseq_index/" + cluster + ".bwt"}

rule bwa_refseq:
    input:
        unpack(bwa_refseq_input)
    output:
        bam = scratch_dir + "/bam_refseq/{isolate}.bam",
        bai = scratch_dir + "/bam_refseq/{isolate}.bam.bai"
    params:
        prefix=lambda wildcards, output: scratch_dir + "/bwa_refseq_index/" + cluster_of_isolate[wildcards["isolate"]]
    conda:
        "scripts/conda_env_yml/bwa_samtools_bamaddrg.yml"
    threads: 8
    shell:
        """
        bwa mem -t {threads} {params.prefix} {input.R1} {input.R2} > {scratch_dir}/{wildcards.isolate}.sam
        samtools sort -@ {threads} -m 2G {scratch_dir}/{wildcards.isolate}.sam > {scratch_dir}/{wildcards.isolate}.temp.bam
        rm {scratch_dir}/{wildcards.isolate}.sam
        bamaddrg -b {scratch_dir}/{wildcards.isolate}.temp.bam -s {wildcards.isolate} > {scratch_dir}/bam_refseq/{wildcards.isolate}.bam
        rm {scratch_dir}/{wildcards.isolate}.temp.bam
        samtools index {scratch_dir}/bam_refseq/{wildcards.isolate}.bam 
        """

def refseq_fasta_fai_input(wildcards):
    cluster=wildcards["cluster"]
    return {"fasta":cluster_refseq_fasta[cluster]}

#This is mostly needed because I don't have write access to the SAureusRefSeq directory, hence I can't write out the fai file...
rule refseq_fasta_fai:
    input:
        unpack(refseq_fasta_fai_input)
    output:
        fasta="results/selected_refseq_fasta/" + isolate_set_name + "/{cluster}.fasta",
        fai="results/selected_refseq_fasta/" + isolate_set_name + "/{cluster}.fasta.fai"
    conda:
        "scripts/conda_env_yml/bwa_samtools_bamaddrg.yml"
    threads: 1
    shell:
        """
        cp {input.fasta} {output.fasta}
        samtools faidx {output.fasta}
        """

def freebayes_refseq_input(wildcards):
    cluster=wildcards["cluster"]
    isolates = isolates_in_cluster[cluster]
    return {'bam' : [scratch_dir + "/bam_refseq/" + isolate + ".bam" for isolate in isolates],
            'ref':"results/selected_refseq_fasta/" + isolate_set_name + "/" + cluster + ".fasta",
            'fai':"results/selected_refseq_fasta/" + isolate_set_name + "/" + cluster + ".fasta.fai"}

rule freebayes_refseq:
    input:
        unpack(freebayes_refseq_input)
    output:
        vcf="results/freebayes/joint_calling_vs_selected_refseq/" + isolate_set_name + "/{cluster}.vcf"
    conda:
        "scripts/conda_env_yml/freebayes.yml"
    threads: 1
    shell:
        """
        #cp {input.ref} {scratch_dir}/
        freebayes -p 1 -f {input.ref} --min-alternate-count 10 --use-best-n-alleles 4 --min-alternate-fraction 0.2 --genotype-qualities {input.bam} > {output.vcf}
        """

rule bcftools_refseq:
    input:
        vcf="results/freebayes/joint_calling_vs_selected_refseq/" + isolate_set_name + "/{cluster}.vcf"
    output:
        vcf="results/bcftools/joint_vcf_filtered_refseq/" + isolate_set_name + "/{cluster}.filtered.vcf"
    conda:
        "scripts/conda_env_yml/bcftools.yml"
    threads: 1
    shell:
        """
        cat {input.vcf} | bcftools view -i 'MIN(GQ)>=100 && COUNT(GQ>=0)=N_SAMPLES' | bcftools view -e 'COUNT(GT="A")=N_SAMPLES || COUNT(GT="R")=N_SAMPLES' > {output.vcf}
        """ 

#For the RefSeq-referenced VCF files, no SnpEff step currently
rule process_vcf_refseq:
    input:
        vcf="results/bcftools/joint_vcf_filtered_refseq/" + isolate_set_name + "/{cluster}.filtered.vcf"
    output:
        tsv="results/snp_tab_no_annot_refseq/" + isolate_set_name + "/{cluster}.tsv"
    run:
        isolate_string = ",".join(isolates_in_cluster[wildcards.cluster])
        shell("python scripts/process_vcf_no_annot.py {input.vcf} {isolate_string} > {output.tsv}")

rule process_vcf_refseq_all:
    input:
        ["results/snp_tab_no_annot_refseq/" + isolate_set_name + "/" + cluster + ".tsv" for cluster in clusters]
