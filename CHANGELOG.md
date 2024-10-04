# Changelog

## 0.13.0

- Fix for missing `end` tokens, in sync responses from Synapse >= v1.61.0 (Thanks to Tom Price for !20).
- A prettier animation while loading comments.

## 0.12.0

- Re-structure login form to more clearly separate matrix.to links from direct login.
- Require user id (e.g. `@alice:example.com`) instead of username. Only show homeserver url if .well-known lookup fails.
- Add top-right "X" button to close login modal.
- Login modal now closes when you press outside it.
- Fix some CSS bugs related to positioning the login form in viewport center.
- Make `LoginForm` a stateful component.

## 0.11.0

- Relicense from GPLv3 to LGPLv3.
- Rewrite large parts of the stylesheet to use flexbox (Thanks to asdfkcdk for !8).
- Introduce CSS variables to the stylesheet (Thanks to asdfkcdk for !9).
- `.dark` and `.light` CSS classes with default values for dark/light mode (Thanks to asdfkcdk for !9).
- Bugfix: "View More" button no longer blinks when auto-refreshing short comment sections.

## 0.10.0

- Allow commenting with Markdown.
- Pluralize time units properly.
- Enforce maximum nesting depth of 100 when sanitizing `org.matrix.custom.html`-formatted messages.

## 0.9.0

- Comment sections can now be initialized using `data-*` attributes on the `script` tag (Thanks to @NicolaiSoeborg for !5).
- Allow using strings for any config parameter, including booleans and numbers.
- Users can now set a displayname when commenting as a guest.
- Some styling improvements for text inputs.

## 0.8.0

- Make comment time a semantic `time` element (Thanks to @hectorjsmith for !4).
- Add hover text to comment time (Thanks to @hectorjsmith for !4).
- Show "just now" instead of negative seconds if message timestamp is ahead of the client's time
- Add ability fetch new messages periodically
- New config option: `updateInterval`, which controls how often to fetch new messages.
- Change thumbnail size from 32x32 to 64x64.
- Stylesheet: allow linebreaks in comments.

## 0.7.0

- New configuration option: `loginEnabled` changes the login button to be a matrix.to link, if set to false (default is true).
- New configuration option: `guestPostingEnabled` requires users to log in using their Matrix account, if set to false (default is true).
- Added HACKING.md, a guide to getting started with hacking on the client.

## 0.6.0

- Move matrix.to link into login modal.
- Removed login status string above textarea.
- Show userid in Post button.
- Add placeholder text to comment textarea.
- Textarea inherits background color, to work better with darkmode websites.
- dev.html example page now has a darkmode toggle button.
- A bunch of smaller improvements to the default CSS.

## 0.5.0

- Support `m.image` messages
- Support `m.audio` messages
- Support `m.file` messages
- Support `m.video` messages

## 0.4.2

- Can now display multiple error messages at the same time.
- Better error messages for common bad config values.
- `m.notice` messages render now.
- Config parsing moved out of javascript, into Elm.
- Bugfix: Correct a hardcoded string oversight, that caused incorrect displaynames on Emote messages.

## 0.4.1

- Bugfix: Move the right sync token when getting newer messages, preventing duplicate comments after posting in small rooms.

## 0.4.0

- Fetch new messages after successfully posting a comment
- Update current time periodically
- Error messages are now red, and can be closed
- Bugfix: don't crash on redactions
- Bugfix: guest users can view messages sent by others after posting anonymously

## 0.3.2

- CI changes: put IPFS gateway links in release description

## 0.3.1

- Don't fetch messages again after an empty chunk was received
- AGPL -> GPL3

## 0.3.0

- Always join users. Issue join API call on login and on user session deserialization

## 0.2.1

- Fix Gitlab CI release pipeline for pinning artifacts to IPFS.

## 0.2.0

- Get a consistent number of comments, irrespective of how many unrenderable
  events are in the room.
- Introduce optional `pageSize` configuration parameter, which sets pagination size.
