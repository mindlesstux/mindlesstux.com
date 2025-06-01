---
title: 'Altering Proxmox Quorum Votes'
date: '2025-05-31 21:30:01 -0400'
last_modified_at: '2025-05-31 21:30:01 -0400'
author: MindlessTux
layout: post
Reference_URL:
categories: [Proxmox]
tags: [proxmox, corosync, homelab]
---

Recently, I converted my Rocky Linux 9 servers, which I had set up QEMU/Libvirt to run my VMs, to Proxmox. Why? That's another post. This one concerns me adjusting the quorum votes a node gets in a cluster.

<!--readmore-->

Why do I need to adjust the votes?  I have an oddball setup in my homelab that would not typically be seen in a production environment.  In the homelab is a single Dell R420.  I also have a VM on my desktop inside of Virtual Box.  Both of these are set up in a cluster.  I would not have the VM running on the desktop in a typical operation.   Its only job is to let me move the VMs to "somewhere" if there is a problem or about to be one—also clustering. 

The problem this causes is that for Proxmox to start any VM in a cluster or allow configuration changes, it has to have a quorum. Unfortunately, that is 51% or better. By default, every node in the cluster gets a single vote. If the server rebooted, it would come up to a 50% quorum, not enough votes. Thankfully, getting around this is easy, but it is not recommended for anyone unless you have a random setup like this.

The howto:
As root
```
systemctl stop pve-cluster.service
pmxcvs -l
nano /etc/pve/corosync.conf
```

In the nodelist section, edit the node you want to have more votes to include
 quorum_votes: 3

Then, in the totem section, update the config_version by one number.

Save and close.

```
killall pmxcfs
systemctl start pve-cluster.service
```

Reboot the node and check `pvecm status` to ensure votequorum show proper expected votes and quorum numbers.