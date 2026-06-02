import Foundation

// MARK: - CPU

struct CPUStats: Equatable {
    let usagePercent: Double        // 0-100
    let coreCount: Int
    let perCoreUsage: [Double]
    static let unavailable = CPUStats(usagePercent: 0, coreCount: 0, perCoreUsage: [])
}

// MARK: - Memory

struct MemoryStats: Equatable {
    let usedGB: Double
    let totalGB: Double
    var usedPercent: Double {
        guard totalGB > 0 else { return 0 }
        return (usedGB / totalGB) * 100
    }
    static let unavailable = MemoryStats(usedGB: 0, totalGB: 0)
}

// MARK: - Disk

struct DiskStats: Equatable {
    struct VolumeInfo: Equatable, Identifiable {
        let id: String              // mount point
        let name: String            // device node
        let usedGB: Double
        let totalGB: Double
        var usedPercent: Double {
            guard totalGB > 0 else { return 0 }
            return (usedGB / totalGB) * 100
        }
    }
    let volumes: [VolumeInfo]
}

// MARK: - Disk I/O

struct DiskIOStats: Equatable {
    let readBytesPerSec: Double
    let writeBytesPerSec: Double
    static let unavailable = DiskIOStats(readBytesPerSec: 0, writeBytesPerSec: 0)
}

// MARK: - Network

struct NetworkStats: Equatable {
    struct InterfaceStats: Equatable, Identifiable {
        let id: String              // "en0", "en1"
        let rxBytesPerSec: Double
        let txBytesPerSec: Double
    }
    let interfaces: [InterfaceStats]
}

// MARK: - GPU

struct GPUStats: Equatable {
    let usagePercent: Double
    let gpuName: String
    static let unavailable = GPUStats(usagePercent: 0, gpuName: "Unknown")
}

// MARK: - Battery

struct BatteryStats: Equatable {
    let chargePercent: Int
    let isCharging: Bool
    let timeRemainingMinutes: Double?
}

// MARK: - Temperature

struct TemperatureStats: Equatable {
    struct SensorReading: Equatable, Identifiable {
        let id: String
        let label: String
        let celsius: Double
    }
    let sensors: [SensorReading]
}

// MARK: - Processes

struct ProcessStats: Equatable {
    struct ProcessInfo: Equatable, Identifiable {
        let id: Int                 // pid
        let name: String
        let cpuPercent: Double
        let memoryMB: Double
    }
    let topProcesses: [ProcessInfo]
}

// MARK: - Snapshot

struct MetricsSnapshot {
    let cpu: CPUStats
    let memory: MemoryStats
    let disk: DiskStats
    let diskIO: DiskIOStats
    let network: NetworkStats
    let gpu: GPUStats
    let battery: BatteryStats?      // nil = no battery (desktop)
    let temperature: TemperatureStats
    let processes: ProcessStats
    let timestamp: Date
}
