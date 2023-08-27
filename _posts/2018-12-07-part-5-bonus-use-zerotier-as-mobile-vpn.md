---
title: 'Part 5: Bonus!  Use ZeroTier as mobile VPN.'
date: '2018-12-07T22:19:54-05:00'
lastmod: '2018-12-07T22:19:54-05:00'
author: MindlessTux
layout: post
series:
    - 'ZeroTier + Multisite LAN'
categories: [ZeroTier]
tags: [zerotier, tutorial]
---

Here is a bonus post. I am not going to go into deep details but should be enough to give a good idea on how to do this.

<!--readmore-->

First thing I would suggest creating a second zerotier network from the routed LAN for all the mobile devices. I would make sure the IP subnet is different than anything else, so following example, 10.10.0.0/24 for example. Next set the range to .10-250 of the last octet under advanced. The reason for this is we are going to set a bit on the routervms and turn them into nat routers on their own IPs. Also use one of the higher ips (say .254 perhaps?) as floating IP between the VMs. This way when we route, we route to the .254 and if something having problems, just move the .254 to another host and count to 30 and things should work again.

Now what will make this work for the clients. You need to add routes in the zerotier network. You can do two options and I will give comments on each.

1. Add 
    - 0.0.0.0/0 via 10.10.0.254
    - This is the most common most people would use. It is a simple common route to push for default route to send everything. The problem I ran into is not everything can take a default route like this out of the box. So I gamed the system with the next one.
2. Or Add 
    - 0.0.0.0/1 via 10.10.0.254
    - 128.0.0.0/1 via 10.10.0.254
    - The reason this works is we can push two routes and neither is technically default. The reason why this works is that they are more specific. This means these routes would be picked over the default in most cases.

At this point it is time to edit all the routervms to enable nat routing and put the IPs on them.

1. 1. 1. Join the routervms to the new VPN network
        2. Run the following to disable routes pushing to the routervms (that would cause some problems for routing). 
            - ```
                sudo zerotier-cli set <network> allowManaged=false
                sudo zerotier-cli set <network> allowGlobal=false
                sudo zerotier-cli set <network> allowDefault=false
                ```
        3. Edit **/etc/sysctl.conf** and add the following to the bottom 
            - ```
                net.ipv4.ip_forward = 1
                ```
        4. Edit **/etc/sysconfig/iptables**
            - ```
                <pre class="line number1 index0 alt2">*nat
                :PREROUTING ACCEPT [0:0]
                :INPUT ACCEPT [0:0]
                :OUTPUT ACCEPT [0:0]
                :POSTROUTING ACCEPT [0:0]
                -A POSTROUTING -o eth0 -s 10.10.0.0/24 -j SNAT --to-source eth.ip.goes.here
                COMMIT
                *filter
                :INPUT ACCEPT [0:0]
                :FORWARD DROP [0:0]
                -A FORWARD -i zt+ -s 10.10.0.0/24 -d 0.0.0.0/0 -j ACCEPT
                -A FORWARD -i eth0 -s 0.0.0.0/0 -d 10.10.0.0/24 -j ACCEPT
                :OUTPUT ACCEPT [0:0]
                COMMIT
                ```
        5. Now add .1-? to the routervms network configs. So one gets .1 and another gets .2 and so on. This way when they get rebooted they at least show up on the network.
        6. Now add .254 to only one of the routervms via, 
            - ```
                ip addr add 10.10.0.254/24 dev <gobblygook network interface>
                ```

If everything was done right (and I did not skip a step) you should now be able to join a new device and approve it for your network. It should then start sending all its traffic to the designated routervm and hopefully have interent connectivity.

Now the real reason for sending all traffic to the .254 and having it as a secondary ip. I have yet to try to configure this but it should be possible to setup heartbeat or pacemaker to control the .254 address. So that it auto moves for you between the hosts as the fail on the network. Thus ensuring you will always have access across the “VPN”.