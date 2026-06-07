<p align="center">
  <img src="public/stacklogo.jpg" alt="stack Logo" width="64" />
  <br />
  <h1 align="center">stack</h1>
  <p align="center">代码库转 Markdown。</p>
  <p align="center">
    <a href="https://github.com/arinltte/stack/releases/latest"><img src="https://img.shields.io/github/v/release/arinltte/stack?style=flat-square&color=blue" alt="最新版本" /></a>
    <a href="https://github.com/arinltte/stack/blob/main/LICENSE"><img src="https://img.shields.io/github/license/arinltte/stack?style=flat-square&color=green" alt="许可证" /></a>
    <img src="https://img.shields.io/badge/macOS-14.0%2B-blue?style=flat-square" alt="macOS" />
    <img src="https://img.shields.io/badge/应用内存-%3C30MB-brightgreen?style=flat-square" alt="内存" />
  </p>
</p>

<p align="center">
  <a href="./README.md">English</a> | <a href="./README-ZH.md">中文文档</a>
</p>

---

**stack** 是一款轻量级、超快的 macOS 实用工具，完全驻留在您的菜单栏中。它采用 SwiftUI 原生构建，允许您拖放代码库（文件夹、子文件夹或单个文件），并立即将它们合并为一个格式整洁的 Markdown 文档。 

它是为 LLM（如 ChatGPT、Claude、Gemini）提示词准备源代码，或进行离线代码审查的完美工具。

---

## 🏗️ 特性

- **原生菜单栏** — 安静地驻留在您的菜单栏中。将文件拖到菜单栏图标上即可瞬间打开拖放区。无需常驻窗口。
- **智能目录扫描** — 递归扫描嵌套文件夹，保留代码库的文件路径（例如 `src/components/App.tsx`）。
- **广泛的语言支持** — 自动检测并为 60 多种编程语言应用正确的 Markdown 语法高亮。
- **安全的二进制文件检测** — 智能检测并跳过编译的二进制文件、图像和可执行文件。通过强大的文本编码回退机制安全地读取纯文本文件。
- **隐藏文件管理** — 默认跳过隐藏文件/目录，以保持 Markdown 的整洁。如果您需要包含 `.env` 或 `.gitignore`，可在合并前轻松将其重新开启。
- **审查与管理** — 在动态可滚动的列表中审查待处理的文件。在生成最终文档前移除不需要的特定文件。
- **100% 离线与私密** — 所有处理均在您的本地计算机上完成。无 API、无遥测、无云端上传。
- **高级氛围设计** — 拥有令人惊艳、零性能开销的动画毛玻璃界面（可在默认、稀世翡翠、深海或繁花四种主题中选择）。

---

## 系统要求

- macOS 14 (Sonoma) 或更高版本。
- 无需任何外部依赖。

---

## 🚀 安装

### 推荐方式

从 [Releases](https://github.com/arinltte/stack/releases/latest) 页面下载最新的 `.dmg` 文件，打开它并将 **stack** 拖入“应用程序 (Applications)”文件夹。

### 绕过 Gatekeeper 拦截

如果 macOS 在首次启动时拦截该应用，请在安装后在终端 (Terminal) 中运行以下命令：

```bash
xattr -rd com.apple.quarantine /Applications/stack.app
```

> **注意：** 您的终端 (Terminal) 应用程序可能需要**完全磁盘访问权限**才能执行此命令。
> 请前往 **系统设置 → 隐私与安全性 → 完全磁盘访问权限** 授予权限，然后再运行上述命令。

---

## 快速开始

1. 启动 **stack**；它将出现在您的菜单栏中。
2. 从访达 (Finder) 拖拽一个文件夹（或多个文件），并悬停在 **stack** 的菜单栏图标上以打开面板。
3. 将文件拖放到虚线拖放区内。
4. 审查待处理文件列表（移除任何您不想要的文件）。
5. 点击 **合并 (Merge)**。
6. 生成的 `.md` 文件将立即保存到您的默认目标位置（“下载”文件夹）。

---

## 📂 数据与隐私

**stack** 100% 离线工作。它仅读取您明确提供的文件，并将其写入本地磁盘的 Markdown 文件中。

配置数据仅存储在您的本地计算机上，不会保存在其他任何地方：

| 位置 | 内容 |
| --- | --- |
| `~/Library/Preferences/com.arinltte.stack.plist` | 应用偏好设置（下载文件夹、文件命名、自动合并设置、主题） |

不会向外部传输任何使用数据、处理历史或任何形式的遥测数据。

要执行完全卸载，请运行：

```bash
rm -f ~/Library/Preferences/com.arinltte.stack.plist
rm -rf ~/Library/Application\ Support/com.arinltte.stack 2>/dev/null
rm -rf ~/Library/Saved\ Application\ State/com.arinltte.stack.savedState 2>/dev/null
killall cfprefsd
```

---

## 🤝 参与贡献

欢迎贡献。无论是错误报告、功能建议、文档改进还是拉取请求 (Pull Request)——我们都不胜感激。

**如何贡献：**

1. Fork 本仓库。
2. 创建功能分支：`git checkout -b feature/your-feature-name`
3. 提交您的更改，并附上清晰的提交信息。
4. 向 `main` 分支发起 Pull Request，并描述您更改的内容及原因。

**报告错误或请求功能**，请提交 [issue](https://github.com/arinltte/stack/issues)。提交错误报告时，请包含您的 macOS 版本和重现步骤。

---

## 从源码构建

```bash
git clone https://github.com/arinltte/stack.git
cd stack
open stack.xcodeproj
```

在 Xcode 中构建并运行 `stack` scheme。需要 Xcode 16 或更高版本。

---

## 📜 许可证

基于 MIT 许可证分发。有关更多信息，请参阅 `LICENSE`。

<p align="center">
  <i>开发者：arinltte · cjshen00@gmail.com</i>
</p>
