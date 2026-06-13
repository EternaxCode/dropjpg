# Changelog

All notable changes to DropJPG are documented here.
Format loosely follows [Keep a Changelog](https://keepachangelog.com/).

## [Unreleased]
### Added
- README screenshot (rendered UI mockup) and app-icon hero.
- Ko-fi sponsor button (`.github/FUNDING.yml`) and Support section.
- `DROPJPG_AUTOSHOW=1` env opens the window with sample data (for docs).
### Changed
- CI: `actions/checkout@v5` + force Node24 runtime (Node20 deprecation).

## [1.1] — 2026-06-13
### Changed
- Release pipeline automated: pushing a `v*` tag builds the DMG on a macOS CI
  runner and publishes the GitHub Release automatically (`release.sh` + Actions).
- Version is now single-sourced from the `VERSION` file.
- No app behavior changes — first CI-built release.

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
