---
title: 'Switching from Wordpress to Jekyll'
date: '2023-02-12T20:00:00-04:00'
last_modified_at: '2023-02-12T20:00:00-04:00'
author: MindlessTux
layout: post
#Reference_URL:
#    - ''
categories: [Jekyll]
tags: [jekyll, wordpress]
---

So my constant need/want to find the perfect means to managing my website has driven me from [WordPress](https://wordpress.org/) over to [Jeykll](https://jekyllrb.com/).  Why am I doing this jump?  There are a few reasons that I am doing this.

<!--readmore-->

The first and major reason is I am moving from self hosting the content to having it hosted by someone else.  In this case I am making use of [CloudFlare Pages](https://pages.cloudflare.com/) to host static pages.  That would be reason two, static pages.  I dont really change my pages a whole lote so the CPU time is wasted by wordpress on a page load.  This allows me to push the caching of the page as far out as I can.  The third reason is instead of managing what basically comes to a database with a web frontent wrapper, I wanted something a little more "tangiable".  So by going with Jekyll I am able to write pages in markdown, store them in github and have Jekyll build pages with deployment on CloudFlare Pages.