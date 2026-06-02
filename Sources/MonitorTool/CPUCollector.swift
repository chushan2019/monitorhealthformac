import Foundation
import Darwin.Mach

/// Collects CPU usage via host_processor_info with PROCESSOR_CPU_LOAD_INFO.
/// CPU% = delta(busy ticks) / delta(total ticks) where busy = USER + SYSTEM + NICE.
/// Requires previous state for delta computation.
final class CPUCollector: MetricCollector {
    typealias Snapshot = CPUStats

    struct PreviousState {
        var perCoreTicks: [processor_cpu_load_info]
        var cpuCount: Int
    }

    var label: String { "CPU" }

    func collect(previous: PreviousState?) -> (Snapshot, PreviousState?) {
        var numCpus: natural_t = 0
        var cpuInfo: processor_info_array_t?
        var numCpuInfo: mach_msg_type_number_t = 0

        let kr = host_processor_info(
            mach_host_self(),
            PROCESSOR_CPU_LOAD_INFO,
            &numCpus,
            &cpuInfo,
            &numCpuInfo
        )

        guard kr == KERN_SUCCESS, let info = cpuInfo else {
            return (.unavailable, nil)
        }

        defer {
            vm_deallocate(
                mach_task_self_,
                vm_address_t(bitPattern: info),
                vm_size_t(Int(numCpuInfo) * MemoryLayout<integer_t>.size)
            )
        }

        let numCores = Int(numCpus)
        var newTicks: [processor_cpu_load_info] = []
        var perCoreUsage: [Double] = []
        var totalBusyDelta: UInt64 = 0
        var totalAllDelta: UInt64 = 0

        let ptr = info.withMemoryRebound(
            to: processor_cpu_load_info.self, capacity: numCores
        ) { $0 }

        for i in 0..<numCores {
            let current = ptr.advanced(by: i).pointee
            newTicks.append(current)

            let curTotal = sumTicks(current)
            let curBusy  = UInt64(current.cpu_ticks.0) + UInt64(current.cpu_ticks.1) + UInt64(current.cpu_ticks.3)

            if let prev = previous, i < prev.perCoreTicks.count {
                let p = prev.perCoreTicks[i]
                let prevTotal = sumTicks(p)
                let prevBusy  = UInt64(p.cpu_ticks.0) + UInt64(p.cpu_ticks.1) + UInt64(p.cpu_ticks.3)

                let dTotal = Int64(curTotal) - Int64(prevTotal)
                let dBusy  = Int64(curBusy) - Int64(prevBusy)
                totalAllDelta += UInt64(max(0, dTotal))
                totalBusyDelta += UInt64(max(0, dBusy))

                perCoreUsage.append(dTotal > 0 ? Double(dBusy) / Double(dTotal) * 100 : 0)
            } else {
                perCoreUsage.append(0)
            }
        }

        let overall = totalAllDelta > 0
            ? Double(totalBusyDelta) / Double(totalAllDelta) * 100 : 0

        let next = PreviousState(perCoreTicks: newTicks, cpuCount: numCores)
        let snap = CPUStats(usagePercent: overall, coreCount: numCores, perCoreUsage: perCoreUsage)
        return (snap, next)
    }

    private func sumTicks(_ t: processor_cpu_load_info) -> UInt64 {
        UInt64(t.cpu_ticks.0) + UInt64(t.cpu_ticks.1) + UInt64(t.cpu_ticks.2) + UInt64(t.cpu_ticks.3)
    }
}
