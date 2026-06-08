#!/usr/bin/env python
from __future__ import annotations

import collections
import json
import re
import sys
from pathlib import Path


def graph_node_id(uid: str) -> str:
    return re.sub(r"[^A-Za-z0-9_]", "_", uid)


def dot_escape(value: str) -> str:
    return value.replace("\\", "\\\\").replace('"', '\\"')


def is_graph_task(node: dict) -> bool:
    return node.get("type", "").endswith(".GraphTask")


def is_graph_cluster_root(node: dict) -> bool:
    return node.get("type", "").endswith(".GraphClusterRoot")


def is_graph_cluster_end(node: dict) -> bool:
    return node.get("type", "").endswith(".GraphClusterEnd")


def task_type(node: dict) -> str:
    return node.get("task", {}).get("type", "")


def task_id(uid: str, nodes_by_uid: dict[str, dict]) -> str:
    node = nodes_by_uid[uid]
    task = node.get("task", {})
    return task.get("id") or uid.split(".")[-1]


def choice_nodes(nodes_by_uid: dict[str, dict]) -> set[str]:
    return {
        uid
        for uid, node in nodes_by_uid.items()
        if is_graph_task(node) and task_type(node).endswith(".If")
    }


def top_level_boundary_nodes(nodes_by_uid: dict[str, dict]) -> tuple[str | None, str | None]:
    start = next(
        (
            uid
            for uid, node in nodes_by_uid.items()
            if is_graph_cluster_root(node) and uid.startswith("root.root-")
        ),
        None,
    )
    end = next(
        (
            uid
            for uid, node in nodes_by_uid.items()
            if is_graph_cluster_end(node) and uid.startswith("root.end-")
        ),
        None,
    )
    return start, end


def relation_label(source_uid: str, relation: dict, choices: set[str]) -> str:
    value = relation.get("value", "")
    if source_uid in choices and value in {"then", "else"}:
        return value
    return ""


def add_implicit_if_else_edges(graph: dict, adjacency: dict[str, list[tuple[str, str]]]) -> None:
    for cluster in graph.get("clusters", []):
        cluster_info = cluster.get("cluster", {})
        task_node = cluster_info.get("taskNode", {})
        task_uid = task_node.get("uid")
        task = task_node.get("task", {})
        cluster_end = cluster.get("end")

        if not task_uid or not cluster_end:
            continue
        if not task.get("type", "").endswith(".If"):
            continue
        if task.get("else"):
            continue

        for target_uid, _ in adjacency.get(cluster_end, []):
            adjacency[task_uid].append((target_uid, "else"))


def compress_technical_edges(
    nodes_by_uid: dict[str, dict],
    adjacency: dict[str, list[tuple[str, str]]],
    relevant_uids: set[str],
) -> set[tuple[str, str, str]]:
    compressed_edges: set[tuple[str, str, str]] = set()

    for source_uid in relevant_uids:
        queue = collections.deque(adjacency.get(source_uid, []))
        seen: set[tuple[str, str]] = set()

        while queue:
            current_uid, label = queue.popleft()
            state = (current_uid, label)
            if state in seen:
                continue
            seen.add(state)

            if current_uid in relevant_uids and current_uid != source_uid:
                compressed_edges.add((source_uid, current_uid, label))
                continue

            for next_uid, next_label in adjacency.get(current_uid, []):
                queue.append((next_uid, label or next_label))

    return compressed_edges


def node_style(uid: str, nodes_by_uid: dict[str, dict], start_uid: str | None, end_uid: str | None) -> str:
    if uid == start_uid:
        return 'shape=circle, label="", width=0.28, fillcolor="#22c55e", color="#22c55e"'
    if uid == end_uid:
        return 'shape=doublecircle, label="", width=0.34, fillcolor="#38bdf8", color="#38bdf8"'

    label = task_id(uid, nodes_by_uid)
    node = nodes_by_uid[uid]

    if task_type(node).endswith(".If"):
        return f'shape=diamond, label="{dot_escape(label)}", fillcolor="#312e81", color="#818cf8", margin="0.10,0.06"'
    if label == "write_ok":
        return f'label="{dot_escape(label)}\\nOK!", fillcolor="#064e3b", color="#34d399"'
    if label == "write_not_ok":
        return f'label="{dot_escape(label)}\\nnot OK...", fillcolor="#7f1d1d", color="#f87171"'
    if label == "write_finished":
        return f'label="{dot_escape(label)}\\nFinished", fillcolor="#0f766e", color="#2dd4bf"'
    if label == "call_variants":
        return f'label="{dot_escape(label)}\\nfreebayes", fillcolor="#78350f", color="#f59e0b"'

    return f'label="{dot_escape(label)}"'


def write_dot(graph: dict, output_path: Path) -> None:
    nodes_by_uid = {node["uid"]: node for node in graph["nodes"]}
    choices = choice_nodes(nodes_by_uid)
    start_uid, end_uid = top_level_boundary_nodes(nodes_by_uid)

    relevant_uids = {uid for uid, node in nodes_by_uid.items() if is_graph_task(node)}
    if start_uid:
        relevant_uids.add(start_uid)
    if end_uid:
        relevant_uids.add(end_uid)

    adjacency: dict[str, list[tuple[str, str]]] = collections.defaultdict(list)
    for edge in graph["edges"]:
        source_uid = edge["source"]
        adjacency[source_uid].append(
            (
                edge["target"],
                relation_label(source_uid, edge.get("relation", {}), choices),
            )
        )

    add_implicit_if_else_edges(graph, adjacency)
    compressed_edges = compress_technical_edges(nodes_by_uid, adjacency, relevant_uids)

    task_order = {
        "prepare_dirs": 10,
        "download_sra": 20,
        "fastq_dump": 30,
        "compress_fastq": 40,
        "fastqc": 50,
        "index_reference": 60,
        "map_reads": 70,
        "sam_to_bam": 80,
        "flagstat": 90,
        "evaluate_mapping": 100,
        "branch_by_mapping_quality": 110,
        "write_ok": 120,
        "maybe_call_variants": 130,
        "index_reference_fasta": 140,
        "sort_bam": 150,
        "index_bam": 160,
        "call_variants": 170,
        "write_finished": 180,
        "write_not_ok": 190,
    }

    def sort_key(uid: str) -> tuple[int, str]:
        if uid == start_uid:
            return (0, uid)
        if uid == end_uid:
            return (999, uid)
        label = task_id(uid, nodes_by_uid)
        return (task_order.get(label, 500), label)

    with output_path.open("w", encoding="utf-8") as dot:
        dot.write("digraph kestra_mapping_quality_ont {\n")
        dot.write('  graph [rankdir=TB, bgcolor="#0f172a", pad="0.32", nodesep="0.48", ranksep="0.70", splines=polyline, outputorder=edgesfirst];\n')
        dot.write('  node [shape=rect, style="rounded,filled", color="#475569", penwidth=1.7, fillcolor="#1e293b", fontcolor="#f8fafc", fontname="DejaVu Sans", fontsize=18, margin="0.16,0.10"];\n')
        dot.write('  edge [color="#94a3b8", penwidth=1.8, arrowsize=0.75, fontname="DejaVu Sans", fontsize=14, fontcolor="#e2e8f0"];\n')

        for uid in sorted(relevant_uids, key=sort_key):
            dot.write(f"  {graph_node_id(uid)} [{node_style(uid, nodes_by_uid, start_uid, end_uid)}];\n")

        for source_uid, target_uid, label in sorted(
            compressed_edges,
            key=lambda edge: (sort_key(edge[0]), sort_key(edge[1]), edge[2]),
        ):
            attrs = f' [label="{dot_escape(label)}"]' if label else ""
            dot.write(f"  {graph_node_id(source_uid)} -> {graph_node_id(target_uid)}{attrs};\n")

        dot.write("}\n")


def main() -> int:
    if len(sys.argv) != 3:
        print(
            "Usage: render_kestra_graph_dot.py <kestra-graph.json> <output.dot>",
            file=sys.stderr,
        )
        return 2

    graph_path = Path(sys.argv[1])
    output_path = Path(sys.argv[2])
    with graph_path.open(encoding="utf-8") as source:
        graph = json.load(source)

    write_dot(graph, output_path)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
