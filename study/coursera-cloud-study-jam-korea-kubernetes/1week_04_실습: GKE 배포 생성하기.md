# 실습: GKE 배포 생성하기

## 개요
이 실습에서는 배포 매니페스트 사용의 기본사항에 대해 알아봅니다. 매니페스트는 여러 포드에서 사용할 수 있는 배포에 필요한 구성이 포함된 파일입니다. 매니페스트는 간단히 변경할 수 있습니다.


## 목표

  * 이 실습에서는 다음 작업을 수행하는 방법을 알아봅니다.
  * 배포 매니페스트를 만들고, 클러스터에 배포하고, 노드가 비활성화되면 포드 재예약 확인하기
  * 배포의 포드 수동 확장 및 축소 트리거하기
  * 배포 출시(새 버전에 대한 순차적 업데이트) 및 롤백 트리거하기
  * 카나리아 배포 수행하기

```bash
Welcome to Cloud Shell! Type "help" to get started.
Your Cloud Platform project in this session is set to qwiklabs-gcp-01-506503ed76d1.
Use “gcloud config set project [PROJECT_ID]” to change to a different project.
student_04_07d6cc0c38f3@cloudshell:~ (qwiklabs-gcp-01-506503ed76d1)$ gcloud auth list
Credentialed Accounts

ACTIVE: *
ACCOUNT: student-04-07d6cc0c38f3@qwiklabs.net

To set the active account, run:
    $ gcloud config set account `ACCOUNT`

student_04_07d6cc0c38f3@cloudshell:~ (qwiklabs-gcp-01-506503ed76d1)$ gcloud config list project
[core]
project = qwiklabs-gcp-01-506503ed76d1

Your active configuration is: [cloudshell-29102]
student_04_07d6cc0c38f3@cloudshell:~ (qwiklabs-gcp-01-506503ed76d1)$ 
```

### 작업 1. 배포 매니페스트를 만들고 클러스터에 배포하기

```bash
Welcome to Cloud Shell! Type "help" to get started.
Your Cloud Platform project in this session is set to qwiklabs-gcp-01-506503ed76d1.
Use “gcloud config set project [PROJECT_ID]” to change to a different project.
student_04_07d6cc0c38f3@cloudshell:~ (qwiklabs-gcp-01-506503ed76d1)$ gcloud auth list
Credentialed Accounts

ACTIVE: *
ACCOUNT: student-04-07d6cc0c38f3@qwiklabs.net

To set the active account, run:
    $ gcloud config set account `ACCOUNT`

student_04_07d6cc0c38f3@cloudshell:~ (qwiklabs-gcp-01-506503ed76d1)$ gcloud config list project
[core]
project = qwiklabs-gcp-01-506503ed76d1

Your active configuration is: [cloudshell-29102]
student_04_07d6cc0c38f3@cloudshell:~ (qwiklabs-gcp-01-506503ed76d1)$ export my_zone=us-central1-a
export my_cluster=standard-cluster-1
student_04_07d6cc0c38f3@cloudshell:~ (qwiklabs-gcp-01-506503ed76d1)$ source <(kubectl completion bash)
student_04_07d6cc0c38f3@cloudshell:~ (qwiklabs-gcp-01-506503ed76d1)$ gcloud container clusters get-credentials $my_cluster --zone $my_zone
Fetching cluster endpoint and auth data.
kubeconfig entry generated for standard-cluster-1.
student_04_07d6cc0c38f3@cloudshell:~ (qwiklabs-gcp-01-506503ed76d1)$ git clone https://github.com/GoogleCloudPlatform/training-data-analyst
Cloning into 'training-data-analyst'...
remote: Enumerating objects: 59780, done.
remote: Counting objects: 100% (203/203), done.
remote: Compressing objects: 100% (105/105), done.
remote: Total 59780 (delta 106), reused 174 (delta 83), pack-reused 59577
Receiving objects: 100% (59780/59780), 680.04 MiB | 23.97 MiB/s, done.
Resolving deltas: 100% (37936/37936), done.
Updating files: 100% (12646/12646), done.
student_04_07d6cc0c38f3@cloudshell:~ (qwiklabs-gcp-01-506503ed76d1)$ ln -s ~/training-data-analyst/courses/ak8s/v1.1 ~/ak8s
student_04_07d6cc0c38f3@cloudshell:~ (qwiklabs-gcp-01-506503ed76d1)$ cd ~/ak8s/Deployments/
student_04_07d6cc0c38f3@cloudshell:~/ak8s/Deployments (qwiklabs-gcp-01-506503ed76d1)$ cat <<EOF > nginx-deployment.yaml
> apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
  labels:
    app: nginx
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:1.7.9
        ports:
        - containerPort: 80
> EOF
student_04_07d6cc0c38f3@cloudshell:~/ak8s/Deployments (qwiklabs-gcp-01-506503ed76d1)$ ls -al
total 20
drwxr-xr-x  2 student_04_07d6cc0c38f3 student_04_07d6cc0c38f3 4096 Aug 22 13:30 .
drwxr-xr-x 20 student_04_07d6cc0c38f3 student_04_07d6cc0c38f3 4096 Aug 22 13:30 ..
-rw-r--r--  1 student_04_07d6cc0c38f3 student_04_07d6cc0c38f3  381 Aug 22 13:30 nginx-canary.yaml
-rw-r--r--  1 student_04_07d6cc0c38f3 student_04_07d6cc0c38f3  340 Aug 22 13:33 nginx-deployment.yaml
-rw-r--r--  1 student_04_07d6cc0c38f3 student_04_07d6cc0c38f3  168 Aug 22 13:30 service-nginx.yaml
student_04_07d6cc0c38f3@cloudshell:~/ak8s/Deployments (qwiklabs-gcp-01-506503ed76d1)$ cat nginx-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
  labels:
    app: nginx
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:1.7.9
        ports:
        - containerPort: 80
student_04_07d6cc0c38f3@cloudshell:~/ak8s/Deployments (qwiklabs-gcp-01-506503ed76d1)$ kubectl apply -f ./nginx-deployment.yaml
deployment.apps/nginx-deployment created
student_04_07d6cc0c38f3@cloudshell:~/ak8s/Deployments (qwiklabs-gcp-01-506503ed76d1)$ kubectl get deployments
NAME               READY   UP-TO-DATE   AVAILABLE   AGE
nginx-deployment   3/3     3            3           13s
student_04_07d6cc0c38f3@cloudshell:~/ak8s/Deployments (qwiklabs-gcp-01-506503ed76d1)$
```


### 작업 2. 배포 시 포드 수를 수동으로 확장 및 축소하기

  * Kubernetes Engine > 워크로드 > [nginx-deployment] > Action > Scale > Replaca > 1, SAVE

```bash
student_04_07d6cc0c38f3@cloudshell:~/ak8s/Deployments (qwiklabs-gcp-01-506503ed76d1)$ kubectl apply -f ./nginx-deployment.yaml
deployment.apps/nginx-deployment created
student_04_07d6cc0c38f3@cloudshell:~/ak8s/Deployments (qwiklabs-gcp-01-506503ed76d1)$ kubectl get deployments
NAME               READY   UP-TO-DATE   AVAILABLE   AGE
nginx-deployment   3/3     3            3           13s
student_04_07d6cc0c38f3@cloudshell:~/ak8s/Deployments (qwiklabs-gcp-01-506503ed76d1)$ kubectl get deployments
NAME               READY   UP-TO-DATE   AVAILABLE   AGE
nginx-deployment   1/1     1            1           7m58s
student_04_07d6cc0c38f3@cloudshell:~/ak8s/Deployments (qwiklabs-gcp-01-506503ed76d1)$ kubectl scale --replicas=3 deployment nginx-deployment
deployment.apps/nginx-deployment scaled
student_04_07d6cc0c38f3@cloudshell:~/ak8s/Deployments (qwiklabs-gcp-01-506503ed76d1)$ kubectl get deployments
NAME               READY   UP-TO-DATE   AVAILABLE   AGE
nginx-deployment   3/3     3            3           9m16s
student_04_07d6cc0c38f3@cloudshell:~/ak8s/Deployments (qwiklabs-gcp-01-506503ed76d1)$
```


### 작업 3. 배포 출시 및 배포 롤백 트리거하기


```bash
student_04_07d6cc0c38f3@cloudshell:~/ak8s/Deployments (qwiklabs-gcp-01-506503ed76d1)$
student_04_07d6cc0c38f3@cloudshell:~/ak8s/Deployments (qwiklabs-gcp-01-506503ed76d1)$
student_04_07d6cc0c38f3@cloudshell:~/ak8s/Deployments (qwiklabs-gcp-01-506503ed76d1)$
student_04_07d6cc0c38f3@cloudshell:~/ak8s/Deployments (qwiklabs-gcp-01-506503ed76d1)$ kubectl set image deployment.v1.apps/nginx-deployment nginx=nginx:1.9.1 --record
Flag --record has been deprecated, --record will be removed in the future
deployment.apps/nginx-deployment image updated
student_04_07d6cc0c38f3@cloudshell:~/ak8s/Deployments (qwiklabs-gcp-01-506503ed76d1)$ kubectl rollout status deployment.v1.apps/nginx-deployment
Waiting for deployment "nginx-deployment" rollout to finish: 2 out of 3 new replicas have been updated...
Waiting for deployment "nginx-deployment" rollout to finish: 2 out of 3 new replicas have been updated...
Waiting for deployment "nginx-deployment" rollout to finish: 2 out of 3 new replicas have been updated...
Waiting for deployment "nginx-deployment" rollout to finish: 1 old replicas are pending termination...
Waiting for deployment "nginx-deployment" rollout to finish: 1 old replicas are pending termination...
deployment "nginx-deployment" successfully rolled out
student_04_07d6cc0c38f3@cloudshell:~/ak8s/Deployments (qwiklabs-gcp-01-506503ed76d1)$ kubectl get deployments
NAME               READY   UP-TO-DATE   AVAILABLE   AGE
nginx-deployment   3/3     3            3           11m
student_04_07d6cc0c38f3@cloudshell:~/ak8s/Deployments (qwiklabs-gcp-01-506503ed76d1)$
student_04_07d6cc0c38f3@cloudshell:~/ak8s/Deployments (qwiklabs-gcp-01-506503ed76d1)$
student_04_07d6cc0c38f3@cloudshell:~/ak8s/Deployments (qwiklabs-gcp-01-506503ed76d1)$
student_04_07d6cc0c38f3@cloudshell:~/ak8s/Deployments (qwiklabs-gcp-01-506503ed76d1)$ kubectl rollout undo deployments nginx-deployment
deployment.apps/nginx-deployment rolled back
student_04_07d6cc0c38f3@cloudshell:~/ak8s/Deployments (qwiklabs-gcp-01-506503ed76d1)$ kubectl rollout history deployment nginx-deployment
deployment.apps/nginx-deployment
REVISION  CHANGE-CAUSE
2         kubectl set image deployment.v1.apps/nginx-deployment nginx=nginx:1.9.1 --record=true
3         <none>

student_04_07d6cc0c38f3@cloudshell:~/ak8s/Deployments (qwiklabs-gcp-01-506503ed76d1)$ kubectl rollout history deployment/nginx-deployment --revision=3
deployment.apps/nginx-deployment with revision #3
Pod Template:
  Labels:       app=nginx
        pod-template-hash=5d59d67564
  Containers:
   nginx:
    Image:      nginx:1.7.9
    Port:       80/TCP
    Host Port:  0/TCP
    Environment:        <none>
    Mounts:     <none>
  Volumes:      <none>

student_04_07d6cc0c38f3@cloudshell:~/ak8s/Deployments (qwiklabs-gcp-01-506503ed76d1)$
student_04_07d6cc0c38f3@cloudshell:~/ak8s/Deployments (qwiklabs-gcp-01-506503ed76d1)$
student_04_07d6cc0c38f3@cloudshell:~/ak8s/Deployments (qwiklabs-gcp-01-506503ed76d1)$
```



### 작업 4. 매니페스트에서 서비스 유형 정의하기

```bash
student_04_07d6cc0c38f3@cloudshell:~/ak8s/Deployments (qwiklabs-gcp-01-506503ed76d1)$
student_04_07d6cc0c38f3@cloudshell:~/ak8s/Deployments (qwiklabs-gcp-01-506503ed76d1)$
student_04_07d6cc0c38f3@cloudshell:~/ak8s/Deployments (qwiklabs-gcp-01-506503ed76d1)$ ls -al
total 20
drwxr-xr-x  2 student_04_07d6cc0c38f3 student_04_07d6cc0c38f3 4096 Aug 22 13:30 .
drwxr-xr-x 20 student_04_07d6cc0c38f3 student_04_07d6cc0c38f3 4096 Aug 22 13:30 ..
-rw-r--r--  1 student_04_07d6cc0c38f3 student_04_07d6cc0c38f3  381 Aug 22 13:30 nginx-canary.yaml
-rw-r--r--  1 student_04_07d6cc0c38f3 student_04_07d6cc0c38f3  340 Aug 22 13:33 nginx-deployment.yaml
-rw-r--r--  1 student_04_07d6cc0c38f3 student_04_07d6cc0c38f3  168 Aug 22 13:30 service-nginx.yaml
student_04_07d6cc0c38f3@cloudshell:~/ak8s/Deployments (qwiklabs-gcp-01-506503ed76d1)$ cat ./service-nginx.yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx
spec:
  type: LoadBalancer
  selector:
    app: nginx
  ports:
  - protocol: TCP
    port: 60000
    targetPort: 80student_04_07d6cc0c38f3@cloudshell:~/ak8s/Deployments (qwiklabs-gcp-01-506503ed76d1)$
student_04_07d6cc0c38f3@cloudshell:~/ak8s/Deployments (qwiklabs-gcp-01-506503ed76d1)$ kubectl apply -f ./service-nginx.yaml
service/nginx created
student_04_07d6cc0c38f3@cloudshell:~/ak8s/Deployments (qwiklabs-gcp-01-506503ed76d1)$ kubectl get service nginx
NAME    TYPE           CLUSTER-IP    EXTERNAL-IP   PORT(S)           AGE
nginx   LoadBalancer   10.12.5.171   <pending>     60000:31810/TCP   18s
student_04_07d6cc0c38f3@cloudshell:~/ak8s/Deployments (qwiklabs-gcp-01-506503ed76d1)$ kubectl get service nginx
NAME    TYPE           CLUSTER-IP    EXTERNAL-IP   PORT(S)           AGE
nginx   LoadBalancer   10.12.5.171   <pending>     60000:31810/TCP   29s
student_04_07d6cc0c38f3@cloudshell:~/ak8s/Deployments (qwiklabs-gcp-01-506503ed76d1)$ kubectl get services nginx
NAME    TYPE           CLUSTER-IP    EXTERNAL-IP   PORT(S)           AGE
nginx   LoadBalancer   10.12.5.171   35.222.6.73   60000:31810/TCP   63s
student_04_07d6cc0c38f3@cloudshell:~/ak8s/Deployments (qwiklabs-gcp-01-506503ed76d1)$
student_04_07d6cc0c38f3@cloudshell:~/ak8s/Deployments (qwiklabs-gcp-01-506503ed76d1)$
```



### 작업 5. 카나리아 배포 수행하기

```bash
student_04_07d6cc0c38f3@cloudshell:~/ak8s/Deployments (qwiklabs-gcp-01-506503ed76d1)$
student_04_07d6cc0c38f3@cloudshell:~/ak8s/Deployments (qwiklabs-gcp-01-506503ed76d1)$
student_04_07d6cc0c38f3@cloudshell:~/ak8s/Deployments (qwiklabs-gcp-01-506503ed76d1)$
student_04_07d6cc0c38f3@cloudshell:~/ak8s/Deployments (qwiklabs-gcp-01-506503ed76d1)$
student_04_07d6cc0c38f3@cloudshell:~/ak8s/Deployments (qwiklabs-gcp-01-506503ed76d1)$ ls -al
total 20
drwxr-xr-x  2 student_04_07d6cc0c38f3 student_04_07d6cc0c38f3 4096 Aug 22 13:30 .
drwxr-xr-x 20 student_04_07d6cc0c38f3 student_04_07d6cc0c38f3 4096 Aug 22 13:30 ..
-rw-r--r--  1 student_04_07d6cc0c38f3 student_04_07d6cc0c38f3  381 Aug 22 13:30 nginx-canary.yaml
-rw-r--r--  1 student_04_07d6cc0c38f3 student_04_07d6cc0c38f3  340 Aug 22 13:33 nginx-deployment.yaml
-rw-r--r--  1 student_04_07d6cc0c38f3 student_04_07d6cc0c38f3  168 Aug 22 13:30 service-nginx.yaml
student_04_07d6cc0c38f3@cloudshell:~/ak8s/Deployments (qwiklabs-gcp-01-506503ed76d1)$ cat nginx-canary.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-canary
  labels:
    app: nginx
spec:
  replicas: 1
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
        track: canary
        Version: 1.9.1
    spec:
      containers:
      - name: nginx
        image: nginx:1.9.1
        ports:
        - containerPort: 80
student_04_07d6cc0c38f3@cloudshell:~/ak8s/Deployments (qwiklabs-gcp-01-506503ed76d1)$ kubectl apply -f nginx-canary.yaml
deployment.apps/nginx-canary created
student_04_07d6cc0c38f3@cloudshell:~/ak8s/Deployments (qwiklabs-gcp-01-506503ed76d1)$ kubectl get deployments
NAME               READY   UP-TO-DATE   AVAILABLE   AGE
nginx-canary       1/1     1            1           22s
nginx-deployment   3/3     3            3           18m
student_04_07d6cc0c38f3@cloudshell:~/ak8s/Deployments (qwiklabs-gcp-01-506503ed76d1)$ w
apiVersion: v1
 13:52:47 up 30 min,  3 users,  load average: 0.63, 0.40, 0.28
USER     TTY      FROM             LOGIN@   IDLE   JCPU   PCPU WHAT
student_ pts/0    127.0.0.1        13:27   25:25   0.00s  0.00s /bin/bash --norc --noprofile
student_ pts/1    127.0.0.1        13:27    5.00s  0.00s  0.00s tmux new-session -A -D -n cloudshell -s 1169973014
student_ pts/2    tmux(413).%0     13:27    5.00s  0.21s  0.00s w
student_04_07d6cc0c38f3@cloudshell:~/ak8s/Deployments (qwiklabs-gcp-01-506503ed76d1)$ kubectl scale --replicas=0 deployment nginx-deployment
deployment.apps/nginx-deployment scaled
student_04_07d6cc0c38f3@cloudshell:~/ak8s/Deployments (qwiklabs-gcp-01-506503ed76d1)$ kubectl get deployments
NAME               READY   UP-TO-DATE   AVAILABLE   AGE
nginx-canary       1/1     1            1           53s
nginx-deployment   0/0     0            0           19m
student_04_07d6cc0c38f3@cloudshell:~/ak8s/Deployments (qwiklabs-gcp-01-506503ed76d1)$ ls -al
total 20
drwxr-xr-x  2 student_04_07d6cc0c38f3 student_04_07d6cc0c38f3 4096 Aug 22 13:30 .
drwxr-xr-x 20 student_04_07d6cc0c38f3 student_04_07d6cc0c38f3 4096 Aug 22 13:30 ..
-rw-r--r--  1 student_04_07d6cc0c38f3 student_04_07d6cc0c38f3  381 Aug 22 13:30 nginx-canary.yaml
-rw-r--r--  1 student_04_07d6cc0c38f3 student_04_07d6cc0c38f3  340 Aug 22 13:33 nginx-deployment.yaml
-rw-r--r--  1 student_04_07d6cc0c38f3 student_04_07d6cc0c38f3  168 Aug 22 13:30 service-nginx.yaml
student_04_07d6cc0c38f3@cloudshell:~/ak8s/Deployments (qwiklabs-gcp-01-506503ed76d1)$ cat service-nginx.yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx
spec:
  type: LoadBalancer
  selector:
    app: nginx
  ports:
  - protocol: TCP
    port: 60000
    targetPort: 80student_04_07d6cc0c38f3@cloudshell:~/ak8s/Deployments (qwiklabs-gcp-01-506503ed76d1)$ cp -pa service-nginx.yaml 2-service-nginx.yaml                                                          
student_04_07d6cc0c38f3@cloudshell:~/ak8s/Deployments (qwiklabs-gcp-01-506503ed76d1)$ vi 2-service-nginx.yaml
student_04_07d6cc0c38f3@cloudshell:~/ak8s/Deployments (qwiklabs-gcp-01-506503ed76d1)$ cat ./2-service-nginx.yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx
spec:
  type: LoadBalancer
  sessionAffinity: ClientIP
  selector:
    app: nginx
  ports:
  - protocol: TCP
    port: 60000
    targetPort: 80
student_04_07d6cc0c38f3@cloudshell:~/ak8s/Deployments (qwiklabs-gcp-01-506503ed76d1)$
student_04_07d6cc0c38f3@cloudshell:~/ak8s/Deployments (qwiklabs-gcp-01-506503ed76d1)$
student_04_07d6cc0c38f3@cloudshell:~/ak8s/Deployments (qwiklabs-gcp-01-506503ed76d1)$
student_04_07d6cc0c38f3@cloudshell:~/ak8s/Deployments (qwiklabs-gcp-01-506503ed76d1)$
student_04_07d6cc0c38f3@cloudshell:~/ak8s/Deployments (qwiklabs-gcp-01-506503ed76d1)$
student_04_07d6cc0c38f3@cloudshell:~/ak8s/Deployments (qwiklabs-gcp-01-506503ed76d1)$ kubectl apply -f ./2-service-nginx.yaml
service/nginx configured
student_04_07d6cc0c38f3@cloudshell:~/ak8s/Deployments (qwiklabs-gcp-01-506503ed76d1)$ cat 2-service-nginx.yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx
spec:
  type: LoadBalancer
  sessionAffinity: ClientIP
  selector:
    app: nginx
  ports:
  - protocol: TCP
    port: 60000
    targetPort: 80
student_04_07d6cc0c38f3@cloudshell:~/ak8s/Deployments (qwiklabs-gcp-01-506503ed76d1)$
```







