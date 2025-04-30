import sys

#VCF filename
fname = sys.argv[1]
#comma-separated string with all of the isolates we need
isolates_string = sys.argv[2]
samplenames = isolates_string.split(',')

#ann_names = ["Allele","Annotation","Annotation_Impact","Gene_Name","Gene_ID","Feature_Type","Feature_ID ","Transcript_BioType","Rank",
#        "HGVS.c","HGVS.p","cDNA.pos / cDNA.length","CDS.pos / CDS.length","AA.pos / AA.length","Distance","ERRORS / WARNINGS / INFO"]

with open(fname,'r') as fin:
    for l in fin.readlines():
        if l.startswith('#') and not l.startswith('##'):
            colnames = l.rstrip()[1:].split()
            #if cluster_prefix=='22AD5N+60AD1':
            #    samplenames = [colname for colname in colnames if (colname.startswith('22AD5N') or colname.startswith('60AD1'))]
            #else:
            #    samplenames = [colname for colname in colnames if colname.startswith(cluster_prefix)]
            output_colnames = ['CHROM','POS','REF','ALT'] + samplenames
            print("\t".join(output_colnames))
        if not l.startswith('#'):
            pieces = l.rstrip().split()
            d = {}
            for colname,val in zip(colnames,pieces):
                d[colname] = val
            info = {}
            for AequalsB in d['INFO'].split(';'):
                A,B = AequalsB.split('=')
                info[A] = B
            d['INFO'] = info
            alleles = [d["REF"]] + d["ALT"].split(',')
            genocodes = {}
            genotypes = {}
            for sample in samplenames:
                genocode = int(d[sample].split(':')[0])
                genocodes[sample] = genocode
                genotype = alleles[genocode]
                genotypes[sample] = genotype
            d['genocodes'] = genocodes
            d['genotypes'] = genotypes
            #annotations = []
            #for annotation in d["INFO"]["ANN"].split(','):
            #    ann_dict = {}
            #    for ann_name,val in zip(ann_names,annotation.split('|')):
            #        ann_dict[ann_name] = val
            #    annotations.append(ann_dict)
            #d['annotations'] = [a for a in annotations if a['Annotation'] != 'intragenic_variant']
            #d['annotations'] = annotations
            #annotation_string = " // ".join([f"Allele {a['Allele']}: {a['Annotation']},{a['Gene_Name']} ({a['Gene_ID']}),{a['HGVS.c']},{a['HGVS.p']}" for a in d['annotations']])
            parts = [d['CHROM'],d['POS'],d['REF'],d['ALT']]
            parts += [d['genotypes'][sample] for sample in samplenames]
            print("\t".join(parts))
