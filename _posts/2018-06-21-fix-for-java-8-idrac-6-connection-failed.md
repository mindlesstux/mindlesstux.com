---
title: 'Fix for Java 8+ &#038; iDRAC 6 Connection Failed'
date: '2018-06-21T18:00:23-04:00'
lastmod: '2018-06-21T18:00:23-04:00'
author: MindlessTux
layout: post
Reference_URL:
    - 'https://www.dell.com/community/Systems-Management-General/iDRAC6-Virtual-Console-Connection-Failed/m-p/6088796/highlight/true#M26061'
categories: []
tags: [idrac, java]
---

For work I recently had to stand up a temporary system that has the old iDRAC 6 in it. Many will know that Java 8+ (from my testing) seems to have a disliking for that version of iDRAC. I spent a day grumbling at the error while standing next to the offending system in the data center watching the OS hang on install. After doing some digging this morning I found the key that kills the connection. SSLv3.

<!--readmore-->

So thanks to MathieuW on the dell community forums for posting this info!

> Go to Java installation folder.  
> Open {JRE\_HOME}\\lib\\security\\java.security -file in text editor.  
> Delete or comment out the following line “jdk.tls.disabledAlgorithms=SSLv3”.

My notes, open the file in notepad++ as admin, just comment out the whole line. Save. Re-Launch your virtual console.

\*edit 2022 Feb 15th\*  
Ubuntu 20.04 location of said file:  
/usr/lib/jvm/java-8-openjdk-amd64/jre/lib/security/java.security  
Might be slightly different if a different package is installed.