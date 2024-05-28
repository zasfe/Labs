# 실습: Cloud Build로 작업하기

> 이번 실습에서는 Cloud Build를 사용하여 제공된 코드와 Dockerfile을 기반으로 Docker 컨테이너 이미지를 빌드하고, 그런 다음 컨테이너를 Container Registry로 업로드합니다.

```bash
## Cloud Shell

Welcome to Cloud Shell! Type "help" to get started.
Your Cloud Platform project in this session is set to qwiklabs-gcp-04-4198725b317d.
Use “gcloud config set project [PROJECT_ID]” to change to a different project.
student_01_d043cda5b3e1@cloudshell:~ (qwiklabs-gcp-04-4198725b317d)$ nano quickstart.sh
student_01_d043cda5b3e1@cloudshell:~ (qwiklabs-gcp-04-4198725b317d)$ cat quickstart.sh
#!/bin/sh
echo "Hello, world! The time is $(date)."
student_01_d043cda5b3e1@cloudshell:~ (qwiklabs-gcp-04-4198725b317d)$ nano Dockerfile
student_01_d043cda5b3e1@cloudshell:~ (qwiklabs-gcp-04-4198725b317d)$ cat Dockerfile
FROM alpine
COPY quickstart.sh /
CMD ["/quickstart.sh"]

student_01_d043cda5b3e1@cloudshell:~ (qwiklabs-gcp-04-4198725b317d)$
student_01_d043cda5b3e1@cloudshell:~ (qwiklabs-gcp-04-4198725b317d)$ chmod +x quickstart.sh
student_01_d043cda5b3e1@cloudshell:~ (qwiklabs-gcp-04-4198725b317d)$ gcloud builds submit --tag gcr.io/${GOOGLE_CLOUD_PROJECT}/quickstart-image .
Creating temporary tarball archive of 7 file(s) totalling 1.5 KiB before compression.
Uploading tarball of [.] to [gs://qwiklabs-gcp-04-4198725b317d_cloudbuild/source/1660962904.24164-457c8b2c234a4e1d898e23411f513623.tgz]
Created [https://cloudbuild.googleapis.com/v1/projects/qwiklabs-gcp-04-4198725b317d/locations/global/builds/f90a5197-d490-43bb-a162-dd45b4df9b9c].
Logs are available at [ https://console.cloud.google.com/cloud-build/builds/f90a5197-d490-43bb-a162-dd45b4df9b9c?project=161859037374 ].
------------------------------------------------------------------- REMOTE BUILD OUTPUT --------------------------------------------------------------------
starting build "f90a5197-d490-43bb-a162-dd45b4df9b9c"

FETCHSOURCE
Fetching storage object: gs://qwiklabs-gcp-04-4198725b317d_cloudbuild/source/1660962904.24164-457c8b2c234a4e1d898e23411f513623.tgz#1660962905944970
Copying gs://qwiklabs-gcp-04-4198725b317d_cloudbuild/source/1660962904.24164-457c8b2c234a4e1d898e23411f513623.tgz#1660962905944970...
/ [1 files][  1.3 KiB/  1.3 KiB]
Operation completed over 1 objects/1.3 KiB.
BUILD
Already have image (with digest): gcr.io/cloud-builders/docker
Sending build context to Docker daemon  10.75kB
Step 1/3 : FROM alpine
latest: Pulling from library/alpine
Digest: sha256:bc41182d7ef5ffc53a40b044e725193bc10142a1243f395ee852a8d9730fc2ad
Status: Downloaded newer image for alpine:latest
 9c6f07244728
Step 2/3 : COPY quickstart.sh /
 b0aa3eb5b483
Step 3/3 : CMD ["/quickstart.sh"]
 Running in 1daa2b3e4701
Removing intermediate container 1daa2b3e4701
 88e1dde08578
Successfully built 88e1dde08578
Successfully tagged gcr.io/qwiklabs-gcp-04-4198725b317d/quickstart-image:latest
PUSH
Pushing gcr.io/qwiklabs-gcp-04-4198725b317d/quickstart-image
The push refers to repository [gcr.io/qwiklabs-gcp-04-4198725b317d/quickstart-image]
39c52bcfaf40: Preparing
994393dc58e7: Preparing
994393dc58e7: Layer already exists
39c52bcfaf40: Pushed
latest: digest: sha256:35986b425754de6a5f32c2c6797a6471f8bd38da1dab5df8a4bc6f2dc52f809b size: 735
DONE
------------------------------------------------------------------------------------------------------------------------------------------------------------
ID: f90a5197-d490-43bb-a162-dd45b4df9b9c
CREATE_TIME: 2022-08-20T02:35:06+00:00
DURATION: 15S
SOURCE: gs://qwiklabs-gcp-04-4198725b317d_cloudbuild/source/1660962904.24164-457c8b2c234a4e1d898e23411f513623.tgz
IMAGES: gcr.io/qwiklabs-gcp-04-4198725b317d/quickstart-image (+1 more)
STATUS: SUCCESS
student_01_d043cda5b3e1@cloudshell:~ (qwiklabs-gcp-04-4198725b317d)$
student_01_d043cda5b3e1@cloudshell:~ (qwiklabs-gcp-04-4198725b317d)$
student_01_d043cda5b3e1@cloudshell:~ (qwiklabs-gcp-04-4198725b317d)$ # Task 3. Building containers with a build configuration file and Cloud Build
student_01_d043cda5b3e1@cloudshell:~ (qwiklabs-gcp-04-4198725b317d)$
student_01_d043cda5b3e1@cloudshell:~ (qwiklabs-gcp-04-4198725b317d)$ git clone https://github.com/GoogleCloudPlatform/training-data-analyst
Cloning into 'training-data-analyst'...
remote: Enumerating objects: 59780, done.
remote: Counting objects: 100% (203/203), done.
remote: Compressing objects: 100% (103/103), done.
remote: Total 59780 (delta 106), reused 177 (delta 85), pack-reused 59577
Receiving objects: 100% (59780/59780), 680.04 MiB | 25.02 MiB/s, done.
Resolving deltas: 100% (37931/37931), done.
Updating files: 100% (12646/12646), done.
student_01_d043cda5b3e1@cloudshell:~ (qwiklabs-gcp-04-4198725b317d)$
student_01_d043cda5b3e1@cloudshell:~ (qwiklabs-gcp-04-4198725b317d)$ ln -s ~/training-data-analyst/courses/ak8s/v1.1 ~/ak8s
student_01_d043cda5b3e1@cloudshell:~ (qwiklabs-gcp-04-4198725b317d)$ cd ~/ak8s/Cloud_Build/a
student_01_d043cda5b3e1@cloudshell:~/ak8s/Cloud_Build/a (qwiklabs-gcp-04-4198725b317d)$ cat cloudbuild.yaml
steps:
- name: 'gcr.io/cloud-builders/docker'
  args: [ 'build', '-t', 'gcr.io/$PROJECT_ID/quickstart-image', '.' ]
images:
- 'gcr.io/$PROJECT_ID/quickstart-image'
student_01_d043cda5b3e1@cloudshell:~/ak8s/Cloud_Build/a (qwiklabs-gcp-04-4198725b317d)$ gcloud builds submit --config cloudbuild.yaml .
Creating temporary tarball archive of 3 file(s) totalling 273 bytes before compression.
Uploading tarball of [.] to [gs://qwiklabs-gcp-04-4198725b317d_cloudbuild/source/1660963201.117013-a132fba0adbd414a915142986127e165.tgz]
Created [https://cloudbuild.googleapis.com/v1/projects/qwiklabs-gcp-04-4198725b317d/locations/global/builds/4b3c8498-1b0d-402c-8b67-bf499e322118].
Logs are available at [ https://console.cloud.google.com/cloud-build/builds/4b3c8498-1b0d-402c-8b67-bf499e322118?project=161859037374 ].
------------------------------------------------------------------- REMOTE BUILD OUTPUT --------------------------------------------------------------------
starting build "4b3c8498-1b0d-402c-8b67-bf499e322118"

FETCHSOURCE
Fetching storage object: gs://qwiklabs-gcp-04-4198725b317d_cloudbuild/source/1660963201.117013-a132fba0adbd414a915142986127e165.tgz#1660963201860077
Copying gs://qwiklabs-gcp-04-4198725b317d_cloudbuild/source/1660963201.117013-a132fba0adbd414a915142986127e165.tgz#1660963201860077...
/ [1 files][  417.0 B/  417.0 B]
Operation completed over 1 objects/417.0 B.
BUILD
Already have image (with digest): gcr.io/cloud-builders/docker
Sending build context to Docker daemon  4.096kB
Step 1/3 : FROM alpine
latest: Pulling from library/alpine
Digest: sha256:bc41182d7ef5ffc53a40b044e725193bc10142a1243f395ee852a8d9730fc2ad
Status: Downloaded newer image for alpine:latest
 9c6f07244728
Step 2/3 : COPY quickstart.sh /
 5bd6593b474b
Step 3/3 : CMD ["/quickstart.sh"]
 Running in 68eb0a831804
Removing intermediate container 68eb0a831804
 f20549aaf54b
Successfully built f20549aaf54b
Successfully tagged gcr.io/qwiklabs-gcp-04-4198725b317d/quickstart-image:latest
PUSH
Pushing gcr.io/qwiklabs-gcp-04-4198725b317d/quickstart-image
The push refers to repository [gcr.io/qwiklabs-gcp-04-4198725b317d/quickstart-image]
89117f81aaac: Preparing
994393dc58e7: Preparing
994393dc58e7: Layer already exists
89117f81aaac: Pushed
latest: digest: sha256:39cfb4e2591935e26a30385a081c53197e92911e767731767ce9a454f1a197d7 size: 735
DONE
------------------------------------------------------------------------------------------------------------------------------------------------------------
ID: 4b3c8498-1b0d-402c-8b67-bf499e322118
CREATE_TIME: 2022-08-20T02:40:02+00:00
DURATION: 13S
SOURCE: gs://qwiklabs-gcp-04-4198725b317d_cloudbuild/source/1660963201.117013-a132fba0adbd414a915142986127e165.tgz
IMAGES: gcr.io/qwiklabs-gcp-04-4198725b317d/quickstart-image (+1 more)
STATUS: SUCCESS
student_01_d043cda5b3e1@cloudshell:~/ak8s/Cloud_Build/a (qwiklabs-gcp-04-4198725b317d)$
student_01_d043cda5b3e1@cloudshell:~/ak8s/Cloud_Build/a (qwiklabs-gcp-04-4198725b317d)$
student_01_d043cda5b3e1@cloudshell:~/ak8s/Cloud_Build/a (qwiklabs-gcp-04-4198725b317d)$
student_01_d043cda5b3e1@cloudshell:~/ak8s/Cloud_Build/a (qwiklabs-gcp-04-4198725b317d)$
student_01_d043cda5b3e1@cloudshell:~/ak8s/Cloud_Build/a (qwiklabs-gcp-04-4198725b317d)$ # Task 4. Building and testing containers with a build configuration file and Cloud Build
student_01_d043cda5b3e1@cloudshell:~/ak8s/Cloud_Build/a (qwiklabs-gcp-04-4198725b317d)$
student_01_d043cda5b3e1@cloudshell:~/ak8s/Cloud_Build/a (qwiklabs-gcp-04-4198725b317d)$ cd ~/ak8s/Cloud_Build/b
student_01_d043cda5b3e1@cloudshell:~/ak8s/Cloud_Build/b (qwiklabs-gcp-04-4198725b317d)$ cat cloudbuild.yaml
steps:
- name: 'gcr.io/cloud-builders/docker'
  args: [ 'build', '-t', 'gcr.io/$PROJECT_ID/quickstart-image', '.' ]
- name: 'gcr.io/$PROJECT_ID/quickstart-image'
  args: ['fail']
images:
- 'gcr.io/$PROJECT_ID/quickstart-image'
student_01_d043cda5b3e1@cloudshell:~/ak8s/Cloud_Build/b (qwiklabs-gcp-04-4198725b317d)$ gcloud builds submit --config cloudbuild.yaml .
Creating temporary tarball archive of 3 file(s) totalling 382 bytes before compression.
Uploading tarball of [.] to [gs://qwiklabs-gcp-04-4198725b317d_cloudbuild/source/1660963424.165465-5b02ba4f22834d74aa637931e3389dda.tgz]
Created [https://cloudbuild.googleapis.com/v1/projects/qwiklabs-gcp-04-4198725b317d/locations/global/builds/2566f089-5bc8-4172-b5b7-7586c43f76f0].
Logs are available at [ https://console.cloud.google.com/cloud-build/builds/2566f089-5bc8-4172-b5b7-7586c43f76f0?project=161859037374 ].
------------------------------------------------------------------- REMOTE BUILD OUTPUT --------------------------------------------------------------------
starting build "2566f089-5bc8-4172-b5b7-7586c43f76f0"

FETCHSOURCE
Fetching storage object: gs://qwiklabs-gcp-04-4198725b317d_cloudbuild/source/1660963424.165465-5b02ba4f22834d74aa637931e3389dda.tgz#1660963424938114
Copying gs://qwiklabs-gcp-04-4198725b317d_cloudbuild/source/1660963424.165465-5b02ba4f22834d74aa637931e3389dda.tgz#1660963424938114...
/ [1 files][  468.0 B/  468.0 B]
Operation completed over 1 objects/468.0 B.
BUILD
Starting Step #0
Step #0: Already have image (with digest): gcr.io/cloud-builders/docker
Step #0: Sending build context to Docker daemon  4.096kB
Step #0: Step 1/3 : FROM alpine
Step #0: latest: Pulling from library/alpine
Step #0: Digest: sha256:bc41182d7ef5ffc53a40b044e725193bc10142a1243f395ee852a8d9730fc2ad
Step #0: Status: Downloaded newer image for alpine:latest
Step #0:  9c6f07244728
Step #0: Step 2/3 : COPY quickstart.sh /
Step #0:  d426b82f3ed9
Step #0: Step 3/3 : CMD ["/quickstart.sh"]
Step #0:  Running in 2f6f9b372e49
Step #0: Removing intermediate container 2f6f9b372e49
Step #0:  079f0dcf770b
Step #0: Successfully built 079f0dcf770b
Step #0: Successfully tagged gcr.io/qwiklabs-gcp-04-4198725b317d/quickstart-image:latest
Finished Step #0
Starting Step #1
Step #1: Already have image: gcr.io/qwiklabs-gcp-04-4198725b317d/quickstart-image
Finished Step #1
ERROR
ERROR: build step 1 "gcr.io/qwiklabs-gcp-04-4198725b317d/quickstart-image" failed: starting step container failed: Error response from daemon: failed to create shim task: OCI runtime create failed: runc create failed: unable to start container process: exec: "fail": executable file not found in $PATH: unknown
------------------------------------------------------------------------------------------------------------------------------------------------------------

BUILD FAILURE: Build step failure: build step 1 "gcr.io/qwiklabs-gcp-04-4198725b317d/quickstart-image" failed: starting step container failed: Error response from daemon: failed to create shim task: OCI runtime create failed: runc create failed: unable to start container process: exec: "fail": executable file not found in $PATH: unknown
ERROR: (gcloud.builds.submit) build 2566f089-5bc8-4172-b5b7-7586c43f76f0 completed with status "FAILURE"
student_01_d043cda5b3e1@cloudshell:~/ak8s/Cloud_Build/b (qwiklabs-gcp-04-4198725b317d)$ echo $?
1
student_01_d043cda5b3e1@cloudshell:~/ak8s/Cloud_Build/b (qwiklabs-gcp-04-4198725b317d)$

```

