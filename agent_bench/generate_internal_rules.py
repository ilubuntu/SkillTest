# -*- coding: utf-8 -*-
"""生成用例的内部评分系统结果"""

import os
import sys
import yaml
from pathlib import Path
from typing import Dict, List, Any

BASE_DIR = Path(__file__).parent
sys.path.insert(0, str(BASE_DIR))

from agent_bench.evaluator.internal_rule_checker import InternalRuleChecker

RULES_FILE = BASE_DIR / "config" / "internal_rules.yaml"
RESULTS_DIR = BASE_DIR / "results"


def check_case_outputs(case_dir: Path, checker: InternalRuleChecker) -> Dict[str, Any]:
    baseline_file = case_dir / "baseline_output.txt"
    enhanced_file = case_dir / "enhanced_output.txt"
    
    result = {"case_id": case_dir.name}
    
    if baseline_file.exists():
        with open(baseline_file, "r", encoding="utf-8") as f:
            baseline_code = f.read()
        baseline_results = checker.check_code(baseline_code)
        baseline_summary = checker.get_summary(baseline_results)
        result["baseline"] = {
            "results": baseline_results,
            "summary": baseline_summary
        }
    
    if enhanced_file.exists():
        with open(enhanced_file, "r", encoding="utf-8") as f:
            enhanced_code = f.read()
        enhanced_results = checker.check_code(enhanced_code)
        enhanced_summary = checker.get_summary(enhanced_results)
        result["enhanced"] = {
            "results": enhanced_results,
            "summary": enhanced_summary
        }
    
    return result


def main():
    checker = InternalRuleChecker(RULES_FILE)
    
    if not RULES_FILE.exists():
        print(f"规则文件不存在: {RULES_FILE}")
        return
    
    results_by_run = {}
    
    for run_dir in sorted(RESULTS_DIR.iterdir(), key=lambda x: x.stat().st_mtime, reverse=True):
        if not run_dir.is_dir():
            continue
        
        cases_dir = run_dir / "cases"
        if not cases_dir.exists():
            continue
        
        run_results = []
        
        for case_dir in sorted(cases_dir.iterdir()):
            if not case_dir.is_dir():
                continue
            
            case_result = check_case_outputs(case_dir, checker)
            run_results.append(case_result)
            
            internal_result_file = case_dir / "internal_rules.yaml"
            with open(internal_result_file, "w", encoding="utf-8") as f:
                yaml.dump(case_result, f, allow_unicode=True, default_flow_style=False)
            
            print(f"生成: {internal_result_file}")
        
        results_by_run[run_dir.name] = run_results
    
    print(f"\n共处理 {len(results_by_run)} 个评测结果目录")


if __name__ == "__main__":
    main()
