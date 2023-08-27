---
title: 'Follow up: Docker + Synology'
date: '2020-09-15T21:24:52-04:00'
last_modified_at: '2020-09-15T21:24:52-04:00'
author: MindlessTux
layout: post
Reference_URL:
    - 'https://mindlesstux.com/2020/09/11/monitoring-my-cable-modem-signal-levels-for-problems/'
series:
    - 'Cable Modem Stats Graphing'
categories: [Monitoring, Grafana]
tags: [docker, synology, grafana, nodered]
---

As a follow up to my previous post as curiosity got the better of me. I decided to see how difficult it would be to set up MariaDB/Grafana/NodeRED on my Synology 1815+. Come to find out it is not that difficult to do so once you figure out the quirks of the UI you have to use.

Here is how to setup docker like I have but in a Synology system.

<!--readmore-->

## Install Docker

First thing, install docker if you do not have it already installed. Open the package center and in the third party apps section.

![Window shadow](/assets/uploads/2020/09/Setup_Docker_1.png){: width="150" height="150" }
_Open Package Center_
![Window shadow](/assets/uploads/2020/09/Setup_Docker_2.png){: width="150" height="150" }
_Find and install Docker under Third Party_
![Window shadow](/assets/uploads/2020/09/Setup_Docker_3.png){: width="150" height="150" }
_Open Docker_

 ## Pull down the images

![](/assets/uploads/2020/09/Setup_Docker_4.png){: width="150" height="150" }
Registry, search, and download

</div>Once you have the docker window open you will need to pull down the container images. To start go to registry, and search an image. Below is a short list of image:tag to search and work with.

- nodered/node-red:latest
- grafana/grafana:latest
- linuxserver/mariadb:latest
  - “Official” is mariadb:latest, but linuxserver team does a good job with their images

Example search node-red and you should find nodered/node-red in the list. Click it, then click the little popout icon to go to the page and see if there are any listed environment variables you might need/want to set. Then click download. Repeat for all 3 images.

## Wait till all images download

Go to the images section and wait till all images have a size of greater than 0 MB.

## Configure and start MariaDB

Once the images all have a file size it is time to launch them, starting with mariadb. In the images section highlight the chosen image, in this case linuxserver/mariadb:latest, then click the little pop out arrow icon. Switch back to the Synology window and click Launch.

Now you are given a chance to edit the settings for it. The tabs of main interest are the volumes and environment tabls. Under volumes click add folder and proceed to make a new structure of docker/mariadb/data, once you have that choose the data folder. Map it to /data. In the environment tab these are optional but suggested, add an entry for TZ, aka timezone, and set it to the local timezone if that is desired, mine is American/New\_York. The other setting is MYSQL\_ROOT\_PASSWORD, set put a password you want the root user to have.

You may also want to have this container auto-restart, that is under Advanced Settings. You may (recommended for now) also want to forward through the port from the Synology’s IP address. Under Port Settings change the local port from Auto to 3306.

[![](https://mindlesstux.com/wp-content/uploads/2020/09/mariadb_env_options-150x150.png)](https://mindlesstux.com/wp-content/uploads/2020/09/mariadb_env_options.png)
Details of interest in the new window that gets opened.
[![](https://mindlesstux.com/wp-content/uploads/2020/09/mariadb_setup_1-150x150.png)](https://mindlesstux.com/wp-content/uploads/2020/09/mariadb_setup_1.png) 
Images, highlight, open details, Launch 
[![](https://mindlesstux.com/wp-content/uploads/2020/09/mariadb_setup_2-150x150.png)](https://mindlesstux.com/wp-content/uploads/2020/09/mariadb_setup_2.png) </dt> <dd class="wp-caption-text gallery-caption" id="gallery-2-7989"> Advanced Settings </dd></dl>  
<dl class="gallery-item"> <dt class="gallery-icon landscape"> [![](https://mindlesstux.com/wp-content/uploads/2020/09/MariaDB_volumes_structure-150x150.png)](https://mindlesstux.com/wp-content/uploads/2020/09/MariaDB_volumes_structure.png) </dt> <dd class="wp-caption-text gallery-caption" id="gallery-2-7993"> Folder Structure </dd></dl><dl class="gallery-item"> <dt class="gallery-icon landscape"> [![](https://mindlesstux.com/wp-content/uploads/2020/09/mariadb_volumes-150x150.png)](https://mindlesstux.com/wp-content/uploads/2020/09/mariadb_volumes.png) </dt> <dd class="wp-caption-text gallery-caption" id="gallery-2-7991"> Configure Volumes </dd></dl><dl class="gallery-item"> <dt class="gallery-icon landscape"> [![](https://mindlesstux.com/wp-content/uploads/2020/09/mariadb_env-150x150.png)](https://mindlesstux.com/wp-content/uploads/2020/09/mariadb_env.png) </dt> <dd class="wp-caption-text gallery-caption" id="gallery-2-7983"> Configure Environmental </dd></dl>  
 </div>The other environment variables that can be set can be found in new window that was opened.

Once done you can click apply and next and apply.

## Configure and start Grafana

<div class="wp-caption alignright" id="attachment_7981" style="width: 160px">[![](https://mindlesstux.com/assets/uploads/2020/09/grafana_volumes-150x150.png)](https://mindlesstux.com/assets/uploads/2020/09/grafana_volumes.png)Grafana volumes.

</div>Launch the grafana/grafana:latest image like the MariaDB was. This time you want to map the volumes as follows:

- docker/grafana/logs -&gt; /var/log/grafana
- docker/grafana/data -&gt; /var/lib/grafana

If you want to map the port through, the port is 3000.

## Configure and start NodeRED

<div class="wp-caption alignright" id="attachment_7995" style="width: 160px">[![](https://mindlesstux.com/assets/uploads/2020/09/nodered_volumes-150x150.png)](https://mindlesstux.com/assets/uploads/2020/09/nodered_volumes.png)NodeRED volumes

</div>Launch the grafana/grafana:latest image like the MariaDB was. This time you want to map the volumes as follows:

- docker/nodered/data -&gt; /data

## Fix filesystem permissions the lazy way

<div class="wp-caption alignright" id="attachment_7979" style="width: 160px">[![](https://mindlesstux.com/assets/uploads/2020/09/Folder_Permissions-150x150.png)](https://mindlesstux.com/assets/uploads/2020/09/Folder_Permissions.png)Set everyone to Read and Write and apply to subfolders

</div>At this point, there should be a couple of containers crashing. If you dig in you will see the logs indicate that they are trying to copy data to the configured volume mount points. They can not due to permissions of where the volumes are on the Synology volume.

The lazy answer here is to edit the docker folder, give read/write to everyone with an application to all subfolders.

## Verify they are running…

At this point, NodeRED, Grafana, and MariaDB should be running without issue.

Grafana will be at http://&lt;ipaddress&gt;:3000/ and the default login is admin/admin.

NodeRED will be at http://&lt;ipaddress&gt;:1880/ and has no login by default.

For MariaDB, you can pull up a console and interact with it via a bash prompt. To do that:

- Go to the container section
- Click on the mariadb container
- Click details up top, new window pops open
- Click terminal in the new window
- Click create
- A new line appears on left side labeled “bash”, click it
- You now have a root prompt into the container,
- mysql -u root -p 
    - Enter the password you set as the environment variable

 <style type="text/css">
			#gallery-3 {
				margin: auto;
			}
			#gallery-3 .gallery-item {
				float: left;
				margin-top: 10px;
				text-align: center;
				width: 50%;
			}
			#gallery-3 img {
				border: 2px solid #cfcfcf;
			}
			#gallery-3 .gallery-caption {
				margin-left: 0;
			}
			/* see gallery_shortcode() in wp-includes/media.php */
		</style><div class="gallery galleryid-7901 gallery-columns-2 gallery-size-thumbnail" id="gallery-3"><dl class="gallery-item"> <dt class="gallery-icon landscape"> [![](https://mindlesstux.com/wp-content/assets/2020/09/MariaDB_verify-150x150.png)](https://mindlesstux.com/assets/uploads/2020/09/MariaDB_verify.png) </dt></dl><dl class="gallery-item"> <dt class="gallery-icon landscape"> [![](https://mindlesstux.com/assets/uploads/2020/09/MariaDB_verify_2-150x150.png)](https://mindlesstux.com/wp-content/uploads/2020/09/MariaDB_verify_2.png) </dt></dl>  
 </div>