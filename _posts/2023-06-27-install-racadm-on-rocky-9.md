---
title: 'Install RACADM on Rocky 9'
date: '2023-05-17T10:00:00-04:00'
author: MindlessTux
layout: post
Reference_URL:
categories: [Linux]
tags: [linux, idrac]
---
I just recently put some effort into rebuilding my server(s) host os for my VMs.  One of the things I dreaded was loosing racadm just in case I needed it when upgradeing from [CentOS](https://www.centos.org/) 7 to [Rocky LInux](https://rockylinux.org/) 9.  Spent some time going down the wrong rabbit holes among other things.  I ended up stumbling on a [posting/faq(?)](https://www.privex.io/articles/install-idrac-tools-racadm-ubuntu-debian/) to install racadm on ubuntu.  In it held some keys to getting what I want done.

<!--readmore-->

The first thing I needed was what was I really searching for.
"Dell iDRAC Tools for Linux"

Pluggin that into google and I find many hits.  I settled on the [version 11.0.0.0](https://www.dell.com/support/home/en-us/drivers/driversdetails?driverid=dfhk6) no real reason over older versions other than it is the highest version I could find.

I reviewed the install script inside the download and did not see clear it should work with Rocky Linux 9.  But it is a RHEL spin so RHEL9 might work.

So I ended up doing something like this:
```bash
wget 'https://dl.dell.com/FOLDER08952875M/1/Dell-iDRACTools-Web-LX-11.0.0.0-5139_A00.tar.gz'
tar xvf Dell-iDRACTools-Web-LX-11.0.0.0-5139_A00.tar.gz
cd iDRACTools/racadm/
./install_racadm.sh
```

The output was shall we say not inspiring...
```
root@atlas racadm]# ./install_racadm.sh 
./install_racadm.sh: line 168: [: 11000: unary operator expected
./install_racadm.sh: line 172: [: 11000: unary operator expected
./install_racadm.sh: line 175: [: 11000: unary operator expected
sed: can't read /etc/bash.bashrc: No such file or directory
     **********************************************************
     After the install process completes, you may need 
     to logout and then login again to reset the PATH
     variable to access the RACADM CLI utilities

     **********************************************************
[root@atlas racadm]#
```

So I took care of it by hand just in case.
```bash
cd RHEL9/x86_64/
rpm -i srvadmin-*.rpm
```

At that point I fired up a new bash shell and racadm was in the path and seemingly functional.

```
[root@atlas racadm]# racadm getniccfg

IPv4 settings:
NIC Enabled          = 1
IPv4 Enabled         = 0
DHCP Enabled         = 1

.....and on.....
```
