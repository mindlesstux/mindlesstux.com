---
title: 'Fail2ban Setup'
date: '2023-09-20 10:00:00 -0400'
last_modified_at: '2023-09-20 10:00:00 -0400'
author: MindlessTux
layout: post
Reference_URL:
    - 'https://www.howtoforge.com/how-to-install-and-configure-fail2ban-on-fedora-33-centos-8/'
    - 'https://wiki.mikrotik.com/wiki/Use_Mikrotik_as_Fail2ban_firewall'
categories: []
tags: [fail2ban, sshd]
---

I finally got annoyed enough with the SSH login spam I decided it was time to do something about it.  Normally one would whitelist the port to certain addresses or change the port it listens on.  Both of these are good but I feel do not do enough.  Sure there are other ssh hardening steps that I did but I wanted just a bit more.  Enter Fail2Ban which will read the logs and extract out the IPs of devices attempting to login and failing.  At which point if the IP trips the threshold actions are taken against it.  So I did a simple setup of fail2ban that I intend to extend in the future but wanted to write up about it so far.

<!--readmore-->

First thing you will need to do is install the EPEL repository.
```bash
dnf install epel-release
```

From there I like to verify you can see the packages to be used.
```bash
[mindlesstux@eos ~]$ dnf search fail2ban
Last metadata expiration check: 10 days, 22:34:09 ago on Sun 16 Apr 2023 04:20:05 AM UTC.
===================================================================== Name Exactly Matched: fail2ban ======================================================================
fail2ban.noarch : Daemon to ban hosts that cause multiple authentication errors
==================================================================== Name & Summary Matched: fail2ban =====================================================================
fail2ban-all.noarch : Install all Fail2Ban packages and dependencies
fail2ban-firewalld.noarch : Firewalld support for Fail2Ban
fail2ban-hostsdeny.noarch : Hostsdeny (tcp_wrappers) support for Fail2Ban
fail2ban-mail.noarch : Mail actions for Fail2Ban
fail2ban-selinux.noarch : SELinux policies for Fail2Ban
fail2ban-sendmail.noarch : Sendmail actions for Fail2Ban
fail2ban-server.noarch : Core server component for Fail2Ban
fail2ban-shorewall.noarch : Shorewall support for Fail2Ban
fail2ban-shorewall-lite.noarch : Shorewall lite support for Fail2Ban
fail2ban-systemd.noarch : Systemd journal configuration for Fail2Ban
fail2ban-tests.noarch : Fail2Ban testcases
[mindlesstux@eos ~]$
```

I installed but maybe not fully used/configured:

- fail2ban
- fail2ban-firewalld
- fail2ban-selinux
- fail2ban-mail
- fail2ban-server
- fail2ban-systemd

```bash
sudo dnf -y install fail2ban fail2ban-firewalld fail2ban-selinux fail2ban-mail fail2ban-server fail2ban-systemd
```

Of course enable and start the fail2ban daemon
```bash
[root@bastion ~]# sudo systemctl enable --now fail2ban
Created symlink /etc/systemd/system/multi-user.target.wants/fail2ban.service → /usr/lib/systemd/system/fail2ban.service.
[root@bastion ~]# 
```

Edit the jail.local file as to overwrite the defaults in a clean way.
```bash
sudo nano /etc/fail2ban/jail.local
```

```
[DEFAULT]
# Ban hosts for one day:
bantime = 86400

# Override backend=auto in /etc/fail2ban/jail.conf
backend = systemd

# Ignore private networks
ignoreip_private_networks = 127.0.0.1/8 10.0.0.0/8 172.16.0.0/12 192.168.0.0/16 fc00::/7 fec0::/10

# Ignore Public IPs we might come from often enough
ignoreip_public_networks = 8.8.8.8

ignoreip = %(ignoreip_private_networks)s %(ignoreip_public_networks)s

action = mikrotik

[sshd]
enabled = true
filter = sshd[mode=aggressive]
```
{: file='/etc/fail2ban/jail.local'}

So what I have done in the configuration is the following:
- default section
  - Set bantime to the number of seconds I want to ban/block ips
    - 86400 seconds = 24 hour * 60 mins * 60 seconds
  - Set the backend to use systemd for some performance gains
  - Set ignoreip_private_networks is a list of all the subnets for private ips
  - Set ignoreip_public_networks to a list of ips where we would come from
  - Set ignoreip to the sum of the previous two
  - Set the default action to using mikrotik (custom script)
- sshd section
  - Enable sshd log polling
  - Set the filter to use the ssh filter mode of aggressive


Restart the service after the change to jail.local
```bash
sudo systemctl restart fail2ban
```

Check the status of the ignoredip to make sure it shows the list of expected ips
```bash
[root@bastion ~]# fail2ban-client get sshd  ignoreip   
These IP addresses/networks are ignored:
|- 127.0.0.0/8
|- 10.0.0.0/8
|- 172.16.0.0/12
|- 192.168.0.0/16
|- 100.64.0.0/10
|- fc00::/7
|- fec0::/10
`- 8.8.8.8
[root@bastion ~]# 
```

Give it a few minutes on the public ssh host and check the status of sshd, should see several lines found.
```bash
[root@bastion ~]# fail2ban-client status sshd
Status for the jail: sshd
|- Filter
|  |- Currently failed: 12
|  |- Total failed:     67
|  `- Journal matches:  _SYSTEMD_UNIT=sshd.service + _COMM=sshd
`- Actions
   |- Currently banned: 20
   |- Total banned:     20
   `- Banned IP list:   119.29.80.42 120.89.98.72 139.59.26.97 165.227.85.21 180.101.88.235 190.232.205.148 204.48.27.25 218.92.0.108 218.92.0.112 218.92.0.113 218.92.0.24 218.92.0.25 41.59.100.34 43.128.81.234 43.129.50.235 43.153.88.11 61.177.172.185 91.93.63.184 93.120.240.202 218.92.0.22
[root@bastion ~]# 
```