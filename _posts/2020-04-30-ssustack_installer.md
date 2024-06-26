---
layout: post
title: "[Project] ssustack_installer"
date: 2020-04-30
desc: "[Project] ssustack_installer"
keywords: "project,ssustack,installer,openstack,cloud computing"
categories: [Project]
tags: [project,ssustack,installer,openstack,cloud computing]
icon: icon-html
---

> **본 프로젝트는 2017년 숭실대학교에서 김명호 교수님의 지도하에 진행되었습니다.**

---

## ssustack_installer

ssustack_installer 프로젝트는 ssustack 설치를 웹 브라우저에서 더욱 쉽게 설치할 수 있도록 도와준다.

ssustack_installer를 실행하면 웹 브라우저가 뜨게되고, 필요한 설정을 입력 및 선택하면 ssustack 스크립트를 기반으로 설치가 시작된다.

사용자의 선택에 따라 싱글노드 혹은 멀티호스트로 자유롭게 설치가 가능하다.

<br>

### Environment

* OpenStack : Rokcy Release
* OS : Ubuntu 18.04 LTS

<br>

### Installation

다음의 설치 방법은 모든 노드가 Ubuntu 18.04 운영체제로 설치된 환경에서 진행되었다.

<br>

#### 1. ssustack & ssustack_installer 클론

OpenStack 환경을 구성하는 모든 노드에서 진행한다.

```
$ git clone http://git.dotstack.io/crisis513/ssustack.git
$ git clone http://git.dotstack.io/dotstack/ssustack_installer.git
$ cd ssustack/bin
$ ./ssustack_user_creation.sh
$ cp -r <your_controller_path>/ssustack/ .
```

생성할 유저의 패스워드를 설정하여 ssustack 유저가 생성되면 ssustack 폴더를 ssustack 유저의 홈 디렉토리로 복사한다.

<br>

#### 2. network 설정

모든 노드의 네트워크 인터페이스를 수정 후 재부팅해주어야 한다. 먼저 Controller node의 경우, 외부와의 통신을 위한 네트워크와 오픈스택 컴포넌트들이 서로 API를 호출할 때 사용하는 내부 네트워크, VM 인스턴스들이 외부와 통신하기 위한 메뉴얼 네트워크를 설정해주어야 한다.

```
$ sudo vi /etc/network/interfaces
auto <INTERFACE_NAME_1>
iface <INTERFACE_NAME_1> inet static
    address <PUBLIC_IP>
    netmask <PUBLIC_IP_NETMASK>
    gateway <PUBLIC_IP_GATEWAY>
    dns-servernames <DNS_NAMESERVERS>
auto <INTERFACE_NAME_2>
iface <INTERFACE_NAME_2> inet static
    address 10.10.10.11
    netmask 255.255.255.0
auto <INTERFACE_NAME_3>
iface <INTERFACE_NAME_3> inet manual
up ip link set dev $IFACE up
down ip link set dev $IFACE down
```

Compute node의 경우, 메뉴얼 네트워크가 필요없다. 오픈스택 설치가 정상적으로 설치되고나면 외부와의 통신은 필요없어 외부 네트워크를 OSD들 간의 통신을 위한 스토리지 네트워크로 설정하여 사용해도 된다.

```
$ sudo vi /etc/network/interfaces
auto <INTERFACE_NAME_1>
iface <INTERFACE_NAME_1> inet static
    address <PUBLIC_IP>
    netmask <PUBLIC_IP_NETMASK>
    gateway <PUBLIC_IP_GATEWAY>
    dns-servernames <DNS_NAMESERVERS>
auto <INTERFACE_NAME_2>
iface <INTERFACE_NAME_2> inet static
    address 10.10.10.21
    netmask 255.255.255.0
```

<br>

#### 3. hosts 및 SSH 설정

위의 작업이 끝나면 Controller node에서 hosts 및 SSH 설정한다.

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

#### 4. ssustack_installer 실행

ssustack_installer는 Controller node에서 실행시킨다.

```
$ cd ssustack_installer/
$ ./app.sh
```

app.sh를 실행시키고나면 우분투 기본 브라우저로 사용되는 파이어폭스가 실행된다.

<br>

#### 5. Welcome 페이지

권장 사양과 현재 PC의 사양을 확인해보고 설치 전 작업이 재대로 되었는지 확인하고 다음으로 넘어간다.

<br>

#### 6. Enable Services 페이지

Controller node 및 Compute node에서 설치할 서비스를 선택하고 넘어간다. 필수로 설치되어야하는 패키지의 경우 이미 체크되어 있다.

<br>

#### 7. Environment Settings 페이지

각각의 Controller node 및 Compute node에서 설정되어야 할 ip, subnet, hostname, password 등을 설정하고 다음으로 넘어간다.

<br>

#### 8. Installing 페이지

앞의 설정이 재대로 되어있는지 확인해보고 Start 버튼을 눌러주고 설치 로그를 확인해준다.

> 한 번만 누르고 브라우저를 종료하면 안된다.

<br>

#### 9. Finished 페이지

정상적으로 설치되었는지 확인하고 종료한다.

<br>

#### 10. 추가 설정

아래 비디오에서 Ceph OSD를 추가하고, Horizon에서 네트워크를 생성하고, 우분투 이미지를 업로드하여 인스턴스 생성 및 테스트하는 부분까지 보여준다. (10:30)

<br>

### Testing video

<video width="840" height="480" src="/static/assets/video/blog/ssustack_working.mp4" controls></video>

> 영상이 재생되지 않는다면 IE 환경에서 다시 재생
