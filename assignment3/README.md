# Домашнее задание 3: Пайплайн получения генетических вариантов

Гаврильев Максим Игоревич, группа 23216

## Выбранный стек

| Компонент | Выбор | Ссылка | Комментарий |
|---|---|---|---|
| Метод секвенирования | Oxford Nanopore MinION/GridION/PromethION (ONT) | - | Длинные риды Oxford Nanopore Technologies |
| Инструмент картирования | minimap2 | <https://github.com/lh3/minimap2> | Подходит для ONT-ридов |
| Движок пайплайна | Kestra | <https://kestra.io/> | Современный, декларативный |
| Окружение | Pixi | <https://pixi.sh/> | Conda-forge environment без ручной установки bioinformatics tools |

## Обоснование выбора

Для задания выбран метод секвенирования **Oxford Nanopore MinION/GridION/PromethION (ONT)**. Для картирования ONT-ридов используется **minimap2**, так как он поддерживает длинные риды и является стандартным инструментом для таких данных.

В качестве фреймворка создания пайплайна выбран **Kestra**. Он позволяет описывать пайплайны декларативно и подходит для воспроизводимого запуска отдельных этапов: проверки качества, картирования, разбора `samtools flagstat`, сортировки BAM и последующего коллинга вариантов.

## Что уже реализовано

| Артефакт | Назначение |
|---|---|
| [TASK.md](TASK.md) | Текст задания в Markdown |
| [docs/data-selection.md](docs/data-selection.md) | Кандидат SRA-данных и выбранная ветка задания |
| [docs/kestra-install.md](docs/kestra-install.md) | Короткая инструкция по установке и запуску Kestra |
| [docs/kestra-run-SRR25637830.md](docs/kestra-run-SRR25637830.md) | Результат работы Kestra pipeline на выбранных данных |
| [docs/kestra-run-SRR25637830.log.txt](docs/kestra-run-SRR25637830.log.txt) | Лог-файл успешного Kestra execution |
| [docs/kestra-dag.jpeg](docs/kestra-dag.jpeg) | Графическая визуализация DAG pipeline |
| [docs/dag-visualization.md](docs/dag-visualization.md) | Описание способа визуализации и отличий DAG от блок-схемы |
| [pixi.toml](pixi.toml), [pixi.lock](pixi.lock) | Описание и lockfile локального bioinformatics environment |
| [scripts/download_data.sh](scripts/download_data.sh) | Восстанавливает ignored reference/reads data из NCBI |
| [scripts/run_mapping_pipeline.sh](scripts/run_mapping_pipeline.sh) | Полный bash-пайплайн: SRA -> FASTQ -> FastQC -> minimap2 -> BAM -> flagstat -> OK/not OK |
| [scripts/parse_flagstat.py](scripts/parse_flagstat.py) | Извлекает `% mapped` из вывода `samtools flagstat` |
| [scripts/evaluate_mapping.sh](scripts/evaluate_mapping.sh) | Печатает `OK!`, если `% mapped > 90`, иначе `not OK...` |
| [scripts/start_kestra_local.sh](scripts/start_kestra_local.sh) | Запускает локальный Kestra container |
| [scripts/import_kestra_flows.sh](scripts/import_kestra_flows.sh) | Импортирует/обновляет Kestra flows через REST API |
| [scripts/run_kestra_mapping.sh](scripts/run_kestra_mapping.sh) | Запускает `mapping_quality_ont` и ожидает завершения |
| [scripts/generate_kestra_dag.sh](scripts/generate_kestra_dag.sh) | Получает DAG из Kestra graph API и сохраняет [docs/kestra-dag.jpeg](docs/kestra-dag.jpeg) |
| [scripts/render_kestra_graph_dot.py](scripts/render_kestra_graph_dot.py) | Конвертирует Kestra graph JSON в DOT для рендера |
| [data/examples/flagstat_ok.txt](data/examples/flagstat_ok.txt) | Toy-пример высокого процента картирования |
| [data/examples/flagstat_not_ok.txt](data/examples/flagstat_not_ok.txt) | Toy-пример низкого процента картирования |
| [tests/test_flagstat_tools.sh](tests/test_flagstat_tools.sh) | Проверяет parser и bash-оценку |
| [tests/test_kestra_workflow.sh](tests/test_kestra_workflow.sh) | Проверяет структуру Kestra mapping workflow |
| [workflows/kestra/hello-world.yml](workflows/kestra/hello-world.yml) | Минимальный Kestra `Hello world` |
| [workflows/kestra/mapping-quality.yml](workflows/kestra/mapping-quality.yml) | Kestra workflow для ONT mapping-quality pipeline |

## Выбранные данные

Основной dataset для финального пайплайна:

| Поле | Значение |
|---|---|
| Reference | `GCF_000005845.2` (*E. coli* K-12 MG1655) |
| Reads experiment | `SRX21364472` |
| Reads run | `SRR25637830` |
| SRA links | <https://www.ncbi.nlm.nih.gov/sra/SRX21364472>, <https://www.ncbi.nlm.nih.gov/sra/SRR25637830> |
| Reads sample | *E. coli* str. K-12 substr. MG1655 |
| Platform | Oxford Nanopore MinION |
| Mapping result | `99.72% mapped` |
| Status | `OK!` |

Подробности сохранены в [docs/manual-run-SRR25637830.md](docs/manual-run-SRR25637830.md).

## Подготовка окружения

Для воспроизводимого запуска используется **Pixi**. Он создает локальное окружение `.pixi/` из [pixi.toml](pixi.toml) и [pixi.lock](pixi.lock); это окружение не коммитится в Git.

Если `pixi` еще не установлен, сначала установите его по официальной инструкции: <https://pixi.sh/latest/installation/>.

После clone подготовить окружение:

```bash
cd assignment3
pixi install
```

После этого все команды ниже запускаются через `pixi run`, поэтому `minimap2`, `samtools`, `fastqc`, `sra-tools`, `freebayes`, `graphviz`, `curl` и `gzip` не нужно ставить вручную в систему.

## Чеклист требований GitHub

| № | Требование | Где закрыто |
|---|---|---|
| 1 | Ссылка на загруженные прочтения из NCBI SRA | [README.md](README.md), [docs/manual-run-SRR25637830.md](docs/manual-run-SRR25637830.md), [docs/kestra-run-SRR25637830.md](docs/kestra-run-SRR25637830.md), [scripts/download_data.sh](scripts/download_data.sh) |
| 2 | Скрипт на bash с реализованным алгоритмом | [scripts/run_mapping_pipeline.sh](scripts/run_mapping_pipeline.sh) |
| 3 | Результат команды `samtools flagstat` | [docs/manual-run-SRR25637830.md](docs/manual-run-SRR25637830.md), [docs/kestra-run-SRR25637830.md](docs/kestra-run-SRR25637830.md) |
| 4 | Скрипт разбора `samtools flagstat` | [scripts/parse_flagstat.py](scripts/parse_flagstat.py) |
| 5 | FASTQ/SAM/BAM/VCF | Не коммитятся, потому что большие; [scripts/download_data.sh](scripts/download_data.sh) восстанавливает input data, runtime paths описаны в docs |
| 6 | Инструкция по развертыванию фреймворка | [docs/kestra-install.md](docs/kestra-install.md) |
| 7 | Тестовый pipeline `Hello world` | [workflows/kestra/hello-world.yml](workflows/kestra/hello-world.yml) |
| 8 | Результаты работы pipeline на фреймворке и логи | [docs/kestra-run-SRR25637830.md](docs/kestra-run-SRR25637830.md), [docs/kestra-run-SRR25637830.log.txt](docs/kestra-run-SRR25637830.log.txt) |
| 9 | Описание visual tools / скриншоты | [docs/dag-visualization.md](docs/dag-visualization.md), [scripts/generate_kestra_dag.sh](scripts/generate_kestra_dag.sh) |
| 10 | Код pipeline оценки качества на фреймворке | [workflows/kestra/mapping-quality.yml](workflows/kestra/mapping-quality.yml) |
| 11 | Выведенные результаты pipeline в отдельном файле | [docs/kestra-run-SRR25637830.md](docs/kestra-run-SRR25637830.md) |
| 12 | Лог-файлы pipeline | [docs/kestra-run-SRR25637830.log.txt](docs/kestra-run-SRR25637830.log.txt) |
| 13 | Визуализация pipeline графическим файлом | [docs/kestra-dag.jpeg](docs/kestra-dag.jpeg), [scripts/generate_kestra_dag.sh](scripts/generate_kestra_dag.sh) |
| 14 | Описание визуализации и отличий DAG | [docs/dag-visualization.md](docs/dag-visualization.md) |

## Быстрая проверка

Восстановить ignored input data после fresh clone:

```bash
cd assignment3
pixi run scripts/download_data.sh
```

Скрипт создает:

```text
data/reference/GCF_000005845.2_ASM584v2_genomic.fna
data/reads/SRR25637830.fastq.gz
```

Проверить весь bash-пайплайн оценки качества картирования:

```bash
cd assignment3
pixi run scripts/run_mapping_pipeline.sh \
  --sra-accession SRR25637830 \
  --reference data/reference/GCF_000005845.2_ASM584v2_genomic.fna \
  --sample SRR25637830_pipeline \
  --work-dir . \
  --threads 4
```

Ожидаемый итог:

```text
mapped_percent=99.72
mapping_status=OK!
```

Проверить unit/smoke tests:

```bash
cd assignment3
pixi run bash tests/test_flagstat_tools.sh
pixi run bash tests/test_run_mapping_pipeline.sh
pixi run bash tests/test_kestra_workflow.sh
pixi run bash tests/test_kestra_runtime_config.sh
pixi run bash tests/test_kestra_helper_scripts.sh
pixi run bash tests/test_submission_artifacts.sh
pixi run bash tests/test_download_data_script.sh
```

Ожидаемый вывод включает:

```text
All flagstat tool tests passed.
Full mapping pipeline smoke test passed.
Kestra mapping workflow structure test passed.
Kestra runtime config test passed.
Kestra helper script tests passed.
Submission artifact tests passed.
Download data script tests passed.
```

## Kestra

Локальный запуск:

```bash
cd assignment3
pixi run scripts/download_data.sh
pixi run scripts/start_kestra_local.sh
pixi run scripts/import_kestra_flows.sh
pixi run scripts/run_kestra_mapping.sh
pixi run scripts/generate_kestra_dag.sh
```

UI: `http://localhost:8080`

Credentials по умолчанию:

```text
username: admin@assignment3.local
password: Assignment3
```

Проверенный Kestra execution `mapping_quality_ont` завершился `SUCCESS`; результат в `results/SRR25637830_kestra/`:

```text
mapped_percent=99.72
mapping_status=OK!
```

Tracked result and visualization artifacts:

- [docs/kestra-run-SRR25637830.md](docs/kestra-run-SRR25637830.md)
- [docs/kestra-run-SRR25637830.log.txt](docs/kestra-run-SRR25637830.log.txt)
- [docs/kestra-dag.jpeg](docs/kestra-dag.jpeg)
- [docs/dag-visualization.md](docs/dag-visualization.md)
- [scripts/generate_kestra_dag.sh](scripts/generate_kestra_dag.sh)

`call_variants=false` остается значением по умолчанию. Ветка `samtools sort` -> `samtools index` -> `freebayes` есть в DAG как optional branch, но не запускается в проверочном Kestra execution.
