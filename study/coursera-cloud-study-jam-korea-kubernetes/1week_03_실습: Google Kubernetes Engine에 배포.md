# 실습: Google Kubernetes Engine에 배포

> 이 실습에서는 Google Cloud Console을 사용하여 GKE 클러스터를 빌드하고 샘플 pod를 배포합니다.

## 목표

이 실습에서는 다음 작업을 수행하는 방법을 알아봅니다.

  * Google Cloud 콘솔을 사용하여 GKE 클러스터 빌드 및 조작하기
  * Google Cloud 콘솔을 사용하여 포드 배포하기
  * Google Cloud 콘솔을 사용하여 클러스터 및 포드 검사하기

## 실습 참고

### GKE nginx deploy yaml

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  annotations:
    deployment.kubernetes.io/revision: "1"
  creationTimestamp: "2022-08-20T03:55:56Z"
  generation: 1
  labels:
    app: nginx-1
  managedFields:
  - apiVersion: apps/v1
    fieldsType: FieldsV1
    fieldsV1:
      f:metadata:
        f:labels:
          .: {}
          f:app: {}
      f:spec:
        f:progressDeadlineSeconds: {}
        f:replicas: {}
        f:revisionHistoryLimit: {}
        f:selector: {}
        f:strategy:
          f:rollingUpdate:
            .: {}
            f:maxSurge: {}
            f:maxUnavailable: {}
          f:type: {}
        f:template:
          f:metadata:
            f:labels:
              .: {}
              f:app: {}
          f:spec:
            f:containers:
              k:{"name":"nginx-1"}:
                .: {}
                f:image: {}
                f:imagePullPolicy: {}
                f:name: {}
                f:resources: {}
                f:terminationMessagePath: {}
                f:terminationMessagePolicy: {}
            f:dnsPolicy: {}
            f:restartPolicy: {}
            f:schedulerName: {}
            f:securityContext: {}
            f:terminationGracePeriodSeconds: {}
    manager: GoogleCloudConsole
    operation: Update
    time: "2022-08-20T03:55:56Z"
  - apiVersion: apps/v1
    fieldsType: FieldsV1
    fieldsV1:
      f:metadata:
        f:annotations:
          .: {}
          f:deployment.kubernetes.io/revision: {}
      f:status:
        f:availableReplicas: {}
        f:conditions:
          .: {}
          k:{"type":"Available"}:
            .: {}
            f:lastTransitionTime: {}
            f:lastUpdateTime: {}
            f:message: {}
            f:reason: {}
            f:status: {}
            f:type: {}
          k:{"type":"Progressing"}:
            .: {}
            f:lastTransitionTime: {}
            f:lastUpdateTime: {}
            f:message: {}
            f:reason: {}
            f:status: {}
            f:type: {}
        f:observedGeneration: {}
        f:readyReplicas: {}
        f:replicas: {}
        f:updatedReplicas: {}
    manager: kube-controller-manager
    operation: Update
    subresource: status
    time: "2022-08-20T03:56:01Z"
  name: nginx-1
  namespace: default
  resourceVersion: "3071"
  uid: a56804ee-efa4-422a-9798-ddeaec86a574
spec:
  progressDeadlineSeconds: 600
  replicas: 3
  revisionHistoryLimit: 10
  selector:
    matchLabels:
      app: nginx-1
  strategy:
    rollingUpdate:
      maxSurge: 25%
      maxUnavailable: 25%
    type: RollingUpdate
  template:
    metadata:
      creationTimestamp: null
      labels:
        app: nginx-1
    spec:
      containers:
      - image: nginx:latest
        imagePullPolicy: Always
        name: nginx-1
        resources: {}
        terminationMessagePath: /dev/termination-log
        terminationMessagePolicy: File
      dnsPolicy: ClusterFirst
      restartPolicy: Always
      schedulerName: default-scheduler
      securityContext: {}
      terminationGracePeriodSeconds: 30
status:
  availableReplicas: 3
  conditions:
  - lastTransitionTime: "2022-08-20T03:56:01Z"
    lastUpdateTime: "2022-08-20T03:56:01Z"
    message: Deployment has minimum availability.
    reason: MinimumReplicasAvailable
    status: "True"
    type: Available
  - lastTransitionTime: "2022-08-20T03:55:56Z"
    lastUpdateTime: "2022-08-20T03:56:01Z"
    message: ReplicaSet "nginx-1-754ddbcd6c" has successfully progressed.
    reason: NewReplicaSetAvailable
    status: "True"
    type: Progressing
  observedGeneration: 1
  readyReplicas: 3
  replicas: 3
  updatedReplicas: 3

```

### GKE nginx-1 pod YAML

```yaml
apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: "2022-08-20T03:55:56Z"
  generateName: nginx-1-754ddbcd6c-
  labels:
    app: nginx-1
    pod-template-hash: 754ddbcd6c
  managedFields:
  - apiVersion: v1
    fieldsType: FieldsV1
    fieldsV1:
      f:metadata:
        f:generateName: {}
        f:labels:
          .: {}
          f:app: {}
          f:pod-template-hash: {}
        f:ownerReferences:
          .: {}
          k:{"uid":"1b031a8d-0ff8-45c1-ab1c-899e42abbdc2"}: {}
      f:spec:
        f:containers:
          k:{"name":"nginx-1"}:
            .: {}
            f:image: {}
            f:imagePullPolicy: {}
            f:name: {}
            f:resources: {}
            f:terminationMessagePath: {}
            f:terminationMessagePolicy: {}
        f:dnsPolicy: {}
        f:enableServiceLinks: {}
        f:restartPolicy: {}
        f:schedulerName: {}
        f:securityContext: {}
        f:terminationGracePeriodSeconds: {}
    manager: kube-controller-manager
    operation: Update
    time: "2022-08-20T03:55:56Z"
  - apiVersion: v1
    fieldsType: FieldsV1
    fieldsV1:
      f:status:
        f:conditions:
          k:{"type":"ContainersReady"}:
            .: {}
            f:lastProbeTime: {}
            f:lastTransitionTime: {}
            f:status: {}
            f:type: {}
          k:{"type":"Initialized"}:
            .: {}
            f:lastProbeTime: {}
            f:lastTransitionTime: {}
            f:status: {}
            f:type: {}
          k:{"type":"Ready"}:
            .: {}
            f:lastProbeTime: {}
            f:lastTransitionTime: {}
            f:status: {}
            f:type: {}
        f:containerStatuses: {}
        f:hostIP: {}
        f:phase: {}
        f:podIP: {}
        f:podIPs:
          .: {}
          k:{"ip":"10.8.3.3"}:
            .: {}
            f:ip: {}
        f:startTime: {}
    manager: kubelet
    operation: Update
    subresource: status
    time: "2022-08-20T03:56:01Z"
  name: nginx-1-754ddbcd6c-tktg6
  namespace: default
  ownerReferences:
  - apiVersion: apps/v1
    blockOwnerDeletion: true
    controller: true
    kind: ReplicaSet
    name: nginx-1-754ddbcd6c
    uid: 1b031a8d-0ff8-45c1-ab1c-899e42abbdc2
  resourceVersion: "3068"
  uid: 48c4750d-162d-4b50-b9eb-cc61073fe2e8
spec:
  containers:
  - image: nginx:latest
    imagePullPolicy: Always
    name: nginx-1
    resources: {}
    terminationMessagePath: /dev/termination-log
    terminationMessagePolicy: File
    volumeMounts:
    - mountPath: /var/run/secrets/kubernetes.io/serviceaccount
      name: kube-api-access-fbt74
      readOnly: true
  dnsPolicy: ClusterFirst
  enableServiceLinks: true
  nodeName: gke-standard-cluster-1-default-pool-608b4103-svtv
  preemptionPolicy: PreemptLowerPriority
  priority: 0
  restartPolicy: Always
  schedulerName: default-scheduler
  securityContext: {}
  serviceAccount: default
  serviceAccountName: default
  terminationGracePeriodSeconds: 30
  tolerations:
  - effect: NoExecute
    key: node.kubernetes.io/not-ready
    operator: Exists
    tolerationSeconds: 300
  - effect: NoExecute
    key: node.kubernetes.io/unreachable
    operator: Exists
    tolerationSeconds: 300
  volumes:
  - name: kube-api-access-fbt74
    projected:
      defaultMode: 420
      sources:
      - serviceAccountToken:
          expirationSeconds: 3607
          path: token
      - configMap:
          items:
          - key: ca.crt
            path: ca.crt
          name: kube-root-ca.crt
      - downwardAPI:
          items:
          - fieldRef:
              apiVersion: v1
              fieldPath: metadata.namespace
            path: namespace
status:
  conditions:
  - lastProbeTime: null
    lastTransitionTime: "2022-08-20T03:55:56Z"
    status: "True"
    type: Initialized
  - lastProbeTime: null
    lastTransitionTime: "2022-08-20T03:56:01Z"
    status: "True"
    type: Ready
  - lastProbeTime: null
    lastTransitionTime: "2022-08-20T03:56:01Z"
    status: "True"
    type: ContainersReady
  - lastProbeTime: null
    lastTransitionTime: "2022-08-20T03:55:56Z"
    status: "True"
    type: PodScheduled
  containerStatuses:
  - containerID: containerd://f44c7607612f7210af244350d1aaf4bed2a9ce7a86abee98589e1657eab30096
    image: docker.io/library/nginx:latest
    imageID: docker.io/library/nginx@sha256:790711e34858c9b0741edffef6ed3d8199d8faa33f2870dea5db70f16384df79
    lastState: {}
    name: nginx-1
    ready: true
    restartCount: 0
    started: true
    state:
      running:
        startedAt: "2022-08-20T03:56:01Z"
  hostIP: 10.128.0.5
  phase: Running
  podIP: 10.8.3.3
  podIPs:
  - ip: 10.8.3.3
  qosClass: BestEffort
  startTime: "2022-08-20T03:55:56Z"

```


## 실습 결과

```bash


```
