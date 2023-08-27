---
title: 'Reducing swap partition on lvm on ubuntu server'
date: '2018-01-06T02:46:48-05:00'
lastmod: '2018-01-06T02:46:48-05:00'
author: MindlessTux
layout: post
Reference_URL:
    - 'https://askubuntu.com/questions/226520/how-to-modify-size-of-swap-with-a-lvm-partition'
    - 'https://askubuntu.com/a/303723'
categories: [Linux, LVM]
tags: [ubuntu, "ubuntu server", lvm, linux]
---

So the server I have hosted at Dacentec is starting to show its age and limitations. Luckily I can get my hands on some decent hardware thanks to ebay and other methods. So the past few days when time allows I have been working on building a replacement 1u server to what I currently have. In doing so I am taking the RAM from 16GB to 196GB. With that said the system is installed with a stock ubuntu 17.10 server using guided lvm partitioning. Which thinks like days of old where total ram equals the swap size needed.

<!--readmore-->

Avoiding the whole debate of how much swap would be ideal. I am just going to scale it back to about 16GB. Thus freeing up about 80% of the OS RAID 1 drives.

As always google and a stackoverflow/askubuntu (Ref links below) along with some good old fashion thinking.

```terminal
root@atlas:~# lvs
  LV     VG       Attr       LSize   Pool Origin Data%  Meta%  Move Log Cpy%Sync Convert
  root   atlas-vg -wi-ao----  86.88g                                                    
  swap_1 atlas-vg -wi-ao---- 191.95g                                                    

root@atlas:~# swapoff /dev/atlas-vg/swap_1

root@atlas:~# lvreduce --size 16G /dev/atlas-vg/swap_1
  WARNING: Reducing active logical volume to 16.00 GiB.
  THIS MAY DESTROY YOUR DATA (filesystem etc.)
Do you really want to reduce atlas-vg/swap_1? [y/n]: y
  Size of logical volume atlas-vg/swap_1 changed from 191.95 GiB (49140 extents) to 16.00 GiB (4096 extents).
  Logical volume atlas-vg/swap_1 successfully resized.

root@atlas:~# mkswap /dev/atlas-vg/swap_1
mkswap: /dev/atlas-vg/swap_1: warning: wiping old swap signature.
Setting up swapspace version 1, size = 16 GiB (17179865088 bytes)
no label, UUID=f0260f73-bf13-41d4-af79-3203114b3f9d

root@atlas:~# swapon /dev/atlas-vg/swap_1

root@atlas:~# lvs
  LV     VG       Attr       LSize  Pool Origin Data%  Meta%  Move Log Cpy%Sync Convert
  root   atlas-vg -wi-ao---- 86.88g                                                    
  swap_1 atlas-vg -wi-ao---- 16.00g    

```