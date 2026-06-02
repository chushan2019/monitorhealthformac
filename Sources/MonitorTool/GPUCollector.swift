import Foundation
import IOKit

/// Collects GPU usage via IOKit.
/// Apple Silicon: matches "AppleGPU" and reads PerformanceStatistics dictionary.
/// Intel fallback: matches "IOAccelerator" (GPU utilization not available via this path).
final class GPUCollector: MetricCollector {
    typealias Snapshot = GPUStats
    typealias PreviousState = Void
    var label: String { "GPU" }

    func collect(previous: Void?) -> (Snapshot, Void?) {
        // Apple Silicon path
        let appleGPU = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("AppleGPU"))
        if appleGPU != MACH_PORT_NULL {
            defer { IOObjectRelease(appleGPU) }

            var name = "Apple GPU"
            if let modelRef = IORegistryEntryCreateCFProperty(
                appleGPU, "model" as CFString, kCFAllocatorDefault, 0
            ) {
                let model = modelRef.takeRetainedValue()
                if let modelStr = model as? String {
                    name = modelStr
                }
            }

            var usage: Double = 0
            if let statsRef = IORegistryEntryCreateCFProperty(
                appleGPU, "PerformanceStatistics" as CFString, kCFAllocatorDefault, 0
            ) {
                let stats = statsRef.takeRetainedValue()
                if let statsDict = stats as? [String: Any] {
                    usage = (statsDict["Device Utilization %"] as? Double)
                         ?? (statsDict["GPU % Utilization"] as? Double)
                         ?? 0
                }
            }

            return (GPUStats(usagePercent: usage, gpuName: name), nil)
        }

        // Intel fallback
        let intelGPU = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("IOAccelerator"))
        if intelGPU != MACH_PORT_NULL {
            defer { IOObjectRelease(intelGPU) }
            var name = "Intel GPU"
            if let nameRef = IORegistryEntryCreateCFProperty(
                intelGPU, "IOName" as CFString, kCFAllocatorDefault, 0
            ) {
                let n = nameRef.takeRetainedValue()
                if let nameStr = n as? String {
                    name = nameStr
                }
            }
            return (GPUStats(usagePercent: 0, gpuName: name), nil)
        }

        return (GPUStats(usagePercent: 0, gpuName: "No GPU"), nil)
    }
}
