#!/opt/voice-login/venv/bin/python
import argparse

def main():
    p=argparse.ArgumentParser(prog='voice-loginctl')
    sp=p.add_subparsers(dest='cmd', required=True)
    for c in ['status','doctor','enable','disable','rollback','purge']:
        sp.add_parser(c)
    en=sp.add_parser('enroll'); en.add_argument('--user', required=True)
    ve=sp.add_parser('verify'); ve.add_argument('--user', required=True); ve.add_argument('--simulate', action='store_true')
    pi=sp.add_parser('set-pin'); pi.add_argument('--user', required=True)
    a=p.parse_args()
    print(f'{a.cmd} executed (prototype)')
    return 0
if __name__=='__main__': raise SystemExit(main())
