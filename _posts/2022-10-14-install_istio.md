---
layout: post
title: "[Infra] minikube에서 istio 설치하기"
date: 2021-10-14
desc: "[Infra] minikube에서 istio 설치하기"
keywords: "son,blog,infra,docker,minikube,kubectl,kubernetes,istio"
categories: [Infra]
tags: [son,blog,infra,docker,minikube,kubectl,kubernetes,istio]
icon: icon-html
---

[개발 환경](http://crisis513.github.io/infra/2021/10/13/install_minikube.html#list1_2 "개발 환경")은 이전 포스팅과 동일하니 참고바랍니다.

---

## 목차

[1. istio란?](#list1)

[2. istio 설치 과정](#list2)

[&nbsp;&nbsp; 2.1. istio 최소 사양](#list2_1)

[&nbsp;&nbsp; 2.2. metallb 설치 및 설정](#list2_2)

[&nbsp;&nbsp; 2.3. istio 설치](#list2_3)

---

## <span style="color:purple">**1. istio란?**</span> <a name="list1"></a>

대부분의 서비스 메시와 마찬가지로 istio는 `사이드카(sidecar)` 라는 프록시 컨테이너로 기존 애플리케이션 컨테이너를 보완합니다. 사이드카 프록시로 Envoy를 사용하고, 아래와 같이 서비스 컨테이너에서 오가는 네트워크 트래픽을 가로채고 전용 네트워크를 통해 트래픽을 다시 라우팅합니다.

| ![istio-architecture](/static/assets/img/landing/infra/istio1.png){: width="80%"} |
|:--:| 
| [그림 1] istio 아키텍처 |

<br>

먼저, Envoy 프록시는 다음과 같은 기능을 가집니다.

- TCP, HTTP1, HTTP2, gRPC protocol 지원
- TLS client certification
- L7 라우팅 지원 및 URL 기반, 버퍼링, 서버간 부하 분산량 조절
- Auto retry / Circuit Breaker 지원 / 다양한 로드밸런싱 기능 제공
- Zipkin을 통한 분산 트랜잭션 성능 측정 제공
- Dynamic configuration 지원, 중앙 레지스트리에 설정 및 설정 정보를 동적으로 읽어옴
- MongoDB에 대한 L7 라우팅 기능

Control Plane은 Data Plane을 컨트롤하는 부분으로써 pilot, citadel, galley, Mixer(istio-1.5.0 부터는 istiod로 통합)로 구성되어 있고, 서비스 디스커버리, 설정 관리, 인증 관리 역할을 수행합니다. 

<br>

## <span style="color:purple">**2. istio 설치 과정**</span> <a name="list2"></a>

<br>

### 2.1. istio 최소 사양 <a name="list2_1"></a>

  istio는 istioctl, helm, Istio Operator 등 다양한 방법으로 설치할 수 있고, minikube에서는 istio를 추가 기능으로 제공하고 있긴 하지만 **본 포스팅에서는 istioctl로 설치**해볼 것 입니다. istio는 minikube에서 작동하기 위해 `4개의 vCPU와 8GB의 RAM이 필요`합니다. 참고로 minikube 가상 머신에 할당된 RAM이 충분하지 않으면 다음과 같은 오류가 발생할 수 있습니다.

  - 이미지 가져오기 실패
  - 상태 확인 시간 초과 실패
  - 호스트의 kubectl 오류
  - 가상 머신과 호스트의 일반적인 네트워크 불안정
  - 가상 머신의 완전한 잠금
  - 호스트 NMI 워치독 재부팅

위에서 설명한대로 vCPU 4개와 8GB RAM의 조건을 충족하기 위해 다음 명령을 통해 minikube를 실행하겠습니다.

  ```bash
  son@son-localhost $ minikube start --cpus=4 --memory=8g
  * minikube v1.27.1 on Ubuntu 22.04
  * Using the docker driver based on existing profile

  X The requested memory allocation of 8192MiB does not leave room for system overhead (total system memory: 8481MiB). You may face stability issues.
  * Suggestion: Start minikube with less memory allocated: 'minikube start --memory=2200mb'

  ! You cannot change the memory size for an existing minikube cluster. Please first delete the cluster.
  ! You cannot change the CPUs for an existing minikube cluster. Please first delete the cluster.
  * Starting control plane node minikube in cluster minikube
  * Pulling base image ...
  * Restarting existing docker container for "minikube" ...
  * Preparing Kubernetes v1.25.2 on Docker 20.10.18 ...
  * Verifying Kubernetes components...
    - Using image gcr.io/k8s-minikube/storage-provisioner:v5
    - Using image docker.io/kubernetesui/dashboard:v2.7.0
    - Using image docker.io/kubernetesui/metrics-scraper:v1.0.8
  * Enabled addons: storage-provisioner, default-storageclass, dashboard
  * Done! kubectl is now configured to use "minikube" cluster and "default" namespace by default
  ```

  minikube에서 지원하는 여러가지 기능들을 addons를 통해 확인할 수 있는데, 여기에 istio도 있는 것을 확인할 수 있습니다. 앞서 언급하였듯 istioctl을 통해 설치를 진행할 것 입니다.

  <br>

### 2.2. metallb 설치 및 설정 <a name="list2_2"></a>

  minikube가 istio에서 사용할 로드 밸런서를 제공하도록 하려면 minikube tunnel 기능을 사용할 수 있지만 본 포스팅에서는 tunnel 기능을 사용하지 않고, metallb를 사용해볼 것 입니다. 그리고 metallb는 addons에 있는 기능으로 사용할 것 입니다. 우선 addons를 확인해보겠습니다.

  > 만약 metallb를 사용하지 않고 minikube tunnel을 사용한다면 아래 명령어를 새로운 터미널 창을 띄워 실행시키면 되겠습니다.
  >
  > $ minikube tunnel

  ```bash
  son@son-localhost $ minikube addons list
  |-----------------------------|----------|--------------|--------------------------------|
  |         ADDON NAME          | PROFILE  |    STATUS    |           MAINTAINER           |
  |-----------------------------|----------|--------------|--------------------------------|
  | ambassador                  | minikube | disabled     | 3rd party (Ambassador)         |
  | auto-pause                  | minikube | disabled     | Google                         |
  | csi-hostpath-driver         | minikube | disabled     | Kubernetes                     |
  | dashboard                   | minikube | disabled     | Kubernetes                     |
  | default-storageclass        | minikube | enabled ✅   | Kubernetes                     |
  | efk                         | minikube | disabled     | 3rd party (Elastic)            |
  | freshpod                    | minikube | disabled     | Google                         |
  | gcp-auth                    | minikube | disabled     | Google                         |
  | gvisor                      | minikube | disabled     | Google                         |
  | headlamp                    | minikube | disabled     | 3rd party (kinvolk.io)         |
  | helm-tiller                 | minikube | disabled     | 3rd party (Helm)               |
  | inaccel                     | minikube | disabled     | 3rd party (InAccel             |
  |                             |          |              | [info@inaccel.com])            |
  | ingress                     | minikube | disabled     | Kubernetes                     |
  | ingress-dns                 | minikube | disabled     | Google                         |
  | istio                       | minikube | disabled     | 3rd party (Istio)              |
  | istio-provisioner           | minikube | disabled     | 3rd party (Istio)              |
  | kong                        | minikube | disabled     | 3rd party (Kong HQ)            |
  | kubevirt                    | minikube | disabled     | 3rd party (KubeVirt)           |
  | logviewer                   | minikube | disabled     | 3rd party (unknown)            |
  | metallb                     | minikube | disabled     | 3rd party (MetalLB)            |
  | metrics-server              | minikube | disabled     | Kubernetes                     |
  | nvidia-driver-installer     | minikube | disabled     | Google                         |
  | nvidia-gpu-device-plugin    | minikube | disabled     | 3rd party (Nvidia)             |
  | olm                         | minikube | disabled     | 3rd party (Operator Framework) |
  | pod-security-policy         | minikube | disabled     | 3rd party (unknown)            |
  | portainer                   | minikube | disabled     | 3rd party (Portainer.io)       |
  | registry                    | minikube | disabled     | Google                         |
  | registry-aliases            | minikube | disabled     | 3rd party (unknown)            |
  | registry-creds              | minikube | disabled     | 3rd party (UPMC Enterprises)   |
  | storage-provisioner         | minikube | enabled ✅   | Google                         |
  | storage-provisioner-gluster | minikube | disabled     | 3rd party (Gluster)            |
  | volumesnapshots             | minikube | disabled     | Kubernetes                     |
  |-----------------------------|----------|--------------|--------------------------------|
  ```

  현재 metallb가 사용되고 있지 않기 떄문에 disabled 상태인 것을 확인할 수 있습니다. minikube addons에서 metallb를 활성화 시켜보겠습니다.

  ```bash
  son@son-localhost $ minikube addons enable metallb
  ! metallb is a 3rd party addon and not maintained or verified by minikube maintainers, enable at your own risk.
    - Using image docker.io/metallb/speaker:v0.9.6
    - Using image docker.io/metallb/controller:v0.9.6
  * The 'metallb' addon is enabled
  son@son-localhost $ kubectl get ns
  NAME              STATUS   AGE
  default           Active   125m
  kube-node-lease   Active   125m
  kube-public       Active   125m
  kube-system       Active   125m
  metallb-system    Active   39s
  son@son-localhost $ kubectl get all -n metallb-system
  NAME                              READY   STATUS    RESTARTS   AGE
  pod/controller-55496b5cd7-52h5q   1/1     Running   0          56s
  pod/speaker-cfvms                 1/1     Running   0          56s

  NAME                     DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR                 AGE
  daemonset.apps/speaker   1         1         1       1            1           beta.kubernetes.io/os=linux   56s

  NAME                         READY   UP-TO-DATE   AVAILABLE   AGE
  deployment.apps/controller   1/1     1            1           56s

  NAME                                    DESIRED   CURRENT   READY   AGE
  replicaset.apps/controller-55496b5cd7   1         1         1       56s

  son@son-localhost $ kubectl get configmap config -n metallb-system -o yaml
  apiVersion: v1
  data:
    config: |
      address-pools:
      - name: default
        protocol: layer2
        addresses:
        - -
  kind: ConfigMap
  metadata:
    annotations:
      kubectl.kubernetes.io/last-applied-configuration: |
        {"apiVersion":"v1","data":{"config":"address-pools:\n- name: default\n  protocol: layer2\n  addresses:\n  - -\n"},"kind":"ConfigMap","metadata":{"annotations":{},"name":"config","namespace":"metallb-system"}}
    creationTimestamp: "2022-10-13T14:34:11Z"
    name: config
    namespace: metallb-system
    resourceVersion: "5621"
    uid: 0a5fd834-87f0-4191-a093-aa9cd25f5f35
  ```

  minikube에서 metallb를 활성화시키면 metallb-system이라는 네임 스페이스가 생기는데, controller라는 deployment와 speaker라는 daemonset이 동작하는 것을 확인할 수 있고 configmap도 생성된 것을 확인할 수 있습니다. configmap 내용을 보면 프로토콜이 **Layer2**로 동작하고, 주소 풀이 비어있는 것을 확인할 수 있습니다. 

  metallb는 기본적으로 외부에 연결할 수 있는 IP 대역대가 있다면 metallb에서 IP 대역을 지정하여 IP를 할당해줄 수 있는데, 우리는 로컬 환경에서 구축하고 있기 때문에 External IP 대신 로컬에서 접속할 수 있는 IP 대역대를 입력해줄 것 입니다. 여기서 metallb를 통해 External IP가 설정된 주소 풀에 맞게 할당되도록 설정해보겠습니다.
  
  ```bash
  son@son-localhost $ minikube addons configure metallb
  -- Enter Load Balancer Start IP: `192.168.49.100`
  -- Enter Load Balancer End IP: `192.168.49.120`
    - Using image docker.io/metallb/speaker:v0.9.6
    - Using image docker.io/metallb/controller:v0.9.6
  * metallb was successfully configured
  son@son-localhost $ kubectl get configmap config -n metallb-system -o yaml
  apiVersion: v1
  data:
    config: |
      address-pools:
      - name: default
        protocol: layer2
        addresses:
        - 192.168.49.100-192.168.49.120
  kind: ConfigMap
  metadata:
    annotations:
      kubectl.kubernetes.io/last-applied-configuration: |
        {"apiVersion":"v1","data":{"config":"address-pools:\n- name: default\n  protocol: layer2\n  addresses:\n  - 192.168.49.100-192.168.49.120\n"},"kind":"ConfigMap","metadata":{"annotations":{},"name":"config","namespace":"metallb-system"}}
    creationTimestamp: "2022-10-13T14:34:11Z"
    name: config
    namespace: metallb-system
    resourceVersion: "5805"
    uid: 0a5fd834-87f0-4191-a093-aa9cd25f5f35
  ```

  여기서 필자는 Enter Load Balancer Start IP 부분에 192.168.49.100을, End IP 부분에 192.168.49.120을 입력하였습니다. 여기서 192.168.49.x 대역대는 필자의 개발환경에서 minikube가 사용하는 내부 네트워크의 대역대 입니다. **만약 실습을 따라하고 있는 사람이 있다면 각자 환경에 맞는 IP를 기입해야 할 것 입니다.**

  <br>

### 2.3. istio 설치 <a name="list2_3"></a>

  다음으로 istio 설치 파일을 다운받아 설치해보겠습니다. 

  ```bash
  son@son-localhost $ curl -L https://istio.io/downloadIstio | sh -
    % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                  Dload  Upload   Total   Spent    Left  Speed
  100   101  100   101    0     0    247      0 --:--:-- --:--:-- --:--:--   247
  100  4856  100  4856    0     0   8533      0 --:--:-- --:--:-- --:--:--  237k

  Downloading istio-1.15.2 from https://github.com/istio/istio/releases/download/1.15.2/istio-1.15.2-linux-amd64.tar.gz ...

  Istio 1.15.2 Download Complete!

  Istio has been successfully downloaded into the istio-1.15.2 folder on your system.

  Next Steps:
  See https://istio.io/latest/docs/setup/install/ to add Istio to your Kubernetes cluster.

  To configure the istioctl client tool for your workstation,
  add the /home/son/istio-1.15.2/bin directory to your environment path variable with:
          export PATH="$PATH:/home/son/istio-1.15.2/bin"

  Begin the Istio pre-installation check by running:
          istioctl x precheck

  Need more information? Visit https://istio.io/latest/docs/setup/install/
  son@son-localhost $ export PATH="$PATH:/home/son/istio-1.15.2/bin"
  son@son-localhost $ which istioctl
  /home/son/istio-1.15.2/bin/istioctl
  son@son-localhost $ istioctl version
  client version: 1.15.2
  control plane version: 1.12.1
  data plane version: 1.12.1 (2 proxies)
  ```

  설치할 당시의 istio 최신 버전을 다운받았고, bin 폴더에 있는 istioctl 바이너리 파일을 통해 istio를 설치할 것 입니다. 위의 istio 다운로드 스크립트를 실행했을 때 안내된 대로 `istioctl x precheck` 명령을 사용하여 설치 요구사항을 충족하고, 설치시 문제없이 안전하게 설치할 수 있는지 사전 검사를 진행해보고나서 설치하겠습니다.

  ```bash
  son@son-localhost $ istioctl x precheck
  ✔ No issues found when checking the cluster. Istio is safe to install or upgrade!
    To get started, check out https://istio.io/latest/docs/setup/getting-started/
  son@son-localhost $ istioctl install --set profile=demo -y
  ✔ Istio core installed
  ✔ Istiod installed
  ✔ Ingress gateways installed
  ✔ Egress gateways installed
  ✔ Installation complete       
  Making this installation the default for injection and validation.

  Thank you for installing Istio 1.15.  Please take a few minutes to tell us about your install/upgrade experience!  https://forms.gle/SWHFBmwJspusK1hv6
  son@son-localhost $ kubectl get all -n istio-system
  NAME                                        READY   STATUS    RESTARTS   AGE
  pod/istio-egressgateway-fffc799cf-kd26t     1/1     Running   0          64s
  pod/istio-ingressgateway-7d68764b55-ckkc5   1/1     Running   0          64s
  pod/istiod-5456fd558d-x6jpf                 1/1     Running   0          93s

  NAME                           TYPE           CLUSTER-IP       EXTERNAL-IP     PORT(S)                                                                      AGE
  service/istio-egressgateway    ClusterIP      10.105.237.74    <none>          80/TCP,443/TCP                                                               10m
  service/istio-ingressgateway   LoadBalancer   10.97.166.77     192.168.49.100  15021:32414/TCP,80:30295/TCP,443:30180/TCP,31400:30731/TCP,15443:30050/TCP   10m
  service/istiod                 ClusterIP      10.109.182.176   <none>          15010/TCP,15012/TCP,443/TCP,15014/TCP                                        10m

  NAME                                   READY   UP-TO-DATE   AVAILABLE   AGE
  deployment.apps/istio-egressgateway    1/1     1            1           10m
  deployment.apps/istio-ingressgateway   1/1     1            1           10m
  deployment.apps/istiod                 1/1     1            1           10m

  NAME                                              DESIRED   CURRENT   READY   AGE
  replicaset.apps/istio-egressgateway-fffc799cf     1         1         1       64s
  replicaset.apps/istio-ingressgateway-7d68764b55   1         1         1       64s
  replicaset.apps/istiod-5456fd558d                 1         1         1       93s
  ```

  istio 디렉토리의 manifests/profiles 경로를 보면 다양한 매니페스트 파일이 존재하는 것을 확인할 수 있는데, 테스트 용도로 설치해보기 위해 demo 매니페스트를 kubernetes에 배포하였습니다. 성공적으로 배포가 되었다면 `istio-system`이라는 네임 스페이스가 생성되는 것을 확인할 수 있습니다. 

  그리고 istio-ingressgateway 로드밸런서 서비스의 External IP가 192.168.49.100으로 할당되어 있는 것을 확인할 수 있습니다. 앞서 metallb를 설치하고 IP 풀을 할당해줬기 때문에 metallb에서 istio-ingressgateway라는 로드밸런서 타입의 서비스에 External IP를 부여해준 것 입니다. 현재 테스트 환경을 간단하게 그림으로 그려보자면 다음 [그림 2]과 같습니다.

  | ![metallb-istio](/static/assets/img/landing/infra/istio2.png){: width="576" height="384"} |
  |:--:| 
  | [그림 2] metallb와 istio 테스트 환경 |

  <br>
