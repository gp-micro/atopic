#CHES 16S Data Run 1
--

Using seqeuncing data from 12/21/23.   

Needed Output:  

* **Feature Table**
* **Taxonomy Table**
* **Tree**
* **Metadata**

Sequencing data contains reads with spike-in *S. ruber*. If not using absolute abundance data, this *S. ruber* should be removed. So two versions of the output are processed here - one with *S. ruber* reads and one without.

######
--

###Work flow:

1. Import sequences
2. Denoise
3. Feature classify with *S. ruber*
4. Check data that controls look good
5. Filter Feature Table by Metadata
6. Filter Sequence List by Metadata
	* At this point, we will have a **Feature Table** with the correct samples with *S. ruber*
	* This **Feature Table** is needed to calculate absolute abundances
7. Feature classify again with *S. ruber*
	* Now we have a **Taxonomy Table** with the correct samples with *S. ruber* 
8. Filter **Feature Table** to remove *S. ruber* as well as Mitochondria and Chloroplast
	* Now we have **Feature Table** with the correct samples withOUT *S. ruber*
9. Filter **Sequence List** to remove *S. ruber*
10. Generate phylogeny 
	* Now we have a phylogeny based on the correct samples without *S. ruber* that we can use for diversity analyses. 
11. Feature classify withOUT *S. ruber* 
	* Now we have a **Taxonomy Table** with the correct samples withOUT **S. ruber**
12. Filter metadata based on **Feature Table**

--
So at the end, we will have:

* **Feature Table** with the correct samples with *S. ruber* (for absolute abundance calculation; we will need to remove *S. ruber* afterward) `sample-filtered-table_R1.qza`
* **Feature Table** with the correct samples withOUT *S. ruber* `sample-taxa-filtered-table_R1.qza`
* **Taxonomy Table** with the correct samples with *S. ruber* `taxonomy-sample-filtered_R1.qza`
* **Taxonomy Table** with the correct samples withOUT *S. ruber* `taxonomy-sample-taxa-filtered_R1.qza `
* Phylogeny without withOUT *S. ruber* `rooted-tree_R1.qza` or `unrooted-tree_R1.qza` 
* Metadata table with correct samples

--


#### Import demultiplexed paired-end Illumina data

```
qiime tools import \
--type 'SampleData[PairedEndSequencesWithQuality]' \
--input-path Sequence_Files \
--input-format CasavaOneEightSingleLanePerSampleDirFmt \
--output-path demux-paired-end_R1.qza
```
  
#### Visualize imported data
```
qiime demux summarize \
  --i-data demux-paired-end_R1.qza \
  --o-visualization demux_R1.qzv
```
  

####Denoise
```
qiime dada2 denoise-paired \
--verbose \
--i-demultiplexed-seqs demux-paired-end_R1.qza \
--p-trunc-len-f 150 \
--p-trunc-len-r 150 \
--p-trim-left-f 0 \
--p-trim-left-r 0 \
--p-n-threads 0 \
--o-representative-sequences rep-seqs-dada2-paired-end_R1.qza \
--o-table table-dada2-paired-end_R1.qza \
--o-denoising-stats stats-dada2-paired-end_R1.qza
```

####Visualize denoising stats
```
qiime metadata tabulate \
--m-input-file stats-dada2-paired-end_R1.qza \
--o-visualization stats-dada2-paired-end_R1.qzv
```

####Visualize feature table and representative sequence list
```
qiime feature-table summarize \
--i-table table-dada2-paired-end_R1.qza \
--o-visualization table-paired-end_R1.qzv

qiime feature-table tabulate-seqs \
--i-data rep-seqs-dada2-paired-end_R1.qza \
--o-visualization rep-seqs-paired-end_R1.qzv
```

####Feature Classify with *Salinibacter ruber*
```
qiime feature-classifier classify-sklearn \
--i-classifier silva-138-99-515-806-nb-classifier.qza \
--i-reads rep-seqs-dada2-paired-end_R1.qza \
--o-classification taxonomy-with-salinibacter_R1.qza \
--verbose \
--p-n-jobs 6

qiime taxa barplot \
--i-table table-dada2-paired-end_R1.qza \
--i-taxonomy taxonomy-with-salinibacter_R1.qza \
--o-visualization taxa-bar-plots-paired-with-salinibacter_R1.qzv
```


####Filter out samples missing from metadata table
```
qiime feature-table filter-samples \
  --i-table table-dada2-paired-end_R1.qza \
  --m-metadata-file NYU_CHES_Sample_Metadata.tsv \
  --o-filtered-table sample-filtered-table_R1.qza
  
  qiime feature-table filter-seqs\
  --i-data rep-seqs-dada2-paired-end_R1.qza\
  --i-table sample-filtered-table_R1.qza\
  --o-filtered-data rep-seqs-sample-filtered_R1.qza
```

####Feature Classify again with *Salinibacter ruber*
```
qiime feature-classifier classify-sklearn \
--i-classifier silva-138-99-515-806-nb-classifier.qza \
--i-reads rep-seqs-sample-filtered_R1.qza \
--o-classification taxonomy-sample-filtered_R1.qza \
--verbose \
--p-n-jobs 6
```

####Filter out *S. ruber* and Mitochondria and Chloroplast
```
qiime taxa filter-seqs \
  --i-sequences rep-seqs-sample-filtered_R1.qza \
  --i-taxonomy taxonomy-sample-filtered_R1.qza \
  --p-include p__ \
  --p-exclude salinibacter,mitochondria,chloroplast \
  --o-filtered-sequences rep-seq-sample-taxa-filtered_R1.qza

qiime taxa filter-table\
  --i-table sample-filtered-table_R1.qza \
  --i-taxonomy taxonomy-sample-filtered_R1.qza \
  --p-include p__ \
  --p-exclude salinibacter,mitochondria,chloroplast \
  --o-filtered-table sample-taxa-filtered-table_R1.qza 
```

####Generate a tree for phylogenetic diversity analyses
```
qiime phylogeny align-to-tree-mafft-fasttree \
  --i-sequences rep-seq-sample-taxa-filtered_R1.qza \
  --o-alignment aligned-rep-seqs_R1.qza \
  --o-masked-alignment masked-aligned-rep-seqs_R1.qza \
  --o-tree unrooted-tree_R1.qza \
  --o-rooted-tree rooted-tree_R1.qza
```

####Feature Classify yet again, now without *S. ruber*
```
qiime feature-classifier classify-sklearn \
--i-classifier silva-138-99-515-806-nb-classifier.qza \
--i-reads rep-seq-sample-taxa-filtered_R1.qza \
--o-classification taxonomy-sample-taxa-filtered_R1.qza \
--verbose \
--p-n-jobs 6
```

####Filter Metadata Table

Performed in R.
