# DropJPG — Launch Posts

Copy-paste drafts for launching DropJPG across communities.
Links: site https://eternaxcode.github.io/dropjpg/ · repo https://github.com/EternaxCode/dropjpg · download https://github.com/EternaxCode/dropjpg/releases/latest

Images to attach: `docs/social-preview.png` (thumbnail), `docs/screenshot.png` (UI).

---

## 1) r/macapps (English)

**Submit:** https://www.reddit.com/r/macapps/submit — use the **[Dev]** flair, attach a screenshot.

**Title:**

```
[Dev] DropJPG – a tiny menu bar app to batch-convert images (incl. HEIC) to JPG
```

**Body:**

**DropJPG** — drag, drop, done. A tiny macOS menu bar app that converts images to JPG.

I kept hitting the same annoyance: a pile of `.HEIC` files from my iPhone that some site or app wouldn't accept, and reaching for Preview's "Export" one file at a time. So I built the smallest tool that fixes it.

**What it does**
- Lives in the menu bar (no Dock icon). Click → drop files **or whole folders** (it recurses).
- Converts JPEG, PNG, GIF, TIFF, WebP, and **HEIC/HEIF** → JPG using the built-in macOS engine (`sips`).
- Auto-renames output to `name_001.jpg`, `name_002.jpg`, … into `~/Desktop/<name>/`.
- Optional: type a target width in px to **resize** (aspect ratio preserved).
- Originals are never touched (copy, not move). Everything runs **100% on-device** — no uploads, no accounts.

**Price:** Free, open source (MIT).

**Honest caveat:** I don't have a paid Apple Developer cert yet ($99/yr), so the app isn't notarized. On first launch macOS Gatekeeper will block it. There's a bundled double-click helper, or one Terminal command:
```
xattr -dr com.apple.quarantine /Applications/DropJPG.app
```
It only removes the "downloaded from internet" quarantine flag — nothing else. Full source is on GitHub if you want to check or build it yourself.

**Requirements:** macOS 12+, Apple Silicon or Intel.

- 🌐 Site: https://eternaxcode.github.io/dropjpg/
- 💻 GitHub: https://github.com/EternaxCode/dropjpg
- ⬇ Download: https://github.com/EternaxCode/dropjpg/releases/latest

It's deliberately minimal — feedback welcome, especially on formats or workflows you'd want supported. Thanks!

---

## 2) GeekNews / 긱뉴스 (한국어)

**제출:** https://news.hada.io/new — URL + 본문 붙여넣기.

**URL:** `https://github.com/EternaxCode/dropjpg`

**제목:**

```
DropJPG – 드래그앤드롭으로 이미지를 JPG로 변환하는 macOS 메뉴바 앱
```

**본문:**

macOS 메뉴바에서 동작하는 작은 이미지→JPG 변환기. 파일·폴더를 끌어다 놓으면 끝.

아이폰 `.HEIC` 파일을 어떤 사이트나 앱이 안 받아줘서 매번 미리보기로 한 장씩 내보내던 게 귀찮아 만들었음. 그 문제만 푸는 가장 작은 도구를 목표로 함.

**주요 기능**
- 메뉴바 상주 (Dock 아이콘 없음). 클릭 → 파일/폴더 드롭 (하위 폴더까지 재귀 처리)
- JPEG·PNG·GIF·TIFF·WebP·**HEIC/HEIF** → JPG 변환 (macOS 내장 `sips` 엔진, 외부 의존성 0)
- 출력 자동 리네임: `~/Desktop/<이름>/<이름>_001.jpg`, `_002.jpg` …
- 선택 옵션: 가로 픽셀 입력 시 비율 유지 리사이즈
- 원본 보존(이동 아닌 복사), **전부 로컬 처리** — 업로드·계정 없음

**기술 스택**
- Swift 단일 파일 + AppKit (NSStatusItem + 드롭 윈도우), 변환은 `sips` 셸 호출
- 의존성 없이 `swiftc`로 빌드, `.app`/DMG 패키징
- 릴리스는 GitHub Actions가 태그 푸시 시 macOS 러너에서 DMG 자동 빌드·배포

**한계 / 솔직한 고지**
- Apple Developer 인증서($99/년)가 아직 없어 **notarize 안 됨**. 첫 실행 시 Gatekeeper가 막음
- 해제: DMG 내 더블클릭 도우미, 또는 터미널 `xattr -dr com.apple.quarantine /Applications/DropJPG.app`
- 이 명령은 "인터넷에서 받음" 격리 속성만 제거함. 소스 전체 공개라 직접 빌드도 가능

**정보**
- 무료, 오픈소스(MIT)
- 요구사항: macOS 12+, Apple Silicon·Intel
- 사이트: https://eternaxcode.github.io/dropjpg/
- 다운로드: https://github.com/EternaxCode/dropjpg/releases/latest

의도적으로 미니멀하게 만듦. 추가로 지원했으면 하는 포맷·워크플로 피드백 환영.

---

## 3) Product Hunt (English)

**Submit:** https://www.producthunt.com/posts/new — launch from your own maker account. Post the maker comment immediately after launch.

**Name:** `DropJPG`

**Tagline (≤60 chars):** `Convert any image (incl. HEIC) to JPG, from your menu bar`

**Description (≤260 chars):**

> A tiny macOS menu bar app. Drag photos or folders, and it converts any image — including HEIC — to JPG, auto-renamed into a new folder, with optional resizing. 100% on-device, no uploads. Free & open source.

**Topics:** Mac · Productivity · Photography · Open Source · Design Tools

**Gallery order:** 1) `docs/social-preview.png` 2) `docs/screenshot.png` 3) (optional) before/after GIF

**Maker's first comment:**

👋 Hey Product Hunt!

I built **DropJPG** to kill one specific annoyance: my iPhone spits out `.HEIC` files, and half the web won't accept them. Exporting them one-by-one in Preview got old fast.

So this is the smallest tool that fixes it:

- 🖼️ **Any format → JPG** — JPEG, PNG, GIF, TIFF, WebP, and **HEIC/HEIF** (built-in macOS engine, zero dependencies)
- 📂 **Drag & drop files or whole folders** — it recurses into subfolders
- 🔢 **Auto-renames** output to `name_001.jpg`, `name_002.jpg`… in `~/Desktop/<name>/`
- 📐 **Optional resize** — set a width in px, aspect ratio preserved
- 🔒 **100% on-device** — no uploads, no accounts, originals untouched
- 🧭 Lives in the **menu bar**, not the Dock

It's **free and open source (MIT)**.

🛠️ One honest note: I don't have a paid Apple Developer cert yet, so it isn't notarized. On first launch macOS Gatekeeper blocks it — there's a one-click helper in the DMG, or a single Terminal command (in the README). Full source is up, so you can build it yourself too.

This is a deliberately minimal v1. I'd love feedback on what formats or workflows you'd want next. Thanks for checking it out! 🙏

---

## Launch checklist

- [ ] Upload `docs/social-preview.png` to GitHub repo **Settings → Social preview**
- [ ] r/macapps — post with **[Dev]** flair + screenshot
- [ ] GeekNews — submit URL + body
- [ ] Product Hunt — launch Tue–Thu, 00:01 PST; post maker comment immediately
- [ ] Reply to every comment in the first few hours (ranking favors engagement)
- [ ] Cross-post link to any relevant Slack/Discord/X
