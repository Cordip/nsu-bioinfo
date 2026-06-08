# Установка и запуск Kestra

Kestra выбран как декларативный движок пайплайна: workflow описывается YAML-файлом, а шаги пайплайна запускаются как задачи.

## Локальный запуск через Docker

Перед запуском Kestra нужно подготовить Pixi environment:

```bash
cd assignment3
pixi install
```

В репозитории есть скрипт локального запуска [scripts/start_kestra_local.sh](../scripts/start_kestra_local.sh):

```bash
cd assignment3
pixi run scripts/start_kestra_local.sh
```

Скрипт запускает single-container Kestra на `localhost:8080` и монтирует текущий каталог `assignment3` внутрь контейнера:

```text
$(pwd)
  -> /workspace/infobio/assignment3
```

Поэтому default `project_dir` в flow равен:

```text
/workspace/infobio/assignment3
```

Скрипт намеренно **не** монтирует `/var/run/docker.sock`. Это безопаснее: наш workflow запускает shell-команды внутри Kestra container и использует bioinformatics tools из mounted Pixi environment:

```text
/workspace/infobio/assignment3/.pixi/envs/default/bin
```

После запуска открыть UI:

```text
http://localhost:8080
```

Локальные Basic Auth credentials по умолчанию:

```text
username: admin@assignment3.local
password: Assignment3
```

Их можно переопределить перед запуском:

```bash
KESTRA_BASIC_AUTH_USERNAME='you@example.com' \
KESTRA_BASIC_AUTH_PASSWORD='StrongPassword1' \
pixi run scripts/start_kestra_local.sh
```

Пароль должен соответствовать правилу Kestra: минимум 8 символов, одна заглавная буква и одна цифра.

Импортировать или обновить flow-файлы скриптом [scripts/import_kestra_flows.sh](../scripts/import_kestra_flows.sh):

```bash
pixi run scripts/import_kestra_flows.sh
```

Скрипт использует актуальный REST endpoint Kestra `/api/v1/main/flows/bulk?delete=false&allowNamespaceChild=true`.
Старый CLI `java -jar /app/kestra flow update` на Kestra `1.3.21` уже deprecated и возвращал `404` на endpoint старого формата.

## Вариант через Docker Compose

Для более production-like установки можно использовать официальный Docker Compose из документации Kestra:

```bash
pixi run curl -o docker-compose.yml https://raw.githubusercontent.com/kestra-io/kestra/develop/docker-compose.yml
docker compose up -d
```

В этом варианте также нужно добавить bind mount каталога `assignment3` в Kestra worker/server container и выставить `project_dir` на путь mount. Локальный путь проекта берется как текущий каталог после `cd assignment3`:

```text
$(pwd)
```

## Flow `mapping_quality_ont`

Основной workflow находится здесь: [workflows/kestra/mapping-quality.yml](../workflows/kestra/mapping-quality.yml).

Перед запуском flow после fresh clone нужно восстановить ignored input data через [scripts/download_data.sh](../scripts/download_data.sh):

```bash
pixi run scripts/download_data.sh
```

Он повторяет bash-пайплайн оценки качества картирования:

```text
prefetch
  -> fasterq-dump
  -> gzip
  -> FastQC
  -> minimap2 index
  -> minimap2 map
  -> samtools view
  -> samtools flagstat
  -> parse % mapped
  -> OK / not OK branch
```

Основные input values:

| Input | Значение по умолчанию |
|---|---|
| `project_dir` | `/workspace/infobio/assignment3` |
| `sra_accession` | `SRR25637830` |
| `reference_fasta` | `data/reference/GCF_000005845.2_ASM584v2_genomic.fna` |
| `sample_name` | `SRR25637830_kestra` |
| `threads` | `4` |
| `call_variants` | `false` |

`call_variants=false` выбран по умолчанию, потому что обязательная часть задания - оценка mapping quality и вывод `OK!`/`not OK...`. Шаги `samtools sort`, `samtools index` и `freebayes` оставлены в DAG под флагом `call_variants=true`.

Запустить основной flow из терминала через [scripts/run_kestra_mapping.sh](../scripts/run_kestra_mapping.sh):

```bash
pixi run scripts/run_kestra_mapping.sh
```

В локальном Docker-варианте shell tasks используют Process runner:

```yaml
taskRunner:
  type: io.kestra.plugin.core.runner.Process
```

Это нужно потому, что script tasks в Kestra по умолчанию используют Docker runner. Мы не монтируем `/var/run/docker.sock`, поэтому Docker runner внутри Kestra container не сможет стартовать nested containers. Process runner запускает команды прямо внутри Kestra container и видит mounted Pixi environment.

## Что проверить после запуска

1. Flow `hello_world_assignment3` импортируется и выводит строку `Hello world from assignment3`.
2. Flow `mapping_quality_ont` импортируется без ошибок YAML.
3. Execution `mapping_quality_ont` завершается с `mapped_percent` около `99.72` и статусом `OK!`.
4. В графическом представлении Kestra видны последовательные шаги пайплайна и условная развилка после оценки `mapped_percent`.

## Источники

- Kestra Docker Compose installation: <https://kestra.io/docs/installation/docker-compose>
- Kestra Flow: <https://kestra.io/docs/workflow-components/flow>
- Kestra Shell commands: <https://kestra.io/docs/how-to-guides/shell>
- Kestra Process task runner: <https://kestra.io/docs/task-runners/types/process-task-runner>
