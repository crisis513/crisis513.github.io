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

[&nbsp;&nbsp; 2.2. VM 인스턴스 생성 및 워드프레스 구축](#list2_2)

[&nbsp;&nbsp; 2.3. VM 인스턴스와 Cloud SQL 연동](#list2_3)

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

- **Cloud SQL 구성**   <a name="list2_1"></a>

    GCP 콘솔 페이지에 접속하면 상단 바에 제품 및 리소스를 검색할 수 있는 텍스트 박스가 있습니다. 

    해당 검색창에서 `Cloud SQL Admin API`를 입력하여 다음 [그림 3]에 보이는 **사용** 버튼을 눌러 Cloud SQL를 활성화 시켜줍니다.

    | ![enable_cloudsql](/static/assets/img/landing/gcp_toyproject_3.png){: width="380" height="163"} |
    |:--:| 
    | [그림 3] Cloud SQL Admin API 활성화 |

    <br>

    Cloud SQL Admin API를 활성화 했다면 GCP 콘솔 페이지의 왼쪽 상단에 있는 탐색 메뉴에서 **[SQL] 탭**을 눌러 다음 [그림 4]와 같이 **Cloud SQL 인스턴스를 생성**했습니다.

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

- **VM 인스턴스 생성 및 워드프레스 구축**   <a name="list2_2"></a>

    웹서버에 연동할 Cloud SQL의 구성이 모두 끝난 후에 워드프레스를 설치할 VM 인스턴스를 생성합니다.

    탐색 메뉴에서 **[Compute Engine] - [VM 인스턴스]** 탭을 눌러 **만들기** 버튼을 클릭하여 다음 [그림 5]와 같이 인스턴스를 생성합니다.

    | ![create_instance](/static/assets/img/landing/gcp_toyproject_5.png){: width="450" height="1040"} |
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

    | ![iam_create](/static/assets/img/landing/gcp_toyproject_6.png){: width="800" height="627"} |
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

    | ![cloudsql_configuration](/static/assets/img/landing/gcp_toyproject_7.png){: width="650" height="442"} |
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

    | ![wordpress_installation](/static/assets/img/landing/gcp_toyproject_8.png){: width="750" height="554"} |
    |:--:| 
    | [그림 8] 워드프레스 설치 |

    <br>

    | ![wordpress_theme](/static/assets/img/landing/gcp_toyproject_9.png){: width="1000" height="541"} |
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

- **스냅샷을 통한 복제 및 NFS 설정**   <a name="list2_4"></a>

    - instance-wordpress-lb1 (nfs-server)

    ```bash
    [root@instance-wordpress-lb1 ~]# yum -y install nfs-utils

    [root@instance-wordpress-lb1 ~]# chmod 775 /var/www/html/wordpress
    [root@instance-wordpress-lb1 ~]# vim /etc/exports
    /var/www/html/wordpress         10.178.0.11(rw,sync,sec=sys)
    [root@instance-wordpress-lb1 ~]# exportfs -r

    [root@instance-wordpress-lb1 ~]# systemctl start nfs-server
    [root@instance-wordpress-lb1 ~]# systemctl enable nfs-server

    [root@instance-wordpress-lb1 ~]# firewall-cmd --permanent --add-service=nfs
    [root@instance-wordpress-lb1 ~]# firewall-cmd --permanent --add-service=mountd
    [root@instance-wordpress-lb1 ~]# firewall-cmd --reload
    success
    ```

    - instance-wordpress-lb2 (nfs-client)

    ```bash
    [root@instance-wordpress-lb2 ~]# yum -y install showmount
    [root@instance-wordpress-lb2 ~]# showmount -e 10.178.0.10
    Export list for 10.178.0.10:
    /var/www/html/wordpress 10.178.0.11

    [root@instance-wordpress-lb2 ~]# mount -o rw,sync,sec=sys 10.178.0.10:/var/www/html/wordpress /var/www/html/wordpress/
    [root@instance-wordpress-lb2 ~]# mount | grep wordpress
    10.178.0.10:/var/www/html/wordpress on /var/www/html/wordpress type nfs4 (rw,relatime,sync,vers=4.1,rsize=524288,wsize=524288,namlen=255,hard,proto=tcp,timeo=600,retrans=2,sec=sys,clientaddr=10.178.0.11,local_lock=none,addr=10.178.0.10)
    [root@instance-wordpress-lb2 ~]# vim /etc/fstab
    10.178.0.10:/var/www/html/wordpress     /var/www/html/wordpress nfs     rw,sync,sec=sys 0 0
    [root@instance-wordpress-lb2 ~]# mount -a
    ```

- **비관리형 로드밸런싱 구성**   <a name="list2_5"></a>



- **Bucket 생성 및 백업 설정**   <a name="list2_6"></a>



- **Stack Driver를 활용한 모니터링 및 로깅 시스템 구축**   <a name="list2_7"></a>



---

## <span style="color:purple">**3. 프로젝트 테스트**</span>   <a name="list3"></a>

<br>



- **NFS 테스트**   <a name="list3_1"></a>



- **Cloud SQL 로깅 테스트**   <a name="list3_2"></a>



- **오토스케일링 및 부하테스트**   <a name="list3_3"></a>


