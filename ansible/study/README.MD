# Learning Ansible 2.7


- 교재: Learning Ansible 2.7 - Third Edition [(packtpub)](https://www.packtpub.com/product/learning-ansible-27-third-edition/9781789954333) [(github)](https://github.com/PacktPublishing/Learning-Ansible-2.X-Third-Edition)
- [(ansible playbook 빠른 실행)](https://github.com/zasfe/Labs/blob/master/ansible/faster-ansible-playbook-execution.sh)
- lab용 client container 설정하기 [(test01)](https://github.com/zasfe/Labs/blob/master/ansible/lab_ansible_client-test01-centos-container.sh) [(centos ws01/ws02/db01)](https://github.com/zasfe/Labs/blob/master/ansible/lab_ansible_client_centos-container-3ea.sh) [(debian ws03)](https://github.com/zasfe/Labs/blob/master/ansible/lab_ansible_client_ws03-debian-container.sh)

## 정리

* 핸들러(roles/이름/handlers) 설정을 하면 "이름" 작업 후 실행한다.
* import_playbook 로 실행할 playbook 순서를 지정할 수 있다.(실패하면 이후 단계 실행 안됨)
* ansible-valut은 비밀번호로 코드를 암호화할 수 있음.(비밀번호는 변경가능) 
* ansible 모듈 위치: /usr/lib/python2.7/site-packages/ansible/modules
* --syntax-check : 문법에 맞는 파일인지 체크
* --diff : playbook 파일 설정 변경 사항을 표시함, --check 와 함께 사용 (+는 추가, -는 삭제)
* --list-hosts : playbook 실행할 대상 목록을 표시
* --list-tasks : playbook 파일의 작업 목록을 표시(제목, 태그)
* -t : playbook 파일 중 특정 태그만 실행
* --skip-tags : playbook 파일 중 특정 태그를 제외하고 실행
* yum 모듈: 여러 패키지를 설치하도록 설정할때 문법이 변경되니 참고 필요(경고 비활성: deprecation_warnings=False in ansible.cfg)

```yaml
- name: Install a list of packages (suitable replacement for 2.11 loop deprecation warning)
  ansible.builtin.yum:
    name:
      - nginx
      - postgresql
      - postgresql-server
    state: present

- name: Install a list of packages with a list variable
  ansible.builtin.yum:
    name: "{{ packages }}"
  vars:
    packages:
    - httpd
    - httpd-tools
```

* Windows 원격 관리 ( WinRM ) 
  * 설명: https://learn.microsoft.com/en-in/windows/win32/winrm/portal
  * Ansible
    * pywinrm 0.3.0 이상,  `pip install "pywinrm>=0.3.0"`
  * Taget(Window Client)
    * WinRM 구성 예시 [ansible examples](https://github.com/ansible/ansible/blob/devel/examples/scripts/ConfigureRemotingForAnsible.ps1)
    * PowerShell 버전 3.0 이상 [설치 예시](https://github.com/cchurch/ansible/blob/devel/examples/scripts/upgrade_to_ps3.ps1)
    * Allow TCP 5986 port
	* 구성 확인: `curl -vk -d '' -u "$USER:$PASSWORD" "https://<IP>:5986/wsman"`




## collections 스크립트

* Docker
  * https://docs.ansible.com/ansible/latest/collections/community/docker/index.html#plugins-in-community-docker
* Amazon Web Services ( AWS )
  * https://docs.ansible.com/ansible/latest/collections/amazon/aws/index.html
  * https://docs.ansible.com/ansible/latest/collections/community/aws/index.html#plugins-in-community-aws
* Kubernetes
  * https://docs.ansible.com/ansible/latest/collections/kubernetes/index.html
* Openstack 
  * https://docs.ansible.com/ansible/latest/collections/openstack/index.html
  * https://docs.ansible.com/ansible/latest/collections/openstack/cloud/index.html#plugins-in-openstack-cloud
* Microsoft
  * https://docs.ansible.com/ansible/latest/collections/microsoft/index.html
  * https://docs.ansible.com/ansible/latest/collections/community/windows/index.html#plugins-in-community-windows

## 한일

  * CentOS 와 CentOS vagrant 컨테이너 빌드 및 docker hub 등록하도록 github action 설정 완료
    * repo: https://github.com/zasfe/docker-centos-systemd
    * container image: https://hub.docker.com/r/zasfe/centos{7:7-systemd-vagrant:8}
    * 참고: https://github.com/robertdebock/docker-centos-systemd


**Gathering Facts 기반으로 when 연산자를 사용해서 실행여부를 설정한다.**

```yaml
..
    - name: Ensure the httpd package is updated 
      yum: 
        name: httpd 
        state: latest 
      become: True 
      when: ansible_os_family == 'RedHat' 
    - name: Ensure the apache2 package is updated 
      apt: 
        name: apache2 
        state: latest 
      become: True 
      when: ansible_os_family == 'Debian' 
..
```

**when 연산자는 변수도 설정할 수 있다. (파리미터: --extra-vars="변수내용")**

```yaml
--- 
- hosts: all 
  remote_user: vagrant
  vars: 
    backup: True 
  tasks: 
    - name: Copy the crontab in tmp if the backup variable is true 
      copy: 
        src: /etc/crontab 
        dest: /tmp/crontab 
        remote_src: True 
      when: backup 
```

**변수를 사용할때는 반드시 선언되어 있는지 확인해야 한다. (예시. when: 변수 is not defined or 변수 == "")**

```yaml
--- 
- hosts: all 
  remote_user: ansible 
  vars: 
    backup: True 
  tasks: 
    - name: Check if the backup_folder is set 
      fail: 
        msg: 'The backup_folder needs to be set' 
      when: backup_folder is not defined or backup_folder == “” 
    - name: Copy the crontab in tmp if the backup variable is true 
      copy: 
        src: /etc/crontab 
        dest: '{{ backup_folder }}/crontab' 
        remote_src: True 
      when: backup 
```

**다른 코드를 재사용해서 유지관리하기 쉬운 코드를 작성할 수 있음.**

```yaml
- inclode: FILENAME.yaml
- inclode: FILENAME.yaml variable1="value1" variable2="value2"
```

### 핸들러 작업

* 복잡한 배포 처리 | 4/26 구간 완료 | 15% | [(link)](https://subscription.packtpub.com/book/cloud-and-networking/9781789954333/6/ch06lvl1sec36/working-with-handlers)

- notify 에 해당하면 핸들러 작업은 플레이북 끝에서 실행됩니다.
  - why? 구성을 변경할때 마다 재시작하는 것이 아니라 미자막에만 1번 재시작도록 설정한다 


### 프로젝트 구성

[(link)](https://subscription.packtpub.com/book/cloud-and-networking/9781789954333/6/ch06lvl1sec38/organizing-a-project)

```
    ├── ansible.cfg        : 폴더 구조에서 파일을 찾을 수 있는 위치를 Ansible에 설명하는 작은 구성 파일
    ├── hosts              : 이전 장에서 이미 본 호스트 파일
    ├── master.yaml        : 전체 인프라를 정렬하는 플레이북
    ├── playbooks          : 플레이북과 그룹 ​​관리용 폴더가 포함됩니다. 한번만 실행함
    │   ├── firstrun.yaml
    │   └── groups
    │       ├── database.yaml
    │       └── webserver.yaml
    └── roles               : 여기에는 필요한 모든 역할이 포함됩니다.
        ├── common          : 모든 서버에 대해 수행되어야 하는 모든 작업
        │   └── tasks       : roles의 필수 폴더
        |       └── main.yaml : 실행할 작업 목록이 될 파일
        │   └── templates   : 템플릿을 저장
        |       └── motd    : 사용되는 파일을 저장
        ├── database
        │   └── tasks
        |       └── main.yaml
        └── webserver

```



```
    ├── ansible.cfg        : 폴더 구조에서 파일을 찾을 수 있는 위치를 Ansible에 설명하는 작은 구성 파일
    ├── hosts              : 이전 장에서 이미 본 호스트 파일
    ├── master.yaml        : 전체 인프라를 정렬하는 플레이북(import_playbook)
    ├── playbooks          : 플레이북과 그룹 ​​관리용 폴더가 포함됩니다. 한번만 실행함
    │   ├── firstrun.yaml
    │   └── groups
    │       ├── database.yaml
    │       └── webserver.yaml
    └── roles               : 여기에는 필요한 모든 역할이 포함됩니다.
        ├── common          : 모든 서버에 대해 수행되어야 하는 모든 작업
        │   └── tasks       : roles의 필수 폴더
        |       └── main.yaml : 실행할 작업 목록이 될 파일
        │   └── templates   : 템플릿을 저장
        |       └── motd    : 사용되는 파일을 저장
        ├── database
        │   └── tasks
        |       └── main.yaml
        └── webserver

```

**import_playbook - 실행해야할 파일이 많은 경우 순서를 지정할 수 있다.**

* 문법: 순서대로 %%import_playbook: playbook yaml 파일 경로%%
* 주의
  * import_playbook 작업이 실패하면 다음 import_playbook 은 실행되지 않는다.
 
**사용 예시**
```bash
[opc@instance-20220112-0945 Chapter04]$ cat master.yaml 
--- 
- import_playbook: playbooks/groups/database.yaml 
- import_playbook: playbooks/groups/webserver.yaml 
[opc@instance-20220112-0945 Chapter04]$ cat playbooks/groups/database.yaml
--- 
- hosts: database 
  user: vagrant 
  roles: 
  - common 
[opc@instance-20220112-0945 Chapter04]$ cat playbooks/groups/webserver.yaml

--- 
- hosts: webserver 
  user: vagrant 
  roles: 
  - common 
  - webserver
[opc@instance-20220112-0945 Chapter04]$ ansible-playbook master.yaml 

PLAY [database] ************************************************************************************
TASK [Gathering Facts] *****************************************************************************ok: [db01.fale.io]
..
```


### ansible 보안관리

* Ansible Vault: 코드 일부를 비밀번호로 암호화

```bash
[opc@instance-20220112-0945 Chapter04]$ echo 'ansible' > .password 
[opc@instance-20220112-0945 Chapter04]$ ansible-vault create secret.yaml
New Vault password: 
Confirm New Vault password: 
=> test 입력
[opc@instance-20220112-0945 Chapter04]$ cat ./secret.yaml
$ANSIBLE_VAULT;1.1;AES256
66653838313932613231346665653662343334396361343333346332623733313533333238323062
3435373332626463393837363239663530653161663562320a356666623932356461316339643238
61626334333964616131663832303133376233356637373836306666383832326362653039653766
6130313033653738310a336631363037666130383236333963346565623362616337336161376261
6463
[opc@instance-20220112-0945 Chapter04]$
[opc@instance-20220112-0945 Chapter04]$ ansible-vault view --vault-password-file .password secret.yaml
test
[opc@instance-20220112-0945 Chapter04]$ ansible-vault decrypt --vault-password-file .password secret.yaml
Decryption successful
[opc@instance-20220112-0945 Chapter04]$ cat ./secret.yaml
test
[opc@instance-20220112-0945 Chapter04]$ 
[opc@instance-20220112-0945 Chapter04]$ ansible-vault encrypt --vault-password-file .password secret.yaml
Encryption successful
[opc@instance-20220112-0945 Chapter04]$ cat ./secret.yaml
$ANSIBLE_VAULT;1.1;AES256
61626637663335646664373532363435316436653335626431306437653965363338363536653938
3835666635316338393632393534666335353464666466360a343762393464303138363037343935
32306637653834313631393262613363613830316462336432333434313830643634613562323131
3131343563343436620a663761323733623664336463376439383264383535653862373439623639
6433
[opc@instance-20220112-0945 Chapter04]$ 
[opc@instance-20220112-0945 Chapter04]$ echo 'ansible2' > .newpassword 
[opc@instance-20220112-0945 Chapter04]$ ansible-vault rekey --vault-password-file .password  --new-vault-password-file .newpassword secret.yaml
Rekey successful
[opc@instance-20220112-0945 Chapter04]$ ansible-vault view --vault-password-file .password secret.yaml^C
[opc@instance-20220112-0945 Chapter04]$ cat ./secret.yaml
$ANSIBLE_VAULT;1.1;AES256
32343136353563313765623162613138373464383938303438313663633130323163313337616466
3564343265366666613030336164666261653333396334340a373937383430373631386238373764
61643132323366623736313566306134653635633139656539313832646663376239356463356436
3834633234333430320a636265326135393237353962383231633235396536386232623030626462
3032
[opc@instance-20220112-0945 Chapter04]$ ansible-vault view --vault-password-file .password secret.yaml
ERROR! Decryption failed (no vault secrets were found that could decrypt) on secret.yaml for secret.yaml
[opc@instance-20220112-0945 Chapter04]$ ansible-vault view --vault-password-file .newpassword secret.yaml
test
[opc@instance-20220112-0945 Chapter04]$ 
```

### 인프라 프로비저닝에서 ansible

* 감사 추적을 위한 서버 생성부터 현재까지 서버 이력 확인
* 다중 스테이징 환경에 서버를 프로비저닝에 도움
* 글로벌 클라우드간 서버 이동


### httpd 재시작하는 동안 Nagios httpd 모니터링을 중지하는 예시  

```yaml
---
- hosts: ws01.fale.io 
  tasks: 
    - name: Mute Nagios 
      nagios: 
        action: disable_alerts 
        service: httpd 
        host: '{{ inventory_hostname }}' 
      delegate_to: nagios.fale.io 
    - name: Stop the HTTPd service 
      service: 
        name: httpd 
        state: stopped 
    - name: Wait for 5 minutes 
      pause: 
        minutes: 5 
    - name: Start the HTTPd service 
      service: 
        name: httpd 
        state: stopped 
    - name: Unmute Nagios 
      nagios: 
        action: enable_alerts 
        service: httpd 
        host: '{{ inventory_hostname }}' 
      delegate_to: nagios.fale.io
```



### 사용자 모듈

* ./Learning-Ansible-2.X-Third-Edition-master/Chapter07

```
├── ansible.cfg                    : 라이브러리 선언
├── library
│   ├── check_user.py
│   ├── check_user_id.py
│   ├── check_user_py2.py
│   ├── check_user_py3.py
│   ├── kill_java.sh
│   ├── rsync.rb
│   └── test_check_user_id.py
└── playbooks
    ├── check_user.yaml
    ├── check_user_id.yaml
    └── check_user_py2.yaml
    
## ansible.cfg 
[defaults]
library=library
## ./playbooks/check_user_id.yaml 
---
- hosts: localhost
  connection: local
  vars:
    user: root
  tasks:
    - name: 'Retrive {{ user }} data if it exists'
      check_user_id:
        user: '{{ user }}'
      register: user_data
    - name: 'Print user {{ user }} data'
      debug:
        msg: '{{ user_data }}'
```

## 디버그와 에러 핸들러

```
├── ansible.cfg
├── hosts
├── playbooks
│   ├── assert_ls.yaml
│   ├── hosts
│   │   └── ws01.yaml
│   ├── maven_build.yaml
│   ├── setup_and_config_apache.yaml
│   ├── setup_apache.yaml
│   └── tags_example.yaml
├── roles
│   └── java
│       └── tasks
│           └── main.yaml
├── templates
│   └── userdir.conf
└── Vagrantfile
```

* --syntax-check : 문법에 맞는 파일인지 체크
* --check : 실제 설치 등 변경을 하지 않고 예상되는 결과를 보여줌 
* --diff : playbook 파일 설정 변경 사항을 표시함, --check 와 함께 사용 (+는 추가, -는 삭제)

```bash
[opc@instance-20220112-0945 Chapter08]$ cat playbooks/setup_and_config_apache_test.yaml
- hosts: all
  tasks: 
    - name: Install Apache 
      yum: 
        name: httpd 
        state: present 
      become: True
    - name: Enable Apache 
      service: 
        name: httpd 
        state: started 
        enabled: True 
      become: True
    - name: Ensure Apache userdirs are properly configured
      template:
        src: ../templates/userdir.conf
        dest: /etc/httpd/conf.d/userdir.conf
      become: True
[opc@instance-20220112-0945 Chapter08]$ ansible-playbook -i ws01.fale.io, -u ansible playbooks/setup_and_config_apache_test.yaml --diff --check

PLAY [all] *****************************************************************************************
TASK [Gathering Facts] *****************************************************************************ok: [ws01.fale.io]

TASK [Install Apache] ******************************************************************************ok: [ws01.fale.io]

TASK [Enable Apache] *******************************************************************************ok: [ws01.fale.io]

TASK [Ensure Apache userdirs are properly configured] **********************************************--- before: /etc/httpd/conf.d/userdir.conf
+++ after: /home/opc/.ansible/tmp/ansible-local-29291647gGWql/tmp2lT3Gp/userdir.conf
@@ -14,7 +14,7 @@
     # of a username on the system (depending on home directory
     # permissions).
     #
-    UserDir disabled
+    UserDir enabled
 
     #
     # To enable requests to /~user/ to serve the user's public_html

changed: [ws01.fale.io]

PLAY RECAP *****************************************************************************************ws01.fale.io               : ok=4    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   

[opc@instance-20220112-0945 Chapter08]$
```



```
├── ansible.cfg
├── hosts
├── playbooks
│   ├── assert_ls.yaml
│   ├── hosts
│   │   └── ws01.yaml
│   ├── maven_build.yaml
│   ├── setup_and_config_apache_test.yaml
│   ├── setup_and_config_apache.yaml
│   ├── setup_apache_test.yaml
│   ├── setup_apache.yaml
│   └── tags_example.yaml
├── roles
│   └── java
│       └── tasks
│           └── main.yaml
├── templates
│   └── userdir.conf
└── Vagrantfile


# ansible.cfg
[defaults]
inventory = hosts 
host_key_checking = False 
roles_path = roles 
remote_user=ansible

# hosts 
ws01


# laybooks/tags_example.yaml
- hosts: all
  tasks: 
    - name: Ensure the file /tmp/ok exists 
      file: 
        name: /tmp/ok 
        state: touch 
      tags: 
        - file_present 
    - name: Ensure the file /tmp/ok does not exists 
      file: 
        name: /tmp/ok 
        state: absent 
      tags: 
        - file_absent

ansible-playbook -u ansible -i ws01, playbooks/tags_example.yaml --list-tasks
ansible-playbook -u ansible -i ws01, playbooks/tags_example.yaml -t file_present
ansible-playbook -u ansible -i ws01, playbooks/tags_example.yaml --skip-tags file_present  


# playbooks/hosts/ws01.yaml
- hosts: ws01
  roles: 
    - java 

ansible-playbook playbooks/hosts/ws01.yaml

# playbooks/maven_build.yaml 
- hosts: all
  tasks: 
    - name: Ensure the tag variable is properly set
      fail: 'The version needs to be defined. To do so, please add: --extra-vars "version=$[TAG/BRANCH]"' 
      when: version is not defined 
    - name: Get last Project version 
      git: 
        repo: https://github.com/org/project.git 
        dest: "/tmp" 
        version: '{{ version }}' 
    - name: Maven clean install 
      shell: "cd /tmp/project && mvn clean install" 
```


```
https://github.com/PacktPublishing/Learning-Ansible-2.X-Third-Edition/tree/master/Chapter09
cd ./Learning-Ansible-2.X-Third-Edition-master/Chapter09

Development -> Testing -> Stage -> Production 

├── ansible.cfg
├── inventory
│   ├── group_vars
│   │   ├── all
│   │   ├── production
│   │   └── staging
│   ├── production
│   └── staging
├── playbooks
│   ├── groups
│   │   ├── builders.yaml
│   │   └── web.yaml
│   ├── manual
│   │   ├── hello_deploy.yaml
│   │   ├── rcs_deploy.yaml
│   │   └── rpm_deploy.yaml
│   └── variables.yaml
├── roles
│   ├── builder
│   │   ├── files
│   │   │   └── repo.conf
│   │   ├── handlers
│   │   │   └── main.yaml
│   │   └── tasks
│   │       └── main.yaml
│   ├── common
│   │   ├── tasks
│   │   │   └── main.yaml
│   │   └── templates
│   │       └── motd
│   └── webserver
│       ├── files
│       │   ├── privaterepo.repo
│       │   └── website.conf
│       ├── handlers
│       │   └── main.yaml
│       ├── tasks
│       │   └── main.yaml
│       └── templates
│           └── index.html.j2
├── spec
│   ├── demo-php-app.spec
│   └── hello-worls.spec
└── Vagrantfile
```

### Chapter09 실습환경 구성 - Vagrantfile

```
#!/bin/bash

# create centos containers
docker run -d --privileged --name ws01 zasfe/centos:7-systemd-vagrant /usr/sbin/init
docker run -d --privileged --name ws02 zasfe/centos:7-systemd-vagrant /usr/sbin/init
docker run -d --privileged --name db01 zasfe/centos:7-systemd-vagrant /usr/sbin/init
docker run -d --privileged --name ws01s zasfe/centos:7-systemd-vagrant /usr/sbin/init
docker run -d --privileged --name ws02s zasfe/centos:7-systemd-vagrant /usr/sbin/init
docker run -d --privileged --name db01s zasfe/centos:7-systemd-vagrant /usr/sbin/init
docker run -d --privileged --name builder01 zasfe/centos:7-systemd-vagrant /usr/sbin/init

echo "`docker inspect -f "\{{ .NetworkSettings.IPAddress }}" ws01` ws01.fale.io ws01" | sudo tee -a /etc/hosts
echo "`docker inspect -f "\{{ .NetworkSettings.IPAddress \}}" ws02` ws02.fale.io ws02" | sudo tee -a /etc/hosts
echo "`docker inspect -f "{{ .NetworkSettings.IPAddress }}" db01` db01.fale.io db01" | sudo tee -a /etc/hosts
echo "`docker inspect -f "{{ .NetworkSettings.IPAddress }}" ws01s` ws01.staging.fale.io ws01s" | sudo tee -a /etc/hosts
echo "`docker inspect -f "{{ .NetworkSettings.IPAddress }}" ws02s` ws02.staging.fale.io ws02s" | sudo tee -a /etc/hosts
echo "`docker inspect -f "{{ .NetworkSettings.IPAddress }}" db01s` db01.staging.fale.io db01s" | sudo tee -a /etc/hosts
echo "`docker inspect -f "{{ .NetworkSettings.IPAddress }}" builder01` builder01.fale.io builder01" | sudo tee -a /etc/hosts

ssh-keygen -R ws01.fale.io
ssh-keygen -R ws02.fale.io
ssh-keygen -R db01.fale.io
ssh-keygen -R ws01s.fale.io
ssh-keygen -R ws02s.fale.io
ssh-keygen -R db01s.fale.io
ssh-keygen -R builder01.fale.io

docker exec -u 0 ws01 /bin/bash -c "rm -f /run/nologin"
docker exec -u 0 ws02 /bin/bash -c "rm -f /run/nologin"
docker exec -u 0 db01 /bin/bash -c "rm -f /run/nologin"
docker exec -u 0 ws01s /bin/bash -c "rm -f /run/nologin"
docker exec -u 0 ws02s /bin/bash -c "rm -f /run/nologin"
docker exec -u 0 db01s /bin/bash -c "rm -f /run/nologin"
docker exec -u 0 builder01 /bin/bash -c "rm -f /run/nologin"

docker exec -u 0 ws01 /bin/bash -c "yum install -y epel-release; yum update -y; yum install -y iproute net-tools openssh-server sudo firwalld python-firewal; yum clean all;"
docker exec -u 0 ws02 /bin/bash -c "yum install -y epel-release; yum update -y; yum install -y iproute net-tools openssh-server sudo firwalld python-firewal; yum clean all;"
docker exec -u 0 db01 /bin/bash -c "yum install -y epel-release; yum update -y; yum install -y iproute net-tools openssh-server sudo firwalld python-firewal; yum clean all;"
docker exec -u 0 ws01s /bin/bash -c "yum install -y epel-release; yum update -y; yum install -y iproute net-tools openssh-server sudo firwalld python-firewal; yum clean all;"
docker exec -u 0 ws02s /bin/bash -c "yum install -y epel-release; yum update -y; yum install -y iproute net-tools openssh-server sudo firwalld python-firewal; yum clean all;"
docker exec -u 0 db01s /bin/bash -c "yum install -y epel-release; yum update -y; yum install -y iproute net-tools openssh-server sudo firwalld python-firewal; yum clean all;"
docker exec -u 0 builder01 /bin/bash -c "yum install -y epel-release; yum update -y; yum install -y iproute net-tools openssh-server sudo firwalld python-firewal; yum clean all;"


sshpass -p vagrant ssh-copy-id -f -i ~/.ssh/id_rsa -o StrictHostKeyChecking=no vagrant@ws01.fale.io
sshpass -p vagrant ssh-copy-id -f -i ~/.ssh/id_rsa -o StrictHostKeyChecking=no vagrant@ws02.fale.io
sshpass -p vagrant ssh-copy-id -f -i ~/.ssh/id_rsa -o StrictHostKeyChecking=no vagrant@db01.fale.io
sshpass -p vagrant ssh-copy-id -f -i ~/.ssh/id_rsa -o StrictHostKeyChecking=no vagrant@ws01.staging.fale.io
sshpass -p vagrant ssh-copy-id -f -i ~/.ssh/id_rsa -o StrictHostKeyChecking=no vagrant@ws02.staging.fale.io
sshpass -p vagrant ssh-copy-id -f -i ~/.ssh/id_rsa -o StrictHostKeyChecking=no vagrant@db01.staging.fale.io
sshpass -p vagrant ssh-copy-id -f -i ~/.ssh/id_rsa -o StrictHostKeyChecking=no vagrant@builder01.fale.io

sshpass -p vagrant ssh-copy-id -f -i ~/.ssh/id_rsa -o StrictHostKeyChecking=no vagrant@ws01
sshpass -p vagrant ssh-copy-id -f -i ~/.ssh/id_rsa -o StrictHostKeyChecking=no vagrant@ws02
sshpass -p vagrant ssh-copy-id -f -i ~/.ssh/id_rsa -o StrictHostKeyChecking=no vagrant@db01
sshpass -p vagrant ssh-copy-id -f -i ~/.ssh/id_rsa -o StrictHostKeyChecking=no vagrant@ws01s
sshpass -p vagrant ssh-copy-id -f -i ~/.ssh/id_rsa -o StrictHostKeyChecking=no vagrant@ws02s
sshpass -p vagrant ssh-copy-id -f -i ~/.ssh/id_rsa -o StrictHostKeyChecking=no vagrant@db01s
sshpass -p vagrant ssh-copy-id -f -i ~/.ssh/id_rsa -o StrictHostKeyChecking=no vagrant@builder01

# ansible.cfg 
[defaults] 
inventory = hosts 
host_key_checking = False 
roles_path = roles 
```

### Chapter09 실습 로그

```
# ./playbooks/variables.yaml
- hosts: web 
  user: vagrant 
  tasks: 
    - name: Print environment name 
      debug: 
        var: env 
    - name: Print db server url 
      debug: 
        var: db_url 
    - name: Print domain url 
      debug: 
        var: domain 
- hosts: db 
  user: vagrant 
  tasks: 
    - name: Print environment name 
      debug: 
        var: env 
    - name: Print database username 
      debug: 
        var: db_user 
    - name: Print database password 
      debug: 
        var: db_pass 

# ./inventory/production 
[web] 
ws01.fale.io 
ws02.fale.io 
 
[db] 
db01.fale.io 


[builders] 
builder01.fale.io 
 
[production:children] 
db 
web 
builders

# ./inventory/staging 
[web] 
ws01.staging.fale.io 
ws02.staging.fale.io 
 
[db] 
db01.staging.fale.io 
 
[staging:children] 
db 
web 

# ./inventory/group_vars/production 
env: production 
domain: fale.io 
db_url: db.fale.io 
db_pass: this_is_a_safe_password 

# playbooks/variables.yaml
- hosts: web 
  user: vagrant 
  tasks: 
    - name: Print environment name 
      debug: 
        var: env 
    - name: Print db server url 
      debug: 
        var: db_url 
    - name: Print domain url 
      debug: 
        var: domain 
- hosts: db 
  user: vagrant 
  tasks: 
    - name: Print environment name 
      debug: 
        var: env 
    - name: Print database username 
      debug: 
        var: db_user 
    - name: Print database password 
      debug: 
        var: db_pass 

ansible-playbook -i inventory/staging playbooks/variables.yaml
ansible-playbook -i inventory/production playbooks/variables.yaml  


# playbooks/groups/web.yaml 
- hosts: web 
  user: vagrant
  roles: 
    - common 
    - webserver 

# roles/common/tasks/main.yaml 
---
- name: Ensure EPEL is enabled 
  yum: 
    name: epel-release 
    state: present 
  become: True 
- name: Ensure libselinux-python is present 
  yum: 
    name: libselinux-python 
    state: present 
  become: True 
- name: Ensure libsemanage-python is present 
  yum: 
    name: libsemanage-python 
    state: present 
  become: True 
..

# roles/webserver/tasks/main.yaml
--- 
- name: Ensure the HTTPd package is installed 
  yum: 
    name: httpd 
    state: present 
  become: True 
- name: Ensure the HTTPd service is enabled and running 
  service: 
    name: httpd 
    state: started 
    enabled: True 
  become: True 
- name: Ensure HTTPd configuration is updated 
  copy: 
    src: website.conf 
    dest: /etc/httpd/conf.d 
  become: True 
  notify: Restart HTTPd 
- name: Ensure the website is present and updated 
  template: 
    src: index.html.j2 
    dest: /var/www/html/index.html 
    owner: root 
    group: root 
    mode: 0644 
  become: True 
- name: Install our private repository
  copy:
    src: privaterepo.repo
    dest: /etc/yum.repos.d/privaterepo.repo
  become: True

# roles/webserver/handlers/main.yaml
--- 
- name: Restart HTTPd 
  service: 
    name: httpd 
    state: restarted 
  become: True 


ansible-playbook -i inventory/production playbooks/groups/web.yaml  
```


```
cd ./Learning-Ansible-2.X-Third-Edition-master/Chapter09

# ./playbooks/manual/rcs_deploy.yaml 
- hosts: web 
  user: vagrant 
  tasks:
    - name: Ensure git is installed
      yum:
        name: git
        state: present 
      become: True
    - name: Install or update website 
      git: 
        repo: https://github.com/Fale/demo-php-app.git 
        dest: /var/www/application 
      become: True 

ansible-playbook -i inventory/production playbooks/manual/rcs_deploy.yaml  

# roles/webserver/files/website.conf
<VirtualHost *:80> 
    ServerName app.fale.io 
    DocumentRoot /var/www/application 
    <Directory /var/www/application> 
        Options None 
    </Directory> 
    <DirectoryMatch ".git*"> 
        Require all denied 
    </DirectoryMatch> 
</VirtualHost> 

ansible-playbook -i inventory/production playbooks/groups/web.yaml  

```


### RPM 패키지를 사용하여 웹 앱 배포

RPM 패키지를 사용하여 웹 앱 배포 [(packtpub)](https://subscription.packtpub.com/book/cloud-and-networking/9781789954333/12/ch12lvl1sec97/deploying-a-web-app-with-rpm-packages)


```
cd Learning-Ansible-2.X-Third-Edition-master/Chapter09

# spec/demo-php-app.spec 
%define debug_package %{nil}   <== 디버그 패키지 생성하지 않음
%global commit0 b49f595e023e07a8345f47a3ad62a6f50f03121e <== 커밋 해시를 commit0 변수에 지정
%global shortcommit0 %(c=%{commit0}; echo ${c:0:7}) <== 처음 문자 8자리만 변수에 지정
 
Name:       demo-php-app 
Version:    0                                   <== 업스트림 버전
Release:    1%{?dist}                           <== 업스트림 릴리스에 대한 SPEC 버전
Summary:    Demo PHP application 
 
License:    PD                                  <== 원본 라이센스
URL:        https://github.com/Fale/demo-php-app  <== 업스트림 웹사이트
Source0:    %{url}/archive/%{commit0}.tar.gz#/%{name}-%{shortcommit0}.tar.gz 
 
%description 
This is a demo PHP application in RPM format 
 
%prep                                           <== 소스 압축, 해제, 적용 단계
%autosetup -n %{name}-%{commit0} 
 
%build                                          <== 컴파일 단계
 
%install 
mkdir -p %{buildroot}/var/www/application 
ls -alh 
cp index.php %{buildroot}/var/www/application 
 
%files                                           <== 패키지에 넣을 파일 선언
%dir /var/www/application 
/var/www/application/index.php 
 
%changelog                                      <== 변경사항
* Sun Feb 24 2019 Fabio Alessandro Locati - 0.1 
- Initial packaging 
```

* RPM 소프트웨어를 구축하는 방법
  * 수동으로 RPM 구축 - 간단, 사람 실수 여지있음. 오류 확인 어려움.
    * Fedora 또는 EL(Red Hat Enterprise Linux, CentOS, Scientific Linux, Oracle Enterprise Linux) 시스템 필요
  * Ansible로 수동 방식을 자동화하세요 - 
  * Jenkins
  * Koji

### 수동으로 RPM 구축

```
# Fedora
sudo dnf install -y fedora-packager

# EL(Red Hat Enterprise Linux, CentOS, Scientific Linux, Oracle Enterprise Linux)
sudo yum install -y mock rpm-build spectool

# 공통
sudo usermod -a -G mock [yourusername]

mkdir -p ~/rpmbuild/SOURCES  
spectool -R -g demo-php-app.spec  
rpmbuild -bs demo-php-app.spec

# Result: Wrote: /home/fale/rpmbuild/SRPMS/demo-php-app-0-1.fc28.src.rpm

mock -r epel-7-x86_64 /home/fale/rpmbuild/SRPMS/demo-php-app-0-1.fc28.src.rpm  
```

### Ansible로 RPM 구축 자동화

```
# inventory/production
[web] 
ws01.fale.io 
ws02.fale.io 
 
[db] 
db01.fale.io 


[builders] 
builder01.fale.io 
 
[production:children] 
db 
web 
builders


# roles/webserver/tasks/main.yaml
--- 
- name: Ensure the HTTPd package is installed 
  yum: 
    name: httpd 
    state: present 
  become: True 
- name: Ensure the HTTPd service is enabled and running 
  service: 
    name: httpd 
    state: started 
    enabled: True 
  become: True 
- name: Ensure HTTPd configuration is updated 
  copy: 
    src: website.conf 
    dest: /etc/httpd/conf.d 
  become: True 
  notify: Restart HTTPd 
- name: Ensure the website is present and updated 
  template: 
    src: index.html.j2 
    dest: /var/www/html/index.html 
    owner: root 
    group: root 
    mode: 0644 
  become: True 
- name: Install our private repository
  copy:
    src: privaterepo.repo
    dest: /etc/yum.repos.d/privaterepo.repo
  become: True

# roles/webserver/files/privaterepo.repo
[privaterepo] 
name=Private repo that will keep our apps packages 
baseurl=http://repo.fale.io/ 
skip_if_unavailable=True 
gpgcheck=0 
enabled=1 
enabled_metadata=1 

# ansible-playbook -i inventory/production playbooks/groups/web.yaml --list-hosts --list-tasks

playbook: playbooks/groups/web.yaml

  play #1 (web): web    TAGS: []
    pattern: [u'web']
    hosts (2):
      ws02.fale.io
      ws01.fale.io
    tasks:
      common : Ensure EPEL is enabled   TAGS: []
      common : Ensure libselinux-python is present      TAGS: []
      common : Ensure libsemanage-python is present     TAGS: []
      common : Ensure we have last version of every package     TAGS: []
      common : Ensure NTP is installed  TAGS: []
      common : Ensure the timezone is set to UTC        TAGS: []
      common : Ensure the NTP service is running and enabled    TAGS: []
      common : Ensure the MOTD file is present and updated      TAGS: []
      webserver : Ensure the HTTPd package is installed TAGS: []
      webserver : Ensure the HTTPd service is enabled and running       TAGS: []
      webserver : Ensure HTTPd configuration is updated TAGS: []
      webserver : Ensure the website is present and updated     TAGS: []
      webserver : Install our private repository        TAGS: []

ansible-playbook -i inventory/production playbooks/groups/web.yaml

# roles/builder/tasks/main.yaml 
- name: Ensure needed packages are present 
  yum: 
    name: '{{ item }}' 
    state: present 
  become: True 
  with_items: 
    - mock 
    - rpm-build 
    - spectool 
    - createrepo 
    - httpd 
 
- name: Ensure the user ansible is in the mock group 
  user: 
    name: ansible 
    groups: mock 
    append: True 
  become: True 
 
- name: Ensure the /var/www/repo folder is present 
  file: 
    name: /var/www/repo 
    state: directory 
    group: ansible 
    owner: ansible 
    mode: 0755 
  become: True 
 
- name: Ensure the HTTPd zone for the repo is present 
  copy: 
    src: repo.conf 
    dest: /etc/httpd/conf.d/repo.conf 
  become: True 
  notify: Restart HTTPd 
 
- name: Ensure the HTTPd service is enabled and running 
  service: 
    name: httpd 
    state: started 
    enabled: True 
  become: True 
 
# roles/builder/files/repo.conf 
<VirtualHost *:80> 
    ServerName repo.fale.io 
    DocumentRoot /var/www/repo 
    <Directory /var/www/repo> 
        Options Indexes FollowSymLinks 
    </Directory> 
</VirtualHost> 

# playbooks/groups/builders.yaml
- hosts: builders 
  user: vagrant
  roles: 
    - common 
    - builder 

# ansible-playbook -i inventory/production playbooks/groups/builders.yaml --list-host --list-tasks

playbook: playbooks/groups/builders.yaml

  play #1 (builders): builders  TAGS: []
    pattern: [u'builders']
    hosts (1):
      builder01.fale.io
    tasks:
      common : Ensure EPEL is enabled   TAGS: []
      common : Ensure libselinux-python is present      TAGS: []
      common : Ensure libsemanage-python is present     TAGS: []
      common : Ensure we have last version of every package     TAGS: []
      common : Ensure NTP is installed  TAGS: []
      common : Ensure the timezone is set to UTC        TAGS: []
      common : Ensure the NTP service is running and enabled    TAGS: []
      common : Ensure the MOTD file is present and updated      TAGS: []
      builder : Ensure needed packages are present      TAGS: []
      builder : Ensure the user ansible is in the mock group    TAGS: []
      builder : Ensure the /var/www/repo folder is present      TAGS: []
      builder : Ensure the HTTPd zone for the repo is present   TAGS: []
      builder : Ensure the HTTPd service is enabled and running TAGS: []


ansible-playbook -i inventory/production playbooks/groups/builders.yaml


# playbooks/manual/rpm_deploy.yaml
- hosts: builders 
  user: vagrant 
  tasks: 
    - name: Copy SPEC file to user folder 
      copy: 
        src: ../../spec/demo-php-app.spec 
        dest: /home/vagrant
    - name: Ensure rpmbuild exists 
      file: 
        name: ~/rpmbuild 
        state: directory 
    - name: Ensure rpmbuild/SOURCES exists 
      file: 
        name: ~/rpmbuild/SOURCES 
        state: directory 
    - name: Download the sources 
      command: spectool -R -g demo-php-app.spec 
    - name: Ensure no SRPM files are present 
      command: rm -f ~/rpmbuild/SRPMS/* 
    - name: Build the SRPM file 
      command: rpmbuild -bs demo-php-app.spec 
    - name: Execute mock 
      shell: mock ~/rpmbuild/SRPMS/* 
    - name: Copy the arch binaries in the repo path 
      shell: cp -f /var/lib/mock/epel-7-x86_64/result/*.x86_64.rpm /var/www/repo 
    - name: Recreate the repo metadata 
      command: createrepo --database /var/www/repo 
- hosts: web 
  user: vagrant 
  tasks: 
    - name: Ensure last version of demo-php-app is present 
      yum: 
        state: latest 
        update_cache: True 
        disable_gpg_check: True 
        name: demo-php-app 
      become: True 


## ansible-playbook -i inventory/production playbooks/manual/rpm_deploy.yaml --list-hosts --list-tasks

playbook: playbooks/manual/rpm_deploy.yaml

  play #1 (builders): builders  TAGS: []
    pattern: [u'builders']
    hosts (1):
      builder01.fale.io
    tasks:
      Copy SPEC file to user folder     TAGS: []
      Ensure rpmbuild exists    TAGS: []
      Ensure rpmbuild/SOURCES exists    TAGS: []
      Download the sources      TAGS: []
      Ensure no SRPM files are present  TAGS: []
      Build the SRPM file       TAGS: []
      Execute mock      TAGS: []
      Copy the arch binaries in the repo path   TAGS: []
      Recreate the repo metadata        TAGS: []

  play #2 (web): web    TAGS: []
    pattern: [u'web']
    hosts (2):
      ws02.fale.io
      ws01.fale.io
    tasks:
      Ensure last version of demo-php-app is present    TAGS: []

```

### 배포 전략

* Canary 배포 - 초기 5% 체크 후 점진적 확대 => 인벤토리 파일내 정규식으로 구분하는 것
* Blue/Green 배포 - 동시 적용, 두배 자원 필요 => 서로다른 인벤토리 파일 구성

### 최적화

* 파이프라이닝: 작업마다 Ansible이 새 연결을 시도하는 것을 연결유지하도록 설정
  * sudo 가 필요한 경우 충돌이 발생하여 플레이북이 실패함
* with_items 최적화: 유사한 작업을 반복하도록 설정



```
# ansible.cfg
pipelining=True # 파이프라이닝
```


### Windows에서의 앤서블 - Windows 원격 관리 ( WinRM )

* Windows 원격 관리 ( WinRM ) 
  * 설명: https://learn.microsoft.com/en-in/windows/win32/winrm/portal
  * Ansible
    * pywinrm 0.3.0 이상,  `pip install "pywinrm>=0.3.0"`
  * Taget
    * WinRM 구성 예시 [ansible examples](https://github.com/ansible/ansible/blob/devel/examples/scripts/ConfigureRemotingForAnsible.ps1)
    * PowerShell 버전 3.0 이상 [설치 예시](https://github.com/cchurch/ansible/blob/devel/examples/scripts/upgrade_to_ps3.ps1)
    * Allow TCP 5986 port
	* 구성 확인: `curl -vk -d `` -u "$USER:$PASSWORD" "https://<IP>:5986/wsman"

* ansible-vault : 자격증명파일 활용


```
ansible-vault create group_vars/windows.yml  

Vault password:
Confirm Vault password: 


ansible_ssh_user: Administrator 
ansible_ssh_pass: <password> 
ansible_ssh_port: 5986 
ansible_connection: winrm 

# inventory
[windows] 
174.129.181.242 

ansible windows -i inventory -m win_ping --ask-vault-pass  

```

* https://docs.ansible.com/ansible/latest/collections/community/windows/index.html


### Ansible Galaxy

* https://github.com/ansible/galaxy_ng
* https://galaxy-ng.readthedocs.io/

```
ansible-galaxy install username.rolename[,version]  
ansible-galaxy install username.rolename[,version] username.rolename[,version] 

cat <<EOF > requirements.txt
user1.rolename,v1.0.0 
user2.rolename,v1.1.0 
user3.rolename,v1.2.1 
EOF
ansible-galaxy install -r requirements.txt  

#### ex)
ansible-galaxy install geerlingguy.apache  
cat <<EOF > playbooks/galaxy.yaml
- hosts: web 
  user: vagrant 
  become: True 
  roles: 
    - geerlingguy.apache 
EOF

# /home/opc/Learning-Ansible-2.X-Third-Edition-master/Chapter09/roles/geerlingguy.apache

ansible-playbook -i inventory playbooks/galaxy.yaml --list-hosts --list-tasks

```





## 문제해결

### Python Module not found: firewalld and its python module are required for this module

* 환경
  * OS: Oracle Linux Server release 7.9
  * APP: ansible 2.9.27(python version = 2.7.5)
* 증상: 방화벽 정책에서 http, https 정책 2개를 한꺼번에 설정하는 과정에 오류가 발생함
* 원인: firewalld 모듈이 없음
* 조치: python-firewall 설치
* 비고: Python 3.x 인 경우 python3-firewall 패키지 설치가 필요함


### 주요 방화벽 정책 추가 명령

```
sudo firewall-cmd --state
sudo firewall-cmd --list-all
sudo firewall-cmd --get-default-zone
sudo firewall-cmd --zone=public --add-port=38317/tcp --permanent
sudo firewall-cmd --reload
sudo firewall-cmd --runtime-to-permanent

sudo ufw status
sudo ufw allow from any to any port 38317 proto tcp

sudo iptables -A INPUT -p tcp -m state --state NEW -m tcp --dport 38317 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 38317 -j ACCEPT
sudo iptables-save

# Oracle Cloud - Ubuntu Firewall
sudo iptables -I INPUT 6 -m state --state NEW -p tcp --dport 38317 -j ACCEPT
sudo netfilter-persistent save
```

* [초보자를 위한 firewalld (rockylinux)](https://docs.rockylinux.org/ko/guides/security/firewalld-beginners/)


### oracle Cloud 방화벽 정책 변경 미적용

* 증상: Oracle Cloud 에서 Ubuntu 22.04 기본 이미지 서버를 사용할 때 Firewall 에서 포트를 허용해도 접속이 되지 않음
* 원인: iptable INPUT Chain에서 reject 하단으로 정책이 추가되어 허용되지 않음
* 조치: reject 상단에 정책을이 추가되도록 number 를 지정하여 정책추가함 <br> `sudo iptables -I INPUT [INPUT 정책에 추가할 위치 줄 번호] -m state --state NEW -p tcp --dport 80 -j ACCEPT`
* 비고: Oracle Cloud 네트워크 방화벽은 별도 허용해야함
* 참고
  * https://stackoverflow.com/questions/62326988/cant-access-oracle-cloud-always-free-compute-http-port


```bash
ubuntu@instance-20220913-1731:~$ sudo iptables -L --line-numbers
Chain INPUT (policy ACCEPT)
num  target     prot opt source               destination         
1    ACCEPT     all  --  anywhere             anywhere             state RELATED,ESTABLISHED
2    ACCEPT     icmp --  anywhere             anywhere            
3    ACCEPT     all  --  anywhere             anywhere            
4    ACCEPT     udp  --  anywhere             anywhere             udp spt:ntp
5    ACCEPT     tcp  --  anywhere             anywhere             state NEW tcp dpt:ssh
6    ACCEPT     tcp  --  anywhere             anywhere             state NEW tcp dpt:38317
7    REJECT     all  --  anywhere             anywhere             reject-with icmp-host-prohibited
8    ACCEPT     tcp  --  anywhere             anywhere             state NEW tcp dpt:38317

Chain FORWARD (policy ACCEPT)
num  target     prot opt source               destination         
1    REJECT     all  --  anywhere             anywhere             reject-with icmp-host-prohibited

Chain OUTPUT (policy ACCEPT)
num  target     prot opt source               destination         
1    InstanceServices  all  --  anywhere             link-local/16       

Chain InstanceServices (1 references)
num  target     prot opt source               destination   
..
```



**Role**

* 역할 = role
  * 컨텐츠를 그룹화하고 다른 사용자와 쉽게 공유하고 재사용이 용이하다
  * 목적에 따라서 역할을 정의할 수 있다
  * 큰 프로젝트를 관리하기 쉽게 해준다
* ansible 역할 구조
  * ansible-galaxy init
    * defualts
      * 재정의 하지 않을 변수들
    * files
    * handlers
    * meta
      * 작성자, 라이센스, role dependency 정보
    * tasks
    * templates
    * tests
    * var
* 변수 적용 우선순위
  * 글로벌
  * role call 변수
  * vars
  * playbook
  * inventory
  * defualt
* 실행 순서 제어
  * pre_tasks, post_tasks 를 통해서 role 수행 전/후로 추가 수행할 task 를 지정가능
* 역할 내용 개발을 위한 권장 사례
  * ansible-galaxy init 후에 필요없는 디렉터리, 파일 삭제
  * README.md, meta/main.yml 을 유지, 관리하고 사용법을 문서 한다
  * 역할은 특정 목적이나 기능에 집중한다
  * 역할은 자주 재사용하고 리팩토링 한다




