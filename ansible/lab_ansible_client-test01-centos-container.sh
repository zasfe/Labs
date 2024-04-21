#!/bin/sh

docker run -d --privileged --name test01 centos:centos7 /usr/sbin/init
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
docker cp ./centos7_vagrant test01:/root/centos7_vagrant.sh
docker exec -u 0 test01 /bin/bash /root/centos7_vagrant.sh


sshpass -p vagrant ssh-copy-id -f -i ~/.ssh/id_rsa vagrant@`docker inspect -f "{{ .NetworkSettings.IPAddress }}" test01`
echo "`docker inspect -f "{{ .NetworkSettings.IPAddress }}" test01` test01.fale.io" | sudo tee -a /etc/hosts
