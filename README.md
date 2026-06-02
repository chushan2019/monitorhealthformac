# MonitorTool

A lightweight macOS menu bar system monitor that displays real-time CPU and memory usage directly in the status bar, with a detailed dashboard available on click.

![macOS](https://img.shields.io/badge/macOS-13%2B-blue)
![Swift](https://img.shields.io/badge/Swift-5.9%2B-orange)
![License](https://img.shields.io/badge/license-MIT-green)
![Size](https://img.shields.io/badge/bundle%20size-~400KB-lightgrey)

## Features

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

## Screenshots

Menu bar item displays `CPU xx% | RAM xx%` at a glance. Click for the full dashboard.

## Requirements

- macOS 13.0 (Ventura) or later
- Apple Silicon (M1/M2/M3/M4) or Intel Mac

## Installation

### Option 1: Download Pre-built

1. Go to [Releases](https://github.com/chushan2019/monitorhealthformac/releases)
2. Download `MonitorTool.dmg`
3. Open the `.dmg` and drag `MonitorTool.app` to your Applications folder
4. Double-click to launch

### Option 2: Build from Source

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

## First Run

Since this app uses an ad-hoc code signature (not a paid Apple Developer certificate), macOS may show a security warning on first launch. To bypass:

1. **Right-click** `MonitorTool.app` → Select **Open**
2. Or go to **System Settings → Privacy & Security** → Click **Open Anyway**

## Usage

- The menu bar item updates every **1 second**
- **Left-click** the menu bar text to open the detailed dashboard
- **Right-click** for a context menu (Details / Quit)
- Click the dashboard window title bar to drag it to any position
- The dashboard updates live while open

## Architecture

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

### Data Sources

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

## Project Structure

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

## Known Limitations

- **Temperature sensors** — Many SMC keys are restricted on Apple Silicon Macs; the temperature section will only appear if readable keys are found.
- **Process details** — Currently disabled due to Swift 6 struct layout changes with `proc_taskinfo`. Planned for future fix.
- **Battery** — Returns `nil` on desktop Macs (iMac, Mac mini, Mac Pro) with no internal battery.

## License

MIT License. See [LICENSE](LICENSE) for details.

## Contributing

Pull requests and issue reports are welcome!
