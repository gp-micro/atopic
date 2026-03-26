#Merging Sequencing Runs for NYU CHES 16S

Merged the following files:

* For relative abundance:
	* sample-taxa-filtered-table.qza
	* taxonomy-sample-taxa-filtered.qza

* For absolute abundance:
	* sample-filtered-table.qza
	* taxonomy-sample-filtered.qza

--
	
To merge features tables:

For relative abundance data:

```
qiime feature-table merge \
	--i-tables sample-taxa-filtered-table_R1.qza \
	--i-tables sample-taxa-filtered-table_R2.qza \
	--p-overlap-method sum \
	--o-merged-table sample-taxa-filtered-table_NYUCHES_R1R2merged.qza
```


For absolute abundance data:

```
qiime feature-table merge \
	--i-tables sample-filtered-table_R1.qza \
	--i-tables sample-filtered-table_R2.qza \
	--p-overlap-method sum \
	--o-merged-table sample-filtered-table_NYUCHES_R1R2merged.qza
```

--
 
To merge taxonomy tables:
 
For relative abundance data:

```
qiime feature-table merge-taxa\
	--i-data taxonomy-sample-taxa-filtered_R2.qza \
	--i-data taxonomy-sample-taxa-filtered_R1.qza \
	--o-merged-data taxonomy-sample-taxa-filtered_NYUCHES_R1R2merged.qza
```


For absolute abundance data:

```
qiime feature-table merge-taxa \
	--i-data taxonomy-sample-filtered_R2.qza \
	--i-data taxonomy-sample-filtered_R1.qza \
	--o-merged-data taxonomy-sample-filtered_NYUCHES_R1R2merged.qza
```
 
-- 
 
Merge representative sequences so as to make a tree:

```
qiime feature-table merge-seqs \
	--i-data rep-seq-sample-taxa-filtered_R2.qza \
	--i-data rep-seq-sample-taxa-filtered_R1.qza \
	--o-merged-data rep-seq-sample-taxa-filtered_NYUCHES_R1R2merged.qza
```

 
To generate a tree:

```
qiime phylogeny align-to-tree-mafft-fasttree \
  --i-sequences rep-seq-sample-taxa-filtered_NYUCHES_R1R2merged.qza\
  --o-alignment aligned-rep-seqs_NYUCHES_R1R2merged.qza \
  --o-masked-alignment masked-aligned-rep-seqs_NYUCHES_R1R2merged.qza \
  --o-tree unrooted-tree_NYUCHES_R1R2merged.qza \
  --o-rooted-tree rooted-tree_NYUCHES_R1R2merged.qza
```
 