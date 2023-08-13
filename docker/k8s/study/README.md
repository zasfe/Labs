

## 모든 VM 초기 APP 설치 스크립트

```
curl -fsSL https://raw.githubusercontent.com/zasfe/Labs/master/docker/k8s/study/pre-run.sh -o pre-run.sh
sudo sh pre-run.sh
```


## (master node) kubelet 설치 및 설정 스크립트

```
curl -fsSL https://raw.githubusercontent.com/zasfe/Labs/master/docker/k8s/study/master_node.sh -o master_node.sh 
sudo sh master_node.sh
```

## (worker node) kubelet에 연결 스크립트

```
curl -fsSL https://raw.githubusercontent.com/zasfe/Labs/master/docker/k8s/study/worker_node.sh -o worker_node.sh 
sudo sh worker_node.sh
```
