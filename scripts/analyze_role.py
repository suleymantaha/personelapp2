"""Opt-in project wrapper for the external role bridge; no model IDs or routing."""
import argparse
import json
from pathlib import Path
import subprocess
import sys


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--kit-root', type=Path, required=True, help='Trusted external kit')
    parser.add_argument('--config', type=Path, required=True, help='Central role/profile config')
    parser.add_argument('--role', choices=('economical', 'strong'), required=True)
    parser.add_argument('--goal', required=True)
    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument('--replay', type=Path, help='Offline response fixture; no model call')
    mode.add_argument('--live', action='store_true', help='Explicitly transmit sources; needs authorization')
    parser.add_argument('--catalog', type=Path)
    parser.add_argument('--require-catalog', action='store_true')
    parser.add_argument('--require-cost', action='store_true')
    args = parser.parse_args(argv)
    root = Path(__file__).absolute().parent.parent
    bridge = args.kit_root.absolute() / 'scripts/run_role.py'
    config = args.config.absolute()
    files = root / 'scripts/analysis-files.json'
    try:
        if not all(p.is_file() for p in (bridge, config, files)):
            raise ValueError('Missing bridge/config/allowlist')
        command = [sys.executable, '-B', str(bridge), '--config', str(config),
                   '--role', args.role, '--goal', args.goal, '--root', str(root),
                   '--files', str(files), '--answer-max-chars', '4000']
        if args.replay:
            command += ['--replay', str(args.replay.absolute())]
        else:
            command += ['--live']
        if args.catalog:
            command += ['--catalog', str(args.catalog.absolute())]
        if args.require_catalog or args.live:
            command += ['--require-catalog']
        if args.require_cost:
            command += ['--require-cost']
        # No shell, retry, alternate config, source discovery or silent fallback.
        return subprocess.run(command, cwd=root, check=False).returncode
    except (OSError, ValueError):
        print(json.dumps({'status': 'BLOCKED', 'answer': None, 'calls_used': 0,
                          'diagnostic': 'MISSING_OR_INACCESSIBLE_BRIDGE_CONFIG_OR_INPUT'}))
        return 2


if __name__ == '__main__':
    raise SystemExit(main())
