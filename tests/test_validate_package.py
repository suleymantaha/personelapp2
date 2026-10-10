import importlib.util
import json
import tempfile
import unittest
from pathlib import Path

SCRIPT = Path(__file__).resolve().parents[1] / 'scripts/validate_package.py'
spec = importlib.util.spec_from_file_location('validator', SCRIPT)
validator = importlib.util.module_from_spec(spec)
spec.loader.exec_module(validator)


class GenericKitTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)

    def write(self, relative, text):
        path = self.root / relative
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(text, encoding='utf-8')

    def settings(self, **changes):
        data = {
            'schema_version': 1, 'kit_version': '1.0', 'execution_mode': 'native',
            'max_active_agents': 3, 'max_delegation_depth': 1,
            'checkpoint_tool_operations': 30, 'checkpoint_minutes': 15,
            'max_fix_attempts_per_error': 3, 'progress_interval_seconds': 60,
            'ledger_writer': 'coordinator', 'enforcement': 'documentation_only',
            'task_states': ['PLANNED', 'READY', 'RUNNING', 'BLOCKED', 'IN_REVIEW', 'DONE', 'FAILED', 'STOPPED'],
            'check_results': ['NOT_RUN', 'PASS', 'FAIL', 'BLOCKED', 'N/A'],
            'contract_states': ['DRAFT', 'REVIEWED', 'ACCEPTED', 'SUPERSEDED'],
            'release_states': ['NOT_REQUESTED', 'PENDING', 'BLOCKED', 'COMPLETED'],
        }
        data.update(changes)
        self.write('.agents/framework.json', json.dumps(data))

    def test_missing_link_is_rejected(self):
        self.write('README.md', '[guide](missing.md)')
        self.assertTrue(validator.check_links(self.root)['errors'])

    def test_existing_link_is_accepted(self):
        self.write('README.md', '[guide](docs/guide.md)')
        self.write('docs/guide.md', '# Guide')
        self.assertFalse(validator.check_links(self.root)['errors'])

    def test_missing_anchor_is_rejected(self):
        self.write('README.md', '[guide](guide.md#absent)')
        self.write('guide.md', '# Guide')
        self.assertTrue(validator.check_links(self.root)['errors'])

    def test_turkish_heading_anchor_is_accepted(self):
        self.write('README.md', '[guide](guide.md#çalışma-akışı)')
        self.write('guide.md', '# Çalışma Akışı')
        self.assertFalse(validator.check_links(self.root)['errors'])

    def test_explicit_anchor_is_accepted(self):
        self.write('README.md', '[guide](guide.md#custom)')
        self.write('guide.md', '<a id="custom"></a>Guide')
        self.assertFalse(validator.check_links(self.root)['errors'])

    def test_example_link_in_fenced_code_is_ignored(self):
        self.write('README.md', '```markdown\n[example](missing.md)\n```')
        self.assertFalse(validator.check_links(self.root)['errors'])

    def test_escaping_package_path_is_rejected(self):
        self.write('README.md', '[outside](../outside.md)')
        self.assertTrue(validator.check_links(self.root)['errors'])

    def test_missing_same_file_fragment_is_rejected(self):
        self.write('README.md', '# Guide\n[missing](#absent)')
        self.assertTrue(validator.check_links(self.root)['errors'])

    def test_custom_positive_limits_are_accepted(self):
        self.settings(max_active_agents=1, checkpoint_minutes=10, checkpoint_tool_operations=20)
        self.assertFalse(validator.check_settings(self.root)['errors'])

    def test_zero_active_agents_is_rejected(self):
        self.settings(max_active_agents=0)
        self.assertTrue(validator.check_settings(self.root)['errors'])

    def test_boolean_is_not_a_numeric_limit(self):
        self.settings(max_active_agents=True)
        self.assertTrue(validator.check_settings(self.root)['errors'])

    def test_zero_delegation_depth_is_accepted(self):
        self.settings(max_delegation_depth=0)
        self.assertFalse(validator.check_settings(self.root)['errors'])

    def test_invalid_execution_mode_is_rejected(self):
        self.settings(execution_mode='unlimited')
        self.assertTrue(validator.check_settings(self.root)['errors'])

    def test_duplicate_state_is_rejected(self):
        self.settings(check_results=['NOT_RUN', 'PASS', 'FAIL', 'BLOCKED', 'N/A', 'PASS'])
        self.assertTrue(validator.check_settings(self.root)['errors'])

    def test_invalid_json_is_reported_with_file_name(self):
        self.write('.agents/framework.json', '{broken')
        with self.assertRaisesRegex(ValueError, 'framework.json'):
            validator.check_settings(self.root)

    def test_task_template_cannot_start_done(self):
        self.write('.agents/templates/task.md', '| Görev durumu | DONE |\nNOT_RUN')
        self.write('.agents/templates/contract.md', '| Durum | DRAFT |\nNOT_RUN')
        self.assertTrue(validator.check_templates(self.root)['errors'])

    def test_honest_template_initial_states_are_accepted(self):
        self.write('.agents/templates/task.md', '| Görev durumu | PLANNED |\nNOT_RUN')
        self.write('.agents/templates/contract.md', '| Durum | DRAFT |\nNOT_RUN')
        self.assertFalse(validator.check_templates(self.root)['errors'])

    def test_missing_structure_is_rejected(self):
        self.assertTrue(validator.check_structure(self.root)['errors'])

    def test_invalid_package_returns_fail_instead_of_crashing(self):
        self.write('.agents/framework.json', '{broken')
        self.assertEqual('FAIL', validator.validate(self.root)['status'])


if __name__ == '__main__':
    unittest.main()
