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
            payload = {"raw": response_text.strip()}
        download_url = self.build_download_url(
            object_name=target_name,
            bucket_name=target_bucket,
        )
        shared_download_url = None
        if share_token:
            shared_download_url = self.build_shared_download_url(
                object_name=target_name,
                share_token=share_token,
                bucket_name=target_bucket,
            )
        return {
            "status": "success",
            "bucket_name": target_bucket,
            "object_name": target_name,
            "url": upload_url,
            "download_url": download_url,
            "shared_download_url": shared_download_url,
            "share_token": share_token,
            "status_code": status_code,
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
        """上传单个文件。object_name 为空时默认使用文件名。"""
        if not file_path or not os.path.isfile(file_path):
            raise FileNotFoundError(f"文件不存在: {file_path}")

        with open(file_path, "rb") as f:
            content = f.read()

        resolved_object_name = object_name or os.path.basename(file_path)
        guessed_type, _ = mimetypes.guess_type(file_path)
        resolved_content_type = content_type or guessed_type or "application/octet-stream"
        return self.upload_bytes(
            content=content,
            object_name=resolved_object_name,
            bucket_name=bucket_name,
            content_type=resolved_content_type,
            share_token=share_token,
        )

    def upload_directory(
        self,
        source_dir: str,
        object_name: Optional[str] = None,
        bucket_name: Optional[str] = None,
        compression: str = "zip",
        share_token: Optional[str] = None,
    ) -> Dict:
        """打包目录并上传。object_name 为空时默认使用打包后的文件名。"""
        package_path = package_directory(source_dir, compression=compression)
        try:
            resolved_object_name = object_name or os.path.basename(package_path)
            return self.upload_file(
                file_path=package_path,
                object_name=resolved_object_name,
                bucket_name=bucket_name,
                content_type="application/zip" if compression == "zip" else ("application/gzip" if compression == "gz" else "application/octet-stream"),
                share_token=share_token,
            )
        finally:
            try:
                os.remove(package_path)
            except OSError:
                pass

    def upload_large_file(
        self,
        file_path: str,
        object_name: Optional[str] = None,
        bucket_name: Optional[str] = None,
        content_type: Optional[str] = None,
        share_token: Optional[str] = None,
    ) -> Dict:
        """兼容旧接口；当前仍走单次上传。"""
        return self.upload_file(
            file_path=file_path,
            object_name=object_name,
            bucket_name=bucket_name,
            content_type=content_type,
            share_token=share_token,
        )


class AgcStorageUploader(AgcCloudStorageClient):
    """兼容旧名称。"""


def _should_exclude_from_package(rel_path: str) -> bool:
    normalized = str(rel_path or "").replace("\\", "/").strip("/")
    if not normalized:
        return False

    parts = [part for part in normalized.split("/") if part]
    file_name = parts[-1]

    if file_name == "oh-package-lock.json5":
        return True
    if any(part in {"oh_modules", "build"} for part in parts):
        return True
    return False


def package_directory(source_dir: str, output_path: str = None, compression: str = "zip") -> str:
    """将目录打包为 zip 或 tar 文件。"""
    if not os.path.isdir(source_dir):
        raise ValueError(f"源路径不是有效目录: {source_dir}")

    if output_path is None:
        temp_dir = tempfile.gettempdir()
        dir_name = os.path.basename(source_dir.rstrip(os.sep))
        if compression == "zip":
            suffix = ".zip"
        else:
            suffix = f".tar.{compression}" if compression else ".tar"
        output_path = os.path.join(temp_dir, f"{dir_name}{suffix}")

    source_dir = os.path.abspath(source_dir)
    root_arcname = os.path.basename(source_dir.rstrip(os.sep))

    if compression == "zip":
        with zipfile.ZipFile(output_path, "w", compression=zipfile.ZIP_DEFLATED) as archive:
            for current_root, dir_names, file_names in os.walk(source_dir):
                rel_root = os.path.relpath(current_root, source_dir)
                rel_root = "" if rel_root == "." else rel_root.replace("\\", "/")

                kept_dirs = []
                for dir_name in dir_names:
                    rel_dir_path = "/".join(part for part in [rel_root, dir_name] if part)
                    if _should_exclude_from_package(rel_dir_path):
                        continue
                    kept_dirs.append(dir_name)
                dir_names[:] = kept_dirs

                for file_name in file_names:
                    rel_file_path = "/".join(part for part in [rel_root, file_name] if part)
                    if _should_exclude_from_package(rel_file_path):
                        continue
                    abs_file_path = os.path.join(current_root, file_name)
                    arcname = "/".join(part for part in [root_arcname, rel_file_path] if part)
                    archive.write(abs_file_path, arcname)
        return output_path

    mode = "w"
    if compression == "gz":
        mode = "w:gz"
    elif compression == "bz2":
        mode = "w:bz2"
    elif compression == "xz":
        mode = "w:xz"

    with tarfile.open(output_path, mode) as tar:
        tar.add(source_dir, arcname=root_arcname, recursive=False)

        for current_root, dir_names, file_names in os.walk(source_dir):
            rel_root = os.path.relpath(current_root, source_dir)
            rel_root = "" if rel_root == "." else rel_root.replace("\\", "/")

            kept_dirs = []
            for dir_name in dir_names:
                rel_dir_path = "/".join(part for part in [rel_root, dir_name] if part)
                if _should_exclude_from_package(rel_dir_path):
                    continue
                kept_dirs.append(dir_name)
            dir_names[:] = kept_dirs

            for file_name in file_names:
                rel_file_path = "/".join(part for part in [rel_root, file_name] if part)
                if _should_exclude_from_package(rel_file_path):
                    continue
                abs_file_path = os.path.join(current_root, file_name)
                arcname = "/".join(part for part in [root_arcname, rel_file_path] if part)
                tar.add(abs_file_path, arcname=arcname, recursive=False)

    return output_path


def calculate_file_md5(file_path: str) -> str:
    """计算文件 MD5。"""
    md5_hash = hashlib.md5()
    with open(file_path, "rb") as f:
        for chunk in iter(lambda: f.read(8192), b""):
            md5_hash.update(chunk)
    return md5_hash.hexdigest()


def calculate_content_md5(content: bytes) -> str:
    """计算内容 MD5，返回 Base64。"""
    md5_hash = hashlib.md5(content).digest()
    return base64.b64encode(md5_hash).decode("utf-8")
