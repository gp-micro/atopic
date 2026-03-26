#Data Clean up for Rectal Swabs
 
Using sequencing data from 8/22/23.

--

#### Import demultiplexed paired-end Illumina data

```
qiime tools import \
--type 'SampleData[PairedEndSequencesWithQuality]' \
--input-path Sequence_Files \
--input-format CasavaOneEightSingleLanePerSampleDirFmt \
--output-path demux-paired-end.qza
```
#### Visualize imported data
```
qiime demux summarize \
  --i-data demux-paired-end.qza \
  --o-visualization demux.qzv
```

####Denoise
```
qiime dada2 denoise-paired \
--verbose \
--i-demultiplexed-seqs demux-paired-end.qza \
--p-trunc-len-f 150 \
--p-trunc-len-r 150 \
--p-trim-left-f 0 \
--p-trim-left-r 3 \
--p-n-threads 0 \
--o-representative-sequences rep-seqs-dada2-paired-end.qza \
--o-table table-dada2-paired-end.qza \
--o-denoising-stats stats-dada2-paired-end.qza
```
####Visualize denoising stats
```
qiime metadata tabulate \
--m-input-file stats-dada2-paired-end.qza \
--o-visualization stats-dada2-paired-end.qzv
```

####Visualize feature table and representative sequence list
```
qiime feature-table summarize \
--i-table table-dada2-paired-end.qza \
--o-visualization table-paired-end.qzv

qiime feature-table tabulate-seqs \
--i-data rep-seqs-dada2-paired-end.qza \
--o-visualization rep-seqs-paired-end.qzv
```

####Feature Classify with *Salinibacter ruber*
```
qiime feature-classifier classify-sklearn \
--i-classifier silva-138-99-515-806-nb-classifier.qza \
--i-reads rep-seqs-dada2-paired-end.qza \
--o-classification taxonomy-with-salinibacter.qza \
--verbose \
--p-n-jobs 6

qiime taxa barplot \
--i-table table-dada2-paired-end.qza \
--i-taxonomy taxonomy-with-salinibacter.qza \
--o-visualization taxa-bar-plots-paired-with-salinibacter.qzv
``` 

####Filter out samples missing from metadata table
```
qiime feature-table filter-samples \
  --i-table table-dada2-paired-end.qza \
  --m-metadata-file rectal_metadata.tsv \
  --o-filtered-table sample-filtered-table.qza
  
  qiime feature-table filter-seqs\
  --i-data rep-seqs-dada2-paired-end.qza\
  --i-table sample-filtered-table.qza\
  --o-filtered-data rep-seqs-sample-filtered.qza
```

####Feature Classify again with *Salinibacter ruber*
```
qiime feature-classifier classify-sklearn \
--i-classifier silva-138-99-515-806-nb-classifier.qza \
--i-reads rep-seqs-sample-filtered.qza \
--o-classification taxonomy-sample-filtered.qza \
--verbose \
--p-n-jobs 6
```

####Filter out *S. ruber* and Mitochondria and Chloroplast
```
qiime taxa filter-seqs \
  --i-sequences rep-seqs-sample-filtered.qza \
  --i-taxonomy taxonomy-sample-filtered.qza \
  --p-include p__ \
  --p-exclude salinibacter,mitochondria,chloroplast \
  --o-filtered-sequences rep-seq-sample-taxa-filtered.qza

qiime taxa filter-table\
  --i-table sample-filtered-table.qza \
  --i-taxonomy taxonomy-sample-filtered.qza \
  --p-include p__ \
  --p-exclude salinibacter,mitochondria,chloroplast \
  --o-filtered-table sample-taxa-filtered-table.qza 
```

####Generate a tree for phylogenetic diversity analyses
```
qiime phylogeny align-to-tree-mafft-fasttree \
  --i-sequences rep-seq-sample-taxa-filtered.qza \
  --o-alignment aligned-rep-seqs.qza \
  --o-masked-alignment masked-aligned-rep-seqs.qza \
  --o-tree unrooted-tree.qza \
  --o-rooted-tree rooted-tree.qza
```

####Feature Classify again, now without *S. ruber*
```
qiime feature-classifier classify-sklearn \
--i-classifier silva-138-99-515-806-nb-classifier.qza \
--i-reads rep-seq-sample-taxa-filtered.qza \
--o-classification taxonomy-sample-taxa-filtered.qza \
--verbose \
--p-n-jobs 6
```

Rest of analyses performed in R.