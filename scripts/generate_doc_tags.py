#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""Generate FAQ and best-practice document tags for case generation."""

from __future__ import annotations

import os
import sys
from pathlib import Path
from typing import Any, Dict, Iterable, List

import yaml


REPO_DIR = Path(__file__).resolve().parents[1]
KNOWLEDGE_DIR = Path(r"E:\repo\harmony-doc\knowledge")
OUTPUT_DIR = REPO_DIR / "config" / "case_generation" / "doc_tags"


FAQ_EXCLUDE_KEYWORDS = [
    "DevEco",
    "签名",
    "证书",
    "安装HAP",
    "部署HAP",
    "模拟器",
    "设备",
    "hdc",
    "编译报错",
    "构建报错",
    "预览",
    "FileTransfer",
    "Studio",
    "私钥",
    "连接设备",
]

FAQ_DEVICE_DEPENDENT_KEYWORDS = [
    "相机",
    "音频",
    "蓝牙",
    "定位",
    "设备",
    "投屏",
    "摄像",
    "麦克风",
]

FAQ_UI_KEYWORDS = [
    "ForEach",
    "LazyForEach",
    "白屏",
    "图片",
    "Image",
    "Navigation",
    "列表",
    "页面",
    "UI",
    "aboutToReuse",
]

FAQ_CODE_FIXABLE_KEYWORDS = [
    "ForEach",
    "LazyForEach",
    "undefined",
    "TypeError",
    "华为账号",
    "白屏",
    "图片",
    "崩溃",
    "权限",
    "页面",
    "列表",
    "刷新",
]

FAQ_ISSUE_RULES = {
    "列表刷新异常": ["ForEach", "LazyForEach", "刷新", "列表"],
    "ForEach键值问题": ["ForEach", "键值", "key"],
    "undefined访问": ["undefined", "TypeError"],
    "页面白屏": ["白屏"],
    "图片加载失败": ["图片", "Image", "加载"],
    "权限拒绝异常": ["权限", "拒绝"],
    "账号授权异常": ["华为账号", "允许", "授权", "登录"],
    "崩溃": ["崩溃"],
}

FAQ_STARTER_RULES = {
    "list_state_refresh": ["ForEach", "LazyForEach", "列表", "刷新"],
    "detail_guard_empty_state": ["undefined", "TypeError", "白屏"],
    "image_fallback_feed": ["图片", "Image", "加载"],
    "permission_error_flow": ["权限", "拒绝"],
    "account_profile_page": ["华为账号", "允许", "授权", "登录"],
}

BEST_PRACTICE_EXCLUDE_KEYWORDS = [
    "音频",
    "视频",
    "Native",
    "C++",
    "低功耗",
    "GPU加速",
    "Web",
    "AVPlayer",
    "AVRecorder",
    "蓝牙",
    "相机硬件",
    "媒体",
]

BEST_PRACTICE_DEVICE_DEPENDENT_KEYWORDS = [
    "相机",
    "音频",
    "视频",
    "蓝牙",
    "LTPO",
    "GPS",
]

BEST_PRACTICE_UI_KEYWORDS = [
    "性能",
    "高性能",
    "长列表",
    "渲染",
    "状态",
    "冷启动",
    "界面",
    "布局",
    "懒加载",
    "丢帧",
]

BEST_PRACTICE_PERF_RULES = {
    "长列表": ["长列表", "懒加载", "List"],
    "状态刷新范围": ["状态刷新", "渲染范围", "状态", "ArkTS高性能编程"],
    "冷启动": ["冷启动", "启动", "首屏", "时延"],
    "界面渲染": ["界面渲染", "渲染", "丢帧", "性能优化", "高性能"],
}

BEST_PRACTICE_STARTER_RULES = {
    "long_list": ["长列表", "懒加载"],
    "state_scope": ["状态刷新", "渲染范围", "状态"],
    "cold_start_feed": ["冷启动", "启动", "首屏"],
}


def _has_any(text: str, keywords: Iterable[str]) -> bool:
    return any(keyword in text for keyword in keywords)


def _match_tags(text: str, rules: Dict[str, List[str]]) -> List[str]:
    tags: List[str] = []
    for tag, keywords in rules.items():
        if _has_any(text, keywords):
            tags.append(tag)
    return tags


def _build_faq_doc(path: Path) -> Dict[str, Any]:
    rel_path = path.relative_to(KNOWLEDGE_DIR).as_posix()
    name = path.stem
    issue_tags = _match_tags(name, FAQ_ISSUE_RULES)
    starter_types = _match_tags(name, FAQ_STARTER_RULES)
    code_fixable = _has_any(name, FAQ_CODE_FIXABLE_KEYWORDS)
    ui_related = _has_any(name, FAQ_UI_KEYWORDS)
    device_dependent = _has_any(name, FAQ_DEVICE_DEPENDENT_KEYWORDS)
    excluded = _has_any(name, FAQ_EXCLUDE_KEYWORDS)

    return {
        "title": name,
        "path": rel_path,
        "source": "FAQ",
        "labels": {
            "code_fixable": code_fixable,
            "ui_related": ui_related,
            "device_dependent": device_dependent,
            "exclude_from_case_generation": excluded,
            "issue_tags": issue_tags,
            "starter_project_types": starter_types,
        },
        "rationale": _faq_rationale(name, code_fixable, excluded, issue_tags),
    }


def _faq_rationale(name: str, code_fixable: bool, excluded: bool, issue_tags: List[str]) -> str:
    if excluded:
        return "更偏环境、设备或工具链问题，不适合作为标准代码修复题。"
    if code_fixable and issue_tags:
        return "标题指向明确的 UI/运行时问题，适合转换为可代码修复的 bug_fix 用例。"
    if code_fixable:
        return "具备转成代码修复题的潜力，但需要人工补充更明确的业务骨架。"
    return f"当前标题“{name}”更适合作为知识参考，不建议直接用于 bug_fix 出题。"


def _build_best_practice_doc(path: Path) -> Dict[str, Any]:
    rel_path = path.relative_to(KNOWLEDGE_DIR).as_posix()
    name = path.stem
    performance_tags = _match_tags(name, BEST_PRACTICE_PERF_RULES)
    starter_types = _match_tags(name, BEST_PRACTICE_STARTER_RULES)
    ui_related = _has_any(name, BEST_PRACTICE_UI_KEYWORDS)
    device_dependent = _has_any(name, BEST_PRACTICE_DEVICE_DEPENDENT_KEYWORDS)
    excluded = _has_any(name, BEST_PRACTICE_EXCLUDE_KEYWORDS)
    scenario_fit = bool(performance_tags) and not excluded

    return {
        "title": name,
        "path": rel_path,
        "source": "最佳实践",
        "labels": {
            "scenario_fit": scenario_fit,
            "ui_related": ui_related,
            "device_dependent": device_dependent,
            "exclude_from_case_generation": excluded,
            "performance_tags": performance_tags,
            "starter_project_types": starter_types,
        },
        "rationale": _best_practice_rationale(name, scenario_fit, excluded, performance_tags),
    }


def _best_practice_rationale(name: str, scenario_fit: bool, excluded: bool, performance_tags: List[str]) -> str:
    if excluded:
        return "内容更偏设备/底层/多媒体专项优化，不适合作为通用 ArkTS 页面性能评测题。"
    if scenario_fit and performance_tags:
        return "标题对应可在页面工程中稳定复现的性能问题，适合生成 performance 用例。"
    return f"当前标题“{name}”可保留为参考文档，但不建议作为首批性能题来源。"


def _dump_yaml(path: Path, data: Any):
    path.parent.mkdir(parents=True, exist_ok=True)
    with open(path, "w", encoding="utf-8") as f:
        yaml.safe_dump(data, f, allow_unicode=True, sort_keys=False)


def generate_doc_tags() -> Dict[str, Any]:
    faq_docs = sorted((KNOWLEDGE_DIR / "FAQ").glob("*.md"))
    best_practice_docs = sorted((KNOWLEDGE_DIR / "最佳实践").glob("*.md"))

    faq_entries = [_build_faq_doc(path) for path in faq_docs]
    best_practice_entries = [_build_best_practice_doc(path) for path in best_practice_docs]

    faq_output = {
        "category": "FAQ",
        "doc_count": len(faq_entries),
        "recommended_for_bug_fix": sum(
            1
            for item in faq_entries
            if item["labels"]["code_fixable"] and not item["labels"]["exclude_from_case_generation"]
        ),
        "docs": faq_entries,
    }
    best_practice_output = {
        "category": "最佳实践",
        "doc_count": len(best_practice_entries),
        "recommended_for_performance": sum(
            1
            for item in best_practice_entries
            if item["labels"]["scenario_fit"] and not item["labels"]["exclude_from_case_generation"]
        ),
        "docs": best_practice_entries,
    }

    _dump_yaml(OUTPUT_DIR / "faq_tags.yaml", faq_output)
    _dump_yaml(OUTPUT_DIR / "best_practice_tags.yaml", best_practice_output)

    return {
        "faq": {
            "count": faq_output["doc_count"],
            "recommended": faq_output["recommended_for_bug_fix"],
            "path": str(OUTPUT_DIR / "faq_tags.yaml"),
        },
        "best_practice": {
            "count": best_practice_output["doc_count"],
            "recommended": best_practice_output["recommended_for_performance"],
            "path": str(OUTPUT_DIR / "best_practice_tags.yaml"),
        },
    }


def main():
    summary = generate_doc_tags()
    print(yaml.safe_dump(summary, allow_unicode=True, sort_keys=False))


if __name__ == "__main__":
    if str(REPO_DIR) not in sys.path:
        sys.path.insert(0, str(REPO_DIR))
    main()
