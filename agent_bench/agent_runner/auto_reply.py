# -*- coding: utf-8 -*-
"""OpenCode question 自动应答。

这个类专门处理 OpenCode SSE 中的 ``question.asked`` 事件。
职责刻意收紧在两件事上：
1. 从 SSE 负载中解析 question 的 requestID / callID / questions / options
2. 默认选择每个问题的第一个选项，并通过 HTTP reply 接口回传

为了避开 OpenCode 服务端 question 注册和 reply 请求之间的竞态，
自动应答不会在收到事件后立刻发送，而是延迟 5 秒并最多重试 3 次。
每次 reply 后优先相信 OpenCode 的 question.replied / completed 事件；
SSE 不稳定时再回查 session message，并只按同一个 callID 的最新状态判断。
"""

import json
import threading
import time
from typing import Callable


class OpenCodeQuestionAutoReply:
    """处理 OpenCode question 事件的自动应答器。"""

    REPLY_DELAY_SECONDS = 5
    MAX_REPLY_ATTEMPTS = 3
    STATE_CHECK_DELAY_SECONDS = 1

    def __init__(self,
                 http_client,
                 log_func: Callable[[str, str, str], None],
                 activity_func: Callable[[str], None],
                 reply_timeout: int = 30):
        self._http_client = http_client
        self._log = log_func
        self._mark_runtime_activity = activity_func
        self._reply_timeout = int(reply_timeout)
        self._scheduled_request_ids: set[str] = set()
        self._replied_request_ids: set[str] = set()
        self._completed_call_ids: set[str] = set()
        self._request_call_ids: dict[str, str] = {}
        self._generation = 0
        self._lock = threading.Lock()

    def reset(self):
        """在新任务开始前清空状态，避免串任务去重或旧线程误写新任务日志。"""
        with self._lock:
            self._scheduled_request_ids.clear()
            self._replied_request_ids.clear()
            self._completed_call_ids.clear()
            self._request_call_ids.clear()
            self._generation += 1

    def handle_sse_payload(self,
                           payload: dict,
                           session_id: str = "",
                           workspace_dir: str = "",
                           tag: str = "") -> bool:
        """尝试处理一条 SSE 负载。

        返回值表示这条 payload 是否是可识别的 question 事件；即使后续 reply 失败，
        只要事件识别成功也返回 True，方便上层区分“没命中事件”和“命中了但回复失败”。
        """
        self._mark_question_asked(payload)
        self._mark_question_replied(payload)
        self._mark_question_completed(self._extract_completed_question_call_id(payload))
        if not self._is_question_asked_payload(payload):
            return False

        call_id = self._extract_question_call_id(payload)
        questions = self._extract_question_items(payload)
        answers = self._build_question_answers(questions)
        if not answers:
            self._log("WARN", "检测到 question.asked，但未找到可用选项，无法自动选择第一个答案", tag)
            return True

        request_id = self._extract_question_request_id(payload)
        if not request_id:
            self._log("WARN", "检测到 question.asked，但未找到 requestID，无法自动应答", tag)
            return True

        summary = self._format_question_summary(questions, answers)
        return self._schedule_reply(
            request_id=request_id,
            call_id=call_id,
            session_id=session_id,
            workspace_dir=workspace_dir,
            answers=answers,
            summary=summary,
            tag=tag,
            discovery_label="检测到 question 问询",
        )

    def handle_message_payload(self,
                               payload: dict,
                               session_id: str = "",
                               workspace_dir: str = "",
                               tag: str = "") -> bool:
        """基于 session message 轮询做兜底，补查 pending question 的 requestID。"""
        self._mark_question_completed(self._extract_completed_question_call_id_from_message(payload))
        part = self._extract_running_question_part(payload)
        if not part:
            return False

        call_id = str(part.get("callID") or part.get("callId") or "").strip()
        questions = self._extract_questions_from_question_part(part)
        answers = self._build_question_answers(questions)
        if not answers:
            return False

        request_id = self._find_pending_request_id(
            session_id=session_id,
            workspace_dir=workspace_dir,
            call_id=call_id,
        )
        if not request_id:
            return False

        summary = self._format_question_summary(questions, answers)
        return self._schedule_reply(
            request_id=request_id,
            call_id=call_id,
            session_id=session_id,
            workspace_dir=workspace_dir,
            answers=answers,
            summary=summary,
            tag=tag,
            discovery_label="HTTP轮询发现 question，已通过 /question 补查到 requestID",
        )

    def _schedule_reply(self,
                        request_id: str,
                        call_id: str,
                        session_id: str,
                        workspace_dir: str,
                        answers: list[list[str]],
                        summary: str,
                        tag: str,
                        discovery_label: str) -> bool:
        with self._lock:
            if request_id in self._scheduled_request_ids or request_id in self._replied_request_ids:
                return True
            self._scheduled_request_ids.add(request_id)
            if request_id and call_id:
                self._request_call_ids[request_id] = call_id
            generation = self._generation

        self._log(
            "INFO",
            f"{discovery_label}，5秒后尝试自动选择第一个选项: {summary or self._first_answer_text(answers)}",
            tag,
        )
        threading.Thread(
            target=self._reply_with_retry,
            args=(generation, request_id, call_id, session_id, workspace_dir, answers, summary, tag),
            daemon=True,
        ).start()
        return True

    def _reply_with_retry(self,
                          generation: int,
                          request_id: str,
                          call_id: str,
                          session_id: str,
                          workspace_dir: str,
                          answers: list[list[str]],
                          summary: str,
                          tag: str):
        for attempt in range(1, self.MAX_REPLY_ATTEMPTS + 1):
            if not self._is_generation_active(generation):
                return
            time.sleep(self.REPLY_DELAY_SECONDS)
            if not self._is_generation_active(generation):
                return
            if self._is_question_done(request_id, call_id):
                self._finalize_success(request_id, session_id, answers, summary, tag)
                return

            self._log(
                "INFO",
                f"question 自动应答第{attempt}次准备发送: requestID={request_id}, answer={summary or self._first_answer_text(answers)}",
                tag,
            )
            result = self._http_client.reply_question(
                request_id=request_id,
                answers=answers,
                workspace_dir=workspace_dir,
                timeout=self._reply_timeout,
            )
            status_code = int(result.get("status_code") or 0)
            body = result.get("body")
            body_preview = self._preview_result_body(body)

            if not bool(result.get("ok")) or body is not True:
                self._log(
                    "WARN",
                    f"question 自动应答第{attempt}次失败: requestID={request_id}, status={status_code}, body={body_preview}",
                    tag,
                )
                continue

            time.sleep(self.STATE_CHECK_DELAY_SECONDS)
            if not self._is_generation_active(generation):
                return
            if self._is_question_done(request_id, call_id):
                self._finalize_success(request_id, session_id, answers, summary, tag)
                return

            if self._is_question_still_running(session_id=session_id, call_id=call_id):
                self._log(
                    "WARN",
                    f"question 自动应答第{attempt}次已被服务端接受，但 question 仍是 running，准备重试: requestID={request_id}",
                    tag,
                )
                continue

            with self._lock:
                self._replied_request_ids.add(request_id)
                self._scheduled_request_ids.discard(request_id)
            self._mark_runtime_activity(session_id=session_id)
            self._log("INFO", f"question 自动应答成功: {summary or self._first_answer_text(answers)}", tag)
            return

        with self._lock:
            self._scheduled_request_ids.discard(request_id)
        self._log("WARN", f"question 自动应答达到最大重试次数，仍未生效: requestID={request_id}", tag)

    def _is_generation_active(self, generation: int) -> bool:
        with self._lock:
            return self._generation == generation

    def _is_call_completed(self, call_id: str) -> bool:
        if not call_id:
            return False
        with self._lock:
            return call_id in self._completed_call_ids

    def _is_question_done(self, request_id: str, call_id: str) -> bool:
        with self._lock:
            return (
                bool(request_id and request_id in self._replied_request_ids)
                or bool(call_id and call_id in self._completed_call_ids)
            )

    def _mark_question_completed(self, call_id: str):
        if not call_id:
            return
        with self._lock:
            self._completed_call_ids.add(call_id)

    def _mark_question_asked(self, payload: dict):
        if not self._is_question_asked_payload(payload):
            return
        request_id = self._extract_question_request_id(payload)
        call_id = self._extract_question_call_id(payload)
        if not request_id or not call_id:
            return
        with self._lock:
            self._request_call_ids[request_id] = call_id

    def _mark_question_replied(self, payload: dict):
        request_id = self._extract_replied_question_request_id(payload)
        if not request_id:
            return
        with self._lock:
            self._replied_request_ids.add(request_id)
            call_id = self._request_call_ids.get(request_id, "")
            if call_id:
                self._completed_call_ids.add(call_id)

    def _finalize_success(self,
                          request_id: str,
                          session_id: str,
                          answers: list[list[str]],
                          summary: str,
                          tag: str):
        with self._lock:
            self._replied_request_ids.add(request_id)
            self._scheduled_request_ids.discard(request_id)
        self._mark_runtime_activity(session_id=session_id)
        self._log("INFO", f"question 自动应答成功: {summary or self._first_answer_text(answers)}", tag)

    def _is_question_asked_payload(self, payload: dict) -> bool:
        event_name = str(payload.get("event") or "").strip().lower()
        event_type = str(self._get_sse_event_type(payload) or "").strip().lower()
        return event_name == "question.asked" or event_type == "question.asked"

    @staticmethod
    def _walk_nested_values(value):
        if isinstance(value, dict):
            yield value
            for item in value.values():
                yield from OpenCodeQuestionAutoReply._walk_nested_values(item)
        elif isinstance(value, list):
            for item in value:
                yield from OpenCodeQuestionAutoReply._walk_nested_values(item)

    def _extract_sse_event_data(self, payload: dict):
        data = payload.get("data")
        if not isinstance(data, dict):
            return data
        nested_payload = data.get("payload")
        if isinstance(nested_payload, dict):
            return nested_payload
        return data

    def _get_sse_event_type(self, payload: dict) -> str:
        data = self._extract_sse_event_data(payload)
        if not isinstance(data, dict):
            return ""
        return str(data.get("type") or "").strip()

    def _extract_question_request_id(self, payload: dict) -> str:
        data = self._extract_sse_event_data(payload)
        for node in self._walk_nested_values(data):
            candidate = node.get("requestID") or node.get("requestId") or node.get("id")
            if candidate and "question" in json.dumps(node, ensure_ascii=False).lower():
                return str(candidate).strip()
        return ""

    def _extract_question_call_id(self, payload: dict) -> str:
        data = self._extract_sse_event_data(payload)
        for node in self._walk_nested_values(data):
            candidate = node.get("callID") or node.get("callId")
            if candidate and "question" in json.dumps(node, ensure_ascii=False).lower():
                return str(candidate).strip()
        return ""

    def _extract_completed_question_call_id(self, payload: dict) -> str:
        data = self._extract_sse_event_data(payload)
        if not isinstance(data, dict):
            return ""
        if str(data.get("type") or "").strip() != "message.part.updated":
            return ""
        props = data.get("properties") if isinstance(data.get("properties"), dict) else {}
        part = props.get("part") if isinstance(props.get("part"), dict) else {}
        if str(part.get("tool") or "").strip() != "question":
            return ""
        state = part.get("state") if isinstance(part.get("state"), dict) else {}
        if str(state.get("status") or "").strip().lower() != "completed":
            return ""
        return str(part.get("callID") or part.get("callId") or "").strip()

    def _extract_replied_question_request_id(self, payload: dict) -> str:
        data = self._extract_sse_event_data(payload)
        if not isinstance(data, dict):
            return ""
        if str(data.get("type") or "").strip() != "question.replied":
            return ""
        props = data.get("properties") if isinstance(data.get("properties"), dict) else {}
        return str(props.get("requestID") or props.get("requestId") or "").strip()

    def _extract_question_items(self, payload: dict) -> list[dict]:
        data = self._extract_sse_event_data(payload)
        for node in self._walk_nested_values(data):
            questions = node.get("questions")
            if isinstance(questions, list):
                return [item for item in questions if isinstance(item, dict)]
        return []

    def _extract_running_question_part(self, payload: dict) -> dict:
        if not isinstance(payload, dict):
            return {}
        for node in self._walk_nested_values(payload):
            if str(node.get("tool") or "").strip() != "question":
                continue
            state = node.get("state") if isinstance(node.get("state"), dict) else {}
            status = str(state.get("status") or "").strip().lower()
            if status == "running":
                return node
        return {}

    def _extract_completed_question_call_id_from_message(self, payload: dict) -> str:
        if not isinstance(payload, dict):
            return ""
        for node in self._walk_nested_values(payload):
            if str(node.get("tool") or "").strip() != "question":
                continue
            state = node.get("state") if isinstance(node.get("state"), dict) else {}
            if str(state.get("status") or "").strip().lower() != "completed":
                continue
            return str(node.get("callID") or node.get("callId") or "").strip()
        return ""

    @staticmethod
    def _extract_questions_from_question_part(part: dict) -> list[dict]:
        state = part.get("state") if isinstance(part.get("state"), dict) else {}
        state_input = state.get("input") if isinstance(state.get("input"), dict) else {}
        questions = state_input.get("questions")
        if isinstance(questions, list):
            return [item for item in questions if isinstance(item, dict)]
        return []

    def _find_pending_request_id(self,
                                 session_id: str,
                                 workspace_dir: str,
                                 call_id: str) -> str:
        try:
            payload = self._http_client.list_questions(workspace_dir=workspace_dir, timeout=10)
        except Exception:
            return ""

        items = payload if isinstance(payload, list) else []
        for item in items:
            if not isinstance(item, dict):
                continue
            if session_id and str(item.get("sessionID") or "").strip() != session_id:
                continue
            tool = item.get("tool") if isinstance(item.get("tool"), dict) else {}
            if call_id and str(tool.get("callID") or tool.get("callId") or "").strip() != call_id:
                continue
            request_id = str(item.get("id") or "").strip()
            if request_id:
                return request_id

        if session_id:
            for item in items:
                if not isinstance(item, dict):
                    continue
                if str(item.get("sessionID") or "").strip() != session_id:
                    continue
                request_id = str(item.get("id") or "").strip()
                if request_id:
                    return request_id
        return ""

    @staticmethod
    def _build_question_answers(questions: list[dict]) -> list[list[str]]:
        # OpenCode 的 reply 接口要求 answers 是二维数组：
        # - 外层：按 question 顺序排列
        # - 内层：该 question 选中的 option 列表
        #
        # 单选题默认选择第一个选项，因此这里为每个问题构造 [label]。
        answers: list[list[str]] = []
        for item in questions or []:
            options = item.get("options")
            if not isinstance(options, list) or not options:
                return []
            first = options[0] if isinstance(options[0], dict) else {}
            label = str(first.get("label") or first.get("value") or "").strip()
            if not label:
                return []
            answers.append([label])
        return answers

    @staticmethod
    def _format_question_summary(questions: list[dict], answers: list[list[str]]) -> str:
        if not questions or not answers:
            return ""
        pairs = []
        for index, item in enumerate(questions):
            question = str(item.get("question") or item.get("header") or f"问题{index + 1}").strip()
            selected = answers[index] if index < len(answers) else []
            answer = selected[0] if selected else ""
            if question or answer:
                pairs.append(f"{question} -> {answer}")
        return "；".join(pairs[:3])

    @staticmethod
    def _first_answer_text(answers: list[list[str]]) -> str:
        if not answers or not answers[0]:
            return ""
        return str(answers[0][0] or "").strip()

    @staticmethod
    def _preview_result_body(body) -> str:
        if body is True:
            return "true"
        if body is False:
            return "false"
        try:
            text = json.dumps(body, ensure_ascii=False)
        except Exception:
            text = str(body)
        return text if len(text) <= 200 else text[:200] + "..."

    def _is_question_still_running(self, session_id: str, call_id: str) -> bool:
        if not session_id or not call_id:
            return False
        try:
            payload = self._http_client.list_messages(session_id, limit=5, timeout=10)
        except Exception:
            return True

        latest_status = ""
        for node in self._walk_nested_values(payload):
            if str(node.get("tool") or "").strip() != "question":
                continue
            if str(node.get("callID") or node.get("callId") or "").strip() != call_id:
                continue
            state = node.get("state") if isinstance(node.get("state"), dict) else {}
            latest_status = str(state.get("status") or "").strip().lower()
        return latest_status == "running"
