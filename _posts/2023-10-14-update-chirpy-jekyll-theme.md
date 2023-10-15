---
title: 'Updating Chirpy Jekyll Theme'
date: '2023-10-14 10:00:00 -0400'
last_modified_at: '2023-10-14 10:00:00 -0400'
author: MindlessTux
layout: post
Reference_URL:
categories: [Jekyll]
tags: [jekyll, chirpy, github]
---
From time to time it is nessary to update the [Chirpy](https://github.com/cotes2020/jekyll-theme-chirpy) theme I use here on my site.  I end up failing to recall my steps everytime so I figured I better write them out and maybe someone might find it interesting.

## Github sync
So I use the 'production' branch as what I base my site off of.  So step one is to sync the production branch to [my repos](https://github.com/mindlesstux/mindlesstux.com).  I simply go to the branch and hit sync fork.  I also do this for the master branch as well, for no reason.  I dont make any changes to production or master branches, they are just replicas for my purpose.

## Update the developmenet branch
I have a branch called [mtcom-development](https://github.com/mindlesstux/mindlesstux.com/tree/mtcom-development) where I do all my changes and inital blog posts editing.  To sync this branch with the themes production branch I have to run the following.

```bash
~/mindlesstux.com$ git checkout mtcom-development
Switched to branch 'mtcom-development'
Your branch is up to date with 'origin/mtcom-development'.

~/mindlesstux.com$ git pull
Already up to date.

~/mindlesstux.com$ git merge origin/production
Auto-merging _layouts/post.html
CONFLICT (content): Merge conflict in _layouts/post.html
Auto-merging _layouts/home.html
CONFLICT (content): Merge conflict in _layouts/home.html
Removing _javascript/modules/components/img-lazyload.js
Auto-merging _includes/head.html
Auto-merging _drafts/old_stuff/1970-01-03-getting-started.md
CONFLICT (content): Merge conflict in _drafts/old_stuff/1970-01-03-getting-started.md
Auto-merging _drafts/old_stuff/1970-01-02-write-a-new-post.md
Auto-merging _drafts/old_stuff/1970-01-01-text-and-typography.md
CONFLICT (content): Merge conflict in _drafts/old_stuff/1970-01-01-text-and-typography.md
Auto-merging _config.yml
CONFLICT (content): Merge conflict in _config.yml
Auto-merging Gemfile
CONFLICT (content): Merge conflict in Gemfile
Removing .github/ISSUE_TEMPLATE/feature_request.md
Removing .github/ISSUE_TEMPLATE/bug_report.md
Automatic merge failed; fix conflicts and then commit the result.
```

Yay for conflicts of my changes.

```
~/mindlesstux.com$ git status
On branch mtcom-development
Your branch is up to date with 'origin/mtcom-development'.

You have unmerged paths.
  (fix conflicts and run "git commit")
  (use "git merge --abort" to abort the merge)

Changes to be committed:
        new file:   .github/DISCUSSION_TEMPLATE/general.yml
        new file:   .github/DISCUSSION_TEMPLATE/q-a.yml
        deleted:    .github/ISSUE_TEMPLATE/bug_report.md
        new file:   .github/ISSUE_TEMPLATE/bug_report.yml
        deleted:    .github/ISSUE_TEMPLATE/feature_request.md
        new file:   .github/ISSUE_TEMPLATE/feature_request.yml
        modified:   .github/PULL_REQUEST_TEMPLATE.md
        modified:   .stylelintrc.json
        modified:   README.md
        modified:   _data/locales/de-DE.yml
        modified:   _data/locales/en.yml
        modified:   _data/locales/ru-RU.yml
        modified:   _data/origin/basic.yml
        modified:   _data/origin/cors.yml
        modified:   _drafts/old_stuff/1970-01-02-write-a-new-post.md
        modified:   _includes/comments/disqus.html
        modified:   _includes/comments/giscus.html
        modified:   _includes/comments/utterances.html
        modified:   _includes/embed/twitch.html
        modified:   _includes/embed/youtube.html
        modified:   _includes/head.html
        modified:   _includes/js-selector.html
        modified:   _includes/refactor-content.html
        modified:   _includes/related-posts.html
        modified:   _includes/toc.html
        modified:   _javascript/home.js
        modified:   _javascript/modules/components/clipboard.js
        deleted:    _javascript/modules/components/img-lazyload.js
        new file:   _javascript/modules/components/img-loading.js
        modified:   _javascript/modules/plugins.js
        modified:   _javascript/page.js
        modified:   _javascript/post.js
        modified:   _layouts/default.html
        modified:   _layouts/page.html
        modified:   _sass/addon/commons.scss
        modified:   _sass/addon/module.scss
        modified:   _sass/addon/syntax.scss
        modified:   _sass/addon/variables.scss
        modified:   _sass/colors/syntax-dark.scss
        modified:   _sass/colors/syntax-light.scss
        modified:   _sass/colors/typography-dark.scss
        modified:   _sass/colors/typography-light.scss
        modified:   _sass/layout/home.scss
        modified:   _sass/layout/post.scss
        modified:   assets/js/pwa/sw.js
        modified:   assets/lib
        renamed:    CHANGELOG.md -> docs/CHANGELOG.md
        modified:   docs/CONTRIBUTING.md
        modified:   jekyll-theme-chirpy.gemspec
        modified:   package.json
        modified:   tools/release

Unmerged paths:
  (use "git add <file>..." to mark resolution)
        both modified:   Gemfile
        both modified:   _config.yml
        both modified:   _drafts/old_stuff/1970-01-01-text-and-typography.md
        both modified:   _drafts/old_stuff/1970-01-03-getting-started.md
        both modified:   _layouts/home.html
        both modified:   _layouts/post.html

~/mindlesstux.com$
```

It could be worse, I only have to look at 4 files this time.  I ignore the ones in `_drafts`.  To modify those 4 files I tend to use [VSCode](https://code.visualstudio.com/) with a git plugin to handle the compare.

![VS Code Diff View](/assets/img/posts/update-chirpy/Chirpy_Theme_Updates_1_vscode_diff_view.png){: .normal}

Though sometimes I forget that ```git status ```  puts in things to identify changes.  I just need to go back in and remove those ensuring the upstream and my changes are what I want.

![VS Code Diff View](/assets/img/posts/update-chirpy/Chirpy_Theme_Updates_2_vscode_diff_view.png){: .normal}

After that usually in VSCode I do the equivalent of ```git push```  to push the changes up into the repository.  After that is done it takes just a moment for CloudFlare Pages to kick and pull the repo, build the site, and give me a semi temporary url to go view the results in.


![Cloudflare Pages](/assets/img/posts/update-chirpy/Chirpy_Theme_Updates_3_Cloudflare_Pages.png){: .normal}