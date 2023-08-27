---
title: 'Setting up a TF2 server &#8211; Part 1'
date: '2018-02-08T20:32:16-05:00'
lastmod: '2018-02-08T20:32:16-05:00'
author: MindlessTux
layout: post
series:
    - 'Setting up a TF2 server'
categories: ["Game Servers", "Team Fortress 2"]
tags: ["game servers", "team fortress 2", tf2, tutorial]
---

So I also host a small set of game servers for me to test plugins and maps out. Not to mention its also a simple way for me to say to a group of friends lets go play this and have a place to go without the hassle of looking for a server. Normally I would tell people to install [LGSM](https://gameservermanagers.com/lgsm/tf2server/) when they want to setup a gameserver. I though have run into a few issues where LGSM is a tad constricting for my needs now. So off to setting the server up from scratch and trying to replicate a couple of features from LGSM.

<!--readmore-->

So for this part, setup the server in a raw form.

Prepare the system as TF2 servers run as 32-bit

```bash
sudo dpkg --add-architecture i386
sudo apt-get update
sudo apt-get install mailutils util-linux byobu tmux lib32gcc1 libstdc++6 libstdc++6:i386 libcurl4-gnutls-dev:i386
```

Always a good idea to run things as a user and not root, so lets add a user and login as it.

```bash
sudo adduser tf2-server
sudo login -f tf2-server
```

Now that we are in the user account lets download the server. First we need to download steamcmd.

```bash
mkdir steamcmd
cd steamcmd
wget http://media.steampowered.com/installer/steamcmd_linux.tar.gz
tar zxf steamcmd_linux.tar.gz
```

Create a steamcmd file and run it.

```bash
cd /home/tf2-server
echo tf2_ds.txt <<EOF
login anonymous
force_install_dir /home/tf2-server/srcds
app_update 232250
quit
EOF
./steamcmd.sh +runscript tf2_ds.txt
```


Now to create a launcher script.

```bash
cd /home/tf2-server/srcds
echo launcher.sh <<EOF
#!/bin/bash
OPTS="-console -debug"
OPTS="$OPTS -game tf +sv_pure 1 -secured -timeout 3"
OPTS="$OPTS +ip 0.0.0.0 -port 27015"
#OPTS="$OPTS +map ctf_2fort"
OPTS="$OPTS +randommap"
OPTS="$OPTS +maxplayers 32"
OPTS="$OPTS -autoupdate -steam_dir /home/tf2-server/srcds/ -steamcmd_script /home/tf2-server/steamcmd/tf2_ds.txt"
OPTS="$OPTS +sv_shutdown_timeout_minutes 40"
./srcds_run $OPTS
EOF
chmod +x launcher.sh
```

At this point it is possible to launch the server.

```bash
./launcher.sh
```