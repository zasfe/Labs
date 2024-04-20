#!/bin/bash

# faster-ansible-playbook-execution

if ! grep -i -q callbacks_enabled "ansible.cfg"; then
  sed -i 's/\[defaults\]/\[defaults\]\n## display tasks times\ncallbacks_enabled = timer, profile_tasks, profile_roles/' ./ansible.cfg
fi

if ! grep -i -q forks "ansible.cfg"; then
  sed -i 's/\[defaults\]/\[defaults\]\n## parallelism running, default 5, Task5\(start-\>end\) -\> Task5 \nforks=50/' ./ansible.cfg
fi

if ! grep -i -q host_key_checking "ansible.cfg"; then
  sed -i 's/\[defaults\]/\[defaults\]\n## Disable host key check\nhost_key_checking = False/' ./ansible.cfg
fi

if ! grep -i -q pipelining "ansible.cfg"; then
  sed -i 's/\[defaults\]/\[defaults\]\n## SSH connections reduce\npipelining = True/' ./ansible.cfg
fi

if ! grep -i -q ssh_connection "ansible.cfg"; then
  echo "[ssh_connection]" >> ./ansible.cfg
  echo "ssh_args = -o ControlMaster=auto -o ControlPersist=60s" >> ./ansible.cfg
fi
