#!/usr/bin/env bash
LANG=C

# sudo bash -c "curl --tlsv1.2 -s https://raw.githubusercontent.com/zasfe/Labs/master/bash/systeminfo3.sh | bash -"
# curl --tlsv1.2 -s https://raw.githubusercontent.com/zasfe/Labs/master/bash/systeminfo3.sh | bash -

docker rm -f ws01 ws02 db01

docker run -d --privileged --name ws01 centos:centos7 /usr/sbin/init
docker run -d --privileged --name ws02 centos:centos7 /usr/sbin/init
docker run -d --privileged --name db01 centos:centos7 /usr/sbin/init

cat <<EOF > ./centos7_vagrant
#!/usr/bin/env bash
LANG=C

mv /usr/bin/systemctl /usr/bin/systemctl.old
curl https://raw.githubusercontent.com/gdraheim/docker-systemctl-replacement/master/files/docker/systemctl.py > /usr/bin/systemctl
chmod +x /usr/bin/systemctl
yum install -y iproute net-tools openssh-server sudo;
ssh-keygen -A;
systemctl enable sshd; systemctl start sshd;
sed -i "s/#UseDNS yes/UseDNS no/g" /etc/ssh/sshd_config
sed -i "s/#UseDNS no/UseDNS no/g" /etc/ssh/sshd_config
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

docker exec -u 0 ws01 /bin/bash -c "rm -f /home/vagrant/.ssh/authorized_keys"
docker exec -u 0 ws02 /bin/bash -c "rm -f /home/vagrant/.ssh/authorized_keys"
docker exec -u 0 db01 /bin/bash -c "rm -f /home/vagrant/.ssh/authorized_keys"


sed -i '/ws01.fale.io/d' "/etc/hosts"
sed -i '/ws02.fale.io/d' "/etc/hosts"
sed -i '/db01.fale.io/d' "/etc/hosts"

echo "`docker inspect -f "{{ .NetworkSettings.IPAddress }}" ws01` ws01.fale.io" >> /etc/hosts
echo "`docker inspect -f "{{ .NetworkSettings.IPAddress }}" ws02` ws02.fale.io" >> /etc/hosts
echo "`docker inspect -f "{{ .NetworkSettings.IPAddress }}" db01` db01.fale.io" >> /etc/hosts


rm -f ~/.ssh/*
ssh-keygen -b 2048 -t rsa -f ~/.ssh/id_rsa -q -N ''

ssh-keygen -f ~/.ssh/known_hosts -R "ws01.fale.io"
ssh-keygen -f ~/.ssh/known_hosts -R "ws02.fale.io"
ssh-keygen -f ~/.ssh/known_hosts -R "db01.fale.io"

ssh-keyscan -t rsa ws01.fale.io >> ~/.ssh/known_hosts
ssh-keyscan -t rsa ws02.fale.io >> ~/.ssh/known_hosts
ssh-keyscan -t rsa db01.fale.io >> ~/.ssh/known_hosts
ssh-keyscan -t rsa `docker inspect -f "{{ .NetworkSettings.IPAddress }}" ws01` >> ~/.ssh/known_hosts
ssh-keyscan -t rsa `docker inspect -f "{{ .NetworkSettings.IPAddress }}" ws02` >> ~/.ssh/known_hosts
ssh-keyscan -t rsa `docker inspect -f "{{ .NetworkSettings.IPAddress }}" db01` >> ~/.ssh/known_hosts

sshpass -p vagrant ssh-copy-id -f -i ~/.ssh/id_rsa vagrant@ws01.fale.io
sshpass -p vagrant ssh-copy-id -f -i ~/.ssh/id_rsa vagrant@ws02.fale.io
sshpass -p vagrant ssh-copy-id -f -i ~/.ssh/id_rsa vagrant@db01.fale.io

# ssh -o StrictHostKeyChecking=no vagrant@ws01.fale.io
# ssh -v vagrant@ws01.fale.io

## EOF
