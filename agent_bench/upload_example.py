# -*- coding: utf-8 -*-
"""AGC Storage上传示例代码

用法:
    python upload_example.py <待上传目录或文件路径>
"""

import os
import sys
import argparse

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from storage_uploader import AgcStorageUploader


BUCKET_NAME = "agent-bench-lpgvk"
PROJECT_CLIENT_CONFIG = {
    "type": "project_client_id",
    "developer_id": "900086000150224722",
    "project_id": "101653523863785276",
    "client_id": "1919775246739619200",
    "client_secret": "D1A9970837E38AAB4B7D4AFBDCAEC1B0D6511662C7026DAE1808298342F9192C",
    "configuration_version": "3.0",
    "region": "CN",
}


def main():
    parser = argparse.ArgumentParser(description="AGC Storage上传示例")
    parser.add_argument("source_path", help="待上传的目录或文件路径")
    parser.add_argument("--object-name", "-o", help="指定存储对象名称（默认使用打包后的文件名）")
    parser.add_argument("--client-secret", "-s", default=PROJECT_CLIENT_CONFIG["client_secret"], help="Client Secret")
    parser.add_argument("--no-package", action="store_true", help="不打包，直接上传单个文件")
    args = parser.parse_args()

    source_path = args.source_path
    if not os.path.exists(source_path):
        print(f"错误: 路径不存在: {source_path}")
        sys.exit(1)

    project_client_config = dict(PROJECT_CLIENT_CONFIG)
    project_client_config["client_secret"] = args.client_secret
    uploader = AgcStorageUploader.from_project_client_config(
        project_client_config,
        bucket_name=BUCKET_NAME,
    )

    try:
        if args.no_package or os.path.isfile(source_path):
            object_name = args.object_name or os.path.basename(source_path)
            print(f"正在上传文件: bucket={BUCKET_NAME}, object={object_name}")
            result = uploader.upload_file(source_path, object_name=object_name)
        else:
            print(f"正在打包并上传目录: {source_path}")
            result = uploader.upload_directory(source_path, object_name=args.object_name)
        print(f"上传成功: {result}")
    except Exception as e:
        print(f"上传失败: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()
