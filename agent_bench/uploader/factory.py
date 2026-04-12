# -*- coding: utf-8 -*-
"""上传适配层工厂。"""

from agent_bench.uploader.agc_cloud_storage import AgcCloudStorageUploader


DEFAULT_UPLOADER_PROVIDER = "agcCloudStorage"


def create_uploader(provider: str = DEFAULT_UPLOADER_PROVIDER, **kwargs):
    provider_name = str(provider or DEFAULT_UPLOADER_PROVIDER).strip()
    if provider_name == "agcCloudStorage":
        return AgcCloudStorageUploader(**kwargs)
    raise ValueError(f"暂不支持的 uploader provider: {provider_name}")
