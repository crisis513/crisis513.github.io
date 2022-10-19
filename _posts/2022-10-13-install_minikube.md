---
layout: post
title: "[Infra] Ubuntu 22.04 환경에서 minikube 설치하기"
date: 2021-10-13
desc: "[Infra] Ubuntu 22.04 환경에서 minikube 설치하기"
keywords: "son,blog,infra,docker,minikube,kubectl,kubernetes"
categories: [Infra]
tags: [son,blog,infra,docker,minikube,kubectl,kubernetes]
icon: icon-html
---

본 포스팅에서는 Ubuntu 22.04 환경에서 minikube를 설치하는 과정을 설명합니다.

---

## 목차

[1. 개요](#list1)

[&nbsp;&nbsp; 1.1. minikube란?](#list1_1)

[&nbsp;&nbsp; 1.2. 개발 환경](#list1_2)

[2. Docker 설치](#list2)

[3. minikube 설치 과정](#list3)

[&nbsp;&nbsp; 3.1. minikube 설치](#list3_1)

[&nbsp;&nbsp; 3.2. kubectl 설치](#list3_2)

[&nbsp;&nbsp; 3.3. minikube 실행 및 종료](#list3_3)

---

## <span style="color:purple">**1. 개요**</span> <a name="list1"></a>

<br>

### 1.1. minikube란? <a name="list1_1"></a>

  minikube는 다양한 OS에서 로컬 Kubernetes 클러스터를 구현할 수 있도록 도와주는 **오픈 소스 도구**입니다. minikube의 주요 목표는 로컬 Kubernetes 애플리케이션 개발을 위한 도구들과 그에 맞는 모든 **Kubernetes 기능을 지원**하는 것 입니다. 로컬에서 리소스 활용이 적은 단일 노드 kubernetes 클러스터를 구동시킬 수 있기 때문에 개발 테스트 및 POC 목적으로 사용하기 좋습니다.

  자세한 설명은 [minikube 웹사이트](https://minikube.sigs.k8s.io/docs "minikube")를 통해 확인하시기 바랍니다.

<br>

### 1.2. 개발 환경 <a name="list1_2"></a>

  필자는 실습을 위해 **VMWare Workstation 16.2**에서 **Ubuntu 22.04 LTS Desktop** 이미지로 가상머신을 생성하여 진행하였습니다. 해당 환경에서 **Docker**를 설치하고, **minikube**에서 드라이버로 Docker를 사용하여 Kubernetes 구성 요소를 여기에 설치해볼 예정입니다.

<br>

## <span style="color:purple">**2. Docker 설치**</span> <a name="list2"></a>

minikube를 설치하기 위해서는 드라이버를 설정해주어야 하는데, minikube는 virtualbox와 같은 VM, Docker와 같은 컨테이너 또는 베어메탈 등 다양한 드라이버를 지원하고 있습니다. 이 중에서 본 포스팅에서는 Docker를 드라이버로 사용하여 진행할 것 입니다.

Docker를 설치하기 전에 모든 시스템 패키지를 최신 릴리스로 업데이트 해야 합니다.
  
```bash
son@son-localhost $ sudo apt update
son@son-localhost $ sudo apt install apt-transport-https
son@son-localhost $ sudo apt upgrade
```

혹시나 재부팅이 필요한 경우 재부팅을 하고난 다음 설치를 진행하면 됩니다. 

Docker는 `get.docker.com`에서 지원하는 **스크립트를 다운받아 실행**해주기만 하면 되기 때문에 간단하게 설치할 수 있습니다. 

```bash
son@son-localhost $ curl -fsSL https://get.docker.com -o get-docker.sh
son@son-localhost $ sudo sh get-docker.sh
# Executing docker install script, commit: 4f282167c425347a931ccfd95cc91fab041d414f
+ sh -c apt-get update -qq >/dev/null
+ sh -c DEBIAN_FRONTEND=noninteractive apt-get install -y -qq apt-transport-https ca-certificates curl >/dev/null
+ sh -c mkdir -p /etc/apt/keyrings && chmod -R 0755 /etc/apt/keyrings
+ sh -c curl -fsSL "https://download.docker.com/linux/ubuntu/gpg" | gpg --dearmor --yes -o /etc/apt/keyrings/docker.gpg
+ sh -c chmod a+r /etc/apt/keyrings/docker.gpg
+ sh -c echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu jammy stable" > /etc/apt/sources.list.d/docker.list
+ sh -c apt-get update -qq >/dev/null
+ sh -c DEBIAN_FRONTEND=noninteractive apt-get install -y -qq --no-install-recommends docker-ce docker-ce-cli containerd.io docker-compose-plugin docker-scan-plugin >/dev/null
+ version_gte 20.10
+ [ -z  ]
+ return 0
+ sh -c DEBIAN_FRONTEND=noninteractive apt-get install -y -qq docker-ce-rootless-extras >/dev/null
+ sh -c docker version
Client: Docker Engine - Community
  Version:           20.10.18
  API version:       1.41
  Go version:        go1.18.6
  Git commit:        b40c2f6
  Built:             Thu Sep  8 23:11:43 2022
  OS/Arch:           linux/amd64
  Context:           default
  Experimental:      true

Server: Docker Engine - Community
  Engine:
  Version:          20.10.18
  API version:      1.41 (minimum version 1.12)
  Go version:       go1.18.6
  Git commit:       e42327a
  Built:            Thu Sep  8 23:09:30 2022
  OS/Arch:          linux/amd64
  Experimental:     false
  containerd:
  Version:          1.6.8
  GitCommit:        9cd3357b7fd7218e4aec3eae239db1f68a5a6ec6
  runc:
  Version:          1.1.4
  GitCommit:        v1.1.4-0-g5fd4c4d
  docker-init:
  Version:          0.19.0
  GitCommit:        de40ad0

================================================================================

To run Docker as a non-privileged user, consider setting up the
Docker daemon in rootless mode for your user:

    dockerd-rootless-setuptool.sh install

Visit https://docs.docker.com/go/rootless/ to learn about rootless mode.

To run the Docker daemon as a fully privileged service, but granting non-root
users access, refer to https://docs.docker.com/go/daemon-access/

WARNING: Access to the remote API on a privileged Docker daemon is equivalent
          to root access on the host. Refer to the 'Docker daemon attack surface'
          documentation for details: https://docs.docker.com/go/attack-surface/

================================================================================
```

get-docker.sh란 이름으로 스크립트를 다운받아 실행해주어 Docker를 설치하고 아래 명령어를 통해 Docker 어느 버전으로 설치되었는지 확인해보겠습니다.


```bash
son@son-localhost $ docker --version
Docker version 20.10.18, build b40c2f6
```

Docker가 정상적으로 설치가 되긴 했지만, 현재 상태로 minikube에서 Docker를 드라이버로 설정하여 설치할 때 permission denied 에러가 발생할 것 입니다. 에러를 사전에 방지하기 위해 Docker를 일반 유저도 쓸 수 있도록 설정해주겠습니다.

```bash
son@son-localhost $ sudo usermod -aG docker $USER && newgrp docker
```

추가로 docker-compose를 사용할 것이라면 다음 명령을 통해 docker-compose를 설치할 수도 있습니다.

```bash
son@son-localhost $ sudo apt install docker-compose
son@son-localhost $ docker-compose --version
docker-compose version 1.29.2, build unknown
```

<br>

## <span style="color:purple">**3. minikube 설치 과정**</span> <a name="list3"></a>

위의 과정을 통해 Docker를 정상적으로 설치하였다면 다음으로 minikube를 설치하겠습니다.

<br>

### 3.1. minikube 설치 <a name="list3_1"></a>

  minikube를 설치하기 위해서는 **minikube 바이너리를 다운로드**해야 합니다. 바이너리를 다운받아 **실행 권한을 준 다음 /usr/local/bin 디렉토리 아래에 넣을 것**입니다.

  ```bash
  son@son-localhost $ wget https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
  --2022-10-13 04:03:24--  https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
  Resolving storage.googleapis.com (storage.googleapis.com)... 34.64.4.112, 34.64.4.80, 34.64.4.16, ...
  Connecting to storage.googleapis.com (storage.googleapis.com)|34.64.4.112|:443... connected.
  HTTP request sent, awaiting response... 200 OK
  Length: 76629407 (73M) [application/octet-stream]
  Saving to: ‘minikube-linux-amd64’
  
  minikube-linux-amd64        100%[===========================================>]  73.08M  5.17MB/s    in 13s
  
  2022-10-13 04:03:38 (5.72 MB/s) - ‘minikube-linux-amd64’ saved [76629407/76629407]
  
  son@son-localhost $ chmod +x minikube-linux-amd64
  son@son-localhost $ sudo mv minikube-linux-amd64 /usr/local/bin/minikube
  ```

  minikube 바이너리 파일을 /usr/local/bin 디렉토리 아래에 두었다면 다음 명령어를 통해 설치된 minikube 버전을 확인해보겠습니다.

  ```bash
  son@son-localhost $ minikube version
  minikube version: v1.27.1
  commit: fe869b5d4da11ba318eb84a3ac00f336411de7ba
  ```

  > 혹시나 minikube가 실행되지 않는다면 $PATH에 /usr/local/bin이 없기 때문일 것입니다. 
  > 다른 $PATH로 위치를 옮기거나 $PATH에 /usr/local/bin 위치를 추가해야 합니다.

  <br>
    
### 3.2. kubectl 설치 <a name="list3_2"></a>

  minikube를 설치하더라도 **Kubernetes에서 애플리케이션을 배포하고 관리하기 위해 사용되는 도구인 kubectl**을 따로 설치해야 합니다. 마찬가지로 kubectl 바이너리 파일을 다운받아 실행권한을 준 다음 /usr/local/bin 위치로 옮겨주겠습니다.
    
  ```bash
  son@son-localhost $ curl -LO https://storage.googleapis.com/kubernetes-release/release/`curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt`/bin/linux/amd64/kubectl
    % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                    Dload  Upload   Total   Spent    Left  Speed
  100 42.9M  100 42.9M    0     0  8035k      0  0:00:05  0:00:05 --:--:-- 8355k
  son@son-localhost $ chmod +x ./kubectl
  son@son-localhost $ sudo mv ./kubectl /usr/local/bin/kubectl
  ```

  kubectl 바이너리 파일을 /usr/local/bin 디렉토리 아래에 두었다면 다음 명령어를 통해 설치된 kubectl 버전을 확인해보겠습니다. 

  ```bash
  son@son-localhost $ kubectl version -o json --client
  {
    "clientVersion": {
      "major": "1",
      "minor": "25",
      "gitVersion": "v1.25.2",
      "gitCommit": "5835544ca568b757a8ecae5c153f317e5736700e",
      "gitTreeState": "clean",
      "buildDate": "2022-09-21T14:33:49Z",
      "goVersion": "go1.19.1",
      "compiler": "gc",
      "platform": "linux/amd64"
    },
    "kustomizeVersion": "v4.5.7"
  }
  ```

  <br>

### 3.3. minikube 실행 및 종료 <a name="list3_3"></a>
  
  minikube를 실행시키기 위해서는 다음과 같이 minikube start 명령을 사용하면 됩니다.

  ```bash
  son@son-localhost $ minikube start
  * minikube v1.27.1 on Ubuntu 22.04
  * Automatically selected the docker driver. Other choices: ssh, none
  * Using Docker driver with root privileges
  * Starting control plane node minikube in cluster minikube
  * Pulling base image ...
  * Downloading Kubernetes v1.25.2 preload ...
      > preloaded-images-k8s-v18-v1...:  385.41 MiB / 385.41 MiB  100.00% 4.47 Mi
      > gcr.io/k8s-minikube/kicbase:  387.10 MiB / 387.11 MiB  100.00% 3.68 MiB p
      > gcr.io/k8s-minikube/kicbase:  0 B [________________________] ?% ? p/s 58s
  * Creating docker container (CPUs=2, Memory=2200MB) ...
  * Preparing Kubernetes v1.25.2 on Docker 20.10.18 ...
    - Generating certificates and keys ...
    - Booting up control plane ...
    - Configuring RBAC rules ...
  * Verifying Kubernetes components...
    - Using image gcr.io/k8s-minikube/storage-provisioner:v5
  * Enabled addons: default-storageclass, storage-provisioner
  * Done! kubectl is now configured to use "minikube" cluster and "default" namespace by default
  ```

  아무런 옵션도 기입하지 않으면 위에서 설치했던 Docker를 드라이버로 잡고, kicbase 이미지를 받아 CPU 2 core와 Memory 2200MB를 자동으로 잡는 것을 확인할 수 있습니다. 

  > 여기서 kicbase 이미지는 통신하기 위해 프록시의 역할을 하는 것으로 알고 있습나다. 
  > 해당 이미지가 없다면 docker pull을 통해 받아오거나, VPN 또는 HTTP/HTTPS 프록시를 환경 변수로 사용하여 minikube start 해야합니다.

  minikube가 정상적으로 실행되었다면 kubectl 명령을 통해 생성된 클러스터 정보와 설정을 확인해보도록 하겠습니다.

  ```bash
  son@son-localhost $ kubectl cluster-info
  Kubernetes control plane is running at https://192.168.49.2:8443
  CoreDNS is running at https://192.168.49.2:8443/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy

  To further debug and diagnose cluster problems, use 'kubectl cluster-info dump'.
  
  son@son-localhost $ kubectl config view
  apiVersion: v1
  clusters:
  - cluster:
      certificate-authority: /home/son/.minikube/ca.crt
      extensions:
      - extension:
          last-update: Thu, 13 Oct 2022 21:29:21 KST
          provider: minikube.sigs.k8s.io
          version: v1.27.1
        name: cluster_info
      server: https://192.168.49.2:8443
    name: minikube
  contexts:
  - context:
      cluster: minikube
      extensions:
      - extension:
          last-update: Thu, 13 Oct 2022 21:29:21 KST
          provider: minikube.sigs.k8s.io
          version: v1.27.1
        name: context_info
      namespace: default
      user: minikube
    name: minikube
  current-context: minikube
  kind: Config
  preferences: {}
  users:
  - name: minikube
    user:
      client-certificate: /home/son/.minikube/profiles/minikube/client.crt
      client-key: /home/son/.minikube/profiles/minikube/client.key
  ```

  minikube를 종료하고 싶다면 다음과 같이 minikube stop 명령을 통해 종료할 수 있습니다.

  ```bash
  son@son-localhost $ minikube stop
  * Stopping node "minikube"  ...
  * Powering off "minikube" via SSH ...
  * 1 node stopped.
  ```
  
<br>
