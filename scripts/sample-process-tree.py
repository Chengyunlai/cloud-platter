#!/usr/bin/env python3
"""采集 macOS 进程树的匿名 CPU / RSS 基线，不读取进程参数、媒体输出或账号信息。"""

import argparse
import ctypes
import json
import platform
import subprocess
import time
from dataclasses import dataclass
from pathlib import Path


class RusageInfoV2(ctypes.Structure):
    # 布局来自所选 macOS SDK 的 sys/resource.h，CPU 时间使用 Mach tick。
    _fields_ = [("uuid", ctypes.c_uint8 * 16)] + [
        (name, ctypes.c_uint64)
        for name in (
            "user", "system", "idle_wakeups", "interrupt_wakeups", "pageins",
            "wired", "rss", "footprint", "started", "exited", "child_user",
            "child_system", "child_idle_wakeups", "child_interrupt_wakeups",
            "child_pageins", "child_elapsed", "disk_read", "disk_write",
        )
    ]


class MachTimebase(ctypes.Structure):
    _fields_ = [("numer", ctypes.c_uint32), ("denom", ctypes.c_uint32)]


@dataclass(frozen=True)
class Usage:
    own_ticks: int
    reaped_child_ticks: int
    rss: int
    footprint: int
    started: int


def ticks_to_seconds(ticks, numer, denom):
    return ticks * numer / denom / 1_000_000_000


def descendants(root_pid, parents):
    selected = {root_pid}
    while True:
        expanded = selected | {pid for pid, parent in parents.items() if parent in selected}
        if expanded == selected:
            return selected
        selected = expanded


def rollup(usages):
    # XNU 回收子进程时累加其自身及已回收后代 CPU；尚存活的后代在这里各加一次。
    # 参考 apple-oss-distributions/xnu 的 bsd/kern/kern_resource.c:update_rusage_info_child。
    return {
        "cpu_ticks": sum(item.own_ticks + item.reaped_child_ticks for item in usages.values()),
        "rss_bytes": sum(item.rss for item in usages.values()),
        "footprint_bytes": sum(item.footprint for item in usages.values()),
        "process_count": len(usages),
    }


class MacProcessReader:
    def __init__(self):
        if platform.system() != "Darwin":
            raise RuntimeError("macos_required")
        self.libproc = ctypes.CDLL("/usr/lib/libproc.dylib", use_errno=True)
        self.libproc.proc_pid_rusage.argtypes = [ctypes.c_int, ctypes.c_int, ctypes.c_void_p]
        self.libproc.proc_pid_rusage.restype = ctypes.c_int
        system = ctypes.CDLL("/usr/lib/libSystem.B.dylib")
        system.mach_timebase_info.argtypes = [ctypes.POINTER(MachTimebase)]
        self.timebase = MachTimebase()
        if system.mach_timebase_info(ctypes.byref(self.timebase)) != 0 or not self.timebase.denom:
            raise RuntimeError("clock_unavailable")

    def read_usage(self, pid):
        data = RusageInfoV2()
        if self.libproc.proc_pid_rusage(pid, 2, ctypes.byref(data)) != 0 or data.exited:
            return None
        return Usage(data.user + data.system, data.child_user + data.child_system,
                     data.rss, data.footprint, data.started)

    def snapshot(self, root_pid):
        # 只读取 PID / PPID 关系，避免 ps 参数或可执行路径进入记录。
        output = subprocess.check_output(["ps", "-axo", "pid=,ppid="], text=True)
        parents = {int(pid): int(parent) for pid, parent in (line.split() for line in output.splitlines())}
        usages = {}
        for pid in descendants(root_pid, parents):
            usage = self.read_usage(pid)
            if usage is not None:
                usages[pid] = usage
        if root_pid not in usages:
            raise RuntimeError("target_exited_or_unreadable")
        return usages


def collect(root_pid, seconds, interval):
    reader = MacProcessReader()
    started_at = time.monotonic()
    first = reader.snapshot(root_pid)
    expected_start = first[root_pid].started
    initial = rollup(first)
    samples = []
    previous_ticks = initial["cpu_ticks"]
    accounting_races = 0
    while True:
        remaining = seconds - (time.monotonic() - started_at)
        if remaining > 0:
            time.sleep(min(interval, remaining))
        current = reader.snapshot(root_pid)
        if current[root_pid].started != expected_start:
            raise RuntimeError("target_pid_reused")
        totals = rollup(current)
        if totals["cpu_ticks"] < previous_ticks:
            accounting_races += 1
        previous_ticks = totals["cpu_ticks"]
        elapsed = time.monotonic() - started_at
        samples.append({
            "seconds": round(elapsed, 3),
            "main_rss_mib": round(current[root_pid].rss / 1_048_576, 3),
            "tree_rss_mib": round(totals["rss_bytes"] / 1_048_576, 3),
            "tree_footprint_mib": round(totals["footprint_bytes"] / 1_048_576, 3),
            "process_count": totals["process_count"],
        })
        if elapsed >= seconds:
            break
    numer, denom = reader.timebase.numer, reader.timebase.denom
    tree_seconds = ticks_to_seconds(totals["cpu_ticks"] - initial["cpu_ticks"], numer, denom)
    main_seconds = ticks_to_seconds(current[root_pid].own_ticks - first[root_pid].own_ticks, numer, denom)
    return {
        "schema_version": 1,
        "macos": platform.mac_ver()[0],
        "architecture": platform.machine(),
        "duration_seconds": round(elapsed, 3),
        "main_cpu_percent": round(100 * main_seconds / elapsed, 3),
        "tree_cpu_percent": round(100 * tree_seconds / elapsed, 3),
        "main_rss_mib_start": round(first[root_pid].rss / 1_048_576, 3),
        "main_rss_mib_end": samples[-1]["main_rss_mib"],
        "tree_rss_mib_peak": max(sample["tree_rss_mib"] for sample in samples),
        "max_live_processes": max(sample["process_count"] for sample in samples),
        "accounting_race_samples": accounting_races,
        "limitations": [
            "CPU percent uses one logical core as 100 percent.",
            "Live PID enumeration and counters are not an atomic snapshot.",
            "RSS sums may double-count shared memory; short-lived RSS peaks may be missed.",
            "Reaped child CPU is included; GPU and battery energy are not measured.",
        ],
        "samples": samples,
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--pid", type=int, required=True)
    parser.add_argument("--seconds", type=float, default=600)
    parser.add_argument("--interval", type=float, default=1)
    parser.add_argument("--output", type=Path, required=True)
    arguments = parser.parse_args()
    if arguments.pid <= 0 or arguments.seconds <= 0 or arguments.interval < 0.05:
        parser.error("pid / seconds 必须为正数，interval 至少为 0.05 秒")
    report = collect(arguments.pid, arguments.seconds, arguments.interval)
    arguments.output.parent.mkdir(parents=True, exist_ok=True)
    arguments.output.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n")
    print(json.dumps({key: value for key, value in report.items() if key != "samples"}))


if __name__ == "__main__":
    main()
