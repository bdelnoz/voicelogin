#!/opt/voice-login/venv/bin/python
import argparse

def main():
    p=argparse.ArgumentParser(); p.add_argument('--user', required=True); args=p.parse_args()
    print(f'Enroll placeholder for {args.user}')
    return 0
if __name__=='__main__': raise SystemExit(main())
