# compute

- last update : 2026-10-05

## claude

| 항목 | 사양 |
| 가상화 | KVM 기반 마이크로VM(커널 이름이 fc이므로 Firecracker로 추정됩니다) | 
| OS | Ubuntu 24.04.5 LTS, Linux 6.18.44 | 
| CPU | Intel Xeon @ 2.10GHz, 2 vCPU(x86_64, 코어당 1스레드) | 
| 메모리 | 7.8GiB(스왑 없음) | 
| 디스크 | 현재 약 30GB를 쓸 수 있습니다. 볼륨 전체는 252GB이지만 세션마다 할당량이 정해져 있습니다 |.
| GPU | 없습니다. | 


## chatgpt

 | 항목 | 사양 | 
| CPU |  Intel Xeon Platinum 8573C CPU 할당 <br> 9개 논리 CPU가 표시되며, 실제 사용 한도는 8 vCPU입니다. |
| 메모리 | 시스템에는 9.7 GiB가 표시되며, 작업 환경 한도는 8 GiB입니다. |
| 디스크 | 작업 경로 기준 전체 32 GiB이며, 약 30 GiB가 남아 있습니다. |
| GPU | 현재 환경에서 GPU 장치가 확인되지 않습니다. |
| 운영체제 | Ubuntu 24.04.3 LTS, x86_64 |
| 커널 | Linux 6.18.44 |
| 가상화 | KVM 기반입니다. |
| 스왑 | 없습니다. |
