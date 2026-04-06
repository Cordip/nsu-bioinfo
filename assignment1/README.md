# Домашнее задание 1: Парное выравнивание последовательностей

Гаврильев Максим Игоревич, группа 23216

## Фенотип: Ахроматопсия (Achromatopsia)

**OMIM:** [216900](https://omim.org/entry/216900) (ACHM2), [262300](https://omim.org/entry/262300) (ACHM3)

### Описание

Ахроматопсия — наследственное аутосомно-рецессивное заболевание сетчатки (~1:30 000). Колбочки не функционируют, что приводит к полной или частичной потере цветового зрения, светобоязни, сниженной остроте зрения и нистагму. Зрение в сумерках сохранено (палочки не затронуты).

Причина — мутации в генах фототрансдукционного каскада колбочек. Известно 6 генов: CNGA3 (~25%), CNGB3 (~50%), GNAT2, PDE6C, PDE6H, ATF6 (редко). В данной работе рассматриваем **CNGA3** и **CNGB3** — субъединицы CNG-канала колбочек, на которые приходится ~75-90% случаев.

### Ассоциированные гены

| Ген | Полное название | Локус |
|---|---|---|
| **CNGA3** | Cyclic Nucleotide Gated Channel Subunit Alpha 3 | 2q11.2 |
| **CNGB3** | Cyclic Nucleotide Gated Channel Subunit Beta 3 | 8q21.3 |

### Модельный организм: мышь (*Mus musculus*)

Строгие 1-к-1 ортологи: CNGA3 (человек) / Cnga3 (мышь), CNGB3 (человек) / Cngb3 (мышь).

## Последовательности

Использованы RefSeq mRNA из NCBI Nucleotide:

| Организм | Ген | NCBI RefSeq | Файл |
|---|---|---|---|
| *Homo sapiens* | CNGA3 | [NM_001298.3](https://www.ncbi.nlm.nih.gov/nuccore/NM_001298.3) | `data/human_CNGA3.fasta` |
| *Mus musculus* | Cnga3 | [NM_009918.3](https://www.ncbi.nlm.nih.gov/nuccore/NM_009918.3) | `data/mouse_Cnga3.fasta` |
| *Homo sapiens* | CNGB3 | [NM_019098.5](https://www.ncbi.nlm.nih.gov/nuccore/NM_019098.5) | `data/human_CNGB3.fasta` |
| *Mus musculus* | Cngb3 | [NM_013927.2](https://www.ncbi.nlm.nih.gov/nuccore/NM_013927.2) | `data/mouse_Cngb3.fasta` |

## Выравнивания

Каждая пара ортологов выравнивается тремя инструментами EMBOSS (онлайн-сервис EBI, матрица EDNAFULL):

- **Needle** — глобальное выравнивание, алгоритм Needleman-Wunsch (gap_open=10, gap_extend=0.5)
- **Water** — локальное выравнивание, алгоритм Smith-Waterman (gap_open=10, gap_extend=0.5)
- **Stretcher** — глобальное выравнивание, алгоритм Myers-Miller (gap_open=16, gap_extend=4)

### CNGA3 (human_CNGA3 vs mouse_Cnga3)

| Инструмент | Тип | Score | Identity | Gaps | Файл |
|---|---|---|---|---|---|
| Needle | глобальное | 8098 | 2400/4229 (56.8%) | 1348/4229 (31.9%) | `results/CNGA3_emboss_needle.txt` |
| Water | локальное | 8098 | 2401/3965 (60.6%) | 1081/3965 (27.3%) | `results/CNGA3_emboss_water.txt` |
| Stretcher | глобальное | 5388 | 2416/3768 (64.1%) | 426/3768 (11.3%) | `results/CNGA3_emboss_stretcher.txt` |

### CNGB3 (human_CNGB3 vs mouse_Cngb3)

| Инструмент | Тип | Score | Identity | Gaps | Файл |
|---|---|---|---|---|---|
| Needle | глобальное | 10265.5 | 3044/5022 (60.6%) | 1274/5022 (25.4%) | `results/CNGB3_emboss_needle.txt` |
| Water | локальное | 10266 | 3033/4818 (63.0%) | 1080/4818 (22.4%) | `results/CNGB3_emboss_water.txt` |
| Stretcher | глобальное | 6501 | 3005/4821 (62.3%) | 872/4821 (18.1%) | `results/CNGB3_emboss_stretcher.txt` |

## Оценка качества выравниваний

Примеры приведены для CNGA3 (mouse_Cnga3 vs human_CNGA3). Для CNGB3 картина аналогичная.

### 1. Участок с полным совпадением

Позиции в выводе отличаются (инструменты по-разному разбивают выравнивание на строки), но участок с полным совпадением один и тот же:

**Needle** (позиции 1106–1205 мыши):
```
mouse_Cnga3     1106 AGGATAGGGAACTTGGTCCTTTACACACTCATCATCATCCACTGGAATGC   1155
                     |||||.||||||||||||.|.||||..|||||||||||||||||||||||
human_CNGA3     1020 AGGATTGGGAACTTGGTCTTGTACATTCTCATCATCATCCACTGGAATGC   1069

mouse_Cnga3     1156 CTGCATCTACTTTGCCATTTCCAAGTTCATTGGTTTTGGGACAGACTCCT   1205
                     ||||||||||||||||||||||||||||||||||||||||||||||||||
human_CNGA3     1070 CTGCATCTACTTTGCCATTTCCAAGTTCATTGGTTTTGGGACAGACTCCT   1119
```

**Stretcher** (позиции 1087–1186 мыши):
```
mouse_Cnga3     1087 CAACTACCCCAACGTGTTCAGGATAGGGAACTTGGTCCTTTACACACTCA   1136
                     ||||||||||||..||||||||||.||||||||||||.|.||||..||||
human_CNGA3     1001 CAACTACCCCAATATGTTCAGGATTGGGAACTTGGTCTTGTACATTCTCA   1050

mouse_Cnga3     1137 TCATCATCCACTGGAATGCCTGCATCTACTTTGCCATTTCCAAGTTCATT   1186
                     ||||||||||||||||||||||||||||||||||||||||||||||||||
human_CNGA3     1051 TCATCATCCACTGGAATGCCTGCATCTACTTTGCCATTTCCAAGTTCATT   1100
```

**Water** (позиции 1105–1204 мыши):
```
mouse_Cnga3     1105 CAGGATAGGGAACTTGGTCCTTTACACACTCATCATCATCCACTGGAATG   1154
                     ||||||.||||||||||||.|.||||..||||||||||||||||||||||
human_CNGA3     1019 CAGGATTGGGAACTTGGTCTTGTACATTCTCATCATCATCCACTGGAATG   1068

mouse_Cnga3     1155 CCTGCATCTACTTTGCCATTTCCAAGTTCATTGGTTTTGGGACAGACTCC   1204
                     ||||||||||||||||||||||||||||||||||||||||||||||||||
human_CNGA3     1069 CCTGCATCTACTTTGCCATTTCCAAGTTCATTGGTTTTGGGACAGACTCC   1118
```

На таких участках выбор инструмента не влияет на результат.

### 2. Начало последовательностей: участок без сходства

У мыши есть ~250 нт в начале, которым нет соответствия у человека. Каждый инструмент обрабатывает это по-своему:

**Needle** — выравнивает всю длину, вставляет ~250 нт gap:
```
mouse_Cnga3        1 CTCAATAACTATGCACTCCCTCTTGTCTTCCACCCCCTTCTCCACACCCA     50
                                                                       
human_CNGA3        1 --------------------------------------------------      0
```

**Water** — пропускает этот участок целиком, начинает с позиции 250 мыши.

**Stretcher** — пытается «натянуть» выравнивание, находя единичные совпадения:
```
mouse_Cnga3        1 CTCAATAACTATGCACTCCCTCTTGTCTTCCACCCCCTTCTCCACACCCA     50
                     .           |.|||.|..||                           
human_CNGA3        1 G-----------GAACTGCGCCT---------------------------     12
```

### 3. Участок с длинным gap-ом

В районе позиции ~475 мыши Needle и Water вставляют ~100 нт gap:

**Needle:**
```
mouse_Cnga3      475 --------------------------------------------------    474
                                                                       
human_CNGA3      220 CCCACTCGTCAAGTGAGGAGACATCGTCAGTGCTGCAGCCGGGGATCGCC    269

mouse_Cnga3      475 ---------------------------GGGCAGGG---------------    482
                                                ||||||||               
human_CNGA3      270 ATGGAGACCAGAGGACTGGCTGACTCCGGGCAGGGCTCCTTCACCGGCCA    319

mouse_Cnga3      483 --------------TGTCACGCCTCATCATCTCGATTCGTGCGTGGGCCT    518
                                   ||||.|||||||||.|||.|.|.||...||||||..
human_CNGA3      320 GGGGATCGCCAGGCTGTCGCGCCTCATCTTCTTGCTGCGCAGGTGGGCTG    369
```

**Stretcher** на том же участке — вместо gap-а замены:
```
mouse_Cnga3      351 CCCCGGGGCTGAATGTGACCTGTGCAGAGATGGCAAAGGTGAACACCCAG    400
                     |.|......|||. |.|||.|...|||.|.||.....||.||.|.||..|
human_CNGA3      224 CTCGTCAAGTGAG-GAGACATCGTCAGTGCTGCAGCCGGGGATCGCCATG    272
```

Разница объясняется параметрами: у Stretcher gap penalty выше (16 vs 10), поэтому алгоритм предпочитает замены вместо длинных gap-ов.

### 4. Конец последовательностей

После ~2500 позиции все инструменты показывают много различий. Один и тот же район (~2570 мыши):

**Needle:**
```
mouse_Cnga3     2570 ----------------TGTTGTTAG-------------------------   2578
                                     ||||.||||                         
human_CNGA3     2511 TATGGAATCTGCAAGGTGTTTTTAGGCTTTTTAATCTGATTTTCTTATAA   2560

mouse_Cnga3     2579 --------TTATGTTGGCA-------------------------------   2589
                             ||||.|.|.||                               
human_CNGA3     2561 ATGAAAGATTATTTAGTCACCTTTCTCCTGTCCAACTTCACCACCACCTG   2610
```

**Water:**
```
mouse_Cnga3     2570 -----------------TGTTGTTAG------------------------   2578
                                      ||||.||||                        
human_CNGA3     2510 TTATGGAATCTGCAAGGTGTTTTTAGGCTTTTTAATCTGATTTTCTTATA   2559

mouse_Cnga3     2579 ---------TTATGTTGGCA------------------------------   2589
                              ||||.|.|.||                              
human_CNGA3     2560 AATGAAAGATTATTTAGTCACCTTTCTCCTGTCCAACTTCACCACCACCT   2609
```

**Stretcher:**
```
mouse_Cnga3     2427 CTTAGTTTCCTCTCCTATGAAATGGGACTCATGGCTGTCGGCCCCAG--A   2474
                     ||  |||||.||.||||..||||||||||..|.| |.||.|.|||||  |
human_CNGA3     2344 CT--GTTTCTTCACCTAAAAAATGGGACTTTTTG-TCTCAGTCCCAGTGA   2390

mouse_Cnga3     2475 AGTTCCAGACT--ATCATGAGGTG-GC--GAA-----------GGTTGTG   2508
                     |||.||||..|  ||..|||.||. ||  |||           ||..| |
human_CNGA3     2391 AGTGCCAGGTTTGATTGTGAAGTCCGCATGAAACACTGCACCAGGCAG-G   2439

mouse_Cnga3     2509 GCTTTGGAAAGCGTGAAGAGTTCCCAACCCAGTGTATAAGCATATGTGCA   2558
                     ||||||.||||.|..|.|..|.||||..|||. |||||.|.|.|.|||||
human_CNGA3     2440 GCTTTGCAAAGTGCAAGGTATCCCCAGTCCAA-GTATATGAAAACGTGCA   2488
```

Needle и Water дают практически одинаковый результат на этом участке (и в целом по всему выравниванию — score 8098 у обоих). Основное отличие между ними — Water пропускает начало без сходства (пример 2), а дальше выравнивания почти идентичны. Stretcher отличается заметнее: вместо gap-ов вставляет замены, выравнивание компактнее, но сходство на этом участке у всех трёх инструментов низкое.

### 5. Сводное сравнение

| | Needle | Water | Stretcher |
|---|---|---|---|
| Identity | 56.8% | 60.6% | 64.1% |
| Gaps | 31.9% | 27.3% | 11.3% |
| Начало (нет сходства) | длинные gaps | пропускает | вынужденные замены |
| Длинный gap в середине | gap ~100 нт | gap ~100 нт | замены вместо gap-а |
| Конец (мало сходства) | много gaps | обрезает | меньше gaps, больше замен |

### Вывод

- **Needle** выравнивает последовательности целиком, что даёт больше всего gap-ов и самый низкий identity%.
- **Water** отбрасывает участки без сходства на концах, поэтому identity% выше.
- **Stretcher** минимизирует gap-ы из-за более высокого gap penalty, что повышает identity%, но длинные gap-ы заменяются на серии несовпадений.

Более высокий identity% у Stretcher и Water — не признак лучшего качества, а следствие параметров и типа алгоритма. Все три инструмента показывают одинаковый результат на участках с высоким сходством, а различия проявляются на участках с низким сходством или отсутствием соответствия.
