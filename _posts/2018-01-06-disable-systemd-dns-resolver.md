---
title: 'Disable Systemd DNS resolver'
date: '2018-01-06T02:13:22-05:00'
lastmod: '2018-01-06T02:13:22-05:00'
author: MindlessTux
layout: post
Reference_URL:
    - 'https://askubuntu.com/questions/907246/how-to-disable-systemd-resolved-in-ubuntu'
    - 'https://askubuntu.com/a/907249'
categories: [Ubuntu, Ubuntu]
tags: ["tips/tricks", ubuntu, "ubuntu desktop", "ubuntu server"]
---

I ran into an issue recently where I tracked back that the systemd resolver was trying to be a tad to helpful and causing me pain through DNS. So I set out to kill and keep it disabled across reboots. In some quick googling I found a good answer on askubuntu.com.

<!--readmore-->

Regurgitating what the answer is for my reference later and for anyone to find. (Along with a reference link below)

1. Disable systemd-resolvd service: 
    ```terminal
sudo systemctl disable systemd-resolved.service
sudo systemctl disable systemd-resolved-update-resolvconf.service
sudo service systemd-resolved stop
    ```

2. If file exists, add to “\[main\]” section in /etc/NetworkManager/NetworkManager.conf 
    ```
    dns=default
    ```
3. Delete symlink and replace /etc/resolv.conf
4. Restart network-manager 
    ```terminal
    sudo service network-manager restart
    ```