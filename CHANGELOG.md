# Changelog

All notable changes to SpeakRate are documented here.
The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [1.3.0] - 2026-10-26

### Added
- **Natural pauses at line breaks**: lines that end without terminal punctuation
  now get a period before speaking, so bullet lists and run-on line breaks no
  longer read as one endless sentence.
- Bullet markers (`•`, `-`, `*`), numbered-list markers (`1.`, `2)`), markdown
  heading markers (`##`) and inline emphasis (`**bold**`, `__underline__`) are
  stripped before speaking instead of being read literally.
- "What's New" link in the About window pointing to this changelog.

## [1.2.0] - 2026-09-11

### Added
- About window with version, author, blog link and MIT license.

## [1.1.0] - 2026-09-10

### Added
- **Skip Technical Text** option: URLs, file paths, inline code, emails, UUIDs
  and hashes are replaced with short spoken placeholders ("link", "file",
  "code"…) localized in English, Spanish and French.
- Configurable read shortcut with 6 presets in the menu bar.

### Changed
- App is signed with a stable self-signed identity so the macOS Accessibility
  grant persists across rebuilds.

## [1.0.0] - 2026-09-07

### Added
- Initial release: read the selected text aloud in any app, with live speed
  control from the menu bar.
