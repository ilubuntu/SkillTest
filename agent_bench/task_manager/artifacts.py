"""任务产物上传。"""

from __future__ import annotations

import os
from typing import Any, Dict

try:
    from agent_bench.uploader import create_uploader
    HAS_STORAGE_UPLOADER = True
except ImportError:
    HAS_STORAGE_UPLOADER = False


AGC_BUCKET_NAME = "agent-bench-lpgvk"
AGC_PROJECT_CLIENT_CONFIG = {
    "type": "project_client_id",
    "developer_id": "900086000150224722",
    "project_id": "101653523863785276",
    "client_id": "1919775246739619200",
    "client_secret": "D1A9970837E38AAB4B7D4AFBDCAEC1B0D6511662C7026DAE1808298342F9192C",
    "configuration_version": "3.0",
    "region": "CN",
}


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
