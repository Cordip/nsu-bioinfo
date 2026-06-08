# DAG visualization

## Файлы

Визуализация пайплайна сохранена как графический файл: [docs/kestra-dag.jpeg](kestra-dag.jpeg).

## Способ визуализации

Для визуализации использован graph model, который отдает сама Kestra для flow [workflows/kestra/mapping-quality.yml](../workflows/kestra/mapping-quality.yml). Скрипт [scripts/generate_kestra_dag.sh](../scripts/generate_kestra_dag.sh) обращается к Kestra graph API:

```text
GET /api/v1/main/flows/nsu.infobio.assignment3/mapping_quality_ont/graph
```

Затем [scripts/render_kestra_graph_dot.py](../scripts/render_kestra_graph_dot.py) преобразует полученный JSON-граф в DOT, а `dot -Tjpeg` сохраняет итоговый файл [docs/kestra-dag.jpeg](kestra-dag.jpeg). Graphviz здесь используется только как renderer изображения; список узлов, ребер и условных cluster берется из Kestra.

`dot` из Graphviz установлен в Pixi environment через [pixi.toml](../pixi.toml). После запуска Kestra и импорта flow изображение можно пересоздать командой:

```bash
cd assignment3
pixi install
pixi run scripts/start_kestra_local.sh
pixi run scripts/import_kestra_flows.sh
pixi run scripts/generate_kestra_dag.sh
```

## Почему это DAG

DAG - directed acyclic graph, направленный ациклический граф. В этом pipeline:

- ребра направлены от более ранних задач к более поздним;
- каждая задача выполняется после своих зависимостей;
- обратных ребер и циклов нет;
- условные ветки представлены как направленные переходы `then` и `else`.

Основная цепочка:

```text
prepare_dirs
  -> download_sra
  -> fastq_dump
  -> compress_fastq
  -> fastqc
  -> index_reference
  -> map_reads
  -> sam_to_bam
  -> flagstat
  -> evaluate_mapping
  -> branch_by_mapping_quality
```

После `evaluate_mapping` Kestra строит условный cluster:

```text
branch_by_mapping_quality
  then -> write_ok -> maybe_call_variants -> write_finished
  else -> write_not_ok
```

Внутри `maybe_call_variants` есть еще одна условная ветка:

```text
maybe_call_variants
  then -> index_reference_fasta -> sort_bam -> index_bam -> call_variants
```

По умолчанию `call_variants=false`, поэтому проверенный execution завершился после `write_ok`, `maybe_call_variants` и `write_finished`, без запуска FreeBayes.

## Отличия от блок-схемы алгоритма

Блок-схема из задания описывает общий алгоритм получения вариантов. Kestra DAG показывает конкретную исполняемую реализацию этого алгоритма.

Главные отличия:

1. В Kestra DAG есть подготовительные задачи `download_sra`, `fastq_dump` и `compress_fastq`. В блок-схеме входом уже является готовый FASTQ-файл.
2. В Kestra DAG `index_reference` является отдельной исполняемой задачей перед `map_reads`. В блок-схеме `Ref. index` показан как входной артефакт.
3. В блок-схеме `FastQC` идет параллельно с картированием от FASTQ. В текущей Kestra реализации шаги идут последовательно, чтобы pipeline был проще, воспроизводимее и легче отлаживался.
4. В Kestra DAG решение `%mapped > 90%` реализовано задачей `branch_by_mapping_quality` типа `io.kestra.plugin.core.flow.If`. В блок-схеме это ромб decision node.
5. В Kestra DAG есть вложенное условие `maybe_call_variants`, зависящее от input `call_variants`. В блок-схеме после `OK` всегда идут `samtools sort` и `freebayes`.
6. В Kestra DAG каждый узел соответствует конкретной задаче фреймворка с типом runner и командой. В блок-схеме узлы являются логическими шагами алгоритма.
7. Kestra graph API включает технические start/end/cluster узлы для отображения вложенных `If`-блоков. В итоговом JPEG они сжаты до task-level графа, чтобы картинка была читаемой, но ребра и условные ветки остаются взятыми из Kestra.

Таким образом, DAG не противоречит блок-схеме, а уточняет ее до уровня реального запуска на выбранных данных и выбранном фреймворке.
