# -*- coding: utf-8 -*-
"""内部评分系统检查器

根据 config/internal_rules.yaml 中的规则对代码进行检查
"""

import re
import yaml
from pathlib import Path
from typing import Dict, List, Any, Optional

BASE_DIR = Path(__file__).parent.parent
RULES_FILE = BASE_DIR / "config" / "internal_rules.yaml"


class InternalRuleChecker:
    def __init__(self, rules_file: Path = RULES_FILE):
        self.rules_file = rules_file
        self.rules = self._load_rules()
    
    def _load_rules(self) -> Dict[str, List[Dict]]:
        if not self.rules_file.exists():
            return {}
        
        with open(self.rules_file, "r", encoding="utf-8") as f:
            return yaml.safe_load(f) or {}
    
    def check_code(self, code: str) -> Dict[str, Any]:
        """对代码进行内部规则检查
        
        Args:
            code: 待检查的代码
            
        Returns:
            检查结果字典（即使code为空也返回正确结构）
        """
        results = {
            "compatibility": {"total": 0, "passed": 0, "rules": []},
            "ecosystem": {"total": 0, "passed": 0, "rules": []},
            "code_quality": {"total": 0, "passed": 0, "rules": []}
        }
        
        for category in ["compatibility", "ecosystem", "code_quality"]:
            rules = self.rules.get(category, [])
            if not rules:
                continue
            for rule in rules:
                result = self._check_single_rule(code, rule)
                results[category]["total"] += 1
                if result["passed"]:
                    results[category]["passed"] += 1
                results[category]["rules"].append(result)
        
        for category in results:
            total = results[category]["total"]
            passed = results[category]["passed"]
            results[category]["score"] = round(passed / total * 100, 1) if total > 0 else 100.0
        
        return results
    
    def _check_single_rule(self, code: str, rule: Dict) -> Dict:
        """检查单条规则
        
        Args:
            code: 待检查的代码
            rule: 规则定义
            
        Returns:
            单条规则检查结果
            如果代码不涉及该规则，默认认定为通过
        """
        name = rule.get("name", "")
        pattern = rule.get("pattern", "")
        pass_on_match = rule.get("pass_on_match", True)
        description = rule.get("description", "")
        level = rule.get("level", "MEDIUM")
        
        matches = []
        try:
            regex = re.compile(pattern, re.MULTILINE)
            matches = regex.findall(code)
            matched = len(matches) > 0
        except re.error:
            matched = False
        
        if not matched:
            passed = True
        elif pass_on_match:
            passed = matched
        else:
            passed = not matched
        
        return {
            "name": name,
            "level": level,
            "description": description,
            "pattern": pattern,
            "matched": matched,
            "pass_on_match": pass_on_match,
            "passed": passed,
            "matches": matches[:5] if matches else []
        }
    
    def get_summary(self, results: Dict[str, Any]) -> Dict[str, float]:
        """获取评分汇总（考虑规则级别权重）
        
        Returns:
            各维度得分和总分
        """
        level_weights = {"HIGH": 0.5, "MEDIUM": 0.3, "LOW": 0.2}
        
        def calc_weighted_score(rules: List[Dict]) -> float:
            if not rules:
                return 100.0
            total_weight = 0
            weighted_sum = 0
            for rule in rules:
                level = rule.get("level", "MEDIUM")
                weight = level_weights.get(level, 0.3)
                score = 100.0 if rule.get("passed") else 0.0
                weighted_sum += score * weight
                total_weight += weight
            return round(weighted_sum / total_weight, 1) if total_weight > 0 else 100.0
        
        compatibility_score = calc_weighted_score(results["compatibility"]["rules"])
        ecosystem_score = calc_weighted_score(results["ecosystem"]["rules"])
        code_quality_score = calc_weighted_score(results["code_quality"]["rules"])
        
        return {
            "compatibility_score": compatibility_score,
            "ecosystem_score": ecosystem_score,
            "code_quality_score": code_quality_score,
            "total_score": round(
                (compatibility_score + ecosystem_score + code_quality_score) / 3,
                1
            )
        }
    
    def get_level_weighted_score(self, results: Dict[str, Any]) -> float:
        """获取考虑规则级别的加权总分（供LLM Judge参考）
        
        Returns:
            0-100的分数
        """
        level_weights = {"HIGH": 0.5, "MEDIUM": 0.3, "LOW": 0.2}
        
        all_rules = (
            results.get("compatibility", {}).get("rules", []) +
            results.get("ecosystem", {}).get("rules", []) +
            results.get("code_quality", {}).get("rules", [])
        )
        
        if not all_rules:
            return 100.0
        
        total_weight = 0
        weighted_sum = 0
        for rule in all_rules:
            level = rule.get("level", "MEDIUM")
            weight = level_weights.get(level, 0.3)
            score = 100.0 if rule.get("passed") else 0.0
            weighted_sum += score * weight
            total_weight += weight
        
        return round(weighted_sum / total_weight, 1) if total_weight > 0 else 100.0


def check_output_file(file_path: str, rules_file: Path = RULES_FILE) -> Dict[str, Any]:
    """检查单个输出文件
    
    Args:
        file_path: 代码文件路径
        rules_file: 规则文件路径
        
    Returns:
        检查结果
    """
    if not Path(file_path).exists():
        return {"error": f"File not found: {file_path}"}
    
    with open(file_path, "r", encoding="utf-8") as f:
        code = f.read()
    
    checker = InternalRuleChecker(rules_file)
    results = checker.check_code(code)
    summary = checker.get_summary(results)
    
    return {
        "file": file_path,
        "results": results,
        "summary": summary
    }
