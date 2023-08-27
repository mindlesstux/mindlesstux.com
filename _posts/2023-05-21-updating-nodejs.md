---
title: 'Updating NodeJS'
date: '2023-05-21T000:45:00-04:00'
lastmod: '2023-05-21T000:45:00-04:00'
author: MindlessTux
layout: post
Reference_URL: https://github.com/nodesource/distributions/issues/1157
categories:
tags:
---
In my efforts to update the theme to my site (this site) I ran into issues of upgradeing NodeJS.  So I just wanted to make a quick post of a soltion I used.

<!--readmore-->

I found [this comment](https://github.com/nodesource/distributions/issues/1157#issuecomment-849595760) that really helped.

```bash
cd /etc/apt/sources.list.d 
sudo rm nodesource.list
sudo apt --fix-broken install
sudo apt update
sudo apt remove nodejs
sudo apt remove nodejs-doc
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs
```
