# -*- coding: utf-8 -*-
"""上传适配层。"""

from agent_bench.uploader.interface import ObjectUploader
from agent_bench.uploader.factory import DEFAULT_UPLOADER_PROVIDER, create_uploader
from agent_bench.uploader.agc_cloud_storage import AgcCloudStorageClient, AgcCloudStorageUploader

__all__ = [
    "ObjectUploader",
    "DEFAULT_UPLOADER_PROVIDER",
    "create_uploader",
    "AgcCloudStorageClient",
    "AgcCloudStorageUploader",
]
