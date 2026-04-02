Recently I decided to nuke a VPS system I have to rebuild it and make a little better use of the resources it offers to me.  One of the steps I need is setting up fail2ban and crowdsec again to defend against the endless ssh scanning shit that is out there.  Yes I know its better to whitelist IPs and/or change the ssh port, but this system is kind of a bastion for me.

To start it is a fresh build of Rocky Linux 9 with current updates applied.  Instead of having fail2ban touch firewalld I want it to simply add/remove routes into a blackhole.

```
[root@eos ~]# dnf search fail2ban
Last metadata expiration check: 1:26:41 ago on Sat 11 Jan 2025 02:23:22 PM UTC.
============================================== Name Exactly Matched: fail2ban ==============================================
fail2ban.noarch : Daemon to ban hosts that cause multiple authentication errors
============================================= Name & Summary Matched: fail2ban =============================================
fail2ban-all.noarch : Install all Fail2Ban packages and dependencies
fail2ban-firewalld.noarch : Firewalld support for Fail2Ban
fail2ban-hostsdeny.noarch : Hostsdeny (tcp_wrappers) support for Fail2Ban
fail2ban-mail.noarch : Mail actions for Fail2Ban
fail2ban-selinux.noarch : SELinux policies for Fail2Ban
fail2ban-sendmail.noarch : Sendmail actions for Fail2Ban
fail2ban-server.noarch : Core server component for Fail2Ban
fail2ban-systemd.noarch : Systemd journal configuration for Fail2Ban
fail2ban-tests.noarch : Fail2Ban testcases
[root@eos ~]#
```

Doing a quick search for the package it looks like there is a meta package and several packages that make it up.

Attempting to install the meta package it seems that it will be bringing in more than I want.  As I dont want any extra packages than what is absolutly nessary

```
[root@eos ~]# dnf install fail2ban
Last metadata expiration check: 1:26:49 ago on Sat 11 Jan 2025 02:23:22 PM UTC.
Dependencies resolved.
============================================================================================================================
 Package                             Architecture            Version                          Repository               Size
============================================================================================================================
Installing:
 fail2ban                            noarch                  1.0.2-12.el9                     epel                    8.8 k
Installing dependencies:
 esmtp                               x86_64                  1.2-19.el9                       epel                     52 k
 fail2ban-firewalld                  noarch                  1.0.2-12.el9                     epel                    8.9 k
 fail2ban-selinux                    noarch                  1.0.2-12.el9                     epel                     29 k
 fail2ban-sendmail                   noarch                  1.0.2-12.el9                     epel                     12 k
 fail2ban-server                     noarch                  1.0.2-12.el9                     epel                    444 k
 libesmtp                            x86_64                  1.0.6-24.el9                     epel                     66 k
 liblockfile                         x86_64                  1.14-10.el9.0.1                  baseos                   27 k

Transaction Summary
============================================================================================================================
Install  8 Packages

Total download size: 647 k
Installed size: 1.8 M
Is this ok [y/N]: n
Operation aborted.
[root@eos ~]# 
```

So I went with a stripped down set.

```
[root@eos ~]# dnf install fail2ban-server fail2ban-systemd fail2ban-selinux
Last metadata expiration check: 1:29:18 ago on Sat 11 Jan 2025 02:23:22 PM UTC.
Dependencies resolved.
============================================================================================================================
 Package                            Architecture             Version                           Repository              Size
============================================================================================================================
Installing:
 fail2ban-selinux                   noarch                   1.0.2-12.el9                      epel                    29 k
 fail2ban-server                    noarch                   1.0.2-12.el9                      epel                   444 k
 fail2ban-systemd                   noarch                   1.0.2-12.el9                      epel                   8.9 k

Transaction Summary
============================================================================================================================
Install  3 Packages

Total download size: 482 k
Installed size: 1.4 M
Is this ok [y/N]: y
Downloading Packages:
(1/3): fail2ban-selinux-1.0.2-12.el9.noarch.rpm                                             2.9 MB/s |  29 kB     00:00
(2/3): fail2ban-systemd-1.0.2-12.el9.noarch.rpm                                              16 kB/s | 8.9 kB     00:00
(3/3): fail2ban-server-1.0.2-12.el9.noarch.rpm                                              602 kB/s | 444 kB     00:00
----------------------------------------------------------------------------------------------------------------------------
Total                                                                                       405 kB/s | 482 kB     00:01
Running transaction check
Transaction check succeeded.
Running transaction test
Transaction test succeeded.
Running transaction
  Preparing        :                                                                                                    1/1
  Running scriptlet: fail2ban-selinux-1.0.2-12.el9.noarch                                                               1/3
  Installing       : fail2ban-selinux-1.0.2-12.el9.noarch                                                               1/3
  Running scriptlet: fail2ban-selinux-1.0.2-12.el9.noarch                                                               1/3
libsemanage.semanage_direct_install_info: Overriding fail2ban module at lower priority 100 with module at priority 200.

  Installing       : fail2ban-server-1.0.2-12.el9.noarch                                                                2/3
  Running scriptlet: fail2ban-server-1.0.2-12.el9.noarch                                                                2/3
  Installing       : fail2ban-systemd-1.0.2-12.el9.noarch                                                               3/3
  Running scriptlet: fail2ban-selinux-1.0.2-12.el9.noarch                                                               3/3
  Running scriptlet: fail2ban-systemd-1.0.2-12.el9.noarch                                                               3/3
  Verifying        : fail2ban-selinux-1.0.2-12.el9.noarch                                                               1/3
  Verifying        : fail2ban-server-1.0.2-12.el9.noarch                                                                2/3
  Verifying        : fail2ban-systemd-1.0.2-12.el9.noarch                                                               3/3

Installed:
  fail2ban-selinux-1.0.2-12.el9.noarch     fail2ban-server-1.0.2-12.el9.noarch     fail2ban-systemd-1.0.2-12.el9.noarch

Complete!
[root@eos ~]#
```

Now that the packages are installed I need to do my configureations.  First thing will be making the jail.local file.

``` /etc/fail2ban/jail.local
[DEFAULT]
# Ban hosts for two weeks (60s * 60m * 24d * 2w) = time in seconds
bantime = 1209600

# Override backend=auto in /etc/fail2ban/jail.conf
#backend = systemd

# Ignore private networks
ignoreip_private_networks = 127.0.0.1/8 10.0.0.0/8 172.16.0.0/12 192.168.0.0/16 100.64.0.0/10 fc00::/7 fec0::/10

# Ignore Public IPs we might come from often enough
ignoreip_public_networks = 8.8.8.8

# Ignore personal network address
ignoreip_personal_networks = IPV4_COLO_IP_SPACE IPV6_COLO_IP_SPACE IPV$_HOME_IP_SPACE IPV6_HOME_IP_SPACE

# Ignore Work VPN addresses
ignoreip_work_vpn_site1 = NATIP1 NATIP2
ignoreip_work_vpn_site2 = NATIP1 NATIP2
ignoreip_work_vpn_site2 = NATIP1 NATIP2
ignoreip_work_vpn_site4 = NATIP1 NATIP2
ignoreip_work_vpn_site5 = NATIP1 NATIP2
ignoreip_work_vpns = %(ignoreip_work_vpn_site1)s %(ignoreip_work_vpn_site2)s %(ignoreip_work_vpn_site3)s %(ignoreip_work_vpn_site4)s %(ignoreip_work_vpn_site5)s

# Set the ignore to the various ignores
ignoreip = %(ignoreip_private_networks)s %(ignoreip_public_networks)s %(ignoreip_personal_networks)s %(ignoreip_work_vpns)s

action = route[blocktype=blackhole]

bantime.overalljails = true

[sshd]
enabled = true
filter = sshd[mode=aggressive]
action = route[blocktype=blackhole]
```

Now if I start fail2ban it will start chugging on the logs but there is one problem.  I have not delt with selinux yet on the system.  Here I am gonna take a lazy method.

```
[root@eos ~]# setenforce 0
[root@eos ~]# systemctl restart fail2ban
[root@eos ~]# ip route
....
blackhole 35.156.206.203
blackhole 46.101.74.125
blackhole 61.171.29.211
blackhole 120.157.224.161
blackhole 218.92.0.210
blackhole 218.92.0.246
...
```

To wrap this up there are two things left.
Edit `/etc/selinux/config` change `SELINUX=enforcing` to `SELINUX=permissive`.
Enable fail2ban on boot, `systemctl enable --now fail2ban.service`
