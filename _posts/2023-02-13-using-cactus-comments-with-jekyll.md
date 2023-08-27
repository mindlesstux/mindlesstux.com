---
title: 'Using Cactus Comments with Jekyll'
date: '2023-02-13T11:36:00-04:00'
lastmod: '2023-02-13T11:36:00-04:00'
author: MindlessTux
layout: post
Reference_URL:
    - 'https://cactus.chat/'
    - 'https://cactus.chat/docs/integrations/jekyll/'
    - 'https://github.com/mindlesstux/mindlesstux.github.io/blob/master/_includes/comments/cactus.html'
categories: [Jekyll]
tags: [comments, jekyll]
---

With my switching to using Jekyll and wanting to still have a comment system on my posts.  I set out looking at my options.  There were many options out there and some were better in ways than my final choice.  Such as [Disqus](https://disqus.com/).  My friend and ex-coworker uses it on [his blog](https://www.unixdude.net/).  While it offers a nice little interface and allows for logins from popular services, it just did not feel right for me to use.  Most of the ones I found all controlled the data, aka I would not host it.  

<!--readmore-->

I'll confess, I have been working on this switch to Jekyll for way to long and knew about [Cactus Comments](https://cactus.chat/) for over a year.  I went back and forth on it as the comment system I wanted to use.  I think what pushed me to it is that the [Matrix](https://matrix.org) protocol/specs just are out there for anyone to read and use.  Along with if I use it the comments are basically hosted by me instead of someone else.

So I set about configureing the comment system into my Jekyll config for my site.  I found the [documentation on Cactus Comments site](https://cactus.chat/docs/integrations/jekyll/) a bit lacking for my taste.  I quickly took what they had and spun it around to a thing of my own.

### The setup
The first things they wanted was to hijack the disqus comments config.  No that wont do.  I made a subsection for Cactus and put in new variables.

##### **_config.yml**
```yaml
comments:
  active: cactus
  cactus:
    siteName: mindlesstux.com
    serverName: cactus.chat
    guestPostingEnabled: false
    loginEnabled: true
    showRoom: true
```
{: file="_config.yml" }

The next thing they said was to toss two linkes into a custom header file, I skipped this in favor of my next bit.

Then they have a replace disqus comment code/template.  Well I went off and just wrote my own comment code/template.

##### **[_includes/comments/cactus.html](https://github.com/mindlesstux/mindlesstux.github.io/blob/master/_includes/comments/cactus.html)**
```html
{% raw %}
<!--
    Cactus Comments!
        Trying to make this work...
-->

<script src="https://latest.cactus.chat/cactus.js" type="text/javascript"></script>
<link href="https://latest.cactus.chat/style.css" rel="stylesheet" type="text/css"></link>

{% if site.comments.cactus.guestPostingEnabled and site.comments.cactus.guestPostingEnabled != "" and site.comments.cactus.guestPostingEnabled != nil %}
{% else %}
  <blockquote class="prompt-warning"><div>
    <p>Guest posting is disabled. Please login to your matrix chat to comment.</p>
  </div></blockquote>
{% endif %}

<div id="comment-section"></div><script>
initComments({
  node: document.getElementById("comment-section"),
  defaultHomeserverUrl: "https://matrix.cactus.chat:8448",
  serverName: "{{ site.comments.cactus.serverName }}",
  siteName: "{{ site.comments.cactus.siteName }}",
  commentSectionId: '{{ page.path | downcase | replace: "_posts/", "-posts--" }}',
  guestPostingEnabled: {{ site.comments.cactus.guestPostingEnabled }},
  loginEnabled: {{ site.comments.cactus.loginEnabled }}
})
</script>

{% capture local_room %}#comments_{{ site.comments.cactus.siteName }}_{{ page.path | downcase | replace: "_posts/", "-posts--" }}:{{ site.comments.cactus.serverName }}{% endcapture%}
{% if site.comments.cactus.showRoom and site.comments.cactus.showRoom != "" and site.comments.cactus.showRoom != nil %}
<blockquote class="prompt-info"><div>
  <p>You may also join the room directly: <a href="https://matrix.to/#/{{ local_room | url_encode }}>">{{ local_room }}</a></p>
</div></blockquote>
{% endif %}

<!--
    room: {{ local_room }}
    
    *END Cactus Comments
-->
{% endraw %}```
{: file="_includes/comments/cactus.html" }

Basically did the header includes (I know probably bad form for html), and setup all the comment bits.  I made use of my new options and throw up a warning box if guest comments are disabled.  I also have a handy link to the matrix chat room that acts as the storage space for the comments.  I also made the comment section id a bit more understandable instead of just a url.
