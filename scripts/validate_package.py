import argparse
import json
import re
import sys
from datetime import datetime, timezone
from pathlib import Path
from urllib.parse import unquote, urlsplit

LINK = re.compile(r'\[[^\]\n]+\]\(([^)\n]+)\)')


def read_json(path):
    try:
        return json.loads(path.read_text(encoding='utf-8-sig'))
    except (OSError, UnicodeError, json.JSONDecodeError) as error:
        raise ValueError(f'{path.name}: JSON okunamadı ({type(error).__name__})') from error



def result(checked, errors):
    return {'checked': checked, 'errors': errors}



def scoped_path(root, relative):
    target = (root / relative).resolve()
    if not target.is_relative_to(root.resolve()):
        raise ValueError(f'Paket dışında yol: {relative}')
    return target



def prose(text):
    return re.sub(r'^(`{3,}|~{3,})[^\n]*\n.*?^\1[^\n]*$', '', text, flags=re.M | re.S)



def anchors(text):
    found = set(re.findall(r'<a\s+id=["\']([^"\']+)["\']', text))
    counts = {}
    for heading in re.findall(r'^#{1,6}\s+(.+)$', prose(text), re.M):
        slug = re.sub(r'[^\w\- ]', '', heading.strip().lower()).replace(' ', '-')
        duplicate = counts.get(slug, 0)
        found.add(f'{slug}-{duplicate}' if duplicate else slug)
        counts[slug] = duplicate + 1
    return found



def link_error(root, origin, target):
    parsed = urlsplit(target.strip().strip('<>'))
    if parsed.scheme or parsed.netloc:
        return None
    try:
        resolved = scoped_path(root, origin.parent / unquote(parsed.path)) if parsed.path else origin
    except ValueError as error:
        return str(error)
    if not resolved.exists():
        return f'Eksik link: {origin.relative_to(root)} -> {target}'
    if parsed.fragment and resolved.is_file():
        if unquote(parsed.fragment) not in anchors(resolved.read_text(encoding='utf-8-sig')):
            return f'Eksik anchor: {origin.relative_to(root)} -> {target}'
    return None



def check_links(root):
    root = root.resolve()
    errors, checked = [], 0
    for path in sorted(root.rglob('*.md')):
        if path.is_relative_to(root / 'archive') or path.is_relative_to(root / 'tasks/history'):
            continue
        text = prose(path.read_text(encoding='utf-8-sig'))
        for match in LINK.finditer(text):
            checked += 1
            error = link_error(root, path, match[1])
            if error:
                errors.append(error)
    return result(checked, errors)



def check_templates(root):
    errors = []
    definitions = [('task.md', 'Görev durumu', 'PLANNED'), ('contract.md', 'Durum', 'DRAFT')]
    for name, field, expected in definitions:
        path = root / '.agents/templates' / name
        if not path.is_file():
            errors.append(f'Eksik şablon: {name}')
            continue
        text = path.read_text(encoding='utf-8-sig')
        if not re.search(rf'\|\s*{field}\s*\|\s*{expected}\s*\|', text):
            errors.append(f'Yanlış şablon başlangıcı: {name}')
        if 'NOT_RUN' not in text:
            errors.append(f'NOT_RUN eksik: {name}')
    return result(len(definitions), errors)



def check_settings(root):
    data = read_json(root / '.agents/framework.json')
    errors = []
    if data.get('schema_version') != 1 or not isinstance(data.get('kit_version'), str):
        errors.append('Ayar schema_version/kit_version eksik veya geçersiz')
    if data.get('execution_mode') not in ('native', 'delegated'):
        errors.append('Geçersiz execution_mode')
    minimums = {'max_active_agents': 1, 'max_delegation_depth': 0,
                'checkpoint_tool_operations': 1, 'checkpoint_minutes': 1,
                'max_fix_attempts_per_error': 1, 'progress_interval_seconds': 1}
    for key, minimum in minimums.items():
        value = data.get(key)
        if type(value) is not int or value < minimum:
            errors.append(f'Geçersiz sayısal limit: {key}')
    if data.get('ledger_writer') != 'coordinator' or data.get('enforcement') != 'documentation_only':
        errors.append('Defter sahipliği veya rehber kapsamı uyuşmuyor')
    vocab = {'task_states': {'PLANNED', 'READY', 'RUNNING', 'BLOCKED', 'IN_REVIEW', 'DONE', 'FAILED', 'STOPPED'},
             'check_results': {'NOT_RUN', 'PASS', 'FAIL', 'BLOCKED', 'N/A'},
             'contract_states': {'DRAFT', 'REVIEWED', 'ACCEPTED', 'SUPERSEDED'},
             'release_states': {'NOT_REQUESTED', 'PENDING', 'BLOCKED', 'COMPLETED'}}
    for key, expected in vocab.items():
        actual = data.get(key)
        if not isinstance(actual, list) or set(actual) != expected or len(actual) != len(expected):
            errors.append(f'Durum sözlüğü geçersiz: {key}')
    return result(len(minimums) + len(vocab) + 3, errors)


def check_structure(root):
    required = ['AGENTS.md', 'README.md', 'PROJECT.md', 'CHECKS.md', '.agents/framework.json',
                '.agents/README.md', 'tasks/ledger.md', 'docs/architecture.md', 'docs/adoption.md']
    groups = {'policies': ['orchestration', 'risk', 'quality', 'security', 'contracts'],
              'roles': ['coordinator', 'worker', 'verifier', 'security-auditor', 'researcher'],
              'templates': ['task', 'report', 'contract'],
              'workflows': ['context', 'isolation', 'recovery']}
    required += [f'.agents/{group}/{name}.md' for group, names in groups.items() for name in names]
    errors = [f'Eksik ortak dosya: {name}' for name in required if not (root / name).is_file()]
    return result(len(required), errors)


def validate(root):
    checks = {}
    for function in (check_links, check_templates, check_settings, check_structure):
        try:
            checks[function.__name__] = function(root)
        except (OSError, ValueError, KeyError, TypeError, AttributeError) as error:
            checks[function.__name__] = result(0, [str(error)])
    errors = [error for check in checks.values() for error in check['errors']]
    return {'status': 'FAIL' if errors else 'PASS', 'utc': datetime.now(timezone.utc).isoformat(),
            'python': sys.version.split()[0], 'root': str(root), 'checks': checks, 'errors': errors,
            'scope': 'generic documentation structure only; no application or global agent integration tests'}


def main():
    parser = argparse.ArgumentParser(description='Read-only agent documentation validation')
    parser.add_argument('--root', type=Path, default=Path.cwd())
    report = validate(parser.parse_args().root.resolve())
    print(json.dumps(report, ensure_ascii=False, indent=2))
    return 0 if report['status'] == 'PASS' else 1


if __name__ == '__main__':
    raise SystemExit(main())
