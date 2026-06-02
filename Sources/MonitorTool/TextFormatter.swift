import Foundation

/// Formats a MetricsSnapshot into compact menu bar text.
/// Uses a Config struct so users can toggle which metrics appear.
enum TextFormatter {
    struct Config {
        var showCPU: Bool = true
        var showMemory: Bool = true
        var showDisk: Bool = false
        var showNetwork: Bool = false
        var showDiskIO: Bool = false
        var showGPU: Bool = false
        var showBattery: Bool = false
        var showTemperature: Bool = false
        var separator: String = " | "
        var maxItems: Int = 2
    }

    static func formatMenuText(_ snap: MetricsSnapshot, config: Config = Config()) -> String {
        var parts: [String] = []

        if config.showCPU { parts.append(cpu(snap.cpu)) }
        if config.showMemory { parts.append(mem(snap.memory)) }
        if config.showDisk, !snap.disk.volumes.isEmpty { parts.append(disk(snap.disk)) }
        if config.showNetwork, !snap.network.interfaces.isEmpty { parts.append(net(snap.network)) }
        if config.showDiskIO, snap.diskIO.readBytesPerSec > 0 || snap.diskIO.writeBytesPerSec > 0 {
            parts.append(diskIO(snap.diskIO))
        }
        if config.showGPU { parts.append(gpu(snap.gpu)) }
        if config.showBattery, let b = snap.battery { parts.append(battery(b)) }
        if config.showTemperature, !snap.temperature.sensors.isEmpty { parts.append(temp(snap.temperature)) }

        // Truncate to maxItems to avoid menu bar overflow
        let capped = Array(parts.prefix(config.maxItems))
        return capped.joined(separator: config.separator)
    }

    private static func cpu(_ c: CPUStats) -> String {
        String(format: "CPU %.0f%%", min(max(c.usagePercent, 0), 100))
    }

    private static func mem(_ m: MemoryStats) -> String {
        String(format: "RAM %.0f%%", min(max(m.usedPercent, 0), 100))
    }

    private static func disk(_ d: DiskStats) -> String {
        guard let root = d.volumes.first(where: { $0.id == "/" }) ?? d.volumes.first
        else { return "DISK --" }
        let pct = min(max(root.usedGB / root.totalGB * 100, 0), 100)
        return String(format: "DISK %.0f%%", pct)
    }

    private static func net(_ n: NetworkStats) -> String {
        guard let en = n.interfaces.first(where: { $0.id == "en0" }) ?? n.interfaces.first
        else { return "" }
        let rx = formatSpeed(en.rxBytesPerSec)
        let tx = formatSpeed(en.txBytesPerSec)
        return "\(rx)↓↑\(tx)"
    }

    private static func diskIO(_ d: DiskIOStats) -> String {
        let r = formatSpeed(d.readBytesPerSec)
        let w = formatSpeed(d.writeBytesPerSec)
        return "DIO \(r)↓ \(w)↑"
    }

    private static func gpu(_ g: GPUStats) -> String {
        String(format: "GPU %.0f%%", min(max(g.usagePercent, 0), 100))
    }

    private static func battery(_ b: BatteryStats) -> String {
        let icon = b.isCharging ? "⚡" : ""
        return "BAT \(b.chargePercent)%\(icon)"
    }

    private static func temp(_ t: TemperatureStats) -> String {
        guard let cpu = t.sensors.first(where: { $0.label.contains("CPU") }) ?? t.sensors.first
        else { return "" }
        let temp = min(max(cpu.celsius, 0), 200)
        return String(format: "%.0f°C", temp)
    }

    static func formatSpeed(_ bps: Double) -> String {
        let safeBps = max(0, bps)
        if safeBps >= 1_048_576 {
            return String(format: "%.1fMB/s", safeBps / 1_048_576)
        } else if safeBps >= 1024 {
            return String(format: "%.0fKB/s", safeBps / 1024)
        } else {
            return String(format: "%.0fB/s", safeBps)
        }
    }
}
