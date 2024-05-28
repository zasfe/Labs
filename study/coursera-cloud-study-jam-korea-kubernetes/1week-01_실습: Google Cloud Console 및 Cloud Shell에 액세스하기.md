
  * https://www.coursera.org/learn/google-kubernetes-engine-ko


```bash
Welcome to Cloud Shell! Type "help" to get started.
Your Cloud Platform project in this session is set to qwiklabs-gcp-04-c78f34fbb45d.
Use “gcloud config set project [PROJECT_ID]” to change to a different project.
student_01_d043cda5b3e1@cloudshell:~ (qwiklabs-gcp-04-c78f34fbb45d)$ MY_BUCKET_NAME_1=qwiklabs-gcp-04-c78f34fbb45d
student_01_d043cda5b3e1@cloudshell:~ (qwiklabs-gcp-04-c78f34fbb45d)$ MY_BUCKET_NAME_2=qwiklabs-gcp-04-c78f34fbb45d_2
student_01_d043cda5b3e1@cloudshell:~ (qwiklabs-gcp-04-c78f34fbb45d)$ MY_REGION=us-central1
student_01_d043cda5b3e1@cloudshell:~ (qwiklabs-gcp-04-c78f34fbb45d)$ ls
credentials.json  README-cloudshell.txt
student_01_d043cda5b3e1@cloudshell:~ (qwiklabs-gcp-04-c78f34fbb45d)$ gsutil mb gs://$MY_BUCKET_NAME_2
Creating gs://qwiklabs-gcp-04-c78f34fbb45d_2/...
student_01_d043cda5b3e1@cloudshell:~ (qwiklabs-gcp-04-c78f34fbb45d)$ gcloud compute zones list | grep $MY_REGION
NAME: us-central1-c
REGION: us-central1
NAME: us-central1-a
REGION: us-central1
NAME: us-central1-f
REGION: us-central1
NAME: us-central1-b
REGION: us-central1
student_01_d043cda5b3e1@cloudshell:~ (qwiklabs-gcp-04-c78f34fbb45d)$ MY_ZONE=us-central1-a
student_01_d043cda5b3e1@cloudshell:~ (qwiklabs-gcp-04-c78f34fbb45d)$ gcloud config set compute/zone $MY_ZONE
Updated property [compute/zone].
student_01_d043cda5b3e1@cloudshell:~ (qwiklabs-gcp-04-c78f34fbb45d)$ MY_VMNAME=second-vm
student_01_d043cda5b3e1@cloudshell:~ (qwiklabs-gcp-04-c78f34fbb45d)$ gcloud compute instances create $MY_VMNAME \
--machine-type "e2-standard-2" \
--image-project "debian-cloud" \
--image-family "debian-11" \
--subnet "default"

Created [https://www.googleapis.com/compute/v1/projects/qwiklabs-gcp-04-c78f34fbb45d/zones/us-central1-a/instances/second-vm].
NAME: second-vm
ZONE: us-central1-a
MACHINE_TYPE: e2-standard-2
PREEMPTIBLE:
INTERNAL_IP: 10.128.0.3
EXTERNAL_IP: 34.132.189.103
STATUS: RUNNING
student_01_d043cda5b3e1@cloudshell:~ (qwiklabs-gcp-04-c78f34fbb45d)$
student_01_d043cda5b3e1@cloudshell:~ (qwiklabs-gcp-04-c78f34fbb45d)$ gcloud compute instances list
NAME: second-vm
ZONE: us-central1-a
MACHINE_TYPE: e2-standard-2
PREEMPTIBLE:
INTERNAL_IP: 10.128.0.3
EXTERNAL_IP: 34.132.189.103
STATUS: RUNNING

NAME: first-vm
ZONE: us-central1-c
MACHINE_TYPE: e2-micro
PREEMPTIBLE:
INTERNAL_IP: 10.128.0.2
EXTERNAL_IP: 34.136.131.163
STATUS: RUNNING
student_01_d043cda5b3e1@cloudshell:~ (qwiklabs-gcp-04-c78f34fbb45d)$
student_01_d043cda5b3e1@cloudshell:~ (qwiklabs-gcp-04-c78f34fbb45d)$ gcloud iam service-accounts create test-service-account2 --display-name "test-service-account2"
Created service account [test-service-account2].
student_01_d043cda5b3e1@cloudshell:~ (qwiklabs-gcp-04-c78f34fbb45d)$
student_01_d043cda5b3e1@cloudshell:~ (qwiklabs-gcp-04-c78f34fbb45d)$ gcloud projects add-iam-policy-binding $GOOGLE_CLOUD_PROJECT --member serviceAccount:test-service-account2@${GOOGLE_CLOUD_PROJECT}.iam.gserviceaccount.com --role roles/viewer
Updated IAM policy for project [qwiklabs-gcp-04-c78f34fbb45d].
bindings:
- members:
  - serviceAccount:qwiklabs-gcp-04-c78f34fbb45d@qwiklabs-gcp-04-c78f34fbb45d.iam.gserviceaccount.com
  role: roles/bigquery.admin
- members:
  - serviceAccount:509615673300@cloudbuild.gserviceaccount.com
  role: roles/cloudbuild.builds.builder
- members:
  - serviceAccount:service-509615673300@gcp-sa-cloudbuild.iam.gserviceaccount.com
  role: roles/cloudbuild.serviceAgent
- members:
  - serviceAccount:service-509615673300@compute-system.iam.gserviceaccount.com
  role: roles/compute.serviceAgent
- members:
  - serviceAccount:service-509615673300@container-engine-robot.iam.gserviceaccount.com
  role: roles/container.serviceAgent
- members:
  - serviceAccount:509615673300-compute@developer.gserviceaccount.com
  - serviceAccount:509615673300@cloudservices.gserviceaccount.com
  - serviceAccount:test-service-account@qwiklabs-gcp-04-c78f34fbb45d.iam.gserviceaccount.com
  role: roles/editor
- members:
  - serviceAccount:admiral@qwiklabs-services-prod.iam.gserviceaccount.com
  - serviceAccount:qwiklabs-gcp-04-c78f34fbb45d@qwiklabs-gcp-04-c78f34fbb45d.iam.gserviceaccount.com
  - user:student-01-d043cda5b3e1@qwiklabs.net
  role: roles/owner
- members:
  - serviceAccount:qwiklabs-gcp-04-c78f34fbb45d@qwiklabs-gcp-04-c78f34fbb45d.iam.gserviceaccount.com
  role: roles/storage.admin
- members:
  - serviceAccount:test-service-account2@qwiklabs-gcp-04-c78f34fbb45d.iam.gserviceaccount.com
  - user:student-01-d043cda5b3e1@qwiklabs.net
  role: roles/viewer
etag: BwXmof9MZ-o=
version: 1
student_01_d043cda5b3e1@cloudshell:~ (qwiklabs-gcp-04-c78f34fbb45d)$
student_01_d043cda5b3e1@cloudshell:~ (qwiklabs-gcp-04-c78f34fbb45d)$ echo $GOOGLE_CLOUD_PROJECT
qwiklabs-gcp-04-c78f34fbb45d
student_01_d043cda5b3e1@cloudshell:~ (qwiklabs-gcp-04-c78f34fbb45d)$
student_01_d043cda5b3e1@cloudshell:~ (qwiklabs-gcp-04-c78f34fbb45d)$
student_01_d043cda5b3e1@cloudshell:~ (qwiklabs-gcp-04-c78f34fbb45d)$ # Task 3. Work with Cloud Storage in Cloud Shell
student_01_d043cda5b3e1@cloudshell:~ (qwiklabs-gcp-04-c78f34fbb45d)$ gsutil cp gs://cloud-training/ak8s/cat.jpg cat.jpg
Copying gs://cloud-training/ak8s/cat.jpg...
/ [1 files][ 81.7 KiB/ 81.7 KiB]
Operation completed over 1 objects/81.7 KiB.
student_01_d043cda5b3e1@cloudshell:~ (qwiklabs-gcp-04-c78f34fbb45d)$ ls
cat.jpg  credentials.json  README-cloudshell.txt
student_01_d043cda5b3e1@cloudshell:~ (qwiklabs-gcp-04-c78f34fbb45d)$ gsutil cp cat.jpg gs://$MY_BUCKET_NAME_1
Copying file://cat.jpg [Content-Type=image/jpeg]...
- [1 files][ 81.7 KiB/ 81.7 KiB]
Operation completed over 1 objects/81.7 KiB.
student_01_d043cda5b3e1@cloudshell:~ (qwiklabs-gcp-04-c78f34fbb45d)$
student_01_d043cda5b3e1@cloudshell:~ (qwiklabs-gcp-04-c78f34fbb45d)$ gsutil cp gs://$MY_BUCKET_NAME_1/cat.jpg gs://$MY_BUCKET_NAME_2/cat.jpg
Copying gs://qwiklabs-gcp-04-c78f34fbb45d/cat.jpg [Content-Type=image/jpeg]...
/ [1 files][ 81.7 KiB/ 81.7 KiB]
Operation completed over 1 objects/81.7 KiB.
student_01_d043cda5b3e1@cloudshell:~ (qwiklabs-gcp-04-c78f34fbb45d)$ gsutil acl get gs://$MY_BUCKET_NAME_1/cat.jpg  > acl.txt
student_01_d043cda5b3e1@cloudshell:~ (qwiklabs-gcp-04-c78f34fbb45d)$ cat acl.txt
[
  {
    "entity": "project-owners-509615673300",
    "projectTeam": {
      "projectNumber": "509615673300",
      "team": "owners"
    },
    "role": "OWNER"
  },
  {
    "entity": "project-editors-509615673300",
    "projectTeam": {
      "projectNumber": "509615673300",
      "team": "editors"
    },
    "role": "OWNER"
  },
  {
    "entity": "project-viewers-509615673300",
    "projectTeam": {
      "projectNumber": "509615673300",
      "team": "viewers"
    },
    "role": "READER"
  },
  {
    "email": "student-01-d043cda5b3e1@qwiklabs.net",
    "entity": "user-student-01-d043cda5b3e1@qwiklabs.net",
    "role": "OWNER"
  }
]
student_01_d043cda5b3e1@cloudshell:~ (qwiklabs-gcp-04-c78f34fbb45d)$
student_01_d043cda5b3e1@cloudshell:~ (qwiklabs-gcp-04-c78f34fbb45d)$ gsutil acl set private gs://$MY_BUCKET_NAME_1/cat.jpg
Setting ACL on gs://qwiklabs-gcp-04-c78f34fbb45d/cat.jpg...
/ [1 objects]
Operation completed over 1 objects.
student_01_d043cda5b3e1@cloudshell:~ (qwiklabs-gcp-04-c78f34fbb45d)$ gsutil acl get gs://$MY_BUCKET_NAME_1/cat.jpg  > acl-2.txt
cat acl-2.txt
[
  {
    "email": "student-01-d043cda5b3e1@qwiklabs.net",
    "entity": "user-student-01-d043cda5b3e1@qwiklabs.net",
    "role": "OWNER"
  }
]
student_01_d043cda5b3e1@cloudshell:~ (qwiklabs-gcp-04-c78f34fbb45d)$
student_01_d043cda5b3e1@cloudshell:~ (qwiklabs-gcp-04-c78f34fbb45d)$ gcloud config list
[accessibility]
screen_reader = True
[component_manager]
disable_update_check = True
[compute]
gce_metadata_read_timeout_sec = 30
zone = us-central1-a
[core]
account = student-01-d043cda5b3e1@qwiklabs.net
disable_usage_reporting = True
project = qwiklabs-gcp-04-c78f34fbb45d
[metrics]
environment = devshell

Your active configuration is: [cloudshell-14275]
student_01_d043cda5b3e1@cloudshell:~ (qwiklabs-gcp-04-c78f34fbb45d)$ gcloud auth activate-service-account --key-file credentials.json
Activated service account credentials for: [test-service-account@qwiklabs-gcp-04-c78f34fbb45d.iam.gserviceaccount.com]
student_01_d043cda5b3e1@cloudshell:~ (qwiklabs-gcp-04-c78f34fbb45d)$ gcloud config list
[accessibility]
screen_reader = True
[component_manager]
disable_update_check = True
[compute]
gce_metadata_read_timeout_sec = 30
zone = us-central1-a
[core]
account = test-service-account@qwiklabs-gcp-04-c78f34fbb45d.iam.gserviceaccount.com
disable_usage_reporting = True
project = qwiklabs-gcp-04-c78f34fbb45d
[metrics]
environment = devshell

Your active configuration is: [cloudshell-14275]
student_01_d043cda5b3e1@cloudshell:~ (qwiklabs-gcp-04-c78f34fbb45d)$
student_01_d043cda5b3e1@cloudshell:~ (qwiklabs-gcp-04-c78f34fbb45d)$ gcloud auth list
Credentialed Accounts

ACTIVE:
ACCOUNT: student-01-d043cda5b3e1@qwiklabs.net

ACTIVE: *
ACCOUNT: test-service-account@qwiklabs-gcp-04-c78f34fbb45d.iam.gserviceaccount.com

To set the active account, run:
    $ gcloud config set account `ACCOUNT`

student_01_d043cda5b3e1@cloudshell:~ (qwiklabs-gcp-04-c78f34fbb45d)$
student_01_d043cda5b3e1@cloudshell:~ (qwiklabs-gcp-04-c78f34fbb45d)$ gsutil cp gs://$MY_BUCKET_NAME_1/cat.jpg ./cat-copy.jpg
Copying gs://qwiklabs-gcp-04-c78f34fbb45d/cat.jpg...
AccessDeniedException: 403 HttpError accessing <https://storage.googleapis.com/download/storage/v1/b/qwiklabs-gcp-04-c78f34fbb45d/o/cat.jpg?generation=1660958437429575&alt=media>: response: <{'x-guploader-uploadid': 'ADPycdtxWYFIFBBCE1s-ZfI_zTA5iN7MUxj-zWiZtcnCKKRuYj5_y010QA8dpvuOcCpCebgyCzynO36huZguMNwi-ruwiQ', 'content-type': 'text/html; charset=UTF-8', 'date': 'Sat, 20 Aug 2022 01:26:04 GMT', 'vary': 'Origin, X-Origin', 'expires': 'Sat, 20 Aug 2022 01:26:04 GMT', 'cache-control': 'private, max-age=0', 'content-length': '150', 'server': 'UploadServer', 'status': '403'}>, content <test-service-account@qwiklabs-gcp-04-c78f34fbb45d.iam.gserviceaccount.com does not have storage.objects.get access to the Google Cloud Storage object.>
student_01_d043cda5b3e1@cloudshell:~ (qwiklabs-gcp-04-c78f34fbb45d)$ gsutil cp gs://$MY_BUCKET_NAME_2/cat.jpg ./cat-copy.jpg
Copying gs://qwiklabs-gcp-04-c78f34fbb45d_2/cat.jpg...
/ [1 files][ 81.7 KiB/ 81.7 KiB]
Operation completed over 1 objects/81.7 KiB.
student_01_d043cda5b3e1@cloudshell:~ (qwiklabs-gcp-04-c78f34fbb45d)$ ls
acl-2.txt  acl.txt  cat-copy.jpg  cat.jpg  credentials.json  README-cloudshell.txt
student_01_d043cda5b3e1@cloudshell:~ (qwiklabs-gcp-04-c78f34fbb45d)$
student_01_d043cda5b3e1@cloudshell:~ (qwiklabs-gcp-04-c78f34fbb45d)$ # gcloud config set account [USERNAME]
student_01_d043cda5b3e1@cloudshell:~ (qwiklabs-gcp-04-c78f34fbb45d)$ gcloud config set account student-01-d043cda5b3e1@qwiklabs.net
Updated property [core/account].
student_01_d043cda5b3e1@cloudshell:~ (qwiklabs-gcp-04-c78f34fbb45d)$ gsutil cp gs://$MY_BUCKET_NAME_1/cat.jpg ./copy2-of-cat.jpg
Copying gs://qwiklabs-gcp-04-c78f34fbb45d/cat.jpg...
/ [1 files][ 81.7 KiB/ 81.7 KiB]
Operation completed over 1 objects/81.7 KiB.
student_01_d043cda5b3e1@cloudshell:~ (qwiklabs-gcp-04-c78f34fbb45d)$ ls
acl-2.txt  acl.txt  cat-copy.jpg  cat.jpg  copy2-of-cat.jpg  credentials.json  README-cloudshell.txt
student_01_d043cda5b3e1@cloudshell:~ (qwiklabs-gcp-04-c78f34fbb45d)$
student_01_d043cda5b3e1@cloudshell:~ (qwiklabs-gcp-04-c78f34fbb45d)$ gsutil iam ch allUsers:objectViewer gs://$MY_BUCKET_NAME_1
student_01_d043cda5b3e1@cloudshell:~ (qwiklabs-gcp-04-c78f34fbb45d)$
student_01_d043cda5b3e1@cloudshell:~ (qwiklabs-gcp-04-c78f34fbb45d)$
student_01_d043cda5b3e1@cloudshell:~ (qwiklabs-gcp-04-c78f34fbb45d)$
student_01_d043cda5b3e1@cloudshell:~ (qwiklabs-gcp-04-c78f34fbb45d)$ # Task 4. Explore the Cloud Shell code editor
student_01_d043cda5b3e1@cloudshell:~ (qwiklabs-gcp-04-c78f34fbb45d)$
student_01_d043cda5b3e1@cloudshell:~ (qwiklabs-gcp-04-c78f34fbb45d)$
student_01_d043cda5b3e1@cloudshell:~ (qwiklabs-gcp-04-c78f34fbb45d)$ git clone https://github.com/googlecodelabs/orchestrate-with-kubernetes.git
Cloning into 'orchestrate-with-kubernetes'...
remote: Enumerating objects: 90, done.
remote: Total 90 (delta 0), reused 0 (delta 0), pack-reused 90
Receiving objects: 100% (90/90), 109.02 KiB | 803.00 KiB/s, done.
Resolving deltas: 100% (25/25), done.
student_01_d043cda5b3e1@cloudshell:~ (qwiklabs-gcp-04-c78f34fbb45d)$ ls
acl-2.txt  acl.txt  cat-copy.jpg  cat.jpg  copy2-of-cat.jpg  credentials.json  orchestrate-with-kubernetes  README-cloudshell.txt
student_01_d043cda5b3e1@cloudshell:~ (qwiklabs-gcp-04-c78f34fbb45d)$ mkdir test
student_01_d043cda5b3e1@cloudshell:~ (qwiklabs-gcp-04-c78f34fbb45d)$
student_01_d043cda5b3e1@cloudshell:~ (qwiklabs-gcp-04-c78f34fbb45d)$ cd orchestrate-with-kubernetes
student_01_d043cda5b3e1@cloudshell:~/orchestrate-with-kubernetes (qwiklabs-gcp-04-c78f34fbb45d)$ cat cleanup.sh
# Copyright 2016 Google Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

gcloud compute instances delete node0 node1
gcloud compute routes delete default-route-10-200-1-0-24 default-route-10-200-0-0-24
gcloud compute firewall-rules delete default-allow-local-api

echo Finished cleanup!
student_01_d043cda5b3e1@cloudshell:~/orchestrate-with-kubernetes (qwiklabs-gcp-04-c78f34fbb45d)$ cat index.html
<html><head><title>Cat</title></head>
<body>
<h1>Cat</h1>
<img src="REPLACE_WITH_CAT_URL">

<img src="https://storage.googleapis.com/qwiklabs-gcp-04-c78f34fbb45d/cat.jpg">

</body></html>student_01_d043cda5b3e1@cloudshell:~/orchestrate-with-kubernetes (qwiklabs-gcp-04-c78f34fbb45d)$
student_01_d043cda5b3e1@cloudshell:~/orchestrate-with-kubernetes (qwiklabs-gcp-04-c78f34fbb45d)$
student_01_d043cda5b3e1@cloudshell:~/orchestrate-with-kubernetes (qwiklabs-gcp-04-c78f34fbb45d)$

### on vm(first-vm) 

Linux first-vm 5.10.0-16-cloud-amd64 #1 SMP Debian 5.10.127-1 (2022-06-30) x86_64

The programs included with the Debian GNU/Linux system are free software;
the exact distribution terms for each program are described in the
individual files in /usr/share/doc/*/copyright.

Debian GNU/Linux comes with ABSOLUTELY NO WARRANTY, to the extent
permitted by applicable law.
student-01-d043cda5b3e1@first-vm:~$ sudo apt-get remove -y --purge man-db
sudo touch /var/lib/man-db/auto-update
sudo apt-get update
sudo apt-get install nginx
...
Upgrading binary: nginx.
Setting up nginx (1.18.0-6.1+deb11u2) ...
Processing triggers for libc-bin (2.31-13+deb11u3) ...
student-01-d043cda5b3e1@first-vm:~$ 

### cloudshell

student_01_d043cda5b3e1@cloudshell:~/orchestrate-with-kubernetes (qwiklabs-gcp-04-c78f34fbb45d)$
student_01_d043cda5b3e1@cloudshell:~/orchestrate-with-kubernetes (qwiklabs-gcp-04-c78f34fbb45d)$ gcloud compute scp index.html first-vm:index.nginx-debian.html --zone=us-central1-c
WARNING: The private SSH key file for gcloud does not exist.
WARNING: The public SSH key file for gcloud does not exist.
WARNING: You do not have an SSH key for gcloud.
WARNING: SSH keygen will be executed to generate a key.
This tool needs to create the directory [/home/student_01_d043cda5b3e1/.ssh] before being able to generate SSH keys.

Do you want to continue (Y/n)?  Y

Generating public/private rsa key pair.
Enter passphrase (empty for no passphrase):
Enter same passphrase again:
Your identification has been saved in /home/student_01_d043cda5b3e1/.ssh/google_compute_engine
Your public key has been saved in /home/student_01_d043cda5b3e1/.ssh/google_compute_engine.pub
The key fingerprint is:
SHA256:eIJWEUirXSBE2S0+Nqv+6HbgMOGDjHIKyMaZ5/Iuin8 student_01_d043cda5b3e1@cs-712057340446-default
The key's randomart image is:
+---[RSA 3072]----+
| o++ooo.         |
|  ..+o..         |
|   ...o          |
|.  o=+ .         |
|O.+.++o S        |
|OXoo.  o         |
|+*+o             |
|oo+oE            |
|+=X*.            |
+----[SHA256]-----+
Warning: Permanently added 'compute.2730730902784936966' (ECDSA) to the list of known hosts.
index.html                                                                                                                100%  187     1.2KB/s   00:00    
student_01_d043cda5b3e1@cloudshell:~/orchestrate-with-kubernetes (qwiklabs-gcp-04-c78f34fbb45d)$


### on vm(first-vm)


student-01-d043cda5b3e1@first-vm:~$ sudo cp index.nginx-debian.html /var/www/html
student-01-d043cda5b3e1@first-vm:~$ ls -al /var/www/html
total 12
drwxr-xr-x 2 root root 4096 Aug 20 01:42 .
drwxr-xr-x 3 root root 4096 Aug 20 01:42 ..
-rw-r--r-- 1 root root  187 Aug 20 01:44 index.nginx-debian.html
student-01-d043cda5b3e1@first-vm:~$ 


### cloudshell

student_01_d043cda5b3e1@cloudshell:~/orchestrate-with-kubernetes (qwiklabs-gcp-04-c78f34fbb45d)$ # curl [first-vm.EXTERNAL_IP,  34.136.131.163]
student_01_d043cda5b3e1@cloudshell:~/orchestrate-with-kubernetes (qwiklabs-gcp-04-c78f34fbb45d)$ curl http://34.136.131.163
<html><head><title>Cat</title></head>
<body>
<h1>Cat</h1>
<img src="REPLACE_WITH_CAT_URL">

<img src="https://storage.googleapis.com/qwiklabs-gcp-04-c78f34fbb45d/cat.jpg">

</body></html>
student_01_d043cda5b3e1@cloudshell:~/orchestrate-with-kubernetes (qwiklabs-gcp-04-c78f34fbb45d)$
student_01_d043cda5b3e1@cloudshell:~/orchestrate-with-kubernetes (qwiklabs-gcp-04-c78f34fbb45d)$
```







