# EmulatorPkg UEFI Shell App Development Skill

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Claude Code](https://img.shields.io/badge/Claude%20Code-Skill-blue.svg)](https://claude.ai/code)

> A comprehensive Claude Code skill for developing UEFI Shell applications with EmulatorPkg.

English | [简体中文](readme.md)

## Overview

This skill provides Claude Code with complete knowledge for UEFI Shell application development, covering the entire workflow from environment setup to debugging and deployment. Supports both Windows (Visual Studio 2019) and Linux (GCC) platforms.

<img width="512" height="480" alt="intro" src="https://github.com/user-attachments/assets/e6d96822-c5be-4d65-8680-71fd7ab53187" />
<img width="512" height="480" alt="gameplay_turret" src="https://github.com/user-attachments/assets/f73d49c7-0c24-4335-b69d-63f10882d197" />
<img width="512" height="480" alt="boss_fight" src="https://github.com/user-attachments/assets/aa3ec6a8-6ab4-401e-baab-bb5f27181754" />
<img width="512" height="480" alt="ending" src="https://github.com/user-attachments/assets/68c8d8d4-2231-46f3-9a53-98b299656691" />


## Features

- **Complete Workflow** — One-stop guide for setup, build, development, and debugging
- **Dual Platform Support** — Windows (VS2019) + Linux (GCC)
- **Code Templates** — INF files, Shell applications, and GOP graphics templates
- **Debugging Guide** — Print output, DebugLib, VS2019 debugger integration
- **CJK Support** — Solutions for Chinese character encoding errors (C4819) in VS2019

## Installation

### Method 1: Direct Copy

Copy `SKILL.md` to your Claude Code skills directory:

```bash
# Windows
copy SKILL.md %USERPROFILE%\.claude\skills\emulator-uefi-shell-app\

# Linux/macOS
mkdir -p ~/.claude/skills/emulator-uefi-shell-app
cp SKILL.md ~/.claude/skills/emulator-uefi-shell-app/
```

### Method 2: Git Clone

```bash
git clone https://github.com/your-username/emulator-uefi-shell-app-skill.git
cd emulator-uefi-shell-app-skill

# Windows
xcopy /E /I skills\emulator-uefi-shell-app %USERPROFILE%\.claude\skills\emulator-uefi-shell-app

# Linux/macOS
cp -r skills/emulator-uefi-shell-app ~/.claude/skills/
```

## Quick Start

After installation, simply ask Claude Code questions to trigger the skill:

```
How do I create a UEFI Shell application?
How do I use GOP for graphics rendering in EmulatorPkg?
How do I fix C4819 encoding errors during compilation?
How do I debug Shell applications in the emulator?
```

## Contents

| Section | Content |
|---------|---------|
| Environment Setup | VS2019/GCC configuration, EDK2 source acquisition |
| Build & Run Emulator | target.txt configuration, build commands, WinHost/Host execution |
| Create Shell App | Directory structure, INF templates, code templates, GOP graphics template |
| Deploy to Emulator | DSC/FDF file modification, build and deploy process |
| Build Error Handling | Chinese encoding error solutions, warning suppression |
| Emulator Debugging | Print debugging, DebugLib, VS2019 debugger |
| Common Protocols & Libraries | GOP graphics protocol, SimpleTextIn input, memory allocation |

## Trigger Conditions

The skill is automatically triggered when users ask about:

- UEFI Shell application development
- EmulatorPkg compilation and execution
- GOP graphics programming
- UEFI application debugging
- Chinese/CJK encoding compilation errors

## Supported Protocols

| Protocol | Header File | Purpose |
|----------|-------------|---------|
| GOP | `Protocol/GraphicsOutput.h` | Graphics rendering, framebuffer operations |
| SimpleTextIn | `Protocol/SimpleTextIn.h` | Keyboard input |

## Common Libraries

| Library | Header File | Purpose |
|---------|-------------|---------|
| UefiLib | `Library/UefiLib.h` | Print function, basic UEFI functions |
| BaseMemoryLib | `Library/BaseMemoryLib.h` | Memory copy, set, compare |
| MemoryAllocationLib | `Library/MemoryAllocationLib.h` | AllocatePool, AllocatePages |
| DebugLib | `Library/DebugLib.h` | DEBUG macro, assertions |

## Quick Reference

| Task | Command |
|------|---------|
| Initialize Environment | `edksetup.bat` (Windows) / `source edksetup.sh` (Linux) |
| Build Emulator | `build -p EmulatorPkg\EmulatorPkg.dsc -a X64 -t VS2019 -b DEBUG` |
| Run Emulator | `Build\Emulator\DEBUG_VS2019\X64\WinHost.exe` |
| Clean & Rebuild | `build clean && build` |

## Resources

- [EDK2 Repository](https://github.com/tianocore/edk2)
- [UEFI Specification](https://uefi.org/specifications)
- [TianoCore Documentation](https://www.tianocore.org/)

## Contributing

Issues and Pull Requests are welcome!

1. Fork this repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Create a Pull Request

## License

This project is licensed under the [MIT](LICENSE) License.

---

**Note**: This skill requires [Claude Code](https://claude.ai/code) to function.
