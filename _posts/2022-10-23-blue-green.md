---
layout: post
title: "[Infra] Kubernetes Blue/Green 배포 전략 실습"
date: 2022-10-23
desc: "[Infra] Kubernetes Blue/Green 배포 전략 실습"
keywords: "son,blog,infra,docker,minikube,kubernetes,grafana,blue/green"
categories: [Infra]
tags: [son,blog,infra,docker,minikube,kubernetes,grafana,blue/green]
icon: icon-html
---

본 포스팅에서는 Kubernetes의 여러 배포 전략 중 Blue/Green에 대해 알아보고 실습해볼 것이다. 실습 진행은 [해당 깃허브 내용]("https://github.com/ContainerSolutions/k8s-deployment-strategies")을 참고하였다.

---

## 목차

[1. Blue/Green 배포](#list1)

[&nbsp;&nbsp; 1.1. Blue/Green이란?](#list1_1)

[&nbsp;&nbsp; 1.2. Blue/Green 실습](#list1_2)

[&nbsp;&nbsp; 1.3. Grafana dashboard 확인](#list1_3)

---

## <span style="color:purple">**1. Blue/Green 배포**</span> <a name="list1"></a>

<br>

### 1.1. Blue/Green이란? <a name="list1_1"></a>

  이전 포스팅에서 살펴본 Rolling Update는 기존 버전과 새로운 버전이 같이 배포되는 시간이 어느정도 있다는 문제가 있다. 이러한 문제를 해결하기 위해 사용되는 방법이 Blue/Green 배포이다. Blue/Green 배포는 서버를 기존 버전과 새로운 버전을 동시에 배포하여 한꺼번에 교체하는 방법이다. 그림으로 살펴보자면 다음 [그림 1]과 같다.

  | ![blue_green](/static/assets/img/landing/infra/bluegreen1.png){: width="100%"} |
  |:--:| 
  | [그림 1] Blue/Green 배포 과정 |

  <br>

  새로운 버전이 요구 사항을 충족하는지 테스트한 후 selector 필드의 version 레이블을 교체하여 새로운 버전으로 트래픽을 보내도록 업데이트하는 방식이다. 즉각적인 롤아웃/롤백이 가능하고 버전 관리 문제를 피하고 전체 클러스터 상태를 한 번에 변경할 수 있는 장점이 있지만, 두 버전이 동시에 올라가야 하기 때문에 두 배의 자원이 필요하고, 프로덕션에 출시하기 전에 전체 플랫폼에 대한 적절한 테스트를 수행하는 과정이 필요하다.

  <br>

### 1.2. Blue/Green 실습 <a name="list1_2"></a>

  실습은 이전 포스팅의 Rolling Update를 진행했던 ramped 폴더에서 blue-green/single-service 폴더로 이동하여 진행한다.

  ```bash
  son@son-localhost ~/k8s-deployment-strategies/ramped $ cd ../blue-green/single-service
  son@son-localhost ~/k8s-deployment-strategies/blue-green/single-service $ ls
  app-v1.yaml  app-v2.yaml  README.md
  son@son-localhost ~/k8s-deployment-strategies/blue-green/single-service $ cat app-v1.yaml
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
      version: v1.0.0
  ---
  apiVersion: apps/v1
  kind: Deployment
  metadata:
    name: my-app-v1
    labels:
      app: my-app
  spec:
    replicas: 3
    selector:
      matchLabels:
        app: my-app
        version: v1.0.0
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
  son@son-localhost ~/k8s-deployment-strategies/blue-green/single-service $ cat app-v2.yaml
  apiVersion: apps/v1
  kind: Deployment
  metadata:
    name: my-app-v2
    labels:
      app: my-app
  spec:
    replicas: 3
    selector:
      matchLabels:
        app: my-app
        version: v2.0.0
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
            periodSeconds: 5
  ```

  Blue/Green도 컨테이너 이미지 부분을 이전에 미리 컨테이너 이미지를 빌드 및 Docker Hub에 푸시했던 **crisis513/strategies-test**로 바꾸었다. 매니페스트가 Rolling Update와 다른 점은 strategy 부분이 없고, selector > matchLabels > version이 추가된 점이다. 사실 `kubectl patch service` 명령어로 어떤 selector의 요소를 바라보게 할 것인지를 바꿔주면 되는 것이고, 본 포스팅에서는 selector > matchLabels > version 부분으로 컨트롤 하는 것 뿐이다.

  먼저 app-v1.yaml을 배포해보자.

  ```bash
  son@son-localhost ~/k8s-deployment-strategies/blue-green/single-service $ k apply -f app-v1.yaml
  service/my-app created
  deployment.apps/my-app-v1 created
  son@son-localhost ~/k8s-deployment-strategies/blue-green/single-service $ k get all
  NAME                             READY   STATUS    RESTARTS   AGE
  pod/my-app-v1-69b978c757-9wtgt   1/1     Running   0          69s
  pod/my-app-v1-69b978c757-g2bfr   1/1     Running   0          69s
  pod/my-app-v1-69b978c757-kcwn7   1/1     Running   0          69s

  NAME                 TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)        AGE
  service/kubernetes   ClusterIP   10.96.0.1       <none>        443/TCP        15d
  service/my-app       NodePort    10.104.28.204   <none>        80:32448/TCP   69s

  NAME                        READY   UP-TO-DATE   AVAILABLE   AGE
  deployment.apps/my-app-v1   3/3     3            3           69s

  NAME                                   DESIRED   CURRENT   READY   AGE
  replicaset.apps/my-app-v1-69b978c757   3         3         3       69s
  ```

  서비스가 정상적으로 올라갔다면 Rolling Update 때와 마찬가지로 해당 애플리케이션으로 지속적인 요청을 보내보도록 하겠다.

  ```bash
  son@son-localhost ~/k8s-deployment-strategies/blue-green/single-service $ while true; do curl -s -o /dev/null "http://192.168.49.2:32448"; done
  ```

  요청은 계속 보내도록 그대로 두고 어느 정도 시간이 지나고나서 새로운 터미널을 열어 app-v2.yaml을 배포하겠다. 
  
  새로운 터미널을 열어 다음 명령어를 통해 pod가 롤아웃 되는 과정을 확인할 수 있다. 

  $ watch kubectl get po 

  ```bash
  son@son-localhost ~/k8s-deployment-strategies/blue-green/single-service $ k apply -f app-v2.yaml
  deployment.apps/my-app-v2 created
  ```

  다음 그림은 app-v1.yaml과 app-v2.yaml을 함께 배포한 것을 확인해본 것으로, 함께 배포되어 있는 것을 확인할 수 있다.

  | ![watch_pod](/static/assets/img/landing/infra/bluegreen2.png){: width="70%"} |
  |:--:| 
  | [그림 2] watch kubectl get po 확인 |

  <br>

  여기서 kubectl patch service 명령으로 어느 버전의 애플리케이션을 가리키느냐에 따라 트래픽의 이동 방향이 정해지는 것이고, 새로운 버전의 애플리케이션을 가리킨 후에 이전 버전의 애플리케이션을 삭제해주면 Blue/Green 배포가 완료되는 것이다. 

  ```bash
  son@son-localhost ~/k8s-deployment-strategies/blue-green/single-service $ k patch service my-app -p '{"spec":{"selector":{"version":"v2.0.0"}}}'
  service/my-app patched
  son@son-localhost ~/k8s-deployment-strategies/blue-green/single-service $ k delete deploy my-app-v1
  deployment.apps "my-app-v1" deleted

  son@son-localhost ~/k8s-deployment-strategies/blue-green/single-service $ k get pod
  NAME                             READY   STATUS    RESTARTS   AGE
  pod/my-app-v2-69b978c757-jf9dn   1/1     Running   0          10m
  pod/my-app-v2-69b978c757-2mdfj   1/1     Running   0          10m
  pod/my-app-v2-69b978c757-ms9dn   1/1     Running   0          10m

  son@son-localhost ~/k8s-deployment-strategies/blue-green/single-service $ k describe service/my-app
  Name:                     my-app
  Namespace:                default
  Labels:                   app=my-app
  Annotations:              <none>
  Selector:                 app=my-app,version=v2.0.0
  Type:                     NodePort
  IP Family Policy:         SingleStack
  IP Families:              IPv4
  IP:                       10.109.224.206
  IPs:                      10.109.224.206
  Port:                     http  80/TCP
  TargetPort:               http/TCP
  NodePort:                 http  30427/TCP
  Endpoints:                172.17.0.10:8080,172.17.0.11:8080,172.17.0.7:8080
  Session Affinity:         None
  External Traffic Policy:  Cluster
  Events:                   <none>
  ```

  app-v2.yaml을 배포하고 kubectl patch service 명령어를 통해 새로 배포된 애플리케이션으로 트래픽을 보내도록 설정한 후에 기존 버전의 애플리케이션을 삭제해 주었다. v2에 해당하는 pod들이 Running되고 있는 것을 확인할 수 있고, 서비스 정보를 살펴보니 Selector의 version도 2.0.0으로 바뀐 것을 확인할 수 있다.

  > 반대로 롤백하고 싶다면 다음 명령어를 사용하면 된다.
  >
  > $ kubectl patch service my-app -p '{"spec":{"selector":{"version":"v1.0.0"}}}'

  <br>

### 1.3. Grafana dashboard 확인 <a name="list1_3"></a>

  새로운 버전으로의 배포가 정상적으로 완료되었다면 Grafana를 통해 Blue/Green 배포 과정에 대한 지속적인 요청 메트릭을 확인하겠다. 마찬가지로 이전 포스팅에서 배포해 두었던 Grafana에 접속하기 위해 localhost:3000으로 접근하여 만들어 둔 패널을 **refresh**해보자. 다음 [그림 3]과 같은 화면을 볼 수 있을 것이다. 

  | ![request_total_panel](/static/assets/img/landing/infra/bluegreen3.png){: width="100%"} |
  |:--:| 
  | [그림 3] Request Total 패널 확인 |

  <br>

  시각화된 데이터를 보면 기존 버전에서 새로운 버전으로 한 번에 교체하기 때문에 점진적으로 롤아웃하던 Rolling Update 때와는 다르게 단번에 롤아웃 되는 것을 확인할 수 있다. 
