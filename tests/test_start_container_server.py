"""Exercise startup boundaries without contacting Steam or starting a real world.

Run with: python3 -m unittest discover -s tests -v
"""

import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest


STARTUP = Path(__file__).resolve().parents[1] / "start-container-server.sh"
BINARY = """#!/usr/bin/env python3
import json, os, sys
with open(os.environ['DST_TEST_EVENTS'], 'a') as events:
    events.write(json.dumps({'launch': sys.argv, 'cwd': os.getcwd()}) + '\\n')
"""
STEAMCMD = """#!/usr/bin/env python3
import json, os, pathlib, sys
events = pathlib.Path(os.environ['DST_TEST_EVENTS'])
attempt = len(events.read_text().splitlines()) + 1
with events.open('a') as output:
    output.write(json.dumps({'steamcmd': sys.argv[1:]}) + '\\n')
if attempt <= int(os.environ.get('DST_TEST_FAILURES', '0')):
    sys.exit(1)
if os.environ.get('DST_TEST_NO_INSTALL') != '1':
    install = pathlib.Path(sys.argv[sys.argv.index('+force_install_dir') + 1])
    binary = install / 'bin64/dontstarve_dedicated_server_nullrenderer_x64'
    binary.parent.mkdir(parents=True, exist_ok=True)
    binary.write_text(os.environ['DST_TEST_BINARY'])
    binary.chmod(0o755)
"""


class StartupTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.home = Path(self.temp.name)
        self.install = self.home / "server_dst"
        self.events = self.home / "events.jsonl"
        self.events.touch()
        self.write_executable(self.home / "steamcmd.sh", STEAMCMD)
        commands = self.home / "commands"
        self.write_executable(commands / "sleep", "#!/bin/sh\nexit 0\n")
        self.env = dict(os.environ, HOME=str(self.home), SHARD_NAME="Master",
                        CLUSTER_NAME="TestCluster", DST_INSTALL_DIR=str(self.install),
                        DST_TEST_EVENTS=str(self.events), DST_TEST_BINARY=BINARY,
                        UPDATE_SERVER="true", STEAMCMD_UPDATE_ATTEMPTS="3",
                        PATH=str(commands) + os.pathsep + os.environ["PATH"])
        for name in ("DST_TEST_FAILURES", "DST_TEST_NO_INSTALL"):
            self.env.pop(name, None)

    @staticmethod
    def write_executable(path, contents):
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(contents)
        path.chmod(0o755)

    def installed(self, legacy=False):
        binary = self.install / ("bin/dontstarve_dedicated_server_nullrenderer" if legacy
                                 else "bin64/dontstarve_dedicated_server_nullrenderer_x64")
        self.write_executable(binary, BINARY)
        return binary

    def run_startup(self, **settings):
        return subprocess.run(["bash", str(STARTUP)], env=dict(self.env, **settings),
                              capture_output=True, text=True, timeout=10)

    def recorded(self):
        return [json.loads(line) for line in self.events.read_text().splitlines()]

    def test_empty_install_downloads_before_launch(self):
        result = self.run_startup()
        self.assertEqual(result.returncode, 0, result.stderr)
        events = self.recorded()
        self.assertEqual(events[0]["steamcmd"], [
            "+@ShutdownOnFailedCommand", "1", "+@NoPromptForPassword", "1",
            "+force_install_dir", str(self.install), "+login", "anonymous",
            "+app_update", "343050", "validate", "+quit"])
        self.assertEqual(events[1]["launch"][1:], ["-cluster", "TestCluster", "-shard", "Master"])
        self.assertEqual(events[1]["cwd"], str(self.install / "bin64"))

    def test_every_restart_checks_existing_install(self):
        self.installed()
        for _ in range(2):
            result = self.run_startup()
            self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual([next(iter(e)) for e in self.recorded()],
                         ["steamcmd", "launch", "steamcmd", "launch"])

    def test_missing_install_downloads_even_with_updates_disabled(self):
        result = self.run_startup(UPDATE_SERVER="false")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("steamcmd", self.recorded()[0])

    def test_installed_server_can_start_without_update(self):
        binary = self.installed()
        result = self.run_startup(UPDATE_SERVER="false")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(len(self.recorded()), 1)
        self.assertEqual(self.recorded()[0]["launch"][0], str(binary))

    def test_legacy_binary_still_supported(self):
        binary = self.installed(legacy=True)
        result = self.run_startup(UPDATE_SERVER="false", SHARD_NAME="Caves")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.recorded()[0]["launch"],
                         [str(binary), "-cluster", "TestCluster", "-shard", "Caves"])

    def test_update_can_switch_legacy_install_to_64_bit(self):
        self.installed(legacy=True)
        result = self.run_startup()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.recorded()[1]["cwd"], str(self.install / "bin64"))

    def test_transient_failure_retries_then_launches(self):
        result = self.run_startup(DST_TEST_FAILURES="2")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual([next(iter(e)) for e in self.recorded()],
                         ["steamcmd", "steamcmd", "steamcmd", "launch"])

    def test_failed_update_does_not_launch_old_server(self):
        self.installed()
        result = self.run_startup(DST_TEST_FAILURES="3")
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual([next(iter(e)) for e in self.recorded()], ["steamcmd"] * 3)

    def test_success_without_binary_does_not_launch(self):
        result = self.run_startup(DST_TEST_NO_INSTALL="1")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("DST server binary not found", result.stderr)
        self.assertEqual(len(self.recorded()), 1)

    def test_invalid_retry_count_rejected_before_download(self):
        result = self.run_startup(STEAMCMD_UPDATE_ATTEMPTS="0")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("must be a positive integer", result.stderr)
        self.assertEqual(self.recorded(), [])


if __name__ == "__main__":
    unittest.main()
