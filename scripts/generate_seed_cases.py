#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""Generate a batch of scenario-driven test cases."""

from __future__ import annotations

import argparse
import json
import os
import sys

REPO_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
if REPO_DIR not in sys.path:
    sys.path.insert(0, REPO_DIR)

from agent_bench.case_generation import generate_seed_case_batch


def main():
    parser = argparse.ArgumentParser(description="Generate scenario-driven seed cases")
    parser.add_argument(
        "--source-project-dir",
        default="empty_hos_project",
        help="Base project copied into each generated original_project",
    )
    parser.add_argument(
        "--scenarios",
        nargs="*",
        default=["requirement", "bug_fix", "performance"],
        help="Scenarios to generate",
    )
    parser.add_argument(
        "--limit-per-scenario",
        type=int,
        default=3,
        help="Limit per scenario, capped at 3",
    )
    parser.add_argument(
        "--single-scenario",
        default="",
        help="Generate a single case from catalog for one scenario",
    )
    parser.add_argument(
        "--seed-id",
        default="",
        help="Optional seed id used together with --single-scenario",
    )
    args = parser.parse_args()

    if args.single_scenario:
        from agent_bench.case_generation import generate_case_from_catalog

        results = [
            generate_case_from_catalog(
                scenario=args.single_scenario,
                source_project_dir=args.source_project_dir,
                seed_id=args.seed_id,
            )
        ]
    else:
        results = generate_seed_case_batch(
            source_project_dir=args.source_project_dir,
            scenarios=args.scenarios,
            limit_per_scenario=args.limit_per_scenario,
        )
    print(json.dumps(results, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
