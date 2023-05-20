---
title: 'Setup your own DNS over TLS'
date: '2018-12-07T19:37:46-05:00'
author: MindlessTux
layout: post
Reference_URL:
    - 'https://kb.isc.org/docs/aa-01386'
    - 'https://en.wikipedia.org/wiki/DNS_over_TLS'
    - 'https://android-developers.googleblog.com/2018/04/dns-over-tls-support-in-android-p.html'
categories: [DNS, DoT]
tags: [dns, dot, tutorial]
---

So I have gone a little crazy lately in my home lab. I have created a [anycast](https://en.wikipedia.org/wiki/Anycast) address in the LAN of 10.10.10.10 that goes to the nearest pihole. (Local, Datacetner 1 or Datacenter 2) While that was nice I still wanted a way to have pihole while on the go. I thought about a VPN, that works but is not perfect for what I want. A little more pondering and I found that [Android 9 supports “Private DNS”](https://android-developers.googleblog.com/2018/04/dns-over-tls-support-in-android-p.html). Turns out that it is a simply [DNS over TLS. (DoT)](https://en.wikipedia.org/wiki/DNS_over_TLS) That just makes this so much easier now.

<!--readmore-->

How does one make a DoT server then? Again answer is really simple, stunnel4 is all you need. [A quick bit of googling](http://lmgtfy.com/?q=dns+over+tls+stunnel) will get you to [this page](https://kb.isc.org/docs/aa-01386), which will walk through a more indepth setup of stunnel4. Boiled down, and assuming you have a SSL cert handy/installed on the system:

```
# yum install stunnel4

# cat /etc/stunnel/dnstls.conf
[dnstls]
cert = /etc/letsencrypt/live/mindlesstux.com/fullchain.pem
key = /etc/letsencrypt/live/mindlesstux.com/privkey.pem

accept = 853
connect = 10.10.10.10:53


# systemctl enable stunnel4
# systemctl start stunnel4
```

After that, it was a matter of punching a hole in the firewall to allow 853 in to the server running the stunnel4 daemon. Once that was up I added a DNS record for exampledot.mindlesstux.com to the ip where the firewall hole was punched. Finally in my android Settings -&gt; Network &amp; Internet -&gt; Advanced -&gt; Private DNS. I set that to “Private DNS provider hostname” and put the mentioned hostname in the text field. Bam, now anywhere I go my phone is covered by one of my piholes.

Now to look into providing [DNS over HTTPS (DOH)](https://en.wikipedia.org/wiki/DNS_over_HTTPS) the same way…