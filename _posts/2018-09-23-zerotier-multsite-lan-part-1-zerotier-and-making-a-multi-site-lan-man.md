---
title: 'Part 1: ZeroTier and making a multi-site LAN (MAN?)'
date: '2018-09-23T22:00:07-04:00'
last_modified_at: '2018-09-23T22:00:07-04:00'
author: MindlessTux
layout: post
Reference_URL:
    - 'https://zerotier.com'
    - 'https://mikrotik.com'
    - 'https://www.google.com/search?q=router+on+a+stick'
series:
    - 'ZeroTier + Multisite LAN'
categories: [ZeroTier]
tags: [zerotier, tutorial]
---

Recently I have come across an interesting little software tech that lets me do some fun things that normally one would only see in the data center or large companies. That software is called [ZeroTier](https://zerotier.com/).

<!--readmore-->

When I first started playing with this I was doing some really bad things abusing networks to get a nice simple method to access all my remote servers and devices without hassle. Let’s just say all of what I did was horrible and was burned to the ground in favor of this. My goal was to set up a small network that would span 3 LANs and allow me to connect them together either in a routed or one big bridge. I do not recommend the bridge but it can be done.

So the first step I took was to draw out what the network should look like. Then I took a little time and thought about it and had to modify it a little more.

| <div class="wp-caption aligncenter" id="attachment_420" style="width: 310px">![](https://mindlesstux.com/wp-content/uploads/2018/09/Part1-HandDrawImage-300x225.png)Rough hand drawn what I wanted it to look like.  </div> | <div class="wp-caption aligncenter" id="attachment_425" style="width: 310px">![](https://mindlesstux.com/wp-content/uploads/2018/09/Part1-HandDrawImage2-300x225.png)After a little thinking.  </div> |
|:-:|:-:|

In the picture on the left, I identified I would need to use 4 subnets, 3 for the LANs and one for the inter LAN routing. I then saw a flaw with this initial diagram, how do I route to ZeroTier? My routers of choice are [MikroTik](https://mikrotik.com/), there is no built-in ZeroTier package for them. It is then I thought of doing a router on a stick at each site to handle doing the handoff to ZeroTier. Granted I drew a device with traffic routing through it; not to and from it on the same interface. This will take you to I need more subnets. So finally I had what needed to complete this task. 3 LAN subnets, 3 point to point subnets, and 1 ZeroTier subnet.

Now, why did I want to go this way? Sure one could set up an IPsec tunnel or any various other VPN tunnels and send traffic over them. This software offered the opportunity to let me make a MAN like network across the internet that is very little configuration and almost zero NAT hole punching. At work, I have seen what happens when VPNs suddenly die and it is due to someone/something doing something bad.

- - - - - -

Terms people may not know:

[Router-on-a-stick](https://www.google.com/search?q=router+on+a+stick) – A router that only has one ethernet port and typically is routing between two or more networks over that one ethernet cable.

- - - - - -

The to long and did not want to read:

3 different LAN networks, to be connected/routed across ZeroTier and have a routing daemon take care of routes as they come/go due to network issues.