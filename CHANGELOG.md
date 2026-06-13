# Changelog

All notable changes to DropJPG are documented here.
Format loosely follows [Keep a Changelog](https://keepachangelog.com/).

## [Unreleased]

## [1.0] — 2026-06-13
### Added
- Menu bar app (no Dock icon) with always-on-top drop window.
- Drag & drop files **and** folders (recurses into subfolders).
- Convert images to JPG via built-in `sips` — JPEG, PNG, GIF, TIFF, WebP, HEIC/HEIF.
- Auto-rename output to `<name>_001.jpg`, `<name>_002.jpg`, … in `~/Desktop/<name>/`.
- Optional target-width resize (aspect ratio preserved).
- Dropped-file list shown in the window.
- Non-image files copied through with the same numbering; originals never modified.
- Custom converter icon (empty→filled tile) for menu bar and app bundle.
- DMG packaging (`make_dmg.sh`) with drag-to-Applications layout and an
  unquarantine install helper.
