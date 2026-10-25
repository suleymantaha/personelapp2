"""Offline CLI integration checks; fixture model IDs never reach a provider."""
import hashlib
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

ROOT = Path(os.environ['ROLE_PROJECT_ROOT'])
KIT = Path(os.environ['ROLE_KIT_ROOT'])
WRAPPER = ROOT / 'scripts/analyze_role.py'


class ProjectRoleTests(unittest.TestCase):
    def setUp(self):
        self.temp = Path(tempfile.mkdtemp(prefix='personel-role-offline-'))
        self.config = self.temp / 'central.json'
        self.replay = self.temp / 'replay.json'
        self.cfg = {
            'profiles': {'economical': 'helper', 'strong': 'review', 'fallback': 'review'},
            'models': {'helper': {'transport': 'codex-cli', 'model': 'fixture-a'},
                       'review': {'transport': 'codex-cli', 'model': 'fixture-b'}},
            'limits': {'max_calls': 3, 'max_tasks': 2, 'max_fallbacks': 0, 'max_escalations': 0},
        }
        self.save(self.config, self.cfg)
        self.save(self.replay, [{'role': 'summary', 'response': {
            'status': 'ok', 'text': 'Offline fixture, not an analysis verdict.',
            'sources': ['helper', 'tests']}}])

    def save(self, path, value):
        path.write_text(json.dumps(value), encoding='utf-8')

    def run_cli(self, role='economical', config=None, extra=()):
        result = subprocess.run([sys.executable, '-B', str(WRAPPER),
            '--kit-root', str(KIT), '--config', str(config or self.config),
            '--role', role, '--goal', 'Inspect filename contract only.',
            '--replay', str(self.replay), *extra], capture_output=True, text=True)
        self.assertTrue(result.stdout.strip(), result.stderr)
        return result.returncode, json.loads(result.stdout)

    def test_central_substitution_without_project_edit(self):
        before = hashlib.sha256(WRAPPER.read_bytes()).hexdigest()
        for model in ('fixture-a', 'fixture-replacement'):
            self.cfg['models']['helper']['model'] = model
            self.save(self.config, self.cfg)
            code, report = self.run_cli()
            self.assertEqual((code, report['status']), (0, 'REVIEW_REQUIRED'))
            self.assertEqual(report['calls'][0]['model'], model)
            self.assertEqual(report['mode'], 'offline-replay')
            self.assertEqual(report['calls_used'], 1)
            self.assertEqual(set(report['citations']), {'helper', 'tests'})
        self.assertEqual(hashlib.sha256(WRAPPER.read_bytes()).hexdigest(), before)

    def test_strong_role(self):
        self.save(self.replay, [{'role': 'decision', 'response': {
            'status': 'ok', 'text': 'Offline fixture only.', 'sources': ['helper']}}])
        code, report = self.run_cli('strong')
        self.assertEqual(code, 0)
        self.assertEqual(report['calls'][0]['model'], 'fixture-b')

    def test_missing_config_blocks(self):
        code, report = self.run_cli(config=self.temp / 'absent.json')
        self.assertEqual((code, report['status'], report['calls_used']), (2, 'BLOCKED', 0))

    def test_missing_profile_blocks(self):
        self.cfg['profiles']['economical'] = 'absent'
        self.save(self.config, self.cfg)
        code, report = self.run_cli()
        self.assertEqual((code, report['status'], report['calls_used']), (2, 'BLOCKED', 0))

    def test_unavailable_has_no_fallback(self):
        self.save(self.replay, [{'role': 'summary', 'error': 'unavailable'}])
        code, report = self.run_cli()
        self.assertEqual((code, report['status'], report['calls_used']), (2, 'BLOCKED', 1))

    def test_required_catalog_blocks_without_call(self):
        code, report = self.run_cli(extra=('--require-catalog',))
        self.assertEqual((code, report['calls_used']), (2, 0))
        self.assertEqual(report['diagnostic'], 'CATALOG_UNAVAILABLE')


if __name__ == '__main__':
    unittest.main()
