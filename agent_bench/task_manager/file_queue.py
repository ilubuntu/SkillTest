# -*- coding: utf-8 -*-
"""本地文件任务队列。

只维护 `pending/` 和 `running/` 两类文件：
- pending: 已接收但尚未进入执行线程，服务重启后会恢复。
- running: 当前进程已经开始执行，正常结束后删除；重启后只作为异常中断证据。
"""

from __future__ import annotations

import json
import os
import time
from typing import Any, Dict, List

from agent_bench.cloud_api.models import CloudExecutionStartRequest


class LocalTaskFileQueue:
    """用普通 JSON 文件保存任务调度状态，避免服务重启丢失 pending 任务。"""

    def __init__(self, root_dir: str):
        self.root_dir = root_dir
        self.pending_dir = os.path.join(root_dir, "pending")
        self.running_dir = os.path.join(root_dir, "running")
        os.makedirs(self.pending_dir, exist_ok=True)
        os.makedirs(self.running_dir, exist_ok=True)

    def _path(self, folder: str, execution_id: int) -> str:
        return os.path.join(folder, f"{int(execution_id)}.json")

    def _write_json_atomic(self, path: str, data: Dict[str, Any]):
        os.makedirs(os.path.dirname(path), exist_ok=True)
        tmp_path = f"{path}.tmp"
        with open(tmp_path, "w", encoding="utf-8") as file_obj:
            json.dump(data, file_obj, ensure_ascii=False, indent=2)
        os.replace(tmp_path, path)

    def write_pending(self, payload: CloudExecutionStartRequest, local_base_url: str):
        record = {
            "executionId": int(payload.executionId),
            "sequence": time.time_ns(),
            "receivedAtEpochMs": int(time.time() * 1000),
            "localBaseUrl": str(local_base_url or "").strip(),
            "payload": payload.model_dump(mode="json"),
        }
        self._write_json_atomic(self._path(self.pending_dir, payload.executionId), record)

    def mark_running(self, execution_id: int):
        pending_path = self._path(self.pending_dir, execution_id)
        running_path = self._path(self.running_dir, execution_id)
        if os.path.exists(pending_path):
            os.replace(pending_path, running_path)

    def remove_running(self, execution_id: int):
        running_path = self._path(self.running_dir, execution_id)
        if os.path.exists(running_path):
            os.remove(running_path)

    def remove_pending(self, execution_id: int) -> bool:
        pending_path = self._path(self.pending_dir, execution_id)
        if os.path.exists(pending_path):
            os.remove(pending_path)
            return True
        return False

    def pending_ids(self) -> List[int]:
        return self._list_ids(self.pending_dir)

    def running_ids(self) -> List[int]:
        return self._list_ids(self.running_dir)

    def load_pending_records(self) -> List[Dict[str, Any]]:
        records: List[Dict[str, Any]] = []
        for file_name in os.listdir(self.pending_dir):
            if not file_name.endswith(".json"):
                continue
            path = os.path.join(self.pending_dir, file_name)
            try:
                with open(path, "r", encoding="utf-8") as file_obj:
                    record = json.load(file_obj)
                record["_path"] = path
                records.append(record)
            except Exception:
                continue
        records.sort(key=lambda item: (
            int(item.get("sequence") or 0),
            int(item.get("receivedAtEpochMs") or 0),
            int(item.get("executionId") or 0),
        ))
        return records

    def _list_ids(self, folder: str) -> List[int]:
        ids: List[int] = []
        if not os.path.isdir(folder):
            return ids
        for file_name in os.listdir(folder):
            if not file_name.endswith(".json"):
                continue
            try:
                ids.append(int(os.path.splitext(file_name)[0]))
            except ValueError:
                continue
        return sorted(ids)
