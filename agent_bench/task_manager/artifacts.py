"""任务产物上传。"""

from __future__ import annotations

import os
from typing import Any, Dict

try:
    from agent_bench.uploader import create_uploader
    HAS_STORAGE_UPLOADER = True
except ImportError:
    HAS_STORAGE_UPLOADER = False


AGC_BUCKET_NAME = "agent-bench-zc9kf"
AGC_PROJECT_CLIENT_CONFIG = {
    "type": "project_client_id",
    "developer_id": "2850086000413834717",
    "project_id": "101653523863784643",
    "client_id": "1946332846855610624",
    "client_secret": "81A2A59F2616F487A72FF83FE4604729ED206B08388D1B2770B102B1052CC07F",
    "configuration_version": "3.0",
    "region": "CN",
}


def _safe_object_segment(value: str) -> str:
    text = str(value or "").strip() or "unknown"
    return "".join(ch if ch.isalnum() or ch in ("-", "_") else "_" for ch in text)


class TaskArtifactUploader:
    def _create_agc_uploader(self):
        return create_uploader(
            provider="agcCloudStorage",
            **{
                "project_id": AGC_PROJECT_CLIENT_CONFIG["project_id"],
                "client_id": AGC_PROJECT_CLIENT_CONFIG["client_id"],
                "client_secret": AGC_PROJECT_CLIENT_CONFIG["client_secret"],
                "developer_id": AGC_PROJECT_CLIENT_CONFIG["developer_id"],
                "credential_type": AGC_PROJECT_CLIENT_CONFIG["type"],
                "region": AGC_PROJECT_CLIENT_CONFIG["region"],
                "bucket_name": AGC_BUCKET_NAME,
            },
        )

    def upload_output_code_dir(self, side_dir: str, execution_id: int, on_progress=None) -> str:
        if not HAS_STORAGE_UPLOADER:
            return ""
        if not os.path.isdir(side_dir):
            return ""
        try:
            object_name = f"cloud_api/output_code/execution_{execution_id}_output.zip"
            if on_progress:
                on_progress("log", {"level": "WARN", "message": f"[cloud_api] 开始上传输出代码: {object_name}"})
            uploader = self._create_agc_uploader()
            result = uploader.upload_directory(
                side_dir,
                object_name=object_name,
            )
            upload_url = result.get("download_url") or ""
            if on_progress:
                on_progress("log", {"level": "WARN", "message": f"[cloud_api] 输出代码上传完成: {upload_url}"})
            return upload_url
        except Exception as exc:
            if on_progress:
                on_progress("log", {"level": "ERROR", "message": f"[cloud_api] 输出代码上传失败: {exc}"})
            return ""

    def upload_diff_file(self, file_path: str, execution_id: int, on_progress=None) -> str:
        if not HAS_STORAGE_UPLOADER:
            return ""
        if not file_path or not os.path.isfile(file_path):
            return ""
        try:
            object_name = f"cloud_api/diff/execution_{execution_id}_changes.patch"
            if on_progress:
                on_progress("log", {"level": "WARN", "message": f"[cloud_api] 开始上传 diff 文件: {object_name}"})
            uploader = self._create_agc_uploader()
            result = uploader.upload_file(
                file_path=file_path,
                object_name=object_name,
                content_type="text/x-diff",
            )
            upload_url = result.get("download_url") or ""
            if on_progress:
                on_progress("log", {"level": "WARN", "message": f"[cloud_api] diff 文件上传完成: {upload_url}"})
            return upload_url
        except Exception as exc:
            if on_progress:
                on_progress("log", {"level": "ERROR", "message": f"[cloud_api] diff 文件上传失败: {exc}"})
            return ""

    def upload_checks_dir(self, checks_dir: str, execution_id: int, stage_name: str = "", on_progress=None) -> str:
        if not HAS_STORAGE_UPLOADER:
            return ""
        if not checks_dir or not os.path.isdir(checks_dir):
            return ""
        try:
            stage_segment = _safe_object_segment(stage_name)
            object_name = f"cloud_api/checks/execution_{execution_id}_{stage_segment}_checks.zip"
            if on_progress:
                on_progress("log", {"level": "WARN", "message": f"[cloud_api] 开始上传编译检查目录: {object_name}"})
            uploader = self._create_agc_uploader()
            result = uploader.upload_directory(
                checks_dir,
                object_name=object_name,
            )
            upload_url = result.get("download_url") or ""
            if on_progress:
                on_progress("log", {"level": "WARN", "message": f"[cloud_api] 编译检查目录上传完成: {upload_url}"})
            return upload_url
        except Exception as exc:
            if on_progress:
                on_progress("log", {"level": "ERROR", "message": f"[cloud_api] 编译检查目录上传失败: {exc}"})
            return ""
