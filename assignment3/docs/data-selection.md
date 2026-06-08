# Выбор данных для assignment3

## Выбранная ветка задания

- Организм: *Escherichia coli*
- Метод секвенирования: Oxford Nanopore MinION/GridION/PromethION (ONT)
- Выравниватель: `minimap2`
- Preset для ONT genomic reads: `-x map-ont`

## Reference

В задании предложен референс *E. coli*:

<https://www.ncbi.nlm.nih.gov/assembly/GCF_000005845.2/>

Для локальной работы helper сохраняет его как:

```text
data/reference/GCF_000005845.2_ASM584v2_genomic.fna
```

## SRA accessions from the UTI89 paper

В статье про *E. coli* UTI89 перечислены несколько датасетов для разных технологий. Для задания нужно не перепутать Illumina и ONT:

| Технология | Run accession | Комментарий |
|---|---|---|
| Illumina NextSeq 500, 2x150 bp | `SRR7349974` | Не подходит под выбранную ONT-ветку |
| Oxford Nanopore MinION R9.4, 1D ligation | `SRR7517493` | Лучший ONT-кандидат для финального запуска, но большой: около 1.5Gb download |
| Oxford Nanopore MinION R7, previous dataset | `ERR908493` | Маленький ONT-кандидат для первого учебного запуска |

## Downloaded SRA candidate: small training run

Для короткого практического запуска скачан `ERR908493`:

| Поле | Значение |
|---|---|
| Run accession | `ERR908493` |
| SRA URL | <https://www.ncbi.nlm.nih.gov/sra/ERR908493> |
| Организм | *Escherichia coli* UTI89 |
| Платформа | OXFORD_NANOPORE MinION |
| Strategy | OTHER |
| Source | GENOMIC |
| Layout | SINGLE |
| Spots | 2,535 |
| Bases | 20.3M |
| Download size | 14.5 Mb |

Почему этот кандидат удобен: файл маленький, это genomic DNA, платформа MinION, layout single. Это подходит для первого запуска `minimap2 -x map-ont`.

Нюанс: локальный SRA Toolkit показывает для `ERR908493` старую SRA schema `NCBI:SRA:Illumina:tbl:phred:v2` и `SRA_PLATFORM_UNDEFINED`, хотя страница NCBI и статья относят этот run к предыдущему Oxford Nanopore MinION R7 dataset. Поэтому для финального отчета лучше либо перейти на `SRR7517493`, либо явно написать, что `ERR908493` использован как маленький учебный ONT dataset.

Ограничение: sample относится к штамму UTI89, а референс из задания - *E. coli* K-12. Поэтому результат нужно проверить через `samtools flagstat`; если `% mapped` окажется ниже 90%, стоит подобрать SRA для K-12/MG1655 или использовать более близкий референс.

## Downloaded SRA candidate: tested ONT WGS run

Также проверен `SRR39004302` из experiment `SRX33760985`:

| Поле | Значение |
|---|---|
| Run accession | `SRR39004302` |
| Experiment accession | `SRX33760985` |
| SRA URL | <https://www.ncbi.nlm.nih.gov/sra/SRX33760985> |
| Организм | *Escherichia coli* |
| Платформа | Oxford Nanopore GridION |
| Strategy | WGS |
| Source | GENOMIC |
| Layout | SINGLE |
| Spots | 50,609 |
| Bases | 156.7M |
| Download size | about 115 MB |

Этот run хорошо подходит по типу данных: ONT, genomic DNA, WGS, single-end reads. Но при проверке против assignment reference `GCF_000005845.2` он дал:

```text
50361 + 0 mapped (87.42% : N/A)
not OK...
```

Причина, вероятно, в том, что sample - клинический изолят *E. coli*, а reference из задания - *E. coli* K-12 MG1655. Для финального результата с порогом `>90% mapped` лучше найти ONT WGS reads именно для K-12/MG1655 или использовать более близкий reference и явно объяснить это в отчете.

## Selected final SRA candidate

После поиска более близкого sample выбран `SRR25637830` из experiment `SRX21364472`:

| Поле | Значение |
|---|---|
| Run accession | `SRR25637830` |
| Experiment accession | `SRX21364472` |
| SRA URL | <https://www.ncbi.nlm.nih.gov/sra/SRX21364472> |
| Организм | *Escherichia coli* str. K-12 substr. MG1655 |
| Платформа | Oxford Nanopore MinION |
| Strategy | WGS |
| Source | GENOMIC |
| Layout | SINGLE |
| Spots | 46,221 |
| Bases | 208.5M |
| Download size | about 189 MB |

Почему выбран именно он: это ONT WGS genomic reads для K-12/MG1655, то есть sample совпадает со штаммом reference `GCF_000005845.2` намного лучше, чем клинические или комменсальные изоляты.

Результат проверки:

```text
51646 + 0 mapped (99.72% : N/A)
46077 + 0 primary mapped (99.69% : N/A)
OK!
```

Этот dataset следует использовать как основной для финального пайплайна.

## Rejected or lower-priority candidates

| Experiment | Run | Причина |
|---|---|---|
| `SRX33760985` | `SRR39004302` | ONT WGS, но clinical isolate; проверка дала `87.42% mapped` |
| `SRX33737619` | `SRR38979932` | ONT WGS, но commensal isolate `24.8-S7`, не K-12 |
| `ERX16559491` | `ERR17175508` | ONT WGS, но faecal isolate, не K-12 |
| `ERX16563907` | `ERR17178816` | ONT WGS, но *E. coli* 55989 / isolate `Q181_04`, не K-12 |
| `SRX33300066` | `SRR38484913` | ONT WGS, но около 2.5 GB и не K-12 |
| `SRX32924141` | `SRR38074178` | adaptive sampling / MLST gene enrichment, хуже подходит для whole-reference mapping |

## Команды для скачивания

Основной воспроизводимый вариант из корня `assignment3` через [scripts/download_data.sh](../scripts/download_data.sh):

```bash
pixi run scripts/download_data.sh
```

Этот helper скачивает reference из NCBI FTP и выбранный ONT run из SRA:

```text
data/reference/GCF_000005845.2_ASM584v2_genomic.fna
data/reads/SRR25637830.fastq.gz
```

URL reference FASTA:

```text
https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/005/845/GCF_000005845.2_ASM584v2/GCF_000005845.2_ASM584v2_genomic.fna.gz
```

Ручной эквивалент для reads через SRA Toolkit:

```bash
prefetch SRR25637830 -O assignment3/data/sra
fasterq-dump \
  assignment3/data/sra/SRR25637830/SRR25637830.sra \
  --split-spot \
  --outdir assignment3/data/reads
gzip -f assignment3/data/reads/SRR25637830.fastq
```

Основной файл для пайплайна после скачивания:

```text
assignment3/data/reads/SRR25637830.fastq.gz
```

Старые файлы `ERR908493_*` относятся к первому проверенному кандидату, который не прошел порог `>90% mapped`, и не используются в финальном пайплайне.

Также стандартный `fasterq-dump` для paired-end runs может создавать split-файлы:

```text
assignment3/data/reads/<run>_1.fastq.gz
assignment3/data/reads/<run>_2.fastq.gz
```

## Источники

- NCBI SRA `ERR908493`: <https://www.ncbi.nlm.nih.gov/sra/ERR908493>
- NCBI SRA `SRX33760985`: <https://www.ncbi.nlm.nih.gov/sra/SRX33760985>
- NCBI SRA `SRX21364472`: <https://www.ncbi.nlm.nih.gov/sra/SRX21364472>
- NCBI SRA `SRR7517493`: <https://www.ncbi.nlm.nih.gov/sra/SRR7517493>
- UTI89 sequencing paper: <https://pmc.ncbi.nlm.nih.gov/articles/PMC7576692/>
- minimap2 ONT preset: <https://github.com/lh3/minimap2>
