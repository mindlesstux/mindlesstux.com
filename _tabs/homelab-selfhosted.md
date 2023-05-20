---
# the default layout is 'page'
icon: fas fa-flask
order: 700
title: HomeLab & SelfHosted
---

I run a various set of things both in my homelab and as self hosted services.  Stuff in the homelab is ment for me to learn from or experiment with.  The self hosted services often ride on top of the homelab and are presented to my network.

# Home Lab

Currently my homelab consits of 3 "sites".  At home and at Dacentec I have a Dell R420 setup and running multiple VMs each.  I also have a couple VMs at [Vultr](https://www.vultr.com/?ref=6912630) for vpn endpoint/rdns for email.  All sites run a pair of wireguard tunnels going to the other sites.  Each site-to-site is setup with wireguard tunnels running over IPv4 and IPv6 transit.  This is due to routing isseus that occured using IPv4 or IPv6 at one time or another that managed to keep my network functional far longer.  On top of those links OSPF and OSPFv3 are being run to route the various networks IPv4 and IPv6 networks around.


# Self Hosted

In the various homelab environments I run bits of software (and servers) that I found useful in some way.  
## Network Monitoring

- [LibreNMS](https://librenms.mindlesstux.com)
- [SmokePing](https://smokeping.mindlesstux.com)
- [Uptime Kuma](https://status.mindlesstux.com)

## Media
- DizqueTV
- [Plex](https://plex.mindlesstux.com)
- JellyFin
- [Lidarr](https://lidarr.mindlesstux.com)[^1]
- [Ombi](https://ombi.mindlesstux.com)
- PiHole
- [PodGrab](https://podgrab.mindlesstux.com) [^1]
- [Prowlarr](https://prowlarr.mindlesstux.com) [^1]
- [Radarr](https://radarr.mindlesstux.com/) [^1]
- [Readarr](https://readarr.mindlesstux.com/) [^1]
- [Sonarr](https://sonarr.mindlesstux.com/) [^1]

## Services
- [FreshRSS](https://freshrss.mindlesstux.com)
- Guacamole
- Hastebin
- [Home Assistant](https://home-assistant.mindlesstux.com)
- Mailcow

---
[^1]: Restricted by [CloudFlare ZeroTrust](https://www.cloudflare.com/products/zero-trust/)