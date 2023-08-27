---
title: 'My tweak to the &#8216;Blogstream&#8217; wordpress theme'
date: '2022-01-15T02:08:15-05:00'
lastmod: '2022-01-15T02:08:15-05:00'
author: MindlessTux
layout: post
Reference_URL:
    - 'https://developer.wordpress.org/reference/functions/get_post_custom_values/'
categories: [Wordpress]
tags: [wordpress, theme]
---

So I got tired of looking at the theme that I had on this site, one of the wordpress out of the box from a few years ago. Out of curiosity I started browsing themes and I came across this one. It is called “[Blogstream](https://alx.media/themes/blogstream/)” by [Alexander Agnarson](http://alx.media/). I spent a little time tweaking the settings from the GUI but knew in a short time I would need to dig into the code for it to add some code for what I call “Reference URLs”. These are pages that I consulted about what I may have written. I just want to make sure they get the credit for part of my writing so I made it a custom field.

I liked how the tags look so I was hoping I could steal its CSS rather clumsily and have each URL be a little bubble. I also only wanted it to show on a full page of a post only. With those restrictions in mind after the break is the code to make it happen.

<!--readmore-->

Diff of the original file and what I have currently

```console
$ diff -u single.php.orig single.php
--- single.php.orig     2022-01-15 01:49:45.258556123 -0500
+++ single.php  2022-01-15 01:47:56.898608750 -0500
@@ -34,6 +34,17 @@
                                                <?php wp_link_pages(array('before'=>'<div class="post-pages">'.esc_html__('Pages:','blogstream'),'after'=>'</div>')); ?>
                                                <div class="clear"></div>
                                                <?php the_tags('<p class="post-tags"><span>'.esc_html__('Tags:','blogstream').'</span> ','','</p>'); ?>
+                                               <?php 
+                                                       $mykey_values = get_post_custom_values('Reference_URL');
+                                                       if(!empty($mykey_values)) {
+                                                               echo '<p class="post-tags"><span>Referenced URL/Sites:';
+                                                               foreach ( $mykey_values as $key => $value ) {
+                                                                       // echo "$key => $value<br />"; 
+                                                                       echo "<a href=\"$value\">$value</a>";
+                                                               }
+                                                               echo '</span></p>';
+                                                       }
+                                               ?>
                                                <?php do_action( 'alx_ext_sharrre' ); ?>
                                        </div><!--/.entry-->
                                </div>
```

Easier to copy/paste code.

```php
$mykey_values = get_post_custom_values('Reference_URL');
if(!empty($mykey_values)) {
    echo '<p class="post-tags"><span>Referenced URL/Sites:';
    foreach ( $mykey_values as $key => $value ) {
        echo "<a href=\"$value\">$value</a>";
    }
    echo '</span></p>';
}
```