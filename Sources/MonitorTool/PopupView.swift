import SwiftUI

struct PopupView: View {
    @ObservedObject var store: MetricsStore

    var body: some View {
        Group {
            if let snap = store.snapshot {
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        // CPU
                        SectionView(title: "CPU") {
                            let cpuClamped = min(max(snap.cpu.usagePercent, 0), 100)
                            MetricRow(
                                label: "Overall",
                                value: String(format: "%.1f%%", cpuClamped),
                                progress: cpuClamped / 100
                            )
                            if !snap.cpu.perCoreUsage.isEmpty {
                                Divider().padding(.vertical, 4)
                                ForEach(Array(snap.cpu.perCoreUsage.enumerated()), id: \.offset) { i, v in
                                    let coreClamped = min(max(v, 0), 100)
                                    MetricRow(label: "Core \(i)", value: String(format: "%.1f%%", coreClamped), progress: coreClamped / 100)
                                }
                            }
                        }

                        // Memory
                        SectionView(title: "Memory") {
                            MetricRow(
                                label: "Used",
                                value: String(format: "%.1f / %.1f GB (%.0f%%)", snap.memory.usedGB, snap.memory.totalGB, snap.memory.usedPercent),
                                progress: snap.memory.usedPercent / 100
                            )
                        }

                        // Disk
                        if !snap.disk.volumes.isEmpty {
                            SectionView(title: "Disk") {
                                ForEach(snap.disk.volumes) { vol in
                                    let displayName = vol.id == "/" ? "Macintosh HD" : vol.id
                                    MetricRow(
                                        label: displayName,
                                        value: String(format: "%.1f / %.1f GB (%.0f%%)", vol.usedGB, vol.totalGB, vol.usedPercent),
                                        progress: vol.usedPercent / 100
                                    )
                                }
                            }
                        }

                        // Disk I/O
                        SectionView(title: "Disk I/O") {
                            MetricRow(label: "Read", value: TextFormatter.formatSpeed(snap.diskIO.readBytesPerSec))
                            MetricRow(label: "Write", value: TextFormatter.formatSpeed(snap.diskIO.writeBytesPerSec))
                        }

                        // Network
                        if !snap.network.interfaces.isEmpty {
                            SectionView(title: "Network") {
                                ForEach(snap.network.interfaces) { iface in
                                    MetricRow(
                                        label: iface.id,
                                        value: "↓ \(TextFormatter.formatSpeed(iface.rxBytesPerSec))  ↑ \(TextFormatter.formatSpeed(iface.txBytesPerSec))"
                                    )
                                }
                            }
                        }

                        // GPU
                        SectionView(title: "GPU") {
                            MetricRow(
                                label: snap.gpu.gpuName,
                                value: String(format: "%.1f%%", snap.gpu.usagePercent),
                                progress: snap.gpu.usagePercent / 100
                            )
                        }

                        // Battery
                        if let batt = snap.battery {
                            SectionView(title: "Battery") {
                                MetricRow(label: "Charge", value: "\(batt.chargePercent)%", progress: Double(batt.chargePercent) / 100)
                                MetricRow(label: "Status", value: batt.isCharging ? "⚡ Charging" : "On Battery")
                                if let t = batt.timeRemainingMinutes {
                                    MetricRow(label: "Remaining", value: String(format: "%.0f min", t))
                                }
                            }
                        }

                        // Temperature
                        if !snap.temperature.sensors.isEmpty {
                            SectionView(title: "Temperature") {
                                ForEach(snap.temperature.sensors) { sensor in
                                    MetricRow(label: sensor.label, value: String(format: "%.1f°C", sensor.celsius))
                                }
                            }
                        }

                        // Top Processes
                        if !snap.processes.topProcesses.isEmpty {
                            SectionView(title: "Top Processes (by CPU)") {
                                ForEach(snap.processes.topProcesses) { proc in
                                    MetricRow(
                                        label: proc.name,
                                        value: String(format: "CPU: %.1f%%  RAM: %.0f MB", proc.cpuPercent, proc.memoryMB)
                                    )
                                }
                            }
                        }
                    }
                    .padding()
                }
            } else {
                ProgressView("Collecting metrics...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(minWidth: 360, minHeight: 420)
    }
}

// MARK: - Reusable subviews

struct MetricRow: View {
    let label: String
    let value: String
    var progress: Double = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack {
                Text(label)
                    .font(.system(size: 12, weight: .medium, design: .default))
                    .foregroundColor(.secondary)
                Spacer()
                Text(value)
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
            }
            if progress > 0 {
                ProgressView(value: progress)
                    .progressViewStyle(.linear)
            }
        }
    }
}

struct SectionView<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.headline)
                .padding(.bottom, 2)
            content
        }
    }
}
