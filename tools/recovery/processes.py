"""Cross-platform process-group lifecycle helpers."""

from __future__ import annotations

import os
import subprocess

import psutil


def process_group_options() -> dict[str, bool | int]:
    return {
        "start_new_session": os.name != "nt",
        "creationflags": (
            getattr(subprocess, "CREATE_NEW_PROCESS_GROUP", 0) if os.name == "nt" else 0
        ),
    }


def kill_process_tree(process: subprocess.Popen[bytes]) -> None:
    if process.poll() is not None:
        return
    try:
        parent = psutil.Process(process.pid)
        descendants = parent.children(recursive=True)
        for candidate in (parent, *reversed(descendants)):
            try:
                candidate.kill()
            except (psutil.AccessDenied, psutil.NoSuchProcess):
                pass
    except (psutil.AccessDenied, psutil.NoSuchProcess):
        pass
    if process.poll() is None:
        try:
            process.kill()
        except OSError:
            pass
