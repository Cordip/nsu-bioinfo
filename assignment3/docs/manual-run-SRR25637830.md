# Manual run: SRR25637830 vs GCF_000005845.2

Цель: проверить ONT WGS-кандидат `SRR25637830` из `SRX21364472` против reference из задания `GCF_000005845.2`.

## Why This Candidate

Из всех проверенных SRA-кандидатов этот имеет лучший шанс пройти порог `>90% mapped`, потому что sample относится к тому же референсному штамму:

```text
Escherichia coli str. K-12 substr. MG1655
```

## Input

Reference:

```text
data/reference/GCF_000005845.2_ASM584v2_genomic.fna
```

Reads:

```text
data/reads/SRR25637830.fastq.gz
```

SRA metadata:

| Поле | Значение |
|---|---|
| Experiment | `SRX21364472` |
| Run | `SRR25637830` |
| Organism | *Escherichia coli* str. K-12 substr. MG1655 |
| Platform | Oxford Nanopore |
| Instrument | MinION |
| Strategy | WGS |
| Source | GENOMIC |
| Layout | SINGLE |
| Spots | 46,221 |
| Bases | 208,457,945 |
| Average read length | 4,510 bp |

## Candidate Ranking

Кандидаты с реальным шансом пройти `>90% mapped` против `GCF_000005845.2`:

| Candidate | Run | Reason | Checked result |
|---|---|---|---|
| `SRX21364472` | `SRR25637830` | K-12 MG1655, ONT, WGS, GENOMIC | `99.72% mapped`, `OK!` |

Кандидаты, которые технически являются ONT WGS, но хуже подходят к reference:

| Candidate | Run | Reason |
|---|---|---|
| `SRX33760985` | `SRR39004302` | clinical isolate, not K-12; checked: `87.42% mapped` |
| `SRX33737619` | `SRR38979932` | commensal isolate `24.8-S7`, not K-12 |
| `ERX16559491` | `ERR17175508` | isolate from faecal sample, not K-12 |
| `ERX16563907` | `ERR17178816` | *E. coli* 55989 / isolate `Q181_04`, not K-12 |
| `SRX33300066` | `SRR38484913` | ONT WGS, but about 2.5 GB and not K-12 |
| `SRX32924141` | `SRR38074178` | adaptive sampling / MLST gene enrichment, not ideal for whole-reference mapping |

## Commands

Автоматический запуск основного bash-пайплайна оценки качества картирования:

```bash
pixi run scripts/run_mapping_pipeline.sh \
  --sra-accession SRR25637830 \
  --reference data/reference/GCF_000005845.2_ASM584v2_genomic.fna \
  --sample SRR25637830_pipeline \
  --work-dir . \
  --threads 4
```

Итоговый stdout:

```text
sample=SRR25637830_pipeline
reads=./data/reads/SRR25637830.fastq.gz
reference=data/reference/GCF_000005845.2_ASM584v2_genomic.fna
results_dir=./results/SRR25637830_pipeline
flagstat=./results/SRR25637830_pipeline/SRR25637830_pipeline.flagstat.txt
mapped_percent=99.72
mapping_status=OK!
```

Ручной эквивалент отдельных шагов:

```bash
pixi run prefetch SRR25637830 -O data/sra

pixi run fasterq-dump \
  data/sra/SRR25637830/SRR25637830.sra \
  --split-spot \
  --outdir data/reads \
  --temp /tmp

pixi run gzip data/reads/SRR25637830.fastq

pixi run fastqc \
  --outdir results/manual \
  data/reads/SRR25637830.fastq.gz

pixi run minimap2 \
  -x map-ont \
  -d results/manual/GCF_000005845.2_ASM584v2_genomic.mmi \
  data/reference/GCF_000005845.2_ASM584v2_genomic.fna

pixi run minimap2 \
  -t 4 \
  -ax map-ont \
  results/manual/GCF_000005845.2_ASM584v2_genomic.mmi \
  data/reads/SRR25637830.fastq.gz \
  > results/manual/SRR25637830.sam

pixi run samtools view \
  -bS \
  results/manual/SRR25637830.sam \
  -o results/manual/SRR25637830.bam

pixi run samtools flagstat \
  results/manual/SRR25637830.bam \
  > results/manual/SRR25637830.flagstat.txt

./scripts/evaluate_mapping.sh \
  results/manual/SRR25637830.flagstat.txt \
  > results/manual/SRR25637830.mapping_status.txt
```

## `samtools flagstat`

```text
51790 + 0 in total (QC-passed reads + QC-failed reads)
46221 + 0 primary
1846 + 0 secondary
3723 + 0 supplementary
0 + 0 duplicates
0 + 0 primary duplicates
51646 + 0 mapped (99.72% : N/A)
46077 + 0 primary mapped (99.69% : N/A)
0 + 0 paired in sequencing
0 + 0 read1
0 + 0 read2
0 + 0 properly paired (N/A : N/A)
0 + 0 with itself and mate mapped
0 + 0 singletons (N/A : N/A)
0 + 0 with mate mapped to a different chr
0 + 0 with mate mapped to a different chr (mapQ>=5)
```

Mapping status:

```text
OK!
```

## Interpretation

`SRR25637830` passes the assignment threshold:

```text
99.72% mapped > 90%
```

This should be the primary reads dataset for the final manual pipeline and for the Kestra workflow.

[scripts/run_mapping_pipeline.sh](../scripts/run_mapping_pipeline.sh) по умолчанию останавливается после mapping-quality decision. Тяжелый variant-calling этап запускается только явно:

```bash
pixi run scripts/run_mapping_pipeline.sh \
  --sra-accession SRR25637830 \
  --reference data/reference/GCF_000005845.2_ASM584v2_genomic.fna \
  --sample SRR25637830_variants \
  --work-dir . \
  --threads 4 \
  --call-variants
```

Source:

```text
https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=sra&id=28802625&retmode=xml
```
