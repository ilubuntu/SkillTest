#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Skill 评测 CLI - 可独立执行的评测工具

本脚本用于评测三种 Skill 的能力：
1. 工程生成 Skill (project_gen)
2. 可编译 Skill (compilable)
3. 性能优化 Skill (performance)

用法:
    # 自动从 Profile 的 scenarios 字段读取要跑的场景
    python cli.py --profile project_gen

    # 可选：通过 --cases 覆盖，只跑指定场景
    python cli.py --profile project_gen --cases project_gen

    # 跑所有场景
    python cli.py --profile all --cases all

    # 干跑模式
    python cli.py --profile project_gen --dry-run
"""

import argparse
import concurrent.futures
import json
import os
import sys
import threading
from typing import Optional
import time
import re
import urllib.request
import urllib.error
from datetime import datetime

DEFAULT_API_BASE = "http://localhost:4096"
TIMEOUT = 180
BASE_DIR = os.path.dirname(os.path.abspath(__file__))


class AgentRunner:
    """Agent 运行器 - 支持 HTTP API 方式"""

    def __init__(self, api_base: str = DEFAULT_API_BASE, model: str = "minimax/MiniMax-M2.7"):
        self.api_base = api_base
        self.model = model

    def _parse_model(self, model_str: str) -> dict:
        """解析模型字符串为 API 格式"""
        if "/" in model_str:
            provider, model_id = model_str.split("/", 1)
            provider_map = {
                "minimax": "minimax-cn-coding-plan",
            }
            provider_id = provider_map.get(provider, provider)
            return {"providerID": provider_id, "modelID": model_id}
        return {"providerID": "minimax-cn-coding-plan", "modelID": model_str}

    def run_http_api(self, prompt: str, timeout: int = TIMEOUT) -> str:
        """通过 HTTP API 调用 OpenCode 服务"""
        try:
            create_req = urllib.request.Request(
                f"{self.api_base}/session",
                data=json.dumps({}).encode("utf-8"),
                headers={"Content-Type": "application/json"},
                method="POST"
            )
            with urllib.request.urlopen(create_req, timeout=10) as response:
                session = json.loads(response.read().decode("utf-8"))
                session_id = session.get("id")
                if not session_id:
                    print(f"  [ERROR] Failed to create session", file=sys.stderr)
                    return ""

            message_payload = {
                "model": self._parse_model(self.model),
                "parts": [{"type": "text", "text": prompt}]
            }
            data = json.dumps(message_payload).encode("utf-8")
            req = urllib.request.Request(
                f"{self.api_base}/session/{session_id}/message",
                data=data,
                headers={"Content-Type": "application/json"},
                method="POST"
            )

            with urllib.request.urlopen(req, timeout=timeout) as response:
                result = json.loads(response.read().decode("utf-8"))
                parts = result.get("parts", [])
                for part in parts:
                    if part.get("type") == "text":
                        return part.get("text", "").strip()
                return ""

        except urllib.error.HTTPError as e:
            print(f"  [ERROR] HTTP API error: {e.code} - {e.reason}", file=sys.stderr)
            try:
                error_body = e.read().decode("utf-8")
                print(f"  [ERROR] Response: {error_body[:200]}", file=sys.stderr)
            except:
                pass
            return ""
        except urllib.error.URLError as e:
            print(f"  [ERROR] Cannot connect to OpenCode API at {self.api_base}", file=sys.stderr)
            print(f"  [ERROR] {e.reason}", file=sys.stderr)
            return ""
        except TimeoutError:
            print(f"  [ERROR] HTTP API timed out after {timeout}s", file=sys.stderr)
            return ""

    def run_baseline(self, prompt: str, code: str) -> str:
        """基线运行 - 纯 Agent 无增强"""
        full_prompt = f"""你是一个ArkTS开发者。请完成以下任务。

## 任务
{prompt}

## 代码
```typescript
{code}
```

## 要求
- 只输出完整的代码
- 不要解释过程
"""
        return self.run_http_api(full_prompt)

    def run_enhanced(self, prompt: str, code: str, skill_content: str) -> str:
        """增强运行 - 根据 skill 构建增强 prompt"""
        full_prompt = f"""你是一个ArkTS开发者。请参考以下最佳实践完成任务。

## 最佳实践参考
{skill_content}

## 任务
{prompt}

## 代码
```typescript
{code}
```

## 要求
- 只输出完整的代码
- 不要解释过程
"""
        return self.run_http_api(full_prompt)


class RuleChecker:
    """规则检查器"""

    @staticmethod
    def check(output: str, expected: dict) -> dict:
        details = []
        must_contain = expected.get("must_contain", [])
        must_not_contain = expected.get("must_not_contain", [])

        for keyword in must_contain:
            passed = keyword in output
            details.append({"rule": f"must_contain: {keyword}", "pass": passed})

        for keyword in must_not_contain:
            passed = keyword not in output
            details.append({"rule": f"must_not_contain: {keyword}", "pass": passed})

        total = len(details)
        if total == 0:
            return {"rule_score": 100.0, "details": details}

        passed_count = sum(1 for d in details if d["pass"])
        score = (passed_count / total) * 100

        return {"rule_score": score, "details": details}


class LLMJudge:
    """LLM 评分器"""

    DEFAULT_SCORE = 50

    def __init__(self, api_base: str = DEFAULT_API_BASE, model: str = "minimax/MiniMax-M2.7"):
        self.api_base = api_base
        self.model = model

    def _parse_model(self, model_str: str) -> dict:
        """解析模型字符串为 API 格式"""
        if "/" in model_str:
            provider, model_id = model_str.split("/", 1)
            provider_map = {
                "minimax": "minimax-cn-coding-plan",
            }
            provider_id = provider_map.get(provider, provider)
            return {"providerID": provider_id, "modelID": model_id}
        return {"providerID": "minimax-cn-coding-plan", "modelID": model_str}

    def judge(self, input_code: str, output_code: str, reference_code: str, rubric: list) -> dict:
        """对 Agent 输出进行 LLM 评分"""
        if not output_code.strip():
            return {
                "scores": [{"name": r["name"], "score": 0, "reason": "Agent无输出"} for r in rubric]
            }

        rubric_text = "\n".join(
            f"- {r['name']}（权重{r['weight']}%: {r['criteria']}）"
            for r in rubric
        )

        judge_prompt = f"""你是一个严格的代码评审专家，请评估以下ArkTS代码的修复质量。

## 原始代码（有bug）
```typescript
{input_code}
```

## 参考答案
```typescript
{reference_code}
```

## 待评估代码
```typescript
{output_code}
```

## 评分维度
{rubric_text}

请对每个维度打分（0-100），返回严格的JSON格式，不要包含其他内容：
{{"scores": [{{"name": "维度名", "score": 分数, "reason": "评分理由"}}]}}
"""

        try:
            result = self._call_api(judge_prompt)
            return self._parse_scores(result, rubric)
        except Exception as e:
            print(f"  [ERROR] LLM judge failed: {e}", file=sys.stderr)
            return {
                "scores": [{"name": r["name"], "score": self.DEFAULT_SCORE, "reason": "评分失败"} for r in rubric]
            }

    def _call_api(self, prompt: str) -> str:
        """调用 HTTP API"""
        try:
            create_req = urllib.request.Request(
                f"{self.api_base}/session",
                data=json.dumps({}).encode("utf-8"),
                headers={"Content-Type": "application/json"},
                method="POST"
            )
            with urllib.request.urlopen(create_req, timeout=10) as response:
                session = json.loads(response.read().decode("utf-8"))
                session_id = session.get("id")
                if not session_id:
                    return ""

            message_payload = {
                "model": self._parse_model(self.model),
                "parts": [{"type": "text", "text": prompt}]
            }
            data = json.dumps(message_payload).encode("utf-8")
            req = urllib.request.Request(
                f"{self.api_base}/session/{session_id}/message",
                data=data,
                headers={"Content-Type": "application/json"},
                method="POST"
            )

            with urllib.request.urlopen(req, timeout=60) as response:
                result = json.loads(response.read().decode("utf-8"))
                parts = result.get("parts", [])
                for part in parts:
                    if part.get("type") == "text":
                        return part.get("text", "").strip()
                return ""
        except Exception as e:
            raise e

    def _parse_scores(self, raw_output: str, rubric: list) -> dict:
        """解析 LLM 输出的 JSON 评分"""
        try:
            match = re.search(r'\{[\s\S]*"scores"[\s\S]*\}', raw_output)
            if match:
                data = json.loads(match.group())
                if "scores" in data:
                    return data
        except (json.JSONDecodeError, AttributeError):
            pass

        print(f"  [WARN] Failed to parse judge output, using default scores", file=sys.stderr)
        return {
            "scores": [{"name": r["name"], "score": self.DEFAULT_SCORE, "reason": "解析失败"} for r in rubric]
        }


class Reporter:
    """报告生成器"""

    @staticmethod
    def generate(results: list, output_dir: str, profile_name: str, scenario: str):
        """生成 JSON + Markdown 报告"""
        os.makedirs(output_dir, exist_ok=True)

        summary = Reporter._compute_summary(results)

        report_json = {
            "generated_at": datetime.now().isoformat(),
            "profile": profile_name,
            "scenario": scenario,
            "summary": summary,
            "cases": results,
        }

        json_path = os.path.join(output_dir, "report.json")
        with open(json_path, "w", encoding="utf-8") as f:
            json.dump(report_json, f, ensure_ascii=False, indent=2)

        md_path = os.path.join(output_dir, "report.md")
        with open(md_path, "w", encoding="utf-8") as f:
            f.write(Reporter._render_markdown(report_json))

        return json_path, md_path

    @staticmethod
    def _compute_summary(results: list) -> dict:
        """计算整体汇总"""
        if not results:
            return {}

        baseline_scores = [r["baseline_total"] for r in results]
        enhanced_scores = [r["enhanced_total"] for r in results]

        baseline_avg = sum(baseline_scores) / len(baseline_scores)
        enhanced_avg = sum(enhanced_scores) / len(enhanced_scores)

        pass_threshold = 60
        baseline_pass = sum(1 for s in baseline_scores if s >= pass_threshold)
        enhanced_pass = sum(1 for s in enhanced_scores if s >= pass_threshold)

        dimensions = {}
        for r in results:
            for dim_name, scores in r.get("dimension_scores", {}).items():
                if dim_name not in dimensions:
                    dimensions[dim_name] = {"baseline": [], "enhanced": []}
                dimensions[dim_name]["baseline"].append(scores["baseline"])
                dimensions[dim_name]["enhanced"].append(scores["enhanced"])

        dim_summary = {}
        for dim_name, vals in dimensions.items():
            b_avg = sum(vals["baseline"]) / len(vals["baseline"])
            e_avg = sum(vals["enhanced"]) / len(vals["enhanced"])
            dim_summary[dim_name] = {
                "baseline_avg": round(b_avg, 1),
                "enhanced_avg": round(e_avg, 1),
                "gain": round(e_avg - b_avg, 1),
            }

        return {
            "total_cases": len(results),
            "baseline_avg": round(baseline_avg, 1),
            "enhanced_avg": round(enhanced_avg, 1),
            "gain": round(enhanced_avg - baseline_avg, 1),
            "baseline_pass_rate": f"{baseline_pass}/{len(results)}",
            "enhanced_pass_rate": f"{enhanced_pass}/{len(results)}",
            "dimensions": dim_summary,
        }

    @staticmethod
    def _render_markdown(report: dict) -> str:
        """渲染 Markdown 格式报告"""
        s = report["summary"]
        if not s:
            return "# Skill 评测报告\n\n无数据\n"

        lines = [
            f"# Skill 评测报告",
            f"",
            f"- **生成时间**: {report['generated_at']}",
            f"- **Profile**: {report['profile']}",
            f"- **场景**: {report['scenario']}",
            f"",
            f"## 总览",
            f"",
            f"| 指标 | 基线 | 增强 | 增益 |",
            f"|------|------|------|------|",
            f"| 平均得分 | {s['baseline_avg']} | {s['enhanced_avg']} | +{s['gain']} |",
            f"| 通过率 (>=60) | {s['baseline_pass_rate']} | {s['enhanced_pass_rate']} | - |",
            f"",
        ]

        if s.get("dimensions"):
            lines.append("## 各维度对比")
            lines.append("")
            lines.append("| 维度 | 基线均分 | 增强均分 | 增益 |")
            lines.append("|------|---------|---------|------|")
            for dim_name, dim in s["dimensions"].items():
                lines.append(f"| {dim_name} | {dim['baseline_avg']} "
                             f"| {dim['enhanced_avg']} | +{dim['gain']} |")
            lines.append("")

        lines.append("## 用例明细")
        lines.append("")
        for r in report["cases"]:
            gain = r["enhanced_total"] - r["baseline_total"]
            flag = "+" if gain >= 0 else ""
            lines.append(f"### {r['case_id']}: {r['title']}")
            lines.append("")
            lines.append(f"| | 基线 | 增强 | 增益 |")
            lines.append(f"|--|------|------|------|")
            lines.append(f"| 规则得分 | {r['baseline_rule']} | {r['enhanced_rule']} "
                         f"| {flag}{round(r['enhanced_rule'] - r['baseline_rule'], 1)} |")

            for dim_name, scores in r.get("dimension_scores", {}).items():
                d_gain = scores["enhanced"] - scores["baseline"]
                d_flag = "+" if d_gain >= 0 else ""
                lines.append(f"| {dim_name} | {scores['baseline']} "
                             f"| {scores['enhanced']} | {d_flag}{d_gain} |")

            lines.append(f"| **总分** | **{r['baseline_total']}** "
                         f"| **{r['enhanced_total']}** | **{flag}{round(gain, 1)}** |")
            lines.append("")

        return "\n".join(lines)


def _check_api_available(api_base: str) -> bool:
    """检查 OpenCode API 是否可用"""
    try:
        req = urllib.request.Request(
            f"{api_base}/global/health",
            method="GET"
        )
        with urllib.request.urlopen(req, timeout=3) as response:
            raw = response.read().decode("utf-8")
            result = json.loads(raw)
            return result.get("healthy", False)
    except Exception:
        return False


def _find_opencode_port() -> Optional[str]:
    """查找当前运行的 OpenCode server 端口"""
    import socket

    common_ports = ["4096", "36903", "8080", "3000", "18792", "8000", "5000"]

    for port in common_ports:
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.settimeout(1)
        try:
            result = sock.connect_ex(("localhost", int(port)))
            sock.close()
            if result == 0:
                if _check_api_available(f"http://localhost:{port}"):
                    return port
        except:
            pass

    return None


def _ensure_opencode_server(timeout: int = 30):
    """确保 OpenCode API 服务可用，必要时自动启动"""
    import subprocess
    import platform

    print("[INFO] Searching for OpenCode server...")
    port = _find_opencode_port()
    if port:
        api_base = f"http://localhost:{port}"
        print(f"[INFO] Found OpenCode API at {api_base}")
        return api_base

    print("[INFO] No valid OpenCode server found, starting new server on port 4096...")

    system = platform.system()

    try:
        if system == "Windows":
            cmd = 'start /b cmd /c "opencode serve --port 4096"'
            print(f"[DEBUG] Running: {cmd}")
            os.system(cmd)
        else:
            subprocess.Popen(
                ["nohup", "opencode", "serve", "--port", "4096", "&"],
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
                stdin=subprocess.DEVNULL
            )

        print(f"[INFO] Server starting, waiting {timeout}s...")
        for i in range(timeout):
            time.sleep(1)
            if _check_api_available("http://localhost:4096"):
                print(f"[INFO] OpenCode server started at http://localhost:4096")
                return "http://localhost:4096"
            print(f"[INFO] Waiting... ({i+1}/{timeout})")

        print(f"[WARN] Server may not have started, continuing anyway...")

    except FileNotFoundError:
        print("[ERROR] opencode command not found. Please install opencode first.")
        print("[ERROR] Download from: https://opencode.ai")
        sys.exit(1)
    except Exception as e:
        print(f"[WARN] Failed to start opencode server: {e}")

    return "http://localhost:8080"


def load_yaml(file_path: str) -> dict:
    """加载 YAML 文件"""
    import yaml
    with open(file_path, "r", encoding="utf-8") as f:
        return yaml.safe_load(f)


def load_file(relative_path: str) -> str:
    """加载测试用例关联的代码文件"""
    path = os.path.join(BASE_DIR, relative_path)
    with open(path, "r", encoding="utf-8") as f:
        return f.read()


def load_test_cases(scenario: str) -> list:
    """加载指定场景目录下的所有测试用例"""
    cases_dir = os.path.join(BASE_DIR, "test_cases", scenario)
    if not os.path.isdir(cases_dir):
        print(f"[WARN] 场景目录不存在: {cases_dir}")
        return []

    cases = []
    for f in sorted(os.listdir(cases_dir)):
        if f.endswith(".yaml") or f.endswith(".yml"):
            filepath = os.path.join(cases_dir, f)
            case = load_yaml(filepath)
            cases.append(case)
    return cases


def resolve_scenarios(profile_name: str, cases_override: str = None,
                      profile_map: dict = None) -> list:
    """解析要运行的场景列表

    优先使用 --cases 覆盖参数；
    如果 --cases 为 "all"，返回所有已知场景；
    如果未指定 --cases，从 Profile YAML 的 scenarios 字段读取；
    最终 fallback 到 profile_name 本身作为场景名。
    """
    all_scenarios = list(profile_map.keys()) if profile_map else []

    # --cases 显式指定
    if cases_override:
        if cases_override == "all":
            return all_scenarios
        return [cases_override]

    # --profile all
    if profile_name == "all":
        return all_scenarios

    # 尝试从 Profile YAML 读取 scenarios
    profile_path = os.path.join(BASE_DIR, "profiles", f"{profile_name}.yaml")
    if os.path.exists(profile_path):
        profile_data = load_yaml(profile_path)
        scenarios = profile_data.get("scenarios", [])
        if scenarios:
            return scenarios

    # fallback: profile_name 即场景名
    return [profile_name]


def compute_total(rule_score: float, llm_scores: list, rubric: list,
                  rule_weight: float = 0.3, llm_weight: float = 0.7) -> float:
    """综合评分计算"""
    llm_weighted = 0
    total_weight = 0
    for rubric_item in rubric:
        name = rubric_item["name"]
        weight = rubric_item["weight"]
        score = next((s["score"] for s in llm_scores if s["name"] == name), 50)
        llm_weighted += score * weight
        total_weight += weight

    llm_avg = llm_weighted / total_weight if total_weight > 0 else 50
    return round(rule_weight * rule_score + llm_weight * llm_avg, 1)


def run_single_case(case: dict, scenario: str, skill_content: str,
                    agent_runner: AgentRunner, llm_judge_inst: LLMJudge,
                    dry_run: bool = False) -> dict:
    """执行单个测试用例（线程安全，日志收集后统一打印）"""
    case_id = case["id"]
    title = case["title"]
    prompt = case["input"]["prompt"]
    input_code = load_file(os.path.join("test_cases", scenario, case["input"]["code_file"]))
    reference_code = load_file(os.path.join("test_cases", scenario, case["expected"]["reference_file"]))
    rubric = case["expected"]["rubric"]

    logs = []

    # 基线运行
    if dry_run:
        baseline_output = "// dry run - no output"
        logs.append("  -> 基线运行... 跳过 (dry-run)")
    else:
        t0 = time.time()
        baseline_output = agent_runner.run_baseline(prompt, input_code)
        logs.append(f"  -> 基线运行... 完成 ({time.time() - t0:.0f}s)")

    # 增强运行
    if dry_run:
        enhanced_output = reference_code
        logs.append("  -> 增强运行... 跳过 (dry-run, 使用参考答案)")
    else:
        t0 = time.time()
        enhanced_output = agent_runner.run_enhanced(prompt, input_code, skill_content)
        logs.append(f"  -> 增强运行... 完成 ({time.time() - t0:.0f}s)")

    # 规则评分
    baseline_rule = RuleChecker.check(baseline_output, case["expected"])
    enhanced_rule = RuleChecker.check(enhanced_output, case["expected"])
    logs.append(f"  -> 规则检查... 基线={baseline_rule['rule_score']}, 增强={enhanced_rule['rule_score']}")

    # LLM 评分
    if dry_run:
        baseline_llm = {"scores": [{"name": r["name"], "score": 30, "reason": "dry-run"} for r in rubric]}
        enhanced_llm = {"scores": [{"name": r["name"], "score": 85, "reason": "dry-run"} for r in rubric]}
        logs.append("  -> LLM 评分... 跳过 (dry-run)")
    else:
        baseline_llm = llm_judge_inst.judge(input_code, baseline_output, reference_code, rubric)
        enhanced_llm = llm_judge_inst.judge(input_code, enhanced_output, reference_code, rubric)
        logs.append("  -> LLM 评分... 完成")

    # 汇总
    baseline_total = compute_total(baseline_rule["rule_score"], baseline_llm["scores"], rubric)
    enhanced_total = compute_total(enhanced_rule["rule_score"], enhanced_llm["scores"], rubric)

    dimension_scores = {}
    for r_item in rubric:
        name = r_item["name"]
        b_score = next((s["score"] for s in baseline_llm["scores"] if s["name"] == name), 50)
        e_score = next((s["score"] for s in enhanced_llm["scores"] if s["name"] == name), 50)
        dimension_scores[name] = {"baseline": b_score, "enhanced": e_score}

    gain = enhanced_total - baseline_total
    sign = "+" if gain >= 0 else ""
    logs.append(f"  -> 结果: 基线={baseline_total}, 增强={enhanced_total}, 增益={sign}{gain}")

    return {
        "case_id": case_id,
        "title": title,
        "scenario": case.get("scenario", scenario),
        "baseline_rule": baseline_rule["rule_score"],
        "enhanced_rule": enhanced_rule["rule_score"],
        "baseline_total": baseline_total,
        "enhanced_total": enhanced_total,
        "dimension_scores": dimension_scores,
        "_logs": logs,
    }


# 线程安全的打印锁，并行执行时防止输出交错
_print_lock = threading.Lock()


def _print_case_result(case_id: str, title: str, index: str, logs: list):
    """线程安全地打印单个用例的完整执行日志"""
    with _print_lock:
        print(f"\n[{index}] {case_id} - {title}")
        for line in logs:
            print(line)


def main():
    parser = argparse.ArgumentParser(
        description="Skill 评测系统 - 评测工程生成/可编译/性能优化 Skill",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
示例:
  %(prog)s --profile project_gen                              # 自动读取 Profile 中的 scenarios
  %(prog)s --profile project_gen --cases project_gen           # 覆盖：只跑指定场景
  %(prog)s --profile all --cases all                           # 跑所有
  %(prog)s --profile project_gen --dry-run                     # 干跑验证
        """,
    )
    parser.add_argument("--profile", required=True,
                        help="Profile 名称: project_gen, compilable, performance, all")
    parser.add_argument("--cases", default=None,
                        help="测试场景（可选），覆盖 Profile 中的 scenarios 配置。支持 all")
    parser.add_argument("--api-base", default=DEFAULT_API_BASE,
                        help="OpenCode API 服务地址")
    parser.add_argument("--model", default="minimax/MiniMax-M2.7",
                        help="使用的模型")
    parser.add_argument("--dry-run", action="store_true",
                        help="干跑模式：跳过 Agent 调用")
    parser.add_argument("--output-dir", default=None,
                        help="输出目录 (默认: results/<run_id>)")
    parser.add_argument("--run-id", default=None,
                        help="运行 ID (默认: 时间戳)")
    parser.add_argument("--max-workers", type=int, default=3,
                        help="场景内用例并行数 (默认: 3)")

    args = parser.parse_args()

    api_base = args.api_base
    if not args.dry_run:
        api_base = _ensure_opencode_server()

    run_id = args.run_id or datetime.now().strftime("%Y%m%d_%H%M%S")
    output_dir = args.output_dir or os.path.join(BASE_DIR, "results", run_id)
    max_workers = args.max_workers

    profile_map = {
        "project_gen": "skills/create-harmony-project.md",
        "compilable": "skills/compilable.md",
        "performance": "skills/performance.md",
        "bug_fix": "skills/bug_fix.md",
    }

    # 解析要运行的场景列表
    scenarios_to_run = resolve_scenarios(args.profile, args.cases, profile_map)

    os.makedirs(os.path.join(output_dir, "cases"), exist_ok=True)

    agent_runner = AgentRunner(api_base=api_base, model=args.model)
    llm_judge_inst = LLMJudge(api_base=api_base, model=args.model)

    all_results = []

    print("=" * 50)
    print("  Skill 评测系统")
    print(f"  Run ID:   {run_id}")
    print(f"  API Base: {api_base}")
    print(f"  Model:    {args.model}")
    print(f"  Scenarios: {', '.join(scenarios_to_run)}")
    print(f"  Parallel: {max_workers} workers")
    print(f"  Mode:     {'dry-run' if args.dry_run else '正式运行'}")
    print("=" * 50)

    for scenario in scenarios_to_run:
        skill_rel = profile_map.get(scenario)
        if skill_rel:
            skill_path = os.path.join(BASE_DIR, skill_rel)
        else:
            skill_path = None

        if not skill_path or not os.path.isfile(skill_path):
            if skill_path:
                print(f"[WARN] Skill 文件不存在: {skill_path}")
            skill_content = ""
        else:
            with open(skill_path, "r", encoding="utf-8") as f:
                skill_content = f.read()

        cases = load_test_cases(scenario)

        print(f"\n{'='*50}")
        print(f"  场景: {scenario}")
        print(f"  Skill: {profile_map.get(scenario, 'N/A')}")
        print(f"  用例数: {len(cases)}")
        print(f"{'='*50}")

        if not cases:
            print(f"没有找到测试用例，跳过")
            continue

        # 场景内用例并行执行
        futures = {}
        with concurrent.futures.ThreadPoolExecutor(max_workers=max_workers) as executor:
            for i, case in enumerate(cases):
                future = executor.submit(
                    run_single_case, case, scenario, skill_content,
                    agent_runner, llm_judge_inst,
                    dry_run=args.dry_run,
                )
                futures[future] = (i, case)

            for future in concurrent.futures.as_completed(futures):
                i, case = futures[future]
                try:
                    result = future.result()
                    index = f"{scenario} {i + 1}/{len(cases)}"
                    _print_case_result(result["case_id"], result["title"],
                                       index, result.pop("_logs", []))
                    all_results.append(result)

                    # 持久化单个用例结果
                    case_output_dir = os.path.join(output_dir, "cases", result["case_id"])
                    os.makedirs(case_output_dir, exist_ok=True)
                    with open(os.path.join(case_output_dir, "result.json"), "w", encoding="utf-8") as f:
                        json.dump(result, f, ensure_ascii=False, indent=2)

                except Exception as e:
                    print(f"\n[ERROR] {case['id']} 执行失败: {e}", file=sys.stderr)

    if all_results:
        scenarios_str = ",".join(scenarios_to_run)
        json_path, md_path = Reporter.generate(all_results, output_dir,
                                               args.profile, scenarios_str)

        print("\n" + "=" * 50)
        print("  评测完成!")
        print(f"  Run ID:        {run_id}")
        print(f"  JSON 报告:     {json_path}")
        print(f"  Markdown 报告: {md_path}")
        print("=" * 50)

        summary = Reporter._compute_summary(all_results)
        print(f"\n总结:")
        print(f"  总用例数: {summary['total_cases']}")
        print(f"  基线均分: {summary['baseline_avg']}")
        print(f"  增强均分: {summary['enhanced_avg']}")
        print(f"  增益:     +{summary['gain']}")
    else:
        print("\n没有运行任何测试用例")


if __name__ == "__main__":
    main()
