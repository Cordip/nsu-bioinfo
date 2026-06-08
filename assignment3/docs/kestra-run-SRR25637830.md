# Kestra run: SRR25637830 vs GCF_000005845.2

Этот файл фиксирует результат работы пайплайна `mapping_quality_ont` на фреймворке Kestra.

## Input

| Поле | Значение |
|---|---|
| Flow | `nsu.infobio.assignment3.mapping_quality_ont` |
| Execution ID | `2mVaKnb1TUn8eazPHuAHs3` |
| Flow revision | `3` |
| Reads experiment | `SRX21364472` |
| Reads run | `SRR25637830` |
| Reads sample | *Escherichia coli* str. K-12 substr. MG1655 |
| Platform | Oxford Nanopore MinION |
| Reference | `GCF_000005845.2_ASM584v2_genomic.fna` |
| Local `project_dir` in Kestra container | `/workspace/infobio/assignment3` |

SRA links:

- <https://www.ncbi.nlm.nih.gov/sra/SRX21364472>
- <https://www.ncbi.nlm.nih.gov/sra/SRR25637830>

## Command

Использованные helper scripts:

- [scripts/start_kestra_local.sh](../scripts/start_kestra_local.sh)
- [scripts/import_kestra_flows.sh](../scripts/import_kestra_flows.sh)
- [scripts/run_kestra_mapping.sh](../scripts/run_kestra_mapping.sh)

```bash
pixi run scripts/start_kestra_local.sh
pixi run scripts/import_kestra_flows.sh
pixi run scripts/run_kestra_mapping.sh
```

The runner script starts the execution through the Kestra REST API:

```text
POST /api/v1/main/executions/nsu.infobio.assignment3/mapping_quality_ont
```

## Result

```text
execution_state=SUCCESS
mapped_percent=99.72
mapping_status=OK!
```

Tracked log file: [docs/kestra-run-SRR25637830.log.txt](kestra-run-SRR25637830.log.txt).

Output files were written under ignored runtime storage:

```text
results/SRR25637830_kestra/
```

The relevant tracked result is copied below.

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

## Task Summary

| Task | State | Duration |
|---|---|---|
| `prepare_dirs` | `SUCCESS` | `PT0.379221S` |
| `download_sra` | `SUCCESS` | `PT0.033657S` |
| `fastq_dump` | `SUCCESS` | `PT0.026638S` |
| `compress_fastq` | `SUCCESS` | `PT0.029757S` |
| `fastqc` | `SUCCESS` | `PT15.228533S` |
| `index_reference` | `SUCCESS` | `PT0.310779S` |
| `map_reads` | `SUCCESS` | `PT23.257718S` |
| `sam_to_bam` | `SUCCESS` | `PT5.844997S` |
| `flagstat` | `SUCCESS` | `PT0.859725S` |
| `evaluate_mapping` | `SUCCESS` | `PT0.077243S` |
| `branch_by_mapping_quality` | `SUCCESS` | `PT0.167091S` |
| `write_ok` | `SUCCESS` | `PT0.034866S` |
| `maybe_call_variants` | `SUCCESS` | `PT0.013953S` |
| `write_finished` | `SUCCESS` | `PT0.048186S` |

FastQC and minimap2 print progress to stderr, so Kestra stores some progress messages with log level `ERROR`. The task states above are the authoritative execution result.

## Interpretation

The assignment threshold is `> 90%` mapped reads. This run produced:

```text
99.72% mapped > 90%
```

Therefore the Kestra pipeline wrote:

```text
OK!
Finished
```
