#!/bin/bash

# create debian container 1 ea 
docker run -d --privileged --volume /sys/fs/cgroup:/sys/fs/cgroup:ro --name ws03 zasfe/debian:main /sbin/init
#docker run --tty --privileged --volume /sys/fs/cgroup:/sys/fs/cgroup:ro robertdebock/debian
#docker run --tty --cgroupns=host --privileged --volume /sys/fs/cgroup:/sys/fs/cgroup robertdebock/debian
  
# add vagrant setting 
cat <<EOF > ./debian_vagrant
# https://hub.docker.com/_/debian
# Default locales: C, C.UTF-8, and POSIX
apt-get update && apt-get install -y locales && rm -rf /var/lib/apt/lists/* \
	&& localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8;

apt-get update && apt-get install -y iproute2 net-tools python3 openssh-server sudo curl vim systemd init chpasswd;
ssh-keygen -A;

sed -i "s/#UseDNS yes/UseDNS no/g" /etc/ssh/sshd_config;
sed -i "s/#UseDNS no/UseDNS no/g" /etc/ssh/sshd_config;
systemctl enable ssh && systemctl restart ssh;
useradd -m vagrant
echo 'vagrant:vagrant' | chpasswd
chmod u+w /etc/sudoers.d
echo "vagrant        ALL=NOPASSWD:       ALL" >> /etc/sudoers.d/vagrant
chmod u-w /etc/sudoers.d
EOF

docker cp ./debian_vagrant ws03:/root/debian_vagrant.sh
docker exec -u 0 ws03 /bin/bash /root/debian_vagrant.sh

echo "`docker inspect -f "{{ .NetworkSettings.IPAddress }}" ws03` ws03.fale.io" | sudo tee -a /etc/hosts

if ! grep -i -q ws03.fale.io "hosts"; then
  sed -i 's/ws02.fale.io/ws02.fale.io\nws03.fale.io/' hosts
fi


sshpass -p vagrant ssh-copy-id -f -i ~/.ssh/id_rsa -o StrictHostKeyChecking=no vagrant@ws03.fale.io
sshpass -p vagrant ssh-copy-id -f -i ~/.ssh/id_rsa -o StrictHostKeyChecking=no vagrant@`docker inspect -f "{{ .NetworkSettings.IPAddress }}" ws03`

cat <<EOF > firstrun.yaml
--- 
- hosts: all 
  user: vagrant 
  tasks: 
    - name: Ensure ansible user exists 
      user: 
        name: ansible 
        state: present 
        comment: Ansible 
      become: True
    - name: Ensure ansible user accepts the SSH key 
      authorized_key: 
        user: ansible 
        key: "{{ lookup('file', '~/.ssh/id_rsa.pub') }}"
        state: present 
      become: True
    - name: Ensure the ansible user is sudoer with no password required 
      lineinfile: 
        dest: /etc/sudoers 
        state: present 
        regexp: '^ansible ALL\=' 
        line: 'ansible ALL=(ALL) NOPASSWD:ALL' 
        validate: 'visudo -cf %s'
      become: True
EOF
ansible-playbook -i ws03.fale.io, firstrun.yaml
