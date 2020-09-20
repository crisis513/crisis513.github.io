---
layout: post
title: "[Project] naver-news-scraper"
date: 2020-04-08
desc: "[Project] naver-news-scraper"
keywords: "son,blog,project,nn-scraper"
categories: [Project]
tags: [son,blog,project,nn-scraper]
icon: icon-html
---

# naver-news-scraper

nn-scraper 프로젝트는 원하는 키워드에 해당하는 네이버 뉴스 속보를 스크랩하여 텔레그램 봇 혹은 카카오톡 봇으로 알림받을 수 있습니다.

<br>

### Environment

* OS : Ubuntu 18.04 LTS
* Python : 2.7.17
* pip : 9.0.1

<br>

### Installation

#### 1. naver-news-scraper 클론

naver-news-scraper 소스를 다운로드 합니다.

```
$ git clone https://github.com/crisis513/naver-news-scraper.git
$ cd naver-news-scraper
```

<br>

#### 2. 실행환경 설정

nn-scraper 실행을 위해 python 및 pip를 설치하고, 필요한 pip 패키지를 설치합니다.

```
$ sudo apt-get install -y python python-pip
$ pip install -r requirements.txt
```

<br>

#### 3. 봇 설정

nn-scraper에서 사용할 수 있는 봇은 카카오톡, 텔레그램 두 종류가 있습니다.

사용할 봇을 설정하는 방법은 다음과 같습니다.

1) config.py 파일에서 USE_BOT 값을 카카오톡일 경우 kakaotalk, 텔레그램일 경우 telegram으로 입력합니다.

2) 아래 Testing images에서 선택한 플랫폼에 맞게 토큰 값을 얻어 config.py 파일에서 요구하는 토큰 혹은 키 값을 입력합니다.

3) app.py 파일을 실행하면 1분 주기로 SEARCH_LIST 값에 설정된 키워드에 맞는 네이버 속보 뉴스를 스크랩하여 보내줍니다.

<br>

### Testing images

#### [Telegram bot]

텔레그램 봇을 사용하기 위해서는 @botfather 를 검색하여 아래 사진과 같이 새로운 봇을 만들고 봇의 TOKEN을 획득해야 합니다.

![use_telegrambot](/static/assets/img/landing/telegrambot.png){: width="360" height="1200"}

위에서 획득한 TOKEN 값을 config.py 파일에서 TELEGRAM_TOKEN 값에 넣어줍니다.

![use_telegrambot](/static/assets/img/landing/telegrambot2.jpg){: width="350" height="1200"}

<br>

#### [Kakaotalk bot]

카카오톡 봇을 사용하기 위해서는 Kakao Developer 사이트에서 카카오 API KEY를 발급 받아야 합니다.

https://developers.kakao.com/

해당 사이트로 들어가서 로그인을 하고 애플리케이션을 만들어줍니다. 

여기서는 NN-SCRAPER 라는 앱 이름으로 생성하였고, 정상적으로 설치되면 아래 사진처럼 각종 앱 키가 보이는 것을 확인할 수 있습니다.

![use_kakaotalkbot](/static/assets/img/landing/kakaotalkbot.png){: width="700" height="460"}

이 앱 키 중에서 REST API 키를 config.py 파일에서 RESTAPI_KEY 값에 넣어줍니다.

![use_kakaotalkbot](/static/assets/img/landing/kakaotalkbot2.png){: width="360" height="780"}