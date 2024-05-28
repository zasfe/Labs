# 실습: Google Kubernetes Engine용 영구 스토리지 구성하기

  * https://www.coursera.org/learn/google-kubernetes-engine-ko/gradedLti/CeJVO/silseub-google-kubernetes-engineyong-yeonggu-seutoriji-guseonghagi

이 실습에서는 PersistentVolume 및 PersistentVolumeClaim을 설정합니다. PersistentVolume은 Kubernetes 클러스터에 사용할 수 있는 스토리지입니다. PersistentVolumeClaim을 사용하면 pod가 PersistentVolume에 액세스할 수 있습니다. PersistentVolumeClaim이 없으면 pod가 주로 일시적이기 때문에 pod 확장, 업데이트 또는 마이그레이션 이후에도 유지되어야 하는 모든 데이터에 대해 PersistentVolumeClaim을 사용해야 합니다.

> 이 실습에서는 영구 볼륨과 영구 볼륨 클레임을 설정합니다 영구 볼륨은 Kubernetes 클러스터에서 사용할 수 있는 스토리지입니다 영구 볼륨 클레임을 통해 포드는 영구 볼륨에 액세스할 수 있습니다 영구 볼륨 클레임이 없으면 포드는 대부분 임시적입니다 따라서 포드 확장과 업데이트, 마이그레이션 이후에도 유지되어야 하는 모든 데이터에 대해 영구 볼륨 클레임을 사용해야 합니다 수행할 작업에는 Compute Engine 영구 디스크에 대한 영구 볼륨과 영구 볼륨 클레임의 매니페스트 만들기, Compute Engine 영구 디스크 PVC를 포드의 볼륨으로 마운트하기, 매니페스트를 사용하여 스테이트풀(Stateful) 세트 만들기가 포함됩니다 또한 Compute Engine 영구 디스크 PVC를 스테이트풀(Stateful) 세트의 볼륨으로 마운트하고 포드가 중지되었다가 다시 시작될 때 스테이트풀(Stateful) 세트의 포드와 특정 PV의 연결을 확인합니다

## 개요

이 실습에서는 PersistentVolume 및 PersistentVolumeClaim을 설정합니다. PersistentVolume은 Kubernetes 클러스터에 사용할 수 있는 스토리지입니다. PersistentVolumeClaim을 사용하면 포드가 PersistentVolume에 액세스할 수 있습니다. PersistentVolumeClaim이 없으면 포드가 주로 일시적이기 때문에 pod 확장, 업데이트 또는 마이그레이션 이후에도 유지되어야 하는 모든 데이터에 대해 PersistentVolumeClaim을 사용해야 합니다.

## 목표
이 실습에서는 다음 작업을 수행하는 방법을 알아봅니다.

  * Google Cloud 영구 디스크(동적으로 만들어진 항목 또는 기존 항목)로 사용할 PersistentVolume(PV) 및 PersistentVolumeClaim(PVC)에 대한 매니페스트 만들기
  * Google Cloud 영구 디스크 PVC를 포드의 볼륨으로 마운트하기
  * 매니페스트를 사용하여 StatefulSet 만들기
  * Google Cloud 영구 디스크 PVC를 StatefulSet의 볼륨으로 마운트하기
  * 포드가 중지되었다가 다시 시작될 때 StatefulSet의 포드와 특정 PV의 연결 확인하기

### 작업 0. 실습 설정

```bash
Welcome to Cloud Shell! Type "help" to get started.
Your Cloud Platform project in this session is set to qwiklabs-gcp-03-bb672f532fde.
Use “gcloud config set project [PROJECT_ID]” to change to a different project.
student_03_06512ce6ccc4@cloudshell:~ (qwiklabs-gcp-03-bb672f532fde)$ gcloud auth list
Credentialed Accounts

ACTIVE: *
ACCOUNT: student-03-06512ce6ccc4@qwiklabs.net

To set the active account, run:
    $ gcloud config set account `ACCOUNT`

student_03_06512ce6ccc4@cloudshell:~ (qwiklabs-gcp-03-bb672f532fde)$ gcloud config list project
[core]
project = qwiklabs-gcp-03-bb672f532fde

Your active configuration is: [cloudshell-22871]
student_03_06512ce6ccc4@cloudshell:~ (qwiklabs-gcp-03-bb672f532fde)$
```

### 작업 1. PV 및 PVC 만들기

```bash
student_03_06512ce6ccc4@cloudshell:~ (qwiklabs-gcp-03-bb672f532fde)$ # 실습 GKE 클러스터에 연결하기
student_03_06512ce6ccc4@cloudshell:~ (qwiklabs-gcp-03-bb672f532fde)$ export my_zone=us-central1-a
student_03_06512ce6ccc4@cloudshell:~ (qwiklabs-gcp-03-bb672f532fde)$ export my_cluster=standard-cluster-1
student_03_06512ce6ccc4@cloudshell:~ (qwiklabs-gcp-03-bb672f532fde)$ source <(kubectl completion bash)
student_03_06512ce6ccc4@cloudshell:~ (qwiklabs-gcp-03-bb672f532fde)$ gcloud container clusters get-credentials $my_cluster --zone $my_zone
Fetching cluster endpoint and auth data.
kubeconfig entry generated for standard-cluster-1.
student_03_06512ce6ccc4@cloudshell:~ (qwiklabs-gcp-03-bb672f532fde)$ # PVC를 사용하여 매니페스트 생성 및 적용하기
student_03_06512ce6ccc4@cloudshell:~ (qwiklabs-gcp-03-bb672f532fde)$ git clone https://github.com/GoogleCloudPlatform/training-data-analyst
Cloning into 'training-data-analyst'...
remote: Enumerating objects: 59907, done.
remote: Counting objects: 100% (330/330), done.
remote: Compressing objects: 100% (175/175), done.
remote: Total 59907 (delta 174), reused 270 (delta 140), pack-reused 59577
Receiving objects: 100% (59907/59907), 680.30 MiB | 23.78 MiB/s, done.
Resolving deltas: 100% (38004/38004), done.
Updating files: 100% (12650/12650), done.
student_03_06512ce6ccc4@cloudshell:~ (qwiklabs-gcp-03-bb672f532fde)$ ln -s ~/training-data-analyst/courses/ak8s/v1.1 ~/ak8s
student_03_06512ce6ccc4@cloudshell:~ (qwiklabs-gcp-03-bb672f532fde)$ cd ~/ak8s/Storage/
student_03_06512ce6ccc4@cloudshell:~/ak8s/Storage (qwiklabs-gcp-03-bb672f532fde)$ kubectl get persistentvolumeclaim
No resources found in default namespace.
student_03_06512ce6ccc4@cloudshell:~/ak8s/Storage (qwiklabs-gcp-03-bb672f532fde)$ ls -al
total 20
drwxr-xr-x  2 student_03_06512ce6ccc4 student_03_06512ce6ccc4 4096 Aug 26 23:50 .
drwxr-xr-x 20 student_03_06512ce6ccc4 student_03_06512ce6ccc4 4096 Aug 26 23:50 ..
-rw-r--r--  1 student_03_06512ce6ccc4 student_03_06512ce6ccc4  302 Aug 26 23:50 pod-volume-demo.yaml
-rw-r--r--  1 student_03_06512ce6ccc4 student_03_06512ce6ccc4  163 Aug 26 23:50 pvc-demo.yaml
-rw-r--r--  1 student_03_06512ce6ccc4 student_03_06512ce6ccc4  857 Aug 26 23:50 statefulset-demo.yaml
student_03_06512ce6ccc4@cloudshell:~/ak8s/Storage (qwiklabs-gcp-03-bb672f532fde)$ cat ./pvc-demo.yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: hello-web-disk
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 30Gi
student_03_06512ce6ccc4@cloudshell:~/ak8s/Storage (qwiklabs-gcp-03-bb672f532fde)$ cat ./pod-volume-demo.yaml
kind: Pod
apiVersion: v1
metadata:
  name: pvc-demo-pod
spec:
  containers:
    - name: frontend
      image: nginx
      volumeMounts:
      - mountPath: "/var/www/html"
        name: pvc-demo-volume
  volumes:
    - name: pvc-demo-volume
      persistentVolumeClaim:
        claimName: hello-web-disk
student_03_06512ce6ccc4@cloudshell:~/ak8s/Storage (qwiklabs-gcp-03-bb672f532fde)$ cat ./statefulset-demo.yaml
kind: Service
apiVersion: v1
metadata:
  name: statefulset-demo-service
spec:
  ports:
  - protocol: TCP
    port: 80
    targetPort: 9376
  type: LoadBalancer
---

apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: statefulset-demo
spec:
  selector:
    matchLabels:
      app: MyApp
  serviceName: statefulset-demo-service
  replicas: 3
  updateStrategy:
    type: RollingUpdate
  template:
    metadata:
      labels:
        app: MyApp
    spec:
      containers:
      - name: stateful-set-container
        image: nginx
        ports:
        - containerPort: 80
          name: http
        volumeMounts:
        - name: hello-web-disk
          mountPath: "/var/www/html"
  volumeClaimTemplates:
  - metadata:
      name: hello-web-disk
    spec:
      accessModes: [ "ReadWriteOnce" ]
      resources:
        requests:
          storage: 30Gi
student_03_06512ce6ccc4@cloudshell:~/ak8s/Storage (qwiklabs-gcp-03-bb672f532fde)$
student_03_06512ce6ccc4@cloudshell:~/ak8s/Storage (qwiklabs-gcp-03-bb672f532fde)$
student_03_06512ce6ccc4@cloudshell:~/ak8s/Storage (qwiklabs-gcp-03-bb672f532fde)$ cat ./pod-volume-demo.yaml
kind: Pod
apiVersion: v1
metadata:
  name: pvc-demo-pod
spec:
  containers:
    - name: frontend
      image: nginx
      volumeMounts:
      - mountPath: "/var/www/html"
        name: pvc-demo-volume
  volumes:
    - name: pvc-demo-volume
      persistentVolumeClaim:
        claimName: hello-web-di
skstudent_03_06512ce6ccc4@cloudshell:~/ak8s/Storage (qwiklabs-gcp-03-bb672f532fde)$ cat ./pvc-demo.yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: hello-web-disk
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 30Gi
student_03_06512ce6ccc4@cloudshell:~/ak8s/Storage (qwiklabs-gcp-03-bb672f532fde)$
student_03_06512ce6ccc4@cloudshell:~/ak8s/Storage (qwiklabs-gcp-03-bb672f532fde)$ kubectl apply -f pvc-demo.yaml
persistentvolumeclaim/hello-web-disk created
student_03_06512ce6ccc4@cloudshell:~/ak8s/Storage (qwiklabs-gcp-03-bb672f532fde)$ kubectl get persistentvolumeclaim
NAME             STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
hello-web-disk   Bound    pvc-8cab666f-70a6-4a93-9d00-4b829a8e8610   30Gi       RWO            standard       15s
student_03_06512ce6ccc4@cloudshell:~/ak8s/Storage (qwiklabs-gcp-03-bb672f532fde)$
```

### 작업 2. 포드에서 Google Cloud 영구 디스크 PVC 마운트하고 확인하기

> 매니페스트 파일 pod-volume-demo.yaml은 nginx 컨테이너를 배포하고, pvc-demo-volume을 포드에 연결하고, 해당 볼륨을 nginx 컨테이너 내부의 경로 /var/www/html에 마운트합니다. 컨테이너 내부에 있는 이 디렉터리에 저장된 파일은 영구 볼륨에 저장되며, 포드와 컨테이너가 종료되었다가 다시 만들어지더라도 유지됩니다.

```yaml
kind: Pod
apiVersion: v1
metadata:
  name: pvc-demo-pod
spec:
  containers:
    - name: frontend
      image: nginx
      volumeMounts:
      - mountPath: "/var/www/html"
        name: pvc-demo-volume
  volumes:
    - name: pvc-demo-volume
      persistentVolumeClaim:
        claimName: hello-web-disk
```


```bash
student_03_06512ce6ccc4@cloudshell:~/ak8s/Storage (qwiklabs-gcp-03-bb672f532fde)$
student_03_06512ce6ccc4@cloudshell:~/ak8s/Storage (qwiklabs-gcp-03-bb672f532fde)$
student_03_06512ce6ccc4@cloudshell:~/ak8s/Storage (qwiklabs-gcp-03-bb672f532fde)$ # 작업 2. 포드에서 Google Cloud 영구 디스크 PVC 마운트하고 확인하기
student_03_06512ce6ccc4@cloudshell:~/ak8s/Storage (qwiklabs-gcp-03-bb672f532fde)$ ## 포드에 PVC 마운트하기
student_03_06512ce6ccc4@cloudshell:~/ak8s/Storage (qwiklabs-gcp-03-bb672f532fde)$ kubectl get persistentvolumeclaim
NAME             STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
hello-web-disk   Bound    pvc-8cab666f-70a6-4a93-9d00-4b829a8e8610   30Gi       RWO            standard       4m41s
student_03_06512ce6ccc4@cloudshell:~/ak8s/Storage (qwiklabs-gcp-03-bb672f532fde)$ cat pod-volume-demo.yaml
kind: Pod
apiVersion: v1
metadata:
  name: pvc-demo-pod
spec:
  containers:
    - name: frontend
      image: nginx
      volumeMounts:
      - mountPath: "/var/www/html"
        name: pvc-demo-volume
  volumes:
    - name: pvc-demo-volume
      persistentVolumeClaim:
        claimName: hello-web-disk
student_03_06512ce6ccc4@cloudshell:~/ak8s/Storage (qwiklabs-gcp-03-bb672f532fde)$
student_03_06512ce6ccc4@cloudshell:~/ak8s/Storage (qwiklabs-gcp-03-bb672f532fde)$ kubectl apply -f pod-volume-demo.yaml
pod/pvc-demo-pod created
student_03_06512ce6ccc4@cloudshell:~/ak8s/Storage (qwiklabs-gcp-03-bb672f532fde)$ kubectl get pods
NAME           READY   STATUS              RESTARTS   AGE
pvc-demo-pod   0/1     ContainerCreating   0          11s
student_03_06512ce6ccc4@cloudshell:~/ak8s/Storage (qwiklabs-gcp-03-bb672f532fde)$ kubectl get pods
NAME           READY   STATUS    RESTARTS   AGE
pvc-demo-pod   1/1     Running   0          34s
student_03_06512ce6ccc4@cloudshell:~/ak8s/Storage (qwiklabs-gcp-03-bb672f532fde)$ kubectl exec -it pvc-demo-pod -- sh
# echo Test webpage in a persistent volume!>/var/www/html/index.html
chmod +x /var/www/html/index.html#
# cat /var/www/html/index.html
Test webpage in a persistent volume!
# exit
student_03_06512ce6ccc4@cloudshell:~/ak8s/Storage (qwiklabs-gcp-03-bb672f532fde)$
student_03_06512ce6ccc4@cloudshell:~/ak8s/Storage (qwiklabs-gcp-03-bb672f532fde)$
student_03_06512ce6ccc4@cloudshell:~/ak8s/Storage (qwiklabs-gcp-03-bb672f532fde)$ ## PV의 지속성 테스트하기
student_03_06512ce6ccc4@cloudshell:~/ak8s/Storage (qwiklabs-gcp-03-bb672f532fde)$ kubectl delete pod pvc-demo-pod
pod "pvc-demo-pod" deleted
student_03_06512ce6ccc4@cloudshell:~/ak8s/Storage (qwiklabs-gcp-03-bb672f532fde)$ kubectl get pods
No resources found in default namespace.
student_03_06512ce6ccc4@cloudshell:~/ak8s/Storage (qwiklabs-gcp-03-bb672f532fde)$ kubectl get persistentvolumeclaim
NAME             STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
hello-web-disk   Bound    pvc-8cab666f-70a6-4a93-9d00-4b829a8e8610   30Gi       RWO            standard       8m2s
student_03_06512ce6ccc4@cloudshell:~/ak8s/Storage (qwiklabs-gcp-03-bb672f532fde)$ kubectl apply -f pod-volume-demo.yaml
pod/pvc-demo-pod created
student_03_06512ce6ccc4@cloudshell:~/ak8s/Storage (qwiklabs-gcp-03-bb672f532fde)$ kubectl get pods
NAME           READY   STATUS    RESTARTS   AGE
pvc-demo-pod   1/1     Running   0          8s
student_03_06512ce6ccc4@cloudshell:~/ak8s/Storage (qwiklabs-gcp-03-bb672f532fde)$ kubectl exec -it pvc-demo-pod -- sh
# cat /var/www/html/index.html
Test webpage in a persistent volume!
# exit
student_03_06512ce6ccc4@cloudshell:~/ak8s/Storage (qwiklabs-gcp-03-bb672f532fde)$
```

### 작업 3. PVC로 StatefulSet 만들기

> 매니페스트 파일 statefulset-demo.yaml은 LoadBalancer 서비스와 포드의 복제본 3개(nginx 컨테이너 및 이름이 hello-web-disk인 30GB PVC용 volumeClaimTemplate이 포함됨)를 포함하는 StatefulSet를 만듭니다. nginx 컨테이너는 이전 작업에서처럼 /var/www/htm에 hello-web-disk라는 PVC를 마운트합니다.

```yml
kind: Service
apiVersion: v1
metadata:
  name: statefulset-demo-service
spec:
  ports:
  - protocol: TCP
    port: 80
    targetPort: 9376
  type: LoadBalancer
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: statefulset-demo
spec:
  selector:
    matchLabels:
      app: MyApp
  serviceName: statefulset-demo-service
  replicas: 3
  updateStrategy:
    type: RollingUpdate
  template:
    metadata:
      labels:
        app: MyApp
    spec:
      containers:
      - name: stateful-set-container
        image: nginx
        ports:
        - containerPort: 80
          name: http
        volumeMounts:
        - name: hello-web-disk
          mountPath: "/var/www/html"
  volumeClaimTemplates:
  - metadata:
      name: hello-web-disk
    spec:
      accessModes: [ "ReadWriteOnce" ]
      resources:
        requests:
          storage: 30Gi
```

```bash
student_03_06512ce6ccc4@cloudshell:~/ak8s/Storage (qwiklabs-gcp-03-bb672f532fde)$ # 작업 3. PVC로 StatefulSet 만들기
student_03_06512ce6ccc4@cloudshell:~/ak8s/Storage (qwiklabs-gcp-03-bb672f532fde)$ ## PVC 할당 해제하기
student_03_06512ce6ccc4@cloudshell:~/ak8s/Storage (qwiklabs-gcp-03-bb672f532fde)$
student_03_06512ce6ccc4@cloudshell:~/ak8s/Storage (qwiklabs-gcp-03-bb672f532fde)$ kubectl delete pod pvc-demo-pod
pod "pvc-demo-pod" deleted
student_03_06512ce6ccc4@cloudshell:~/ak8s/Storage (qwiklabs-gcp-03-bb672f532fde)$ kubectl get pods
No resources found in default namespace.
student_03_06512ce6ccc4@cloudshell:~/ak8s/Storage (qwiklabs-gcp-03-bb672f532fde)$
student_03_06512ce6ccc4@cloudshell:~/ak8s/Storage (qwiklabs-gcp-03-bb672f532fde)$ ## StatefulSet 만들기
student_03_06512ce6ccc4@cloudshell:~/ak8s/Storage (qwiklabs-gcp-03-bb672f532fde)$
student_03_06512ce6ccc4@cloudshell:~/ak8s/Storage (qwiklabs-gcp-03-bb672f532fde)$ cat ./statefulset-demo.yaml
kind: Service
apiVersion: v1
metadata:
  name: statefulset-demo-service
spec:
  ports:
  - protocol: TCP
    port: 80
    targetPort: 9376
  type: LoadBalancer
---

apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: statefulset-demo
spec:
  selector:
    matchLabels:
      app: MyApp
  serviceName: statefulset-demo-service
  replicas: 3
  updateStrategy:
    type: RollingUpdate
  template:
    metadata:
      labels:
        app: MyApp
    spec:
      containers:
      - name: stateful-set-container
        image: nginx
        ports:
        - containerPort: 80
          name: http
        volumeMounts:
        - name: hello-web-disk
          mountPath: "/var/www/html"
  volumeClaimTemplates:
  - metadata:
      name: hello-web-disk
    spec:
      accessModes: [ "ReadWriteOnce" ]
      resources:
        requests:
          storage: 30Gistudent_03_06512ce6ccc4@cloudshell:~/ak8s/Storage (qwiklabs-gcp-03-bb672f532fde)$
student_03_06512ce6ccc4@cloudshell:~/ak8s/Storage (qwiklabs-gcp-03-bb672f532fde)$ kubectl apply -f statefulset-demo.yaml
service/statefulset-demo-service created
statefulset.apps/statefulset-demo created
student_03_06512ce6ccc4@cloudshell:~/ak8s/Storage (qwiklabs-gcp-03-bb672f532fde)$
student_03_06512ce6ccc4@cloudshell:~/ak8s/Storage (qwiklabs-gcp-03-bb672f532fde)$ ## StatefulSet에서 포드의 연결 확인하기
student_03_06512ce6ccc4@cloudshell:~/ak8s/Storage (qwiklabs-gcp-03-bb672f532fde)$
student_03_06512ce6ccc4@cloudshell:~/ak8s/Storage (qwiklabs-gcp-03-bb672f532fde)$ kubectl describe statefulset statefulset-demo
Name:               statefulset-demo
Namespace:          default
CreationTimestamp:  Sat, 27 Aug 2022 00:04:35 +0000
Selector:           app=MyApp
Labels:             <none>
Annotations:        <none>
Replicas:           3 desired | 2 total
Update Strategy:    RollingUpdate
Pods Status:        1 Running / 1 Waiting / 0 Succeeded / 0 Failed
Pod Template:
  Labels:  app=MyApp
  Containers:
   stateful-set-container:
    Image:        nginx
    Port:         80/TCP
    Host Port:    0/TCP
    Environment:  <none>
    Mounts:
      /var/www/html from hello-web-disk (rw)
  Volumes:  <none>
Volume Claims:
  Name:          hello-web-disk
  StorageClass:
  Labels:        <none>
  Annotations:   <none>
  Capacity:      30Gi
  Access Modes:  [ReadWriteOnce]
Events:
  Type    Reason            Age   From                    Message
  ----    ------            ----  ----                    -------
  Normal  SuccessfulCreate  26s   statefulset-controller  create Claim hello-web-disk-statefulset-demo-0 Pod statefulset-demo-0 in StatefulSet statefulset-demo success
  Normal  SuccessfulCreate  26s   statefulset-controller  create Pod statefulset-demo-0 in StatefulSet statefulset-demo successful
  Normal  SuccessfulCreate  7s    statefulset-controller  create Claim hello-web-disk-statefulset-demo-1 Pod statefulset-demo-1 in StatefulSet statefulset-demo success
  Normal  SuccessfulCreate  7s    statefulset-controller  create Pod statefulset-demo-1 in StatefulSet statefulset-demo successful
student_03_06512ce6ccc4@cloudshell:~/ak8s/Storage (qwiklabs-gcp-03-bb672f532fde)$ kubectl get pods
NAME                 READY   STATUS    RESTARTS   AGE
statefulset-demo-0   1/1     Running   0          63s
statefulset-demo-1   1/1     Running   0          44s
statefulset-demo-2   1/1     Running   0          20s
student_03_06512ce6ccc4@cloudshell:~/ak8s/Storage (qwiklabs-gcp-03-bb672f532fde)$ kubectl get pvc
NAME                                STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
hello-web-disk                      Bound    pvc-8cab666f-70a6-4a93-9d00-4b829a8e8610   30Gi       RWO            standard       13m
hello-web-disk-statefulset-demo-0   Bound    pvc-89bd83c9-6b42-4613-a45e-6b9e89e0c2c5   30Gi       RWO            standard       75s
hello-web-disk-statefulset-demo-1   Bound    pvc-dd550b92-328a-440c-97e7-c8f3e388864b   30Gi       RWO            standard       56s
hello-web-disk-statefulset-demo-2   Bound    pvc-70f23d54-31d2-4447-a043-4cbead47633a   30Gi       RWO            standard       32s
student_03_06512ce6ccc4@cloudshell:~/ak8s/Storage (qwiklabs-gcp-03-bb672f532fde)$ kubectl describe pvc hello-web-disk-statefulset-demo-0
Name:          hello-web-disk-statefulset-demo-0
Namespace:     default
StorageClass:  standard
Status:        Bound
Volume:        pvc-89bd83c9-6b42-4613-a45e-6b9e89e0c2c5
Labels:        app=MyApp
Annotations:   pv.kubernetes.io/bind-completed: yes
               pv.kubernetes.io/bound-by-controller: yes
               volume.beta.kubernetes.io/storage-provisioner: pd.csi.storage.gke.io
Finalizers:    [kubernetes.io/pvc-protection]
Capacity:      30Gi
Access Modes:  RWO
VolumeMode:    Filesystem
Used By:       statefulset-demo-0
Events:
  Type    Reason                 Age                From                                                                                              Message
  ----    ------                 ----               ----                                                                                              -------
  Normal  ExternalProvisioning   95s (x2 over 95s)  persistentvolume-controller                                                                       waiting for a volume to be created, either by external provisioner "pd.csi.storage.gke.io" or manually created by system administrator
  Normal  Provisioning           95s                pd.csi.storage.gke.io_gke-b2a13072c34a4567bac6-a69d-4333-vm_82152533-5ccf-47a9-838a-114662d593ca  External provisioner is provisioning volume for claim "default/hello-web-disk-statefulset-demo-0"
  Normal  ProvisioningSucceeded  91s                pd.csi.storage.gke.io_gke-b2a13072c34a4567bac6-a69d-4333-vm_82152533-5ccf-47a9-838a-114662d593ca  Successfully provisioned volume pvc-89bd83c9-6b42-4613-a45e-6b9e89e0c2c5
student_03_06512ce6ccc4@cloudshell:~/ak8s/Storage (qwiklabs-gcp-03-bb672f532fde)$
student_03_06512ce6ccc4@cloudshell:~/ak8s/Storage (qwiklabs-gcp-03-bb672f532fde)$
student_03_06512ce6ccc4@cloudshell:~/ak8s/Storage (qwiklabs-gcp-03-bb672f532fde)$
```

### 작업 4. StatefulSet가 관리하는 포드에 대한 영구 볼륨 연결의 지속성 확인하기



```bash
student_03_06512ce6ccc4@cloudshell:~/ak8s/Storage (qwiklabs-gcp-03-bb672f532fde)$
student_03_06512ce6ccc4@cloudshell:~/ak8s/Storage (qwiklabs-gcp-03-bb672f532fde)$ 
student_03_06512ce6ccc4@cloudshell:~/ak8s/Storage (qwiklabs-gcp-03-bb672f532fde)$ # 작업 4. StatefulSet가 관리하는 포드에 대한 영구 볼륨 연결의 지속성 확인하기
student_03_06512ce6ccc4@cloudshell:~/ak8s/Storage (qwiklabs-gcp-03-bb672f532fde)$
student_03_06512ce6ccc4@cloudshell:~/ak8s/Storage (qwiklabs-gcp-03-bb672f532fde)$ kubectl get pods
NAME                 READY   STATUS    RESTARTS   AGE
statefulset-demo-0   1/1     Running   0          3m32s
statefulset-demo-1   1/1     Running   0          3m13s
statefulset-demo-2   1/1     Running   0          2m49s
student_03_06512ce6ccc4@cloudshell:~/ak8s/Storage (qwiklabs-gcp-03-bb672f532fde)$ kubectl exec -it statefulset-demo-0 -- sh
# cat /var/www/html/index.html
cat: /var/www/html/index.html: No such file or directory
# echo Test webpage in a persistent volume!>/var/www/html/index.html
chmod +x /var/www/html/index.html#
# cat /var/www/html/index.html
Test webpage in a persistent volume!
# exit
student_03_06512ce6ccc4@cloudshell:~/ak8s/Storage (qwiklabs-gcp-03-bb672f532fde)$ kubectl delete pod statefulset-demo-0
pod "statefulset-demo-0" deleted
student_03_06512ce6ccc4@cloudshell:~/ak8s/Storage (qwiklabs-gcp-03-bb672f532fde)$ kubectl get pods
NAME                 READY   STATUS              RESTARTS   AGE
statefulset-demo-0   0/1     ContainerCreating   0          5s
statefulset-demo-1   1/1     Running             0          4m25s
statefulset-demo-2   1/1     Running             0          4m1s
student_03_06512ce6ccc4@cloudshell:~/ak8s/Storage (qwiklabs-gcp-03-bb672f532fde)$ time

real    0m0.000s
user    0m0.000s
sys     0m0.000s
student_03_06512ce6ccc4@cloudshell:~/ak8s/Storage (qwiklabs-gcp-03-bb672f532fde)$ date
Sat 27 Aug 2022 12:09:35 AM UTC
student_03_06512ce6ccc4@cloudshell:~/ak8s/Storage (qwiklabs-gcp-03-bb672f532fde)$ kubectl get pods
NAME                 READY   STATUS    RESTARTS   AGE
statefulset-demo-0   1/1     Running   0          27s
statefulset-demo-1   1/1     Running   0          4m47s
statefulset-demo-2   1/1     Running   0          4m23s
student_03_06512ce6ccc4@cloudshell:~/ak8s/Storage (qwiklabs-gcp-03-bb672f532fde)$ date
Sat 27 Aug 2022 12:09:44 AM UTC
student_03_06512ce6ccc4@cloudshell:~/ak8s/Storage (qwiklabs-gcp-03-bb672f532fde)$ kubectl exec -it statefulset-demo-0 -- sh
# cat /var/www/html/index.html
Test webpage in a persistent volume!
# exit
student_03_06512ce6ccc4@cloudshell:~/ak8s/Storage (qwiklabs-gcp-03-bb672f532fde)$
```

### 실습 종료하기










