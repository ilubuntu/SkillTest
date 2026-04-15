# -*- coding: utf-8 -*-
"""Scenario-driven local test-case generation."""

from __future__ import annotations

import os
import re
import shutil
from functools import lru_cache
from typing import Any, Dict, List, Optional

import yaml




BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
REPO_DIR = os.path.dirname(BASE_DIR)
TEST_CASES_DIR = os.path.join(BASE_DIR, "test_cases")
DEFAULT_SOURCE_PROJECT = "empty_hos_project"
SEED_CATALOGS_PATH = os.path.join(REPO_DIR, "config", "case_catalogs", "seed_catalogs.yaml")
MAX_GENERATED_CASES_PER_SCENARIO = 3


SCENARIO_KEYWORDS = {
    "project_gen": ("新工程", "项目生成", "工程生成", "从零", "新建项目", "搭建工程", "创建工程", "完整工程"),
    "performance": ("性能", "卡顿", "慢", "首屏", "重绘", "列表优化", "渲染优化", "耗时"),
    "bug_fix": ("修复", "报错", "异常", "闪退", "不显示", "不生效", "无法", "bug", "问题"),
    "requirement": ("开发", "实现", "新增", "搭建", "页面", "接入", "功能"),
}

SUPPORTED_SCENARIOS = ("requirement", "bug_fix", "performance", "project_gen")

PAGE_TAG_RULES = {
    "我的页面": ("我的页面", "我的页", "个人中心"),
    "商品详情页": ("商品详情", "详情页", "商品页"),
    "酒店预订页": ("酒店预订", "预订页面", "房型", "入住", "离店"),
    "列表页": ("列表", "清单"),
    "资讯首页": ("资讯首页", "资讯", "新闻首页", "资讯流"),
}

CAPABILITY_TAG_RULES = {
    "华为账号登录": ("华为账号", "账号登录", "一键登录", "登录"),
    "支付": ("支付", "下单", "购物车", "订单"),
    "定位": ("定位", "地图", "导航"),
}

ISSUE_TAG_RULES = {
    "列表刷新异常": ("列表刷新", "不刷新", "刷新异常", "界面不刷新"),
    "ForEach键值问题": ("ForEach", "LazyForEach", "key", "键值"),
    "undefined访问": ("undefined", "TypeError", "空数据", "非空断言"),
    "图片加载失败": ("图片加载失败", "在线图片", "网络图片", "image", "海报"),
}

PERFORMANCE_TAG_RULES = {
    "长列表": ("长列表", "超长列表", "列表滚动", "列表性能"),
    "状态刷新范围": ("整页重绘", "局部刷新", "状态刷新", "重绘"),
    "冷启动": ("首屏", "冷启动", "启动", "加载过慢"),
}

BUSINESS_TAG_RULES = {
    "政务": ("政务", "便民", "我的页面", "服务"),
    "商城": ("商城", "商品", "购物车", "下单"),
    "酒店": ("酒店", "房型", "预订", "入住"),
    "资讯": ("资讯", "新闻", "海报"),
    "任务": ("任务", "待办", "事项"),
}

STARTER_TYPE_RULES = {
    "account_profile_page": ("我的页面", "个人中心", "华为账号", "登录"),
    "mall_detail_trade": ("商城", "商品详情", "购物车", "下单"),
    "booking_form_page": ("酒店", "预订", "房型", "日期"),
    "list_state_refresh": ("列表", "ForEach", "刷新", "筛选"),
    "detail_guard_empty_state": ("详情", "undefined", "空数据", "白屏"),
    "image_fallback_feed": ("图片", "海报", "加载失败", "资讯"),
    "long_list": ("长列表", "超长列表", "滚动", "卡顿"),
    "state_scope": ("重绘", "局部刷新", "状态刷新", "我的页面"),
    "cold_start_feed": ("首屏", "冷启动", "资讯", "加载过慢"),
}

DEFAULT_SCORING_WEIGHTS = {
    "keyword": 3,
    "title": 2,
    "template": 2,
    "industry": 2,
    "page_tag": 4,
    "capability_tag": 5,
    "issue_tag": 5,
    "performance_tag": 5,
    "business_tag": 3,
    "starter_project_type": 2,
    "source_priority": 1,
}


class _CaseYamlDumper(yaml.SafeDumper):
    def increase_indent(self, flow=False, indentless=False):
        return super().increase_indent(flow, False)


def _represent_case_yaml_str(dumper: yaml.Dumper, data: str):
    style = "|" if "\n" in str(data) else None
    return dumper.represent_scalar("tag:yaml.org,2002:str", data, style=style)


_CaseYamlDumper.add_representer(str, _represent_case_yaml_str)


def _normalize_text(text: str) -> str:
    return str(text or "").strip()


def infer_scenario(text: str, preferred_scenario: str = "") -> str:
    preferred = _normalize_text(preferred_scenario).lower()
    if preferred in SUPPORTED_SCENARIOS:
        return preferred

    normalized = _normalize_text(text)
    for scenario in ("project_gen", "performance", "bug_fix", "requirement"):
        if any(keyword in normalized for keyword in SCENARIO_KEYWORDS[scenario]):
            return scenario
    return "requirement"


@lru_cache(maxsize=1)
def _load_seed_catalogs() -> Dict[str, List[Dict[str, Any]]]:
    result = {scenario: [] for scenario in SUPPORTED_SCENARIOS}
    if os.path.isfile(SEED_CATALOGS_PATH):
        with open(SEED_CATALOGS_PATH, "r", encoding="utf-8") as f:
            data = yaml.safe_load(f) or {}
        if isinstance(data, dict):
            result.update({
                scenario: [item for item in data.get(scenario, []) if isinstance(item, dict)]
                for scenario in SUPPORTED_SCENARIOS
            })
    return result


def _resolve_original_project_dir(source_project_dir: str) -> str:
    value = _normalize_text(source_project_dir) or DEFAULT_SOURCE_PROJECT
    if os.path.isabs(value):
        return value
    candidate = os.path.join(REPO_DIR, value)
    if os.path.isdir(candidate):
        return candidate
    raise FileNotFoundError(f"Original project directory not found: {value}")


def _next_case_number(scenario: str) -> str:
    scenario_dir = os.path.join(TEST_CASES_DIR, scenario)
    os.makedirs(scenario_dir, exist_ok=True)
    numbers: List[int] = []
    for name in os.listdir(scenario_dir):
        if re.fullmatch(r"\d{3}", name):
            numbers.append(int(name))
    return f"{(max(numbers) + 1) if numbers else 1:03d}"


def _score_seed(seed: Dict[str, Any], text: str) -> int:
    normalized = _normalize_text(text)
    score = 0
    intent_tags = _extract_intent_tags(normalized)
    weights = dict(DEFAULT_SCORING_WEIGHTS)
    custom_weights = seed.get("scoring_weights") or {}
    if isinstance(custom_weights, dict):
        for key, value in custom_weights.items():
            if key in weights:
                try:
                    weights[key] = int(value)
                except Exception:
                    pass
    for keyword in seed.get("keywords", []):
        token = _normalize_text(keyword)
        if token and token in normalized:
            score += weights["keyword"]
    for token in (
        seed.get("title"),
        seed.get("input"),
        seed.get("template", {}).get("name"),
        seed.get("template", {}).get("industry"),
    ):
        token_text = _normalize_text(token)
        if token_text and token_text in normalized:
            if token == seed.get("template", {}).get("name"):
                score += weights["template"]
            elif token == seed.get("template", {}).get("industry"):
                score += weights["industry"]
            else:
                score += weights["title"]
    selection_tags = seed.get("selection_tags") or {}
    score += _score_tag_group(
        intent_tags["page_tags"],
        selection_tags.get("page_tags"),
        weights["page_tag"],
    )
    score += _score_tag_group(
        intent_tags["capability_tags"],
        selection_tags.get("capability_tags"),
        weights["capability_tag"],
    )
    score += _score_tag_group(
        intent_tags["issue_tags"],
        selection_tags.get("issue_tags"),
        weights["issue_tag"],
    )
    score += _score_tag_group(
        intent_tags["performance_tags"],
        selection_tags.get("performance_tags"),
        weights["performance_tag"],
    )
    score += _score_tag_group(
        intent_tags["business_tags"],
        selection_tags.get("business_tags"),
        weights["business_tag"],
    )
    starter_type = _normalize_text(selection_tags.get("starter_project_type"))
    if starter_type and starter_type in intent_tags["starter_project_types"]:
        score += weights["starter_project_type"]
    source_priority = seed.get("source", {}).get("priority")
    if isinstance(source_priority, int):
        score += source_priority * weights["source_priority"]
    return score


def _match_rule_tags(text: str, rules: Dict[str, tuple[str, ...]]) -> List[str]:
    matches: List[str] = []
    for tag, keywords in rules.items():
        if any(keyword in text for keyword in keywords):
            matches.append(tag)
    return matches


def _extract_intent_tags(text: str) -> Dict[str, List[str]]:
    normalized = _normalize_text(text)
    return {
        "page_tags": _match_rule_tags(normalized, PAGE_TAG_RULES),
        "capability_tags": _match_rule_tags(normalized, CAPABILITY_TAG_RULES),
        "issue_tags": _match_rule_tags(normalized, ISSUE_TAG_RULES),
        "performance_tags": _match_rule_tags(normalized, PERFORMANCE_TAG_RULES),
        "business_tags": _match_rule_tags(normalized, BUSINESS_TAG_RULES),
        "starter_project_types": _match_rule_tags(normalized, STARTER_TYPE_RULES),
    }


def _score_tag_group(intent_tags: List[str], seed_tags: Any, weight: int) -> int:
    if not isinstance(seed_tags, list) or not seed_tags:
        return 0
    if not intent_tags:
        return 0
    return len(set(intent_tags) & set(str(item) for item in seed_tags)) * weight


def _select_seed_for_text(scenario: str, text: str) -> Optional[Dict[str, Any]]:
    seeds = _load_seed_catalogs().get(scenario, [])
    if not seeds:
        return None
    best_seed = seeds[0]
    best_score = -1
    for seed in seeds:
        score = _score_seed(seed, text)
        if score > best_score:
            best_seed = seed
            best_score = score
    return best_seed


def _seed_priority(seed: Dict[str, Any]) -> tuple[int, str]:
    source = seed.get("source") if isinstance(seed.get("source"), dict) else {}
    priority = source.get("priority")
    if not isinstance(priority, int):
        priority = 0
    return (-priority, str(seed.get("seed_id") or ""))


def _select_seed_from_catalog(scenario: str, seed_id: str = "") -> Optional[Dict[str, Any]]:
    seeds = _load_seed_catalogs().get(scenario, [])
    if not seeds:
        return None
    normalized_seed_id = _normalize_text(seed_id)
    if normalized_seed_id:
        for seed in seeds:
            if _normalize_text(seed.get("seed_id")) == normalized_seed_id:
                return seed
    return sorted(seeds, key=_seed_priority)[0]


def _write_text(path: str, content: str):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8", newline="\n") as f:
        f.write(content.rstrip() + "\n")


def _normalize_case_yaml_payload(payload: Dict[str, Any]) -> Dict[str, Any]:
    normalized = dict(payload or {})
    normalized.pop("context", None)

    case_meta = normalized.get("case")
    if isinstance(case_meta, dict):
        case_meta = dict(case_meta)
        output_requirements = case_meta.get("output_requirements")
        if isinstance(output_requirements, list):
            compact_items = []
            for item in output_requirements:
                text = str(item).strip()
                if not text:
                    continue
                compact_items.append(text.rstrip(".;??"))
            case_meta["output_requirements"] = " ; ".join(compact_items)
        normalized["case"] = case_meta

    return normalized


def _write_case_yaml(path: str, payload: Dict[str, Any]):
    payload = _normalize_case_yaml_payload(payload)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8", newline="\n") as f:
        yaml.dump(
            payload,
            f,
            Dumper=_CaseYamlDumper,
            allow_unicode=True,
            sort_keys=False,
            default_flow_style=False,
            width=4096,
        )


def _ensure_placeholder_resources(project_dir: str):
    string_json = os.path.join(project_dir, "AppScope", "resources", "base", "element", "string.json")
    if not os.path.isfile(string_json):
        _write_text(
            string_json,
            '{\n  "string": [\n    {\n      "name": "app_name",\n      "value": "SkillTest"\n    }\n  ]\n}\n',
        )


def _copy_template_from_existing_case(project_dir: str, scenario: str, case_number: str):
    """从现有用例目录复制模板工程"""
    template_case_dir = os.path.join(TEST_CASES_DIR, scenario, case_number)
    template_original_dir = os.path.join(template_case_dir, "original_project")
    if not os.path.isdir(template_original_dir):
        return False
    index_path = os.path.join(project_dir, "entry", "src", "main", "ets", "pages", "Index.ets")
    template_index_path = os.path.join(template_original_dir, "entry", "src", "main", "ets", "pages", "Index.ets")
    if os.path.isfile(template_index_path):
        try:
            with open(template_index_path, "r", encoding="utf-8") as f:
                content = f.read()
            _write_text(index_path, content)
            return True
        except Exception:
            return False
    return False


def _write_requirement_profile_coupon_extension(project_dir: str):
    index_path = os.path.join(project_dir, "entry", "src", "main", "ets", "pages", "Index.ets")
    _write_text(
        index_path,
        """
import { router } from '@kit.ArkUI'

@Entry
@Component
struct Index {
  private shortcuts: Array<{ title: string, subtitle: string }> = [
    { title: '我的订单', subtitle: '查看近30天订单' },
    { title: '地址管理', subtitle: '维护收货与服务地址' },
    { title: '客服中心', subtitle: '常见问题与联系入口' }
  ]

  build() {
    Column({ space: 18 }) {
      Column({ space: 8 }) {
        Text('个人中心')
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
        Text('当前页面已具备用户卡片和常用入口，请在此基础上续写新的权益能力。')
          .fontSize(14)
          .fontColor('#666666')
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)

      Column({ space: 10 }) {
        Text('Harmony 用户')
          .fontSize(22)
          .fontWeight(FontWeight.Medium)
        Text('会员等级：银卡会员')
          .fontSize(14)
          .fontColor('#666666')
        Text('当前积分 1280')
          .fontSize(14)
          .fontColor('#666666')
      }
      .width('100%')
      .padding(20)
      .backgroundColor('#FFFFFF')
      .borderRadius(20)

      Column({ space: 12 }) {
        ForEach(this.shortcuts, (item: { title: string, subtitle: string }) => {
          Row() {
            Column({ space: 4 }) {
              Text(item.title)
                .fontSize(16)
                .fontWeight(FontWeight.Medium)
              Text(item.subtitle)
                .fontSize(13)
                .fontColor('#888888')
            }
            .alignItems(HorizontalAlign.Start)
            Blank()
            Text('>')
              .fontSize(16)
              .fontColor('#999999')
          }
          .width('100%')
          .padding(16)
          .backgroundColor('#FFFFFF')
          .borderRadius(16)
        })
      }
      .width('100%')

      Button('新增优惠券中心能力')
        .width('100%')
        .height(52)
        .onClick(() => {
          router.pushUrl({ url: 'pages/CouponCenterPage' })
        })
    }
    .width('100%')
    .height('100%')
    .padding(20)
    .backgroundColor('#F5F7FA')
  }
}
""",
    )


def _write_requirement_news_detail_extension(project_dir: str):
    index_path = os.path.join(project_dir, "entry", "src", "main", "ets", "pages", "Index.ets")
    _write_text(
        index_path,
        """
import { router } from '@kit.ArkUI'

type NewsCard = {
  id: string,
  title: string,
  summary: string,
  source: string
}

@Entry
@Component
struct Index {
  private cards: NewsCard[] = [
    { id: 'news_1', title: 'HarmonyOS 新版本发布', summary: '带来更稳定的分布式体验与组件能力。', source: '官方资讯' },
    { id: 'news_2', title: '本地生活服务模板更新', summary: '模板仓新增多个高频业务场景骨架。', source: '行业快报' },
    { id: 'news_3', title: '开发者活动开启报名', summary: '围绕元服务与体验设计展开主题分享。', source: '社区动态' }
  ]

  build() {
    Column({ space: 16 }) {
      Text('今日资讯')
        .width('100%')
        .fontSize(28)
        .fontWeight(FontWeight.Bold)

      ForEach(this.cards, (item: NewsCard) => {
        Column({ space: 8 }) {
          Text(item.title)
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
          Text(item.summary)
            .fontSize(14)
            .fontColor('#666666')
            .lineHeight(21)
          Row() {
            Text(item.source)
              .fontSize(12)
              .fontColor('#999999')
            Blank()
            Text('阅读详情')
              .fontSize(13)
              .fontColor('#0A59F7')
          }
          .width('100%')
        }
        .width('100%')
        .padding(18)
        .backgroundColor('#FFFFFF')
        .borderRadius(18)
        .onClick(() => {
          router.pushUrl({ url: 'pages/ArticleDetailPage', params: item })
        })
      }, (item: NewsCard) => item.id)
    }
    .width('100%')
    .height('100%')
    .padding(20)
    .backgroundColor('#F5F7FA')
  }
}
""",
    )


def _write_requirement_shopping_cart_extension(project_dir: str):
    index_path = os.path.join(project_dir, "entry", "src", "main", "ets", "pages", "Index.ets")
    _write_text(
        index_path,
        """
import { router } from '@kit.ArkUI'

type ProductItem = {
  id: string,
  title: string,
  price: number,
  tag: string
}

@Entry
@Component
struct Index {
  private products: ProductItem[] = [
    { id: 'sku_1', title: '智能手表 Pro', price: 1299, tag: '新品' },
    { id: 'sku_2', title: '降噪耳机 Air', price: 899, tag: '热卖' },
    { id: 'sku_3', title: '便携音箱 Mini', price: 399, tag: '限时优惠' }
  ]

  build() {
    Column({ space: 16 }) {
      Row() {
        Text('精选商品')
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
        Blank()
        Button('查看购物车')
          .height(40)
          .onClick(() => {
            router.pushUrl({ url: 'pages/CartPage' })
          })
      }
      .width('100%')

      ForEach(this.products, (item: ProductItem) => {
        Row({ space: 12 }) {
          Column()
            .width(72)
            .height(72)
            .borderRadius(16)
            .backgroundColor('#E8ECF8')

          Column({ space: 6 }) {
            Text(item.title)
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
            Text('￥' + item.price.toString())
              .fontSize(15)
              .fontColor('#D9485F')
            Text(item.tag)
              .fontSize(12)
              .fontColor('#666666')
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Start)
        }
        .width('100%')
        .padding(16)
        .backgroundColor('#FFFFFF')
        .borderRadius(18)
      }, (item: ProductItem) => item.id)

      Text('当前首页已完成商品浏览，请在此基础上续写购物车与结算链路。')
        .width('100%')
        .fontSize(13)
        .fontColor('#888888')
        .textAlign(TextAlign.Center)
    }
    .width('100%')
    .height('100%')
    .padding(20)
    .backgroundColor('#F6F7FB')
  }
}
""",
    )


STARTER_KIND_TO_CASE_NUMBER = {
    "requirement_food_restaurant": ("requirement", "006"),
    "requirement_food_menu": ("requirement", "005"),
    "requirement_news_feed": ("requirement", "007"),
    "requirement_news_detail": ("requirement", "004"),
    "requirement_shopping_list": ("requirement", "003"),
    "requirement_shopping_cart": ("requirement", "002"),
    "bug_fix_food_list_refresh": ("bug_fix", "004"),
    "bug_fix_news_image": ("bug_fix", "005"),
    "bug_fix_shopping_cart": ("bug_fix", "006"),
    "performance_food_long_list": ("performance", "004"),
    "performance_news_feed": ("performance", "005"),
    "performance_shopping_cart": ("performance", "006"),
}


def _apply_starter_project(project_dir: str, starter_kind: str):
    _ensure_placeholder_resources(project_dir)
    normalized_kind = _normalize_text(starter_kind)
    if normalized_kind == "requirement_profile_coupon_extension":
        _write_requirement_profile_coupon_extension(project_dir)
        return
    if normalized_kind == "requirement_news_detail_extension":
        _write_requirement_news_detail_extension(project_dir)
        return
    if normalized_kind == "requirement_shopping_cart_extension":
        _write_requirement_shopping_cart_extension(project_dir)
        return
    if normalized_kind and normalized_kind in STARTER_KIND_TO_CASE_NUMBER:
        scenario, case_number = STARTER_KIND_TO_CASE_NUMBER[normalized_kind]
        success = _copy_template_from_existing_case(project_dir, scenario, case_number)
        if not success:
            pass


def _build_title(text: str, scenario: str, explicit_title: str = "") -> str:
    if _normalize_text(explicit_title):
        return explicit_title.strip()
    prefix_map = {
        "requirement": "需求实现",
        "bug_fix": "问题修复",
        "performance": "性能优化",
        "project_gen": "工程生成",
    }
    return f"{prefix_map.get(scenario, '测试用例')} - {text.strip()}"


def _build_output_requirements(scenario: str) -> str:
    if scenario == "project_gen":
        return "请直接在当前工程中生成或补齐项目结构，工程需可编译，并在回复中说明添加的模块、页面和关键配置文件。"
    if scenario == "bug_fix":
        return "请直接在当前工程中修改代码并修复缺陷，工程需可编译，并在回复中说明根因、修复点和修改文件。"
    if scenario == "performance":
        return "请直接在当前工程中修改代码并完成优化，页面需可编译，并在回复中说明性能瓶颈和优化点。"
    return "请直接在当前工程中修改代码并完成需求实现，页面需可编译，保留现有首页，并在回复中说明新增页面、组件和导航链路。"


def _build_prompt_from_seed(
    scenario: str,
    seed: Dict[str, Any],
    user_text: str,
    expected_output: str = "",
) -> str:
    user_text = _normalize_text(user_text or seed.get("input"))
    expected_output = _normalize_text(expected_output)

    if scenario == "requirement":
        new_scope = seed.get("new_requirement_scope") or []
        scope_text = "，" + "、".join(new_scope[:3]) if new_scope else ""
        prompt = f"这是一个增量开发需求。{user_text}{scope_text}。"
    elif scenario == "bug_fix":
        problem = _normalize_text(seed.get("problem_statement"))
        if problem:
            prompt = f"这是一个缺陷修复任务。{user_text}。{problem}。请修复缺陷，保持现有业务结构稳定。"
        else:
            prompt = f"这是一个缺陷修复任务。{user_text}。请修复缺陷，保持现有业务结构稳定。"
    elif scenario == "performance":
        problem = _normalize_text(seed.get("problem_statement"))
        goals = seed.get("optimization_goals") or []
        goal_text = "，" + "、".join(goals[:3]) if goals else ""
        if problem:
            prompt = f"这是一个性能优化需求。{user_text}。{problem}{goal_text}。请优化性能瓶颈。"
        else:
            prompt = f"这是一个性能优化需求。{user_text}{goal_text}。请优化性能瓶颈。"
    else:
        prompt = user_text

    if expected_output:
        prompt = f"{prompt}。{expected_output}"

    return prompt.strip()


def _normalize_constraint_name(description: str, fallback: str) -> str:
    text = _normalize_text(description)
    if not text:
        return fallback
    text = re.sub(r"\s+", "", text)
    text = re.sub(r"^[\-•·]+", "", text)
    text = text.rstrip("。；;：:")
    for delimiter in ("。", "；", ";"):
        if delimiter in text:
            text = text.split(delimiter, 1)[0].strip()
    if len(text) > 40 and "，" in text:
        first_clause = text.split("，", 1)[0].strip()
        if 6 <= len(first_clause) <= 40:
            text = first_clause
    if len(text) > 40:
        text = text[:40].rstrip("，,、 ")
    return text or fallback


def _build_constraint_id(prefix: str, case_id: str, index: int) -> str:
    case_no = ""
    if "_" in case_id:
        suffix = case_id.rsplit("_", 1)[-1]
        if re.fullmatch(r"\d{3}", suffix):
            case_no = suffix
    if case_no:
        return f"HM-{prefix}-{case_no}-{index:02d}"
    return f"HM-{prefix}-{index:02d}"


def _build_structured_constraints_from_seed(case_id: str,
                                            scenario: str,
                                            seed: Dict[str, Any],
                                            prefix: str,
                                            items: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
    result: List[Dict[str, Any]] = []
    for index, item in enumerate(items, start=1):
        if not isinstance(item, dict):
            continue

        fallback_name = f"{prefix}_constraint_{index:02d}"
        description = _normalize_text(item.get("description") or item.get("name"))
        constraint: Dict[str, Any] = {
            "id": _normalize_text(item.get("id")) or _build_constraint_id(prefix, case_id, index),
            "name": _normalize_constraint_name(
                str(item.get("name") or item.get("description") or ""),
                fallback_name,
            ),
            "description": description,
            "priority": _normalize_text(item.get("priority")) or ("P0" if index == 1 else "P1"),
        }
        rules = item.get("rules")
        if rules and isinstance(rules, list):
            constraint["rules"] = rules
        result.append(constraint)
    return result


def _build_constraints_from_seed(case_id: str, scenario: str, seed: Dict[str, Any]) -> List[Dict[str, Any]]:
    structured_constraints = seed.get("constraints") or []
    if scenario == "bug_fix":
        prefix = "BUGFIX"
    elif scenario == "performance":
        prefix = "PERF"
    elif scenario == "requirement":
        prefix = "REQ"
    else:
        prefix = "GEN"

    if structured_constraints and all(isinstance(item, dict) for item in structured_constraints):
        return _build_structured_constraints_from_seed(case_id, scenario, seed, prefix, structured_constraints)

    if scenario == "bug_fix":
        descriptions = structured_constraints or seed.get("fix_targets") or []
    elif scenario == "performance":
        descriptions = structured_constraints or seed.get("optimization_goals") or []
    elif scenario == "requirement":
        descriptions = (seed.get("new_requirement_scope") or []) + (seed.get("template_constraints") or []) + (seed.get("doc_rules") or [])
    else:
        descriptions = structured_constraints or []

    result: List[Dict[str, Any]] = []
    for index, item in enumerate(descriptions, start=1):
        fallback_name = f"{prefix}_constraint_{index:02d}"
        constraint_id = _build_constraint_id(prefix, case_id, index)
        
        constraint = {
            "id": constraint_id,
            "name": _normalize_constraint_name(str(item), fallback_name),
            "description": str(item),
            "priority": "P0" if index == 1 else "P1",
        }

        result.append(constraint)
    return result


def _build_context_from_seed(seed: Dict[str, Any], user_text: str, scenario: str) -> Dict[str, Any]:
    context: Dict[str, Any] = {
        "user_input": _normalize_text(user_text),
        "seed_id": seed.get("seed_id") or "",
        "source_type": scenario,
        "source": seed.get("source") or {},
        "selection_tags": seed.get("selection_tags") or {},
    }
    if scenario == "requirement":
        context["template"] = {
            "name": seed.get("template", {}).get("name", ""),
            "industry": seed.get("template", {}).get("industry", ""),
            "app_type": seed.get("template", {}).get("app_type", ""),
            "real_case_tags": seed.get("real_case_tags") or [],
            "system_capability_tags": seed.get("system_capability_tags") or [],
        }
        context["document_refs"] = seed.get("doc_refs") or []
    elif scenario == "bug_fix":
        context["faq_refs"] = seed.get("faq_refs") or []
    elif scenario == "performance":
        context["best_practice_refs"] = seed.get("best_practice_refs") or []
    return context


def _create_case_artifact(
    scenario: str,
    user_text: str,
    seed: Dict[str, Any],
    source_project_dir: str = "",
    title: str = "",
    expected_output: str = "",
) -> Dict[str, str]:
    case_no = _next_case_number(scenario)
    case_id = f"{scenario}_{case_no}"
    case_dir = os.path.join(TEST_CASES_DIR, scenario, case_no)
    original_project_target = os.path.join(case_dir, "original_project")
    os.makedirs(case_dir, exist_ok=True)

    source_dir = _resolve_original_project_dir(source_project_dir)
    if os.path.exists(original_project_target):
        shutil.rmtree(original_project_target)
    shutil.copytree(source_dir, original_project_target)
    _apply_starter_project(original_project_target, str(seed.get("starter_kind") or ""))

    generated_title = _build_title(user_text, scenario, explicit_title=title or str(seed.get("title") or ""))
    prompt = _build_prompt_from_seed(scenario, seed, user_text, expected_output=expected_output)

    case_spec = {
        "case": {
            "id": case_id,
            "scenario": scenario,
            "title": generated_title,
            "prompt": prompt,
            "output_requirements": _build_output_requirements(scenario),
        },
        "constraints": _build_constraints_from_seed(case_id, scenario, seed),
    }

    case_yaml_path = os.path.join(case_dir, "case.yaml")
    _write_case_yaml(case_yaml_path, case_spec)

    return {
        "scenario": scenario,
        "case_id": case_id,
        "case_dir": case_dir,
        "case_yaml_path": case_yaml_path,
        "original_project_dir": original_project_target,
        "title": generated_title,
        "selected_template": seed.get("template", {}).get("name", ""),
        "seed_id": seed.get("seed_id") or "",
    }


def _build_generic_project_gen_seed(text: str) -> Dict[str, Any]:
    normalized = _normalize_text(text)
    return {
        "seed_id": "project_gen_generic",
        "title": normalized or "工程生成任务",
        "input": normalized,
        "constraints": [
            "结果必须保留 HarmonyOS 基础工程结构，如 AppScope、entry、hvigorfile.ts 和 oh-package.json5。",
            "生成内容应包含可继续开发的业务页面或模块，而不是只输出单页代码片段。",
        ],
        "starter_kind": "",
    }


def generate_case_from_text(
    text: str,
    source_project_dir: str = "",
    preferred_scenario: str = "",
    title: str = "",
    expected_output: str = "",
) -> Dict[str, str]:
    normalized_text = _normalize_text(text)
    if not normalized_text:
        scenario = _normalize_text(preferred_scenario).lower()
        if scenario in {"requirement", "bug_fix", "performance"}:
            return generate_case_from_catalog(
                scenario=scenario,
                source_project_dir=source_project_dir,
                title=title,
                expected_output=expected_output,
            )
        raise ValueError("Missing input text; provide scenario or use batch generation")

    scenario = infer_scenario(normalized_text, preferred_scenario)
    if scenario == "project_gen":
        seed = _build_generic_project_gen_seed(normalized_text)
    else:
        seed = _select_seed_for_text(scenario, normalized_text)
        if not seed:
            raise ValueError(f"No seed catalog found for scenario: {scenario}")

    return _create_case_artifact(
        scenario=scenario,
        user_text=normalized_text,
        seed=seed,
        source_project_dir=source_project_dir,
        title=title,
        expected_output=expected_output,
    )


def generate_case_from_catalog(
    scenario: str,
    source_project_dir: str = "",
    seed_id: str = "",
    title: str = "",
    expected_output: str = "",
) -> Dict[str, str]:
    normalized_scenario = _normalize_text(scenario).lower()
    if normalized_scenario not in {"requirement", "bug_fix", "performance"}:
        raise ValueError(f"Unsupported catalog scenario: {scenario}")

    seed = _select_seed_from_catalog(normalized_scenario, seed_id=seed_id)
    if not seed:
        raise ValueError(f"No seed catalog found for scenario: {normalized_scenario}")

    user_text = _normalize_text(seed.get("input") or seed.get("title"))
    return _create_case_artifact(
        scenario=normalized_scenario,
        user_text=user_text,
        seed=seed,
        source_project_dir=source_project_dir,
        title=title,
        expected_output=expected_output,
    )


def generate_seed_case_batch(
    source_project_dir: str = "",
    scenarios: Optional[List[str]] = None,
    limit_per_scenario: Optional[int] = None,
) -> List[Dict[str, str]]:
    catalogs = _load_seed_catalogs()
    selected_scenarios = scenarios or ["requirement", "bug_fix", "performance"]
    results: List[Dict[str, str]] = []
    effective_limit = MAX_GENERATED_CASES_PER_SCENARIO
    if limit_per_scenario is not None:
        effective_limit = max(0, min(int(limit_per_scenario), MAX_GENERATED_CASES_PER_SCENARIO))

    for scenario in selected_scenarios:
        seeds = sorted(catalogs.get(scenario, []), key=_seed_priority)
        seeds = seeds[:effective_limit]
        for seed in seeds:
            user_text = _normalize_text(seed.get("input") or seed.get("title"))
            results.append(
                _create_case_artifact(
                    scenario=scenario,
                    user_text=user_text,
                    seed=seed,
                    source_project_dir=source_project_dir,
                )
            )
    return results
