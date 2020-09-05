---
layout: post
title: "파이썬 크롤링"
date: 2000-01-01
desc: "파이썬 크롤링"
keywords: "son,blog,python,crawling"
categories: []
tags: [son,blog,python,crawling]
icon: icon-html
---

### 크롤링 관련 용어 정리
- 스크랩핑(scraping) : 데이터를 수집하는 행위
- 크롤링(Crawling) : 조직적 자동화된 방법으로 월드와이드웹을 탐색 하는 것
- 파싱(parsing) : 문장 혹은 문서를 구성 성분으로 분해하고 위계관계를 분석하여 문장의 구조를 결정하는 것

<br>

os 모듈 - 시스템 명령어를 실행시킬 수 있는 모듈

### 파이썬 크롤링에 사용되는 모듈

### 1. requests
requests 모듈은 Apache License 2.0에 따라 배포 된 HTTP 파이썬 라이브러리
> $ pip install requests

### 2. BeautifulSoup4
BeautifulSoup 모듈은 HTML과 XML을 파싱하는 데에 사용되는 파이썬 라이브러리
> $ pip install bs4

### 3. selenium
selenium은 웹 애플리케이션 테스트를 위한 포터블 프레임워크
> $ pip install selenium

사용할 브라우저의 드라이버를 설치
https://chromedriver.storage.googleapis.com/index.html?path=83.0.4103.14/

> from selenium import webdriver
> import time
>
> driver = webdriver.Chrome('chromedriver')
> driver.get("https://www.youtube.com/")
>
> time.sleep(3)
>
> search = driver.find_element_by_xpath('//*[@id="search"]')
>
> search.send_keys('검색')
> time.sleep(1)

<br>

[1 to 50 게임 자동화]

> num = 1
> 
> def clickBtn():
>     global num
>     btns = driver.find_elements_by_xpath('//*[@id="grid"]/div[*]')
> 
>     for btn in btns:
>         print(btn.text, end='\t')
>         if btn.text == str(num):
>             btn.click()
>             prunt(true)
>             num += 1
>             return
> 
> while num <= 50:
>     clickBtn()

<br>

### 특수문자 치환
re.sub('[^0-9a-zA-Zr-힗]', '', title)

### 다운로드
urlretrive(img_src, title + '.jpg')



