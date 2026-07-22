---
name: emulator-uefi-shell-app
description: Use when developing UEFI Shell applications, creating INF/GOP/SimpleTextIn code, building or debugging with EmulatorPkg/WinHost or QEMU, handling VS2019/GCC or encoding issues, validating runs with version stamps and snapshot screenshots, or driving QEMU apps hands-on via monitor screendump/sendkey closed-loop.
---

# EmulatorPkg UEFI Shell 应用程序开发指南

本技能提供在 EmulatorPkg 模拟器环境下开发 UEFI Shell 应用程序的完整流程，适用于 Windows（VS2019）和 Linux（GCC）平台。

本技能不假设任何特定项目或机器环境。EDK2、编译工具链、QEMU、OVMF 固件和应用输出路径都由目标项目配置；如果目标项目的 `CLAUDE.md` 或脚本已经给出这些路径，优先使用项目配置，不要重新下载或改写全局环境。

## 目录

1. [环境搭建](#1-环境搭建)
2. [编译与运行模拟器](#2-编译与运行模拟器)
3. [创建 Shell 应用程序](#3-创建-shell-应用程序)
4. [部署到模拟器](#4-部署到模拟器)
5. [编译错误处理](#5-编译错误处理)
6. [模拟器调试方法](#6-模拟器调试方法)
7. [常用协议与库](#7-常用协议与库)

---

## 1. 环境搭建

### 1.1 Windows + Visual Studio 2019

**前置条件：**
- Visual Studio 2019（社区版/专业版/企业版）
- Windows SDK 10
- Git for Windows

**环境变量设置：**

```batch
:: 设置 VS2019 路径
set VS2019_PREFIX=C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\VC\
set WINSDK10_PREFIX=C:\Program Files (x86)\Windows Kits\10\bin\10.0.19041.0\

:: 设置 EDK2 工作区
set WORKSPACE=<你的edk2路径>
set EDK_TOOLS_PATH=%WORKSPACE%\BaseTools
set PACKAGES_PATH=%WORKSPACE%
```

**初始化环境：**

```batch
cd %WORKSPACE%
edksetup.bat
```

### 1.2 Linux + GCC

**前置条件：**
- GCC 5+ 或 GCC 9+（推荐）
- GNU Make、Python 3.x
- libuuid-dev、nasm

```bash
# Ubuntu/Debian
sudo apt-get install build-essential uuid-dev iasl nasm python3

# 设置环境变量
export WORKSPACE=/path/to/edk2
export EDK_TOOLS_PATH=$WORKSPACE/BaseTools
export PACKAGES_PATH=$WORKSPACE

# 初始化
cd $WORKSPACE
source edksetup.sh
make -C BaseTools
```

### 1.3 获取 EDK2 源码

```bash
git clone https://github.com/tianocore/edk2.git
cd edk2
git submodule update --init
```

---

## 2. 编译与运行模拟器

### 2.1 配置 target.txt

编辑 `Conf/target.txt`：

```ini
ACTIVE_PLATFORM       = EmulatorPkg/EmulatorPkg.dsc
TARGET                = DEBUG
TARGET_ARCH           = X64          # 或 IA32
TOOL_CHAIN_TAG        = VS2019       # Windows
# TOOL_CHAIN_TAG      = GCC5         # Linux
```

### 2.2 编译命令

**Windows：**
```batch
build -p EmulatorPkg\EmulatorPkg.dsc -a X64 -t VS2019 -b DEBUG
```

**Linux：**
```bash
build -p EmulatorPkg/EmulatorPkg.dsc -a X64 -t GCC5 -b DEBUG
```

**输出文件：**
```
Build/Emulator/DEBUG_VS2019/X64/WinHost.exe    # Windows 模拟器
Build/Emulator/DEBUG_GCC5/X64/Host             # Linux 模拟器
```

### 2.3 运行模拟器

**Windows：**
```batch
cd Build\Emulator\DEBUG_VS2019\X64
WinHost.exe
```

**Linux：**
```bash
cd Build/Emulator/DEBUG_GCC5/X64
./Host
```

模拟器启动后进入 UEFI Shell 界面。

---

## 3. 创建 Shell 应用程序

### 3.1 目录结构

```
EmulatorPkg/Application/MyShellApp/
├── MyShellApp.inf     # 模块定义文件
├── main.c             # 主源文件
└── types.h            # 头文件（可选）
```

### 3.2 INF 文件模板

```ini
[Defines]
  INF_VERSION                    = 0x00010005
  BASE_NAME                      = MyShellApp
  FILE_GUID                      = 12345678-90ab-cdef-1234-567890abcdef
  MODULE_TYPE                    = UEFI_APPLICATION
  VERSION_STRING                 = 1.0
  ENTRY_POINT                    = UefiMain

[BuildOptions]
  MSFT:*_*_*_LINK_FLAGS = /SUBSYSTEM:EFI_APPLICATION

[Sources]
  main.c

[Packages]
  MdePkg/MdePkg.dec

[LibraryClasses]
  UefiLib
  UefiApplicationEntryPoint
  BaseLib
  BaseMemoryLib
```

**如需使用 Shell 库函数：**

```ini
[Packages]
  MdePkg/MdePkg.dec
  ShellPkg/ShellPkg.dec

[LibraryClasses]
  UefiLib
  UefiApplicationEntryPoint
  ShellLib
  BaseLib
```

### 3.3 基础代码模板

```c
#include <Uefi.h>
#include <Library/UefiLib.h>
#include <Library/UefiBootServicesTableLib.h>

EFI_STATUS
EFIAPI
UefiMain (
  IN EFI_HANDLE        ImageHandle,
  IN EFI_SYSTEM_TABLE  *SystemTable
  )
{
  Print(L"Hello, UEFI Shell!\n");
  return EFI_SUCCESS;
}
```

### 3.4 GOP 图形应用模板

**重要：EmulatorPkg 的 GOP 可能没有设置 FrameBufferBase，必须使用 Blt() 方法。**

```c
#include <Uefi.h>
#include <Protocol/GraphicsOutput.h>
#include <Library/UefiLib.h>
#include <Library/UefiBootServicesTableLib.h>
#include <Library/MemoryAllocationLib.h>
#include <Library/DebugLib.h>

static EFI_GRAPHICS_OUTPUT_PROTOCOL *gGOP = NULL;
static UINT32 *gBackBuffer = NULL;  /* 后备缓冲区 */
static UINT32 gScreenWidth = 0;
static UINT32 gScreenHeight = 0;

EFI_STATUS GraphicsInit(VOID)
{
  EFI_STATUS Status;

  /* 定位 GOP */
  Status = gBS->LocateProtocol(
    &gEfiGraphicsOutputProtocolGuid,
    NULL,
    (VOID **)&gGOP
  );
  if (EFI_ERROR(Status)) {
    DEBUG((DEBUG_ERROR, "[Graphics] LocateProtocol failed: %r\n", Status));
    return Status;
  }

  gScreenWidth = gGOP->Mode->Info->HorizontalResolution;
  gScreenHeight = gGOP->Mode->Info->VerticalResolution;
  DEBUG((DEBUG_INFO, "[Graphics] Resolution: %dx%d\n", gScreenWidth, gScreenHeight));

  /* 分配后备缓冲区（双缓冲） */
  gBackBuffer = AllocatePool(gScreenWidth * gScreenHeight * sizeof(UINT32));
  if (gBackBuffer == NULL) {
    DEBUG((DEBUG_ERROR, "[Graphics] AllocatePool failed\n"));
    return EFI_OUT_OF_RESOURCES;
  }

  return EFI_SUCCESS;
}

/* 设置像素到后备缓冲区 */
VOID PutPixel(UINT32 x, UINT32 y, UINT32 color)
{
  if (x < gScreenWidth && y < gScreenHeight) {
    gBackBuffer[y * gScreenWidth + x] = color;
  }
}

/* 将后备缓冲区提交到屏幕 */
VOID Present(VOID)
{
  gGOP->Blt(
    gGOP,
    (EFI_GRAPHICS_OUTPUT_BLT_PIXEL *)gBackBuffer,
    EfiBltBufferToVideo,
    0, 0, 0, 0,
    gScreenWidth, gScreenHeight,
    gScreenWidth * sizeof(UINT32)
  );
}

/* 颜色定义（BGR格式） */
#define COLOR_BLACK   0x00000000
#define COLOR_WHITE   0x00FFFFFF
#define COLOR_RED     0x000000FF
#define COLOR_GREEN   0x0000FF00
#define COLOR_BLUE    0x00FF0000
#define COLOR_YELLOW  0x0000FFFF
```

**关键要点：**
1. **使用双缓冲** - 先写入内存缓冲区，再一次性 Blt 到屏幕，避免闪烁
2. **不要访问 FrameBufferBase** - Emulator 可能未设置，使用 `Blt()` 替代
3. **颜色格式** - UEFI 使用 BGR（蓝绿红）格式，非 RGB
4. **边界检查** - 所有绘图函数必须检查坐标是否在屏幕范围内

---

## 4. 部署到模拟器

### 4.1 在 DSC 文件中注册

编辑 `EmulatorPkg/EmulatorPkg.dsc`，在 `[Components]` 节添加：

```ini
[Components]
  # ... 已有组件 ...

  EmulatorPkg/Application/MyShellApp/MyShellApp.inf
```

### 4.2 在 FDF 文件中包含

编辑 `EmulatorPkg/EmulatorPkg.fdf`，在 `[FV.FvRecovery]` 节添加：

```ini
[FV.FvRecovery]
  # ... 已有条目 ...

  INF EmulatorPkg/Application/MyShellApp/MyShellApp.inf
```

### 4.3 重新编译

```batch
build clean
build -p EmulatorPkg\EmulatorPkg.dsc -a X64 -t VS2019 -b DEBUG
```

### 4.4 运行应用

1. 启动模拟器：`WinHost.exe`
2. 在 Shell 中输入应用名称：

```
Shell> MyShellApp
```

---

## 5. 编译错误处理

### 5.1 中文字符编码错误

**问题现象：**
```
warning C4819: The file contains a character that cannot be represented in the current code page (936)
error C2001: newline in constant
```

**解决方案一：在 INF 中添加编译标志**

```ini
[BuildOptions]
  MSFT:*_*_*_CC_FLAGS = /wd4819 /source-charset:utf-8
  MSFT:*_*_*_LINK_FLAGS = /SUBSYSTEM:EFI_APPLICATION
```

**解决方案二：在 DSC 中添加全局选项**

```ini
[BuildOptions]
  MSFT:*_*_*_CC_FLAGS = /wd4819 /source-charset:utf-8
```

**解决方案三：文件保存为 UTF-8 with BOM**

VS2019: 文件 → 高级保存选项 → 编码: Unicode (UTF-8 with signature)

### 5.2 常见警告抑制

```ini
[BuildOptions]
  MSFT:*_*_*_CC_FLAGS = /wd4819 /wd4100 /wd4204 /wd4245
```

| 参数 | 说明 |
|------|------|
| /wd4819 | 字符编码问题 |
| /wd4100 | 未引用的参数 |
| /wd4204 | 非常量聚合初始化 |
| /wd4245 | 有符号/无符号不匹配 |

---

## 6. 模拟器调试方法

### 6.1 Print 调试输出

```c
#include <Library/UefiLib.h>

Print(L"值: %d, 状态: %r\n", value, Status);
```

**格式说明符：**

| 格式 | 说明 |
|------|------|
| `%d` | 十进制整数 |
| `%x` | 十六进制 |
| `%lx` | 64位十六进制 |
| `%r` | EFI_STATUS |
| `%s` | Unicode 字符串 |
| `%a` | ASCII 字符串 |

### 6.2 DebugLib 串口调试（推荐）

**核心优势：** Claude 可以通过监控模拟器的串口输出（stdout/stderr）来分析问题，无需用户告知屏幕显示内容。

**使用方法：**

```c
#include <Library/DebugLib.h>

/* 在 INF 中添加 DebugLib */
[LibraryClasses]
  DebugLib

/* 调试输出示例 */
DEBUG((DEBUG_INFO, "[MyApp] Starting initialization...\n"));
DEBUG((DEBUG_INFO, "[MyApp] Resolution: %dx%d\n", width, height));
DEBUG((DEBUG_ERROR, "[MyApp] Error: %r (0x%x)\n", Status, Status));
DEBUG((DEBUG_WARN, "[MyApp] Warning: value=%d\n", value));
```

**调试级别：**

| 级别 | 宏 | 用途 |
|------|-----|------|
| 错误 | `DEBUG_ERROR` | 严重错误，必须关注 |
| 警告 | `DEBUG_WARN` | 潜在问题 |
| 信息 | `DEBUG_INFO` | 一般调试信息 |
| 详细 | `DEBUG_VERBOSE` | 详细跟踪信息 |

**最佳实践：**

```c
EFI_STATUS DoSomething(VOID)
{
    DEBUG((DEBUG_INFO, "[Module] DoSomething: Start\n"));

    /* 关键步骤添加调试输出 */
    Status = gBS->LocateProtocol(&gEfiGraphicsOutputProtocolGuid, NULL, (VOID **)&Gop);
    if (EFI_ERROR(Status)) {
        DEBUG((DEBUG_ERROR, "[Module] LocateProtocol failed: %r\n", Status));
        return Status;
    }
    DEBUG((DEBUG_INFO, "[Module] GOP found, Resolution: %dx%d\n",
           Gop->Mode->Info->HorizontalResolution,
           Gop->Mode->Info->VerticalResolution));

    /* 高频操作避免过多输出 */
    for (i = 0; i < count; i++) {
        /* 不要在循环中输出，除非出错 */
        if (error) {
            DEBUG((DEBUG_ERROR, "[Module] Error at index %d\n", i));
        }
    }

    DEBUG((DEBUG_INFO, "[Module] DoSomething: Done\n"));
    return EFI_SUCCESS;
}
```

### 6.3 监控串口输出

**运行模拟器并捕获调试输出：**

```bash
# Windows (Git Bash / PowerShell)
cd Build/EmulatorX64/DEBUG_VS2019/X64
./WinHost.exe 2>&1 | grep -i "\[MyApp\]"

# 过滤特定级别
./WinHost.exe 2>&1 | grep -E "ERROR|WARN"

# 保存到文件
./WinHost.exe 2>&1 | tee debug.log
```

**常用过滤命令：**

```bash
# 只看特定模块
./WinHost.exe 2>&1 | grep "\[Graphics\]"

# 排除噪音
./WinHost.exe 2>&1 | grep -v "PROGRESS CODE"

# 实时监控错误
./WinHost.exe 2>&1 | grep --line-buffered "ERROR"
```

### 6.4 配置调试级别

在 DSC 文件中：

```ini
[PcdsFixedAtBuild]
  # 启用所有调试输出
  gEfiMdePkgTokenSpaceGuid.PcdDebugPrintErrorLevel|0xFFFFFFFF

  # 启用调试属性
  gEfiMdePkgTokenSpaceGuid.PcdDebugPropertyMask|0x1f
```

### 6.5 图形应用调试技巧

**问题：屏幕闪烁后崩溃**

常见原因及调试方法：

```c
/* 1. 检查帧缓冲区是否有效 */
DEBUG((DEBUG_INFO, "[Graphics] FrameBufferBase: 0x%lx\n",
       (UINT64)Gop->Mode->FrameBufferBase));
if (Gop->Mode->FrameBufferBase == 0) {
    DEBUG((DEBUG_ERROR, "[Graphics] FrameBufferBase is NULL, use Blt() instead\n"));
}

/* 2. 检查分辨率是否超出范围 */
DEBUG((DEBUG_INFO, "[Graphics] Screen: %dx%d, Map needs: %dx%d\n",
       screenWidth, screenHeight, mapWidth, mapHeight));

/* 3. 检查内存分配 */
VOID *buffer = AllocatePool(size);
DEBUG((DEBUG_INFO, "[Graphics] Allocated %d bytes at 0x%lx\n", size, (UINT64)buffer));
if (buffer == NULL) {
    DEBUG((DEBUG_ERROR, "[Graphics] Allocation failed!\n"));
}
```

### 6.6 VS2019 调试器

1. 打开 VS2019
2. 文件 → 打开 → 项目
3. 选择 `Build\Emulator\DEBUG_VS2019\X64\WinHost.exe`
4. 设置断点后按 F5 开始调试

---

## 7. 常用协议与库

### 7.1 GOP 图形协议

**头文件：** `MdePkg/Include/Protocol/GraphicsOutput.h`

```c
// 查询模式
Gop->QueryMode(Gop, ModeNumber, &InfoSize, &Info);

// 设置模式
Gop->SetMode(Gop, ModeNumber);

// 块传输
Gop->Blt(Gop, Buffer, Operation, SrcX, SrcY, DstX, DstY, Width, Height, Delta);
```

**Blt 操作：**
- `EfiBltVideoFill` - 填充
- `EfiBltVideoToBltBuffer` - 读屏幕
- `EfiBltBufferToVideo` - 写屏幕

### 7.2 文本输入协议

**头文件：** `MdePkg/Include/Protocol/SimpleTextIn.h`

```c
EFI_INPUT_KEY Key;

// 读取按键
gST->ConIn->ReadKeyStroke(gST->ConIn, &Key);

// 等待按键
gBS->WaitForEvent(1, &gST->ConIn->WaitForKey, &Index);
```

**扫描码：**

| 常量 | 值 | 说明 |
|------|-----|------|
| SCAN_UP | 0x0001 | 上箭头 |
| SCAN_DOWN | 0x0002 | 下箭头 |
| SCAN_LEFT | 0x0004 | 左箭头 |
| SCAN_RIGHT | 0x0003 | 右箭头 |
| SCAN_ESC | 0x0017 | ESC |

### 7.3 常用库

| 库 | 头文件 | 用途 |
|-----|--------|------|
| UefiLib | Library/UefiLib.h | Print 函数 |
| BaseMemoryLib | Library/BaseMemoryLib.h | 内存操作 |
| MemoryAllocationLib | Library/MemoryAllocationLib.h | 内存分配 |
| DebugLib | Library/DebugLib.h | 调试输出 |

### 7.4 内存分配

```c
#include <Library/MemoryAllocationLib.h>

VOID *Buffer = AllocatePool(Size);
VOID *Buffer = AllocateZeroPool(Size);
FreePool(Buffer);

VOID *Pages = AllocatePages(PageCount);
FreePages(Pages, PageCount);
```

---

## 8. 版本化构建与运行前检查

每次修改代码后都必须产生新版本。推荐工程根目录维护 `VERSION.txt`，格式为两行：`VERSION=major.minor.patch` 和 `BUILD=<整数>`。构建脚本每次执行时将 `BUILD` 加一，生成 `Version.h`，并写入 `expected_version.txt`。应用必须包含 `Version.h`，启动时输出 `APP_VERSION=<major.minor.patch+build timestamp>` 到 DEBUG/串口，并把同一字符串绘制到 GOP 窗口固定角落。

构建失败、版本头生成失败或目标 `.efi` 缺失时，不允许运行旧版本。运行前先检查 `expected_version.txt`、目标 `.efi` 和串口日志路径都已准备好。如果不使用 `Build-UefiApp.ps1` 而手工构建，也必须重新生成 `Version.h` 和 `expected_version.txt`；不得复用上一次构建留下的预期版本文件。

## 9. QEMU 运行路径

QEMU 路径与 Emulator/WinHost 路径产出相同证据：串口日志、`expected_version.txt` 和 `snapshot/` 截图。推荐用 OVMF 固件加虚拟 FAT 镜像启动：把目标 `.efi`、`startup.nsh` 和 `expected_version.txt` 放到同一个 FAT 目录，QEMU 参数将该目录映射为只读或读写驱动器，并把串口重定向到 `run_logs/yyyyMMdd_HHmmss_serial.log`。

Windows PowerShell 模板见 `templates/Run-QemuWithSnapshots.ps1`。Linux 使用相同参数形态，只是把路径和进程启动命令换成 shell 等价写法。

## 10. snapshot 定时截屏与多模态分析

运行目标 app 后，必须在工程目录创建 `snapshot/`，并按固定间隔截取目标画面，文件名格式为 `yyyyMMdd_HHmmss_fff.png`。

**首选 QEMU monitor screendump 通道**：用 `-display none` 或 SDL 窗口运行时，通过 monitor（`-monitor stdio` 或 QMP socket）执行 `screendump <file.ppm>` 抓取的是**模拟器显存内容**——与宿主机窗口状态无关，永远可靠。SDL 窗口的客户区抓屏（PowerShell/.NET 窗口截图）在 QEMU SDL 显示后端下必然全黑，**不要用它作为证据来源**；它只适用于 EmulatorPkg/WinHost 这类真实窗口。

截图循环应在窗口不存在、进程退出或达到运行时长后停止，并保留已生成截图。PPM 可用 ImageMagick 或 Python/Pillow 转 PNG。

分析运行结果时，先读取串口日志确认 `APP_VERSION=` 与 `expected_version.txt` 一致，再读取 `snapshot/` 截图。判断目标时必须引用具体证据，例如 `snapshot/20260718_101530_123.png` 显示版本水印和目标画面，`run_logs/20260718_101500_serial.log` 第 N 行包含一致版本。证据不足、连续黑屏、版本不一致或串口出现 ERROR 时，按失败处理，不要询问用户“运行是否正常”。

## 11. 防止运行旧版本

静默编译错误最常见的结果是旧 `.efi` 仍在运行目录。防错流程必须是：生成新版本，构建成功，写入 `expected_version.txt`，启动程序，读取串口版本，比对一致后才允许分析画面。`Test-AppVersion.ps1` 找不到 `APP_VERSION=`、找到多个不同版本，或版本不等于 `expected_version.txt` 时返回非零，并输出 expected/actual、串口日志路径和截图目录。

## 12. QMP 监控通道：screendump 抓帧与 sendkey 输入注入（眼睛和手）

QEMU monitor（人读协议 HMP，`-monitor stdio`；或 QMP JSON socket）同时提供两条闭环通道，让大模型"看见画面并动手操作"：

**眼睛——screendump 抓帧：**

```
(monitor) screendump D:/proj/snapshot/000.ppm
```

抓的是虚拟机显存快照，与宿主窗口无关（SDL 窗口抓屏必黑的问题由此规避）。建议 `-display none` 或常规 SDL 均可；定时循环 screendump 即得连续帧，PPM 转 PNG 后供多模态读取。

**手——sendkey 注入按键：**

```
(monitor) sendkey ret            # 单击
(monitor) sendkey up 4500        # 按住 4500ms（make 后延时发 break）
```

键名是 QEMU 标准名：`up/down/left/right`（方向）、`a-z`、`ret`（回车）、`backspace`、`esc` 等。注意：**QEMU 模拟的 PS/2 键盘不产生 typematic 自动重复**——一次 `sendkey key N` 只有一次按下事件。应用若靠重复按键维持"按住"语义（例如节流后的长按移动），要用一串短促连点（如每 0.3s 一次 `sendkey up 120`）来模拟持续按住，而不是一次长 hold。

**闭环工作流：** 构建新版本 → 启动 QEMU（`-serial file:...` 重定向串口 + monitor 通道）→ screendump 抓帧 → 多模态分析画面 → sendkey 驱动应用（开局、移动、开火、菜单操作）→ 读串口日志做断言。整个"编译-运行-看图-按键-验证"循环可以全程无人值守；SDL 窗口仅用于人工观察时，脚本化验证一律走 monitor 通道。

---

## 快速参考

| 任务 | 命令/模板 |
|------|-----------|
| 初始化环境 | 目标项目配置的 `edksetup.bat` 或 `source edksetup.sh` |
| 编译模拟器 | `build -p EmulatorPkg\EmulatorPkg.dsc -a X64 -t VS2019 -b DEBUG`（Windows）或 GCC 等价命令（Linux） |
| 运行模拟器 | `Build\Emulator\DEBUG_VS2019\X64\WinHost.exe` |
| QEMU 运行带截图 | `templates/Run-QemuWithSnapshots.ps1` |
| 生成新版本并构建 | `templates/Build-UefiApp.ps1` |
| 检查运行版本 | `templates/Test-AppVersion.ps1` |
| 显存抓帧（首选） | monitor `screendump file.ppm`（SDL 窗口抓屏必黑时用它） |
| 注入按键 | monitor `sendkey ret` / `sendkey up 120`（长按用连点模拟） |
| 清理重编 | `build clean && build` |

---

## 故障排除

| 问题 | 解决方案 |
|------|----------|
| 找不到包 | 检查 PACKAGES_PATH 环境变量 |
| 应用不在 Shell 中 | 确认 DSC 和 FDF 都已添加 INF |
| 中文编码错误 | 添加 `/wd4819 /source-charset:utf-8` |
| GOP 定位失败 | 确保模拟器启动完成后再运行 |
| Print 无输出 | 检查控制台重定向设置 |
| 屏幕闪烁后崩溃 | 使用双缓冲 + Blt，不要直接访问 FrameBufferBase |
| 分辨率超出屏幕 | 缩小 TILE_SIZE 或检查 UI 布局是否超出 640x480 |
| 内存分配失败 | 检查缓冲区大小计算是否溢出，使用 (UINTN) 强制转换 |
| 运行了旧版本 | 检查 `expected_version.txt`、串口日志 `APP_VERSION=` 和 `Test-AppVersion.ps1` 返回码 |
| snapshot 没有截图 | 确认目标窗口标题/进程名、截图脚本是否仍在运行、目录是否有写权限 |
| SDL 窗口截图全黑 | 改用 monitor `screendump` 抓显存快照，SDL 客户区抓屏不可用 |
| sendkey 按住无效 | QEMU 无 typematic 重复，用短促连点序列模拟持续按住 |
| QEMU 无法启动 app | 检查 OVMF 路径、虚拟 FAT 镜像内容、`startup.nsh` 和目标 `.efi` 是否在同一目录 |

---

## 自动启动脚本

在应用程序目录创建 `startup.nsh`，模拟器启动时自动执行：

```bash
# startup.nsh - 放在与 WinHost.exe 相同目录
@echo -off
echo Starting My Application...
MyApp.efi
echo Application exited.
pause
```