#!/bin/bash

# create centos container 3 ea 
docker run -d --privileged --name ws01 centos:centos7 /usr/sbin/init
docker run -d --privileged --name ws02 centos:centos7 /usr/sbin/init
docker run -d --privileged --name db01 centos:centos7 /usr/sbin/init

# add vagrant setting 
cat <<EOF > ./centos7_vagrant
mv /usr/bin/systemctl /usr/bin/systemctl.old;
curl https://raw.githubusercontent.com/gdraheim/docker-systemctl-replacement/master/files/docker/systemctl.py > /usr/bin/systemctl;
chmod +x /usr/bin/systemctl;
yum install -y iproute net-tools openssh-server sudo;
ssh-keygen -A;
sed -i "s/#UseDNS yes/UseDNS no/g" /etc/ssh/sshd_config
sed -i "s/#UseDNS no/UseDNS no/g" /etc/ssh/sshd_config
systemctl enable sshd; systemctl restart sshd;
useradd vagrant
echo "vagrant" | passwd --stdin vagrant
chmod u+w /etc/sudoers.d
echo "vagrant        ALL=NOPASSWD:       ALL" >> /etc/sudoers.d/vagrant
chmod u-w /etc/sudoers.d
EOF

docker cp ./centos7_vagrant ws01:/root/centos7_vagrant.sh
docker exec -u 0 ws01 /bin/bash /root/centos7_vagrant.sh

docker cp ./centos7_vagrant ws02:/root/centos7_vagrant.sh
docker exec -u 0 ws02 /bin/bash /root/centos7_vagrant.sh

docker cp ./centos7_vagrant db01:/root/centos7_vagrant.sh
docker exec -u 0 db01 /bin/bash /root/centos7_vagrant.sh

echo "`docker inspect -f "{{ .NetworkSettings.IPAddress }}" ws01` ws01.fale.io ws01" | sudo tee -a /etc/hosts
echo "`docker inspect -f "{{ .NetworkSettings.IPAddress }}" ws02` ws02.fale.io ws02" | sudo tee -a /etc/hosts
echo "`docker inspect -f "{{ .NetworkSettings.IPAddress }}" db01` db01.fale.io db01" | sudo tee -a /etc/hosts

sshpass -p vagrant ssh-copy-id -f -i ~/.ssh/id_rsa -o StrictHostKeyChecking=no vagrant@ws01.fale.io
sshpass -p vagrant ssh-copy-id -f -i ~/.ssh/id_rsa -o StrictHostKeyChecking=no vagrant@ws02.fale.io
sshpass -p vagrant ssh-copy-id -f -i ~/.ssh/id_rsa -o StrictHostKeyChecking=no vagrant@db01.fale.io

sshpass -p vagrant ssh-copy-id -f -i ~/.ssh/id_rsa -o StrictHostKeyChecking=no vagrant@`docker inspect -f "{{ .NetworkSettings.IPAddress }}" ws01`
sshpass -p vagrant ssh-copy-id -f -i ~/.ssh/id_rsa -o StrictHostKeyChecking=no vagrant@`docker inspect -f "{{ .NetworkSettings.IPAddress }}" ws02`
sshpass -p vagrant ssh-copy-id -f -i ~/.ssh/id_rsa -o StrictHostKeyChecking=no vagrant@`docker inspect -f "{{ .NetworkSettings.IPAddress }}" db01`
