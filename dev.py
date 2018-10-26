#!/usr/bin/env python3
import argparse, os, subprocess, sys

def get_cli_args():
  parser = argparse.ArgumentParser(usage='dev.py [-h] [-ip IP] [-p P] cmd: (autotouch | dav | install | stop_dav | tail) [cmd_args]')
  parser.add_argument('-ip', type=str, help='Ip address of device')
  parser.add_argument('-p', type=str, help='Ssh password of device')
  parser.add_argument('cmd', type=str, help='Command to run (autotouch, dav, install, stop_dav, tail)')
  parser.add_argument('cmd_args', nargs='*')
  args = parser.parse_args()
  ip_pass = {}
  for name, fname, argname in [('ip', '.last_ip', '-ip'), ('p', '.sshpass', '-p')]:
    arg = getattr(args, name, None)
    if arg is None:
      if not os.path.exists(fname):
        raise RuntimeError('%s not found, %s argument must be specified' % (fname, argname))
      else:
        with open(fname) as f:
          ip_pass[name] = f.read()
    else:
      with open(fname, 'w') as f:
        f.write(arg)
      ip_pass[name] = arg
  return args.cmd, ip_pass['ip'], ip_pass['p'], args.cmd_args


if __name__ == '__main__':
  command, ip_address, password, command_args = get_cli_args()
  if command == 'autotouch':
    assert len(command_args) > 0, 'Must provide script name'
    os.system('wget -qO- http://%s:8080/control/start_playing?path=%s.lua' % (ip_address, command_args[0].replace('.lua', '')))
    print('')
  elif command == 'dav':
    if not os.path.exists('mount/'):
      os.mkdir('mount/')
    print('\nConnecting to WebDAV server: %s\n' % ip_address)
    os.system('yes "" | sudo mount -t davfs -o noexec %s mount/' % ip_address)
  elif command == 'install':
    os.system("sshpass -p '%s' scp AutoTouchPlus.lua tests.lua root@%s:/var/mobile/Library/AutoTouch/Scripts/" % (password, ip_address))
    os.system("sshpass -p '%s' ssh root@%s 'chmod ugo+rwx /var/mobile/Library/AutoTouch/Scripts/*'" % (password, ip_address))
  elif command == 'stop-dav':
    print('\nDisconnecting from WebDAV server: %s\n' % ip_address)
    os.system('sudo umount mount/')
  elif command == 'tail':
      cmd = "sshpass -p '%s' ssh root@%s 'tail -f /var/mobile/Library/AutoTouch/Library/log.txt'" % (password, ip_address)
      if command_args:
        cmd += ' -n %s' % command_args[0]
      os.system(cmd)
  else:
    raise RuntimeError('Command "%s" not in (autotouch, dav, install, stop_dav, tail)' % command)