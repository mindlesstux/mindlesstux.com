---
title: 'Fix for ping socket operation not permitted'
date: '2022-01-15T00:27:01-05:00'
lastmod: '2022-01-15T00:27:01-05:00'
author: MindlessTux
layout: post
Reference_URL:
    - 'https://upwork.link/os_configs/centos-ping-socket-operation-not-permitted-for-usual-user/'
    - 'https://fedoraproject.org/wiki/Changes/EnableSysctlPingGroupRange'
categories: [Linux]
tags: [linux, troubleshooting]
---

Just a little while ago I checked my [kuma status page](https://status.mindlesstux.com) and noted that several checks were failing. In troubleshooting, I found that at least the ping command had a problem.

<!--readmore-->

```console
$ ping www.google.com
ping: socket: Operation not permitted
```

Needless to say, this became rather annoying and off to google I went. I quickly found these [two](https://upwork.link/os_configs/centos-ping-socket-operation-not-permitted-for-usual-user/) [pages](https://fedoraproject.org/wiki/Changes/EnableSysctlPingGroupRange) that described the problem and a fix for it. While I don’t understand yet how the problem started on my system, I am glad I found a fix.

  
Verify this is the problem

```console
# cat /proc/sys/net/ipv4/ping_group_range 
1       0
# ping www.google.com
ping: socket: Operation not permitted
```

First, create a file

```console
$ cd /usr/lib/sysctl.d
$ sudo vi 95-fix-ping-socket.conf
```

Contents of the new file

```markup
net.ipv4.ping_group_range = 0 2147483647
```

Kick sysctl to pick up the new settings

```console
$ sudo systemctl restart systemd-sysctl
```

Verify the fix is in place

```console
# cat /proc/sys/net/ipv4/ping_group_range 
0       2147483647
# ping -4 -c 1 www.google.com
PING www.google.com (142.250.80.100) 56(84) bytes of data.
64 bytes from lga34s36-in-f4.1e100.net (142.250.80.100): icmp_seq=1 ttl=118 time=0.901 ms

--- www.google.com ping statistics ---
1 packets transmitted, 1 received, 0% packet loss, time 0ms
rtt min/avg/max/mdev = 0.901/0.901/0.901/0.000 ms
```
