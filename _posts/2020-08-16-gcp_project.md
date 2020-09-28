---
layout: post
title: "[Project] GCP를 활용한 웹사이트 구축과 모너터링 및 부하 테스트"
date: 2020-08-16
desc: "[Project] GCP를 활용한 웹사이트 구축과 모너터링 및 부하 테스트"
keywords: "son,blog,project,gcp"
categories: [Project]
tags: [son,blog,project,gcp]
icon: icon-html
---

본 프로젝트는 CCCR에서 GCP(Google Cloud Platform)를 공부하며 짧은 기간 진행된 토이 프로젝트입니다. 

구현 과정 및 설정까지 작성하여 글이 다소 길 수 있지만 하나의 프로젝트로 진행되어 포스팅을 따로 나누지 않았습니다. 

---

## 목차

[1. 프로젝트 개요](#list1)

[&nbsp;&nbsp; 1.1. 프로젝트 목적](#list1_2)

[&nbsp;&nbsp; 1.2. 프로젝트 아키텍처](#list1_2)

[2. 프로젝트 구현](#list2)

[&nbsp;&nbsp; 2.1. Cloud SQL 구성](#list2_1)

[&nbsp;&nbsp; 2.2. VM 인스턴스 생성 및 워드프레스 구축](#list2_2)

[&nbsp;&nbsp; 2.3. VM 인스턴스와 Cloud SQL 연동](#list2_3)

[&nbsp;&nbsp; 2.4. 관리형 로드 밸런싱 구성](#list2_4)

[&nbsp;&nbsp; 2.5. Bucket 생성 및 백업 설정](#list2_5)

[&nbsp;&nbsp; 2.6. Stack Driver를 활용한 모니터링 및 로깅 시스템 구축](#list2_6)

[3. 프로젝트 테스트](#list3)

[&nbsp;&nbsp; 3.1. Cloud SQL 로깅 테스트](#list3_1)

[&nbsp;&nbsp; 3.2. 오토 스케일링 및 부하 테스트](#list3_2)

<br>

---

## <span style="color:purple">**1. 프로젝트 개요**</span>   <a name="list1"></a>

<br>

- **프로젝트 목적**   <a name="list1_1"></a>

    본 프로젝트는 GCP의 전반적인 환경을 이해하고 흔하게 사용할 수 있는 기능들을 사용하여 GCP 환경에서 워드프레스(Wordpress)를 구축합니다.

    구축된 워드프레스 서버를 Google Cloud Console을 사용해 서비스와 상호작용하는 방법 등 GCP의 기본적인 기능들을 사용해보는 것을 목표로 진행된 프로젝트입니다.

    <br>

    프로젝트 진행 당시에 notion을 통해 정리했었던 프로젝트 진행 순서는 다음 [그림 1]과 같습니다.

    | ![What_we_did](/static/assets/img/landing/project/gcp_toyproject_1.png){: width="560" height="310"} |
    |:--:| 
    | [그림 1] 프로젝트 진행 순서 |

    <br>

- **프로젝트 아키텍처**   <a name="list1_2"></a>

    웹서비스는 CentOS 인스턴스를 생성하여 워드프레스를 구축하였고, 구축한 웹서비스에 GCP의 기능을 최대한 활용하는 형태로 프로젝트를 진행했습니다.

    다음 [그림 2]는 본 프로젝트의 구조를 쉽게 나타낼 수 있도록 아키텍처를 그린 것입니다.

    | ![project_architecture](/static/assets/img/landing/project/gcp_toyproject_2.png){: width="850" height="470"} |
    |:--:| 
    | [그림 2] 프로젝트 아키텍처 |

    <br>

    위와 같이 Compute Engine을 통한 인스턴스 생성, 로드 밸런싱, Cloud SQL 및 Bucket 연동, Stack Driver를 통한 로깅과 모니터링하는 부분까지 진행하였습니다.

    Cloud DNS를 이용하여 도메인을 설정해보고 싶었지만, 도메인을 구입하고 등록하는 과정이 필요하여 생략하였습니다.

    <br>

---

## <span style="color:purple">**2. 프로젝트 구현**</span>   <a name="list2"></a>

<br>

- **Cloud SQL 구성**   <a name="list2_1"></a>

    GCP 콘솔 페이지에 접속하면 상단 바에 제품 및 리소스를 검색할 수 있는 텍스트 박스가 있습니다. 

    해당 검색창에서 `Cloud SQL Admin API`를 입력하여 다음 [그림 3]에 보이는 **사용** 버튼을 눌러 **Cloud SQL를 활성화** 시켜줍니다.

    | ![enable_cloudsql](/static/assets/img/landing/project/gcp_toyproject_3.png){: width="320" height="132"} |
    |:--:| 
    | [그림 3] Cloud SQL Admin API 활성화 |

    <br>

    Cloud SQL Admin API를 활성화 했다면 GCP 콘솔 페이지의 왼쪽 상단에 있는 탐색 메뉴에서 **[SQL] 탭**을 눌러 다음 [그림 4]와 같이 **Cloud SQL 인스턴스를 생성**했습니다.

    | ![create_cloudsql_instance](/static/assets/img/landing/project/gcp_toyproject_4.png){: width="450" height="552"} |
    |:--:| 
    | [그림 4] Cloud SQL 인스턴스 생성 |

    <br>

    본 프로젝트에서는 MySQL 5.7을 선택하여 데이터베이스를 생성하였고, 리전은 성능 향상을 위해 비교적 가까운 **서울 리전**을 선택하였습니다. 

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

- **VM 인스턴스 생성 및 워드프레스 구축**   <a name="list2_2"></a>

    웹서버에 연동할 Cloud SQL의 구성이 모두 끝난 후에 워드프레스를 설치할 VM 인스턴스를 생성합니다.

    탐색 메뉴에서 **[Compute Engine] - [VM 인스턴스]** 탭을 눌러 **만들기** 버튼을 클릭하여 다음 [그림 5]와 같이 인스턴스를 생성합니다.

    | ![create_instance](/static/assets/img/landing/project/gcp_toyproject_5.png){: width="450" height="1040"} |
    |:--:| 
    | [그림 5] VM 인스턴스 생성 |
    
    <br>

    먼저, 인스턴스를 생성할 때 앞서 생성한 Cloud SQL 인스턴스와 같은 리전(서울 - `asia-northeast3-a`)을 선택하도록 합니다.

    flavor는 실제 서비스를 운영할 목적이 아니기에 VM 사양이 낮은 `n1-standard-1`을 선택하였고, 

    OS는 `CentOS 7`, 웹서버의 `HTTP 트래픽을 허용`해주도록 체크하였습니다.

    <br>

    생성한 인스턴스에 워드프레스를 설치하기 위해 터미널에 입력한 명령어는 다음과 같습니다.

     ```bash
    [crisis51526@instance-wordpress ~]$ sudo su -

    [root@instance-wordpress ~]# yum -y update
    [root@instance-wordpress ~]# yum -y install https://rpms.remirepo.net/enterprise/remi-release-7.rpm 
    [root@instance-wordpress ~]# yum -y install epel-release yum-utils

    [root@instance-wordpress ~]# setenforce 0

    [root@instance-wordpress ~]# yum-config-manager --disable remi-php54
    [root@instance-wordpress ~]# yum-config-manager --enable remi-php74
    [root@instance-wordpress ~]# yum -y install php php-fpm
    [root@instance-wordpress ~]# yum -y install php-cli php-redis php-brotli php-intl php-gd php-gmp php-imap php-bcmath \
        php-interbase php-json php-mbstring php-mysqlnd php-odbc php-opcache php-memcached php-tidy php-pdo php-pdo-dblib \
        php-pear php-pgsql php-process php-pecl-apcu php-pecl-geoip php-pecl-imagick php-pecl-hrtime php-pecl-json \
        php-pecl-memcache php-pecl-rar php-pecl-pq php-pecl-redis4 php-pecl-yaml php-pecl-zip
    [root@instance-wordpress ~]# systemctl enable httpd
    [root@instance-wordpress ~]# systemctl restart httpd
    [root@instance-wordpress ~]# systemctl enable php-fpm && systemctl start php-fpm
    
    [root@instance-wordpress ~]# yum -y install redis memcached
    [root@instance-wordpress ~]# systemctl enable redis && systemctl enable memcached 
    [root@instance-wordpress ~]# systemctl start redis && systemctl start memcached
    [root@instance-wordpress ~]# vim /etc/sysconfig/memcached
    OPTIONS="-l 127.0.0.1"

    [root@instance-wordpress ~]# systemctl restart memcached
    
    [root@instance-wordpress ~]# yum -y install wget
    [root@instance-wordpress ~]# wget http://wordpress.org/latest.tar.gz
    [root@instance-wordpress ~]# tar -xvzf latest.tar.gz -C /var/www/html
    [root@instance-wordpress ~]# chown -R apache: /var/www/html/wordpress
    [root@instance-wordpress ~]# vim /etc/httpd/conf.d/wordpress.conf
    <VirtualHost *:80>
        DocumentRoot /var/www/html/wordpress
        ServerName lls.wordpress.com
        ServerAlias www.lls.wordpress.com
    
        <Directory /var/www/html/wordpress/>
            Options +FollowSymlinks
            AllowOverride All
        </Directory>
    
        ErrorLog /var/log/httpd/tecminttest-error-log
        CustomLog /var/log/httpd/tecminttest-acces-log common
    </VirtualHost>
    
    [root@instance-wordpress ~]# systemctl restart httpd.service
    [root@instance-wordpress ~]# cd /var/www/html/wordpress/
    [root@instance-wordpress wordpress]# cp wp-config-sample.php wp-config.php 
    [root@instance-wordpress wordpress]# vim wp-config.php
    define( 'DB_NAME', 'wordpress' );
    define( 'DB_USER', 'wordpressuser' );
    define( 'DB_PASSWORD', 'Input Your Password.' );
    define( 'DB_HOST', 'localhost' );
    ```

    <br>

- **VM 인스턴스와 Cloud SQL 연동**   <a name="list2_3"></a>

    워드프레스를 설치한 인스턴스에서 Cloud SQL Proxy를 통해 Cloud SQL에 연결하기 위해서는 권한이 필요하다.

    탐색 메뉴에서 **[IAM 및 관리자] - [IAM]** 탭을 눌러 다음 [그림 6]와 같이 새로운 구성원을 추가합니다.

    | ![iam_create](/static/assets/img/landing/project/gcp_toyproject_6.png){: width="800" height="627"} |
    |:--:| 
    | [그림 6] 서비스 계정 생성 |

    <br>

    역할에서 **Cloud SQL -> Cloud SQL 편집자**를 선택하고 서비스 키도 생성해줍니다.

    ```python
    {
        "type": "service_account",
        "project_id": "cccr-gcp-project",
        "private_key_id": "3ef41c7827f3524bc358d489313f6084c229cf2f",
        "private_key": "-----BEGIN PRIVATE KEY-----\\nMIIEvAIBADANBgkqhkiG9w0BAQEFAASCBKYwggSiAgEAAoIBAQCVnSNgrX4B+Vi1\\nYoTpCMXSl/p/tSjfhGaIUprWzCSfl3mVVQJlnN9mDQ8GTvg4l5UpGxvuaftV3MDN\\npwBkZ/tCKE7h/DTRx1cay28paXGV/vKZt8OwwWCCmm5Uk5ZvIvmel/oGho9TC886\\nJ1DvWSqjZL+aRwFxWJqGwpF4zxXOFjStcqhCdnT9UipCfOgqx2xBoN4N0mhkUEby\\nfqLqo7AqEYh/5/zXWR9PTm7bESbqtz2i+VUOGwDDt5U0PVatGpFahNL8qUj4lJlO\\nOzltgNICedHdUMa9B+GuSi5NOKHkuR5lOJZGcqziZFQLw3UpUyGMPVdsupcn6ZQm\\nLwdl/lpfAgMBAAECgf8TSS5GSBb2Ki5FM23unDLj8rNXwwKBzY9qAzvydF5ENEJ3\\n/X1Rm+cwQH6vUX6tzNxtcBEpqn+7kblIyT5DsyOwY4HHn7svT4Lq8U5jCDScIUEk\\nj4uqPUMzkrSmMmAx81A6IV0Zej7/dYZA+NB2Cgh1B4erW3vUIJfKx0n5SLiG2CN9\\nSRC2L3YlwKPrmGiKXSvt6p2qezDjwycooph5s8EWjZ4Wyy5lP2bjaIGqs+QzIN3s\\nYAMf3KTNF8EHNs4jJYmFiwIuz8q4zscnt3z7TF5vsgcBSgKqnE5rSa2UiyXx/8um\\nw7gU5taZh32o0Xk8AYTrVW7vYx9PkAz7g77yVFkCgYEAxQSTYZmkPxXKYs9aGeyi\\nYCRnBNgNr1WjvQ5DQGBAUQS4OiZEb6JoWDqlOvcMqvF1Vu2CPv5MTgEWrs2+mAmj\\n8xWvySm97oJ2FfnYX2rl/SmGmxbWq2CKzsU56jJNDUGBiC4/3Ot8hsy/cnzEec54\\nhU1yW+mEwq0Ew50Ab5IldcsCgYEAwmeFo8XoI86Y8MakIoW6rL9zredwf+B9qYjI\\n7VHGcEnAcCfnRevLj7kK/QFswox/cfGmIbOxd1BPBH4D6nVKmRWqIzkpnCPkVRJ8\\n5BuImNhzfurPUgJWf0lNkrRaSwbsBYf12ZQ01J5t4Bg8ArQ5nNNT4ieC9dptpYTL\\n2hFSuz0CgYAMkzEw/pR8LlDfo6p1kyP+DPTCW2PsOAQecgWa20nfofR8Sar+kRgl\\n4YBgVhpp4sWBieFRUfve0rT27Uzn+V2Mi2rP5SkpSwxsdKj51iHd2cOsrHWBNMVH\\nU1FSAGnombDB12neGO220OS7UvlbaPFKWNoewbXmkxKFxcScWnCnpwKBgQCIiwub\\nhzLQi5hybSL1uHXwRZxrhgZHWxcID7IItgop7jNC01QmkUJt1St5nxmT3/jXwEHO\\npBa+1eJaJmR7thxKP6Q7jzfBmpgShKTB1vDvYgBlIWmykT/NsV/R7ekJj3gRPniY\\ndPdSa2CDKKJlx847b1cYnmXmZp/ixM4lgUtZhQKBgQC7GBZxRh4dx6JWqQ8J2Vaq\\n1sE83o0/K0i4i2MqEw70CG4nFs5831fnV6DSVWpyvxlN9M8Ce19ZcpVLP4UD0pE6\\ndTKGhvdIkQeat9yWBr4J/+d9jz3uleXGZCmVYrR/f2Ge8Vb/DWEUf2Ps9s0QZkoO\\nN6xZ+UJBHIwBp+i3pLqXOw==\\n-----END PRIVATE KEY-----\\n",
        "client_email": "wpmanager@cccr-gcp-project.iam.gserviceaccount.com",
        "client_id": "116608554003641610764",
        "auth_uri": "<https://accounts.google.com/o/oauth2/auth>",
        "token_uri": "<https://oauth2.googleapis.com/token>",
        "auth_provider_x509_cert_url": "<https://www.googleapis.com/oauth2/v1/certs>",
        "client_x509_cert_url": "<https://www.googleapis.com/robot/v1/metadata/x509/wpmanager%40cccr-gcp-project.iam.gserviceaccount.com>"
    }
    ```

    생성된 서비스 키의 샘플입니다. Cloud SQL Proxy를 통해 Cloud SQL에 접속할 때 필요합니다.

    <br>

    그리고 다음 [그림 7]과 같이 Cloud SQL 인스턴스에서 접근을 허용할 네트워크를 추가해주어야 합니다.

    | ![cloudsql_configuration](/static/assets/img/landing/project/gcp_toyproject_7.png){: width="650" height="442"} |
    |:--:| 
    | [그림 7] Cloud SQL 인스턴스 설정 |

    <br>

    연결 방식을 **공개 IP**에 체크하여 프록시를 통해 Cloud SQL에 접근할 수 있도록 설정하고,
    
    아래쪽의 네트워크 추가 버튼을 눌러 워드프레스 **웹서버의 공개 IP 주소를 등록**합니다.

    <br>

    다음은 워드프레스 웹서버에서 Cloud SQL에 접속하는 과정을 정리한 명령어입니다.

    ```bash
    [root@instance-wordpress wordpress]# yum -y install mysql
    [root@instance-wordpress wordpress]# mysql -u root -p -h 34.64.148.237
    Enter password: 
    Welcome to the MariaDB monitor.  Commands end with ; or \\g.
    Your MySQL connection id is 343
    Server version: 5.7.25-google-log (Google)

    Copyright (c) 2000, 2018, Oracle, MariaDB Corporation Ab and others.

    Type 'help;' or '\\h' for help. Type '\\c' to clear the current input statement.

    MySQL [(none)]> show databases;
    +--------------------+
    | Database           |
    +--------------------+
    | information_schema |
    | mysql              |
    | performance_schema |
    | sys                |
    | wordpress          |
    +--------------------+
    5 rows in set (0.01 sec)

    MySQL [(none)]> exit
    Bye

    [root@instance-wordpress ~]# mkdir /cloudsql
    [root@instance-wordpress ~]# chmod 777 /cloudsql
    [root@instance-wordpress ~]# wget https://dl.google.com/cloudsql/cloud_sql_proxy.linux.amd64 -O cloud_sql_proxy
    --2020-08-02 10:39:20--  https://dl.google.com/cloudsql/cloud_sql_proxy.linux.amd64
    Resolving dl.google.com (dl.google.com)... 172.217.161.238, 2404:6800:400a:80c::200e
    Connecting to dl.google.com (dl.google.com)|172.217.161.238|:443... connected.
    HTTP request sent, awaiting response... 200 OK
    Length: 14492253 (14M) [application/octet-stream]
    Saving to: ‘cloud_sql_proxy’

    100%[=========================================================================>] 14,492,253  22.0MB/s   in 0.6s   

    2020-08-02 10:39:21 (22.0 MB/s) - ‘cloud_sql_proxy’ saved [14492253/14492253]

    [root@instance-wordpress ~]# chmod +x cloud_sql_proxy
    [root@instance-wordpress ~]# vim wordpress-key.json
    # wpmanager 서비스 계정에서 키를 만들 때 생성된 json 내용 입력

    [root@instance-wordpress ~]# ./cloud_sql_proxy -dir=/cloudsql -instances=cccr-gcp-project:asia-northeast3:mysql-wordpress -credential_file=/root/wordpress-key.json &
    [1] 15932
    [root@instance-wordpress ~]# 2020/08/02 15:23:07 Rlimits for file descriptors set to {&{8500 8500}}
    2020/08/02 15:23:07 using credential file for authentication; email=wpmanager@cccr-gcp-project.iam.gserviceaccount.com
    2020/08/02 15:23:07 Listening on /cloudsql/cccr-gcp-project:asia-northeast3:mysql-wordpress for cccr-gcp-project:asia-northeast3:mysql-wordpress
    2020/08/02 15:23:07 Ready for new connections*

    [root@instance-wordpress ~]# mysql -u root -p -S /cloudsql/cccr-gcp-project:asia-northeast3:mysql-wordpress 
    Enter password: 
    2020/08/02 10:52:05 New connection for "cccr-gcp-project:asia-northeast3:mysql-wordpress"
    Welcome to the MariaDB monitor.  Commands end with ; or \\g.
    Your MySQL connection id is 429
    Server version: 5.7.25-google-log (Google)

    Copyright (c) 2000, 2018, Oracle, MariaDB Corporation Ab and others.

    Type 'help;' or '\\h' for help. Type '\\c' to clear the current input statement.

    MySQL [(none)]> exit
    Bye
    2020/08/02 10:52:24 Client closed local connection on /cloudsql/cccr-gcp-project:asia-northeast3:mysql-wordpress

    [root@instance-wordpress ~]# ps
    PID TTY          TIME CMD
    1467 pts/0    00:00:00 sudo
    1469 pts/0    00:00:00 su
    1470 pts/0    00:00:00 bash
    16476 pts/0    00:00:00 cloud_sql_proxy
    16517 pts/0    00:00:00 ps
    [root@instance-wordpress ~]# kill -9 16476
    [1]+  Killed                  ./cloud_sql_proxy -dir=/cloudsql -instances=cccr-gcp-project:asia-northeast3:mysql-wordpress -credential_file=wordpress-key.json
    [root@instance-wordpress ~]# mkdir -p /opt/cloudsqlproxy/
    [root@instance-wordpress ~]# cp cloud_sql_proxy /opt/cloudsqlproxy/
    [root@instance-wordpress ~]# vim ~/cloudsqlproxy.service
    [Unit]
    Description=Google Cloud SQL Proxy
    After=syslog.target network.target auditd.service

    [Service]
    ExecStart=/opt/cloudsqlproxy/cloud_sql_proxy -dir=/cloudsql -instances=cccr-gcp-project:asia-northeast3:mysql-wordpress -credential_file=/root/wordpress-key.json
    ExecStop=/bin/kill -TERM $MAINPID

    [Install]
    WantedBy=multi-user.target

    [root@instance-wordpress ~]# cp ~/cloudsqlproxy.service /etc/systemd/system/
    [root@instance-wordpress ~]# systemctl daemon-reload
    [root@instance-wordpress ~]# systemctl start cloudsqlproxy
    [root@instance-wordpress ~]# systemctl enable cloudsqlproxy
    Created symlink from /etc/systemd/system/multi-user.target.wants/cloudsqlproxy.service to /etc/systemd/system/cloudsqlproxy.service.
    [root@instance-wordpress ~]# systemctl status cloudsqlproxy
    ● cloudsqlproxy.service - Google Cloud SQL Proxy
        Loaded: loaded (/etc/systemd/system/cloudsqlproxy.service; disabled; vendor preset: disabled)
        Active: active (running) since Sun 2020-08-02 10:55:53 UTC; 13s ago
    Main PID: 16524 (cloud_sql_proxy)
        CGroup: /system.slice/cloudsqlproxy.service
                └─16524 /opt/cloudsqlproxy/cloud_sql_proxy -dir=/cloudsql -instances=cccr-gcp-project:asia-northeast3...

    Aug 02 10:55:53 instance-wordpress systemd[1]: Started Google Cloud SQL Proxy.
    Aug 02 10:55:53 instance-wordpress cloud_sql_proxy[16524]: 2020/08/02 10:55:53 Rlimits for file descriptors s...0}}
    Aug 02 10:55:53 instance-wordpress cloud_sql_proxy[16524]: 2020/08/02 10:55:53 using credential file for auth...com
    Aug 02 10:55:53 instance-wordpress cloud_sql_proxy[16524]: 2020/08/02 10:55:53 Listening on /cloudsql/cccr-gc...ess
    Aug 02 10:55:53 instance-wordpress cloud_sql_proxy[16524]: 2020/08/02 10:55:53 Ready for new connections
    Hint: Some lines were ellipsized, use -l to show in full.

    [root@instance-wordpress wordpress]# vim /var/www/html/wordpress/wp-config.php
    define( 'DB_HOST', 'localhost:/cloudsql/cccr-gcp-project:asia-northeast3:mysql-wordpress' );
    ```

    Cloud SQL Proxy가 정상적으로 동작하는지 테스트 한 후에 데몬을 생성하여 cloudsqlproxy 서비스가 실행되도록 했습니다.
    
    wordpress-key.json 파일의 내용에는 위에서 wpmanager 서비스 계정의 키를 만들 때 생성된 json 내용을 입력하면 됩니다.

    워드프레스의 설정파일에서 데이터베이스 설정 값에 cloudsqlproxy 서비스로 생겨난 소켓 파일의 경로를 적어주고 정상적으로 연결되는지 확인합니다.

    <br>

    Cloud SQL에 정상적으로 연결되었다면 워드프레스를 설치하고 워드프레스 데이터베이스와 테이블이 정상적으로 생성되었는지 확인하도록 합니다.

    | ![wordpress_installation](/static/assets/img/landing/project/gcp_toyproject_8.png){: width="750" height="554"} |
    |:--:| 
    | [그림 8] 워드프레스 설치 |

    <br>

    | ![wordpress_theme](/static/assets/img/landing/project/gcp_toyproject_9.png){: width="1000" height="541"} |
    |:--:| 
    | [그림 9] 워드프레스 테마 적용 |

    <br>

    워드프레스 설치 및 테마 적용이 정상적으로 이루어진 후에 Cloud SQL에서 워드프레스 데이터베이스의 테이블이 정상적으로 생성되었는지 확인합니다.

    ```python
    [root@instance-wordpress ~]# mysql -u root -p -S /cloudsql/cccr-gcp-project:asia-northeast3:mysql-wordpress
    Enter password: 
    Welcome to the MariaDB monitor.  Commands end with ; or \\g.
    Your MySQL connection id is 1478
    Server version: 5.7.25-google-log (Google)

    Copyright (c) 2000, 2018, Oracle, MariaDB Corporation Ab and others.

    Type 'help;' or '\\h' for help. Type '\\c' to clear the current input statement.

    MySQL [(none)]> use wordpress
    Reading table information for completion of table and column names
    You can turn off this feature to get a quicker startup with -A

    Database changed
    MySQL [wordpress]> show tables;
    +-----------------------+
    | Tables_in_wordpress   |
    +-----------------------+
    | wp_commentmeta        |
    | wp_comments           |
    | wp_links              |
    | wp_options            |
    | wp_postmeta           |
    | wp_posts              |
    | wp_term_relationships |
    | wp_term_taxonomy      |
    | wp_termmeta           |
    | wp_terms              |
    | wp_usermeta           |
    | wp_users              |
    +-----------------------+
    12 rows in set (0.00 sec)
    ```

    <br>

- **관리형 로드 밸런싱 구성**   <a name="list2_4"></a>

    GCLB(Google Cloud Load Balancing)을 구성하기 위해서는 기본적으로 대상으로 할 인스턴스 그룹이 존재해야 합니다. 인스턴스 그룹은 **오토 스케일링(Auto-scaling)을 위한** `관리형 인스턴스 그룹`과 **템플릿을 사용하지 않고 직접 VM 인스턴스를 추가할 수 있는** `비관리형 인스턴스 그룹`으로 나뉩니다.

    <br>

    본 프로젝트에서는 관리형 인스턴스 그룹을 구성하고 부하 분산기를 생성하여 로스 밸런싱 환경을 구축합니다.

    먼저 VM 인스턴스에 대한 `스냅샷을 생성`하고, 생성한 스냅샷으로 `이미지를 생성`합니다. 

    | ![create_snapshot](/static/assets/img/landing/project/gcp_toyproject_10.png){: width="400" height="566"} |
    |:--:| 
    | [그림 10] 스냅샷 생성 |

    <br>

    | ![create_image](/static/assets/img/landing/project/gcp_toyproject_11.png){: width="400" height="689"} |
    |:--:| 
    | [그림 11] 이미지 생성 |

    <br>

    이미지까지 정상적으로 생성되었다면 다음으로 관리형 인스턴스 그룹을 만들기 전에 다음 [그림 12]과 같이 `인스턴스 템플릿을 생성`합니다. 
    
    그룹에 속한 VM의 종류가 여러 개라면 모든 VM의 운영체제의 이미지를 지정해야 합니다.

    | ![create_instance_template](/static/assets/img/landing/project/gcp_toyproject_12.png){: width="400" height="881"} |
    |:--:| 
    | [그림 12] 인스턴스 템플릿 생성 |

    <br>

    인스턴스 템플릿을 정상적으로 생성한 후에 다음 [그림 13]과 같이 `관리형 인스턴스 그룹을 생성`합니다.

    | ![create_instance_group](/static/assets/img/landing/project/gcp_toyproject_13.png){: width="700" height="1114"} |
    |:--:| 
    | [그림 13] 인스턴스 그룹 생성 |

    <br>

    인스턴스 그룹까지 정상적으로 생성되었다면 부하 분산기를 생성할 준비가 끝났습니다. 

    탐색 메뉴에서 **[네트워크 서비스] - [부하 분산]** 탭에 들어와서 `부하 분산기 만들기`를 눌러줍니다.

    HTTP(S), TCP, UDP에 대한 부하 분산기를 만들 수 있으며 본 프로젝트에서는 워드프레스를 통한 웹서버 인스턴스를 부하 분산 시켜주기 위해 `HTTP(S) 부하 분산기`를 선택하고 `인터넷 트래픽을 VM으로 분산`을 눌러줍니다.

    <br>

    다음 단계로 넘어오면 백엔드 서비스와 프런트엔드 서비스를 생성하는 화면으로 넘어오게 됩니다.


    | ![create_lb_backend](/static/assets/img/landing/project/gcp_toyproject_14.png){: width="400" height="589"} |
    |:--:| 
    | [그림 14] 백엔드 서비스 생성 |

    <br>

    기존에 만들어둔 백엔드 서비스가 없기 때문에 새로운 서비스 생성을 선택하고 백앤드 서비스의 이름과 앞에서 생성한 인스턴스 그룹을 선택하면 됩니다. 다음으로는 로드밸런서에서 들어온 트래픽을 인스턴스 그룹의 인스턴스들의 어느 포트로 전달할 것인지를 포트 번호에 정의하는데, 여기서는 HTTP 트래픽을 전달하는 것이기 때문에 80을 선택합니다.

    <br>
    
    백엔드 서비스를 생성할 때 상태 확인(Health check)을 선택하는 항목이 있는데 마찬가지로 기존에 만들어둔 상태 확인이 없기 때문에 새로 생성합니다.

    | ![create_lb_check](/static/assets/img/landing/project/gcp_toyproject_15.png){: width="400" height="465"} |
    |:--:| 
    | [그림 15] 상태 확인 생성 |

    <br>

    상태 확인은 인스턴스 그룹 내의 인스턴스가 양호한지를 체크하고 만약에 정상적이지 않으면 비정상 노드는 부하 분산에서 빼버리는 기능을 수행합니다. 프로토콜은 HTTP를 입력하고, 포트에는 HTTP 포트인 80포트, 그리고 서비스가 정상인지를 확인하는 확인 간격은 체크 주기이고, 제한 시간은 이 시간(초)내에 응답이 없으면 장애라고 판단을 합니다.

    <br>

    | ![create_lb_frontend](/static/assets/img/landing/project/gcp_toyproject_16.png){: width="400" height="493"} |
    |:--:| 
    | [그림 16] 프런트엔드 서비스 생성 |

    <br>

    마지막으로 프런트엔드 서비스를 설정하는데, 여기서는 어떤 프로토콜을 어떤 IP와 포트로 받을 것인지, HTTPS의 경우에는 SSL 인증서를 설정하는 작업을 합니다. 본 프로젝트에서는 HTTP 프로토콜을 80 포트로 설정하기 때문에 [그림 16]과 같이 설정하고, 부하 분산 이름을 입력하여 생성을 완료합니다.

    <br>

    정상적으로 부하 분산기가 생성이 되면 다음 [그림 17]과 같이 백엔드 서비스에 지정된 인스턴스 그룹에 해당하는 인스턴스가 모두 정상 동작하는 화면을 볼 수 있습니다.

    | ![lb_detail](/static/assets/img/landing/project/gcp_toyproject_17.png){: width="800" height="404"} |
    |:--:| 
    | [그림 17] 부하 분산기 세부 정보 |

    <br>

- **Bucket 생성 및 백업 설정**   <a name="list2_5"></a>

    탐색 메뉴에서 **[Storage] - [브라우저]** 탭을 눌러 **버킷 생성** 버튼을 클릭하여 버킷을 생성합니다.

    | ![create_bucket](/static/assets/img/landing/project/gcp_toyproject_18.png){: width="900" height="145"} |
    |:--:| 
    | [그림 18] 버킷 생성 |

    <br>

    버킷 이름을 입력하고 리전을 아시아로 설정한 후에 나머지는 기본 값으로 생성하게 되면 위의 [그림 18]과 같이 버킷이 생성된 모습을 확인할 수 있습니다.

    <br>

    생성한 버킷의 권한 탭에 들어오면 버킷에 접근 가능한 구성원들과 역할을 확인할 수 있습니다.

    다음 [그림 19]에서 보이는 **추가** 버튼을 클릭하여 새로운 구성원을 추가해줍니다.

    <br>

    | ![bucket_allUsers](/static/assets/img/landing/project/gcp_toyproject_19.png){: width="500" height="223"} |
    |:--:| 
    | [그림 19] 버킷 allUsers 구성원 추가 |
    
    <br>

    `allUsers` 구성원에 `저장소 개체 관리자` 역할을 주어 모든 사용자들이 저장소에 접근할 수 있도록 설정했습니다.

    <br>

    다음은 Cloud SQL에 저장된 wordpress 데이터베이스를 `mysqldump`하여 `crontab`을 통해 주기적으로 백업하기 위한 명령어입니다.

    ```bash
    [root@instance-wordpress ~]# vim /etc/my.cnf
    [mysqldump]
    user=root
    password=Input Your Password

    [root@instance-wordpress ~]# vim cloudsql_backup.sh
    #!/bin/bash
    db_instance=mysql-wordpress
    db_name=wordpress
    db_user=root
    bucket_name=gs://bucket-mysql-wordpress
    socket_path=/cloudsql/cccr-gcp-project:asia-northeast3:mysql-wordpress
    date_YYYYMMDDHHMMSS=`date '+%Y%m%d%H%M%S'`
    backupfile_name=wordpress_${date_YYYYMMDDHHMMSS}.sql

    echo "Cloud SQLl daily backup start.."

    #gcloud sql export csv $db_instance $bucket_name/test.csv --database=$db_name --query=$sql_query
    mysqldump -u $db_user -S $socket_path --databases $db_name --hex-blob --single-transaction --default-character-set=utf8mb4 > $backupfile_name

    gsutil mv $backupfile_name $bucket_name

    echo "Cloud SQL daily backup stop.."

    [root@instance-wordpress ~]# crontab -e
    0 */3 * * * /root/cloudsql_backup.sh
    ```
    <br>

    Cloud SQL을 백업하는 쉘 스크립트를 작성하여 crontab에 등록하여 3시간 주기로 mysqldump가 실행되도록 설정해두고 일정 시간이 지난 후에 버킷에 정상적으로 백업되어 저장됐는지 확인하였습니다.

    | ![cloudsql_bucket_backup1](/static/assets/img/landing/project/gcp_toyproject_20.png){: width="800" height="323"} |
    |:--:| 
    | [그림 20] crontab을 사용한 Cloud SQL의 주기적인 백업 |

    <br>

    위의 [그림 20]에서 최종 수정 날짜를 확인해보면 3시간 주기로 저장되어 있는 것을 확인할 수 있습니다.

    <br>

    같은 형태로 이번에는 syslog를 백업하는 쉘 스크립트를 작성하여 crontab에 등록합니다.

    ```bash
    [root@instance-wordpress ~]# vim apache_log_backup.sh
    #!/bin/bash

    echo "syslog daily backup start.."

    cat /var/log/messages | grep -iE "apache|wordpress" >> /root/apache_log_backup_$(date '+%y-%m-%d').log
    gsutil cp /root/apache_log_backup_*.log gs://bucket-mysql-wordpress/apache_log_backup/
    rm -rf /root/*.log

    echo "syslog daily backup stop.."

    [root@instance-wordpress ~]# crontab -e
    * * * * * /root/apache_log_backup.sh
    ```

    <br>
    
    이번에는 매 분마다 쉘 스크립트를 실행하도록 crontab에 등록하고 버킷을 확인해보았습니다.

    <br>

    | ![syslog_bucket_backup](/static/assets/img/landing/project/gcp_toyproject_21.png){: width="800" height="383"} |
    |:--:| 
    | [그림 21] crontab을 사용한 syslog의 주기적인 백업 |

    <br>

- **Stack Driver를 활용한 모니터링 및 로깅 시스템 구축**   <a name="list2_6"></a>

    - VM 인스턴스에 monitoring-agent 설치
    
        ```bash
        $ curl -sSO https://dl.google.com/cloudagents/add-monitoring-agent-repo.sh
        $ sudo bash add-monitoring-agent-repo.sh
        $ sudo yum -y update
        $ sudo yum -y install stackdriver-agent

        $ sudo systemctl start stackdriver-agent
        $ sudo systemctl enable stackdriver-agent
        ```

    - VM 인스턴스에 logging-agent 설치

        ```bash
        $ curl -sSO https://dl.google.com/cloudagents/add-logging-agent-repo.sh
        $ sudo bash add-logging-agent-repo.sh
        $ sudo yum -y update
        $ sudo yum -y install google-fluentd
        $ sudo yum -y install google-fluentd-catch-all-config-structured

        $ sudo systemctl start google-fluentd
        $ sudo systemctl enable google-fluentd
        ```
    
    <br>

    모니터링과 로깅을 할 VM 인스턴스에 에이전트를 설치하고 **[모니터링] - [대시보드]** 탭을 눌러 들어갑니다.

    대시보드 페이지에 들어오면 `Create Dashboard` 버튼을 통해 새로운 대시보드를 생성할 수 있습니다.

    원하는 대시보드의 이름을 입력하고 대시보드를 생성하면 우측 상단에 `Add Chart` 버튼을 눌러 원하는 차트들을 추가하여 대시보드를 커스터마이징할 수 있습니다.

    | ![add_chart](/static/assets/img/landing/project/gcp_toyproject_22.png){: width="800" height="402"} |
    |:--:| 
    | [그림 22] 대시보드 차트 추가 |

    <br>

    위의 [그림 22]와 같이 차트에 나타낼 CPU, Memory, I/O 등 모니터링할 항목들의 `Metric`과 Instance, Group 등 `Resource 타입`을 지정하고 차트를 생성할 수 있습니다. 원하는 차트를 추가하고 대시보드를 확인하면 다음 [그림 23]과 같이 monitoring-agent을 통해 VM 인스턴스의 Metric들을 모니터링할 수 있습니다.

    | ![monitoring_dashboard](/static/assets/img/landing/project/gcp_toyproject_23.png){: width="1000" height="744"} |
    |:--:| 
    | [그림 23] 모니터링 대시보드 완성 |

    <br>

    다음으로 로깅 시스템은 **[로그 기록] - [로그 뷰어]** 탭에 들어오면 다음 [그림 24]와 같이 logging-agent를 통해 수집된 로그들을 확인할 수 있습니다.

    | ![log_viewer](/static/assets/img/landing/project/gcp_toyproject_24.png){: width="900" height="294"} |
    |:--:| 
    | [그림 24] 로그 뷰어 확인|

    <br>

    | ![log_query](/static/assets/img/landing/project/gcp_toyproject_25.png){: width="900" height="316"} |
    |:--:| 
    | [그림 25] 로그 뷰어 쿼리 빌더 |

    <br>

---

## <span style="color:purple">**3. 프로젝트 테스트**</span>   <a name="list3"></a>

<br>

- **Cloud SQL 로깅 테스트**   <a name="list3_1"></a>

    서비스 중인 워드프레스 서버에서 Cloud SQL에 대한 접속을 시도하는데 다음 [그림 26]과 같이 패스워드를 잘못 입력한 상황입니다.

    | ![cloudsql_connection_failure](/static/assets/img/landing/project/gcp_toyproject_26.png) |
    |:--:| 
    | [그림 26] Cloud SQL 접속 실패 |

    <br>

    패스워드를 잘못 입력하여 접속을 실패하여 쉘에 나타나는 로그를 다음 [그림 27]처럼 GCP의 로그 뷰어에서도 확인할 수 있습니다.

    | ![cloudsql_log_viewer](/static/assets/img/landing/project/gcp_toyproject_27.png) |
    |:--:| 
    | [그림 27] Cloud SQL 접속 실패 로그 뷰어 |

    <br>

- **오토 스케일링 및 부하 테스트**   <a name="list3_2"></a>

    다음으로 아파치(Apache)의 `JMeter`라는 툴을 사용하여 부하 테스트를 진행합니다.

    JMeter에서 핵심 기능은 웹 HTTP/HTTPS 프로토콜을 통해 클라이언트의 요청을 수행하여 부하를 발생시키는 것입니다.

    요청에 대한 성공/실패, 소요 시간 등의 정보를 기록하여 제공해줍니다.
    
    다음 [그림 28]은 테스트할 사용자 수 및 반복 횟수 등을 설정해 웹 사이트 서버의 성능을 테스트한 내용입니다.

    | ![jmeter](/static/assets/img/landing/project/gcp_toyproject_28.png) |
    |:--:| 
    | [그림 28] JMeter로 부하 테스트 |

    <br>

    여기서 **스레드를 300개와 1000개 두 번의 부하 테스트를 진행**하였고, 300개의 스레드로 요청을 보냈을 때 오토 스케일링 기능으로 인해 인스턴스의 갯수가 2개에서 3개로 늘어났고, 1000개의 스레드로 부하를 주었을 때 3개에서 4개로 인스턴스가 자동 확장되는 것을 확인할 수 있었습니다.

    | ![instance_upscale](/static/assets/img/landing/project/gcp_toyproject_29.png) |
    |:--:| 
    | [그림 29] 인스턴스 자동 확장 |

    <br>

    위의 [그림 29]는 인스턴스가 3개에서 4개로 확장되는 장면을 캡처한 것입니다. 

    다음으로 부하 테스트를 진행하면서 인스턴스가 자동 생성되는 부분을 모니터링을 통해 확인하였습니다.

    | ![instance_upscale_monitoring](/static/assets/img/landing/project/gcp_toyproject_30.png) |
    |:--:| 
    | [그림 30] 인스턴스 확장 모니터링 |

    <br>

    위의 [그림 30]에서 볼 수 있듯이 부하 테스트를 수행한 시점에 **CPU, Memory, Network traffic이 확 늘어난 것을 확인**할 수 있고, 그와 동시에 인스턴스가 각각 하나씩 생겨난 것을 확인할 수 있습니다. 메모리 사용량을 확인하는 부분에서 측정 항목(인스턴스)가 새로 생겨난 것을 쉽게 확인할 수 있습니다.

    그 후 **마지막 10분**을 `안정화 기간`이라고 하는데, 안정화 기간동안 관찰된 최대 부하를 기준으로 관리형 인스턴스 그룹이 유지되면 자동으로 인스턴스가 축소 되는 것을 확인할 수 있습니다. 

    | ![instance_downscale](/static/assets/img/landing/project/gcp_toyproject_31.png) |
    |:--:| 
    | [그림 31] 인스턴스 자동 축소 |

    <br>

    물론 안정화 기간에 대한 설정은 로드밸런싱을 구성할 때 따로 설정이 가능하고, 인스턴스는 생성된지 가장 오래된 인스턴스를 우선으로 삭제되는 것 같았습니다.

    이로써 GCP의 기능을 활용한 서버 구성과 로깅 및 테스트까지 정상적으로 끝났습니다!

    <br>
