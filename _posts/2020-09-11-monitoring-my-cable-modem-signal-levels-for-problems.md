---
title: 'Monitoring my cable modem signal levels for problems'
date: '2020-09-11T20:33:51-04:00'
last_modified_at: '2020-09-11T20:33:51-04:00'
author: MindlessTux
layout: post
series:
    - 'Cable Modem Stats Graphing'
categories: [Monitoring, Grafana]
tags: [docker, grafana, nodered]
---

![Screenshot of grafana showing modem stats for past 7 days (2020/09/11)](/assets/uploads/2020/09/2020-09-11_09-11.png){: width="300" height="177" .w-50 .right}
Recently I got the itch to learn something new and I chose to explore Grafana. Of course, I needed something to graph or make a dashboard out of. So I pondered for a while and during that time I had some trouble with my internet connection. This of course had me looking at my cable modem stats page and that’s where I found my inspiration. So many numbers that are a point in time snapshot that I wished I had a historical graph of. So I set about figuring out how to install Grafana in docker and pull the data in. I quickly found that grafana is a display thing and not a collector and display. This meant that I had to collect the data and store it so that grafana could display it. For this, I figured I could store it in MariaDB, as using that in grafana looked simple enough. The problem I had was getting the data off of the modems stats page. I plinked around with a bash script and a python script, neither did that great for me. About this time I remembered that nodered has some power to it and tried that. I managed to pull the data and store it into MariaDB via nodered. I then managed to display the data via grafana and was rather satisfied with myself.

<!--readmore-->

I have written instructions on how to do this for an SB6183, it might work on an SB6190 with a bit of editing to support the extra channels in grafana. Any other modem you will have to figure out the HTML and how to slice it up and make possibly major changes to the NodeRED flow and possibly the database.

#### Install Docker

To install Docker, follow the [appropriate section on the dockers website](https://docs.docker.com/get-docker/). I use docker containers of nodered and grafana. You could possibly setup MariaDB too that way but I find a non-docker install of that is best. I know at least one person I know will try to do all of this on a platform such as a Synology, it may work but I won’t know how to help. (You know who you are. :), [here ya go I think I figured it out.](https://mindlesstux.com/2020/09/15/follow-up-docker-synology/))

#### Install MariaDB

Next is to set up the database for use. As I use CentOS for most of my linux systems:

```shell
sudo yum install mariadb-server mariadb-client
```

Next up some basic create database and user stuff for mariadb.

```shell
mysql -u root -p
MariaDB [(none)]> CREATE DATABASE nodered
MariaDB [(none)]> CREATE USER 'nodered'@'%' IDENTIFIED BY 'nodered';
MariaDB [(none)]> GRANT ALL PRIVILEGES ON 'nodered'.* TO 'nodered'@'%';
MariaDB [(none)]> FLUSH PRIVILEGES;
```

The next thing needed is the tables in which the data will be stored. These by no means are an optimal design, but it works.

```sql
--
-- Table structure for table `cable_modem_downstream`
--

DROP TABLE IF EXISTS `cable_modem_downstream`;

CREATE TABLE `cable_modem_downstream` (
`timestamp` int(11) DEFAULT NULL,
`channel` int(11) NOT NULL,
`channelid` int(11) NOT NULL,
`lockstatus` varchar(32) NOT NULL,
`modulation` varchar(16) NOT NULL,
`frequency` int(11) NOT NULL,
`power` float NOT NULL,
`snr` float NOT NULL,
`corrected` int(11) NOT NULL,
`uncorrectables` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Table structure for table `cable_modem_upstream`
--

DROP TABLE IF EXISTS `cable_modem_upstream`;

CREATE TABLE `cable_modem_upstream` (
`timestamp` int(11) DEFAULT NULL,
`channel` int(11) NOT NULL,
`channelid` int(11) NOT NULL,
`lockstatus` varchar(32) NOT NULL,
`channeltype` varchar(16) NOT NULL,
`symbolrate` int(11) NOT NULL,
`frequency` int(11) NOT NULL,
`power` float NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
```

#### Install NodeRED

I store most of my docker related things in a directory called docker-store. I also then have a per container folder under that. So to get the nodered docker container up and running:

```shell
sudo mkdir -p /docker-store/nodered/data
sudo chmod 777 -R /docker-store/nodered/
```

Edit `/docker-store/nodered/docker-compose.yml`{: .filepath}

```yaml
services:
  node-red:
    container_name: node-red
    image: nodered/node-red:latest
    environment:
      - TZ=American/New_York
    ports:
      - "1880:1880"
    volumes:
      - /docker-store/nodered/data:/data
    restart: always
```

I then did a “docker-compose up -d” to start the container. I then gave it a couple of minutes and then pointed my browser at http://ip\_address\_of\_docker\_server:1880/.

##### Configuring NodeRED

Once in the GUI there is one plugin needed, node-red-node-mysql. 3 bars/hamburger menu top right -&gt; Manage Pallete -&gt; Install -&gt; search for node-red-node-mysql -&gt; Install

Once that is done import the following by: 3 bars/hamburger menu top right -&gt; Import -&gt; Paste in the below code -&gt; Set import to new flow -&gt; Import

```json
[ { "id": "91a0acfd.f9bd5", "type": "tab", "label": "Arris SB6183 Cable Modem Status", "disabled": false, "info": "" }, { "id": "58d5cd01.3b2fe4", "type": "inject", "z": "91a0acfd.f9bd5", "name": "", "topic": "", "payload": "", "payloadType": "date", "repeat": "300", "crontab": "", "once": true, "onceDelay": "5", "x": 150, "y": 60, "wires": [ [ "a9a3eee0.1350f8", "f18564d3.35a6f" ] ] }, { "id": "e4a8aeda.effca", "type": "http request", "z": "91a0acfd.f9bd5", "name": "SB6183", "method": "GET", "ret": "txt", "paytoqs": false, "url": "http://192.168.100.1/", "tls": "", "persist": false, "proxy": "", "authType": "", "x": 560, "y": 60, "wires": [ [ "341a7dc4.956e8a" ] ] }, { "id": "1f35ba.2b71e247", "type": "debug", "z": "91a0acfd.f9bd5", "name": "SB6183 Troubleshoot", "active": false, "tosidebar": true, "console": false, "tostatus": false, "complete": "true", "targetType": "full", "x": 380, "y": 120, "wires": [] }, { "id": "951e1362.4675b", "type": "html", "z": "91a0acfd.f9bd5", "name": "", "property": "payload", "outproperty": "payload", "tag": "table", "ret": "html", "as": "multi", "x": 190, "y": 120, "wires": [ [ "1f35ba.2b71e247", "4a61f2e3.755a64" ] ] }, { "id": "a9a3eee0.1350f8", "type": "function", "z": "91a0acfd.f9bd5", "name": "Set User Agent String", "func": "msg.timestamp = msg.payload;\nmsg.headers = {};\n//msg.headers['user-agent'] = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/76.0.3809.100 Safari/537.36';\nmsg.headers['user-agent'] = 'NodeRed/1.0.6';\nreturn msg;", "outputs": 1, "noerr": 0, "x": 380, "y": 60, "wires": [ [ "e4a8aeda.effca" ] ] }, { "id": "96c7501a.832908", "type": "html", "z": "91a0acfd.f9bd5", "name": "", "property": "payload", "outproperty": "payload", "tag": "tr", "ret": "html", "as": "multi", "x": 530, "y": 160, "wires": [ [ "975b9197.3dd9e8" ] ] }, { "id": "4a61f2e3.755a64", "type": "switch", "z": "91a0acfd.f9bd5", "name": "Up or Down", "property": "payload", "propertyType": "msg", "rules": [ { "t": "cont", "v": "Downstream Bonded", "vt": "str" }, { "t": "cont", "v": "Upstream Bonded", "vt": "str" } ], "checkall": "true", "repair": false, "outputs": 2, "x": 210, "y": 160, "wires": [ [ "a1379300.d70068" ], [ "cc5156d.09bb728" ] ] }, { "id": "26e5b79f.7efad8", "type": "switch", "z": "91a0acfd.f9bd5", "name": "Data Only", "property": "payload", "propertyType": "msg", "rules": [ { "t": "cont", "v": "th", "vt": "str" }, { "t": "cont", "v": "Modulation", "vt": "str" }, { "t": "cont", "v": "US Channel Type", "vt": "str" }, { "t": "else" } ], "checkall": "false", "repair": false, "outputs": 4, "x": 120, "y": 260, "wires": [ [], [], [], [ "c9a1a9b4.e9d81" ] ] }, { "id": "c9a1a9b4.e9d81", "type": "html", "z": "91a0acfd.f9bd5", "name": "", "property": "payload", "outproperty": "payload", "tag": "td", "ret": "html", "as": "single", "x": 330, "y": 260, "wires": [ [ "4c8437fa.b0dd88", "6a3f56c1.0836d8" ] ] }, { "id": "6a3f56c1.0836d8", "type": "debug", "z": "91a0acfd.f9bd5", "name": "TDs", "active": false, "tosidebar": true, "console": false, "tostatus": false, "complete": "true", "targetType": "full", "x": 330, "y": 300, "wires": [] }, { "id": "a1379300.d70068", "type": "change", "z": "91a0acfd.f9bd5", "name": "Set Down", "rules": [ { "t": "set", "p": "direction", "pt": "msg", "to": "downstream", "tot": "str" } ], "action": "", "property": "", "from": "", "to": "", "reg": false, "x": 380, "y": 160, "wires": [ [ "96c7501a.832908" ] ] }, { "id": "cc5156d.09bb728", "type": "change", "z": "91a0acfd.f9bd5", "name": "Set Up", "rules": [ { "t": "set", "p": "direction", "pt": "msg", "to": "upstream", "tot": "str" } ], "action": "", "property": "", "from": "", "to": "", "reg": false, "x": 370, "y": 200, "wires": [ [ "96c7501a.832908" ] ] }, { "id": "4c8437fa.b0dd88", "type": "function", "z": "91a0acfd.f9bd5", "name": "SQL Load", "func": "cm_timestamp = msg.timestamp;\ncm_timestamp = (cm_timestamp-(cm_timestamp%1000))/1000;\n\nif (msg.direction == \"downstream\") {\n cm_channel = msg.payload[0];\n cm_lockstatus = msg.payload[1];\n cm_modulation = msg.payload[2];\n cm_channelid = msg.payload[3];\n // Remove the \" Hz\"\n cm_frequency = msg.payload[4];\n cm_frequency = cm_frequency.substring(0, cm_frequency.length-3);\n // Remove the \" dBmV\"\n cm_power = msg.payload[5];\n cm_power = cm_power.substring(0, cm_power.length-4);\n // Remove the \"dB\"\n cm_snr = msg.payload[6];\n cm_snr = cm_snr.substring(0, cm_snr.length-3);\n cm_corrected = msg.payload[7];\n cm_uncorrectables = msg.payload[8];\n \n sql = \"INSERT INTO cable_modem_downstream (timestamp,channel,channelid,lockstatus,modulation,frequency,power,snr,corrected,uncorrectables) VALUES(\" + cm_timestamp + \", \" + cm_channel + \", \" + cm_channelid + \", '\" + cm_lockstatus + \"', '\" + cm_modulation + \"', \" + cm_frequency + \", \" + cm_power + \", \" + cm_snr + \", \" + cm_corrected + \", \" + cm_uncorrectables + \");\";\n} else if (msg.direction == \"upstream\") {\n cm_channel = msg.payload[0];\n cm_lockstatus = msg.payload[1];\n cm_channeltype = msg.payload[2];\n cm_channelid = msg.payload[3];\n cm_symbolrate = msg.payload[4];\n cm_symbolrate = cm_symbolrate.substring(0, cm_symbolrate.length-9);\n cm_frequency = msg.payload[5];\n cm_frequency = cm_frequency.substring(0, cm_frequency.length-3);\n cm_power = msg.payload[6];\n cm_power = cm_power.substring(0, cm_power.length-5);\n sql = \"INSERT INTO cable_modem_upstream (timestamp,channel,channelid,lockstatus,channeltype,symbolrate,frequency,power) VALUES(\" + cm_timestamp + \", \" + cm_channel + \", \" + cm_channelid + \", '\" + cm_lockstatus + \"', '\" + cm_channeltype + \"', \" + cm_symbolrate + \", \" + cm_frequency + \", \" + cm_power + \");\"\n} else {\n sql = \"SELECT NOW()\";\n}\n\nmsg = {};\nmsg.topic = sql;\n\nreturn msg;", "outputs": 1, "noerr": 0, "x": 500, "y": 260, "wires": [ [ "18706122.d4ebd7", "5d713bf7.61b4dc" ] ] }, { "id": "18706122.d4ebd7", "type": "debug", "z": "91a0acfd.f9bd5", "name": "SQL", "active": false, "tosidebar": true, "console": false, "tostatus": false, "complete": "true", "targetType": "full", "x": 490, "y": 300, "wires": [] }, { "id": "5d713bf7.61b4dc", "type": "mysql", "z": "91a0acfd.f9bd5", "mydb": "92719932.2d2678", "name": "", "x": 660, "y": 260, "wires": [ [] ] }, { "id": "946f4f02.648888", "type": "http request", "z": "91a0acfd.f9bd5", "name": "HealthChecks.io", "method": "GET", "ret": "txt", "paytoqs": false, "url": "https://hc-ping.com/00000000-0000-0000-0000-000000000000/start", "tls": "", "persist": false, "proxy": "", "authType": "", "x": 160, "y": 460, "wires": [ [] ] }, { "id": "de603e32.796718", "type": "link in", "z": "91a0acfd.f9bd5", "name": "", "links": [ "975b9197.3dd9e8" ], "x": 35, "y": 260, "wires": [ [ "26e5b79f.7efad8" ] ] }, { "id": "975b9197.3dd9e8", "type": "link out", "z": "91a0acfd.f9bd5", "name": "", "links": [ "de603e32.796718" ], "x": 615, "y": 160, "wires": [] }, { "id": "2398ad65.bcb4ba", "type": "function", "z": "91a0acfd.f9bd5", "name": "Set User Agent String", "func": "msg.timestamp = msg.payload;\nmsg.payload = {};\nmsg.headers = {};\n//msg.headers['user-agent'] = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/76.0.3809.100 Safari/537.36';\nmsg.headers['user-agent'] = 'NodeRed/1.0.6';\nreturn msg;", "outputs": 1, "noerr": 0, "x": 180, "y": 420, "wires": [ [ "946f4f02.648888" ] ] }, { "id": "402d2d61.6e91cc", "type": "http request", "z": "91a0acfd.f9bd5", "name": "HealthChecks.io", "method": "GET", "ret": "txt", "paytoqs": false, "url": "https://hc-ping.com/00000000-0000-0000-0000-000000000000", "tls": "", "persist": false, "proxy": "", "authType": "", "x": 500, "y": 460, "wires": [ [] ] }, { "id": "edd848fb.bcd128", "type": "function", "z": "91a0acfd.f9bd5", "name": "Set User Agent String", "func": "msg.timestamp = msg.payload;\nmsg.payload = {};\nmsg.headers = {};\n//msg.headers['user-agent'] = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/76.0.3809.100 Safari/537.36';\nmsg.headers['user-agent'] = 'NodeRed/1.0.6';\nreturn msg;", "outputs": 1, "noerr": 0, "x": 520, "y": 420, "wires": [ [ "402d2d61.6e91cc" ] ] }, { "id": "1c81fa85.00658d", "type": "link in", "z": "91a0acfd.f9bd5", "name": "", "links": [ "f18564d3.35a6f" ], "x": 55, "y": 420, "wires": [ [ "2398ad65.bcb4ba" ] ] }, { "id": "d1ed0e2a.ddaff", "type": "link in", "z": "91a0acfd.f9bd5", "name": "", "links": [ "341a7dc4.956e8a" ], "x": 395, "y": 420, "wires": [ [ "edd848fb.bcd128" ] ] }, { "id": "f18564d3.35a6f", "type": "link out", "z": "91a0acfd.f9bd5", "name": "", "links": [ "1c81fa85.00658d" ], "x": 255, "y": 40, "wires": [] }, { "id": "341a7dc4.956e8a", "type": "link out", "z": "91a0acfd.f9bd5", "name": "", "links": [ "d1ed0e2a.ddaff", "e0ff726f.21083" ], "x": 655, "y": 60, "wires": [] }, { "id": "cccbd4db.cca3", "type": "link in", "z": "91a0acfd.f9bd5", "name": "", "links": [], "x": -20, "y": 160, "wires": [ [] ] }, { "id": "e0ff726f.21083", "type": "link in", "z": "91a0acfd.f9bd5", "name": "", "links": [ "341a7dc4.956e8a" ], "x": 95, "y": 120, "wires": [ [ "951e1362.4675b" ] ] }, { "id": "149aa1a5.acf8e6", "type": "comment", "z": "91a0acfd.f9bd5", "name": "HealthChecks.io Start", "info": "", "x": 180, "y": 380, "wires": [] }, { "id": "dd7db74.41c6cc8", "type": "comment", "z": "91a0acfd.f9bd5", "name": "HealthChecks.io Stop", "info": "", "x": 520, "y": 380, "wires": [] }, { "id": "92719932.2d2678", "type": "MySQLdatabase", "z": "", "host": "127.0.0.1", "port": "3306", "db": "nodered", "tz": "" } ]
```

![](https://mindlesstux.com/wp-content/uploads/2020/09/2020-09-11_15-53.png){: width="300" height="189" .w-50 .right}
The code is also available here in a more readable view: [sb6183\_nodered\_grafana.json](/assets/uploads/2020/09/sb6183_nodered_grafana.json_.txt)

If things go well it should come out looking something like what is off to the right. If you don’t use [healthchecks.io](https://healthchecks.io/) then you don’t need the bottom 8 nodes, just highlight and delete. I have them set up for myself to alert me to either home ISP is down or to if the nodered flow has crashed somehow.

The only things you would have to edit are the following:

- SB6183 (top right) 
    - Make sure this has your modems IP in it, should be rather universal but just in case
- nodered (middle right) 
    - Update the MariaDB settings so that they are correct
- 2x Heathchecks.io (bottom left and right) 
    - Update the UUID they provide be the check you set up for yourself.

Once your edits have been made, don’t forget to deploy your new flow! At this point, every five minutes a new set of data points should be entered into the database.

#### Install Grafana

Now on to the last part of the whole thing, Grafana. Like nodered, I run it in docker and set it up similarly.

```shell
sudo mkdir -p /docker-store/grafana/{data,logs,plugins,provisioning}
sudo touch /docker-store/grafana/grafana.ini
sudo chmod 777 -R /docker-store/grafana/
```

Create/Edit: `/docker-store/grafana/docker-compose.yml`{: .filepath}

```yaml
version: "3"
services:
  grafana:
    image: grafana/grafana:latest
    container_name: grafana
    ports:
    volumes:
      - /docker-store/grafana/grafana.ini:/etc/grafana/grafana.ini
      - /docker-store/grafana/data:/var/lib/grafana
      # - /docker-store/grafana/plugins:/var/lib/grafana/plugins
      - /docker-store/grafana/logs:/var/log/grafana
      # - /docker-store/grafana/provisioning:/etc/grafana/provisioning
    ports:
      - 3000:3000
    restart: unless-stopped
```

I then did a “docker-compose up -d” to start the container. I then gave it a couple of minutes and then pointed my browser at http://ip\_address\_of\_docker\_server:3000/. Default user/pass is admin/admin. I suggest making a new user with admin privileges that are not defaults.

##### Configuring Grafana

Once I was in, I setup the MariaDB data source, Gear icon left side -&gt; Data sources -&gt; Add data source -&gt; Select mysql -&gt; fill in blanks for ip:port, user/pass, etc… -&gt; save and test.

At this point, I was finally ready to build myself a new dashboard based on the data that was being collected. It was as simple as plus symbol on left and picking dashboard. From there I started with the first panel, the upstream stats. I mashed that “Add new panel” button and off I went.

On the new screen that appeared, I made sure to select the new mysql data source just below the query tab. From there I started just clicking around and found that it was kind of a GUI SQL builder. I set the table as cable\_modem\_upstream, chose the power column, gave it an alias of Channel 1, and then set the expression of channel = 1. I hit the copy button three times and change the Channel 1 to a Channel 2, etc, and the channel = 1 to channel = 2, etc. I gave the panel a title and hit save then apply. My first panel and it looked wonderful.

![](/assets/uploads/2020/09/2020-09-11_16-55.png){: width="300" height="90" .w-50 .right}
To save you time at recreating my dashboard as there is a lot of channels when it comes to downstream I have made an export of the JSON for the dashboard. On the left Dashboard (looks like 4 boxes in 2×2) and manage. Next click the blue import. Copy the [contents of this (sb6183\_nodered\_grafana\_2.json)](/assets/uploads/2020/09/sb6183_nodered_grafana_2.json_.txt) to “Import via panal json” text editor there and load. You may have to edit the data source on each of the 6 panels.

Now sit back and let time pass and you will soon have hopefully a pretty graph of your modems connection stats. Or you will see the ugly truth of how bad your connection is. The third option is I screwed up my steps and you will have a mess on your hands. If option 3 is the case, if you figure it out and know I missed something let me know so I can edit this post!

**\*EDIT 2020-09-15 17:00 ET:** Updated jab to a co-worker about Synology with a coming soon followup. After Grafana install steps tweaked to be proper flow. Grafana import process fails the way I wrote it, re-written with the method that does work.

**\*EDIT 2020-09-15 21:25 ET:** Updated post to be part of a series. Made post about how to get the containers running on a Synology NAS.