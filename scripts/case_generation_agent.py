import os
import yaml
import re

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SEED_CATALOG_PATH = os.path.join(BASE_DIR, 'config', 'case_catalogs', 'seed_catalogs.yaml')
CONSTRAINT_REFS_PATH = os.path.join(BASE_DIR, 'config', 'skills', 'constraint-score-review', 'references', 'constraint_refs.yaml')
OUTPUT_BASE_DIR = os.path.join(BASE_DIR, 'agent_bench', 'test_cases')

PUBLIC_CONSTRAINT_SEMANTICS = {
    'harmony_v2_state_management': {
        'key_decorators': ['ObservedV2', 'Trace'],
        'description': 'V2状态管理装饰器'
    },
    'harmony_avoid_magic_numbers': {
        'key_types': ['no_literal_number'],
        'description': '避免魔法数'
    },
    'harmony_spacing_size_use_tokens': {
        'key_names': ['Metrics', 'Spacing', 'Sizes', '$r'],
        'description': '使用Token常量'
    },
    'harmony_component_input_contract': {
        'key_decorators': ['Param'],
        'description': '组件输入接口'
    },
    'harmony_component_output_contract': {
        'key_decorators': ['Event'],
        'description': '组件输出接口'
    },
    'harmony_navigation': {
        'key_names': ['navPathStack', 'NavPathStack'],
        'key_types': ['no_import'],
        'description': '声明式导航'
    }
}

AST_RULE_MAPPING = {
    'uses_traceable_list_state': lambda p: [
        {'type': 'decorator', 'name': 'ObservedV2'},
        {'type': 'decorator', 'name': 'Trace'}
    ],
    'uses_observed_cart_item_state': lambda p: [
        {'type': 'decorator', 'name': 'ObservedV2'},
        {'type': 'decorator', 'name': 'Trace'}
    ],
    'uses_observed_trace_for_item_state': lambda p: [
        {'type': 'decorator', 'name': 'ObservedV2'},
        {'type': 'decorator', 'name': 'Trace'}
    ],
    'uses_granular_cart_item_state': lambda p: [
        {'type': 'decorator', 'name': 'ObservedV2'},
        {'type': 'decorator', 'name': 'Trace'}
    ],
    'avoids_full_page_refresh_on_quantity_change': lambda p: [
        {'type': 'decorator', 'name': 'ObservedV2'},
        {'type': 'decorator', 'name': 'Trace'}
    ],
    'uses_computed_cart_total': lambda p: [
        {'type': 'decorator', 'name': 'Computed'}
    ],
    'uses_computed_cart_summary': lambda p: [
        {'type': 'decorator', 'name': 'Computed'}
    ],
    'uses_computed_for_total_summary': lambda p: [
        {'type': 'decorator', 'name': 'Computed'}
    ],
    'refreshes_price_after_quantity_change': lambda p: [
        {'type': 'decorator', 'name': 'Trace'},
        {'type': 'decorator', 'name': 'Computed'}
    ],
    'handles_image_error_fallback': lambda p: [
        {'type': 'call', 'name': 'Image'},
        {'type': 'property', 'name': 'onError'}
    ],
    'preserves_article_body_on_image_error': lambda p: [
        {'type': 'call', 'name': 'Image'},
        {'type': 'property', 'name': 'onError'}
    ],
    'provides_placeholder_or_retry': lambda p: [
        {'type': 'property', 'name': 'onError'}
    ],
    'uses_lazy_list_data_source': lambda p: [
        {'type': 'call', 'name': 'LazyForEach'}
    ],
    'uses_lazy_feed_render': lambda p: [
        {'type': 'call', 'name': 'LazyForEach'}
    ],
    'avoids_eager_full_list_render': lambda p: [
        {'type': 'no_call', 'name': 'ForEach'}
    ],
    'avoids_eager_feed_render': lambda p: [
        {'type': 'no_call', 'name': 'ForEach'}
    ],
    'uses_stable_restaurant_keys': lambda p: [
        {'type': 'call', 'name': 'ForEach'},
        {'type': 'property_access', 'name': 'restaurant.id'}
    ],
    'uses_stable_list_keys': lambda p: [
        {'type': 'call', 'name': 'LazyForEach'},
        {'type': 'property_access', 'name': 'restaurant.id'}
    ],
    'uses_stable_coupon_keys': lambda p: [
        {'type': 'call', 'name': 'ForEach'},
        {'type': 'property_access', 'name': 'couponId'}
    ],
    'preserves_card_state_after_filter': lambda p: [
        {'type': 'decorator', 'name': 'Trace'},
        {'type': 'call', 'name': 'ForEach'}
    ],
    'keeps_image_failure_non_blocking': lambda p: [
        {'type': 'call', 'name': 'Image'},
        {'type': 'property', 'name': 'onError'}
    ],
    'has_coupon_center_entry_and_page': lambda p: [
        {'type': 'file_exists', 'name': p.get('target_file', 'entry/src/main/ets/pages/CouponCenter.ets')},
        {'type': 'navigation', 'target': p.get('target_page', 'pages/CouponCenter')}
    ],
    'renders_coupon_groups_and_filter_controls': lambda p: [
        {'type': 'call', 'name': 'Tabs'},
        {'type': 'call', 'name': 'ForEach'}
    ],
    'supports_coupon_detail_navigation': lambda p: [
        {'type': 'navigation', 'target': p.get('target_page', 'pages/CouponDetail')}
    ],
    'isolates_coupon_logic_in_new_page': lambda p: [
        {'type': 'file_exists', 'name': p.get('file', 'entry/src/main/ets/pages/CouponCenter.ets')}
    ],
    'keeps_profile_to_coupon_navigation_usable': lambda p: [
        {'type': 'navigation', 'target': p.get('target_page', 'pages/CouponCenter')}
    ],
    'uses_granular_coupon_filter_state': lambda p: [
        {'type': 'decorator', 'name': 'Local'},
        {'type': 'decorator', 'name': 'Trace'}
    ],
    'has_news_detail_page_and_navigation': lambda p: [
        {'type': 'file_exists', 'name': p.get('detail_file', 'entry/src/main/ets/pages/NewsDetailPage.ets')},
        {'type': 'navigation', 'target': p.get('target_page', 'pages/NewsDetailPage')}
    ],
    'renders_news_detail_core_sections': lambda p: [
        {'type': 'property_access', 'name': 'title'},
        {'type': 'property_access', 'name': 'content'}
    ],
    'supports_related_article_navigation': lambda p: [
        {'type': 'navigation', 'target': p.get('target_page', 'pages/NewsDetailPage')}
    ],
    'isolates_detail_logic_in_new_page': lambda p: [
        {'type': 'file_exists', 'name': p.get('file', 'entry/src/main/ets/pages/NewsDetailPage.ets')}
    ],
    'passes_article_params_between_pages': lambda p: [
        {'type': 'navigation_with_params'}
    ],
    'handles_detail_image_error_fallback': lambda p: [
        {'type': 'call', 'name': 'Image'},
        {'type': 'property', 'name': 'onError'}
    ],
    'uses_structured_related_article_data': lambda p: [
        {'type': 'call', 'name': 'ForEach'},
        {'type': 'variable', 'name': 'relatedArticles'}
    ],
    'has_cart_page_and_entry': lambda p: [
        {'type': 'file_exists', 'name': p.get('target_file', 'entry/src/main/ets/pages/CartPage.ets')},
        {'type': 'navigation', 'target': p.get('target_page', 'pages/CartPage')}
    ],
    'supports_cart_item_mutation_and_summary': lambda p: [
        {'type': 'decorator', 'name': 'Trace'},
        {'type': 'decorator', 'name': 'Computed'}
    ],
    'checkout_action_reflects_cart_state': lambda p: [
        {'type': 'decorator', 'name': 'Computed'},
        {'type': 'property', 'name': 'enabled'}
    ],
    'isolates_cart_logic_in_separate_page': lambda p: [
        {'type': 'file_exists', 'name': p.get('file', 'entry/src/main/ets/pages/CartPage.ets')}
    ],
    'updates_price_summary_reactively': lambda p: [
        {'type': 'decorator', 'name': 'Trace'},
        {'type': 'decorator', 'name': 'Computed'}
    ],
}

LLM_PROMPT_MAPPING = {
    'uses_traceable_list_state': '检查列表状态是否使用可追踪的状态管理装饰器',
    'uses_observed_cart_item_state': '检查购物车商品状态是否使用可追踪的状态管理',
    'uses_computed_cart_total': '检查总价是否使用派生状态计算',
    'uses_computed_cart_summary': '检查结算摘要是否使用派生状态计算',
    'handles_image_error_fallback': '检查图片组件是否处理加载失败回调',
    'uses_lazy_list_data_source': '检查长列表是否使用懒加载渲染',
    'uses_stable_restaurant_keys': '检查列表渲染是否使用稳定key',
    'uses_stable_list_keys': '检查懒加载列表是否使用稳定key',
    'uses_stable_coupon_keys': '检查列表渲染是否使用稳定key',
    'preserves_card_state_after_filter': '检查筛选后卡片状态是否保持一致',
    'has_coupon_center_entry_and_page': '检查是否有入口跳转到目标页面',
    'renders_coupon_groups_and_filter_controls': '检查页面是否展示分组和筛选控件',
    'supports_coupon_detail_navigation': '检查点击条目是否能跳转详情页',
    'supports_related_article_navigation': '检查点击推荐是否能跳转详情页',
    'uses_granular_coupon_filter_state': '检查筛选状态是否使用粒度化状态管理',
    'avoids_eager_full_list_render': '检查是否避免全量同步渲染',
    'avoids_eager_feed_render': '检查是否避免全量同步渲染',
    'avoids_full_page_refresh_on_quantity_change': '检查数量变化是否避免整页刷新',
    'uses_lazy_list_data_source': '检查是否使用懒加载数据源',
    'uses_lazy_feed_render': '检查是否使用懒加载渲染',
    'keeps_image_failure_non_blocking': '检查图片加载失败是否不影响滚动',
    'refreshes_price_after_quantity_change': '检查数量变化后价格是否实时刷新',
    'updates_price_summary_reactively': '检查价格摘要是否响应式更新',
    'checkout_action_reflects_cart_state': '检查结算按钮状态是否与购物车同步',
    'supports_cart_item_mutation_and_summary': '检查购物车是否支持数量调整和汇总',
    'has_news_detail_page_and_navigation': '检查是否有入口跳转到详情页',
    'has_cart_page_and_entry': '检查是否有入口跳转到购物车页',
    'renders_news_detail_core_sections': '检查详情页是否展示核心内容区域',
    'handles_detail_image_error_fallback': '检查详情页图片是否处理加载失败',
    'uses_structured_related_article_data': '检查推荐数据是否使用结构化列表',
    'passes_article_params_between_pages': '检查页面间是否正确传递数据',
    'provides_placeholder_or_retry': '检查图片加载失败是否有兜底展示',
    'isolates_coupon_logic_in_new_page': '检查逻辑是否隔离到独立页面',
    'isolates_detail_logic_in_new_page': '检查逻辑是否隔离到独立页面',
    'isolates_cart_logic_in_separate_page': '检查逻辑是否隔离到独立页面',
    'keeps_profile_to_coupon_navigation_usable': '检查导航链路是否可用',
}

def load_public_constraints():
    if not os.path.exists(CONSTRAINT_REFS_PATH):
        return {}
    with open(CONSTRAINT_REFS_PATH, 'r', encoding='utf-8') as f:
        return yaml.safe_load(f)

def get_public_constraints_for_scenario(scenario, constraint_refs):
    if not constraint_refs:
        return []
    defaults = constraint_refs.get('defaults', {})
    return defaults.get(scenario, [])

def is_constraint_duplicate_with_public(rule_name, ast_rules, all_public_semantics):
    for public_name, semantics in all_public_semantics.items():
        key_decorators = semantics.get('key_decorators', [])
        key_names = semantics.get('key_names', [])
        key_types = semantics.get('key_types', [])
        if key_decorators:
            matched_decorators = set()
            for ast_rule in ast_rules:
                if ast_rule.get('type') == 'decorator' and ast_rule.get('name') in key_decorators:
                    matched_decorators.add(ast_rule.get('name'))
            if set(key_decorators) == matched_decorators:
                return True, public_name
        if key_names:
            for ast_rule in ast_rules:
                name = ast_rule.get('name', '')
                if name in key_names or ast_rule.get('type') == 'call' and name == key_names[0]:
                    if len(ast_rules) == 1 or all(r.get('name') in key_names for r in ast_rules):
                        return True, public_name
        if key_types:
            for ast_rule in ast_rules:
                if ast_rule.get('type') in key_types:
                    return True, public_name
    return False, None

def get_next_case_number(scenario):
    scenario_dir = os.path.join(OUTPUT_BASE_DIR, scenario)
    if not os.path.exists(scenario_dir):
        return 1
    max_num = 0
    for name in os.listdir(scenario_dir):
        if re.match(r'^\d+$', name):
            max_num = max(max_num, int(name))
    return max_num + 1

def build_ast_rules(rule_name, params):
    if rule_name in AST_RULE_MAPPING:
        return AST_RULE_MAPPING[rule_name](params)
    return [{'type': 'rule_ref', 'name': rule_name}]

def build_llm_prompt(rule_name, params):
    if rule_name in LLM_PROMPT_MAPPING:
        return LLM_PROMPT_MAPPING[rule_name]
    return f"检查是否满足{rule_name}规则要求"

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
    constraint_refs = load_public_constraints()
    for scenario, seeds in catalogs.items():
        if not isinstance(seeds, list):
            continue
        public_constraints = get_public_constraints_for_scenario(scenario, constraint_refs)
        next_num = get_next_case_number(scenario)
        for seed in seeds:
            seed_id = seed.get('seed_id', 'unknown_id')
            case_num = str(next_num).zfill(3)
            target_dir = os.path.join(OUTPUT_BASE_DIR, scenario, case_num)
            case_file_path = os.path.join(target_dir, 'case.yaml')
            if os.path.exists(case_file_path):
                print(f"忽略已存在用例: {os.path.relpath(case_file_path, BASE_DIR)}")
                next_num += 1
                continue
            os.makedirs(target_dir, exist_ok=True)
            os.makedirs(os.path.join(target_dir, 'original_project'), exist_ok=True)
            raw_constraints = seed.get('constraints', [])
            formatted_constraints = []
            skipped_constraints = []
            for idx, c in enumerate(raw_constraints):
                params = c.get('params', {})
                target_file = params.get('file', params.get('source_file', 'entry/src/main/ets/pages/Index.ets'))
                rule_name = c.get('rule', '')
                ast_rules = build_ast_rules(rule_name, params)
                is_duplicate, public_name = is_constraint_duplicate_with_public(rule_name, ast_rules, PUBLIC_CONSTRAINT_SEMANTICS)
                if is_duplicate:
                    skipped_constraints.append({
                        'name': c.get('name'),
                        'rule': rule_name,
                        'public_constraint': public_name
                    })
                    continue
                llm_prompt = build_llm_prompt(rule_name, params)
                rule_entry = {'target': target_file}
                rule_entry['ast'] = ast_rules
                rule_entry['llm'] = llm_prompt
                constraint_id = f"HM-{scenario.upper()}-{str(len(formatted_constraints)+1).zfill(3)}"
                formatted_constraint = {
                    'id': constraint_id,
                    'name': c.get('name'),
                    'priority': c.get('priority', 'P1'),
                    'rules': [rule_entry]
                }
                formatted_constraints.append(formatted_constraint)
            if skipped_constraints:
                print(f"  过滤重复约束 {len(skipped_constraints)} 条:")
                for sc in skipped_constraints:
                    print(f"    - {sc['name']} (与公共约束 {sc['public_constraint']} 语义重复)")
            case_content = {
                'case': {
                    'id': seed_id,
                    'scenario': scenario,
                    'title': seed.get('title', ''),
                    'prompt': seed.get('input', ''),
                    'output_requirements': '请直接在当前工程中修改代码，并说明修改了哪些文件、主要修改内容及效果。'
                },
                'constraints': formatted_constraints
            }
            with open(case_file_path, 'w', encoding='utf-8') as out_f:
                yaml.dump(case_content, out_f, allow_unicode=True, sort_keys=False, default_flow_style=False)
            print(f"成功生成用例: {os.path.relpath(case_file_path, BASE_DIR)} ({len(formatted_constraints)} 条约束)")
            next_num += 1

if __name__ == '__main__':
    print("开始自动生成测试用例...")
    generate_cases()
    print("测试用例生成完毕！")