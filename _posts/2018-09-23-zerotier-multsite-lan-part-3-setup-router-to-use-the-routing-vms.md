---
title: 'Part 3: Setup router to use the routing VM(s)'
date: '2018-09-23T22:04:29-04:00'
lastmod: '2018-09-23T22:04:29-04:00'
author: MindlessTux
layout: post
series:
    - 'ZeroTier + Multisite LAN'
categories: [ZeroTier]
tags: [zerotier, tutorial]    
---

With the VM building out of the way, on to configuring the VMs.

<!--readmore-->

First a little more software install/prep work

```
yum install quagga
systemctl enable zebra
systemctl enable ospfd
systemctl disable firewalld
cp /usr/share/doc/quagga-*/zebra.conf.sample /etc/quagga/zebra.conf
cp /usr/share/doc/quagga-*/ospfd.conf.sample /etc/quagga/ospfd.conf
chown quagga.quagga /etc/quagga/*.conf
setsebool -P zebra_write_config 1
systemctl start zebra
systemctl start ospfd
systemctl stop firewalld
vtysh
```

Basically, install quagga, a routing daemon that works similar to cisco ios. From there enabling the two services we need for ipv4 connectivity. Zebra is the main quagga daemon, the ospfd is the daemon to run this as an OSPF router. There is an ospf6d daemon that I have yet to mess with to route the fd00::/8 ipv6 network.  
In the process of setting this up, I found the default firewall is pointless and causes problems with the routing daemons unless you open the right ports and subnets. I chose to disable the firewall as these VMs are not directly exposed to the internet and are behind firewalls already.  
The last two odd commands that may not be familiar:  
The setsebool, allows the quagga daemon to modify the /etc/quaga/\*.conf files.  
The vtysh, this is how you get into the quagga software. Thus into the next bit.

```
routervm-site1# conf t
routervm-site1(config)# int eth0
routervm-site1(config-if)# ip address 10.10.9.2/29
routervm-site1(config-if)# ip ospf authentication message-digest
routervm-site1(config-if)# ip ospf message-digest-key 1 md5 quagga
routervm-site1(config-if)# exit
routervm-site1(config)# int zt-interfacename
routervm-site1(config-if)# ip address 10.10.10.251/24
routervm-site1(config-if)# ip ospf authentication message-digest
routervm-site1(config-if)# ip ospf message-digest-key 1 md5 quagga
routervm-site1(config-if)# exit
routervm-site1(config)# router ospf
routervm-site1(config-router)# ospf router-id 10.10.10.251
routervm-site1(config-router)# network 10.10.10.251/24 area 0.0.0.0
routervm-site1(config-router)# network 10.10.9.2/29 area 0.0.0.1
routervm-site1(config-router)# area 0.0.0.0 authentication message-digest
routervm-site1(config-router)# neighbor 10.10.10.252
routervm-site1(config-router)# neighbor 10.10.10.253
routervm-site1(config-router)# exit
routervm-site1(config)# ip forwarding
routervm-site1(config)# ipv6 forwarding
routervm-site1(config)# exit
routervm-site1# write
```

To sum this up:

- - Enter configuration terminal
    - interface eth0, (may need to change this to match, silly eno2345 names now days are possible.
    - Configure the IP address
    - Setup MD5 authentication and defines the key “quagga”
    - Drops back to config terminal, and then into the ZeroTier interface
    - A repeat of the eth0 interface, just different IP
    - Drops back to config terminal, and into the OSPF routing bit
    - Defines the [OSPF router ID](http://www.omnisecu.com/cisco-certified-network-associate-ccna/what-is-ospf-router-id-and-how-to-configure-ospf-router-id.php), I chose the ZeroTier IP.
    - Defines the networks OSPF is to run on and in what area 
        - I went with the backbone area, as I don’t really want to get to complex
    - Defines the area to use MD5 authentication
    - Defines the OSPF neighbors, 
        - In this case the other two VMs in the ZeroTier network.
    - Drops back and sets IP forwarding for IPv4 and IPv6
    - Drops back again and writes configs to disk

At each site where one of these VMs is set up, change the IP address as needed. (network interfaces, neighbors, and router-id)

For this next part, making it work with MikroTik routers. It is rather simple and easy.

```
/routing ospf area
set [ find default=yes ] disabled=yes
/routing ospf instance
set [ find default=yes ] disabled=yes
add name=ospf1 router-id=10.10.9.1
/routing ospf area
add instance=ospf1 name=area0
/routing ospf area range
add area=backbone disabled=yes
/routing ospf interface
add authentication=md5 authentication-key=quagga interface=etherLAN network-type=broadcast
/routing ospf network
add area=area0 network=10.10.10.0/24 comment="REAL LAN"
add area=area0 network=10.10.9.0/29 comment="LAN to RouterOnStick"
```

To summerize:

- disables defaults
- Create a new instance and set router-id
- Create new area
- Create an area range
- Setup authentication on the interface for the LAN
- Configure the networks to use