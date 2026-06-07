<p align="center">
  <img src="public/stacklogo.jpg" alt="stack Logo" width="64" />
  <br />
  <h1 align="center">stack</h1>
  <p align="center">Repo to Markdown.</p>
  <p align="center">
    <a href="https://github.com/arinltte/stack/releases/latest"><img src="https://img.shields.io/github/v/release/arinltte/stack?style=flat-square&color=blue" alt="Latest Release" /></a>
    <a href="https://github.com/arinltte/stack/blob/main/LICENSE"><img src="https://img.shields.io/github/license/arinltte/stack?style=flat-square&color=green" alt="License" /></a>
    <img src="https://img.shields.io/badge/macOS-14.0%2B-blue?style=flat-square" alt="macOS" />
    <img src="https://img.shields.io/badge/app%20memory-%3C30MB-brightgreen?style=flat-square" alt="Memory" />
  </p>
</p>

<p align="center">
  <a href="./README.md">English</a> | <a href="./README-ZH.md">中文文档</a>
</p>

---

**stack** is a lightweight, ultra-fast macOS utility that lives entirely in your menu bar. Built natively with SwiftUI, it allows you to drag and drop your codebase—folders, sub-folders, or individual files—and instantly merge them into a single, cleanly formatted Markdown document. 

It is the perfect tool for preparing your source code for LLM prompting (ChatGPT, Claude, Gemini) or offline code reviews.

---

## 🏗️ Features

- **Menu bar native** — Lives quietly in your menu bar. Drag files over the menu bar icon to instantly open the drop zone. No persistent window required.
- **Smart Directory Scanning** — Recursively scans nested folders, maintaining your codebase's file paths (e.g., `src/components/App.tsx`).
- **Universal Language Support** — Automatically detects and applies the correct Markdown syntax highlighting for over 60+ programming languages.
- **Safe Binary Detection** — Intelligently detects and skips compiled binaries, images, and executables. Reads plain text files securely with robust text-encoding fallbacks.
- **Hidden Files Management** — Skips hidden files/directories by default to keep your Markdown clean. Easily toggle them back in before merging if you need to include `.env` or `.gitignore`.
- **Review & Manage** — Review your pending files in a dynamic, scrollable list. Remove specific files before compiling your final document.
- **100% Offline & Private** — Processes everything locally on your machine. No APIs, no telemetry, no cloud uploads.
- **Premium ambient design** — Features a stunning, zero-overhead animated frosted glass interface (choose between Default, Rare Jade, Deep Ocean, or Floral themes).

---

## Requirements

- macOS 14 (Sonoma) or later.
- Zero external dependencies required.

---

## 🚀 Installation

### Recommended

Download the latest `.dmg` from the [Releases](https://github.com/arinltte/stack/releases/latest) page, open it, and drag **stack** to your Applications folder.

### Gatekeeper

If macOS blocks the app on first launch, run the following in Terminal after installation:

```bash
xattr -rd com.apple.quarantine /Applications/stack.app
```

> **Note:** Your Terminal application may require **Full Disk Access** before this command works.
> Grant it under **System Settings → Privacy & Security → Full Disk Access**, then run the command above.

---

## Getting Started

1. Launch **stack**; it will appear in your menu bar.
2. Drag a folder (or multiple files) from Finder and hover over the **stack** menu bar icon to open the panel.
3. Drop your files into the dotted drop zone.
4. Review the list of pending files (remove any you don't want).
5. Click **Merge**.
6. The compiled `.md` file will be saved instantly to your default destination (Downloads).

---

## 📂 Data & Privacy

**stack** works 100% offline. It reads the files you explicitly provide and writes them to a Markdown file on your local disk.

Configuration data is stored locally on your machine and nowhere else:

| Location | Contents |
| --- | --- |
| `~/Library/Preferences/com.arinltte.stack.plist` | App preferences (download folder, file naming, auto-merge settings, themes) |

No usage data, processing history, or telemetry of any kind are transmitted externally.

To perform a complete uninstall:

```bash
rm -f ~/Library/Preferences/com.arinltte.stack.plist
rm -rf ~/Library/Application\ Support/com.arinltte.stack 2>/dev/null
rm -rf ~/Library/Saved\ Application\ State/com.arinltte.stack.savedState 2>/dev/null
killall cfprefsd
```

---

## 🤝 Contributing

Contributions are welcome. Whether it's a bug report, a feature suggestion, a documentation improvement, or a pull request — all are appreciated.

**To contribute:**

1. Fork the repository.
2. Create a feature branch: `git checkout -b feature/your-feature-name`
3. Commit your changes with a clear message.
4. Open a pull request against `main` with a description of what you changed and why.

**To report a bug or request a feature**, open an [issue](https://github.com/arinltte/stack/issues). Please include your macOS version and steps to reproduce for bug reports.

---

## Building from Source

```bash
git clone https://github.com/arinltte/stack.git
cd stack
open stack.xcodeproj
```

Build and run the `stack` scheme in Xcode. Requires Xcode 16 or later.

---

## 📜 License

Distributed under the MIT License. See `LICENSE` for more information.

<p align="center">
  <i>Developed by arinltte · cjshen00@gmail.com</i>
</p>
