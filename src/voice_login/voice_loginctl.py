#!/opt/voice-login/venv/bin/python
import argparse
import os
import platform
import subprocess
from pathlib import Path


def run_doctor() -> int:
    checks = []
    venv_python = Path('/opt/voice-login/venv/bin/python')
    if not venv_python.exists():
        dev_python = Path('.venv/bin/python')
        venv_python = dev_python if dev_python.exists() else venv_python

    checks.append((venv_python.exists(), f"venv python exists: {venv_python}"))

    if venv_python.exists():
        pyv = subprocess.run([str(venv_python), '-c', 'import platform; print(platform.python_version())'], capture_output=True, text=True)
        checks.append((pyv.returncode == 0, f"venv python version: {pyv.stdout.strip() if pyv.returncode == 0 else 'unavailable'}"))

        pipc = subprocess.run([str(venv_python), '-m', 'pip', '--version'], capture_output=True, text=True)
        checks.append((pipc.returncode == 0, 'venv pip available'))

        for module in ['numpy', 'scipy', 'sounddevice', 'argon2', 'torch', 'speechbrain']:
            rc = subprocess.run([str(venv_python), '-c', f'import {module}'], capture_output=True, text=True)
            checks.append((rc.returncode == 0, f'import {module}'))

    checks.append((Path('config/config.example.toml').exists(), 'config example exists'))
    checks.append((os.access('scripts', os.R_OK | os.X_OK), 'scripts directory accessible'))

    print(f"doctor host python: {platform.python_version()}")
    failure = False
    for ok, label in checks:
        status = 'OK' if ok else 'KO'
        print(f"[{status}] {label}")
        if not ok:
            failure = True
    return 1 if failure else 0


def main():
    p=argparse.ArgumentParser(prog='voice-loginctl')
    sp=p.add_subparsers(dest='cmd', required=True)
    for c in ['status','enable','disable','rollback','purge']:
        sp.add_parser(c)
    sp.add_parser('doctor')
    en=sp.add_parser('enroll'); en.add_argument('--user', required=True)
    ve=sp.add_parser('verify'); ve.add_argument('--user', required=True); ve.add_argument('--simulate', action='store_true')
    pi=sp.add_parser('set-pin'); pi.add_argument('--user', required=True)
    a=p.parse_args()
    if a.cmd == 'doctor':
        return run_doctor()
    print(f'{a.cmd} executed (prototype)')
    return 0


if __name__=='__main__':
    raise SystemExit(main())
