#!/opt/voice-login/venv/bin/python
import argparse

def main():
    p=argparse.ArgumentParser()
    p.add_argument('--user', required=True)
    p.add_argument('--pin', default='')
    args=p.parse_args()
    print(f'REJECT for user={args.user} (prototype fail-closed)')
    return 1
if __name__=='__main__': raise SystemExit(main())
