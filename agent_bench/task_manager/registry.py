"""任务状态注册表。"""

from __future__ import annotations

from typing import Any, Dict, Optional

from agent_bench.task_manager.state import clone_task_state


class TaskRegistry:
    def __init__(self):
        self._states: Dict[int, Dict[str, Any]] = {}
        self._handles: Dict[int, Dict[str, Any]] = {}

    def create(self, execution_id: int, state: Dict[str, Any]):
        self._states[execution_id] = state
        self._handles.setdefault(execution_id, {})

    def get(self, execution_id: int) -> Optional[Dict[str, Any]]:
        return self._states.get(execution_id)

    def require(self, execution_id: int) -> Dict[str, Any]:
        return self._states[execution_id]

    def values(self):
        return self._states.values()

    def set_handle_metadata(self, execution_id: int, **metadata: Any):
        handle = self._handles.setdefault(execution_id, {})
        handle.update(metadata)

    def get_handle_metadata(self, execution_id: int) -> Dict[str, Any]:
        return dict(self._handles.get(execution_id) or {})

    def clear_handle_metadata(self, execution_id: int, *keys: str):
        handle = self._handles.get(execution_id)
        if not handle:
            return
        for key in keys:
            handle.pop(key, None)

    def running_execution_count(self) -> int:
        count = 0
        for handle in self._handles.values():
            worker_thread = handle.get("worker_thread")
            if worker_thread is not None and getattr(worker_thread, "is_alive", lambda: False)():
                count += 1
        return count

    def running_execution_ids(self) -> list[int]:
        running_ids = []
        for execution_id, handle in self._handles.items():
            worker_thread = handle.get("worker_thread")
            if worker_thread is not None and getattr(worker_thread, "is_alive", lambda: False)():
                running_ids.append(execution_id)
        return sorted(running_ids)

    def latest_execution_id(self) -> Optional[int]:
        if not self._states:
            return None
        return max(
            self._states.keys(),
            key=lambda execution_id: (
                str(self._states[execution_id].get("created_at") or ""),
                execution_id,
            ),
        )

    def snapshot(self, execution_id: Optional[int] = None) -> Optional[Dict[str, Any]]:
        target_execution_id = execution_id if execution_id is not None else self.latest_execution_id()
        if target_execution_id is None:
            return None
        state = self._states.get(target_execution_id)
        if not state:
            return None
        snapshot = clone_task_state(state)
        handle = self._handles.get(target_execution_id) or {}
        worker_thread = handle.get("worker_thread")
        status_thread = handle.get("status_thread")
        snapshot["handle"] = {
            "has_worker_thread": bool(worker_thread),
            "worker_alive": bool(worker_thread and getattr(worker_thread, "is_alive", lambda: False)()),
            "has_status_thread": bool(status_thread),
            "status_alive": bool(status_thread and getattr(status_thread, "is_alive", lambda: False)()),
            "queued": bool(handle.get("queued")),
            "queued_at": handle.get("queued_at"),
            "started_at": handle.get("started_at"),
            "finished_at": handle.get("finished_at"),
            "local_base_url": handle.get("local_base_url"),
        }
        return snapshot

    def snapshot_list(self) -> list[Dict[str, Any]]:
        states = [self.snapshot(execution_id) for execution_id in self._states.keys()]
        states = [item for item in states if item]
        states.sort(key=lambda item: (item.get("created_at") or "", item.get("execution_id") or 0), reverse=True)
        return states
