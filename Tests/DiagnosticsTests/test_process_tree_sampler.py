import importlib.util
import sys
import unittest
from pathlib import Path

path = Path(__file__).resolve().parents[2] / "scripts" / "sample-process-tree.py"
spec = importlib.util.spec_from_file_location("process_tree_sampler", path)
sampler = importlib.util.module_from_spec(spec)
sys.modules[spec.name] = sampler
spec.loader.exec_module(sampler)


class ProcessTreeSamplerTests(unittest.TestCase):
    def test_mach_ticks_use_architecture_timebase(self):
        self.assertEqual(sampler.ticks_to_seconds(24_000_000, 125, 3), 1)
        self.assertEqual(sampler.ticks_to_seconds(1_000_000_000, 1, 1), 1)

    def test_child_reaping_does_not_drop_cpu(self):
        usage = sampler.Usage
        before = sampler.rollup({1: usage(10, 0, 100, 50, 1), 2: usage(20, 0, 40, 30, 2)})
        after = sampler.rollup({1: usage(11, 20, 100, 50, 1)})
        self.assertEqual(before["cpu_ticks"], 30)
        self.assertEqual(after["cpu_ticks"] - before["cpu_ticks"], 1)

    def test_live_nested_helpers_include_reaped_descendants_once(self):
        usage = sampler.Usage
        report = sampler.rollup({
            1: usage(100, 40, 100, 50, 1),
            2: usage(30, 10, 40, 30, 2),
            3: usage(20, 0, 50, 40, 3),
        })
        self.assertEqual(report["cpu_ticks"], 200)
        self.assertEqual(report["rss_bytes"], 190)

    def test_unrelated_processes_are_excluded(self):
        self.assertEqual(sampler.descendants(10, {10: 1, 11: 10, 12: 11, 20: 1, 21: 20}),
                         {10, 11, 12})


if __name__ == "__main__":
    unittest.main()
