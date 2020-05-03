---
layout: post
title: "ssustack_installer"
date: 2020-04-30
desc: "ssustack_installer"
keywords: "son,blog,project,ssustack"
categories: [Project]
tags: [son,blog,project,ssustack]
icon: icon-html
---

# ssustack_installer

ssustack_installer 프로젝트는 ssustack 설치를 웹 브라우저에서 더욱 쉽게 설치할 수 있도록 도와줍니다.

ssustack_installer를 실행하면 웹 브라우저가 뜨게되고, 필요한 설정을 입력 및 선택하면 ssustack 스크립트를 기반으로 설치가 시작됩니다.

사용자의 선택에 따라 싱글노드 혹은 멀티호스트로 자유롭게 설치가 가능하다.

<br>

### Environment

OpenStack : Rokcy Release

OS : Ubuntu 18.04 LTS

<br>

### Installation

#### 1. ssustack & ssustack_installer 클론

OpenStack 환경을 구성하는 모든 노드에서 진행

```
$ git clone http://git.dotstack.io/crisis513/ssustack.git
$ git clone http://git.dotstack.io/dotstack/ssustack_installer.git
$ cd ssustack/bin
$ ./ssustack_user_creation.sh
$ cp -r <your_controller_path>/ssustack/ .
```

생성할 유저의 패스워드를 설정하여 ssustack 유저가 생성되면 ssustack 폴더를 ssustack 유저의 홈 디렉토리로 복사한다.

<br>

#### 2. hosts 및 SSH 설정

위의 작업이 끝나면 controller node에서 hosts 및 SSH 설정

```
$ sudo vi /etc/hosts
10.10.10.11 controller-node
10.10.10.21 compute-node1 
10.10.10.22 compute-node2
10.10.10.23 compute-node3
    
$ cd ssustack/bin/
$ ./creating_ssh_keys.sh [<host_name> ... ]
ex) ./creating_ssh_keys.sh compute-node1 compute-node2 compute-node3
```

<br>

#### 3. OpenStack 설치 스크립트 설정

```
$ cd ..
$ vi local.conf
```

<br>

#### 4. local.conf 설정을 기반으로 각 노드별 스크립트 생성

```
$ ./ssustack.sh
```

<br>

#### 5. ssustack/tmp 경로에서 각 노드에 맞는 스크립트 실행

```
## controller-node Case
$ cd tmp/controller/
$ ./controller.sh

## compute-node1 Case
$ cd tmp/compute/
$ ./compute_1.sh
 
## compute-node2 Case
$ cd tmp/compute/
$ ./compute_2.sh
 
## compute-node3 Case
$ cd tmp/compute/
$ ./compute_3.sh
```

> 현재는 각 스크립트를 직접 수정하여 rbd_secret_uuid 값을 수동으로 맞춰주어야 함.. 

<br>

#### 6. controller node에서 ceph 추가 설정

```
$ cd ../../bin/ # ssustack/bin/
$ ./ceph_configuration.sh [<host_name> ... ]
ex) ./ceph_configuration.sh compute-node1 compute-node2 compute-node3 
```

<br>

#### 7. 각 compute node에서 ceph osd 및 ceph mon 설정

```
$ cd ../../bin/ # ssustack/bin/
$ ./add_ceph_osd.sh /dev/sdb    # /dev/sdb는 각 컴퓨터 노드에서 추가할 osd 장치명
$ ./add_ceph_mon.sh 10.10.10.21 # 10.10.10.21은 각 컴퓨터 노드에서 management network로 사용하는 ip
```

<br>

#### 8. controller node에서 compute 호스트를 찾도록 스크립트 실행

```  
$ ./add_compute_node.sh
```


[ssustack_installer manual]
1. 주어진 ISO 이미지 기반 부팅 디스크로 우분투 설치 (user: ssustack, password: ssustack123)
2. 네트워크 인터페이스, 호스트네임, 호스트 설정파일 수정 후 reboot (/etc/network/interfaces, /etc/hostname, /etc/hosts)
3. ssh 설정 
	$ sudo vim /etc/hosts  # compute node들의 IP 설정
	$ ssustack_installer/bin/create_ssh_keys.sh <COMPUTE_NODE1> <COMPUTE_NODE2> ...  # /etc/hosts의 IP 및 hostname 매핑 기반
4. ssustack_installer 실행
	$ ssustack_installer/app.sh
5. 브라우저를 통해 설정 및 설치 진행
6. Ceph OSD 추가 (컴퓨트 노드+추가 하드 있는 경우) - ※주의 : $ sudo fdisk -l 명령어를 통해 디스크 이름 확인 (e.g. /dev/sdb)
	$ ssustack/bin/add_ceph_osd.sh <DISK_NAME> 
7. Ceph OSD 추가 확인
	$ sudo ceph -s 
8. 네트워크 생성
	# Horizon admin 유저로 로그인하여 아래 작업 실행
	a. Admin>Network>Networks의 Create Network
		*Network
		Name: external
		Project: admin
		Provider Network Type: Flat
		Physical Network: provider
		체크박스 4개 모두 체크
		*Subnet
		Subnet Name: external-subnet
		Network Address: 자기 네트워크 CDIR
		Gateway IP: 보통 x.x.x.254
	b. Admin>Network>Networks의 Create Network
		*Network
		Name: internal
		Project: admin
		Provider Network Type: vxlan 
		Segmentation ID: 1
		체크박스 위아래 두개만 체크 (기존 체크)
		*Subnet
		Subnet Name: internal-subnet
		Network Address: 내부 네트워크 CDIR
		Gateway IP: 보통 x.x.x.254
	c. Project>Network>Routers의 Create Router
		Router Name: router
		External Network: external
		나머지 체크박스 등 기본 상태로
	d. Network Topology에서 라우터 클릭 후 Add Interface
		Subnet: internal
	
9. 이미지 업로드
	$ ssustack/bin/create_image.sh
10. 대시보드 업데이트
	$ ssustack/bin/horizon_update.sh
11. 모니터링 설정
	a. Grafana 대시보드 접속 후 패스워드 설정
		스크립트가 정상 종료된 후에 WEB_SERVER_IP:3000(Grafana URL)로 접속한다.
		Grafana의 초기 아이디 및 패스워드는 admin/admin이다. 
	b. Gnocchi Datasources를 생성
		URL에는 Gnocchi Endpoint 주소를, Auth Mode는 token으로 하여 터미널에서 $ openstack token issue 명령을 통해 나온 토큰 값을 작성한다.
		e.g. URL: http://10.10.10.11:8041, Token: gAAAAABcj3Q0kqr_QDVI-ehExoBpwMYHFI2w0C5qYZpsXDT81-nnSkqLURqlwCwYR_2feaU7wWdi0KXiPNcwb1QSYofC_xt-o7tVhjkBg66r47QaGBLUBJPeugpwhRw3SR_bKqz203n3OqLaHdkfRz8DwUm2XDJuxgNkVJb6eV29gxJYGAS84qE
	c. Gnocchi 대시보드 
		[Dashboards - Settings - JSON Model] 패널으로 이동하여 ssustack 폴더에 있는 datasource-sample.json 내용을 붙여넣는다.
        
<br>

### Testing video

<video width="840" height="480" src="/static/assets/video/ssustack_working.mp4" controls></video>

> 영상이 재생되지 않는다면 IE 환경에서 다시 재생해보세요.
