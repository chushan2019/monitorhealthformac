# MonitorTool

A lightweight macOS menu bar system monitor that displays real-time CPU and memory usage directly in the status bar, with a detailed dashboard available on click.

一款輕量級 macOS 選單列系統監控工具，在右上角即時顯示 CPU 和記憶體用量，點擊可查看完整系統資訊。

![macOS](https://img.shields.io/badge/macOS-13%2B-blue)
![Swift](https://img.shields.io/badge/Swift-5.9%2B-orange)
![License](https://img.shields.io/badge/license-MIT-green)
![Size](https://img.shields.io/badge/bundle%20size-~400KB-lightgrey)

**[English](#english) · [繁體中文](#%E7%B9%81%E9%AB%94%E4%B8%AD%E6%96%87)**

---

<a id="english"></a>

## 🇬🇧 English

### Features

- **Menu Bar Display** — Shows live CPU & RAM usage as compact text (e.g., `CPU 45% | RAM 67%`)
- **Detailed Dashboard** — Click the menu bar item to open a panel with full system stats:
  - Per-core CPU usage with progress bars
  - Memory used / total with usage percentage
  - Disk volume capacity
  - Disk read/write speed
  - Network interface upload/download rates
  - GPU utilization (Apple Silicon & Intel)
  - Battery status (charge %, charging state, time remaining)
  - Temperature sensors (via SMC, where available)
  - Top 10 processes by CPU usage
- **Lightweight** — ~400KB app bundle, < 30MB RAM footprint
- **No Dock Icon** — Runs silently in the menu bar only
- **Native** — Built with Swift/SwiftUI, using macOS native APIs

### Requirements

- macOS 13.0 (Ventura) or later
- Apple Silicon (M1/M2/M3/M4) or Intel Mac

### Installation

#### Option 1: Download Pre-built

1. Go to [Releases](https://github.com/chushan2019/monitorhealthformac/releases)
2. Download `MonitorTool.dmg`
3. Open the `.dmg` and drag `MonitorTool.app` to your Applications folder
4. Double-click to launch

#### Option 2: Build from Source

```bash
git clone https://github.com/chushan2019/monitorhealthformac.git
cd monitorhealthformac
swift build -c release
open .build/arm64-apple-macosx/release/MonitorTool.app
```

Or build with Xcode:

```bash
swift package generate-xcodeproj
open MonitorTool.xcodeproj
```

### First Run

Since this app uses an ad-hoc code signature (not a paid Apple Developer certificate), macOS may show a security warning on first launch. To bypass:

1. **Right-click** `MonitorTool.app` → Select **Open**
2. Or go to **System Settings → Privacy & Security** → Click **Open Anyway**

### Usage

- The menu bar item updates every **1 second**
- **Left-click** the menu bar text to open the detailed dashboard
- **Right-click** for a context menu (Details / Quit)
- Click the dashboard window title bar to drag it to any position
- The dashboard updates live while open

### Architecture

```
┌─────────────────────────────────────┐
│        MenuBarManager               │
│    (NSStatusItem + text display)    │
└──────────────┬──────────────────────┘
               │  @Published snapshot
               ▼
┌─────────────────────────────────────┐
│         MetricsStore                │
│   (async let concurrent collectors) │
└──┬──┬──┬──┬──┬──┬──┬──┬──┬─────────┘
   │  │  │  │  │  │  │  │  │
   ▼  ▼  ▼  ▼  ▼  ▼  ▼  ▼  ▼
  CPU Mem Disk DIO Net GPU Batt Temp Proc
```

Each collector runs concurrently via `async let` on a background utility queue. The `MetricsStore` aggregates all results and publishes a `MetricsSnapshot` on the main actor. The menu bar text is formatted by `TextFormatter`.

#### Data Sources

| Metric | macOS API |
|--------|-----------|
| CPU usage | `host_processor_info(PROCESSOR_CPU_LOAD_INFO)` |
| Memory | `host_statistics64(HOST_VM_INFO64)` |
| Disk capacity | `getfsstat(MNT_NOWAIT)` |
| Disk I/O speed | IOKit `IOBlockStorageDriver` statistics |
| Network speed | `getifaddrs` → `ifi_ibytes` / `ifi_obytes` |
| GPU usage | IOKit `AppleGPU` / `IOAccelerator` |
| Battery | `IOPSCopyPowerSourcesInfo` |
| Temperature | IOKit SMC (`AppleSMC` user client) |
| Process stats | `proc_listallpids` + `proc_pidinfo` |

### Project Structure

```
MonitorTool/
├── Package.swift
├── Resources/
│   └── Info.plist
├── Sources/MonitorTool/
│   ├── MonitorToolApp.swift         # App entry point + AppDelegate
│   ├── MenuBarManager.swift         # NSStatusItem lifecycle
│   ├── PopupWindow.swift            # NSPanel dashboard window
│   ├── PopupView.swift              # SwiftUI dashboard view
│   ├── MetricsStore.swift           # Central ObservableObject
│   ├── MetricCollector.swift        # Collector protocol
│   ├── UpdateScheduler.swift        # 1s DispatchSourceTimer
│   ├── MetricModels.swift           # Data models
│   ├── TextFormatter.swift          # Menu bar text formatter
│   ├── CPUCollector.swift           # CPU usage
│   ├── MemoryCollector.swift        # Memory usage
│   ├── DiskCollector.swift          # Disk capacity
│   ├── DiskIOCollector.swift        # Disk read/write speed
│   ├── NetworkCollector.swift       # Network traffic
│   ├── GPUCollector.swift           # GPU usage
│   ├── BatteryCollector.swift       # Battery status
│   ├── TemperatureCollector.swift   # SMC temperature
│   ├── SMCHelper.swift              # SMC low-level helper
│   ├── ProcessCollector.swift       # Per-process stats
│   └── SysctlHelper.swift           # sysctlbyname wrappers
└── dist/                            # Built distribution files
```

### Known Limitations

- **Temperature sensors** — Many SMC keys are restricted on Apple Silicon Macs; the temperature section will only appear if readable keys are found.
- **Process details** — Currently disabled due to Swift 6 struct layout changes with `proc_taskinfo`. Planned for future fix.
- **Battery** — Returns `nil` on desktop Macs (iMac, Mac mini, Mac Pro) with no internal battery.

---

<a id="繁體中文"></a>

## 🇹🇼 繁體中文

### 功能特色

- **選單列即時顯示** — 以精簡文字顯示 CPU 和記憶體即時用量（例如 `CPU 45% | RAM 67%`）
- **詳細資訊儀表板** — 點擊選單列項目即可開啟完整系統資訊面板：
  - 每個 CPU 核心使用率（含進度條）
  - 記憶體已用 / 總量（含使用百分比）
  - 磁碟分割區容量
  - 磁碟讀取 / 寫入速度
  - 網路介面上傳 / 下載速率
  - GPU 使用率（支援 Apple Silicon 和 Intel）
  - 電池狀態（電量百分比、充電中、剩餘時間）
  - 溫度感測器（透過 SMC，在可讀取時顯示）
  - CPU 使用率前 10 的程序
- **輕量級** — App 僅 ~400KB，記憶體佔用 < 30MB
- **無 Dock 圖示** — 僅在選單列靜默執行
- **原生開發** — 使用 Swift/SwiftUI，直接呼叫 macOS 原生 API

### 系統需求

- macOS 13.0 (Ventura) 或更高版本
- Apple Silicon (M1/M2/M3/M4) 或 Intel Mac

### 安裝方式

#### 方式一：下載預編譯版本

1. 前往 [Releases](https://github.com/chushan2019/monitorhealthformac/releases) 頁面
2. 下載 `MonitorTool.dmg`
3. 開啟 `.dmg` 並將 `MonitorTool.app` 拖曳至「應用程式」資料夾
4. 雙擊即可啟動

#### 方式二：從原始碼編譯

```bash
git clone https://github.com/chushan2019/monitorhealthformac.git
cd monitorhealthformac
swift build -c release
open .build/arm64-apple-macosx/release/MonitorTool.app
```

或使用 Xcode 編譯：

```bash
swift package generate-xcodeproj
open MonitorTool.xcodeproj
```

### 首次執行

由於此 App 使用臨時程式碼簽章（非付費的 Apple 開發者憑證），macOS 在首次啟動時可能會顯示安全警告。請按照以下方式繞過：

1. **右鍵點擊** `MonitorTool.app` → 選擇 **「開啟」**
2. 或前往 **「系統設定 → 隱私權與安全性」** → 點擊 **「還是允許開啟」**

### 使用說明

- 選單列項目每 **1 秒** 更新一次
- **左鍵點擊** 選單列文字以開啟詳細資訊儀表板
- **右鍵點擊** 可開啟情境選單（詳細資訊 / 結束）
- 點擊儀表板視窗的標題列可拖曳到任意位置
- 儀表板開啟後會即時更新

### 已知限制

- **溫度感測器** — Apple Silicon Mac 上許多 SMC 鍵值受到限制；僅在可讀取時才會顯示溫度區塊。
- **程序詳情** — 目前因 Swift 6 `proc_taskinfo` 結構佈局變更而暫時停用，計劃於未來修復。
- **電池** — 在沒有內建電池的桌上型 Mac（iMac、Mac mini、Mac Pro）上會返回 `nil`，不顯示電池區塊。

---

## License

MIT License. See [LICENSE](LICENSE) for details.

MIT 授權條款。詳情請見 [LICENSE](LICENSE)。

## Contributing

Pull requests and issue reports are welcome!

歡迎提交 Pull Request 或回報 Issue！
