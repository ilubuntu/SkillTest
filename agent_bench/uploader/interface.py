# -*- coding: utf-8 -*-
"""上传适配层统一接口。"""

from abc import ABC, abstractmethod
from typing import Dict, Optional


class ObjectUploader(ABC):
    """对象存储上传接口。"""

    @abstractmethod
    def upload_file(
        self,
        file_path: str,
        object_name: Optional[str] = None,
        bucket_name: Optional[str] = None,
        content_type: Optional[str] = None,
        share_token: Optional[str] = None,
    ) -> Dict:
        pass

    @abstractmethod
    def upload_directory(
        self,
        directory_path: str,
        object_name: Optional[str] = None,
        bucket_name: Optional[str] = None,
        content_type: Optional[str] = None,
        archive_format: str = "zip",
        share_token: Optional[str] = None,
    ) -> Dict:
        pass
