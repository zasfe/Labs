* Create a “config” file that will be used by SSH-agent to do the forwarding of SSH connection.
```
$ cd .ssh
$ touch config
$ chmod 600 config
$ sudo vi config
```
##### SSH-agent forwarding
```
Host <bastion_hostname/IP>
  User <user_name>
  HostName <bastion_public_dns/public_IP>
  Port 22
  IdentityFile <path_to_private_key>

Host <destination_instance_IP_address>
  User <user_name>
  HostName <bastion_public_dns/public_IP>
  Port 22
  IdentityFile <path_to_destination_instance_private_key>
  ProxyCommand ssh -W %h:%p <bastion_hostname/IP>
```

* Change to the Directory where the Ansible Script is present and modify the ansible.cfg and hosts files.
```
$ sudo nano ansible.cfg
```
```
[defaults]
inventory = ./hosts
[ssh_connection]
ssh_args = -F ~/.ssh/config -o ControlMaster=auto -o ControlPersist=30m -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o ForwardAgent=yes
control_path = ~/.ansible/cp/ansible-%%r@%%h:%%p
```
* The ansible.cfg has the SSH-Connection configuration for ansible, where we need to point it to look at the ~/.ssh/config we’ve created in the previous step. In the section above, the ssh_args points to the file and has other options such as (ControlMaster, ControlPersist, and ControlPath) which are needed for agent forwarding. Also ensure to have the StrictHostKeyChecking flag which points to “no”.

```
sudo vi hosts
```
```
[<profilename>]
<Public IP/ DNS — Bastion> ansible_ssh_private_key_file=~/.ssh/<bastion_instance_private_key.pem> ansible_user=<instance-username> ansible_ssh_extra_args=’-o StrictHostKeyChecking=no’
<private IP — node> ansible_user=<instance-username> ansible_ssh_extra_args=’-o StrictHostKeyChecking=no’
<private IP — node> ansible_user=<instance-username> ansible_ssh_extra_args=’-o StrictHostKeyChecking=no’
```
* Add the private keys to the SSH-agent to allow the agent forwarding to successfully establish the connection with the identity files without storing the private keys on Bastion.

```
$ ssh-agent bash
$ ssh-add ~/.ssh/<bastion_private_key.pem>
$ ssh-add ~/.ssh/<destination_instance1_private_key.pem>
$ ssh-add ~/.ssh/<destination_instance2_private_key.pem>
$ ssh-add -L

ssh-add -L:command lists the keys that are added to the SSH-agent to do the forwarding. Verify the keys to ensure all the needed ones are present.
```
NOTE: This is a very important step. NEVER Store private keys on the BASTION host to access the private instances.

* Run your ansible playbook with the new configuration. Should you run into issues, use the -vvv option to run it in DEBUG mode.
