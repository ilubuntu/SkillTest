import os
import yaml
import re

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SEED_CATALOG_PATH = os.path.join(BASE_DIR, 'config', 'case_catalogs', 'seed_catalogs.yaml')
OUTPUT_BASE_DIR = os.path.join(BASE_DIR, 'agent_bench', 'test_cases')

SCENARIO_OUTPUT_MAP = {
    'bug_fix': 'bug_fix',
    'performance': 'performance',
    'requirement': 'requirement',
    'project_gen': 'project_gen',
}

SCENARIO_PREFIX_MAP = {
    'bug_fix': 'BUGFIX',
    'performance': 'PERF',
    'requirement': 'REQ',
    'project_gen': 'GEN',
}


def get_next_case_number(scenario):
    scenario_dir = os.path.join(OUTPUT_BASE_DIR, scenario)
    if not os.path.exists(scenario_dir):
        return 1
    max_num = 0
    for name in os.listdir(scenario_dir):
        if re.match(r'^\d+$', name):
            max_num = max(max_num, int(name))
    return max_num + 1


def _build_output_requirements(scenario):
    if scenario == 'bug_fix':
        return '请直接在当前工程中修改代码并修复缺陷，工程需可编译，并在回复中说明根因、修复点和修改文件。'
    elif scenario == 'performance':
        return '请直接在当前工程中修改代码并完成优化，页面需可编译，并在回复中说明性能瓶颈和优化点。'
    elif scenario == 'requirement':
        return '请直接在当前工程中修改代码并完成需求实现，页面需可编译，保留现有首页，并在回复中说明新增页面、组件和导航链路。'
    return '请直接在当前工程中修改代码，并说明修改了哪些文件、主要修改内容及效果。'


def _format_rules(constraint):
    rules = constraint.get('rules')
    if rules and isinstance(rules, list):
        formatted = []
        for rule in rules:
            if not isinstance(rule, dict):
                continue
            entry = {'target': rule.get('target', '**/*.ets')}
            ast = rule.get('ast')
            if ast and isinstance(ast, list):
                entry['ast'] = ast
            llm = rule.get('llm')
            if llm and isinstance(llm, str) and llm.strip():
                entry['llm'] = llm.strip()
            formatted.append(entry)
        return formatted
    return []


def generate_cases():
    if not os.path.exists(SEED_CATALOG_PATH):
        print(f"错误: 找不到配置文件 {SEED_CATALOG_PATH}")
        return
    try:
        with open(SEED_CATALOG_PATH, 'r', encoding='utf-8') as f:
            catalogs = yaml.safe_load(f)
    except Exception as e:
        print(f"解析 YAML 文件失败: {e}")
        return
    if not catalogs:
        print("种子配置为空。")
        return

    total_generated = 0
    for scenario, seeds in catalogs.items():
        if not isinstance(seeds, list):
            continue
        next_num = get_next_case_number(scenario)
        prefix = SCENARIO_PREFIX_MAP.get(scenario, 'GEN')
        for seed in seeds:
            seed_id = seed.get('seed_id', 'unknown_id')
            case_num = str(next_num).zfill(3)
            target_dir = os.path.join(OUTPUT_BASE_DIR, scenario, case_num)
            case_file_path = os.path.join(target_dir, 'case.yaml')
            if os.path.exists(case_file_path):
                print(f"跳过已存在用例: {os.path.relpath(case_file_path, BASE_DIR)}")
                next_num += 1
                continue

            raw_constraints = seed.get('constraints', [])
            if not raw_constraints:
                print(f"  跳过无约束的 seed: {seed_id}")
                next_num += 1
                continue

            formatted_constraints = []
            for idx, c in enumerate(raw_constraints, start=1):
                if not isinstance(c, dict):
                    continue
                rules = _format_rules(c)
                if not rules:
                    continue
                scenario_prefix = SCENARIO_PREFIX_MAP.get(scenario, 'GEN')
                constraint_id = c.get('id') or f"HM-{scenario_prefix}-{case_num}-{idx:02d}"
                formatted_constraint = {
                    'id': constraint_id,
                    'name': c.get('name', ''),
                    'priority': c.get('priority', 'P1'),
                }
                desc = c.get('description') or c.get('name', '')
                if desc:
                    formatted_constraint['description'] = desc
                formatted_constraint['rules'] = rules
                formatted_constraints.append(formatted_constraint)

            if not formatted_constraints:
                print(f"  跳过无有效约束的 seed: {seed_id}")
                next_num += 1
                continue

            os.makedirs(target_dir, exist_ok=True)
            os.makedirs(os.path.join(target_dir, 'original_project'), exist_ok=True)

            case_content = {
                'case': {
                    'id': f"{scenario}_{case_num}",
                    'scenario': scenario,
                    'title': seed.get('title', ''),
                    'prompt': seed.get('input', ''),
                    'output_requirements': _build_output_requirements(scenario),
                },
                'constraints': formatted_constraints,
            }

            with open(case_file_path, 'w', encoding='utf-8') as out_f:
                yaml.dump(case_content, out_f, allow_unicode=True, sort_keys=False, default_flow_style=False)

            print(f"成功生成: {os.path.relpath(case_file_path, BASE_DIR)} ({len(formatted_constraints)} 条约束, seed={seed_id})")
            total_generated += 1
            next_num += 1

    print(f"\n生成完毕，共 {total_generated} 个用例。")


if __name__ == '__main__':
    print("开始自动生成测试用例...")
    generate_cases()