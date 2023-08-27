---
title: 'iDRAC 7 &#8211; LetsEncrypt Wildcard Cert'
date: '2018-03-13T23:03:26-04:00'
last_modified_at: '2018-03-13T23:03:26-04:00'
author: MindlessTux
layout: post
Reference_URL:
    - 'https://serverfault.com/questions/485426/install-existing-ssl-certificate-on-dell-idrac7'
    - 'https://lonesysadmin.net/2015/08/13/interesting-dell-idrac-tricks/'
    - 'http://www.itwalkthru.com/2014/01/how-to-install-wildcard-certificate-on.html'
categories: []
tags: [idrac, letsencrypt]
---

So I have a few “hand me down” dell servers. The ones I use right now have iDRAC 7 in them. I have always been annoyed at the SSL warning that comes up. I thought about rolling my own CA and generating my own certs. I shot that down though as some times I pull up the iDRACs remotely from systems where I don’t want to install the custom root cert. I finally took the time to figure out how to take the [Let’s Encrypt](https://letsencrypt.org/) free SSL cert and apply it to the iDRACs. This is mainly due to they [started issuing wildcard certs](https://community.letsencrypt.org/t/acme-v2-and-wildcard-certificate-support-is-live/55579) as of today.

<!--readmore-->

So step one, reissue all my certs into one nice wildcard cert. Took a bit of effort but to make things simple for others that may find this. Install certbot-auto on a linux system and run something like:

```bash
./certbot-auto certonly --rsa-key-size=4096 -d domain.com -d *.domain.com --server https://acme-v02.api.letsencrypt.org/directory --manual
```

Follow the prompts and setup the verification checks as requested. If all goes well you will get a nice little dump of you have a new cert and it lives at /etc/letsencrypt/live/domain.com/.

From there I scp’ed the private key and the full chain down to my windows vm where I have racadm installed. For quick finding [for those that need racadm](http://www.dell.com/support/search/us/en/19#q=racadm&sort=relevancy&f:typeFacet=[Drivers]&f:langFacet=[en]) installed on a windows system. (Download, unzip, run installer, good to go) After that all that was needed is to run 3 commands in a command prompt in the directory where the two files I scp’ed to the system.

```bash
racadm -r idrac1.domain.com -u adminuser -p adminpass sslkeyupload -t 1 -f privkey.pem
racadm -r idrac1.domain.com -u adminuser -p adminpass sslcertupload -t 1 -f fullchain.pem
racadm racreset
```

After the iDRAC reset itself after those commands, I now had a shiny and valid SSL cert. There can be a small hiccup, and you may get a system that says “The Remote RACADM interface is disabled”. As long as you have trust in your firewalls, Overview-&gt;iDRAC Settings-&gt;Network-&gt;Services-&gt;Remote RACADM-&gt;Tick the enabled box and apply.

Next up to see if I can make Java not complain when loading the virtual console. Or perhaps scripting this some how to automatically check daily if new cert was issued and pull/push.