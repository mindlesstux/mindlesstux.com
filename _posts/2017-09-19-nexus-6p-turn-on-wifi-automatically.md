---
title: 'Nexus 6P: Turn on WiFi Automatically'
date: '2017-09-19T13:52:41-04:00'
last_modified_at: '2017-09-19T13:52:41-04:00'
author: MindlessTux
layout: post
Reference_URL:
    - 'https://www.xda-developers.com/turn-on-wifi-automatically-nexus5x-nexus6p/'
categories: [Android]
tags: [android, "tips/tricks", "nexus 6p"]
---

I use a Nexus 6P as my day to day driver despite my phone having the early shutdown bug with the battery. (Currently working on getting an RMA, come on google I am at 4wks now waiting for outbound shipment.) I stumbled upon something that I just wanted to bookmark for use just in case I ever needed to find this again. Instead of a regular bookmark I figured it would be better if I made a public posting and linked the original artical.

<!--readmore-->

```
adb shell
settings put global wifi_wakeup_available 1
settings put global wifi_wakeup_enabled 1
```