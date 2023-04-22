---
layout: post
title: "[Infra] Kubernetes kube-monkey 사용기"
date: 2022-10-31
desc: "[Infra] Kubernetes kube-monkey 사용기"
keywords: "infra,minikube,kubernetes,chaos,kube-monkey"
categories: []
tags: [infra,minikube,kubernetes,chaos,kube-monkey]
icon: icon-html
---

본 포스팅에서는 Kubernetes에서 kube-monkey를 사용하여 Pod Fault를 실습해볼 것이다. 필자가 DevSecOps 파이프라인 구축 프로젝트를 진행할 때 앱을 배포하면서 Chaos Monkey를 통해 각종 장애에 대한 테스트를 진행하는 과정을 추가해볼 계획이었지만 갑작스런 입대로 인해 적용시키지 못했던 것이 아쉬워 살펴보는 시간을 가져보았다.

---

## 목차

[1. kube-monkey란?](#list1)

[2. kube-monkey 실습](#list2)

[&nbsp;&nbsp; 2.1. 실습 환경 구성](#list2_1)

[&nbsp;&nbsp; 2.2. kube-monkey 배포](#list2_2)

---

## **1. kube-monkey란?** <a name="list1"></a>

  kube-monkey는 Netflix의 Chaos Monkey를 Kubernetes 환경에서 사용할 수 있도록 간단하게 구현된 오픈소스 도구이다. Kubernetes 클러스터에서 Kube API를 통해 Pod를 무작위로 삭제하여 장애에 대한 복구가 정상 동작하는지 확인할 수 있다. **기존의 Chaos Monkey와는 달리 노드 자체를 방해하거나 네트워크 또는 IO에 영향을 미치는 기능을 제공하지 않으며 순전히 Pod를 죽이는 기능만 제공하고** 있다. 해당 기능을 통해 구성 및 배포가 빠르며 Pod 장애에 대한 복구를 시뮬레이션 및 테스트해볼 수 있고, 모든 것이 얼마나 빨리 정상화되는지 확인할 수 있다.

  <br>

## **2. kube-monkey 실습** <a name="list2"></a>

<br>

### **2.1. 실습 환경 구성** <a name="list2_1"></a>

  우선 Kubernetes 클러스터 환경이 필요하다. 여기서는 Minikube와 kubectl이 설치되어 있고, **minikube를 통해 Kubernetes 클러스터를 구성**하여 사용하여 실습에 필요한 [해당 Git 레포지토리](https://github.com/asobti/kube-monkey)를 다운받아 실습을 진행해볼 것이다.

  ```bash
  son@son-localhost ~ $ minikube start --cpus=4 --memory=8g
  * minikube v1.27.1 on Ubuntu 22.04
  * Using the docker driver based on existing profile

  X The requested memory allocation of 8192MiB does not leave room for system overhead (total system memory: 9103MiB). You may face stability issues.
  * Suggestion: Start minikube with less memory allocated: 'minikube start --memory=2200mb'

  ! You cannot change the memory size for an existing minikube cluster. Please first delete the cluster.
  ! You cannot change the CPUs for an existing minikube cluster. Please first delete the cluster.
  * Starting control plane node minikube in cluster minikube
  * Pulling base image ...
  * Restarting existing docker container for "minikube" ...
  * Preparing Kubernetes v1.25.2 on Docker 20.10.18 ...
  * Verifying Kubernetes components...
  - Using image docker.io/metallb/controller:v0.9.6
  - Using image docker.io/metallb/speaker:v0.9.6
  - Using image gcr.io/k8s-minikube/storage-provisioner:v5
  * Enabled addons: default-storageclass, storage-provisioner, metallb
  * Done! kubectl is now configured to use "minikube" cluster and "default" namespace by default

  son@son-localhost ~ $ git clone https://github.com/asobti/kube-monkey
  Cloning into 'kube-monkey'...
  remote: Enumerating objects: 14804, done.
  remote: Counting objects: 100% (277/277), done.
  remote: Compressing objects: 100% (159/159), done.
  remote: Total 14804 (delta 119), reused 222 (delta 93), pack-reused 14527
  Receiving objects: 100% (14804/14804), 30.68 MiB | 4.75 MiB/s, done.
  Resolving deltas: 100% (6565/6565), done.
  son@son-localhost ~ $ cd kube-monkey
  ```

  그리고 kube-monkey 배포를 위해 helm을 설치하겠다. 필자는 Ubuntu 22.04에서 실습을 진행하기 때문에 다음 명령어를 통해 helm을 설치하지만, 각자 환경에 맞는 설치법을 찾아 설치해주면 된다.

  ```bash
  son@son-localhost ~/kube-monkey $ sudo snap install helm --classic
  helm 3.7.0 from Snapcrafters installed
  ```

  <br>

### **2.2. kube-monkey 배포** <a name="list2_2"></a>

  kube-monkey를 배포할 네임스페이스를 만들어서 해당 네임스페이스에 helm을 사용하여 kube-monkey를 배포해볼 것이다. helm 배포에 필요한 차트와 설정 파일들은 helm/kubemonkey 디렉토리에 들어있다.

  ```bash
  son@son-localhost ~/kube-monkey $ k create ns kube-monkey
  namespace/kube-monkey created
  son@son-localhost ~/kube-monkey $ helm upgrade --install kube-monkey ./helm/kubemonkey \
    -n kube-monkey \
    --set config.debug.enabled=true \
    --set config.debug.schedule_immediate_kill=true \
    --set config.dryRun=false \
    --set config.whitelistedNamespaces="{default}"
  Release "kube-monkey" does not exist. Installing it now.
  NAME: kube-monkey
  LAST DEPLOYED: Sun Oct 30 15:03:12 2022
  NAMESPACE: kube-monkey
  STATUS: deployed
  REVISION: 1
  TEST SUITE: None
  NOTES:
  1. Wait until the application is rolled out:
    kubectl -n kube-monkey rollout status deployment kube-monkey
  2. Check the logs:
    kubectl logs -f deployment.apps/kube-monkey -n kube-monkey

  son@son-localhost ~/kube-monkey $ k get all -n kube-monkey
  NAME                              READY   STATUS    RESTARTS   AGE
  pod/kube-monkey-9dc7d68df-rxkr2   1/1     Running   0          17s

  NAME                          READY   UP-TO-DATE   AVAILABLE   AGE
  deployment.apps/kube-monkey   1/1     1            1           17s

  NAME                                    DESIRED   CURRENT   READY   AGE
  replicaset.apps/kube-monkey-9dc7d68df   1         1         1       17s
  ```

  helm 배포할 때 옵션 중 `schedule_immediate_kill=true`는 30초마다 새로운 스케줄을 예약하여 테스트할 수 있는 디버그 옵션이다. `dryRun=false` 옵션은 실제로 대상 Pod를 죽이는 것을 의미하고, `whitelistedNamespaces="{default}"` 옵션은 테스트를 허용할 네임스페이스 리스트를 작성하면 된다. 여기서는 default 네임스페이스에서 앱을 배포하여 테스트해볼 예정이다.

  schedule_immediate_kill 옵션을 true로 설정 했기 때문에 kube-monkey가 배포된 즉시 Pod 종료하기 시작한다. kube-monkey 로그를 확인하여 정상적으로 작동하는지 확인할 수 있다.

  ```bash
  son@son-localhost ~/kube-monkey $ k get all
  NAME                 TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)        AGE
  service/kubernetes   ClusterIP   10.96.0.1       <none>        443/TCP        23d

  son@son-localhost ~/kube-monkey $ kubectl logs -n kube-monkey -l release=kube-monkey -f
  I1106 06:03:46.953170       1 kubemonkey.go:21] Status Update: Generating next schedule in 30 sec
  I1106 06:04:16.954629       1 schedule.go:73] Status Update: Generating schedule for terminations
  I1106 06:04:16.990255       1 schedule.go:66] Status Update: 0 terminations scheduled today
  I1106 06:04:16.990304       1 kubemonkey.go:76] Status Update: Waiting to run scheduled terminations.
  I1106 06:04:16.990308       1 kubemonkey.go:94] Status Update: All terminations done.
  I1106 06:04:16.990404       1 kubemonkey.go:20] Debug mode detected!
  I1106 06:04:16.990414       1 kubemonkey.go:21] Status Update: Generating next schedule in 30 sec
          ********** Today's schedule **********
          No terminations scheduled
          ********** End of schedule **********
  ```

  지금은 default 네임스페이스에 Deployment나 Pod가 배포되어 있지 않은 상태이기 때문에 kube-monkey 로그를 확인해봤을 때 종료할 Pod가 없어 스케쥴이 따로 잡히지 않는 것을 확인할 수 있다. default 네임스페이스에 배포되어 있는 Pod는 없지만, 위의 옵션처럼 30초마다 Pod를 죽이기 위한 스케쥴이 지속적으로 예약되고 있는 상황인 것이다.

  <br>

  샘플 애플리케이션은 [이전 포스팅](http://crisis513.github.io/infra/2022/10/24/canary.html)의 Canary 배포에 사용한 애플리케이션을 사용할 것이다. 앱은 아무거나 사용해도 되지만 매니페스트에서 추가해야 할 부분이 있다. 

  ```bash
  son@son-localhost ~/kube-monkey $ cd ~/k8s-deployment-strategies/canary/native
  son@son-localhost ~/kube-monkey $ cat app-v1.yaml
  apiVersion: v1
  kind: Service
  metadata:
    name: my-app
    labels:
      app: my-app
  spec:
    type: NodePort
    ports:
    - name: http
      port: 80
      targetPort: http
    selector:
      app: my-app
  ---
  apiVersion: apps/v1
  kind: Deployment
  metadata:
    name: my-app-v1
    labels:
      app: my-app
      kube-monkey/enabled: enabled
      kube-monkey/identifier: monkey-victim
      kube-monkey/mtbf: '2'
      kube-monkey/kill-mode: "fixed"
      kube-monkey/kill-value: '1'
  spec:
    replicas: 10
    selector:
      matchLabels:
        app: my-app
        version: v1.0.0
    template:
      metadata:
        labels:
          app: my-app
          version: v1.0.0
          kube-monkey/enabled: enabled
          kube-monkey/identifier: monkey-victim
        annotations:
          prometheus.io/scrape: "true"
          prometheus.io/port: "9101"
      spec:
        containers:
        - name: my-app
          image: crisis513/strategies-test
          ports:
          - name: http
            containerPort: 8080
          - name: probe
            containerPort: 8086
          env:
          - name: VERSION
            value: v1.0.0
          livenessProbe:
            httpGet:
              path: /live
              port: probe
            initialDelaySeconds: 5
            periodSeconds: 5
          readinessProbe:
            httpGet:
              path: /ready
              port: probe
            periodSeconds: 5

  son@son-localhost ~/k8s-deployment-strategies/canary/native $ k apply -f app-v1.yaml
  service/my-app created
  deployment.apps/my-app-v1 created
  ```

  위 내용과 같이 metadata.labels 섹션에 kube-monkey 관련 옵션 5줄과 spec.template.metadata.labels 섹션에 kube-monkey 관련 옵션 2줄이 추가된 것을 확인할 수 있다. `kube-monkey/enabled: enabled` 옵션으로 kube-monkey에 해당 Pod가 종료 일정의 대상으로 간주하도록 설정하고, `kube-monkey/identifier: monkey-victim` 옵션은 어떤 Pod가 어떤 배포에 속하는지 확인하기 위한 고유 식별자 레이블이다. 다음으로 `kube-monkey/mtbf: '2'` 옵션에서 mtbf는 **Mean Time Between Failure**를 나타내며 Kubernetes 배포에서 Pod 중 하나가 종료될 것으로 예상할 수 있는 평균 일수를 의미한다. 그리고 `kube-monkey/kill-mode: "fixed"` 옵션은 고정된 수의 Pod를 죽이는 옵션이며, `kube-monkey/kill-value: '1'` 옵션은 죽일 Pod의 수를 결정한다.

  필요에 따라 kube-monkey 옵션을 설정하여 default 네임스페이스에 앱을 배포하고나서 다시 kube-monkey 로그를 살펴보면 배포된 Pod들 중 하나가 스케줄에 잡혀있는 것을 확인할 수 있다.

  ```bash
  son@son-localhost ~/k8s-deployment-strategies/canary/native $ k logs -n kube-monkey -l release=kube-monkey -f
  I1106 06:05:53.657472       1 schedule.go:66] Status Update: 0 terminations scheduled today
  I1106 06:05:53.657495       1 kubemonkey.go:76] Status Update: Waiting to run scheduled terminations.
  I1106 06:05:53.657498       1 kubemonkey.go:94] Status Update: All terminations done.
  I1106 06:05:53.657518       1 kubemonkey.go:20] Debug mode detected!
  I1106 06:05:53.657521       1 kubemonkey.go:21] Status Update: Generating next schedule in 30 sec
  I1106 06:06:23.660792       1 schedule.go:73] Status Update: Generating schedule for terminations
          ********** Today's schedule **********
          No terminations scheduled
          ********** End of schedule **********
  I1106 06:06:23.783121       1 schedule.go:66] Status Update: 0 terminations scheduled today
  I1106 06:06:23.783144       1 kubemonkey.go:76] Status Update: Waiting to run scheduled terminations.
  I1106 06:06:23.783148       1 kubemonkey.go:94] Status Update: All terminations done.
  I1106 06:06:23.783209       1 kubemonkey.go:20] Debug mode detected!
  I1106 06:06:23.783213       1 kubemonkey.go:21] Status Update: Generating next schedule in 30 sec
  I1106 06:06:53.787910       1 schedule.go:73] Status Update: Generating schedule for terminations
  I1106 06:06:53.951894       1 schedule.go:66] Status Update: 1 terminations scheduled today
  I1106 06:06:53.951927       1 schedule.go:68] v1.Deployment my-app-v1 scheduled for termination at 10/30/2022 01:07:29 -0500 EST
  I1106 06:06:53.951953       1 kubemonkey.go:76] Status Update: Waiting to run scheduled terminations.
          ********** Today's schedule **********
          k8 Api Kind     Kind Namespace  Kind Name               Termination Time
          -----------     --------------  ---------               ----------------
          v1.Deployment   default my-app-v1               10/30/2022 01:07:29 -0500 EST
          ********** End of schedule **********
  I1106 06:07:30.044403       1 kubemonkey.go:84] Termination successfully executed for v1.Deployment my-app-v1
  I1106 06:07:30.044441       1 kubemonkey.go:91] Status Update: 0 scheduled terminations left.
  I1106 06:07:30.044445       1 kubemonkey.go:94] Status Update: All terminations done.
  I1106 06:07:30.045412       1 kubemonkey.go:20] Debug mode detected!
  I1106 06:07:30.045446       1 kubemonkey.go:21] Status Update: Generating next schedule in 30 sec
  ```

  <br>

  다음 영상은 위에서 설명한 내용을 실습하는 과정을 촬영한 것이고, 1.5배로 재생되도록 편집하였다. 30초마다 Pod가 삭제되는 스케쥴이 잡히고 실제로 Pod가 삭제되고 다시 생성되는 것을 확인할 수 있다.

  <video width="100%" preload="auto" muted controls>
      <source src="/static/assets/video/blog/kube-monkey.mp4" type="video/mp4" />
  </video>

  <br>

  마지막으로 kube-monkey를 삭제하지 않으면 계속해서 Pod 삭제 스케쥴이 잡히기 때문에 테스트를 다 했다면 삭제해주도록 하자.

  ```bash
  son@son-localhost ~/kube-monkey $ helm uninstall kube-monkey
  ```

  <br>

  kube-monkey는 Pod를 죽이는 기능밖에 없기 때문에 카오스 엔지니어링을 하기에는 기능이 많이 부족하다. 다음 포스팅에서는 Pod Fault 뿐만 아니라 Stress test, IO Injection, Network Attack, HTTP Fault 등 다양한 카오스 엔지니어링을 실습할 수 있는 chaos-mesh를 실습해보는 시간을 가져볼 것이다.