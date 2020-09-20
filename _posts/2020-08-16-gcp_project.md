---
layout: post
title: "[Project] GCP를 활용한 웹사이트 구축과 모너터링 및 부하테스트"
date: 2020-08-16
desc: "[Project] GCP를 활용한 웹사이트 구축과 모너터링 및 부하테스트"
keywords: "son,blog,project,gcp"
categories: [Project]
tags: [son,blog,project,gcp]
icon: icon-html
---

본 프로젝트는 CCCR에서 GCP(Google Cloud Platform)를 공부하며 짧은 기간 진행된 토이 프로젝트입니다.

---

## 목차

[1. 프로젝트 개요](#list1)

[2. 프로젝트 구현](#list2)

[&nbsp;&nbsp; 2.1. Cloud SQL 구성](#list2_1)

[&nbsp;&nbsp; 2.2. 인스턴스 생성](#list2_2)

[&nbsp;&nbsp; 2.3. Wordpress 구축 및 Cloud SQL 연동](#list2_3)

[&nbsp;&nbsp; 2.4. 스냅샷을 통한 복제 및 NFS 설정](#list2_4)

[&nbsp;&nbsp; 2.5. 비관리형 로드밸런싱 구성](#list2_5)

[&nbsp;&nbsp; 2.6. Bucket 생성 및 백업 설정](#list2_6)

[&nbsp;&nbsp; 2.7. Stack Driver를 활용한 모니터링 및 로깅 시스템 구축](#list2_7)

[3. 프로젝트 테스트](#list3)

[&nbsp;&nbsp; 3.1. NFS 테스트](#list3_1)

[&nbsp;&nbsp; 3.2. Cloud SQL 로깅 테스트](#list3_2)

[&nbsp;&nbsp; 3.3. 오토스케일링 및 부하테스트](#list3_3)

---

## <span style="color:purple">**1. 프로젝트 개요**</span>   <a name="list1"></a>

<br>

먼저, 프로젝트 진행 당시에 notion을 통해 정리했었던 프로젝트 진행 순서는 다음 [그림 1]과 같습니다.

| ![What_we_did](/static/assets/img/landing/gcp_toyproject_1.png){: width="560" height="310"} |
|:--:| 
| [그림 1] 프로젝트 진행 순서 |

<br>

웹서비스는 CentOS 인스턴스를 생성하여 워드프레스(Wordpress)를 구축하였고, 구축한 웹서비스에 GCP의 기능을 최대한 활용하는 형태로 프로젝트를 진행했습니다.

GCP에서 제공해주는 Cloud DNS를 이용하여 도메인을 설정해보고 싶었지만, 도메인을 구입하고 등록하는 과정이 필요하여 생략했습니다.

다음 [그림 2]는 본 프로젝트의 구조를 쉽게 나타낼 수 있도록 아키텍처를 그린 것입니다.

<br>

| ![project_architecture](/static/assets/img/landing/gcp_toyproject_2.png){: width="850" height="400"} |
|:--:| 
| [그림 2] 프로젝트 아키텍처 |

<br>

---

## <span style="color:purple">**2. 프로젝트 구현**</span>   <a name="list2"></a>

<br>

### Cloud SQL 구성   <a name="list2_1"></a>

GCP 콘솔 페이지에 접속하면 상단 바에 제품 및 리소스를 검색할 수 있는 텍스트 박스가 있습니다. 

해당 검색창에서 `Cloud SQL Admin API`를 입력하여 다음 [그림 3]에 보이는 **사용** 버튼을 눌러 Cloud SQL를 활성화 시켜줍니다.

| ![enable_cloudsql](/static/assets/img/landing/gcp_toyproject_3.png){: width="380" height="163"} |
|:--:| 
| [그림 3] Cloud SQL Admin API 활성화 |

<br>

Cloud SQL Admin API를 활성화 했다면 GCP 콘솔 페이지의 왼쪽 상단에 있는 탐색 메뉴에서 **SQL 탭**을 눌러 다음 [그림 4]와 같이 **Cloud SQL 인스턴스를 생성**했습니다.

| ![create_cloudsql_instance](/static/assets/img/landing/gcp_toyproject_4.png){: width="500" height="600"} |
|:--:| 
| [그림 4] Cloud SQL 인스턴스 생성 |

<br>

본 프로젝트에서는 MySQL 5.7을 선택하여 데이터베이스를 생성하였고, 리전은 성능 향상을 위해 비교적 가까운 서울 리전을 선택하였습니다. 

다음으로 GCP 콘솔 기능인 Cloud Shell 화면에서 웹서버에서 사용할 데이터베이스의 설정을 진행합니다.

```mysql
crisis51526@cloudshell:~ (cccr-gcp-project)$ gcloud sql connect mysql-wordpress --user=root --quiet
Allowlisting your IP for incoming connection for 5 minutes...done.
Connecting to database with SQL user [root].Enter password: Input Your Password

Your MySQL connection id is 187
Server version: 5.7.25-google-log (Google)

Copyright (c) 2000, 2020, Oracle and/or its affiliates. All rights reserved.

Oracle is a registered trademark of Oracle Corporation and/or its
affiliates. Other names may be trademarks of their respective
owners.

Type 'help;' or '\\h' for help. Type '\\c' to clear the current input statement.

mysql> GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY 'Input Your Password' WITH GRANT OPTION;
Query OK, 0 rows affected, 1 warning (0.05 sec)

mysql> CREATE DATABASE wordpress CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
Query OK, 1 row affected (0.05 sec)

mysql> GRANT ALL ON wordpress.* TO 'wordpressuser'@'%' IDENTIFIED BY 'Input Your Password';
Query OK, 0 rows affected, 1 warning (0.06 sec)

mysql> FLUSH PRIVILEGES;
Query OK, 0 rows affected (0.06 sec)
```

<br>

### 인스턴스 생성   <a name="list2_2"></a>

웹서버로 사용할 인스턴스를 선택할 때 같은 리전을 선택하도록 합니다.

<br>

### Wordpress 구축 및 Cloud SQL 연동   <a name="list2_3"></a>



### 스냅샷을 통한 복제 및 NFS 설정   <a name="list2_4"></a>



### 비관리형 로드밸런싱 구성   <a name="list2_5"></a>



### Bucket 생성 및 백업 설정   <a name="list2_6"></a>



### Stack Driver를 활용한 모니터링 및 로깅 시스템 구축   <a name="list2_7"></a>



---

## <span style="color:purple">**3. 프로젝트 테스트**</span>   <a name="list3"></a>

<br>



### NFS 테스트   <a name="list3_1"></a>



### Cloud SQL 로깅 테스트   <a name="list3_2"></a>



### 오토스케일링 및 부하테스트   <a name="list3_3"></a>


