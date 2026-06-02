import Foundation
import Darwin.Mach

/// Collects memory usage via host_statistics64 with HOST_VM_INFO64.
/// Memory model: used = total - free - inactive - speculative.
final class MemoryCollector: MetricCollector {
    typealias Snapshot = MemoryStats
    typealias PreviousState = Void
    var label: String { "Memory" }

    func collect(previous: Void?) -> (Snapshot, Void?) {
        var stats = vm_statistics64_data_t()
        var count = mach_msg_type_number_t(
            MemoryLayout<vm_statistics64_data_t>.size / MemoryLayout<integer_t>.size
        )

        let kr = withUnsafeMutablePointer(to: &stats) { statsPtr in
            statsPtr.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { intPtr in
                host_statistics64(mach_host_self(), HOST_VM_INFO64, intPtr, &count)
            }
        }

        guard kr == KERN_SUCCESS else { return (.unavailable, nil) }

        let pageSize = UInt64(vm_kernel_page_size)
        let totalBytes = UInt64(ProcessInfo.processInfo.physicalMemory)
        let freeBytes      = UInt64(stats.free_count) * pageSize
        let inactiveBytes  = UInt64(stats.inactive_count) * pageSize
        let speculativeBytes = UInt64(stats.speculative_count) * pageSize

        let usedBytes = totalBytes &- freeBytes &- inactiveBytes &- speculativeBytes
        return (MemoryStats(
            usedGB: Double(usedBytes) / 1_073_741_824.0,
            totalGB: Double(totalBytes) / 1_073_741_824.0
        ), nil)
    }
}
