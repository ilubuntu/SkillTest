# -*- coding: utf-8 -*-
"""AGC 云存储上传工具。

参考文档：
- 获取 Access Token：
  https://developer.huawei.com/consumer/cn/doc/AppGallery-connect-References/agcapi-obtain-token-project-0000001477336048#section1466414833814
- 云存储文件上传：
  https://developer.huawei.com/consumer/cn/doc/AppGallery-connect-References/storage-restapi-uploadfile-0000001549318457
"""

import hashlib
import mimetypes
import os
import tarfile
import tempfile
import time
import uuid
import zipfile
import base64
from urllib.parse import quote
import urllib.error
import urllib.request
from typing import Dict, Optional

import json

from agent_bench.uploader.interface import ObjectUploader


class AgcCloudStorageClient:
    """AppGallery Connect 云存储通用上传客户端。"""

    TOKEN_URL = "https://connect-api.cloud.huawei.com/api/oauth2/v1/token"
    UPLOAD_HOSTS = {
        "CN": "https://ops-server-drcn.agcstorage.link",
        "RU": "https://ops-server-drru.agcstorage.link",
        "SG": "https://ops-server-dra.agcstorage.link",
        "DE": "https://ops-server-dre.agcstorage.link",
    }
    SHARE_DOWNLOAD_HOSTS = {
        "CN": "https://agc-storage-drcn.platform.dbankcloud.cn",
    }
    UPLOAD_BASE_URL = UPLOAD_HOSTS["CN"]
    DEFAULT_BUCKET_NAME = "agent-bench-lpgvk"

    def __init__(
        self,
        project_id: str,
        client_id: str,
        client_secret: str,
        developer_id: Optional[str] = None,
        credential_type: str = "project_client_id",
        region: str = "CN",
        bucket_name: str = DEFAULT_BUCKET_NAME,
        token_url: str = TOKEN_URL,
        upload_base_url: str = UPLOAD_BASE_URL,
        timeout: int = 300,
    ):
        if not project_id:
            raise ValueError("project_id 不能为空")
        if not client_id:
            raise ValueError("client_id 不能为空")
        if not client_secret:
            raise ValueError("client_secret 不能为空")
        if not bucket_name:
            raise ValueError("bucket_name 不能为空")

        self.project_id = str(project_id).strip()
        self.client_id = str(client_id).strip()
        self.client_secret = str(client_secret).strip()
        self.developer_id = str(developer_id or "").strip()
        self.credential_type = str(credential_type or "project_client_id").strip()
        self.region = str(region or "CN").strip().upper()
        self.bucket_name = str(bucket_name).strip()
        self.token_url = str(token_url).rstrip("/")
        resolved_upload_base = upload_base_url
        if upload_base_url == self.UPLOAD_BASE_URL:
            resolved_upload_base = self.UPLOAD_HOSTS.get(self.region, upload_base_url)
        self.upload_base_url = str(resolved_upload_base).rstrip("/")
        self.timeout = int(timeout)

        self._access_token: Optional[str] = None
        self._token_expires_at = 0.0

    @classmethod
    def from_project_client_config(
        cls,
        config: Dict,
        bucket_name: str = DEFAULT_BUCKET_NAME,
        token_url: str = TOKEN_URL,
        upload_base_url: str = UPLOAD_BASE_URL,
        timeout: int = 300,
    ) -> "AgcCloudStorageClient":
        if not isinstance(config, dict):
            raise ValueError("config 必须是字典")
        return cls(
            project_id=str(config.get("project_id") or "").strip(),
            client_id=str(config.get("client_id") or "").strip(),
            client_secret=str(config.get("client_secret") or "").strip(),
            developer_id=str(config.get("developer_id") or "").strip(),
            credential_type=str(config.get("type") or "project_client_id").strip(),
            region=str(config.get("region") or "CN").strip().upper(),
            bucket_name=bucket_name,
            token_url=token_url,
            upload_base_url=upload_base_url,
            timeout=timeout,
        )

    def _get_access_token(self) -> str:
        """按 AGC OAuth 文档获取 access_token。"""
        if self._access_token and time.time() < self._token_expires_at:
            return self._access_token

        payload = {
            "grant_type": "client_credentials",
            "client_id": self.client_id,
            "client_secret": self.client_secret,
        }
        headers = {
            "Content-Type": "application/json",
            "Accept": "application/json",
        }

        body = json.dumps(payload, ensure_ascii=False).encode("utf-8")
        request = urllib.request.Request(
            url=self.token_url,
            data=body,
            headers=headers,
            method="POST",
        )
        try:
            with urllib.request.urlopen(request, timeout=min(self.timeout, 30)) as response:
                status_code = response.getcode()
                response_text = response.read().decode("utf-8", errors="replace")
        except urllib.error.HTTPError as exc:
            body_preview = exc.read().decode("utf-8", errors="replace").strip()[:500]
            raise Exception(
                f"Token request failed: {self.token_url} -> {exc.code} {body_preview}"
            ) from exc
        except Exception as exc:
            raise Exception(f"Token request failed: {self.token_url} -> {exc}") from exc

        if status_code != 200:
            body_preview = response_text.strip()[:500]
            raise Exception(
                f"Token request failed: {self.token_url} -> {status_code} {body_preview}"
            )

        result = json.loads(response_text or "{}")
        access_token = str(result.get("access_token") or "").strip()
        if not access_token:
            raise Exception(f"No access_token in response: {result}")

        expires_in = int(result.get("expires_in") or 3600)
        self._access_token = access_token
        self._token_expires_at = time.time() + max(expires_in - 60, 60)
        return self._access_token

    def _build_object_url(self, bucket_name: str, object_name: str) -> str:
        clean_object_name = str(object_name or "").lstrip("/")
        if not clean_object_name:
            raise ValueError("object_name 不能为空")
        encoded_name = quote(clean_object_name, safe="/")
        return f"{self.upload_base_url}/v0/{bucket_name}/{encoded_name}"

    def build_shared_download_url(
        self,
        object_name: str,
        share_token: str,
        bucket_name: Optional[str] = None,
    ) -> str:
        clean_token = str(share_token or "").strip()
        if not clean_token:
            raise ValueError("share_token 不能为空")
        target_bucket = str(bucket_name or self.bucket_name).strip()
        clean_object_name = str(object_name or "").lstrip("/")
        if not target_bucket:
            raise ValueError("bucket_name 不能为空")
        if not clean_object_name:
            raise ValueError("object_name 不能为空")
        share_host = self.SHARE_DOWNLOAD_HOSTS.get(self.region)
        if not share_host:
            raise ValueError(f"暂不支持区域 {self.region} 的共享下载地址生成")
        encoded_name = quote(clean_object_name, safe="/")
        return f"{share_host}/v0/{target_bucket}/{encoded_name}?token={clean_token}"

    def build_download_url(
        self,
        object_name: str,
        bucket_name: Optional[str] = None,
    ) -> str:
        target_bucket = str(bucket_name or self.bucket_name).strip()
        clean_object_name = str(object_name or "").lstrip("/")
        if not target_bucket:
            raise ValueError("bucket_name 不能为空")
        if not clean_object_name:
            raise ValueError("object_name 不能为空")
        download_host = self.SHARE_DOWNLOAD_HOSTS.get(self.region)
        if not download_host:
            raise ValueError(f"暂不支持区域 {self.region} 的下载地址生成")
        encoded_name = quote(clean_object_name, safe="/")
        return f"{download_host}/v0/{target_bucket}/{encoded_name}"

    def upload_bytes(
        self,
        content: bytes,
        object_name: str,
        bucket_name: Optional[str] = None,
        content_type: Optional[str] = None,
        share_token: Optional[str] = None,
    ) -> Dict:
        """上传二进制内容。"""
        if content is None:
            raise ValueError("content 不能为空")

        target_bucket = str(bucket_name or self.bucket_name).strip()
        target_name = str(object_name or "").strip()
        if not target_bucket:
            raise ValueError("bucket_name 不能为空")
        if not target_name:
            raise ValueError("object_name 不能为空")

        upload_url = self._build_object_url(target_bucket, target_name)
        resolved_content_type = content_type or "application/octet-stream"
        headers = {
            "Authorization": f"Bearer {self._get_access_token()}",
            "Content-Type": resolved_content_type,
            "Content-Length": str(len(content)),
            "X-Agc-File-Size": str(len(content)),
            "X-Agc-Trace-Id": str(uuid.uuid1()),
            "client_id": self.client_id,
            "productId": self.project_id,
        }

        request = urllib.request.Request(
            url=upload_url,
            data=content,
            headers=headers,
            method="PUT",
        )
        try:
            with urllib.request.urlopen(request, timeout=self.timeout) as response:
                status_code = response.getcode()
                response_bytes = response.read()
                response_text = response_bytes.decode("utf-8", errors="replace")
        except urllib.error.HTTPError as exc:
            body_preview = exc.read().decode("utf-8", errors="replace").strip()[:500]
            raise Exception(
                f"Upload request failed: {upload_url} -> {exc.code} {body_preview}"
            ) from exc
        except Exception as exc:
            raise Exception(f"Upload request failed: {upload_url} -> {exc}") from exc

        if status_code not in (200, 201):
            body_preview = response_text.strip()[:500]
            raise Exception(
                f"Upload request failed: {upload_url} -> {status_code} {body_preview}"
            )

        try:
            payload = json.loads(response_text) if response_text else {}
        except ValueError:
            payload = {"raw_response": response_text}

        download_url = self.build_download_url(target_name, bucket_name=target_bucket)
        shared_download_url = ""
        share_token = str(share_token or payload.get("shareToken") or payload.get("token") or "").strip()
        if share_token:
            try:
                shared_download_url = self.build_shared_download_url(
                    target_name,
                    share_token,
                    bucket_name=target_bucket,
                )
            except Exception:
                shared_download_url = ""

        return {
            "bucket_name": target_bucket,
            "object_name": target_name,
            "upload_url": upload_url,
            "download_url": download_url,
            "shared_download_url": shared_download_url,
            "share_token": share_token,
            "response": payload,
        }

    def upload_file(
        self,
        file_path: str,
        object_name: Optional[str] = None,
        bucket_name: Optional[str] = None,
        content_type: Optional[str] = None,
        share_token: Optional[str] = None,
    ) -> Dict:
        if not file_path:
            raise ValueError("file_path 不能为空")
        if not os.path.isfile(file_path):
            raise FileNotFoundError(f"待上传文件不存在: {file_path}")

        resolved_object_name = object_name or os.path.basename(file_path)
        resolved_content_type = content_type or mimetypes.guess_type(file_path)[0] or "application/octet-stream"
        with open(file_path, "rb") as f:
            content = f.read()

        result = self.upload_bytes(
            content=content,
            object_name=resolved_object_name,
            bucket_name=bucket_name,
            content_type=resolved_content_type,
            share_token=share_token,
        )
        result.update({
            "source_path": os.path.abspath(file_path),
            "size": os.path.getsize(file_path),
            "sha256": hashlib.sha256(content).hexdigest(),
        })
        return result

    def upload_directory(
        self,
        directory_path: str,
        object_name: Optional[str] = None,
        bucket_name: Optional[str] = None,
        content_type: Optional[str] = None,
        archive_format: str = "zip",
        share_token: Optional[str] = None,
    ) -> Dict:
        if not directory_path:
            raise ValueError("directory_path 不能为空")
        if not os.path.isdir(directory_path):
            raise FileNotFoundError(f"待上传目录不存在: {directory_path}")

        archive_format = str(archive_format or "zip").strip().lower()
        if archive_format not in ("zip", "tar.gz"):
            raise ValueError("archive_format 仅支持 zip 或 tar.gz")

        if archive_format == "zip":
            archive_name = object_name or f"{os.path.basename(os.path.abspath(directory_path.rstrip(os.sep))) or 'archive'}.zip"
            with tempfile.TemporaryDirectory(prefix="agc_upload_") as tmp_dir:
                archive_path = os.path.join(tmp_dir, os.path.basename(archive_name))
                self._package_directory_as_zip(directory_path, archive_path)
                return self.upload_file(
                    archive_path,
                    object_name=archive_name,
                    bucket_name=bucket_name,
                    content_type=content_type or "application/zip",
                    share_token=share_token,
                )

        archive_name = object_name or f"{os.path.basename(os.path.abspath(directory_path.rstrip(os.sep))) or 'archive'}.tar.gz"
        with tempfile.TemporaryDirectory(prefix="agc_upload_") as tmp_dir:
            archive_path = os.path.join(tmp_dir, os.path.basename(archive_name))
            self._package_directory_as_tar_gz(directory_path, archive_path)
            return self.upload_file(
                archive_path,
                object_name=archive_name,
                bucket_name=bucket_name,
                content_type=content_type or "application/gzip",
                share_token=share_token,
            )

    @staticmethod
    def _should_exclude_from_package(relative_path: str) -> bool:
        normalized = str(relative_path or "").replace("\\", "/").strip("/")
        if not normalized:
            return False
        parts = normalized.split("/")
        if "build" in parts:
            return True
        if ".hvigor" in parts:
            return True
        if "oh_modules" in parts:
            return True
        if ".opencode" in parts:
            return True
        if normalized.endswith("opencode.json"):
            return True
        if normalized.endswith("oh-package-lock.json5"):
            return True
        return False

    @classmethod
    def _package_directory_as_zip(cls, directory_path: str, archive_path: str):
        with zipfile.ZipFile(archive_path, "w", compression=zipfile.ZIP_DEFLATED) as zip_file:
            for current_root, _, files in os.walk(directory_path):
                for filename in files:
                    full_path = os.path.join(current_root, filename)
                    relative_path = os.path.relpath(full_path, directory_path)
                    if cls._should_exclude_from_package(relative_path):
                        continue
                    zip_file.write(full_path, arcname=relative_path)

    @classmethod
    def _package_directory_as_tar_gz(cls, directory_path: str, archive_path: str):
        with tarfile.open(archive_path, "w:gz") as tar:
            for current_root, _, files in os.walk(directory_path):
                for filename in files:
                    full_path = os.path.join(current_root, filename)
                    relative_path = os.path.relpath(full_path, directory_path)
                    if cls._should_exclude_from_package(relative_path):
                        continue
                    tar.add(full_path, arcname=relative_path)


class AgcCloudStorageUploader(AgcCloudStorageClient, ObjectUploader):
    """AGC Cloud Storage 上传实现。"""

    pass
