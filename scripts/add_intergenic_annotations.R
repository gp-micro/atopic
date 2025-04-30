library(tidyverse)
library(rtracklayer)

df.gff <- rtracklayer::readGFF(snakemake@input$gff) %>%
      data.frame

locus_tags_with_multiple_coordinates <- df.gff %>%
    filter(!is.na(locus_tag)) %>%
    select(seqid,start,end,locus_tag) %>%
    distinct %>%
    add_count(locus_tag) %>%
    filter(n>1) %>%
    pull(locus_tag)

df.coords <- df.gff %>%
    filter(!is.na(locus_tag)) %>%
    group_by(locus_tag,seqid,strand) %>%
    #There are a handful of genes (see above) with multiple coding sequences
    summarize(start=min(start),end=max(end),.groups='drop') %>%
    column_to_rownames('locus_tag')

df.tab <- read_tsv(snakemake@input$tsv,col_types=cols( CHROM=col_character(), POS=col_double(), REF=col_character(), ALT=col_character(), ANNOTATIONS=col_character(), .default=col_character()))

process_annotation <- function(a,POS){
  if(!grepl("intergenic",a)){
      return(a)
    } else {
        gene_info <- word(a,2,sep=',')
        part2 <- sub("[)]$","",word(gene_info,2,sep='[(]'))
        left <- word(part2,1,sep='-')
        right <- word(part2,2,sep='-')
        
        dist.left <- POS-df.coords[left,'end']
        updownstream.left <- ifelse(df.coords[left,'strand']=='+','downstream','upstream')
        
        dist.right <- df.coords[right,'start'] - POS
        updownstream.right <- ifelse(df.coords[right,'strand']=='+','upstream','downstream')
        
        s <- paste0(as.character(dist.left),' nt ',updownstream.left,' of ',left)
        s <- paste0(s,' ; ',as.character(dist.right),' nt ',updownstream.right,' of ',right)
      }
}

df.tab %>%
    separate_rows(ANNOTATIONS,sep=' // ') %>%
    mutate(ANNOTATIONS = Vectorize(process_annotation)(ANNOTATIONS,POS)) %>%
    group_by(across(-ANNOTATIONS)) %>%
    summarize(ANNOTATIONS=paste0(ANNOTATIONS,collapse=' // '),.groups='drop') %>%
    select(CHROM,POS,REF,ALT,ANNOTATIONS,everything()) %>%
    write_tsv(snakemake@output$tsv)
