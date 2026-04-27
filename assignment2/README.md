# Домашнее задание 2: Изучение представленности генов в таксонах

Гаврильев Максим Игоревич, группа 23216

## Выбранный ген

**Gene Symbol:** `CNGA3`

**Полное название:** cyclic nucleotide gated channel subunit alpha 3

**Организм:** *Homo sapiens* (человек разумный)

**RefSeq:** [NM_001298.3](https://www.ncbi.nlm.nih.gov/nuccore/NM_001298.3)

`CNGA3` кодирует альфа-субъединицу циклического нуклеотид-зависимого канала колбочек сетчатки. Белок участвует в фототрансдукции, то есть в преобразовании светового сигнала в электрический сигнал фоторецептора. Мутации в `CNGA3` связаны с ахроматопсией.

Для анализа использовались **CDS-последовательности**, так как они соответствуют кодирующей части гена и удобны для сравнения между разными видами.

## Параметры BLAST

Гомологичные последовательности искались через **NCBI BLASTN** по CDS человеческого гена `CNGA3`.

| Параметр | Значение |
|---|---|
| Query | CDS *Homo sapiens* `CNGA3` (`NM_001298.3`), 2085 нт |
| Database | Reference RNA sequences (`refseq_rna`) |
| Program | `blastn`, somewhat similar sequences |
| Organism filters | использовались в отдельных запросах |

Было выполнено несколько BLAST-запросов:

| Файл | Назначение |
|---|---|
| `results/blast/1-mammals_descriptions.csv` | общий поиск без ограничения по таксону |
| `results/blast/2-nonmammals_descriptions.csv` | поиск с исключением `Mammalia (taxid:40674)` |
| `results/blast/3-fish_amphibians_descriptions.csv` | поиск по `Actinopterygii (taxid:7898)` и `Amphibia (taxid:8292)` |

Из результатов выбирались последовательности, аннотированные как `CNGA3`, `Cnga3`, `cnga3` или близкие рыбные варианты `cnga3a`. Похожие члены семейства (`CNGA1`, `CNGA2`, `CNGA4`, `CNGB3`) не использовались.

## Найденные гомологичные гены

Итоговый набор включает исходный человеческий `CNGA3` и 10 гомологичных последовательностей из других видов.

| № | Вид | Русское название | Группа | Gene Symbol | RefSeq | Длина CDS |
|---:|---|---|---|---|---|---:|
| 0 | *Homo sapiens* | человек разумный | исходный ген | `CNGA3` | [NM_001298.3](https://www.ncbi.nlm.nih.gov/nuccore/NM_001298.3) | 2085 |
| 1 | *Pan troglodytes* | шимпанзе обыкновенный | млекопитающие | `CNGA3` | [XM_054678681.2](https://www.ncbi.nlm.nih.gov/nuccore/XM_054678681.2) | 2031 |
| 2 | *Lepus europaeus* | заяц-русак | млекопитающие | `CNGA3` | [XM_062208882.1](https://www.ncbi.nlm.nih.gov/nuccore/XM_062208882.1) | 2085 |
| 3 | *Loxodonta africana* | африканский слон | млекопитающие | `CNGA3` | [XM_023552513.2](https://www.ncbi.nlm.nih.gov/nuccore/XM_023552513.2) | 2076 |
| 4 | *Aythya fuligula* | хохлатая чернеть | птицы | `CNGA3` | [XM_032200842.1](https://www.ncbi.nlm.nih.gov/nuccore/XM_032200842.1) | 2196 |
| 5 | *Nothoprocta perdicaria* | чилийский тинаму | птицы | `CNGA3` | [XM_026035640.1](https://www.ncbi.nlm.nih.gov/nuccore/XM_026035640.1) | 1905 |
| 6 | *Podarcis erhardii* | эгейская стенная ящерица | пресмыкающиеся | `CNGA3` | [XM_081858976.1](https://www.ncbi.nlm.nih.gov/nuccore/XM_081858976.1) | 2202 |
| 7 | *Chelonia mydas* | зелёная черепаха | пресмыкающиеся | `CNGA3` | [XM_037898670.2](https://www.ncbi.nlm.nih.gov/nuccore/XM_037898670.2) | 2025 |
| 8 | *Ambystoma mexicanum* | мексиканская амбистома / аксолотль | амфибии | `CNGA3` | [XM_069636583.1](https://www.ncbi.nlm.nih.gov/nuccore/XM_069636583.1) | 2199 |
| 9 | *Megalops cyprinoides* | индо-тихоокеанский тарпон | лучепёрые рыбы | `cnga3a` | [XM_036545736.1](https://www.ncbi.nlm.nih.gov/nuccore/XM_036545736.1) | 2247 |
| 10 | *Callorhinchus milii* | австралийская химера | хрящевые рыбы | `cnga3a` | [XM_007891119.2](https://www.ncbi.nlm.nih.gov/nuccore/XM_007891119.2) | 2043 |

У рыб и химеры используются обозначения `cnga3a`. Такие последовательности рассматривались как гомологи `CNGA3`; при этом они могут не быть строгими 1-к-1 ортологами человеческого гена.

## Файлы с последовательностями

Последовательности сохранены в папке `data/`:

- `data/CNGA3_selected_cds.fasta` — общий FASTA-файл для множественного выравнивания с короткими заголовками
- `data/individual/` — отдельные CDS с короткими заголовками
- `data/original/` — оригинальные FASTA-файлы, полученные из NCBI
- `data/CNGA3_selected_metadata.tsv` — таблица с видами, accession и длинами CDS

## Множественное выравнивание

Множественное выравнивание построено через **Clustal Omega**.

| Параметр | Значение |
|---|---|
| Sequence type | DNA |
| Входной файл | `data/CNGA3_selected_cds.fasta` |
| Output format | ClustalW with character counts |
| Файл результата | `results/CNGA3_selected_clustalo.clustal` |

## Анализ консервативности

В выравнивании 11 CDS-последовательностей. Длина выравнивания составила **2289** колонок.

| Показатель | Значение |
|---|---:|
| Последовательностей | 11 |
| Длина выравнивания | 2289 колонок |
| Колонки без gap-ов | 1606 (70.2%) |
| Колонки с gap-ами | 683 (29.8%) |
| Полностью консервативные колонки | 806 (35.2%) |
| Колонки, где совпадают минимум 9 из 11 последовательностей | 1217 (53.2%) |

Выравнивание показывает достаточно сильную степень консервативности CDS `CNGA3`, если учитывать широкий набор групп: в анализ входят не только млекопитающие, но и птицы, пресмыкающиеся, амфибия, костная рыба и хрящевая рыба.

Наиболее консервативные блоки находятся в центральной части CDS. Например, в районе колонок выравнивания **1354-1477** видны длинные участки с большим количеством совпадений. Фрагмент человеческой последовательности в этом районе:

```text
GTTCTGATTTTTGCCACCATTGTGGGCAATGTGGGCTCCATGATCTCGAATATGAATGCC
TCACGGGCAGAGTTCCAGGCCAAGATTGATTCCATCAAGCAGTACATGCAGTTCCGCAAGGTCA
```

Больше всего gap-ов наблюдается в начале и конце выравнивания, а также в отдельном внутреннем участке примерно в колонках **372-509**. У *Nothoprocta perdicaria* выбран transcript variant X2, который даёт большой N-концевой gap относительно части других последовательностей. У *Callorhinchus milii* также есть крупный gap в ранней части.

Таким образом, большая часть CDS выравнивается достаточно ровно, но отдельные области содержат вставки, пропуски и накопленные точечные замены.

## Объединяющий таксон

Для определения общего таксона использовалась база **NCBI Taxonomy**.

Во всех lineage выбранных видов присутствуют:

```text
Chordata; Craniata; Vertebrata; Gnathostomata
```

Дальше виды расходятся на две крупные ветви:

```text
Gnathostomata
├── Chondrichthyes — хрящевые рыбы
│   └── Callorhinchus milii
└── Teleostomi — костные позвоночные
    ├── Megalops cyprinoides
    ├── Ambystoma mexicanum
    ├── Podarcis erhardii / Chelonia mydas
    ├── Aythya fuligula / Nothoprocta perdicaria
    └── Homo sapiens / Pan troglodytes / Lepus europaeus / Loxodonta africana
```

**Ближайший общий таксон:** *Gnathostomata*

**Русское название:** челюстноротые

**NCBI Taxonomy:** [taxid 7776](https://www.ncbi.nlm.nih.gov/Taxonomy/Browser/wwwtax.cgi?command=show&mode=node&id=7776&lvl=)

`Gnathostomata` объединяет позвоночных животных с челюстями. Более узкий таксон `Teleostomi` не подходит для всего набора, потому что *Callorhinchus milii* относится к хрящевым рыбам (`Chondrichthyes`), а не к костным позвоночным (`Teleostomi`).
