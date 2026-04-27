# -*- coding: utf-8 -*-
"""HarmonyOS build-profile.json5 处理。"""

from __future__ import annotations

import os
import re
from typing import Optional


_KEY_PATTERN_CACHE: dict[str, re.Pattern[str]] = {}


def _key_pattern(key: str) -> re.Pattern[str]:
    pattern = _KEY_PATTERN_CACHE.get(key)
    if pattern is None:
        pattern = re.compile(rf'"{re.escape(key)}"\s*:')
        _KEY_PATTERN_CACHE[key] = pattern
    return pattern


def _skip_ws(text: str, index: int) -> int:
    while index < len(text) and text[index].isspace():
        index += 1
    return index


def _find_matching(text: str, start: int, open_char: str, close_char: str) -> int:
    depth = 0
    in_string = False
    escaped = False
    quote_char = ""
    for index in range(start, len(text)):
        char = text[index]
        if in_string:
            if escaped:
                escaped = False
                continue
            if char == "\\":
                escaped = True
                continue
            if char == quote_char:
                in_string = False
            continue
        if char in {'"', "'"}:
            in_string = True
            quote_char = char
            continue
        if char == open_char:
            depth += 1
            continue
        if char == close_char:
            depth -= 1
            if depth == 0:
                return index
    return -1


def _find_key_container_range(text: str, key: str, open_char: str, close_char: str, start: int = 0) -> Optional[tuple[int, int]]:
    match = _key_pattern(key).search(text, start)
    if not match:
        return None
    value_start = _skip_ws(text, match.end())
    if value_start >= len(text) or text[value_start] != open_char:
        return None
    value_end = _find_matching(text, value_start, open_char, close_char)
    if value_end < 0:
        return None
    return value_start, value_end


def sanitize_root_build_profile_signing_configs(project_dir: str) -> str:
    """清理根目录 build-profile.json5 中 app.signingConfigs。

    返回值：
    - "updated": 已清空为 []
    - "already_empty": 原本就是 []
    - "not_found": 文件不存在或未找到 app/signingConfigs
    """
    build_profile_path = os.path.join(project_dir, "build-profile.json5")
    if not os.path.isfile(build_profile_path):
        return "not_found"

    with open(build_profile_path, "r", encoding="utf-8") as f:
        text = f.read()

    app_range = _find_key_container_range(text, "app", "{", "}")
    if not app_range:
        return "not_found"
    app_start, app_end = app_range
    app_text = text[app_start: app_end + 1]

    signing_range = _find_key_container_range(app_text, "signingConfigs", "[", "]")
    if not signing_range:
        return "not_found"
    sign_start_rel, sign_end_rel = signing_range
    sign_start = app_start + sign_start_rel
    sign_end = app_start + sign_end_rel

    current_inner = text[sign_start + 1: sign_end]
    if current_inner.strip() == "":
        return "already_empty"

    updated = text[:sign_start] + "[]" + text[sign_end + 1:]
    with open(build_profile_path, "w", encoding="utf-8") as f:
        f.write(updated)
    return "updated"
