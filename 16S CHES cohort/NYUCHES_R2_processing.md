#Data Clean Up for NYU-CHES 16S Data Run 2
--

Using seqeuncing data from 1/31/24.

Needed Output:  

* **Feature Table**
* **Taxonomy Table**
* **Tree**
* **Metadata**

Sequencing data contains reads with spike-in *S. ruber*. If not using absolute abundance data, this *S. ruber* should be removed. So two versions of the output are processed here - one with *S. ruber* reads and one without.

######

--

#### Import demultiplexed paired-end Illumina data

```
qiime tools import \
--type 'SampleData[PairedEndSequencesWithQuality]' \
--input-path Sequence_Files_Run2 \
--input-format CasavaOneEightSingleLanePerSampleDirFmt \
--output-path demux-paired-end_R2.qza
```
  
#### Visualize imported data
```
qiime demux summarize \
  --i-data demux-paired-end_R2.qza \
  --o-visualization demux_R2.qzv
```


####Denoise
```
qiime dada2 denoise-paired \
--verbose \
--i-demultiplexed-seqs demux-paired-end_R2.qza \
--p-trunc-len-f 150 \
--p-trunc-len-r 150 \
--p-trim-left-f 0 \
--p-trim-left-r 0 \
--p-n-threads 0 \
--o-representative-sequences rep-seqs-dada2-paired-end_R2.qza \
--o-table table-dada2-paired-end_R2.qza \
--o-denoising-stats stats-dada2-paired-end_R2.qza
```

####Visualize denoising stats
```
qiime metadata tabulate \
--m-input-file stats-dada2-paired-end_R2.qza \
--o-visualization stats-dada2-paired-end_R2.qzv
```
 

####Visualize feature table and representative sequence list
```
qiime feature-table summarize \
--i-table table-dada2-paired-end_R2.qza \
--o-visualization table-paired-end_R2.qzv

qiime feature-table tabulate-seqs \
--i-data rep-seqs-dada2-paired-end_R2.qza \
--o-visualization rep-seqs-paired-end_R2.qzv
```

####Feature Classify with *Salinibacter ruber*
```
qiime feature-classifier classify-sklearn \
--i-classifier silva-138-99-515-806-nb-classifier.qza \
--i-reads rep-seqs-dada2-paired-end_R2.qza \
--o-classification taxonomy-with-salinibacter_R2.qza \
--verbose \
--p-n-jobs 6

qiime taxa barplot \
--i-table table-dada2-paired-end_R2.qza \
--i-taxonomy taxonomy-with-salinibacter_R2.qza \
--o-visualization taxa-bar-plots-paired-with-salinibacter_R2.qzv
```

####Filter out samples missing from metadata table
```
qiime feature-table filter-samples \
  --i-table table-dada2-paired-end_R2.qza \
  --m-metadata-file NYU_CHES_Sample_Metadata.tsv \
  --o-filtered-table sample-filtered-table_R2.qza
  
  qiime feature-table filter-seqs\
  --i-data rep-seqs-dada2-paired-end_R2.qza\
  --i-table sample-filtered-table_R2.qza\
  --o-filtered-data rep-seqs-sample-filtered_R2.qza
```

####Feature Classify again with *Salinibacter ruber*
```
qiime feature-classifier classify-sklearn \
--i-classifier silva-138-99-515-806-nb-classifier.qza \
--i-reads rep-seqs-sample-filtered_R2.qza \
--o-classification taxonomy-sample-filtered_R2.qza \
--verbose \
--p-n-jobs 6
```

####Filter out *S. ruber* and Mitochondria and Chloroplast
```
qiime taxa filter-seqs \
  --i-sequences rep-seqs-sample-filtered_R2.qza \
  --i-taxonomy taxonomy-sample-filtered_R2.qza \
  --p-include p__ \
  --p-exclude salinibacter,mitochondria,chloroplast \
  --o-filtered-sequences rep-seq-sample-taxa-filtered_R2.qza

qiime taxa filter-table\
  --i-table sample-filtered-table_R2.qza \
  --i-taxonomy taxonomy-sample-filtered_R2.qza \
  --p-include p__ \
  --p-exclude salinibacter,mitochondria,chloroplast \
  --o-filtered-table sample-taxa-filtered-table_R2.qza 
```

####Generate a tree for phylogenetic diversity analyses
```
qiime phylogeny align-to-tree-mafft-fasttree \
  --i-sequences rep-seq-sample-taxa-filtered_R2.qza \
  --o-alignment aligned-rep-seqs_R2.qza \
  --o-masked-alignment masked-aligned-rep-seqs_R2.qza \
  --o-tree unrooted-tree_R2.qza \
  --o-rooted-tree rooted-tree_R2.qza
```

####Feature Classify yet again, now without *S. ruber*
```
qiime feature-classifier classify-sklearn \
--i-classifier silva-138-99-515-806-nb-classifier.qza \
--i-reads rep-seq-sample-taxa-filtered_R2.qza \
--o-classification taxonomy-sample-taxa-filtered_R2.qza \
--verbose \
--p-n-jobs 6
```

####Filter Metadata Table

Peformed in R.
