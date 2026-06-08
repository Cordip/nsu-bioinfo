# Домашнее задание 3: Построение пайплайна получения генетических вариантов

Юрий Викторович Вяткин
E-mail: <vyatkin@gmail.com>

Факультет информационных технологий
Новосибирский государственный университет
Весенний семестр 2026

## Организационное

- **Куда сдавать:** оформить решение в репозитории на GitHub и выслать преподавателю на почту `vyatkin@gmail.com`.
- **Обязательно указать:** ФИО слушателя и ссылку на репозиторий.
- **Срок выполнения:** 2 недели, до **08.06.26**.
- Наличие выполненного задания и срок сдачи влияют на допуск к экзамену и оценку.

## Задачи

1. Найти Linux, вспомнить bash.
2. Найти на NCBI SRA и скачать результат секвенирования, то есть набор ридов:
   - **Escherichia coli** (`e.coli`), или
   - **Homo sapiens**:
     - WES/WXS - whole exome sequencing, 2-20Gb;
     - WGS - whole genome sequencing, осторожно, большой файл.
3. Скачать референсный геном:
   - `e.coli`: <https://www.ncbi.nlm.nih.gov/assembly/GCF_000005845.2/>
   - `Homo sapiens`: <https://hgdownload.soe.ucsc.edu/goldenPath/hg38/bigZips/hg38.fa.gz>
4. Скачать и установить, скомпилировав или используя бинарный файл, консольные версии программ:
   - FastQC;
   - bwa или minimap2;
   - samtools.
5. Изучить простой запуск этих программ: Getting started, Quick start и т.д.
6. Индексировать референсный геном соответствующим инструментом.
7. Написать скрипт на bash/Python для разбора результатов `samtools flagstat` и получения процента картированных ридов.
8. Реализовать алгоритм оценки качества картирования на bash со всеми элементами, в том числе с выводом сообщения вида `OK`/`not OK`.
9. Найти, скачать и установить или развернуть фреймворк создания пайплайнов.
10. Написать короткую инструкцию по скачиванию и установке фреймворка.
11. Изучить базовые возможности фреймворка: Tutorials, YouTube и т.д. Написать тест `Hello world`.
12. Реализовать пайплайн оценки качества картирования на фреймворке.
13. Визуализировать полученный пайплайн автоматическими инструментами фреймворка.
14. Описать использованный способ визуализации и отличия полученного DAG от блок-схемы алгоритма.

## Что должно быть в GitHub-репозитории

1. Ссылка на загруженные прочтения из NCBI SRA.
2. Скрипт на bash с реализованным алгоритмом.
3. Результат команды `samtools flagstat`.
4. Скрипт разбора файлов с этими результатами.
5. *Опционально:* файлы FASTQ, SAM/BAM, VCF в архивах, так как они могут быть большого размера.
6. Инструкция по развертыванию и установке фреймворка.
7. Код любого тестового пайплайна `Hello world` на фреймворке.
8. Результаты работы пайплайна на фреймворке и лог-файлы.
9. *Опционально:* описание использованных инструментов для визуального создания пайплайнов, скриншоты.
10. Код пайплайна оценки качества картирования на фреймворке.
11. Выведенные результаты работы пайплайна на загруженных данных в отдельном файле.
12. Лог-файлы работы пайплайна на загруженных данных.
13. Визуализация пайплайна в виде графического файла.
14. Описание использованного способа визуализации и отличий полученной визуализации от блок-схемы алгоритма в свободной форме.

## Алгоритм получения генетических вариантов

```mermaid
flowchart TD
    fastq[Your FASTQ file(s)]
    ref_index[Ref. index]
    fastqc[FastQC]
    qc_report[Rename and save QC-report]
    align[BWA/minimap2]
    view[samtools view]
    flagstat[samtools flagstat]
    parse[Parse: %mapped]
    decision{%mapped > 90%}
    not_ok[Write not OK]
    ok[Write OK]
    sort[samtools sort]
    freebayes[freebayes]
    finished[Write Finished]

    fastq --> fastqc
    fastqc --> qc_report
    fastq --> align
    ref_index --> align
    align --> view
    view --> flagstat
    flagstat --> parse
    parse --> decision
    decision -- No --> not_ok
    decision -- Yes --> ok
    ok --> sort
    sort --> freebayes
    not_ok --> finished
    freebayes --> finished
```

## Burrows-Wheeler Aligner

### BWA

- Команда: `bwa mem`
- Ссылка: <https://github.com/lh3/bwa>

### Minimap2

- Ссылка: <https://github.com/lh3/minimap2>

### Индексирование референса

- **Вход:** `hg38.fa`
- **Выход:** `hg38.fa.*`, `hg38.mmi`

### Картирование

- **Вход:** `hg38.fa.*`, `sample_1.fastq(.gz)`, `sample_2.fastq(.gz)`
- **Выход:** `sample.sam`

## Конвертация форматов SAM/BAM

### Samtools

- Команда: `samtools view`
- Ссылка: <https://github.com/samtools/samtools>

### SAM -> BAM

- **Вход:** `sample.sam`
- **Выход:** `sample.bam`, `sample.bai`

### BAM -> SAM

- **Вход:** `sample.bam`
- **Выход:** `sample.sam`

## Оценка SAM/BAM

### Samtools

- Команда: `samtools flagstat`
- Ссылка: <https://github.com/samtools/samtools>
- **Вход:** `sample.bam`
- **Выход:** `sample.txt`

Пример результата `samtools flagstat`:

```text
1099585 + 0 in total (QC-passed reads + QC-failed reads)
0 + 0 secondary
159 + 0 supplementary
183658 + 0 duplicates
1097662 + 0 mapped (99.83% : N/A)
1099426 + 0 paired in sequencing
549713 + 0 read1
549713 + 0 read2
1091988 + 0 properly paired (99.32% : N/A)
1095974 + 0 with itself and mate mapped
1529 + 0 singletons (0.14% : N/A)
3566 + 0 with mate mapped to a different chr
2892 + 0 with mate mapped to a different chr (mapQ>=5)
```

Строка для разбора:

```text
1097662 + 0 mapped (99.83% : N/A)
```

Правило оценки:

- Если процент картированных ридов **> 90%**, вывести `OK!`.
- Если процент картированных ридов **< 90%**, вывести `not OK...`.

## Сортировка BAM

### Samtools

- Команда: `samtools sort`
- Ссылка: <https://github.com/samtools/samtools>
- **Вход:** `sample.bam`
- **Выход:** `sample.sorted.bam`

## Коллинг генетических вариантов FreeBayes

- Инструмент: FreeBayes
- Ссылка: <https://github.com/freebayes/freebayes>
- **Вход:** `hg38.fa`, `sample.sorted.bam`
- **Выход:** `sample.vcf`
