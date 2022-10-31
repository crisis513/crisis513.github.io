---
layout: post
title: "[Infra] Kubernetes Rolling Update 배포 전략 실습"
date: 2022-10-22
desc: "[Infra] Kubernetes Rolling Update 배포 전략 실습"
keywords: "son,blog,infra,docker,minikube,kubernetes,grafana,rolling update"
categories: [Infra]
tags: [son,blog,infra,docker,minikube,kubernetes,grafana,rolling update]
icon: icon-html
---

본 포스팅에서는 Kubernetes의 여러 배포 전략 중 Rolloing Update에 대해 알아보고 실습해볼 것이다. 실습 진행은 [해당 깃허브 내용]("https://github.com/ContainerSolutions/k8s-deployment-strategies")을 참고하였다.

---

## 목차

[1. 무중단 배포 전략](#list1)

[2. Rolling Update 배포](#list2)

[&nbsp;&nbsp; 2.1. Rolling Update란?](#list2_1)

[&nbsp;&nbsp; 2.2. Rolling Update 실습](list2_2)

[&nbsp;&nbsp; 2.3. Grafana dashboard 확인](#list2_3)

---

## <span style="color:purple">**1. 무중단 배포 전략**</span> <a name="list1"></a>

무중단 배포는 실제로 **서버를 운영할 때 서비스가 중단되지 않고, 서비스적인 장애를 최소화시킬 수 있도록 배포**하는 것을 의미한다. 얼마 전 2022년 10월 15일에 C&C 데이터센터에 화재가 발생하여 역대 최악의 서비스 중단 사태를 맞았었다. 10시간이 지나서야 일부 기능이 복구되기 시작되었고 공식적으로는 127시간 30분만에 모든 서비스가 정상화 되었다고 알려져있는데, 이번 사태로 유료서비스 사용자에 대한 보상액과 서비스 중단에 대한 매출액 피해 등을 합하면 수백 수천억의 손실을 입었을 것이다. 서비스의 규모가 클 수록 정상적으로 서비스를 운영할 수 있는 인프라 및 환경을 갖추는 것이 매우 중요하다. 데이터센터가 이원화가 재대로 되지 않아 발생한 문제여서 이번 포스팅에서 다룰 쿠버네티스 무중단 배포 전략과는 약간 다른 문제이긴 하지만 그만큼 서비스가 중단되지 않고 정상 서비스하는 것이 매우 중요하다는 것을 강조하고 싶었다. 

쿠버네티스 서비스 환경에서 새로운 버전으로 롤아웃 하면서 스테이지에서 없던 문제가 운영에서 생겨나면서 서비스가 중단되는 상황도 있기 때문에 일관된 환경을 제공하는 것도 중요한 이슈이다. 다시 돌아와서, 쿠버네티스에서 기본적으로 제공하는 Rolling Update와 Blue/Green, Canary 등 새로운 버전으로 롤아웃하기 위한 여러 가지 무중단 배포 전략이 존재한다. 본 포스팅에서는 대표적인 3가지 방법 중 Rolling Update에 대해 알아보고 실습해볼 것이다.

<br>

## <span style="color:purple">**2. Rolling Update 배포**</span> <a name="list2"></a>

<br>

### 2.1. Rolling Update란? <a name="list2_1"></a>

  Rolling Update란 새로운 버전을 배포하면서 새로운 버전의 인스턴스를 하나씩 올리고 기존 버전의 인스턴스를 하나씩 줄여나가는 방식이다. 이런 방식으로 배포하면 서비스가 중단되지 않으며 배포할 수 있다는 장점이 있지만, 새로운 버전의 인스턴스로 트래픽이 이전되기 전까지 이전 버전과 새로운 버전의 인스턴스가 동시에 존재할 수 있다는 단점이 있다. 배포하는 기간 동안 어떤 사용자는 이전 버전을 사용하게 되고, 또다른 사용자는 새로운 버전을 사용할 수도 있다는 것이다. 그림으로 표현하자면 다음 [그림 1]과 같다.

  | ![rolling_update](/static/assets/img/landing/infra/rollingupdate1.png){: width="100%"} |
  |:--:| 
  | [그림 1] Rolling Update 배포 과정 |

  <br>

  그림의 예시에서는 Deployment가 replicas를 3으로 설정하여 3개의 pod가 배포되었다고 가정한다. 우측의 Running, Terminating, Container Creating는 Pod의 Status를 어떠한 과정으로 변화하는지를 의미하며, X는 pod가 존재하지 않는다는 의미이다. 설명을 보태자면, **기존 버전의 pod 집합에서 pod를 하나씩 제거하고 새로운 버전의 pod를 하나씩 추가하는 과정이 반복**되는 것이다. 위에서도 언급하였듯 Deployment의 배포 전략에 아무런 설정하지 않으면 기본적으로 Rolling Update로 설정된다.

  <br>

### 2.2. Rolling Update 실습 <a name="list2_2"></a>

  먼저 Rolling Update 실습에 필요한 자료를 다운받아 오겠다.

  ```bash
  son@son-localhost ~ $ git clone https://github.com/ContainerSolutions/k8s-deployment-strategies.git
  Cloning into 'k8s-deployment-strategies'...
  remote: Enumerating objects: 452, done.
  remote: Counting objects: 100% (20/20), done.
  remote: Compressing objects: 100% (20/20), done.
  remote: Total 452 (delta 1), reused 8 (delta 0), pack-reused 432
  Receiving objects: 100% (452/452), 3.70 MiB | 923.00 KiB/s, done.
  Resolving deltas: 100% (236/236), done.

  son@son-localhost ~ $ cd k8s-deployment-strategies/
  son@son-localhost ~/k8s-deployment-strategies $ ls
  ab-testing  app  blue-green  canary  decision-diagram.png  grafana-dashboard.json  ramped  README.md  recreate  shadow
  son@son-localhost ~/k8s-deployment-strategies $ cd app/
  son@son-localhost ~/k8s-deployment-strategies/app $ ls
  Dockerfile  Gopkg.lock  Gopkg.toml  main.go  Makefile  README.md
  ```

  해당 깃 폴더를 살펴보면 recreate, ramped, blue/green, canary, a/b testing 배포 전략을 실습해볼 수 있도록 폴더가 나뉘어져있고, app에는 배포 테스트를 진행하면서 애플리케이션 버전을 확인해볼 수 있도록 GO 언어로 간단하게 구현되어 있다. 그리고 Dockerfile을 통해 컨테이너 이미지로 만들 수 있기 때문에 빌드하여 Docker Hub에서 새로운 레포지토리를 만든 후에 해당 레포지토리로 푸시해볼 것이다. Docker Hub에서 리포지토리명은 다음 [그림 2]와 같이 `strategies-test`로 만들었다.

  | ![](/static/assets/img/landing/infra/rollingupdate2.png){: width="60%"} |
  |:--:| 
  | [그림 2] Grafana 접속 화면 |

  <br>

  ```bash
  son@son-localhost ~/k8s-deployment-strategies/app $ docker build -t crisis513/strategies-test .
  Sending build context to Docker daemon  15.36kB
  Step 1/9 : FROM golang:1.9-alpine AS build
  ---> b0260be938c6
  Step 2/9 : RUN apk --no-cache add git &&   go get -u github.com/golang/dep/cmd/dep
  ---> Running in fbf1fd7871e4
  fetch http://dl-cdn.alpinelinux.org/alpine/v3.8/main/x86_64/APKINDEX.tar.gz
  fetch http://dl-cdn.alpinelinux.org/alpine/v3.8/community/x86_64/APKINDEX.tar.gz
  (1/6) Installing nghttp2-libs (1.39.2-r0)
  (2/6) Installing libssh2 (1.9.0-r1)
  (3/6) Installing libcurl (7.61.1-r3)
  (4/6) Installing expat (2.2.8-r0)
  (5/6) Installing pcre2 (10.31-r0)
  (6/6) Installing git (2.18.4-r0)
  Executing busybox-1.28.4-r0.trigger
  OK: 19 MiB in 20 packages
  Removing intermediate container fbf1fd7871e4
  ---> af88bec1e59a
  Step 3/9 : COPY . $GOPATH/src/app
  ---> ea2deb243f50
  Step 4/9 : WORKDIR $GOPATH/src/app
  ---> Running in 3e98a321c375
  Removing intermediate container 3e98a321c375
  ---> 32abad570106
  Step 5/9 : RUN dep ensure &&   CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o app .
  ---> Running in bd96701a0b9c
  Removing intermediate container bd96701a0b9c
  ---> e6584e1d6bd4
  Step 6/9 : FROM scratch
  --->
  Step 7/9 : COPY --from=build /go/src/app/app /app
  ---> Using cache
  ---> a12284a9dd08
  Step 8/9 : EXPOSE 8080 8086 9101
  ---> Using cache
  ---> 5a912ba846b7
  Step 9/9 : CMD ["/app"]
  ---> Using cache
  ---> 9bdd1b95aae3
  Successfully built 9bdd1b95aae3
  Successfully tagged crisis513/strategies-test:latest

  son@son-localhost ~/k8s-deployment-strategies/app $ docker login
  Authenticating with existing credentials...
  WARNING! Your password will be stored unencrypted in /home/son/.docker/config.json.
  Configure a credential helper to remove this warning. See
  https://docs.docker.com/engine/reference/commandline/login/#credentials-store

  Login Succeeded

  son@son-localhost ~/k8s-deployment-strategies/app $ docker push crisis513/strategies-test
  Using default tag: latest
  The push refers to repository [docker.io/crisis513/strategies-test]
  a6412e70ba42: Pushed
  latest: digest: sha256:9f281584fa169d7a045d0fa17f3125871783b0dc5340eb0abe22ebc8f54c1c85 size: 528
  ```

  푸시가 정상적으로 되었다면 예제 애플리케이션 코드와 컨테이너 이미지로 만들 Dockerfile, 컨테이너 이미지를 저장할 Docker Hub 레포지토리까지 생기게 되고, 코드를 수정하여 새롭게 배포할 수 있는 모든 환경이 만들어 진 것이다. 

  <br>

  다음으로 Prometheus와 Grafana를 배포해야 하는데, 이전 포스팅에서 Istio를 설치하여 addons를 배포하는 과정에서 Prometheus와 Grafana가 이미 Running 상태이다. 따라서 필자는 Grafana에 접속할 수 있도록 포트포워딩만 해줄 것이다.

  > 혹시나 블로그 내용을 따라오고 있지 않아 Istio가 구성되어 있지 않다면 [해당 readme]("https://github.com/ContainerSolutions/k8s-deployment-strategies#readme")를 참고하여 Prometheus와 Grafana 환경을 구성하면 될 것 같다.
  >
  > 그리고 Grafana에 접속할 때마다 포트포워딩을 해주기 귀찮다면 NodePort를 올려도 상관 없다.

  ```bash
  son@son-localhost ~/k8s-deployment-strategies/app $ k get all -n istio-system
  NAME                                        READY   STATUS    RESTARTS   AGE
  pod/grafana-56bdf8bf85-ff924                1/1     Running   0          3d
  pod/istio-egressgateway-fffc799cf-fw5cv     1/1     Running   0          3d
  pod/istio-ingressgateway-7d68764b55-8sq9l   1/1     Running   0          3d
  pod/istiod-5456fd558d-dpkvc                 1/1     Running   0          3d
  pod/jaeger-c4fdf6674-56w7h                  1/1     Running   0          3d
  pod/kiali-5ff49b9f69-c9fxt                  1/1     Running   0          3d
  pod/prometheus-85949fddb-csxkd              2/2     Running   0          3d

  NAME                           TYPE           CLUSTER-IP       EXTERNAL-IP      PORT(S)                                                                      AGE
  service/grafana                ClusterIP      10.96.226.7      <none>           3000/TCP                                                                     3d
  service/istio-egressgateway    ClusterIP      10.110.60.52     <none>           80/TCP,443/TCP                                                               3d
  service/istio-ingressgateway   LoadBalancer   10.111.160.6     192.168.49.100   15021:32528/TCP,80:30521/TCP,443:32312/TCP,31400:32156/TCP,15443:31761/TCP   3d
  service/istiod                 ClusterIP      10.102.30.48     <none>           15010/TCP,15012/TCP,443/TCP,15014/TCP                                        3d
  service/jaeger-collector       ClusterIP      10.102.207.195   <none>           14268/TCP,14250/TCP,9411/TCP                                                 3d
  service/kiali                  ClusterIP      10.109.43.201    <none>           20001/TCP,9090/TCP                                                           3d
  service/prometheus             ClusterIP      10.96.52.254     <none>           9090/TCP                                                                     3d
  service/tracing                ClusterIP      10.105.237.18    <none>           80/TCP,16685/TCP                                                             3d
  service/zipkin                 ClusterIP      10.96.209.177    <none>           9411/TCP                                                                     3d

  NAME                                   READY   UP-TO-DATE   AVAILABLE   AGE
  deployment.apps/grafana                1/1     1            1           3d
  deployment.apps/istio-egressgateway    1/1     1            1           3d
  deployment.apps/istio-ingressgateway   1/1     1            1           3d
  deployment.apps/istiod                 1/1     1            1           3d
  deployment.apps/jaeger                 1/1     1            1           3d
  deployment.apps/kiali                  1/1     1            1           3d
  deployment.apps/prometheus             1/1     1            1           3d

  NAME                                              DESIRED   CURRENT   READY   AGE
  replicaset.apps/grafana-56bdf8bf85                1         1         1       3d
  replicaset.apps/istio-egressgateway-fffc799cf     1         1         1       3d
  replicaset.apps/istio-ingressgateway-7d68764b55   1         1         1       3d
  replicaset.apps/istiod-5456fd558d                 1         1         1       3d
  replicaset.apps/jaeger-c4fdf6674                  1         1         1       3d
  replicaset.apps/kiali-5ff49b9f69                  1         1         1       3d
  replicaset.apps/prometheus-85949fddb              1         1         1       3d

  son@son-localhost ~ $ kubectl -n istio-system port-forward $(kubectl -n istio-system get pod -l app=grafana -o jsonpath='{.items[0].metadata.name}') 3000:3000 &
  [1] 15635
  Forwarding from 127.0.0.1:3000 -> 3000
  Forwarding from [::1]:3000 -> 3000
  ```

  app 폴더의 main.go 코드를 살펴보면 HTTP Request가 올 때마다 /metrics 경로와 9101포트를 통해 Prometheus 서버에서 매트릭을 수집하도록 작성되어 있는 것을 확인할 수 있다. 혹시나 매트릭이 정상적으로 수집되지 않아 Grafana에서 재대로 보이지 않는다면 Prometheus가 정상적으로 배포되어 있는지, health check 했을 때 서비스가 잘 동작하고 있는지, 포트 번호가 다르진 않는지, 로그에서 에러가 확인되는지 등을 확인해보면 될 것 같다.

  > k는 별칭을 설정하여 kubectl을 의미한다.
  >
  > $ alias k="kubectl"

  Grafana 포트포워딩을 하고 **localhost:3000**으로 접속했을 때 정상적으로 접속되면 다음 [그림 2]와 같은 화면을 볼 수 있다.

  | ![grafana_home](/static/assets/img/landing/infra/rollingupdate3.png){: width="80%"} |
  |:--:| 
  | [그림 3] Grafana 접속 화면 |

  <br>

  Grafana에 정상적으로 접근이 된다면 준비가 다 되었다. 다음으로 Rolling Update 실습을 진행해보자. Rolling Update 실습에 사용되는 매니페스트는 ramped 폴더에 있다. ramped 폴더 안에 있는 app-v1.yaml 파일과 app-v2.yaml의 내용을 비교해보겠다. 

  ```bash
  son@son-localhost ~/k8s-deployment-strategies/app $ cd ../ramped/
  son@son-localhost ~/k8s-deployment-strategies/ramped $ cat app-v1.yaml
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
    name: my-app
    labels:
      app: my-app
  spec:
    replicas: 10
    selector:
      matchLabels:
        app: my-app
    template:
      metadata:
        labels:
          app: my-app
          version: v1.0.0
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
  son@son-localhost ~/k8s-deployment-strategies/ramped $ cat app-v2.yaml
  apiVersion: apps/v1
  kind: Deployment
  metadata:
    name: my-app
    labels:
      app: my-app
  spec:
    replicas: 10
    strategy:
      type: RollingUpdate
      rollingUpdate:
        maxSurge: 1
        maxUnavailable: 0
    selector:
      matchLabels:
        app: my-app
    template:
      metadata:
        labels:
          app: my-app
          version: v2.0.0
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
            value: v2.0.0
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
            initialDelaySeconds: 15
            periodSeconds: 5
  ```

  우선, 컨테이너 이미지 부분을 위에서 빌드 및 푸시해서 Docker Hub에 저장한 **crisis513/strategies-test**로 바꾸었다. app-v1.yaml 파일과 다르게 app-v2.yaml에서는 버전을 의미하는 부분들이 v1.0.0에서 v2.0.0으로 버전업 되었고, spec > strategy 부분이 추가된 것을 확인할 수 있다. type을 RollingUpdate로 설정하고 maxSurge, maxUnavailable 두 파라미터를 설정해야 한다. **maxSurge는 의도한 pod 수에 대해 생성할 수 있는 최대 pod 수를 지정할 수 있고, maxUnavailable는 Rolling Update 중에 사용할 수 없는 최대 파드의 수를 지정할 수 있다.** [그림 1]에서는 pod 집합을 하나씩 제거한다고 설명했지만 실제로는 maxUnavailable에서 설정된 값만큼 기존 버전의 pod들을 제거하고 새로운 버전의 pod들을 생성하게 된다. maxSurge, maxUnavailable 두 파라미터의 값은 직접적인 **수치(ex: 1)**를 지정하거나 **비율(ex: 10%)**로도 지정이 가능하다.

  app-v1.yaml부터 배포하여 서비스와 디플로이먼트, 파드들이 정상적으로 동작하는지 확인해보자.

  ```bash
  son@son-localhost ~/k8s-deployment-strategies/ramped $ k apply -f app-v1.yaml
  service/my-app created
  deployment.apps/my-app created
  son@son-localhost ~/k8s-deployment-strategies/ramped $ k get all
  NAME                         READY   STATUS    RESTARTS   AGE
  pod/my-app-9b99b584b-7m8mw   1/1     Running   0          46s
  pod/my-app-9b99b584b-b9q6d   1/1     Running   0          46s
  pod/my-app-9b99b584b-gjd2p   1/1     Running   0          46s
  pod/my-app-9b99b584b-hzqcf   1/1     Running   0          46s
  pod/my-app-9b99b584b-jbjq8   1/1     Running   0          46s
  pod/my-app-9b99b584b-pldbh   1/1     Running   0          46s
  pod/my-app-9b99b584b-s8ts9   1/1     Running   0          46s
  pod/my-app-9b99b584b-sdn9q   1/1     Running   0          46s
  pod/my-app-9b99b584b-smg9k   1/1     Running   0          46s
  pod/my-app-9b99b584b-zkf7s   1/1     Running   0          46s

  NAME                 TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)        AGE
  service/kubernetes   ClusterIP   10.96.0.1        <none>        443/TCP        15d
  service/my-app       NodePort    10.103.204.108   <none>        80:30738/TCP   46s

  NAME                     READY   UP-TO-DATE   AVAILABLE   AGE
  deployment.apps/my-app   10/10   10           10          46s

  NAME                               DESIRED   CURRENT   READY   AGE
  replicaset.apps/my-app-9b99b584b   10        10        10      46s

  son@son-localhost ~/k8s-deployment-strategies/ramped $ curl http://192.168.49.2:30738
  Host: my-app-744d48b664-d5qqn, Version: v1.0.0
  ```

  정상적으로 배포되어 curl 요청에 대해 1.0.0 버전을 사용하고 있다는 애플리케이션 응답을 확인할 수 있다. curl을 통해 request를 보낼 때 192.168.49.2는 필자가 구성한 Kubernetes 클러스터 노드의 IP이다. 이 주소는 환경에 따라 달라질 수 있으니 상황에 맞게 수정하면 된다. 30738 포트번호는 app-v1.yaml에서 NodePort를 생성하면서 임의로 설정된 포트번호이다. 서비스를 지웠다가 다시 생성하면 해당 포트번호는 달라질 것이니 참고 바란다.

  그리고 다음과 같이 **while 명령어를 통해 Ctrl + C를 누르기 전까지 계속해서 해당 서비스로 요청을 보낼 것**이다. 그래야 지속적인 요청에 대한 메트릭이 쌓이게 되고, v2.0.0으로 바뀌는 과정의 메트릭을 볼 수 있게 된다.

  ```bash
  son@son-localhost ~/k8s-deployment-strategies/ramped $ while true; do curl -s -o /dev/null "http://192.168.49.2:30738"; done
  ```

  필자는 약 6분정도 요청을 계속 보내도록 두었고, 그동안 Grafana에서 메트릭이 수집된 내용을 시각화하여 볼 수 있도록 대시보드를 추가하였다. k8s-deployment-strategies 폴더 내의 grafana-dashboard.json 파일에서 대시보드를 어떻게 만들었는지에 대한 설정 내용이 들어있어 쉽게 시각화 시킬 수 있다. **New Dashboard**를 통해 대시보드를 생성하고, 우측 상단의 톱니바퀴 모양의 아이콘을 눌러 설정 창에 들어가면 다음 [그림 4]와 같이 좌측의 **JSON Model** 탭을 눌러 대시보드 설정을 json 형태로 관리할 수 있는 창이 나오게 된다. 

  | ![dashboard_settings](/static/assets/img/landing/infra/rollingupdate4.png){: width="100%"} |
  |:--:| 
  | [그림 4] Grafana dashboard 설정 |

  <br>

  대시보드 명은 예시와 같이 **k8s-deployment-strategies dashboard**로 하였고, panel 부분만 grafana-dashboard.json 파일의 30~130라인에 해당하는 panel부분으로 대체하여 저장하였다.

  <br>

  다시 터미널로 돌아와 curl 요청 중인 터미널 말고 새로운 터미널을 열어 app-v2.yaml 파일을 배포하고나서 배포했던 app-v1.yaml을 제거해보자.

  ```bash
  son@son-localhost ~/k8s-deployment-strategies/ramped $ k apply -f app-v2.yaml
  deployment.apps/my-app configured

  son@son-localhost ~/k8s-deployment-strategies/ramped $ k delete -f app-v1.yaml
  service "my-app" deleted
  deployment.apps "my-app" deleted
  ```

  일정 시간이 지나면 기존에 배포했던 v1.0.0 애플리케이션이 모두 제거되고 v2.0.0에 해당하는 새로운 애플리케이션으로 버전업 되어 있을 것이다. 

  <br>
  
### 2.3. Grafana dashboard 확인 <a name="list2_3"></a>
  
  **현재 Rolling Update를 통해 새로운 버전으로 버전업시키는 과정을 curl을 통해 계속해서 요청을 보내는 메트릭을 수집하고 있는 상황**이고, 일정 시간이 지난 후에 위에서 만들어둔 Grafana 패널을 확인해보면 [그림 5]와 같이 보일 것이다.

  | ![request_total_panel1](/static/assets/img/landing/infra/rollingupdate5.png){: width="80%"} |
  |:--:| 
  | [그림 5] Request Total 패널 확인 |

  <br>

  pod 인스턴스를 차례로 교체하여 애플리케이션 버전을 천천히 롤아웃하는 과정을 수집된 메트릭을 통해 확인할 수 있다. 패널을 누르고 **e**키를 누르면 edit 화면으로 넘어갈 수 있는데 [그림 6]과 같이 **Full Opacity 옵션을 100**으로 설정하여 바 안쪽의 색을 채울 수 있고, **Stack series 옵션을 100%**로 설정하면 모든 series 합이 100%가 되도록 백분율로 표현할 수 있다.

  | ![request_total_panel2](/static/assets/img/landing/infra/rollingupdate6.png){: width="100%"} |
  |:--:| 
  | [그림 6] Request Total 패널 설정 |

  <br>

  시각화된 데이터를 보면 기존 버전이 사라지고 새로운 버전이 올라오는 과정이 점진적으로 롤아웃 되는 것을 확인할 수 있다. 