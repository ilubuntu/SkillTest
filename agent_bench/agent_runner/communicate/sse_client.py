# -*- coding: utf-8 -*-
"""OpenCode SSE 客户端。"""

import time
import urllib.parse
import urllib.request


class OpenCodeSseClient:
    """封装 OpenCode SSE 连接读取。"""

    def __init__(self, api_base: str, endpoints=None):
        self.api_base = str(api_base or "").rstrip("/")
        self.endpoints = tuple(endpoints or ("/global/event", "/event"))

    def capture_events(self,
                       stop_event,
                       connected_event,
                       parse_payload,
                       handle_payload,
                       handle_error,
                       handle_empty_endpoint=None,
                       timeout: int = 120,
                       workspace_dir: str = "",
                       retry_delay: float = 1.0):
        while not stop_event.is_set():
            try:
                connected = False
                last_error = None
                for endpoint in self.endpoints:
                    try:
                        url = f"{self.api_base}{endpoint}"
                        headers = {}
                        if workspace_dir:
                            query = urllib.parse.urlencode({"directory": workspace_dir})
                            url = f"{url}?{query}"
                            headers["x-opencode-directory"] = str(workspace_dir)
                        req = urllib.request.Request(url, headers=headers, method="GET")
                        with urllib.request.urlopen(req, timeout=timeout) as response:
                            connected = True
                            connected_event.set()
                            received_payload = False
                            event_name = None
                            data_lines = []
                            while not stop_event.is_set():
                                raw_line = response.readline()
                                if not raw_line:
                                    break
                                line = raw_line.decode("utf-8", errors="replace").rstrip("\r\n")
                                if line.startswith("event:"):
                                    event_name = line[6:].strip()
                                elif line.startswith("data:"):
                                    data_lines.append(line[5:].lstrip())
                                elif line == "":
                                    payload = parse_payload(event_name, data_lines)
                                    if payload is not None:
                                        received_payload = True
                                        handle_payload(payload)
                                    event_name = None
                                    data_lines = []
                        if connected and received_payload:
                            break
                        if connected and not received_payload and not stop_event.is_set() and handle_empty_endpoint:
                            handle_empty_endpoint(endpoint)
                    except Exception as exc:
                        last_error = exc
                        continue
                if not connected and last_error is not None:
                    raise last_error
                time.sleep(0.5)
            except Exception as exc:
                if stop_event.is_set():
                    break
                handle_error(exc)
                time.sleep(retry_delay)
