---
title: 'Reset lost iDRAC pass from OMSA'
date: '2018-04-04T19:35:28-04:00'
lastmod: '2018-04-04T19:35:28-04:00'
author: MindlessTux
layout: post
Reference_URL:
    - 'https://www.dell.com/community/PowerEdge-Hardware-General/Unluckly-I-forgot-my-dell-server-R720-IDRAC-password-now-I-can-t/td-p/4458788'
    - 'https://mindlesstux.com/2018/01/08/install-dell-openmanage-on-ubuntu-16-04-and-up/'
categories: []
tags: [idrac]
---

I was recently playing around with EM7 and various Dynamic Apps around Dell hardware. I came to find that my remote server (hosting this site) had storage in a ‘nonCritical’ state. I promptly tried logging into my idrac for the system and was having issues getting in. I had forgot what I had set for the password on the root and personal accounts. (For those that leave it root/calvin, shame on you!) This set off a “fear” if you will of having to shut down several VMs and get the datacenter hosting it to attach a remote KVM so I could change the drac password. I hate this thought. I spent 30 seconds here and there trying every password I could think of but nothing worked. I finally started googling around to see if there was any other method. I struck a winner.

<!--readmore-->

So first thing is you will need Dell Open manage installed on the host system. From what I can tell this wont work otherwise. I wrote up a short on [installing Dell OpenManage](https://mindlesstux.com/2018/01/08/install-dell-openmanage-on-ubuntu-16-04-and-up/) on an Ubuntu 16.04 system previously.

I quickly found that racadm is not properly setup for x64 systems.

```shell
root@hostsystem:~# racadm getconfig -g cfgUserAdmin -i 2
/opt/dell/srvadmin/sbin/racadm: line 3: /opt/dell/srvadmin/lib/srvadmin-omilcore/Funcs.sh: No such file or directory
/opt/dell/srvadmin/sbin/racadm: line 5: GetRegVal: command not found
/opt/dell/srvadmin/sbin/racadm: line 6: GetRegVal: command not found
/opt/dell/srvadmin/sbin/racadm: line 8: GetSysId: command not found
/opt/dell/srvadmin/sbin/racadm: line 9: GetRegVal: command not found
/opt/dell/srvadmin/sbin/racadm: line 10: GetRegVal: command not found
/opt/dell/srvadmin/sbin/racadm: line 13: printf: 0x: invalid hex number
ERROR: Unable to communicate with RAC controller. Please make sure that a RAC
controller is present in the server and appropriate software is installed.
```

Thankfully it looks like it was just missing a couple of things in the lib folder that are in lib64.

```shell
cd /opt/dell/srvadmin/lib
ln -s ../lib64/srvadmin-deng/
ln -s ../lib64/srvadmin-idrac/
ln -s ../lib64/srvadmin-isvc/
ln -s ../lib64/srvadmin-omacore/
ln -s ../lib64/srvadmin-omilcore/
ln -s ../lib64/srvadmin-storage/
```

After that, racadm appears to work on the hostsystem.

After all that, it appears that racadm works locally without needing a user/pass to do anything. This will help later when I will be working on pushing out LetsEncrypt certs into the iDRACs automatically. So I ran the following as mentioned on the dell forum post to reset the root password to ‘ThisIsNewPass’. If you want to change other users, change the 2 to what ever number they are in the user list.

```shell
racadm set idrac.users.2.password ThisIsNewPass
```

What it looks like when you run the command.

```shell
root@hostsystem:~# racadm set idrac.users.3.password ThisIsNewPass
[Key=idrac.Embedded.1#Users.3]
Object value modified successfully

root@hostsystem:~#

```
