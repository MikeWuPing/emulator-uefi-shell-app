# EmulatorPkg UEFI Shell 应用开发技能

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Claude Code](https://img.shields.io/badge/Claude%20Code-Skill-blue.svg)](https://claude.ai/code)

> 基于 EmulatorPkg 的 UEFI Shell 应用程序开发技能，为 Claude Code 提供完整的开发指南。

[English](README_EN.md) | 简体中文

## 简介

本技能为 Claude Code 提供 UEFI Shell 应用程序开发的完整知识库，涵盖从环境搭建到调试部署的全流程。支持 Windows（Visual Studio 2019）和 Linux（GCC）双平台开发环境。

## 特性

- **完整工作流** — 环境搭建、编译、开发、调试一站式指南
- **双平台支持** — Windows (VS2019) + Linux (GCC)
- **代码模板** — INF 文件、Shell 应用、GOP 图形应用模板
- **调试指南** — Print 输出、DebugLib、VS2019 调试器集成
- **中文支持** — 解决 VS2019 中文编码编译错误 (C4819)
- **QEMU 运行路径** — 除 Emulator/WinHost 外，提供 QEMU + OVMF + 虚拟 FAT 镜像运行模板
- **snapshot 自动截屏** — 运行后按间隔截取目标画面，写入带时间戳的 PNG，供多模态分析
- **版本一致性检查** — 每次构建自动递增 build 号，串口和窗口输出版本，运行后比对 `expected_version.txt`
- **眼睛和手（QMP 闭环）** — monitor `screendump` 抓显存快照（规避 SDL 窗口抓屏必黑）、`sendkey` 注入按键，构成"看图-操作"闭环，支持无人值守的"编译-运行-看图-按键-验证"循环

## 安装

### 方法一：直接复制

将 `SKILL.md` 复制到 Claude Code 技能目录：

```bash
# Windows
copy SKILL.md %USERPROFILE%\.claude\skills\emulator-uefi-shell-app\

# Linux/macOS
mkdir -p ~/.claude/skills/emulator-uefi-shell-app
cp SKILL.md ~/.claude/skills/emulator-uefi-shell-app/
```

### 方法二：Git Clone

```bash
git clone https://github.com/your-username/emulator-uefi-shell-app-skill.git
cd emulator-uefi-shell-app-skill

# Windows
xcopy /E /I skills\emulator-uefi-shell-app %USERPROFILE%\.claude\skills\emulator-uefi-shell-app

# Linux/macOS
cp -r skills/emulator-uefi-shell-app ~/.claude/skills/
```

## 快速开始

安装后，在 Claude Code 中直接提问即可触发技能：

```
如何创建一个 UEFI Shell 应用程序？
如何在 EmulatorPkg 中使用 GOP 进行图形渲染？
编译时出现 C4819 中文编码错误怎么解决？
如何在模拟器中调试 Shell 应用？
```

## 内容目录

| 章节 | 内容 |
|------|------|
| 环境搭建 | VS2019/GCC 环境配置、EDK2 源码获取 |
| 编译运行模拟器 | target.txt 配置、build 命令、WinHost/Host 运行 |
| 创建 Shell 应用 | 目录结构、INF 模板、代码模板、GOP 图形模板 |
| 部署到模拟器 | DSC/FDF 文件修改、编译部署流程 |
| 编译错误处理 | 中文编码错误解决方案、警告抑制 |
| 模拟器调试 | Print 调试、DebugLib、VS2019 调试器 |
| 常用协议与库 | GOP 图形协议、SimpleTextIn 输入、内存分配 |
| 版本化构建 | `VERSION.txt` 自动递增、`Version.h` 生成、`expected_version.txt` 写入 |
| QEMU 运行 | OVMF、虚拟 FAT 镜像、串口日志重定向 |
| snapshot 分析 | 定时截屏（首选 monitor screendump 显存快照）、多模态目标判定 |
| QMP 闭环 | screendump 抓帧（眼睛）、sendkey 输入注入（手）、无人值守验证循环 |

## 触发条件

当用户提问涉及以下内容时自动触发：

- UEFI Shell 应用程序开发
- EmulatorPkg 模拟器编译运行
- GOP 图形编程
- UEFI 应用调试方法
- 中文编码编译错误
- QEMU 运行 UEFI Shell app
- 用 snapshot 截图分析运行结果
- 防止编译失败后运行旧版本
- QEMU/SDL 窗口截图全黑（改用 monitor screendump）
- 需要脚本驱动 QEMU 中的应用（按键注入、自动开局/操作）
- 需要"编译-运行-看图-按键-验证"的无人值守闭环

## 支持的协议

| 协议 | 头文件 | 用途 |
|------|--------|------|
| GOP | `Protocol/GraphicsOutput.h` | 图形渲染、帧缓冲操作 |
| SimpleTextIn | `Protocol/SimpleTextIn.h` | 键盘输入 |

## 常用库

| 库 | 头文件 | 用途 |
|-----|--------|------|
| UefiLib | `Library/UefiLib.h` | Print 函数、基础 UEFI 功能 |
| BaseMemoryLib | `Library/BaseMemoryLib.h` | 内存复制、设置、比较 |
| MemoryAllocationLib | `Library/MemoryAllocationLib.h` | AllocatePool、AllocatePages |
| DebugLib | `Library/DebugLib.h` | DEBUG 宏、断言 |

## 快速参考

| 任务 | 命令/模板 |
|------|-----------|
| 初始化环境 | 目标项目配置的 `edksetup.bat` (Windows) / `source edksetup.sh` (Linux) |
| 编译模拟器 | `build -p EmulatorPkg\EmulatorPkg.dsc -a X64 -t VS2019 -b DEBUG` |
| 运行模拟器 | `Build\Emulator\DEBUG_VS2019\X64\WinHost.exe` |
| 生成新版本并构建 | `templates/Build-UefiApp.ps1` |
| QEMU 运行带截图 | `templates/Run-QemuWithSnapshots.ps1` |
| 检查运行版本 | `templates/Test-AppVersion.ps1` |
| 显存抓帧（首选） | monitor `screendump file.ppm`（SDL 窗口抓屏必黑时用它） |
| 注入按键 | monitor `sendkey ret` / `sendkey up 120`（长按用连点模拟） |
| 清理重编 | `build clean && build` |

## 相关资源

- [EDK2 官方仓库](https://github.com/tianocore/edk2)
- [UEFI 规范](https://uefi.org/specifications)
- [TianoCore 文档](https://www.tianocore.org/)

## 贡献

欢迎提交 Issue 和 Pull Request！

1. Fork 本仓库
2. 创建特性分支 (`git checkout -b feature/amazing-feature`)
3. 提交更改 (`git commit -m 'Add some amazing feature'`)
4. 推送到分支 (`git push origin feature/amazing-feature`)
5. 创建 Pull Request

## 许可证

本项目采用 [MIT](LICENSE) 许可证。

---

**注意**：本技能需要配合 [Claude Code](https://claude.ai/code) 使用。