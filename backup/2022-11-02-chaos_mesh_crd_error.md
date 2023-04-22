---
layout: post
title: "[Troubleshooting] Install chaos-mesh CRD Error - metadata.annotations: Too long: must have at most 262144 bytes"
date: 2022-11-02
desc: "[Troubleshooting] Install chaos-mesh CRD Error - metadata.annotations: Too long: must have at most 262144 bytes"
keywords: "troubleshooting,minikube,kubernetes,chaos,chaos-mesh,crd,error"
categories: []
tags: [troubleshooting,minikube,kubernetes,chaos,chaos-mesh,crd,error]
icon: icon-html
---

본 포스팅에서는 Kubernetes 클러스터에 chaos-mesh를 배포할 때 발생하는 주석 길이로 인해 CRD(Custom Resource Definition, 사용자 지정 리소스 정의)를 적용할 수 없는 문제를 해결하는 과정을 설명한다.

---

## **문제** 

  다음 에러는 chaos-mesh CRD를 배포하면서 발생하는 에러이다.

  ```bash
  son@son-localhost ~/chaos-mesh $ k apply -f manifests/crd.yaml
  customresourcedefinition.apiextensions.k8s.io/awschaos.chaos-mesh.org created
  customresourcedefinition.apiextensions.k8s.io/azurechaos.chaos-mesh.org created
  customresourcedefinition.apiextensions.k8s.io/blockchaos.chaos-mesh.org created
  customresourcedefinition.apiextensions.k8s.io/dnschaos.chaos-mesh.org created
  customresourcedefinition.apiextensions.k8s.io/gcpchaos.chaos-mesh.org created
  customresourcedefinition.apiextensions.k8s.io/httpchaos.chaos-mesh.org created
  customresourcedefinition.apiextensions.k8s.io/iochaos.chaos-mesh.org created
  customresourcedefinition.apiextensions.k8s.io/jvmchaos.chaos-mesh.org created
  customresourcedefinition.apiextensions.k8s.io/kernelchaos.chaos-mesh.org created
  customresourcedefinition.apiextensions.k8s.io/networkchaos.chaos-mesh.org created
  customresourcedefinition.apiextensions.k8s.io/physicalmachinechaos.chaos-mesh.org created
  customresourcedefinition.apiextensions.k8s.io/physicalmachines.chaos-mesh.org created
  customresourcedefinition.apiextensions.k8s.io/podchaos.chaos-mesh.org created
  customresourcedefinition.apiextensions.k8s.io/podhttpchaos.chaos-mesh.org created
  customresourcedefinition.apiextensions.k8s.io/podiochaos.chaos-mesh.org created
  customresourcedefinition.apiextensions.k8s.io/podnetworkchaos.chaos-mesh.org created
  customresourcedefinition.apiextensions.k8s.io/remoteclusters.chaos-mesh.org created
  customresourcedefinition.apiextensions.k8s.io/statuschecks.chaos-mesh.org created
  customresourcedefinition.apiextensions.k8s.io/stresschaos.chaos-mesh.org created
  customresourcedefinition.apiextensions.k8s.io/timechaos.chaos-mesh.org created
  Error from server (Invalid): error when creating "manifests/crd.yaml": CustomResourceDefinition.apiextensions.k8s.io "schedules.chaos-mesh.org" is invalid: metadata.annotations: Too long: must have at most 262144 bytes
  Error from server (Invalid): error when creating "manifests/crd.yaml": CustomResourceDefinition.apiextensions.k8s.io "workflownodes.chaos-mesh.org" is invalid: metadata.annotations: Too long: must have at most 262144 bytes
  Error from server (Invalid): error when creating "manifests/crd.yaml": CustomResourceDefinition.apiextensions.k8s.io "workflows.chaos-mesh.org" is invalid: metadata.annotations: Too long: must have at most 262144 bytes
  ```

  Kubernetes 객체는 **annotations에 대해 256KB의 크기 제한**이 존재하는데, 맨 아래 3줄을 보면 annotations 길이로 인해 CRD를 적용할 수 없는 문제 때문에 배포할 수 없는 문제가 발생할 것을 확인할 수 있다. 

  에러를 보인 배포 환경은 다음과 같다.

  - Ubuntu 22.04 LTS
  - Minikube v1.27.1
  - Kubernetes v1.25.2

  <br>

## **해결** 

  해당 문제는 Kubernetes v1.18 버전부터 사용자와 컨트롤러가 리소스를 관리할 수 있게 해주는 Server Side Apply를 활용하여 해결할 수 있다. `kubectl apply`로 배포할 때 `--server-side=true` 옵션을 사용하면 된다.

  ```bash
  son@son-localhost ~/chaos-mesh $ k apply -f manifests/crd.yaml --server-side=true
  customresourcedefinition.apiextensions.k8s.io/awschaos.chaos-mesh.org serverside-applied
  customresourcedefinition.apiextensions.k8s.io/azurechaos.chaos-mesh.org serverside-applied
  customresourcedefinition.apiextensions.k8s.io/blockchaos.chaos-mesh.org serverside-applied
  customresourcedefinition.apiextensions.k8s.io/dnschaos.chaos-mesh.org serverside-applied
  customresourcedefinition.apiextensions.k8s.io/gcpchaos.chaos-mesh.org serverside-applied
  customresourcedefinition.apiextensions.k8s.io/httpchaos.chaos-mesh.org serverside-applied
  customresourcedefinition.apiextensions.k8s.io/iochaos.chaos-mesh.org serverside-applied
  customresourcedefinition.apiextensions.k8s.io/jvmchaos.chaos-mesh.org serverside-applied
  customresourcedefinition.apiextensions.k8s.io/kernelchaos.chaos-mesh.org serverside-applied
  customresourcedefinition.apiextensions.k8s.io/networkchaos.chaos-mesh.org serverside-applied
  customresourcedefinition.apiextensions.k8s.io/physicalmachinechaos.chaos-mesh.org serverside-applied
  customresourcedefinition.apiextensions.k8s.io/physicalmachines.chaos-mesh.org serverside-applied
  customresourcedefinition.apiextensions.k8s.io/podchaos.chaos-mesh.org serverside-applied
  customresourcedefinition.apiextensions.k8s.io/podhttpchaos.chaos-mesh.org serverside-applied
  customresourcedefinition.apiextensions.k8s.io/podiochaos.chaos-mesh.org serverside-applied
  customresourcedefinition.apiextensions.k8s.io/podnetworkchaos.chaos-mesh.org serverside-applied
  customresourcedefinition.apiextensions.k8s.io/remoteclusters.chaos-mesh.org serverside-applied
  customresourcedefinition.apiextensions.k8s.io/schedules.chaos-mesh.org serverside-applied
  customresourcedefinition.apiextensions.k8s.io/statuschecks.chaos-mesh.org serverside-applied
  customresourcedefinition.apiextensions.k8s.io/stresschaos.chaos-mesh.org serverside-applied
  customresourcedefinition.apiextensions.k8s.io/timechaos.chaos-mesh.org serverside-applied
  customresourcedefinition.apiextensions.k8s.io/workflownodes.chaos-mesh.org serverside-applied
  customresourcedefinition.apiextensions.k8s.io/workflows.chaos-mesh.org serverside-applied
  ```

  위의 명령어를 통해 CRD를 다시 배포하면 해당 문제가 발생하지 않는다. 

  <br>

  그리고 Server Side Apply 적용 외에 다른 방법으로는 다음과 같이 `kubectl create`로 배포해도 에러가 발생하지 않는다.

  ```bash
  son@son-localhost ~/chaos-mesh $ k create -f manifests/crd.yaml
  customresourcedefinition.apiextensions.k8s.io/awschaos.chaos-mesh.org created
  customresourcedefinition.apiextensions.k8s.io/azurechaos.chaos-mesh.org created
  customresourcedefinition.apiextensions.k8s.io/blockchaos.chaos-mesh.org created
  customresourcedefinition.apiextensions.k8s.io/dnschaos.chaos-mesh.org created
  customresourcedefinition.apiextensions.k8s.io/gcpchaos.chaos-mesh.org created
  customresourcedefinition.apiextensions.k8s.io/httpchaos.chaos-mesh.org created
  customresourcedefinition.apiextensions.k8s.io/iochaos.chaos-mesh.org created
  customresourcedefinition.apiextensions.k8s.io/jvmchaos.chaos-mesh.org created
  customresourcedefinition.apiextensions.k8s.io/kernelchaos.chaos-mesh.org created
  customresourcedefinition.apiextensions.k8s.io/networkchaos.chaos-mesh.org created
  customresourcedefinition.apiextensions.k8s.io/physicalmachinechaos.chaos-mesh.org created
  customresourcedefinition.apiextensions.k8s.io/physicalmachines.chaos-mesh.org created
  customresourcedefinition.apiextensions.k8s.io/podchaos.chaos-mesh.org created
  customresourcedefinition.apiextensions.k8s.io/podhttpchaos.chaos-mesh.org created
  customresourcedefinition.apiextensions.k8s.io/podiochaos.chaos-mesh.org created
  customresourcedefinition.apiextensions.k8s.io/podnetworkchaos.chaos-mesh.org created
  customresourcedefinition.apiextensions.k8s.io/remoteclusters.chaos-mesh.org created
  customresourcedefinition.apiextensions.k8s.io/schedules.chaos-mesh.org created
  customresourcedefinition.apiextensions.k8s.io/statuschecks.chaos-mesh.org created
  customresourcedefinition.apiextensions.k8s.io/stresschaos.chaos-mesh.org created
  customresourcedefinition.apiextensions.k8s.io/timechaos.chaos-mesh.org created
  customresourcedefinition.apiextensions.k8s.io/workflownodes.chaos-mesh.org created
  customresourcedefinition.apiextensions.k8s.io/workflows.chaos-mesh.org created
  ```

  apply는 부분적인 spec을 적용하여 리소스를 다시 구성해 주는 명령어이고, create는 yaml 파일안에 모든 것을 기술히여 존재하지 않는 리소스를 새로 생성하기 때문에 에러가 발생하지 않은 듯 보인다. 

  <br>